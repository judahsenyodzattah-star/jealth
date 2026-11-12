/// Why a prediction could not be obtained.
enum PredictionFailureType {
  /// No backend URL is configured (the normal state during Phase A).
  notConfigured,

  /// The backend could not be reached (offline, wrong address, refused, CORS).
  unreachable,

  /// The backend did not answer within the configured time limits.
  timeout,

  /// The backend answered, but not with the agreed response contract.
  invalidResponse,

  /// The backend rejected the submitted measurements (HTTP 400 / 422).
  rejected,

  /// The backend reported an internal problem (HTTP 5xx or unexpected status).
  serverError,

  /// The request was cancelled before it finished.
  cancelled,

  /// Anything else.
  unknown,
}

/// A typed, user-presentable prediction failure.
///
/// [detail] is technical context for developers (shown in a muted "details"
/// line at most); it never contains a stack trace.
class PredictionException implements Exception {
  const PredictionException(this.type, {this.statusCode, this.detail});

  final PredictionFailureType type;
  final int? statusCode;
  final String? detail;

  /// Short headline for the failure.
  String get title => switch (type) {
    PredictionFailureType.notConfigured => 'Assessment service unavailable',
    PredictionFailureType.unreachable =>
      'Assessment service unavailable',
    PredictionFailureType.timeout => 'Assessment service timed out',
    PredictionFailureType.invalidResponse =>
      'Assessment service returned an unexpected result',
    PredictionFailureType.rejected => 'Measurements need review',
    PredictionFailureType.serverError => 'Assessment service error',
    PredictionFailureType.cancelled => 'Assessment cancelled',
    PredictionFailureType.unknown => 'Something went wrong',
  };

  /// Friendly explanation with a suggested next step.
  String get message => switch (type) {
    PredictionFailureType.notConfigured =>
      'The assessment service is not configured yet. Add its address in '
          'Settings to continue. No result was generated.',
    PredictionFailureType.unreachable =>
      'Please check your connection and try again. No result was generated.',
    PredictionFailureType.timeout =>
      'The assessment service did not answer in time. It may be starting up or busy. '
          'Please try again. No result was generated.',
    PredictionFailureType.invalidResponse =>
      'The assessment service returned an unreadable result, so the '
          'answer was discarded rather than shown. No result was generated.',
    PredictionFailureType.rejected =>
      'The assessment service could not accept the submitted values. Review the '
          'measurements and try again. No result was generated.',
    PredictionFailureType.serverError =>
      'The assessment service ran into a problem. Please try again in a '
          'moment. No result was generated.',
    PredictionFailureType.cancelled =>
      'The request was cancelled before the service answered. No result was '
          'generated.',
    PredictionFailureType.unknown =>
      'An unexpected problem stopped the classification. Please try again. '
          'No result was generated.',
  };

  /// Whether sending the same request again can reasonably succeed.
  bool get canRetry => switch (type) {
    PredictionFailureType.notConfigured ||
    PredictionFailureType.rejected => false,
    _ => true,
  };

  @override
  String toString() =>
      'PredictionException(${type.name}'
      '${statusCode == null ? '' : ', status $statusCode'}'
      '${detail == null ? '' : ', $detail'})';
}

/// A failure of the device-local storage (preferences or saved history).
class StorageException implements Exception {
  const StorageException(this.message);

  /// Safe to show to the user.
  final String message;

  @override
  String toString() => 'StorageException($message)';
}
