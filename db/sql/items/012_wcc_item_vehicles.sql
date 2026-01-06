CREATE TABLE IF NOT EXISTS wcc_item_vehicles (
    wt_id            varchar(10) PRIMARY KEY,          -- e.g. 'WT001'
    dlc_dlc_id       varchar(64) NOT NULL REFERENCES wcc_dlcs(dlc_id), -- source_id (core)

    name_id          uuid NOT NULL,                    -- ck_id('witcher_cc.items.vehicle.name.'||wt_id)

    base             integer NULL,                     -- Атлетика + ЛВК (NULL для N/A)
    control_modifier integer NULL,                     -- Модификатор управления
    speed            varchar(32) NULL,                 -- Скорость (может быть числом или текстом типа "Animal's -3")
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

COMMENT ON COLUMN wcc_item_vehicles.base IS
  'Атлетика + ЛВК (DEX+Athletics). NULL для транспортных средств без этого параметра.';

COMMENT ON COLUMN wcc_item_vehicles.speed IS
  'Скорость. Может быть числом или текстовым выражением (например, "Animal''s -3").';

WITH raw_data (
  wt_id, name_ru, name_en,
  base, control_modifier, speed, hp, weight, price
) AS ( VALUES
  ('WT001','Карета','Carriage',NULL,-1,'Animal''s -3',60,600,660),
  ('WT002','Повозка','Cart',NULL,0,'Animal''s -1',30,300,200),
  ('WT003','Куттер','Cutter',NULL,0,'10',60,610,1670),
  ('WT004','Лошадь','Horse',11,2,'12',40,100,520),
  ('WT005','Мул','Mule',7,0,'9',45,150,200),
  ('WT006','Вол','Ox',5,-2,'6',50,300,278),
  ('WT007','Парусная лодка','Sailing Boat',NULL,-1,'6',30,130,230),
  ('WT008','Парусный корабль','Sailing Ship',NULL,-2,'8',80,2040,2180),
  ('WT009','Боевой конь','War Horse',12,-2,'11',50,270,1600)
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
  base, control_modifier, speed, hp, weight, price
)
SELECT rd.wt_id
     , 'core' AS dlc_dlc_id
     , ck_id('witcher_cc.items.vehicle.name.'||rd.wt_id) AS name_id
     , rd.base
     , rd.control_modifier
     , rd.speed
     , rd.hp
     , rd.weight
     , rd.price
  FROM raw_data rd
ON CONFLICT (wt_id) DO UPDATE
SET
  dlc_dlc_id = EXCLUDED.dlc_dlc_id,
  name_id = EXCLUDED.name_id,
  base = EXCLUDED.base,
  control_modifier = EXCLUDED.control_modifier,
  speed = EXCLUDED.speed,
  hp = EXCLUDED.hp,
  weight = EXCLUDED.weight,
  price = EXCLUDED.price;

