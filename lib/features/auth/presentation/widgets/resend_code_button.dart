import 'package:flutter/material.dart';

import '../../../../core/theme/palette.dart';
import '../../../../core/theme/type.dart';
import '../../../../core/widgets/buttons.dart';

/// "Resend code", or the time left until it can be asked for again.
class ResendCodeButton extends StatelessWidget {
  const ResendCodeButton({super.key, required this.secondsUntilAllowed, required this.onResend});

  final int secondsUntilAllowed;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    if (secondsUntilAllowed <= 0) return GTextAction(label: 'Resend code', onTap: onResend);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text('Resend code in ${_asClock(secondsUntilAllowed)}', style: GType.label.c(context.g.ink3)),
    );
  }

  static String _asClock(int seconds) => '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
