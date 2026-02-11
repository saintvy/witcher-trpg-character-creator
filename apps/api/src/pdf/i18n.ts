import { loadCharacterPdfPage1I18n, type CharacterPdfPage1I18n } from './pages/page1I18n.js';
import { loadCharacterPdfPage2I18n, type CharacterPdfPage2I18n } from './pages/page2I18n.js';

export type CharacterPdfI18n = {
  lang: string;
  page1: CharacterPdfPage1I18n;
  page2: CharacterPdfPage2I18n;
};

export async function loadCharacterPdfI18n(lang: string): Promise<CharacterPdfI18n> {
  const [page1, page2] = await Promise.all([
    loadCharacterPdfPage1I18n(lang),
    loadCharacterPdfPage2I18n(lang),
  ]);
  return { lang, page1, page2 };
}
