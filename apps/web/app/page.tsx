"use client";

import { useLanguage } from "./language-context";
import { Topbar } from "./components/Topbar";

export default function HomePage() {
  const { lang } = useLanguage();
  const displayLang = lang;

  const content = {
    en: {
      title: "Notice Board",
      subtitle: "Portal news",
      greetingTitle: "Welcome, traveler!",
      welcome:
        "Kick the mud off your boots, grab a stool, and park yourself by the fire before the bard starts charging for every verse.\nTonight the ale is bold, the rumors are louder than the lute, and the dice are itching to ruin somebody's plans magnificently.\nIf your witcher survives the contract, we'll cheer; if he accidentally adopts a cursed goat, we'll cheer even louder.\nSo grin, roll the bones, keep silver in your sleeve, and try not to arm-wrestle anyone with suspiciously yellow eyes.",
      whatsNew: "What's New",
      news: [
        {
          title: "March 6, 2026: Two professions from DLC",
          text: "Added the professions Noble (DLC \"Lords and Lands\") and Peasant (DLC \"Peasant\").",
        },
        {
          title: "March 5, 2026: DLC races",
          text: "Added the races Gnomes, Vrans, and Werebbubbs (DLC \"A Book of Tales\"), and Halflings (DLC \"Lords and Lands\").",
        },
        {
          title: "March 4, 2026: Avatars",
          text: "Added the ability to add and change a character's avatar.",
        },
        {
          title: "March 3, 2026: PDF charsheet",
          text: "Added the ability to generate and download a PDF character sheet.",
        },
        {
          title: "February 24, 2026: First portal launch",
          text: "The site first went online with basic functionality: navigation, the characters page, core settings, and a working path to the character builder.",
        },
      ],
    },
    ru: {
      title: "Доска объявлений",
      subtitle: "Новости портала",
      greetingTitle: "Приветствую тебя, путник!",
      welcome:
        "Скидывай дорожную пыль с сапог, подсаживайся к огню и хватай кружку, пока бард не начал брать плату за каждый куплет.\nСегодня эль крепкий, слухи громче лютни, а кубы уже чешутся кому-нибудь эффектно испортить планы.\nЕсли твой ведьмак вернется с контракта героем, мы поднимем тост; если притащит домой проклятого козла, поднимем два.\nТак что улыбайся, бросай кости, держи серебро в рукаве и не меряйся силой с тем, у кого слишком желтые глаза.",
      whatsNew: "Что нового",
      news: [
        {
          title: "6 марта 2026: Две профессии из DLC",
          text: "Добавлены профессии Аристократ (DLC \"Правители и земли\") и Крестьянин (DLC \"Крестьянин\").",
        },
        {
          title: "5 марта 2026: Расы из DLC",
          text: "Добавлены расы Гномы, Враны, Баболаки (DLC \"Книга сказок\") и Низушки (DLC \"Правители и земли\").",
        },
        {
          title: "4 марта 2026: Аватары",
          text: "Добавлена возможность добавлять и менять аватар персонажа.",
        },
        {
          title: "3 марта 2026: PDF чарник",
          text: "Добавлена возможность генерировать и скачивать PDF чарник персонажа.",
        },
        {
          title: "24 февраля 2026: Первый запуск портала",
          text: "Сайт впервые вышел онлайн с базовым функционалом: навигация, страница персонажей, базовые настройки и рабочий переход в конструктор персонажа.",
        },
      ],
    },
  } as const;

  const t = content[displayLang];
  const accentColor = "#c67a2b";

  return (
    <>
      <Topbar title={t.title} subtitle={t.subtitle} />
      <section className="content" suppressHydrationWarning>
        <h1
          style={{
            color: accentColor,
            fontSize: 28,
            fontWeight: 800,
            letterSpacing: "0.04em",
            textTransform: "uppercase",
            margin: "2px 0 10px",
            textShadow: "0 2px 12px rgba(198,122,43,0.22)",
          }}
        >
          {t.greetingTitle}
        </h1>
        {/* Visually hidden text for SEO indexing */}
        <span style={{ position: "absolute", width: 1, height: 1, padding: 0, margin: -1, overflow: "hidden", clip: "rect(0, 0, 0, 0)", whiteSpace: "nowrap", borderWidth: 0 }}>
          {lang === "en" ? "Witcher Character Creator, Witcher TTRPG, Character Generator" : "Генератор персонажей Ведьмак НРИ"}
        </span>

        <div className="card">
          <p
            style={{
              margin: 0,
              lineHeight: 1.7,
              fontSize: 15,
              color: "var(--text-main)",
              whiteSpace: "pre-line",
            }}
          >
            {t.welcome}
          </p>
        </div>

        <h2
          style={{
            color: accentColor,
            fontSize: 24,
            fontWeight: 800,
            letterSpacing: "0.06em",
            textTransform: "uppercase",
            margin: "16px 0 8px",
          }}
        >
          {t.whatsNew}
        </h2>

        <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
          {t.news.map((item, index) => (
            <div className="card" key={index}>
              <div className="timeline-list" style={{ marginTop: 0 }}>
                <div className="timeline-item" style={{ paddingBottom: 0 }}>
                  <div className="timeline-label" style={{ color: accentColor }}>{item.title}</div>
                  {item.text && <div className="timeline-text">{item.text}</div>}
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>
    </>
  );
}
