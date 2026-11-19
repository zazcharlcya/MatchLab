import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:matchlab/services/api_service.dart';
import 'package:matchlab/services/app_logger.dart';

void main() {
  test('таймаут превращается в понятную NetworkException', () async {
    final api = SportsApiService(
      logger: const SilentLog(),
      timeout: const Duration(milliseconds: 20),
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(seconds: 2));
        return http.Response('[]', 200);
      }),
    );
    expect(
      () => api.fetchLeagueMatches(),
      throwsA(
        isA<NetworkException>().having(
          (error) => error.message,
          'message',
          contains('слишком долго'),
        ),
      ),
    );
  });

  test('битый JSON не роняет приложение английским текстом', () async {
    final api = SportsApiService(
      logger: const SilentLog(),
      client: MockClient((_) async => http.Response('not-json', 200)),
    );
    expect(
      () => api.fetchLeagueMatches(),
      throwsA(isA<NetworkException>()),
    );
  });

  test('HTTP 500 даёт NetworkException', () async {
    final api = SportsApiService(
      logger: const SilentLog(),
      client: MockClient((_) async => http.Response('fail', 500)),
    );
    expect(
      () => api.fetchLeagueMatches(),
      throwsA(isA<NetworkException>()),
    );
  });
}
