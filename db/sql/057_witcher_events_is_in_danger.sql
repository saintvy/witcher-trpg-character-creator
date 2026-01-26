\echo '057_witcher_events_is_in_danger.sql'
-- Узел: Каково ваше нынешнее положение?

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_is_in_danger' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru', 'Попал ли ведьмак в неприятности в ту декаду? Правила подразумевают обязательный бросок кубика.'),
        ('en', 'Did the witcher get into trouble during that decade? This step requires a mandatory dice roll.')
      ) AS v(lang, text)
      CROSS JOIN meta
  )
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Ответ'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Answer')
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
           SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_witcher_events_is_in_danger' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
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
           ck_id('witcher_cc.hierarchy.witcher_events_is_in_danger')::text
         )
       )
  FROM meta;

-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_is_in_danger' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
  FROM (VALUES
    (1, 1, 0.9, 'Всё обошлось'),
    (1, 2, 0.03, 'Последствия - Раны'),
    (1, 3, 0.03, 'Последствия - Опасные события'),
    (1, 4, 0.04, 'Последствия - Враг'),

    (2, 1, 0.75, 'Всё обошлось'),
    (2, 2, 0.075, 'Последствия - Раны'),
    (2, 3, 0.075, 'Последствия - Опасные события'),
    (2, 4, 0.1, 'Последствия - Враг'),

    (3, 1, 0.5, 'Всё обошлось'),
    (3, 2, 0.15, 'Последствия - Раны'),
    (3, 3, 0.15, 'Последствия - Опасные события'),
    (3, 4, 0.2, 'Последствия - Враг'),

    (4, 1, 0.25, 'Всё обошлось'),
    (4, 2, 0.225, 'Последствия - Раны'),
    (4, 3, 0.225, 'Последствия - Опасные события'),
    (4, 4, 0.3, 'Последствия - Враг')
  ) AS raw_data_ru(group_id, num, probability, txt)

  UNION ALL

  SELECT 'en' AS lang, raw_data_en.*
  FROM (VALUES
    (1, 1, 0.9, 'All went well'),
    (1, 2, 0.03, 'Consequences – Wounds'),
    (1, 3, 0.03, 'Consequences – Dangerous Events'),
    (1, 4, 0.04, 'Consequences – Enemy'),

    (2, 1, 0.75, 'All went well'),
    (2, 2, 0.075, 'Consequences – Wounds'),
    (2, 3, 0.075, 'Consequences – Dangerous Events'),
    (2, 4, 0.1, 'Consequences – Enemy'),

    (3, 1, 0.5, 'All went well'),
    (3, 2, 0.15, 'Consequences – Wounds'),
    (3, 3, 0.15, 'Consequences – Dangerous Events'),
    (3, 4, 0.2, 'Consequences – Enemy'),

    (4, 1, 0.25, 'All went well'),
    (4, 2, 0.225, 'Consequences – Wounds'),
    (4, 3, 0.225, 'Consequences – Dangerous Events'),
    (4, 4, 0.3, 'Consequences – Enemy')
  ) AS raw_data_en(group_id, num, probability, txt)
)
, vals AS (
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
            }')::jsonb::jsonb FROM (SELECT DISTINCT group_id FROM raw_data) v(group_id)
),
ins_rules AS (
  INSERT INTO rules(ru_id, body) SELECT r.id, r.body FROM rules_vals r
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT
  'wcc_witcher_events_is_in_danger_o' || to_char(vals.group_id, 'FM00') || to_char(vals.num, 'FM00') AS an_id,
  meta.su_su_id,
  meta.qu_id,
  ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*vals.group_id+vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
  vals.num,
  r.id,
  jsonb_build_object(
           'probability', vals.probability
  )
FROM vals
CROSS JOIN meta
JOIN rules_vals r ON vals.group_id = r.group_id
ON CONFLICT (an_id) DO NOTHING;

-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_witcher_events_risk', 'wcc_witcher_events_is_in_danger';