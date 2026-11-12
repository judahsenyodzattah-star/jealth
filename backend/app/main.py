"""FastAPI adapter for the saved J'ealth heart-disease model.

The service deliberately keeps model preprocessing inside the persisted
scikit-learn pipeline. The API only validates the frontend contract, builds a
single-row DataFrame with the pipeline's feature names, and serializes the
model's binary result.
"""

from __future__ import annotations

import math
import os
from functools import lru_cache
from pathlib import Path
from typing import Literal

import joblib
import pandas as pd
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, ConfigDict, Field, field_validator

DEFAULT_MODEL_PATH = (
    Path(__file__).resolve().parent.parent
    / "models"
    / "hospital_heart_disease_model.joblib"
)

MODEL_VERSION = os.getenv("JEALTH_MODEL_VERSION", "hospital-logistic-regression-1.0.0")
FEATURE_NAMES = (
    "age",
    "sex",
    "blood_pressure",
    "cholesterol",
    "bmi",
    "smoker",
    "diabetes",
    "physical_activity",
    "family_history",
    "stress_level",
)


class PatientInput(BaseModel):
    """The ten fields emitted by Flutter's PatientInput.toJson()."""

    model_config = ConfigDict(extra="forbid")

    age: int = Field(ge=1, le=120)
    sex: Literal["Male", "Female"]
    blood_pressure: float = Field(gt=0, le=1000)
    cholesterol: float = Field(gt=0, le=2000)
    bmi: float = Field(gt=0, le=200)
    smoker: Literal["Yes", "No"]
    diabetes: Literal["Yes", "No"]
    physical_activity: int = Field(ge=0, le=1000)
    family_history: Literal["Yes", "No"]
    stress_level: int = Field(ge=0, le=1000)

    @field_validator("blood_pressure", "cholesterol", "bmi")
    @classmethod
    def finite_measurement(cls, value: float) -> float:
        if not math.isfinite(value):
            raise ValueError("must be finite")
        return value


class PredictionResponse(BaseModel):
    predicted_class: Literal[0, 1]
    class_label: Literal["No Heart Disease", "Heart Disease"]
    model_score: float = Field(ge=0, le=1)
    model_version: str


class HealthResponse(BaseModel):
    status: Literal["ok"]
    model_version: str


def model_path() -> Path:
    configured = os.getenv("JEALTH_MODEL_PATH")
    return Path(configured).expanduser() if configured else DEFAULT_MODEL_PATH


@lru_cache(maxsize=1)
def load_model() -> object:
    path = model_path()
    if not path.is_file():
        raise FileNotFoundError(f"Model artifact was not found: {path}")
    return joblib.load(path)


def _row_from_input(patient: PatientInput) -> pd.DataFrame:
    return pd.DataFrame([patient.model_dump()], columns=FEATURE_NAMES)


app = FastAPI(title="J'ealth Prediction API", version=MODEL_VERSION)
cors_origins = [origin.strip() for origin in os.getenv("JEALTH_CORS_ORIGINS", "*").split(",") if origin.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type"],
)


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    load_model()
    return HealthResponse(status="ok", model_version=MODEL_VERSION)


@app.post("/predict", response_model=PredictionResponse)
def predict(patient: PatientInput) -> PredictionResponse:
    model = load_model()
    row = _row_from_input(patient)
    predicted_class = int(model.predict(row)[0])
    if predicted_class not in (0, 1):
        raise ValueError(f"Unexpected model class: {predicted_class}")

    probabilities = model.predict_proba(row)[0]
    classes = list(getattr(model, "classes_", (0, 1)))
    if 1 not in classes:
        raise ValueError("Model does not expose the positive class 1")
    # The API score is always the positive heart-disease probability, even
    # when the predicted class is 0. This keeps the meaning stable for the
    # Flutter result screen and for future clients.
    score = float(probabilities[classes.index(1)])
    return PredictionResponse(
        predicted_class=predicted_class,
        class_label="Heart Disease" if predicted_class == 1 else "No Heart Disease",
        model_score=score,
        model_version=MODEL_VERSION,
    )
