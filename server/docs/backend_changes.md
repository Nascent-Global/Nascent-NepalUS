# Backend Changes

This file records the implementation choices made to translate the product brief into the actual backend schema and runtime behavior.

## Storage Choices
- PostgreSQL is the canonical database.
- Prisma is the ORM and migration system.
- UUID primary keys are used across entities.
- UTC timestamps are used throughout.
- `created_at` and `updated_at` are present on persisted records that require history tracking.

## Schema Choices
- Added `user_accounts` and `auth_sessions` for real authentication support.
- Kept the burnout domain tables normalized.
- Added `synced` flags to support future offline or sync workflows.
- Kept append-only burnout score history.
- Kept task records date-based rather than score-based.

## Contract Choices
- Route names are unversioned.
- Responses use an envelope shape for success and error cases.
- Swagger UI is exposed at `/docs`.
- `GET /dashboard` returns the aggregate keys used by the frontend:
  - `latest_score`
  - `causes`
  - `tasks_today`
  - `trend`

## Runtime Choices
- Fastify handles HTTP, validation, and route composition.
- JWT bearer auth protects the app routes.
- Passwords are hashed before storage.
- Session rows are stored to support future token revocation and auditability.
- The mock seed script covers non-user-domain sample data and expects an existing local `user_id` for rows that reference a user.

## Deviations From the Brief
- The implementation uses `user_accounts` plus `auth_sessions` for authentication, instead of a single profile table.
- The backend is designed for production PostgreSQL rather than the earlier mock-only auth flow.
- No business logic is embedded in SQL; it remains in the application layer.
