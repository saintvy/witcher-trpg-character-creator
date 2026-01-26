\echo '040_life_events_enemy_the_power.sql'

-- Узел: 
-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_enemy_the_power' AS qu_id
                , 'questions' AS entity)
, c_vals(lang, num, text) AS (VALUES ('ru', 1, 'Шанс'),
                                     ('ru', 2, 'В чем сила врага?'),
                                     ('en', 1, 'Chance'),
                                     ('en', 2, 'What is their power?'))
, ins_c AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| 'column_name') AS id
                       , meta.entity, 'column_name', c_vals.lang, c_vals.text
				    FROM c_vals
					CROSS JOIN meta)
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
  SELECT meta.qu_id
       , meta.su_su_id
       , NULL
       , NULL
       , 'single_table'
       , jsonb_build_object(
           'dice','d_weighed',
           'columns', (
             SELECT jsonb_agg(
                      ck_id('witcher_cc' ||'.'|| 'wcc_life_events_enemy_the_power' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text
                      ORDER BY num
                    )
               FROM (SELECT DISTINCT num FROM c_vals) AS cols
           ),
           'counterIncrement', jsonb_build_object(
             'id','lifeEventsCounter',
             'step',10
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
             ck_id('witcher_cc.hierarchy.life_events_enemy')::text,
             ck_id('witcher_cc.hierarchy.life_events_enemy_power')::text
           )
         )
    FROM meta;

-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_enemy_the_power' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
           SELECT ('<td>' || to_char(probability*100, 'FM990.00') || '%</td>' ||
                   '<td>' || txt || '</td>') AS text,
                  txt,
                  num,
                  probability,
                  lang
           FROM (VALUES
                  ('ru', 1, 'Социальная сфера', 0.2::numeric),
                  ('ru', 2, 'Знание', 0.2),
                  ('ru', 3, 'Физическая сила', 0.2),
                  ('ru', 4, 'Подручные', 0.2),
                  ('ru', 5, 'Магия', 0.2),
                  ('en', 1, 'Social Power', 0.2),
                  ('en', 2, 'Knowledge', 0.2),
                  ('en', 3, 'Physical', 0.2),
                  ('en', 4, 'Minions', 0.2),
                  ('en', 5, 'Magic', 0.2)
           ) AS v(lang, num, txt, probability)
)
, ins_label AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
                     , meta.entity, meta.entity_field, vals.lang, vals.text
                  FROM vals
                  CROSS JOIN meta
)
, ins_label_value AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field || '_value') AS id
                     , meta.entity, meta.entity_field || '_value', vals.lang, vals.txt
                  FROM vals
                  CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
  SELECT 'wcc_life_events_enemy_the_power_o' || to_char(vals.num, 'FM9900') AS an_id,
         meta.su_su_id,
         meta.qu_id,
         ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
         vals.num AS sort_order,
         jsonb_build_object(
           'probability', vals.probability
         ) AS metadata
    FROM vals
    CROSS JOIN meta
  ON CONFLICT (an_id) DO NOTHING;
  
-- Эффекты для всех вариантов ответов
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_enemy_the_power' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
    SELECT num FROM (VALUES (1), (2), (3), (4), (5)) AS v(num)
)

INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_life_events_enemy_the_power_o' || to_char(vals.num, 'FM9900'),
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.enemies'),
      jsonb_build_object(
        'victim',      jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_life_events_enemy_victim'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'gender',      jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_life_events_enemy_gender'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'position',    jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_life_events_enemy_position'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'cause',       jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_life_events_enemy_cause'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'power_level', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_life_events_enemy_power_level'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'how_far',     jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_life_events_enemy_how_far'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'the_power',   jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field || '_value')::text)
      )
    )
  )
FROM vals
CROSS JOIN meta;

-- i18n для eventType "Союзники и враги" (создается также в ноде 43, используем ON CONFLICT)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id('witcher_cc' ||'.'|| 'wcc_life_events_allies_and_enemies' ||'.'|| 'event_type_allies_and_enemies') AS id
       , 'character', 'event_type', v.lang, v.text
    FROM (VALUES
      ('ru', 'Союзники и враги'),
      ('en', 'Allies and Enemies')
    ) AS v(lang, text)
  ON CONFLICT (id, lang) DO NOTHING;

-- Эффект: добавление события в lifeEvents (привязан к вопросу)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_enemy_the_power' AS qu_id
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
INSERT INTO effects (scope, qu_qu_id, an_an_id, body)
SELECT 'character', meta.qu_id, NULL,
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
  SELECT 'wcc_life_events_enemy_how_far', 'wcc_life_events_enemy_the_power';

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_life_events_enemy_the_power', 'wcc_life_events_event', r.ru_id, 1
    FROM (SELECT ru_id FROM rules WHERE name = 'lifeEventsCounter_is_valid') r;