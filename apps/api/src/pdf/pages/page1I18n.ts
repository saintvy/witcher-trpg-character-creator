import crypto from 'node:crypto';
import { db } from '../../db/pool.js';

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

function page1Key(key: string): string {
  return `witcher_cc.pdf.page1.${key}`;
}

const PAGE1_KEYS = {
  titleSuffix: page1Key('titleSuffix'),
  defaults: {
    characterName: page1Key('defaults.characterName'),
    branchTitle: page1Key('defaults.branchTitle'),
  },
  section: {
    baseData: page1Key('section.baseData'),
    consumables: page1Key('section.consumables'),
    avatar: page1Key('section.avatar'),
    professional: page1Key('section.professional'),
    mainParams: page1Key('section.mainParams'),
    extraParams: page1Key('section.extraParams'),
  },
  base: {
    name: page1Key('base.name'),
    race: page1Key('base.race'),
    gender: page1Key('base.gender'),
    age: page1Key('base.age'),
    profession: page1Key('base.profession'),
    definingSkill: page1Key('base.definingSkill'),
  },
  derived: {
    run: page1Key('derived.run'),
    leap: page1Key('derived.leap'),
    stability: page1Key('derived.stability'),
    rest: page1Key('derived.rest'),
    punch: page1Key('derived.punch'),
    kick: page1Key('derived.kick'),
    vigor: page1Key('derived.vigor'),
  },
  stats: {
    abbr: {
      INT: page1Key('stats.abbr.INT'),
      REF: page1Key('stats.abbr.REF'),
      DEX: page1Key('stats.abbr.DEX'),
      BODY: page1Key('stats.abbr.BODY'),
      SPD: page1Key('stats.abbr.SPD'),
      EMP: page1Key('stats.abbr.EMP'),
      CRA: page1Key('stats.abbr.CRA'),
      WILL: page1Key('stats.abbr.WILL'),
    },
    name: {
      INT: page1Key('stats.name.INT'),
      REF: page1Key('stats.name.REF'),
      DEX: page1Key('stats.name.DEX'),
      BODY: page1Key('stats.name.BODY'),
      SPD: page1Key('stats.name.SPD'),
      EMP: page1Key('stats.name.EMP'),
      CRA: page1Key('stats.name.CRA'),
      WILL: page1Key('stats.name.WILL'),
      OTHER: page1Key('stats.name.OTHER'),
    },
  },
  consumables: {
    colParameter: page1Key('consumables.col.parameter'),
    colMax: page1Key('consumables.col.max'),
    colCur: page1Key('consumables.col.cur'),
    label: {
      carry: page1Key('consumables.label.carry'),
      hp: page1Key('consumables.label.hp'),
      sta: page1Key('consumables.label.sta'),
      resolve: page1Key('consumables.label.resolve'),
      luck: page1Key('consumables.label.luck'),
    },
  },
  skills: {
    languagePrefix: page1Key('skills.languagePrefix'),
    languageCommonSpeech: page1Key('skills.language.commonSpeech'),
    languageElderSpeech: page1Key('skills.language.elderSpeech'),
    languageDwarvish: page1Key('skills.language.dwarvish'),
  },
  avatarPlaceholder: page1Key('avatar.placeholder'),
  tables: {
    perks: {
      colPerk: page1Key('tables.perks.col.perk'),
      colEffect: page1Key('tables.perks.col.effect'),
    },
    weapons: {
      title: page1Key('tables.weapons.title'),
      colCheck: page1Key('tables.weapons.col.check'),
      colQty: page1Key('tables.weapons.col.qty'),
      colDmg: page1Key('tables.weapons.col.dmg'),
      colType: page1Key('tables.weapons.col.type'),
      colReliability: page1Key('tables.weapons.col.reliability'),
      colHands: page1Key('tables.weapons.col.hands'),
      colConcealment: page1Key('tables.weapons.col.concealment'),
      colEnh: page1Key('tables.weapons.col.enhancements'),
      colWeight: page1Key('tables.weapons.col.weight'),
      colPrice: page1Key('tables.weapons.col.price'),
    },
    armors: {
      title: page1Key('tables.armors.title'),
      colCheck: page1Key('tables.armors.col.check'),
      colQty: page1Key('tables.armors.col.qty'),
      colSp: page1Key('tables.armors.col.sp'),
      colEnc: page1Key('tables.armors.col.enc'),
      colEnh: page1Key('tables.armors.col.enhancements'),
      colWeight: page1Key('tables.armors.col.weight'),
      colPrice: page1Key('tables.armors.col.price'),
    },
    potions: {
      title: page1Key('tables.potions.title'),
      colQty: page1Key('tables.potions.col.qty'),
      colName: page1Key('tables.potions.col.name'),
      colTox: page1Key('tables.potions.col.tox'),
      colTime: page1Key('tables.potions.col.time'),
      colEffect: page1Key('tables.potions.col.effect'),
      colWeight: page1Key('tables.potions.col.weight'),
      colPrice: page1Key('tables.potions.col.price'),
    },
    magic: {
      colType: page1Key('tables.magic.col.type'),
      colName: page1Key('tables.magic.col.name'),
      colElement: page1Key('tables.magic.col.element'),
      colVigor: page1Key('tables.magic.col.vigor'),
      colVigorKeep: page1Key('tables.magic.col.vigorKeep'),
      colDamage: page1Key('tables.magic.col.damage'),
      colTime: page1Key('tables.magic.col.time'),
      colDistance: page1Key('tables.magic.col.distance'),
      colSize: page1Key('tables.magic.col.size'),
      colForm: page1Key('tables.magic.col.form'),
    },
    notes: {
      title: page1Key('tables.notes.title'),
    },
  },
  magicType: {
    sign: page1Key('magic.type.sign'),
    spell: page1Key('magic.type.spell'),
    invocation: page1Key('magic.type.invocation'),
  },
} satisfies DeepKeyTree;

export type CharacterPdfPage1I18n = {
  lang: string;
  titleSuffix: string;
  defaults: { characterName: string; branchTitle: string };
  section: {
    baseData: string;
    consumables: string;
    avatar: string;
    professional: string;
    mainParams: string;
    extraParams: string;
  };
  base: { name: string; race: string; gender: string; age: string; profession: string; definingSkill: string };
  derived: { run: string; leap: string; stability: string; rest: string; punch: string; kick: string; vigor: string };
  stats: {
    abbr: { INT: string; REF: string; DEX: string; BODY: string; SPD: string; EMP: string; CRA: string; WILL: string };
    name: { INT: string; REF: string; DEX: string; BODY: string; SPD: string; EMP: string; CRA: string; WILL: string; OTHER: string };
  };
  consumables: {
    colParameter: string;
    colMax: string;
    colCur: string;
    label: { carry: string; hp: string; sta: string; resolve: string; luck: string };
  };
  skills: { languagePrefix: string; languageCommonSpeech: string; languageElderSpeech: string; languageDwarvish: string };
  avatarPlaceholder: string;
  tables: {
    perks: { colPerk: string; colEffect: string };
    weapons: {
      title: string;
      colCheck: string;
      colQty: string;
      colDmg: string;
      colType: string;
      colReliability: string;
      colHands: string;
      colConcealment: string;
      colEnh: string;
      colWeight: string;
      colPrice: string;
    };
    armors: { title: string; colCheck: string; colQty: string; colSp: string; colEnc: string; colEnh: string; colWeight: string; colPrice: string };
    potions: { title: string; colQty: string; colName: string; colTox: string; colTime: string; colEffect: string; colWeight: string; colPrice: string };
    magic: {
      colType: string;
      colName: string;
      colElement: string;
      colVigor: string;
      colVigorKeep: string;
      colDamage: string;
      colTime: string;
      colDistance: string;
      colSize: string;
      colForm: string;
    };
    notes: { title: string };
  };
  magicType: { sign: string; spell: string; invocation: string };
};

type I18nRow = { id: string; lang: string; text: string };

export async function loadCharacterPdfPage1I18n(lang: string): Promise<CharacterPdfPage1I18n> {
  const keySet = new Set<string>();
  collectLeafStrings(PAGE1_KEYS, keySet);
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
    return key;
  };

  const translated = mapLeafStrings(PAGE1_KEYS, resolve) as Omit<CharacterPdfPage1I18n, 'lang'>;
  return { lang, ...(translated as any) };
}
