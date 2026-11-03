import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/genie_mark.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/parts.dart';
import '../../core/widgets/states.dart';
import '../../data/models.dart';
import '../shell/tab_page.dart';
import 'new_task_sheet.dart';
import 'task_row.dart';

/// Which tasks a list shows.
class TaskFilter {
  const TaskFilter._(this.label, this.icon, this.test, [this.empty = 'Nothing here right now.']);

  final String label;
  final IconData icon;
  final bool Function(Task t) test;
  final String empty;

  static final today = TaskFilter._(
    'Today',
    LucideIcons.sun,
    (t) => t.when == TaskWhen.today && t.assigneeId == null,
    'Nothing due today. Add one, or plan tomorrow.',
  );
  static final overdue = TaskFilter._('Overdue', LucideIcons.bellRing, (t) => t.when == TaskWhen.overdue && !t.done, 'Nothing overdue. Nicely done.');
  static final upcoming = TaskFilter._(
    'Upcoming',
    LucideIcons.calendarClock,
    (t) => t.when == TaskWhen.upcoming && !t.done && t.assigneeId == null,
    'Nothing scheduled ahead yet.',
  );
  static final priorities = TaskFilter._('Priorities', LucideIcons.flag, (t) => t.priority && !t.done, 'Flag a task to keep it here.');
  static final delegated = TaskFilter._(
    'Delegated',
    LucideIcons.userCheck,
    (t) => t.assigneeId != null && !t.done,
    'Tasks you give to others show here so you can follow them.',
  );
  static final done = TaskFilter._('Done', LucideIcons.circleCheckBig, (t) => t.done, 'Finished tasks show here.');

  static TaskFilter dept(String d) => TaskFilter._(d, LucideIcons.folder, (t) => t.dept == d);

  static List<TaskFilter> get tiles => [today, overdue, priorities, upcoming, delegated, done];
}

/// One list of tasks: open first, done folded at the bottom. "Plan my day"
/// lives on Today and runs only when pressed.
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key, required this.filter});

  final TaskFilter filter;

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  bool _planning = false;
  bool _planned = false;

  Future<void> _planDay(List<Task> open) async {
    setState(() => _planning = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() {
      _planning = false;
      _planned = true;
    });
    GHaptics.heavy();
  }

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final f = widget.filter;
    return Scaffold(
      backgroundColor: g.surface,
      body: SafeArea(
        bottom: false,
        child: GLoadView(
          builder: (context, data) {
            final all = data.tasks.where(f.test).toList();
            final open = all.where((t) => !t.done).toList();
            final done = all.where((t) => t.done).toList();
            if (_planned) {
              open.sort((a, b) => (b.priority ? 1 : 0) - (a.priority ? 1 : 0));
            }
            final isToday = identical(f, TaskFilter.today);
            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(GSpace.m, GSpace.s, GSpace.gutter, 0),
                        child: Row(
                          children: [
                            GRoundButton(icon: LucideIcons.arrowLeft, label: 'Back', onTap: () => Navigator.of(context).pop()),
                            const SizedBox(width: GSpace.m),
                            Expanded(
                              child: Text(f.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.h1.c(g.ink)),
                            ),
                            if (open.isNotEmpty) Text('${open.length} left', style: GType.label.c(g.ink3)),
                          ],
                        ),
                      ),
                    ),
                    if (isToday && open.length > 1)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.l, GSpace.gutter, 0),
                          child: _PlanCard(
                            planning: _planning,
                            planned: _planned,
                            onPlan: () => _planDay(open),
                            onUndo: () => setState(() => _planned = false),
                          ),
                        ),
                      ),
                    if (all.isEmpty)
                      SliverToBoxAdapter(
                        child: GEmptyState(icon: f.icon, title: 'All clear', body: f.empty, action: 'New task', onAction: () => showNewTaskSheet(context)),
                      )
                    else ...[
                      const SliverToBoxAdapter(child: SizedBox(height: GSpace.l)),
                      SliverList.builder(
                        itemCount: open.length,
                        itemBuilder: (context, i) => Container(
                          margin: const EdgeInsets.fromLTRB(GSpace.gutter, 0, GSpace.gutter, 12),
                          clipBehavior: Clip.antiAlias,
                          decoration: GShape.lifted(g.surface, 18),
                          child: Column(
                            children: [
                              TaskRow(key: ValueKey(open[i].id), task: open[i]),
                              if (_planned && isToday)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(60, 0, GSpace.gutter, 14),
                                  child: Row(
                                    children: [
                                      GenieMark(size: 13, mono: g.ink3, dot: g.ai),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(_reason(open[i], i), style: GType.caption.c(g.ai))),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (open.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(GSpace.gutter + 4, GSpace.xs, GSpace.gutter, 0),
                            child: Text('Swipe right to finish · swipe left to start the clock', style: GType.caption.c(g.ink3)),
                          ),
                        ),
                      if (done.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(GSpace.gutter + 4, GSpace.xxl, GSpace.gutter, GSpace.m),
                            child: Text('Done · ${done.length}', style: GType.label.c(g.ink3)),
                          ),
                        ),
                        SliverList.builder(
                          itemCount: done.length,
                          itemBuilder: (context, i) => Container(
                            margin: const EdgeInsets.fromLTRB(GSpace.gutter, 0, GSpace.gutter, 12),
                            clipBehavior: Clip.antiAlias,
                            decoration: GShape.lifted(g.surface, 18),
                            child: TaskRow(key: ValueKey(done[i].id), task: done[i]),
                          ),
                        ),
                      ],
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
                Positioned(
                  right: GSpace.gutter,
                  bottom: MediaQuery.paddingOf(context).bottom + GSpace.l,
                  child: GButton(label: 'New task', icon: LucideIcons.plus, onTap: () => showNewTaskSheet(context)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _reason(Task t, int i) {
    if (t.priority) return i == 0 ? 'First: flagged and due soonest' : 'Flagged, so it goes early';
    if ((t.minutes ?? 0) >= 45) return 'Needs a long block, so before lunch';
    if (t.byGenie) return 'Quick follow-up from your meetings';
    return 'Short, fits between meetings';
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.planning, required this.planned, required this.onPlan, required this.onUndo});

  final bool planning, planned;
  final VoidCallback onPlan, onUndo;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return GCard(
      color: g.aiSoft,
      radius: GRadius.tile + 2,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const GenieMark(size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(planned ? 'Your day is ordered' : 'Plan my day', style: GType.title.c(g.ink)),
                Text(
                  planned
                      ? 'Genie put flagged and long tasks first, between your meetings.'
                      : 'Genie orders today’s tasks around your meetings, with a reason for each.',
                  style: GType.caption.c(g.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          planned
              ? GButton(
                  label: 'Accept',
                  compact: true,
                  kind: GButtonKind.ai,
                  onTap: () {
                    GToast.show(context, 'Day accepted. Genie will nudge you before each one.');
                    onUndo();
                  },
                )
              : GButton(label: 'Plan', compact: true, kind: GButtonKind.ai, busy: planning, onTap: onPlan),
        ],
      ),
    );
  }
}
