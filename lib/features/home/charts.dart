import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';

/// The last 30 days as three rows of pills: ink where the day's plan was
/// met, grey where some work was done, an outline for days off. Today is
/// ringed. They fill in one after another.
class ActivityGrid extends StatelessWidget {
  const ActivityGrid({super.key, required this.days});

  final List<int> days;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: GMotion.of(context, const Duration(milliseconds: 900)),
      curve: Curves.easeOut,
      builder: (context, t, _) => Column(
        children: [
          for (var r = 0; r < 3; r++) ...[
            if (r > 0) const SizedBox(height: 7),
            Row(
              children: [
                for (var c = 0; c < 10; c++) ...[if (c > 0) const SizedBox(width: 6), Expanded(child: _cell(g, r * 10 + c, t))],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _cell(GPalette g, int i, double t) {
    final v = i < days.length ? days[i] : 0;
    final show = ((t * 36) - i).clamp(0.0, 6.0) / 6;
    final today = i == days.length - 1;
    return Opacity(
      opacity: show,
      child: Container(
        height: 22,
        decoration: BoxDecoration(
          color: switch (v) {
            2 => g.ink,
            1 => g.ink.withValues(alpha: .26),
            -1 => Colors.transparent,
            _ => g.card,
          },
          borderRadius: BorderRadius.circular(11),
          border: today ? Border.all(color: g.accent, width: 2) : (v == -1 ? Border.all(color: g.ruleStrong, width: 1.2) : null),
        ),
      ),
    );
  }
}

/// A smooth line over a soft fill, drawn left to right once.
class TrendArea extends StatelessWidget {
  const TrendArea({super.key, required this.values, this.height = 70});

  final List<double> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: GMotion.of(context, const Duration(milliseconds: 1100)),
      curve: GMotion.easeOut,
      builder: (context, t, _) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _TrendPainter(values, t, g.ink, g.surface)),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values, this.t, this.ink, this.surface);

  final List<double> values;
  final double t;
  final Color ink, surface;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final lo = values.reduce(math.min), hi = values.reduce(math.max);
    final span = (hi - lo).abs() < 1e-6 ? 1 : hi - lo;
    final pts = [
      for (var i = 0; i < values.length; i++)
        Offset(i / (values.length - 1) * (size.width - 10), size.height - 8 - (values[i] - lo) / span * (size.height - 20)),
    ];
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = i == 0 ? pts[i] : pts[i - 1], p1 = pts[i], p2 = pts[i + 1], p3 = i + 2 < pts.length ? pts[i + 2] : p2;
      line.cubicTo(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6, p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6, p2.dx, p2.dy);
    }
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * t, size.height));
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ink.withValues(alpha: .16), ink.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
    if (t > .98) {
      final end = pts.last;
      canvas.drawCircle(end, 5.5, Paint()..color = surface);
      canvas.drawCircle(end, 3.5, Paint()..color = ink);
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.t != t || old.values != values || old.ink != ink;
}

/// Seven days as bars with their count on top; today in ink, the past in
/// grey, days still to come as a short stub.
class WeekBars extends StatelessWidget {
  const WeekBars({super.key, required this.values, required this.today, this.height = 72});

  /// Counts from Monday; may be shorter than seven.
  final List<int> values;

  /// 0 for Monday … 6 for Sunday.
  final int today;
  final double height;

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final top = values.isEmpty ? 1 : values.reduce(math.max).clamp(1, 1 << 30);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: GMotion.of(context, const Duration(milliseconds: 900)),
      curve: GMotion.easeOut,
      builder: (context, t, _) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (i <= today && i < values.length)
                    Text('${values[i]}', style: GType.micro.c(i == today ? g.ink : g.ink3).copyWith(fontSize: 9.5, letterSpacing: 0)),
                  const SizedBox(height: 3),
                  Container(
                    height: i <= today && i < values.length ? math.max(4, height * values[i] / top * t) : 4,
                    decoration: BoxDecoration(
                      color: i == today ? g.ink : (i < today ? g.ink.withValues(alpha: .16) : g.card),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(_days[i], style: GType.micro.c(i == today ? g.ink : g.ink3).copyWith(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
