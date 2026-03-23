"use client";

import { getSiteUrl } from "./seo";
import { useLanguage } from "./language-context";
import { Topbar } from "./components/Topbar";

export default function HomePage() {
  const { lang } = useLanguage();
  const displayLang = lang;
  const siteUrl = getSiteUrl().replace(/\/$/, "");

  const content = {
    en: {
      title: "Notice Board",
      subtitle: "Portal news",
      greetingTitle: "Welcome, traveler!",
      welcome:
        "Kick the mud off your boots, grab a stool, and park yourself by the fire before the bard starts charging for every verse.\nTonight the ale is bold, the rumors are louder than the lute, and the dice are itching to ruin somebody's plans magnificently.\nIf your witcher survives the contract, we'll cheer; if he accidentally adopts a cursed goat, we'll cheer even louder.\nSo grin, roll the bones, keep silver in your sleeve, and try not to arm-wrestle anyone with suspiciously yellow eyes.",
      highlightsTitle: "What You Can Do Here",
      highlightsLead:
        "Witcher Character Creator is a free unofficial character generator for the Witcher Tabletop Roleplaying Game. Here you can:",
      highlights: [
        "Generate Witcher TTRPG characters with guided rules-based choices.",
        "Save your builds and return to them later.",
        "Download printable PDF character sheets.",
      ],
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
      highlightsTitle: "Что Здесь Можно Делать",
      highlightsLead:
        "Witcher Character Creator это бесплатный неофициальный генератор персонажей для настольной ролевой игры по Ведьмаку. Здесь можно:",
      highlights: [
        "Генерировать персонажей Witcher TTRPG через пошаговый мастер.",
        "Сохранять сборки и возвращаться к ним позже.",
        "Скачивать готовые PDF-листы персонажей.",
      ],
      whatsNew: "Что нового",
      news: [
        {
          title: "6 марта 2026: Две профессии из DLC",
          text: "Добавлены профессии Дворянин (DLC \"Правители и земли\") и Крестьянин (DLC \"Крестьянин\").",
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
  const jsonLd = [
    {
      "@context": "https://schema.org",
      "@type": "WebSite",
      name: "Witcher Character Creator",
      url: siteUrl,
      inLanguage: ["en", "ru"],
      description:
        "Free unofficial character creator for the Witcher Tabletop Roleplaying Game.",
    },
    {
      "@context": "https://schema.org",
      "@type": "SoftwareApplication",
      name: "Witcher Character Creator",
      applicationCategory: "GameApplication",
      operatingSystem: "Web",
      isAccessibleForFree: true,
      url: siteUrl,
      offers: {
        "@type": "Offer",
        price: "0",
        priceCurrency: "USD",
      },
      description:
        "Create, save, and export characters for the Witcher Tabletop Roleplaying Game.",
    },
  ];

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
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

        <div className="card">
          <h2
            style={{
              color: accentColor,
              fontSize: 22,
              fontWeight: 800,
              letterSpacing: "0.05em",
              textTransform: "uppercase",
              margin: "0 0 12px",
            }}
          >
            {t.highlightsTitle}
          </h2>
          <p
            style={{
              margin: "0 0 12px",
              lineHeight: 1.7,
              fontSize: 15,
              color: "var(--text-main)",
            }}
          >
            {t.highlightsLead}
          </p>
          <ul style={{ margin: 0, paddingLeft: "20px", lineHeight: 1.8 }}>
            {t.highlights.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
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
