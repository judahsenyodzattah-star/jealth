import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/patient_field.dart';
import '../models/patient_input.dart';
import '../validation/field_validators.dart';

/// Everything the user has typed or selected in the classification form.
///
/// Kept in a provider (not in the screen) so the form survives navigation
/// between tabs, to the result screen and back.
class ClassificationFormState {
  const ClassificationFormState({
    this.text = const {},
    this.sex,
    this.smoker,
    this.diabetes,
    this.familyHistory,
    this.showErrors = false,
    this.resetCount = 0,
  });

  /// Raw text of the numeric fields.
  final Map<PatientField, String> text;
  final Sex? sex;
  final YesNo? smoker;
  final YesNo? diabetes;
  final YesNo? familyHistory;

  /// True once the user has tried to submit: errors are then shown live.
  final bool showErrors;

  /// Incremented by every reset so the screen can clear its text fields.
  final int resetCount;

  String textOf(PatientField field) => text[field] ?? '';

  YesNo? yesNoOf(PatientField field) => switch (field) {
    PatientField.smoker => smoker,
    PatientField.diabetes => diabetes,
    PatientField.familyHistory => familyHistory,
    _ => null,
  };

  bool get isPristine =>
      text.values.every((v) => v.trim().isEmpty) &&
      sex == null &&
      smoker == null &&
      diabetes == null &&
      familyHistory == null;

  /// Validation message for [field], or `null` when it is valid.
  String? errorFor(PatientField field) => switch (field) {
    PatientField.sex => FieldValidators.validateChoice(field, sex),
    PatientField.smoker ||
    PatientField.diabetes ||
    PatientField.familyHistory => FieldValidators.validateChoice(
      field,
      yesNoOf(field),
    ),
    _ => FieldValidators.validateNumeric(field, textOf(field)),
  };

  bool get isValid => PatientField.values.every((f) => errorFor(f) == null);

  /// Number of fields that currently have a valid value.
  int get completedCount =>
      PatientField.values.where((f) => errorFor(f) == null).length;

  /// Builds the typed model input, or `null` while anything is invalid.
  PatientInput? toInput() {
    if (!isValid) return null;
    double number(PatientField f) => FieldValidators.parseNumber(textOf(f))!;
    return PatientInput(
      age: number(PatientField.age).toInt(),
      sex: sex!,
      bloodPressure: number(PatientField.bloodPressure),
      cholesterol: number(PatientField.cholesterol),
      bmi: number(PatientField.bmi),
      smoker: smoker!,
      diabetes: diabetes!,
      physicalActivity: number(PatientField.physicalActivity).toInt(),
      familyHistory: familyHistory!,
      stressLevel: number(PatientField.stressLevel).toInt(),
    );
  }

  ClassificationFormState _copy({
    Map<PatientField, String>? text,
    Sex? sex,
    YesNo? smoker,
    YesNo? diabetes,
    YesNo? familyHistory,
    bool? showErrors,
  }) => ClassificationFormState(
    text: text ?? this.text,
    sex: sex ?? this.sex,
    smoker: smoker ?? this.smoker,
    diabetes: diabetes ?? this.diabetes,
    familyHistory: familyHistory ?? this.familyHistory,
    showErrors: showErrors ?? this.showErrors,
    resetCount: resetCount,
  );
}

class ClassificationFormController extends Notifier<ClassificationFormState> {
  @override
  ClassificationFormState build() => const ClassificationFormState();

  void setText(PatientField field, String value) {
    if (state.textOf(field) == value) return;
    state = state._copy(text: {...state.text, field: value});
  }

  void setSex(Sex value) => state = state._copy(sex: value);

  void setYesNo(PatientField field, YesNo value) {
    state = switch (field) {
      PatientField.smoker => state._copy(smoker: value),
      PatientField.diabetes => state._copy(diabetes: value),
      PatientField.familyHistory => state._copy(familyHistory: value),
      _ => state,
    };
  }

  /// Validates everything and returns the typed input when the form is
  /// complete. Otherwise switches on live error display and returns `null`.
  PatientInput? submit() {
    final input = state.toInput();
    if (input == null && !state.showErrors) {
      state = state._copy(showErrors: true);
    }
    return input;
  }

  /// Clears every field and returns the previous contents so the caller can
  /// offer "Undo".
  ClassificationFormState reset() {
    final previous = state;
    state = ClassificationFormState(resetCount: state.resetCount + 1);
    return previous;
  }

  /// Puts back the contents returned by [reset].
  void restore(ClassificationFormState previous) {
    state = ClassificationFormState(
      text: previous.text,
      sex: previous.sex,
      smoker: previous.smoker,
      diabetes: previous.diabetes,
      familyHistory: previous.familyHistory,
      showErrors: previous.showErrors,
      resetCount: state.resetCount + 1,
    );
  }
}

final classificationFormControllerProvider =
    NotifierProvider<ClassificationFormController, ClassificationFormState>(
      ClassificationFormController.new,
    );
