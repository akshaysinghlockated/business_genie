import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// Changes content in place with a fade-through: the old content leaves fast
/// (first third), then the new content fades in rising from 10 px lower and
/// 0.96 scale. Both are never fully visible together, so text never sits on
/// text. [reverse] drops the new content in from above (going back).
class GSwap extends StatelessWidget {
  const GSwap({super.key, required this.id, required this.child, this.reverse = false, this.duration, this.alignment = Alignment.centerLeft});

  final Object id;
  final Widget child;
  final bool reverse;
  final Duration? duration;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final current = ValueKey(id);
    return AnimatedSwitcher(
      duration: GMotion.of(context, duration ?? const Duration(milliseconds: 300)),
      layoutBuilder: (currentChild, previous) => Stack(alignment: alignment, children: [...previous, ?currentChild]),
      transitionBuilder: (child, animation) {
        if (child.key == current) {
          final a = CurvedAnimation(
            parent: animation,
            curve: const Interval(.33, 1, curve: GMotion.easeOut),
          );
          return AnimatedBuilder(
            animation: a,
            child: child,
            builder: (context, child) => Opacity(
              opacity: a.value,
              child: Transform.translate(
                offset: Offset(0, (1 - a.value) * (reverse ? -10 : 10)),
                child: Transform.scale(scale: .96 + .04 * a.value, alignment: alignment.resolve(TextDirection.ltr), child: child),
              ),
            ),
          );
        }
        // Outgoing: the animation runs 1 → 0; it is gone in the first third.
        final a = CurvedAnimation(parent: animation, curve: const Interval(.67, 1));
        return FadeTransition(opacity: a, child: child);
      },
      child: KeyedSubtree(key: current, child: child),
    );
  }
}

/// Changes content sideways, like turning a page: the new content slides in
/// from the side it lies on ([forward] means from the right) while the old
/// slides out the other way, both fading. For dates, weeks and steps.
class GSlide extends StatelessWidget {
  const GSlide({super.key, required this.id, required this.child, this.forward = true, this.alignment = Alignment.topLeft});

  final Object id;
  final Widget child;
  final bool forward;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final current = ValueKey(id);
    final dir = forward ? 1.0 : -1.0;
    return ClipRect(
      child: AnimatedSwitcher(
        duration: GMotion.of(context, const Duration(milliseconds: 340)),
        layoutBuilder: (currentChild, previous) => Stack(
          alignment: alignment,
          children: [
            // The outgoing page keeps its own height and is clipped,
            // never squeezed into the new one's.
            for (final p in previous) Positioned(left: 0, right: 0, top: 0, child: p),
            if (currentChild != null) SizedBox(width: double.infinity, child: currentChild),
          ],
        ),
        transitionBuilder: (child, animation) {
          final a = CurvedAnimation(parent: animation, curve: GMotion.easeOut, reverseCurve: Curves.easeIn);
          final incoming = child.key == current;
          return AnimatedBuilder(
            animation: a,
            child: child,
            builder: (context, child) {
              final t = 1 - a.value;
              return Opacity(
                opacity: a.value.clamp(0.0, 1.0),
                child: FractionalTranslation(translation: Offset((incoming ? dir : -dir) * .18 * t, 0), child: child),
              );
            },
          );
        },
        child: KeyedSubtree(key: current, child: child),
      ),
    );
  }
}
