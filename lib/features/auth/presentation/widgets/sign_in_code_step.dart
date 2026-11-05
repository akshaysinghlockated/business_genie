import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/palette.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/theme/type.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/input.dart';
import 'resend_code_button.dart';

/// Step 2 of sign-in: the six-digit code from the email.
class SignInCodeStep extends StatelessWidget {
  const SignInCodeStep({
    super.key,
    required this.codeController,
    required this.sentTo,
    required this.note,
    required this.codeError,
    required this.codeErrorCount,
    required this.isBusy,
    required this.secondsUntilResend,
    required this.onVerify,
    required this.onResend,
  });

  final TextEditingController codeController;
  final String sentTo;

  /// The backend's sentence about the code. Empty until it answers.
  final String note;
  final String? codeError;

  /// Goes up on every code error, which replays the shake.
  final int codeErrorCount;
  final bool isBusy;
  final int secondsUntilResend;
  final ValueChanged<String> onVerify;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final palette = context.g;
    final shouldShake = codeErrorCount > 0 && !MediaQuery.disableAnimationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Check your email', style: GType.display.c(palette.ink)),
        const SizedBox(height: GSpace.s),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'We sent a code to '),
              TextSpan(text: sentTo, style: GType.body.c(palette.ink).w(FontWeight.w600)),
              TextSpan(text: '. ${note.isEmpty ? 'It works for 10 minutes.' : note} Not there? Check spam.'),
            ],
          ),
          style: GType.body.c(palette.ink2),
        ),
        const SizedBox(height: GSpace.xl),
        GCodeInput(
          controller: codeController,
          error: codeError != null,
          onCompleted: onVerify,
        ).animate(key: ValueKey(codeErrorCount), autoPlay: shouldShake).shakeX(hz: 5, amount: 5, duration: 360.ms),
        AnimatedSize(
          duration: GMotion.quick,
          child: codeError == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(codeError!, style: GType.caption.c(palette.danger)),
                ),
        ),
        const SizedBox(height: GSpace.l),
        GButton(label: 'Verify and sign in', expand: true, height: 52, busy: isBusy, onTap: () => onVerify(codeController.text)),
        const SizedBox(height: GSpace.s),
        Center(
          child: ResendCodeButton(secondsUntilAllowed: secondsUntilResend, onResend: onResend),
        ),
      ],
    );
  }
}
