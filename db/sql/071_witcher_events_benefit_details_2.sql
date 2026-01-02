\echo '071_witcher_events_benefit_details_2.sql'

-- Вопрос: уточнения к опасностям ведьмака
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_benefit_details_2' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id,entity,entity_field,lang,text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru','Раскройте подробности выбранной выгоды.'),
        ('en','Pick the specific outcome for your benefit.')
      ) AS v(lang,text)
      CROSS JOIN meta
  )
, c_vals(lang,num,text) AS (
    VALUES
      ('ru',1,'Шанс'),
      ('ru',2,'Уточнение'),
      ('en',1,'Chance'),
      ('en',2,'Detail')
  )
, ins_cols AS (
    INSERT INTO i18n_text (id,entity,entity_field,lang,text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| 'column_name') AS id
         , meta.entity, 'column_name', c_vals.lang, c_vals.text
      FROM c_vals
      CROSS JOIN meta
  )

INSERT INTO questions (qu_id,su_su_id,title,body,qtype,metadata)
SELECT meta.qu_id
     , meta.su_su_id
     , NULL
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body')
     , 'single_table'
     , jsonb_build_object(
         'dice', 'd_weighed',
         'columns', (
           SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_witcher_events_benefit_details_2' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
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
           ck_id('witcher_cc.hierarchy.witcher_events_benefit')::text,
           ck_id('witcher_cc.hierarchy.witcher_events_benefit_details_2')::text
         )
       )
  FROM meta;

-- Ответы (RU/EN)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_benefit_details_2' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
      -- 107. Случайная находка
      ( 107, 1, 0.1666, '<b>Случайная находка</b>: драгоценность стоимостью 10 крон'),
      ( 107, 2, 0.1666, '<b>Случайная находка</b>: драгоценность стоимостью 20 крон'),
      ( 107, 3, 0.1666, '<b>Случайная находка</b>: драгоценность стоимостью 30 крон'),
      ( 107, 4, 0.1666, '<b>Случайная находка</b>: драгоценность стоимостью 40 крон'),
      ( 107, 5, 0.1666, '<b>Случайная находка</b>: драгоценность стоимостью 50 крон'),
      ( 107, 6, 0.1666, '<b>Случайная находка</b>: драгоценность стоимостью 60 крон')
    ) AS raw_data_ru(group_id, num, probability, txt)

  UNION ALL

  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
    -- 107. Random Boon
    ( 107, 1, 0.1666, '<b>Random Boon</b>: jewelry worth 10 crowns'),
    ( 107, 2, 0.1666, '<b>Random Boon</b>: jewelry worth 20 crowns'),
    ( 107, 3, 0.1666, '<b>Random Boon</b>: jewelry worth 30 crowns'),
    ( 107, 4, 0.1666, '<b>Random Boon</b>: jewelry worth 40 crowns'),
    ( 107, 5, 0.1666, '<b>Random Boon</b>: jewelry worth 50 crowns'),
    ( 107, 6, 0.1666, '<b>Random Boon</b>: jewelry worth 60 crowns')
  ) AS raw_data_en(group_id, num, probability, txt)
),

vals AS (
  SELECT ('<td>'||to_char(probability*100,'FM990.00')||'%</td>'
         ||'<td>'||txt||'</td>') AS text
       , group_id
       , num
       , probability
       , lang
  FROM raw_data
)
, ins_lbl AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.group_id, 'FM0000') || to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field)
       , meta.entity, meta.entity_field, vals.lang, vals.text
    FROM vals
    CROSS JOIN meta
)

, rules_vals(group_id, id, body) AS (
    SELECT v.group_id
         , gen_random_uuid()
         , ('{ "==":
                [
                  { "reduce":
                      [
                        { "var": ["answers.byQuestion.wcc_witcher_events_benefit_details", []] },
                        { "var": "current" },
                        null
                      ]
                  },
                  "wcc_witcher_events_benefit_details_o' || to_char(group_id, 'FM0000') || '"
                ]
            }')::jsonb FROM (SELECT DISTINCT group_id FROM raw_data) v(group_id)
),
ins_rules AS (
  INSERT INTO rules(ru_id, body) SELECT r.id, r.body FROM rules_vals r
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, visible_ru_ru_id, sort_order,metadata)
SELECT
  'wcc_witcher_events_benefit_details_o'||to_char(vals.group_id, 'FM0000')||to_char(vals.num, 'FM9900'),
  meta.su_su_id,
  meta.qu_id,
  ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.group_id, 'FM0000') || to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
  r.id,
  vals.num,
  jsonb_build_object(
           'probability', vals.probability
  )
FROM vals
CROSS JOIN meta
JOIN rules_vals r ON vals.group_id = r.group_id
ON CONFLICT (an_id) DO NOTHING;

-- Эффекты
WITH
  raw_data AS (
    SELECT DISTINCT num FROM (VALUES
      (107, 1), (107, 2), (107, 3), (107, 4), (107, 5), (107, 6)
    ) AS v(group_id, num)
    WHERE group_id = 107
  )
, meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_benefit_details_2' AS qu_id
                , 'character' AS entity)
-- i18n для eventType "Fortune"/"Удача"
, ins_event_type_fortune AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id('witcher_cc' ||'.'|| 'wcc_life_events_fortune' ||'.'|| 'event_type_fortune') AS id
         , meta.entity, 'event_type', v.lang, v.text
      FROM (VALUES
        ('ru', 'Удача'),
        ('en', 'Fortune')
      ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
)
-- i18n для описаний событий группы 107
, ins_desc_107 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(107, 'FM0000') || to_char(vals.num, 'FM00') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Право Неожиданности: получена драгоценность стоимостью 10 крон.'),
        ('ru', 2, 'Право Неожиданности: получена драгоценность стоимостью 20 крон.'),
        ('ru', 3, 'Право Неожиданности: получена драгоценность стоимостью 30 крон.'),
        ('ru', 4, 'Право Неожиданности: получена драгоценность стоимостью 40 крон.'),
        ('ru', 5, 'Право Неожиданности: получена драгоценность стоимостью 50 крон.'),
        ('ru', 6, 'Право Неожиданности: получена драгоценность стоимостью 60 крон.'),
        ('en', 1, 'Law of Surprises: received jewelry worth 10 crowns.'),
        ('en', 2, 'Law of Surprises: received jewelry worth 20 crowns.'),
        ('en', 3, 'Law of Surprises: received jewelry worth 30 crowns.'),
        ('en', 4, 'Law of Surprises: received jewelry worth 40 crowns.'),
        ('en', 5, 'Law of Surprises: received jewelry worth 50 crowns.'),
        ('en', 6, 'Law of Surprises: received jewelry worth 60 crowns.')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- i18n для gear items группы 107
, ins_gear_107 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(107, 'FM0000') || to_char(vals.num, 'FM00') ||'.'|| 'gear_name') AS id
         , 'gear', 'name', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Драгоценность (10 крон)'),
        ('ru', 2, 'Драгоценность (20 крон)'),
        ('ru', 3, 'Драгоценность (30 крон)'),
        ('ru', 4, 'Драгоценность (40 крон)'),
        ('ru', 5, 'Драгоценность (50 крон)'),
        ('ru', 6, 'Драгоценность (60 крон)'),
        ('en', 1, 'Jewelry (10 crowns)'),
        ('en', 2, 'Jewelry (20 crowns)'),
        ('en', 3, 'Jewelry (30 crowns)'),
        ('en', 4, 'Jewelry (40 crowns)'),
        ('en', 5, 'Jewelry (50 crowns)'),
        ('en', 6, 'Jewelry (60 crowns)')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
INSERT INTO effects (scope, an_an_id, body)
-- Группа 107: lifeEvents + gear
SELECT DISTINCT
  'character', 'wcc_witcher_events_benefit_details_o' || to_char(107, 'FM0000') || to_char(raw_data.num, 'FM00'),
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
        jsonb_build_object('i18n_uuid', ck_id('witcher_cc' ||'.'|| 'wcc_life_events_fortune' ||'.'|| 'event_type_fortune')::text),
        'description',
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(107, 'FM0000') || to_char(raw_data.num, 'FM00') ||'.'|| 'event_desc')::text)
      )
    )
  )
FROM raw_data
CROSS JOIN meta
UNION ALL
SELECT DISTINCT
  'character', 'wcc_witcher_events_benefit_details_o' || to_char(107, 'FM0000') || to_char(raw_data.num, 'FM00'),
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.gear'),
      jsonb_build_object(
        'name', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(107, 'FM0000') || to_char(raw_data.num, 'FM00') ||'.'|| 'gear_name')::text),
        'weight', 0
      )
    )
  )
FROM raw_data
CROSS JOIN meta;

-- Переходы: из базового узла опасностей к уточнениям по нужным вариантам
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  VALUES
    ('wcc_witcher_events_benefit_details','wcc_witcher_events_benefit_details_2','wcc_witcher_events_benefit_details_o0107',2);

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_witcher_events_benefit_details_2', 'wcc_witcher_events_risk', r.ru_id, 1
    FROM (SELECT ru_id FROM rules WHERE name = 'lifeEventsCounter_is_valid') r;