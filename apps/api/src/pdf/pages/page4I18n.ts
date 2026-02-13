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

// Reuse the same i18n keys as in magic shop (node 096) so columns match 1:1.
const PAGE4_KEYS = {
  source: {
    magicSpellsTitle: 'witcher_cc.wcc_shop.source.magic_spells.title',
    magicSignsTitle: 'witcher_cc.wcc_shop.source.magic_signs.title',
    magicHexesTitle: 'witcher_cc.wcc_shop.source.magic_hexes.title',
    magicRitualsTitle: 'witcher_cc.wcc_shop.source.magic_rituals.title',
    invocationsPriestTitle: 'witcher_cc.wcc_shop.source.invocations_priest.title',
    invocationsDruidTitle: 'witcher_cc.pdf.page4.invocations_druid.title',
    magicGiftsTitle: 'witcher_cc.wcc_shop.source.magic_gifts.title',
  },
  effects: {
    title: 'witcher_cc.pdf.page4.effects.title',
  },
  column: {
    name: 'witcher_cc.wcc_shop.column.name',
    element: 'witcher_cc.wcc_shop.column.element',
    level: 'witcher_cc.wcc_shop.column.level',
    group: 'witcher_cc.wcc_shop.column.group',
    staminaCast: 'witcher_cc.wcc_shop.column.stamina_cast',
    staminaKeeping: 'witcher_cc.wcc_shop.column.stamina_keeping',
    damage: 'witcher_cc.wcc_shop.column.damage',
    distance: 'witcher_cc.wcc_shop.column.distance',
    zoneSize: 'witcher_cc.wcc_shop.column.zone_size',
    form: 'witcher_cc.wcc_shop.column.form',
    preparingTime: 'witcher_cc.wcc_shop.column.preparing_time',
    dc: 'witcher_cc.wcc_shop.column.difficulty_check',
    effectTime: 'witcher_cc.wcc_shop.column.time_effect',
  },
  gifts: {
    colName: 'witcher_cc.pdf.page4.gifts.col.name',
    colGroup: 'witcher_cc.pdf.page4.gifts.col.group',
    colSl: 'witcher_cc.pdf.page4.gifts.col.sl',
    colVigor: 'witcher_cc.pdf.page4.gifts.col.vigor',
    colCost: 'witcher_cc.pdf.page4.gifts.col.cost',
    costAction: 'witcher_cc.pdf.page4.gifts.cost.action',
    costFullAction: 'witcher_cc.pdf.page4.gifts.cost.fullAction',
  },
} satisfies DeepKeyTree;

export type CharacterPdfPage4I18n = {
  lang: string;
  source: {
    magicSpellsTitle: string;
    magicSignsTitle: string;
    magicHexesTitle: string;
    magicRitualsTitle: string;
    invocationsPriestTitle: string;
    invocationsDruidTitle: string;
    magicGiftsTitle: string;
  };
  effects: {
    title: string;
  };
  column: {
    name: string;
    element: string;
    level: string;
    group: string;
    staminaCast: string;
    staminaKeeping: string;
    damage: string;
    distance: string;
    zoneSize: string;
    form: string;
    preparingTime: string;
    dc: string;
    effectTime: string;
  };
  gifts: {
    colName: string;
    colGroup: string;
    colSl: string;
    colVigor: string;
    colCost: string;
    costAction: string;
    costFullAction: string;
  };
};

type I18nRow = { id: string; lang: string; text: string };

export async function loadCharacterPdfPage4I18n(lang: string): Promise<CharacterPdfPage4I18n> {
  const keySet = new Set<string>();
  collectLeafStrings(PAGE4_KEYS, keySet);
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

  const translated = mapLeafStrings(PAGE4_KEYS, resolve) as Omit<CharacterPdfPage4I18n, 'lang'>;
  return { lang, ...(translated as any) };
}
