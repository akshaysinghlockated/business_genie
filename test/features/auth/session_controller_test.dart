import 'package:business_genie/core/network/api_client.dart';
import 'package:business_genie/core/network/api_exception.dart';
import 'package:business_genie/core/storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  const email = 'neha@northwind.test';
  const sampleDataDelay = Duration(milliseconds: 1000);

  test('signed out, only the sign-in calls leave the phone', () async {
    final backend = workingBackend();
    final (:app, :dependencies) = buildTestApp(backend);
    await app.init();

    expect(app.signedIn, isFalse);
    await expectLater(
      dependencies.apiClient.get('/auth/me'),
      throwsA(isA<ApiException>().having((error) => error.statusCode, 'statusCode', 401)),
    );
    expect(backend.requests, isEmpty);
  });

  test('requesting a code sends the cleaned-up email without a token', () async {
    final backend = workingBackend();
    final (:app, dependencies: _) = buildTestApp(backend);
    await app.init();

    final codeRequest = await app.session.requestCode(' Neha@Northwind.test ');

    expect(codeRequest.sentTo, email);
    expect(backend.requests.single.data, {'email': email});
    expect(backend.requests.single.headers.containsKey('Authorization'), isFalse);
  });

  test('an unknown email is a no-account error', () async {
    final backend = workingBackend()
      ..answer('POST /auth/login', 404, {'ok': false, 'error': 'No account for that email.', 'no_account': true});
    final (:app, dependencies: _) = buildTestApp(backend);
    await app.init();

    await expectLater(
      app.session.requestCode('who@x.test'),
      throwsA(isA<ApiException>().having((error) => error.isNoAccount, 'isNoAccount', isTrue)),
    );
  });

  test('a right code keeps the token, the person and the company', () async {
    final backend = workingBackend();
    final (:app, :dependencies) = buildTestApp(backend);
    await app.init();

    await app.session.verifyCode(email: email, code: '123456');

    expect(await dependencies.tokenStorage.readToken(), 'tok-1');
    expect(await dependencies.tokenStorage.readLastEmail(), email);
    expect(app.live, isTrue);
    expect(app.setupPending, isFalse);
    expect(app.session.user!.fullName, 'Neha Kulkarni');
    expect(app.session.organization!.name, 'Northwind Traders');
    final onboardingRequest = backend.requests.firstWhere((request) => request.path == '/onboarding');
    expect(onboardingRequest.headers['Authorization'], 'Bearer tok-1');

    // The sample data is shown for the real person and company.
    await Future<void>.delayed(sampleDataDelay);
    expect(app.data!.owner.name, 'Neha Kulkarni');
    expect(app.data!.owner.role, 'Employee');
    expect(app.data!.company, 'Northwind Traders');
  });

  test('a wrong code shows the backend sentence and keeps nothing', () async {
    final backend = workingBackend()..answer('POST /auth/login/verify', 422, {'ok': false, 'error': 'That code is wrong or has expired.'});
    final (:app, :dependencies) = buildTestApp(backend);
    await app.init();

    await expectLater(
      app.session.verifyCode(email: email, code: '000000'),
      throwsA(isA<ApiException>().having((error) => error.message, 'message', 'That code is wrong or has expired.')),
    );
    expect(await dependencies.tokenStorage.readToken(), isNull);
    expect(app.signedIn, isFalse);
  });

  test('a company not set up yet waits for the web', () async {
    final backend = workingBackend()..answer('GET /onboarding', 200, {'ok': true, 'workspace': true, 'step': 'products'});
    final (:app, dependencies: _) = buildTestApp(backend);
    await app.init();

    await app.session.verifyCode(email: email, code: '123456');

    expect(app.signedIn, isTrue);
    expect(app.setupPending, isTrue);
    expect(app.data, isNull);
  });

  test('a stored token restores the session, and a 401 signs out', () async {
    final backend = workingBackend();
    final tokenStorage = TokenStorage.inMemory();
    await tokenStorage.saveToken('tok-old', expiresAt: DateTime.now().add(const Duration(days: 3)));
    final (:app, dependencies: _) = buildTestApp(backend, tokenStorage: tokenStorage);
    await app.init();
    expect(app.signedIn, isTrue);

    await app.session.refresh();
    expect(app.session.user!.firstName, 'Neha');

    backend.answer('GET /auth/me', 401, {'ok': false, 'error': 'Sign in again.'});
    await app.session.refresh();
    expect(app.signedIn, isFalse);
    expect(await tokenStorage.readToken(), isNull);
    expect(app.session.takeSignInNotice(), isNotNull);
  });

  test('an expired token is dropped at launch without a call', () async {
    final backend = workingBackend();
    final tokenStorage = TokenStorage.inMemory();
    await tokenStorage.saveToken('tok-old', expiresAt: DateTime.now().subtract(const Duration(minutes: 1)));
    final (:app, dependencies: _) = buildTestApp(backend, tokenStorage: tokenStorage);
    await app.init();

    expect(app.signedIn, isFalse);
    expect(await tokenStorage.readToken(), isNull);
    expect(backend.requests, isEmpty);
  });

  test('the demo makes no calls, and leaving it signs out', () async {
    final backend = workingBackend();
    final (:app, dependencies: _) = buildTestApp(backend);
    await app.init();

    await app.session.startDemo();
    expect(app.signedIn && app.demo, isTrue);
    await Future<void>.delayed(sampleDataDelay);
    expect(app.data, isNotNull);
    expect(backend.requests, isEmpty);

    app.signOut();
    expect(app.signedIn || app.demo, isFalse);
  });

  test('only the allowed paths can be written', () {
    expect(ApiClient.canWrite('/auth/login'), isTrue);
    expect(ApiClient.canWrite('/auth/login/verify'), isTrue);
    expect(ApiClient.canWrite('/auth/signup'), isFalse);
    expect(ApiClient.canWrite('/organization'), isFalse);
  });
}
