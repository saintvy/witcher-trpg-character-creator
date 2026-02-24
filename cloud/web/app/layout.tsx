"use client";

import { AuthProvider, AuthRouteGate } from "./auth-context";
import { LanguageProvider, useLanguage } from "./language-context";
import "./globals.css";
import "./ddlist.css";
import Link from "next/link";
import { usePathname } from "next/navigation";

function Sidebar() {
  const pathname = usePathname();
  const { lang, mounted } = useLanguage();
  const displayLang = mounted ? lang : "en";

  const content = {
    en: {
      subtitle: "Witcher character creator",
      tavernTitle: "The Pickles and Lard Tavern",
      navigation: "Navigation",
      home: "📜 Notice Board",
      characters: "Characters",
      settings: "Settings",
      rulesStore: "Rules store",
    },
    ru: {
      subtitle: "Witcher character creator",
      tavernTitle: 'Таверна "Сало и Огурчики"',
      navigation: "Навигация",
      home: "📜 Доска объявлений",
      characters: "Персонажи",
      settings: "Настройки",
      rulesStore: "Магазин правил",
    },
  } as const;

  const t = content[displayLang];

  const isActive = (path: string) => {
    if (!pathname) return false;
    if (path === "/") return pathname === "/";
    return pathname === path || pathname.startsWith(path + "/");
  };

  return (
    <aside className="sidebar">
      <div className="sidebar-header">
        <div className="sidebar-title-text">
          <div
            className="sidebar-title"
            style={{ textTransform: "none", letterSpacing: 0, lineHeight: 1.2 }}
            suppressHydrationWarning
          >
            {t.tavernTitle}
          </div>
          <div className="sidebar-subtitle" suppressHydrationWarning>
            {t.subtitle}
          </div>
        </div>
      </div>

      <div className="sidebar-nav">
        <div className="nav-group-label" suppressHydrationWarning>{t.navigation}</div>
        <Link href="/" className={`nav-item ${pathname === "/" ? "active" : ""}`}>
          <div className="nav-item-icon">🏠</div>
          <div className="nav-label" suppressHydrationWarning>{t.home}</div>
        </Link>
        <Link href="/characters" className={`nav-item ${isActive("/characters") ? "active" : ""}`}>
          <div className="nav-item-icon">🧬</div>
          <div className="nav-label" suppressHydrationWarning>{t.characters}</div>
          <div className="nav-pill">3</div>
        </Link>
        <Link href="/settings" className={`nav-item ${isActive("/settings") ? "active" : ""}`}>
          <div className="nav-item-icon">⚙️</div>
          <div className="nav-label" suppressHydrationWarning>{t.settings}</div>
        </Link>
      </div>

      <div className="sidebar-footer">
        <div className="sidebar-footer-row">
          <a
            href="https://talsorianstore.com/collections/the-witcher-trpg"
            target="_blank"
            rel="noopener noreferrer"
            className="footer-link"
          >
            <span suppressHydrationWarning>{t.rulesStore}</span>
          </a>
        </div>
      </div>
    </aside>
  );
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <AuthProvider>
          <LanguageProvider>
            <div className="layout">
              <Sidebar />
              <main className="main">
                <AuthRouteGate>{children}</AuthRouteGate>
              </main>
            </div>
          </LanguageProvider>
        </AuthProvider>
      </body>
    </html>
  );
}
