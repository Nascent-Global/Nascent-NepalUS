-- Create extensions required for UUID generation.
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Enums
CREATE TYPE "AuthProvider" AS ENUM ('LOCAL');

CREATE TYPE "BurnoutClassification" AS ENUM ('low', 'medium', 'high');

CREATE TYPE "TaskType" AS ENUM ('user', 'recovery');

CREATE TYPE "BurnoutCauseType" AS ENUM (
  'LOW_SLEEP',
  'HIGH_WORKLOAD',
  'LOW_MOOD',
  'DEADLINE_PRESSURE',
  'RISING_TREND',
  'TASK_OVERLOAD',
  'INSUFFICIENT_BREAKS',
  'OTHER'
);

CREATE TYPE "AlertType" AS ENUM (
  'HIGH_BURNOUT',
  'RISING_BURNOUT',
  'TASK_OVERLOAD',
  'REMINDER',
  'SYSTEM'
);

-- Auth accounts
CREATE TABLE "user_accounts" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "email" TEXT NOT NULL,
  "password_hash" TEXT NOT NULL,
  "provider" "AuthProvider" NOT NULL DEFAULT 'LOCAL',
  "is_active" BOOLEAN NOT NULL DEFAULT TRUE,
  "last_login_at" TIMESTAMPTZ(6),
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "user_accounts_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "uq_user_accounts_email" ON "user_accounts" ("email");

-- Optional server sessions for auth/session support.
CREATE TABLE "auth_sessions" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL,
  "token_hash" TEXT NOT NULL,
  "refresh_token" TEXT,
  "expires_at" TIMESTAMPTZ(6) NOT NULL,
  "revoked_at" TIMESTAMPTZ(6),
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "auth_sessions_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "uq_auth_sessions_token_hash" ON "auth_sessions" ("token_hash");
CREATE UNIQUE INDEX "uq_auth_sessions_refresh_token" ON "auth_sessions" ("refresh_token");
CREATE INDEX "idx_auth_sessions_user_id" ON "auth_sessions" ("user_id");
CREATE INDEX "idx_auth_sessions_expires_at" ON "auth_sessions" ("expires_at");

-- User profile
CREATE TABLE "user_profile" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL,
  "username" TEXT NOT NULL,
  "avatar" TEXT NOT NULL,
  "timezone" TEXT NOT NULL,
  "synced" BOOLEAN NOT NULL DEFAULT FALSE,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "user_profile_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "uq_user_profile_user_id" ON "user_profile" ("user_id");
CREATE INDEX "idx_user_profile_username" ON "user_profile" ("username");

-- Daily entries
CREATE TABLE "daily_entries" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL,
  "date" DATE NOT NULL,
  "sleep_hours" DOUBLE PRECISION,
  "work_hours" DOUBLE PRECISION,
  "mood" INTEGER NOT NULL,
  "was_ok" BOOLEAN,
  "synced" BOOLEAN NOT NULL DEFAULT FALSE,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "daily_entries_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "daily_entries_mood_check" CHECK ("mood" BETWEEN 1 AND 5)
);

CREATE INDEX "idx_daily_entries_date" ON "daily_entries" ("date");
CREATE INDEX "idx_daily_entries_user_date" ON "daily_entries" ("user_id", "date");
CREATE INDEX "idx_daily_entries_created_at" ON "daily_entries" ("created_at");

-- Burnout scores
CREATE TABLE "burnout_scores" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL,
  "date" DATE NOT NULL,
  "score" INTEGER NOT NULL,
  "classification" "BurnoutClassification" NOT NULL,
  "synced" BOOLEAN NOT NULL DEFAULT FALSE,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "burnout_scores_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "burnout_scores_score_check" CHECK ("score" BETWEEN 0 AND 100)
);

CREATE INDEX "idx_burnout_scores_date" ON "burnout_scores" ("date");
CREATE INDEX "idx_burnout_scores_user_date" ON "burnout_scores" ("user_id", "date");
CREATE INDEX "idx_burnout_scores_user_created_at" ON "burnout_scores" ("user_id", "created_at");

-- Burnout causes
CREATE TABLE "burnout_causes" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "score_id" UUID NOT NULL,
  "cause_type" "BurnoutCauseType" NOT NULL,
  "synced" BOOLEAN NOT NULL DEFAULT FALSE,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "burnout_causes_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "uq_burnout_causes_score_cause" ON "burnout_causes" ("score_id", "cause_type");
CREATE INDEX "idx_burnout_causes_score_id" ON "burnout_causes" ("score_id");

-- Tasks
CREATE TABLE "tasks" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL,
  "date" DATE NOT NULL,
  "title" TEXT NOT NULL,
  "deadline" TIMESTAMPTZ(6),
  "priority" INTEGER,
  "completed" BOOLEAN NOT NULL DEFAULT FALSE,
  "task_type" "TaskType" NOT NULL,
  "synced" BOOLEAN NOT NULL DEFAULT FALSE,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "tasks_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "idx_tasks_date" ON "tasks" ("date");
CREATE INDEX "idx_tasks_user_date" ON "tasks" ("user_id", "date");
CREATE INDEX "idx_tasks_user_type" ON "tasks" ("user_id", "task_type");
CREATE INDEX "idx_tasks_user_completed" ON "tasks" ("user_id", "completed");

-- Score logs
CREATE TABLE "score_logs" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL,
  "score_id" UUID NOT NULL,
  "change_amount" INTEGER NOT NULL,
  "reason" TEXT,
  "synced" BOOLEAN NOT NULL DEFAULT FALSE,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "score_logs_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "idx_score_logs_score_id" ON "score_logs" ("score_id");
CREATE INDEX "idx_score_logs_user_created_at" ON "score_logs" ("user_id", "created_at");

-- Pomodoro sessions
CREATE TABLE "pomodoro_sessions" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL,
  "start_time" TIMESTAMPTZ(6) NOT NULL,
  "end_time" TIMESTAMPTZ(6),
  "duration" INTEGER,
  "completed" BOOLEAN,
  "synced" BOOLEAN NOT NULL DEFAULT FALSE,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "pomodoro_sessions_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "idx_pomodoro_user_start" ON "pomodoro_sessions" ("user_id", "start_time");

-- Breathing sessions
CREATE TABLE "breathing_sessions" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL,
  "started_at" TIMESTAMPTZ(6) NOT NULL,
  "duration" INTEGER NOT NULL,
  "completed" BOOLEAN NOT NULL,
  "synced" BOOLEAN NOT NULL DEFAULT FALSE,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "breathing_sessions_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "idx_breathing_user_started" ON "breathing_sessions" ("user_id", "started_at");

-- Alerts
CREATE TABLE "alerts" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL,
  "date" DATE,
  "type" "AlertType" NOT NULL,
  "message" TEXT NOT NULL,
  "synced" BOOLEAN NOT NULL DEFAULT FALSE,
  "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "alerts_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "idx_alerts_date" ON "alerts" ("date");
CREATE INDEX "idx_alerts_user_date" ON "alerts" ("user_id", "date");
CREATE INDEX "idx_alerts_user_created_at" ON "alerts" ("user_id", "created_at");

-- Foreign keys
ALTER TABLE "auth_sessions"
  ADD CONSTRAINT "auth_sessions_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "user_accounts"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "user_profile"
  ADD CONSTRAINT "user_profile_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "user_accounts"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "daily_entries"
  ADD CONSTRAINT "daily_entries_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "user_accounts"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "burnout_scores"
  ADD CONSTRAINT "burnout_scores_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "user_accounts"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "burnout_causes"
  ADD CONSTRAINT "burnout_causes_score_id_fkey"
  FOREIGN KEY ("score_id") REFERENCES "burnout_scores"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "tasks"
  ADD CONSTRAINT "tasks_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "user_accounts"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "score_logs"
  ADD CONSTRAINT "score_logs_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "user_accounts"("id")
  ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT "score_logs_score_id_fkey"
  FOREIGN KEY ("score_id") REFERENCES "burnout_scores"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "pomodoro_sessions"
  ADD CONSTRAINT "pomodoro_sessions_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "user_accounts"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "breathing_sessions"
  ADD CONSTRAINT "breathing_sessions_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "user_accounts"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "alerts"
  ADD CONSTRAINT "alerts_user_id_fkey"
  FOREIGN KEY ("user_id") REFERENCES "user_accounts"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;
