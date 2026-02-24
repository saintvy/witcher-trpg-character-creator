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
      greetingTitle: "Welcome, traveler!",
      welcome:
        "Kick the mud off your boots, grab a stool, and park yourself by the fire before the bard starts charging for every verse.\nTonight the ale is bold, the rumors are louder than the lute, and the dice are itching to ruin somebody's plans magnificently.\nIf your witcher survives the contract, we'll cheer; if he accidentally adopts a cursed goat, we'll cheer even louder.\nSo grin, roll the bones, keep silver in your sleeve, and try not to arm-wrestle anyone with suspiciously yellow eyes.",
      whatsNew: "What's New",
      launchTitle: "First portal launch: February 24, 2026",
      launchText:
        "The site first went online with basic functionality: navigation, the characters page, core settings, and a working path to the character builder.",
    },
    ru: {
      title: "Доска объявлений",
      subtitle: "Новости портала",
      greetingTitle: "Приветствую тебя, путник!",
      welcome:
        "Скидывай дорожную пыль с сапог, подсаживайся к огню и хватай кружку, пока бард не начал брать плату за каждый куплет.\nСегодня эль крепкий, слухи громче лютни, а кубы уже чешутся кому-нибудь эффектно испортить планы.\nЕсли твой ведьмак вернется с контракта героем, мы поднимем тост; если притащит домой проклятого козла, поднимем два.\nТак что улыбайся, бросай кости, держи серебро в рукаве и не меряйся силой с тем, у кого слишком желтые глаза.",
      whatsNew: "Что нового",
      launchTitle: "Первый запуск портала: 24 февраля 2026",
      launchText:
        "Сайт впервые вышел онлайн с базовым функционалом: навигация, страница персонажей, базовые настройки и рабочий переход в конструктор персонажа.",
    },
  } as const;

  const t = content[displayLang];
  const accentColor = "#c67a2b";

  return (
    <>
      <Topbar title={t.title} subtitle={t.subtitle} />
      <section className="content" suppressHydrationWarning>
        <div
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
        </div>

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

        <div
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
        </div>

        <div className="card">
          <div className="timeline-list" style={{ marginTop: 0 }}>
            <div className="timeline-item">
              <div className="timeline-label" style={{ color: accentColor }}>{t.launchTitle}</div>
              <div className="timeline-text">{t.launchText}</div>
            </div>
          </div>
        </div>
      </section>
    </>
  );
}
