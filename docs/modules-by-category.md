# Business Genie app: modules by category, and a solo-developer timeline

Written Tue 3 Nov 2026 from the new UI/UX app in `business_genie/` (commit `855c0fe`). Endpoint-level detail for every module is in [`modules-and-api-plan.md`](modules-and-api-plan.md). This file groups the modules and plans the work for **one Flutter developer**.

## Summary

- **18 modules** in 7 categories, plus one area with ready APIs but no screens yet (HR self-service).
- Every screen is designed and built on sample data. The remaining work is mostly **wiring each screen to the API** and handling the live states: loading, empty, errors and offline.
- **API status:** 5 modules ✅ ready · 10 🟡 partly ready · 3 ❌ no backend.
- **Solo timeline:**

  | Milestone | Date |
  |---|---|
  | Internal build 1: every ready-API module live | Fri 11 Dec 2026 |
  | Internal build 2: Tasks, Calendar, Projects on PATM | Fri 8 Jan 2027 |
  | Internal build 3: push, Decisions, Genie chat | Fri 5 Feb 2027 |
  | **Store submission** | **Fri 26 Feb 2027** (1 week buffer to 5 Mar) |
- **Smaller v1:** if it ships with only the APIs that work today, it can go to the stores around **Fri 18 Dec 2026**.

Legend: ✅ API ready · 🟡 API exists with a gap, or waits on PATM/Calendar access (B0) · ❌ no backend yet. Days are working days for one developer.

---

## 1. Modules by category

### A. Access and account

| # | Module | Code | Screens and features | Data from | API | Days |
|---|---|---|---|---|---|---|
| 1 | Sign-in and first run | `features/auth` | Splash, work email → 6-digit code, Google Workspace button, "Before you start" notice | Business Genie | 🟡 | 2 |
| 2 | Profile and settings | `features/profile` | Account, theme (Automatic/Light/Dark), demo data, your companies, notifications and do not disturb, out of office, "Your week so far", review my week with Genie, help, sign out | Business Genie + phone | 🟡 | 1 + 2.5 |
| 3 | Web-only areas | `shell/routes.dart` `showWebOnly` | One sheet with "Copy web link" for: company setup, business plan, products, organisation, helpdesk, invitations, goal setting, scheduling, edit profile, notification settings | none | ✅ | 0 |

### B. App frame and discovery

| # | Module | Code | Screens and features | Data from | API | Days |
|---|---|---|---|---|---|---|
| 4 | Create | `shell/create_sheet.dart` | "Just start typing" box; Ask Genie, Task, Reminder (Only me); More: Meeting, Goal, Invite a teammate | PATM, Calendar | 🟡 | 1 |
| 5 | Search | `shell/search_screen.dart` | One search over tasks, goals, people, meetings and projects | loaded data, `GET /hr/people?q=` | ✅ | 0.5 |
| 6 | Explore | `features/explore` | Hub with live counts: Goals, Calendar, Delegated, Milestone, Projects, Portfolios, Team workload, People, Decisions, News, Genie suggests, plus web-only tiles | other modules | ✅ | 0.5 |

The app shell (`features/shell/shell.dart`) holds the frosted tab bar (Home · Tasks · Create · Inbox · Explore · Milestone), the Genie island that folds in on scroll, and the full-screen Genie reveal. It needs no API and is counted in Foundation.

### C. Daily work

| # | Module | Code | Screens and features | Data from | API | Days |
|---|---|---|---|---|---|---|
| 7 | Home | `features/home` | Milestone highlight with 3 numbers, day ribbon, Needs you (full screen too), Quick actions, My tasks, Today's schedule, Projects, Goals, Team today, Trends and charts, news ticker, Genie suggests button, Customise home (order and hide sections), switch company | Business Genie + PATM + Calendar | 🟡 | 5 + 1.5 |
| 8 | Tasks | `features/tasks` | **Layouts:** List, Board, Timeline, Calendar, Decisions, Team, Goals. **Manage view:** show (All, Only mine, Priority, From Genie), group, sort, compact. **Detail:** notes, comments, move, priority, timer, delete. **Also:** new task and sub-task sheet, Delegated and Only me lists, Plan my day | PATM | 🟡 | 8 |
| 9 | Calendar and meetings | `features/calendar` | Week strip with previous/next, day list, Live tag and Join, meeting sheet (going, organiser, agenda, Ask Genie for notes) | Calendar app | 🟡 | 4 |
| 10 | Inbox | `features/inbox` | Filters All / Mentions / Unread / Decisions; brief, mention, activity, report, slipped and decision items; Reply, Make a task, Open brief; Mark all as read | Business Genie | 🟡 | 2 + (push in G) |

### D. Company direction

| # | Module | Code | Screens and features | Data from | API | Days |
|---|---|---|---|---|---|---|
| 11 | Milestone | `features/milestone` | Road by stage (Foundation → Short → Mid → Long → BHAG), key results and plan targets, goals carrying it, Genie's insight | Business Genie | 🟡 | 2 |
| 12 | Goals | `features/goals` | Goals list by status, goal detail with key results, latest updates, ask for an update, share | Business Genie (`/goals`, `/hr/goals`) | ✅ | 3 |
| 13 | Decisions | `features/decisions` | Decision cards: source, tone (Off track · Needs a call · Ahead), effect, options, pick and undo | none yet (B2) | ❌ | 2.5 |
| 14 | Projects and portfolios | `features/projects` | Projects with owner, team, status, progress, steps, due date; filter chips; Portfolios | PATM | 🟡 | 2 |

### E. Team

| # | Module | Code | Screens and features | Data from | API | Days |
|---|---|---|---|---|---|---|
| 15 | People | `features/people` | Team list, invite (web), person sheet: role, today, email, phone, about, today's report, message | Business Genie (`/hr/people`) | ✅ | 1.5 |

Team workload ("who carries what, who is behind") is the Team layout inside Tasks, so it is counted under Tasks.

### F. Genie (AI)

| # | Module | Code | Screens and features | Data from | API | Days |
|---|---|---|---|---|---|---|
| 16 | Genie | `features/genie` | Full-screen panel, today's brief, four starters, chat, dictation, voice mode (Listening, Mute, End), draft task to Add; on-phone fallback answers (`genie_brain.dart`) | Business Genie | 🟡 | 1.5 + 9 |
| 17 | Genie suggests | `features/news/news.dart` | Swipe deck (right keep, left let go), kept list, run a suggestion (decision, task, ask Genie), pulsing button on Home | none yet (B6) | ❌ | 2 |
| 18 | News | `features/news/news.dart` | Ticker on Home, news list by kind (Industry, Competitors, Rules and tax, Customers, Your company), "What this means for you", make a task | none yet (B5) | ❌ | 2 |

### G. Across the app (platform)

Not modules of their own, but every module needs them.

| Item | What | API | Days |
|---|---|---|---|
| Foundation | Port the API client, token store, config and error envelope from `app/`; a `LiveSource` behind `GenieData.load()`; keep sample data as demo mode | ✅ | 5 |
| States | Loading, empty, error and offline on every screen (the `DataMode` switch already shows them) | — | 1.5 |
| Push and notifications | FCM/APNs, device registration, open the right screen, server read state | ❌ B1 | 5 |
| Trends data | Revenue (finance actuals) and reports on Home | ❌ B7, B8 | 1 |
| Test and release | Android + iOS regression, performance, accessibility, crash reporting, analytics, store listings | — | 10 |

### H. Not in the new UI yet: HR self-service

Check-in/out, leave and holidays, roster swaps, full approvals, policies, letters, SOPs, payslips, claims and advances, joining/exit tasks, interview feedback. **About 60 Ready endpoints, no screens.** Not in the timeline below. Adding it costs about **15 days (3 weeks)** for one developer, with no backend work needed. See `modules-and-api-plan.md` §2.20.

### Category count

| Category | Modules | ✅ | 🟡 | ❌ |
|---|---|---|---|---|
| A. Access and account | 3 | 1 | 2 | 0 |
| B. App frame and discovery | 3 | 2 | 1 | 0 |
| C. Daily work | 4 | 0 | 4 | 0 |
| D. Company direction | 4 | 1 | 2 | 1 |
| E. Team | 1 | 1 | 0 | 0 |
| F. Genie (AI) | 3 | 0 | 1 | 2 |
| **Total** | **18** | **5** | **10** | **3** |

---

## 2. Solo-developer timeline

### Assumptions

- **One Flutter developer.** The backend team builds B0–B8 in parallel (list in `modules-and-api-plan.md` §4).
- **Order:** modules whose APIs work today come first, so nothing waits on the backend for the first 6 weeks.
- **Working days:** Mon–Fri. The plan counts 78 days in 17 weeks. Holidays are planned in:

  | Week | Off |
  |---|---|
  | 9 Nov | 2 days for Diwali |
  | Christmas week | 2 days |
  | 1 Jan | 1 day |
  | 26 Jan | 1 day (Republic Day) |
- **Effort:** each week's days add up to the module estimates in §1.

### Week by week

| Wk | Dates | Days | Work | Needs from backend |
|---|---|---|---|---|
| **Phase 1: Ready APIs** |||||
| 1 | Tue 3 – Fri 6 Nov | 4 | Foundation: API client, token store, config, error envelope, `LiveSource`, demo-mode switch | — |
| 2 | 9 – 13 Nov | 3 | Finish foundation · Sign-in on the API (email code, onboarding check, `GET /hr` role), hide Google sign-in | — |
| 3 | 16 – 20 Nov | 5 | Home on live data: brief with job polling, milestone highlight, Goals, Team today, Needs you (approvals, goals behind) | B9 read-only milestones (helpful) |
| 4 | 23 – 27 Nov | 5 | Milestone screen · Goals (both models, detail, key-result updates for owners) | B10 goal role check |
| 5 | 30 Nov – 4 Dec | 5 | People and person sheet · Inbox (brief, activity, announcements, approvals) · Genie basics (brief, dictation, HR desk) | — |
| 6 | 7 – 11 Dec | 5 | Explore counts, Search, Profile basics, live states everywhere · **internal build 1** | **B0 must be ready by 11 Dec** |
| **Phase 2: PATM and Calendar** |||||
| 7 | 14 – 18 Dec | 5 | Tasks: list, detail, new task / sub-task, done / reopen / move, comments | B0 |
| 8 | 21 – 25 Dec | 3 | Tasks: Board, Timeline, Team layouts, Only me (to-dos), timer, manage view | B0 |
| 9 | 28 Dec – 1 Jan | 4 | Calendar and meetings: day view, meeting sheet, RSVP, new meeting with free/busy | B0 |
| 10 | 4 – 8 Jan | 5 | Projects and portfolios · Create sheet (task, reminder, meeting) · Home PATM sections · **internal build 2** | B1 ready by 8 Jan |
| **Phase 3: New backend modules** |||||
| 11 | 11 – 15 Jan | 5 | Push notifications and the notifications inbox (mentions, read state) | B1 |
| 12 | 18 – 22 Jan | 5 | Decisions (list, pick, undo; in Needs you and Inbox) · Profile and settings, token refresh, sign-out | B2, B4 |
| 13 | 25 – 29 Jan | 4 | Genie chat: answers with cards and actions, draft task → PATM | B3 |
| 14 | 1 – 5 Feb | 5 | Genie: plan my day, prep my meeting, voice mode · **internal build 3** | B3 |
| **Phase 4: Finish and release** |||||
| 15 | 8 – 12 Feb | 5 | News · Genie suggests · Trends (revenue, reports) | B5, B6, B7, B8 |
| 16 | 15 – 19 Feb | 5 | Regression on Android and iOS, performance, accessibility, crash reporting, analytics | production mode on server |
| 17 | 22 – 26 Feb | 5 | Fix list, store listings, privacy labels, release builds · **store submission Fri 26 Feb** | — |
| Buffer | 1 – 5 Mar | 5 | Store review feedback, late fixes | — |

### Release options

| Option | What ships | Submit by |
|---|---|---|
| **Quick v1** | Phase 1 (11 modules on ready APIs: Sign-in, Profile, Web-only, Search, Explore, Home, Inbox, Milestone, Goals, People, Genie basics) + 1 week of release work. Tasks, Calendar and Projects stay "opens on the web". | **Fri 18 Dec 2026** |
| **Full v1** | All 18 modules | **Fri 26 Feb 2027** |
| **Full v1 + HR self-service** | All 18 modules + category H | **Fri 19 Mar 2027** (+3 weeks) |

### If the backend is late

- **B0 not ready by 11 Dec:** build HR self-service (category H) in weeks 7–9 instead, since its APIs already work. Move PATM and Calendar back by the same amount.
- **B3 (Genie chat) late:** Genie keeps the brief, dictation and HR desk, with on-phone answers as the fallback. Chat moves to v1.1.
- **B2, B5, B6 late:** hide Decisions, News and Genie suggests, or show a "coming soon" state. Genie suggests can use dashboard `findings` for now.
- **B1 late:** keep read state on the phone; the app refreshes when opened.

### Risks for a solo developer

- **No parallel track:** any backend delay stalls the app unless there is ready-API work to swap in. That's why HR self-service is the swap.
- **Testing:** one person testing two platforms. Keep the screenshot goldens and add widget tests per module as it goes live, not only in week 16.
- **Store review:** the first iOS review often comes back with notes, which is what the 1-week buffer is for.
