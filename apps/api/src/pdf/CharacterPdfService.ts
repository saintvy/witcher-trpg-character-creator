import { chromium, type Browser } from 'playwright';
import { mapCharacterJsonToPage1Vm, type SkillCatalogInfo, type WeaponDetails, type ArmorDetails, type PotionDetails } from './viewModel.js';
import { renderCharacterPage1Html } from './templates/characterHtml.js';
import { getSkillsCatalog } from '../services/skillsCatalog.js';
import { db } from '../db/pool.js';

export class CharacterPdfService {
  private static browserPromise: Promise<Browser> | null = null;

  private static async getBrowser(): Promise<Browser> {
    if (!CharacterPdfService.browserPromise) {
      CharacterPdfService.browserPromise = chromium.launch({ headless: true });
    }
    return CharacterPdfService.browserPromise;
  }

  private detectLang(characterJson: unknown): string {
    const containsCyrillic = (value: unknown): boolean => {
      if (typeof value === 'string') return /[А-Яа-яЁё]/.test(value);
      if (Array.isArray(value)) return value.some(containsCyrillic);
      if (typeof value === 'object' && value !== null) return Object.values(value as Record<string, unknown>).some(containsCyrillic);
      return false;
    };

    const record =
      characterJson && typeof characterJson === 'object' && !Array.isArray(characterJson) ? (characterJson as Record<string, unknown>) : null;

    const tryReadLang = (value: unknown): string | null => {
      if (!value) return null;
      if (typeof value === 'object' && !Array.isArray(value)) {
        const rec = value as Record<string, unknown>;
        const lang = rec.lang;
        if (typeof lang === 'string' && lang) return lang;
      }
      if (Array.isArray(value)) {
        for (const x of value) {
          const found = tryReadLang(x);
          if (found) return found;
        }
      } else if (typeof value === 'object' && value !== null) {
        for (const v of Object.values(value as Record<string, unknown>)) {
          const found = tryReadLang(v);
          if (found) return found;
        }
      }
      return null;
    };

    const explicitLang = tryReadLang(record);
    if (explicitLang) return explicitLang;

    return containsCyrillic(characterJson) ? 'ru' : 'en';
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

  async generatePdfBuffer(characterJson: unknown): Promise<Buffer> {
    const lang = this.detectLang(characterJson);

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

    const vm = mapCharacterJsonToPage1Vm(characterJson, { skillsCatalog, weaponDetailsById, armorDetailsById, potionDetailsById });
    const html = renderCharacterPage1Html(vm);

    const browser = await CharacterPdfService.getBrowser();
    const context = await browser.newContext({
      viewport: { width: 1280, height: 720 },
      deviceScaleFactor: 2,
    });
    const page = await context.newPage();

    try {
      await page.setContent(html, { waitUntil: 'networkidle' });
      await page.emulateMedia({ media: 'print' });

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
