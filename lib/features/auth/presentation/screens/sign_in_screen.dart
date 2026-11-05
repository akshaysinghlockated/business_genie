import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/theme/type.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/genie_mark.dart';
import '../../../../core/widgets/overlays.dart';
import '../../../../core/widgets/swap.dart';
import '../../../../data/app_state.dart';
import '../widgets/no_account_sheet.dart';
import '../widgets/sign_in_code_step.dart';
import '../widgets/sign_in_email_step.dart';

/// Sign in with a work email and a six-digit code sent by email
/// (POST /auth/login, then POST /auth/login/verify). A code works for 10
/// minutes, three wrong tries end it, and a new one can be asked for once a
/// minute. "Try the demo" opens the sample company without any network.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static const _resendWaitSeconds = 60;
  static const _maxWrongCodes = 3;

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isCodeStep = false;
  bool _isBusy = false;
  String? _emailError;
  String? _codeError;
  String _sentTo = '';
  String _codeNote = '';
  int _wrongCodeCount = 0;
  int _codeErrorCount = 0;
  int _secondsUntilResend = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    final session = context.sessionRead;
    session.lastSignedInEmail().then((email) {
      if (mounted && email != null && _emailController.text.isEmpty) _emailController.text = email;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notice = session.takeSignInNotice();
      if (notice != null && mounted) GToast.show(context, notice, type: GToastType.info);
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // ---- Step 1: email ----

  Future<void> _sendCode() async {
    if (_isBusy) return;
    final email = _emailController.text.trim();
    final emailProblem = _validateEmail(email);
    if (emailProblem != null) {
      setState(() => _emailError = emailProblem);
      GHaptics.heavy();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _emailError = null;
      _isBusy = true;
    });
    try {
      final codeRequest = await context.sessionRead.requestCode(email);
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _isCodeStep = true;
        _sentTo = codeRequest.sentTo;
        _codeNote = codeRequest.note;
        _wrongCodeCount = 0;
        _codeError = null;
        _codeController.clear();
      });
      _startResendWait();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      GHaptics.heavy();
      if (error.isNoAccount) {
        showNoAccountSheet(context);
        return;
      }
      setState(() => _emailError = error.message);
      if (error.isRateLimited) _startResendWait();
    }
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) return 'Enter your work email.';
    if (!_emailPattern.hasMatch(email)) return 'That email doesn’t look right.';
    if (_secondsUntilResend > 0) return 'Wait $_secondsUntilResend s before asking for a new code.';
    return null;
  }

  // ---- Step 2: code ----

  Future<void> _verifyCode(String code) async {
    if (_isBusy) return;
    if (code.length < 6) {
      _showCodeError('Enter all 6 digits.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _codeError = null;
      _isBusy = true;
    });
    try {
      await context.sessionRead.verifyCode(email: _emailController.text, code: code);
      GHaptics.heavy();
      // The app's root moves on to the next screen by itself.
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      if (error.isInvalidInput || error.isUnauthorized) _wrongCodeCount++;
      if (_wrongCodeCount >= _maxWrongCodes) {
        _backToEmail();
        setState(() => _emailError = 'That code has ended after three tries. Ask for a new code.');
        GHaptics.heavy();
        return;
      }
      _showCodeError(error.message);
    }
  }

  Future<void> _resendCode() async {
    if (_isBusy || _secondsUntilResend > 0) return;
    setState(() => _isBusy = true);
    try {
      final codeRequest = await context.sessionRead.requestCode(_emailController.text);
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _sentTo = codeRequest.sentTo;
        _wrongCodeCount = 0;
        _codeError = null;
        _codeController.clear();
      });
      _startResendWait();
      GToast.show(context, 'A new code is on its way.', type: GToastType.info);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      if (error.isRateLimited) _startResendWait();
      GToast.show(context, error.message, type: GToastType.warning);
    }
  }

  void _showCodeError(String message) {
    _codeController.clear();
    setState(() {
      _codeError = message;
      _codeErrorCount++;
    });
    GHaptics.heavy();
  }

  void _backToEmail() {
    setState(() {
      _isCodeStep = false;
      _codeController.clear();
      _codeError = null;
    });
  }

  void _startResendWait() {
    _resendTimer?.cancel();
    setState(() => _secondsUntilResend = _resendWaitSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _secondsUntilResend = (_secondsUntilResend - 1).clamp(0, _resendWaitSeconds));
      if (_secondsUntilResend == 0) timer.cancel();
    });
  }

  // ---- Layout ----

  @override
  Widget build(BuildContext context) {
    final palette = context.g;
    return Scaffold(
      backgroundColor: palette.ground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: GSpace.xl),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: GSpace.l),
                    _BackButton(isVisible: _isCodeStep, onTap: _backToEmail),
                    const SizedBox(height: GSpace.xxl),
                    const GenieMark(size: 56),
                    const SizedBox(height: GSpace.xl),
                    GSwap(id: _isCodeStep, reverse: !_isCodeStep, child: _isCodeStep ? _buildCodeStep() : _buildEmailStep()),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: GSpace.l, top: GSpace.xl),
                      child: Text('By continuing you agree to the Terms and the Privacy Policy.', style: GType.caption.c(palette.ink3)),
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

  Widget _buildEmailStep() => SignInEmailStep(
    key: const ValueKey('email-step'),
    emailController: _emailController,
    emailError: _emailError,
    isBusy: _isBusy,
    onSendCode: _sendCode,
    onEmailChanged: () {
      if (_emailError != null) setState(() => _emailError = null);
    },
    onTryDemo: () => context.sessionRead.startDemo(),
  );

  Widget _buildCodeStep() => SignInCodeStep(
    key: const ValueKey('code-step'),
    codeController: _codeController,
    sentTo: _sentTo.isEmpty ? _emailController.text.trim() : _sentTo,
    note: _codeNote,
    codeError: _codeError,
    codeErrorCount: _codeErrorCount,
    isBusy: _isBusy,
    secondsUntilResend: _secondsUntilResend,
    onVerify: _verifyCode,
    onResend: _resendCode,
  );
}

/// Back to the email step; hidden (but keeping its space) on the email step.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.isVisible, required this.onTap});

  final bool isVisible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: AnimatedOpacity(
        opacity: isVisible ? 1 : 0,
        duration: GMotion.quick,
        child: IgnorePointer(
          ignoring: !isVisible,
          child: GRoundButton(icon: LucideIcons.arrowLeft, label: 'Back', onTap: onTap),
        ),
      ),
    );
  }
}
