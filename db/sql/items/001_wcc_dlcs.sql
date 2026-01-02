CREATE TABLE IF NOT EXISTS wcc_dlcs (
    dlc_id  varchar(64) PRIMARY KEY, -- source_id (core, hb, dlc_*, exp_*)
    name_id uuid NOT NULL            -- ck_id('witcher_cc.items.dlc.name.'||dlc_id)
);

COMMENT ON TABLE wcc_dlcs IS
  'Справочник DLC/источников (core/hb/dlc_*/exp_*). Локализуемое имя хранится как i18n UUID (name_id) и ищется в i18n_text.';

COMMENT ON COLUMN wcc_dlcs.dlc_id IS
  'ID DLC/источника (например core, hb, dlc_rw1, exp_toc). Используется как FK из wcc_item_weapons.dlc_dlc_id.';

COMMENT ON COLUMN wcc_dlcs.name_id IS
  'i18n UUID для названия DLC. Генерируется детерминированно: ck_id(''witcher_cc.items.dlc.name.''||dlc_id).';

WITH raw_data (dlc_id, name_ru, name_en) AS ( VALUES
    ('core',            'База',                                              'Core'),
    ('dlc_rw_rudolf',   'DLC "Фургончик Родольфа: Сам Родольф"',              'DLC "Rodolf’s Wagon: Rodolf himself"'),
    ('dlc_rw1',         'DLC "Фургончик Родольфа" - 1 - Полезные вещицы',     'DLC "Rodolf’s Wagon" - 1 - General Gear'),
    ('dlc_rw2',         'DLC "Фургончик Родольфа" - 2 - Инструменты',         'DLC "Rodolf’s Wagon" - 2 - A Professionals Tools'),
    ('dlc_rw3',         'DLC "Фургончик Родольфа" - 3 - Модификации арбалета', 'DLC "Rodolf’s Wagon" - 3 - Crossbow Upgrades'),
    ('dlc_rw4',         'DLC "Фургончик Родольфа" - 4 - Обычные элексиры',    'DLC "Rodolf’s Wagon" - 4 - Mundane Potions'),
    ('dlc_rw5',         'DLC "Фургончик Родольфа" - 5 - Оружие Туссента',     'DLC "Rodolf’s Wagon" - 5 - Weapons of Toussaint'),
    ('dlc_sch_manticore','DLC "Школа Мантикоры"',                             'DLC "The Manticore School"'),
    ('dlc_sch_snail',   'DLC "Школа Улитки"',                                 'DLC "The Snail School"'),
    ('dlc_sh_mothr',    'DLC "Справочник Сироль: Монстры на Дороге"',         'DLC "Siriol’s Handbook: Monsters on the Road"'),
    ('dlc_sh_tai',      'DLC "Справочник Сироль: Таверны и Гостиницы"',       'DLC "Siriol’s Handbook: Tavens and Inns"'),
    ('dlc_sh_tothr',    'DLC "Справочник Сироль: Путники на дороге"',         'DLC "Siriol’s Handbook: Travelers on the Road"'),
    ('dlc_sh_wat',      'DLC "Справочник Сироль: Повозки и Путешествие"',     'DLC "Siriol’s Handbook: Wagons and Travel"'),
    ('dlc_wt',          'DLC "Снаряжение ведьмака"',                          'DLC "A Witcher’s Tools"'),
    ('exp_bot',         'DLC "Книга Сказок"',                                 'DLC "A Book of Tales"'),
    ('exp_lal',         'DLC "Правители и земли"',                            'DLC "Lords and Lands"'),
    ('exp_toc',         'DLC "Том Хаоса"',                                    'DLC "A Tome of Chaos"'),
    ('exp_wj',          'DLC "Журная охотника"',                              'DLC "A Witcher''s Journal"'),
    ('hb',              'Фанатский',                                          'Home Brew'),
    ('dlc_prof_peasant','DLC "Крестьянин"',                                   'DLC "The Peasant Profession"'),
    ('dlc_wpaw',        'DLC "Ведьмачьи протезы и кресла-каталки"',           'DLC "Witcher Prostheses and Wheelchairs"')
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
INSERT INTO wcc_dlcs (dlc_id, name_id)
SELECT rd.dlc_id,
       ck_id('witcher_cc.items.dlc.name.'||rd.dlc_id) AS name_id
  FROM raw_data rd
ON CONFLICT (dlc_id) DO UPDATE
SET name_id = EXCLUDED.name_id;


