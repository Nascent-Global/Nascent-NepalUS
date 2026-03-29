# Backend API Contract

## Base Rules
- No version prefix is used.
- All protected endpoints require `Authorization: Bearer <token>`.
- All responses use the envelope format:
  - success: `{ "ok": true, "data": ... }`
  - error: `{ "ok": false, "error": { "code": "...", "message": "...", "details"?: ... } }`
- Timestamps are UTC ISO-8601.
- Dates stored as date-only values are rendered as `YYYY-MM-DD`.

## Authentication
### `POST /auth/register`
Request:
```json
{
  "username": "Manish",
  "email": "manish@example.com",
  "password": "secret123",
  "timezone": "Asia/Kathmandu"
}
```
Response:
```json
{
  "ok": true,
  "data": {
    "token": "jwt-token",
    "user": {
      "id": "uuid",
      "email": "manish@example.com",
      "username": "Manish",
      "avatar": "avatar_1",
      "timezone": "Asia/Kathmandu",
      "is_active": true,
      "last_login_at": "2026-03-28T12:30:00.000Z",
      "created_at": "2026-03-28T12:30:00.000Z",
      "updated_at": "2026-03-28T12:30:00.000Z"
    }
  }
}
```

### `POST /auth/login`
Request:
```json
{
  "email": "manish@example.com",
  "password": "secret123"
}
```

### `GET /auth/me`
Returns the current authenticated user.

## User Profile
- `PUT /user-profile`
- `GET /user-profile`

Request fields:
- `username`
- `avatar`
- `timezone`

## Daily Entries
- `POST /daily-entries`
- `GET /daily-entries?from=YYYY-MM-DD&to=YYYY-MM-DD&limit=50&offset=0`

Fields:
- `date`
- `sleep_hours`
- `work_hours`
- `mood`
- `was_ok`

## Burnout Scores
- `POST /burnout-scores`
- `GET /burnout-scores/latest`
- `GET /burnout-scores?from=YYYY-MM-DD&to=YYYY-MM-DD&limit=50&offset=0`

## Burnout Causes
- `POST /burnout-causes`
- `GET /burnout-causes?score_id=<uuid>&limit=50&offset=0`

## Tasks
- `POST /tasks`
- `GET /tasks?date=YYYY-MM-DD&limit=50&offset=0`
- `PATCH /tasks/:id`

## Score Logs
- `POST /score-logs`
- `GET /score-logs?score_id=<uuid>&limit=50&offset=0`

## Pomodoro Sessions
- `POST /pomodoro-sessions`
- `PATCH /pomodoro-sessions/:id`
- `GET /pomodoro-sessions?from=YYYY-MM-DD&to=YYYY-MM-DD&limit=50&offset=0`

Fields:
- `start_time`
- `end_time`
- `duration`
- `completed`
- `task_label` (nullable)

## Breathing Sessions
- `POST /breathing-sessions`
- `PATCH /breathing-sessions/:id`
- `GET /breathing-sessions?from=YYYY-MM-DD&to=YYYY-MM-DD&limit=50&offset=0`

## Alerts
- `POST /alerts`
- `GET /alerts?from=YYYY-MM-DD&to=YYYY-MM-DD&limit=50&offset=0`

## Dashboard
### `GET /dashboard`
Returns:
```json
{
  "ok": true,
  "data": {
    "latest_score": {},
    "causes": [],
    "tasks_today": [],
    "trend": []
  }
}
```

## Error Codes
- `VALIDATION_ERROR`
- `UNAUTHORIZED`
- `FORBIDDEN`
- `NOT_FOUND`
- `CONFLICT`
- `INTERNAL_SERVER_ERROR`
