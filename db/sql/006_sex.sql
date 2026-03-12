\echo '006_sex.sql'
-- Узел: Пол (Sex)

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_sex' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
              ('ru', 'Определите пол персонажа.'),
              ('en', 'Choose character sex.')
           ) AS v(lang, text)
      CROSS JOIN meta
)
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Пол'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Sex')
)
, ins_c AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.column_name') AS id
         , meta.entity, 'column_name', c_vals.lang, c_vals.text
      FROM c_vals
      CROSS JOIN meta
)
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
SELECT meta.qu_id
     , meta.su_su_id
     , NULL
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body')
     , 'single_table'
     , jsonb_build_object(
         'dice', 'd_weighed',
         'columns', (
           SELECT jsonb_agg(ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(num, 'FM9900') ||'.'|| meta.entity ||'.column_name')::text ORDER BY num)
           FROM (SELECT DISTINCT num FROM c_vals) cols
         ),
         'path', jsonb_build_array(
           ck_id('witcher_cc.hierarchy.identity')::text,
           ck_id('witcher_cc.hierarchy.gender')::text
         )
       )
  FROM meta;

-- Правило: not is_witcher
WITH is_witcher_rule AS (
  SELECT body
    FROM rules
   WHERE name = 'is_witcher'
   ORDER BY ru_id
   LIMIT 1
)
INSERT INTO rules (ru_id, name, body)
SELECT ck_id('witcher_cc.rules.is_not_witcher') AS ru_id
     , 'is_not_witcher' AS name
     , jsonb_build_object('!', is_witcher_rule.body) AS body
  FROM is_witcher_rule
ON CONFLICT (ru_id) DO UPDATE
SET body = EXCLUDED.body;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_sex' AS qu_id
                , 'answer_options' AS entity)
, raw_data AS (
  SELECT 'ru' AS lang, raw_ru.*
    FROM (VALUES
            (1, 'Мужской', 1.0, 'is_not_witcher', 'male',   'Male'),
            (2, 'Женский', 1.0, 'is_not_witcher', 'female', 'Female'),
            (3, 'Мужской', 1.0, 'is_witcher',     'male',   'Male'),
            (4, 'Женский', 0.0, 'is_witcher',     'female', 'Female')
         ) AS raw_ru(num, label_txt, probability, rule_name, sex_key, sex_logic)
  UNION ALL
  SELECT 'en' AS lang, raw_en.*
    FROM (VALUES
            (1, 'Male',   1.0, 'is_not_witcher', 'male',   'Male'),
            (2, 'Female', 1.0, 'is_not_witcher', 'female', 'Female'),
            (3, 'Male',   1.0, 'is_witcher',     'male',   'Male'),
            (4, 'Female', 0.0, 'is_witcher',     'female', 'Female')
         ) AS raw_en(num, label_txt, probability, rule_name, sex_key, sex_logic)
)
, ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM00') ||'.'|| meta.entity ||'.label') AS id
       , meta.entity, 'label', raw_data.lang
       , '<td style="color: grey;">' || to_char(raw_data.probability * 100, 'FM990.00') || '%</td><td>' || raw_data.label_txt || '</td>'
    FROM raw_data
    CROSS JOIN meta
)
, ins_sex_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| raw_data.sex_key ||'.character.sex') AS id
       , 'character', 'sex', raw_data.lang
       , CASE
           WHEN raw_data.sex_key = 'male' AND raw_data.lang = 'ru' THEN 'Мужской'
           WHEN raw_data.sex_key = 'female' AND raw_data.lang = 'ru' THEN 'Женский'
           WHEN raw_data.sex_key = 'male' AND raw_data.lang = 'en' THEN 'Male'
           ELSE 'Female'
         END
    FROM (SELECT DISTINCT lang, sex_key FROM raw_data) raw_data
    CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT meta.qu_id || '_o' || to_char(raw_data.num, 'FM00') AS an_id
     , meta.su_su_id
     , meta.qu_id
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM00') ||'.'|| meta.entity ||'.label') AS label
     , raw_data.num
     , (SELECT ru_id FROM rules WHERE name = raw_data.rule_name ORDER BY ru_id LIMIT 1) AS visible_ru_ru_id
     , jsonb_build_object('probability', raw_data.probability)
  FROM raw_data
  CROSS JOIN meta
 WHERE raw_data.lang = 'ru'
ON CONFLICT (an_id) DO NOTHING;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_sex' AS qu_id)
, vals AS (
    SELECT *
      FROM (VALUES
              (1, 'male', 'Male'),
              (2, 'female', 'Female'),
              (3, 'male', 'Male'),
              (4, 'female', 'Female')
           ) AS v(num, sex_key, sex_logic)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character' AS scope
     , meta.qu_id || '_o' || to_char(vals.num, 'FM00') AS an_an_id
     , jsonb_build_object(
         'set',
         jsonb_build_array(
           jsonb_build_object('var','characterRaw.sex'),
           jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| vals.sex_key ||'.character.sex')::text)
         )
       ) AS body
  FROM vals
 CROSS JOIN meta
UNION ALL
SELECT 'character' AS scope
     , meta.qu_id || '_o' || to_char(vals.num, 'FM00') AS an_an_id
     , jsonb_build_object(
         'set',
         jsonb_build_array(
           jsonb_build_object('var','characterRaw.logicFields.sex'),
           vals.sex_logic
         )
       ) AS body
  FROM vals
 CROSS JOIN meta;

-- Связи: нода пола перед профессией
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_race', 'wcc_sex';
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_witcher_school', 'wcc_sex';
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, priority)
  SELECT 'wcc_gnome_craft_skills', 'wcc_sex', 0;
