\echo '072_witcher_events_benefit_details.sql'

-- Вопрос: уточнения к опасностям ведьмака
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_benefit_details' AS qu_id
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
           SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_witcher_events_benefit_details' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
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
           ck_id('witcher_cc.hierarchy.witcher_events_benefit_details')::text
         )
       )
  FROM meta;

-- Ответы (RU/EN)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_benefit_details' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
      -- 1. Право неожиданности
      ( 1, 1, 0.1, '<b>Случайная находка</b>: ребёнок'),
      ( 1, 2, 0.1, '<b>Случайная находка</b>: собака'),
      ( 1, 3, 0.1, '<b>Случайная находка</b>: лошадь'),
      ( 1, 4, 0.1, '<b>Случайная находка</b>: новый плуг'),
      ( 1, 5, 0.1, '<b>Случайная находка</b>: кошка'),
      ( 1, 6, 0.1, '<b>Случайная находка</b>: бочка эля'),
      ( 1, 7, 0.1, '<b>Случайная находка</b>: драгоценность стоимостью 10-60 крон'),
      ( 1, 8, 0.1, '<b>Случайная находка</b>: оружие стоимостью до 500 крон'),
      ( 1, 9, 0.1, '<b>Случайная находка</b>: бык'),
      ( 1,10, 0.1, '<b>Случайная находка</b>: мул'),

      -- 2. Любовный интерес
      ( 2, 1, 0.6, '<b>Любовный интерес</b>: всё длилось пару недель'),
      ( 2, 2, 0.2, '<b>Любовный интерес</b>: всё длилось пару месяцев'),
      ( 2, 3, 0.2, '<b>Любовный интерес</b>: роман до сих пор продолжается с переменным успехом'),

      -- 3. Неожиданная удача
      ( 3, 1, 0.1, '<b>Неожиданная удача</b>: вы получили 100 крон'),

      -- 5. Ведьмачьи тайны - алхимические формулы
      ( 5, 1, 0.3333, '<b>Алхимическая формула</b>: масло'),
      ( 5, 2, 0.3333, '<b>Алхимическая формула</b>: эликсир'),
      ( 5, 3, 0.3334, '<b>Алхимическая формула</b>: отвар'),
      ( 3, 2, 0.1, '<b>Неожиданная удача</b>: вы получили 200 крон'),
      ( 3, 3, 0.1, '<b>Неожиданная удача</b>: вы получили 300 крон'),
      ( 3, 4, 0.1, '<b>Неожиданная удача</b>: вы получили 400 крон'),
      ( 3, 5, 0.1, '<b>Неожиданная удача</b>: вы получили 500 крон'),
      ( 3, 6, 0.1, '<b>Неожиданная удача</b>: вы получили 600 крон'),
      ( 3, 7, 0.1, '<b>Неожиданная удача</b>: вы получили 700 крон'),
      ( 3, 8, 0.1, '<b>Неожиданная удача</b>: вы получили 800 крон'),
      ( 3, 9, 0.1, '<b>Неожиданная удача</b>: вы получили 900 крон'),
      ( 3,10, 0.1, '<b>Неожиданная удача</b>: вы получили 1000 крон'),

      -- 6. Посвящение в рыцарство за храбрость - королевства
      ( 6, 1, 0.041, 'Редания'),
      ( 6, 2, 0.041, 'Каэдвен'),
      ( 6, 3, 0.041, 'Темерия'),
      ( 6, 4, 0.041, 'Аэдирн'),
      ( 6, 5, 0.041, 'Лирия'),
      ( 6, 6, 0.041, 'Ривия'),
      ( 6, 7, 0.041, 'Ковир'),
      ( 6, 8, 0.041, 'Повис'),
      ( 6, 9, 0.041, 'Скеллиге'),
      ( 6,10, 0.041, 'Цидарис'),
      ( 6,11, 0.041, 'Вердэн'),
      ( 6,12, 0.041, 'Цинтра'),
      ( 6,13, 0.041, 'Сердце Нильфгаарда'),
      ( 6,14, 0.041, 'Вассальное государство Нильфгаарда - Виковаро'),
      ( 6,15, 0.041, 'Вассальное государство Нильфгаарда - Аигрен'),
      ( 6,16, 0.041, 'Вассальное государство Нильфгаарда - Назаир'),
      ( 6,17, 0.041, 'Вассальное государство Нильфгаарда - Метиина'),
      ( 6,18, 0.041, 'Вассальное государство Нильфгаарда - Маг Турга'),
      ( 6,19, 0.041, 'Вассальное государство Нильфгаарда - Гесо'),
      ( 6,20, 0.041, 'Вассальное государство Нильфгаарда - Эббинг'),
      ( 6,21, 0.041, 'Вассальное государство Нильфгаарда - Мехт'),
      ( 6,22, 0.041, 'Вассальное государство Нильфгаарда - Геммера'),
      ( 6,23, 0.041, 'Вассальное государство Нильфгаарда - Этолия'),
      ( 6,24, 0.041, 'Вассальное государство Нильфгаарда - Туссент'),

      -- 8. Исследование руин
      ( 8, 1, 0.2, '<b>Находка в руинах</b>: эльфийское усиление'),
      ( 8, 2, 0.2, '<b>Находка в руинах</b>: эльфийский мессер'),
      ( 8, 3, 0.2, '<b>Находка в руинах</b>: краснолюдское усиление'),
      ( 8, 4, 0.2, '<b>Находка в руинах</b>: гномий ручной арбалет'),
      ( 8, 5, 0.2, '<b>Находка в руинах</b>: краснолюдский плащ'),

      -- 10. Нашёл учителя - навыки интеллекта
      (10, 1, 0.0909, 'Внимание'),
      (10, 2, 0.0909, 'Выживание в дикой природе'),
      (10, 3, 0.0909, 'Дедукция'),
      (10, 4, 0.0909, 'Монстрология'),
      (10, 5, 0.0909, 'Образование'),
      (10, 6, 0.0909, 'Ориентирование в городе'),
      (10, 7, 0.0909, 'Передача знаний'),
      (10, 8, 0.0909, 'Тактика'),
      (10, 9, 0.0909, 'Торговля'),
      (10,10, 0.0909, 'Этикет'),
      (10,11, 0.0303, 'Язык - северный'),
      (10,12, 0.0303, 'Язык - дварфийский'),
      (10,13, 0.0303, 'Язык - старшая речь')
    ) AS raw_data_ru(group_id, num, probability, txt)

  UNION ALL

  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
    -- 1. Law of Surprise
    ( 1, 1, 0.10, '<b>Random Boon</b>: a baby'),
    ( 1, 2, 0.10, '<b>Random Boon</b>: a dog'),
    ( 1, 3, 0.10, '<b>Random Boon</b>: a horse'),
    ( 1, 4, 0.10, '<b>Random Boon</b>: a new plow'),
    ( 1, 5, 0.10, '<b>Random Boon</b>: a cat'),
    ( 1, 6, 0.10, '<b>Random Boon</b>: a barrel of ale'),
    ( 1, 7, 0.10, '<b>Random Boon</b>: jewelry worth 10–60 crowns'),
    ( 1, 8, 0.10, '<b>Random Boon</b>: a weapon worth up to 500 crowns'),
    ( 1, 9, 0.10, '<b>Random Boon</b>: an ox'),
    ( 1,10, 0.10, '<b>Random Boon</b>: a mule'),

    -- 2. Romance
    ( 2, 1, 0.60, '<b>Romance</b>: lasted a few weeks'),
    ( 2, 2, 0.20, '<b>Romance</b>: lasted a few months'),
    ( 2, 3, 0.20, '<b>Romance</b>: still going, on and off'),

    -- 3. Windfall
    ( 3, 1, 0.10, '<b>Windfall</b>: you gained 100 crowns'),

    -- 5. Witcher Secrets Passed Down - alchemical formulas
    ( 5, 1, 0.3333, '<b>Alchemical Formula</b>: oil'),
    ( 5, 2, 0.3333, '<b>Alchemical Formula</b>: potion'),
    ( 5, 3, 0.3334, '<b>Alchemical Formula</b>: decoction'),
    ( 3, 2, 0.10, '<b>Windfall</b>: you gained 200 crowns'),
    ( 3, 3, 0.10, '<b>Windfall</b>: you gained 300 crowns'),
    ( 3, 4, 0.10, '<b>Windfall</b>: you gained 400 crowns'),
    ( 3, 5, 0.10, '<b>Windfall</b>: you gained 500 crowns'),
    ( 3, 6, 0.10, '<b>Windfall</b>: you gained 600 crowns'),
    ( 3, 7, 0.10, '<b>Windfall</b>: you gained 700 crowns'),
    ( 3, 8, 0.10, '<b>Windfall</b>: you gained 800 crowns'),
    ( 3, 9, 0.10, '<b>Windfall</b>: you gained 900 crowns'),
    ( 3,10, 0.10, '<b>Windfall</b>: you gained 1000 crowns'),

    -- 6. Knighted For Valor - kingdoms
    ( 6, 1, 0.041, 'Redania'),
    ( 6, 2, 0.041, 'Kaedwen'),
    ( 6, 3, 0.041, 'Temeria'),
    ( 6, 4, 0.041, 'Aedirn'),
    ( 6, 5, 0.041, 'Lyria'),
    ( 6, 6, 0.041, 'Rivia'),
    ( 6, 7, 0.041, 'Kovir'),
    ( 6, 8, 0.041, 'Poviss'),
    ( 6, 9, 0.041, 'Skellige'),
    ( 6,10, 0.041, 'Cidaris'),
    ( 6,11, 0.041, 'Verden'),
    ( 6,12, 0.041, 'Cintra'),
    ( 6,13, 0.041, 'The Heart of Nilfgaard'),
    ( 6,14, 0.041, 'Nilfgaardian Vassal State - Vicovaro'),
    ( 6,15, 0.041, 'Nilfgaardian Vassal State - Angren'),
    ( 6,16, 0.041, 'Nilfgaardian Vassal State - Nazair'),
    ( 6,17, 0.041, 'Nilfgaardian Vassal State - Mettina'),
    ( 6,18, 0.041, 'Nilfgaardian Vassal State - Mag Turga'),
    ( 6,19, 0.041, 'Nilfgaardian Vassal State - Gheso'),
    ( 6,20, 0.041, 'Nilfgaardian Vassal State - Ebbing'),
    ( 6,21, 0.041, 'Nilfgaardian Vassal State - Maecht'),
    ( 6,22, 0.041, 'Nilfgaardian Vassal State - Gemmeria'),
    ( 6,23, 0.041, 'Nilfgaardian Vassal State - Etolia'),
    ( 6,24, 0.041, 'Nilfgaardian Vassal State - Toussaint'),

    -- 8. Explored a Ruin
    ( 8, 1, 0.20, '<b>Ruin Find</b>: elven enhancement'),
    ( 8, 2, 0.20, '<b>Ruin Find</b>: elven messer'),
    ( 8, 3, 0.20, '<b>Ruin Find</b>: dwarven enhancement'),
    ( 8, 4, 0.20, '<b>Ruin Find</b>: gnomish hand crossbow'),
    ( 8, 5, 0.20, '<b>Ruin Find</b>: dwarven cloak'),

    -- 10. Found a Teacher - INT skills
    (10, 1, 0.0909, 'Awareness'),
    (10, 2, 0.0909, 'Wilderness Survival'),
    (10, 3, 0.0909, 'Deduction'),
    (10, 4, 0.0909, 'Monster Lore'),
    (10, 5, 0.0909, 'Education'),
    (10, 6, 0.0909, 'Streetwise'),
    (10, 7, 0.0909, 'Teaching'),
    (10, 8, 0.0909, 'Tactics'),
    (10, 9, 0.0909, 'Business'),
    (10,10, 0.0909, 'Social Etiquette'),
    (10,11, 0.0303, 'Language - Northern'),
    (10,12, 0.0303, 'Language - Dwarvish'),
    (10,13, 0.0303, 'Language - Elder Speech')
  ) AS raw_data_en(group_id, num, probability, txt)
),

vals AS (
  SELECT ('<td>'||to_char(probability*100,'FM990.00')||'%</td>'
         ||'<td>'||txt||'</td>') AS text
       , group_id
       , num
       , probability
       , lang
       , counter_txt
  FROM raw_data
  LEFT JOIN (VALUES ('"counterIncrement":
                        {
                          "id": "lifeEventsCounter",
                          "step": 10
                        }')) as c(counter_txt) ON NOT (raw_data.group_id = 1 AND raw_data.num = 7)
)
, ins_lbl AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*vals.group_id+vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
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
                        { "var": ["answers.byQuestion.wcc_witcher_events_benefit", []] },
                        { "var": "current" },
                        null
                      ]
                  },
                  "wcc_witcher_events_benefit_o' || to_char(group_id, 'FM00') || '"
                ]
            }')::jsonb FROM (SELECT DISTINCT group_id FROM raw_data) v(group_id)
),
ins_rules AS (
  INSERT INTO rules(ru_id, body) SELECT r.id, r.body FROM rules_vals r
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, visible_ru_ru_id, sort_order,metadata)
SELECT
  'wcc_witcher_events_benefit_details_o'||to_char(vals.group_id,'FM00')||to_char(vals.num,'FM00'),
  meta.su_su_id,
  meta.qu_id,
  ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*vals.group_id+vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
  r.id,
  vals.num,
  jsonb_build_object(
           'probability', vals.probability
  ) || ('{'|| coalesce(vals.counter_txt,'') ||'}')::jsonb
FROM vals
CROSS JOIN meta
JOIN rules_vals r ON vals.group_id = r.group_id
ON CONFLICT (an_id) DO NOTHING;

-- Эффекты
WITH
  raw_data AS (
    SELECT DISTINCT group_id, num
    FROM (VALUES
      (1,1), (1,2), (1,3), (1,4), (1,5), (1,6), (1,8), (1,9), (1,10),
      (2,1), (2,2), (2,3),
      (3,1), (3,2), (3,3), (3,4), (3,5), (3,6), (3,7), (3,8), (3,9), (3,10),
      (5,1), (5,2), (5,3),
      (6,1), (6,2), (6,3), (6,4), (6,5), (6,6), (6,7), (6,8), (6,9), (6,10),
      (6,11), (6,12), (6,13), (6,14), (6,15), (6,16), (6,17), (6,18), (6,19), (6,20),
      (6,21), (6,22), (6,23), (6,24),
      (8,1), (8,2), (8,3), (8,4), (8,5),
      (10,1), (10,2), (10,3), (10,4), (10,5), (10,6), (10,7), (10,8), (10,9), (10,10),
      (10,11), (10,12), (10,13)
    ) AS v(group_id, num)
  )
, meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_benefit_details' AS qu_id
                , 'character' AS entity)
-- i18n для eventType "Fortune"/"Удача" и "Relationships"/"Отношения"
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
, ins_event_type_relationships AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id('witcher_cc' ||'.'|| 'wcc_life_events_relationships' ||'.'|| 'event_type_relationships') AS id
         , meta.entity, 'event_type', v.lang, v.text
      FROM (VALUES
        ('ru', 'Отношения'),
        ('en', 'Relationships')
      ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
)
-- i18n для описаний событий группы 1 (кроме варианта 7)
, ins_desc_01 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*1+vals.num, 'FM0000') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Право Неожиданности: получен ребёнок-неожиданность.'),
        ('ru', 2, 'Право Неожиданности: получена собака.'),
        ('ru', 3, 'Право Неожиданности: получена лошадь.'),
        ('ru', 4, 'Право Неожиданности: получен новый плуг.'),
        ('ru', 5, 'Право Неожиданности: получена кошка.'),
        ('ru', 6, 'Право Неожиданности: получена бочка эля.'),
        ('ru', 8, 'Право Неожиданности: получено оружие стоимостью до 500 крон (на усмотрение мастера).'),
        ('ru', 9, 'Право Неожиданности: получен бык.'),
        ('ru',10, 'Право Неожиданности: получен мул.'),
        ('en', 1, 'Law of Surprises: received a child of surprise.'),
        ('en', 2, 'Law of Surprises: received a dog.'),
        ('en', 3, 'Law of Surprises: received a horse.'),
        ('en', 4, 'Law of Surprises: received a new plow.'),
        ('en', 5, 'Law of Surprises: received a cat.'),
        ('en', 6, 'Law of Surprises: received a barrel of ale.'),
        ('en', 8, 'Law of Surprises: received a weapon worth up to 500 crowns (GM discretion).'),
        ('en', 9, 'Law of Surprises: received an ox.'),
        ('en',10, 'Law of Surprises: received a mule.')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- i18n для описаний событий группы 2
, ins_desc_02 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*2+vals.num, 'FM0000') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Роман: всё длилось пару недель.'),
        ('ru', 2, 'Роман: всё длилось пару месяцев.'),
        ('ru', 3, 'Роман: роман до сих пор продолжается с переменным успехом.'),
        ('en', 1, 'Romance: lasted a few weeks.'),
        ('en', 2, 'Romance: lasted a few months.'),
        ('en', 3, 'Romance: still going, on and off.')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- i18n для описаний событий группы 3
, ins_desc_03 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*3+vals.num, 'FM0000') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Неожиданная удача: получено 100 крон.'),
        ('ru', 2, 'Неожиданная удача: получено 200 крон.'),
        ('ru', 3, 'Неожиданная удача: получено 300 крон.'),
        ('ru', 4, 'Неожиданная удача: получено 400 крон.'),
        ('ru', 5, 'Неожиданная удача: получено 500 крон.'),
        ('ru', 6, 'Неожиданная удача: получено 600 крон.'),
        ('ru', 7, 'Неожиданная удача: получено 700 крон.'),
        ('ru', 8, 'Неожиданная удача: получено 800 крон.'),
        ('ru', 9, 'Неожиданная удача: получено 900 крон.'),
        ('ru',10, 'Неожиданная удача: получено 1000 крон.'),
        ('en', 1, 'Windfall: gained 100 crowns.'),
        ('en', 2, 'Windfall: gained 200 crowns.'),
        ('en', 3, 'Windfall: gained 300 crowns.'),
        ('en', 4, 'Windfall: gained 400 crowns.'),
        ('en', 5, 'Windfall: gained 500 crowns.'),
        ('en', 6, 'Windfall: gained 600 crowns.'),
        ('en', 7, 'Windfall: gained 700 crowns.'),
        ('en', 8, 'Windfall: gained 800 crowns.'),
        ('en', 9, 'Windfall: gained 900 crowns.'),
        ('en',10, 'Windfall: gained 1000 crowns.')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- i18n для описаний событий группы 5
, ins_desc_05 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*5+vals.num, 'FM0000') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Ведьмачьи тайны: вы встретили другого ведьмака и научились формуле масла.'),
        ('ru', 2, 'Ведьмачьи тайны: вы встретили другого ведьмака и научились формуле эликсира.'),
        ('ru', 3, 'Ведьмачьи тайны: вы встретили другого ведьмака и научились формуле отвара.'),
        ('en', 1, 'Witcher Secrets Passed Down: you met another witcher and learned an oil formula.'),
        ('en', 2, 'Witcher Secrets Passed Down: you met another witcher and learned a potion formula.'),
        ('en', 3, 'Witcher Secrets Passed Down: you met another witcher and learned a decoction formula.')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- i18n для описаний событий группы 6
, ins_desc_06 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*6+vals.num, 'FM0000') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Посвящение в рыцари: посвящены в рыцари в Редании (+1 к репутации).'),
        ('ru', 2, 'Посвящение в рыцари: посвящены в рыцари в Каэдвене (+1 к репутации).'),
        ('ru', 3, 'Посвящение в рыцари: посвящены в рыцари в Темерии (+1 к репутации).'),
        ('ru', 4, 'Посвящение в рыцари: посвящены в рыцари в Аэдирне (+1 к репутации).'),
        ('ru', 5, 'Посвящение в рыцари: посвящены в рыцари в Лирии (+1 к репутации).'),
        ('ru', 6, 'Посвящение в рыцари: посвящены в рыцари в Ривии (+1 к репутации).'),
        ('ru', 7, 'Посвящение в рыцари: посвящены в рыцари в Ковире (+1 к репутации).'),
        ('ru', 8, 'Посвящение в рыцари: посвящены в рыцари в Повиссе (+1 к репутации).'),
        ('ru', 9, 'Посвящение в рыцари: посвящены в рыцари в Скеллиге (+1 к репутации).'),
        ('ru',10, 'Посвящение в рыцари: посвящены в рыцари в Цидарисе (+1 к репутации).'),
        ('ru',11, 'Посвящение в рыцари: посвящены в рыцари в Вердене (+1 к репутации).'),
        ('ru',12, 'Посвящение в рыцари: посвящены в рыцари в Цинтре (+1 к репутации).'),
        ('ru',13, 'Посвящение в рыцари: посвящены в рыцари в Сердце Нильфгаарда (+1 к репутации).'),
        ('ru',14, 'Посвящение в рыцари: посвящены в рыцари в Виковаро (+1 к репутации).'),
        ('ru',15, 'Посвящение в рыцари: посвящены в рыцари в Аигрене (+1 к репутации).'),
        ('ru',16, 'Посвящение в рыцари: посвящены в рыцари в Назаире (+1 к репутации).'),
        ('ru',17, 'Посвящение в рыцари: посвящены в рыцари в Метиине (+1 к репутации).'),
        ('ru',18, 'Посвящение в рыцари: посвящены в рыцари в Маг Турге (+1 к репутации).'),
        ('ru',19, 'Посвящение в рыцари: посвящены в рыцари в Гесо (+1 к репутации).'),
        ('ru',20, 'Посвящение в рыцари: посвящены в рыцари в Эббинге (+1 к репутации).'),
        ('ru',21, 'Посвящение в рыцари: посвящены в рыцари в Мехте (+1 к репутации).'),
        ('ru',22, 'Посвящение в рыцари: посвящены в рыцари в Геммерии (+1 к репутации).'),
        ('ru',23, 'Посвящение в рыцари: посвящены в рыцари в Этолии (+1 к репутации).'),
        ('ru',24, 'Посвящение в рыцари: посвящены в рыцари в Туссенте (+1 к репутации).'),
        ('en', 1, 'Knighted: knighted in Redania (+1 reputation).'),
        ('en', 2, 'Knighted: knighted in Kaedwen (+1 reputation).'),
        ('en', 3, 'Knighted: knighted in Temeria (+1 reputation).'),
        ('en', 4, 'Knighted: knighted in Aedirn (+1 reputation).'),
        ('en', 5, 'Knighted: knighted in Lyria (+1 reputation).'),
        ('en', 6, 'Knighted: knighted in Rivia (+1 reputation).'),
        ('en', 7, 'Knighted: knighted in Kovir (+1 reputation).'),
        ('en', 8, 'Knighted: knighted in Poviss (+1 reputation).'),
        ('en', 9, 'Knighted: knighted in Skellige (+1 reputation).'),
        ('en',10, 'Knighted: knighted in Cidaris (+1 reputation).'),
        ('en',11, 'Knighted: knighted in Verden (+1 reputation).'),
        ('en',12, 'Knighted: knighted in Cintra (+1 reputation).'),
        ('en',13, 'Knighted: knighted in The Heart of Nilfgaard (+1 reputation).'),
        ('en',14, 'Knighted: knighted in Vicovaro (+1 reputation).'),
        ('en',15, 'Knighted: knighted in Angren (+1 reputation).'),
        ('en',16, 'Knighted: knighted in Nazair (+1 reputation).'),
        ('en',17, 'Knighted: knighted in Mettina (+1 reputation).'),
        ('en',18, 'Knighted: knighted in Mag Turga (+1 reputation).'),
        ('en',19, 'Knighted: knighted in Gheso (+1 reputation).'),
        ('en',20, 'Knighted: knighted in Ebbing (+1 reputation).'),
        ('en',21, 'Knighted: knighted in Maecht (+1 reputation).'),
        ('en',22, 'Knighted: knighted in Gemmeria (+1 reputation).'),
        ('en',23, 'Knighted: knighted in Etolia (+1 reputation).'),
        ('en',24, 'Knighted: knighted in Toussaint (+1 reputation).')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- i18n для описаний событий группы 8
, ins_desc_08 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*8+vals.num, 'FM0000') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Исследование руин: найдено эльфийское усиление.'),
        ('ru', 2, 'Исследование руин: найден эльфийский мессер.'),
        ('ru', 3, 'Исследование руин: найдено краснолюдское усиление.'),
        ('ru', 4, 'Исследование руин: найден гномий ручной арбалет.'),
        ('ru', 5, 'Исследование руин: найден краснолюдский плащ.'),
        ('en', 1, 'Explored a Ruin: found elven enhancement.'),
        ('en', 2, 'Explored a Ruin: found elven messer.'),
        ('en', 3, 'Explored a Ruin: found dwarven enhancement.'),
        ('en', 4, 'Explored a Ruin: found gnomish hand crossbow.'),
        ('en', 5, 'Explored a Ruin: found dwarven cloak.')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- i18n для описаний событий группы 10
, ins_desc_10 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*10+vals.num, 'FM0000') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Нашёл учителя: +1 к Вниманию или новый навык +2.'),
        ('ru', 2, 'Нашёл учителя: +1 к Выживанию в дикой природе или новый +2.'),
        ('ru', 3, 'Нашёл учителя: +1 к Дедукции или новый навык +2.'),
        ('ru', 4, 'Нашёл учителя: +1 к Монстрологии или новый навык +2.'),
        ('ru', 5, 'Нашёл учителя: +1 к Образованию или новый навык +2.'),
        ('ru', 6, 'Нашёл учителя: +1 к Ориентированию в городе или новый +2.'),
        ('ru', 7, 'Нашёл учителя: +1 к Передаче знаний или новый навык +2.'),
        ('ru', 8, 'Нашёл учителя: +1 к Тактике или новый навык +2.'),
        ('ru', 9, 'Нашёл учителя: +1 к Торговле или новый навык +2.'),
        ('ru',10, 'Нашёл учителя: +1 к Этикету или новый навык +2.'),
        ('ru',11, 'Нашёл учителя: +1 к Языку - северный или новый +2.'),
        ('ru',12, 'Нашёл учителя: +1 к Языку - дварфийский или новый +2.'),
        ('ru',13, 'Нашёл учителя: +1 к Языку - старшая речь или новый +2.'),
        ('en', 1, 'Found a Teacher: +1 Awareness or new skill +2.'),
        ('en', 2, 'Found a Teacher: +1 Wilderness Survival or new +2.'),
        ('en', 3, 'Found a Teacher: +1 Deduction or new skill +2.'),
        ('en', 4, 'Found a Teacher: +1 Monster Lore or new skill +2.'),
        ('en', 5, 'Found a Teacher: +1 Education or new skill +2.'),
        ('en', 6, 'Found a Teacher: +1 Streetwise or new skill +2.'),
        ('en', 7, 'Found a Teacher: +1 Teaching or new skill +2.'),
        ('en', 8, 'Found a Teacher: +1 Tactics or new skill +2.'),
        ('en', 9, 'Found a Teacher: +1 Business or new skill +2.'),
        ('en',10, 'Found a Teacher: +1 Social Etiquette or new +2.'),
        ('en',11, 'Found a Teacher: +1 Language - Northern or new +2.'),
        ('en',12, 'Found a Teacher: +1 Language - Dwarvish or new +2.'),
        ('en',13, 'Found a Teacher: +1 Language - Elder Speech or new +2.')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- i18n для gear items группы 1 (кроме варианта 7)
, ins_gear_01 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*1+vals.num, 'FM0000') ||'.'|| 'gear_name') AS id
         , 'gear', 'name', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Ребёнок-неожиданность'),
        ('ru', 2, 'Собака'),
        ('ru', 3, 'Лошадь'),
        ('ru', 4, 'Новый плуг'),
        ('ru', 5, 'Кошка'),
        ('ru', 6, 'Бочка эля'),
        ('ru', 8, 'Оружие (до 500 крон, на усмотрение мастера)'),
        ('ru', 9, 'Бык'),
        ('ru',10, 'Мул'),
        ('en', 1, 'Child of Surprise'),
        ('en', 2, 'Dog'),
        ('en', 3, 'Horse'),
        ('en', 4, 'New Plow'),
        ('en', 5, 'Cat'),
        ('en', 6, 'Barrel of Ale'),
        ('en', 8, 'Weapon (up to 500 crowns, GM discretion)'),
        ('en', 9, 'Ox'),
        ('en',10, 'Mule')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- i18n для gear items группы 5
, ins_gear_05 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*5+vals.num, 'FM0000') ||'.'|| 'gear_name') AS id
         , 'gear', 'name', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Алхимическая формула масла'),
        ('ru', 2, 'Алхимическая формула эликсира'),
        ('ru', 3, 'Алхимическая формула отвара'),
        ('en', 1, 'Alchemical Formula: Oil'),
        ('en', 2, 'Alchemical Formula: Potion'),
        ('en', 3, 'Alchemical Formula: Decoction')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- i18n для gear items группы 8
, ins_gear_08 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*8+vals.num, 'FM0000') ||'.'|| 'gear_name') AS id
         , 'gear', 'name', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Эльфийское усиление'),
        ('ru', 2, 'Эльфийский мессер'),
        ('ru', 3, 'Краснолюдское усиление'),
        ('ru', 4, 'Гномий ручной арбалет'),
        ('ru', 5, 'Краснолюдский плащ'),
        ('en', 1, 'Elven Enhancement'),
        ('en', 2, 'Elven Messer'),
        ('en', 3, 'Dwarven Enhancement'),
        ('en', 4, 'Gnomish Hand Crossbow'),
        ('en', 5, 'Dwarven Cloak')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- Маппинг навыков для группы 10
, skill_mapping_group10 AS (
  SELECT 1 AS num, 'awareness' AS skill_path
  UNION ALL SELECT 2, 'wilderness_survival'
  UNION ALL SELECT 3, 'deduction'
  UNION ALL SELECT 4, 'monster_lore'
  UNION ALL SELECT 5, 'education'
  UNION ALL SELECT 6, 'streetwise'
  UNION ALL SELECT 7, 'teaching'
  UNION ALL SELECT 8, 'tactics'
  UNION ALL SELECT 9, 'business'
  UNION ALL SELECT 10, 'social_etiquette'
  UNION ALL SELECT 11, 'language_northern'
  UNION ALL SELECT 12, 'language_dwarvish'
  UNION ALL SELECT 13, 'language_elder_speech'
)
INSERT INTO effects (scope, an_an_id, body)
-- Группа 1 (кроме варианта 7): lifeEvents + gear
SELECT DISTINCT
  'character', 'wcc_witcher_events_benefit_details_o' || to_char(1, 'FM00') || to_char(raw_data.num, 'FM00'),
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
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*1+raw_data.num, 'FM0000') ||'.'|| 'event_desc')::text)
      )
    )
  )
FROM raw_data
CROSS JOIN meta
WHERE raw_data.group_id = 1 AND raw_data.num != 7
UNION ALL
SELECT DISTINCT
  'character', 'wcc_witcher_events_benefit_details_o' || to_char(1, 'FM00') || to_char(raw_data.num, 'FM00'),
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.gear'),
      jsonb_build_object(
        'name', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*1+raw_data.num, 'FM0000') ||'.'|| 'gear_name')::text),
        'weight', 0
      )
    )
  )
FROM raw_data
CROSS JOIN meta
WHERE raw_data.group_id = 1 AND raw_data.num != 7
UNION ALL
-- Группа 2: lifeEvents (Отношения)
SELECT DISTINCT
  'character', 'wcc_witcher_events_benefit_details_o' || to_char(2, 'FM00') || to_char(raw_data.num, 'FM00'),
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
        jsonb_build_object('i18n_uuid', ck_id('witcher_cc' ||'.'|| 'wcc_life_events_relationships' ||'.'|| 'event_type_relationships')::text),
        'description',
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*2+raw_data.num, 'FM0000') ||'.'|| 'event_desc')::text)
      )
    )
  )
FROM raw_data
CROSS JOIN meta
WHERE raw_data.group_id = 2
UNION ALL
-- Группа 3: lifeEvents + деньги
SELECT DISTINCT
  'character', 'wcc_witcher_events_benefit_details_o' || to_char(3, 'FM00') || to_char(raw_data.num, 'FM00'),
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
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*3+raw_data.num, 'FM0000') ||'.'|| 'event_desc')::text)
      )
    )
  )
FROM raw_data
CROSS JOIN meta
WHERE raw_data.group_id = 3
UNION ALL
SELECT DISTINCT
  'character', 'wcc_witcher_events_benefit_details_o' || to_char(3, 'FM00') || to_char(raw_data.num, 'FM00'),
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.money.crowns'),
      raw_data.num * 100
    )
  )
FROM raw_data
CROSS JOIN meta
WHERE raw_data.group_id = 3
UNION ALL
-- Группа 5: lifeEvents + gear (алхимическая формула)
SELECT DISTINCT
  'character', 'wcc_witcher_events_benefit_details_o' || to_char(5, 'FM00') || to_char(raw_data.num, 'FM00'),
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
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*5+raw_data.num, 'FM0000') ||'.'|| 'event_desc')::text)
      )
    )
  )
FROM raw_data
CROSS JOIN meta
WHERE raw_data.group_id = 5
UNION ALL
SELECT DISTINCT
  'character', 'wcc_witcher_events_benefit_details_o' || to_char(5, 'FM00') || to_char(raw_data.num, 'FM00'),
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.gear'),
      jsonb_build_object(
        'name', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*5+raw_data.num, 'FM0000') ||'.'|| 'gear_name')::text),
        'weight', 0
      )
    )
  )
FROM raw_data
CROSS JOIN meta
WHERE raw_data.group_id = 5
UNION ALL
-- Группа 6: lifeEvents
SELECT DISTINCT
  'character', 'wcc_witcher_events_benefit_details_o' || to_char(6, 'FM00') || to_char(raw_data.num, 'FM00'),
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
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*6+raw_data.num, 'FM0000') ||'.'|| 'event_desc')::text)
      )
    )
  )
FROM raw_data
CROSS JOIN meta
WHERE raw_data.group_id = 6
UNION ALL
-- Группа 8: lifeEvents + gear
SELECT DISTINCT
  'character', 'wcc_witcher_events_benefit_details_o' || to_char(8, 'FM00') || to_char(raw_data.num, 'FM00'),
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
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*8+raw_data.num, 'FM0000') ||'.'|| 'event_desc')::text)
      )
    )
  )
FROM raw_data
CROSS JOIN meta
WHERE raw_data.group_id = 8
UNION ALL
SELECT DISTINCT
  'character', 'wcc_witcher_events_benefit_details_o' || to_char(8, 'FM00') || to_char(raw_data.num, 'FM00'),
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.gear'),
      jsonb_build_object(
        'name', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*8+raw_data.num, 'FM0000') ||'.'|| 'gear_name')::text),
        'weight', 0
      )
    )
  )
FROM raw_data
CROSS JOIN meta
WHERE raw_data.group_id = 8
UNION ALL
-- Группа 10: lifeEvents + навык
SELECT DISTINCT
  'character', 'wcc_witcher_events_benefit_details_o' || to_char(10, 'FM00') || to_char(raw_data.num, 'FM00'),
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
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*10+raw_data.num, 'FM0000') ||'.'|| 'event_desc')::text)
      )
    )
  )
FROM raw_data
CROSS JOIN meta
WHERE raw_data.group_id = 10
UNION ALL
SELECT 'character', 'wcc_witcher_events_benefit_details_o' || to_char(10, 'FM00') || to_char(skill_mapping_group10.num, 'FM00'),
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.' || skill_mapping_group10.skill_path || '.bonus'),
      1
    )
  )
FROM skill_mapping_group10
CROSS JOIN meta
UNION ALL
SELECT 'character', 'wcc_witcher_events_benefit_details_o' || to_char(10, 'FM00') || to_char(skill_mapping_group10.num, 'FM00'),
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.' || skill_mapping_group10.skill_path || '.bonus_if_new'),
      1
    )
  )
FROM skill_mapping_group10
CROSS JOIN meta;

-- Переходы: из базового узла опасностей к уточнениям по нужным вариантам
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  VALUES
    ('wcc_witcher_events_benefit','wcc_witcher_events_benefit_details','wcc_witcher_events_benefit_o01',2),
    ('wcc_witcher_events_benefit','wcc_witcher_events_benefit_details','wcc_witcher_events_benefit_o02',2),
    ('wcc_witcher_events_benefit','wcc_witcher_events_benefit_details','wcc_witcher_events_benefit_o03',2),
    ('wcc_witcher_events_benefit','wcc_witcher_events_benefit_details','wcc_witcher_events_benefit_o05',2),
    ('wcc_witcher_events_benefit','wcc_witcher_events_benefit_details','wcc_witcher_events_benefit_o06',2),
    ('wcc_witcher_events_benefit','wcc_witcher_events_benefit_details','wcc_witcher_events_benefit_o08',2),
    ('wcc_witcher_events_benefit','wcc_witcher_events_benefit_details','wcc_witcher_events_benefit_o10',2)
  ON CONFLICT DO NOTHING;

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_witcher_events_benefit_details', 'wcc_witcher_events_risk', r.ru_id, 1
    FROM (SELECT ru_id FROM rules WHERE name = 'lifeEventsCounter_is_valid') r;