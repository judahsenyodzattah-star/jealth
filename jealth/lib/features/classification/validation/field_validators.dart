import '../models/patient_field.dart';

/// Pure validation helpers for the patient classification form.
///
/// Only structural rules are enforced (required, numeric, positive, whole
/// number where the dataset uses whole numbers). No clinical thresholds are
/// applied: values outside the training range are allowed and merely flagged
/// through [trainingRangeAdvisory].
abstract final class FieldValidators {
  /// Largest age accepted by the form: a plausibility bound for typing
  /// mistakes, not a clinical rule.
  static const int maxAge = 120;

  /// Upper bound that catches obviously mistyped measurements.
  static const double maxMeasurement = 1000;

  /// Parses user-typed text, accepting "," as a decimal separator.
  static double? parseNumber(String? raw) {
    if (raw == null) return null;
    final text = raw.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(text)) return null;
    final value = double.tryParse(text);
    return value != null && value.isFinite ? value : null;
  }

  /// Returns an error message for a numeric [field], or `null` when valid.
  static String? validateNumeric(PatientField field, String? raw) {
    assert(field.isNumeric);
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return 'Enter ${_article(field)}.';
    final value = parseNumber(text);
    if (value == null) return 'Enter a valid number.';

    if (field.isWholeNumber && value != value.roundToDouble()) {
      return 'Enter a whole number.';
    }

    switch (field) {
      case PatientField.age:
        if (value < 1) return 'Age must be a positive whole number.';
        if (value > maxAge) return 'Enter an age of $maxAge or less.';
      case PatientField.physicalActivity || PatientField.stressLevel:
        if (value > maxMeasurement) return 'This value is too large.';
      default:
        if (value <= 0) return '${field.label} must be greater than 0.';
        if (value > maxMeasurement) return 'This value is too large.';
    }
    return null;
  }

  /// Returns an error message when a categorical field has no selection.
  static String? validateChoice(PatientField field, Object? selection) =>
      selection == null
      ? 'Select an option for ${field.label.toLowerCase()}.'
      : null;

  /// A non-blocking note for valid values outside the range the model saw
  /// during training. Returns `null` when the value is inside the range,
  /// empty or invalid.
  static String? trainingRangeAdvisory(PatientField field, String? raw) {
    final range = field.trainingRange;
    if (range == null || validateNumeric(field, raw) != null) return null;
    final value = parseNumber(raw)!;
    if (range.contains(value)) return null;
    return 'This value is outside the usual range for this assessment '
        '(${range.label}). Please check it before continuing.';
  }

  static String _article(PatientField field) => switch (field) {
    PatientField.age => 'an age',
    PatientField.bmi => 'a BMI value',
    PatientField.bloodPressure => 'a blood pressure value',
    PatientField.cholesterol => 'a cholesterol value',
    PatientField.physicalActivity => 'a physical activity score',
    PatientField.stressLevel => 'a stress score',
    _ => 'a value',
  };
}
