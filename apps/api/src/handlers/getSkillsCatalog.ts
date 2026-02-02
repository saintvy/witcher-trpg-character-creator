import type { Context } from 'hono';
import { getSkillsCatalog } from '../services/skillsCatalog.js';

export async function getSkillsCatalogHandler(c: Context) {
  try {
    const payload = await c.req.json().catch(() => ({}));
    const result = await getSkillsCatalog(payload);
    return c.json(result);
  } catch (error) {
    console.error('[skills] catalog error', error);
    return c.json({ error: 'Failed to load skills catalog' }, 400);
  }
}

