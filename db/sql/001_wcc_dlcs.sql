\echo '001_wcc_dlcs.sql'
-- Узел: Выбор DLC/источников для генерации
WITH raw_data (dlc_id, name_ru, name_en, is_official) AS ( VALUES
    ('core',             'База',                                                'Core',                                             TRUE),
    ('exp_bot',          'EXP-DLC "Книга Сказок"',                              'EXP-DLC "A Book of Tales"',                        TRUE),
    ('exp_lal',          'EXP-DLC "Правители и земли"',                         'EXP-DLC "Lords and Lands"',                        TRUE),
    ('exp_toc',          'EXP-DLC "Том Хаоса"',                                 'EXP-DLC "A Tome of Chaos"',                        TRUE),
    ('exp_wj',           'EXP-DLC "Журнал охотника"',                           'EXP-DLC "A Witcher''s Journal"',                   TRUE),
    ('dlc_rw_rudolf',    'DLC "Фургончик Родольфа: Сам Родольф"',               'DLC "Rodolf’s Wagon: Rodolf himself"',             TRUE),
    ('dlc_rw1',          'DLC "Фургончик Родольфа" - 1 - Полезные вещицы',      'DLC "Rodolf’s Wagon" - 1 - General Gear',          TRUE),
    ('dlc_rw2',          'DLC "Фургончик Родольфа" - 2 - Инструменты',          'DLC "Rodolf’s Wagon" - 2 - A Professionals Tools', TRUE),
    ('dlc_rw3',          'DLC "Фургончик Родольфа" - 3 - Модификации арбалета', 'DLC "Rodolf’s Wagon" - 3 - Crossbow Upgrades',     TRUE),
    ('dlc_rw4',          'DLC "Фургончик Родольфа" - 4 - Обычные элексиры',     'DLC "Rodolf’s Wagon" - 4 - Mundane Potions',       TRUE),
    ('dlc_rw5',          'DLC "Фургончик Родольфа" - 5 - Оружие Туссента',      'DLC "Rodolf’s Wagon" - 5 - Weapons of Toussaint',  TRUE),
    ('dlc_wt',           'DLC "Снаряжение ведьмака"',                           'DLC "A Witcher’s Tools"',                          TRUE),
    ('dlc_sch_manticore','DLC "Школа Мантикоры"',                               'DLC "The Manticore School"',                       TRUE),
    ('dlc_sch_snail',    'DLC "Школа Улитки"',                                  'DLC "The Snail School"',                           TRUE),
    ('dlc_sh_mothr',     'DLC "Справочник Сироль: Монстры на Дороге"',          'DLC "Siriol’s Handbook: Monsters on the Road"',    TRUE),
    ('dlc_sh_tai',       'DLC "Справочник Сироль: Таверны и Гостиницы"',        'DLC "Siriol’s Handbook: Tavens and Inns"',         TRUE),
    ('dlc_sh_tothr',     'DLC "Справочник Сироль: Путники на дороге"',          'DLC "Siriol’s Handbook: Travelers on the Road"',   TRUE),
    ('dlc_sh_wat',       'DLC "Справочник Сироль: Повозки и Путешествие"',      'DLC "Siriol’s Handbook: Wagons and Travel"',       TRUE),
    ('dlc_wpaw',         'DLC "Ведьмачьи протезы и кресла-каталки"',            'DLC "Witcher Prostheses and Wheelchairs"',         TRUE),
    ('dlc_prof_peasant', 'DLC "Крестьянин"',                                    'DLC "The Peasant Profession"',                     TRUE),
    ('hb',               'Фанатский',                                           'Home Brew',                                        FALSE)
),
ins_names AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    SELECT ck_id('witcher_cc.items.dlc.name.'||rd.dlc_id),
           'items',
           'dlc_names',
           'ru',
           rd.name_ru
      FROM raw_data rd
     WHERE nullif(rd.name_ru,'') is not null
    UNION ALL
    SELECT ck_id('witcher_cc.items.dlc.name.'||rd.dlc_id),
           'items',
           'dlc_names',
           'en',
           rd.name_en
      FROM raw_data rd
     WHERE nullif(rd.name_en,'') is not null
  ) foo
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO wcc_dlcs (dlc_id, su_su_id, title, semver, priority, is_official, name_id)
SELECT
  rd.dlc_id,
  'witcher_cc' AS su_su_id,
  rd.name_en   AS title,
  '1.0.0'      AS semver,
  0            AS priority,
  rd.is_official,
  ck_id('witcher_cc.items.dlc.name.'||rd.dlc_id) AS name_id
FROM raw_data rd
ON CONFLICT (dlc_id) DO UPDATE
SET su_su_id = EXCLUDED.su_su_id,
    title = EXCLUDED.title,
    semver = EXCLUDED.semver,
    priority = EXCLUDED.priority,
    is_official = EXCLUDED.is_official,
    name_id = EXCLUDED.name_id;


-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_dlcs' AS qu_id
                , 'questions' AS entity
                , 'multiple'::question_type AS qtype)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| v.entity_field) AS id
           , meta.entity, v.entity_field, v.lang, v.text
        FROM (VALUES
                ('ru', 'Выберите DLC/источники, которые будут доступны при генерации', 'body'),
                ('en', 'Select DLCs/sources that will be available during generation', 'body')
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
       , jsonb_build_object(
           'dice', 'd0',
           'allowEmptySelection', true,
           'path', jsonb_build_array(
             ck_id('witcher_cc.hierarchy.identity')::text,
             ck_id('witcher_cc.hierarchy.dlcs')::text
           )
         )
     FROM meta;

-- Опции: DLC/источники (список из sql/items/002_wcc_dlcs.sql)
WITH raw_data (sort_order, dlc_id, name_ru, name_en) AS ( VALUES
    (1,  'exp_bot',          '[Платное] "Книга Сказок"',                                          '[Paid] "A Book of Tales"',                        TRUE),
    (2,  'exp_lal',          '[Платное] "Правители и земли"',                                     '[Paid] "Lords and Lands"',                        TRUE),
    (3,  'exp_toc',          '[Платное] "Том Хаоса"',                                             '[Paid] "A Tome of Chaos"',                        TRUE),
    (4,  'exp_wj',           '[Платное] "Журнал охотника"',                                       '[Paid] "A Witcher''s Journal"',                   TRUE),
    (5,  'dlc_rw_rudolf',    '[Бепсплатное] DLC "Фургончик Родольфа: Сам Родольф"',               '[Free] DLC "Rodolf’s Wagon: Rodolf himself"',             TRUE),
    (6,  'dlc_rw1',          '[Бепсплатное] DLC "Фургончик Родольфа" - 1 - Полезные вещицы',      '[Free] DLC "Rodolf’s Wagon" - 1 - General Gear',          TRUE),
    (7,  'dlc_rw2',          '[Бепсплатное] DLC "Фургончик Родольфа" - 2 - Инструменты',          '[Free] DLC "Rodolf’s Wagon" - 2 - A Professionals Tools', TRUE),
    (8,  'dlc_rw3',          '[Бепсплатное] DLC "Фургончик Родольфа" - 3 - Модификации арбалета', '[Free] DLC "Rodolf’s Wagon" - 3 - Crossbow Upgrades',     TRUE),
    (9,  'dlc_rw4',          '[Бепсплатное] DLC "Фургончик Родольфа" - 4 - Обычные элексиры',     '[Free] DLC "Rodolf’s Wagon" - 4 - Mundane Potions',       TRUE),
    (10, 'dlc_rw5',          '[Бепсплатное] DLC "Фургончик Родольфа" - 5 - Оружие Туссента',      '[Free] DLC "Rodolf’s Wagon" - 5 - Weapons of Toussaint',  TRUE),
    (11, 'dlc_wt',           '[Бепсплатное] DLC "Снаряжение ведьмака"',                           '[Free] DLC "A Witcher’s Tools"',                          TRUE),
    (12, 'dlc_sh_mothr',     '[Бепсплатное] DLC "Справочник Сироль: Монстры на Дороге"',          '[Free] DLC "Siriol’s Handbook: Monsters on the Road"',    TRUE),
    (13, 'dlc_sh_tai',       '[Бепсплатное] DLC "Справочник Сироль: Таверны и Гостиницы"',        '[Free] DLC "Siriol’s Handbook: Tavens and Inns"',         TRUE),
    (14, 'dlc_sh_tothr',     '[Бепсплатное] DLC "Справочник Сироль: Путники на дороге"',          '[Free] DLC "Siriol’s Handbook: Travelers on the Road"',   TRUE),
    (15, 'dlc_sh_wat',       '[Бепсплатное] DLC "Справочник Сироль: Повозки и Путешествие"',      '[Free] DLC "Siriol’s Handbook: Wagons and Travel"',       TRUE),
    (16, 'dlc_wpaw',         '[Бепсплатное] DLC "Ведьмачьи протезы и кресла-каталки"',            '[Free] DLC "Witcher Prostheses and Wheelchairs"',         TRUE),
    (17, 'dlc_sch_manticore','[Бепсплатное] DLC "Школа Мантикоры"',                               '[Free] DLC "The Manticore School"',                       TRUE),
    (18, 'dlc_sch_snail',    '[Бепсплатное] [1 апреля] DLC "Школа Улитки"',                       '[Free] [1st April] DLC "The Snail School"',                           TRUE),
    (19, 'dlc_prof_peasant', '[Бепсплатное] [1 апреля] DLC "Крестьянин"',                         '[Free] [1st April] DLC "The Peasant Profession"',                     TRUE),
    (20, 'hb',               'Фанатский',                                                         'Home Brew',                                        FALSE)
),
ins_names AS (
  -- same deterministic IDs as in sql/items/002_wcc_dlcs.sql:
  -- ck_id('witcher_cc.items.dlc.name.'||dlc_id)
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    SELECT ck_id('witcher_cc.items.dlc.name.option.'||rd.dlc_id),
           'items',
           'dlc_names',
           'ru',
           rd.name_ru
      FROM raw_data rd
     WHERE nullif(rd.name_ru,'') is not null
    UNION ALL
    SELECT ck_id('witcher_cc.items.dlc.name.option.'||rd.dlc_id),
           'items',
           'dlc_names',
           'en',
           rd.name_en
      FROM raw_data rd
     WHERE nullif(rd.name_en,'') is not null
  ) foo
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO answer_options (an_id, su_su_id, dlc_dlc_id, qu_qu_id, label, sort_order, metadata)
  SELECT 'wcc_dlcs_' || rd.dlc_id AS an_id
       , 'witcher_cc' AS su_su_id
       , 'core' AS dlc_dlc_id
       , 'wcc_dlcs' AS qu_qu_id
       , ck_id('witcher_cc.items.dlc.name.option.'||rd.dlc_id)::text AS label
       , rd.sort_order
       , jsonb_build_object('dlc_id', rd.dlc_id)
    FROM raw_data rd
  ON CONFLICT (an_id) DO NOTHING;

-- Эффекты: сохраняем выбранные dlc_id в state.dlcs (массив строк)
WITH raw_data (dlc_id) AS ( VALUES
    ('dlc_rw_rudolf'),
    ('dlc_rw1'),
    ('dlc_rw2'),
    ('dlc_rw3'),
    ('dlc_rw4'),
    ('dlc_rw5'),
    ('dlc_sch_manticore'),
    ('dlc_sch_snail'),
    ('dlc_sh_mothr'),
    ('dlc_sh_tai'),
    ('dlc_sh_tothr'),
    ('dlc_sh_wat'),
    ('dlc_wt'),
    ('exp_bot'),
    ('exp_lal'),
    ('exp_toc'),
    ('exp_wj'),
    ('hb'),
    ('dlc_prof_peasant'),
    ('dlc_wpaw')
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'state' AS scope,
  'wcc_dlcs_' || rd.dlc_id AS an_an_id,
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','dlcs'),
      rd.dlc_id
    )
  ) AS body
FROM raw_data rd;


