import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/parts.dart';
import '../../core/widgets/pressable.dart';
import '../../data/models.dart';
import '../shell/routes.dart';

GTone goalTone(GoalStatus s) => switch (s) {
  GoalStatus.onTrack => GTone.success,
  GoalStatus.behind => GTone.danger,
  GoalStatus.achieved => GTone.accent,
  GoalStatus.notStarted => GTone.neutral,
};

Color goalColor(GoalStatus s, GPalette g) => switch (s) {
  GoalStatus.onTrack => g.success,
  GoalStatus.behind => g.danger,
  GoalStatus.achieved => g.accent,
  GoalStatus.notStarted => g.ink4,
};

/// The current milestone: where the company is in its plan. Opens to show
/// the milestone's key results; the stage track sits underneath.
class MilestoneCard extends StatefulWidget {
  const MilestoneCard({super.key, required this.milestone, this.targets = const []});

  final Milestone milestone;
  final List<PlanTarget> targets;

  @override
  State<MilestoneCard> createState() => _MilestoneCardState();
}

class _MilestoneCardState extends State<MilestoneCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final m = widget.milestone;
    return GCard(
      onTap: () {
        GHaptics.select();
        setState(() => _open = !_open);
      },
      semanticLabel: '${m.name}, ${(m.progress * 100).round()} percent, week ${m.week} of ${m.weeks}. ${_open ? 'Collapse' : 'Expand'}',
      padding: const EdgeInsets.all(GSpace.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name, style: GType.title.c(g.ink)),
                    const SizedBox(height: 2),
                    Text('Week ${m.week} of ${m.weeks}', style: GType.caption.c(g.ink3)),
                  ],
                ),
              ),
              Text('${(m.progress * 100).round()}%', style: GType.numeral.copyWith(fontSize: 26, color: g.ink)),
            ],
          ),
          const SizedBox(height: 12),
          GProgressBar(value: m.progress, height: 8),
          AnimatedSize(
            duration: GMotion.of(context, GMotion.enter),
            curve: GMotion.easeOut,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.only(top: GSpace.l),
                    child: Column(
                      children: [
                        for (final kr in m.krs)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: KrRow(kr: kr),
                          ),
                        if (widget.targets.isNotEmpty) ...[
                          const GRule(),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              for (var i = 0; i < widget.targets.length; i++) ...[
                                if (i > 0) const SizedBox(width: 10),
                                Expanded(child: _TargetMini(t: widget.targets[i])),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: GSpace.l),
          StageTrack(stage: m.stage),
          const SizedBox(height: 4),
          Center(
            child: AnimatedRotation(
              turns: _open ? .5 : 0,
              duration: GMotion.of(context, GMotion.quick),
              child: Icon(LucideIcons.chevronDown, size: 18, color: g.ink3),
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetMini extends StatelessWidget {
  const _TargetMini({required this.t});

  final PlanTarget t;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(t.current, style: GType.figure.c(g.ink)),
        ),
        Text('of ${t.target}', maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.micro.c(g.ink3).w(FontWeight.w500)),
        const SizedBox(height: 6),
        GProgressBar(value: t.progress, height: 4),
        const SizedBox(height: 4),
        Text(t.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.micro.c(g.ink2).w(FontWeight.w500)),
      ],
    );
  }
}

/// A key result: its name, its reading against target, and a bar. Before the
/// first reading it says so instead of showing 0%.
class KrRow extends StatelessWidget {
  const KrRow({super.key, required this.kr});

  final KeyResult kr;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(kr.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.label.c(g.ink)),
            ),
            const SizedBox(width: 8),
            Text(
              kr.progress == null ? 'No reading yet' : '${kr.current ?? ''} / ${kr.target}',
              style: (kr.progress == null ? GType.caption.c(g.ink3) : GType.caption.c(g.ink2)).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (kr.progress != null) GProgressBar(value: kr.progress!, height: 5) else Container(height: 5, decoration: GShape.fill(g.ruleStrong, 3)),
      ],
    );
  }
}

/// Foundation → Short → Mid → Long → BHAG, with the current stage marked.
class StageTrack extends StatelessWidget {
  const StageTrack({super.key, required this.stage});

  final int stage;

  static const stages = ['Foundation', 'Short', 'Mid', 'Long', 'BHAG'];

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Column(
      children: [
        SizedBox(
          height: 16,
          child: LayoutBuilder(
            builder: (context, box) {
              final step = box.maxWidth / stages.length;
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Positioned(
                    left: step / 2,
                    right: step / 2,
                    child: Container(height: 2, color: g.ruleStrong),
                  ),
                  for (var i = 0; i < stages.length; i++)
                    Positioned(
                      left: step * i + step / 2 - (i == stage ? 8 : 5),
                      child: Container(
                        width: i == stage ? 16 : 10,
                        height: i == stage ? 16 : 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i <= stage ? g.ink : g.surface,
                          border: Border.all(color: i <= stage ? g.ink : g.ink4, width: 2),
                          boxShadow: i == stage ? [BoxShadow(color: g.ink.withValues(alpha: .15), spreadRadius: 4)] : null,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < stages.length; i++)
              Expanded(
                child: Text(
                  stages[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GType.micro.c(i == stage ? g.ink : g.ink3).w(i == stage ? FontWeight.w700 : FontWeight.w500),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// All goals at a glance: one bar split by status, the counts, and the goals
/// that are behind.
class GoalsSummaryCard extends StatelessWidget {
  const GoalsSummaryCard({super.key, required this.data});

  final Snapshot data;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final goals = data.goals;
    final counts = {for (final s in GoalStatus.values) s: goals.where((x) => x.status == s).length};
    final behind = goals.where((x) => x.status == GoalStatus.behind).toList();
    return GCard(
      padding: const EdgeInsets.all(GSpace.l),
      onTap: () => openGoals(context),
      semanticLabel: '${goals.length} business goals',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${goals.length}', style: GType.numeral.c(g.ink)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(goals.length == 1 ? 'goal this year' : 'goals this year', style: GType.label.c(g.ink2)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  for (final s in GoalStatus.values)
                    if (counts[s]! > 0)
                      Expanded(
                        flex: counts[s]!,
                        child: Container(margin: const EdgeInsets.only(right: 2), color: goalColor(s, g)),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final s in GoalStatus.values)
                if (counts[s]! > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: goalColor(s, g), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text('${counts[s]} ${s.label.toLowerCase()}', style: GType.caption.c(g.ink2)),
                    ],
                  ),
            ],
          ),
          if (behind.isNotEmpty) ...[
            const SizedBox(height: 14),
            const GRule(),
            const SizedBox(height: 6),
            for (final x in behind)
              GPressable(
                scale: .98,
                semanticLabel: '${x.title}, behind',
                onTap: () => openGoal(context, x.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(LucideIcons.triangleAlert, size: 16, color: g.danger),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(x.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.label.c(g.ink)),
                      ),
                      Text(data.person(x.ownerId)?.first ?? '', style: GType.caption.c(g.ink3)),
                      Icon(LucideIcons.chevronRight, size: 16, color: g.ink3),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// One goal in a list: due, status, title, owner, department, progress.
class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.goal, required this.owner});

  final Goal goal;
  final Person? owner;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final x = goal;
    final withReading = x.krs.where((k) => k.progress != null).length;
    return GCard(
      color: g.surface,
      border: true,
      onTap: () => openGoal(context, x.id),
      semanticLabel: '${x.title}, ${x.status.label}, due ${x.due}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.calendar, size: 14, color: g.ink3),
              const SizedBox(width: 6),
              Text('Due ${x.due}', style: GType.caption.c(g.ink3)),
              const Spacer(),
              GStatusPill(label: x.status.label, tone: goalTone(x.status)),
            ],
          ),
          const SizedBox(height: 10),
          Text(x.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.h3.c(g.ink)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (owner != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GAvatar(name: owner!.name, size: 22),
                    const SizedBox(width: 6),
                    Text(owner!.name, style: GType.caption.c(g.ink2)),
                    const SizedBox(width: 6),
                  ],
                ),
              GTag(GFormat.shortDept(x.dept), dot: GFormat.dept(x.dept)),
            ],
          ),
          const SizedBox(height: 14),
          if (x.progress != null) ...[
            GProgressBar(value: x.progress!, color: goalColor(x.status, g), height: 8),
            const SizedBox(height: 8),
            Text('${(x.progress! * 100).round()}% · $withReading of ${x.krs.length} key results reading', style: GType.caption.c(g.ink3)),
          ] else
            Text('No reading yet. Progress shows after the first update.', style: GType.caption.c(g.ink3)),
        ],
      ),
    );
  }
}
