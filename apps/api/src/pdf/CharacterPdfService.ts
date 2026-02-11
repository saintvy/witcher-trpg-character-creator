import { chromium, type Browser } from 'playwright';
import { type SkillCatalogInfo, type WeaponDetails, type ArmorDetails, type PotionDetails } from './pages/viewModelPage1.js';
import {
  type VehicleDetails,
  type RecipeDetails,
} from './pages/viewModelPage3.js';
import { renderCharacterPdfHtml } from './templates/characterHtml.js';
import { getSkillsCatalog } from '../services/skillsCatalog.js';
import { db } from '../db/pool.js';
import { loadCharacterPdfI18n, type CharacterPdfI18n } from './i18n.js';
import { buildCharacterPdfViewModel } from './pdfViewModel.js';

export type PdfOptions = { alchemy_style?: 'w1' | 'w2' };

export class CharacterPdfService {
  private static browserPromise: Promise<Browser> | null = null;
  private static i18nCache = new Map<string, CharacterPdfI18n>();

  private static async getBrowser(): Promise<Browser> {
    if (!CharacterPdfService.browserPromise) {
      CharacterPdfService.browserPromise = chromium.launch({ headless: true });
    }
    return CharacterPdfService.browserPromise;
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
    const cached = CharacterPdfService.i18nCache.get(lang);
    if (cached) return cached;
    const i18n = await this.withTimeout(loadCharacterPdfI18n(lang), 2500);
    CharacterPdfService.i18nCache.set(lang, i18n);
    return i18n;
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

    const pdfVm = buildCharacterPdfViewModel(characterJson, {
      lang,
      i18n,
      skillsCatalog,
      weaponDetailsById,
      armorDetailsById,
      potionDetailsById,
      vehicleDetailsById,
      recipeDetailsById,
    });
    const html = renderCharacterPdfHtml({ page1: pdfVm.page1, page2: pdfVm.page2, page3: pdfVm.page3, options });

    const browser = await CharacterPdfService.getBrowser();
    const context = await browser.newContext({
      viewport: { width: 1280, height: 720 },
      deviceScaleFactor: 2,
    });
    const page = await context.newPage();

    try {
      await page.setContent(html, { waitUntil: 'networkidle' });
      await page.emulateMedia({ media: 'print' });
      await page.waitForFunction('window.__pdfReady === true', { timeout: 1000 }).catch(() => undefined);

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
