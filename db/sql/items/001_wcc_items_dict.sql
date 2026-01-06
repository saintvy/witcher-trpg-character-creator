-- Common dictionary terms for items (shared across multiple item categories)
-- Source: db/sql/items/dict.tsv
--
-- IMPORTANT:
-- - We store dictionary entries in i18n_text with deterministic UUID ids: ck_id(<key>)
-- - Later, item tables can reference these UUIDs directly (e.g. body_part_id = ck_id('bodypart.head'))

WITH raw_data (dict_key, name_ru, name_en) AS ( VALUES
  ('armor_class.light',  'Лёгкая',                           'Light'),
  ('armor_class.medium', 'Средняя',                          'Medium'),
  ('armor_class.heavy',  'Тяжёлая',                          'Heavy'),

  ('bodypart.head',         'Голова',                        'Head Armor'),
  ('bodypart.torso',        'Корпус',                        'Torso Armor'),
  ('bodypart.full',         'Полный сет',                    'Full set of Armor'),
  ('bodypart.full_wo_head', 'Полный сет без головы',         'Torso & Leg Armor'),
  ('bodypart.legs',         'Ноги',                          'Leg Armor'),
  ('bodypart.shield',       'Щит',                           'Shield'),

  -- Availability codes (as in source data)
  ('availability.U', 'Э',                                    'U'),
  ('availability.R', 'У',                                    'R'),
  ('availability.P', 'Р',                                    'P'),
  ('availability.C', 'О',                                    'C'),
  ('availability.E', 'П',                                    'E'),

  -- Ingredients categories
  ('ingredients.craft.crafting_materials',        'Ремесленные материалы',           'Crafting Materials'),
  ('ingredients.craft.hidesand_animal_parts',     'Шкуры и части животных',          'Hides & Animal Parts'),
  ('ingredients.craft.alchemical_treatments',     'Алхимические пропитки и составы', 'Alchemical Treatments'),
  ('ingredients.craft.ingots_and_minerals',       'Слитки и минералы',               'Ingots & Minerals'),
  ('ingredients.alchemy.extracted_alchemical_components', 'Извлеченные алхимические компоненты', 'Extracted alchemical components'),
  ('ingredients.alchemy.from_the_environment',    'Из окружающей среды',             'From the environment'),
  ('ingredients.alchemy.from_monsters',           'Из чудовищ',                      'From monsters'),

  -- Alchemy substances
  ('ingredients.caelum',     'Аер',                           'Caelum'),
  ('ingredients.hydragenum', 'Гидраген',                      'Hydragenum'),
  ('ingredients.quebrith',   'Квебрит',                       'Quebrith'),
  ('ingredients.vermilion',  'Киноварь',                      'Vermilion'),
  ('ingredients.vitriol',    'Купорос',                       'Vitriol'),
  ('ingredients.rebis',      'Ребис',                         'Rebis'),
  ('ingredients.sol',        'Солнце',                        'Sol'),
  ('ingredients.fulgur',     'Фульгор',                       'Fulgur'),
  ('ingredients.aether',     'Эфир',                          'Aether'),

  -- Crafted by
  ('crafted_by.humans',      'Люди',                          'Humans'),
  ('crafted_by.non-humans',  'Нелюди',                        'Non-humans'),
  ('crafted_by.witchers',    'Ведьмаки',                      'Witchers'),

  -- Concealment
  ('concealment.T',          'М',                             'T'),
  ('concealment.S',          'Н',                             'S'),
  ('concealment.L',          'К',                             'L'),
  ('concealment.N/A',        'Н/C',                           'N/A'),

  -- Common damage/protection type labels (reused by armor views)
  ('damage_type.P',          'К',                             'P'),
  ('damage_type.S',          'Р',                             'S'),
  ('damage_type.B',          'Д',                             'B'),
  ('damage_type.E',          'С',                             'E'),
  ('damage_type.Poison',     'Яд',                            'Poison'),
  ('damage_type.Bleeding',   'Кровь',                         'Bleeding'),

  -- Upgrades
  ('upgrades.crossbow',                'Улучшение арбалета', 'Crossbow Upgrades'),
  ('upgrades.rune',                    'Руна',               'Runes'),
  ('upgrades.runeword',                'Рунное слово',       'Runewords'),
  ('upgrades.armor',                   'Усиление брони',     'Armor enhancements'),
  ('upgrades.glyph',                   'Глиф',               'Glyphs'),
  ('upgrades.glyphword',               'Глифное слово',      'Glyphwords'),
  ('upgrades.target.crossbow',         'Арбалеты',           'Crossbows'),
  ('upgrades.target.head',             'Головная броня',     'Head Armor'),
  ('upgrades.target.torso',            'Корпусная броня',    'Torso Armor'),
  ('upgrades.target.legs',             'Ножная броня',       'Leg Armor'),
  ('upgrades.target.weapon',           'Оружие',             'Weapon'),
  ('upgrades.target.weapon_or_shield', 'Оружие, Щит',        'Weapon or Shield'),
  ('upgrades.target.any_armor',        'Любая часть брони',  'Any Armor'),

  -- General gear groups
  ('general_gear.group.clothing',      'Одежда',             'Clothing'),
  ('general_gear.group.containers',   'Контейнеры',          'Containers'),
  ('general_gear.group.food',          'Еда и напитки',       'Food & Drinks'),
  ('general_gear.group.jewerly',       'Украшения',           'Jewelry'),
  ('general_gear.group.other',         'Прочее',             'Other'),
  ('general_gear.group.quest',         'Квестовые предметы',  'Quest Items'),
  ('general_gear.group.standard',      'Стандартное',         'Standard'),
  ('general_gear.group.tools',         'Инструменты',         'Tools'),
  ('general_gear.group.transport',     'Транспорт',           'Transport'),
  ('general_gear.group.harness',       'Упряжь',              'Outfitting for a mount')
),
ins_dict AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    SELECT ck_id(rd.dict_key),
           'items',
           'dict',
           'ru',
           rd.name_ru
      FROM raw_data rd
     WHERE nullif(rd.name_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id(rd.dict_key),
           'items',
           'dict',
           'en',
           rd.name_en
      FROM raw_data rd
     WHERE nullif(rd.name_en,'') IS NOT NULL
  ) foo
  ON CONFLICT (id, lang) DO NOTHING
)
SELECT 1;


