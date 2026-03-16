\echo '049_mage_events_ally_value.sql'

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id,
           'wcc_mage_events_ally_value' AS qu_id,
           'questions' AS entity
  ),
  c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Сила'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Value')
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
           ck_id('witcher_cc.hierarchy.mage_events_ally_value')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO UPDATE
SET metadata = EXCLUDED.metadata,
    qtype = EXCLUDED.qtype;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id,
           'wcc_mage_events_ally_value' AS qu_id,
           'answer_options' AS entity,
           'label' AS entity_field
  ),
  vals AS (
    SELECT *
      FROM (VALUES
        ('ru', 1, 'Социальная сфера', 0.2::numeric),
        ('ru', 2, 'Знание', 0.2::numeric),
        ('ru', 3, 'Физическая', 0.2::numeric),
        ('ru', 4, 'Подручные', 0.2::numeric),
        ('ru', 5, 'Магия', 0.2::numeric),
        ('en', 1, 'Social', 0.2::numeric),
        ('en', 2, 'Knowledge', 0.2::numeric),
        ('en', 3, 'Physical', 0.2::numeric),
        ('en', 4, 'Minions', 0.2::numeric),
        ('en', 5, 'Magic', 0.2::numeric)
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
SELECT 'wcc_mage_events_ally_value_o' || to_char(vals.num, 'FM0000'),
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

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_life_events_allies_and_enemies.event_type_allies_and_enemies'),
       'character',
       'event_type',
       v.lang,
       v.text
  FROM (VALUES
    ('ru', 'Союзники и враги'),
    ('en', 'Allies and Enemies')
  ) AS v(lang, text)
ON CONFLICT (id, lang) DO NOTHING;

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id(v.key),
       'character',
       'ally_field',
       v.lang,
       v.text
  FROM (VALUES
    ('witcher_cc.wcc_mage_events_ally_value.how_met_academy_life_3_8', 'ru', 'Вы помогли укрыться этому магу-отступнику'),
    ('witcher_cc.wcc_mage_events_ally_value.how_met_academy_life_3_8', 'en', 'You helped shelter this rogue mage')
  ) AS v(key, lang, text)
ON CONFLICT (id, lang) DO UPDATE
SET text = EXCLUDED.text;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id,
           'wcc_mage_events_ally_value' AS qu_id,
           'character' AS entity
  ),
  ins_desc_ally AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id || '.' || meta.qu_id || '.event_desc_ally'),
           meta.entity,
           'event_desc',
           v.lang,
           v.text
      FROM (VALUES
        ('ru', 'Союзник'),
        ('en', 'Ally')
      ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
  ),
  vals AS (
    SELECT generate_series(1, 5) AS num
  )
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character',
       'wcc_mage_events_ally_value_o' || to_char(vals.num, 'FM0000'),
       jsonb_build_object(
         'when',
         jsonb_build_object(
           '!',
           jsonb_build_object(
             'in',
             jsonb_build_array(
               jsonb_build_object('var', 'characterRaw.logicFields.last_node_and_answer'),
               jsonb_build_array(
                 'academy life 1-2',
                 'academy life 3-8'
               )
             )
           )
         ),
         'add',
         jsonb_build_array(
           jsonb_build_object('var', 'characterRaw.allies'),
           jsonb_build_object(
             'gender', '',
             'position', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array(
               'witcher_cc.',
               jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_mage_events_ally_position'), jsonb_build_object('var', 'current'), NULL)),
               '.answer_options.label_value'
             )))),
             'how_met', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array(
               'witcher_cc.',
               jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_mage_events_ally_how_met'), jsonb_build_object('var', 'current'), NULL)),
               '.answer_options.label_value'
             )))),
             'how_close', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array(
               'witcher_cc.',
               jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_mage_events_ally_closeness'), jsonb_build_object('var', 'current'), NULL)),
               '.answer_options.label_value'
             )))),
             'where', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_ally_value_o' || to_char(vals.num, 'FM0000') || '.answer_options.label_value')::text),
             'value', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_ally_value_o' || to_char(vals.num, 'FM0000') || '.answer_options.label_value')::text)
           )
         )
       )
  FROM vals;

WITH vals AS (
  SELECT generate_series(1, 5) AS num
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character',
       'wcc_mage_events_ally_value_o' || to_char(vals.num, 'FM0000'),
       jsonb_build_object(
         'when',
         jsonb_build_object(
           '==',
           jsonb_build_array(
             jsonb_build_object('var', 'characterRaw.logicFields.last_node_and_answer'),
             'academy life 1-2'
           )
         ),
         'add',
         jsonb_build_array(
           jsonb_build_object('var', 'characterRaw.allies'),
           jsonb_build_object(
             'gender', '',
             'position', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_ally_position_o0008.answer_options.label_value')::text),
             'how_met', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_ally_how_met_o0001.answer_options.label_value')::text),
             'how_close', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array(
               'witcher_cc.',
               jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_mage_events_ally_closeness'), jsonb_build_object('var', 'current'), NULL)),
               '.answer_options.label_value'
             )))),
             'where', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_ally_value_o' || to_char(vals.num, 'FM0000') || '.answer_options.label_value')::text),
             'value', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_ally_value_o' || to_char(vals.num, 'FM0000') || '.answer_options.label_value')::text)
           )
         )
       )
  FROM vals;

WITH vals AS (
  SELECT generate_series(1, 5) AS num
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character',
       'wcc_mage_events_ally_value_o' || to_char(vals.num, 'FM0000'),
       jsonb_build_object(
         'when',
         jsonb_build_object(
           '==',
           jsonb_build_array(
             jsonb_build_object('var', 'characterRaw.logicFields.last_node_and_answer'),
             'academy life 3-8'
           )
         ),
         'add',
         jsonb_build_array(
           jsonb_build_object('var', 'characterRaw.allies'),
           jsonb_build_object(
             'gender', '',
             'position', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_ally_position_o0008.answer_options.label_value')::text),
             'how_met', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_ally_value.how_met_academy_life_3_8')::text),
             'how_close', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array(
               'witcher_cc.',
               jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_mage_events_ally_closeness'), jsonb_build_object('var', 'current'), NULL)),
               '.answer_options.label_value'
             )))),
             'where', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_ally_value_o' || to_char(vals.num, 'FM0000') || '.answer_options.label_value')::text),
             'value', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_ally_value_o' || to_char(vals.num, 'FM0000') || '.answer_options.label_value')::text)
           )
         )
       )
  FROM vals;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id,
           'wcc_mage_events_ally_value' AS qu_id
  )
INSERT INTO effects (scope, qu_qu_id, an_an_id, body)
SELECT 'character',
       meta.qu_id,
       NULL,
       jsonb_build_object(
         'add',
         jsonb_build_array(
           jsonb_build_object('var', 'characterRaw.lore.lifeEvents'),
           jsonb_build_object(
             'timePeriod',
             jsonb_build_object(
               'jsonlogic_expression',
               jsonb_build_object(
                 'cat',
                 jsonb_build_array(
                   jsonb_build_object('var', 'counters.lifeEventsCounter'),
                   '-',
                   jsonb_build_object('+', jsonb_build_array(
                     jsonb_build_object('var', 'counters.lifeEventsCounter'),
                     10
                   ))
                 )
               )
             ),
             'eventType',
             jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_life_events_allies_and_enemies.event_type_allies_and_enemies')::text),
             'description',
             jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id || '.' || meta.qu_id || '.event_desc_ally')::text)
           )
         )
       )
  FROM meta;
