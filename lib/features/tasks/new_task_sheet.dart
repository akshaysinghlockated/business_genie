import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/type.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/controls.dart';
import '../../core/widgets/input.dart';
import '../../core/widgets/overlays.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';

/// New task: what needs doing, a target time, when, a department, and
/// whether it is just for you.
void showNewTaskSheet(BuildContext context, {String? title, bool private = false}) {
  showGSheet<void>(
    context,
    builder: (_) => _NewTaskSheet(title: title ?? '', private: private),
  );
}

class _NewTaskSheet extends StatefulWidget {
  const _NewTaskSheet({required this.title, required this.private});

  final String title;
  final bool private;

  @override
  State<_NewTaskSheet> createState() => _NewTaskSheetState();
}

class _NewTaskSheetState extends State<_NewTaskSheet> {
  late final _title = TextEditingController(text: widget.title);
  int _minutes = 30;
  TaskWhen _when = TaskWhen.today;
  String _dept = 'Leadership';
  late bool _private = widget.private;
  bool _priority = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _add() {
    final t = _title.text.trim();
    if (t.isEmpty) {
      setState(() => _error = 'Say what needs doing.');
      GHaptics.heavy();
      return;
    }
    final app = context.appRead;
    app.addTask(title: t, dept: _private ? 'Personal' : _dept, minutes: _minutes, when: _when, private: _private, priority: _priority);
    Navigator.of(context).pop();
    GHaptics.heavy();
    GToast.show(context, 'Task added to ${_when == TaskWhen.today ? 'Today' : 'Upcoming'}');
  }

  @override
  Widget build(BuildContext context) {
    final g = context.g;
    final depts = context.app.data?.departments ?? const <String>[];
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GSheetHeader(title: 'New task'),
            Padding(
              padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.s, GSpace.gutter, 0),
              child: GInput(
                hint: 'What needs doing?',
                controller: _title,
                autofocus: widget.title.isEmpty,
                error: _error,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _add(),
              ),
            ),
            _label('Target time', g),
            GChipRow(
              children: [
                for (final m in const [15, 30, 45, 60]) GChip(label: GFormat.minutes(m), selected: _minutes == m, onTap: () => setState(() => _minutes = m)),
              ],
            ),
            _label('When', g),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: GSpace.gutter),
              child: GSegmented<TaskWhen>(
                options: const [(TaskWhen.today, 'Today'), (TaskWhen.upcoming, 'Later this week')],
                value: _when,
                onChanged: (v) => setState(() => _when = v),
              ),
            ),
            if (!_private && depts.isNotEmpty) ...[
              _label('Department', g),
              GChipRow(
                children: [
                  for (final d in ['Leadership', ...depts]) GChip(label: GFormat.shortDept(d), selected: _dept == d, onTap: () => setState(() => _dept = d)),
                ],
              ),
            ],
            const SizedBox(height: GSpace.l),
            _toggle(g, LucideIcons.lock, 'Only me', 'Nobody else sees it, not even your heads.', _private, (v) => setState(() => _private = v)),
            _toggle(g, LucideIcons.flag, 'Priority', 'Keeps it in your Priorities list.', _priority, (v) => setState(() => _priority = v)),
            Padding(
              padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.l, GSpace.gutter, GSpace.l),
              child: GButton(label: 'Add task', expand: true, height: 52, onTap: _add),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t, GPalette g) => Padding(
    padding: const EdgeInsets.fromLTRB(GSpace.gutter, GSpace.l, GSpace.gutter, GSpace.s),
    child: Text(t, style: GType.label.c(g.ink2)),
  );

  Widget _toggle(GPalette g, IconData icon, String title, String sub, bool v, ValueChanged<bool> on) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: GSpace.gutter, vertical: 8),
    child: Row(
      children: [
        Icon(icon, size: 20, color: g.ink2),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GType.title.c(g.ink).w(FontWeight.w500)),
              Text(sub, style: GType.caption.c(g.ink3)),
            ],
          ),
        ),
        GSwitch(value: v, onChanged: on, label: title),
      ],
    ),
  );
}
