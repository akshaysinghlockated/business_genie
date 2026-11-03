import 'package:flutter/material.dart';

import '../theme/palette.dart';
import '../theme/tokens.dart';
import '../theme/type.dart';
import 'brand.dart';
import 'pressable.dart';
import 'swap.dart';

enum GButtonKind { primary, secondary, quiet, danger, ai }

/// A pill button. One primary (ink) action per screen; every other control is
/// quiet. While [busy] the label fades through to a small spinner and the
/// button resizes smoothly instead of jumping.
class GButton extends StatelessWidget {
  const GButton({
    super.key,
    required this.label,
    this.onTap,
    this.kind = GButtonKind.primary,
    this.icon,
    this.busy = false,
    this.expand = false,
    this.height = 48,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onTap;
  final GButtonKind kind;
  final IconData? icon;
  final bool busy;
  final bool expand;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final (bg, fg, side) = switch (kind) {
      GButtonKind.primary => (g.ink, g.onInk, BorderSide.none),
      GButtonKind.secondary => (g.surface, g.ink, BorderSide(color: g.ruleStrong)),
      GButtonKind.quiet => (g.card, g.ink, BorderSide.none),
      GButtonKind.danger => (g.dangerSoft, g.danger, BorderSide.none),
      GButtonKind.ai => (g.ai, Colors.white, BorderSide.none),
    };
    final disabled = onTap == null && !busy;
    final h = compact ? 36.0 : height;
    final content = GSwap(
      id: busy ? 'busy' : label,
      alignment: Alignment.center,
      child: busy
          ? SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: compact ? 16 : 18, color: fg), const SizedBox(width: 8)],
                Flexible(
                  child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: (compact ? GType.caption : GType.label).c(fg).w(FontWeight.w600)),
                ),
              ],
            ),
    );
    return AnimatedOpacity(
      opacity: disabled ? .4 : 1,
      duration: GMotion.quick,
      child: GPressable(
        onTap: busy ? null : onTap,
        semanticLabel: label,
        child: AnimatedSize(
          duration: GMotion.of(context, GMotion.quick),
          curve: GMotion.easeOut,
          child: Container(
            height: h,
            width: expand ? double.infinity : null,
            padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 20),
            alignment: expand ? Alignment.center : null,
            decoration: GShape.fill(bg, GRadius.pill, side: side),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// A round button: a paper circle for close / back, or a solid ink circle for
/// the one main action.
class GRoundButton extends StatelessWidget {
  const GRoundButton({super.key, required this.icon, required this.onTap, required this.label, this.solid = false, this.size = 44, this.tint});

  final IconData icon;
  final VoidCallback? onTap;
  final String label;
  final bool solid;
  final double size;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return GPressable(
      onTap: onTap,
      scale: .92,
      semanticLabel: label,
      child: solid || tint != null
          ? Container(
              width: size,
              height: size,
              decoration: BoxDecoration(color: solid ? g.ink : tint, shape: BoxShape.circle),
              child: Icon(icon, size: size * .45, color: solid ? g.onInk : g.ink),
            )
          : GProtoGlass(
              circle: true,
              solid: true,
              child: SizedBox.square(
                dimension: size,
                child: Icon(icon, size: size * .45, color: g.ink),
              ),
            ),
    );
  }
}

/// A bare icon with a 44 pt target, for header actions.
class GIconButton extends StatelessWidget {
  const GIconButton({super.key, required this.icon, required this.onTap, required this.label, this.color, this.badge = false});

  final IconData icon;
  final VoidCallback? onTap;
  final String label;
  final Color? color;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return GPressable(
      onTap: onTap,
      scale: .9,
      semanticLabel: label,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: g.surface,
          shape: BoxShape.circle,
          border: Border.all(color: g.rule),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 17, color: color ?? g.ink),
            if (badge)
              Positioned(
                top: 8,
                right: 9,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: g.danger,
                    shape: BoxShape.circle,
                    border: Border.all(color: g.surface, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A quiet text action ("See all") with a full-height target.
class GTextAction extends StatelessWidget {
  const GTextAction({super.key, required this.label, required this.onTap, this.color});

  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GPressable(
      onTap: onTap,
      scale: .94,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Text(label, style: GType.label.c(color ?? context.g.ink2)),
      ),
    );
  }
}
