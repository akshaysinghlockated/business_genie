import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Spacing on a 4-point grid. The page's side margin is [gutter].
abstract final class GSpace {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double gutter = 20;

  /// Room left under scrolling content so the round create button never
  /// covers the last row.
  static const double navClearance = 160;
}

/// Corner radii. Shapes use continuous (superellipse) corners, see [GShape].
abstract final class GRadius {
  static const double chip = 12;
  static const double tile = 16;
  static const double card = 22;
  static const double sheet = 28;
  static const double pill = 999;
}

abstract final class GShape {
  static RoundedSuperellipseBorder of(double r, {BorderSide side = BorderSide.none}) =>
      RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(r), side: side);

  static ShapeDecoration fill(Color color, double r, {BorderSide side = BorderSide.none}) => ShapeDecoration(
    color: color,
    shape: of(r, side: side),
  );

  /// A white card lifted by a soft shadow instead of a hairline.
  static ShapeDecoration lifted(Color color, double r) => ShapeDecoration(
    color: color,
    shape: of(r),
    shadows: const [BoxShadow(color: Color(0x0B000000), blurRadius: 22, offset: Offset(0, 6))],
  );
}

/// Motion tokens. Timed curves for sequences nobody interrupts, springs for
/// anything a finger drives. UI motion stays at or under 320 ms.
abstract final class GMotion {
  /// The default. Ease-in is never used on UI.
  static const Curve easeOut = Cubic(.23, 1, .32, 1);
  static const Curve easeInOut = Cubic(.77, 0, .175, 1);

  /// Material 3 emphasised decelerate, for sheets.
  static const Curve sheet = Cubic(.05, .70, .10, 1);

  /// Things moving in space; may overshoot a hair.
  static const Curve spatial = Cubic(.27, 1.06, .18, 1);

  /// Opacity and colour; never overshoots.
  static const Curve effects = Cubic(.34, .80, .34, 1);

  static const Duration press = Duration(milliseconds: 120);
  static const Duration fadeOut = Duration(milliseconds: 100);
  static const Duration quick = Duration(milliseconds: 200);
  static const Duration enter = Duration(milliseconds: 280);
  static const Duration sheetIn = Duration(milliseconds: 320);
  static const Duration stagger = Duration(milliseconds: 50);

  /// Lively moves with a small overshoot (press release, flicks).
  static final SpringDescription springFast = SpringDescription.withDampingRatio(mass: 1, stiffness: 800, ratio: .6);

  /// Default finger-driven moves (tab highlight, thumbs).
  static final SpringDescription spring = SpringDescription.withDampingRatio(mass: 1, stiffness: 380, ratio: .8);

  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [d], or zero when the person has asked for reduced motion.
  static Duration of(BuildContext context, Duration d) => reduced(context) ? Duration.zero : d;
}

/// Three haptics only. A second haptic within 40 ms is dropped, so one touch
/// gives one tick even when nested handlers both ask for one.
abstract final class GHaptics {
  static DateTime _last = DateTime(0);
  static int count = 0;

  static bool _gate() {
    final now = DateTime.now();
    if (now.difference(_last).inMilliseconds < 40) return false;
    _last = now;
    count++;
    return true;
  }

  /// Presses, toasts, sheets.
  static void light() {
    if (_gate()) HapticFeedback.lightImpact();
  }

  /// Tabs, segments, chips, ticks.
  static void select() {
    if (_gate()) HapticFeedback.selectionClick();
  }

  /// Landings, completions, errors.
  static void heavy() {
    if (_gate()) HapticFeedback.mediumImpact();
  }
}
