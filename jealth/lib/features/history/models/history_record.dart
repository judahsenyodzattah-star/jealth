import 'dart:convert';

import '../../classification/models/patient_input.dart';
import '../../classification/models/prediction_result.dart';

/// One classification the user explicitly chose to save on this device.
///
/// Stored fields: a random identifier, the ten submitted measurements, the
/// predicted class, the timestamp and (when the service supplied them) the
/// model score and model version. Nothing that identifies a person.
class HistoryRecord {
  const HistoryRecord({
    required this.id,
    required this.input,
    required this.predictedClass,
    required this.timestamp,
    this.modelScore,
    this.modelVersion,
  });

  /// Storage format version, written with every record.
  static const int schemaVersion = 1;

  final String id;
  final PatientInput input;
  final HeartDiseaseClass predictedClass;
  final DateTime timestamp;
  final double? modelScore;
  final String? modelVersion;

  factory HistoryRecord.fromOutcome(ClassificationOutcome outcome) =>
      HistoryRecord(
        id: outcome.id,
        input: outcome.input,
        predictedClass: outcome.result.predictedClass,
        timestamp: outcome.timestamp,
        modelScore: outcome.result.modelScore,
        modelVersion: outcome.result.modelVersion,
      );

  Map<String, dynamic> toJson() => {
    'v': schemaVersion,
    'id': id,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'input': input.toJson(),
    'predicted_class': predictedClass.value,
    'model_score': ?modelScore,
    'model_version': ?modelVersion,
  };

  String encode() => jsonEncode(toJson());

  /// Decodes a stored record. Throws [FormatException] for anything that is
  /// malformed, incomplete or written by an unknown newer format.
  factory HistoryRecord.decode(String raw) {
    final Object? json = jsonDecode(raw);
    if (json is! Map) throw const FormatException('record is not an object');

    final version = json['v'];
    if (version is! int || version < 1 || version > schemaVersion) {
      throw FormatException('unsupported record version: $version');
    }
    final id = json['id'];
    if (id is! String || id.isEmpty) throw const FormatException('missing id');

    final rawTimestamp = json['timestamp'];
    final timestamp = rawTimestamp is String
        ? DateTime.tryParse(rawTimestamp)
        : null;
    if (timestamp == null) throw const FormatException('invalid timestamp');

    final predicted = HeartDiseaseClass.tryFromValue(json['predicted_class']);
    if (predicted == null) throw const FormatException('invalid class');

    final score = json['model_score'];
    if (score != null && (score is! num || !score.isFinite)) {
      throw const FormatException('invalid model score');
    }
    final modelVersion = json['model_version'];
    if (modelVersion != null && modelVersion is! String) {
      throw const FormatException('invalid model version');
    }

    return HistoryRecord(
      id: id,
      input: PatientInput.fromJson(json['input']),
      predictedClass: predicted,
      timestamp: timestamp.toLocal(),
      modelScore: (score as num?)?.toDouble(),
      modelVersion: modelVersion as String?,
    );
  }
}
