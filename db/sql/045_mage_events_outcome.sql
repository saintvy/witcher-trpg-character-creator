\echo '045_mage_events_outcome.sql'

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.hierarchy.mage_events_outcome'), 'hierarchy', 'path', 'ru', 'Исход'),
  (ck_id('witcher_cc.hierarchy.mage_events_outcome'), 'hierarchy', 'path', 'en', 'Outcome')
ON CONFLICT (id, lang) DO NOTHING;

INSERT INTO rules (ru_id, name, body)
VALUES
  (
    ck_id('witcher_cc.rules.wcc_mage_events_outcome_group_01'),
    'wcc_mage_events_outcome_group_01',
    '{"==":[{"reduce":[{"var":["answers.byQuestion.wcc_mage_events_risk",[]]},{"var":"current"},null]},"wcc_mage_events_risk_o01"]}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.wcc_mage_events_outcome_group_02'),
    'wcc_mage_events_outcome_group_02',
    '{"==":[{"reduce":[{"var":["answers.byQuestion.wcc_mage_events_risk",[]]},{"var":"current"},null]},"wcc_mage_events_risk_o02"]}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.wcc_mage_events_outcome_group_03'),
    'wcc_mage_events_outcome_group_03',
    '{"==":[{"reduce":[{"var":["answers.byQuestion.wcc_mage_events_risk",[]]},{"var":"current"},null]},"wcc_mage_events_risk_o03"]}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.wcc_mage_events_outcome_group_04'),
    'wcc_mage_events_outcome_group_04',
    '{"==":[{"reduce":[{"var":["answers.byQuestion.wcc_mage_events_risk",[]]},{"var":"current"},null]},"wcc_mage_events_risk_o04"]}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_mage_outcome_from_life_events_2_5'),
    'is_mage_outcome_from_life_events_2_5',
    '{"==":[{"var":"characterRaw.logicFields.last_node_and_answer"},"life events 2-5"]}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_mage_outcome_from_life_events_4_10'),
    'is_mage_outcome_from_life_events_4_10',
    '{"==":[{"var":"characterRaw.logicFields.last_node_and_answer"},"life events 4-10"]}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_mage_outcome_from_life_events_1_2'),
    'is_mage_outcome_from_life_events_1_2',
    '{"==":[{"var":"characterRaw.logicFields.last_node_and_answer"},"life events 1-2"]}'::jsonb
  )
ON CONFLICT (ru_id) DO UPDATE
SET name = EXCLUDED.name,
    body = EXCLUDED.body;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_mage_events_outcome' AS qu_id
         , 'questions' AS entity
  )
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body')
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru', 'Определите исход этой декады. Вероятности зависят от выбранного ранее образа жизни.'),
        ('en', 'Determine the outcome of this decade. The probabilities depend on the lifestyle you selected earlier.')
      ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
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
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.column_name')
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
           ck_id('witcher_cc.hierarchy.mage_events_outcome')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO UPDATE
SET body = EXCLUDED.body,
    qtype = EXCLUDED.qtype,
    metadata = EXCLUDED.metadata;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_mage_events_outcome' AS qu_id
         , 'answer_options' AS entity
         , 'label' AS entity_field
  )
, raw_data AS (
  SELECT 'ru' AS lang, v.*
    FROM (VALUES
      (1, 1, 0.7::numeric, 'Ничего',    'wcc_mage_events_outcome_group_01'),
      (1, 2, 0.1::numeric, 'Выгода',    'wcc_mage_events_outcome_group_01'),
      (1, 3, 0.1::numeric, 'Союзник',   'wcc_mage_events_outcome_group_01'),
      (1, 4, 0.1::numeric, 'Знание',    'wcc_mage_events_outcome_group_01'),
      (2, 1, 0.2::numeric, 'Ничего',    'wcc_mage_events_outcome_group_02'),
      (2, 2, 0.2::numeric, 'Выгода',    'wcc_mage_events_outcome_group_02'),
      (2, 3, 0.5::numeric, 'Союзник',   'wcc_mage_events_outcome_group_02'),
      (2, 4, 0.1::numeric, 'Знание',    'wcc_mage_events_outcome_group_02'),
      (3, 1, 0.2::numeric, 'Ничего',    'wcc_mage_events_outcome_group_03'),
      (3, 2, 0.5::numeric, 'Выгода',    'wcc_mage_events_outcome_group_03'),
      (3, 3, 0.2::numeric, 'Союзник',   'wcc_mage_events_outcome_group_03'),
      (3, 4, 0.1::numeric, 'Знание',    'wcc_mage_events_outcome_group_03'),
      (4, 1, 0.0::numeric, 'Ничего',    'wcc_mage_events_outcome_group_04'),
      (4, 2, 0.3::numeric, 'Выгода',    'wcc_mage_events_outcome_group_04'),
      (4, 3, 0.1::numeric, 'Союзник',   'wcc_mage_events_outcome_group_04'),
      (4, 4, 0.6::numeric, 'Знание',    'wcc_mage_events_outcome_group_04')
    ) AS v(group_id, num, probability, txt, rule_name)

  UNION ALL

  SELECT 'en' AS lang, v.*
    FROM (VALUES
      (1, 1, 0.7::numeric, 'Nothing',   'wcc_mage_events_outcome_group_01'),
      (1, 2, 0.1::numeric, 'Benefit',   'wcc_mage_events_outcome_group_01'),
      (1, 3, 0.1::numeric, 'Ally',      'wcc_mage_events_outcome_group_01'),
      (1, 4, 0.1::numeric, 'Knowledge', 'wcc_mage_events_outcome_group_01'),
      (2, 1, 0.2::numeric, 'Nothing',   'wcc_mage_events_outcome_group_02'),
      (2, 2, 0.2::numeric, 'Benefit',   'wcc_mage_events_outcome_group_02'),
      (2, 3, 0.5::numeric, 'Ally',      'wcc_mage_events_outcome_group_02'),
      (2, 4, 0.1::numeric, 'Knowledge', 'wcc_mage_events_outcome_group_02'),
      (3, 1, 0.2::numeric, 'Nothing',   'wcc_mage_events_outcome_group_03'),
      (3, 2, 0.5::numeric, 'Benefit',   'wcc_mage_events_outcome_group_03'),
      (3, 3, 0.2::numeric, 'Ally',      'wcc_mage_events_outcome_group_03'),
      (3, 4, 0.1::numeric, 'Knowledge', 'wcc_mage_events_outcome_group_03'),
      (4, 1, 0.0::numeric, 'Nothing',   'wcc_mage_events_outcome_group_04'),
      (4, 2, 0.3::numeric, 'Benefit',   'wcc_mage_events_outcome_group_04'),
      (4, 3, 0.1::numeric, 'Ally',      'wcc_mage_events_outcome_group_04'),
      (4, 4, 0.6::numeric, 'Knowledge', 'wcc_mage_events_outcome_group_04')
    ) AS v(group_id, num, probability, txt, rule_name)
)
, vals AS (
  SELECT
    lang,
    group_id,
    num,
    probability,
    rule_name,
    '<td style="color: grey;">' || to_char(probability * 100, 'FM990.00') || '%</td><td>' || txt || '</td>' AS text
  FROM raw_data
)
, ins_lbl AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100 * vals.group_id + vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field)
       , meta.entity, meta.entity_field, vals.lang, vals.text
    FROM vals
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO UPDATE
  SET text = EXCLUDED.text
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT
  'wcc_mage_events_outcome_o' || to_char(vals.group_id, 'FM00') || to_char(vals.num, 'FM00'),
  meta.su_su_id,
  meta.qu_id,
  ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100 * vals.group_id + vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field),
  vals.num,
  (SELECT ru_id FROM rules WHERE name = vals.rule_name),
  jsonb_build_object('probability', vals.probability)
FROM vals
CROSS JOIN meta
WHERE vals.lang = 'ru'
ON CONFLICT (an_id) DO UPDATE
SET label = EXCLUDED.label,
    sort_order = EXCLUDED.sort_order,
    visible_ru_ru_id = EXCLUDED.visible_ru_ru_id,
    metadata = EXCLUDED.metadata;
