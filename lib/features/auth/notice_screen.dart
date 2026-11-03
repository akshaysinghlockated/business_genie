import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/parts.dart';
import '../../data/app_state.dart';

/// Shown once, on first sign-in: what Business Genie keeps and why. The
/// person accepts before going on.
class NoticeScreen extends StatelessWidget {
  const NoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    const points = [
      (LucideIcons.building2, 'Your company plan', 'Goals, milestones and departments, so Genie can show where the company stands.'),
      (LucideIcons.listChecks, 'Your work', 'Tasks, meetings and decisions, so your day is in one place.'),
      (LucideIcons.lock, 'Private stays private', 'Tasks marked “Only me” are seen by you alone. Not by your heads, not by Genie’s summaries for others.'),
      (LucideIcons.hand, 'You decide', 'Genie drafts. Nothing is sent, approved or published until you press the button.'),
    ];
    return Scaffold(
      backgroundColor: g.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(GSpace.xl, GSpace.xxxl, GSpace.xl, GSpace.xl),
                children: [
                  Text('Before you start', style: GType.display.c(g.ink)),
                  const SizedBox(height: GSpace.s),
                  Text('Here is what Business Genie keeps, and why.', style: GType.body.c(g.ink2)),
                  const SizedBox(height: GSpace.xl),
                  for (final p in points)
                    Padding(
                      padding: const EdgeInsets.only(bottom: GSpace.l),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GIconBox(icon: p.$1, size: 40),
                          const SizedBox(width: GSpace.m),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.$2, style: GType.title.c(g.ink)),
                                const SizedBox(height: 2),
                                Text(p.$3, style: GType.bodyS.c(g.ink2)),
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
              padding: const EdgeInsets.fromLTRB(GSpace.xl, 0, GSpace.xl, GSpace.l),
              child: GButton(label: 'I understand, continue', expand: true, height: 52, onTap: context.appRead.acceptNotice),
            ),
          ],
        ),
      ),
    );
  }
}
