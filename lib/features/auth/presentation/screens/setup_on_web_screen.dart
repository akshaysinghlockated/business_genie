import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/env.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/theme/type.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/genie_mark.dart';
import '../../../../core/widgets/overlays.dart';
import '../../../../data/app_state.dart';

/// Signed in, but the company isn't set up yet (GET /onboarding not done).
/// Set-up happens on the web; this screen says so and checks again.
class SetupOnWebScreen extends StatefulWidget {
  const SetupOnWebScreen({super.key});

  @override
  State<SetupOnWebScreen> createState() => _SetupOnWebScreenState();
}

class _SetupOnWebScreenState extends State<SetupOnWebScreen> {
  bool _isChecking = false;

  Future<void> _checkAgain() async {
    final session = context.sessionRead;
    setState(() => _isChecking = true);
    await session.refresh();
    if (!mounted) return;
    setState(() => _isChecking = false);
    if (session.isWorkspaceSetupPending) {
      GToast.show(context, 'Set-up isn’t finished yet. Finish it on the web, then check again.', type: GToastType.info);
    }
  }

  void _copyWebLink() {
    Clipboard.setData(ClipboardData(text: Env.webUrl));
    GToast.show(context, 'Web link copied', type: GToastType.info);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.g;
    final firstName = context.session.user?.firstName ?? '';
    return Scaffold(
      backgroundColor: palette.ground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: GSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: GSpace.l + 44 + GSpace.xxl),
              const GenieMark(size: 56),
              const SizedBox(height: GSpace.xl),
              Text(firstName.isEmpty ? 'Finish setting up\non the web' : 'Almost there,\n$firstName', style: GType.display.c(palette.ink)),
              const SizedBox(height: GSpace.s),
              Text(
                'Your company’s workspace isn’t set up yet. Finish the set-up on Business Genie on the web, then come back here.',
                style: GType.body.c(palette.ink2),
              ),
              const SizedBox(height: GSpace.xl),
              GButton(label: 'Copy web link', icon: LucideIcons.link, expand: true, height: 52, onTap: _copyWebLink),
              const SizedBox(height: GSpace.m),
              GButton(
                label: 'I’ve finished, check again',
                kind: GButtonKind.secondary,
                expand: true,
                height: 52,
                busy: _isChecking,
                onTap: _checkAgain,
              ),
              const Spacer(),
              Center(
                child: GTextAction(label: 'Sign out', onTap: () => context.sessionRead.signOut()),
              ),
              const SizedBox(height: GSpace.l),
            ],
          ),
        ),
      ),
    );
  }
}
