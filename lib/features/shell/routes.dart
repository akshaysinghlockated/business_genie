import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/parts.dart';
import '../calendar/calendar_screen.dart';
import '../decisions/decisions_screen.dart';
import '../goals/goal_detail_screen.dart';
import '../goals/goals_screen.dart';
import '../inbox/inbox_screen.dart';
import '../people/people_screen.dart';
import '../tasks/task_detail_screen.dart';
import '../tasks/task_list_screen.dart';
import '../tasks/tasks_screen.dart';
import 'shell.dart';

/// One place for every push, so screens don't import each other.
Future<T?> _push<T>(BuildContext context, Widget page) => Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

void openGoals(BuildContext context) => _push<void>(context, const GoalsScreen());
void openGoal(BuildContext context, String id) => _push<void>(context, GoalDetailScreen(goalId: id));
void openInbox(BuildContext context) => _push<void>(context, const InboxScreen());
void openCalendar(BuildContext context, {DateTime? day}) => _push<void>(context, CalendarScreen(day: day));
void openDecisions(BuildContext context) => _push<void>(context, const DecisionsScreen());
void openPeople(BuildContext context) => _push<void>(context, const PeopleScreen());
void openTaskList(BuildContext context, TaskFilter filter) => _push<void>(context, TaskListScreen(filter: filter));
void openTasks(BuildContext context) => _push<void>(context, const TasksScreen());
void openTask(BuildContext context, String id) => _push<void>(context, TaskDetailScreen(taskId: id));

/// Genie lives in the shell: close whatever is open, swipe to Genie, and ask
/// [ask] if given.
void openGenie(BuildContext context, {String? ask}) {
  Navigator.of(context).popUntil((r) => r.isFirst);
  shellKey.currentState?.askGenie(ask);
}

/// Areas that still live on the web app. Says so plainly and copies the link.
void showWebOnly(BuildContext context, String name, IconData icon) {
  showGSheet<void>(
    context,
    builder: (context) {
      final g = context.g;
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(GSpace.xl, GSpace.s, GSpace.xl, GSpace.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 38, height: 4, decoration: GShape.fill(g.ink4, 2)),
              const SizedBox(height: GSpace.xl),
              GIconBox(icon: icon, size: 56),
              const SizedBox(height: GSpace.l),
              Text('$name opens on the web for now', textAlign: TextAlign.center, style: GType.h2.c(g.ink)),
              const SizedBox(height: GSpace.s),
              Text(
                'Everything here works in the Business Genie web app. It comes to the phone in a later update.',
                textAlign: TextAlign.center,
                style: GType.body.c(g.ink2),
              ),
              const SizedBox(height: GSpace.xl),
              GButton(
                label: 'Copy web link',
                icon: LucideIcons.link,
                expand: true,
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: 'https://business-genie.gophygital.work'));
                  Navigator.of(context).pop();
                  GToast.show(context, 'Web link copied', type: GToastType.info);
                },
              ),
              const SizedBox(height: GSpace.s),
              GButton(label: 'Not now', kind: GButtonKind.quiet, expand: true, onTap: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      );
    },
  );
}
