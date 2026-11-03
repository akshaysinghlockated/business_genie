import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lucide_icons_flutter/lucide_icons_300.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/genie_mark.dart';
import '../../core/widgets/pressable.dart';
import '../../data/app_state.dart';
import '../explore/explore_screen.dart';
import '../genie/genie_panel.dart';
import '../home/home_screen.dart';
import '../inbox/inbox_screen.dart';
import '../milestone/milestone_screen.dart';
import '../tasks/task_view.dart';
import '../tasks/tasks_screen.dart';
import 'create_sheet.dart';

/// Reaches the shell from anywhere (to switch tab or open Genie).
final GlobalKey<ShellState> shellKey = GlobalKey<ShellState>();

/// The tabs. Create is not a tab: goTab(Tabs.create) opens its sheet.
abstract final class Tabs {
  static const today = 0, tasks = 1, create = 2, inbox = 3, explore = 4, milestone = 5;
}

/// The app's frame: four pages kept alive in a stack (hidden ones have their
/// tickers off), a frosted pill bar with a highlight that slides between
/// tabs, and above it the tab's own container (Genie on Home, the toolbar on
/// Tasks). Scrolling down folds the bar into a circle on the left and the
/// container takes the row. Genie opens full screen, revealed in a circle.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => ShellState();
}

class ShellState extends State<Shell> with SingleTickerProviderStateMixin {
  int _tab = Tabs.today;
  final Set<int> _built = {Tabs.today};
  final _genie = GlobalKey<GeniePanelState>();
  final _genieButton = GlobalKey();
  late final _window = AnimationController(vsync: this, duration: const Duration(milliseconds: 520), reverseDuration: const Duration(milliseconds: 360));
  late final _curve = CurvedAnimation(parent: _window, curve: Curves.easeInOutCubic, reverseCurve: Curves.easeInCubic);
  bool _genieBuilt = false;
  bool _genieOpen = false;
  Offset _origin = Offset.zero;

  /// True while the page scrolls down: the bar folds to a circle on the left
  /// and the tab's container takes the row.
  bool _min = false;

  @override
  void initState() {
    super.initState();
    // Build the other tabs once the first frame is up, so opening any of
    // them later is instant instead of a one-frame hitch.
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _built.addAll(const [Tabs.tasks, Tabs.inbox, Tabs.explore, Tabs.milestone]));
    });
  }

  @override
  void dispose() {
    _window.dispose();
    super.dispose();
  }

  void goTab(int i) {
    if (i == Tabs.create) {
      showCreateSheet(context);
      return;
    }
    if (i == _tab) return;
    GHaptics.select();
    setState(() {
      _tab = i;
      _min = false;
      _built.add(i);
    });
  }

  void openGenieWindow() {
    if (_genieOpen) return;
    GHaptics.light();
    FocusManager.instance.primaryFocus?.unfocus();
    final box = _genieButton.currentContext?.findRenderObject() as RenderBox?;
    final size = MediaQuery.sizeOf(context);
    _origin = box == null ? Offset(size.width - 48, size.height - 60) : box.localToGlobal(box.size.center(Offset.zero));
    setState(() {
      _genieBuilt = true;
      _genieOpen = true;
    });
    MediaQuery.disableAnimationsOf(context) ? _window.value = 1 : _window.forward();
  }

  void closeGenieWindow() {
    if (!_genieOpen) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _genieOpen = false);
    MediaQuery.disableAnimationsOf(context) ? _window.value = 0 : _window.reverse();
  }

  /// Opens Genie and, if given, asks [ask] straight away.
  void askGenie([String? ask]) {
    openGenieWindow();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 260), () => _genie.currentState?.ask(ask));
    });
  }

  Widget _page(int i) => switch (i) {
    Tabs.today => const HomeScreen(),
    Tabs.tasks => const TasksScreen(asTab: true),
    Tabs.inbox => const InboxScreen(asTab: true),
    Tabs.milestone => const MilestoneScreen(),
    _ => const ExploreScreen(),
  };

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical || n.depth > 2) return false;
    // Only tabs with their own container fold the bar.
    if (_tab != Tabs.today && _tab != Tabs.tasks) return false;
    if (n is ScrollUpdateNotification && n.dragDetails != null) {
      final d = n.scrollDelta ?? 0;
      if (d > 2 && !_min && n.metrics.pixels > 40) {
        setState(() => _min = true);
      } else if (d < -2 && _min) {
        setState(() => _min = false);
      }
    } else if (n is ScrollUpdateNotification && _min && n.metrics.pixels <= 0) {
      setState(() => _min = false);
    }
    return false;
  }

  /// The tab's own container: Genie on Home, the toolbar on Tasks.
  Widget? _accessory(bool wide) => switch (_tab) {
    Tabs.today => _GenieAccessory(key: _genieButton, wide: wide, onTap: openGenieWindow),
    Tabs.tasks => TasksToolbar(wide: wide),
    Tabs.inbox => _CornerButton(
      label: 'New',
      icon: Icon(LucideIcons.plus, size: 18, color: context.g.onInk),
      onTap: () => showInboxNew(context),
    ),
    Tabs.milestone when context.app.data?.milestone != null => _CornerButton(
      label: 'Insight',
      icon: GenieMark(size: 17, mono: context.g.onInk, dot: const Color(0xFF9B85FF)),
      onTap: () => showMilestoneInsight(context),
    ),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final size = MediaQuery.sizeOf(context);
    final barBottom = math.max(bottom - 12, 10.0);
    const side = 14.0, bar = 60.0;
    final pillWidth = size.width - side * 2;
    final accessory = _accessory(_min);
    final move = GMotion.of(context, const Duration(milliseconds: 480));
    return PopScope(
      canPop: _tab == Tabs.today && !_genieOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _genieOpen ? closeGenieWindow() : goTab(Tabs.today);
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: g.ground,
            // One shared backdrop for every frosted layer: cheaper, and no
            // blur flicker on Android while pages change underneath.
            body: BackdropGroup(
              child: Stack(
                children: [
                  NotificationListener<ScrollNotification>(
                    onNotification: _onScroll,
                    child: Stack(
                      children: [
                        for (final i in const [Tabs.today, Tabs.tasks, Tabs.inbox, Tabs.explore, Tabs.milestone])
                          _TabLayer(key: ValueKey(i), visible: _tab == i, child: _built.contains(i) ? _page(i) : const SizedBox.shrink()),
                      ],
                    ),
                  ),
                  // A soft fade so content dissolves under the floating bar.
                  AnimatedPositioned(
                    duration: move,
                    curve: GMotion.easeOut,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: bottom + (accessory != null && !_min ? 150 : 96),
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [g.ground.withValues(alpha: 0), g.ground.withValues(alpha: .85), g.ground],
                            stops: const [0, .55, 1],
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: move,
                    curve: GMotion.spatial,
                    left: _min ? side + bar + 10 : side,
                    right: side,
                    bottom: _min ? barBottom : barBottom + bar + 10,
                    height: _min ? bar : 50,
                    child: AnimatedBuilder(
                      animation: _curve,
                      builder: (context, child) => Opacity(opacity: (1 - _curve.value * 2).clamp(0.0, 1.0), child: child),
                      child: AnimatedSwitcher(
                        duration: GMotion.of(context, const Duration(milliseconds: 240)),
                        switchInCurve: GMotion.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, a) => FadeTransition(
                          opacity: a,
                          child: ScaleTransition(scale: Tween(begin: .92, end: 1.0).animate(a), alignment: Alignment.bottomCenter, child: child),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey('${accessory == null ? 'none' : _tab}'),
                          child: accessory == null ? const SizedBox.shrink() : (_min ? accessory : Center(child: accessory)),
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: move,
                    curve: GMotion.spatial,
                    left: _min ? side : (size.width - pillWidth) / 2,
                    bottom: barBottom,
                    width: _min ? bar : pillWidth,
                    height: bar,
                    child: _Pill(index: _tab, min: _min, full: pillWidth, onTap: goTab, onExpand: () => setState(() => _min = false)),
                  ),
                ],
              ),
            ),
          ),
          if (_genieBuilt)
            _GenieWindow(
              animation: _curve,
              open: _genieOpen,
              origin: _origin,
              panel: GeniePanel(key: _genie, onClose: closeGenieWindow),
            ),
        ],
      ),
    );
  }
}

/// Frosted glass: the page shows through, blurred, under a milky surface.
class _Frost extends StatelessWidget {
  const _Frost({required this.radius, required this.child});

  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter.grouped(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: g.surface.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: g.surface.withValues(alpha: .9)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The floating bar: Home, Tasks, Inbox, Explore on frosted glass. A soft
/// tile slides to the chosen tab, whose icon turns bold. Folded, it is a
/// circle holding just the current tab; a tap opens it again.
class _Pill extends StatelessWidget {
  const _Pill({required this.index, required this.min, required this.full, required this.onTap, required this.onExpand});

  final int index;
  final bool min;

  /// The open bar's width; each tab gets a quarter.
  final double full;
  final ValueChanged<int> onTap;
  final VoidCallback onExpand;

  static const pad = 5.0;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final unread = context.app.data?.unread ?? 0;
    final items = <(int, IconData, IconData, String)>[
      (Tabs.today, LucideIcons300.house, LucideIcons600.house, 'Home'),
      (Tabs.tasks, LucideIcons300.squareCheckBig, LucideIcons600.squareCheckBig, 'Tasks'),
      (Tabs.inbox, LucideIcons300.inbox, LucideIcons600.inbox, 'Inbox'),
      (Tabs.explore, LucideIcons300.layoutGrid, LucideIcons600.layoutGrid, 'Explore'),
      (Tabs.milestone, LucideIcons300.flag, LucideIcons600.flag, 'Milestone'),
    ];
    final at = items.indexWhere((it) => it.$1 == index).clamp(0, items.length - 1);
    final slot = (full - pad * 2) / items.length;
    final fade = GMotion.of(context, const Duration(milliseconds: 220));
    return _Frost(
      radius: 30,
      child: Stack(
        children: [
          IgnorePointer(
            ignoring: min,
            child: AnimatedOpacity(
              duration: fade,
              opacity: min ? 0 : 1,
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: full,
                maxWidth: full,
                child: Padding(
                  padding: const EdgeInsets.all(pad),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: GMotion.of(context, const Duration(milliseconds: 460)),
                        curve: GMotion.spatial,
                        left: slot * at + 3,
                        top: 3,
                        bottom: 3,
                        width: slot - 6,
                        // A stadium pill behind the chosen tab, wider than its icon.
                        child: Container(
                          decoration: BoxDecoration(color: g.ink.withValues(alpha: .09), borderRadius: BorderRadius.circular(999)),
                        ),
                      ),
                      Row(
                        children: [
                          for (final it in items)
                            GPressable(
                              scale: .86,
                              haptic: false,
                              selected: it.$1 == index,
                              semanticLabel: it.$1 == Tabs.inbox && unread > 0 ? 'Inbox, $unread unread' : it.$4,
                              onTap: () => onTap(it.$1),
                              child: SizedBox(
                                width: slot,
                                height: 60 - pad * 2,
                                child: Center(
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Icon(it.$1 == index ? it.$3 : it.$2, size: 21, color: it.$1 == index ? g.ink : g.ink2),
                                      if (it.$1 == Tabs.inbox && unread > 0)
                                        Positioned(
                                          bottom: -2,
                                          right: -3,
                                          child: Container(
                                            width: 9,
                                            height: 9,
                                            decoration: BoxDecoration(
                                              color: g.danger,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: g.surface, width: 1.5),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            ignoring: !min,
            child: AnimatedOpacity(
              duration: fade,
              opacity: min ? 1 : 0,
              child: GPressable(
                scale: .88,
                semanticLabel: 'Show tabs, now on ${items[at].$4}',
                onTap: onExpand,
                child: Center(child: Icon(items[at].$3, size: 21, color: g.ink)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Genie on Home: a small ink "Ask Genie" above the bar; when the bar folds
/// it widens into a full ask bar in the bar's row.
class _GenieAccessory extends StatelessWidget {
  const _GenieAccessory({super.key, required this.wide, required this.onTap});

  final bool wide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final d = GMotion.of(context, const Duration(milliseconds: 360));
    return GPressable(
      scale: .95,
      semanticLabel: 'Ask Genie',
      onTap: onTap,
      child: AnimatedContainer(
        duration: d,
        curve: GMotion.easeOut,
        height: wide ? 60 : 40,
        padding: EdgeInsets.fromLTRB(wide ? 8 : 10, 0, wide ? 8 : 15, 0),
        decoration: BoxDecoration(
          color: g.ink,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .16), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Row(
          mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: d,
              curve: GMotion.easeOut,
              width: wide ? 44 : 22,
              height: wide ? 44 : 22,
              decoration: BoxDecoration(
                color: g.onInk.withValues(alpha: wide ? .1 : 0),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: GenieMark(size: wide ? 20 : 17, mono: g.onInk, dot: const Color(0xFF9B85FF)),
              ),
            ),
            SizedBox(width: wide ? 10 : 7),
            if (wide)
              Expanded(
                child: Text('Ask Genie anything', maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.body.c(g.onInk.withValues(alpha: .6))),
              )
            else
              Text('Ask Genie', style: GType.label.c(g.onInk).w(FontWeight.w600).copyWith(fontSize: 13.5)),
            if (wide)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: g.onInk, shape: BoxShape.circle),
                child: Icon(LucideIcons.audioLines, size: 19, color: g.ink),
              ),
          ],
        ),
      ),
    );
  }
}

/// Genie full screen, revealed as a circle that grows out of its button and
/// shrinks back into it on close.
class _GenieWindow extends StatelessWidget {
  const _GenieWindow({required this.animation, required this.open, required this.origin, required this.panel});

  final Animation<double> animation;
  final bool open;
  final Offset origin;
  final Widget panel;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final size = MediaQuery.sizeOf(context);
    final far = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((c) => (c - origin).distance).reduce(math.max);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final v = animation.value;
        return IgnorePointer(
          ignoring: !open,
          child: Offstage(
            offstage: v == 0 && !open,
            child: ClipPath(
              clipper: _Circle(origin, 33 + (far - 33) * v),
              child: Opacity(opacity: (v * 3).clamp(0.0, 1.0), child: child),
            ),
          ),
        );
      },
      child: Material(color: g.ground, child: panel),
    );
  }
}

class _Circle extends CustomClipper<Path> {
  _Circle(this.center, this.radius);

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) => Path()..addOval(Rect.fromCircle(center: center, radius: radius));

  @override
  bool shouldReclip(_Circle old) => old.radius != radius || old.center != center;
}

/// One tab's page. Coming in it fades up over 180 ms; going out it fades and
/// then leaves the tree's paint and tickers, so hidden tabs cost nothing.
class _TabLayer extends StatefulWidget {
  const _TabLayer({super.key, required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  State<_TabLayer> createState() => _TabLayerState();
}

class _TabLayerState extends State<_TabLayer> {
  late bool _shown = widget.visible;

  @override
  void didUpdateWidget(_TabLayer old) {
    super.didUpdateWidget(old);
    if (widget.visible) _shown = true;
  }

  @override
  Widget build(BuildContext context) {
    // The fade runs outside TickerMode: a muted ticker would freeze the
    // fade-out and leave the old page painted on top.
    return Offstage(
      offstage: !_shown,
      child: IgnorePointer(
        ignoring: !widget.visible,
        child: AnimatedOpacity(
          duration: GMotion.of(context, const Duration(milliseconds: 180)),
          curve: Curves.easeOut,
          opacity: widget.visible ? 1 : 0,
          onEnd: () {
            if (!widget.visible && _shown) setState(() => _shown = false);
          },
          child: TickerMode(
            enabled: widget.visible,
            child: RepaintBoundary(child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// A floating pill on the right, just above the bar: Inbox's New and the
/// Milestone's Insight.
class _CornerButton extends StatelessWidget {
  const _CornerButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Align(
      alignment: Alignment.centerRight,
      child: GPressable(
        scale: .93,
        semanticLabel: label,
        onTap: onTap,
        child: Container(
          height: 50,
          padding: const EdgeInsets.fromLTRB(16, 0, 20, 0),
          decoration: BoxDecoration(
            color: g.ink,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .18), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 8),
              Text(label, style: GType.label.c(g.onInk).w(FontWeight.w600).copyWith(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
