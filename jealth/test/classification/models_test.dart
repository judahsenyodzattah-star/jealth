import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jealth/core/errors/app_exceptions.dart';
import 'package:jealth/features/classification/models/patient_input.dart';
import 'package:jealth/features/classification/models/prediction_result.dart';

import '../support/fixtures.dart';

Matcher throwsInvalidResponse = throwsA(
  isA<PredictionException>().having(
    (e) => e.type,
    'type',
    PredictionFailureType.invalidResponse,
  ),
);

void main() {
  group('request serialization', () {
    test('matches the API contract example exactly', () {
      expect(contractExampleInput.toJson(), {
        'age': 68,
        'sex': 'Male',
        'blood_pressure': 105,
        'cholesterol': 191,
        'bmi': 38.0,
        'smoker': 'Yes',
        'diabetes': 'Yes',
        'physical_activity': 0,
        'family_history': 'No',
        'stress_level': 2,
      });
    });

    test('uses the ten contract keys in order and nothing else', () {
      expect(contractExampleInput.toJson().keys.toList(), [
        'age',
        'sex',
        'blood_pressure',
        'cholesterol',
        'bmi',
        'smoker',
        'diabetes',
        'physical_activity',
        'family_history',
        'stress_level',
      ]);
    });

    test('encodes value types as the service expects', () {
      final json = contractExampleInput.toJson();
      expect(json['age'], isA<int>());
      expect(json['blood_pressure'], isA<int>());
      expect(json['cholesterol'], isA<int>());
      expect(json['bmi'], isA<double>());
      expect(json['physical_activity'], isA<int>());
      expect(json['stress_level'], isA<int>());
    });

    test('keeps decimals when a measurement has them', () {
      const input = PatientInput(
        age: 41,
        sex: Sex.female,
        bloodPressure: 120.5,
        cholesterol: 201.25,
        bmi: 24.6,
        smoker: YesNo.no,
        diabetes: YesNo.no,
        physicalActivity: 3,
        familyHistory: YesNo.yes,
        stressLevel: 7,
      );
      final json = input.toJson();
      expect(json['sex'], 'Female');
      expect(json['blood_pressure'], 120.5);
      expect(json['cholesterol'], 201.25);
      expect(json['family_history'], 'Yes');
    });

    test('survives a JSON round trip', () {
      final decoded = PatientInput.fromJson(
        jsonDecode(jsonEncode(contractExampleInput.toJson())),
      );
      expect(decoded.toJson(), contractExampleInput.toJson());
    });

    test('rejects malformed stored inputs', () {
      expect(() => PatientInput.fromJson('nope'), throwsFormatException);
      expect(
        () => PatientInput.fromJson(
          {...contractExampleInput.toJson()}..remove('bmi'),
        ),
        throwsFormatException,
      );
      expect(
        () => PatientInput.fromJson({
          ...contractExampleInput.toJson(),
          'sex': 'Unknown',
        }),
        throwsFormatException,
      );
    });
  });

  group('response parsing', () {
    test('parses a full response', () {
      final result = PredictionResult.fromJson({
        'predicted_class': 1,
        'class_label': 'Heart Disease',
        'model_score': 0.6123,
        'model_version': 'lr-1.0',
      });
      expect(result.predictedClass, HeartDiseaseClass.heartDisease);
      expect(result.modelScore, 0.6123);
      expect(result.modelVersion, 'lr-1.0');
    });

    test('parses a minimal response', () {
      final result = PredictionResult.fromJson({'predicted_class': 0});
      expect(result.predictedClass, HeartDiseaseClass.noHeartDisease);
      expect(result.modelScore, isNull);
      expect(result.modelVersion, isNull);
    });

    test('class labels are fixed by the app, not by the service', () {
      expect(HeartDiseaseClass.noHeartDisease.label, 'No Heart Disease');
      expect(HeartDiseaseClass.heartDisease.label, 'Heart Disease');
    });

    test('accepts integral doubles and numeric versions', () {
      final result = PredictionResult.fromJson({
        'predicted_class': 1.0,
        'model_score': 1,
        'model_version': 2,
      });
      expect(result.predictedClass, HeartDiseaseClass.heartDisease);
      expect(result.modelScore, 1.0);
      expect(result.modelVersion, '2');
    });

    test('rejects bodies that are not objects', () {
      expect(() => PredictionResult.fromJson(null), throwsInvalidResponse);
      expect(() => PredictionResult.fromJson('1'), throwsInvalidResponse);
      expect(() => PredictionResult.fromJson([1]), throwsInvalidResponse);
    });

    test('rejects a missing or out-of-range class', () {
      for (final value in [null, 2, -1, '1', 0.5, true]) {
        expect(
          () => PredictionResult.fromJson({'predicted_class': value}),
          throwsInvalidResponse,
          reason: '$value',
        );
      }
    });

    test('rejects a label that contradicts the class', () {
      expect(
        () => PredictionResult.fromJson({
          'predicted_class': 0,
          'class_label': 'Heart Disease',
        }),
        throwsInvalidResponse,
      );
    });

    test('rejects an invalid model score', () {
      for (final value in [1.2, -0.1, 'high', double.nan]) {
        expect(
          () => PredictionResult.fromJson({
            'predicted_class': 1,
            'model_score': value,
          }),
          throwsInvalidResponse,
          reason: '$value',
        );
      }
    });
  });
}
