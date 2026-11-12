import 'package:material_ui/material_ui.dart';

import '../../../core/constants/dataset_info.dart';
import '../../../core/utils/formatters.dart';
import 'patient_input.dart';

/// Presentation metadata for the ten assessment inputs.
///
/// Units are shown only where they follow from the definition of the
/// measurement (age in years, BMI in kg/m²). The dataset does not document
/// units for blood pressure or cholesterol, nor a scale for the activity and
/// stress scores, so none is claimed.
enum PatientField {
  age(
    label: 'Age',
    jsonKey: 'age',
    icon: Icons.cake_outlined,
    unit: 'years',
    helper: 'Whole number of years.',
    trainingRange: DatasetInfo.age,
  ),
  sex(
    label: 'Sex',
    jsonKey: 'sex',
    icon: Icons.wc_outlined,
    helper: 'Choose the option that best describes you.',
  ),
  bloodPressure(
    label: 'Blood Pressure',
    jsonKey: 'blood_pressure',
    icon: Icons.speed_outlined,
    helper: 'Enter the value from your blood pressure reading.',
    trainingRange: DatasetInfo.bloodPressure,
  ),
  cholesterol(
    label: 'Cholesterol',
    jsonKey: 'cholesterol',
    icon: Icons.water_drop_outlined,
    helper: 'Enter the value from a recent cholesterol result, if available.',
    trainingRange: DatasetInfo.cholesterol,
  ),
  bmi(
    label: 'BMI',
    jsonKey: 'bmi',
    icon: Icons.monitor_weight_outlined,
    unit: 'kg/m²',
    helper: 'Body mass index. Decimals are allowed.',
    trainingRange: DatasetInfo.bmi,
  ),
  smoker(
    label: 'Smoker',
    jsonKey: 'smoker',
    icon: Icons.smoking_rooms_outlined,
    helper: 'Choose Yes or No.',
  ),
  diabetes(
    label: 'Diabetes',
    jsonKey: 'diabetes',
    icon: Icons.bloodtype_outlined,
    helper: 'Choose Yes or No.',
  ),
  physicalActivity(
    label: 'Physical Activity',
    jsonKey: 'physical_activity',
    icon: Icons.directions_run_outlined,
    helper: 'Enter your usual activity level as a whole number.',
    trainingRange: DatasetInfo.physicalActivity,
  ),
  familyHistory(
    label: 'Family History',
    jsonKey: 'family_history',
    icon: Icons.family_restroom_outlined,
    helper: 'Choose Yes or No.',
  ),
  stressLevel(
    label: 'Stress Level',
    jsonKey: 'stress_level',
    icon: Icons.psychology_alt_outlined,
    helper: 'Enter your usual stress level as a whole number.',
    trainingRange: DatasetInfo.stressLevel,
  );

  const PatientField({
    required this.label,
    required this.jsonKey,
    required this.icon,
    required this.helper,
    this.unit,
    this.trainingRange,
  });

  final String label;
  final String jsonKey;
  final IconData icon;
  final String helper;
  final String? unit;

  /// Numeric validation ranges retained for the assessment service contract.
  final NumericRange? trainingRange;

  bool get isNumeric => trainingRange != null;

  /// Numeric fields that only accept whole numbers.
  bool get isWholeNumber =>
      this == age || this == physicalActivity || this == stressLevel;

  /// Label including the unit when one is known, e.g. "Age (years)".
  String get labelWithUnit => unit == null ? label : '$label ($unit)';

  /// The value of this field in [input], formatted for display.
  String displayValue(PatientInput input) => switch (this) {
    age => '${input.age}',
    sex => input.sex.apiValue,
    bloodPressure => formatNumber(input.bloodPressure),
    cholesterol => formatNumber(input.cholesterol),
    bmi => formatNumber(input.bmi),
    smoker => input.smoker.apiValue,
    diabetes => input.diabetes.apiValue,
    physicalActivity => '${input.physicalActivity}',
    familyHistory => input.familyHistory.apiValue,
    stressLevel => '${input.stressLevel}',
  };

  /// Display value with the unit appended when one is known.
  String displayValueWithUnit(PatientInput input) =>
      unit == null ? displayValue(input) : '${displayValue(input)} $unit';
}
