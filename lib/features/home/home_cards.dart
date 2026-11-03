import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/genie_mark.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/parts.dart';
import '../../core/widgets/pressable.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../calendar/meeting_sheet.dart';
import '../decisions/decision_card.dart' show decisionIcon, decisionTone, showDecisionSheet;
import '../goals/goal_widgets.dart' show goalColor;
import '../people/person_sheet.dart';
import '../projects/projects_screen.dart';
import '../shell/routes.dart';
import '../shell/shell.dart';
import '../shell/tab_page.dart';
import '../tasks/new_task_sheet.dart';
import '../tasks/task_list_screen.dart' show TaskFilter;
import '../tasks/task_row.dart' show TickCircle;
import '../tasks/task_view.dart' show TaskLayout, taskLayout;
import 'charts.dart';
import 'milestone_hero.dart' show CountUp;

const double _m = 20;

/// One width for every pill on the right of a card: View all and the row
/// actions (Join, Done, Decide…), so their edges line up.
const double _pillW = 84;

BoxDecoration _lift(GPalette g, [double r = 22]) => BoxDecoration(
  color: g.surface,
  borderRadius: BorderRadius.circular(r),
  boxShadow: const [BoxShadow(color: Color(0x0B000000), blurRadius: 22, offset: Offset(0, 6))],
);

// ─── Highlight ───────────────────────────────────────────────────────────

/// The one highlight at the top: where the company is on its milestone,
/// and the three numbers that need you today.
class HomeHighlight extends StatelessWidget {
  const HomeHighlight({super.key, required this.data, required this.now});

  final Snapshot data;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final m = data.milestone;
    if (!data.setupDone || m == null) return _SetupHighlight(company: data.company);
    final pace = m.progress - m.week / m.weeks;
    final (paceText, paceColor) = pace >= .05
        ? ('Ahead of pace', g.success)
        : pace <= -.05
        ? ('Behind pace', g.danger)
        : ('On pace', g.ink2);
    final stage = m.name.replaceFirst(RegExp(r'^Milestone \d+ · '), '');
    final mine = data.openTasks.where((t) => t.assigneeId == null && t.when != TaskWhen.upcoming);
    final late = mine.where((t) => t.when == TaskWhen.overdue).length;
    final behind = data.goals.where((x) => x.status == GoalStatus.behind).length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _m),
      child: Container(
        decoration: _lift(g, 28),
        child: Column(
          children: [
            GPressable(
              scale: .99,
              semanticLabel: '$stage, ${(m.progress * 100).round()} percent. Open milestone',
              onTap: () => shellKey.currentState?.goTab(Tabs.milestone),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Milestone ${m.stage + 1} of 5', style: GType.label.c(g.ink3)),
                          const SizedBox(height: 10),
                          Text(
                            stage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GType.display.c(g.ink).copyWith(fontSize: 32, height: 1.05, letterSpacing: -1.2, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          Text('Week ${m.week} of ${m.weeks} · ${m.weeks - m.week} weeks to go', style: GType.label.c(g.ink3)),
                          const SizedBox(height: 14),
                          Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 11),
                            decoration: BoxDecoration(color: paceColor.withValues(alpha: .1), borderRadius: BorderRadius.circular(14)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(color: paceColor, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                Text(paceText, style: GType.caption.c(paceColor).w(FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          GRing(value: m.progress, size: 88, stroke: 8, color: g.ink, track: g.ink.withValues(alpha: .08), label: ''),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CountUp(value: (m.progress * 100).round(), style: GType.numeral.c(g.ink).copyWith(fontSize: 24, height: 1)),
                              Text('%', style: GType.caption.c(g.ink3).w(FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(height: 1, color: g.rule),
            IntrinsicHeight(
              child: Row(
                children: [
                  _Stat(value: data.openDecisions.length, label: 'Decisions', onTap: () => openDecisions(context)),
                  Container(width: 1, color: g.rule),
                  _Stat(
                    value: mine.length,
                    label: late > 0 ? 'Due · $late late' : 'Due today',
                    alert: late > 0,
                    onTap: () {
                      taskLayout.value = TaskLayout.list;
                      shellKey.currentState?.goTab(Tabs.tasks);
                    },
                  ),
                  Container(width: 1, color: g.rule),
                  _Stat(value: behind, label: 'Goals behind', alert: behind > 0, onTap: () => openGoals(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.onTap, this.alert = false});

  final int value;
  final String label;
  final VoidCallback onTap;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Expanded(
      child: GPressable(
        scale: .95,
        semanticLabel: '$value $label',
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              CountUp(value: value, style: GType.numeral.c(g.ink).copyWith(fontSize: 22, height: 1.1)),
              const SizedBox(height: 6),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.caption.c(alert ? g.danger : g.ink3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupHighlight extends StatelessWidget {
  const _SetupHighlight({required this.company});

  final String company;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    const steps = ['Company profile and business plan', 'Goals and the first milestone', 'Departments and people'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _m),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: _lift(g, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome to $company', style: GType.label.c(g.ink3)),
            const SizedBox(height: 6),
            Text('Set up your company', style: GType.display.c(g.ink).copyWith(fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Three steps on the web, about 20 minutes. Every section below fills in as you go.', style: GType.bodyS.c(g.ink2)),
            const SizedBox(height: 16),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: g.card, shape: BoxShape.circle),
                      child: Text('${i + 1}', style: GType.figure.c(g.ink).copyWith(fontSize: 12.5)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(steps[i], style: GType.label.c(g.ink).copyWith(fontSize: 14.5))),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            GPressable(
              scale: .97,
              semanticLabel: 'Start setup on the web',
              onTap: () => showWebOnly(context, 'Company setup', LucideIcons.building2),
              child: Container(
                height: 48,
                decoration: BoxDecoration(color: g.ink, borderRadius: BorderRadius.circular(24)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Start setup', style: GType.label.c(g.onInk).w(FontWeight.w600).copyWith(fontSize: 14.5)),
                    const SizedBox(width: 6),
                    Icon(LucideIcons.arrowUpRight, size: 16, color: g.onInk),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── The section card ─────────────────────────────────────────────────────

/// Every Home section is one of these: an icon, a title, a count, View all,
/// then its content, or its own empty state when there is nothing yet.
class HomeCard extends StatelessWidget {
  const HomeCard({super.key, required this.icon, required this.title, required this.child, this.count, this.onViewAll, this.viewAll = 'View all', this.empty});

  final IconData icon;
  final String title;
  final Widget child;
  final int? count;
  final VoidCallback? onViewAll;
  final String viewAll;

  /// When set, shown instead of [child].
  final HomeEmpty? empty;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_m, 28, _m, 0),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: _lift(g),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 18, 18),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: g.card, borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, size: 16, color: g.ink),
                  ),
                  const SizedBox(width: 12),
                  // Title and count take the left; View all always sits on
                  // the right edge.
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.h3.c(g.ink).copyWith(fontSize: 16.5)),
                        ),
                        if (count != null && count! > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: g.card, borderRadius: BorderRadius.circular(8)),
                            child: Text('$count', style: GType.caption.c(g.ink2).w(FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onViewAll != null)
                    GPressable(
                      scale: .94,
                      semanticLabel: '$title: $viewAll',
                      onTap: onViewAll,
                      child: Container(
                        width: _pillW,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: g.ruleStrong),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                viewAll,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GType.caption.c(g.ink).w(FontWeight.w600).copyWith(fontSize: 12.5),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(LucideIcons.chevronRight, size: 14, color: g.ink2),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            empty ?? child,
            // Breathing room under the last item.
            if (empty == null) const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// A section's own empty state: what would fill it, and the way to start.
class HomeEmpty extends StatelessWidget {
  const HomeEmpty({super.key, required this.icon, required this.title, required this.body, this.action, this.onAction});

  final IconData icon;
  final String title, body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
      decoration: BoxDecoration(color: g.ground, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: g.surface,
              shape: BoxShape.circle,
              border: Border.all(color: g.rule),
            ),
            child: Icon(icon, size: 21, color: g.ink2),
          ),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: GType.label.c(g.ink).w(FontWeight.w600).copyWith(fontSize: 15)),
          const SizedBox(height: 6),
          Text(body, textAlign: TextAlign.center, style: GType.caption.c(g.ink3).copyWith(fontSize: 12.5, height: 1.45)),
          if (action != null) ...[
            const SizedBox(height: 18),
            GPressable(
              scale: .95,
              semanticLabel: action!,
              onTap: onAction,
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(color: g.ink, borderRadius: BorderRadius.circular(19)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.plus, size: 15, color: g.onInk),
                    const SizedBox(width: 6),
                    Text(action!, style: GType.label.c(g.onInk).w(FontWeight.w600).copyWith(fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A row inside a section card, split from the one above by a hairline.
class _Row extends StatelessWidget {
  const _Row({required this.lead, required this.title, this.sub, this.subColor, this.trailing, this.onTap});

  final Widget lead;
  final String title;
  final String? sub;
  final Color? subColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return GPressable(
      scale: .985,
      semanticLabel: title,
      onTap: onTap,
      child: Container(
        height: 82,
        padding: const EdgeInsets.fromLTRB(20, 0, 18, 0),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: g.rule)),
        ),
        child: Row(
          children: [
            SizedBox(width: 38, child: Center(child: lead)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.label.c(g.ink).copyWith(fontSize: 14.5)),
                  if (sub != null) ...[
                    const SizedBox(height: 4),
                    Text(sub!, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.caption.c(subColor ?? g.ink3)),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ],
        ),
      ),
    );
  }
}

Widget _dot(IconData icon, Color tone) => Builder(
  builder: (context) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(color: tone.withValues(alpha: .1), shape: BoxShape.circle),
    child: Icon(icon, size: 16, color: tone),
  ),
);

Widget _chip(BuildContext context, String label, VoidCallback onTap, {bool solid = false}) {
  final g = context.g;
  return GPressable(
    scale: .92,
    semanticLabel: label,
    onTap: onTap,
    child: Container(
      width: _pillW,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: solid ? g.ink : g.card, borderRadius: BorderRadius.circular(16)),
      child: Text(label, style: GType.caption.c(solid ? g.onInk : g.ink).w(FontWeight.w600).copyWith(fontSize: 12.5)),
    ),
  );
}

// ─── Needs you ────────────────────────────────────────────────────────────

class HomeNeed {
  const HomeNeed({
    required this.rank,
    required this.lead,
    required this.title,
    required this.sub,
    this.subColor,
    required this.action,
    required this.onAction,
    this.solid = false,
    this.onTap,
  });

  final int rank;
  final Widget lead;
  final String title, sub, action;
  final Color? subColor;
  final VoidCallback onAction;
  final VoidCallback? onTap;
  final bool solid;
}

/// Everything that needs the owner, ranked: live meeting, late work, calls
/// that hurt the plan, a meeting soon, people waiting on a reply.
List<HomeNeed> buildNeeds(BuildContext context, Snapshot d, DateTime now) {
  final g = context.g;
  final out = <HomeNeed>[];
  final live = d.meetings.where((m) => m.stateAt(now) == MeetingState.live).firstOrNull;
  if (live != null) {
    out.add(
      HomeNeed(
        rank: 0,
        lead: _dot(LucideIcons.radio, g.danger),
        title: '${live.title} is live',
        sub: '${live.end.difference(now).inMinutes.clamp(1, 999)} min left · ${live.people.length} in the room',
        subColor: g.danger,
        action: 'Join',
        solid: true,
        onAction: () => GToast.show(context, 'Opening ${live.place}…', type: GToastType.info),
        onTap: () => showMeetingSheet(context, live),
      ),
    );
  }
  for (final t in d.tasks.where((t) => t.when == TaskWhen.overdue && !t.done && t.assigneeId == null)) {
    out.add(
      HomeNeed(
        rank: t.priority ? 1 : 3,
        lead: _dot(LucideIcons.alarmClock, g.danger),
        title: t.title,
        sub: 'Overdue${t.due == null ? '' : ' since ${t.due}'}',
        subColor: g.danger,
        action: 'Done',
        onAction: () {
          final app = context.appRead;
          app.toggleTask(t.id);
          GHaptics.select();
          GToast.show(context, 'Done: ${t.title}', action: 'Undo', onAction: () => app.toggleTask(t.id));
        },
        onTap: () => openTask(context, t.id),
      ),
    );
  }
  for (final x in d.openDecisions) {
    final (tone, _) = decisionTone(x.tone).colors(g);
    out.add(
      HomeNeed(
        rank: switch (x.tone) {
          DecisionTone.offTrack => 1,
          DecisionTone.needsCall => 2,
          DecisionTone.ahead => 5,
        },
        lead: _dot(decisionIcon(x.source), tone),
        title: x.title,
        sub: '${x.tone.label} · ${x.effect}',
        subColor: x.tone == DecisionTone.ahead ? null : tone,
        action: 'Decide',
        onAction: () => showDecisionSheet(context, x),
        onTap: () => showDecisionSheet(context, x),
      ),
    );
  }
  final soon = d.meetings.where((m) => m.stateAt(now) == MeetingState.next && GFormat.sameDay(m.start, now) && m.start.difference(now).inMinutes <= 90).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  if (soon.isNotEmpty) {
    final m = soon.first;
    out.add(
      HomeNeed(
        rank: 2,
        lead: _dot(LucideIcons.calendarClock, g.ink),
        title: '${m.title} in ${m.start.difference(now).inMinutes} min',
        sub: '${GFormat.time(m.start)} · ${m.place}',
        action: 'Prep',
        onAction: () => openGenie(context, ask: 'Prep me for ${m.title}'),
        onTap: () => showMeetingSheet(context, m),
      ),
    );
  }
  for (final i in d.inbox.where((i) => i.kind == InboxKind.mention && i.unread)) {
    final who = d.person(i.actorId);
    out.add(
      HomeNeed(
        rank: 4,
        lead: who == null ? _dot(LucideIcons.atSign, g.accent) : GAvatar(name: who.name, size: 34),
        title: '${who?.first ?? 'Someone'} is waiting on you',
        sub: i.body.replaceFirst(RegExp(r'^@\w+\s*'), ''),
        action: 'Reply',
        onAction: () {
          context.appRead.markRead(i.id);
          shellKey.currentState?.goTab(Tabs.inbox);
        },
        onTap: () => shellKey.currentState?.goTab(Tabs.inbox),
      ),
    );
  }
  final indexed = [for (var k = 0; k < out.length; k++) (k, out[k])]
    ..sort((a, b) => a.$2.rank != b.$2.rank ? a.$2.rank.compareTo(b.$2.rank) : a.$1.compareTo(b.$1));
  return [for (final (_, n) in indexed) n];
}

Widget _needRow(BuildContext context, HomeNeed n) => _Row(
  lead: n.lead,
  title: n.title,
  sub: n.sub,
  subColor: n.subColor,
  onTap: n.onTap,
  trailing: _chip(context, n.action, n.onAction, solid: n.solid),
);

class NeedsCard extends StatelessWidget {
  const NeedsCard({super.key, required this.data, required this.now});

  final Snapshot data;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final needs = buildNeeds(context, data, now);
    return HomeCard(
      icon: LucideIcons.zap,
      title: 'Needs you',
      count: needs.length,
      onViewAll: needs.length > 3 ? () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NeedsScreen())) : null,
      empty: needs.isEmpty
          ? const HomeEmpty(icon: LucideIcons.circleCheckBig, title: 'You’re clear', body: 'No live meetings, late work or calls waiting on you right now.')
          : null,
      child: Column(children: [for (final n in needs.take(3)) _needRow(context, n)]),
    );
  }
}

/// Needs you, in full.
class NeedsScreen extends StatelessWidget {
  const NeedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GPushPage(
      title: 'Needs you',
      child: GLoadView(
        builder: (context, data) {
          final g = context.g;
          final needs = buildNeeds(context, data, DateTime.now());
          return ListView(
            padding: EdgeInsets.fromLTRB(_m, 16, _m, MediaQuery.paddingOf(context).bottom + 32),
            children: [
              Text('${needs.length} things, most urgent first.', style: GType.label.c(g.ink3)),
              const SizedBox(height: 12),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: _lift(g),
                child: Column(
                  children: [
                    for (var i = 0; i < needs.length; i++)
                      i == 0 ? Transform.translate(offset: const Offset(0, -1), child: _needRow(context, needs[i])) : _needRow(context, needs[i]),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Quick actions ────────────────────────────────────────────────────────

class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final actions = <(Widget, String, VoidCallback)>[
      (Icon(LucideIcons.plus, size: 20, color: g.ink), 'New task', () => showNewTaskSheet(context)),
      (Icon(LucideIcons.alarmClock, size: 19, color: g.ink), 'Reminder', () => showNewTaskSheet(context, private: true)),
      (Icon(LucideIcons.listOrdered, size: 19, color: g.ink), 'Plan my day', () => openTaskList(context, TaskFilter.today)),
      (GenieMark(size: 20, mono: g.ink, dot: g.ai), 'Brief me', () => openGenie(context, ask: 'Brief me on today')),
    ];
    // No card: a plain title and four tiles straight on the page.
    return Padding(
      padding: const EdgeInsets.fromLTRB(_m, 32, _m, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 14),
            child: Text('Quick actions', style: GType.h3.c(g.ink).copyWith(fontSize: 16.5)),
          ),
          Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: GPressable(
                    scale: .92,
                    semanticLabel: actions[i].$2,
                    onTap: actions[i].$3,
                    child: Container(
                      height: 92,
                      decoration: _lift(g, 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: g.card, shape: BoxShape.circle),
                            child: Center(child: actions[i].$1),
                          ),
                          const SizedBox(height: 10),
                          Text(actions[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.caption.c(g.ink2).copyWith(fontSize: 11.5)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── My tasks ─────────────────────────────────────────────────────────────

class MyTasksCard extends StatelessWidget {
  const MyTasksCard({super.key, required this.data});

  final Snapshot data;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final mine = data.tasks.where((t) => t.assigneeId == null && t.when != TaskWhen.upcoming && !t.done).toList()
      ..sort((a, b) => (a.when == TaskWhen.overdue ? 0 : 1).compareTo(b.when == TaskWhen.overdue ? 0 : 1));
    void viewAll() {
      taskLayout.value = TaskLayout.list;
      shellKey.currentState?.goTab(Tabs.tasks);
    }

    return HomeCard(
      icon: LucideIcons.squareCheckBig,
      title: 'My tasks',
      count: mine.length,
      onViewAll: viewAll,
      empty: mine.isEmpty
          ? HomeEmpty(
              icon: LucideIcons.listChecks,
              title: 'Nothing due today',
              body: 'Tasks from meetings, chats and Genie land here. Add your own any time.',
              action: 'Add a task',
              onAction: () => showNewTaskSheet(context),
            )
          : null,
      child: Column(
        children: [
          for (final t in mine.take(4))
            _Row(
              lead: TickCircle(
                done: t.done,
                size: 22,
                onTap: () {
                  context.appRead.toggleTask(t.id);
                  GHaptics.select();
                },
              ),
              title: t.title,
              sub: t.when == TaskWhen.overdue
                  ? 'Overdue${t.due == null ? '' : ' · ${t.due}'}'
                  : [?t.due, GFormat.shortDept(t.dept), if (t.minutes != null) GFormat.minutes(t.minutes!)].join(' · '),
              subColor: t.when == TaskWhen.overdue ? g.danger : null,
              trailing: t.priority ? Icon(LucideIcons.flag, size: 15, color: g.warning) : null,
              onTap: () => openTask(context, t.id),
            ),
          if (mine.length > 4)
            _Row(
              lead: Icon(LucideIcons.ellipsis, size: 18, color: g.ink3),
              title: '${mine.length - 4} more for today',
              onTap: viewAll,
            ),
        ],
      ),
    );
  }
}

// ─── Schedule ─────────────────────────────────────────────────────────────

class ScheduleCard extends StatelessWidget {
  const ScheduleCard({super.key, required this.data, required this.now});

  final Snapshot data;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: today.weekday - 1));
    final days = [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];
    final next = data.meetings.where((m) => GFormat.sameDay(m.start, now) && m.stateAt(now) != MeetingState.done).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final count = data.meetings.where((m) => GFormat.sameDay(m.start, now) && !m.cancelled).length;
    return HomeCard(
      icon: LucideIcons.calendarDays,
      title: 'Schedule',
      count: count,
      onViewAll: () => openCalendar(context),
      viewAll: 'Calendar',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
            child: Row(
              children: [
                for (final d in days)
                  Expanded(
                    child: GPressable(
                      scale: .9,
                      semanticLabel: GFormat.longDate(d),
                      onTap: () => openCalendar(context, day: d),
                      child: Column(
                        children: [
                          Text(GFormat.weekdayLetter(d), style: GType.micro.c(GFormat.sameDay(d, now) ? g.ink : g.ink3)),
                          const SizedBox(height: 5),
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: GFormat.sameDay(d, now) ? g.ink : null, shape: BoxShape.circle),
                            child: Text('${d.day}', style: GType.figure.c(GFormat.sameDay(d, now) ? g.onInk : g.ink).copyWith(fontSize: 14)),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: data.meetings.any((m) => GFormat.sameDay(m.start, d) && !m.cancelled) ? g.ink3 : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (next.isEmpty)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: g.rule)),
              ),
              child: const HomeEmpty(icon: LucideIcons.coffee, title: 'No more meetings today', body: 'A good time for deep work.'),
            ),
          for (final m in next.take(3))
            _Row(
              lead: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(GFormat.time(m.start).split(' ').first, style: GType.figure.c(m.cancelled ? g.ink3 : g.ink).copyWith(fontSize: 13)),
                  Text(GFormat.time(m.start).split(' ').last, style: GType.micro.c(g.ink3).copyWith(fontWeight: FontWeight.w500)),
                ],
              ),
              title: m.title,
              sub: m.cancelled
                  ? 'Cancelled'
                  : m.stateAt(now) == MeetingState.live
                  ? 'Live · ${m.end.difference(now).inMinutes.clamp(1, 999)} min left'
                  : '${GFormat.minutes(m.minutes)} · ${m.place}',
              subColor: m.stateAt(now) == MeetingState.live ? g.danger : null,
              onTap: () => showMeetingSheet(context, m),
            ),
        ],
      ),
    );
  }
}

// ─── Projects ─────────────────────────────────────────────────────────────

class ProjectsCard extends StatelessWidget {
  const ProjectsCard({super.key, required this.data});

  final Snapshot data;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final list = [...data.projects.where((p) => p.status != ProjectStatus.done)]..sort((a, b) => projectRank(a.status).compareTo(projectRank(b.status)));
    return HomeCard(
      icon: LucideIcons.folderKanban,
      title: 'Projects',
      count: list.length,
      onViewAll: () => openProjects(context),
      empty: data.projects.isEmpty
          ? HomeEmpty(
              icon: LucideIcons.folderKanban,
              title: 'No projects yet',
              body: 'Projects group the work behind a goal: an owner, a team and steps.',
              action: 'Set up on the web',
              onAction: () => showWebOnly(context, 'Projects', LucideIcons.folderKanban),
            )
          : null,
      child: Column(
        children: [
          for (final p in list.take(3))
            _Row(
              lead: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: projectColor(p.status, g), shape: BoxShape.circle),
              ),
              title: p.name,
              sub: '${p.status.label} · ${p.portfolio} · due ${p.due}',
              subColor: p.status == ProjectStatus.onTrack ? null : projectColor(p.status, g),
              trailing: SizedBox(
                width: 52,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${(p.progress * 100).round()}%', style: GType.figure.c(g.ink).copyWith(fontSize: 13)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SizedBox(
                        height: 4,
                        child: Stack(
                          children: [
                            Container(color: g.ink.withValues(alpha: .08)),
                            FractionallySizedBox(
                              widthFactor: p.progress,
                              child: Container(color: projectColor(p.status, g)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () => openProject(context, p.id),
            ),
          _Row(
            lead: Icon(LucideIcons.folders, size: 18, color: g.ink2),
            title: 'Portfolios',
            sub: '${data.projects.map((p) => p.portfolio).toSet().length} areas · ${data.projects.length} projects',
            trailing: Icon(LucideIcons.chevronRight, size: 16, color: g.ink4),
            onTap: () => openPortfolios(context),
          ),
        ],
      ),
    );
  }
}

// ─── Goals ────────────────────────────────────────────────────────────────

class GoalsCard extends StatelessWidget {
  const GoalsCard({super.key, required this.data});

  final Snapshot data;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final goals = data.goals;
    final counts = {for (final s in GoalStatus.values) s: goals.where((x) => x.status == s).length};
    final behind = goals.where((x) => x.status == GoalStatus.behind).toList();
    return HomeCard(
      icon: LucideIcons.target,
      title: 'Goals',
      count: goals.length,
      onViewAll: () => openGoals(context),
      empty: goals.isEmpty
          ? const HomeEmpty(
              icon: LucideIcons.target,
              title: 'No goals yet',
              body: 'Goals come from your business plan. Each shows its owner and progress here.',
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: GMotion.of(context, const Duration(milliseconds: 900)),
                  curve: GMotion.easeOut,
                  builder: (context, t, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: t,
                          child: Row(
                            children: [
                              for (final s in GoalStatus.values)
                                if (counts[s]! > 0)
                                  Expanded(
                                    flex: counts[s]!,
                                    child: Container(margin: const EdgeInsets.only(right: 2), color: goalColor(s, g)),
                                  ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    for (final s in GoalStatus.values)
                      if (counts[s]! > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(color: goalColor(s, g), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 5),
                            Text('${counts[s]} ${s.label.toLowerCase()}', style: GType.caption.c(g.ink2)),
                          ],
                        ),
                  ],
                ),
              ],
            ),
          ),
          for (final x in behind.take(2))
            _Row(
              lead: Icon(LucideIcons.triangleAlert, size: 17, color: g.danger),
              title: x.title,
              sub: '${data.person(x.ownerId)?.first ?? GFormat.shortDept(x.dept)} · due ${x.due}',
              trailing: Text(x.progress == null ? '—' : '${(x.progress! * 100).round()}%', style: GType.figure.c(g.ink2).copyWith(fontSize: 13)),
              onTap: () => openGoal(context, x.id),
            ),
        ],
      ),
    );
  }
}

// ─── Team ─────────────────────────────────────────────────────────────────

class TeamCard extends StatelessWidget {
  const TeamCard({super.key, required this.data});

  final Snapshot data;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final people = [...data.people]..sort((a, b) => (b.live ? 2 : (b.behind ? 1 : 0)).compareTo(a.live ? 2 : (a.behind ? 1 : 0)));
    final filed = data.people.where((p) => p.reportFiled).length;
    return HomeCard(
      icon: LucideIcons.usersRound,
      title: 'Team today',
      count: data.people.length,
      onViewAll: () => openPeople(context),
      empty: people.isEmpty
          ? HomeEmpty(
              icon: LucideIcons.userPlus,
              title: 'No one invited yet',
              body: 'Invite your department heads. Who is live, behind or has reported shows here.',
              action: 'Invite people',
              onAction: () => showWebOnly(context, 'Invitations', LucideIcons.userPlus),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              '$filed of ${data.people.length} reported · ${data.people.where((p) => p.live).length} in meetings · ${data.people.where((p) => p.behind).length} behind',
              style: GType.caption.c(g.ink3),
            ),
          ),
          SizedBox(
            height: 124,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              itemCount: people.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final p = people[i];
                final dot = p.live ? g.danger : (p.behind ? g.warning : (p.reportFiled ? g.success : null));
                final status = p.live ? 'In a meeting' : (p.today ?? GFormat.shortDept(p.dept));
                return GPressable(
                  scale: .94,
                  semanticLabel: '${p.name}, $status',
                  onTap: () => showPersonSheet(context, p),
                  child: SizedBox(
                    width: 72,
                    child: Column(
                      children: [
                        GAvatar(name: p.name, size: 46, dot: dot),
                        const SizedBox(height: 6),
                        Text(p.first, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.label.c(g.ink).copyWith(fontSize: 12.5)),
                        Text(
                          status,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: GType.caption.c(p.live ? g.danger : g.ink3).copyWith(fontSize: 10.5, height: 1.2),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Trends ───────────────────────────────────────────────────────────────

class TrendsCard extends StatelessWidget {
  const TrendsCard({super.key, required this.data, required this.now});

  final Snapshot data;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final rev = data.revenue;
    final week = data.doneThisWeek.take(now.weekday).toList();
    final change = rev.length < 2 ? 0 : ((rev.last - rev[rev.length - 2]) / rev[rev.length - 2] * 100).round();
    final met = data.activity.where((d) => d == 2).length;
    final empty = data.activity.isEmpty && rev.isEmpty && week.isEmpty;
    return HomeCard(
      icon: LucideIcons.chartNoAxesColumn,
      title: 'Trends',
      onViewAll: data.milestone == null ? null : () => shellKey.currentState?.goTab(Tabs.milestone),
      viewAll: 'Milestone',
      empty: empty
          ? const HomeEmpty(
              icon: LucideIcons.chartLine,
              title: 'Charts come with history',
              body: 'After your first week of work, trends for revenue, tasks and days on plan show here.',
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data.activity.isNotEmpty) ...[
              Row(
                children: [
                  Text('Last 30 days', style: GType.label.c(g.ink2)),
                  const Spacer(),
                  Text('$met days on plan', style: GType.caption.c(g.ink3)),
                ],
              ),
              const SizedBox(height: 18),
              ActivityGrid(days: data.activity),
              const SizedBox(height: 26),
              Container(height: 1, color: g.rule),
              const SizedBox(height: 22),
            ],
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (rev.length >= 2)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Revenue, 8 weeks', style: GType.caption.c(g.ink3)),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹${rev.last.round()} L', style: GType.numeral.c(g.ink).copyWith(fontSize: 20, height: 1)),
                              const SizedBox(width: 6),
                              Text('${change >= 0 ? '+' : ''}$change%', style: GType.caption.c(change >= 0 ? g.success : g.danger).w(FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TrendArea(values: rev, height: 64),
                        ],
                      ),
                    ),
                  if (rev.length >= 2 && week.isNotEmpty) Container(width: 1, margin: const EdgeInsets.symmetric(horizontal: 18), color: g.rule),
                  if (week.isNotEmpty)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tasks done, this week', style: GType.caption.c(g.ink3)),
                          const SizedBox(height: 8),
                          CountUp(value: week.fold(0, (a, b) => a + b), style: GType.numeral.c(g.ink).copyWith(fontSize: 20, height: 1)),
                          const SizedBox(height: 16),
                          WeekBars(values: week, today: now.weekday - 1, height: 48),
                        ],
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
