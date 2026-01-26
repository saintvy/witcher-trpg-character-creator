import type { Context } from 'hono';
import { db } from '../db/pool.js';

/**
 * Generates character from characterRaw:
 * - Removes logicFields
 * - Replaces i18n objects with strings from DB
 */
type I18nValue = { i18n_uuid: string };
type CharacterRaw = Record<string, unknown> & { logicFields?: Record<string, unknown> };
type Character = Record<string, unknown>;

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function isI18nValue(value: unknown): value is I18nValue {
  return (
    typeof value === 'object' &&
    value !== null &&
    !Array.isArray(value) &&
    'i18n_uuid' in value &&
    typeof (value as I18nValue).i18n_uuid === 'string'
  );
}

type I18nArrayValue = { i18n_uuid_array: string[] };

function isI18nArrayValue(value: unknown): value is I18nArrayValue {
  return (
    typeof value === 'object' &&
    value !== null &&
    !Array.isArray(value) &&
    'i18n_uuid_array' in value &&
    Array.isArray((value as I18nArrayValue).i18n_uuid_array) &&
    (value as I18nArrayValue).i18n_uuid_array.every((item) => typeof item === 'string')
  );
}

type I18nResolver = (uuid: string) => string;

/**
 * Prepares i18n resolver: one batch to DB, cache in memory
 */
async function buildI18nResolver(uuids: Set<string>, lang: string): Promise<I18nResolver> {
  if (uuids.size === 0) {
    return (uuid) => uuid;
  }

  const uuidArray = Array.from(uuids);
  const languages = Array.from(new Set([lang, 'en'])); // en for fallback without extra queries

  const { rows } = await db.query<{ id: string; lang: string; text: string }>(
    `
      SELECT id::text, lang, text
      FROM i18n_text
      WHERE id = ANY($1::uuid[]) AND lang = ANY($2::text[])
    `,
    [uuidArray, languages],
  );

  const cache = new Map<string, Record<string, string>>();
  for (const row of rows) {
    const byLang = cache.get(row.id) ?? {};
    byLang[row.lang] = row.text;
    cache.set(row.id, byLang);
  }

  return (uuid: string) => {
    const byLang = cache.get(uuid);
    if (byLang?.[lang]) return byLang[lang];
    if (lang !== 'en' && byLang?.['en']) return byLang['en'];
    return uuid;
  };
}

/**
 * Collects all UUIDs for batch resolution
 */
function collectI18nUuids(value: unknown, acc: Set<string>): void {
  if (typeof value === 'string') {
    if (UUID_PATTERN.test(value)) {
      acc.add(value);
    }
    return;
  }
  if (isI18nValue(value)) {
    if (UUID_PATTERN.test(value.i18n_uuid)) {
      acc.add(value.i18n_uuid);
    }
    return;
  }
  if (isI18nArrayValue(value)) {
    // [separator, ...uuids]
    value.i18n_uuid_array.slice(1).forEach((uuid) => {
      if (UUID_PATTERN.test(uuid)) {
        acc.add(uuid);
      }
    });
    return;
  }
  if (Array.isArray(value)) {
    value.forEach((item) => collectI18nUuids(item, acc));
    return;
  }
  if (typeof value === 'object' && value !== null) {
    for (const [key, val] of Object.entries(value)) {
      if (key === 'logicFields') continue;
      collectI18nUuids(val, acc);
    }
  }
}

/**
 * Recursively processes object: replaces i18n objects and UUID strings with strings
 */
async function resolveI18nRecursive(
  value: unknown,
  lang: string,
  resolveText: I18nResolver,
): Promise<unknown> {
  if (isI18nValue(value)) {
    return resolveText(value.i18n_uuid);
  }

  if (isI18nArrayValue(value)) {
    const [separator, ...uuids] = value.i18n_uuid_array;
    const texts = uuids.map((uuid) => resolveText(uuid));
    return texts.join(separator ?? '');
  }

  if (typeof value === 'string') {
    if (UUID_PATTERN.test(value)) {
      return resolveText(value);
    }
    return value;
  }

  if (typeof value === 'number' || typeof value === 'boolean' || value === null) {
    return value;
  }

  if (Array.isArray(value)) {
    return Promise.all(value.map((item) => resolveI18nRecursive(item, lang, resolveText)));
  }

  if (typeof value === 'object' && value !== null) {
    const result: Record<string, unknown> = {};
    for (const [key, val] of Object.entries(value)) {
      // Skip logicFields
      if (key === 'logicFields') {
        continue;
      }
      result[key] = await resolveI18nRecursive(val, lang, resolveText);
    }
    return result;
  }

  return value;
}

export async function generateCharacter(c: Context): Promise<Character> {
  // Accept either:
  // - raw character object (CharacterRaw)
  // - wrapper { characterRaw: CharacterRaw } (e.g. survey state)
  const body = (await c.req.json().catch(() => ({}))) as unknown;
  const characterRaw =
    body && typeof body === 'object' && !Array.isArray(body) && 'characterRaw' in (body as Record<string, unknown>)
      ? (((body as Record<string, unknown>).characterRaw ?? {}) as CharacterRaw)
      : (body as CharacterRaw);
  
  // Get language from query parameter or header, default 'en'
  const lang = c.req.query('lang') || c.req.header('Accept-Language')?.split(',')[0]?.split('-')[0] || 'en';

  // Collect all UUIDs for one query
  const uuids = new Set<string>();
  collectI18nUuids(characterRaw, uuids);
  const resolveText = await buildI18nResolver(uuids, lang);

  // Remove logicFields and resolve i18n objects
  const character = (await resolveI18nRecursive(characterRaw, lang, resolveText)) as Character;
  
  return character;
}
