\echo '044_mage_events_enemy_the_power.sql'

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_mage_events_enemy_the_power' AS qu_id
                , 'questions' AS entity)
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Сила'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Power')
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
           ck_id('witcher_cc.hierarchy.mage_events_enemy_power')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO UPDATE
SET qtype = EXCLUDED.qtype,
    metadata = EXCLUDED.metadata;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_mage_events_enemy_the_power' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
    SELECT ('<td style="color: grey;">' || to_char(probability * 100, 'FM990.00') || '%</td><td>' || txt || '</td>') AS text
         , txt
         , num
         , probability
         , lang
      FROM (VALUES
        ('ru', 1, 'Социальная', 0.2::numeric),
        ('ru', 2, 'Знания', 0.2::numeric),
        ('ru', 3, 'Физическая', 0.2::numeric),
        ('ru', 4, 'Подручные', 0.2::numeric),
        ('ru', 5, 'Магия', 0.2::numeric),
        ('en', 1, 'Social', 0.2::numeric),
        ('en', 2, 'Knowledge', 0.2::numeric),
        ('en', 3, 'Physical', 0.2::numeric),
        ('en', 4, 'Minions', 0.2::numeric),
        ('en', 5, 'Magic', 0.2::numeric)
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
SELECT 'wcc_mage_events_enemy_the_power_o' || to_char(vals.num, 'FM0000')
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

-- Enemy assembly
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id(v.key), 'character', 'enemy_field', v.lang, v.text
FROM (VALUES
  ('witcher_cc.wcc_mage_events_enemy_the_power.enemy_cause_academy_life_1_3', 'ru', 'Из-за вас соперницу изгнали из Аретузы'),
  ('witcher_cc.wcc_mage_events_enemy_the_power.enemy_cause_academy_life_1_3', 'en', 'Your rival was expelled from Aretuza because of you'),
  ('witcher_cc.wcc_mage_events_enemy_the_power.enemy_cause_academy_life_2_6', 'ru', 'Вы испортили им день, наложив заклинание'),
  ('witcher_cc.wcc_mage_events_enemy_the_power.enemy_cause_academy_life_2_6', 'en', 'You ruined their day by casting a spell on them'),
  ('witcher_cc.wcc_mage_events_enemy_the_power.enemy_cause_academy_life_3_6', 'ru', 'По чужой просьбе вы подвергли их цензуре'),
  ('witcher_cc.wcc_mage_events_enemy_the_power.enemy_cause_academy_life_3_6', 'en', 'At someone else''s request, you censored them'),
  ('witcher_cc.wcc_mage_events_enemy_the_power.enemy_cause_life_events_2_9', 'ru', 'Вы стали соперниками'),
  ('witcher_cc.wcc_mage_events_enemy_the_power.enemy_cause_life_events_2_9', 'en', 'You became rivals')
) AS v(key, lang, text)
ON CONFLICT (id, lang) DO UPDATE
SET text = EXCLUDED.text;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_mage_events_enemy_the_power' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
    SELECT num FROM (VALUES (1), (2), (3), (4), (5)) AS v(num)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_mage_events_enemy_the_power_o' || to_char(vals.num, 'FM0000'),
  jsonb_build_object(
    'when',
    jsonb_build_object(
      '!',
      jsonb_build_object(
        'in',
        jsonb_build_array(
          jsonb_build_object('var', 'characterRaw.logicFields.last_node_and_answer'),
          jsonb_build_array(
            'academy life 1-3',
            'academy life 2-6',
            'academy life 3-6',
            'life events 2-3',
            'life events 2-5',
            'life events 2-9'
          )
        )
      )
    ),
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.enemies'),
      jsonb_build_object(
        'gender', '',
        'victim', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_mage_events_enemy_victim'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'position', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_mage_events_enemy_position'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'cause', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_mage_events_enemy_cause'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'power_level', '',
        'how_far', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_mage_events_enemy_how_far'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'the_power', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field || '_value')::text)
      )
    )
  )
FROM vals
CROSS JOIN meta;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_mage_events_enemy_the_power' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
    SELECT num FROM (VALUES (1), (2), (3), (4), (5)) AS v(num)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_mage_events_enemy_the_power_o' || to_char(vals.num, 'FM0000'),
  jsonb_build_object(
    'when',
    jsonb_build_object(
      '==',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.logicFields.last_node_and_answer'),
        'life events 2-3'
      )
    ),
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.enemies'),
      jsonb_build_object(
        'gender', '',
        'victim', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_enemy_victim_o0001.answer_options.label_value')::text),
        'position', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_mage_events_enemy_position'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'cause', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_mage_events_enemy_cause'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'power_level', '',
        'how_far', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_mage_events_enemy_how_far'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'the_power', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field || '_value')::text)
      )
    )
  )
FROM vals
CROSS JOIN meta;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_mage_events_enemy_the_power' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
    SELECT num FROM (VALUES (1), (2), (3), (4), (5)) AS v(num)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_mage_events_enemy_the_power_o' || to_char(vals.num, 'FM0000'),
  jsonb_build_object(
    'when',
    jsonb_build_object(
      '==',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.logicFields.last_node_and_answer'),
        'academy life 1-3'
      )
    ),
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.enemies'),
      jsonb_build_object(
        'gender', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_life_events_enemy_gender_o0002.answer_options.label_value')::text),
        'victim', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_enemy_victim_o0002.answer_options.label_value')::text),
        'position', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_enemy_position_o0008.answer_options.label_value')::text),
        'cause', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_enemy_the_power.enemy_cause_academy_life_1_3')::text),
        'power_level', '',
        'how_far', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_mage_events_enemy_how_far'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'the_power', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field || '_value')::text)
      )
    )
  )
FROM vals
CROSS JOIN meta;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_mage_events_enemy_the_power' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
    SELECT num FROM (VALUES (1), (2), (3), (4), (5)) AS v(num)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_mage_events_enemy_the_power_o' || to_char(vals.num, 'FM0000'),
  jsonb_build_object(
    'when',
    jsonb_build_object(
      '==',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.logicFields.last_node_and_answer'),
        'academy life 2-6'
      )
    ),
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.enemies'),
      jsonb_build_object(
        'gender', '',
        'victim', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_enemy_victim_o0002.answer_options.label_value')::text),
        'position', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_mage_events_enemy_position'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'cause', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_enemy_the_power.enemy_cause_academy_life_2_6')::text),
        'power_level', '',
        'how_far', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_mage_events_enemy_how_far'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'the_power', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field || '_value')::text)
      )
    )
  )
FROM vals
CROSS JOIN meta;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_mage_events_enemy_the_power' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
    SELECT num FROM (VALUES (1), (2), (3), (4), (5)) AS v(num)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_mage_events_enemy_the_power_o' || to_char(vals.num, 'FM0000'),
  jsonb_build_object(
    'when',
    jsonb_build_object(
      '==',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.logicFields.last_node_and_answer'),
        'academy life 3-6'
      )
    ),
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.enemies'),
      jsonb_build_object(
        'gender', '',
        'victim', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_enemy_victim_o0002.answer_options.label_value')::text),
        'position', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_mage_events_enemy_position'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'cause', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_enemy_the_power.enemy_cause_academy_life_3_6')::text),
        'power_level', '',
        'how_far', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_mage_events_enemy_how_far'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'the_power', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field || '_value')::text)
      )
    )
  )
FROM vals
CROSS JOIN meta;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_mage_events_enemy_the_power' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
    SELECT num FROM (VALUES (1), (2), (3), (4), (5)) AS v(num)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_mage_events_enemy_the_power_o' || to_char(vals.num, 'FM0000'),
  jsonb_build_object(
    'when',
    jsonb_build_object(
      '==',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.logicFields.last_node_and_answer'),
        'life events 2-9'
      )
    ),
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.enemies'),
      jsonb_build_object(
        'gender', '',
        'victim', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_enemy_victim_o0002.answer_options.label_value')::text),
        'position', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_mage_events_enemy_position'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'cause', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_enemy_the_power.enemy_cause_life_events_2_9')::text),
        'power_level', '',
        'how_far', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_mage_events_enemy_how_far'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'the_power', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field || '_value')::text)
      )
    )
  )
FROM vals
CROSS JOIN meta;

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
                , 'wcc_mage_events_enemy_the_power' AS qu_id
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
INSERT INTO effects (scope, qu_qu_id, an_an_id, body)
SELECT
  'character',
  meta.qu_id,
  NULL,
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.lifeEvents'),
      jsonb_build_object(
        'timePeriod', jsonb_build_object(
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
FROM meta;

WITH vals AS (
    SELECT num FROM (VALUES (1), (2), (3), (4), (5)) AS v(num)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_mage_events_enemy_the_power_o' || to_char(vals.num, 'FM0000'),
  jsonb_build_object(
    'when',
    '{
      "or": [
        {"==": [{"var": "characterRaw.logicFields.flags.academy_life"}, 1]},
        {"==": [{"var": "characterRaw.logicFields.flags.academy_life"}, 2]}
      ]
    }'::jsonb,
    'inc',
    jsonb_build_array(
      jsonb_build_object('var', 'counters.lifeEventsCounter'),
      10
    )
  )
FROM vals;

-- transitions
