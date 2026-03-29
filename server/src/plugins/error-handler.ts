import type { FastifyPluginAsync } from 'fastify';
import fp from 'fastify-plugin';
import { Prisma } from '@prisma/client';
import { ZodError } from 'zod';

import { fail, type ApiErrorCode } from '../lib/response.js';

export const errorHandlerPlugin: FastifyPluginAsync = fp(async (fastify) => {
  fastify.setErrorHandler((error, request, reply) => {
    if (error instanceof ZodError) {
      return reply
        .status(400)
        .send(fail('VALIDATION_ERROR', 'Validation failed', error.flatten()));
    }

    if ((error as any).validation) {
      return reply.status(400).send(fail('VALIDATION_ERROR', 'Validation failed', (error as any).validation));
    }

    if ((error as any).code === 'FST_JWT_NO_AUTHORIZATION_IN_HEADER' || (error as any).code === 'FST_JWT_AUTHORIZATION_TOKEN_INVALID') {
      return reply.status(401).send(fail('UNAUTHORIZED', 'Unauthorized'));
    }

    if (error instanceof Prisma.PrismaClientKnownRequestError) {
      if (error.code === 'P2002') {
        return reply.status(409).send(fail('CONFLICT', 'Resource already exists', error.meta));
      }
      if (error.code === 'P2025') {
        return reply.status(404).send(fail('NOT_FOUND', 'Resource not found'));
      }
    }

    request.log.error({ err: error }, 'Unhandled error');
    return reply.status(500).send(fail('INTERNAL_SERVER_ERROR', 'Internal server error'));
  });
});
