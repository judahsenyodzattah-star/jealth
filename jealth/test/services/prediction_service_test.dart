import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jealth/core/constants/api_config.dart';
import 'package:jealth/core/errors/app_exceptions.dart';
import 'package:jealth/core/network/dio_client.dart';
import 'package:jealth/core/storage/key_value_store.dart';
import 'package:jealth/core/storage/storage_providers.dart';
import 'package:jealth/features/classification/models/prediction_result.dart';
import 'package:jealth/features/classification/providers/prediction_controller.dart';
import 'package:jealth/features/settings/providers/api_settings_controller.dart';
import 'package:jealth/services/prediction_service.dart';

import '../support/fixtures.dart';

/// TEST FIXTURE: answers HTTP requests with a scripted reply so the real
/// [HttpPredictionService] can be exercised without a network.
class ScriptedHttpAdapter implements HttpClientAdapter {
  ScriptedHttpAdapter(this.handler);

  final ResponseBody Function(RequestOptions options, String body) handler;
  final List<RequestOptions> requests = [];
  final List<String> bodies = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final chunks = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        chunks.addAll(chunk);
      }
    }
    final body = utf8.decode(chunks);
    requests.add(options);
    bodies.add(body);
    return handler(options, body);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonReply(Object? body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

const _config = ApiConfig(baseUrl: 'http://service.test:8000');

(HttpPredictionService, ScriptedHttpAdapter) serviceWith(
  ResponseBody Function(RequestOptions options, String body) handler,
) {
  final adapter = ScriptedHttpAdapter(handler);
  final dio = createDio(_config)..httpClientAdapter = adapter;
  return (HttpPredictionService(dio, _config), adapter);
}

Matcher failsWith(PredictionFailureType type) =>
    throwsA(isA<PredictionException>().having((e) => e.type, 'type', type));

void main() {
  group('missing prediction service', () {
    test('the default service is the unconfigured one', () {
      final container = ProviderContainer(
        overrides: [
          preferencesLoaderProvider.overrideWithValue(
            () async => InMemoryKeyValueStore(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final service = container.read(predictionServiceProvider);
      expect(service, isA<UnconfiguredPredictionService>());
      expect(service.isConfigured, isFalse);
    }, skip: ApiConfig.compiledBaseUrl.isNotEmpty);

    test('predict fails with notConfigured and never returns a class', () {
      expect(
        const UnconfiguredPredictionService().predict(contractExampleInput),
        failsWith(PredictionFailureType.notConfigured),
      );
    });

    test('health reports notConfigured', () async {
      final health = await const UnconfiguredPredictionService().checkHealth();
      expect(health.connection, ServiceConnection.notConfigured);
      expect(health.isConnected, isFalse);
    });

    test(
      'the failure is described as "not connected" and is not retryable',
      () {
        const error = PredictionException(PredictionFailureType.notConfigured);
        expect(error.title, 'Prediction service not connected');
        expect(error.message, contains('No result was generated'));
        expect(error.canRetry, isFalse);
      },
    );

    test('the controller ends in a failed state, not a result', () async {
      final container = ProviderContainer(
        overrides: [
          predictionServiceProvider.overrideWithValue(
            const UnconfiguredPredictionService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(predictionControllerProvider.notifier)
          .submit(contractExampleInput);
      final state = container.read(predictionControllerProvider);
      expect(state, isA<PredictionFailed>());
      expect(
        (state as PredictionFailed).error.type,
        PredictionFailureType.notConfigured,
      );
    });

    test(
      'saving an address in settings switches to the HTTP service',
      () async {
        final container = ProviderContainer(
          overrides: [
            preferencesLoaderProvider.overrideWithValue(
              () async => InMemoryKeyValueStore(isPersistent: true),
            ),
          ],
        );
        addTearDown(container.dispose);
        await container.read(appStartupProvider.future);
        final settings = container.read(apiSettingsControllerProvider.notifier);

        expect(await settings.setBaseUrl('not a url'), isNotNull);
        expect(await settings.setBaseUrl('http://localhost:8000/'), isNull);
        expect(
          container.read(apiConfigProvider).baseUrl,
          'http://localhost:8000',
        );
        expect(
          container.read(predictionServiceProvider),
          isA<HttpPredictionService>(),
        );
        expect(
          container.read(preferencesProvider).getString(PrefKeys.apiBaseUrl),
          'http://localhost:8000',
        );
      },
    );
  });

  group('HttpPredictionService', () {
    test('POSTs the contract JSON to /predict and parses the reply', () async {
      final (service, adapter) = serviceWith(
        (_, _) => jsonReply({
          'predicted_class': 1,
          'class_label': 'Heart Disease',
          'model_score': 0.61,
          'model_version': 'lr-1.0',
        }),
      );

      final result = await service.predict(contractExampleInput);

      expect(result.predictedClass, HeartDiseaseClass.heartDisease);
      expect(result.modelScore, 0.61);
      expect(result.modelVersion, 'lr-1.0');

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.toString(), 'http://service.test:8000/predict');
      expect(request.contentType, contains('application/json'));
      expect(jsonDecode(adapter.bodies.single), contractExampleInput.toJson());
    });

    test('rejects a reply that does not match the contract', () {
      final (service, _) = serviceWith(
        (_, _) => jsonReply({'prediction': 'yes'}),
      );
      expect(
        service.predict(contractExampleInput),
        failsWith(PredictionFailureType.invalidResponse),
      );
    });

    test('rejects a reply that is not JSON', () {
      final (service, _) = serviceWith(
        (_, _) => ResponseBody.fromString(
          '<html>Bad gateway</html>',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
      expect(
        service.predict(contractExampleInput),
        failsWith(PredictionFailureType.invalidResponse),
      );
    });

    test(
      'maps FastAPI validation errors to "rejected" with a summary',
      () async {
        final (service, _) = serviceWith(
          (_, _) => jsonReply({
            'detail': [
              {
                'loc': ['body', 'bmi'],
                'msg': 'Input should be greater than 0',
                'type': 'greater_than',
              },
            ],
          }, status: 422),
        );
        await expectLater(
          service.predict(contractExampleInput),
          throwsA(
            isA<PredictionException>()
                .having((e) => e.type, 'type', PredictionFailureType.rejected)
                .having((e) => e.statusCode, 'statusCode', 422)
                .having((e) => e.detail, 'detail', contains('bmi')),
          ),
        );
      },
    );

    test('maps server errors', () {
      final (service, _) = serviceWith(
        (_, _) => jsonReply({'detail': 'boom'}, status: 500),
      );
      expect(
        service.predict(contractExampleInput),
        failsWith(PredictionFailureType.serverError),
      );
    });

    test('maps timeouts and connection failures', () {
      PredictionException map(DioExceptionType type) =>
          HttpPredictionService.mapDioException(
            DioException(requestOptions: RequestOptions(), type: type),
          );
      expect(
        map(DioExceptionType.connectionTimeout).type,
        PredictionFailureType.timeout,
      );
      expect(
        map(DioExceptionType.receiveTimeout).type,
        PredictionFailureType.timeout,
      );
      expect(
        map(DioExceptionType.sendTimeout).type,
        PredictionFailureType.timeout,
      );
      expect(
        map(DioExceptionType.connectionError).type,
        PredictionFailureType.unreachable,
      );
      expect(
        map(DioExceptionType.unknown).type,
        PredictionFailureType.unreachable,
      );
      expect(
        map(DioExceptionType.cancel).type,
        PredictionFailureType.cancelled,
      );
    });

    test('a network failure surfaces as "unreachable"', () {
      final (service, _) = serviceWith(
        (options, _) => throw DioException.connectionError(
          requestOptions: options,
          reason: 'fixture: connection refused',
        ),
      );
      expect(
        service.predict(contractExampleInput),
        failsWith(PredictionFailureType.unreachable),
      );
    });

    test('health check calls GET /health', () async {
      final (service, adapter) = serviceWith(
        (_, _) => jsonReply({'status': 'ok'}),
      );
      final health = await service.checkHealth();
      expect(health.isConnected, isTrue);
      expect(adapter.requests.single.method, 'GET');
      expect(adapter.requests.single.uri.path, '/health');
    });

    test('health check reports an unreachable service', () async {
      final (service, _) = serviceWith(
        (_, _) => jsonReply({'detail': 'down'}, status: 503),
      );
      final health = await service.checkHealth();
      expect(health.connection, ServiceConnection.unreachable);
    });
  });

  group('PredictionController', () {
    test('ignores a second submission while one is running', () async {
      final service = FakePredictionService(
        response: const PredictionResult(
          predictedClass: HeartDiseaseClass.noHeartDisease,
        ),
        gate: Completer<void>(),
      );
      final container = ProviderContainer(
        overrides: [predictionServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);
      final controller = container.read(predictionControllerProvider.notifier);

      final first = controller.submit(contractExampleInput);
      final second = controller.submit(contractExampleInput);
      expect(
        container.read(predictionControllerProvider),
        isA<PredictionLoading>(),
      );
      service.gate!.complete();
      await Future.wait([first, second]);

      expect(service.requests, hasLength(1));
      expect(
        container.read(predictionControllerProvider),
        isA<PredictionSuccess>(),
      );
    });

    test('stamps a result with an id and the current time', () async {
      final now = DateTime(2026, 5, 2, 10, 15);
      final container = ProviderContainer(
        overrides: [
          predictionServiceProvider.overrideWithValue(
            FakePredictionService(
              response: const PredictionResult(
                predictedClass: HeartDiseaseClass.heartDisease,
                modelVersion: 'fixture',
              ),
            ),
          ),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(predictionControllerProvider.notifier)
          .submit(contractExampleInput);
      final state =
          container.read(predictionControllerProvider) as PredictionSuccess;
      expect(state.outcome.timestamp, now);
      expect(state.outcome.id, isNotEmpty);
      expect(state.outcome.result.modelVersion, 'fixture');
    });

    test('retry repeats a failed request', () async {
      final service = FakePredictionService(
        failure: const PredictionException(PredictionFailureType.timeout),
        response: const PredictionResult(
          predictedClass: HeartDiseaseClass.noHeartDisease,
        ),
      );
      final container = ProviderContainer(
        overrides: [predictionServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);
      final controller = container.read(predictionControllerProvider.notifier);

      await controller.submit(contractExampleInput);
      expect(
        container.read(predictionControllerProvider),
        isA<PredictionFailed>(),
      );

      service.failure = null;
      await controller.retry();
      expect(
        container.read(predictionControllerProvider),
        isA<PredictionSuccess>(),
      );
      expect(service.requests, hasLength(2));
    });
  });
}
