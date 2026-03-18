\echo '039_mage_events_danger_details_2.sql'

-- Hierarchy key
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.hierarchy.mage_events_danger_details_2'), 'hierarchy', 'path', 'ru', 'Детали 2'),
  (ck_id('witcher_cc.hierarchy.mage_events_danger_details_2'), 'hierarchy', 'path', 'en', 'Details 2')
ON CONFLICT (id, lang) DO NOTHING;

-- Question
WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_mage_events_danger_details_2' AS qu_id
         , 'questions' AS entity
  )
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru', 'Уточните длительность последствия несчастного случая.'),
        ('en', 'Clarify the duration of the accident''s consequence.')
      ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
)
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Уточнение'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Clarification')
)
, ins_cols AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.column_name') AS id
         , meta.entity, 'column_name', c_vals.lang, c_vals.text
      FROM c_vals
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
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
           ck_id('witcher_cc.hierarchy.life_events')::text,
           jsonb_build_object('jsonlogic_expression', jsonb_build_object('cat', jsonb_build_array(
             jsonb_build_object('var', 'counters.lifeEventsCounter'),
             '-',
             jsonb_build_object('+', jsonb_build_array(
               jsonb_build_object('var', 'counters.lifeEventsCounter'),
               10
             ))
           ))),
           ck_id('witcher_cc.hierarchy.mage_events_risk')::text,
           ck_id('witcher_cc.hierarchy.mage_events_danger_details_2')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO UPDATE
SET body = EXCLUDED.body,
    qtype = EXCLUDED.qtype,
    metadata = EXCLUDED.metadata;

-- Answer options
WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_mage_events_danger_details_2' AS qu_id
         , 'answer_options' AS entity
         , 'label' AS entity_field
  )
, raw_data AS (
    SELECT 'ru' AS lang,
           10502 AS group_id,
           gs.num,
           0.1::numeric AS probability,
           'Вы были прикованы к постели ' ||
           gs.num::text || ' ' ||
           CASE
             WHEN gs.num = 1 THEN 'год'
             WHEN gs.num BETWEEN 2 AND 4 THEN 'года'
             ELSE 'лет'
           END || '.' AS txt
      FROM generate_series(1, 10) AS gs(num)

    UNION ALL

    SELECT 'en' AS lang,
           10502 AS group_id,
           gs.num,
           0.1::numeric AS probability,
           'You were bedridden for ' ||
           gs.num::text || ' ' ||
           CASE WHEN gs.num = 1 THEN 'year' ELSE 'years' END || '.' AS txt
      FROM generate_series(1, 10) AS gs(num)

    UNION ALL

    SELECT 'ru' AS lang,
           10503 AS group_id,
           gs.num,
           0.1::numeric AS probability,
           'Вы потеряли память о ' ||
           gs.num::text || ' ' ||
           CASE
             WHEN gs.num = 1 THEN 'годе'
             ELSE 'годах'
           END || ' из этой декады.' AS txt
      FROM generate_series(1, 10) AS gs(num)

    UNION ALL

    SELECT 'en' AS lang,
           10503 AS group_id,
           gs.num,
           0.1::numeric AS probability,
           'You lost your memory of ' ||
           gs.num::text || ' ' ||
           CASE WHEN gs.num = 1 THEN 'year' ELSE 'years' END || ' from this decade.' AS txt
      FROM generate_series(1, 10) AS gs(num)
)
, vals AS (
    SELECT ('<td style="color: grey;">' || to_char(probability * 100, 'FM990.00') || '%</td>'
         || '<td>' || txt || '</td>') AS text
         , group_id
         , num
         , probability
         , lang
      FROM raw_data
)
, ins_lbl AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.group_id, 'FM00000') || to_char(vals.num, 'FM00') ||'.'|| meta.entity ||'.'|| meta.entity_field)
         , meta.entity, meta.entity_field, vals.lang, vals.text
      FROM vals
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
)
, rules_vals(group_id, ru_id, name, body) AS (
    SELECT v.group_id
         , ck_id('witcher_cc.rules.wcc_mage_events_danger_details_2_group_' || v.group_id::text)
         , 'wcc_mage_events_danger_details_2_group_' || v.group_id::text
         , ('{
              "==": [
                { "reduce": [
                  { "var": ["answers.byQuestion.wcc_mage_events_danger_details", []] },
                  { "var": "current" },
                  null
                ] },
                "' || CASE WHEN v.group_id = 10502 THEN 'wcc_mage_events_danger_details_o010502' ELSE 'wcc_mage_events_danger_details_o010503' END || '"
              ]
            }')::jsonb
      FROM (VALUES (10502), (10503)) AS v(group_id)
)
, ins_rules AS (
    INSERT INTO rules (ru_id, name, body)
    SELECT ru_id, name, body
      FROM rules_vals
    ON CONFLICT (ru_id) DO UPDATE
    SET name = EXCLUDED.name,
        body = EXCLUDED.body
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, visible_ru_ru_id, sort_order, metadata)
SELECT 'wcc_mage_events_danger_details_2_o' || to_char(vals.group_id, 'FM00000') || to_char(vals.num, 'FM00')
     , meta.su_su_id
     , meta.qu_id
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.group_id, 'FM00000') || to_char(vals.num, 'FM00') ||'.'|| meta.entity ||'.'|| meta.entity_field)
     , rules_vals.ru_id
     , vals.num
     , jsonb_build_object('probability', vals.probability)
  FROM vals
  CROSS JOIN meta
  JOIN rules_vals ON rules_vals.group_id = vals.group_id
 WHERE vals.lang = 'ru'
ON CONFLICT (an_id) DO UPDATE
SET label = EXCLUDED.label,
    visible_ru_ru_id = EXCLUDED.visible_ru_ru_id,
    sort_order = EXCLUDED.sort_order,
    metadata = EXCLUDED.metadata;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_mage_events_danger_details_2' AS qu_id
  )
, event_desc_vals(lang, group_id, num, text) AS (
    SELECT 'ru' AS lang,
           10502 AS group_id,
           gs.num,
           'Несчастный случай: Прикованы к постели на ' ||
           gs.num::text || ' ' ||
           CASE
             WHEN gs.num = 1 THEN 'год.'
             WHEN gs.num BETWEEN 2 AND 4 THEN 'года.'
             ELSE 'лет.'
           END AS text
      FROM generate_series(1, 10) AS gs(num)

    UNION ALL

    SELECT 'en' AS lang,
           10502 AS group_id,
           gs.num,
           'Accident: Bedridden for ' ||
           gs.num::text || ' ' ||
           CASE WHEN gs.num = 1 THEN 'year.' ELSE 'years.' END AS text
      FROM generate_series(1, 10) AS gs(num)

    UNION ALL

    SELECT 'ru' AS lang,
           10503 AS group_id,
           gs.num,
           'Несчастный случай: Потеря памяти о ' ||
           gs.num::text || ' ' ||
           CASE
             WHEN gs.num = 1 THEN 'годе.'
             ELSE 'годах.'
           END || ' из этой декады.' AS text
      FROM generate_series(1, 10) AS gs(num)

    UNION ALL

    SELECT 'en' AS lang,
           10503 AS group_id,
           gs.num,
           'Accident: Lost memories of ' ||
           gs.num::text || ' ' ||
           CASE WHEN gs.num = 1 THEN 'year' ELSE 'years' END || ' from this decade.' AS text
      FROM generate_series(1, 10) AS gs(num)
)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(event_desc_vals.group_id, 'FM00000') || to_char(event_desc_vals.num, 'FM00') ||'.event_desc')
     , 'character'
     , 'event_desc'
     , event_desc_vals.lang
     , event_desc_vals.text
  FROM event_desc_vals
 CROSS JOIN meta
ON CONFLICT (id, lang) DO UPDATE
SET text = EXCLUDED.text;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_mage_events_danger_details_2' AS qu_id
  )
, event_effects AS (
    SELECT an_id
      FROM answer_options
     CROSS JOIN meta
     WHERE qu_qu_id = meta.qu_id
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character'
     , event_effects.an_id
     , jsonb_build_object(
         'add',
         jsonb_build_array(
           jsonb_build_object('var', 'characterRaw.lore.lifeEvents'),
           jsonb_build_object(
             'timePeriod',
             jsonb_build_object(
               'jsonlogic_expression',
               jsonb_build_object(
                 'cat',
                 jsonb_build_array(
                   jsonb_build_object('var', 'counters.lifeEventsCounter'),
                   '-',
                   jsonb_build_object(
                     '+',
                     jsonb_build_array(
                       jsonb_build_object('var', 'counters.lifeEventsCounter'),
                       10
                     )
                   )
                 )
               )
             ),
             'eventType',
             jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.wcc_mage_events_danger.life_event_type.danger')::text),
             'description',
             jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| event_effects.an_id ||'.event_desc')::text)
           )
         )
       )
  FROM event_effects
 CROSS JOIN meta;
