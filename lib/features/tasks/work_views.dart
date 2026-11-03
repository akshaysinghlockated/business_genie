import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/genie_mark.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/parts.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/swap.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../calendar/meeting_sheet.dart';
import '../goals/goal_widgets.dart' show GoalCard, goalColor;
import '../people/person_sheet.dart';
import '../shell/routes.dart';
import '../shell/tab_page.dart';
import 'task_row.dart' show TickCircle;
import 'task_view.dart';

/// Minutes after midnight for a label like "10:30 AM"; null for "Fri".
int? dueMinutes(String? label) {
  if (label == null) return null;
  final m = RegExp(r'^(\d+):(\d+) (AM|PM)$').firstMatch(label);
  if (m == null) return null;
  var h = int.parse(m.group(1)!) % 12;
  if (m.group(3) == 'PM') h += 12;
  return h * 60 + int.parse(m.group(2)!);
}

bool _shown(Task t, TaskViewPrefs v) => switch (v.show) {
  TaskShow.all => true,
  TaskShow.mine => t.assigneeId == null,
  TaskShow.priority => t.priority,
  TaskShow.genie => t.byGenie,
};

BoxDecoration _card(GPalette g, [double r = 18]) => BoxDecoration(
  color: g.surface,
  borderRadius: BorderRadius.circular(r),
  boxShadow: const [BoxShadow(color: Color(0x0B000000), blurRadius: 22, offset: Offset(0, 6))],
);

// ─── Board ────────────────────────────────────────────────────────────────

/// Board: work in columns by when it is due. Long-press a card to move it.
class BoardView extends StatelessWidget {
  const BoardView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TaskViewPrefs>(
      valueListenable: taskView,
      builder: (context, view, _) => GLoadView(
        builder: (context, data) {
          final g = context.g;
          final tasks = data.tasks.where((t) => _shown(t, view)).toList();
          final cols = <(String, Color, List<Task>)>[
            ('Overdue', g.danger, tasks.where((t) => t.when == TaskWhen.overdue && !t.done && t.assigneeId == null).toList()),
            ('Today', g.ink, tasks.where((t) => t.when == TaskWhen.today && !t.done && t.assigneeId == null).toList()),
            ('Upcoming', g.accent, tasks.where((t) => t.when == TaskWhen.upcoming && !t.done && t.assigneeId == null).toList()),
            ('With the team', g.warning, tasks.where((t) => t.assigneeId != null && !t.done).toList()),
            ('Done', g.success, tasks.where((t) => t.done).toList()),
          ];
          for (final c in cols) {
            c.$3.sort((a, b) => (dueMinutes(a.due) ?? 9999).compareTo(dueMinutes(b.due) ?? 9999));
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(GSpace.gutter, 8, GSpace.gutter, 0),
            itemCount: cols.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _Column(title: cols[i].$1, color: cols[i].$2, tasks: cols[i].$3, data: data, compact: view.compact),
          );
        },
      ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({required this.title, required this.color, required this.tasks, required this.data, required this.compact});

  final String title;
  final Color color;
  final List<Task> tasks;
  final Snapshot data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return SizedBox(
      width: 262,
      child: Container(
        decoration: BoxDecoration(color: g.ink.withValues(alpha: .035), borderRadius: BorderRadius.circular(22)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 10),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(title, style: GType.label.c(g.ink).w(FontWeight.w600).copyWith(fontSize: 14.5)),
                  const SizedBox(width: 6),
                  Text('${tasks.length}', style: GType.caption.c(g.ink3)),
                ],
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text('Nothing here', style: GType.caption.c(g.ink3)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, GSpace.navClearance),
                      itemCount: tasks.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _BoardCard(task: tasks[i], assignee: data.person(tasks[i].assigneeId), compact: compact),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardCard extends StatelessWidget {
  const _BoardCard({required this.task, required this.assignee, required this.compact});

  final Task task;
  final Person? assignee;
  final bool compact;

  void _move(BuildContext context) {
    final app = context.appRead;
    GHaptics.heavy();
    showGSheet<void>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GSheetHeader(title: 'Move “${task.title}”'),
          for (final (label, icon, slot) in [('Today', LucideIcons.sun, TaskWhen.today), ('Upcoming', LucideIcons.calendarClock, TaskWhen.upcoming)])
            GRow(
              leading: Icon(icon, size: 20, color: sheet.g.ink),
              title: label,
              trailing: task.when == slot && !task.done ? Icon(LucideIcons.check, size: 18, color: sheet.g.ink) : null,
              onTap: () {
                app.moveTask(task.id, slot);
                Navigator.of(sheet).pop();
                GToast.show(context, 'Moved to $label');
              },
            ),
          GRow(
            leading: Icon(task.done ? LucideIcons.rotateCcw : LucideIcons.check, size: 20, color: sheet.g.ink),
            title: task.done ? 'Reopen' : 'Mark done',
            onTap: () {
              app.toggleTask(task.id);
              Navigator.of(sheet).pop();
            },
          ),
          SizedBox(height: MediaQuery.paddingOf(sheet).bottom + 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final t = task;
    final overdue = t.when == TaskWhen.overdue && !t.done;
    return GestureDetector(
      onLongPress: () => _move(context),
      child: GPressable(
        scale: .97,
        semanticLabel: '${t.title}. Long press to move',
        onTap: () => openTask(context, t.id),
        child: Container(
          padding: EdgeInsets.all(compact ? 10 : 12),
          decoration: _card(g, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TickCircle(
                    done: t.done,
                    size: 20,
                    onTap: () {
                      context.appRead.toggleTask(t.id);
                      GHaptics.select();
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.title,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: GType.label.copyWith(fontSize: 14, color: t.done ? g.ink3 : g.ink, decoration: t.done ? TextDecoration.lineThrough : null),
                    ),
                  ),
                  if (t.priority && !t.done) Icon(LucideIcons.flag, size: 14, color: g.warning),
                ],
              ),
              if (!compact) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (t.due != null) ...[
                      Icon(LucideIcons.clock, size: 12, color: overdue ? g.danger : g.ink3),
                      const SizedBox(width: 4),
                      Text(t.due!, style: GType.caption.c(overdue ? g.danger : g.ink2).copyWith(fontSize: 11.5)),
                      const SizedBox(width: 10),
                    ],
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: GFormat.dept(t.dept), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        GFormat.shortDept(t.dept),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GType.caption.c(g.ink3).copyWith(fontSize: 11.5),
                      ),
                    ),
                    const Spacer(),
                    if (t.byGenie)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GenieMark(size: 12, mono: g.ink3, dot: g.ai),
                      ),
                    if (assignee != null) GAvatar(name: assignee!.name, size: 22),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Timeline ─────────────────────────────────────────────────────────────

/// Timeline: today hour by hour, meetings and timed tasks as blocks, a line
/// at now. Opens scrolled to the current hour.
class TimelineView extends StatefulWidget {
  const TimelineView({super.key});

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  static const start = 8, end = 21, hour = 72.0;
  late final _scroll = ScrollController(initialScrollOffset: ((DateTime.now().hour - start - 1).clamp(0, end - start) * hour).toDouble());

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GLoadView(
      builder: (context, data) {
        final g = context.g;
        final now = DateTime.now();
        final meetings = data.meetings.where((m) => GFormat.sameDay(m.start, now)).toList();
        final tasks = data.tasks.where((t) => t.when == TaskWhen.today && t.assigneeId == null && dueMinutes(t.due) != null).toList();
        double y(int minutes) => (minutes - start * 60) / 60 * hour;
        final nowY = y(now.hour * 60 + now.minute);
        return LayoutBuilder(
          builder: (context, box) {
            const gutter = 60.0;
            final w = box.maxWidth - GSpace.gutter * 2 - gutter;
            return SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(GSpace.gutter, 12, GSpace.gutter, GSpace.navClearance),
              child: SizedBox(
                height: (end - start) * hour,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var h = start; h <= end; h++)
                      Positioned(
                        top: (h - start) * hour,
                        left: 0,
                        right: 0,
                        child: Row(
                          children: [
                            SizedBox(
                              width: gutter,
                              child: Transform.translate(
                                offset: const Offset(0, -8),
                                child: Text(h == 12 ? '12 PM' : (h > 12 ? '${h - 12} PM' : '$h AM'), style: GType.caption.c(g.ink3).copyWith(fontSize: 11.5)),
                              ),
                            ),
                            Expanded(child: Container(height: 1, color: g.rule)),
                          ],
                        ),
                      ),
                    for (final m in meetings)
                      _Block(
                        top: y(m.start.hour * 60 + m.start.minute),
                        height: (m.minutes / 60 * hour).clamp(30.0, 400.0),
                        left: gutter + 4,
                        width: w * .54 - 8,
                        title: m.title,
                        sub: m.cancelled ? 'Cancelled' : '${GFormat.time(m.start)} · ${GFormat.minutes(m.minutes)} · ${m.place}',
                        color: m.stateAt(now) == MeetingState.live ? g.danger : GFormat.dept(m.dept),
                        faded: m.stateAt(now) == MeetingState.done || m.cancelled,
                        icon: m.online ? LucideIcons.video : LucideIcons.mapPin,
                        onTap: () => showMeetingSheet(context, m),
                      ),
                    for (final t in tasks)
                      _Block(
                        top: y(dueMinutes(t.due)!),
                        height: ((t.minutes ?? 30) / 60 * hour).clamp(30.0, 300.0),
                        left: gutter + w * .54,
                        width: w * .46,
                        title: t.title,
                        sub: 'Task · ${t.due}',
                        color: g.ink,
                        faded: t.done,
                        icon: LucideIcons.squareCheckBig,
                        dashed: true,
                        onTap: () => openTask(context, t.id),
                      ),
                    if (now.hour >= start && now.hour < end)
                      Positioned(
                        top: nowY - 5,
                        left: gutter - 6,
                        right: 0,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: g.danger, shape: BoxShape.circle),
                            ),
                            Expanded(child: Container(height: 2, color: g.danger)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.top,
    required this.height,
    required this.left,
    required this.width,
    required this.title,
    required this.sub,
    required this.color,
    required this.faded,
    required this.icon,
    required this.onTap,
    this.dashed = false,
  });

  final double top, height, left, width;
  final String title, sub;
  final Color color;
  final bool faded, dashed;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Positioned(
      top: top + 1,
      left: left,
      width: width,
      height: height - 2,
      child: Opacity(
        opacity: faded ? .5 : 1,
        child: GPressable(
          scale: .97,
          semanticLabel: '$title, $sub',
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
            decoration: BoxDecoration(
              color: dashed ? g.surface : color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: color, width: 3)),
              boxShadow: dashed ? [BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 10, offset: const Offset(0, 3))] : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 12, color: g.ink2),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.label.c(g.ink).w(FontWeight.w600).copyWith(fontSize: 13)),
                    ),
                  ],
                ),
                if (height > 44) Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.caption.c(g.ink2).copyWith(fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Team workload ────────────────────────────────────────────────────────

/// Team: what each person carries for you: open, overdue and done, with
/// their tasks one tap away.
class TeamWorkView extends StatelessWidget {
  const TeamWorkView({super.key});

  @override
  Widget build(BuildContext context) {
    return GLoadView(
      builder: (context, data) {
        final g = context.g;
        if (data.people.isEmpty) {
          return ListView(
            padding: const EdgeInsets.only(top: GSpace.xl),
            children: [
              GEmptyState(
                icon: LucideIcons.users,
                title: 'No one to hand work to yet',
                body: 'Invite your department heads. Tasks you give them are tracked here.',
                action: 'Invite people',
                onAction: () => showWebOnly(context, 'Invitations', LucideIcons.userPlus),
              ),
            ],
          );
        }
        final rows = [for (final p in data.people) (p, data.tasks.where((t) => t.assigneeId == p.id).toList())]
          ..sort((a, b) => b.$2.where((t) => !t.done).length.compareTo(a.$2.where((t) => !t.done).length));
        final delegated = data.tasks.where((t) => t.assigneeId != null).toList();
        final open = delegated.where((t) => !t.done).length;
        final late = delegated.where((t) => t.when == TaskWhen.overdue && !t.done).length;
        final filed = data.people.where((p) => p.reportFiled).length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(GSpace.gutter, 8, GSpace.gutter, GSpace.navClearance),
          children: [
            Row(
              children: [
                _Stat(value: '$open', label: 'Open tasks'),
                const SizedBox(width: 10),
                _Stat(value: '$late', label: 'Overdue', color: late > 0 ? g.danger : null),
                const SizedBox(width: 10),
                _Stat(value: '$filed/${data.people.length}', label: 'Reported'),
              ],
            ),
            const SizedBox(height: 18),
            for (final (p, tasks) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PersonLoad(person: p, tasks: tasks),
              ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.color});

  final String value, label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Expanded(
      child: Container(
        height: 84,
        padding: const EdgeInsets.all(14),
        decoration: _card(g),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GType.numeral.c(color ?? g.ink).copyWith(fontSize: 24, height: 1)),
            const Spacer(),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.caption.c(g.ink3)),
          ],
        ),
      ),
    );
  }
}

class _PersonLoad extends StatefulWidget {
  const _PersonLoad({required this.person, required this.tasks});

  final Person person;
  final List<Task> tasks;

  @override
  State<_PersonLoad> createState() => _PersonLoadState();
}

class _PersonLoadState extends State<_PersonLoad> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final p = widget.person;
    final open = widget.tasks.where((t) => !t.done).toList();
    final late = open.where((t) => t.when == TaskWhen.overdue).length;
    final done = widget.tasks.length - open.length;
    final dot = p.live ? g.danger : (p.behind ? g.warning : (p.reportFiled ? g.success : null));
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _card(g, 20),
      child: Column(
        children: [
          GPressable(
            scale: .985,
            semanticLabel: '${p.name}, ${open.length} open',
            onTap: () {
              if (widget.tasks.isEmpty) return showPersonSheet(context, p);
              GHaptics.select();
              setState(() => _open = !_open);
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => showPersonSheet(context, p),
                        child: GAvatar(name: p.name, size: 42, dot: dot),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: GType.label.c(g.ink).w(FontWeight.w600).copyWith(fontSize: 14.5)),
                            Text(
                              p.live ? 'In a meeting' : (p.today ?? '${p.role} · ${GFormat.shortDept(p.dept)}'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GType.caption.c(p.live ? g.danger : g.ink3),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${open.length}', style: GType.numeral.c(g.ink).copyWith(fontSize: 20, height: 1)),
                          Text(late > 0 ? '$late overdue' : 'open', style: GType.caption.c(late > 0 ? g.danger : g.ink3).copyWith(fontSize: 11)),
                        ],
                      ),
                      if (widget.tasks.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: _open ? .5 : 0,
                          duration: GMotion.of(context, GMotion.enter),
                          curve: GMotion.easeOut,
                          child: Icon(LucideIcons.chevronDown, size: 18, color: g.ink3),
                        ),
                      ],
                    ],
                  ),
                  if (widget.tasks.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: 6,
                        child: Row(
                          children: [
                            if (done > 0)
                              Expanded(
                                flex: done,
                                child: Container(color: g.success),
                              ),
                            if (open.length - late > 0)
                              Expanded(
                                flex: open.length - late,
                                child: Container(color: g.ink.withValues(alpha: .7)),
                              ),
                            if (late > 0)
                              Expanded(
                                flex: late,
                                child: Container(color: g.danger),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '$done done · ${open.length - late} on time${late > 0 ? ' · $late late' : ''}',
                          style: GType.caption.c(g.ink3).copyWith(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Nothing handed over yet', style: GType.caption.c(g.ink3)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: GMotion.of(context, const Duration(milliseconds: 320)),
            curve: GMotion.easeOut,
            alignment: Alignment.topCenter,
            child: _open
                ? Column(
                    children: [
                      for (final t in widget.tasks)
                        GPressable(
                          scale: .985,
                          semanticLabel: t.title,
                          onTap: () => openTask(context, t.id),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: g.rule)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  t.done ? LucideIcons.circleCheck : LucideIcons.circle,
                                  size: 16,
                                  color: t.done ? g.success : (t.when == TaskWhen.overdue ? g.danger : g.ink3),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    t.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GType.label.copyWith(color: t.done ? g.ink3 : g.ink, decoration: t.done ? TextDecoration.lineThrough : null),
                                  ),
                                ),
                                if (t.due != null) Text(t.due!, style: GType.caption.c(t.when == TaskWhen.overdue && !t.done ? g.danger : g.ink3)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// ─── Goals ────────────────────────────────────────────────────────────────

/// Goals: every goal with its owner and progress, filtered by status.
class GoalsWorkView extends StatefulWidget {
  const GoalsWorkView({super.key});

  @override
  State<GoalsWorkView> createState() => _GoalsWorkViewState();
}

class _GoalsWorkViewState extends State<GoalsWorkView> {
  GoalStatus? _filter;

  @override
  Widget build(BuildContext context) {
    return GLoadView(
      builder: (context, data) {
        final g = context.g;
        if (data.goals.isEmpty) {
          return ListView(
            padding: const EdgeInsets.only(top: GSpace.xl),
            children: const [GEmptyState(icon: LucideIcons.target, title: 'No goals yet', body: 'Goals come from the business plan you set on the web.')],
          );
        }
        final counts = {for (final s in GoalStatus.values) s: data.goals.where((x) => x.status == s).length};
        final list = data.goals.where((x) => _filter == null || x.status == _filter).toList();
        return Column(
          children: [
            const SizedBox(height: 6),
            GChipRow(
              children: [
                GChip(label: 'All', count: data.goals.length, selected: _filter == null, onTap: () => setState(() => _filter = null)),
                for (final s in GoalStatus.values)
                  if (counts[s]! > 0) GChip(label: s.label, count: counts[s], selected: _filter == s, onTap: () => setState(() => _filter = s)),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GSwap(
                id: _filter?.name ?? 'all',
                alignment: Alignment.topCenter,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(GSpace.gutter, 4, GSpace.gutter, GSpace.navClearance),
                  children: [
                    for (final x in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GoalCard(goal: x, owner: data.person(x.ownerId)),
                      ),
                    if (list.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Center(child: Text('No goals with this status', style: GType.label.c(g.ink3))),
                      ),
                    if (_filter == null && counts[GoalStatus.behind]! > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: goalColor(GoalStatus.behind, g), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text('${counts[GoalStatus.behind]} behind. Ask Genie what would bring them back.', style: GType.caption.c(g.ink3))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
