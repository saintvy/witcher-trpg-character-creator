\echo '099_pdf_page4_and_magic_templates_i18n.sql'

-- Magic (shop tooltips) templates
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.magic.hex.tooltip_tpl'), 'magic', 'hex.tooltip_tpl', 'ru', E'<b>Описание:</b> {effect}\n<b>Как снять:</b> {remove}\n<b>Ингредиенты ритуала снятия:</b>{components}'),
  (ck_id('witcher_cc.magic.hex.tooltip_tpl'), 'magic', 'hex.tooltip_tpl', 'en', E'<b>Description:</b> {effect}\n<b>How to remove:</b> {remove}\n<b>Removal ritual ingredients:</b>{components}'),

  (ck_id('witcher_cc.magic.ritual.effect_tpl'), 'magic', 'ritual.effect_tpl', 'ru', E'<b>Описание:</b> {effect}\n<b>Ингредиенты:</b>{ingredients}'),
  (ck_id('witcher_cc.magic.ritual.effect_tpl'), 'magic', 'ritual.effect_tpl', 'en', E'<b>Description:</b> {effect}\n<b>Ingredients:</b>{ingredients}'),

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
  (ck_id('witcher_cc.pdf.page4.gifts.cost.fullAction'), 'pdf', 'page4.gifts.cost.fullAction', 'en', 'Full action'),

  -- PDF page 4: invocations title for druids
  (ck_id('witcher_cc.pdf.page4.invocations_druid.title'), 'pdf', 'page4.invocations.druid.title', 'ru', 'Инвокации друида'),
  (ck_id('witcher_cc.pdf.page4.invocations_druid.title'), 'pdf', 'page4.invocations.druid.title', 'en', 'Druid Invocations')
ON CONFLICT (id, lang) DO UPDATE
  SET text = EXCLUDED.text;
