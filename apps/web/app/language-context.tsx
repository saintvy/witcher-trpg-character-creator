"use client";

import { createContext, useContext, useEffect, useMemo, useState } from "react";

type Language = "en" | "ru";

type LanguageContextValue = {
  lang: Language;
  setLang: (lang: Language) => void;
  mounted: boolean;
};

const DEFAULT_LANG: Language = "en";
const STORAGE_KEY = "wcc.language";

const LanguageContext = createContext<LanguageContextValue | undefined>(undefined);

export function LanguageProvider({ children }: { children: React.ReactNode }) {
  const [mounted, setMounted] = useState(false);
  const [lang, setLang] = useState<Language>(DEFAULT_LANG);

  useEffect(() => {
    // Only read from localStorage on client side after mount
    const stored = window.localStorage.getItem(STORAGE_KEY);
    const initialLang = (stored === "en" || stored === "ru" ? stored : DEFAULT_LANG) as Language;
    setLang(initialLang);
    setMounted(true);
  }, []);

  useEffect(() => {
    if (!mounted) return;
    window.localStorage.setItem(STORAGE_KEY, lang);
    document.documentElement.lang = lang;
  }, [lang, mounted]);

  const value = useMemo(() => ({ lang, setLang, mounted }), [lang, mounted]);

  return <LanguageContext.Provider value={value}>{children}</LanguageContext.Provider>;
}

export function useLanguage() {
  const context = useContext(LanguageContext);
  if (!context) {
    throw new Error("useLanguage must be used within LanguageProvider");
  }
  return context;
}
