import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/parts.dart';
import '../../core/widgets/swap.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';

/// One task: status, who, when, how long, notes; move it, flag it, time it,
/// finish it. Delete asks once and offers Undo.
class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final app = context.app;
    final data = app.data;
    final t = data?.tasks.where((t) => t.id == taskId).firstOrNull;
    if (t == null) {
      return Scaffold(backgroundColor: g.surface, body: const SizedBox.shrink());
    }
    final assignee = data!.person(t.assigneeId);
    final running = app.runningTaskId == t.id;
    final (statusLabel, statusTone) = t.done
        ? ('Done', GTone.success)
        : switch (t.when) {
            TaskWhen.overdue => ('Overdue', GTone.danger),
            TaskWhen.today => ('Today', GTone.accent),
            TaskWhen.upcoming => ('Upcoming', GTone.neutral),
          };
    return Scaffold(
      backgroundColor: g.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(GSpace.m, GSpace.s, GSpace.m, 0),
              child: Row(
                children: [
                  GRoundButton(icon: LucideIcons.arrowLeft, label: 'Back', onTap: () => Navigator.of(context).pop()),
                  const Spacer(),
                  GRoundButton(
                    icon: t.priority ? LucideIcons.flagOff : LucideIcons.flag,
                    label: t.priority ? 'Remove priority' : 'Make priority',
                    onTap: () {
                      app.togglePriority(t.id);
                      GToast.show(context, t.priority ? 'Added to Priorities' : 'Removed from Priorities', type: GToastType.info);
                    },
                  ),
                  const SizedBox(width: 8),
                  GRoundButton(icon: LucideIcons.trash2, label: 'Delete', onTap: () => _confirmDelete(context, t)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.l, GSpace.gutter, GSpace.xl),
                children: [
                  Row(
                    children: [
                      GSwap(
                        id: statusLabel,
                        child: GStatusPill(label: statusLabel, tone: statusTone),
                      ),
                      if (t.byGenie) ...[const SizedBox(width: 8), const GStatusPill(label: 'Written by Genie', tone: GTone.ai)],
                      if (t.private) ...[const SizedBox(width: 8), const GStatusPill(label: 'Only me', tone: GTone.neutral, icon: LucideIcons.lock)],
                    ],
                  ),
                  const SizedBox(height: GSpace.m),
                  Text(t.title, style: GType.h1.c(t.done ? g.ink3 : g.ink).copyWith(decoration: t.done ? TextDecoration.lineThrough : null)),
                  const SizedBox(height: GSpace.l),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Fact(icon: LucideIcons.user, text: assignee == null ? 'You' : assignee.name),
                      if (t.due != null) _Fact(icon: LucideIcons.clock, text: t.due!, danger: t.when == TaskWhen.overdue && !t.done),
                      if (t.minutes != null) _Fact(icon: LucideIcons.timer, text: GFormat.minutes(t.minutes!)),
                      _Fact(
                        icon: LucideIcons.folder,
                        text: t.dept == 'Personal' ? 'Only me' : GFormat.shortDept(t.dept),
                        dot: t.dept == 'Personal' ? null : GFormat.dept(t.dept),
                      ),
                    ],
                  ),
                  const SizedBox(height: GSpace.xl),
                  Text('Notes', style: GType.label.c(g.ink3)),
                  const SizedBox(height: 6),
                  Text(t.notes.isEmpty ? 'No notes yet.' : t.notes, style: GType.body.c(t.notes.isEmpty ? g.ink3 : g.ink)),
                  const SizedBox(height: GSpace.xl),
                  Text('Move to', style: GType.label.c(g.ink3)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final w in const [(TaskWhen.today, 'Today'), (TaskWhen.upcoming, 'Later this week')])
                        GButton(
                          label: w.$2,
                          compact: true,
                          kind: t.when == w.$1 ? GButtonKind.quiet : GButtonKind.secondary,
                          icon: t.when == w.$1 ? LucideIcons.check : null,
                          onTap: t.when == w.$1
                              ? null
                              : () {
                                  app.moveTask(t.id, w.$1);
                                  GToast.show(context, 'Moved to ${w.$2}', type: GToastType.info);
                                },
                        ),
                    ],
                  ),
                  const SizedBox(height: GSpace.xl),
                  Text('Comments', style: GType.label.c(g.ink3)),
                  const SizedBox(height: 6),
                  Text('No comments yet.', style: GType.body.c(g.ink3)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.s, GSpace.gutter, GSpace.m),
              child: Row(
                children: [
                  if (!t.done && assignee == null) ...[
                    GButton(
                      label: running ? 'Stop clock' : 'Start clock',
                      icon: running ? LucideIcons.pause : LucideIcons.play,
                      kind: GButtonKind.secondary,
                      onTap: () => running ? app.stopTimer() : app.startTimer(t.id),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (assignee != null && !t.done) ...[
                    GButton(
                      label: 'Nudge ${assignee.first}',
                      kind: GButtonKind.secondary,
                      onTap: () => GToast.show(context, 'Nudge sent to ${assignee.first}'),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: GButton(
                      label: t.done ? 'Reopen' : 'Mark as done',
                      icon: t.done ? LucideIcons.rotateCcw : LucideIcons.check,
                      onTap: () {
                        app.toggleTask(t.id);
                        GHaptics.heavy();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Task t) {
    showGSheet<void>(
      context,
      builder: (sheet) {
        final g = sheet.g;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(GSpace.xl, GSpace.xl, GSpace.xl, GSpace.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Delete this task?', style: GType.h2.c(g.ink)),
                const SizedBox(height: 6),
                Text('“${t.title}” will be removed for everyone it was shared with.', textAlign: TextAlign.center, style: GType.body.c(g.ink2)),
                const SizedBox(height: GSpace.xl),
                GButton(
                  label: 'Delete task',
                  kind: GButtonKind.danger,
                  expand: true,
                  onTap: () {
                    final app = sheet.appRead;
                    final index = app.data!.tasks.indexOf(t);
                    final nav = Navigator.of(context);
                    Navigator.of(sheet).pop();
                    nav.pop();
                    app.deleteTask(t.id);
                    GToast.show(nav.context, 'Task deleted', action: 'Undo', onAction: () => app.restoreTask(t, index));
                  },
                ),
                const SizedBox(height: 8),
                GButton(label: 'Not now', kind: GButtonKind.quiet, expand: true, onTap: () => Navigator.of(sheet).pop()),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text, this.danger = false, this.dot});

  final IconData icon;
  final String text;
  final bool danger;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: GShape.fill(danger ? g.dangerSoft : g.card, GRadius.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            )
          else
            Icon(icon, size: 15, color: danger ? g.danger : g.ink2),
          const SizedBox(width: 7),
          Text(text, style: GType.label.c(danger ? g.danger : g.ink)),
        ],
      ),
    );
  }
}
