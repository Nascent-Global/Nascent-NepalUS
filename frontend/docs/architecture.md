# Architecture

## Goal
Burnout Radar is a Flutter-only, offline-first app that computes burnout risk from daily signals and closes the recovery loop locally.

## Layers
- `presentation/`: Screens, widgets, and user interactions.
- `domain/`: Burnout engine and reminder services.
- `data/`: SQLite schema, models, repository implementation, and backend API contract types.

## Rules
- UI never accesses SQLite directly.
- Repository is the only entry point to persistence.
- Backend route/schema contract is defined in `docs/api_contract.md` and mirrored in `lib/data/remote/`.
- Burnout score snapshots are immutable history entries.
- Dates/timestamps are stored in UTC and shown in local timezone.

## Main Flow
1. Daily check-in is submitted.
2. Domain computes score/classification.
3. Causes are detected.
4. Recovery tasks are generated.
5. Alerts are inserted when needed.
6. Completing recovery tasks creates score logs and a new lower score snapshot.
