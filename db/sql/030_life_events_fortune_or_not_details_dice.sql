\echo '030_life_events_fortune_or_not_details_dice.sql'
-- Узел: Братья и сёстры - количество

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_fortune_or_not_details_dice' AS qu_id
                , 'questions' AS entity)
, ins_body AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
                       , meta.entity, 'body', v.lang, v.text
                    FROM (VALUES
                            ('ru', 'Определите дополнительные детали произошедшего события.'),
                            ('en', 'Determine the additional details of what happened.')) AS v(lang, text)
                    CROSS JOIN meta)
, c_vals(lang, num, text) AS (VALUES ('ru', 1, 'Шанс'),
                                     ('ru', 2, 'Уточнение'),
                                     ('en', 1, 'Chance'),
                                     ('en', 2, 'Clarification'))
, ins_c AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| 'column_name') AS id
                       , meta.entity, 'column_name', c_vals.lang, c_vals.text
				    FROM c_vals
					CROSS JOIN meta)
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
  SELECT meta.qu_id
       , meta.su_su_id
       , NULL
       , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body')
       , 'single_table'
       , jsonb_build_object(
           'dice','d_weighed',
           'columns', (
             SELECT jsonb_agg(
                      ck_id('witcher_cc' ||'.'|| 'wcc_life_events_fortune_or_not_details_dice' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text
                      ORDER BY num
                    )
               FROM (SELECT DISTINCT num FROM c_vals) AS cols
           ),
           'counterIncrement', jsonb_build_object(
             'id','lifeEventsCounter',
             'step',10
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
             ck_id('witcher_cc.hierarchy.life_events_misfortune')::text,
             ck_id('witcher_cc.hierarchy.life_events_misfortune_details_2')::text
           )
         )
    FROM meta;


-- Ответы (каждый вариант 10%)
WITH
raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
            (1802, 1, 0.1, 'Вы лечились 1 месяц'),
            (1802, 2, 0.1, 'Вы лечились 2 месяца'),
            (1802, 3, 0.1, 'Вы лечились 3 месяца'),
            (1802, 4, 0.1, 'Вы лечились 4 месяца'),
            (1802, 5, 0.1, 'Вы лечились 5 месяцев'),
            (1802, 6, 0.1, 'Вы лечились 6 месяцев'),
            (1802, 7, 0.1, 'Вы лечились 7 месяцев'),
            (1802, 8, 0.1, 'Вы лечились 8 месяцев'),
            (1802, 9, 0.1, 'Вы лечились 9 месяцев'),
            (1802, 10, 0.1, 'Вы лечились 10 месяцев'),

            (1803, 1, 0.1, 'Вы потеряли память об 1 месяце того года'),
            (1803, 2, 0.1, 'Вы потеряли память об 2 месяцах того года'),
            (1803, 3, 0.1, 'Вы потеряли память об 3 месяцах того года'),
            (1803, 4, 0.1, 'Вы потеряли память об 4 месяцах того года'),
            (1803, 5, 0.1, 'Вы потеряли память об 5 месяцах того года'),
            (1803, 6, 0.1, 'Вы потеряли память об 6 месяцах того года'),
            (1803, 7, 0.1, 'Вы потеряли память об 7 месяцах того года'),
            (1803, 8, 0.1, 'Вы потеряли память об 8 месяцах того года'),
            (1803, 9, 0.1, 'Вы потеряли память об 9 месяцах того года'),
            (1803, 10, 0.1, 'Вы потеряли память об 10 месяцах того года')
          ) AS raw_data_ru(group_id, num, probability, option_txt)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
  FROM (VALUES
          (1802, 1, 0.1, 'You were recovering for 1 month'),
          (1802, 2, 0.1, 'You were recovering for 2 months'),
          (1802, 3, 0.1, 'You were recovering for 3 months'),
          (1802, 4, 0.1, 'You were recovering for 4 months'),
          (1802, 5, 0.1, 'You were recovering for 5 months'),
          (1802, 6, 0.1, 'You were recovering for 6 months'),
          (1802, 7, 0.1, 'You were recovering for 7 months'),
          (1802, 8, 0.1, 'You were recovering for 8 months'),
          (1802, 9, 0.1, 'You were recovering for 9 months'),
          (1802, 10, 0.1, 'You were recovering for 10 months'),

          (1803, 1, 0.1, 'You lost 1 month of memory from that year'),
          (1803, 2, 0.1, 'You lost 2 months of memory from that year'),
          (1803, 3, 0.1, 'You lost 3 months of memory from that year'),
          (1803, 4, 0.1, 'You lost 4 months of memory from that year'),
          (1803, 5, 0.1, 'You lost 5 months of memory from that year'),
          (1803, 6, 0.1, 'You lost 6 months of memory from that year'),
          (1803, 7, 0.1, 'You lost 7 months of memory from that year'),
          (1803, 8, 0.1, 'You lost 8 months of memory from that year'),
          (1803, 9, 0.1, 'You lost 9 months of memory from that year'),
          (1803, 10, 0.1, 'You lost 10 months of memory from that year')
       ) AS raw_data_en(group_id, num, probability, option_txt)

),
vals AS (
         SELECT ('<td>' || to_char(probability*100, 'FM990.00') || '%</td>' ||
                 '<td>' || option_txt || '</td>') AS text,
                num,
                probability,
                lang,
                group_id
         FROM raw_data
)
, meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_fortune_or_not_details_dice' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, ins_label AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.group_id, 'FM0000') || to_char(vals.num, 'FM00') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
                     , meta.entity, meta.entity_field, vals.lang, vals.text
                  FROM vals
                  CROSS JOIN meta
)
, rules_vals(group_id, id, body) AS (
    SELECT v.num
         , gen_random_uuid()
         , ('{
               "and":
                 [
                   { "==":
                       [
                         { "var": "answers.lastAnswer.questionId" },
                         "wcc_life_events_fortune_or_not_details"
                       ]
                   },
                   { "in":
                       [
                         "wcc_life_events_fortune_or_not_details_o' || to_char(num, 'FM9900')
                                                                    || '" ,
                         { "var": "answers.lastAnswer.answerIds" }
                       ]
                   }
                 ]
             }')::jsonb FROM (SELECT DISTINCT group_id FROM raw_data) v(num)
)
, ins_rules AS (
  INSERT INTO rules(ru_id, body) SELECT r.id, r.body FROM rules_vals r
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT 'wcc_life_events_fortune_or_not_details_dice_o' || to_char(vals.group_id, 'FM9900') || to_char(vals.num, 'FM00') AS an_id,
       meta.su_su_id,
       meta.qu_id,
       ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.group_id, 'FM0000') || to_char(vals.num, 'FM00') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
       vals.num AS sort_order,
       rules_vals.id AS visible_ru_ru_id,
       jsonb_build_object(
           'probability', vals.probability
       ) AS metadata
FROM vals
CROSS JOIN meta
LEFT JOIN rules_vals ON rules_vals.group_id = vals.group_id
ON CONFLICT (an_id) DO NOTHING;

-- Эффекты
WITH
  raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
            (1802, 1, 0.1, 'Вы лечились 1 месяц'),
            (1802, 2, 0.1, 'Вы лечились 2 месяца'),
            (1802, 3, 0.1, 'Вы лечились 3 месяца'),
            (1802, 4, 0.1, 'Вы лечились 4 месяца'),
            (1802, 5, 0.1, 'Вы лечились 5 месяцев'),
            (1802, 6, 0.1, 'Вы лечились 6 месяцев'),
            (1802, 7, 0.1, 'Вы лечились 7 месяцев'),
            (1802, 8, 0.1, 'Вы лечились 8 месяцев'),
            (1802, 9, 0.1, 'Вы лечились 9 месяцев'),
            (1802, 10, 0.1, 'Вы лечились 10 месяцев'),

            (1803, 1, 0.1, 'Вы потеряли память об 1 месяце того года'),
            (1803, 2, 0.1, 'Вы потеряли память об 2 месяцах того года'),
            (1803, 3, 0.1, 'Вы потеряли память об 3 месяцах того года'),
            (1803, 4, 0.1, 'Вы потеряли память об 4 месяцах того года'),
            (1803, 5, 0.1, 'Вы потеряли память об 5 месяцах того года'),
            (1803, 6, 0.1, 'Вы потеряли память об 6 месяцах того года'),
            (1803, 7, 0.1, 'Вы потеряли память об 7 месяцах того года'),
            (1803, 8, 0.1, 'Вы потеряли память об 8 месяцах того года'),
            (1803, 9, 0.1, 'Вы потеряли память об 9 месяцах того года'),
            (1803, 10, 0.1, 'Вы потеряли память об 10 месяцах того года')
          ) AS raw_data_ru(group_id, num, probability, option_txt)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
  FROM (VALUES
          (1802, 1, 0.1, 'You were recovering for 1 month'),
          (1802, 2, 0.1, 'You were recovering for 2 months'),
          (1802, 3, 0.1, 'You were recovering for 3 months'),
          (1802, 4, 0.1, 'You were recovering for 4 months'),
          (1802, 5, 0.1, 'You were recovering for 5 months'),
          (1802, 6, 0.1, 'You were recovering for 6 months'),
          (1802, 7, 0.1, 'You were recovering for 7 months'),
          (1802, 8, 0.1, 'You were recovering for 8 months'),
          (1802, 9, 0.1, 'You were recovering for 9 months'),
          (1802, 10, 0.1, 'You were recovering for 10 months'),

          (1803, 1, 0.1, 'You lost 1 month of memory from that year'),
          (1803, 2, 0.1, 'You lost 2 months of memory from that year'),
          (1803, 3, 0.1, 'You lost 3 months of memory from that year'),
          (1803, 4, 0.1, 'You lost 4 months of memory from that year'),
          (1803, 5, 0.1, 'You lost 5 months of memory from that year'),
          (1803, 6, 0.1, 'You lost 6 months of memory from that year'),
          (1803, 7, 0.1, 'You lost 7 months of memory from that year'),
          (1803, 8, 0.1, 'You lost 8 months of memory from that year'),
          (1803, 9, 0.1, 'You lost 9 months of memory from that year'),
          (1803, 10, 0.1, 'You lost 10 months of memory from that year')
       ) AS raw_data_en(group_id, num, probability, option_txt)
)
, meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_fortune_or_not_details_dice' AS qu_id
                , 'character' AS entity)
-- i18n для описаний событий (группы 1802 и 1803)
, ins_desc_1802 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(1802, 'FM0000') || to_char(vals.num, 'FM00') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Несчастный случай: Лечились 1 месяц.'),
        ('ru', 2, 'Несчастный случай: Лечились 2 месяца.'),
        ('ru', 3, 'Несчастный случай: Лечились 3 месяца.'),
        ('ru', 4, 'Несчастный случай: Лечились 4 месяца.'),
        ('ru', 5, 'Несчастный случай: Лечились 5 месяцев.'),
        ('ru', 6, 'Несчастный случай: Лечились 6 месяцев.'),
        ('ru', 7, 'Несчастный случай: Лечились 7 месяцев.'),
        ('ru', 8, 'Несчастный случай: Лечились 8 месяцев.'),
        ('ru', 9, 'Несчастный случай: Лечились 9 месяцев.'),
        ('ru', 10, 'Несчастный случай: Лечились 10 месяцев.'),
        ('en', 1, 'Accident: Recovering for 1 month.'),
        ('en', 2, 'Accident: Recovering for 2 months.'),
        ('en', 3, 'Accident: Recovering for 3 months.'),
        ('en', 4, 'Accident: Recovering for 4 months.'),
        ('en', 5, 'Accident: Recovering for 5 months.'),
        ('en', 6, 'Accident: Recovering for 6 months.'),
        ('en', 7, 'Accident: Recovering for 7 months.'),
        ('en', 8, 'Accident: Recovering for 8 months.'),
        ('en', 9, 'Accident: Recovering for 9 months.'),
        ('en', 10, 'Accident: Recovering for 10 months.')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
, ins_desc_1803 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(1803, 'FM0000') || to_char(vals.num, 'FM00') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Несчастный случай: Потеря памяти об 1 месяце того года.'),
        ('ru', 2, 'Несчастный случай: Потеря памяти о 2 месяцах того года.'),
        ('ru', 3, 'Несчастный случай: Потеря памяти о 3 месяцах того года.'),
        ('ru', 4, 'Несчастный случай: Потеря памяти о 4 месяцах того года.'),
        ('ru', 5, 'Несчастный случай: Потеря памяти о 5 месяцах того года.'),
        ('ru', 6, 'Несчастный случай: Потеря памяти о 6 месяцах того года.'),
        ('ru', 7, 'Несчастный случай: Потеря памяти о 7 месяцах того года.'),
        ('ru', 8, 'Несчастный случай: Потеря памяти о 8 месяцах того года.'),
        ('ru', 9, 'Несчастный случай: Потеря памяти о 9 месяцах того года.'),
        ('ru', 10, 'Несчастный случай: Потеря памяти о 10 месяцах того года.'),
        ('en', 1, 'Accident: Lost 1 month of memory from that year.'),
        ('en', 2, 'Accident: Lost 2 months of memory from that year.'),
        ('en', 3, 'Accident: Lost 3 months of memory from that year.'),
        ('en', 4, 'Accident: Lost 4 months of memory from that year.'),
        ('en', 5, 'Accident: Lost 5 months of memory from that year.'),
        ('en', 6, 'Accident: Lost 6 months of memory from that year.'),
        ('en', 7, 'Accident: Lost 7 months of memory from that year.'),
        ('en', 8, 'Accident: Lost 8 months of memory from that year.'),
        ('en', 9, 'Accident: Lost 9 months of memory from that year.'),
        ('en', 10, 'Accident: Lost 10 months of memory from that year.')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- i18n для event_type_misfortune (используем тот же, что в ноде 27)
, ins_event_type_misfortune AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| 'wcc_life_events_fortune_or_not_details' ||'.'|| 'event_type_misfortune') AS id
         , meta.entity, 'event_type', v.lang, v.text
      FROM (VALUES
        ('ru', 'Неудача'),
        ('en', 'Misfortune')
      ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
)
-- Эффекты: добавление в lifeEvents для групп 1802 и 1803
INSERT INTO effects (scope, an_an_id, body)
SELECT DISTINCT
  'character', 'wcc_life_events_fortune_or_not_details_dice_o' || to_char(raw_data.group_id, 'FM0000') || to_char(raw_data.num, 'FM00'),
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
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| 'wcc_life_events_fortune_or_not_details' ||'.'|| 'event_type_misfortune')::text),
        'description',
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.group_id, 'FM0000') || to_char(raw_data.num, 'FM00') ||'.'|| 'event_desc')::text)
      )
    )
  )
FROM raw_data
CROSS JOIN meta;

-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_life_events_fortune_or_not_details', 'wcc_life_events_fortune_or_not_details_dice', 'wcc_life_events_fortune_or_not_details_o1802', 2;
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_life_events_fortune_or_not_details', 'wcc_life_events_fortune_or_not_details_dice', 'wcc_life_events_fortune_or_not_details_o1803', 2;

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_life_events_fortune_or_not_details_dice', 'wcc_life_events_event', r.ru_id, 1
    FROM (SELECT ru_id FROM rules WHERE name = 'lifeEventsCounter_is_valid') r;