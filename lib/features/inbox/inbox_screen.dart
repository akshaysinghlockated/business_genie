import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/genie_mark.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/parts.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/swap.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../shell/routes.dart';
import '../shell/tab_page.dart';
import '../tasks/new_task_sheet.dart';

enum _InboxFilter { all, mentions, unread, decisions }

/// Everything that came in: Genie's brief, mentions, decisions, goals that
/// slipped, reports. Mentions can be turned straight into a task.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key, this.asTab = false});

  /// True when it is the bar's Inbox tab rather than a pushed page.
  final bool asTab;

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  _InboxFilter _filter = _InboxFilter.all;

  bool _match(InboxItem i) => switch (_filter) {
    _InboxFilter.all => true,
    _InboxFilter.mentions => i.kind == InboxKind.mention,
    _InboxFilter.unread => i.unread,
    _InboxFilter.decisions => i.kind == InboxKind.decision || i.kind == InboxKind.slipped,
  };

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final unread = app.data?.unread ?? 0;
    final markAll = GIconButton(
      icon: LucideIcons.checkCheck,
      label: 'Mark all as read',
      onTap: unread == 0
          ? null
          : () {
              app.markAllRead();
              GToast.show(context, 'All caught up');
            },
    );
    final body = GLoadView(
      builder: (context, data) {
        final list = data.inbox.where(_match).toList();
        return Column(
          children: [
            const SizedBox(height: GSpace.m),
            GChipRow(
              children: [
                GChip(label: 'All', selected: _filter == _InboxFilter.all, onTap: () => setState(() => _filter = _InboxFilter.all)),
                GChip(
                  label: 'Mentions',
                  icon: LucideIcons.atSign,
                  selected: _filter == _InboxFilter.mentions,
                  onTap: () => setState(() => _filter = _InboxFilter.mentions),
                ),
                GChip(
                  label: 'Unread',
                  count: unread == 0 ? null : unread,
                  selected: _filter == _InboxFilter.unread,
                  onTap: () => setState(() => _filter = _InboxFilter.unread),
                ),
                GChip(label: 'Decisions', selected: _filter == _InboxFilter.decisions, onTap: () => setState(() => _filter = _InboxFilter.decisions)),
              ],
            ),
            const SizedBox(height: GSpace.s),
            const GRule(),
            Expanded(
              child: GSwap(
                id: _filter,
                alignment: Alignment.topCenter,
                child: list.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.only(top: GSpace.xl, bottom: GSpace.navClearance),
                        children: [
                          GEmptyState(
                            icon: LucideIcons.inbox,
                            title: data.inbox.isEmpty ? 'Nothing here yet' : 'Inbox zero',
                            body: data.inbox.isEmpty
                                ? 'Mentions, Genie’s morning brief and decisions arrive here once your team is set up.'
                                : 'You’ve cleared everything in this view.',
                          ),
                        ],
                      )
                    : GRefresh(
                        child: ListView(
                          padding: const EdgeInsets.only(bottom: GSpace.navClearance),
                          children: _grouped(context, list, data),
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
    if (widget.asTab) return GTabPage(title: 'Inbox', subtitle: unread == 0 ? 'All caught up' : '$unread unread', actions: [markAll], child: body);
    return GPushPage(title: 'Inbox', actions: [markAll], child: body);
  }

  List<Widget> _grouped(BuildContext context, List<InboxItem> list, Snapshot data) {
    final g = context.g;
    final out = <Widget>[];
    String? group;
    // Days in order, newest first; items keep their order within a day.
    const days = ['Today', 'Yesterday', 'Earlier this week', 'Last week'];
    int rank(String d) => days.contains(d) ? days.indexOf(d) : days.length;
    // "25m ago" before "3h ago"; a clock time ("8:30 AM") is this morning,
    // so older than any "h ago"; anything else keeps its order.
    int age(String ago) {
      final m = RegExp(r'^(\d+)([mh]) ago$').firstMatch(ago);
      if (m != null) return int.parse(m.group(1)!) * (m.group(2) == 'h' ? 60 : 1);
      return RegExp(r'^\d+:\d+ [AP]M$').hasMatch(ago) ? 24 * 60 : 1 << 20;
    }

    final sorted = [for (var k = 0; k < list.length; k++) (k, list[k])]
      ..sort((a, b) {
        final r = rank(a.$2.group).compareTo(rank(b.$2.group));
        if (r != 0) return r;
        final t = age(a.$2.ago).compareTo(age(b.$2.ago));
        return t != 0 ? t : a.$1.compareTo(b.$1);
      });
    for (final (_, i) in sorted) {
      if (i.group != group) {
        group = i.group;
        out.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.l, GSpace.gutter, GSpace.xs),
            child: Text(group, style: GType.label.c(g.ink3)),
          ),
        );
      }
      out.add(_InboxRow(key: ValueKey(i.id), item: i, actor: data.person(i.actorId)));
    }
    return out;
  }
}

class _InboxRow extends StatelessWidget {
  const _InboxRow({super.key, required this.item, this.actor});

  final InboxItem item;
  final Person? actor;

  void _open(BuildContext context) {
    final app = context.appRead;
    app.markRead(item.id);
    switch (item.kind) {
      case InboxKind.brief:
        openGenie(context, ask: 'Brief me on today');
      case InboxKind.decision:
        openDecisions(context);
      case InboxKind.slipped:
        final goal = app.data?.goals.where((x) => item.title.startsWith(x.title)).firstOrNull;
        goal == null ? openGoals(context) : openGoal(context, goal.id);
      case InboxKind.mention || InboxKind.activity || InboxKind.report:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final i = item;
    final Widget lead = switch (i.kind) {
      InboxKind.brief => Container(width: 40, height: 40, alignment: Alignment.center, decoration: GShape.fill(g.aiSoft, 13), child: const GenieMark(size: 22)),
      InboxKind.slipped => const GIconBox(icon: LucideIcons.triangleAlert, tone: GTone.danger, size: 40),
      InboxKind.decision => const GIconBox(icon: LucideIcons.gitFork, tone: GTone.warning, size: 40),
      _ => actor != null ? GAvatar(name: actor!.name, size: 40) : const GIconBox(icon: LucideIcons.bell, size: 40),
    };
    return GPressable(
      scale: .985,
      semanticLabel: '${i.unread ? 'Unread. ' : ''}${i.title}. ${i.body}. ${i.ago}',
      onTap: () => _open(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(GSpace.gutter, 14, GSpace.gutter, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            lead,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          i.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GType.title.c(g.ink).w(i.unread ? FontWeight.w600 : FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(i.ago, style: GType.caption.c(g.ink3)),
                      AnimatedContainer(
                        duration: GMotion.quick,
                        width: i.unread ? 8 : 0,
                        height: 8,
                        margin: EdgeInsets.only(left: i.unread ? 6 : 0),
                        decoration: BoxDecoration(color: g.accent, shape: BoxShape.circle),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    height: 40,
                    child: Text(i.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: GType.bodyS.c(g.ink2).copyWith(height: 1.45)),
                  ),
                  if (i.kind == InboxKind.mention) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        GButton(
                          label: 'Reply',
                          icon: LucideIcons.reply,
                          compact: true,
                          kind: GButtonKind.secondary,
                          onTap: () => GToast.show(context, 'Replies come with team chat.', type: GToastType.info),
                        ),
                        const SizedBox(width: 8),
                        GButton(
                          label: 'Make a task',
                          icon: LucideIcons.circlePlus,
                          compact: true,
                          kind: GButtonKind.quiet,
                          onTap: () {
                            context.appRead.markRead(i.id);
                            showNewTaskSheet(context, title: i.body.replaceFirst(RegExp(r'^@\w+\s*'), ''));
                          },
                        ),
                      ],
                    ),
                  ],
                  if (i.kind == InboxKind.brief) ...[
                    const SizedBox(height: 10),
                    GButton(label: 'Open brief', icon: LucideIcons.messageSquareText, compact: true, kind: GButtonKind.quiet, onTap: () => _open(context)),
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

/// New from the Inbox: a post to the team, a direct message, or a task.
void showInboxNew(BuildContext context) {
  showGSheet<void>(
    context,
    builder: (sheet) {
      final g = sheet.g;
      Widget row(IconData icon, String title, String sub, VoidCallback onTap) => GRow(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: g.card, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 18, color: g.ink),
        ),
        title: title,
        subtitle: sub,
        chevron: true,
        onTap: onTap,
      );
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GSheetHeader(title: 'New'),
          row(LucideIcons.megaphone, 'Post to the team', 'An update everyone sees, with Acknowledge', () {
            Navigator.of(sheet).pop();
            GToast.show(context, 'Team posts come with team chat.', type: GToastType.info);
          }),
          row(LucideIcons.messageSquare, 'Message someone', 'A direct message to one person', () {
            Navigator.of(sheet).pop();
            GToast.show(context, 'Direct messages come with team chat.', type: GToastType.info);
          }),
          row(LucideIcons.squareCheckBig, 'New task', 'For you or someone on the team', () {
            Navigator.of(sheet).pop();
            showNewTaskSheet(context);
          }),
          SizedBox(height: MediaQuery.paddingOf(sheet).bottom + 12),
        ],
      );
    },
  );
}
