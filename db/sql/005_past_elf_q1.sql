\echo '005_past_elf_q1.sql'
-- Узел: Родина эльфа

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_elf_q1' AS qu_id
                , 'questions' AS entity
                , 'single'::question_type AS qtype)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| v.entity_field) AS id
           , meta.entity, v.entity_field, v.lang, v.text
        FROM (VALUES
                ('ru',
'Вы выбрали расу эльфа. Правила говорят, что родина эльфа - это всегда Доль Блатанна (+1 к Этикету). Но при желании вы '
  || 'можете сделать выбор самостоятельно', 'body'),
                ('en',
'You''ve chosen the elf race. The rules state that the elf homeland is always Dol Blathanna (+1 to Etiquette). But if you '
  || 'wish, you can make your own choice.', 'body')
             ) AS v(lang, text, entity_field)
        CROSS JOIN meta
      RETURNING id AS body_id
)
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
  SELECT meta.qu_id
       , meta.su_su_id
       , NULL
       , (SELECT DISTINCT body_id FROM ins_body)
       , meta.qtype
       , jsonb_build_object(
           'dice', 'd0',
           'path', jsonb_build_array(
             ck_id('witcher_cc.hierarchy.identity')::text,
             ck_id('witcher_cc.hierarchy.homeland_nonhuman')::text
           )
         )
     FROM meta;
-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_elf_q1' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
  SELECT v.*
  FROM (VALUES
    ('ru', 1, 'Я согласен на родину по-умолчанию - Доль Блатанна. (+1 к Этикету)'),
    ('en', 1, 'I agree to the default homeland - Dol Blathanna. (+1 to Etiquette)'),
    ('ru', 2, 'Я хочу выбрать что-то из земель старших народов.'),
    ('en', 2, 'I want to choose something from the lands of the elder peoples.'),
    ('ru', 3, 'Я хочу выбрать что-то из людских поселений.'),
    ('en', 3, 'I want to choose something from human settlements.')
  ) AS v(lang, num, text)
)
, ins_label AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
           , meta.entity, meta.entity_field, vals.lang, vals.text
        FROM vals
        CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
  SELECT 'wcc_past_elf_q1_o' || to_char(vals.num, 'FM9900') AS an_id,
         meta.su_su_id,
         meta.qu_id,
         ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
         vals.num AS sort_order,
         '{}'::jsonb AS metadata
    FROM vals
    CROSS JOIN meta
  ON CONFLICT (an_id) DO NOTHING;
-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id)
  SELECT 'wcc_race', 'wcc_past_elf_q1', 'wcc_race_elf';