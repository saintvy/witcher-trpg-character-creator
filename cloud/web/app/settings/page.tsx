"use client";

import { useEffect, useState } from "react";
import { useAuth } from "../auth-context";
import { apiFetch } from "../api-fetch";
import { useLanguage } from "../language-context";
import { Topbar } from "../components/Topbar";

type PdfTableKey =
  | "allies"
  | "enemies"
  | "alchemyRecipes"
  | "blueprints"
  | "components"
  | "spellsSigns"
  | "invocations"
  | "rituals"
  | "hexes";

type PdfTableSetting = {
  showIfEmpty: boolean;
  emptyRows: number;
};

type PdfTablesSettings = Record<PdfTableKey, PdfTableSetting>;

type UserSettingsPayload = {
  useW1AlchemyIcons: boolean;
  pdfTables: PdfTablesSettings;
};

const API_URL = (process.env.NEXT_PUBLIC_API_URL ?? "/api").replace(/\/$/, "");

const PDF_TABLE_ORDER: PdfTableKey[] = [
  "allies",
  "enemies",
  "alchemyRecipes",
  "blueprints",
  "components",
  "spellsSigns",
  "invocations",
  "rituals",
  "hexes",
];

const DEFAULT_PDF_TABLE_SETTINGS: PdfTablesSettings = {
  allies: { showIfEmpty: false, emptyRows: 0 },
  enemies: { showIfEmpty: false, emptyRows: 0 },
  alchemyRecipes: { showIfEmpty: true, emptyRows: 3 },
  blueprints: { showIfEmpty: true, emptyRows: 2 },
  components: { showIfEmpty: true, emptyRows: 3 },
  spellsSigns: { showIfEmpty: false, emptyRows: 0 },
  invocations: { showIfEmpty: false, emptyRows: 0 },
  rituals: { showIfEmpty: false, emptyRows: 0 },
  hexes: { showIfEmpty: false, emptyRows: 0 },
};

function clampEmptyRows(value: number): number {
  if (!Number.isFinite(value)) return 0;
  return Math.min(50, Math.max(0, Math.trunc(value)));
}

function cloneDefaultPdfTables(): PdfTablesSettings {
  return Object.fromEntries(
    PDF_TABLE_ORDER.map((key) => {
      const base = DEFAULT_PDF_TABLE_SETTINGS[key];
      return [key, { showIfEmpty: base.showIfEmpty, emptyRows: base.emptyRows }];
    }),
  ) as PdfTablesSettings;
}

function mergePdfTables(source: unknown): PdfTablesSettings {
  const out = cloneDefaultPdfTables();
  if (!source || typeof source !== "object" || Array.isArray(source)) {
    return out;
  }
  const rec = source as Record<string, unknown>;
  for (const key of PDF_TABLE_ORDER) {
    const node = rec[key];
    if (!node || typeof node !== "object" || Array.isArray(node)) continue;
    const nodeRec = node as Record<string, unknown>;
    const showIfEmptyValue = nodeRec.showIfEmpty ?? nodeRec.show_if_empty;
    const emptyRowsValue = nodeRec.emptyRows ?? nodeRec.empty_rows;
    if (typeof showIfEmptyValue === "boolean") {
      out[key].showIfEmpty = showIfEmptyValue;
    }
    if (typeof emptyRowsValue === "number" || typeof emptyRowsValue === "string") {
      const parsed = Number(emptyRowsValue);
      out[key].emptyRows = clampEmptyRows(parsed);
    }
  }
  return out;
}

export default function SettingsPage() {
  const { lang, mounted } = useLanguage();
  const { isAuthenticated } = useAuth();
  const displayLang = mounted ? lang : "en";

  const [useW1AlchemyIcons, setUseW1AlchemyIcons] = useState(false);
  const [pdfTables, setPdfTables] = useState<PdfTablesSettings>(cloneDefaultPdfTables);
  const [isSettingsLoading, setIsSettingsLoading] = useState(true);
  const [isSettingsSaving, setIsSettingsSaving] = useState(false);
  const [settingsError, setSettingsError] = useState<string | null>(null);

  const content = {
    en: {
      title: "Settings",
      subtitle: "Language and display preferences",
      alchemyCard: {
        title: "Graphic assets for PDF generation",
        subtitle: "Visual style",
        toggleLabel: "Witcher 1 style alchemy icons",
        loading: "Loading saved settings...",
        saving: "Saving...",
      },
      pdfTablesCard: {
        title: "Empty table display in PDF generation",
        subtitle: "Show empty tables and extra blank rows",
        tableName: "Table",
        showIfEmpty: "Show if empty",
        emptyRows: "Extra empty rows",
        note: "Rules are applied in addition to existing visibility logic.",
      },
      pdfTableNames: {
        allies: "Allies",
        enemies: "Enemies",
        alchemyRecipes: "Alchemy recipes",
        blueprints: "Blueprints",
        components: "Components",
        spellsSigns: "Spells / Signs",
        invocations: "Invocations",
        rituals: "Rituals",
        hexes: "Hexes",
      } as Record<PdfTableKey, string>,
    },
    ru: {
      title: "Настройки",
      subtitle: "Язык и параметры отображения",
      alchemyCard: {
        title: "Графические ассеты при генерации PDF",
        subtitle: "Визуальный стиль",
        toggleLabel: "Иконки алхимии в стиле Witcher 1",
        loading: "Загружаем сохранённые настройки...",
        saving: "Сохраняем...",
      },
      pdfTablesCard: {
        title: "Отображение пустых таблицы при генерации PDF",
        subtitle: "Показывать пустые таблицы и добавлять пустые строки",
        tableName: "Таблица",
        showIfEmpty: "Показывать пустую",
        emptyRows: "Пустых строк",
        note: "Правила применяются в дополнение к текущей логике отображения.",
      },
      pdfTableNames: {
        allies: "Друзья",
        enemies: "Враги",
        alchemyRecipes: "Алхимические рецепты",
        blueprints: "Чертежи",
        components: "Компоненты",
        spellsSigns: "Заклинания/Знаки",
        invocations: "Инвокации",
        rituals: "Ритуалы",
        hexes: "Порчи",
      } as Record<PdfTableKey, string>,
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
        const json = (await response.json()) as Partial<UserSettingsPayload> & {
          pdf_tables?: unknown;
        };
        if (cancelled) return;
        if (typeof json.useW1AlchemyIcons === "boolean") {
          setUseW1AlchemyIcons(json.useW1AlchemyIcons);
        }
        setPdfTables(mergePdfTables(json.pdfTables ?? json.pdf_tables));
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

  async function saveSettingsPatch(
    patch: Partial<UserSettingsPayload>,
  ): Promise<Partial<UserSettingsPayload> | null> {
    setIsSettingsSaving(true);
    setSettingsError(null);
    try {
      const response = await apiFetch(`${API_URL}/user/settings`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(patch),
      });
      if (!response.ok) {
        throw new Error(`Request failed with status ${response.status}`);
      }
      return (await response.json()) as Partial<UserSettingsPayload>;
    } catch (error) {
      setSettingsError(error instanceof Error ? error.message : String(error));
      return null;
    } finally {
      setIsSettingsSaving(false);
    }
  }

  async function handleW1AlchemyToggle(): Promise<void> {
    if (isSettingsLoading || isSettingsSaving) return;

    const previous = useW1AlchemyIcons;
    const next = !previous;

    setUseW1AlchemyIcons(next);
    const json = await saveSettingsPatch({ useW1AlchemyIcons: next });
    if (!json) {
      setUseW1AlchemyIcons(previous);
      return;
    }
    if (typeof json.useW1AlchemyIcons === "boolean") {
      setUseW1AlchemyIcons(json.useW1AlchemyIcons);
    }
    if (json.pdfTables) {
      setPdfTables(mergePdfTables(json.pdfTables));
    }
  }

  async function handlePdfTableToggle(key: PdfTableKey): Promise<void> {
    if (isSettingsLoading || isSettingsSaving) return;
    const previous = pdfTables;
    const next: PdfTablesSettings = {
      ...pdfTables,
      [key]: {
        ...pdfTables[key],
        showIfEmpty: !pdfTables[key].showIfEmpty,
      },
    };
    setPdfTables(next);
    const json = await saveSettingsPatch({ pdfTables: next });
    if (!json) {
      setPdfTables(previous);
      return;
    }
    if (json.pdfTables) {
      setPdfTables(mergePdfTables(json.pdfTables));
    }
  }

  function handlePdfEmptyRowsInput(key: PdfTableKey, value: string): void {
    const parsed = Number.parseInt(value, 10);
    const safeValue = Number.isFinite(parsed) ? clampEmptyRows(parsed) : 0;
    setPdfTables((prev) => ({
      ...prev,
      [key]: {
        ...prev[key],
        emptyRows: safeValue,
      },
    }));
  }

  async function handlePdfEmptyRowsCommit(key: PdfTableKey): Promise<void> {
    if (isSettingsLoading || isSettingsSaving) return;
    const previous = pdfTables;
    const next: PdfTablesSettings = {
      ...pdfTables,
      [key]: {
        ...pdfTables[key],
        emptyRows: clampEmptyRows(pdfTables[key].emptyRows),
      },
    };
    setPdfTables(next);
    const json = await saveSettingsPatch({ pdfTables: next });
    if (!json) {
      setPdfTables(previous);
      return;
    }
    if (json.pdfTables) {
      setPdfTables(mergePdfTables(json.pdfTables));
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
          </div>

          <div className="card">
            <div className="card-header">
              <div>
                <div className="card-title">{t.pdfTablesCard.title}</div>
                <div className="card-subtitle">{t.pdfTablesCard.subtitle}</div>
              </div>
            </div>
            <div className="settings-pdf-table-wrap">
              <table className="settings-pdf-table">
                <thead>
                  <tr>
                    <th>{t.pdfTablesCard.tableName}</th>
                    <th>{t.pdfTablesCard.showIfEmpty}</th>
                    <th>{t.pdfTablesCard.emptyRows}</th>
                  </tr>
                </thead>
                <tbody>
                  {PDF_TABLE_ORDER.map((key) => (
                    <tr key={key}>
                      <td>{t.pdfTableNames[key]}</td>
                      <td>
                        <button
                          type="button"
                          className={`toggle-switch ${pdfTables[key].showIfEmpty ? "on" : ""}`}
                          aria-pressed={pdfTables[key].showIfEmpty}
                          aria-label={`${t.pdfTableNames[key]} ${t.pdfTablesCard.showIfEmpty}`}
                          disabled={isSettingsLoading || isSettingsSaving}
                          onClick={() => void handlePdfTableToggle(key)}
                        />
                      </td>
                      <td>
                        <input
                          type="number"
                          min={0}
                          max={50}
                          step={1}
                          className="settings-number-input"
                          value={pdfTables[key].emptyRows}
                          disabled={isSettingsLoading || isSettingsSaving}
                          onChange={(e) => handlePdfEmptyRowsInput(key, e.target.value)}
                          onBlur={() => void handlePdfEmptyRowsCommit(key)}
                        />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            {isSettingsLoading ? <div className="coming-soon">{t.alchemyCard.loading}</div> : null}
            {isSettingsSaving ? <div className="coming-soon">{t.alchemyCard.saving}</div> : null}
            {settingsError ? <div className="coming-soon">{settingsError}</div> : null}
            <div className="coming-soon">{t.pdfTablesCard.note}</div>
          </div>
        </div>
      </section>
    </>
  );
}
