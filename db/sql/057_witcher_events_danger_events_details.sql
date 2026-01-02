\echo '057_witcher_events_danger_events_details.sql'

-- Вопрос: уточнения к опасностям ведьмака
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_danger_events_details' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id,entity,entity_field,lang,text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru','Раскройте подробности выбранной опасности.'),
        ('en','Pick the specific outcome for your danger.')
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
           SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_witcher_events_danger_events_details' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
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
           ck_id('witcher_cc.hierarchy.witcher_events_danger')::text,
           ck_id('witcher_cc.hierarchy.witcher_events_danger_events_details')::text
         )
       )
  FROM meta;

-- Ответы (RU/EN)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_danger_events_details' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
  FROM (VALUES
    -- 1. Долг
    ( 1, 1, 0.1, '<b>Долг</b>: 100 крон'),
    ( 1, 2, 0.1, '<b>Долг</b>: 200 крон'),
    ( 1, 3, 0.1, '<b>Долг</b>: 300 крон'),
    ( 1, 4, 0.1, '<b>Долг</b>: 400 крон'),
    ( 1, 5, 0.1, '<b>Долг</b>: 500 крон'),
    ( 1, 6, 0.1, '<b>Долг</b>: 600 крон'),
    ( 1, 7, 0.1, '<b>Долг</b>: 700 крон'),
    ( 1, 8, 0.1, '<b>Долг</b>: 800 крон'),
    ( 1, 9, 0.1, '<b>Долг</b>: 900 крон'),
    ( 1,10, 0.1, '<b>Долг</b>: 1000 крон'),

    -- 3. Зависимость
    ( 3, 1, 0.125, '<b>Зависимость</b>: Алкоголь'),
    ( 3, 2, 0.125, '<b>Зависимость</b>: Табак'),
    ( 3, 3, 0.125, '<b>Зависимость</b>: Фисштех'),
    ( 3, 4, 0.125, '<b>Зависимость</b>: Азартные игры'),
    ( 3, 5, 0.125, '<b>Зависимость</b>: Клептомания'),
    ( 3, 6, 0.125, '<b>Зависимость</b>: Похоть'),
    ( 3, 7, 0.125, '<b>Зависимость</b>: Обжорство'),
    ( 3, 8, 0.125, '<b>Зависимость</b>: Адреналиновая зависимость'),
    ( 3, 10, 0.0, '<b>Зависимость</b>: Другое (можете придумать сами)'),

    -- 4. Заключение
    ( 4, 1, 0.1, '<b>Заключение</b>: 1 год'),
    ( 4, 2, 0.1, '<b>Заключение</b>: 2 года'),
    ( 4, 3, 0.1, '<b>Заключение</b>: 3 года'),
    ( 4, 4, 0.1, '<b>Заключение</b>: 4 года'),
    ( 4, 5, 0.1, '<b>Заключение</b>: 5 лет'),
    ( 4, 6, 0.1, '<b>Заключение</b>: 6 лет'),
    ( 4, 7, 0.1, '<b>Заключение</b>: 7 лет'),
    ( 4, 8, 0.1, '<b>Заключение</b>: 8 лет'),
    ( 4, 9, 0.1, '<b>Заключение</b>: 9 лет'),
    ( 4,10, 0.1, '<b>Заключение</b>: 10 лет'),

    -- 5. Ложное обвинение (1–3; 4–5; 6–8; 9; 10)
    ( 5, 1, 0.30, '<b>Ложное обвинение</b>: кража'),
    ( 5, 2, 0.20, '<b>Ложное обвинение</b>: предательство или трусость'),
    ( 5, 3, 0.30, '<b>Ложное обвинение</b>: убийство'),
    ( 5, 4, 0.10, '<b>Ложное обвинение</b>: изнасилование'),
    ( 5, 5, 0.10, '<b>Ложное обвинение</b>: незаконное колдовство'),

    -- 6. Предательство (1–3; 4–7; 8–10)
    ( 6, 1, 0.30, '<b>Предательство</b>: шантаж'),
    ( 6, 2, 0.40, '<b>Предательство</b>: раскрыта ваша тайна'),
    ( 6, 3, 0.30, '<b>Предательство</b>: на вас напали'),

    -- 7. Убит друг или любимый (1–3; 4–6; 7–8; 9–10)
    ( 7, 1, 0.30, '<b>Убит друг или любимый</b>: погиб от чудовища'),
    ( 7, 2, 0.30, '<b>Убит друг или любимый</b>: казнён'),
    ( 7, 3, 0.20, '<b>Убит друг или любимый</b>: жертва убийцы'),
    ( 7, 4, 0.20, '<b>Убит друг или любимый</b>: отравлен'),

    -- 8. Вне закона в королевстве - список королевств
    ( 8, 1, 0.041, '<b>Вне закона</b>: Редания'),
    ( 8, 2, 0.041, '<b>Вне закона</b>: Каэдвен'),
    ( 8, 3, 0.041, '<b>Вне закона</b>: Темерия'),
    ( 8, 4, 0.041, '<b>Вне закона</b>: Аэдирн'),
    ( 8, 5, 0.041, '<b>Вне закона</b>: Лирия'),
    ( 8, 6, 0.041, '<b>Вне закона</b>: Ривия'),
    ( 8, 7, 0.041, '<b>Вне закона</b>: Ковир'),
    ( 8, 8, 0.041, '<b>Вне закона</b>: Повис'),
    ( 8, 9, 0.041, '<b>Вне закона</b>: Скеллиге'),
    ( 8,10, 0.041, '<b>Вне закона</b>: Цидарис'),
    ( 8,11, 0.041, '<b>Вне закона</b>: Вердэн'),
    ( 8,12, 0.041, '<b>Вне закона</b>: Цинтра'),
    ( 8,13, 0.041, '<b>Вне закона</b>: Сердце Нильфгаарда'),
    ( 8,14, 0.041, '<b>Вне закона</b>: Вассальное государство Нильфгаарда - Виковаро'),
    ( 8,15, 0.041, '<b>Вне закона</b>: Вассальное государство Нильфгаарда - Аигрен'),
    ( 8,16, 0.041, '<b>Вне закона</b>: Вассальное государство Нильфгаарда - Назаир'),
    ( 8,17, 0.041, '<b>Вне закона</b>: Вассальное государство Нильфгаарда - Метиина'),
    ( 8,18, 0.041, '<b>Вне закона</b>: Вассальное государство Нильфгаарда - Маг Турга'),
    ( 8,19, 0.041, '<b>Вне закона</b>: Вассальное государство Нильфгаарда - Гесо'),
    ( 8,20, 0.041, '<b>Вне закона</b>: Вассальное государство Нильфгаарда - Эббинг'),
    ( 8,21, 0.041, '<b>Вне закона</b>: Вассальное государство Нильфгаарда - Мехт'),
    ( 8,22, 0.041, '<b>Вне закона</b>: Вассальное государство Нильфгаарда - Геммера'),
    ( 8,23, 0.041, '<b>Вне закона</b>: Вассальное государство Нильфгаарда - Этолия'),
    ( 8,24, 0.041, '<b>Вне закона</b>: Вассальное государство Нильфгаарда - Туссент'),

    -- 10. Проклят - варианты проклятий
    (10, 1, 0.2, '<b>Проклят</b>: Проклятие чудовищности'),
    (10, 2, 0.2, '<b>Проклят</b>: Проклятие призраков'),
    (10, 3, 0.2, '<b>Проклят</b>: Проклятие заразы'),
    (10, 4, 0.2, '<b>Проклят</b>: Проклятие странника'),
    (10, 5, 0.2, '<b>Проклят</b>: Проклятие ликантропии'),
    (10, 6, 0.0, '<b>Проклят</b>: Другое (можете придумать сами)')
  ) AS raw_data_ru(group_id, num, probability, txt)

  UNION ALL

  SELECT 'en' AS lang, raw_data_en.*
  FROM (VALUES

      -- 1. Debt
    ( 1, 1, 0.1, '<b>Debt</b>: 100 crowns'),
    ( 1, 2, 0.1, '<b>Debt</b>: 200 crowns'),
    ( 1, 3, 0.1, '<b>Debt</b>: 300 crowns'),
    ( 1, 4, 0.1, '<b>Debt</b>: 400 crowns'),
    ( 1, 5, 0.1, '<b>Debt</b>: 500 crowns'),
    ( 1, 6, 0.1, '<b>Debt</b>: 600 crowns'),
    ( 1, 7, 0.1, '<b>Debt</b>: 700 crowns'),
    ( 1, 8, 0.1, '<b>Debt</b>: 800 crowns'),
    ( 1, 9, 0.1, '<b>Debt</b>: 900 crowns'),
    ( 1,10, 0.1, '<b>Debt</b>: 1,000 crowns'),

    -- 3. Addiction
    ( 3, 1, 0.125, '<b>Addiction</b>: Alcohol'),
    ( 3, 2, 0.125, '<b>Addiction</b>: Tobacco'),
    ( 3, 3, 0.125, '<b>Addiction</b>: Fisstech'),
    ( 3, 4, 0.125, '<b>Addiction</b>: Gambling'),
    ( 3, 5, 0.125, '<b>Addiction</b>: Kleptomania'),
    ( 3, 6, 0.125, '<b>Addiction</b>: Lust'),
    ( 3, 7, 0.125, '<b>Addiction</b>: Gluttony'),
    ( 3, 8, 0.125, '<b>Addiction</b>: Adrenaline addiction'),
    ( 3,10, 0.0, '<b>Addiction</b>: Other (create your own)'),

    -- 4. Imprisonment
    ( 4, 1, 0.1, '<b>Imprisonment</b>: 1 year'),
    ( 4, 2, 0.1, '<b>Imprisonment</b>: 2 years'),
    ( 4, 3, 0.1, '<b>Imprisonment</b>: 3 years'),
    ( 4, 4, 0.1, '<b>Imprisonment</b>: 4 years'),
    ( 4, 5, 0.1, '<b>Imprisonment</b>: 5 years'),
    ( 4, 6, 0.1, '<b>Imprisonment</b>: 6 years'),
    ( 4, 7, 0.1, '<b>Imprisonment</b>: 7 years'),
    ( 4, 8, 0.1, '<b>Imprisonment</b>: 8 years'),
    ( 4, 9, 0.1, '<b>Imprisonment</b>: 9 years'),
    ( 4,10, 0.1, '<b>Imprisonment</b>: 10 years'),

    -- 5. Falsely Accused (1–3; 4–5; 6–8; 9; 10)
    ( 5, 1, 0.30, '<b>Falsely Accused</b>: theft'),
    ( 5, 2, 0.20, '<b>Falsely Accused</b>: betrayal or cowardice'),
    ( 5, 3, 0.30, '<b>Falsely Accused</b>: murder'),
    ( 5, 4, 0.10, '<b>Falsely Accused</b>: rape'),
    ( 5, 5, 0.10, '<b>Falsely Accused</b>: illegal witchcraft'),

    -- 6. Betrayed (1–3; 4–7; 8–10)
    ( 6, 1, 0.30, '<b>Betrayed</b>: blackmailed'),
    ( 6, 2, 0.40, '<b>Betrayed</b>: a secret was exposed'),
    ( 6, 3, 0.30, '<b>Betrayed</b>: you were attacked'),

    -- 7. Friend or Lover Killed (1–3; 4–6; 7–8; 9–10)
    ( 7, 1, 0.30, '<b>Friend or Lover Killed</b>: slain by a monster'),
    ( 7, 2, 0.30, '<b>Friend or Lover Killed</b>: executed'),
    ( 7, 3, 0.20, '<b>Friend or Lover Killed</b>: murdered'),
    ( 7, 4, 0.20, '<b>Friend or Lover Killed</b>: poisoned'),

    -- 8. Outlawed in a Kingdom - list of kingdoms
    ( 8, 1, 0.041, '<b>Outlawed</b>: Redania'),
    ( 8, 2, 0.041, '<b>Outlawed</b>: Kaedwen'),
    ( 8, 3, 0.041, '<b>Outlawed</b>: Temeria'),
    ( 8, 4, 0.041, '<b>Outlawed</b>: Aedirn'),
    ( 8, 5, 0.041, '<b>Outlawed</b>: Lyria'),
    ( 8, 6, 0.041, '<b>Outlawed</b>: Rivia'),
    ( 8, 7, 0.041, '<b>Outlawed</b>: Kovir'),
    ( 8, 8, 0.041, '<b>Outlawed</b>: Poviss'),
    ( 8, 9, 0.041, '<b>Outlawed</b>: Skellige'),
    ( 8,10, 0.041, '<b>Outlawed</b>: Cidaris'),
    ( 8,11, 0.041, '<b>Outlawed</b>: Verden'),
    ( 8,12, 0.041, '<b>Outlawed</b>: Cintra'),
    ( 8,13, 0.041, '<b>Outlawed</b>: The Heart of Nilfgaard'),
    ( 8,14, 0.041, '<b>Outlawed</b>: Nilfgaardian Vassal State - Vicovaro'),
    ( 8,15, 0.041, '<b>Outlawed</b>: Nilfgaardian Vassal State - Angren'),
    ( 8,16, 0.041, '<b>Outlawed</b>: Nilfgaardian Vassal State - Nazair'),
    ( 8,17, 0.041, '<b>Outlawed</b>: Nilfgaardian Vassal State - Mettina'),
    ( 8,18, 0.041, '<b>Outlawed</b>: Nilfgaardian Vassal State - Mag Turga'),
    ( 8,19, 0.041, '<b>Outlawed</b>: Nilfgaardian Vassal State - Gheso'),
    ( 8,20, 0.041, '<b>Outlawed</b>: Nilfgaardian Vassal State - Ebbing'),
    ( 8,21, 0.041, '<b>Outlawed</b>: Nilfgaardian Vassal State - Maecht'),
    ( 8,22, 0.041, '<b>Outlawed</b>: Nilfgaardian Vassal State - Gemmeria'),
    ( 8,23, 0.041, '<b>Outlawed</b>: Nilfgaardian Vassal State - Etolia'),
    ( 8,24, 0.041, '<b>Outlawed</b>: Nilfgaardian Vassal State - Toussaint'),

    -- 10. Cursed - curse options
    (10, 1, 0.2, '<b>Cursed</b>: Curse of Monstrosity'),
    (10, 2, 0.2, '<b>Cursed</b>: Curse of Phantoms'),
    (10, 3, 0.2, '<b>Cursed</b>: Curse of Pestilence'),
    (10, 4, 0.2, '<b>Cursed</b>: Curse of the Wanderer'),
    (10, 5, 0.2, '<b>Cursed</b>: Curse of Lycanthropy'),
    (10, 6, 0.0, '<b>Cursed</b>: Other (create your own)')
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
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*vals.group_id+vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
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
                         "wcc_witcher_events_danger_events"
                       ]
                   },
                   { "in":
                       [
                         "wcc_witcher_events_danger_events_o' || to_char(v.group_id, 'FM00') || '" ,
                         { "var": "answers.lastAnswer.answerIds" }
                       ]
                   }
                 ]
             }')::jsonb FROM (SELECT DISTINCT group_id FROM raw_data) v(group_id)
),
ins_rules AS (
  INSERT INTO rules(ru_id, body) SELECT r.id, r.body FROM rules_vals r
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, visible_ru_ru_id, sort_order,metadata)
SELECT
  'wcc_witcher_events_danger_events_details_o'||to_char(vals.group_id,'FM00')||to_char(vals.num,'FM00'),
  meta.su_su_id,
  meta.qu_id,
  ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*vals.group_id+vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
  r.id,
  vals.num,
  jsonb_build_object(
           'probability', vals.probability
  )
FROM vals
CROSS JOIN meta
JOIN rules_vals r ON vals.group_id = r.group_id
ON CONFLICT (an_id) DO NOTHING;

-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_witcher_events_danger_events_details', 'wcc_life_events_fortune_or_not_details_addiction', 'wcc_witcher_events_danger_events_details_o0310', 1;
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_witcher_events_danger_events_details', 'wcc_life_events_fortune_or_not_details_curse', 'wcc_witcher_events_danger_events_details_o1006', 1;


INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  VALUES
    ('wcc_witcher_events_danger_events','wcc_witcher_events_danger_events_details','wcc_witcher_events_danger_events_o01',1),
    ('wcc_witcher_events_danger_events','wcc_witcher_events_danger_events_details','wcc_witcher_events_danger_events_o03',1),
    ('wcc_witcher_events_danger_events','wcc_witcher_events_danger_events_details','wcc_witcher_events_danger_events_o04',1),
    ('wcc_witcher_events_danger_events','wcc_witcher_events_danger_events_details','wcc_witcher_events_danger_events_o05',1),
    ('wcc_witcher_events_danger_events','wcc_witcher_events_danger_events_details','wcc_witcher_events_danger_events_o06',1),
    ('wcc_witcher_events_danger_events','wcc_witcher_events_danger_events_details','wcc_witcher_events_danger_events_o07',1),
    ('wcc_witcher_events_danger_events','wcc_witcher_events_danger_events_details','wcc_witcher_events_danger_events_o08',1),
    ('wcc_witcher_events_danger_events','wcc_witcher_events_danger_events_details','wcc_witcher_events_danger_events_o10',1);

-- i18n для event_type "Неудача" / "Misfortune"
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

-- i18n для event_desc (краткие описания для lifeEvents)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_danger_events_details' AS qu_id
                , 'character' AS entity)
, desc_vals AS (
  SELECT v.*
  FROM (VALUES
    -- Группа 1: Долг
    ('ru', 1, 1, 'Долг 100 крон'),
    ('ru', 1, 2, 'Долг 200 крон'),
    ('ru', 1, 3, 'Долг 300 крон'),
    ('ru', 1, 4, 'Долг 400 крон'),
    ('ru', 1, 5, 'Долг 500 крон'),
    ('ru', 1, 6, 'Долг 600 крон'),
    ('ru', 1, 7, 'Долг 700 крон'),
    ('ru', 1, 8, 'Долг 800 крон'),
    ('ru', 1, 9, 'Долг 900 крон'),
    ('ru', 1, 10, 'Долг 1000 крон'),
    
    -- Группа 3: Зависимость (кроме варианта 10, который ведет в детализацию)
    ('ru', 3, 1, 'Зависимость - Алкоголь'),
    ('ru', 3, 2, 'Зависимость - Табак'),
    ('ru', 3, 3, 'Зависимость - Фисштех'),
    ('ru', 3, 4, 'Зависимость - Азартные игры'),
    ('ru', 3, 5, 'Зависимость - Клептомания'),
    ('ru', 3, 6, 'Зависимость - Похоть'),
    ('ru', 3, 7, 'Зависимость - Обжорство'),
    ('ru', 3, 8, 'Зависимость - Адреналиновая зависимость'),
    
    -- Группа 4: Заключение
    ('ru', 4, 1, 'Заключение в тюрьме на 1 год'),
    ('ru', 4, 2, 'Заключение в тюрьме на 2 года'),
    ('ru', 4, 3, 'Заключение в тюрьме на 3 года'),
    ('ru', 4, 4, 'Заключение в тюрьме на 4 года'),
    ('ru', 4, 5, 'Заключение в тюрьме на 5 лет'),
    ('ru', 4, 6, 'Заключение в тюрьме на 6 лет'),
    ('ru', 4, 7, 'Заключение в тюрьме на 7 лет'),
    ('ru', 4, 8, 'Заключение в тюрьме на 8 лет'),
    ('ru', 4, 9, 'Заключение в тюрьме на 9 лет'),
    ('ru', 4, 10, 'Заключение в тюрьме на 10 лет'),
    
    -- Группа 5: Ложное обвинение
    ('ru', 5, 1, 'Ложное обвинение в краже'),
    ('ru', 5, 2, 'Ложное обвинение в предательстве'),
    ('ru', 5, 3, 'Ложное обвинение в убийстве'),
    ('ru', 5, 4, 'Ложное обвинение в изнасиловании'),
    ('ru', 5, 5, 'Ложное обвинение в колдовстве'),
    
    -- Группа 6: Предательство
    ('ru', 6, 1, 'Предательство - шантаж'),
    ('ru', 6, 2, 'Предательство - раскрыта тайна'),
    ('ru', 6, 3, 'Предательство - нападение'),
    
    -- Группа 7: Убит друг или любимый
    ('ru', 7, 1, 'Убит близкий - погиб от чудовища'),
    ('ru', 7, 2, 'Убит близкий - казнён'),
    ('ru', 7, 3, 'Убит близкий - жертва убийцы'),
    ('ru', 7, 4, 'Убит близкий - отравлен'),
    
    -- EN translations
    ('en', 1, 1, 'Debt 100 crowns'),
    ('en', 1, 2, 'Debt 200 crowns'),
    ('en', 1, 3, 'Debt 300 crowns'),
    ('en', 1, 4, 'Debt 400 crowns'),
    ('en', 1, 5, 'Debt 500 crowns'),
    ('en', 1, 6, 'Debt 600 crowns'),
    ('en', 1, 7, 'Debt 700 crowns'),
    ('en', 1, 8, 'Debt 800 crowns'),
    ('en', 1, 9, 'Debt 900 crowns'),
    ('en', 1, 10, 'Debt 1,000 crowns'),
    
    ('en', 3, 1, 'Addiction - Alcohol'),
    ('en', 3, 2, 'Addiction - Tobacco'),
    ('en', 3, 3, 'Addiction - Fisstech'),
    ('en', 3, 4, 'Addiction - Gambling'),
    ('en', 3, 5, 'Addiction - Kleptomania'),
    ('en', 3, 6, 'Addiction - Lust'),
    ('en', 3, 7, 'Addiction - Gluttony'),
    ('en', 3, 8, 'Addiction - Adrenaline'),
    
    ('en', 4, 1, 'Imprisonment for 1 year'),
    ('en', 4, 2, 'Imprisonment for 2 years'),
    ('en', 4, 3, 'Imprisonment for 3 years'),
    ('en', 4, 4, 'Imprisonment for 4 years'),
    ('en', 4, 5, 'Imprisonment for 5 years'),
    ('en', 4, 6, 'Imprisonment for 6 years'),
    ('en', 4, 7, 'Imprisonment for 7 years'),
    ('en', 4, 8, 'Imprisonment for 8 years'),
    ('en', 4, 9, 'Imprisonment for 9 years'),
    ('en', 4, 10, 'Imprisonment for 10 years'),
    
    ('en', 5, 1, 'Falsely accused of theft'),
    ('en', 5, 2, 'Falsely accused of betrayal'),
    ('en', 5, 3, 'Falsely accused of murder'),
    ('en', 5, 4, 'Falsely accused of rape'),
    ('en', 5, 5, 'Falsely accused of witchcraft'),
    
    ('en', 6, 1, 'Betrayed - blackmailed'),
    ('en', 6, 2, 'Betrayed - secret exposed'),
    ('en', 6, 3, 'Betrayed - attacked'),
    
    ('en', 7, 1, 'Friend/lover killed by monster'),
    ('en', 7, 2, 'Friend/lover executed'),
    ('en', 7, 3, 'Friend/lover murdered'),
    ('en', 7, 4, 'Friend/lover poisoned'),
    
    -- Группа 8: Вне закона в королевстве
    ('ru', 8, 1, 'Вне закона в Редании, вас разыскивает стража'),
    ('ru', 8, 2, 'Вне закона в Каэдвене, вас разыскивает стража'),
    ('ru', 8, 3, 'Вне закона в Темерии, вас разыскивает стража'),
    ('ru', 8, 4, 'Вне закона в Аэдирне, вас разыскивает стража'),
    ('ru', 8, 5, 'Вне закона в Лирии, вас разыскивает стража'),
    ('ru', 8, 6, 'Вне закона в Ривии, вас разыскивает стража'),
    ('ru', 8, 7, 'Вне закона в Ковире, вас разыскивает стража'),
    ('ru', 8, 8, 'Вне закона в Повиссе, вас разыскивает стража'),
    ('ru', 8, 9, 'Вне закона в Скеллиге, вас разыскивает стража'),
    ('ru', 8, 10, 'Вне закона в Цидарисе, вас разыскивает стража'),
    ('ru', 8, 11, 'Вне закона в Вердэне, вас разыскивает стража'),
    ('ru', 8, 12, 'Вне закона в Цинтре, вас разыскивает стража'),
    ('ru', 8, 13, 'Вне закона в Сердце Нильфгаарда, вас разыскивает стража'),
    ('ru', 8, 14, 'Вне закона в Виковаро, вас разыскивает стража'),
    ('ru', 8, 15, 'Вне закона в Аигрене, вас разыскивает стража'),
    ('ru', 8, 16, 'Вне закона в Назаире, вас разыскивает стража'),
    ('ru', 8, 17, 'Вне закона в Метиине, вас разыскивает стража'),
    ('ru', 8, 18, 'Вне закона в Маг Турге, вас разыскивает стража'),
    ('ru', 8, 19, 'Вне закона в Гесо, вас разыскивает стража'),
    ('ru', 8, 20, 'Вне закона в Эббинге, вас разыскивает стража'),
    ('ru', 8, 21, 'Вне закона в Мехте, вас разыскивает стража'),
    ('ru', 8, 22, 'Вне закона в Геммерии, вас разыскивает стража'),
    ('ru', 8, 23, 'Вне закона в Этолии, вас разыскивает стража'),
    ('ru', 8, 24, 'Вне закона в Туссенте, вас разыскивает стража'),
    
    -- Группа 10: Проклятие (кроме варианта 6, который ведет в детализацию)
    ('ru', 10, 1, 'Проклятие чудовищности (Интенсивность: Средняя)'),
    ('ru', 10, 2, 'Проклятие призраков (Интенсивность: Средняя)'),
    ('ru', 10, 3, 'Проклятие заразы (Интенсивность: Высокая)'),
    ('ru', 10, 4, 'Проклятие странника (Интенсивность: Высокая)'),
    ('ru', 10, 5, 'Проклятие ликантропии (Интенсивность: Высокая)'),
    
    -- EN translations для групп 8 и 10
    ('en', 8, 1, 'Outlawed in Redania, you are wanted by the Guard'),
    ('en', 8, 2, 'Outlawed in Kaedwen, you are wanted by the Guard'),
    ('en', 8, 3, 'Outlawed in Temeria, you are wanted by the Guard'),
    ('en', 8, 4, 'Outlawed in Aedirn, you are wanted by the Guard'),
    ('en', 8, 5, 'Outlawed in Lyria, you are wanted by the Guard'),
    ('en', 8, 6, 'Outlawed in Rivia, you are wanted by the Guard'),
    ('en', 8, 7, 'Outlawed in Kovir, you are wanted by the Guard'),
    ('en', 8, 8, 'Outlawed in Poviss, you are wanted by the Guard'),
    ('en', 8, 9, 'Outlawed in Skellige, you are wanted by the Guard'),
    ('en', 8, 10, 'Outlawed in Cidaris, you are wanted by the Guard'),
    ('en', 8, 11, 'Outlawed in Verden, you are wanted by the Guard'),
    ('en', 8, 12, 'Outlawed in Cintra, you are wanted by the Guard'),
    ('en', 8, 13, 'Outlawed in The Heart of Nilfgaard, you are wanted by the Guard'),
    ('en', 8, 14, 'Outlawed in Vicovaro, you are wanted by the Guard'),
    ('en', 8, 15, 'Outlawed in Angren, you are wanted by the Guard'),
    ('en', 8, 16, 'Outlawed in Nazair, you are wanted by the Guard'),
    ('en', 8, 17, 'Outlawed in Mettina, you are wanted by the Guard'),
    ('en', 8, 18, 'Outlawed in Mag Turga, you are wanted by the Guard'),
    ('en', 8, 19, 'Outlawed in Gheso, you are wanted by the Guard'),
    ('en', 8, 20, 'Outlawed in Ebbing, you are wanted by the Guard'),
    ('en', 8, 21, 'Outlawed in Maecht, you are wanted by the Guard'),
    ('en', 8, 22, 'Outlawed in Gemmeria, you are wanted by the Guard'),
    ('en', 8, 23, 'Outlawed in Etolia, you are wanted by the Guard'),
    ('en', 8, 24, 'Outlawed in Toussaint, you are wanted by the Guard'),
    
    ('en', 10, 1, 'Curse of Monstrosity (Intensity: Moderate)'),
    ('en', 10, 2, 'Curse of Phantoms (Intensity: Moderate)'),
    ('en', 10, 3, 'Curse of Pestilence (Intensity: High)'),
    ('en', 10, 4, 'Curse of the Wanderer (Intensity: High)'),
    ('en', 10, 5, 'Curse of Lycanthropy (Intensity: High)')
  ) AS v(lang, group_id, num, text)
)
, ins_desc AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*desc_vals.group_id+desc_vals.num, 'FM0000') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', desc_vals.lang, desc_vals.text
      FROM desc_vals
      CROSS JOIN meta
)
-- Эффекты: добавление в lifeEvents для всех детализированных вариантов
-- Исключаем вариант 3-10 (зависимость "Другое"), который ведет в детализацию
INSERT INTO effects (scope, an_an_id, body)
SELECT DISTINCT
  'character', 'wcc_witcher_events_danger_events_details_o' || to_char(desc_vals.group_id, 'FM00') || to_char(desc_vals.num, 'FM00'),
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
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'event_type_misfortune')::text),
        'description',
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*desc_vals.group_id+desc_vals.num, 'FM0000') ||'.'|| 'event_desc')::text)
      )
    )
  )
FROM desc_vals
CROSS JOIN meta
WHERE NOT (desc_vals.group_id = 3 AND desc_vals.num = 10)   -- Исключаем вариант "Другое" для зависимости
  AND NOT (desc_vals.group_id = 10 AND desc_vals.num = 6);  -- Исключаем вариант "Другое" для проклятия
























