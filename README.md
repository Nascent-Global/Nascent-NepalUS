# Burnout Radar

Burnout Radar is a burnout support product for students and early-career professionals who need to catch overload before it turns into lost focus, missed deadlines, or full shutdown.

It is not a passive tracker. It closes the loop from daily signal capture to explainable scoring, cause detection, recovery actions, and follow-through.

## Why Now

- Burnout is usually recognized after productivity and wellbeing have already dropped.
- People already collect sleep, mood, work, and activity signals, but the missing piece is turning those signals into a clear next step.
- The best fit is a product that works with weak connectivity, low setup friction, and immediate value on day one.

## End-to-End Loop

1. Capture a quick daily check-in with the minimum useful inputs.
2. Compute a burnout score and trend from the latest signals.
3. Explain the likely causes behind the score movement.
4. Turn the cause into concrete recovery or focus interventions.
5. Track completion and use that history to improve the next recommendation.

## Standout Capabilities

- Local-first by default, so core use works offline and without sign-in.
- Sync for continuity, so authenticated users can carry history across devices without losing the local experience.
- Explainable scoring, so the user sees why risk went up instead of getting a generic warning.
- Cause-aware guidance, so recommendations reflect what is actually driving the score.
- Built-in interventions, including breathing, focus sessions, and recovery tasks, so action happens inside the same product loop.
- Append-only history, so snapshots and activity logs preserve the story over time.
- User-centric nudges, so reminders and notifications push action rather than just reporting status.

## Technical Implementation Snapshot

- Mobile client: Flutter app with a local SQLite/Drift persistence layer as the primary runtime store.
- API server: Node.js + Fastify service with documented HTTP endpoints and Swagger UI (`/docs`).
- Data layer: PostgreSQL with Prisma schema/migrations and relational integrity across scores, causes, tasks, sessions, and alerts.
- Auth and continuity: JWT-based auth with refresh flow, guest mode by default, authenticated sync when a session exists.
- Sync model: push unsynced local records first, then pull remote updates and upsert locally.
- Infrastructure:
  - local development uses Docker Compose for PostgreSQL
  - server runs locally during development for fast iteration
  - production compose supports containerized server + PostgreSQL deployment
- Device signals: Android Health Connect integration for sleep and exercise, with manual fallback when unavailable.

## High-Level Architecture

- Local storage is the source of truth for immediate reads and writes.
- Scoring, causes, and interventions are modeled as part of one connected workflow.
- Authenticated sync keeps local data and backend data aligned without blocking offline use.
- The backend handles account continuity and shared history for cross-device use.
- Signals, scores, causes, tasks, and recovery actions all feed the same closed loop.

## Practical Rollout

- Start with students, founders, and early-career knowledge workers who feel overload most acutely.
- Keep onboarding low-friction with guest access and local use first.
- Use reminders, recovery suggestions, and visible progress to build repeat usage.
- Add sync as a continuity layer for users who want it, not as a prerequisite for value.
- Expand from individual use into campus, team, or wellness programs once the core loop proves sticky.

## Next Steps

- Refine scoring inputs and cause mapping with more real-world usage.
- Expand intervention suggestions for different work patterns and recovery needs.
- Improve sync resilience and multi-device continuity.
- Package pilot-ready onboarding for small teams, student groups, or wellness leads.

## Repository Map

- `frontend/`: Flutter mobile app (offline-first UX, local storage, Health Connect, sync client)
- `server/`: Fastify + Prisma + PostgreSQL API service
- `docker-compose.yml`: local PostgreSQL runtime

## Quick Start

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

## Service URLs

- API health: `http://localhost:3000/health`
- API docs (Swagger): `http://localhost:3000/docs`
