\echo '047_life_events_lovestory.sql'

-- Узел: 
-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_relationshipsstory' AS qu_id
                , 'questions' AS entity)
, c_vals(lang, num, text) AS (VALUES ('ru', 1, 'Шанс'),
                                     ('ru', 2, 'Любовная связь'),
                                     ('en', 1, 'Chance'),
                                     ('en', 2, 'Love Affair'))
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
                      ck_id('witcher_cc' ||'.'|| 'wcc_life_events_relationshipsstory' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text
                      ORDER BY num
                    )
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
             ck_id('witcher_cc.hierarchy.life_events_relationships')::text,
             ck_id('witcher_cc.hierarchy.life_events_relationships_type')::text
           )
         )
    FROM meta;

-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_relationshipsstory' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
           SELECT ('<td>' || to_char(probability*100, 'FM990.00') || '%</td>' ||
                   '<td>' || txt || '</td>') AS text,
                  num,
                  probability,
                  lang,
                  txt
           FROM (VALUES
                  ('ru', 1, 'Счастливая любовь', 0.1::numeric),
                  ('ru', 2, 'Романтическая трагедия', 0.3),
                  ('ru', 3, 'Трудная любовь', 0.2),
                  ('ru', 4, 'Шлюхи и разгул', 0.4),
                  ('en', 1, 'A Happy Love Affair', 0.1),
                  ('en', 2, 'A Romantic Tragedy', 0.3),
                  ('en', 3, 'A Problematic Love', 0.2),
                  ('en', 4, 'Whores and Debauchery', 0.4)
           ) AS v(lang, num, txt, probability)
)
, ins_label AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
                     , meta.entity, meta.entity_field, vals.lang, vals.text
                  FROM vals
                  CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
  SELECT 'wcc_life_events_relationshipsstory_o' || to_char(vals.num, 'FM9900') AS an_id,
         meta.su_su_id,
         meta.qu_id,
         ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
         vals.num AS sort_order,
         jsonb_build_object(
           'probability', vals.probability
         ) || CASE WHEN to_char(vals.num, 'FM00')
                     IN ('02','03') THEN '{}'::jsonb
                     ELSE jsonb_build_object( 'counterIncrement'
                                            , jsonb_build_object('id', 'lifeEventsCounter', 'step', 10))
              END
         AS metadata
    FROM vals
    CROSS JOIN meta
  ON CONFLICT (an_id) DO NOTHING;
  
-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_life_events_event', 'wcc_life_events_relationshipsstory', 'wcc_life_events_event_o03', 2;

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_life_events_relationshipsstory', 'wcc_life_events_event', r.ru_id, 1
    FROM (SELECT ru_id FROM rules WHERE name = 'lifeEventsCounter_is_valid') r;

-- i18n для eventType "Отношения" / "Relationships" (если еще не создан)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id('witcher_cc' ||'.'|| 'wcc_life_events_relationships' ||'.'|| 'event_type_relationships') AS id
       , 'character', 'event_type', v.lang, v.text
    FROM (VALUES
      ('ru', 'Отношения'),
      ('en', 'Relationships')
    ) AS v(lang, text)
  ON CONFLICT (id, lang) DO NOTHING;

-- i18n для кратких описаний событий (варианты 1 и 4)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_relationshipsstory' AS qu_id
                , 'character' AS entity)
, desc_vals AS (
  SELECT v.*
  FROM (VALUES
    -- RU: Happy Love Affair (option 1)
    ('ru', 1, 'Любовь: Счастливая и взаимная любовная связь'),
    -- RU: Whores and Debauchery (option 4)
    ('ru', 4, 'Кутёж: Разгул, продажная любовь и разврат'),
    -- EN: Happy Love Affair (option 1)
    ('en', 1, 'Love: A Happy and Mutual Love Affair'),
    -- EN: Whores and Debauchery (option 4)
    ('en', 4, 'Prostitution: Whores, Debauchery and Vice')
  ) AS v(lang, num, text)
)
, ins_desc AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(desc_vals.num, 'FM9900') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', desc_vals.lang, desc_vals.text
      FROM desc_vals
      CROSS JOIN meta
)
-- Эффект: добавление события в lifeEvents для вариантов 1 и 4 (answer-level)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_life_events_relationshipsstory_o' || to_char(event_nums.num, 'FM9900'),
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
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| 'wcc_life_events_relationships' ||'.'|| 'event_type_relationships')::text),
        'description',
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(event_nums.num, 'FM9900') ||'.'|| 'event_desc')::text)
      )
    )
  )
FROM (VALUES (1), (4)) AS event_nums(num)
CROSS JOIN meta;