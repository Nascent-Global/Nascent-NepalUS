-- Mock seed data for DBeaver / PostgreSQL
--
-- Usage:
-- 1. Replace the `REPLACE_WITH_USER_ID` placeholder below with a real `user_accounts.id` UUID.
-- 2. Execute the whole script in DBeaver.
-- 3. If the UUID is missing or unknown, the script aborts before any data is changed.
--
-- What this script does:
-- - Verifies the target account exists in `user_accounts`.
-- - Removes only that account's existing domain rows from non-user tables.
-- - Inserts deterministic mock data for the current app flow around 2026-03-23 through 2026-03-29.
-- - Leaves `user_accounts`, `user_profile`, and `auth_sessions` untouched.

BEGIN;

DO $$
DECLARE
  v_user_id_text text := 'REPLACE_WITH_USER_ID';
  v_user_id uuid;
BEGIN
  IF v_user_id_text IS NULL
    OR btrim(v_user_id_text) = ''
    OR v_user_id_text !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
  THEN
    RAISE EXCEPTION 'Set v_user_id_text to a valid UUID from user_accounts.id before running this seed script.';
  END IF;

  v_user_id := v_user_id_text::uuid;

  IF NOT EXISTS (
    SELECT 1
    FROM user_accounts
    WHERE id = v_user_id
  ) THEN
    RAISE EXCEPTION 'user_accounts.id % does not exist. Seed aborted.', v_user_id;
  END IF;

  -- Remove only domain data for the selected user.
  DELETE FROM score_logs
  WHERE user_id = v_user_id;

  DELETE FROM burnout_causes bc
  USING burnout_scores bs
  WHERE bc.score_id = bs.id
    AND bs.user_id = v_user_id;

  DELETE FROM alerts
  WHERE user_id = v_user_id;

  DELETE FROM breathing_sessions
  WHERE user_id = v_user_id;

  DELETE FROM pomodoro_sessions
  WHERE user_id = v_user_id;

  DELETE FROM tasks
  WHERE user_id = v_user_id;

  DELETE FROM burnout_scores
  WHERE user_id = v_user_id;

  DELETE FROM daily_entries
  WHERE user_id = v_user_id;

  -- Daily entries: the app can show a 7-day emotional/workload trend off these records.
  INSERT INTO daily_entries (
    id,
    user_id,
    date,
    sleep_hours,
    work_hours,
    mood,
    was_ok,
    synced,
    created_at,
    updated_at
  )
  VALUES
    ('11111111-1111-1111-1111-111111111101', v_user_id, DATE '2026-03-23', 6.0, 8.5, 2, FALSE, FALSE, TIMESTAMPTZ '2026-03-23 18:20:00+00', TIMESTAMPTZ '2026-03-23 18:20:00+00'),
    ('11111111-1111-1111-1111-111111111102', v_user_id, DATE '2026-03-24', 5.8, 9.0, 2, FALSE, FALSE, TIMESTAMPTZ '2026-03-24 18:20:00+00', TIMESTAMPTZ '2026-03-24 18:20:00+00'),
    ('11111111-1111-1111-1111-111111111103', v_user_id, DATE '2026-03-25', 6.2, 8.7, 3, FALSE, FALSE, TIMESTAMPTZ '2026-03-25 18:20:00+00', TIMESTAMPTZ '2026-03-25 18:20:00+00'),
    ('11111111-1111-1111-1111-111111111104', v_user_id, DATE '2026-03-26', 6.7, 8.0, 3, TRUE, FALSE, TIMESTAMPTZ '2026-03-26 18:20:00+00', TIMESTAMPTZ '2026-03-26 18:20:00+00'),
    ('11111111-1111-1111-1111-111111111105', v_user_id, DATE '2026-03-27', 7.1, 7.6, 4, TRUE, FALSE, TIMESTAMPTZ '2026-03-27 18:20:00+00', TIMESTAMPTZ '2026-03-27 18:20:00+00'),
    ('11111111-1111-1111-1111-111111111106', v_user_id, DATE '2026-03-28', 7.4, 6.8, 4, TRUE, FALSE, TIMESTAMPTZ '2026-03-28 18:20:00+00', TIMESTAMPTZ '2026-03-28 18:20:00+00'),
    ('11111111-1111-1111-1111-111111111107', v_user_id, DATE '2026-03-29', 7.6, 6.1, 4, TRUE, FALSE, TIMESTAMPTZ '2026-03-29 18:20:00+00', TIMESTAMPTZ '2026-03-29 18:20:00+00');

  -- Burnout scores: created in date order so the latest record is the highest-pressure day.
  INSERT INTO burnout_scores (
    id,
    user_id,
    date,
    score,
    classification,
    synced,
    created_at,
    updated_at
  )
  VALUES
    ('22222222-2222-2222-2222-222222222201', v_user_id, DATE '2026-03-23', 28, 'low'::"BurnoutClassification", FALSE, TIMESTAMPTZ '2026-03-23 19:00:00+00', TIMESTAMPTZ '2026-03-23 19:00:00+00'),
    ('22222222-2222-2222-2222-222222222202', v_user_id, DATE '2026-03-24', 33, 'medium'::"BurnoutClassification", FALSE, TIMESTAMPTZ '2026-03-24 19:00:00+00', TIMESTAMPTZ '2026-03-24 19:00:00+00'),
    ('22222222-2222-2222-2222-222222222203', v_user_id, DATE '2026-03-25', 47, 'medium'::"BurnoutClassification", FALSE, TIMESTAMPTZ '2026-03-25 19:00:00+00', TIMESTAMPTZ '2026-03-25 19:00:00+00'),
    ('22222222-2222-2222-2222-222222222204', v_user_id, DATE '2026-03-26', 55, 'medium'::"BurnoutClassification", FALSE, TIMESTAMPTZ '2026-03-26 19:00:00+00', TIMESTAMPTZ '2026-03-26 19:00:00+00'),
    ('22222222-2222-2222-2222-222222222205', v_user_id, DATE '2026-03-27', 62, 'medium'::"BurnoutClassification", FALSE, TIMESTAMPTZ '2026-03-27 19:00:00+00', TIMESTAMPTZ '2026-03-27 19:00:00+00'),
    ('22222222-2222-2222-2222-222222222206', v_user_id, DATE '2026-03-28', 71, 'high'::"BurnoutClassification", FALSE, TIMESTAMPTZ '2026-03-28 19:00:00+00', TIMESTAMPTZ '2026-03-28 19:00:00+00'),
    ('22222222-2222-2222-2222-222222222207', v_user_id, DATE '2026-03-29', 79, 'high'::"BurnoutClassification", FALSE, TIMESTAMPTZ '2026-03-29 19:00:00+00', TIMESTAMPTZ '2026-03-29 19:00:00+00');

  INSERT INTO burnout_causes (
    id,
    score_id,
    cause_type,
    synced,
    created_at,
    updated_at
  )
  VALUES
    ('33333333-3333-3333-3333-333333333301', '22222222-2222-2222-2222-222222222201', 'LOW_SLEEP'::"BurnoutCauseType", FALSE, TIMESTAMPTZ '2026-03-23 19:05:00+00', TIMESTAMPTZ '2026-03-23 19:05:00+00'),
    ('33333333-3333-3333-3333-333333333302', '22222222-2222-2222-2222-222222222201', 'LOW_MOOD'::"BurnoutCauseType", FALSE, TIMESTAMPTZ '2026-03-23 19:05:00+00', TIMESTAMPTZ '2026-03-23 19:05:00+00'),
    ('33333333-3333-3333-3333-333333333303', '22222222-2222-2222-2222-222222222202', 'LOW_SLEEP'::"BurnoutCauseType", FALSE, TIMESTAMPTZ '2026-03-24 19:05:00+00', TIMESTAMPTZ '2026-03-24 19:05:00+00'),
    ('33333333-3333-3333-3333-333333333304', '22222222-2222-2222-2222-222222222202', 'TASK_OVERLOAD'::"BurnoutCauseType", FALSE, TIMESTAMPTZ '2026-03-24 19:05:00+00', TIMESTAMPTZ '2026-03-24 19:05:00+00'),
    ('33333333-3333-3333-3333-333333333305', '22222222-2222-2222-2222-222222222203', 'HIGH_WORKLOAD'::"BurnoutCauseType", FALSE, TIMESTAMPTZ '2026-03-25 19:05:00+00', TIMESTAMPTZ '2026-03-25 19:05:00+00'),
    ('33333333-3333-3333-3333-333333333306', '22222222-2222-2222-2222-222222222203', 'INSUFFICIENT_BREAKS'::"BurnoutCauseType", FALSE, TIMESTAMPTZ '2026-03-25 19:05:00+00', TIMESTAMPTZ '2026-03-25 19:05:00+00'),
    ('33333333-3333-3333-3333-333333333307', '22222222-2222-2222-2222-222222222204', 'RISING_TREND'::"BurnoutCauseType", FALSE, TIMESTAMPTZ '2026-03-26 19:05:00+00', TIMESTAMPTZ '2026-03-26 19:05:00+00'),
    ('33333333-3333-3333-3333-333333333308', '22222222-2222-2222-2222-222222222204', 'HIGH_WORKLOAD'::"BurnoutCauseType", FALSE, TIMESTAMPTZ '2026-03-26 19:05:00+00', TIMESTAMPTZ '2026-03-26 19:05:00+00'),
    ('33333333-3333-3333-3333-333333333309', '22222222-2222-2222-2222-222222222205', 'HIGH_WORKLOAD'::"BurnoutCauseType", FALSE, TIMESTAMPTZ '2026-03-27 19:05:00+00', TIMESTAMPTZ '2026-03-27 19:05:00+00'),
    ('33333333-3333-3333-3333-333333333310', '22222222-2222-2222-2222-222222222205', 'TASK_OVERLOAD'::"BurnoutCauseType", FALSE, TIMESTAMPTZ '2026-03-27 19:05:00+00', TIMESTAMPTZ '2026-03-27 19:05:00+00'),
    ('33333333-3333-3333-3333-333333333311', '22222222-2222-2222-2222-222222222206', 'HIGH_WORKLOAD'::"BurnoutCauseType", FALSE, TIMESTAMPTZ '2026-03-28 19:05:00+00', TIMESTAMPTZ '2026-03-28 19:05:00+00'),
    ('33333333-3333-3333-3333-333333333312', '22222222-2222-2222-2222-222222222206', 'LOW_SLEEP'::"BurnoutCauseType", FALSE, TIMESTAMPTZ '2026-03-28 19:05:00+00', TIMESTAMPTZ '2026-03-28 19:05:00+00'),
    ('33333333-3333-3333-3333-333333333313', '22222222-2222-2222-2222-222222222206', 'TASK_OVERLOAD'::"BurnoutCauseType", FALSE, TIMESTAMPTZ '2026-03-28 19:05:00+00', TIMESTAMPTZ '2026-03-28 19:05:00+00'),
    ('33333333-3333-3333-3333-333333333314', '22222222-2222-2222-2222-222222222207', 'HIGH_WORKLOAD'::"BurnoutCauseType", FALSE, TIMESTAMPTZ '2026-03-29 19:05:00+00', TIMESTAMPTZ '2026-03-29 19:05:00+00'),
    ('33333333-3333-3333-3333-333333333315', '22222222-2222-2222-2222-222222222207', 'LOW_SLEEP'::"BurnoutCauseType", FALSE, TIMESTAMPTZ '2026-03-29 19:05:00+00', TIMESTAMPTZ '2026-03-29 19:05:00+00'),
    ('33333333-3333-3333-3333-333333333316', '22222222-2222-2222-2222-222222222207', 'INSUFFICIENT_BREAKS'::"BurnoutCauseType", FALSE, TIMESTAMPTZ '2026-03-29 19:05:00+00', TIMESTAMPTZ '2026-03-29 19:05:00+00'),
    ('33333333-3333-3333-3333-333333333317', '22222222-2222-2222-2222-222222222207', 'RISING_TREND'::"BurnoutCauseType", FALSE, TIMESTAMPTZ '2026-03-29 19:05:00+00', TIMESTAMPTZ '2026-03-29 19:05:00+00');

  -- Tasks: include today's tasks so the dashboard has something to show immediately.
  INSERT INTO tasks (
    id,
    user_id,
    date,
    title,
    deadline,
    priority,
    completed,
    task_type,
    synced,
    created_at,
    updated_at
  )
  VALUES
    ('44444444-4444-4444-4444-444444444401', v_user_id, DATE '2026-03-24', 'Prepare weekly client update', TIMESTAMPTZ '2026-03-24 16:30:00+00', 2, TRUE, 'user'::"TaskType", FALSE, TIMESTAMPTZ '2026-03-24 09:10:00+00', TIMESTAMPTZ '2026-03-24 09:10:00+00'),
    ('44444444-4444-4444-4444-444444444402', v_user_id, DATE '2026-03-25', 'Review backlog and reprioritize', TIMESTAMPTZ '2026-03-25 17:00:00+00', 2, FALSE, 'user'::"TaskType", FALSE, TIMESTAMPTZ '2026-03-25 09:15:00+00', TIMESTAMPTZ '2026-03-25 09:15:00+00'),
    ('44444444-4444-4444-4444-444444444403', v_user_id, DATE '2026-03-26', 'Take a 20-minute recovery walk', NULL, 1, TRUE, 'recovery'::"TaskType", FALSE, TIMESTAMPTZ '2026-03-26 10:00:00+00', TIMESTAMPTZ '2026-03-26 10:00:00+00'),
    ('44444444-4444-4444-4444-444444444404', v_user_id, DATE '2026-03-27', 'Finish sprint planning notes', TIMESTAMPTZ '2026-03-27 15:00:00+00', 3, TRUE, 'user'::"TaskType", FALSE, TIMESTAMPTZ '2026-03-27 09:05:00+00', TIMESTAMPTZ '2026-03-27 09:05:00+00'),
    ('44444444-4444-4444-4444-444444444405', v_user_id, DATE '2026-03-28', 'Clear inbox to zero', TIMESTAMPTZ '2026-03-28 18:00:00+00', 2, FALSE, 'user'::"TaskType", FALSE, TIMESTAMPTZ '2026-03-28 08:55:00+00', TIMESTAMPTZ '2026-03-28 08:55:00+00'),
    ('44444444-4444-4444-4444-444444444406', v_user_id, DATE '2026-03-29', 'Draft status update for Monday standup', TIMESTAMPTZ '2026-03-29 11:00:00+00', 1, FALSE, 'user'::"TaskType", FALSE, TIMESTAMPTZ '2026-03-29 08:30:00+00', TIMESTAMPTZ '2026-03-29 08:30:00+00'),
    ('44444444-4444-4444-4444-444444444407', v_user_id, DATE '2026-03-29', 'Run a breathing reset before lunch', NULL, 1, TRUE, 'recovery'::"TaskType", FALSE, TIMESTAMPTZ '2026-03-29 10:15:00+00', TIMESTAMPTZ '2026-03-29 10:15:00+00'),
    ('44444444-4444-4444-4444-444444444408', v_user_id, DATE '2026-03-29', 'Send final review comments', TIMESTAMPTZ '2026-03-29 17:30:00+00', 3, FALSE, 'user'::"TaskType", FALSE, TIMESTAMPTZ '2026-03-29 08:45:00+00', TIMESTAMPTZ '2026-03-29 08:45:00+00');

  -- Score logs: give the chart some change history and causality around each score snapshot.
  INSERT INTO score_logs (
    id,
    user_id,
    score_id,
    change_amount,
    reason,
    synced,
    created_at,
    updated_at
  )
  VALUES
    ('55555555-5555-5555-5555-555555555501', v_user_id, '22222222-2222-2222-2222-222222222201', 28, 'Baseline score after two short-sleep nights', FALSE, TIMESTAMPTZ '2026-03-23 19:10:00+00', TIMESTAMPTZ '2026-03-23 19:10:00+00'),
    ('55555555-5555-5555-5555-555555555502', v_user_id, '22222222-2222-2222-2222-222222222202', 4, 'Workload increased and recovery time stayed limited', FALSE, TIMESTAMPTZ '2026-03-24 19:10:00+00', TIMESTAMPTZ '2026-03-24 19:10:00+00'),
    ('55555555-5555-5555-5555-555555555503', v_user_id, '22222222-2222-2222-2222-222222222203', 5, 'Deadline pressure started to show up in the day plan', FALSE, TIMESTAMPTZ '2026-03-25 19:10:00+00', TIMESTAMPTZ '2026-03-25 19:10:00+00'),
    ('55555555-5555-5555-5555-555555555504', v_user_id, '22222222-2222-2222-2222-222222222204', 5, 'More meetings and less breathing room between tasks', FALSE, TIMESTAMPTZ '2026-03-26 19:10:00+00', TIMESTAMPTZ '2026-03-26 19:10:00+00'),
    ('55555555-5555-5555-5555-555555555505', v_user_id, '22222222-2222-2222-2222-222222222205', 6, 'Short recovery break helped, but task load still climbed', FALSE, TIMESTAMPTZ '2026-03-27 19:10:00+00', TIMESTAMPTZ '2026-03-27 19:10:00+00'),
    ('55555555-5555-5555-5555-555555555506', v_user_id, '22222222-2222-2222-2222-222222222206', 7, 'Sleep recovered slightly, but the trend still pointed upward', FALSE, TIMESTAMPTZ '2026-03-28 19:10:00+00', TIMESTAMPTZ '2026-03-28 19:10:00+00'),
    ('55555555-5555-5555-5555-555555555507', v_user_id, '22222222-2222-2222-2222-222222222207', 8, 'Latest snapshot reflects the heaviest workload day in the set', FALSE, TIMESTAMPTZ '2026-03-29 19:10:00+00', TIMESTAMPTZ '2026-03-29 19:10:00+00');

  -- Pomodoro sessions: task_label keeps the sessions readable in the UI without needing a task FK.
  INSERT INTO pomodoro_sessions (
    id,
    user_id,
    start_time,
    end_time,
    duration,
    completed,
    task_label,
    synced,
    created_at,
    updated_at
  )
  VALUES
    ('66666666-6666-6666-6666-666666666601', v_user_id, TIMESTAMPTZ '2026-03-27 08:30:00+00', TIMESTAMPTZ '2026-03-27 09:00:00+00', 30, TRUE, 'Finish sprint planning notes', FALSE, TIMESTAMPTZ '2026-03-27 09:00:00+00', TIMESTAMPTZ '2026-03-27 09:00:00+00'),
    ('66666666-6666-6666-6666-666666666602', v_user_id, TIMESTAMPTZ '2026-03-28 09:00:00+00', TIMESTAMPTZ '2026-03-28 09:50:00+00', 50, TRUE, 'Clear inbox to zero', FALSE, TIMESTAMPTZ '2026-03-28 09:50:00+00', TIMESTAMPTZ '2026-03-28 09:50:00+00'),
    ('66666666-6666-6666-6666-666666666603', v_user_id, TIMESTAMPTZ '2026-03-28 14:00:00+00', TIMESTAMPTZ '2026-03-28 14:25:00+00', 25, TRUE, 'Prepare weekly client update', FALSE, TIMESTAMPTZ '2026-03-28 14:25:00+00', TIMESTAMPTZ '2026-03-28 14:25:00+00'),
    ('66666666-6666-6666-6666-666666666604', v_user_id, TIMESTAMPTZ '2026-03-29 08:15:00+00', TIMESTAMPTZ '2026-03-29 08:45:00+00', 30, TRUE, 'Draft status update for Monday standup', FALSE, TIMESTAMPTZ '2026-03-29 08:45:00+00', TIMESTAMPTZ '2026-03-29 08:45:00+00'),
    ('66666666-6666-6666-6666-666666666605', v_user_id, TIMESTAMPTZ '2026-03-29 10:30:00+00', TIMESTAMPTZ '2026-03-29 11:00:00+00', 30, TRUE, 'Send final review comments', FALSE, TIMESTAMPTZ '2026-03-29 11:00:00+00', TIMESTAMPTZ '2026-03-29 11:00:00+00'),
    ('66666666-6666-6666-6666-666666666606', v_user_id, TIMESTAMPTZ '2026-03-29 13:00:00+00', NULL, NULL, FALSE, 'Review backlog and reprioritize', FALSE, TIMESTAMPTZ '2026-03-29 13:00:00+00', TIMESTAMPTZ '2026-03-29 13:00:00+00');

  -- Breathing sessions: quick recovery breaks to balance the heavier score trend.
  INSERT INTO breathing_sessions (
    id,
    user_id,
    started_at,
    duration,
    completed,
    synced,
    created_at,
    updated_at
  )
  VALUES
    ('77777777-7777-7777-7777-777777777701', v_user_id, TIMESTAMPTZ '2026-03-25 12:10:00+00', 6, TRUE, FALSE, TIMESTAMPTZ '2026-03-25 12:16:00+00', TIMESTAMPTZ '2026-03-25 12:16:00+00'),
    ('77777777-7777-7777-7777-777777777702', v_user_id, TIMESTAMPTZ '2026-03-26 12:35:00+00', 5, TRUE, FALSE, TIMESTAMPTZ '2026-03-26 12:40:00+00', TIMESTAMPTZ '2026-03-26 12:40:00+00'),
    ('77777777-7777-7777-7777-777777777703', v_user_id, TIMESTAMPTZ '2026-03-27 15:20:00+00', 8, TRUE, FALSE, TIMESTAMPTZ '2026-03-27 15:28:00+00', TIMESTAMPTZ '2026-03-27 15:28:00+00'),
    ('77777777-7777-7777-7777-777777777704', v_user_id, TIMESTAMPTZ '2026-03-28 11:45:00+00', 7, TRUE, FALSE, TIMESTAMPTZ '2026-03-28 11:52:00+00', TIMESTAMPTZ '2026-03-28 11:52:00+00'),
    ('77777777-7777-7777-7777-777777777705', v_user_id, TIMESTAMPTZ '2026-03-29 12:20:00+00', 5, TRUE, FALSE, TIMESTAMPTZ '2026-03-29 12:25:00+00', TIMESTAMPTZ '2026-03-29 12:25:00+00');

  -- Alerts: keep the messaging aligned with the score trend so the notifications panel looks realistic.
  INSERT INTO alerts (
    id,
    user_id,
    date,
    type,
    message,
    synced,
    created_at,
    updated_at
  )
  VALUES
    ('88888888-8888-8888-8888-888888888801', v_user_id, DATE '2026-03-26', 'RISING_BURNOUT'::"AlertType", 'Burnout has trended upward for four days. Prioritize recovery before the next work block.', FALSE, TIMESTAMPTZ '2026-03-26 19:30:00+00', TIMESTAMPTZ '2026-03-26 19:30:00+00'),
    ('88888888-8888-8888-8888-888888888802', v_user_id, DATE '2026-03-28', 'TASK_OVERLOAD'::"AlertType", 'You have multiple pending tasks and a high workload score. Trim the list to the highest-value items.', FALSE, TIMESTAMPTZ '2026-03-28 19:35:00+00', TIMESTAMPTZ '2026-03-28 19:35:00+00'),
    ('88888888-8888-8888-8888-888888888803', v_user_id, DATE '2026-03-29', 'HIGH_BURNOUT'::"AlertType", 'Today''s burnout score is in the high range. Keep the rest of the day light and avoid adding new commitments.', FALSE, TIMESTAMPTZ '2026-03-29 19:40:00+00', TIMESTAMPTZ '2026-03-29 19:40:00+00'),
    ('88888888-8888-8888-8888-888888888804', v_user_id, DATE '2026-03-29', 'REMINDER'::"AlertType", 'Take a short breathing reset before the final work block and close out one small task.', FALSE, TIMESTAMPTZ '2026-03-29 20:00:00+00', TIMESTAMPTZ '2026-03-29 20:00:00+00');
END $$;

COMMIT;
