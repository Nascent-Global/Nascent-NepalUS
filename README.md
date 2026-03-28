# Nascent-NepalUS

A lightweight Django + DRF backend for the Burnout Reduction MVP (Nascent-NepalUS).  
This repo contains a Dockerized development environment (Postgres DB + Adminer) and a Django project under `backend/` with project package `config`.

This README explains how to start the project, required environment variables, how to contribute, and common troubleshooting notes.

---

## Quick start (Docker, recommended for hackathon)

1. Copy example environment file and edit secrets:
- Copy `.env.example` to `.env` and fill sensible values (especially `POSTGRES_PASSWORD` and `SECRET_KEY`):
  - `cp .env.example .env`
  - Edit `.env` with your editor and set `SECRET_KEY`, `POSTGRES_PASSWORD`, and other vars.

2. Build and run with Docker Compose:
- Start in the foreground (shows logs):
  - `docker compose up --build`
- Start detached:
  - `docker compose up -d --build`

3. Useful commands:
- Show web logs: `docker compose logs -f web`
- Run migrations manually: `docker compose exec web python manage.py migrate`
- Create a superuser interactively: `docker compose exec web python manage.py createsuperuser`
- Enter a shell in the web container: `docker compose exec web sh`

4. Ports:
- Django app: http://localhost:8000
- Adminer DB GUI: http://localhost:8080
- Postgres (host): configured by `POSTGRES_PORT` in `.env` (default 5432)

---

## Quick start (without Docker)

If you prefer a local Python environment:

1. Create & activate a virtualenv:
- `python -m venv .venv`
- `source .venv/bin/activate`

2. Install dependencies:
- `pip install -r requirements.txt`

3. Setup env vars:
- Copy `.env.example` to `.env` and export or load variables (or use `direnv`/`dotenv`).

4. Run migrations and start dev server:
- From repo root: `python backend/manage.py migrate`
- Start dev server: `python backend/manage.py runserver 0.0.0.0:8000`

---

## Required environment variables (see `.env.example`)

At minimum set:
- `SECRET_KEY` — Django secret (keep private)
- `DEBUG` — `1` or `0`
- `ALLOWED_HOSTS` — comma-separated hosts
- `POSTGRES_DB` — database name (e.g., `nascent`)
- `POSTGRES_USER` — DB user (e.g., `nascent`)
- `POSTGRES_PASSWORD` — DB password
- `POSTGRES_HOST` — typically `db` when using compose
- `POSTGRES_PORT` — default `5432`
- `GUNICORN_WORKERS` — optional for the web container

The repository includes `.env.example` with defaults and additional helpful envs (burnout weights, superuser vars).

---

## Starting flow summary

1. `cp .env.example .env` → edit sensitive values.
2. `docker compose up --build` → the `web` service runs migrations and starts the Django server.
3. Visit `http://localhost:8000` for the API and `http://localhost:8080` for Adminer (DB GUI).

If the web container fails on startup:
- Check `docker compose logs web` and `docker compose logs db`.
- Common fixes are described in the Troubleshooting section below.

---

## File layout and docs

- Django project root: `backend/`  
  - `backend/manage.py` — management entrypoint  
  - Django project package: `backend/config/` (settings, urls, wsgi)  
- App stubs: `core/`, `users/`, `tasks/`, `focus/`, `sleep/`, `analytics/` (may be empty until scaffolded)  
- Developer doc: `backend/FILE_STRUCTURE.md` — describes where to place models, serializers, services and how to add apps.

---

## How to contribute (short guide)

1. Branching:
- Use feature branches: `feature/<short-desc>` or `fix/<short-desc>`

2. Commit messages:
- Keep concise; include issue/task id if available.

3. Linting & formatting:
- Run `black .` and `flake8` (or configured linters) before opening a PR.

4. Tests:
- Add unit tests for new services and models.
- Run tests locally: `docker compose exec web python manage.py test` or `python backend/manage.py test`

5. Pull Request:
- Describe intent, migration requirements, and any API changes.
- Include screenshots or sample API responses where applicable.
- Ensure tests and linting pass.

6. Code review:
- Keep PRs small and focused. Prefer one responsibility per PR.

---

## Troubleshooting (common issues)

- `python: can't open file '/app/manage.py'` after starting containers:
  - If you bind-mount the project root into `/app` (`./:/app`), `/app/manage.py` may be missing because `manage.py` is located under `backend/manage.py`.
  - Fix: change the compose volume to mount `./backend:/app` (so `/app/manage.py` exists), or remove the mount to use code baked into the image.

- `Unknown command: 'collectstatic'`:
  - This happens if `django.contrib.staticfiles` is not in `INSTALLED_APPS`. Either re-enable it in settings or remove `collectstatic` from the startup command in `docker-compose.yml`.

- `You're using the staticfiles app without having set the STATIC_ROOT setting`:
  - Set `STATIC_ROOT` in `backend/config/settings.py`, e.g.:
    - `STATIC_ROOT = BASE_DIR / 'staticfiles'`
  - Ensure the `staticfiles` directory is writable by the container user (or set location inside the container).

- DB not ready / web fails to connect:
  - Check DB logs: `docker compose logs db`
  - Retry migrations manually: `docker compose exec web python manage.py migrate`

---

## Additional suggestions for hackathon/demo

- Keep `DEBUG=1` for development; set `DEBUG=0` for public demos.
- For quick iteration, run the dev server instead of Gunicorn (the compose command can be changed to `runserver` for faster start).
- Commit migrations so teammates can run the project without generating schema diffs.

---

## Further automation (optional tasks you can request)
- Add a Makefile with common commands (`make build`, `make up`, `make console`).
- Add GitHub Actions to run tests and lint on PRs.
- Add simple Docker health-check scripts or a startup wait loop in the web entrypoint (for DB readiness).

---

Thanks — if you want, I can:
- Add a small `Contributing.md` with a PR template,
- Update `backend/config/settings.py` to include `STATIC_ROOT` and re-enable `django.contrib.staticfiles`,
- Or modify `docker-compose.yml` to mount `./backend:/app` which resolves the `manage.py` location issue.

Tell me which change you'd like me to apply next.