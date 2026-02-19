import crypto from 'node:crypto';
import { db } from '@wcc/core';

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
  formulaLegend: {
    Aether: page2Key('formulaLegend.Aether'),
    Caelum: page2Key('formulaLegend.Caelum'),
    Fulgur: page2Key('formulaLegend.Fulgur'),
    Hydragenum: page2Key('formulaLegend.Hydragenum'),
    Quebrith: page2Key('formulaLegend.Quebrith'),
    Rebis: page2Key('formulaLegend.Rebis'),
    Sol: page2Key('formulaLegend.Sol'),
    Vermilion: page2Key('formulaLegend.Vermilion'),
    Vitriol: page2Key('formulaLegend.Vitriol'),
    Mutagen: page2Key('formulaLegend.Mutagen'),
    Spirits: page2Key('formulaLegend.Spirits'),
    'Dog Tallow': page2Key('formulaLegend.DogTallow'),
  },
  section: {
    lore: page2Key('section.lore'),
    socialStatus: page2Key('section.socialStatus'),
    lifePath: page2Key('section.lifePath'),
    style: page2Key('section.style'),
    values: page2Key('section.values'),
    siblings: page2Key('section.siblings'),
    allies: page2Key('section.allies'),
    enemies: page2Key('section.enemies'),
    vehicles: page2Key('section.vehicles'),
    recipes: page2Key('section.recipes'),
    blueprints: page2Key('section.blueprints'),
    money: page2Key('section.money'),
    generalGear: page2Key('section.generalGear'),
    upgrades: page2Key('section.upgrades'),
    mutagens: page2Key('section.mutagens'),
    trophies: page2Key('section.trophies'),
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
    vehicles: {
      colQty: page2Key('tables.vehicles.col.qty'),
      colType: page2Key('tables.vehicles.col.type'),
      colVehicle: page2Key('tables.vehicles.col.vehicle'),
      colSkill: page2Key('tables.vehicles.col.skill'),
      colMod: page2Key('tables.vehicles.col.mod'),
      colSpeed: page2Key('tables.vehicles.col.speed'),
      colHp: page2Key('tables.vehicles.col.hp'),
      colWeight: page2Key('tables.vehicles.col.weight'),
      colPrice: page2Key('tables.vehicles.col.price'),
      colOccupancy: page2Key('tables.vehicles.col.occupancy'),
    },
    recipes: {
      colQty: page2Key('tables.recipes.col.qty'),
      colRecipeGroup: page2Key('tables.recipes.col.recipeGroup'),
      colRecipeName: page2Key('tables.recipes.col.recipeName'),
      colCraftLevel: page2Key('tables.recipes.col.craftLevel'),
      colComplexity: page2Key('tables.recipes.col.complexity'),
      colTimeCraft: page2Key('tables.recipes.col.timeCraft'),
      colFormula: page2Key('tables.recipes.col.formula'),
      colPriceFormula: page2Key('tables.recipes.col.priceFormula'),
      colMinimalIngredientsCost: page2Key('tables.recipes.col.minimalIngredientsCost'),
      colTimeEffect: page2Key('tables.recipes.col.timeEffect'),
      colToxicity: page2Key('tables.recipes.col.toxicity'),
      colRecipeDescription: page2Key('tables.recipes.col.recipeDescription'),
      colWeightPotion: page2Key('tables.recipes.col.weightPotion'),
      colPricePotion: page2Key('tables.recipes.col.pricePotion'),
    },
    blueprints: {
      colQty: page2Key('tables.blueprints.col.qty'),
      colName: page2Key('tables.blueprints.col.name'),
      colGroup: page2Key('tables.blueprints.col.group'),
      colCraftLevel: page2Key('tables.blueprints.col.craftLevel'),
      colDifficultyCheck: page2Key('tables.blueprints.col.difficultyCheck'),
      colTimeCraft: page2Key('tables.blueprints.col.timeCraft'),
      colComponents: page2Key('tables.blueprints.col.components'),
      colItemDesc: page2Key('tables.blueprints.col.itemDesc'),
      colPriceComponents: page2Key('tables.blueprints.col.priceComponents'),
      colPrice: page2Key('tables.blueprints.col.price'),
      colPriceItem: page2Key('tables.blueprints.col.priceItem'),
    },
    components: {
      colQty: page2Key('tables.components.col.qty'),
      colSub: page2Key('tables.components.col.sub'),
      colName: page2Key('tables.components.col.name'),
      colHarvestingComplexity: page2Key('tables.components.col.harvestingComplexity'),
      colWeight: page2Key('tables.components.col.weight'),
      colPrice: page2Key('tables.components.col.price'),
    },
    money: {
      colCrowns: page2Key('tables.money.col.crowns'),
      colOrens: page2Key('tables.money.col.orens'),
      colFlorens: page2Key('tables.money.col.florens'),
      colDucats: page2Key('tables.money.col.ducats'),
      colBizants: page2Key('tables.money.col.bizants'),
      colLintars: page2Key('tables.money.col.lintars'),
    },
    generalGear: {
      colGroup: page2Key('tables.generalGear.col.group'),
      colName: page2Key('tables.generalGear.col.name'),
      colConcealment: page2Key('tables.generalGear.col.concealment'),
      colWeight: page2Key('tables.generalGear.col.weight'),
      colPrice: page2Key('tables.generalGear.col.price'),
    },
    upgrades: {
      colName: page2Key('tables.upgrades.col.name'),
      colEffects: page2Key('tables.upgrades.col.effects'),
      colSlots: page2Key('tables.upgrades.col.slots'),
      colWeight: page2Key('tables.upgrades.col.weight'),
      colPrice: page2Key('tables.upgrades.col.price'),
    },
    mutagens: {
      colQty: page2Key('tables.mutagens.col.qty'),
      colName: page2Key('tables.mutagens.col.name'),
      colColor: page2Key('tables.mutagens.col.color'),
      colAlchemyDc: page2Key('tables.mutagens.col.alchemyDc'),
      colEffect: page2Key('tables.mutagens.col.effect'),
      colMinorMutation: page2Key('tables.mutagens.col.minorMutation'),
    },
    trophies: {
      colQty: page2Key('tables.trophies.col.qty'),
      colName: page2Key('tables.trophies.col.name'),
      colEffect: page2Key('tables.trophies.col.effect'),
    },
  },
} satisfies DeepKeyTree;

export type CharacterPdfPage2I18n = {
  lang: string;
  formulaLegend: { Aether: string; Caelum: string; Fulgur: string; Hydragenum: string; Quebrith: string; Rebis: string; Sol: string; Vermilion: string; Vitriol: string; Mutagen: string; Spirits: string; 'Dog Tallow': string };
  section: {
    lore: string;
    socialStatus: string;
    lifePath: string;
    style: string;
    values: string;
    siblings: string;
    allies: string;
    enemies: string;
    vehicles: string;
    recipes: string;
    blueprints: string;
    money: string;
    generalGear: string;
    upgrades: string;
    mutagens: string;
    trophies: string;
  };
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
    vehicles: { colQty: string; colType: string; colVehicle: string; colSkill: string; colMod: string; colSpeed: string; colHp: string; colWeight: string; colPrice: string; colOccupancy: string };
    recipes: { colQty: string; colRecipeGroup: string; colRecipeName: string; colCraftLevel: string; colComplexity: string; colTimeCraft: string; colFormula: string; colPriceFormula: string; colMinimalIngredientsCost: string; colTimeEffect: string; colToxicity: string; colRecipeDescription: string; colWeightPotion: string; colPricePotion: string };
    blueprints: { colQty: string; colName: string; colGroup: string; colCraftLevel: string; colDifficultyCheck: string; colTimeCraft: string; colComponents: string; colItemDesc: string; colPriceComponents: string; colPrice: string; colPriceItem: string };
    components: { colQty: string; colSub: string; colName: string; colHarvestingComplexity: string; colWeight: string; colPrice: string };
    money: { colCrowns: string; colOrens: string; colFlorens: string; colDucats: string; colBizants: string; colLintars: string };
    generalGear: { colGroup: string; colName: string; colConcealment: string; colWeight: string; colPrice: string };
    upgrades: { colName: string; colEffects: string; colSlots: string; colWeight: string; colPrice: string };
    mutagens: { colQty: string; colName: string; colColor: string; colAlchemyDc: string; colEffect: string; colMinorMutation: string };
    trophies: { colQty: string; colName: string; colEffect: string };
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
    return key;
  };

  const translated = mapLeafStrings(PAGE2_KEYS, resolve) as Omit<CharacterPdfPage2I18n, 'lang'>;
  return { lang, ...(translated as any) };
}
