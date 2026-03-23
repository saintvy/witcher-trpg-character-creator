"use client";

import { getDisplayName, useAuth } from "../auth-context";
import { useLanguage } from "../language-context";
import { useState, useRef, useEffect } from "react";
import Image from "next/image";

export function Topbar({ title, subtitle }: { title: string; subtitle?: string }) {
  const { lang, setLang } = useLanguage();
  const auth = useAuth();
  const [isOpen, setIsOpen] = useState(false);
  const [avatarFailed, setAvatarFailed] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);
  const googleButtonRef = useRef<HTMLDivElement>(null);

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

  useEffect(() => {
    auth.renderGoogleButton(googleButtonRef.current);
  }, [auth, auth.isAuthenticated]);

  useEffect(() => {
    setAvatarFailed(false);
  }, [auth.session?.user.picture]);

  const userName = getDisplayName(auth.session?.user);
  const userRole =
    auth.session?.provider === "cognito"
      ? "cognito user"
      : auth.session?.provider === "google"
      ? "google account"
      : "guest";
  const userPicture = auth.session?.user.picture;
  const userInitial = userName.trim().charAt(0).toUpperCase() || "U";

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
          {auth.isAuthenticated ? (
            <>
              <div className="user-avatar" aria-hidden="true">
                {userPicture && !avatarFailed ? (
                  <img
                    src={userPicture}
                    alt=""
                    className="user-avatar-img"
                    referrerPolicy="no-referrer"
                    onError={() => setAvatarFailed(true)}
                  />
                ) : (
                  userInitial
                )}
              </div>
              <div className="user-info">
                <div className="user-name" title={auth.session?.user.email}>{userName}</div>
                <div className="user-role">{userRole}</div>
              </div>
              <button
                type="button"
                className="user-pill-button"
                onClick={() => void auth.signOut()}
                title="Sign out"
              >
                ↩
              </button>
            </>
          ) : auth.provider === "google" ? (
            <div className="user-login-slot">
              <div ref={googleButtonRef} />
              <button
                type="button"
                className="user-pill-button"
                onClick={() => void auth.signIn()}
                title="Open Google sign-in"
              >
                Sign in
              </button>
            </div>
          ) : (
            <div className="user-login-slot">
              <div className="user-info">
                <div className="user-name">
                  {auth.provider === "cognito" ? "Cloud Sign-In" : "Guest"}
                </div>
                <div className="user-role">{auth.error ? "auth error" : "authorization required"}</div>
              </div>
              {auth.provider !== "none" ? (
                <button
                  type="button"
                  className="user-pill-button"
                  onClick={() => void auth.signIn()}
                  disabled={auth.isBusy}
                >
                  Login
                </button>
              ) : null}
            </div>
          )}
        </div>
      </div>
    </header>
  );
}


