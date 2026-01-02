// apps/api/src/server.ts
import 'dotenv/config';
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { serve } from '@hono/node-server';
import { generateCharacter } from './handlers/generateCharacter.js';
import { nextQuestion } from './handlers/nextQuestion.js';
import { shopSourceRows } from './handlers/shopSourceRows.js';

const app = new Hono();

app.use('*', cors({ origin: 'http://localhost:3000' }));

app.post('/generate-character', async (c) => {
  const result = await generateCharacter(c);
  return c.json(result);
});
app.post('/survey/next', nextQuestion);
app.post('/shop/sourceRows', shopSourceRows);

const port = Number(process.env.PORT || 4000);
serve({ fetch: app.fetch, port }, () => {
  console.log(`[api] listening on http://localhost:${port}`);
});
