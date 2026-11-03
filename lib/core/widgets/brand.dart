import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/palette.dart';
import '../theme/tokens.dart';

/// The prototype's glass and ambient values, by brightness (--glass, --rim,
/// --rim2, --thumb, --edge, --shadow2, --amb1, --amb2).
class GLook {
  const GLook._(this.glass, this.glassSolid, this.rim, this.rim2, this.thumb, this.edge, this.shadow2, this.amb1, this.amb2);

  final Color glass, glassSolid, rim, rim2, thumb, edge, shadow2, amb1, amb2;

  static const _light = GLook._(
    Color(0x94FFFFFF),
    Color(0xFFFFFFFF),
    Color(0xF2FFFFFF),
    Color(0x80FFFFFF),
    Color(0xFFFFFFFF),
    Color(0x1218181A),
    Color(0x0D1E1C18),
    Color(0x29A0968C),
    Color(0x248C96AA),
  );

  static const _dark = GLook._(
    Color(0x8028282C),
    Color(0xFF1E1E21),
    Color(0x33FFFFFF),
    Color(0x0FFFFFFF),
    Color(0x24FFFFFF),
    Color(0x0FFFFFFF),
    Color(0x4D000000),
    Color(0x24786E64),
    Color(0x295A6482),
  );

  static GLook of(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? _dark : _light;
}

/// Two soft, warm light pools behind everything, as in the prototype. They
/// drift with [shift] (the pager position) so the page feels deep.
class GAmbient extends StatelessWidget {
  const GAmbient({super.key, this.shift = 0});

  final double shift;

  @override
  Widget build(BuildContext context) {
    final look = GLook.of(context);
    return IgnorePointer(
      child: RepaintBoundary(
        child: Transform.translate(
          offset: Offset(-shift * 60, 0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-.55, -.75),
                radius: .7,
                colors: [look.amb1, look.amb1.withValues(alpha: 0)],
                stops: const [0, .72],
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(.6, .25),
                  radius: .8,
                  colors: [look.amb2, look.amb2.withValues(alpha: 0)],
                  stops: const [0, .72],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

/// The prototype's glass: blurred, translucent, with a bright rim that
/// catches light at the top-left and a soft shadow outside.
class GProtoGlass extends StatelessWidget {
  const GProtoGlass({super.key, required this.child, this.radius = GRadius.pill, this.circle = false, this.solid = false});

  final Widget child;
  final double radius;
  final bool circle;

  /// Use the near-opaque glass (no blur), for things over busy content.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final look = GLook.of(context);
    final shape = circle ? const CircleBorder() : GShape.of(radius);
    final fill = DecoratedBox(
      decoration: ShapeDecoration(color: solid ? look.glassSolid : look.glass, shape: shape),
      child: CustomPaint(foregroundPainter: _RimPainter(shape, look.rim, look.rim2, look.edge), child: child),
    );
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: [
          BoxShadow(color: g.shadow, blurRadius: 28, spreadRadius: -14, offset: const Offset(0, 10)),
          BoxShadow(color: look.shadow2, blurRadius: 2, offset: const Offset(0, 1)),
        ],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: solid ? fill : BackdropFilter.grouped(filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24), child: fill),
      ),
    );
  }
}

class _RimPainter extends CustomPainter {
  _RimPainter(this.shape, this.rim, this.rim2, this.edge);

  final ShapeBorder shape;
  final Color rim, rim2, edge;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = shape.getOuterPath(rect.deflate(.5));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .5
        ..color = edge,
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: const Alignment(-1, -1),
          end: const Alignment(1, 1),
          colors: [rim, rim.withValues(alpha: 0), rim2.withValues(alpha: 0), rim2],
          stops: const [0, .34, .64, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_RimPainter old) => old.rim != rim || old.rim2 != rim2 || old.edge != edge || old.shape != shape;
}

/// A white card with the prototype's hairline and soft lift.
BoxDecoration gProtoCard(BuildContext context, {double radius = 20, bool lift = true}) {
  final g = context.g;
  return BoxDecoration(
    color: g.surface,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(color: g.rule, spreadRadius: 1),
      if (lift) BoxShadow(color: g.shadow.withValues(alpha: .7), blurRadius: 24, spreadRadius: -16, offset: const Offset(0, 8)),
    ],
  );
}

/// The prototype's "materialise" entrance: content fades in rising 10 px from
/// 0.98 scale and clears from an 8 px blur. Plays once; nothing under
/// reduced motion.
extension GMaterialize on Widget {
  Widget materialize({Duration delay = Duration.zero, Duration duration = const Duration(milliseconds: 600), bool blur = true}) {
    return Builder(
      builder: (context) {
        if (GMotion.reduced(context)) return this;
        var a = animate(delay: delay)
            .fadeIn(duration: duration, curve: GMotion.easeOut)
            .moveY(begin: 10, end: 0, duration: duration, curve: GMotion.easeOut)
            .scaleXY(begin: .98, end: 1, duration: duration, curve: GMotion.easeOut);
        if (blur) a = a.blur(begin: const Offset(8, 8), end: Offset.zero, duration: duration * .8, curve: GMotion.easeOut);
        return a;
      },
    );
  }

  /// A message bubble arriving on a spring from its corner.
  Widget pop({Alignment origin = Alignment.bottomRight}) {
    return Builder(
      builder: (context) {
        if (GMotion.reduced(context)) return this;
        return animate()
            .fadeIn(duration: 200.ms)
            .scale(begin: const Offset(.85, .85), end: const Offset(1, 1), alignment: origin, duration: 500.ms, curve: GMotion.spatial);
      },
    );
  }
}
