\echo '064_witcher_events_danger_enemy_strength.sql'

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_danger_enemy_strength' AS qu_id
                , 'questions' AS entity)
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Сила'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Power')
  )
, ins_cols AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| 'column_name') AS id
         , meta.entity, 'column_name', c_vals.lang, c_vals.text
      FROM c_vals
      CROSS JOIN meta
  )

INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
SELECT meta.qu_id
     , meta.su_su_id
     , NULL
     , NULL
     , 'single_table'
     , jsonb_build_object(
         'dice', 'd_weighed',
         'columns', (
           SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_witcher_events_danger_enemy_strength' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
           FROM (SELECT DISTINCT num FROM c_vals) AS cols
         ),
         'path', jsonb_build_array(
           ck_id('witcher_cc.hierarchy.life_events')::text,
           jsonb_build_object('jsonlogic_expression', jsonb_build_object('cat', jsonb_build_array(
              jsonb_build_object('var', 'counters.lifeEventsCounter'),
              '-',
              jsonb_build_object('+', jsonb_build_array(
                jsonb_build_object('var', 'counters.lifeEventsCounter'),
                10
              ))
            ))),
           ck_id('witcher_cc.hierarchy.witcher_events_danger')::text,
           ck_id('witcher_cc.hierarchy.witcher_events_danger_enemy')::text,
           ck_id('witcher_cc.hierarchy.witcher_events_danger_enemy_strength')::text
         )
       )
  FROM meta;

-- Ответы (50/50)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_danger_enemy_strength' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
  FROM (VALUES
    (1, 0.2, 'Социальное положение'),
    (2, 0.2, 'Знание'),
    (3, 0.2, 'Физическая сила'),
    (4, 0.2, 'Подручные'),
    (5, 0.2, 'Магия')
  ) AS raw_data_ru(num, probability, txt)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
  FROM (VALUES
    (1, 0.2, 'Social standing'),
    (2, 0.2, 'Knowledge'),
    (3, 0.2, 'Physical'),
    (4, 0.2, 'Minions'),
    (5, 0.2, 'Magic')
  ) AS raw_data_en(num, probability, txt)
),

vals AS (
  SELECT
    ('<td>' || to_char(probability*100, 'FM990.00') || '%</td>'
     || '<td>' || txt || '</td>') AS text,
    num, probability, lang, txt
  FROM raw_data
)
, ins_lbl AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
       , meta.entity, meta.entity_field, vals.lang, vals.text
    FROM vals
    CROSS JOIN meta
)
, ins_lbl_value AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field || '_value') AS id
       , meta.entity, meta.entity_field || '_value', vals.lang, vals.txt
    FROM vals
    CROSS JOIN meta
)

INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
SELECT
  'wcc_witcher_events_danger_enemy_strength_o' || to_char(vals.num, 'FM00') AS an_id,
  meta.su_su_id,
  meta.qu_id,
  ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
  vals.num,
  jsonb_build_object(
           'probability', vals.probability
  )
FROM vals
CROSS JOIN meta
ON CONFLICT (an_id) DO NOTHING;

-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id) 
  SELECT 'wcc_witcher_events_danger_enemy_reason', 'wcc_witcher_events_danger_enemy_strength'
  ;