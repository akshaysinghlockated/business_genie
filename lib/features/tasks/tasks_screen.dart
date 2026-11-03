import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/business.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/genie_mark.dart';
import '../../core/widgets/parts.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/swap.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../calendar/calendar_screen.dart';
import '../shell/routes.dart';
import '../shell/search_screen.dart';
import '../shell/tab_page.dart';
import 'new_task_sheet.dart';
import 'task_list_screen.dart';
import 'task_row.dart';
import 'task_view.dart';
import 'work_views.dart';
import '../decisions/decisions_screen.dart';

/// Tasks: pill tabs for each list, then the list as Manage view shapes it
/// (filtered, sorted, grouped, compact or not). The toolbar above the bar
/// switches to the calendar. "Plan my day" sits on Today.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, this.asTab = false});

  /// In the bottom bar: the shared tab header and room for the bar.
  final bool asTab;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  TaskFilter _tab = TaskFilter.today;

  void _onView() => setState(() {});

  @override
  void initState() {
    super.initState();
    taskView.addListener(_onView);
  }

  @override
  void dispose() {
    taskView.removeListener(_onView);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final search = GIconButton(icon: LucideIcons.search, label: 'Search tasks', onTap: () => openSearch(context));
    final left = context.app.data?.openTasks.where((t) => t.assigneeId == null && t.when != TaskWhen.upcoming).length;
    final body = Stack(
      children: [
        GLoadView(
          builder: (context, data) {
            final g = context.g;
            if (data.tasks.isEmpty) {
              return ListView(
                padding: const EdgeInsets.only(top: GSpace.xl),
                children: [
                  GEmptyState(
                    icon: LucideIcons.listChecks,
                    title: 'No tasks yet',
                    body: 'Tasks from your meetings, chats and Genie arrive here. You can add your own too.',
                    action: 'New task',
                    onAction: () => showNewTaskSheet(context),
                  ),
                ],
              );
            }
            int count(TaskFilter f) => data.tasks.where(f.test).where((t) => identical(f, TaskFilter.done) || !t.done).length;
            final tabs = <TaskFilter>[
              TaskFilter.today,
              TaskFilter.upcoming,
              if (count(TaskFilter.overdue) > 0) TaskFilter.overdue,
              TaskFilter.delegated,
              TaskFilter.done,
            ];
            final view = taskView.value;
            final list = data.tasks
                .where(_tab.test)
                .where((t) => identical(_tab, TaskFilter.done) || !t.done)
                .where(
                  (t) => switch (view.show) {
                    TaskShow.all => true,
                    TaskShow.mine => t.assigneeId == null,
                    TaskShow.priority => t.priority,
                    TaskShow.genie => t.byGenie,
                  },
                )
                .toList();
            int minutesOf(Task t) => _dueMinutes(t.due) ?? 99999;
            list.sort(
              (a, b) => switch (view.sort) {
                TaskSort.due => minutesOf(a).compareTo(minutesOf(b)),
                TaskSort.priority => (b.priority ? 1 : 0) - (a.priority ? 1 : 0),
                TaskSort.length => (a.minutes ?? 999).compareTo(b.minutes ?? 999),
                TaskSort.title => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
              },
            );
            String groupOf(Task t) => switch (view.group) {
              TaskGroup.none => '',
              TaskGroup.due =>
                t.when == TaskWhen.overdue
                    ? 'Overdue'
                    : (t.due == null
                          ? 'No time'
                          : (_dueMinutes(t.due) == null ? 'Later' : (_dueMinutes(t.due)! < 12 * 60 ? 'Morning' : 'Afternoon and evening'))),
              TaskGroup.department => GFormat.shortDept(t.dept),
              TaskGroup.priority => t.priority ? 'Priority' : 'Everything else',
            };
            final groups = <String, List<Task>>{};
            for (final t in list) {
              groups.putIfAbsent(groupOf(t), () => []).add(t);
            }
            return Column(
              children: [
                GUnderlineTabs<TaskFilter>(tabs: [for (final f in tabs) (f, f.label, count(f))], value: _tab, onChanged: (f) => setState(() => _tab = f)),
                Expanded(
                  child: GSwap(
                    id: _tab.label,
                    alignment: Alignment.topCenter,
                    child: GRefresh(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: GSpace.navClearance),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.s, GSpace.gutter, GSpace.m),
                            child: Text(
                              [
                                if (list.isNotEmpty) '${list.length} ${identical(_tab, TaskFilter.done) ? 'done' : 'open'}',
                                if (view.show != TaskShow.all) view.show.label,
                                if (view.group != TaskGroup.none) 'by ${view.group.label.toLowerCase()}',
                                'sorted by ${view.sort.label.toLowerCase()}',
                              ].join(' · '),
                              style: GType.label.c(g.ink3),
                            ),
                          ),
                          if (identical(_tab, TaskFilter.today) && list.length > 1)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(GSpace.gutter, 0, GSpace.gutter, GSpace.m),
                              child: GCard(
                                color: g.aiSoft,
                                radius: GRadius.tile + 2,
                                padding: const EdgeInsets.all(14),
                                onTap: () => openTaskList(context, TaskFilter.today),
                                semanticLabel: 'Plan my day with Genie',
                                child: Row(
                                  children: [
                                    const GenieMark(size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Plan my day', style: GType.title.c(g.ink)),
                                          Text('Genie orders today’s tasks around your meetings.', style: GType.caption.c(g.ink2)),
                                        ],
                                      ),
                                    ),
                                    Icon(LucideIcons.chevronRight, size: 18, color: g.ink3),
                                  ],
                                ),
                              ),
                            ),
                          if (list.isEmpty)
                            GEmptyState(icon: _tab.icon, title: 'All clear', body: _tab.empty, compact: true)
                          else
                            for (final e in groups.entries) ...[
                              if (e.key.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(GSpace.gutter + 4, GSpace.m, GSpace.gutter, GSpace.s),
                                  child: Row(
                                    children: [
                                      Text(e.key, style: GType.label.c(g.ink).w(FontWeight.w600)),
                                      const SizedBox(width: 6),
                                      Text('${e.value.length}', style: GType.caption.c(g.ink3)),
                                    ],
                                  ),
                                ),
                              for (final t in e.value)
                                Container(
                                  key: ValueKey('card-${t.id}'),
                                  margin: EdgeInsets.fromLTRB(GSpace.gutter, 0, GSpace.gutter, view.compact ? 8 : 12),
                                  decoration: GShape.lifted(g.surface, 18),
                                  clipBehavior: Clip.antiAlias,
                                  child: TaskRow(key: ValueKey(t.id), task: t, view: view),
                                ),
                            ],
                          if (list.isNotEmpty && !identical(_tab, TaskFilter.done))
                            Padding(
                              padding: const EdgeInsets.fromLTRB(GSpace.gutter + 4, GSpace.m, GSpace.gutter, 0),
                              child: Text('Swipe right to finish · swipe left to start the clock', style: GType.caption.c(g.ink3)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        if (!widget.asTab)
          Positioned(
            right: GSpace.gutter,
            bottom: GSpace.l,
            child: GFab(label: 'New task', onTap: () => showNewTaskSheet(context)),
          ),
      ],
    );
    if (widget.asTab) {
      return ListenableBuilder(
        listenable: Listenable.merge([taskLayout, taskView]),
        builder: (context, _) {
          final v = taskLayout.value;
          final d = context.app.data;
          final subtitle = switch (v) {
            TaskLayout.list => left == null ? null : '$left open for today',
            TaskLayout.board => 'Long press a card to move it',
            TaskLayout.timeline => 'Today, hour by hour',
            TaskLayout.calendar => 'Meetings by day',
            TaskLayout.decisions => d == null ? null : '${d.openDecisions.length} waiting on you',
            TaskLayout.team => d == null ? null : '${d.tasks.where((t) => t.assigneeId != null && !t.done).length} open with ${d.people.length} people',
            TaskLayout.goals => d == null ? null : '${d.goals.length} goals this year',
          };
          return GTabPage(
            title: v == TaskLayout.list ? 'Tasks' : v.label,
            subtitle: subtitle,
            actions: [search],
            child: GSwap(
              id: v,
              alignment: Alignment.topCenter,
              child: switch (v) {
                TaskLayout.list => body,
                TaskLayout.board => const BoardView(),
                TaskLayout.timeline => const TimelineView(),
                TaskLayout.calendar => const CalendarScreen(embedded: true),
                TaskLayout.decisions => const DecisionsScreen(embedded: true),
                TaskLayout.team => const TeamWorkView(),
                TaskLayout.goals => const GoalsWorkView(),
              },
            ),
          );
        },
      );
    }
    return GPushPage(title: 'Tasks', actions: [search], child: body);
  }
}

/// Minutes after midnight for a label like "10:30 AM"; null for "Fri".
int? _dueMinutes(String? label) {
  if (label == null) return null;
  final m = RegExp(r'^(\d+):(\d+) (AM|PM)$').firstMatch(label);
  if (m == null) return null;
  var h = int.parse(m.group(1)!) % 12;
  if (m.group(3) == 'PM') h += 12;
  return h * 60 + int.parse(m.group(2)!);
}
