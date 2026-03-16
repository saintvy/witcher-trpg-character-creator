\echo '158_user_settings.sql'

CREATE TABLE IF NOT EXISTS wcc_user_settings (
  owner_email            TEXT PRIMARY KEY,
  owner_sub              TEXT,
  owner_provider         TEXT,
  settings_json          JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

