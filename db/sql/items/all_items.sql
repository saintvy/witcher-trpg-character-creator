-- ============================================================================
-- Automatically combined file from all SQL scripts in items folder
-- Generated: 2025-12-17 13:59:36
-- File count: 7
-- ============================================================================


-- ============================================================================
-- File: 000_drop_all_tables.sql
-- ============================================================================

-- ============================================================================
-- Automatically generated DROP IF EXISTS commands for all tables
-- Generated: 2025-12-17 11:47:01
-- Table count: 6
-- ============================================================================
-- WARNING: This file will delete all tables from items folder!
-- Use with caution.
-- ============================================================================

DROP TABLE IF EXISTS wcc_item_weapons_to_effects CASCADE;
DROP TABLE IF EXISTS wcc_item_weapons CASCADE;
DROP TABLE IF EXISTS wcc_item_classes CASCADE;
DROP TABLE IF EXISTS wcc_item_effects CASCADE;
DROP TABLE IF EXISTS wcc_item_effect_conditions CASCADE;
DROP TABLE IF EXISTS wcc_dlcs CASCADE;



-- ============================================================================
-- File: 001_wcc_dlcs.sql
-- ============================================================================

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





-- ============================================================================
-- File: 002_wcc_item_weapon_types.sql
-- ============================================================================

CREATE TABLE IF NOT EXISTS wcc_item_classes (
    ic_id   varchar(64) PRIMARY KEY, -- e.g. 'wt_sword'
    -- Детерминированный UUID через ck_id(...):
    -- основание = 'witcher_cc.items.weapon_type.name.' || ic_id
    -- (стабильный текстовый ключ → стабильный UUID, удобно для i18n и миграций)
    name_id uuid NOT NULL            -- ck_id('witcher_cc.items.weapon_type.name.'||ic_id)
);

COMMENT ON TABLE wcc_item_classes IS
  'Справочник типов оружия (wt_*). Локализуемое имя хранится как i18n UUID (name_id) и ищется в i18n_text.';

COMMENT ON COLUMN wcc_item_classes.ic_id IS
  'ID типа оружия (например wt_sword). Используется как FK из wcc_item_weapons.ic_ic_id.';

COMMENT ON COLUMN wcc_item_classes.name_id IS
  'i18n UUID для названия типа. Генерируется детерминированно: ck_id(''witcher_cc.items.weapon_type.name.''||ic_id).';

WITH raw_data (ic_id, name_ru, name_en) AS ( VALUES
    ('wt_crossbow', 'Арбалеты',      'Crossbow'),
    ('wt_ammo',     'Боеприпасы',    'Ammunition'),
    ('wt_bomb',     'Бомба',         'Bomb'),
    ('wt_pole',     'Древковое',     'Pole Arms'),
    ('wt_bludgeon', 'Дробящее',      'Bludgeon'),
    ('wt_tool',     'Инструменты',   'Tool'),
    ('wt_sblade',   'Легкие клинки', 'Small Blade'),
    ('wt_trap',     'Ловушки',       'Trap'),
    ('wt_bow',      'Лук',           'Bow'),
    ('wt_thrown',   'Метательное',   'Thrown Weapon'),
    ('wt_sword',    'Меч',           'Sword'),
    ('wt_staff',    'Посох',         'Staff'),
    ('wt_axe',      'Топор',         'Axe')
),
ins_names AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    SELECT ck_id('witcher_cc.items.weapon_type.name.'||rd.ic_id),
           'items',
           'weapon_type_names',
           'ru',
           rd.name_ru
      FROM raw_data rd
     WHERE nullif(rd.name_ru,'') is not null
    UNION ALL
    SELECT ck_id('witcher_cc.items.weapon_type.name.'||rd.ic_id),
           'items',
           'weapon_type_names',
           'en',
           rd.name_en
      FROM raw_data rd
     WHERE nullif(rd.name_en,'') is not null
  ) foo
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO wcc_item_classes (ic_id, name_id)
SELECT rd.ic_id,
       ck_id('witcher_cc.items.weapon_type.name.'||rd.ic_id) AS name_id
  FROM raw_data rd
ON CONFLICT (ic_id) DO UPDATE
SET name_id = EXCLUDED.name_id;




-- ============================================================================
-- File: 003_wcc_item_weapons.sql
-- ============================================================================

CREATE TABLE IF NOT EXISTS wcc_item_weapons (
    w_id            varchar(10) PRIMARY KEY,          -- e.g. 'W001'
    dlc_dlc_id      varchar(64) NOT NULL REFERENCES wcc_dlcs(dlc_id), -- source_id (core, hb, dlc_*, exp_*)
    ic_ic_id        varchar(64) NOT NULL REFERENCES wcc_item_classes(ic_id), -- class_id (wt_crossbow, wt_sword, ...)

    name_id         uuid NOT NULL,                    -- ck_id('witcher_cc.items.weapon.name.'||w_id)

    is_piercing     boolean NOT NULL DEFAULT false,
    is_slashing     boolean NOT NULL DEFAULT false,
    is_bludgeoning  boolean NOT NULL DEFAULT false,
    is_elemental    boolean NOT NULL DEFAULT false,

    accuracy        integer NOT NULL,                 -- can be negative
    crafted_by      varchar(64) NULL,                 -- humans / non-humans / witchers / etc.
    availability    varchar(8)  NULL,                 -- E/C/R/P/U etc. (as-is)
    dmg             varchar(32) NULL,                 -- e.g. '4d6+3' (kept as text)

    damage_dices    integer NULL,
    damage_modifier integer NULL,

    reliability     integer NOT NULL,
    hands           integer NULL,

    range           varchar(32) NULL,                 -- e.g. '100' or 'Тел*4' (as text)
    concealment     varchar(8)  NULL,                 -- S/M/L/XL etc.
    enhancements    integer NOT NULL DEFAULT 0,

    weight           numeric(12,3) NULL,               -- stored after REPLACE(',', '.')
    price           numeric(12,3) NULL,               -- stored after REPLACE(',', '.')

    description_id  uuid NOT NULL                     -- ck_id('witcher_cc.items.weapon.description.'||w_id)
);

COMMENT ON TABLE wcc_item_weapons IS
  'Оружие/боеприпасы/бомбы и т.п. Ссылается на типы оружия (wcc_item_classes) и хранит локализуемые поля как i18n UUID.';

COMMENT ON COLUMN wcc_item_weapons.dlc_dlc_id IS
  'FK на wcc_dlcs.dlc_id (источник/пакет: core/hb/dlc_*/exp_*).';

COMMENT ON COLUMN wcc_item_weapons.ic_ic_id IS
  'FK на wcc_item_classes.ic_id (тип оружия: wt_*).';

COMMENT ON COLUMN wcc_item_weapons.name_id IS
  'i18n UUID для названия оружия. Генерируется детерминированно: ck_id(''witcher_cc.items.weapon.name.''||w_id).';

COMMENT ON COLUMN wcc_item_weapons.description_id IS
  'i18n UUID для описания оружия. Генерируется детерминированно: ck_id(''witcher_cc.items.weapon.description.''||w_id).';

WITH raw_data (w_id, source_id, class_id, name_ru, name_en, is_piercing, is_slashing, is_bludgeoning, is_elemental, accuracy, crafted_by, availability, dmg, damage_dices, damage_modifier, reliability, hands, range, concealment, enhancements, weight, price, description_ru) AS ( VALUES
    ('W001', 'core', 'wt_crossbow', 'Арбалет', 'Crossbow', 'TRUE', NULL, NULL, NULL, 1, 'humans', 'E', '4d6+3', 4, 3, 5, 2, '100', 'XL', 1, '3', '455', 'Крепкий, точный, мощный. Да, я предвзято говорю, но арбалет я обожаю. На перезарядку требуется время, это да, но хороший стрелок нашпигует противника болтами с точностью, которая большинству человеческих лучников и не снилась. Ложе можно к плечу приложить, чтобы вдоль него прицелиться, - так выстрел точнее будет. Я с таким арбалетом прошёл всю Вторую войну - добрую он сослужил мне службу.'),
    ('W002', 'core', 'wt_crossbow', 'Арбалет охотника на чудовищ', 'Monster Hunter’s Crossbow', 'TRUE', NULL, NULL, NULL, 1, 'humans', 'R', '6d6', 6, NULL, 15, 2, '200', 'XL', 1, '4', '1125', 'В наши дни чудовищ не так уж много. Я, пожалуй, могу пересчитать встреченных тварей по пальцам одной руки. Но всё же чудовища раз от раза вылезают, а поскольку ведьмаков тоже совсем мало соталось, какой-то сукин сын с юга придумал вот такую игрушку. Больше метра длиной, столько же в плечах. Говорят, что арбалет этот надо воротом взводить, а выстрел у него силой в 136 килограмм. Решили, видать, что раз уж для убийства чудовища надо нехило так приложить силушки, чего б не сделать, курва, ручную баллисту, чтобы издалека их отстреливать.'),
    ('W003', 'hb', 'wt_crossbow', 'Арбалет школы Волка', 'Wolven Crossbow', 'TRUE', NULL, NULL, NULL, 1, 'witchers', 'R', '2d6+2', 2, 2, 5, 1, '50', 'L', 1, '0,5', NULL, ''),
    ('W004', 'dlc_wt', 'wt_crossbow', 'Арбалет школы Грифона', 'Griffin Crossbow', 'TRUE', NULL, NULL, NULL, 1, 'witchers', 'R', '2d6+2', 2, 2, 5, 1, '50', 'L', 1, '0,5', NULL, ''),
    ('W005', 'hb', 'wt_crossbow', 'Арбалет школы Змеи', 'Serpentine Crossbow', 'TRUE', NULL, NULL, NULL, 1, 'witchers', 'R', '2d6+2', 2, 2, 5, 1, '50', 'L', 1, '0,5', NULL, ''),
    ('W006', 'dlc_wt', 'wt_crossbow', 'Арбалет школы Кота', 'Feline Crossbow', 'TRUE', NULL, NULL, NULL, 1, 'witchers', 'R', '2d6+2', 2, 2, 5, 1, '50', 'L', 1, '0,5', NULL, ''),
    ('W007', 'hb', 'wt_crossbow', 'Арбалет школы Мантикоры', 'Manticore Crossbow', 'TRUE', NULL, NULL, NULL, 1, 'witchers', 'R', '2d6+2', 2, 2, 5, 1, '50', 'L', 1, '0,5', NULL, ''),
    ('W008', 'dlc_wt', 'wt_crossbow', 'Арбалет школы Медведя', 'Ursine Crossbow', 'TRUE', NULL, NULL, NULL, 1, 'witchers', 'R', '4d6+2', 4, 2, 5, 1, '50', 'L', 1, '0,5', NULL, ''),
    ('W009', 'core', 'wt_crossbow', 'Гномий ручной арбалет', 'Gnomish Hand Crossbow', 'TRUE', NULL, NULL, NULL, 3, 'non-humans', 'R', '2d6', 2, NULL, 10, 1, '100', 'M', 1, '1', '425', 'Не особо люблю ручные арбалеты, но вот такое оружие гномей работы мне нравится. Настоящее произведение искусства: тонкая работа по металлу да чёрное травлёное дерево с изящной резьбой.'),
    ('W010', 'core', 'wt_crossbow', 'Краснолюдский тяжёлый арбалет', 'Dwarven Heavy Crossbow', 'TRUE', NULL, NULL, NULL, 3, 'non-humans', 'R', '5d6', 5, NULL, 15, 2, '300', 'XL', 2, '3,5', '850', 'Мы, краснолюды, будем посильнее людей. Может, мы и ниже, чем люди и эльфы, но уж точно крепче. Краснолюдский арбалет создан как раз с учётом нашей силушки - когда мы их продаём людям и эльфам, приходится ещё и рычаг им впаривать, чтобы натянуть могли.'),
    ('W011', 'exp_bot', 'wt_crossbow', 'Охотничий арбалет', 'Huntsman’s Crossbow', 'TRUE', NULL, NULL, NULL, 2, 'humans', 'C', '5d6', 5, 0, 10, 2, '150', 'L', 1, '3', '600', ''),
    ('W012', 'core', 'wt_crossbow', 'Ручной арбалет', 'Hand Crossbow', 'TRUE', NULL, NULL, NULL, 1, 'humans', 'E', '2d6+2', 2, 2, 5, 1, '50', 'L', 1, '0,5', '285', 'Не знаю точно, где они впервые появились. Думается мне, изначально это оружие было для гражданских. Думается мне, изначально это оружие было для гражданских. Такой арбалетик небольшой, заметно слабее обычного, зато держать его можно одной рукой, да и стреляешь из такого поточнее. В наши дни их используют для защиты родной хаты: немногие могут себе позволить учиться боевому делу, а чтобы стрелять из арбалета, много ума не надо.'),
    ('W013', 'dlc_rw2', 'wt_crossbow', 'Скорпио', 'Scorpio', 'TRUE', NULL, NULL, NULL, 0, 'humans', 'R', '10d6', 10, 0, 20, 2, '200', 'XL', 0, '40', '2500', ''),
    ('W014', 'core', 'wt_crossbow', 'Красная Смерть', 'Red Death', 'TRUE', NULL, NULL, NULL, 2, 'humans', 'U', '10d6', 10, NULL, 15, 2, '300', 'XL', 3, '2,5', NULL, ''),
    ('W015', 'core', 'wt_ammo', 'Бронебойные', 'Bodkin Arrow', 'TRUE', NULL, NULL, NULL, 0, 'humans', 'C', NULL, NULL, NULL, 10, NULL, NULL, 'S', NULL, '0,1', '15', 'Боеприпасы с затупленным или широким наконечником хороши, если у твоего противника брони нет. Проблема в том, что большинству ума хватает хотя бы самую плохонькую броньку-то надеть, так что приходится изрядно постараться, чтобы их достать. Вот для таких ситуаций и нужны бронебойные наконечники - длинные, узкие, закалённые в огне. Прекрасно пробивают как кожу, так и сталь.'),
    ('W016', 'core', 'wt_ammo', 'Взрывные', 'Explosive Arrow', NULL, NULL, NULL, 'TRUE', 0, 'humans', 'R', '4d6', 4, NULL, 1, NULL, NULL, 'S', NULL, '0,1', '108', 'К взырвному боеприпасу прикреплена скляночка с бахающей химозой. При столкновениий склянка лопается да как жахнет по всем частям тела любого в радиусе пары метров!'),
    ('W017', 'core', 'wt_ammo', 'Выслеживающие', 'Tracking Arrow', 'TRUE', NULL, NULL, NULL, 0, 'humans', 'R', NULL, NULL, NULL, 1, NULL, NULL, 'S', NULL, '0,1', '22', 'Вонючей дрянью они измазаны. Советую хранить в чехольчике. Зато коль засадишь в кого, то без усилий выследишь след с твоим то нюхом! Ну по крайней мере в первые пол суток.'),
    ('W018', 'hb', 'wt_ammo', 'Гавенкарские разбрызгивающие', 'HavenKar Bloom Arrow', 'TRUE', NULL, NULL, NULL, 0, 'humans', 'R', '+3', NULL, 3, 5, NULL, NULL, 'S', NULL, '0,1', '130', ''),
    ('W019', 'core', 'wt_ammo', 'Краснолюдские пробивные', 'Dwarven Impact Arrow', NULL, NULL, 'TRUE', NULL, 0, 'non-humans', 'R', NULL, NULL, NULL, 15, NULL, NULL, 'S', NULL, '0,1', '50', 'По слухам, мы стали пользоваться такими стрелами и болтами, чтобы ломать камни в копях, но ныне краснолюбским наёмникам эти наконечники служат для того, чтобы пробивать латные доспехи.'),
    ('W020', 'core', 'wt_ammo', 'Разделяющиеся', 'Split Arrow', 'TRUE', NULL, NULL, NULL, 0, 'humans', 'R', NULL, NULL, NULL, 1, NULL, NULL, 'S', NULL, '0,3', '54', 'Убойная вещь, прям уважаю. Эдакая связка боеприпасов, связанная едва держащимся хлыстиком. После выстрела он лопается и вот в тебя летят уж три снаряда по цене одного! {devider} За каждый пункт свыше защиты цели (до 3-х) вы наносите полный урон в случайную часть тела.'),
    ('W021', 'core', 'wt_ammo', 'С затупленным наконечником', 'Blunt Arrow', NULL, NULL, 'TRUE', NULL, 0, 'humans', 'C', NULL, NULL, NULL, 10, NULL, NULL, 'S', NULL, '0,1', '5', 'Стрелы  и болты с затупленным наконечником - штучки любопытные. Сам я такими никогда не пользовался. Да и не сражался толком с теми, кого широкий наконечник не возьмет. У таких боеприпасов здоровенный деревянный наконечник, похожий на кулак. Говорят, даже если таким в полнатяга стрелять, можно издалека вырубить противника.'),
    ('W022', 'core', 'wt_ammo', 'С широким наконечником', 'Broadhead Arrow', 'TRUE', NULL, NULL, NULL, 0, 'humans', 'C', NULL, NULL, NULL, 10, NULL, NULL, 'S', NULL, '0,1', '10', 'Боеприпасы с широким наконечником - одни из лучших. Они во многом похожи на стандартные стрелы и болты, только наконечник у них широкий, плоский и заострённый по краям. Форма и размер разными бывают: есть листья, ромбики, в форме буквы V, но все они всаживаются куда глубже обычных стрел, оставляя кровоточащие раны.'),
    ('W023', 'hb', 'wt_ammo', 'Серебряные', 'Silver Arrow', 'TRUE', NULL, NULL, NULL, 0, 'humans', 'P', NULL, NULL, NULL, 10, NULL, NULL, 'S', NULL, '0,1', '16', ''),
    ('W024', 'core', 'wt_ammo', 'Стандартные (х10)', 'Standard Arrows (x10)', 'TRUE', NULL, NULL, NULL, 0, 'humans', 'E', NULL, NULL, NULL, 10, NULL, NULL, 'S', NULL, '0,5', '10', 'Если есть стрелковое оружие, нужны и боеприпасы. Стандартнвые боеприпасы - стрелы да болты. Вторые обычно меньше первых, но и у тех, и у других, есть оперение и острый мталлический наконечник.'),
    ('W025', 'core', 'wt_ammo', 'Эльфские ввинчивающиеся', 'Elven Burrower Arrow', 'TRUE', NULL, NULL, NULL, 0, 'non-humans', 'R', NULL, NULL, NULL, 10, NULL, NULL, 'S', NULL, '0,1', '50', 'Скоя''таэли пару лет назад приобрели их у человеческих торговцев и стали активно использовать. Наконечник по форме напоминает винт, из-за чего снаряд буквально ввинчивается в плоть, и вытащить его становится тяжеловато.'),
    ('W026', 'dlc_rw2', 'wt_ammo', 'Бронебойный болт', 'Piercing Scorpio Bolt (x5)', 'TRUE', NULL, NULL, NULL, 0, 'humans', 'R', NULL, NULL, NULL, 10, NULL, NULL, 'M', NULL, '2', '75', ''),
    ('W027', 'dlc_rw2', 'wt_ammo', 'Разрушающий болт', 'Breaker Scorpio Bolt (x5)', NULL, NULL, 'TRUE', NULL, 0, 'humans', 'R', NULL, NULL, NULL, 10, NULL, NULL, 'M', NULL, '2', '75', ''),
    ('W028', 'dlc_rw2', 'wt_ammo', 'Стандартный болт', 'Standard Scorpio Bolt (x5)', 'TRUE', NULL, NULL, NULL, 0, 'humans', 'R', NULL, NULL, NULL, 10, NULL, NULL, 'M', NULL, '2', '50', ''),
    ('W029', 'core', 'wt_bomb', 'Двимеритовая бомба', 'Dimeritium Bomb', NULL, NULL, NULL, 'TRUE', 0, 'humans', 'P', NULL, NULL, NULL, 8, 1, 'Тел*4', 'S', 0, '1', '264', ''),
    ('W030', 'core', 'wt_bomb', 'Картечь', 'Grapeshot', 'TRUE', NULL, NULL, NULL, 0, 'humans', 'P', '7d6', 7, NULL, 4, 1, 'Тел*4', 'S', 0, '1', '159', ''),
    ('W031', 'core', 'wt_bomb', 'Лунная пыль', 'Moon Dust', NULL, NULL, NULL, 'TRUE', 0, 'humans', 'P', NULL, NULL, NULL, 8, 1, 'Тел*4', 'S', 0, '1', '199', ''),
    ('W032', 'core', 'wt_bomb', 'Самум', 'Samum', NULL, NULL, 'TRUE', NULL, 0, 'humans', 'P', NULL, NULL, NULL, 4, 1, 'Тел*4', 'S', 0, '1', '147', ''),
    ('W033', 'core', 'wt_bomb', 'Северный ветер', 'Northern Wind', NULL, NULL, NULL, 'TRUE', 0, 'humans', 'P', NULL, NULL, NULL, 4, 1, 'Тел*4', 'S', 0, '1', '177', ''),
    ('W034', 'dlc_rw2', 'wt_bomb', 'Солнце Зеррикании', 'Zerrikanian Sun', NULL, NULL, NULL, NULL, 0, 'humans', 'P', NULL, NULL, NULL, 4, 1, 'Тел*4', 'S', 0, '1', '120', ''),
    ('W035', 'core', 'wt_bomb', 'Сон дракона', 'Dragon’s Dream', NULL, NULL, NULL, 'TRUE', 0, 'humans', 'P', NULL, NULL, NULL, 8, 1, 'Тел*4', 'S', 0, '1', '177', ''),
    ('W036', 'core', 'wt_bomb', 'Танцующая звезда', 'Dancing Star', NULL, NULL, NULL, 'TRUE', 0, 'humans', 'P', '5d6', 5, NULL, 4, 1, 'Тел*4', 'S', 0, '1', '162', ''),
    ('W037', 'core', 'wt_bomb', 'Чёртов гриб', 'Devil’s Puffball', NULL, NULL, NULL, 'TRUE', 0, 'humans', 'P', NULL, NULL, NULL, 4, 1, 'Тел*4', 'S', 0, '1', '138', ''),
    ('W038', 'dlc_prof_peasant', 'wt_tool', 'Вилы', 'Pitchfork', 'TRUE', NULL, NULL, NULL, -2, 'humans', 'E', '2d6+2', 2, 2, 15, 2, '2', 'XL', 0, '2', '115', ''),
    ('W039', 'exp_toc', 'wt_tool', 'Друидский серп', 'Druid’s Sickle', 'TRUE', 'TRUE', NULL, NULL, 0, 'humans', 'E', '3d6', 3, NULL, 15, 1, NULL, 'S', 0, '1', '540', ''),
    ('W040', 'hb', 'wt_tool', 'Кирка', 'Pickaxe', 'TRUE', NULL, NULL, NULL, -2, 'humans', 'E', '2d6', 2, NULL, 10, 2, NULL, 'L', 0, '1', '14', ''),
    ('W041', 'exp_lal', 'wt_tool', 'Кнут', 'Whip', NULL, 'TRUE', NULL, NULL, 0, 'humans', 'C', '1d6+2', 1, 2, 5, 1, NULL, 'M', 0, '0,5', '152', ''),
    ('W042', 'hb', 'wt_tool', 'Кочерга', 'Poker', 'TRUE', NULL, 'TRUE', NULL, 0, 'humans', 'E', '2d6+2', 2, 2, 10, 1, '2', 'L', 0, '2', '137', ''),
    ('W043', 'hb', 'wt_tool', 'Крюк', 'Hook', 'TRUE', NULL, NULL, NULL, -2, 'humans', 'E', '1d6', 1, NULL, 5, 1, NULL, 'M', 0, '0,1', '5', ''),
    ('W044', 'exp_lal', 'wt_tool', 'Ламия', 'Lamia', NULL, 'TRUE', NULL, NULL, -1, 'humans', 'R', '3d6+1', 3, 1, 5, 1, '2', 'M', 1, '0,5', '600', ''),
    ('W045', 'hb', 'wt_tool', 'Ледоруб', 'Ice Axe', 'TRUE', NULL, NULL, NULL, 0, 'humans', 'E', '1d6+2', 1, 2, 10, 1, NULL, 'S', 0, '1', '77', ''),
    ('W046', 'dlc_rw1', 'wt_tool', 'Лопата', 'Shovel', NULL, NULL, 'TRUE', NULL, -2, 'humans', 'E', '2d6', 2, NULL, 15, 2, NULL, 'L', 0, '1,5', '15', ''),
    ('W047', 'exp_bot', 'wt_tool', 'Пятиметровая цепь', '5m Chain', 'TRUE', NULL, NULL, NULL, -2, 'humans', 'E', '2d6+4', 2, 4, 15, 2, NULL, 'XL', 0, '2', '80', ''),
    ('W048', 'dlc_prof_peasant', 'wt_tool', 'Серп', 'Sickle', 'TRUE', 'TRUE', NULL, NULL, 0, 'humans', 'E', '1d6+2', 1, 2, 10, 1, NULL, 'S', 0, '1', '76', ''),
    ('W049', 'dlc_rw2', 'wt_tool', 'Утяжелённая сеть', 'Weighted Net', NULL, NULL, NULL, NULL, 0, 'humans', 'E', NULL, 0, NULL, 5, 2, NULL, 'L', 0, '4', '125', ''),
    ('W050', 'dlc_rw2', 'wt_tool', 'Сеть охотника на монстров', 'Monster Catcher’s Net', NULL, NULL, NULL, NULL, 0, 'humans', 'R', NULL, 0, NULL, 5, 2, NULL, 'L', 0, '4', '500', ''),
    ('W051', 'dlc_rw1', 'wt_tool', 'Факел', 'Torch', NULL, NULL, 'TRUE', NULL, -1, 'humans', 'E', '1d6', 1, NULL, 5, 1, NULL, 'M', 0, '0,1', '1', ''),
    ('W052', 'dlc_rw2', 'wt_tool', 'Шприц полевого врача', 'Field Doctor’s Syringe', 'TRUE', NULL, NULL, NULL, 1, 'humans', 'P', '1d6', 1, NULL, 5, 1, NULL, 'S', 0, '0,5', '350', ''),
    ('W053', 'hb', 'wt_pole', 'Алебарда-секач', 'Cleaving Halberd', 'TRUE', 'TRUE', 'TRUE', NULL, 0, 'humans', 'P', '5d6+2', 5, 2, 10, 2, '2', 'XL', 1, '3', '568', ''),
    ('W054', 'exp_bot', 'wt_pole', 'Боевое копьё', 'War Lance', 'TRUE', NULL, NULL, NULL, 0, 'humans', 'P', '2d6', 2, NULL, 10, 1, '2', 'XL', 0, '3,5', '550', ''),
    ('W055', 'core', 'wt_pole', 'Копьё', 'Spear', 'TRUE', NULL, 'TRUE', NULL, 0, 'humans', 'E', '3d6', 3, NULL, 10, 2, '2', 'XL', 1, '3,5', '375', 'Любимое оружие пехоты. Не маленькое, в среднем два метра в длину, зато поможет врага удержать подальше, да и кавалерии не даст тебя затоптать. Служа арбалетчиком в армии, я копья полюбил: нас от кавалерии нильфов как раз защищал отряд копейщиков.'),
    ('W056', 'dlc_prof_peasant', 'wt_pole', 'Коса', 'Scythe', 'TRUE', 'TRUE', NULL, NULL, -3, 'humans', 'E', '3d6', 3, NULL, 10, 2, NULL, 'XL', 0, '3,5', '126', ''),
    ('W057', 'core', 'wt_pole', 'Красная алебарда', 'Red Halberd', 'TRUE', 'TRUE', 'TRUE', NULL, 0, 'humans', 'P', '6d6+3', 6, 3, 10, 2, '2', 'XL', 1, '4', '865', 'Реданские алебардщики - одни из самых организованных и опасных воинов на Севере. Эти шлюхины дети сдерживают атаку кавалерии и пехоты на раз-два. Алебарды, которыми они вооружены, - настоящие произведения искусства. Двухметровое древко с тяжёлым широким лезвием и с шипами сзади и сверху.'),
    ('W058', 'core', 'wt_pole', 'Краснолюдский боевой молот', 'Dwarven Pole Hammer', 'TRUE', NULL, 'TRUE', NULL, 0, 'non-humans', 'R', '5d6+2', 5, 2, 15, 2, '2', 'XL', 1, '4', '835', 'Махакамские краснолюды выковали первые боевые молоты несколько веков тому назад для защиты от любого сукина сына, которому духу хватит напасть. На крепкой двухметровой рукояти закреплена сложная головка с длинным шипом сверху и крюком сзади. Универсальное оружие. Прям-таки машина для убийства.'),
    ('W059', 'dlc_prof_peasant', 'wt_pole', 'Палка', 'Quarter Staff', NULL, NULL, 'TRUE', NULL, 0, 'humans', 'E', '2d6', 2, NULL, 10, 2, '2', 'XL', 0, '3', '96', ''),
    ('W060', 'dlc_prof_peasant', 'wt_pole', 'Пастуший посох', 'Shepherd’s Crook', NULL, NULL, 'TRUE', NULL, 0, 'humans', 'E', '1d6-2', 1, -2, 10, 1, NULL, 'L', 0, '1', '14', ''),
    ('W061', 'exp_bot', 'wt_pole', 'Протазан', 'Partisan', 'TRUE', 'TRUE', 'TRUE', NULL, 1, 'humans', 'C', '4d6+2', 4, 2, 10, 2, '2', 'XL', 1, '3,5', '750', ''),
    ('W062', 'core', 'wt_pole', 'Секира', 'Pole Axe', 'TRUE', 'TRUE', 'TRUE', NULL, 0, 'humans', 'P', '4d6+2', 4, 2, 10, 2, '2', 'XL', 0, '3', '460', 'Эту лёгкую секиру выковал кузнец-краснолюд из Повисса. На длинном древке закреплён увесистый доёк: с одной стороны у него топор, а с другой - молот. А сверху острый шип торчит. Это универсальное оружие создано, чтобы разбираться с любой бронёй. Если хочешь держать нейтралитет, надо иметь хорошее оружие.'),
    ('W063', 'exp_bot', 'wt_pole', 'Турнирное копьё', 'Blunted Lance', NULL, NULL, 'TRUE', NULL, 0, 'humans', 'P', '2d6', 2, NULL, 5, 1, '2', 'XL', 0, '3,5', '500', ''),
    ('W064', 'hb', 'wt_pole', 'Фальшарда', 'Fauchard', 'TRUE', 'TRUE', 'TRUE', NULL, 0, 'humans', 'E', '3d6+2', 3, 2, 10, 2, '2', 'XL', 1, '1,5', '412', ''),
    ('W065', 'exp_lal', 'wt_pole', 'Человеколов', 'Mancatcher', 'TRUE', NULL, NULL, NULL, 0, 'humans', 'P', '3d6+3', 3, 3, 15, 2, '2', 'XL', 0, '3', '463', ''),
    ('W066', 'core', 'wt_pole', 'Эльфская глефа', 'Elven Glaive', 'TRUE', 'TRUE', 'TRUE', NULL, 2, 'non-humans', 'R', '4d6+3', 4, 3, 10, 2, '2', 'XL', 2, '3', '925', 'Слыхал я, что глефы были самым популярным оружием в золотой век эльфов, еще до прибытия людей. Полагаю, их использовала дворцовая стража. Длинное древко, на котором сверху закреплено бритвенно острое лезвие. Учитывая то, что большинство эльфов на севере сейчас пряутся, они, скорее всего, не могут себе позволить таскать такие большие штуки, как глефа.'),
    ('W067', 'core', 'wt_pole', 'Страж Бездны', 'The Abyss Guard', 'TRUE', NULL, 'TRUE', NULL, 2, 'humans', 'U', '7d6+4', 7, 4, 10, 2, '2', 'XL', 3, '4', NULL, ''),
    ('W068', 'exp_bot', 'wt_bludgeon', 'Крестьянский молот', 'Peasant’s Maul', NULL, NULL, 'TRUE', NULL, 0, 'humans', 'E', '5d6', 5, NULL, 5, 2, NULL, 'XL', 0, '3', '375', ''),
    ('W069', 'core', 'wt_bludgeon', 'Булава', 'Mace', NULL, NULL, 'TRUE', NULL, 0, 'humans', 'C', '5d6', 5, NULL, 15, 1, NULL, 'L', 0, '2', '525', 'Серьёзная игрушка. Цельный кусок металла с выступающими лопастями и шипами. Удар булавой способен переломать кости. Знаю многих наёмников, которые с собой это оружие таскают только ради того, чтобы пробивать броню.'),
    ('W070', 'hb', 'wt_bludgeon', 'Дубинка', 'Club', NULL, NULL, 'TRUE', NULL, 0, 'humans', 'E', '2d6+2', 2, 2, 10, 1, NULL, 'S', 0, '1', '83', ''),
    ('W071', 'exp_bot', 'wt_bludgeon', 'Клевец', 'Horseman’s Hammer', 'TRUE', NULL, 'TRUE', NULL, 0, 'humans', 'C', '2d6', 2, NULL, 10, 1, NULL, 'XL', 1, '2,5', '860', ''),
    ('W072', 'core', 'wt_bludgeon', 'Кастет', 'Brass Knuckles', NULL, NULL, 'TRUE', NULL, 1, 'humans', 'E', '1d6', 1, NULL, 15, 1, NULL, 'S', 1, '0,5', '50', 'Друже, мир - место несправедливое. И некоторым просто не повезло родиться слабыми. Обычно мне не приходится идти с врагом врукопашную - да-да, преимущество арбалетчика, - но если бы мне надо было регулярно чистить рожи, я бы обазвёлся кастетом, чтобы кулаком большее бить.'),
    ('W073', 'exp_lal', 'wt_bludgeon', 'Кистень', 'Flail', 'TRUE', NULL, 'TRUE', NULL, -1, 'humans', 'P', '4d6+2', 4, 2, 10, 1, NULL, 'L', 1, '2', '562', ''),
    ('W074', 'core', 'wt_bludgeon', 'Кистень из метеоритной стали', 'Meteorite Chain Mace', NULL, NULL, 'TRUE', NULL, 2, 'non-humans', 'R', '6d6', 6, NULL, 20, 1, NULL, 'XL', 2, '4', '900', 'Стильная игрушка. Шипастый шар из метеоритной стали на цепочке, которая крепится к обмотанной кожей рукояти. На полной скорости шар проламывает шлем вместе с черепом, примерно как если бы в голову попал настоящий метеорит. А цепью можно не только оружие ловить...'),
    ('W075', 'core', 'wt_bludgeon', 'Махакамский мартель', 'Mahakaman Martell', NULL, NULL, 'TRUE', NULL, 0, 'non-humans', 'R', '5d6', 5, NULL, 15, 2, NULL, 'L', 1, '3,5', '750', 'Мартель - краснолюдское оружие, достаточно редкое. Нечасто видишь, как с ним люди шастают. По сути, это молот с длинным шипом с обратной стороны, насаженный на метровую рукоять. Многие краснолюды предпочитают укорачивать рукоять и носить это оружие за голенищем сапога.'),
    ('W076', 'core', 'wt_bludgeon', 'Молот горца', 'Highland Mauler', NULL, NULL, 'TRUE', NULL, 0, 'humans', 'R', '6d6+2', 6, 2, 20, 2, NULL, 'XL', 1, '3', '1100', 'Каэдвенцы - ребята крупные. Если бы меня попросили назвать самых крепких засранцев в мире, то я толчно выбрал бы островитян со Скеллиге, каэдвенцев и геммерцев. Но вот эти вот молоты дают каэдвенцам преимущество. За свою жизнь я продал только два таких, но они действительно огромны. Почти два метра длиной, со здоровенным навершием, выложенным метеоритной сталью.'),
    ('W077', 'hb', 'wt_bludgeon', 'Нагайка', 'Riding Whip', NULL, NULL, 'TRUE', NULL, 0, 'humans', 'E', '2d6', 2, NULL, 10, 1, NULL, 'S', 0, '1', '115', ''),
    ('W078', 'core', 'wt_bludgeon', 'Огх''р', 'Ogh’r', NULL, NULL, 'TRUE', NULL, 0, 'non-humans', 'U', '10d6', 10, NULL, 15, 2, NULL, 'XL', 3, '5', NULL, ''),
    ('W079', 'exp_lal', 'wt_sblade', 'Дага', 'Parrying Dagger', 'TRUE', 'TRUE', NULL, NULL, 0, 'humans', 'C', '2d6', 2, NULL, 10, 1, NULL, 'M', 1, '1', '350', ''),
    ('W080', 'core', 'wt_sblade', 'Джамбия', 'Jambiya', 'TRUE', 'TRUE', NULL, NULL, 2, 'humans', 'R', '2d6', 2, NULL, 10, 1, NULL, 'M', 1, '0,5', '440', 'Друже, даже в далёокй Зеррикании смерть - самая твёрдая валюта. И именно там куют один из лучших кинжалов в мире. Впервые эти странные кривые штуки мы заметили у ассасинов из Мехта во время Первой войны.'),
    ('W081', 'dlc_wt', 'wt_sblade', 'Змеиный клык', 'Viper’s Fang', 'TRUE', 'TRUE', NULL, NULL, 1, 'witchers', 'R', '2d6+2', 2, 2, 10, 1, NULL, 'M', 1, '0,5', NULL, ''),
    ('W082', 'core', 'wt_sblade', 'Кинжал', 'Dagger', 'TRUE', 'TRUE', NULL, NULL, 0, 'humans', 'E', '1d6+2', 1, 2, 10, 1, NULL, 'M', 0, '0,5', '50', 'Кинжалы бывают разной формы и размеров, но обычно они достаточно малы, чтобы влезать в карман. Кинжал при себе носят все, от рыцарей до крестьян.'),
    ('W083', 'core', 'wt_sblade', 'Короткий кинжал', 'Poniard', 'TRUE', 'TRUE', NULL, NULL, 1, 'humans', 'P', '2d6+2', 2, 2, 10, 1, NULL, 'M', 0, '1', '350', 'Оружие старой доброй темерской работы. Длинное, тонкое и лёгкое. В битве под Содденом я с чёрным дрался, а из оружия у меня был лишь этот вот ножик. Нильф мне шесть рёбер переломал, вот только я то жив-здоров, а он - нет.'),
    ('W084', 'core', 'wt_sblade', 'Краснолюдский секач', 'Dwarven Cleaver', NULL, 'TRUE', 'TRUE', NULL, 2, 'non-humans', 'R', '3d6', 3, NULL, 15, 1, NULL, 'M', 1, '1,5', '500', 'Ха! Вот кто-кто, а краснолюды могут притащить секач на бой на ножах. Если тебе надо прорубиться... да, честно говоря, через что угодно, то бери краснолюдский секач. Он недлинный, но прекрасно и конечности людям рубит, и ветки деревьев.'),
    ('W085', 'exp_toc', 'wt_sblade', 'Кинжал из кровавого камня', 'Bloodstone Dagger', 'TRUE', 'TRUE', NULL, NULL, 0, 'humans', 'R', '2d6', 2, NULL, 5, 1, NULL, 'M', 1, '0,5', NULL, ''),
    ('W086', 'dlc_rw2', 'wt_sblade', 'Ловец Мечей', 'Sword Catcher', 'TRUE', 'TRUE', NULL, NULL, 0, 'humans', 'P', '2d6', 2, NULL, 10, 1, NULL, 'M', 1, '1', '500', ''),
    ('W087', 'core', 'wt_sblade', 'Низушечий рондель', 'Halfling Rondel', 'TRUE', 'TRUE', NULL, NULL, 2, 'non-humans', 'R', '2d6+2', 2, 2, 10, 1, NULL, 'M', 1, '1', '485', 'Низушки куда ниже людей и куда хрупче краснолюдов. Не скажу, что они слабаки, но что-то не видно армий низушков. Этот кинжал для низушков в самый раз: тонкий и крепкий, с круглой головкой и гардой. Им очень легко колоть в стыки брони, оставляя кровоточащие раны.'),
    ('W088', 'hb', 'wt_sblade', 'Серебряный змеиный клык', 'Silver Viper Fang', 'TRUE', 'TRUE', NULL, NULL, 1, 'witchers', 'R', '1d6+2', 1, 2, 10, 1, NULL, 'M', 1, '0,5', NULL, ''),
    ('W089', 'core', 'wt_sblade', 'Стилет', 'Stiletto', 'TRUE', 'TRUE', NULL, NULL, 2, 'humans', 'C', '1d6', 1, NULL, 5, 1, NULL, 'S', 1, '0,5', '275', 'Вот уж кто-кто, а чёрные могут даже из обычного кинжала сделать ещё более подлое оружие. Длинный тонкий клинок этого кинжала убирается в рукоять, так что спрятать эту дрянь можно где угодно.'),
    ('W090', 'core', 'wt_sblade', 'Шип', 'Thorn', 'TRUE', 'TRUE', NULL, NULL, 3, 'non-humans', 'U', '3d6', 3, NULL, 15, 1, NULL, 'M', 3, '0,5', NULL, ''),
    ('W091', 'core', 'wt_trap', 'Бешенство', 'Fury', NULL, NULL, NULL, 'TRUE', 0, 'humans', 'P', NULL, NULL, NULL, 8, NULL, NULL, NULL, NULL, '2', '114', ''),
    ('W092', 'core', 'wt_trap', 'Капкан', 'Bear trap', NULL, NULL, 'TRUE', NULL, 0, 'humans', 'C', '3d6', 3, NULL, 1, NULL, NULL, NULL, NULL, '2', '72', ''),
    ('W093', 'core', 'wt_trap', 'Когтезуб', 'Clawer', NULL, 'TRUE', NULL, NULL, 0, 'humans', 'P', '5d6', 5, NULL, 4, NULL, NULL, NULL, NULL, '2', '111', ''),
    ('W094', 'core', 'wt_trap', 'Кусач', 'Biter', 'TRUE', NULL, NULL, NULL, 0, 'humans', 'P', '7d6', 7, NULL, 4, NULL, NULL, NULL, NULL, '2', '144', ''),
    ('W095', 'core', 'wt_trap', 'Метка', 'Marker', NULL, NULL, NULL, 'TRUE', 0, 'humans', 'P', NULL, NULL, NULL, 8, NULL, NULL, NULL, NULL, '2', '57', ''),
    ('W096', 'dlc_rw1', 'wt_trap', 'Мешочек с шариками', 'Bag of Marbles', NULL, NULL, NULL, NULL, 0, 'humans', 'E', NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, '0,1', '18', ''),
    ('W097', 'core', 'wt_trap', 'Пожарище', 'Conflagration', NULL, NULL, NULL, 'TRUE', 0, 'humans', 'P', '5d6', 5, NULL, 4, NULL, NULL, NULL, NULL, '2', '121', ''),
    ('W098', 'core', 'wt_trap', 'Талгарская зима', 'Talgar Winter', NULL, NULL, NULL, 'TRUE', 0, 'humans', 'P', NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL, '2', '126', ''),
    ('W099', 'core', 'wt_bow', 'Армейский лук', 'War Bow', 'TRUE', NULL, NULL, NULL, 0, 'humans', 'C', '6d6', 6, NULL, 15, 2, '300', 'XL', 1, '3', '835', 'Убойная штука. Создан для того, чтобы отстреливать рыцарей в крепких латах. Эта дура два метра высотой, с силой натяжения до 77 килограмм. Такие луки на поле боя часто встречаются - а что, стой себе и постреливай в небо, поливая врага дождём из стрел. Я то предпочитаю арбалетом орудовать, но уважаю бойцов, способных стрелять из этой громадины.'),
    ('W100', 'core', 'wt_bow', 'Длинный лук', 'Long Bow', 'TRUE', NULL, NULL, NULL, 0, 'humans', 'E', '4d6', 4, NULL, 10, 2, '200', 'XL', 1, '2', '475', 'Длинный лук - предок арбалета. Для меня они слишком громоздкие, держать их трудно. Но это я ростом не выдался. А вот эльфы на длинные луки чуть ли не молятся. В их руках это второе по смертоносности дальнобойное оружие после, мать её, баллисты. Люди в основном предпочитают арбалеты, хотя в Нильфгаарде полным-полно лучников, готовых наглядно доказать своё смертоносное мастерство.'),
    ('W101', 'hb', 'wt_bow', 'Ковирский ламинированный лук', 'Kovirian Laminated Bow', 'TRUE', NULL, NULL, NULL, 3, 'humans', 'R', '6d6', 6, NULL, 10, 2, '370', 'XL', 2, '1,5', '1371', ''),
    ('W102', 'core', 'wt_bow', 'Короткий лук', 'Short Bow', 'TRUE', NULL, NULL, NULL, 0, 'humans', 'E', '3d6+3', 3, 3, 10, 2, '100', 'L', 0, '1', '290', 'На войне коротких луков раз-два и обчёлся. Они слишком маленькие, чтобы быть полезными на поле боя, да и дальность стрельбы у них не очень. Впрочем, такое оружие идеально подходит для охоты на оленя... или на проезжего купца.'),
    ('W103', 'core', 'wt_bow', 'Эльфский зефар', 'Elven Zefhar', 'TRUE', NULL, NULL, NULL, 2, 'non-humans', 'R', '6d6', 6, NULL, 10, 2, '350', 'XL', 2, '2,5', '1100', 'Гордость и отрада эльфов. Это длинный лук с четырьмя плечами, на который натянута крепкая вощёная тетива. Две пары плеч у зефара увеличивают силы выстрела в два раза. Что приятно, лук от этого тяжелее не становится.'),
    ('W104', 'core', 'wt_bow', 'Эльфский походный лук', 'Elven Travel Bow', 'TRUE', NULL, NULL, NULL, 1, 'non-humans', 'R', '4d6', 4, NULL, 10, 2, '200', 'L', 1, '1', '575', 'По сути, это просто уменьшенный зефар. Отличные в том, что с походного лука можно спокойно снять тетиву и согнуть его, чтобы запихнуть в сумку.'),
    ('W105', 'hb', 'wt_bow', 'Эльфский сдвоенный лук', 'Elven Double Bow', 'TRUE', NULL, NULL, NULL, 1, 'non-humans', 'R', '5d6', 5, NULL, 10, 2, '250', 'XL', 1, '2', '816', ''),
    ('W106', 'core', 'wt_bow', 'Лунный лук', 'The Moon Bow', 'TRUE', NULL, NULL, NULL, 1, 'non-humans', 'U', '8d6+2', 8, 2, 10, 2, '200', 'XL', 3, '2', NULL, ''),
    ('W107', 'core', 'wt_thrown', 'Метательный нож', 'Throwing Knife', 'TRUE', NULL, NULL, NULL, 0, 'humans', 'E', '1d6', 1, NULL, 5, 1, 'Тел*4', 'S', 0, '0,5', '50', 'Ножички эти - весьма занимательные штучки. Они маленькие (так что их легко спрятать) и сбалансированы для метания. Придётся попрактиковаться, чтобы запомнить скорость вращения и прочее, но оно того стоит. Хорошее оружие для убийцы.'),
    ('W108', 'core', 'wt_thrown', 'Метательный топор', 'Throwing Axe', NULL, 'TRUE', NULL, NULL, 0, 'humans', 'E', '2d6', 2, NULL, 10, 1, 'Тел*2', 'M', 0, '1', '75', 'Но летит куда дальше топора, зато топором по голове прилетит покрепче. Нет ничего страшнее, чем несущаяся тебе в рыло металическая штуковина с ручкой.'),
    ('W109', 'core', 'wt_thrown', 'Орион', 'Orion', NULL, 'TRUE', NULL, NULL, 1, 'humans', 'P', '1d6', 1, NULL, 5, 1, 'Тел*4', 'S', 0, '0,1', '100', 'Чёрные стали ими пользоваться пару десятилетий назад. Это что-то вроде метательного ножа, только формой напоминает звёздочку. Странновато выглядит, но вещь опасная. Да и летит быстро.'),
    ('W110', 'dlc_rw2', 'wt_thrown', 'Отравленный коготь гарпии', 'Poisoned Harpy Claw', 'TRUE', NULL, NULL, NULL, 1, 'humans', 'P', '1d6', 1, NULL, 10, 1, 'Тел*4', 'S', 0, '0,5', '450', ''),
    ('W111', 'hb', 'wt_sword', 'Боклерский меч', 'Buckler Sword', 'TRUE', 'TRUE', NULL, NULL, 0, 'humans', 'R', '5d6', 5, NULL, 10, 1, NULL, 'L', 1, '1,5', '800', ''),
    ('W112', 'core', 'wt_sword', 'Гледдиф', 'Gleddyf', 'TRUE', 'TRUE', NULL, NULL, 0, 'humans', 'C', '3d6+2', 3, 2, 5, 2, NULL, 'L', 0, '3', '285', 'Это один из самых тяжёлых и тонких клинков на Континенте. Весь его вес сосредоточен в вычурной гарде и навершии. Но сделать его достаточно просто. Потому-то чёрные его и предпочитают, учитывая, как быстро у них армия множится.'),
    ('W113', 'core', 'wt_sword', 'Гномий гвихир', 'Gnomish Gwyhyr', 'TRUE', 'TRUE', NULL, NULL, 3, 'non-humans', 'R', '5d6+3', 5, 3, 15, 2, NULL, 'XL', 2, '2,5', '1090', 'Долгое время гвихиры считались лучшими мечами в мире. Они до сих пор одни из лучших. Длинный чёрный клинок настолько острый, что им бриться можно. Настолько лёгкий, что им спокойно можно размахивать одной рукой на полной скорости. Обожаю эти игрушки, но они чертовски редкие.'),
    ('W114', 'hb', 'wt_sword', 'Деревянный меч', 'Wooden Sword', NULL, NULL, 'TRUE', NULL, 0, 'humans', 'E', '2d6', 2, NULL, 10, 2, NULL, 'L', 0, '1', '67', ''),
    ('W115', 'hb', 'wt_sword', 'Железный меч', 'Iron Sword', 'TRUE', 'TRUE', NULL, NULL, 0, 'humans', 'E', '2d6', 2, NULL, 10, 1, NULL, 'L', 0, '1', '167', ''),
    ('W116', 'core', 'wt_sword', 'Железный полуторный меч', 'Iron Long Sword', 'TRUE', 'TRUE', NULL, NULL, 0, 'humans', 'E', '2d6+2', 2, 2, 10, 2, NULL, 'L', 0, '1,5', '160', 'Полуторный меч. Из железа. Скажу тебе, как краснолюд: от одной мысли об этой дряни мне дурно становится. Им чёрта с два кого прирежешь. Но зато его делать просто и достать можно всюду'),
    ('W117', 'core', 'wt_sword', 'Клинок бригады "Врихед"', 'Vrihedd Cavalry Sword', 'TRUE', 'TRUE', NULL, NULL, 3, 'non-humans', 'R', '4d6+4', 4, 4, 15, 1, NULL, 'L', 0, '2,5', '745', 'Когда-то кавалерийской бригады "Врихедд" боялись по всему миру. Как-то раз мне довелось с ними столкнуться. Мне и моим парням. Вот эти вот мечи из синей стали в руках всадников снесут башку даже самому крепкому краснолюду. Мне повезло выжить.'),
    ('W118', 'core', 'wt_sword', 'Клинок из Виковаро', 'Vicovarian Blade', 'TRUE', 'TRUE', NULL, NULL, 0, 'humans', 'R', '5d6+4', 5, 4, 15, 2, NULL, 'XL', 1, '1,5', '955', 'Такие мечи можно узнать по тяжёлой гарде. Обычно ими дерутся рыцари из Виковаро, но из-за войны их можно найти чуть ли не всюду. Вот что я тебе скажу: видал я, как на эти мечи обрушивались целые замки, и даже после такого этим оружием рубили руки-ноги.'),
    ('W119', 'exp_bot', 'wt_sword', 'Клинок из Вироледы', 'Viroledan Blade', 'TRUE', 'TRUE', NULL, NULL, 1, 'humans', 'R', '4d6+4', 4, 4, 10, 2, NULL, 'XL', 0, '2,5', '995', ''),
    ('W120', 'core', 'wt_sword', 'Клинок из Тир Тохаира', 'Tir Tochair Blade', 'TRUE', 'TRUE', NULL, NULL, 3, 'non-humans', 'R', '6d6', 6, NULL, 15, 2, NULL, 'XL', 2, '3', '1175', 'Гномы Тир Тохаира начали ковать мечи за много веков до того, как эльфы высадились на Континенте. Столь долгий опыт пошёл им на пользу. Клинки из Тыр Тохаира длинные и острые, словно бритва, и по всей длине покрыты тончайшими гномьими письменами.'),
    ('W121', 'core', 'wt_sword', 'Корд', 'Kord', 'TRUE', 'TRUE', NULL, NULL, 0, 'humans', 'R', '5d6', 5, NULL, 15, 1, NULL, 'XL', 1, '1,5', '725', 'Корды куют для моряков в прибрежном цидарском городе. Крепкий и простой клинок с изогнутым лезвием. Слыхал я, что клинки эти вывозят на Север, а то и вовсе в море выбрасывают, лишь бы чёрные их к рукам не прибрали.'),
    ('W122', 'core', 'wt_sword', 'Кригсверд', 'Krigsværd', 'TRUE', 'TRUE', NULL, NULL, 2, 'humans', 'C', '4d6+4', 4, 4, 10, 1, NULL, 'L', 0, '2', '570', 'Говаривают, что жители Скеллиге закаляют клинки в крови сирен и утопцев. Скажу так, друже: это правда. Ну, или было правдой. Благодаря закалённой стали и облегчённой конструкции эти клинки бьют невероятно точно.'),
    ('W123', 'hb', 'wt_sword', 'Махакамский сигилль', 'Mahakaman Sigil', 'TRUE', 'TRUE', NULL, NULL, 2, 'non-humans', 'R', '5d6+2', 5, 2, 15, 2, NULL, 'XL', 2, '2', '924', ''),
    ('W124', 'core', 'wt_sword', 'Меч из метеоритной стали', 'Meteorite Sword', 'TRUE', 'TRUE', NULL, NULL, 1, 'non-humans', 'R', '5d6', 5, NULL, 20, 2, NULL, 'XL', 2, '3', '875', 'Метеоритная сталь - один из лучших материалов для оружия. Выкованные из неё мечи поблёскивают разными цветами, да ещё и крепкие донельзя. И удивительно лёгкие.'),
    ('W125', 'hb', 'wt_sword', 'Меч охотника за колдуньями', 'Witch Hunter’s Sword', 'TRUE', 'TRUE', NULL, NULL, 0, 'humans', 'P', '5d6', 5, NULL, 15, 2, NULL, 'XL', 1, '2', '679', ''),
    ('W126', 'core', 'wt_sword', 'Охотничий фальшион', 'Hunter’s Falchion', 'TRUE', 'TRUE', NULL, NULL, 0, 'humans', 'C', '3d6', 3, NULL, 15, 1, NULL, 'L', 0, '2', '325', 'Таким оружием охотники пользуются для разделки подстреленной животины. Если тебе нужен хороший клинок, чтобы и дрова рубить, и конечности, лучше не найдешь. Оружие такое встречается часто.'),
    ('W127', 'core', 'wt_sword', 'Рыцарский меч', 'Arming Sword', 'TRUE', 'TRUE', NULL, NULL, 0, 'humans', 'C', '2d6+4', 2, 4, 15, 1, NULL, 'L', 0, '2,5', '270', 'Реданский рыцарский меч - это одноручное оружие с простой изогнутой гардой и острой режущей кромкой. Учитывая то, как реданцы расползаются по всему Северу, чтобы нас "защитить", этих мечей хоть жопой жуй.'),
    ('W128', 'core', 'wt_sword', 'Серебряный ведьмачий меч', 'Witcher’s Silver Sword', 'TRUE', 'TRUE', NULL, NULL, 0, 'witchers', 'R', '1d6+2', 1, 2, 10, 1, NULL, 'XL', 2, '1,5', NULL, 'Каких только жутей не видали ведьмаки. А таким вот клинком они орудуют при охоте на особо отвратительных тварей. У кого другого такой почти не реально найти, ведь он куда менее острый и твердый чем даже обычная железяка, но уж больно твари это серебро не любят. От того почти невозможно встретить ведьмака без своего серебряного клинка.'),
    ('W129', 'dlc_wt', 'wt_sword', 'Серебряный ведьмачий меч школы Волка', 'Wolven Silver Sword', 'TRUE', 'TRUE', NULL, NULL, 1, 'witchers', 'R', '2d6+2', 2, 2, 10, 1, NULL, 'XL', 3, '1,5', NULL, ''),
    ('W130', 'dlc_wt', 'wt_sword', 'Серебряный ведьмачий меч школы Грифона', 'Griffin Silver Sword', 'TRUE', 'TRUE', NULL, NULL, 1, 'witchers', 'R', '2d6+2', 2, 2, 10, 1, NULL, 'XL', 2, '1,5', NULL, ''),
    ('W131', 'dlc_wt', 'wt_sword', 'Серебряный ведьмачий меч школы Змеи', 'Serpentine Silver Sword', 'TRUE', 'TRUE', NULL, NULL, 2, 'witchers', 'R', '1d6+2', 1, 2, 10, 1, NULL, 'XL', 2, '1,5', NULL, ''),
    ('W132', 'dlc_wt', 'wt_sword', 'Серебряный ведьмачий меч школы Кота', 'Feline Silver Sword', 'TRUE', 'TRUE', NULL, NULL, 2, 'witchers', 'R', '1d6+2', 1, 2, 10, 1, NULL, 'XL', 2, '1,5', NULL, ''),
    ('W133', 'dlc_wt', 'wt_sword', 'Серебряный ведьмачий меч школы Мантикоры', 'Manticore Silver Sword', 'TRUE', 'TRUE', NULL, NULL, 1, 'witchers', 'R', '2d6+2', 2, 2, 10, 1, NULL, 'XL', 2, '1,5', NULL, ''),
    ('W134', 'dlc_wt', 'wt_sword', 'Серебряный ведьмачий меч школы Медведя', 'Ursine Silver Sword', 'TRUE', 'TRUE', NULL, NULL, 0, 'witchers', 'R', '3d6+2', 3, 2, 10, 1, NULL, 'XL', 2, '1,5', NULL, ''),
    ('W135', 'core', 'wt_sword', 'Стальной ведьмачий меч', 'Witcher’s Steel Sword', 'TRUE', 'TRUE', NULL, NULL, 0, 'witchers', 'R', '4d6+2', 4, 2, 15, 1, NULL, 'XL', 2, '2,5', NULL, 'По сей день ведьмаки - единственные, кто постоянно носит при себе пару мечей из метеоритной стали и серебра. Это тот, который сделан из метеоритной стали. Весьма редкая вещица, не каждый день с неба камни падают. Но такой меч - практически часть ведьмака!'),
    ('W136', 'dlc_wt', 'wt_sword', 'Стальной ведьмачий меч школы Волка', 'Wolven Steel Sword', 'TRUE', 'TRUE', NULL, NULL, 1, 'witchers', 'R', '5d6+2', 5, 2, 15, 1, NULL, 'XL', 3, '2,5', NULL, ''),
    ('W137', 'dlc_wt', 'wt_sword', 'Стальной ведьмачий меч школы Грифона', 'Griffin Steel Sword', 'TRUE', 'TRUE', NULL, NULL, 1, 'witchers', 'R', '5d6+2', 5, 2, 15, 1, NULL, 'XL', 2, '2,5', NULL, ''),
    ('W138', 'dlc_wt', 'wt_sword', 'Стальной ведьмачий меч школы Змеи', 'Serpentine Steel Sword', 'TRUE', 'TRUE', NULL, NULL, 2, 'witchers', 'R', '4d6+2', 4, 2, 15, 1, NULL, 'XL', 2, '2,5', NULL, ''),
    ('W139', 'dlc_wt', 'wt_sword', 'Стальной ведьмачий меч школы Кота', 'Feline Steel Sword', 'TRUE', 'TRUE', NULL, NULL, 2, 'witchers', 'R', '4d6+2', 4, 2, 15, 1, NULL, 'XL', 2, '2,5', NULL, ''),
    ('W140', 'dlc_wt', 'wt_sword', 'Стальной ведьмачий меч школы Мантикоры', 'Manticore Steel Sword', 'TRUE', 'TRUE', NULL, NULL, 1, 'witchers', 'R', '5d6+2', 5, 2, 15, 1, NULL, 'XL', 2, '2,5', NULL, ''),
    ('W141', 'dlc_wt', 'wt_sword', 'Стальной ведьмачий меч школы Медведя', 'Ursine Steel Sword', 'TRUE', 'TRUE', NULL, NULL, 0, 'witchers', 'R', '5d6+2', 5, 2, 15, 1, NULL, 'XL', 2, '2,5', NULL, ''),
    ('W142', 'hb', 'wt_sword', 'Счетовод', 'The Abacus', 'TRUE', 'TRUE', NULL, NULL, 0, 'humans', 'C', '4d6', 4, NULL, 15, 1, NULL, 'L', 1, '1,5', '481', ''),
    ('W143', 'core', 'wt_sword', 'Торрур', 'Torwyr', 'TRUE', 'TRUE', NULL, NULL, 0, 'humans', 'R', '6d6', 6, NULL, 15, 2, NULL, 'XL', 2, '2', '1075', 'Если на тебя бежит мужик с торруром, притворись мёртвым. Во время последней войны я видел, как здоровяк ростом с небольшую гору попросту отрубил этой штукой башку скачущей лошади. Геммерцы вообще больные на голову сукины дети. Смотрят на тебя так, словно сожрать готовы.'),
    ('W144', 'exp_bot', 'wt_sword', 'Фламберг', 'Flamberge', 'TRUE', 'TRUE', NULL, NULL, -1, 'humans', 'P', '6d6', 6, NULL, 15, 2, '2', 'XL', 1, '3,5', '1025', ''),
    ('W145', 'core', 'wt_sword', 'Эльфский мессер', 'Elven Messer', 'TRUE', 'TRUE', NULL, NULL, 2, 'non-humans', 'R', '3d6+4', 3, 4, 15, 1, NULL, 'L', 2, '2', '595', 'Поговаривают, что этот клинок выдумали назаирцы, которым чёрные запретили мечи носить. Вот и выковали нож-переросток - технически-то это не меч. Закончилось всё не очень хорошо, но в итоге эльфы взяли ту конструкцию и доработали.'),
    ('W146', 'core', 'wt_sword', 'Эсбода', 'Esboda', 'TRUE', 'TRUE', NULL, NULL, 1, 'humans', 'P', '5d6', 5, NULL, 10, 1, NULL, 'XL', 1, '1,5', '650', 'Торговцам порой приходится забыть о своих предубеждениях, когда речь заходит о хорошем товаре. Метинская эсбода - один из самых лёгких и острых ковалерийских клинков, какие мне только доводилось видеть. Как гледдиф, только лучше. И чёрные не брезгуют заставить "вассалов" такое оружие для армии ковать.'),
    ('W147', 'core', 'wt_sword', 'Волк', 'Wolf', 'TRUE', 'TRUE', NULL, NULL, 2, 'humans', 'U', '7d6', 7, NULL, 15, 2, NULL, 'XL', 3, '4', NULL, ''),
    ('W148', 'core', 'wt_sword', 'Девин', 'Devine', 'TRUE', 'TRUE', NULL, NULL, 0, 'humans', 'U', '10d6', 10, NULL, 20, 2, NULL, 'XL', 3, '2', NULL, ''),
    ('W149', 'core', 'wt_sword', 'Каролина', 'Caroline', 'TRUE', 'TRUE', NULL, NULL, 3, 'humans', 'U', '9d6', 9, NULL, 15, 2, NULL, 'XL', 3, '3', NULL, ''),
    ('W150', 'core', 'wt_sword', 'Лунный клинок', 'Moon Blade', 'TRUE', 'TRUE', NULL, NULL, 1, 'humans', 'U', '3d6', 3, NULL, 10, 2, NULL, 'XL', 3, '4', NULL, ''),
    ('W151', 'core', 'wt_sword', 'Могрим', 'Maugrim', 'TRUE', 'TRUE', NULL, NULL, 0, 'witchers', 'U', '2d6', 2, NULL, 10, 2, NULL, 'XL', 3, '6', NULL, ''),
    ('W152', 'core', 'wt_sword', 'Сорвишапка', 'Cleaver Hood', 'TRUE', 'TRUE', NULL, NULL, 0, 'humans', 'U', '8d6+2', 8, 2, 20, 2, NULL, 'XL', 3, '3', NULL, ''),
    ('W153', 'core', 'wt_sword', 'Судьба', 'Fate', 'TRUE', 'TRUE', NULL, NULL, 3, 'non-humans', 'U', '2d6+1', 2, 1, 10, 2, NULL, 'XL', 3, '4', NULL, ''),
    ('W154', 'core', 'wt_staff', 'Гномий посох', 'Gnomish Staff', NULL, NULL, 'TRUE', NULL, 1, 'non-humans', 'R', '3d6+2', 3, 2, 15, 2, '2', 'L', 2, '2,5', '910', 'Как и любое изделие гномей работы, эти посохи впечатляют. Они сделаны из тёмной травлёной древесины и покрыты рунами сверху донизу. Обычно ещё местами в них вправлены самоцветы.'),
    ('W155', 'core', 'wt_staff', 'Железный посох', 'Iron Staff', NULL, NULL, 'TRUE', NULL, 0, 'humans', 'P', '3d6', 3, NULL, 15, 2, '2', 'XL', 1, '4', '675', 'Иногда магу требуется чуть больше защиты, ну, на тот случай, если магиея подведёт. Для этого есть железный посох. По сути, это просто большая палка из железа с пятой эссенцией внутри. Такой посох крепче обычного, а врезать им можно прям как булавой, да и удары мечом отчасти блокировать.'),
    ('W156', 'exp_toc', 'wt_staff', 'Истинный связывающий посох', 'True Staff of Binding', NULL, NULL, 'TRUE', NULL, 0, 'humans', 'R', '2d6', 2, NULL, 5, 2, '2', 'XL', 1, '2', NULL, ''),
    ('W157', 'core', 'wt_staff', 'Посох', 'Staff', NULL, NULL, 'TRUE', NULL, 0, 'humans', 'C', '1d6+2', 1, 2, 10, 2, '2', 'XL', 1, '3', '335', 'Никому не говори, что я его тебе продал, понял? Спокойно расхаживать с магически посохом можно разве что на Скеллиге, или, может, в Зеррикании или Офире. Для простых смертных это светящаяся палка, а вот маги с помощью посоха способны использовать куда больше магии, чем без него. Учитывая ненависть к магам на Севере и недоверие к ним на Юге, посох делает из владельца ходячую мишень.'),
    ('W158', 'core', 'wt_staff', 'Посох с кристаллом', 'Crystal Staff', NULL, NULL, 'TRUE', NULL, 0, 'humans', 'R', '2d6+2', 2, 2, 5, 2, '2', 'XL', 2, '2,5', '835', 'У лучших магов при себе есть посох с кристаллом. На первый взгляд это обычный посох, в навершие которого вправлен самоцвет. Только вот самоцвет должен быть совершенным: если он хоть чуточку треснутый или изъяном, то может рвануть прямо в лицо. Но посохи эти стоят подобного риска, учитывая то, как хорошо они магию усиливают.'),
    ('W159', 'core', 'wt_staff', 'Посох с крюком', 'Hooked Staff', 'TRUE', NULL, 'TRUE', NULL, 0, 'humans', 'P', '2d6', 2, NULL, 10, 2, '2', 'XL', 1, '3,5', '550', 'Никогда не понимал, зачем нужен такой посох, но один юный маг, с которым я странствовал, рассказал, что таким орудовал маг по имени Альзур. Оказывается, этот Альзур крюком направлял тварей, которых сам создал. Бьюсь об заклад, у него-то крюк был из серебра. Но оружие это в любом случае пригодится тем, кто любит посохом промеж глаз засветить.'),
    ('W160', 'exp_toc', 'wt_staff', 'Связывающий посох', 'Staff of Binding', NULL, NULL, 'TRUE', NULL, 0, 'humans', 'R', '2d6', 2, NULL, 5, 2, '2', 'XL', 1, '2', NULL, ''),
    ('W161', 'core', 'wt_staff', 'Эльфский дорожный посох', 'Elven Walking Staff', NULL, NULL, 'TRUE', NULL, 1, 'non-humans', 'R', '3d6', 3, NULL, 10, 2, '2', 'XL', 2, '1,5', '975', 'Много лет назад с такими ходили эльфьи мудрецы. Дорожные посохи куда меньше обычных, самое большее до груди. Красивые, украшенные шёлком и золотом, но важнее всего в них то, насколько хорошо позволяют фокусировать магическую энергию.'),
    ('W162', 'core', 'wt_staff', 'Посох суккуба', 'Succubus’ Wand', NULL, NULL, 'TRUE', NULL, 0, 'non-humans', 'U', '3d6+2', 3, 2, 5, 2, '2', 'XL', 3, '2', NULL, ''),
    ('W163', 'core', 'wt_axe', 'Боевой топор', 'Battle Axe', NULL, 'TRUE', NULL, NULL, 0, 'humans', 'C', '5d6', 5, NULL, 15, 1, NULL, 'L', 0, '2', '525', 'Надо выломать дверь? Изрубить тело, живое или мёртвое? Тогда, приятель, тебе нужен боевой топор. Форма может быть разной, но так-то боевой топор - смертоносное оружие, поркрепче многих мечей.'),
    ('W164', 'core', 'wt_axe', 'Гномий чёрный топор', 'Gnomish Black Axe', NULL, 'TRUE', NULL, NULL, 2, 'non-humans', 'R', '6d6+2', 6, 2, 15, 2, NULL, 'XL', 2, '2,5', '910', 'Гномий гвихир всем известен. Но немногие знают, что гномы ещё и топоры куют. Сделаны они аналогично гвихирам, только потяжелее. Топор бородовидный, покрытый гномьими рунами. Это оружие по ощущениям настолько лёгкое и тонкое, что пользовать его в бою кажется чем-то несусветным. Но достаточно крепкое, чтобы проломить доспех.'),
    ('W165', 'core', 'wt_axe', 'Краснолюдский топор', 'Dwarven Axe', NULL, 'TRUE', NULL, NULL, 3, 'non-humans', 'R', '5d6+3', 5, 3, 15, 1, NULL, 'L', 1, '4', '740', 'Есть ошибочное мнение, что краснолюды поголовно топоры таскают. На самом деле не все, но многие. Дай краснолюду тяжёлый топор, и он тебе дырку в любой стене прорубит. Особенно если топор этот краснолюдской работы. Двусторонний топор весьма увесист, да и рубить им можно в любую сторону.'),
    ('W166', 'core', 'wt_axe', 'Топор', 'Hand Axe', NULL, 'TRUE', NULL, NULL, 0, 'humans', 'E', '2d6+1', 2, 1, 10, 1, NULL, 'M', 0, '1', '205', 'Полюбил я со временем простой топор. Рубил им сначала дрова. Крепкий такой инструмент. А уж если этим можно дерево рубить, то кости и подавно.'),
    ('W167', 'core', 'wt_axe', 'Топор берсерка', 'Berserker’s Axe', NULL, 'TRUE', NULL, NULL, 0, 'humans', 'P', '6d6', 6, NULL, 15, 2, NULL, 'XL', 1, '3', '960', 'На островах Скеллиге много волколаков и сирен, а ведьмаков мало. Добавь к этому показную храбрость обычного скеллигца, и получится вот эта штука. Двухметровый топор с огромным бородовидным лезвием, украшенным скеллигскими рунам.'),
    ('W168', 'core', 'wt_axe', 'Обезглавливатель', 'Decapitator', NULL, 'TRUE', NULL, NULL, 0, 'humans', 'U', '10d6', 10, NULL, 20, 2, NULL, 'XL', 3, '4', NULL, '')
),
ins_names AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    SELECT ck_id('witcher_cc.items.weapon.name.'||rd.w_id),
	       'items',
		   'weapon_names',
	       'ru',
		   rd.name_ru
	  FROM raw_data rd
	 WHERE nullif(rd.name_ru,'') is not null
	UNION ALL
    SELECT ck_id('witcher_cc.items.weapon.name.'||rd.w_id),
	       'items',
		   'weapon_names',
	       'en',
		   rd.name_en
	  FROM raw_data rd
	 WHERE nullif(rd.name_en,'') is not null
	UNION ALL
    SELECT ck_id('witcher_cc.items.weapon.description.'||rd.w_id),
	       'items',
		   'weapon_descriptions',
	       'ru',
		   rd.description_ru
	  FROM raw_data rd
	 WHERE nullif(rd.description_ru,'') is not null) foo
)
INSERT INTO wcc_item_weapons
  SELECT w_id
       , source_id AS dlc_dlc_id
	   , class_id AS ic_ic_id
	   , ck_id('witcher_cc.items.weapon.name.'||rd.w_id) AS name_id
	   , CASE WHEN is_piercing = 'TRUE' THEN True ELSE False END is_piercing
	   , CASE WHEN is_slashing = 'TRUE' THEN True ELSE False END is_slashing
	   , CASE WHEN is_bludgeoning = 'TRUE' THEN True ELSE False END is_bludgeoning
	   , CASE WHEN is_elemental = 'TRUE' THEN True ELSE False END is_elemental
	   , accuracy
	   , nullif(rd.crafted_by,'') crafted_by
	   , nullif(rd.availability,'') availability
	   , nullif(rd.dmg,'') dmg
	   , damage_dices
	   , damage_modifier
	   , reliability
	   , hands
	   , nullif(rd.range,'') range
	   , nullif(rd.concealment,'') concealment
	   , coalesce(enhancements,0) enhancements
	   , CAST(REPLACE(rd.weight, ',', '.') AS numeric) weight
	   , CAST(REPLACE(rd.price, ',', '.') AS numeric) price
	   , ck_id('witcher_cc.items.weapon.description.'||rd.w_id) description_id
    FROM raw_data rd;


-- ============================================================================
-- File: 004_wcc_item_effects.sql
-- ============================================================================

CREATE TABLE IF NOT EXISTS wcc_item_effects (
    e_id           varchar(10) PRIMARY KEY, -- e.g. 'E001'
    name_id        uuid NOT NULL,           -- ck_id('witcher_cc.items.effect.name.'||e_id)
    description_id uuid NOT NULL            -- ck_id('witcher_cc.items.effect.description.'||e_id)
);

COMMENT ON TABLE wcc_item_effects IS
  'Справочник эффектов для предметов/оружия. Локализуемые поля вынесены в i18n_text через детерминированные UUID (ck_id).';

COMMENT ON COLUMN wcc_item_effects.e_id IS
  'ID эффекта (например E001). Первичный ключ.';

COMMENT ON COLUMN wcc_item_effects.name_id IS
  'i18n UUID для названия эффекта. Генерируется детерминированно: ck_id(''witcher_cc.items.effect.name.''||e_id).';

COMMENT ON COLUMN wcc_item_effects.description_id IS
  'i18n UUID для описания эффекта. Генерируется детерминированно: ck_id(''witcher_cc.items.effect.description.''||e_id).';

WITH raw_data (e_id, name_ru, name_en, description_ru, description_en) AS ( VALUES
    ('E001', 'Бешенство', 'Fury', 'Цель атакует ближайшее существо каждый раунд, пока не пройдет проверку на устойчивость (СЛ18)', 'The target attacks the nearest creature each round until it passes a Stamina check (DC 18).'),
    ('E002', 'Ближний бой арбалетом', 'Crossbow Melee', 'Арбалет можно использовать как Дробящее оружие с тем же уроном, но штрафом к Точности (-1)', 'A crossbow can be used as a bludgeoning weapon with the same damage, but with an Accuracy penalty (-1).'),
    ('E003', 'Взрывное (<mod>м)', 'Explosive (<mod>m)', 'Урон по всем частям тела в радиусе <mod> метров', 'Deals damage to all body locations within a radius of <mod> meters.'),
    ('E004', 'Горение (<mod>)', 'Burning (<mod>)', 'С вероятностью <mod> поджигает цель при нанесении урона.', 'With a <mod>% chance, sets the target on fire when dealing damage.'),
    ('E005', 'Густая кровь (-<mod>)', 'Thick Blood (-<mod>)', 'Шанс кровотечения снижается на <mod>', 'Bleeding chance is reduced by <mod>.'),
    ('E006', 'Двимеритовая пыль', 'Dimeritium Dust', 'Не позволяет использовать магию в зоне действия в течение 20 ходов.', 'Prevents the use of magic in the affected area for 20 rounds.'),
    ('E007', 'Двойной урон ядом', 'Double Poison Damage', 'Если цель отравлена, то получает 6 урона ядом каждый ход вместо 3.', 'If the target is poisoned, it takes 6 poison damage each turn instead of 3.'),
    ('E008', 'Дезориентирующее (<mod>)', 'Disorienting (<mod>)', 'При ударе по туловищу или голове, цель должна совершить проверку Устойчивости со штрафом (<mod>)', 'When hit in the torso or head, the target must make a Stamina check with a (<mod>) penalty.'),
    ('E009', 'Длинное', 'Long', '', ''),
    ('E010', 'Доп. Атлетика (<mod>)', 'Bonus Athletics (<mod>)', '', ''),
    ('E011', 'Доп. Верховая езда (<mod>)', 'Bonus Riding (<mod>)', '', ''),
    ('E012', 'Доп. Внешний вид (<mod>)', 'Bonus Appearance (<mod>)', '', ''),
    ('E013', 'Доп. Здоровье (<mod>)', 'Bonus Health (<mod>)', '', ''),
    ('E014', 'Доп. Лидерство (<mod>)', 'Bonus Leadership (<mod>)', '', ''),
    ('E015', 'Доп. Наведение порчи (<mod>)', 'Bonus Hex Weaving (<mod>)', '', ''),
    ('E016', 'Доп. Надёжность (<mod>)', 'Bonus Reliability (<mod>)', '', ''),
    ('E017', 'Доп. Пункты Брони (<mod>)', 'Bonus Armor Points (<mod>)', '', ''),
    ('E018', 'Доп. Скорость ездового животного (<mod>)', 'Bonus Mount Speed (<mod>)', '', ''),
    ('E019', 'Доп. Скрытность (<mod>)', 'Bonus Stealth (<mod>)', '', ''),
    ('E020', 'Доп. слот на броне', 'Extra Armor Slot', 'Место на броне под глиф или руну. Максимум (3). Для добавления броня должна быть в идеально не поврежденном состоянии.', 'A slot on the armor for a glyph or rune. Maximum (3). To add it, the armor must be in perfect, undamaged condition.'),
    ('E021', 'Доп. Соблазнение (<mod>)', 'Bonus Seduction (<mod>)', '', ''),
    ('E022', 'Доп. Сопротивление магии (<mod>)', 'Bonus Magic Resistance (<mod>)', '', ''),
    ('E023', 'Доп. Сотворение заклинаний (<mod>)', 'Bonus Spell Casting (<mod>)', '', ''),
    ('E024', 'Доп. Точность (<mod>)', 'Bonus Accuracy (<mod>)', '', ''),
    ('E025', 'Доп. Урон (<mod>)', 'Bonus Damage (<mod>)', '', ''),
    ('E026', 'Доп. урон призракам (<mod>)', 'Bonus Damage vs Ghosts (<mod>)', '', ''),
    ('E027', 'Доп. Харизма (<mod>)', 'Bonus Charisma (<mod>)', '', ''),
    ('E028', 'Доп. Храбрость (<mod>)', 'Bonus Courage (<mod>)', '', ''),
    ('E029', 'Заморозка (<mod>)', 'Freeze (<mod>)', 'С вероятностью 30% замораживает цель при нанесении урона.', 'With a 30% chance, freezes the target when dealing damage.'),
    ('E030', 'Застревающий наконечник', 'Barbed Head', 'Кровотечение можно прекратить только совершив проверку Первой помощи (СЛ16) для извлечения наконечника из раны.', 'Bleeding can only be stopped by making a First Aid check (DC 16) to remove the head from the wound.'),
    ('E031', 'Захватное', 'Grappling', 'Можно использовать для захвата и подсечки противника в пределах дистанции.', 'Can be used to grapple and trip an opponent within reach.'),
    ('E032', 'Зима', 'Winter', 'С вероятностью 100% замораживает цель на 8 ходов. Можно снять проверкой на Силу (СЛ18) или будучи атакованным, тогда Доп. урон (2d6)', 'With a 100% chance, freezes the target for 8 rounds. Can be removed with a Strength check (DC 18), or by being attacked (then bonus damage (2d6)).'),
    ('E033', 'Командная перезарядка', 'Team Reload', 'Чтобы перезарядить это оружие, требуется потратить 2 действия. Эти действия могут быть совершены двумя разными персонажами.', 'Reloading this weapon requires spending 2 actions. These actions may be taken by two different characters.'),
    ('E034', 'Критическая казнь', 'Critical Execution', 'При крите ведьмачьим оружием тяжесть крита поднимается на ступень. Лёгкое ранение становится средним, среднее - тяжёлым, а тяжёлое - смертельным.', 'On a critical hit with a witcher weapon, the critical severity increases by one step: Light becomes Medium, Medium becomes Severe, and Severe becomes Deadly.'),
    ('E035', 'Критическая магия', 'Critical Magic', 'При крите ведьмачьим оружием можете пробросить проверку Сотворения заклинаний чтобы сотворить знак без штрафов и траты выносливости (кроме базовой цены сотворения знака).', 'On a critical hit with a witcher weapon, you may roll Spell Casting to cast a Sign without penalties and without spending Stamina (except the Sign’s base cost).'),
    ('E036', 'Критический натиск', 'Critical Rush', 'При крите ведьмачьим оружием можете пробросить проверку Разоружения или Подсечки без штрафов и траты выносливости.', 'On a critical hit with a witcher weapon, you may roll Disarm or Trip without penalties and without spending Stamina.'),
    ('E037', 'Критическое блокирование', 'Critical Shield Bash', 'Когда проброс попытки Парирования или Блокирования ведьмачьим щитом сильнее попытки атаки на 5 и больше, вы можете нанести удар щитом без штрафов и траты выносливости, который отбросит противника на 4м и собьет его с ног.', 'When your Parry or Block attempt with a witcher shield exceeds the attack roll by 5 or more, you may bash with the shield without penalties or Stamina cost, knocking the opponent back 4m and knocking them prone.'),
    ('E038', 'Критическое парирование', 'Critical Riposte', 'Когда проброс попытки Парирования ведьмачьим оружием сильнее попытки атаки на 5 и больше, вы можете нанести удар этим оружием без штрафов и траты выносливости.', 'When your Parry attempt with a witcher weapon exceeds the attack roll by 5 or more, you may strike with that weapon without penalties or Stamina cost.'),
    ('E039', 'Критическое ускорение', 'Critical Speed', 'При крите ведьмачьим оружием можете нанести дополнительный удар без штрафов и траты выносливости.', 'On a critical hit with a witcher weapon, you may make an additional strike without penalties or Stamina cost.'),
    ('E040', 'Кровопускающее (<mod>)', 'Bloodletting (<mod>)', 'С вероятностью <mod> вызывает у цели кровотечение при нанесении урона.', 'With a <mod>% chance, causes the target to bleed when dealing damage.'),
    ('E041', 'Крупный калибр', 'Large Caliber', 'Боеприпас предназначен для оружия "Скорпио".', 'This ammunition is intended for the weapon "Scorpio".'),
    ('E042', 'Ловящие лезвия', 'Catching Blades', 'При успешном блоке атаки этим оружием, оба оружия становятся бесполезными и не могут быть разделены до тех пор, пока противник не сможет пройти проверку Силы или Ловкости рук, которая превзойдет изначальную проверку Владения лёгкими клинками, или пока владелец не выпустит свое оружие.', 'On a successful block with this weapon, both weapons become locked together and cannot be separated until the opponent passes a Strength or Sleight of Hand check that exceeds the original Small Blade skill check, or until the wielder releases their weapon.'),
    ('E043', 'Лунная пыль', 'Moon Dust', 'Покрывает невидимые объекты россыпью частиц на 20 ходов, делая их видимыми, осязаемыми, а также цель не может регенировать и трансформироваться.', 'Covers invisible objects with a cloud of particles for 20 rounds, making them visible and tangible; the target also cannot regenerate or transform.'),
    ('E044', 'Магические путы', 'Magic Shackles', 'Невозможность невидимости, неосязаемости и телепорта при контакте с оружием.', 'Prevents invisibility, intangibility, and teleportation while in contact with the weapon.'),
    ('E045', 'Медленно перезаряжающееся', 'Slow Reload', 'Для перезарядки требуется 1 действие.', 'Reloading requires 1 action.'),
    ('E046', 'Метаемое (<mod>)', 'Thrown (<mod>)', 'Оружие можно метать на <mod> метра(ов)', 'The weapon can be thrown up to <mod> meter(s).'),
    ('E047', 'Метеоритное', 'Meteorite', 'Полный урон чудовищам, уязвимым к метеоритной стали. Доп. Надёжность снаряжения (+5)', 'Deals full damage to monsters vulnerable to meteorite steel. Bonus gear reliability (+5).'),
    ('E048', 'Метка вонючей краской', 'Stinky Paint Mark', 'Метка держится 1 сутки на расстоянии до полутора километров. Дополнительные +5 к проверке при попытке выследить или заметить цель. Можно смыть за 3 хода или перебить чем-то (духи, валяние в грязи), тогда Доп. Выслеживание падает до (+2).', 'The mark lasts 1 day at a distance of up to 1.5 km. Grants +5 to checks to track or notice the target. Can be washed off in 3 rounds or masked (perfume, rolling in mud), reducing the tracking bonus to (+2).'),
    ('E049', 'Незаметное', 'Inconspicuous', 'Дополнительные (+2) при попытке скрыть это оружие.', 'Grants an additional (+2) when attempting to conceal this weapon.'),
    ('E050', 'Несмертельное', 'Nonlethal', 'Можно использовать для нанесения несмертельного урона без штрафов.', 'Can be used to deal nonlethal damage without penalties.'),
    ('E051', 'Облако газа', 'Gas Cloud', 'Создает на 3 хода взрывоопасное облако газа, которое может дрейфовать в случайном направлении. При взрыве наносит 5d6 урона.', 'Creates an explosive gas cloud for 3 rounds that may drift in a random direction. If ignited, it deals 5d6 damage.'),
    ('E052', 'Огнеупорный', 'Fireproof', 'Элемент брони не получает повреждений от огненных атак.', 'This armor element takes no damage from fire attacks.'),
    ('E053', 'Ограничение зрения', 'Restricted Vision', 'При опущенном забрале, конус поля зрения сужается до 90 градусов и для ведьмаков отключается способность "Обостренные чувства".', 'With the visor down, the field of view narrows to a 90-degree cone and witchers lose the "Heightened Senses" ability.'),
    ('E054', 'Опутывающее', 'Entangling', 'Опутывает цель. Опутанная цель снижает Скор на 5 и получает (-2) штраф ко всем физическим действиям. Чтобы высвободиться нужен проброс со СЛ18 Уклонение/Изворотливость/Борьбу или 1 действие помощи кого-то другого.', 'Entangles the target. An entangled target reduces SPD by 5 and takes a (-2) penalty to all physical actions. To break free requires a DC 18 Dodge/Escape Artist/Wrestling check, or 1 action of help from another character.'),
    ('E055', 'Отравленное (<mod>)', 'Poisoned (<mod>)', 'С вероятностью <mod> отравляет цель при нанесении урона', 'With a <mod>% chance, poisons the target when dealing damage.'),
    ('E056', 'Отторжение магии', 'Magic Rejection', 'Если доспех надет на адепта магии, то скованность движений доспеха равна (5).', 'If the armor is worn by a magic adept, the armor’s encumbrance is (5).'),
    ('E057', 'Ошеломление (<mod>)', 'Stun (<mod>)', 'С вероятностью <mod> ошеломляет цель при нанесении урона', 'With a <mod>% chance, stuns the target when dealing damage.'),
    ('E058', 'Парирующее', 'Parrying', '(-2) к штрафу при парировании.', 'Reduces the Parry penalty by (-2).'),
    ('E059', 'Пахучее', 'Scented', 'Пока боеприпас остаётся в теле цели, выслеживание по запаху не требует проверок, если следу менее половины суток.', 'While the ammunition remains in the target’s body, tracking by smell requires no checks if the trail is less than half a day old.'),
    ('E060', 'Перелом ноги', 'Broken Leg', 'Критическое ранение "Перелом ноги" при отсутстви брони ног.', 'Inflicts the "Broken Leg" critical injury if the target has no leg armor.'),
    ('E061', 'Подвижная перезарядка', 'Mobile Reload', '', ''),
    ('E062', 'Полное укрытие', 'Full Cover', 'Если присесть за щитом, то щит рассматривается как укрытие, снижая любой проходящий урон на количество своей прочности.', 'If you crouch behind the shield, it counts as cover, reducing any incoming damage by its durability.'),
    ('E063', 'Пробивающее броню', 'Armor Piercing', 'Игнорирует сопротивление урону любой брони, по которой оно попадает.', 'Ignores the damage resistance of any armor it hits.'),
    ('E064', 'Пробивающее броню (+)', 'Armor Piercing (+)', 'Игнорирует сопротивление урону любой брони и половину прочности брони, по которой оно попадает.', 'Ignores the damage resistance of any armor it hits and half of that armor’s durability.'),
    ('E065', 'Прочность Чернобога', 'Blackbog Durability', 'С вероятностью 50% оружие не получает урон, когда должно.', 'With a 50% chance, the weapon takes no damage when it otherwise would.'),
    ('E066', 'Разделяющееся (<mod>)', 'Splitting', 'При выстреле связка снарядов разделяется на <mod> отдельных. Цель получает дополнительное попадание в случайную часть тела за каждое очко выше защиты до <mod>.', 'When fired, the bundle splits into <mod> separate projectiles. The target suffers an additional hit to a random body location for each point your roll exceeds the target’s defense (up to <mod>).'),
    ('E067', 'Разрушающее', 'Sundering', 'При попадании это оружие наносит 1d6/2 урона Прочности брони.', 'On a hit, this weapon deals 1d6/2 damage to armor durability.'),
    ('E068', 'Рвение Перуна', 'Perun’s Zeal', 'Удваивает количество получаемых дайсов адреналина.', 'Doubles the number of adrenaline dice gained.'),
    ('E069', 'Реликвия (<mod>)', 'Relic (<mod>)', 'Если пробросить Образование со СЛ<mod>, то вы вспомните историю этой реликвии', 'If you roll Education at DC <mod>, you recall the history of this relic.'),
    ('E070', 'Рукопашное', 'Brawling', 'Такое оружие использует навык Борьба. Его урон прибавляется к урону от атаки без оружия.', 'This weapon uses the Wrestling skill. Its damage is added to your unarmed attack damage.'),
    ('E071', 'Сбалансированное', 'Balanced', 'При крит.ранении по цели бросаете 2d6+2 вместо 2d6 и 1d6+1 вместо 1d6.', 'When rolling for critical injuries on the target, roll 2d6+2 instead of 2d6, and 1d6+1 instead of 1d6.'),
    ('E072', 'Свечение', 'Glow', 'В радиусе пяти метров повышает уровень освещенности на 1.', 'Within a 5-meter radius, increases the light level by 1.'),
    ('E073', 'Серебряное (<mod>)', 'Silvered (<mod>)', 'Доп.урон <mod> по существам, уязвимым к серебру.', 'Deals bonus damage <mod> to creatures vulnerable to silver.'),
    ('E074', 'Скользкий пол', 'Slippery Floor', 'Цель с ногами бросает Атлетику чтобы не оказаться сбитой с ног. СЛ14 для двуногого, СЛ12 для четвероногого, СЛ10 для остальных.', 'A target with legs rolls Athletics to avoid being knocked prone: DC 14 for bipeds, DC 12 for quadrupeds, DC 10 for others.'),
    ('E075', 'Сложные раны', 'Complex Wounds', 'Проверки стабилизации критических ранений получают (+3) к Сложности.', 'Stabilization checks for critical wounds gain (+3) Difficulty.'),
    ('E076', 'Сопротивление (Д)', 'Resistance (B)', 'Урон атак с дробящим уроном снижается вдвое.', 'Damage from bludgeoning attacks is halved.'),
    ('E077', 'Сопротивление (К)', 'Resistance (P)', 'Урон атак с колящим уроном снижается вдвое.', 'Damage from piercing attacks is halved.'),
    ('E078', 'Сопротивление (Р)', 'Resistance (S)', 'Урон атак с рубящим уроном снижается вдвое.', 'Damage from slashing attacks is halved.'),
    ('E079', 'Сопротивление (С)', 'Resistance (E)', 'Урон атак со стихийным уроном снижается вдвое.', 'Damage from elemental attacks is halved.'),
    ('E080', 'Сопротивление кровотечению', 'Bleeding Resistance', 'Урон от эффектов кровотечения уменьшен вдвое.', 'Damage from bleeding effects is halved.'),
    ('E081', 'Сопротивление огню', 'Fire Resistance', 'Урон от атак огнем снижается вдвое.', 'Damage from fire attacks is halved.'),
    ('E082', 'Сопротивление отравлению', 'Poison Resistance', 'Урон от эффектов отравления уменьшен вдвое.', 'Damage from poison effects is halved.'),
    ('E083', 'Таранящее', 'Charging', 'В случае атаки оружием верхом и с резбега, количество бонусных кубов урона (до 5) равно расстоянию до цели, т.е. не нужно делить расстояние пополам как для обычного оружия.', 'When attacking while mounted and with a run-up, the number of bonus damage dice (up to 5) equals the distance to the target; you do not halve the distance as with normal weapons.'),
    ('E084', 'Текстиль низушков', 'Halfling Textile', 'Доспех выглядит как обычная одежда. Можно понять, что это броня при успешной проверке Внимания со СЛ20.', 'The armor looks like ordinary clothing. You can tell it is armor with a successful Awareness check (DC 20).'),
    ('E085', 'Удар щитом', 'Shield Strike', 'Пробросьте Ближний бой. При успехе цель получает смертельный урон, равный урону ударом рукой.', 'Roll Melee. On success, the target takes lethal damage equal to your fist strike damage.'),
    ('E086', 'Удар щитом (<mod>)', 'Shield Strike (<mod>)', 'Пробросьте Ближний бой. При успехе цель получает смертельный урон, равный урону ударом рукой и дополнительно (<mod>).', 'Roll Melee. On success, the target takes lethal damage equal to your fist strike damage, plus (<mod>).'),
    ('E087', 'Улучшение лечения (+1)', 'Improved Healing (+1)', 'При каждом лечении вы получаете 1 дополнительный Пункт Здоровья.', 'Each time you heal, you gain 1 additional Health Point.'),
    ('E088', 'Усиление магии', 'Magic Amplification', 'При атаке магией вы можете выбрать или СЛ защиты от магии возрастет на (+3), или урон возрастет на 1d6', 'When attacking with magic, you may choose either to increase the DC to defend against your spell by (+3), or increase the damage by 1d6.'),
    ('E089', 'Устанавливаемое', 'Deployable', 'Для использования оружие нужно разложить за 1 действие. Переносить разложенное оружие нельзя. Чтобы собрать нужно также потратить 1 действие.', 'To use this weapon, you must deploy it with 1 action. You cannot carry it while deployed. Packing it up also requires 1 action.'),
    ('E090', 'Установка на подставку', 'Stand Mount', 'Щит может стоять сам без поддержки (требует действие на установку, переустановку), но тогда используется только как укрытие (без блокирования). Падает при получении урона больше половины прочности.', 'A shield can stand on its own (requires an action to set up or reposition), but then it is used only as cover (no blocking). It falls if it takes damage greater than half its durability.'),
    ('E091', 'Фокусирующее (+)', 'Focusing (+)', '(+2) к СЛ проверок против вашего заклинания', '(+2) to the DC of checks made against your spell.'),
    ('E092', 'Фокусирующее (<mod>)', 'Focusing (<mod>)', 'При сотворении магии с помощью этого оружия вычтите <mod> из стоимости заклинания в Выносливости.', 'When casting magic using this weapon, subtract <mod> from the spell’s Stamina cost.'),
    ('E093', 'Шприц', 'Syringe', 'Это оружие может быть заряжено флаконом с любым ядом или эликсиром. (+3) к СЛ для избавления от яда или (+3 хода) к продолжительности действия эликсира', 'This weapon can be loaded with a vial of any poison or potion. Grants (+3) to the DC to resist/remove the poison, or (+3 rounds) to the potion’s duration.'),
    ('E094', 'Эффект синергии "Баланс"', 'Synergy Effect "Balance"', 'Изменение Скованности Движений брони на (-1)', 'Changes armor encumbrance by (-1).'),
    ('E095', 'Эффект синергии "Воздаяние"', 'Synergy Effect "Retribution"', 'При получении урона атакующий полчает (3) неблокируемого урона в туловище.', 'When you take damage, the attacker takes (3) unblockable damage to the torso.'),
    ('E096', 'Эффект синергии "Закрепление"', 'Synergy Effect "Reinforcement"', 'Доп. Надёжность экипировки (+5)', 'Bonus gear reliability (+5).'),
    ('E097', 'Эффект синергии "Истощение"', 'Synergy Effect "Exhaustion"', 'Доп. Нелетальный урон (+1d6) магией при использовании оружия как фокусирующее.', 'Bonus nonlethal magic damage (+1d6) when using the weapon as a focus.'),
    ('E098', 'Эффект синергии "Кольцо"', 'Synergy Effect "Ring"', 'Атакующее существо не получает бонусов при атаке за пределами вашего обзора.', 'An attacking creature gains no bonuses when attacking from outside your field of view.'),
    ('E099', 'Эффект синергии "Обновление"', 'Synergy Effect "Refresh"', 'Восстановление выносливости на значение Отдых при убийстве врага этим оружием.', 'Restore Stamina equal to your Rest value when you kill an enemy with this weapon.'),
    ('E100', 'Эффект синергии "Отражение"', 'Synergy Effect "Reflection"', 'Даёт навык Отбивание стрел с двойным штрафом. Или Доп. Отбивание стрел (+2), если оно уже есть.', 'Grants the Deflect Arrows skill with double penalty, or Bonus Deflect Arrows (+2) if you already have it.'),
    ('E101', 'Эффект синергии "Продление"', 'Synergy Effect "Extension"', 'Удваивает количество дайсов для получение времени действия магии, если оружие использовано как фокусирующее.', 'Doubles the number of dice used to determine the duration of magic if the weapon is used as a focus.'),
    ('E102', 'Эффект синергии "Пылание"', 'Synergy Effect "Blazing"', 'Смена типа урона на стихийный (огонь). Не поджигает цель.', 'Changes the damage type to elemental (fire). Does not set the target on fire.'),
    ('E103', 'Эффект синергии "Рассечение"', 'Synergy Effect "Cleave"', 'Доп. Разрушение брони или щита (+1) при пробитии.', 'Bonus Sunder Armor or Shield (+1) on penetration.'),
    ('E104', 'Эффект синергии "Сияние"', 'Synergy Effect "Radiance"', 'Доспех сияет, доводя уровень освещенности вокруг до дневного света. Нужно (1) действие для активации на 30 минут. На монстров влияет как Солнце.', 'The armor shines, raising the surrounding light level to daylight. Requires (1) action to activate for 30 minutes. Affects monsters as sunlight.'),
    ('E105', 'Эффект синергии "Спокойствие"', 'Synergy Effect "Calm"', 'Снижает вдвое затраты Выносливости на использование дайсов Адреналин.', 'Halves the Stamina cost of spending Adrenaline dice.'),
    ('E106', 'Эффект синергии "Тяжесть"', 'Synergy Effect "Heaviness"', 'Доп. Прочность Брони (+2), Скованность Движений брони удваивается.', 'Bonus armor durability (+2); armor encumbrance is doubled.'),
    ('E107', 'Яркая вспышка', 'Bright Flash', 'Штраф к Устойчивости к ослеплению (-2). Цель получает слепоту на 6 ходов.', 'Penalty to Stamina vs blinding (-2). The target is blinded for 6 rounds.'),
    ('E108', 'Яркая вспышка (+)', 'Bright Flash (+)', 'Цель получает слепоту на 5 ходов. Если цель обладает ночным зрением, то получает дополнительные 5 ходов слепоты и ошеломление (дезориентацию для ночного зрения (+)).', 'The target is blinded for 5 rounds. If the target has night vision, it suffers an additional 5 rounds of blindness and is stunned (disoriented for night vision (+)).')
),
ins_names AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    SELECT ck_id('witcher_cc.items.effect.name.'||rd.e_id),
           'items',
           'effect_names',
           'ru',
           rd.name_ru
      FROM raw_data rd
     WHERE nullif(rd.name_ru,'') is not null
    UNION ALL
    SELECT ck_id('witcher_cc.items.effect.name.'||rd.e_id),
           'items',
           'effect_names',
           'en',
           rd.name_en
      FROM raw_data rd
     WHERE nullif(rd.name_en,'') is not null
  ) foo
  ON CONFLICT (id, lang) DO NOTHING
),
ins_descriptions AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    SELECT ck_id('witcher_cc.items.effect.description.'||rd.e_id),
           'items',
           'effect_descriptions',
           'ru',
           rd.description_ru
      FROM raw_data rd
     WHERE nullif(rd.description_ru,'') is not null
    UNION ALL
    SELECT ck_id('witcher_cc.items.effect.description.'||rd.e_id),
           'items',
           'effect_descriptions',
           'en',
           rd.description_en
      FROM raw_data rd
     WHERE nullif(rd.description_en,'') is not null
  ) foo
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO wcc_item_effects (e_id, name_id, description_id)
SELECT rd.e_id,
       ck_id('witcher_cc.items.effect.name.'||rd.e_id) AS name_id,
       ck_id('witcher_cc.items.effect.description.'||rd.e_id) AS description_id
  FROM raw_data rd
ON CONFLICT (e_id) DO UPDATE
SET name_id = EXCLUDED.name_id,
    description_id = EXCLUDED.description_id;





-- ============================================================================
-- File: 005_wcc_item_effect_conditions.sql
-- ============================================================================

CREATE TABLE IF NOT EXISTS wcc_item_effect_conditions (
    ec_id          varchar(10) PRIMARY KEY, -- e.g. 'EC001'
    description_id uuid NOT NULL            -- ck_id('witcher_cc.items.effect_condition.description.'||ec_id)
);

COMMENT ON TABLE wcc_item_effect_conditions IS
  'Справочник условий применения/активации эффектов. Локализуемое описание хранится в i18n_text через детерминированный UUID (ck_id).';

COMMENT ON COLUMN wcc_item_effect_conditions.ec_id IS
  'ID условия эффекта (например EC001). Первичный ключ.';

COMMENT ON COLUMN wcc_item_effect_conditions.description_id IS
  'i18n UUID для описания условия. Генерируется детерминированно: ck_id(''witcher_cc.items.effect_condition.description.''||ec_id).';

WITH raw_data (ec_id, description_ru, description_en) AS ( VALUES
    ('EC001', 'Если оружие раскалено', 'If the weapon is heated'),
    ('EC002', 'Если оружие горит', 'If the weapon is burning'),
    ('EC003', 'При альпинизме', 'While climbing'),
    ('EC004', 'Если в седле', 'While mounted'),
    ('EC005', 'В дикой среде', 'In the wilderness'),
    ('EC006', 'Огонь', 'Fire'),
    ('EC007', 'Вода', 'Water'),
    ('EC008', 'Земля', 'Earth'),
    ('EC009', 'Воздух', 'Air')
),
ins_descriptions AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    SELECT ck_id('witcher_cc.items.effect_condition.description.'||rd.ec_id),
           'items',
           'effect_condition_descriptions',
           'ru',
           rd.description_ru
      FROM raw_data rd
     WHERE nullif(rd.description_ru,'') is not null
    UNION ALL
    SELECT ck_id('witcher_cc.items.effect_condition.description.'||rd.ec_id),
           'items',
           'effect_condition_descriptions',
           'en',
           rd.description_en
      FROM raw_data rd
     WHERE nullif(rd.description_en,'') is not null
  ) foo
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO wcc_item_effect_conditions (ec_id, description_id)
SELECT rd.ec_id,
       ck_id('witcher_cc.items.effect_condition.description.'||rd.ec_id) AS description_id
  FROM raw_data rd
ON CONFLICT (ec_id) DO UPDATE
SET description_id = EXCLUDED.description_id;





-- ============================================================================
-- File: 006_wcc_item_weapons_to_effects.sql
-- ============================================================================

CREATE TABLE IF NOT EXISTS wcc_item_weapons_to_effects (
    w_w_id    varchar(10) NOT NULL REFERENCES wcc_item_weapons(w_id) ON DELETE CASCADE,
    e_e_id    varchar(10) NOT NULL REFERENCES wcc_item_effects(e_id) ON DELETE CASCADE,
    ec_ec_id  varchar(10) REFERENCES wcc_item_effect_conditions(ec_id) ON DELETE SET NULL,
    modifier  varchar(50)
);

COMMENT ON TABLE wcc_item_weapons_to_effects IS
  'Связь оружия с эффектами. Каждая строка представляет один эффект для одного оружия.';

COMMENT ON COLUMN wcc_item_weapons_to_effects.w_w_id IS
  'ID оружия из wcc_item_weapons.';

COMMENT ON COLUMN wcc_item_weapons_to_effects.e_e_id IS
  'ID эффекта из wcc_item_effects.';

COMMENT ON COLUMN wcc_item_weapons_to_effects.ec_ec_id IS
  'ID условия эффекта из wcc_item_effect_conditions (опционально).';

COMMENT ON COLUMN wcc_item_weapons_to_effects.modifier IS
  'Модификатор эффекта (например, "+2", "75%", "2м" и т.д.).';

INSERT INTO wcc_item_weapons_to_effects (w_w_id, e_e_id, ec_ec_id, modifier) VALUES
-- W001: Медленно перезаряжающееся
('W001', 'E045', NULL, NULL),

-- W012: Медленно перезаряжающееся
('W012', 'E045', NULL, NULL),

-- W002: Медленно перезаряжающееся Пробивающее броню
('W002', 'E045', NULL, NULL),
('W002', 'E063', NULL, NULL),

-- W009: Медленно перезаряжающееся
('W009', 'E045', NULL, NULL),

-- W010: Медленно перезаряжающееся
('W010', 'E045', NULL, NULL),

-- W014: Реликвия (16) Отравленное (100%) Доп. Наведение порчи (+3) Доп. Сопротивление магии(+3)
('W014', 'E069', NULL, '16'),
('W014', 'E055', NULL, '100%'),
('W014', 'E015', NULL, '+3'),
('W014', 'E022', NULL, '+3'),

-- W003: Медленно перезаряжающееся Разрушающее
('W003', 'E045', NULL, NULL),
('W003', 'E067', NULL, NULL),

-- W005: Медленно перезаряжающееся Отравленное (75%)
('W005', 'E045', NULL, NULL),
('W005', 'E055', NULL, '75%'),

-- W007: Медленно перезаряжающееся Кровопускающее (75%)
('W007', 'E045', NULL, NULL),
('W007', 'E040', NULL, '75%'),

-- W011: Медленно перезаряжающееся
('W011', 'E045', NULL, NULL),

-- W004: Медленно перезаряжающееся Пробивающее броню (+)
('W004', 'E045', NULL, NULL),
('W004', 'E064', NULL, NULL),

-- W006: Медленно перезаряжающееся Сбалансированное
('W006', 'E045', NULL, NULL),
('W006', 'E071', NULL, NULL),

-- W008: Медленно перезаряжающееся
('W008', 'E045', NULL, NULL),

-- W013: Командная перезарядка Устанавливаемое
('W013', 'E033', NULL, NULL),
('W013', 'E089', NULL, NULL),

-- W015: Пробивающее броню
('W015', 'E063', NULL, NULL),

-- W021: Несмертельное
('W021', 'E050', NULL, NULL),

-- W022: Кровопускающее (100%)
('W022', 'E040', NULL, '100%'),

-- W024: (пусто)
-- Нет эффектов

-- W016: Взрывное (2м)
('W016', 'E003', NULL, '2'),

-- W017: Пахучее
('W017', 'E059', NULL, NULL),

-- W019: Разрушающее
('W019', 'E067', NULL, NULL),

-- W020: Разделяющееся (3)
('W020', 'E066', NULL, '3'),

-- W025: Кровопускающее (100%) Застревающий наконечник
('W025', 'E040', NULL, '100%'),
('W025', 'E030', NULL, NULL),

-- W023: Серебряное (2d6)
('W023', 'E073', NULL, '2d6'),

-- W018: Сложные раны
('W018', 'E075', NULL, NULL),

-- W026: Крупный калибр Пробивающее броню
('W026', 'E041', NULL, NULL),
('W026', 'E063', NULL, NULL),

-- W027: Крупный калибр Разрушающее
('W027', 'E041', NULL, NULL),
('W027', 'E067', NULL, NULL),

-- W028: Крупный калибр
('W028', 'E041', NULL, NULL),

-- W029: Двимеритовая пыль
('W029', 'E006', NULL, NULL),

-- W030: Горение (25%)
('W030', 'E004', NULL, '25%'),

-- W031: Лунная пыль
('W031', 'E043', NULL, NULL),

-- W032: Яркая вспышка
('W032', 'E107', NULL, NULL),

-- W033: Зима
('W033', 'E032', NULL, NULL),

-- W035: Облако газа Горение (75%)
('W035', 'E051', NULL, NULL),
('W035', 'E004', NULL, '75%'),

-- W036: Горение (100%)
('W036', 'E004', NULL, '100%'),

-- W037: Отравленное (100%) Двойной урон ядом
('W037', 'E055', NULL, '100%'),
('W037', 'E007', NULL, NULL),

-- W034: Яркая вспышка (+)
('W034', 'E108', NULL, NULL),

-- W040: (пусто)
-- Нет эффектов

-- W042: Горение (15%) [если раскалено]
('W042', 'E004', 'EC001', '15%'),

-- W043: Захватное Кровопускающее (15%)
('W043', 'E031', NULL, NULL),
('W043', 'E040', NULL, '15%'),

-- W045: Захватное Доп. Атлетика при альпинизме (+2)
('W045', 'E031', NULL, NULL),
('W045', 'E010', 'EC003', '+2'),

-- W047: Длинное Захватное
('W047', 'E009', NULL, NULL),
('W047', 'E031', NULL, NULL),

-- W038: Кровопускающее (15%)
('W038', 'E040', NULL, '15%'),

-- W048: Захватное
('W048', 'E031', NULL, NULL),

-- W041: Длинное Захватное
('W041', 'E009', NULL, NULL),
('W041', 'E031', NULL, NULL),

-- W044: Длинное Захватное Кровопускающее (100%)
('W044', 'E009', NULL, NULL),
('W044', 'E031', NULL, NULL),
('W044', 'E040', NULL, '100%'),

-- W039: Захватное Кровопускающее (30%)
('W039', 'E031', NULL, NULL),
('W039', 'E040', NULL, '30%'),

-- W046: (пусто)
-- Нет эффектов

-- W051: Горение (25%) [если горит], Свечение
('W051', 'E004', 'EC002', '25%'),
('W051', 'E072', NULL, NULL),

-- W049: Кровопускающее (15%) Метаемое (4)
('W049', 'E040', NULL, '15%'),
('W049', 'E046', NULL, '4'),

-- W052: Шприц Пробивающее броню
('W052', 'E093', NULL, NULL),
('W052', 'E063', NULL, NULL),

-- W050: Опутывающее Магические путы Метаемое (4)
('W050', 'E054', NULL, NULL),
('W050', 'E044', NULL, NULL),
('W050', 'E046', NULL, '4'),

-- W055: Длинное Метаемое (Тел*2)
('W055', 'E009', NULL, NULL),
('W055', 'E046', NULL, 'Тел*2'),

-- W057: Длинное
('W057', 'E009', NULL, NULL),

-- W062: Длинное
('W062', 'E009', NULL, NULL),

-- W058: Длинное Дезориентирующее (-2)
('W058', 'E009', NULL, NULL),
('W058', 'E008', NULL, '-2'),

-- W066: Длинное Кровопускающее (25%)
('W066', 'E009', NULL, NULL),
('W066', 'E040', NULL, '25%'),

-- W067: Реликвия (18) Длинное Фокусирующее (+) (вода) Заморозка (75%)
('W067', 'E069', NULL, '18'),
('W067', 'E009', NULL, NULL),
('W067', 'E091', 'EC007', NULL),
('W067', 'E029', NULL, '75%'),

-- W064: Длинное
('W064', 'E009', NULL, NULL),

-- W053: Длинное
('W053', 'E009', NULL, NULL),

-- W061: Длинное Кровопускающее (25%)
('W061', 'E009', NULL, NULL),
('W061', 'E040', NULL, '25%'),

-- W054: Длинное Таранящее
('W054', 'E009', NULL, NULL),
('W054', 'E083', NULL, NULL),

-- W063: Длинное Таранящее Несмертельное
('W063', 'E009', NULL, NULL),
('W063', 'E083', NULL, NULL),
('W063', 'E050', NULL, NULL),

-- W056: Длинное
('W056', 'E009', NULL, NULL),

-- W059: Длинное Несмертельное
('W059', 'E009', NULL, NULL),
('W059', 'E050', NULL, NULL),

-- W060: Несмертельное Захватное Метаемое (Тел*2)
('W060', 'E050', NULL, NULL),
('W060', 'E031', NULL, NULL),
('W060', 'E046', NULL, 'Тел*2'),

-- W065: Длинное Захватное
('W065', 'E009', NULL, NULL),
('W065', 'E031', NULL, NULL),

-- W069: (пусто)
-- Нет эффектов

-- W072: Рукопашное
('W072', 'E070', NULL, NULL),

-- W074: Захватное Метеоритное
('W074', 'E031', NULL, NULL),
('W074', 'E047', NULL, NULL),

-- W075: Пробивающее броню
('W075', 'E063', NULL, NULL),

-- W076: Дезориентирующее (-2) Метеоритное
('W076', 'E008', NULL, '-2'),
('W076', 'E047', NULL, NULL),

-- W078: Реликвия (18) Дезориентирующее (-4) Сбалансированное
('W078', 'E069', NULL, '18'),
('W078', 'E008', NULL, '-4'),
('W078', 'E071', NULL, NULL),

-- W070: Несмертельное
('W070', 'E050', NULL, NULL),

-- W077: Несмертельное Доп. Скорость ездового животного (+1)
('W077', 'E050', NULL, NULL),
('W077', 'E018', NULL, '+1'),

-- W071: Таранящее
('W071', 'E083', NULL, NULL),

-- W068: Разрушающее
('W068', 'E067', NULL, NULL),

-- W073: Захватное Пробивающее броню
('W073', 'E031', NULL, NULL),
('W073', 'E063', NULL, NULL),

-- W089: Незаметное
('W089', 'E049', NULL, NULL),

-- W082: (пусто)
-- Нет эффектов

-- W083: Кровопускающее (25%)
('W083', 'E040', NULL, '25%'),

-- W080: Кровопускающее (25%) Пробивающее броню
('W080', 'E040', NULL, '25%'),
('W080', 'E063', NULL, NULL),

-- W084: (пусто)
-- Нет эффектов

-- W087: Пробивающее броню
('W087', 'E063', NULL, NULL),

-- W090: Реликвия (15) Кровопускающее (75%) Отравленное (100%) Метаемое (Тел*2)
('W090', 'E069', NULL, '15'),
('W090', 'E040', NULL, '75%'),
('W090', 'E055', NULL, '100%'),
('W090', 'E046', NULL, 'Тел*2'),

-- W088: Парирующее Серебряное (1d6+2)
('W088', 'E058', NULL, NULL),
('W088', 'E073', NULL, '1d6+2'),

-- W079: Парирующее
('W079', 'E058', NULL, NULL),

-- W081: Парирующее
('W081', 'E058', NULL, NULL),

-- W085: Кровопускающее (25%)
('W085', 'E040', NULL, '25%'),

-- W086: Ловящие лезвия
('W086', 'E042', NULL, NULL),

-- W092: Перелом ноги
('W092', 'E060', NULL, NULL),

-- W091: Бешенство
('W091', 'E001', NULL, NULL),

-- W093: Кровопускающее (60%)
('W093', 'E040', NULL, '60%'),

-- W094: (пусто)
-- Нет эффектов

-- W095: Метка вонючей краской
('W095', 'E048', NULL, NULL),

-- W097: Горение (75%)
('W097', 'E004', NULL, '75%'),

-- W098: Зима
('W098', 'E032', NULL, NULL),

-- W096: Скользкий пол
('W096', 'E074', NULL, NULL),

-- W099: (пусто)
-- Нет эффектов

-- W100: (пусто)
-- Нет эффектов

-- W102: (пусто)
-- Нет эффектов

-- W103: Пробивающее броню (+)
('W103', 'E064', NULL, NULL),

-- W104: (пусто)
-- Нет эффектов

-- W106: Реликвия (17) Сбалансированное Заморозка (75%) Доп. урон призракам (+3)
('W106', 'E069', NULL, '17'),
('W106', 'E071', NULL, NULL),
('W106', 'E029', NULL, '75%'),
('W106', 'E026', NULL, '+3'),

-- W101: Пробивающее броню Сбалансированное
('W101', 'E063', NULL, NULL),
('W101', 'E071', NULL, NULL),

-- W105: Пробивающее броню
('W105', 'E063', NULL, NULL),

-- W107: (пусто)
-- Нет эффектов

-- W108: (пусто)
-- Нет эффектов

-- W109: (пусто)
-- Нет эффектов

-- W110: Отравленное (90%) Сбалансированное
('W110', 'E055', NULL, '90%'),
('W110', 'E071', NULL, NULL),

-- W112: (пусто)
-- Нет эффектов

-- W122: (пусто)
-- Нет эффектов

-- W126: (пусто)
-- Нет эффектов

-- W127: (пусто)
-- Нет эффектов

-- W116: (пусто)
-- Нет эффектов

-- W146: (пусто)
-- Нет эффектов

-- W113: Кровопускающее (50%)
('W113', 'E040', NULL, '50%'),

-- W117: Кровопускающее (25%)
('W117', 'E040', NULL, '25%'),

-- W118: Сбалансированное
('W118', 'E071', NULL, NULL),

-- W120: Кровопускающее (25%)
('W120', 'E040', NULL, '25%'),

-- W121: Кровопускающее (25%)
('W121', 'E040', NULL, '25%'),

-- W124: Метеоритное Сбалансированное
('W124', 'E047', NULL, NULL),
('W124', 'E071', NULL, NULL),

-- W128: Серебряное (3d6)
('W128', 'E073', NULL, '3d6'),

-- W135: Метеоритное Пробивающее броню
('W135', 'E047', NULL, NULL),
('W135', 'E063', NULL, NULL),

-- W143: Кровопускающее (50%)
('W143', 'E040', NULL, '50%'),

-- W145: (пусто)
-- Нет эффектов

-- W147: Реликвия (16) Кровопускающее (75%) Пробивающее броню
('W147', 'E069', NULL, '16'),
('W147', 'E040', NULL, '75%'),
('W147', 'E063', NULL, NULL),

-- W148: Реликвия (18) Метеоритное Пробивающее броню Дезориентирующее (-2) Фокусирующее (+) (воздух)
('W148', 'E069', NULL, '18'),
('W148', 'E047', NULL, NULL),
('W148', 'E063', NULL, NULL),
('W148', 'E008', NULL, '-2'),
('W148', 'E091', 'EC009', NULL),

-- W149: Реликвия (20) Кровопускающее (75%) Доп. Здоровье (+25) Сбалансированное Фокусирующее (+) (вода)
('W149', 'E069', NULL, '20'),
('W149', 'E040', NULL, '75%'),
('W149', 'E013', NULL, '+25'),
('W149', 'E071', NULL, NULL),
('W149', 'E091', 'EC007', NULL),

-- W150: Реликвия (18) Серебряное (7d6+4) Фокусирующее (+)
('W150', 'E069', NULL, '18'),
('W150', 'E073', NULL, '7d6+4'),
('W150', 'E091', NULL, NULL),

-- W151: Реликвия (22) Серебряное (6d6+4) Сбалансированное Фокусирующее (+) (вода, земля) Заморозка (75%)
('W151', 'E069', NULL, '22'),
('W151', 'E073', NULL, '6d6+4'),
('W151', 'E071', NULL, NULL),
('W151', 'E091', 'EC007', NULL),
('W151', 'E091', 'EC008', NULL),
('W151', 'E029', NULL, '75%'),

-- W152: Реликвия (16) Метеоритное Пробивающее броню Сбалансированное
('W152', 'E069', NULL, '16'),
('W152', 'E047', NULL, NULL),
('W152', 'E063', NULL, NULL),
('W152', 'E071', NULL, NULL),

-- W153: Реликвия (19) Серебряное (6d6+4) Ошеломление (75%) Фокусирующее (+) (вода, огонь)
('W153', 'E069', NULL, '19'),
('W153', 'E073', NULL, '6d6+4'),
('W153', 'E057', NULL, '75%'),
('W153', 'E091', 'EC007', NULL),
('W153', 'E091', 'EC006', NULL),

-- W142: (пусто)
-- Нет эффектов

-- W114: Несмертельное
('W114', 'E050', NULL, NULL),

-- W115: (пусто)
-- Нет эффектов

-- W125: Кровопускающее (25%)
('W125', 'E040', NULL, '25%'),

-- W111: Пробивающее броню
('W111', 'E063', NULL, NULL),

-- W123: Ошеломление (25%)
('W123', 'E057', NULL, '25%'),

-- W144: Длинное Разрушающее
('W144', 'E009', NULL, NULL),
('W144', 'E067', NULL, NULL),

-- W119: Сбалансированное Кровопускающее (30%) Отравленное (30%)
('W119', 'E071', NULL, NULL),
('W119', 'E040', NULL, '30%'),
('W119', 'E055', NULL, '30%'),

-- W129: Серебряное (3d6) Пробивающее броню
('W129', 'E073', NULL, '3d6'),
('W129', 'E063', NULL, NULL),

-- W130: Серебряное (3d6) Фокусирующее (1)
('W130', 'E073', NULL, '3d6'),
('W130', 'E092', NULL, '1'),

-- W131: Серебряное (3d6) Отравленное (30%)
('W131', 'E073', NULL, '3d6'),
('W131', 'E055', NULL, '30%'),

-- W132: Серебряное (3d6) Кровопускающее (30%)
('W132', 'E073', NULL, '3d6'),
('W132', 'E040', NULL, '30%'),

-- W133: Серебряное (3d6) Сбалансированное
('W133', 'E073', NULL, '3d6'),
('W133', 'E071', NULL, NULL),

-- W134: Серебряное (3d6) Разрушающее
('W134', 'E073', NULL, '3d6'),
('W134', 'E067', NULL, NULL),

-- W136: Пробивающее броню (+) Метеоритное
('W136', 'E064', NULL, NULL),
('W136', 'E047', NULL, NULL),

-- W137: Пробивающее броню Метеоритное Фокусирующее (1)
('W137', 'E063', NULL, NULL),
('W137', 'E047', NULL, NULL),
('W137', 'E092', NULL, '1'),

-- W138: Пробивающее броню Метеоритное Отравленное (30%)
('W138', 'E063', NULL, NULL),
('W138', 'E047', NULL, NULL),
('W138', 'E055', NULL, '30%'),

-- W139: Пробивающее броню Метеоритное Кровопускающее (30%)
('W139', 'E063', NULL, NULL),
('W139', 'E047', NULL, NULL),
('W139', 'E040', NULL, '30%'),

-- W140: Пробивающее броню Метеоритное Сбалансированное
('W140', 'E063', NULL, NULL),
('W140', 'E047', NULL, NULL),
('W140', 'E071', NULL, NULL),

-- W141: Пробивающее броню Метеоритное Разрушающее
('W141', 'E063', NULL, NULL),
('W141', 'E047', NULL, NULL),
('W141', 'E067', NULL, NULL),

-- W157: Длинное Фокусирующее (1)
('W157', 'E009', NULL, NULL),
('W157', 'E092', NULL, '1'),

-- W155: Длинное Фокусирующее (2)
('W155', 'E009', NULL, NULL),
('W155', 'E092', NULL, '2'),

-- W159: Длинное Фокусирующее (1) Захватное
('W159', 'E009', NULL, NULL),
('W159', 'E092', NULL, '1'),
('W159', 'E031', NULL, NULL),

-- W154: Длинное Фокусирующее (3)
('W154', 'E009', NULL, NULL),
('W154', 'E092', NULL, '3'),

-- W158: Длинное Фокусирующее (3) Фокусирующее (+)
('W158', 'E009', NULL, NULL),
('W158', 'E092', NULL, '3'),
('W158', 'E091', NULL, NULL),

-- W161: Длинное Фокусирующее (3) Фокусирующее (+)
('W161', 'E009', NULL, NULL),
('W161', 'E092', NULL, '3'),
('W161', 'E091', NULL, NULL),

-- W162: Реликвия (20) Длинное Горение (25%) Доп. Соблазнение (+2) Фокусирующее (+) (огонь) Фокусирующее (5)
('W162', 'E069', NULL, '20'),
('W162', 'E009', NULL, NULL),
('W162', 'E004', NULL, '25%'),
('W162', 'E021', NULL, '+2'),
('W162', 'E091', 'EC006', NULL),
('W162', 'E092', NULL, '5'),

-- W156: Длинное Фокусирующее (3) Фокусирующее (+)
('W156', 'E009', NULL, NULL),
('W156', 'E092', NULL, '3'),
('W156', 'E091', NULL, NULL),

-- W160: Длинное Фокусирующее (3) Фокусирующее (+)
('W160', 'E009', NULL, NULL),
('W160', 'E092', NULL, '3'),
('W160', 'E091', NULL, NULL),

-- W163: (пусто)
-- Нет эффектов

-- W166: (пусто)
-- Нет эффектов

-- W167: Кровопускающее (25%) Разрушающее
('W167', 'E040', NULL, '25%'),
('W167', 'E067', NULL, NULL),

-- W164: (пусто)
-- Нет эффектов

-- W165: (пусто)
-- Нет эффектов

-- W168: Реликвия (14) Метеоритное Кровопускающее (100%) Сбалансированное
('W168', 'E069', NULL, '14'),
('W168', 'E047', NULL, NULL),
('W168', 'E040', NULL, '100%'),
('W168', 'E071', NULL, NULL);



