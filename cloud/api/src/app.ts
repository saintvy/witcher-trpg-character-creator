import { Hono } from 'hono';
import { cors } from 'hono/cors';
import type { AuthUser } from './auth.js';
import { authMiddleware } from './auth.js';
import { getSurveyRandomToStable } from './survey-random.js';
import {
  generateCharacterFromBody,
  getNextQuestion,
  getAllShopItems,
  getSkillsCatalog,
  db,
} from '@wcc/core';

type AppEnv = {
  Variables: {
    authUser?: AuthUser;
  };
};

type SavedCharacterRow = {
  id: string;
  owner_email: string;
  name: string | null;
  race_code: string | null;
  profession_code: string | null;
  created_at: string;
  raw_character_json?: unknown;
  answers_export_json?: unknown;
};

type CountRow = {
  count: number;
};

function getUserEmail(user: AuthUser | undefined): string | null {
  if (!user) return null;
  const email = typeof user.email === 'string' ? user.email.trim().toLowerCase() : '';
  return email.length > 0 ? email : null;
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return value && typeof value === 'object' && !Array.isArray(value) ? (value as Record<string, unknown>) : null;
}

function readStringAt(obj: Record<string, unknown> | null, key: string): string | null {
  if (!obj) return null;
  const value = obj[key];
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function extractCharacterSummary(rawCharacter: unknown): {
  name: string | null;
  raceCode: string | null;
  professionCode: string | null;
} {
  const raw = asRecord(rawCharacter);
  const logicFields =
    asRecord(raw?.logicFields) ??
    asRecord(raw?.logic_fields) ??
    null;

  const name =
    readStringAt(raw, 'name') ??
    readStringAt(raw, 'characterName') ??
    readStringAt(raw, 'fullName') ??
    readStringAt(logicFields, 'name') ??
    readStringAt(logicFields, 'character_name') ??
    null;

  const raceCode =
    readStringAt(logicFields, 'race') ??
    readStringAt(logicFields, 'race_code') ??
    null;

  const professionCode =
    readStringAt(logicFields, 'profession') ??
    readStringAt(logicFields, 'profession_code') ??
    null;

  return { name, raceCode, professionCode };
}

function safeFileNameBase(value: string | null | undefined, fallback: string): string {
  const base = (value ?? '')
    .replace(/[<>:"/\\|?*\x00-\x1F]/g, '')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 80);
  return base.length > 0 ? base : fallback;
}

const app = new Hono<AppEnv>().basePath('/api');

const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',')
  : ['http://localhost:3100'];

app.use('*', cors({ origin: allowedOrigins }));
app.use('*', authMiddleware);

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

app.post('/survey/random-to-end', async (c) => {
  try {
    const payload = await c.req.json();
    const result = await getSurveyRandomToStable(payload);
    return c.json(result);
  } catch (error) {
    console.error('[survey] random-to-end error', error);
    return c.json({ error: 'Failed to randomise survey to stable state' }, 400);
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

app.post('/characters', async (c) => {
  const user = c.get('authUser');
  const ownerEmail = getUserEmail(user);
  if (!ownerEmail) {
    return c.json({ error: 'Authenticated user email is required' }, 401);
  }

  const body = (await c.req.json().catch(() => null)) as unknown;
  const bodyRec = asRecord(body);
  if (!bodyRec) {
    return c.json({ error: 'Invalid JSON body' }, 400);
  }

  const rawCharacter =
    bodyRec.rawCharacter ?? bodyRec.characterRaw ?? bodyRec.raw_character ?? null;
  const answersExport =
    bodyRec.answersExport ?? bodyRec.historyExport ?? bodyRec.answers_export ?? null;

  if (!asRecord(rawCharacter)) {
    return c.json({ error: 'rawCharacter object is required' }, 400);
  }
  if (!asRecord(answersExport)) {
    return c.json({ error: 'answersExport object is required' }, 400);
  }

  const summary = extractCharacterSummary(rawCharacter);

  try {
    const { rows } = await db.query<SavedCharacterRow>(
      `
        INSERT INTO wcc_user_characters (
          owner_email,
          owner_sub,
          owner_provider,
          name,
          race_code,
          profession_code,
          raw_character_json,
          answers_export_json
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb, $8::jsonb)
        RETURNING
          id::text AS id,
          owner_email,
          name,
          race_code,
          profession_code,
          created_at::text
      `,
      [
        ownerEmail,
        user?.sub ?? null,
        user?.provider ?? null,
        summary.name,
        summary.raceCode,
        summary.professionCode,
        JSON.stringify(rawCharacter),
        JSON.stringify(answersExport),
      ],
    );

    const row = rows[0];
    return c.json({
      id: row?.id,
      name: row?.name ?? summary.name,
      race: row?.race_code ?? summary.raceCode,
      profession: row?.profession_code ?? summary.professionCode,
      createdAt: row?.created_at ?? new Date().toISOString(),
    });
  } catch (error) {
    console.error('[characters] save error', error);
    return c.json({ error: 'Failed to save character' }, 500);
  }
});

app.get('/characters', async (c) => {
  const ownerEmail = getUserEmail(c.get('authUser'));
  if (!ownerEmail) {
    return c.json({ error: 'Authenticated user email is required' }, 401);
  }

  try {
    const { rows } = await db.query<SavedCharacterRow>(
      `
        SELECT
          id::text AS id,
          owner_email,
          name,
          race_code,
          profession_code,
          created_at::text
        FROM wcc_user_characters
        WHERE owner_email = $1
        ORDER BY created_at DESC, id DESC
      `,
      [ownerEmail],
    );

    return c.json({
      items: rows.map((row) => ({
        id: row.id,
        name: row.name,
        race: row.race_code,
        profession: row.profession_code,
        createdAt: row.created_at,
      })),
    });
  } catch (error) {
    console.error('[characters] list error', error);
    return c.json({ error: 'Failed to load characters' }, 500);
  }
});

app.get('/characters/count', async (c) => {
  const ownerEmail = getUserEmail(c.get('authUser'));
  if (!ownerEmail) {
    return c.json({ error: 'Authenticated user email is required' }, 401);
  }

  try {
    const { rows } = await db.query<CountRow>(
      `
        SELECT COUNT(*)::int AS count
        FROM wcc_user_characters
        WHERE owner_email = $1
      `,
      [ownerEmail],
    );
    const count = Number(rows[0]?.count ?? 0);
    return c.json({ count: Number.isFinite(count) ? count : 0 });
  } catch (error) {
    console.error('[characters] count error', error);
    return c.json({ error: 'Failed to load characters count' }, 500);
  }
});

app.get('/characters/:id/raw', async (c) => {
  const ownerEmail = getUserEmail(c.get('authUser'));
  if (!ownerEmail) {
    return c.json({ error: 'Authenticated user email is required' }, 401);
  }
  const id = c.req.param('id');

  try {
    const { rows } = await db.query<SavedCharacterRow>(
      `
        SELECT id::text AS id, name, raw_character_json
        FROM wcc_user_characters
        WHERE id = $1::uuid AND owner_email = $2
      `,
      [id, ownerEmail],
    );
    const row = rows[0];
    if (!row) return c.json({ error: 'Character not found' }, 404);

    const fileName = `${safeFileNameBase(row.name, 'character')}-raw.json`;
    return c.body(JSON.stringify(row.raw_character_json ?? {}, null, 2), 200, {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
      'Content-Disposition': `attachment; filename="${fileName}"`,
    });
  } catch (error) {
    console.error('[characters] raw download error', error);
    return c.json({ error: 'Failed to download raw JSON' }, 500);
  }
});

app.get('/characters/:id/history-export', async (c) => {
  const ownerEmail = getUserEmail(c.get('authUser'));
  if (!ownerEmail) {
    return c.json({ error: 'Authenticated user email is required' }, 401);
  }
  const id = c.req.param('id');

  try {
    const { rows } = await db.query<SavedCharacterRow>(
      `
        SELECT id::text AS id, name, answers_export_json
        FROM wcc_user_characters
        WHERE id = $1::uuid AND owner_email = $2
      `,
      [id, ownerEmail],
    );
    const row = rows[0];
    if (!row) return c.json({ error: 'Character not found' }, 404);

    const fileName = `${safeFileNameBase(row.name, 'character')}-history.json`;
    return c.body(JSON.stringify(row.answers_export_json ?? {}, null, 2), 200, {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
      'Content-Disposition': `attachment; filename="${fileName}"`,
    });
  } catch (error) {
    console.error('[characters] history download error', error);
    return c.json({ error: 'Failed to download history export' }, 500);
  }
});

app.get('/health', (c) => c.json({ status: 'ok' }));

export { app };
