# Manual QA Checklist

## Core Flow
- [ ] Submit daily check-in and verify a new `daily_entries` row is created.
- [ ] Verify burnout score appears on dashboard with correct classification.
- [ ] Verify causes are shown after check-in.
- [ ] Verify 2-3 recovery tasks are generated when causes exist.
- [ ] Complete one recovery task and verify score decreases via new snapshot.

## Task and Pressure
- [ ] Add user task with priority and optional deadline.
- [ ] Confirm task pressure indicator updates.
- [ ] Confirm completed task remains persisted after app restart.

## Alerts
- [ ] Verify high-risk alert is inserted when score is 70 or above.
- [ ] Verify rising-trend alert when score increases by 5 or more day-over-day.
- [ ] Verify alerts list displays newest first.

## Sessions
- [ ] Start and complete a pomodoro session.
- [ ] Trigger breathing session and verify it is recorded.

## Reminders
- [ ] Enable daily reminders and confirm no runtime permission crash.
- [ ] Trigger quick reminder preview and verify notification appears.
- [ ] Disable daily reminders and confirm scheduled reminders are canceled.

## Persistence and Offline
- [ ] Close and reopen app; confirm dashboard/tasks/alerts remain.
- [ ] Disconnect internet; confirm all core features still function.
