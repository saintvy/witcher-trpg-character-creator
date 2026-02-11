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

export type CharacterPdfPage3Vm = {
  i18n: CharacterPdfPage2I18n;
  vehicles: VehicleRow[];
  recipes: RecipeRow[];
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
    vehicleDetailsById?: ReadonlyMap<string, VehicleDetails>;
    recipeDetailsById?: ReadonlyMap<string, RecipeDetails>;
  },
): CharacterPdfPage3Vm {
  const i18n = deps.i18n;
  const vehicleDetailsById = deps.vehicleDetailsById ?? new Map();
  const recipeDetailsById = deps.recipeDetailsById ?? new Map();

  const gearRoot = asRecord(getPath(characterJson, 'gear')) ?? {};
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

  return {
    i18n,
    vehicles,
    recipes,
  };
}

