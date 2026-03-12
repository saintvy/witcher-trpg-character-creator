\echo '035_mage_events_risk.sql'

-- Hierarchy key
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.hierarchy.mage_events_risk'), 'hierarchy', 'path', 'ru', 'Риск'),
  (ck_id('witcher_cc.hierarchy.mage_events_risk'), 'hierarchy', 'path', 'en', 'Risk')
ON CONFLICT (id, lang) DO NOTHING;

-- Placeholder question
WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_mage_events_risk' AS qu_id
         , 'questions' AS entity
  )
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru', 'Заглушка: ветка рискованных событий мага.'),
        ('en', 'Placeholder: mage risk-events branch.')
      ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
)
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Результат'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Outcome')
)
, ins_cols AS (
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
         'dice', 'd0',
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
           ck_id('witcher_cc.hierarchy.mage_events_risk')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO NOTHING;

-- Placeholder option
WITH vals AS (
  SELECT *
    FROM (VALUES
      ('ru', '<td>100.00%</td><td>Ветка еще в разработке</td>'),
      ('en', '<td>100.00%</td><td>Branch is under construction</td>')
    ) AS v(lang, text)
)
, ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id('witcher_cc.wcc_mage_events_risk_o01.answer_options.label') AS id
       , 'answer_options' AS entity
       , 'label' AS entity_field
       , vals.lang
       , vals.text
    FROM vals
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
VALUES (
  'wcc_mage_events_risk_o01',
  'witcher_cc',
  'wcc_mage_events_risk',
  ck_id('witcher_cc.wcc_mage_events_risk_o01.answer_options.label')::text,
  1,
  jsonb_build_object('probability', 1.0)
)
ON CONFLICT (an_id) DO NOTHING;

