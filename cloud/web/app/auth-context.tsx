"use client";

import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from "react";
import { usePathname } from "next/navigation";

type AuthProviderKind = "none" | "google" | "cognito";

type AuthUser = {
  sub: string;
  email?: string;
  name?: string;
  picture?: string;
};

type AuthSession = {
  provider: Exclude<AuthProviderKind, "none">;
  idToken: string;
  accessToken?: string;
  expiresAt?: number; // epoch seconds
  user: AuthUser;
};

type AuthContextValue = {
  mounted: boolean;
  provider: AuthProviderKind;
  session: AuthSession | null;
  isAuthenticated: boolean;
  isBusy: boolean;
  error: string | null;
  signIn: () => Promise<void>;
  signOut: () => Promise<void>;
  renderGoogleButton: (container: HTMLDivElement | null) => void;
  acceptGoogleCredential: (credential: string) => void;
};

const AUTH_PROVIDER = (process.env.NEXT_PUBLIC_AUTH_PROVIDER ?? "google") as AuthProviderKind;
const GOOGLE_CLIENT_ID = process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID ?? "";
const COGNITO_DOMAIN = (process.env.NEXT_PUBLIC_COGNITO_DOMAIN ?? "").replace(/\/$/, "");
const COGNITO_CLIENT_ID = process.env.NEXT_PUBLIC_COGNITO_CLIENT_ID ?? "";
const COGNITO_REDIRECT_URI = process.env.NEXT_PUBLIC_COGNITO_REDIRECT_URI ?? "";
const COGNITO_LOGOUT_REDIRECT_URI = process.env.NEXT_PUBLIC_COGNITO_LOGOUT_REDIRECT_URI ?? "";
const COGNITO_SCOPE = process.env.NEXT_PUBLIC_COGNITO_SCOPE ?? "openid email profile";

const SESSION_STORAGE_KEY = "wcc.auth.session";
const PKCE_VERIFIER_KEY = "wcc.auth.pkceVerifier";
const PKCE_STATE_KEY = "wcc.auth.pkceState";
const RETURN_TO_KEY = "wcc.auth.returnTo";

let currentIdToken: string | null = null;
let googleScriptPromise: Promise<void> | null = null;

export function getCurrentAuthIdToken(): string | null {
  return currentIdToken;
}

function setCurrentAuthIdToken(token: string | null): void {
  currentIdToken = token;
}

function parseJwtClaims(token: string): Record<string, unknown> {
  const parts = token.split(".");
  if (parts.length < 2) throw new Error("Invalid JWT");
  const base64 = parts[1]!.replace(/-/g, "+").replace(/_/g, "/");
  const padded = base64.padEnd(Math.ceil(base64.length / 4) * 4, "=");
  const binary = atob(padded);
  const bytes = Uint8Array.from(binary, (char) => char.charCodeAt(0));
  const json = new TextDecoder("utf-8").decode(bytes);
  return JSON.parse(json) as Record<string, unknown>;
}

function parseJwtExp(token: string): number | undefined {
  const claims = parseJwtClaims(token);
  return typeof claims.exp === "number" ? claims.exp : undefined;
}

function claimsToUser(claims: Record<string, unknown>): AuthUser {
  return {
    sub:
      (typeof claims.sub === "string" && claims.sub) ||
      (typeof claims.username === "string" && claims.username) ||
      "unknown",
    email: typeof claims.email === "string" ? claims.email : undefined,
    name:
      (typeof claims.name === "string" && claims.name) ||
      (typeof claims["cognito:username"] === "string" ? claims["cognito:username"] : undefined) ||
      undefined,
    picture: typeof claims.picture === "string" ? claims.picture : undefined,
  };
}

function isExpired(expiresAt?: number): boolean {
  if (!expiresAt) return false;
  const now = Math.floor(Date.now() / 1000);
  return expiresAt <= now + 30;
}

function readStoredSession(): AuthSession | null {
  try {
    const raw = window.localStorage.getItem(SESSION_STORAGE_KEY);
    if (!raw) return null;
    const session = JSON.parse(raw) as AuthSession;
    if (!session?.idToken || !session?.user) return null;
    if (isExpired(session.expiresAt)) return null;
    return session;
  } catch {
    return null;
  }
}

function writeStoredSession(session: AuthSession | null): void {
  if (!session) {
    window.localStorage.removeItem(SESSION_STORAGE_KEY);
    return;
  }
  window.localStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(session));
}

function loadGoogleScript(): Promise<void> {
  if (googleScriptPromise) return googleScriptPromise;

  googleScriptPromise = new Promise<void>((resolve, reject) => {
    const existing = document.querySelector<HTMLScriptElement>(
      'script[src="https://accounts.google.com/gsi/client"]',
    );
    if (existing && (window as any).google?.accounts?.id) {
      resolve();
      return;
    }

    const script = existing ?? document.createElement("script");
    script.src = "https://accounts.google.com/gsi/client";
    script.async = true;
    script.defer = true;
    script.onload = () => resolve();
    script.onerror = () => reject(new Error("Failed to load Google Identity script"));

    if (!existing) {
      document.head.appendChild(script);
    }
  });

  return googleScriptPromise;
}

function base64UrlEncode(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

async function sha256Base64Url(value: string): Promise<string> {
  const bytes = new TextEncoder().encode(value);
  const digest = await window.crypto.subtle.digest("SHA-256", bytes);
  return base64UrlEncode(new Uint8Array(digest));
}

function randomString(size = 64): string {
  const bytes = new Uint8Array(size);
  window.crypto.getRandomValues(bytes);
  return base64UrlEncode(bytes);
}

function getCognitoRedirectUri(): string {
  if (COGNITO_REDIRECT_URI) return COGNITO_REDIRECT_URI;
  return `${window.location.origin}/`;
}

function getCognitoLogoutRedirectUri(): string {
  if (COGNITO_LOGOUT_REDIRECT_URI) {
    try {
      const configured = new URL(COGNITO_LOGOUT_REDIRECT_URI);
      const cognitoHost = COGNITO_DOMAIN ? new URL(COGNITO_DOMAIN).host : "";
      // Misconfiguration guard: logout_uri must point back to the app, not Cognito itself.
      if (configured.host && cognitoHost && configured.host === cognitoHost) {
        return `${window.location.origin}/`;
      }
      return configured.toString();
    } catch {
      // Fall through to current origin fallback
    }
  }
  return `${window.location.origin}/`;
}

function buildDisplayName(user: AuthUser): string {
  return user.name || user.email || "Portal User";
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [mounted, setMounted] = useState(false);
  const [session, setSession] = useState<AuthSession | null>(null);
  const [isBusy, setIsBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [googleReady, setGoogleReady] = useState(false);
  const cognitoCallbackHandledRef = useRef(false);

  useEffect(() => {
    const initial = readStoredSession();
    setSession(initial);
    setCurrentAuthIdToken(initial?.idToken ?? null);
    setMounted(true);
  }, []);

  useEffect(() => {
    if (!mounted) return;
    if (session && isExpired(session.expiresAt)) {
      setSession(null);
      writeStoredSession(null);
      setCurrentAuthIdToken(null);
      return;
    }
    writeStoredSession(session);
    setCurrentAuthIdToken(session?.idToken ?? null);
  }, [mounted, session]);

  useEffect(() => {
    if (!mounted) return;
    if (AUTH_PROVIDER !== "google") return;
    if (!GOOGLE_CLIENT_ID) {
      setError("NEXT_PUBLIC_GOOGLE_CLIENT_ID is not configured");
      return;
    }

    void loadGoogleScript()
      .then(() => {
        (window as any).google?.accounts?.id?.initialize({
          client_id: GOOGLE_CLIENT_ID,
          callback: (response: { credential?: string }) => {
            if (response.credential) {
              acceptGoogleCredential(response.credential);
            }
          },
        });
        setGoogleReady(true);
      })
      .catch((err) => {
        setError(err instanceof Error ? err.message : String(err));
      });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [mounted]);

  useEffect(() => {
    if (!mounted) return;
    if (AUTH_PROVIDER !== "cognito") return;
    if (cognitoCallbackHandledRef.current) return;

    const url = new URL(window.location.href);
    const code = url.searchParams.get("code");
    const state = url.searchParams.get("state");
    if (!code || !state) return;

    cognitoCallbackHandledRef.current = true;
    setIsBusy(true);
    setError(null);

    void (async () => {
      try {
        const expectedState = window.sessionStorage.getItem(PKCE_STATE_KEY);
        const verifier = window.sessionStorage.getItem(PKCE_VERIFIER_KEY);
        if (!expectedState || !verifier || expectedState !== state) {
          throw new Error("Invalid Cognito OAuth state");
        }
        if (!COGNITO_DOMAIN || !COGNITO_CLIENT_ID) {
          throw new Error("Cognito auth is not configured in frontend env");
        }

        const body = new URLSearchParams({
          grant_type: "authorization_code",
          client_id: COGNITO_CLIENT_ID,
          code,
          code_verifier: verifier,
          redirect_uri: getCognitoRedirectUri(),
        });

        const response = await fetch(`${COGNITO_DOMAIN}/oauth2/token`, {
          method: "POST",
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
          body: body.toString(),
        });

        if (!response.ok) {
          throw new Error(`Cognito token exchange failed (${response.status})`);
        }

        const tokenData = (await response.json()) as {
          id_token?: string;
          access_token?: string;
          expires_in?: number;
        };

        if (!tokenData.id_token) {
          throw new Error("Cognito response does not include id_token");
        }

        const claims = parseJwtClaims(tokenData.id_token);
        const expiresAt =
          typeof tokenData.expires_in === "number"
            ? Math.floor(Date.now() / 1000) + tokenData.expires_in
            : parseJwtExp(tokenData.id_token);

        const nextSession: AuthSession = {
          provider: "cognito",
          idToken: tokenData.id_token,
          accessToken: tokenData.access_token,
          expiresAt,
          user: claimsToUser(claims),
        };

        setSession(nextSession);
        window.sessionStorage.removeItem(PKCE_STATE_KEY);
        window.sessionStorage.removeItem(PKCE_VERIFIER_KEY);

        const returnTo = window.sessionStorage.getItem(RETURN_TO_KEY) || "/";
        window.sessionStorage.removeItem(RETURN_TO_KEY);

        const cleanUrl = new URL(window.location.href);
        cleanUrl.searchParams.delete("code");
        cleanUrl.searchParams.delete("state");
        window.history.replaceState({}, "", cleanUrl.pathname + cleanUrl.search + cleanUrl.hash);

        if (returnTo && returnTo !== window.location.pathname) {
          window.location.assign(returnTo);
        }
      } catch (err) {
        setError(err instanceof Error ? err.message : String(err));
      } finally {
        setIsBusy(false);
      }
    })();
  }, [mounted]);

  const acceptGoogleCredential = useCallback((credential: string) => {
    try {
      const claims = parseJwtClaims(credential);
      const nextSession: AuthSession = {
        provider: "google",
        idToken: credential,
        expiresAt: parseJwtExp(credential),
        user: claimsToUser(claims),
      };
      setError(null);
      setSession(nextSession);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    }
  }, []);

  const signIn = useCallback(async () => {
    setError(null);

    if (AUTH_PROVIDER === "none") {
      return;
    }

    if (AUTH_PROVIDER === "google") {
      if (!googleReady) {
        throw new Error("Google auth is not ready yet");
      }
      (window as any).google?.accounts?.id?.prompt();
      return;
    }

    if (!COGNITO_DOMAIN || !COGNITO_CLIENT_ID) {
      throw new Error("Cognito auth env vars are not configured");
    }

    const verifier = randomString(64);
    const state = randomString(32);
    const challenge = await sha256Base64Url(verifier);

    window.sessionStorage.setItem(PKCE_VERIFIER_KEY, verifier);
    window.sessionStorage.setItem(PKCE_STATE_KEY, state);
    window.sessionStorage.setItem(
      RETURN_TO_KEY,
      window.location.pathname + window.location.search + window.location.hash,
    );

    const authorizeUrl = new URL(`${COGNITO_DOMAIN}/oauth2/authorize`);
    authorizeUrl.searchParams.set("response_type", "code");
    authorizeUrl.searchParams.set("client_id", COGNITO_CLIENT_ID);
    authorizeUrl.searchParams.set("redirect_uri", getCognitoRedirectUri());
    authorizeUrl.searchParams.set("scope", COGNITO_SCOPE);
    authorizeUrl.searchParams.set("state", state);
    authorizeUrl.searchParams.set("code_challenge_method", "S256");
    authorizeUrl.searchParams.set("code_challenge", challenge);

    window.location.assign(authorizeUrl.toString());
  }, [googleReady]);

  const signOut = useCallback(async () => {
    const provider = session?.provider;
    setSession(null);
    setError(null);

    if (provider === "google") {
      try {
        (window as any).google?.accounts?.id?.disableAutoSelect?.();
      } catch {
        // ignore
      }
      return;
    }

    if (provider === "cognito" && COGNITO_DOMAIN && COGNITO_CLIENT_ID) {
      const logoutUrl = new URL(`${COGNITO_DOMAIN}/logout`);
      logoutUrl.searchParams.set("client_id", COGNITO_CLIENT_ID);
      logoutUrl.searchParams.set("logout_uri", getCognitoLogoutRedirectUri());
      window.location.assign(logoutUrl.toString());
    }
  }, [session?.provider]);

  const renderGoogleButton = useCallback(
    (container: HTMLDivElement | null) => {
      if (!container) return;
      if (AUTH_PROVIDER !== "google") return;
      if (!googleReady || session) {
        container.innerHTML = "";
        return;
      }

      const google = (window as any).google;
      if (!google?.accounts?.id?.renderButton) return;

      container.innerHTML = "";
      google.accounts.id.renderButton(container, {
        theme: "outline",
        size: "small",
        text: "signin_with",
        shape: "pill",
      });
    },
    [googleReady, session],
  );

  const value = useMemo<AuthContextValue>(
    () => ({
      mounted,
      provider: AUTH_PROVIDER,
      session,
      isAuthenticated: Boolean(session),
      isBusy,
      error,
      signIn,
      signOut,
      renderGoogleButton,
      acceptGoogleCredential,
    }),
    [acceptGoogleCredential, error, isBusy, mounted, renderGoogleButton, session, signIn, signOut],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within AuthProvider");
  }
  return context;
}

function AuthRequiredPanel() {
  const { provider, signIn, isBusy, error } = useAuth();

  return (
    <section className="auth-guard-card">
      <h2>Authorization Required</h2>
      <p>
        This page is available only to authenticated users. Sign in to continue.
      </p>
      <div className="auth-guard-actions">
        <button
          type="button"
          className="auth-guard-btn"
          disabled={isBusy || provider === "none"}
          onClick={() => void signIn()}
        >
          {provider === "cognito" ? "Sign in with Cognito" : "Sign in with Google"}
        </button>
        <a href="/" className="auth-guard-link">
          Go to Home
        </a>
      </div>
      {error ? <div className="auth-guard-error">{error}</div> : null}
    </section>
  );
}

export function AuthRouteGate({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const { mounted, provider, isAuthenticated } = useAuth();

  const isProtected = pathname !== "/";
  if (!isProtected) return <>{children}</>;

  if (!mounted) {
    return <section className="auth-guard-card">Loading authorization...</section>;
  }

  if (provider !== "none" && isAuthenticated) {
    return <>{children}</>;
  }

  if (provider === "none") {
    return (
      <section className="auth-guard-card">
        <h2>Auth Provider Is Not Configured</h2>
        <p>
          Protected routes are enabled, but no auth provider is configured. Set
          `NEXT_PUBLIC_AUTH_PROVIDER` and provider-specific env vars.
        </p>
        <a href="/" className="auth-guard-link">
          Go to Home
        </a>
      </section>
    );
  }

  return <AuthRequiredPanel />;
}

export function getDisplayName(user: AuthUser | undefined): string {
  if (!user) return "Portal User";
  return buildDisplayName(user);
}
