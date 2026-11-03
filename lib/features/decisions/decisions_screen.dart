import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/swap.dart';
import '../shell/tab_page.dart';
import 'decision_card.dart';

/// Everything waiting on the owner's call, and what was already decided.
class DecisionsScreen extends StatefulWidget {
  const DecisionsScreen({super.key, this.embedded = false});

  /// True inside Home's Decisions tab: no page header of its own.
  final bool embedded;

  @override
  State<DecisionsScreen> createState() => _DecisionsScreenState();
}

class _DecisionsScreenState extends State<DecisionsScreen> {
  bool _decided = false;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final content = [
      widget.embedded
          ? Padding(
              padding: const EdgeInsets.only(top: GSpace.s, bottom: GSpace.s),
              child: GChipRow(
                children: [
                  GChip(label: 'Open', selected: !_decided, onTap: () => setState(() => _decided = false)),
                  GChip(label: 'Decided', selected: _decided, onTap: () => setState(() => _decided = true)),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.l, GSpace.gutter, GSpace.s),
              child: GSegmented<bool>(options: const [(false, 'Open'), (true, 'Decided')], value: _decided, onChanged: (v) => setState(() => _decided = v)),
            ),
      Expanded(
        child: GLoadView(
          builder: (context, data) {
            final list = data.decisions.where((d) => _decided ? d.picked != null : d.picked == null).toList();
            return GSwap(
              id: _decided,
              reverse: !_decided,
              alignment: Alignment.topCenter,
              child: list.isEmpty
                  ? ListView(
                      children: [
                        GEmptyState(
                          icon: _decided ? LucideIcons.history : LucideIcons.circleCheckBig,
                          title: _decided ? 'Nothing decided yet' : 'Nothing waiting on you',
                          body: _decided
                              ? 'Decisions you make show here, so you can see what was chosen and undo a mistap.'
                              : 'When hiring, finance or a workflow changes the plan, Genie brings the decision here.',
                        ),
                      ],
                    )
                  : GRefresh(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.s, GSpace.gutter, GSpace.navClearance),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: GSpace.m),
                        itemBuilder: (context, i) => DecisionCard(key: ValueKey(list[i].id), decision: list[i]),
                      ),
                    ),
            );
          },
        ),
      ),
    ];
    if (widget.embedded) return Column(crossAxisAlignment: CrossAxisAlignment.start, children: content);
    return GPushPage(
      title: 'Decisions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.m, GSpace.gutter, 0),
            child: Text('Changes in other areas that affect the plan and need your call.', style: GType.bodyS.c(g.ink2)),
          ),
          ...content,
        ],
      ),
    );
  }
}
