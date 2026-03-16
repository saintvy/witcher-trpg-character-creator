\echo '046_mage_events_ally_position.sql'

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.hierarchy.mage_events_ally'), 'hierarchy', 'path', 'ru', 'Союзник'),
  (ck_id('witcher_cc.hierarchy.mage_events_ally'), 'hierarchy', 'path', 'en', 'Ally'),
  (ck_id('witcher_cc.hierarchy.mage_events_ally_position'), 'hierarchy', 'path', 'ru', 'Профессия'),
  (ck_id('witcher_cc.hierarchy.mage_events_ally_position'), 'hierarchy', 'path', 'en', 'Profession'),
  (ck_id('witcher_cc.hierarchy.mage_events_ally_how_met'), 'hierarchy', 'path', 'ru', 'Как вы встретились'),
  (ck_id('witcher_cc.hierarchy.mage_events_ally_how_met'), 'hierarchy', 'path', 'en', 'How You Met'),
  (ck_id('witcher_cc.hierarchy.mage_events_ally_closeness'), 'hierarchy', 'path', 'ru', 'Насколько вы близки'),
  (ck_id('witcher_cc.hierarchy.mage_events_ally_closeness'), 'hierarchy', 'path', 'en', 'Closeness'),
  (ck_id('witcher_cc.hierarchy.mage_events_ally_value'), 'hierarchy', 'path', 'ru', 'Сила'),
  (ck_id('witcher_cc.hierarchy.mage_events_ally_value'), 'hierarchy', 'path', 'en', 'Value')
ON CONFLICT (id, lang) DO NOTHING;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id,
           'wcc_mage_events_ally_position' AS qu_id,
           'questions' AS entity
  ),
  c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Профессия'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Profession')
  ),
  ins_cols AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id || '.' || meta.qu_id || '.' || to_char(c_vals.num, 'FM9900') || '.' || meta.entity || '.column_name'),
           meta.entity,
           'column_name',
           c_vals.lang,
           c_vals.text
      FROM c_vals
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
  )
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
SELECT meta.qu_id,
       meta.su_su_id,
       NULL,
       NULL,
       'single_table',
       jsonb_build_object(
         'dice', 'd_weighed',
         'columns', (
           SELECT jsonb_agg(
                    ck_id(meta.su_su_id || '.' || meta.qu_id || '.' || to_char(num, 'FM9900') || '.' || meta.entity || '.column_name')::text
                    ORDER BY num
                  )
             FROM (SELECT DISTINCT num FROM c_vals) cols
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
           ck_id('witcher_cc.hierarchy.mage_events_outcome')::text,
           ck_id('witcher_cc.hierarchy.mage_events_ally')::text,
           ck_id('witcher_cc.hierarchy.mage_events_ally_position')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO UPDATE
SET metadata = EXCLUDED.metadata,
    qtype = EXCLUDED.qtype;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id,
           'wcc_mage_events_ally_position' AS qu_id,
           'answer_options' AS entity,
           'label' AS entity_field
  ),
  vals AS (
    SELECT *
      FROM (VALUES
        ('ru', 1, 'Преступник', 0.1::numeric),
        ('ru', 2, 'Наемник', 0.1::numeric),
        ('ru', 3, 'Торговец', 0.1::numeric),
        ('ru', 4, 'Ремесленник', 0.1::numeric),
        ('ru', 5, 'Ученый', 0.1::numeric),
        ('ru', 6, 'Друид', 0.1::numeric),
        ('ru', 7, 'Священник', 0.1::numeric),
        ('ru', 8, 'Маг', 0.1::numeric),
        ('ru', 9, 'Рыцарь', 0.1::numeric),
        ('ru', 10, 'Аристократ', 0.1::numeric),
        ('en', 1, 'Criminal', 0.1::numeric),
        ('en', 2, 'Mercenary', 0.1::numeric),
        ('en', 3, 'Merchant', 0.1::numeric),
        ('en', 4, 'Artisan', 0.1::numeric),
        ('en', 5, 'Scholar', 0.1::numeric),
        ('en', 6, 'Druid', 0.1::numeric),
        ('en', 7, 'Priest', 0.1::numeric),
        ('en', 8, 'Mage', 0.1::numeric),
        ('en', 9, 'Knight', 0.1::numeric),
        ('en', 10, 'Noble', 0.1::numeric)
      ) AS v(lang, num, txt, probability)
  ),
  ins_label AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id || '.' || meta.qu_id || '_o' || to_char(vals.num, 'FM0000') || '.' || meta.entity || '.' || meta.entity_field),
           meta.entity,
           meta.entity_field,
           vals.lang,
           '<td style="color: grey;">' || to_char(vals.probability * 100, 'FM990.00') || '%</td><td>' || vals.txt || '</td>'
      FROM vals
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
  ),
  ins_label_value AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id || '.' || meta.qu_id || '_o' || to_char(vals.num, 'FM0000') || '.' || meta.entity || '.' || meta.entity_field || '_value'),
           meta.entity,
           meta.entity_field || '_value',
           vals.lang,
           vals.txt
      FROM vals
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
  )
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
SELECT 'wcc_mage_events_ally_position_o' || to_char(vals.num, 'FM0000'),
       meta.su_su_id,
       meta.qu_id,
       ck_id(meta.su_su_id || '.' || meta.qu_id || '_o' || to_char(vals.num, 'FM0000') || '.' || meta.entity || '.' || meta.entity_field),
       vals.num,
       jsonb_build_object('probability', vals.probability)
  FROM vals
 CROSS JOIN meta
 WHERE vals.lang = 'ru'
ON CONFLICT (an_id) DO UPDATE
SET label = EXCLUDED.label,
    sort_order = EXCLUDED.sort_order,
    metadata = EXCLUDED.metadata;
