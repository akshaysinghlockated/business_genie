import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/parts.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/swap.dart';
import '../../data/models.dart';
import '../home/home_sections.dart';
import '../shell/tab_page.dart';
import 'meeting_sheet.dart';

/// The week: a strip of days with a dot where something is booked, the
/// chosen day's summary, then its agenda with a "now" line.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, this.day, this.embedded = false});

  /// True inside the Tasks tab's calendar view: the month and week arrows sit
  /// in a row of their own instead of a page header.
  final bool embedded;

  /// The day to open on; today when null.
  final DateTime? day;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _day = _dateOnly(widget.day ?? DateTime.now());
  bool _back = false;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime get _weekStart => _day.subtract(Duration(days: _day.weekday - 1));

  void _shift(int days) {
    setState(() {
      _back = days < 0;
      _day = _day.add(Duration(days: days));
    });
  }

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final month = GSwap(
      id: GFormat.month(_weekStart),
      reverse: _back,
      child: Text(GFormat.month(_weekStart), maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.h2.c(g.ink)),
    );
    final arrows = [
      GIconButton(icon: LucideIcons.chevronLeft, label: 'Previous week', onTap: () => _shift(-7)),
      const SizedBox(width: 8),
      GIconButton(icon: LucideIcons.chevronRight, label: 'Next week', onTap: () => _shift(7)),
    ];
    final content = GLoadView(
      builder: (context, data) {
        final now = DateTime.now();
        final days = [for (var i = 0; i < 7; i++) _weekStart.add(Duration(days: i))];
        final list = data.meetings.where((m) => GFormat.sameDay(m.start, _day)).toList()..sort((a, b) => a.start.compareTo(b.start));
        final booked = list.where((m) => !m.cancelled);
        final total = booked.fold<int>(0, (s, m) => s + m.minutes);
        return GRefresh(
          child: ListView(
            padding: const EdgeInsets.only(top: GSpace.l, bottom: GSpace.navClearance),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: GSpace.m),
                child: GSlide(
                  id: _weekStart,
                  forward: !_back,
                  child: _Week(
                    days: days,
                    selected: _day,
                    now: now,
                    busy: (d) => data.meetings.any((m) => GFormat.sameDay(m.start, d) && !m.cancelled),
                    onPick: (d) {
                      if (GFormat.sameDay(d, _day)) return;
                      GHaptics.select();
                      setState(() {
                        _back = d.isBefore(_day);
                        _day = d;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: GSpace.l),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: (e) {
                  final v = e.primaryVelocity ?? 0;
                  if (v.abs() < 250) return;
                  GHaptics.select();
                  _shift(v < 0 ? 1 : -1);
                },
                child: GSlide(
                  id: _day,
                  forward: !_back,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: GSpace.gutter),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: GFormat.dayName(_day, now), style: GType.h3.c(g.ink)),
                              TextSpan(
                                text: booked.isEmpty ? '' : '  ·  ${booked.length} meeting${booked.length == 1 ? '' : 's'} · ${GFormat.minutes(total)}',
                                style: GType.label.c(g.ink3),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: GSpace.m),
                      if (list.isEmpty)
                        GEmptyState(
                          icon: LucideIcons.coffee,
                          title: data.meetings.isEmpty ? 'No meetings yet' : 'Nothing booked',
                          body: data.meetings.isEmpty ? 'Connect your calendar on the web and your meetings show here.' : 'A good day for deep work.',
                          compact: true,
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: GSpace.gutter),
                          child: GCard(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(children: _agenda(context, list, now)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (widget.embedded) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(GSpace.gutter, 4, GSpace.gutter, 0),
            child: Row(
              children: [
                Expanded(
                  child: Align(alignment: Alignment.centerLeft, child: month),
                ),
                ...arrows,
              ],
            ),
          ),
          Expanded(child: content),
        ],
      );
    }
    return GPushPage(title: 'Calendar', titleWidget: month, actions: arrows, child: content);
  }

  List<Widget> _agenda(BuildContext context, List<Meeting> list, DateTime now) {
    final out = <Widget>[];
    final isToday = GFormat.sameDay(_day, now);
    var nowShown = !isToday;
    for (var i = 0; i < list.length; i++) {
      final m = list[i];
      if (!nowShown && m.start.isAfter(now)) {
        out.add(_NowLine(now: now));
        nowShown = true;
      } else if (i > 0) {
        out.add(const GRule(indent: 76));
      }
      out.add(_MeetingRow(meeting: m, now: now));
    }
    if (!nowShown) out.add(_NowLine(now: now));
    return out;
  }
}

/// The week as seven days with one ink circle that glides to the chosen
/// day. Today keeps a ring; a dot marks days with meetings.
class _Week extends StatelessWidget {
  const _Week({required this.days, required this.selected, required this.now, required this.busy, required this.onPick});

  final List<DateTime> days;
  final DateTime selected, now;
  final bool Function(DateTime) busy;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final at = days.indexWhere((d) => GFormat.sameDay(d, selected));
    final quick = GMotion.of(context, const Duration(milliseconds: 200));
    return LayoutBuilder(
      builder: (context, box) {
        final cell = box.maxWidth / 7;
        return SizedBox(
          height: 80,
          child: Stack(
            children: [
              if (at >= 0)
                AnimatedPositioned(
                  duration: GMotion.of(context, const Duration(milliseconds: 380)),
                  curve: GMotion.spatial,
                  left: cell * at + (cell - 40) / 2,
                  top: 24,
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(color: g.ink, shape: BoxShape.circle),
                  ),
                ),
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: GPressable(
                        haptic: false,
                        scale: .9,
                        selected: i == at,
                        semanticLabel:
                            '${GFormat.weekdayShort(days[i])} ${days[i].day}${GFormat.sameDay(days[i], now) ? ', today' : ''}${busy(days[i]) ? ', has meetings' : ''}',
                        onTap: () => onPick(days[i]),
                        child: Column(
                          children: [
                            SizedBox(height: 18, child: Text(GFormat.weekdayLetter(days[i]), style: GType.caption.c(g.ink3))),
                            const SizedBox(height: 6),
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: GFormat.sameDay(days[i], now) && i != at ? g.ink : Colors.transparent, width: 1.5),
                              ),
                              child: AnimatedDefaultTextStyle(duration: quick, style: GType.figure.c(i == at ? g.onInk : g.ink), child: Text('${days[i].day}')),
                            ),
                            const SizedBox(height: 6),
                            AnimatedContainer(
                              duration: quick,
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: busy(days[i]) ? (i == at ? g.ink : g.ink3) : Colors.transparent),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NowLine extends StatelessWidget {
  const _NowLine({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 54, child: Text(GFormat.time(now).split(' ').first, style: GType.micro.c(g.danger))),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: g.danger, shape: BoxShape.circle),
          ),
          Expanded(child: Container(height: 1.5, color: g.danger)),
        ],
      ),
    );
  }
}

class _MeetingRow extends StatelessWidget {
  const _MeetingRow({required this.meeting, required this.now});

  final Meeting meeting;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final m = meeting;
    final st = m.stateAt(now);
    final faded = st == MeetingState.done || st == MeetingState.cancelled;
    final t = GFormat.time(m.start).split(' ');
    return GPressable(
      scale: .985,
      semanticLabel: '${GFormat.time(m.start)}, ${m.title}, ${st.name}',
      onTap: () => showMeetingSheet(context, m),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.first, style: GType.figure.c(faded ? g.ink3 : g.ink)),
                  Text(t.last, style: GType.micro.c(g.ink3)),
                ],
              ),
            ),
            Container(width: 3, height: 40, margin: const EdgeInsets.only(right: 12), decoration: GShape.fill(faded ? g.ink4 : GFormat.dept(m.dept), 2)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          m.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GType.title.c(faded ? g.ink3 : g.ink).copyWith(decoration: st == MeetingState.cancelled ? TextDecoration.lineThrough : null),
                        ),
                      ),
                      if (st == MeetingState.live) ...[const SizedBox(width: 6), LiveTag(label: 'Live · ${m.end.difference(now).inMinutes.clamp(1, 999)}m')],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    st == MeetingState.cancelled ? 'Cancelled' : '${GFormat.minutes(m.minutes)} · ${m.place}${st == MeetingState.done ? ' · Completed' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GType.caption.c(st == MeetingState.cancelled ? g.danger : g.ink3),
                  ),
                  const SizedBox(height: 8),
                  GAvatarStack(names: m.people, size: 22),
                ],
              ),
            ),
            if (st == MeetingState.live && m.online) GButton(label: 'Join', compact: true, onTap: () => showMeetingSheet(context, m)),
          ],
        ),
      ),
    );
  }
}
