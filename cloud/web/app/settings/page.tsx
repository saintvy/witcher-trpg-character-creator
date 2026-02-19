"use client";

import { useLanguage } from "../language-context";
import { Topbar } from "../components/Topbar";

export default function SettingsPage() {
  const { lang, mounted, setLang } = useLanguage();
  // Use default language until mounted to avoid hydration mismatch
  const displayLang = mounted ? lang : "en";

  const content = {
    en: {
      title: "Settings",
      subtitle: "Portal settings and preferences",
      description: "Future settings for UI, localization, export, and synchronization with external services.",
      cards: {
        theme: {
          title: "Interface Theme",
          subtitle: "Light / dark / system",
          darkTheme: "Dark theme (current)",
          autoSystem: "Auto by system",
        },
        localization: {
          title: "Localization",
          subtitle: "Interface and rule text language",
          uiLanguage: "UI Language",
          multiLanguage: "multi-language",
          note: "Link to i18n key system (race, profession_local, etc.) will be here.",
        },
        export: {
          title: "Export and Integrations",
          subtitle: "PDF, FoundryVTT, Roll20, JSON",
          exportPDF: "Export PDF sheet in one click",
          generateJSON: "Generate JSON saves",
          virtualTable: "Virtual tabletop integration",
        },
      },
      footer: {
        note: "This is only a visual reference. All data here are placeholders.",
        link: "Open character API contract",
      },
      buttons: {
        reset: "Reset to default",
        save: "Save",
      },
      languages: {
        ru: "Russian",
        en: "English",
      },
    },
    ru: {
      title: "Настройки",
      subtitle: "Настройки портала и предпочтения",
      description: "Будущие настройки UI, локализации, экспорта и синхронизации с внешними сервисами.",
      cards: {
        theme: {
          title: "Тема интерфейса",
          subtitle: "Светлая / тёмная / системная",
          darkTheme: "Тёмная тема (как сейчас)",
          autoSystem: "Авто по системе",
        },
        localization: {
          title: "Локализация",
          subtitle: "Язык интерфейса и текстов правил",
          uiLanguage: "Язык UI",
          multiLanguage: "multi-language",
          note: "Ссылка на систему i18n-ключей (race, profession_local и т. д.) будет здесь.",
        },
        export: {
          title: "Экспорт и интеграции",
          subtitle: "PDF, FoundryVTT, Roll20, JSON",
          exportPDF: "Экспорт PDF листа в один клик",
          generateJSON: "Генерировать JSON сохранения",
          virtualTable: "Интеграция с виртуальным столом",
        },
      },
      footer: {
        note: "Это только визуальный референс. Все данные здесь — заглушки.",
        link: "Открыть API контракт персонажа",
      },
      buttons: {
        reset: "Сбросить до дефолта",
        save: "Сохранить",
      },
      languages: {
        ru: "Русский",
        en: "Английский",
      },
    },
  };

  const t = content[displayLang];

  return (
    <>
      <Topbar title={t.title} subtitle={t.subtitle} />
      <section className="content" suppressHydrationWarning>
        <div className="section-title-row">
          <div>
            <div className="section-title">{t.title}</div>
            <div className="section-note">{t.description}</div>
          </div>
          <div style={{ display: "flex", gap: "6px" }}>
            <button className="btn">{t.buttons.reset}</button>
            <button className="btn btn-primary">{t.buttons.save}</button>
          </div>
        </div>

        <div className="settings-grid">
          <div className="card">
            <div className="card-header">
              <div>
                <div className="card-title">{t.cards.theme.title}</div>
                <div className="card-subtitle">{t.cards.theme.subtitle}</div>
              </div>
            </div>
            <div className="toggle-row">
              <div className="toggle-label">{t.cards.theme.darkTheme}</div>
              <div className="toggle-switch on"></div>
            </div>
            <div className="toggle-row">
              <div className="toggle-label">{t.cards.theme.autoSystem}</div>
              <div className="toggle-switch"></div>
            </div>
          </div>

          <div className="card">
            <div className="card-header">
              <div>
                <div className="card-title">{t.cards.localization.title}</div>
                <div className="card-subtitle">{t.cards.localization.subtitle}</div>
              </div>
            </div>
            <div className="field">
              <label className="field-label">
                {t.cards.localization.uiLanguage}
                <span>{t.cards.localization.multiLanguage}</span>
              </label>
              <select value={lang} onChange={(e) => setLang(e.target.value as "en" | "ru")}>
                <option value="ru">{t.languages.ru}</option>
                <option value="en">{t.languages.en}</option>
              </select>
            </div>
            <div className="coming-soon">{t.cards.localization.note}</div>
          </div>

          <div className="card">
            <div className="card-header">
              <div>
                <div className="card-title">{t.cards.export.title}</div>
                <div className="card-subtitle">{t.cards.export.subtitle}</div>
              </div>
            </div>
            <div className="toggle-row">
              <div className="toggle-label">{t.cards.export.exportPDF}</div>
              <div className="toggle-switch on"></div>
            </div>
            <div className="toggle-row">
              <div className="toggle-label">{t.cards.export.generateJSON}</div>
              <div className="toggle-switch on"></div>
            </div>
            <div className="toggle-row">
              <div className="toggle-label">{t.cards.export.virtualTable}</div>
              <div className="toggle-switch"></div>
            </div>
          </div>
        </div>

        <div className="footer-note">
          <span>{t.footer.note}</span>
          <span className="link-muted">{t.footer.link}</span>
        </div>
      </section>
    </>
  );
}
