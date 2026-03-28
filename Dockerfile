# Dockerfile for Nascent-NepalUS Django backend
# Base image: Python 3.14.3 slim variant
# Multi-stage is omitted for simplicity; optimized for hackathon use.
#
# Build notes:
# - Expects a `requirements.txt` at the repo root (same directory as this Dockerfile).
# - Expects Django project package to be copied into /app (we copy the whole project).
# - Use environment variables in docker-compose to configure DB and django settings.
#
# Typical commands:
#  docker build -t nascent-backend:latest .
#  docker run --env-file .env -p 8000:8000 nascent-backend:latest

FROM python:3.14.3-slim AS base

# Prevent Python from writing .pyc files and enable unbuffered stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set a production-friendly working directory
WORKDIR /app

# Install system dependencies required for building Python packages (e.g. psycopg2)
# Keep packages minimal to reduce image size.
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        gcc \
        libpq-dev \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Add a non-root user to run the app
ARG APP_USER=appuser
ARG APP_UID=1000
RUN groupadd -g ${APP_UID} ${APP_USER} \
    && useradd -m -u ${APP_UID} -g ${APP_UID} -s /bin/bash ${APP_USER}

# Copy only requirements first for better layer caching
# Expect a requirements.txt in the build context (repo root)
COPY requirements.txt /app/requirements.txt

# Install Python dependencies
# Use --no-cache-dir to reduce final image size
RUN pip install --upgrade pip \
    && pip install --no-cache-dir -r /app/requirements.txt

# Copy the rest of the application code
COPY ./backend/ /app

# Ensure the non-root user owns the app directory
RUN chown -R ${APP_USER}:${APP_USER} /app

# Switch to non-root user
USER ${APP_USER}

# Expose port that Django/ Gunicorn will bind to
EXPOSE 8000

# Default environment variables (can be overridden by docker-compose / env files)
ENV DJANGO_SETTINGS_MODULE=config.settings
ENV PYTHONPATH=/app

# Prefer using Gunicorn in production/deploy; fallback to manage.py runserver if not present.
# The `CMD` below assumes your Django project root package is named `backend` and that
#
# If you want to run Django development server instead, replace CMD with:
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
#
# CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "3", "--timeout", "120"]
