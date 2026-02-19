# Witcher Character Creator — Архитектура и руководство по эксплуатации

> **Дата:** 19 февраля 2026  
> **Статус:** Репозиторий реструктурирован. Legacy работает. Cloud-версия — scaffold, готов к деплою после сборки.

---

## 1. Новая структура репозитория

```
wcc/
│
├── packages/                          SHARED — ядро бизнес-логики
│   └── core/
│       ├── src/
│       │   ├── db/pool.ts             Подключение к PostgreSQL (pg.Pool)
│       │   ├── services/
│       │   │   ├── surveyEngine.ts    Движок опросника (4248 строк, JSONLogic)
│       │   │   ├── shopCatalog.ts     Каталог магазина предметов
│       │   │   └── skillsCatalog.ts   Каталог навыков
│       │   ├── character/
│       │   │   └── generateCharacter.ts   Генерация персонажа + i18n-резолвинг
│       │   ├── data/
│       │   │   └── defaultCharacter.json  Шаблон персонажа по умолчанию
│       │   └── index.ts               Barrel-экспорт всего модуля
│       ├── package.json               "@wcc/core"
│       └── tsconfig.json
│
├── apps/                              LEGACY — текущее рабочее приложение
│   ├── api/
│   │   ├── src/
│   │   │   ├── server.ts              Точка входа (Hono + @hono/node-server, порт 4000)
│   │   │   ├── handlers/              Тонкие обёртки, импортируют из @wcc/core
│   │   │   │   ├── generateCharacter.ts
│   │   │   │   ├── nextQuestion.ts
│   │   │   │   ├── getAllShopItems.ts
│   │   │   │   ├── getSkillsCatalog.ts
│   │   │   │   └── characterPdf.ts    PDF-генерация (Playwright)
│   │   │   └── pdf/                   Всё, что связано с PDF (шаблоны, assets, viewModels)
│   │   └── package.json               Зависит от @wcc/core
│   └── web/
│       ├── app/                        Next.js App Router (все страницы "use client")
│       ├── next.config.mjs             Стандартный Next.js (НЕ static export)
│       └── package.json
│
├── cloud/                             NEW — облачная версия
│   ├── api/
│   │   ├── src/
│   │   │   ├── app.ts                 Hono-приложение с basePath('/api')
│   │   │   ├── lambda.ts              Точка входа для AWS Lambda (3 строки)
│   │   │   └── server.ts              Точка входа для локальной разработки (порт 4100)
│   │   ├── package.json               "@wcc/cloud-api"
│   │   └── tsconfig.json
│   ├── web/
│   │   ├── app/                        Копия apps/web, адаптированная для облака
│   │   ├── next.config.mjs             output: 'export' (статический сайт)
│   │   ├── .env.local                  NEXT_PUBLIC_API_URL=http://localhost:4100/api
│   │   └── package.json               "@wcc/cloud-web", порт 3100
│   └── infra/
│       ├── bin/infra.ts                Точка входа CDK
│       ├── lib/wcc-stack.ts            CDK-стек (VPC, RDS, Lambda, API Gateway, S3, CloudFront)
│       ├── cdk.json
│       └── package.json               "@wcc/infra"
│
├── db/                                SHARED — база данных
│   ├── sql/                            150+ SQL-миграций
│   ├── docker-compose.yml              PostgreSQL 16 + pgAdmin
│   └── seed.sh                         Скрипт инициализации БД
│
└── package.json                       Корневой — npm workspaces, скрипты запуска
```

---

## 2. Что такое `packages/core` и что он экспортирует

`@wcc/core` — это npm workspace-пакет, содержащий всю бизнес-логику, которая не зависит от фреймворка (Hono) или среды выполнения (Node.js / Lambda).

### Экспортируемые функции

| Экспорт | Файл | Описание |
|---------|------|----------|
| `db` | `db/pool.ts` | Объект с методами `query()` и `close()` для PostgreSQL |
| `getNextQuestion()` | `services/surveyEngine.ts` | Следующий вопрос опросника по текущему состоянию |
| `getCharacterRawFromAnswers()` | `services/surveyEngine.ts` | Собирает characterRaw из массива ответов |
| `getAllShopItems()` | `services/shopCatalog.ts` | Все товары магазина для данного вопроса |
| `getSkillsCatalog()` | `services/skillsCatalog.ts` | Каталог навыков с i18n |
| `generateCharacterFromBody()` | `character/generateCharacter.ts` | Генерация персонажа: i18n-резолвинг UUID → строки |

### Как используется

```typescript
// В apps/api (legacy):
import { getNextQuestion } from '@wcc/core';

// В cloud/api (облачная версия):
import { generateCharacterFromBody, getNextQuestion } from '@wcc/core';
```

Один и тот же код — два потребителя. Исправление бага в survey engine автоматически применяется и в legacy, и в облаке.

---

## 3. Отличие legacy (`apps/`) от облачной версии (`cloud/`)

| Аспект | `apps/` (legacy) | `cloud/` (облако) |
|--------|-------------------|-------------------|
| **Точка входа API** | `server.ts` → `@hono/node-server` (порт 4000) | `lambda.ts` → `hono/aws-lambda` + `server.ts` (порт 4100) |
| **Фронтенд** | Next.js с dev-сервером (порт 3000) | Next.js `output: 'export'` → статические файлы (порт 3100) |
| **API URL по умолчанию** | `http://localhost:4000` | `/api` (relative, через CloudFront) |
| **PDF** | Есть (Playwright/Chromium) | Пока нет (добавится отдельной Lambda) |
| **Auth** | Нет | Будет добавлен (Cognito + Google) |
| **CRUD персонажей** | Нет | Будет добавлен |
| **Маршрутизация API** | Без basePath (`/survey/next`) | С basePath (`/api/survey/next`) |
| **CORS** | `http://localhost:3000` | Конфигурируемый через `ALLOWED_ORIGINS` |
| **Деплой** | Не предусмотрен | CDK → AWS (Lambda + S3 + CloudFront + RDS) |

### Что предстоит добавить в `cloud/`

1. **CRUD для персонажей** — новые эндпоинты в `cloud/api/src/app.ts` + таблица `wcc_characters` в `db/sql/`
2. **Google Auth** — AWS Cognito в CDK-стеке + middleware проверки JWT в `cloud/api`
3. **PDF-генерация** — отдельная Lambda с `@sparticuz/chromium` (или клиентская генерация)
4. **Страница редактирования** — `cloud/web/app/characters/[id]/page.tsx`
5. **Rate-limiting** — middleware в `cloud/api/src/app.ts`

---

## 4. Локальный запуск

### Предварительные требования

- Node.js >= 20
- Docker Desktop (для PostgreSQL)
- npm (входит в Node.js)

### Запуск legacy (для отладки бизнес-логики / SQL)

```bash
# 1. Поднять базу данных
cd db
docker compose up -d
./seed.sh          # или: bash seed.sh (Windows Git Bash)

# 2. Вернуться в корень и запустить
cd ..
npm run dev
```

Откроется:
- Фронтенд: http://localhost:3000
- API: http://localhost:4000

### Запуск cloud-версии (для разработки облачных фич)

```bash
# 1. Поднять базу данных (если ещё не запущена)
cd db
docker compose up -d
./seed.sh

# 2. Вернуться в корень и запустить
cd ..
npm run dev:cloud
```

Откроется:
- Фронтенд: http://localhost:3100
- API: http://localhost:4100/api/health

### Оба одновременно

```bash
npm-run-all -p dev dev:cloud
```

Legacy будет на портах 3000/4000, cloud — на 3100/4100. Оба используют одну и ту же БД.

---

## 5. Сборка для деплоя

```bash
# Собрать cloud API (TypeScript → JavaScript)
npm run build:cloud-api

# Собрать cloud Web (Next.js → статические файлы в cloud/web/out/)
npm run build:cloud-web
```

После сборки:
- `cloud/api/dist/` содержит JS-файлы для Lambda
- `cloud/web/out/` содержит HTML/JS/CSS для S3

---

## 6. Деплой в AWS

### Предварительные требования

1. **AWS-аккаунт** — https://aws.amazon.com/
2. **AWS CLI** — установлен и настроен (`aws configure`)
3. **AWS CDK** — `npm install -g aws-cdk`

### Инфраструктура, создаваемая CDK-стеком

CDK-стек (`cloud/infra/lib/wcc-stack.ts`) создаёт:

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS Cloud                           │
│                                                             │
│  ┌──────────────┐     ┌───────────────┐                     │
│  │  CloudFront   │────▶│  S3 Bucket    │                     │
│  │  (CDN + HTTPS)│     │  (cloud/web/  │                     │
│  │               │     │   out/)       │                     │
│  │  /api/*       │     └───────────────┘                     │
│  │  ─────────────│──┐                                        │
│  └──────────────┘  │                                        │
│                     │  ┌───────────────┐     ┌────────────┐ │
│                     └─▶│  API Gateway   │────▶│  Lambda    │ │
│                        │  (HTTP API)    │     │  (cloud/   │ │
│                        └───────────────┘     │   api/)    │ │
│                                              └─────┬──────┘ │
│  ┌────────────┐                              ┌─────▼──────┐ │
│  │    VPC      │                              │    RDS      │ │
│  │  (сеть)     │◀────────────────────────────▶│ PostgreSQL  │ │
│  └────────────┘                              │    16       │ │
│                                              └────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

| Сервис | Что делает | Конфигурация |
|--------|-----------|-------------|
| **VPC** | Изолированная сеть | 2 зоны доступности, 1 NAT Gateway |
| **RDS** | PostgreSQL 16 | db.t4g.micro, 20 ГБ, автосекрет |
| **Lambda** | Исполняет API-код | Node.js 20, 256 МБ, 29 сек timeout |
| **API Gateway** | HTTP прокси к Lambda | Все методы, CORS |
| **S3** | Хранит фронтенд-файлы | Приватный, доступ через CloudFront |
| **CloudFront** | CDN, HTTPS, маршрутизация | `/` → S3, `/api/*` → API Gateway |

### Команды деплоя

```bash
# 1. Собрать проект
npm run build:cloud-api
npm run build:cloud-web

# 2. Инициализировать CDK (один раз на аккаунт/регион)
cd cloud/infra
npx cdk bootstrap

# 3. Посмотреть, что будет создано
npx cdk diff

# 4. Развернуть
npx cdk deploy
# или из корня:
npm run deploy

# 5. После деплоя — в терминале появятся:
#    SiteUrl = https://d1a2b3c4d5e6f7.cloudfront.net
#    ApiUrl  = https://abc123.execute-api.eu-central-1.amazonaws.com
#    DbEndpoint = wccdb.cluster-xyz.eu-central-1.rds.amazonaws.com
```

### Заполнение базы данных

После первого деплоя RDS пуст. Нужно применить миграции через bastion host или Lambda-миграцию (описано в `docs/CLOUD_FIRST_SERVERLESS_REPORT.md`).

### Удаление всех ресурсов

```bash
cd cloud/infra
npx cdk destroy
```

---

## 7. Рабочий процесс разработки

```
 Ваш компьютер                               AWS
┌───────────────────────────────┐   ┌──────────────────────────┐
│                               │   │                          │
│  npm run dev:cloud            │   │  CloudFront              │
│  ├── cloud/web (Next.js) :3100│   │  ├── S3 (cloud/web/out)  │
│  └── cloud/api (Hono)   :4100│   │  └── Lambda (cloud/api)  │
│       │                       │   │       │                  │
│       ▼                       │   │       ▼                  │
│  PostgreSQL (Docker) :5433    │   │  RDS PostgreSQL          │
│                               │   │                          │
│  npm run dev                  │   │                          │
│  ├── apps/web  :3000          │   │                          │
│  └── apps/api  :4000          │   │                          │
│       │                       │   │                          │
│       ▼                       │   │                          │
│  PostgreSQL (Docker) :5433    │   │                          │
│  (та же БД)                   │   │                          │
└───────────────┬───────────────┘   └──────────────────────────┘
                │                              ▲
                │  git push → CI/CD            │
                └──────────────────────────────┘
```

### Цикл разработки

1. **Пишете код** в `cloud/api/src/` или `cloud/web/app/`
2. **Тестируете** локально: `npm run dev:cloud`
3. **Отлаживаете SQL/бизнес-логику** через legacy: `npm run dev`
4. **Коммитите** в git
5. **Деплоите** через `npm run deploy` (или через CI/CD)

### Когда использовать legacy, когда cloud

| Задача | Используйте |
|--------|------------|
| Добавить новый вопрос в опросник (SQL) | `npm run dev` (legacy) — пройти опросник визуально |
| Добавить новую расу/профессию (SQL + survey data) | `npm run dev` (legacy) |
| Проверить PDF-генерацию | `npm run dev` (legacy) — PDF только там |
| Добавить CRUD для персонажей | `npm run dev:cloud` |
| Настроить Auth | `npm run dev:cloud` |
| Проверить деплой | `npm run deploy` |

---

## 8. Переменные окружения

### `packages/core` (db/pool.ts)

| Переменная | По умолчанию | Описание |
|-----------|-------------|----------|
| `POSTGRES_HOST` | `localhost` | Хост БД |
| `POSTGRES_PORT` | `5433` | Порт БД |
| `POSTGRES_USER` | `cc_user` | Пользователь |
| `POSTGRES_PASSWORD` | `cc_pass` | Пароль |
| `POSTGRES_DB` | `witcher_cc` | Имя БД |
| `POSTGRES_SSL` | (не задан) | `'true'` для SSL |

### `apps/api` (legacy)

| Переменная | По умолчанию | Описание |
|-----------|-------------|----------|
| `PORT` | `4000` | Порт API |

### `cloud/api`

| Переменная | По умолчанию | Описание |
|-----------|-------------|----------|
| `PORT` | `4100` | Порт API (локально) |
| `ALLOWED_ORIGINS` | `http://localhost:3100` | CORS origins (через запятую) |

### `cloud/web`

| Переменная | По умолчанию | Описание |
|-----------|-------------|----------|
| `NEXT_PUBLIC_API_URL` | `/api` | URL API (для продакшена — relative) |

В `.env.local` для локальной разработки задано `http://localhost:4100/api`.

---

## 9. Что дальше

### Ближайшие шаги

1. **CRUD для персонажей** — добавить таблицу `wcc_characters` в `db/sql/`, эндпоинты в `cloud/api/src/app.ts`, страницу списка и редактирования в `cloud/web/`
2. **Google Auth** — добавить Cognito в CDK-стек, middleware JWT-проверки в `cloud/api`, UI логина в `cloud/web`
3. **CI/CD** — GitHub Actions workflow для автоматического деплоя при push

### Позднее

4. **PDF-генерация** — отдельная Lambda с `@sparticuz/chromium` или клиентская генерация через `window.print()`
5. **Удаление legacy** — когда cloud-версия полностью заменит apps/:
   ```bash
   rm -rf apps/
   # Обновить workspaces в корневом package.json
   ```

---

## 10. Справочник команд

| Команда | Что делает |
|---------|-----------|
| `npm run dev` | Запуск legacy (apps/api :4000 + apps/web :3000) |
| `npm run dev:cloud` | Запуск cloud (cloud/api :4100 + cloud/web :3100) |
| `npm run build:cloud-api` | Сборка cloud API (TypeScript → dist/) |
| `npm run build:cloud-web` | Сборка cloud Web (Next.js → out/) |
| `npm run deploy` | Деплой в AWS через CDK |
| `cd db && docker compose up -d` | Запуск PostgreSQL |
| `cd db && bash seed.sh` | Инициализация/обновление БД |
