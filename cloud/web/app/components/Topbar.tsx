"use client";

import { useLanguage } from "../language-context";
import { useState, useRef, useEffect } from "react";
import Image from "next/image";

export function Topbar({ title, subtitle }: { title: string; subtitle?: string }) {
  const { lang, setLang } = useLanguage();
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  const languages = [
    { code: "en", flag: "/uk.png", name: "English" },
    { code: "ru", flag: "/russia.png", name: "Русский" },
  ];

  const currentLang = languages.find((l) => l.code === lang) || languages[0];

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    }

    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, []);

  return (
    <header className="topbar">
      <div className="topbar-left">
        <div className="topbar-title">{title}</div>
        {subtitle && <div className="topbar-subtitle">{subtitle}</div>}
      </div>
      <div className="topbar-right">
        <div className="lang-select-wrapper" ref={dropdownRef}>
          <button
            className="lang-select-btn"
            onClick={() => setIsOpen(!isOpen)}
            type="button"
          >
            <Image
              src={currentLang.flag}
              alt={currentLang.name}
              width={24}
              height={24}
              className="lang-flag"
            />
          </button>
          {isOpen && (
            <div className="lang-dropdown">
              {languages.map((language) => (
                <button
                  key={language.code}
                  className={`lang-option ${lang === language.code ? "active" : ""}`}
                  onClick={() => {
                    setLang(language.code as "en" | "ru");
                    setIsOpen(false);
                  }}
                  type="button"
                >
                  <Image
                    src={language.flag}
                    alt={language.name}
                    width={24}
                    height={24}
                    className="lang-flag"
                  />
                </button>
              ))}
            </div>
          )}
        </div>
        <div className="user-pill">
          <div className="user-avatar">V</div>
          <div className="user-info">
            <div className="user-name">Хозяин портала</div>
            <div className="user-role">архитектор правил</div>
          </div>
        </div>
      </div>
    </header>
  );
}

