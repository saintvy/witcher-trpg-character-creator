\echo '099_pdf_page4_and_magic_templates_i18n.sql'

-- Magic (shop tooltips) templates
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.magic.hex.tooltip_tpl'), 'magic', 'hex.tooltip_tpl', 'ru', E'Описание: {effect}\nКак снять: {remove}\nИнгредиенты ритуала снятия:{components}'),
  (ck_id('witcher_cc.magic.hex.tooltip_tpl'), 'magic', 'hex.tooltip_tpl', 'en', E'Description: {effect}\nHow to remove: {remove}\nRemoval ritual ingredients:{components}'),

  (ck_id('witcher_cc.magic.ritual.effect_tpl'), 'magic', 'ritual.effect_tpl', 'ru', E'Описание: {effect}\nИнгредиенты:{ingredients}'),
  (ck_id('witcher_cc.magic.ritual.effect_tpl'), 'magic', 'ritual.effect_tpl', 'en', E'Description: {effect}\nIngredients:{ingredients}'),

  -- PDF page 4: gifts table
  (ck_id('witcher_cc.pdf.page4.gifts.col.name'), 'pdf', 'page4.gifts.col.name', 'ru', 'Имя'),
  (ck_id('witcher_cc.pdf.page4.gifts.col.name'), 'pdf', 'page4.gifts.col.name', 'en', 'Name'),
  (ck_id('witcher_cc.pdf.page4.gifts.col.group'), 'pdf', 'page4.gifts.col.group', 'ru', 'Группа'),
  (ck_id('witcher_cc.pdf.page4.gifts.col.group'), 'pdf', 'page4.gifts.col.group', 'en', 'Group'),
  (ck_id('witcher_cc.pdf.page4.gifts.col.sl'), 'pdf', 'page4.gifts.col.sl', 'ru', 'СЛ'),
  (ck_id('witcher_cc.pdf.page4.gifts.col.sl'), 'pdf', 'page4.gifts.col.sl', 'en', 'DC'),
  (ck_id('witcher_cc.pdf.page4.gifts.col.vigor'), 'pdf', 'page4.gifts.col.vigor', 'ru', 'Вын'),
  (ck_id('witcher_cc.pdf.page4.gifts.col.vigor'), 'pdf', 'page4.gifts.col.vigor', 'en', 'STA'),
  (ck_id('witcher_cc.pdf.page4.gifts.col.cost'), 'pdf', 'page4.gifts.col.cost', 'ru', 'Затраты'),
  (ck_id('witcher_cc.pdf.page4.gifts.col.cost'), 'pdf', 'page4.gifts.col.cost', 'en', 'Cost'),
  (ck_id('witcher_cc.pdf.page4.gifts.cost.action'), 'pdf', 'page4.gifts.cost.action', 'ru', 'Действие'),
  (ck_id('witcher_cc.pdf.page4.gifts.cost.action'), 'pdf', 'page4.gifts.cost.action', 'en', 'Action'),
  (ck_id('witcher_cc.pdf.page4.gifts.cost.fullAction'), 'pdf', 'page4.gifts.cost.fullAction', 'ru', 'Действие полного хода'),
  (ck_id('witcher_cc.pdf.page4.gifts.cost.fullAction'), 'pdf', 'page4.gifts.cost.fullAction', 'en', 'Full action')
ON CONFLICT (id, lang) DO UPDATE
  SET text = EXCLUDED.text;

