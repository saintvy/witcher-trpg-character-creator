\echo '045_life_events_ally_where.sql'

-- Узел: 
-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_ally_where' AS qu_id
                , 'questions' AS entity)
, c_vals(lang, num, text) AS (VALUES ('ru', 1, 'Шанс'),
                                     ('ru', 2, 'Регион'),
                                     ('en', 1, 'Chance'),
                                     ('en', 2, 'Region'))
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
                      ck_id('witcher_cc' ||'.'|| 'wcc_life_events_ally_where' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text
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
             ck_id('witcher_cc.hierarchy.life_events_ally')::text,
             ck_id('witcher_cc.hierarchy.life_events_ally_where')::text
           )
         )
    FROM meta;

-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_ally_where' AS qu_id
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
                  ('ru', 1, 'Королевства Севера', 0.3::numeric),
                  ('ru', 2, 'Империя Нильфгаард', 0.3),
                  ('ru', 3, 'Земли Старших Народов', 0.3),
                  ('ru', 4, 'За пределами', 0.1),
                  ('en', 1, 'The Northern Kingdoms', 0.3),
                  ('en', 2, 'The Empire of Nilfgaard', 0.3),
                  ('en', 3, 'Elder Lands', 0.3),
                  ('en', 4, 'Beyond the Boundaries', 0.1)
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
  SELECT 'wcc_life_events_ally_where_o' || to_char(vals.num, 'FM9900') AS an_id,
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
                , 'wcc_life_events_ally_where' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
    SELECT num FROM (VALUES (1), (2), (3), (4)) AS v(num)
)

INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_life_events_ally_where_o' || to_char(vals.num, 'FM9900'),
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.allies'),
      jsonb_build_object(
        'gender',    jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_life_events_ally_gender'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'position',  jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_life_events_ally_position'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'how_met',   jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_life_events_ally_how_met'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'how_close', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_life_events_ally_how_close'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'where',     jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field || '_value')::text)
      )
    )
  )
FROM vals
CROSS JOIN meta;

-- i18n для eventType "Союзники и враги" (создается также в ноде 38, используем ON CONFLICT)
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
                , 'wcc_life_events_ally_where' AS qu_id
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
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'event_desc_ally')::text)
      )
    )
  )
FROM meta;
  
-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_life_events_ally_how_close', 'wcc_life_events_ally_where';

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_life_events_ally_where', 'wcc_life_events_event', r.ru_id, 1
    FROM (SELECT ru_id FROM rules WHERE name = 'lifeEventsCounter_is_valid') r;