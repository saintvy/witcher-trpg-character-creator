\echo '036_mage_events_is_in_danger.sql'

-- Hierarchy key
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.hierarchy.mage_events_is_in_danger'), 'hierarchy', 'path', 'ru', 'Какая именно'),
  (ck_id('witcher_cc.hierarchy.mage_events_is_in_danger'), 'hierarchy', 'path', 'en', 'Which one')
ON CONFLICT (id, lang) DO NOTHING;

-- Question
WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_mage_events_is_in_danger' AS qu_id
         , 'questions' AS entity
  )
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru', 'Попал ли маг в неприятности в ту декаду? Вероятность зависит от выбранного ранее образа жизни.'),
        ('en', 'Did the mage get into trouble during that decade? The chance depends on the lifestyle you selected earlier.')
      ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
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
           ck_id('witcher_cc.hierarchy.mage_events_is_in_danger')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO UPDATE
SET body = EXCLUDED.body,
    qtype = EXCLUDED.qtype,
    metadata = EXCLUDED.metadata;

-- Answers
WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_mage_events_is_in_danger' AS qu_id
         , 'answer_options' AS entity
         , 'label' AS entity_field
  )
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
      (1, 1, 0.8, 'Всё хорошо', false),
      (1, 2, 0.2, 'Опасность (Осторожность)', true),

      (2, 1, 0.5, 'Всё хорошо', false),
      (2, 2, 0.5, 'Опасность (Политика)', true),

      (3, 1, 0.5, 'Всё хорошо', false),
      (3, 2, 0.5, 'Опасность (Изучение магии)', true),

      (4, 1, 0.3, 'Всё хорошо', false),
      (4, 2, 0.7, 'Опасность (Эксперименты)', true)
    ) AS raw_data_ru(group_id, num, probability, txt, is_risk)

  UNION ALL

  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
      (1, 1, 0.8, 'All is well', false),
      (1, 2, 0.2, 'Danger (Cautiousness)', true),

      (2, 1, 0.5, 'All is well', false),
      (2, 2, 0.5, 'Danger (Politics)', true),

      (3, 1, 0.5, 'All is well', false),
      (3, 2, 0.5, 'Danger (Studying Magic)', true),

      (4, 1, 0.3, 'All is well', false),
      (4, 2, 0.7, 'Danger (Experiments)', true)
    ) AS raw_data_en(group_id, num, probability, txt, is_risk)
)
, vals AS (
  SELECT
    (
      '<td style="' ||
      CASE WHEN is_risk THEN 'color: red; font-weight: bold;' ELSE 'color: grey;' END ||
      '">' || to_char(probability * 100, 'FM990.00') || '%</td>' ||
      CASE
        WHEN is_risk THEN '<td style="color: red;"><b>' || txt || '</b></td>'
        ELSE '<td>' || txt || '</td>'
      END
    ) AS text,
    group_id,
    num,
    probability,
    lang
  FROM raw_data
)
, ins_lbl AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100 * vals.group_id + vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
       , meta.entity, meta.entity_field, vals.lang, vals.text
    FROM vals
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO UPDATE
  SET text = EXCLUDED.text
)
, rules_vals AS (
  SELECT
    v.group_id,
    ck_id('witcher_cc.rules.wcc_mage_events_is_in_danger_group_' || to_char(v.group_id, 'FM00')) AS ru_id,
    'wcc_mage_events_is_in_danger_group_' || to_char(v.group_id, 'FM00') AS name,
    ('{
      "==": [
        { "reduce": [ { "var": ["answers.byQuestion.wcc_mage_events_risk", []] }, { "var": "current" }, null ] },
        "wcc_mage_events_risk_o' || to_char(v.group_id, 'FM00') || '"
      ]
    }')::jsonb AS body
  FROM (SELECT DISTINCT group_id FROM raw_data) v
)
, ins_rules AS (
  INSERT INTO rules (ru_id, name, body)
  SELECT ru_id, name, body
    FROM rules_vals
  ON CONFLICT (ru_id) DO UPDATE
  SET name = EXCLUDED.name,
      body = EXCLUDED.body
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT
  'wcc_mage_events_is_in_danger_o' || to_char(vals.group_id, 'FM00') || to_char(vals.num, 'FM00') AS an_id,
  meta.su_su_id,
  meta.qu_id,
  ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100 * vals.group_id + vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
  vals.num,
  r.ru_id,
  jsonb_build_object('probability', vals.probability)
FROM vals
CROSS JOIN meta
JOIN rules_vals r ON r.group_id = vals.group_id
WHERE vals.lang = 'ru'
ON CONFLICT (an_id) DO UPDATE
SET label = EXCLUDED.label,
    sort_order = EXCLUDED.sort_order,
    visible_ru_ru_id = EXCLUDED.visible_ru_ru_id,
    metadata = EXCLUDED.metadata;

-- Link from previous node
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, priority)
SELECT 'wcc_mage_events_risk', 'wcc_mage_events_is_in_danger', 1
WHERE NOT EXISTS (
  SELECT 1
  FROM transitions t
  WHERE t.from_qu_qu_id = 'wcc_mage_events_risk'
    AND t.to_qu_qu_id = 'wcc_mage_events_is_in_danger'
    AND t.via_an_an_id IS NULL
    AND t.ru_ru_id IS NULL
);
