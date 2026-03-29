import type { PrismaClient } from '@prisma/client';

import { daysAgoUtc, endOfUtcDay, startOfUtcDay } from '../lib/date.js';

export async function buildDashboard(prisma: PrismaClient, userId: string) {
  const latestScore = await prisma.burnoutScore.findFirst({
    where: { userId },
    orderBy: { createdAt: 'desc' },
    include: { causes: true },
  });

  const today = new Date();
  const todayStart = startOfUtcDay(today);
  const todayEnd = endOfUtcDay(today);
  const trendStart = daysAgoUtc(6, today);

  const [tasksToday, scores] = await Promise.all([
    prisma.task.findMany({
      where: { userId, date: todayStart },
      orderBy: [{ completed: 'asc' }, { createdAt: 'desc' }],
    }),
    prisma.burnoutScore.findMany({
      where: { userId, createdAt: { gte: trendStart, lte: todayEnd } },
      orderBy: { createdAt: 'asc' },
    }),
  ]);

  const grouped = new Map<string, { total: number; count: number }>();
  for (const score of scores) {
    const date = score.date.toISOString().slice(0, 10);
    const current = grouped.get(date) ?? { total: 0, count: 0 };
    current.total += score.score;
    current.count += 1;
    grouped.set(date, current);
  }

  return {
    latest_score: latestScore
      ? {
          id: latestScore.id,
          date: latestScore.date.toISOString().slice(0, 10),
          score: latestScore.score,
          classification: latestScore.classification.toLowerCase(),
          created_at: latestScore.createdAt.toISOString(),
          updated_at: latestScore.updatedAt.toISOString(),
        }
      : null,
    causes: latestScore?.causes.map((cause) => ({ id: cause.id, cause_type: cause.causeType })) ?? [],
    tasks_today: tasksToday.map((task) => ({
      id: task.id,
      date: task.date.toISOString().slice(0, 10),
      title: task.title,
      deadline: task.deadline?.toISOString() ?? null,
      priority: task.priority,
      completed: task.completed,
      task_type: task.taskType.toLowerCase(),
      created_at: task.createdAt.toISOString(),
      updated_at: task.updatedAt.toISOString(),
    })),
    trend: [...grouped.entries()].map(([date, value]) => ({ date, score: Math.round(value.total / value.count) })),
  };
}
