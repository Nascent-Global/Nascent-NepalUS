# Backend Changes (SQL -> Flutter SQLite)

This file documents the exact changes made when adapting the provided approximate PostgreSQL schema to local SQLite (`sqflite`).

## Type Adaptation
- PostgreSQL `UUID` -> SQLite `TEXT`
- PostgreSQL `TIMESTAMP` -> SQLite `TEXT` (UTC ISO-8601)
- PostgreSQL `DATE` -> SQLite `TEXT` (`yyyy-MM-dd` key)
- PostgreSQL `BOOLEAN` -> SQLite `INTEGER` with `CHECK (IN (0,1))`

## Added/Adjusted Columns
- Added `created_at` to tables that lacked it in the approximate schema:
  - `burnout_causes`
  - `pomodoro_sessions`
  - `breathing_sessions`
- Added `synced INTEGER NOT NULL DEFAULT 0 CHECK (synced IN (0,1))` to all tables.
- Added optional `tasks.reason` (`TEXT`) to persist recovery impact/category keys used by domain rules.

## Runtime DB Behavior
- Enabled `PRAGMA foreign_keys = ON`.
- Enabled WAL journaling for better local write/read concurrency.

## Constraint and Integrity Notes
- `burnout_causes` and `score_logs` keep `ON DELETE CASCADE` with `burnout_scores`.
- Burnout score snapshots are append-only (no overwrite path).
- Score + causes writes are grouped in one transaction.

## Query Behavior Adjustments
- Latest score uses `ORDER BY created_at DESC LIMIT 1`.
- Trend uses grouped daily average from `burnout_scores`.
- “Today” is evaluated by app-side date keys rather than SQLite `CURRENT_DATE` to avoid timezone drift.
