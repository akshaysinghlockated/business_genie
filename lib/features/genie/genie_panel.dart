import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/genie_mark.dart';
import '../../core/widgets/pressable.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../shell/create_sheet.dart';
import 'genie_brain.dart';
import 'genie_chat.dart';

/// Genie, full screen: a header, then either the start (today's brief and
/// four ways in) or the conversation, and the composer with dictation and
/// voice mode. Genie only suggests; nothing changes until the owner presses.
class GeniePanel extends StatefulWidget {
  const GeniePanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<GeniePanel> createState() => GeniePanelState();
}

class GeniePanelState extends State<GeniePanel> {
  final _chat = GlobalKey<GenieChatState>();
  final _input = TextEditingController();
  final _focus = FocusNode();
  bool _listening = false;
  bool _voice = false;
  Timer? _listen;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _listen?.cancel();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Asks [q] now, or puts the cursor in the composer when [q] is null.
  void ask(String? q) {
    if (q == null) {
      _focus.requestFocus();
    } else {
      _chat.currentState?.send(q);
    }
  }

  void _send() {
    final t = _input.text.trim();
    if (t.isEmpty) return;
    _input.clear();
    _chat.currentState?.send(t);
  }

  void _mic() {
    if (_listening) {
      _listen?.cancel();
      setState(() => _listening = false);
      return;
    }
    GHaptics.heavy();
    _focus.unfocus();
    setState(() => _listening = true);
    _listen = Timer(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      setState(() => _listening = false);
      _chat.currentState?.send('Brief me');
    });
  }

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final has = _input.text.trim().isNotEmpty;
    return Stack(
      children: [
        SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 60,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      _Round(icon: LucideIcons.chevronDown, label: 'Close Genie', onTap: widget.onClose),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Genie', style: GType.h3.c(g.ink)),
                            Text('Knows your plan, goals, tasks and calendar', maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.caption.c(g.ink3)),
                          ],
                        ),
                      ),
                      _Round(icon: LucideIcons.squarePen, label: 'New chat', onTap: () => _chat.currentState?.newChat()),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: GenieChat(
                  key: _chat,
                  top: 0,
                  bottom: 8,
                  start: (context, send) => _Start(onAsk: send),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 58),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    color: g.surface,
                    borderRadius: BorderRadius.circular(29),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 24, offset: const Offset(0, 8))],
                    border: Border.all(color: g.rule),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _Plain(icon: LucideIcons.plus, label: 'Add', onTap: () => showCreateSheet(context)),
                      Expanded(
                        child: _listening
                            ? SizedBox(
                                height: 46,
                                child: Row(
                                  children: [
                                    Text('Listening…', style: GType.body.c(g.ink2)),
                                    const SizedBox(width: 10),
                                    const Expanded(child: _Wave()),
                                  ],
                                ),
                              )
                            : TextField(
                                controller: _input,
                                focusNode: _focus,
                                minLines: 1,
                                maxLines: 4,
                                textInputAction: TextInputAction.send,
                                textCapitalization: TextCapitalization.sentences,
                                onSubmitted: (_) => _send(),
                                style: GType.body.c(g.ink),
                                decoration: InputDecoration(
                                  isCollapsed: true,
                                  border: InputBorder.none,
                                  hintText: 'Ask Genie anything',
                                  hintStyle: GType.body.c(g.ink3),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
                                ),
                              ),
                      ),
                      if (!has) _Plain(icon: _listening ? LucideIcons.square : LucideIcons.mic, label: _listening ? 'Stop' : 'Dictate', onTap: _mic),
                      const SizedBox(width: 4),
                      GPressable(
                        scale: .88,
                        semanticLabel: has ? 'Send' : 'Voice mode',
                        onTap: has
                            ? _send
                            : () {
                                GHaptics.heavy();
                                _focus.unfocus();
                                setState(() => _voice = true);
                              },
                        child: AnimatedContainer(
                          duration: GMotion.quick,
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(color: g.ink, shape: BoxShape.circle),
                          child: AnimatedSwitcher(
                            duration: GMotion.of(context, const Duration(milliseconds: 220)),
                            transitionBuilder: (c, a) => ScaleTransition(
                              scale: Tween(begin: .4, end: 1.0).animate(a),
                              child: FadeTransition(opacity: a, child: c),
                            ),
                            child: Icon(has ? LucideIcons.arrowUp : LucideIcons.audioLines, key: ValueKey(has), size: 19, color: g.onInk),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('Genie suggests. Nothing changes until you press it.', style: GType.caption.c(g.ink3).copyWith(fontSize: 11)),
              ),
            ],
          ),
        ),
        if (_voice)
          Positioned.fill(
            child: _VoiceMode(
              onEnd: (spoke) {
                setState(() => _voice = false);
                if (spoke) _chat.currentState?.send('Brief me');
              },
            ).animate().fadeIn(duration: 260.ms),
          ),
      ],
    );
  }
}

/// Before the first question: who Genie is talking to, today's brief in
/// three lines, and four ways in.
class _Start extends StatelessWidget {
  const _Start({required this.onAsk});

  final ValueChanged<String> onAsk;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final data = context.app.data;
    final now = DateTime.now();
    if (data == null || !data.setupDone) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
        children: [
          const GenieMark(size: 40),
          const SizedBox(height: 20),
          Text('Ask me how to set up your company.', style: GType.display.c(g.ink).copyWith(fontSize: 26)),
          const SizedBox(height: 18),
          _Starter(
            icon: LucideIcons.building2,
            title: 'What do I set up first?',
            sub: 'Plan, goals and people',
            onTap: () => onAsk('How do I set up my company?'),
          ),
        ],
      );
    }
    final live = data.meetings.where((m) => m.stateAt(now) == MeetingState.live).firstOrNull;
    final next = data.meetings.where((m) => m.stateAt(now) == MeetingState.next).toList()..sort((a, b) => a.start.compareTo(b.start));
    final open = data.openDecisions;
    final behind = data.goals.where((x) => x.status == GoalStatus.behind).toList();
    final brief = <(IconData, Color, String)>[
      if (live != null) (LucideIcons.radio, g.danger, '${live.title} is live, ${live.end.difference(now).inMinutes.clamp(1, 999)} min left'),
      if (open.isNotEmpty)
        (LucideIcons.gitFork, g.warning, '${open.length} ${open.length == 1 ? 'decision waits' : 'decisions wait'} on you: ${open.first.title.toLowerCase()}'),
      if (behind.isNotEmpty)
        (LucideIcons.triangleAlert, g.danger, '${behind.length} ${behind.length == 1 ? 'goal is' : 'goals are'} behind, led by “${behind.first.title}”'),
      if (live == null && next.isNotEmpty) (LucideIcons.calendarClock, g.ink2, 'Next: ${next.first.title} at ${GFormat.time(next.first.start)}'),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      children: [
        const _Orbit().animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 22),
        Text('${GFormat.greeting(now)}, ${data.owner.first}', style: GType.label.c(g.ink3).copyWith(fontSize: 14)).animate().fadeIn(delay: 80.ms),
        const SizedBox(height: 4),
        Text(
          'What should we look at today?',
          style: GType.display.c(g.ink).copyWith(fontSize: 28, height: 1.12),
        ).animate().fadeIn(delay: 120.ms, duration: 400.ms).moveY(begin: 8, end: 0, curve: GMotion.easeOut),
        if (brief.isNotEmpty) ...[
          const SizedBox(height: 22),
          GPressable(
            scale: .98,
            semanticLabel: 'Today’s brief. Read it in full',
            onTap: () => onAsk('Brief me'),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              decoration: BoxDecoration(
                color: g.surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('TODAY’S BRIEF', style: GType.micro.c(g.ink3).copyWith(letterSpacing: 1)),
                      const Spacer(),
                      Text(GFormat.time(now), style: GType.caption.c(g.ink3)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final b in brief.take(3))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(b.$1, size: 15, color: b.$2),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(b.$3, style: GType.bodyS.c(g.ink).copyWith(height: 1.35))),
                        ],
                      ),
                    ),
                  Container(height: 1, color: g.rule, margin: const EdgeInsets.only(top: 6)),
                  SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        Text('Read the full brief', style: GType.label.c(g.ink).w(FontWeight.w600)),
                        const Spacer(),
                        Icon(LucideIcons.arrowRight, size: 16, color: g.ink),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 180.ms, duration: 400.ms).moveY(begin: 10, end: 0, curve: GMotion.easeOut),
        ],
        const SizedBox(height: 24),
        Text('Start with', style: GType.label.c(g.ink3)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Starter(
                icon: LucideIcons.chartNoAxesColumn,
                title: 'How’s business?',
                sub: 'Milestone, targets, goals',
                onTap: () => onAsk('How’s business?'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Starter(icon: LucideIcons.listOrdered, title: 'Plan my day', sub: 'Tasks around meetings', onTap: () => onAsk('Plan my day')),
            ),
          ],
        ).animate().fadeIn(delay: 240.ms, duration: 400.ms),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Starter(
                icon: LucideIcons.calendarClock,
                title: 'Prep my meeting',
                sub: next.isEmpty ? 'Nothing else today' : next.first.title,
                onTap: () => onAsk('My next meeting'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Starter(icon: LucideIcons.triangleAlert, title: 'What’s off track?', sub: 'Goals and decisions', onTap: () => onAsk('What’s off track?')),
            ),
          ],
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
      ],
    );
  }
}

class _Starter extends StatelessWidget {
  const _Starter({required this.icon, required this.title, required this.sub, required this.onTap});

  final IconData icon;
  final String title, sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return GPressable(
      scale: .96,
      semanticLabel: title,
      onTap: onTap,
      child: Container(
        height: 118,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: g.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .04), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: g.card, shape: BoxShape.circle),
              child: Icon(icon, size: 16, color: g.ink),
            ),
            const Spacer(),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.title.c(g.ink).copyWith(fontSize: 14.5)),
            const SizedBox(height: 2),
            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.caption.c(g.ink3)),
          ],
        ),
      ),
    );
  }
}

/// The mark with its dot slowly circling the ring: Genie, awake.
class _Orbit extends StatefulWidget {
  const _Orbit();

  @override
  State<_Orbit> createState() => _OrbitState();
}

class _OrbitState extends State<_Orbit> with SingleTickerProviderStateMixin {
  late final _spin = AnimationController(vsync: this, duration: const Duration(seconds: 6));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (GMotion.reduced(context)) {
      _spin.stop();
    } else if (!_spin.isAnimating) {
      _spin.repeat();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(color: g.ink, shape: BoxShape.circle),
            ),
            GenieMark(size: 26, mono: g.onInk, dot: Colors.transparent),
            AnimatedBuilder(
              animation: _spin,
              builder: (context, _) {
                final a = -math.pi / 4 + _spin.value * 2 * math.pi;
                return Transform.translate(
                  offset: Offset(math.cos(a) * 22, math.sin(a) * 22),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: Color(0xFF9B85FF), shape: BoxShape.circle),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Voice mode: a breathing orb on ink. Genie listens, then answers aloud
/// with the words shown underneath. Mute and End sit at the bottom.
class _VoiceMode extends StatefulWidget {
  const _VoiceMode({required this.onEnd});

  final ValueChanged<bool> onEnd;

  @override
  State<_VoiceMode> createState() => _VoiceModeState();
}

class _VoiceModeState extends State<_VoiceMode> with SingleTickerProviderStateMixin {
  late final _orb = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  bool _muted = false;
  bool _speaking = false;
  String _said = '';
  Timer? _turn;
  Timer? _words;

  @override
  void initState() {
    super.initState();
    _turn = Timer(const Duration(milliseconds: 2400), _answer);
  }

  void _answer() {
    if (!mounted) return;
    final text = GenieBrain.answer('Brief me', context.appRead).text;
    setState(() => _speaking = true);
    var i = 0;
    _words = Timer.periodic(const Duration(milliseconds: 90), (t) {
      if (!mounted) return t.cancel();
      final next = text.indexOf(' ', i + 1);
      setState(() => _said = text.substring(0, next == -1 ? text.length : next));
      i = next;
      if (next == -1) t.cancel();
    });
  }

  @override
  void dispose() {
    _turn?.cancel();
    _words?.cancel();
    _orb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF111113);
    const on = Colors.white;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: ink,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 18),
              Text(_speaking ? 'Genie' : (_muted ? 'Muted' : 'Listening'), style: GType.label.c(on.withValues(alpha: .6))),
              const Spacer(),
              AnimatedBuilder(
                animation: _orb,
                builder: (context, _) => CustomPaint(size: const Size(240, 240), painter: _OrbPainter(_orb.value, _speaking ? 1 : (_muted ? .2 : .6))),
              ),
              const SizedBox(height: 36),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: SizedBox(
                  height: 120,
                  child: Text(
                    _speaking ? _said : 'Ask about your goals, your team or your day.',
                    textAlign: TextAlign.center,
                    maxLines: 5,
                    overflow: TextOverflow.fade,
                    style: GType.body.c(on.withValues(alpha: _speaking ? .92 : .5)).copyWith(fontSize: 16, height: 1.45),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _VoiceButton(
                      icon: _muted ? LucideIcons.micOff : LucideIcons.mic,
                      label: _muted ? 'Unmute' : 'Mute',
                      color: on.withValues(alpha: _muted ? .9 : .12),
                      iconColor: _muted ? ink : on,
                      onTap: () => setState(() => _muted = !_muted),
                    ),
                    const SizedBox(width: 28),
                    _VoiceButton(icon: LucideIcons.x, label: 'End', color: const Color(0xFFD93F44), iconColor: on, onTap: () => widget.onEnd(_speaking)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceButton extends StatelessWidget {
  const _VoiceButton({required this.icon, required this.label, required this.color, required this.iconColor, required this.onTap});

  final IconData icon;
  final String label;
  final Color color, iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GPressable(
      scale: .9,
      semanticLabel: label,
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: GMotion.quick,
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(label, style: GType.caption.c(Colors.white.withValues(alpha: .6))),
        ],
      ),
    );
  }
}

/// Three soft rings that drift and breathe; [energy] makes them move more
/// while Genie speaks.
class _OrbPainter extends CustomPainter {
  _OrbPainter(this.t, this.energy);

  final double t, energy;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 * .62;
    final a = t * 2 * math.pi;
    const tones = [Color(0xFF7C5CFF), Color(0xFF3579D7), Color(0xFFB9A8FF)];
    for (var i = 0; i < 3; i++) {
      final phase = a + i * 2.1;
      final o = Offset(math.cos(phase), math.sin(phase * 1.3)) * (10 + 12 * energy);
      final rr = r * (1 + .06 * energy * math.sin(a * 2 + i));
      canvas.drawCircle(
        c + o,
        rr,
        Paint()
          ..color = tones[i].withValues(alpha: .55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
      );
    }
    canvas.drawCircle(c, r * .78, Paint()..color = Colors.white.withValues(alpha: .9 * (.6 + .4 * energy)));
    canvas.drawCircle(
      c,
      r * .78,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white, const Color(0xFFE9E4FF).withValues(alpha: .9)],
        ).createShader(Rect.fromCircle(center: c, radius: r * .78)),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.t != t || old.energy != energy;
}

class _Round extends StatelessWidget {
  const _Round({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return GPressable(
      scale: .9,
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: g.surface,
          shape: BoxShape.circle,
          border: Border.all(color: g.rule),
        ),
        child: Icon(icon, size: 18, color: g.ink),
      ),
    );
  }
}

class _Plain extends StatelessWidget {
  const _Plain({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return GPressable(
      scale: .88,
      semanticLabel: label,
      onTap: onTap,
      child: SizedBox.square(dimension: 46, child: Icon(icon, size: 19, color: g.ink2)),
    );
  }
}

/// Bars that move while Genie listens.
class _Wave extends StatelessWidget {
  const _Wave();

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Row(
      children: [
        for (var i = 0; i < 18; i++)
          Expanded(
            child: Center(
              child: Container(width: 3, height: 18, decoration: GShape.fill(g.ink2, 2))
                  .animate(onPlay: (c) => c.repeat(reverse: true), delay: ((i * 73) % 600).ms)
                  .scaleY(begin: .25, end: 1, duration: 420.ms, curve: Curves.easeInOut),
            ),
          ),
      ],
    );
  }
}
