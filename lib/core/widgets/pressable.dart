import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// The base of every tap target. It eases down to [scale] while held, always
/// reaches the bottom on a quick tap so every press is seen, then springs back
/// with a hair of overshoot. A second tap within 380 ms is ignored, so a
/// double-tap can't open a screen twice. The haptic fires after [onTap], and
/// only when the handler didn't give one of its own.
class GPressable extends StatefulWidget {
  const GPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = .97,
    this.haptic = true,
    this.semanticLabel,
    this.selected,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;
  final String? semanticLabel;
  final bool? selected;
  final HitTestBehavior behavior;

  @override
  State<GPressable> createState() => _GPressableState();
}

class _GPressableState extends State<GPressable> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this, value: 1);
  DateTime _lastTap = DateTime(0);
  bool _down = false;

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _press() {
    if (!_enabled || GMotion.reduced(context)) return;
    _down = true;
    _c.animateTo(widget.scale, duration: GMotion.press, curve: GMotion.easeOut);
  }

  Future<void> _release() async {
    if (!_down) return;
    _down = false;
    if (_c.value > widget.scale + .002) {
      await _c.animateTo(widget.scale, duration: const Duration(milliseconds: 60), curve: GMotion.easeOut);
    }
    if (!mounted) return;
    _c.animateWith(SpringSimulation(GMotion.springFast, _c.value, 1, 0));
  }

  void _tap() {
    final now = DateTime.now();
    if (now.difference(_lastTap).inMilliseconds < 380) return;
    _lastTap = now;
    final before = GHaptics.count;
    widget.onTap?.call();
    if (widget.haptic && GHaptics.count == before) GHaptics.light();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: _enabled,
      label: widget.semanticLabel,
      selected: widget.selected,
      excludeSemantics: widget.semanticLabel != null,
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: _enabled ? (_) => _press() : null,
        onTapUp: _enabled ? (_) => _release() : null,
        onTapCancel: _enabled ? _release : null,
        onTap: widget.onTap == null ? null : _tap,
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                _release();
                GHaptics.heavy();
                widget.onLongPress!();
              },
        child: ScaleTransition(scale: _c, child: widget.child),
      ),
    );
  }
}
