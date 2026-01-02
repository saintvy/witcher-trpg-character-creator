\echo '023_life_events_fortune_or_not.sql'

-- Узел: Выжные события - Удача или неудача
-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_fortune_or_not' AS qu_id
                , 'questions' AS entity
                , 'single'::question_type AS qtype
	              , jsonb_build_object('dice','d0') AS metadata)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| v.entity_field) AS id
           , meta.entity, v.entity_field, v.lang, v.text
        FROM (VALUES
                ('ru', 'Определите какое событие случилось с вами в соответствующей декаде.', 'body'),
                ('en', 'Determine what event occurred to you during that decade.', 'body')
             ) AS v(lang, text, entity_field)
        CROSS JOIN meta
      RETURNING id AS body_id
)
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
  SELECT meta.qu_id
       , meta.su_su_id
       , NULL
       , (SELECT DISTINCT body_id FROM ins_body)
       , meta.qtype
	     , meta.metadata || jsonb_build_object(
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
            ck_id('witcher_cc.hierarchy.life_events_fortune_or_not')::text
          )
        )
     FROM meta;
	   
-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_fortune_or_not' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
  SELECT v.*
  FROM (VALUES ('ru', 1, 'Удача'),
               ('ru', 2, 'Неудача'),
               ('en', 1, 'Fortune'),
               ('en', 2, 'Misfortune')
         ) AS v(lang, num, text)
)
, ins_label AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
           , meta.entity, meta.entity_field, vals.lang, vals.text
        FROM vals
        CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
  SELECT 'wcc_life_events_fortune_or_not_o' || to_char(vals.num, 'FM9900') AS an_id,
         meta.su_su_id,
         meta.qu_id,
         ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
         vals.num AS sort_order,
         '{}'::jsonb AS metadata
    FROM vals
    CROSS JOIN meta
  ON CONFLICT (an_id) DO NOTHING;
  
-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id)
  SELECT 'wcc_life_events_event', 'wcc_life_events_fortune_or_not', 'wcc_life_events_event_o01';