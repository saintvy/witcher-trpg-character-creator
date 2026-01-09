\echo 'wcc_ddl_schema.sql'

DROP MATERIALIZED VIEW IF EXISTS wcc_item_upgrades_v CASCADE;
DROP MATERIALIZED VIEW IF EXISTS wcc_item_ingredients_v CASCADE;
DROP MATERIALIZED VIEW IF EXISTS wcc_item_armors_v CASCADE;
DROP MATERIALIZED VIEW IF EXISTS wcc_item_general_gear_v CASCADE;
DROP MATERIALIZED VIEW IF EXISTS wcc_item_vehicles_v CASCADE;
DROP MATERIALIZED VIEW IF EXISTS wcc_item_weapons_v CASCADE;
DROP MATERIALIZED VIEW IF EXISTS wcc_item_recipes_v CASCADE;
DROP MATERIALIZED VIEW IF EXISTS wcc_item_mutagens_v CASCADE;
DROP MATERIALIZED VIEW IF EXISTS wcc_item_trophies_v CASCADE;
DROP TABLE IF EXISTS wcc_item_to_effects CASCADE;
DROP TABLE IF EXISTS wcc_item_upgrades CASCADE;
DROP TABLE IF EXISTS wcc_item_weapons CASCADE;
DROP TABLE IF EXISTS wcc_item_armors CASCADE;
DROP TABLE IF EXISTS wcc_item_general_gear CASCADE;
DROP TABLE IF EXISTS wcc_item_vehicles CASCADE;
DROP TABLE IF EXISTS wcc_item_ingredients CASCADE;
DROP TABLE IF EXISTS wcc_item_recipes CASCADE;
DROP TABLE IF EXISTS wcc_item_mutagens CASCADE;
DROP TABLE IF EXISTS wcc_item_trophies CASCADE;
DROP TABLE IF EXISTS wcc_item_classes CASCADE;
DROP TABLE IF EXISTS wcc_item_effects CASCADE;
DROP TABLE IF EXISTS wcc_item_effect_conditions CASCADE;
DROP TABLE IF EXISTS wcc_dlcs CASCADE;

DROP TABLE IF EXISTS effects;
DROP TABLE IF EXISTS transitions;
DROP TABLE IF EXISTS answer_options;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS i18n_text;
DROP TABLE IF EXISTS i18n_keys;
DROP TABLE IF EXISTS content_packs;
DROP TABLE IF EXISTS survey_versions;
DROP TABLE IF EXISTS surveys;
DROP TABLE IF EXISTS rules;
DROP TYPE IF EXISTS question_type;
DROP TYPE IF EXISTS trigger_timing;
DROP TYPE IF EXISTS rule_logic;

CREATE TYPE question_type AS ENUM ('single', 'single_table', 'multiple', 'value_textbox', 'value_numeric', 'value_string', 'drop_down_detailed');
CREATE TYPE trigger_timing AS ENUM ('on_enter', 'on_exit', 'on_select');
CREATE TYPE rule_logic AS ENUM ('jsonlogic'); -- зарезервировано на будущее, можно расширять

CREATE OR REPLACE FUNCTION ck_id(src text)
RETURNS uuid AS $$
DECLARE
  _ns constant text := '12345678-9098-7654-3212-345678909876';
  m text;
BEGIN
  m := md5(_ns || src);
  RETURN (
      substr(m, 1, 8)  || '-' ||
      substr(m, 9, 4)  || '-' ||
      substr(m, 13, 4) || '-' ||
      substr(m, 17, 4) || '-' ||
      substr(m, 21, 12)
  )::uuid;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;


-- Версионирование/пространство графа
CREATE TABLE surveys (
  su_id         TEXT PRIMARY KEY,
  title         TEXT NOT NULL,
  description   TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE survey_versions (
  sv_id         INTEGER PRIMARY KEY,
  su_su_id      TEXT NOT NULL REFERENCES surveys(su_id) ON DELETE CASCADE,
  is_active     BOOLEAN NOT NULL DEFAULT FALSE,
  valid_from    TIMESTAMPTZ,
  valid_to      TIMESTAMPTZ,
  UNIQUE (su_su_id, sv_id)
);

-- DLC/источники (замена content_packs; используется как FK из questions/answer_options и из items-таблиц)
CREATE TABLE wcc_dlcs (
  dlc_id      varchar(64) PRIMARY KEY,  -- source_id (core, hb, dlc_*, exp_*)
  su_su_id    TEXT NOT NULL REFERENCES surveys(su_id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  semver      TEXT NOT NULL,             -- '1.2.0'
  priority    INTEGER NOT NULL DEFAULT 0, -- порядок применения патчей (выше — позже применяется)
  created_at  timestamptz NOT NULL DEFAULT now(),
  is_official BOOLEAN NOT NULL DEFAULT TRUE,
  name_id     uuid NOT NULL,            -- ck_id('witcher_cc.items.dlc.name.'||dlc_id)
  UNIQUE (su_su_id, dlc_id)
);

-- Локализация (опционально)
/*
CREATE TABLE i18n_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid()
);*/
CREATE TABLE i18n_text (
  id           UUID NOT NULL,
  entity       TEXT NOT NULL,  -- 'questions' | 'answer_options' | ...
  entity_field TEXT NOT NULL,  -- id из соответствующей таблицы
  lang         TEXT NOT NULL,  -- 'ru', 'en', ...
  text         TEXT NOT NULL,
  PRIMARY KEY (id, lang)
);

-- Узлы: вопросы
CREATE TABLE questions (
  qu_id            TEXT PRIMARY KEY,
  su_su_id         TEXT NOT NULL REFERENCES surveys(su_id) ON DELETE CASCADE,
  dlc_dlc_id       TEXT NOT NULL DEFAULT 'core' REFERENCES wcc_dlcs(dlc_id) ON DELETE CASCADE,
  title            UUID, -- краткая формулировка
  body             UUID, -- подробный текст/описание
  qtype            question_type NOT NULL,
  metadata         JSONB NOT NULL DEFAULT '{}'::jsonb, -- произвольные настройки рендера/валидации
  UNIQUE (su_su_id, dlc_dlc_id, qu_id)
);

-- Варианты ответов
CREATE TABLE answer_options (
  an_id            TEXT PRIMARY KEY,
  su_su_id         TEXT NOT NULL REFERENCES surveys(su_id) ON DELETE CASCADE,
  dlc_dlc_id       TEXT NOT NULL DEFAULT 'core' REFERENCES wcc_dlcs(dlc_id) ON DELETE CASCADE,
  qu_qu_id         TEXT NOT NULL REFERENCES questions(qu_id) ON DELETE CASCADE,
  label            TEXT NOT NULL,
  sort_order       INTEGER NOT NULL DEFAULT 0,
  visible_ru_ru_id UUID,
  metadata         JSONB NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE (qu_qu_id, an_id)
);

-- Эффекты (атомарные последствия)
CREATE TABLE effects (
  ef_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  qu_qu_id       TEXT REFERENCES questions(qu_id) ON DELETE CASCADE,
  an_an_id       TEXT REFERENCES answer_options(an_id) ON DELETE CASCADE,
  scope          TEXT NOT NULL,
  name           TEXT,
  description    TEXT,
  body           JSONB NOT NULL
);

-- Правила/условия (универсально: для видимости, переходов, эффектов и т.д.)
CREATE TABLE rules (
  ru_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT,
  description   TEXT,
  dialect       rule_logic NOT NULL DEFAULT 'jsonlogic',
  body          JSONB NOT NULL                 -- например JSONLogic выражение
);

-- Переходы между узлами (ребра)
CREATE TABLE transitions (
  tr_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_qu_qu_id      TEXT NOT NULL REFERENCES questions(qu_id) ON DELETE CASCADE,
  to_qu_qu_id        TEXT NOT NULL REFERENCES questions(qu_id) ON DELETE CASCADE,
  via_an_an_id       TEXT REFERENCES answer_options(an_id) ON DELETE SET NULL,
  ru_ru_id           UUID REFERENCES rules(ru_id) ON DELETE SET NULL,  -- условие перехода (доп. к via_answer)
  priority           INTEGER NOT NULL DEFAULT 0 -- чем больше, тем выше приоритет
);