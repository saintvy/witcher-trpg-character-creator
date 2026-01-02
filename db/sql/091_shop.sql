\echo '091_shop.sql'
-- Узел: Магазин (закупка перед стартом)

-- Иерархия путей (если ещё не добавлена)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.hierarchy.' || v.path) AS id
     , 'hierarchy' AS entity
     , 'path' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          ('equipment', 'ru', 'Снаряжение'),
          ('equipment', 'en', 'Equipment')
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
          ('column.effects', 'ru', 'Эффекты'),
          ('column.effects', 'en', 'Effects'),
          ('column.dlc', 'ru', 'DLC'),
          ('column.dlc', 'en', 'DLC'),
          -- Названия столбцов (специфичные для брони)
          ('column.body_part', 'ru', 'Часть тела'),
          ('column.body_part', 'en', 'Body Part'),
          ('column.stopping_power', 'ru', 'Защита'),
          ('column.stopping_power', 'en', 'Stopping Power'),
          ('column.encumbrance', 'ru', 'Обременение'),
          ('column.encumbrance', 'en', 'Encumbrance'),
          ('column.protections', 'ru', 'Защита'),
          ('column.protections', 'en', 'Protections')
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
           -- Ограничитель: только money.crowns
           'budget', jsonb_build_object(
             'currency', 'crowns',
             'path', 'characterRaw.money.crowns'
           ),
           -- Разрешенные DLC (можно расширить список)
           'allowedDlcs', jsonb_build_array('core', 'hb', 'dlc_wt', 'exp_bot', 'exp_lal', 'exp_toc', 'exp_wj', 'dlc_prof_peasant', 'dlc_rw1', 'dlc_rw2', 'dlc_rw3', 'dlc_rw4', 'dlc_rw5', 'dlc_sch_manticore', 'dlc_sch_snail', 'dlc_sh_mothr', 'dlc_sh_tai', 'dlc_sh_tothr', 'dlc_sh_wat', 'dlc_wpaw', 'dlc_rw_rudolf'),
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
               'targetPath', 'characterRaw.gear',
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
               'targetPath', 'characterRaw.gear',
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
                 jsonb_build_object('field', 'dmg_types', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.protections')::text)),
                 jsonb_build_object('field', 'effect_names', 'label', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_shop.column.effects')::text)),
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
SELECT 'wcc_profession', 'wcc_shop'
WHERE NOT EXISTS (
  SELECT 1
  FROM transitions t
  WHERE t.from_qu_qu_id = 'wcc_profession'
    AND t.to_qu_qu_id = 'wcc_shop'
);


