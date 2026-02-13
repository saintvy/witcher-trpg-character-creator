import {
  mapCharacterJsonToPage2Vm,
  type CharacterPdfPage2Vm,
} from './pages/viewModelPage2.js';
import {
  mapCharacterJsonToPage3Vm,
  type VehicleDetails,
  type RecipeDetails,
  type GeneralGearDetails,
  type UpgradeDetails,
  type BlueprintDetails,
  type IngredientDetails,
  type MutagenDetails,
  type TrophyDetails,
  type CharacterPdfPage3Vm,
} from './pages/viewModelPage3.js';
import { mapCharacterJsonToPage4Vm, type CharacterPdfPage4Vm } from './pages/viewModelPage4.js';
import type { MagicGiftDetails, ItemEffectGlossaryRow } from './pages/viewModelPage4.js';
import {
  mapCharacterJsonToPage1Vm,
  type SkillCatalogInfo,
  type WeaponDetails,
  type ArmorDetails,
  type PotionDetails,
  type CharacterPdfPage1Vm,
} from './pages/viewModelPage1.js';
import type { CharacterPdfI18n } from './i18n.js';

export type CharacterPdfViewModel = {
  page1: CharacterPdfPage1Vm;
  page2: CharacterPdfPage2Vm;
  page3: CharacterPdfPage3Vm;
  page4: CharacterPdfPage4Vm;
};

export type BuildCharacterPdfViewModelDeps = {
  lang: string;
  i18n: CharacterPdfI18n;
  skillsCatalog?: ReadonlyMap<string, SkillCatalogInfo>;
  weaponDetailsById?: ReadonlyMap<string, WeaponDetails>;
  armorDetailsById?: ReadonlyMap<string, ArmorDetails>;
  potionDetailsById?: ReadonlyMap<string, PotionDetails>;
  vehicleDetailsById?: ReadonlyMap<string, VehicleDetails>;
  recipeDetailsById?: ReadonlyMap<string, RecipeDetails>;
  blueprintDetailsById?: ReadonlyMap<string, BlueprintDetails>;
  ingredientDetailsById?: ReadonlyMap<string, IngredientDetails>;
  mutagenDetailsById?: ReadonlyMap<string, MutagenDetails>;
  trophyDetailsById?: ReadonlyMap<string, TrophyDetails>;
  generalGearDetailsById?: ReadonlyMap<string, GeneralGearDetails>;
  upgradeDetailsById?: ReadonlyMap<string, UpgradeDetails>;
  giftDetailsById?: ReadonlyMap<string, MagicGiftDetails>;
  itemEffectsGlossary?: ReadonlyArray<ItemEffectGlossaryRow>;
};

export function buildCharacterPdfViewModel(
  characterJson: unknown,
  deps: BuildCharacterPdfViewModelDeps,
): CharacterPdfViewModel {
  const page1 = mapCharacterJsonToPage1Vm(characterJson, {
    lang: deps.lang,
    i18n: deps.i18n.page1,
    skillsCatalog: deps.skillsCatalog,
    weaponDetailsById: deps.weaponDetailsById,
    armorDetailsById: deps.armorDetailsById,
    potionDetailsById: deps.potionDetailsById,
  });

  const page2 = mapCharacterJsonToPage2Vm(characterJson, {
    i18n: deps.i18n.page2,
  });
  const page3 = mapCharacterJsonToPage3Vm(characterJson, {
    i18n: deps.i18n.page2,
    vehicleDetailsById: deps.vehicleDetailsById,
    recipeDetailsById: deps.recipeDetailsById,
    blueprintDetailsById: deps.blueprintDetailsById,
    ingredientDetailsById: deps.ingredientDetailsById,
    mutagenDetailsById: deps.mutagenDetailsById,
    trophyDetailsById: deps.trophyDetailsById,
    generalGearDetailsById: deps.generalGearDetailsById,
    upgradeDetailsById: deps.upgradeDetailsById,
  });

  const page4 = mapCharacterJsonToPage4Vm(characterJson, {
    i18n: deps.i18n.page4,
    giftDetailsById: deps.giftDetailsById,
    itemEffectsGlossary: deps.itemEffectsGlossary,
  });

  return { page1, page2, page3, page4 };
}
