# Google + Cognito Authorization Setup (WCC)

## Что реализовано в проекте

- Frontend (`cloud/web`)
  - Google sign-in (Google Identity Services, ID token)
  - Cognito Hosted UI sign-in (Authorization Code + PKCE)
  - Guard: все страницы, кроме `/`, требуют авторизацию
  - Все клиентские вызовы API автоматически отправляют `Authorization: Bearer <id_token>`

- Backend (`cloud/api`)
  - Middleware авторизации для API
  - Режимы:
    - `none`
    - `google-jwt` (локальная проверка Google ID token через Google JWKS)
    - `trust-apigw` (для облака, когда JWT проверяет API Gateway authorizer)

- Infra (`cloud/infra`)
  - Поддержка JWT authorizer для API Gateway (Cognito) через env-переменные на этапе `cdk synth/deploy`

## Важное про ключи и безопасность (git)

### Что можно хранить в frontend env (это не секрет)

- `NEXT_PUBLIC_GOOGLE_CLIENT_ID`
- `NEXT_PUBLIC_COGNITO_DOMAIN`
- `NEXT_PUBLIC_COGNITO_CLIENT_ID`
- `NEXT_PUBLIC_COGNITO_REDIRECT_URI`
- `NEXT_PUBLIC_COGNITO_LOGOUT_REDIRECT_URI`

Это публичные идентификаторы/URL, они попадают в браузер по определению.

### Что нельзя коммитить в git

- Google OAuth `client secret`
- Любые приватные ключи, access tokens, refresh tokens
- Локальные `.env.*.local`

В проекте уже добавлено в `.gitignore`:

- `.env.local`
- `.env.*.local`

Используйте:

- `cloud/web/.env.local` или `cloud/web/.env.development.local`
- `cloud/api/.env.local` или `cloud/api/.env.development.local`

### Где хранить Google client secret

- Для варианта с Cognito federation: **в настройках Cognito Identity Provider (Google)** в AWS Console.
- Не в репозитории.
- Не в frontend env.
- Не в `cloud/infra/.env.example`.

## Локальный запуск с Google авторизацией

### 1. Создайте OAuth Client в Google Cloud

Тип:

- `Web application`

Добавьте Authorized JavaScript origins:

- `http://localhost:3100`

Добавьте Authorized redirect URIs:

- Для Google Identity Services (One Tap / button ID token) отдельный redirect URI обычно не требуется.
- Если будете использовать классический OAuth flow отдельно, добавьте свои URI.

### 2. Настройте frontend env (`cloud/web/.env.local`)

Скопируйте `cloud/web/.env.example` в `cloud/web/.env.local` и заполните:

```env
NEXT_PUBLIC_API_URL=/api
NEXT_PUBLIC_AUTH_PROVIDER=google
NEXT_PUBLIC_GOOGLE_CLIENT_ID=your-google-oauth-client-id.apps.googleusercontent.com
```

### 3. Настройте backend env (`cloud/api/.env.local`)

Скопируйте `cloud/api/.env.example` в `cloud/api/.env.local` и заполните:

```env
PORT=4100
POSTGRES_HOST=localhost
POSTGRES_PORT=5433
POSTGRES_USER=cc_user
POSTGRES_PASSWORD=cc_pass
POSTGRES_DB=witcher_cc
POSTGRES_SSL=false
ALLOWED_ORIGINS=http://localhost:3100
AUTH_MODE=google-jwt
AUTH_GOOGLE_CLIENT_IDS=your-google-oauth-client-id.apps.googleusercontent.com
AUTH_PROTECT_HEALTH=true
```

Примечание:

- `AUTH_GOOGLE_CLIENT_IDS` может содержать несколько client id через запятую.
- Backend будет проверять подпись токена через Google JWKS.

### 4. Запуск

Запускайте ваш локальный сценарий как раньше (скрипты проекта), `dotenv-flow` подхватит `.env.local`.

## Облачный режим с Cognito (рекомендуемый для публичного доступа)

## Архитектурная идея

- Frontend логинится через Cognito Hosted UI
- Cognito (опционально) федеративно подключен к Google как внешнему IdP
- Frontend получает `id_token` Cognito и отправляет его в API
- API Gateway HTTP API проверяет JWT (Cognito JWT authorizer)
- Lambda получает уже проверенный токен и работает в режиме `trust-apigw`

Это снижает риск анонимного бот-трафика по API (вместе с throttling).

### 1. Создайте Cognito User Pool + App Client

Требования:

- App client без client secret (для SPA / PKCE)
- Включите Hosted UI domain
- Callback URL:
  - `https://<ваш-cloudfront-domain>/`
  - для локальной проверки также можно `http://localhost:3100/`
- Sign out URL:
  - `https://<ваш-cloudfront-domain>/`
  - `http://localhost:3100/` (опционально)

Scopes:

- `openid`
- `email`
- `profile`

### 2. (Опционально) Подключите Google как IdP в Cognito

В Cognito User Pool -> Federation / Identity providers -> Google:

- укажите Google `client id`
- укажите Google `client secret`

Важно:

- `client secret` хранится в AWS (Cognito), а не в git/коде проекта.

### 3. Настройте frontend env для облака (`cloud/web/.env.production.local`)

```env
NEXT_PUBLIC_API_URL=/api
NEXT_PUBLIC_AUTH_PROVIDER=cognito
NEXT_PUBLIC_COGNITO_DOMAIN=https://your-domain-prefix.auth.eu-central-1.amazoncognito.com
NEXT_PUBLIC_COGNITO_CLIENT_ID=your-cognito-app-client-id
NEXT_PUBLIC_COGNITO_REDIRECT_URI=https://<cloudfront-domain>/
NEXT_PUBLIC_COGNITO_LOGOUT_REDIRECT_URI=https://<cloudfront-domain>/
NEXT_PUBLIC_COGNITO_SCOPE=openid email profile
```

Примечание:

- Эти значения не секретны.
- Их можно передавать через CI/CD env при сборке фронтенда.

### 4. Включите Cognito JWT authorizer в CDK (infra)

Перед `cdk synth/deploy` задайте env в shell (или в CI secret variables):

PowerShell:

```powershell
$env:WCC_COGNITO_JWT_ISSUER = "https://cognito-idp.eu-central-1.amazonaws.com/eu-central-1_XXXXXXXXX"
$env:WCC_COGNITO_JWT_AUDIENCE = "your-cognito-app-client-id"
```

Опционально (если нужно временно переопределить режим Lambda без authorizer):

```powershell
$env:WCC_API_AUTH_MODE = "none"
$env:WCC_GOOGLE_CLIENT_IDS = ""
```

После этого:

```powershell
npm --workspace @wcc/infra run synth
npm --workspace @wcc/infra run deploy
```

Что произойдет:

- На `API Gateway HTTP API` включится JWT authorizer
- Lambda автоматически получит `AUTH_MODE=trust-apigw`

### 5. Сборка/деплой frontend с env

Перед сборкой `cloud/web` задайте `NEXT_PUBLIC_*` переменные для Cognito.
Затем выполните сборку фронтенда и `cdk deploy` (стек загрузит `cloud/web/out` в S3).

## Поведение защиты страниц и API

- `/` (главная) остается публичной
- Любая другая страница требует авторизацию (frontend route guard)
- API требует `Authorization` (backend middleware / API Gateway authorizer)

Исключение:

- `/api/health` также защищен по умолчанию
- Если нужен публичный health-check, установите `AUTH_PROTECT_HEALTH=false`

## Что нужно указать вручную сейчас

Обязательно:

- Google `client id` (для локального Google sign-in)
- Cognito User Pool / App Client / Hosted UI (для облака)

Необязательно:

- `POSTGRES_USER` в Lambda env для облака (берется из секрета БД, если не задан)

## Быстрая проверка после настройки

1. Откройте `/` без логина: страница должна открываться.
2. Откройте `/builder` без логина: должен сработать auth guard.
3. Выполните вход.
4. Повторно откройте `/builder`: доступ должен быть разрешен.
5. Проверьте любой API-вызов из UI: должен уходить с `Authorization: Bearer ...`.

## Замечания по кодировке

Файл сохранен в UTF-8.
