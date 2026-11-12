import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jealth/features/classification/models/patient_field.dart';
import 'package:jealth/features/classification/models/patient_input.dart';
import 'package:jealth/features/classification/providers/classification_form_controller.dart';
import 'package:jealth/features/classification/validation/field_validators.dart';

void main() {
  group('FieldValidators.validateNumeric', () {
    test('requires a value', () {
      for (final field in PatientField.values.where((f) => f.isNumeric)) {
        expect(FieldValidators.validateNumeric(field, ''), isNotNull);
        expect(FieldValidators.validateNumeric(field, '   '), isNotNull);
      }
    });

    test('rejects text, signs and malformed numbers', () {
      for (final raw in ['abc', '-5', '+5', '1.2.3', '5e2', '.', '12.']) {
        expect(
          FieldValidators.validateNumeric(PatientField.bmi, raw),
          isNotNull,
          reason: raw,
        );
      }
    });

    test('age must be a positive whole number', () {
      expect(FieldValidators.validateNumeric(PatientField.age, '68'), isNull);
      expect(FieldValidators.validateNumeric(PatientField.age, '0'), isNotNull);
      expect(
        FieldValidators.validateNumeric(PatientField.age, '45.5'),
        isNotNull,
      );
      expect(
        FieldValidators.validateNumeric(PatientField.age, '121'),
        isNotNull,
      );
    });

    test('BMI accepts positive decimals with either separator', () {
      expect(FieldValidators.validateNumeric(PatientField.bmi, '38.0'), isNull);
      expect(FieldValidators.validateNumeric(PatientField.bmi, '27,4'), isNull);
      expect(FieldValidators.validateNumeric(PatientField.bmi, '0'), isNotNull);
      expect(FieldValidators.parseNumber('27,4'), 27.4);
    });

    test('blood pressure and cholesterol must be greater than zero', () {
      for (final field in [
        PatientField.bloodPressure,
        PatientField.cholesterol,
      ]) {
        expect(FieldValidators.validateNumeric(field, '105'), isNull);
        expect(FieldValidators.validateNumeric(field, '0'), isNotNull);
        expect(FieldValidators.validateNumeric(field, '1001'), isNotNull);
      }
    });

    test('activity and stress scores are whole numbers, zero allowed', () {
      for (final field in [
        PatientField.physicalActivity,
        PatientField.stressLevel,
      ]) {
        expect(FieldValidators.validateNumeric(field, '0'), isNull);
        expect(FieldValidators.validateNumeric(field, '2'), isNull);
        expect(FieldValidators.validateNumeric(field, '1.5'), isNotNull);
      }
    });
  });

  group('training range advisory', () {
    test('is silent inside the range seen in the dataset', () {
      expect(
        FieldValidators.trainingRangeAdvisory(PatientField.age, '68'),
        isNull,
      );
      expect(
        FieldValidators.trainingRangeAdvisory(PatientField.stressLevel, '9'),
        isNull,
      );
    });

    test('warns, without blocking, outside that range', () {
      expect(
        FieldValidators.validateNumeric(PatientField.age, '25'),
        isNull,
        reason: 'out-of-range values are still valid input',
      );
      expect(
        FieldValidators.trainingRangeAdvisory(PatientField.age, '25'),
        contains('30–79'),
      );
      expect(
        FieldValidators.trainingRangeAdvisory(
          PatientField.physicalActivity,
          '7',
        ),
        contains('0–4'),
      );
    });
  });

  test('units are shown only where the dataset supports them', () {
    expect(PatientField.age.unit, 'years');
    expect(PatientField.bmi.unit, 'kg/m²');
    for (final field in [
      PatientField.bloodPressure,
      PatientField.cholesterol,
      PatientField.physicalActivity,
      PatientField.stressLevel,
    ]) {
      expect(field.unit, isNull, reason: field.name);
    }
  });

  group('ClassificationFormController', () {
    late ProviderContainer container;
    ClassificationFormController form() =>
        container.read(classificationFormControllerProvider.notifier);
    ClassificationFormState state() =>
        container.read(classificationFormControllerProvider);

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
    });

    void fill() {
      form()
        ..setText(PatientField.age, '68')
        ..setSex(Sex.male)
        ..setText(PatientField.bloodPressure, '105')
        ..setText(PatientField.cholesterol, '191')
        ..setText(PatientField.bmi, '38.0')
        ..setYesNo(PatientField.smoker, YesNo.yes)
        ..setYesNo(PatientField.diabetes, YesNo.yes)
        ..setText(PatientField.physicalActivity, '0')
        ..setYesNo(PatientField.familyHistory, YesNo.no)
        ..setText(PatientField.stressLevel, '2');
    }

    test('an empty form is invalid and reports every field', () {
      expect(state().isPristine, isTrue);
      expect(form().submit(), isNull);
      expect(state().showErrors, isTrue);
      expect(state().completedCount, 0);
      for (final field in PatientField.values) {
        expect(state().errorFor(field), isNotNull, reason: field.name);
      }
    });

    test('a complete form produces a typed input', () {
      fill();
      expect(state().isValid, isTrue);
      expect(state().completedCount, 10);
      final input = form().submit()!;
      expect(input.age, 68);
      expect(input.sex, Sex.male);
      expect(input.bmi, 38.0);
      expect(input.familyHistory, YesNo.no);
      expect(input.stressLevel, 2);
    });

    test('one invalid field blocks submission', () {
      fill();
      form().setText(PatientField.bmi, '0');
      expect(form().submit(), isNull);
      expect(state().errorFor(PatientField.bmi), isNotNull);
      expect(state().errorFor(PatientField.age), isNull);
    });

    test('reset clears everything and restore brings it back', () {
      fill();
      final previous = form().reset();
      expect(state().isPristine, isTrue);
      expect(state().resetCount, 1);
      form().restore(previous);
      expect(state().isValid, isTrue);
      expect(state().textOf(PatientField.age), '68');
    });
  });
}
