import 'package:dio/dio.dart';

import '../constants/api_config.dart';

/// Creates the HTTP client used to talk to the prediction service.
Dio createDio(ApiConfig config) {
  return Dio(
    BaseOptions(
      baseUrl: config.baseUrl ?? '',
      connectTimeout: config.connectTimeout,
      sendTimeout: config.sendTimeout,
      receiveTimeout: config.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: const {'Accept': 'application/json'},
    ),
  );
}
