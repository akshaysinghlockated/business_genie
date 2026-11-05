import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/palette.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/theme/type.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/input.dart';
import '../../../../core/widgets/overlays.dart';

/// Step 1 of sign-in: the work email.
class SignInEmailStep extends StatelessWidget {
  const SignInEmailStep({
    super.key,
    required this.emailController,
    required this.emailError,
    required this.isBusy,
    required this.onSendCode,
    required this.onEmailChanged,
    required this.onTryDemo,
  });

  final TextEditingController emailController;
  final String? emailError;
  final bool isBusy;
  final VoidCallback onSendCode;
  final VoidCallback onEmailChanged;
  final VoidCallback onTryDemo;

  @override
  Widget build(BuildContext context) {
    final palette = context.g;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sign in to\nBusiness Genie', style: GType.display.c(palette.ink)),
        const SizedBox(height: GSpace.s),
        Text('We’ll email you a 6-digit code. No password needed.', style: GType.body.c(palette.ink2)),
        const SizedBox(height: GSpace.xl),
        GInput(
          label: 'Work email',
          hint: 'you@company.com',
          controller: emailController,
          icon: LucideIcons.mail,
          error: emailError,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.go,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => onSendCode(),
          onChanged: (_) => onEmailChanged(),
        ),
        const SizedBox(height: GSpace.l),
        GButton(label: 'Send code', expand: true, height: 52, busy: isBusy, onTap: onSendCode),
        const SizedBox(height: GSpace.m),
        GButton(
          label: 'Continue with Google Workspace',
          icon: LucideIcons.building2,
          kind: GButtonKind.secondary,
          expand: true,
          height: 52,
          onTap: () => GToast.show(context, 'Google sign-in is coming to the app soon.', type: GToastType.info),
        ),
        const SizedBox(height: GSpace.s),
        Center(
          child: GTextAction(label: 'Try the demo', onTap: onTryDemo),
        ),
      ],
    );
  }
}
