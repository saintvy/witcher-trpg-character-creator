\echo '019_past_family_size_mage.sql'

-- Hierarchy keys for new mage-family branch
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.hierarchy.family_size'), 'hierarchy', 'path', 'ru', 'Размер семьи'),
  (ck_id('witcher_cc.hierarchy.family_size'), 'hierarchy', 'path', 'en', 'Family size'),
  (ck_id('witcher_cc.hierarchy.family_personality'), 'hierarchy', 'path', 'ru', 'Характер семьи'),
  (ck_id('witcher_cc.hierarchy.family_personality'), 'hierarchy', 'path', 'en', 'Family personality'),
  (ck_id('witcher_cc.hierarchy.magic_discovery'), 'hierarchy', 'path', 'ru', 'Обнаружение способностей'),
  (ck_id('witcher_cc.hierarchy.magic_discovery'), 'hierarchy', 'path', 'en', 'Magic discovery'),
  (ck_id('witcher_cc.hierarchy.magic_discovery_how'), 'hierarchy', 'path', 'ru', 'Как обнаружились'),
  (ck_id('witcher_cc.hierarchy.magic_discovery_how'), 'hierarchy', 'path', 'en', 'How discovered'),
  (ck_id('witcher_cc.hierarchy.magic_reaction'), 'hierarchy', 'path', 'ru', 'Реакция людей'),
  (ck_id('witcher_cc.hierarchy.magic_reaction'), 'hierarchy', 'path', 'en', 'People reaction')
ON CONFLICT (id, lang) DO NOTHING;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_family_size_mage' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
              ('ru', 'Определите размер семьи.'),
              ('en', 'Determine your family size.')
           ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
)
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Размер семьи'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Family size')
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
           ck_id('witcher_cc.hierarchy.family_size')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO NOTHING;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_family_size_mage' AS qu_id
                , 'answer_options' AS entity)
, raw_data AS (
  SELECT 'ru' AS lang, raw_ru.*
    FROM (VALUES
            (1, 'Крохотная', 10),
            (2, 'Маленькая', 20),
            (3, 'Средняя', 40),
            (4, 'Большая', 20),
            (5, 'Огромная', 10)
         ) AS raw_ru(num, label_txt, probability)
  UNION ALL
  SELECT 'en' AS lang, raw_en.*
    FROM (VALUES
            (1, 'Tiny', 10),
            (2, 'Small', 20),
            (3, 'Medium', 40),
            (4, 'Large', 20),
            (5, 'Huge', 10)
         ) AS raw_en(num, label_txt, probability)
)
, ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM00') ||'.'|| meta.entity ||'.label') AS id
       , meta.entity, 'label', raw_data.lang
       , '<td>' || to_char(raw_data.probability, 'FM990.00') || '%</td><td>' || raw_data.label_txt || '</td>'
    FROM raw_data
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
, ins_lore_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM00') ||'.lore.family.size') AS id
       , 'character', 'family_size', raw_data.lang, raw_data.label_txt
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
                , 'wcc_past_family_size_mage' AS qu_id)
, nums AS (
    SELECT generate_series(1, 5) AS num
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character'
     , meta.qu_id || '_o' || to_char(nums.num, 'FM00')
     , jsonb_build_object(
         'set',
         jsonb_build_array(
           jsonb_build_object('var','characterRaw.lore.family.size'),
           jsonb_build_object(
             'i18n_uuid',
             ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(nums.num, 'FM00') ||'.lore.family.size')::text
           )
         )
       )
  FROM nums
  CROSS JOIN meta;

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, priority)
SELECT 'wcc_past_mage_school', 'wcc_past_family_size_mage', 0;
