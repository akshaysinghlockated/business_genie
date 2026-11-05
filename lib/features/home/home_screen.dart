import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/parts.dart';
import '../../core/widgets/pressable.dart';
import '../../core/widgets/states.dart';
import '../../data/app_state.dart';
import '../../data/companies.dart';
import '../../data/models.dart';
import '../profile/profile_sheet.dart';
import '../shell/routes.dart';
import '../shell/shell.dart';
import '../shell/search_screen.dart';
import '../shell/tab_page.dart';
import '../news/news.dart';
import 'home_cards.dart';

const double _m = 20;

/// Home: the company header, then three swipeable views. Overview is the
/// owner's morning in one scroll; Decisions and Team are the full lists.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final data = context.app.data;
    final company = data?.company ?? 'Kanris';
    final unread = data?.unread ?? 0;
    final info = companies[context.app.company.clamp(0, companies.length - 1)];
    final top = MediaQuery.paddingOf(context).top;
    // The app bar scrolls away with the page; a ground-coloured strip keeps
    // content from showing under the status bar.
    final header = Padding(
      padding: EdgeInsets.fromLTRB(_m, top + 16, _m, 6),
      child: Column(
        children: [
          Row(
            children: [
              GPressable(
                scale: .92,
                semanticLabel: 'You, profile and settings',
                onTap: () => openProfile(context),
                child: GAvatar(name: data?.owner.name ?? 'Nikhil Bansal', size: 50, strong: true, photo: context.app.photo),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GPressable(
                  scale: .98,
                  semanticLabel: context.app.live ? 'Company: $company' : 'Company: $company, ${info.industry}. Switch company',
                  onTap: context.app.live ? null : () => _showCompanies(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              company,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GType.h3.c(g.ink).copyWith(fontSize: 18.5),
                            ),
                          ),
                          if (!context.app.live) ...[const SizedBox(width: 2), Icon(LucideIcons.chevronDown, size: 16, color: g.ink3)],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.app.industry,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GType.caption.c(g.ink3).copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (data != null && data.setupDone) ...[const SuggestButton(), const SizedBox(width: 8)],
              _Bell(unread: unread),
            ],
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
    return ColoredBox(
      color: g.ground,
      child: Stack(
        children: [
          MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: _Overview(header: header, onDecisions: () => openDecisions(context), onTeam: () => openPeople(context)),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: top,
            child: ColoredBox(color: g.ground),
          ),
        ],
      ),
    );
  }
}

class _Overview extends StatefulWidget {
  const _Overview({required this.header, required this.onDecisions, required this.onTeam});

  final Widget header;
  final VoidCallback onDecisions, onTeam;

  @override
  State<_Overview> createState() => _OverviewState();
}

class _OverviewState extends State<_Overview> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final app = context.app;
    final data = app.data;
    final now = DateTime.now();
    final List<Widget> body;
    if (data == null) {
      body = [
        if (app.error != null && !app.loading)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: GErrorState(message: app.error!, onRetry: app.load),
          )
        else
          const _Skeleton(),
      ];
    } else {
      var i = 0;
      body = [
        _Hello(name: data.owner.first, now: now),
        if (data.news.isNotEmpty) NewsTicker(news: data.news).materialize(delay: 20.ms),
        _Greeting(data: data, now: now),
        HomeHighlight(data: data, now: now).materialize(delay: 40.ms),
        for (final s in app.sections)
          if (!app.hidden.contains(s)) _section(s, data, now).materialize(delay: (100 + 50 * i++).ms),
      ];
    }
    return GRefresh(
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
        padding: const EdgeInsets.only(bottom: GSpace.navClearance),
        children: [widget.header, ...body],
      ),
    );
  }

  /// Every section always shows; with nothing in it, it shows its own
  /// empty state.
  Widget _section(HomeSection s, Snapshot data, DateTime now) => switch (s) {
    HomeSection.needs => NeedsCard(data: data, now: now),
    HomeSection.quick => const QuickActionsCard(),
    HomeSection.tasks => MyTasksCard(data: data),
    HomeSection.schedule => ScheduleCard(data: data, now: now),
    HomeSection.projects => ProjectsCard(data: data),
    HomeSection.goals => GoalsCard(data: data),
    HomeSection.team => TeamCard(data: data),
    HomeSection.trends => TrendsCard(data: data, now: now),
  };
}

/// Notifications: a bell with the unread count; opens the Inbox.
class _Bell extends StatelessWidget {
  const _Bell({required this.unread});

  final int unread;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return GPressable(
      scale: .9,
      semanticLabel: unread > 0 ? 'Notifications, $unread unread' : 'Notifications',
      onTap: () => shellKey.currentState?.goTab(Tabs.inbox),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: g.surface,
                shape: BoxShape.circle,
                border: Border.all(color: g.rule),
              ),
              child: Icon(LucideIcons.bell, size: 17, color: g.ink),
            ),
            if (unread > 0)
              Positioned(
                top: -2,
                right: -4,
                child: Container(
                  height: 20,
                  constraints: const BoxConstraints(minWidth: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: g.danger,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: g.ground, width: 2),
                  ),
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: GType.micro.c(Colors.white).copyWith(fontSize: 10, height: 1, letterSpacing: 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Good evening, Nikhil": one calm line under the app bar.
class _Hello extends StatelessWidget {
  const _Hello({required this.name, required this.now});

  final String name;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_m, 14, _m, 26),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${GFormat.greeting(now)},\n',
              style: TextStyle(color: g.ink3, fontWeight: FontWeight.w500),
            ),
            TextSpan(
              text: name,
              style: TextStyle(color: g.ink),
            ),
          ],
        ),
        style: GType.display.copyWith(fontSize: 28, height: 1.2),
      ),
    );
  }
}

/// Search, with Customise beside it: the first thing under the header.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.data, required this.now});

  final Snapshot data;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Padding(
      padding: const EdgeInsets.fromLTRB(_m, 0, _m, 20),
      child: Row(
        children: [
          Expanded(
            child: GPressable(
              scale: .98,
              semanticLabel: 'Search tasks, people, meetings',
              onTap: () => openSearch(context),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: g.surface,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.search, size: 18, color: g.ink3),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search tasks, people, meetings',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GType.body.c(g.ink3).copyWith(fontSize: 14.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (data.setupDone) ...[
            const SizedBox(width: 10),
            GPressable(
              scale: .92,
              semanticLabel: 'Customise home: choose and order the sections',
              onTap: () => _showCustomise(context),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: g.ink, shape: BoxShape.circle),
                child: Icon(LucideIcons.slidersHorizontal, size: 19, color: g.onInk),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return const GSkeletonPulse(
      child: Padding(
        padding: EdgeInsets.fromLTRB(_m, 18, _m, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GSkeleton(width: 120, height: 12),
            SizedBox(height: 18),
            GSkeleton(height: 210, radius: 28),
            SizedBox(height: 14),
            GSkeleton(height: 220, radius: 22),
            SizedBox(height: 14),
            GSkeleton(height: 140, radius: 22),
          ],
        ),
      ),
    );
  }
}

/// Customise home: switch sections on or off and drag them into your order.
void _showCustomise(BuildContext context) {
  showGSheet<void>(
    context,
    builder: (context) => ListenableBuilder(
      listenable: context.appRead,
      builder: (context, _) {
        final app = context.appRead;
        final g = context.g;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GSheetHeader(title: 'Customise home'),
            Padding(
              padding: const EdgeInsets.fromLTRB(_m, 0, _m, 8),
              child: Text(
                'The highlight always leads. Drag sections into the order you want, or switch one off.',
                style: GType.bodyS.c(g.ink3),
              ),
            ),
            ReorderableListView(
              shrinkWrap: true,
              buildDefaultDragHandles: false,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              onReorderItem: (from, to) {
                final list = [...app.sections];
                final s = list.removeAt(from);
                list.insert(to, s);
                GHaptics.select();
                app.setSections(list);
              },
              children: [
                for (var i = 0; i < app.sections.length; i++)
                  Container(
                    key: ValueKey(app.sections[i]),
                    color: g.surface,
                    padding: const EdgeInsets.fromLTRB(8, 4, _m, 4),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: i,
                          child: SizedBox(width: 44, height: 44, child: Icon(LucideIcons.gripVertical, size: 18, color: g.ink3)),
                        ),
                        Expanded(child: Text(app.sections[i].label, style: GType.label.c(g.ink).copyWith(fontSize: 14.5))),
                        GSwitch(
                          label: app.sections[i].label,
                          value: !app.hidden.contains(app.sections[i]),
                          onChanged: (v) => app.toggleSection(app.sections[i], v),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

/// The numbers over time: the last 30 days of work, revenue's 8-week line
/// and tasks done this week.
void _showCompanies(BuildContext context) {
  showGSheet<void>(
    context,
    builder: (sheet) {
      final g = sheet.g;
      final app = sheet.appRead;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GSheetHeader(title: 'Your companies'),
          for (var i = 0; i < companies.length; i++)
            GPressable(
              scale: .98,
              semanticLabel: companies[i].name,
              onTap: () {
                Navigator.of(sheet).pop();
                if (i != app.company) {
                  app.setCompany(i);
                  GToast.show(context, 'Opened ${companies[i].name}', type: GToastType.info);
                }
              },
              child: Container(
                margin: const EdgeInsets.fromLTRB(_m, 0, _m, 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: g.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: i == app.company ? g.ink : g.rule, width: i == app.company ? 1.5 : 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: i == app.company ? g.ink : g.card, borderRadius: BorderRadius.circular(13)),
                      child: Text(companies[i].initials, style: GType.label.c(i == app.company ? g.onInk : g.ink).w(FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(companies[i].name, style: GType.title.c(g.ink)),
                          Text('${companies[i].industry} · ${companies[i].city}', style: GType.caption.c(g.ink3)),
                          Text('${companies[i].role} · ${companies[i].people} people', style: GType.caption.c(g.ink2)),
                        ],
                      ),
                    ),
                    if (i == app.company) Icon(LucideIcons.circleCheck, size: 20, color: g.ink),
                  ],
                ),
              ),
            ),
          GPressable(
            scale: .98,
            semanticLabel: 'Join or create a company',
            onTap: () => showWebOnly(sheet, 'New company', LucideIcons.building2),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_m, 4, _m, 8),
              child: Row(
                children: [
                  Icon(LucideIcons.plus, size: 18, color: g.ink2),
                  const SizedBox(width: 10),
                  Text('Join or create a company', style: GType.label.c(g.ink2)),
                ],
              ),
            ),
          ),
          SizedBox(height: MediaQuery.paddingOf(sheet).bottom + 12),
        ],
      );
    },
  );
}

/// Level one: the five-second answer. One headline about the company and
/// three vitals, each opening where it is counted.
