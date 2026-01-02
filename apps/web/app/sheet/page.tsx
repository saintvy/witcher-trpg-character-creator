"use client";

import { useLanguage } from "../language-context";
import { Topbar } from "../components/Topbar";

export default function SheetPage() {
  const { lang, mounted } = useLanguage();
  // Use default language until mounted to avoid hydration mismatch
  const displayLang = mounted ? lang : "en";

  const content = {
    en: {
      title: "Character Sheet",
      subtitle: "View and print character sheet",
      description: "Visual prototype of the final character sheet that can be exported to PDF.",
      characterName: "Geralt of Rivia",
      characterMeta: "Witcher • School of the Wolf\nNorthern Kingdoms • Social Status: fear",
      tags: {
        race: "Race: witcher",
        profession: "Profession: Witcher",
        age: "Age: 90+",
      },
      stats: {
        attributes: "Core Attributes",
        resources: "Resources",
      },
      skills: {
        title: "Skills and Signs",
        description: "Example grouping by rulebook: combat, general, magic, witcher signs.",
        mode: "Mode: read-only",
        showFormulas: "Show formulas",
      },
      signs: {
        title: "Witcher Signs",
        description: "Placeholder for magic / rituals / signs block.",
        signs: ["Yrden", "Quen", "Aard", "Igni", "Axii"],
      },
      timeline: {
        lifepath: {
          label: "Lifepath",
          text: "Born in the Northern Kingdoms. Survived the First and Second Northern Wars. Connected to Kaer Morhen and the School of the Wolf. Attitude to war: witcher neutrality.",
        },
        events: {
          label: "Key Events",
          text: "Participated in the Battle of Brenna, events in Vizima, Loc Muinne. Present: searching for Ciri and Yennefer, backdrop of the Third Northern War.",
        },
      },
      notes: {
        title: "Game Master Notes",
        description: "In GM mode, there will be an editable field with private notes here.",
        toggle: "Toggle editing",
      },
      buttons: {
        switchToGM: "Switch to GM version",
        exportPDF: "Export to PDF",
      },
    },
    ru: {
      title: "Лист персонажа",
      subtitle: "Просмотр и печать листа персонажа",
      description: "Визуальный прототип конечного листа, который можно будет экспортировать в PDF.",
      characterName: "Геральт из Ривии",
      characterMeta: "Ведьмак • Школа Волка\nКоролевства Севера • Соц. статус: опасение",
      tags: {
        race: "Раса: ведьмак",
        profession: "Профессия: Ведьмак",
        age: "Возраст: 90+",
      },
      stats: {
        attributes: "Основные параметры",
        resources: "Ресурсы",
      },
      skills: {
        title: "Навыки и знаки",
        description: "Пример группировки по книге правил: боевые, общие, магия, ведьмачьи знаки.",
        mode: "Режим: только-чтение",
        showFormulas: "Показывать формулы",
      },
      signs: {
        title: "Ведьмачьи знаки",
        description: "Просто заглушка для блока «магия» / «ритуалы» / «знаки».",
        signs: ["Ирден", "Квен", "Аард", "Игни", "Аксий"],
      },
      timeline: {
        lifepath: {
          label: "Жизненный путь",
          text: "Родом из Королевств Севера. Пережил Первую и Вторую Северные войны. Связан с Каэр Морхен и Школой Волка. Отношение к войне — «нейтралитет ведьмака».",
        },
        events: {
          label: "Ключевые события",
          text: "Участвовал в битве при Бренне, событиях в Вызиме, Лок Муинне. Настоящее время: поиски Цири и Йеннифэр, фон Третьей Северной войны.",
        },
      },
      notes: {
        title: "Заметки ведущего",
        description: "В режиме GM здесь будет редактируемое поле с приватными пометками.",
        toggle: "Переключить редактирование",
      },
      buttons: {
        switchToGM: "Переключить на «версию ведущего»",
        exportPDF: "Экспорт в PDF",
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
            <div className="section-title">{t.title} (просмотр)</div>
            <div className="section-note">{t.description}</div>
          </div>
          <div style={{ display: "flex", gap: "6px" }}>
            <button className="btn">{t.buttons.switchToGM}</button>
            <button className="btn btn-primary">{t.buttons.exportPDF}</button>
          </div>
        </div>

        <div className="sheet-layout">
          <aside className="sheet-sidebar">
            <div className="sheet-avatar"></div>
            <div className="sheet-name">{t.characterName}</div>
            <div className="sheet-meta" style={{ whiteSpace: "pre-line" }}>
              {t.characterMeta}
            </div>
            <div className="sheet-tags">
              <span className="pill accent">{t.tags.race}</span>
              <span className="pill">{t.tags.profession}</span>
              <span className="pill">{t.tags.age}</span>
            </div>

            <div className="sheet-stat-block">
              <div className="sheet-stat-title">{t.stats.attributes}</div>
              <div className="stat-grid">
                <div className="stat-pill">
                  <span>INT</span>
                  <span>6</span>
                </div>
                <div className="stat-pill">
                  <span>REF</span>
                  <span>14</span>
                </div>
                <div className="stat-pill">
                  <span>DEX</span>
                  <span>10</span>
                </div>
                <div className="stat-pill">
                  <span>BODY</span>
                  <span>8</span>
                </div>
                <div className="stat-pill">
                  <span>EMP</span>
                  <span>3</span>
                </div>
                <div className="stat-pill">
                  <span>WILL</span>
                  <span>8</span>
                </div>
                <div className="stat-pill">
                  <span>LUCK</span>
                  <span>3</span>
                </div>
                <div className="stat-pill">
                  <span>STAM</span>
                  <span>35</span>
                </div>
                <div className="stat-pill">
                  <span>RUN</span>
                  <span>9</span>
                </div>
              </div>
            </div>

            <div className="sheet-stat-block">
              <div className="sheet-stat-title">{t.stats.resources}</div>
              <div className="stat-grid">
                <div className="stat-pill">
                  <span>HP</span>
                  <span>55</span>
                </div>
                <div className="stat-pill">
                  <span>Энергия</span>
                  <span>7</span>
                </div>
                <div className="stat-pill">
                  <span>Удача (сейчас)</span>
                  <span>1 / 3</span>
                </div>
              </div>
            </div>
          </aside>

          <div className="sheet-main">
            <div className="section-title-row">
              <div>
                <div className="section-title">{t.skills.title}</div>
                <div className="section-note">{t.skills.description}</div>
              </div>
              <div className="pill-row">
                <span className="pill accent">{t.skills.mode}</span>
                <span className="pill">{t.skills.showFormulas}</span>
              </div>
            </div>

            <div className="skills-grid">
              <div className="skill-chip">
                <div className="skill-name">Владение мечом</div>
                <div className="skill-meta">11 / max 10</div>
              </div>
              <div className="skill-chip">
                <div className="skill-name">Уклонение / Изворотливость</div>
                <div className="skill-meta">10 / max 10</div>
              </div>
              <div className="skill-chip">
                <div className="skill-name">Внимание</div>
                <div className="skill-meta">9</div>
              </div>
              <div className="skill-chip">
                <div className="skill-name">Выживание в дикой природе</div>
                <div className="skill-meta">9</div>
              </div>
              <div className="skill-chip">
                <div className="skill-name">Алхимия</div>
                <div className="skill-meta">5</div>
              </div>
              <div className="skill-chip">
                <div className="skill-name">Скрытность</div>
                <div className="skill-meta">8</div>
              </div>
            </div>

            <div className="section-title-row" style={{ marginTop: "6px" }}>
              <div>
                <div className="section-title">{t.signs.title}</div>
                <div className="section-note">{t.signs.description}</div>
              </div>
              <div className="pill-row">
                {t.signs.signs.map((sign, idx) => (
                  <span key={idx} className="pill">
                    {sign}
                  </span>
                ))}
              </div>
            </div>

            <div className="timeline">
              <div className="timeline-item">
                <div className="timeline-label">{t.timeline.lifepath.label}</div>
                <div className="timeline-text">{t.timeline.lifepath.text}</div>
              </div>
              <div className="timeline-item">
                <div className="timeline-label">{t.timeline.events.label}</div>
                <div className="timeline-text">{t.timeline.events.text}</div>
              </div>
            </div>

            <div className="section-title-row" style={{ marginTop: "8px" }}>
              <div>
                <div className="section-title">{t.notes.title}</div>
                <div className="section-note">{t.notes.description}</div>
              </div>
              <button className="btn">{t.notes.toggle}</button>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}
