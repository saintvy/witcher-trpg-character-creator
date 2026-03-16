\echo '043_mage_events_enemy_how_far.sql'

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_mage_events_enemy_how_far' AS qu_id
                , 'questions' AS entity)
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Обострение'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Escalation')
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
           ck_id('witcher_cc.hierarchy.mage_events_enemy_how_far')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO UPDATE
SET qtype = EXCLUDED.qtype,
    metadata = EXCLUDED.metadata;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_mage_events_enemy_how_far' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
    SELECT ('<td style="color: grey;">' || to_char(probability * 100, 'FM990.00') || '%</td><td>' || txt || '</td>') AS text
         , txt
         , num
         , probability
         , lang
      FROM (VALUES
        ('ru', 1, 'Он или вы забыли об этом', 0.1::numeric),
        ('ru', 2, 'Он или вы в поисках друг друга', 0.1::numeric),
        ('ru', 3, 'Он или вы простили агрессора, но обида может вернуться', 0.1::numeric),
        ('ru', 4, 'Он или вы активно плетете интриги против друг друга', 0.1::numeric),
        ('ru', 5, 'Он или вы не хотите иметь ничего общего с друг с другом', 0.1::numeric),
        ('ru', 6, 'Он или вы планируете преследовать их или ваших близких', 0.1::numeric),
        ('ru', 7, 'Он или вы пытаетесь мешать другому', 0.1::numeric),
        ('ru', 8, 'Он или вы распространяете вредные сплетни', 0.1::numeric),
        ('ru', 9, 'Он или вы достаточно злы, чтобы впасть в ярость при вашей следующей встрече', 0.1::numeric),
        ('ru', 10, 'Он или вы ищете союзников, чтобы навредить ему', 0.1::numeric),
        ('en', 1, 'They/you have forgotten about it', 0.1::numeric),
        ('en', 2, 'They/you are on the lookout', 0.1::numeric),
        ('en', 3, 'They/you have forgiven the aggressor but could be pushed back', 0.1::numeric),
        ('en', 4, 'They/you are actively scheming against the other', 0.1::numeric),
        ('en', 5, 'They/you want nothing to do with the other', 0.1::numeric),
        ('en', 6, 'They/you are planning to go after the other''s loved ones', 0.1::numeric),
        ('en', 7, 'They/you are trying to sabotage the other', 0.1::numeric),
        ('en', 8, 'They/you are just spreading harmful rumors', 0.1::numeric),
        ('en', 9, 'They/you are mad enough to fly into a rage at your next meeting', 0.1::numeric),
        ('en', 10, 'They/you are looking for allies to hurt the other', 0.1::numeric)
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
SELECT 'wcc_mage_events_enemy_how_far_o' || to_char(vals.num, 'FM0000')
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

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_life_events_allies_and_enemies.event_type_allies_and_enemies')
     , 'character', 'event_type', v.lang, v.text
  FROM (VALUES
    ('ru', 'Союзники и враги'),
    ('en', 'Allies and Enemies')
  ) AS v(lang, text)
ON CONFLICT (id, lang) DO NOTHING;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_mage_events_enemy_how_far' AS qu_id
                , 'character' AS entity)
, ins_desc_enemy AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.event_desc_enemy')
       , meta.entity, 'event_desc', v.lang, v.text
    FROM (VALUES
      ('ru', 'Враг'),
      ('en', 'Enemy')
    ) AS v(lang, text)
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO UPDATE
  SET text = EXCLUDED.text
)
, vals AS (
  SELECT generate_series(1, 10) AS num
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_mage_events_enemy_how_far_o' || to_char(vals.num, 'FM0000'),
  jsonb_build_object(
    'when',
    jsonb_build_object(
      '==',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.logicFields.last_node_and_answer'),
        'life events 2-5'
      )
    ),
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.enemies'),
      jsonb_build_object(
        'gender', '',
        'victim', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_enemy_victim_o0002.answer_options.label_value')::text),
        'position', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_mage_events_enemy_position'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'cause', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_enemy_cause_o0008.answer_options.label_value')::text),
        'power_level', '',
        'how_far', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_enemy_how_far_o' || to_char(vals.num, 'FM0000') || '.answer_options.label_value')::text),
        'the_power', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_enemy_the_power_o0004.answer_options.label_value')::text)
      )
    )
  )
FROM vals;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_mage_events_enemy_how_far' AS qu_id)
, vals AS (
  SELECT generate_series(1, 10) AS num
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_mage_events_enemy_how_far_o' || to_char(vals.num, 'FM0000'),
  jsonb_build_object(
    'when',
    jsonb_build_object(
      '==',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.logicFields.last_node_and_answer'),
        'life events 2-5'
      )
    ),
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.lifeEvents'),
      jsonb_build_object(
        'timePeriod',
        jsonb_build_object(
          'jsonlogic_expression', jsonb_build_object(
            'cat', jsonb_build_array(
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
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.event_desc_enemy')::text)
      )
    )
  )
FROM vals
CROSS JOIN meta;
