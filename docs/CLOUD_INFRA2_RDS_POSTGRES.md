# Cloud infra 2: RDS PostgreSQL (только БД)

> Цель: развернуть **только PostgreSQL в Amazon RDS**, чтобы в него ходила Lambda (внутри VPC), без обязательного выхода в интернет.

## Что добавлено в репозитории

- `cloud/infra 2/` — отдельный CDK-пакет `@wcc/infra2-db`, который создаёт:
  - VPC (2 AZ, **без NAT**)
  - Security Group для БД
  - RDS PostgreSQL 16 (самый дешёвый класс `t4g.micro`, Single-AZ)
  - Secret в AWS Secrets Manager (логин/пароль мастер-пользователя)
  - (опционально) VPC Interface Endpoint для Secrets Manager, чтобы Lambda внутри VPC могла читать секрет **без NAT/интернета**

## Почему нужны “доп. ресурсы” кроме RDS-инстанса

- **VPC + subnets + Security Groups**: RDS всегда живёт в VPC и управляется через SG. Это базовая необходимость.
- **Secrets Manager secret**: безопаснее, чем хранить пароль в коде/переменных окружения.
- **VPC Endpoint для Secrets Manager (рекомендовано)**: если Lambda будет в приватных подсетях без NAT, то без endpoint она не сможет вызывать Secrets Manager API. Endpoint обычно **дешевле**, чем держать NAT Gateway.
- **NAT Gateway намеренно не создаётся**: это одна из самых дорогих “базовых” сетевых сущностей, а вам интернет Lambda не нужен.

## Предпосылки

- AWS CLI настроен (`aws configure`) и есть права на CloudFormation, EC2, RDS, Secrets Manager.
- Node.js `>= 20` (см. `package.json` в корне).
- CDK bootstrap для аккаунта/региона (один раз на окружение).

## Как задеплоить инфраструктуру (без запуска из этого репозитория автоматически)

1) Установите зависимости в корне монорепо:

```bash
npm ci
```

2) Bootstrap CDK (1 раз на аккаунт+регион):

```bash
npm --workspace @wcc/infra2-db exec -- cdk bootstrap
```

3) Посмотреть, что будет создано:

```bash
npm --workspace @wcc/infra2-db run diff
```

4) Деплой:

```bash
npm --workspace @wcc/infra2-db run deploy
```

Примечание: если удобнее запускать прямо из папки, используйте `cd "cloud/infra 2"` и `npx cdk ...` (путь содержит пробел).

После деплоя сохраните **CloudFormation Outputs**: `DbEndpointAddress`, `DbEndpointPort`, `DbSecretArn`, `DbName`, `VpcId`, `DbSecurityGroupId`.

## Как “залить” текущую базу в RDS (Postgres)

В репозитории уже есть “миграции” как набор SQL-файлов и скрипт, который их склеивает и применяет:
- SQL: `db/sql/**/*.sql`
- Скрипт: `db/seed.sh` (генерирует `db/sql/wcc_sql_deploy.sql` и применяет его)

### Вариант A (рекомендовано): применить SQL напрямую в RDS

1) Получите пароль из Secrets Manager (по `DbSecretArn`):

```bash
aws secretsmanager get-secret-value --secret-id "<DbSecretArn>"
```

В `SecretString` будет JSON с `username` и `password`.

2) Создайте/обновите `db/.env` под RDS (пример):

```env
POSTGRES_HOST=<DbEndpointAddress>
POSTGRES_PORT=5432
POSTGRES_USER=cc_user
POSTGRES_PASSWORD=<password_from_secret>
POSTGRES_DB=witcher_cc
```

3) Запустите деплой SQL в RDS (важно: форсируем host-mode, чтобы не “попасть” в локальный docker-postgres):

```bash
cd db
WCC_SEED_FORCE_HOST=true ./seed.sh
```

Требования на вашей машине для этого варианта:
- `bash`
- `psql` и `pg_isready` (PostgreSQL client tools)

### Вариант B: только собрать “единый SQL”, а применить вручную

```bash
cd db
WCC_SEED_MERGE_ONLY=true ./seed.sh
```

После этого файл `db/sql/wcc_sql_deploy.sql` можно применять любым `psql -f`.

## Как подключиться к базе “руками” (консоль / psql)

БД создаётся **в приватных (isolated) подсетях** и не имеет публичного доступа из интернета. Поэтому есть два типовых пути:

### Путь 1 (правильный для приватной БД): port-forward через SSM на временную EC2

Идея: поднять маленький EC2-инстанс в **public subnet** этой VPC (входящих правил не нужно), подключиться к нему через SSM Session Manager и сделать port-forward до RDS.

1) Создайте EC2 в этой VPC:
- AMI: Amazon Linux 2023 (любая свежая)
- Тип: `t4g.nano`/`t3.nano` (временно, самый дешёвый)
- Subnet: public subnet из Outputs `PublicSubnetIds` (это подсети внутри `VpcId`)
- IAM Role: `AmazonSSMManagedInstanceCore`
- Security Group: без inbound, outbound по умолчанию

2) На локальной машине запустите порт-форвардинг (нужен AWS CLI + SSM plugin):

```bash
aws ssm start-session \
  --target "<i-INSTANCE_ID>" \
  --document-name "AWS-StartPortForwardingSessionToRemoteHost" \
  --parameters host="<DbEndpointAddress>",portNumber="5432",localPortNumber="15432"
```

3) В другом терминале подключитесь `psql` к локальному порту:

```bash
PGPASSWORD="<password_from_secret>" psql -h 127.0.0.1 -p 15432 -U cc_user -d witcher_cc "sslmode=require"
```

4) После работы **остановите или удалите** EC2, чтобы не платить за простои.

### Путь 2 (если у вас уже есть VPN/DirectConnect в VPC)

Подключайтесь `psql` напрямую к `DbEndpointAddress:5432`, используя пароль из Secrets Manager.

## Как подключать Lambda к этой RDS

- Lambda должна быть **в этой VPC** (см. `VpcId`) и в приватных подсетях.
- Для подключения достаточно, чтобы Lambda находилась внутри VPC: SG БД уже разрешает вход на 5432 **из CIDR VPC**.
- Чтобы Lambda могла читать пароль из Secrets Manager **без NAT**, оставьте включённым `createSecretsManagerVpcEndpoint=true` (по умолчанию в `cloud/infra 2/cdk.json`).

## Параметры стоимости / почему это “дёшево”

- RDS: `db.t4g.micro`, Single-AZ, `gp3` 20GB (минимум).
- NAT Gateway отсутствует.
- Endpoint Secrets Manager добавляет небольшой постоянный cost, но обычно дешевле NAT и соответствует требованию “без интернета”.
