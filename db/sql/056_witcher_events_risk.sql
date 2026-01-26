\echo '056_witcher_events_risk.sql'
-- Узел: Каково ваше нынешнее положение?

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_risk' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru', 'Выберите насколько рискованную жизнь вел ведьмак в ту декаду.'),
        ('en', 'Choose how dangerous a life your witcher led in that decade.')
      ) AS v(lang, text)
      CROSS JOIN meta
  )
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Поведение'),
      ('ru', 2, 'Ничего'),
      ('ru', 3, 'Выгода'),
      ('ru', 4, 'Союзник'),
      ('ru', 5, 'Охота'),
      ('ru', 6, 'Риск - Опасные события'),
      ('ru', 7, 'Риск - Раны'),
      ('ru', 8, 'Риск - Враг'),
      ('en', 1, 'Saftey'),
      ('en', 2, 'Nothing'),
      ('en', 3, 'Benefit'),
      ('en', 4, 'Ally'),
      ('en', 5, 'A hunt'),
      ('en', 6, 'Risk - Danger events'),
      ('en', 7, 'Risk - Wounds'),
      ('en', 8, 'Risk - Enemies')
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
         'dice', 'd0',
         'columns', (
           SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_witcher_events_risk' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
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
           ck_id('witcher_cc.hierarchy.witcher_events_risk')::text
         )
       )
  FROM meta;

-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_risk' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
  FROM (VALUES
    (1, 'Осторожное' , '70%', '10%', '10%', '10%', '3%', '3%', '4%'),
    (2, 'Нормальное' , '50%', '10%', '10%', '30%', '7.5%', '7.5%', '10%'),
    (3, 'Среднее'    , '20%', '20%', '50%', '10%', '15%', '15%', '20%'),
    (4, 'Рискованное', '10%', '50%', '20%', '20%', '22.5%', '22.5%', '30%')
  ) AS raw_data_ru(num, Saftey, Nothing, Benefit, Ally, a_hunt, Danger_events, Wounds, Enemies)

  UNION ALL

  SELECT 'en' AS lang, raw_data_en.*
  FROM (VALUES
    (1, 'Cautious'   , '63%', '9%', '9%', '9%', '3%', '3%', '4%'),
    (2, 'Normal'     , '37.5%', '7.5%', '7.5%', '22.5%', '7.5%', '7.5%', '10%'),
    (3, 'Non-Neutral', '10%', '10%', '25%', '5%', '15%', '15%', '20%'),
    (4, 'Risky'      , '2.5%', '12.5%', '5%', '5%', '22.5%', '22.5%', '30%')
  ) AS raw_data_en(num, Saftey, Nothing, Benefit, Ally, a_hunt, Danger_events, Wounds, Enemies)
)
, vals AS (
  SELECT '<td>' || Saftey || '</td>'
         || '<td>' || Nothing || '</td>'
         || '<td>' || Benefit || '</td>'
         || '<td>' || Ally || '</td>'
         || '<td>' || a_hunt || '</td>'
         || '<td style="color: red; text-align: center;"><b>' || Danger_events || '</b></td>'
         || '<td style="color: red; text-align: center;"><b>' || Wounds || '</b></td>'
         || '<td style="color: red; text-align: center;"><b>' || Enemies || '</b></td>' AS text,
     num, lang
   FROM raw_data
)
, ins_lbl AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
       , meta.entity, meta.entity_field, vals.lang, vals.text
    FROM vals
    CROSS JOIN meta
)

INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
SELECT
  'wcc_witcher_events_risk_o' || to_char(vals.num, 'FM00') AS an_id,
  meta.su_su_id,
  meta.qu_id,
  ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
  vals.num,
  '{}'jsonb
FROM vals
CROSS JOIN meta
ON CONFLICT (an_id) DO NOTHING;

-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_witcher_current_situation', 'wcc_witcher_events_risk';