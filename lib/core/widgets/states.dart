import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/palette.dart';
import '../theme/tokens.dart';
import '../theme/type.dart';
import 'buttons.dart';

/// One controller pulses every skeleton under it (opacity only). Holds still
/// under reduced motion.
class GSkeletonPulse extends StatefulWidget {
  const GSkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<GSkeletonPulse> createState() => _GSkeletonPulseState();
}

class _GSkeletonPulseState extends State<GSkeletonPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100), lowerBound: .45, upperBound: 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (GMotion.reduced(context)) {
      _c.stop();
      _c.value = .8;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _c, child: widget.child);
}

/// A grey block shaped like the content that will replace it.
class GSkeleton extends StatelessWidget {
  const GSkeleton({super.key, this.width, required this.height, this.radius = 10});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(width: width, height: height, decoration: GShape.fill(context.g.card, radius));
}

/// Skeleton rows for a list: an icon, a long line and a short line each.
class GSkeletonList extends StatelessWidget {
  const GSkeletonList({super.key, this.rows = 5});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return GSkeletonPulse(
      child: Column(
        children: [
          for (var i = 0; i < rows; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: GSpace.gutter, vertical: 12),
              child: Row(
                children: [
                  const GSkeleton(width: 36, height: 36, radius: 12),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FractionallySizedBox(widthFactor: i.isEven ? .75 : .55, child: const GSkeleton(height: 14)),
                        const SizedBox(height: 8),
                        FractionallySizedBox(widthFactor: i.isEven ? .4 : .5, child: const GSkeleton(height: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// An honest empty state: what will appear here, and one action.
class GEmptyState extends StatelessWidget {
  const GEmptyState({super.key, required this.icon, required this.title, required this.body, this.action, this.onAction, this.compact = false});

  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: GSpace.xxl, vertical: compact ? GSpace.xl : GSpace.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 56 : 72,
            height: compact ? 56 : 72,
            decoration: GShape.fill(g.card, 24),
            child: Icon(icon, size: compact ? 24 : 30, color: g.ink3),
          ),
          const SizedBox(height: GSpace.l),
          Text(title, textAlign: TextAlign.center, style: GType.h3.c(g.ink)),
          const SizedBox(height: 6),
          Text(body, textAlign: TextAlign.center, style: GType.bodyS.c(g.ink2)),
          if (action != null && onAction != null) ...[
            const SizedBox(height: GSpace.l),
            GButton(label: action!, onTap: onAction, kind: GButtonKind.secondary, compact: true),
          ],
        ],
      ),
    );
  }
}

/// Something that fetched and failed: plain words and one Try again.
class GErrorState extends StatelessWidget {
  const GErrorState({super.key, required this.message, required this.onRetry, this.busy = false});

  final String message;
  final VoidCallback onRetry;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GSpace.xxl, vertical: GSpace.xxxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: GShape.fill(g.dangerSoft, 24),
            child: Icon(LucideIcons.cloudOff, size: 30, color: g.danger),
          ),
          const SizedBox(height: GSpace.l),
          Text('This didn’t load', textAlign: TextAlign.center, style: GType.h3.c(g.ink)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: GType.bodyS.c(g.ink2)),
          const SizedBox(height: GSpace.l),
          GButton(label: 'Try again', icon: LucideIcons.rotateCcw, busy: busy, onTap: onRetry, compact: true),
        ],
      ),
    );
  }
}
