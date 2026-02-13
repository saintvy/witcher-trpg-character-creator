import type { CharacterPdfPage4I18n } from './page4I18n.js';

function asRecord(value: unknown): Record<string, unknown> | null {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null;
  return value as Record<string, unknown>;
}

function asString(value: unknown): string | null {
  if (value === null || value === undefined) return null;
  if (typeof value === 'string') return value;
  if (typeof value === 'number' && Number.isFinite(value)) return String(value);
  if (typeof value === 'boolean') return value ? 'true' : 'false';
  return null;
}

function asNumber(value: unknown): number | null {
  if (value === null || value === undefined) return null;
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
}

function getPath(root: unknown, path: string): unknown {
  const parts = path.split('.');
  let current: any = root;
  for (const segment of parts) {
    if (!current || typeof current !== 'object') return undefined;
    current = (current as any)[segment];
  }
  return current;
}

function getFirst(root: unknown, paths: string[]): unknown {
  for (const path of paths) {
    const value = path.includes('.') ? getPath(root, path) : asRecord(root)?.[path];
    if (value !== undefined) return value;
  }
  return undefined;
}

function getFirstString(root: unknown, paths: string[]): string {
  return asString(getFirst(root, paths)) ?? '';
}

function readStat(characterJson: unknown, statId: string): { cur: number | null; bonus: number | null; raceBonus: number | null } {
  const statsRoot = asRecord(getFirst(characterJson, ['statistics', 'stats', 'attributes'])) ?? {};
  const statRec = asRecord(statsRoot[statId]);
  if (!statRec) return { cur: null, bonus: null, raceBonus: null };
  return {
    cur: asNumber(statRec.cur),
    bonus: asNumber(statRec.bonus),
    raceBonus: asNumber(statRec.race_bonus),
  };
}

function normalizeProfession(profession: string): string {
  return profession.trim().toLowerCase();
}

function hasAny(profession: string, needles: string[]): boolean {
  return needles.some((n) => profession.includes(n));
}

function toSortKey(value: unknown): number {
  const n = typeof value === 'number' ? value : Number(String(value ?? '').trim());
  return Number.isFinite(n) ? n : Number.POSITIVE_INFINITY;
}

export type MagicSpellLikeRow = {
  name: string;
  element: string;
  staminaCast: string;
  staminaKeeping: string;
  damage: string;
  distance: string;
  zoneSize: string;
  form: string;
  effectTime: string;
  tooltip: string;
};

export type MagicInvocationRow = {
  name: string;
  group: string;
  staminaCast: string;
  staminaKeeping: string;
  damage: string;
  distance: string;
  zoneSize: string;
  form: string;
  effectTime: string;
  tooltip: string;
};

export type MagicRitualRow = {
  name: string;
  level: string;
  dc: string;
  preparingTime: string;
  staminaCast: string;
  staminaKeeping: string;
  zoneSize: string;
  form: string;
  effectTime: string;
  tooltip: string;
};

export type MagicHexRow = {
  name: string;
  level: string;
  staminaCast: string;
  tooltip: string;
};

export type MagicGiftDetails = {
  mg_id: string;
  group_name: string;
  gift_name: string;
  dc: number | null;
  vigor_cost: number | null;
  description: string | null;
  sort_key: string | null;
  is_major: boolean | null;
};

export type MagicGiftRow = {
  name: string;
  group: string;
  sl: string;
  vigor: string;
  cost: string;
  description: string;
};

export type ItemEffectGlossaryRow = {
  name: string;
  value: string;
};

export type CharacterPdfPage4Vm = {
  i18n: CharacterPdfPage4I18n;
  shouldRender: boolean;
  onlyGiftsData: boolean;
  showSpellsSigns: boolean;
  showInvocations: boolean;
  showRituals: boolean;
  showHexes: boolean;
  showGifts: boolean;
  showItemEffects: boolean;
  invocationsTitle: string;
  invocationsBoxClass: string;
  spellsSigns: MagicSpellLikeRow[];
  invocations: MagicInvocationRow[];
  rituals: MagicRitualRow[];
  hexes: MagicHexRow[];
  gifts: MagicGiftRow[];
  itemEffects: ItemEffectGlossaryRow[];
};

export function mapCharacterJsonToPage4Vm(
  characterJson: unknown,
  deps: {
    i18n: CharacterPdfPage4I18n;
    giftDetailsById?: ReadonlyMap<string, MagicGiftDetails>;
    itemEffectsGlossary?: ReadonlyArray<ItemEffectGlossaryRow>;
  },
): CharacterPdfPage4Vm {
  const i18n = deps.i18n;

  const profession = normalizeProfession(getFirstString(characterJson, ['profession', 'role', 'class', 'career']));
  const isMage = hasAny(profession, ['mage', 'маг']);
  const isWitcher = hasAny(profession, ['witcher', 'ведьмак', 'ведьмач']);
  const isDruid = hasAny(profession, ['druid', 'друид']);
  // Druids use invocations (like priests), so treat them as priest-like for PDF visibility.
  const isPriest = hasAny(profession, ['priest', 'жрец']) || isDruid;

  const vigor = readStat(characterJson, 'vigor');
  const vigorTotal = (vigor.cur ?? 0) + (vigor.bonus ?? 0) + (vigor.raceBonus ?? 0);
  const hasVigor = vigorTotal > 0;

  const gearRoot = asRecord(getFirst(characterJson, ['gear', 'character.gear'])) ?? {};
  const magicRec = asRecord(gearRoot.magic) ?? {};

  const spellsRaw = Array.isArray(magicRec.spells) ? (magicRec.spells as unknown[]) : [];
  const signsRaw = Array.isArray(magicRec.signs) ? (magicRec.signs as unknown[]) : [];
  const spellsSignsRaw = [...spellsRaw, ...signsRaw];

  const spellsSigns: MagicSpellLikeRow[] = spellsSignsRaw
    .map((x) => {
      const rec = asRecord(x);
      if (!rec) return null;
      const name = (asString(rec.spell_name) ?? asString(rec.name) ?? '').trim();
      if (!name) return null;
      const tooltip = (asString(rec.effect) ?? asString(rec.tooltip) ?? '').trim();
      return {
        name,
        element: (asString(rec.element) ?? '').trim(),
        staminaCast: (asString(rec.stamina_cast) ?? '').trim(),
        staminaKeeping: (asString(rec.stamina_keeping) ?? '').trim(),
        damage: (asString(rec.damage) ?? '').trim(),
        distance: (asString(rec.distance) ?? '').trim(),
        zoneSize: (asString(rec.zone_size) ?? '').trim(),
        form: (asString(rec.form) ?? '').trim(),
        effectTime: (asString(rec.effect_time) ?? '').trim(),
        tooltip,
        _sortKey: toSortKey(rec.sort_key),
      };
    })
    .filter((x): x is (MagicSpellLikeRow & { _sortKey: number }) => Boolean(x))
    .sort((a, b) => (a._sortKey - b._sortKey) || a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }))
    .map(({ _sortKey: _ignored, ...rest }) => rest);

  const invocationsRec = asRecord(magicRec.invocations) ?? {};
  const druidRaw = Array.isArray(invocationsRec.druid) ? (invocationsRec.druid as unknown[]) : [];
  const priestRaw = Array.isArray(invocationsRec.priest) ? (invocationsRec.priest as unknown[]) : [];
  const invocations: MagicInvocationRow[] = [...druidRaw, ...priestRaw]
    .map((x) => {
      const rec = asRecord(x);
      if (!rec) return null;
      const name = (asString(rec.invocation_name) ?? asString(rec.name) ?? '').trim();
      if (!name) return null;
      const tooltip = (asString(rec.effect) ?? asString(rec.tooltip) ?? '').trim();
      return {
        name,
        group: (asString(rec.cult_or_circle) ?? '').trim(),
        staminaCast: (asString(rec.stamina_cast) ?? '').trim(),
        staminaKeeping: (asString(rec.stamina_keeping) ?? '').trim(),
        damage: (asString(rec.damage) ?? '').trim(),
        distance: (asString(rec.distance) ?? '').trim(),
        zoneSize: (asString(rec.zone_size) ?? '').trim(),
        form: (asString(rec.form) ?? '').trim(),
        effectTime: (asString(rec.effect_time) ?? '').trim(),
        tooltip,
      };
    })
    .filter((x): x is MagicInvocationRow => Boolean(x))
    .sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }));

  const ritualsRaw = Array.isArray(magicRec.rituals) ? (magicRec.rituals as unknown[]) : [];
  const rituals: MagicRitualRow[] = ritualsRaw
    .map((x) => {
      const rec = asRecord(x);
      if (!rec) return null;
      const name = (asString(rec.ritual_name) ?? asString(rec.name) ?? '').trim();
      if (!name) return null;
      const tooltip = (asString((rec as any).effect_tpl) ?? asString(rec.effect) ?? asString(rec.tooltip) ?? '').trim();
      return {
        name,
        level: (asString(rec.level) ?? '').trim(),
        dc: (asString(rec.dc) ?? '').trim(),
        preparingTime: (asString(rec.preparing_time) ?? '').trim(),
        staminaCast: (asString(rec.stamina_cast) ?? '').trim(),
        staminaKeeping: (asString(rec.stamina_keeping) ?? '').trim(),
        zoneSize: (asString(rec.zone_size) ?? '').trim(),
        form: (asString(rec.form) ?? '').trim(),
        effectTime: (asString(rec.effect_time) ?? '').trim(),
        tooltip,
        _sortKey: toSortKey(rec.sort_key),
      };
    })
    .filter((x): x is (MagicRitualRow & { _sortKey: number }) => Boolean(x))
    .sort((a, b) => (a._sortKey - b._sortKey) || a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }))
    .map(({ _sortKey: _ignored, ...rest }) => rest);

  const hexesRaw = Array.isArray(magicRec.hexes) ? (magicRec.hexes as unknown[]) : [];
  const hexes: MagicHexRow[] = hexesRaw
    .map((x) => {
      const rec = asRecord(x);
      if (!rec) return null;
      const name = (asString(rec.hex_name) ?? asString(rec.name) ?? '').trim();
      if (!name) return null;
      const tooltip = (asString(rec.tooltip) ?? asString(rec.effect) ?? '').trim();
      return {
        name,
        level: (asString(rec.level) ?? '').trim(),
        staminaCast: (asString(rec.stamina_cast) ?? '').trim(),
        tooltip,
        _sortKey: toSortKey(rec.sort_key),
      };
    })
    .filter((x): x is (MagicHexRow & { _sortKey: number }) => Boolean(x))
    .sort((a, b) => (a._sortKey - b._sortKey) || a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }))
    .map(({ _sortKey: _ignored, ...rest }) => rest);

  const giftsRaw = Array.isArray(magicRec.gifts) ? (magicRec.gifts as unknown[]) : [];
  const giftIds = giftsRaw
    .map((x) => {
      const rec = asRecord(x);
      if (!rec) return '';
      const id = rec.mg_id ?? (rec as any).id;
      return String(id ?? '').trim();
    })
    .filter((x) => x.length > 0);

  const giftDetails = deps.giftDetailsById ?? new Map<string, MagicGiftDetails>();
  const gifts: MagicGiftRow[] = giftIds
    .map((id) => {
      const d = giftDetails.get(id);
      if (!d) return null;
      const isMajor = d.is_major === true;
      return {
        name: String(d.gift_name ?? '').trim() || id,
        group: String(d.group_name ?? '').trim(),
        sl: d.dc === null || d.dc === undefined ? '' : String(d.dc),
        vigor: d.vigor_cost === null || d.vigor_cost === undefined ? '' : String(d.vigor_cost),
        cost: isMajor ? i18n.gifts.costFullAction : i18n.gifts.costAction,
        description: String(d.description ?? '').trim(),
        _sortKey: String(d.sort_key ?? '').trim(),
      };
    })
    .filter((x): x is (MagicGiftRow & { _sortKey: string }) => Boolean(x))
    .sort((a, b) => (a._sortKey || a.group || '').localeCompare(b._sortKey || b.group || '', undefined, { sensitivity: 'base' }))
    .map(({ _sortKey: _ignored, ...rest }) => rest);

  const itemEffects = Array.isArray(deps.itemEffectsGlossary) ? [...deps.itemEffectsGlossary] : [];
  const showItemEffects = itemEffects.length > 0;

  const onlyGiftsMagic =
    gifts.length > 0 &&
    spellsSigns.length === 0 &&
    invocations.length === 0 &&
    rituals.length === 0 &&
    hexes.length === 0;

  const onlyGiftsData = onlyGiftsMagic && !showItemEffects;

  // Display rules:
  // - If corresponding magic exists in JSON -> show the table.
  // - Profession / Vigor only affects whether to show an empty table.
  const showSpellsSigns = onlyGiftsMagic ? false : spellsSigns.length > 0 || isMage || isWitcher;
  const showInvocations = onlyGiftsMagic ? false : invocations.length > 0 || isPriest;
  const showRituals = onlyGiftsMagic ? false : rituals.length > 0 || hasVigor;
  const showHexes = onlyGiftsMagic ? false : hexes.length > 0 || hasVigor;
  const showGifts = gifts.length > 0;
  const shouldRender = showSpellsSigns || showInvocations || showRituals || showHexes || showGifts || showItemEffects;
  const resolveI18nFallback = (value: string, fallback: string): string => {
    const v = String(value ?? '').trim();
    if (!v) return fallback;
    // If a key wasn't found in DB, loaders fall back to returning the key itself.
    if (v.startsWith('witcher_cc.')) return fallback;
    return v;
  };

  return {
    i18n,
    shouldRender,
    onlyGiftsData,
    showSpellsSigns,
    showInvocations,
    showRituals,
    showHexes,
    showGifts,
    showItemEffects,
    invocationsTitle: isDruid
      ? resolveI18nFallback(i18n.source.invocationsDruidTitle, i18n.lang === 'ru' ? 'Инвокации друида' : 'Druid Invocations')
      : i18n.source.invocationsPriestTitle,
    invocationsBoxClass: isDruid ? 'magic4-invocations-druid-box' : 'magic4-invocations-box',
    spellsSigns,
    invocations,
    rituals,
    hexes,
    gifts,
    itemEffects,
  };
}
