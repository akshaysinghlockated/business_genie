import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/genie_mark.dart';

/// The launch moment: the mark springs in from 0.55 scale out of a soft
/// blur, then the wordmark rises. About 1.4 s, and instant under reduced motion.
class GSplash extends StatefulWidget {
  const GSplash({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<GSplash> createState() => _GSplashState();
}

class _GSplashState extends State<GSplash> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (GMotion.reduced(context)) {
      _c.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
      return;
    }
    _c.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final mark = CurvedAnimation(
      parent: _c,
      curve: const Interval(0, .55, curve: GMotion.spatial),
    );
    final word = CurvedAnimation(
      parent: _c,
      curve: const Interval(.32, .8, curve: GMotion.easeOut),
    );
    return Scaffold(
      backgroundColor: g.ground,
      body: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: mark.value.clamp(0, 1),
                child: Transform(
                  transform: Matrix4.identity(),
                  child: Transform.scale(
                    scale: .55 + .45 * mark.value,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: ((1 - mark.value) * 14).clamp(0, 14), sigmaY: ((1 - mark.value) * 14).clamp(0, 14)),
                      child: const GenieMark(size: 88),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: GSpace.l),
              Opacity(
                opacity: word.value,
                child: Transform.translate(
                  offset: Offset(0, (1 - word.value) * 10),
                  child: Text('Business Genie', style: GType.title.c(g.ink).copyWith(fontSize: 15, letterSpacing: -.3)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
