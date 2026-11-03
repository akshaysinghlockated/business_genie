import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/genie_mark.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/swap.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../decisions/decision_card.dart' show showDecisionSheet;
import '../shell/routes.dart';
import '../shell/tab_page.dart';

const double _m = 20;

IconData newsIcon(NewsKind k) => switch (k) {
  NewsKind.industry => LucideIcons.trendingUp,
  NewsKind.competitors => LucideIcons.swords,
  NewsKind.rules => LucideIcons.landmark,
  NewsKind.customers => LucideIcons.users,
  NewsKind.company => LucideIcons.award,
};

void openNews(BuildContext context, {String? focus}) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => NewsScreen(focus: focus)));

void openSuggestions(BuildContext context) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SuggestionsScreen()));

// ─── Rolling highlight ────────────────────────────────────────────────────

/// A small picture for a story: a photo from the web when there is a
/// connection, else a calm tile with the story's icon.
class NewsThumb extends StatelessWidget {
  const NewsThumb({super.key, required this.item, this.size = 44, this.radius = 12});

  final NewsItem item;
  final double size, radius;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final fallback = Container(
      width: size,
      height: size,
      color: g.card,
      child: Icon(newsIcon(item.kind), size: size * .4, color: g.ink2),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          'https://picsum.photos/seed/bg-${item.id}/${(size * 3).round()}/${(size * 3).round()}',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
          frameBuilder: (context, child, frame, sync) =>
              AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: frame == null && !sync ? fallback : child),
        ),
      ),
    );
  }
}

/// News from the company's field in a small strip that keeps scrolling
/// sideways; touch pauses it, a story opens the news list on it.
class NewsTicker extends StatefulWidget {
  const NewsTicker({super.key, required this.news});

  final List<NewsItem> news;

  @override
  State<NewsTicker> createState() => _NewsTickerState();
}

class _NewsTickerState extends State<NewsTicker> with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  bool _held = false;

  static const _speed = 28.0; // points a second

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (GMotion.reduced(context)) {
      if (_ticker.isActive) _ticker.stop();
    } else if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration t) {
    final dt = _last == Duration.zero ? 0.0 : (t - _last).inMicroseconds / 1e6;
    _last = t;
    if (_held || !_scroll.hasClients) return;
    final p = _scroll.position;
    // The list repeats; jump back by one copy so it never ends.
    final copy = p.maxScrollExtent / 3;
    var next = p.pixels + _speed * dt;
    if (copy > 0 && next >= copy * 2) next -= copy;
    _scroll.jumpTo(next);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final items = widget.news;
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(_m + 4, 0, _m, 10),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: g.danger, shape: BoxShape.circle),
                ),
                const SizedBox(width: 7),
                Text('NEWS IN YOUR FIELD', style: GType.micro.c(g.ink3).copyWith(letterSpacing: .8)),
                const Spacer(),
                GPressable(
                  scale: .94,
                  semanticLabel: 'All news',
                  onTap: () => openNews(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View all', style: GType.caption.c(g.ink2).w(FontWeight.w600)),
                      Icon(LucideIcons.chevronRight, size: 14, color: g.ink3),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 64,
            child: Listener(
              onPointerDown: (_) => _held = true,
              onPointerUp: (_) => _held = false,
              onPointerCancel: (_) => _held = false,
              child: ListView.separated(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: _m),
                itemCount: items.length * 3,
                separatorBuilder: (_, _) => Container(width: 1, margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), color: g.rule),
                itemBuilder: (context, i) {
                  final n = items[i % items.length];
                  return GPressable(
                    scale: .97,
                    semanticLabel: n.title,
                    onTap: () => openNews(context, focus: n.id),
                    child: SizedBox(
                      width: 268,
                      child: Row(
                        children: [
                          NewsThumb(item: n, size: 60, radius: 16),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${n.kind.label} · ${n.ago}', style: GType.caption.c(g.ink3).copyWith(fontSize: 11.5)),
                                const SizedBox(height: 3),
                                Text(
                                  n.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GType.label.c(g.ink).w(FontWeight.w600).copyWith(fontSize: 14, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── News list ────────────────────────────────────────────────────────────

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key, this.focus});

  /// The story that was tapped in the strip; it opens first.
  final String? focus;

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  NewsKind? _kind;

  @override
  Widget build(BuildContext context) {
    return GPushPage(
      title: 'News in your field',
      child: GLoadView(
        builder: (context, data) {
          final g = context.g;
          if (data.news.isEmpty) {
            return ListView(
              padding: const EdgeInsets.only(top: GSpace.xl),
              children: const [
                GEmptyState(
                  icon: LucideIcons.newspaper,
                  title: 'No news yet',
                  body: 'Once your industry is set in the business plan, news from your field shows here with what it means for you.',
                ),
              ],
            );
          }
          final kinds = [
            for (final k in NewsKind.values)
              if (data.news.any((n) => n.kind == k)) k,
          ];
          var list = data.news.where((n) => _kind == null || n.kind == _kind).toList();
          if (_kind == null && widget.focus != null) {
            final f = list.where((n) => n.id == widget.focus).toList();
            list = [...f, ...list.where((n) => n.id != widget.focus)];
          }
          return Column(
            children: [
              const SizedBox(height: GSpace.m),
              GChipRow(
                children: [
                  GChip(label: 'All', count: data.news.length, selected: _kind == null, onTap: () => setState(() => _kind = null)),
                  for (final k in kinds) GChip(label: k.label, selected: _kind == k, onTap: () => setState(() => _kind = k)),
                ],
              ),
              const SizedBox(height: GSpace.s),
              Expanded(
                child: GSwap(
                  id: _kind?.name ?? 'all',
                  alignment: Alignment.topCenter,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(_m, 12, _m, MediaQuery.paddingOf(context).bottom + 32),
                    itemCount: list.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      if (i == list.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Sample sources for the demo. Genie’s read is a suggestion, not advice.',
                            textAlign: TextAlign.center,
                            style: GType.caption.c(g.ink3),
                          ),
                        );
                      }
                      return _NewsCard(item: list[i], highlight: list[i].id == widget.focus && _kind == null);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item, required this.highlight});

  final NewsItem item;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final n = item;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: g.surface,
        borderRadius: BorderRadius.circular(22),
        border: highlight ? Border.all(color: g.ink, width: 1.5) : null,
        boxShadow: const [BoxShadow(color: Color(0x0B000000), blurRadius: 22, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: g.card, borderRadius: BorderRadius.circular(9)),
                child: Icon(newsIcon(n.kind), size: 15, color: g.ink),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('${n.kind.label} · ${n.source}', maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.caption.c(g.ink3)),
              ),
              Text(n.ago, style: GType.caption.c(g.ink3)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 2.2,
              child: LayoutBuilder(
                builder: (context, box) => NewsThumb(item: n, size: box.maxWidth, radius: 0),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(n.title, style: GType.h3.c(g.ink).copyWith(height: 1.3)),
          const SizedBox(height: 8),
          Text(n.summary, style: GType.bodyS.c(g.ink2).copyWith(height: 1.5)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: g.aiSoft, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const GenieMark(size: 15),
                    const SizedBox(width: 6),
                    Text('What this means for you', style: GType.caption.c(g.ink).w(FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(n.take, style: GType.bodyS.c(g.ink).copyWith(height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Btn(
                label: 'Ask Genie',
                icon: LucideIcons.messageSquareText,
                onTap: () => openGenie(context, ask: 'What does “${n.title}” mean for us?'),
              ),
              const SizedBox(width: 8),
              _Btn(
                label: 'Make a task',
                icon: LucideIcons.plus,
                quiet: true,
                onTap: () {
                  context.appRead.addTask(title: 'Follow up: ${n.title}', dept: 'Leadership', minutes: 15, byGenie: true);
                  GToast.show(context, 'Added to your tasks');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.label, required this.icon, required this.onTap, this.quiet = false});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return GPressable(
      scale: .95,
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: quiet ? Colors.transparent : g.ink,
          borderRadius: BorderRadius.circular(18),
          border: quiet ? Border.all(color: g.ruleStrong) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: quiet ? g.ink : g.onInk),
            const SizedBox(width: 6),
            Text(label, style: GType.caption.c(quiet ? g.ink : g.onInk).w(FontWeight.w600).copyWith(fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}

// ─── Suggestions ──────────────────────────────────────────────────────────

/// Runs a suggestion: open its decision, add its task, or ask Genie.
void runSuggestion(BuildContext context, Suggestion s) {
  final app = context.appRead;
  switch (s.action) {
    case SuggestionAction.decision:
      final d = app.data?.decisions.where((d) => d.id == s.ref).firstOrNull;
      if (d != null) showDecisionSheet(context, d);
    case SuggestionAction.task:
      app.addTask(title: s.ref ?? s.title, dept: 'Leadership', minutes: 30, byGenie: true);
      app.closeSuggestion(s.id);
      GToast.show(context, 'Added to your tasks', action: 'Undo', onAction: () => app.reopenSuggestion(s.id));
    case SuggestionAction.genie:
      app.closeSuggestion(s.id);
      openGenie(context, ask: s.ref ?? s.title);
  }
}

void dismissSuggestion(BuildContext context, Suggestion s) {
  final app = context.appRead;
  app.closeSuggestion(s.id);
  GHaptics.select();
  GToast.show(context, 'Hidden for now', type: GToastType.info, action: 'Undo', onAction: () => app.reopenSuggestion(s.id));
}

/// One suggestion: the area, what to do, why, the gain, and two buttons.
class SuggestionTile extends StatelessWidget {
  const SuggestionTile({super.key, required this.s, this.width});

  final Suggestion s;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: g.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: g.ai.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: g.aiSoft, borderRadius: BorderRadius.circular(10)),
                child: Text(s.area, style: GType.micro.c(g.ai).copyWith(letterSpacing: 0)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(s.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GType.title.c(g.ink).copyWith(fontSize: 15.5, height: 1.3)),
          const SizedBox(height: 8),
          Text(s.why, maxLines: 2, overflow: TextOverflow.ellipsis, style: GType.caption.c(g.ink2).copyWith(fontSize: 12.5, height: 1.45)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(LucideIcons.trendingUp, size: 13, color: g.success),
              const SizedBox(width: 5),
              Flexible(
                child: Text(s.impact, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.caption.c(g.success).w(FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Btn(label: s.cta, icon: LucideIcons.check, onTap: () => runSuggestion(context, s)),
              const SizedBox(width: 8),
              GPressable(
                scale: .95,
                semanticLabel: 'Not now',
                onTap: () => dismissSuggestion(context, s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  child: Text('Not now', style: GType.caption.c(g.ink3).w(FontWeight.w600).copyWith(fontSize: 12.5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Genie suggests, one card at a time: swipe right to keep it, left to let
/// it go. Kept ones wait below, ready to act on.
class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> with SingleTickerProviderStateMixin {
  Offset _drag = Offset.zero;
  late final _fly = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  Offset _from = Offset.zero, _to = Offset.zero;
  VoidCallback? _after;

  @override
  void initState() {
    super.initState();
    _fly.addListener(() => setState(() => _drag = Offset.lerp(_from, _to, Curves.easeOut.transform(_fly.value))!));
    _fly.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        final f = _after;
        _after = null;
        setState(() => _drag = Offset.zero);
        f?.call();
      }
    });
  }

  @override
  void dispose() {
    _fly.dispose();
    super.dispose();
  }

  void _animate(Offset to, [VoidCallback? after]) {
    _from = _drag;
    _to = to;
    _after = after;
    _fly.forward(from: 0);
  }

  void _decide(Suggestion s, bool keep) {
    final w = MediaQuery.sizeOf(context).width;
    GHaptics.select();
    _animate(Offset(keep ? w * 1.4 : -w * 1.4, _drag.dy), () {
      final app = context.appRead;
      keep ? app.keepSuggestion(s.id) : app.closeSuggestion(s.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final g = context.g;
    final deck = app.openSuggestions;
    final kept = app.kept;
    final w = MediaQuery.sizeOf(context).width;
    return GPushPage(
      title: 'Genie suggests',
      child: ListView(
        padding: EdgeInsets.fromLTRB(_m, 12, _m, MediaQuery.paddingOf(context).bottom + 32),
        children: [
          Text(deck.isEmpty ? 'You have seen every suggestion.' : 'Swipe right to keep, left to let it go. ${deck.length} left.', style: GType.label.c(g.ink3)),
          const SizedBox(height: 16),
          SizedBox(
            height: 340,
            child: deck.isEmpty
                ? Container(
                    decoration: BoxDecoration(color: g.surface, borderRadius: BorderRadius.circular(26)),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(color: g.aiSoft, shape: BoxShape.circle),
                          child: const Center(child: GenieMark(size: 26)),
                        ),
                        const SizedBox(height: 14),
                        Text('All caught up', style: GType.h3.c(g.ink)),
                        const SizedBox(height: 6),
                        Text('New suggestions arrive as your goals, tasks and news change.', textAlign: TextAlign.center, style: GType.bodyS.c(g.ink3)),
                      ],
                    ),
                  )
                : Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var i = (deck.length - 1).clamp(0, 2); i >= 0; i--)
                        Positioned.fill(
                          child: i == 0
                              ? GestureDetector(
                                  onPanUpdate: (d) => setState(() => _drag += d.delta),
                                  onPanEnd: (d) {
                                    final v = d.velocity.pixelsPerSecond.dx;
                                    if (_drag.dx > w * .28 || v > 900) {
                                      _decide(deck.first, true);
                                    } else if (_drag.dx < -w * .28 || v < -900) {
                                      _decide(deck.first, false);
                                    } else {
                                      _animate(Offset.zero);
                                    }
                                  },
                                  child: Transform.translate(
                                    offset: _drag,
                                    child: Transform.rotate(
                                      angle: _drag.dx / w * .25,
                                      child: _DeckCard(s: deck[0], lean: _drag.dx / (w * .28)),
                                    ),
                                  ),
                                )
                              : Transform.translate(
                                  offset: Offset(0, 30.0 * i),
                                  child: Transform.scale(
                                    scale: 1 - .05 * i,
                                    alignment: Alignment.topCenter,
                                    child: _DeckCard(s: deck[i], lean: 0),
                                  ),
                                ),
                        ),
                    ],
                  ),
          ),
          if (deck.isNotEmpty) ...[
            const SizedBox(height: 52),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundAct(icon: LucideIcons.x, label: 'Let it go', color: g.ink2, bg: g.surface, onTap: () => _decide(deck.first, false)),
                const SizedBox(width: 28),
                _RoundAct(icon: LucideIcons.check, label: 'Keep', color: g.onInk, bg: g.ink, onTap: () => _decide(deck.first, true)),
              ],
            ),
          ],
          if (kept.isNotEmpty) ...[
            const SizedBox(height: 34),
            Text('Kept · ${kept.length}', style: GType.h3.c(g.ink)),
            const SizedBox(height: 12),
            for (final s in kept)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                decoration: BoxDecoration(color: g.surface, borderRadius: BorderRadius.circular(18)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.label.c(g.ink).copyWith(fontSize: 14.5)),
                          const SizedBox(height: 3),
                          Text(s.impact, style: GType.caption.c(g.success).w(FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _Btn(label: s.cta, icon: LucideIcons.check, onTap: () => runSuggestion(context, s)),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 18),
          Text(
            'Based on your goals, decisions, tasks and news from your field. Nothing changes until you press it.',
            textAlign: TextAlign.center,
            style: GType.caption.c(g.ink3),
          ),
        ],
      ),
    );
  }
}

class _DeckCard extends StatelessWidget {
  const _DeckCard({required this.s, required this.lean});

  final Suggestion s;

  /// -1 … 1 as the card is dragged: shows Keep or Let go.
  final double lean;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final keep = lean.clamp(0.0, 1.0), skip = (-lean).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: g.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Color.lerp(g.rule, keep > 0 ? g.success : g.danger, (keep + skip).clamp(0.0, 1.0))!, width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 30, offset: Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GenieMark(size: 20),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: g.aiSoft, borderRadius: BorderRadius.circular(10)),
                child: Text(s.area, style: GType.micro.c(g.ai).copyWith(letterSpacing: 0)),
              ),
              const Spacer(),
              if (keep > .15) Text('KEEP', style: GType.micro.c(g.success).copyWith(letterSpacing: 1)),
              if (skip > .15) Text('LET GO', style: GType.micro.c(g.danger).copyWith(letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 22),
          Text(s.title, style: GType.h2.c(g.ink).copyWith(fontSize: 22, height: 1.25)),
          const SizedBox(height: 12),
          Text(s.why, style: GType.body.c(g.ink2).copyWith(fontSize: 14.5, height: 1.5)),
          const Spacer(),
          Row(
            children: [
              Icon(LucideIcons.trendingUp, size: 15, color: g.success),
              const SizedBox(width: 6),
              Expanded(child: Text(s.impact, style: GType.label.c(g.success).w(FontWeight.w600))),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundAct extends StatelessWidget {
  const _RoundAct({required this.icon, required this.label, required this.color, required this.bg, required this.onTap});

  final IconData icon;
  final String label;
  final Color color, bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return GPressable(
      scale: .9,
      semanticLabel: label,
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 18, offset: Offset(0, 6))],
            ),
            child: Icon(icon, size: 26, color: color),
          ),
          const SizedBox(height: 8),
          Text(label, style: GType.caption.c(g.ink2)),
        ],
      ),
    );
  }
}

/// Genie suggests, as a small round button in the Home app bar. Every five
/// seconds a ring ripples out, so it reads as alive without taking room.
/// Tap opens the swipe screen.
class SuggestButton extends StatefulWidget {
  const SuggestButton({super.key});

  @override
  State<SuggestButton> createState() => _SuggestButtonState();
}

class _SuggestButtonState extends State<SuggestButton> with SingleTickerProviderStateMixin {
  // Drives the glow that circles the border, slowly and for ever.
  late final _spin = AnimationController(vsync: this, duration: const Duration(seconds: 3));

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
    final n = context.app.openSuggestions.length;
    return GPressable(
      scale: .95,
      semanticLabel: n > 0 ? 'Genie suggests, $n new ideas' : 'Genie suggests',
      onTap: () => openSuggestions(context),
      child: AnimatedBuilder(
        animation: _spin,
        builder: (context, child) => Container(
          width: 92,
          height: 40,
          padding: const EdgeInsets.all(2.8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            // A white light travels round the edge: the "something new" cue.
            gradient: SweepGradient(
              transform: GradientRotation(_spin.value * 6.2832),
              colors: const [Color(0x33FFFFFF), Color(0xFFFFFFFF), Color(0xFFB9A8FF), Color(0x33FFFFFF), Color(0x33FFFFFF)],
              stops: const [0, .12, .22, .4, 1],
            ),
          ),
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(color: const Color(0xFF141416), borderRadius: BorderRadius.circular(17.5)),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('✦', style: TextStyle(color: Color(0xFFC9BCFF), fontSize: 10, height: 1)),
                        const SizedBox(width: 3),
                        Text('Genie', style: GType.caption.c(Colors.white).w(FontWeight.w700).copyWith(fontSize: 11.5, height: 1.1)),
                      ],
                    ),
                    Text('suggests', style: GType.micro.c(Colors.white.withValues(alpha: .62)).copyWith(fontSize: 9.5, letterSpacing: .2, height: 1.15)),
                  ],
                ),
              ),
              if (n > 0)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    height: 18,
                    constraints: const BoxConstraints(minWidth: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C5CFF),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text('$n', style: GType.micro.c(Colors.white).copyWith(fontSize: 9.5, height: 1, letterSpacing: 0)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
