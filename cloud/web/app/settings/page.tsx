"use client";

import { useState } from "react";
import { useLanguage } from "../language-context";
import { Topbar } from "../components/Topbar";

export default function SettingsPage() {
  const { lang, mounted, setLang } = useLanguage();
  const displayLang = mounted ? lang : "en";
  const [useW1AlchemyIcons, setUseW1AlchemyIcons] = useState(false);

  const content = {
    en: {
      title: "Settings",
      subtitle: "Language and display preferences",
      languageCard: {
        title: "Language",
        subtitle: "Interface language",
        uiLanguage: "UI Language",
        note: "The selected language is applied immediately.",
      },
      alchemyCard: {
        title: "Alchemy icons",
        subtitle: "Visual style",
        toggleLabel: "Witcher 1 style alchemy icons",
        note: "Clickable now, functional behavior will be connected later.",
      },
      languages: {
        ru: "Russian",
        en: "English",
      },
    },
    ru: {
      title: "Настройки",
      subtitle: "Язык и параметры отображения",
      languageCard: {
        title: "Язык",
        subtitle: "Язык интерфейса",
        uiLanguage: "Язык UI",
        note: "Выбранный язык применяется сразу.",
      },
      alchemyCard: {
        title: "Иконки алхимии",
        subtitle: "Визуальный стиль",
        toggleLabel: "Иконки алхимии в стиле Witcher 1",
        note: "Переключатель кликабельный, но пока ни на что не влияет.",
      },
      languages: {
        ru: "Русский",
        en: "Английский",
      },
    },
  } as const;

  const t = content[displayLang];

  return (
    <>
      <Topbar title={t.title} subtitle={t.subtitle} />
      <section className="content" suppressHydrationWarning>
        <div className="settings-grid">
          <div className="card">
            <div className="card-header">
              <div>
                <div className="card-title">{t.languageCard.title}</div>
                <div className="card-subtitle">{t.languageCard.subtitle}</div>
              </div>
            </div>
            <div className="field">
              <label className="field-label">
                {t.languageCard.uiLanguage}
                <span>interface</span>
              </label>
              <select value={lang} onChange={(e) => setLang(e.target.value as "en" | "ru")}>
                <option value="ru">{t.languages.ru}</option>
                <option value="en">{t.languages.en}</option>
              </select>
            </div>
            <div className="coming-soon">{t.languageCard.note}</div>
          </div>

          <div className="card">
            <div className="card-header">
              <div>
                <div className="card-title">{t.alchemyCard.title}</div>
                <div className="card-subtitle">{t.alchemyCard.subtitle}</div>
              </div>
            </div>
            <div className="toggle-row">
              <div className="toggle-label">{t.alchemyCard.toggleLabel}</div>
              <button
                type="button"
                className={`toggle-switch ${useW1AlchemyIcons ? "on" : ""}`}
                aria-pressed={useW1AlchemyIcons}
                aria-label={t.alchemyCard.toggleLabel}
                onClick={() => setUseW1AlchemyIcons((value) => !value)}
              />
            </div>
            <div className="coming-soon">{t.alchemyCard.note}</div>
          </div>
        </div>
      </section>
    </>
  );
}
