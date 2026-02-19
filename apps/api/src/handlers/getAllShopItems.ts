import type { Context } from 'hono';
import { getAllShopItems } from '@wcc/core';

export async function getAllShopItemsHandler(c: Context) {
  try {
    const payload = await c.req.json();
    const result = await getAllShopItems(payload);
    return c.json(result);
  } catch (error) {
    console.error('[shop] all items error', error);
    return c.json({ error: 'Failed to load all shop items' }, 400);
  }
}

