import type {
  Alert,
  AuthSession,
  BreathingSession,
  BurnoutCause,
  BurnoutScore,
  DailyEntry,
  PomodoroSession,
  ScoreLog,
  Task,
  UserAccount,
  UserProfile,
  Prisma,
} from '@prisma/client';

import { toUtcDateOnly } from './date.js';

function iso(value: Date): string {
  return value.toISOString();
}

export function serializeUserAccount(user: UserAccount, profile?: UserProfile | null) {
  return {
    id: user.id,
    email: user.email,
    username: profile?.username ?? '',
    avatar: profile?.avatar ?? '',
    timezone: profile?.timezone ?? 'UTC',
    is_active: user.isActive,
    last_login_at: user.lastLoginAt ? iso(user.lastLoginAt) : null,
    created_at: iso(user.createdAt),
    updated_at: iso(user.updatedAt),
  };
}

export function serializeProfile(profile: UserProfile) {
  return {
    id: profile.id,
    user_id: profile.userId,
    username: profile.username,
    avatar: profile.avatar,
    timezone: profile.timezone,
    created_at: iso(profile.createdAt),
    updated_at: iso(profile.updatedAt),
  };
}

export function serializeDailyEntry(entry: DailyEntry) {
  return {
    id: entry.id,
    date: toUtcDateOnly(entry.date),
    sleep_hours: entry.sleepHours,
    work_hours: entry.workHours,
    mood: entry.mood,
    was_ok: entry.wasOk,
    synced: entry.synced,
    created_at: iso(entry.createdAt),
    updated_at: iso(entry.updatedAt),
  };
}

export function serializeBurnoutScore(score: BurnoutScore, causes: BurnoutCause[] = []) {
  return {
    id: score.id,
    date: toUtcDateOnly(score.date),
    score: score.score,
    classification: score.classification.toLowerCase(),
    synced: score.synced,
    causes: causes.map(serializeBurnoutCause),
    created_at: iso(score.createdAt),
    updated_at: iso(score.updatedAt),
  };
}

export function serializeBurnoutCause(cause: BurnoutCause) {
  return {
    id: cause.id,
    score_id: cause.scoreId,
    cause_type: cause.causeType,
    created_at: iso(cause.createdAt),
    updated_at: iso(cause.updatedAt),
  };
}

export function serializeTask(task: Task) {
  return {
    id: task.id,
    date: toUtcDateOnly(task.date),
    title: task.title,
    deadline: task.deadline ? iso(task.deadline) : null,
    priority: task.priority,
    completed: task.completed,
    task_type: task.taskType.toLowerCase(),
    synced: task.synced,
    created_at: iso(task.createdAt),
    updated_at: iso(task.updatedAt),
  };
}

export function serializeScoreLog(log: ScoreLog) {
  return {
    id: log.id,
    score_id: log.scoreId,
    change_amount: log.changeAmount,
    reason: log.reason,
    synced: log.synced,
    created_at: iso(log.createdAt),
    updated_at: iso(log.updatedAt),
  };
}

export function serializePomodoroSession(session: PomodoroSession) {
  return {
    id: session.id,
    start_time: iso(session.startTime),
    end_time: session.endTime ? iso(session.endTime) : null,
    duration: session.duration,
    completed: session.completed,
    task_label: session.taskLabel,
    synced: session.synced,
    created_at: iso(session.createdAt),
    updated_at: iso(session.updatedAt),
  };
}

export function serializeBreathingSession(session: BreathingSession) {
  return {
    id: session.id,
    started_at: iso(session.startedAt),
    duration: session.duration,
    completed: session.completed,
    synced: session.synced,
    created_at: iso(session.createdAt),
    updated_at: iso(session.updatedAt),
  };
}

export function serializeAlert(alert: Alert) {
  return {
    id: alert.id,
    date: alert.date ? toUtcDateOnly(alert.date) : null,
    type: alert.type,
    message: alert.message,
    synced: alert.synced,
    created_at: iso(alert.createdAt),
    updated_at: iso(alert.updatedAt),
  };
}

export function serializeSession(session: AuthSession) {
  return {
    id: session.id,
    user_id: session.userId,
    token_hash: session.tokenHash,
    expires_at: iso(session.expiresAt),
    revoked_at: session.revokedAt ? iso(session.revokedAt) : null,
    created_at: iso(session.createdAt),
    updated_at: iso(session.updatedAt),
  };
}
