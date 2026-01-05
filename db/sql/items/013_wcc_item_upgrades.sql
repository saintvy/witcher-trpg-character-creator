CREATE TABLE IF NOT EXISTS wcc_item_upgrades (
    u_id            varchar(10) PRIMARY KEY,          -- e.g. 'U001'
    dlc_dlc_id      varchar(64) NOT NULL REFERENCES wcc_dlcs(dlc_id), -- source_id (core, hb, dlc_*, exp_*)

    name_id         uuid NOT NULL,                    -- ck_id('witcher_cc.items.upgrade.name.'||u_id)

    -- Reused dictionary fields (see 001_wcc_items_dict.sql)
    group_id        uuid NULL,                        -- ck_id('upgrades.*')
    availability_id uuid NULL,                        -- ck_id('availability.*')
    target_id       uuid NULL,                        -- ck_id('upgrades.target.*')

    slots           integer NOT NULL DEFAULT 1,        -- number of slots required
    price           integer NULL,
    weight          numeric(12,1) NULL
);

COMMENT ON TABLE wcc_item_upgrades IS
  'Улучшения для оружия и брони (руны, глифы, модификации арбалета и т.д.). Источник (DLC) через wcc_dlcs, локализуемые поля через i18n_text UUID (ck_id). Группа/доступность/цель — из общего словаря (001_wcc_items_dict.sql).';

COMMENT ON COLUMN wcc_item_upgrades.dlc_dlc_id IS
  'FK на wcc_dlcs.dlc_id (источник/пакет: core/hb/dlc_*/exp_*).';

COMMENT ON COLUMN wcc_item_upgrades.name_id IS
  'i18n UUID для названия улучшения. Генерируется детерминированно: ck_id(''witcher_cc.items.upgrade.name.''||u_id).';

COMMENT ON COLUMN wcc_item_upgrades.group_id IS
  'i18n UUID для группы улучшения. Использует ключи из словаря: ck_id(''upgrades.*'').';

COMMENT ON COLUMN wcc_item_upgrades.availability_id IS
  'i18n UUID для доступности улучшения. Использует ключи из словаря: ck_id(''availability.*'').';

COMMENT ON COLUMN wcc_item_upgrades.target_id IS
  'i18n UUID для цели улучшения. Использует ключи из словаря: ck_id(''upgrades.target.*'').';

WITH raw_data (
  u_id, source_id, group_key, name_ru, name_en, availability_key, target_key, slots, price, weight
) AS ( VALUES
  ('U001','dlc_rw3','upgrades.crossbow','Скеллигское стремя','Skelliger Brace','availability.C','upgrades.target.crossbow',1,375,'0,5'),
  ('U002','dlc_rw3','upgrades.crossbow','Балансировочное стремя','Stabilizing Brace','availability.C','upgrades.target.crossbow',1,395,'0,5'),
  ('U003','dlc_rw3','upgrades.crossbow','Нильфгаардский прицел','Nilfgaardian Sights','availability.P','upgrades.target.crossbow',1,275,'0,1'),
  ('U004','dlc_rw3','upgrades.crossbow','Усиленная тетива','High Tension String','availability.P','upgrades.target.crossbow',1,425,'0,1'),
  ('U005','dlc_rw3','upgrades.crossbow','Улучшенный ворот','Improved Windlass','availability.R','upgrades.target.crossbow',1,440,'0,5'),
  ('U006','core','upgrades.rune','Велес','Veles','availability.P','upgrades.target.weapon',1,600,'0,5'),
  ('U007','core','upgrades.rune','Даждьбог','Dazhbog','availability.P','upgrades.target.weapon',1,600,'0,5'),
  ('U008','core','upgrades.rune','Девана','Devanna','availability.P','upgrades.target.weapon',1,575,'0,5'),
  ('U009','core','upgrades.rune','Зоря','Zoria','availability.P','upgrades.target.weapon',1,550,'0,5'),
  ('U010','core','upgrades.rune','Марена','Morana','availability.P','upgrades.target.weapon',1,575,'0,5'),
  ('U011','core','upgrades.rune','Перун','Perun','availability.P','upgrades.target.weapon',1,575,'0,5'),
  ('U012','core','upgrades.rune','Сварог','Svarog','availability.P','upgrades.target.weapon',1,600,'0,5'),
  ('U013','core','upgrades.rune','Стрибог','Stribog','availability.P','upgrades.target.weapon',1,600,'0,5'),
  ('U014','core','upgrades.rune','Триглав','Triglav','availability.P','upgrades.target.weapon',1,575,'0,5'),
  ('U015','core','upgrades.rune','Чернобог','Chernobog','availability.P','upgrades.target.weapon',1,575,'0,5'),
  ('U016','exp_toc','upgrades.runeword','Продление','Prolongation','availability.R','upgrades.target.weapon',2,1175,'1'),
  ('U017','exp_toc','upgrades.runeword','Пылание','Burning','availability.R','upgrades.target.weapon',2,1175,'1'),
  ('U018','exp_toc','upgrades.runeword','Спокойствие','Placation','availability.R','upgrades.target.weapon',2,1175,'1'),
  ('U019','exp_toc','upgrades.runeword','Закрепление','Preservation','availability.R','upgrades.target.weapon_or_shield',2,1150,'1'),
  ('U020','exp_toc','upgrades.runeword','Рассечение','Shearing','availability.R','upgrades.target.weapon',2,1150,'1'),
  ('U021','exp_toc','upgrades.runeword','Отражение','Deflection','availability.R','upgrades.target.weapon',3,1750,'1,5'),
  ('U022','exp_toc','upgrades.runeword','Истощение','Depletion','availability.R','upgrades.target.weapon',3,1775,'1,5'),
  ('U023','exp_toc','upgrades.runeword','Обновление','Rejuvenation','availability.R','upgrades.target.weapon',3,1750,'1,5'),
  ('U024','core','upgrades.armor','Ткань','Fiber','availability.E','upgrades.target.any_armor',1,40,'0,5'),
  ('U025','core','upgrades.armor','Клёпанная кожа','Studded Leather','availability.C','upgrades.target.any_armor',1,80,'1'),
  ('U026','core','upgrades.armor','Кольчужное','Chain Mail','availability.P','upgrades.target.any_armor',1,125,'3'),
  ('U027','core','upgrades.armor','Укрепленная кожа','Hardened Leather','availability.C','upgrades.target.any_armor',1,130,'1,5'),
  ('U028','core','upgrades.armor','Стальное','Steel','availability.P','upgrades.target.any_armor',1,145,'3,5'),
  ('U029','core','upgrades.armor','Краснолюдское усиление','Dwarven','availability.R','upgrades.target.any_armor',1,195,'3,5'),
  ('U030','core','upgrades.armor','Эльфийское усиление','Elven','availability.R','upgrades.target.any_armor',1,200,'0,5'),
  ('U031','exp_toc','upgrades.glyph','Глиф улучшения','Glyph of Enhancement','availability.P','upgrades.target.any_armor',1,100,'0,5'),
  ('U032','exp_toc','upgrades.glyph','Глиф связывания','Glyph of Binding','availability.P','upgrades.target.any_armor',1,200,'0,5'),
  ('U033','exp_toc','upgrades.glyph','Глиф обороны','Glyph of Defense','availability.P','upgrades.target.any_armor',1,300,'0,5'),
  ('U034','exp_toc','upgrades.glyph','Глиф выздоровления','Glyph of Healing','availability.P','upgrades.target.any_armor',1,450,'0,5'),
  ('U035','core','upgrades.glyph','Глиф магии','Glyph of Magic','availability.P','upgrades.target.any_armor',1,575,'0,5'),
  ('U036','core','upgrades.glyph','Глиф воздуха','Glyph of Air','availability.P','upgrades.target.any_armor',1,575,'0,5'),
  ('U037','core','upgrades.glyph','Глиф земли','Glyph of Earth','availability.P','upgrades.target.any_armor',1,575,'0,5'),
  ('U038','core','upgrades.glyph','Глиф огня','Glyph of Fire','availability.P','upgrades.target.any_armor',1,575,'0,5'),
  ('U039','core','upgrades.glyph','Глиф воды','Glyph of Water','availability.P','upgrades.target.any_armor',1,575,'0,5'),
  ('U040','exp_toc','upgrades.glyphword','Баланс','Balance','availability.R','upgrades.target.any_armor',2,550,'1'),
  ('U041','exp_toc','upgrades.glyphword','Воздаяние','Retribution','availability.R','upgrades.target.any_armor',3,1250,'1,5'),
  ('U042','exp_toc','upgrades.glyphword','Кольцо','Rotation','availability.R','upgrades.target.legs',2,300,'1'),
  ('U043','exp_toc','upgrades.glyphword','Очарование','Beguilement','availability.R','upgrades.target.head',2,1150,'1'),
  ('U044','exp_toc','upgrades.glyphword','Сияние','Shining','availability.R','upgrades.target.torso',2,875,'1'),
  ('U045','exp_toc','upgrades.glyphword','Тяжесть','Heft','availability.R','upgrades.target.any_armor',2,550,'1'),
  ('U046','exp_toc','upgrades.glyphword','Щит','Protection','availability.R','upgrades.target.torso',3,1450,'1,5')
),
ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    -- Upgrade names
    SELECT ck_id('witcher_cc.items.upgrade.name.'||rd.u_id),
           'items',
           'upgrade_names',
           'ru',
           rd.name_ru
      FROM raw_data rd
     WHERE nullif(rd.name_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.items.upgrade.name.'||rd.u_id),
           'items',
           'upgrade_names',
           'en',
           rd.name_en
      FROM raw_data rd
     WHERE nullif(rd.name_en,'') IS NOT NULL
  ) foo
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO wcc_item_upgrades (
  u_id, dlc_dlc_id, name_id,
  group_id, availability_id, target_id,
  slots, price, weight
)
SELECT rd.u_id
     , rd.source_id AS dlc_dlc_id
     , ck_id('witcher_cc.items.upgrade.name.'||rd.u_id) AS name_id
     , ck_id(rd.group_key) AS group_id
     , ck_id(rd.availability_key) AS availability_id
     , ck_id(rd.target_key) AS target_id
     , rd.slots
     , rd.price
     , CAST(NULLIF(REPLACE(rd.weight, ',', '.'), '') AS numeric) AS weight
  FROM raw_data rd
ON CONFLICT (u_id) DO UPDATE
SET
  dlc_dlc_id = EXCLUDED.dlc_dlc_id,
  name_id = EXCLUDED.name_id,
  group_id = EXCLUDED.group_id,
  availability_id = EXCLUDED.availability_id,
  target_id = EXCLUDED.target_id,
  slots = EXCLUDED.slots,
  price = EXCLUDED.price,
  weight = EXCLUDED.weight;



