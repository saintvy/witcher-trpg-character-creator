# Witcher Character Creator — Сценарий «Cloud First, Serverless»

> **Дата:** 19 февраля 2026  
> **Суть:** Сначала переносим то, что есть, в AWS (чисто Lambda). Потом продолжаем разработку в облаке. PDF — потом. Auth — потом. Пока — закрытый сервис без внешнего доступа.

---

## Оглавление

1. [Ключевые решения этого сценария](#1-ключевые-решения-этого-сценария)
2. [Архитектура: ни одного контейнера](#2-архитектура-ни-одного-контейнера)
3. [Фронтенд без контейнера — как и почему](#3-фронтенд-без-контейнера--как-и-почему)
4. [Пошаговый план переезда в AWS](#4-пошаговый-план-переезда-в-aws)
5. [Как открыть проект без публичного домена](#5-как-открыть-проект-без-публичного-домена)
6. [Локальная разработка при Lambda в облаке](#6-локальная-разработка-при-lambda-в-облаке)
7. [Добавление хранения персонажей](#7-добавление-хранения-персонажей)
8. [Добавление Google-аутентификации (позже)](#8-добавление-google-аутентификации-позже)
9. [Добавление PDF-генерации (позже)](#9-добавление-pdf-генерации-позже)
10. [Полная структура файлов проекта после миграции](#10-полная-структура-файлов-проекта-после-миграции)
11. [Ответы на прямые вопросы](#11-ответы-на-прямые-вопросы)

---

## 1. Ключевые решения этого сценария

| Вопрос | Решение | Почему |
|--------|---------|--------|
| Нужен ли контейнер для фронтенда? | **Нет** | Все страницы — `"use client"`, фронтенд собирается в статические файлы → S3 |
| Нужен ли контейнер для API? | **Нет** | Без PDF нет Chromium, Hono имеет Lambda-адаптер → одна Lambda |
| Можно ли открыть проект из AWS? | **Да** | CloudFront выдаёт URL вида `d1234abc.cloudfront.net` |
| Можно ли разрабатывать локально? | **Да** | Тот же код работает и локально, и в Lambda |
| Когда добавлять Auth? | **Потом** | Сначала закрытый сервис, доступ только по URL |
| Когда добавлять PDF? | **Потом** | Добавится как отдельная Lambda с `@sparticuz/chromium` |

---

## 2. Архитектура: ни одного контейнера

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS Cloud                           │
│                                                             │
│  ┌──────────────┐     ┌───────────────┐                     │
│  │  CloudFront   │────▶│  S3 Bucket    │                     │
│  │  (CDN)        │     │  (HTML/JS/CSS)│                     │
│  │               │     │  Фронтенд     │                     │
│  │  d1234.cf.net │     └───────────────┘                     │
│  │               │                                           │
│  │  /api/*       │     ┌───────────────┐     ┌────────────┐ │
│  │  ─────────────│────▶│  API Gateway   │────▶│  Lambda    │ │
│  │               │     │  (HTTP API)    │     │  (Hono)    │ │
│  └──────────────┘     └───────────────┘     └─────┬──────┘ │
│                                                    │        │
│                                              ┌─────▼──────┐ │
│                                              │    RDS      │ │
│                                              │ PostgreSQL  │ │
│                                              └────────────┘ │
│                                                             │
│  Контейнеры: 0                                              │
│  Серверы: 0                                                 │
│  Всё serverless                                             │
└─────────────────────────────────────────────────────────────┘
```

**Что тут что:**

| Компонент | Что делает | Как оплачивается |
|-----------|-----------|-----------------|
| **S3** | Хранит HTML/JS/CSS файлы фронтенда | За хранение (~$0.02/ГБ/мес) |
| **CloudFront** | Раздаёт фронтенд быстро + маршрутизирует `/api/*` запросы | За трафик (1 ТБ бесплатно) |
| **API Gateway** | Принимает API-запросы, передаёт в Lambda | За запрос (~$1 за 1 млн) |
| **Lambda** | Исполняет код API (Hono) | За время выполнения ($0 до 1 млн запросов) |
| **RDS** | База данных PostgreSQL | Фиксированно ~$15/мес (самый маленький) |

**Итого при малой нагрузке: ~$15–18/мес** (почти всё — стоимость RDS).

---

## 3. Фронтенд без контейнера — как и почему

### Почему контейнер не нужен

Ваш фронтенд — это **полностью клиентское приложение**. Каждая страница начинается с `"use client"`:

- `app/page.tsx` — `"use client"`
- `app/builder/page.tsx` — `"use client"`
- `app/characters/page.tsx` — `"use client"`
- `app/sheet/page.tsx` — `"use client"`
- `app/settings/page.tsx` — `"use client"`
- `app/layout.tsx` — `"use client"`

Это значит, что **весь рендеринг происходит в браузере пользователя**, а не на сервере. Серверу нужно лишь отдать HTML/JS/CSS файлы — для этого хватает простого файлового хранилища (S3).

### Аналогия

Представьте, что ваш фронтенд — это книга в PDF. Чтобы её прочитать, не нужен живой автор (сервер). Достаточно положить файл на полку (S3), а CloudFront — это библиотекарь, который быстро выдаёт копию каждому читателю.

### Что нужно изменить

Добавьте в `next.config.mjs` одну строку:

```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  output: 'export',  // ← это превращает Next.js в статический сайт
  // убираем typedRoutes — несовместим с output: 'export'
};
export default nextConfig;
```

**Что делает `output: 'export'`:**
- Команда `npm run build` генерирует папку `out/` с обычными HTML/JS/CSS файлами
- Эти файлы можно загрузить куда угодно: S3, Nginx, GitHub Pages, даже на флешку
- Не нужен Node.js сервер для запуска

**Ограничения `output: 'export'`:**
- Нельзя использовать серверные API-роуты (`app/api/...`) — но вам они и не нужны, у вас отдельный API на Hono
- Нельзя использовать `getServerSideProps` — но вы и не используете (всё `"use client"`)
- Нельзя использовать `next/image` с оптимизацией — можно использовать обычные `<img>` теги

> **Когда понадобится Auth (NextAuth)**, нужно будет либо отказаться от `output: 'export'` и поставить фронтенд в Lambda@Edge, либо (рекомендуется) реализовать Auth на стороне API (Hono), а не через NextAuth. Подробнее — в разделе 8.

### Как это выглядит при сборке

```bash
cd apps/web
npm run build

# Результат:
# apps/web/out/
# ├── index.html          (главная страница)
# ├── builder.html        (создание персонажа)
# ├── characters.html     (список персонажей)
# ├── sheet.html          (лист персонажа)
# ├── settings.html       (настройки)
# ├── _next/
# │   ├── static/         (JS бандлы, CSS)
# │   └── ...
# └── ...
```

Эти файлы загружаются в S3 — и фронтенд работает.

---

## 4. Пошаговый план переезда в AWS

### Шаг 0: Подготовка (на вашем компьютере)

#### 0.1 — Создать AWS-аккаунт

1. Откройте https://aws.amazon.com/ → «Create an AWS Account»
2. Введите email, пароль, данные карты
3. AWS не списывает деньги в рамках Free Tier (первые 12 месяцев)
4. Запомните **Account ID** (12-значный номер, виден в правом верхнем углу консоли)

#### 0.2 — Установить инструменты

```bash
# 1. AWS CLI (управление AWS из терминала)
# Скачайте: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-windows.html
# После установки:
aws configure
# Введите: Access Key ID, Secret Access Key, регион (eu-central-1), формат (json)

# 2. AWS CDK (инфраструктура как код)
npm install -g aws-cdk

# 3. Проверить:
aws --version
cdk --version
```

#### 0.3 — Подготовить фронтенд к статическому экспорту

В файле `apps/web/next.config.mjs`:

```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  output: 'export',
  trailingSlash: true,  // для корректной маршрутизации в S3
};
export default nextConfig;
```

Проверьте локально:

```bash
cd apps/web
npm run build
# Должна появиться папка out/ с HTML-файлами
```

#### 0.4 — Добавить Lambda-адаптер для Hono

Hono имеет **встроенный** адаптер для AWS Lambda. Один и тот же код работает и локально, и в Lambda.

```bash
cd apps/api
npm install @hono/aws-lambda
```

Создайте файл `apps/api/src/lambda.ts` (точка входа для Lambda):

```typescript
import { handle } from '@hono/aws-lambda';
import { app } from './app.js';

export const handler = handle(app);
```

Выделите приложение Hono в отдельный файл `apps/api/src/app.ts`:

```typescript
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { generateCharacter } from './handlers/generateCharacter.js';
import { nextQuestion } from './handlers/nextQuestion.js';
import { getAllShopItemsHandler } from './handlers/getAllShopItems.js';
import { getSkillsCatalogHandler } from './handlers/getSkillsCatalog.js';

const app = new Hono();

const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',')
  : ['http://localhost:3000'];

app.use('*', cors({ origin: allowedOrigins }));

app.post('/generate-character', async (c) => {
  const result = await generateCharacter(c);
  return c.json(result);
});
app.post('/survey/next', nextQuestion);
app.post('/shop/allItems', getAllShopItemsHandler);
app.post('/skills/catalog', getSkillsCatalogHandler);

export { app };
```

Обновите `apps/api/src/server.ts` (для локальной разработки):

```typescript
import 'dotenv/config';
import { serve } from '@hono/node-server';
import { app } from './app.js';
import { db } from './db/pool.js';

const port = Number(process.env.PORT || 4000);
const server = serve({ fetch: app.fetch, port }, () => {
  console.log(`[api] listening on http://localhost:${port}`);
});

// ...graceful shutdown код остаётся как есть...
```

**Что произошло:**
1. `app.ts` — чистое Hono-приложение (маршруты, middleware). Не знает, где запущено.
2. `server.ts` — запускает `app` через Node.js HTTP-сервер (для `npm run dev`)
3. `lambda.ts` — запускает `app` через Lambda-адаптер (для AWS)

**Один код — две точки входа.**

---

### Шаг 1: Создать CDK-проект

```bash
# В корне репозитория
mkdir infra
cd infra
npx cdk init app --language typescript
npm install aws-cdk-lib constructs
```

### Шаг 2: Написать CDK-стек

Создайте `infra/lib/wcc-stack.ts`:

```typescript
import * as cdk from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3deploy from 'aws-cdk-lib/aws-s3-deployment';
import * as cloudfront from 'aws-cdk-lib/aws-cloudfront';
import * as origins from 'aws-cdk-lib/aws-cloudfront-origins';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigw from 'aws-cdk-lib/aws-apigatewayv2';
import * as apigwIntegrations from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as rds from 'aws-cdk-lib/aws-rds';
import { Construct } from 'constructs';
import * as path from 'path';

export class WccStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // ════════════════════════════════════════════════════════
    // 1. СЕТЬ
    // ════════════════════════════════════════════════════════
    // VPC — виртуальная сеть, в которой живёт база данных.
    // Lambda подключается к ней, чтобы общаться с RDS.
    const vpc = new ec2.Vpc(this, 'WccVpc', {
      maxAzs: 2,
      natGateways: 1, // Нужен для Lambda → интернет (если понадобится)
    });

    // ════════════════════════════════════════════════════════
    // 2. БАЗА ДАННЫХ (RDS PostgreSQL)
    // ════════════════════════════════════════════════════════
    const database = new rds.DatabaseInstance(this, 'WccDb', {
      engine: rds.DatabaseInstanceEngine.postgres({
        version: rds.PostgresEngineVersion.VER_16,
      }),
      instanceType: ec2.InstanceType.of(
        ec2.InstanceClass.T4G,
        ec2.InstanceSize.MICRO, // Самый дешёвый (~$15/мес)
      ),
      vpc,
      vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS },
      databaseName: 'witcher_cc',
      credentials: rds.Credentials.fromGeneratedSecret('cc_user'),
      multiAz: false,
      allocatedStorage: 20,
      maxAllocatedStorage: 50,
      removalPolicy: cdk.RemovalPolicy.SNAPSHOT,
    });

    // ════════════════════════════════════════════════════════
    // 3. LAMBDA (API)
    // ════════════════════════════════════════════════════════
    const apiFunction = new lambda.Function(this, 'WccApiFunction', {
      runtime: lambda.Runtime.NODEJS_20_X,
      handler: 'dist/lambda.handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '../../apps/api'), {
        exclude: ['node_modules/.cache', 'src', '*.ts', 'tsconfig.json'],
        // CDK автоматически упакует папку в ZIP
      }),
      memorySize: 256,
      timeout: cdk.Duration.seconds(29),
      vpc,
      vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_WITH_EGRESS },
      environment: {
        POSTGRES_HOST: database.instanceEndpoint.hostname,
        POSTGRES_PORT: '5432',
        POSTGRES_DB: 'witcher_cc',
        POSTGRES_SSL: 'true',
        NODE_OPTIONS: '--enable-source-maps',
      },
    });

    // Передаём пароль БД через Secrets Manager
    if (database.secret) {
      apiFunction.addEnvironment(
        'DB_SECRET_ARN', database.secret.secretArn,
      );
      database.secret.grantRead(apiFunction);
    }

    // Разрешаем Lambda обращаться к БД
    database.connections.allowDefaultPortFrom(apiFunction);

    // ════════════════════════════════════════════════════════
    // 4. API GATEWAY (HTTP API)
    // ════════════════════════════════════════════════════════
    const httpApi = new apigw.HttpApi(this, 'WccHttpApi', {
      apiName: 'wcc-api',
      corsPreflight: {
        allowOrigins: ['*'],  // Потом ограничим до CloudFront URL
        allowMethods: [apigw.CorsHttpMethod.ANY],
        allowHeaders: ['Content-Type', 'Authorization'],
      },
    });

    httpApi.addRoutes({
      path: '/{proxy+}',
      methods: [apigw.HttpMethod.ANY],
      integration: new apigwIntegrations.HttpLambdaIntegration(
        'ApiIntegration', apiFunction,
      ),
    });

    // ════════════════════════════════════════════════════════
    // 5. S3 (фронтенд)
    // ════════════════════════════════════════════════════════
    const siteBucket = new s3.Bucket(this, 'WccSiteBucket', {
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      autoDeleteObjects: true,
    });

    // Загружаем собранный фронтенд в S3
    new s3deploy.BucketDeployment(this, 'DeploySite', {
      sources: [s3deploy.Source.asset(
        path.join(__dirname, '../../apps/web/out'),
      )],
      destinationBucket: siteBucket,
    });

    // ════════════════════════════════════════════════════════
    // 6. CLOUDFRONT (точка входа)
    // ════════════════════════════════════════════════════════
    const distribution = new cloudfront.Distribution(this, 'WccCdn', {
      defaultBehavior: {
        origin:
          origins.S3BucketOrigin.withOriginAccessControl(siteBucket),
        viewerProtocolPolicy:
          cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
      },
      additionalBehaviors: {
        '/api/*': {
          origin: new origins.HttpOrigin(
            `${httpApi.httpApiId}.execute-api.${this.region}.amazonaws.com`,
          ),
          allowedMethods: cloudfront.AllowedMethods.ALLOW_ALL,
          viewerProtocolPolicy:
            cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
          cachePolicy: cloudfront.CachePolicy.CACHING_DISABLED,
          originRequestPolicy:
            cloudfront.OriginRequestPolicy.ALL_VIEWER_EXCEPT_HOST_HEADER,
        },
      },
      defaultRootObject: 'index.html',
      errorResponses: [
        {
          httpStatus: 403,
          responsePagePath: '/index.html',
          responseHttpStatus: 200,
        },
        {
          httpStatus: 404,
          responsePagePath: '/index.html',
          responseHttpStatus: 200,
        },
      ],
    });

    // ════════════════════════════════════════════════════════
    // ВЫВОДЫ (показываются после cdk deploy)
    // ════════════════════════════════════════════════════════
    new cdk.CfnOutput(this, 'SiteUrl', {
      value: `https://${distribution.distributionDomainName}`,
      description: 'Откройте этот URL в браузере',
    });
    new cdk.CfnOutput(this, 'ApiUrl', {
      value: httpApi.apiEndpoint,
      description: 'Прямой URL к API (для отладки)',
    });
    new cdk.CfnOutput(this, 'DbEndpoint', {
      value: database.instanceEndpoint.hostname,
      description: 'Адрес базы данных (внутренний)',
    });
  }
}
```

Обновите `infra/bin/infra.ts`:

```typescript
#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { WccStack } from '../lib/wcc-stack';

const app = new cdk.App();
new WccStack(app, 'WccStack', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION ?? 'eu-central-1',
  },
});
```

### Шаг 3: Подготовить фронтенд к работе с API через CloudFront

Сейчас фронтенд обращается к `http://localhost:4000`. В AWS он будет обращаться к тому же домену, но по пути `/api/`.

Измените `apps/web/app/layout.tsx` (и все файлы, где используется `API_URL`):

```typescript
// Было:
const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:4000";
// fetch(`${API_URL}/survey/next`, ...)

// Стало:
const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "/api";
// fetch(`${API_URL}/survey/next`, ...)
// В продакшене запрос пойдёт на /api/survey/next → CloudFront → API Gateway → Lambda
// Локально: задаёте NEXT_PUBLIC_API_URL=http://localhost:4000 в .env.local
```

Создайте `apps/web/.env.local` (для локальной разработки):

```env
NEXT_PUBLIC_API_URL=http://localhost:4000
```

А в Hono добавьте базовый путь `/api`:

```typescript
// apps/api/src/app.ts
import { Hono } from 'hono';

const app = new Hono().basePath('/api');  // ← все роуты будут /api/...

app.post('/generate-character', ...);  // → /api/generate-character
app.post('/survey/next', ...);         // → /api/survey/next
// ...
```

Для локальной разработки `basePath` тоже будет `/api`, поэтому локально фронтенд обращается к `http://localhost:4000/api/survey/next`.

### Шаг 4: Собрать и задеплоить

```bash
# 1. Собрать API
cd apps/api
npm run build              # TypeScript → dist/

# 2. Собрать фронтенд
cd ../web
npm run build              # Next.js → out/

# 3. Инициализировать CDK (один раз)
cd ../../infra
npx cdk bootstrap

# 4. Деплой!
npx cdk deploy
```

**Что произойдёт:**
1. CDK создаст VPC, RDS, Lambda, API Gateway, S3, CloudFront (~5–10 мин)
2. Скомпилированный API загрузится в Lambda
3. Статический фронтенд загрузится в S3
4. В терминале появится URL:
   ```
   Outputs:
   WccStack.SiteUrl = https://d1a2b3c4d5e6f7.cloudfront.net
   WccStack.ApiUrl = https://abc123.execute-api.eu-central-1.amazonaws.com
   WccStack.DbEndpoint = wccdb.cluster-xyz.eu-central-1.rds.amazonaws.com
   ```

### Шаг 5: Заполнить базу данных

После деплоя база пустая. Нужно применить миграции.

**Вариант A: Через Bastion Host (безопасно)**

CDK не создаёт прямой доступ к RDS из интернета (это правильно). Чтобы подключиться:

```bash
# Добавьте в CDK-стек временный Bastion Host:
const bastion = new ec2.BastionHostLinux(this, 'Bastion', {
  vpc,
  instanceType: ec2.InstanceType.of(ec2.InstanceClass.T4G, ec2.InstanceSize.NANO),
});
database.connections.allowDefaultPortFrom(bastion);

# После деплоя подключитесь через SSM Session Manager:
aws ssm start-session --target i-0123456789abcdef0

# Внутри bastion:
psql -h wccdb.xyz.rds.amazonaws.com -U cc_user -d witcher_cc < wcc_sql_deploy.sql
```

**Вариант B: Lambda-миграция (автоматически)**

Создайте отдельную Lambda, которая при деплое запускает SQL-миграции. Это лучший подход для CI/CD, но сложнее настроить с первого раза.

---

## 5. Как открыть проект без публичного домена

### Можно ли открыть проект из AWS консоли?

**Не совсем «из консоли»**, но вот что доступно:

CloudFront выдаёт URL вида:
```
https://d1a2b3c4d5e6f7.cloudfront.net
```

Этот URL **работает сразу** после деплоя. Вы открываете его в обычном браузере — и видите свой сайт. Никакого домена покупать не нужно.

### Кто может открыть этот URL?

По умолчанию — **любой, кто знает URL**. Но URL длинный и случайный, поэтому его практически невозможно угадать.

Если нужна дополнительная защита до добавления Auth:

**Вариант 1: CloudFront + WAF (простой пароль)**

Добавьте AWS WAF правило, которое проверяет секретный заголовок:

```typescript
// В CDK-стеке:
// Это потребует CloudFront Function, которая проверяет, например,
// query-параметр ?key=ваш_секрет
```

**Вариант 2: CloudFront Function (проверка токена в URL)**

```typescript
// CloudFront Function (простейшая «авторизация»):
function handler(event) {
  var request = event.request;
  var params = request.querystring;
  if (!params.key || params.key.value !== 'мой-секретный-ключ-123') {
    return {
      statusCode: 403,
      body: { encoding: 'text', data: 'Forbidden' },
    };
  }
  return request;
}
// URL: https://d1a2b3c4d5e6f7.cloudfront.net?key=мой-секретный-ключ-123
```

**Вариант 3: Просто не публикуйте URL**

Пока Auth не добавлен, URL знаете только вы. Этого достаточно для тестирования.

### Что можно увидеть в AWS Console

В веб-консоли AWS (https://console.aws.amazon.com/) вы можете:
- **CloudWatch Logs** — логи Lambda (что выводит `console.log`)
- **Lambda → Monitor** — графики вызовов, ошибок, длительности
- **RDS → Performance Insights** — нагрузка на базу данных
- **S3** — файлы фронтенда
- **CloudFront** — статистика запросов, кэширование

Но **открыть сам сайт** нужно через CloudFront URL в обычном браузере.

---

## 6. Локальная разработка при Lambda в облаке

### Главный принцип: один код — два режима

```
┌──────────────────────────────────────────────────────────┐
│                     apps/api/src/                         │
│                                                          │
│                    ┌───────────┐                          │
│                    │  app.ts   │ ← Маршруты, логика       │
│                    │  (Hono)   │    Не знает, где запущен │
│                    └─────┬─────┘                          │
│                    ┌─────┴─────┐                          │
│              ┌─────▼───┐ ┌─────▼──────┐                   │
│              │server.ts│ │ lambda.ts   │                   │
│              │(Node.js)│ │(AWS Lambda) │                   │
│              └─────────┘ └────────────┘                   │
│              Локально      В облаке                       │
│              npm run dev   cdk deploy                     │
└──────────────────────────────────────────────────────────┘
```

**Вы НЕ запускаете Lambda локально.** Вы запускаете тот же `app.ts` через обычный Node.js сервер (`server.ts`). Код бизнес-логики — идентичен.

### Рабочий процесс разработки

```
Ваш компьютер (localhost)               AWS Cloud (продакшен)
┌─────────────────────────┐             ┌────────────────────────┐
│                         │             │                        │
│  npm run dev            │   git push  │  CloudFront            │
│  ├── Next.js :3000      │ ──────────▶ │  ├── S3 (фронтенд)    │
│  └── Hono    :4000      │   + CI/CD   │  └── Lambda (API)      │
│       │                 │             │       │                │
│       ▼                 │             │       ▼                │
│  PostgreSQL :5433       │             │  RDS PostgreSQL        │
│  (Docker)               │             │                        │
└─────────────────────────┘             └────────────────────────┘
```

**Что меняется при разработке? Ничего.**

| Действие | Локально | AWS |
|----------|---------|-----|
| Запуск API | `npm run dev:api` | Lambda (автоматически) |
| Запуск фронтенда | `npm run dev:web` | S3 + CloudFront |
| База данных | Docker PostgreSQL :5433 | RDS PostgreSQL |
| URL фронтенда | `http://localhost:3000` | `https://d1234.cloudfront.net` |
| URL API | `http://localhost:4000/api` | `https://d1234.cloudfront.net/api` |

### Можно ли тестировать Lambda локально?

**Да**, но это обычно не нужно. Если хотите:

**AWS SAM** (Serverless Application Model) может эмулировать Lambda + API Gateway:

```bash
# Установить SAM CLI:
# https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html

# Запустить API локально через эмуляцию Lambda:
sam local start-api
```

Но это медленнее, чем просто `npm run dev`. Рекомендация: **используйте SAM только если нужно отладить Lambda-специфичные вещи** (IAM, VPC, Secrets Manager). Для обычной разработки — `npm run dev`.

### Файлы окружения

**`apps/web/.env.local`** (локальная разработка):

```env
NEXT_PUBLIC_API_URL=http://localhost:4000/api
```

**`apps/api/.env`** (локальная разработка):

```env
POSTGRES_HOST=localhost
POSTGRES_PORT=5433
POSTGRES_USER=cc_user
POSTGRES_PASSWORD=cc_pass
POSTGRES_DB=witcher_cc
```

В AWS переменные задаются через CDK (в Lambda environment) — файлы `.env` не нужны.

---

## 7. Добавление хранения персонажей

### Новые таблицы в БД

Добавьте миграцию `db/sql/100_characters_storage.sql`:

```sql
-- Таблица пользователей (пока без Auth, просто идентификатор)
CREATE TABLE IF NOT EXISTS wcc_users (
    user_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    external_id TEXT UNIQUE,           -- Google sub ID (заполнится при добавлении Auth)
    display_name TEXT NOT NULL DEFAULT 'Anonymous',
    email       TEXT,
    avatar_url  TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Таблица сохранённых персонажей
CREATE TABLE IF NOT EXISTS wcc_characters (
    character_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES wcc_users(user_id) ON DELETE CASCADE,
    name         TEXT NOT NULL DEFAULT 'Unnamed',
    race         TEXT,
    profession   TEXT,
    land         TEXT,
    character_json JSONB NOT NULL,     -- Полный JSON персонажа (тот же, что возвращает /generate-character)
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_characters_user ON wcc_characters(user_id);
```

**Почему `character_json JSONB`?**
Структура персонажа сложная и может меняться. Хранить её как JSON в PostgreSQL — самый гибкий подход. JSONB позволяет индексировать и фильтровать по полям внутри JSON.

### Новые API-эндпоинты

Добавьте в `apps/api/src/app.ts`:

```typescript
import { listCharacters } from './handlers/listCharacters.js';
import { getCharacter } from './handlers/getCharacter.js';
import { saveCharacter } from './handlers/saveCharacter.js';
import { updateCharacter } from './handlers/updateCharacter.js';
import { deleteCharacter } from './handlers/deleteCharacter.js';

// CRUD для персонажей
app.get('/characters',        listCharacters);    // Список персонажей пользователя
app.get('/characters/:id',    getCharacter);       // Один персонаж по ID
app.post('/characters',       saveCharacter);      // Сохранить нового
app.put('/characters/:id',    updateCharacter);    // Обновить существующего
app.delete('/characters/:id', deleteCharacter);    // Удалить
```

Пример хэндлера `apps/api/src/handlers/saveCharacter.ts`:

```typescript
import type { Context } from 'hono';
import { db } from '../db/pool.js';

export async function saveCharacter(c: Context) {
  const body = await c.req.json();
  const { userId, characterJson } = body;

  if (!userId || !characterJson) {
    return c.json({ error: 'userId and characterJson are required' }, 400);
  }

  const name = characterJson.base?.name ?? 'Unnamed';
  const race = characterJson.base?.race ?? null;
  const profession = characterJson.base?.profession ?? null;
  const land = characterJson.base?.homeland ?? null;

  const { rows } = await db.query(
    `INSERT INTO wcc_characters (user_id, name, race, profession, land, character_json)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING character_id, created_at`,
    [userId, name, race, profession, land, JSON.stringify(characterJson)],
  );

  return c.json({ characterId: rows[0].character_id, createdAt: rows[0].created_at });
}
```

Пример `apps/api/src/handlers/listCharacters.ts`:

```typescript
import type { Context } from 'hono';
import { db } from '../db/pool.js';

export async function listCharacters(c: Context) {
  const userId = c.req.query('userId');
  if (!userId) return c.json({ error: 'userId query param required' }, 400);

  const { rows } = await db.query(
    `SELECT character_id, name, race, profession, land, created_at, updated_at
     FROM wcc_characters
     WHERE user_id = $1
     ORDER BY updated_at DESC`,
    [userId],
  );

  return c.json({ characters: rows });
}
```

### Фронтенд: списки и редактирование

Страница `/characters` уже имеет UI-заглушку с таблицей. Нужно заменить моковые данные на реальные:

```typescript
// apps/web/app/characters/page.tsx
// Вместо хардкода t.characters:

const [characters, setCharacters] = useState([]);

useEffect(() => {
  fetch(`${API_URL}/characters?userId=${currentUserId}`)
    .then(r => r.json())
    .then(data => setCharacters(data.characters));
}, []);
```

Для страницы редактирования создайте `apps/web/app/characters/[id]/page.tsx`:

```typescript
'use client';
import { useParams } from 'next/navigation';
import { useEffect, useState } from 'react';

export default function CharacterEditPage() {
  const { id } = useParams();
  const [character, setCharacter] = useState(null);

  useEffect(() => {
    fetch(`${API_URL}/characters/${id}`)
      .then(r => r.json())
      .then(setCharacter);
  }, [id]);

  // Режим просмотра/редактирования полей персонажа
  // ...
}
```

> **Без Auth (пока):** используйте фиксированный `userId` (например, захардкоженный UUID). Когда добавите Google Auth — замените на реальный ID пользователя.

---

## 8. Добавление Google-аутентификации (позже)

Поскольку фронтенд — статический (S3), использовать NextAuth нельзя (он требует сервера). Есть два подхода:

### Подход A: AWS Cognito Hosted UI (рекомендуется для serverless)

```
Пользователь
    │
    ├── Нажимает «Войти через Google»
    │
    ├── Перенаправляется на Cognito Hosted UI
    │   (страница авторизации, которую AWS создаёт за вас)
    │
    ├── Cognito → Google OAuth → Cognito
    │
    ├── Cognito возвращает JWT-токены в браузер
    │
    └── Браузер отправляет JWT при каждом запросе к API
        (заголовок Authorization: Bearer ...)
```

**На фронтенде:**
- Используйте `amazon-cognito-identity-js` или `@aws-amplify/auth`
- Токены хранятся в `localStorage`
- При каждом `fetch()` к API добавляйте заголовок `Authorization`

**На API (Lambda):**
- Можно проверять JWT прямо в API Gateway (встроенный Cognito Authorizer — бесплатно, без кода)
- Или проверять в Hono middleware

**Добавление в CDK:**

```typescript
import * as cognito from 'aws-cdk-lib/aws-cognito';

const userPool = new cognito.UserPool(this, 'WccUserPool', {
  selfSignUpEnabled: false,  // Только вход через Google
  signInAliases: { email: true },
});

new cognito.UserPoolIdentityProviderGoogle(this, 'Google', {
  userPool,
  clientId: 'GOOGLE_CLIENT_ID',
  clientSecretValue: cdk.SecretValue.unsafePlainText('GOOGLE_SECRET'),
  scopes: ['email', 'profile'],
  attributeMapping: {
    email: cognito.ProviderAttribute.GOOGLE_EMAIL,
    fullname: cognito.ProviderAttribute.GOOGLE_NAME,
  },
});

const client = userPool.addClient('WebClient', {
  oAuth: {
    flows: { authorizationCodeGrant: true },
    callbackUrls: [
      'http://localhost:3000/',    // Локальная разработка
      `https://${distribution.distributionDomainName}/`,
    ],
  },
  supportedIdentityProviders: [
    cognito.UserPoolClientIdentityProvider.GOOGLE,
  ],
});

userPool.addDomain('CognitoDomain', {
  cognitoDomain: { domainPrefix: 'witcher-cc' },
});
// URL входа: https://witcher-cc.auth.eu-central-1.amazoncognito.com/login
```

### Подход B: Auth на Hono (API-side)

Реализовать OAuth2 flow прямо в API:

```
/api/auth/login     → Перенаправляет на Google
/api/auth/callback  → Google возвращает code → обмен на токен → создание сессии
/api/auth/me        → Текущий пользователь
/api/auth/logout    → Удаление сессии
```

Это даёт полный контроль, но больше кода. Рекомендуется если вы не хотите зависеть от Cognito.

---

## 9. Добавление PDF-генерации (позже)

Когда понадобится PDF, добавьте **отдельную Lambda**:

```typescript
// В CDK:
const pdfFunction = new lambda.Function(this, 'WccPdfFunction', {
  runtime: lambda.Runtime.NODEJS_20_X,
  handler: 'dist/pdfLambda.handler',
  code: lambda.Code.fromAsset(path.join(__dirname, '../../apps/api')),
  memorySize: 2048,  // Chromium нужна память
  timeout: cdk.Duration.seconds(29),
  layers: [
    // @sparticuz/chromium как Lambda Layer
    lambda.LayerVersion.fromLayerVersionArn(this, 'ChromiumLayer',
      'arn:aws:lambda:eu-central-1:764866452798:layer:chrome-aws-lambda:45'
    ),
  ],
  vpc,
  environment: { /* ...DB creds... */ },
});

httpApi.addRoutes({
  path: '/api/character/pdf',
  methods: [apigw.HttpMethod.POST],
  integration: new apigwIntegrations.HttpLambdaIntegration(
    'PdfIntegration', pdfFunction,
  ),
});
```

Или используйте клиентскую генерацию (API возвращает HTML, браузер печатает в PDF) — тогда дополнительная Lambda не нужна.

---

## 10. Полная структура файлов проекта после миграции

```
wcc/
├── apps/
│   ├── api/
│   │   ├── src/
│   │   │   ├── app.ts              ← НОВЫЙ: Hono-приложение (маршруты)
│   │   │   ├── lambda.ts           ← НОВЫЙ: точка входа для Lambda
│   │   │   ├── server.ts           ← ИЗМЕНЁН: использует app.ts
│   │   │   ├── handlers/
│   │   │   │   ├── generateCharacter.ts
│   │   │   │   ├── nextQuestion.ts
│   │   │   │   ├── getAllShopItems.ts
│   │   │   │   ├── getSkillsCatalog.ts
│   │   │   │   ├── saveCharacter.ts     ← НОВЫЙ
│   │   │   │   ├── listCharacters.ts    ← НОВЫЙ
│   │   │   │   ├── getCharacter.ts      ← НОВЫЙ
│   │   │   │   ├── updateCharacter.ts   ← НОВЫЙ
│   │   │   │   └── deleteCharacter.ts   ← НОВЫЙ
│   │   │   ├── services/
│   │   │   ├── db/
│   │   │   └── pdf/                     (пока не трогаем)
│   │   └── package.json
│   └── web/
│       ├── app/
│       │   ├── characters/
│       │   │   ├── page.tsx             ← ИЗМЕНЁН: реальные данные
│       │   │   └── [id]/
│       │   │       └── page.tsx         ← НОВЫЙ: редактирование
│       │   └── ...
│       ├── next.config.mjs              ← ИЗМЕНЁН: output: 'export'
│       ├── .env.local                   ← НОВЫЙ: NEXT_PUBLIC_API_URL
│       └── package.json
├── db/
│   ├── sql/
│   │   ├── ...существующие миграции...
│   │   └── 100_characters_storage.sql   ← НОВЫЙ
│   └── docker-compose.yml
├── infra/                               ← НОВЫЙ: CDK-проект
│   ├── bin/infra.ts
│   ├── lib/wcc-stack.ts
│   ├── cdk.json
│   └── package.json
├── .github/
│   └── workflows/
│       └── deploy.yml                   ← НОВЫЙ: CI/CD
└── package.json
```

---

## 11. Ответы на прямые вопросы

### «Нужен ли отдельный контейнер для фронтенда?»

**Нет.** Ваш фронтенд — полностью клиентский (`"use client"` на всех страницах). Он собирается в обычные HTML/JS/CSS файлы командой `next build` с `output: 'export'`. Эти файлы загружаются в S3, а CloudFront раздаёт их по HTTPS. Контейнеры, серверы, Lambda — ничего из этого не нужно для фронтенда.

### «Можно ли генерацию страниц тоже делать serverless?»

Страницы **не генерируются** на сервере — они генерируются в браузере пользователя (все `"use client"`). Сервер лишь отдаёт файлы. Поэтому вопрос «serverless или нет» к фронтенду не применим — S3 уже «serverless» по определению.

Если бы у вас были серверные страницы (SSR), то да, нужен был бы сервер (или Lambda@Edge). Но у вас его нет.

### «Можно ли открыть проект из AWS консоли?»

CloudFront автоматически выдаёт URL вида `https://d1a2b3c4d5e6f7.cloudfront.net`. Вы открываете его в обычном браузере. Не нужно покупать домен, не нужно настраивать DNS. URL работает сразу после `cdk deploy`.

В самой AWS Console вы **не увидите** сайт визуально, но увидите:
- Логи Lambda (CloudWatch)
- Статистику запросов (CloudFront, API Gateway)
- Файлы фронтенда (S3)
- Состояние базы данных (RDS)

### «Как продолжается разработка?»

**Точно так же, как сейчас.** Вы запускаете `npm run dev` — Next.js стартует на :3000, Hono на :4000, PostgreSQL в Docker на :5433. Пишете код, тестируете локально. Когда готово — `git push` запускает CI/CD, который:
1. Собирает API (`tsc`)
2. Собирает фронтенд (`next build`)
3. Запускает `cdk deploy`
4. Обновляет Lambda и S3

Локальная среда **не зависит** от AWS. Если AWS упадёт — вы продолжите разрабатывать. Если у вас нет интернета — `npm run dev` работает.

### «Тестовая среда может размещаться локально, когда функции лежат в Lambda?»

**Да.** Код API — это обычный TypeScript-файл `app.ts`. Он не знает, запущен он в Lambda или в Node.js. Вы тестируете `app.ts` через `server.ts` (Node.js) локально. В AWS тот же `app.ts` запускается через `lambda.ts` (Lambda-адаптер). Бизнес-логика идентична.

Единственное, что нельзя протестировать локально без дополнительных инструментов:
- IAM-права Lambda
- Secrets Manager (можно заменить на `.env` локально)
- VPC-подключение к RDS (локально используете Docker PostgreSQL)

Для этих случаев существует **AWS SAM** (`sam local start-api`), но для 95% разработки `npm run dev` достаточно.

---

> **Порядок действий (резюме):**
>
> 1. Разделить `server.ts` на `app.ts` + `server.ts` + `lambda.ts` (~30 мин)
> 2. Добавить `output: 'export'` в Next.js config (~5 мин)
> 3. Создать CDK-стек (~2 часа с изучением)
> 4. `cdk deploy` — проект в облаке (~10 мин)
> 5. Применить миграции к RDS (~30 мин)
> 6. Добавить хранение персонажей (новые эндпоинты + таблицы) (~1-2 дня)
> 7. Позже: Google Auth через Cognito
> 8. Позже: PDF через `@sparticuz/chromium` или клиентскую генерацию
