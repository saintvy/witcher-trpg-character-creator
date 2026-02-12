import type { CharacterPdfPage2I18n } from './page2I18n.js';

export type VehicleDetails = {
  wt_id: string;
  vehicle_name: string | null;
  subgroup_name: string | null;
  base: number | null;
  control_modifier: number | null;
  speed: string | null;
  occupancy: string | null;
  hp: number | null;
  weight: string | number | null;
  price: number | null;
};

export type RecipeDetails = {
  r_id: string;
  recipe_name: string | null;
  recipe_group: string | null;
  craft_level: string | null;
  complexity: number | null;
  time_craft: string | null;
  formula: string | null;
  formula_en: string | null;
  price_formula: number | null;
  minimal_ingredients_cost: number | null;
  time_effect: string | null;
  toxicity: string | null;
  recipe_description: string | null;
  weight_potion: string | null;
  price_potion: number | null;
};

export type GeneralGearDetails = {
  t_id: string;
  gear_name: string | null;
  group_name: string | null;
  subgroup_name: string | null;
  gear_description: string | null;
  concealment: string | null;
  weight: string | number | null;
  price: number | null;
};

export type UpgradeDetails = {
  u_id: string;
  upgrade_name: string | null;
  upgrade_group: string | null;
  target: string | null;
  effect_names: string | null;
  slots: number | null;
  weight: string | number | null;
  price: number | null;
};

export type BlueprintDetails = {
  b_id: string;
  blueprint_name: string | null;
  blueprint_group: string | null;
  craft_level: string | null;
  difficulty_check: number | null;
  time_craft: string | null;
  components: string | null;
  item_desc: string | null;
  price_components: number | null;
  price: number | null;
  price_item: number | null;
};

export type IngredientDetails = {
  i_id: string;
  ingredient_name: string | null;
  alchemy_substance: string | null;
  alchemy_substance_en: string | null;
  harvesting_complexity: number | null;
  weight: string | number | null;
  price: number | null;
};

export type MutagenDetails = {
  m_id: string;
  mutagen_name: string | null;
  mutagen_color: string | null;
  effect: string | null;
  alchemy_dc: number | null;
  minor_mutation: string | null;
};

export type TrophyDetails = {
  tr_id: string;
  trophy_name: string | null;
  effect: string | null;
};

export type VehicleRow = {
  amount: string;
  subgroupName: string;
  vehicleName: string;
  base: string;
  controlModifier: string;
  speed: string;
  hp: string;
  weight: string;
  occupancy: string;
  price: string;
};

export type RecipeRow = {
  amount: string;
  recipeGroup: string;
  recipeName: string;
  complexity: string;
  timeCraft: string;
  formulaEn: string;
  priceFormula: string;
  minimalIngredientsCost: string;
  timeEffect: string;
  toxicity: string;
  recipeDescription: string;
  weightPotion: string;
  pricePotion: string;
};

export type GeneralGearRow = {
  amount: string;
  group: string;
  subgroup: string;
  name: string;
  description: string;
  concealment: string;
  weight: string;
  price: string;
};

export type UpgradeRow = {
  amount: string;
  group: string;
  name: string;
  target: string;
  effects: string;
  slots: string;
  weight: string;
  price: string;
};

export type BlueprintRow = {
  amount: string;
  name: string;
  group: string;
  craftLevel: string;
  difficultyCheck: string;
  timeCraft: string;
  components: string;
  itemDesc: string;
  priceComponents: string;
  price: string;
  priceItem: string;
};

export type ComponentRow = {
  amount: string;
  substanceEn: string;
  name: string;
  harvestingComplexity: string;
  weight: string;
  price: string;
};

export type MutagenRow = {
  amount: string;
  name: string;
  color: string;
  alchemyDc: string;
  effect: string;
  minorMutation: string;
};

export type TrophyRow = {
  amount: string;
  name: string;
  effect: string;
};

export type CharacterPdfPage3Vm = {
  i18n: CharacterPdfPage2I18n;
  recipes: RecipeRow[];
  blueprints: BlueprintRow[];
  componentsTables: Array<{ rows: ComponentRow[] }>;
  mutagens: MutagenRow[];
  trophies: TrophyRow[];
  vehicles: VehicleRow[];
  generalGear: GeneralGearRow[];
  upgrades: UpgradeRow[];
  money: { crowns: string };
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

export function mapCharacterJsonToPage3Vm(
  characterJson: unknown,
  deps: {
    i18n: CharacterPdfPage2I18n;
    recipeDetailsById?: ReadonlyMap<string, RecipeDetails>;
    blueprintDetailsById?: ReadonlyMap<string, BlueprintDetails>;
    ingredientDetailsById?: ReadonlyMap<string, IngredientDetails>;
    mutagenDetailsById?: ReadonlyMap<string, MutagenDetails>;
    trophyDetailsById?: ReadonlyMap<string, TrophyDetails>;
    vehicleDetailsById?: ReadonlyMap<string, VehicleDetails>;
    generalGearDetailsById?: ReadonlyMap<string, GeneralGearDetails>;
    upgradeDetailsById?: ReadonlyMap<string, UpgradeDetails>;
  },
): CharacterPdfPage3Vm {
  const i18n = deps.i18n;
  const recipeDetailsById = deps.recipeDetailsById ?? new Map();
  const blueprintDetailsById = deps.blueprintDetailsById ?? new Map();
  const ingredientDetailsById = deps.ingredientDetailsById ?? new Map();
  const mutagenDetailsById = deps.mutagenDetailsById ?? new Map();
  const trophyDetailsById = deps.trophyDetailsById ?? new Map();
  const vehicleDetailsById = deps.vehicleDetailsById ?? new Map();
  const generalGearDetailsById = deps.generalGearDetailsById ?? new Map();
  const upgradeDetailsById = deps.upgradeDetailsById ?? new Map();

  const gearRoot = asRecord(getPath(characterJson, 'gear')) ?? {};
  const recipesRaw = Array.isArray(gearRoot.recipes) ? (gearRoot.recipes as unknown[]) : [];
  const recipes: RecipeRow[] = recipesRaw
    .map((r) => {
      const rec = asRecord(r) ?? {};
      const rId = asString(rec.r_id);
      const amount = asNumber(rec.amount) ?? asNumber(rec.qty) ?? 1;
      const details = rId ? recipeDetailsById.get(rId) : null;
      return {
        amount: String(amount),
        recipeGroup: asString(rec.recipe_group) ?? details?.recipe_group ?? '',
        recipeName: asString(rec.recipe_name) ?? details?.recipe_name ?? rId ?? '',
        complexity: details?.complexity != null ? String(details.complexity) : asString(rec.complexity) ?? '',
        timeCraft: asString(rec.time_craft) ?? details?.time_craft ?? '',
        formulaEn: asString(rec.formula_en) ?? details?.formula_en ?? '',
        priceFormula: details?.price_formula != null ? String(details.price_formula) : asString(rec.price_formula) ?? '',
        minimalIngredientsCost:
          details?.minimal_ingredients_cost != null ? String(details.minimal_ingredients_cost) : asString(rec.minimal_ingredients_cost) ?? '',
        timeEffect: asString(rec.time_effect) ?? details?.time_effect ?? '',
        toxicity: asString(rec.toxicity) ?? details?.toxicity ?? '',
        recipeDescription: asString(rec.recipe_description) ?? details?.recipe_description ?? '',
        weightPotion: asString(rec.weight_potion) ?? details?.weight_potion ?? '',
        pricePotion: details?.price_potion != null ? String(details.price_potion) : asString(rec.price_potion) ?? '',
      };
    })
    .filter((r) => r.recipeName || r.amount);

  const blueprintsRaw = Array.isArray(gearRoot.blueprints) ? (gearRoot.blueprints as unknown[]) : [];
  const blueprints: BlueprintRow[] = blueprintsRaw
    .map((b) => {
      const rec = asRecord(b) ?? {};
      const bId = asString(rec.b_id);
      if (!bId) return null;
      const details = bId ? blueprintDetailsById.get(bId) : null;
      const amount = 1;
      return {
        amount: String(amount),
        name: details?.blueprint_name ?? bId ?? '',
        group: details?.blueprint_group ?? '',
        craftLevel: details?.craft_level ?? '',
        difficultyCheck: details?.difficulty_check != null ? String(details.difficulty_check) : '',
        timeCraft: details?.time_craft ?? '',
        components: details?.components ?? '',
        itemDesc: details?.item_desc ?? '',
        priceComponents: details?.price_components != null ? String(details.price_components) : '',
        price: details?.price != null ? String(details.price) : '',
        priceItem: details?.price_item != null ? String(details.price_item) : '',
      };
    })
    .filter((b): b is BlueprintRow => Boolean(b))
    .filter((b) => b.name || b.group || b.amount);

  const ingredientsRoot = asRecord(gearRoot.ingredients) ?? {};
  const ingAlchemyRaw = Array.isArray(ingredientsRoot.alchemy) ? (ingredientsRoot.alchemy as unknown[]) : [];
  const ingCraftRaw = Array.isArray(ingredientsRoot.craft) ? (ingredientsRoot.craft as unknown[]) : [];
  const componentRowsAll: ComponentRow[] = [...ingAlchemyRaw, ...ingCraftRaw]
    .map((x) => {
      const rec = asRecord(x) ?? {};
      const iId = asString(rec.i_id);
      if (!iId) return null;
      const amount = asNumber(rec.amount) ?? asNumber(rec.qty) ?? 1;
      const details = ingredientDetailsById.get(iId);
      return {
        amount: String(amount),
        substanceEn: details?.alchemy_substance_en ?? '',
        name: details?.ingredient_name ?? iId,
        harvestingComplexity:
          details?.harvesting_complexity != null ? String(details.harvesting_complexity) : '',
        weight: details?.weight != null ? String(details.weight) : '',
        price: details?.price != null ? String(details.price) : '',
      };
    })
    .filter((r): r is ComponentRow => Boolean(r));

  const rowsPerTable = Math.max(3, Math.ceil(componentRowsAll.length / 3) + 3);
  const componentRowsByTable: ComponentRow[][] = [[], [], []];
  for (let i = 0; i < componentRowsAll.length; i++) {
    componentRowsByTable[i % 3]!.push(componentRowsAll[i]!);
  }
  const componentsTables: Array<{ rows: ComponentRow[] }> = componentRowsByTable.map((rows) => {
    const out = rows.slice(0, rowsPerTable);
    while (out.length < rowsPerTable) out.push({ amount: '', substanceEn: '', name: '', harvestingComplexity: '', weight: '', price: '' });
    return { rows: out };
  });

  const mutagensRaw = Array.isArray(gearRoot.mutagens) ? (gearRoot.mutagens as unknown[]) : [];
  const mutagens: MutagenRow[] = mutagensRaw
    .map((m) => {
      const rec = asRecord(m) ?? {};
      const mId = asString(rec.m_id);
      if (!mId) return null;
      const amount = asNumber(rec.amount) ?? asNumber(rec.qty) ?? 1;
      const details = mutagenDetailsById.get(mId);
      return {
        amount: String(amount),
        name: details?.mutagen_name ?? mId,
        color: details?.mutagen_color ?? '',
        alchemyDc: details?.alchemy_dc != null ? String(details.alchemy_dc) : '',
        effect: details?.effect ?? '',
        minorMutation: details?.minor_mutation ?? '',
      };
    })
    .filter((m): m is MutagenRow => Boolean(m))
    .filter((m) => m.name || m.amount);

  const trophiesRaw = Array.isArray(gearRoot.trophies) ? (gearRoot.trophies as unknown[]) : [];
  const trophies: TrophyRow[] = trophiesRaw
    .map((t) => {
      const rec = asRecord(t) ?? {};
      const trId = asString(rec.tr_id);
      if (!trId) return null;
      const amount = asNumber(rec.amount) ?? asNumber(rec.qty) ?? 1;
      const details = trophyDetailsById.get(trId);
      return {
        amount: String(amount),
        name: details?.trophy_name ?? trId,
        effect: details?.effect ?? '',
      };
    })
    .filter((t): t is TrophyRow => Boolean(t))
    .filter((t) => t.name || t.amount);

  const vehiclesRaw = Array.isArray(gearRoot.vehicles) ? (gearRoot.vehicles as unknown[]) : [];
  const vehicles: VehicleRow[] = vehiclesRaw
    .map((v) => {
      const rec = asRecord(v) ?? {};
      const wtId = asString(rec.wt_id);
      const amount = asNumber(rec.amount) ?? asNumber(rec.qty) ?? 1;
      const details = wtId ? vehicleDetailsById.get(wtId) : null;
      return {
        amount: String(amount),
        subgroupName: asString(rec.subgroup_name) ?? details?.subgroup_name ?? '',
        vehicleName: asString(rec.vehicle_name) ?? details?.vehicle_name ?? wtId ?? '',
        base: asString(rec.base) ?? (details?.base != null ? String(details.base) : ''),
        controlModifier: asString(rec.control_modifier) ?? (details?.control_modifier != null ? String(details.control_modifier) : ''),
        speed: asString(rec.speed) ?? details?.speed ?? '',
        hp: asString(rec.hp) ?? (details?.hp != null ? String(details.hp) : ''),
        weight: asString(rec.weight) ?? (details?.weight != null ? String(details.weight) : ''),
        occupancy: asString(rec.occupancy) ?? details?.occupancy ?? '',
        price: details?.price != null ? String(details.price) : asString(rec.price) ?? '',
      };
    })
    .filter((r) => r.vehicleName || r.amount);

  const generalGearRaw = Array.isArray(gearRoot.general_gear) ? (gearRoot.general_gear as unknown[]) : [];
  const generalGear: GeneralGearRow[] = generalGearRaw
    .map((g) => {
      const rec = asRecord(g) ?? {};
      const tId = asString(rec.t_id);
      const hasInlineDetails =
        !tId &&
        Boolean(
          asString(rec.name) ||
            asString(rec.gear_name) ||
            asString(rec.group_name) ||
            asString(rec.subgroup_name) ||
            asString(rec.gear_description) ||
            asString(rec.description) ||
            asString(rec.concealment) ||
            asString(rec.weight) ||
            asString(rec.price),
        );
      const amountDefault = tId || hasInlineDetails ? 1 : 0;
      const amount = asNumber(rec.amount) ?? asNumber(rec.qty) ?? amountDefault;
      const details = tId ? generalGearDetailsById.get(tId) : null;
      const group = (details?.group_name ?? asString(rec.group_name) ?? '').trim();
      const subgroup = (details?.subgroup_name ?? asString(rec.subgroup_name) ?? '').trim();
      return {
        amount: String(amount),
        group,
        subgroup,
        name: details?.gear_name ?? asString(rec.name) ?? asString(rec.gear_name) ?? tId ?? '',
        description: details?.gear_description ?? asString(rec.gear_description) ?? '',
        concealment: details?.concealment ?? asString(rec.concealment) ?? '',
        weight: details?.weight != null ? String(details.weight) : asString(rec.weight) ?? '',
        price: details?.price != null ? String(details.price) : asString(rec.price) ?? '',
      };
    })
    .filter((g) => g.name || g.group || g.subgroup || g.description || g.amount);

  const upgradesRaw = Array.isArray(gearRoot.upgrades) ? (gearRoot.upgrades as unknown[]) : [];
  const upgrades: UpgradeRow[] = upgradesRaw
    .map((u) => {
      const rec = asRecord(u) ?? {};
      const uId = asString(rec.u_id);
      const amount = asNumber(rec.amount) ?? asNumber(rec.qty) ?? 1;
      const details = uId ? upgradeDetailsById.get(uId) : null;
      return {
        amount: String(amount),
        group: details?.upgrade_group ?? '',
        name: details?.upgrade_name ?? uId,
        target: details?.target ?? '',
        effects: details?.effect_names ?? '',
        slots: details?.slots != null ? String(details.slots) : '',
        weight: details?.weight != null ? String(details.weight) : '',
        price: details?.price != null ? String(details.price) : '',
      };
    })
    .filter((u) => u.name || u.group || u.amount);

  const moneyRoot = asRecord(getPath(characterJson, 'money')) ?? {};
  const crowns = asNumber(moneyRoot.crowns);

  return {
    i18n,
    recipes,
    blueprints,
    componentsTables,
    mutagens,
    trophies,
    vehicles,
    generalGear,
    upgrades,
    money: { crowns: crowns != null ? String(crowns) : '' },
  };
}
