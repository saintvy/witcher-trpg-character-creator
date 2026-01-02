# Witcher Character Creator (WCC)

> **Status: Work in Progress** 🚧  
> This project is actively under development. Core functionality is implemented, but some features are still being refined.

A full-stack web application for generating Witcher TTRPG (Tabletop Role-Playing Game) characters through an interactive survey system. The application produces detailed character sheets that can be exported as printable PDFs.

## 🎯 Project Overview

This project demonstrates modern full-stack development practices with:
- **TypeScript** throughout the codebase
- **Next.js** (App Router) for the frontend
- **Node.js** API with **Hono** framework
- **PostgreSQL** database with Docker
- **Monorepo** structure using npm workspaces
- **i18n** support (English/Russian)

The application features a sophisticated survey engine that:
- Supports complex conditional logic using JSONLogic
- Handles dynamic question flows based on previous answers
- Manages character state and effects incrementally
- Provides shop/item selection interfaces
- Generates complete character data structures

## 🏗️ Architecture

### Tech Stack

**Frontend:**
- Next.js 14+ (App Router)
- TypeScript
- React Server Components & Client Components
- CSS Modules

**Backend:**
- Node.js with TypeScript
- Hono web framework
- PostgreSQL with connection pooling
- JSONLogic for conditional logic

**Database:**
- PostgreSQL 15+
- Docker Compose for local development
- PGAdmin for database management

**Development:**
- npm workspaces (monorepo)
- TypeScript strict mode
- ESLint configuration

### Project Structure

```
.
├─ apps/
│  ├─ api/              # Backend API (Node.js + Hono)
│  │  ├─ src/
│  │  │  ├─ handlers/   # API route handlers
│  │  │  ├─ services/   # Business logic (survey engine, shop catalog)
│  │  │  └─ db/         # Database connection pool
│  │  └─ dist/          # Compiled JavaScript
│  └─ web/              # Frontend (Next.js)
│     └─ app/           # Next.js App Router pages
├─ db/
│  ├─ sql/              # Database schema and seed data
│  ├─ docker-compose.yml
│  └─ seed.sh          # Database initialization script
└─ start-scripts/       # Development helper scripts
```

## 🚀 Getting Started

### Prerequisites

- **Node.js** LTS (>= 20) - [Install via NVM](https://github.com/nvm-sh/nvm) recommended
- **npm** (bundled with Node.js)
- **Docker Desktop** - for local PostgreSQL database

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd wcc
   ```

2. **Install dependencies**
   ```bash
   npm run setup
   ```

3. **Set up the database**
   ```bash
   cd db
   cp .env.example .env  # Edit if needed
   docker compose up -d
   ./seed.sh
   ```

4. **Start development servers**

   Terminal 1 (API):
   ```bash
   npm run dev:api
   ```

   Terminal 2 (Web):
   ```bash
   npm run dev:web
   ```

5. **Access the application**
   - Web UI: http://localhost:3000
   - API: http://localhost:4000
   - PGAdmin: http://localhost:5050 (admin@admin.com / admin)

## 📋 Features

### Implemented

- ✅ Interactive character creation survey
- ✅ Dynamic question flow with conditional logic
- ✅ Multiple question types (single choice, multiple choice, tables, dropdowns, numeric/text inputs)
- ✅ Shop/item selection interface
- ✅ Character state management with effects and counters
- ✅ i18n support (English/Russian)
- ✅ Character generation from survey answers
- ✅ Question history navigation
- ✅ Random answer generation with weighted probabilities

### In Progress

- 🚧 PDF export functionality
- 🚧 User authentication (Cognito integration)
- 🚧 Cloud deployment (AWS Lambda + RDS)
- 🚧 Additional character sheet views
- 🚧 Character saving/loading

## 🔧 Development

### Available Scripts

- `npm run setup` - Install all workspace dependencies
- `npm run dev:api` - Start API development server
- `npm run dev:web` - Start Next.js development server
- `npm run build` - Build all workspaces
- `npm run lint` - Run ESLint across all workspaces

### Code Organization

- **API handlers** (`apps/api/src/handlers/`) - HTTP route handlers
- **Services** (`apps/api/src/services/`) - Business logic and data processing
- **Database** (`db/sql/`) - Schema definitions and seed data
- **Frontend pages** (`apps/web/app/`) - Next.js pages and components

### Database Schema

The database uses a flexible survey/question system:
- `surveys` - Survey definitions
- `questions` - Survey questions with metadata
- `answer_options` - Available answers for questions
- `effects` - Answer and question effects (JSONLogic expressions)
- `transitions` - Question flow logic
- `i18n_text` - Internationalization texts
- `rules` - Visibility and transition rules

## 🎓 Learning Resources

This project demonstrates:
- Monorepo management with npm workspaces
- TypeScript best practices
- Database design for complex survey systems
- State management in survey engines
- JSONLogic for conditional logic
- i18n implementation patterns
- Docker for local development

## 📝 Notes

- The project is configured for local development. Cloud deployment configuration is planned.
- Database migrations are managed through SQL files in `db/sql/`
- The survey engine supports complex nested conditions and dynamic state computation
- Character generation uses a template-based approach with effect application

## 🤝 Contributing

This is a personal project, but suggestions and feedback are welcome!

---

**Built with ❤️ for Witcher TTRPG enthusiasts**
