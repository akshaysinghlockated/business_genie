import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/palette.dart';
import '../theme/tokens.dart';
import '../theme/type.dart';
import 'brand.dart';
import 'buttons.dart';
import 'parts.dart';
import 'pressable.dart';

/// Opens a bottom sheet in the house motion: in on the emphasised-decelerate
/// curve over 320 ms, out quicker. A light haptic marks the open.
Future<T?> showGSheet<T>(BuildContext context, {required WidgetBuilder builder, bool full = false}) {
  GHaptics.light();
  final reduced = GMotion.reduced(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.g.surface,
    barrierColor: context.g.scrim,
    elevation: 0,
    shape: const RoundedSuperellipseBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(GRadius.sheet))),
    clipBehavior: Clip.antiAlias,
    sheetAnimationStyle: reduced
        ? AnimationStyle.noAnimation
        : AnimationStyle(duration: GMotion.sheetIn, reverseDuration: GMotion.quick, curve: GMotion.sheet, reverseCurve: GMotion.easeOut),
    builder: (context) {
      final child = Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: builder(context),
      );
      if (!full) return child;
      return SizedBox(height: MediaQuery.sizeOf(context).height * .94, child: child);
    },
  );
}

/// The top of a sheet: a handle, a centred title and a round close button.
class GSheetHeader extends StatelessWidget {
  const GSheetHeader({super.key, required this.title, this.leading});

  final String title;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Padding(
      padding: const EdgeInsets.fromLTRB(GSpace.l, GSpace.s, GSpace.l, GSpace.s),
      child: Column(
        children: [
          Container(width: 38, height: 4, decoration: GShape.fill(g.ink4, 2)),
          const SizedBox(height: GSpace.s),
          SizedBox(
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (leading != null) Align(alignment: Alignment.centerLeft, child: leading),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 52),
                  child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.h3.c(g.ink)),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: GRoundButton(icon: LucideIcons.x, label: 'Close', size: 38, onTap: () => Navigator.of(context).maybePop()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum GToastType { success, info, warning, error }

/// One toast at a time, sitting above the floating bar. Tinted by type with a
/// matching icon and dark text (never black). Rises on the spatial curve,
/// leaves fast, and announces itself to screen readers.
abstract final class GToast {
  static OverlayEntry? _entry;
  static GlobalKey<_ToastViewState>? _key;

  static void show(BuildContext context, String message, {GToastType type = GToastType.success, String? action, VoidCallback? onAction}) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _remove();
    final key = GlobalKey<_ToastViewState>();
    final entry = OverlayEntry(
      builder: (_) => _ToastView(key: key, message: message, type: type, action: action, onAction: onAction, onDone: _remove),
    );
    _entry = entry;
    _key = key;
    overlay.insert(entry);
    GHaptics.light();
  }

  static void _remove() {
    _entry?.remove();
    _entry = null;
    _key = null;
  }

  /// Dismisses the toast that is showing, if any.
  static void hide() => _key?.currentState?.leave();
}

class _ToastView extends StatefulWidget {
  const _ToastView({super.key, required this.message, required this.type, this.action, this.onAction, required this.onDone});

  final String message;
  final GToastType type;
  final String? action;
  final VoidCallback? onAction;
  final VoidCallback onDone;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: GMotion.sheetIn, reverseDuration: const Duration(milliseconds: 200));
  Timer? _hold;
  bool _leaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.status == AnimationStatus.dismissed && !_leaving) {
      if (GMotion.reduced(context)) {
        _c.value = 1;
      } else {
        _c.forward();
      }
      _hold = Timer(const Duration(milliseconds: 3600), leave);
    }
  }

  Future<void> leave() async {
    if (_leaving) return;
    _leaving = true;
    _hold?.cancel();
    if (mounted) await _c.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _hold?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final (tone, icon) = switch (widget.type) {
      GToastType.success => (GTone.success, LucideIcons.check),
      GToastType.info => (GTone.accent, LucideIcons.info),
      GToastType.warning => (GTone.warning, LucideIcons.triangleAlert),
      GToastType.error => (GTone.danger, LucideIcons.circleAlert),
    };
    final (fg, _) = tone.colors(g);
    final top = MediaQuery.paddingOf(context).top + 8;
    final drop = CurvedAnimation(parent: _c, curve: GMotion.spatial, reverseCurve: Curves.easeIn);
    // The prototype's toast: a glass pill dropping in at the top, a round
    // mark on the left, one line of text.
    return Positioned(
      left: GSpace.m,
      right: GSpace.m,
      top: top,
      child: Center(
        child: AnimatedBuilder(
          animation: drop,
          builder: (context, child) => Opacity(
            opacity: _c.value.clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, (drop.value - 1) * 18),
              child: Transform.scale(scale: .9 + .1 * drop.value, child: child),
            ),
          ),
          child: Semantics(
            liveRegion: true,
            child: Material(
              type: MaterialType.transparency,
              child: GestureDetector(
                onTap: leave,
                onVerticalDragEnd: (_) => leave(),
                child: GProtoGlass(
                  solid: true,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(7, 7, 14, 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: widget.type == GToastType.success ? g.success : (widget.type == GToastType.info ? g.ink : fg),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 15, color: widget.type == GToastType.info ? g.ground : Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(widget.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: GType.label.c(g.ink).copyWith(fontSize: 13)),
                        ),
                        if (widget.action != null)
                          GPressable(
                            scale: .92,
                            semanticLabel: widget.action,
                            onTap: () {
                              widget.onAction?.call();
                              leave();
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                              child: Text(widget.action!, style: GType.label.c(g.accent).w(FontWeight.w600).copyWith(fontSize: 13)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Frosted glass for controls floating above content (the bar). Real blur,
/// a translucent fill, a bright hairline edge and one soft shadow outside.
class GGlass extends StatelessWidget {
  const GGlass({super.key, required this.child, this.radius = GRadius.pill, this.circle = false});

  final Widget child;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final shape = circle ? const CircleBorder() : GShape.of(radius);
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        shadows: [BoxShadow(color: g.shadow, blurRadius: 28, offset: const Offset(0, 10))],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: BackdropFilter.grouped(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: g.glass,
              shape: circle
                  ? CircleBorder(side: BorderSide(color: g.glassEdge, width: .8))
                  : GShape.of(radius, side: BorderSide(color: g.glassEdge, width: .8)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
