# Witcher Character Creator (WCC)

Monorepo for generating Witcher TTRPG characters from a survey flow and exporting character sheets.

## Current Status

- `apps/*` is the active application runtime.
- Legacy branch has been removed.
- Shared business logic is embedded into `apps/api/src/core`.

## Tech Stack

- Frontend: Next.js 14, React, TypeScript (`apps/web`)
- Backend: Hono, Node.js, TypeScript (`apps/api`)
- Shared domain/services: local module (`apps/api/src/core`)
- Infra: AWS CDK (`infra`)
- Database: PostgreSQL (`db/sql`, `db/seed.sh`)

## Repository Layout

```text
.
|-- apps/
|   |-- api/      # API (Hono)
|   `-- web/      # Web app (Next.js)
|-- infra/        # AWS CDK infrastructure
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

- `npm run dev` - run API + web in parallel
- `npm run dev:api` - run only API
- `npm run dev:web` - run only web
- `npm run build` - prepare SQL + build API + web
- `npm run build:api` - build API
- `npm run build:web` - build web
- `npm run deploy` - deploy AWS infra from `@wcc/infra`

## Notes

- SQL deploy bundle metadata is generated into `infra/generated/sql-bundle-version.json`.
