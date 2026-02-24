# Cloud Infra (AWS Web App): рефакторинг под VPC Endpoints вместо NAT

## Краткий итог

В `cloud/infra` выполнен рефакторинг сетевой части стека для снижения постоянных затрат:

- `NAT Gateway` удален (`natGateways: 0`)
- `Lambda` и `RDS` переведены в `PRIVATE_ISOLATED` подсети
- добавлен `Interface VPC Endpoint` для `Secrets Manager`
- доступы ужаты через отдельные `Security Group` (Lambda -> RDS:5432, Lambda -> VPCE:443)
- outbound для `Lambda SG` ограничен (только `DB`, `VPCE`, `DNS` внутри VPC)
- outbound для `RDS SG` отключен по умолчанию
- пароль БД не передается в `Lambda environment`, а читается из `Secrets Manager` в runtime
- `Lambda` переведена на bundling (`NodejsFunction`) с включением логики `@wcc/core` в deploy-артефакт

Это соответствует сценарию, где API Lambda не требует выхода в интернет и работает только с:

- `RDS PostgreSQL`
- `Secrets Manager` (чтение секрета с паролем БД)

## Что именно изменено в коде (`cloud/infra`)

Файл: `cloud/infra/lib/wcc-stack.ts`

- VPC: `natGateways: 1` -> `natGateways: 0`
- Подсети: `PRIVATE_WITH_EGRESS` -> `PRIVATE_ISOLATED`
- Добавлены SG:
  - `WccApiLambdaSecurityGroup`
  - `WccDbSecurityGroup`
  - `WccSecretsManagerEndpointSecurityGroup`
- Добавлен `InterfaceVpcEndpoint` для `Secrets Manager`
- RDS переведен в приватный режим (`publiclyAccessible: false`) и использует явный SG
- Ограничен `egress` для `Lambda SG` и `RDS SG`
- `cloud/api` читает секрет БД из `Secrets Manager` на cold start (по `DB_SECRET_ARN`)
- Lambda API упаковывается через `NodejsFunction` (bundling) вместо загрузки сырой папки `cloud/api`
- Добавлен базовый `API Gateway` throttling на `$default` stage (защита от массового bot traffic без WAF)
- Добавлен output `SecretsManagerVpcEndpointId`

## Почему VPC Endpoint вместо NAT здесь уместен

Предпосылка верная: если Lambda не должна ходить в интернет, то для вызовов AWS API можно использовать VPC Endpoints.

В текущем стеке Lambda нужна связь с AWS API только для чтения секрета из `Secrets Manager`. Для этого достаточно:

- `Interface VPC Endpoint: com.amazonaws.<region>.secretsmanager`
- `Private DNS` (включено), чтобы SDK использовал стандартный hostname

Плюсы:

- ниже постоянные расходы, чем у NAT Gateway
- нет публичного egress для Lambda
- проще контролировать разрешенные направления трафика

Ограничения (важно):

- если позже Lambda начнет вызывать другие AWS сервисы (`SSM`, `SQS`, `SNS`, `KMS`, `Bedrock`, и т.д.), нужно добавить соответствующие VPC Endpoints
- если нужен доступ во внешний интернет (внешние API, npm registry, и т.п.), NAT или другой egress все равно потребуется

## Ресурсы стека и их назначение (по доменам)

Ниже перечислены ресурсы, которые создает стек `cloud/infra` (включая часть служебных ресурсов CDK, которые появляются из-за `BucketDeployment` и `autoDeleteObjects`).

### 1. Network / Private Connectivity

- `AWS::EC2::VPC` (`WccVpc`)
  - Изолированная сеть для Lambda, RDS и VPC endpoint.

- `AWS::EC2::Subnet` x2 (`app-isolated`, по AZ)
  - Приватные изолированные подсети для Lambda, RDS и ENI интерфейсного endpoint.

- `AWS::EC2::RouteTable` x2 + `AWS::EC2::SubnetRouteTableAssociation` x2
  - Маршрутизация для изолированных подсетей (без маршрута в интернет, так как NAT отсутствует).

- `AWS::EC2::VPCEndpoint` (`WccSecretsManagerVpcEndpoint`, Interface)
  - Приватный доступ из Lambda к `AWS Secrets Manager` по внутренней сети AWS.

### 2. Security / Access Control

- `AWS::EC2::SecurityGroup` (`WccApiLambdaSecurityGroup`)
  - Сетевой периметр API Lambda внутри VPC.
  - Исходящий трафик ограничен до `RDS`, `Secrets Manager VPCE` и `DNS` внутри VPC.

- `AWS::EC2::SecurityGroup` (`WccDbSecurityGroup`)
  - Сетевой периметр PostgreSQL; принимает только трафик от SG Lambda на `5432/tcp`.
  - Широкий исходящий трафик отключен (`egress` не открыт).

- `AWS::EC2::SecurityGroupIngress` (Lambda -> DB :5432)
  - Разрешает API Lambda подключаться к PostgreSQL.

- `AWS::EC2::SecurityGroup` (`WccSecretsManagerEndpointSecurityGroup`)
  - Периметр интерфейсного VPC endpoint для `Secrets Manager`.

- `AWS::EC2::SecurityGroupIngress` (Lambda -> VPCE :443)
  - Разрешает Lambda вызывать `Secrets Manager` через endpoint по HTTPS.

### 3. Data / Database

- `AWS::RDS::DBSubnetGroup` (`WccDbSubnetGroup`)
  - Группа подсетей для размещения RDS в изолированных подсетях двух AZ.

- `AWS::RDS::DBInstance` (`WccDb`)
  - PostgreSQL 16 (`db.t4g.micro`, Single-AZ) для API-приложения.

- `AWS::SecretsManager::Secret` (сгенерированный секрет для RDS)
  - Хранит логин/пароль мастер-пользователя БД.

- `AWS::SecretsManager::SecretTargetAttachment`
  - Привязывает секрет к RDS instance (стандартный паттерн CDK для `fromGeneratedSecret`).

### 4. Compute / API Runtime

- `AWS::IAM::Role` (role Lambda API)
  - Execution role для Lambda.

- `AWS::IAM::Policy` (inline policy Lambda API)
  - Разрешает `GetSecretValue/DescribeSecret` для секрета БД.

- `AWS::Lambda::Function` (`WccApiFunction`)
  - Backend API (Node.js 20), работает в VPC и подключается к RDS.
  - На cold start загружает credentials БД из `Secrets Manager`, затем инициализирует app.

- `AWS::Lambda::Permission` (invoke from API Gateway)
  - Разрешает HTTP API вызывать Lambda.

### 5. API Ingress

- `AWS::ApiGatewayV2::Api` (`WccHttpApi`)
  - HTTP API для проксирования запросов к Lambda.

- `AWS::ApiGatewayV2::Stage` (`$default`)
  - Автодеплой API без ручного stage management.
  - На stage включен базовый throttling (`rate/burst`) для ограничения всплесков запросов.

- `AWS::ApiGatewayV2::Integration`
  - Lambda proxy integration (`payloadFormatVersion=2.0`).

- `AWS::ApiGatewayV2::Route` (`ANY /{proxy+}`)
  - Один catch-all маршрут для backend API.

### 6. Frontend Static Hosting / CDN

- `AWS::S3::Bucket` (`WccSiteBucket`)
  - Хранилище статической сборки фронтенда (`cloud/web/out`).

- `AWS::S3::BucketPolicy`
  - Доступ к объектам только через CloudFront (OAC), плюс права для служебных custom resources CDK.

- `AWS::CloudFront::OriginAccessControl`
  - Безопасный доступ CloudFront к приватному S3 bucket (вместо публичного bucket).

- `AWS::CloudFront::Distribution` (`WccCdn`)
  - CDN для фронтенда, SPA fallback (`403/404 -> /index.html`), и проксирование `/api/*` на HTTP API.

### 7. Deployment Automation (CDK-generated helpers)

Эти ресурсы создаются не бизнес-логикой приложения напрямую, а потому что в стеке используется `BucketDeployment` и `autoDeleteObjects`.

- `Custom::S3AutoDeleteObjects`
  - Очистка S3 bucket при удалении стека (нужна для `autoDeleteObjects: true`).

- `AWS::Lambda::Function` + `AWS::IAM::Role` (provider для `S3AutoDeleteObjects`)
  - Служебная Lambda CDK, выполняет очистку bucket.

- `Custom::CDKBucketDeployment`
  - Копирует статические файлы из CDK assets в S3 bucket.

- `AWS::Lambda::Function` + `AWS::IAM::Role` + `AWS::IAM::Policy` (provider для `BucketDeployment`)
  - Служебная Lambda CDK для деплоя файлов.

- `AWS::Lambda::LayerVersion` (AWS CLI layer)
  - Слой, используемый CDK provider'ом `BucketDeployment`.

### 7.1. Lambda Bundling (build-time packaging)

- `NodejsFunction` bundling (`esbuild`)
  - Собирает `cloud/api` и зависимости monorepo (включая `@wcc/core`) в Lambda-compatible bundle.
  - Устраняет риск отсутствующих workspace-зависимостей внутри deploy zip.

- `defaultCharacter.json` (данные `@wcc/core`)
  - Копируется в bundle-артефакт на этапе bundling.
  - Lambda получает путь через env `WCC_DEFAULT_CHARACTER_PATH`, чтобы `surveyEngine` корректно находил файл после bundling.

### 8. Meta / Platform

- `AWS::CDK::Metadata`
  - Техническая мета-информация CDK.

- `SSM parameter /cdk-bootstrap/...` (параметр как dependency bootstrap)
  - Используется CDK для проверки версии bootstrap-окружения.
  - Важно: это не ресурс приложения, а инфраструктурная предпосылка CDK.

## Логическая оценка стоимости (почему это экономнее)

Что убрали:

- `NAT Gateway` (и связанный с ним egress-path для приватных подсетей)

Что добавили:

- `Interface VPC Endpoint` для `Secrets Manager`

Обычно для такого сценария это выгоднее, потому что:

- нужен доступ только к 1 AWS API
- нет требований к интернет-выходу
- нет постоянного NAT-трафика/egress для Lambda

Важно перепроверить цены в вашем регионе перед продом (например, `eu-central-1`), так как стоимость endpoint и NAT зависит от региона и трафика.

## Ограничение текущего ingress (важно)

Текущий стек по-прежнему использует публичные ingress-ресурсы:

- `CloudFront Distribution` (публичная точка входа)
- `API Gateway HTTP API` (публичный `execute-api` endpoint)

Это значит:

- backend-сегмент (`Lambda + RDS + VPC Endpoint`) уже приватизирован и cost-optimized
- но режим "приложение доступно только по внутреннему DNS и недоступно извне" требует отдельного рефакторинга ingress-слоя
- базовая защита от request flood частично добавлена через throttling API Gateway (но это не заменяет WAF)

Практически это будет отдельный архитектурный переключатель (`exposure mode`), а не только флаг в текущем `CloudFront + HTTP API` шаблоне.

## Что стоит учесть для будущего web-приложения

Если стек будет расти, рекомендую держать такую модель:

- VPC без NAT по умолчанию
- добавлять VPC Endpoints по факту потребности сервиса
- выносить интернет-egress в отдельный стек/подсети только когда реально нужен

Вероятные будущие endpoints (только при необходимости):

- `SSM` / `SSM_MESSAGES` / `EC2_MESSAGES` (если используете Session Manager на EC2 внутри VPC)
- `KMS` (если код Lambda сам вызывает KMS API)
- `SQS`, `SNS`, `DynamoDB` (по факту интеграций)
- `S3 Gateway Endpoint` (если workloads внутри VPC начнут активно ходить в S3)

## Планируемый шаблон (блок-схема)

```text
                       +----------------------+
                       |   Пользователь       |
                       +----------+-----------+
                                  |
                                  v
                       +----------------------+
                       | CloudFront (WccCdn)  |
                       |  - SPA static        |
                       |  - /api/* proxy      |
                       +-----+-----------+----+
                             |           |
              static files   |           | /api/*
                             |           v
                             |   +----------------------+
                             |   | API Gateway HTTP API |
                             |   +----------+-----------+
                             |              |
                             v              v
                    +----------------+  +----------------------+
                    | S3 Bucket       |  | Lambda (API)         |
                    | WccSiteBucket   |  | in PRIVATE_ISOLATED   |
                    +----------------+  +-----+------------+----+
                                              |            |
                                   PostgreSQL |            | HTTPS (private)
                                         5432 |            | to AWS API
                                              v            v
                                   +----------------+  +----------------------+
                                   | RDS Postgres    |  | VPC Endpoint         |
                                   | WccDb           |  | Secrets Manager      |
                                   +-----------------+  +----------+-----------+
                                                                  |
                                                                  v
                                                        +----------------------+
                                                        | Secrets Manager       |
                                                        | DB credentials secret |
                                                        +----------------------+

Notes:
- NAT Gateway отсутствует
- Интернет-egress из Lambda не предусмотрен
- Доступ к AWS API идет через VPC Endpoint (private path)
```

## Примечание по кодировке

Отчет сохранен в UTF-8.
