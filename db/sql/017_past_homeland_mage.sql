\echo '017_past_homeland_mage.sql'

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_past_homeland_mage' AS qu_id
         , 'questions' AS entity
         , 'single_table'::question_type AS qtype
  )
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| v.entity_field) AS id
         , meta.entity
         , v.entity_field
         , v.lang
         , v.text
      FROM (VALUES
              ('ru', 'Где вы родились?', 'body'),
              ('en', 'Where were you born?', 'body'),
              ('ru', 'Родина мага', 'title'),
              ('en', 'Mage homeland', 'title'),
              ('ru', 'Шанс', 'col_1'),
              ('en', 'Chance', 'col_1'),
              ('ru', 'Место рождения', 'col_2'),
              ('en', 'Birth Location', 'col_2')
           ) AS v(lang, text, entity_field)
      CROSS JOIN meta
)
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
SELECT meta.qu_id
     , meta.su_su_id
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.title')
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body')
     , meta.qtype
     , jsonb_build_object(
         'dice', 'd_weighed',
         'allowEmptySelection', false,
         'columns', jsonb_build_array(
           ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.col_1')::text,
           ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.col_2')::text
         ),
         'path', jsonb_build_array(
           ck_id('witcher_cc.hierarchy.identity')::text,
           ck_id('witcher_cc.hierarchy.homeland_mage')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO NOTHING;

-- Правила видимости
WITH rule_parts AS (
  SELECT
    (SELECT r.body FROM rules r WHERE r.name = 'is_elf' ORDER BY r.ru_id LIMIT 1) AS is_elf_expr,
    (SELECT r.body FROM rules r WHERE r.name = 'is_gnome' ORDER BY r.ru_id LIMIT 1) AS is_gnome_expr,
    (SELECT r.body FROM rules r WHERE r.name = 'is_vran' ORDER BY r.ru_id LIMIT 1) AS is_vran_expr,
    (SELECT r.body FROM rules r WHERE r.name = 'is_werebbubb' ORDER BY r.ru_id LIMIT 1) AS is_werebbubb_expr
)
, rules_setup AS (
  INSERT INTO rules (ru_id, name, body)
  SELECT
    ck_id('witcher_cc.rules.is_mage_homeland_elder'),
    'is_mage_homeland_elder',
    jsonb_build_object(
      'or',
      jsonb_build_array(
        rule_parts.is_elf_expr,
        rule_parts.is_gnome_expr,
        rule_parts.is_vran_expr,
        rule_parts.is_werebbubb_expr
      )
    )
  FROM rule_parts
  ON CONFLICT (ru_id) DO UPDATE SET body = EXCLUDED.body
  RETURNING ru_id
)
, rules_setup_not AS (
  INSERT INTO rules (ru_id, name, body)
  SELECT
    ck_id('witcher_cc.rules.is_mage_homeland_not_elder'),
    'is_mage_homeland_not_elder',
    jsonb_build_object(
      '!',
      jsonb_build_object(
        'or',
        jsonb_build_array(
          (SELECT r.body FROM rules r WHERE r.name = 'is_elf' ORDER BY r.ru_id LIMIT 1),
          (SELECT r.body FROM rules r WHERE r.name = 'is_gnome' ORDER BY r.ru_id LIMIT 1),
          (SELECT r.body FROM rules r WHERE r.name = 'is_vran' ORDER BY r.ru_id LIMIT 1),
          (SELECT r.body FROM rules r WHERE r.name = 'is_werebbubb' ORDER BY r.ru_id LIMIT 1)
        )
      )
    )
  ON CONFLICT (ru_id) DO UPDATE SET body = EXCLUDED.body
  RETURNING ru_id
)
SELECT 1;

-- Опции ответов
WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_past_homeland_mage' AS qu_id
         , 'answer_options' AS entity
  )
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
            ( 1, 'Северные королевства - Ковир и Повис', 'is_mage_homeland_not_elder', 1.5),
            ( 2, 'Северные королевства - Хенгфорская лига', 'is_mage_homeland_not_elder', 1.5),
            ( 3, 'Северные королевства - Редания', 'is_mage_homeland_not_elder', 1.5),
            ( 4, 'Северные королевства - Каэдвен', 'is_mage_homeland_not_elder', 1.5),
            ( 5, 'Северные королевства - Аэдирн', 'is_mage_homeland_not_elder', 1.0),
            ( 6, 'Северные королевства - Лирия и Ривия', 'is_mage_homeland_not_elder', 1.0),
            ( 7, 'Северные королевства - Темерия', 'is_mage_homeland_not_elder', 1.0),
            ( 8, 'Северные королевства - Цидарис', 'is_mage_homeland_not_elder', 1.0),
            ( 9, 'Северные королевства - Керак', 'is_mage_homeland_not_elder', 1.0),
            (10, 'Северные королевства - Верден', 'is_mage_homeland_not_elder', 1.0),
            (11, 'Скеллиге', 'is_mage_homeland_not_elder', 3.0),
            (12, 'Нильфгаард - Цинтра', 'is_mage_homeland_not_elder', 1.0),
            (13, 'Нильфгаард - Ангрен', 'is_mage_homeland_not_elder', 1.0),
            (14, 'Нильфгаард - Назаир', 'is_mage_homeland_not_elder', 1.0),
            (15, 'Нильфгаард - Меттина', 'is_mage_homeland_not_elder', 1.0),
            (16, 'Нильфгаард - Туссент', 'is_mage_homeland_not_elder', 1.0),
            (17, 'Нильфгаард - Маг Турга', 'is_mage_homeland_not_elder', 1.0),
            (18, 'Нильфгаард - Гесо', 'is_mage_homeland_not_elder', 1.0),
            (19, 'Нильфгаард - Эббинг', 'is_mage_homeland_not_elder', 1.0),
            (20, 'Нильфгаард - Мехт', 'is_mage_homeland_not_elder', 1.0),
            (21, 'Нильфгаард - Этолия', 'is_mage_homeland_not_elder', 1.0),
            (22, 'Нильфгаард - Геммера', 'is_mage_homeland_not_elder', 1.0),
            (23, 'Нильфгаард - Виковаро', 'is_mage_homeland_not_elder', 1.0),
            (24, 'Нильфгаард - Сердце Нильфгаарда', 'is_mage_homeland_not_elder', 3.0),
            (25, 'Доль Блатанна', 'is_mage_homeland_elder', 1.0),
            (26, 'Горный конклав', 'is_mage_homeland_elder', 1.0)
         ) AS raw_data_ru(num, text, rule_name, probability)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
            ( 1, 'The Northern Realms - Kovir & Poviss', 'is_mage_homeland_not_elder', 1.5),
            ( 2, 'The Northern Realms - The Hengfors League', 'is_mage_homeland_not_elder', 1.5),
            ( 3, 'The Northern Realms - Redania', 'is_mage_homeland_not_elder', 1.5),
            ( 4, 'The Northern Realms - Kaedwen', 'is_mage_homeland_not_elder', 1.5),
            ( 5, 'The Northern Realms - Aedirn', 'is_mage_homeland_not_elder', 1.0),
            ( 6, 'The Northern Realms - Lyria & Rivia', 'is_mage_homeland_not_elder', 1.0),
            ( 7, 'The Northern Realms - Temeria', 'is_mage_homeland_not_elder', 1.0),
            ( 8, 'The Northern Realms - Cidaris', 'is_mage_homeland_not_elder', 1.0),
            ( 9, 'The Northern Realms - Kerack', 'is_mage_homeland_not_elder', 1.0),
            (10, 'The Northern Realms - Verden', 'is_mage_homeland_not_elder', 1.0),
            (11, 'Skellige', 'is_mage_homeland_not_elder', 3.0),
            (12, 'Nilfgaard - Cintra', 'is_mage_homeland_not_elder', 1.0),
            (13, 'Nilfgaard - Angren', 'is_mage_homeland_not_elder', 1.0),
            (14, 'Nilfgaard - Nazair', 'is_mage_homeland_not_elder', 1.0),
            (15, 'Nilfgaard - Mettina', 'is_mage_homeland_not_elder', 1.0),
            (16, 'Nilfgaard - Toussaint', 'is_mage_homeland_not_elder', 1.0),
            (17, 'Nilfgaard - Mag Turga', 'is_mage_homeland_not_elder', 1.0),
            (18, 'Nilfgaard - Gheso', 'is_mage_homeland_not_elder', 1.0),
            (19, 'Nilfgaard - Ebbing', 'is_mage_homeland_not_elder', 1.0),
            (20, 'Nilfgaard - Maecht', 'is_mage_homeland_not_elder', 1.0),
            (21, 'Nilfgaard - Etolia', 'is_mage_homeland_not_elder', 1.0),
            (22, 'Nilfgaard - Gemmera', 'is_mage_homeland_not_elder', 1.0),
            (23, 'Nilfgaard - Vicovaro', 'is_mage_homeland_not_elder', 1.0),
            (24, 'Nilfgaard - The Heart of Nilfgaard', 'is_mage_homeland_not_elder', 3.0),
            (25, 'Dol Blathanna', 'is_mage_homeland_elder', 1.0),
            (26, 'Mountain conclave', 'is_mage_homeland_elder', 1.0)
         ) AS raw_data_en(num, text, rule_name, probability)
)
, ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM00') ||'.'|| meta.entity ||'.label') AS id
       , meta.entity
       , 'label'
       , raw_data.lang
       , '<td style="color: grey;">' || to_char(raw_data.probability*100, 'FM990.00') || '%</td><td>' || raw_data.text || '</td>'
    FROM raw_data
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
, ins_lore_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM00') ||'.lore.homeland') AS id
       , 'character'
       , 'homeland'
       , raw_data.lang
       , raw_data.text
    FROM raw_data
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT meta.qu_id || '_o' || to_char(raw_data.num, 'FM00') AS an_id
     , meta.su_su_id
     , meta.qu_id
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM00') ||'.'|| meta.entity ||'.label') AS label
     , raw_data.num AS sort_order
     , (SELECT ru_id FROM rules WHERE name = raw_data.rule_name LIMIT 1) AS visible_ru_ru_id
     , jsonb_build_object(
         'probability', raw_data.probability
       ) AS metadata
  FROM raw_data
  CROSS JOIN meta
 WHERE raw_data.lang = 'ru'
ON CONFLICT (an_id) DO NOTHING;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_past_homeland_mage' AS qu_id
  )
, nums AS (
    SELECT generate_series(1, 26) AS num
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character' AS scope
     , meta.qu_id || '_o' || to_char(nums.num, 'FM00') AS an_an_id
     , jsonb_build_object(
         'set',
         jsonb_build_array(
           jsonb_build_object('var', 'characterRaw.lore.homeland'),
           jsonb_build_object(
             'i18n_uuid',
             ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(nums.num, 'FM00') ||'.lore.homeland')::text
           )
         )
       ) AS body
  FROM nums
 CROSS JOIN meta;

-- Родной язык и языковой бонус зависят от выбранной родины
WITH meta AS (
  SELECT 'witcher_cc' AS su_su_id
       , 'wcc_past_homeland_mage' AS qu_id
       , 'character' AS entity
)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| v.lang_key ||'.'|| meta.entity ||'.home_language')
     , meta.entity
     , 'home_language'
     , v.lang
     , v.text
  FROM (VALUES
    ('common', 'ru', 'Всеобщий'),
    ('common', 'en', 'Common Speech'),
    ('elder_speech', 'ru', 'Старшая речь'),
    ('elder_speech', 'en', 'Elder Speech'),
    ('dwarvish', 'ru', 'Краснолюдский'),
    ('dwarvish', 'en', 'Dwarvish')
  ) AS v(lang_key, lang, text)
 CROSS JOIN meta
ON CONFLICT (id, lang) DO UPDATE
SET text = EXCLUDED.text;

WITH meta AS (
  SELECT 'witcher_cc' AS su_su_id
       , 'wcc_past_homeland_mage' AS qu_id
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_past_homeland_mage_o' || to_char(v.num, 'FM00'),
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.home_language'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| v.lang_key ||'.character.home_language')::text)
    )
  )
FROM (VALUES
  ( 1, 'common'), ( 2, 'common'), ( 3, 'common'), ( 4, 'common'), ( 5, 'common'),
  ( 6, 'common'), ( 7, 'common'), ( 8, 'common'), ( 9, 'common'), (10, 'common'),
  (11, 'common'), (12, 'common'), (13, 'common'), (14, 'common'), (15, 'common'),
  (16, 'common'), (17, 'common'), (18, 'common'), (19, 'common'), (20, 'common'),
  (21, 'common'), (22, 'common'), (23, 'common'), (24, 'common'),
  (25, 'elder_speech'),
  (26, 'dwarvish')
) AS v(num, lang_key)
CROSS JOIN meta
UNION ALL
SELECT 'character', 'wcc_past_homeland_mage_o' || to_char(v.num, 'FM00'),
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.common.' || v.skill_id || '.bonus'),
      8
    )
  )
FROM (VALUES
  ( 1, 'language_common_speech'), ( 2, 'language_common_speech'), ( 3, 'language_common_speech'), ( 4, 'language_common_speech'),
  ( 5, 'language_common_speech'), ( 6, 'language_common_speech'), ( 7, 'language_common_speech'), ( 8, 'language_common_speech'),
  ( 9, 'language_common_speech'), (10, 'language_common_speech'), (11, 'language_common_speech'), (12, 'language_common_speech'),
  (13, 'language_common_speech'), (14, 'language_common_speech'), (15, 'language_common_speech'), (16, 'language_common_speech'),
  (17, 'language_common_speech'), (18, 'language_common_speech'), (19, 'language_common_speech'), (20, 'language_common_speech'),
  (21, 'language_common_speech'), (22, 'language_common_speech'), (23, 'language_common_speech'), (24, 'language_common_speech'),
  (25, 'language_elder_speech'),
  (26, 'language_dwarvish')
) AS v(num, skill_id)
UNION ALL
SELECT 'character', 'wcc_past_homeland_mage_o' || to_char(v.num, 'FM00'),
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.logicFields.home_language'),
      v.logic_value
    )
  )
FROM (VALUES
  ( 1, 'Common Speech'), ( 2, 'Common Speech'), ( 3, 'Common Speech'), ( 4, 'Common Speech'),
  ( 5, 'Common Speech'), ( 6, 'Common Speech'), ( 7, 'Common Speech'), ( 8, 'Common Speech'),
  ( 9, 'Common Speech'), (10, 'Common Speech'), (11, 'Common Speech'), (12, 'Common Speech'),
  (13, 'Common Speech'), (14, 'Common Speech'), (15, 'Common Speech'), (16, 'Common Speech'),
  (17, 'Common Speech'), (18, 'Common Speech'), (19, 'Common Speech'), (20, 'Common Speech'),
  (21, 'Common Speech'), (22, 'Common Speech'), (23, 'Common Speech'), (24, 'Common Speech'),
  (25, 'Elder Speech'),
  (26, 'Dwarvish')
) AS v(num, logic_value);

-- Переход в Родину Мага из возраста персонажа
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
SELECT 'wcc_ch_age', 'wcc_past_homeland_mage', ru_id, 1
  FROM rules
 WHERE ru_id = ck_id('witcher_cc.rules.is_mage_and_exp_toc');

-- Переход из Родины Мага в Семью
-- INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
--   SELECT 'wcc_past_homeland_mage', 'wcc_family';
