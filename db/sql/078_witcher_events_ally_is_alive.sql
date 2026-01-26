\echo '078_witcher_events_ally_is_alive.sql'

-- Вопрос: жив ли союзник
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_ally_is_alive' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru', 'Определите, жив ли ваш союзник.'),
        ('en', 'Determine if your ally is alive.')
      ) AS v(lang, text)
      CROSS JOIN meta
  )
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Жив ли?'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Is alive?')
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
           SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_witcher_events_ally_is_alive' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
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
           ck_id('witcher_cc.hierarchy.witcher_events_ally')::text,
           ck_id('witcher_cc.hierarchy.witcher_events_ally_is_alive')::text
         )
       )
  FROM meta;

-- Ответы (жив 70%, 10 опций смерти по 3%)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_ally_is_alive' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
  FROM (VALUES
    (1, 0.7, 'Союзник жив'),
    (2, 0.03, 'Союзник умер, прожив еще 10 лет с момента знакомства.'),
    (3, 0.03, 'Союзник умер, прожив еще 20 лет с момента знакомства.'),
    (4, 0.03, 'Союзник умер, прожив еще 30 лет с момента знакомства.'),
    (5, 0.03, 'Союзник умер, прожив еще 40 лет с момента знакомства.'),
    (6, 0.03, 'Союзник умер, прожив еще 50 лет с момента знакомства.'),
    (7, 0.03, 'Союзник умер, прожив еще 60 лет с момента знакомства.'),
    (8, 0.03, 'Союзник умер, прожив еще 70 лет с момента знакомства.'),
    (9, 0.03, 'Союзник умер, прожив еще 80 лет с момента знакомства.'),
    (10, 0.03, 'Союзник умер, прожив еще 90 лет с момента знакомства.'),
    (11, 0.03, 'Союзник умер, прожив еще 100 лет с момента знакомства.')
  ) AS raw_data_ru(num, probability, txt)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
  FROM (VALUES
    (1, 0.7, 'The ally is alive'),
    (2, 0.03, 'The ally dies 10 years after they meet.'),
    (3, 0.03, 'The ally dies 20 years after they meet.'),
    (4, 0.03, 'The ally dies 30 years after they meet.'),
    (5, 0.03, 'The ally dies 40 years after they meet.'),
    (6, 0.03, 'The ally dies 50 years after they meet.'),
    (7, 0.03, 'The ally dies 60 years after they meet.'),
    (8, 0.03, 'The ally dies 70 years after they meet.'),
    (9, 0.03, 'The ally dies 80 years after they meet.'),
    (10, 0.03, 'The ally dies 90 years after they meet.'),
    (11, 0.03, 'The ally dies 100 years after they meet.')
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
  'wcc_witcher_events_ally_is_alive_o' || to_char(vals.num, 'FM00') AS an_id,
  meta.su_su_id,
  meta.qu_id,
  ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
  vals.num,
   (
     jsonb_build_object(
           'probability', vals.probability
     )
     || CASE
          WHEN vals.num = 1 THEN
            '{"counterIncrement":{"id":"lifeEventsCounter","step":10}}'::jsonb
          ELSE '{}'::jsonb
        END
   )
FROM vals
CROSS JOIN meta
ON CONFLICT (an_id) DO NOTHING;

-- Эффекты: добавление союзника в allies (только для варианта ответа 1 - "союзник жив")
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_ally_is_alive' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_witcher_events_ally_is_alive_o01',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.allies'),
      jsonb_build_object(
        'gender', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_witcher_events_ally_gender'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'position', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_witcher_events_ally_who'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'how_met', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_witcher_events_ally_how_met'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'how_close', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_witcher_events_ally_closeness'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'is_alive', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_witcher_events_ally_is_alive'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value'))))
      )
    )
  )
FROM meta;

-- i18n для eventType "Союзники и враги" (создается также в других нодах, используем ON CONFLICT)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id('witcher_cc' ||'.'|| 'wcc_life_events_allies_and_enemies' ||'.'|| 'event_type_allies_and_enemies') AS id
       , 'character', 'event_type', v.lang, v.text
    FROM (VALUES
      ('ru', 'Союзники и враги'),
      ('en', 'Allies and Enemies')
    ) AS v(lang, text)
  ON CONFLICT (id, lang) DO NOTHING;

-- Эффект: добавление события в lifeEvents (привязан к варианту ответа 1)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_ally_is_alive' AS qu_id
                , 'character' AS entity)
-- i18n для description "Союзник"
, ins_desc_ally AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'event_desc_ally') AS id
         , meta.entity, 'event_desc', v.lang, v.text
      FROM (VALUES
        ('ru', 'Союзник'),
        ('en', 'Ally')
      ) AS v(lang, text)
      CROSS JOIN meta
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_witcher_events_ally_is_alive_o01',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.lore.lifeEvents'),
      jsonb_build_object(
        'timePeriod',
        jsonb_build_object(
          'jsonlogic_expression', jsonb_build_object(
            'cat', jsonb_build_array(
              jsonb_build_object('var', 'counters.lifeEventsCounter'),
              '-',
              jsonb_build_object(
                '+', jsonb_build_array(
                  jsonb_build_object('var', 'counters.lifeEventsCounter'),
                  10
                )
              )
            )
          )
        ),
        'eventType',
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| 'wcc_life_events_allies_and_enemies' ||'.'|| 'event_type_allies_and_enemies')::text),
        'description',
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'event_desc_ally')::text)
      )
    )
  )
FROM meta;
 
 -- Связь: напрямую от ноды близости
 INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
   SELECT 'wcc_witcher_events_ally_closeness', 'wcc_witcher_events_ally_is_alive'
   ;
 
 -- Переход по окончанию цикла событий: к рискам
 INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
   SELECT 'wcc_witcher_events_ally_is_alive', 'wcc_witcher_events_risk', r.ru_id, 1
     FROM (SELECT ru_id FROM rules WHERE name = 'lifeEventsCounter_is_valid') r;

































