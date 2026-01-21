CREATE TABLE IF NOT EXISTS wcc_item_vehicles (
    wt_id            varchar(10) PRIMARY KEY,          -- e.g. 'WT001'
    dlc_dlc_id       varchar(64) NOT NULL REFERENCES wcc_dlcs(dlc_id), -- source_id (core, dlc_*, exp_*)

    name_id          uuid NOT NULL,                    -- ck_id('witcher_cc.items.vehicle.name.'||wt_id)

    subgroup_id      uuid NULL,                        -- ck_id('vehicles.subgroup.*')

    base             integer NULL,                     -- Атлетика + ЛВК (NULL для N/A)
    control_modifier integer NULL,                     -- Модификатор управления
    speed            varchar(32) NULL,                 -- Скорость (может быть числом или текстом типа "Animal's -3")

    occupancy        integer NULL,                     -- "жилая" вместимость (сколько людей может жить внутри)
    upgrade_slots    integer NULL,                     -- слоты улучшений (СУ/Improvement Slots)

    hp               integer NULL,                      -- ПЗ (Hit Points)
    weight           numeric(12,1) NULL,
    price            integer NULL
);

COMMENT ON TABLE wcc_item_vehicles IS
  'Транспорт и скакуны. Источник (DLC) через wcc_dlcs, локализуемые поля через i18n_text UUID (ck_id).';

COMMENT ON COLUMN wcc_item_vehicles.dlc_dlc_id IS
  'FK на wcc_dlcs.dlc_id (источник/пакет: core).';

COMMENT ON COLUMN wcc_item_vehicles.name_id IS
  'i18n UUID для названия транспорта. Генерируется детерминированно: ck_id(''witcher_cc.items.vehicle.name.''||wt_id).';

COMMENT ON COLUMN wcc_item_vehicles.subgroup_id IS
  'i18n UUID для подгруппы транспорта. Использует ключи из словаря: ck_id(''vehicles.subgroup.*'').';

COMMENT ON COLUMN wcc_item_vehicles.base IS
  'Атлетика + ЛВК (DEX+Athletics). NULL для транспортных средств без этого параметра.';

COMMENT ON COLUMN wcc_item_vehicles.speed IS
  'Скорость. Может быть числом или текстовым выражением (например, "Animal''s -3").';

COMMENT ON COLUMN wcc_item_vehicles.occupancy IS
  'Вместимость для проживания (сколько людей может жить внутри транспорта).';

COMMENT ON COLUMN wcc_item_vehicles.upgrade_slots IS
  'Слоты улучшений (СУ / Improvement Slots).';

-- Backward-compatible schema upgrades (if table already existed)
ALTER TABLE wcc_item_vehicles ADD COLUMN IF NOT EXISTS subgroup_id uuid NULL;
ALTER TABLE wcc_item_vehicles ADD COLUMN IF NOT EXISTS occupancy integer NULL;
ALTER TABLE wcc_item_vehicles ADD COLUMN IF NOT EXISTS upgrade_slots integer NULL;
ALTER TABLE wcc_item_vehicles DROP COLUMN IF EXISTS sp;

WITH raw_data (
  wt_id, name_ru, name_en,
  source_id, subgroup_key,
  base, control_modifier, speed,
  occupancy, upgrade_slots,
  hp,
  weight, price
) AS ( VALUES
  ('WT001','Карета','Carriage','core','vehicles.subgroup.attached',NULL,-1,'Animal''s -3',NULL,NULL,60,600,660),
  ('WT002','Повозка','Cart','core','vehicles.subgroup.attached',NULL,0,'Animal''s -1',NULL,NULL,30,300,200),
  ('WT003','Куттер','Cutter','core','vehicles.subgroup.water',NULL,0,'10',NULL,NULL,60,610,1670),
  ('WT004','Лошадь','Horse','core','vehicles.subgroup.animals',11,2,'12',NULL,NULL,40,100,520),
  ('WT005','Мул','Mule','core','vehicles.subgroup.animals',7,0,'9',NULL,NULL,45,150,200),
  ('WT006','Вол','Ox','core','vehicles.subgroup.animals',5,-2,'6',NULL,NULL,50,300,278),
  ('WT007','Парусная лодка','Sailing Boat','core','vehicles.subgroup.water',NULL,-1,'6',NULL,NULL,30,130,230),
  ('WT008','Парусный корабль','Sailing Ship','core','vehicles.subgroup.water',NULL,-2,'8',NULL,NULL,80,2040,2180),
  ('WT009','Боевой конь','War Horse','core','vehicles.subgroup.animals',12,-2,'11',NULL,NULL,50,270,1600),

  -- Wagons (dlc_sh_wat)
  ('WT010','Эльфский Гэдвх','Elven Gedwch','dlc_sh_wat','vehicles.subgroup.attached',NULL,-1,'Animal''s -3',3,5,60,400,700),
  ('WT011','Торговый фургон','Merchant Wagon','dlc_sh_wat','vehicles.subgroup.attached',NULL,-1,'Animal''s -3',1,3,60,400,500),
  ('WT012','Хижина пастуха','Shepherd''s Hut','dlc_sh_wat','vehicles.subgroup.attached',NULL,-2,'Animal''s -5',4,2,80,600,700),
  ('WT013','Боевой фургон','War Wagon','dlc_sh_wat','vehicles.subgroup.attached',NULL,-2,'Animal''s -5',0,4,100,800,700)
),
ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    -- Vehicle names
    SELECT ck_id('witcher_cc.items.vehicle.name.'||rd.wt_id),
           'items',
           'vehicle_names',
           'ru',
           rd.name_ru
      FROM raw_data rd
     WHERE nullif(rd.name_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.items.vehicle.name.'||rd.wt_id),
           'items',
           'vehicle_names',
           'en',
           rd.name_en
      FROM raw_data rd
     WHERE nullif(rd.name_en,'') IS NOT NULL
  ) foo
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO wcc_item_vehicles (
  wt_id, dlc_dlc_id, name_id,
  subgroup_id,
  base, control_modifier, speed,
  occupancy, upgrade_slots,
  hp,
  weight, price
)
SELECT rd.wt_id
     , rd.source_id AS dlc_dlc_id
     , ck_id('witcher_cc.items.vehicle.name.'||rd.wt_id) AS name_id
     , CASE WHEN rd.subgroup_key IS NOT NULL THEN ck_id(rd.subgroup_key) ELSE NULL END AS subgroup_id
     , rd.base
     , rd.control_modifier
     , rd.speed
     , rd.occupancy
     , rd.upgrade_slots
     , rd.hp
     , rd.weight
     , rd.price
  FROM raw_data rd
ON CONFLICT (wt_id) DO UPDATE
SET
  dlc_dlc_id = EXCLUDED.dlc_dlc_id,
  name_id = EXCLUDED.name_id,
  subgroup_id = EXCLUDED.subgroup_id,
  base = EXCLUDED.base,
  control_modifier = EXCLUDED.control_modifier,
  speed = EXCLUDED.speed,
  occupancy = EXCLUDED.occupancy,
  upgrade_slots = EXCLUDED.upgrade_slots,
  hp = EXCLUDED.hp,
  weight = EXCLUDED.weight,
  price = EXCLUDED.price;

