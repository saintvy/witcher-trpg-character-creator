\echo '056_witcher_events_danger_events.sql'

-- Узел: Важные события — Опасности
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_danger_events' AS qu_id
                , 'questions' AS entity
                , 'single'::question_type AS qtype
	              , '{"dice":"d0"}'::jsonb AS metadata)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| v.entity_field) AS id
           , meta.entity, v.entity_field, v.lang, v.text
        FROM (VALUES
                ('ru', 'Определите, какие неприятности приключились с вами.', 'body'),
                ('en', 'Determine which dangers befell you.', 'body')
             ) AS v(lang, text, entity_field)
        CROSS JOIN meta
      RETURNING id AS body_id
)
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
  SELECT meta.qu_id
       , meta.su_su_id
       , NULL
       , (SELECT DISTINCT body_id FROM ins_body)
       , meta.qtype
	     , meta.metadata || jsonb_build_object(
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
             ck_id('witcher_cc.hierarchy.witcher_events_danger')::text,
             ck_id('witcher_cc.hierarchy.witcher_events_danger_events')::text
           )
         )
     FROM meta;

-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_danger_events' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
  SELECT v.*
  FROM (VALUES-- RU
          ('ru', 1, '<b>Долг</b><br>Из-за сломанного снаряжения, игр в гвинт и тому подобного вы задолжали от 100 до 1000 крон заведению или благородному дому.'),
          ('ru', 2, '<b>Разумное чудовище сбежало</b><br>Тролль, катакан, волколак или иное разумное чудовище, на которое вы охотились, ушло от вас и бродит на свободе. Возможно, однажды оно вернётся за вами.'),
          ('ru', 3, '<b>Зависимость</b><br>Вы пережили тяжёлые времена и пристрастились к чему-то.'),
          ('ru', 4, '<b>Заключение</b><br>Вы провели от 1 до 10 лет в тюрьме — по ложному обвинению или за совершённое преступление.'),
          ('ru', 5, '<b>Ложное обвинение</b><br>Кому-то нужно было избавиться от вас, либо вы стали удобным козлом отпущения. Возможные обвинения: воровство, предательство, убийство, изнасилование, незаконное колдовство.'),
          ('ru', 6, '<b>Предательство</b><br>Друг или возлюбленный предал вас. Возможные последствия: шантаж, раскрытие вашей тайны или нападение.'),
          ('ru', 7, '<b>Убит друг или любимый</b><br>Кого-то из ваших близких убили. Возможные причины: чудовище, казнь, убийство или отравление.'),
          ('ru', 8, '<b>Вне закона в королевстве</b><br>В какой-то стране вы стали вне закона из-за преступления или ложных обвинений. Теперь вас разыскивает стража.'),
          ('ru', 9, '<b>Манипуляция</b><br>Вас обманом заставили нарушить нейтралитет. Как именно — решайте сами, но те, кто знает вашу репутацию, уверены: вы больше не нейтральны.'),
          ('ru',10, '<b>Проклят</b><br>Вы были прокляты. Природа проклятия и способ его снятия остаются на усмотрение ведущего. Он не обязан раскрывать вам эти детали.'),

          -- EN
          ('en', 1, '<b>Debt</b><br>Through broken gear, gwent matches, or similar misfortunes, you have run up a debt of 100 to 1000 crowns to an establishment or noble house.'),
          ('en', 2, '<b>Sentient Monster Escaped</b><br>A troll, katakan, werewolf, or other sentient monster you were hunting escaped you and is now wandering free. It may come for you someday.'),
          ('en', 3, '<b>Addiction</b><br>You fell on hard times and developed an addiction.'),
          ('en', 4, '<b>Imprisoned</b><br>You spent between 1 and 10 years in prison, either due to a false accusation or an actual crime you committed.'),
          ('en', 5, '<b>Falsely Accused</b><br>Someone wanted you gone, or you were an easy scapegoat. Possible charges: theft, betrayal, murder, rape, or illegal witchcraft.'),
          ('en', 6, '<b>Betrayed</b><br>A friend or lover betrayed you. Possible outcomes: blackmail, exposure of a secret, or a direct attack.'),
          ('en', 7, '<b>Friend or Lover Killed</b><br>Someone close to you was killed. Possible causes: a monster, an execution, a murder, or poisoning.'),
          ('en', 8, '<b>Outlawed in a Kingdom</b><br>In some kingdom you became an outlaw because of a crime or false accusations. There, you are wanted by the Guard.'),
          ('en', 9, '<b>Manipulated</b><br>You were deceived into breaking your neutrality. You decide how it happened, but anyone who knows your reputation knows you are no longer neutral.'),
          ('en',10, '<b>Cursed</b><br>You were afflicted by a curse. The nature of the curse and how it can be lifted are up to your GM, who is not required to reveal them to you.')

 ) AS v(lang, num, text)
)
, ins_label AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM00') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
           , meta.entity, meta.entity_field, vals.lang, vals.text
        FROM vals
        CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
SELECT
  'wcc_witcher_events_danger_events_o' || to_char(vals.num, 'FM00'),
  meta.su_su_id,
  meta.qu_id,
  ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM00') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
  vals.num,
  '{}'::jsonb AS metadata
FROM vals
CROSS JOIN meta
ON CONFLICT (an_id) DO NOTHING;

-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority) 
  SELECT 'wcc_witcher_events_is_in_danger', 'wcc_witcher_events_danger_events', 'wcc_witcher_events_is_in_danger_o0103', 1 UNION ALL
  SELECT 'wcc_witcher_events_is_in_danger', 'wcc_witcher_events_danger_events', 'wcc_witcher_events_is_in_danger_o0203', 1 UNION ALL
  SELECT 'wcc_witcher_events_is_in_danger', 'wcc_witcher_events_danger_events', 'wcc_witcher_events_is_in_danger_o0303', 1 UNION ALL
  SELECT 'wcc_witcher_events_is_in_danger', 'wcc_witcher_events_danger_events', 'wcc_witcher_events_is_in_danger_o0403', 1
  ;

-- i18n для event_type "Неудача" / "Misfortune" (используем тот же, что в ноде 57)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_danger_events_details' AS qu_id
                , 'character' AS entity)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'event_type_misfortune') AS id
       , meta.entity, 'event_type', v.lang, v.text
    FROM (VALUES
      ('ru', 'Неудача'),
      ('en', 'Misfortune')
    ) AS v(lang, text)
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING;

-- i18n для описаний событий вариантов 2 и 9
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_danger_events' AS qu_id
                , 'character' AS entity)
, desc_vals AS (
  SELECT v.*
  FROM (VALUES
    -- Вариант 2: Разумное чудовище сбежало
    ('ru', 2, 'Разумное чудовище сбежало от вас во время охоты и бродит на свободе.'),
    -- Вариант 9: Манипуляция
    ('ru', 9, 'Нейтралитет нарушен обманом в глазах знакомых с вашей репутацией'),
    -- EN translations
    ('en', 2, 'A sentient monster escaped from you during hunting and is now wandering free'),
    ('en', 9, 'Neutrality broken by deception in the eyes of those who know your reputation')
  ) AS v(lang, num, text)
)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(desc_vals.num, 'FM00') ||'.'|| 'event_desc') AS id
       , meta.entity, 'event_desc', desc_vals.lang, desc_vals.text
    FROM desc_vals
    CROSS JOIN meta;

-- Эффекты: добавление в lifeEvents для вариантов 2 и 9
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_danger_events' AS qu_id)
, desc_vals AS (
  SELECT v.*
  FROM (VALUES (2), (9)) AS v(num)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character', 'wcc_witcher_events_danger_events_o' || to_char(desc_vals.num, 'FM00'),
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
        jsonb_build_object('i18n_uuid', ck_id('witcher_cc' ||'.'|| 'wcc_witcher_events_danger_events_details' ||'.'|| 'event_type_misfortune')::text),
        'description',
        jsonb_build_object('i18n_uuid', ck_id('witcher_cc' ||'.'|| meta.qu_id ||'_o'|| to_char(desc_vals.num, 'FM00') ||'.'|| 'event_desc')::text)
      )
    )
  )
FROM desc_vals
CROSS JOIN meta;