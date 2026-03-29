# Database Schema

## Storage Model
The backend uses PostgreSQL with Prisma as the schema and query layer.

## Core Tables
- `user_accounts`
- `auth_sessions`
- `user_profile`
- `daily_entries`
- `burnout_scores`
- `burnout_causes`
- `tasks`
- `score_logs`
- `pomodoro_sessions`
- `breathing_sessions`
- `alerts`

## Key Relations
- `user_profile.user_id` references `user_accounts.id`
- `auth_sessions.user_id` references `user_accounts.id`
- `daily_entries.user_id` references `user_accounts.id`
- `burnout_scores.user_id` references `user_accounts.id`
- `burnout_causes.score_id` references `burnout_scores.id`
- `tasks.user_id` references `user_accounts.id`
- `score_logs.user_id` references `user_accounts.id`
- `score_logs.score_id` references `burnout_scores.id`
- `pomodoro_sessions.user_id` references `user_accounts.id`
- `breathing_sessions.user_id` references `user_accounts.id`
- `alerts.user_id` references `user_accounts.id`

## Enums
- `AuthProvider`: `LOCAL`
- `BurnoutClassification`: `low`, `medium`, `high`
- `TaskType`: `user`, `recovery`
- `BurnoutCauseType`: `LOW_SLEEP`, `HIGH_WORKLOAD`, `LOW_MOOD`, `DEADLINE_PRESSURE`, `RISING_TREND`, `TASK_OVERLOAD`, `INSUFFICIENT_BREAKS`, `OTHER`
- `AlertType`: `HIGH_BURNOUT`, `RISING_BURNOUT`, `TASK_OVERLOAD`, `REMINDER`, `SYSTEM`

## Integrity Rules
- UUIDs are generated in the database or the application layer.
- Timestamps are stored in UTC.
- Score snapshots are append-only.
- Cause rows belong to a specific score snapshot.
- Logs belong to a specific score snapshot.
- Tasks belong to a calendar date, not to a score snapshot.
- History is preserved; deletes cascade only through foreign keys.

## Indexing
- Date indexes exist for read paths on daily entries, scores, tasks, alerts, and sessions.
- Foreign-key indexes exist for user and score lookups.
- Unique constraints protect account email, score/cause pairing, and session token hashes.

## Notes
- The schema is normalized rather than JSON-heavy.
- The app layer is responsible for score computation, cause detection, task generation, and alert creation.

