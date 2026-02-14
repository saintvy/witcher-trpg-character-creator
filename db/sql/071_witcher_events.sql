\echo '071_witcher_events.sql'


-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru', 'Определите, что именно произошло с вами за текущую декаду.'),
        ('en', 'Determine what happened to you during this decade.')
      ) AS v(lang, text)
      CROSS JOIN meta
  )
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Исход'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Outcome')
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
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body')
     , 'single_table'
     , jsonb_build_object(
         'dice', 'd_weighed',
         'columns', (
           SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_witcher_events' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
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
           ck_id('witcher_cc.hierarchy.witcher_events')::text
         )
       )
  FROM meta;

-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
  FROM (VALUES
    (1, 1, 0.1, 'Выгода'),
    (1, 2, 0.1, 'Союзник'),
    (1, 3, 0.1, 'Охота'),
    (1, 4, 0.7, 'Ничего'),

    (2, 1, 0.1, 'Выгода'),
    (2, 2, 0.1, 'Союзник'),
    (2, 3, 0.3, 'Охота'),
    (2, 4, 0.5, 'Ничего'),

    (3, 1, 0.2, 'Выгода'),
    (3, 2, 0.2, 'Союзник'),
    (3, 3, 0.1, 'Охота'),
    (3, 4, 0.5, 'Ничего'),

    (4, 1, 0.25, 'Выгода'),
    (4, 2, 0.225, 'Союзник'),
    (4, 3, 0.225, 'Охота'),
    (4, 4, 0.3, 'Ничего')
  ) AS raw_data_ru(group_id, num, probability, txt)

  UNION ALL

  SELECT 'en' AS lang, raw_data_en.*
  FROM (VALUES
    (1, 1, 0.1, 'Benefit'),
    (1, 2, 0.1, 'Ally'),
    (1, 3, 0.1, 'A Hunt'),
    (1, 4, 0.7, 'Nothing'),

    (2, 1, 0.1, 'Benefit'),
    (2, 2, 0.1, 'Ally'),
    (2, 3, 0.3, 'A Hunt'),
    (2, 4, 0.5, 'Nothing'),

    (3, 1, 0.2, 'Benefit'),
    (3, 2, 0.2, 'Ally'),
    (3, 3, 0.1, 'A Hunt'),
    (3, 4, 0.5, 'Nothing'),

    (4, 1, 0.5, 'Benefit'),
    (4, 2, 0.2, 'Ally'),
    (4, 3, 0.2, 'A Hunt'),
    (4, 4, 0.1, 'Nothing')
  ) AS raw_data_en(group_id, num, probability, txt)
),
vals AS (
  SELECT ('<td>' || to_char(probability*100, 'FM990.00') || '%</td>' || 
          '<td>' || txt                                  || '</td>') AS text
    , num
    , group_id
    , probability
    , lang
  FROM raw_data
)
, ins_lbl AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*vals.group_id+vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
       , meta.entity, meta.entity_field, vals.lang, vals.text
    FROM vals
    CROSS JOIN meta
)
, rules_vals(group_id, id, body) AS (
    SELECT v.group_id
         , gen_random_uuid()
         , ('{ "==":
                [
                  { "reduce":
                      [
                        { "var": ["answers.byQuestion.wcc_witcher_events_risk", []] },
                        { "var": "current" },
                        null
                      ]
                  },
                  "wcc_witcher_events_risk_o' || to_char(group_id, 'FM00') || '"
                ]
            }')::jsonb FROM (SELECT DISTINCT group_id FROM raw_data) v(group_id)
),
ins_rules AS (
  INSERT INTO rules(ru_id, body) SELECT r.id, r.body FROM rules_vals r
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT
  'wcc_witcher_events_o' || to_char(vals.group_id, 'FM00') || to_char(vals.num, 'FM00') AS an_id,
  meta.su_su_id,
  meta.qu_id,
  ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*vals.group_id+vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
  vals.num,
  r.id,
  jsonb_build_object(
           'probability', vals.probability
  )
     || CASE
          WHEN vals.num = 4 THEN
            '{"counterIncrement":{"id":"lifeEventsCounter","step":10}}'::jsonb
          ELSE '{}'::jsonb
        END AS metadata
FROM vals
CROSS JOIN meta
JOIN rules_vals r ON vals.group_id = r.group_id
ON CONFLICT (an_id) DO NOTHING;

-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id) 
  SELECT 'wcc_witcher_events_is_in_danger', 'wcc_witcher_events' UNION ALL
  SELECT 'wcc_witcher_events_danger_wounds', 'wcc_witcher_events' UNION ALL
  SELECT 'wcc_witcher_events_danger_enemy_death_reason', 'wcc_witcher_events' UNION ALL
  SELECT 'wcc_witcher_events_danger_events', 'wcc_witcher_events' UNION ALL
  SELECT 'wcc_witcher_events_danger_events_details', 'wcc_witcher_events'
  ;
  
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority) 
  SELECT 'wcc_witcher_events_danger_enemy_is_alive', 'wcc_witcher_events', 'wcc_witcher_events_danger_enemy_is_alive_o01', 1
  ;

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id)
  SELECT 'wcc_witcher_events', 'wcc_witcher_events_risk', 'wcc_witcher_events_o0104' UNION ALL
  SELECT 'wcc_witcher_events', 'wcc_witcher_events_risk', 'wcc_witcher_events_o0204' UNION ALL
  SELECT 'wcc_witcher_events', 'wcc_witcher_events_risk', 'wcc_witcher_events_o0304' UNION ALL
  SELECT 'wcc_witcher_events', 'wcc_witcher_events_risk', 'wcc_witcher_events_o0404';


WITH
  is_witcher_rule AS (SELECT ru_id, body FROM rules WHERE name = 'is_witcher')
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_life_events_fortune_or_not_details_addiction', 'wcc_witcher_events', r.ru_id, 2 FROM is_witcher_rule r UNION ALL
  SELECT 'wcc_life_events_fortune_or_not_details_curse', 'wcc_witcher_events', r.ru_id, 2 FROM is_witcher_rule r UNION ALL
  SELECT 'wcc_life_events_fortune_or_not_details_curse_monstrosity', 'wcc_witcher_events', r.ru_id, 2 FROM is_witcher_rule r;