import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/parts.dart';
import '../../core/widgets/pressable.dart';
import '../../data/models.dart';

/// A teammate: who they are, how to reach them, and today at a glance.
void showPersonSheet(BuildContext context, Person p) {
  showGSheet<void>(context, builder: (_) => _PersonSheet(person: p));
}

class _PersonSheet extends StatelessWidget {
  const _PersonSheet({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final p = person;
    final dot = p.live ? g.danger : (p.behind ? g.warning : (p.reportFiled ? g.success : null));
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GSheetHeader(title: ''),
            GAvatar(name: p.name, size: 88, dot: dot),
            const SizedBox(height: GSpace.m),
            Text(p.name, style: GType.h2.c(g.ink)),
            const SizedBox(height: 2),
            Text(p.role, style: GType.body.c(g.ink2)),
            const SizedBox(height: 10),
            GTag(GFormat.shortDept(p.dept), dot: GFormat.dept(p.dept)),
            if (p.today != null) ...[
              const SizedBox(height: GSpace.l),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: GSpace.gutter),
                child: GCard(
                  radius: GRadius.tile,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(p.live ? LucideIcons.radio : (p.reportFiled ? LucideIcons.fileCheck : LucideIcons.clock), size: 18, color: dot ?? g.ink2),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Today: ${p.today}', style: GType.label.c(g.ink))),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: GSpace.l),
            _Contact(icon: LucideIcons.mail, label: 'Email', value: p.email),
            _Contact(icon: LucideIcons.phone, label: 'Phone', value: p.phone),
            if (p.about.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.l, GSpace.gutter, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About', style: GType.label.c(g.ink3)),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: Text(p.about, style: GType.body.c(g.ink)),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.xl, GSpace.gutter, GSpace.l),
              child: Row(
                children: [
                  Expanded(
                    child: GButton(
                      label: 'Today’s report',
                      kind: GButtonKind.secondary,
                      icon: LucideIcons.fileText,
                      onTap: p.reportFiled
                          ? () => GToast.show(context, 'Reports open on the web for now.', type: GToastType.info)
                          : () => GToast.show(context, '${p.first} hasn’t filed today’s report yet.', type: GToastType.warning),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GButton(
                      label: 'Message',
                      icon: LucideIcons.messageSquare,
                      onTap: () => GToast.show(context, 'Team chat is coming to the app. Call or email for now.', type: GToastType.info),
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

class _Contact extends StatelessWidget {
  const _Contact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(GSpace.gutter, 0, GSpace.gutter, 8),
      child: GPressable(
        scale: .98,
        semanticLabel: '$label $value. Copy',
        onTap: () {
          Clipboard.setData(ClipboardData(text: value));
          GToast.show(context, '$label copied', type: GToastType.info);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: GShape.fill(g.surface, GRadius.tile, side: BorderSide(color: g.rule)),
          child: Row(
            children: [
              Icon(icon, size: 18, color: g.ink3),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: GType.micro.c(g.ink3).w(FontWeight.w500)),
                    Text(value, style: GType.label.c(g.ink)),
                  ],
                ),
              ),
              Icon(LucideIcons.copy, size: 16, color: g.ink3),
            ],
          ),
        ),
      ),
    );
  }
}
