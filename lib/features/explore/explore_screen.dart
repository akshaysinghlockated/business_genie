import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/pressable.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../profile/profile_sheet.dart';
import '../shell/routes.dart';
import '../shell/search_screen.dart';
import '../news/news.dart';
import '../projects/projects_screen.dart';
import '../shell/shell.dart';
import '../shell/tab_page.dart';
import '../tasks/task_view.dart' show TaskLayout, taskLayout;
import '../tasks/task_list_screen.dart' show TaskFilter;

/// Explore: every area of the business in one place, grouped by what you
/// came to do, each tile with its live count. Areas that still live on the
/// web say so when opened.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final d = context.app.data;
    final now = DateTime.now();
    String? n(int? v, String one, String many) => v == null ? null : '$v ${v == 1 ? one : many}';
    final behind = d?.goals.where((x) => x.status == GoalStatus.behind).length ?? 0;
    final today = d?.meetings.where((m) => GFormat.sameDay(m.start, now) && !m.cancelled).length;

    final groups = <(String, List<_Area>)>[
      (
        'Run the business',
        [
          _Area(
            LucideIcons.target,
            'Goals',
            d == null ? null : '${n(d.goals.length, 'goal', 'goals')}${behind > 0 ? ' · $behind behind' : ''}',
            () => openGoals(context),
            alert: behind > 0,
          ),
          _Area(
            LucideIcons.gitFork,
            'Decisions',
            n(d?.openDecisions.length, 'open', 'open'),
            () => openDecisions(context),
            alert: (d?.openDecisions.length ?? 0) > 0,
          ),
          _Area(LucideIcons.calendarDays, 'Calendar', n(today, 'meeting today', 'meetings today'), () => openCalendar(context)),
          _Area(
            LucideIcons.userCheck,
            'Delegated',
            n(d?.openTasks.where((t) => t.assigneeId != null).length, 'with the team', 'with the team'),
            () => openTaskList(context, TaskFilter.delegated),
          ),
        ],
      ),
      (
        'Stay ahead',
        [
          _Area(LucideIcons.newspaper, 'News', d == null ? null : '${d.news.length} stories from your field', () => openNews(context)),
          _Area(
            LucideIcons.sparkle,
            'Genie suggests',
            d == null ? null : '${context.app.openSuggestions.length} ideas for you',
            () => openSuggestions(context),
          ),
        ],
      ),
      (
        'Projects and portfolios',
        [
          _Area(
            LucideIcons.folderKanban,
            'Projects',
            d == null
                ? null
                : '${d.projects.length} · ${d.projects.where((p) => p.status == ProjectStatus.offTrack || p.status == ProjectStatus.atRisk).length} need care',
            () => openProjects(context),
            alert: d?.projects.any((p) => p.status == ProjectStatus.offTrack) ?? false,
          ),
          _Area(
            LucideIcons.folders,
            'Portfolios',
            d == null ? null : '${d.projects.map((p) => p.portfolio).toSet().length} areas',
            () => openPortfolios(context),
          ),
          _Area(
            LucideIcons.flag,
            'Milestone',
            d?.milestone == null ? 'Not set yet' : '${(d!.milestone!.progress * 100).round()}% done',
            () => shellKey.currentState?.goTab(Tabs.milestone),
          ),
          _Area(LucideIcons.chartNoAxesColumn, 'Team workload', 'Who carries what', () {
            taskLayout.value = TaskLayout.team;
            shellKey.currentState?.goTab(Tabs.tasks);
          }),
        ],
      ),
      (
        'People',
        [
          _Area(
            LucideIcons.usersRound,
            'Team',
            d == null ? null : '${d.people.length} people · ${d.people.where((p) => p.reportFiled).length} reported',
            () => openPeople(context),
          ),
          _Area(LucideIcons.network, 'Organisation', 'Departments and roles', () => showWebOnly(context, 'Organisation', LucideIcons.network)),
        ],
      ),
      (
        'Plan and offer',
        [
          _Area(LucideIcons.fileText, 'Business plan', 'Vision, mission, targets', () => showWebOnly(context, 'Business plan', LucideIcons.fileText)),
          _Area(LucideIcons.package, 'Products', 'What you sell', () => showWebOnly(context, 'Products', LucideIcons.package)),
        ],
      ),
      (
        'Support',
        [
          _Area(LucideIcons.lifeBuoy, 'Helpdesk', 'Requests and issues', () => showWebOnly(context, 'Helpdesk', LucideIcons.lifeBuoy)),
          _Area(LucideIcons.settings, 'Settings', 'Display, demo data, account', () => openProfile(context)),
        ],
      ),
    ];

    return GTabPage(
      title: 'Explore',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, GSpace.navClearance),
        children: [
          GPressable(
            scale: .98,
            semanticLabel: 'Search everything',
            onTap: () => openSearch(context),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: GShape.lifted(g.surface, 24),
              child: Row(
                children: [
                  Icon(LucideIcons.search, size: 18, color: g.ink3),
                  const SizedBox(width: 10),
                  Text('Search goals, people, meetings, tasks', style: GType.body.c(g.ink3).copyWith(fontSize: 14.5)),
                ],
              ),
            ),
          ),
          for (final grp in groups) ...[
            Padding(
              padding: const EdgeInsets.only(top: 28, bottom: 12),
              child: Text(grp.$1, style: GType.h3.c(g.ink).copyWith(fontSize: 16)),
            ),
            for (var r = 0; r < grp.$2.length; r += 2)
              Padding(
                padding: EdgeInsets.only(top: r == 0 ? 0 : 10),
                child: Row(
                  children: [
                    Expanded(child: _Tile(area: grp.$2[r])),
                    const SizedBox(width: 10),
                    Expanded(child: r + 1 < grp.$2.length ? _Tile(area: grp.$2[r + 1]) : const SizedBox.shrink()),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Area {
  const _Area(this.icon, this.title, this.sub, this.onTap, {this.alert = false});

  final IconData icon;
  final String title;
  final String? sub;
  final VoidCallback onTap;
  final bool alert;
}

class _Tile extends StatelessWidget {
  const _Tile({required this.area});

  final _Area area;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final a = area;
    return GPressable(
      scale: .97,
      semanticLabel: '${a.title}${a.sub == null ? '' : ', ${a.sub}'}',
      onTap: a.onTap,
      child: Container(
        height: 118,
        padding: const EdgeInsets.all(16),
        decoration: GShape.lifted(g.surface, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: g.card, shape: BoxShape.circle),
                  child: Icon(a.icon, size: 18, color: g.ink),
                ),
                const Spacer(),
                if (a.alert)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: g.danger, shape: BoxShape.circle),
                  ),
              ],
            ),
            const Spacer(),
            Text(a.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.title.c(g.ink).copyWith(fontSize: 15)),
            const SizedBox(height: 2),
            Text(a.sub ?? ' ', maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.caption.c(g.ink3).copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
