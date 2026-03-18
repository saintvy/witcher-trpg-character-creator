\echo '052_mage_events_benefit_details_2.sql'

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id,
           'wcc_mage_events_benefit_details_2' AS qu_id,
           'questions' AS entity
  ),
  ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id || '.' || meta.qu_id || '.' || meta.entity || '.body'),
           meta.entity,
           'body',
           v.lang,
           v.text
      FROM (VALUES
        ('ru', 'Уточните стихию Места Силы.'),
        ('en', 'Specify the element of the Place of Power.')
      ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
  ),
  c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Стихия'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Element')
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
       ck_id(meta.su_su_id || '.' || meta.qu_id || '.' || meta.entity || '.body'),
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
         'counterIncrement', jsonb_build_object(
           'id', 'lifeEventsCounter',
           'step', 10
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
           ck_id('witcher_cc.hierarchy.mage_events_benefit')::text,
           ck_id('witcher_cc.hierarchy.mage_events_benefit_details_2')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO UPDATE
SET body = EXCLUDED.body,
    qtype = EXCLUDED.qtype,
    metadata = EXCLUDED.metadata;

WITH place_vals AS (
  SELECT generate_series(1, 23) AS num
), meta AS (
  SELECT 'witcher_cc' AS su_su_id,
         'wcc_mage_events_benefit_details_2' AS qu_id,
         'rules' AS entity
)
INSERT INTO rules (ru_id, name, body)
SELECT ck_id('witcher_cc.rules.wcc_mage_events_benefit_details_2_group_' || to_char(place_vals.num, 'FM00')),
       'wcc_mage_events_benefit_details_2_group_' || to_char(place_vals.num, 'FM00'),
       ('{"==":[{"reduce":[{"var":["answers.byQuestion.wcc_mage_events_benefit_details",[]]},{"var":"current"},null]},"wcc_mage_events_benefit_details_o09' || to_char(place_vals.num, 'FM00') || '"]}')::jsonb
  FROM place_vals
ON CONFLICT (ru_id) DO UPDATE
SET name = EXCLUDED.name,
    body = EXCLUDED.body;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id,
           'wcc_mage_events_benefit_details_2' AS qu_id,
           'answer_options' AS entity,
           'label' AS entity_field
  ),
  place_vals AS (
    SELECT generate_series(1, 23) AS group_id
  ),
  element_vals AS (
    SELECT * FROM (VALUES
      (1, 'Вода', 'Water'),
      (2, 'Воздух', 'Air'),
      (3, 'Земля', 'Earth'),
      (4, 'Огонь', 'Fire')
    ) AS v(num, ru_name, en_name)
  ),
  raw_data AS (
    SELECT 'ru' AS lang, place_vals.group_id, element_vals.num, 0.25::numeric AS probability, element_vals.ru_name AS txt,
           'wcc_mage_events_benefit_details_2_group_' || to_char(place_vals.group_id, 'FM00') AS rule_name
      FROM place_vals
      CROSS JOIN element_vals

    UNION ALL

    SELECT 'en' AS lang, place_vals.group_id, element_vals.num, 0.25::numeric AS probability, element_vals.en_name AS txt,
           'wcc_mage_events_benefit_details_2_group_' || to_char(place_vals.group_id, 'FM00') AS rule_name
      FROM place_vals
      CROSS JOIN element_vals
  ),
  vals AS (
    SELECT lang,
           group_id,
           num,
           probability,
           rule_name,
           '<td style="color: grey;">' || to_char(probability * 100, 'FM990.00') || '%</td><td>' || txt || '</td>' AS text
      FROM raw_data
  ),
  ins_lbl AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id || '.' || meta.qu_id || '_o' || to_char(100 * vals.group_id + vals.num, 'FM0000') || '.' || meta.entity || '.' || meta.entity_field),
           meta.entity,
           meta.entity_field,
           vals.lang,
           vals.text
      FROM vals
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
  )
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, visible_ru_ru_id, sort_order, metadata)
SELECT 'wcc_mage_events_benefit_details_2_o' || to_char(vals.group_id, 'FM00') || to_char(vals.num, 'FM00'),
       meta.su_su_id,
       meta.qu_id,
       ck_id(meta.su_su_id || '.' || meta.qu_id || '_o' || to_char(100 * vals.group_id + vals.num, 'FM0000') || '.' || meta.entity || '.' || meta.entity_field),
       (SELECT ru_id FROM rules WHERE name = vals.rule_name ORDER BY ru_id LIMIT 1),
       vals.num,
       jsonb_build_object('probability', vals.probability)
  FROM vals
 CROSS JOIN meta
 WHERE vals.lang = 'ru'
ON CONFLICT (an_id) DO UPDATE
SET label = EXCLUDED.label,
    visible_ru_ru_id = EXCLUDED.visible_ru_ru_id,
    sort_order = EXCLUDED.sort_order,
    metadata = EXCLUDED.metadata;
