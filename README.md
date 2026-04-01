# Witcher Character Creator

Unofficial full-stack character builder for **The Witcher Tabletop Roleplaying Game**.

The project turns a rules-driven survey into a generated character, lets authenticated users save builds, attach avatars, export raw data and answer history, and download a printable PDF sheet. The repository is organized as a monorepo with a static Next.js frontend, a Hono API, PostgreSQL-backed game data, and AWS CDK infrastructure for cloud deployment.

## Highlights

- Guided survey engine backed by PostgreSQL content and JSON Logic-based branching.
- Persistent user characters with ownership tied to authenticated email identity.
- PDF export pipeline with translated labels, gear tables, magic catalogs, and avatar embedding.
- EN/RU interface support.
- DLC-aware rules content and item/magic catalogs.
- Static frontend delivery via S3 + CloudFront and API delivery via API Gateway + Lambda.
- Deterministic SQL bundle generation for both local seeding and cloud provisioning.

## Architecture

```text
Browser
  |
  +--> CloudFront
         |
         +--> S3 static site (`apps/web/out`)
         |
         +--> /api/* --> API Gateway HTTP API --> Lambda (`apps/api`)
                                               |
                                               +--> PostgreSQL (local Docker or AWS RDS)
                                               |
                                               +--> S3 data bucket (avatars)

SQL source (`db/sql`, `db/sql/items`)
  |
  +--> `db/seed.sh` --> merged `db/sql/wcc_sql_deploy.sql`
                         |
                         +--> local PostgreSQL seed
                         +--> infra custom resource seed during CDK deploy
```

## Current Product Surface

- **Public landing page** with SEO metadata, release notes, and portal navigation.
- **Builder** that walks the player through the questionnaire and resolves character state.
- **Characters area** for listing saved builds, importing raw JSON, deleting entries, downloading raw/history exports, generating PDFs, and managing avatars.
- **Settings** for PDF rendering preferences, including empty-table behavior and Witcher 1 alchemy icon mode.
- **Survey graph viewer** exposed as a static utility page for inspecting the questionnaire graph.

The repo currently contains:

- `125` source SQL modules under `db/sql` (excluding the generated deploy bundle)
- `38` item/catalog SQL modules under `db/sql/items`
- active web routes for `builder`, `characters`, `settings`, and supporting static pages

## Tech Stack

- **Frontend:** Next.js 14, React 18, TypeScript, static export mode
- **Backend:** Hono, Node.js 20, TypeScript
- **Database:** PostgreSQL 16
- **Infrastructure:** AWS CDK v2
- **PDF:** PDFKit
- **Auth:** Google ID token validation locally, optional Cognito/API Gateway JWT authorizer in AWS

## Repository Layout

```text
.
|-- apps/
|   |-- api/        # Hono API, PDF generation, auth, domain services
|   |-- graph/      # Survey graph export/viewer utility
|   `-- web/        # Next.js static frontend
|-- db/
|   |-- sql/        # schema, survey graph, lifepath, i18n, user data, PDF support
|   |-- sql/items/  # equipment, formulas, magic, effects, professional bundles
|   |-- docker-compose.yml
|   `-- seed.sh     # deterministic SQL merge + seed runner
|-- infra/          # AWS CDK stack, DB seed custom resource, deployment config
|-- scripts/        # build-time helpers for SQL bundle + web env generation
|-- start-scripts/  # Windows convenience scripts for local/dev/prod flows
`-- package.json
```

## Local Development

### Prerequisites

- Node.js `>=20`
- npm
- Docker Desktop
- Bash available in PATH for `db/seed.sh`
  - On Windows, Git Bash is sufficient

### 1. Install dependencies

```bash
npm install
```

### 2. Configure local database

Create `db/.env`:

```env
POSTGRES_USER=cc_user
POSTGRES_PASSWORD=cc_pass
POSTGRES_DB=witcher_cc
PGADMIN_EMAIL=admin@admin.com
PGADMIN_PASSWORD=admin
PGADMIN_PORT=5050
```

### 3. Configure auth for a usable local app

Important: the homepage is public, but the working product flows (`/builder`, `/characters`, `/settings`) are protected by the frontend auth gate and the API stores user-owned data by authenticated email. For a full local run, configure auth.

Minimal Google setup:

Create `apps/web/.env.local`:

```env
NEXT_PUBLIC_API_URL=http://localhost:4100/api
NEXT_PUBLIC_AUTH_PROVIDER=google
NEXT_PUBLIC_GOOGLE_CLIENT_ID=your_google_oauth_client_id
NEXT_PUBLIC_SITE_URL=http://localhost:3100
```

Create `apps/api/.env.local`:

```env
AUTH_MODE=google-jwt
AUTH_GOOGLE_CLIENT_IDS=your_google_oauth_client_id
ALLOWED_ORIGINS=http://localhost:3100
POSTGRES_HOST=localhost
POSTGRES_PORT=5433
POSTGRES_USER=cc_user
POSTGRES_PASSWORD=cc_pass
POSTGRES_DB=witcher_cc
```

If auth is not configured, the landing page still works, but protected routes will not be usable end-to-end.

### 4. Start PostgreSQL and seed content

```bash
cd db
docker compose up -d
bash ./seed.sh
```

What this does:

- generates `db/sql/wcc_sql_deploy.sql`
- applies the merged SQL bundle to the local PostgreSQL instance
- refreshes pgAdmin connection metadata

### 5. Run the application

From the repository root:

```bash
npm run dev
```

Local endpoints:

- Web: `http://localhost:3100`
- API: `http://localhost:4100/api`
- pgAdmin: `http://localhost:5050`

### Windows helpers

The repo also includes convenience launchers:

- `start-scripts/start-dev.bat`
- `start-scripts/start-dev-no-db-seed.bat`
- `start-scripts/start-prod.bat`

These are wrappers around the same core flows and are useful for local Windows-only operations.

## Key Commands

| Command | Purpose |
| --- | --- |
| `npm run dev` | Run API and web in parallel |
| `npm run dev:api` | Run only the API |
| `npm run dev:web` | Run only the web app |
| `npm run build` | Generate deploy SQL, build API, generate web env, build web |
| `npm run build:prepare-sql` | Merge SQL and refresh bundle version metadata |
| `npm run build:api` | Compile API |
| `npm run build:web` | Prepare web env and build static frontend |
| `npm run deploy` | Deploy AWS infrastructure |
| `npm --workspace @wcc/web run typecheck` | Type-check frontend |
| `npm --workspace @wcc/infra run synth` | Synthesize CDK stack |
| `bash db/seed.sh` | Merge and apply SQL locally |

## API Surface

Primary routes exposed by `apps/api`:

- `POST /api/generate-character`
- `POST /api/survey/next`
- `POST /api/survey/random-to-end`
- `POST /api/shop/allItems`
- `POST /api/skills/catalog`
- `POST /api/i18n/resolve`
- `GET /api/user/settings`
- `PUT /api/user/settings`
- `POST /api/characters`
- `GET /api/characters`
- `GET /api/characters/count`
- `GET /api/characters/:id/raw`
- `GET /api/characters/:id/history-export`
- `GET /api/characters/:id/pdf`
- `PUT /api/characters/:id/avatar`
- `GET /api/characters/:id/avatar`
- `DELETE /api/characters/:id`
- `GET /api/health`

## Build and Deployment

### Build flow

`npm run build` performs two important pre-build steps:

1. `scripts/prepare-deploy-sql.mjs`
   - runs `db/seed.sh` in merge-only mode
   - hashes the merged SQL bundle
   - writes `infra/generated/sql-bundle-version.json`
2. `scripts/prepare-web-env.mjs`
   - resolves frontend env values from `apps/web/.env.local` and/or `infra/.env.local`
   - writes `apps/web/.env.production.local`

### AWS stack

The CDK stack provisions:

- VPC with isolated subnets
- PostgreSQL RDS instance
- API Lambda
- DB seed Lambda custom resource
- API Gateway HTTP API
- S3 data bucket for private app assets
- S3 site bucket for static frontend
- CloudFront distribution with `/api/*` routing to the API

The stack outputs:

- site URL
- direct API URL
- RDS endpoint
- S3 data bucket name

### Minimal infra configuration

Create `infra/.env.local` before `npm run deploy`.

Minimum required values:

```env
WCC_DB_USER=app_user
WCC_DB_PASSWORD=strong_password
```

Common deployment values:

```env
WCC_SITE_URL=https://your-domain.example
WCC_FRONTEND_AUTH_PROVIDER=cognito
WCC_COGNITO_DOMAIN=https://your-domain.auth.region.amazoncognito.com
WCC_COGNITO_CLIENT_ID=your_cognito_app_client_id
WCC_COGNITO_REDIRECT_URI=https://your-domain.example/
WCC_COGNITO_LOGOUT_REDIRECT_URI=https://your-domain.example/
WCC_COGNITO_SCOPE=openid email profile
WCC_COGNITO_JWT_ISSUER=https://cognito-idp.region.amazonaws.com/your_user_pool_id
WCC_COGNITO_JWT_AUDIENCE=your_cognito_app_client_id
```

If you prefer Google auth in non-AWS environments, the frontend/API can instead use:

```env
WCC_GOOGLE_CLIENT_IDS=google_client_id_1,google_client_id_2
```

## Operational Notes

- The frontend is a **static export**, not a server-rendered Next.js deployment.
- User avatars are stored in S3 in AWS and on local disk fallback storage during local development.
- The API defaults to `http://localhost:3100` as an allowed CORS origin when `ALLOWED_ORIGINS` is not supplied.
- Cloud deployment applies the SQL bundle automatically through a custom resource, so schema/content changes travel with infrastructure changes.
- `apps/graph` is a repo utility, not part of the primary runtime path.

## Current Engineering Gaps

The project is significantly more production-shaped than the initial bootstrap, but a few gaps are still visible in the repo:

- root `lint` and `format` scripts are placeholders
- automated test suites are not wired into the monorepo yet
- CDK API CORS config is currently permissive (`*`) and should be tightened to known origins before a stricter production rollout

## License / Disclaimer

This is an unofficial fan project and is not affiliated with CD PROJEKT, R. Talsorian Games, or other rights holders of The Witcher franchise.
