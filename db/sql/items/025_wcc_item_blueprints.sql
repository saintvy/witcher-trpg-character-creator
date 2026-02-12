\echo '025_wcc_item_blueprints.sql'
-- Узел: Чертежи (blueprints)
-- Источник данных: inline `VALUES (...)` (сформировано из db/sql/items/wcc_items - wcc_item_blueprints.tsv)
--

-- Примечания:
-- - Название чертежа всегда в i18n_text (через name_id). Для item_id без постфикса B — ссылка на название создаваемого объекта (armor/weapon/...). Для item_id с постфиксом B — свои записи в i18n (witcher_cc.items.blueprint.name.<item_id>).
-- - components сохраняем как JSONB массив пар: [{"id": "<uuid>", "qty": <int|null>}, ...]
--   где id — это i18n UUID (ck_id) для *названия* соответствующего предмета (armor/weapon/ingredient/...),
--   qty — число из скобок (если есть), иначе NULL.
-- - Исключение по components: T041, T044, W156 — часть значений отсутствует в i18n, поэтому создаём tech_val ключи и добавляем их в i18n_text.

CREATE TABLE IF NOT EXISTS wcc_item_blueprints (
  b_id              varchar(10) PRIMARY KEY, -- e.g. 'B001'
  item_id           varchar(10) NOT NULL,    -- e.g. 'A001', 'I004', 'W015B', ...
  dlc_dlc_id        varchar(64) NOT NULL REFERENCES wcc_dlcs(dlc_id),

  name_id           uuid NULL,               -- i18n_text: для не-B — название создаваемого объекта; для ..B — witcher_cc.items.blueprint.name.<item_id>
  availability_id   uuid NULL,               -- ck_id('availability.*') — доступность чертежа (как у брони/оружия)

  group_id          uuid NULL,               -- ck_id(<group_key>) e.g. 'bodypart.head', 'weapons.wt_ammo', ...
  craft_level_id    uuid NULL,               -- ck_id(<craft.level.*>)
  difficulty_check  integer NULL,
  time_value        integer NULL,
  time_unit_id      uuid NULL,               -- ck_id(<time.unit.*>)

  components        jsonb NULL,              

  price_components  integer NULL,
  price_blueprint   integer NULL,
  price_item        integer NULL
);

COMMENT ON TABLE wcc_item_blueprints IS
  'Чертежи для крафта предметов (armor/weapon/ingredients/etc). Названия в i18n_text (name_id). Компоненты — JSONB массив пар (i18n_uuid, qty).';

WITH
-- Data as VALUES for cleaner structure
raw_data (b_id, item_id, name_ru, name_en, dlc_id, group_key, craft_level_key, difficulty_check, time_value, time_unit_key, components_raw, price_components, price_blueprint, price_item, availability_key) AS (
  VALUES
    ('B001', 'A001', 'Двуслойный капюшон', 'Double Woven Hood', 'core', 'bodypart.head', 'craft.level.novice', 13, 4, 'time.unit.hour', 'I004 (2), I020 (2), I011 (7), I013 (4)', 129, 262, 175,'availability.P')
  , ('B002', 'A002', 'Капюшон вардэнского лучника', 'Verden Archer''s Hood', 'core', 'bodypart.head', 'craft.level.novice', 10, 3, 'time.unit.hour', 'I007 (2), I020 (1), I011 (6), I013 (3)', 70, 150, 100,'availability.C')
  , ('B003', 'A003', 'Каркасный шлем с полумаской', 'Spectacled Helm', 'core', 'bodypart.head', 'craft.level.novice', 15, 4, 'time.unit.hour', 'I043 (3), I014 (1)', 152, 300, 200,'availability.C')
  , ('B004', 'A004', 'Капеллина', 'Capelline', 'core', 'bodypart.head', 'craft.level.novice', 16, 5, 'time.unit.hour', 'I043 (3), I037 (1)', 174, 348, 230,'availability.E')
  , ('B005', 'A005', 'Кольчужный капюшон', 'Chain Coif', 'core', 'bodypart.head', 'craft.level.journeyman', 16, 4, 'time.unit.hour', 'I043 (4)', 192, 374, 250,'availability.E')
  , ('B006', 'A006', 'Темерский армет', 'Temerian Armet', 'core', 'bodypart.head', 'craft.level.journeyman', 18, 5, 'time.unit.hour', 'I043 (4), I019 (2), I025 (1), I020 (2)', 352, 712, 475,'availability.P')
  , ('B007', 'A007', 'Усиленный капюшон', 'Armored Hood', 'core', 'bodypart.head', 'craft.level.journeyman', 17, 5, 'time.unit.hour', 'I020 (1), I019 (3), I004 (3), I011 (4), I028 (1)', 260, 524, 250,'availability.C')
  , ('B008', 'A008', 'Нильфгаардский шлем', 'Nilfgaardian Helm', 'core', 'bodypart.head', 'craft.level.master', 24, 6, 'time.unit.hour', 'I032 (4), I008 (1), I019 (1), I023 (2), I024 (2), I007 (1), I001 (10)', 537, 1200, 800,'availability.R')
  , ('B009', 'A009', 'Скеллигский шлем', 'Skellige Helm', 'core', 'bodypart.head', 'craft.level.master', 22, 6, 'time.unit.hour', 'I032 (4), I011 (6), I019 (2), I014 (5), I024 (1)', 537, 1050, 700,'availability.P')
  , ('B010', 'A010', 'Топфхельм', 'Great Helm', 'core', 'bodypart.head', 'craft.level.master', 19, 5, 'time.unit.hour', 'I043 (5), I019 (3), I011 (6), I028 (2), I007 (1)', 431, 862, 575,'availability.R')
  , ('B011', 'A011', 'Аэдирнский гамбезон', 'Aedirnian Gambeson', 'core', 'bodypart.torso', 'craft.level.novice', 12, 6, 'time.unit.hour', 'I007 (6), I011 (6), I020 (2), I008 (1)', 131, 362, 175,'availability.P')
  , ('B012', 'A012', 'Гамбезон', 'Gambeson', 'core', 'bodypart.torso', 'craft.level.novice', 10, 5, 'time.unit.hour', 'I007 (6), I011 (7)', 75, 150, 100,'availability.E')
  , ('B013', 'A013', 'Гамбезон верденского лучника', 'Verden Archer''s Gambeson', 'core', 'bodypart.torso', 'craft.level.novice', 16, 10, 'time.unit.hour', 'I004 (5), I011 (6), I020 (2), I007 (3), I003 (15)', 226, 450, 300,'availability.P')
  , ('B014', 'A014', 'Двуслойный гамбезон', 'Double Woven Gambeson', 'core', 'bodypart.torso', 'craft.level.novice', 15, 8, 'time.unit.hour', 'I004 (5), I011 (6), I030 (4), I007 (4), I003 (11)', 187, 374, 250,'availability.P')
  , ('B015', 'A015', 'Доспех чародея из Бан Арда', 'Ban Ard Mage Armor', 'core', 'bodypart.torso', 'craft.level.master', 20, 16, 'time.unit.hour', 'I032 (5), I004 (5), I011 (4), I027 (2)', 696, 1403, 930,'availability.R')
  , ('B016', 'A016', 'Низушечий защитный дублет', 'Halfling Protective Doublet', 'core', 'bodypart.torso', 'craft.level.master', 18, 9, 'time.unit.hour', 'I010 (4), I011 (10), I003 (7), I004 (2)', 281, 562, 375,'availability.R')
  , ('B017', 'A017', 'Бригантина', 'Brigandine', 'core', 'bodypart.torso', 'craft.level.journeyman', 16, 8, 'time.unit.hour', 'I020 (3), I019 (3)', 228, 450, 300,'availability.C')
  , ('B018', 'A018', 'Броня реданского алебардщика', 'Redanian Halberdier''s Armor', 'core', 'bodypart.torso', 'craft.level.journeyman', 17, 9, 'time.unit.hour', 'I011 (5), I020 (2), I043 (2), I045 (2)', 295, 600, 400,'availability.P')
  , ('B019', 'A019', 'Доспех боевого чародея', 'Battlemage Armor', 'core', 'bodypart.torso', 'craft.level.grand_master', 24, 24, 'time.unit.hour', 'I032 (8), I004 (6), I063 (2), I067 (4), I011 (6), I027 (2), I078 (4)', 1640, 2300, 2200,'availability.R')
  , ('B020', 'A020', 'Доспех охотника за колдуньями', 'Witch Hunter Armor', 'core', 'bodypart.torso', 'craft.level.journeyman', 18, 12, 'time.unit.hour', 'I011 (5), I019 (2), I025 (2), I078 (1), I045 (2), I086 (3)', 374, 750, 500,'availability.P')
  , ('B021', 'A021', 'Каэдвенская кираса', 'Kaedweni Cuirass', 'core', 'bodypart.torso', 'craft.level.journeyman', 16, 12, 'time.unit.hour', 'I019 (2), I020 (3), I037 (3)', 270, 530, 355,'availability.C')
  , ('B022', 'A022', 'Кожаная куртка из Лирии', 'Lyrian Leather Jacket', 'core', 'bodypart.torso', 'craft.level.journeyman', 18, 9, 'time.unit.hour', 'I021 (4), I011 (4), I020 (2), I007 (4), I043 (1)', 392, 786, 525,'availability.R')
  , ('B023', 'A023', 'Доспех с Ундвика', 'Undvik Armor', 'core', 'bodypart.torso', 'craft.level.master', 24, 12, 'time.unit.hour', 'I011 (6), I019 (2), I024 (3), I014 (3), I004 (4), I027 (2)', 607, 1214, 815,'availability.R')
  , ('B024', 'A024', 'Латный доспех', 'Plate Armor', 'core', 'bodypart.torso', 'craft.level.master', 19, 10, 'time.unit.hour', 'I043 (5), I019 (3), I011 (7), I026 (4), I024 (1), I028 (1)', 468, 937, 625,'availability.R')
  , ('B025', 'A025', 'Нильфгаардский латный доспех', 'Nilfgaardian Plate Armor', 'core', 'bodypart.torso', 'craft.level.master', 24, 12, 'time.unit.hour', 'I032 (5), I007 (3), I019 (1), I020 (1), I023 (1), I024 (2), I001 (10)', 637, 1274, 850,'availability.R')
  , ('B026', 'A026', 'Хиндарсфьяльский тяжёлый доспех', 'Hindarsfjall Heavy Armor', 'core', 'bodypart.torso', 'craft.level.master', 22, 11, 'time.unit.hour', 'I011 (6), I014 (5), I019 (1), I024 (3), I032 (4)', 569, 1124, 750,'availability.R')
  , ('B027', 'A027', 'Двуслойные штаны', 'Double Woven Trousers', 'core', 'bodypart.legs', 'craft.level.novice', 15, 8, 'time.unit.hour', 'I004 (6), I011 (6), I003 (6), I007 (1)', 165, 336, 225,'availability.P')
  , ('B028', 'A028', 'Кавалерийские штаны', 'Cavalry Trousers', 'core', 'bodypart.legs', 'craft.level.novice', 13, 7, 'time.unit.hour', 'I007 (5), I011 (4)', 57, 112, 75,'availability.C')
  , ('B029', 'A029', 'Стёганые штаны', 'Padded Trousers', 'core', 'bodypart.legs', 'craft.level.novice', 14, 7, 'time.unit.hour', 'I007 (5), I011 (4), I003 (9), I020 (1)', 94, 186, 125,'availability.C')
  , ('B030', 'A030', 'Штаны темерского пехотинца', 'Temerian Infantry Trousers', 'core', 'bodypart.legs', 'craft.level.novice', 16, 9, 'time.unit.hour', 'I004 (4), I011 (6), I037 (2), I007 (2), I003 (6)', 190, 380, 255,'availability.P')
  , ('B031', 'A031', 'Кожаные штаны из Лирии', 'Lyrian Leather Trousers', 'core', 'bodypart.legs', 'craft.level.journeyman', 18, 9, 'time.unit.hour', 'I021 (4), I011 (4), I020 (2), I007 (4), I043 (1)', 392, 786, 525,'availability.R')
  , ('B032', 'A032', 'Реданские поножи', 'Redanian Greaves', 'core', 'bodypart.legs', 'craft.level.journeyman', 17, 9, 'time.unit.hour', 'I019 (1), I020 (1), I045 (3), I011 (5), I030 (3), I003 (3)', 295, 600, 400,'availability.P')
  , ('B033', 'A033', 'Усиленные штаны', 'Armored Trousers', 'core', 'bodypart.legs', 'craft.level.journeyman', 16, 8, 'time.unit.hour', 'I019 (2), I043 (1), I020 (1), I011 (5)', 187, 374, 250,'availability.E')
  , ('B034', 'A034', 'Латные поножи', 'Plate Greaves', 'core', 'bodypart.legs', 'craft.level.master', 19, 10, 'time.unit.hour', 'I043 (5), I019 (3), I011 (7), I026 (4), I024 (1), I028 (1)', 468, 798, 625,'availability.R')
  , ('B035', 'A035', 'Нильфгаардские поножи', 'Nilfgaardian Greaves', 'core', 'bodypart.legs', 'craft.level.master', 24, 12, 'time.unit.hour', 'I032 (5), I001 (10), I019 (1), I020 (1), I023 (1), I008 (4), I024 (2), I007 (1)', 631, 1274, 850,'availability.R')
  , ('B036', 'A036', 'Хиндарсфьяльские тяжёлые поножи', 'Hindarsfjall Heavy Chausses', 'core', 'bodypart.legs', 'craft.level.master', 22, 11, 'time.unit.hour', 'I011 (8), I014 (5), I019 (2), I020 (1), I024 (1), I032 (4)', 561, 1124, 650,'availability.R')
  , ('B037', 'A037', 'Кольчуга гномьей работы', 'Gnomish Chain', 'core', 'bodypart.full', 'craft.level.grand_master', 24, 24, 'time.unit.hour', 'I032 (8), I020 (2), I023 (1)', 736, 1462, 975,'availability.R')
  , ('B038', 'A038', 'Броня скоя''таэля', 'Scoia''tael Armor', 'core', 'bodypart.full', 'craft.level.master', 20, 20, 'time.unit.hour', 'I032 (12), I022 (3), I025 (10), I026 (12), I001 (11), I004 (8), I023 (4), I006 (13), I024 (2), I011 (9)', 1738, 3486, 2325,'availability.R')
  , ('B039', 'A040', 'Краснолюдский плащ', 'Dwarven Cloak', 'core', 'bodypart.full', 'craft.level.master', 18, 9, 'time.unit.hour', 'I019 (12), I028 (10), I009 (10), I024 (2), I020 (6), I025 (7), I011 (10), I015 (1)', 1050, 2100, 1400,'availability.R')
  , ('B040', 'A041', 'Драгунская броня гномьей работы', 'Gnomish Dragoon Armor', 'core', 'bodypart.full', 'craft.level.grand_master', 25, 25, 'time.unit.hour', 'I032 (12), I040 (1), I038 (2), I025 (10), I026 (14), I004 (5), I023 (4), I024 (2), I011 (15)', 2131, 4274, 2850,'availability.R')
  , ('B041', 'A042', 'Махакамские латы', 'Mahakaman Plate Armor', 'core', 'bodypart.full', 'craft.level.grand_master', 28, 28, 'time.unit.hour', 'I039 (12), I038 (2), I025 (8), I026 (12), I019 (5), I023 (2), I024 (1), I040 (2), I028 (3), I011 (10)', 2645, 5286, 3525,'availability.R')
  , ('B042', 'A044', 'Броня школы Змеи', 'Serpentine Armor', 'core', 'bodypart.full_wo_head', 'craft.level.master', 18, 20, 'time.unit.hour', 'I007 (4), I019 (2), I020 (3), I011 (6), I016 (4), I032 (5), I023 (2)', 842, 0, NULL,'availability.R')
  , ('B043', 'A045', 'Броня школы Кота', 'Feline Armor', 'core', 'bodypart.full_wo_head', 'craft.level.master', 18, 18, 'time.unit.hour', 'I007 (2), I019 (3), I032 (1), I031 (1), I006 (1), I116 (1), I083 (1), I011 (4), I020 (3), I010 (1), I066 (1)', 713, 0, NULL,'availability.R')
  , ('B044', 'A047', 'Броня школы Волка', 'Wolven Armor', 'core', 'bodypart.full_wo_head', 'craft.level.master', 20, 23, 'time.unit.hour', 'I019 (2), I040 (2), I020 (10), I043 (2), I141 (2), I011 (5), I167 (1), I074 (1), I083 (1), I010 (2)', 1302, 0, NULL,'availability.R')
  , ('B045', 'A048', 'Броня школы Грифона', 'Griffin Armor', 'core', 'bodypart.full_wo_head', 'craft.level.master', 20, 24, 'time.unit.hour', 'I007 (3), I019 (5), I042 (1), I040 (3), I020 (4), I107 (2), I032 (4), I011 (5), I102 (1), I083 (2), I010 (2), I164 (1)', 1571, 0, NULL,'availability.R')
  , ('B046', 'A049', 'Броня школы Мантикоры', 'Manticore Armor', 'core', 'bodypart.full_wo_head', 'craft.level.master', 20, 22, 'time.unit.hour', 'I007 (3), I016 (5), I091 (1), I121 (1), I116 (1), I040 (1), I167 (1), I033 (2), I137 (1)', 1052, 0, NULL,'availability.R')
  , ('B047', 'A050', 'Броня школы Медведя', 'Ursine Armor', 'core', 'bodypart.full_wo_head', 'craft.level.master', 22, 25, 'time.unit.hour', 'I019 (7), I032 (2), I004 (6), I014 (4), I032 (2), I040 (2), I011 (8), I127 (1), I164 (1), I042 (2), I020 (6), I104 (2), I010 (2), I092 (1), I028 (6)', 1813, 0, NULL,'availability.R')
  , ('B048', 'A051', 'Гномий баклер', 'Gnomish Buckler', 'core', 'bodypart.shield', 'craft.level.master', 22, 6, 'time.unit.hour', 'I032 (3), I020 (1), I025 (1), I026 (4), I024 (1)', 335, 674, 450,'availability.R')
  , ('B049', 'A052', 'Кожаный щит', 'Leather Shield', 'core', 'bodypart.shield', 'craft.level.novice', 12, 3, 'time.unit.hour', 'I020 (1), I012 (2), I030 (1)', 37, 74, 50,'availability.E')
  , ('B050', 'A053', 'Стальной баклер', 'Steel Buckler', 'core', 'bodypart.shield', 'craft.level.novice', 15, 4, 'time.unit.hour', 'I043 (1), I006 (1), I019 (1)', 112, 224, 150,'availability.C')
  , ('B051', 'A054', 'Темерский щит', 'Temerian Shield', 'core', 'bodypart.shield', 'craft.level.novice', 16, 4, 'time.unit.hour', 'I006 (4), I037 (1), I019 (1), I028 (3)', 172, 342, 225,'availability.C')
  , ('B052', 'A055', 'Каэдвенский щит', 'Kaedweni Shield', 'core', 'bodypart.shield', 'craft.level.journeyman', 19, 5, 'time.unit.hour', 'I006 (5), I032 (1), I014 (7), I020 (1), I028 (5), I013 (2)', 300, 600, 400,'availability.P')
  , ('B053', 'A056', 'Стальной каплевидный щит', 'Steel Kite Shield', 'core', 'bodypart.shield', 'craft.level.journeyman', 17, 5, 'time.unit.hour', 'I043 (4), I032 (1), I020 (1)', 302, 600, 400,'availability.C')
  , ('B054', 'A057', 'Щит из чешуи виверны', 'Wyvern Scale Shield', 'core', 'bodypart.shield', 'craft.level.master', 22, 5, 'time.unit.hour', 'I031 (1), I016 (3), I019 (1), I006 (5), I009 (3), I030 (3), I011 (2)', 375, 750, 500,'availability.R')
  , ('B055', 'A058', 'Щит налётчика со Скеллиге', 'Skellige Raider Shield', 'core', 'bodypart.shield', 'craft.level.journeyman', 18, 5, 'time.unit.hour', 'I006 (5), I032 (1), I028 (1), I014 (5), I020 (1)', 240, 486, 325,'availability.P')
  , ('B056', 'A059', 'Щит школы Мантикоры', 'Manticore Shield', 'core', 'bodypart.shield', 'craft.level.master', 20, 8, 'time.unit.hour', 'I006 (4), I019 (2), I040 (3), I042 (2), I025 (2), I026 (2), I041 (6)', 652, 1304, NULL,'availability.R')
  , ('B057', 'A060', 'Эльфский щит', 'Elven Shield', 'core', 'bodypart.shield', 'craft.level.master', 20, 5, 'time.unit.hour', 'I006 (5), I019 (5), I032 (2), I025 (2), I026 (4), I028 (2)', 528, 1050, 700,'availability.R')
  , ('B058', 'A061', 'Махакамская павеза', 'Mahakaman Pavise', 'core', 'bodypart.shield', 'craft.level.grand_master', 26, 7, 'time.unit.hour', 'I006 (10), I019 (5), I028 (11), I025 (2), I039 (2), I026 (3), I020 (1)', 788, 1574, 1050,'availability.R')
  , ('B059', 'A062', 'Нильфгаардская павеза', 'Nilfgaardian Pavise', 'core', 'bodypart.shield', 'craft.level.master', 22, 6, 'time.unit.hour', 'I006 (10), I019 (3), I028 (1), I032 (1), I025 (2), I023 (1), I001 (10), I026 (2)', 450, 900, 600,'availability.R')
  , ('B060', 'A063', 'Павеза', 'Pavise', 'core', 'bodypart.shield', 'craft.level.master', 19, 5, 'time.unit.hour', 'I006 (10), I043 (1), I019 (3), I028 (1), I025 (2)', 378, 750, 500,'availability.P')
  , ('B061', 'I004', 'Двойное полотно', 'Double Woven Linen', 'core', 'ingredients.craft.crafting_materials', 'craft.level.novice', 14, 30, 'time.unit.minute', 'I007 (1), I011 (2)', 15, 30, 22,'availability.P')
  , ('B062', 'I006', 'Укреплённое дерево', 'Hardened Timber', 'core', 'ingredients.craft.crafting_materials', 'craft.level.novice', 12, 30, 'time.unit.minute', 'I012 (2), I009 (4)', 11, 21, 16,'availability.P')
  , ('B063', 'I007', 'Полотно', 'Linen', 'core', 'ingredients.craft.crafting_materials', 'craft.level.novice', 10, 15, 'time.unit.minute', 'I011 (2)', 6, 12, 9,'availability.C')
  , ('B064', 'I011', 'Нитки', 'Thread', 'core', 'ingredients.craft.crafting_materials', 'craft.level.novice', 10, 15, 'time.unit.minute', 'I003 (2)', 2, 4, 3,'availability.C')
  , ('B065', 'I016', 'Кожа драконида', 'Draconid Leather', 'core', 'ingredients.craft.crafting_materials', 'craft.level.master', 18, 1, 'time.unit.hour', 'I017 (1), I030 (3)', 39, 78, 58,'availability.R')
  , ('B066', 'I019', 'Укреплённая кожа', 'Hardened Leather', 'core', 'ingredients.craft.crafting_materials', 'craft.level.novice', 14, 30, 'time.unit.minute', 'I020 (1), I013 (2)', 32, 64, 48,'availability.P')
  , ('B067', 'I020', 'Кожа', 'Leather', 'core', 'ingredients.craft.crafting_materials', 'craft.level.novice', 12, 1, 'time.unit.hour', 'I015 (1), I030 (3)', 19, 38, 28,'availability.C')
  , ('B068', 'I021', 'Лирийская кожа', 'Lyrian Leather', 'core', 'ingredients.craft.crafting_materials', 'craft.level.journeyman', 17, 1, 'time.unit.hour', 'I020 (1), I028 (1), I002 (2)', 40, 80, 60,'availability.P')
  , ('B069', 'I032', 'Тёмная сталь', 'Dark Steel', 'core', 'ingredients.craft.crafting_materials', 'craft.level.journeyman', 17, 1, 'time.unit.hour', 'I031 (1), I002 (3)', 55, 110, 82,'availability.R')
  , ('B070', 'I033', 'Двимерит', 'Dimeritium', 'core', 'ingredients.craft.crafting_materials', 'craft.level.master', 20, 1, 'time.unit.hour', 'I035 (2)', 160, 320, 240,'availability.R')
  , ('B071', 'I038', 'Махакамский двимерит', 'Mahakaman Dimeritium', 'core', 'ingredients.craft.crafting_materials', 'craft.level.master', 24, 1, 'time.unit.hour', 'I035 (2), I041 (3), I001 (2), I014 (3)', 201, 402, 300,'availability.R')
  , ('B072', 'I039', 'Махакамская сталь', 'Mahakaman Steel', 'core', 'ingredients.craft.crafting_materials', 'craft.level.master', 22, 1, 'time.unit.hour', 'I037 (1), I002 (5), I001 (2), I041 (3), I014 (3)', 76, 152, 114,'availability.P')
  , ('B073', 'I043', 'Сталь', 'Steel', 'core', 'ingredients.craft.crafting_materials', 'craft.level.journeyman', 15, 1, 'time.unit.hour', 'I037 (1), I002 (5)', 35, 70, 48,'availability.P')
  , ('B074', 'I045', 'Третогорская сталь', 'Tretogor Steel', 'core', 'ingredients.craft.crafting_materials', 'craft.level.journeyman', 16, 1, 'time.unit.hour', 'I037 (1), I002 (5), I018 (2)', 43, 86, 64,'availability.P')
  , ('B075', 'T039', 'Совершенный самоцвет', 'Perfect Gemstone', 'core', 'general_gear.group.quest', 'craft.level.grand_master', 30, 30, 'time.unit.minute', 'I034 (1)', 0, 1000, 1000,'availability.R')
  , ('B076', 'T041', 'Ведьмачий медальон', 'Witcher medallion', 'core', 'general_gear.group.quest', 'craft.level.mage', 15, 4, 'time.unit.hour', 'I042 (1), I026 (5), Обработка в месте силы (1ч) (1)', 82, 0, NULL,NULL)
  , ('B077', 'T044', 'Головоломка Коллекционера', 'Centerpiece', 'exp_toc', 'general_gear.group.quest', 'craft.level.master', 22, 10, 'time.unit.hour', '3 различных материала, Используемый навык: Искусство (Fine Arts)', 700, 0, NULL,NULL)
  , ('B078', 'T045', 'Церебральный эликсир', 'Cerebral Elixir', 'exp_toc', 'general_gear.group.quest', 'craft.level.master', 22, 10, 'time.unit.hour', 'T025 (3), I126 (1), R042, I076 (3), I098 (5), I059 (3), I100 (4), I042 (1), I067 (4)', 666, 1332, NULL,NULL)
  , ('B079', 'T046', 'Земные ленты', 'Earthly Ribbons', 'exp_toc', 'general_gear.group.quest', 'craft.level.master', 22, 10, 'time.unit.hour', 'I010 (8), I027 (5), I011 (10)', 676, 1352, NULL,NULL)
  , ('B080', 'T047', 'Жезл изгнания', 'Wand of Banishment', 'exp_toc', 'general_gear.group.quest', 'craft.level.journeyman', 17, 9, 'time.unit.hour', 'I012 (1), I027 (2), I025 (2), I032 (2), I026 (5), I028 (3), I085 (1)', 405, 800, NULL,NULL)
  , ('B081', 'U001', 'Скеллигское стремя', 'Skelliger Brace', 'core', 'upgrades.crossbow', 'craft.level.novice', 10, 1, 'time.unit.hour', 'I032 (2), I028 (3), I014 (6)', 242, 750, 375,'availability.C')
  , ('B082', 'U002', 'Балансировочное стремя', 'Stabilizing Brace', 'core', 'upgrades.crossbow', 'craft.level.novice', 12, 2, 'time.unit.hour', 'I043 (3), I006 (5), I020 (1), I025 (1)', 260, 790, 395,'availability.C')
  , ('B083', 'U003', 'Нильфгаардский прицел', 'Nilfgaardian Sights', 'core', 'upgrades.crossbow', 'craft.level.journeyman', 15, 4, 'time.unit.hour', 'I043 (1), I029 (4)', 176, 550, 275,'availability.P')
  , ('B084', 'U004', 'Усиленная тетива', 'High Tension String', 'core', 'upgrades.crossbow', 'craft.level.journeyman', 17, 4, 'time.unit.hour', 'I028 (10), I011 (10), I010 (3)', 280, 850, 425,'availability.P')
  , ('B085', 'U005', 'Улучшенный ворот', 'Improved Windlass', 'core', 'upgrades.crossbow', 'craft.level.master', 20, 10, 'time.unit.hour', 'I043 (4), I013 (3), I011 (10), I025 (7)', 284, 880, 440,'availability.R')
  , ('B086', 'U016', 'Продление', 'Prolongation', 'exp_toc', 'upgrades.runeword', 'craft.level.journeyman', 15, 1, 'time.unit.hour', 'U011 (1), U012 (1)', 1175, 2150, 1175,'availability.R')
  , ('B087', 'U017', 'Пылание', 'Burning', 'exp_toc', 'upgrades.runeword', 'craft.level.journeyman', 15, 1, 'time.unit.hour', 'U015 (1), U007 (1)', 1175, 2150, 1175,'availability.R')
  , ('B088', 'U018', 'Спокойствие', 'Placation', 'exp_toc', 'upgrades.runeword', 'craft.level.journeyman', 15, 1, 'time.unit.hour', 'U010 (1), U013 (1)', 1075, 2150, 1175,'availability.R')
  , ('B089', 'U019', 'Закрепление', 'Preservation', 'exp_toc', 'upgrades.runeword', 'craft.level.journeyman', 15, 1, 'time.unit.hour', 'U008 (1), U010 (1)', 1150, 2300, 1150,'availability.R')
  , ('B090', 'U020', 'Рассечение', 'Shearing', 'exp_toc', 'upgrades.runeword', 'craft.level.journeyman', 15, 1, 'time.unit.hour', 'U006 (1), U009 (1)', 1150, 2300, 1150,'availability.R')
  , ('B091', 'U021', 'Отражение', 'Deflection', 'exp_toc', 'upgrades.runeword', 'craft.level.master', 21, 1, 'time.unit.hour', 'U015 (1), U011 (1), U013 (1)', 1650, 3300, 1750,'availability.R')
  , ('B092', 'U022', 'Истощение', 'Depletion', 'exp_toc', 'upgrades.runeword', 'craft.level.master', 21, 1, 'time.unit.hour', 'U013 (1), U014 (1), U006 (1)', 1675, 3350, 1775,'availability.R')
  , ('B093', 'U023', 'Обновление', 'Rejuvenation', 'exp_toc', 'upgrades.runeword', 'craft.level.master', 21, 1, 'time.unit.hour', 'U011 (1), U012 (1), U014 (1)', 1750, 3500, 1750,'availability.R')
  , ('B094', 'U024', 'Ткань', 'Fiber', 'core', 'upgrades.armor', 'craft.level.novice', 14, 3, 'time.unit.hour', 'I004 (1), I011 (2)', 28, 60, 40,'availability.E')
  , ('B095', 'U025', 'Клёпанная кожа', 'Studded Leather', 'core', 'upgrades.armor', 'craft.level.novice', 14, 3, 'time.unit.hour', 'I020 (1), I037 (1), I011 (1)', 61, 120, 80,'availability.C')
  , ('B096', 'U026', 'Кольчужное', 'Chain Mail', 'core', 'upgrades.armor', 'craft.level.journeyman', 17, 5, 'time.unit.hour', 'I043 (2)', 96, 187, 125,'availability.P')
  , ('B097', 'U027', 'Укрепленная кожа', 'Hardened Leather', 'core', 'upgrades.armor', 'craft.level.journeyman', 16, 4, 'time.unit.hour', 'I019 (1), I020 (1), I011 (5), I013 (3)', 97, 195, 130,'availability.C')
  , ('B098', 'U028', 'Стальное', 'Steel', 'core', 'upgrades.armor', 'craft.level.journeyman', 18, 5, 'time.unit.hour', 'I043 (2), I011 (3), I026 (2)', 109, 217, 145,'availability.P')
  , ('B099', 'U029', 'Краснолюдское усиление', 'Dwarven', 'core', 'upgrades.armor', 'craft.level.master', 27, 6, 'time.unit.hour', 'I039 (1), I011 (5), I022 (1), I002 (1)', 144, 292, 195,'availability.R')
  , ('B100', 'U030', 'Эльфийское усиление', 'Elven', 'core', 'upgrades.armor', 'craft.level.master', 27, 6, 'time.unit.hour', 'I032 (1), I011 (5), I019 (1), I018 (1)', 149, 300, 200,'availability.R')
  , ('B101', 'U040', 'Баланс', 'Balance', 'exp_toc', 'upgrades.glyphword', 'craft.level.journeyman', NULL, 1, 'time.unit.hour', 'U034 (1), U031 (1)', 550, 1100, 550,'availability.R')
  , ('B102', 'U041', 'Воздаяние', 'Retribution', 'exp_toc', 'upgrades.glyphword', 'craft.level.master', NULL, 1, 'time.unit.hour', 'U037 (1), U038 (1), U031 (1)', 1250, 2500, 1250,'availability.R')
  , ('B103', 'U042', 'Кольцо', 'Rotation', 'exp_toc', 'upgrades.glyphword', 'craft.level.journeyman', NULL, 1, 'time.unit.hour', 'U032 (1), U031 (1)', 300, 600, 300,'availability.R')
  , ('B104', 'U043', 'Очарование', 'Beguilement', 'exp_toc', 'upgrades.glyphword', 'craft.level.journeyman', NULL, 1, 'time.unit.hour', 'U038 (1), U039 (1)', 1150, 2300, 1150,'availability.R')
  , ('B105', 'U044', 'Сияние', 'Shining', 'exp_toc', 'upgrades.glyphword', 'craft.level.journeyman', NULL, 1, 'time.unit.hour', 'U036 (1), U033 (1)', 875, 1750, 875,'availability.R')
  , ('B106', 'U045', 'Тяжесть', 'Heft', 'exp_toc', 'upgrades.glyphword', 'craft.level.journeyman', NULL, 1, 'time.unit.hour', 'U034 (1), U031 (1)', 550, 1100, 550,'availability.R')
  , ('B107', 'U046', 'Щит', 'Protection', 'exp_toc', 'upgrades.glyphword', 'craft.level.master', NULL, 1, 'time.unit.hour', 'U037 (1), U035 (1), U033 (1)', 1450, 2900, 1450,'availability.R')
  , ('B108', 'U047', 'Доп. слот для улучшения на броне/оружии', 'Additional upgrade slot on armor/weapon', 'core', 'upgrades.armor', 'craft.level.master', 25, 4, 'time.unit.hour', 'I040 (4), I089 (2)', 684, 1368, 684,NULL)
  , ('B109', 'W001', 'Арбалет', 'Crossbow', 'core', 'weapons.wt_crossbow', 'craft.level.journeyman', 17, 9, 'time.unit.hour', 'I006 (4), I011 (5), I013 (1), I009 (2), I043 (3), I019 (1), I025 (2), I028 (2), I037 (1)', 343, 682, 455,'availability.E')
  , ('B110', 'W002', 'Арбалет охотника на чудовищ', 'Monster Hunter''s Crossbow', 'core', 'weapons.wt_crossbow', 'craft.level.master', 24, 12, 'time.unit.hour', 'I006 (6), I032 (4), I011 (6), I019 (3), I009 (4), I025 (2), I013 (3), I028 (4), I031 (3), I014 (4)', 844, 1686, 1125,'availability.R')
  , ('B111', 'W003', 'Арбалет школы Волка', 'Wolven Crossbow', 'hb', 'weapons.wt_crossbow', 'craft.level.master', 17, 8, 'time.unit.hour', 'I006 (2), I137 (2), I013 (2), I009 (2), I031 (1), I019 (1), I025 (2), I028 (2), I032 (1), I014 (2)', 346, 0, NULL,'availability.R')
  , ('B112', 'W004', 'Арбалет школы Грифона', 'Griffin Crossbow', 'dlc_wt', 'weapons.wt_crossbow', 'craft.level.master', 17, 8, 'time.unit.hour', 'I006 (2), I191 (2), I013 (2), I032 (1), I031 (1), I009 (2), I019 (1), I025 (2), I028 (1)', 342, 0, NULL,'availability.R')
  , ('B113', 'W005', 'Арбалет школы Змеи', 'Serpentine Crossbow', 'hb', 'weapons.wt_crossbow', 'craft.level.master', 17, 8, 'time.unit.hour', 'I006 (2), I137 (2), I013 (2), I009 (2), I031 (1), I019 (1), I025 (2), I028 (2), I032 (1), I115 (2)', 346, 0, NULL,'availability.R')
  , ('B114', 'W006', 'Арбалет школы Кота', 'Feline Crossbow', 'dlc_wt', 'weapons.wt_crossbow', 'craft.level.master', 17, 8, 'time.unit.hour', 'I006 (2), I137 (2), I009 (2), I013 (2), I019 (1), I028 (2), I025 (2), I031 (1), I032 (1), I014 (2)', 346, 0, NULL,'availability.R')
  , ('B115', 'W007', 'Арбалет школы Мантикоры', 'Manticore Crossbow', 'hb', 'weapons.wt_crossbow', 'craft.level.master', 17, 8, 'time.unit.hour', 'I006 (2), I103 (1), I013 (2), I009 (3), I032 (1), I019 (1), I025 (2), I028 (2), I031 (1), I014 (2)', 347, 0, NULL,'availability.R')
  , ('B116', 'W008', 'Арбалет школы Медведя', 'Ursine Crossbow', 'dlc_wt', 'weapons.wt_crossbow', 'craft.level.master', 17, 8, 'time.unit.hour', 'I006 (2), I013 (2), I009 (2), I019 (1), I103 (1), I032 (1), I025 (2), I028 (2), I031 (1), I014 (2)', 347, 0, NULL,'availability.R')
  , ('B117', 'W009', 'Гномий ручной арбалет', 'Gnomish Hand Crossbow', 'core', 'weapons.wt_crossbow', 'craft.level.grand_master', 25, 13, 'time.unit.hour', 'I006 (2), I011 (4), I032 (2), I025 (1), I023 (2), I009 (2), I024 (1), I013 (2)', 317, 634, 425,'availability.R')
  , ('B118', 'W010', 'Краснолюдский тяжёлый арбалет', 'Dwarven Heavy Crossbow', 'core', 'weapons.wt_crossbow', 'craft.level.master', 24, 12, 'time.unit.hour', 'I006 (5), I039 (3), I019 (2), I011 (4), I028 (5), I031 (1)', 632, 1274, 850,'availability.R')
  , ('B119', 'W011', 'Охотничий арбалет', 'Huntsman''s Crossbow', 'exp_bot', 'weapons.wt_crossbow', 'craft.level.journeyman', 18, 9, 'time.unit.hour', 'I019 (1), I006 (3), I039 (3), I028 (1), I011 (4)', 460, 900, 600,'availability.C')
  , ('B120', 'W012', 'Ручной арбалет', 'Hand Crossbow', 'core', 'weapons.wt_crossbow', 'craft.level.journeyman', 15, 8, 'time.unit.hour', 'I006 (2), I011 (4), I013 (2), I009 (2), I043 (1), I019 (1), I025 (2), I028 (2), I037 (1)', 214, 426, 285,'availability.E')
  , ('B121', 'W013', 'Скорпио', 'Scorpio', 'dlc_rw2', 'weapons.wt_crossbow', 'craft.level.master', 22, 24, 'time.unit.hour', 'I014 (9), I031 (5), I032 (8), I026 (4), I019 (4), I006 (30), I028 (8), I008 (3), I009 (10), I011 (18), I013 (10)', 1875, 3750, 2500,'availability.R')
  , ('B122', 'W015B', 'Бронебойные стрелы (х10)', 'Bodkin Arrows (х10)', 'core', 'weapons.wt_ammo', 'craft.level.journeyman', 16, 1, 'time.unit.hour', 'I006 (1), I043 (1), I018 (1), I029 (1), I028 (1)', 110, 224, 15,'availability.C')
  , ('B123', 'W016B', 'Взрывные стрелы (х5)', 'Explosive Arrows (х5)', 'core', 'weapons.wt_ammo', 'craft.level.master', 20, 30, 'time.unit.minute', 'I032 (2), I018 (1), I006 (1), I008 (1), I041 (3), I028 (4), I046 (4)', 362, 0, 108,'availability.R')
  , ('B124', 'W017B', 'Выслеживающие стрелы (х5)', 'Tracking Arrows (х5)', 'core', 'weapons.wt_ammo', 'craft.level.master', 14, 30, 'time.unit.minute', 'I006 (1), I043 (1), I009 (1), I030 (2)', 76, 0, 22,'availability.R')
  , ('B125', 'W018B', 'Гавенкарские разбрызгивающие стрелы (х5)', 'HavenKar Bloom Arrows (х5)', 'hb', 'weapons.wt_ammo', 'craft.level.master', 18, 2, 'time.unit.hour', 'I032 (3), I009 (1), I018 (2), I006 (1), I028 (1), I029 (6), I011 (3)', 483, 374, 130,'availability.R')
  , ('B126', 'W019B', 'Краснолюдские пробивные (х5)', 'Dwarven Impact Arrows (х5)', 'core', 'weapons.wt_ammo', 'craft.level.master', 20, 30, 'time.unit.minute', 'I039 (1), I006 (1), I018 (1), I028 (2), I037 (1)', 184, 100, 50,'availability.R')
  , ('B127', 'W020B', 'Разделяющиеся стрелы (х5)', 'Split Arrows (х5)', 'core', 'weapons.wt_ammo', 'craft.level.master', 18, 30, 'time.unit.minute', 'I006 (2), I043 (2), I018 (3), I011 (3), I004 (1), I041 (2)', 181, 0, 54,'availability.R')
  , ('B128', 'W021B', 'Стрелы с затупленным наконечником (х5)', 'Blunt Arrows (х5)', 'core', 'weapons.wt_ammo', 'craft.level.novice', 12, 1, 'time.unit.hour', 'I012 (1), I037 (1), I018 (1)', 37, 74, 5,'availability.C')
  , ('B129', 'W022B', 'Стрелы с широким наконечником (х10)', 'Broadhead Arrows (х10)', 'core', 'weapons.wt_ammo', 'craft.level.journeyman', 15, 1, 'time.unit.hour', 'I012 (1), I037 (1), I018 (1), I029 (1)', 69, 125, 10,'availability.C')
  , ('B130', 'W023B', 'Серебряные стрелы (х10)', 'Silver Arrows (х10)', 'hb', 'weapons.wt_ammo', 'craft.level.journeyman', 16, 1, 'time.unit.hour', 'I012 (1), I042 (1), I018 (1), I029 (1)', 111, 212, 16,'availability.P')
  , ('B131', 'W024B', 'Стандартные стрелы (х30)', 'Standard Arrows (x30)', 'core', 'weapons.wt_ammo', 'craft.level.novice', 10, 2, 'time.unit.hour', 'I012 (1), I037 (1), I018 (1)', 37, 14, 10,'availability.E')
  , ('B132', 'W025B', 'Эльфские ввинчивающиеся стрелы (х5)', 'Elven Burrower Arrows (х5)', 'core', 'weapons.wt_ammo', 'craft.level.master', 20, 30, 'time.unit.minute', 'I032 (1), I009 (1), I006 (1), I018 (2), I029 (2), I028 (1), I011 (1)', 185, 100, 50,'availability.R')
  , ('B133', 'W026B', 'Бронебойные болты для Скорпио (x5)', 'Piercing Scorpio Bolts (x5)', 'dlc_rw2', 'weapons.wt_ammo', 'craft.level.journeyman', 17, 3, 'time.unit.hour', 'I002 (1), I018 (6), I006 (6), I041 (4), I029 (1), I043 (2), I011 (2)', 275, 550, 75,'availability.R')
  , ('B134', 'W027B', 'Разрушающие болты для Скорпио (x5)', 'Breaker Scorpio Bolts (x5)', 'dlc_rw2', 'weapons.wt_ammo', 'craft.level.journeyman', 17, 3, 'time.unit.hour', 'I031 (2), I018 (4), I006 (7), I028 (4), I011 (1)', 275, 550, 75,'availability.R')
  , ('B135', 'W028B', 'Стандартные болты для Скорпио (x5)', 'Standard Scorpio Bolts (x5)', 'dlc_rw2', 'weapons.wt_ammo', 'craft.level.journeyman', 16, 3, 'time.unit.hour', 'I018 (6), I006 (6), I037 (2), I009 (2), I011 (1)', 187, 375, 50,'availability.R')
  , ('B136', 'W029', 'Двимеритовая бомба', 'Dimeritium Bomb', 'core', 'weapons.wt_bomb', 'craft.level.master', 20, 30, 'time.unit.minute', 'I041 (2), I013 (1), I046 (1), I085 (1), I075 (2)', 176, 0, 264,'availability.P')
  , ('B137', 'W030', 'Картечь', 'Grapeshot', 'core', 'weapons.wt_bomb', 'craft.level.journeyman', 20, 30, 'time.unit.minute', 'I041 (2), I013 (1), I046 (1), I037 (1), I059 (2)', 106, 0, 159,'availability.P')
  , ('B138', 'W031', 'Лунная пыль', 'Moon Dust', 'core', 'weapons.wt_bomb', 'craft.level.master', 16, 30, 'time.unit.minute', 'I041 (2), I013 (1), I046 (1), I078 (1), I086 (1)', 133, 0, 199,'availability.P')
  , ('B139', 'W032', 'Самум', 'Samum', 'core', 'weapons.wt_bomb', 'craft.level.journeyman', 18, 30, 'time.unit.minute', 'I041 (2), I013 (1), I046 (1), I065 (2), I099 (2)', 98, 0, 147,'availability.P')
  , ('B140', 'W033', 'Северный ветер', 'Northern Wind', 'core', 'weapons.wt_bomb', 'craft.level.journeyman', 20, 30, 'time.unit.minute', 'I041 (2), I013 (1), I046 (1), I081 (2), I105 (2)', 118, 0, 177,'availability.P')
  , ('B141', 'W034', 'Солнце Зеррикании', 'Zerrikanian Sun', 'dlc_rw2', 'weapons.wt_bomb', 'craft.level.journeyman', 16, 30, 'time.unit.minute', 'I102 (1), I041 (2), I079 (1), I046 (1)', 90, 180, 120,'availability.P')
  , ('B142', 'W035', 'Сон дракона', 'Dragon''s Dream', 'core', 'weapons.wt_bomb', 'craft.level.journeyman', 16, 30, 'time.unit.minute', 'I041 (2), I013 (1), I046 (1), I072 (2), I099 (2)', 118, 0, 177,'availability.P')
  , ('B143', 'W036', 'Танцующая звезда', 'Dancing Star', 'core', 'weapons.wt_bomb', 'craft.level.journeyman', 20, 30, 'time.unit.minute', 'I041 (2), I013 (1), I046 (1), I086 (2), I076 (2)', 108, 0, 162,'availability.P')
  , ('B144', 'W037', 'Чёртов гриб', 'Devil''s Puffball', 'core', 'weapons.wt_bomb', 'craft.level.journeyman', 16, 30, 'time.unit.minute', 'I041 (2), I013 (1), I046 (1), I075 (2), I113 (2)', 92, 0, 138,'availability.P')
  , ('B145', 'W039', 'Друидский серп', 'Druid''s Sickle', 'exp_toc', 'weapons.wt_tool', 'craft.level.journeyman', 17, 5, 'time.unit.hour', 'I006 (2), I009 (1), I014 (2), I019 (2), I029 (4), I043 (2), I018 (3)', 390, 780, 540,'availability.E')
  , ('B146', 'W041', 'Кнут', 'Whip', 'exp_lal', 'weapons.wt_tool', 'craft.level.novice', 10, 2, 'time.unit.hour', 'I013 (1), I020 (4)', 114, 228, 152,'availability.C')
  , ('B147', 'W044', 'Ламия', 'Lamia', 'exp_lal', 'weapons.wt_tool', 'craft.level.master', 24, 12, 'time.unit.hour', 'I006 (1), I019 (2), I029 (2), I032 (2), I045 (2), I008 (3), I002 (10)', 487, 937, 600,'availability.R')
  , ('B148', 'W049', 'Утяжелённая сеть', 'Weighted Net', 'dlc_rw2', 'weapons.wt_tool', 'craft.level.master', 13, 3, 'time.unit.hour', 'I037 (1), I009 (1), I011 (20), I013 (1)', 94, 188, 125,'availability.E')
  , ('B149', 'W050', 'Сеть охотника на монстров', 'Monster Catcher''s Net', 'dlc_rw2', 'weapons.wt_tool', 'craft.level.master', 24, 6, 'time.unit.hour', 'I025 (1), I078 (3), I009 (6), I086 (3), I011 (25), I013 (4)', 375, 750, 500,'availability.R')
  , ('B150', 'W052', 'Шприц полевого врача', 'Field Doctor''s Syringe', 'dlc_rw2', 'weapons.wt_tool', 'craft.level.journeyman', 18, 6, 'time.unit.hour', 'I024 (2), I005 (1), I006 (1), I008 (1), I009 (2), I029 (3), I043 (1)', 262, 525, 350,'availability.P')
  , ('B151', 'W053', 'Алебарда-секач', 'Cleaving Halberd', 'hb', 'weapons.wt_pole', 'craft.level.journeyman', 18, 10, 'time.unit.hour', 'I006 (4), I037 (4), I043 (3), I029 (2), I020 (1), I026 (2)', 424, 850, 568,'availability.P')
  , ('B152', 'W054', 'Боевое копьё', 'War Lance', 'exp_bot', 'weapons.wt_pole', 'craft.level.journeyman', 15, 6, 'time.unit.hour', 'I031 (2), I019 (2), I006 (9), I028 (3), I043 (1)', 392, 825, 550,'availability.P')
  , ('B153', 'W055', 'Копьё', 'Spear', 'core', 'weapons.wt_pole', 'craft.level.novice', 12, 6, 'time.unit.hour', 'I006 (5), I043 (2), I009 (2), I020 (3), I011 (4)', 276, 562, 375,'availability.E')
  , ('B154', 'W057', 'Красная алебарда', 'Red Halberd', 'core', 'weapons.wt_pole', 'craft.level.master', 22, 11, 'time.unit.hour', 'I006 (6), I032 (3), I045 (2), I019 (2), I029 (2), I025 (2)', 646, 1298, 865,'availability.P')
  , ('B155', 'W058', 'Краснолюдский боевой молот', 'Dwarven Pole Hammer', 'core', 'weapons.wt_pole', 'craft.level.grand_master', 25, 13, 'time.unit.hour', 'I006 (6), I039 (3), I019 (3), I028 (1), I029 (1)', 624, 2359, 835,'availability.R')
  , ('B156', 'W061', 'Протазан', 'Partisan', 'exp_bot', 'weapons.wt_pole', 'craft.level.journeyman', 16, 8, 'time.unit.hour', 'I031 (3), I032 (2), I025 (2), I019 (2), I006 (7), I028 (2)', 515, 1126, 750,'availability.C')
  , ('B157', 'W062', 'Секира', 'Pole Axe', 'core', 'weapons.wt_pole', 'craft.level.journeyman', 16, 8, 'time.unit.hour', 'I006 (5), I032 (2), I020 (2), I029 (1), I025 (1), I007 (1)', 349, 690, 460,'availability.P')
  , ('B158', 'W063', 'Турнирное копьё', 'Blunted Lance', 'exp_bot', 'weapons.wt_pole', 'craft.level.journeyman', 15, 6, 'time.unit.hour', 'I031 (1), I019 (2), I006 (9), I028 (3), I043 (1)', 370, 750, 500,'availability.P')
  , ('B159', 'W064', 'Фальшарда', 'Fauchard', 'hb', 'weapons.wt_pole', 'craft.level.novice', 13, 8, 'time.unit.hour', 'I006 (4), I043 (3), I009 (2), I020 (3), I011 (4)', 308, 604, 412,'availability.E')
  , ('B160', 'W065', 'Человеколов', 'Mancatcher', 'exp_lal', 'weapons.wt_pole', 'craft.level.journeyman', 16, 8, 'time.unit.hour', 'I006 (4), I011 (1), I013 (2), I020 (3), I025 (2), I029 (1), I043 (3)', 347, 679, 463,'availability.P')
  , ('B161', 'W066', 'Эльфская глефа', 'Elven Glaive', 'core', 'weapons.wt_pole', 'craft.level.master', 19, 10, 'time.unit.hour', 'I006 (6), I032 (4), I043 (1), I020 (4), I018 (3), I029 (2), I025 (4)', 692, 1386, 925,'availability.R')
  , ('B162', 'W068', 'Крестьянский молот', 'Peasant''s Maul', 'exp_bot', 'weapons.wt_bludgeon', 'craft.level.novice', 12, 3, 'time.unit.hour', 'I025 (1), I006 (6), I037 (3), I020 (3), I013 (2)', 282, 562, 375,'availability.E')
  , ('B163', 'W069', 'Булава', 'Mace', 'core', 'weapons.wt_bludgeon', 'craft.level.journeyman', 16, 8, 'time.unit.hour', 'I039 (1), I006 (1), I018 (1), I028 (2), I037 (1)', 384, 786, 525,'availability.C')
  , ('B164', 'W070', 'Дубинка', 'Club', 'hb', 'weapons.wt_bludgeon', 'craft.level.novice', 10, 30, 'time.unit.minute', 'I006 (1), I020 (1), I007 (1)', 53, 105, 83,'availability.E')
  , ('B165', 'W071', 'Клевец', 'Horseman''s Hammer', 'exp_bot', 'weapons.wt_bludgeon', 'craft.level.journeyman', 18, 9, 'time.unit.hour', 'I031 (3), I032 (4), I019 (2), I006 (3), I028 (2)', 648, 1290, 860,'availability.C')
  , ('B166', 'W072', 'Кастет', 'Brass Knuckles', 'core', 'weapons.wt_bludgeon', 'craft.level.novice', 10, 2, 'time.unit.hour', 'I043 (1), I006 (1), I009 (3), I013 (1)', 72, 125, 50,'availability.E')
  , ('B167', 'W073', 'Кистень', 'Flail', 'exp_lal', 'weapons.wt_bludgeon', 'craft.level.journeyman', 16, 6, 'time.unit.hour', 'I009 (1), I012 (1), I024 (2), I028 (1), I029 (2), I037 (2), I043 (4)', 421, 843, 562,'availability.P')
  , ('B168', 'W074', 'Кистень из метеоритной стали', 'Meteorite Chain Mace', 'core', 'weapons.wt_bludgeon', 'craft.level.grand_master', 25, 13, 'time.unit.hour', 'I040 (5), I025 (1), I006 (1), I019 (1), I032 (1), I029 (1)', 686, 1352, 900,'availability.R')
  , ('B169', 'W075', 'Махакамский мартель', 'Mahakaman Martell', 'core', 'weapons.wt_bludgeon', 'craft.level.master', 22, 11, 'time.unit.hour', 'I039 (3), I006 (3), I019 (2), I022 (1), I029 (1), I025 (3), I024 (2), I041 (4), I007 (1)', 675, 1350, 750,'availability.R')
  , ('B170', 'W076', 'Молот горца', 'Highland Mauler', 'core', 'weapons.wt_bludgeon', 'craft.level.master', 25, 13, 'time.unit.hour', 'I031 (5), I032 (1), I006 (10), I019 (1), I026 (6), I014 (10), I025 (4), I040 (1)', 772, 1440, 1100,'availability.R')
  , ('B171', 'W077', 'Нагайка', 'Riding Whip', 'hb', 'weapons.wt_bludgeon', 'craft.level.novice', 10, 1, 'time.unit.hour', 'I013 (1), I020 (2), I037 (1)', 88, 176, 115,'availability.E')
  , ('B172', 'W079', 'Дага', 'Parrying Dagger', 'exp_lal', 'weapons.wt_sblade', 'craft.level.journeyman', 16, 4, 'time.unit.hour', 'I006 (1), I019 (2), I028 (2), I032 (1), I043 (1)', 262, 525, 350,'availability.C')
  , ('B173', 'W080', 'Джамбия', 'Jambiya', 'core', 'weapons.wt_sblade', 'craft.level.master', 20, 5, 'time.unit.hour', 'I006 (1), I016 (1), I032 (1), I043 (2), I029 (2), I009 (1), I023 (1)', 342, 660, 440,'availability.R')
  , ('B174', 'W081', 'Змеиный клык', 'Viper''s Fang', 'dlc_wt', 'weapons.wt_sblade', 'craft.level.master', 16, 4, 'time.unit.hour', 'I006 (1), I016 (1), I032 (1), I029 (1), I061 (1)', 218, 0, NULL,'availability.R')
  , ('B175', 'W082', 'Кинжал', 'Dagger', 'core', 'weapons.wt_sblade', 'craft.level.novice', 8, 2, 'time.unit.hour', 'I012 (1), I037 (1)', 33, 74, 50,'availability.E')
  , ('B176', 'W083', 'Короткий кинжал', 'Poniard', 'core', 'weapons.wt_sblade', 'craft.level.journeyman', 18, 4, 'time.unit.hour', 'I006 (1), I032 (1), I019 (1), I029 (2), I026 (4), I014 (4)', 250, 534, 350,'availability.P')
  , ('B177', 'W084', 'Краснолюдский секач', 'Dwarven Cleaver', 'core', 'weapons.wt_sblade', 'craft.level.master', 19, 10, 'time.unit.hour', 'I039 (2), I006 (1), I020 (1), I029 (1), I024 (1), I041 (5)', 374, 750, 500,'availability.R')
  , ('B178', 'W085', 'Кинжал из кровавого камня', 'Bloodstone Dagger', 'exp_toc', 'weapons.wt_sblade', 'craft.level.journeyman', 14, 4, 'time.unit.hour', 'I001 (2), I014 (1), I023 (1), I026 (4), I029 (1), I034 (1)', 254, 500, NULL,'availability.R')
  , ('B179', 'W086', 'Ловец Мечей', 'Sword Catcher', 'dlc_rw2', 'weapons.wt_sblade', 'craft.level.master', 20, 6, 'time.unit.hour', 'I024 (2), I026 (2), I006 (1), I020 (1), I041 (6), I029 (2), I011 (1), I045 (2)', 375, 750, 500,'availability.P')
  , ('B180', 'W087', 'Низушечий рондель', 'Halfling Rondel', 'core', 'weapons.wt_sblade', 'craft.level.master', 19, 10, 'time.unit.hour', 'I032 (2), I006 (1), I019 (1), I029 (3), I023 (1), I025 (2)', 364, 726, 485,'availability.R')
  , ('B181', 'W088', 'Серебряный змеиный клык', 'Silver Viper Fang', 'hb', 'weapons.wt_sblade', 'craft.level.master', 17, 5, 'time.unit.hour', 'I006 (1), I042 (1), I063 (1), I060 (1), I029 (1)', 327, 0, NULL,'availability.R')
  , ('B182', 'W089', 'Стилет', 'Stiletto', 'core', 'weapons.wt_sblade', 'craft.level.journeyman', 16, 4, 'time.unit.hour', 'I012 (1), I009 (1), I032 (1), I013 (2), I023 (1), I029 (2), I002 (5)', 184, 412, 275,'availability.C')
  , ('B183', 'W091', 'Бешенство', 'Fury', 'core', 'weapons.wt_trap', 'craft.level.master', 16, 30, 'time.unit.minute', 'I012 (3), I011 (5), I041 (2), I008 (4), I070 (1)', 76, NULL, 114,'availability.P')
  , ('B184', 'W092', 'Капкан', 'Bear trap', 'hb', 'weapons.wt_trap', 'craft.level.novice', 12, 30, 'time.unit.minute', 'I037 (1), I007 (1), I044 (1), I012 (2), I011 (2)', 55, 110, 72,'availability.C')
  , ('B185', 'W093', 'Когтезуб', 'Clawer', 'core', 'weapons.wt_trap', 'craft.level.journeyman', 16, 30, 'time.unit.minute', 'I012 (3), I011 (3), I044 (2), I007 (1), I115 (1), I002 (1)', 74, NULL, 111,'availability.P')
  , ('B186', 'W094', 'Кусач', 'Biter', 'core', 'weapons.wt_trap', 'craft.level.journeyman', 16, 30, 'time.unit.minute', 'I012 (7), I011 (5), I037 (1), I046 (1)', 96, NULL, 144,'availability.P')
  , ('B187', 'W095', 'Метка', 'Marker', 'core', 'weapons.wt_trap', 'craft.level.novice', 14, 30, 'time.unit.minute', 'I012 (1), I011 (1), I086 (1), I075 (1), I001 (1)', 38, NULL, 57,'availability.P')
  , ('B188', 'W097', 'Пожарище', 'Conflagration', 'core', 'weapons.wt_trap', 'craft.level.master', 18, 30, 'time.unit.minute', 'I012 (2), I011 (2), I041 (2), I013 (2), I119 (1)', 81, NULL, 121,'availability.P')
  , ('B189', 'W098', 'Талгарская зима', 'Talgar Winter', 'core', 'weapons.wt_trap', 'craft.level.master', 18, 30, 'time.unit.minute', 'I012 (3), I011 (4), I088 (1), I062 (1)', 84, NULL, 126,'availability.P')
  , ('B190', 'W099', 'Армейский лук', 'War Bow', 'core', 'weapons.wt_bow', 'craft.level.master', 22, 11, 'time.unit.hour', 'I006 (6), I011 (8), I025 (3), I013 (4), I032 (4), I009 (4), I019 (1), I024 (2)', 626, 1296, 835,'availability.C')
  , ('B191', 'W100', 'Длинный лук', 'Long Bow', 'core', 'weapons.wt_bow', 'craft.level.journeyman', 16, 8, 'time.unit.hour', 'I006 (6), I011 (8), I013 (4), I009 (2), I025 (3), I043 (1), I019 (1)', 252, 712, 475,'availability.E')
  , ('B192', 'W101', 'Ковирский ламинированный лук', 'Kovirian Laminated Bow', 'hb', 'weapons.wt_bow', 'craft.level.master', 25, 13, 'time.unit.hour', 'I160 (3), I006 (2), I011 (4), I010 (4), I025 (3), I028 (4), I045 (4), I008 (4), I019 (1), I024 (2)', 1022, 2044, 1371,'availability.R')
  , ('B193', 'W102', 'Короткий лук', 'Short Bow', 'core', 'weapons.wt_bow', 'craft.level.novice', 15, 8, 'time.unit.hour', 'I006 (5), I011 (4), I013 (2), I009 (2), I025 (3), I037 (1), I020 (2)', 210, 434, 290,'availability.E')
  , ('B194', 'W103', 'Эльфский зефар', 'Elven Zefhar', 'core', 'weapons.wt_bow', 'craft.level.grand_master', 25, 13, 'time.unit.hour', 'I006 (8), I011 (8), I028 (8), I027 (2), I014 (4), I018 (4), I032 (3), I020 (2), I025 (9), I026 (6)', 830, 1660, 1100,'availability.R')
  , ('B195', 'W104', 'Эльфский походный лук', 'Elven Travel Bow', 'core', 'weapons.wt_bow', 'craft.level.master', 22, 11, 'time.unit.hour', 'I006 (4), I011 (4), I013 (4), I027 (1), I020 (1), I032 (2), I018 (3), I014 (2), I025 (5), I026 (3)', 432, 862, 575,'availability.R')
  , ('B196', 'W105', 'Эльфский сдвоенный лук', 'Elven Double Bow', 'hb', 'weapons.wt_bow', 'craft.level.master', 22, 12, 'time.unit.hour', 'I006 (6), I018 (5), I027 (2), I011 (5), I013 (7), I014 (3), I025 (6), I020 (2), I026 (5), I032 (2)', 611, 1242, 816,'availability.R')
  , ('B197', 'W107B', 'Метательный нож (х3)', 'Throwing Knife (х3)', 'core', 'weapons.wt_thrown', 'craft.level.novice', 8, 1, 'time.unit.hour', 'I043 (1)', 48, 74, 50,'availability.E')
  , ('B198', 'W108B', 'Метательный топор (х3)', 'Throwing Axe (х3)', 'core', 'weapons.wt_thrown', 'craft.level.novice', 10, 1, 'time.unit.hour', 'I012 (1), I043 (1)', 51, 116, 75,'availability.E')
  , ('B199', 'W109B', 'Орион (х3)', 'Orion (х3)', 'core', 'weapons.wt_thrown', 'craft.level.novice', 12, 1, 'time.unit.hour', 'I043 (1), I008 (2), I041 (1), I001 (3)', 62, 125, 100,'availability.P')
  , ('B200', 'W110', 'Отравленный коготь гарпии', 'Poisoned Harpy Claw', 'dlc_rw2', 'weapons.wt_thrown', 'craft.level.master', 22, 5, 'time.unit.hour', 'I032 (1), I023 (1), I024 (1), I026 (4), I029 (2), I115 (3)', 337, 675, 450,'availability.P')
  , ('B201', 'W111', 'Герцогский меч', 'Ducal Sword', 'dlc_rw5', 'weapons.wt_sword', 'craft.level.master', 23, 12, 'time.unit.hour', 'I032 (4), I036 (2), I019 (1), I006 (1), I029 (1)', 594, 1200, 800,'availability.R')
  , ('B202', 'W112', 'Гледдиф', 'Gleddyf', 'core', 'weapons.wt_sword', 'craft.level.novice', 14, 7, 'time.unit.hour', 'I012 (1), I019 (1), I020 (1), I037 (1), I043 (2), I008 (1), I009 (4)', 210, 426, 285,'availability.C')
  , ('B203', 'W113', 'Гномий гвихир', 'Gnomish Gwyhyr', 'core', 'weapons.wt_sword', 'craft.level.grand_master', 25, 13, 'time.unit.hour', 'I006 (2), I019 (1), I033 (2), I032 (1), I025 (3), I029 (4), I023 (1)', 818, 1628, 1090,'availability.R')
  , ('B204', 'W114', 'Деревянный меч', 'Wooden Sword', 'hb', 'weapons.wt_sword', 'craft.level.novice', 6, 2, 'time.unit.hour', 'I012 (2), I011 (1), I007 (1), I006 (2)', 50, 98, 67,'availability.E')
  , ('B205', 'W115', 'Железный меч', 'Iron Sword', 'hb', 'weapons.wt_sword', 'craft.level.novice', 12, 6, 'time.unit.hour', 'I012 (2), I011 (1), I020 (2), I037 (2)', 125, 256, 167,'availability.E')
  , ('B206', 'W116', 'Железный полуторный меч', 'Iron Long Sword', 'core', 'weapons.wt_sword', 'craft.level.novice', 10, 5, 'time.unit.hour', 'I012 (1), I037 (2), I020 (2)', 119, 240, 160,'availability.E')
  , ('B207', 'W117', 'Клинок бригады "Врихед"', 'Vrihedd Cavalry Sword', 'core', 'weapons.wt_sword', 'craft.level.master', 24, 12, 'time.unit.hour', 'I006 (2), I010 (1), I032 (4), I029 (3), I025 (4), I041 (4)', 558, 1117, 745,'availability.R')
  , ('B208', 'W118', 'Клинок из Виковаро', 'Vicovarian Blade', 'core', 'weapons.wt_sword', 'craft.level.master', 24, 12, 'time.unit.hour', 'I006 (3), I032 (4), I031 (2), I019 (3), I009 (4), I001 (4), I014 (3)', 660, 1282, 955,'availability.R')
  , ('B209', 'W119', 'Клинок из Вироледы', 'Viroledan Blade', 'exp_bot', 'weapons.wt_sword', 'craft.level.master', 25, 12, 'time.unit.hour', 'I032 (5), I023 (2), I024 (1), I019 (1), I006 (1), I029 (2), I115 (3)', 745, 1492, 995,'availability.R')
  , ('B210', 'W120', 'Клинок из Тир Тохаира', 'Tir Tochair Blade', 'core', 'weapons.wt_sword', 'craft.level.grand_master', 26, 13, 'time.unit.hour', 'I006 (2), I001 (4), I019 (1), I038 (2), I032 (1), I025 (4), I029 (1), I016 (1)', 888, 1776, 1175,'availability.R')
  , ('B211', 'W121', 'Корд', 'Kord', 'core', 'weapons.wt_sword', 'craft.level.master', 22, 11, 'time.unit.hour', 'I006 (1), I010 (1), I032 (3), I009 (4), I031 (1), I002 (1), I019 (2), I014 (7)', 525, 1012, 725,'availability.R')
  , ('B212', 'W122', 'Кригсверд', 'Krigsværd', 'core', 'weapons.wt_sword', 'craft.level.journeyman', 16, 8, 'time.unit.hour', 'I006 (2), I032 (3), I019 (2), I009 (4), I014 (7), I043 (3), I001 (2)', 438, 854, 570,'availability.C')
  , ('B213', 'W123', 'Махакамский сигилль', 'Mahakaman Sigil', 'hb', 'weapons.wt_sword', 'craft.level.grand_master', 23, 12, 'time.unit.hour', 'I039 (3), I032 (1), I024 (1), I025 (3), I019 (2), I011 (1), I029 (3)', 688, 1376, 924,'availability.R')
  , ('B214', 'W124', 'Меч из метеоритной стали', 'Meteorite Sword', 'core', 'weapons.wt_sword', 'craft.level.master', 20, 10, 'time.unit.hour', 'I006 (2), I020 (2), I029 (1), I026 (4), I025 (4), I040 (5)', 650, 1312, 875,'availability.R')
  , ('B215', 'W125', 'Меч охотника за колдуньями', 'Witch Hunter''s Sword', 'hb', 'weapons.wt_sword', 'craft.level.master', 21, 12, 'time.unit.hour', 'I006 (3), I041 (2), I045 (3), I032 (1), I019 (3), I013 (4), I025 (3)', 508, 1008, 679,'availability.P')
  , ('B216', 'W126', 'Охотничий фальшион', 'Hunter''s Falchion', 'core', 'weapons.wt_sword', 'craft.level.novice', 14, 7, 'time.unit.hour', 'I006 (1), I019 (2), I043 (2), I025 (4)', 240, 486, 325,'availability.C')
  , ('B217', 'W127', 'Рыцарский меч', 'Arming Sword', 'core', 'weapons.wt_sword', 'craft.level.novice', 13, 7, 'time.unit.hour', 'I012 (2), I011 (1), I019 (2), I043 (2)', 201, 404, 270,'availability.C')
  , ('B218', 'W128', 'Серебряный ведьмачий меч', 'Witcher''s Silver Sword', 'core', 'weapons.wt_sword', 'craft.level.master', 19, 10, 'time.unit.hour', 'I006 (2), I020 (2), I042 (4), I043 (1), I029 (2), I026 (1), I025 (1)', 498, 0, NULL,'availability.R')
  , ('B219', 'W129', 'Серебряный ведьмачий меч школы Волка', 'Wolven Silver Sword', 'dlc_wt', 'weapons.wt_sword', 'craft.level.master', 18, 9, 'time.unit.hour', 'I006 (2), I020 (2), I040 (2), I043 (3), I029 (2), I173 (1), I026 (2), I025 (1), I011 (1)', 656, 0, NULL,'availability.R')
  , ('B220', 'W130', 'Серебряный ведьмачий меч школы Грифона', 'Griffin Silver Sword', 'dlc_wt', 'weapons.wt_sword', 'craft.level.master', 18, 9, 'time.unit.hour', 'I006 (2), I020 (2), I029 (2), I043 (3), I026 (2), I025 (1), I011 (1), I040 (2), I096 (1)', 656, 0, NULL,'availability.R')
  , ('B221', 'W131', 'Серебряный ведьмачий меч школы Змеи', 'Serpentine Silver Sword', 'dlc_wt', 'weapons.wt_sword', 'craft.level.master', 18, 9, 'time.unit.hour', 'I006 (2), I040 (2), I043 (3), I020 (2), I029 (2), I025 (1), I011 (1), I115 (3), I087 (2), I026 (2)', 656, 0, NULL,'availability.R')
  , ('B222', 'W132', 'Серебряный ведьмачий меч школы Кота', 'Feline Silver Sword', 'dlc_wt', 'weapons.wt_sword', 'craft.level.master', 18, 9, 'time.unit.hour', 'I006 (2), I040 (2), I025 (1), I020 (2), I029 (2), I043 (3), I026 (2), I011 (1), I107 (2)', 656, 0, NULL,'availability.R')
  , ('B223', 'W133', 'Серебряный ведьмачий меч школы Мантикоры', 'Manticore Silver Sword', 'dlc_wt', 'weapons.wt_sword', 'craft.level.master', 18, 9, 'time.unit.hour', 'I006 (2), I020 (2), I040 (1), I043 (3), I033 (1), I025 (1), I029 (2), I014 (1), I026 (2), I011 (1)', 656, 0, NULL,'availability.R')
  , ('B224', 'W134', 'Серебряный ведьмачий меч школы Медведя', 'Ursine Silver Sword', 'dlc_wt', 'weapons.wt_sword', 'craft.level.master', 18, 9, 'time.unit.hour', 'I006 (2), I020 (2), I040 (2), I043 (3), I029 (2), I026 (2), I025 (1), I011 (1), I112 (1), I093 (1), I117 (1)', 656, 0, NULL,'availability.R')
  , ('B225', 'W135', 'Стальной ведьмачий меч', 'Witcher''s Steel Sword', 'core', 'weapons.wt_sword', 'craft.level.master', 18, 9, 'time.unit.hour', 'I006 (2), I020 (2), I040 (2), I043 (3), I029 (2), I026 (2), I025 (1), I011 (1)', 507, 0, NULL,'availability.R')
  , ('B226', 'W136', 'Стальной ведьмачий меч школы Волка', 'Wolven Steel Sword', 'dlc_wt', 'weapons.wt_sword', 'craft.level.master', 19, 10, 'time.unit.hour', 'I006 (2), I043 (1), I042 (4), I020 (2), I029 (2), I025 (1), I026 (1), I027 (1), I100 (2)', 597, 0, NULL,'availability.R')
  , ('B227', 'W137', 'Стальной ведьмачий меч школы Грифона', 'Griffin Steel Sword', 'dlc_wt', 'weapons.wt_sword', 'craft.level.master', 19, 10, 'time.unit.hour', 'I006 (2), I020 (2), I043 (1), I029 (2), I042 (4), I026 (2), I025 (2), I018 (2), I027 (1)', 597, 0, NULL,'availability.R')
  , ('B228', 'W138', 'Стальной ведьмачий меч школы Змеи', 'Serpentine Steel Sword', 'dlc_wt', 'weapons.wt_sword', 'craft.level.master', 19, 10, 'time.unit.hour', 'I006 (2), I042 (4), I043 (1), I020 (2), I029 (2), I025 (1), I026 (1), I124 (2)', 597, 0, NULL,'availability.R')
  , ('B229', 'W139', 'Стальной ведьмачий меч школы Кота', 'Feline Steel Sword', 'dlc_wt', 'weapons.wt_sword', 'craft.level.master', 19, 10, 'time.unit.hour', 'I006 (2), I020 (2), I029 (2), I043 (1), I026 (1), I042 (4), I025 (1), I125 (1)', 597, 0, NULL,'availability.R')
  , ('B230', 'W140', 'Стальной ведьмачий меч школы Мантикоры', 'Manticore Steel Sword', 'dlc_wt', 'weapons.wt_sword', 'craft.level.master', 19, 10, 'time.unit.hour', 'I006 (2), I020 (2), I042 (3), I029 (1), I026 (1), I025 (1), I033 (1), I058 (1)', 597, 0, NULL,'availability.R')
  , ('B231', 'W141', 'Стальной ведьмачий меч школы Медведя', 'Ursine Steel Sword', 'dlc_wt', 'weapons.wt_sword', 'craft.level.master', 19, 10, 'time.unit.hour', 'I006 (2), I020 (2), I042 (4), I043 (1), I029 (2), I026 (1), I025 (1), I145 (1), I090 (1)', 597, 0, NULL,'availability.R')
  , ('B232', 'W142', 'Счетовод', 'The Abacus', 'hb', 'weapons.wt_sword', 'craft.level.master', 20, 11, 'time.unit.hour', 'I006 (1), I020 (1), I039 (1), I032 (1), I029 (3), I026 (2), I023 (1)', 364, 770, 481,'availability.C')
  , ('B233', 'W143', 'Торрур', 'Torwyr', 'core', 'weapons.wt_sword', 'craft.level.master', 25, 13, 'time.unit.hour', 'I006 (3), I032 (5), I043 (2), I019 (3), I009 (5), I001 (4), I014 (2), I029 (1)', 760, 1462, 1075,'availability.R')
  , ('B234', 'W144', 'Фламберг', 'Flamberge', 'exp_bot', 'weapons.wt_sword', 'craft.level.master', 25, 13, 'time.unit.hour', 'I031 (5), I032 (4), I019 (2), I006 (1), I029 (2)', 764, 1540, 1025,'availability.P')
  , ('B235', 'W145', 'Эльфский мессер', 'Elven Messer', 'core', 'weapons.wt_sword', 'craft.level.master', 19, 10, 'time.unit.hour', 'I006 (2), I020 (3), I032 (3), I010 (1), I029 (1), I026 (1)', 446, 892, 595,'availability.R')
  , ('B236', 'W146', 'Эсбода', 'Esboda', 'core', 'weapons.wt_sword', 'craft.level.journeyman', 17, 9, 'time.unit.hour', 'I006 (2), I043 (3), I032 (2), I019 (2), I024 (1)', 481, 974, 650,'availability.P')
  , ('B237', 'W154', 'Гномий посох', 'Gnomish Staff', 'core', 'weapons.wt_staff', 'craft.level.master', 22, 11, 'time.unit.hour', 'I006 (6), I027 (5), I032 (1), I023 (3), I004 (1)', 685, 1364, 910,'availability.R')
  , ('B238', 'W155', 'Железный посох', 'Iron Staff', 'core', 'weapons.wt_staff', 'craft.level.master', 20, 10, 'time.unit.hour', 'I031 (4), I032 (1), I027 (2), I020 (1), I026 (4), I006 (1)', 506, 1012, 675,'availability.P')
  , ('B239', 'W156', 'Истинный связывающий посох', 'True Staff of Binding', 'exp_toc', 'weapons.wt_staff', 'craft.level.grand_master', 25, 13, 'time.unit.hour', 'I128 (4), I027 (5), I001 (1), I025 (1), I024 (3), I028 (5), I034 (1), I040 (3), I085 (2) ИЛИ W160 (1), I040 (3), I085 (2)', 1160, 2320, 0,'availability.R')
  , ('B240', 'W157', 'Посох', 'Staff', 'core', 'weapons.wt_staff', 'craft.level.journeyman', 18, 9, 'time.unit.hour', 'I012 (6), I043 (1), I027 (2), I025 (2), I013 (2)', 250, 502, 335,'availability.C')
  , ('B241', 'W158', 'Посох с кристаллом', 'Crystal Staff', 'core', 'weapons.wt_staff', 'craft.level.master', 25, 13, 'time.unit.hour', 'I012 (6), I043 (2), I027 (4), I034 (1), I025 (3), I013 (2), I026 (4), I024 (1)', 623, 1296, 835,'availability.R')
  , ('B242', 'W159', 'Посох с крюком', 'Hooked Staff', 'core', 'weapons.wt_staff', 'craft.level.journeyman', 18, 9, 'time.unit.hour', 'I012 (6), I043 (1), I027 (2), I025 (2), I013 (3), I043 (2), I026 (2), I019 (1), I011 (4)', 412, 824, 550,'availability.P')
  , ('B243', 'W160', 'Связывающий посох', 'Staff of Binding', 'exp_toc', 'weapons.wt_staff', 'craft.level.master', 19, 12, 'time.unit.hour', 'I012 (4), I027 (5), I001 (1), I025 (1), I024 (3), I028 (5), I034 (1)', 666, 1332, 0,'availability.R')
  , ('B244', 'W161', 'Эльфский дорожный посох', 'Elven Walking Staff', 'core', 'weapons.wt_staff', 'craft.level.grand_master', 25, 13, 'time.unit.hour', 'I006 (6), I036 (1), I025 (6), I010 (1), I022 (2), I032 (1), I027 (3), I034 (1)', 735, 1470, 975,'availability.R')
  , ('B245', 'W163', 'Боевой топор', 'Battle Axe', 'core', 'weapons.wt_axe', 'craft.level.journeyman', 17, 9, 'time.unit.hour', 'I006 (4), I043 (3), I020 (3), I025 (4), I028 (4), I041 (5)', 389, 786, 525,'availability.C')
  , ('B246', 'W164', 'Гномий чёрный топор', 'Gnomish Black Axe', 'core', 'weapons.wt_axe', 'craft.level.grand_master', 25, 13, 'time.unit.hour', 'I006 (4), I019 (2), I033 (1), I032 (3), I028 (1), I029 (1)', 688, 1376, 910,'availability.R')
  , ('B247', 'W165', 'Краснолюдский топор', 'Dwarven Axe', 'core', 'weapons.wt_axe', 'craft.level.master', 24, 12, 'time.unit.hour', 'I039 (3), I006 (4), I019 (2), I026 (4), I029 (1), I041 (2), I002 (3)', 555, 1110, 740,'availability.R')
  , ('B248', 'W166', 'Топор', 'Hand Axe', 'core', 'weapons.wt_axe', 'craft.level.novice', 10, 3, 'time.unit.hour', 'I006 (1), I043 (1), I019 (1), I020 (1), I009 (4)', 148, 306, 205,'availability.E')
  , ('B249', 'W167', 'Топор берсерка', 'Berserker''s Axe', 'core', 'weapons.wt_axe', 'craft.level.master', 25, 13, 'time.unit.hour', 'I039 (4), I006 (5), I019 (1), I043 (2), I009 (1), I029 (1), I025 (1)', 772, 1440, 960,'availability.P')
  , ('B250', 'W169', 'Стальной меч школы Улитки', 'Gastropod Steel Sword', 'dlc_sch_snail', 'weapons.wt_sword', 'craft.level.master', 18, 13, 'time.unit.hour', 'I006 (3), I020 (2), I040 (1), I043 (7), I037 (1), I029 (2), I026 (2), I025 (2), I011 (1), I002 (1)', 656, 0, NULL,'availability.R')
  , ('B251', 'W170', 'Серебряный меч школы Улитки', 'Gastropod Silver Sword', 'dlc_sch_snail', 'weapons.wt_sword', 'craft.level.master', 19, 15, 'time.unit.hour', 'I006 (3), I020 (2), I042 (2), I043 (2), I037 (4), I029 (2), I026 (1), I025 (2), I002 (1), I041 (10)', 597, 0, NULL,'availability.R')
  , ('B252', 'A064', 'Броня школы Улитки', 'Gastropod Armor', 'dlc_sch_snail', 'bodypart.full', 'craft.level.master', 18, 24, 'time.unit.hour', 'I004 (10), I011 (10), I037 (10), I043 (10), I040 (2), I025 (10), I028 (10), I089 (1), I002 (20), I041 (30)', 1538, 0, NULL,'availability.R')
  , ('B253', 'T126', 'Обычная инвалидная коляска', 'Basic Wheelchair', 'dlc_wpaw', 'general_gear.group.transport', 'craft.level.novice', 13, 5, 'time.unit.hour', 'I003 (5), I007 (1), I012 (8)', 38, 76, 50,'availability.E')
  , ('B254', 'T127', 'Качественная инвалидная коляска', 'Quality Wheelchair', 'dlc_wpaw', 'general_gear.group.transport', 'craft.level.journeyman', 16, 8, 'time.unit.hour', 'I003 (6), I025 (2), I043 (1), I020 (2), I012 (8)', 150, 300, 200,'availability.P')
  , ('B255', 'T128', 'Обычный протез', 'Basic Prosthesis', 'dlc_wpaw', 'general_gear.group.transport', 'craft.level.novice', 13, 5, 'time.unit.hour', 'I003 (1), I012 (3), I020 (1)', 38, 76, 50,'availability.E')
  , ('B256', 'T129', 'Магический протез', 'Magical Prosthesis', 'dlc_wpaw', 'general_gear.group.transport', 'craft.level.master', 10, 8, 'time.unit.hour', 'I003 (3), I004 (2), I025 (4), I026 (4), I027 (2), I006 (3), I020 (1), I043 (1)', 375, 750, 500,'availability.R')
  , ('B257', 'T130', 'Ведьмачий протез', 'Witcher Prosthesis', 'dlc_wpaw', 'general_gear.group.transport', 'craft.level.master', 22, 9, 'time.unit.hour', 'I003 (2), I004 (2), I025 (2), I026 (6), I027 (3), I006 (2), I019 (1), I029 (1), I042 (1), I043 (2)', 600, 1200, 800,'availability.R')
  , ('B258', 'T131', 'Протез-проводник', 'Conduit Prosthesis', 'dlc_wpaw', 'general_gear.group.transport', 'craft.level.master', 24, 10, 'time.unit.hour', 'I003 (4), I004 (2), I025 (4), I026 (8), I027 (4), I034 (1), I006 (3), I020 (1), I085 (1), I043 (1), I013 (1)', 750, 1500, 1000,'availability.R')
),
ins_i18n_tech AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    -- T041: includes non-item operation in components
    SELECT ck_id('witcher_cc.items.blueprint.tech_val.T041_01'), 'items', 'blueprint_tech_val', 'ru', 'Обработка в месте силы (1ч) (1)'
    UNION ALL
    SELECT ck_id('witcher_cc.items.blueprint.tech_val.T041_01'), 'items', 'blueprint_tech_val', 'en', 'Обработка в месте силы (1ч) (1)'
    UNION ALL
    -- T044: free-form text (commas inside)
    SELECT ck_id('witcher_cc.items.blueprint.tech_val.T044_01'), 'items', 'blueprint_tech_val', 'ru', '3 различных материала, Используемый навык: Искусство (Fine Arts)'
    UNION ALL
    SELECT ck_id('witcher_cc.items.blueprint.tech_val.T044_01'), 'items', 'blueprint_tech_val', 'en', '3 различных материала, Используемый навык: Искусство (Fine Arts)'
    UNION ALL
    -- W156: "ИЛИ" token
    SELECT ck_id('witcher_cc.items.blueprint.tech_val.W156_01'), 'items', 'blueprint_tech_val', 'ru', 'ИЛИ'
    UNION ALL
    SELECT ck_id('witcher_cc.items.blueprint.tech_val.W156_01'), 'items', 'blueprint_tech_val', 'en', 'OR'
  ) foo
  ON CONFLICT (id, lang) DO NOTHING
),
ins_i18n_blueprint_B AS (
  -- Названия чертежей с постфиксом B (нет в таблицах вещей) — сохраняем в i18n, id = ck_id('witcher_cc.items.blueprint.name.'||item_id)
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT id, entity, entity_field, lang, text
    FROM (
      SELECT ck_id('witcher_cc.items.blueprint.name.' || rd.item_id) AS id
           , 'items'::text AS entity
           , 'blueprint_name'::text AS entity_field
           , 'ru'::text AS lang
           , nullif(trim(rd.name_ru), '') AS text
        FROM raw_data rd
       WHERE right(rd.item_id, 1) = 'B'
         AND nullif(trim(rd.name_ru), '') IS NOT NULL
      UNION ALL
      SELECT ck_id('witcher_cc.items.blueprint.name.' || rd.item_id)
           , 'items'
           , 'blueprint_name'
           , 'en'
           , nullif(trim(rd.name_en), '')
        FROM raw_data rd
       WHERE right(rd.item_id, 1) = 'B'
         AND nullif(trim(rd.name_en), '') IS NOT NULL
    ) foo
  ON CONFLICT (id, lang) DO UPDATE SET text = EXCLUDED.text
),
ins_i18n_blueprint_groups AS (
  -- Create generalized group labels like "Оружие - Арбалеты", "Броня - Ноги"
  -- Stored under deterministic UUID: ck_id('blueprint_groups.'||ck_id(<group_key>)::text)
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT
    ck_id('blueprint_groups.' || ck_id(gk.group_key)::text) AS id,
    'items' AS entity,
    'blueprint_groups' AS entity_field,
    gk.lang,
    (
      CASE
        WHEN gk.group_key LIKE 'weapons.%' THEN (CASE WHEN gk.lang = 'ru' THEN 'Оружие' ELSE 'Weapons' END)
        WHEN gk.group_key LIKE 'bodypart.%' THEN (CASE WHEN gk.lang = 'ru' THEN 'Броня' ELSE 'Armor' END)
        WHEN gk.group_key LIKE 'ingredients.%' THEN (CASE WHEN gk.lang = 'ru' THEN 'Ингредиенты' ELSE 'Ingredients' END)
        WHEN gk.group_key LIKE 'upgrades.%' THEN (CASE WHEN gk.lang = 'ru' THEN 'Улучшения' ELSE 'Upgrades' END)
        WHEN gk.group_key LIKE 'general_gear.group.%' THEN (CASE WHEN gk.lang = 'ru' THEN 'Обычные вещи' ELSE 'General Gear' END)
        WHEN gk.group_key LIKE 'reciples.group.%' THEN (CASE WHEN gk.lang = 'ru' THEN 'Рецепты' ELSE 'Recipes' END)
        ELSE (CASE WHEN gk.lang = 'ru' THEN 'Другое' ELSE 'Other' END)
      END
      || ' - ' || gk.group_text
    ) AS text
  FROM (
    SELECT DISTINCT
      rd.group_key,
      l.lang,
      it.text AS group_text
    FROM raw_data rd
    CROSS JOIN (VALUES ('ru'::text), ('en'::text)) AS l(lang)
    JOIN i18n_text it
      ON it.id = ck_id(rd.group_key)
     AND it.lang = l.lang
     AND it.entity = 'items'
     AND it.entity_field = 'dict'
    WHERE rd.group_key IS NOT NULL
      AND rd.group_key <> ''
  ) gk
  ON CONFLICT (id, lang) DO NOTHING
),
ins_i18n_blueprint_item_desc_tpl AS (
  -- Templates for item description formatting in wcc_item_blueprints_v (use replace on placeholders).
  -- One row per language and per item type.
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    -- weapon
    SELECT ck_id('witcher_cc.items.blueprint.item_desc_tpl.weapon'), 'items', 'blueprint_item_desc_tpl', 'ru',
      E'Урон: {dmg}\nНадежность: {reliability}\nХват: {hands}\nСкрытность: {concealment}\nУБ: {enhancements}\nЭффекты: {effect_names}'
    UNION ALL
    SELECT ck_id('witcher_cc.items.blueprint.item_desc_tpl.weapon'), 'items', 'blueprint_item_desc_tpl', 'en',
      E'DMG: {dmg}\nReliability: {reliability}\nHands: {hands}\nConcealment: {concealment}\nEnh.: {enhancements}\nEffects: {effect_names}'

    UNION ALL
    -- armor (ПБ)
    SELECT ck_id('witcher_cc.items.blueprint.item_desc_tpl.armor'), 'items', 'blueprint_item_desc_tpl', 'ru',
      E'ПБ: {stopping_power}\nСкованность: {encumbrance}\nУБ: {enhancements}\nЭффекты: {effect_names}'
    UNION ALL
    SELECT ck_id('witcher_cc.items.blueprint.item_desc_tpl.armor'), 'items', 'blueprint_item_desc_tpl', 'en',
      E'SP: {stopping_power}\nEnc.: {encumbrance}\nEnh.: {enhancements}\nEffects: {effect_names}'
    UNION ALL
    -- armor для щитов (Надежность)
    SELECT ck_id('witcher_cc.items.blueprint.item_desc_tpl.armor_shield'), 'items', 'blueprint_item_desc_tpl', 'ru',
      E'Надежность: {stopping_power}\nСкованность: {encumbrance}\nУБ: {enhancements}\nЭффекты: {effect_names}'
    UNION ALL
    SELECT ck_id('witcher_cc.items.blueprint.item_desc_tpl.armor_shield'), 'items', 'blueprint_item_desc_tpl', 'en',
      E'Reliability: {stopping_power}\nEnc.: {encumbrance}\nEnh.: {enhancements}\nEffects: {effect_names}'

    UNION ALL
    -- ingredient (craft)
    SELECT ck_id('witcher_cc.items.blueprint.item_desc_tpl.ingredient'), 'items', 'blueprint_item_desc_tpl', 'ru',
      E'Ингредиент для крафта\nВес: {weight}'
    UNION ALL
    SELECT ck_id('witcher_cc.items.blueprint.item_desc_tpl.ingredient'), 'items', 'blueprint_item_desc_tpl', 'en',
      E'Craft ingredient\nWeight: {weight}'

    UNION ALL
    -- general gear
    SELECT ck_id('witcher_cc.items.blueprint.item_desc_tpl.general_gear'), 'items', 'blueprint_item_desc_tpl', 'ru',
      E'Группа: {group_name}\nОписание: {gear_description}\nСкрытность: {concealment}\nВес: {weight}'
    UNION ALL
    SELECT ck_id('witcher_cc.items.blueprint.item_desc_tpl.general_gear'), 'items', 'blueprint_item_desc_tpl', 'en',
      E'Group: {group_name}\nDesc: {gear_description}\nConcealment: {concealment}\nWeight: {weight}'

    UNION ALL
    -- upgrade
    SELECT ck_id('witcher_cc.items.blueprint.item_desc_tpl.upgrade'), 'items', 'blueprint_item_desc_tpl', 'ru',
      E'Группа: {upgrade_group}\nЦель: {target}\nЭффекты: {effect_names}\nСлоты: {slots}'
    UNION ALL
    SELECT ck_id('witcher_cc.items.blueprint.item_desc_tpl.upgrade'), 'items', 'blueprint_item_desc_tpl', 'en',
      E'Group: {upgrade_group}\nTarget: {target}\nEffects: {effect_names}\nSlots: {slots}'
  ) foo
  ON CONFLICT (id, lang) DO UPDATE SET text = EXCLUDED.text
)
INSERT INTO wcc_item_blueprints (
  b_id, item_id, dlc_dlc_id,
  name_id,
  availability_id,
  group_id, craft_level_id,
  difficulty_check, time_value, time_unit_id,
  components,
  price_components, price_blueprint, price_item
)
SELECT rd.b_id
     , rd.item_id
     , rd.dlc_id AS dlc_dlc_id
     , CASE
         WHEN right(rd.item_id, 1) = 'B' THEN ck_id('witcher_cc.items.blueprint.name.' || rd.item_id)
         ELSE CASE
           WHEN rd.item_id ~ '^A[0-9]{3}$' THEN ck_id('witcher_cc.items.armor.name.'||rd.item_id)
           WHEN rd.item_id ~ '^I[0-9]{3}$' THEN ck_id('witcher_cc.items.ingredient.name.'||rd.item_id)
           WHEN rd.item_id ~ '^T[0-9]{3}$' THEN ck_id('witcher_cc.items.general_gear.name.'||rd.item_id)
           WHEN rd.item_id ~ '^U[0-9]{3}$' THEN ck_id('witcher_cc.items.upgrade.name.'||rd.item_id)
           WHEN rd.item_id ~ '^W[0-9]{3}$' THEN ck_id('witcher_cc.items.weapon.name.'||rd.item_id)
           WHEN rd.item_id ~ '^R[0-9]{3}$' THEN ck_id('witcher_cc.items.recipe.name.'||rd.item_id)
           ELSE NULL
         END
       END AS name_id
     , CASE WHEN rd.availability_key IS NOT NULL THEN ck_id(rd.availability_key) ELSE NULL END AS availability_id
     , CASE WHEN rd.group_key IS NOT NULL THEN ck_id(rd.group_key) ELSE NULL END AS group_id
     , CASE WHEN rd.craft_level_key IS NOT NULL THEN ck_id(rd.craft_level_key) ELSE NULL END AS craft_level_id
     , rd.difficulty_check
     , rd.time_value
     , CASE WHEN rd.time_unit_key IS NOT NULL THEN ck_id(rd.time_unit_key) ELSE NULL END AS time_unit_id
     , CASE
         WHEN rd.components_raw IS NULL OR trim(rd.components_raw) = '' THEN NULL
         WHEN rd.item_id = 'T044' THEN jsonb_build_array(
           jsonb_build_object('id', ck_id('witcher_cc.items.blueprint.tech_val.T044_01')::text, 'qty', NULL)
         )
         ELSE (
           SELECT
             CASE
               WHEN jsonb_agg(comp.obj ORDER BY comp.pos) IS NULL THEN NULL
               ELSE jsonb_agg(comp.obj ORDER BY comp.pos)
             END
           FROM (
             SELECT
               pieces.pos,
               jsonb_build_object(
                 'id',
                 (
                   CASE
                     WHEN pieces.is_or THEN ck_id('witcher_cc.items.blueprint.tech_val.W156_01')
                     ELSE
                       COALESCE(
                         -- normal item-id mapping by prefix
                         CASE
                           WHEN pieces.code ~ '^A[0-9]{3}$' THEN ck_id('witcher_cc.items.armor.name.'||pieces.code)
                           WHEN pieces.code ~ '^I[0-9]{3}$' THEN ck_id('witcher_cc.items.ingredient.name.'||pieces.code)
                           WHEN pieces.code ~ '^T[0-9]{3}$' THEN ck_id('witcher_cc.items.general_gear.name.'||pieces.code)
                           WHEN pieces.code ~ '^U[0-9]{3}$' THEN ck_id('witcher_cc.items.upgrade.name.'||pieces.code)
                           WHEN pieces.code ~ '^W[0-9]{3}$' THEN ck_id('witcher_cc.items.weapon.name.'||pieces.code)
                           WHEN pieces.code ~ '^R[0-9]{3}$' THEN ck_id('witcher_cc.items.recipe.name.'||pieces.code)
                           ELSE NULL
                         END,
                         -- known exception: T041 tech op in components
                         CASE WHEN rd.item_id = 'T041' THEN ck_id('witcher_cc.items.blueprint.tech_val.T041_01') ELSE NULL END
                       )
                   END
                 )::text,
                 'qty',
                 CASE
                   WHEN pieces.is_or THEN NULL
                   WHEN rd.item_id = 'T041' AND (
                     pieces.code IS NULL OR pieces.code !~ '^[AITUWR][0-9]{3}$'
                   ) THEN NULL
                   ELSE pieces.qty
                 END
               ) AS obj
             FROM (
               SELECT
                 -- explode by commas first
                 CASE
                   WHEN rd.item_id = 'W156' AND position('ИЛИ' IN part.part_raw) > 0 THEN (part.ord * 10) + u.subpos
                   ELSE part.ord * 10
                 END AS pos,
                 u.is_or,
                 u.qty,
                 u.code
               FROM (
                 SELECT token AS part_raw, ord
                 FROM regexp_split_to_table(rd.components_raw, '\s*,\s*') WITH ORDINALITY AS s(token, ord)
               ) part
               CROSS JOIN LATERAL (
                 -- W156: split "… ИЛИ …" into 3 logical components; otherwise keep as is
                 SELECT 1 AS subpos,
                        false AS is_or,
                        (regexp_match(trim(split_part(part.part_raw, 'ИЛИ', 1)), '\((\d+)\)\s*$'))[1]::int AS qty,
                        trim(regexp_replace(trim(split_part(part.part_raw, 'ИЛИ', 1)), '\s*\([^)]*\)\s*$', '')) AS code
                  WHERE rd.item_id = 'W156'
                    AND position('ИЛИ' IN part.part_raw) > 0
                    AND nullif(trim(split_part(part.part_raw, 'ИЛИ', 1)), '') IS NOT NULL
                 UNION ALL
                 SELECT 2 AS subpos,
                        true AS is_or,
                        NULL::int AS qty,
                        NULL::text AS code
                  WHERE rd.item_id = 'W156'
                    AND position('ИЛИ' IN part.part_raw) > 0
                 UNION ALL
                 SELECT 3 AS subpos,
                        false AS is_or,
                        (regexp_match(trim(split_part(part.part_raw, 'ИЛИ', 2)), '\((\d+)\)\s*$'))[1]::int AS qty,
                        trim(regexp_replace(trim(split_part(part.part_raw, 'ИЛИ', 2)), '\s*\([^)]*\)\s*$', '')) AS code
                  WHERE rd.item_id = 'W156'
                    AND position('ИЛИ' IN part.part_raw) > 0
                    AND nullif(trim(split_part(part.part_raw, 'ИЛИ', 2)), '') IS NOT NULL
                 UNION ALL
                 SELECT 0 AS subpos,
                        false AS is_or,
                        (regexp_match(trim(part.part_raw), '\((\d+)\)\s*$'))[1]::int AS qty,
                        trim(regexp_replace(trim(part.part_raw), '\s*\([^)]*\)\s*$', '')) AS code
                  WHERE NOT (rd.item_id = 'W156' AND position('ИЛИ' IN part.part_raw) > 0)
               ) u
             ) pieces
             WHERE (pieces.is_or OR (pieces.code IS NOT NULL AND pieces.code <> ''))
           ) comp
           WHERE (comp.obj->>'id') IS NOT NULL
         )
       END AS components
     , rd.price_components
     , rd.price_blueprint
     , rd.price_item
  FROM raw_data rd
ON CONFLICT (b_id) DO UPDATE
SET
  item_id = EXCLUDED.item_id,
  dlc_dlc_id = EXCLUDED.dlc_dlc_id,
  name_id = EXCLUDED.name_id,
  availability_id = EXCLUDED.availability_id,
  group_id = EXCLUDED.group_id,
  craft_level_id = EXCLUDED.craft_level_id,
  difficulty_check = EXCLUDED.difficulty_check,
  time_value = EXCLUDED.time_value,
  time_unit_id = EXCLUDED.time_unit_id,
  components = EXCLUDED.components,
  price_components = EXCLUDED.price_components,
  price_blueprint = EXCLUDED.price_blueprint,
  price_item = EXCLUDED.price_item;
