from __future__ import annotations

import unittest
from unittest.mock import patch

from fastapi.testclient import TestClient

from backend.app.main import app, load_model


VALID_PATIENT = {
    "age": 54,
    "sex": "Male",
    "blood_pressure": 142,
    "cholesterol": 238,
    "bmi": 28.4,
    "smoker": "No",
    "diabetes": "No",
    "physical_activity": 3,
    "family_history": "Yes",
    "stress_level": 6,
}


class ApiContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        load_model()
        cls.client = TestClient(app)

    def test_health_loads_verified_model(self) -> None:
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["status"], "ok")
        self.assertTrue(response.json()["model_version"])

    def test_predict_accepts_all_ten_frontend_features(self) -> None:
        response = self.client.post("/predict", json=VALID_PATIENT)
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertIn(body["predicted_class"], (0, 1))
        self.assertIn(body["class_label"], ("No Heart Disease", "Heart Disease"))
        self.assertGreaterEqual(body["model_score"], 0)
        self.assertLessEqual(body["model_score"], 1)

    def test_prediction_label_matches_model_class(self) -> None:
        class ModelReturningPositive:
            classes_ = [0, 1]

            def predict(self, row):
                return [1]

            def predict_proba(self, row):
                return [[0.2, 0.8]]

        with patch("backend.app.main.load_model", return_value=ModelReturningPositive()):
            response = self.client.post("/predict", json=VALID_PATIENT)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["predicted_class"], 1)
        self.assertEqual(response.json()["class_label"], "Heart Disease")

    def test_model_score_is_class_one_probability_even_for_class_zero(self) -> None:
        class ModelReturningNegative:
            # Deliberately reverse the ordering to prove the lookup uses the
            # class label rather than assuming a probability position.
            classes_ = [1, 0]

            def predict(self, row):
                return [0]

            def predict_proba(self, row):
                return [[0.31, 0.69]]

        with patch("backend.app.main.load_model", return_value=ModelReturningNegative()):
            response = self.client.post("/predict", json=VALID_PATIENT)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["predicted_class"], 0)
        self.assertEqual(response.json()["class_label"], "No Heart Disease")
        self.assertEqual(response.json()["model_score"], 0.31)

    def test_predict_rejects_missing_or_extra_features(self) -> None:
        missing = dict(VALID_PATIENT)
        del missing["stress_level"]
        self.assertEqual(self.client.post("/predict", json=missing).status_code, 422)

        extra = dict(VALID_PATIENT, unexpected=True)
        self.assertEqual(self.client.post("/predict", json=extra).status_code, 422)

    def test_predict_rejects_invalid_category(self) -> None:
        invalid = dict(VALID_PATIENT, sex="Unknown")
        self.assertEqual(self.client.post("/predict", json=invalid).status_code, 422)


if __name__ == "__main__":
    unittest.main()
