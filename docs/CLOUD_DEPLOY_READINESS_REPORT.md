# Отчет о готовности к деплою в облако (WCC)

Дата проверки: 2026-02-24

## Краткий вывод

Текущий проект **готов к техническому тестовому деплою (staging/smoke)** после выполнения нескольких обязательных шагов конфигурации.

Для **публичного прод-деплоя** в текущем виде есть блокеры/риски:

- JWT authorizer в API Gateway **не включен по умолчанию** (в синтезированном шаблоне `AuthorizationType: NONE`)
- фронтенд-артефакт `cloud/web/out` сейчас собран с локальным `API_URL=http://localhost:4100/api`
- в UI есть вызов `/api/character/pdf`, но такой маршрут отсутствует в `cloud/api`

## Что проверено (факт)

### Сборка кода

- `@wcc/core` build: ✅
- `@wcc/cloud-api` build: ✅
- `@wcc/cloud-web` build: ✅
- `@wcc/infra` build: ✅
- `@wcc/infra` synth: ✅

### Проверка шаблона CloudFormation (после `cdk synth`)

Подтверждено:

- `NAT` отсутствует (`natGateways: 0`) — cost-optimized
- RDS пароль не попадает в шаблон в plaintext (используется dynamic reference Secrets Manager)
- у Lambda нет `POSTGRES_PASSWORD` в `Environment`
- throttling API Gateway включен (`20/40`)

Обнаружено:

- маршрут API в шаблоне сейчас имеет `AuthorizationType: NONE` (JWT authorizer не активирован в текущем synth)

## Оценка готовности по направлениям

### 1. Код и сборка: Частично готово (с функциональным замечанием)

Что хорошо:

- Backend и infra собираются (`cloud/api`, `cloud/infra`)
- Frontend собирается и экспортируется как static (`cloud/web/next.config.mjs:5`)
- Lambda bundling через `NodejsFunction` настроен (`cloud/infra/lib/wcc-stack.ts:153`)
- Загрузка пароля БД в runtime из Secrets Manager реализована (`cloud/api/src/lambda.ts:15`, `cloud/api/src/lambda.ts:44`)

Замечание (функциональный блокер для части UI):

- Frontend вызывает `/character/pdf` (`cloud/web/app/builder/page.tsx:1330`)
- В `cloud/api/src/app.ts` такого маршрута нет (есть только `/generate-character`, `/survey/next`, `/shop/allItems`, `/skills/catalog`, `/health`) (`cloud/api/src/app.ts:27`, `cloud/api/src/app.ts:37`, `cloud/api/src/app.ts:48`, `cloud/api/src/app.ts:59`, `cloud/api/src/app.ts:70`)

Вывод:

- Если PDF-экспорт нужен в облаке на первом этапе, деплой **неполностью готов**.
- Если PDF-экспорт можно временно отключить, остальная функциональность ближе к готовой.

### 2. Секреты и чувствительные данные: В целом хорошо, но cloud auth требует доп. настройки

Что хорошо:

- RDS master password генерируется CDK через Secrets Manager (`cloud/infra/lib/wcc-stack.ts:136`)
- Lambda читает пароль из Secrets Manager по `DB_SECRET_ARN`, а не из env (`cloud/api/src/lambda.ts:15`, `cloud/api/src/lambda.ts:20`)
- В шаблоне нет `POSTGRES_PASSWORD` (проверено)
- Локальные env-файлы игнорируются git (`.gitignore:11`, `.gitignore:12`)

Проверка на утечку секретов в репозитории:

- Поиск по репозиторию не выявил реальных секретов в tracked-коде (найден только текстовый placeholder `client_secret` в документации)

Что НЕ добавлено (и это ожидаемо):

- `Google client_secret` для Cognito federation не хранится в проекте (его нужно добавить в AWS Cognito вручную, если будете включать Google как внешний IdP)
- `WCC_COGNITO_JWT_ISSUER` и `WCC_COGNITO_JWT_AUDIENCE` не заданы автоматически — это env конфигурация для `cdk synth/deploy`, а не секреты в репозитории (`cloud/infra/.env.example:6`, `cloud/infra/.env.example:9`)

Вывод:

- С точки зрения хранения секретов проект сделан корректно.
- С точки зрения готовности cloud auth конфигурации: **нужны обязательные deploy-time env настройки**.

### 3. Авторизация (Google / Cognito / защита страниц и API): Реализовано, но в облаке по умолчанию не активировано

Что реализовано в коде:

- Frontend auth provider + route guard (`cloud/web/app/auth-context.tsx:179`, `cloud/web/app/auth-context.tsx:481`)
- Защита всех страниц кроме `/` через `AuthRouteGate` (`cloud/web/app/layout.tsx:204`, `cloud/web/app/layout.tsx:209`)
- Автоматическая передача `Authorization` в API (`cloud/web/app/api-fetch.ts:9`)
- Backend middleware auth (`cloud/api/src/auth.ts:92`, `cloud/api/src/app.ts:25`)
- Режимы `google-jwt` / `trust-apigw` (`cloud/api/src/auth.ts:4`)
- `health` защищен по умолчанию (`cloud/api/src/auth.ts:22`)

Что важно для облака:

- JWT authorizer в API Gateway включается **только если** заданы `WCC_COGNITO_JWT_ISSUER` + `WCC_COGNITO_JWT_AUDIENCE` (`cloud/infra/lib/wcc-stack.ts:21`, `cloud/infra/lib/wcc-stack.ts:22`, `cloud/infra/lib/wcc-stack.ts:230`)
- В текущем `cdk.out` маршрут API без authorizer (`cloud/infra/cdk.out/WccStack.template.json:727`)

Вывод:

- Кодовая поддержка авторизации готова.
- Конкретный облачный деплой **не будет защищен Cognito**, пока не переданы env для CDK на этапе synth/deploy.

### 4. Архитектура CDK (необходимость / избыточность): В целом адекватна и не излишняя для MVP

Что выглядит оправданно:

- VPC без NAT + VPCE для Secrets Manager (`cloud/infra/lib/wcc-stack.ts:35`, `cloud/infra/lib/wcc-stack.ts:108`)
- Isolated subnets для Lambda/RDS (`cloud/infra/lib/wcc-stack.ts:39`, `cloud/infra/lib/wcc-stack.ts:132`)
- Ограниченный outbound у Lambda/RDS SG (`cloud/infra/lib/wcc-stack.ts:51`, `cloud/infra/lib/wcc-stack.ts:58`)
- S3 + CloudFront + API Gateway + Lambda + RDS — типовая и понятная связка для web app

Где архитектура сейчас скорее минимальная (а не избыточная):

- Нет WAF (осознанно, ради экономии)
- Нет Cognito ресурсов в CDK (пока только интеграционная поддержка через env)
- Нет CloudWatch alarms/Budgets в стеке
- Нет `reserved concurrency` у Lambda
- Нет RDS Proxy

Где есть упрощения/риски для прод:

- CORS в API Gateway открыт на `*` (`cloud/infra/lib/wcc-stack.ts:210`)
- API Gateway публичный `execute-api` endpoint остается доступным напрямую
- `autoDeleteObjects` + `Bucket DESTROY` подходят для dev/staging, но опасны для prod (`cloud/infra/lib/wcc-stack.ts:257`, `cloud/infra/lib/wcc-stack.ts:258`)
- RDS `db.t4g.micro`, Single-AZ — экономично, но хрупко под нагрузкой

Вывод:

- Для cost-optimized MVP архитектура **не избыточна**.
- Для прод-нормы ей не хватает нескольких защитных/операционных элементов.

### 5. Готовность статического фронтенда к облаку: Есть критичный pre-deploy шаг

Критично:

- `cloud/web/out` сейчас содержит локальный URL `http://localhost:4100/api` (проверено по собранным файлам)
- CDK загружает в S3 именно `cloud/web/out` (`cloud/infra/lib/wcc-stack.ts:264`)

Последствие:

- Если задеплоить стек прямо сейчас с текущим `out`, фронтенд в облаке будет ходить на локальный backend URL и не заработает корректно

Что нужно:

- пересобрать `cloud/web` для облака с `NEXT_PUBLIC_API_URL=/api` (или убрать локальный override перед prod build)

## Обязательные шаги перед первым облачным деплоем (минимум)

1. Подготовить/создать Cognito User Pool + App Client + Hosted UI (вне текущего CDK стека).
2. Задать env для CDK перед `synth/deploy`:
   - `WCC_COGNITO_JWT_ISSUER`
   - `WCC_COGNITO_JWT_AUDIENCE`
3. Пересобрать frontend для облака так, чтобы `NEXT_PUBLIC_API_URL=/api` (и `NEXT_PUBLIC_AUTH_PROVIDER=cognito` при cloud-режиме).
4. Убедиться, что в `cloud/web/out` больше нет `http://localhost:4100/api`.
5. Решить судьбу `/character/pdf`:
   - реализовать endpoint в `cloud/api`, или
   - скрыть/отключить кнопку/функцию в UI до реализации.

## Рекомендуемые шаги (не блокеры, но сильно желательны)

1. Ограничить `API Gateway CORS allowOrigins` до CloudFront domain вместо `*`.
2. Добавить `Lambda reserved concurrency` как бюджетный предохранитель.
3. Добавить CloudWatch alarms / AWS Budgets.
4. Для прод-режима изменить политики удаления S3 bucket (`DESTROY`/`autoDeleteObjects`) на безопасные.
5. Рассмотреть WAF позже (после базовой стабилизации и оценки трафика).

## Итоговый статус готовности

- **Тестовый деплой в облако (staging/smoke): Условно готов**
  - при выполнении обязательных шагов выше

- **Публичный прод-деплой: Пока не готов**
  - из-за отсутствия активированного JWT authorizer в текущем synth
  - из-за неверного `API_URL` в текущем `cloud/web/out`
  - из-за несоответствия `UI -> API` по `/character/pdf`

## Примечание по кодировке

Отчет сохранен в UTF-8.
