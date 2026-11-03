import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/pressable.dart';
import '../../data/models.dart';
import '../shell/shell.dart';

/// A number that counts up to [value] the first time it shows.
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, required this.style, this.suffix = ''});

  final int value;
  final TextStyle style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: GMotion.of(context, const Duration(milliseconds: 1100)),
      curve: GMotion.easeOut,
      builder: (context, v, _) => Text('${v.round()}$suffix', style: style.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
    );
  }
}

/// Where the company stands, first on Home: the milestone and how far along
/// it is, whether it is ahead of the weeks used, the road from Foundation to
/// BHAG, what needs attention, and the key results on demand.
class MilestoneHero extends StatefulWidget {
  const MilestoneHero({super.key, required this.milestone, required this.behind, required this.decisions, this.results = true});

  final Milestone milestone;
  final int behind, decisions;

  /// False where the key results are listed right below (the Milestone tab).
  final bool results;

  @override
  State<MilestoneHero> createState() => _MilestoneHeroState();
}

class _MilestoneHeroState extends State<MilestoneHero> {
  bool _open = false;

  static const stages = ['Foundation', 'Short', 'Mid', 'Long', 'BHAG'];

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final m = widget.milestone;
    final pace = m.progress - m.week / m.weeks;
    final (paceLabel, paceColor, paceSoft) = pace >= .05
        ? ('Ahead of pace', g.success, g.successSoft)
        : pace <= -.05
        ? ('Behind pace', g.danger, g.dangerSoft)
        : ('On pace', g.ink2, g.card);
    return GPressable(
      scale: .99,
      semanticLabel: '${m.name}, ${(m.progress * 100).round()} percent, week ${m.week} of ${m.weeks}. Open milestone',
      onTap: () => shellKey.currentState?.goTab(Tabs.milestone),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: GShape.lifted(g.surface, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Milestone ${m.stage + 1} of ${stages.length}', style: GType.label.c(g.ink3)),
                const Spacer(),
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(color: paceSoft, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: paceColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(paceLabel, style: GType.caption.c(paceColor).w(FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    stages.contains(m.name.split(' · ').last) ? m.name.split(' · ').last : m.name.replaceFirst(RegExp(r'^Milestone \d+ · '), ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GType.display.c(g.ink).copyWith(fontSize: 36, height: 1.05, letterSpacing: -1.4, fontWeight: FontWeight.w700),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CountUp(value: (m.progress * 100).round(), style: GType.numeral.c(g.ink).copyWith(fontSize: 36, height: 1.05, letterSpacing: -1.2)),
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text('%', style: GType.label.c(g.ink3)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Week ${m.week} of ${m.weeks} · ${m.weeks - m.week} weeks to go', style: GType.label.c(g.ink3)),
            const SizedBox(height: 18),
            _StageBar(stage: m.stage, progress: m.progress, stages: stages),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.behind > 0) _Chip(icon: LucideIcons.triangleAlert, label: '${widget.behind} goals behind', color: g.danger),
                if (widget.decisions > 0) _Chip(icon: LucideIcons.gitFork, label: '${widget.decisions} decisions waiting', color: g.ink2),
              ],
            ),
            if (widget.results) ...[
              const SizedBox(height: 16),
              GPressable(
                scale: .97,
                semanticLabel: _open ? 'Hide key results' : 'See key results',
                onTap: () {
                  GHaptics.select();
                  setState(() => _open = !_open);
                },
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(color: g.ink, borderRadius: BorderRadius.circular(25)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _open ? 'Hide key results' : 'See ${m.krs.length} key results',
                        style: GType.label.c(g.onInk).w(FontWeight.w600).copyWith(fontSize: 14.5),
                      ),
                      const SizedBox(width: 6),
                      AnimatedRotation(
                        turns: _open ? .5 : 0,
                        duration: GMotion.of(context, GMotion.enter),
                        curve: GMotion.easeOut,
                        child: Icon(LucideIcons.chevronDown, size: 17, color: g.onInk),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: GMotion.of(context, const Duration(milliseconds: 360)),
                curve: GMotion.easeOut,
                alignment: Alignment.topCenter,
                child: _open
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(children: [for (final kr in m.krs) _Kr(kr: kr)]),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(color: g.card, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: GType.caption.c(g.ink).copyWith(fontSize: 12.5)),
        ],
      ),
    );
  }
}

/// Foundation → Short → Mid → Long → BHAG as five segments: stages done in
/// ink, the current one filling to its progress, the rest pale.
class _StageBar extends StatelessWidget {
  const _StageBar({required this.stage, required this.progress, required this.stages});

  final int stage;
  final double progress;
  final List<String> stages;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0, 1)),
      duration: GMotion.of(context, const Duration(milliseconds: 1100)),
      curve: GMotion.easeOut,
      builder: (context, v, _) => Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < stages.length; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: Stack(
                        children: [
                          Container(color: i < stage ? g.ink : g.ink.withValues(alpha: .08)),
                          if (i == stage)
                            FractionallySizedBox(
                              widthFactor: v,
                              child: Container(color: g.ink),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < stages.length; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    stages[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GType.micro.c(i == stage ? g.ink : g.ink3).w(i == stage ? FontWeight.w700 : FontWeight.w500).copyWith(letterSpacing: 0),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Kr extends StatelessWidget {
  const _Kr({required this.kr});

  final KeyResult kr;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final p = kr.progress;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(kr.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.label.c(g.ink).copyWith(fontSize: 13.5)),
              ),
              const SizedBox(width: 10),
              Text(
                p == null ? 'No reading yet' : '${kr.current ?? '${(p * 100).round()}%'} / ${kr.target}',
                style: GType.caption.c(g.ink3).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 5,
              child: Stack(
                children: [
                  Container(color: g.ink.withValues(alpha: .08)),
                  if (p != null)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: p.clamp(0, 1)),
                      duration: GMotion.of(context, const Duration(milliseconds: 700)),
                      curve: GMotion.easeOut,
                      builder: (context, v, _) => FractionallySizedBox(
                        widthFactor: v,
                        child: Container(color: g.ink),
                      ),
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
