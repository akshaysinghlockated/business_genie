import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/overlays.dart';
import '../../core/widgets/pressable.dart';
import '../shell/create_sheet.dart';

/// How the Tasks tab lays its work out.
enum TaskLayout {
  list('List', LucideIcons.listChecks, 'Your tasks, one row each', true),
  board('Board', LucideIcons.columns3, 'Columns from overdue to done', true),
  timeline('Timeline', LucideIcons.chartGantt, 'Today hour by hour', true),
  calendar('Calendar', LucideIcons.calendarDays, 'Meetings and tasks by day', true),
  decisions('Decisions', LucideIcons.gitFork, 'Calls waiting on you', false),
  team('Team', LucideIcons.usersRound, 'Who carries what, who is behind', false),
  goals('Goals', LucideIcons.target, 'Every goal and how it is going', false);

  const TaskLayout(this.label, this.icon, this.hint, this.work);
  final String label, hint;
  final IconData icon;

  /// True for views of your own work; false for company views.
  final bool work;
}

enum TaskShow {
  all('All'),
  mine('Only mine'),
  priority('Priority'),
  genie('From Genie');

  const TaskShow(this.label);
  final String label;
}

enum TaskGroup {
  none('None'),
  due('Due'),
  department('Department'),
  priority('Priority');

  const TaskGroup(this.label);
  final String label;
}

enum TaskSort {
  due('Due time'),
  priority('Priority first'),
  length('Shortest first'),
  title('A to Z');

  const TaskSort(this.label);
  final String label;
}

/// What the owner chose in Manage view. Kept for the session.
@immutable
class TaskViewPrefs {
  const TaskViewPrefs({
    this.compact = false,
    this.show = TaskShow.all,
    this.group = TaskGroup.none,
    this.sort = TaskSort.due,
    this.time = true,
    this.department = true,
    this.length = true,
    this.timer = true,
  });

  final bool compact;
  final TaskShow show;
  final TaskGroup group;
  final TaskSort sort;

  /// Fields shown on each row.
  final bool time, department, length, timer;

  TaskViewPrefs copyWith({bool? compact, TaskShow? show, TaskGroup? group, TaskSort? sort, bool? time, bool? department, bool? length, bool? timer}) =>
      TaskViewPrefs(
        compact: compact ?? this.compact,
        show: show ?? this.show,
        group: group ?? this.group,
        sort: sort ?? this.sort,
        time: time ?? this.time,
        department: department ?? this.department,
        length: length ?? this.length,
        timer: timer ?? this.timer,
      );

  /// How many choices differ from the default, for the badge on the button.
  int get changes {
    const d = TaskViewPrefs();
    return [compact != d.compact, show != d.show, group != d.group, sort != d.sort, !time, !department, !length, !timer].where((c) => c).length;
  }
}

final ValueNotifier<TaskViewPrefs> taskView = ValueNotifier(const TaskViewPrefs());
final ValueNotifier<TaskLayout> taskLayout = ValueNotifier(TaskLayout.list);

/// The Tasks toolbar: Manage view on the left, the chosen view in the middle,
/// add on the right. In the bar's row it stretches to the full width.
class TasksToolbar extends StatelessWidget {
  const TasksToolbar({super.key, this.wide = false});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final h = wide ? 48.0 : 40.0;
    return ListenableBuilder(
      listenable: Listenable.merge([taskView, taskLayout]),
      builder: (context, _) {
        final changes = taskView.value.changes;
        final view = taskLayout.value;
        final soft = BoxDecoration(color: g.ink.withValues(alpha: .06), borderRadius: BorderRadius.circular(13));
        final choose = Builder(
          builder: (context) => GPressable(
            scale: .95,
            semanticLabel: 'Choose view, now ${view.label}',
            onTap: () => showChooseView(context),
            child: Container(
              height: h,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: soft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(view.icon, size: 16, color: g.ink),
                  const SizedBox(width: 7),
                  Text(view.label, style: GType.label.c(g.ink).w(FontWeight.w600)),
                  const SizedBox(width: 4),
                  Icon(LucideIcons.chevronsUpDown, size: 14, color: g.ink3),
                ],
              ),
            ),
          ),
        );
        return _Glass(
          radius: wide ? 32 : 18,
          child: Padding(
            padding: EdgeInsets.all(wide ? 8 : 5),
            child: Row(
              mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
              children: [
                GPressable(
                  scale: .9,
                  semanticLabel: 'Manage view${changes > 0 ? ', $changes changed' : ''}',
                  onTap: () => openManageView(context),
                  child: Container(
                    width: h,
                    height: h,
                    decoration: soft,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(LucideIcons.slidersHorizontal, size: 17, color: g.ink),
                        if (changes > 0)
                          Positioned(
                            top: 7,
                            right: 7,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: g.accent, shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                if (wide) Expanded(child: choose) else choose,
                const SizedBox(width: 5),
                GPressable(
                  scale: .9,
                  semanticLabel: 'Add a task, meeting or goal',
                  onTap: () => showCreateSheet(context),
                  child: Container(
                    width: h,
                    height: h,
                    decoration: BoxDecoration(color: g.ink, borderRadius: BorderRadius.circular(13)),
                    child: Icon(LucideIcons.plus, size: 19, color: g.onInk),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child, required this.radius});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .07), blurRadius: 22, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter.grouped(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: g.surface.withValues(alpha: .78),
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

/// Choose view: a small menu that grows up out of the button.
void showChooseView(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  final size = MediaQuery.sizeOf(context);
  final at = box == null ? Offset(size.width / 2, size.height - 160) : box.localToGlobal(Offset(box.size.width / 2, 0));
  GHaptics.light();
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: .08),
    transitionDuration: GMotion.of(context, const Duration(milliseconds: 240)),
    pageBuilder: (context, _, _) {
      final g = context.g;
      const w = 268.0;
      final left = (at.dx - w / 2).clamp(16.0, size.width - w - 16);
      return Stack(
        children: [
          Positioned(
            left: left,
            bottom: size.height - at.dy + 12,
            width: w,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: GShape.lifted(g.surface, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (title, work) in const [('Your work', true), ('Company', false)]) ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(10, work ? 6 : 10, 10, 4),
                        child: Text(title.toUpperCase(), style: GType.micro.c(g.ink3).copyWith(letterSpacing: .8)),
                      ),
                      for (final v in TaskLayout.values.where((v) => v.work == work))
                        GPressable(
                          scale: .97,
                          semanticLabel: v.label,
                          onTap: () {
                            GHaptics.select();
                            taskLayout.value = v;
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: taskLayout.value == v ? g.ink.withValues(alpha: .05) : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Icon(v.icon, size: 18, color: g.ink),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(v.label, style: GType.label.c(g.ink).w(FontWeight.w600)),
                                      Text(v.hint, maxLines: 1, overflow: TextOverflow.ellipsis, style: GType.caption.c(g.ink3).copyWith(fontSize: 11.5)),
                                    ],
                                  ),
                                ),
                                if (taskLayout.value == v) Icon(LucideIcons.check, size: 17, color: g.ink),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (context, a, _, child) {
      final c = CurvedAnimation(parent: a, curve: GMotion.easeOut);
      return FadeTransition(
        opacity: c,
        child: ScaleTransition(scale: Tween(begin: .92, end: 1.0).animate(c), alignment: Alignment.bottomCenter, child: child),
      );
    },
  );
}

/// Manage view: a tall bottom sheet over the list, so changes show the
/// moment the sheet closes. Reset on the left, Done on the right.
void openManageView(BuildContext context) {
  showGSheet<void>(context, full: true, builder: (_) => const ManageViewSheet());
}

class ManageViewSheet extends StatelessWidget {
  const ManageViewSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TaskViewPrefs>(
      valueListenable: taskView,
      builder: (context, p, _) {
        final g = context.g;
        void set(TaskViewPrefs v) {
          GHaptics.select();
          taskView.value = v;
        }

        return ColoredBox(
          color: g.ground,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(color: g.ink4, borderRadius: BorderRadius.circular(2)),
              ),
              SizedBox(
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: AnimatedOpacity(
                          duration: GMotion.of(context, GMotion.quick),
                          opacity: p.changes > 0 ? 1 : 0,
                          child: GPressable(
                            scale: .94,
                            semanticLabel: 'Reset to default',
                            onTap: p.changes > 0 ? () => set(const TaskViewPrefs()) : null,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text('Reset', style: GType.label.c(g.ink2).w(FontWeight.w600)),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(child: Text('Manage view', style: GType.h3.c(g.ink))),
                      ),
                      SizedBox(
                        width: 80,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: GPressable(
                            scale: .94,
                            semanticLabel: 'Done',
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              height: 34,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: g.ink, borderRadius: BorderRadius.circular(17)),
                              child: Text('Done', style: GType.label.c(g.onInk).w(FontWeight.w600)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(GSpace.gutter, 0, GSpace.gutter, MediaQuery.paddingOf(context).bottom + 32),
                  children: [
                    _Section(
                      title: 'Layout',
                      children: [
                        _SwitchRow(
                          icon: LucideIcons.rows3,
                          title: 'Compact mode',
                          sub: 'Tighter rows, one line each',
                          value: p.compact,
                          onChanged: (v) => set(p.copyWith(compact: v)),
                        ),
                      ],
                    ),
                    _Section(
                      title: 'Filter',
                      children: [
                        for (final v in TaskShow.values)
                          _PickRow(
                            title: v.label,
                            sub: switch (v) {
                              TaskShow.all => 'Every task in the list',
                              TaskShow.mine => 'Not the ones given to others',
                              TaskShow.priority => 'Flagged as priority',
                              TaskShow.genie => 'Written by Genie from meetings and chats',
                            },
                            on: p.show == v,
                            onTap: () => set(p.copyWith(show: v)),
                          ),
                      ],
                    ),
                    _Section(
                      title: 'Group by',
                      children: [
                        for (final v in TaskGroup.values)
                          _PickRow(
                            title: v.label,
                            on: p.group == v,
                            onTap: () => set(p.copyWith(group: v)),
                          ),
                      ],
                    ),
                    _Section(
                      title: 'Sort',
                      children: [
                        for (final v in TaskSort.values)
                          _PickRow(
                            title: v.label,
                            on: p.sort == v,
                            onTap: () => set(p.copyWith(sort: v)),
                          ),
                      ],
                    ),
                    _Section(
                      title: 'Fields on each row',
                      children: [
                        _SwitchRow(
                          icon: LucideIcons.clock,
                          title: 'Time',
                          sub: 'When it is due',
                          value: p.time,
                          onChanged: (v) => set(p.copyWith(time: v)),
                        ),
                        _SwitchRow(
                          icon: LucideIcons.building2,
                          title: 'Department',
                          sub: 'The coloured dot and name',
                          value: p.department,
                          onChanged: (v) => set(p.copyWith(department: v)),
                        ),
                        _SwitchRow(
                          icon: LucideIcons.hourglass,
                          title: 'Length',
                          sub: 'How long it takes',
                          value: p.length,
                          onChanged: (v) => set(p.copyWith(length: v)),
                        ),
                        _SwitchRow(
                          icon: LucideIcons.play,
                          title: 'Timer',
                          sub: 'The play button on each row',
                          value: p.timer,
                          onChanged: (v) => set(p.copyWith(timer: v)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
          child: Text(title, style: GType.label.c(g.ink3)),
        ),
        Container(
          decoration: GShape.lifted(g.surface, 20),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Container(height: 1, color: g.rule),
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({required this.title, required this.on, required this.onTap, this.sub});

  final String title;
  final String? sub;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return GPressable(
      scale: .99,
      selected: on,
      semanticLabel: title,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GType.label.c(g.ink).copyWith(fontSize: 15)),
                  if (sub != null) Text(sub!, style: GType.caption.c(g.ink3)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: GMotion.of(context, GMotion.quick),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? g.ink : Colors.transparent,
                border: Border.all(color: on ? g.ink : g.ruleStrong, width: 1.5),
              ),
              child: on ? Icon(LucideIcons.check, size: 13, color: g.onInk) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.icon, required this.title, required this.sub, required this.value, required this.onChanged});

  final IconData icon;
  final String title, sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: g.card, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 16, color: g.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GType.label.c(g.ink).copyWith(fontSize: 15)),
                Text(sub, style: GType.caption.c(g.ink3)),
              ],
            ),
          ),
          GSwitch(label: title, value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
