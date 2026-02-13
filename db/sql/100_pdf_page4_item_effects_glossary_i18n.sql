\echo '100_pdf_page4_item_effects_glossary_i18n.sql'

-- PDF page 4: item effects glossary
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.pdf.page4.effects.title'), 'pdf', 'page4.effects.title', 'ru', 'Эффекты предметов'),
  (ck_id('witcher_cc.pdf.page4.effects.title'), 'pdf', 'page4.effects.title', 'en', 'Item effects')
ON CONFLICT (id, lang) DO UPDATE
  SET text = EXCLUDED.text;

