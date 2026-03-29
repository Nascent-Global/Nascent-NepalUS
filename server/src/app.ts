import fastify from 'fastify';
import cors from '@fastify/cors';

import { env } from './config/env.js';
import { errorHandlerPlugin } from './plugins/error-handler.js';
import { jwtPlugin } from './plugins/jwt.js';
import { prismaPlugin } from './plugins/prisma.js';
import { swaggerPlugin } from './plugins/swagger.js';
import { routesPlugin } from './routes/index.js';

export function buildApp() {
  const app = fastify({ logger: true });

  app.register(cors, {
    origin: env.CORS_ORIGIN === '*' ? true : env.CORS_ORIGIN.split(',').map((value) => value.trim()).filter(Boolean),
  });

  app.register(errorHandlerPlugin);
  app.register(prismaPlugin);
  app.register(jwtPlugin);
  app.register(swaggerPlugin);
  app.register(routesPlugin);

  return app;
}
