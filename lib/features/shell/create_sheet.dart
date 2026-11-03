import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/genie_mark.dart';
import '../../core/widgets/input.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/parts.dart';
import '../tasks/new_task_sheet.dart';
import 'routes.dart';

/// "+": type anything, then choose what it becomes. The most used choices
/// come first; areas that live on the web say so.
void showCreateSheet(BuildContext context) {
  showGSheet<void>(context, builder: (_) => const _CreateSheet());
}

class _CreateSheet extends StatefulWidget {
  const _CreateSheet();

  @override
  State<_CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends State<_CreateSheet> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _then(void Function(BuildContext root, String text) f) {
    final text = _text.text.trim();
    final nav = Navigator.of(context);
    final root = nav.context;
    nav.pop();
    f(root, text);
  }

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GSheetHeader(title: 'Create'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: GSpace.gutter),
              child: GInput(hint: 'Monday standup agenda', controller: _text, icon: LucideIcons.pencilLine, textCapitalization: TextCapitalization.sentences),
            ),
            const SizedBox(height: GSpace.m),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: GSpace.gutter),
              child: Container(
                padding: const EdgeInsets.all(GSpace.m),
                decoration: GShape.fill(g.aiSoft, GRadius.tile),
                child: Row(
                  children: [
                    Container(width: 36, height: 36, alignment: Alignment.center, decoration: GShape.fill(g.surface, 12), child: const GenieMark(size: 20)),
                    const SizedBox(width: GSpace.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Just start typing', style: GType.title.c(g.ink)),
                          Text('“Call Arjun after the board meeting on the 3rd” becomes a task with a date.', style: GType.caption.c(g.ink2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: GSpace.s),
            GRow(
              leading: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: context.g.aiSoft, borderRadius: BorderRadius.circular(10)),
                child: const GenieMark(size: 19),
              ),
              title: 'Ask Genie',
              subtitle: 'Brief me, what’s off track, plan my day',
              onTap: () => _then((root, t) => openGenie(root, ask: t.isEmpty ? null : t)),
            ),
            GRow(
              leading: const GIconBox(icon: LucideIcons.circleCheck),
              title: 'Task',
              subtitle: 'For you or someone on the team',
              onTap: () => _then((root, t) => showNewTaskSheet(root, title: t)),
            ),
            GRow(
              leading: const GIconBox(icon: LucideIcons.alarmClock),
              title: 'Reminder',
              subtitle: 'A task just for you, marked Only me',
              onTap: () => _then((root, t) => showNewTaskSheet(root, title: t, private: true)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.l, GSpace.gutter, GSpace.xs),
              child: Text('More', style: GType.label.c(g.ink3)),
            ),
            GRow(
              leading: const GIconBox(icon: LucideIcons.calendarPlus),
              title: 'Meeting',
              onTap: () => _then((root, _) => showWebOnly(root, 'Scheduling', LucideIcons.calendarPlus)),
            ),
            GRow(
              leading: const GIconBox(icon: LucideIcons.target),
              title: 'Goal',
              onTap: () => _then((root, _) => showWebOnly(root, 'Goal setting', LucideIcons.target)),
            ),
            GRow(
              leading: const GIconBox(icon: LucideIcons.userPlus),
              title: 'Invite a teammate',
              onTap: () => _then((root, _) => showWebOnly(root, 'Invitations', LucideIcons.userPlus)),
            ),
            const SizedBox(height: GSpace.l),
          ],
        ),
      ),
    );
  }
}
