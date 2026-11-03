import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../data/models.dart';

/// Business Genie's signature: the working day on one strip, 9 AM to 9 PM.
/// Meetings are blocks (ink to come, faint once done, red while live, struck
/// when cancelled), timed tasks are small ticks above, and a red needle marks
/// now. The blocks grow in once, from the left, when the strip first shows.
class DayRibbon extends StatelessWidget {
  const DayRibbon({super.key, required this.meetings, required this.taskTimes, required this.now, this.height = 64});

  final List<Meeting> meetings;
  final List<DateTime> taskTimes;
  final DateTime now;
  final double height;

  static const startHour = 9, endHour = 21;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Semantics(
      label: 'Today from 9 AM to 9 PM: ${meetings.length} meetings, ${taskTimes.length} timed tasks',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: GMotion.of(context, const Duration(milliseconds: 900)),
        curve: GMotion.easeOut,
        builder: (context, grow, _) => SizedBox(
          height: height + 18,
          child: Column(
            children: [
              SizedBox(
                height: height,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _RibbonPainter(
                    meetings: meetings,
                    taskTimes: taskTimes,
                    now: now,
                    grow: grow,
                    ink: g.ink,
                    faint: g.ink4,
                    track: g.card,
                    rule: g.rule,
                    live: g.danger,
                    surface: g.surface,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final h in const [9, 12, 15, 18, 21])
                    Text(
                      h == 12 ? '12' : (h > 12 ? '${h - 12}' : '$h'),
                      style: GType.micro.c(g.ink3).copyWith(fontWeight: FontWeight.w500, fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  _RibbonPainter({
    required this.meetings,
    required this.taskTimes,
    required this.now,
    required this.grow,
    required this.ink,
    required this.faint,
    required this.track,
    required this.rule,
    required this.live,
    required this.surface,
  });

  final List<Meeting> meetings;
  final List<DateTime> taskTimes;
  final DateTime now;
  final double grow;
  final Color ink, faint, track, rule, live, surface;

  double _x(DateTime t, double w) {
    final mins = (t.hour - DayRibbon.startHour) * 60 + t.minute;
    return (mins / ((DayRibbon.endHour - DayRibbon.startHour) * 60)).clamp(0.0, 1.0) * w;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final bandTop = size.height * .34;
    final bandH = size.height * .5;
    final band = RRect.fromRectAndRadius(Rect.fromLTWH(0, bandTop, w, bandH), const Radius.circular(10));
    canvas.drawRRect(band, Paint()..color = track);

    // Hour ticks under the band.
    final tick = Paint()
      ..color = rule
      ..strokeWidth = 1;
    for (var h = DayRibbon.startHour; h <= DayRibbon.endHour; h++) {
      final x = (h - DayRibbon.startHour) / (DayRibbon.endHour - DayRibbon.startHour) * w;
      canvas.drawLine(Offset(x, bandTop + bandH + 3), Offset(x, bandTop + bandH + (h % 3 == 0 ? 8 : 5)), tick);
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w * grow, size.height));
    for (final m in meetings) {
      final st = m.stateAt(now);
      final x0 = _x(m.start, w), x1 = _x(m.end, w);
      if (x1 <= 0 || x0 >= w) continue;
      final left = x0.clamp(0.0, w - 6) + 1;
      final right = math.max(left + 4, math.min(x1 - 1, w));
      final r = RRect.fromRectAndRadius(Rect.fromLTRB(left, bandTop + 4, right, bandTop + bandH - 4), const Radius.circular(6));
      switch (st) {
        case MeetingState.live:
          canvas.drawRRect(r, Paint()..color = live);
        case MeetingState.done:
          canvas.drawRRect(r, Paint()..color = faint);
        case MeetingState.cancelled:
          canvas.drawRRect(
            r,
            Paint()
              ..color = faint
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2,
          );
        case MeetingState.next:
          canvas.drawRRect(r, Paint()..color = ink);
      }
    }
    // Timed tasks: small ticks above the band.
    for (final t in taskTimes) {
      final x = _x(t, w);
      canvas.drawCircle(Offset(x, bandTop - 8), 3, Paint()..color = t.isBefore(now) ? faint : ink);
    }
    canvas.restore();

    // The now needle.
    if (now.hour >= DayRibbon.startHour && now.hour < DayRibbon.endHour) {
      final x = _x(now, w);
      final p = Paint()
        ..color = live
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x, bandTop - 14), Offset(x, bandTop + bandH + 2), p);
      canvas.drawCircle(Offset(x, bandTop - 16), 4.5, Paint()..color = live);
      canvas.drawCircle(Offset(x, bandTop - 16), 2, Paint()..color = surface);
    }
  }

  @override
  bool shouldRepaint(_RibbonPainter old) => old.grow != grow || old.now != now || old.meetings != meetings || old.ink != ink;
}

/// "In 1 h 5 m", "in 12 min", "now".
String inTime(DateTime from, DateTime to) {
  final m = to.difference(from).inMinutes;
  if (m <= 0) return 'now';
  if (m < 60) return 'in $m min';
  return 'in ${GFormat.minutes(m)}';
}
