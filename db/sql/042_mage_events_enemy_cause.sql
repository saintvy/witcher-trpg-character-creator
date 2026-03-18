\echo '042_mage_events_enemy_cause.sql'

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_mage_events_enemy_cause' AS qu_id
                , 'questions' AS entity)
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Причина'),
      ('en', 1, 'Chance'),
      ('en', 2, 'The Cause')
)
, ins_c AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.column_name')
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
     , NULL
     , 'single_table'
     , jsonb_build_object(
         'dice', 'd_weighed',
         'columns', (
           SELECT jsonb_agg(ck_id('witcher_cc.' || meta.qu_id ||'.'|| to_char(num, 'FM9900') ||'.questions.column_name')::text ORDER BY num)
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
           ck_id('witcher_cc.hierarchy.mage_events_risk')::text,
           ck_id('witcher_cc.hierarchy.mage_events_enemy')::text,
           ck_id('witcher_cc.hierarchy.mage_events_enemy_cause')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO UPDATE
SET qtype = EXCLUDED.qtype,
    metadata = EXCLUDED.metadata;

INSERT INTO rules (ru_id, name, body)
VALUES
  (
    ck_id('witcher_cc.rules.is_enemy_cause_life_events_2_3'),
    'is_enemy_cause_life_events_2_3',
    '{"==":[{"var":"characterRaw.logicFields.last_node_and_answer"},"life events 2-3"]}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_not_enemy_cause_life_events_2_3'),
    'is_not_enemy_cause_life_events_2_3',
    '{"!=":[{"var":"characterRaw.logicFields.last_node_and_answer"},"life events 2-3"]}'::jsonb
  )
ON CONFLICT (ru_id) DO UPDATE
SET name = EXCLUDED.name,
    body = EXCLUDED.body;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_mage_events_enemy_cause' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
    SELECT ('<td style="color: grey;">' || to_char(probability * 100, 'FM990.00') || '%</td><td>' || txt || '</td>') AS text
         , txt
         , num
         , probability
         , lang
         , variant
      FROM (VALUES
        ('ru', 1, 'Сдал потерпевшую сторону', 0.1::numeric, 'default'),
        ('ru', 2, 'Нанес удар в спину потерпевшей стороне', 0.1::numeric, 'default'),
        ('ru', 3, 'Отказал потерпевшей стороне', 0.1::numeric, 'default'),
        ('ru', 4, 'Удержал потерпевшую сторону от приобретения чего-либо', 0.1::numeric, 'default'),
        ('ru', 5, 'Украл что-то у потерпевшей стороны', 0.1::numeric, 'default'),
        ('ru', 6, 'Причинил потерпевшей стороне вред', 0.1::numeric, 'default'),
        ('ru', 7, 'Пытался испортить репутацию потерпевшей стороны', 0.1::numeric, 'default'),
        ('ru', 8, 'Манипулировал потерпевшей стороной', 0.1::numeric, 'default'),
        ('ru', 9, 'Пытался отравить потерпевшую сторону', 0.1::numeric, 'default'),
        ('ru', 10, 'Оскорбил потерпевшую сторону', 0.1::numeric, 'default'),
        ('ru', 1, 'Сдал потерпевшую сторону, но вы были преданы', 0.1::numeric, 'betrayal'),
        ('ru', 2, 'Нанес удар в спину потерпевшей стороне, но вы были преданы', 0.1::numeric, 'betrayal'),
        ('ru', 3, 'Отказал потерпевшей стороне, но вы были преданы', 0.1::numeric, 'betrayal'),
        ('ru', 4, 'Удержал потерпевшую сторону от приобретения чего-либо, но вы были преданы', 0.1::numeric, 'betrayal'),
        ('ru', 5, 'Украл что-то у потерпевшей стороны, но вы были преданы', 0.1::numeric, 'betrayal'),
        ('ru', 6, 'Причинил потерпевшей стороне вред, но вы были преданы', 0.1::numeric, 'betrayal'),
        ('ru', 7, 'Пытался испортить репутацию потерпевшей стороны, но вы были преданы', 0.1::numeric, 'betrayal'),
        ('ru', 8, 'Манипулировал потерпевшей стороной, но вы были преданы', 0.1::numeric, 'betrayal'),
        ('ru', 9, 'Пытался отравить потерпевшую сторону, но вы были преданы', 0.1::numeric, 'betrayal'),
        ('ru', 10, 'Оскорбил потерпевшую сторону, но вы были преданы', 0.1::numeric, 'betrayal'),
        ('en', 1, 'Sold out the offended party', 0.1::numeric, 'default'),
        ('en', 2, 'Backstabbed the offended party', 0.1::numeric, 'default'),
        ('en', 3, 'Turned down the offended party', 0.1::numeric, 'default'),
        ('en', 4, 'Kept the offended party from acquiring something', 0.1::numeric, 'default'),
        ('en', 5, 'Stole something from the offended party', 0.1::numeric, 'default'),
        ('en', 6, 'Caused the offended party harm', 0.1::numeric, 'default'),
        ('en', 7, 'Tried to ruin the offended party''s reputation', 0.1::numeric, 'default'),
        ('en', 8, 'Manipulated the offended party', 0.1::numeric, 'default'),
        ('en', 9, 'Tried to poison the offended party', 0.1::numeric, 'default'),
        ('en', 10, 'Insulted the offended party', 0.1::numeric, 'default'),
        ('en', 1, 'Sold out the offended party, but you were betrayed', 0.1::numeric, 'betrayal'),
        ('en', 2, 'Backstabbed the offended party, but you were betrayed', 0.1::numeric, 'betrayal'),
        ('en', 3, 'Turned down the offended party, but you were betrayed', 0.1::numeric, 'betrayal'),
        ('en', 4, 'Kept the offended party from acquiring something, but you were betrayed', 0.1::numeric, 'betrayal'),
        ('en', 5, 'Stole something from the offended party, but you were betrayed', 0.1::numeric, 'betrayal'),
        ('en', 6, 'Caused the offended party harm, but you were betrayed', 0.1::numeric, 'betrayal'),
        ('en', 7, 'Tried to ruin the offended party''s reputation, but you were betrayed', 0.1::numeric, 'betrayal'),
        ('en', 8, 'Manipulated the offended party, but you were betrayed', 0.1::numeric, 'betrayal'),
        ('en', 9, 'Tried to poison the offended party, but you were betrayed', 0.1::numeric, 'betrayal'),
        ('en', 10, 'Insulted the offended party, but you were betrayed', 0.1::numeric, 'betrayal')
      ) AS v(lang, num, txt, probability, variant)
)
, ins_label AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM0000') ||
                 CASE WHEN vals.variant = 'betrayal' THEN '_betrayal' ELSE '' END ||'.'|| meta.entity ||'.'|| meta.entity_field)
         , meta.entity, meta.entity_field, vals.lang, vals.text
      FROM vals
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
)
, ins_label_value AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM0000') ||
                 CASE WHEN vals.variant = 'betrayal' THEN '_betrayal' ELSE '' END ||'.'|| meta.entity ||'.'|| meta.entity_field || '_value')
         , meta.entity, meta.entity_field || '_value', vals.lang, vals.txt
      FROM vals
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT 'wcc_mage_events_enemy_cause_o' || to_char(vals.num, 'FM0000') ||
       CASE WHEN vals.variant = 'betrayal' THEN '_betrayal' ELSE '' END
     , meta.su_su_id
     , meta.qu_id
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM0000') ||
             CASE WHEN vals.variant = 'betrayal' THEN '_betrayal' ELSE '' END ||'.'|| meta.entity ||'.'|| meta.entity_field)
     , vals.num
     , CASE
         WHEN vals.variant = 'betrayal' THEN (SELECT ru_id FROM rules WHERE name = 'is_enemy_cause_life_events_2_3' ORDER BY ru_id LIMIT 1)
         ELSE (SELECT ru_id FROM rules WHERE name = 'is_not_enemy_cause_life_events_2_3' ORDER BY ru_id LIMIT 1)
       END
     , jsonb_build_object('probability', vals.probability)
  FROM vals
 CROSS JOIN meta
 WHERE vals.lang = 'ru'
ON CONFLICT (an_id) DO UPDATE
SET label = EXCLUDED.label,
    sort_order = EXCLUDED.sort_order,
    visible_ru_ru_id = EXCLUDED.visible_ru_ru_id,
    metadata = EXCLUDED.metadata;
