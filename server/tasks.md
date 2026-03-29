# Burnout Radar Backend Tasks

## Project Foundation
- [x] Create a production-style backend service in `server/`
- [x] Use Fastify for HTTP routing and Swagger UI exposure
- [x] Use Prisma Client for database access
- [x] Load configuration from `.env` with fail-fast validation
- [x] Keep unversioned routes without `/v1`
- [x] Return a consistent envelope shape for success and error responses

## Authentication
- [x] Implement register, login, and current-user endpoints
- [x] Hash passwords before persistence
- [x] Issue JWT bearer tokens
- [x] Guard protected routes with auth middleware
- [ ] Add refresh-token rotation and explicit logout revocation
- [ ] Add automated auth integration tests

## API Surface
- [x] Implement `/user-profile`
- [x] Implement `/daily-entries`
- [x] Implement `/burnout-scores`
- [x] Implement `/burnout-causes`
- [x] Implement `/tasks`
- [x] Implement `/score-logs`
- [x] Implement `/pomodoro-sessions`
- [x] Add nullable `task_label` support for pomodoro create/update/read flows
- [x] Implement `/breathing-sessions`
- [x] Implement `/alerts`
- [x] Implement `/dashboard`
- [x] Expose Swagger/OpenAPI docs at `/docs`

## Database and Schema
- [x] Model users, auth sessions, and burnout domain records in Prisma
- [x] Use UUID primary keys
- [x] Use UTC timestamps
- [x] Keep append-only score snapshots
- [x] Add indexes for date and foreign-key lookup paths
- [x] Add migration SQL for the initial schema
- [x] Add migration SQL for nullable `pomodoro_sessions.task_label`
- [x] Add seed data for local development and QA

## Docker and Deployment
- [x] Add root Docker Compose for local PostgreSQL
- [x] Add backend production Dockerfile
- [x] Add production Compose for backend + PostgreSQL
- [ ] Add CI smoke test for backend container startup
- [ ] Add container health endpoint to production rollout checklist

## Documentation
- [x] Document backend architecture
- [x] Document API contract
- [x] Document database schema
- [x] Document local setup and migration flow
- [x] Document deployment flow
- [x] Document SQL/schema deviations from the source brief

## Stabilization
- [x] Run backend typecheck
- [x] Run backend build
- [x] Smoke-test auth against Docker PostgreSQL
- [ ] Add integration tests for dashboard and CRUD endpoints
- [ ] Add rate limiting and request throttling
