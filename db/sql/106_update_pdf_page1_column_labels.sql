\echo '106_update_pdf_page1_column_labels.sql'

-- Ensure latest PDF page1 table column labels are applied for existing DBs.
UPDATE i18n_text
SET text = 'Алхимия'
WHERE id = ck_id('witcher_cc.pdf.page1.tables.potions.col.name')
  AND lang = 'ru';

UPDATE i18n_text
SET text = 'Alchemy'
WHERE id = ck_id('witcher_cc.pdf.page1.tables.potions.col.name')
  AND lang = 'en';

UPDATE i18n_text
SET text = 'Магия'
WHERE id = ck_id('witcher_cc.pdf.page1.tables.magic.col.name')
  AND lang = 'ru';

UPDATE i18n_text
SET text = 'Magic'
WHERE id = ck_id('witcher_cc.pdf.page1.tables.magic.col.name')
  AND lang = 'en';
