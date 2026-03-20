\echo '054_mage_events_knowledge_details.sql'

INSERT INTO rules (ru_id, name, body)
VALUES
  (
    ck_id('witcher_cc.rules.is_mage_events_knowledge_detail_not_selected_01'),
    'is_mage_events_knowledge_detail_not_selected_01',
    '{"!":{"in":["wcc_mage_events_knowledge_details_o0001",{"var":["answers.byQuestion.wcc_mage_events_knowledge_details",[]]}]}}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_mage_events_knowledge_detail_not_selected_02'),
    'is_mage_events_knowledge_detail_not_selected_02',
    '{"!":{"in":["wcc_mage_events_knowledge_details_o0002",{"var":["answers.byQuestion.wcc_mage_events_knowledge_details",[]]}]}}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_mage_events_knowledge_detail_not_selected_03'),
    'is_mage_events_knowledge_detail_not_selected_03',
    '{"!":{"in":["wcc_mage_events_knowledge_details_o0003",{"var":["answers.byQuestion.wcc_mage_events_knowledge_details",[]]}]}}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_mage_events_knowledge_detail_not_selected_04'),
    'is_mage_events_knowledge_detail_not_selected_04',
    '{"!":{"in":["wcc_mage_events_knowledge_details_o0004",{"var":["answers.byQuestion.wcc_mage_events_knowledge_details",[]]}]}}'::jsonb
  )
ON CONFLICT (ru_id) DO UPDATE
SET name = EXCLUDED.name,
    body = EXCLUDED.body;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id,
           'wcc_mage_events_knowledge_details' AS qu_id,
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
        ('ru', 'Выберите ритуал, который вы освоили.'),
        ('en', 'Choose the ritual you mastered.')
      ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
  ),
  c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Ритуал'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Ritual')
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
         'counterIncrement', jsonb_build_object(
           'id', 'lifeEventsCounter',
           'step', 10
         ),
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
           ck_id('witcher_cc.hierarchy.mage_events_knowledge')::text,
           ck_id('witcher_cc.hierarchy.mage_events_knowledge_details')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO UPDATE
SET body = EXCLUDED.body,
    qtype = EXCLUDED.qtype,
    metadata = EXCLUDED.metadata;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id,
           'wcc_mage_events_knowledge_details' AS qu_id,
           'answer_options' AS entity,
           'label' AS entity_field
  ),
  raw_data AS (
    SELECT *
      FROM (VALUES
        ('ru', 1, 0.25::numeric, 'Гидромантия', 'is_mage_events_knowledge_detail_not_selected_01'),
        ('ru', 2, 0.25::numeric, 'Пиромантия', 'is_mage_events_knowledge_detail_not_selected_02'),
        ('ru', 3, 0.25::numeric, 'Тиромантия', 'is_mage_events_knowledge_detail_not_selected_03'),
        ('ru', 4, 0.25::numeric, 'Онейромантия', 'is_mage_events_knowledge_detail_not_selected_04'),
        ('en', 1, 0.25::numeric, 'Hydromancy', 'is_mage_events_knowledge_detail_not_selected_01'),
        ('en', 2, 0.25::numeric, 'Pyromancy', 'is_mage_events_knowledge_detail_not_selected_02'),
        ('en', 3, 0.25::numeric, 'Tyromancy', 'is_mage_events_knowledge_detail_not_selected_03'),
        ('en', 4, 0.25::numeric, 'Oneiromancy', 'is_mage_events_knowledge_detail_not_selected_04')
      ) AS v(lang, num, probability, txt, rule_name)
  ),
  vals AS (
    SELECT lang,
           num,
           probability,
           rule_name,
           '<td style="color: grey;">' || to_char(probability * 100, 'FM990.00') || '%</td><td>' || txt || '</td>' AS text
      FROM raw_data
  ),
  ins_lbl AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id || '.' || meta.qu_id || '_o' || to_char(vals.num, 'FM0000') || '.' || meta.entity || '.' || meta.entity_field),
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
SELECT 'wcc_mage_events_knowledge_details_o' || to_char(vals.num, 'FM0000'),
       meta.su_su_id,
       meta.qu_id,
       ck_id(meta.su_su_id || '.' || meta.qu_id || '_o' || to_char(vals.num, 'FM0000') || '.' || meta.entity || '.' || meta.entity_field),
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

INSERT INTO effects (scope, an_an_id, body)
VALUES
  (
    'character',
    'wcc_mage_events_knowledge_details_o0001',
    jsonb_build_object(
      'set',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.professional_gear_options.hydromancy_tokens'),
        1
      )
    )
  ),
  (
    'character',
    'wcc_mage_events_knowledge_details_o0002',
    jsonb_build_object(
      'set',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.professional_gear_options.pyromancy_tokens'),
        1
      )
    )
  ),
  (
    'character',
    'wcc_mage_events_knowledge_details_o0003',
    jsonb_build_object(
      'set',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.professional_gear_options.tyromancy_tokens'),
        1
      )
    )
  ),
  (
    'character',
    'wcc_mage_events_knowledge_details_o0004',
    jsonb_build_object(
      'set',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.professional_gear_options.oneiromancy_tokens'),
        1
      )
    )
  )
ON CONFLICT DO NOTHING;
