import '@fastify/jwt';

declare module '@fastify/jwt' {
  interface FastifyJWT {
    payload: {
      email: string;
      sub: string;
      sid: string;
      token_type: 'access' | 'refresh';
    };
    user: {
      sub: string;
      email: string;
      sid: string;
      token_type: 'access' | 'refresh';
      iat: number;
      exp: number;
      jti: string;
    };
  }
}
