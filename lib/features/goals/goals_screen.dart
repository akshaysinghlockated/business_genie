import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/business.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/parts.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/swap.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../shell/routes.dart';
import '../shell/tab_page.dart';
import 'goal_widgets.dart';

/// Goals and the milestone, with a status filter. Changing the filter
/// cross-fades the list instead of swapping it in one frame.
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key, this.asTab = false});

  /// In the bottom bar: the shared header instead of a back button.
  final bool asTab;

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  int _view = 0;
  GoalStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final body = Column(
      children: [
        GUnderlineTabs<int>(
          tabs: [(0, 'Goals', context.app.data?.goals.length), (1, 'Milestone', null)],
          value: _view,
          onChanged: (v) => setState(() => _view = v),
        ),
        Expanded(
          child: GLoadView(
            builder: (context, data) =>
                GSwap(id: _view, reverse: _view == 0, alignment: Alignment.topCenter, child: _view == 0 ? _goals(context, data) : _milestone(context, data)),
          ),
        ),
      ],
    );
    if (widget.asTab) {
      final d = context.app.data;
      final behind = d?.goals.where((x) => x.status == GoalStatus.behind).length ?? 0;
      return GTabPage(
        title: 'Goals',
        subtitle: d == null || d.goals.isEmpty ? 'Your plan' : (behind == 0 ? 'All on track' : '$behind behind plan'),
        child: body,
      );
    }
    return Scaffold(
      backgroundColor: g.ground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(GSpace.m, GSpace.s, GSpace.gutter, GSpace.s),
              child: Row(
                children: [
                  GRoundButton(icon: LucideIcons.arrowLeft, label: 'Back', onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: GSpace.m),
                  Expanded(child: Text('Goals', style: GType.h1.c(g.ink))),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _goals(BuildContext context, Snapshot data) {
    if (data.goals.isEmpty) {
      return ListView(
        children: [
          GEmptyState(
            icon: LucideIcons.target,
            title: 'No goals yet',
            body: 'Goals come from your business plan. Set them up on the web and they show here with their progress.',
            action: 'Set up goals',
            onAction: () => showWebOnly(context, 'Goal setting', LucideIcons.target),
          ),
        ],
      );
    }
    final list = _filter == null ? data.goals : data.goals.where((x) => x.status == _filter).toList();
    return Column(
      children: [
        const SizedBox(height: GSpace.m),
        GChipRow(
          children: [
            GChip(label: 'All', count: data.goals.length, selected: _filter == null, onTap: () => setState(() => _filter = null)),
            for (final s in GoalStatus.values)
              if (data.goals.any((x) => x.status == s))
                GChip(label: s.label, count: data.goals.where((x) => x.status == s).length, selected: _filter == s, onTap: () => setState(() => _filter = s)),
          ],
        ),
        const SizedBox(height: GSpace.s),
        Expanded(
          child: GSwap(
            id: _filter?.name ?? 'all',
            alignment: Alignment.topCenter,
            child: GRefresh(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.s, GSpace.gutter, 110),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: GSpace.m),
                itemBuilder: (context, i) => GoalCard(goal: list[i], owner: data.person(list[i].ownerId)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _milestone(BuildContext context, Snapshot data) {
    final g = context.g;
    final m = data.milestone;
    if (m == null) {
      return ListView(
        children: const [
          GEmptyState(
            icon: LucideIcons.flag,
            title: 'No milestone yet',
            body: 'Your plan’s first milestone appears once the business plan is confirmed on the web.',
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.l, GSpace.gutter, 110),
      children: [
        GCard(
          padding: const EdgeInsets.all(GSpace.l),
          child: Row(
            children: [
              GRing(value: m.progress, size: 76, stroke: 7),
              const SizedBox(width: GSpace.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name, style: GType.h3.c(g.ink)),
                    const SizedBox(height: 4),
                    Text('Week ${m.week} of ${m.weeks}', style: GType.bodyS.c(g.ink2)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: GSpace.l),
        GCard(
          padding: const EdgeInsets.fromLTRB(GSpace.s, GSpace.l, GSpace.s, GSpace.l),
          child: StageTrack(stage: m.stage),
        ),
        GSectionHeader(
          title: 'Key results',
          padding: const EdgeInsets.only(top: GSpace.xl, bottom: GSpace.m),
        ),
        for (final kr in m.krs)
          Padding(
            padding: const EdgeInsets.only(bottom: GSpace.l),
            child: KrRow(kr: kr),
          ),
        if (data.targets.isNotEmpty) ...[
          GSectionHeader(
            title: 'Plan targets',
            padding: const EdgeInsets.only(top: GSpace.l, bottom: GSpace.m),
          ),
          for (final t in data.targets)
            Padding(
              padding: const EdgeInsets.only(bottom: GSpace.l),
              child: KrRow(
                kr: KeyResult(title: t.label, target: t.target, current: t.current, progress: t.progress),
              ),
            ),
        ],
        if (data.vision.isNotEmpty) ...[
          const SizedBox(height: GSpace.s),
          GCard(
            padding: const EdgeInsets.all(GSpace.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vision', style: GType.label.c(g.ink3)),
                const SizedBox(height: 6),
                Text(data.vision, style: GType.body.c(g.ink)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
