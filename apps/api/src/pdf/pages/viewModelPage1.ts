import type { CharacterPdfPage1I18n } from './page1I18n.js';

export type SkillCatalogInfo = {
  name: string;
  param: string | null;
  isDifficult: boolean;
};

export type CharacterPdfPage1Vm = {
  i18n: CharacterPdfPage1I18n;
  base: {
    name: string;
    race: string;
    gender: string;
    age: string;
    profession: string;
    school?: string;
    definingSkill: string;
  };
  computed: {
    run: string;
    leap: string;
    stability: string;
    punch: string;
    kick: string;
    rest: string;
    vigor: string;
  };
  mainStats: { id: string; label: string; cur: number | null; bonus: number | null; raceBonus: number | null }[];
  consumables: {
    id: 'carry' | 'hp' | 'sta' | 'resolve' | 'luck';
    label: string;
    max: string;
    current: string;
  }[];
  avatar: { dataUrl?: string | null };
  skillGroups: {
    statId: string;
    statLabel: string;
    stat: { cur: number | null; bonus: number | null; raceBonus: number | null };
    skills: {
      id: string;
      name: string;
      cur: number | null;
      bonus: number | null;
      raceBonus: number | null;
      isDifficult: boolean;
    }[];
  }[];
  professional: {
    branches: {
      title: string;
      color: 'blue' | 'green' | 'red';
      skills: { id: string; name: string; paramAbbr: string }[];
    }[];
  };
  perks: Array<{ perk: string; effect: string }>;
  equipment: {
    weapons: {
      id: string;
      qty: string;
      name: string;
      effects: string;
      dmg: string;
      dmgTypes: string;
      reliability: string;
      hands: string;
      concealment: string;
      enhancements: string;
      weight: string;
      price: string;
    }[];
    armors: {
      id: string;
      qty: string;
      name: string;
      effects: string;
      sp: string;
      enc: string;
      enhancements: string;
      weight: string;
      price: string;
    }[];
    potions: { id: string; qty: string; name: string; toxicity: string; duration: string; effect: string; weight: string; price: string }[];
    magic: {
      type: string;
      name: string;
      element: string; // element для знаков/спеллов, cult_or_circle для инвокаций
      staminaCast: string;
      staminaKeeping: string;
      damage: string;
      effectTime: string;
      distance: string;
      zoneSize: string;
      form: string;
    }[];
  };
};

export type WeaponDetails = {
  w_id: string;
  weapon_name: string | null;
  dmg: string | null;
  dmg_types: string | null;
  weight: string | null;
  price: number | null;
  hands: number | null;
  reliability: number | null;
  concealment: string | null;
  effect_names: string | null;
};

export type ArmorDetails = {
  a_id: string;
  armor_name: string | null;
  stopping_power: number | null;
  encumbrance: number | null;
  enhancements: number | null;
  weight: string | null;
  price: number | null;
  effect_names: string | null;
};

export type PotionDetails = {
  p_id: string;
  potion_name: string | null;
  toxicity: string | null;
  time_effect: string | null;
  effect: string | null;
  weight: string | null;
  price: number | null;
};

function asRecord(value: unknown): Record<string, unknown> | null {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) return null;
  return value as Record<string, unknown>;
}

function asString(value: unknown): string | null {
  if (value === null || value === undefined) return null;
  if (typeof value === 'string') return value;
  if (typeof value === 'number') return Number.isFinite(value) ? String(value) : null;
  if (typeof value === 'boolean') return value ? 'true' : 'false';
  return null;
}

function asNumber(value: unknown): number | null {
  if (typeof value === 'number') return Number.isFinite(value) ? value : null;
  if (typeof value === 'string') {
    const num = Number(value);
    return Number.isFinite(num) ? num : null;
  }
  return null;
}

function getPath(root: unknown, path: string): unknown {
  const segments = path.split('.').filter(Boolean);
  let current: unknown = root;
  for (const segment of segments) {
    const record = asRecord(current);
    if (!record) return undefined;
    current = record[segment];
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

type SkillValue = { cur?: unknown; bonus?: unknown; race_bonus?: unknown };

function readSkillValue(value: unknown): { cur: number | null; bonus: number | null; raceBonus: number | null } {
  const rec = asRecord(value) as SkillValue | null;
  if (!rec) return { cur: null, bonus: null, raceBonus: null };
  return {
    cur: asNumber(rec.cur),
    bonus: asNumber(rec.bonus),
    raceBonus: asNumber(rec.race_bonus),
  };
}

function formatSigned(value: number): string {
  return value >= 0 ? `+${value}` : `${value}`;
}

function formatSkillValue(value: { cur: number | null; bonus: number | null; raceBonus: number | null }): string {
  const parts: string[] = [];
  if (value.cur !== null && value.cur !== 0) parts.push(String(value.cur));
  if (value.bonus !== null && value.bonus !== 0) parts.push(formatSigned(value.bonus));
  if (value.raceBonus !== null && value.raceBonus !== 0) parts.push(formatSigned(value.raceBonus));
  return parts.join('');
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

function formatValueWithBonuses(value: { cur: number | null; bonus: number | null; raceBonus: number | null }): string {
  const parts: string[] = [];

  if (value.cur !== null) parts.push(String(value.cur));
  if (value.bonus !== null && value.bonus !== 0) parts.push(formatSigned(value.bonus));
  if (value.raceBonus !== null && value.raceBonus !== 0) parts.push(formatSigned(value.raceBonus));

  return parts.join('');
}

function readCalcCurString(characterJson: unknown, key: string): string {
  const calc = asRecord(getPath(characterJson, 'statistics.calculated')) ?? {};
  const rec = asRecord(calc[key]);
  const curRaw = rec?.cur;
  const curStr = asString(curRaw) ?? '';
  const curNum = asNumber(curRaw);
  if (curNum === null) return curStr;

  const bonus = asNumber(rec?.bonus);
  const raceBonus = asNumber(rec?.race_bonus);
  return formatValueWithBonuses({ cur: curNum, bonus, raceBonus });
}

function sumCarriedWeight(characterJson: unknown): number | null {
  const gearRoot = getFirst(characterJson, ['gear', 'inventory', 'items']);

  const flatten = (value: unknown): unknown[] => {
    if (Array.isArray(value)) return value.flatMap(flatten);
    const rec = asRecord(value);
    if (!rec) return [];
    return Object.values(rec).flatMap(flatten);
  };

  const items = Array.isArray(gearRoot) ? gearRoot : flatten(gearRoot);
  if (items.length === 0) return null;

  let total = 0;
  let seen = false;
  for (const item of items) {
    const rec = asRecord(item);
    if (!rec) continue;
    const weight = asNumber(rec.weight);
    if (weight === null) continue;
    const qty = asNumber(rec.amount) ?? asNumber(rec.qty) ?? asNumber(rec.quantity) ?? 1;
    total += weight * qty;
    seen = true;
  }

  return seen ? total : null;
}

function buildSkillCatalogMaps(
  catalog: ReadonlyMap<string, SkillCatalogInfo> | undefined,
): { nameById: ReadonlyMap<string, string>; paramById: ReadonlyMap<string, string>; difficultById: ReadonlyMap<string, boolean> } {
  if (!catalog) {
    return { nameById: new Map(), paramById: new Map(), difficultById: new Map() };
  }
  const nameById = new Map<string, string>();
  const paramById = new Map<string, string>();
  const difficultById = new Map<string, boolean>();
  for (const [id, info] of catalog.entries()) {
    nameById.set(id, info.name);
    if (info.param) paramById.set(id, info.param);
    difficultById.set(id, info.isDifficult);
  }
  return { nameById, paramById, difficultById };
}

function normalizeEffectNames(value: string): string {
  const raw = value.trim();
  if (!raw) return '';
  return raw
    .split(/[,\n;|]+/g)
    .map((x) => x.trim())
    .filter(Boolean)
    .join(', ');
}

export function mapCharacterJsonToPage1Vm(
  characterJson: unknown,
  deps: {
    lang: string;
    i18n: CharacterPdfPage1I18n;
    skillsCatalog?: ReadonlyMap<string, SkillCatalogInfo>;
    weaponDetailsById?: ReadonlyMap<string, WeaponDetails>;
    armorDetailsById?: ReadonlyMap<string, ArmorDetails>;
    potionDetailsById?: ReadonlyMap<string, PotionDetails>;
  },
): CharacterPdfPage1Vm {
  const lang = deps.lang;
  const i18n = deps.i18n;
  const skillsRoot = asRecord(getFirst(characterJson, ['skills', 'character.skills'])) ?? {};
  const common = asRecord(skillsRoot.common) ?? {};
  const { nameById, paramById, difficultById } = buildSkillCatalogMaps(deps?.skillsCatalog);

  const canonicalSkillId = (skillId: string): string => {
    if (skillId === 'dodge') return 'dodge_escape';
    if (skillId === 'staff') return 'staff_spear';
    return skillId;
  };

  const definingRaw = skillsRoot.defining;
  const definingRec = asRecord(definingRaw);
  const definingId = asString(definingRec?.id) ?? '';
  const definingName = asString(definingRec?.name) ?? (definingId ? nameById.get(definingId) ?? definingId : '');
  const definingValue = definingId ? readSkillValue(common[definingId]) : { cur: null, bonus: null, raceBonus: null };
  const definingText =
    definingName && definingId
      ? `${definingName} ${formatSkillValue(definingValue)}`.trim()
      : definingName
        ? definingName
        : '';

  const base: CharacterPdfPage1Vm['base'] = {
    name: getFirstString(characterJson, ['name', 'characterName', 'fullName']) || i18n.defaults.characterName,
    race: getFirstString(characterJson, ['race']) || '',
    gender: getFirstString(characterJson, ['gender']) || '',
    age: getFirstString(characterJson, ['age']) || '',
    profession: getFirstString(characterJson, ['profession', 'role', 'class', 'career']) || '',
    school: (getFirstString(characterJson, ['characterRaw.school', 'school']) || '').trim() || undefined,
    definingSkill: definingText,
  };

  const statTotal = (id: string): number => {
    const s = readStat(characterJson, id);
    return (s.cur ?? 0) + (s.bonus ?? 0) + (s.raceBonus ?? 0);
  };
  const resolveVal = Math.floor((5 * (statTotal('WILL') + statTotal('INT'))) / 2);
  const resolveText = Number.isFinite(resolveVal) ? String(resolveVal) : '';

  const computed: CharacterPdfPage1Vm['computed'] = {
    run: readCalcCurString(characterJson, 'run'),
    leap: readCalcCurString(characterJson, 'leap'),
    stability: readCalcCurString(characterJson, 'STUN'),
    punch: readCalcCurString(characterJson, 'bonus_punch'),
    kick: readCalcCurString(characterJson, 'bonus_kick'),
    rest: readCalcCurString(characterJson, 'REC'),
    vigor: formatValueWithBonuses(readStat(characterJson, 'vigor')),
  };

  const mainStatOrder: { id: string; label: string }[] = [
    { id: 'INT', label: i18n.stats.abbr.INT },
    { id: 'REF', label: i18n.stats.abbr.REF },
    { id: 'DEX', label: i18n.stats.abbr.DEX },
    { id: 'BODY', label: i18n.stats.abbr.BODY },
    { id: 'SPD', label: i18n.stats.abbr.SPD },
    { id: 'EMP', label: i18n.stats.abbr.EMP },
    { id: 'CRA', label: i18n.stats.abbr.CRA },
    { id: 'WILL', label: i18n.stats.abbr.WILL },
  ];

  const mainStats = mainStatOrder.map(({ id, label }) => ({
    id,
    label,
    ...readStat(characterJson, id),
  }));

  const carryMax = readCalcCurString(characterJson, 'ENC');
  const carried = sumCarriedWeight(characterJson);
  const carriedText = carried === null ? '' : carried.toFixed(1);

  const consumables: CharacterPdfPage1Vm['consumables'] = [
    { id: 'carry', label: i18n.consumables.label.carry, max: carryMax, current: carriedText },
    { id: 'hp', label: i18n.consumables.label.hp, max: readCalcCurString(characterJson, 'max_HP'), current: '' },
    { id: 'sta', label: i18n.consumables.label.sta, max: readCalcCurString(characterJson, 'STA'), current: '' },
    { id: 'resolve', label: i18n.consumables.label.resolve, max: resolveText, current: '' },
    { id: 'luck', label: i18n.consumables.label.luck, max: asString(asRecord(getPath(characterJson, 'statistics.LUCK'))?.cur) ?? '', current: '' },
  ];

  const groupLabels: Record<string, string> = {
    INT: i18n.stats.name.INT,
    REF: i18n.stats.name.REF,
    DEX: i18n.stats.name.DEX,
    BODY: i18n.stats.name.BODY,
    SPD: i18n.stats.name.SPD,
    EMP: i18n.stats.name.EMP,
    CRA: i18n.stats.name.CRA,
    WILL: i18n.stats.name.WILL,
    OTHER: i18n.stats.name.OTHER,
  };

  const groups = new Map<string, CharacterPdfPage1Vm['skillGroups'][number]>();
  const ensureGroup = (statId: string) => {
    const id = (statId || 'OTHER').toUpperCase();
    if (!groups.has(id)) {
      groups.set(id, {
        statId: id,
        statLabel: groupLabels[id] ?? id,
        stat: readStat(characterJson, id),
        skills: [],
      });
    }
    return groups.get(id)!;
  };

  const paramFallbackBySkillId = (skillId: string): string | null => {
    if (skillId === 'staff') return 'REF';
    if (skillId === 'dodge') return 'REF';
    if (skillId === 'sailing') return 'REF';
    if (skillId === 'small_blades') return 'REF';
    if (skillId === 'swordsmanship') return 'REF';
    if (skillId === 'melee') return 'REF';
    if (skillId === 'brawling') return 'REF';
    return null;
  };

  const languageSkillFallback = (skillId: string): { name: string; param: string } | null => {
    if (!skillId.startsWith('language_')) return null;
    const suffix = skillId.slice('language_'.length);
    const map: Record<string, string> = {
      common_speech: i18n.skills.languageCommonSpeech,
      elder_speech: i18n.skills.languageElderSpeech,
      dwarvish: i18n.skills.languageDwarvish,
    };
    const display = map[suffix] ?? suffix.replaceAll('_', ' ');
    return { name: `${i18n.skills.languagePrefix}${display}`, param: 'INT' };
  };

  for (const [skillId, value] of Object.entries(common)) {
    const metaId = canonicalSkillId(skillId);
    const fallback = languageSkillFallback(skillId);
    const name = nameById.get(metaId) ?? fallback?.name ?? skillId;
    const param = paramById.get(metaId) ?? fallback?.param ?? paramFallbackBySkillId(metaId) ?? 'OTHER';
    const group = ensureGroup(param);
    const v = readSkillValue(value);
    group.skills.push({
      id: skillId,
      name,
      cur: v.cur,
      bonus: v.bonus,
      raceBonus: v.raceBonus,
      isDifficult: difficultById.get(metaId) ?? false,
    });
  }

  const groupOrder = ['INT', 'REF', 'DEX', 'BODY', 'SPD', 'EMP', 'CRA', 'WILL', 'OTHER'];
  const skillGroups = groupOrder
    .map((id) => groups.get(id))
    .filter((g): g is NonNullable<typeof g> => Boolean(g))
    .map((g) => {
      const locale = lang.toLowerCase().startsWith('ru') ? 'ru' : 'en';
      g.skills.sort((a, b) => a.name.localeCompare(b.name, locale));
      return g;
    });

  const prof = asRecord(skillsRoot.professional);
  const branchTitles = Array.isArray(prof?.branches)
    ? (prof?.branches as unknown[]).map((x) => asString(x) ?? '').filter(Boolean)
    : [];
  const colors: Array<'blue' | 'green' | 'red'> = ['blue', 'green', 'red'];
  const abbrByParam: Record<string, string> = {
    INT: i18n.stats.abbr.INT,
    REF: i18n.stats.abbr.REF,
    DEX: i18n.stats.abbr.DEX,
    BODY: i18n.stats.abbr.BODY,
    SPD: i18n.stats.abbr.SPD,
    EMP: i18n.stats.abbr.EMP,
    CRA: i18n.stats.abbr.CRA,
    WILL: i18n.stats.abbr.WILL,
  };
  const paramToAbbr = (param: string | null | undefined): string => {
    const p = (param ?? '').toUpperCase();
    return abbrByParam[p] ?? '';
  };
  const branches: CharacterPdfPage1Vm['professional']['branches'] = colors.map((color, index) => {
    const title =
      branchTitles[index] ?? i18n.defaults.branchTitle.replace('{n}', String(index + 1));
    const skills: { id: string; name: string; paramAbbr: string }[] = [];
    for (let slot = 1; slot <= 3; slot += 1) {
      const key = `skill_${index + 1}_${slot}`;
      const item = prof ? prof[key] : undefined;
      const rec = asRecord(item);
      const id = asString(rec?.id) ?? '';
      const name = asString(rec?.name) ?? (id ? (nameById.get(id) ?? id) : '');
      const param = id ? deps?.skillsCatalog?.get(id)?.param ?? null : null;
      const paramAbbr = paramToAbbr(param);
      if (id || name) skills.push({ id: id || name, name: name || id, paramAbbr });
    }
    return { title, color, skills };
  });

  const perksRaw = Array.isArray(getFirst(characterJson, ['perks', 'characterRaw.perks']))
    ? (getFirst(characterJson, ['perks', 'characterRaw.perks']) as unknown[])
    : [];
  const perks: CharacterPdfPage1Vm['perks'] = perksRaw
    .filter((p): p is string => typeof p === 'string')
    .map((s) => {
      const idx = s.indexOf(':');
      const perk = idx >= 0 ? s.slice(0, idx).trim() : s.trim();
      const effect = idx >= 0 ? s.slice(idx + 1).trim() : '';
      return { perk, effect };
    })
    .filter((p) => p.perk || p.effect);

  const gearRoot = asRecord(getFirst(characterJson, ['gear', 'character.gear'])) ?? {};
  const weaponsRaw = Array.isArray(gearRoot.weapons) ? (gearRoot.weapons as unknown[]) : [];
  const armorsRaw = Array.isArray(gearRoot.armors) ? (gearRoot.armors as unknown[]) : [];
  const potionsRaw = Array.isArray(gearRoot.potions) ? (gearRoot.potions as unknown[]) : [];

  const weapons: CharacterPdfPage1Vm['equipment']['weapons'] = weaponsRaw
    .map((w) => {
      const rec = asRecord(w);
      if (!rec) return null;
      const id = asString(rec.w_id) ?? '';
      if (!id) return null;
      const d = deps?.weaponDetailsById?.get(id);
      const qtyRaw = asNumber(rec.amount) ?? asNumber(rec.qty) ?? asNumber(rec.quantity);
      const qty = qtyRaw !== null ? String(qtyRaw) : '';
      const enhRaw = asNumber(rec.enhancements);
      const enhancements = enhRaw !== null ? String(enhRaw) : '';
      return {
        id,
        qty,
        name: (d?.weapon_name ?? asString(rec.weapon_name) ?? id) || id,
        effects: normalizeEffectNames(d?.effect_names ?? asString(rec.effect_names) ?? ''),
        dmg: d?.dmg ?? asString(rec.dmg) ?? '',
        dmgTypes: d?.dmg_types ?? asString(rec.dmg_types) ?? '',
        reliability:
          d?.reliability !== null && d?.reliability !== undefined ? String(d.reliability) : asString(rec.reliability) ?? '',
        hands: d?.hands !== null && d?.hands !== undefined ? String(d.hands) : asString(rec.hands) ?? '',
        concealment: d?.concealment ?? asString(rec.concealment) ?? '',
        enhancements,
        weight: d?.weight ?? asString(rec.weight) ?? '',
        price: d?.price !== null && d?.price !== undefined ? String(d.price) : asString(rec.price) ?? '',
      };
    })
    .filter((x): x is NonNullable<typeof x> => Boolean(x));

  const armors: CharacterPdfPage1Vm['equipment']['armors'] = armorsRaw
    .map((a) => {
      const rec = asRecord(a);
      if (!rec) return null;
      const id = asString(rec.a_id) ?? '';
      if (!id) return null;
      const d = deps?.armorDetailsById?.get(id);
      const qtyRaw = asNumber(rec.amount) ?? asNumber(rec.qty) ?? asNumber(rec.quantity);
      const qty = qtyRaw !== null ? String(qtyRaw) : '';
      const enhRaw = d?.enhancements !== null && d?.enhancements !== undefined ? d.enhancements : asNumber(rec.enhancements);
      const enhancements = enhRaw !== null && enhRaw !== undefined ? String(enhRaw) : '';
      const price = d?.price !== null && d?.price !== undefined ? String(d.price) : asString(rec.price) ?? '';
      return {
        id,
        qty,
        name: (d?.armor_name ?? asString(rec.armor_name) ?? id) || id,
        effects: normalizeEffectNames(d?.effect_names ?? asString(rec.effect_names) ?? ''),
        sp:
          d?.stopping_power !== null && d?.stopping_power !== undefined
            ? String(d.stopping_power)
            : asString(rec.stopping_power) ?? '',
        enc:
          d?.encumbrance !== null && d?.encumbrance !== undefined ? String(d.encumbrance) : asString(rec.encumbrance) ?? '',
        enhancements,
        weight: d?.weight ?? asString(rec.weight) ?? '',
        price,
      };
    })
    .filter((x): x is NonNullable<typeof x> => Boolean(x));

  const potions: CharacterPdfPage1Vm['equipment']['potions'] = potionsRaw
    .map((p) => {
      const rec = asRecord(p);
      if (!rec) return null;
      const id = asString(rec.p_id) ?? '';
      if (!id) return null;
      const d = deps?.potionDetailsById?.get(id);
      const qtyRaw = asNumber(rec.amount) ?? asNumber(rec.qty) ?? asNumber(rec.quantity);
      const qty = qtyRaw !== null ? String(qtyRaw) : '';
      return {
        id,
        qty,
        name: (d?.potion_name ?? asString(rec.potion_name) ?? id) || id,
        toxicity: d?.toxicity ?? asString(rec.toxicity) ?? '',
        duration: d?.time_effect ?? asString(rec.time_effect) ?? '',
        effect: d?.effect ?? asString(rec.effect) ?? '',
        weight: d?.weight ?? asString(rec.weight) ?? '',
        price: d?.price !== null && d?.price !== undefined ? String(d.price) : asString(rec.price) ?? '',
      };
    })
    .filter((x): x is NonNullable<typeof x> => Boolean(x));

  // Read magic items
  const magicRoot = asRecord(getFirst(characterJson, ['gear', 'character.gear'])) ?? {};
  const magicRec = asRecord(magicRoot.magic) ?? {};
  
  // Check if we should show magic table: 
  // Don't show if Vigor = 0 AND gear.magic is empty
  const vigorStat = readStat(characterJson, 'vigor');
  const hasVigor = (vigorStat.cur ?? 0) !== 0 || (vigorStat.bonus ?? 0) !== 0 || (vigorStat.raceBonus ?? 0) !== 0;
  const hasMagic = magicRec && Object.keys(magicRec).length > 0;
  const shouldShowMagic = hasVigor || hasMagic;
  
  const magicItems: CharacterPdfPage1Vm['equipment']['magic'] = [];
  
  if (shouldShowMagic) {
    // Read spells
    const spellsRaw = Array.isArray(magicRec.spells) ? (magicRec.spells as unknown[]) : [];
    spellsRaw.forEach((s) => {
      const rec = asRecord(s);
      if (!rec) return;
      const typeRaw = (asString(rec.type) ?? '').toLowerCase();
      const name = asString(rec.name) ?? asString(rec.spell_name) ?? '';
      if (!name) return;
      magicItems.push({
        type: typeRaw === 'sign' ? i18n.magicType.sign : i18n.magicType.spell,
        name,
        element: asString(rec.element) ?? '',
        staminaCast: asString(rec.stamina_cast) ?? '',
        staminaKeeping: asString(rec.stamina_keeping) ?? '',
        damage: asString(rec.damage) ?? '',
        effectTime: asString(rec.effect_time) ?? '',
        distance: asString(rec.distance) ?? '',
        zoneSize: asString(rec.zone_size) ?? '',
        form: asString(rec.form) ?? '',
      });
    });
    
    // Read signs
    const signsRaw = Array.isArray(magicRec.signs) ? (magicRec.signs as unknown[]) : [];
    signsRaw.forEach((s) => {
      const rec = asRecord(s);
      if (!rec) return;
      const name = asString(rec.name) ?? asString(rec.spell_name) ?? '';
      if (!name) return;
      magicItems.push({
        type: i18n.magicType.sign,
        name,
        element: asString(rec.element) ?? '',
        staminaCast: asString(rec.stamina_cast) ?? '',
        staminaKeeping: asString(rec.stamina_keeping) ?? '',
        damage: asString(rec.damage) ?? '',
        effectTime: asString(rec.effect_time) ?? '',
        distance: asString(rec.distance) ?? '',
        zoneSize: asString(rec.zone_size) ?? '',
        form: asString(rec.form) ?? '',
      });
    });
    
    // Read invocations
    const invocationsRec = asRecord(magicRec.invocations) ?? {};
    const druidRaw = Array.isArray(invocationsRec.druid) ? (invocationsRec.druid as unknown[]) : [];
    const priestRaw = Array.isArray(invocationsRec.priest) ? (invocationsRec.priest as unknown[]) : [];
    
    [...druidRaw, ...priestRaw].forEach((i) => {
      const rec = asRecord(i);
      if (!rec) return;
      const name = asString(rec.name) ?? asString(rec.invocation_name) ?? '';
      if (!name) return;
      magicItems.push({
        type: i18n.magicType.invocation,
        name,
        element: asString(rec.cult_or_circle) ?? '',
        staminaCast: asString(rec.stamina_cast) ?? '',
        staminaKeeping: asString(rec.stamina_keeping) ?? '',
        damage: asString(rec.damage) ?? '',
        effectTime: asString(rec.effect_time) ?? '',
        distance: asString(rec.distance) ?? '',
        zoneSize: asString(rec.zone_size) ?? '',
        form: asString(rec.form) ?? '',
      });
    });
  }

  return {
    i18n,
    base,
    computed,
    mainStats,
    consumables,
    avatar: { dataUrl: getFirstString(characterJson, ['avatarDataUrl', 'avatar.dataUrl']) || null },
    skillGroups,
    professional: { branches },
    perks,
    equipment: { weapons, armors, potions, magic: magicItems },
  };
}
