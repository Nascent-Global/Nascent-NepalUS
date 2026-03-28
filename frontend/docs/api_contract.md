# API Contract (No Version Prefix)

This contract is the frontend expectation for backend integration. Routes do not use `/v1`.

## Global Rules
- All timestamps are UTC ISO-8601 (`2026-03-28T12:30:00Z`).
- Every persisted resource response includes `created_at` and `updated_at`.
- List endpoints support pagination with `limit` and `offset`.
- Validation rules:
  - `mood`: `1..5`
  - `score`: `0..100`
- Burnout score snapshots are append-only.
- Business logic stays in backend/app layer, not DB procedures.

## Endpoints

### 1) User Profile
- `PUT /user-profile`
- `GET /user-profile`

Request/response shape:
```json
{
  "id": "uuid",
  "username": "Manish",
  "avatar": "avatar_1",
  "timezone": "Asia/Kathmandu",
  "created_at": "2026-03-28T10:00:00Z",
  "updated_at": "2026-03-28T10:00:00Z"
}
```

### 2) Daily Entries
- `POST /daily-entries`
- `GET /daily-entries?from=2026-03-20T00:00:00Z&to=2026-03-28T23:59:59Z&limit=50&offset=0`

### 3) Burnout Scores
- `POST /burnout-scores`
- `GET /burnout-scores/latest`
- `GET /burnout-scores?from=...&to=...&limit=50&offset=0`

### 4) Burnout Causes
- `POST /burnout-causes`
```json
{
  "score_id": "uuid",
  "causes": ["LOW_SLEEP", "HIGH_WORKLOAD"]
}
```
- `GET /burnout-causes?score_id=uuid&limit=50&offset=0`

### 5) Tasks
- `POST /tasks`
- `GET /tasks?date=2026-03-28&limit=50&offset=0`
- `PATCH /tasks/{id}`

Task request/response core fields:
```json
{
  "id": "uuid",
  "date": "2026-03-28",
  "title": "Sleep 7 hours",
  "deadline": "2026-03-28T23:00:00Z",
  "priority": 2,
  "completed": false,
  "task_type": "recovery",
  "created_at": "2026-03-28T10:00:00Z",
  "updated_at": "2026-03-28T10:00:00Z"
}
```

### 6) Score Logs
- `POST /score-logs`
- `GET /score-logs?score_id=uuid&limit=50&offset=0`

### 7) Pomodoro Sessions
- `POST /pomodoro-sessions`
- `PATCH /pomodoro-sessions/{id}`
- `GET /pomodoro-sessions?from=...&to=...&limit=50&offset=0`

### 8) Breathing Sessions
- `POST /breathing-sessions`
- `PATCH /breathing-sessions/{id}`
- `GET /breathing-sessions?from=...&to=...&limit=50&offset=0`

### 9) Alerts
- `POST /alerts`
- `GET /alerts?from=...&to=...&limit=50&offset=0`

### 10) Dashboard Aggregate
- `GET /dashboard`

Response shape:
```json
{
  "latest_score": {},
  "causes": [],
  "tasks_today": [],
  "trend": []
}
```

## Frontend Contract Files
- `lib/data/remote/api_paths.dart`
- `lib/data/remote/api_models.dart`
- `lib/data/remote/burnout_api_contract.dart`
