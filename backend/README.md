# J'ealth Phase B prediction service

This service loads the existing Logistic Regression pipeline from:

`C:\Users\judah\Downloads\hospital_classification\models\hospital_heart_disease_model.joblib`

The path can be overridden with `JEALTH_MODEL_PATH`; no model is copied or
retrained by this service.

## Run locally

From `backend/`:

```powershell
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Point Flutter at `http://localhost:8000` using Settings or:

```powershell
flutter run -d chrome --dart-define=JEALTH_API_BASE_URL=http://localhost:8000
```

## Contract

- `GET /health` returns a 2xx response only when the saved model can be loaded.
- `POST /predict` accepts the ten keys emitted by Flutter and returns
  `predicted_class`, `class_label`, `model_score`, and `model_version`.
- CORS origins default to `*` for local development and can be restricted with
  comma-separated `JEALTH_CORS_ORIGINS`.
