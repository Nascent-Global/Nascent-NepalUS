## MVP Description — Burnout Radar
---

# 1. Product Overview

Burnout Radar is a local-first mobile system for early burnout prevention during high-intensity study/work cycles.

It combines:

* Daily check-in signals (sleep, work, mood, exercise)
* Burnout scoring and cause detection
* Recovery and focus interventions (breathing + pomodoro)
* Notification nudges and habit support
* Optional authenticated sync for multi-device continuity

Positioning:

> A practical burnout prevention loop that moves from signal capture to action, not just passive tracking.

---

# 2. Core MVP Goal

Deliver a working product where daily behavior signals are converted into:

1. a clear burnout score (`0-100`),
2. explainable cause insights,
3. immediate recovery/focus actions,
4. measurable follow-through over time.

---

# 3. Key Concept: Burnout Feedback Loop

```id="burnout-loop"
Input -> Analysis -> Score -> Intervention -> Recovery
```

### Inputs

* Sleep hours (Health Connect first, manual fallback)
* Work hours (manual; completed pomodoro effort included in scoring input)
* Mood (`1-5`)
* Exercise minutes (Health Connect first, manual fallback)

### Outputs

* Burnout score (`0-100`)
* Classification (`low`, `medium`, `high`)
* Cause list (for example `LOW_SLEEP`, `HIGH_WORKLOAD`, `LOW_MOOD`)
* Suggested actions (recovery tasks, breathing, focus reset)

---

# 4. Current MVP Capabilities

## 4.1 Daily Signal Capture

* Fast check-in flow with low-friction inputs.
* Health Connect integration for sleep and exercise on Android.
* Manual logging path when Health Connect is unavailable.

## 4.2 Burnout Scoring + Explainability

* Score snapshot generated on check-in.
* Cause detection stored alongside each score snapshot.
* Trend direction available for dashboard context.

## 4.3 Recovery + Focus Interventions

* Recovery task generation (limited to avoid overload).
* Breathing session logging.
* Pomodoro sessions with label support and completion tracking.

## 4.4 Alerting and Nudge Layer

* High-risk and rising-trend alerts.
* Local smart notifications with score-aware guidance and motivational phrasing.

## 4.5 Local-First + Sync

* App remains fully usable without sign-in.
* Local SQLite/Drift is the runtime source of truth.
* Authenticated users get background push/pull sync with backend.

---

# 5. Burnout Score System

## 5.1 Scoring Logic (Implemented)

Score is computed from sleep, effective work load, mood, and exercise, then clamped to `0..100`.

Effective work considers manual work input with completed pomodoro contribution included in check-in scoring.

## 5.2 Current Rule Bands

| Factor | Rule bands (higher risk -> higher score contribution) |
| --- | --- |
| Sleep | `<5h: +25`, `<6h: +18`, `<7h: +12`, `>8h: +4` |
| Workload | `>10h: +25`, `>8h: +16`, `>6h: +8` |
| Mood | `(5 - mood) * 7` |
| Exercise | `<10m: +10`, `<20m: +6`, `<30m: +3`, `>=45m: -4` |

## 5.3 Classification Bands

| Score Range | Meaning |
| --- | --- |
| `0-30` | Low |
| `31-70` | Medium |
| `71-100` | High |

## 5.4 Alert Triggers

* High-risk alert when score `>= 70`
* Rising-trend alert when day-over-day increase `>= 5`

---

# 6. Data Model (MVP)

## Core Entities

* `user_accounts`, `auth_sessions`, `user_profile`
* `daily_entries`
* `burnout_scores`
* `burnout_causes`
* `tasks`
* `score_logs`
* `pomodoro_sessions`
* `breathing_sessions`
* `alerts`

## Data Rules

* UUID keys
* UTC timestamps
* Append-only score snapshots
* Causes linked to score snapshots
* Logs linked to score snapshots

---

# 7. System Architecture

```id="arch-v3"
[Flutter Mobile App]
  - local SQLite/Drift
  - scoring + intervention runtime
  - notifications + Health Connect
        |
        | authenticated sync (when session exists)
        v
[Fastify Server API]
  - JWT auth
  - REST endpoints + Swagger
        |
        v
[PostgreSQL + Prisma]
```

## Runtime Responsibilities

### Mobile App (`frontend/`)

* local-first reads/writes
* check-in UX and intervention UX
* local notifications and reminder scheduling
* Health Connect data ingestion + manual fallback

### Server (`server/`)

* authentication and session lifecycle
* API contract and protected routes
* durable persistence and relational integrity
* cross-device history continuity

### Infrastructure

* local development: root `docker-compose.yml` for PostgreSQL
* production shape: `server/docker-compose.prod.yml` for server + PostgreSQL containers

---

# 8. Demo Flow

1. Open app in guest mode (no forced login).
2. Submit daily check-in with current signals.
3. Show score, classification, and detected causes.
4. Complete one recovery/focus action.
5. Show updated history/log context and notification nudge.
6. Sign in and show continuity via backend sync.

---

# 9. Practical Rollout Path

* Start with students and early-career professionals in high-load cycles.
* Keep zero-friction entry (offline + guest) to reduce drop-off.
* Use recovery completion + streak visibility to reinforce retention.
* Expand into campus/team wellness pilots once usage loop stabilizes.

---

# 10. Repository Map

* `frontend/` -> Flutter mobile application
* `server/` -> Node.js/Fastify backend service
* `docker-compose.yml` -> local PostgreSQL runtime

Detailed docs:

* Frontend: `frontend/README.md`
* Server: `server/README.md`

---

# 11. Quick Start

```bash
docker compose up -d postgres

# terminal 1
cd server
cp .env.example .env
npm install
npm run prisma:generate
npm run prisma:migrate:dev
npm run dev

# terminal 2
cd frontend
cp .env.example .env
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

Service URLs:

* API health: `http://localhost:3000/health`
* API docs: `http://localhost:3000/docs`
