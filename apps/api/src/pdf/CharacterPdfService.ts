import { chromium, type Browser } from 'playwright';
import { mapCharacterJsonToViewModel } from './viewModel.js';
import { renderCharacterHtml } from './templates/characterHtml.js';
import { getSkillsCatalog } from '../services/skillsCatalog.js';

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

    const record = characterJson && typeof characterJson === 'object' && !Array.isArray(characterJson) ? (characterJson as Record<string, unknown>) : null;
    const gear = record?.gear;
    if (Array.isArray(gear)) {
      for (const item of gear) {
        if (item && typeof item === 'object' && !Array.isArray(item) && typeof (item as any).lang === 'string') {
          const lang = String((item as any).lang);
          if (lang) return lang;
        }
      }
    }

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

    const skillNameById = new Map<string, string>();
    const skillIsDifficultById = new Map<string, boolean>();
    try {
      const catalog = await this.withTimeout(getSkillsCatalog({ lang }), 2500);
      for (const s of catalog.skills) {
        skillNameById.set(s.id, s.name);
        skillIsDifficultById.set(s.id, Boolean(s.isDifficult));
      }
    } catch (error) {
      console.error('[pdf] skills catalog load failed', error);
    }

    const vm = mapCharacterJsonToViewModel(characterJson, { skillNameById, skillIsDifficultById });
    const html = renderCharacterHtml(vm);

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
