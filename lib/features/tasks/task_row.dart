import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets/genie_mark.dart';
import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/parts.dart';
import '../../core/widgets/pressable.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../shell/routes.dart';
import 'task_view.dart';

/// A task row. Swipe right to finish, swipe left to start the clock; the row
/// follows the finger and springs home. Tick, title, when, department and
/// length sit on the same lines for every row so lists line up.
class TaskRow extends StatelessWidget {
  const TaskRow({super.key, required this.task, this.view = const TaskViewPrefs()});

  final Task task;

  /// Compact mode and which fields to show, from Manage view.
  final TaskViewPrefs view;

  void _toggle(BuildContext context) {
    final app = context.appRead;
    app.toggleTask(task.id);
    GHaptics.select();
    if (task.done) {
      GToast.show(context, 'Done: ${task.title}', action: 'Undo', onAction: () => app.toggleTask(task.id));
    }
  }

  void _timer(BuildContext context) {
    final app = context.appRead;
    if (app.runningTaskId == task.id) {
      app.stopTimer();
      GToast.show(context, 'Clock stopped', type: GToastType.info);
    } else {
      app.startTimer(task.id);
      GHaptics.heavy();
      GToast.show(context, 'Clock started on “${task.title}”', type: GToastType.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final app = context.app;
    final t = task;
    final running = app.runningTaskId == t.id;
    final assignee = app.data?.person(t.assigneeId);
    return Dismissible(
      key: ValueKey('swipe-${t.id}'),
      direction: t.done ? DismissDirection.startToEnd : DismissDirection.horizontal,
      dismissThresholds: const {DismissDirection.startToEnd: .3, DismissDirection.endToStart: .3},
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          _toggle(context);
        } else {
          _timer(context);
        }
        return false;
      },
      background: _SwipeBg(color: g.success, icon: t.done ? LucideIcons.rotateCcw : LucideIcons.check, label: t.done ? 'Reopen' : 'Done', left: true),
      secondaryBackground: _SwipeBg(color: g.ink, icon: running ? LucideIcons.pause : LucideIcons.play, label: running ? 'Stop' : 'Start', left: false),
      child: GPressable(
        scale: .985,
        semanticLabel: '${t.title}${t.done ? ', done' : ''}',
        onTap: () => openTask(context, t.id),
        child: ColoredBox(
          color: g.surface,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: GSpace.gutter, vertical: view.compact ? 12 : 18),
            child: Row(
              children: [
                TickCircle(done: t.done, size: view.compact ? 22 : 26, onTap: () => _toggle(context)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: GMotion.quick,
                        style: GType.title.c(t.done ? g.ink3 : g.ink).w(FontWeight.w500).copyWith(decoration: t.done ? TextDecoration.lineThrough : null),
                        child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (!view.compact) const SizedBox(height: 4),
                      if (!view.compact)
                        Row(
                          children: [
                            if (t.when == TaskWhen.overdue && !t.done) ...[
                              Text('Overdue${t.due == null || !view.time ? '' : ' · ${t.due}'}', style: GType.caption.c(g.danger)),
                              if (view.department || (view.length && t.minutes != null)) _sep(g),
                            ] else if (t.due != null && view.time) ...[
                              Text(t.due!, style: GType.caption.c(g.ink2)),
                              if (view.department || (view.length && t.minutes != null)) _sep(g),
                            ],
                            if (view.department) ...[
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(color: GFormat.dept(t.dept), shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(GFormat.shortDept(t.dept), maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.caption.c(g.ink3)),
                              ),
                            ],
                            if (t.minutes != null && view.length) ...[
                              if (view.department) _sep(g),
                              Text(GFormat.minutes(t.minutes!), style: GType.caption.c(g.ink3)),
                            ],
                            if (t.private) ...[const SizedBox(width: 6), Icon(LucideIcons.lock, size: 12, color: g.ink3)],
                            if (t.byGenie) ...[const SizedBox(width: 6), GenieMark(size: 13, mono: g.ink3, dot: g.ai)],
                          ],
                        ),
                      if (running) ...[const SizedBox(height: 6), _Elapsed(since: app.runningSince!)],
                    ],
                  ),
                ),
                if (assignee != null) ...[const SizedBox(width: 8), GAvatar(name: assignee.name, size: 26)],
                if (t.priority && !t.done) ...[const SizedBox(width: 8), Icon(LucideIcons.flag, size: 16, color: g.warning)],
                if (view.compact && view.time && t.due != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(t.due!, style: GType.caption.c(t.when == TaskWhen.overdue && !t.done ? g.danger : g.ink3)),
                  ),
                if (!t.done && assignee == null && view.timer)
                  GPressable(
                    scale: .88,
                    haptic: false,
                    semanticLabel: running ? 'Stop the clock' : 'Start the clock',
                    onTap: () => _timer(context),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: AnimatedContainer(
                        duration: GMotion.quick,
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(color: running ? g.ink : g.card, shape: BoxShape.circle),
                        child: Icon(running ? LucideIcons.pause : LucideIcons.play, size: 15, color: running ? g.onInk : g.ink),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sep(GPalette g) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Text('·', style: GType.caption.c(g.ink4)),
  );
}

/// The round tick. Fills and draws its check with a selection haptic.
class TickCircle extends StatelessWidget {
  const TickCircle({super.key, required this.done, required this.onTap, this.size = 26});

  final bool done;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return GPressable(
      scale: .85,
      haptic: false,
      semanticLabel: done ? 'Mark as not done' : 'Mark as done',
      onTap: onTap,
      child: AnimatedContainer(
        duration: GMotion.of(context, GMotion.quick),
        curve: GMotion.effects,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? g.success : Colors.transparent,
          border: Border.all(color: done ? g.success : g.ink4, width: 1.8),
        ),
        child: AnimatedScale(
          scale: done ? 1 : 0,
          duration: GMotion.of(context, const Duration(milliseconds: 220)),
          curve: GMotion.spatial,
          child: Icon(LucideIcons.check, size: size * .6, color: Colors.white),
        ),
      ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  const _SwipeBg({required this.color, required this.icon, required this.label, required this.left});

  final Color color;
  final IconData icon;
  final String label;
  final bool left;

  @override
  Widget build(BuildContext context) {
    final fg = context.g.surface;
    return Container(
      color: color,
      alignment: left ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: GSpace.xl),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 8),
          Text(label, style: GType.label.c(fg).w(FontWeight.w600)),
        ],
      ),
    );
  }
}

/// The running clock under a task. Ticks once a second only while shown.
class _Elapsed extends StatefulWidget {
  const _Elapsed({required this.since});

  final DateTime since;

  @override
  State<_Elapsed> createState() => _ElapsedState();
}

class _ElapsedState extends State<_Elapsed> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && TickerMode.valuesOf(context).enabled) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final d = DateTime.now().difference(widget.since);
    final s = '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: GShape.fill(g.ink, GRadius.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.timer, size: 12, color: g.onInk),
          const SizedBox(width: 5),
          Text(s, style: GType.micro.c(g.onInk).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}
