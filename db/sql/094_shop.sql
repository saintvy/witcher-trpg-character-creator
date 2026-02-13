\echo '094_shop.sql'
-- Узел: Магазин (закупка перед стартом)

-- Иерархия путей (если ещё не добавлена)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.hierarchy.' || v.path) AS id
     , 'hierarchy' AS entity
     , 'path' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          ('equipment', 'ru', 'Закупка снаряжения'),
          ('equipment', 'en', 'Equipment Purchase')
       ) AS v(path, lang, text)
ON CONFLICT (id, lang) DO NOTHING;

-- i18n записи для заголовков источников и названий столбцов магазина
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_shop.' || v.key) AS id
     , 'questions' AS entity
     , 'metadata' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          -- Заголовки источников
          ('source.weapons.title', 'ru', 'Оружие'),
          ('source.weapons.title', 'en', 'Weapons'),
          ('source.armors.title', 'ru', 'Броня'),
          ('source.armors.title', 'en', 'Armors'),
          ('source.general_gear.title', 'ru', 'Обычные вещи'),
          ('source.general_gear.title', 'en', 'General Gear'),
          ('source.vehicles.title', 'ru', 'Транспорт и скакуны'),
          ('source.vehicles.title', 'en', 'Vehicles & Mounts'),
          ('source.potions.title', 'ru', 'Алхимические продукты'),
          ('source.potions.title', 'en', 'Alchemical Products'),
          ('source.ingredients_alchemy.title', 'ru', 'Алхимические субстанции'),
          ('source.ingredients_alchemy.title', 'en', 'Alchemical Substances'),
          ('source.ingredients_craft.title', 'ru', 'Ремесленные компоненты'),
          ('source.ingredients_craft.title', 'en', 'Crafting Components'),
          ('source.upgrades.title', 'ru', 'Улучшения оружия и брони'),
          ('source.upgrades.title', 'en', 'Weapon & Armor Upgrades'),
          ('source.recipes.title', 'ru', 'Алхимические рецепты'),
          ('source.recipes.title', 'en', 'Alchemy Recipes'),
          ('source.blueprints.title', 'ru', 'Ремесленные чертежи'),
          ('source.blueprints.title', 'en', 'Crafting Diagrams'),
          ('source.mutagens.title', 'ru', 'Мутагены'),
          ('source.mutagens.title', 'en', 'Mutagens'),
          ('source.trophies.title', 'ru', 'Трофеи'),
          ('source.trophies.title', 'en', 'Trophies'),
          -- Названия столбцов (общие)
          ('column.name', 'ru', 'Название'),
          ('column.name', 'en', 'Name'),
          ('column.class', 'ru', 'Класс'),
          ('column.class', 'en', 'Class'),
          ('column.damage', 'ru', 'Урон'),
          ('column.damage', 'en', 'Damage'),
          ('column.weight', 'ru', 'Вес'),
          ('column.weight', 'en', 'Weight'),
          ('column.price', 'ru', 'Цена'),
          ('column.price', 'en', 'Price'),
          ('column.hands', 'ru', 'Руки'),
          ('column.hands', 'en', 'Hands'),
          ('column.availability', 'ru', 'Доступность'),
          ('column.availability', 'en', 'Availability'),
          ('column.crafted_by', 'ru', 'Изготовлено'),
          ('column.crafted_by', 'en', 'Crafted By'),
          ('column.concealment', 'ru', 'Скрытность'),
          ('column.concealment', 'en', 'Concealment'),
          ('column.damage_types', 'ru', 'Типы урона'),
          ('column.damage_types', 'en', 'Damage Types'),
          ('column.reliability', 'ru', 'Надёжность'),
          ('column.reliability', 'en', 'Reliability'),
          ('column.effects', 'ru', 'Эффекты'),
          ('column.effects', 'en', 'Effects'),
          ('column.enhancements', 'ru', 'Ус'),
          ('column.enhancements', 'en', 'EN'),
          ('column.dlc', 'ru', 'DLC'),
          ('column.dlc', 'en', 'DLC'),
          -- Названия столбцов (специфичные для брони)
          ('column.body_part', 'ru', 'Часть тела'),
          ('column.body_part', 'en', 'Body Part'),
          ('column.stopping_power', 'ru', 'Защита'),
          ('column.stopping_power', 'en', 'SP/Rel'),
          ('column.encumbrance', 'ru', 'Обременение'),
          ('column.encumbrance', 'en', 'Encumbrance'),
          ('column.protections', 'ru', 'Защита'),
          ('column.protections', 'en', 'Protections'),
          ('column.group', 'ru', 'Категория'),
          ('column.group', 'en', 'Category'),
          ('column.harvesting_complexity', 'ru', 'Сложность сбора'),
          ('column.harvesting_complexity', 'en', 'Harvesting Complexity'),
          ('column.alchemy_substance', 'ru', 'Алхимическое вещество'),
          ('column.alchemy_substance', 'en', 'Alchemy Substance'),
          -- Названия столбцов (специфичные для апгрейдов)
          ('column.upgrade_group', 'ru', 'Группа'),
          ('column.upgrade_group', 'en', 'Group'),
          ('column.target', 'ru', 'Цель'),
          ('column.target', 'en', 'Target'),
          ('column.slots', 'ru', 'Слоты'),
          ('column.slots', 'en', 'Slots'),
          -- Названия столбцов (специфичные для транспорта)
          ('column.base', 'ru', 'Атлетика + ЛВК'),
          ('column.base', 'en', 'DEX+Athletics'),
          ('column.control_modifier', 'ru', 'Модификатор управления'),
          ('column.control_modifier', 'en', 'Control Mod'),
          ('column.speed', 'ru', 'Скорость'),
          ('column.speed', 'en', 'Speed'),
          ('column.hp', 'ru', 'ПЗ'),
          ('column.hp', 'en', 'HP'),
          ('column.occupancy', 'ru', 'Вместимость'),
          ('column.occupancy', 'en', 'Occupancy'),
          ('column.upgrade_slots', 'ru', 'СУ'),
          ('column.upgrade_slots', 'en', 'IS'),
          -- Названия столбцов (специфичные для рецептов)
          ('column.formula', 'ru', 'Формула'),
          ('column.formula', 'en', 'Formula'),
          ('column.price_formula', 'ru', 'Цена формулы'),
          ('column.price_formula', 'en', 'Formula Price'),
          -- Названия столбцов (специфичные для чертежей)
          ('column.price_blueprint', 'ru', 'Цена чертежа'),
          ('column.price_blueprint', 'en', 'Blueprint Price'),
          ('column.price_item', 'ru', 'Цена предмета'),
          ('column.price_item', 'en', 'Item Price'),
          ('column.price_components', 'ru', 'Цена компонентов'),
          ('column.price_components', 'en', 'Components Price'),
          ('column.components', 'ru', 'Компоненты'),
          ('column.components', 'en', 'Components'),
          ('column.difficulty_check', 'ru', 'СЛ'),
          ('column.difficulty_check', 'en', 'DC'),
          ('column.time_effect', 'ru', 'Время эффекта'),
          ('column.time_effect', 'en', 'Effect Duration'),
          ('column.toxicity', 'ru', 'Токсичность состава'),
          ('column.toxicity', 'en', 'Composition Toxicity'),
          ('column.craft_level', 'ru', 'Уровень крафта'),
          ('column.craft_level', 'en', 'Craft Level'),
          ('column.complexity', 'ru', 'Сложность крафта'),
          ('column.complexity', 'en', 'Craft Complexity'),
          ('column.time_craft', 'ru', 'Время крафта'),
          ('column.time_craft', 'en', 'Craft Time'),
          ('column.price_potion', 'ru', 'Цена зелья'),
          ('column.price_potion', 'en', 'Potion Price'),
          ('column.weight_potion', 'ru', 'Вес зелья'),
          ('column.weight_potion', 'en', 'Potion Weight'),
          -- Названия столбцов (специфичные для мутагенов)
          ('column.mutagen_color', 'ru', 'Цвет'),
          ('column.mutagen_color', 'en', 'Color'),
          ('column.alchemy_dc', 'ru', 'СЛ Алхимии'),
          ('column.alchemy_dc', 'en', 'Alchemy DC'),
          ('column.minor_mutation', 'ru', 'Малая мутация'),
          ('column.minor_mutation', 'en', 'Minor Mutation'),
          -- Названия столбцов (специфичные для трофеев)
          ('column.monster_type', 'ru', 'Тип монстра'),
          ('column.monster_type', 'en', 'Monster Type'),
          -- Бюджеты
          ('budget.crowns.name', 'ru', 'Кроны'),
          ('budget.crowns.name', 'en', 'Crowns'),
          ('budget.alchemy_ingredients_crowns.name', 'ru', 'Кроны на алхимические ингредиенты'),
          ('budget.alchemy_ingredients_crowns.name', 'en', 'Crowns for Alchemy Ingredients'),
          -- Witcher token budgets
          ('budget.witcher_decoction_formulae_tokens.name', 'ru', 'Жетоны: формулы отваров'),
          ('budget.witcher_decoction_formulae_tokens.name', 'en', 'Tokens: Decoction Formulae'),
          ('budget.witcher_oil_formulae_tokens.name', 'ru', 'Жетоны: формулы масел'),
          ('budget.witcher_oil_formulae_tokens.name', 'en', 'Tokens: Oil Formulae'),
          ('budget.witcher_potion_formulae_tokens.name', 'ru', 'Жетоны: формулы эликсиров'),
          ('budget.witcher_potion_formulae_tokens.name', 'en', 'Tokens: Potion Formulae'),
          ('budget.witcher_steel_sword_tokens.name', 'ru', 'Жетоны: ведьмачий стальной меч'),
          ('budget.witcher_steel_sword_tokens.name', 'en', 'Tokens: Witcher’s Steel Sword'),
          ('budget.witcher_silver_sword_tokens.name', 'ru', 'Жетоны: ведьмачий серебряный меч'),
          ('budget.witcher_silver_sword_tokens.name', 'en', 'Tokens: Witcher''s Silver Sword'),
          ('budget.simple_blueprint_tokens.name', 'ru', 'Жетоны: обычные чертежи/формулы'),
          ('budget.simple_blueprint_tokens.name', 'en', 'Tokens: Common Diagrams/Formulae'),
          ('budget.witcher_silver_sword_tokens.name', 'en', 'Tokens: Witcher''s Silver Sword'),
          ('budget.witcher_blueprint_tokens.name', 'ru', 'Жетоны ведьмачьих чертежей'),
          ('budget.witcher_blueprint_tokens.name', 'en', 'Tokens: Witcher Blueprints'),
          -- Предупреждения
          ('warning.price_zero', 'ru', 'Внимание: товары со стоимостью 0 лучше согласовать с мастером, т.к. это товары, которые не купить в магазине, но которые могут достаться другим способом (наследство, досталось во время обучения и т.д.)'),
          ('warning.price_zero', 'en', 'Warning: items with price 0 should be coordinated with the master, as these are items that cannot be bought in the shop, but may be obtained in other ways (inheritance, received during training, etc.)'),
          ('warning.budget_exceeded', 'ru', 'Один или несколько бюджетов перевыполнены'),
          ('warning.budget_exceeded', 'en', 'One or more budgets are exceeded'),
          ('warning.ignore_warnings', 'ru', 'Игнорировать предупреждения'),
          ('warning.ignore_warnings', 'en', 'Ignore warnings')
       ) AS v(key, lang, text)
ON CONFLICT (id, lang) DO NOTHING;

WITH meta AS (
  SELECT 'witcher_cc' AS su_su_id
       , 'wcc_shop' AS qu_id
       , 'questions' AS entity
)
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
SELECT meta.qu_id
     , meta.su_su_id
     , NULL
     , NULL
     , 'value_textbox'
     , jsonb_build_object(
         'path', jsonb_build_array(
           ck_id('witcher_cc.hierarchy.equipment')::text
         ),
         'renderer', 'shop',
         'shop', jsonb_build_object(
           -- Предупреждение про товары со стоимостью 0
           'warningPriceZero', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.warning.price_zero')::text),
           -- Allowed DLCs: берём из state.dlcs (core всегда доступен и добавляется на стороне API)
           'allowedDlcs', jsonb_build_object('jsonlogic_expression', jsonb_build_object('var','dlcs')),
           -- Бюджеты
           'budgets', jsonb_build_array(
             jsonb_build_object(
               'id', 'crowns',
               'type', 'money',
               'source', 'characterRaw.money.crowns',
               'priority', 0,
               'is_default', true,
               'name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.budget.crowns.name')::text)
             ),
             jsonb_build_object(
               'id', 'alchemy_ingredients_crowns',
               'type', 'money',
               'source', 'characterRaw.money.alchemyIngredientsCrowns',
               'priority', 1,
               'is_default', false,
               -- Покрытие: бюджет тратится только на указанные источники/предметы (OR)
               'coverage', jsonb_build_object(
                 'sources', jsonb_build_array('ingredients_alchemy', 'ingredients_craft')
               ),
               'name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.budget.alchemy_ingredients_crowns.name')::text)
             ),
             -- Witcher: token budgets (choice-limited lists)
             jsonb_build_object(
               'id', 'witcher_decoction_formulae_tokens',
               'type', 'tokens',
               'source', 'characterRaw.professional_gear_options.witcher_decoction_formulae_tokens',
               'priority', 2,
               'is_default', false,
               'coverage', jsonb_build_object(
                 'items', jsonb_build_array('R028','R029','R030','R031','R032','R033','R034','R035','R036','R037')
               ),
               'name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.budget.witcher_decoction_formulae_tokens.name')::text)
             ),
             jsonb_build_object(
               'id', 'witcher_oil_formulae_tokens',
               'type', 'tokens',
               'source', 'characterRaw.professional_gear_options.witcher_oil_formulae_tokens',
               'priority', 2,
               'is_default', false,
               'coverage', jsonb_build_object(
                 'items', jsonb_build_array('R016','R017','R018','R019','R020','R021','R022','R023','R024','R025','R026','R027')
               ),
               'name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.budget.witcher_oil_formulae_tokens.name')::text)
             ),
             jsonb_build_object(
               'id', 'witcher_potion_formulae_tokens',
               'type', 'tokens',
               'source', 'characterRaw.professional_gear_options.witcher_potion_formulae_tokens',
               'priority', 2,
               'is_default', false,
               'coverage', jsonb_build_object(
                 'items', jsonb_build_array('R001','R002','R005','R007','R008','R009','R010','R011','R012','R013','R014','R015')
               ),
               'name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.budget.witcher_potion_formulae_tokens.name')::text)
             ),
             jsonb_build_object(
               'id', 'witcher_steel_sword_tokens',
               'type', 'tokens',
               'source', 'characterRaw.professional_gear_options.witcher_steel_sword_tokens',
               'priority', 2,
               'is_default', false,
               'coverage', jsonb_build_object(
                 'items', jsonb_build_array('W135','W136','W137','W138','W139','W140','W141','W169')
               ),
               'name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.budget.witcher_steel_sword_tokens.name')::text)
             ),
             jsonb_build_object(
               'id', 'witcher_silver_sword_tokens',
               'type', 'tokens',
               'source', 'characterRaw.professional_gear_options.witcher_silver_sword_tokens',
               'priority', 2,
               'is_default', false,
               'coverage', jsonb_build_object(
                 'items', jsonb_build_array('W128','W129','W130','W131','W132','W133','W134','W170')
               ),
               'name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.budget.witcher_silver_sword_tokens.name')::text)
             ),
             jsonb_build_object(
               'id', 'simple_blueprint_tokens',
               'type', 'tokens',
               'source', 'characterRaw.money.simple_blueprint_tokens',
               'priority', 2,
               'is_default', false,
               'coverage', jsonb_build_object(
                 'items', jsonb_build_array('B002','B003','B004','B005','B007','B012','B017','B021','B028','B029','B033','B049','B050','B051','B053','B063','B064','B067','B081','B082','B094','B095','B097','B109','B119','B120','B122','B128','B129','B131','B145','B146','B148','B206','B153','B156','B159','B162','B163','B164','B165','B166','B171','B172','B175','B182','B184','B190','B191','B193','B197','B198','B202','B204','B205','B212','B216','B217','B232','B240','B245','B248','B253','B255','R039','R042','R043','R044','R048','R049','R050','R051','R052','R053','R054','R056','R062','R063','R064','R069','R070','R071','R072','R073','R074','R075','R076','R077','R078')
               ),
               'name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.budget.simple_blueprint_tokens.name')::text)
             ),
             jsonb_build_object(
               'id', 'witcher_blueprint_tokens',
               'type', 'tokens',
               'source', 'characterRaw.professional_gear_options.witcher_blueprint_tokens',
               'priority', 2,
               'is_default', false,
               'coverage', jsonb_build_object(
                 'items', jsonb_build_array('B042','B043','B044','B045','B046','B047','B056','B111','B112','B113','B114','B115','B116','B219','B220','B221','B222','B223','B224','B226','B227','B228','B229','B230','B231','B250','B251','B252')
               ),
               'name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.budget.witcher_blueprint_tokens.name')::text)
             )
           ),
           'sources', jsonb_build_array(
             jsonb_build_object(
               'id', 'weapons',
               'title', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.source.weapons.title')::text),
               'table', 'wcc_item_weapons_v',
               'dlcColumn', 'dlc_id',
               'keyColumn', 'w_id',
               'langColumn', 'lang',
               'langPath', 'characterRaw.lang',
               'groupColumn', 'weapon_class',
               'tooltipField', 'effect_descriptions',
               'targetPath', 'characterRaw.gear.weapons',
               'columns', jsonb_build_array(
                 jsonb_build_object('field', 'weapon_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.name')::text)),
                 jsonb_build_object('field', 'weapon_class', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.class')::text)),
                 jsonb_build_object('field', 'dmg', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.damage')::text)),
                 jsonb_build_object('field', 'weight', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.weight')::text)),
                 jsonb_build_object('field', 'price', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.price')::text)),
                 jsonb_build_object('field', 'hands', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.hands')::text)),
                 jsonb_build_object('field', 'availability', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.availability')::text)),
                 jsonb_build_object('field', 'crafted_by', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.crafted_by')::text)),
                 jsonb_build_object('field', 'concealment', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.concealment')::text)),
                 jsonb_build_object('field', 'dmg_types', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.damage_types')::text)),
                 jsonb_build_object('field', 'reliability', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.reliability')::text)),
                 jsonb_build_object('field', 'enhancements', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.slots')::text)),
                 jsonb_build_object('field', 'effect_names', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.effects')::text)),
                 jsonb_build_object('field', 'dlc', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.dlc')::text))
               )
             ),
            jsonb_build_object(
              'id', 'armors',
              'title', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.source.armors.title')::text),
              'table', 'wcc_item_armors_v',
              'dlcColumn', 'dlc_id',
              'keyColumn', 'a_id',
              'langColumn', 'lang',
              'langPath', 'characterRaw.lang',
              'groupColumn', 'body_part',
              'tooltipField', 'effect_descriptions',
              'targetPath', 'characterRaw.gear.armors',
              'columns', jsonb_build_array(
                jsonb_build_object('field', 'armor_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.name')::text)),
                jsonb_build_object('field', 'body_part', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.body_part')::text)),
                jsonb_build_object('field', 'armor_class', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.class')::text)),
                jsonb_build_object('field', 'stopping_power', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.stopping_power')::text)),
                jsonb_build_object('field', 'encumbrance', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.encumbrance')::text)),
                jsonb_build_object('field', 'weight', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.weight')::text)),
                jsonb_build_object('field', 'price', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.price')::text)),
                jsonb_build_object('field', 'availability', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.availability')::text)),
                jsonb_build_object('field', 'crafted_by', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.crafted_by')::text)),
                jsonb_build_object('field', 'enhancements', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.enhancements')::text)),
                jsonb_build_object('field', 'effect_names', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.effects')::text)),
                jsonb_build_object('field', 'dlc', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.dlc')::text))
              )
            ),
            jsonb_build_object(
              'id', 'upgrades',
              'title', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.source.upgrades.title')::text),
              'table', 'wcc_item_upgrades_v',
              'dlcColumn', 'dlc_id',
              'keyColumn', 'u_id',
              'langColumn', 'lang',
              'langPath', 'characterRaw.lang',
              'groupColumn', 'upgrade_group',
              'tooltipField', 'effect_descriptions',
              'targetPath', 'characterRaw.gear.upgrades',
              'columns', jsonb_build_array(
                jsonb_build_object('field', 'upgrade_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.name')::text)),
                jsonb_build_object('field', 'upgrade_group', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.upgrade_group')::text)),
                jsonb_build_object('field', 'target', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.target')::text)),
                jsonb_build_object('field', 'slots', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.slots')::text)),
                jsonb_build_object('field', 'weight', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.weight')::text)),
                jsonb_build_object('field', 'price', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.price')::text)),
                jsonb_build_object('field', 'availability', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.availability')::text)),
                jsonb_build_object('field', 'effect_names', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.effects')::text)),
                jsonb_build_object('field', 'dlc', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.dlc')::text))
              )
            ),
            jsonb_build_object(
              'id', 'general_gear',
              'title', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.source.general_gear.title')::text),
              'table', 'wcc_item_general_gear_v',
              'dlcColumn', 'dlc_id',
              'keyColumn', 't_id',
              'langColumn', 'lang',
              'langPath', 'characterRaw.lang',
              'groupColumn', 'group_name',
              'tooltipField', 'gear_description',
              'targetPath', 'characterRaw.gear.general_gear',
              'columns', jsonb_build_array(
                jsonb_build_object('field', 'gear_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.name')::text)),
                jsonb_build_object('field', 'group_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.group')::text)),
                jsonb_build_object('field', 'subgroup_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.group')::text)),
                jsonb_build_object('field', 'weight', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.weight')::text)),
                jsonb_build_object('field', 'price', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.price')::text)),
                jsonb_build_object('field', 'availability', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.availability')::text)),
                jsonb_build_object('field', 'concealment', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.concealment')::text)),
                jsonb_build_object('field', 'dlc', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.dlc')::text))
              )
            ),
            jsonb_build_object(
              'id', 'recipes',
              'title', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.source.recipes.title')::text),
              'table', 'wcc_item_recipes_v',
              'dlcColumn', 'dlc_id',
              'keyColumn', 'r_id',
              'langColumn', 'lang',
              'langPath', 'characterRaw.lang',
              'groupColumn', 'recipe_group',
              'tooltipField', 'recipe_description',
              'targetPath', 'characterRaw.gear.recipes',
              'columns', jsonb_build_array(
                jsonb_build_object('field', 'recipe_group', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.group')::text)),
                jsonb_build_object('field', 'recipe_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.name')::text)),
                jsonb_build_object('field', 'price', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.price_formula')::text)),
                jsonb_build_object('field', 'availability', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.availability')::text)),
                jsonb_build_object('field', 'complexity', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.complexity')::text)),
                jsonb_build_object('field', 'craft_level', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.craft_level')::text)),
                jsonb_build_object('field', 'time_craft', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.time_craft')::text)),
                jsonb_build_object('field', 'formula', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.formula')::text)),
                jsonb_build_object('field', 'toxicity', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.toxicity')::text)),
                jsonb_build_object('field', 'time_effect', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.time_effect')::text)),
                jsonb_build_object('field', 'weight_potion', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.weight_potion')::text)),
                jsonb_build_object('field', 'price_potion', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.price_potion')::text)),
                jsonb_build_object('field', 'dlc', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.dlc')::text))
              )
            ),
            jsonb_build_object(
              'id', 'potions',
              'title', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.source.potions.title')::text),
              'table', 'wcc_item_potions_v',
              'dlcColumn', 'dlc_id',
              'keyColumn', 'p_id',
              'langColumn', 'lang',
              'langPath', 'characterRaw.lang',
              'groupColumn', 'potion_group',
              'tooltipField', 'effect',
              'targetPath', 'characterRaw.gear.potions',
              'columns', jsonb_build_array(
                jsonb_build_object('field', 'potion_group', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.group')::text)),
                jsonb_build_object('field', 'potion_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.name')::text)),
                jsonb_build_object('field', 'price', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.price')::text)),
                jsonb_build_object('field', 'availability', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.availability')::text)),
                jsonb_build_object('field', 'time_effect', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.time_effect')::text)),
                jsonb_build_object('field', 'toxicity', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.toxicity')::text)),
                jsonb_build_object('field', 'weight', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.weight')::text)),
                jsonb_build_object('field', 'dlc', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.dlc')::text))
              )
            ),
            jsonb_build_object(
              'id', 'ingredients_alchemy',
              'title', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.source.ingredients_alchemy.title')::text),
              'table', 'wcc_item_ingredients_v',
              'dlcColumn', 'dlc_id',
              'keyColumn', 'i_id',
              'langColumn', 'lang',
              'langPath', 'characterRaw.lang',
              'groupColumn', 'ingredient_group',
              'targetPath', 'characterRaw.gear.ingredients.alchemy',
              'filters', jsonb_build_object('isNotNull', 'alchemy_substance'),
              'columns', jsonb_build_array(
                jsonb_build_object('field', 'ingredient_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.name')::text)),
                jsonb_build_object('field', 'ingredient_group', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.group')::text)),
                jsonb_build_object('field', 'availability', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.availability')::text)),
                jsonb_build_object('field', 'alchemy_substance', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.alchemy_substance')::text)),
                jsonb_build_object('field', 'harvesting_complexity', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.harvesting_complexity')::text)),
                jsonb_build_object('field', 'weight', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.weight')::text)),
                jsonb_build_object('field', 'price', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.price')::text)),
                jsonb_build_object('field', 'dlc', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.dlc')::text))
              )
            ),
            jsonb_build_object(
              'id', 'blueprints',
              'title', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.source.blueprints.title')::text),
              'table', 'wcc_item_blueprints_v',
              'dlcColumn', 'dlc_id',
              'keyColumn', 'b_id',
              'langColumn', 'lang',
              'langPath', 'characterRaw.lang',
              'groupColumn', 'blueprint_group',
              'targetPath', 'characterRaw.gear.blueprints',
              'tooltipField', 'components',
              'columns', jsonb_build_array(
                jsonb_build_object('field', 'blueprint_group', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.group')::text)),
                jsonb_build_object('field', 'blueprint_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.name')::text)),
                jsonb_build_object('field', 'availability', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.availability')::text)),
                jsonb_build_object('field', 'price', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.price_blueprint')::text)),
                jsonb_build_object('field', 'price_components', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.price_components')::text)),
                jsonb_build_object('field', 'price_item', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.price_item')::text)),
                jsonb_build_object('field', 'difficulty_check', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.difficulty_check')::text)),
                jsonb_build_object('field', 'craft_level', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.craft_level')::text)),
                jsonb_build_object('field', 'time_craft', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.time_craft')::text)),
                jsonb_build_object('field', 'dlc', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.dlc')::text))
              )
            ),
            jsonb_build_object(
              'id', 'ingredients_craft',
              'title', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.source.ingredients_craft.title')::text),
              'table', 'wcc_item_ingredients_v',
              'dlcColumn', 'dlc_id',
              'keyColumn', 'i_id',
              'langColumn', 'lang',
              'langPath', 'characterRaw.lang',
              'groupColumn', 'ingredient_group',
              'targetPath', 'characterRaw.gear.ingredients.craft',
              'filters', jsonb_build_object('isNull', 'alchemy_substance'),
              'columns', jsonb_build_array(
                jsonb_build_object('field', 'ingredient_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.name')::text)),
                jsonb_build_object('field', 'ingredient_group', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.group')::text)),
                jsonb_build_object('field', 'availability', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.availability')::text)),
                jsonb_build_object('field', 'harvesting_complexity', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.harvesting_complexity')::text)),
                jsonb_build_object('field', 'weight', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.weight')::text)),
                jsonb_build_object('field', 'price', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.price')::text)),
                jsonb_build_object('field', 'dlc', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.dlc')::text))
              )
            ),
            jsonb_build_object(
              'id', 'vehicles',
              'title', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.source.vehicles.title')::text),
              'table', 'wcc_item_vehicles_v',
              'dlcColumn', 'dlc_id',
              'keyColumn', 'wt_id',
              'langColumn', 'lang',
              'langPath', 'characterRaw.lang',
              'groupColumn', 'subgroup_name',
              'orderBy', jsonb_build_object('column', 'vehicle_name', 'direction', 'asc'),
              'targetPath', 'characterRaw.gear.vehicles',
              'columns', jsonb_build_object(
                'jsonlogic_expression', jsonb_build_object(
                  'if', jsonb_build_array(
                    jsonb_build_object('in', jsonb_build_array('dlc_sh_wat', jsonb_build_object('var', 'dlcs'))),
                    jsonb_build_array(
                      jsonb_build_object('field', 'vehicle_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.name')::text)),
                      jsonb_build_object('field', 'base', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.base')::text)),
                      jsonb_build_object('field', 'control_modifier', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.control_modifier')::text)),
                      jsonb_build_object('field', 'speed', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.speed')::text)),
                      jsonb_build_object('field', 'occupancy', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.occupancy')::text)),
                      jsonb_build_object('field', 'upgrade_slots', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.upgrade_slots')::text)),
                      jsonb_build_object('field', 'hp', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.hp')::text)),
                      jsonb_build_object('field', 'weight', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.weight')::text)),
                      jsonb_build_object('field', 'price', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.price')::text)),
                      jsonb_build_object('field', 'dlc', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.dlc')::text))
                    ),
                    jsonb_build_array(
                      jsonb_build_object('field', 'vehicle_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.name')::text)),
                      jsonb_build_object('field', 'base', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.base')::text)),
                      jsonb_build_object('field', 'control_modifier', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.control_modifier')::text)),
                      jsonb_build_object('field', 'speed', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.speed')::text)),
                      jsonb_build_object('field', 'hp', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.hp')::text)),
                      jsonb_build_object('field', 'weight', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.weight')::text)),
                      jsonb_build_object('field', 'price', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.price')::text)),
                      jsonb_build_object('field', 'dlc', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.dlc')::text))
                    )
                  )
                )
              )
            ),
            jsonb_build_object(
              'id', 'mutagens',
              'title', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.source.mutagens.title')::text),
              'table', 'wcc_item_mutagens_v',
              'dlcColumn', 'dlc_id',
              'keyColumn', 'm_id',
              'langColumn', 'lang',
              'langPath', 'characterRaw.lang',
              'targetPath', 'characterRaw.gear.mutagens',
              'columns', jsonb_build_array(
                jsonb_build_object('field', 'mutagen_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.name')::text)),
                jsonb_build_object('field', 'mutagen_color', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.mutagen_color')::text)),
                jsonb_build_object('field', 'effect', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.effects')::text)),
                jsonb_build_object('field', 'alchemy_dc', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.alchemy_dc')::text)),
                jsonb_build_object('field', 'minor_mutation', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.minor_mutation')::text)),
                jsonb_build_object('field', 'price', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.price')::text)),
                jsonb_build_object('field', 'availability', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.availability')::text)),
                jsonb_build_object('field', 'dlc', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.dlc')::text))
              )
            ),
            jsonb_build_object(
              'id', 'trophies',
              'title', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.source.trophies.title')::text),
              'table', 'wcc_item_trophies_v',
              'dlcColumn', 'dlc_id',
              'keyColumn', 'tr_id',
              'langColumn', 'lang',
              'langPath', 'characterRaw.lang',
              'targetPath', 'characterRaw.gear.trophies',
              'columns', jsonb_build_array(
                jsonb_build_object('field', 'trophy_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.name')::text)),
                jsonb_build_object('field', 'monster_type', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.monster_type')::text)),
                jsonb_build_object('field', 'effect', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.effects')::text)),
                jsonb_build_object('field', 'price', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.price')::text)),
                jsonb_build_object('field', 'availability', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.availability')::text)),
                jsonb_build_object('field', 'dlc', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.dlc')::text))
              )
            )
          )
        )
      )
  FROM meta
ON CONFLICT (qu_id) DO UPDATE
SET
  su_su_id = EXCLUDED.su_su_id,
  title = EXCLUDED.title,
  body = EXCLUDED.body,
  qtype = EXCLUDED.qtype,
  metadata = EXCLUDED.metadata;

-- Связи: после выбора профессии — магазин
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
SELECT 'wcc_shop_professional', 'wcc_shop'
WHERE NOT EXISTS (
  SELECT 1
  FROM transitions t
  WHERE t.from_qu_qu_id = 'wcc_shop_professional'
    AND t.to_qu_qu_id = 'wcc_shop'
);

-- Правило: ведьмак с выбранной школой (logicFields.witcher_school) ИЛИ раса Witcher + DLC dlc_wt
-- используется для перехода из wcc_values_feelings_on_people сразу в wcc_shop (мимо профессионального магазина).
INSERT INTO rules (ru_id, name, body)
VALUES (
  ck_id('witcher_cc.rules.wcc_shop.witcher_skip_professional'),
  'witcher_skip_professional_shop',
  '{"or":[{"var":"characterRaw.logicFields.witcher_school"},{"and":[{"==":[{"var":"characterRaw.logicFields.race"},"Witcher"]},{"in":["dlc_wt",{"var":["dlcs",[]]}]}]}]}'::jsonb
)
ON CONFLICT (ru_id) DO UPDATE SET body = EXCLUDED.body;

-- Связи (приоритетные): из wcc_values_feelings_on_people в магазин — если правило witcher_skip_professional_shop:
-- наличие witcher_school в logicFields либо раса Witcher и dlc_wt в dlcs (пропуск профессионального магазина).
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
SELECT
  'wcc_values_feelings_on_people' AS from_qu_qu_id,
  'wcc_shop' AS to_qu_qu_id,
  r.ru_id AS ru_ru_id,
  1 AS priority
FROM rules r
WHERE r.name = 'witcher_skip_professional_shop'
  AND NOT EXISTS (
    SELECT 1
    FROM transitions t
    WHERE t.from_qu_qu_id = 'wcc_values_feelings_on_people'
      AND t.to_qu_qu_id = 'wcc_shop'
      AND t.ru_ru_id = r.ru_id
  );
