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

