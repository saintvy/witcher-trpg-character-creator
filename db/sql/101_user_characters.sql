\echo '101_user_characters.sql'

DROP TABLE IF EXISTS wcc_user_characters CASCADE;

CREATE TABLE wcc_user_characters (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_email       TEXT NOT NULL,
  owner_sub         TEXT,
  owner_provider    TEXT,
  name              TEXT,
  race_code         TEXT,
  profession_code   TEXT,
  raw_character_json JSONB NOT NULL,
  answers_export_json JSONB NOT NULL,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX wcc_user_characters_owner_email_idx
  ON wcc_user_characters (owner_email);

CREATE INDEX wcc_user_characters_owner_email_created_at_idx
  ON wcc_user_characters (owner_email, created_at DESC);
