\echo '021_past_family_status_mage.sql'

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_family_status_mage' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
              ('ru', 'Определите положение семьи.'),
              ('en', 'Determine your family status.')
           ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
)
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Положение семьи'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Family status')
)
, ins_c AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.column_name') AS id
         , meta.entity, 'column_name', c_vals.lang, c_vals.text
      FROM c_vals
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
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
           ck_id('witcher_cc.hierarchy.family')::text,
           ck_id('witcher_cc.hierarchy.family_status')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO NOTHING;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_family_status_mage' AS qu_id
                , 'answer_options' AS entity)
, raw_data AS (
  SELECT 'ru' AS lang, raw_ru.*
    FROM (VALUES
            (1, 'Аристократы', 1.0),
            (2, 'Ремесленники', 1.0),
            (3, 'Рыцари', 1.0),
            (4, 'Торговцы', 1.0),
            (5, 'Крестьяне', 1.0),
            (6, 'Рабы или преступники', 1.0),
            (7, 'Священники', 1.0),
            (8, 'Маги', 1.0),
            (9, 'Артисты', 1.0),
            (10, 'Ученые', 1.0)
         ) AS raw_ru(num, label_txt, probability)
  UNION ALL
  SELECT 'en' AS lang, raw_en.*
    FROM (VALUES
            (1, 'Aristocracy', 1.0),
            (2, 'Artisans', 1.0),
            (3, 'Knights', 1.0),
            (4, 'Merchants', 1.0),
            (5, 'Peasants', 1.0),
            (6, 'Slaves or Prisoners', 1.0),
            (7, 'Priests', 1.0),
            (8, 'Mages', 1.0),
            (9, 'Entertainers', 1.0),
            (10, 'Academics', 1.0)
         ) AS raw_en(num, label_txt, probability)
)
, ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM00') ||'.'|| meta.entity ||'.label') AS id
       , meta.entity, 'label', raw_data.lang
       , '<td>' || to_char(raw_data.probability * 100, 'FM990.00') || '%</td><td>' || raw_data.label_txt || '</td>'
    FROM raw_data
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
, ins_lore_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM00') ||'.lore.family.status') AS id
       , 'character', 'family_status', raw_data.lang, raw_data.label_txt
    FROM raw_data
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
SELECT meta.qu_id || '_o' || to_char(raw_data.num, 'FM00') AS an_id
     , meta.su_su_id
     , meta.qu_id
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM00') ||'.'|| meta.entity ||'.label') AS label
     , raw_data.num
     , jsonb_build_object('probability', raw_data.probability)
  FROM raw_data
  CROSS JOIN meta
 WHERE raw_data.lang = 'ru'
ON CONFLICT (an_id) DO NOTHING;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_family_status_mage' AS qu_id)
, nums AS (
    SELECT generate_series(1, 10) AS num
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character'
     , meta.qu_id || '_o' || to_char(nums.num, 'FM00')
     , jsonb_build_object(
         'set',
         jsonb_build_array(
           jsonb_build_object('var','characterRaw.lore.family.status'),
           jsonb_build_object(
             'i18n_uuid',
             ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(nums.num, 'FM00') ||'.lore.family.status')::text
           )
         )
       )
  FROM nums
  CROSS JOIN meta;

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, priority)
SELECT 'wcc_past_family_personality_mage', 'wcc_past_family_status_mage', 1;
