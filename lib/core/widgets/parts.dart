import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/palette.dart';
import '../theme/tokens.dart';
import '../theme/type.dart';
import 'pressable.dart';

/// Initials on a quiet disc. [strong] is the ink disc used for "you".
class GAvatar extends StatelessWidget {
  const GAvatar({super.key, required this.name, this.size = 36, this.strong = false, this.dot, this.square = false, this.photo});

  final String name;

  /// A picture to show instead of initials; initials stay underneath while
  /// it loads or if it fails.
  final String? photo;
  final double size;
  final bool strong;
  final Color? dot;
  final bool square;

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final initials = initialsOf(name);
    final bg = strong ? g.ink : g.stone;
    final fg = strong ? g.onInk : g.ink;
    return Semantics(
      label: name,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: square ? GShape.fill(bg, size * .28) : BoxDecoration(color: bg, shape: BoxShape.circle),
              child: initials.isEmpty
                  ? Icon(LucideIcons.user, size: size * .45, color: fg)
                  : Text(
                      initials,
                      style: GType.label.copyWith(fontSize: size * (initials.length > 1 ? .34 : .4), fontWeight: FontWeight.w600, color: fg, height: 1),
                    ),
            ),
            if (photo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(square ? size * .28 : size),
                child: Image.network(
                  photo!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  frameBuilder: (context, child, frame, sync) =>
                      AnimatedOpacity(opacity: frame == null && !sync ? 0 : 1, duration: const Duration(milliseconds: 250), child: child),
                ),
              ),
            if (dot != null)
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: size * .3,
                  height: size * .3,
                  decoration: BoxDecoration(
                    color: dot,
                    shape: BoxShape.circle,
                    border: Border.all(color: g.surface, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Overlapping avatars for a meeting's people.
class GAvatarStack extends StatelessWidget {
  const GAvatarStack({super.key, required this.names, this.size = 24, this.max = 3});

  final List<String> names;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final shown = names.take(max).toList();
    final extra = names.length - shown.length;
    final step = size * .82;
    final count = shown.length + (extra > 0 ? 1 : 0);
    return SizedBox(
      width: count == 0 ? 0 : step * (count - 1) + size,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: step * i,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: g.surface, width: 1.5),
                ),
                child: GAvatar(name: shown[i], size: size - 3),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: step * shown.length,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: g.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: g.surface, width: 1.5),
                ),
                child: Text('+$extra', style: GType.micro.c(g.ink2)),
              ),
            ),
        ],
      ),
    );
  }
}

enum GTone { neutral, success, warning, danger, ai, accent }

extension GToneColors on GTone {
  (Color, Color) colors(GPalette g) => switch (this) {
    GTone.neutral => (g.ink2, g.card),
    GTone.success => (g.success, g.successSoft),
    GTone.warning => (g.warning, g.warningSoft),
    GTone.danger => (g.danger, g.dangerSoft),
    GTone.ai => (g.ai, g.aiSoft),
    GTone.accent => (g.accent, g.accentSoft),
  };
}

/// Status as a small dot and a word on a soft tint.
class GStatusPill extends StatelessWidget {
  const GStatusPill({super.key, required this.label, required this.tone, this.icon});

  final String label;
  final GTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final (fg, _) = tone.colors(g);
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: GShape.fill(g.card, GRadius.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 12, color: fg)
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
          const SizedBox(width: 6),
          Text(label, style: GType.caption.c(g.ink2).w(FontWeight.w500)),
        ],
      ),
    );
  }
}

/// A small grey tag (a department, a team).
class GTag extends StatelessWidget {
  const GTag(this.label, {super.key, this.dot});

  final String label;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: GShape.fill(g.card, GRadius.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(label, style: GType.caption.c(g.ink2)),
        ],
      ),
    );
  }
}

/// A progress bar that grows to its value once when it first shows.
class GProgressBar extends StatelessWidget {
  const GProgressBar({super.key, required this.value, this.color, this.height = 4});

  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: g.ruleStrong,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0, 1)),
          duration: GMotion.of(context, const Duration(milliseconds: 700)),
          curve: GMotion.easeOut,
          builder: (context, v, _) => FractionallySizedBox(
            widthFactor: math.max(v, .015),
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(color: color ?? g.ink, borderRadius: BorderRadius.circular(height)),
            ),
          ),
        ),
      ),
    );
  }
}

/// A progress ring with the figure inside.
class GRing extends StatelessWidget {
  const GRing({super.key, required this.value, this.size = 64, this.stroke = 6, this.color, this.label, this.track, this.labelColor});

  final double value;
  final double size;
  final double stroke;
  final Color? color;
  final String? label;
  final Color? track;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1)),
        duration: GMotion.of(context, const Duration(milliseconds: 900)),
        curve: GMotion.easeOut,
        builder: (context, v, _) => CustomPaint(
          painter: _RingPainter(v, color ?? g.ink, track ?? g.ruleStrong, stroke),
          child: Center(
            child: Text(
              label ?? '${(value * 100).round()}%',
              style: GType.figure.copyWith(fontSize: size * .26, color: labelColor ?? g.ink, fontWeight: FontWeight.w600, letterSpacing: -.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v, this.color, this.track, this.stroke);

  final double v;
  final Color color, track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (size.shortestSide - stroke) / 2;
    final c = size.center(Offset.zero);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, p..color = track);
    if (v > 0) canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * v, false, p..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.v != v || old.color != color || old.track != track;
}

/// A section title with one quiet action on the right.
class GSectionHeader extends StatelessWidget {
  const GSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.xl, GSpace.gutter, GSpace.s),
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.h3.c(g.ink)),
          ),
          ?trailing,
          if (action != null && onAction != null)
            GPressable(
              onTap: onAction,
              scale: .94,
              semanticLabel: action,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(action!, style: GType.label.c(g.ink2)),
                    const SizedBox(width: 2),
                    Icon(LucideIcons.chevronRight, size: 16, color: g.ink3),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A white card with an 8 % ink hairline on the warm page; never a shadow.
class GCard extends StatelessWidget {
  const GCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(GSpace.l),
    this.color,
    this.radius = GRadius.card,
    this.semanticLabel,
    this.border = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;
  final double radius;
  final String? semanticLabel;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final box = Container(
      padding: padding,
      decoration: color == null && !border
          ? GShape.lifted(g.surface, radius)
          : GShape.fill(color ?? g.surface, radius, side: border ? BorderSide(color: g.rule) : BorderSide.none),
      child: child,
    );
    if (onTap == null) return box;
    return GPressable(onTap: onTap, scale: .98, semanticLabel: semanticLabel, child: box);
  }
}

/// A list row: leading, title + subtitle, trailing; same shape everywhere.
class GRow extends StatelessWidget {
  const GRow({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.danger = false,
    this.padding = const EdgeInsets.symmetric(horizontal: GSpace.gutter, vertical: 12),
    this.chevron = false,
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;
  final EdgeInsets padding;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final row = Padding(
      padding: padding,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 14)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.title.c(danger ? g.danger : g.ink).w(FontWeight.w500)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: GType.bodyS.c(g.ink3)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          if (chevron) ...[const SizedBox(width: 6), Icon(LucideIcons.chevronRight, size: 18, color: g.ink3)],
        ],
      ),
    );
    if (onTap == null) return row;
    return GPressable(onTap: onTap, scale: .985, semanticLabel: subtitle == null ? title : '$title, $subtitle', child: row);
  }
}

/// An icon on a soft rounded square, the leading mark of rows and tiles.
class GIconBox extends StatelessWidget {
  const GIconBox({super.key, required this.icon, this.tone = GTone.neutral, this.size = 36});

  final IconData icon;
  final GTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final (fg, bg) = tone == GTone.neutral ? (g.ink, g.card) : tone.colors(g);
    return Container(
      width: size,
      height: size,
      decoration: GShape.fill(bg, size * .32),
      child: Icon(icon, size: size * .5, color: fg),
    );
  }
}

/// A 1 px hairline.
class GRule extends StatelessWidget {
  const GRule({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: indent),
    child: Container(height: 1, color: context.g.rule),
  );
}
