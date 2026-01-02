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
               'title', 'Weapons',
               'table', 'wcc_item_weapons_v',
               'dlcColumn', 'dlc_id',
               'keyColumn', 'w_id',
               'langColumn', 'lang',
               'langPath', 'characterRaw.lang',
               'groupColumn', 'weapon_class',
               'tooltipField', 'effect_descriptions',
               'targetPath', 'characterRaw.gear',
               'columns', jsonb_build_array(
                 jsonb_build_object('field', 'weapon_name', 'label', 'Name'),
                 jsonb_build_object('field', 'weapon_class', 'label', 'Class'),
                 jsonb_build_object('field', 'dmg', 'label', 'Damage'),
                 jsonb_build_object('field', 'weight', 'label', 'Weight'),
                 jsonb_build_object('field', 'price', 'label', 'Price'),
                 jsonb_build_object('field', 'hands', 'label', 'Hands'),
                 jsonb_build_object('field', 'availability', 'label', 'Availability'),
                 jsonb_build_object('field', 'crafted_by', 'label', 'Crafted By'),
                 jsonb_build_object('field', 'concealment', 'label', 'Concealment'),
                 jsonb_build_object('field', 'dmg_types', 'label', 'Damage Types'),
                 jsonb_build_object('field', 'effect_names', 'label', 'Effects'),
                 jsonb_build_object('field', 'dlc', 'label', 'DLC')
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


