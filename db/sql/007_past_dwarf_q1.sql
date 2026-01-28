\echo '007_past_dwarf_q1.sql'
-- Узел: Родина краснолюда

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_dwarf_q1' AS qu_id
                , 'questions' AS entity
                , 'single'::question_type AS qtype)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| v.entity_field) AS id
           , meta.entity, v.entity_field, v.lang, v.text
        FROM (VALUES
                ('ru',
'Вы выбрали расу краснолюда. Правила говорят, что родина краснолюда - это всегда Махакам (+1 к Изготовлению). Но при желании вы можете сделать '
  || 'выбор самостоятельно', 'body'),
                ('en',
'You''ve chosen the dwarf race. The rules state that the dwarf homeland is always Mahakam (+1 to Crafting). But if you wish, you can make your '
  || 'own choice.', 'body')
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
                , 'wcc_past_dwarf_q1' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
  SELECT v.*
  FROM (VALUES
    ('ru', 1, 'Я согласен на родину по-умолчанию - Махакам. (+1 к Изготовлению)'),
    ('en', 1, 'I agree to the default homeland - Mahakam. (+1 to Crafting)'),
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
  SELECT 'wcc_past_dwarf_q1_o' || to_char(vals.num, 'FM9900') AS an_id,
         meta.su_su_id,
         meta.qu_id,
         ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
         vals.num AS sort_order,
         '{}'::jsonb AS metadata
    FROM vals
    CROSS JOIN meta
  ON CONFLICT (an_id) DO NOTHING;
-- Эффекты для варианта ответа: Я согласен на родину по-умолчанию - Махакам
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_dwarf_q1' AS qu_id
                , 'character' AS entity)
, ins_homeland AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o01' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES
        ('ru', 'Махакам'),
        ('en', 'Mahakam')
      ) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_home_language AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o01' ||'.'|| meta.entity ||'.'|| 'home_language') AS id
         , meta.entity, 'home_language', v.lang, v.text
      FROM (VALUES
        ('ru', 'Краснолюдский'),
        ('en', 'Dwarvish')
      ) AS v(lang, text)
      CROSS JOIN meta
  )
INSERT INTO effects (scope, an_an_id, body)
-- Эффект: +1 к Изготовлению (Crafting)
SELECT 'character', 'wcc_past_dwarf_q1_o01',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.crafting.bonus'),
      1
    )
  )
FROM meta UNION ALL
-- Эффект: Родина - Махакам
SELECT 'character', 'wcc_past_dwarf_q1_o01',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.lore.homeland'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o01' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
    )
  )
FROM meta UNION ALL
-- Эффект: Родной язык - Краснолюдский
SELECT 'character', 'wcc_past_dwarf_q1_o01',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.lore.home_language'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o01' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
    )
  )
FROM meta UNION ALL
-- Эффект: logicFields.home_language = 'Dwarvish'
SELECT 'character', 'wcc_past_dwarf_q1_o01',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.logicFields.home_language'),
      'Dwarvish'
    )
  )
FROM meta UNION ALL
-- Эффект: +8 к Краснолюдскому языку (language_dwarvish)
SELECT 'character', 'wcc_past_dwarf_q1_o01',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.language_dwarvish.bonus'),
      8
    )
  )
FROM meta;

-- Связи
-- Переход из профессии (через правило is_dwarf) - добавлен в 090_profession.sql
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_profession', 'wcc_past_dwarf_q1', r.ru_id, 1
    FROM (SELECT ru_id FROM rules WHERE name = 'is_dwarf') r;