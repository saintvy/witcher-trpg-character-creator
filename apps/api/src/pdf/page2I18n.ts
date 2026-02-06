import crypto from 'node:crypto';
import { db } from '../db/pool.js';

type DeepKeyTree = { [k: string]: string | DeepKeyTree };

const CK_ID_NAMESPACE = '12345678-9098-7654-3212-345678909876';

function ck_id(src: string): string {
  const hash = crypto.createHash('md5').update(CK_ID_NAMESPACE + src).digest('hex');
  return (
    hash.substring(0, 8) +
    '-' +
    hash.substring(8, 12) +
    '-' +
    hash.substring(12, 16) +
    '-' +
    hash.substring(16, 20) +
    '-' +
    hash.substring(20, 32)
  );
}

function collectLeafStrings(tree: DeepKeyTree, out: Set<string>): void {
  for (const v of Object.values(tree)) {
    if (typeof v === 'string') out.add(v);
    else collectLeafStrings(v, out);
  }
}

function mapLeafStrings<T extends DeepKeyTree>(tree: T, mapFn: (value: string) => string): any {
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(tree)) {
    if (typeof v === 'string') out[k] = mapFn(v);
    else out[k] = mapLeafStrings(v, mapFn);
  }
  return out;
}

function page2Key(key: string): string {
  return `witcher_cc.pdf.page2.${key}`;
}

const PAGE2_KEYS = {
  section: {
    lore: page2Key('section.lore'),
    socialStatus: page2Key('section.socialStatus'),
    lifePath: page2Key('section.lifePath'),
    style: page2Key('section.style'),
    values: page2Key('section.values'),
    siblings: page2Key('section.siblings'),
    allies: page2Key('section.allies'),
    enemies: page2Key('section.enemies'),
  },
  lore: {
    homeland: page2Key('lore.homeland'),
    homeLanguage: page2Key('lore.homeLanguage'),
    familyStatus: page2Key('lore.familyStatus'),
    familyFate: page2Key('lore.familyFate'),
    parentsFateWho: page2Key('lore.parentsFateWho'),
    parentsFate: page2Key('lore.parentsFate'),
    friend: page2Key('lore.friend'),
    school: page2Key('lore.school'),
    witcherInitiationMoment: page2Key('lore.witcherInitiationMoment'),
    diseasesAndCurses: page2Key('lore.diseasesAndCurses'),
    mostImportantEvent: page2Key('lore.mostImportantEvent'),
    trainings: page2Key('lore.trainings'),
    currentSituation: page2Key('lore.currentSituation'),
    style: page2Key('lore.style'),
    values: page2Key('lore.values'),
  },
  tables: {
    socialStatus: {
      statusEqual: page2Key('tables.socialStatus.status.equal'),
      statusTolerated: page2Key('tables.socialStatus.status.tolerated'),
      statusHated: page2Key('tables.socialStatus.status.hated'),
      statusFeared: page2Key('tables.socialStatus.status.feared'),
      and: page2Key('tables.socialStatus.and'),
      reputationLabel: page2Key('tables.socialStatus.reputationLabel'),
    },
    lifeEvents: {
      colPeriod: page2Key('tables.lifeEvents.col.period'),
      colType: page2Key('tables.lifeEvents.col.type'),
      colDesc: page2Key('tables.lifeEvents.col.desc'),
    },
    style: {
      colClothing: page2Key('tables.style.col.clothing'),
      colPersonality: page2Key('tables.style.col.personality'),
      colHairStyle: page2Key('tables.style.col.hairStyle'),
      colAffectations: page2Key('tables.style.col.affectations'),
    },
    values: {
      colValuedPerson: page2Key('tables.values.col.valuedPerson'),
      colValue: page2Key('tables.values.col.value'),
      colFeelingsOnPeople: page2Key('tables.values.col.feelingsOnPeople'),
    },
    siblings: {
      colAge: page2Key('tables.siblings.col.age'),
      colGender: page2Key('tables.siblings.col.gender'),
      colAttitude: page2Key('tables.siblings.col.attitude'),
      colPersonality: page2Key('tables.siblings.col.personality'),
    },
    allies: {
      colGender: page2Key('tables.allies.col.gender'),
      colPosition: page2Key('tables.allies.col.position'),
      colWhere: page2Key('tables.allies.col.where'),
      colAcquaintance: page2Key('tables.allies.col.acquaintance'),
      colHowMet: page2Key('tables.allies.col.howMet'),
      colHowClose: page2Key('tables.allies.col.howClose'),
      colAlive: page2Key('tables.allies.col.alive'),
    },
    enemies: {
      colGender: page2Key('tables.enemies.col.gender'),
      colPosition: page2Key('tables.enemies.col.position'),
      colVictim: page2Key('tables.enemies.col.victim'),
      colCause: page2Key('tables.enemies.col.cause'),
      colPower: page2Key('tables.enemies.col.power'),
      colLevel: page2Key('tables.enemies.col.level'),
      colResult: page2Key('tables.enemies.col.result'),
      colAlive: page2Key('tables.enemies.col.alive'),
      colHowFar: page2Key('tables.enemies.col.howFar'),
    },
  },
} satisfies DeepKeyTree;

const PAGE2_FALLBACK: Record<string, { ru: string; en: string }> = {
  'witcher_cc.pdf.page2.section.lore': { ru: 'Лор', en: 'Lore' },
  'witcher_cc.pdf.page2.section.socialStatus': { ru: 'Социальный статус', en: 'Social status' },
  'witcher_cc.pdf.page2.section.lifePath': { ru: 'Жизненный путь', en: 'Life path' },
  'witcher_cc.pdf.page2.section.style': { ru: 'Стиль', en: 'Style' },
  'witcher_cc.pdf.page2.section.values': { ru: 'Ценности', en: 'Values' },
  'witcher_cc.pdf.page2.section.siblings': { ru: 'Братья и сёстры', en: 'Siblings' },
  'witcher_cc.pdf.page2.section.allies': { ru: 'Союзники', en: 'Allies' },
  'witcher_cc.pdf.page2.section.enemies': { ru: 'Враги', en: 'Enemies' },

  'witcher_cc.pdf.page2.lore.homeland': { ru: 'Родина', en: 'Homeland' },
  'witcher_cc.pdf.page2.lore.homeLanguage': { ru: 'Родной язык', en: 'Home language' },
  'witcher_cc.pdf.page2.lore.familyStatus': { ru: 'Статус семьи', en: 'Family status' },
  'witcher_cc.pdf.page2.lore.familyFate': { ru: 'Судьба семьи', en: 'Family fate' },
  'witcher_cc.pdf.page2.lore.parentsFateWho': { ru: 'Родители', en: 'Parents' },
  'witcher_cc.pdf.page2.lore.parentsFate': { ru: 'Судьба родителей', en: 'Parents fate' },
  'witcher_cc.pdf.page2.lore.friend': { ru: 'Друг', en: 'Friend' },
  'witcher_cc.pdf.page2.lore.school': { ru: 'Школа', en: 'School' },
  'witcher_cc.pdf.page2.lore.witcherInitiationMoment': { ru: 'Становление ведьмаком', en: 'Becoming a witcher' },
  'witcher_cc.pdf.page2.lore.diseasesAndCurses': { ru: 'Болезни и проклятия', en: 'Diseases & curses' },
  'witcher_cc.pdf.page2.lore.mostImportantEvent': { ru: 'Самое важное событие', en: 'Most important event' },
  'witcher_cc.pdf.page2.lore.trainings': { ru: 'Обучение', en: 'Trainings' },
  'witcher_cc.pdf.page2.lore.currentSituation': { ru: 'Текущая ситуация', en: 'Current situation' },
  'witcher_cc.pdf.page2.lore.style': { ru: 'Стиль', en: 'Style' },
  'witcher_cc.pdf.page2.lore.values': { ru: 'Ценности', en: 'Values' },

  'witcher_cc.pdf.page2.tables.lifeEvents.col.period': { ru: 'Период', en: 'Period' },
  'witcher_cc.pdf.page2.tables.lifeEvents.col.type': { ru: 'Тип', en: 'Type' },
  'witcher_cc.pdf.page2.tables.lifeEvents.col.desc': { ru: 'Описание', en: 'Description' },

  'witcher_cc.pdf.page2.tables.style.col.clothing': { ru: 'Одежда', en: 'Clothing' },
  'witcher_cc.pdf.page2.tables.style.col.personality': { ru: 'Характер', en: 'Personality' },
  'witcher_cc.pdf.page2.tables.style.col.hairStyle': { ru: 'Причёска', en: 'Hairstyle' },
  'witcher_cc.pdf.page2.tables.style.col.affectations': { ru: 'Украшения', en: 'Affectations' },
  'witcher_cc.pdf.page2.tables.values.col.valuedPerson': { ru: 'Кого ценит', en: 'Valued person' },
  'witcher_cc.pdf.page2.tables.values.col.value': { ru: 'Что ценит', en: 'Value' },
  'witcher_cc.pdf.page2.tables.values.col.feelingsOnPeople': { ru: 'Мысли об окружающих', en: 'Feelings on people' },

  'witcher_cc.pdf.page2.tables.siblings.col.age': { ru: 'Возраст', en: 'Age' },
  'witcher_cc.pdf.page2.tables.siblings.col.gender': { ru: 'Пол', en: 'Sex' },
  'witcher_cc.pdf.page2.tables.siblings.col.attitude': { ru: 'Отношение', en: 'Attitude' },
  'witcher_cc.pdf.page2.tables.siblings.col.personality': { ru: 'Характер', en: 'Personality' },

  'witcher_cc.pdf.page2.tables.allies.col.gender': { ru: 'Пол', en: 'Sex' },
  'witcher_cc.pdf.page2.tables.allies.col.position': { ru: 'Кто', en: 'Who' },
  'witcher_cc.pdf.page2.tables.allies.col.where': { ru: 'Где он сейчас', en: 'Where now' },
  'witcher_cc.pdf.page2.tables.allies.col.acquaintance': { ru: 'Знакомство', en: 'Acquaintance' },
  'witcher_cc.pdf.page2.tables.allies.col.howMet': { ru: 'Как встретились', en: 'How met' },
  'witcher_cc.pdf.page2.tables.allies.col.howClose': { ru: 'Близость', en: 'Closeness' },
  'witcher_cc.pdf.page2.tables.allies.col.alive': { ru: 'Жив ли', en: 'Alive' },

  'witcher_cc.pdf.page2.tables.enemies.col.gender': { ru: 'Пол', en: 'Sex' },
  'witcher_cc.pdf.page2.tables.enemies.col.position': { ru: 'Кто', en: 'Who' },
  'witcher_cc.pdf.page2.tables.enemies.col.victim': { ru: 'Жертва', en: 'Victim' },
  'witcher_cc.pdf.page2.tables.enemies.col.cause': { ru: 'Причина', en: 'Cause' },
  'witcher_cc.pdf.page2.tables.enemies.col.power': { ru: 'Сила', en: 'Power' },
  'witcher_cc.pdf.page2.tables.enemies.col.level': { ru: 'Мощь', en: 'Level' },
  'witcher_cc.pdf.page2.tables.enemies.col.result': { ru: 'Итог', en: 'Result' },
  'witcher_cc.pdf.page2.tables.enemies.col.alive': { ru: 'Жив ли', en: 'Alive' },
  'witcher_cc.pdf.page2.tables.enemies.col.howFar': { ru: 'Насколько далеко', en: 'How far' },
  'witcher_cc.pdf.page2.tables.socialStatus.status.equal': { ru: 'Равенство', en: 'Equal' },
  'witcher_cc.pdf.page2.tables.socialStatus.status.tolerated': { ru: 'Терпимость', en: 'Tolerated' },
  'witcher_cc.pdf.page2.tables.socialStatus.status.hated': { ru: 'Ненависть', en: 'Hated' },
  'witcher_cc.pdf.page2.tables.socialStatus.status.feared': { ru: 'Опасение', en: 'Feared' },
  'witcher_cc.pdf.page2.tables.socialStatus.and': { ru: ' и ', en: ' and ' },
  'witcher_cc.pdf.page2.tables.socialStatus.reputationLabel': { ru: 'Репутация', en: 'Reputation' },
};

export type CharacterPdfPage2I18n = {
  lang: string;
  section: { lore: string; socialStatus: string; lifePath: string; style: string; values: string; siblings: string; allies: string; enemies: string };
  lore: {
    homeland: string;
    homeLanguage: string;
    familyStatus: string;
    familyFate: string;
    parentsFateWho: string;
    parentsFate: string;
    friend: string;
    school: string;
    witcherInitiationMoment: string;
    diseasesAndCurses: string;
    mostImportantEvent: string;
    trainings: string;
    currentSituation: string;
    style: string;
    values: string;
  };
  tables: {
    socialStatus: { statusEqual: string; statusTolerated: string; statusHated: string; statusFeared: string; and: string; reputationLabel: string };
    lifeEvents: { colPeriod: string; colType: string; colDesc: string };
    style: { colClothing: string; colPersonality: string; colHairStyle: string; colAffectations: string };
    values: { colValuedPerson: string; colValue: string; colFeelingsOnPeople: string };
    siblings: { colAge: string; colGender: string; colAttitude: string; colPersonality: string };
    allies: { colGender: string; colPosition: string; colWhere: string; colAcquaintance: string; colHowMet: string; colHowClose: string; colAlive: string };
    enemies: { colGender: string; colPosition: string; colVictim: string; colCause: string; colPower: string; colLevel: string; colResult: string; colAlive: string; colHowFar: string };
  };
};

type I18nRow = { id: string; lang: string; text: string };

export async function loadCharacterPdfPage2I18n(lang: string): Promise<CharacterPdfPage2I18n> {
  const keySet = new Set<string>();
  collectLeafStrings(PAGE2_KEYS, keySet);
  const keys = Array.from(keySet);

  const ids = keys.map((k) => ck_id(k));
  const languages = Array.from(new Set([lang, 'en']));

  const { rows } = await db.query<I18nRow>(
    `
      SELECT id::text, lang, text
      FROM i18n_text
      WHERE id = ANY($1::uuid[]) AND lang = ANY($2::text[])
    `,
    [ids, languages],
  );

  const byId = new Map<string, Record<string, string>>();
  for (const r of rows) {
    const rec = byId.get(r.id) ?? {};
    rec[r.lang] = r.text;
    byId.set(r.id, rec);
  }

  const keyToId = new Map<string, string>();
  keys.forEach((k, idx) => keyToId.set(k, ids[idx]));

  const resolve = (key: string): string => {
    const id = keyToId.get(key);
    if (!id) return key;
    const rec = byId.get(id);
    if (rec?.[lang]) return rec[lang];
    if (lang !== 'en' && rec?.['en']) return rec['en'];
    const fb = PAGE2_FALLBACK[key];
    if (fb) return lang === 'ru' ? fb.ru : fb.en;
    return key;
  };

  const translated = mapLeafStrings(PAGE2_KEYS, resolve) as Omit<CharacterPdfPage2I18n, 'lang'>;
  return { lang, ...(translated as any) };
}
