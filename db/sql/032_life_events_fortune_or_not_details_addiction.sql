\echo '032_life_events_fortune_or_not_details_addiction.sql'
-- Узел: Братья и сёстры - Основная черта характера

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_fortune_or_not_details_addiction' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru', 'Придумайте свой вариант зависимости для персонажа.'),
        ('en', 'Create your own addiction for your characterRaw.')
      ) AS v(lang, text)
      CROSS JOIN meta
  )
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
SELECT meta.qu_id
     , meta.su_su_id
     , NULL
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body')
       , 'value_string'
       , (
         jsonb_build_object(
          'defaultValue', '',
          'placeholder' , '',
          'valueTarget' , '_temp.addiction_description',
          'counterIncrement', jsonb_build_object('jsonlogic_expression', jsonb_build_object('if', jsonb_build_array(
            jsonb_build_object('!=', jsonb_build_array(
              jsonb_build_object('var', 'characterRaw.logicFields.race'),
              'Witcher'
            )),
            jsonb_build_object(
              'id', 'lifeEventsCounter',
              'step', 10
            ),
            null
          )))
         ) ||
         jsonb_build_object(
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
             -- Условный элемент 3: для ведьмака или обычных рас
             jsonb_build_object('jsonlogic_expression', jsonb_build_object('if', jsonb_build_array(
               jsonb_build_object('==', jsonb_build_array(
                 jsonb_build_object('var', 'characterRaw.logicFields.race'),
                 'Witcher'
               )),
               ck_id('witcher_cc.hierarchy.witcher_events_danger')::text,
               ck_id('witcher_cc.hierarchy.life_events_misfortune')::text
             ))),
             -- Условный элемент 4: для ведьмака или обычных рас
             jsonb_build_object('jsonlogic_expression', jsonb_build_object('if', jsonb_build_array(
               jsonb_build_object('==', jsonb_build_array(
                 jsonb_build_object('var', 'characterRaw.logicFields.race'),
                 'Witcher'
               )),
               ck_id('witcher_cc.hierarchy.witcher_events_danger_events_details_addiction')::text,
               ck_id('witcher_cc.hierarchy.life_events_misfortune_custom_addiction')::text
             )))
           )
         )
       ) AS metadata
  FROM meta;

-- i18n для event_type_misfortune (используем тот же, что в ноде 026)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_fortune_or_not_details_addiction' AS qu_id
                , 'character' AS entity)
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
-- i18n для описания "Кастомная зависимость"
, ins_event_desc AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', v.lang, v.text
      FROM (VALUES
        ('ru', 'Кастомная зависимость'),
        ('en', 'Custom Addiction')
      ) AS v(lang, text)
      CROSS JOIN meta
)
-- Эффекты: добавление кастомной зависимости в массив diseases_and_curses и в lifeEvents
-- Эффекты привязаны к вопросу (qu_qu_id), применяются при выходе из вопроса
INSERT INTO effects (scope, qu_qu_id, an_an_id, body)
-- 1. Добавление в diseases_and_curses
SELECT 'character', meta.qu_id, NULL,
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.lore.diseases_and_curses'),
      jsonb_build_object(
        'type', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_life_events_fortune_or_not_details.disease_type_addiction')::text),
        'description', jsonb_build_object('var', '_temp.addiction_description')
      )
    )
  )
FROM meta
UNION ALL
-- 2. Добавление в lifeEvents
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
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| 'wcc_life_events_fortune_or_not_details' ||'.'|| 'event_type_misfortune')::text),
        'description',
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'event_desc')::text)
      )
    )
  )
FROM meta;
  
-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_life_events_fortune_or_not_details', 'wcc_life_events_fortune_or_not_details_addiction', 'wcc_life_events_fortune_or_not_details_o1310', 2;
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_life_events_fortune_or_not_details_addiction', 'wcc_life_events_event', r.ru_id, 1
    FROM (SELECT ru_id FROM rules WHERE name = 'lifeEventsCounter_is_valid') r;