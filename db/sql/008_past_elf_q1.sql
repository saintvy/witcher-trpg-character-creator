\echo '008_past_elf_q1.sql'
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

-- Эффекты для опции по умолчанию (o01): Доль Блатанна
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_elf_q1' AS qu_id
                , 'character' AS entity)
-- i18n записи для родины
, ins_homeland AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o01' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Доль Блатанна'), ('en', 'Dol Blathanna')) AS v(lang, text)
      CROSS JOIN meta
  )
-- i18n записи для родного языка: Старшая речь
, ins_lang_elder_speech AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elder_speech' ||'.'|| meta.entity ||'.'|| 'home_language') AS id
         , meta.entity, 'home_language', v.lang, v.text
      FROM (VALUES ('ru', 'Старшая речь'), ('en', 'Elder Speech')) AS v(lang, text)
      CROSS JOIN meta
  )
INSERT INTO effects (scope, an_an_id, body)
-- 01: +1 к Этикету (Social Etiquette)
SELECT 'character', 'wcc_past_elf_q1_o01',
  jsonb_build_object('when', '{"!==":[{"var":"characterRaw.logicFields.race"},"Witcher"]}'::jsonb, 'inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.social_etiquette.bonus'), 1
  ))
FROM meta UNION ALL
-- 01: Родина - Доль Блатанна
SELECT 'character', 'wcc_past_elf_q1_o01',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.homeland'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o01' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
  ))
FROM meta UNION ALL
-- 01: Родной язык - Старшая речь
SELECT 'character', 'wcc_past_elf_q1_o01',
  jsonb_build_object('when', '{"!==":[{"var":"characterRaw.logicFields.race"},"Witcher"]}'::jsonb, 'set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.home_language'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elder_speech' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
  ))
FROM meta UNION ALL
-- 01: +8 к Старшей речи (language_elder_speech)
SELECT 'character', 'wcc_past_elf_q1_o01',
  jsonb_build_object('when', '{"!==":[{"var":"characterRaw.logicFields.race"},"Witcher"]}'::jsonb, 'inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.language_elder_speech.bonus'), 8
  ))
FROM meta UNION ALL
-- 01: Логическое поле родного языка - Elder Speech
SELECT 'character', 'wcc_past_elf_q1_o01',
  jsonb_build_object(
    'when', '{"!==":[{"var":"characterRaw.logicFields.race"},"Witcher"]}'::jsonb,
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.logicFields.home_language'),
      'Elder Speech'
    )
  )
FROM meta;

-- Связи
-- Переход из профессии (через правило is_elf) - добавлен в 090_profession.sql
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_profession', 'wcc_past_elf_q1', r.ru_id, 1
    FROM (SELECT ru_id FROM rules WHERE name = 'is_elf') r;