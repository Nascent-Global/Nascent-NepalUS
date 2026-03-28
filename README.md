# Nascent-NepalUS

## Quick Start

```bash
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env
docker compose up -d postgres
(cd backend && npm install && npm run prisma:generate && npm run prisma:migrate:dev && npm run dev)
# In a second terminal:
(cd frontend && flutter pub get && flutter run --dart-define=API_BASE_URL=http://localhost:3000)
```

## Useful URLs
- Backend health: `http://localhost:3000/health`
- Backend docs: `http://localhost:3000/docs`
