# Burnout Radar Frontend

Flutter frontend for Burnout Radar. It is local-first, guest-first, and designed to keep the core app usable offline while syncing to the backend only when an authenticated session exists.

## Purpose
- Capture daily burnout check-ins, recovery actions, focus sessions, and alerts.
- Keep the UI responsive from local SQLite/Drift storage as the source of truth.
- Integrate with Android Health Connect for sleep and exercise signals.
- Sync local changes to the backend only after login or session restore.

## Key UX / Features
- Dashboard with latest burnout score, trend, causes, tasks, and alerts.
- Daily check-in flow with quick-select mood/work controls.
- Health Connect-backed sleep and exercise chips, with manual fallback when needed.
- Recovery tasks, pomodoro/focus tracking, breathing sessions, and alert history.
- Profile entry point for login, register, logout, and session recovery.

## Local-First / Offline Behavior
- Core screens work without login and without network access.
- Reads come from local Drift tables first.
- New local rows start unsynced and are pushed later when auth + network are available.
- Sync failures do not block the UI.

## Auth-Gated Sync
- Sync runs only when a valid auth session exists.
- Triggered on app bootstrap, every 2 minutes, and immediately after login/register/session restore.
- Sync order is push unsynced local rows first, then pull remote rows and upsert locally.

## Health Connect
- Android-only frontend integration for check-in sourcing.
- Sleep and exercise are read from Health Connect by default.
- When Health Connect is unavailable, the app falls back to safe defaults and lets the user connect now or log manually.
- Health Connect setup requirements are documented in [`health_connect_frontend.md`](docs/health_connect_frontend.md).

## Setup and Run on an Android Device
1. Start the backend locally on port `3000`.
2. Connect the phone over USB with Developer Options and USB debugging enabled.
3. Reverse the backend port to the device:
   ```bash
   adb reverse tcp:3000 tcp:3000
   ```
4. From `frontend/`, install deps and run the app:
   ```bash
   flutter pub get
   flutter run --dart-define=API_BASE_URL=http://localhost:3000
   ```
5. If multiple devices are connected, add `-d <device_id>` to `flutter run`.

## Env Config
- Supported config source: `frontend/.env`
- Supported fallback: `--dart-define=API_BASE_URL=...`
- Default API base URL: `http://localhost:3000`
- Minimal local config:
  ```env
  API_BASE_URL=http://localhost:3000
  ```

## Docs
- [Architecture](docs/architecture.md)
- [API Contract](docs/api_contract.md)
- [Health Connect Frontend](docs/health_connect_frontend.md)
- [Offline Sync](docs/offline_sync.md)
- [Manual QA Checklist](docs/manual_qa_checklist.md)
