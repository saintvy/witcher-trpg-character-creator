import { Hono } from 'hono';
import { cors } from 'hono/cors';
import {
  generateCharacterFromBody,
  getNextQuestion,
  getAllShopItems,
  getSkillsCatalog,
} from '@wcc/core';

const app = new Hono().basePath('/api');

const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',')
  : ['http://localhost:3100'];

app.use('*', cors({ origin: allowedOrigins }));

app.post('/generate-character', async (c) => {
  const body = (await c.req.json().catch(() => ({}))) as unknown;
  const lang =
    c.req.query('lang') ||
    c.req.header('Accept-Language')?.split(',')[0]?.split('-')[0] ||
    'en';
  const result = await generateCharacterFromBody(body, lang);
  return c.json(result);
});

app.post('/survey/next', async (c) => {
  try {
    const payload = await c.req.json();
    const result = await getNextQuestion(payload);
    return c.json(result);
  } catch (error) {
    console.error('[survey] next question error', error);
    return c.json({ error: 'Failed to resolve next question' }, 400);
  }
});

app.post('/shop/allItems', async (c) => {
  try {
    const payload = await c.req.json();
    const result = await getAllShopItems(payload);
    return c.json(result);
  } catch (error) {
    console.error('[shop] all items error', error);
    return c.json({ error: 'Failed to load all shop items' }, 400);
  }
});

app.post('/skills/catalog', async (c) => {
  try {
    const payload = await c.req.json().catch(() => ({}));
    const result = await getSkillsCatalog(payload);
    return c.json(result);
  } catch (error) {
    console.error('[skills] catalog error', error);
    return c.json({ error: 'Failed to load skills catalog' }, 400);
  }
});

app.get('/health', (c) => c.json({ status: 'ok' }));

export { app };
