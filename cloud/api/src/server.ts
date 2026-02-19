import 'dotenv/config';
import { serve } from '@hono/node-server';
import { app } from './app.js';
import { db } from '@wcc/core';

const port = Number(process.env.PORT || 4100);
const server = serve({ fetch: app.fetch, port }, () => {
  console.log(`[cloud-api] listening on http://localhost:${port}`);
});

function timeout(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

let shuttingDown = false;
async function shutdown(signal: string): Promise<void> {
  if (shuttingDown) return;
  shuttingDown = true;
  console.log(`[cloud-api] shutting down (${signal})...`);

  try {
    if (typeof (server as any).closeAllConnections === 'function') (server as any).closeAllConnections();
    if (typeof (server as any).closeIdleConnections === 'function') (server as any).closeIdleConnections();
  } catch { /* ignore */ }

  await Promise.race([
    new Promise<void>((resolve) => server.close(() => resolve())),
    timeout(1500),
  ]);

  await Promise.race([db.close().catch(() => undefined), timeout(1500)]);

  process.exit(0);
}

process.on('SIGINT', () => void shutdown('SIGINT'));
process.on('SIGTERM', () => void shutdown('SIGTERM'));
