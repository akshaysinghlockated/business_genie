import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/parts.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/states.dart';
import '../../data/app_state.dart';
import '../../data/companies.dart' show ownerPhoto;
import '../../data/models.dart';
import '../profile/profile_sheet.dart';

/// The frame every tab sits in: a 60 pt bar with the title (or [leading])
/// on the left and the actions and you on the right, all on
/// the 20 pt margin. Content sits on the warm page below.
class GTabPage extends StatelessWidget {
  const GTabPage({super.key, this.title, this.subtitle, this.leading, this.actions = const [], this.showMe = true, required this.child});

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  /// False when the page puts you on the left itself (Home).
  final bool showMe;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return ColoredBox(
      color: g.ground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: 60,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child:
                          leading ??
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GType.h1.c(g.ink).copyWith(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -.6),
                              ),
                              if (subtitle != null) Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.caption.c(g.ink3)),
                            ],
                          ),
                    ),
                    for (final a in actions) ...[a, const SizedBox(width: 8)],
                    if (showMe) const MeButton(),
                  ],
                ),
              ),
            ),
          ),
          // The bar above already took the status bar; lists below must not add it again.
          Expanded(
            child: MediaQuery.removePadding(context: context, removeTop: true, child: child),
          ),
        ],
      ),
    );
  }
}

/// You: your initials in an ink circle; opens your profile and settings.
class MeButton extends StatelessWidget {
  const MeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final name = context.app.data?.owner.name ?? 'Nikhil Bansal';
    return GPressable(
      scale: .9,
      semanticLabel: 'You, profile and settings',
      onTap: () => openProfile(context),
      child: GAvatar(name: name, size: 38, strong: true, photo: ownerPhoto),
    );
  }
}

/// Shows skeletons on the first load, a plain error with Try again when the
/// fetch failed, and the content once the snapshot is here. Refreshes after
/// that are quiet: the content stays on screen.
class GLoadView extends StatelessWidget {
  const GLoadView({super.key, required this.builder, this.skeleton});

  final Widget Function(BuildContext context, Snapshot data) builder;
  final Widget? skeleton;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final data = app.data;
    final Widget child;
    final String id;
    if (data != null) {
      child = builder(context, data);
      id = 'data-${app.mode.name}';
    } else if (app.error != null && !app.loading) {
      child = ListView(
        padding: const EdgeInsets.only(top: GSpace.xxl, bottom: GSpace.navClearance),
        children: [GErrorState(message: app.error!, onRetry: app.load)],
      );
      id = 'error';
    } else {
      child = ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: GSpace.l),
        children: [skeleton ?? const GSkeletonList(rows: 7)],
      );
      id = 'loading';
    }
    return AnimatedSwitcher(
      duration: GMotion.of(context, const Duration(milliseconds: 380)),
      switchInCurve: const Interval(.25, 1, curve: GMotion.sheet),
      switchOutCurve: const Interval(.5, 1),
      child: KeyedSubtree(key: ValueKey(id), child: child),
    );
  }
}

/// Pull to refresh that keeps the content on screen while it reloads.
class GRefresh extends StatelessWidget {
  const GRefresh({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return RefreshIndicator(
      color: g.ink,
      backgroundColor: g.surface,
      strokeWidth: 2,
      onRefresh: () async {
        GHaptics.select();
        await context.appRead.load();
      },
      child: child,
    );
  }
}

/// An inner page: a 56 pt bar with a back button and the title beside it,
/// actions on the right, then content on the warm page.
class GPushPage extends StatelessWidget {
  const GPushPage({super.key, required this.title, this.titleWidget, this.actions = const [], required this.child});

  final String title;
  final Widget? titleWidget;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Scaffold(
      backgroundColor: g.ground,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
                child: Row(
                  children: [
                    GPressable(
                      scale: .9,
                      semanticLabel: 'Back',
                      onTap: () => Navigator.of(context).pop(),
                      child: SizedBox.square(dimension: 40, child: Icon(LucideIcons.chevronLeft, size: 24, color: g.ink)),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child:
                          titleWidget ??
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GType.h2.c(g.ink).copyWith(fontSize: 19, fontWeight: FontWeight.w600),
                          ),
                    ),
                    for (final a in actions) ...[const SizedBox(width: 8), a],
                  ],
                ),
              ),
            ),
            Container(height: 1, color: g.rule),
            Expanded(
              child: MediaQuery.removePadding(context: context, removeTop: true, child: child),
            ),
          ],
        ),
      ),
    );
  }
}
