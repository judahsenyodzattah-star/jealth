# J'ealth

**AI-Powered Heart Disease Classification** — *Explore Health Through Machine Learning*

J'ealth is the Flutter front end of an academic Hospital Heart Disease
Classification project. It collects ten patient measurements, sends them to a
prediction service, and shows the class the trained model returns. It also
presents the project's historical model evaluation and explains the machine
learning concepts involved.

> J'ealth is an educational machine learning demonstration. It is not a medical
> device and it does not provide a diagnosis.

## Project status: Phase A

| | |
|---|---|
| Phase A (this repository) | Complete front end and a typed prediction-service interface. |
| Phase B (not started) | Serve the trained Logistic Regression model through FastAPI and connect it. |

The app contains **no prediction logic and no model**. Until a prediction
service address is configured, every submission ends in a
"Prediction service not connected" screen and nothing is simulated.

## Requirements

- Flutter 3.47.9 stable (Dart 3.13.7) or newer on the same major line
- Chrome for web; Android SDK and JDK 17+ for Android; Visual Studio with the
  "Desktop development with C++" workload for Windows; Xcode for iOS

## Setup

```bash
cd jealth
flutter pub get
```

## Run

```bash
# Web (Chrome)
flutter run -d chrome

# Android (emulator or device)
flutter run -d android

# Windows
flutter run -d windows
```

Release builds: `flutter build web`, `flutter build apk`, `flutter build windows`.

## Checks

```bash
flutter analyze
flutter test
```

## Connecting the FastAPI service

There are two ways to tell the app where the service is. The address saved in
Settings wins when both are present.

**1. In the app.** Settings → Prediction service → enter the address →
**Save address**. **Test connection** calls `GET /health`.

**2. At build time.**

```bash
flutter run -d chrome --dart-define=JEALTH_API_BASE_URL=http://localhost:8000
```

| `--dart-define` | Default | Purpose |
|---|---|---|
| `JEALTH_API_BASE_URL` | *(empty: not connected)* | Base address of the service |
| `JEALTH_PREDICT_PATH` | `/predict` | Path of the prediction endpoint (POST) |
| `JEALTH_HEALTH_PATH` | `/health` | Path of the health endpoint (GET, any 2xx = reachable) |

Addresses to use during development:

| Running the app on | Service on the same computer |
|---|---|
| Chrome, Windows | `http://localhost:8000` |
| Android emulator | `http://10.0.2.2:8000` |
| Physical phone | `http://<your-computer's-LAN-IP>:8000` (start uvicorn with `--host 0.0.0.0`) |

Platform rules to know:

- **Web:** the service must allow the app's origin with CORS (see Phase B).
- **Android:** plain `http://` works in debug builds only. Release builds
  require `https://`.
- **iOS:** plain `http://` is allowed for local-network addresses only.

## API contract

`POST /predict`

```json
{
  "age": 68,
  "sex": "Male",
  "blood_pressure": 105,
  "cholesterol": 191,
  "bmi": 38.0,
  "smoker": "Yes",
  "diabetes": "Yes",
  "physical_activity": 0,
  "family_history": "No",
  "stress_level": 2
}
```

Response:

```json
{
  "predicted_class": 1,
  "class_label": "Heart Disease",
  "model_score": 0.61,
  "model_version": "1.0.0"
}
```

| Field | Rule enforced by the app |
|---|---|
| `predicted_class` | Required. Must be `0` (No Heart Disease) or `1` (Heart Disease). |
| `class_label` | Optional. Rejected if it names the other class. The app always displays its own label. |
| `model_score` | Optional. Number from 0 to 1. Shown as "Model score", never as a risk percentage. |
| `model_version` | Optional. Text or number. |

A reply that breaks these rules is discarded and reported as
"Unexpected response from the service". HTTP 400 and 422 are shown as rejected
input, including FastAPI's `detail` summary.

Whole numbers are sent without a decimal point. On the web this includes
`bmi` (`38`, not `38.0`), because JavaScript has a single number type; declare
the numeric fields as `float` in the service so both forms are accepted.

## Phase B integration guide

Everything Phase B has to touch is listed here.

1. **Find the trained model.** The notebook and the saved Logistic Regression
   model were not in the workspace or the shared Drive folder when Phase A was
   built; only `hospital_synthetic_dataset.xlsx` was found. The service needs
   the fitted model **together with the exact preprocessing used in training**
   (category encoding and any scaling), ideally saved as one scikit-learn
   `Pipeline`.
2. **Build the FastAPI service** with:
   - `POST /predict` accepting and returning the JSON above.
   - `GET /health` returning any 2xx response.
   - `CORSMiddleware` allowing the web app's origin, the `POST` and `GET`
     methods, and the `Content-Type` header.
   - Field names and category spellings exactly as in the dataset columns
     (`"Male"`/`"Female"`, `"Yes"`/`"No"`).
3. **Point the app at it** using Settings or `JEALTH_API_BASE_URL`. No Dart
   code needs to change if the contract above is followed.

Integration points in the code:

| File | Role |
|---|---|
| `lib/services/prediction_service.dart` | The boundary. `PredictionService` interface, `HttpPredictionService` (real HTTP client), `UnconfiguredPredictionService` (used while no address is set), `predictionServiceProvider`, `serviceHealthProvider`. |
| `lib/core/constants/api_config.dart` | Base URL, endpoint paths and timeouts (connect 8 s, send 10 s, receive 15 s). |
| `lib/features/classification/models/patient_input.dart` | Request model; `toJson()` defines the request body. |
| `lib/features/classification/models/prediction_result.dart` | Response model; `fromJson()` validates the reply. |
| `lib/core/errors/app_exceptions.dart` | Failure types and the user-facing wording for each. |
| `lib/features/settings/providers/api_settings_controller.dart` | Stores the address entered in Settings. |

If the service ends up with different paths, change only the two
`--dart-define` values. If it needs different field names, change only
`PatientInput.toJson()` and `PredictionResult.fromJson()` and their tests.

After connecting, update the wording of `PredictionFailureType.notConfigured`
in `app_exceptions.dart` if "has not been connected yet" no longer fits.

## What the app verified about the dataset

`hospital_synthetic_dataset.xlsx` has 500 complete records and these columns:
`age`, `sex`, `blood_pressure`, `cholesterol`, `bmi`, `smoker`, `diabetes`,
`physical_activity`, `family_history`, `stress_level`, `heart_disease`.

The file states **no units and no scale descriptions**. The app therefore:

- shows a unit only for Age (years) and BMI (kg/m², by definition);
- shows no unit for blood pressure or cholesterol, and says so;
- treats physical activity and stress level as whole-number scores without
  naming what the values mean;
- shows the range seen in the data (for example age 30–79) as a note, and warns
  without blocking when a value falls outside it. These ranges describe the
  dataset; they are not clinical thresholds.

## Privacy

- No accounts, analytics, advertising or cloud storage.
- No names or identifiers are collected.
- A result is stored only when the user presses **Save Result**, on the device,
  through `flutter_secure_storage` (Android Keystore, iOS Keychain, Windows
  Credential Manager). On the web, records are encrypted in the browser's local
  storage with a key kept in the same browser, so they are not protected from
  someone using the same browser profile. The app says this on its Privacy page.
- Android backups and device transfer exclude the history.
- **Clear classification history** (History, Settings and Privacy) deletes every
  saved record, including unreadable ones.
- Sharing happens only after the user presses Share and confirms; measurements
  are left out unless the user switches them on.

## Project structure

```
lib/
  main.dart
  app/            router, navigation shell, themes
  core/           constants, errors, storage, network, formatting, shared widgets
  services/       prediction service interface and HTTP client
  features/
    splash/  onboarding/  home/
    classification/   form, validation, request and response models
    results/          result screen, share
    history/          local records
    analytics/        historical evaluation data and charts
    learn/            educational content
    settings/         theme, service address, privacy, about, model information
test/             unit and widget tests; fakes live in test/support/fixtures.dart
tool/generate_icons.py   regenerates every launcher icon (needs Pillow)
```

State management is Riverpod, navigation is GoRouter, HTTP is Dio, preferences
use SharedPreferences. Charts are drawn with plain widgets; there is no chart
package.

## Evaluation figures shown in Analytics

These are fixed, historical results supplied with the project. The app does not
compute them.

| Model | Accuracy | Precision | Recall | F1 | ROC-AUC |
|---|---|---|---|---|---|
| Logistic Regression (selected) | 56% | 0.562 | 0.774 | 0.651 | 0.505 |
| Decision Tree | 47% | 0.500 | 0.226 | 0.312 | 0.497 |
| Random Forest | 52% | 0.542 | 0.604 | 0.571 | 0.521 |

Logistic Regression confusion matrix on the 100 test records: TN 15, FP 32,
FN 12, TP 41. The majority class makes up 53 of those 100 records, so the
model is only slightly better than always predicting the more common class, and
its ROC-AUC is close to random.

## Acknowledgements

- [Plus Jakarta Sans](https://github.com/tokotype/PlusJakartaSans), Copyright
  2020 The Plus Jakarta Sans Project Authors, SIL Open Font License 1.1
  (`assets/fonts/OFL.txt`).
- Flutter, material_ui, flutter_riverpod, go_router, dio, shared_preferences,
  flutter_secure_storage and share_plus. Full licence texts are in the app under
  Settings → Licenses and acknowledgements.
