const FALLBACK_SITE_URL = "https://picklesandlard.com";

function normalizeSiteUrl(value: string): string {
  const trimmed = value.trim();
  if (!trimmed) return FALLBACK_SITE_URL;
  return trimmed.endsWith("/") ? trimmed : `${trimmed}/`;
}

export function getSiteUrl(): string {
  return normalizeSiteUrl(process.env.NEXT_PUBLIC_SITE_URL ?? FALLBACK_SITE_URL);
}

export function getAbsoluteUrl(path = "/"): string {
  return new URL(path, getSiteUrl()).toString();
}

