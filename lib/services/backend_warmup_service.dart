import 'dart:async';

import 'package:http/http.dart' as http;

enum BackendWarmupStatus { ready, failed, timedOut, skipped }

abstract interface class BackendWarmupService {
  Future<BackendWarmupStatus> warmUp();
}

class HttpBackendWarmupService implements BackendWarmupService {
  HttpBackendWarmupService({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(milliseconds: 2800),
  }) : _client = client ?? http.Client(),
       baseUrl =
           baseUrl ?? const String.fromEnvironment('KABUCA_BACKEND_BASE_URL');

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  @override
  Future<BackendWarmupStatus> warmUp() async {
    if (baseUrl.trim().isEmpty) return BackendWarmupStatus.skipped;
    try {
      final base = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/');
      final response = await _client
          .get(
            base.resolve('health'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(timeout);
      return response.statusCode >= 200 && response.statusCode < 300
          ? BackendWarmupStatus.ready
          : BackendWarmupStatus.failed;
    } on TimeoutException {
      return BackendWarmupStatus.timedOut;
    } catch (_) {
      return BackendWarmupStatus.failed;
    }
  }
}
