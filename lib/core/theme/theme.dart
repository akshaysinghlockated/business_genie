import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'palette.dart';
import 'tokens.dart';

/// Builds the app theme from a palette. Material is only the frame; screens
/// draw with `context.g` and [GType](type.dart).
ThemeData buildTheme(GPalette p, Brightness brightness) {
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  final text = GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: p.ink, displayColor: p.ink);
  return base.copyWith(
    scaffoldBackgroundColor: p.ground,
    canvasColor: p.surface,
    colorScheme: ColorScheme.fromSeed(seedColor: p.accent, brightness: brightness, surface: p.surface, primary: p.ink, onPrimary: p.onInk, error: p.danger),
    textTheme: text,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    textSelectionTheme: TextSelectionThemeData(cursorColor: p.ink, selectionColor: p.accentSoft, selectionHandleColor: p.ink),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: _RisePageTransitions(), TargetPlatform.iOS: CupertinoPageTransitionsBuilder()},
    ),
    extensions: [p],
  );
}

/// Android pushes: the new page fades in over the first part and rises a
/// little while settling from 0.97 scale. Reverse is quicker and plain.
class _RisePageTransitions extends PageTransitionsBuilder {
  const _RisePageTransitions();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 240);

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (GMotion.reduced(context)) return child;
    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, .45, curve: GMotion.effects),
      reverseCurve: GMotion.effects,
    );
    final move = CurvedAnimation(parent: animation, curve: GMotion.spatial, reverseCurve: GMotion.easeOut);
    return FadeTransition(
      opacity: fade,
      child: AnimatedBuilder(
        animation: move,
        child: child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (1 - move.value) * 24),
          child: Transform.scale(scale: .97 + .03 * move.value, child: child),
        ),
      ),
    );
  }
}
