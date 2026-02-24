"use client";

import { AuthProvider, AuthRouteGate } from "./auth-context";
import { apiFetch } from "./api-fetch";
import { LanguageProvider, useLanguage } from "./language-context";
import "./globals.css";
import "./ddlist.css";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useCallback, useState } from "react";

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "/api";

function Sidebar() {
  const pathname = usePathname();
  const { lang, mounted } = useLanguage();
  const displayLang = mounted ? lang : "en";
  const [showExample, setShowExample] = useState(false);
  const [loadingExample, setLoadingExample] = useState(false);
  const [exampleJson, setExampleJson] = useState<string | null>(null);
  const [exampleError, setExampleError] = useState<string | null>(null);

  const content = {
    en: {
      subtitle: "Dark TTRPG • v0.1 UI ref",
      navigation: "Navigation",
      home: "Overview",
      builder: "Character Creation",
      characters: "Characters",
      sheet: "Character Sheet",
      settings: "Settings",
      apiContract: "API contract",
      exampleCharacter: "Example character",
      unavailable: "Unavailable",
      rulesStore: "Rules store",
      close: "Close",
      loading: "Loading...",
      error: "Error:",
      empty: "(empty)",
      responseTitle: "Response /generate-character",
    },
    ru: {
      subtitle: "Тёмная НРИ • v0.1 UI ref",
      navigation: "Навигация",
      home: "Обзор",
      builder: "Создание персонажа",
      characters: "Персонажи",
      sheet: "Лист персонажа",
      settings: "Настройки",
      apiContract: "API контракт",
      exampleCharacter: "Пример персонажа",
      unavailable: "Недоступно",
      rulesStore: "Магазин правил",
      close: "Закрыть",
      loading: "Загрузка...",
      error: "Ошибка:",
      empty: "(пусто)",
      responseTitle: "Ответ /generate-character",
    },
  };

  const t = content[displayLang];

  const isActive = (path: string) => {
    if (!pathname) return false;
    if (path === "/") return pathname === "/";
    return pathname === path || pathname.startsWith(path + "/");
  };

  const closeExample = useCallback(() => {
    setShowExample(false);
  }, []);

  const loadExample = useCallback(async () => {
    setLoadingExample(true);
    setExampleError(null);
    try {
      const response = await apiFetch(`${API_URL}/generate-character`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({}),
      });

      if (!response.ok) {
        throw new Error(`Request failed with status ${response.status}`);
      }

      const data = await response.json();
      setExampleJson(JSON.stringify(data, null, 2));
    } catch (error) {
      setExampleError(error instanceof Error ? error.message : String(error));
      setExampleJson(null);
    } finally {
      setLoadingExample(false);
    }
  }, []);

  const openExample = useCallback(() => {
    setShowExample(true);
    void loadExample();
  }, [loadExample]);

  return (
    <>
      <aside className="sidebar">
        <div className="sidebar-header">
          <div className="sidebar-logo">W</div>
          <div className="sidebar-title-text">
            <div className="sidebar-title">Witcher Character</div>
            <div className="sidebar-subtitle" suppressHydrationWarning>{t.subtitle}</div>
          </div>
        </div>

        <div className="sidebar-nav">
          <div className="nav-group-label" suppressHydrationWarning>{t.navigation}</div>
          <Link href="/" className={`nav-item ${pathname === "/" ? "active" : ""}`}>
            <div className="nav-item-icon">🏠</div>
            <div className="nav-label" suppressHydrationWarning>{t.home}</div>
          </Link>
          <Link href="/builder" className={`nav-item ${isActive("/builder") ? "active" : ""}`}>
            <div className="nav-item-icon">✨</div>
            <div className="nav-label" suppressHydrationWarning>{t.builder}</div>
          </Link>
          <Link href="/characters" className={`nav-item ${isActive("/characters") ? "active" : ""}`}>
            <div className="nav-item-icon">🧬</div>
            <div className="nav-label" suppressHydrationWarning>{t.characters}</div>
            <div className="nav-pill">3</div>
          </Link>
          <Link href="/sheet" className={`nav-item ${isActive("/sheet") ? "active" : ""}`}>
            <div className="nav-item-icon">📜</div>
            <div className="nav-label" suppressHydrationWarning>{t.sheet}</div>
          </Link>
          <Link href="/settings" className={`nav-item ${isActive("/settings") ? "active" : ""}`}>
            <div className="nav-item-icon">⚙️</div>
            <div className="nav-label" suppressHydrationWarning>{t.settings}</div>
          </Link>
        </div>

        <div className="sidebar-footer">
          <div className="sidebar-footer-row">
            <span suppressHydrationWarning>{t.apiContract}</span>
            <span className="badge-version">v1.0 draft</span>
          </div>
          <button
            type="button"
            className="sidebar-footer-row sidebar-footer-button"
            disabled
            style={{ cursor: "not-allowed", opacity: 0.6 }}
            title={t.unavailable}
          >
            <span suppressHydrationWarning>{t.exampleCharacter}</span>
            <span className="beta-tag">json</span>
          </button>
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

      {showExample && (
        <div className="modal-overlay" onClick={closeExample}>
          <div className="modal" onClick={(event) => event.stopPropagation()}>
            <div className="modal-header">
              <div className="modal-title" suppressHydrationWarning>{t.exampleCharacter}</div>
              <button
                type="button"
                className="modal-close"
                onClick={closeExample}
                aria-label={t.close}
              >
                ×
              </button>
            </div>
            <div className="modal-body">
              <div className="debug-section">
                <div className="debug-section-title" suppressHydrationWarning>{t.responseTitle}</div>
                <pre className="debug-code debug-json">
                  {loadingExample
                    ? t.loading
                    : exampleError
                    ? `${t.error} ${exampleError}`
                    : exampleJson ?? t.empty}
                </pre>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
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
