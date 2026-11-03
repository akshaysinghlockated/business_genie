import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/parts.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/swap.dart';
import '../shell/routes.dart';
import '../shell/tab_page.dart';
import 'person_sheet.dart';

/// The team today: who is live, who filed a report, who is behind. Filter by
/// department or by state.
class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key, this.embedded = false});

  /// True inside Home's Team tab: no page header of its own.
  final bool embedded;

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final list = Expanded(
      child: GLoadView(
        builder: (context, data) {
          if (data.people.isEmpty) {
            return ListView(
              children: [
                GEmptyState(
                  icon: LucideIcons.users,
                  title: 'No one invited yet',
                  body: 'Invite the people who run each department. Their day shows here once they join.',
                  action: 'Invite people',
                  onAction: () => showWebOnly(context, 'Invitations', LucideIcons.userPlus),
                ),
              ],
            );
          }
          final depts = data.people.map((p) => p.dept).toSet().toList();
          final list = data.people
              .where(
                (p) => switch (_filter) {
                  'All' => true,
                  'Live' => p.live,
                  'Behind' => p.behind,
                  _ => p.dept == _filter,
                },
              )
              .toList();
          return Column(
            children: [
              const SizedBox(height: GSpace.m),
              GChipRow(
                children: [
                  for (final f in ['All', if (data.people.any((p) => p.live)) 'Live', if (data.people.any((p) => p.behind)) 'Behind', ...depts])
                    GChip(label: GFormat.shortDept(f), selected: _filter == f, onTap: () => setState(() => _filter = f)),
                ],
              ),
              const SizedBox(height: GSpace.s),
              Expanded(
                child: GSwap(
                  id: _filter,
                  alignment: Alignment.topCenter,
                  child: GRefresh(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: GSpace.s, bottom: GSpace.navClearance),
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final p = list[i];
                        final dot = p.live ? g.danger : (p.behind ? g.warning : (p.reportFiled ? g.success : null));
                        return GRow(
                          leading: GAvatar(name: p.name, size: 44, dot: dot),
                          title: p.name,
                          subtitle: '${p.role} · ${p.today ?? GFormat.shortDept(p.dept)}',
                          trailing: GIconButton(
                            icon: LucideIcons.messageSquare,
                            label: 'Message ${p.first}',
                            onTap: () => GToast.show(context, 'Team chat is coming to the app. Call or email for now.', type: GToastType.info),
                          ),
                          onTap: () => showPersonSheet(context, p),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    final invite = GIconButton(icon: LucideIcons.userPlus, label: 'Invite', onTap: () => showWebOnly(context, 'Invitations', LucideIcons.userPlus));
    if (widget.embedded) return Column(children: [list]);
    return GPushPage(
      title: 'Team',
      actions: [invite],
      child: Column(children: [list]),
    );
  }
}
