# Business Genie app: modules, API coverage and timeline

Written Tue 3 Nov 2026, from the new app in `business_genie/` (commit `855c0fe`) and the backend references. Checked again the same day against the code, `API.md` and the Postman collection. In that check the timeline dates were fixed (3 Nov 2026 is a Tuesday) and §2.20 (HR self-service) was added.

## Summary

- The new app has **18 modules**, listed in §2. All of them run on sample data today (`lib/data/sample_data.dart`). There is no API code yet. `GenieData.load()` in `lib/data/app_state.dart` is the single place where the live API plugs in.
- **API coverage:**

  | | Modules |
  |---|---|
  | ✅ API ready | **5** |
  | 🟡 Partly ready | **10** |
  | ❌ No API | **3** |
- **Partly ready** has two causes:
  - Some screens have no API for one piece.
  - Some screens use PATM / Calendar, which the app can't call until **Business Genie sign-in works for PATM and Calendar** (backend task B0).
- **No API:** Decisions, News and Genie suggestions have no backend at all. Neither do the Genie chat about the business (inside the Genie module) or push notifications (used across the app).
- **HR self-service has APIs but no screens:** about 60 of the 80 endpoints the backend marks for the app are HR self-service, for example check-in, leave, payslips and claims. They are Ready, but the new UI has no screens for them (§2.20). Product has to decide whether v1 includes them.
- **Timeline:** about **11 weeks to store release**, from Tue 3 Nov 2026 to **Fri 15 Jan 2027**. That assumes 2 Flutter developers and 1 backend developer working in parallel. Most of the risk is in the backend work in §4, not in the app.

Sources used:

| Source | What it covers |
|---|---|
| `buisness_genie_app/docs/API.md` | All 355 Business Genie endpoints, marked for the phone (App, Later, Web only) and status (Ready, Needs work, Not built) |
| `Business_Genie_API.postman_collection.json` | 369 requests, including the proposed endpoints in "26. Proposed & Future Endpoints" |
| `docs/patm-calendar-field-map.md` | PATM (tasks, to-dos, issues, projects) and Calendar app requests |
| `app/` (the earlier app) | API client, token store and repositories that can be reused |

Legend: ✅ ready on the live server · 🟡 exists but has a gap or depends on something · ❌ no backend.

---

## 1. How the app gets its data today

- **One snapshot:** `AppState` loads one `Snapshot` (`lib/data/models.dart`). It holds the company, owner, vision, milestone, plan targets, goals, decisions, tasks, meetings, people, inbox, projects, news, suggestions and chart series.
- **Field names:** the model's comments say they follow what the Business Genie API is expected to send.
- **Writes are optimistic:** a task done, a priority change, a decision picked or an item marked read changes the screen at once. A live source needs to send the matching write and roll back on failure.
- **Demo mode:** the `DataMode` switch (Full · Some · Empty · Fails) shows every screen state. Keep it as a demo mode behind the live source; the earlier app already does this with a sample company.
- **Navigation:** five tabs (Home · Tasks · Inbox · Explore · Milestone), a centre **Create** button, and Genie opening full screen from Home.

---

## 2. Modules and their APIs

### 2.1 Sign-in and first run (`features/auth`) 🟡

Screens: splash, work email → 6-digit code, "Continue with Google Workspace", and the "Before you start" notice.

| Feature | API | Status |
|---|---|---|
| Email code | `POST /auth/login`, `POST /auth/login/verify` (15-day token) | ✅ |
| Who am I | `GET /auth/me` | ✅ |
| Is the workspace set up | `GET /onboarding` (send to the web if not done) | ✅ |
| Role and menu | `GET /hr` (nav, permissions) | ✅ |
| Google Workspace sign-in | none | ❌ hide the button for v1, or backend adds Google sign-in |
| Stay signed in / sign out | `POST /auth/refresh`, `POST /auth/logout` | ❌ proposed only. Sign-out works locally; the token can't be revoked. |
| Notice screen | stored on the phone | ✅ no API needed |

### 2.2 Home (`features/home`) 🟡

Sections the owner can reorder: milestone hero, day ribbon, Needs you, Quick actions, My tasks, Today's schedule, Projects, Goals, Team today, Trends and charts.

| Section | API | Status |
|---|---|---|
| Company, owner, weekly brief, recent changes | `GET /dashboard` (brief can arrive as a job → `GET /jobs/:id`) | ✅ |
| Milestone hero | `GET /dashboard` → `milestone_reports`; milestone itself from the business plan | 🟡 the milestone list is inside `GET /business_plan`, which can start AI writing on first read. Backend should add a read-only milestone endpoint (B9). |
| Needs you | approvals `GET /hr/approvals?scope=to_decide` ✅ + goals behind ✅ + decisions ❌ | 🟡 |
| My tasks, Projects | PATM (see 2.4, 2.12) | 🟡 needs B0 |
| Today's schedule | Calendar app (see 2.11) | 🟡 needs B0 |
| Goals | `GET /goals`, `GET /hr/goals` | ✅ |
| Team today: who is in, who is behind | `GET /hr/overview`, `GET /hr/attendance/daily` | ✅ |
| Team today: who has reported | daily reports | ❌ `GET /daily-reports` proposed only |
| Trends: revenue | finance actuals | ❌ `GET /finance/actuals` proposed only |
| Trends: tasks done per day, days on plan | derived from PATM tasks | 🟡 needs B0 |
| Layout (order, hidden sections) | stored on the phone | ✅ |

### 2.3 Genie (`features/genie`) 🟡

Screens: Genie panel (full screen), today's brief, chat with starter prompts, voice mode (Listening, Mute, End), and a draft task Genie writes.

| Feature | API | Status |
|---|---|---|
| Today's brief | `GET /dashboard` → `brief`, `POST /dashboard/brief` to rewrite | ✅ |
| Speak instead of typing | `POST /dictations` (audio → text, job) | ✅ |
| HR questions (leave, policies) | `POST /hr/desk/ask` | ✅ (AI answers are switched off on live: `GET /hr/ai`) |
| Chat about the business: goals, team, meetings, "plan my day", "prep my meeting" | none | ❌ needs a Genie chat endpoint that knows the plan, goals, tasks and calendar (B3) |
| Live voice conversation (voice mode) | none | ❌ v1 can use dictation plus a spoken reply on the phone; a real voice session needs B3 |
| "Draft task" → Add | PATM create task | 🟡 needs B0 |

`genie_brain.dart` answers on the phone today with canned replies. It should become the fallback when the chat endpoint is down.

### 2.4 Tasks (`features/tasks`) 🟡

Screens:
- **Layouts:** List, Board (overdue → done), Timeline (today by hour), Calendar, Decisions, Team (who carries what) and Goals.
- **Task detail:** notes, comments, move, priority, timer, delete.
- **Lists:** new task sheet, Delegated, Only me.

| Feature | API (PATM) | Status |
|---|---|---|
| List tasks | `GET /task_managements.json` (filters by owner, status, dates) | 🟡 needs B0 |
| New task / sub-task | `POST /task_managements.json` (title, `responsible_person_id`, `target_date`, priority …) | 🟡 needs B0 |
| Done, reopen, move | `PUT /task_managements/{id}/update_status.json` | 🟡 needs B0 |
| Start / stop clock | same endpoint, `started` / `stopped` | 🟡 needs B0 |
| Comments | `POST /comments.json` (`commentable_type: TaskManagement`) | 🟡 needs B0 |
| "Only me" reminders | `POST /todos.json`, `GET /todos.json` | 🟡 needs B0 |
| People to assign | `GET /pms/users/get_escalate_to_users.json?type=Task` | 🟡 needs B0 |
| Priority star (app's own flag) | PATM `priority` (Urgent/High/Medium/Low) | 🟡 map "priority" to High/Urgent |
| Delete | PATM delete task | 🟡 confirm the endpoint with the PATM team |
| "Written by Genie" label | `source` field on the task | 🟡 needs B0 |
| Business Genie's own `/tasks` | proposed only | ❌ not needed if PATM is used |

### 2.5 Create (`features/shell/create_sheet.dart`) 🟡

| Item | API | Status |
|---|---|---|
| Task | PATM `POST /task_managements.json` | 🟡 needs B0 |
| Reminder | PATM `POST /todos.json` | 🟡 needs B0 |
| Meeting | Calendar `POST api/google_calendar_events` | 🟡 needs B0. The new UI sends Meeting to the web ("Scheduling") for now. Once B0 works, give it an in-app sheet. |
| Goal | `POST /goals` exists but has no role check | 🟡 keep "Goal setting opens on the web" until the check is added (B10) |
| Invite a teammate | `POST /team`, `/team/send` | ✅ exists, but web only by decision. Keep the web sheet. |
| Ask Genie | see 2.3 | 🟡 |

### 2.6 Inbox (`features/inbox`) 🟡

Filters: All, Unread, Mentions, Decisions. Item kinds: brief, mention, activity, report, slipped, decision. "New" offers: message someone, post to the team, new task.

| Feature | API | Status |
|---|---|---|
| Brief | `GET /dashboard` → `brief` | ✅ |
| Activity (joined, changed) | `GET /dashboard` → `changes` | ✅ |
| Announcements | `GET /hr/announcements` | ✅ |
| Approvals waiting | `GET /hr/approvals` | ✅ |
| Slipped (overdue tasks, goals behind) | derived from goals ✅ and PATM tasks 🟡 | 🟡 |
| Mentions | none | ❌ needs the notifications inbox (B1) |
| Reports | daily reports | ❌ B7 |
| Decisions | see 2.10 | ❌ B2 |
| Read state, mark all read | `GET /notifications`, `POST /notifications/:id/read` | ❌ proposed only (B1); keep read state on the phone until then |
| Post to the team | `POST /hr/announcements` | ✅ exists, web only by decision. Enable for founders, or open the web. |
| Message someone | none | ❌ no team chat. Show "Call or email" as the app does now. |

### 2.7 Explore (`features/explore`) ✅

A hub of tiles with live counts. It needs no API of its own: counts come from the other modules.

| Tile | Where it goes | Status |
|---|---|---|
| Goals, Calendar, Delegated, Milestone, Team workload, Team | other modules | follows each module |
| Decisions, News, Genie suggests | other modules | ❌ (§2.10, 2.14, 2.15) |
| Projects, Portfolios | PATM | 🟡 needs B0 |
| Organisation, Business plan, Products, Helpdesk | web only (sheet) | ✅ as designed. Read APIs exist for later: `GET /hr/organisation`, `GET /business_plan/download`, `GET /offerings`. Helpdesk has no backend. |

### 2.8 Milestone (`features/milestone`) 🟡

Content:
- the road by stage (Foundation → Short → Mid → Long → BHAG)
- key results and plan targets
- goals carrying the milestone
- Genie's insight

| Feature | API | Status |
|---|---|---|
| Stage, progress, targets, KPIs | `GET /business_plan` (milestones with targets and KPIs) | 🟡 the read can start AI writing; needs B9 |
| Genie's insight | `GET /dashboard` → `milestone_reports` | ✅ |
| Rewrite the insight | `POST /dashboard/milestones/:id/report` (job) | ✅ |
| Goals carrying it | `GET /goals` | ✅ |
| Actual values for targets (current vs target) | finance / KPI actuals | ❌ B8; until then show baseline → target only |

### 2.9 Goals (`features/goals`) ✅ (mostly)

Screens: goals list, goal detail with key results, latest updates, ask for an update, share.

| Feature | API | Status |
|---|---|---|
| Plan goals by horizon | `GET /goals` | ✅ |
| Goals chain with key results | `GET /hr/goals?period=` | ✅ |
| Update progress / status | `PATCH /goals/:id`, `PATCH /hr/goals/:goal_id/key-results/:id` | 🟡 `PATCH /goals/:id` has no role check; allow only the owner in the app until B10 |
| Latest updates (history) | none | ❌ add an updates list to goals (B11) |
| Ask the owner for an update | none | ❌ needs notifications (B1) |
| Share | none | ❌ "Sharing comes with team chat" stays |

Two goal systems exist (plan goals and HR goals chain). The app should show them clearly named until product picks one.

### 2.10 Decisions (`features/decisions`) ❌

Cards: where the decision came from, tone (Off track · Needs a call · Ahead), title, effect, options. Pick, then Undo.

| Feature | API | Status |
|---|---|---|
| List open decisions | none | ❌ B2 |
| Pick an option / undo | none | ❌ B2 |
| HR approvals (leave, claims …) | `GET /hr/approvals`, `POST /hr/approvals/:id/decide` | ✅ these are not the same as the design's business decisions, but can sit in "Needs you" |

### 2.11 Calendar and meetings (`features/calendar`) 🟡

Screens: calendar by day, meeting sheet (join, going, organiser, agenda, "Ask Genie for notes").

| Feature | API (Calendar app) | Status |
|---|---|---|
| Meetings by day | `GET api/google_calendar_events` | 🟡 needs B0 |
| New meeting | `POST api/google_calendar_events` | 🟡 needs B0 |
| Edit | `PUT api/google_calendar_events/{id}` | 🟡 needs B0 |
| Going / Maybe / No | `PATCH api/google_calendar_events/{id}/rsvp` | 🟡 needs B0 |
| Free / busy when booking | `user_calendars.json?…&user_id=` | 🟡 needs B0 |
| Genie notes and agenda | none | ❌ part of B3 |
| Business Genie's own `/meetings` | proposed only | ❌ not needed if the Calendar app is used |

### 2.12 Projects and portfolios (`features/projects`) 🟡

Content: projects with owner, team, status, progress, steps and due date; portfolios grouping projects.

| Feature | API (PATM) | Status |
|---|---|---|
| Projects | `GET /project_managements.json` | 🟡 needs B0 |
| Steps | `GET /milestones.json?q[project_management_id_eq]=` (project milestones) | 🟡 needs B0 |
| Team | `GET /project_teams.json` | 🟡 needs B0 |
| Portfolio | project team or project type | 🟡 confirm with product which PATM field is the portfolio |
| Status and progress | PATM project status, tasks done / total | 🟡 needs B0 |

### 2.13 People (`features/people`) ✅ (mostly)

Screens: team list and a person sheet (role, today, email, phone, about, today's report, message).

| Feature | API | Status |
|---|---|---|
| Directory | `GET /hr/people` (`?q`, department, status) | ✅ |
| One person, reporting line, today | `GET /hr/people/:user_id` | ✅ |
| Live / in a meeting | attendance today ✅; meeting status from Calendar 🟡 | 🟡 |
| Behind | goals ✅ and PATM tasks 🟡 | 🟡 |
| Today's report | daily reports | ❌ B7 |
| Message | none | ❌ no team chat; call or email |

### 2.14 News (`features/news`) ❌

Content: headlines by kind (Industry, Competitors, Rules and tax, Customers, Your company), each with a summary and Genie's read "What this means for you".

| Feature | API | Status |
|---|---|---|
| News in your field with Genie's read | none | ❌ B5 (industry comes from `GET /organization` ✅) |
| Make a task from a story | PATM | 🟡 needs B0 |

### 2.15 Genie suggests (`features/news/news.dart`) ❌ (partly)

Content: cards with title, why, area, impact and an action (task · decision · ask Genie). Keep, let go, do it.

| Feature | API | Status |
|---|---|---|
| Suggestions | none | ❌ B6. `GET /dashboard` → `findings` and `brief.items` can stand in for v1 (🟡) |
| Keep / let go state | none | ❌ keep on the phone until B6 |

### 2.16 Search (`features/shell/search_screen.dart`) ✅

Searches what's loaded: tasks, goals, people, meetings, projects. No API needed. `GET /hr/people?q=` covers people beyond the loaded list.

### 2.17 Profile and settings (`features/profile`) 🟡

Content:
- theme (Automatic, Light, Dark) and demo data
- your companies
- notifications on/paused and do not disturb
- out of office
- your week so far (tasks done, meetings, decisions made)
- edit profile, help, sign out

| Feature | API | Status |
|---|---|---|
| Theme, demo data | stored on the phone | ✅ |
| Name, role, company | `GET /auth/me`, `GET /dashboard` | ✅ |
| Edit profile (phone, photo, timezone) | `GET/PATCH /profile` | ❌ proposed only (B4); keep "opens on the web" |
| Notification settings, do not disturb, out of office | none | ❌ B4 |
| Your companies (switch workspace) | none, a user belongs to one workspace | ❌ B12, or hide for v1 |
| Week so far: tasks done | PATM 🟡 · meetings: Calendar 🟡 · decisions made: ❌ | 🟡 |
| Sign out | local; `POST /auth/logout` proposed | 🟡 |

### 2.18 Web-only areas (sheets that say "opens on the web") ✅ as designed

Company setup, Business plan, Products, Organisation, Helpdesk, Invitations, Goal setting, Edit profile, Notification settings.

- The app only needs the web link.
- APIs exist for later phases for Business plan PDF, offerings and organisation.
- Helpdesk has no backend (`/helpdesk/tickets` proposed only).

### 2.19 Across the app

| Need | API | Status |
|---|---|---|
| Push notifications | `POST/DELETE /devices` | ❌ B1 |
| Notifications inbox | `GET /notifications` | ❌ B1 |
| Token refresh, revoke on sign-out | `POST /auth/refresh`, `/auth/logout` | ❌ B4 |
| AI jobs (brief, dictation, reports) | `GET /jobs/:id` | ✅ |
| Error envelope, 401, 423 (HR off) | as documented | ✅ (the earlier app's `ApiClient` handles them) |

### 2.20 HR self-service: APIs ready, no screens in the new UI

The backend marks 80 endpoints for the app, and about 60 of them are HR self-service. All are Ready. The earlier apps (`app/`, `buisness_genie_app/`) already have screens for several of them. The new UI has none: it touches HR only through Needs you (approvals), Team today (attendance) and Genie (HR desk).

| Area | Endpoints (all ✅) |
|---|---|
| Attendance | `GET /hr/attendance/today`, `POST /hr/attendance/check-in`, `check-out`, attendance requests (missed, WFH, on duty), `GET /hr/attendance/month` |
| Leave and holidays | `GET /hr/leave/types`, `balances`, `ledger`, `requests`; `POST /hr/leave/draft`, `requests`, `comp-off`, cancel; `GET /hr/holidays/mine` |
| Roster | `GET /hr/shift-assignments`, `GET /hr/roster`, swaps (ask, respond) |
| Approvals (full) | `GET /hr/approvals`, `decide`, `ask`, `answer`, `withdraw` |
| Policies, letters, SOPs | read and sign policies; sign or decline letters; read SOPs, workflow steps |
| Pay and claims | `GET /hr/payslips` (+ PDF); claims and advances (start, lines with receipts, submit, withdraw) |
| Joining and exit | my tasks, tick, documents, resign, withdraw |
| Hiring | `GET /hr/interviews/mine`, `POST /hr/interviews/:id/feedback` |
| Desk flags | `GET /hr/desk/flags`, resolve |

Not in the timeline below. If product wants them in v1, it adds about **3 weeks for one Flutter developer**, with no backend work: check-in, leave and approvals take 1.5 weeks, and payslips, claims, policies and letters take 1.5 weeks. They can also ship as one "HR" area in v1.1.

---

## 3. Scoreboard

| # | Module | API | What's missing |
|---|---|---|---|
| 1 | Sign-in and first run | 🟡 | Google sign-in, token refresh/logout |
| 2 | Home | 🟡 | PATM/Calendar access, decisions, daily reports, finance actuals, read-only milestones |
| 3 | Genie | 🟡 | Business chat (and voice), PATM access for drafts |
| 4 | Tasks | 🟡 | PATM access (B0) |
| 5 | Create | 🟡 | PATM/Calendar access; goal role check |
| 6 | Inbox | 🟡 | Notifications inbox, mentions, reports, decisions |
| 7 | Explore | ✅ | none of its own |
| 8 | Milestone | 🟡 | Read-only milestone endpoint; KPI actuals |
| 9 | Goals | ✅ | Update history, ask for an update (nice to have) |
| 10 | Decisions | ❌ | Whole backend |
| 11 | Calendar and meetings | 🟡 | Calendar access (B0); Genie notes |
| 12 | Projects and portfolios | 🟡 | PATM access (B0) |
| 13 | People | ✅ | Daily reports, chat (nice to have) |
| 14 | News | ❌ | Whole backend |
| 15 | Genie suggests | ❌ | Whole backend (dashboard findings as a stopgap) |
| 16 | Search | ✅ | none |
| 17 | Profile and settings | 🟡 | Profile, notification settings, out of office, multi-company |
| 18 | Web-only areas | ✅ | none for v1 |

Counted:

| Status | Count | Modules |
|---|---|---|
| ✅ | **5** | Explore, Goals, People, Search, Web-only areas |
| 🟡 | **10** | Sign-in, Home, Genie, Tasks, Create, Inbox, Milestone, Calendar, Projects, Profile and settings |
| ❌ | **3** | Decisions, News, Genie suggests |

Push notifications and the notifications inbox are not modules of their own. They are needed across the app (§2.19, B1).

Sign-in is 🟡 only for Google sign-in and token refresh. The email-code path is ready, so v1 can ship it.

---

## 4. APIs the backend still has to build (priority order)

Each line names who it unblocks.

| # | Backend work | Unblocks | Proposed shape | Size |
|---|---|---|---|---|
| **B0** | **Business Genie sign-in for PATM and Calendar:** one token (or a token exchange) so the app can call PMS and Calendar as the signed-in person. Includes the user and org sync with PMS, and fixing the "Tools account not linked" error. | Tasks, Create, Calendar, Projects, Home (tasks, schedule, trends), Genie drafts | `POST /tools/token` → `{ spree_token, org_base_url }`, or PMS accepts the Business Genie token | 1–2 weeks, **critical path** |
| B1 | Push and notifications inbox | Inbox (mentions, read state), ask for an update, every alert | `POST/DELETE /devices`, `GET /notifications`, `POST /notifications/:id/read` | 1–1.5 weeks |
| B2 | Decisions | Decisions, Needs you, Inbox, week stats | `GET /decisions` → `{ id, source, at, tone, title, effect, detail, options[], picked }`; `POST /decisions/:id/choose { option }`; `POST /decisions/:id/undo` | 1 week |
| B3 | Genie chat about the business | Genie chat, prep my meeting, plan my day, meeting notes, voice replies | `POST /genie/chat { message, thread_id }` → answer, cards, suggested actions (job or stream); `GET /genie/threads` | 2–3 weeks |
| B4 | Profile, settings and session | Profile, notification settings, out of office, safe sign-out | `GET/PATCH /profile`, `PATCH /profile/notifications`, `POST /auth/refresh`, `POST /auth/logout` | 1 week |
| B5 | News in your field with Genie's read | News | `GET /news?kind=` → `{ id, kind, title, source, at, summary, take, url }` (feed source + AI take, cached daily) | 1.5 weeks |
| B6 | Genie suggestions | Genie suggests, Home | `GET /suggestions` → `{ id, title, why, area, impact, action, ref }`; `POST /suggestions/:id/keep\|dismiss\|done` | 1 week (after B3) |
| B7 | Daily reports | Team today, Inbox reports, person sheet | `GET /daily-reports?date=`, `POST /daily-reports` | 1 week |
| B8 | Finance and KPI actuals | Trends (revenue), Milestone targets | `GET /finance/actuals?metric=&from=&to=`, `POST /finance/actuals` | 1–1.5 weeks |
| B9 | Read-only milestones (no AI start) | Milestone, Home hero | `GET /business_plan/milestones` → milestones with stage, targets, KPIs, progress | 2 days |
| B10 | Role checks on goal and plan writes | Goal progress updates, Create → Goal | founder/admin, or the goal owner for `PATCH /goals/:id` | 2 days |
| B11 | Goal update history | Goal detail "Latest" | `GET /goals/:id/updates`, `POST /goals/:id/updates` | 3 days |
| B12 | Several companies per user (if product wants it) | Profile → Your companies | `GET /workspaces`, token per workspace | 1 week (or drop for v1) |
| B13 | Google Workspace sign-in (if product wants it) | Sign-in | `POST /auth/google { id_token }` | 3–4 days (or hide the button) |

Fixes from `API.md` §5.2 that matter for the app:
- Role checks on goal and plan writes (B10).
- `GET /dashboard` starts the brief as an AI job on its first read. That's acceptable, because the app polls `/jobs/:id`.
- Switch the server to production mode, so errors don't return stack traces.

---

## 5. Timeline

**Assumptions:**
- **Team:** 2 Flutter developers (F1, F2) and 1 backend developer (BE). Design is done, and it's this app.
- **Starting point:** port the earlier app's network layer rather than rewriting it. That means `app/lib/core/network/api_client.dart`, `json.dart`, `api_exception.dart`, `core/storage`, `core/config`, and the auth, workspace, business, team, desk and approvals repositories, adapted to this app's `AppState`. That saves about a week.
- **Weeks run Monday to Friday.** Week 1 is short (Tue 3 – Fri 6 Nov). Christmas week is planned at half speed, and 1 Jan is a holiday.

### Phase 0: Foundation (3–6 Nov)

| Who | Work |
|---|---|
| F1 | Port the API client, token store, environment config and error envelope. Add a `LiveSource` behind `GenieData.load()` that builds the `Snapshot` from the API, and keep sample data as demo mode. |
| F2 | Sign-in on the API: email code, onboarding check, `GET /hr` role and menu, the "no account" and "finish setup on the web" states, and hiding Google sign-in for now. |
| BE | **B0 starts** (PATM/Calendar token and user sync). B9 and B10 (small). |

### Phase 1: Modules whose APIs are ready (9–20 Nov)

| Who | Work |
|---|---|
| F1 | Home on the API: dashboard brief with job polling, milestone hero (B9), Goals section, Team today from `/hr/overview`, Needs you from approvals and goals behind. Milestone screen with insight and targets. |
| F2 | Goals (both models, detail, key-result updates for owners), People (directory, person sheet), Inbox (brief, activity, announcements, approvals; read state on the phone), Genie (brief, dictation, HR desk answers). |
| Both | Explore counts, Search, Profile basics (name, company, theme, sign out), error, empty and offline states on every screen. |
| BE | Finish **B0**, then **B1** (devices and notifications), then **B4** (profile, refresh, logout). |

**Checkpoint, Fri 20 Nov:**
- B0 is working in the demo workspace.
- Every ✅ module runs on live data.
- An internal build goes out (TestFlight and Play internal track).

### Phase 2: PATM and Calendar (23 Nov – 11 Dec)

| Who | Work |
|---|---|
| F1 | Tasks: list, board, timeline, team, delegated, Only me (to-dos), detail with notes, comments, move, priority, timer and delete; new task and sub-task with owner, due date and priority; "Written by Genie". |
| F2 | Calendar and meetings (by day, meeting sheet, RSVP, new meeting with free/busy), Projects and portfolios (list, steps, team), Create sheet (task, reminder, meeting), Home sections (My tasks, Today's schedule, Projects, tasks-done trend). |
| BE | **B2** (decisions), then **B3** (Genie chat, 2–3 weeks; continues into Phase 3). |

**Checkpoint, Fri 11 Dec:**
- Tasks, Calendar, Projects and Create work end to end against PATM and Calendar.
- Second internal build.

If B0 is late, Phase 1 polish and Phase 3 app work move forward and PATM work shifts by the same amount.

### Phase 3: New backend modules (14 Dec – 1 Jan)

| Who | Work |
|---|---|
| F1 | Push notifications (FCM/APNs setup, device registration, opening the right screen), the notifications inbox (mentions, read state on the server), Decisions (list, choose, undo, in Needs you and Inbox), Profile and settings (B4). |
| F2 | Genie chat on B3: answers with cards and actions, draft task → PATM, prep my meeting, plan my day; voice mode with dictation and spoken replies. The phone's canned answers stay as the fallback. |
| BE | **B6** (suggestions), **B5** (news), **B7** (daily reports), then **B8** (finance actuals). |

**Checkpoint, Thu 31 Dec:**
- Decisions, notifications, profile and Genie chat are live.
- Third internal build.

### Phase 4: Finish, test and release (4–15 Jan)

| Who | Work |
|---|---|
| F1 | News and Genie suggests on B5/B6. Trends on B8 (revenue) and B7 (reports). Goal history if B11 lands. |
| F2 | Full regression on Android and iOS, performance (cold start, scrolling, Genie open), accessibility (text size, reduce motion, screen reader), analytics, crash reporting. |
| Both | Fix list, store listings, privacy labels, release builds. |
| BE | Bug fixes, production mode, load check on dashboard and Genie chat. |

**Release target:** store submission **Fri 15 Jan 2027**, public release in the week of **18 Jan** after review.

### At a glance

| Week | Dates | Flutter | Backend |
|---|---|---|---|
| 1 | 3–6 Nov | Foundation, sign-in | B0 starts, B9, B10 |
| 2 | 9–13 Nov | Home, Milestone, Goals, People | B0 |
| 3 | 16–20 Nov | Inbox, Genie (brief, desk, voice-to-text), states · **internal build 1** | B0 done, B1 |
| 4 | 23–27 Nov | Tasks list and detail, Calendar | B1, B4 |
| 5 | 30 Nov – 4 Dec | Tasks layouts, new task; Projects; Create | B2 |
| 6 | 7–11 Dec | Home PATM sections, timer, comments · **internal build 2** | B3 |
| 7 | 14–18 Dec | Push, notifications inbox, Decisions; Genie chat | B3 |
| 8 | 21–25 Dec (half week) | Profile and settings; Genie chat and voice | B3 done, B6 |
| 9 | 28 Dec – 1 Jan | Polish · **internal build 3** | B5, B7 |
| 10 | 4–8 Jan | News, Suggestions, Trends; regression | B8, fixes |
| 11 | 11–15 Jan | Fixes, store submission | Fixes, production mode |

### If something slips

Each module can ship without its missing API:
- **No B0 by 4 Dec:** Tasks, Calendar and Projects ship as "opens on the web" sheets (the app already has this pattern), and v1 ships without them.
- **No B3:** Genie keeps today's brief, HR answers and dictation; business chat follows in v1.1.
- **No B5, B6, B7 or B8:** hide News, Genie suggests, reports and the revenue trend, or show them with a clear "coming soon" state. Suggestions can use dashboard findings.
- **Decisions without B2:** hide the Decisions tile and layout; Needs you shows approvals and goals behind.

**Minimum viable v1**, built only on APIs that are ready today, is Phases 0–1 plus the release work. That is about 5 weeks, which means a store submission around **Fri 4 Dec 2026**.

---

## 6. Decisions needed from product

1. **Google Workspace sign-in:** build it (B13) or hide the button for v1?
2. **Your companies:** does one person need several workspaces (B12)?
3. **Goals:** show plan goals and the HR goals chain separately, or pick one?
4. **Posting from the app:** announcements and invitations exist but are web only. Should founders post from the phone?
5. **Portfolios:** which PATM field groups projects (project team or project type)?
6. **Decisions vs approvals:** are HR approvals part of "Decisions", or only of "Needs you"?
7. **Minimum v1:** ship on 4 Dec with ready APIs only, or wait for the full release on 15 Jan?
8. **HR self-service:** add screens for check-in, leave, payslips and claims in v1 (+3 weeks, §2.20), or leave them for v1.1?
