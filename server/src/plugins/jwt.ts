import fp from 'fastify-plugin';
import fastifyJwt from '@fastify/jwt';
import type { FastifyPluginAsync, FastifyReply, FastifyRequest } from 'fastify';

import { env } from '../config/env.js';
import { fail } from '../lib/response.js';
import { hashToken } from '../lib/auth.js';

export const jwtPlugin: FastifyPluginAsync = fp(async (fastify) => {
  fastify.register(fastifyJwt, { secret: env.JWT_SECRET });

  fastify.decorate('authenticate', async function authenticate(request: FastifyRequest, reply: FastifyReply) {
    try {
      await request.jwtVerify();
    } catch {
      return reply.status(401).send(fail('UNAUTHORIZED', 'Unauthorized'));
    }

    const authorization = request.headers.authorization;
    const token = authorization?.startsWith('Bearer ')
      ? authorization.slice('Bearer '.length)
      : null;

    if (!token) {
      return reply.status(401).send(fail('UNAUTHORIZED', 'Missing bearer token'));
    }

    if (request.user.token_type !== 'access') {
      return reply.status(401).send(fail('UNAUTHORIZED', 'Invalid token type'));
    }

    const session = await fastify.prisma.authSession.findFirst({
      where: {
        id: request.user.sid,
        userId: request.user.sub,
        tokenHash: hashToken(token),
        revokedAt: null,
        expiresAt: { gt: new Date() },
      },
      select: { id: true },
    });

    if (!session) {
      return reply.status(401).send(fail('UNAUTHORIZED', 'Token is invalid or expired'));
    }
  });
});
