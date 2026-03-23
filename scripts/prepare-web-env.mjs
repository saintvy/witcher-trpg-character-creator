import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const rootDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const webDir = path.join(rootDir, "apps", "web");
const outputPath = path.join(webDir, ".env.production.local");

function readEnvFile(filePath) {
  if (!fs.existsSync(filePath)) return {};

  const raw = fs.readFileSync(filePath, "utf8");
  const result = {};
  for (const line of raw.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const separator = trimmed.indexOf("=");
    if (separator <= 0) continue;

    const key = trimmed.slice(0, separator).trim();
    let value = trimmed.slice(separator + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    result[key] = value;
  }

  return result;
}

function loadLocalEnv() {
  const candidates = [];
  if (path.basename(rootDir).startsWith(".worktree-")) {
    const parentRoot = path.resolve(rootDir, "..");
    candidates.push(
      path.join(parentRoot, "apps", "web", ".env.local"),
      path.join(parentRoot, "apps", "web", ".env.production.local"),
      path.join(parentRoot, "infra", ".env.local"),
    );
  }
  candidates.push(
    path.join(rootDir, "apps", "web", ".env.local"),
    path.join(rootDir, "infra", ".env.local"),
  );

  return candidates.reduce((acc, candidate) => {
    return fs.existsSync(candidate) ? { ...acc, ...readEnvFile(candidate) } : acc;
  }, {});
}

const localEnv = loadLocalEnv();

function envValue(name) {
  return normalized(process.env[name]) || normalized(localEnv[name]);
}

function pickFirstCsv(value) {
  return String(value ?? "")
    .split(",")
    .map((part) => part.trim())
    .filter(Boolean)[0] ?? "";
}

function normalized(value) {
  return String(value ?? "").trim();
}

const googleClientId =
  envValue("NEXT_PUBLIC_GOOGLE_CLIENT_ID") || pickFirstCsv(envValue("WCC_GOOGLE_CLIENT_IDS"));

const cognitoDomain =
  envValue("NEXT_PUBLIC_COGNITO_DOMAIN") || envValue("WCC_COGNITO_DOMAIN");
const cognitoClientId =
  envValue("NEXT_PUBLIC_COGNITO_CLIENT_ID") ||
  envValue("WCC_COGNITO_CLIENT_ID") ||
  envValue("WCC_COGNITO_JWT_AUDIENCE");
const cognitoRedirectUri =
  envValue("NEXT_PUBLIC_COGNITO_REDIRECT_URI") || envValue("WCC_COGNITO_REDIRECT_URI");
const cognitoLogoutRedirectUri =
  envValue("NEXT_PUBLIC_COGNITO_LOGOUT_REDIRECT_URI") || envValue("WCC_COGNITO_LOGOUT_REDIRECT_URI");
const cognitoScope =
  envValue("NEXT_PUBLIC_COGNITO_SCOPE") || envValue("WCC_COGNITO_SCOPE") || "openid email profile";
const siteUrl = envValue("NEXT_PUBLIC_SITE_URL") || envValue("WCC_SITE_URL");
const googleSiteVerification =
  envValue("NEXT_PUBLIC_GOOGLE_SITE_VERIFICATION") || envValue("GOOGLE_SITE_VERIFICATION");
const explicitFrontendAuthProvider =
  envValue("WCC_FRONTEND_AUTH_PROVIDER") || envValue("NEXT_PUBLIC_AUTH_PROVIDER");

const hasCognitoFrontendConfig =
  Boolean(cognitoDomain) &&
  Boolean(cognitoClientId) &&
  Boolean(cognitoRedirectUri) &&
  Boolean(cognitoLogoutRedirectUri);

const inferredProvider = hasCognitoFrontendConfig
  ? "cognito"
  : googleClientId
    ? "google"
  : cognitoDomain && cognitoClientId
    ? "cognito"
    : "none";

const authProvider = explicitFrontendAuthProvider.toLowerCase() || inferredProvider;

if (authProvider === "google" && !googleClientId) {
  throw new Error(
    "Frontend auth build config is incomplete: NEXT_PUBLIC_GOOGLE_CLIENT_ID is missing. " +
      "Set NEXT_PUBLIC_GOOGLE_CLIENT_ID or WCC_GOOGLE_CLIENT_IDS before building apps/web.",
  );
}

if (authProvider === "cognito") {
  const missing = [
    !cognitoDomain && "NEXT_PUBLIC_COGNITO_DOMAIN",
    !cognitoClientId && "NEXT_PUBLIC_COGNITO_CLIENT_ID",
    !cognitoRedirectUri && "NEXT_PUBLIC_COGNITO_REDIRECT_URI",
    !cognitoLogoutRedirectUri && "NEXT_PUBLIC_COGNITO_LOGOUT_REDIRECT_URI",
  ].filter(Boolean);

  if (missing.length > 0) {
    throw new Error(
      `Frontend auth build config is incomplete for Cognito: missing ${missing.join(", ")}.`,
    );
  }
}

const lines = [
  `NEXT_PUBLIC_API_URL=${normalized(process.env.NEXT_PUBLIC_API_URL) || "/api"}`,
  `NEXT_PUBLIC_AUTH_PROVIDER=${authProvider}`,
  `NEXT_PUBLIC_GOOGLE_CLIENT_ID=${googleClientId}`,
  `NEXT_PUBLIC_COGNITO_DOMAIN=${cognitoDomain}`,
  `NEXT_PUBLIC_COGNITO_CLIENT_ID=${cognitoClientId}`,
  `NEXT_PUBLIC_COGNITO_REDIRECT_URI=${cognitoRedirectUri}`,
  `NEXT_PUBLIC_COGNITO_LOGOUT_REDIRECT_URI=${cognitoLogoutRedirectUri}`,
  `NEXT_PUBLIC_COGNITO_SCOPE=${cognitoScope}`,
  `NEXT_PUBLIC_SITE_URL=${siteUrl}`,
  `NEXT_PUBLIC_GOOGLE_SITE_VERIFICATION=${googleSiteVerification}`,
  "",
];

fs.writeFileSync(outputPath, lines.join("\n"), "utf8");

console.log(
  `[prepare-web-env] wrote ${path.relative(rootDir, outputPath)} with auth provider "${authProvider}"`,
);
