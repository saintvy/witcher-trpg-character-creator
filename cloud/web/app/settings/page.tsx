"use client";

import { useEffect, useState } from "react";
import { useAuth } from "../auth-context";
import { apiFetch } from "../api-fetch";
import { useLanguage } from "../language-context";
import { Topbar } from "../components/Topbar";

type UserSettingsPayload = {
  useW1AlchemyIcons: boolean;
};

const API_URL = (process.env.NEXT_PUBLIC_API_URL ?? "/api").replace(/\/$/, "");

export default function SettingsPage() {
  const { lang, mounted, setLang } = useLanguage();
  const { isAuthenticated } = useAuth();
  const displayLang = mounted ? lang : "en";

  const [useW1AlchemyIcons, setUseW1AlchemyIcons] = useState(false);
  const [isSettingsLoading, setIsSettingsLoading] = useState(true);
  const [isSettingsSaving, setIsSettingsSaving] = useState(false);
  const [settingsError, setSettingsError] = useState<string | null>(null);

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
        note: "Affects ingredient icons in generated PDF recipes.",
        loading: "Loading saved settings...",
        saving: "Saving...",
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
        note: "Влияет на иконки ингредиентов в PDF с рецептами.",
        loading: "Загружаем сохранённые настройки...",
        saving: "Сохраняем...",
      },
      languages: {
        ru: "Русский",
        en: "Английский",
      },
    },
  } as const;

  const t = content[displayLang];

  useEffect(() => {
    if (!mounted || !isAuthenticated) {
      setIsSettingsLoading(false);
      return;
    }

    let cancelled = false;
    setIsSettingsLoading(true);
    setSettingsError(null);

    void (async () => {
      try {
        const response = await apiFetch(`${API_URL}/user/settings`, {
          method: "GET",
          cache: "no-store",
        });
        if (!response.ok) {
          throw new Error(`Request failed with status ${response.status}`);
        }
        const json = (await response.json()) as Partial<UserSettingsPayload>;
        if (!cancelled && typeof json.useW1AlchemyIcons === "boolean") {
          setUseW1AlchemyIcons(json.useW1AlchemyIcons);
        }
      } catch (error) {
        if (!cancelled) {
          setSettingsError(error instanceof Error ? error.message : String(error));
        }
      } finally {
        if (!cancelled) {
          setIsSettingsLoading(false);
        }
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [mounted, isAuthenticated]);

  async function handleW1AlchemyToggle(): Promise<void> {
    if (isSettingsLoading || isSettingsSaving) return;

    const previous = useW1AlchemyIcons;
    const next = !previous;

    setUseW1AlchemyIcons(next);
    setIsSettingsSaving(true);
    setSettingsError(null);

    try {
      const response = await apiFetch(`${API_URL}/user/settings`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ useW1AlchemyIcons: next }),
      });
      if (!response.ok) {
        throw new Error(`Request failed with status ${response.status}`);
      }
      const json = (await response.json()) as Partial<UserSettingsPayload>;
      if (typeof json.useW1AlchemyIcons === "boolean") {
        setUseW1AlchemyIcons(json.useW1AlchemyIcons);
      }
    } catch (error) {
      setUseW1AlchemyIcons(previous);
      setSettingsError(error instanceof Error ? error.message : String(error));
    } finally {
      setIsSettingsSaving(false);
    }
  }

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
                disabled={isSettingsLoading || isSettingsSaving}
                onClick={() => void handleW1AlchemyToggle()}
              />
            </div>
            {isSettingsLoading ? <div className="coming-soon">{t.alchemyCard.loading}</div> : null}
            {isSettingsSaving ? <div className="coming-soon">{t.alchemyCard.saving}</div> : null}
            {settingsError ? <div className="coming-soon">{settingsError}</div> : null}
            <div className="coming-soon">{t.alchemyCard.note}</div>
          </div>
        </div>
      </section>
    </>
  );
}
