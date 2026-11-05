import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/palette.dart';
import 'core/theme/theme.dart';
import 'core/theme/tokens.dart';
import 'data/app_state.dart';
import 'features/auth/presentation/screens/notice_screen.dart';
import 'features/auth/presentation/screens/setup_on_web_screen.dart';
import 'features/auth/presentation/screens/sign_in_screen.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/shell/shell.dart';

class BusinessGenieApp extends StatelessWidget {
  const BusinessGenieApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => MaterialApp(
          title: 'Business Genie',
          debugShowCheckedModeBanner: false,
          themeMode: state.themeMode,
          theme: buildTheme(GPalette.light, Brightness.light),
          darkTheme: buildTheme(GPalette.dark, Brightness.dark),
          themeAnimationDuration: GMotion.enter,
          themeAnimationCurve: GMotion.effects,
          home: const _Root(),
        ),
      ),
    );
  }
}

/// Splash first, then sign-in, the data notice once, then the app. Each step
/// fades through to the next.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final Widget page;
    final String id;
    if (!_splashDone) {
      page = GSplash(onDone: () => setState(() => _splashDone = true));
      id = 'splash';
    } else if (!app.signedIn) {
      page = const SignInScreen();
      id = 'signin';
    } else if (app.setupPending) {
      page = const SetupOnWebScreen();
      id = 'setup';
    } else if (!app.noticeAccepted) {
      page = const NoticeScreen();
      id = 'notice';
    } else {
      page = Shell(key: shellKey);
      id = 'shell';
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      child: AnimatedSwitcher(
        duration: GMotion.of(context, const Duration(milliseconds: 420)),
        switchInCurve: const Interval(.3, 1, curve: GMotion.easeOut),
        switchOutCurve: const Interval(.6, 1),
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: ScaleTransition(scale: Tween(begin: .985, end: 1.0).animate(a), child: child),
        ),
        child: KeyedSubtree(key: ValueKey(id), child: page),
      ),
    );
  }
}
