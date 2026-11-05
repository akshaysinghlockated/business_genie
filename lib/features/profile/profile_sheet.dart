import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/genie_mark.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/parts.dart';
import '../../core/widgets/pressable.dart';
import '../../data/app_state.dart';
import '../../data/companies.dart';
import '../../data/models.dart';
import '../shell/routes.dart';

/// You, full screen: who you are, two quick switches (away, do not
/// disturb), your week in numbers, your companies, then display, demo data
/// and account settings.
void openProfile(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _away = false, _dnd = false;

  static const _m = 20.0;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final app = context.app;
    final data = app.data;
    final owner = data?.owner;
    final name = owner?.name ?? 'Nikhil Bansal';
    final info = companies[app.company.clamp(0, companies.length - 1)];
    final weekDone = data?.doneThisWeek.fold(0, (a, b) => a + b) ?? 0;
    final decided = data?.decisions.where((d) => d.picked != null).length ?? 0;
    final meetings = data?.meetings.where((m) => !m.cancelled).length ?? 0;
    return Scaffold(
      backgroundColor: g.ground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 60,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _TopButton(icon: LucideIcons.chevronLeft, label: 'Back', onTap: () => Navigator.of(context).pop()),
                    Expanded(
                      child: Center(child: Text('Account', style: GType.h3.c(g.ink))),
                    ),
                    _TopButton(
                      icon: LucideIcons.pencil,
                      label: 'Edit profile',
                      onTap: () => showWebOnly(context, 'Profile', LucideIcons.pencil),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(_m, 12, _m, MediaQuery.paddingOf(context).bottom + 40),
                children: [
                  // Who you are.
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GAvatar(name: name, size: 104, strong: true, photo: app.photo),
                        Positioned(
                          right: 2,
                          bottom: 4,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _dnd ? g.danger : (_away ? g.warning : g.success),
                              shape: BoxShape.circle,
                              border: Border.all(color: g.ground, width: 3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: GPressable(
                      scale: .97,
                      semanticLabel: 'Edit profile',
                      onTap: () => showWebOnly(context, 'Profile', LucideIcons.pencil),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(name, style: GType.h1.c(g.ink).copyWith(fontSize: 24)),
                          const SizedBox(width: 4),
                          Icon(LucideIcons.chevronRight, size: 20, color: g.ink3),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(child: Text(owner?.email ?? 'nikhil@kanris.in', style: GType.body.c(g.ink3))),
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: g.card, borderRadius: BorderRadius.circular(14)),
                      child: Text(
                        '${owner?.role ?? info.role} · ${data?.company ?? info.name}',
                        style: GType.caption.c(g.ink2).w(FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick switches.
                  Row(
                    children: [
                      Expanded(
                        child: _Toggle(
                          icon: LucideIcons.calendarOff,
                          label: 'Out of office',
                          on: _away,
                          onTap: () {
                            setState(() => _away = !_away);
                            GToast.show(context, _away ? 'You’re marked out of office' : 'Welcome back', type: GToastType.info);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Toggle(
                          icon: _dnd ? LucideIcons.bellOff : LucideIcons.bell,
                          label: 'Do not disturb',
                          on: _dnd,
                          onTap: () {
                            setState(() => _dnd = !_dnd);
                            GToast.show(context, _dnd ? 'Notifications paused' : 'Notifications on', type: GToastType.info);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Your week, with Genie.
                  if (data != null && data.setupDone)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C5CFF), Color(0xFF3579D7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), shape: BoxShape.circle),
                                child: const Center(
                                  child: GenieMark(size: 18, mono: Colors.white, dot: Color(0xFFFFD66B)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text('Your week so far', style: GType.title.c(Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              _WeekStat(value: '$weekDone', label: 'Tasks done'),
                              _WeekStat(value: '$meetings', label: 'Meetings'),
                              _WeekStat(value: '$decided', label: 'Decisions made'),
                            ],
                          ),
                          const SizedBox(height: 18),
                          GPressable(
                            scale: .97,
                            semanticLabel: 'Ask Genie for a weekly review',
                            onTap: () {
                              final nav = Navigator.of(context);
                              nav.pop();
                              openGenie(nav.context, ask: 'Brief me on my week');
                            },
                            child: Container(
                              height: 42,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(21)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Review my week with Genie', style: GType.label.c(const Color(0xFF4B3BCB)).w(FontWeight.w700)),
                                  const SizedBox(width: 6),
                                  const Icon(LucideIcons.arrowRight, size: 15, color: Color(0xFF4B3BCB)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Companies.
                  if (app.demo) ...[
                    _Label('Your companies'),
                    _Group(
                      children: [
                        for (var i = 0; i < companies.length; i++)
                          GPressable(
                            scale: .985,
                            semanticLabel: companies[i].name,
                            onTap: () {
                              if (i == app.company) return;
                              app.setCompany(i);
                              GToast.show(context, 'Opened ${companies[i].name}', type: GToastType.info);
                            },
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: i == app.company ? g.ink : g.card,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      companies[i].initials,
                                      style: GType.label.c(i == app.company ? g.onInk : g.ink).w(FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(companies[i].name, style: GType.title.c(g.ink)),
                                        Text('${companies[i].role} · ${companies[i].people} people', style: GType.caption.c(g.ink3)),
                                      ],
                                    ),
                                  ),
                                  if (i == app.company) Icon(LucideIcons.check, size: 20, color: g.accent),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],

                  // Display and demo data.
                  _Label('Display'),
                  GSegmented<ThemeMode>(
                    options: const [(ThemeMode.system, 'Automatic'), (ThemeMode.light, 'Light'), (ThemeMode.dark, 'Dark')],
                    value: app.themeMode,
                    onChanged: app.setTheme,
                  ),
                  _Label('Demo data'),
                  GSegmented<DataMode>(
                    options: [for (final m in DataMode.values) (m, m.label)],
                    value: app.mode,
                    onChanged: (m) {
                      app.setMode(m);
                      GToast.show(context, _modeToast(m), type: GToastType.info);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                    child: Text(_modeHelp(app.mode), style: GType.caption.c(g.ink3).copyWith(height: 1.4)),
                  ),

                  // Settings.
                  _Label('Settings'),
                  _Group(
                    children: [
                      _Row(
                        icon: LucideIcons.bell,
                        title: 'Notifications',
                        sub: 'Quiet 9 pm – 7 am',
                        onTap: () => showWebOnly(context, 'Notification settings', LucideIcons.bell),
                      ),
                      _Row(
                        icon: LucideIcons.fileText,
                        title: 'Business plan',
                        onTap: () => showWebOnly(context, 'Business plan', LucideIcons.fileText),
                      ),
                      _Row(icon: LucideIcons.phone, title: 'Phone', trailing: owner?.phone ?? '', onTap: null),
                      _Row(
                        icon: LucideIcons.circleQuestionMark,
                        title: 'Help and support',
                        onTap: () => showWebOnly(context, 'Help and support', LucideIcons.lifeBuoy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Group(
                    children: [
                      _Row(
                        icon: LucideIcons.logOut,
                        title: app.demo ? 'Leave the demo' : 'Sign out',
                        danger: true,
                        onTap: () {
                          final app = context.appRead;
                          Navigator.of(context).pop();
                          app.signOut();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(child: Text(app.demo ? 'Business Genie · demo 0.1.0' : 'Business Genie 0.1.0', style: GType.caption.c(g.ink3))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _modeToast(DataMode m) => switch (m) {
    DataMode.full => 'Showing a company in full swing',
    DataMode.some => 'Showing a company a few weeks in',
    DataMode.empty => 'Showing a company that just signed up',
    DataMode.failure => 'Showing what happens when the server fails',
  };

  static String _modeHelp(DataMode m) => switch (m) {
    DataMode.full => 'A company in full swing: decisions, a live meeting, goals and a busy day.',
    DataMode.some => 'A company a few weeks in: a little of everything, some readings still missing.',
    DataMode.empty => 'A company that has just signed up: every screen shows its empty state.',
    DataMode.failure => 'The server not answering: every screen shows its error and Try again.',
  };
}

class _TopButton extends StatelessWidget {
  const _TopButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return GPressable(
      scale: .9,
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: g.surface,
          shape: BoxShape.circle,
          border: Border.all(color: g.rule),
        ),
        child: Icon(icon, size: 18, color: g.ink),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.icon, required this.label, required this.on, required this.onTap});

  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return GPressable(
      scale: .96,
      selected: on,
      semanticLabel: '$label, ${on ? 'on' : 'off'}',
      onTap: onTap,
      child: AnimatedContainer(
        duration: GMotion.of(context, GMotion.quick),
        height: 104,
        decoration: BoxDecoration(
          color: on ? g.ink : g.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x0B000000), blurRadius: 20, offset: Offset(0, 6))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: on ? g.onInk : g.ink2),
            const SizedBox(height: 10),
            Text(label, style: GType.label.c(on ? g.onInk : g.ink).w(FontWeight.w600).copyWith(fontSize: 14)),
            const SizedBox(height: 2),
            Text(on ? 'On' : 'Off', style: GType.caption.c(on ? g.onInk.withValues(alpha: .6) : g.ink3)),
          ],
        ),
      ),
    );
  }
}

class _WeekStat extends StatelessWidget {
  const _WeekStat({required this.value, required this.label});

  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: GType.numeral.c(Colors.white).copyWith(fontSize: 28)),
          const SizedBox(height: 4),
          Text(label, style: GType.caption.c(Colors.white.withValues(alpha: .75))),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 30, 4, 12),
      child: Text(text, style: GType.label.c(context.g.ink3)),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: GShape.lifted(g.surface, 20),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(left: 68),
                child: Container(height: 1, color: g.rule),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.onTap, this.sub, this.trailing, this.danger = false});

  final IconData icon;
  final String title;
  final String? sub, trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final c = danger ? g.danger : g.ink;
    return GPressable(
      scale: .985,
      semanticLabel: title,
      onTap: onTap,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: danger ? g.dangerSoft : g.card, borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, size: 17, color: c),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GType.label.c(c).w(FontWeight.w600).copyWith(fontSize: 14.5)),
                  if (sub != null) Text(sub!, style: GType.caption.c(g.ink3)),
                ],
              ),
            ),
            if (trailing != null) Text(trailing!, style: GType.caption.c(g.ink2)),
            if (onTap != null && !danger) Icon(LucideIcons.chevronRight, size: 16, color: g.ink4),
          ],
        ),
      ),
    );
  }
}
