import 'dart:convert';
import 'dart:typed_data';

import 'package:business_genie/core/di/app_dependencies.dart';
import 'package:business_genie/core/storage/token_storage.dart';
import 'package:business_genie/data/app_state.dart';
import 'package:dio/dio.dart';

/// A pretend Business Genie server for tests: answers by "METHOD /path".
/// Every request is recorded, so a test can check what left the phone.
class FakeBackend implements HttpClientAdapter {
  final Map<String, (int, Map<String, dynamic>)> _answers = {};
  final List<RequestOptions> requests = [];

  /// Answers [route] ("POST /auth/login") with [statusCode] and [body].
  void answer(String route, int statusCode, Map<String, dynamic> body) => _answers[route] = (statusCode, body);

  Dio createDio() => Dio(BaseOptions(baseUrl: 'https://genie.test/api/genie'))..httpClientAdapter = this;

  List<String> get requestedRoutes => [for (final request in requests) '${request.method} ${request.path}'];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final answer = _answers['${options.method} ${options.path}'];
    final (status, body) = answer ?? (404, <String, dynamic>{'ok': false, 'error': 'Not found'});
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const demoUserJson = {
  'id': 6,
  'first_name': 'Neha',
  'last_name': 'Kulkarni',
  'full_name': 'Neha Kulkarni',
  'email': 'neha@northwind.test',
  'user_type': 'employee',
  'role': 'Employee',
  'org_id': 2,
  'department_id': 2,
};

/// A backend where neha@northwind.test signs in with 123456 and the company is set up.
FakeBackend workingBackend() => FakeBackend()
  ..answer('POST /auth/login', 200, {'ok': true, 'to': 'neha@northwind.test', 'note': 'The code works for ten minutes.'})
  ..answer('POST /auth/login/verify', 200, {
    'ok': true,
    'token': 'tok-1',
    'token_type': 'Bearer',
    'expires_at': DateTime.now().add(const Duration(days: 15)).toIso8601String(),
    'user': demoUserJson,
  })
  ..answer('GET /auth/me', 200, {'ok': true, 'user': demoUserJson})
  ..answer('GET /onboarding', 200, {'ok': true, 'workspace': true, 'step': 'done'})
  ..answer('GET /dashboard', 200, {
    'ok': true,
    'organization': {'organization_name': 'Northwind Traders', 'industry': 'Retail', 'location': 'Pune'},
  });

/// An app wired to [backend] with nothing stored, ready for `init()`.
({AppState app, AppDependencies dependencies}) buildTestApp(FakeBackend backend, {TokenStorage? tokenStorage}) {
  final dependencies = AppDependencies.create(dio: backend.createDio(), tokenStorage: tokenStorage ?? TokenStorage.inMemory());
  return (app: AppState(session: dependencies.session), dependencies: dependencies);
}
