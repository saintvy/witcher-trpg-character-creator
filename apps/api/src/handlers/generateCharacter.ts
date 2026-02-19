import type { Context } from 'hono';
import { generateCharacterFromBody } from '@wcc/core';

export async function generateCharacter(c: Context): Promise<Record<string, unknown>> {
  const body = (await c.req.json().catch(() => ({}))) as unknown;
  const lang = c.req.query('lang') || c.req.header('Accept-Language')?.split(',')[0]?.split('-')[0] || 'en';

  const result = await generateCharacterFromBody(body, lang);
  return result;
}
