import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/genie_mark.dart';
import '../../core/widgets/states.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../goals/goal_widgets.dart' show GoalCard, KrRow;
import '../home/milestone_hero.dart';
import '../shell/routes.dart';
import '../shell/tab_page.dart';

/// Milestone: where the company is on its plan. The current milestone, its
/// key results, the plan's targets, the road from Foundation to the BHAG,
/// and the goals that carry it.
class MilestoneScreen extends StatelessWidget {
  const MilestoneScreen({super.key});

  static const _stages = ['Foundation', 'Short term', 'Mid term', 'Long term', 'BHAG'];

  @override
  Widget build(BuildContext context) {
    final top = context.app.data?.milestone;
    return GTabPage(
      title: 'Milestone',
      subtitle: top == null ? 'Your plan, stage by stage' : 'Week ${top.week} of ${top.weeks} · ${(top.progress * 100).round()}% done',
      child: GLoadView(
        builder: (context, data) {
          final m = data.milestone;
          if (m == null) {
            return ListView(
              padding: const EdgeInsets.only(top: GSpace.xxl),
              children: [
                GEmptyState(
                  icon: LucideIcons.flag,
                  title: 'No milestone yet',
                  body: 'Your first milestone is set with the business plan on the web. Its progress shows here.',
                  action: 'Get the web link',
                  onAction: () => showWebOnly(context, 'Business plan', LucideIcons.fileText),
                ),
              ],
            );
          }
          return _Body(data: data, m: m);
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data, required this.m});

  final Snapshot data;
  final Milestone m;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final behind = data.goals.where((x) => x.status == GoalStatus.behind).length;
    final goals = [...data.goals]..sort((a, b) => _rank(a.status).compareTo(_rank(b.status)));
    return GRefresh(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(GSpace.gutter, 6, GSpace.gutter, GSpace.navClearance),
        children: [
          MilestoneHero(milestone: m, behind: behind, decisions: data.openDecisions.length, results: false),
          _Title('Key results', meta: '${m.krs.length}'),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            decoration: GShape.lifted(g.surface, 22),
            child: Column(
              children: [
                for (final kr in m.krs)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: KrRow(kr: kr),
                  ),
              ],
            ),
          ),
          if (data.targets.isNotEmpty) ...[
            const _Title('Plan targets'),
            Row(
              children: [
                for (var i = 0; i < data.targets.length && i < 3; i++) ...[if (i > 0) const SizedBox(width: 10), Expanded(child: _Target(t: data.targets[i]))],
              ],
            ),
          ],
          const _Title('The road'),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            decoration: GShape.lifted(g.surface, 22),
            child: Column(
              children: [
                for (var i = 0; i < MilestoneScreen._stages.length; i++)
                  _Stage(
                    index: i,
                    name: MilestoneScreen._stages[i],
                    current: m.stage,
                    last: i == MilestoneScreen._stages.length - 1,
                    sub: i < m.stage
                        ? 'Done'
                        : i == m.stage
                        ? 'Now · week ${m.week} of ${m.weeks} · ${(m.progress * 100).round()}%'
                        : (i == MilestoneScreen._stages.length - 1 ? data.vision : 'Opens after ${MilestoneScreen._stages[i - 1]}'),
                  ),
              ],
            ),
          ),
          _Title('Goals carrying it', meta: 'All goals', onTap: () => openGoals(context)),
          for (final x in goals.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GoalCard(goal: x, owner: data.person(x.ownerId)),
            ),
        ],
      ),
    );
  }

  static int _rank(GoalStatus s) => switch (s) {
    GoalStatus.behind => 0,
    GoalStatus.onTrack => 1,
    GoalStatus.notStarted => 2,
    GoalStatus.achieved => 3,
  };
}

class _Title extends StatelessWidget {
  const _Title(this.title, {this.meta, this.onTap});

  final String title;
  final String? meta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 28, 0, 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: GType.h3.c(g.ink))),
          if (meta != null)
            GPressable(
              scale: .94,
              semanticLabel: '$title, $meta',
              onTap: onTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(meta!, style: GType.label.c(g.ink3).copyWith(fontSize: 13)),
                  if (onTap != null) Icon(LucideIcons.chevronRight, size: 15, color: g.ink3),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Target extends StatelessWidget {
  const _Target({required this.t});

  final PlanTarget t;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Container(
      height: 128,
      padding: const EdgeInsets.all(14),
      decoration: GShape.lifted(g.surface, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: GType.caption.c(g.ink3).copyWith(height: 1.25)),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(t.current, style: GType.numeral.c(g.ink).copyWith(fontSize: 20)),
          ),
          Text('of ${t.target}', maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.caption.c(g.ink3).copyWith(fontSize: 11)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              child: Stack(
                children: [
                  Container(color: g.ink.withValues(alpha: .08)),
                  FractionallySizedBox(
                    widthFactor: t.progress.clamp(0, 1),
                    child: Container(color: g.ink),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One stop on the road: a dot on a line, the stage, and where it stands.
class _Stage extends StatelessWidget {
  const _Stage({required this.index, required this.name, required this.current, required this.last, required this.sub});

  final int index, current;
  final String name, sub;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final done = index < current, now = index == current;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done || now ? g.ink : g.surface,
                    border: Border.all(color: done || now ? g.ink : g.ruleStrong, width: 1.5),
                  ),
                  child: done
                      ? Icon(LucideIcons.check, size: 12, color: g.onInk)
                      : now
                      ? Center(
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(color: g.onInk, shape: BoxShape.circle),
                          ),
                        )
                      : null,
                ),
                if (!last)
                  Expanded(
                    child: Container(width: 1.5, margin: const EdgeInsets.symmetric(vertical: 4), color: done ? g.ink : g.rule),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 10 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GType.label.c(now || done ? g.ink : g.ink2).w(now ? FontWeight.w700 : FontWeight.w500).copyWith(fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(sub, style: GType.caption.c(now ? g.ink2 : g.ink3).copyWith(height: 1.35)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showMilestoneInsight(BuildContext context) {
  final d = context.appRead.data;
  final m = d?.milestone;
  if (d == null || m == null) return;
  final pace = m.progress - m.week / m.weeks;
  final behind = d.goals.where((x) => x.status == GoalStatus.behind).toList();
  final weakest = [...m.krs.where((k) => k.progress != null)]..sort((a, b) => a.progress!.compareTo(b.progress!));
  final points = <(IconData, String)>[
    (
      pace >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
      '${(m.progress * 100).round()}% done with ${((m.week / m.weeks) * 100).round()}% of the time used: ${pace >= .05 ? 'ahead of pace' : (pace <= -.05 ? 'behind pace' : 'on pace')}.',
    ),
    if (weakest.isNotEmpty)
      (
        LucideIcons.target,
        'Weakest key result: ${weakest.first.title} at ${(weakest.first.progress! * 100).round()}%. It decides whether the milestone lands on time.',
      ),
    if (behind.isNotEmpty)
      (LucideIcons.triangleAlert, '${behind.length} ${behind.length == 1 ? 'goal is' : 'goals are'} behind, led by “${behind.first.title}”.'),
    if (d.openDecisions.isNotEmpty)
      (LucideIcons.gitFork, '${d.openDecisions.length} decisions are waiting; “${d.openDecisions.first.title}” affects this milestone most.'),
  ];
  showGSheet<void>(
    context,
    builder: (sheet) {
      final g = sheet.g;
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.paddingOf(sheet).bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GSheetHeader(title: 'Genie’s insight'),
            for (final p in points)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: g.aiSoft, shape: BoxShape.circle),
                      child: Icon(p.$1, size: 15, color: g.ai),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(p.$2, style: GType.bodyS.c(g.ink).copyWith(height: 1.45)),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            GPressable(
              scale: .97,
              semanticLabel: 'Ask Genie more',
              onTap: () {
                final nav = Navigator.of(sheet);
                nav.pop();
                openGenie(nav.context, ask: 'How is ${m.name} going and what should I do this week?');
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(color: g.ink, borderRadius: BorderRadius.circular(24)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GenieMark(size: 17, mono: g.onInk, dot: const Color(0xFF9B85FF)),
                    const SizedBox(width: 8),
                    Text('Ask Genie what to do this week', style: GType.label.c(g.onInk).w(FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
