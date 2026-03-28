# Data Model

## Tables
- `user_profile`
- `daily_entries`
- `burnout_scores`
- `burnout_causes`
- `tasks`
- `score_logs`
- `pomodoro_sessions`
- `breathing_sessions`
- `alerts`

## Core Relationships
- `burnout_causes.score_id -> burnout_scores.id` (cascade delete)
- `score_logs.score_id -> burnout_scores.id` (cascade delete)

## Key Storage Rules
- UUID values stored as `TEXT`.
- Booleans stored as `INTEGER` 0/1.
- Timestamps stored as UTC ISO text.
- Date keys stored as `yyyy-MM-dd`.
- `created_at` and `synced` are present on all tables.
- Score rows are append-only snapshots.

## Indexes
- `daily_entries(date)`
- `burnout_scores(date)`
- `burnout_scores(created_at)`
- `tasks(date)`
- `tasks(task_type)`
- `pomodoro_sessions(start_time)`
