import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/genie_mark.dart';
import '../../core/widgets/parts.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/swap.dart';
import '../../data/models.dart';
import '../people/person_sheet.dart';
import '../shell/routes.dart';
import '../shell/tab_page.dart';

Color projectColor(ProjectStatus s, GPalette g) => switch (s) {
  ProjectStatus.onTrack => g.success,
  ProjectStatus.atRisk => g.warning,
  ProjectStatus.offTrack => g.danger,
  ProjectStatus.done => g.accent,
};

int projectRank(ProjectStatus s) => switch (s) {
  ProjectStatus.offTrack => 0,
  ProjectStatus.atRisk => 1,
  ProjectStatus.onTrack => 2,
  ProjectStatus.done => 3,
};

void openProjects(BuildContext context) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ProjectsScreen()));
void openPortfolios(BuildContext context) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PortfoliosScreen()));
void openProject(BuildContext context, String id) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ProjectDetailScreen(id: id)));

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);

  final ProjectStatus status;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final c = projectColor(status, g);
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: c.withValues(alpha: .1), borderRadius: BorderRadius.circular(13)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(status.label, style: GType.caption.c(c).w(FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.color, this.height = 6});

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: g.ink.withValues(alpha: .08)),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0, 1)),
              duration: GMotion.of(context, const Duration(milliseconds: 700)),
              curve: GMotion.easeOut,
              builder: (context, v, _) => FractionallySizedBox(
                widthFactor: v,
                child: Container(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One project as a card: name, portfolio and due date, status, progress,
/// steps done, owner and team.
class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.project, required this.data});

  final Project project;
  final Snapshot data;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final p = project;
    final owner = data.person(p.ownerId);
    final done = p.steps.where((s) => s.done).length;
    final names = [for (final id in p.members) ?data.person(id)?.name];
    return GPressable(
      scale: .98,
      semanticLabel: '${p.name}, ${p.status.label}, ${(p.progress * 100).round()} percent',
      onTap: () => openProject(context, p.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: GShape.lifted(g.surface, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${p.portfolio} · due ${p.due}', maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.caption.c(g.ink3)),
                ),
                _StatusPill(p.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.h3.c(g.ink)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _Bar(value: p.progress, color: projectColor(p.status, g)),
                ),
                const SizedBox(width: 10),
                Text('${(p.progress * 100).round()}%', style: GType.figure.c(g.ink).copyWith(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (owner != null) ...[GAvatar(name: owner.name, size: 24), const SizedBox(width: 6), Text(owner.first, style: GType.caption.c(g.ink2))],
                const Spacer(),
                Icon(LucideIcons.listChecks, size: 13, color: g.ink3),
                const SizedBox(width: 4),
                Text('$done of ${p.steps.length} steps', style: GType.caption.c(g.ink3)),
                if (names.length > 1) ...[const SizedBox(width: 10), GAvatarStack(names: names, size: 22)],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Every project, filtered by status, the ones in trouble first.
class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  ProjectStatus? _filter;

  @override
  Widget build(BuildContext context) {
    return GPushPage(
      title: 'Projects',
      actions: [GIconButtonLike(icon: LucideIcons.folderKanban, label: 'Portfolios', onTap: () => openPortfolios(context))],
      child: GLoadView(
        builder: (context, data) {
          if (data.projects.isEmpty) {
            return ListView(
              padding: const EdgeInsets.only(top: GSpace.xl),
              children: [
                GEmptyState(
                  icon: LucideIcons.folderKanban,
                  title: 'No projects yet',
                  body: 'Projects group the work behind a goal: an owner, a team and steps. Create them on the web.',
                  action: 'Get the web link',
                  onAction: () => showWebOnly(context, 'Projects', LucideIcons.folderKanban),
                ),
              ],
            );
          }
          final counts = {for (final s in ProjectStatus.values) s: data.projects.where((p) => p.status == s).length};
          final list = data.projects.where((p) => _filter == null || p.status == _filter).toList()
            ..sort((a, b) => projectRank(a.status).compareTo(projectRank(b.status)));
          return Column(
            children: [
              const SizedBox(height: GSpace.m),
              GChipRow(
                children: [
                  GChip(label: 'All', count: data.projects.length, selected: _filter == null, onTap: () => setState(() => _filter = null)),
                  for (final s in ProjectStatus.values)
                    if (counts[s]! > 0) GChip(label: s.label, count: counts[s], selected: _filter == s, onTap: () => setState(() => _filter = s)),
                ],
              ),
              const SizedBox(height: GSpace.s),
              Expanded(
                child: GSwap(
                  id: _filter?.name ?? 'all',
                  alignment: Alignment.topCenter,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(GSpace.gutter, GSpace.s, GSpace.gutter, MediaQuery.paddingOf(context).bottom + 32),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => ProjectCard(project: list[i], data: data),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A round icon button for page headers.
class GIconButtonLike extends StatelessWidget {
  const GIconButtonLike({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return GPressable(
      scale: .9,
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: g.surface,
          shape: BoxShape.circle,
          border: Border.all(color: g.rule),
        ),
        child: Icon(icon, size: 17, color: g.ink),
      ),
    );
  }
}

/// Portfolios: projects grouped by area, each with a status bar.
class PortfoliosScreen extends StatelessWidget {
  const PortfoliosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GPushPage(
      title: 'Portfolios',
      child: GLoadView(
        builder: (context, data) {
          final g = context.g;
          if (data.projects.isEmpty) {
            return ListView(
              padding: const EdgeInsets.only(top: GSpace.xl),
              children: const [
                GEmptyState(icon: LucideIcons.folders, title: 'No portfolios yet', body: 'Portfolios group projects by area, like Growth or Product.'),
              ],
            );
          }
          final groups = <String, List<Project>>{};
          for (final p in data.projects) {
            groups.putIfAbsent(p.portfolio, () => []).add(p);
          }
          return ListView(
            padding: EdgeInsets.fromLTRB(GSpace.gutter, GSpace.l, GSpace.gutter, MediaQuery.paddingOf(context).bottom + 32),
            children: [
              for (final e in groups.entries) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  clipBehavior: Clip.antiAlias,
                  decoration: GShape.lifted(g.surface, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(color: g.card, borderRadius: BorderRadius.circular(10)),
                                  child: Icon(LucideIcons.folder, size: 16, color: g.ink),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(e.key, style: GType.h3.c(g.ink))),
                                Text('${e.value.length} projects', style: GType.caption.c(g.ink3)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox(
                                height: 8,
                                child: Row(
                                  children: [
                                    for (final s in ProjectStatus.values)
                                      if (e.value.any((p) => p.status == s))
                                        Expanded(
                                          flex: e.value.where((p) => p.status == s).length,
                                          child: Container(margin: const EdgeInsets.only(right: 2), color: projectColor(s, g)),
                                        ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final p in e.value..sort((a, b) => projectRank(a.status).compareTo(projectRank(b.status))))
                        GPressable(
                          scale: .985,
                          semanticLabel: p.name,
                          onTap: () => openProject(context, p.id),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: g.rule)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(color: projectColor(p.status, g), shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.label.c(g.ink).copyWith(fontSize: 14.5)),
                                      Text('${p.status.label} · due ${p.due}', style: GType.caption.c(g.ink3)),
                                    ],
                                  ),
                                ),
                                Text('${(p.progress * 100).round()}%', style: GType.figure.c(g.ink2).copyWith(fontSize: 13)),
                                const SizedBox(width: 4),
                                Icon(LucideIcons.chevronRight, size: 16, color: g.ink4),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// One project in full: status, progress, why it exists, its steps and team.
class ProjectDetailScreen extends StatelessWidget {
  const ProjectDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return GPushPage(
      title: 'Project',
      child: GLoadView(
        builder: (context, data) {
          final g = context.g;
          final p = data.project(id);
          if (p == null) return const Center(child: Text('This project is no longer here.'));
          final owner = data.person(p.ownerId);
          final done = p.steps.where((s) => s.done).length;
          final team = [for (final m in p.members) ?data.person(m)];
          return ListView(
            padding: EdgeInsets.fromLTRB(GSpace.gutter, GSpace.l, GSpace.gutter, MediaQuery.paddingOf(context).bottom + 32),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: GShape.lifted(g.surface, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(p.portfolio, style: GType.label.c(g.ink3))),
                        _StatusPill(p.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(p.name, style: GType.h1.c(g.ink).copyWith(fontSize: 24)),
                    if (p.about.isNotEmpty) ...[const SizedBox(height: 6), Text(p.about, style: GType.bodyS.c(g.ink2))],
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${(p.progress * 100).round()}%', style: GType.numeral.c(g.ink).copyWith(fontSize: 34, height: 1)),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('$done of ${p.steps.length} steps', style: GType.label.c(g.ink3)),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('Due ${p.due}', style: GType.label.c(g.ink2)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _Bar(value: p.progress, color: projectColor(p.status, g), height: 8),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 26, 4, 10),
                child: Text('Steps', style: GType.h3.c(g.ink)),
              ),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: GShape.lifted(g.surface, 20),
                child: Column(
                  children: [
                    for (var i = 0; i < p.steps.length; i++)
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                        decoration: BoxDecoration(
                          border: i == 0 ? null : Border(top: BorderSide(color: g.rule)),
                        ),
                        child: Row(
                          children: [
                            Icon(p.steps[i].done ? LucideIcons.circleCheck : LucideIcons.circle, size: 20, color: p.steps[i].done ? g.success : g.ink4),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                p.steps[i].title,
                                style: GType.label.copyWith(
                                  fontSize: 14.5,
                                  color: p.steps[i].done ? g.ink3 : g.ink,
                                  decoration: p.steps[i].done ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            if (p.steps[i].due != null && !p.steps[i].done) Text(p.steps[i].due!, style: GType.caption.c(g.ink3)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 26, 4, 10),
                child: Text('Team', style: GType.h3.c(g.ink)),
              ),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: GShape.lifted(g.surface, 20),
                child: Column(
                  children: [
                    for (var i = 0; i < team.length; i++)
                      GPressable(
                        scale: .985,
                        semanticLabel: team[i].name,
                        onTap: () => showPersonSheet(context, team[i]),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
                          decoration: BoxDecoration(
                            border: i == 0 ? null : Border(top: BorderSide(color: g.rule)),
                          ),
                          child: Row(
                            children: [
                              GAvatar(name: team[i].name, size: 36),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(team[i].name, style: GType.label.c(g.ink).copyWith(fontSize: 14.5)),
                                    Text('${team[i].role} · ${GFormat.shortDept(team[i].dept)}', style: GType.caption.c(g.ink3)),
                                  ],
                                ),
                              ),
                              if (team[i].id == owner?.id)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: g.card, borderRadius: BorderRadius.circular(8)),
                                  child: Text('Owner', style: GType.micro.c(g.ink2)),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GPressable(
                scale: .97,
                semanticLabel: 'Ask Genie about this project',
                onTap: () => openGenie(context, ask: 'How is ${p.name} going?'),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(color: g.ink, borderRadius: BorderRadius.circular(26)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GenieMark(size: 18, mono: g.onInk, dot: const Color(0xFF9B85FF)),
                      const SizedBox(width: 8),
                      Text('Ask Genie about this project', style: GType.label.c(g.onInk).w(FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
