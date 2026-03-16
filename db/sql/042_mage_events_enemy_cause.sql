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
      FROM (VALUES
        ('ru', 1, 'Сдал потерпевшую сторону', 0.1::numeric),
        ('ru', 2, 'Нанес удар в спину потерпевшей стороне', 0.1::numeric),
        ('ru', 3, 'Отказал потерпевшей стороне', 0.1::numeric),
        ('ru', 4, 'Удержал потерпевшую сторону от приобретения чего-либо', 0.1::numeric),
        ('ru', 5, 'Украл что-то у потерпевшей стороны', 0.1::numeric),
        ('ru', 6, 'Причинил потерпевшей стороне вред', 0.1::numeric),
        ('ru', 7, 'Пытался испортить репутацию потерпевшей стороны', 0.1::numeric),
        ('ru', 8, 'Манипулировал потерпевшей стороной', 0.1::numeric),
        ('ru', 9, 'Пытался отравить потерпевшую сторону', 0.1::numeric),
        ('ru', 10, 'Оскорбил потерпевшую сторону', 0.1::numeric),
        ('en', 1, 'Sold out the offended party', 0.1::numeric),
        ('en', 2, 'Backstabbed the offended party', 0.1::numeric),
        ('en', 3, 'Turned down the offended party', 0.1::numeric),
        ('en', 4, 'Kept the offended party from acquiring something', 0.1::numeric),
        ('en', 5, 'Stole something from the offended party', 0.1::numeric),
        ('en', 6, 'Caused the offended party harm', 0.1::numeric),
        ('en', 7, 'Tried to ruin the offended party''s reputation', 0.1::numeric),
        ('en', 8, 'Manipulated the offended party', 0.1::numeric),
        ('en', 9, 'Tried to poison the offended party', 0.1::numeric),
        ('en', 10, 'Insulted the offended party', 0.1::numeric)
      ) AS v(lang, num, txt, probability)
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
         , meta.entity, meta.entity_field || '_value', vals.lang, vals.txt
      FROM vals
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
SELECT 'wcc_mage_events_enemy_cause_o' || to_char(vals.num, 'FM0000')
     , meta.su_su_id
     , meta.qu_id
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field)
     , vals.num
     , jsonb_build_object('probability', vals.probability)
  FROM vals
 CROSS JOIN meta
 WHERE vals.lang = 'ru'
ON CONFLICT (an_id) DO UPDATE
SET label = EXCLUDED.label,
    sort_order = EXCLUDED.sort_order,
    metadata = EXCLUDED.metadata;
