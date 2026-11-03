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
import '../../data/models.dart';
import '../shell/routes.dart';

/// A meeting's details: when, where, who, the agenda and any notes.
void showMeetingSheet(BuildContext context, Meeting m) {
  showGSheet<void>(context, builder: (_) => _MeetingSheet(meeting: m));
}

class _MeetingSheet extends StatelessWidget {
  const _MeetingSheet({required this.meeting});

  final Meeting meeting;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final m = meeting;
    final now = DateTime.now();
    final st = m.stateAt(now);
    final host = context.app.data?.person(m.hostId);
    final (label, tone) = switch (st) {
      MeetingState.live => ('Live · ${m.end.difference(now).inMinutes.clamp(1, 999)} min left', GTone.danger),
      MeetingState.done => ('Completed', GTone.neutral),
      MeetingState.cancelled => ('Cancelled', GTone.danger),
      MeetingState.next => ('Scheduled', GTone.accent),
    };
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GSheetHeader(title: 'Meeting'),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.s, GSpace.gutter, GSpace.l),
                children: [
                  Row(
                    children: [
                      GStatusPill(label: label, tone: tone),
                      const SizedBox(width: 8),
                      GTag(GFormat.shortDept(m.dept), dot: GFormat.dept(m.dept)),
                    ],
                  ),
                  const SizedBox(height: GSpace.m),
                  Text(m.title, style: GType.h1.c(g.ink).copyWith(decoration: st == MeetingState.cancelled ? TextDecoration.lineThrough : null)),
                  const SizedBox(height: GSpace.l),
                  _Line(
                    icon: LucideIcons.clock,
                    text: '${GFormat.dayName(m.start, now)}, ${GFormat.time(m.start)} – ${GFormat.time(m.end)} (${GFormat.minutes(m.minutes)})',
                  ),
                  _Line(icon: m.online ? LucideIcons.video : LucideIcons.mapPin, text: m.place),
                  if (host != null) _Line(icon: LucideIcons.user, text: 'Hosted by ${host.id == 'me' ? 'you' : host.name}'),
                  if (m.agenda.isNotEmpty) ...[
                    const SizedBox(height: GSpace.l),
                    Text('Agenda', style: GType.label.c(g.ink3)),
                    const SizedBox(height: 6),
                    for (var i = 0; i < m.agenda.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: g.card, shape: BoxShape.circle),
                              child: Text('${i + 1}', style: GType.micro.c(g.ink2)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(m.agenda[i], style: GType.body.c(g.ink))),
                          ],
                        ),
                      ),
                  ],
                  if (m.notes != null) ...[
                    const SizedBox(height: GSpace.l),
                    GCard(
                      radius: GRadius.tile,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.notebookPen, size: 15, color: g.ink2),
                              const SizedBox(width: 6),
                              Text('Minutes · written by Genie', style: GType.caption.c(g.ink2)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(m.notes!, style: GType.body.c(g.ink)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: GSpace.l),
                  Text('People · ${m.people.length}', style: GType.label.c(g.ink3)),
                  const SizedBox(height: 4),
                  for (final n in m.people)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          GAvatar(name: n, size: 30),
                          const SizedBox(width: 10),
                          Expanded(child: Text(n, style: GType.label.c(g.ink))),
                          Text(n == m.people.first ? 'Organiser' : 'Going', style: GType.caption.c(g.ink3)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (st != MeetingState.cancelled)
              Padding(
                padding: const EdgeInsets.fromLTRB(GSpace.gutter, 0, GSpace.gutter, GSpace.m),
                child: Row(
                  children: [
                    Expanded(
                      child: GButton(
                        label: st == MeetingState.done ? 'Ask Genie for notes' : 'Ask Genie',
                        kind: GButtonKind.secondary,
                        icon: LucideIcons.messageSquareText,
                        onTap: () {
                          final nav = Navigator.of(context);
                          nav.pop();
                          openGenie(nav.context, ask: st == MeetingState.done ? 'Summarise ${m.title}' : 'Prep me for ${m.title}');
                        },
                      ),
                    ),
                    if (m.online && st != MeetingState.done) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: GButton(
                          label: 'Join',
                          icon: LucideIcons.video,
                          onTap: () => GToast.show(context, 'Opening ${m.place}…', type: GToastType.info),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: g.ink3),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GType.body.c(g.ink))),
        ],
      ),
    );
  }
}
