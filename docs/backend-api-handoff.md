# Business Genie app: API handoff for the backend team

**For:** the backend developers who build and fix the APIs the new Business Genie app needs.
**Written:** Wed 4 Nov 2026, from the new UI/UX app in `business_genie/` (18 modules, all on sample data today).
**Checked against:** `buisness_genie_app/docs/API.md` (all 355 endpoints, live-tested 25 Oct), `Business_Genie_API.postman_collection.json` and `docs/patm-calendar-field-map.md` (PATM and Calendar requests).

## In short

- The app has **18 modules**. Every screen is designed and built on sample data. The app team now wires each screen to the API.
- **5 modules have every API they need**, **10 are missing one piece**, and **3 have no backend at all**.
- **The one thing that blocks most of the app is B0:** the app cannot call PATM (tasks, to-dos, projects) or the Calendar app with a Business Genie sign-in. Tasks, Calendar, Projects, Create and half of Home wait on it.
- **13 pieces of backend work** are listed in §4 (B0–B13), in priority order, each with the request and response the app expects. A further **9 fixes to endpoints that already exist** are in §5.
- **Field names in §4 match the app's data model** (`lib/data/models.dart`), so if the backend sends these names the app maps them one to one.

| What the backend needs to do | Count | Most urgent |
|---|---|---|
| New APIs to build | 13 (B0–B13) | **B0** PATM and Calendar sign-in, then **B1** push and notifications |
| Fixes to APIs that exist | 9 | Role checks on goal writes; production mode |
| APIs ready, nothing to do | about 40 used by the app | — |

---

## 1. How to read this file

- **Paths** leave out the API root. `/dashboard` means `https://business-genie.gophygital.work/api/genie/dashboard`. PATM paths (`/task_managements.json`) are on the PMS server; Calendar paths (`api/google_calendar_events`) are on the Calendar app server.
- **Status:**

  | Mark | Meaning |
  |---|---|
  | ✅ | Exists and works on the live server. Nothing to do. |
  | 🟡 | Exists, but has a gap (named), or the app can't reach it yet (needs B0). |
  | ❌ | Doesn't exist. The backend has to build it. |

- **Conventions the new endpoints should follow** (the same as today's Business Genie API, see `API.md` §1):
  - Sign-in token in `Authorization: Bearer <token>`. Never trust an `org_id` sent by the app; use the signed-in person's workspace.
  - Success: `{ "ok": true, ...data }`. Error: `{ "ok": false, "error": "One sentence for the person" }`, plus `errors` by field on forms.
  - Slow AI work answers `202 { ok, job, poll }`; the app polls `GET /jobs/:id`.
  - Dates `YYYY-MM-DD`, timestamps ISO 8601 with offset, times of day `HH:MM`.
  - Lists that can grow long take `?page=&per=` and answer `total`, `page`, `per`.

---

## 2. Modules and their APIs

The app's tabs are **Home · Tasks · Create · Inbox · Explore · Milestone**. Genie opens full screen from Home.

### Scoreboard

| # | Module | API | What is missing (backend work) |
|---|---|---|---|
| 1 | Sign-in and first run | 🟡 | Token refresh and sign-out (B4); Google sign-in (B13, optional) |
| 2 | Home | 🟡 | PATM and Calendar access (B0), decisions (B2), daily reports (B7), revenue (B8), read-only milestones (B9) |
| 3 | Genie | 🟡 | Business chat and voice (B3); PATM access for drafted tasks (B0) |
| 4 | Tasks | 🟡 | PATM access (B0) |
| 5 | Create | 🟡 | PATM and Calendar access (B0); role check on goal writes (B10) |
| 6 | Inbox | 🟡 | Notifications inbox and mentions (B1), daily reports (B7), decisions (B2) |
| 7 | Explore | ✅ | Nothing of its own (counts come from other modules) |
| 8 | Milestone | 🟡 | Read-only milestones (B9); KPI actuals (B8) |
| 9 | Goals | ✅ | Update history (B11) and "ask for an update" (B1), both nice to have |
| 10 | Decisions | ❌ | Whole backend (B2) |
| 11 | Calendar and meetings | 🟡 | Calendar access (B0); Genie meeting notes (B3) |
| 12 | Projects and portfolios | 🟡 | PATM access (B0) |
| 13 | People | ✅ | Daily reports (B7), nice to have |
| 14 | News | ❌ | Whole backend (B5) |
| 15 | Genie suggests | ❌ | Whole backend (B6) |
| 16 | Search | ✅ | Nothing |
| 17 | Profile and settings | 🟡 | Profile and notification settings (B4); several companies (B12, optional) |
| 18 | Web-only areas | ✅ | Nothing (these screens only open a web link) |

Push notifications are used across the app and are part of B1.

### 2.1 Sign-in and first run 🟡

The person types a work email, gets a 6-digit code, and is signed in. If the company hasn't finished setup on the web, the app sends them there.

| What the app needs | Endpoint | Status | Note for backend |
|---|---|---|---|
| Send the code | `POST /auth/login { email }` | ✅ | `no_account: true` on 404 is used for the "create your workspace on the web" popup |
| Check the code, get a token | `POST /auth/login/verify { email, code }` | ✅ | 15-day token |
| Who am I | `GET /auth/me` | ✅ | |
| Is setup finished | `GET /onboarding` | ✅ | `step != "done"` → "finish on the web" |
| Role and menu | `GET /hr` | ✅ | `me.nav`, `me.can`, `me.manager` |
| Stay signed in | `POST /auth/refresh` | ❌ | **B4.** Today the app signs people out after 15 days with no warning |
| Sign out properly | `POST /auth/logout` | ❌ | **B4.** Today a lost phone keeps access until the token expires |
| "Continue with Google Workspace" | `POST /auth/google` | ❌ | **B13**, only if product keeps the button |

### 2.2 Home 🟡

The owner's day: the milestone with 3 numbers, a day ribbon, "Needs you", quick actions, my tasks, today's schedule, projects, goals, team today, trends, a news ticker and "Genie suggests". The owner can reorder or hide sections (stored on the phone).

| Section | Endpoint | Status | Note for backend |
|---|---|---|---|
| Company, owner, weekly brief, recent changes | `GET /dashboard` | ✅ | The brief can come as a job (`brief_job`); the app polls |
| Milestone highlight | `GET /dashboard` → `milestone_reports`, plus the milestone itself | 🟡 | The milestone list only lives inside `GET /business_plan`, whose first read can start AI writing. **B9** adds a read-only milestone endpoint |
| Needs you: approvals | `GET /hr/approvals?scope=to_decide` | ✅ | |
| Needs you: goals behind | `GET /goals`, `GET /hr/goals` | ✅ | |
| Needs you: decisions | `GET /decisions` | ❌ | **B2** |
| My tasks | PATM `GET /task_managements.json` | 🟡 | Needs **B0** |
| Today's schedule | Calendar `GET api/google_calendar_events` | 🟡 | Needs **B0** |
| Projects | PATM `GET /project_managements.json` | 🟡 | Needs **B0** |
| Goals | `GET /goals`, `GET /hr/goals` | ✅ | |
| Team today: who is in, late, on leave | `GET /hr/overview`, `GET /hr/attendance/daily` | ✅ | |
| Team today: who has sent a daily report | `GET /daily-reports?date=` | ❌ | **B7** |
| Trends: revenue, last 8 weeks | `GET /finance/actuals?metric=revenue` | ❌ | **B8** |
| Trends: tasks done per day, days on plan | worked out from PATM tasks | 🟡 | Needs **B0** |
| News ticker | `GET /news` | ❌ | **B5** |
| Genie suggests button | `GET /suggestions` | ❌ | **B6** (dashboard `findings` can stand in until then) |
| Switch company | `GET /workspaces` | ❌ | **B12**, optional |

### 2.3 Genie 🟡

Genie opens full screen: today's brief, chat with starter prompts ("Plan my day", "Prep my meeting", "Review my week"), voice mode, and tasks Genie drafts for the owner to add.

| What the app needs | Endpoint | Status | Note for backend |
|---|---|---|---|
| Today's brief | `GET /dashboard` → `brief`; rewrite with `POST /dashboard/brief` | ✅ | |
| Speak instead of typing | `POST /dictations` (audio file → text, job) | ✅ | |
| HR questions (leave left, policy) | `POST /hr/desk/ask` | ✅ | AI answers are switched off on live (`GET /hr/ai` → `allowed: false`); the HR owner switches them on |
| Chat about the business: goals, team, tasks, meetings | `POST /genie/chat` | ❌ | **B3.** The most visible gap: today the app answers with canned replies on the phone |
| Plan my day, prep my meeting, review my week | `POST /genie/chat` with an intent | ❌ | **B3** |
| Past chats | `GET /genie/threads` | ❌ | **B3** |
| Live voice conversation | `POST /genie/chat` + speech on the phone | ❌ | **B3.** v1 can record → `POST /dictations` → chat → read the answer aloud on the phone |
| Add a task Genie drafted | PATM `POST /task_managements.json` | 🟡 | Needs **B0** |

### 2.4 Tasks 🟡

Tasks in 7 layouts (List, Board, Timeline, Calendar, Decisions, Team, Goals), task detail (notes, comments, move, priority, timer, delete), a new task / sub-task sheet, Delegated, Only me (private reminders) and Plan my day. **All of it is PATM.** Business Genie's proposed `/tasks` is not needed if PATM is used.

| What the app needs | PATM endpoint | Status | Note for backend |
|---|---|---|---|
| List tasks (mine, delegated, team) | `GET /task_managements.json` with owner, status and date filters | 🟡 | Needs **B0** |
| New task or sub-task | `POST /task_managements.json` (`title`, `responsible_person_id`, `target_date`, `priority`, `parent_id` for a sub-task) | 🟡 | Needs **B0**. Fields in `docs/patm-calendar-field-map.md` |
| Done, reopen, move | `PUT /task_managements/{id}/update_status.json` | 🟡 | Needs **B0** |
| Start or stop the timer | same endpoint, `started` / `stopped` | 🟡 | Needs **B0** |
| Comments | `POST /comments.json` (`commentable_type: TaskManagement`) | 🟡 | Needs **B0** |
| Only me (private reminders) | `GET /todos.json`, `POST /todos.json` | 🟡 | Needs **B0** |
| People to assign | `GET /pms/users/get_escalate_to_users.json?type=Task` | 🟡 | Needs **B0** |
| Priority star | PATM `priority` | 🟡 | The app's star maps to High / Urgent |
| Delete a task | PATM delete | 🟡 | **Please confirm the delete endpoint** with the PATM team |
| "Written by Genie" label | PATM task `source` field | 🟡 | Needs **B0**. The app sends `source: "genie"` |

### 2.5 Create 🟡

The centre button: "Just start typing", then Ask Genie, Task, Reminder (Only me), and under More: Meeting, Goal, Invite a teammate.

| Item | Endpoint | Status | Note for backend |
|---|---|---|---|
| Task | PATM `POST /task_managements.json` | 🟡 | Needs **B0** |
| Reminder | PATM `POST /todos.json` | 🟡 | Needs **B0** |
| Meeting | Calendar `POST api/google_calendar_events` | 🟡 | Needs **B0**. Opens on the web until then |
| Goal | `POST /goals` | 🟡 | **No role check today** (any employee can add a plan goal). **B10.** Opens on the web until then |
| Invite a teammate | `POST /team`, `POST /team/send` | ✅ | Web only by decision. The app shows a web link |
| Ask Genie | see 2.3 | 🟡 | |

### 2.6 Inbox 🟡

Everything that happened, with filters All / Mentions / Unread / Decisions. Item kinds: brief, mention, activity, report, slipped (overdue or behind), decision. Actions: Reply, Make a task, Open brief, Mark all as read.

| What the app needs | Endpoint | Status | Note for backend |
|---|---|---|---|
| Brief | `GET /dashboard` → `brief` | ✅ | |
| Activity (joined, changed) | `GET /dashboard` → `changes` | ✅ | |
| Announcements | `GET /hr/announcements` | ✅ | |
| Approvals waiting | `GET /hr/approvals` | ✅ | |
| Slipped: goals behind | `GET /goals`, `GET /hr/goals` | ✅ | |
| Slipped: overdue tasks | PATM tasks | 🟡 | Needs **B0** |
| Mentions | `GET /notifications?kind=mention` | ❌ | **B1** |
| Read / unread, mark all as read | `GET /notifications`, `POST /notifications/:id/read`, `POST /notifications/read-all` | ❌ | **B1.** Until then the app keeps read state on the phone |
| Daily reports | `GET /daily-reports` | ❌ | **B7** |
| Decisions | `GET /decisions` | ❌ | **B2** |
| Reply | no team chat | ❌ | Not planned. The app offers call or email |
| Post to the team | `POST /hr/announcements` | ✅ | Web only by decision |

### 2.7 Explore ✅

A hub of tiles with live counts: Goals, Calendar, Delegated, Milestone, Projects, Portfolios, Team workload, People, Decisions, News, Genie suggests, and web-only tiles. It has no API of its own; each tile follows its module.

### 2.8 Milestone 🟡

The road by stage (Foundation → Short → Mid → Long → BHAG), the milestone's key results and plan targets, the goals carrying it, and Genie's insight.

| What the app needs | Endpoint | Status | Note for backend |
|---|---|---|---|
| Stages, current milestone, targets, KPIs | `GET /business_plan` | 🟡 | First read can start AI writing. **B9** adds `GET /business_plan/milestones` (read only) |
| Genie's insight | `GET /dashboard` → `milestone_reports` | ✅ | |
| Rewrite the insight | `POST /dashboard/milestones/:id/report` (job) | ✅ | |
| Goals carrying it | `GET /goals` | ✅ | |
| Current value of each target (current vs target) | `GET /finance/actuals` | ❌ | **B8.** Until then the app shows baseline → target only |

### 2.9 Goals ✅

Goals list by status, goal detail with key results, latest updates, ask the owner for an update, share.

| What the app needs | Endpoint | Status | Note for backend |
|---|---|---|---|
| Plan goals by horizon | `GET /goals` | ✅ | |
| Goals chain with key results | `GET /hr/goals?period=` | ✅ | |
| Update progress or status | `PATCH /goals/:id` | 🟡 | **No role check: anyone can edit any goal.** **B10** |
| Update a key result | `PATCH /hr/goals/:goal_id/key-results/:id` | ✅ | |
| Latest updates on a goal | `GET /goals/:id/updates` | ❌ | **B11** |
| Ask the owner for an update | push + notification | ❌ | **B1** |
| Share a goal | no team chat | ❌ | Not planned |

There are **two goal systems** (plan goals at `/goals`, the HR goals chain at `/hr/goals`) that don't stay in sync. The app shows both, clearly named, until product picks one (§6).

### 2.10 Decisions ❌

Cards for business calls the owner has to make: where it came from, a tone (Off track · Needs a call · Ahead), the title, its effect, and 2–3 options. The owner picks one, with Undo.

| What the app needs | Endpoint | Status | Note for backend |
|---|---|---|---|
| Open decisions | `GET /decisions` | ❌ | **B2** |
| Pick an option | `POST /decisions/:id/choose` | ❌ | **B2** |
| Undo a pick | `POST /decisions/:id/undo` | ❌ | **B2** |
| HR approvals (leave, claims) | `GET /hr/approvals`, `POST /hr/approvals/:id/decide` | ✅ | These are a different thing; the app shows them in "Needs you" |

### 2.11 Calendar and meetings 🟡

A week strip with a day list, a Live tag and Join, and a meeting sheet (going, organiser, agenda, "Ask Genie for notes"). **This is the Calendar app.** Business Genie's proposed `/meetings` is not needed if the Calendar app is used.

| What the app needs | Calendar endpoint | Status | Note for backend |
|---|---|---|---|
| Meetings for a day or week | `GET api/google_calendar_events` | 🟡 | Needs **B0** |
| New meeting | `POST api/google_calendar_events` | 🟡 | Needs **B0** |
| Edit a meeting | `PUT api/google_calendar_events/{id}` | 🟡 | Needs **B0** |
| Going / Maybe / No | `PATCH api/google_calendar_events/{id}/rsvp` | 🟡 | Needs **B0** |
| Free / busy when booking | `user_calendars.json?…&user_id=` | 🟡 | Needs **B0** |
| Genie's notes and agenda | `POST /genie/chat` with `intent: "meeting_notes"` | ❌ | **B3** |

### 2.12 Projects and portfolios 🟡

Projects with owner, team, status, progress, steps and due date; portfolios group projects. **All PATM.**

| What the app needs | PATM endpoint | Status | Note for backend |
|---|---|---|---|
| Projects | `GET /project_managements.json` | 🟡 | Needs **B0** |
| Steps | `GET /milestones.json?q[project_management_id_eq]=` | 🟡 | Needs **B0** |
| Team | `GET /project_teams.json` | 🟡 | Needs **B0** |
| Portfolio | project team or project type | 🟡 | **Product to confirm which PATM field is the portfolio** |
| Status and progress | project status; tasks done ÷ total | 🟡 | Needs **B0** |

### 2.13 People ✅

The team list and a person sheet: role, today's status, email, phone, about, today's report, message.

| What the app needs | Endpoint | Status | Note for backend |
|---|---|---|---|
| Directory | `GET /hr/people?q=&department_id=&status=&page=&per=` | ✅ | |
| One person, reporting line, today | `GET /hr/people/:user_id` | ✅ | |
| "In a meeting" now | Calendar | 🟡 | Needs **B0** |
| "Behind" | goals ✅, PATM tasks 🟡 | 🟡 | Needs **B0** for tasks |
| Today's report | `GET /daily-reports?user_id=&date=` | ❌ | **B7** |
| Message | no team chat | ❌ | Not planned; call or email |

### 2.14 News ❌

Headlines from the company's field, by kind (Industry, Competitors, Rules and tax, Customers, Your company), each with a short summary and Genie's one-line read: "What this means for you". A story can become a task.

| What the app needs | Endpoint | Status | Note for backend |
|---|---|---|---|
| News with Genie's read | `GET /news?kind=` | ❌ | **B5.** The company's industry and location are already in `GET /organization` ✅ |
| Make a task from a story | PATM create task | 🟡 | Needs **B0** |

### 2.15 Genie suggests ❌

Cards for things Genie thinks are worth doing, each with the reason, the area, the impact and one action (make a task, open a decision, ask Genie). The owner keeps it, lets it go, or does it.

| What the app needs | Endpoint | Status | Note for backend |
|---|---|---|---|
| Suggestions | `GET /suggestions` | ❌ | **B6.** `GET /dashboard` → `findings` can stand in for v1 |
| Keep, let go, done | `POST /suggestions/:id/keep \| dismiss \| done` | ❌ | **B6.** Kept on the phone until then |

### 2.16 Search ✅

Searches what the app has loaded (tasks, goals, people, meetings, projects). `GET /hr/people?q=` ✅ finds people beyond the loaded list. Nothing to build.

### 2.17 Profile and settings 🟡

Account, theme, demo data, your companies, notifications and do not disturb, out of office, "Your week so far", review my week with Genie, help, sign out.

| What the app needs | Endpoint | Status | Note for backend |
|---|---|---|---|
| Name, role, company | `GET /auth/me`, `GET /dashboard` | ✅ | |
| Edit phone, photo, timezone | `GET /profile`, `PATCH /profile` | ❌ | **B4** |
| Notifications on or paused, do not disturb hours | `PATCH /profile/notifications` | ❌ | **B4** |
| Out of office | `PATCH /profile/out-of-office` | ❌ | **B4** |
| Your companies | `GET /workspaces` | ❌ | **B12**, optional |
| Your week so far: tasks done, meetings, decisions made | PATM 🟡, Calendar 🟡, decisions ❌ | 🟡 | **B0**, **B2** |
| Sign out | `POST /auth/logout` | ❌ | **B4** |
| Theme, demo data, home layout | kept on the phone | ✅ | No API needed |

### 2.18 Web-only areas ✅

One sheet with "Copy web link" for: company setup, business plan, products, organisation, helpdesk, invitations, goal setting, scheduling, edit profile, notification settings. The app only needs the web address. Nothing to build.

### 2.19 HR self-service (APIs ready, no screens in the new UI)

About 60 HR endpoints are Ready: check-in and check-out, leave, holidays, roster, full approvals, policies, letters, SOPs, payslips, claims and advances, joining and exit tasks, interview feedback, desk flags. The new UI has no screens for them yet. **Nothing for the backend to do;** product decides whether they come into v1 (§6).

---

## 3. Endpoints the app will call that already exist

Nothing to build here; they are listed so the backend knows what the app depends on and does not change them without telling the app team.

### 3.1 Business Genie (`/api/genie`)

| Method | Path | In plain words | Used by | Status |
|---|---|---|---|---|
| POST | `/auth/login` | Email a 6-digit sign-in code | Sign-in | ✅ |
| POST | `/auth/login/verify` | Check the code; answer the 15-day token and the user | Sign-in | ✅ |
| GET | `/auth/me` | The signed-in person | Sign-in, Profile | ✅ |
| GET | `/onboarding` | Which setup step the company is on | Sign-in | ✅ |
| GET | `/hr` | Is HR on; my menu keys and what I'm allowed to do | Sign-in, every screen | ✅ |
| GET | `/dashboard` | Company, recent changes, weekly brief, findings, milestone reports | Home, Genie, Inbox, Milestone | ✅ (first read of the day starts the brief job) |
| POST | `/dashboard/brief` | Write the weekly brief again (job) | Genie | ✅ |
| POST | `/dashboard/milestones/:id/report` | AI report on one milestone (job) | Milestone | ✅ |
| GET | `/jobs/:id` | Status and result of an AI job | Everywhere AI runs | ✅ |
| GET | `/goals` | Plan goals by horizon, with people and statuses | Goals, Home, Milestone, Inbox | ✅ |
| PATCH | `/goals/:id` | Change a goal's status, progress, owner or due date | Goals | 🟡 no role check (B10) |
| GET | `/hr/goals?period=` | Goals chain, company → department → person, with key results | Goals, Home | ✅ |
| PATCH | `/hr/goals/:goal_id/key-results/:id` | Set a key result's current value | Goals | ✅ |
| GET | `/hr/overview` | Today's attendance, items waiting, tiles | Home | ✅ |
| GET | `/hr/attendance/daily` | Who is in, late, absent today | Home (Team today) | ✅ |
| GET | `/hr/approvals?scope=to_decide` | HR requests waiting for me | Home (Needs you), Inbox | ✅ |
| POST | `/hr/approvals/:id/decide` | Approve or reject an HR request | Needs you | ✅ |
| GET | `/hr/announcements` | Company announcements | Inbox | ✅ |
| GET | `/hr/people` | People directory, searchable, paged | People, Search, task owners | ✅ |
| GET | `/hr/people/:user_id` | One person: profile, today, reporting line | People | ✅ |
| GET | `/hr/organisation` | Departments with heads; org chart | People, web-only sheet | ✅ |
| POST | `/hr/desk/ask` | Ask an HR question; answers at once | Genie | ✅ (AI kind off on live) |
| POST | `/dictations` | Voice note → text (job) | Genie, every text box | ✅ |
| GET | `/organization` | Company profile: industry, location | News (B5 input) | ✅ |
| GET | `/business_plan` | The whole plan, including milestones | Milestone (until B9) | 🟡 may start AI writing |

### 3.2 PATM (PMS server): reachable after B0

| Method | Path | In plain words | Used by |
|---|---|---|---|
| GET | `/task_managements.json` | Tasks, filtered by owner, status and dates | Tasks, Home, Inbox, People |
| POST | `/task_managements.json` | New task or sub-task | Tasks, Create, Genie, News |
| PUT | `/task_managements/{id}/update_status.json` | Done, reopen, move, start or stop the timer | Tasks |
| POST | `/comments.json` | Comment on a task | Tasks |
| GET, POST | `/todos.json` | Private reminders ("Only me") | Tasks, Create |
| GET | `/pms/users/get_escalate_to_users.json?type=Task` | People a task can be given to | Tasks, Create |
| GET | `/project_managements.json` | Projects | Projects, Home |
| GET | `/milestones.json?q[project_management_id_eq]=` | A project's steps | Projects |
| GET | `/project_teams.json` | Project teams | Projects |
| — | delete a task | Delete | Tasks (**endpoint to confirm**) |

### 3.3 Calendar app: reachable after B0

| Method | Path | In plain words | Used by |
|---|---|---|---|
| GET | `api/google_calendar_events` | Meetings in a date range | Calendar, Home, People |
| POST | `api/google_calendar_events` | New meeting | Calendar, Create |
| PUT | `api/google_calendar_events/{id}` | Edit a meeting | Calendar |
| PATCH | `api/google_calendar_events/{id}/rsvp` | Going / Maybe / No | Calendar |
| GET | `user_calendars.json?…&user_id=` | Someone's free and busy times | Calendar, Create |

---

## 4. APIs to build (priority order)

Each item says why it matters, which screens wait on it, the request and response the app expects, and the rules. Shapes are proposals: change names if you need to, but tell the app team.

| # | Work | Unblocks | Size | Priority |
|---|---|---|---|---|
| **B0** | PATM and Calendar with a Business Genie sign-in | Tasks, Calendar, Projects, Create, Home, Genie drafts | 1–2 weeks | **Critical: needed by 11 Dec** |
| B1 | Push notifications and notifications inbox | Inbox, every alert, "ask for an update" | 1–1.5 weeks | High |
| B2 | Decisions | Decisions, Needs you, Inbox, week stats | 1 week | High |
| B3 | Genie chat about the business | Genie chat, plan my day, prep my meeting, meeting notes, voice | 2–3 weeks | High |
| B4 | Profile, settings, refresh and sign-out | Profile, notification settings, safe sign-out | 1 week | High |
| B5 | News with Genie's read | News, Home ticker | 1.5 weeks | Medium |
| B6 | Genie suggestions | Genie suggests, Home | 1 week (after B3) | Medium |
| B7 | Daily reports | Team today, Inbox, person sheet | 1 week | Medium |
| B8 | Finance and KPI actuals | Revenue trend, milestone target values | 1–1.5 weeks | Medium |
| B9 | Read-only milestones | Milestone, Home highlight | 2 days | **Do early (small)** |
| B10 | Role checks on goal and plan writes | Goal updates, Create → Goal | 2 days | **Do early (small, security)** |
| B11 | Goal update history | Goal detail "Latest" | 3 days | Low |
| B12 | Several companies per person | Profile → Your companies, switch company | 1 week | Optional |
| B13 | Google Workspace sign-in | Sign-in button | 3–4 days | Optional |

### B0. PATM and Calendar with a Business Genie sign-in (critical)

**Why:** Tasks, meetings and projects live in PATM and the Calendar app. The app signs in to Business Genie only, and today it has no way to call PATM or Calendar as that person. `GET /tools` answers "Tools account not linked" (`sync_error: "… has no account in Tools yet"`) on the demo workspace.

**What the app needs:** one call after sign-in that returns what it needs to call PATM and Calendar as the signed-in person.

```json
// POST /api/genie/tools/token          (Bearer = the Business Genie token)
// 200
{ "ok": true,
  "pms":      { "base_url": "https://<pms host>",      "token": "<token PMS accepts>",      "user_id": 412, "expires_at": "2026-11-19T04:00:00Z" },
  "calendar": { "base_url": "https://<calendar host>", "token": "<token Calendar accepts>", "user_id": 412, "expires_at": "2026-11-19T04:00:00Z" } }
// 409 when the person has no PMS account yet
{ "ok": false, "error": "Your Tools account is being set up. Try again in a few minutes.", "setting_up": true }
```

Alternative: PMS and Calendar accept the Business Genie JWT directly. Either works for the app.

**Rules:**
- Create the PMS / Calendar user automatically when someone joins the workspace (or on first call), so `setting_up` is rare.
- Map the Business Genie person to the PMS user, so `responsible_person_id` and `GET /hr/people` ids can be matched. Send `pms.user_id` in this answer, or add `pms_user_id` to `GET /hr/people`.
- Fix the demo workspace (Northwind) so its Tools account is linked.
- Confirm the PATM delete-task endpoint.

### B1. Push notifications and the notifications inbox

**Why:** without it the app only learns about new things when someone opens it. Inbox mentions, read state and "ask for an update" all need it.

```json
// POST /api/genie/devices
{ "token": "<FCM or APNs token>", "platform": "ios" }         // platform: ios | android
// 201 { "ok": true }

// DELETE /api/genie/devices/:token                               (on sign-out)
// 200 { "ok": true }

// GET /api/genie/notifications?kind=&unread=1&page=1&per=30
{ "ok": true, "total": 42, "unread": 5, "page": 1, "per": 30,
  "notifications": [ {
    "id": "n_981",
    "kind": "mention",              // brief | mention | activity | report | slipped | decision | approval | announcement
    "title": "Rohit mentioned you",
    "body": "Can we move the Runwal handover to Monday?",
    "actor_id": 14,                 // person who caused it, or null
    "ref": { "type": "task", "id": "T-221" },   // what to open: task | goal | decision | meeting | approval | brief
    "at": "2026-11-04T10:12:00+05:30",
    "unread": true } ] }

// POST /api/genie/notifications/:id/read       → { "ok": true }
// POST /api/genie/notifications/read-all       → { "ok": true, "unread": 0 }
```

**Send a push when:** someone mentions me, an approval is waiting for me, my request is decided, a goal I own is asked for an update, a decision needs me, a policy needs my signature, an announcement is posted. Each push carries `ref` so the app opens the right screen. Respect the person's do-not-disturb hours from B4.

### B2. Decisions

**Why:** Decisions is a whole module, and it also feeds Home "Needs you", the Inbox and "Your week so far". It does not exist at all today.

**What a decision is:** a business call for the owner, raised by Genie or a person, with 2–3 options. For example: "Field sales hiring is at 1 of 4. Post 2 contract roles now?"

```json
// GET /api/genie/decisions?status=open            // open | decided | all
{ "ok": true, "decisions": [ {
    "id": "D-31",
    "source": "Genie · from the Milestone 1 report",   // where it came from, shown as written
    "at": "2026-11-03T09:00:00+05:30",
    "tone": "off_track",                                // off_track | needs_call | ahead
    "title": "Field sales hiring is behind",
    "effect": "Milestone 1 slips by about 3 weeks",     // one line: what happens if nothing is done
    "detail": "1 of 4 hired by week 11 of 26.",         // optional, longer
    "options": ["Post 2 contract roles now", "Wait until December", "Lower the target to 3"],
    "picked": null,                                     // index of the chosen option, or null
    "decided_by": null, "decided_at": null } ] }

// POST /api/genie/decisions/D-31/choose   { "option": 0 }
// 200 { "ok": true, "decision": { ...same shape, "picked": 0, "decided_by": 2, "decided_at": "..." } }

// POST /api/genie/decisions/D-31/undo     (within 10 minutes of choosing)
// 200 { "ok": true, "decision": { ...same shape, "picked": null } }
```

**Rules:** only the founder, or the person the decision is addressed to, can choose. Undo is allowed for a short window (suggest 10 minutes) and only by the person who chose. Tell product whether a choice should create a task automatically.

### B3. Genie chat about the business

**Why:** the Genie panel is the centre of the app. Today the app answers with canned replies on the phone. HR Desk answers only HR questions.

**What it must know:** the business plan and milestones, goals and KPIs, the team, the person's tasks (PATM) and meetings (Calendar).

```json
// POST /api/genie/genie/chat
{ "thread_id": null,                 // null starts a new chat
  "message": "Why is on-time collection off?",
  "intent": null,                    // optional shortcut: plan_my_day | prep_meeting | review_week | meeting_notes
  "context": { "screen": "goal", "id": "G-12" } }   // optional: what the person is looking at

// 202 (slow) → poll /jobs/:id, or 200 (fast) with the answer:
{ "ok": true, "thread_id": "th_77",
  "answer": {
    "text": "It's at 78% against a 95% target. Three clients paid 20+ days late in September and October.",
    "sources": [ { "label": "KPI · On-time collection", "ref": { "type": "kpi", "id": "K-4" } },
                 { "label": "Tally · Oct invoices" } ],
    "cards": [ { "type": "task_draft", "title": "Move the 3 clients to 30-day terms",
                 "assignee_id": 14, "due": "2026-11-15" } ],   // types: task_draft | meeting | goal | decision
    "actions": [ "Make it a task", "Remind me Friday" ] } }

// GET /api/genie/genie/threads                → { ok, threads: [ { id, title, at, last } ] }
// GET /api/genie/genie/threads/:id            → { ok, id, messages: [ { from: "me"|"genie", text, at, sources, cards } ] }
// DELETE /api/genie/genie/threads/:id         → { ok }
```

**Rules:** answer only from data the person may see (same permissions as the screens). Never create or send anything on its own: a `task_draft` card is created only when the person taps Add, through PATM. Streaming the answer is welcome but optional; a job with polling is fine for v1.

### B4. Profile, settings, refresh and sign-out

**Why:** people can't change their own phone number or photo, notifications can't be paused, and a token can't be renewed or revoked.

```json
// GET /api/genie/profile
{ "ok": true, "profile": {
    "name": "Vikram Rao", "email": "vikram@lockated.com", "phone": "+91 98200 00000",
    "photo_url": null, "timezone": "Asia/Kolkata",
    "notifications": { "push": true, "paused_until": null, "quiet_from": "21:00", "quiet_to": "07:00" },
    "out_of_office": { "on": false, "from": null, "to": null, "note": null } } }

// PATCH /api/genie/profile                 { "phone": "...", "timezone": "..." }         (photo: multipart "photo")
// PATCH /api/genie/profile/notifications   { "push": true, "paused_until": "2026-11-05T09:00:00+05:30", "quiet_from": "21:00", "quiet_to": "07:00" }
// PATCH /api/genie/profile/out-of-office   { "on": true, "from": "2026-11-09", "to": "2026-11-11", "note": "Diwali" }

// POST /api/genie/auth/refresh   (Bearer = the current, still valid token)
// 200 { "ok": true, "token": "...", "expires_at": "..." }

// POST /api/genie/auth/logout    (revokes this token)
// 200 { "ok": true }
```

**Rules:** out of office should show on the person in `GET /hr/people/:user_id` (`today`), and pushes should respect quiet hours and pauses.

### B5. News with Genie's read

**Why:** the News module and the Home ticker. Nothing exists.

```json
// GET /api/genie/news?kind=&page=1&per=20       // kind: industry | competitors | rules | customers | company
{ "ok": true, "news": [ {
    "id": "nw_5521", "kind": "rules",
    "title": "GST e-invoicing threshold lowered to ₹2 Cr",
    "source": "Economic Times", "url": "https://...", "at": "2026-11-03T08:00:00+05:30",
    "summary": "From 1 April, companies above ₹2 Cr turnover must issue e-invoices.",
    "take": "You cross ₹2 Cr this year, so billing must switch before April." } ] }
```

**Rules:** pick stories by the company's industry, location, products and named competitors (`GET /organization`, `/offerings`). Write `take` once per story per company and cache it daily; don't run AI on every read.

### B6. Genie suggestions

**Why:** the "Genie suggests" module and its Home button. Build after B3, since it uses the same reasoning.

```json
// GET /api/genie/suggestions
{ "ok": true, "suggestions": [ {
    "id": "sg_88",
    "title": "Post 2 contract field sales roles",
    "why": "Hiring is at 1 of 4 in week 11; contract roles fill in about 2 weeks.",
    "area": "Sales", "impact": "Keeps Milestone 1 on pace",
    "action": "task",                     // task | decision | genie
    "cta": "Do it",
    "ref": "Post 2 contract field sales roles",  // task title, decision id, or the question for Genie
    "state": "new" } ] }                  // new | kept | dismissed | done

// POST /api/genie/suggestions/sg_88/keep      → { ok }
// POST /api/genie/suggestions/sg_88/dismiss   → { ok }
// POST /api/genie/suggestions/sg_88/done      → { ok }
```

**Until B6:** the app turns `GET /dashboard` → `findings` into suggestion cards.

### B7. Daily reports

**Why:** Home "Team today" shows who has reported, the Inbox shows reports, and the person sheet shows today's report.

```json
// GET /api/genie/daily-reports?date=2026-11-04&user_id=          // user_id optional; default = my team
{ "ok": true, "date": "2026-11-04", "reports": [ {
    "id": "dr_301", "user_id": 14, "name": "Arjun Nair",
    "done": "Two client demos; Kolte Patil pricing sent.",
    "next": "Shortlist field sales candidates.",
    "blockers": "CRM import stuck since Monday.",
    "at": "2026-11-04T18:40:00+05:30" } ],
  "missing": [ 21, 25 ] }                                       // people who haven't reported

// POST /api/genie/daily-reports   { "date": "2026-11-04", "done": "...", "next": "...", "blockers": "..." }
```

**Rules:** a person sees their own; managers see their team; the founder sees everyone.

### B8. Finance and KPI actuals

**Why:** the Home revenue trend (last 8 weeks) and the current value of each milestone target and KPI. Today the app can only show baseline → target.

```json
// GET /api/genie/finance/actuals?metric=revenue&from=2026-09-01&to=2026-11-04&every=week
{ "ok": true, "metric": "revenue", "unit": "INR", "points": [
    { "on": "2026-09-07", "value": 3820000 }, { "on": "2026-09-14", "value": 3910000 } ] }

// GET /api/genie/kpis/actuals?milestone_id=2
{ "ok": true, "kpis": [ {
    "id": "K-4", "name": "On-time collection", "unit": "%",
    "baseline": "80", "target": "95", "current": "78", "progress": 0.0,  // null until the first reading
    "owner_id": 14, "source": "Tally", "at": "2026-11-01" } ] }

// POST /api/genie/finance/actuals   { "metric": "revenue", "on": "2026-11-01", "value": 4120000, "source": "manual" }
```

**Rules:** values come from connected tools (Tally, Zoho Books) or are typed in on the web. `progress` is `null` until the first reading; never send 0 for "no data".

### B9. Read-only milestones (small, do early)

**Why:** the milestone list lives inside `GET /business_plan`, which can start AI writing (and spend tokens) on its first read. The app must not trigger that.

```json
// GET /api/genie/business_plan/milestones
{ "ok": true, "vision": "Be the operating system for India's real-estate communities.",
  "current": 1,
  "milestones": [ {
    "id": 1, "name": "Automate client onboarding and hire 4 field sales",
    "stage": "foundation",                 // foundation | short | mid | long | bhag
    "from": "2026-08-01", "to": "2027-01-31", "week": 11, "weeks": 26,
    "progress": 0.25,                      // targets done ÷ targets
    "targets": [ { "id": 11, "title": "Hire 4 field sales executives", "done": false, "owner_id": 14 } ],
    "kpis": [ { "name": "Field sales headcount", "target": "4", "current": "1" } ] } ] }
```

**Rules:** never start AI work. If the plan isn't written yet, answer `{ "ok": true, "milestones": [] }`.

### B10. Role checks on goal and plan writes (small, security)

**Why:** today any member, including an employee, can add, edit or delete plan goals and edit the business plan.

| Endpoint | Who may call it |
|---|---|
| `POST /goals`, `DELETE /goals/:id` | Founder and admin |
| `PATCH /goals/:id` | Founder, admin, or the goal's owner |
| `POST/PATCH/DELETE /business_plan/:section…`, `PUT /organization`, logo, departments, products, services, categories | Founder and admin |

Answer `403 { ok:false, error:"Only the founder or the goal's owner can change this goal." }` otherwise.

### B11. Goal update history

**Why:** goal detail shows "Latest" updates (who said what, when).

```json
// GET /api/genie/goals/:id/updates
{ "ok": true, "updates": [ { "id": 7, "text": "2 offers out, 1 accepted.", "by_id": 14, "by": "Arjun Nair",
                              "progress": 0.25, "at": "2026-11-02T17:00:00+05:30" } ] }

// POST /api/genie/goals/:id/updates   { "text": "...", "progress": 0.5 }    // also updates the goal's progress
```

### B12. Several companies per person (optional)

Only if product wants "Your companies" and "Switch company".

```json
// GET /api/genie/workspaces
{ "ok": true, "workspaces": [ { "id": 2, "name": "Lockated", "role": "Founder", "current": true } ] }
// POST /api/genie/workspaces/:id/switch   → { "ok": true, "token": "...", "expires_at": "..." }
```

### B13. Google Workspace sign-in (optional)

Only if product keeps the "Continue with Google Workspace" button.

```json
// POST /api/genie/auth/google   { "id_token": "<Google ID token>" }
// 200 same as /auth/login/verify; 404 { ok:false, no_account:true } if the email has no workspace
```

---

## 5. Fixes to endpoints that already exist

| # | Fix | Where | Why it matters for the app |
|---|---|---|---|
| 1 | Add role checks | Goal and plan writes (see B10) | Security: an employee can change company goals today |
| 2 | Switch the server to production mode | Whole server | Unknown paths and crashes return stack traces, not `{ ok:false, error }` |
| 3 | Don't start AI on a read | `GET /business_plan`, `/company_report`, `/discovery`, `/offerings` | The app opening a screen shouldn't spend AI tokens. B9 solves the milestone case |
| 4 | Link the Tools account for every workspace | `/tools*`, `/disc*` | Part of B0; the demo workspace isn't linked |
| 5 | Strip salary fields for non-founders | `GET /departments` | Every member sees salary bands and payroll totals |
| 6 | Show the join link only to founder and admin | `GET /team` | Every member sees the live invite link |
| 7 | Limit the founder interview to the founder | `GET /interview` | Every member can read it |
| 8 | One source for the weekly off | `GET /hr/leave/settings` vs the General shift | Saturdays are flagged "absent with no leave" |
| 9 | Default required dates | `/hr/attendance/month`, `/hr/roster` | A missing `month` or `from`/`to` answers a raw 422 |

---

## 6. Questions for product and backend

1. **B0 approach:** a token exchange (`POST /tools/token`), or PMS and Calendar accept the Business Genie token directly?
2. **Two goal systems:** keep plan goals (`/goals`) and the HR goals chain (`/hr/goals`) separate, link them both ways, or merge?
3. **Decisions vs approvals:** are HR approvals a kind of decision (one list), or separate (as designed)?
4. **Portfolios:** which PATM field groups projects: project team or project type?
5. **Decision → task:** should choosing an option create a task automatically?
6. **Google sign-in and several companies:** build B13 and B12, or hide those for v1?
7. **HR self-service:** do check-in, leave, payslips and claims come into v1? (No backend work; the app team needs about 3 weeks.)
8. **News sources:** which feeds or providers may the backend use, and is there a budget for them?
