import '../../../core/errors/app_exceptions.dart';
import 'patient_input.dart';

/// The two classes the model can output.
enum HeartDiseaseClass {
  noHeartDisease(0, 'No Heart Disease'),
  heartDisease(1, 'Heart Disease');

  const HeartDiseaseClass(this.value, this.label);

  /// Encoded class as used by the dataset's `heart_disease` column.
  final int value;
  final String label;

  static HeartDiseaseClass? tryFromValue(Object? value) {
    for (final c in values) {
      if (c.value == value) return c;
    }
    return null;
  }
}

/// A validated answer from the prediction service.
class PredictionResult {
  const PredictionResult({
    required this.predictedClass,
    this.modelScore,
    this.modelVersion,
  });

  final HeartDiseaseClass predictedClass;

  /// Raw model score, only present when the backend supplies one. It is the
  /// model's internal output, not a validated clinical risk percentage.
  final double? modelScore;

  /// Model version, only present when the backend supplies one.
  final String? modelVersion;

  /// Parses and validates the response body of the prediction API contract:
  ///
  /// ```json
  /// {"predicted_class": 1, "class_label": "Heart Disease",
  ///  "model_score": 0.6802, "model_version": "1.0"}
  /// ```
  ///
  /// `predicted_class` is required and must be 0 or 1. `class_label`,
  /// `model_score` and `model_version` are optional. Anything that does not
  /// match is rejected with [PredictionFailureType.invalidResponse] so that a
  /// malformed answer is never displayed as a result.
  factory PredictionResult.fromJson(Object? json) {
    if (json is! Map) throw _invalid('response body is not a JSON object');

    final rawClass = json['predicted_class'];
    final HeartDiseaseClass? predicted = switch (rawClass) {
      int v => HeartDiseaseClass.tryFromValue(v),
      double v when v == v.roundToDouble() => HeartDiseaseClass.tryFromValue(
        v.toInt(),
      ),
      _ => null,
    };
    if (predicted == null) {
      throw _invalid('"predicted_class" must be 0 or 1');
    }

    final rawLabel = json['class_label'];
    if (rawLabel != null) {
      if (rawLabel is! String) throw _invalid('"class_label" must be text');
      final normalized = rawLabel.trim().toLowerCase();
      final contradicts = HeartDiseaseClass.values.any(
        (c) => c != predicted && c.label.toLowerCase() == normalized,
      );
      if (contradicts) {
        throw _invalid('"class_label" contradicts "predicted_class"');
      }
    }

    double? score;
    final rawScore = json['model_score'];
    if (rawScore != null) {
      if (rawScore is! num || !rawScore.isFinite) {
        throw _invalid('"model_score" must be a number');
      }
      if (rawScore < 0 || rawScore > 1) {
        throw _invalid('"model_score" must be between 0 and 1');
      }
      score = rawScore.toDouble();
    }

    String? version;
    final rawVersion = json['model_version'];
    if (rawVersion != null) {
      if (rawVersion is! String && rawVersion is! num) {
        throw _invalid('"model_version" must be text');
      }
      final text = rawVersion.toString().trim();
      if (text.isNotEmpty) version = text;
    }

    return PredictionResult(
      predictedClass: predicted,
      modelScore: score,
      modelVersion: version,
    );
  }

  static PredictionException _invalid(String detail) => PredictionException(
    PredictionFailureType.invalidResponse,
    detail: detail,
  );
}

/// A completed classification: what was submitted, what the service answered,
/// and when. This only ever exists after a real service response.
class ClassificationOutcome {
  const ClassificationOutcome({
    required this.id,
    required this.input,
    required this.result,
    required this.timestamp,
  });

  /// Random identifier; contains no personal information.
  final String id;
  final PatientInput input;
  final PredictionResult result;
  final DateTime timestamp;
}
