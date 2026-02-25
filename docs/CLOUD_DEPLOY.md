# Деплой WCC в AWS

## Команды для консоли (всё уже готово в репо)

```powershell
aws sso login --profile pal-iamic-admin
$env:AWS_PROFILE = "pal-iamic-admin"
npm run build
npm run deploy
```

После деплоя URL приложения будет в выводе (CloudFront). Для первого деплоя в аккаунте один раз выполните:  
`cd cloud\infra; npx cdk bootstrap --profile pal-iamic-admin`

---

## Предварительные условия (подробнее)

- Node.js ≥ 20
- AWS CLI v2, настроенный профиль (например `pal-iamic-admin`)
- Один раз выполнен `aws sso login --profile pal-iamic-admin`

---

## 1. Войти в AWS

```powershell
aws sso login --profile pal-iamic-admin
```

При необходимости замените `pal-iamic-admin` на ваш профиль.

---

## 2. Bootstrap CDK (один раз на аккаунт/регион)

Если CDK в этом аккаунте ещё не бутстрапили:

```powershell
cd cloud\infra
npx cdk bootstrap aws://ACCOUNT_ID/eu-central-1 --profile pal-iamic-admin
```

`ACCOUNT_ID` — ваш AWS account id (узнать: `aws sts get-caller-identity --profile pal-iamic-admin`).

---

## 3. Переменные окружения для инфраструктуры

В `cloud/infra` перед `synth`/`deploy` нужно задать переменные (можно в PowerShell или в `.env` и загрузка через скрипт).

**Минимум для тестового деплоя (без Cognito):**

```powershell
$env:WCC_API_AUTH_MODE = "none"
# WCC_COGNITO_JWT_ISSUER и WCC_COGNITO_JWT_AUDIENCE не задаём — API будет без JWT authorizer
```

**Для продакшена с Cognito:**

```powershell
$env:WCC_COGNITO_JWT_ISSUER = "https://cognito-idp.eu-central-1.amazonaws.com/eu-central-1_XXXXXXXXX"
$env:WCC_COGNITO_JWT_AUDIENCE = "your-cognito-app-client-id"
$env:WCC_API_AUTH_MODE = "trust-apigw"
```

Cognito User Pool и App Client нужно создать вручную в AWS Console (см. `docs/AUTH_GOOGLE_COGNITO_SETUP.md`).

---

## 4. Собрать фронтенд под облако

В `cloud/web` при сборке должен использоваться **облачный** API URL, иначе в статике попадёт `localhost`.

**Вариант A — файл `cloud/web/.env.production.local`:**

```env
NEXT_PUBLIC_API_URL=/api
NEXT_PUBLIC_AUTH_PROVIDER=cognito
NEXT_PUBLIC_COGNITO_DOMAIN=https://your-prefix.auth.eu-central-1.amazoncognito.com
NEXT_PUBLIC_COGNITO_CLIENT_ID=your-app-client-id
NEXT_PUBLIC_COGNITO_REDIRECT_URI=https://your-cloudfront-domain.cloudfront.net/
NEXT_PUBLIC_COGNITO_LOGOUT_REDIRECT_URI=https://your-cloudfront-domain.cloudfront.net/
NEXT_PUBLIC_COGNITO_SCOPE=openid email profile
```

Для первого теста без авторизации можно `NEXT_PUBLIC_AUTH_PROVIDER=none` и только `NEXT_PUBLIC_API_URL=/api`.

**Вариант B — переменные в момент сборки (PowerShell):**

```powershell
$env:NEXT_PUBLIC_API_URL = "/api"
$env:NEXT_PUBLIC_AUTH_PROVIDER = "cognito"
# остальные NEXT_PUBLIC_* по необходимости
```

Далее сборка всего проекта и статики веба:

```powershell
cd c:\Vitalii Iandulov\Projects\Witcher\wcc
npm run build
```

Убедитесь, что в `cloud/web/out` в сгенерированных JS нет `localhost` — только `/api`.

---

## 5. Деплой стека

Из корня репозитория:

```powershell
$env:AWS_PROFILE = "pal-iamic-admin"
# при необходимости задать WCC_COGNITO_JWT_ISSUER, WCC_COGNITO_JWT_AUDIENCE, WCC_API_AUTH_MODE
npm run deploy
```

Или из `cloud/infra`:

```powershell
cd cloud\infra
$env:AWS_PROFILE = "pal-iamic-admin"
$env:WCC_API_AUTH_MODE = "none"
npx cdk deploy --require-approval never
```

При первом деплое создаётся VPC, RDS, Lambda, API Gateway, S3, CloudFront. RDS и первый запуск Lambda могут занять несколько минут.

---

## 6. После деплоя

- **URL приложения:** в выводе `cdk deploy` будет `WccCdnDistributionDomainName` или CloudFront URL (например `https://xxxxx.cloudfront.net`).
- **Redirect URI для Cognito:** укажите `https://ваш-cloudfront-url/` и `https://ваш-cloudfront-url/**` в настройках App Client.
- Проверка: откройте CloudFront URL, убедитесь, что запросы идут на `/api` (сеть в DevTools).

---

## Краткий чеклист

| Шаг | Действие |
|-----|----------|
| 1 | `aws sso login --profile pal-iamic-admin` |
| 2 | При необходимости: `cdk bootstrap` |
| 3 | Задать env для infra: `WCC_API_AUTH_MODE`, при необходимости Cognito |
| 4 | В `cloud/web` задать `NEXT_PUBLIC_API_URL=/api` и собрать: `npm run build` |
| 5 | `npm run deploy` (или `cd cloud/infra && npx cdk deploy`) с выбранным профилем |

Подробнее о готовности и ограничениях — `docs/CLOUD_DEPLOY_READINESS_REPORT.md`.
