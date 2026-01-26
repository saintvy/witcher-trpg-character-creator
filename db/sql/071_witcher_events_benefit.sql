\echo '071_witcher_events_benefit.sql'

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_benefit' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru','Выберите полученную выгоду.'),
        ('en','Choose a benefit you''ve got.')
      ) AS v(lang,text)
      CROSS JOIN meta
  )
, c_vals(lang,num,text) AS (
    VALUES
      ('ru',1,'Выгода'),
      ('ru',2,'Эффект'),
      ('ru',3,'Описание'),
      ('en',1,'Benefit'),
      ('en',2,'Effect'),
      ('en',3,'Description')
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
         'dice', 'd0',
         'columns', (
           SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_witcher_events_benefit' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
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
           ck_id('witcher_cc.hierarchy.witcher_events_benefit')::text,
           ck_id('witcher_cc.hierarchy.witcher_events_benefit_type')::text
         )
       )
  FROM meta;

-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_benefit' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
      (1,'Право Неожиданности', '<b>Случайная находка:</b><br> - ребёнок<br> - собака<br> - лошадь<br> - новый плуг<br> - кошка<br> - бочка эля<br> - драгоценность стоимостью 10-60 крон<br> - оружие стоимостью до 500 крон<br> - бык<br> - мул', 'В это десятилетие вы воспользовались Правом Неожиданности.'),
      (2,'Роман', '<b>Любовный интерес</b> со случайным финалом:<br> - всё длилось пару недель<br> - всё длилось пару месяцев<br> - роман до сих пор продолжается с переменным успехом', 'У вас появился любовный интерес - тот, кому плевать на ваши мутации и отсутствие эмоций. Каким-то образом с этой личностью у вас появилась серьёзная связь.'),
      (3,'Неожиданная удача', 'От 100 до 1000 <b>крон</b>', 'За это десятилетие вам удалось заработать неожиданно крупную сумму. Вы смогли не только оплатить алхимические ингредиенты и починку снаряжения, но и отложили немного денег на будущее.'),
      (4,'Долг дворянина', '<b>Услуга</b> дворянина', 'Вы выполнили работу для дворянина. Неважно, легально или нет, - так или иначе, он вам сильно задолжал и знает, что когда-нибудь вы придёте за оплатой. Вы можете в любой момент обратиться за ответной услугой, но всё должно быть в пределах разумного (на усмотрение ведущего).'),
      (5,'Ведьмачьи тайны', '<b>Алхимическая формула на выбор:</b><br> - формула масла<br> - формула эликсира<br> - формула отвара', 'В ходе приключений вы встретили другого ведьмака и какое-то время путешествовали вместе. Этот ведьмак кое-чему научил вас и поделился знаниями, которые считались давно утраченными.'),
      (6,'Посвящение в рыцарство за храбрость', '<b>+1 к Репутации</b> в одной стране на выбор', 'Так случилось, что в это десятилетие вы как минимум однажды храбро сражались за страну. Возможно, вы кого-то защищали или просто оказались в нужном месте в нужное время. За этот великий подвиг вас король или королева посвятил(а) в рыцари.'),
      (7,'Дружба с разбойниками', '<b>Услуга</b> скоя’таэлей', 'Во время охоты вы сдружились с группой разбойников или скоя’таэлей. Возможно, вы не совсем согласны с их методами, но они вас не тронули, так что вы отплатили им и вы. Вы даже пару раз выпивали вместе. Вы можете просить у них одну услугу в месяц, в пределах разумного (на усмотрение ведущего).'),
      (8,'Исследование руин', '<b>Находка в руинах:</b><br> - эльфийское усиление<br> - эльфийский мессер<br> - краснолюдское усиление<br> - гномий ручной арбалет<br> - краснолюдский плащ.', 'Вам пришлось охотиться на чудовище в огромных запутанных руинах. По пути вы нашли кое-что полезное.'),
      (9,'Долг мага', '<b>Услуга</b> мага', 'В это десятилетие вы помогли магу. Вы собирали части чудовищ для его экспериментов, позволили ему вас изучать или даже захватили для него живьём чудовище. Так или иначе, теперь этот маг должен вам одну услугу в пределах разумного (на усмотрение ведущего).'),
      (10,'Нашёл учителя', '<b>+1 к</b> любому <b>ИНТ-навыку</b> или новый <b>ИНТ-навык с +2</b>', 'Вы нашли себе наставника. Вы много недель учились, практиковались и задавали учителю вопросы. Это был необычный опыт.')
    ) AS raw_data_ru(num, head, effect, txt)

  UNION ALL

  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
      (1,'Law of Surprises','<b>Law of Surprise loot:</b><br> - a baby<br> - a dog<br> - a horse<br> - a new plow<br> - a cat<br> - a barrel of ale<br> - a piece of jewelry worth 10–60 crowns<br> - a weapon worth up to 500 crowns<br> - an ox<br> - a mule','During that decade you invoked the Law of Surprises.'),
      (2,'Romance','<b>A romance</b> with a random outcome:<br> - it lasted a few weeks<br> - it lasted a few months<br> - it is still going, on and off','You found a lover who saw past your mutations and lack of normal emotions. Somehow you formed a meaningful connection.'),
      (3,'Windfall','Between 100 and 1000 <b>crowns</b>','That decade you brought in a surprisingly large amount of coin. You paid for alchemical ingredients and gear repairs and even saved some for the future.'),
      (4,'A Noble Owes You','<b>A favor</b> from a noble','You performed a task for a noble. Whether legal or not, they owe you and know you may come to collect. You can invoke one reasonable favor at any time (GM discretion).'),
      (5,'Witcher Secrets Passed Down','<b>Witcher formula on choice:</b><br> - formula of oil<br> - formula of potion<br> - formula of decoction','On your journeys you met another witcher, traveled together, and learned some long-lost knowledge.'),
      (6,'Knighted For Valor','<b>+1 Reputation</b> in one country of your choice','At least once that decade you fought bravely for a country. For this deed, a king or queen knighted you.'),
      (7,'Fell in with Bandits','<b>A favor</b> from bandits or scoia’tael','While on a hunt you fell in with a group of bandits or scoia’tael. You did not bother each other and even shared drinks. You may ask them for one reasonable favor per month (GM discretion).'),
      (8,'Explored a Ruin','<b>Gear</b> from this list:<br> - elven enhancement<br> - elven messer<br> - dwarven enhancement<br> - gnomish hand crossbow<br> - dwarven cloak','You hunted a monster through a large, complex ruin and found something useful along the way.'),
      (9,'A Mage Owes You','<b>A favor</b> from mage','During this decade you did a favor for a mage: gathered monster parts, allowed study, or even captured a monster alive. The mage now owes you one reasonable favor (GM discretion).'),
      (10,'Found a Teacher','<b>+1 to</b> any <b>INT skill</b> or start a <b>new INT skill at +2</b>','You studied under a mentor for many weeks, learning and practicing. It was a strange experience.')
    ) AS raw_data_en(num, head, effect, txt)

)
,

vals AS (
  SELECT
    ('<td>'||effect||'</td>'
     ||'<td><b>'||head||':</b><br>'||txt||'</td>') AS text,
    num, lang, counter_txt
  FROM raw_data
  LEFT JOIN (VALUES ('"counterIncrement":
                        {
                          "id": "lifeEventsCounter",
                          "step": 10
                        }')) as c(counter_txt) ON raw_data.num in (4,6,7,9,10)
)
, ins_lbl AS (
  INSERT INTO i18n_text (id,entity,entity_field,lang,text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
       , meta.entity, meta.entity_field, vals.lang, vals.text
    FROM vals
    CROSS JOIN meta
)

INSERT INTO answer_options (an_id,su_su_id,qu_qu_id,label,sort_order,metadata)
SELECT
  'wcc_witcher_events_benefit_o'||to_char(vals.num,'FM00'),
  meta.su_su_id,
  meta.qu_id,
  ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
  vals.num,
  ('{' || coalesce(vals.counter_txt,'') || '}')::jsonb
FROM vals
CROSS JOIN meta
ON CONFLICT (an_id) DO NOTHING;

-- Эффекты
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_benefit' AS qu_id
                , 'character' AS entity)
-- i18n для eventType "Fortune"/"Удача"
, ins_event_type AS (
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
-- i18n для описаний событий (варианты 4, 7, 9)
, ins_desc_04 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| '04' ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', v.lang, v.text
      FROM (VALUES
        ('ru', 'Долг дворянина: вы выполнили работу для дворянина, и он вам должен услугу.'),
        ('en', 'A Noble Owes You: you performed a task for a noble, and they owe you a favor.')
      ) AS v(lang, text)
      CROSS JOIN meta
)
, ins_desc_07 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| '07' ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', v.lang, v.text
      FROM (VALUES
        ('ru', 'Дружба с разбойниками: вы сдружились с группой разбойников или скоя''таэлей.'),
        ('en', 'Fell in with Bandits: you befriended a group of bandits or scoia''tael.')
      ) AS v(lang, text)
      CROSS JOIN meta
)
, ins_desc_09 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| '09' ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', v.lang, v.text
      FROM (VALUES
        ('ru', 'Долг мага: вы помогли магу, и теперь он вам должен услугу.'),
        ('en', 'A Mage Owes You: you helped a mage, and they now owe you a favor.')
      ) AS v(lang, text)
      CROSS JOIN meta
)
-- i18n для gear items
, ins_gear_04 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| '04' ||'.'|| 'gear_name') AS id
         , 'gear', 'name', v.lang, v.text
      FROM (VALUES
        ('ru', 'Услуга дворянина'),
        ('en', 'Nobleman Service')
      ) AS v(lang, text)
      CROSS JOIN meta
)
, ins_gear_07 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| '07' ||'.'|| 'gear_name') AS id
         , 'gear', 'name', v.lang, v.text
      FROM (VALUES
        ('ru', 'Ежемесячная услуга скоя''таэлей'),
        ('en', 'Monthly Scoia''tael Service')
      ) AS v(lang, text)
      CROSS JOIN meta
)
, ins_gear_09 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| '09' ||'.'|| 'gear_name') AS id
         , 'gear', 'name', v.lang, v.text
      FROM (VALUES
        ('ru', 'Услуга мага'),
        ('en', 'Mage Service')
      ) AS v(lang, text)
      CROSS JOIN meta
)
, event_items AS (
  SELECT num FROM (VALUES (4), (7), (9)) AS v(num)
)
INSERT INTO effects (scope, an_an_id, body)
-- 1. Добавление в lifeEvents (варианты 4, 7, 9)
SELECT 'character', 'wcc_witcher_events_benefit_o' || to_char(event_items.num, 'FM00'),
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
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(event_items.num, 'FM00') ||'.'|| 'event_desc')::text)
      )
    )
  )
FROM event_items
CROSS JOIN meta
UNION ALL
-- 2. Добавление в gear (варианты 4, 7, 9)
SELECT 'character', 'wcc_witcher_events_benefit_o' || to_char(event_items.num, 'FM00'),
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.gear'),
      jsonb_build_object(
        'name', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(event_items.num, 'FM00') ||'.'|| 'gear_name')::text),
        'weight', 0
      )
    )
  )
FROM event_items
CROSS JOIN meta;

-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id) 
  SELECT 'wcc_witcher_events', 'wcc_witcher_events_benefit', 'wcc_witcher_events_o0101' UNION ALL
  SELECT 'wcc_witcher_events', 'wcc_witcher_events_benefit', 'wcc_witcher_events_o0201' UNION ALL
  SELECT 'wcc_witcher_events', 'wcc_witcher_events_benefit', 'wcc_witcher_events_o0301' UNION ALL
  SELECT 'wcc_witcher_events', 'wcc_witcher_events_benefit', 'wcc_witcher_events_o0401'
  ;

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_witcher_events_benefit', 'wcc_witcher_events_risk', r.ru_id, 1
    FROM (SELECT ru_id FROM rules WHERE name = 'lifeEventsCounter_is_valid') r;