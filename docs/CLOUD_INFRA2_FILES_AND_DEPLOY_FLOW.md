# Cloud / infra 2 — разбор по файлам и “как деплоится” (DB only)

Этот документ объясняет **каждый файл** в `cloud/infra 2/` и даёт “пошаговый трейс” того, что реально происходит при `cdk deploy` (куда передаётся управление, какие артефакты рождаются, и какие AWS ресурсы создаются).

---

## 1) Карта папки `cloud/infra 2/`

Внутри вы увидите:

- `package.json` — npm workspace-пакет с CDK-скриптами.
- `cdk.json` — конфиг CDK CLI: как запускать app + контексты.
- `tsconfig.json` — конфиг TypeScript компиляции в `dist/`.
- `bin/infra2-db.ts` — “entrypoint” CDK приложения (создаёт `App` и `Stack`).
- `lib/wcc-db-only-stack.ts` — сам CDK Stack: VPC + RDS + Secret + Outputs.
- `dist/**` — скомпилированные JS/DTS (генерируется `npm run build`).
- `cdk.out/**` — результат `cdk synth` (Cloud Assembly: template, assets, manifest, tree).
- `cdk.context.json` — кеш CDK lookups (например, список AZ в регионе).

Важно: `dist/` и `cdk.out/` — **генерируемые артефакты**. Они помогают отлаживать, но не являются “исходниками”.

---

## 2) Файлы верхнего уровня

### `cloud/infra 2/package.json`

Назначение: делает `cloud/infra 2` самостоятельным CDK-пакетом `@wcc/infra2-db`.

Что внутри:

- `scripts.build`: `tsc -p tsconfig.json` → компилирует `bin/` и `lib/` в `dist/`.
- `scripts.synth`: `cdk synth` → собирает CloudFormation-шаблон(ы) в `cdk.out/`.
- `scripts.diff`: `cdk diff` → сравнивает текущее состояние CloudFormation с новым synth.
- `scripts.deploy`: `cdk deploy` → запускает публикацию assets (если есть) и CloudFormation deploy.
- `scripts.destroy`: `cdk destroy` → удаляет stack (в вашем случае RDS стоит `SNAPSHOT`, поэтому будет snapshot при удалении).

Зависимости:

- `aws-cdk-lib`, `constructs` — CDK v2.
- `aws-cdk` (devDependency) — CDK CLI.
- `ts-node` — чтобы CDK мог запускать `bin/infra2-db.ts` прямо как TS (см. `cdk.json`).
- `source-map-support` — чтобы ошибки в runtime указывали на TS-строки (удобно при отладке).

---

### `cloud/infra 2/cdk.json`

Назначение: главный конфиг CDK CLI для этого workspace.

Ключевые поля:

- `app`: команда, которую CDK выполняет, чтобы построить construct tree.
  - Здесь: `npx ts-node --prefer-ts-exts bin/infra2-db.ts`
  - То есть CDK не запускает `dist/` автоматически — он запускает **TypeScript entrypoint напрямую**.
- `context`: значения, которые попадают в `App.node.tryGetContext(...)`.
  - `dbName` — имя создаваемой БД в RDS (`witcher_cc`).
  - `dbUsername` — мастер-логин (в Secrets Manager хранится пароль).
  - `createSecretsManagerVpcEndpoint` — создавать ли VPC endpoint, чтобы из VPC без NAT читать секрет.

Как переопределять контекст при запуске:

```bash
npm --workspace @wcc/infra2-db exec -- cdk synth -c dbName=witcher_cc -c dbUsername=cc_user -c createSecretsManagerVpcEndpoint=false
```

---

### `cloud/infra 2/tsconfig.json`

Назначение: правила компиляции TypeScript → JavaScript в `dist/`.

Ключевые моменты:

- `outDir: "dist"` — куда складываются `.js` и `.d.ts`.
- `declaration: true` — генерятся `.d.ts`, чтобы было видно публичные типы.
- `include: ["bin", "lib"]` — компилируются только эти папки.

---

### `cloud/infra 2/cdk.context.json`

Назначение: локальный кеш результатов “lookups”, которые CDK иногда делает через AWS API во время `synth`.

Пример в вашем файле:

- `availability-zones:account=...:region=eu-central-1` → список AZ.

Почему появляется:

- CDK `Vpc` по умолчанию раскладывает subnets по AZ и для этого может узнать список AZ в регионе.

Практически:

- Этот файл можно удалить — он будет пересоздан при следующем synth.
- В CI/командной работе его часто не считают “исходником” (но это решение команды).

---

## 3) Исходники CDK app

### `cloud/infra 2/bin/infra2-db.ts` (entrypoint)

Назначение: “точка входа” CDK приложения.

Что делает по шагам:

1) `import 'source-map-support/register'` — улучшает stack traces.
2) `const app = new cdk.App()` — создаёт CDK App.
3) Читает контексты из `cdk.json` через `app.node.tryGetContext(...)`:
   - `dbName`, `dbUsername`, `createSecretsManagerVpcEndpoint`.
4) Создаёт Stack:
   - `new WccDbOnlyStack(app, 'WccDbOnlyStack', { env, ...props })`
5) На этом JS/TS “заканчивается”: дальше CDK CLI забирает construct tree и делает synth.

Почему важен `env`:

- `account`/`region` влияют на:
  - имена bootstrap-ресурсов,
  - lookups,
  - куда деплоится CloudFormation stack.

---

### `cloud/infra 2/lib/wcc-db-only-stack.ts` (Stack)

Назначение: описывает *что именно* нужно создать в AWS.

#### Блок 1 — VPC

Создаёт `ec2.Vpc` с:

- `maxAzs: 2` — раскладываем subnets в 2 AZ.
- `natGateways: 0` — **NAT не создаётся** (экономия и соответствует требованию “Lambda без интернета”).
- `subnetConfiguration`:
  - `PUBLIC` — нужны как минимум для:
    - Internet Gateway маршрутизации,
    - (опционально) временной EC2 для SSM port-forward при ручном доступе к RDS.
  - `PRIVATE_ISOLATED` — сюда кладём RDS (без маршрута в интернет).

Опционально:

- `InterfaceVpcEndpoint` для Secrets Manager — чтобы Lambda в isolated subnets могла дергать Secrets Manager API без NAT.

#### Блок 2 — Security Group

Создаётся SG для БД и добавляется inbound правило:

- TCP 5432 **из CIDR всей VPC** (`vpc.vpcCidrBlock`).

Смысл:

- Любая Lambda/EC2/ECS внутри этой VPC сможет подключиться к Postgres по 5432.

#### Блок 3 — RDS PostgreSQL

Создаётся `rds.DatabaseInstance`:

- Engine: PostgreSQL 16.
- Instance class: `t4g.micro` — самый дешёвый “общий” вариант под RDS (ARM/Graviton).
- Subnets: `PRIVATE_ISOLATED` → `publiclyAccessible: false`.
- Storage: `gp3`, `allocatedStorage: 20` (минимально разумный).
- `multiAz: false` — экономия.
- Credentials: `fromGeneratedSecret(dbUsername)`:
  - CDK создаёт Secret в Secrets Manager,
  - и подключает его к RDS (автогенерация пароля).
- `removalPolicy: SNAPSHOT` — при удалении stack сохранит snapshot (защита от случайной потери данных).
- `backupRetention: 1 day` — минимальная ретенция автоматических бэкапов.

#### Outputs (для людей и для будущих stack’ов)

Stack публикует:

- `VpcId`
- `IsolatedSubnetIds` (CSV)
- `PublicSubnetIds` (CSV)
- `DbSecurityGroupId`
- `DbEndpointAddress`
- `DbEndpointPort`
- `DbName`
- `DbSecretArn` (если secret создан)

Плюс эти outputs экспортируются через `exportName = ${stackName}-...`, чтобы другой CloudFormation stack мог их импортировать.

---

## 4) `dist/` (результат `npm run build`)

### `cloud/infra 2/dist/bin/infra2-db.js`

Назначение: скомпилированная версия `bin/infra2-db.ts`.

Что важно понимать:

- Этот файл **не участвует** в стандартном `cdk synth/deploy` в текущей конфигурации, потому что `cdk.json` запускает `ts-node bin/infra2-db.ts`.
- Он нужен для:
  - проверки, что TypeScript компилируется,
  - возможного будущего режима “запускать без ts-node” (например, если захотите поменять `cdk.json` на `node dist/bin/infra2-db.js`).

### `cloud/infra 2/dist/bin/infra2-db.d.ts`

Назначение: декларации типов для entrypoint (у entrypoint обычно почти пусто — это нормально).

### `cloud/infra 2/dist/lib/wcc-db-only-stack.js` / `.d.ts`

Назначение: скомпилированная версия Stack и типы для неё.

---

## 5) `cdk.out/` (результат `cdk synth`)

`cdk synth` строит “Cloud Assembly” — набор артефактов для последующего `deploy`.

### `cloud/infra 2/cdk.out/WccDbOnlyStack.template.json`

Назначение: **CloudFormation template**, который реально будет применён в AWS.

Что вы там увидите:

- `AWS::EC2::*` ресурсы VPC:
  - VPC, Subnets, RouteTables, Routes, IGW, associations.
- `AWS::EC2::SecurityGroup` для БД.
- `AWS::EC2::VPCEndpoint` (если включено создание endpoint).
- `AWS::SecretsManager::Secret` и `SecretTargetAttachment`.
- `AWS::RDS::DBSubnetGroup`.
- `AWS::RDS::DBInstance`.
- `Outputs` — те же, что описаны в `lib/wcc-db-only-stack.ts`.

### `cloud/infra 2/cdk.out/WccDbOnlyStack.assets.json`

Назначение: “манифест ассетов”.

Даже если у вас нет Lambda-кода/архивов, CDK всё равно может публиковать **сам template** как file-asset в bootstrap S3 bucket (для крупных шаблонов/стандарта CDK).

Отсюда берутся:

- bucket/region,
- objectKey,
- роли публикации (file publishing role).

### `cloud/infra 2/cdk.out/manifest.json`

Назначение: главный манифест cloud assembly.

Что важно:

- описывает, какой template-файл относится к какому stack’у;
- какие роли CDK будет использовать при `deploy` (deploy role, cfn exec role, lookup role);
- какие зависимости между артефактами (например, stack зависит от `.assets`).

### `cloud/infra 2/cdk.out/tree.json`

Назначение: “дерево конструктов” (construct tree) и его маппинг на CloudFormation logical IDs.

Использование:

- отличный файл для дебага: “какой construct породил какой CFN ресурс”.

### `cloud/infra 2/cdk.out/cdk.out`

Назначение: служебный “маркер” версии/формата cloud assembly (в вашем случае просто `{"version":"48.0.0"}`).

---

## 6) Что происходит при деплое (очень подробно, по шагам)

Ниже описан процесс, когда вы запускаете:

```bash
npm --workspace @wcc/infra2-db run deploy
```

### Шаг 0 — npm → CDK CLI

1) npm находит workspace `@wcc/infra2-db`.
2) запускает script `deploy`, то есть команду `cdk deploy`.
3) `cdk` читает `cloud/infra 2/cdk.json`.

Точка внимания: **`cdk.json:app`** — это “куда CDK передаёт управление”, чтобы получить construct tree.

### Шаг 1 — запуск CDK app (TypeScript entrypoint)

4) CDK выполняет команду из `cdk.json:app`:
   - `npx ts-node ... bin/infra2-db.ts`
5) Node.js поднимает runtime, `ts-node` компилирует TS на лету.
6) выполняется `bin/infra2-db.ts`:
   - создаётся `new cdk.App()`,
   - читаются контексты,
   - создаётся `new WccDbOnlyStack(...)`,
   - внутри конструктора создаются VPC → SG → RDS → Outputs (как construct’ы).

Точка внимания: **`lib/wcc-db-only-stack.ts`** — именно здесь формируется “что будет создано”.

### Шаг 2 — synth (получение Cloud Assembly)

7) CDK “снимает слепок” construct tree и переводит его в CloudFormation:
   - генерирует `cdk.out/WccDbOnlyStack.template.json`,
   - генерирует `cdk.out/manifest.json`,
   - генерирует `cdk.out/*assets*.json`,
   - обновляет/создаёт `cdk.context.json` (если были lookups).

Точка внимания: **`cdk.out/WccDbOnlyStack.template.json`** — это конечный CFN-шаблон.

### Шаг 3 — bootstrap check / роли / ассеты

8) CDK проверяет, что окружение bootstrapped (есть `cdk-hnb659fds-*` ресурсы).
9) CDK готовит публикацию ассетов:
   - в вашем случае это, как минимум, загрузка template в bootstrap S3 bucket (см. `WccDbOnlyStack.assets.json`).
10) CDK (если настроено) пытается использовать bootstrap роли:
   - `lookup role` для lookups,
   - `file publishing role` для загрузки в S3,
   - `deploy role` для вызова CloudFormation,
   - `cfn exec role` — роль, от имени которой CloudFormation создаёт ресурсы.

### Шаг 4 — CloudFormation deploy (создание/обновление ресурсов)

11) CDK вызывает CloudFormation `CreateChangeSet/ExecuteChangeSet` (или direct update).
12) CloudFormation создаёт ресурсы в порядке зависимостей:

**A. Сеть (VPC)**

- создаётся VPC (`AWS::EC2::VPC`);
- создаются 2 public subnet и 2 isolated subnet;
- создаётся Internet Gateway и прикрепляется к VPC;
- в public subnets создаются route table + default route `0.0.0.0/0 → IGW`;
- isolated subnets остаются без default route в интернет (это и делает их “isolated”).

**B. (Опционально) Endpoint**

- создаётся security group endpoint’а и сам `AWS::EC2::VPCEndpoint` для Secrets Manager.

**C. Security Group БД**

- создаётся SG для Postgres;
- добавляется inbound TCP 5432 из CIDR VPC.

**D. Secrets Manager**

- создаётся `AWS::SecretsManager::Secret` с `{"username":"cc_user"}` и автосгенерированным паролем.

**E. RDS**

- создаётся `AWS::RDS::DBSubnetGroup` из isolated subnet IDs;
- создаётся `AWS::RDS::DBInstance` (Postgres 16, `db.t4g.micro`, `gp3`).
- создаётся `SecretTargetAttachment`, чтобы RDS использовал пароль из Secret.

13) После успешного создания CloudFormation публикует Outputs.

Точка внимания: если деплой “завис” надолго — это обычно шаг создания `AWS::RDS::DBInstance` (он самый долгий).

---

## 7) Частые “почему так” (коротко)

- **Почему есть public subnets, если RDS приватная?**
  - Они нужны для IGW и (при желании) для временной EC2 под SSM port-forward. RDS всё равно сидит в isolated.
- **Почему без NAT?**
  - NAT Gateway — дорогая сущность и не нужна для “Lambda → RDS” без интернета. Для Secrets Manager вместо NAT используется VPC endpoint.
- **Почему Secret генерируется CDK?**
  - Это безопаснее и упрощает ротацию/аудит, чем “пароль в env”.

