import type { Context } from 'hono';
import { getShopSourceRows } from '../services/shopCatalog.js';

export async function shopSourceRows(c: Context) {
  try {
    const payload = await c.req.json();
    const result = await getShopSourceRows(payload);
    return c.json(result);
  } catch (error) {
    console.error('[shop] source rows error', error);
    return c.json({ error: 'Failed to load shop source rows' }, 400);
  }
}


