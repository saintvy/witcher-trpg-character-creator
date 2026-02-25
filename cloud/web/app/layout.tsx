"use client";

import { useEffect, useState } from "react";
import { AuthProvider, AuthRouteGate, useAuth } from "./auth-context";
import { LanguageProvider, useLanguage } from "./language-context";
import { apiFetch } from "./api-fetch";
import "./globals.css";
import "./ddlist.css";
import Link from "next/link";
import { usePathname } from "next/navigation";

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "/api";

function Sidebar() {
  const pathname = usePathname();
  const { lang, mounted } = useLanguage();
  const { mounted: authMounted, provider, isAuthenticated } = useAuth();
  const displayLang = mounted ? lang : "en";
  const [characterCount, setCharacterCount] = useState<number | null>(null);

  const content = {
    en: {
      subtitle: "Witcher character creator",
      tavernTitle: "The Pickles and Lard Tavern",
      navigation: "Navigation",
      home: "Notice Board",
      characters: "Characters",
      settings: "Settings",
      rulesStore: "Rules store",
    },
    ru: {
      subtitle: "Witcher character creator",
      tavernTitle: 'Таверна "Сало и Огурчики"',
      navigation: "Навигация",
      home: "Доска объявлений",
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

  useEffect(() => {
    let disposed = false;

    const loadCharacterCount = async () => {
      if (!authMounted) return;
      if (provider !== "none" && !isAuthenticated) {
        if (!disposed) setCharacterCount(null);
        return;
      }
      try {
        const response = await apiFetch(`${API_URL}/characters/count`);
        if (!response.ok) {
          return;
        }
        const payload = (await response.json()) as { count?: unknown };
        const nextCount =
          typeof payload.count === "number"
            ? payload.count
            : Number(payload.count ?? 0);
        if (!disposed && Number.isFinite(nextCount)) {
          setCharacterCount(Math.max(0, Math.trunc(nextCount)));
        }
      } catch {
        // ignore sidebar badge failures
      }
    };

    void loadCharacterCount();

    const onCharactersChanged = () => {
      void loadCharacterCount();
    };
    window.addEventListener("wcc:characters-changed", onCharactersChanged);

    return () => {
      disposed = true;
      window.removeEventListener("wcc:characters-changed", onCharactersChanged);
    };
  }, [authMounted, isAuthenticated, pathname, provider]);

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
          <div className="nav-item-icon">📜</div>
          <div className="nav-label" suppressHydrationWarning>{t.home}</div>
        </Link>
        <Link href="/characters" className={`nav-item ${isActive("/characters") ? "active" : ""}`}>
          <div className="nav-item-icon">🧬</div>
          <div className="nav-label" suppressHydrationWarning>{t.characters}</div>
          <div className="nav-pill">{characterCount ?? "..."}</div>
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
