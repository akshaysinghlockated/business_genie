/// Plain models for the owner view. Field names follow what the Business
/// Genie API is expected to send, so a live source can fill them later.
library;

/// Which data the demo shows. "Some" is a company a few weeks in; "Empty" is
/// a company that has just signed up; "Fails" is the server not answering.
enum DataMode {
  full('Full'),
  some('Some'),
  empty('Empty'),
  failure('Fails');

  const DataMode(this.label);
  final String label;
}

class Person {
  const Person({
    required this.id,
    required this.name,
    required this.role,
    required this.dept,
    this.today,
    this.live = false,
    this.behind = false,
    this.email = '',
    this.phone = '',
    this.about = '',
    this.reportFiled = false,
  });

  final String id, name, role, dept;

  /// Today's one-line status ("In Daily huddle", "Out until 12").
  final String? today;
  final bool live, behind, reportFiled;
  final String email, phone, about;

  String get first => name.split(' ').first;
}

enum GoalStatus {
  onTrack('On track'),
  behind('Behind'),
  achieved('Achieved'),
  notStarted('Not started');

  const GoalStatus(this.label);
  final String label;
}

class KeyResult {
  const KeyResult({required this.title, this.progress, required this.target, this.current});

  final String title, target;
  final String? current;

  /// Null until the first reading; never shown as 0%.
  final double? progress;
}

class GoalUpdate {
  const GoalUpdate({required this.text, required this.by, required this.ago});
  final String text, by, ago;
}

class Goal {
  const Goal({
    required this.id,
    required this.title,
    required this.ownerId,
    required this.dept,
    required this.status,
    this.progress,
    required this.due,
    this.krs = const [],
    this.updates = const [],
    this.why = '',
  });

  final String id, title, ownerId, dept, due, why;
  final GoalStatus status;
  final double? progress;
  final List<KeyResult> krs;
  final List<GoalUpdate> updates;
}

class Milestone {
  const Milestone({required this.name, required this.week, required this.weeks, required this.progress, required this.krs, required this.stage});

  final String name;
  final int week, weeks;
  final double progress;
  final List<KeyResult> krs;

  /// 0 Foundation · 1 Short · 2 Mid · 3 Long · 4 BHAG.
  final int stage;
}

enum DecisionTone {
  offTrack('Off track'),
  needsCall('Needs a call'),
  ahead('Ahead');

  const DecisionTone(this.label);
  final String label;
}

class Decision {
  Decision({
    required this.id,
    required this.source,
    required this.ago,
    required this.tone,
    required this.title,
    required this.effect,
    required this.options,
    this.detail = '',
    this.picked,
  });

  final String id, source, ago, title, effect, detail;
  final DecisionTone tone;
  final List<String> options;
  int? picked;
}

class Task {
  Task({
    required this.id,
    required this.title,
    required this.when,
    required this.dept,
    this.minutes,
    this.priority = false,
    this.done = false,
    this.assigneeId,
    this.byGenie = false,
    this.private = false,
    this.notes = '',
    this.due,
  });

  final String id, dept, notes;
  String title;

  /// today · overdue · upcoming · done group, and a short label.
  TaskWhen when;
  final int? minutes;
  bool priority, done, private;
  final String? assigneeId;
  final bool byGenie;

  /// A display time such as "10:30 AM" or "Fri".
  final String? due;
}

enum TaskWhen { overdue, today, upcoming }

enum MeetingState { done, live, next, cancelled }

class Meeting {
  const Meeting({
    required this.id,
    required this.title,
    required this.start,
    required this.minutes,
    required this.dept,
    required this.hostId,
    required this.people,
    this.place = 'Google Meet',
    this.online = true,
    this.cancelled = false,
    this.agenda = const [],
    this.notes,
  });

  final String id, title, dept, hostId, place;
  final DateTime start;
  final int minutes;
  final List<String> people;
  final bool online, cancelled;
  final List<String> agenda;
  final String? notes;

  DateTime get end => start.add(Duration(minutes: minutes));

  MeetingState stateAt(DateTime now) {
    if (cancelled) return MeetingState.cancelled;
    if (now.isAfter(end)) return MeetingState.done;
    if (!now.isBefore(start)) return MeetingState.live;
    return MeetingState.next;
  }
}

enum InboxKind { brief, mention, activity, report, slipped, decision }

class InboxItem {
  InboxItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.ago,
    required this.group,
    this.actorId,
    this.unread = true,
  });

  final String id, title, body, ago, group;
  final InboxKind kind;
  final String? actorId;
  bool unread;
}

enum ProjectStatus {
  onTrack('On track'),
  atRisk('At risk'),
  offTrack('Off track'),
  done('Done');

  const ProjectStatus(this.label);
  final String label;
}

class ProjectStep {
  const ProjectStep(this.title, {this.done = false, this.due});
  final String title;
  final bool done;
  final String? due;
}

/// A piece of work with an owner, a team and steps; projects sit in
/// portfolios ("Growth", "Product").
class Project {
  const Project({
    required this.id,
    required this.name,
    required this.portfolio,
    required this.ownerId,
    required this.dept,
    required this.status,
    required this.progress,
    required this.due,
    this.members = const [],
    this.steps = const [],
    this.about = '',
  });

  final String id, name, portfolio, ownerId, dept, due, about;
  final ProjectStatus status;
  final double progress;
  final List<String> members;
  final List<ProjectStep> steps;
}

enum NewsKind {
  industry('Industry'),
  competitors('Competitors'),
  rules('Rules and tax'),
  customers('Customers'),
  company('Your company');

  const NewsKind(this.label);
  final String label;
}

/// A headline from the company's field, with Genie's read on what it means
/// for this company. Sample sources in the demo.
class NewsItem {
  const NewsItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.source,
    required this.ago,
    required this.summary,
    required this.take,
  });

  final String id, title, source, ago, summary;
  final NewsKind kind;

  /// Genie's one-line read: what this means for us.
  final String take;
}

enum SuggestionAction { task, decision, genie }

/// Something Genie thinks is worth doing, with the reason. Nothing happens
/// until the owner presses Do it.
class Suggestion {
  const Suggestion({
    required this.id,
    required this.title,
    required this.why,
    required this.area,
    required this.impact,
    required this.action,
    this.cta = 'Do it',
    this.ref,
  });

  final String id, title, why, area, impact, cta;
  final SuggestionAction action;

  /// Decision id, or the task title, or the question for Genie.
  final String? ref;
}

class PlanTarget {
  const PlanTarget({required this.label, required this.current, required this.target, required this.progress});
  final String label, current, target;
  final double progress;
}

/// Everything the owner view shows, loaded in one go.
class Snapshot {
  Snapshot({
    required this.company,
    required this.owner,
    required this.vision,
    required this.milestone,
    required this.targets,
    required this.goals,
    required this.decisions,
    required this.tasks,
    required this.meetings,
    required this.people,
    required this.inbox,
    required this.departments,
    required this.setupDone,
    this.activity = const [],
    this.revenue = const [],
    this.doneThisWeek = const [],
    this.projects = const [],
    this.news = const [],
    this.suggestions = const [],
  });

  final String company;
  final Person owner;
  final String vision;
  final Milestone? milestone;
  final List<PlanTarget> targets;
  final List<Goal> goals;
  final List<Decision> decisions;
  final List<Task> tasks;
  final List<Meeting> meetings;
  final List<Person> people;
  final List<InboxItem> inbox;
  final List<String> departments;

  /// False for a company that hasn't finished setup on the web.
  final bool setupDone;

  /// The last 30 days, oldest first: 0 nothing done, 1 some work, 2 the
  /// day's plan met, -1 a day off. Empty until there is history.
  final List<int> activity;

  /// Revenue for the last 8 weeks in ₹ lakh, oldest first.
  final List<double> revenue;

  /// Tasks finished each day this week, Monday first, up to today.
  final List<int> doneThisWeek;

  final List<Project> projects;
  final List<NewsItem> news;
  final List<Suggestion> suggestions;

  Project? project(String id) => projects.where((p) => p.id == id).firstOrNull;

  Person? person(String? id) {
    if (id == null) return null;
    if (id == owner.id) return owner;
    for (final p in people) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<Decision> get openDecisions => decisions.where((d) => d.picked == null).toList();
  List<Task> get openTasks => tasks.where((t) => !t.done).toList();
  int get unread => inbox.where((i) => i.unread).length;
}
