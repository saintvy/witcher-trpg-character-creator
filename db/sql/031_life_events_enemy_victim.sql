\echo '031_life_events_enemy_victim.sql'

-- Узел: Выжные события - Кто потерпевший
-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_enemy_victim' AS qu_id
                , 'questions' AS entity
                , 'single'::question_type AS qtype
	              , jsonb_build_object('dice','d0') AS metadata)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| v.entity_field) AS id
           , meta.entity, v.entity_field, v.lang, v.text
        FROM (VALUES
                ('ru', 'Определите кто был потерпевшим в вашем конфликте.', 'body'),
                ('en', 'Determine who was wronged in your conflict.', 'body')
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
            ck_id('witcher_cc.hierarchy.life_events_enemy')::text,
            ck_id('witcher_cc.hierarchy.life_events_enemy_victim')::text
          )
        )
     FROM meta;
	   
-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_enemy_victim' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
  SELECT v.*
  FROM (VALUES ('ru', 1, 'Ваш персонаж — потерпевшая сторона.'),
               ('ru', 2, 'Враг — потерпевшая сторона.'),
               ('en', 1, 'You were the one who was wronged.'),
               ('en', 2, 'You wronged someone else.')
         ) AS v(lang, num, text)
)
, ins_label AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
           , meta.entity, meta.entity_field, vals.lang, vals.text
        FROM vals
        CROSS JOIN meta
)
, ins_label_value AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field || '_value') AS id
           , meta.entity, meta.entity_field || '_value', vals.lang, vals.text
        FROM vals
        CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
  SELECT 'wcc_life_events_enemy_victim_o' || to_char(vals.num, 'FM9900') AS an_id,
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
  SELECT 'wcc_life_events_allies_and_enemies_who', 'wcc_life_events_enemy_victim', 'wcc_life_events_allies_and_enemies_who_o02';