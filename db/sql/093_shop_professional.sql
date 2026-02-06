\echo '093_shop_professional.sql'
-- Узел: Профессиональный магазин (специализированный магазин для профессий)

-- i18n записи для бюджета и предупреждений профессионального магазина
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_shop_professional.' || v.key) AS id
     , 'questions' AS entity
     , 'metadata' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          -- Бюджет
          ('budget.tokens.name', 'ru', 'Жетоны'),
          ('budget.tokens.name', 'en', 'Tokens'),
          -- Предупреждения
          ('warning.budget_exceeded', 'ru', 'Один или несколько бюджетов перевыполнены'),
          ('warning.budget_exceeded', 'en', 'One or more budgets are exceeded'),
          ('warning.ignore_warnings', 'ru', 'Игнорировать предупреждения'),
          ('warning.ignore_warnings', 'en', 'Ignore warnings')
       ) AS v(key, lang, text)
ON CONFLICT (id, lang) DO NOTHING;

-- Переиспользуем локализацию источников и столбцов из обычного магазина (091_shop.sql)
-- Используем те же самые i18n ключи, что и в 091_shop.sql

-- Иерархия путей (если ещё не добавлена)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.hierarchy.' || v.path) AS id
     , 'hierarchy' AS entity
     , 'path' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          ('professional_equipment', 'ru', 'Профессиональное снаряжение'),
          ('professional_equipment', 'en', 'Professional Equipment')
       ) AS v(path, lang, text)
ON CONFLICT (id, lang) DO NOTHING;

WITH meta AS (
  SELECT 'witcher_cc' AS su_su_id
       , 'wcc_shop_professional' AS qu_id
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
           ck_id('witcher_cc.hierarchy.professional_equipment')::text
         ),
         'renderer', 'shop',
         'shop', jsonb_build_object(
           -- Флаг: профессиональный магазин (для отдельного рендера на фронте)
           'isProfessional', true,
           -- Allowed DLCs: берём из state.dlcs (core всегда доступен и добавляется на стороне API)
           'allowedDlcs', jsonb_build_object('jsonlogic_expression', jsonb_build_object('var','dlcs')),
           -- Бюджет с жетонами
           'budgets', jsonb_build_array(
             jsonb_build_object(
               'id', 'tokens',
               'type', 'tokens',
               'source', 'characterRaw.professional_gear_options.tokens',
               'priority', 0,
              'is_required', true,
               'is_default', true,
               'name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop_professional.budget.tokens.name')::text)
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
               'filters', jsonb_build_object(
                 'in', jsonb_build_object(
                   'column', 'w_id',
                   'values', jsonb_build_object('jsonlogic_expression', jsonb_build_object('concat_arrays', jsonb_build_array(
                    jsonb_build_object('var', 'characterRaw.professional_gear_options.items'),
                    jsonb_build_object('cat_array', 'characterRaw.professional_gear_options.bundles[].items[].itemId')
                  )))
                 )
               ),
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
              'filters', jsonb_build_object(
                'in', jsonb_build_object(
                  'column', 'a_id',
                  'values', jsonb_build_object('jsonlogic_expression', jsonb_build_object('concat_arrays', jsonb_build_array(
                    jsonb_build_object('var', 'characterRaw.professional_gear_options.items'),
                    jsonb_build_object('cat_array', 'characterRaw.professional_gear_options.bundles[].items[].itemId')
                  )))
                )
              ),
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
              'filters', jsonb_build_object(
                'in', jsonb_build_object(
                  'column', 'u_id',
                  'values', jsonb_build_object('jsonlogic_expression', jsonb_build_object('concat_arrays', jsonb_build_array(
                    jsonb_build_object('var', 'characterRaw.professional_gear_options.items'),
                    jsonb_build_object('cat_array', 'characterRaw.professional_gear_options.bundles[].items[].itemId')
                  )))
                )
              ),
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
              'filters', jsonb_build_object(
                'in', jsonb_build_object(
                  'column', 't_id',
                  'values', jsonb_build_object('jsonlogic_expression', jsonb_build_object('concat_arrays', jsonb_build_array(
                    jsonb_build_object('var', 'characterRaw.professional_gear_options.items'),
                    jsonb_build_object('cat_array', 'characterRaw.professional_gear_options.bundles[].items[].itemId')
                  )))
                )
              ),
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
              'filters', jsonb_build_object(
                'in', jsonb_build_object(
                  'column', 'r_id',
                  'values', jsonb_build_object('jsonlogic_expression', jsonb_build_object('concat_arrays', jsonb_build_array(
                    jsonb_build_object('var', 'characterRaw.professional_gear_options.items'),
                    jsonb_build_object('cat_array', 'characterRaw.professional_gear_options.bundles[].items[].itemId')
                  )))
                )
              ),
              'columns', jsonb_build_array(
                jsonb_build_object('field', 'recipe_group', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.group')::text)),
                jsonb_build_object('field', 'recipe_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.name')::text)),
                jsonb_build_object('field', 'price_formula', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.price_formula')::text)),
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
              'filters', jsonb_build_object(
                'in', jsonb_build_object(
                  'column', 'p_id',
                  'values', jsonb_build_object('jsonlogic_expression', jsonb_build_object('concat_arrays', jsonb_build_array(
                    jsonb_build_object('var', 'characterRaw.professional_gear_options.items'),
                    jsonb_build_object('cat_array', 'characterRaw.professional_gear_options.bundles[].items[].itemId')
                  )))
                )
              ),
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
              'targetPath', 'characterRaw.ingredients',
              'filters', jsonb_build_object(
                'all', jsonb_build_array(
                  jsonb_build_object('isNotNull', 'alchemy_substance'),
                  jsonb_build_object(
                    'in', jsonb_build_object(
                      'column', 'i_id',
                      'values', jsonb_build_object('jsonlogic_expression', jsonb_build_object('concat_arrays', jsonb_build_array(
                    jsonb_build_object('var', 'characterRaw.professional_gear_options.items'),
                    jsonb_build_object('cat_array', 'characterRaw.professional_gear_options.bundles[].items[].itemId')
                  )))
                    )
                  )
                )
              ),
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
              'filters', jsonb_build_object(
                'in', jsonb_build_object(
                  'column', 'b_id',
                  'values', jsonb_build_object('jsonlogic_expression', jsonb_build_object('concat_arrays', jsonb_build_array(
                    jsonb_build_object('var', 'characterRaw.professional_gear_options.items'),
                    jsonb_build_object('cat_array', 'characterRaw.professional_gear_options.bundles[].items[].itemId')
                  )))
                )
              ),
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
              'targetPath', 'characterRaw.ingredients',
              'filters', jsonb_build_object(
                'all', jsonb_build_array(
                  jsonb_build_object('isNull', 'alchemy_substance'),
                  jsonb_build_object(
                    'in', jsonb_build_object(
                      'column', 'i_id',
                      'values', jsonb_build_object('jsonlogic_expression', jsonb_build_object('concat_arrays', jsonb_build_array(
                    jsonb_build_object('var', 'characterRaw.professional_gear_options.items'),
                    jsonb_build_object('cat_array', 'characterRaw.professional_gear_options.bundles[].items[].itemId')
                  )))
                    )
                  )
                )
              ),
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
              'filters', jsonb_build_object(
                'in', jsonb_build_object(
                  'column', 'wt_id',
                  'values', jsonb_build_object('jsonlogic_expression', jsonb_build_object('concat_arrays', jsonb_build_array(
                    jsonb_build_object('var', 'characterRaw.professional_gear_options.items'),
                    jsonb_build_object('cat_array', 'characterRaw.professional_gear_options.bundles[].items[].itemId')
                  )))
                )
              ),
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
              'filters', jsonb_build_object(
                'in', jsonb_build_object(
                  'column', 'm_id',
                  'values', jsonb_build_object('jsonlogic_expression', jsonb_build_object('concat_arrays', jsonb_build_array(
                    jsonb_build_object('var', 'characterRaw.professional_gear_options.items'),
                    jsonb_build_object('cat_array', 'characterRaw.professional_gear_options.bundles[].items[].itemId')
                  )))
                )
              ),
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
              'filters', jsonb_build_object(
                'in', jsonb_build_object(
                  'column', 'tr_id',
                  'values', jsonb_build_object('jsonlogic_expression', jsonb_build_object('concat_arrays', jsonb_build_array(
                    jsonb_build_object('var', 'characterRaw.professional_gear_options.items'),
                    jsonb_build_object('cat_array', 'characterRaw.professional_gear_options.bundles[].items[].itemId')
                  )))
                )
              ),
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

-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
SELECT 'wcc_values_feelings_on_people', 'wcc_shop_professional';








