import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/presentation/controllers/session_controller.dart';
import 'companies.dart';
import 'models.dart';
import 'sample_data.dart';

/// Thrown when the data can't be fetched. [message] is shown as is.
class LoadError implements Exception {
  const LoadError(this.message);
  final String message;
}

/// The one data source the screens call. Today it serves sample data in the
/// chosen [DataMode] with a realistic delay; a live Business Genie API slots
/// in here later without any screen changing.
abstract final class GenieData {
  static Future<Snapshot> load(DataMode mode, [int company = 0]) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mode == DataMode.failure) {
      throw const LoadError('We couldn’t reach Business Genie. Check your connection, then try again.');
    }
    if (company == 1 && mode == DataMode.full) return brewline(DateTime.now());
    return buildSnapshot(mode, DateTime.now());
  }
}

/// Sections of Home the owner can reorder and hide.
enum HomeSection {
  needs('Needs you'),
  quick('Quick actions'),
  tasks('My tasks'),
  schedule('Today’s schedule'),
  projects('Projects'),
  goals('Goals'),
  team('Team today'),
  trends('Trends and charts');

  const HomeSection(this.label);
  final String label;
}

/// App-wide state: sign-in, theme, demo data mode, the loaded snapshot and
/// the owner's Home layout. Changes to the snapshot are optimistic: the
/// screen updates at once.
class AppState extends ChangeNotifier {
  AppState({required this.session}) {
    session.addListener(_onSessionChanged);
  }

  /// Sign-in state; this class only reacts to it.
  final SessionController session;

  SharedPreferences? _prefs;

  bool ready = false;

  bool get signedIn => session.isSignedIn;
  bool get demo => session.isDemo;
  bool get setupPending => session.isWorkspaceSetupPending;

  /// Signed in with a real account (not the demo).
  bool get live => session.isRealAccount;

  /// The profile photo: the sample portrait in the demo, none for a real
  /// account until the API serves one.
  String? get photo => demo ? ownerPhoto : null;

  /// The company line under its name.
  String get industry => live ? (session.organization?.industry ?? '') : companies[company.clamp(0, companies.length - 1)].industry;

  bool noticeAccepted = false;
  ThemeMode themeMode = ThemeMode.system;
  DataMode mode = DataMode.full;

  /// Which of [companies] is open.
  int company = 0;

  Snapshot? data;
  String? error;
  bool loading = false;

  List<HomeSection> sections = HomeSection.values.toList();
  final Set<HomeSection> hidden = {};

  String? runningTaskId;
  DateTime? runningSince;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    noticeAccepted = p.getBool('notice.v1') ?? false;
    themeMode = ThemeMode.values[(p.getInt('theme.v1') ?? 0).clamp(0, 2)];
    mode = DataMode.values[(p.getInt('mode.v1') ?? 0).clamp(0, DataMode.values.length - 1)];
    final order = p.getStringList('home.order.v7');
    if (order != null) {
      final parsed = [for (final n in order) ...HomeSection.values.where((s) => s.name == n)];
      sections = [...parsed, ...HomeSection.values.where((s) => !parsed.contains(s))];
    }
    hidden.addAll([for (final n in p.getStringList('home.hidden.v7') ?? const <String>[]) ...HomeSection.values.where((s) => s.name == n)]);
    await session.restore();
    ready = true;
    notifyListeners();
    if (signedIn && !setupPending) load();
    if (live) unawaited(session.refresh());
  }

  /// Keeps the sample data in step with sign-in: cleared on sign-out,
  /// loaded once signed in, and shown for the real person and company.
  void _onSessionChanged() {
    if (!signedIn) {
      data = null;
      runningTaskId = null;
      runningSince = null;
    } else if (!setupPending && data == null && !loading && ready) {
      load();
    } else {
      _showSignedInAccount();
    }
    notifyListeners();
  }

  /// Puts the real person and company on the sample data.
  void _showSignedInAccount() {
    final user = session.user;
    final snapshot = data;
    if (!live || user == null || snapshot == null) return;
    final companyName = session.organization?.name ?? '';
    data = snapshot.withOwner(
      Person(id: snapshot.owner.id, name: user.displayName, role: user.roleLabel, dept: snapshot.owner.dept, email: user.email),
      companyName.isEmpty ? 'Your company' : companyName,
    );
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      data = await GenieData.load(mode, company);
      _showSignedInAccount();
    } on LoadError catch (e) {
      data = null;
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  /// First load shows skeletons; switching mode shows them again briefly so
  /// every state can be seen.
  void setMode(DataMode m) {
    if (m == mode) return;
    mode = m;
    _prefs?.setInt('mode.v1', m.index);
    data = null;
    load();
  }

  /// Opens another company: skeletons, then its data.
  void setCompany(int i) {
    if (i == company) return;
    company = i;
    data = null;
    load();
  }

  void setTheme(ThemeMode m) {
    themeMode = m;
    _prefs?.setInt('theme.v1', m.index);
    notifyListeners();
  }

  void acceptNotice() {
    noticeAccepted = true;
    _prefs?.setBool('notice.v1', true);
    notifyListeners();
  }

  /// Signs out (or leaves the demo) on this phone.
  void signOut() => session.signOut();

  void setSections(List<HomeSection> order) {
    sections = order;
    _prefs?.setStringList('home.order.v7', [for (final s in order) s.name]);
    notifyListeners();
  }

  void toggleSection(HomeSection s, bool visible) {
    visible ? hidden.remove(s) : hidden.add(s);
    _prefs?.setStringList('home.hidden.v7', [for (final h in hidden) h.name]);
    notifyListeners();
  }

  // ---- Tasks ----

  void toggleTask(String id) {
    final t = data?.tasks.where((t) => t.id == id).firstOrNull;
    if (t == null) return;
    t.done = !t.done;
    if (t.done && runningTaskId == id) stopTimer();
    notifyListeners();
  }

  void togglePriority(String id) {
    final t = data?.tasks.where((t) => t.id == id).firstOrNull;
    if (t == null) return;
    t.priority = !t.priority;
    notifyListeners();
  }

  void moveTask(String id, TaskWhen when) {
    final t = data?.tasks.where((t) => t.id == id).firstOrNull;
    if (t == null) return;
    t.when = when;
    notifyListeners();
  }

  Task addTask({
    required String title,
    required String dept,
    int? minutes,
    TaskWhen when = TaskWhen.today,
    bool private = false,
    bool priority = false,
    bool byGenie = false,
  }) {
    final t = Task(
      id: 't${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      when: when,
      dept: dept,
      minutes: minutes,
      private: private,
      priority: priority,
      byGenie: byGenie,
    );
    data?.tasks.insert(0, t);
    notifyListeners();
    return t;
  }

  void deleteTask(String id) {
    data?.tasks.removeWhere((t) => t.id == id);
    if (runningTaskId == id) stopTimer();
    notifyListeners();
  }

  void restoreTask(Task t, int index) {
    final list = data?.tasks;
    if (list == null) return;
    list.insert(index.clamp(0, list.length), t);
    notifyListeners();
  }

  void startTimer(String id) {
    runningTaskId = id;
    runningSince = DateTime.now();
    notifyListeners();
  }

  void stopTimer() {
    runningTaskId = null;
    runningSince = null;
    notifyListeners();
  }

  // ---- Decisions and inbox ----

  void choose(String decisionId, int option) {
    final d = data?.decisions.where((d) => d.id == decisionId).firstOrNull;
    if (d == null) return;
    d.picked = option;
    notifyListeners();
  }

  void undoChoice(String decisionId) {
    final d = data?.decisions.where((d) => d.id == decisionId).firstOrNull;
    if (d == null) return;
    d.picked = null;
    notifyListeners();
  }

  void markRead(String id) {
    final i = data?.inbox.where((i) => i.id == id).firstOrNull;
    if (i == null || !i.unread) return;
    i.unread = false;
    notifyListeners();
  }

  /// Suggestions the owner acted on or put aside this session.
  final Set<String> doneSuggestions = {};

  /// Suggestions the owner swiped to keep.
  final Set<String> keptSuggestions = {};

  /// Not yet seen: neither kept nor put aside.
  List<Suggestion> get openSuggestions => [
    for (final x in data?.suggestions ?? const <Suggestion>[])
      if (!doneSuggestions.contains(x.id) && !keptSuggestions.contains(x.id)) x,
  ];

  List<Suggestion> get kept => [
    for (final x in data?.suggestions ?? const <Suggestion>[])
      if (keptSuggestions.contains(x.id) && !doneSuggestions.contains(x.id)) x,
  ];

  void keepSuggestion(String id) {
    keptSuggestions.add(id);
    notifyListeners();
  }

  void closeSuggestion(String id) {
    doneSuggestions.add(id);
    notifyListeners();
  }

  void reopenSuggestion(String id) {
    doneSuggestions.remove(id);
    keptSuggestions.remove(id);
    notifyListeners();
  }

  void markAllRead() {
    for (final i in data?.inbox ?? const <InboxItem>[]) {
      i.unread = false;
    }
    notifyListeners();
  }
}

/// Makes [AppState] reachable from any widget.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

extension AppStateContext on BuildContext {
  AppState get app => AppScope.of(this);
  AppState get appRead => AppScope.read(this);

  /// Sign-in state, for the auth screens.
  SessionController get session => AppScope.of(this).session;
  SessionController get sessionRead => AppScope.read(this).session;
}
