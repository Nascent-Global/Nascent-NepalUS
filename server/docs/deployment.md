# Deployment

## Production Shape
Production uses two containers:
- Backend application container
- PostgreSQL container

## Build Flow
1. Build the backend image with the provided `server/Dockerfile`.
2. Run Prisma generate during the image build.
3. Start the backend container with the production environment variables.
4. Start PostgreSQL with a persistent volume.

## Production Compose
- `server/docker-compose.prod.yml` defines the backend and database services.
- The backend container points `DATABASE_URL` at the PostgreSQL service hostname.

## Environment
- `DATABASE_URL`
- `JWT_SECRET`
- `PORT`
- `CORS_ORIGIN`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_DB`

## Operational Notes
- Keep secrets out of source control.
- Use a dedicated production `JWT_SECRET`.
- Run migrations as part of the deployment workflow before serving traffic.
- Ensure the backend container can reach the PostgreSQL service before startup completes.

