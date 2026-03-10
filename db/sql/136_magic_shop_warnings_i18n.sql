\echo '136_magic_shop_warnings_i18n.sql'

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  ('d7b50262-5bb0-4d5c-8ad1-8c3327119e71'::uuid, 'ui', 'shop.magic.no_tokens_warning', 'ru', 'Похоже, ваш персонаж не способен к магии, если следовать правилам.'),
  ('d7b50262-5bb0-4d5c-8ad1-8c3327119e71'::uuid, 'ui', 'shop.magic.no_tokens_warning', 'en', 'It looks like your character is not capable of magic, if the rules are followed.')
ON CONFLICT (id, lang) DO UPDATE
SET text = EXCLUDED.text;
