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


