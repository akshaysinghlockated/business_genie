import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets/genie_mark.dart';
import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/parts.dart';
import '../../core/widgets/swap.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../calendar/meeting_sheet.dart';
import '../decisions/decision_card.dart';
import '../goals/goal_widgets.dart';
import '../shell/routes.dart';
import '../tasks/task_list_screen.dart';

/// What Genie says back: a line about what it is doing while it thinks, the
/// reply, and optionally a card and follow-up chips.
class GenieReply {
  const GenieReply({required this.thinking, required this.text, this.card, this.chips = const []});

  final String thinking;
  final String text;
  final WidgetBuilder? card;
  final List<String> chips;
}

class GenieMessage {
  GenieMessage.me(this.text) : me = true, card = null, chips = const [], streamed = text.length;

  GenieMessage.genie(GenieReply r) : me = false, text = r.text, card = r.card, chips = r.chips, streamed = 0;

  final bool me;
  final String text;
  final WidgetBuilder? card;
  final List<String> chips;

  /// How many characters have been written in so far.
  int streamed;
}

/// The demo's answers, built from the loaded company data. A live model
/// replaces this; the screen only needs a [GenieReply].
abstract final class GenieBrain {
  static const _starters = ['Brief me on today', 'What’s off track?', 'My next meeting'];

  static GenieReply answer(String q, AppState app) {
    final s = q.toLowerCase();
    final data = app.data;
    if (data == null) {
      return const GenieReply(
        thinking: 'Reaching your company data…',
        text: 'I can’t reach your company data right now, so I can’t answer that properly. Try again in a minute; nothing you asked is lost.',
        chips: ['Brief me on today'],
      );
    }
    if (!data.setupDone) {
      return const GenieReply(
        thinking: 'Checking your setup…',
        text:
            'Your company isn’t set up yet, so I don’t know your plan, goals or team. Finish setup on the web (about 20 minutes) and I’ll be able to brief you every morning.',
        chips: ['What does setup include?'],
      );
    }
    final owner = data.owner.first;

    if (RegExp(r'^(hi|hey|hello|good (morning|afternoon|evening))\b').hasMatch(s)) {
      return GenieReply(thinking: '…', text: '${GFormat.greeting(DateTime.now())}, $owner. What can I take off your plate?', chips: _starters);
    }
    if (s.contains('add a task') || s.startsWith('add ') || s.contains('remind me') || s.contains('create a task')) {
      return _propose(q, data);
    }
    if (s.startsWith('explain') || s.contains('hiring') || s.contains('budget') || s.contains('decision')) {
      final d =
          data.decisions
              .where(
                (d) =>
                    s.contains(d.title.toLowerCase().split(' ').first) ||
                    (s.contains('hiring') && d.source == 'Workforce plan') ||
                    (s.contains('budget') && d.source == 'Finance'),
              )
              .firstOrNull ??
          data.openDecisions.firstOrNull;
      if (d != null) return _decision(d);
    }
    if (s.contains('prep') || s.contains('summar') || s.contains('next meeting') || s.contains('meeting')) {
      return _meeting(s, data);
    }
    if (s.contains('off track') || s.contains('behind') || s.contains('slipping')) return _offTrack(data);
    if (s.contains('how is') || s.contains('going')) {
      final x = data.goals.where((x) => s.contains(x.title.toLowerCase())).firstOrNull;
      if (x != null) return _goal(x, data);
    }
    if (s.contains('goal')) return _goals(data);
    if (s.contains('task') || s.contains('left')) return _tasks(data);
    if (s.contains('plan my day')) {
      return GenieReply(
        thinking: 'Looking at your meetings and tasks…',
        text: 'I can order today’s tasks around your meetings, with a reason for each. Open Today and press Plan; nothing moves until you accept.',
        card: (c) => GButton(label: 'Open Today', icon: LucideIcons.sun, compact: true, onTap: () => openTaskList(c, TaskFilter.today)),
      );
    }
    if (s.contains('business') || s.contains('health') || s.contains('numbers') || s.contains('revenue') || s.contains('how are we')) return _health(data);
    if (s.contains('brief') || s.contains('today') || s.contains('morning') || s.contains('update')) return _brief(data);
    if (s.contains('setup')) {
      return const GenieReply(
        thinking: '…',
        text:
            'Setup covers your company profile, a short founder interview, the business plan, goals, departments and inviting your heads. It’s done on the web.',
      );
    }
    return const GenieReply(
      thinking: 'Thinking…',
      text: 'I’m not sure I caught that. In this demo I can brief you, check goals, meetings and tasks, explain decisions, and draft tasks for you.',
      chips: _starters,
    );
  }

  static GenieReply _brief(Snapshot data) {
    final now = DateTime.now();
    final open = data.openDecisions;
    final next =
        (data.meetings.where((m) => m.stateAt(now) == MeetingState.next || m.stateAt(now) == MeetingState.live).toList()
              ..sort((a, b) => a.start.compareTo(b.start)))
            .firstOrNull;
    final today = data.openTasks.where((t) => t.when == TaskWhen.today && t.assigneeId == null).length;
    final behind = data.goals.where((x) => x.status == GoalStatus.behind).length;
    final parts = <String>[
      if (open.isNotEmpty) '${open.length} decision${open.length == 1 ? '' : 's'} need${open.length == 1 ? 's' : ''} you',
      if (behind > 0) '$behind goal${behind == 1 ? ' is' : 's are'} behind',
      '$today task${today == 1 ? '' : 's'} today',
    ];
    final text =
        '${GFormat.greeting(now)}, ${data.owner.first}. ${_cap(parts.join(', '))}.'
        '${data.milestone == null ? '' : ' The company is ${(data.milestone!.progress * 100).round()}% through ${data.milestone!.name.split(' · ').first}.'}';
    return GenieReply(
      thinking: 'Reading your plan, inbox and calendar…',
      text: text,
      chips: const ['What’s off track?', 'Tasks left today'],
      card: (c) {
        final g = c.g;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final d in open.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DecisionCard(decision: d),
              ),
            if (next != null)
              GCard(
                radius: GRadius.tile,
                padding: const EdgeInsets.all(12),
                onTap: () => showMeetingSheet(c, next),
                child: Row(
                  children: [
                    Icon(LucideIcons.clock, size: 16, color: g.ink2),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        next.stateAt(now) == MeetingState.live ? '${next.title} is live now' : '${next.title} in ${next.start.difference(now).inMinutes} min',
                        style: GType.label.c(g.ink),
                      ),
                    ),
                    Icon(LucideIcons.chevronRight, size: 16, color: g.ink3),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  static GenieReply _offTrack(Snapshot data) {
    final behind = data.goals.where((x) => x.status == GoalStatus.behind).toList();
    final off = data.openDecisions.where((d) => d.tone == DecisionTone.offTrack).toList();
    if (behind.isEmpty && off.isEmpty) {
      return const GenieReply(thinking: 'Checking every goal…', text: 'Nothing is off track right now. Every goal with a reading is on track or ahead.');
    }
    return GenieReply(
      thinking: 'Checking every goal and key result…',
      text:
          '${behind.length} goal${behind.length == 1 ? ' is' : 's are'} behind. '
          '${behind.isNotEmpty ? 'The biggest risk is “${behind.first.title}”, which ${off.isNotEmpty ? 'is slipping Milestone 1 by about 3 weeks' : 'needs a push this month'}.' : ''}',
      chips: const ['Explain the hiring decision', 'How are the goals?'],
      card: (c) => Column(
        children: [
          for (final x in behind)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GoalCard(goal: x, owner: data.person(x.ownerId)),
            ),
        ],
      ),
    );
  }

  static GenieReply _health(Snapshot data) {
    final m = data.milestone;
    if (m == null) {
      return const GenieReply(
        thinking: 'Reading your plan…',
        text: 'There are no readings yet. Once your plan is set up, I can tell you how the business is doing.',
      );
    }
    final behind = data.goals.where((x) => x.status == GoalStatus.behind).length;
    final parts = [
      'The company is ${(m.progress * 100).round()}% through ${m.name.split(' · ').first}, week ${m.week} of ${m.weeks}.',
      for (final t in data.targets.take(2)) '${t.label}: ${t.current} of ${t.target}.',
      if (behind > 0) '$behind goal${behind == 1 ? ' is' : 's are'} behind, so that’s where to look.',
    ];
    return GenieReply(
      thinking: 'Reading the plan and ${data.people.length} team reports…',
      text: parts.join(' '),
      chips: const ['What’s off track?', 'Brief me'],
      card: (c) {
        final g = c.g;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: g.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: g.rule, spreadRadius: 1)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GRing(
                    value: m.progress,
                    size: 56,
                    stroke: 5,
                    color: m.progress >= .75 ? g.success : const Color(0xFFE2AE0B),
                    label: '${(m.progress * 100).round()}',
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name.split(' · ').last, style: GType.title.c(g.ink)),
                        Text('Week ${m.week} of ${m.weeks}', style: GType.caption.c(g.ink3)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              for (final t in data.targets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: KrRow(
                    kr: KeyResult(title: t.label, target: t.target, current: t.current, progress: t.progress),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: GButton(label: 'Open goals', compact: true, kind: GButtonKind.secondary, onTap: () => openGoals(c)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static GenieReply _goals(Snapshot data) {
    if (data.goals.isEmpty) return const GenieReply(thinking: 'Checking goals…', text: 'There are no goals yet. They come from your business plan on the web.');
    final on = data.goals.where((x) => x.status == GoalStatus.onTrack || x.status == GoalStatus.achieved).length;
    return GenieReply(
      thinking: 'Adding up your goals…',
      text: '$on of ${data.goals.length} goals are on track or achieved. Tap a goal that is behind to see why.',
      card: (c) => GoalsSummaryCard(data: data),
      chips: const ['What’s off track?'],
    );
  }

  static GenieReply _goal(Goal x, Snapshot data) {
    final owner = data.person(x.ownerId);
    final latest = x.updates.isEmpty ? '' : ' Latest from ${x.updates.first.by.split(' ').first}: “${x.updates.first.text}”';
    return GenieReply(
      thinking: 'Reading ${x.title.toLowerCase()}…',
      text: x.progress == null
          ? '“${x.title}” has no reading yet, so I can’t say how it’s going. ${owner?.first ?? 'The owner'} posts the first update soon.'
          : '“${x.title}” is ${x.status.label.toLowerCase()} at ${(x.progress! * 100).round()}%.$latest',
      card: (c) => GoalCard(goal: x, owner: owner),
    );
  }

  static GenieReply _tasks(Snapshot data) {
    final open = data.openTasks.where((t) => t.when != TaskWhen.upcoming && t.assigneeId == null).toList();
    if (open.isEmpty) return const GenieReply(thinking: 'Checking your list…', text: 'Nothing left for today. Want me to look at tomorrow?');
    final mins = open.fold<int>(0, (s, t) => s + (t.minutes ?? 0));
    return GenieReply(
      thinking: 'Checking your list…',
      text:
          '${open.length} task${open.length == 1 ? '' : 's'} left, about ${GFormat.minutes(mins)} of work. ${open.where((t) => t.when == TaskWhen.overdue).isNotEmpty ? 'Start with the overdue ones.' : ''}',
      chips: const ['Plan my day'],
      card: (c) {
        final g = c.g;
        return GCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          radius: GRadius.tile,
          child: Column(
            children: [
              for (final t in open.take(5))
                GRow(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  leading: Icon(
                    t.when == TaskWhen.overdue ? LucideIcons.bellRing : LucideIcons.circle,
                    size: 16,
                    color: t.when == TaskWhen.overdue ? g.danger : g.ink3,
                  ),
                  title: t.title,
                  trailing: t.minutes == null ? null : Text(GFormat.minutes(t.minutes!), style: GType.caption.c(g.ink3)),
                  onTap: () => openTask(c, t.id),
                ),
            ],
          ),
        );
      },
    );
  }

  static GenieReply _meeting(String s, Snapshot data) {
    final now = DateTime.now();
    final named = data.meetings.where((m) => s.contains(m.title.toLowerCase())).firstOrNull;
    final m =
        named ??
        (data.meetings.where((m) => m.stateAt(now) == MeetingState.live || m.stateAt(now) == MeetingState.next).toList()
              ..sort((a, b) => a.start.compareTo(b.start)))
            .firstOrNull;
    if (m == null) return const GenieReply(thinking: 'Checking your calendar…', text: 'Nothing else is booked today. A good afternoon for deep work.');
    final summary = s.contains('summar');
    final text = summary
        ? (m.notes ?? 'There are no minutes for ${m.title} yet. They appear once the notetaker has written them.')
        : '${m.title} is ${m.stateAt(now) == MeetingState.live ? 'live now' : 'at ${GFormat.time(m.start)}'} with ${m.people.length} people.'
              '${m.agenda.isEmpty ? '' : ' On the agenda: ${m.agenda.join(', ').toLowerCase()}.'}';
    return GenieReply(
      thinking: summary ? 'Reading the minutes…' : 'Checking your calendar…',
      text: text,
      card: (c) {
        final g = c.g;
        return GCard(
          radius: GRadius.tile,
          padding: const EdgeInsets.all(12),
          onTap: () => showMeetingSheet(c, m),
          child: Row(
            children: [
              GIconBox(icon: m.online ? LucideIcons.video : LucideIcons.mapPin, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.title, style: GType.title.c(g.ink)),
                    Text('${GFormat.time(m.start)} · ${GFormat.minutes(m.minutes)} · ${m.place}', style: GType.caption.c(g.ink3)),
                  ],
                ),
              ),
              GAvatarStack(names: m.people, size: 22),
            ],
          ),
        );
      },
    );
  }

  static GenieReply _decision(Decision d) {
    return GenieReply(
      thinking: 'Reading the ${d.source.toLowerCase()} data…',
      text: '${d.detail} Effect if nothing changes: ${d.effect.toLowerCase()}.',
      card: (c) => DecisionCard(decision: d),
    );
  }

  static GenieReply _propose(String q, Snapshot data) {
    var title = q
        .replaceFirst(RegExp(r'^(please\s+)?(can you\s+)?(add|create|make)\s+(a\s+)?(new\s+)?task\s*(to|for|:)?\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^(remind me to|remind me)\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^for me\s*', caseSensitive: false), '')
        .trim();
    if (title.isEmpty) title = 'Follow up with Rahul on the hiring plan';
    title = title[0].toUpperCase() + title.substring(1);
    return GenieReply(
      thinking: 'Drafting the task…',
      text: 'Here’s the task. Nothing is added until you press Add.',
      card: (c) => _ProposalCard(title: title),
    );
  }

  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// A task Genie drafted. The owner presses Add; until then nothing changes.
class _ProposalCard extends StatefulWidget {
  const _ProposalCard({required this.title});

  final String title;

  @override
  State<_ProposalCard> createState() => _ProposalCardState();
}

class _ProposalCardState extends State<_ProposalCard> {
  bool? _added;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return GCard(
      color: g.surface,
      border: true,
      radius: GRadius.tile + 2,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GenieMark(size: 15, mono: g.ink3, dot: g.ai),
              const SizedBox(width: 6),
              Text('Draft task', style: GType.caption.c(g.ai).w(FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.title, style: GType.title.c(g.ink)),
          const SizedBox(height: 4),
          Text('Today · 15m · Leadership', style: GType.caption.c(g.ink3)),
          const SizedBox(height: 12),
          GSwap(
            id: _added ?? 'ask',
            child: switch (_added) {
              null => Row(
                children: [
                  GButton(
                    label: 'Add',
                    icon: LucideIcons.plus,
                    compact: true,
                    onTap: () {
                      context.appRead.addTask(title: widget.title, dept: 'Leadership', minutes: 15, byGenie: true);
                      GHaptics.heavy();
                      setState(() => _added = true);
                      GToast.show(context, 'Added to Today');
                    },
                  ),
                  const SizedBox(width: 8),
                  GButton(label: 'Not now', compact: true, kind: GButtonKind.quiet, onTap: () => setState(() => _added = false)),
                ],
              ),
              true => Row(
                children: [
                  Icon(LucideIcons.circleCheck, size: 16, color: g.success),
                  const SizedBox(width: 6),
                  Text('Added to Today', style: GType.label.c(g.success)),
                ],
              ),
              false => Text('Not added.', style: GType.label.c(g.ink3)),
            },
          ),
        ],
      ),
    );
  }
}
