/// Facts about the synthetic hospital dataset used to train the model.
///
/// The value ranges below were read from `hospital_synthetic_dataset.xlsx`
/// (500 rows, 11 columns) and are *observations*, not clinical thresholds.
/// The dataset does not document units or scoring scales, so the application
/// never assigns a meaning to them.
abstract final class DatasetInfo {
  static const int totalRecords = 500;
  static const int inputFeatures = 10;
  static const int targetColumns = 1;
  static const int trainingRecords = 400;
  static const int testingRecords = 100;
  static const String targetName = 'heart_disease';

  /// Class balance across all 500 records.
  static const int classOneRecords = 266;
  static const int classZeroRecords = 234;

  static const NumericRange age = NumericRange(30, 79);
  static const NumericRange bloodPressure = NumericRange(90, 179);
  static const NumericRange cholesterol = NumericRange(150, 299);
  static const NumericRange bmi = NumericRange(18.1, 40.0);
  static const NumericRange physicalActivity = NumericRange(0, 4);
  static const NumericRange stressLevel = NumericRange(1, 9);
}

/// Inclusive range of values observed in the training dataset.
class NumericRange {
  const NumericRange(this.min, this.max);

  final num min;
  final num max;

  bool contains(num value) => value >= min && value <= max;

  String get label => '${_fmt(min)}–${_fmt(max)}';

  static String _fmt(num v) =>
      v == v.roundToDouble() && v is int ? '$v' : v.toString();
}
