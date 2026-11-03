import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/parts.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/swap.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../calendar/meeting_sheet.dart';
import '../people/person_sheet.dart';
import 'routes.dart';

void openSearch(BuildContext context) {
  Navigator.of(context).push<void>(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => const SearchScreen(),
      transitionsBuilder: (context, a, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: GMotion.effects),
        child: child,
      ),
    ),
  );
}

/// Search across tasks, meetings, people and goals as you type.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final data = context.app.data;
    final q = _q.text.trim().toLowerCase();
    bool hit(String s) => s.toLowerCase().contains(q);

    final tasks = q.isEmpty || data == null ? const <Task>[] : data.tasks.where((t) => hit(t.title)).take(5).toList();
    final meetings = q.isEmpty || data == null ? const <Meeting>[] : data.meetings.where((m) => hit(m.title)).take(5).toList();
    final people = q.isEmpty || data == null ? const <Person>[] : data.people.where((p) => hit(p.name) || hit(p.role) || hit(p.dept)).take(5).toList();
    final goals = q.isEmpty || data == null ? const <Goal>[] : data.goals.where((x) => hit(x.title)).take(5).toList();
    final none = q.isNotEmpty && tasks.isEmpty && meetings.isEmpty && people.isEmpty && goals.isEmpty;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: g.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.s, GSpace.s, GSpace.s),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: GShape.fill(g.card, GRadius.pill),
                      child: Row(
                        children: [
                          Icon(LucideIcons.search, size: 18, color: g.ink3),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _q,
                              autofocus: true,
                              onChanged: (_) => setState(() {}),
                              style: GType.body.c(g.ink),
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: 'Search meetings, tasks, people',
                                hintStyle: GType.body.c(g.ink3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GTextAction(label: 'Cancel', color: g.ink, onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            Expanded(
              child: GSwap(
                id: q.isEmpty ? 'idle' : (none ? 'none' : 'results'),
                alignment: Alignment.topCenter,
                child: q.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.only(top: GSpace.s),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: GSpace.gutter, vertical: GSpace.s),
                            child: Text('Try', style: GType.label.c(g.ink3)),
                          ),
                          for (final s in const ['Daily huddle', 'hiring', 'Rahul', 'budget'])
                            GRow(
                              leading: Icon(LucideIcons.cornerDownRight, size: 18, color: g.ink3),
                              title: s,
                              onTap: () => setState(() => _q.text = s),
                            ),
                        ],
                      )
                    : none
                    ? ListView(
                        children: [
                          GEmptyState(icon: LucideIcons.searchX, title: 'Nothing found', body: 'No task, meeting, person or goal matches “${_q.text.trim()}”.'),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: GSpace.xxl),
                        children: [
                          if (meetings.isNotEmpty) _head('Meetings', g),
                          for (final m in meetings)
                            GRow(
                              leading: const GIconBox(icon: LucideIcons.video),
                              title: m.title,
                              subtitle: '${GFormat.dayName(m.start, now)} · ${GFormat.time(m.start)}',
                              onTap: () => showMeetingSheet(context, m),
                            ),
                          if (tasks.isNotEmpty) _head('Tasks', g),
                          for (final t in tasks)
                            GRow(
                              leading: const GIconBox(icon: LucideIcons.circleCheck),
                              title: t.title,
                              subtitle: t.done ? 'Done' : GFormat.shortDept(t.dept),
                              onTap: () => openTask(context, t.id),
                            ),
                          if (people.isNotEmpty) _head('People', g),
                          for (final p in people)
                            GRow(
                              leading: GAvatar(name: p.name),
                              title: p.name,
                              subtitle: p.role,
                              onTap: () => showPersonSheet(context, p),
                            ),
                          if (goals.isNotEmpty) _head('Goals', g),
                          for (final x in goals)
                            GRow(
                              leading: const GIconBox(icon: LucideIcons.target),
                              title: x.title,
                              subtitle: x.status.label,
                              onTap: () => openGoal(context, x.id),
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _head(String t, GPalette g) => Padding(
    padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.l, GSpace.gutter, GSpace.xs),
    child: Text(t, style: GType.label.c(g.ink3)),
  );
}
