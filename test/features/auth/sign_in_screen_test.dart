import 'package:business_genie/app.dart';
import 'package:business_genie/data/app_state.dart';
import 'package:business_genie/features/auth/presentation/screens/notice_screen.dart';
import 'package:business_genie/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_backend.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  /// Opens the app on the sign-in screen, past the splash.
  Future<AppState> openSignIn(WidgetTester tester, FakeBackend backend) async {
    final (:app, dependencies: _) = buildTestApp(backend);
    await tester.runAsync(app.init);
    await tester.binding.setSurfaceSize(const Size(400, 860));
    await tester.pumpWidget(BusinessGenieApp(state: app));
    for (var frame = 0; frame < 40 && find.byType(SignInScreen).evaluate().isEmpty; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);
    return app;
  }

  /// Lets the fake network answer and the screens animate.
  Future<void> waitForNetworkAndAnimations(WidgetTester tester) async {
    for (var step = 0; step < 6; step++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('email, then code, then signed in', (tester) async {
    final backend = workingBackend();
    final app = await openSignIn(tester, backend);

    await tester.enterText(find.byType(TextField).first, 'neha@northwind.test');
    await tester.tap(find.text('Send code'));
    await waitForNetworkAndAnimations(tester);
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.textContaining('Resend code in'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).last, '123456');
    await waitForNetworkAndAnimations(tester);
    expect(app.live, isTrue);
    expect(backend.requestedRoutes, containsAllInOrder(['POST /auth/login', 'POST /auth/login/verify', 'GET /onboarding']));
    expect(find.byType(NoticeScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('a new email gets the web sign-up sheet', (tester) async {
    final backend = workingBackend()..answer('POST /auth/login', 404, {'ok': false, 'error': 'No account.', 'no_account': true});
    await openSignIn(tester, backend);

    await tester.enterText(find.byType(TextField).first, 'new@x.test');
    await tester.tap(find.text('Send code'));
    await waitForNetworkAndAnimations(tester);
    expect(find.text('No account for this email yet'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('trying the demo signs in without the network', (tester) async {
    final backend = workingBackend();
    final app = await openSignIn(tester, backend);

    await tester.tap(find.text('Try the demo'));
    await waitForNetworkAndAnimations(tester);
    expect(app.demo, isTrue);
    expect(find.byType(NoticeScreen), findsOneWidget);
    expect(backend.requests, isEmpty);
    await tester.pump(const Duration(seconds: 2));
  });
}
