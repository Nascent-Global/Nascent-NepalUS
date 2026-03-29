# Server

This `server` directory contains the production API for the app. It owns authentication, persistence, and the HTTP contract consumed by the client app.

## Purpose
- Serve the application API from Fastify.
- Persist domain data in PostgreSQL through Prisma.
- Enforce JWT bearer authentication for protected routes.
- Expose Swagger UI for interactive API exploration.

## Stack
- Node.js 22
- Fastify 5
- Prisma Client
- PostgreSQL 16
- JWT bearer auth with hashed token sessions
- Swagger UI
- `dotenv` and `zod` for environment loading and validation

## API Highlights
- Routes are unversioned.
- Standard response envelope:
  - success: `{ "ok": true, "data": ... }`
  - error: `{ "ok": false, "error": { "code": "...", "message": "...", "details"?: ... } }`
- Health check: `GET /health`
- Auth routes:
  - `POST /auth/register`
  - `POST /auth/login`
  - `POST /auth/refresh`
  - `GET /auth/me`
- Core domain routes:
  - `GET /dashboard`
  - `GET` and `POST` routes for daily entries, burnout scores, burnout causes, tasks, score logs, pomodoro sessions, breathing sessions, and alerts
- Swagger UI: `GET /docs`

## Auth Model
- Authentication uses JWT bearer tokens.
- `POST /auth/register` and `POST /auth/login` issue both access and refresh tokens.
- Access tokens are required on protected routes via `Authorization: Bearer <token>`.
- The server stores hashed session tokens in `auth_sessions` so a token can be validated against an active session row.
- Refresh tokens are verified separately and are also backed by stored session data.
- Passwords are hashed with `bcryptjs` before storage.

## Database and Migrations
- Prisma is the schema and migration layer.
- The canonical schema lives in `server/prisma/schema.prisma`.
- Migration files live under `server/prisma/migrations`.
- Common commands:
  - `npm run prisma:generate`
  - `npm run prisma:migrate:dev`
  - `npm run prisma:studio`
- Tables are normalized and use UUID primary keys, UTC timestamps, and append-friendly history for score data.

## Seed Data
- Local mock seed data lives at `server/docs/sql/mock_seed_data.sql`.
- The script expects an existing `user_accounts.id` value.
- Replace `REPLACE_WITH_USER_ID` with a real UUID before running it in DBeaver or another PostgreSQL client.
- The script seeds non-auth sample data and leaves `user_accounts`, `user_profile`, and `auth_sessions` untouched.

## Local Run
1. Copy environment values:
   ```bash
   cp server/.env.example server/.env
   ```
2. Set `DATABASE_URL` and `JWT_SECRET` in `server/.env` if needed.
3. Start PostgreSQL from the repository root:
   ```bash
   docker compose up -d postgres
   ```
4. Install dependencies and generate Prisma Client:
   ```bash
   cd server
   npm install
   npm run prisma:generate
   ```
5. Apply migrations:
   ```bash
   npm run prisma:migrate:dev
   ```
6. Start the server:
   ```bash
   npm run dev
   ```
7. Verify:
   - `http://localhost:3000/health`
   - `http://localhost:3000/docs`

## Production Compose
- Production is defined in `server/docker-compose.prod.yml`.
- It starts a `backend` container and a `postgres` container.
- The backend image is built from `server/Dockerfile`.
- In production, `DATABASE_URL` is wired through `DATABASE_URL_DOCKER` in the compose file.
- Run migrations as part of deployment before serving traffic.

## Related Server Docs
- [Architecture](docs/architecture.md)
- [API Contract](docs/api_contract.md)
- [Database Schema](docs/database_schema.md)
- [Run Locally](docs/run_local.md)
- [Deployment](docs/deployment.md)
- [Backend Changes](docs/backend_changes.md)
- [Mock Seed Data](docs/sql/mock_seed_data.sql)
