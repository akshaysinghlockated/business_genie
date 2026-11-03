import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets/genie_mark.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/parts.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/swap.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../shell/routes.dart';

GTone decisionTone(DecisionTone t) => switch (t) {
  DecisionTone.offTrack => GTone.danger,
  DecisionTone.needsCall => GTone.warning,
  DecisionTone.ahead => GTone.success,
};

IconData decisionIcon(String source) => switch (source) {
  'Workforce plan' => LucideIcons.users,
  'Finance' => LucideIcons.wallet,
  'SOPs & workflows' => LucideIcons.workflow,
  _ => LucideIcons.gitFork,
};

/// A change somewhere in the company that needs the owner's call. Two
/// choices; once picked, the choice shows a tick and the other steps back,
/// with Undo for a mistap.
class DecisionCard extends StatelessWidget {
  const DecisionCard({super.key, required this.decision});

  final Decision decision;

  void _pick(BuildContext context, int i) {
    final app = context.appRead;
    app.choose(decision.id, i);
    GHaptics.heavy();
    GToast.show(context, '“${decision.options[i]}” saved', action: 'Undo', onAction: () => app.undoChoice(decision.id));
  }

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final d = decision;
    return GCard(
      onTap: () => showDecisionSheet(context, d),
      semanticLabel: '${d.title}. ${d.tone.label}. ${d.effect}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(decisionIcon(d.source), size: 15, color: g.ink3),
              const SizedBox(width: 6),
              Expanded(
                child: Text('${d.source} · ${d.ago}', maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.caption.c(g.ink3)),
              ),
              const SizedBox(width: 8),
              GStatusPill(label: d.tone.label, tone: decisionTone(d.tone)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: Text(d.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GType.title.c(g.ink).copyWith(height: 1.35)),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(d.tone == DecisionTone.ahead ? LucideIcons.trendingUp : LucideIcons.trendingDown, size: 15, color: g.ink2),
              const SizedBox(width: 6),
              Expanded(child: Text(d.effect, style: GType.bodyS.c(g.ink2))),
            ],
          ),
          const SizedBox(height: 14),
          GSwap(
            id: d.picked ?? -1,
            child: d.picked == null
                ? Row(
                    children: [
                      for (var i = 0; i < d.options.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Flexible(
                          child: GButton(
                            label: d.options[i],
                            compact: true,
                            kind: i == 0 ? GButtonKind.primary : GButtonKind.secondary,
                            onTap: () => _pick(context, i),
                          ),
                        ),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      Flexible(
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: GShape.fill(g.stone, GRadius.pill),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.check, size: 15, color: g.ink),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  d.options[d.picked!],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GType.caption.c(g.ink).w(FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      for (var i = 0; i < d.options.length; i++)
                        if (i != d.picked)
                          Flexible(
                            child: Opacity(
                              opacity: .4,
                              child: Text(
                                d.options[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GType.caption.c(g.ink2).copyWith(decoration: TextDecoration.lineThrough),
                              ),
                            ),
                          ),
                      const Spacer(),
                      GTextAction(label: 'Undo', onTap: () => context.appRead.undoChoice(d.id)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// The full story behind a decision, its choices, and a way to ask Genie.
void showDecisionSheet(BuildContext context, Decision d) {
  showGSheet<void>(
    context,
    builder: (context) {
      final g = context.g;
      final app = context.app;
      final live = app.data?.decisions.where((x) => x.id == d.id).firstOrNull ?? d;
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GSheetHeader(title: 'Decision'),
            Padding(
              padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.s, GSpace.gutter, GSpace.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GIconBox(icon: decisionIcon(live.source), size: 32),
                      const SizedBox(width: 10),
                      Expanded(child: Text('${live.source} · ${live.ago}', style: GType.label.c(g.ink2))),
                      GStatusPill(label: live.tone.label, tone: decisionTone(live.tone)),
                    ],
                  ),
                  const SizedBox(height: GSpace.l),
                  Text(live.title, style: GType.h2.c(g.ink)),
                  const SizedBox(height: GSpace.s),
                  Text(live.detail, style: GType.body.c(g.ink2)),
                  const SizedBox(height: GSpace.m),
                  GCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    radius: GRadius.tile,
                    child: Row(
                      children: [
                        Icon(LucideIcons.flag, size: 16, color: g.ink2),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Effect: ${live.effect}', style: GType.label.c(g.ink))),
                      ],
                    ),
                  ),
                  const SizedBox(height: GSpace.xl),
                  if (live.picked == null) ...[
                    for (var i = 0; i < live.options.length; i++) ...[
                      GButton(
                        label: live.options[i],
                        expand: true,
                        kind: i == 0 ? GButtonKind.primary : GButtonKind.secondary,
                        onTap: () {
                          app.choose(live.id, i);
                          GHaptics.heavy();
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: GChip(label: live.options[live.picked!], selected: true, onTap: () {}),
                        ),
                        GTextAction(label: 'Undo', onTap: () => app.undoChoice(live.id)),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Center(
                    child: GPressable(
                      semanticLabel: 'Ask Genie about this',
                      onTap: () {
                        final nav = Navigator.of(context);
                        nav.pop();
                        openGenie(nav.context, ask: 'Explain: ${live.title}');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GenieMark(size: 17, mono: g.ink3, dot: g.ai),
                            const SizedBox(width: 6),
                            Text('Ask Genie about this', style: GType.label.c(g.ai).w(FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
