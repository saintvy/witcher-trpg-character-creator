import type { CharacterPdfPage2I18n } from './page2I18n.js';

export type EnemyRow = {
  gender: string;
  position: string;
  victim: string;
  cause: string;
  power: string;
  level: string;
  result: string;
  alive: string;
};

export type SocialStatusGroup = { groupName: string; statusLabel: string; isFeared: boolean };

export type CharacterPdfPage2Vm = {
  i18n: CharacterPdfPage2I18n;
  loreBlocks: Array<{ label: string; html: string }>;
  socialStatusTable: { groups: SocialStatusGroup[]; reputation: number };
  styleTable: { clothing: string; personality: string; hairStyle: string; affectations: string };
  valuesTable: { valuedPerson: string; value: string; feelingsOnPeople: string };
  lifeEvents: Array<{ period: string; type: string; description: string }>;
  siblings: Array<{ age: string; gender: string; attitude: string; personality: string }>;
  allies: Array<{ gender: string; position: string; where: string; howMet: string; howClose: string; isAlive: string }>;
  alliesIsWitcher: boolean;
  enemiesIsWitcher: boolean;
  enemies: EnemyRow[];
};

function asRecord(value: unknown): Record<string, unknown> | null {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) return null;
  return value as Record<string, unknown>;
}

function asString(value: unknown): string {
  if (value === null || value === undefined) return '';
  if (typeof value === 'string') return value;
  if (typeof value === 'number') return Number.isFinite(value) ? String(value) : '';
  if (typeof value === 'boolean') return value ? 'true' : 'false';
  try {
    return JSON.stringify(value);
  } catch {
    return '';
  }
}

function asNumber(value: unknown): number | null {
  if (value === null || value === undefined) return null;
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string') {
    const n = Number(value);
    return Number.isFinite(n) ? n : null;
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

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

function renderRichText(value: string): string {
  // allow only a tiny subset of tags already used in content packs
  const safe = escapeHtml(value);
  return safe
    .replaceAll(/&lt;br\s*\/?&gt;/gi, '<br>')
    .replaceAll(/&lt;\/?(b|strong)&gt;/gi, (m) => m.replace('&lt;', '<').replace('&gt;', '>'))
    .replaceAll(/&lt;\/?(i|em)&gt;/gi, (m) => m.replace('&lt;', '<').replace('&gt;', '>'));
}

function paragraph(label: string, value: string): { label: string; html: string } | null {
  const v = value.trim();
  if (!v) return null;
  return { label, html: `<div class="p"><span class="p-k">${escapeHtml(label)}:</span> <span class="p-v">${renderRichText(v)}</span></div>` };
}

function joinParagraphs(items: Array<{ label: string; html: string }>): Array<{ label: string; html: string }> {
  // Combine into one block "Lore" later; keep pre-rendered paragraphs here.
  return items;
}

export function mapCharacterJsonToPage2Vm(
  characterJson: unknown,
  deps: {
    i18n: CharacterPdfPage2I18n;
  },
): CharacterPdfPage2Vm {
  const i18n = deps.i18n;

  const lore = asRecord(getPath(characterJson, 'lore')) ?? {};

  const blocks: Array<{ label: string; html: string }> = [];
  const paragraphs: Array<{ label: string; html: string }> = [];

  const homeland = asString(lore.homeland);
  const homeLanguage = asString(lore.home_language);
  const familyStatus = asString(lore.family_status);
  const familyFate = asString(lore.family_fate);
  const parentsFateWho = asString(lore.parents_fate_who);
  const parentsFate = asString(lore.parents_fate);
  const friend = asString(lore.friend);
  const school = asString(lore.school);
  const witcherInitiationMoment = asString(lore.witcher_initiation_moment);

  const style = asRecord(lore.style);
  const styleParts = [
    asString(style?.clothing),
    asString(style?.personality),
    asString(style?.hair_style),
    asString(style?.affectations),
  ].filter(Boolean);

  const values = asRecord(lore.values);
  const valueParts = [
    asString(values?.valued_person),
    asString(values?.value),
    asString(values?.feelings_on_people),
  ].filter(Boolean);

  const diseasesAndCurses = Array.isArray(lore.diseases_and_curses)
    ? (lore.diseases_and_curses as unknown[]).map(asString).filter(Boolean).join('<br>')
    : asString(lore.diseases_and_curses);

  const add = (p: { label: string; html: string } | null) => {
    if (p) paragraphs.push(p);
  };

  add(paragraph(i18n.lore.homeland, homeland));
  add(paragraph(i18n.lore.homeLanguage, homeLanguage));
  add(paragraph(i18n.lore.familyStatus, familyStatus));
  add(paragraph(i18n.lore.familyFate, familyFate));
  if (parentsFateWho || parentsFate) {
    const who = parentsFateWho ? `${escapeHtml(parentsFateWho)}. ` : '';
    add(paragraph(i18n.lore.parentsFate, `${who}${parentsFate}`));
  }
  add(paragraph(i18n.lore.friend, friend));
  add(paragraph(i18n.lore.school, school));
  add(paragraph(i18n.lore.witcherInitiationMoment, witcherInitiationMoment));
  add(paragraph(i18n.lore.diseasesAndCurses, diseasesAndCurses));
  add(paragraph(i18n.lore.mostImportantEvent, asString(lore.most_important_event)));
  add(paragraph(i18n.lore.trainings, asString(lore.trainings)));
  add(paragraph(i18n.lore.currentSituation, asString(lore.current_situation)));

  blocks.push(...joinParagraphs(paragraphs));

  const styleTable = {
    clothing: asString(style?.clothing),
    personality: asString(style?.personality),
    hairStyle: asString(style?.hair_style),
    affectations: asString(style?.affectations),
  };
  const valuesTable = {
    valuedPerson: asString(values?.valued_person),
    value: asString(values?.value),
    feelingsOnPeople: asString(values?.feelings_on_people),
  };

  const lifeEvents = Array.isArray(lore.lifeEvents)
    ? (lore.lifeEvents as unknown[])
        .map((e) => {
          const rec = asRecord(e) ?? {};
          return {
            period: asString(rec.timePeriod),
            type: asString(rec.eventType),
            description: asString(rec.description),
          };
        })
        .filter((e) => e.period || e.type || e.description)
    : [];

  const siblings = Array.isArray(lore.siblings)
    ? (lore.siblings as unknown[])
        .map((s) => {
          const rec = asRecord(s) ?? {};
          return {
            age: asString(rec.age),
            gender: asString(rec.gender),
            attitude: asString(rec.attitude),
            personality: asString(rec.personality),
          };
        })
        .filter((s) => s.age || s.gender || s.attitude || s.personality)
    : [];

  const root = asRecord(characterJson);
  const logicFields = asRecord(root?.logicFields ?? getPath(characterJson, 'characterRaw.logicFields'));
  const isWitcher = asString(logicFields?.race) === 'Witcher';

  const socialStatusRaw = Array.isArray(root?.social_status)
    ? root.social_status
    : Array.isArray(getPath(characterJson, 'characterRaw.social_status'))
      ? getPath(characterJson, 'characterRaw.social_status')
      : [];
  const repVal = getPath(characterJson, 'reputation') ?? root?.reputation ?? getPath(characterJson, 'characterRaw.reputation');
  const reputation = asNumber(repVal) ?? 0;
  const statusLabels = [
    i18n.tables.socialStatus.statusHated,
    i18n.tables.socialStatus.statusTolerated,
    i18n.tables.socialStatus.statusEqual,
  ];
  const socialStatusTable = {
    groups: (socialStatusRaw as unknown[])
      .map((s) => {
        const rec = asRecord(s) ?? {};
        const groupName = asString(rec.group_name);
        const st = asNumber(rec.group_status);
        const isFeared = rec.group_is_feared === true || asString(rec.group_is_feared) === 'true';
        const idx = st === 1 ? 0 : st === 2 ? 1 : 2;
        const statusLabel = statusLabels[idx] ?? statusLabels[2];
        return { groupName, statusLabel, isFeared };
      })
      .filter((g) => g.groupName),
    reputation: Number.isFinite(reputation) ? reputation : 0,
  };

  const alliesRoot = Array.isArray(root?.allies)
    ? root.allies
    : Array.isArray(getPath(characterJson, 'characterRaw.allies'))
      ? getPath(characterJson, 'characterRaw.allies')
      : [];
  const allies = Array.isArray(alliesRoot)
    ? (alliesRoot as unknown[])
        .map((a) => {
          const rec = asRecord(a) ?? {};
          const aliveVal = asString(rec.is_alive);
          const deathReason = asString(rec.death_reason);
          const isAlive = deathReason ? `${aliveVal} - ${deathReason}` : aliveVal;
          return {
            gender: asString(rec.gender),
            position: asString(rec.position),
            where: asString(rec.where),
            howMet: asString(rec.how_met),
            howClose: asString(rec.how_close),
            isAlive,
          };
        })
        .filter((a) => a.gender || a.position || a.where || a.howMet || a.howClose || a.isAlive)
    : [];
  const enemiesRoot = Array.isArray(root?.enemies)
    ? root.enemies
    : Array.isArray(getPath(characterJson, 'characterRaw.enemies'))
      ? getPath(characterJson, 'characterRaw.enemies')
      : [];
  const enemies: EnemyRow[] = Array.isArray(enemiesRoot)
    ? (enemiesRoot as unknown[])
        .map((e) => {
          const rec = asRecord(e) ?? {};
          if (isWitcher) {
            const aliveVal = asString(rec.is_alive);
            const deathReason = asString(rec.death_reason);
            const alive = deathReason ? `${aliveVal} — ${deathReason}` : aliveVal;
            return {
              gender: asString(rec.gender),
              position: asString(rec.position),
              victim: '',
              cause: asString(rec.the_cause),
              power: asString(rec.power),
              level: '',
              result: asString(rec.escalation_level),
              alive,
            };
          }
          return {
            gender: asString(rec.gender),
            position: asString(rec.position),
            victim: asString(rec.victim),
            cause: asString(rec.cause),
            power: asString(rec.the_power),
            level: asString(rec.power_level),
            result: asString(rec.how_far),
            alive: '',
          };
        })
        .filter(
          (e) =>
            e.gender ||
            e.position ||
            e.victim ||
            e.cause ||
            e.power ||
            e.level ||
            e.result ||
            e.alive,
        )
    : [];

  return {
    i18n,
    loreBlocks: blocks,
    socialStatusTable,
    styleTable,
    valuesTable,
    lifeEvents,
    siblings,
    allies,
    alliesIsWitcher: isWitcher,
    enemiesIsWitcher: isWitcher,
    enemies,
  };
}
