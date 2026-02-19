# Witcher Character Creator — Отчёт: Google-аутентификация и миграция в AWS

> **Дата:** 19 февраля 2026  
> **Проект:** witcher-cc-starter (монорепозиторий)  
> **Текущий стек:** Next.js 14 (фронтенд, порт 3000) + Hono/Node.js (API, порт 4000) + PostgreSQL 16 (Docker, порт 5433)

---

## Оглавление

1. [Краткое описание проекта](#1-краткое-описание-проекта)
2. [Часть 1 — Google-аутентификация](#2-часть-1--google-аутентификация)
   - 2.1. [Что такое аутентификация и зачем она нужна](#21-что-такое-аутентификация-и-зачем-она-нужна)
   - 2.2. [Выбор подхода: AWS Cognito + Google](#22-выбор-подхода-aws-cognito--google)
   - 2.3. [Альтернатива: NextAuth.js (для оффлайн/localhost)](#23-альтернатива-nextauthjs-для-оффлайнlocalhost)
   - 2.4. [Пошаговая реализация Google-логина на localhost](#24-пошаговая-реализация-google-логина-на-localhost)
   - 2.5. [Защита API-эндпоинтов](#25-защита-api-эндпоинтов)
   - 2.6. [Переход от localhost к AWS Cognito (потом)](#26-переход-от-localhost-к-aws-cognito-потом)
3. [Часть 2 — Миграция в AWS Cloud](#3-часть-2--миграция-в-aws-cloud)
   - 3.1. [Общая схема архитектуры в облаке](#31-общая-схема-архитектуры-в-облаке)
   - 3.2. [Сценарий A: Контейнеры (ECS Fargate) — рекомендуемый](#32-сценарий-a-контейнеры-ecs-fargate--рекомендуемый)
   - 3.3. [Сценарий B: Lambda-функции](#33-сценарий-b-lambda-функции)
   - 3.4. [Сравнительная таблица](#34-сравнительная-таблица)
   - 3.5. [Инфраструктура как код (IaC) — AWS CDK](#35-инфраструктура-как-код-iac--aws-cdk)
   - 3.6. [Пошаговый план миграции](#36-пошаговый-план-миграции)
   - 3.7. [Локальная разработка при облачном деплое](#37-локальная-разработка-при-облачном-деплое)
4. [Приложения](#4-приложения)
   - A. [Словарь терминов](#a-словарь-терминов)
   - B. [Примерная стоимость AWS](#b-примерная-стоимость-aws)
   - C. [Чеклист готовности к деплою](#c-чеклист-готовности-к-деплою)

---

## 1. Краткое описание проекта

**Witcher Character Creator** — это веб-приложение для создания персонажей настольной ролевой игры «Ведьмак». 

Оно состоит из трёх частей:

```
┌──────────────────────────────────────────────────────┐
│                    Монорепозиторий                    │
│                                                      │
│  ┌─────────────┐   ┌─────────────┐   ┌───────────┐  │
│  │  apps/web   │──▶│  apps/api   │──▶│ PostgreSQL │  │
│  │  (Next.js)  │   │   (Hono)    │   │   (Docker) │  │
│  │  порт 3000  │   │  порт 4000  │   │  порт 5433 │  │
│  └─────────────┘   └─────────────┘   └───────────┘  │
│    Фронтенд           Бэкенд           База данных   │
└──────────────────────────────────────────────────────┘
```

**Что сейчас реализовано:**
- Пошаговый опросник для создания персонажа (survey engine с JSONLogic)
- Магазин предметов (оружие, броня, зелья и т.д.)
- Каталог навыков с распределением очков
- Генерация PDF-листа персонажа (через Playwright/Chromium)
- Двуязычность: русский и английский

**Что НЕ реализовано:**
- ❌ Аутентификация (нет логина, нет пользователей)
- ❌ Сохранение персонажей на сервере (только sessionStorage в браузере)
- ❌ Защита от ботов / rate-limiting
- ❌ Деплой в облако
- ❌ CI/CD пайплайн

---

## 2. Часть 1 — Google-аутентификация

### 2.1. Что такое аутентификация и зачем она нужна

**Аутентификация** — это процесс проверки «кто ты?». Когда пользователь входит через Google, Google подтверждает: «Да, это Вася Пупкин, вот его email».

**Зачем это нужно вашему проекту:**

| Проблема | Как решает аутентификация |
|----------|--------------------------|
| Боты отправляют тысячи запросов к API | Без логина — нет токена, без токена — API отклоняет запрос |
| Нельзя сохранить персонажа | Знаем пользователя → можем привязать к нему персонажей в БД |
| Нельзя ограничить действия | Можно задать лимиты на пользователя (например: 10 PDF в час) |

**Как это работает (упрощённо):**

```
1. Пользователь нажимает "Войти через Google"
2. Браузер перенаправляет на страницу Google
3. Пользователь вводит свой Google-пароль
4. Google говорит вашему приложению: "Всё ок, вот данные: email, имя, фото"
5. Ваше приложение создаёт сессию (или JWT-токен)
6. При каждом запросе к API браузер отправляет этот токен
7. API проверяет токен и решает: обработать запрос или отклонить
```

### 2.2. Выбор подхода: AWS Cognito + Google

**AWS Cognito** — сервис AWS для управления пользователями. Он умеет:
- Хранить учётные записи пользователей
- Интегрироваться с Google, Facebook, Apple
- Выдавать JWT-токены
- Масштабироваться автоматически

**Почему Cognito подходит для продакшена:**
- Бесплатно до 50 000 активных пользователей в месяц
- Не нужно писать код для хранения паролей
- Интегрируется с другими сервисами AWS (API Gateway, ALB)
- Handles security (MFA, password policies) за вас

**Но есть проблема:** Cognito работает только в AWS облаке. Для локальной разработки на `localhost` его использовать можно, но настройка требует подключения к интернету и активного AWS-аккаунта.

### 2.3. Альтернатива: NextAuth.js (для оффлайн/localhost)

> **Ответ на вопрос:** Да, Google-аутентификацию **можно** добавить на текущем этапе разработки прямо на localhost.

**NextAuth.js (Auth.js)** — популярная библиотека для Next.js, которая:
- Работает прямо на `localhost:3000`
- Поддерживает Google, GitHub, Discord и 50+ провайдеров
- Не требует AWS-аккаунта
- Хранит сессии в cookie (или в БД)
- Легко заменяется на Cognito позже

**Важное ограничение:** для Google-логина даже на localhost нужен доступ к интернету — браузер должен обратиться к серверам Google. Полностью оффлайн (без интернета) Google-логин **невозможен**, так как Google OAuth требует связи с серверами Google. Но работа через `localhost` (ваш компьютер подключён к интернету) — **полностью поддерживается**.

**Рекомендация:**  
Начать с NextAuth.js сейчас → перейти на Cognito при миграции в AWS.

### 2.4. Пошаговая реализация Google-логина на localhost

#### Шаг 1: Зарегистрировать проект в Google Cloud Console

1. Откройте https://console.cloud.google.com/
2. Создайте новый проект (например: `witcher-cc`)
3. Перейдите в **APIs & Services → Credentials**
4. Нажмите **Create Credentials → OAuth client ID**
5. Тип приложения: **Web application**
6. Название: `Witcher CC Dev`
7. В **Authorized redirect URIs** добавьте:
   ```
   http://localhost:3000/api/auth/callback/google
   ```
8. Нажмите **Create**
9. Запишите **Client ID** и **Client Secret** — они понадобятся

> ⚠️ Эти данные секретные. Никогда не добавляйте их в git.

#### Шаг 2: Установить NextAuth.js

Выполните в корне проекта:

```bash
cd apps/web
npm install next-auth@4
```

> Используем версию 4, т.к. она стабильна и имеет обширную документацию.

#### Шаг 3: Создать файл переменных окружения

Создайте файл `apps/web/.env.local`:

```env
# Google OAuth (из Google Cloud Console — шаг 1)
GOOGLE_CLIENT_ID=ваш_client_id_из_google_console
GOOGLE_CLIENT_SECRET=ваш_client_secret_из_google_console

# NextAuth
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=случайная_длинная_строка_минимум_32_символа
```

Для генерации `NEXTAUTH_SECRET` выполните:

```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

#### Шаг 4: Создать API-роут для NextAuth

Создайте файл `apps/web/app/api/auth/[...nextauth]/route.ts`:

```typescript
import NextAuth from 'next-auth';
import GoogleProvider from 'next-auth/providers/google';

const handler = NextAuth({
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
  ],
  callbacks: {
    async jwt({ token, account }) {
      // При первом логине сохраняем данные из Google
      if (account) {
        token.accessToken = account.access_token;
      }
      return token;
    },
    async session({ session, token }) {
      // Передаём токен в сессию, чтобы фронтенд имел к нему доступ
      (session as any).accessToken = token.accessToken;
      return session;
    },
  },
  pages: {
    signIn: '/login',  // кастомная страница логина (опционально)
  },
});

export { handler as GET, handler as POST };
```

**Что тут происходит (простым языком):**
- `GoogleProvider` — говорит NextAuth: «Разрешаем вход через Google»
- `callbacks.jwt` — когда пользователь входит, сохраняем его токен
- `callbacks.session` — когда фронтенд запрашивает сессию, отдаём данные пользователя
- `pages.signIn` — если пользователь не залогинен, перенаправляем на `/login`

#### Шаг 5: Обернуть приложение в SessionProvider

Отредактируйте `apps/web/app/layout.tsx` — оберните содержимое в `SessionProvider`:

```typescript
// Добавить в начало файла:
import { SessionProvider } from 'next-auth/react';

// Обернуть children в SessionProvider:
// <SessionProvider>{children}</SessionProvider>
```

> Поскольку ваше приложение использует `"use client"`, SessionProvider нужно вынести в отдельный клиентский компонент-обёртку.

Создайте `apps/web/app/components/AuthProvider.tsx`:

```typescript
'use client';

import { SessionProvider } from 'next-auth/react';
import { ReactNode } from 'react';

export function AuthProvider({ children }: { children: ReactNode }) {
  return <SessionProvider>{children}</SessionProvider>;
}
```

Затем в `layout.tsx` используйте:

```tsx
import { AuthProvider } from './components/AuthProvider';

// ...внутри return:
<AuthProvider>
  <LanguageProvider>
    {/* ...существующий контент... */}
  </LanguageProvider>
</AuthProvider>
```

#### Шаг 6: Добавить кнопку «Войти через Google»

Замените хардкод пользователя в `apps/web/app/components/Topbar.tsx`:

```typescript
'use client';

import { useSession, signIn, signOut } from 'next-auth/react';

// Внутри компонента Topbar:
export function Topbar() {
  const { data: session, status } = useSession();

  // ...остальной код...

  // Вместо захардкоженного "Хозяин портала":
  return (
    <div className="user-pill">
      {status === 'authenticated' && session?.user ? (
        <>
          <img 
            src={session.user.image ?? ''} 
            alt="" 
            className="user-avatar"
            width={32} 
            height={32} 
          />
          <div className="user-info">
            <div className="user-name">{session.user.name}</div>
            <div className="user-role">{session.user.email}</div>
          </div>
          <button onClick={() => signOut()}>Выйти</button>
        </>
      ) : (
        <button onClick={() => signIn('google')}>
          Войти через Google
        </button>
      )}
    </div>
  );
}
```

#### Шаг 7: Проверить работу

1. Запустите `npm run dev` из корня проекта
2. Откройте `http://localhost:3000`
3. Нажмите «Войти через Google»
4. Вас перенаправит на страницу Google
5. После входа — вернёт назад с данными пользователя

**Возможные проблемы:**
| Проблема | Решение |
|----------|---------|
| `Error: redirect_uri_mismatch` | В Google Console проверьте redirect URI: `http://localhost:3000/api/auth/callback/google` |
| `NEXTAUTH_SECRET is not set` | Убедитесь, что `.env.local` создан в `apps/web/` |
| Белый экран | Проверьте консоль браузера (F12) на ошибки |

### 2.5. Защита API-эндпоинтов

После того как фронтенд знает «кто залогинен», нужно защитить бэкенд.

#### Вариант A: Простая защита через заголовок (для начала)

**Фронтенд** передаёт токен сессии при каждом запросе:

```typescript
// В каждом fetch-запросе к API:
const response = await fetch(`${apiUrl}/generate-character`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${session.accessToken}`,
  },
  body: JSON.stringify(data),
});
```

**Бэкенд** проверяет токен (в `apps/api/src/server.ts`):

```typescript
import { Hono } from 'hono';

const app = new Hono();

// Middleware: проверяем, что запрос содержит валидный токен
app.use('/generate-character', async (c, next) => {
  const authHeader = c.req.header('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return c.json({ error: 'Unauthorized' }, 401);
  }
  
  const token = authHeader.slice(7);
  
  // Проверяем токен (простая проверка через Google API)
  try {
    const res = await fetch(
      `https://www.googleapis.com/oauth2/v3/tokeninfo?access_token=${token}`
    );
    if (!res.ok) {
      return c.json({ error: 'Invalid token' }, 401);
    }
  } catch {
    return c.json({ error: 'Token verification failed' }, 401);
  }
  
  await next();
});
```

#### Вариант B: JWT-валидация (продвинутый, для продакшена)

При переходе на AWS Cognito, API будет проверять JWT-токен, подписанный Cognito, используя публичные ключи (JWKS). Это не требует обращения к внешнему API при каждом запросе.

### 2.6. Переход от localhost к AWS Cognito (потом)

Когда будете готовы к продакшену, замена NextAuth → Cognito потребует:

1. **Создать User Pool** в AWS Cognito
2. **Добавить Google как Identity Provider** в Cognito
3. **Заменить NextAuth** на Cognito-клиент (библиотека `@aws-amplify/auth` или `amazon-cognito-identity-js`)
4. **API проверяет JWT** от Cognito вместо Google access_token

```
Текущая схема (localhost):
  Браузер → Google → NextAuth → Сессия

Будущая схема (AWS):
  Браузер → Cognito Hosted UI → Google → Cognito → JWT-токен → API Gateway
```

Подробный план переключения описан в Части 2 (шаг 5 в плане миграции).

---

## 3. Часть 2 — Миграция в AWS Cloud

### 3.1. Общая схема архитектуры в облаке

```
                          ┌──────────────────────────────────────────┐
                          │               AWS Cloud                  │
                          │                                          │
┌──────────┐   HTTPS      │  ┌─────────────┐     ┌──────────────┐   │
│          │─────────────▶│  │ CloudFront   │────▶│    S3        │   │
│ Браузер  │              │  │ (CDN)        │     │ (статика     │   │
│          │              │  └──────┬───────┘     │  фронтенда)  │   │
│          │              │         │              └──────────────┘   │
│          │              │         │ /api/*                          │
│          │              │         ▼                                 │
│          │              │  ┌─────────────┐     ┌──────────────┐   │
│          │              │  │ API Gateway  │────▶│ ECS Fargate  │   │
│          │              │  │ или ALB      │     │ (API-сервер) │   │
│          │              │  └─────────────┘     └──────┬───────┘   │
│          │              │                             │            │
│          │              │                             ▼            │
│          │              │  ┌─────────────┐     ┌──────────────┐   │
│          │              │  │ Cognito      │     │ RDS          │   │
│          │              │  │ (авторизация)│     │ (PostgreSQL) │   │
│          │              │  └─────────────┘     └──────────────┘   │
│          │              │                                          │
└──────────┘              └──────────────────────────────────────────┘
```

**Что тут что (простым языком):**

| Сервис | Что делает | Аналогия |
|--------|-----------|----------|
| **S3** | Хранит файлы фронтенда (HTML, CSS, JS) | Флешка в облаке |
| **CloudFront** | Раздаёт файлы быстро по всему миру (CDN) | Курьерская сеть |
| **API Gateway** / **ALB** | Принимает HTTP-запросы и направляет их в API | Охранник на входе |
| **ECS Fargate** | Запускает ваш API-сервер в контейнере | Виртуальный компьютер |
| **RDS** | Управляемая база данных PostgreSQL | Тот же PostgreSQL, но AWS следит за ним |
| **Cognito** | Аутентификация пользователей | Паспортный стол |

### 3.2. Сценарий A: Контейнеры (ECS Fargate) — рекомендуемый

> **Рекомендуется для этого проекта**, потому что API использует Playwright (Chromium) для генерации PDF. Lambda плохо подходит для тяжёлых процессов вроде запуска браузера.

#### Что такое контейнер?

Контейнер — это «упакованное приложение» со всем необходимым для запуска. Как коробка, в которой лежат ваш код, Node.js, Chromium и все зависимости. Где бы вы ни открыли эту коробку — приложение запустится одинаково.

#### Что такое ECS Fargate?

- **ECS** (Elastic Container Service) — сервис AWS для запуска контейнеров
- **Fargate** — режим ECS, где AWS сам управляет серверами (вам не нужно настраивать виртуальные машины)
- Вы просто говорите: «Запусти мой контейнер с 512 МБ памяти и 0.25 CPU» — и AWS делает это

#### Шаг A.1: Создать Dockerfile для API

Создайте файл `apps/api/Dockerfile`:

```dockerfile
FROM node:20-slim

# Playwright требует системных библиотек для Chromium
RUN apt-get update && apt-get install -y \
    libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 \
    libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 \
    libxrandr2 libgbm1 libpango-1.0-0 libcairo2 \
    libasound2 libxshmfence1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Копируем package.json и устанавливаем зависимости
COPY package.json package-lock.json* ./
RUN npm ci --production

# Устанавливаем Playwright с Chromium
RUN npx playwright install chromium

# Копируем скомпилированный код
COPY dist/ ./dist/

EXPOSE 4000

CMD ["node", "dist/server.js"]
```

**Что тут происходит (строка за строкой):**

1. `FROM node:20-slim` — берём базовый образ с Node.js 20
2. `RUN apt-get...` — устанавливаем библиотеки, нужные Chromium
3. `WORKDIR /app` — создаём рабочую папку
4. `COPY package.json...` — копируем файл зависимостей
5. `RUN npm ci --production` — устанавливаем зависимости
6. `RUN npx playwright install chromium` — скачиваем Chromium
7. `COPY dist/` — копируем скомпилированный TypeScript-код
8. `EXPOSE 4000` — открываем порт 4000
9. `CMD [...]` — запускаем сервер

#### Шаг A.2: Создать Dockerfile для Web (Next.js)

> **Альтернатива:** Если Next.js приложение полностью клиентское (все страницы с `"use client"`), его можно собрать как статический сайт и загрузить в S3. Это дешевле и проще. Однако, поскольку нам понадобится NextAuth (серверный API-роут), нужен полноценный сервер.

Создайте файл `apps/web/Dockerfile`:

```dockerfile
FROM node:20-slim AS builder

WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-slim AS runner
WORKDIR /app

COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/public ./public

EXPOSE 3000

CMD ["npm", "run", "start"]
```

#### Шаг A.3: Разместить контейнеры в AWS

```
                Ваш компьютер                           AWS
┌──────────────────────────┐        ┌──────────────────────────────┐
│                          │        │                              │
│  docker build            │───────▶│  ECR (реестр контейнеров)    │
│  docker push             │        │    ├── wcc-api:latest        │
│                          │        │    └── wcc-web:latest        │
│                          │        │            │                  │
│                          │        │            ▼                  │
│                          │        │  ECS Fargate (запуск)        │
│                          │        │    ├── wcc-api (1 экземпляр) │
│                          │        │    └── wcc-web (1 экземпляр) │
│                          │        │                              │
└──────────────────────────┘        └──────────────────────────────┘
```

**ECR** (Elastic Container Registry) — это хранилище для Docker-образов в AWS. Как Docker Hub, но приватный и внутри вашего AWS-аккаунта.

### 3.3. Сценарий B: Lambda-функции

#### Что такое Lambda?

AWS Lambda — сервис, который запускает ваш код **только когда приходит запрос**. Нет запросов — нет расходов. Как лампочка: горит только когда включена.

#### Можно ли разделить ваше приложение на Lambda?

| Эндпоинт | Подходит для Lambda? | Почему |
|-----------|---------------------|--------|
| `POST /survey/next` | ✅ Да | Лёгкий запрос: запрос к БД + JSONLogic |
| `POST /generate-character` | ✅ Да | Запрос к БД + обработка данных |
| `POST /shop/allItems` | ✅ Да | Простой запрос к БД |
| `POST /skills/catalog` | ✅ Да | Простой запрос к БД |
| `POST /character/pdf` | ⚠️ Проблематично | Запускает Chromium (~300 МБ), время выполнения ~5-15 сек |

**Проблема с PDF-генерацией в Lambda (текущий подход — Playwright):**
- Playwright скачивает полный Chromium (~280 МБ), что **не влезает** в Lambda Layer (250 МБ)
- Lambda имеет максимум 10 ГБ памяти, но стандартные конфигурации — 128-512 МБ
- Timeout Lambda по умолчанию — 3 сек (максимум 15 мин), но API Gateway ограничивает до 29 сек

#### 3.3.1. Альтернативные способы генерации PDF для Lambda

Ваш HTML-шаблон (`characterHtml.ts`) — это **3380 строк** со сложными особенностями:
- Inline JavaScript, который измеряет размеры элементов (`getBoundingClientRect`)
- Динамическое перемещение контента между страницами
- Embedded изображения (body_parts PNG, formula_ingredients WebP) как base64
- Сигнал `window.__pdfReady` для синхронизации с PDF-движком

Это означает, что **любая альтернатива должна уметь исполнять JavaScript** — чисто серверные PDF-библиотеки (pdfkit, jsPDF, pdfmake) не подходят без полной переписки шаблона.

---

##### Вариант 1: `@sparticuz/chromium` + Puppeteer (⭐ рекомендуется)

**Что это:** Специально собранный Chromium (~50 МБ в сжатом виде), оптимизированный для AWS Lambda. Используется вместе с Puppeteer (аналог Playwright).

**Почему подходит:**
- Поддерживает весь HTML/CSS/JS — ваш шаблон работает без изменений
- Помещается в Lambda Layer (~50 МБ сжатый)
- Проверенное решение: используется тысячами проектов в продакшене
- Минимальные изменения в коде (замена Playwright → Puppeteer)

**Ограничения:**
- Cold start: 3–8 секунд (первый запуск после простоя)
- Рекомендуется Lambda с 1536–2048 МБ памяти
- Provisioned Concurrency ($) убирает cold start

**Изменения в коде — только в `CharacterPdfService.ts`:**

```typescript
// БЫЛО (Playwright):
import { chromium, type Browser } from 'playwright';

// СТАЛО (Puppeteer + @sparticuz/chromium):
import puppeteer, { type Browser } from 'puppeteer-core';
import chromium from '@sparticuz/chromium';

export class CharacterPdfService {
  private static browserPromise: Promise<Browser> | null = null;

  private static async getBrowser(): Promise<Browser> {
    if (!CharacterPdfService.browserPromise) {
      CharacterPdfService.browserPromise = puppeteer.launch({
        args: chromium.args,
        defaultViewport: { width: 748, height: 720, deviceScaleFactor: 2 },
        executablePath: await chromium.executablePath(),
        headless: chromium.headless,  // 'shell' в Lambda
      });
    }
    return CharacterPdfService.browserPromise;
  }

  async generatePdfBuffer(characterJson: unknown, options: PdfOptions = {}): Promise<Buffer> {
    // ...вся существующая логика подготовки данных — без изменений...

    const html = renderCharacterPdfHtml({ page1, page2, page3, page4, options });

    const browser = await CharacterPdfService.getBrowser();
    const page = await browser.newPage();

    try {
      await page.emulateMediaType('print');
      await page.setContent(html, { waitUntil: 'networkidle0' });
      await page.waitForFunction('window.__pdfReady === true', { timeout: 5000 })
        .catch(() => undefined);

      const pdf = await page.pdf({
        format: 'A4',
        printBackground: true,
        margin: { top: '0mm', right: '0mm', bottom: '0mm', left: '0mm' },
      });

      return Buffer.from(pdf);
    } finally {
      await page.close().catch(() => undefined);
    }
  }
}
```

**Установка:**

```bash
cd apps/api
npm uninstall playwright
npm install puppeteer-core @sparticuz/chromium
```

**Для локальной разработки** (где нет Lambda-среды) нужен обычный Chrome:

```typescript
private static async getBrowser(): Promise<Browser> {
  if (!CharacterPdfService.browserPromise) {
    const isLambda = !!process.env.AWS_LAMBDA_FUNCTION_NAME;
    
    CharacterPdfService.browserPromise = puppeteer.launch({
      args: isLambda ? chromium.args : ['--no-sandbox'],
      defaultViewport: { width: 748, height: 720, deviceScaleFactor: 2 },
      executablePath: isLambda
        ? await chromium.executablePath()
        : undefined,  // puppeteer найдёт локальный Chrome
      headless: isLambda ? chromium.headless : true,
    });
  }
  return CharacterPdfService.browserPromise;
}
```

---

##### Вариант 2: Gotenberg (внешний микросервис)

**Что это:** Docker-контейнер, который принимает HTML и возвращает PDF. Внутри — тот же Chromium, но упакованный как отдельный сервис.

```
Lambda (API)  ──POST HTML──▶  Gotenberg (ECS)  ──▶  PDF
```

**Плюсы:**
- Ваш шаблон работает без изменений
- Lambda остаётся лёгкой (не содержит Chromium)
- Gotenberg масштабируется отдельно

**Минусы:**
- Дополнительный сервис в инфраструктуре (контейнер ECS, ~$8/мес)
- Сетевой вызов добавляет задержку (~100-300 мс)
- Всё равно нужен контейнер (хотя и маленький, стандартный)

**Как использовать:**

```typescript
// В Lambda-функции:
const response = await fetch('http://gotenberg:3000/forms/chromium/convert/html', {
  method: 'POST',
  body: formData,  // HTML-файл как multipart/form-data
});
const pdfBuffer = Buffer.from(await response.arrayBuffer());
```

---

##### Вариант 3: Переписать шаблон на `@react-pdf/renderer` (без браузера)

**Что это:** React-библиотека, которая рендерит PDF **напрямую**, без браузера. Вместо HTML/CSS используется свой набор компонентов (`<Document>`, `<Page>`, `<View>`, `<Text>`).

**Плюсы:**
- Нет браузера вообще → Lambda с 256 МБ памяти, cold start < 1 сек
- Самый дешёвый вариант
- Размер пакета ~5 МБ

**Минусы:**
- ❌ **Требуется полная переписка шаблона** (3380 строк HTML → React-PDF компоненты)
- Не поддерживает произвольный CSS (своя система стилей, подмножество flexbox)
- Нет `getBoundingClientRect` — динамическую логику перемещения контента между страницами нужно реализовать иначе
- Ограниченная поддержка шрифтов, нет inline JS

**Пример (для представления о масштабе переписки):**

```tsx
import { Document, Page, View, Text, Image, StyleSheet } from '@react-pdf/renderer';

const styles = StyleSheet.create({
  page: { padding: '6mm', fontSize: 8, fontFamily: 'Helvetica' },
  row: { flexDirection: 'row', borderBottom: '0.5pt solid #333' },
  cell: { padding: 2, flex: 1 },
});

function CharacterSheet({ vm }) {
  return (
    <Document>
      <Page size="A4" style={styles.page}>
        <View style={styles.row}>
          <Text style={styles.cell}>{vm.page1.base.name}</Text>
          <Text style={styles.cell}>{vm.page1.base.race}</Text>
        </View>
        {/* ...и так ещё ~3000 строк... */}
      </Page>
    </Document>
  );
}
```

**Оценка трудозатрат:** 2–4 недели на переписку с учётом 4 страниц, таблиц, изображений и динамической логики.

---

##### Вариант 4: Генерация на клиенте (в браузере пользователя)

**Что это:** Переместить генерацию PDF из сервера в браузер пользователя. Браузер и так может печатать HTML в PDF.

**Как:**
1. API возвращает не PDF-файл, а **готовый HTML** (тот же шаблон)
2. Фронтенд открывает HTML в скрытом `<iframe>`
3. Вызывает `window.print()` или использует библиотеку `html2pdf.js`

**Плюсы:**
- Сервер вообще не генерирует PDF → полностью Lambda-совместимо
- Нулевая нагрузка на бэкенд
- Шаблон работает как есть (браузер пользователя — это и есть Chromium)

**Минусы:**
- Пользователь видит диалог печати (менее «гладкий» UX)
- Разные браузеры могут рендерить по-разному
- Нет контроля над настройками (пользователь может изменить поля, масштаб)
- `html2pdf.js` использует `html2canvas` → растровый PDF (не векторный, большой размер)

**Компромисс: API отдаёт HTML, клиент через `<iframe>` + `window.print()`:**

```typescript
// Новый эндпоинт API (лёгкий, без Chromium):
app.post('/character/preview-html', async (c) => {
  // ...та же логика подготовки данных...
  const html = renderCharacterPdfHtml({ page1, page2, page3, page4, options });
  return c.html(html);
});

// На фронтенде:
function downloadPdf(html: string) {
  const iframe = document.createElement('iframe');
  iframe.style.display = 'none';
  document.body.appendChild(iframe);
  iframe.contentDocument!.write(html);
  iframe.contentDocument!.close();
  iframe.contentWindow!.print();
}
```

---

##### Сравнение вариантов генерации PDF

| Критерий | `@sparticuz/chromium` | Gotenberg | `@react-pdf/renderer` | Клиентская генерация |
|----------|----------------------|-----------|----------------------|---------------------|
| **Изменения в коде** | ~50 строк | ~30 строк + инфра | 3000+ строк (переписка) | ~100 строк |
| **Совместимость с шаблоном** | ✅ 100% | ✅ 100% | ❌ Полная переписка | ✅ 100% (в Chrome) |
| **Работает в Lambda** | ✅ Да | ✅ Да (Lambda + ECS) | ✅ Да | ✅ Нет сервера |
| **Память Lambda** | 1536–2048 МБ | 256 МБ (Lambda), отдельно ECS | 256 МБ | Не применимо |
| **Cold start** | 3–8 сек | < 1 сек (Lambda) | < 1 сек | Нет |
| **Качество PDF** | Отличное (как сейчас) | Отличное | Хорошее | Зависит от браузера |
| **Стоимость Lambda** | ~$0.01 за вызов | ~$0.002 + ECS | ~$0.001 | $0 |
| **Рекомендация** | ⭐ **Лучший баланс** | Хорошо, если уже есть ECS | Если начинать с нуля | Быстрый MVP |

---

##### Рекомендуемый путь

**Краткосрочно (сейчас):** замените Playwright на `@sparticuz/chromium` + Puppeteer. Это ~50 строк изменений, и ваш PDF работает в Lambda без переделки шаблона.

**Среднесрочно:** добавьте параллельно эндпоинт `/character/preview-html`, чтобы пользователь мог распечатать через браузер. Это снимет нагрузку с сервера для большинства пользователей.

**Долгосрочно (если нужно):** если стоимость Lambda с Chromium станет проблемой при высокой нагрузке, тогда рассмотрите переписку на `@react-pdf/renderer`.

---

#### Гибридный подход (полностью Lambda-совместимый):

С `@sparticuz/chromium` **все** эндпоинты помещаются в Lambda:

```
┌────────────────────────────────────┐
│           API Gateway              │
│                                    │
│  /survey/next    ──▶ Lambda 1      │  256 МБ, быстрый
│  /generate-char  ──▶ Lambda 2      │  256 МБ, быстрый
│  /shop/allItems  ──▶ Lambda 3      │  256 МБ, быстрый
│  /skills/catalog ──▶ Lambda 4      │  256 МБ, быстрый
│                                    │
│  /character/pdf  ──▶ Lambda 5      │  2048 МБ, @sparticuz/chromium
│                                    │
└────────────────────────────────────┘
```

Контейнеры ECS **не нужны** вообще. Вся инфраструктура — serverless.

Или, с клиентской генерацией, Lambda 5 вообще не нужна:

```
┌────────────────────────────────────────────┐
│           API Gateway                      │
│                                            │
│  /survey/next        ──▶ Lambda 1          │
│  /generate-char      ──▶ Lambda 2          │
│  /shop/allItems      ──▶ Lambda 3          │
│  /skills/catalog     ──▶ Lambda 4          │
│  /character/html     ──▶ Lambda 5 (лёгкая) │  ← возвращает HTML
│                                            │
│  PDF генерируется В БРАУЗЕРЕ пользователя  │
│                                            │
└────────────────────────────────────────────┘
```

#### Пример Lambda-функции (для `/survey/next`):

```typescript
// lambda/surveyNext.ts
import { APIGatewayProxyHandler } from 'aws-lambda';
import { Pool } from 'pg';

let pool: Pool | null = null;

function getPool(): Pool {
  if (!pool) {
    pool = new Pool({
      host: process.env.POSTGRES_HOST,
      port: Number(process.env.POSTGRES_PORT ?? '5432'),
      user: process.env.POSTGRES_USER,
      password: process.env.POSTGRES_PASSWORD,
      database: process.env.POSTGRES_DB,
      ssl: { rejectUnauthorized: false },
      max: 1,  // Lambda: 1 соединение на инстанс
    });
  }
  return pool;
}

export const handler: APIGatewayProxyHandler = async (event) => {
  const body = JSON.parse(event.body ?? '{}');
  const db = getPool();
  
  // ...логика из surveyEngine.ts...
  
  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(result),
  };
};
```

### 3.4. Сравнительная таблица сценариев

| Критерий | ECS Fargate (контейнеры) | Lambda + `@sparticuz/chromium` | Lambda + клиентский PDF |
|----------|--------------------------|-------------------------------|------------------------|
| **Сложность настройки** | Средняя | Средняя (~50 строк) | Низкая (~100 строк) |
| **Стоимость при малой нагрузке** | ~$55/мес (24/7) | ~$1-5/мес | ~$0.50-2/мес |
| **Стоимость при большой нагрузке** | Растёт линейно | Растёт, но медленнее | Минимально (PDF на клиенте) |
| **PDF-генерация** | ✅ Playwright (как сейчас) | ✅ `@sparticuz/chromium` | ✅ Браузер пользователя |
| **Качество PDF** | Отличное | Отличное | Зависит от браузера |
| **Cold start** | Нет | 3-8 сек (PDF), <1 сек (остальное) | <1 сек |
| **Масштабирование** | Нужно настраивать | Автоматически | Автоматически |
| **Изменения в коде** | Минимальные (Dockerfile) | ~50 строк (замена Playwright) | ~100 строк (новый эндпоинт) |
| **Контейнеры нужны?** | Да (ECS) | Нет (полностью serverless) | Нет (полностью serverless) |
| **Рекомендация** | Если нужен полный контроль | ⭐ Лучший баланс | Самый дешёвый вариант |

### 3.5. Инфраструктура как код (IaC) — AWS CDK

#### Что такое IaC?

**Infrastructure as Code** — это когда вся ваша облачная инфраструктура (серверы, базы данных, сети) описана в коде. Вместо того, чтобы кликать по консоли AWS, вы пишете код, и инструмент создаёт всё автоматически.

**Почему CDK, а не Terraform:**
- CDK — от AWS, нативная интеграция
- Пишется на TypeScript (тот же язык, что и ваш проект)
- Terraform тоже отличный инструмент, но CDK проще для AWS-only проектов

#### Шаг: Создать CDK-проект

```bash
# В корне монорепозитория
mkdir infra
cd infra
npx cdk init app --language typescript
```

Это создаст структуру:

```
infra/
├── bin/
│   └── infra.ts          # Точка входа CDK
├── lib/
│   └── infra-stack.ts    # Описание инфраструктуры
├── cdk.json
├── package.json
└── tsconfig.json
```

#### Пример CDK-стека (ECS Fargate + RDS):

```typescript
// infra/lib/infra-stack.ts
import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecr from 'aws-cdk-lib/aws-ecr';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import { Construct } from 'constructs';

export class WccStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // ── Сеть ────────────────────────────────────────────
    // VPC — виртуальная сеть, в которой живут все сервисы
    const vpc = new ec2.Vpc(this, 'WccVpc', {
      maxAzs: 2,  // Два дата-центра для надёжности
      natGateways: 1,
    });

    // ── База данных ─────────────────────────────────────
    const database = new rds.DatabaseInstance(this, 'WccDb', {
      engine: rds.DatabaseInstanceEngine.postgres({
        version: rds.PostgresEngineVersion.VER_16,
      }),
      instanceType: ec2.InstanceType.of(
        ec2.InstanceClass.T4G, ec2.InstanceSize.MICRO  // Самый дешёвый
      ),
      vpc,
      databaseName: 'witcher_cc',
      credentials: rds.Credentials.fromGeneratedSecret('cc_user'),
      removalPolicy: cdk.RemovalPolicy.SNAPSHOT,
    });

    // ── Контейнер API ───────────────────────────────────
    const cluster = new ecs.Cluster(this, 'WccCluster', { vpc });

    const apiTaskDef = new ecs.FargateTaskDefinition(this, 'ApiTask', {
      memoryLimitMiB: 1024,  // 1 ГБ памяти (нужно для Playwright)
      cpu: 512,              // 0.5 vCPU
    });

    apiTaskDef.addContainer('api', {
      image: ecs.ContainerImage.fromAsset('../apps/api'),
      portMappings: [{ containerPort: 4000 }],
      environment: {
        PORT: '4000',
        POSTGRES_HOST: database.instanceEndpoint.hostname,
        POSTGRES_PORT: '5432',
        POSTGRES_DB: 'witcher_cc',
        POSTGRES_SSL: 'true',
      },
      secrets: {
        POSTGRES_USER: ecs.Secret.fromSecretsManager(
          database.secret!, 'username'
        ),
        POSTGRES_PASSWORD: ecs.Secret.fromSecretsManager(
          database.secret!, 'password'
        ),
      },
      logging: ecs.LogDrivers.awsLogs({ streamPrefix: 'wcc-api' }),
    });

    const apiService = new ecs.FargateService(this, 'ApiService', {
      cluster,
      taskDefinition: apiTaskDef,
      desiredCount: 1,  // 1 экземпляр (увеличить при нагрузке)
    });

    // Разрешаем API обращаться к БД
    database.connections.allowDefaultPortFrom(apiService);

    // ── Балансировщик нагрузки ──────────────────────────
    const alb = new elbv2.ApplicationLoadBalancer(this, 'WccAlb', {
      vpc,
      internetFacing: true,
    });

    const listener = alb.addListener('HttpListener', { port: 80 });
    listener.addTargets('ApiTarget', {
      port: 4000,
      targets: [apiService],
      healthCheck: { path: '/survey/next' },
    });

    // ── Cognito (аутентификация) ────────────────────────
    const userPool = new cognito.UserPool(this, 'WccUserPool', {
      selfSignUpEnabled: true,
      signInAliases: { email: true },
      autoVerify: { email: true },
    });

    const googleProvider = new cognito.UserPoolIdentityProviderGoogle(
      this, 'GoogleProvider', {
        userPool,
        clientId: 'GOOGLE_CLIENT_ID',       // Подставить при деплое
        clientSecretValue: cdk.SecretValue.unsafePlainText(
          'GOOGLE_CLIENT_SECRET'             // Лучше: SecretsManager
        ),
        scopes: ['email', 'profile'],
        attributeMapping: {
          email: cognito.ProviderAttribute.GOOGLE_EMAIL,
          fullname: cognito.ProviderAttribute.GOOGLE_NAME,
          profilePicture: cognito.ProviderAttribute.GOOGLE_PICTURE,
        },
      }
    );

    const userPoolClient = userPool.addClient('WccWebClient', {
      supportedIdentityProviders: [
        cognito.UserPoolClientIdentityProvider.GOOGLE,
      ],
      oAuth: {
        flows: { authorizationCodeGrant: true },
        scopes: [cognito.OAuthScope.OPENID, cognito.OAuthScope.EMAIL],
        callbackUrls: [
          'http://localhost:3000/api/auth/callback/cognito',
          'https://your-domain.com/api/auth/callback/cognito',
        ],
      },
    });

    // ── Выводим важные значения ─────────────────────────
    new cdk.CfnOutput(this, 'AlbDnsName', {
      value: alb.loadBalancerDnsName,
    });
    new cdk.CfnOutput(this, 'DbEndpoint', {
      value: database.instanceEndpoint.hostname,
    });
    new cdk.CfnOutput(this, 'UserPoolId', {
      value: userPool.userPoolId,
    });
    new cdk.CfnOutput(this, 'UserPoolClientId', {
      value: userPoolClient.userPoolClientId,
    });
  }
}
```

**Что создаёт этот код:**
1. Виртуальную сеть (VPC) с двумя зонами доступности
2. Базу данных PostgreSQL 16 (RDS, самый дешёвый инстанс)
3. Контейнерный кластер (ECS Fargate) с API-сервером
4. Балансировщик нагрузки (ALB) для приёма HTTP-запросов
5. Cognito User Pool с Google-провайдером

#### Команды деплоя:

```bash
cd infra

# Первый раз: инициализация CDK в вашем AWS аккаунте
npx cdk bootstrap

# Посмотреть, что будет создано (без реального создания)
npx cdk diff

# Создать/обновить инфраструктуру
npx cdk deploy

# Удалить всё (если нужно)
npx cdk destroy
```

### 3.6. Пошаговый план миграции

Ниже — план по шагам в хронологическом порядке. Каждый шаг можно делать независимо.

---

#### Этап 0: Подготовка (делать сейчас, на localhost)

**Шаг 0.1 — Создать AWS-аккаунт**
1. Перейдите на https://aws.amazon.com/
2. Нажмите «Create an AWS Account»
3. Введите email, пароль, данные карты (не списывают, если Free Tier)
4. Подтвердите email
5. Установите AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html
6. Настройте: `aws configure` (введите Access Key и Secret Key)

**Шаг 0.2 — Установить Docker Desktop**
1. Скачайте: https://www.docker.com/products/docker-desktop/
2. Установите и запустите
3. Проверьте: `docker --version`

**Шаг 0.3 — Добавить Google Auth (NextAuth.js)**
- Следуйте шагам из раздела 2.4 этого документа
- Убедитесь, что вход через Google работает на `localhost:3000`

**Шаг 0.4 — Добавить Rate-Limiting**

Установите middleware для ограничения запросов:

```bash
cd apps/api
npm install hono-rate-limiter
```

Добавьте в `server.ts`:

```typescript
import { rateLimiter } from 'hono-rate-limiter';

app.use('*', rateLimiter({
  windowMs: 60 * 1000,  // 1 минута
  limit: 30,            // Максимум 30 запросов в минуту
  keyGenerator: (c) => {
    // Используем IP или токен пользователя
    return c.req.header('Authorization') ?? 
           c.req.header('x-forwarded-for') ?? 
           'anonymous';
  },
}));
```

---

#### Этап 1: Контейнеризация (подготовка к облаку)

**Шаг 1.1 — Создать Dockerfile для API**
- Файл: `apps/api/Dockerfile` (см. раздел 3.2, Шаг A.1)

**Шаг 1.2 — Создать Dockerfile для Web**
- Файл: `apps/web/Dockerfile` (см. раздел 3.2, Шаг A.2)

**Шаг 1.3 — Создать docker-compose.yml для полного стека**

Создайте `docker-compose.yml` в корне проекта:

```yaml
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: cc_user
      POSTGRES_PASSWORD: cc_pass
      POSTGRES_DB: witcher_cc
    ports:
      - "5433:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U cc_user -d witcher_cc"]
      interval: 5s
      timeout: 5s
      retries: 20

  api:
    build: ./apps/api
    ports:
      - "4000:4000"
    environment:
      PORT: "4000"
      POSTGRES_HOST: postgres
      POSTGRES_PORT: "5432"
      POSTGRES_USER: cc_user
      POSTGRES_PASSWORD: cc_pass
      POSTGRES_DB: witcher_cc
    depends_on:
      postgres:
        condition: service_healthy

  web:
    build: ./apps/web
    ports:
      - "3000:3000"
    environment:
      NEXT_PUBLIC_API_URL: http://api:4000
    depends_on:
      - api

volumes:
  pgdata:
```

**Шаг 1.4 — Проверить локально**

```bash
# Собрать и запустить всё одной командой
docker compose up --build

# Проверить: http://localhost:3000
# Остановить: Ctrl+C или docker compose down
```

---

#### Этап 2: Инфраструктура как код

**Шаг 2.1 — Инициализировать CDK**

```bash
# Установить CDK глобально
npm install -g aws-cdk

# Создать папку infra
mkdir infra && cd infra
npx cdk init app --language typescript

# Установить необходимые модули
npm install aws-cdk-lib constructs
```

**Шаг 2.2 — Написать CDK-стек**
- Используйте пример из раздела 3.5 как основу
- Адаптируйте параметры (имя домена, размер инстансов и т.д.)

**Шаг 2.3 — Инициализировать CDK в AWS**

```bash
# Выполняется один раз для каждого AWS-аккаунта/региона
cd infra
npx cdk bootstrap aws://ACCOUNT_ID/eu-central-1
```

> `ACCOUNT_ID` — 12-значный номер вашего AWS-аккаунта. Найти: AWS Console → правый верхний угол → Account ID.  
> `eu-central-1` — регион (Франкфурт). Выберите ближайший к вашим пользователям.

---

#### Этап 3: Первый деплой

**Шаг 3.1 — Собрать Docker-образы и запушить в ECR**

```bash
# Логин в ECR
aws ecr get-login-password --region eu-central-1 | \
  docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.eu-central-1.amazonaws.com

# CDK может делать это автоматически через ContainerImage.fromAsset()
```

**Шаг 3.2 — Деплой инфраструктуры**

```bash
cd infra
npx cdk deploy
```

**Что произойдёт:**
1. CDK создаст все ресурсы в AWS (~5-10 минут)
2. Выведет URL балансировщика нагрузки
3. API будет доступен по этому URL

**Шаг 3.3 — Применить миграции БД**

После деплоя нужно заполнить базу данных:

```bash
# Подключиться к RDS (через SSH-туннель или AWS Systems Manager)
# Или запустить ECS Task с миграциями:

aws ecs run-task \
  --cluster WccCluster \
  --task-definition WccMigrationTask \
  --launch-type FARGATE \
  --network-configuration "..." 
```

> Лучше создать отдельный ECS Task Definition для миграций, который запускает `seed.sh`.

---

#### Этап 4: Настройка фронтенда

**Вариант A: Next.js в контейнере (проще, дороже)**
- Уже настроено в Шаге 1.2
- Добавить сервис в CDK-стек

**Вариант B: Статический экспорт + S3 + CloudFront (дешевле)**

> Подходит, если удастся перенести NextAuth на серверную сторону API (Hono) и использовать `output: 'export'` в Next.js. Требует рефакторинга.

Для начала — используйте **Вариант A** (проще).

---

#### Этап 5: Подключить Cognito вместо NextAuth

1. Установите `next-auth` провайдер для Cognito:

```typescript
// apps/web/app/api/auth/[...nextauth]/route.ts
import CognitoProvider from 'next-auth/providers/cognito';

const handler = NextAuth({
  providers: [
    CognitoProvider({
      clientId: process.env.COGNITO_CLIENT_ID!,
      clientSecret: process.env.COGNITO_CLIENT_SECRET!,
      issuer: process.env.COGNITO_ISSUER!,
      // issuer = https://cognito-idp.{region}.amazonaws.com/{userPoolId}
    }),
  ],
});
```

2. Обновите переменные окружения:

```env
COGNITO_CLIENT_ID=из_CDK_вывода
COGNITO_CLIENT_SECRET=из_AWS_Console
COGNITO_ISSUER=https://cognito-idp.eu-central-1.amazonaws.com/eu-central-1_XXXXX
```

3. API проверяет JWT от Cognito:

```typescript
// apps/api/src/middleware/auth.ts
import { verify } from 'jsonwebtoken';
import jwksClient from 'jwks-rsa';

const client = jwksClient({
  jwksUri: `https://cognito-idp.${REGION}.amazonaws.com/${USER_POOL_ID}/.well-known/jwks.json`,
});

export async function verifyToken(token: string) {
  // Получаем публичный ключ и проверяем подпись JWT
  const decoded = verify(token, getKey, { algorithms: ['RS256'] });
  return decoded;
}
```

---

#### Этап 6: CI/CD (автоматический деплой)

Создайте `.github/workflows/deploy.yml`:

```yaml
name: Deploy to AWS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Install dependencies
        run: npm ci

      - name: Build API
        run: npm run build:api

      - name: Build Web
        run: npm run build:web

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: eu-central-1

      - name: Deploy with CDK
        working-directory: infra
        run: |
          npm ci
          npx cdk deploy --require-approval never
```

**Что это делает:**
- При каждом `git push` в ветку `main`
- GitHub Actions автоматически собирает проект
- И деплоит его в AWS через CDK

### 3.7. Локальная разработка при облачном деплое

После миграции в AWS вы продолжаете разрабатывать **локально**. Вот как это работает:

```
┌─────────────────────────────────────────────────────────────────┐
│                     Ваш компьютер (localhost)                   │
│                                                                 │
│  ┌──────────┐     ┌──────────┐     ┌─────────────────────────┐  │
│  │ Next.js  │────▶│ Hono API │────▶│ PostgreSQL (Docker)     │  │
│  │ :3000    │     │ :4000    │     │ :5433                   │  │
│  └──────────┘     └──────────┘     └─────────────────────────┘  │
│                                                                 │
│  Всё работает локально, как сейчас. Ничего не меняется.         │
│  npm run dev — запускает всё.                                   │
└────────────────────────┬────────────────────────────────────────┘
                         │ git push
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     GitHub Actions (CI/CD)                       │
│  Автоматически собирает образы и деплоит в AWS                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     AWS Cloud (продакшен)                        │
│                                                                 │
│  CloudFront → ALB → ECS Fargate (API + Web) → RDS (PostgreSQL) │
│                                                                 │
│  Cognito → Google Auth                                          │
└─────────────────────────────────────────────────────────────────┘
```

**Ключевые правила:**
1. **Разрабатываете** всегда локально (`npm run dev`)
2. **Тестируете** локально (localhost + Docker PostgreSQL)
3. **Деплоите** через `git push` → GitHub Actions → AWS
4. **Переменные окружения** разные для dev и prod:
   - Локально: `.env.local` с `localhost` значениями
   - AWS: переменные задаются в CDK/ECS Task Definition

**Файл `.env.local` (для локальной разработки):**

```env
# API
POSTGRES_HOST=localhost
POSTGRES_PORT=5433
POSTGRES_USER=cc_user
POSTGRES_PASSWORD=cc_pass
POSTGRES_DB=witcher_cc

# Web
NEXT_PUBLIC_API_URL=http://localhost:4000
GOOGLE_CLIENT_ID=ваш_id
GOOGLE_CLIENT_SECRET=ваш_secret
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=ваша_строка
```

**Переменные для AWS (в CDK):**

```env
POSTGRES_HOST=wcc-db.xxxxxx.eu-central-1.rds.amazonaws.com
POSTGRES_PORT=5432
POSTGRES_SSL=true
# Пароль берётся из AWS Secrets Manager автоматически
```

---

## 4. Приложения

### A. Словарь терминов

| Термин | Объяснение |
|--------|-----------|
| **AWS** | Amazon Web Services — облачная платформа. Предоставляет серверы, базы данных и другие сервисы в аренду |
| **VPC** | Virtual Private Cloud — ваша приватная сеть в AWS. Как домашний Wi-Fi, но в облаке |
| **EC2** | Виртуальные серверы в AWS. ECS Fargate использует их «под капотом», но вы их не видите |
| **ECS** | Elastic Container Service — запускает Docker-контейнеры в AWS |
| **Fargate** | Режим ECS, где AWS управляет серверами за вас |
| **ECR** | Elastic Container Registry — хранилище Docker-образов (как Docker Hub, но приватный) |
| **RDS** | Relational Database Service — управляемые базы данных. AWS следит за обновлениями, бэкапами |
| **S3** | Simple Storage Service — хранилище файлов. Бесконечное, дешёвое |
| **CloudFront** | CDN (Content Delivery Network) — раздаёт файлы с серверов, ближайших к пользователю |
| **Lambda** | Сервис для запуска кода без серверов. Платите только за время выполнения |
| **API Gateway** | Сервис для создания HTTP API. Принимает запросы и направляет в Lambda/ECS |
| **ALB** | Application Load Balancer — распределяет запросы между несколькими экземплярами приложения |
| **Cognito** | Сервис аутентификации. Управляет пользователями, токенами, интеграцией с Google |
| **CDK** | Cloud Development Kit — инструмент для описания AWS-инфраструктуры кодом (TypeScript) |
| **Docker** | Платформа для контейнеризации. Упаковывает приложение со всеми зависимостями |
| **JWT** | JSON Web Token — зашифрованный токен с данными пользователя. Передаётся в заголовке запроса |
| **OAuth** | Протокол авторизации. Позволяет «Войти через Google» без передачи пароля вашему сайту |
| **CORS** | Cross-Origin Resource Sharing — механизм безопасности браузера. Разрешает/запрещает запросы между разными доменами |
| **CI/CD** | Continuous Integration / Continuous Deployment — автоматическая сборка и деплой при каждом коммите |
| **Cold start** | Время «разогрева» Lambda при первом запросе после простоя |
| **IaC** | Infrastructure as Code — описание инфраструктуры кодом вместо ручной настройки |

### B. Примерная стоимость AWS

> Все цены приблизительные, на февраль 2026, регион eu-central-1.

**Минимальная конфигурация (ECS Fargate):**

| Сервис | Конфигурация | Стоимость/мес |
|--------|-------------|---------------|
| ECS Fargate (API) | 0.5 vCPU, 1 GB RAM, 24/7 | ~$15 |
| ECS Fargate (Web) | 0.25 vCPU, 0.5 GB RAM, 24/7 | ~$8 |
| RDS PostgreSQL | db.t4g.micro, 20 GB | ~$15 |
| ALB | 1 балансировщик | ~$16 |
| ECR | Хранение образов | ~$1 |
| CloudFront | До 1 TB трафика | $0 (Free Tier) |
| Cognito | До 50,000 пользователей | $0 (Free Tier) |
| **Итого** | | **~$55/мес** |

**Альтернатива — полностью Lambda (c `@sparticuz/chromium` для PDF):**

| Сервис | Конфигурация | Стоимость/мес |
|--------|-------------|---------------|
| Lambda (лёгкие эндпоинты) | 256 МБ, до 1 млн запросов | $0 (Free Tier) |
| Lambda (PDF) | 2048 МБ, ~1000 PDF/мес | ~$2 |
| API Gateway | До 1 млн запросов | ~$3.50 |
| RDS PostgreSQL | db.t4g.micro | ~$15 |
| CloudFront + S3 (фронтенд) | До 1 ТБ трафика | $0 (Free Tier) |
| Cognito | До 50,000 пользователей | $0 (Free Tier) |
| **Итого** | | **~$21/мес** |

**Самый дешёвый — Lambda + клиентский PDF (без серверной генерации):**

| Сервис | Конфигурация | Стоимость/мес |
|--------|-------------|---------------|
| Lambda | 256 МБ, до 1 млн запросов | $0 (Free Tier) |
| API Gateway | До 1 млн запросов | ~$3.50 |
| RDS PostgreSQL | db.t4g.micro | ~$15 |
| **Итого** | | **~$19/мес** |

> Первые 12 месяцев AWS предоставляет Free Tier — многие сервисы бесплатны в рамках лимитов.

### C. Чеклист готовности к деплою

- [ ] **Аутентификация**
  - [ ] Google Cloud Console: создан OAuth Client ID
  - [ ] NextAuth.js установлен и работает на localhost
  - [ ] API-эндпоинты защищены middleware авторизации
  - [ ] Rate-limiting настроен

- [ ] **Контейнеризация**
  - [ ] Dockerfile для API создан и протестирован
  - [ ] Dockerfile для Web создан и протестирован
  - [ ] docker-compose.yml для полного стека работает
  - [ ] .dockerignore создан (исключает node_modules, .git, .env)

- [ ] **Инфраструктура**
  - [ ] AWS-аккаунт создан
  - [ ] AWS CLI установлен и настроен
  - [ ] CDK-проект создан в папке `infra/`
  - [ ] CDK-стек описывает: VPC, RDS, ECS, ALB, Cognito
  - [ ] `cdk bootstrap` выполнен

- [ ] **База данных**
  - [ ] Миграции работают в контейнере
  - [ ] Начальные данные (seed) загружаются
  - [ ] SSL-подключение к RDS проверено

- [ ] **CI/CD**
  - [ ] GitHub Actions workflow создан
  - [ ] AWS credentials добавлены в GitHub Secrets
  - [ ] Деплой работает при `git push`

- [ ] **Безопасность**
  - [ ] Секреты хранятся в AWS Secrets Manager (не в коде)
  - [ ] CORS настроен на домен продакшена
  - [ ] HTTPS настроен (через ALB или CloudFront)
  - [ ] .env файлы в .gitignore

- [ ] **Мониторинг**
  - [ ] CloudWatch логи настроены
  - [ ] Алерты на ошибки (опционально)

---

> **Итоговая рекомендация:**  
> 1. Сначала добавьте Google Auth через NextAuth.js (работает сразу на localhost).  
> 2. Создайте Dockerfiles и проверьте `docker compose up`.  
> 3. Напишите CDK-стек и разверните в AWS.  
> 4. Настройте CI/CD через GitHub Actions.  
> 5. Замените NextAuth на Cognito для продакшена.  
> 
> Каждый этап можно делать независимо. Начинайте с п.1 — это даст защиту от ботов уже сейчас.
