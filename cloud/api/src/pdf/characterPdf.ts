import * as fs from 'node:fs';
import * as path from 'node:path';
import PDFDocument from 'pdfkit';

type Lang = 'en' | 'ru';
type Row = { cells: string[] };
type Table = { title: string; columns: string[]; rows: Row[] };
type SkillCatalogLite = { param: string | null; name?: string };
type DefiningDisplay = {
  skillLine: string;
  basis: string;
  cells: {
    skillCur: string;
    skillBonus: string;
    skillRaceBonus: string;
    basis: string;
  };
};
type ValueCells = { cur: string; bonus: string; raceBonus: string; final: string };
type SkillSidebarRow = { name: string; cells: ValueCells };
type SkillSidebarGroup = { statId: string; title: string; statCells: ValueCells; rows: SkillSidebarRow[] };
type ProfBranchRow = { name: string; paramAbbr: string };
type ProfBranch = { title: string; color: 'blue' | 'mint' | 'rose'; rows: ProfBranchRow[] };

const COLORS = {
  page: '#ffffff',
  line: '#1f2d3a',
  text: '#111111',
  muted: '#616161',
  blue: '#dbe6f3',
  sand: '#efe8da',
  mint: '#e1eee8',
  rose: '#f1e1e1',
  zebra: '#f5f5f5',
};

const FONTS = { regular: 'WccNotoSans', bold: 'WccNotoSansBold' } as const;
const PAGE = { margin: 20, gap: 8, headerH: 16 };

const SKILL_TO_STAT: Record<string, string> = {
  awareness: 'INT', business: 'INT', deduction: 'INT', education: 'INT', monster_lore: 'INT', tactics: 'INT', streetwise: 'INT',
  language_common_speech: 'INT', language_elder_speech: 'INT', language_dwarvish: 'INT', wilderness_survival: 'INT',
  brawling: 'REF', dodge: 'REF', melee: 'REF', riding: 'REF', sailing: 'REF', small_blades: 'REF', staff: 'REF', swordsmanship: 'REF',
  archery: 'DEX', athletics: 'DEX', crossbow: 'DEX', sleight_of_hand: 'DEX', stealth: 'DEX',
  endurance: 'BODY', physique: 'BODY',
  charisma: 'EMP', deceit: 'EMP', fine_arts: 'EMP', gambling: 'EMP', grooming_and_style: 'EMP', human_perception: 'EMP', leadership: 'EMP', persuasion: 'EMP', performance: 'EMP', seduction: 'EMP',
  alchemy: 'CRA', crafting: 'CRA', disguise: 'CRA', first_aid: 'CRA', forgery: 'CRA', pick_lock: 'CRA', trap_crafting: 'CRA',
  courage: 'WILL', hex_weaving: 'WILL', intimidation: 'WILL', spell_casting: 'WILL', resist_magic: 'WILL', resist_coercion: 'WILL', ritual_crafting: 'WILL',
};

function tr(lang: Lang) {
  return {
    title: lang === 'ru' ? 'Лист персонажа' : 'Character Sheet',
    subtitle: lang === 'ru' ? 'Таверна "Сало и Огурчики" — облачный экспорт' : 'The Pickles and Lard Tavern — cloud export',
    top: {
      base: lang === 'ru' ? 'БАЗОВЫЕ ДАННЫЕ' : 'BASE DATA',
      main: lang === 'ru' ? 'ОСНОВНЫЕ ПАРАМЕТРЫ' : 'MAIN STATS',
      extra: lang === 'ru' ? 'ДОП. ПАРАМЕТРЫ' : 'EXTRA STATS',
      cons: lang === 'ru' ? 'РАСХОДУЕМЫЕ' : 'CONSUMABLES',
      avatar: lang === 'ru' ? 'АВАТАР' : 'AVATAR',
    },
    cols: {
      n: lang === 'ru' ? 'Название' : 'Name',
      v: lang === 'ru' ? 'Знач.' : 'Val',
      b: lang === 'ru' ? 'Бонус' : 'Bonus',
      max: lang === 'ru' ? 'МАКС' : 'MAX',
      cur: lang === 'ru' ? 'ТЕК' : 'CUR',
      qty: '#',
      dmg: lang === 'ru' ? 'Урон' : 'DMG',
      type: lang === 'ru' ? 'Тип' : 'Type',
      rel: lang === 'ru' ? 'Н' : 'Rel',
      hands: lang === 'ru' ? 'ХВАТ' : 'HANDS',
      conceal: lang === 'ru' ? 'СКР' : 'CONC',
      enh: lang === 'ru' ? 'УС' : 'ENH',
      wt: lang === 'ru' ? 'ВЕС' : 'WEIGHT',
      price: lang === 'ru' ? 'ЦЕНА' : 'PRICE',
      sp: lang === 'ru' ? 'ПБ' : 'SP',
      enc: lang === 'ru' ? 'СД' : 'Enc',
      tox: lang === 'ru' ? 'Токс' : 'Tox',
      time: lang === 'ru' ? 'Время' : 'Time',
      effect: lang === 'ru' ? 'Эффект' : 'Effect',
      field: lang === 'ru' ? 'Поле' : 'Field',
      note: lang === 'ru' ? 'Примечание' : 'Note',
    },
    labels: {
      name: lang === 'ru' ? 'Имя' : 'Name',
      race: lang === 'ru' ? 'Раса' : 'Race',
      gender: lang === 'ru' ? 'Пол' : 'Gender',
      age: lang === 'ru' ? 'Возраст' : 'Age',
      profession: lang === 'ru' ? 'Профессия' : 'Profession',
      def: lang === 'ru' ? 'Определяющий навык' : 'Defining skill',
      carry: lang === 'ru' ? 'Переносимый вес' : 'Carry',
      hp: lang === 'ru' ? 'Здоровье' : 'HP',
      sta: lang === 'ru' ? 'Выносливость' : 'STA',
      resolve: lang === 'ru' ? 'Решимость' : 'Resolve',
      luck: lang === 'ru' ? 'Удача' : 'Luck',
      enc: lang === 'ru' ? 'Переносимый вес' : 'Carry',
      rec: lang === 'ru' ? 'Отдых' : 'Recovery',
      stun: lang === 'ru' ? 'Уст.' : 'Stun',
      run: lang === 'ru' ? 'Бег' : 'Run',
      leap: lang === 'ru' ? 'Прыж.' : 'Leap',
      punch: lang === 'ru' ? 'Уд.р.' : 'Punch',
      kick: lang === 'ru' ? 'Уд.н.' : 'Kick',
      vigor: lang === 'ru' ? 'Энергия' : 'Vigor',
    },
    statsAbbr: lang === 'ru'
      ? { INT: 'ИНТ', REF: 'РЕФ', DEX: 'ЛОВ', BODY: 'ТЕЛ', SPD: 'СКР', EMP: 'ЭМП', CRA: 'РЕМ', WILL: 'ВОЛ', LUCK: 'УДА', VIGOR: 'ЭНЕРГИЯ' }
      : { INT: 'INT', REF: 'REF', DEX: 'DEX', BODY: 'BODY', SPD: 'SPD', EMP: 'EMP', CRA: 'CRA', WILL: 'WILL', LUCK: 'LUCK', VIGOR: 'VIGOR' },
    statsFull: lang === 'ru'
      ? { INT: 'ИНТЕЛЛЕКТ', REF: 'РЕФЛЕКСЫ', DEX: 'ЛОВКОСТЬ', BODY: 'ТЕЛО', SPD: 'СКОРОСТЬ', EMP: 'ЭМПАТИЯ', CRA: 'РЕМЕСЛО', WILL: 'ВОЛЯ', OTHER: 'ПРОЧЕЕ' }
      : { INT: 'INTELLIGENCE', REF: 'REFLEXES', DEX: 'DEXTERITY', BODY: 'BODY', SPD: 'SPEED', EMP: 'EMPATHY', CRA: 'CRAFT', WILL: 'WILL', OTHER: 'OTHER' },
    baseWord: lang === 'ru' ? 'Основа' : 'Base',
    sections: {
      skills: lang === 'ru' ? 'НАВЫКИ' : 'SKILLS',
      prof: lang === 'ru' ? 'ПРОФЕССИОНАЛЬНЫЕ НАВЫКИ' : 'PROFESSIONAL SKILLS',
      perks: lang === 'ru' ? 'ПЕРКИ' : 'PERKS',
      weapons: lang === 'ru' ? 'ОРУЖИЕ' : 'WEAPONS',
      armor: lang === 'ru' ? 'БРОНЯ' : 'ARMOR',
      alchemy: lang === 'ru' ? 'АЛХИМИЯ' : 'ALCHEMY',
      magic: lang === 'ru' ? 'МАГИЯ' : 'MAGIC',
      lore: lang === 'ru' ? 'ЛОР И БИОГРАФИЯ' : 'LORE & BIOGRAPHY',
      notes: lang === 'ru' ? 'ЗАМЕТКИ' : 'NOTES',
    },
    avatarPlaceholder: lang === 'ru' ? 'Портрет не загружен' : 'Portrait not provided',
  };
}

function asRecord(v: unknown): Record<string, unknown> | null {
  return v && typeof v === 'object' && !Array.isArray(v) ? (v as Record<string, unknown>) : null;
}
function asArray(v: unknown): unknown[] { return Array.isArray(v) ? v : []; }
function num(v: unknown): number | null {
  if (typeof v === 'number' && Number.isFinite(v)) return v;
  if (typeof v === 'string' && v.trim()) { const n = Number(v); return Number.isFinite(n) ? n : null; }
  return null;
}
function text(v: unknown, none = '—'): string {
  if (v == null) return none;
  if (typeof v === 'string') return v.trim() || none;
  if (typeof v === 'number') return Number.isFinite(v) ? String(v) : none;
  if (Array.isArray(v)) return v.map((x) => text(x, '')).filter(Boolean).join(', ') || none;
  const r = asRecord(v);
  if (!r) return none;
  for (const k of ['name', 'label', 'title', 'text', 'value']) {
    if (typeof r[k] === 'string' && (r[k] as string).trim()) return (r[k] as string).trim();
  }
  if (typeof r.i18n_uuid === 'string') return r.i18n_uuid as string;
  return JSON.stringify(r);
}
function pretty(k: string): string {
  return k.replace(/^language_/, 'language ').replace(/_/g, ' ').replace(/\b\w/g, (m) => m.toUpperCase());
}
function stripHtmlTags(s: string): string {
  return s.replace(/<[^>]*>/g, '').trim();
}
function normalizeMinusChars(s: string): string {
  // Normalize minus-like characters to ASCII hyphen-minus, but keep em/en dashes intact.
  return s
    .replace(/\u2212/g, '-') // minus sign
    .replace(/\u2011/g, '-') // non-breaking hyphen
    .replace(/\u2010/g, '-'); // hyphen
}
function normalizeInlineEffects(s: string): string {
  return normalizeMinusChars(stripHtmlTags(s))
    .replace(/\r?\n+/g, ', ')
    .replace(/\s*\|\s*/g, ', ')
    .replace(/\s*;\s*/g, ', ')
    .replace(/\s*,\s*/g, ', ')
    .replace(/,\s*,+/g, ', ')
    .replace(/\s{2,}/g, ' ')
    .trim();
}
function calcDerivedDiceFromBody(bodyCur: number, kind: 'punch' | 'kick'): string {
  const mod = kind === 'punch'
    ? 2 * Math.trunc((bodyCur - 1) / 2) - 4
    : 2 * Math.trunc((bodyCur - 1) / 2);
  if (mod === 0) return '1d6';
  return mod > 0 ? `1d6+${mod}` : `1d6${mod}`;
}
function statValue(r: Record<string, unknown> | null): { cur: string; bonus: string; full: string } {
  const rec = r ?? {};
  const cur = num(rec.cur ?? rec.value ?? rec.total);
  const b1 = num(rec.bonus ?? rec.mod);
  const b2 = num(rec.race_bonus);
  const bonusParts = [b1, b2].filter((x): x is number => x != null && x !== 0).map((x) => (x > 0 ? `+${x}` : String(x)));
  const fullParts = [cur != null ? String(cur) : '', ...bonusParts].filter(Boolean);
  return { cur: cur == null ? '—' : String(cur), bonus: bonusParts.join(' ') || '—', full: fullParts.join(' ') || '—' };
}

function fontPaths(): { regular: string; bold: string } {
  const regular = [
    '/var/task/pdf-fonts/NotoSans-Regular.ttf',
    path.join(process.cwd(), 'src', 'pdf', 'fonts', 'NotoSans-Regular.ttf'),
    path.join(process.cwd(), 'cloud', 'api', 'src', 'pdf', 'fonts', 'NotoSans-Regular.ttf'),
  ].find((p) => fs.existsSync(p));
  const bold = [
    '/var/task/pdf-fonts/NotoSans-Bold.ttf',
    path.join(process.cwd(), 'src', 'pdf', 'fonts', 'NotoSans-Bold.ttf'),
    path.join(process.cwd(), 'cloud', 'api', 'src', 'pdf', 'fonts', 'NotoSans-Bold.ttf'),
  ].find((p) => fs.existsSync(p));
  if (!regular || !bold) throw new Error('NotoSans fonts not found for PDF rendering');
  return { regular, bold };
}

function buildVm(resolved: Record<string, unknown>, raw: Record<string, unknown>, lang: Lang) {
  return buildVmWithCatalog(resolved, raw, lang, undefined);
}

function buildVmWithCatalog(
  resolved: Record<string, unknown>,
  raw: Record<string, unknown>,
  lang: Lang,
  skillsCatalogById?: ReadonlyMap<string, SkillCatalogLite>,
) {
  const tx = tr(lang);
  const stats = asRecord(resolved.statistics) ?? {};
  const rawStats = asRecord(raw.statistics) ?? {};
  const calc = asRecord(stats.calculated) ?? {};
  const logic = asRecord(raw.logicFields) ?? asRecord(raw.logic_fields) ?? {};
  const defining = asRecord(asRecord(resolved.skills)?.defining);
  const skillsCommon = asRecord(asRecord(resolved.skills)?.common) ?? {};
  const rawSkillsCommon = asRecord(asRecord(raw.skills)?.common) ?? skillsCommon;
  const definingCalc = calcDefiningDisplay({
    statistics: rawStats,
    skillsCommon: rawSkillsCommon,
    defining,
    statAbbr: tx.statsAbbr,
    skillsCatalogById,
  });

  const baseRows = [
    { label: tx.labels.name, value: text(resolved.name) },
    { label: tx.labels.race, value: text(resolved.race) },
    { label: tx.labels.gender, value: text(resolved.gender) },
    { label: tx.labels.age, value: text(resolved.age) },
    { label: tx.labels.profession, value: text(resolved.profession ?? logic.profession ?? logic.profession_code) },
  ];

  const mainStats = ['INT','REF','DEX','BODY','SPD','EMP','CRA','WILL','LUCK','vigor'].map((k) => {
    const statCells = valueCellsFromStatish(asRecord(rawStats[k] ?? stats[k]));
    const abbr =
      k === 'vigor'
        ? tx.statsAbbr.VIGOR
        : k === 'LUCK'
          ? tx.statsAbbr.LUCK
          : tx.statsAbbr[k as keyof typeof tx.statsAbbr] ?? k.toUpperCase();
    return { cells: [abbr, statCells.cur || '0', statCells.bonus, statCells.raceBonus] };
  });
  const bodyCurForDerived = num(asRecord(stats.BODY)?.cur) ?? 0;
  const extraStats = [
    [tx.labels.run, calc.run], [tx.labels.leap, calc.leap],
    [tx.labels.stun, calc.STUN], [tx.labels.rec, calc.REC],
    [tx.labels.punch, calc.bonus_punch], [tx.labels.kick, calc.bonus_kick],
    [tx.labels.vigor, stats.vigor],
  ].map(([k, v]) => {
    const rec = asRecord(v);
    const curStr = typeof rec?.cur === 'string' ? rec.cur.trim() : '';
    let display = statValue(rec).full;
    if (curStr) {
      display = curStr;
    } else if (k === tx.labels.punch || k === tx.labels.kick) {
      display = calcDerivedDiceFromBody(bodyCurForDerived, k === tx.labels.punch ? 'punch' : 'kick');
    }
    return { cells: [String(k), display] };
  });
  const consRows = [
    [tx.labels.carry, calc.ENC, ''],
    [tx.labels.hp, calc.max_HP, ''],
    [tx.labels.sta, calc.STA, ''],
    [tx.labels.resolve, { cur: calcResolve(stats) }, ''],
    [tx.labels.luck, stats.LUCK, ''],
  ].map(([k, v, cur]) => ({ cells: [String(k), statValue(asRecord(v)).full, String(cur || '')] }));

  const grouped = new Map<string, Row[]>();
  const skillSidebarGrouped = new Map<string, SkillSidebarRow[]>();
  const canonicalSkillId = (skillId: string): string => {
    if (skillId === 'dodge') return 'dodge_escape';
    if (skillId === 'staff') return 'staff_spear';
    return skillId;
  };
  const definingSkillId = typeof defining?.id === 'string' ? defining.id : '';
  const definingSkillCanonicalId = definingSkillId ? canonicalSkillId(definingSkillId) : '';
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
  const languageSkillFallbackName = (id: string): string => {
    if (!id.startsWith('language_')) return '';
    const suffix = id.slice('language_'.length);
    if (lang === 'ru') {
      const map: Record<string, string> = {
        common_speech: 'Язык: Всеобщий',
        elder_speech: 'Язык: Старшая речь',
        dwarvish: 'Язык: Краснолюдский',
      };
      return map[suffix] ?? `Язык: ${suffix.replace(/_/g, ' ')}`;
    }
    const map: Record<string, string> = {
      common_speech: 'Language Common Speech',
      elder_speech: 'Language Elder Speech',
      dwarvish: 'Language Dwarvish',
    };
    return map[suffix] ?? pretty(id);
  };
  for (const [skillId, rawValue] of Object.entries(rawSkillsCommon)) {
    const v = statValue(asRecord(rawValue)).full;
    const metaId = canonicalSkillId(skillId);
    if (skillId === definingSkillId || (definingSkillCanonicalId && metaId === definingSkillCanonicalId)) continue;
    const catalog = skillsCatalogById?.get(metaId) ?? skillsCatalogById?.get(skillId);
    const key = ((catalog?.param?.toUpperCase()) || paramFallbackBySkillId(metaId) || SKILL_TO_STAT[metaId] || SKILL_TO_STAT[skillId] || 'OTHER').toUpperCase();
    const arr = grouped.get(key) ?? [];
    const fallbackLangName = languageSkillFallbackName(skillId);
    const displayName = (catalog?.name?.trim() || text(asRecord(rawValue)?.name, '') || fallbackLangName || pretty(skillId));
    arr.push({ cells: [displayName, v] });
    grouped.set(key, arr);
    const sidebarArr = skillSidebarGrouped.get(key) ?? [];
    sidebarArr.push({
      name: displayName,
      cells: (() => {
        const skillRec = asRecord(rawValue) ?? {};
        const skillCur = num(skillRec.cur) ?? 0;
        const skillBonus = num(skillRec.bonus ?? skillRec.mod) ?? 0;
        const skillRaceBonus = num(skillRec.race_bonus) ?? 0;
        const statRec = asRecord(rawStats[key]) ?? {};
        const statCur = num(statRec.cur) ?? 0;
        const statBonus = num(statRec.bonus ?? statRec.mod) ?? 0;
        const statRaceBonus = num(statRec.race_bonus) ?? 0;
        const base =
          calcStatFinal(statCur, statBonus, statRaceBonus) +
          calcSkillContribution(skillCur, skillBonus, skillRaceBonus);
        const hasOwnContribution = skillCur !== 0 || skillBonus !== 0 || skillRaceBonus !== 0;
        return {
          cur: skillCur === 0 ? '' : String(skillCur),
          bonus: formatSignedVisible(skillBonus),
          raceBonus: formatSignedVisible(skillRaceBonus),
          final: hasOwnContribution ? String(base) : '',
        } satisfies ValueCells;
      })(),
    });
    skillSidebarGrouped.set(key, sidebarArr);
  }
  const skillTables: Table[] = ['INT','REF','DEX','BODY','SPD','EMP','CRA','WILL','OTHER']
    .map((key) => {
      const rows = (grouped.get(key) ?? []).sort((a, b) => (a.cells[0] ?? '').localeCompare(b.cells[0] ?? '', lang === 'ru' ? 'ru' : 'en'));
      if (!rows.length) return null;
      const statLabel = key === 'OTHER' ? 'OTHER' : `${key} ${statValue(asRecord(stats[key])).full}`;
      return { title: statLabel, columns: [tx.cols.n, tx.cols.v], rows };
    })
    .filter((t): t is Table => Boolean(t));

  const prof = asRecord(asRecord(resolved.skills)?.professional) ?? {};
  const branchNames = asArray(prof.branches).map((x) => text(x, '')).filter(Boolean);
  const profRows: Row[] = [];
  for (let b = 1; b <= 3; b += 1) {
    for (let s = 1; s <= 3; s += 1) {
      const rec = asRecord(prof[`skill_${b}_${s}`]);
      const name = text(rec?.name ?? rec?.label ?? rec?.id, '');
      if (name) profRows.push({ cells: [branchNames[b - 1] || `Branch ${b}`, name] });
    }
  }
  const profTable: Table = { title: tx.sections.prof, columns: [lang === 'ru' ? 'Ветка' : 'Branch', tx.cols.n], rows: profRows.length ? profRows : [{ cells: ['—', '—'] }] };
  const profBranches: ProfBranch[] = (['blue', 'mint', 'rose'] as const).map((color, idx) => {
    const rows: ProfBranchRow[] = [];
    for (let slot = 1; slot <= 3; slot += 1) {
      const rec = asRecord(prof[`skill_${idx + 1}_${slot}`]);
      const id = typeof rec?.id === 'string' ? rec.id : '';
      const catalog = id ? skillsCatalogById?.get(id) : undefined;
      const name = text(rec?.name ?? rec?.label ?? catalog?.name ?? rec?.id, '');
      const paramId = (catalog?.param || (typeof rec?.param === 'string' ? rec.param : '') || '').toUpperCase();
      const paramAbbr = (tx.statsAbbr as Record<string, string>)[paramId] ?? '';
      if (name) rows.push({ name, paramAbbr });
    }
    return {
      title: branchNames[idx] || `${lang === 'ru' ? 'Ветка' : 'Branch'} ${idx + 1}`,
      color,
      rows,
    };
  });

  const skillSidebarGroups: SkillSidebarGroup[] = ['INT','REF','DEX','BODY','SPD','EMP','CRA','WILL','OTHER']
    .map((id) => {
      const rows = (skillSidebarGrouped.get(id) ?? []).sort((a, b) => a.name.localeCompare(b.name, lang === 'ru' ? 'ru' : 'en'));
      if (!rows.length) return null;
      const statCells = id === 'OTHER'
        ? { cur: '', bonus: '', raceBonus: '', final: '' }
        : valueCellsFromStatish(asRecord(rawStats[id]));
      const full = (tx.statsFull as Record<string, string>)[id] ?? id;
      return { statId: id, title: full, statCells, rows } satisfies SkillSidebarGroup;
    })
    .filter((g): g is SkillSidebarGroup => Boolean(g));

  const perksTable: Table = {
    title: tx.sections.perks,
    columns: [tx.cols.n, tx.cols.effect],
    rows: asArray(resolved.perks).map((p) => {
      const s = text(p, '');
      const i = s.indexOf(':');
      return i >= 0 ? { cells: [s.slice(0, i).trim(), s.slice(i + 1).trim()] } : { cells: [s || '—', ''] };
    }),
  };
  if (!perksTable.rows.length) perksTable.rows.push({ cells: ['—', '—'] });

  const gear = asRecord(resolved.gear) ?? {};
  const makeItemName = (rec: Record<string, unknown>) => text(rec.name ?? rec.weapon_name ?? rec.armor_name ?? rec.potion_name ?? rec.spell_name ?? rec.invocation_name ?? rec.gift_name ?? rec.w_id ?? rec.a_id ?? rec.p_id);
  const weapons = asArray(gear.weapons).map((x) => asRecord(x) ?? {}).map((r) => ({
    cells: [
      text(r.amount ?? r.qty ?? r.quantity, ''),
      makeItemName(r),
      text(r.dmg),
      text(r.dmg_types ?? r.type),
      text(r.reliability),
      text(r.hands),
      text(r.concealment ?? r.conceal),
      text(r.enhancements ?? r.enhancement ?? r.upgrades),
      text(r.weight),
      text(r.price),
      text(r.effect_names ?? r.effect ?? r.note ?? r.special, ''),
    ],
  }));
  const armors = asArray(gear.armors).map((x) => asRecord(x) ?? {}).map((r) => ({
    cells: [
      text(r.amount ?? r.qty ?? r.quantity, ''),
      makeItemName(r),
      text(r.stopping_power ?? r.sp),
      text(r.encumbrance ?? r.enc),
      text(r.enhancements ?? r.enhancement ?? r.upgrades),
      text(r.weight),
      text(r.price),
      text(r.effect_names ?? r.effect ?? r.note ?? r.special, ''),
    ],
  }));
  const potions = asArray(gear.potions).map((x) => asRecord(x) ?? {}).map((r) => ({ cells: [text(r.amount ?? r.qty ?? r.quantity, ''), makeItemName(r), text(r.toxicity), text(r.time_effect ?? r.duration), text(r.effect), text(r.weight), text(r.price)] }));

  const magic = asRecord(gear.magic);
  const magicRows: Row[] = [];
  const pushMagic = (list: unknown[], typeLabel: string) => list.forEach((x) => {
    const r = asRecord(x) ?? {};
    magicRows.push({ cells: [typeLabel, makeItemName(r), text(r.element ?? r.cult_or_circle), text(r.stamina_cast ?? r.vigor_cost ?? r.cost), text(r.effect_time ?? r.duration), text(r.distance ?? r.range), text(r.damage), text(r.form ?? r.note)] });
  });
  if (magic) {
    pushMagic(asArray(magic.signs), lang === 'ru' ? 'Знак' : 'Sign');
    pushMagic(asArray(magic.spells), lang === 'ru' ? 'Закл.' : 'Spell');
    pushMagic(asArray(magic.gifts), lang === 'ru' ? 'Дар' : 'Gift');
    pushMagic(asArray(magic.hexes), lang === 'ru' ? 'Прокл.' : 'Hex');
    pushMagic(asArray(magic.rituals), lang === 'ru' ? 'Ритуал' : 'Ritual');
    const inv = asRecord(magic.invocations);
    pushMagic(asArray(inv?.druid), lang === 'ru' ? 'Друид' : 'Druid');
    pushMagic(asArray(inv?.priest), lang === 'ru' ? 'Жрец' : 'Priest');
  }

  const lore = asRecord(resolved.lore);
  const loreRows: Row[] = [];
  const addLore = (label: string, v: unknown) => { const s = text(v, ''); if (s) loreRows.push({ cells: [label, s] }); };
  if (lore) {
    addLore(lang === 'ru' ? 'Родина' : 'Homeland', lore.homeland);
    addLore(lang === 'ru' ? 'Семья' : 'Family', lore.family_fate);
    addLore(lang === 'ru' ? 'Родители' : 'Parents', lore.parents_fate);
    addLore(lang === 'ru' ? 'Друг' : 'Friend', lore.friend);
  }
  const joinArr = (label: string, v: unknown) => { const arr = asArray(v).map((x) => text(x, '')).filter(Boolean); if (arr.length) loreRows.push({ cells: [label, arr.join(' | ')] }); };
  joinArr(lang === 'ru' ? 'Союзники' : 'Allies', resolved.allies);
  joinArr(lang === 'ru' ? 'Соц. статус' : 'Social status', resolved.social_status);

  return {
    lang, tx, title: tx.title, subtitle: tx.subtitle, baseRows, mainStats, extraStats, consRows, skillTables, profTable, perksTable,
    definingSkillLine: definingCalc.skillLine,
    definingCells: definingCalc.cells,
    definingBasis: definingCalc.basis,
    skillSidebarGroups,
    profBranches,
    weaponsTable: weapons.length ? { title: tx.sections.weapons, columns: [' ', tx.cols.qty, tx.sections.weapons, tx.cols.dmg, tx.cols.type, tx.cols.rel, tx.cols.hands, tx.cols.conceal, tx.cols.enh, tx.cols.wt, tx.cols.price], rows: weapons } : null,
    armorTable: armors.length ? { title: tx.sections.armor, columns: [' ', tx.cols.qty, tx.sections.armor, lang === 'ru' ? 'ПБ/Н' : 'SP', tx.cols.enc, lang === 'ru' ? 'УБ' : 'ENH', tx.cols.wt, tx.cols.price], rows: armors } : null,
    potionTable: potions.length ? { title: tx.sections.alchemy, columns: [tx.cols.qty, tx.cols.n, tx.cols.tox, tx.cols.time, tx.cols.effect, tx.cols.wt, tx.cols.price], rows: potions } : null,
    magicTable: magicRows.length ? { title: tx.sections.magic, columns: [tx.cols.type, tx.cols.n, 'Elem', 'Cost', tx.cols.time, 'Dist', tx.cols.dmg, tx.cols.note], rows: magicRows } : null,
    loreTable: loreRows.length ? { title: tx.sections.lore, columns: [tx.cols.field, tx.cols.note], rows: loreRows } : null,
  };
}

function calcResolve(stats: Record<string, unknown>): string {
  const w = num(asRecord(stats.WILL)?.cur) ?? 0;
  const i = num(asRecord(stats.INT)?.cur) ?? 0;
  return String(Math.floor((5 * (w + i)) / 2));
}

function calcDefiningBase(params: {
  statistics: Record<string, unknown>;
  skillsCommon: Record<string, unknown>;
  defining: Record<string, unknown> | null;
  statAbbr: Record<string, string>;
  baseWord: string;
  skillsCatalogById?: ReadonlyMap<string, SkillCatalogLite>;
}): { skillLine: string; rightLine: string; basis: string } {
  const { statistics, skillsCommon, defining } = params;
  if (!defining) return { skillLine: '—', rightLine: '', basis: '' };
  const skillId = typeof defining.id === 'string' ? defining.id : '';
  const skillName = text(defining.name ?? defining.label ?? defining.id, '—');
  const skillRec = asRecord(skillId ? skillsCommon[skillId] : null) ?? {};
  const catalogParam = params.skillsCatalogById?.get(skillId)?.param ?? null;
  const normalizedParam =
    typeof catalogParam === 'string' && catalogParam.trim()
      ? catalogParam.trim().toUpperCase()
      : skillId.startsWith('language_')
        ? 'INT'
        : (SKILL_TO_STAT[skillId] ?? '').toUpperCase();
  const statId = normalizedParam;
  const statRec = asRecord(statId ? statistics[statId] : null) ?? {};
  const skillVal = statValue(skillRec).full;
  if (!statId) return { skillLine: `${skillName} ${skillVal}`.trim(), rightLine: '', basis: '' };

  const statCur = num(statRec.cur) ?? 0;
  const statBonus = num(statRec.bonus ?? statRec.mod) ?? 0;
  const statRaceBonus = num(statRec.race_bonus) ?? 0;
  const skillCur = num(skillRec.cur) ?? 0;
  const skillBonus = num(skillRec.bonus ?? skillRec.mod) ?? 0;
  const skillRaceBonus = num(skillRec.race_bonus) ?? 0;

  const basis =
    calcStatFinal(statCur, statBonus, statRaceBonus) +
    calcSkillContribution(skillCur, skillBonus, skillRaceBonus);

  const fmt = (n: number) => (n > 0 ? `+${n}` : `${n}`);
  const statAbbr = params.statAbbr[statId] ?? statId;
  const compact = [
    String(skillCur),
    fmt(skillBonus),
    fmt(skillRaceBonus),
    `${params.baseWord} ${basis}`,
  ].join('  ');
  return {
    skillLine: `${skillName} (${statAbbr})`,
    rightLine: compact,
    basis: String(basis),
  };
}

function calcDefiningDisplay(params: {
  statistics: Record<string, unknown>;
  skillsCommon: Record<string, unknown>;
  defining: Record<string, unknown> | null;
  statAbbr: Record<string, string>;
  skillsCatalogById?: ReadonlyMap<string, SkillCatalogLite>;
}): DefiningDisplay {
  const { statistics, skillsCommon, defining } = params;
  if (!defining) {
    return { skillLine: '—', basis: '', cells: { skillCur: '', skillBonus: '', skillRaceBonus: '', basis: '' } };
  }
  const skillId = typeof defining.id === 'string' ? defining.id : '';
  const skillName = text(defining.name ?? defining.label ?? defining.id, '—');
  const skillRec = asRecord(skillId ? skillsCommon[skillId] : null) ?? {};
  const catalogParam = params.skillsCatalogById?.get(skillId)?.param ?? null;
  const statId =
    (typeof catalogParam === 'string' && catalogParam.trim()
      ? catalogParam.trim().toUpperCase()
      : skillId.startsWith('language_')
        ? 'INT'
        : (SKILL_TO_STAT[skillId] ?? '').toUpperCase());
  const statRec = asRecord(statId ? statistics[statId] : null) ?? {};
  const statAbbr = params.statAbbr[statId] ?? statId;

  const statCur = num(statRec.cur) ?? 0;
  const statBonus = num(statRec.bonus ?? statRec.mod) ?? 0;
  const statRaceBonus = num(statRec.race_bonus) ?? 0;
  const skillCur = num(skillRec.cur) ?? 0;
  const skillBonus = num(skillRec.bonus ?? skillRec.mod) ?? 0;
  const skillRaceBonus = num(skillRec.race_bonus) ?? 0;
  const basis =
    calcStatFinal(statCur, statBonus, statRaceBonus) +
    calcSkillContribution(skillCur, skillBonus, skillRaceBonus);
  const fmtSigned = (n: number) => (n > 0 ? `+${n}` : `${n}`);
  const visibleIfNonZero = (n: number) => (n === 0 ? '' : fmtSigned(n));
  return {
    skillLine: statId ? `${skillName} (${statAbbr})` : skillName,
    basis: String(basis),
    cells: {
      skillCur: skillCur === 0 ? '' : String(skillCur),
      skillBonus: visibleIfNonZero(skillBonus),
      skillRaceBonus: visibleIfNonZero(skillRaceBonus),
      basis: String(basis),
    },
  };
}

function sumWeight(resolved: Record<string, unknown>): string {
  const gear = asRecord(resolved.gear); if (!gear) return '';
  let total = 0; let seen = false;
  const walk = (v: unknown): void => {
    if (Array.isArray(v)) return v.forEach(walk);
    const r = asRecord(v); if (!r) return;
    const w = num(r.weight); if (w != null) { total += w * (num(r.amount ?? r.qty ?? r.quantity) ?? 1); seen = true; }
    Object.values(r).forEach(walk);
  };
  walk(gear);
  return seen ? total.toFixed(1) : '';
}

function formatSignedVisible(n: number): string {
  if (n === 0) return '';
  return n > 0 ? `+${n}` : `${n}`;
}

function clamp(n: number, minValue: number, maxValue: number): number {
  return Math.min(Math.max(n, minValue), maxValue);
}

function calcStatFinal(cur: number, bonus: number, raceBonus: number): number {
  return Math.max(1, Math.min(cur + bonus, 10) + raceBonus);
}

function calcSkillContribution(cur: number, bonus: number, raceBonus: number): number {
  return Math.max(0, Math.min(cur + bonus, 10) + raceBonus);
}

function formatStatHeaderExpression(cells: ValueCells): string {
  const cur = cells.cur.trim();
  const bonus = cells.bonus.trim();
  const race = cells.raceBonus.trim();
  const final = cells.final.trim();
  if (!cur && !final) return '';
  if (!bonus && !race) return final || cur;
  return `${cur}${bonus}${race} = ${final || cur}`;
}

function valueCellsFromStatish(rec: Record<string, unknown> | null): ValueCells {
  const r = rec ?? {};
  const cur = num(r.cur ?? r.value ?? r.total) ?? 0;
  const bonus = num(r.bonus ?? r.mod) ?? 0;
  const raceBonus = num(r.race_bonus) ?? 0;
  const final = calcStatFinal(cur, bonus, raceBonus);
  return {
    cur: cur === 0 ? '' : String(cur),
    bonus: formatSignedVisible(bonus),
    raceBonus: formatSignedVisible(raceBonus),
    final: String(final),
  };
}

class Painter {
  private doc: PDFKit.PDFDocument;
  private x: number;
  private w: number;
  private y: number;
  constructor(doc: PDFKit.PDFDocument) {
    this.doc = doc;
    this.x = PAGE.margin;
    this.w = doc.page.width - PAGE.margin * 2;
    this.y = PAGE.margin;
    const fp = fontPaths();
    doc.registerFont(FONTS.regular, fp.regular);
    doc.registerFont(FONTS.bold, fp.bold);
    this.paintBg();
  }
  private paintBg() { this.doc.rect(0, 0, this.doc.page.width, this.doc.page.height).fill(COLORS.page); }
  private bottom() { return this.doc.page.height - PAGE.margin; }
  private ensure(h: number) { if (this.y + h <= this.bottom()) return; this.doc.addPage(); this.paintBg(); this.y = PAGE.margin; }
  private fontB(n: number) { this.doc.font(FONTS.bold).fontSize(n); }
  private fontR(n: number) { this.doc.font(FONTS.regular).fontSize(n); }
  private boxHeader(x: number, y: number, w: number, t: string, fill: string) {
    this.doc.rect(x, y, w, PAGE.headerH).fill(fill);
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, PAGE.headerH).stroke();
    this.fontB(8.4); this.doc.fillColor(COLORS.text).text(t, x + 4, y + 3, { width: w - 8, lineBreak: false, ellipsis: true });
  }
  private shell(x: number, y: number, w: number, h: number, t: string, fill: string) {
    this.boxHeader(x, y, w, t, fill);
    this.doc.rect(x, y + PAGE.headerH, w, h - PAGE.headerH).fill('#ffffff');
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, h).stroke();
  }
  private kvBox(x: number, y: number, w: number, title: string, rows: { label: string; value: string }[]) {
    const rowH = 14; const h = PAGE.headerH + Math.max(1, rows.length) * rowH; const split = x + w * 0.45;
    this.shell(x, y, w, h, title, '#e7e7e7');
    let cy = y + PAGE.headerH;
    rows.forEach((r, i) => {
      if (i > 0) this.doc.moveTo(x, cy).lineTo(x + w, cy).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      this.doc.moveTo(split, cy).lineTo(split, cy + rowH).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      this.fontB(7.2); this.doc.fillColor(COLORS.text).text(r.label, x + 4, cy + 3, { width: split - x - 8, lineBreak: false, ellipsis: true });
      this.fontR(7.1); this.doc.fillColor(COLORS.text).text(r.value, split + 4, cy + 3, { width: x + w - split - 8, lineBreak: false, ellipsis: true });
      cy += rowH;
    });
    return h;
  }
  private baseHeaderBox(
    x: number,
    y: number,
    w: number,
    title: string,
    rows: { label: string; value: string }[],
    definingLabel: string,
    definingLeftValue: string,
    definingCells: { skillCur: string; skillBonus: string; skillRaceBonus: string; basis: string },
    fixedHeight?: number,
  ) {
    const rowH = 12;
    const totalRows = rows.length + 2;
    const h = Math.max(PAGE.headerH + totalRows * rowH, fixedHeight ?? 0);
    this.shell(x, y, w, h, title, '#e7e7e7');
    let cy = y + PAGE.headerH;

    rows.forEach((r, i) => {
      if (i > 0) this.doc.moveTo(x, cy).lineTo(x + w, cy).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      this.fontB(7.0);
      this.doc.fillColor(COLORS.text).text(r.label, x + 4, cy + 2, { width: w * 0.45 - 8, lineBreak: false, ellipsis: true });
      this.fontR(7.0);
      this.doc.fillColor(COLORS.text).text(r.value, x + w * 0.42, cy + 2, { width: w * 0.58 - 6, lineBreak: false, ellipsis: true });
      cy += rowH;
    });

    this.doc.moveTo(x, cy).lineTo(x + w, cy).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      this.fontB(7.0);
      this.doc.fillColor(COLORS.text).text(definingLabel, x + 4, cy + 2, { width: w - 8, lineBreak: false, ellipsis: true });
      cy += rowH;

    // No horizontal line between "Defining skill" label row and its value row.
    this.fontR(6.85);
    const cells = [
      { text: definingCells.skillCur, bold: false },
      { text: definingCells.skillBonus, bold: false },
      { text: definingCells.skillRaceBonus, bold: true },
      { text: definingCells.basis, bold: false },
    ];
    const gap = 2;
    const measuredWidths = cells.map((cell) => {
      if (!cell.text) return 0;
      if (cell.bold) this.fontB(6.2); else this.fontR(6.2);
      return Math.ceil(this.doc.widthOfString(cell.text)) + 2;
    });
    const widths = [
      Math.max(0, measuredWidths[0] ?? 0),
      Math.max(0, measuredWidths[1] ?? 0),
      Math.max(0, measuredWidths[2] ?? 0),
      Math.max(0, measuredWidths[3] ?? 0),
    ];
    const visibleCells = cells.reduce((acc, c) => acc + (c.text ? 1 : 0), 0);
    const rightW = widths.reduce((a, b) => a + b, 0) + Math.max(0, visibleCells - 1) * gap;
    const leftPad = 4;
    const rightPad = 4;
    const leftW = Math.max(12, w - leftPad - rightPad - rightW - 4);
    this.fontR(6.85);
    this.doc.fillColor(COLORS.text).text(definingLeftValue, x + leftPad, cy + 2, {
      width: leftW,
      height: rowH - 2,
      lineBreak: false,
      ellipsis: true,
    });
    let rx = x + w - rightPad - rightW;
    for (let i = 0; i < cells.length; i += 1) {
      const cell = cells[i]!;
      const cw = widths[i]!;
      if (!cw) continue;
      if (cell.bold) this.fontB(6.2); else this.fontR(6.2);
      this.doc.fillColor(COLORS.text).text(cell.text, rx, cy + 2, {
        width: cw,
        align: 'right',
        height: rowH - 2,
        lineBreak: false,
        ellipsis: true,
      });
      rx += cw;
      if (i < cells.length - 1) {
        let hasNextVisible = false;
        for (let j = i + 1; j < cells.length; j += 1) {
          if (widths[j] && cells[j]!.text) {
            hasNextVisible = true;
            break;
          }
        }
        if (hasNextVisible) rx += gap;
      }
    }
    return h;
  }
  private topParamsCombinedBox(
    x: number,
    y: number,
    w: number,
    mainTitle: string,
    mainRows: Row[],
    extraTitle: string,
    extraRows: Row[],
    fixedHeight?: number,
  ) {
    const rowH = 12;
    const subHeaderH = 13;
    const pairX1 = x + 4;
    const pairV1 = x + w * 0.32;
    const pairX2 = x + w * 0.53;
    const pairV2 = x + w - 4;
    const h = Math.max(PAGE.headerH + 4 * rowH + subHeaderH + 4 * rowH, fixedHeight ?? 0);
    this.shell(x, y, w, h, mainTitle, '#e7e7e7');
    let cy = y + PAGE.headerH;

    const drawRichValueRight = (parts: Array<{ text: string; bold?: boolean }>, x0: number, y0: number, width: number) => {
      const visible = parts.filter((p) => p.text);
      if (!visible.length) return;
      const widths = visible.map((p) => {
        if (p.bold) this.fontB(6.9); else this.fontR(6.9);
        return Math.ceil(this.doc.widthOfString(p.text));
      });
      let rx = x0 + width - widths.reduce((a, b) => a + b, 0);
      for (let i = 0; i < visible.length; i += 1) {
        const p = visible[i]!;
        const pw = widths[i]!;
        if (p.bold) this.fontB(6.9); else this.fontR(6.9);
        this.doc.fillColor(COLORS.text).text(p.text, rx, y0, { width: pw, lineBreak: false, ellipsis: true });
        rx += pw;
      }
    };

    const drawPairRow = (left?: Row, right?: Row) => {
      if (cy > y + PAGE.headerH) this.doc.moveTo(x, cy).lineTo(x + w, cy).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      const lLabel = left?.cells[0] ?? '';
      const lBonus = left?.cells[2] && left.cells[2] !== '—' ? String(left.cells[2]).replace(/\s+/g, '') : '';
      const lRace = left?.cells[3] && left.cells[3] !== '—' ? String(left.cells[3]).replace(/\s+/g, '') : '';
      const lVal = left?.cells[1] ? `${left.cells[1]}${lBonus}${lRace}` : '';
      const rLabel = right?.cells[0] ?? '';
      const rBonus = right?.cells[2] && right.cells[2] !== '—' ? String(right.cells[2]).replace(/\s+/g, '') : '';
      const rRace = right?.cells[3] && right.cells[3] !== '—' ? String(right.cells[3]).replace(/\s+/g, '') : '';
      const rVal = right?.cells[1] ? `${right.cells[1]}${rBonus}${rRace}` : '';
      this.fontB(6.9);
      this.doc.fillColor(COLORS.text).text(lLabel, pairX1, cy + 2, { width: pairV1 - pairX1 - 2, lineBreak: false, ellipsis: true });
      if (left?.cells?.length && left.cells[3] !== undefined) {
        drawRichValueRight([
          { text: String(left.cells[1] ?? '') },
          { text: lBonus },
          { text: lRace, bold: true },
        ], pairV1, cy + 2, pairX2 - pairV1 - 6);
      } else {
        this.fontR(6.9);
        this.doc.fillColor(COLORS.text).text(lVal, pairV1, cy + 2, { width: pairX2 - pairV1 - 6, align: 'right', lineBreak: false, ellipsis: true });
      }
      this.fontB(6.9);
      this.doc.fillColor(COLORS.text).text(rLabel, pairX2, cy + 2, { width: pairV2 - pairX2 - 18, lineBreak: false, ellipsis: true });
      if (right?.cells?.length && right.cells[3] !== undefined) {
        drawRichValueRight([
          { text: String(right.cells[1] ?? '') },
          { text: rBonus },
          { text: rRace, bold: true },
        ], pairX2 + 14, cy + 2, pairV2 - (pairX2 + 14));
      } else {
        this.fontR(6.9);
        this.doc.fillColor(COLORS.text).text(rVal, pairX2 + 14, cy + 2, { width: pairV2 - (pairX2 + 14), align: 'right', lineBreak: false, ellipsis: true });
      }
      cy += rowH;
    };

    for (let i = 0; i < 4; i += 1) {
      drawPairRow(mainRows[i * 2], mainRows[i * 2 + 1]);
    }

    this.doc.rect(x, cy, w, subHeaderH).fill('#e7e7e7');
    this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(x, cy, w, subHeaderH).stroke();
    this.fontB(7.2);
    this.doc.fillColor(COLORS.text).text(extraTitle, x + 4, cy + 3, { width: w - 8, lineBreak: false, ellipsis: true });
    cy += subHeaderH;

    const extraPairs: Array<[Row | undefined, Row | undefined]> = [
      [extraRows[0], extraRows[1]],
      [extraRows[2], extraRows[3]],
      [extraRows[4], extraRows[5]],
      [extraRows[6], undefined],
    ];
    for (const [l, r] of extraPairs) drawPairRow(l, r);
    return h;
  }
  private topConsumablesBox(x: number, y: number, w: number, title: string, table: Table, fixedHeight?: number) {
    const rowH = 13;
    const headH = 14;
    const rows = table.rows.slice(0, 5);
    const h = Math.max(PAGE.headerH + headH + 5 * rowH, fixedHeight ?? 0);
    this.shell(x, y, w, h, title, '#e7e7e7');
    const ty = y + PAGE.headerH;
    this.doc.rect(x, ty, w, headH).fill('#ecebe7');
    this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(x, ty, w, headH).stroke();
    const header0 = (table.columns[0] ?? '').replace(/^Название$/i, 'ПАРАМЕТР');
    const valuesCol1 = rows.map((r) => r?.cells[1] ?? '');
    const valuesCol0 = rows.map((r) => r?.cells[0] ?? '');
    this.fontB(6.8);
    const nameW = Math.min(
      Math.max(
        52,
        Math.ceil(this.doc.widthOfString(header0)) + 8,
        ...valuesCol0.map((v) => Math.ceil(this.doc.widthOfString(String(v))) + 8),
      ),
      Math.floor(w * 0.68),
    );
    const maxW = Math.min(
      Math.max(
        34,
        Math.ceil(this.doc.widthOfString(table.columns[1] ?? '')) + 8,
        ...valuesCol1.map((v) => Math.ceil(this.doc.widthOfString(String(v))) + 8),
      ),
      Math.floor(w * 0.24),
    );
    const c1 = x + nameW;
    const c2 = x + nameW + maxW;
    this.fontB(6.8);
    this.doc.fillColor(COLORS.text).text(header0, x + 3, ty + 2, { width: c1 - x - 6, lineBreak: false, ellipsis: true });
    this.doc.fillColor(COLORS.text).text(table.columns[1] ?? '', c1 + 2, ty + 2, { width: c2 - c1 - 4, align: 'center', lineBreak: false, ellipsis: true });
    this.doc.fillColor(COLORS.text).text(table.columns[2] ?? '', c2 + 2, ty + 2, { width: x + w - c2 - 4, align: 'center', lineBreak: false, ellipsis: true });
    let ry = ty + headH;
    for (let i = 0; i < 5; i += 1) {
      this.doc.moveTo(x, ry).lineTo(x + w, ry).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      const row = rows[i];
      this.fontR(6.4);
      this.doc.fillColor(COLORS.text).text(row?.cells[0] ?? '', x + 3, ry + 2, { width: c1 - x - 6, height: rowH - 2 });
      this.doc.fillColor(COLORS.text).text(row?.cells[1] ?? '', c1 + 2, ry + 2, { width: c2 - c1 - 4, align: 'center', lineBreak: false, ellipsis: true });
      this.doc.fillColor(COLORS.text).text((row?.cells[2] ?? '').trim() === '0.0' ? '' : (row?.cells[2] ?? ''), c2 + 2, ry + 2, { width: x + w - c2 - 4, align: 'center', lineBreak: false, ellipsis: true });
      ry += rowH;
    }
    return h;
  }
  private drawValueCellsRow(
    x: number,
    y: number,
    w: number,
    cells: ValueCells,
    opts?: { fontSize?: number; fixedWidths?: [number, number, number, number] },
  ): number {
    const fontSize = opts?.fontSize ?? 6.2;
    const gap = 2;
    const items = [
      { text: cells.cur, bold: false },
      { text: cells.bonus, bold: false },
      { text: cells.raceBonus, bold: true },
      { text: cells.final, bold: false },
    ];
    const measuredWidths = items.map((it) => {
      if (!it.text) return 0;
      if (it.bold) this.fontB(fontSize); else this.fontR(fontSize);
      return Math.ceil(this.doc.widthOfString(it.text)) + 2;
    });
    const hasFixedWidths = Boolean(opts?.fixedWidths);
    const widths = opts?.fixedWidths ? [...opts.fixedWidths] : measuredWidths;
    const visibleCount = opts?.fixedWidths
      ? items.length
      : items.reduce((acc, it, idx) => acc + (it.text && widths[idx]! > 0 ? 1 : 0), 0);
    const rightW = widths.reduce((a, b) => a + b, 0) + Math.max(0, visibleCount - 1) * gap;
    let rx = x + w - 4 - rightW;
    for (let i = 0; i < items.length; i += 1) {
      const it = items[i]!;
      const width = widths[i]!;
      if (width > 0 && it.text) {
        if (it.bold) this.fontB(fontSize); else this.fontR(fontSize);
        this.doc.fillColor(COLORS.text).text(it.text, rx, y, {
          width,
          align: 'right',
          lineBreak: false,
          ellipsis: true,
        });
      }
      rx += width;
      if (hasFixedWidths) {
        if (i < items.length - 1) rx += gap;
      } else {
        let hasNextVisible = false;
        for (let j = i + 1; j < items.length; j += 1) {
          if (items[j]!.text && widths[j]! > 0) {
            hasNextVisible = true;
            break;
          }
        }
        if (hasNextVisible) rx += gap;
      }
    }
    return rightW;
  }
  private drawSkillSidebar(x: number, y: number, w: number, h: number, groups: SkillSidebarGroup[]) {
    this.doc.rect(x, y, w, h).fill('#ffffff');
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, h).stroke();
    let headerH = 14;
    let rowFont = 6.6;
    let valueFont = 6.0;
    let headerValueFont = 6.1;
    let minRowH = 12;
    const sidebarColWidths: [number, number, number, number] = [0, 0, 0, 0];
    const measureSidebarCells = (cells: ValueCells, fontSize: number) => {
      const vals = [
        { t: cells.cur, bold: false },
        { t: cells.bonus, bold: false },
        { t: cells.raceBonus, bold: true },
        { t: cells.final, bold: false },
      ] as const;
      vals.forEach((v, i) => {
        if (!v.t) return;
        if (v.bold) this.fontB(fontSize); else this.fontR(fontSize);
        const width = Math.ceil(this.doc.widthOfString(v.t)) + 2;
        if (width > sidebarColWidths[i]!) sidebarColWidths[i] = width;
      });
    };
    const recalcWidths = () => {
      sidebarColWidths[0] = 0; sidebarColWidths[1] = 0; sidebarColWidths[2] = 0; sidebarColWidths[3] = 0;
      for (const group of groups) {
        measureSidebarCells(group.statCells, headerValueFont);
        for (const row of group.rows) measureSidebarCells(row.cells, valueFont);
      }
      sidebarColWidths.forEach((v, i) => { if (v <= 0) sidebarColWidths[i] = 7; });
    };
    const measureTotalHeight = () => {
      recalcWidths();
      const sidebarRightW = sidebarColWidths.reduce((a, b) => a + b, 0) + 2 * 3;
      let total = 0;
      for (const group of groups) {
        total += headerH;
        for (const row of group.rows) {
          this.fontR(rowFont);
          const leftW = Math.max(18, w - sidebarRightW - 12);
          const textH = Math.ceil(this.doc.heightOfString(row.name, { width: leftW }));
          total += Math.max(minRowH, textH + 2);
        }
      }
      return { total, sidebarRightW };
    };
    let measured = measureTotalHeight();
    if (measured.total > h) {
      headerH = 13;
      rowFont = 6.1;
      valueFont = 5.8;
      headerValueFont = 5.9;
      minRowH = 10;
      measured = measureTotalHeight();
    }
    if (measured.total > h) {
      headerH = 12;
      rowFont = 5.8;
      valueFont = 5.5;
      headerValueFont = 5.6;
      minRowH = 9;
      measured = measureTotalHeight();
    }
    const totalRowCount = groups.reduce((acc, g) => acc + g.rows.length, 0);
    const spare = Math.max(0, h - measured.total);
    const rowExtraPad = totalRowCount > 0 ? Math.min(2, Math.floor(spare / totalRowCount)) : 0;
    const sidebarRightW = measured.sidebarRightW;
    let cy = y;
    for (const group of groups) {
      let groupHeight = headerH;
      const measuredRowHeights: number[] = [];
      for (const row of group.rows) {
        this.fontR(rowFont);
        const leftW = Math.max(20, w - sidebarRightW - 12);
        const textH = Math.ceil(this.doc.heightOfString(row.name, { width: leftW }));
        const rowH = Math.max(minRowH, textH + 2 + rowExtraPad);
        measuredRowHeights.push(rowH);
        groupHeight += rowH;
      }
      if (cy + groupHeight > y + h) break;
      this.doc.rect(x, cy, w, headerH).fill('#e7e7e7');
      this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(x, cy, w, headerH).stroke();
      this.fontB(headerH <= 12 ? 6.7 : 7.1);
      this.doc.fillColor(COLORS.text).text(group.title, x + 4, cy + 3, {
        width: Math.max(18, w - sidebarRightW - 10),
        lineBreak: false,
        ellipsis: true,
      });
      const statExpr = formatStatHeaderExpression(group.statCells);
      this.fontB(headerValueFont);
      this.doc.fillColor(COLORS.text).text(statExpr, x + 4, cy + 3, {
        width: w - 8,
        align: 'right',
        lineBreak: false,
        ellipsis: true,
      });
      cy += headerH;

      for (let i = 0; i < group.rows.length; i += 1) {
        const row = group.rows[i]!;
        const rowH = measuredRowHeights[i] ?? 12;
        this.doc.moveTo(x, cy).lineTo(x + w, cy).strokeColor('#d7dbe0').lineWidth(0.2).stroke();
        this.drawValueCellsRow(x, cy + 1, w, row.cells, { fontSize: valueFont, fixedWidths: sidebarColWidths });
        const leftW = Math.max(20, w - sidebarRightW - 12);
        this.fontR(rowFont);
        this.doc.fillColor(COLORS.text).text(row.name, x + 4, cy + 2, {
          width: leftW,
          height: rowH - 3,
        });
        cy += rowH;
      }
    }
  }
  private drawProfessionalBranches(x: number, y: number, w: number, branches: ProfBranch[], title: string): number {
    const titleH = PAGE.headerH;
    const gap = PAGE.gap;
    const colW = (w - gap * 2) / 3;
    this.fontB(8.4);
    this.doc.fillColor(COLORS.text).text(title, x + 4, y + 3, { width: w - 8, lineBreak: false, ellipsis: true });
    const by = y + titleH;
    const branchLayouts = branches.slice(0, 3).map((b, idx) => {
      const bx = x + idx * (colW + gap);
      const fill = b.color === 'blue' ? COLORS.blue : b.color === 'mint' ? COLORS.mint : COLORS.rose;
      const rowHeights: number[] = [];
      const split = bx + colW * 0.8;
      this.fontR(6.5);
      for (let i = 0; i < 3; i += 1) {
        const row = b.rows[i];
        const left = row ? `${row.name}${row.paramAbbr ? ` (${row.paramAbbr})` : ''}` : '';
        const textH = left ? Math.ceil(this.doc.heightOfString(left, { width: split - bx - 6 })) : 0;
        rowHeights.push(Math.max(13, textH + 3));
      }
      const bodyH = rowHeights.reduce((a, v) => a + v, 0);
      return { b, idx, bx, fill, split, rowHeights, bodyH };
    });
    const maxBodyH = Math.max(0, ...branchLayouts.map((l) => l.bodyH));
    let maxBranchH = PAGE.headerH + maxBodyH;
    branchLayouts.forEach((layout) => {
      const extra = Math.max(0, maxBodyH - layout.bodyH);
      if (extra > 0) {
        const baseAdd = Math.floor(extra / layout.rowHeights.length);
        let rem = extra % layout.rowHeights.length;
        for (let i = 0; i < layout.rowHeights.length; i += 1) {
          layout.rowHeights[i]! += baseAdd + (rem > 0 ? 1 : 0);
          if (rem > 0) rem -= 1;
        }
      }
      const { b, bx, fill, split, rowHeights } = layout;
      const bodyH = rowHeights.reduce((a, v) => a + v, 0);
      const boxH = PAGE.headerH + bodyH;
      this.doc.rect(bx, by, colW, boxH).fill('#ffffff');
      this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(bx, by, colW, boxH).stroke();
      this.doc.rect(bx, by, colW, PAGE.headerH).fill(fill);
      this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(bx, by, colW, PAGE.headerH).stroke();
      this.fontB(8.4);
      this.doc.fillColor(COLORS.text).text(b.title.toUpperCase(), bx + 4, by + 3, { width: colW - 8, lineBreak: false, ellipsis: true });
      let ry = by + PAGE.headerH;
      for (let i = 0; i < 3; i += 1) {
        const rowH = rowHeights[i] ?? 13;
        this.doc.moveTo(bx, ry).lineTo(bx + colW, ry).strokeColor(COLORS.line).lineWidth(0.2).stroke();
        this.doc.rect(bx, ry, split - bx, rowH).fill(fill);
        this.doc.lineWidth(0.2).strokeColor(COLORS.line).rect(bx, ry, split - bx, rowH).stroke();
        this.doc.lineWidth(0.2).strokeColor(COLORS.line).rect(split, ry, bx + colW - split, rowH).stroke();
        const row = b.rows[i];
        const left = row ? `${row.name}${row.paramAbbr ? ` (${row.paramAbbr})` : ''}` : '';
        this.fontR(6.5);
        this.doc.fillColor(COLORS.text).text(left, bx + 3, ry + 2, {
          width: split - bx - 6,
          height: rowH - 3,
        });
        ry += rowH;
      }
    });
    return titleH + maxBranchH;
  }
  private drawPerksCompact(x: number, y: number, w: number, table: Table): number {
    const rows = table.rows.slice(0, 6).map((r) => ({
      name: stripHtmlTags((r.cells[0] ?? '').trim()),
      effect: stripHtmlTags((r.cells[1] ?? '').trim()),
    }));
    const headerH = PAGE.headerH;
    const nameWMeasured = rows.reduce((m, r) => {
      this.fontB(7.0);
      return Math.max(m, Math.ceil(this.doc.widthOfString(r.name || '—')) + 8);
    }, 72);
    const nameW = Math.min(Math.max(72, nameWMeasured), Math.floor(w * 0.26));
    const rowHeights = rows.map((r) => {
      this.fontR(6.2);
      return Math.max(13, Math.ceil(this.doc.heightOfString(r.effect || '—', { width: Math.max(20, w - nameW - 8) })) + 3);
    });
    const bodyH = rowHeights.reduce((a, v) => a + v, 0);
    const h = headerH + bodyH;
    this.doc.rect(x, y, w, h).fill('#ffffff');
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, h).stroke();
    this.doc.rect(x, y, w, headerH).fill(COLORS.sand);
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, headerH).stroke();
    this.doc.moveTo(x + nameW, y).lineTo(x + nameW, y + h).strokeColor(COLORS.line).lineWidth(0.25).stroke();
    this.fontB(8.4);
    this.doc.fillColor(COLORS.text).text('ПЕРК', x + 4, y + 3, { width: nameW - 8, lineBreak: false, ellipsis: true });
    this.doc.fillColor(COLORS.text).text((table.columns[1] ?? 'ЭФФЕКТ').toUpperCase(), x + nameW + 2, y + 3, { width: w - nameW - 4, align: 'center', lineBreak: false, ellipsis: true });
    let cy = y + headerH;
    for (let i = 0; i < rows.length; i += 1) {
      const row = rows[i]!;
      const rowH = rowHeights[i]!;
      this.doc.moveTo(x, cy).lineTo(x + w, cy).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      this.fontB(6.8);
      this.doc.fillColor(COLORS.text).text(row.name || '—', x + 3, cy + 2, { width: nameW - 6, height: rowH - 3 });
      this.fontR(6.1);
      this.doc.fillColor(COLORS.text).text(row.effect || '—', x + nameW + 3, cy + 2, { width: w - nameW - 6, height: rowH - 3 });
      cy += rowH;
    }
    this.doc.moveTo(x, y + h).lineTo(x + w, y + h).strokeColor(COLORS.line).lineWidth(0.25).stroke();
    return h;
  }
  private drawWeaponsCompact(x: number, y: number, w: number, table: Table): number {
    const headerH = PAGE.headerH;
    const srcRows = table.rows.map((r) => {
      const rawName = (r.cells[1] ?? '').trim();
      const parts = rawName.split(/\r?\n/).map((s) => s.trim()).filter(Boolean);
      const name = parts[0] ?? '—';
      const effectFromName = parts.slice(1).join(' ');
      const effect = normalizeInlineEffects((r.cells[10] ?? effectFromName ?? '').trim());
      return {
        qty: (r.cells[0] ?? '').trim(),
        name: stripHtmlTags(name),
        effect,
        dmg: (r.cells[2] ?? '').trim(),
        type: (r.cells[3] ?? '').trim(),
        rel: (r.cells[4] ?? '').trim(),
        hands: (r.cells[5] ?? '').trim(),
        conceal: (r.cells[6] ?? '').trim(),
        enh: (r.cells[7] ?? '').trim(),
        wt: (r.cells[8] ?? '').trim(),
        price: (r.cells[9] ?? '').trim(),
      };
    });
    const rows = [...srcRows, ...new Array(3).fill(null).map(() => ({
      qty: '', name: '', effect: '', dmg: '', type: '', rel: '', hands: '', conceal: '', enh: '', wt: '', price: '',
    }))];
    const headers = (table.columns.length >= 11
      ? table.columns
      : [' ', '#', 'ОРУЖИЕ', 'УРОН', 'ТИП', 'Н', 'ХВАТ', 'СКР', 'УС', 'ВЕС', 'ЦЕНА']).map((h, i) => (i === 0 ? ' ' : String(h || '').toUpperCase()));
    const checkW = 14;
    const fitDefs: Array<{ key: keyof (typeof rows)[number]; header: string; min: number }> = [
      { key: 'qty', header: headers[1] ?? '#', min: 12 },
      { key: 'dmg', header: headers[3] ?? 'УРОН', min: 20 },
      { key: 'type', header: headers[4] ?? 'ТИП', min: 16 },
      { key: 'rel', header: headers[5] ?? 'Н', min: 14 },
      { key: 'hands', header: headers[6] ?? 'ХВАТ', min: 20 },
      { key: 'conceal', header: headers[7] ?? 'СКР', min: 18 },
      { key: 'enh', header: headers[8] ?? 'УС', min: 16 },
      { key: 'wt', header: headers[9] ?? 'ВЕС', min: 18 },
      { key: 'price', header: headers[10] ?? 'ЦЕНА', min: 20 },
    ];
    const fitWidths = fitDefs.map((d) => {
      this.fontB(6.5);
      let mw = Math.max(d.min, Math.ceil(this.doc.widthOfString(d.header)) + 6);
      this.fontR(6.4);
      for (const row of rows) mw = Math.max(mw, Math.ceil(this.doc.widthOfString(String(row[d.key] || ''))) + 6);
      return mw;
    });
    const nonNameW = checkW + fitWidths.reduce((a, v) => a + v, 0);
    const nameW = Math.max(110, w - nonNameW);
    const rowHeights = rows.map((row) => {
      if (!row.name && !row.effect) return 14;
      this.fontR(6.4);
      const nameH = Math.ceil(this.doc.heightOfString(row.name || '—', { width: nameW - 6 }));
      let effectH = 0;
      if (row.effect) {
        this.doc.font(FONTS.regular).fontSize(5.8);
        effectH = Math.ceil(this.doc.heightOfString(row.effect, { width: nameW - 6 }));
      }
      return Math.max(14, nameH + (row.effect ? effectH + 1 : 0) + 3);
    });
    const bodyH = rowHeights.reduce((a, v) => a + v, 0);
    const h = headerH + bodyH;
    this.doc.rect(x, y, w, h).fill('#ffffff');
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, h).stroke();
    this.doc.rect(x, y, w, headerH).fill('#f5ecec');
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, headerH).stroke();
    const cols = [checkW, fitWidths[0]!, nameW, ...fitWidths.slice(1)];
    let cx = x;
    for (let i = 0; i < cols.length; i += 1) {
      const cw = cols[i]!;
      this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(cx, y, cw, h).stroke();
      this.fontB(6.5);
      this.doc.fillColor(COLORS.text).text(i === 0 ? ' ' : (headers[i] ?? ''), cx + 2, y + 2, { width: cw - 4, align: i >= 3 ? 'center' : (i === 2 ? 'left' : 'center'), lineBreak: false, ellipsis: true });
      cx += cw;
    }
    let cy = y + headerH;
    for (let i = 0; i < rows.length; i += 1) {
      const row = rows[i]!;
      const rowH = rowHeights[i]!;
      this.doc.moveTo(x, cy).lineTo(x + w, cy).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      const vals = [' ', row.qty, row.name, row.dmg, row.type, row.rel, row.hands, row.conceal, row.enh, row.wt, row.price];
      let rx = x;
      for (let c = 0; c < cols.length; c += 1) {
        const cw = cols[c]!;
        if (c === 2) {
          this.fontR(6.4);
          this.doc.fillColor(COLORS.text).text(vals[c] ?? '', rx + 3, cy + 2, { width: cw - 6, height: rowH - 3 });
          if (row.effect) {
            const nameHeight = Math.ceil(this.doc.heightOfString(row.name || '—', { width: cw - 6 }));
            this.doc.font(FONTS.regular).fontSize(5.8).fillColor('#6a6a6a').text(row.effect, rx + 3, cy + 2 + nameHeight, { width: cw - 6, height: rowH - 3, oblique: true });
          }
        } else if (c !== 0) {
          this.fontR(6.4);
          this.doc.fillColor(COLORS.text).text(vals[c] ?? '', rx + 2, cy + 2, { width: cw - 4, align: c >= 3 ? 'center' : 'right', lineBreak: false, ellipsis: true });
        }
        rx += cw;
      }
      cy += rowH;
    }
    return h;
  }
  private drawArmorDoll(x: number, y: number, w: number): number {
    // `doll.png` source is 218x400. Use aspect ratio to avoid oversized invisible box.
    const targetH = Math.round((Math.max(8, w - 4) * 400) / 218) + 4;
    const pad = 2;
    const boxH = targetH;

    const candidates = [
      '/var/task/assets/doll.png',
      path.join(process.cwd(), 'src', 'pdf', 'assets', 'doll.png'),
      path.join(process.cwd(), 'cloud', 'api', 'src', 'pdf', 'assets', 'doll.png'),
      path.join(process.cwd(), 'apps', 'api', 'src', 'pdf', 'assets', 'doll.png'),
    ];
    const dollPath = candidates.find((p) => fs.existsSync(p));
    if (!dollPath) {
      this.fontR(6.5);
      this.doc.fillColor(COLORS.muted).text('doll.png', x + 2, y + Math.max(2, Math.floor(boxH / 2) - 4), { width: w - 4, align: 'center', lineBreak: false, ellipsis: true });
      return boxH;
    }

    try {
      this.doc.image(dollPath, x + pad, y + pad, {
        fit: [w - pad * 2, boxH - pad * 2],
        align: 'center',
      });
    } catch {
      this.fontR(6.5);
      this.doc.fillColor(COLORS.muted).text('doll.png', x + 2, y + Math.max(2, Math.floor(boxH / 2) - 4), { width: w - 4, align: 'center', lineBreak: false, ellipsis: true });
    }
    return boxH;
  }
  private drawArmorCompact(x: number, y: number, w: number, table: Table): number {
    const headerH = PAGE.headerH;
    const srcRows = table.rows.map((r) => ({
      qty: (r.cells[0] ?? '').trim(),
      name: stripHtmlTags((r.cells[1] ?? '').trim()),
      sp: (r.cells[2] ?? '').trim(),
      enc: (r.cells[3] ?? '').trim(),
      enh: (r.cells[4] ?? '').trim(),
      wt: (r.cells[5] ?? '').trim(),
      price: (r.cells[6] ?? '').trim(),
      effect: normalizeInlineEffects((r.cells[7] ?? '').trim()),
    }));
    const totalRows = Math.max(srcRows.length + 3, 6);
    const rows = [...srcRows, ...new Array(Math.max(0, totalRows - srcRows.length)).fill(null).map(() => ({ qty: '', name: '', sp: '', enc: '', enh: '', wt: '', price: '', effect: '' }))];
    const headers = (table.columns.length >= 8 ? table.columns : [' ', '#', 'БРОНЯ', 'ПБ/Н', 'СД', 'УБ', 'ВЕС', 'ЦЕНА']).map((h, i) => (i === 0 ? ' ' : String(h || '').toUpperCase()));
    const checkW = 14;
    const fitDefs: Array<{ key: keyof (typeof rows)[number]; header: string; min: number }> = [
      { key: 'qty', header: headers[1] ?? '#', min: 12 },
      { key: 'sp', header: headers[3] ?? 'SP', min: 22 },
      { key: 'enc', header: headers[4] ?? 'ENC', min: 18 },
      { key: 'enh', header: headers[5] ?? 'ENH', min: 18 },
      { key: 'wt', header: headers[6] ?? 'WT', min: 20 },
      { key: 'price', header: headers[7] ?? 'PRICE', min: 22 },
    ];
    const fitWidths = fitDefs.map((d) => {
      this.fontB(6.5);
      let mw = Math.max(d.min, Math.ceil(this.doc.widthOfString(d.header)) + 6);
      this.fontR(6.4);
      for (const row of rows) mw = Math.max(mw, Math.ceil(this.doc.widthOfString(String(row[d.key] || ''))) + 6);
      return mw;
    });
    const nonNameW = checkW + fitWidths.reduce((a, v) => a + v, 0);
    const nameW = Math.max(100, w - nonNameW);
    const rowHeights = rows.map((row) => {
      if (!row.name && !row.effect) return 14;
      this.fontR(6.4);
      const nameH = Math.ceil(this.doc.heightOfString(row.name || '—', { width: nameW - 6 }));
      let effectH = 0;
      if (row.effect) {
        this.doc.font(FONTS.regular).fontSize(5.8);
        effectH = Math.ceil(this.doc.heightOfString(row.effect, { width: nameW - 6 }));
      }
      return Math.max(14, nameH + (row.effect ? effectH + 1 : 0) + 3);
    });
    const bodyH = rowHeights.reduce((a, v) => a + v, 0);
    const h = headerH + bodyH;
    this.doc.rect(x, y, w, h).fill('#ffffff');
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, h).stroke();
    this.doc.rect(x, y, w, headerH).fill(COLORS.blue);
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, headerH).stroke();
    const cols = [checkW, fitWidths[0]!, nameW, ...fitWidths.slice(1)];
    let cx = x;
    for (let i = 0; i < cols.length; i += 1) {
      const cw = cols[i]!;
      this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(cx, y, cw, h).stroke();
      this.fontB(6.5);
      this.doc.fillColor(COLORS.text).text(i === 0 ? ' ' : (headers[i] ?? ''), cx + 2, y + 2, { width: cw - 4, align: i >= 3 ? 'center' : (i === 2 ? 'left' : 'center'), lineBreak: false, ellipsis: true });
      cx += cw;
    }
    let cy = y + headerH;
    for (let i = 0; i < rows.length; i += 1) {
      const row = rows[i]!;
      const rowH = rowHeights[i]!;
      this.doc.moveTo(x, cy).lineTo(x + w, cy).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      const vals = [' ', row.qty, row.name, row.sp, row.enc, row.enh, row.wt, row.price];
      let rx = x;
      for (let c = 0; c < cols.length; c += 1) {
        const cw = cols[c]!;
        if (c === 2) {
          this.fontR(6.4);
          this.doc.fillColor(COLORS.text).text(vals[c] ?? '', rx + 3, cy + 2, { width: cw - 6, height: rowH - 3 });
          if (row.effect) {
            const nameHeight = Math.ceil(this.doc.heightOfString(row.name || '—', { width: cw - 6 }));
            this.doc.font(FONTS.regular).fontSize(5.8).fillColor('#6a6a6a').text(row.effect, rx + 3, cy + 2 + nameHeight, { width: cw - 6, height: rowH - 3, oblique: true });
          }
        } else if (c !== 0) {
          this.fontR(6.4);
          this.doc.fillColor(COLORS.text).text(vals[c] ?? '', rx + 2, cy + 2, { width: cw - 4, align: c >= 3 ? 'center' : 'right', lineBreak: false, ellipsis: true });
        }
        rx += cw;
      }
      cy += rowH;
    }
    return h;
  }
  private drawAlchemyCompact(x: number, y: number, w: number, table: Table): number {
    const headerH = PAGE.headerH;
    const srcRows = table.rows.map((r) => ({
      qty: (r.cells[0] ?? '').trim(),
      name: stripHtmlTags((r.cells[1] ?? '').trim()),
      tox: (r.cells[2] ?? '').trim(),
      time: (r.cells[3] ?? '').trim(),
      effect: normalizeInlineEffects((r.cells[4] ?? '').trim()),
      wt: (r.cells[5] ?? '').trim(),
      price: (r.cells[6] ?? '').trim(),
    }));
    const totalRows = Math.max(srcRows.length + 3, 3);
    const rows = [...srcRows, ...new Array(Math.max(0, totalRows - srcRows.length)).fill(null).map(() => ({ qty: '', name: '', tox: '', time: '', effect: '', wt: '', price: '' }))];
    const headers = (table.columns.length >= 7 ? table.columns : ['#', 'АЛХИМИЯ', 'ТОКС', 'ВРЕМЯ', 'ЭФФЕКТ', 'ВЕС', 'ЦЕНА']).map((h) => String(h || '').toUpperCase());
    const fitDefs: Array<{ key: keyof (typeof rows)[number]; header: string; min: number }> = [
      { key: 'qty', header: headers[0] ?? '#', min: 14 },
      { key: 'name', header: headers[1] ?? 'АЛХИМИЯ', min: 56 },
      { key: 'tox', header: headers[2] ?? 'ТОКС', min: 22 },
      { key: 'time', header: headers[3] ?? 'ВРЕМЯ', min: 30 },
      { key: 'wt', header: headers[5] ?? 'ВЕС', min: 20 },
      { key: 'price', header: headers[6] ?? 'ЦЕНА', min: 22 },
    ];
    const fitWidths = fitDefs.map((d) => {
      this.fontB(6.5);
      let mw = Math.max(d.min, Math.ceil(this.doc.widthOfString(d.header)) + 6);
      this.fontR(6.2);
      for (const row of rows) mw = Math.max(mw, Math.ceil(this.doc.widthOfString(String(row[d.key] || ''))) + 6);
      return mw;
    });
    const nonFlex = fitWidths.reduce((a, v) => a + v, 0);
    const effectW = Math.max(100, w - nonFlex);
    const rowHeights = rows.map((row) => {
      if (!row.effect) return 14;
      this.fontR(6.0);
      return Math.max(14, Math.ceil(this.doc.heightOfString(row.effect, { width: effectW - 6 })) + 3);
    });
    const bodyH = rowHeights.reduce((a, v) => a + v, 0);
    const h = headerH + bodyH;
    this.doc.rect(x, y, w, h).fill('#ffffff');
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, h).stroke();
    this.doc.rect(x, y, w, headerH).fill(COLORS.mint);
    this.doc.lineWidth(0.7).strokeColor(COLORS.line).rect(x, y, w, headerH).stroke();
    const cols = [fitWidths[0]!, fitWidths[1]!, fitWidths[2]!, fitWidths[3]!, effectW, fitWidths[4]!, fitWidths[5]!];
    let cx = x;
    for (let i = 0; i < cols.length; i += 1) {
      const cw = cols[i]!;
      this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(cx, y, cw, h).stroke();
      this.fontB(6.5);
      this.doc.fillColor(COLORS.text).text(headers[i] ?? '', cx + 2, y + 2, { width: cw - 4, align: i === 1 || i === 4 ? 'left' : 'center', lineBreak: false, ellipsis: true });
      cx += cw;
    }
    let cy = y + headerH;
    for (let i = 0; i < rows.length; i += 1) {
      const row = rows[i]!;
      const rowH = rowHeights[i]!;
      this.doc.moveTo(x, cy).lineTo(x + w, cy).strokeColor(COLORS.line).lineWidth(0.25).stroke();
      const vals = [row.qty, row.name, row.tox, row.time, row.effect, row.wt, row.price];
      let rx = x;
      for (let c = 0; c < cols.length; c += 1) {
        const cw = cols[c]!;
        this.fontR(c === 4 ? 6.0 : 6.2);
        this.doc.fillColor(COLORS.text).text(vals[c] ?? '', rx + 2, cy + 2, { width: cw - 4, height: rowH - 3, align: c === 1 || c === 4 ? 'left' : 'center' });
        rx += cw;
      }
      cy += rowH;
    }
    return h;
  }
  private table(x: number, y: number, w: number, table: Table, weights: number[], fill: string, maxRows?: number) {
    const rows = typeof maxRows === 'number' ? table.rows.slice(0, maxRows) : table.rows;
    const headH = 14, rowH = 12, h = PAGE.headerH + headH + Math.max(1, rows.length) * rowH;
    this.shell(x, y, w, h, table.title, fill);
    const total = weights.reduce((a, b) => a + b, 0);
    const colW = weights.map((k) => (w * k) / total);
    const ty = y + PAGE.headerH;
    this.doc.rect(x, ty, w, headH).fill('#e9e9e9');
    let cx = x;
    for (let c = 0; c < colW.length; c += 1) {
      this.doc.lineWidth(0.25).strokeColor(COLORS.line).rect(cx, ty, colW[c]!, headH + Math.max(1, rows.length) * rowH).stroke();
      this.fontB(6.8); this.doc.fillColor(COLORS.text).text(table.columns[c] ?? '', cx + 3, ty + 3, { width: colW[c]! - 6, lineBreak: false, ellipsis: true });
      cx += colW[c]!;
    }
    let ry = ty + headH;
    for (let r = 0; r < Math.max(1, rows.length); r += 1) {
      // Keep table bodies white (no zebra fill) to match the reference style.
      const row = rows[r];
      let rx = x;
      for (let c = 0; c < colW.length; c += 1) {
        this.fontR(6.8);
        this.doc.fillColor(COLORS.text).text(row?.cells[c] ?? '', rx + 3, ry + 2, { width: colW[c]! - 6, height: rowH - 4, ellipsis: true });
        rx += colW[c]!;
      }
      ry += rowH;
    }
    return h;
  }
  private flowTable(table: Table, weights: number[], fill: string) {
    let idx = 0;
    while (idx < table.rows.length || (idx === 0 && table.rows.length === 0)) {
      const rowCapacity = Math.max(1, Math.floor((this.bottom() - this.y - PAGE.headerH - 18) / 12));
      this.ensure(PAGE.headerH + 18 + Math.min(3, Math.max(1, rowCapacity)) * 12);
      const chunkRows = table.rows.slice(idx, idx + rowCapacity);
      const title = idx === 0 ? table.title : `${table.title} (cont.)`;
      const h = this.table(this.x, this.y, this.w, { ...table, title, rows: chunkRows }, weights, fill);
      this.y += h + 6;
      if (!chunkRows.length) break;
      idx += chunkRows.length;
    }
  }
  private notesStrip(title: string) {
    const left = this.bottom() - this.y;
    if (left < 70) return;
    const h = left;
    const w = (this.w - PAGE.gap * 2) / 3;
    for (let i = 0; i < 3; i += 1) {
      const x = this.x + i * (w + PAGE.gap);
      this.shell(x, this.y, w, h, title, COLORS.sand);
      for (let ly = this.y + PAGE.headerH + 13; ly < this.y + h; ly += 14) {
        this.doc.moveTo(x, ly).lineTo(x + w, ly).strokeColor(COLORS.line).lineWidth(0.2).stroke();
      }
    }
    this.y += h;
  }
  private notesStripAt(x: number, y: number, w: number, h: number, title: string) {
    if (h < 50) return 0;
    const colW = (w - PAGE.gap * 2) / 3;
    for (let i = 0; i < 3; i += 1) {
      const bx = x + i * (colW + PAGE.gap);
      this.shell(bx, y, colW, h, title, COLORS.sand);
      for (let ly = y + PAGE.headerH + 13; ly < y + h; ly += 14) {
        this.doc.moveTo(bx, ly).lineTo(bx + colW, ly).strokeColor(COLORS.line).lineWidth(0.2).stroke();
      }
    }
    return h;
  }
  draw(vm: ReturnType<typeof buildVm>) {
    const tx = vm.tx;
    this.ensure(190);
    const freeW = this.w - PAGE.gap * 3;
    const baseW = freeW * 0.28;
    const cw = (freeW - baseW) / 3;
    const topY = this.y;
    const topH = 125;
    const x1 = this.x;
    const x2 = x1 + baseW + PAGE.gap;
    const x3 = x2 + cw + PAGE.gap;
    const x4 = x3 + cw + PAGE.gap;

    this.baseHeaderBox(
      x1,
      topY,
      baseW,
      tx.top.base,
      vm.baseRows,
      tx.labels.def,
      vm.definingSkillLine ?? '—',
      vm.definingCells ?? { skillCur: '', skillBonus: '', skillRaceBonus: '', basis: '' },
      topH,
    );
    this.topParamsCombinedBox(
      x2,
      topY,
      cw,
      tx.top.main,
      vm.mainStats,
      tx.top.extra,
      vm.extraStats,
      topH,
    );
    this.topConsumablesBox(
      x3,
      topY,
      cw,
      tx.top.cons,
      { title: tx.top.cons, columns: [tx.cols.n, tx.cols.max, tx.cols.cur], rows: vm.consRows },
      topH,
    );
    this.shell(x4, topY, cw, topH, tx.top.avatar, '#e7e7e7');
    this.doc.rect(x4 + 4, topY + PAGE.headerH + 4, cw - 8, topH - PAGE.headerH - 8).fill('#ddd2be');
    this.doc.lineWidth(0.4).strokeColor('#8f826b').rect(x4 + 4, topY + PAGE.headerH + 4, cw - 8, topH - PAGE.headerH - 8).stroke();
    this.fontR(7); this.doc.fillColor(COLORS.muted).text(tx.avatarPlaceholder, x4 + 8, topY + topH - 18, { width: cw - 16, align: 'center', lineBreak: false, ellipsis: true });
    this.y = topY + topH + PAGE.gap;

    const leftColumnH = this.bottom() - this.y;
    this.drawSkillSidebar(x1, this.y, baseW, leftColumnH, vm.skillSidebarGroups ?? []);
    const rightX = x2;
    const rightW = this.w - (rightX - this.x);
    const profUsedH = this.drawProfessionalBranches(rightX, this.y, rightW, vm.profBranches ?? [], tx.sections.prof);
    this.y += profUsedH + 8;
    if (vm.perksTable) {
      const perksH = this.drawPerksCompact(rightX, this.y, rightW, vm.perksTable);
      this.y += perksH + 6;
    }
    {
      const weaponsTable = vm.weaponsTable ?? {
        title: tx.sections.weapons,
        columns: [' ', tx.cols.qty, tx.sections.weapons, tx.cols.dmg, tx.cols.type, tx.cols.rel, tx.cols.hands, tx.cols.conceal, tx.cols.enh, tx.cols.wt, tx.cols.price],
        rows: [],
      };
      const weaponsH = this.drawWeaponsCompact(rightX, this.y, rightW, weaponsTable);
      this.y += weaponsH + 6;
    }
    {
      const armorTable = vm.armorTable ?? {
        title: tx.sections.armor,
        columns: [' ', tx.cols.qty, tx.sections.armor, vm.lang === 'ru' ? 'ПБ/Н' : 'SP', tx.cols.enc, vm.lang === 'ru' ? 'УБ' : 'ENH', tx.cols.wt, tx.cols.price],
        rows: [],
      };
      const dollW = Math.floor(rightW * 0.15);
      const armorGap = 6;
      const armorX = rightX + dollW + armorGap;
      const armorW = rightW - dollW - armorGap;
      const dollH = this.drawArmorDoll(rightX, this.y, dollW);
      const armorH = this.drawArmorCompact(armorX, this.y, armorW, armorTable);
      this.y += Math.max(dollH, armorH) + 6;
    }
    {
      const potionTable = vm.potionTable ?? {
        title: tx.sections.alchemy,
        columns: [tx.cols.qty, tx.cols.n, tx.cols.tox, tx.cols.time, tx.cols.effect, tx.cols.wt, tx.cols.price],
        rows: [],
      };
      const alchemyH = this.drawAlchemyCompact(rightX, this.y, rightW, potionTable);
      this.y += alchemyH + 6;
    }
    {
      const notesH = this.bottom() - this.y;
      if (notesH >= 60) {
        this.notesStripAt(rightX, this.y, rightW, notesH, tx.sections.notes);
        this.y += notesH;
      }
    }

    return;
  }
}

function createPdfBuffer(build: (doc: PDFKit.PDFDocument) => void): Promise<Buffer> {
  return new Promise<Buffer>((resolve, reject) => {
    const doc = new PDFDocument({ size: 'A4', margin: 0, compress: true, info: { Title: 'WCC Character Sheet', Producer: 'WCC Cloud PDF Engine (pdfkit)' } });
    const chunks: Buffer[] = [];
    doc.on('data', (c) => chunks.push(Buffer.isBuffer(c) ? c : Buffer.from(c)));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);
    try { build(doc); doc.end(); } catch (e) { reject(e); }
  });
}

export async function generateCharacterPdfBuffer(params: {
  rawCharacter: Record<string, unknown>;
  resolvedCharacter: Record<string, unknown>;
  lang: Lang;
  skillsCatalogById?: ReadonlyMap<string, SkillCatalogLite>;
}): Promise<Buffer> {
  const vm = buildVmWithCatalog(
    params.resolvedCharacter,
    params.rawCharacter,
    params.lang,
    params.skillsCatalogById,
  );
  return createPdfBuffer((doc) => new Painter(doc).draw(vm));
}

