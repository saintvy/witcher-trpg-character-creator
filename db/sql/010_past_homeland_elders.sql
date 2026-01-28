\echo '010_past_homeland_elders.sql'
-- Узел: Родина - земли старших народов

-- Вопрос

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_homeland_elders' AS qu_id
                , 'questions' AS entity)
, ins_body AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
                       , meta.entity, 'body', v.lang, v.text
                    FROM (VALUES
                            ('ru', 'Выберете родину вашего персонажа.'),
                            ('en', 'Choose your character''s homeland.')) AS v(lang, text)
                    CROSS JOIN meta)
, c_vals(lang, num, text) AS (VALUES ('ru', 1, 'Шанс'),
                                     ('ru', 3, 'Место'),
                                     ('ru', 4, 'Эффект'),
                                     ('en', 1, 'Chance'),
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
             SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_past_homeland_elders' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
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
                , 'wcc_past_homeland_elders' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
           SELECT ('<td>' || to_char(probability*100, 'FM990.00') || '%</td>' ||
                   '<td>' || place_name || '</td>' ||
                   '<td>' || effect || '</td>') AS text,
                  num,
                  probability,
                  lang
           FROM (VALUES
                  -- RU: Northern Kingdoms (10* по 0.05)
                  ('ru', 1, 'Доль Блатанна','+1 к Образованию', 0.5::numeric),
                  ('ru', 2, 'Махакам','+1 к Стойкости', 0.5),
                  ('en', 1, 'Dol Blathanna','+1 Social Etiquette', 0.5),
                  ('en', 2, 'Mahakam','+1 Crafting', 0.5)
           ) AS v(lang, num, place_name, effect, probability)
)
, ins_label AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
                     , meta.entity, meta.entity_field, vals.lang, vals.text
                  FROM vals
                  CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
  SELECT 'wcc_past_homeland_elders_o' || to_char(vals.num, 'FM9900') AS an_id,
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
                , 'wcc_past_homeland_elders' AS qu_id
                , 'character' AS entity)
-- i18n записи для родин
, ins_homeland_01 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o01' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Доль Блатанна'), ('en', 'Dol Blathanna')) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_homeland_02 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o02' ||'.'|| meta.entity ||'.'|| 'homeland') AS id
         , meta.entity, 'homeland', v.lang, v.text
      FROM (VALUES ('ru', 'Махакам'), ('en', 'Mahakam')) AS v(lang, text)
      CROSS JOIN meta
  )
-- i18n записи для родного языка: Старшая речь для Доль Блатанна
, ins_lang_elder_speech AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elder_speech' ||'.'|| meta.entity ||'.'|| 'home_language') AS id
         , meta.entity, 'home_language', v.lang, v.text
      FROM (VALUES ('ru', 'Старшая речь'), ('en', 'Elder Speech')) AS v(lang, text)
      CROSS JOIN meta
  )
-- i18n записи для родного языка: Дварфийский для Махакам
, ins_lang_dwarvish AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'dwarvish' ||'.'|| meta.entity ||'.'|| 'home_language') AS id
         , meta.entity, 'home_language', v.lang, v.text
      FROM (VALUES ('ru', 'Краснолюдский'), ('en', 'Dwarvish')) AS v(lang, text)
      CROSS JOIN meta
  )
INSERT INTO effects (scope, an_an_id, body)
-- 01: Доль Блатанна - +1 к Образованию (Education)
SELECT 'character', 'wcc_past_homeland_elders_o01',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.education.bonus'), 1
  ))
FROM meta UNION ALL
-- 01: Родина - Доль Блатанна
SELECT 'character', 'wcc_past_homeland_elders_o01',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.homeland'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o01' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
  ))
FROM meta UNION ALL
-- 01: Родной язык - Старшая речь
SELECT 'character', 'wcc_past_homeland_elders_o01',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.home_language'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elder_speech' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
  ))
FROM meta UNION ALL
-- 01: +8 к Старшей речи (language_elder_speech)
SELECT 'character', 'wcc_past_homeland_elders_o01',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.language_elder_speech.bonus'), 8
  ))
FROM meta UNION ALL
-- 02: Махакам - +1 к Стойкости (Endurance)
SELECT 'character', 'wcc_past_homeland_elders_o02',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.endurance.bonus'), 1
  ))
FROM meta UNION ALL
-- 02: Родина - Махакам
SELECT 'character', 'wcc_past_homeland_elders_o02',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.homeland'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o02' ||'.'|| meta.entity ||'.'|| 'homeland')::text)
  ))
FROM meta UNION ALL
-- 02: Родной язык - Краснолюдский
SELECT 'character', 'wcc_past_homeland_elders_o02',
  jsonb_build_object('set', jsonb_build_array(
    jsonb_build_object('var','characterRaw.lore.home_language'),
    jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'dwarvish' ||'.'|| meta.entity ||'.'|| 'home_language')::text)
  ))
FROM meta UNION ALL
-- 02: +8 к Краснолюдскому языку (language_dwarvish)
SELECT 'character', 'wcc_past_homeland_elders_o02',
  jsonb_build_object('inc', jsonb_build_array(
    jsonb_build_object('var','characterRaw.skills.common.language_dwarvish.bonus'), 8
  ))
FROM meta;

-- Дополнительные эффекты: логическое поле родного языка (logicFields.home_language)
WITH meta_lang AS (
  SELECT 'witcher_cc' AS su_su_id,
         'wcc_past_homeland_elders' AS qu_id,
         'character' AS entity
)
INSERT INTO effects (scope, an_an_id, body)
-- 01: Dol Blathanna -> Elder Speech
SELECT 'character', 'wcc_past_homeland_elders_o01',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.logicFields.home_language'),
      'Elder Speech'
    )
  )
FROM meta_lang
UNION ALL
-- 02: Mahakam -> Dwarvish
SELECT 'character', 'wcc_past_homeland_elders_o02',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.logicFields.home_language'),
      'Dwarvish'
    )
  )
FROM meta_lang;

-- Связи  
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id)
  SELECT 'wcc_past_dwarf_q1', 'wcc_past_homeland_elders', 'wcc_past_dwarf_q1_o02' UNION ALL
  SELECT 'wcc_past_elf_q1', 'wcc_past_homeland_elders', 'wcc_past_elf_q1_o02';

    -- Переходы из новой ноды с правилами по расе (без is_witcher, т.к. ведьмак не может быть воином)
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_man_at_arms_combat_skills', 'wcc_past_homeland_human', r.ru_id, 1
    FROM (SELECT ru_id FROM rules WHERE name = 'is_human') r;

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_man_at_arms_combat_skills', 'wcc_past_dwarf_q1', r.ru_id, 1
    FROM (SELECT ru_id FROM rules WHERE name = 'is_dwarf') r;

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_man_at_arms_combat_skills', 'wcc_past_elf_q1', r.ru_id, 1
    FROM (SELECT ru_id FROM rules WHERE name = 'is_elf') r;