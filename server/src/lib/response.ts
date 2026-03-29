import type { FastifyReply } from 'fastify';

export type ApiErrorCode =
  | 'VALIDATION_ERROR'
  | 'UNAUTHORIZED'
  | 'FORBIDDEN'
  | 'NOT_FOUND'
  | 'CONFLICT'
  | 'INTERNAL_SERVER_ERROR';

export type ApiSuccess<T> = { ok: true; data: T };
export type ApiError = {
  ok: false;
  error: { code: ApiErrorCode; message: string; details?: unknown };
};

export function ok<T>(data: T): ApiSuccess<T> {
  return { ok: true, data };
}

export function fail(code: ApiErrorCode, message: string, details?: unknown): ApiError {
  return { ok: false, error: { code, message, ...(details === undefined ? {} : { details }) } };
}

export function sendOk<T>(reply: FastifyReply, data: T, status = 200): FastifyReply {
  return reply.status(status).send(ok(data));
}

export function sendFail(reply: FastifyReply, code: ApiErrorCode, message: string, details?: unknown, status = 400): FastifyReply {
  return reply.status(status).send(fail(code, message, details));
}
