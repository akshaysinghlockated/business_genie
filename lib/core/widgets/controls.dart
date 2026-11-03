import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/palette.dart';
import '../theme/tokens.dart';
import '../theme/type.dart';
import 'pressable.dart';

/// A choice chip. Selected is a stone fill with a slightly darker edge and a
/// tick (the design review: selected is stone or grey, never black).
class GChip extends StatelessWidget {
  const GChip({super.key, required this.label, required this.selected, required this.onTap, this.icon, this.count});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return GPressable(
      onTap: () {
        GHaptics.select();
        onTap();
      },
      scale: .95,
      selected: selected,
      semanticLabel: count == null ? label : '$label, $count',
      child: AnimatedContainer(
        duration: GMotion.of(context, GMotion.quick),
        curve: GMotion.effects,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: GShape.fill(selected ? g.stone : g.surface, GRadius.pill, side: BorderSide(color: selected ? g.ruleStrong : g.rule)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: GMotion.of(context, GMotion.quick),
              curve: GMotion.easeOut,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(LucideIcons.check, size: 15, color: g.ink),
                    )
                  : (icon != null
                        ? Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(icon, size: 15, color: g.ink2),
                          )
                        : const SizedBox.shrink()),
            ),
            Text(label, style: GType.label.c(selected ? g.ink : g.ink2).w(selected ? FontWeight.w600 : FontWeight.w500)),
            if (count != null) ...[
              const SizedBox(width: 6),
              Text('$count', style: GType.caption.c(g.ink3).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
            ],
          ],
        ),
      ),
    );
  }
}

/// A horizontal row of chips that scrolls on narrow phones.
class GChipRow extends StatelessWidget {
  const GChipRow({super.key, required this.children, this.padding = const EdgeInsets.symmetric(horizontal: GSpace.gutter)});

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: 8), children[i]],
        ],
      ),
    );
  }
}

/// A segmented control: a grey track with a white thumb that slides (never
/// jumps) to the chosen option. Each change ticks once.
class GSegmented<T> extends StatelessWidget {
  const GSegmented({super.key, required this.options, required this.value, required this.onChanged, this.height = 40, this.radius = GRadius.pill});

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;

  /// Corner radius of the track; the thumb follows it.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final index = options.indexWhere((o) => o.$1 == value).clamp(0, options.length - 1);
    final n = options.length;
    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: GShape.fill(g.card, radius),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: GMotion.of(context, const Duration(milliseconds: 260)),
            curve: GMotion.spatial,
            alignment: Alignment(n == 1 ? 0 : -1 + 2 * index / (n - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: g.surface,
                  shape: GShape.of(radius == GRadius.pill ? radius : radius - 3, side: BorderSide(color: g.rule)),
                  shadows: [BoxShadow(color: g.shadow.withValues(alpha: .08), blurRadius: 6, offset: const Offset(0, 1))],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final o in options)
                Expanded(
                  child: GPressable(
                    haptic: false,
                    scale: .96,
                    selected: o.$1 == value,
                    semanticLabel: o.$2,
                    onTap: () {
                      if (o.$1 == value) return;
                      GHaptics.select();
                      onChanged(o.$1);
                    },
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: GMotion.quick,
                        style: GType.label.c(o.$1 == value ? g.ink : g.ink3).w(o.$1 == value ? FontWeight.w600 : FontWeight.w500),
                        child: FittedBox(fit: BoxFit.scaleDown, child: Text(o.$2, maxLines: 1)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A switch whose "on" is the brand blue. The whole switch presses and ticks.
class GSwitch extends StatelessWidget {
  const GSwitch({super.key, required this.value, required this.onChanged, required this.label});

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final d = GMotion.of(context, GMotion.quick);
    return Semantics(
      toggled: value,
      label: label,
      child: GPressable(
        haptic: false,
        scale: .94,
        onTap: () {
          GHaptics.select();
          onChanged(!value);
        },
        child: AnimatedContainer(
          duration: d,
          curve: GMotion.effects,
          width: 46,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: GShape.fill(value ? g.accent : g.ink4, GRadius.pill),
          child: AnimatedAlign(
            duration: d,
            curve: GMotion.spatial,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1))],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The search pill used at the top of every tab.
class GSearchPill extends StatelessWidget {
  const GSearchPill({super.key, required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return GPressable(
      onTap: onTap,
      scale: .98,
      semanticLabel: hint,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: GShape.fill(
          g.surface.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? .6 : 1),
          GRadius.pill,
          side: BorderSide(color: g.rule),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.search, size: 18, color: g.ink3),
            const SizedBox(width: 10),
            Expanded(
              child: Text(hint, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.body.c(g.ink3)),
            ),
          ],
        ),
      ),
    );
  }
}
