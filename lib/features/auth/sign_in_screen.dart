import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/genie_mark.dart';
import '../../core/widgets/input.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/swap.dart';
import '../../data/app_state.dart';

/// Sign in with a work email and a 6-digit code sent by email (the way
/// Business Genie signs people in). In the demo any 6 digits work.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController(text: 'nikhil@kanris.in');
  final _code = TextEditingController();
  bool _codeStep = false;
  bool _busy = false;
  String? _emailError;
  bool _codeError = false;

  static final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final v = _email.text.trim();
    if (v.isEmpty || !_emailRe.hasMatch(v)) {
      setState(() => _emailError = v.isEmpty ? 'Enter your work email.' : 'That email doesn’t look right.');
      GHaptics.heavy();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _emailError = null;
      _busy = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _codeStep = true;
    });
  }

  Future<void> _verify(String code) async {
    if (code.length < 6) {
      setState(() => _codeError = true);
      GHaptics.heavy();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _codeError = false;
      _busy = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    GHaptics.heavy();
    context.appRead.signIn();
  }

  void _back() {
    setState(() {
      _codeStep = false;
      _code.clear();
      _codeError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Scaffold(
      backgroundColor: g.ground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: GSpace.xl),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: GSpace.l),
                    SizedBox(
                      height: 44,
                      child: AnimatedOpacity(
                        opacity: _codeStep ? 1 : 0,
                        duration: GMotion.quick,
                        child: IgnorePointer(
                          ignoring: !_codeStep,
                          child: GRoundButton(icon: LucideIcons.arrowLeft, label: 'Back', onTap: _back),
                        ),
                      ),
                    ),
                    const SizedBox(height: GSpace.xxl),
                    const GenieMark(size: 56),
                    const SizedBox(height: GSpace.xl),
                    GSwap(id: _codeStep, reverse: !_codeStep, child: _codeStep ? _codeView(g) : _emailView(g)),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: GSpace.l, top: GSpace.xl),
                      child: Text('By continuing you agree to the Terms and the Privacy Policy.', style: GType.caption.c(g.ink3)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailView(GPalette g) {
    return Column(
      key: const ValueKey('email'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sign in to\nBusiness Genie', style: GType.display.c(g.ink)),
        const SizedBox(height: GSpace.s),
        Text('We’ll email you a 6-digit code. No password needed.', style: GType.body.c(g.ink2)),
        const SizedBox(height: GSpace.xl),
        GInput(
          label: 'Work email',
          hint: 'you@company.com',
          controller: _email,
          icon: LucideIcons.mail,
          error: _emailError,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.go,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => _sendCode(),
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
        ),
        const SizedBox(height: GSpace.l),
        GButton(label: 'Send code', expand: true, height: 52, busy: _busy, onTap: _sendCode),
        const SizedBox(height: GSpace.m),
        GButton(
          label: 'Continue with Google Workspace',
          icon: LucideIcons.building2,
          kind: GButtonKind.secondary,
          expand: true,
          height: 52,
          onTap: () => GToast.show(context, 'Google sign-in is coming to the app soon.', type: GToastType.info),
        ),
      ],
    );
  }

  Widget _codeView(GPalette g) {
    return Column(
      key: const ValueKey('code'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Check your email', style: GType.display.c(g.ink)),
        const SizedBox(height: GSpace.s),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'We sent a code to '),
              TextSpan(text: _email.text.trim(), style: GType.body.c(g.ink).w(FontWeight.w600)),
              const TextSpan(text: '. It works for 10 minutes. Not there? Check spam.'),
            ],
          ),
          style: GType.body.c(g.ink2),
        ),
        const SizedBox(height: GSpace.xl),
        GCodeInput(controller: _code, error: _codeError, onCompleted: _verify),
        AnimatedSize(
          duration: GMotion.quick,
          child: _codeError
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Enter all 6 digits.', style: GType.caption.c(g.danger)),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: GSpace.l),
        GButton(label: 'Verify and sign in', expand: true, height: 52, busy: _busy, onTap: () => _verify(_code.text)),
        const SizedBox(height: GSpace.s),
        Center(
          child: GTextAction(
            label: 'Resend code',
            onTap: () => GToast.show(context, 'A new code is on its way.', type: GToastType.info),
          ),
        ),
        const SizedBox(height: GSpace.s),
        Center(child: Text('Demo: any 6 digits sign you in.', style: GType.caption.c(g.ink3))),
      ],
    );
  }
}
