\echo '093_witcher_events_risk.sql'
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
      ('ru', 6, 'Охота', 'center', true),
      ('ru', 7, '|', 'center', true),
      ('ru', 8, 'Риск (Опасные события)', 'center', true),
      ('ru', 9, 'Риск (Раны)', 'center', true),
      ('ru', 10, 'Риск (Враг)', 'center', true),
      ('ru', 11, ' ', 'center', false),
      ('en', 1, 'Chance', 'center', true),
      ('en', 2, 'Behavior', 'center', true),
      ('en', 3, 'Nothing', 'center', true),
      ('en', 4, 'Benefit', 'center', true),
      ('en', 5, 'Ally', 'center', true),
      ('en', 6, 'A hunt', 'center', true),
      ('en', 7, '|', 'center', true),
      ('en', 8, 'Risk (Danger events)', 'center', true),
      ('en', 9, 'Risk (Wounds)', 'center', true),
      ('en', 10, 'Risk (Enemies)', 'center', true),
      ('en', 11, ' ', 'center', false)
  )
, ins_cols AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| 'column_name') AS id
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
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body')
     , 'single_table'
     , jsonb_build_object(
         'dice', 'd0',
         'columns', (
           SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_witcher_events_risk' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
           FROM (SELECT DISTINCT num FROM c_vals) AS cols
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
    (1, '25%', 'Осторожное' , '70%', '10%', '10%', '10%', '3%', '3%', '4%'),
    (2, '25%', 'Нормальное' , '50%', '10%', '10%', '30%', '7.5%', '7.5%', '10%'),
    (3, '25%', 'Среднее'    , '20%', '20%', '50%', '10%', '15%', '15%', '20%'),
    (4, '25%', 'Рискованное', '10%', '50%', '20%', '20%', '22.5%', '22.5%', '30%')
  ) AS raw_data_ru(num, chance, Safety, Nothing, Benefit, Ally, a_hunt, Danger_events, Wounds, Enemies)

  UNION ALL

  SELECT 'en' AS lang, raw_data_en.*
  FROM (VALUES
    (1, '25%', 'Cautious'   , '63%', '9%', '9%', '9%', '3%', '3%', '4%'),
    (2, '25%', 'Normal'     , '37.5%', '7.5%', '7.5%', '22.5%', '7.5%', '7.5%', '10%'),
    (3, '25%', 'Non-Neutral', '10%', '10%', '25%', '5%', '15%', '15%', '20%'),
    (4, '25%', 'Risky'      , '2.5%', '12.5%', '5%', '5%', '22.5%', '22.5%', '30%')
  ) AS raw_data_en(num, chance, Safety, Nothing, Benefit, Ally, a_hunt, Danger_events, Wounds, Enemies)
)
, vals AS (
  SELECT '<td style="color: grey;">' || chance || '</td>'
         || '<td>' || Safety || '</td>'
         || '<td>' || Nothing || '</td>'
         || '<td>' || Benefit || '</td>'
         || '<td>' || Ally || '</td>'
         || '<td>' || a_hunt || '</td>'
         || '<td>|</td>'
         || '<td style="color: red;"><b>' || Danger_events || '</b></td>'
         || '<td style="color: red;"><b>' || Wounds || '</b></td>'
         || '<td style="color: red;"><b>' || Enemies || '</b></td>'
         || '<td> </td>' AS text,
     num, lang
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
