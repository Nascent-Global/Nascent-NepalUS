import { daysAgoUtc, endOfUtcDay, parseDateOnly, startOfUtcDay } from './date.js';

export function normalizeQueryDate(value: string | undefined, fallback = new Date()): Date {
  return value ? parseDateOnly(value) : fallback;
}

export function rangeFromQuery(from?: string, to?: string, defaultDays = 7): { from: Date; to: Date } {
  const endBase = to ? parseDateOnly(to) : new Date();
  const startBase = from ? parseDateOnly(from) : daysAgoUtc(defaultDays - 1, endBase);
  return {
    from: startOfUtcDay(startBase),
    to: endOfUtcDay(endBase),
  };
}
