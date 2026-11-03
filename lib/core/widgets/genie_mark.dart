import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/palette.dart';

/// Business Genie's own mark: an open ring (a "G" drawn as a plan that isn't
/// closed yet) with the wish, a violet dot, sitting in its gap, about to
/// complete it. Drawn in code, so it is crisp at any size and owes nothing to
/// any other artwork.
class GenieMark extends StatelessWidget {
  const GenieMark({super.key, this.size = 24, this.mono, this.dot});

  final double size;

  /// The ring's colour (ink by default).
  final Color? mono;

  /// The wish's colour (Genie violet by default).
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Semantics(
      label: 'Business Genie',
      excludeSemantics: true,
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: GenieMarkPainter(ring: mono ?? g.ink, dot: dot ?? (mono ?? g.ai)),
          ),
        ),
      ),
    );
  }
}

class GenieMarkPainter extends CustomPainter {
  GenieMarkPainter({required this.ring, required this.dot});

  final Color ring, dot;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = Offset(size.width / 2, size.height / 2);
    final stroke = s * .15;
    final r = s / 2 - stroke / 2 - s * .06;
    // The ring opens at the upper right, from -78° to -4°.
    const gapStart = -math.pi * 78 / 180;
    const gap = math.pi * 74 / 180;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      gapStart + gap,
      2 * math.pi - gap,
      false,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
    // The crossbar of the G, reaching in from the ring's lower end.
    canvas.drawLine(
      Offset(c.dx + r * .12, c.dy + r * .02),
      Offset(c.dx + r, c.dy + r * .02),
      Paint()
        ..color = ring
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
    // The wish, in the gap.
    const mid = gapStart + gap / 2;
    canvas.drawCircle(c + Offset(math.cos(mid), math.sin(mid)) * r, stroke * .8, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(GenieMarkPainter old) => old.ring != ring || old.dot != dot;
}
