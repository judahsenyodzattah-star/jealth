import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_config.dart';
import '../core/errors/app_exceptions.dart';
import '../core/network/dio_client.dart';
import '../features/classification/models/patient_input.dart';
import '../features/classification/models/prediction_result.dart';
import '../features/settings/providers/api_settings_controller.dart';

/// The single boundary between the application and the trained model.
///
/// Screens and controllers depend only on this interface. Phase B connects
/// the existing Logistic Regression model by running the FastAPI backend and
/// pointing [ApiConfig.baseUrl] at it: no screen needs to change.
///
/// Implementations must never invent a result: they either return what the
/// backend answered (after validation) or throw a [PredictionException].
abstract interface class PredictionService {
  /// Whether a backend address is configured at all.
  bool get isConfigured;

  /// Requests a classification for [input].
  ///
  /// Throws [PredictionException] for every failure.
  Future<PredictionResult> predict(PatientInput input);

  /// Checks whether the backend can be reached.
  Future<ServiceHealth> checkHealth();
}

/// Outcome of a connectivity check.
enum ServiceConnection { notConfigured, connected, unreachable }

class ServiceHealth {
  const ServiceHealth(this.connection, {this.detail});

  final ServiceConnection connection;

  /// Short technical context when the check failed.
  final String? detail;

  bool get isConnected => connection == ServiceConnection.connected;
}

/// Used while no backend address is configured (all of Phase A).
/// It performs no computation and always reports "not connected".
class UnconfiguredPredictionService implements PredictionService {
  const UnconfiguredPredictionService();

  @override
  bool get isConfigured => false;

  @override
  Future<PredictionResult> predict(PatientInput input) async {
    throw const PredictionException(PredictionFailureType.notConfigured);
  }

  @override
  Future<ServiceHealth> checkHealth() async =>
      const ServiceHealth(ServiceConnection.notConfigured);
}

/// Talks to the Phase B FastAPI backend over HTTP.
///
/// * `POST {baseUrl}{predictPath}` with the [PatientInput.toJson] body.
/// * `GET  {baseUrl}{healthPath}` for the connectivity check.
class HttpPredictionService implements PredictionService {
  HttpPredictionService(this._dio, this._config);

  final Dio _dio;
  final ApiConfig _config;

  @override
  bool get isConfigured => _config.isConfigured;

  @override
  Future<PredictionResult> predict(PatientInput input) async {
    if (!isConfigured) {
      throw const PredictionException(PredictionFailureType.notConfigured);
    }
    try {
      final response = await _dio.post<Object?>(
        _config.predictPath,
        data: input.toJson(),
      );
      return PredictionResult.fromJson(response.data);
    } on PredictionException {
      rethrow;
    } on DioException catch (error) {
      throw mapDioException(error);
    } catch (error) {
      debugPrint('Prediction request failed: $error');
      throw const PredictionException(PredictionFailureType.unknown);
    }
  }

  @override
  Future<ServiceHealth> checkHealth() async {
    if (!isConfigured) {
      return const ServiceHealth(ServiceConnection.notConfigured);
    }
    try {
      await _dio.get<Object?>(_config.healthPath);
      return const ServiceHealth(ServiceConnection.connected);
    } on DioException catch (error) {
      final mapped = mapDioException(error);
      return ServiceHealth(
        ServiceConnection.unreachable,
        detail: mapped.statusCode != null
            ? 'The service answered with HTTP ${mapped.statusCode}.'
            : mapped.title,
      );
    } catch (error) {
      debugPrint('Health check failed: $error');
      return const ServiceHealth(ServiceConnection.unreachable);
    }
  }

  /// Converts a transport error into a typed, user-presentable failure.
  @visibleForTesting
  static PredictionException mapDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const PredictionException(PredictionFailureType.timeout);
      case DioExceptionType.cancel:
        return const PredictionException(PredictionFailureType.cancelled);
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return const PredictionException(PredictionFailureType.unreachable);
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        if (status == 400 || status == 422) {
          return PredictionException(
            PredictionFailureType.rejected,
            statusCode: status,
            detail: _validationDetail(error.response?.data),
          );
        }
        return PredictionException(
          PredictionFailureType.serverError,
          statusCode: status,
        );
      case DioExceptionType.unknown:
        // A body that is not valid JSON surfaces here as a FormatException.
        if (error.error is FormatException) {
          return const PredictionException(
            PredictionFailureType.invalidResponse,
            detail: 'response body is not valid JSON',
          );
        }
        // On the web, blocked (CORS) and refused requests surface here.
        return const PredictionException(PredictionFailureType.unreachable);
    }
  }

  /// Extracts a short summary from a FastAPI validation error body
  /// (`{"detail": [{"loc": ["body", "age"], "msg": "..."}]}`).
  static String? _validationDetail(Object? body) {
    if (body is! Map) return null;
    final detail = body['detail'];
    if (detail is String) return _truncate(detail);
    if (detail is List) {
      final parts = <String>[];
      for (final item in detail.take(3)) {
        if (item is Map && item['msg'] is String) {
          final loc = item['loc'];
          final field = loc is List && loc.isNotEmpty ? '${loc.last}: ' : '';
          parts.add('$field${item['msg']}');
        }
      }
      if (parts.isNotEmpty) return _truncate(parts.join('; '));
    }
    return null;
  }

  static String _truncate(String text) =>
      text.length <= 200 ? text : '${text.substring(0, 197)}...';
}

/// Effective backend configuration (Settings override, then build-time value).
final apiConfigProvider = Provider<ApiConfig>((ref) {
  final runtimeUrl = ref.watch(apiSettingsControllerProvider);
  return ApiConfig.resolve(runtimeBaseUrl: runtimeUrl);
});

/// The prediction service used by the whole application.
///
/// Tests override this provider with a clearly labelled fake; production code
/// only ever gets one of the two implementations in this file.
final predictionServiceProvider = Provider<PredictionService>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (!config.isConfigured) return const UnconfiguredPredictionService();
  final dio = createDio(config);
  ref.onDispose(dio.close);
  return HttpPredictionService(dio, config);
});

/// Result of the most recent connectivity check. Re-run it with
/// `ref.invalidate(serviceHealthProvider)`.
final serviceHealthProvider = FutureProvider<ServiceHealth>((ref) {
  return ref.watch(predictionServiceProvider).checkHealth();
});
