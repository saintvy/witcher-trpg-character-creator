"use client";

import { ChangeEvent, useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useAuth } from "../auth-context";
import { useLanguage } from "../language-context";
import { Topbar } from "../components/Topbar";
import { apiFetch } from "../api-fetch";
import { AvatarPopup } from "../components/AvatarPopup";

const BUILDER_IMPORT_HANDOFF_STORAGE_KEY = "wcc_builder_import_handoff";
const RUN_SEED_STORAGE_KEY = "wcc_builder_run_seed";
const RUN_PROGRESS_STORAGE_PREFIX = "wcc_builder_progress";
const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "/api";

type CharacterListItem = {
  id: string;
  name: string | null;
  race: string | null;
  profession: string | null;
  createdAt: string;
  avatarUrl?: string | null;
};

type CharactersListResponse = {
  items?: CharacterListItem[];
};

function normalizeCode(value: string | null | undefined): string {
  return typeof value === "string" ? value.trim().toLowerCase() : "";
}

function getRaceVisual(race: string | null, lang: "en" | "ru") {
  const code = normalizeCode(race);
  const byCode: Record<string, { ru: string; en: string; dot: string; border: string; bg: string; text: string }> = {
    witcher: { ru: "Ведьмак", en: "Witcher", dot: "#d8bf6a", border: "rgba(216,191,106,0.45)", bg: "rgba(216,191,106,0.08)", text: "#e8d7a0" },
    human: { ru: "Человек", en: "Human", dot: "#d35757", border: "rgba(211,87,87,0.45)", bg: "rgba(211,87,87,0.08)", text: "#f1b0b0" },
    elf: { ru: "Эльф", en: "Elf", dot: "#4ec27f", border: "rgba(78,194,127,0.45)", bg: "rgba(78,194,127,0.08)", text: "#9ce2bb" },
    dwarf: { ru: "Краснолюд", en: "Dwarf", dot: "#c9853b", border: "rgba(201,133,59,0.45)", bg: "rgba(201,133,59,0.08)", text: "#e4b483" },
    gnome: { ru: "Гном", en: "Gnome", dot: "#6cb6ff", border: "rgba(108,182,255,0.45)", bg: "rgba(108,182,255,0.08)", text: "#b6dbff" },
    halfling: { ru: "Низушек", en: "Halfling", dot: "#d6a65d", border: "rgba(214,166,93,0.45)", bg: "rgba(214,166,93,0.08)", text: "#ecd2a5" },
    vran: { ru: "Вран", en: "Vran", dot: "#8e6dd9", border: "rgba(142,109,217,0.45)", bg: "rgba(142,109,217,0.08)", text: "#ccb9f5" },
    werebbubb: { ru: "Баболак", en: "Werebbubb", dot: "#9b7f63", border: "rgba(155,127,99,0.45)", bg: "rgba(155,127,99,0.08)", text: "#d4c1af" },
    werebbubbs: { ru: "Баболаки", en: "Werebbubbs", dot: "#9b7f63", border: "rgba(155,127,99,0.45)", bg: "rgba(155,127,99,0.08)", text: "#d4c1af" },
    bobolak: { ru: "Баболак", en: "Bobolak", dot: "#9b7f63", border: "rgba(155,127,99,0.45)", bg: "rgba(155,127,99,0.08)", text: "#d4c1af" },
    bobolok: { ru: "Баболак", en: "Bobolak", dot: "#9b7f63", border: "rgba(155,127,99,0.45)", bg: "rgba(155,127,99,0.08)", text: "#d4c1af" },
  };

  const item = byCode[code];
  if (item) {
    return {
      label: lang === "ru" ? item.ru : item.en,
      style: { borderColor: item.border, background: item.bg, color: item.text },
      dotColor: item.dot,
    };
  }

  return {
    label: race || (lang === "ru" ? "Неизвестно" : "Unknown"),
    style: undefined,
    dotColor: "#48e29b",
  };
}

function formatProfession(profession: string | null, lang: "en" | "ru"): string {
  if (!profession) return lang === "ru" ? "—" : "—";
  const raw = profession.trim();
  const map: Record<string, { ru: string; en: string }> = {
    witcher: { ru: "Ведьмак", en: "Witcher" },
    bard: { ru: "Бард", en: "Bard" },
    doctor: { ru: "Доктор", en: "Doctor" },
    mage: { ru: "Маг", en: "Mage" },
    "man at arms": { ru: "Воин", en: "Man-at-Arms" },
    criminal: { ru: "Преступник", en: "Criminal" },
    priest: { ru: "Жрец", en: "Priest" },
    craftsman: { ru: "Ремесленник", en: "Craftsman" },
    merchant: { ru: "Купец", en: "Merchant" },
    druid: { ru: "Друид", en: "Druid" },
  };
  const key = raw.toLowerCase();
  if (map[key]) return lang === "ru" ? map[key]!.ru : map[key]!.en;
  return raw;
}

function formatDate(value: string, lang: "en" | "ru"): string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return new Intl.DateTimeFormat(lang === "ru" ? "ru-RU" : "en-US", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  }).format(date);
}

function parseFilenameFromDisposition(value: string | null): string | null {
  if (!value) return null;
  const star = /filename\*=UTF-8''([^;]+)/i.exec(value);
  if (star?.[1]) {
    try {
      return decodeURIComponent(star[1]);
    } catch {
      return star[1];
    }
  }
  const plain = /filename="?([^";]+)"?/i.exec(value);
  return plain?.[1] ?? null;
}

function triggerDownload(blob: Blob, fileName: string): void {
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = fileName;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

export default function CharactersPage() {
  const { lang } = useLanguage();
  const { mounted: authMounted, provider, isAuthenticated } = useAuth();
  const displayLang = lang;
  const importInputRef = useRef<HTMLInputElement>(null);
  const [items, setItems] = useState<CharacterListItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busyActionId, setBusyActionId] = useState<string | null>(null);
  const [avatarPopupCharId, setAvatarPopupCharId] = useState<string | null>(null);

  const content = {
    en: {
      title: "Characters",
      subtitle: "Your saved characters",
      table: {
        name: "Name",
        race: "Race",
        profession: "Profession",
        created: "Created",
        actions: "Actions",
      },
      buttons: {
        import: "Import from JSON",
        create: "+ Create",
      },
      actions: {
        history: "Download answer history",
        raw: "Download raw JSON",
        avatar: "Avatar",
      },
      states: {
        loading: "Loading characters...",
        empty: "No saved characters yet. Finish the survey and save your first one.",
        loadError: "Failed to load character list.",
        downloadError: "Failed to download file.",
      },
    },
    ru: {
      title: "Персонажи",
      subtitle: "Твои сохраненные персонажи",
      table: {
        name: "Имя",
        race: "Раса",
        profession: "Профессия",
        created: "Создан",
        actions: "Действия",
      },
      buttons: {
        import: "Импорт из JSON",
        create: "+ Создать",
      },
      actions: {
        history: "Скачать историю ответов",
        raw: "Скачать raw JSON",
        avatar: "Аватар",
      },
      states: {
        loading: "Загрузка персонажей...",
        empty: "Пока нет сохраненных персонажей. Заверши опрос и сохрани первого.",
        loadError: "Не удалось загрузить список персонажей.",
        downloadError: "Не удалось скачать файл.",
      },
    },
  } as const;

  const t = content[displayLang];
  const pdfActionTitle = displayLang === "ru" ? "Скачать PDF" : "Download PDF";
  const deleteActionTitle = displayLang === "ru" ? "Удалить персонажа" : "Delete character";
  const deleteConfirmText =
    displayLang === "ru"
      ? "Удалить этого персонажа? Действие необратимо."
      : "Delete this character? This action cannot be undone.";
  const deleteErrorText = displayLang === "ru" ? "Не удалось удалить персонажа." : "Failed to delete character.";

  const loadCharacters = useCallback(async () => {
    if (!authMounted) return;
    if (provider !== "none" && !isAuthenticated) return;

    setLoading(true);
    setError(null);
    try {
      const response = await apiFetch(`${API_URL}/characters`);
      if (!response.ok) {
        throw new Error(`Request failed with status ${response.status}`);
      }
      const data = (await response.json()) as CharactersListResponse;
      setItems(Array.isArray(data.items) ? data.items : []);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
      setItems([]);
    } finally {
      setLoading(false);
    }
  }, [authMounted, isAuthenticated, provider]);

  useEffect(() => {
    if (!authMounted) return;
    if (provider !== "none" && !isAuthenticated) return;
    void loadCharacters();
  }, [authMounted, isAuthenticated, loadCharacters, provider]);

  const openImportPicker = useCallback(() => {
    importInputRef.current?.click();
  }, []);

  const startFreshBuilder = useCallback(() => {
    try {
      sessionStorage.removeItem(BUILDER_IMPORT_HANDOFF_STORAGE_KEY);
      sessionStorage.removeItem(RUN_SEED_STORAGE_KEY);
      const keysToDelete: string[] = [];
      for (let i = 0; i < sessionStorage.length; i += 1) {
        const key = sessionStorage.key(i);
        if (key && key.startsWith(`${RUN_PROGRESS_STORAGE_PREFIX}:`)) {
          keysToDelete.push(key);
        }
      }
      for (const key of keysToDelete) {
        sessionStorage.removeItem(key);
      }
    } catch {
      // ignore storage access failures
    }
    window.location.href = "/builder/";
  }, []);

  const importToBuilder = useCallback(async (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    event.target.value = "";
    if (!file) return;

    try {
      const raw = await file.text();
      const parsed = JSON.parse(raw) as unknown;
      if (parsed === null || parsed === undefined) {
        throw new Error("Empty file");
      }
      sessionStorage.setItem(BUILDER_IMPORT_HANDOFF_STORAGE_KEY, raw);
      window.location.href = "/builder/";
    } catch {
      window.alert(displayLang === "ru" ? "Не удалось импортировать JSON. Проверь формат файла." : "Failed to import JSON. Please check the file format.");
    }
  }, [displayLang]);

  const downloadCharacterFile = useCallback(async (id: string, kind: "history" | "raw") => {
    try {
      setBusyActionId(`${id}:${kind}`);
      const url =
        kind === "history"
          ? `${API_URL}/characters/${id}/history-export`
          : `${API_URL}/characters/${id}/raw`;
      const response = await apiFetch(url);
      if (!response.ok) {
        throw new Error(`Request failed with status ${response.status}`);
      }
      const blob = await response.blob();
      const fileName =
        parseFilenameFromDisposition(response.headers.get("content-disposition")) ??
        (kind === "history" ? "character-history.json" : "character-raw.json");
      triggerDownload(blob, fileName);
    } catch (err) {
      window.alert(displayLang === "ru" ? t.states.downloadError : t.states.downloadError);
    } finally {
      setBusyActionId(null);
    }
  }, [displayLang, t.states.downloadError]);

  const downloadCharacterPdf = useCallback(async (id: string) => {
    try {
      setBusyActionId(`${id}:pdf`);
      const response = await apiFetch(`${API_URL}/characters/${id}/pdf?lang=${displayLang}`);
      if (!response.ok) {
        throw new Error(`Request failed with status ${response.status}`);
      }
      const blob = await response.blob();
      const fileName =
        parseFilenameFromDisposition(response.headers.get("content-disposition")) ??
        "character-sheet.pdf";
      triggerDownload(blob, fileName);
    } catch {
      window.alert(displayLang === "ru" ? "Не удалось скачать PDF." : "Failed to download PDF.");
    } finally {
      setBusyActionId(null);
    }
  }, [displayLang]);

  const deleteCharacter = useCallback(async (id: string) => {
    if (!window.confirm(deleteConfirmText)) return;

    try {
      setBusyActionId(`${id}:delete`);
      const response = await apiFetch(`${API_URL}/characters/${id}`, {
        method: "DELETE",
      });
      if (!response.ok) {
        throw new Error(`Request failed with status ${response.status}`);
      }

      setItems((prev) => prev.filter((item) => item.id !== id));
      try {
        window.dispatchEvent(new Event("wcc:characters-changed"));
      } catch {
        // ignore browser event failures
      }
    } catch {
      window.alert(deleteErrorText);
    } finally {
      setBusyActionId(null);
    }
  }, [deleteConfirmText, deleteErrorText]);

  const rows = useMemo(() => items, [items]);

  return (
    <>
      <Topbar title={t.title} subtitle={t.subtitle} />
      <section className="content" suppressHydrationWarning>
        <div className="section-title-row" style={{ justifyContent: "flex-start" }}>
          <div style={{ display: "flex", gap: "6px" }}>
            <button
              type="button"
              className="btn btn-primary"
              style={{ textDecoration: "none" }}
              onClick={startFreshBuilder}
            >
              {t.buttons.create}
            </button>
            <button type="button" className="btn" onClick={openImportPicker}>
              {t.buttons.import}
            </button>
          </div>
        </div>
        <input
          ref={importInputRef}
          type="file"
          accept="application/json,.json"
          onChange={(event) => void importToBuilder(event)}
          style={{ display: "none" }}
        />

        <div className="card table-card">
          {loading ? (
            <div className="section-note">{t.states.loading}</div>
          ) : error ? (
            <div className="survey-error" style={{ marginBottom: 0 }}>{t.states.loadError}: {error}</div>
          ) : rows.length === 0 ? (
            <div className="section-note">{t.states.empty}</div>
          ) : (
            <table>
              <thead>
                <tr>
                  <th>{t.table.name}</th>
                  <th>{t.table.race}</th>
                  <th>{t.table.profession}</th>
                  <th>{t.table.created}</th>
                  <th>{t.table.actions}</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((character) => {
                  const raceVisual = getRaceVisual(character.race, displayLang);
                  const isBusyHistory = busyActionId === `${character.id}:history`;
                  const isBusyPdf = busyActionId === `${character.id}:pdf`;
                  const isBusyDelete = busyActionId === `${character.id}:delete`;
                  return (
                    <tr key={character.id}>
                      <td>{character.name || (displayLang === "ru" ? "Без имени" : "Unnamed")}</td>
                      <td>
                        <span className="tag" style={raceVisual.style}>
                          <span className="tag-dot" style={{ background: raceVisual.dotColor }}></span>
                          {raceVisual.label}
                        </span>
                      </td>
                      <td>{formatProfession(character.profession, displayLang)}</td>
                      <td>{formatDate(character.createdAt, displayLang)}</td>
                      <td>
                        <button
                          type="button"
                          className="btn-icon"
                          title={t.actions.avatar}
                          onClick={() => setAvatarPopupCharId(character.id)}
                          disabled={Boolean(busyActionId)}
                        >
                          🖼️
                        </button>
                        <button
                          type="button"
                          className="btn-icon"
                          title={t.actions.history}
                          onClick={() => void downloadCharacterFile(character.id, "history")}
                          disabled={Boolean(busyActionId)}
                        >
                          {isBusyHistory ? "…" : "📜"}
                        </button>
                        <button
                          type="button"
                          className="btn-icon"
                          title={displayLang === "ru" ? "Скачать PDF" : "Download PDF"}
                          onClick={() => void downloadCharacterPdf(character.id)}
                          disabled={Boolean(busyActionId)}
                        >
                          {isBusyPdf ? "…" : "📥"}
                        </button>
                        <span aria-hidden="true" style={{ whiteSpace: "pre" }}>
                          {"      "}
                        </span>
                        <button
                          type="button"
                          className="btn-icon"
                          title={deleteActionTitle}
                          onClick={() => void deleteCharacter(character.id)}
                          disabled={Boolean(busyActionId)}
                        >
                          {isBusyDelete ? "…" : "🗑️"}
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>
      </section>
      {avatarPopupCharId && (
        <AvatarPopup
          characterId={avatarPopupCharId}
          hasAvatar={Boolean(items.find(it => it.id === avatarPopupCharId)?.avatarUrl)}
          lang={displayLang}
          onClose={() => setAvatarPopupCharId(null)}
        />
      )}
    </>
  );
}
