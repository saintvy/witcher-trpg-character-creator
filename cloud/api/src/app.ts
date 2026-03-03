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

type UserSettingsRow = {
  owner_email: string;
  settings_json: unknown | null;
};

type UserSettingsDto = {
  useW1AlchemyIcons: boolean;
  pdfTables: PdfTablesSettingsDto;
};

type PdfTableSettingsDto = {
  showIfEmpty: boolean;
  emptyRows: number;
};

type PdfTablesSettingsDto = {
  allies: PdfTableSettingsDto;
  enemies: PdfTableSettingsDto;
  alchemyRecipes: PdfTableSettingsDto;
  blueprints: PdfTableSettingsDto;
  components: PdfTableSettingsDto;
  spellsSigns: PdfTableSettingsDto;
  invocations: PdfTableSettingsDto;
  rituals: PdfTableSettingsDto;
  hexes: PdfTableSettingsDto;
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

type RecipePdfDetailsRow = {
  r_id: string;
  recipe_name: string | null;
  recipe_group: string | null;
  craft_level: string | null;
  complexity: number | string | null;
  time_craft: string | null;
  formula_en: string | null;
  price_formula: number | string | null;
  minimal_ingredients_cost: number | string | null;
  time_effect: string | null;
  toxicity: string | null;
  recipe_description: string | null;
  weight_potion: string | null;
  price_potion: number | string | null;
};

type BlueprintPdfDetailsRow = {
  b_id: string;
  blueprint_name: string | null;
  blueprint_group: string | null;
  craft_level: string | null;
  difficulty_check: number | string | null;
  time_craft: string | null;
  item_id: string | null;
  components: string | null;
  item_desc: string | null;
  price_components: number | string | null;
  price: number | string | null;
  price_item: number | string | null;
};

type IngredientPdfDetailsRow = {
  i_id: string;
  ingredient_name: string | null;
  alchemy_substance: string | null;
  alchemy_substance_en: string | null;
  harvesting_complexity: number | string | null;
  weight: string | null;
  price: number | string | null;
};

type GeneralGearPdfDetailsRow = {
  t_id: string;
  gear_name: string | null;
  group_name: string | null;
  subgroup_name: string | null;
  gear_description: string | null;
  concealment: string | null;
  weight: string | null;
  price: number | string | null;
};

type VehiclePdfDetailsRow = {
  wt_id: string;
  vehicle_name: string | null;
  subgroup_name: string | null;
  base: number | string | null;
  control_modifier: number | string | null;
  speed: string | null;
  occupancy: string | null;
  hp: number | string | null;
  weight: string | null;
  price: number | string | null;
};

type MagicSpellPdfDetailsRow = {
  ms_id: string;
  spell_name: string | null;
  level: string | null;
  element: string | null;
  stamina_cast: number | string | null;
  stamina_keeping: number | string | null;
  damage: string | null;
  distance: number | string | null;
  zone_size: string | null;
  form: string | null;
  effect_time: string | null;
  effect: string | null;
  sort_key: string | null;
  type: string | null;
};

type MagicInvocationPdfDetailsRow = {
  ms_id: string;
  invocation_name: string | null;
  level: string | null;
  cult_or_circle: string | null;
  stamina_cast: number | string | null;
  stamina_keeping: number | string | null;
  damage: string | null;
  distance: number | string | null;
  zone_size: string | null;
  form: string | null;
  effect_time: string | null;
  effect: string | null;
  type: string | null;
};

type MagicRitualPdfDetailsRow = {
  ms_id: string;
  ritual_name: string | null;
  level: string | null;
  dc: number | string | null;
  preparing_time: string | null;
  ingredients: string | null;
  zone_size: string | null;
  stamina_cast: number | string | null;
  stamina_keeping: number | string | null;
  effect_time: string | null;
  form: string | null;
  effect: string | null;
  effect_tpl: string | null;
  how_to_remove: string | null;
  sort_key: string | null;
};

type MagicHexPdfDetailsRow = {
  ms_id: string;
  hex_name: string | null;
  level: string | null;
  stamina_cast: number | string | null;
  effect: string | null;
  remove_instructions: string | null;
  remove_components: string | null;
  tooltip: string | null;
  sort_key: string | null;
};

type MagicGiftPdfDetailsRow = {
  mg_id: string;
  group_name: string | null;
  gift_name: string | null;
  dc: number | string | null;
  vigor_cost: number | string | null;
  action_cost: string | null;
  description: string | null;
  sort_key: string | null;
  is_major: boolean | null;
};

type I18nResolveRow = {
  id: string;
  lang: string;
  text: string;
};

type ItemEffectLookupRow = {
  item_id: string;
  effect_id: string;
  modifier: number | null;
  name_tpl: string | null;
  desc_tpl: string | null;
  cond_tpl: string | null;
};

type ItemEffectGlossaryRow = {
  name: string;
  value: string;
};

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const ITEM_ID_RE = {
  weapon: /^W\d+$/i,
  armor: /^A\d+$/i,
  potion: /^P\d+$/i,
  recipe: /^R\d+$/i,
  blueprint: /^B\d+$/i,
  ingredient: /^I\d+$/i,
  generalGear: /^T\d+$/i,
  vehicle: /^WT\d+$/i,
  magicSpell: /^MS\d+$/i,
  magicGift: /^MG\d+$/i,
  upgrade: /^U\d+$/i,
} as const;
const PDF_TABLE_KEYS = [
  'allies',
  'enemies',
  'alchemyRecipes',
  'blueprints',
  'components',
  'spellsSigns',
  'invocations',
  'rituals',
  'hexes',
] as const;
type PdfTableKey = (typeof PDF_TABLE_KEYS)[number];
const DEFAULT_PDF_TABLE_SETTINGS: PdfTablesSettingsDto = {
  allies: { showIfEmpty: false, emptyRows: 0 },
  enemies: { showIfEmpty: false, emptyRows: 0 },
  alchemyRecipes: { showIfEmpty: true, emptyRows: 3 },
  blueprints: { showIfEmpty: true, emptyRows: 2 },
  components: { showIfEmpty: true, emptyRows: 3 },
  spellsSigns: { showIfEmpty: false, emptyRows: 0 },
  invocations: { showIfEmpty: false, emptyRows: 0 },
  rituals: { showIfEmpty: false, emptyRows: 0 },
  hexes: { showIfEmpty: false, emptyRows: 0 },
};
const DEFAULT_USER_SETTINGS: UserSettingsDto = {
  useW1AlchemyIcons: false,
  pdfTables: DEFAULT_PDF_TABLE_SETTINGS,
};
const SHOP_BUNDLE_I18N_PREFIX = 'witcher_cc.wcc_profession_shop.bundle.';

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

function looksLikeI18nKey(value: string): boolean {
  return /^[a-z0-9_.-]+$/i.test(value) && value.length > 0;
}

function normalizeBundleI18nKey(value: string): string {
  const trimmed = value.trim();
  if (!trimmed) return '';
  if (trimmed.includes('.')) return trimmed;
  return `${SHOP_BUNDLE_I18N_PREFIX}${trimmed}`;
}

function canonicalId(value: unknown, pattern: RegExp): string {
  if (typeof value !== 'string') return '';
  const trimmed = value.trim();
  return pattern.test(trimmed) ? trimmed : '';
}

function humanizeBundleLabel(value: string): string {
  const trimmed = value.trim();
  if (!trimmed) return '';
  const noPrefix = trimmed.replace(/^witcher_cc\.wcc_profession_shop\.bundle\./i, '');
  return noPrefix.replace(/[_-]+/g, ' ').trim();
}

async function enrichProfessionalBundleLabelsInState(state: Record<string, unknown>, lang: string): Promise<void> {
  const characterRaw = asRecord(state.characterRaw);
  const profOptions = asRecord(characterRaw?.professional_gear_options);
  const bundles = asArray(profOptions?.bundles);
  if (bundles.length === 0) return;

  const bundleRows: Array<{ bundleId: string; ids: string[]; keys: string[]; fallback: string }> = [];
  const idsSet = new Set<string>();
  const keysSet = new Set<string>();

  for (const bundle of bundles) {
    const rec = asRecord(bundle);
    if (!rec) continue;
    const bundleId = typeof rec.bundleId === 'string' ? rec.bundleId.trim() : '';
    if (!bundleId) continue;

    const ids = new Set<string>();
    const keys = new Set<string>();
    let fallback = humanizeBundleLabel(bundleId) || bundleId;

    const displayName = rec.displayName;
    if (typeof displayName === 'string') {
      const raw = displayName.trim();
      if (raw) {
        if (UUID_RE.test(raw)) {
          ids.add(raw);
        } else {
          fallback = raw;
          if (looksLikeI18nKey(raw)) {
            keys.add(normalizeBundleI18nKey(raw));
          }
        }
      }
    } else {
      const obj = asRecord(displayName);
      const i18nUuid = typeof obj?.i18n_uuid === 'string' ? obj.i18n_uuid.trim() : '';
      if (i18nUuid && UUID_RE.test(i18nUuid)) {
        ids.add(i18nUuid);
      }
    }

    for (const id of ids) idsSet.add(id);
    for (const key of keys) keysSet.add(key);

    bundleRows.push({
      bundleId,
      ids: Array.from(ids),
      keys: Array.from(keys),
      fallback,
    });
  }

  if (bundleRows.length === 0) return;

  const keyToId = new Map<string, string>();
  const keyList = Array.from(keysSet);
  if (keyList.length > 0) {
    const { rows: keyRows } = await db.query<{ key: string; id: string }>(
      `
        SELECT src.key::text AS key, ck_id(src.key)::text AS id
        FROM unnest($1::text[]) AS src(key)
      `,
      [keyList],
    );
    for (const row of keyRows) {
      keyToId.set(row.key, row.id);
      idsSet.add(row.id);
    }
  }

  const textById = new Map<string, string>();
  const allIds = Array.from(idsSet).filter((v) => UUID_RE.test(v));
  if (allIds.length > 0) {
    const { rows } = await db.query<I18nResolveRow>(
      `
        SELECT id::text AS id, lang, text
        FROM i18n_text
        WHERE id = ANY($1::uuid[])
          AND lang = ANY($2::text[])
      `,
      [allIds, [lang, 'en']],
    );
    const byId = new Map<string, Map<string, string>>();
    for (const row of rows) {
      const m = byId.get(row.id) ?? new Map<string, string>();
      m.set(row.lang, row.text);
      byId.set(row.id, m);
    }
    for (const id of allIds) {
      const m = byId.get(id);
      const resolved = m?.get(lang) ?? m?.get('en');
      if (resolved) textById.set(id, resolved);
    }
  }

  const resolvedBundleNames: Record<string, string> = {};
  for (const row of bundleRows) {
    let resolved = '';
    for (const id of row.ids) {
      const text = textById.get(id);
      if (text) {
        resolved = text;
        break;
      }
    }
    if (!resolved) {
      for (const key of row.keys) {
        const id = keyToId.get(key);
        if (!id) continue;
        const text = textById.get(id);
        if (text) {
          resolved = text;
          break;
        }
      }
    }
    resolvedBundleNames[row.bundleId] = resolved || row.fallback;
  }

  const uiState = asRecord(state.ui) ?? {};
  const existingBundleNames = asRecord(uiState.professionalBundleNames) ?? {};
  state.ui = {
    ...uiState,
    professionalBundleNames: {
      ...existingBundleNames,
      ...resolvedBundleNames,
    },
  };
}

function readBooleanAt(obj: Record<string, unknown> | null, key: string): boolean | null {
  if (!obj) return null;
  const value = obj[key];
  return typeof value === 'boolean' ? value : null;
}

function readNumberAt(obj: Record<string, unknown> | null, key: string): number | null {
  if (!obj) return null;
  const value = obj[key];
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string' && value.trim()) {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return null;
}

function normalizeEmptyRows(value: number): number {
  const n = Math.trunc(value);
  if (!Number.isFinite(n)) return 0;
  return Math.min(50, Math.max(0, n));
}

function normalizePdfTableEntry(
  base: PdfTableSettingsDto,
  source: Record<string, unknown> | null,
): PdfTableSettingsDto {
  const showIfEmpty =
    readBooleanAt(source, 'showIfEmpty') ??
    readBooleanAt(source, 'show_if_empty') ??
    base.showIfEmpty;
  const emptyRowsRaw =
    readNumberAt(source, 'emptyRows') ??
    readNumberAt(source, 'empty_rows');
  const emptyRows = emptyRowsRaw == null ? base.emptyRows : normalizeEmptyRows(emptyRowsRaw);
  return { showIfEmpty, emptyRows };
}

function normalizePdfTablesSettingsFromUnknown(source: unknown): PdfTablesSettingsDto {
  const root = asRecord(source);
  const out: Partial<PdfTablesSettingsDto> = {};
  for (const key of PDF_TABLE_KEYS) {
    const base = DEFAULT_PDF_TABLE_SETTINGS[key];
    const entry = asRecord(root?.[key]);
    out[key] = normalizePdfTableEntry(base, entry);
  }
  return out as PdfTablesSettingsDto;
}

function normalizeUserSettingsRow(row: UserSettingsRow | undefined): UserSettingsDto {
  const settingsJson = asRecord(row?.settings_json);
  const fromCamel = readBooleanAt(settingsJson, 'useW1AlchemyIcons');
  const fromSnake = readBooleanAt(settingsJson, 'use_w1_alchemy_icons');
  const pdfTablesSource =
    settingsJson?.pdfTables ??
    settingsJson?.pdf_tables ??
    null;
  return {
    useW1AlchemyIcons: fromCamel ?? fromSnake ?? DEFAULT_USER_SETTINGS.useW1AlchemyIcons,
    pdfTables: normalizePdfTablesSettingsFromUnknown(pdfTablesSource),
  };
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

function readIdListFromGear(
  rawCharacter: Record<string, unknown>,
  listKey: 'weapons' | 'armors' | 'potions',
  idKey: string,
  idPattern: RegExp,
): string[] {
  const gear = asRecord(rawCharacter.gear);
  const list = asArray(gear?.[listKey]);
  const out: string[] = [];
  for (const item of list) {
    const rec = asRecord(item);
    const id = canonicalId(rec?.[idKey], idPattern);
    if (id) out.push(id);
  }
  return Array.from(new Set(out));
}

function readIdListFromGearAny(rawCharacter: Record<string, unknown>, listKey: string, idKeys: string[], idPattern: RegExp): string[] {
  const gear = asRecord(rawCharacter.gear);
  const list = asArray(gear?.[listKey]);
  const out: string[] = [];
  for (const item of list) {
    const rec = asRecord(item);
    if (!rec) continue;
    let id = '';
    for (const key of idKeys) {
      const value = canonicalId(rec[key], idPattern);
      if (value) {
        id = value;
        break;
      }
    }
    if (id) out.push(id);
  }
  return Array.from(new Set(out));
}

function readIdListFromIngredients(rawCharacter: Record<string, unknown>, listKey: 'alchemy' | 'craft', idKey: string): string[] {
  const gear = asRecord(rawCharacter.gear);
  const ingredients = asRecord(gear?.ingredients);
  const list = asArray(ingredients?.[listKey]);
  const out: string[] = [];
  for (const item of list) {
    const rec = asRecord(item);
    const id = canonicalId(rec?.[idKey], ITEM_ID_RE.ingredient);
    if (id) out.push(id);
  }
  return Array.from(new Set(out));
}

function readIdListFromMagicGifts(rawCharacter: Record<string, unknown>): string[] {
  const gear = asRecord(rawCharacter.gear);
  const magic = asRecord(gear?.magic);
  const gifts = asArray(magic?.gifts);
  const out: string[] = [];
  for (const item of gifts) {
    const rec = asRecord(item);
    const id =
      canonicalId(rec?.mg_id, ITEM_ID_RE.magicGift) ||
      canonicalId(rec?.id, ITEM_ID_RE.magicGift);
    if (id) out.push(id);
  }
  return Array.from(new Set(out));
}

function readIdListFromMagicList(rawCharacter: Record<string, unknown>, listKey: 'spells' | 'signs' | 'rituals' | 'hexes'): string[] {
  const gear = asRecord(rawCharacter.gear);
  const magic = asRecord(gear?.magic);
  const list = asArray(magic?.[listKey]);
  const out: string[] = [];
  for (const item of list) {
    const rec = asRecord(item);
    const id =
      canonicalId(rec?.ms_id, ITEM_ID_RE.magicSpell) ||
      canonicalId(rec?.id, ITEM_ID_RE.magicSpell);
    if (id) out.push(id);
  }
  return Array.from(new Set(out));
}

function readIdListFromMagicInvocations(rawCharacter: Record<string, unknown>, invType: 'druid' | 'priest'): string[] {
  const gear = asRecord(rawCharacter.gear);
  const magic = asRecord(gear?.magic);
  const invocations = asRecord(magic?.invocations);
  const list = asArray(invocations?.[invType]);
  const out: string[] = [];
  for (const item of list) {
    const rec = asRecord(item);
    const id =
      canonicalId(rec?.ms_id, ITEM_ID_RE.magicSpell) ||
      canonicalId(rec?.id, ITEM_ID_RE.magicSpell);
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
  recipesById: ReadonlyMap<string, RecipePdfDetailsRow>;
  blueprintsById: ReadonlyMap<string, BlueprintPdfDetailsRow>;
  ingredientsById: ReadonlyMap<string, IngredientPdfDetailsRow>;
  generalGearById: ReadonlyMap<string, GeneralGearPdfDetailsRow>;
  vehiclesById: ReadonlyMap<string, VehiclePdfDetailsRow>;
  magicSpellsById: ReadonlyMap<string, MagicSpellPdfDetailsRow>;
  magicInvocationsById: ReadonlyMap<string, MagicInvocationPdfDetailsRow>;
  magicRitualsById: ReadonlyMap<string, MagicRitualPdfDetailsRow>;
  magicHexesById: ReadonlyMap<string, MagicHexPdfDetailsRow>;
  giftsById: ReadonlyMap<string, MagicGiftPdfDetailsRow>;
}) {
  const rawGear = asRecord(params.rawCharacter.gear) ?? {};
  const resolvedGear = asRecord(params.resolvedCharacter.gear) ?? {};
  const getId = (rec: Record<string, unknown>, keys: string[], pattern: RegExp): string => {
    for (const key of keys) {
      const value = canonicalId(rec[key], pattern);
      if (value) return value;
    }
    return '';
  };
  const sourceList = (rawList: unknown, resolvedList: unknown): unknown[] => {
    const r = asArray(rawList);
    if (r.length > 0) return r;
    return asArray(resolvedList);
  };

  const patchWeapons = asArray(rawGear.weapons).map((item) => {
    const rec = asRecord(item) ?? {};
    const id = canonicalId(rec.w_id, ITEM_ID_RE.weapon);
    const hasId = id.length > 0;
    const d = id ? params.weaponsById.get(id) : undefined;
    return {
      ...rec,
      w_id: hasId ? id : rec.w_id,
      weapon_name: hasId ? (d?.weapon_name ?? id) : (rec.weapon_name ?? rec.name),
      name: hasId ? (d?.weapon_name ?? id) : (rec.name ?? rec.weapon_name),
      dmg: hasId ? d?.dmg : rec.dmg,
      dmg_types: hasId ? d?.dmg_types : (rec.dmg_types ?? rec.type),
      type: hasId ? d?.dmg_types : (rec.type ?? rec.dmg_types),
      reliability: hasId ? d?.reliability : rec.reliability,
      hands: hasId ? d?.hands : rec.hands,
      concealment: hasId ? d?.concealment : (rec.concealment ?? rec.conceal),
      enhancements: rec.enhancements ?? rec.enhancement ?? rec.upgrades,
      weight: hasId ? d?.weight : rec.weight,
      price: hasId ? d?.price : rec.price,
      effect_names: hasId ? d?.effect_names : (rec.effect_names ?? rec.effect),
    };
  });

  const patchArmors = asArray(rawGear.armors).map((item) => {
    const rec = asRecord(item) ?? {};
    const id = canonicalId(rec.a_id, ITEM_ID_RE.armor);
    const hasId = id.length > 0;
    const d = id ? params.armorsById.get(id) : undefined;
    return {
      ...rec,
      a_id: hasId ? id : rec.a_id,
      armor_name: hasId ? (d?.armor_name ?? id) : (rec.armor_name ?? rec.name),
      name: hasId ? (d?.armor_name ?? id) : (rec.name ?? rec.armor_name),
      stopping_power: hasId ? d?.stopping_power : (rec.stopping_power ?? rec.sp),
      sp: hasId ? d?.stopping_power : (rec.sp ?? rec.stopping_power),
      encumbrance: hasId ? d?.encumbrance : (rec.encumbrance ?? rec.enc),
      enc: hasId ? d?.encumbrance : (rec.enc ?? rec.encumbrance),
      enhancements: hasId ? d?.enhancements : (rec.enhancements ?? rec.enhancement ?? rec.upgrades),
      weight: hasId ? d?.weight : rec.weight,
      price: hasId ? d?.price : rec.price,
      effect_names: hasId ? d?.effect_names : (rec.effect_names ?? rec.effect),
    };
  });

  const patchPotions = asArray(rawGear.potions).map((item) => {
    const rec = asRecord(item) ?? {};
    const id = canonicalId(rec.p_id, ITEM_ID_RE.potion);
    const hasId = id.length > 0;
    const d = id ? params.potionsById.get(id) : undefined;
    return {
      ...rec,
      p_id: hasId ? id : rec.p_id,
      potion_name: hasId ? (d?.potion_name ?? id) : (rec.potion_name ?? rec.name),
      name: hasId ? (d?.potion_name ?? id) : (rec.name ?? rec.potion_name),
      toxicity: hasId ? d?.toxicity : rec.toxicity,
      time_effect: hasId ? d?.time_effect : (rec.time_effect ?? rec.duration),
      duration: hasId ? d?.time_effect : (rec.duration ?? rec.time_effect),
      effect: hasId ? d?.effect : rec.effect,
      weight: hasId ? d?.weight : rec.weight,
      price: hasId ? d?.price : rec.price,
    };
  });

  const patchRecipes = asArray(rawGear.recipes).map((item) => {
    const rec = asRecord(item) ?? {};
    const id = getId(rec, ['r_id', 'id'], ITEM_ID_RE.recipe);
    const hasId = id.length > 0;
    const d = id ? params.recipesById.get(id) : undefined;
    return {
      ...rec,
      r_id: hasId ? id : rec.r_id,
      recipe_name: hasId ? (d?.recipe_name ?? id) : (rec.recipe_name ?? rec.name),
      name: hasId ? (d?.recipe_name ?? id) : (rec.name ?? rec.recipe_name),
      recipe_group: hasId ? d?.recipe_group : (rec.recipe_group ?? rec.group),
      craft_level: hasId ? d?.craft_level : rec.craft_level,
      complexity: hasId ? d?.complexity : rec.complexity,
      time_craft: hasId ? d?.time_craft : rec.time_craft,
      formula_en: hasId ? d?.formula_en : rec.formula_en,
      price_formula: hasId ? d?.price_formula : rec.price_formula,
      minimal_ingredients_cost: hasId ? d?.minimal_ingredients_cost : rec.minimal_ingredients_cost,
      time_effect: hasId ? d?.time_effect : rec.time_effect,
      toxicity: hasId ? d?.toxicity : rec.toxicity,
      recipe_description: hasId ? d?.recipe_description : (rec.recipe_description ?? rec.effect),
      weight_potion: hasId ? d?.weight_potion : (rec.weight_potion ?? rec.weight),
      price_potion: hasId ? d?.price_potion : (rec.price_potion ?? rec.price),
    };
  });

  const patchBlueprints = asArray(rawGear.blueprints).map((item) => {
    const rec = asRecord(item) ?? {};
    const id = getId(rec, ['b_id', 'bp_id', 'id'], ITEM_ID_RE.blueprint);
    const hasId = id.length > 0;
    const d = id ? params.blueprintsById.get(id) : undefined;
    return {
      ...rec,
      b_id: hasId ? id : rec.b_id,
      blueprint_name: hasId ? (d?.blueprint_name ?? id) : (rec.blueprint_name ?? rec.name),
      name: hasId ? (d?.blueprint_name ?? id) : (rec.name ?? rec.blueprint_name),
      blueprint_group: hasId ? d?.blueprint_group : (rec.blueprint_group ?? rec.group),
      group: hasId ? d?.blueprint_group : (rec.group ?? rec.blueprint_group),
      craft_level: hasId ? d?.craft_level : rec.craft_level,
      difficulty_check: hasId ? d?.difficulty_check : (rec.difficulty_check ?? rec.complexity),
      time_craft: hasId ? d?.time_craft : rec.time_craft,
      item_id: hasId ? d?.item_id : rec.item_id,
      components: hasId ? d?.components : rec.components,
      item_desc: hasId ? d?.item_desc : (rec.item_desc ?? rec.description),
      price_components: hasId ? d?.price_components : rec.price_components,
      price: hasId ? d?.price : rec.price,
      price_item: hasId ? d?.price_item : rec.price_item,
    };
  });

  const rawIngredients = asRecord(rawGear.ingredients) ?? {};
  const resolvedIngredients = asRecord(resolvedGear.ingredients) ?? {};
  const patchIngredients = (list: unknown[]) =>
    asArray(list).map((item) => {
      const rec = asRecord(item) ?? {};
      const id = canonicalId(rec.i_id, ITEM_ID_RE.ingredient);
      const hasId = id.length > 0;
      const d = id ? params.ingredientsById.get(id) : undefined;
      return {
        ...rec,
        i_id: hasId ? id : rec.i_id,
        ingredient_name: hasId ? (d?.ingredient_name ?? id) : (rec.ingredient_name ?? rec.name),
        name: hasId ? (d?.ingredient_name ?? id) : (rec.name ?? rec.ingredient_name),
        alchemy_substance: hasId ? d?.alchemy_substance : rec.alchemy_substance,
        alchemy_substance_en: hasId ? d?.alchemy_substance_en : rec.alchemy_substance_en,
        harvesting_complexity: hasId ? d?.harvesting_complexity : rec.harvesting_complexity,
        weight: hasId ? d?.weight : rec.weight,
        price: hasId ? d?.price : rec.price,
      };
    });
  const patchAlchemyIngredients = patchIngredients(asArray(rawIngredients.alchemy));
  const patchCraftIngredients = patchIngredients(asArray(rawIngredients.craft));
  const rawGeneralGear = asArray(rawGear.general_gear);
  const resolvedGeneralGear = asArray(resolvedGear.general_gear);
  const sourceGeneralGear = rawGeneralGear.length > 0 ? rawGeneralGear : resolvedGeneralGear;
  const patchGeneralGear = sourceGeneralGear.map((item, idx) => {
    const rec = asRecord(item) ?? {};
    const recResolved = asRecord(resolvedGeneralGear[idx]) ?? {};
    const id =
      getId(rec, ['t_id', 'id'], ITEM_ID_RE.generalGear) ||
      getId(recResolved, ['t_id', 'id'], ITEM_ID_RE.generalGear);
    const hasId = id.length > 0;
    const d = id ? params.generalGearById.get(id) : undefined;
    return {
      ...recResolved,
      ...rec,
      t_id: hasId ? id : (rec.t_id ?? recResolved.t_id),
      gear_name: hasId ? (d?.gear_name ?? id) : (recResolved.gear_name ?? recResolved.name ?? rec.gear_name ?? rec.name),
      name: hasId ? (d?.gear_name ?? id) : (recResolved.name ?? recResolved.gear_name ?? rec.name ?? rec.gear_name),
      group_name: hasId ? d?.group_name : (recResolved.group_name ?? rec.group_name),
      subgroup_name: hasId ? d?.subgroup_name : (recResolved.subgroup_name ?? rec.subgroup_name),
      gear_description: hasId ? d?.gear_description : (recResolved.gear_description ?? recResolved.description ?? rec.gear_description ?? rec.description),
      description: hasId ? d?.gear_description : (recResolved.description ?? recResolved.gear_description ?? rec.description ?? rec.gear_description),
      concealment: hasId ? d?.concealment : (recResolved.concealment ?? rec.concealment),
      weight: hasId ? d?.weight : (recResolved.weight ?? rec.weight),
      price: hasId ? d?.price : (recResolved.price ?? rec.price),
    };
  });
  const patchVehicles = asArray(rawGear.vehicles).map((item) => {
    const rec = asRecord(item) ?? {};
    const id = getId(rec, ['wt_id', 'id'], ITEM_ID_RE.vehicle);
    const hasId = id.length > 0;
    const d = id ? params.vehiclesById.get(id) : undefined;
    return {
      ...rec,
      wt_id: hasId ? id : rec.wt_id,
      vehicle_name: hasId ? (d?.vehicle_name ?? id) : (rec.vehicle_name ?? rec.name),
      name: hasId ? (d?.vehicle_name ?? id) : (rec.name ?? rec.vehicle_name),
      subgroup_name: hasId ? d?.subgroup_name : rec.subgroup_name,
      base: hasId ? d?.base : rec.base,
      control_modifier: hasId ? d?.control_modifier : rec.control_modifier,
      speed: hasId ? d?.speed : rec.speed,
      occupancy: hasId ? d?.occupancy : rec.occupancy,
      hp: hasId ? d?.hp : rec.hp,
      weight: hasId ? d?.weight : rec.weight,
      price: hasId ? d?.price : rec.price,
    };
  });

  const rawMagic = asRecord(rawGear.magic) ?? {};
  const resolvedMagic = asRecord(resolvedGear.magic) ?? {};
  const patchSpells = sourceList(rawMagic.spells, resolvedMagic.spells).map((item) => {
    const rec = asRecord(item) ?? {};
    const id = getId(rec, ['ms_id', 'id'], ITEM_ID_RE.magicSpell);
    const hasId = id.length > 0;
    const d = id ? params.magicSpellsById.get(id) : undefined;
    return {
      ...rec,
      ms_id: hasId ? id : (rec.ms_id ?? rec.id),
      id: hasId ? id : (rec.id ?? rec.ms_id),
      spell_name: hasId ? (d?.spell_name ?? id) : (rec.spell_name ?? rec.name),
      name: hasId ? (d?.spell_name ?? id) : (rec.name ?? rec.spell_name),
      level: hasId ? d?.level : rec.level,
      element: hasId ? d?.element : rec.element,
      stamina_cast: hasId ? d?.stamina_cast : rec.stamina_cast,
      stamina_keeping: hasId ? d?.stamina_keeping : rec.stamina_keeping,
      damage: hasId ? d?.damage : rec.damage,
      distance: hasId ? d?.distance : rec.distance,
      zone_size: hasId ? d?.zone_size : rec.zone_size,
      form: hasId ? d?.form : rec.form,
      effect_time: hasId ? d?.effect_time : rec.effect_time,
      effect: hasId ? d?.effect : rec.effect,
      sort_key: hasId ? d?.sort_key : rec.sort_key,
      type: hasId ? (d?.type ?? rec.type) : rec.type,
    };
  });
  const patchSigns = sourceList(rawMagic.signs, resolvedMagic.signs).map((item) => {
    const rec = asRecord(item) ?? {};
    const id = getId(rec, ['ms_id', 'id'], ITEM_ID_RE.magicSpell);
    const hasId = id.length > 0;
    const d = id ? params.magicSpellsById.get(id) : undefined;
    return {
      ...rec,
      ms_id: hasId ? id : (rec.ms_id ?? rec.id),
      id: hasId ? id : (rec.id ?? rec.ms_id),
      spell_name: hasId ? (d?.spell_name ?? id) : (rec.spell_name ?? rec.name),
      name: hasId ? (d?.spell_name ?? id) : (rec.name ?? rec.spell_name),
      level: hasId ? d?.level : rec.level,
      element: hasId ? d?.element : rec.element,
      stamina_cast: hasId ? d?.stamina_cast : rec.stamina_cast,
      stamina_keeping: hasId ? d?.stamina_keeping : rec.stamina_keeping,
      damage: hasId ? d?.damage : rec.damage,
      distance: hasId ? d?.distance : rec.distance,
      zone_size: hasId ? d?.zone_size : rec.zone_size,
      form: hasId ? d?.form : rec.form,
      effect_time: hasId ? d?.effect_time : rec.effect_time,
      effect: hasId ? d?.effect : rec.effect,
      sort_key: hasId ? d?.sort_key : rec.sort_key,
      type: 'sign',
    };
  });
  const rawInvocations = asRecord(rawMagic.invocations) ?? {};
  const resolvedInvocations = asRecord(resolvedMagic.invocations) ?? {};
  const patchInvocationsByType = (invType: 'druid' | 'priest') =>
    sourceList(rawInvocations[invType], resolvedInvocations[invType]).map((item) => {
      const rec = asRecord(item) ?? {};
      const id = getId(rec, ['ms_id', 'id'], ITEM_ID_RE.magicSpell);
      const hasId = id.length > 0;
      const d = id ? params.magicInvocationsById.get(id) : undefined;
      return {
        ...rec,
        ms_id: hasId ? id : (rec.ms_id ?? rec.id),
        id: hasId ? id : (rec.id ?? rec.ms_id),
        invocation_name: hasId ? (d?.invocation_name ?? id) : (rec.invocation_name ?? rec.name),
        name: hasId ? (d?.invocation_name ?? id) : (rec.name ?? rec.invocation_name),
        level: hasId ? d?.level : rec.level,
        cult_or_circle: hasId ? d?.cult_or_circle : rec.cult_or_circle,
        stamina_cast: hasId ? d?.stamina_cast : rec.stamina_cast,
        stamina_keeping: hasId ? d?.stamina_keeping : rec.stamina_keeping,
        damage: hasId ? d?.damage : rec.damage,
        distance: hasId ? d?.distance : rec.distance,
        zone_size: hasId ? d?.zone_size : rec.zone_size,
        form: hasId ? d?.form : rec.form,
        effect_time: hasId ? d?.effect_time : rec.effect_time,
        effect: hasId ? d?.effect : rec.effect,
        type: hasId ? (d?.type ?? invType) : (rec.type ?? invType),
      };
    });
  const patchRituals = sourceList(rawMagic.rituals, resolvedMagic.rituals).map((item) => {
    const rec = asRecord(item) ?? {};
    const id = getId(rec, ['ms_id', 'id'], ITEM_ID_RE.magicSpell);
    const hasId = id.length > 0;
    const d = id ? params.magicRitualsById.get(id) : undefined;
    return {
      ...rec,
      ms_id: hasId ? id : (rec.ms_id ?? rec.id),
      id: hasId ? id : (rec.id ?? rec.ms_id),
      ritual_name: hasId ? (d?.ritual_name ?? id) : (rec.ritual_name ?? rec.name),
      name: hasId ? (d?.ritual_name ?? id) : (rec.name ?? rec.ritual_name),
      level: hasId ? d?.level : rec.level,
      dc: hasId ? d?.dc : rec.dc,
      preparing_time: hasId ? d?.preparing_time : rec.preparing_time,
      ingredients: hasId ? d?.ingredients : rec.ingredients,
      zone_size: hasId ? d?.zone_size : rec.zone_size,
      stamina_cast: hasId ? d?.stamina_cast : rec.stamina_cast,
      stamina_keeping: hasId ? d?.stamina_keeping : rec.stamina_keeping,
      effect_time: hasId ? d?.effect_time : rec.effect_time,
      form: hasId ? d?.form : rec.form,
      effect: hasId ? d?.effect : rec.effect,
      effect_tpl: hasId ? d?.effect_tpl : rec.effect_tpl,
      how_to_remove: hasId ? d?.how_to_remove : rec.how_to_remove,
      sort_key: hasId ? d?.sort_key : rec.sort_key,
    };
  });
  const patchHexes = sourceList(rawMagic.hexes, resolvedMagic.hexes).map((item) => {
    const rec = asRecord(item) ?? {};
    const id = getId(rec, ['ms_id', 'id'], ITEM_ID_RE.magicSpell);
    const hasId = id.length > 0;
    const d = id ? params.magicHexesById.get(id) : undefined;
    return {
      ...rec,
      ms_id: hasId ? id : (rec.ms_id ?? rec.id),
      id: hasId ? id : (rec.id ?? rec.ms_id),
      hex_name: hasId ? (d?.hex_name ?? id) : (rec.hex_name ?? rec.name),
      name: hasId ? (d?.hex_name ?? id) : (rec.name ?? rec.hex_name),
      level: hasId ? d?.level : rec.level,
      stamina_cast: hasId ? d?.stamina_cast : rec.stamina_cast,
      effect: hasId ? d?.effect : rec.effect,
      remove_instructions: hasId ? d?.remove_instructions : rec.remove_instructions,
      remove_components: hasId ? d?.remove_components : rec.remove_components,
      tooltip: hasId ? d?.tooltip : rec.tooltip,
      sort_key: hasId ? d?.sort_key : rec.sort_key,
    };
  });
  const sourceGifts = (() => {
    const rawList = asArray(rawMagic.gifts);
    if (rawList.length > 0) return rawList;
    return asArray(resolvedMagic.gifts);
  })();
  const patchGifts = sourceGifts.map((item) => {
    const rec = asRecord(item) ?? {};
    const id = getId(rec, ['mg_id', 'id'], ITEM_ID_RE.magicGift);
    const hasId = id.length > 0;
    const d = id ? params.giftsById.get(id) : undefined;
    return {
      ...rec,
      mg_id: hasId ? id : (rec.mg_id ?? rec.id),
      id: hasId ? id : (rec.id ?? rec.mg_id),
      gift_name: hasId ? (d?.gift_name ?? id) : (rec.gift_name ?? rec.name),
      name: hasId ? (d?.gift_name ?? id) : (rec.name ?? rec.gift_name),
      group_name: hasId ? d?.group_name : (rec.group_name ?? rec.group),
      group: hasId ? d?.group_name : (rec.group ?? rec.group_name),
      dc: hasId ? d?.dc : rec.dc,
      vigor_cost: hasId ? d?.vigor_cost : rec.vigor_cost,
      action_cost: hasId ? d?.action_cost : rec.action_cost,
      description: hasId ? d?.description : rec.description,
      sort_key: hasId ? d?.sort_key : rec.sort_key,
      is_major: hasId ? d?.is_major : rec.is_major,
    };
  });

  params.resolvedCharacter.gear = {
    ...resolvedGear,
    weapons: patchWeapons,
    armors: patchArmors,
    potions: patchPotions,
    vehicles: patchVehicles,
    general_gear: patchGeneralGear,
    recipes: patchRecipes,
    blueprints: patchBlueprints,
    ingredients: {
      ...resolvedIngredients,
      alchemy: patchAlchemyIngredients,
      craft: patchCraftIngredients,
    },
    magic: {
      ...resolvedMagic,
      spells: patchSpells,
      signs: patchSigns,
      invocations: {
        ...resolvedInvocations,
        druid: patchInvocationsByType('druid'),
        priest: patchInvocationsByType('priest'),
      },
      rituals: patchRituals,
      hexes: patchHexes,
      gifts: patchGifts,
    },
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
    const lang =
      (typeof payload?.lang === 'string' && payload.lang.trim()) ||
      c.req.query('lang') ||
      c.req.header('Accept-Language')?.split(',')[0]?.split('-')[0] ||
      'en';
    if (result?.state && typeof result.state === 'object' && !Array.isArray(result.state)) {
      await enrichProfessionalBundleLabelsInState(result.state as Record<string, unknown>, String(lang));
    }
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
    const lang =
      (typeof payload?.lang === 'string' && payload.lang.trim()) ||
      c.req.query('lang') ||
      c.req.header('Accept-Language')?.split(',')[0]?.split('-')[0] ||
      'en';
    if (result?.state && typeof result.state === 'object' && !Array.isArray(result.state)) {
      await enrichProfessionalBundleLabelsInState(result.state as Record<string, unknown>, String(lang));
    }
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

app.post('/i18n/resolve', async (c) => {
  try {
    const payload = (await c.req.json().catch(() => ({}))) as Record<string, unknown>;
    const lang = typeof payload.lang === 'string' && payload.lang.trim() ? payload.lang.trim() : 'en';
    const ids = Array.isArray(payload.ids)
      ? Array.from(
          new Set(
            payload.ids
              .filter((v): v is string => typeof v === 'string')
              .map((v) => v.trim())
              .filter((v) => UUID_RE.test(v)),
          ),
        )
      : [];
    const keys = Array.isArray(payload.keys)
      ? Array.from(
          new Set(
            payload.keys
              .filter((v): v is string => typeof v === 'string')
              .map((v) => v.trim())
              .filter((v) => v.length > 0),
          ),
        )
      : [];

    if (ids.length === 0 && keys.length === 0) {
      return c.json({ texts: {}, keys: {} });
    }

    const keyToId = new Map<string, string>();
    if (keys.length > 0) {
      const { rows: keyRows } = await db.query<{ key: string; id: string }>(
        `
          SELECT src.key::text AS key, ck_id(src.key)::text AS id
          FROM unnest($1::text[]) AS src(key)
        `,
        [keys],
      );
      for (const row of keyRows) {
        keyToId.set(row.key, row.id);
      }
    }
    const allIds = Array.from(new Set([
      ...ids,
      ...Array.from(keyToId.values()).filter((v) => UUID_RE.test(v)),
    ]));

    const { rows } = await db.query<I18nResolveRow>(
      `
        SELECT id::text AS id, lang, text
        FROM i18n_text
        WHERE id = ANY($1::uuid[])
          AND lang = ANY($2::text[])
      `,
      [allIds, [lang, 'en']],
    );

    const byId = new Map<string, Map<string, string>>();
    for (const row of rows) {
      const m = byId.get(row.id) ?? new Map<string, string>();
      m.set(row.lang, row.text);
      byId.set(row.id, m);
    }

    const texts: Record<string, string> = {};
    for (const id of allIds) {
      const m = byId.get(id);
      if (!m) continue;
      texts[id] = m.get(lang) ?? m.get('en') ?? id;
    }

    const keyTexts: Record<string, string> = {};
    for (const key of keys) {
      const id = keyToId.get(key);
      if (!id) continue;
      const m = byId.get(id);
      keyTexts[key] = m?.get(lang) ?? m?.get('en') ?? key;
    }

    return c.json({ texts, keys: keyTexts });
  } catch (error) {
    console.error('[i18n] resolve error', error);
    return c.json({ error: 'Failed to resolve i18n texts' }, 400);
  }
});

app.get('/user/settings', async (c) => {
  const ownerEmail = getUserEmail(c.get('authUser'));
  if (!ownerEmail) {
    return c.json({ error: 'Authenticated user email is required' }, 401);
  }

  try {
    const { rows } = await db.query<UserSettingsRow>(
      `
        SELECT owner_email, settings_json
        FROM wcc_user_settings
        WHERE owner_email = $1
      `,
      [ownerEmail],
    );
    const settings = normalizeUserSettingsRow(rows[0]);
    return c.json(settings);
  } catch (error) {
    console.error('[user-settings] load error', error);
    return c.json({ error: 'Failed to load user settings' }, 500);
  }
});

app.put('/user/settings', async (c) => {
  const user = c.get('authUser');
  const ownerEmail = getUserEmail(user);
  if (!ownerEmail) {
    return c.json({ error: 'Authenticated user email is required' }, 401);
  }

  const body = (await c.req.json().catch(() => null)) as unknown;
  const bodyRec = asRecord(body);
  const useW1AlchemyIcons =
    readBooleanAt(bodyRec, 'useW1AlchemyIcons') ??
    readBooleanAt(bodyRec, 'use_w1_alchemy_icons');
  const pdfTablesRaw =
    bodyRec?.pdfTables ??
    bodyRec?.pdf_tables ??
    null;
  const pdfTablesProvided = asRecord(pdfTablesRaw) != null;
  const normalizedPdfTables = pdfTablesProvided
    ? normalizePdfTablesSettingsFromUnknown(pdfTablesRaw)
    : null;

  if (useW1AlchemyIcons == null && !pdfTablesProvided) {
    return c.json({ error: 'At least one setting field is required' }, 400);
  }

  const patchPayload: Record<string, unknown> = {};
  if (useW1AlchemyIcons != null) {
    patchPayload.useW1AlchemyIcons = useW1AlchemyIcons;
  }
  if (normalizedPdfTables) {
    patchPayload.pdfTables = normalizedPdfTables;
  }

  try {
    const { rows } = await db.query<UserSettingsRow>(
      `
        INSERT INTO wcc_user_settings (
          owner_email,
          owner_sub,
          owner_provider,
          settings_json
        )
        VALUES ($1, $2, $3, $4::jsonb)
        ON CONFLICT (owner_email) DO UPDATE
        SET
          owner_sub = EXCLUDED.owner_sub,
          owner_provider = EXCLUDED.owner_provider,
          settings_json = COALESCE(wcc_user_settings.settings_json, '{}'::jsonb) || EXCLUDED.settings_json,
          updated_at = NOW()
        RETURNING owner_email, settings_json
      `,
      [
        ownerEmail,
        user?.sub ?? null,
        user?.provider ?? null,
        JSON.stringify(patchPayload),
      ],
    );
    return c.json(normalizeUserSettingsRow(rows[0]));
  } catch (error) {
    console.error('[user-settings] save error', error);
    return c.json({ error: 'Failed to save user settings' }, 500);
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
  const lang = requestedLang || 'en';

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
    let userSettings = DEFAULT_USER_SETTINGS;
    try {
      const settingsResult = await db.query<UserSettingsRow>(
        `
          SELECT owner_email, settings_json
          FROM wcc_user_settings
          WHERE owner_email = $1
        `,
        [ownerEmail],
      );
      userSettings = normalizeUserSettingsRow(settingsResult.rows[0]);
    } catch (error) {
      console.error('[characters] pdf user settings lookup failed, using defaults', error);
    }
    const rawCharacterForPdf: Record<string, unknown> = {
      ...rawCharacter,
      user_settings: {
        use_w1_alchemy_icons: userSettings.useW1AlchemyIcons,
        pdf_tables: userSettings.pdfTables,
      },
    };

    const resolvedCharacter = await resolveCharacterRawI18n(rawCharacter, lang);
    const weaponIds = readIdListFromGear(rawCharacter, 'weapons', 'w_id', ITEM_ID_RE.weapon);
    const armorIds = readIdListFromGear(rawCharacter, 'armors', 'a_id', ITEM_ID_RE.armor);
    const potionIds = readIdListFromGear(rawCharacter, 'potions', 'p_id', ITEM_ID_RE.potion);
    const recipeIds = readIdListFromGearAny(rawCharacter, 'recipes', ['r_id', 'id'], ITEM_ID_RE.recipe);
    const upgradeIds = readIdListFromGearAny(rawCharacter, 'upgrades', ['u_id', 'id'], ITEM_ID_RE.upgrade);
    const blueprintIds = readIdListFromGearAny(rawCharacter, 'blueprints', ['b_id', 'bp_id', 'id'], ITEM_ID_RE.blueprint);
    const generalGearIds = readIdListFromGearAny(rawCharacter, 'general_gear', ['t_id', 'id'], ITEM_ID_RE.generalGear);
    const vehicleIds = readIdListFromGearAny(rawCharacter, 'vehicles', ['wt_id', 'id'], ITEM_ID_RE.vehicle);
    const ingredientAlchemyIds = readIdListFromIngredients(rawCharacter, 'alchemy', 'i_id');
    const ingredientCraftIds = readIdListFromIngredients(rawCharacter, 'craft', 'i_id');
    const ingredientIds = Array.from(new Set([...ingredientAlchemyIds, ...ingredientCraftIds]));
    const spellIds = readIdListFromMagicList(rawCharacter, 'spells');
    const signIds = readIdListFromMagicList(rawCharacter, 'signs');
    const ritualIds = readIdListFromMagicList(rawCharacter, 'rituals');
    const hexIds = readIdListFromMagicList(rawCharacter, 'hexes');
    const invocationDruidIds = readIdListFromMagicInvocations(rawCharacter, 'druid');
    const invocationPriestIds = readIdListFromMagicInvocations(rawCharacter, 'priest');
    const magicSpellLikeIds = Array.from(new Set([...spellIds, ...signIds]));
    const magicInvocationIds = Array.from(new Set([...invocationDruidIds, ...invocationPriestIds]));
    const giftIds = readIdListFromMagicGifts(rawCharacter);

    const weaponsById = new Map<string, WeaponPdfDetailsRow>();
    const armorsById = new Map<string, ArmorPdfDetailsRow>();
    const potionsById = new Map<string, PotionPdfDetailsRow>();
    const recipesById = new Map<string, RecipePdfDetailsRow>();
    const blueprintsById = new Map<string, BlueprintPdfDetailsRow>();
    const ingredientsById = new Map<string, IngredientPdfDetailsRow>();
    const generalGearById = new Map<string, GeneralGearPdfDetailsRow>();
    const vehiclesById = new Map<string, VehiclePdfDetailsRow>();
    const magicSpellsById = new Map<string, MagicSpellPdfDetailsRow>();
    const magicInvocationsById = new Map<string, MagicInvocationPdfDetailsRow>();
    const magicRitualsById = new Map<string, MagicRitualPdfDetailsRow>();
    const magicHexesById = new Map<string, MagicHexPdfDetailsRow>();
    const giftsById = new Map<string, MagicGiftPdfDetailsRow>();
    const itemEffectsGlossary: ItemEffectGlossaryRow[] = [];

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

    try {
      if (recipeIds.length > 0) {
        const { rows } = await db.query<RecipePdfDetailsRow>(
          `
            SELECT r_id, recipe_name, recipe_group, craft_level, complexity, time_craft, formula_en,
                   price_formula, minimal_ingredients_cost, time_effect, toxicity, recipe_description,
                   weight_potion, price_potion
            FROM wcc_item_recipes_v
            WHERE lang = $1 AND r_id = ANY($2::text[])
          `,
          [lang, recipeIds],
        );
        rows.forEach((r) => recipesById.set(r.r_id, r));
      }
    } catch (error) {
      console.error('[characters] pdf recipe lookup failed', error);
    }

    try {
      if (blueprintIds.length > 0) {
        const { rows } = await db.query<BlueprintPdfDetailsRow>(
          `
            SELECT b_id, blueprint_name, blueprint_group, craft_level, difficulty_check, time_craft,
                   item_id, components, item_desc, price_components, price, price_item
            FROM wcc_item_blueprints_v
            WHERE lang = $1 AND b_id = ANY($2::text[])
          `,
          [lang, blueprintIds],
        );
        rows.forEach((r) => blueprintsById.set(r.b_id, r));
      }
    } catch (error) {
      console.error('[characters] pdf blueprint lookup failed', error);
    }

    try {
      if (ingredientIds.length > 0) {
        const { rows } = await db.query<IngredientPdfDetailsRow>(
          `
            SELECT i_id, ingredient_name, alchemy_substance, alchemy_substance_en, harvesting_complexity, weight, price
            FROM wcc_item_ingredients_v
            WHERE lang = $1 AND i_id = ANY($2::text[])
          `,
          [lang, ingredientIds],
        );
        rows.forEach((r) => ingredientsById.set(r.i_id, r));
      }
    } catch (error) {
      console.error('[characters] pdf ingredient lookup failed', error);
    }

    try {
      if (generalGearIds.length > 0) {
        const { rows } = await db.query<GeneralGearPdfDetailsRow>(
          `
            SELECT t_id, gear_name, group_name, subgroup_name, gear_description, concealment, weight, price
            FROM wcc_item_general_gear_v
            WHERE lang = $1 AND t_id = ANY($2::text[])
          `,
          [lang, generalGearIds],
        );
        rows.forEach((r) => generalGearById.set(r.t_id, r));
      }
    } catch (error) {
      console.error('[characters] pdf general gear lookup failed', error);
    }

    try {
      if (vehicleIds.length > 0) {
        const { rows } = await db.query<VehiclePdfDetailsRow>(
          `
            SELECT wt_id, vehicle_name, subgroup_name, base, control_modifier, speed, occupancy, hp, weight, price
            FROM wcc_item_vehicles_v
            WHERE lang = $1 AND wt_id = ANY($2::text[])
          `,
          [lang, vehicleIds],
        );
        rows.forEach((r) => vehiclesById.set(r.wt_id, r));
      }
    } catch (error) {
      console.error('[characters] pdf vehicle lookup failed', error);
    }

    try {
      if (magicSpellLikeIds.length > 0) {
        const { rows } = await db.query<MagicSpellPdfDetailsRow>(
          `
            SELECT ms_id, spell_name, level, element, stamina_cast, stamina_keeping, damage, distance, zone_size, form, effect_time, effect, sort_key, type
            FROM wcc_magic_spells_v
            WHERE lang = $1 AND ms_id = ANY($2::text[])
          `,
          [lang, magicSpellLikeIds],
        );
        rows.forEach((r) => magicSpellsById.set(r.ms_id, r));
      }
    } catch (error) {
      console.error('[characters] pdf spells/signs lookup failed', error);
    }

    try {
      if (magicInvocationIds.length > 0) {
        const { rows } = await db.query<MagicInvocationPdfDetailsRow>(
          `
            SELECT ms_id, invocation_name, level, cult_or_circle, stamina_cast, stamina_keeping, damage, distance, zone_size, form, effect_time, effect, type
            FROM wcc_magic_invocations_v
            WHERE lang = $1 AND ms_id = ANY($2::text[])
          `,
          [lang, magicInvocationIds],
        );
        rows.forEach((r) => magicInvocationsById.set(r.ms_id, r));
      }
    } catch (error) {
      console.error('[characters] pdf invocations lookup failed', error);
    }

    try {
      if (ritualIds.length > 0) {
        const { rows } = await db.query<MagicRitualPdfDetailsRow>(
          `
            SELECT ms_id, ritual_name, level, dc, preparing_time, ingredients, zone_size, stamina_cast, stamina_keeping, effect_time, form, effect, effect_tpl, how_to_remove, sort_key
            FROM wcc_magic_rituals_v
            WHERE lang = $1 AND ms_id = ANY($2::text[])
          `,
          [lang, ritualIds],
        );
        rows.forEach((r) => magicRitualsById.set(r.ms_id, r));
      }
    } catch (error) {
      console.error('[characters] pdf rituals lookup failed', error);
    }

    try {
      if (hexIds.length > 0) {
        const { rows } = await db.query<MagicHexPdfDetailsRow>(
          `
            SELECT ms_id, hex_name, level, stamina_cast, effect, remove_instructions, remove_components, tooltip, sort_key
            FROM wcc_magic_hexes_v
            WHERE lang = $1 AND ms_id = ANY($2::text[])
          `,
          [lang, hexIds],
        );
        rows.forEach((r) => magicHexesById.set(r.ms_id, r));
      }
    } catch (error) {
      console.error('[characters] pdf hexes lookup failed', error);
    }

    try {
      if (giftIds.length > 0) {
        const { rows } = await db.query<MagicGiftPdfDetailsRow>(
          `
            SELECT mg_id, group_name, gift_name, dc, vigor_cost, action_cost, description, sort_key, is_major
            FROM wcc_magic_gifts_v
            WHERE lang = $1 AND mg_id = ANY($2::text[])
          `,
          [lang, giftIds],
        );
        rows.forEach((r) => giftsById.set(r.mg_id, r));
      }
    } catch (error) {
      console.error('[characters] pdf gifts lookup failed', error);
    }

    try {
      const blueprintItemIds: string[] = [];
      for (const row of blueprintsById.values()) {
        const itemId = typeof row.item_id === 'string' ? row.item_id.trim() : '';
        if (itemId) blueprintItemIds.push(itemId);
      }

      const itemIdsForEffects = Array.from(
        new Set([...weaponIds, ...armorIds, ...upgradeIds, ...blueprintItemIds]),
      ).filter((id) => /^(W|A|U)/.test(id));

      if (itemIdsForEffects.length > 0) {
        const { rows } = await db.query<ItemEffectLookupRow>(
          `
            SELECT ite.item_id::text AS item_id,
                   ite.e_e_id::text AS effect_id,
                   ite.modifier AS modifier,
                   COALESCE(ie_lang.text, ie_en.text, '') AS name_tpl,
                   COALESCE(ide_lang.text, ide_en.text, '') AS desc_tpl,
                   COALESCE(iec_lang.text, iec_en.text, '') AS cond_tpl
            FROM wcc_item_to_effects ite
            LEFT JOIN wcc_item_effects e ON e.e_id = ite.e_e_id
            LEFT JOIN i18n_text ie_lang ON ie_lang.id = e.name_id AND ie_lang.lang = $1
            LEFT JOIN i18n_text ie_en ON ie_en.id = e.name_id AND ie_en.lang = 'en'
            LEFT JOIN i18n_text ide_lang ON ide_lang.id = e.description_id AND ide_lang.lang = $1
            LEFT JOIN i18n_text ide_en ON ide_en.id = e.description_id AND ide_en.lang = 'en'
            LEFT JOIN wcc_item_effect_conditions ec ON ec.ec_id = ite.ec_ec_id
            LEFT JOIN i18n_text iec_lang ON iec_lang.id = ec.description_id AND iec_lang.lang = $1
            LEFT JOIN i18n_text iec_en ON iec_en.id = ec.description_id AND iec_en.lang = 'en'
            WHERE ite.item_id = ANY($2::text[])
            ORDER BY ite.e_e_id ASC, ite.modifier ASC NULLS FIRST
          `,
          [lang, itemIdsForEffects],
        );

        const normalize = (v: string | null | undefined): string => String(v ?? '').trim();
        const replaceMod = (tpl: string, modifier: number | null): string => {
          const mod = modifier === null || modifier === undefined ? '' : String(modifier);
          return tpl.replaceAll('<mod>', mod);
        };
        const toSortNumber = (effectId: string): number => {
          const m = /^E(\d+)$/.exec(effectId.trim());
          if (!m) return Number.POSITIVE_INFINITY;
          const n = Number(m[1]);
          return Number.isFinite(n) ? n : Number.POSITIVE_INFINITY;
        };

        const byKey = new Map<string, { effectId: string; modifier: number | null; row: ItemEffectGlossaryRow }>();
        for (const row of rows) {
          const effectId = normalize(row.effect_id);
          const nameTpl = normalize(row.name_tpl);
          if (!effectId && !nameTpl) continue;
          const cond = replaceMod(normalize(row.cond_tpl), row.modifier).trim();
          const nameBase = replaceMod(nameTpl || effectId, row.modifier).trim();
          const name = cond ? `${nameBase} [${cond}]` : nameBase;
          const value = replaceMod(normalize(row.desc_tpl), row.modifier).trim();
          const key = `${effectId}|${row.modifier ?? ''}|${cond}`;
          if (byKey.has(key)) continue;
          byKey.set(key, {
            effectId,
            modifier: row.modifier ?? null,
            row: { name, value },
          });
        }

        const sorted = Array.from(byKey.values()).sort((a, b) => {
          const an = toSortNumber(a.effectId);
          const bn = toSortNumber(b.effectId);
          if (an !== bn) return an - bn;
          const am = a.modifier ?? Number.NEGATIVE_INFINITY;
          const bm = b.modifier ?? Number.NEGATIVE_INFINITY;
          if (am !== bm) return am - bm;
          return a.row.name.localeCompare(b.row.name, undefined, { sensitivity: 'base' });
        });
        itemEffectsGlossary.push(...sorted.map((x) => x.row));
      }
    } catch (error) {
      console.error('[characters] pdf item effects lookup failed', error);
    }

    patchResolvedGearFromDbViews({
      rawCharacter,
      resolvedCharacter,
      weaponsById,
      armorsById,
      potionsById,
      recipesById,
      blueprintsById,
      ingredientsById,
      generalGearById,
      vehiclesById,
      magicSpellsById,
      magicInvocationsById,
      magicRitualsById,
      magicHexesById,
      giftsById,
    });

    const skillsCatalog = await getSkillsCatalog({ lang }).catch(() => ({ skills: [] as Array<{ id: string; param: string | null; name: string }> }));
    const skillsCatalogById = new Map(
      (Array.isArray(skillsCatalog.skills) ? skillsCatalog.skills : []).map((s) => [s.id, { param: s.param, name: s.name }] as const),
    );
    const pdfBuffer = await generateCharacterPdfBuffer({
      rawCharacter: rawCharacterForPdf,
      resolvedCharacter,
      lang,
      skillsCatalogById,
      itemEffectsGlossary,
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
