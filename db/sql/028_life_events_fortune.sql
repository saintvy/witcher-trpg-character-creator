\echo '028_life_events_fortune.sql'

-- Узел: Выжные события - Кто потерпевший
-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_fortune' AS qu_id
                , 'questions' AS entity
                , 'single'::question_type AS qtype
	              , jsonb_build_object('dice','d0') AS metadata)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| v.entity_field) AS id
           , meta.entity, v.entity_field, v.lang, v.text
        FROM (VALUES
                ('ru', 'Определите, как именно удача с вами приключилась.', 'body'),
                ('en', 'Determine how fortune came your way.', 'body')
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
            ck_id('witcher_cc.hierarchy.life_events_fortune')::text,
            ck_id('witcher_cc.hierarchy.life_events_fortune_kind')::text
          )
        )
     FROM meta;
	   
-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_fortune' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
  SELECT v.*, c.*
  FROM (VALUES ('ru', 1, '<b>Джекпот:</b><br>Благодаря какому-то событию или по счастливой случайности вы получаете IdlO х 100 крон.'),
               ('ru', 2, '<b>Учитель:</b><br>Вы обучались под опекой учителя. Получите +1 к любому навыку Инт или же выберите новый навык Инт с бонусом +2.'),
               ('ru', 3, '<b>Благодарность дворянина</b><br>Вы что-то сделали для дворянина, и теперь он вам должен 1 услугу.'),
               ('ru', 4, '<b>Боевой инструктор:</b><br>Вы учились боевым искусствам у настоящего воина. Получите +1 к любому боевому навыку или же выберите новый боевой навык с бонусом +2.'),
               ('ru', 5, '<b>Благодарность ведьмака:</b><br>Как-то раз вы повстречали ведьмака и оказали ему услугу. Теперь он вам должен услугу в ответ.'),
               ('ru', 6, '<b>Дружба с разбойниками:</b><br>Вы подружились с разбойничьей шайкой. Раз в месяц вы можете попросить их об 1 услуге.'),
               ('ru', 7, '<b>Приручённый зверь:</b><br>Вы сумели приручить дикое животное. Совершите бросок IdlO: от 1 до 7 — дикая собака (см. параметры собаки на стр. 310), от 8 до 10 — волк (см. стр. 286).'),
               ('ru', 8, '<b>Благодарность мага:</b><br>Могущественный маг, которому вы помогли, должен вам 1 услугу.'),
               ('ru', 9, '<b>Благословление жреца:</b><br>У вас есть священный символ. Вы можете показать его персонажам, исповедующим ту же веру, и получить бонус +2 к Харизме при общении с ними.'),
               ('ru', 10, '<b>Рыцарство:</b><br>В случайно выбранном королевстве вас за храбрость посвятили в рыцари. В этом королевстве вы получаете +2 к репутации и считаетесь рыцарем.'),
               ('en', 1, '<b>Jackpot:</b><br>Some major event or stroke of luck brought you 1d10x100 crowns.'),
               ('en', 2, '<b>Find a Teacher:</b><br>You trained with a teacher. Gain +1 in any INT skill or start a new INT skill at +2.'),
               ('en', 3, '<b>A Noble Owes You:</b><br>Something you did gained you 1 favor from a nobleman/noblewoman.'),
               ('en', 4, '<b>Find a Combat Teacher:</b><br>You trained with a soldier. Gain +1 in any combat skill or start a new combat skill at +2.'),
               ('en', 5, '<b>A Witcher Owes You:</b><br>You encountered a witcher at some point and managed to garner a favor from them.'),
               ('en', 6, '<b>Fell in with Bandits:</b><br>You fell in with a bandit gang. Once per month you can ask these bandits for 1 favor.'),
               ('en', 7, '<b>Tamed a Wild Animal:</b><br>You tamed a wild animal you encountered in the wilderness. Roll 1d10. 1-7: Wild Dog (See Dog on Pg.310), 8-10: Wolf (See Wolf on Pg.286).'),
               ('en', 8, '<b>A Mage Owes You:</b><br>You managed to garner 1 favor from a powerful mage you helped.'),
               ('en', 9, '<b>Blessed by a Priest:</b><br>You were given a holy symbol that you can show to people of that faith to gain a +2 to Charisma with them.'),
               ('en', 10, '<b>Knighted:</b><br>You were knighted for valor in a random kingdom. In this kingdom you gain +2 reputation and are recognized as a knight.')
         ) AS v(lang, num, text)
  LEFT JOIN (VALUES ('"counterIncrement":
                       {
                         "id": "lifeEventsCounter",
                         "step": 10
                       }')) as c(counter_txt) ON v.num in (3,5,6,8,9)
)
, ins_label AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
           , meta.entity, meta.entity_field, vals.lang, vals.text
        FROM vals
        CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
  SELECT 'wcc_life_events_fortune_o' || to_char(vals.num, 'FM9900') AS an_id,
         meta.su_su_id,
         meta.qu_id,
         ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
         vals.num AS sort_order,
         ('{' || coalesce(vals.counter_txt,'') || '}')::jsonb AS metadata
    FROM vals
    CROSS JOIN meta
  ON CONFLICT (an_id) DO NOTHING;
  
-- Эффекты
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_fortune' AS qu_id
                , 'character' AS entity)
-- i18n для eventType "Fortune"/"Удача"
, ins_event_type AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'event_type_fortune') AS id
         , meta.entity, 'event_type', v.lang, v.text
      FROM (VALUES
        ('ru', 'Удача'),
        ('en', 'Fortune')
      ) AS v(lang, text)
      CROSS JOIN meta
)
-- i18n для description (варианты 3, 5, 6, 8, 9)
, ins_desc_03 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| '03' ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', v.lang, v.text
      FROM (VALUES
        ('ru', 'Благодарность дворянина: вы помогли дворянину, и он пообещал вам услугу.'),
        ('en', 'A Noble Owes You: you helped a noble, who promised you a favor.')
      ) AS v(lang, text)
      CROSS JOIN meta
)
, ins_desc_05 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| '05' ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', v.lang, v.text
      FROM (VALUES
        ('ru', 'Благодарность ведьмака: вы повстречали ведьмака и оказали ему услугу.'),
        ('en', 'A Witcher Owes You: you encountered a witcher and helped them.')
      ) AS v(lang, text)
      CROSS JOIN meta
)
, ins_desc_06 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| '06' ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', v.lang, v.text
      FROM (VALUES
        ('ru', 'Дружба с разбойниками: вы подружились с разбойничьей шайкой.'),
        ('en', 'Fell in with Bandits: you befriended a bandit gang.')
      ) AS v(lang, text)
      CROSS JOIN meta
)
, ins_desc_08 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| '08' ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', v.lang, v.text
      FROM (VALUES
        ('ru', 'Благодарность мага: вы помогли могущественному магу.'),
        ('en', 'A Mage Owes You: you helped a powerful mage.')
      ) AS v(lang, text)
      CROSS JOIN meta
)
, ins_desc_09 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| '09' ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', v.lang, v.text
      FROM (VALUES
        ('ru', 'Благословление жреца: от жреца вы получили священный для его религии символ.'),
        ('en', 'Blessed by a Priest: a priest gave you a holy symbol of their faith.')
      ) AS v(lang, text)
      CROSS JOIN meta
)
-- i18n для gear items
, ins_gear_03 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| '03' ||'.'|| 'gear_name') AS id
         , 'gear', 'name', v.lang, v.text
      FROM (VALUES
        ('ru', 'Услуга дворянина'),
        ('en', 'Nobleman Service')
      ) AS v(lang, text)
      CROSS JOIN meta
)
, ins_gear_05 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| '05' ||'.'|| 'gear_name') AS id
         , 'gear', 'name', v.lang, v.text
      FROM (VALUES
        ('ru', 'Услуга ведьмака'),
        ('en', 'Witcher Service')
      ) AS v(lang, text)
      CROSS JOIN meta
)
, ins_gear_06 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| '06' ||'.'|| 'gear_name') AS id
         , 'gear', 'name', v.lang, v.text
      FROM (VALUES
        ('ru', 'Ежемесячная услуга разбойников'),
        ('en', 'Monthly Bandit Service')
      ) AS v(lang, text)
      CROSS JOIN meta
)
, ins_gear_08 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| '08' ||'.'|| 'gear_name') AS id
         , 'gear', 'name', v.lang, v.text
      FROM (VALUES
        ('ru', 'Услуга мага'),
        ('en', 'Mage Service')
      ) AS v(lang, text)
      CROSS JOIN meta
)
, ins_gear_09_name AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| '09' ||'.'|| 'gear_name') AS id
         , 'gear', 'name', v.lang, v.text
      FROM (VALUES
        ('ru', 'Священный символ'),
        ('en', 'Sacred Symbol')
      ) AS v(lang, text)
      CROSS JOIN meta
)
, ins_gear_09_notes AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| '09' ||'.'|| 'gear_notes') AS id
         , 'gear', 'notes', v.lang, v.text
      FROM (VALUES
        ('ru', 'Получаем +2 к навыку харизмы при общении с единоверцами.'),
        ('en', 'Gain +2 to Charisma skill when communicating with co-religionists.')
      ) AS v(lang, text)
      CROSS JOIN meta
)
, event_items AS (
  SELECT num FROM (VALUES (3), (5), (6), (8), (9)) AS v(num)
)
INSERT INTO effects (scope, an_an_id, body)
-- 1. Добавление в lifeEvents (варианты 3, 5, 6, 8, 9)
SELECT 'character', 'wcc_life_events_fortune_o' || to_char(event_items.num, 'FM9900'),
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
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'event_type_fortune')::text),
        'description',
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(event_items.num, 'FM9900') ||'.'|| 'event_desc')::text)
      )
    )
  )
FROM event_items
CROSS JOIN meta
UNION ALL
-- 2. Добавление в gear (варианты 3, 5, 6, 8, 9)
SELECT 'character', 'wcc_life_events_fortune_o' || to_char(event_items.num, 'FM9900'),
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.gear'),
      (
        jsonb_build_object(
          'name', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(event_items.num, 'FM9900') ||'.'|| 'gear_name')::text),
          'weight', 0
        ) ||
        CASE WHEN event_items.num = 9 THEN
          jsonb_build_object('notes', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| '09' ||'.'|| 'gear_notes')::text))
        ELSE
          '{}'::jsonb
        END
      )
    )
  )
FROM event_items
CROSS JOIN meta;

-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id)
  SELECT 'wcc_life_events_fortune_or_not', 'wcc_life_events_fortune', 'wcc_life_events_fortune_or_not_o01';

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_life_events_fortune', 'wcc_life_events_event', r.ru_id, 1
  FROM (SELECT ru_id FROM rules WHERE name = 'lifeEventsCounter_is_valid') r;