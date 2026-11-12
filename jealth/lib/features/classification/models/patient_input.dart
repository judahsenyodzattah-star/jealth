/// Categories exactly as they appear in the training dataset's `sex` column.
enum Sex {
  male('Male'),
  female('Female');

  const Sex(this.apiValue);

  /// Value sent to (and expected by) the prediction service.
  final String apiValue;

  static Sex? tryParse(Object? value) {
    for (final sex in values) {
      if (sex.apiValue == value) return sex;
    }
    return null;
  }
}

/// "Yes" / "No" categories used by the `smoker`, `diabetes` and
/// `family_history` dataset columns.
enum YesNo {
  yes('Yes'),
  no('No');

  const YesNo(this.apiValue);

  final String apiValue;

  static YesNo? tryParse(Object? value) {
    for (final option in values) {
      if (option.apiValue == value) return option;
    }
    return null;
  }
}

/// The ten model inputs for one patient.
///
/// Deliberately contains no name, address, identifier or any other personal
/// detail: only the measurements the model was trained on.
class PatientInput {
  const PatientInput({
    required this.age,
    required this.sex,
    required this.bloodPressure,
    required this.cholesterol,
    required this.bmi,
    required this.smoker,
    required this.diabetes,
    required this.physicalActivity,
    required this.familyHistory,
    required this.stressLevel,
  });

  final int age;
  final Sex sex;
  final double bloodPressure;
  final double cholesterol;
  final double bmi;
  final YesNo smoker;
  final YesNo diabetes;
  final int physicalActivity;
  final YesNo familyHistory;
  final int stressLevel;

  /// Request body of the prediction API contract.
  Map<String, dynamic> toJson() => {
    'age': age,
    'sex': sex.apiValue,
    'blood_pressure': _compact(bloodPressure),
    'cholesterol': _compact(cholesterol),
    'bmi': bmi,
    'smoker': smoker.apiValue,
    'diabetes': diabetes.apiValue,
    'physical_activity': physicalActivity,
    'family_history': familyHistory.apiValue,
    'stress_level': stressLevel,
  };

  /// Parses a stored record. Throws [FormatException] when anything is
  /// missing or has the wrong type.
  factory PatientInput.fromJson(Object? json) {
    if (json is! Map) throw const FormatException('input is not an object');
    return PatientInput(
      age: _int(json, 'age'),
      sex: Sex.tryParse(json['sex']) ?? _fail('sex'),
      bloodPressure: _double(json, 'blood_pressure'),
      cholesterol: _double(json, 'cholesterol'),
      bmi: _double(json, 'bmi'),
      smoker: YesNo.tryParse(json['smoker']) ?? _fail('smoker'),
      diabetes: YesNo.tryParse(json['diabetes']) ?? _fail('diabetes'),
      physicalActivity: _int(json, 'physical_activity'),
      familyHistory:
          YesNo.tryParse(json['family_history']) ?? _fail('family_history'),
      stressLevel: _int(json, 'stress_level'),
    );
  }

  /// Whole numbers are sent as integers (105 rather than 105.0).
  static num _compact(double value) =>
      value == value.roundToDouble() ? value.toInt() : value;

  static int _int(Map<dynamic, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is double && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    return _fail(key);
  }

  static double _double(Map<dynamic, dynamic> json, String key) {
    final value = json[key];
    if (value is num && value.isFinite) return value.toDouble();
    return _fail(key);
  }

  static Never _fail(String key) =>
      throw FormatException('missing or invalid "$key"');

  @override
  bool operator ==(Object other) =>
      other is PatientInput &&
      other.age == age &&
      other.sex == sex &&
      other.bloodPressure == bloodPressure &&
      other.cholesterol == cholesterol &&
      other.bmi == bmi &&
      other.smoker == smoker &&
      other.diabetes == diabetes &&
      other.physicalActivity == physicalActivity &&
      other.familyHistory == familyHistory &&
      other.stressLevel == stressLevel;

  @override
  int get hashCode => Object.hash(
    age,
    sex,
    bloodPressure,
    cholesterol,
    bmi,
    smoker,
    diabetes,
    physicalActivity,
    familyHistory,
    stressLevel,
  );
}
