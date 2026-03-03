import crypto from 'node:crypto';
import { db } from '@wcc/core';

type DeepKeyTree = { [k: string]: string | DeepKeyTree };

const CK_ID_NAMESPACE = '348ce630-ac0d-49e3-8d22-d7a2aa677825';

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

function normalizeResolvedText(value: string): string {
  return String(value ?? '').replace(/<br\s*\/?>/gi, '\n').replace(/\r\n?/g, '\n').trim();
}

const CLOUD_PDF_EXTRA_KEYS = {
  subtitle: 'witcher_cc.pdf.cloud.subtitle',
  baseWord: 'witcher_cc.pdf.cloud.base_word',
  cols: {
    value: 'witcher_cc.pdf.cloud.cols.value',
    bonus: 'witcher_cc.pdf.cloud.cols.bonus',
    field: 'witcher_cc.pdf.cloud.cols.field',
    note: 'witcher_cc.pdf.cloud.cols.note',
  },
  sections: {
    skills: 'witcher_cc.pdf.cloud.sections.skills',
    perks: 'witcher_cc.pdf.cloud.sections.perks',
    magic: 'witcher_cc.pdf.cloud.sections.magic',
  },
  stats: {
    abbr: {
      LUCK: 'witcher_cc.pdf.cloud.stats.abbr.LUCK',
      VIGOR: 'witcher_cc.pdf.cloud.stats.abbr.VIGOR',
    },
  },
  prof: {
    branchCol: 'witcher_cc.pdf.cloud.prof.branch_col',
  },
  page4: {
    titles: {
      spellsSigns: 'witcher_cc.pdf.cloud.page4.titles.spells_signs',
    },
    cols: {
      ingredients: 'witcher_cc.pdf.cloud.page4.cols.ingredients',
      removeComponents: 'witcher_cc.pdf.cloud.page4.cols.remove_components',
      removeInstructions: 'witcher_cc.pdf.cloud.page4.cols.remove_instructions',
    },
  },
} satisfies DeepKeyTree;

export type CloudPdfExtraI18n = {
  lang: string;
  subtitle: string;
  baseWord: string;
  cols: {
    value: string;
    bonus: string;
    field: string;
    note: string;
  };
  sections: {
    skills: string;
    perks: string;
    magic: string;
  };
  stats: {
    abbr: {
      LUCK: string;
      VIGOR: string;
    };
  };
  prof: {
    branchCol: string;
  };
  page4: {
    titles: {
      spellsSigns: string;
    };
    cols: {
      ingredients: string;
      removeComponents: string;
      removeInstructions: string;
    };
  };
};

type I18nRow = { id: string; lang: string; text: string };

export async function loadCloudPdfExtraI18n(lang: string): Promise<CloudPdfExtraI18n> {
  const keySet = new Set<string>();
  collectLeafStrings(CLOUD_PDF_EXTRA_KEYS, keySet);
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
    if (rec?.[lang]) return normalizeResolvedText(rec[lang]);
    if (lang !== 'en' && rec?.en) return normalizeResolvedText(rec.en);
    return key;
  };

  const translated = mapLeafStrings(CLOUD_PDF_EXTRA_KEYS, resolve) as Omit<CloudPdfExtraI18n, 'lang'>;
  return { lang, ...(translated as any) };
}
