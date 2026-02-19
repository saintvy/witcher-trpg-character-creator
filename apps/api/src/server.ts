// apps/api/src/server.ts
import 'dotenv/config';
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { serve } from '@hono/node-server';
import { generateCharacter } from './handlers/generateCharacter.js';
import { nextQuestion } from './handlers/nextQuestion.js';
import { getAllShopItemsHandler } from './handlers/getAllShopItems.js';
import { getSkillsCatalogHandler } from './handlers/getSkillsCatalog.js';
import { characterPdf } from './handlers/characterPdf.js';
import { db } from '@wcc/core';
import { CharacterPdfService } from './pdf/CharacterPdfService.js';

const app = new Hono();

app.use('*', cors({ origin: 'http://localhost:3000' }));

app.post('/generate-character', async (c) => {
  const result = await generateCharacter(c);
  return c.json(result);
});
app.post('/character/pdf', characterPdf);
app.post('/survey/next', nextQuestion);
app.post('/shop/allItems', getAllShopItemsHandler);
app.post('/skills/catalog', getSkillsCatalogHandler);

const port = Number(process.env.PORT || 4000);
const server = serve({ fetch: app.fetch, port }, () => {
  console.log(`[api] listening on http://localhost:${port}`);
});

function timeout(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

let shuttingDown = false;
async function shutdown(signal: string): Promise<void> {
  if (shuttingDown) return;
  shuttingDown = true;

  console.log(`[api] shutting down (${signal})...`);

  try {
    if (typeof (server as any).closeAllConnections === 'function') (server as any).closeAllConnections();
    if (typeof (server as any).closeIdleConnections === 'function') (server as any).closeIdleConnections();
  } catch {
    // ignore
  }

  await Promise.race([
    new Promise<void>((resolve) => server.close(() => resolve())),
    timeout(1500),
  ]);

  await Promise.race([
    db.close().catch(() => undefined),
    timeout(1500),
  ]);

  await Promise.race([
    CharacterPdfService.shutdown(),
    timeout(1500),
  ]);

  process.exit(0);
}

process.on('SIGINT', () => void shutdown('SIGINT'));
process.on('SIGTERM', () => void shutdown('SIGTERM'));
process.on('SIGBREAK', () => void shutdown('SIGBREAK'));
