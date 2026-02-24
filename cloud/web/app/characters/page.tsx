"use client";

import { ChangeEvent, useCallback, useRef } from "react";
import Link from "next/link";
import { useLanguage } from "../language-context";
import { Topbar } from "../components/Topbar";

const BUILDER_IMPORT_HANDOFF_STORAGE_KEY = "wcc_builder_import_handoff";

export default function CharactersPage() {
  const { lang, mounted } = useLanguage();
  const displayLang = mounted ? lang : "en";
  const importInputRef = useRef<HTMLInputElement>(null);

  const content = {
    en: {
      title: "Characters",
      subtitle: "List of player and NPC characters",
      description: "Character list with filters, sorting, and pagination will be implemented here.",
      cardTitle: "Character List (placeholder)",
      cardSubtitle: "Column names and structure will be synchronized with the API contract.",
      filters: {
        race: "Filter: race = witcher",
        profession: "Profession: all",
        campaign: "Campaign: any",
      },
      tableHeaders: {
        name: "Name",
        race: "Race",
        status: "Social Status",
        profession: "Profession",
        land: "Land",
        created: "Created",
        actions: "Actions",
      },
      buttons: {
        import: "Import from JSON",
        create: "+ Create",
      },
      characters: [
        {
          name: "Oath of the Wolf School",
          race: "witcher",
          status: "fear",
          profession: "Witcher",
          land: "Northern Kingdoms",
          created: "01.11.1272",
        },
        {
          name: "Aedirnian Deserter",
          race: "human",
          status: "equality",
          profession: "Warrior",
          land: "Aedirn",
          created: "13.09.1271",
        },
        {
          name: "Elven Archer from Dol Blathanna",
          race: "elf",
          status: "equality",
          profession: "Warrior / Bard",
          land: "Dol Blathanna",
          created: "22.03.1270",
        },
      ],
    },
    ru: {
      title: "Персонажи",
      subtitle: "Список персонажей игрока и NPC",
      description: "Список персонажей игрока и NPC. Здесь будут фильтры, сортировка и пагинация.",
      cardTitle: "Список персонажей (заглушка)",
      cardSubtitle: "Названия колонок и структуры будут синхронизированы с контрактом API.",
      filters: {
        race: "Фильтр: раса = ведьмак",
        profession: "Профессия: все",
        campaign: "Кампания: любая",
      },
      tableHeaders: {
        name: "Имя",
        race: "Раса",
        status: "Соц. статус",
        profession: "Профессия",
        land: "Земля",
        created: "Создан",
        actions: "Действия",
      },
      buttons: {
        import: "Импорт из JSON",
        create: "+ Создать",
      },
      characters: [
        {
          name: "Клятва Школы Волка",
          race: "ведьмак",
          status: "опасение",
          profession: "Ведьмак",
          land: "Королевства Севера",
          created: "01.11.1272",
        },
        {
          name: "Аэдирнский дезертир",
          race: "человек",
          status: "равенство",
          profession: "Воин",
          land: "Аэдирн",
          created: "13.09.1271",
        },
        {
          name: "Эльф-лучник из Доль Блатанны",
          race: "эльф",
          status: "равенство",
          profession: "Воин / Бард",
          land: "Доль Блатанна",
          created: "22.03.1270",
        },
      ],
    },
  } as const;

  const t = content[displayLang];

  const openImportPicker = useCallback(() => {
    importInputRef.current?.click();
  }, []);

  const importToBuilder = useCallback(async (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    event.target.value = "";
    if (!file) return;

    try {
      const raw = await file.text();
      // Quick shape check so obvious invalid files fail here before redirect.
      const parsed = JSON.parse(raw) as unknown;
      if (parsed === null || parsed === undefined) {
        throw new Error("Empty file");
      }
      sessionStorage.setItem(BUILDER_IMPORT_HANDOFF_STORAGE_KEY, raw);
      window.location.href = "/builder";
    } catch {
      window.alert(
        displayLang === "ru"
          ? "Не удалось импортировать JSON. Проверь формат файла."
          : "Failed to import JSON. Please check the file format.",
      );
    }
  }, [displayLang]);

  return (
    <>
      <Topbar title={t.title} subtitle={t.subtitle} />
      <section className="content" suppressHydrationWarning>
        <div className="section-title-row" style={{ justifyContent: "flex-start" }}>
          <div style={{ display: "flex", gap: "6px" }}>
            <Link href="/builder" className="btn btn-primary" style={{ textDecoration: "none" }}>
              {t.buttons.create}
            </Link>
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
          <div className="card-header">
            <div>
              <div className="card-title">{t.cardTitle}</div>
              <div className="card-subtitle">{t.cardSubtitle}</div>
            </div>
            <div className="pill-row">
              <span className="pill">{t.filters.race}</span>
              <span className="pill">{t.filters.profession}</span>
              <span className="pill">{t.filters.campaign}</span>
            </div>
          </div>
          <table>
            <thead>
              <tr>
                <th>{t.tableHeaders.name}</th>
                <th>{t.tableHeaders.race}</th>
                <th>{t.tableHeaders.status}</th>
                <th>{t.tableHeaders.profession}</th>
                <th>{t.tableHeaders.land}</th>
                <th>{t.tableHeaders.created}</th>
                <th>{t.tableHeaders.actions}</th>
              </tr>
            </thead>
            <tbody>
              {t.characters.map((character, idx) => (
                <tr key={idx}>
                  <td>{character.name}</td>
                  <td>
                    <span className={`tag ${character.race === "человек" || character.race === "human" ? "red" : ""}`}>
                      <span className="tag-dot"></span>
                      {character.race}
                    </span>
                  </td>
                  <td>{character.status}</td>
                  <td>{character.profession}</td>
                  <td>{character.land}</td>
                  <td>{character.created}</td>
                  <td>
                    <button className="btn-icon">👁</button>
                    <button className="btn-icon">✏️</button>
                    <button className="btn-icon">🗑</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </>
  );
}
