import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';

/// A small red "Live" tag; red marks only what is happening now.
class LiveTag extends StatelessWidget {
  const LiveTag({super.key, this.label = 'Live'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: GShape.fill(g.dangerSoft, GRadius.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: g.danger, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label, style: GType.micro.c(g.danger)),
        ],
      ),
    );
  }
}
