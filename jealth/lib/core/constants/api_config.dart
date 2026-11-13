/// Configuration of the production prediction backend (Python FastAPI).
///
/// Nothing in this file talks to the network. It only describes *where* the
/// prediction service lives so that screens never hold URLs themselves.
///
/// The base URL can be supplied in two ways (highest priority first):
///  1. At runtime from Settings > Assessment service (stored in preferences).
///  2. At build time:
///     `flutter run --dart-define=JEALTH_API_BASE_URL=http://localhost:8000`
///
/// Without either override the app uses [productionBaseUrl]. Passing an
/// explicitly empty build-time value keeps the service disconnected.
class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    this.predictPath = defaultPredictPath,
    this.healthPath = defaultHealthPath,
    this.connectTimeout = const Duration(seconds: 8),
    this.sendTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 15),
  });

  /// URL used by release builds unless a build-time override is supplied.
  static const String productionBaseUrl = 'https://jealth-api.onrender.com';

  /// Whether a build-time override was explicitly supplied.
  static const bool hasBuildTimeOverride = bool.hasEnvironment(
    'JEALTH_API_BASE_URL',
  );

  /// Build-time base URL. Defaults to production; an explicit empty value
  /// leaves the application disconnected.
  static const String compiledBaseUrl = String.fromEnvironment(
    'JEALTH_API_BASE_URL',
    defaultValue: productionBaseUrl,
  );

  /// `POST` endpoint that accepts a patient record and returns a prediction.
  static const String defaultPredictPath = String.fromEnvironment(
    'JEALTH_PREDICT_PATH',
    defaultValue: '/predict',
  );

  /// `GET` endpoint used by "Test connection". Any 2xx answer counts as
  /// reachable.
  static const String defaultHealthPath = String.fromEnvironment(
    'JEALTH_HEALTH_PATH',
    defaultValue: '/health',
  );

  /// Normalised base URL (no trailing slash) or `null` when not configured.
  final String? baseUrl;
  final String predictPath;
  final String healthPath;
  final Duration connectTimeout;
  final Duration sendTimeout;
  final Duration receiveTimeout;

  bool get isConfigured => baseUrl != null;

  /// Resolves the effective configuration from the runtime override and the
  /// build-time value.
  factory ApiConfig.resolve({String? runtimeBaseUrl}) {
    return ApiConfig(
      baseUrl:
          normalizeBaseUrl(runtimeBaseUrl) ?? normalizeBaseUrl(compiledBaseUrl),
    );
  }

  /// Returns a cleaned base URL, or `null` when [raw] is empty or invalid.
  static String? normalizeBaseUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty || validateBaseUrl(trimmed) != null) return null;
    return trimmed.replaceFirst(RegExp(r'/+$'), '');
  }

  /// Returns a human readable problem with [raw], or `null` when it is a
  /// usable http(s) URL. An empty value is valid and means "not connected".
  static String? validateBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) {
      return 'Start the address with http:// or https://';
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return 'Only http:// and https:// addresses are supported';
    }
    if (uri.host.isEmpty) {
      return 'Enter a host, for example http://localhost:8000';
    }
    if (uri.hasQuery || uri.hasFragment) {
      return 'Enter the base address only, without ? or #';
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is ApiConfig &&
      other.baseUrl == baseUrl &&
      other.predictPath == predictPath &&
      other.healthPath == healthPath &&
      other.connectTimeout == connectTimeout &&
      other.sendTimeout == sendTimeout &&
      other.receiveTimeout == receiveTimeout;

  @override
  int get hashCode => Object.hash(
    baseUrl,
    predictPath,
    healthPath,
    connectTimeout,
    sendTimeout,
    receiveTimeout,
  );
}
