\echo '040_mage_events_enemy_victim.sql'

-- Hierarchy keys for mage enemy branch
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.hierarchy.mage_events_enemy'), 'hierarchy', 'path', 'ru', 'Враг'),
  (ck_id('witcher_cc.hierarchy.mage_events_enemy'), 'hierarchy', 'path', 'en', 'Enemy'),
  (ck_id('witcher_cc.hierarchy.mage_events_enemy_victim'), 'hierarchy', 'path', 'ru', 'Кто жертва'),
  (ck_id('witcher_cc.hierarchy.mage_events_enemy_victim'), 'hierarchy', 'path', 'en', 'Who Was Wronged'),
  (ck_id('witcher_cc.hierarchy.mage_events_enemy_position'), 'hierarchy', 'path', 'ru', 'Профессия'),
  (ck_id('witcher_cc.hierarchy.mage_events_enemy_position'), 'hierarchy', 'path', 'en', 'Profession'),
  (ck_id('witcher_cc.hierarchy.mage_events_enemy_cause'), 'hierarchy', 'path', 'ru', 'Причина'),
  (ck_id('witcher_cc.hierarchy.mage_events_enemy_cause'), 'hierarchy', 'path', 'en', 'The Cause'),
  (ck_id('witcher_cc.hierarchy.mage_events_enemy_how_far'), 'hierarchy', 'path', 'ru', 'Обострение'),
  (ck_id('witcher_cc.hierarchy.mage_events_enemy_how_far'), 'hierarchy', 'path', 'en', 'Escalation'),
  (ck_id('witcher_cc.hierarchy.mage_events_enemy_power'), 'hierarchy', 'path', 'ru', 'Сила'),
  (ck_id('witcher_cc.hierarchy.mage_events_enemy_power'), 'hierarchy', 'path', 'en', 'Power')
ON CONFLICT (id, lang) DO NOTHING;

-- Question
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_mage_events_enemy_victim' AS qu_id
                , 'questions' AS entity
                , 'single'::question_type AS qtype
                , jsonb_build_object('dice', 'd0') AS metadata)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body') AS id
           , meta.entity, 'body', v.lang, v.text
        FROM (VALUES
                ('ru', 'Определите, кто был потерпевшей стороной в этой обиде.'),
                ('en', 'Determine who was the wronged party in this grudge.')
             ) AS v(lang, text)
        CROSS JOIN meta
      ON CONFLICT (id, lang) DO UPDATE
      SET text = EXCLUDED.text
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
           ck_id('witcher_cc.hierarchy.mage_events_risk')::text,
           ck_id('witcher_cc.hierarchy.mage_events_enemy')::text,
           ck_id('witcher_cc.hierarchy.mage_events_enemy_victim')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO UPDATE
SET body = EXCLUDED.body,
    qtype = EXCLUDED.qtype,
    metadata = EXCLUDED.metadata;

-- Answers
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_mage_events_enemy_victim' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
  SELECT *
    FROM (VALUES
      ('ru', 1, 'Вы'),
      ('ru', 2, 'Другая сторона'),
      ('en', 1, 'You'),
      ('en', 2, 'The Other Side')
    ) AS v(lang, num, text)
)
, ins_label AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field)
           , meta.entity, meta.entity_field, vals.lang, vals.text
        FROM vals
        CROSS JOIN meta
      ON CONFLICT (id, lang) DO UPDATE
      SET text = EXCLUDED.text
)
, ins_label_value AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field || '_value')
           , meta.entity, meta.entity_field || '_value', vals.lang, vals.text
        FROM vals
        CROSS JOIN meta
      ON CONFLICT (id, lang) DO UPDATE
      SET text = EXCLUDED.text
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
SELECT 'wcc_mage_events_enemy_victim_o' || to_char(vals.num, 'FM0000')
     , meta.su_su_id
     , meta.qu_id
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field)
     , vals.num
     , '{}'::jsonb
  FROM vals
 CROSS JOIN meta
 WHERE vals.lang = 'ru'
ON CONFLICT (an_id) DO UPDATE
SET label = EXCLUDED.label,
    sort_order = EXCLUDED.sort_order,
    metadata = EXCLUDED.metadata;
