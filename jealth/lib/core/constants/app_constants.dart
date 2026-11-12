/// Application identity and wording shared by every screen.
abstract final class AppConstants {
  static const String appName = "J'ealth";
  static const String subtitle = 'Digital health assessment';
  static const String tagline = 'Health Insights, Made Simple.';

  /// Keep in sync with `version:` in pubspec.yaml (checked by a unit test).
  static const String version = '1.0.0';
  static const String buildNumber = '1';

  static const String projectDescription =
      "J'ealth is a digital health assessment experience that presents "
      'clear, transparent results from an assessment service.';

  /// Short notice shown wherever a model output or model description appears.
  static const String educationalNotice =
      "J'ealth is an experimental educational assessment tool. It is not "
      'medically validated and does not provide a diagnosis.';

  /// Longer disclaimer used on results and shared summaries.
  static const String resultDisclaimer =
      'This is an experimental assessment result for information only. It is '
      'not a diagnosis, a validated risk estimate or medical advice. Always '
      'consult a qualified health professional about health concerns.';

  /// Maximum number of classification records kept on the device.
  static const int maxHistoryRecords = 200;
}
