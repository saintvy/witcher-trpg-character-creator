import { chromium, type Browser } from 'playwright';
import { type SkillCatalogInfo, type WeaponDetails, type ArmorDetails, type PotionDetails } from './pages/viewModelPage1.js';
import {
  type VehicleDetails,
  type RecipeDetails,
  type GeneralGearDetails,
  type UpgradeDetails,
  type BlueprintDetails,
  type IngredientDetails,
  type MutagenDetails,
  type TrophyDetails,
} from './pages/viewModelPage3.js';
import type { MagicGiftDetails, ItemEffectGlossaryRow } from './pages/viewModelPage4.js';
import { renderCharacterPdfHtml } from './templates/characterHtml.js';
import { getSkillsCatalog } from '../services/skillsCatalog.js';
import { db } from '../db/pool.js';
import { loadCharacterPdfI18n, type CharacterPdfI18n } from './i18n.js';
import { buildCharacterPdfViewModel } from './pdfViewModel.js';

export type PdfOptions = { alchemy_style?: 'w1' | 'w2' };

export class CharacterPdfService {
  private static browserPromise: Promise<Browser> | null = null;

  private static async getBrowser(): Promise<Browser> {
    if (!CharacterPdfService.browserPromise) {
      CharacterPdfService.browserPromise = chromium.launch({ headless: true });
    }
    return CharacterPdfService.browserPromise;
  }

  static async shutdown(): Promise<void> {
    if (!CharacterPdfService.browserPromise) return;
    const p = CharacterPdfService.browserPromise;
    CharacterPdfService.browserPromise = null;
    try {
      const browser = await p;
      await browser.close().catch(() => undefined);
    } catch {
      // ignore (e.g. launch failed)
    }
  }

  private getLangFromCharacter(characterJson: unknown): string {
    const record =
      characterJson && typeof characterJson === 'object' && !Array.isArray(characterJson) ? (characterJson as Record<string, unknown>) : null;
    const lang = record?.lang;
    return typeof lang === 'string' && lang.trim().length > 0 ? lang.trim() : 'en';
  }

  private async withTimeout<T>(promise: Promise<T>, timeoutMs: number): Promise<T> {
    let timeoutHandle: NodeJS.Timeout | null = null;
    const timeoutPromise = new Promise<T>((_, reject) => {
      timeoutHandle = setTimeout(() => reject(new Error(`Timeout after ${timeoutMs}ms`)), timeoutMs);
    });

    try {
      return await Promise.race([promise, timeoutPromise]);
    } finally {
      if (timeoutHandle) clearTimeout(timeoutHandle);
    }
  }

  private async getPdfI18n(lang: string): Promise<CharacterPdfI18n> {
    return this.withTimeout(loadCharacterPdfI18n(lang), 2500);
  }

  async generatePdfBuffer(characterJson: unknown, options: PdfOptions = {}): Promise<Buffer> {
    const lang = this.getLangFromCharacter(characterJson);
    let i18n: CharacterPdfI18n;
    try {
      i18n = await this.getPdfI18n(lang);
    } catch (error) {
      console.error('[pdf] i18n load failed', error);
      i18n = await this.getPdfI18n('en');
    }

    const skillsCatalog = new Map<string, SkillCatalogInfo>();
    try {
      const catalog = await this.withTimeout(getSkillsCatalog({ lang }), 2500);
      for (const s of catalog.skills) {
        skillsCatalog.set(s.id, {
          name: s.name,
          param: s.param,
          isDifficult: Boolean(s.isDifficult),
        });
      }
    } catch (error) {
      console.error('[pdf] skills catalog load failed', error);
    }

    const gear = characterJson && typeof characterJson === 'object' && characterJson !== null && !Array.isArray(characterJson)
      ? (characterJson as Record<string, unknown>).gear
      : undefined;
    const gearRec = gear && typeof gear === 'object' && gear !== null && !Array.isArray(gear) ? (gear as Record<string, unknown>) : null;

    const weaponIds = Array.isArray(gearRec?.weapons)
      ? (gearRec!.weapons as unknown[])
          .map((x) => (x && typeof x === 'object' && !Array.isArray(x) ? String((x as any).w_id ?? '') : ''))
          .filter((x) => x.length > 0)
      : [];

    const armorIds = Array.isArray(gearRec?.armors)
      ? (gearRec!.armors as unknown[])
          .map((x) => (x && typeof x === 'object' && !Array.isArray(x) ? String((x as any).a_id ?? '') : ''))
          .filter((x) => x.length > 0)
      : [];

    const potionIds = Array.isArray(gearRec?.potions)
      ? (gearRec!.potions as unknown[])
          .map((x) => (x && typeof x === 'object' && !Array.isArray(x) ? String((x as any).p_id ?? '') : ''))
          .filter((x) => x.length > 0)
      : [];

    const vehicleIds = Array.isArray(gearRec?.vehicles)
      ? (gearRec!.vehicles as unknown[])
          .map((x) => (x && typeof x === 'object' && !Array.isArray(x) ? String((x as any).wt_id ?? '') : ''))
          .filter((x) => x.length > 0)
      : [];

    const recipeIds = Array.isArray(gearRec?.recipes)
      ? (gearRec!.recipes as unknown[])
          .map((x) => (x && typeof x === 'object' && !Array.isArray(x) ? String((x as any).r_id ?? '') : ''))
          .filter((x) => x.length > 0)
      : [];

    const ingredientsRec =
      gearRec?.ingredients && typeof gearRec.ingredients === 'object' && gearRec.ingredients !== null && !Array.isArray(gearRec.ingredients)
        ? (gearRec.ingredients as Record<string, unknown>)
        : null;

    const ingredientAlchemyIds = Array.isArray(ingredientsRec?.alchemy)
      ? (ingredientsRec!.alchemy as unknown[])
          .map((x) => (x && typeof x === 'object' && !Array.isArray(x) ? String((x as any).i_id ?? '') : ''))
          .filter((x) => x.length > 0)
      : [];

    const ingredientCraftIds = Array.isArray(ingredientsRec?.craft)
      ? (ingredientsRec!.craft as unknown[])
          .map((x) => (x && typeof x === 'object' && !Array.isArray(x) ? String((x as any).i_id ?? '') : ''))
          .filter((x) => x.length > 0)
      : [];

    const ingredientIds = [...ingredientAlchemyIds, ...ingredientCraftIds];

    const mutagenIds = Array.isArray(gearRec?.mutagens)
      ? (gearRec!.mutagens as unknown[])
          .map((x) => (x && typeof x === 'object' && !Array.isArray(x) ? String((x as any).m_id ?? '') : ''))
          .filter((x) => x.length > 0)
      : [];

    const trophyIds = Array.isArray(gearRec?.trophies)
      ? (gearRec!.trophies as unknown[])
          .map((x) => (x && typeof x === 'object' && !Array.isArray(x) ? String((x as any).tr_id ?? '') : ''))
          .filter((x) => x.length > 0)
      : [];

    const blueprintIds = Array.isArray(gearRec?.blueprints)
      ? (gearRec!.blueprints as unknown[])
          .map((x) => (x && typeof x === 'object' && !Array.isArray(x) ? String((x as any).b_id ?? '') : ''))
          .filter((x) => x.length > 0)
      : [];

    const generalGearIds = Array.isArray(gearRec?.general_gear)
      ? (gearRec!.general_gear as unknown[])
          .map((x) => (x && typeof x === 'object' && !Array.isArray(x) ? String((x as any).t_id ?? '') : ''))
          .filter((x) => x.length > 0)
      : [];

    const upgradeIds = Array.isArray(gearRec?.upgrades)
      ? (gearRec!.upgrades as unknown[])
          .map((x) => (x && typeof x === 'object' && !Array.isArray(x) ? String((x as any).u_id ?? '') : ''))
          .filter((x) => x.length > 0)
      : [];

    const magic = gearRec?.magic;
    const magicRec = magic && typeof magic === 'object' && magic !== null && !Array.isArray(magic) ? (magic as Record<string, unknown>) : null;
    const giftIds = Array.isArray(magicRec?.gifts)
      ? (magicRec!.gifts as unknown[])
          .map((x) => (x && typeof x === 'object' && !Array.isArray(x) ? String((x as any).mg_id ?? '') : ''))
          .filter((x) => x.length > 0)
      : [];

    const weaponDetailsById = new Map<string, WeaponDetails>();
    const armorDetailsById = new Map<string, ArmorDetails>();
    const potionDetailsById = new Map<string, PotionDetails>();

    try {
      if (weaponIds.length > 0) {
        const { rows } = await this.withTimeout(
          db.query<WeaponDetails>(
            `
              SELECT w_id, weapon_name, dmg, dmg_types, weight, price, hands, reliability, concealment, effect_names
              FROM wcc_item_weapons_v
              WHERE lang = $1 AND w_id = ANY($2::text[])
            `,
            [lang, Array.from(new Set(weaponIds))],
          ),
          2500,
        );
        rows.forEach((r) => weaponDetailsById.set(r.w_id, r));
      }
    } catch (error) {
      console.error('[pdf] weapons lookup failed', error);
    }

    try {
        if (armorIds.length > 0) {
          const { rows } = await this.withTimeout(
            db.query<ArmorDetails>(
              `
              SELECT a_id, armor_name, stopping_power, encumbrance, enhancements, weight, price, effect_names
              FROM wcc_item_armors_v
              WHERE lang = $1 AND a_id = ANY($2::text[])
            `,
              [lang, Array.from(new Set(armorIds))],
            ),
          2500,
        );
        rows.forEach((r) => armorDetailsById.set(r.a_id, r));
      }
    } catch (error) {
      console.error('[pdf] armors lookup failed', error);
    }

    try {
        if (potionIds.length > 0) {
          const { rows } = await this.withTimeout(
            db.query<PotionDetails>(
              `
              SELECT p_id, potion_name, toxicity, time_effect, effect, weight, price
              FROM wcc_item_potions_v
              WHERE lang = $1 AND p_id = ANY($2::text[])
            `,
              [lang, Array.from(new Set(potionIds))],
            ),
          2500,
        );
        rows.forEach((r) => potionDetailsById.set(r.p_id, r));
      }
    } catch (error) {
      console.error('[pdf] potions lookup failed', error);
    }

    const vehicleDetailsById = new Map<string, VehicleDetails>();
    try {
      if (vehicleIds.length > 0) {
        const { rows } = await this.withTimeout(
          db.query<VehicleDetails>(
            `
              SELECT wt_id, vehicle_name, subgroup_name, base, control_modifier, speed, occupancy, hp, weight, price
              FROM wcc_item_vehicles_v
              WHERE lang = $1 AND wt_id = ANY($2::text[])
            `,
            [lang, Array.from(new Set(vehicleIds))],
          ),
          2500,
        );
        rows.forEach((r) => vehicleDetailsById.set(r.wt_id, r));
      }
    } catch (error) {
      console.error('[pdf] vehicles lookup failed', error);
    }

    const recipeDetailsById = new Map<string, RecipeDetails>();
    try {
      if (recipeIds.length > 0) {
        const { rows } = await this.withTimeout(
          db.query<RecipeDetails>(
            `
              SELECT r_id, recipe_name, recipe_group, craft_level, complexity, time_craft, formula_en,
                     price_formula, minimal_ingredients_cost, time_effect, toxicity, recipe_description,
                     weight_potion, price_potion
              FROM wcc_item_recipes_v
              WHERE lang = $1 AND r_id = ANY($2::text[])
            `,
            [lang, Array.from(new Set(recipeIds))],
          ),
          2500,
        );
        rows.forEach((r) => recipeDetailsById.set(r.r_id, r));
      }
    } catch (error) {
      console.error('[pdf] recipes lookup failed', error);
    }

    const ingredientDetailsById = new Map<string, IngredientDetails>();
    try {
      if (ingredientIds.length > 0) {
        const { rows } = await this.withTimeout(
          db.query<IngredientDetails>(
            `
              SELECT i_id, ingredient_name, alchemy_substance, alchemy_substance_en, harvesting_complexity, weight, price
              FROM wcc_item_ingredients_v
              WHERE lang = $1 AND i_id = ANY($2::text[])
            `,
            [lang, Array.from(new Set(ingredientIds))],
          ),
          2500,
        );
        rows.forEach((r) => ingredientDetailsById.set(r.i_id, r));
      }
    } catch (error) {
      console.error('[pdf] ingredients lookup failed', error);
    }

    const mutagenDetailsById = new Map<string, MutagenDetails>();
    try {
      if (mutagenIds.length > 0) {
        const { rows } = await this.withTimeout(
          db.query<MutagenDetails>(
            `
              SELECT m_id, mutagen_name, mutagen_color, effect, alchemy_dc, minor_mutation
              FROM wcc_item_mutagens_v
              WHERE lang = $1 AND m_id = ANY($2::text[])
            `,
            [lang, Array.from(new Set(mutagenIds))],
          ),
          2500,
        );
        rows.forEach((r) => mutagenDetailsById.set(r.m_id, r));
      }
    } catch (error) {
      console.error('[pdf] mutagens lookup failed', error);
    }

    const trophyDetailsById = new Map<string, TrophyDetails>();
    try {
      if (trophyIds.length > 0) {
        const { rows } = await this.withTimeout(
          db.query<TrophyDetails>(
            `
              SELECT tr_id, trophy_name, effect
              FROM wcc_item_trophies_v
              WHERE lang = $1 AND tr_id = ANY($2::text[])
            `,
            [lang, Array.from(new Set(trophyIds))],
          ),
          2500,
        );
        rows.forEach((r) => trophyDetailsById.set(r.tr_id, r));
      }
    } catch (error) {
      console.error('[pdf] trophies lookup failed', error);
    }

    const blueprintDetailsById = new Map<string, BlueprintDetails>();
    try {
      if (blueprintIds.length > 0) {
        const { rows } = await this.withTimeout(
          db.query<BlueprintDetails>(
            `
              SELECT b_id, blueprint_name, blueprint_group, craft_level, difficulty_check, time_craft,
                     item_id, components, item_desc, price_components, price, price_item
              FROM wcc_item_blueprints_v
              WHERE lang = $1 AND b_id = ANY($2::text[])
            `,
            [lang, Array.from(new Set(blueprintIds))],
          ),
          2500,
        );
        rows.forEach((r) => blueprintDetailsById.set(r.b_id, r));
      }
    } catch (error) {
      console.error('[pdf] blueprints lookup failed', error);
    }

    const generalGearDetailsById = new Map<string, GeneralGearDetails>();
    try {
      if (generalGearIds.length > 0) {
        const { rows } = await this.withTimeout(
          db.query<GeneralGearDetails>(
            `
              SELECT t_id, gear_name, group_name, subgroup_name, gear_description, concealment, weight, price
              FROM wcc_item_general_gear_v
              WHERE lang = $1 AND t_id = ANY($2::text[])
            `,
            [lang, Array.from(new Set(generalGearIds))],
          ),
          2500,
        );
        rows.forEach((r) => generalGearDetailsById.set(r.t_id, r));
      }
    } catch (error) {
      console.error('[pdf] general gear lookup failed', error);
    }

    const upgradeDetailsById = new Map<string, UpgradeDetails>();
    try {
      if (upgradeIds.length > 0) {
        const { rows } = await this.withTimeout(
          db.query<UpgradeDetails>(
            `
              SELECT u_id, upgrade_name, upgrade_group, target, effect_names, slots, weight, price
              FROM wcc_item_upgrades_v
              WHERE lang = $1 AND u_id = ANY($2::text[])
            `,
            [lang, Array.from(new Set(upgradeIds))],
          ),
          2500,
        );
        rows.forEach((r) => upgradeDetailsById.set(r.u_id, r));
      }
    } catch (error) {
      console.error('[pdf] upgrades lookup failed', error);
    }

    const giftDetailsById = new Map<string, MagicGiftDetails>();
    try {
      if (giftIds.length > 0) {
        const { rows } = await this.withTimeout(
          db.query<MagicGiftDetails>(
            `
              SELECT mg_id, group_name, gift_name, dc, vigor_cost, action_cost, description, sort_key, is_major
              FROM wcc_magic_gifts_v
              WHERE lang = $1 AND mg_id = ANY($2::text[])
            `,
            [lang, Array.from(new Set(giftIds))],
          ),
          2500,
        );
        rows.forEach((r) => giftDetailsById.set(r.mg_id, r));
      }
    } catch (error) {
      console.error('[pdf] gifts lookup failed', error);
    }

    const itemEffectsGlossary: ItemEffectGlossaryRow[] = [];
    try {
      const blueprintItemIds = Array.from(blueprintDetailsById.values())
        .map((b) => String(b.item_id ?? '').trim())
        .filter((x) => x.length > 0);

      const itemIdsForEffects = Array.from(
        new Set([...weaponIds, ...armorIds, ...upgradeIds, ...blueprintItemIds]),
      ).filter((id) => id.startsWith('W') || id.startsWith('A') || id.startsWith('U'));

      if (itemIdsForEffects.length > 0) {
        type EffectRow = {
          item_id: string;
          effect_id: string;
          modifier: number | null;
          name_tpl: string | null;
          desc_tpl: string | null;
          cond_tpl: string | null;
        };

        const { rows } = await this.withTimeout(
          db.query<EffectRow>(
            `
              SELECT ite.item_id::text AS item_id,
                     ite.e_e_id::text AS effect_id,
                     ite.modifier AS modifier,
                     COALESCE(ie_lang.text, ie_en.text, '') AS name_tpl,
                     COALESCE(ide_lang.text, ide_en.text, '') AS desc_tpl,
                     COALESCE(iec_lang.text, iec_en.text, '') AS cond_tpl
                FROM wcc_item_to_effects ite
                LEFT JOIN wcc_item_effects e ON e.e_id = ite.e_e_id
                LEFT JOIN i18n_text ie_lang ON ie_lang.id = e.name_id AND ie_lang.lang = $1
                LEFT JOIN i18n_text ie_en ON ie_en.id = e.name_id AND ie_en.lang = 'en'
                LEFT JOIN i18n_text ide_lang ON ide_lang.id = e.description_id AND ide_lang.lang = $1
                LEFT JOIN i18n_text ide_en ON ide_en.id = e.description_id AND ide_en.lang = 'en'
                LEFT JOIN wcc_item_effect_conditions ec ON ec.ec_id = ite.ec_ec_id
                LEFT JOIN i18n_text iec_lang ON iec_lang.id = ec.description_id AND iec_lang.lang = $1
                LEFT JOIN i18n_text iec_en ON iec_en.id = ec.description_id AND iec_en.lang = 'en'
               WHERE ite.item_id = ANY($2::text[])
               ORDER BY ite.e_e_id ASC, ite.modifier ASC NULLS FIRST
            `,
            [lang, itemIdsForEffects],
          ),
          2500,
        );

        const normalize = (v: string | null | undefined): string => String(v ?? '').trim();
        const replaceMod = (tpl: string, modifier: number | null): string => {
          const mod = modifier === null || modifier === undefined ? '' : String(modifier);
          return tpl.replaceAll('<mod>', mod);
        };
        const toSortNumber = (effectId: string): number => {
          const m = /^E(\d+)$/.exec(effectId.trim());
          if (!m) return Number.POSITIVE_INFINITY;
          const n = Number(m[1]);
          return Number.isFinite(n) ? n : Number.POSITIVE_INFINITY;
        };

        const byKey = new Map<string, { effectId: string; modifier: number | null; cond: string; row: ItemEffectGlossaryRow }>();
        for (const r of rows) {
          const effectId = normalize(r.effect_id);
          const nameTpl = normalize(r.name_tpl);
          if (!effectId && !nameTpl) continue;

          const cond = replaceMod(normalize(r.cond_tpl), r.modifier).trim();
          const nameBase = replaceMod(nameTpl || effectId, r.modifier).trim();
          const name = cond ? `${nameBase} [${cond}]` : nameBase;
          const value = replaceMod(normalize(r.desc_tpl), r.modifier).trim();

          const key = `${effectId}|${r.modifier ?? ''}|${cond}`;
          if (byKey.has(key)) continue;
          byKey.set(key, { effectId, modifier: r.modifier ?? null, cond, row: { name, value } });
        }

        const sorted = Array.from(byKey.values()).sort((a, b) => {
          const an = toSortNumber(a.effectId);
          const bn = toSortNumber(b.effectId);
          if (an !== bn) return an - bn;
          const am = a.modifier ?? Number.NEGATIVE_INFINITY;
          const bm = b.modifier ?? Number.NEGATIVE_INFINITY;
          if (am !== bm) return am - bm;
          return a.row.name.localeCompare(b.row.name, undefined, { sensitivity: 'base' });
        });

        itemEffectsGlossary.push(...sorted.map((x) => x.row));
      }
    } catch (error) {
      console.error('[pdf] item effects glossary lookup failed', error);
    }

    const pdfVm = buildCharacterPdfViewModel(characterJson, {
      lang,
      i18n,
      skillsCatalog,
      weaponDetailsById,
      armorDetailsById,
      potionDetailsById,
      vehicleDetailsById,
      recipeDetailsById,
      blueprintDetailsById,
      ingredientDetailsById,
      mutagenDetailsById,
      trophyDetailsById,
      generalGearDetailsById,
      upgradeDetailsById,
      giftDetailsById,
      itemEffectsGlossary,
    });
    const html = renderCharacterPdfHtml({ page1: pdfVm.page1, page2: pdfVm.page2, page3: pdfVm.page3, page4: pdfVm.page4, options });

    const browser = await CharacterPdfService.getBrowser();
    // Viewport width MUST match the PDF printable area so that inline layout
    // scripts (getBoundingClientRect measurements) produce results consistent
    // with the actual printed page.  A4 = 210 mm; @page margin = 6 mm per side
    // → content width = 210 − 12 = 198 mm ≈ 748 CSS-px at 96 dpi.
    const context = await browser.newContext({
      viewport: { width: 748, height: 720 },
      deviceScaleFactor: 2,
    });
    const page = await context.newPage();

    try {
      // Important: apply print media before injecting HTML so any layout measurements in inline scripts
      // run deterministically under print CSS (avoids occasional mis-measurements that can add extra rows).
      await page.emulateMedia({ media: 'print' });
      await page.setContent(html, { waitUntil: 'networkidle' });
      await page.waitForFunction('window.__pdfReady === true', { timeout: 5000 }).catch(() => undefined);

      const pdf = await page.pdf({
        format: 'A4',
        printBackground: true,
        margin: { top: '0mm', right: '0mm', bottom: '0mm', left: '0mm' },
      });

      return pdf;
    } finally {
      await page.close().catch(() => undefined);
      await context.close().catch(() => undefined);
    }
  }
}
