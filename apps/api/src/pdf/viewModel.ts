export type SkillCatalogInfo = {
  name: string;
  param: string | null;
  isDifficult: boolean;
};

export type CharacterPdfPage1Vm = {
  base: {
    name: string;
    race: string;
    gender: string;
    age: string;
    profession: string;
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

function readCalcCurString(characterJson: unknown, key: string): string {
  const calc = asRecord(getPath(characterJson, 'statistics.calculated')) ?? {};
  const rec = asRecord(calc[key]);
  return asString(rec?.cur) ?? '';
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

export function mapCharacterJsonToPage1Vm(
  characterJson: unknown,
  deps?: { skillsCatalog?: ReadonlyMap<string, SkillCatalogInfo> },
): CharacterPdfPage1Vm {
  const skillsRoot = asRecord(getFirst(characterJson, ['skills', 'character.skills'])) ?? {};
  const common = asRecord(skillsRoot.common) ?? {};
  const { nameById, paramById, difficultById } = buildSkillCatalogMaps(deps?.skillsCatalog);

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

  const base = {
    name: getFirstString(characterJson, ['name', 'characterName', 'fullName']) || 'Персонаж',
    race: getFirstString(characterJson, ['race']) || '',
    gender: getFirstString(characterJson, ['gender']) || '',
    age: getFirstString(characterJson, ['age']) || '',
    profession: getFirstString(characterJson, ['profession', 'role', 'class', 'career']) || '',
    definingSkill: definingText,
  };

  const computed = {
    run: readCalcCurString(characterJson, 'run'),
    leap: readCalcCurString(characterJson, 'leap'),
    stability: readCalcCurString(characterJson, 'STUN'),
    punch: readCalcCurString(characterJson, 'bonus_punch'),
    kick: readCalcCurString(characterJson, 'bonus_kick'),
    rest: readCalcCurString(characterJson, 'REC'),
    vigor: asString(asRecord(getPath(characterJson, 'statistics.vigor'))?.cur) ?? '',
  };

  const mainStatOrder: { id: string; label: string }[] = [
    { id: 'INT', label: 'ИНТ' },
    { id: 'REF', label: 'РЕФ' },
    { id: 'DEX', label: 'ЛОВ' },
    { id: 'BODY', label: 'ТЕЛ' },
    { id: 'SPD', label: 'СКР' },
    { id: 'EMP', label: 'ЭМП' },
    { id: 'CRA', label: 'РЕМ' },
    { id: 'WILL', label: 'ВОЛ' },
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
    { id: 'carry', label: 'Переносимый вес', max: carryMax, current: carriedText },
    { id: 'hp', label: 'Здоровье', max: readCalcCurString(characterJson, 'max_HP'), current: '' },
    { id: 'sta', label: 'Выносливость', max: readCalcCurString(characterJson, 'STA'), current: '' },
    { id: 'resolve', label: 'Решимость', max: '', current: '' },
    { id: 'luck', label: 'Удача', max: asString(asRecord(getPath(characterJson, 'statistics.LUCK'))?.cur) ?? '', current: '' },
  ];

  const groupLabels: Record<string, string> = {
    INT: 'Интеллект',
    REF: 'Рефлексы',
    DEX: 'Ловкость',
    BODY: 'Тело',
    SPD: 'Скорость',
    EMP: 'Эмпатия',
    CRA: 'Ремесло',
    WILL: 'Воля',
    LUCK: 'Удача',
    OTHER: 'Прочее',
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
      common_speech: 'Всеобщий',
      elder_speech: 'Старшая речь',
      dwarvish: 'Краснолюдский',
    };
    const display = map[suffix] ?? suffix.replaceAll('_', ' ');
    return { name: `Язык: ${display}`, param: 'INT' };
  };

  for (const [skillId, value] of Object.entries(common)) {
    const fallback = languageSkillFallback(skillId);
    const name = nameById.get(skillId) ?? fallback?.name ?? skillId;
    const param = paramById.get(skillId) ?? fallback?.param ?? paramFallbackBySkillId(skillId) ?? 'OTHER';
    const group = ensureGroup(param);
    const v = readSkillValue(value);
    group.skills.push({
      id: skillId,
      name,
      cur: v.cur,
      bonus: v.bonus,
      raceBonus: v.raceBonus,
      isDifficult: difficultById.get(skillId) ?? false,
    });
  }

  const groupOrder = ['INT', 'REF', 'DEX', 'BODY', 'SPD', 'EMP', 'CRA', 'WILL', 'OTHER'];
  const skillGroups = groupOrder
    .map((id) => groups.get(id))
    .filter((g): g is NonNullable<typeof g> => Boolean(g))
    .map((g) => {
      g.skills.sort((a, b) => a.name.localeCompare(b.name, 'ru'));
      return g;
    });

  const prof = asRecord(skillsRoot.professional);
  const branchTitles = Array.isArray(prof?.branches)
    ? (prof?.branches as unknown[]).map((x) => asString(x) ?? '').filter(Boolean)
    : [];
  const colors: Array<'blue' | 'green' | 'red'> = ['blue', 'green', 'red'];
  const paramToAbbr = (param: string | null | undefined): string => {
    const p = (param ?? '').toUpperCase();
    if (p === 'INT') return 'INT';
    if (p === 'REF') return 'REF';
    if (p === 'DEX') return 'DEX';
    if (p === 'BODY') return 'BODY';
    if (p === 'SPD') return 'SPD';
    if (p === 'EMP') return 'EMP';
    if (p === 'CRA') return 'CRA';
    if (p === 'WILL') return 'WILL';
    return '';
  };
  const branches: CharacterPdfPage1Vm['professional']['branches'] = colors.map((color, index) => {
    const title = branchTitles[index] ?? `Ветка ${index + 1}`;
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

  return {
    base,
    computed,
    mainStats,
    consumables,
    avatar: { dataUrl: getFirstString(characterJson, ['avatarDataUrl', 'avatar.dataUrl']) || null },
    skillGroups,
    professional: { branches },
  };
}
