\echo '159_cloud_pdf_i18n_extras.sql'

-- Cloud PDF extra labels that are not covered by legacy page1/page2/page4 keysets.
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.pdf.cloud.subtitle'), 'pdf', 'cloud.subtitle', 'ru', 'Облачный экспорт'),
  (ck_id('witcher_cc.pdf.cloud.subtitle'), 'pdf', 'cloud.subtitle', 'en', 'Cloud export'),

  (ck_id('witcher_cc.pdf.cloud.base_word'), 'pdf', 'cloud.base_word', 'ru', 'Основа'),
  (ck_id('witcher_cc.pdf.cloud.base_word'), 'pdf', 'cloud.base_word', 'en', 'Base'),

  (ck_id('witcher_cc.pdf.cloud.cols.value'), 'pdf', 'cloud.cols.value', 'ru', 'Знач.'),
  (ck_id('witcher_cc.pdf.cloud.cols.value'), 'pdf', 'cloud.cols.value', 'en', 'Val'),
  (ck_id('witcher_cc.pdf.cloud.cols.bonus'), 'pdf', 'cloud.cols.bonus', 'ru', 'Бонус'),
  (ck_id('witcher_cc.pdf.cloud.cols.bonus'), 'pdf', 'cloud.cols.bonus', 'en', 'Bonus'),
  (ck_id('witcher_cc.pdf.cloud.cols.field'), 'pdf', 'cloud.cols.field', 'ru', 'Поле'),
  (ck_id('witcher_cc.pdf.cloud.cols.field'), 'pdf', 'cloud.cols.field', 'en', 'Field'),
  (ck_id('witcher_cc.pdf.cloud.cols.note'), 'pdf', 'cloud.cols.note', 'ru', 'Примечание'),
  (ck_id('witcher_cc.pdf.cloud.cols.note'), 'pdf', 'cloud.cols.note', 'en', 'Note'),

  (ck_id('witcher_cc.pdf.cloud.sections.skills'), 'pdf', 'cloud.sections.skills', 'ru', 'Навыки'),
  (ck_id('witcher_cc.pdf.cloud.sections.skills'), 'pdf', 'cloud.sections.skills', 'en', 'Skills'),
  (ck_id('witcher_cc.pdf.cloud.sections.perks'), 'pdf', 'cloud.sections.perks', 'ru', 'Перки'),
  (ck_id('witcher_cc.pdf.cloud.sections.perks'), 'pdf', 'cloud.sections.perks', 'en', 'Perks'),
  (ck_id('witcher_cc.pdf.cloud.sections.magic'), 'pdf', 'cloud.sections.magic', 'ru', 'Магия'),
  (ck_id('witcher_cc.pdf.cloud.sections.magic'), 'pdf', 'cloud.sections.magic', 'en', 'Magic'),

  (ck_id('witcher_cc.pdf.cloud.stats.abbr.LUCK'), 'pdf', 'cloud.stats.abbr.LUCK', 'ru', 'УДА'),
  (ck_id('witcher_cc.pdf.cloud.stats.abbr.LUCK'), 'pdf', 'cloud.stats.abbr.LUCK', 'en', 'LUCK'),
  (ck_id('witcher_cc.pdf.cloud.stats.abbr.VIGOR'), 'pdf', 'cloud.stats.abbr.VIGOR', 'ru', 'ЭНЕРГИЯ'),
  (ck_id('witcher_cc.pdf.cloud.stats.abbr.VIGOR'), 'pdf', 'cloud.stats.abbr.VIGOR', 'en', 'VIGOR'),

  (ck_id('witcher_cc.pdf.cloud.prof.branch_col'), 'pdf', 'cloud.prof.branch_col', 'ru', 'Ветка'),
  (ck_id('witcher_cc.pdf.cloud.prof.branch_col'), 'pdf', 'cloud.prof.branch_col', 'en', 'Branch'),

  (ck_id('witcher_cc.pdf.cloud.page4.titles.spells_signs'), 'pdf', 'cloud.page4.titles.spells_signs', 'ru', 'Заклинания / Знаки'),
  (ck_id('witcher_cc.pdf.cloud.page4.titles.spells_signs'), 'pdf', 'cloud.page4.titles.spells_signs', 'en', 'Spells / Signs'),
  (ck_id('witcher_cc.pdf.cloud.page4.cols.ingredients'), 'pdf', 'cloud.page4.cols.ingredients', 'ru', 'Компоненты'),
  (ck_id('witcher_cc.pdf.cloud.page4.cols.ingredients'), 'pdf', 'cloud.page4.cols.ingredients', 'en', 'Components'),
  (ck_id('witcher_cc.pdf.cloud.page4.cols.remove_components'), 'pdf', 'cloud.page4.cols.remove_components', 'ru', 'Компоненты для снятия'),
  (ck_id('witcher_cc.pdf.cloud.page4.cols.remove_components'), 'pdf', 'cloud.page4.cols.remove_components', 'en', 'Remove components'),
  (ck_id('witcher_cc.pdf.cloud.page4.cols.remove_instructions'), 'pdf', 'cloud.page4.cols.remove_instructions', 'ru', 'Как снять'),
  (ck_id('witcher_cc.pdf.cloud.page4.cols.remove_instructions'), 'pdf', 'cloud.page4.cols.remove_instructions', 'en', 'How to remove')
ON CONFLICT (id, lang) DO UPDATE
  SET text = EXCLUDED.text;

