import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/palette.dart';
import '../theme/tokens.dart';
import '../theme/type.dart';
import 'pressable.dart';

/// Pill tabs for a screen ("Today 5 · Upcoming 3 · Done"). An ink pill rides
/// a spring to the chosen tab and keeps its speed when the choice changes
/// mid-flight.
class GUnderlineTabs<T> extends StatefulWidget {
  const GUnderlineTabs({super.key, required this.tabs, required this.value, required this.onChanged});

  /// Each tab: its value, its label and an optional count.
  final List<(T, String, int?)> tabs;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  State<GUnderlineTabs<T>> createState() => _GUnderlineTabsState<T>();
}

class _GUnderlineTabsState<T> extends State<GUnderlineTabs<T>> with SingleTickerProviderStateMixin {
  late final AnimationController _x = AnimationController.unbounded(vsync: this, value: _index.toDouble());
  final _keys = <GlobalKey>[];
  final _row = GlobalKey();
  List<(double, double)> _spans = const [];

  int get _index => widget.tabs.indexWhere((t) => t.$1 == widget.value).clamp(0, widget.tabs.length - 1);

  @override
  void didUpdateWidget(GUnderlineTabs<T> old) {
    super.didUpdateWidget(old);
    final target = _index.toDouble();
    if (_x.value != target) {
      if (GMotion.reduced(context)) {
        _x.value = target;
      } else {
        _x.animateWith(SpringSimulation(GMotion.spring, _x.value, target, _x.velocity));
      }
    }
  }

  @override
  void dispose() {
    _x.dispose();
    super.dispose();
  }

  void _measure() {
    final box = _row.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final spans = <(double, double)>[];
    for (final k in _keys) {
      final b = k.currentContext?.findRenderObject() as RenderBox?;
      if (b == null) return;
      final left = b.localToGlobal(Offset.zero, ancestor: box).dx;
      spans.add((left, b.size.width));
    }
    if (spans.length == _spans.length && List.generate(spans.length, (i) => spans[i] == _spans[i]).every((e) => e)) return;
    setState(() => _spans = spans);
  }

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    while (_keys.length < widget.tabs.length) {
      _keys.add(GlobalKey());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measure();
    });
    final pill = _spans.length == widget.tabs.length
        ? AnimatedBuilder(
            animation: _x,
            builder: (context, _) {
              final v = _x.value.clamp(0, _spans.length - 1.0);
              final i = v.floor(), j = v.ceil();
              final t = v - i;
              final left = _spans[i].$1 + (_spans[j].$1 - _spans[i].$1) * t;
              final width = _spans[i].$2 + (_spans[j].$2 - _spans[i].$2) * t;
              return Transform.translate(
                offset: Offset(left, 0),
                child: Container(
                  width: width,
                  height: 38,
                  decoration: BoxDecoration(color: g.ink, borderRadius: BorderRadius.circular(19)),
                ),
              );
            },
          )
        : const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(GSpace.gutter, 8, GSpace.gutter, 8),
        child: Stack(
          key: _row,
          children: [
            Positioned(left: 0, top: 0, child: pill),
            Row(
              children: [
                for (var i = 0; i < widget.tabs.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  GPressable(
                    key: _keys[i],
                    haptic: false,
                    scale: .95,
                    selected: widget.tabs[i].$1 == widget.value,
                    semanticLabel: widget.tabs[i].$3 == null ? widget.tabs[i].$2 : '${widget.tabs[i].$2}, ${widget.tabs[i].$3}',
                    onTap: () {
                      if (widget.tabs[i].$1 == widget.value) return;
                      GHaptics.select();
                      widget.onChanged(widget.tabs[i].$1);
                    },
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(19),
                        color: _spans.length == widget.tabs.length || i != _index ? Colors.transparent : g.ink,
                      ),
                      child: Row(
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: GMotion.quick,
                            style: GType.label.c(i == _index ? g.onInk : g.ink2).w(i == _index ? FontWeight.w600 : FontWeight.w500).copyWith(fontSize: 14),
                            child: Text(widget.tabs[i].$2),
                          ),
                          if (widget.tabs[i].$3 != null && widget.tabs[i].$3! > 0) ...[
                            const SizedBox(width: 6),
                            AnimatedDefaultTextStyle(
                              duration: GMotion.quick,
                              style: GType.caption
                                  .c(i == _index ? g.onInk.withValues(alpha: .6) : g.ink3)
                                  .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                              child: Text('${widget.tabs[i].$3}'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A count row on the owner's dashboard: a coloured edge, a big figure, what
/// it counts, and a chevron. The edge colour says how urgent it is.
class GCountRow extends StatelessWidget {
  const GCountRow({super.key, required this.count, required this.label, required this.color, required this.onTap, this.grouped = false});

  /// Inside a group card: no edge or corners of its own.
  final bool grouped;

  final int count;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return GPressable(
      scale: .985,
      semanticLabel: '$count $label',
      onTap: onTap,
      child: Container(
        height: grouped ? 54 : 58,
        decoration: grouped ? null : GShape.fill(g.surface, GRadius.tile, side: BorderSide(color: g.rule)),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Container(width: 3.5, height: 30, decoration: GShape.fill(color, 2)),
            const SizedBox(width: 14),
            SizedBox(
              width: 34,
              child: Text('$count', style: GType.numeral.copyWith(fontSize: 24, color: count == 0 ? g.ink3 : g.ink)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.body.c(g.ink2)),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: g.ink4),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

/// A quiet pill for sorting a list ("Due ↑").
class GSortPill extends StatelessWidget {
  const GSortPill({super.key, required this.label, required this.onTap, this.up = true});

  final String label;
  final bool up;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return GPressable(
      scale: .95,
      semanticLabel: 'Sort by $label',
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: GShape.fill(g.surface, GRadius.pill, side: BorderSide(color: g.ruleStrong)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: GType.caption.c(g.ink2).w(FontWeight.w500)),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: up ? 0 : .5,
              duration: GMotion.of(context, GMotion.quick),
              curve: GMotion.spatial,
              child: Icon(LucideIcons.arrowUp, size: 14, color: g.ink2),
            ),
          ],
        ),
      ),
    );
  }
}

/// A round ink button for the one create action on a list screen.
class GFab extends StatelessWidget {
  const GFab({super.key, required this.onTap, required this.label, this.icon = LucideIcons.plus});

  final VoidCallback onTap;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return GPressable(
      scale: .9,
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: g.ink,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: g.shadow, blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Icon(icon, size: 24, color: g.onInk),
      ),
    );
  }
}
