export type CharacterPdfViewModel = {
  meta: {
    player: string;
    name: string;
    race: string;
    profession: string;
    age: string;
    definingSkill: string;
    homeland: string;
    homeLanguage: string;
  };
  stats: { id: string; label: string; value: number | null }[];
  derived: { id: string; label: string; value: string }[];
  hpMax: number | null;
  staMax: number | null;
  stun: number | null;
  enc: number | null;
  rec: number | null;
  moneyCrowns: number | null;

  reputation: { groupName: string; status: number | null; isFeared: boolean }[];
  characteristics: { label: string; value: string }[];
  values: { label: string; value: string }[];

  perks: string[];
  loreNotes: { label: string; value: string }[];
  lifeEvents: { timePeriod: string; eventType: string; description: string }[];

  skillsByStat: {
    statId: string;
    title: string;
    rows: { id: string; name: string; value: number | null; isInitial: boolean; isDifficult: boolean }[];
  }[];

  professionalBranches: string[];
  professionalAbilities: { id: string; name: string }[];
  initialSkills: { id: string; name: string }[];

  weapons: {
    name: string;
    dmg: string;
    reliability: string;
    hands: string;
    concealment: string;
    weight: string;
  }[];
  armor: { name: string; sp: string; penalty: string; weight: string }[];
  gear: { name: string; qty: string; weight: string; notes: string }[];
  totalWeight: number | null;
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

function getFirstString(root: unknown, paths: string[]): string | null {
  return asString(getFirst(root, paths));
}

type SkillValue = { cur?: unknown; bonus?: unknown; race_bonus?: unknown; is_difficult?: unknown };

const SKILL_STAT_MAP: Record<string, string> = {
  // INT
  awareness: 'INT',
  business: 'INT',
  deduction: 'INT',
  education: 'INT',
  monster_lore: 'INT',
  tactics: 'INT',
  teaching: 'INT',
  wilderness_survival: 'INT',
  language_common_speech: 'INT',
  language_elder_speech: 'INT',
  language_dwarvish: 'INT',
  language_nilfgaardian: 'INT',
  language_skellige: 'INT',
  language_gnomish: 'INT',
  language_halfling: 'INT',
  language_nordling: 'INT',

  // REF
  brawling: 'REF',
  dodge: 'REF',
  melee: 'REF',
  riding: 'REF',
  sailing: 'REF',
  small_blades: 'REF',
  staff: 'REF',
  swordsmanship: 'REF',

  // DEX
  archery: 'DEX',
  athletics: 'DEX',
  crossbow: 'DEX',
  sleight_of_hand: 'DEX',
  stealth: 'DEX',

  // BODY
  endurance: 'BODY',
  physique: 'BODY',
  resistance: 'BODY',

  // EMP
  charisma: 'EMP',
  deceit: 'EMP',
  fine_arts: 'EMP',
  gambling: 'EMP',
  grooming_and_style: 'EMP',
  human_perception: 'EMP',
  leadership: 'EMP',
  persuasion: 'EMP',
  performance: 'EMP',
  seduction: 'EMP',
  social_etiquette: 'EMP',
  streetwise: 'EMP',

  // CRA
  alchemy: 'CRA',
  craft: 'CRA',
  disguise: 'CRA',
  first_aid: 'CRA',
  forgery: 'CRA',
  pick_lock: 'CRA',
  trap_craft: 'CRA',

  // WILL (magic)
  courage: 'WILL',
  hex_weaving: 'WILL',
  ritual_crafting: 'WILL',
  resist_magic: 'WILL',
  spell_casting: 'WILL',
  intimation: 'WILL',
};

function getSkillName(skillId: string, skillNameById?: ReadonlyMap<string, string>): string {
  const fromMap = skillNameById?.get(skillId);
  if (fromMap && fromMap.trim().length > 0) return fromMap;
  return skillId;
}

function valueFromSkill(skillValue: SkillValue): { total: number | null; isDifficult: boolean } {
  const cur = asNumber(skillValue.cur) ?? 0;
  const bonus = asNumber(skillValue.bonus) ?? 0;
  const raceBonus = asNumber(skillValue.race_bonus) ?? 0;
  const total = cur + bonus + raceBonus;
  const isDifficult = skillValue.is_difficult === true;
  return { total: Number.isFinite(total) ? total : null, isDifficult };
}

function extractStats(characterJson: unknown): CharacterPdfViewModel['stats'] {
  const statsRoot = getFirst(characterJson, ['statistics', 'stats', 'attributes', 'character.statistics', 'character.stats']);
  const statIds: { id: string; label: string }[] = [
    { id: 'INT', label: 'ИНТ' },
    { id: 'REF', label: 'РЕФ' },
    { id: 'DEX', label: 'ЛОВ' },
    { id: 'BODY', label: 'ТЕЛ' },
    { id: 'SPD', label: 'СКР' },
    { id: 'EMP', label: 'ЭМП' },
    { id: 'CRA', label: 'РЕМ' },
    { id: 'WILL', label: 'ВОЛ' },
    { id: 'LUCK', label: 'УДАЧА' },
    { id: 'vigor', label: 'ВЫН' },
  ];

  const rootRec = asRecord(statsRoot);
  return statIds.map(({ id, label }) => {
    const val = rootRec ? asRecord(rootRec[id]) : null;
    const cur = val ? asNumber(val.cur) : null;
    return { id, label, value: cur };
  });
}

function extractDerived(characterJson: unknown): {
  derived: CharacterPdfViewModel['derived'];
  hpMax: number | null;
  staMax: number | null;
  stun: number | null;
  enc: number | null;
  rec: number | null;
} {
  const calc = getFirst(characterJson, ['statistics.calculated', 'calculated']);
  const calcRec = asRecord(calc) ?? {};

  const readCur = (key: string): string => {
    const rec = asRecord(calcRec[key]);
    const cur = rec ? rec.cur : undefined;
    return asString(cur) ?? '';
  };

  const hpMax = asNumber(asRecord(calcRec.max_HP)?.cur);
  const staMax = asNumber(asRecord(calcRec.STA)?.cur);
  const stun = asNumber(asRecord(calcRec.STUN)?.cur);
  const enc = asNumber(asRecord(calcRec.ENC)?.cur);
  const rec = asNumber(asRecord(calcRec.REC)?.cur);

  const derived: CharacterPdfViewModel['derived'] = [
    { id: 'max_HP', label: 'MAX HP', value: readCur('max_HP') },
    { id: 'STA', label: 'MAX STAM', value: readCur('STA') },
    { id: 'STUN', label: 'STUN', value: readCur('STUN') },
    { id: 'ENC', label: 'ENC', value: readCur('ENC') },
    { id: 'REC', label: 'REC', value: readCur('REC') },
    { id: 'bonus_punch', label: 'Punch', value: readCur('bonus_punch') },
    { id: 'bonus_kick', label: 'Kick', value: readCur('bonus_kick') },
    { id: 'run', label: 'Run', value: readCur('run') },
    { id: 'leap', label: 'Leap', value: readCur('leap') },
  ].filter((row) => row.value.trim().length > 0);

  return { derived, hpMax, staMax, stun, enc, rec };
}

function extractSkillsByStat(
  characterJson: unknown,
  deps?: { skillNameById?: ReadonlyMap<string, string>; skillIsDifficultById?: ReadonlyMap<string, boolean> },
): {
  skillsByStat: CharacterPdfViewModel['skillsByStat'];
  initialSkills: CharacterPdfViewModel['initialSkills'];
  professionalBranches: string[];
  professionalAbilities: CharacterPdfViewModel['professionalAbilities'];
} {
  const skillsRoot = asRecord(getFirst(characterJson, ['skills', 'character.skills'])) ?? {};
  const common = asRecord(skillsRoot.common) ?? {};
  const initialIds = Array.isArray(skillsRoot.initial)
    ? skillsRoot.initial.map((x) => (typeof x === 'string' ? x : '')).filter(Boolean)
    : [];
  const initialSet = new Set(initialIds);

  const professional = asRecord(skillsRoot.professional);
  const professionalBranches = Array.isArray(professional?.branches)
    ? (professional?.branches as unknown[]).map((x) => asString(x) ?? '').filter(Boolean)
    : [];

  const professionalAbilities: CharacterPdfViewModel['professionalAbilities'] = [];
  if (professional) {
    for (const [key, val] of Object.entries(professional)) {
      if (!key.startsWith('skill_')) continue;
      const rec = asRecord(val);
      if (!rec) continue;
      const id = asString(rec.id) ?? '';
      const name = asString(rec.name) ?? (id ? getSkillName(id, deps?.skillNameById) : '');
      if (id || name) {
        professionalAbilities.push({ id: id || name, name: name || id });
      }
    }
  }

  const statOrder: { statId: string; title: string }[] = [
    { statId: 'INT', title: 'Интеллект' },
    { statId: 'REF', title: 'Рефлексы (Реакция)' },
    { statId: 'DEX', title: 'Ловкость' },
    { statId: 'BODY', title: 'Тело' },
    { statId: 'EMP', title: 'Эмпатия' },
    { statId: 'CRA', title: 'Ремесло' },
    { statId: 'WILL', title: 'Воля' },
    { statId: 'OTHER', title: 'Прочее' },
  ];

  const rowsByStat = new Map<string, CharacterPdfViewModel['skillsByStat'][number]['rows']>();
  for (const { statId } of statOrder) rowsByStat.set(statId, []);

  for (const [skillId, value] of Object.entries(common)) {
    const valRec = asRecord(value) as SkillValue | null;
    if (!valRec) continue;
    const { total, isDifficult } = valueFromSkill(valRec);

    const statId = SKILL_STAT_MAP[skillId] ?? 'OTHER';
    const name = getSkillName(skillId, deps?.skillNameById);
    const difficultOverride = deps?.skillIsDifficultById?.get(skillId);
    rowsByStat.get(statId)?.push({
      id: skillId,
      name,
      value: total && total > 0 ? total : null,
      isInitial: initialSet.has(skillId),
      isDifficult: difficultOverride ?? isDifficult,
    });
  }

  const skillsByStat = statOrder.map(({ statId, title }) => {
    const rows = rowsByStat.get(statId) ?? [];
    rows.sort((a, b) => a.name.localeCompare(b.name, 'ru'));
    return { statId, title, rows };
  });

  const initialSkills = initialIds.map((id) => ({ id, name: getSkillName(id, deps?.skillNameById) }));

  return { skillsByStat, initialSkills, professionalBranches, professionalAbilities };
}

/** Flatten gear when it is an object (e.g. { professional: [], weapons: [], magic: { spells: [] } }) into one array. */
function gearToItems(gearValue: unknown): unknown[] {
  if (Array.isArray(gearValue)) return gearValue;
  const rec = asRecord(gearValue);
  if (!rec) return [];
  const out: unknown[] = [];
  for (const v of Object.values(rec)) {
    if (Array.isArray(v)) {
      out.push(...v);
    } else if (v && typeof v === 'object' && !Array.isArray(v)) {
      for (const w of Object.values(v as Record<string, unknown>)) {
        if (Array.isArray(w)) out.push(...w);
      }
    }
  }
  return out;
}

function extractGear(characterJson: unknown): {
  weapons: CharacterPdfViewModel['weapons'];
  armor: CharacterPdfViewModel['armor'];
  gear: CharacterPdfViewModel['gear'];
  totalWeight: number | null;
} {
  const gearArr = getFirst(characterJson, ['gear', 'inventory', 'items', 'character.gear']);
  const items = gearToItems(gearArr);

  const weapons: CharacterPdfViewModel['weapons'] = [];
  const armor: CharacterPdfViewModel['armor'] = [];
  const gear: CharacterPdfViewModel['gear'] = [];
  let totalWeight = 0;

  for (const item of items) {
    const rec = asRecord(item);
    if (!rec) continue;

    const amount = asString(rec.amount) ?? asString(rec.qty) ?? asString(rec.quantity) ?? '1';
    const weight = asString(rec.weight) ?? '';
    const qtyNum = asNumber(amount) ?? 1;
    const weightNum = asNumber(weight) ?? null;

    if (rec.weapon_name || rec.weapon_class || rec.dmg || rec.reliability) {
      weapons.push({
        name: asString(rec.weapon_name) ?? asString(rec.name) ?? '—',
        dmg: asString(rec.dmg) ?? '',
        reliability: asString(rec.reliability) ?? '',
        hands: asString(rec.hands) ?? '',
        concealment: asString(rec.concealment) ?? '',
        weight,
      });
      if (weightNum !== null) totalWeight += weightNum * qtyNum;
      continue;
    }

    if (rec.armor_name || rec.sp || rec.armor_sp) {
      armor.push({
        name: asString(rec.armor_name) ?? asString(rec.name) ?? '—',
        sp: asString(rec.sp) ?? asString(rec.armor_sp) ?? '',
        penalty: asString(rec.penalty) ?? asString(rec.armor_penalty) ?? '',
        weight,
      });
      if (weightNum !== null) totalWeight += weightNum * qtyNum;
      continue;
    }

    const name =
      asString(rec.name) ??
      asString(rec.gear_name) ??
      asString(rec.item_name) ??
      asString(rec.weapon_name) ??
      asString(rec.spell_name) ??
      asString(rec.hex_name) ??
      asString(rec.ritual_name) ??
      asString(rec.invocation_name) ??
      '(item)';
    const notes =
      asString(rec.notes) ?? asString(rec.gear_description) ?? asString(rec.description) ?? asString(rec.desc) ?? '';

    gear.push({ name, qty: amount, weight, notes });
    if (weightNum !== null) totalWeight += weightNum * qtyNum;
  }

  return { weapons, armor, gear, totalWeight: Number.isFinite(totalWeight) && totalWeight > 0 ? totalWeight : null };
}

function extractReputation(characterJson: unknown): CharacterPdfViewModel['reputation'] {
  const value = getFirst(characterJson, ['social_status', 'reputationByRegion', 'character.social_status']);
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => {
      const rec = asRecord(item);
      if (!rec) return null;
      return {
        groupName: asString(rec.group_name) ?? asString(rec.name) ?? '—',
        status: asNumber(rec.group_status),
        isFeared: rec.group_is_feared === true,
      };
    })
    .filter((x): x is NonNullable<typeof x> => Boolean(x));
}

function extractCharacteristics(characterJson: unknown): {
  characteristics: CharacterPdfViewModel['characteristics'];
  values: CharacterPdfViewModel['values'];
} {
  const lore = asRecord(getFirst(characterJson, ['lore', 'character.lore'])) ?? {};
  const style = asRecord(lore.style) ?? {};
  const values = asRecord(lore.values) ?? {};

  const characteristics: CharacterPdfViewModel['characteristics'] = [
    { label: 'Возраст', value: getFirstString(characterJson, ['age']) ?? '' },
    { label: 'Одежда', value: asString(style.clothing) ?? '' },
    { label: 'Личность', value: asString(style.personality) ?? '' },
    { label: 'Причёска', value: asString(style.hair_style) ?? '' },
    { label: 'Влечения', value: asString(style.affectations) ?? '' },
  ].filter((row) => row.value.trim().length > 0);

  const valuesList: CharacterPdfViewModel['values'] = [
    { label: 'Важные люди', value: asString(values.valued_person) ?? '' },
    { label: 'Ценности', value: asString(values.value) ?? '' },
    { label: 'Чувства', value: asString(values.feelings_on_people) ?? '' },
  ].filter((row) => row.value.trim().length > 0);

  return { characteristics, values: valuesList };
}

function extractLoreNotes(characterJson: unknown): CharacterPdfViewModel['loreNotes'] {
  const lore = asRecord(getFirst(characterJson, ['lore', 'character.lore'])) ?? {};
  const siblings = Array.isArray(lore.siblings) ? lore.siblings : [];

  return [
    { label: 'Родина', value: asString(lore.homeland) ?? '' },
    { label: 'Родной язык', value: asString(lore.home_language) ?? '' },
    { label: 'Статус семьи', value: asString(lore.family_status) ?? '' },
    { label: 'Судьба родителей', value: asString(lore.parents_fate) ?? '' },
    { label: 'Друг', value: asString(lore.friend) ?? '' },
    {
      label: 'Сиблинги',
      value:
        siblings.length > 0
          ? siblings
              .map((s) => {
                const r = asRecord(s) ?? {};
                const parts = [asString(r.gender), asString(r.age), asString(r.attitude), asString(r.personality)].filter(
                  (x): x is string => Boolean(x && x.trim().length > 0),
                );
                return parts.join(', ');
              })
              .filter(Boolean)
              .join(' • ')
          : '',
    },
  ].filter((row) => row.value.trim().length > 0);
}

function extractLifeEvents(characterJson: unknown): CharacterPdfViewModel['lifeEvents'] {
  const lore = asRecord(getFirst(characterJson, ['lore', 'character.lore'])) ?? {};
  const events = lore.lifeEvents;
  if (!Array.isArray(events)) return [];
  return events
    .map((e) => {
      const rec = asRecord(e);
      if (!rec) return null;
      return {
        eventType: asString(rec.eventType) ?? '',
        timePeriod: asString(rec.timePeriod) ?? '',
        description: asString(rec.description) ?? '',
      };
    })
    .filter((x): x is NonNullable<typeof x> => Boolean(x));
}

export function mapCharacterJsonToViewModel(
  characterJson: unknown,
  deps?: { skillNameById?: ReadonlyMap<string, string>; skillIsDifficultById?: ReadonlyMap<string, boolean> },
): CharacterPdfViewModel {
  const name = getFirstString(characterJson, ['name', 'characterName', 'fullName']) ?? 'Персонаж';
  const profession = getFirstString(characterJson, ['profession', 'role', 'class', 'career']) ?? '';
  const race = getFirstString(characterJson, ['race', 'species', 'ancestry']) ?? '';
  const age = getFirstString(characterJson, ['age']) ?? '';

  const skillsRoot = asRecord(getFirst(characterJson, ['skills', 'character.skills'])) ?? {};
  const definingRaw = skillsRoot.defining;
  const definingId =
    typeof definingRaw === 'string'
      ? definingRaw
      : asString(asRecord(definingRaw)?.id) ?? asString(asRecord(definingRaw)?.skill) ?? null;

  const meta: CharacterPdfViewModel['meta'] = {
    player: getFirstString(characterJson, ['player', 'playerName']) ?? '',
    name,
    race,
    profession,
    age: age ? String(age) : '',
    definingSkill: definingId ? getSkillName(definingId, deps?.skillNameById) : '',
    homeland: getFirstString(characterJson, ['lore.homeland']) ?? '',
    homeLanguage: getFirstString(characterJson, ['lore.home_language']) ?? '',
  };

  const moneyCrowns = asNumber(getFirst(characterJson, ['money.crowns', 'money', 'crowns']));

  const stats = extractStats(characterJson);
  const { derived, hpMax, staMax, stun, enc, rec } = extractDerived(characterJson);

  const { skillsByStat, initialSkills, professionalBranches, professionalAbilities } = extractSkillsByStat(characterJson, deps);

  const { weapons, armor, gear, totalWeight } = extractGear(characterJson);

  const reputation = extractReputation(characterJson);
  const { characteristics, values } = extractCharacteristics(characterJson);

  const perksValue = getFirst(characterJson, ['perks', 'advantages', 'traits', 'character.perks']);
  const perks = Array.isArray(perksValue)
    ? perksValue.map((x) => asString(x) ?? '').filter((x) => x.trim().length > 0)
    : [];

  const loreNotes = extractLoreNotes(characterJson);
  const lifeEvents = extractLifeEvents(characterJson);

  return {
    meta,
    stats,
    derived,
    hpMax,
    staMax,
    stun,
    enc,
    rec,
    moneyCrowns,
    reputation,
    characteristics,
    values,
    perks,
    loreNotes,
    lifeEvents,
    skillsByStat,
    professionalBranches,
    professionalAbilities,
    initialSkills,
    weapons,
    armor,
    gear,
    totalWeight,
  };
}
