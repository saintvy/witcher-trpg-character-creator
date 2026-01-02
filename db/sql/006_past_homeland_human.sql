\echo '006_past_homeland_human.sql'
-- Узел: Родина - людские поселения

-- Вопрос

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_homeland_human' AS qu_id
                , 'questions' AS entity)
, ins_body AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
                       , meta.entity, 'body', v.lang, v.text
                    FROM (VALUES
                            ('ru', 'Выберете родину вашего персонажа.'),
                            ('en', 'Choose your character''s homeland.')) AS v(lang, text)
                    CROSS JOIN meta)
, c_vals(lang, num, text) AS (VALUES ('ru', 1, 'Шанс'),
                                     ('ru', 2, 'Регион'),
                                     ('ru', 3, 'Место'),
                                     ('ru', 4, 'Эффект'),
                                     ('en', 1, 'Chance'),
                                     ('en', 2, 'Region'),
                                     ('en', 3, 'Place'),
                                     ('en', 4, 'Effect'))
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
           'dice', 'd_weighed',
           'columns', (
             SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_past_homeland_human' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
             FROM (SELECT DISTINCT num FROM c_vals) AS cols
           ),
           'path', jsonb_build_array(
             ck_id('witcher_cc.hierarchy.identity')::text,
             ck_id('witcher_cc.hierarchy.homeland')::text
           )
         )
    FROM meta;

-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_homeland_human' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
           SELECT ('<td>' || to_char(probability*100, 'FM990.00') || '%</td>' ||
                   '<td>' || region || '</td>' ||
                   '<td>' || place_name || '</td>' ||
                   '<td>' || effect || '</td>') AS text,
                  num,
                  probability,
                  lang
           FROM (VALUES
                          -- RU: Northern Kingdoms (10* по 0.05)
                          ('ru', 101, 'Королевства Севера','Редания','+1 к Образованию',               0.05::numeric),
                          ('ru', 102, 'Королевства Севера','Каэдвен','+1 к Стойкости',                  0.05),
                          ('ru', 103, 'Королевства Севера','Темерия','+1 к Харизме',                    0.05),
                          ('ru', 104, 'Королевства Севера','Аэдирн','+1 к Изготовлению',                0.05),
                          ('ru', 105, 'Королевства Севера','Лирия и Ривия','+1 к Сопротивлению убеждению', 0.05),
                          ('ru', 106, 'Королевства Севера','Ковир и Повисс','+1 к Торговле',            0.05),
                          ('ru', 107, 'Королевства Севера','Скеллиге','+1 к Храбрости',                  0.05),
                          ('ru', 108, 'Королевства Севера','Цидарис','+1 к Мореходству',                 0.05),
                          ('ru', 109, 'Королевства Севера','Вердэн','+1 к Выживанию в дикой природе',   0.05),
                          ('ru', 110, 'Королевства Севера','Цинтра','+1 к Пониманию людей',             0.05),
                      
                          -- EN: Northern Kingdoms (10* по 0.05)
                          ('en', 101, 'Northern Kingdoms','Redania','+1 Education',                      0.05),
                          ('en', 102, 'Northern Kingdoms','Kaedwen','+1 Endurance',                      0.05),
                          ('en', 103, 'Northern Kingdoms','Temeria','+1 Charisma',                       0.05),
                          ('en', 104, 'Northern Kingdoms','Aedirn','+1 Crafting',                        0.05),
                          ('en', 105, 'Northern Kingdoms','Lyria & Rivia','+1 Resist Coercion',          0.05),
                          ('en', 106, 'Northern Kingdoms','Kovir & Poviss','+1 Business',                0.05),
                          ('en', 107, 'Northern Kingdoms','Skellige','+1 Courage',                        0.05),
                          ('en', 108, 'Northern Kingdoms','Cidaris','+1 Sailing',                         0.05),
                          ('en', 109, 'Northern Kingdoms','Verden','+1 Wilderness Survival',             0.05),
                          ('en', 110, 'Northern Kingdoms','Cintra','+1 Human Perception',                0.05),
                      
                          -- RU/EN: Nilfgaard core (по 0.15)
                          ('ru', 201, 'Империя Нильфгаард','Сердце Нильфгаарда','+1 к Обману',          0.15),
                          ('en', 201, 'Nilfgaardian Empire','The Heart of Nilfgaard','+1 Deceit',       0.15),
                      
                          -- RU: Nilfgaard vassals (10* по 0.035)
                          ('ru', 301, 'Вассальное государство Нильфгаарда','Виковаро','+1 к Образованию',                 0.035),
                          ('ru', 302, 'Вассальное государство Нильфгаарда','Аигрен','+1 к Выживанию в дикой природе',     0.035),
                          ('ru', 303, 'Вассальное государство Нильфгаарда','Назаир','+1 к Борьбе',                         0.035),
                          ('ru', 304, 'Вассальное государство Нильфгаарда','Метиина','+1 к Верховой езде',                 0.035),
                          ('ru', 305, 'Вассальное государство Нильфгаарда','Маг Турга','+1 к Стойкости',                   0.035),
                          ('ru', 306, 'Вассальное государство Нильфгаарда','Гесо','+1 к Скрытности',                       0.035),
                          ('ru', 307, 'Вассальное государство Нильфгаарда','Эббинг','+1 к Дедукции',                       0.035),
                          ('ru', 308, 'Вассальное государство Нильфгаарда','Мехт','+1 к Харизме',                          0.035),
                          ('ru', 309, 'Вассальное государство Нильфгаарда','Геммера','+1 к Запугиванию',                   0.035),
                          ('ru', 310, 'Вассальное государство Нильфгаарда','Этолия','+1 к Храбрости',                      0.035),
                      
                          -- EN: Nilfgaard vassals (10* по 0.035)
                          ('en', 301, 'Nilfgaardian Vassal State','Vicovaro','+1 Education',             0.035),
                          ('en', 302, 'Nilfgaardian Vassal State','Angren','+1 Wilderness Survival',     0.035),
                          ('en', 303, 'Nilfgaardian Vassal State','Nazair','+1 Brawling',                0.035),
                          ('en', 304, 'Nilfgaardian Vassal State','Mettina','+1 Ride',                   0.035),
                          ('en', 305, 'Nilfgaardian Vassal State','Mag Turga','+1 Endurance',            0.035),
                          ('en', 306, 'Nilfgaardian Vassal State','Gheso','+1 Stealth',                  0.035),
                          ('en', 307, 'Nilfgaardian Vassal State','Ebbing','+1 Deduction',               0.035),
                          ('en', 308, 'Nilfgaardian Vassal State','Maecht','+1 Charisma',                0.035),
                          ('en', 309, 'Nilfgaardian Vassal State','Gemmeria','+1 Intimidation',          0.035),
                          ('en', 310, 'Nilfgaardian Vassal State','Etolia','+1 Courage',                 0.035)
           ) AS v(lang, num, region, place_name, effect, probability)
)
, ins_label AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
                     , meta.entity, meta.entity_field, vals.lang, vals.text
                  FROM vals
                  CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
  SELECT 'wcc_past_homeland_human_o' || to_char(vals.num, 'FM0000') AS an_id,
         meta.su_su_id,
         meta.qu_id,
         ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
         vals.num AS sort_order,
         jsonb_build_object(
           'probability', vals.probability
         ) AS metadata
    FROM vals
    CROSS JOIN meta
  ON CONFLICT (an_id) DO NOTHING;

-- Эффекты для всех вариантов ответов
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_homeland_human' AS qu_id
                , 'character' AS entity)
-- i18n записи для родин
, ins_homeland_101 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0101' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Редания'), ('en', 'Redania')) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_homeland_102 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0102' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Каэдвен'), ('en', 'Kaedwen')) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_homeland_103 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0103' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Темерия'), ('en', 'Temeria')) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_homeland_104 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0104' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Аэдирн'), ('en', 'Aedirn')) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_homeland_105 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0105' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Лирия и Ривия'), ('en', 'Lyria & Rivia')) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_homeland_106 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0106' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Ковир и Повисс'), ('en', 'Kovir & Poviss')) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_homeland_107 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0107' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Скеллиге'), ('en', 'Skellige')) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_homeland_108 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0108' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Цидарис'), ('en', 'Cidaris')) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_homeland_109 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0109' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Вердэн'), ('en', 'Verden')) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_homeland_110 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0110' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Цинтра'), ('en', 'Cintra')) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_homeland_201 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0201' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Сердце Нильфгаарда'), ('en', 'The Heart of Nilfgaard')) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_homeland_301 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0301' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Виковаро'), ('en', 'Vicovaro')) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_homeland_302 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0302' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Аигрен'), ('en', 'Angren')) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_homeland_303 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0303' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Назаир'), ('en', 'Nazair')) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_homeland_304 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0304' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Метиина'), ('en', 'Mettina')) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_homeland_305 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0305' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Маг Турга'), ('en', 'Mag Turga')) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_homeland_306 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0306' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Гесо'), ('en', 'Gheso')) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_homeland_307 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0307' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Эббинг'), ('en', 'Ebbing')) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_homeland_308 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0308' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Мехт'), ('en', 'Maecht')) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_homeland_309 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0309' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Геммера'), ('en', 'Gemmeria')) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_homeland_310 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0310' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Этолия'), ('en', 'Etolia')) AS v(lang, text)
      CROSS JOIN meta
  )
-- i18n записи для родного языка: Всеобщий (Northern) для 101-106, 108-110
, ins_lang_northern AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'northern' ||'.'|| meta.entity ||'.'|| 'home_language') AS id
         , meta.entity, 'home_language', v.lang, v.text
      FROM (VALUES ('ru', 'Всеобщий'), ('en', 'Northern')) AS v(lang, text)
      CROSS JOIN meta
  )
-- i18n записи для родного языка: Старшая речь (Elder Speech) для 107, 201, 301-310
, ins_lang_elder_speech AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elder_speech' ||'.'|| meta.entity ||'.'|| 'home_language') AS id
         , meta.entity, 'home_language', v.lang, v.text
      FROM (VALUES ('ru', 'Старшая речь'), ('en', 'Elder Speech')) AS v(lang, text)
      CROSS JOIN meta
  )
INSERT INTO effects (scope, an_an_id, body)
-- 101: Редания - +1 к Образованию (Education)
SELECT 'character', 'wcc_past_homeland_human_o0101',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.education.bonus'),
      1
    )
  )
FROM meta UNION ALL
-- 101: Родина - Редания
SELECT 'character', 'wcc_past_homeland_human_o0101',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.lore.homeland'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0101' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
    )
  )
FROM meta UNION ALL
-- 101: Родной язык - Всеобщий
SELECT 'character', 'wcc_past_homeland_human_o0101',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.lore.home_language'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'northern' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
    )
  )
FROM meta UNION ALL
-- 101: +8 к Всеобщему языку (language_northern)
SELECT 'character', 'wcc_past_homeland_human_o0101',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.language_northern.bonus'),
      8
    )
  )
FROM meta UNION ALL
-- 102: Каэдвен - +1 к Стойкости (Endurance)
SELECT 'character', 'wcc_past_homeland_human_o0102',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.endurance.bonus'),
      1
    )
  )
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0102',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.homeland'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0102' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0102',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.home_language'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'northern' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0102',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.language_northern.bonus'),
    8
  ))
FROM meta UNION ALL
-- 103: Темерия - +1 к Харизме (Charisma)
SELECT 'character', 'wcc_past_homeland_human_o0103',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.charisma.bonus'), 1
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0103',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.homeland'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0103' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0103',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.home_language'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'northern' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0103',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.language_northern.bonus'), 8
  ))
FROM meta UNION ALL
-- 104: Аэдирн - +1 к Изготовлению (Crafting)
SELECT 'character', 'wcc_past_homeland_human_o0104',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.crafting.bonus'), 1
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0104',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.homeland'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0104' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0104',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.home_language'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'northern' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0104',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.language_northern.bonus'), 8
  ))
FROM meta UNION ALL
-- 105: Лирия и Ривия - +1 к Сопротивлению убеждению (Resist Coercion)
SELECT 'character', 'wcc_past_homeland_human_o0105',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.resist_coercion.bonus'), 1
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0105',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.homeland'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0105' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0105',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.home_language'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'northern' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0105',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.language_northern.bonus'), 8
  ))
FROM meta UNION ALL
-- 106: Ковир и Повисс - +1 к Торговле (Business)
SELECT 'character', 'wcc_past_homeland_human_o0106',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.business.bonus'), 1
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0106',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.homeland'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0106' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0106',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.home_language'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'northern' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0106',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.language_northern.bonus'), 8
  ))
FROM meta UNION ALL
-- 107: Скеллиге - +1 к Храбрости (Courage)
SELECT 'character', 'wcc_past_homeland_human_o0107',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.courage.bonus'), 1
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0107',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.homeland'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0107' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0107',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.home_language'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elder_speech' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0107',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.language_elder_speech.bonus'), 8
  ))
FROM meta UNION ALL
-- 108: Цидарис - +1 к Мореходству (Sailing)
SELECT 'character', 'wcc_past_homeland_human_o0108',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.sailing.bonus'), 1
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0108',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.homeland'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0108' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0108',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.home_language'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'northern' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0108',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.language_northern.bonus'), 8
  ))
FROM meta UNION ALL
-- 109: Вердэн - +1 к Выживанию в дикой природе (Wilderness Survival)
SELECT 'character', 'wcc_past_homeland_human_o0109',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.wilderness_survival.bonus'), 1
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0109',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.homeland'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0109' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0109',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.home_language'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'northern' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0109',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.language_northern.bonus'), 8
  ))
FROM meta UNION ALL
-- 110: Цинтра - +1 к Пониманию людей (Human Perception)
SELECT 'character', 'wcc_past_homeland_human_o0110',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.human_perception.bonus'), 1
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0110',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.homeland'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0110' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0110',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.home_language'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'northern' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0110',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.language_northern.bonus'), 8
  ))
FROM meta UNION ALL
-- 201: Сердце Нильфгаарда - +1 к Обману (Deceit)
SELECT 'character', 'wcc_past_homeland_human_o0201',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.deceit.bonus'), 1
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0201',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.homeland'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0201' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0201',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.home_language'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elder_speech' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0201',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.language_elder_speech.bonus'), 8
  ))
FROM meta UNION ALL
-- 301: Виковаро - +1 к Образованию (Education)
SELECT 'character', 'wcc_past_homeland_human_o0301',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.education.bonus'), 1
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0301',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.homeland'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0301' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0301',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.home_language'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elder_speech' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0301',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.language_elder_speech.bonus'), 8
  ))
FROM meta UNION ALL
-- 302: Аигрен - +1 к Выживанию в дикой природе (Wilderness Survival)
SELECT 'character', 'wcc_past_homeland_human_o0302',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.wilderness_survival.bonus'), 1
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0302',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.homeland'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0302' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0302',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.home_language'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elder_speech' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0302',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.language_elder_speech.bonus'), 8
  ))
FROM meta UNION ALL
-- 303: Назаир - +1 к Борьбе (Brawling)
SELECT 'character', 'wcc_past_homeland_human_o0303',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.brawling.bonus'), 1
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0303',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.homeland'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0303' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0303',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.home_language'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elder_speech' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0303',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.language_elder_speech.bonus'), 8
  ))
FROM meta UNION ALL
-- 304: Метиина - +1 к Верховой езде (Riding)
SELECT 'character', 'wcc_past_homeland_human_o0304',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.riding.bonus'), 1
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0304',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.homeland'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0304' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0304',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.home_language'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elder_speech' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0304',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.language_elder_speech.bonus'), 8
  ))
FROM meta UNION ALL
-- 305: Маг Турга - +1 к Стойкости (Endurance)
SELECT 'character', 'wcc_past_homeland_human_o0305',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.endurance.bonus'), 1
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0305',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.homeland'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0305' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0305',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.home_language'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elder_speech' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0305',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.language_elder_speech.bonus'), 8
  ))
FROM meta UNION ALL
-- 306: Гесо - +1 к Скрытности (Stealth)
SELECT 'character', 'wcc_past_homeland_human_o0306',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.stealth.bonus'), 1
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0306',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.homeland'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0306' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0306',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.home_language'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elder_speech' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0306',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.language_elder_speech.bonus'), 8
  ))
FROM meta UNION ALL
-- 307: Эббинг - +1 к Дедукции (Deduction)
SELECT 'character', 'wcc_past_homeland_human_o0307',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.deduction.bonus'), 1
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0307',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.homeland'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0307' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0307',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.home_language'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elder_speech' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0307',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.language_elder_speech.bonus'), 8
  ))
FROM meta UNION ALL
-- 308: Мехт - +1 к Харизме (Charisma)
SELECT 'character', 'wcc_past_homeland_human_o0308',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.charisma.bonus'), 1
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0308',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.homeland'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0308' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0308',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.home_language'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elder_speech' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0308',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.language_elder_speech.bonus'), 8
  ))
FROM meta UNION ALL
-- 309: Геммера - +1 к Запугиванию (Intimidation)
SELECT 'character', 'wcc_past_homeland_human_o0309',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.intimidation.bonus'), 1
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0309',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.homeland'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0309' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0309',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.home_language'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elder_speech' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0309',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.language_elder_speech.bonus'), 8
  ))
FROM meta UNION ALL
-- 310: Этолия - +1 к Храбрости (Courage)
SELECT 'character', 'wcc_past_homeland_human_o0310',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.courage.bonus'), 1
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0310',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.homeland'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o0310' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0310',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.home_language'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elder_speech' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
  ))
FROM meta UNION ALL
SELECT 'character', 'wcc_past_homeland_human_o0310',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.language_elder_speech.bonus'), 8
  ))
FROM meta;
  
-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id)
  SELECT 'wcc_race', 'wcc_past_homeland_human', 'wcc_race_human' UNION ALL
  SELECT 'wcc_past_witcher_q1', 'wcc_past_homeland_human', 'wcc_past_witcher_q1_o02' UNION ALL
  SELECT 'wcc_past_dwarf_q1', 'wcc_past_homeland_human', 'wcc_past_dwarf_q1_o03' UNION ALL
  SELECT 'wcc_past_elf_q1', 'wcc_past_homeland_human', 'wcc_past_elf_q1_o03';