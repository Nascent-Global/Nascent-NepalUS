import { randomUUID } from 'node:crypto';
import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { AlertType, BurnoutClassification, BurnoutCauseType, Prisma, TaskType } from '@prisma/client';

import { env } from '../config/env.js';
import { durationToMs, hashPassword, hashToken, verifyPassword } from '../lib/auth.js';
import { parseDateOnly, startOfUtcDay } from '../lib/date.js';
import { rangeFromQuery } from '../lib/query.js';
import { sendFail, sendOk } from '../lib/response.js';
import {
  serializeAlert,
  serializeBreathingSession,
  serializeBurnoutCause,
  serializeBurnoutScore,
  serializeDailyEntry,
  serializePomodoroSession,
  serializeProfile,
  serializeScoreLog,
  serializeTask,
  serializeUserAccount,
} from '../lib/serialize.js';
import { buildDashboard } from '../services/dashboard.service.js';

function classificationFromScore(score: number): BurnoutClassification {
  if (score <= 30) return BurnoutClassification.LOW;
  if (score <= 70) return BurnoutClassification.MEDIUM;
  return BurnoutClassification.HIGH;
}

function classificationFromInput(
  classification: 'low' | 'medium' | 'high',
): BurnoutClassification {
  switch (classification) {
    case 'low':
      return BurnoutClassification.LOW;
    case 'medium':
      return BurnoutClassification.MEDIUM;
    case 'high':
      return BurnoutClassification.HIGH;
  }
}

const rangeDateInput = z.string().refine((value) => {
  try {
    parseDateOnly(value);
    return true;
  } catch {
    return false;
  }
}, 'Invalid date value');

function buildDate(value: string): Date {
  return parseDateOnly(value);
}

function buildUserAggregate(user: { id: string; email: string; passwordHash: string; isActive: boolean; lastLoginAt: Date | null; createdAt: Date; updatedAt: Date }, profile: { username: string; avatar: string; timezone: string; createdAt: Date; updatedAt: Date } | null) {
  return serializeUserAccount(user as any, profile as any);
}

export const routesPlugin: FastifyPluginAsync = async (fastify) => {
  fastify.get('/health', async () => ({ ok: true, data: { status: 'ok', service: 'burnout-radar-backend' } }));

  const issueSessionTokens = async (
    tx: Prisma.TransactionClient,
    userId: string,
    email: string,
  ) => {
    const sessionId = randomUUID();

    const token = fastify.jwt.sign(
      { email, sub: userId, sid: sessionId, token_type: 'access' },
      { jti: randomUUID(), expiresIn: env.ACCESS_TOKEN_EXPIRES_IN },
    );

    const refreshToken = fastify.jwt.sign(
      { email, sub: userId, sid: sessionId, token_type: 'refresh' },
      { jti: randomUUID(), expiresIn: env.REFRESH_TOKEN_EXPIRES_IN },
    );

    await tx.authSession.create({
      data: {
        id: sessionId,
        userId,
        tokenHash: hashToken(token),
        refreshToken: hashToken(refreshToken),
        expiresAt: new Date(
          Date.now() + durationToMs(env.REFRESH_TOKEN_EXPIRES_IN),
        ),
      },
    });

    return { token, refreshToken };
  };

  fastify.post('/auth/register', {
    schema: {
      body: {
        type: 'object',
        additionalProperties: false,
        required: ['email', 'password', 'username', 'timezone'],
        properties: {
          email: { type: 'string', format: 'email' },
          password: { type: 'string', minLength: 6 },
          username: { type: 'string', minLength: 2 },
          timezone: { type: 'string', minLength: 1 },
          avatar: { type: 'string' },
        },
      },
    },
  }, async (request, reply) => {
    const parsed = z.object({
      email: z.string().email(),
      password: z.string().min(6),
      username: z.string().min(2),
      timezone: z.string().min(1),
      avatar: z.string().optional(),
    }).safeParse(request.body);

    if (!parsed.success) {
      return sendFail(reply, 'VALIDATION_ERROR', 'Validation failed', parsed.error.flatten(), 400);
    }

    const email = parsed.data.email.toLowerCase();
    const existing = await fastify.prisma.userAccount.findUnique({ where: { email } });
    if (existing) {
      return sendFail(reply, 'CONFLICT', 'An account with this email already exists', undefined, 409);
    }

    const passwordHash = await hashPassword(parsed.data.password);
    const user = await fastify.prisma.$transaction(async (tx) => {
      const createdUser = await tx.userAccount.create({
        data: {
          id: randomUUID(),
          email,
          passwordHash,
          profile: {
            create: {
              id: randomUUID(),
              username: parsed.data.username,
              avatar: parsed.data.avatar ?? 'avatar_1',
              timezone: parsed.data.timezone,
            },
          },
          lastLoginAt: new Date(),
        },
        include: { profile: true },
      });

      const tokens = await issueSessionTokens(
        tx,
        createdUser.id,
        createdUser.email,
      );

      return { createdUser, ...tokens };
    });

    return sendOk(
      reply,
      {
        token: user.token,
        refresh_token: user.refreshToken,
        user: buildUserAggregate(user.createdUser as any, user.createdUser.profile as any),
      },
      201,
    );
  });

  fastify.post('/auth/login', {
    schema: {
      body: {
        type: 'object',
        additionalProperties: false,
        required: ['email', 'password'],
        properties: {
          email: { type: 'string', format: 'email' },
          password: { type: 'string', minLength: 1 },
        },
      },
    },
  }, async (request, reply) => {
    const parsed = z.object({
      email: z.string().email(),
      password: z.string().min(1),
    }).safeParse(request.body);

    if (!parsed.success) {
      return sendFail(reply, 'VALIDATION_ERROR', 'Validation failed', parsed.error.flatten(), 400);
    }

    const email = parsed.data.email.toLowerCase();
    const user = await fastify.prisma.userAccount.findUnique({ where: { email }, include: { profile: true } });
    if (!user || !(await verifyPassword(parsed.data.password, user.passwordHash))) {
      return sendFail(reply, 'UNAUTHORIZED', 'Invalid email or password', undefined, 401);
    }

    const tokens = await fastify.prisma.$transaction(async (tx) => {
      await tx.userAccount.update({ where: { id: user.id }, data: { lastLoginAt: new Date() } });
      return issueSessionTokens(tx, user.id, user.email);
    });

    return sendOk(reply, {
      token: tokens.token,
      refresh_token: tokens.refreshToken,
      user: buildUserAggregate(user as any, user.profile as any),
    });
  });

  fastify.post('/auth/refresh', async (request, reply) => {
    const parsed = z
      .object({
        refresh_token: z.string().min(1),
      })
      .safeParse(request.body);

    if (!parsed.success) {
      return sendFail(
        reply,
        'VALIDATION_ERROR',
        'Validation failed',
        parsed.error.flatten(),
        400,
      );
    }

    type RefreshPayload = {
      sub: string;
      email: string;
      sid: string;
      token_type: 'access' | 'refresh';
    };
    let payload: RefreshPayload | undefined;
    try {
      payload = await fastify.jwt.verify<RefreshPayload>(
        parsed.data.refresh_token,
      );
    } catch {
      return sendFail(reply, 'UNAUTHORIZED', 'Invalid refresh token', undefined, 401);
    }

    if (!payload || payload.token_type !== 'refresh') {
      return sendFail(reply, 'UNAUTHORIZED', 'Invalid token type', undefined, 401);
    }

    const refreshHash = hashToken(parsed.data.refresh_token);
    const session = await fastify.prisma.authSession.findFirst({
      where: {
        id: payload.sid,
        userId: payload.sub,
        refreshToken: refreshHash,
        revokedAt: null,
        expiresAt: { gt: new Date() },
      },
      include: {
        user: { include: { profile: true } },
      },
    });

    if (!session) {
      return sendFail(
        reply,
        'UNAUTHORIZED',
        'Refresh token is invalid or expired',
        undefined,
        401,
      );
    }

    const rotatedTokens = await fastify.prisma.$transaction(async (tx) => {
      await tx.authSession.update({
        where: { id: session.id },
        data: { revokedAt: new Date() },
      });

      await tx.userAccount.update({
        where: { id: session.userId },
        data: { lastLoginAt: new Date() },
      });

      return issueSessionTokens(tx, session.userId, session.user.email);
    });

    return sendOk(reply, {
      token: rotatedTokens.token,
      refresh_token: rotatedTokens.refreshToken,
      user: buildUserAggregate(session.user as any, session.user.profile as any),
    });
  });

  fastify.get('/auth/me', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const user = await fastify.prisma.userAccount.findUnique({ where: { id: request.user.sub }, include: { profile: true } });
    if (!user) {
      return sendFail(reply, 'NOT_FOUND', 'User not found', undefined, 404);
    }

    return sendOk(reply, { user: buildUserAggregate(user as any, user.profile as any) });
  });

  fastify.post(
    '/auth/logout',
    { preHandler: [fastify.authenticate] },
    async (request, reply) => {
      await fastify.prisma.authSession.updateMany({
        where: {
          id: request.user.sid,
          userId: request.user.sub,
          revokedAt: null,
        },
        data: {
          revokedAt: new Date(),
        },
      });

      return sendOk(reply, { logged_out: true });
    },
  );

  fastify.put('/user-profile', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = z.object({
      username: z.string().min(2),
      avatar: z.string().min(1),
      timezone: z.string().min(1),
    }).parse(request.body);

    const existing = await fastify.prisma.userProfile.upsert({
      where: { userId: request.user.sub },
      create: {
        id: randomUUID(),
        userId: request.user.sub,
        username: body.username,
        avatar: body.avatar,
        timezone: body.timezone,
      },
      update: {
        username: body.username,
        avatar: body.avatar,
        timezone: body.timezone,
      },
    });

    return sendOk(reply, serializeProfile(existing));
  });

  fastify.get('/user-profile', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const profile = await fastify.prisma.userProfile.findUnique({ where: { userId: request.user.sub } });
    if (!profile) {
      return sendFail(reply, 'NOT_FOUND', 'Profile not found', undefined, 404);
    }
    return sendOk(reply, serializeProfile(profile));
  });

  fastify.post('/daily-entries', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = z.object({
      id: z.string().uuid().optional(),
      date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
      sleep_hours: z.number().optional().nullable(),
      work_hours: z.number().optional().nullable(),
      mood: z.number().int().min(1).max(5),
      was_ok: z.boolean().optional().nullable(),
    }).parse(request.body);

    const entry = await fastify.prisma.dailyEntry.create({
      data: {
        id: body.id ?? randomUUID(),
        userId: request.user.sub,
        date: buildDate(body.date),
        sleepHours: body.sleep_hours ?? null,
        workHours: body.work_hours ?? null,
        mood: body.mood,
        wasOk: body.was_ok ?? null,
      },
    });

    return sendOk(reply, serializeDailyEntry(entry), 201);
  });

  fastify.get('/daily-entries', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const query = z.object({ from: rangeDateInput.optional(), to: rangeDateInput.optional(), limit: z.coerce.number().int().positive().max(100).default(50), offset: z.coerce.number().int().nonnegative().default(0) }).parse(request.query);
    const range = rangeFromQuery(query.from, query.to);

    const entries = await fastify.prisma.dailyEntry.findMany({
      where: { userId: request.user.sub, date: { gte: range.from, lte: range.to } },
      orderBy: { createdAt: 'desc' },
      take: query.limit,
      skip: query.offset,
    });

    return sendOk(reply, entries.map(serializeDailyEntry));
  });

  fastify.post('/burnout-scores', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = z.object({
      id: z.string().uuid().optional(),
      date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
      score: z.number().int().min(0).max(100),
      classification: z.enum(['low', 'medium', 'high']).optional(),
    }).parse(request.body);

    const score = await fastify.prisma.burnoutScore.create({
      data: {
        id: body.id ?? randomUUID(),
        userId: request.user.sub,
        date: buildDate(body.date),
        score: body.score,
        classification: body.classification
          ? classificationFromInput(body.classification)
          : classificationFromScore(body.score),
      },
    });

    return sendOk(reply, serializeBurnoutScore(score), 201);
  });

  fastify.get('/burnout-scores/latest', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const score = await fastify.prisma.burnoutScore.findFirst({
      where: { userId: request.user.sub },
      orderBy: { createdAt: 'desc' },
      include: { causes: true },
    });
    return sendOk(reply, score ? serializeBurnoutScore(score, score.causes) : null);
  });

  fastify.get('/burnout-scores', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const query = z.object({ from: rangeDateInput.optional(), to: rangeDateInput.optional(), limit: z.coerce.number().int().positive().max(100).default(50), offset: z.coerce.number().int().nonnegative().default(0) }).parse(request.query);
    const range = rangeFromQuery(query.from, query.to);

    const scores = await fastify.prisma.burnoutScore.findMany({
      where: { userId: request.user.sub, date: { gte: range.from, lte: range.to } },
      orderBy: { createdAt: 'desc' },
      take: query.limit,
      skip: query.offset,
      include: { causes: true },
    });

    return sendOk(reply, scores.map((score) => serializeBurnoutScore(score, score.causes)));
  });

  fastify.post('/burnout-causes', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = z.object({
      score_id: z.string().uuid(),
      causes: z.array(z.nativeEnum(BurnoutCauseType)).min(1),
    }).parse(request.body);

    const score = await fastify.prisma.burnoutScore.findFirst({ where: { id: body.score_id, userId: request.user.sub } });
    if (!score) {
      return sendFail(reply, 'NOT_FOUND', 'Score not found', undefined, 404);
    }

    const causes = await fastify.prisma.$transaction(
      body.causes.map((causeType) => fastify.prisma.burnoutCause.upsert({
        where: { scoreId_causeType: { scoreId: body.score_id, causeType } },
        update: {},
        create: { id: randomUUID(), scoreId: body.score_id, causeType },
      })),
    );

    return sendOk(reply, causes.map(serializeBurnoutCause), 201);
  });

  fastify.get('/burnout-causes', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const query = z.object({ score_id: z.string().uuid() }).parse(request.query);
    const score = await fastify.prisma.burnoutScore.findFirst({ where: { id: query.score_id, userId: request.user.sub } });
    if (!score) {
      return sendFail(reply, 'NOT_FOUND', 'Score not found', undefined, 404);
    }

    const causes = await fastify.prisma.burnoutCause.findMany({
      where: { scoreId: query.score_id },
      orderBy: { createdAt: 'asc' },
    });
    return sendOk(reply, causes.map(serializeBurnoutCause));
  });

  fastify.post('/tasks', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = z.object({
      id: z.string().uuid().optional(),
      date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
      title: z.string().min(1),
      deadline: z.string().datetime().optional().nullable(),
      priority: z.number().int().optional().nullable(),
      completed: z.boolean().optional(),
      task_type: z.enum(['user', 'recovery']).default('user'),
    }).parse(request.body);

    const task = await fastify.prisma.task.create({
      data: {
        id: body.id ?? randomUUID(),
        userId: request.user.sub,
        date: buildDate(body.date),
        title: body.title,
        deadline: body.deadline ? new Date(body.deadline) : null,
        priority: body.priority ?? null,
        completed: body.completed ?? false,
        taskType: body.task_type === 'recovery' ? TaskType.RECOVERY : TaskType.USER,
      },
    });

    return sendOk(reply, serializeTask(task), 201);
  });

  fastify.get('/tasks', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const query = z.object({ date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(), limit: z.coerce.number().int().positive().max(100).default(50), offset: z.coerce.number().int().nonnegative().default(0) }).parse(request.query);
    const date = buildDate(query.date ?? startOfUtcDay(new Date()).toISOString().slice(0, 10));
    const tasks = await fastify.prisma.task.findMany({
      where: { userId: request.user.sub, date },
      orderBy: [{ completed: 'asc' }, { createdAt: 'desc' }],
      take: query.limit,
      skip: query.offset,
    });
    return sendOk(reply, tasks.map(serializeTask));
  });

  fastify.patch('/tasks/:id', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const params = z.object({ id: z.string().uuid() }).parse(request.params);
    const body = z.object({
      date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
      title: z.string().min(1).optional(),
      deadline: z.string().datetime().nullable().optional(),
      priority: z.number().int().nullable().optional(),
      completed: z.boolean().optional(),
      task_type: z.enum(['user', 'recovery']).optional(),
    }).parse(request.body ?? {});

    const existing = await fastify.prisma.task.findFirst({ where: { id: params.id, userId: request.user.sub } });
    if (!existing) {
      return sendFail(reply, 'NOT_FOUND', 'Task not found', undefined, 404);
    }

    const task = await fastify.prisma.task.update({
      where: { id: params.id },
      data: {
        ...(body.date ? { date: buildDate(body.date) } : {}),
        ...(body.title ? { title: body.title } : {}),
        ...(body.deadline === undefined ? {} : { deadline: body.deadline ? new Date(body.deadline) : null }),
        ...(body.priority === undefined ? {} : { priority: body.priority }),
        ...(body.completed === undefined ? {} : { completed: body.completed }),
        ...(body.task_type ? { taskType: body.task_type === 'recovery' ? TaskType.RECOVERY : TaskType.USER } : {}),
      },
    });

    return sendOk(reply, serializeTask(task));
  });

  fastify.post('/score-logs', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = z.object({
      id: z.string().uuid().optional(),
      score_id: z.string().uuid(),
      change_amount: z.number().int(),
      reason: z.string().optional().nullable(),
    }).parse(request.body);

    const score = await fastify.prisma.burnoutScore.findFirst({ where: { id: body.score_id, userId: request.user.sub } });
    if (!score) {
      return sendFail(reply, 'NOT_FOUND', 'Score not found', undefined, 404);
    }

    const log = await fastify.prisma.scoreLog.create({
      data: {
        id: body.id ?? randomUUID(),
        userId: request.user.sub,
        scoreId: body.score_id,
        changeAmount: body.change_amount,
        reason: body.reason ?? null,
      },
    });

    return sendOk(reply, serializeScoreLog(log), 201);
  });

  fastify.get('/score-logs', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const query = z.object({ score_id: z.string().uuid().optional(), limit: z.coerce.number().int().positive().max(100).default(50), offset: z.coerce.number().int().nonnegative().default(0) }).parse(request.query);
    const logs = await fastify.prisma.scoreLog.findMany({
      where: { userId: request.user.sub, ...(query.score_id ? { scoreId: query.score_id } : {}) },
      orderBy: { createdAt: 'desc' },
      take: query.limit,
      skip: query.offset,
    });
    return sendOk(reply, logs.map(serializeScoreLog));
  });

  fastify.post('/pomodoro-sessions', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = z.object({
      id: z.string().uuid().optional(),
      start_time: z.string().datetime(),
      end_time: z.string().datetime().optional().nullable(),
      duration: z.number().int().optional().nullable(),
      completed: z.boolean().optional().nullable(),
      task_label: z.string().optional().nullable(),
    }).parse(request.body);

    const session = await fastify.prisma.pomodoroSession.create({
      data: {
        id: body.id ?? randomUUID(),
        userId: request.user.sub,
        startTime: new Date(body.start_time),
        endTime: body.end_time ? new Date(body.end_time) : null,
        duration: body.duration ?? null,
        completed: body.completed ?? null,
        taskLabel: body.task_label ?? null,
      },
    });

    return sendOk(reply, serializePomodoroSession(session), 201);
  });

  fastify.patch('/pomodoro-sessions/:id', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const params = z.object({ id: z.string().uuid() }).parse(request.params);
    const body = z.object({
      end_time: z.string().datetime().nullable().optional(),
      duration: z.number().int().nullable().optional(),
      completed: z.boolean().nullable().optional(),
      task_label: z.string().nullable().optional(),
    }).parse(request.body ?? {});

    const existing = await fastify.prisma.pomodoroSession.findFirst({ where: { id: params.id, userId: request.user.sub } });
    if (!existing) {
      return sendFail(reply, 'NOT_FOUND', 'Session not found', undefined, 404);
    }

    const session = await fastify.prisma.pomodoroSession.update({
      where: { id: params.id },
      data: {
        ...(body.end_time === undefined ? {} : { endTime: body.end_time ? new Date(body.end_time) : null }),
        ...(body.duration === undefined ? {} : { duration: body.duration }),
        ...(body.completed === undefined ? {} : { completed: body.completed }),
        ...(body.task_label === undefined ? {} : { taskLabel: body.task_label }),
      },
    });

    return sendOk(reply, serializePomodoroSession(session));
  });

  fastify.get('/pomodoro-sessions', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const query = z.object({ from: rangeDateInput.optional(), to: rangeDateInput.optional(), limit: z.coerce.number().int().positive().max(100).default(50), offset: z.coerce.number().int().nonnegative().default(0) }).parse(request.query);
    const range = rangeFromQuery(query.from, query.to);
    const sessions = await fastify.prisma.pomodoroSession.findMany({
      where: { userId: request.user.sub, startTime: { gte: range.from, lte: range.to } },
      orderBy: { startTime: 'desc' },
      take: query.limit,
      skip: query.offset,
    });
    return sendOk(reply, sessions.map(serializePomodoroSession));
  });

  fastify.post('/breathing-sessions', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = z.object({
      id: z.string().uuid().optional(),
      started_at: z.string().datetime(),
      duration: z.number().int(),
      completed: z.boolean(),
    }).parse(request.body);

    const session = await fastify.prisma.breathingSession.create({
      data: {
        id: body.id ?? randomUUID(),
        userId: request.user.sub,
        startedAt: new Date(body.started_at),
        duration: body.duration,
        completed: body.completed,
      },
    });

    return sendOk(reply, serializeBreathingSession(session), 201);
  });

  fastify.patch('/breathing-sessions/:id', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const params = z.object({ id: z.string().uuid() }).parse(request.params);
    const body = z.object({
      duration: z.number().int().optional(),
      completed: z.boolean().optional(),
    }).parse(request.body ?? {});

    const existing = await fastify.prisma.breathingSession.findFirst({ where: { id: params.id, userId: request.user.sub } });
    if (!existing) {
      return sendFail(reply, 'NOT_FOUND', 'Session not found', undefined, 404);
    }

    const session = await fastify.prisma.breathingSession.update({
      where: { id: params.id },
      data: {
        ...(body.duration === undefined ? {} : { duration: body.duration }),
        ...(body.completed === undefined ? {} : { completed: body.completed }),
      },
    });

    return sendOk(reply, serializeBreathingSession(session));
  });

  fastify.get('/breathing-sessions', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const query = z.object({ from: rangeDateInput.optional(), to: rangeDateInput.optional(), limit: z.coerce.number().int().positive().max(100).default(50), offset: z.coerce.number().int().nonnegative().default(0) }).parse(request.query);
    const range = rangeFromQuery(query.from, query.to);
    const sessions = await fastify.prisma.breathingSession.findMany({
      where: { userId: request.user.sub, startedAt: { gte: range.from, lte: range.to } },
      orderBy: { startedAt: 'desc' },
      take: query.limit,
      skip: query.offset,
    });
    return sendOk(reply, sessions.map(serializeBreathingSession));
  });

  fastify.post('/alerts', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const body = z.object({
      id: z.string().uuid().optional(),
      date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().nullable(),
      type: z.nativeEnum(AlertType),
      message: z.string().min(1),
    }).parse(request.body);

    const alert = await fastify.prisma.alert.create({
      data: {
        id: body.id ?? randomUUID(),
        userId: request.user.sub,
        date: body.date ? buildDate(body.date) : null,
        type: body.type,
        message: body.message,
      },
    });

    return sendOk(reply, serializeAlert(alert), 201);
  });

  fastify.get('/alerts', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const query = z.object({ from: rangeDateInput.optional(), to: rangeDateInput.optional(), limit: z.coerce.number().int().positive().max(100).default(50), offset: z.coerce.number().int().nonnegative().default(0) }).parse(request.query);
    const range = rangeFromQuery(query.from, query.to);
    const alerts = await fastify.prisma.alert.findMany({
      where: { userId: request.user.sub, createdAt: { gte: range.from, lte: range.to } },
      orderBy: { createdAt: 'desc' },
      take: query.limit,
      skip: query.offset,
    });
    return sendOk(reply, alerts.map(serializeAlert));
  });

  fastify.get('/dashboard', { preHandler: [fastify.authenticate] }, async (request, reply) => {
    const dashboard = await buildDashboard(fastify.prisma, request.user.sub);
    return sendOk(reply, dashboard);
  });
};
