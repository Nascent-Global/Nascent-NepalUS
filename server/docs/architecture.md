# Backend Architecture

## Goal
The backend is the production API for Burnout Radar. It owns authentication, persistence, and the HTTP contract consumed by the Flutter app.

## Stack
- Node.js 22
- Fastify 5
- Prisma Client
- PostgreSQL 16
- JWT bearer authentication
- Swagger UI for interactive API exploration
- `dotenv` + `zod` for environment validation

## Structure
- `src/app.ts`: Fastify app composition
- `src/main.ts`: process bootstrap
- `src/config/`: environment loading and validation
- `src/plugins/`: prisma, jwt, error handler, swagger
- `src/routes/`: route definitions by domain
- `src/lib/`: shared helpers for auth, dates, response envelopes, and serialization
- `src/services/`: higher-level domain aggregation, such as dashboard composition
- `prisma/`: schema and migrations

## Request Flow
1. The app loads `.env` and validates required variables.
2. Fastify registers CORS, Prisma, JWT, error handling, and Swagger.
3. Public routes handle registration and login.
4. Protected routes enforce bearer token authentication.
5. Services read and write PostgreSQL through Prisma.
6. Responses are serialized into the frontend contract shape.

## Response Contract
- Success: `{ "ok": true, "data": ... }`
- Error: `{ "ok": false, "error": { "code": "...", "message": "...", "details"?: ... } }`

## Design Rules
- No version prefixes in the route space.
- No database logic in SQL beyond integrity and relations.
- No direct client access to database internals.
- Append-only history for burnout snapshots and logs.
- Swagger should reflect the actual request/response schema, not just placeholder examples.

