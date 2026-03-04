import { createRemoteJWKSet, jwtVerify } from 'jose';
import type { MiddlewareHandler } from 'hono';

type AuthMode = 'none' | 'google-jwt' | 'trust-apigw';

export type AuthUser = {
  sub: string;
  email?: string;
  name?: string;
  picture?: string;
  provider: 'google' | 'cognito' | 'unknown';
};

const googleClientIds = (process.env.AUTH_GOOGLE_CLIENT_IDS ?? '')
  .split(',')
  .map((value) => value.trim())
  .filter(Boolean);
const authMode = (
  process.env.AUTH_MODE ??
  (googleClientIds.length > 0 ? 'google-jwt' : 'none')
) as AuthMode;
const protectHealth = process.env.AUTH_PROTECT_HEALTH !== 'false';

const googleJwks = createRemoteJWKSet(
  new URL('https://www.googleapis.com/oauth2/v3/certs'),
);

function getBearerToken(headerValue?: string): string | null {
  if (!headerValue) return null;
  const [scheme, token] = headerValue.split(/\s+/, 2);
  if (!scheme || !token || scheme.toLowerCase() !== 'bearer') return null;
  return token;
}

function decodeJwtPayloadUnverified(token: string): Record<string, unknown> {
  const parts = token.split('.');
  if (parts.length < 2) throw new Error('Invalid JWT');
  const base64 = parts[1]!.replace(/-/g, '+').replace(/_/g, '/');
  const padded = base64.padEnd(Math.ceil(base64.length / 4) * 4, '=');
  const payload = Buffer.from(padded, 'base64').toString('utf8');
  return JSON.parse(payload) as Record<string, unknown>;
}

function mapClaimsToUser(
  claims: Record<string, unknown>,
  provider: AuthUser['provider'],
): AuthUser {
  return {
    sub:
      (typeof claims.sub === 'string' && claims.sub) ||
      (typeof claims.username === 'string' && claims.username) ||
      'unknown',
    email: typeof claims.email === 'string' ? claims.email : undefined,
    name:
      (typeof claims.name === 'string' && claims.name) ||
      (typeof claims['cognito:username'] === 'string'
        ? claims['cognito:username']
        : undefined),
    picture: typeof claims.picture === 'string' ? claims.picture : undefined,
    provider,
  };
}

async function verifyGoogleIdToken(token: string): Promise<AuthUser> {
  if (googleClientIds.length === 0) {
    throw new Error(
      'Google auth is enabled but AUTH_GOOGLE_CLIENT_IDS is not configured',
    );
  }

  const { payload } = await jwtVerify(token, googleJwks, {
    issuer: ['https://accounts.google.com', 'accounts.google.com'],
    audience: googleClientIds,
  });

  return mapClaimsToUser(payload as Record<string, unknown>, 'google');
}

function trustApiGatewayToken(token: string): AuthUser {
  const payload = decodeJwtPayloadUnverified(token);

  const iss = typeof payload.iss === 'string' ? payload.iss : '';
  const provider = iss.includes('cognito-idp')
    ? 'cognito'
    : iss.includes('accounts.google.com')
    ? 'google'
    : 'unknown';

  return mapClaimsToUser(payload, provider);
}

export const authMiddleware: MiddlewareHandler = async (c, next) => {
  if (authMode === 'none') {
    return next();
  }

  if (c.req.method === 'OPTIONS') {
    return next();
  }

  if (!protectHealth && c.req.path === '/api/health') {
    return next();
  }

  const token = getBearerToken(c.req.header('Authorization'));
  if (!token) {
    return c.json({ error: 'Authorization required' }, 401);
  }

  try {
    const user =
      authMode === 'google-jwt'
        ? await verifyGoogleIdToken(token)
        : trustApiGatewayToken(token);
    c.set('authUser', user);
    return next();
  } catch (error) {
    console.error('[auth] token validation failed', error);
    return c.json({ error: 'Invalid authentication token' }, 401);
  }
};
