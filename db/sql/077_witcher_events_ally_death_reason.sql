\echo '077_witcher_events_ally_death_reason.sql'

-- Вопрос: причина смерти союзника
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_ally_death_reason' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru', 'Определите причину смерти союзника.'),
        ('en', 'Determine the reason of your ally''s death.')
      ) AS v(lang, text)
      CROSS JOIN meta
  )
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Причина смерти'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Death Reason')
  )
, ins_cols AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| 'column_name') AS id
         , meta.entity, 'column_name', c_vals.lang, c_vals.text
      FROM c_vals
      CROSS JOIN meta
  )

INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
SELECT meta.qu_id
     , meta.su_su_id
     , NULL
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body')
     , 'single_table'
     , jsonb_build_object(
         'dice', 'd_weighed',
         'columns', (
           SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_witcher_events_ally_death_reason' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
           FROM (SELECT DISTINCT num FROM c_vals) AS cols
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
           ck_id('witcher_cc.hierarchy.witcher_events_ally')::text,
           ck_id('witcher_cc.hierarchy.witcher_events_ally_death_reason')::text
         )
       )
  FROM meta;

 -- Ответы (распределение по d10: 1-3, 4-6, 7-9, 10)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_ally_death_reason' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
  FROM (VALUES
     (1, 0.3, 'Нападение разбойников'),
     (2, 0.3, 'Нападение чудовища'),
     (3, 0.3, 'Война'),
     (4, 0.1, 'Мирная смерть')
  ) AS raw_data_ru(num, probability, txt)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
  FROM (VALUES
     (1, 0.3, 'Bandit Attack'),
     (2, 0.3, 'Monster Attack'),
     (3, 0.3, 'Casualty of War'),
     (4, 0.1, 'Peaceful Death')
  ) AS raw_data_en(num, probability, txt)
),
vals AS (
  SELECT
    ('<td>' || to_char(probability*100, 'FM990.00') || '%</td>'
     || '<td>' || txt || '</td>') AS text,
    num, probability, lang, txt
  FROM raw_data
)
, ins_lbl AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
       , meta.entity, meta.entity_field, vals.lang, vals.text
    FROM vals
    CROSS JOIN meta
)
, ins_lbl_value AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field || '_value') AS id
       , meta.entity, meta.entity_field || '_value', vals.lang, vals.txt
    FROM vals
    CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
SELECT
  'wcc_witcher_events_ally_death_reason_o' || to_char(vals.num, 'FM00') AS an_id,
  meta.su_su_id,
  meta.qu_id,
  ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
  vals.num,
  jsonb_build_object(
           'probability', vals.probability
  )
FROM vals
CROSS JOIN meta
ON CONFLICT (an_id) DO NOTHING;

-- Эффекты: добавление союзника в allies (привязано к вопросу)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_ally_death_reason' AS qu_id
                , 'character' AS entity)
INSERT INTO effects (scope, qu_qu_id, an_an_id, body)
SELECT 'character', meta.qu_id, NULL,
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.allies'),
      jsonb_build_object(
        'gender', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_witcher_events_ally_gender'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'position', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_witcher_events_ally_who'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'how_met', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_witcher_events_ally_how_met'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'how_close', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_witcher_events_ally_closeness'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'is_alive', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_witcher_events_ally_is_alive'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'death_reason', jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_witcher_events_ally_death_reason'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value'))))
      )
    )
  )
FROM meta;

-- i18n для eventType "Союзники и враги" (создается также в других нодах, используем ON CONFLICT)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id('witcher_cc' ||'.'|| 'wcc_life_events_allies_and_enemies' ||'.'|| 'event_type_allies_and_enemies') AS id
       , 'character', 'event_type', v.lang, v.text
    FROM (VALUES
      ('ru', 'Союзники и враги'),
      ('en', 'Allies and Enemies')
    ) AS v(lang, text)
  ON CONFLICT (id, lang) DO NOTHING;

-- Эффект: добавление события в lifeEvents (привязан к вопросу)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_ally_death_reason' AS qu_id
                , 'character' AS entity)
-- i18n для description "Союзник"
, ins_desc_ally AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'event_desc_ally') AS id
         , meta.entity, 'event_desc', v.lang, v.text
      FROM (VALUES
        ('ru', 'Союзник'),
        ('en', 'Ally')
      ) AS v(lang, text)
      CROSS JOIN meta
)
INSERT INTO effects (scope, qu_qu_id, an_an_id, body)
SELECT 'character', meta.qu_id, NULL,
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.lore.lifeEvents'),
      jsonb_build_object(
        'timePeriod',
        jsonb_build_object(
          'jsonlogic_expression', jsonb_build_object(
            'cat', jsonb_build_array(
              jsonb_build_object('var', 'counters.lifeEventsCounter'),
              '-',
              jsonb_build_object(
                '+', jsonb_build_array(
                  jsonb_build_object('var', 'counters.lifeEventsCounter'),
                  10
                )
              )
            )
          )
        ),
        'eventType',
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| 'wcc_life_events_allies_and_enemies' ||'.'|| 'event_type_allies_and_enemies')::text),
        'description',
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'event_desc_ally')::text)
      )
    )
  )
FROM meta;

-- Переходы: из ноды жив ли союзник — только по вариантам смерти
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_witcher_events_ally_is_alive', 'wcc_witcher_events_ally_death_reason', 'wcc_witcher_events_ally_is_alive_o02', 2 UNION ALL
  SELECT 'wcc_witcher_events_ally_is_alive', 'wcc_witcher_events_ally_death_reason', 'wcc_witcher_events_ally_is_alive_o03', 2 UNION ALL
  SELECT 'wcc_witcher_events_ally_is_alive', 'wcc_witcher_events_ally_death_reason', 'wcc_witcher_events_ally_is_alive_o04', 2 UNION ALL
  SELECT 'wcc_witcher_events_ally_is_alive', 'wcc_witcher_events_ally_death_reason', 'wcc_witcher_events_ally_is_alive_o05', 2 UNION ALL
  SELECT 'wcc_witcher_events_ally_is_alive', 'wcc_witcher_events_ally_death_reason', 'wcc_witcher_events_ally_is_alive_o06', 2 UNION ALL
  SELECT 'wcc_witcher_events_ally_is_alive', 'wcc_witcher_events_ally_death_reason', 'wcc_witcher_events_ally_is_alive_o07', 2 UNION ALL
  SELECT 'wcc_witcher_events_ally_is_alive', 'wcc_witcher_events_ally_death_reason', 'wcc_witcher_events_ally_is_alive_o08', 2 UNION ALL
  SELECT 'wcc_witcher_events_ally_is_alive', 'wcc_witcher_events_ally_death_reason', 'wcc_witcher_events_ally_is_alive_o09', 2 UNION ALL
  SELECT 'wcc_witcher_events_ally_is_alive', 'wcc_witcher_events_ally_death_reason', 'wcc_witcher_events_ally_is_alive_o10', 2 UNION ALL
  SELECT 'wcc_witcher_events_ally_is_alive', 'wcc_witcher_events_ally_death_reason', 'wcc_witcher_events_ally_is_alive_o11', 2
  ;

-- Переход по окончанию цикла событий
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_witcher_events_ally_death_reason', 'wcc_witcher_events_risk', r.ru_id, 1
    FROM (SELECT ru_id FROM rules WHERE name = 'lifeEventsCounter_is_valid') r;



























