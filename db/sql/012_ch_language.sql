\echo '012_ch_language.sql'
-- Узел: Выбор дополнительного языка (для Барда и Торговца)

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_ch_language' AS qu_id
                , 'questions' AS entity)
-- i18n записи для вариантов body с подстановкой языка
, ins_body_dwarvish AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body_dwarvish') AS id
       , meta.entity, 'body', v.lang, v.text
    FROM (VALUES
      ('ru', 'Выберите дополнительный язык<br><br>Ваш родной язык: Краснолюдский'),
      ('en', 'Choose an additional language<br><br>Your native language: Dwarvish')
    ) AS v(lang, text)
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
, ins_body_elder_speech AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body_elder_speech') AS id
       , meta.entity, 'body', v.lang, v.text
    FROM (VALUES
      ('ru', 'Выберите дополнительный язык<br><br>Ваш родной язык: Старшая речь'),
      ('en', 'Choose an additional language<br><br>Your native language: Elder Speech')
    ) AS v(lang, text)
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
, ins_body_northern AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body_northern') AS id
       , meta.entity, 'body', v.lang, v.text
    FROM (VALUES
      ('ru', 'Выберите дополнительный язык<br><br>Ваш родной язык: Всеобщий'),
      ('en', 'Choose an additional language<br><br>Your native language: Common Speech')
    ) AS v(lang, text)
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
, ins_body_default AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body_default') AS id
       , meta.entity, 'body', v.lang, v.text
    FROM (VALUES
      ('ru', 'Выберите дополнительный язык'),
      ('en', 'Choose an additional language')
    ) AS v(lang, text)
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
SELECT meta.qu_id
     , meta.su_su_id
     , NULL
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body_default')::uuid
     , 'single'::question_type
     , jsonb_build_object(
         'path', jsonb_build_array(
           ck_id('witcher_cc.hierarchy.identity')::text
         ),
         'body',
         jsonb_build_object(
           'jsonlogic_expression',
           jsonb_build_object(
             'if',
             jsonb_build_array(
               jsonb_build_object('==', jsonb_build_array(
                 jsonb_build_object('var', 'characterRaw.logicFields.home_language'),
                 'Dwarvish'
               )),
               ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body_dwarvish')::text,
               jsonb_build_object(
                 'if',
                 jsonb_build_array(
                   jsonb_build_object('==', jsonb_build_array(
                     jsonb_build_object('var', 'characterRaw.logicFields.home_language'),
                     'Elder Speech'
                   )),
                   ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body_elder_speech')::text,
                   jsonb_build_object(
                     'if',
                     jsonb_build_array(
                       jsonb_build_object('==', jsonb_build_array(
                         jsonb_build_object('var', 'characterRaw.logicFields.home_language'),
                         'Common Speech'
                       )),
                       ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body_northern')::text,
                       ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body_default')::text
                     )
                   )
                 )
               )
             )
           )
         )
       )
  FROM meta;

-- Правила видимости для опций
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_ch_language' AS qu_id)
-- Правило: родной язык НЕ Dwarvish
, rule_not_dwarvish AS (
  INSERT INTO rules (ru_id, name, body)
  SELECT
    ck_id('witcher_cc.rules.wcc_ch_language.not_dwarvish') AS ru_id,
    'wcc_ch_language_not_dwarvish' AS name,
    jsonb_build_object('!=', jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.logicFields.home_language'),
      'Dwarvish'
    )) AS body
  FROM meta
  ON CONFLICT (ru_id) DO NOTHING
  RETURNING ru_id
)
-- Правило: родной язык НЕ Elder Speech
, rule_not_elder_speech AS (
  INSERT INTO rules (ru_id, name, body)
  SELECT
    ck_id('witcher_cc.rules.wcc_ch_language.not_elder_speech') AS ru_id,
    'wcc_ch_language_not_elder_speech' AS name,
    jsonb_build_object('!=', jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.logicFields.home_language'),
      'Elder Speech'
    )) AS body
  FROM meta
  ON CONFLICT (ru_id) DO NOTHING
  RETURNING ru_id
)
-- Правило: родной язык НЕ Common Speech
, rule_not_common_speech AS (
  INSERT INTO rules (ru_id, name, body)
  SELECT
    ck_id('witcher_cc.rules.wcc_ch_language.not_common_speech') AS ru_id,
    'wcc_ch_language_not_common_speech' AS name,
    jsonb_build_object('!=', jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.logicFields.home_language'),
      'Common Speech'
    )) AS body
  FROM meta
  ON CONFLICT (ru_id) DO NOTHING
  RETURNING ru_id
)
SELECT 1;

-- Опции ответов
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_ch_language' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
  SELECT v.*
  FROM (VALUES
    ('ru', 1, 'Краснолюдский язык'),
    ('en', 1, 'Dwarvish'),
    ('ru', 2, 'Старшая речь'),
    ('en', 2, 'Elder Speech'),
    ('ru', 3, 'Всеобщий'),
    ('en', 3, 'Common Speech')
  ) AS v(lang, num, text)
)
, ins_label AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
           , meta.entity, meta.entity_field, vals.lang, vals.text
        FROM vals
        CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
  SELECT 'wcc_ch_language_o' || to_char(vals.num, 'FM9900') AS an_id,
         meta.su_su_id,
         meta.qu_id,
         ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
         vals.num AS sort_order,
         CASE vals.num
           WHEN 1 THEN ck_id('witcher_cc.rules.wcc_ch_language.not_dwarvish')
           WHEN 2 THEN ck_id('witcher_cc.rules.wcc_ch_language.not_elder_speech')
           WHEN 3 THEN ck_id('witcher_cc.rules.wcc_ch_language.not_common_speech')
         END AS visible_ru_ru_id,
         '{}'::jsonb AS metadata
    FROM (SELECT DISTINCT num FROM vals) AS vals
    CROSS JOIN meta
  ON CONFLICT (an_id) DO NOTHING;

-- Эффекты: добавление навыка языка в characterRaw.skills.initial[]
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_ch_language' AS qu_id)
, skill_mapping (an_id_suffix, skill_name) AS ( VALUES
    ('01', 'language_dwarvish'),
    ('02', 'language_elder_speech'),
    ('03', 'language_common_speech')
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_ch_language_o' || sm.an_id_suffix AS an_an_id,
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.initial'),
      sm.skill_name
    )
  ) AS body
FROM skill_mapping sm;

-- Правило для перехода из 011: профессия Бард или Торговец
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_ch_language' AS qu_id)
, rule_bard_or_merchant AS (
  INSERT INTO rules (ru_id, name, body)
  SELECT
    ck_id('witcher_cc.rules.wcc_ch_language.bard_or_merchant') AS ru_id,
    'wcc_ch_language_bard_or_merchant' AS name,
    jsonb_build_object('or', jsonb_build_array(
      jsonb_build_object('==', jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.logicFields.profession'),
        'Bard'
      )),
      jsonb_build_object('==', jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.logicFields.profession'),
        'Merchant'
      ))
    )) AS body
  FROM meta
  ON CONFLICT (ru_id) DO NOTHING
  RETURNING ru_id
)
SELECT 1;

-- Переходы
-- Из 011_ch_name по правилу (профессия Бард или Торговец)
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_ch_name', 'wcc_ch_language', r.ru_id, 1
    FROM (SELECT ru_id FROM rules WHERE name = 'wcc_ch_language_bard_or_merchant') r;