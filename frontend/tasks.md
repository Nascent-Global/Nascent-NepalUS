# Burnout Radar Frontend Tasks

## Project Foundation
- [x] Set app metadata to Burnout Radar and verify Android package ID `com.nascentnepalus.burnoutradar`
- [x] Confirm dependency set (`sqflite`, `path_provider`, `uuid`, `fl_chart`, `flutter_riverpod`, `flutter_local_notifications`, `intl`)
- [x] Keep architecture boundaries strict: `presentation` -> `domain` -> `data`
- [x] Keep root clean: only root `README.md` and `frontend/` (plus git internals)
- [x] Keep `tasks.md` updated during implementation progress

## Database and Local Storage
- [x] Finalize SQLite schema creation and startup pragmas
- [x] Verify all required indexes are created
- [x] Confirm `created_at` and `synced` exist on all tables
- [x] Validate FK cascade behavior (`burnout_causes`, `score_logs`)
- [x] Ensure dates are UTC for storage and local timezone for display
- [x] Confirm score snapshots are append-only (never overwrite)

## Models and Repository
- [x] Create one model per table with `toMap`, `fromMap`, `toJson`
- [x] Complete `BurnoutRepository` interface for all required flows
- [x] Implement `LocalBurnoutRepository` with no direct UI SQL access
- [ ] Add transaction-safe score snapshot + causes + logs save path
- [x] Add trend query for dashboard graph

## Domain Logic
- [x] Implement burnout score calculation from daily inputs + task pressure
- [x] Implement classification mapping (low/medium/high)
- [x] Implement cause detection rules
- [x] Map causes to personalized recovery tasks (2-3/day cap)
- [x] Implement task completion impact and score reduction snapshots
- [x] Implement threshold and rising-trend alert insertion
- [x] Implement pomodoro and breathing session tracking

## UI - Vertical Slices
- [x] Dashboard screen with latest score, direction arrow, causes, tasks progress, and trend chart
- [x] Daily Check-in screen with sleep/work/mood/was-ok inputs
- [x] Tasks/Pressure screen with task creation and completion flow
- [x] Recovery screen with breathing action and recovery checklist
- [x] Focus screen with pomodoro controls and session list
- [x] Alerts screen with historical alert feed
- [x] Navigation shell and app styling aligned to Stitch references

## Reminders and Habit Support
- [ ] Initialize local notifications on app startup path
- [x] Add daily reminder enable/disable toggle in UI
- [ ] Add quick reminder trigger for manual verification

## Documentation
- [x] Maintain architecture docs in `docs/architecture.md`
- [x] Maintain data and schema docs in `docs/data_model.md`
- [x] Maintain static constants docs in `docs/scoring_and_static_rules.md`
- [x] Record SQL deviations in `docs/backend_changes.md`
- [x] Maintain backend endpoint/schema contract in `docs/api_contract.md`
- [x] Maintain manual validation steps in `docs/manual_qa_checklist.md`
- [x] Maintain real-device run guide in `docs/run_on_android_device.md`

## API Readiness
- [x] Keep endpoint naming without version prefixes
- [x] Keep single-profile upsert route as `PUT /user-profile`
- [x] Keep session resources as `/pomodoro-sessions` and `/breathing-sessions`
- [x] Keep mutable resources updated through `PATCH /{resource}/{id}`
- [x] Keep pagination (`limit`, `offset`) for all list endpoints
- [x] Ensure all API responses include `created_at` and `updated_at`

## Pre-demo Stabilization
- [x] Run `dart format` and `flutter analyze`
- [ ] Run app on connected Android device and verify core flows
- [ ] Validate offline persistence across app relaunch
- [ ] Verify end-to-end loop: Detect -> Explain -> Assign -> Complete -> Reduce
