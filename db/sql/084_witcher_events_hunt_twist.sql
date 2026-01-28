\echo '084_witcher_events_hunt_twist.sql'

-- Вопрос: был ли поворот сюжета
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_hunt_twist' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
           , meta.entity, 'body', v.lang, v.text
        FROM (VALUES
          ('ru', 'Определите, был ли неожиданный поворот.'),
          ('en', 'Determine whether there was a twist.')
        ) AS v(lang, text)
        CROSS JOIN meta
)
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Внезапный поворот?'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Twist?')
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
           SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_witcher_events_hunt_twist' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
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
           ck_id('witcher_cc.hierarchy.witcher_events_hunt')::text,
           ck_id('witcher_cc.hierarchy.witcher_events_hunt_twist')::text
         )
       )
  FROM meta;

-- Ответы (Да 40%, Нет 60%)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_hunt_twist' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.* FROM (VALUES
    (1, 0.4, 'Да'),
    (2, 0.6, 'Нет')
  ) AS raw_data_ru(num, probability, txt)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.* FROM (VALUES
    (1, 0.4, 'Yes'),
    (2, 0.6, 'No')
  ) AS raw_data_en(num, probability, txt)
)
, vals AS (
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
  'wcc_witcher_events_hunt_twist_o' || to_char(vals.num, 'FM00') AS an_id,
  meta.su_su_id,
  meta.qu_id,
  ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
  vals.num AS sort_order,
  jsonb_build_object(
           'probability', vals.probability
  ) 
     || CASE
          WHEN vals.num = 2 THEN
            '{"counterIncrement":{"id":"lifeEventsCounter","step":10}}'::jsonb
          ELSE '{}'::jsonb
        END AS metadata
FROM vals
CROSS JOIN meta
ON CONFLICT (an_id) DO NOTHING;

-- Связь: напрямую из ноды результата охоты
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_witcher_events_hunt_outcome', 'wcc_witcher_events_hunt_twist'
  ;

-- Переход по окончанию цикла событий
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_witcher_events_hunt_twist', 'wcc_witcher_events_risk', r.ru_id, 1
    FROM (SELECT ru_id FROM rules WHERE name = 'lifeEventsCounter_is_valid') r;

-- i18n для eventType "Охота" (используем ON CONFLICT)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id('witcher_cc' ||'.'|| 'wcc_witcher_events_hunt' ||'.'|| 'event_type_hunt') AS id
       , 'character', 'event_type', v.lang, v.text
    FROM (VALUES
      ('ru', 'Охота'),
      ('en', 'Hunt')
    ) AS v(lang, text)
  ON CONFLICT (id, lang) DO NOTHING;

-- i18n для description "Охота" (привязка к ноде поворота)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_hunt_twist' AS qu_id
                , 'character' AS entity)
, ins_desc_hunt AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'event_desc_hunt') AS id
         , meta.entity, 'event_desc', v.lang, v.text
      FROM (VALUES
        ('ru', 'Охота'),
        ('en', 'Hunt')
      ) AS v(lang, text)
      CROSS JOIN meta
)
-- Эффект: добавление события "Охота" (только вариант 2 — поворота нет)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_witcher_events_hunt_twist_o02',
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
        jsonb_build_object('i18n_uuid', ck_id('witcher_cc' ||'.'|| 'wcc_witcher_events_hunt' ||'.'|| 'event_type_hunt')::text),
        'description',
        jsonb_build_object(
          'i18n_uuid_array',
          jsonb_build_array(
            ' - ',
            jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_witcher_events_hunt_prey'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value'))),
            jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_witcher_events_hunt_location'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value'))),
            jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_witcher_events_hunt_outcome'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))
          )
        )
      )
    )
  )
FROM meta;
































