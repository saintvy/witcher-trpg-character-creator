\echo '163_avatar_column.sql'

ALTER TABLE wcc_user_characters ADD COLUMN IF NOT EXISTS avatar_url TEXT;

