# Run Locally

## Prerequisites
- Node.js 22
- npm
- Docker and Docker Compose

## Environment
1. Copy the example file:
   ```bash
   cp server/.env.example server/.env
   ```
2. Update `DATABASE_URL` and `JWT_SECRET` if needed.

## Start PostgreSQL
```bash
docker compose up -d postgres
```

## Install and Generate Prisma Client
```bash
cd server
npm install
npm run prisma:generate
```

## Apply Migrations
```bash
npm run prisma:migrate:dev
```

## Seed Data
1. Open `server/docs/sql/mock_seed_data.sql` in DBeaver against the local PostgreSQL database.
2. Replace `REPLACE_WITH_USER_ID` in the script with an existing `user_accounts.id` UUID.
3. Run the script to load the non-auth sample data used for local development and QA.

## Start the Server
```bash
npm run dev
```

## Verify
- API health: `http://localhost:3000/health`
- Swagger UI: `http://localhost:3000/docs`

## Notes
- The backend reads config from `server/.env`.
- The local Flutter app can point to this backend with `API_BASE_URL=http://localhost:3000`.
- Use the Docker PostgreSQL container for development; the backend itself runs on the host during local development.
- The seed SQL is for non-user-domain records; create or reuse a local auth user first so you can set `user_id` correctly in DBeaver.
