\echo '096_shop_magic.sql'
-- New shop step after 092_shop.sql: magic shop (spells, hexes, rituals, invocations).

-- i18n records for new source titles and new column labels
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_shop.' || v.key) AS id
     , 'questions' AS entity
     , 'metadata' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          -- Source titles
          ('source.magic_spells.title', 'ru', 'Заклинания мага'),
          ('source.magic_spells.title', 'en', 'Mage Spells'),
          ('source.magic_signs.title', 'ru', 'Ведьмачьи знаки'),
          ('source.magic_signs.title', 'en', 'Witcher Signs'),
          ('source.magic_hexes.title', 'ru', 'Порчи'),
          ('source.magic_hexes.title', 'en', 'Hexes'),
          ('source.magic_rituals.title', 'ru', 'Ритуалы'),
          ('source.magic_rituals.title', 'en', 'Rituals'),
          ('source.invocations_druid.title', 'ru', 'Инвокации друида'),
          ('source.invocations_druid.title', 'en', 'Druid Invocations'),
          ('source.invocations_priest.title', 'ru', 'Инвокации жреца'),
          ('source.invocations_priest.title', 'en', 'Priest Invocations'),
          ('source.magic_gifts.title', 'ru', 'Магические дары'),
          ('source.magic_gifts.title', 'en', 'Magical Gifts'),

          -- Column labels
          ('column.level', 'ru', 'Уровень'),
          ('column.level', 'en', 'Level'),
          ('column.element', 'ru', 'Стихия'),
          ('column.element', 'en', 'Element'),
          ('column.stamina_cast', 'ru', 'ВЫН (каст)'),
          ('column.stamina_cast', 'en', 'STA (cast)'),
          ('column.stamina_keeping', 'ru', 'ВЫН (поддерж.)'),
          ('column.stamina_keeping', 'en', 'STA (sustain)'),
          ('column.distance', 'ru', 'Дистанция'),
          ('column.distance', 'en', 'Range'),
          ('column.form', 'ru', 'Форма'),
          ('column.form', 'en', 'Form'),
          ('column.preparing_time', 'ru', 'Подготовка'),
          ('column.preparing_time', 'en', 'Preparation'),
          ('column.zone_size', 'ru', 'Зона'),
          ('column.zone_size', 'en', 'Area'),
          ('column.action_cost', 'ru', 'Затраты'),
          ('column.action_cost', 'en', 'Action cost'),

          -- Budget names
          ('budget.novice_invocation_tokens.name', 'ru', 'Жетоны инвокаций новичка'),
          ('budget.novice_invocation_tokens.name', 'en', 'Novice Invocation Tokens'),
          ('budget.novice_spells_tokens.name', 'ru', 'Жетоны заклинаний новичка'),
          ('budget.novice_spells_tokens.name', 'en', 'Novice Spells Tokens'),
          ('budget.novice_signs_tokens.name', 'ru', 'Жетоны ведьмачьих знаков новичка'),
          ('budget.novice_signs_tokens.name', 'en', 'Novice Witcher Signs Tokens'),
          ('budget.novice_rituals_tokens.name', 'ru', 'Жетоны ритуалов новичка'),
          ('budget.novice_rituals_tokens.name', 'en', 'Novice Rituals Tokens'),
          ('budget.novice_hexes_tokens.name', 'ru', 'Жетоны порч с низкой опасностью'),
          ('budget.novice_hexes_tokens.name', 'en', 'Low Danger Hexes Tokens'),
          ('budget.magic_gifts_tokens.name', 'ru', 'Жетоны магических даров (!! Обязательно получи одобрение ГМа на использование !!)'),
          ('budget.magic_gifts_tokens.name', 'en', 'Magical Gifts Tokens (!! Be sure to get GM approval for use !!)')
       ) AS v(key, lang, text)
ON CONFLICT (id, lang) DO UPDATE
  SET text = EXCLUDED.text;

-- Иерархия путей (если ещё не добавлена)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.hierarchy.' || v.path) AS id
     , 'hierarchy' AS entity
     , 'path' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          ('magicShop', 'ru', 'Выбор магии'),
          ('magicShop', 'en', 'Magic Selection')
       ) AS v(path, lang, text)
ON CONFLICT (id, lang) DO NOTHING;

WITH meta AS (
  SELECT 'witcher_cc' AS su_su_id
       , 'wcc_shop_magic' AS qu_id
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
           ck_id('witcher_cc.hierarchy.magicShop')::text
         ),
         'renderer', 'shop',
         'onlyCoveredByBudget', true,
         'shop', jsonb_build_object(
           'warningPriceZero', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.warning.price_zero')::text),
           'allowedDlcs', jsonb_build_object('jsonlogic_expression', jsonb_build_object('var','dlcs')),
           'budgets', jsonb_build_array(
             jsonb_build_object(
               'id', 'novice_invocation_tokens',
               'type', 'token',
               'source', 'characterRaw.professional_gear_options.novice_invocation_tokens',
               'priority', 1,
               'is_default', false,
               'is_required', true,
               'name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.budget.novice_invocation_tokens.name')::text),
               'coverage', jsonb_build_object('items', jsonb_build_array('MS066', 'MS067', 'MS068', 'MS069', 'MS070', 'MS071', 'MS077', 'MS078', 'MS079', 'MS080', 'MS081', 'MS082', 'MS177', 'MS178', 'MS179', 'MS180', 'MS181', 'MS195', 'MS196', 'MS197', 'MS198', 'MS199'))
             ),
             jsonb_build_object(
               'id', 'novice_spells_tokens',
               'type', 'token',
               'source', 'characterRaw.professional_gear_options.novice_spells_tokens',
               'priority', 1,
               'is_default', false,
               'is_required', true,
               'name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.budget.novice_spells_tokens.name')::text),
               'coverage', jsonb_build_object('items', jsonb_build_array('MS001', 'MS002', 'MS003', 'MS004', 'MS005', 'MS006', 'MS007', 'MS008', 'MS009', 'MS010', 'MS011', 'MS012', 'MS013', 'MS014', 'MS015', 'MS016', 'MS017', 'MS018', 'MS019', 'MS020', 'MS021', 'MS022', 'MS023', 'MS024', 'MS025', 'MS026', 'MS027', 'MS028', 'MS029', 'MS030', 'MS031', 'MS032', 'MS033', 'MS034', 'MS035', 'MS036', 'MS037', 'MS038', 'MS039', 'MS040', 'MS125', 'MS126', 'MS127', 'MS128', 'MS129', 'MS130', 'MS131', 'MS132', 'MS133', 'MS134', 'MS135', 'MS136', 'MS137', 'MS138', 'MS139', 'MS140', 'MS141', 'MS142', 'MS143', 'MS144', 'MS145', 'MS146', 'MS147', 'MS148'))
             ),
             jsonb_build_object(
               'id', 'novice_signs_tokens',
               'type', 'token',
               'source', 'characterRaw.professional_gear_options.novice_signs_tokens',
               'priority', 1,
               'is_default', false,
               'is_required', true,
               'name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.budget.novice_signs_tokens.name')::text),
               'coverage', jsonb_build_object('items', jsonb_build_array('MS094', 'MS095', 'MS096', 'MS097', 'MS098'))
             ),
             jsonb_build_object(
               'id', 'novice_rituals_tokens',
               'type', 'token',
               'source', 'characterRaw.professional_gear_options.novice_rituals_tokens',
               'priority', 1,
               'is_default', false,
               'is_required', true,
               'name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.budget.novice_rituals_tokens.name')::text),
               'coverage', jsonb_build_object('items', jsonb_build_array('MS104', 'MS105', 'MS106', 'MS107', 'MS108', 'MS109', 'MS110', 'MS111', 'MS112', 'MS212', 'MS213', 'MS214', 'MS215', 'MS240', 'MS241', 'MS242'))
             ),
             jsonb_build_object(
               'id', 'novice_hexes_tokens',
               'type', 'token',
               'source', 'characterRaw.professional_gear_options.novice_hexes_tokens',
               'priority', 1,
               'is_default', false,
               'is_required', true,
               'name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.budget.novice_hexes_tokens.name')::text),
               'coverage', jsonb_build_object('items', jsonb_build_array('MS119', 'MS120', 'MS222', 'MS223'))
             ),
             jsonb_build_object(
               'id', 'magic_gifts_tokens',
               'type', 'token',
               'source', 'characterRaw.professional_gear_options.magic_gifts_tokens',
               'priority', 1,
               'is_default', false,
               'is_required', false,
               'name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.budget.magic_gifts_tokens.name')::text),
               'coverage', jsonb_build_object('items', jsonb_build_array('MG001', 'MG002', 'MG003', 'MG004', 'MG005', 'MG006', 'MG007', 'MG008', 'MG009', 'MG010', 'MG011', 'MG012', 'MG013', 'MG014'))
             )
           ),
           'sources', jsonb_build_array(
             -- 1) Mage Spells (group by mastery level; sort by element + name; tooltip = effect)
             jsonb_build_object(
               'id', 'magic_spells',
               'title', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.source.magic_spells.title')::text),
               'table', 'wcc_magic_spells_v',
               'dlcColumn', 'dlc_id',
               'keyColumn', 'ms_id',
               'langColumn', 'lang',
               'langPath', 'characterRaw.lang',
               'groupColumn', 'level',
               'filters', jsonb_build_object('type', 'spell'),
               'tooltipField', 'effect',
               'orderBy', 'sort_key',
               'targetPath', 'characterRaw.gear.magic.spells',
               'columns', jsonb_build_array(
                 jsonb_build_object('field', 'spell_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.name')::text)),
                 jsonb_build_object('field', 'element', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.element')::text)),
                 jsonb_build_object('field', 'stamina_cast', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.stamina_cast')::text)),
                 jsonb_build_object('field', 'stamina_keeping', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.stamina_keeping')::text)),
                 jsonb_build_object('field', 'damage', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.damage')::text)),
                 jsonb_build_object('field', 'distance', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.distance')::text)),
                 jsonb_build_object('field', 'zone_size', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.zone_size')::text)),
                 jsonb_build_object('field', 'form', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.form')::text)),
                 jsonb_build_object('field', 'effect_time', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.time_effect')::text)),
                 jsonb_build_object('field', 'dlc', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.dlc')::text))
               )
             ),
             -- 1b) Witcher Signs (group by mastery level; sort by element + name; tooltip = effect)
             jsonb_build_object(
               'id', 'magic_signs',
               'title', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.source.magic_signs.title')::text),
               'table', 'wcc_magic_spells_v',
               'dlcColumn', 'dlc_id',
               'keyColumn', 'ms_id',
               'langColumn', 'lang',
               'langPath', 'characterRaw.lang',
               'groupColumn', 'level',
               'filters', jsonb_build_object('type', 'sign'),
               'tooltipField', 'effect',
               'orderBy', 'sort_key',
               'targetPath', 'characterRaw.gear.magic.signs',
               'columns', jsonb_build_array(
                 jsonb_build_object('field', 'spell_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.name')::text)),
                 jsonb_build_object('field', 'element', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.element')::text)),
                 jsonb_build_object('field', 'stamina_cast', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.stamina_cast')::text)),
                 jsonb_build_object('field', 'stamina_keeping', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.stamina_keeping')::text)),
                 jsonb_build_object('field', 'damage', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.damage')::text)),
                 jsonb_build_object('field', 'distance', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.distance')::text)),
                 jsonb_build_object('field', 'zone_size', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.zone_size')::text)),
                 jsonb_build_object('field', 'form', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.form')::text)),
                 jsonb_build_object('field', 'effect_time', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.time_effect')::text)),
                 jsonb_build_object('field', 'dlc', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.dlc')::text))
               )
             ),
             -- 2) Hexes (no grouping; sort by level + name; tooltip = effect + remove + components)
             jsonb_build_object(
               'id', 'magic_hexes',
               'title', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.source.magic_hexes.title')::text),
               'table', 'wcc_magic_hexes_v',
               'dlcColumn', 'dlc_id',
               'keyColumn', 'ms_id',
               'langColumn', 'lang',
               'langPath', 'characterRaw.lang',
               'tooltipField', 'tooltip',
               'orderBy', 'sort_key',
               'targetPath', 'characterRaw.gear.magic.hexes',
               'columns', jsonb_build_array(
                 jsonb_build_object('field', 'hex_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.name')::text)),
                 jsonb_build_object('field', 'level', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.level')::text)),
                 jsonb_build_object('field', 'stamina_cast', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.stamina_cast')::text)),
                 jsonb_build_object('field', 'dlc', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.dlc')::text))
               )
             ),
             -- 3) Rituals (no grouping; sort by level + name; tooltip = effect)
             jsonb_build_object(
               'id', 'magic_rituals',
               'title', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.source.magic_rituals.title')::text),
               'table', 'wcc_magic_rituals_v',
               'dlcColumn', 'dlc_id',
               'keyColumn', 'ms_id',
               'langColumn', 'lang',
               'langPath', 'characterRaw.lang',
                 'tooltipField', 'effect_tpl',
                 'orderBy', 'sort_key',
                 'targetPath', 'characterRaw.gear.magic.rituals',
               'columns', jsonb_build_array(
                 jsonb_build_object('field', 'ritual_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.name')::text)),
                 jsonb_build_object('field', 'level', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.level')::text)),
                 jsonb_build_object('field', 'dc', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.difficulty_check')::text)),
                 jsonb_build_object('field', 'preparing_time', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.preparing_time')::text)),
                 jsonb_build_object('field', 'stamina_cast', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.stamina_cast')::text)),
                 jsonb_build_object('field', 'stamina_keeping', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.stamina_keeping')::text)),
                 jsonb_build_object('field', 'zone_size', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.zone_size')::text)),
                 jsonb_build_object('field', 'form', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.form')::text)),
                 jsonb_build_object('field', 'effect_time', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.time_effect')::text)),
                 jsonb_build_object('field', 'dlc', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.dlc')::text))
               )
             ),
             -- 4) Invocations: druids
             jsonb_build_object(
               'id', 'invocations_druid',
               'title', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.source.invocations_druid.title')::text),
               'table', 'wcc_magic_invocations_v',
               'dlcColumn', 'dlc_id',
               'keyColumn', 'ms_id',
               'langColumn', 'lang',
               'langPath', 'characterRaw.lang',
               'groupColumn', 'level',
               'filters', jsonb_build_object('type', 'druid'),
               'tooltipField', 'effect',
               'orderBy', 'invocation_name',
               'targetPath', 'characterRaw.gear.magic.invocations.druid',
               'columns', jsonb_build_array(
                 jsonb_build_object('field', 'invocation_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.name')::text)),
                 jsonb_build_object('field', 'cult_or_circle', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.group')::text)),
                 jsonb_build_object('field', 'stamina_cast', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.stamina_cast')::text)),
                 jsonb_build_object('field', 'stamina_keeping', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.stamina_keeping')::text)),
                 jsonb_build_object('field', 'damage', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.damage')::text)),
                 jsonb_build_object('field', 'distance', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.distance')::text)),
                 jsonb_build_object('field', 'zone_size', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.zone_size')::text)),
                 jsonb_build_object('field', 'form', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.form')::text)),
                 jsonb_build_object('field', 'effect_time', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.time_effect')::text)),
                 jsonb_build_object('field', 'dlc', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.dlc')::text))
               )
             ),
             -- 5) Invocations: priests
             jsonb_build_object(
               'id', 'invocations_priest',
               'title', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.source.invocations_priest.title')::text),
               'table', 'wcc_magic_invocations_v',
               'dlcColumn', 'dlc_id',
               'keyColumn', 'ms_id',
               'langColumn', 'lang',
               'langPath', 'characterRaw.lang',
               'groupColumn', 'level',
               'filters', jsonb_build_object('type', 'priest'),
               'tooltipField', 'effect',
               'orderBy', 'invocation_name',
               'targetPath', 'characterRaw.gear.magic.invocations.priest',
               'columns', jsonb_build_array(
                 jsonb_build_object('field', 'invocation_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.name')::text)),
                 jsonb_build_object('field', 'cult_or_circle', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.group')::text)),
                 jsonb_build_object('field', 'stamina_cast', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.stamina_cast')::text)),
                 jsonb_build_object('field', 'stamina_keeping', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.stamina_keeping')::text)),
                 jsonb_build_object('field', 'damage', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.damage')::text)),
                 jsonb_build_object('field', 'distance', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.distance')::text)),
                 jsonb_build_object('field', 'zone_size', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.zone_size')::text)),
                 jsonb_build_object('field', 'form', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.form')::text)),
                 jsonb_build_object('field', 'effect_time', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.time_effect')::text)),
                 jsonb_build_object('field', 'dlc', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.dlc')::text))
               )
             ),
             -- 6) Magical Gifts (no grouping; tooltip = description = effect + side_effect)
             jsonb_build_object(
               'id', 'magic_gifts',
               'title', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.source.magic_gifts.title')::text),
               'table', 'wcc_magic_gifts_v',
               'dlcColumn', 'dlc_id',
               'keyColumn', 'mg_id',
               'langColumn', 'lang',
               'langPath', 'characterRaw.lang',
               'tooltipField', 'description',
               'orderBy', 'sort_key',
               'targetPath', 'characterRaw.gear.magic.gifts',
               'columns', jsonb_build_array(
                 jsonb_build_object('field', 'gift_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.name')::text)),
                 jsonb_build_object('field', 'group_name', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.group')::text)),
                 jsonb_build_object('field', 'action_cost', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.action_cost')::text)),
                 jsonb_build_object('field', 'dc', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.difficulty_check')::text)),
                 jsonb_build_object('field', 'vigor_cost', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.stamina_cast')::text)),
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

-- Cleanup: ensure magic sources are NOT embedded into base shop (legacy 094 behavior).
-- Keeps shop separation: 092 (wcc_shop) -> 094 (wcc_shop_magic).
WITH q AS (
  SELECT qu_id, su_su_id, metadata
    FROM questions
   WHERE qu_id = 'wcc_shop' AND su_su_id = 'witcher_cc'
),
existing_sources AS (
  SELECT COALESCE(q.metadata->'shop'->'sources', '[]'::jsonb) AS arr
    FROM q
),
existing_filtered AS (
  SELECT elem, ord
    FROM existing_sources
    CROSS JOIN LATERAL jsonb_array_elements(existing_sources.arr) WITH ORDINALITY t(elem, ord)
   WHERE (elem->>'id') NOT IN ('magic_spells', 'magic_signs', 'magic_hexes', 'magic_rituals', 'invocations_druid', 'invocations_priest', 'magic_gifts')
),
merged AS (
  SELECT COALESCE(jsonb_agg(elem ORDER BY ord), '[]'::jsonb) AS arr
    FROM existing_filtered
)
UPDATE questions qq
   SET metadata = jsonb_set(qq.metadata, '{shop,sources}', merged.arr, true)
  FROM merged
 WHERE qq.qu_id = 'wcc_shop' AND qq.su_su_id = 'witcher_cc';

-- Transition: after base shop -> magic shop
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
SELECT 'wcc_shop', 'wcc_shop_magic'
WHERE NOT EXISTS (
  SELECT 1
  FROM transitions t
  WHERE t.from_qu_qu_id = 'wcc_shop'
    AND t.to_qu_qu_id = 'wcc_shop_magic'
);









