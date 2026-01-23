\echo '012_wcc_item_potions.sql'
CREATE TABLE IF NOT EXISTS wcc_item_potions (
    p_id            varchar(10) PRIMARY KEY,          -- e.g. 'P001'
    dlc_dlc_id      varchar(64) NOT NULL REFERENCES wcc_dlcs(dlc_id), -- source_id (core, hb, dlc_*, exp_*)

    name_id         uuid NOT NULL,                    -- ck_id('witcher_cc.items.potion.name.'||p_id)

    -- Reused dictionary fields (see 001_wcc_items_dict.sql)
    group_id        uuid NULL,                        -- ck_id('reciples.group.*')
    availability_id uuid NULL,                        -- ck_id('availability.*')

    weight          numeric(12,1) NULL,
    price           integer NULL,                     -- price_potion from recipe
    time_effect_val text NULL,
    time_effect_unit_id uuid NULL,                   -- ck_id('time.unit.*')
    toxicity        text NULL,

    effect_id       uuid NOT NULL                     -- ck_id('witcher_cc.items.potion.effect.'||p_id) - same as description_id from recipe
);

COMMENT ON TABLE wcc_item_potions IS
  'Готовые алхимические составы (зелья, масла, отвары и т.д.). Источник (DLC) через wcc_dlcs, локализуемые поля через i18n_text UUID (ck_id). Группа/доступность/единицы времени — из общего словаря (001_wcc_items_dict.sql).';

COMMENT ON COLUMN wcc_item_potions.dlc_dlc_id IS
  'FK на wcc_dlcs.dlc_id (источник/пакет: core/hb/dlc_*/exp_*).';

COMMENT ON COLUMN wcc_item_potions.name_id IS
  'i18n UUID для названия состава. Генерируется детерминированно: ck_id(''witcher_cc.items.potion.name.''||p_id).';

COMMENT ON COLUMN wcc_item_potions.effect_id IS
  'i18n UUID для описания эффекта состава. Генерируется детерминированно: ck_id(''witcher_cc.items.potion.effect.''||p_id).';

-- Generate potions from recipes (excluding medicine group, all with price 0)
WITH ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    -- Potion names (copy from recipe names)
    SELECT ck_id('witcher_cc.items.potion.name.P' || substring(ir.r_id from 2)),
           'items',
           'potion_names',
           iname.lang,
           iname.text
      FROM wcc_item_recipes ir
      JOIN i18n_text iname ON iname.id = ir.name_id
     WHERE (ir.group_id != ck_id('reciples.group.medicine') OR ir.group_id IS NULL)
    UNION ALL
    -- Potion effects (copy from recipe descriptions)
    SELECT ck_id('witcher_cc.items.potion.effect.P' || substring(ir.r_id from 2)),
           'items',
           'potion_effects',
           idesc.lang,
           idesc.text
      FROM wcc_item_recipes ir
      JOIN i18n_text idesc ON idesc.id = ir.description_id
     WHERE (ir.group_id != ck_id('reciples.group.medicine') OR ir.group_id IS NULL)
  ) foo
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO wcc_item_potions (
  p_id, dlc_dlc_id, name_id,
  group_id, availability_id,
  weight, price,
  time_effect_val, time_effect_unit_id,
  toxicity,
  effect_id
)
SELECT 'P' || substring(ir.r_id from 2) AS p_id
     , ir.dlc_dlc_id
     , ck_id('witcher_cc.items.potion.name.P' || substring(ir.r_id from 2)) AS name_id
     , ir.group_id
     , ir.availability_id
     , ir.weight
     , 0 AS price
     , ir.time_effect_val
     , ir.time_effect_unit_id
     , ir.toxicity
     , ck_id('witcher_cc.items.potion.effect.P' || substring(ir.r_id from 2)) AS effect_id
  FROM wcc_item_recipes ir
 WHERE (ir.group_id != ck_id('reciples.group.medicine') OR ir.group_id IS NULL)
ON CONFLICT (p_id) DO UPDATE
SET
  dlc_dlc_id = EXCLUDED.dlc_dlc_id,
  name_id = EXCLUDED.name_id,
  group_id = EXCLUDED.group_id,
  availability_id = EXCLUDED.availability_id,
  weight = EXCLUDED.weight,
  price = EXCLUDED.price,
  time_effect_val = EXCLUDED.time_effect_val,
  time_effect_unit_id = EXCLUDED.time_effect_unit_id,
  toxicity = EXCLUDED.toxicity,
  effect_id = EXCLUDED.effect_id;

