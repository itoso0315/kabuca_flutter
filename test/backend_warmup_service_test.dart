import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kabuca_flutter/services/backend_warmup_service.dart';

void main() {
  test('未設定時は通信せずskipする', () async {
    final service = HttpBackendWarmupService(
      baseUrl: '',
      client: MockClient((_) async => throw StateError('must not call')),
    );
    expect(await service.warmUp(), BackendWarmupStatus.skipped);
  });

  test('base URLの/healthへ軽量GETする', () async {
    Uri? requested;
    final service = HttpBackendWarmupService(
      baseUrl: 'https://api.example.com/v1/',
      client: MockClient((request) async {
        requested = request.url;
        return http.Response('{}', 200);
      }),
    );
    expect(await service.warmUp(), BackendWarmupStatus.ready);
    expect(requested, Uri.parse('https://api.example.com/v1/health'));
  });

  test('タイムアウトを状態として返す', () async {
    final service = HttpBackendWarmupService(
      baseUrl: 'https://api.example.com',
      timeout: const Duration(milliseconds: 1),
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(seconds: 1));
        return http.Response('{}', 200);
      }),
    );
    expect(await service.warmUp(), BackendWarmupStatus.timedOut);
  });
}
