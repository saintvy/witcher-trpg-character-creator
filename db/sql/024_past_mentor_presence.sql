\echo '024_past_mentor_presence.sql'

-- Hierarchy keys for mentor branch
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.hierarchy.mentor'), 'hierarchy', 'path', 'ru', 'Наставник'),
  (ck_id('witcher_cc.hierarchy.mentor'), 'hierarchy', 'path', 'en', 'Mentor'),
  (ck_id('witcher_cc.hierarchy.mentor_presence'), 'hierarchy', 'path', 'ru', 'Наличие наставника'),
  (ck_id('witcher_cc.hierarchy.mentor_presence'), 'hierarchy', 'path', 'en', 'Mentor presence'),
  (ck_id('witcher_cc.hierarchy.mentor_personality'), 'hierarchy', 'path', 'ru', 'Характер'),
  (ck_id('witcher_cc.hierarchy.mentor_personality'), 'hierarchy', 'path', 'en', 'Personality'),
  (ck_id('witcher_cc.hierarchy.mentor_value'), 'hierarchy', 'path', 'ru', 'Что ценит'),
  (ck_id('witcher_cc.hierarchy.mentor_value'), 'hierarchy', 'path', 'en', 'Value'),
  (ck_id('witcher_cc.hierarchy.mentor_lifestyle'), 'hierarchy', 'path', 'ru', 'Стиль жизни'),
  (ck_id('witcher_cc.hierarchy.mentor_lifestyle'), 'hierarchy', 'path', 'en', 'Lifestyle'),
  (ck_id('witcher_cc.hierarchy.mentor_hatred'), 'hierarchy', 'path', 'ru', 'Что ненавидит'),
  (ck_id('witcher_cc.hierarchy.mentor_hatred'), 'hierarchy', 'path', 'en', 'Hatred'),
  (ck_id('witcher_cc.hierarchy.mentor_teaching_style'), 'hierarchy', 'path', 'ru', 'Стиль преподавания'),
  (ck_id('witcher_cc.hierarchy.mentor_teaching_style'), 'hierarchy', 'path', 'en', 'Teaching style'),
  (ck_id('witcher_cc.hierarchy.mentor_key_event'), 'hierarchy', 'path', 'ru', 'Важное событие'),
  (ck_id('witcher_cc.hierarchy.mentor_key_event'), 'hierarchy', 'path', 'en', 'Important event'),
  (ck_id('witcher_cc.hierarchy.mentor_relationship_end'), 'hierarchy', 'path', 'ru', 'Завершение отношений'),
  (ck_id('witcher_cc.hierarchy.mentor_relationship_end'), 'hierarchy', 'path', 'en', 'Relationship ending')
ON CONFLICT (id, lang) DO NOTHING;

-- Visibility rules by mage school
INSERT INTO rules (ru_id, name, body)
SELECT
  ck_id('witcher_cc.rules.is_mentor_school_aretuza'),
  'is_mentor_school_aretuza',
  jsonb_build_object(
    'or',
    jsonb_build_array(
      jsonb_build_object('==', jsonb_build_array(jsonb_build_object('var', 'characterRaw.logic_fields.school'), 'aretuza')),
      jsonb_build_object('==', jsonb_build_array(jsonb_build_object('var', 'characterRaw.logicFields.school'), 'aretuza'))
    )
  )
UNION ALL
SELECT
  ck_id('witcher_cc.rules.is_mentor_school_ban_ard'),
  'is_mentor_school_ban_ard',
  jsonb_build_object(
    'or',
    jsonb_build_array(
      jsonb_build_object('==', jsonb_build_array(jsonb_build_object('var', 'characterRaw.logic_fields.school'), 'ban_ard')),
      jsonb_build_object('==', jsonb_build_array(jsonb_build_object('var', 'characterRaw.logicFields.school'), 'ban_ard'))
    )
  )
UNION ALL
SELECT
  ck_id('witcher_cc.rules.is_mentor_school_minor'),
  'is_mentor_school_minor',
  jsonb_build_object(
    'or',
    jsonb_build_array(
      jsonb_build_object('==', jsonb_build_array(jsonb_build_object('var', 'characterRaw.logic_fields.school'), 'minor_academia')),
      jsonb_build_object('==', jsonb_build_array(jsonb_build_object('var', 'characterRaw.logicFields.school'), 'minor_academia'))
    )
  )
UNION ALL
SELECT
  ck_id('witcher_cc.rules.is_mentor_school_gweison_or_imperial'),
  'is_mentor_school_gweison_or_imperial',
  jsonb_build_object(
    'or',
    jsonb_build_array(
      jsonb_build_object('==', jsonb_build_array(jsonb_build_object('var', 'characterRaw.logic_fields.school'), 'gweison_haul')),
      jsonb_build_object('==', jsonb_build_array(jsonb_build_object('var', 'characterRaw.logicFields.school'), 'gweison_haul')),
      jsonb_build_object('==', jsonb_build_array(jsonb_build_object('var', 'characterRaw.logic_fields.school'), 'imperial_magic_academy')),
      jsonb_build_object('==', jsonb_build_array(jsonb_build_object('var', 'characterRaw.logicFields.school'), 'imperial_magic_academy'))
    )
  )
ON CONFLICT (ru_id) DO UPDATE SET body = EXCLUDED.body;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_mentor_presence' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
              ('ru', 'Были ли вы подопечным опытного мага?'),
              ('en', 'Were you an Apprentice under an experienced Mentor?')
           ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
)
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Наличие наставника'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Apprentice')
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
           ck_id('witcher_cc.hierarchy.mentor')::text,
           ck_id('witcher_cc.hierarchy.mentor_presence')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO NOTHING;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_mentor_presence' AS qu_id
                , 'answer_options' AS entity)
, raw_data AS (
  SELECT 'ru' AS lang, raw_ru.*
    FROM (VALUES
            (1, 'Да',  0.5::numeric,        'is_mentor_school_aretuza'),
            (2, 'Нет', 0.5::numeric,        'is_mentor_school_aretuza'),
            (3, 'Да',  0.3333333333::numeric, 'is_mentor_school_ban_ard'),
            (4, 'Нет', 0.6666666667::numeric, 'is_mentor_school_ban_ard'),
            (5, 'Да',  0.6666666667::numeric, 'is_mentor_school_gweison_or_imperial'),
            (6, 'Нет', 0.3333333333::numeric, 'is_mentor_school_gweison_or_imperial'),
            (7, 'Да',  1.0::numeric,        'is_mentor_school_minor'),
            (8, 'Нет', 0.0::numeric,        'is_mentor_school_minor')
         ) AS raw_ru(num, label_txt, probability, rule_name)
  UNION ALL
  SELECT 'en' AS lang, raw_en.*
    FROM (VALUES
            (1, 'Yes', 0.5::numeric,        'is_mentor_school_aretuza'),
            (2, 'No',  0.5::numeric,        'is_mentor_school_aretuza'),
            (3, 'Yes', 0.3333333333::numeric, 'is_mentor_school_ban_ard'),
            (4, 'No',  0.6666666667::numeric, 'is_mentor_school_ban_ard'),
            (5, 'Yes', 0.6666666667::numeric, 'is_mentor_school_gweison_or_imperial'),
            (6, 'No',  0.3333333333::numeric, 'is_mentor_school_gweison_or_imperial'),
            (7, 'Yes', 1.0::numeric,        'is_mentor_school_minor'),
            (8, 'No',  0.0::numeric,        'is_mentor_school_minor')
         ) AS raw_en(num, label_txt, probability, rule_name)
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
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM00') ||'.lore.mentor.has_mentor') AS id
       , 'character', 'mentor_has_mentor', raw_data.lang, raw_data.label_txt
    FROM raw_data
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
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
                , 'wcc_past_mentor_presence' AS qu_id)
, nums AS (
  SELECT generate_series(1, 8) AS num
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character'
     , meta.qu_id || '_o' || to_char(nums.num, 'FM00')
     , jsonb_build_object(
         'set',
         jsonb_build_array(
           jsonb_build_object('var','characterRaw.lore.mentor.has_mentor'),
           jsonb_build_object(
             'i18n_uuid',
             ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(nums.num, 'FM00') ||'.lore.mentor.has_mentor')::text
           )
         )
       )
  FROM nums
 CROSS JOIN meta;

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, priority)
SELECT 'wcc_past_magic_reaction', 'wcc_past_mentor_presence', 1;

