import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/parts.dart';
import '../../data/app_state.dart';
import '../people/person_sheet.dart';
import '../shell/routes.dart';
import 'goal_widgets.dart';

/// One goal: status, owner, progress, its key results and the latest
/// updates. The one main action is asking Genie about it.
class GoalDetailScreen extends StatelessWidget {
  const GoalDetailScreen({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final data = context.app.data;
    final x = data?.goals.where((x) => x.id == goalId).firstOrNull;
    if (data == null || x == null) {
      return Scaffold(
        backgroundColor: g.surface,
        appBar: AppBar(backgroundColor: g.surface),
        body: const SizedBox.shrink(),
      );
    }
    final owner = data.person(x.ownerId);
    return Scaffold(
      backgroundColor: g.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(GSpace.m, GSpace.s, GSpace.m, 0),
              child: Row(
                children: [
                  GRoundButton(icon: LucideIcons.arrowLeft, label: 'Back', onTap: () => Navigator.of(context).pop()),
                  const Spacer(),
                  GRoundButton(
                    icon: LucideIcons.share2,
                    label: 'Share',
                    onTap: () => GToast.show(context, 'Sharing comes with team chat.', type: GToastType.info),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.l, GSpace.gutter, GSpace.xl),
                children: [
                  Row(
                    children: [
                      GStatusPill(label: x.status.label, tone: goalTone(x.status)),
                      const SizedBox(width: 8),
                      GTag('Due ${x.due}'),
                    ],
                  ),
                  const SizedBox(height: GSpace.m),
                  Text(x.title, style: GType.h1.c(g.ink)),
                  if (x.why.isNotEmpty) ...[const SizedBox(height: 6), Text(x.why, style: GType.body.c(g.ink2).copyWith(fontStyle: FontStyle.italic))],
                  const SizedBox(height: GSpace.l),
                  Row(
                    children: [
                      if (owner != null)
                        Expanded(
                          child: GCard(
                            radius: GRadius.tile,
                            padding: const EdgeInsets.all(12),
                            onTap: () => showPersonSheet(context, owner),
                            child: Row(
                              children: [
                                GAvatar(name: owner.name, size: 32),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Owner', style: GType.micro.c(g.ink3).w(FontWeight.w500)),
                                      Text(owner.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.label.c(g.ink).w(FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GCard(
                          radius: GRadius.tile,
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: GShape.fill(g.surface, 10),
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(color: GFormat.dept(x.dept), shape: BoxShape.circle),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Department', style: GType.micro.c(g.ink3).w(FontWeight.w500)),
                                    Text(
                                      GFormat.shortDept(x.dept),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GType.label.c(g.ink).w(FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: GSpace.l),
                  GCard(
                    padding: const EdgeInsets.all(GSpace.l),
                    child: x.progress == null
                        ? Row(
                            children: [
                              const GIconBox(icon: LucideIcons.hourglass, size: 40),
                              const SizedBox(width: 12),
                              Expanded(child: Text('No reading yet. Progress shows after the owner’s first update.', style: GType.bodyS.c(g.ink2))),
                            ],
                          )
                        : Row(
                            children: [
                              GRing(value: x.progress!, size: 72, stroke: 7, color: goalColor(x.status, g)),
                              const SizedBox(width: GSpace.l),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${x.krs.where((k) => (k.progress ?? 0) >= 1).length} of ${x.krs.length} key results met',
                                      style: GType.title.c(g.ink),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Progress is the average of the key results with a reading.', style: GType.caption.c(g.ink3)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                  GSectionHeader(
                    title: 'Key results',
                    padding: const EdgeInsets.only(top: GSpace.xl, bottom: GSpace.m),
                  ),
                  for (final kr in x.krs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: GSpace.l),
                      child: KrRow(kr: kr),
                    ),
                  GSectionHeader(
                    title: 'Latest',
                    padding: const EdgeInsets.only(top: GSpace.s, bottom: GSpace.s),
                  ),
                  if (x.updates.isEmpty)
                    Text('No updates yet.', style: GType.bodyS.c(g.ink3))
                  else
                    for (final u in x.updates)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GAvatar(name: u.by, size: 30),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u.text, style: GType.body.c(g.ink)),
                                  const SizedBox(height: 2),
                                  Text('${u.by} · ${u.ago}', style: GType.caption.c(g.ink3)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.s, GSpace.gutter, GSpace.m),
              child: Row(
                children: [
                  Expanded(
                    child: GButton(
                      label: owner == null ? 'Ask for an update' : 'Ask ${owner.first} for an update',
                      kind: GButtonKind.secondary,
                      onTap: () => GToast.show(context, 'Update request sent to ${owner?.first ?? 'the owner'}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GButton(
                      label: 'Ask Genie',
                      icon: LucideIcons.messageSquareText,
                      onTap: () => openGenie(context, ask: 'How is "${x.title}" going?'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
