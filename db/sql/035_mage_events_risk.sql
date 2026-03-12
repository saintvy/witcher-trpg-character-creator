\echo '035_mage_events_risk.sql'

-- Hierarchy key
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.hierarchy.mage_events_risk'), 'hierarchy', 'path', 'ru', 'Риск'),
  (ck_id('witcher_cc.hierarchy.mage_events_risk'), 'hierarchy', 'path', 'en', 'Risk')
ON CONFLICT (id, lang) DO NOTHING;

-- Question
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_mage_events_risk' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru', 'Выберите, какой образ жизни вы вели в эту декаду. Вероятность того, реализуется ли риск, зависит от поведения, и тип опасности также зависит от него.'),
        ('en', 'Choose what kind of life you led in this decade. The chance that risk materializes depends on your behavior, and the type of danger also depends on it.')
      ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
)
, c_vals(lang, num, text, align, fit) AS (
    VALUES
      ('ru', 1, 'Шанс', 'center', true),
      ('ru', 2, 'Поведение', 'left', true),
      ('ru', 3, 'Ничего', 'center', true),
      ('ru', 4, 'Выгода', 'center', true),
      ('ru', 5, 'Союзник', 'center', true),
      ('ru', 6, 'Знание', 'center', true),
      ('ru', 7, '|', 'center', true),
      ('ru', 8, 'Риск', 'center', true),
      ('ru', 9, ' ', 'left', false),
      ('en', 1, 'Chance', 'left', true),
      ('en', 2, 'Behavior', 'left', true),
      ('en', 3, 'Nothing', 'center', true),
      ('en', 4, 'Benefit', 'center', true),
      ('en', 5, 'Ally', 'center', true),
      ('en', 6, 'Knowledge', 'center', true),
      ('en', 7, '|', 'center', true),
      ('en', 8, 'Risk', 'center', true),
      ('en', 9, ' ', 'left', false)
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
         'dice', 'd0',
         'columns', (
           SELECT jsonb_agg(ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(num, 'FM9900') ||'.'|| meta.entity ||'.column_name')::text ORDER BY num)
           FROM (SELECT DISTINCT num FROM c_vals) cols
         ),
         'columnLayout', (
           SELECT jsonb_agg(jsonb_build_object('align', align, 'fit', fit) ORDER BY num)
           FROM (
             SELECT DISTINCT num, align, fit
             FROM c_vals
             WHERE lang = 'ru'
           ) cols
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
           ck_id('witcher_cc.hierarchy.mage_events_risk')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO UPDATE
SET body = EXCLUDED.body,
    qtype = EXCLUDED.qtype,
    metadata = EXCLUDED.metadata;

-- Answers
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_mage_events_risk' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
      (1, '25%', 'Осторожное',     '70%', '10%', '10%', '10%', '20%'),
      (2, '25%', 'Политика',       '20%', '20%', '50%', '10%', '50%'),
      (3, '25%', 'Изучение магии', '20%', '50%', '20%', '10%', '50%'),
      (4, '25%', 'Эксперименты',   '0%',  '30%', '10%', '60%', '70%')
    ) AS raw_data_ru(num, chance, behavior, nothing, benefit, ally, knowledge, risk)

  UNION ALL

  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
      (1, '25%', 'Cautious',       '70%', '10%', '10%', '10%', '20%'),
      (2, '25%', 'Politics',       '20%', '20%', '50%', '10%', '50%'),
      (3, '25%', 'Studying Magic', '20%', '50%', '20%', '10%', '50%'),
      (4, '25%', 'Experimentation','0%',  '30%', '10%', '60%', '70%')
    ) AS raw_data_en(num, chance, behavior, nothing, benefit, ally, knowledge, risk)
)
, vals AS (
  SELECT
    '<td style="color: grey;">' || chance || '</td>'
    || '<td>' || behavior || '</td>'
    || '<td>' || nothing || '</td>'
    || '<td>' || benefit || '</td>'
    || '<td>' || ally || '</td>'
    || '<td>' || knowledge || '</td>'
    || '<td>|</td>'
    || '<td style="color: red;"><b>' || risk || '</b></td>'
    || '<td> </td>' AS text,
    num,
    lang
  FROM raw_data
)
, ins_lbl AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
       , meta.entity, meta.entity_field, vals.lang, vals.text
    FROM vals
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO UPDATE
  SET text = EXCLUDED.text
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
SELECT
  'wcc_mage_events_risk_o' || to_char(vals.num, 'FM00') AS an_id,
  meta.su_su_id,
  meta.qu_id,
  ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
  vals.num,
  '{}'::jsonb
FROM vals
CROSS JOIN meta
WHERE vals.lang = 'ru'
ON CONFLICT (an_id) DO UPDATE
SET label = EXCLUDED.label,
    sort_order = EXCLUDED.sort_order,
    metadata = EXCLUDED.metadata;

-- Effects: on any answer set academy_life flag = 3
DELETE FROM effects
 WHERE an_an_id IN (
   'wcc_mage_events_risk_o01',
   'wcc_mage_events_risk_o02',
   'wcc_mage_events_risk_o03',
   'wcc_mage_events_risk_o04'
 );

WITH nums AS (
  SELECT generate_series(1, 4) AS num
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_mage_events_risk_o' || to_char(nums.num, 'FM00'),
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.logic_fields.flags.academy_life'),
      3
    )
  )
FROM nums;
