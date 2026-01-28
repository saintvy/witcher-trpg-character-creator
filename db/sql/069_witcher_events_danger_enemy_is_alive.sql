\echo '069_witcher_events_danger_enemy_is_alive.sql'

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_danger_enemy_is_alive' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru', 'Определите, жив ли ваш враг.'),
        ('en', 'Determine if your enemy alive.')
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
           SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_witcher_events_danger_enemy_is_alive' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
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
           ck_id('witcher_cc.hierarchy.witcher_events_danger_enemy')::text,
           ck_id('witcher_cc.hierarchy.witcher_events_danger_enemy_is_alive')::text
         )
       )
  FROM meta;

-- Ответы (50/50)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_danger_enemy_is_alive' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
  FROM (VALUES
    (1, 0.7, 'Враг жив'),
    (2, 0.03, 'Враг умер, прожив еще 10 лет'),
    (3, 0.03, 'Враг умер, прожив еще 20 лет'),
    (4, 0.03, 'Враг умер, прожив еще 30 лет'),
    (5, 0.03, 'Враг умер, прожив еще 40 лет'),
    (6, 0.03, 'Враг умер, прожив еще 50 лет'),
    (7, 0.03, 'Враг умер, прожив еще 60 лет'),
    (8, 0.03, 'Враг умер, прожив еще 70 лет'),
    (9, 0.03, 'Враг умер, прожив еще 80 лет'),
    (10, 0.03, 'Враг умер, прожив еще 90 лет'),
    (11, 0.03, 'Враг умер, прожив еще 100 лет')
  ) AS raw_data_ru(num, probability, txt)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
  FROM (VALUES
    (1, 0.7, 'The enemy is alive'),
    (2, 0.03, 'The enemy is dead now, but had been living for 10 years before it happened.'),
    (3, 0.03, 'The enemy is dead now, but had been living for 20 years before it happened.'),
    (4, 0.03, 'The enemy is dead now, but had been living for 30 years before it happened.'),
    (5, 0.03, 'The enemy is dead now, but had been living for 40 years before it happened.'),
    (6, 0.03, 'The enemy is dead now, but had been living for 50 years before it happened.'),
    (7, 0.03, 'The enemy is dead now, but had been living for 60 years before it happened.'),
    (8, 0.03, 'The enemy is dead now, but had been living for 70 years before it happened.'),
    (9, 0.03, 'The enemy is dead now, but had been living for 80 years before it happened.'),
    (10, 0.03, 'The enemy is dead now, but had been living for 90 years before it happened.'),
    (11, 0.03, 'The enemy is dead now, but had been living for 100 years before it happened.')
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
  'wcc_witcher_events_danger_enemy_is_alive_o' || to_char(vals.num, 'FM00') AS an_id,
  meta.su_su_id,
  meta.qu_id,
  ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
  vals.num,
  jsonb_build_object(
           'probability', vals.probability
  )
FROM vals
CROSS JOIN meta
ON CONFLICT (an_id) DO NOTHING;

-- Эффекты: добавление врага в массив enemies (только для варианта ответа 1 - "Враг жив")
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_danger_enemy_is_alive' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_witcher_events_danger_enemy_is_alive_o01',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.enemies'),
      jsonb_build_object(
        'gender', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_witcher_events_danger_enemy_gender'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'position', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_witcher_events_danger_enemy_profession'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'the_cause', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_witcher_events_danger_enemy_reason'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'power', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_witcher_events_danger_enemy_strength'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'escalation_level', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_witcher_events_danger_enemy_result'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'is_alive', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_witcher_events_danger_enemy_is_alive'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value'))))
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
                , 'wcc_witcher_events_danger_enemy_is_alive' AS qu_id
                , 'character' AS entity)
-- i18n для description "Враг"
, ins_desc_enemy AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'event_desc_enemy') AS id
         , meta.entity, 'event_desc', v.lang, v.text
      FROM (VALUES
        ('ru', 'Враг'),
        ('en', 'Enemy')
      ) AS v(lang, text)
      CROSS JOIN meta
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_witcher_events_danger_enemy_is_alive_o01',
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
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'event_desc_enemy')::text)
      )
    )
  )
FROM meta;

-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id) 
  SELECT 'wcc_witcher_events_danger_enemy_result', 'wcc_witcher_events_danger_enemy_is_alive'
  ;