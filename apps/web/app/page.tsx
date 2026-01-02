"use client";

import { useLanguage } from "./language-context";
import { Topbar } from "./components/Topbar";

export default function HomePage() {
  const { lang, mounted } = useLanguage();
  
  // Use default language until mounted to avoid hydration mismatch
  const displayLang = mounted ? lang : "en";
  
  const content = {
    en: {
      title: "Project Overview",
      subtitle: "Character generation portal for The Witcher TRPG",
      description: "Overview of project goals, architecture, and technical implementation",
      sections: {
        goals: {
          title: "Project Goals",
          items: [
            "Create a web application for generating Witcher TTRPG characters through an interactive questionnaire",
            "Provide printable PDF character sheets",
            "Support multiple languages (English, Russian, Czech) via i18n",
            "Enable character storage and management for players and game masters",
            "Integrate with virtual tabletop platforms (FoundryVTT, Roll20)"
          ]
        },
        architecture: {
          title: "Architecture",
          items: [
            "Frontend: Next.js (App Router) with TypeScript",
            "Backend: Node.js API that will be deployed as AWS Lambda functions",
            "Database: PostgreSQL (local via Docker, will use RDS/Aurora in production)",
            "Infrastructure: AWS CDK for IaC (Infrastructure as Code)",
            "Authentication: AWS Cognito (with Google Sign-in support planned)",
            "Storage: S3 for generated PDFs"
          ]
        },
        technical: {
          title: "Technical Implementation",
          items: [
            "Survey engine: Dynamic questionnaire system using JSON Logic for conditional questions",
            "Character generation: Step-by-step character creation following The Witcher TRPG rules",
            "Content packs: Support for base game and DLC content (Tome of Chaos, etc.)",
            "Localization: UUID-based i18n system for questions, answers, and game content",
            "Data model: PostgreSQL schema with surveys, questions, answer options, and effects",
            "API contracts: OpenAPI specification for frontend-backend communication"
          ]
        }
      }
    },
    ru: {
      title: "Обзор проекта",
      subtitle: "Портал генерации персонажей для The Witcher TRPG",
      description: "Описание целей проекта, архитектуры и технической реализации",
      sections: {
        goals: {
          title: "Цели проекта",
          items: [
            "Создать веб-приложение для генерации персонажей The Witcher TTRPG через интерактивный опросник",
            "Предоставить печатные листы персонажей в формате PDF",
            "Поддержка нескольких языков (английский, русский, чешский) через i18n",
            "Возможность хранения и управления персонажами для игроков и мастеров",
            "Интеграция с виртуальными столами (FoundryVTT, Roll20)"
          ]
        },
        architecture: {
          title: "Архитектура",
          items: [
            "Frontend: Next.js (App Router) с TypeScript",
            "Backend: Node.js API, который будет развёрнут как AWS Lambda функции",
            "База данных: PostgreSQL (локально через Docker, в продакшене будет использоваться RDS/Aurora)",
            "Инфраструктура: AWS CDK для IaC (Infrastructure as Code)",
            "Аутентификация: AWS Cognito (с поддержкой Google Sign-in в планах)",
            "Хранилище: S3 для сгенерированных PDF"
          ]
        },
        technical: {
          title: "Техническая реализация",
          items: [
            "Движок опросника: Динамическая система вопросов с использованием JSON Logic для условных вопросов",
            "Генерация персонажа: Пошаговое создание персонажа в соответствии с правилами The Witcher TRPG",
            "Контент-паки: Поддержка базовой игры и DLC контента (Tome of Chaos и др.)",
            "Локализация: UUID-based система i18n для вопросов, ответов и игрового контента",
            "Модель данных: PostgreSQL схема с опросами, вопросами, вариантами ответов и эффектами",
            "API контракты: Спецификация OpenAPI для коммуникации frontend-backend"
          ]
        }
      }
    }
  };

  const t = content[displayLang];

  return (
    <>
      <Topbar title={t.title} subtitle={t.subtitle} />
      <section className="content" suppressHydrationWarning>
        <div className="info-section">
          <h3>{t.sections.goals.title}</h3>
          <ul>
            {t.sections.goals.items.map((item, idx) => (
              <li key={idx}>{item}</li>
            ))}
          </ul>
        </div>

        <div className="info-section">
          <h3>{t.sections.architecture.title}</h3>
          <ul>
            {t.sections.architecture.items.map((item, idx) => (
              <li key={idx}>{item}</li>
            ))}
          </ul>
        </div>

        <div className="info-section">
          <h3>{t.sections.technical.title}</h3>
          <ul>
            {t.sections.technical.items.map((item, idx) => (
              <li key={idx}>{item}</li>
            ))}
          </ul>
        </div>
      </section>
    </>
  );
}
