\echo '012_professional_budget_items.sql'
-- Technical "pseudo-items" used as professional shop options.
-- They should NOT be visible in the regular shop lists; therefore they belong to sys_internal DLC and are enabled
-- only when a shop's allowedDlcs explicitly includes sys_internal (professional shop does).
--
-- IMPORTANT: This file is numbered before 013_*_general_gear_v.sql so that the materialized view
-- wcc_item_general_gear_v includes these rows at creation time.

-- Professional option: 100 / 50 crowns of components
WITH meta AS (SELECT 'witcher_cc' AS su_su_id),
ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (VALUES
    -- T900: 100 crowns components budget
    (ck_id('witcher_cc.items.general_gear.name.T900'), 'items', 'general_gear_name', 'ru', 'Ингредиенты на 100 крон'),
    (ck_id('witcher_cc.items.general_gear.name.T900'), 'items', 'general_gear_name', 'en', '100 crowns of components'),
    (ck_id('witcher_cc.items.general_gear.description.T900'), 'items', 'general_gear_description', 'ru', 'Опция профессионального снаряжения: даёт бюджет 100 крон на алхимические субстанции и ремесленные компоненты для следующего узла магазина.'),
    (ck_id('witcher_cc.items.general_gear.description.T900'), 'items', 'general_gear_description', 'en', 'Professional gear option: grants 100 crowns budget for alchemical substances and crafting components for the next shop node.'),
    (ck_id('witcher_cc.items.general_gear.subgroup_name.T900'), 'items', 'general_gear_subgroup', 'ru', 'Бюджеты'),
    (ck_id('witcher_cc.items.general_gear.subgroup_name.T900'), 'items', 'general_gear_subgroup', 'en', 'Budgets'),
    -- T901: 50 crowns components budget
    (ck_id('witcher_cc.items.general_gear.name.T901'), 'items', 'general_gear_name', 'ru', 'Ингредиенты на 50 крон'),
    (ck_id('witcher_cc.items.general_gear.name.T901'), 'items', 'general_gear_name', 'en', '50 crowns of components'),
    (ck_id('witcher_cc.items.general_gear.description.T901'), 'items', 'general_gear_description', 'ru', 'Опция профессионального снаряжения: даёт бюджет 50 крон на алхимические субстанции и ремесленные компоненты для следующего узла магазина.'),
    (ck_id('witcher_cc.items.general_gear.description.T901'), 'items', 'general_gear_description', 'en', 'Professional gear option: grants 50 crowns budget for alchemical substances and crafting components for the next shop node.'),
    (ck_id('witcher_cc.items.general_gear.subgroup_name.T901'), 'items', 'general_gear_subgroup', 'ru', 'Бюджеты'),
    (ck_id('witcher_cc.items.general_gear.subgroup_name.T901'), 'items', 'general_gear_subgroup', 'en', 'Budgets')
  ) AS v(id, entity, entity_field, lang, text)
  ON CONFLICT (id, lang) DO NOTHING
  RETURNING 1
)
INSERT INTO wcc_item_general_gear (
  t_id,
  dlc_dlc_id,
  name_id,
  group_key_id,
  concealment_id,
  availability_id,
  weight,
  price,
  description_id,
  subgroup_name_id
)
SELECT
  v.t_id,
  'sys_internal' AS dlc_dlc_id,
  ck_id('witcher_cc.items.general_gear.name.' || v.t_id) AS name_id,
  ck_id('general_gear.group.other') AS group_key_id,
  NULL::uuid AS concealment_id,
  NULL::uuid AS availability_id,
  0::numeric AS weight,
  0::integer AS price,
  ck_id('witcher_cc.items.general_gear.description.' || v.t_id) AS description_id,
  ck_id('witcher_cc.items.general_gear.subgroup_name.' || v.t_id) AS subgroup_name_id
FROM (VALUES
  ('T900'),
  ('T901')
) AS v(t_id)
ON CONFLICT (t_id) DO NOTHING;

