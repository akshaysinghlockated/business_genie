import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/env.dart';
import '../../../../core/theme/palette.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/theme/type.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/overlays.dart';

/// Shown when sign-in is asked for an email with no account. The app never
/// signs anyone up: that happens on the web, or by invitation.
void showNoAccountSheet(BuildContext context) {
  showGSheet<void>(context, builder: (_) => const _NoAccountSheet());
}

class _NoAccountSheet extends StatelessWidget {
  const _NoAccountSheet();

  @override
  Widget build(BuildContext context) {
    final palette = context.g;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(GSpace.xl, GSpace.s, GSpace.xl, GSpace.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 38, height: 4, decoration: GShape.fill(palette.ink4, 2)),
            const SizedBox(height: GSpace.xl),
            Text('No account for this email yet', textAlign: TextAlign.center, style: GType.h2.c(palette.ink)),
            const SizedBox(height: GSpace.s),
            Text(
              'Create your company’s workspace on Business Genie on the web, or ask your company to invite you. Then sign in here.',
              textAlign: TextAlign.center,
              style: GType.body.c(palette.ink2),
            ),
            const SizedBox(height: GSpace.xl),
            GButton(label: 'Copy sign-up link', icon: LucideIcons.link, expand: true, onTap: () => _copySignUpLink(context)),
            const SizedBox(height: GSpace.s),
            GButton(label: 'Use another email', kind: GButtonKind.quiet, expand: true, onTap: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }

  void _copySignUpLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: Env.signUpUrl));
    Navigator.of(context).pop();
    GToast.show(context, 'Sign-up link copied', type: GToastType.info);
  }
}
