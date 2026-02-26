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
  resolveCharacterRawI18n,
  db,
} from '@wcc/core';
import { generateCharacterPdfBuffer } from './pdf/characterPdf.js';

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

type WeaponPdfDetailsRow = {
  w_id: string;
  weapon_name: string | null;
  dmg: string | null;
  dmg_types: string | null;
  weight: string | null;
  price: number | string | null;
  hands: number | string | null;
  reliability: number | string | null;
  concealment: string | null;
  effect_names: string | null;
};

type ArmorPdfDetailsRow = {
  a_id: string;
  armor_name: string | null;
  stopping_power: number | string | null;
  encumbrance: number | string | null;
  enhancements: number | string | null;
  weight: string | null;
  price: number | string | null;
  effect_names: string | null;
};

type PotionPdfDetailsRow = {
  p_id: string;
  potion_name: string | null;
  toxicity: string | null;
  time_effect: string | null;
  effect: string | null;
  weight: string | null;
  price: number | string | null;
};

function getUserEmail(user: AuthUser | undefined): string | null {
  if (!user) return null;
  const email = typeof user.email === 'string' ? user.email.trim().toLowerCase() : '';
  return email.length > 0 ? email : null;
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return value && typeof value === 'object' && !Array.isArray(value) ? (value as Record<string, unknown>) : null;
}

function asArray(value: unknown): unknown[] {
  return Array.isArray(value) ? value : [];
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

function readIdListFromGear(rawCharacter: Record<string, unknown>, listKey: 'weapons' | 'armors' | 'potions', idKey: string): string[] {
  const gear = asRecord(rawCharacter.gear);
  const list = asArray(gear?.[listKey]);
  const out: string[] = [];
  for (const item of list) {
    const rec = asRecord(item);
    const id = typeof rec?.[idKey] === 'string' ? rec[idKey].trim() : '';
    if (id) out.push(id);
  }
  return Array.from(new Set(out));
}

function patchResolvedGearFromDbViews(params: {
  rawCharacter: Record<string, unknown>;
  resolvedCharacter: Record<string, unknown>;
  weaponsById: ReadonlyMap<string, WeaponPdfDetailsRow>;
  armorsById: ReadonlyMap<string, ArmorPdfDetailsRow>;
  potionsById: ReadonlyMap<string, PotionPdfDetailsRow>;
}) {
  const rawGear = asRecord(params.rawCharacter.gear) ?? {};
  const resolvedGear = asRecord(params.resolvedCharacter.gear) ?? {};

  const patchWeapons = asArray(rawGear.weapons).map((item) => {
    const rec = asRecord(item) ?? {};
    const id = typeof rec.w_id === 'string' ? rec.w_id : '';
    const d = id ? params.weaponsById.get(id) : undefined;
    return {
      ...rec,
      w_id: id || rec.w_id,
      weapon_name: d?.weapon_name ?? rec.weapon_name,
      name: d?.weapon_name ?? rec.name ?? rec.weapon_name,
      dmg: d?.dmg ?? rec.dmg,
      dmg_types: d?.dmg_types ?? rec.dmg_types ?? rec.type,
      type: d?.dmg_types ?? rec.type ?? rec.dmg_types,
      reliability: d?.reliability ?? rec.reliability,
      hands: d?.hands ?? rec.hands,
      concealment: d?.concealment ?? rec.concealment ?? rec.conceal,
      enhancements: rec.enhancements ?? rec.enhancement ?? rec.upgrades,
      weight: d?.weight ?? rec.weight,
      price: d?.price ?? rec.price,
      effect_names: d?.effect_names ?? rec.effect_names ?? rec.effect,
    };
  });

  const patchArmors = asArray(rawGear.armors).map((item) => {
    const rec = asRecord(item) ?? {};
    const id = typeof rec.a_id === 'string' ? rec.a_id : '';
    const d = id ? params.armorsById.get(id) : undefined;
    return {
      ...rec,
      a_id: id || rec.a_id,
      armor_name: d?.armor_name ?? rec.armor_name,
      name: d?.armor_name ?? rec.name ?? rec.armor_name,
      stopping_power: d?.stopping_power ?? rec.stopping_power ?? rec.sp,
      sp: d?.stopping_power ?? rec.sp ?? rec.stopping_power,
      encumbrance: d?.encumbrance ?? rec.encumbrance ?? rec.enc,
      enc: d?.encumbrance ?? rec.enc ?? rec.encumbrance,
      enhancements: rec.enhancements ?? rec.enhancement ?? rec.upgrades ?? d?.enhancements,
      weight: d?.weight ?? rec.weight,
      price: d?.price ?? rec.price,
      effect_names: d?.effect_names ?? rec.effect_names ?? rec.effect,
    };
  });

  const patchPotions = asArray(rawGear.potions).map((item) => {
    const rec = asRecord(item) ?? {};
    const id = typeof rec.p_id === 'string' ? rec.p_id : '';
    const d = id ? params.potionsById.get(id) : undefined;
    return {
      ...rec,
      p_id: id || rec.p_id,
      potion_name: d?.potion_name ?? rec.potion_name,
      name: d?.potion_name ?? rec.name ?? rec.potion_name,
      toxicity: d?.toxicity ?? rec.toxicity,
      time_effect: d?.time_effect ?? rec.time_effect ?? rec.duration,
      duration: d?.time_effect ?? rec.duration ?? rec.time_effect,
      effect: d?.effect ?? rec.effect,
      weight: d?.weight ?? rec.weight,
      price: d?.price ?? rec.price,
    };
  });

  params.resolvedCharacter.gear = {
    ...resolvedGear,
    weapons: patchWeapons,
    armors: patchArmors,
    potions: patchPotions,
  };
}

function safeFileNameBase(value: string | null | undefined, fallback: string): string {
  const base = (value ?? '')
    .replace(/[<>:"/\\|?*\x00-\x1F]/g, '')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 80);
  return base.length > 0 ? base : fallback;
}

function buildDownloadContentDisposition(fileName: string): string {
  const asciiFallback = fileName
    .normalize('NFKD')
    .replace(/[^\x20-\x7E]/g, '')
    .replace(/["\\]/g, '')
    .replace(/\s+/g, ' ')
    .trim() || 'download';
  const encoded = encodeURIComponent(fileName)
    .replace(/['()]/g, (m) => `%${m.charCodeAt(0).toString(16).toUpperCase()}`)
    .replace(/\*/g, '%2A');
  return `attachment; filename="${asciiFallback}"; filename*=UTF-8''${encoded}`;
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
      'Content-Disposition': buildDownloadContentDisposition(fileName),
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
      'Content-Disposition': buildDownloadContentDisposition(fileName),
    });
  } catch (error) {
    console.error('[characters] history download error', error);
    return c.json({ error: 'Failed to download history export' }, 500);
  }
});

app.get('/characters/:id/pdf', async (c) => {
  const ownerEmail = getUserEmail(c.get('authUser'));
  if (!ownerEmail) {
    return c.json({ error: 'Authenticated user email is required' }, 401);
  }
  const id = c.req.param('id');
  const requestedLang = (c.req.query('lang') || c.req.header('Accept-Language')?.split(',')[0]?.split('-')[0] || 'en')
    .trim()
    .toLowerCase();
  const lang = requestedLang === 'ru' ? 'ru' : 'en';

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

    const rawCharacter = asRecord(row.raw_character_json);
    if (!rawCharacter) {
      return c.json({ error: 'Saved raw character JSON is invalid' }, 500);
    }

    const resolvedCharacter = await resolveCharacterRawI18n(rawCharacter, lang);
    const weaponIds = readIdListFromGear(rawCharacter, 'weapons', 'w_id');
    const armorIds = readIdListFromGear(rawCharacter, 'armors', 'a_id');
    const potionIds = readIdListFromGear(rawCharacter, 'potions', 'p_id');

    const weaponsById = new Map<string, WeaponPdfDetailsRow>();
    const armorsById = new Map<string, ArmorPdfDetailsRow>();
    const potionsById = new Map<string, PotionPdfDetailsRow>();

    try {
      if (weaponIds.length > 0) {
        const { rows } = await db.query<WeaponPdfDetailsRow>(
          `
            SELECT w_id, weapon_name, dmg, dmg_types, weight, price, hands, reliability, concealment, effect_names
            FROM wcc_item_weapons_v
            WHERE lang = $1 AND w_id = ANY($2::text[])
          `,
          [lang, weaponIds],
        );
        rows.forEach((r) => weaponsById.set(r.w_id, r));
      }
    } catch (error) {
      console.error('[characters] pdf weapon lookup failed', error);
    }

    try {
      if (armorIds.length > 0) {
        const { rows } = await db.query<ArmorPdfDetailsRow>(
          `
            SELECT a_id, armor_name, stopping_power, encumbrance, enhancements, weight, price, effect_names
            FROM wcc_item_armors_v
            WHERE lang = $1 AND a_id = ANY($2::text[])
          `,
          [lang, armorIds],
        );
        rows.forEach((r) => armorsById.set(r.a_id, r));
      }
    } catch (error) {
      console.error('[characters] pdf armor lookup failed', error);
    }

    try {
      if (potionIds.length > 0) {
        const { rows } = await db.query<PotionPdfDetailsRow>(
          `
            SELECT p_id, potion_name, toxicity, time_effect, effect, weight, price
            FROM wcc_item_potions_v
            WHERE lang = $1 AND p_id = ANY($2::text[])
          `,
          [lang, potionIds],
        );
        rows.forEach((r) => potionsById.set(r.p_id, r));
      }
    } catch (error) {
      console.error('[characters] pdf potion lookup failed', error);
    }

    patchResolvedGearFromDbViews({
      rawCharacter,
      resolvedCharacter,
      weaponsById,
      armorsById,
      potionsById,
    });

    const skillsCatalog = await getSkillsCatalog({ lang }).catch(() => ({ skills: [] as Array<{ id: string; param: string | null; name: string }> }));
    const skillsCatalogById = new Map(
      (Array.isArray(skillsCatalog.skills) ? skillsCatalog.skills : []).map((s) => [s.id, { param: s.param, name: s.name }] as const),
    );
    const pdfBuffer = await generateCharacterPdfBuffer({
      rawCharacter,
      resolvedCharacter,
      lang,
      skillsCatalogById,
    });

    const fileName = `${safeFileNameBase(row.name, 'character')}-sheet.pdf`;
    return c.body(new Uint8Array(pdfBuffer), 200, {
      'Content-Type': 'application/pdf',
      'Cache-Control': 'no-store',
      'Content-Disposition': buildDownloadContentDisposition(fileName),
    });
  } catch (error) {
    console.error('[characters] pdf generation error', error);
    return c.json({ error: 'Failed to generate PDF' }, 500);
  }
});

app.delete('/characters/:id', async (c) => {
  const ownerEmail = getUserEmail(c.get('authUser'));
  if (!ownerEmail) {
    return c.json({ error: 'Authenticated user email is required' }, 401);
  }
  const id = c.req.param('id');

  try {
    const { rows } = await db.query<{ id: string }>(
      `
        DELETE FROM wcc_user_characters
        WHERE id = $1::uuid AND owner_email = $2
        RETURNING id::text AS id
      `,
      [id, ownerEmail],
    );
    if (!rows[0]) {
      return c.json({ error: 'Character not found' }, 404);
    }
    return c.json({ ok: true, id: rows[0].id });
  } catch (error) {
    console.error('[characters] delete error', error);
    return c.json({ error: 'Failed to delete character' }, 500);
  }
});

app.get('/health', (c) => c.json({ status: 'ok' }));

export { app };
