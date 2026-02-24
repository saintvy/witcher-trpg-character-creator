"use client";

import { useLanguage } from "./language-context";
import { Topbar } from "./components/Topbar";

export default function HomePage() {
  const { lang, mounted } = useLanguage();
  const displayLang = mounted ? lang : "en";

  const content = {
    en: {
      title: "Notice Board",
      subtitle: "Portal news",
      welcome:
        "Welcome to the tavern, traveler: pull up a chair by the fire and let the dice decide your fate.\nHere we trade stories from the Continent, lucky omens, and glorious disasters with a smile.\nA witcher, bard, or merchant walks in with a tale, and we pin it to the board before the ale cools.\nRoll bold, keep silver close, and avoid wagers with anyone who grins like a leshen.",
      whatsNew: "What's New",
      launchTitle: "February 24, 2026: first public launch",
      launchText: "The site went online for the first time with basic functionality: navigation, character list mockup, settings basics, and a working path to the character builder.",
    },
    ru: {
      title: "Доска объявлений",
      subtitle: "Новости портала",
      welcome:
        "Добро пожаловать в корчму, путник: подсаживайся к огню и дай кубам решить твою судьбу.\nЗдесь мы собираем слухи с Континента, удачные знамения и славные провалы с улыбкой.\nЕсли ведьмак, бард или купец приносит историю, мы вешаем ее на доску раньше, чем остынет эль.\nБросай дайсы смелее, держи серебро под рукой и не спорь на ставки с тем, кто ухмыляется как леший.",
      whatsNew: "Что нового",
      launchTitle: "24 февраля 2026: первый выход сайта онлайн",
      launchText: "Сайт впервые появился онлайн с базовым функционалом: навигация, страница персонажей, базовые настройки и рабочий переход в конструктор персонажа.",
    },
  } as const;

  const t = content[displayLang];

  return (
    <>
      <Topbar title={t.title} subtitle={t.subtitle} />
      <section className="content" suppressHydrationWarning>
        <div className="card">
          <div className="card-header">
            <div>
              <div className="card-title">{t.title}</div>
              <div className="card-subtitle">{t.subtitle}</div>
            </div>
          </div>
          <p
            style={{
              margin: 0,
              lineHeight: 1.65,
              fontSize: 14,
              color: "var(--text-main)",
              whiteSpace: "pre-line",
            }}
          >
            {t.welcome}
          </p>
        </div>

        <div className="card" style={{ marginTop: 12 }}>
          <div className="card-header">
            <div>
              <div className="card-title">{t.whatsNew}</div>
            </div>
          </div>
          <div className="timeline-list" style={{ marginTop: 0 }}>
            <div className="timeline-item">
              <div className="timeline-label">{displayLang === "ru" ? "Новость" : "News"}</div>
              <div className="timeline-text">
                <strong>{t.launchTitle}</strong>
                <div style={{ marginTop: 4 }}>{t.launchText}</div>
              </div>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}
