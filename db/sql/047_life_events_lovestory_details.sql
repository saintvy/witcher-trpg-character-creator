\echo '047_life_events_lovestory_details.sql'

-- Узел: Выжные события - Союзники и враги
-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_relationshipsstory_details' AS qu_id
                , 'questions' AS entity
                , 'single'::question_type AS qtype
	              , jsonb_build_object(
                    'dice','d0',
                    'counterIncrement', jsonb_build_object(
                      'id','lifeEventsCounter',
                      'step',10
                    )
                  ) AS metadata)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| v.entity_field) AS id
           , meta.entity, v.entity_field, v.lang, v.text
        FROM (VALUES
                ('ru', 'Выберите вариант, соответствующий вашей истории любви.', 'body'),
                ('en', 'Choose the entry that fits your love story.', 'body')
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
            ck_id('witcher_cc.hierarchy.life_events_relationships')::text,
            ck_id('witcher_cc.hierarchy.life_events_relationships_details')::text
          )
        )
     FROM meta;
	   
-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_relationshipsstory_details' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
  SELECT v.*
  FROM (VALUES
          -- ====== RU: Romantic Tragedy ======
          ('ru',2,1,'Некоторое время назад вашего возлюбленного схватили разбойники. Он до сих пор в плену.'),
          ('ru',2,2,'Однажды ваш возлюбленный таинственным образом исчез. Вы не знаете, где он.'),
          ('ru',2,3,'Ваш возлюбленный попал в тюрьму или был изгнан за преступления, которых он, возможно, не совершал.'),
          ('ru',2,4,'Ваш возлюбленный пал жертвой могущественного проклятия.'),
          ('ru',2,5,'Что-то встало между вами, и вы были вынуждены убить своего возлюбленного.'),
          ('ru',2,6,'Ваш возлюбленный совершил самоубийство. Вы можете и не знать, почему.'),
          ('ru',2,7,'Вашего возлюбленного похитил дворянин и сделал своей наложницей.'),
          ('ru',2,8,'Соперник вырвал инициативу и увёл любовь вашего возлюбленного.'),
          ('ru',2,9,'Вашего возлюбленного убили чудовища. Это мог быть несчастный случай или заранее спланированное убийство.'),
          ('ru',2,10,'Ваш возлюбленный — маг, ведьмак или разумное чудовище, что ставит крест на ваших отношениях.'),

          -- ====== RU: Problematic Love ======
          ('ru',3,1,'Семья или друзья вашего возлюбленного ненавидят вас и не одобряют вашу связь.'),
          ('ru',3,2,'Ваш возлюбленный торгует своим телом и не собирается бросать эту работу.'),
          ('ru',3,3,'Ваш возлюбленный страдает от малой порчи — паранойи или жутких кошмаров.'),
          ('ru',3,4,'Ваш возлюбленный спал с кем попало и отказался прекратить это, когда вы узнали.'),
          ('ru',3,5,'Ваш возлюбленный ужасно ревнив и не выносит вашего соседства с любым потенциальным ухажёром.'),
          ('ru',3,6,'Вы постоянно ссоритесь и быстро скатываетесь к крику.'),
          ('ru',3,7,'Вы с возлюбленным — профессиональные соперники и часто уводите друг у друга клиентов.'),
          ('ru',3,8,'Один из вас — человек, а другой — нелюдь, что осложняет жизнь.'),
          ('ru',3,9,'Ваш возлюбленный уже состоит в браке. Он может хотеть уйти от супруга, а может и нет.'),
          ('ru',3,10,'Ваши друзья или семья ненавидят вашего возлюбленного и тоже не одобряют эту связь.'),

          -- ====== EN: Romantic Tragedy ======
          ('en',2,1,'Your Lover was captured by bandits some time ago and is still their captive.'),
          ('en',2,2,'Your Lover mysteriously vanished one day and you don''t know where they went.'),
          ('en',2,3,'Your Lover was imprisoned or exiled for crimes they may not have committed.'),
          ('en',2,4,'Your Lover was taken from you by a powerful curse.'),
          ('en',2,5,'Something got between you and your Lover and you were forced to kill them.'),
          ('en',2,6,'Your Lover committed suicide. You may not know why they did it.'),
          ('en',2,7,'Your Lover was kidnapped by a noble and made into a concubine.'),
          ('en',2,8,'A rival cut you out of the action and stole your Lover''s affection.'),
          ('en',2,9,'Your Lover was killed by monsters. It may have been an accident or planned.'),
          ('en',2,10,'Your Lover is a mage, a witcher, or a sentient monster, dooming the romance.'),

          -- ====== EN: Problematic Love ======
          ('en',3,1,'Your Lover''s family or friends hate you and do not condone your romance.'),
          ('en',3,2,'Your Lover works as a whore for a living and refuses to give up their job.'),
          ('en',3,3,'Your Lover is under a minor curse such as paranoia or horrible nightmares.'),
          ('en',3,4,'Your Lover slept around and refused to stop when you found out.'),
          ('en',3,5,'Your Lover is insanely jealous and can''t stand you being around any possible rival.'),
          ('en',3,6,'You fight constantly and nothing can stop it for long. You always descend into screaming.'),
          ('en',3,7,'You''re professional rivals of some sort. You steal customers from each other often.'),
          ('en',3,8,'One of you is human and the other is non-human, making your life difficult.'),
          ('en',3,9,'Your Lover is already married. They may or may not be willing to leave their spouse.'),
          ('en',3,10,'Your friends or family hate your Lover and do not condone your romance.')
        ) AS v(lang, group_id, num, text)
)
, ins_label AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.group_id, 'FM00') || to_char(vals.num, 'FM00') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
           , meta.entity, meta.entity_field, vals.lang, vals.text
        FROM vals
        CROSS JOIN meta
)
, rules_vals(group_id, id, body) AS (
    SELECT v.group_id
         , gen_random_uuid()
         , ('{
               "and":
                 [
                   { "==":
                       [
                         { "var": "answers.lastAnswer.questionId" },
                         "wcc_life_events_relationshipsstory"
                       ]
                   },
                   { "in":
                       [
                         "wcc_life_events_relationshipsstory_o' || to_char(v.group_id, 'FM00')
                                            || '" ,
                         { "var": "answers.lastAnswer.answerIds" }
                       ]
                   }
                 ]
             }')::jsonb FROM (SELECT DISTINCT group_id FROM vals) v(group_id)
)
, ins_rules AS (
  INSERT INTO rules(ru_id, body) SELECT r.id, r.body FROM rules_vals r
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
  SELECT 'wcc_life_events_relationshipsstory_details_o' || to_char(vals.group_id, 'FM00') || to_char(vals.num, 'FM00') AS an_id,
         meta.su_su_id,
         meta.qu_id,
         ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.group_id, 'FM00') || to_char(vals.num, 'FM00') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
         vals.num AS sort_order,
         r.id,
         '{}'::jsonb AS metadata
    FROM vals
    CROSS JOIN meta
    LEFT JOIN rules_vals r ON r.group_id = vals.group_id
  ON CONFLICT (an_id) DO NOTHING;
  
-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_life_events_relationshipsstory', 'wcc_life_events_relationshipsstory_details', 'wcc_life_events_relationshipsstory_o02', 2;
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_life_events_relationshipsstory', 'wcc_life_events_relationshipsstory_details', 'wcc_life_events_relationshipsstory_o03', 2;

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_life_events_relationshipsstory_details', 'wcc_life_events_event', r.ru_id, 1
    FROM (SELECT ru_id FROM rules WHERE name = 'lifeEventsCounter_is_valid') r;

-- i18n для eventType "Отношения" / "Relationships"
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id('witcher_cc' ||'.'|| 'wcc_life_events_relationships' ||'.'|| 'event_type_relationships') AS id
       , 'character', 'event_type', v.lang, v.text
    FROM (VALUES
      ('ru', 'Отношения'),
      ('en', 'Relationships')
    ) AS v(lang, text)
  ON CONFLICT (id, lang) DO NOTHING;

-- i18n для кратких описаний событий (каждый ответ в формате "{тип}: {краткое описание}")
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_relationshipsstory_details' AS qu_id
                , 'character' AS entity)
, desc_vals AS (
  SELECT v.*
  FROM (VALUES
    -- RU: Romantic Tragedy (group_id=2)
    ('ru', 2, 1, 'Романтическая трагедия: Возлюбленный в плену разбойников'),
    ('ru', 2, 2, 'Романтическая трагедия: Возлюбленный таинственно исчез'),
    ('ru', 2, 3, 'Романтическая трагедия: Возлюбленный в тюрьме или изгнан'),
    ('ru', 2, 4, 'Романтическая трагедия: Возлюбленный под проклятием'),
    ('ru', 2, 5, 'Романтическая трагедия: Вы убили возлюбленного'),
    ('ru', 2, 6, 'Романтическая трагедия: Возлюбленный совершил самоубийство'),
    ('ru', 2, 7, 'Романтическая трагедия: Возлюбленного похитил дворянин'),
    ('ru', 2, 8, 'Романтическая трагедия: Соперник увёл возлюбленного'),
    ('ru', 2, 9, 'Романтическая трагедия: Возлюбленного убили чудовища'),
    ('ru', 2, 10, 'Романтическая трагедия: Возлюбленный — маг или ведьмак'),
    
    -- RU: Problematic Love (group_id=3)
    ('ru', 3, 1, 'Трудная любовь: Семья не одобряет связь'),
    ('ru', 3, 2, 'Трудная любовь: Возлюбленный торгует телом'),
    ('ru', 3, 3, 'Трудная любовь: Возлюбленный под малой порчей'),
    ('ru', 3, 4, 'Трудная любовь: Возлюбленный изменял и не прекратил'),
    ('ru', 3, 5, 'Трудная любовь: Возлюбленный ужасно ревнив'),
    ('ru', 3, 6, 'Трудная любовь: Постоянные ссоры и крики'),
    ('ru', 3, 7, 'Трудная любовь: Профессиональные соперники'),
    ('ru', 3, 8, 'Трудная любовь: Разные расы осложняют жизнь'),
    ('ru', 3, 9, 'Трудная любовь: Возлюбленный уже в браке'),
    ('ru', 3, 10, 'Трудная любовь: Друзья не одобряют связь'),
    
    -- EN: Romantic Tragedy (group_id=2)
    ('en', 2, 1, 'Romantic Tragedy: Lover captured by bandits'),
    ('en', 2, 2, 'Romantic Tragedy: Lover mysteriously vanished'),
    ('en', 2, 3, 'Romantic Tragedy: Lover imprisoned or exiled'),
    ('en', 2, 4, 'Romantic Tragedy: Lover under powerful curse'),
    ('en', 2, 5, 'Romantic Tragedy: You killed your lover'),
    ('en', 2, 6, 'Romantic Tragedy: Lover committed suicide'),
    ('en', 2, 7, 'Romantic Tragedy: Lover kidnapped by noble'),
    ('en', 2, 8, 'Romantic Tragedy: Rival stole lover away'),
    ('en', 2, 9, 'Romantic Tragedy: Lover killed by monsters'),
    ('en', 2, 10, 'Romantic Tragedy: Lover is mage or witcher'),
    
    -- EN: Problematic Love (group_id=3)
    ('en', 3, 1, 'Problematic Love: Family disapproves romance'),
    ('en', 3, 2, 'Problematic Love: Lover works as whore'),
    ('en', 3, 3, 'Problematic Love: Lover under minor curse'),
    ('en', 3, 4, 'Problematic Love: Lover cheated and refused to stop'),
    ('en', 3, 5, 'Problematic Love: Lover insanely jealous'),
    ('en', 3, 6, 'Problematic Love: Constant fighting and screaming'),
    ('en', 3, 7, 'Problematic Love: Professional rivals'),
    ('en', 3, 8, 'Problematic Love: Different races complicate life'),
    ('en', 3, 9, 'Problematic Love: Lover already married'),
    ('en', 3, 10, 'Problematic Love: Friends disapprove romance')
  ) AS v(lang, group_id, num, text)
)
, ins_desc AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(desc_vals.group_id, 'FM00') || to_char(desc_vals.num, 'FM00') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', desc_vals.lang, desc_vals.text
      FROM desc_vals
      CROSS JOIN meta
)
-- Эффект: добавление события в lifeEvents (привязан к вопросу)
-- Использует последний ответ из ноды 45 для получения описания
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
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| 'wcc_life_events_relationships' ||'.'|| 'event_type_relationships')::text),
        'description',
        jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array(
          'witcher_cc.',
          jsonb_build_object('reduce', jsonb_build_array(
            jsonb_build_object('var', 'answers.byQuestion.wcc_life_events_relationshipsstory_details'),
            jsonb_build_object('var', 'current'),
            NULL
          )),
          '.event_desc'
        ))))
      )
    )
  )
FROM meta;