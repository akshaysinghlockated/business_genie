import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/genie_mark.dart';
import '../../core/widgets/pressable.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import 'genie_brain.dart';

/// True while the conversation is empty; the shell shows the suggestion pills
/// only then.
final ValueNotifier<bool> genieChatEmpty = ValueNotifier(true);

/// The Genie pane: a quiet hello, then the conversation. Bubbles pop from
/// their corner; replies say what Genie is doing while it thinks (a breathing
/// lamp over shimmering words), then materialise and write themselves in.
class GenieChat extends StatefulWidget {
  const GenieChat({super.key, required this.top, required this.bottom, this.start});

  /// Space under the top bar and above the composer.
  final double top, bottom;

  /// What to show before the first question; it gets [GenieChatState.send].
  final Widget Function(BuildContext context, ValueChanged<String> send)? start;

  @override
  State<GenieChat> createState() => GenieChatState();
}

class GenieChatState extends State<GenieChat> {
  final _scroll = ScrollController();
  final _messages = <GenieMessage>[];
  String? _thinking;
  Timer? _stream;

  bool get busy => _thinking != null;

  @override
  void dispose() {
    _stream?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent, duration: GMotion.of(context, const Duration(milliseconds: 420)), curve: GMotion.easeOut);
    });
  }

  void newChat() {
    _stream?.cancel();
    setState(() {
      _messages.clear();
      _thinking = null;
    });
    genieChatEmpty.value = true;
  }

  Future<void> send(String text) async {
    final q = text.trim();
    if (q.isEmpty || busy) return;
    _stream?.cancel();
    for (final m in _messages) {
      m.streamed = m.text.length;
    }
    final reply = GenieBrain.answer(q, context.appRead);
    setState(() {
      _messages.add(GenieMessage.me(q));
      _thinking = reply.thinking;
    });
    genieChatEmpty.value = false;
    GHaptics.light();
    _toBottom();
    await Future<void>.delayed(Duration(milliseconds: 900 + math.min(900, reply.text.length * 4)));
    if (!mounted) return;
    final msg = GenieMessage.genie(reply);
    setState(() {
      _thinking = null;
      _messages.add(msg);
    });
    _toBottom();
    if (GMotion.reduced(context)) {
      msg.streamed = msg.text.length;
      return;
    }
    _stream = Timer.periodic(const Duration(milliseconds: 34), (t) {
      if (!mounted) return t.cancel();
      final next = msg.text.indexOf(' ', msg.streamed + 1);
      setState(() => msg.streamed = next == -1 ? msg.text.length : next);
      if (msg.streamed >= msg.text.length) {
        t.cancel();
        GHaptics.select();
        _toBottom();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final empty = _messages.isEmpty && _thinking == null;
    return AnimatedSwitcher(
      duration: GMotion.of(context, const Duration(milliseconds: 320)),
      switchInCurve: GMotion.easeOut,
      switchOutCurve: GMotion.easeOut,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween(begin: .97, end: 1.0).animate(a), child: child),
      ),
      child: empty
          ? KeyedSubtree(
              key: const ValueKey('hello'),
              child: widget.start?.call(context, send) ?? _Hello(top: widget.top, bottom: widget.bottom, onBrief: () => send('Brief me')),
            )
          : ListView(
              key: const ValueKey('chat'),
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(18, widget.top + 8, 18, widget.bottom + 24),
              children: [
                for (final m in _messages)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _Message(key: ObjectKey(m), message: m, onChip: send),
                  ),
                if (_thinking != null) _Thinking(text: _thinking!),
              ],
            ),
    );
  }
}

class _Hello extends StatelessWidget {
  const _Hello({required this.top, required this.bottom, required this.onBrief});

  final double top, bottom;
  final VoidCallback onBrief;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final data = context.app.data;
    final now = DateTime.now();
    final needs = data == null ? 0 : data.openDecisions.length + data.openTasks.where((t) => t.when == TaskWhen.overdue && t.assigneeId == null).length;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, top, 24, bottom + 90),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GenieMark(size: 46).materialize(),
            const SizedBox(height: 18),
            Text(
              data == null ? 'Genie' : '${GFormat.greeting(now)}, ${data.owner.first}',
              textAlign: TextAlign.center,
              style: GType.h2.c(g.ink).copyWith(fontSize: 21, letterSpacing: -.6),
            ).materialize(delay: 80.ms),
            const SizedBox(height: 8),
            if (needs > 0)
              GPressable(
                scale: .95,
                semanticLabel: '$needs things need you today. Brief me',
                onTap: onBrief,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: g.ai, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '$needs thing${needs == 1 ? '' : 's'} need${needs == 1 ? 's' : ''} you today',
                        style: GType.label.c(g.ink2).copyWith(fontSize: 13.5),
                      ),
                      const SizedBox(width: 6),
                      Icon(LucideIcons.chevronRight, size: 14, color: g.ink3),
                    ],
                  ),
                ),
              ).materialize(delay: 160.ms)
            else
              Text(
                data == null || !data.setupDone ? 'Ask me how to set up your company.' : 'Nothing needs you right now.',
                style: GType.label.c(g.ink2).copyWith(fontSize: 13.5),
              ).materialize(delay: 160.ms),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.message, required this.onChip});

  final GenieMessage message;
  final ValueChanged<String> onChip;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final m = message;
    if (m.me) {
      return Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: g.ink,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(6),
              ),
            ),
            child: Text(m.text, style: GType.body.c(g.onInk).copyWith(fontSize: 14, height: 1.4)),
          ),
        ).pop(),
      );
    }
    final done = m.streamed >= m.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(padding: EdgeInsets.only(top: 5), child: GenieMark(size: 20)),
            const SizedBox(width: 10),
            Expanded(child: Text(m.text.substring(0, m.streamed.clamp(0, m.text.length)), style: GType.body.c(g.ink).copyWith(fontSize: 14.5, height: 1.5))),
          ],
        ).materialize(duration: 500.ms, blur: false),
        if (done && m.card != null) Padding(padding: const EdgeInsets.only(top: 12), child: m.card!(context)).materialize(delay: 60.ms),
        if (done && m.chips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in m.chips)
                  GPressable(
                    scale: .95,
                    semanticLabel: c,
                    onTap: () => onChip(c),
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: g.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: g.ruleStrong),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [Text(c, style: GType.caption.c(g.ink).copyWith(fontSize: 12.5))],
                      ),
                    ),
                  ),
              ],
            ),
          ).materialize(delay: 140.ms, blur: false),
      ],
    );
  }
}

/// What Genie is doing, in words that shimmer, beside a lamp that breathes.
class _Thinking extends StatelessWidget {
  const _Thinking({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final reduced = GMotion.reduced(context);
    Widget lamp = const GenieMark(size: 20);
    Widget words = Text(text, style: GType.label.c(g.ink3).copyWith(fontSize: 13.5));
    if (!reduced) {
      lamp = lamp
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -1.5, duration: 650.ms, curve: Curves.easeInOut)
          .rotate(begin: 0, end: -.016, duration: 650.ms, curve: Curves.easeInOut)
          .fade(begin: 1, end: .6, duration: 650.ms);
      words = words.animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms, color: g.ink, angle: 0);
    }
    return Row(
      children: [
        lamp,
        const SizedBox(width: 10),
        Flexible(child: words),
      ],
    ).materialize(duration: 400.ms, blur: false);
  }
}
