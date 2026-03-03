# Witcher Character Creator (WCC)

Cloud-first monorepo for generating Witcher TTRPG characters from a survey flow and exporting character sheets.

## Current Status

- `cloud/*` is the only active application runtime.
- Legacy `apps/*` has been removed.
- Shared business logic is embedded into `cloud/api/src/core`.

## Tech Stack

- Frontend: Next.js 14, React, TypeScript (`cloud/web`)
- Backend: Hono, Node.js, TypeScript (`cloud/api`)
- Shared domain/services: local module (`cloud/api/src/core`)
- Infra: AWS CDK (`cloud/infra`)
- Database: PostgreSQL (`db/sql`, `db/seed.sh`)

## Repository Layout

```text
.
|-- cloud/
|   |-- api/      # Cloud API (Hono)
|   |-- web/      # Cloud web app (Next.js)
|   `-- infra/    # AWS CDK infrastructure
|-- db/
|   |-- sql/      # Schema, data, migrations
|   `-- seed.sh   # SQL bundle generation / local seed
|-- scripts/
|-- start-scripts/
`-- package.json
```

## Prerequisites

- Node.js >= 20
- npm
- Docker Desktop (for local PostgreSQL)

## Installation

```bash
npm run setup
```

## Local Development

1. Start PostgreSQL (and optional pgAdmin) from `db/docker-compose.yml`.
2. Seed DB:

```bash
cd db
./seed.sh
```

3. Start app:

```bash
npm run dev
```

Default ports:
- Web: `http://localhost:3100`
- API: `http://localhost:4100`

## Scripts

- `npm run dev` - run cloud API + cloud web in parallel
- `npm run dev:api` - run only cloud API
- `npm run dev:web` - run only cloud web
- `npm run build` - prepare SQL + build cloud API + cloud web
- `npm run build:api` - build cloud API
- `npm run build:web` - build cloud web
- `npm run deploy` - deploy AWS infra from `@wcc/infra`

## Notes

- SQL deploy bundle metadata is generated into `cloud/infra/generated/sql-bundle-version.json`.
- Cloud deployment instructions are in `docs/CLOUD_DEPLOY.md`.
- Authentication setup notes are in `docs/AUTH_GOOGLE_COGNITO_SETUP.md`.
