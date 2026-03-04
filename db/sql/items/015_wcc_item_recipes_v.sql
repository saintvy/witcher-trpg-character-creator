\echo '015_wcc_item_recipes_v.sql'
-- Materialized view for shop UI (recipes catalog)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.
-- Filters out medicine group (reciples.group.medicine).

DROP MATERIALIZED VIEW IF EXISTS wcc_item_recipes_v;

CREATE MATERIALIZED VIEW wcc_item_recipes_v AS
SELECT ir.r_id
     , ir.dlc_dlc_id AS dlc_id
     , coalesce(idlcs_lang.text, idlcs_en.text) AS dlc
     , coalesce(iname_lang.text, iname_en.text) AS recipe_name
     , coalesce(igroup_lang.text, igroup_en.text) AS recipe_group
     , coalesce(icl_lang.text, icl_en.text) AS craft_level
     , coalesce(ir.weight, 0) AS weight_potion
     , coalesce(ir.minimal_ingredients_cost, 0) AS minimal_ingredients_cost
     , coalesce(ir.price_potion, 0) AS price_potion
     , coalesce(ir.price_formula, 0) AS price_formula
     , coalesce(ir.price_formula, 0) AS price
     , coalesce(ir.complexity, 0) AS complexity
     , CASE 
         WHEN ir.time_craft_val IS NOT NULL AND ir.time_craft_unit_id IS NOT NULL THEN
           ir.time_craft_val || ' ' || coalesce(itcu_lang.text, itcu_en.text, '')
         WHEN ir.time_craft_val IS NOT NULL THEN ir.time_craft_val
         ELSE NULL
       END AS time_craft
     , CASE 
         WHEN ir.time_effect_val IS NOT NULL AND ir.time_effect_unit_id IS NOT NULL THEN
           ir.time_effect_val || ' ' || coalesce(iteu_lang.text, iteu_en.text, '')
         WHEN ir.time_effect_val IS NOT NULL THEN ir.time_effect_val
         ELSE NULL
       END AS time_effect
     , ir.toxicity
     , coalesce(formula_ingredients_lang.formula_text, formula_ingredients_en.formula_text) AS formula
     , formula_en_ingredients.formula_en_text AS formula_en
     , coalesce(iav_lang.text, iav_en.text) AS availability
     , coalesce(idesc_lang.text, idesc_en.text) AS recipe_description
     , iname_lang.lang
  FROM wcc_item_recipes ir
  JOIN i18n_text iname_lang ON iname_lang.id = ir.name_id
  LEFT JOIN i18n_text iname_en ON iname_en.id = ir.name_id AND iname_en.lang = 'en'
  LEFT JOIN i18n_text idesc_lang ON idesc_lang.id = ir.description_id AND idesc_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text idesc_en ON idesc_en.id = ir.description_id AND idesc_en.lang = 'en'
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = ir.dlc_dlc_id
  LEFT JOIN i18n_text idlcs_lang ON idlcs_lang.id = dlcs.name_id AND idlcs_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text idlcs_en ON idlcs_en.id = dlcs.name_id AND idlcs_en.lang = 'en'
  LEFT JOIN i18n_text igroup_lang ON igroup_lang.id = ir.group_id AND igroup_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text igroup_en ON igroup_en.id = ir.group_id AND igroup_en.lang = 'en'
  LEFT JOIN i18n_text icl_lang ON icl_lang.id = ir.craft_level_id AND icl_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text icl_en ON icl_en.id = ir.craft_level_id AND icl_en.lang = 'en'
  LEFT JOIN i18n_text iav_lang ON iav_lang.id = ir.availability_id AND iav_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text iav_en ON iav_en.id = ir.availability_id AND iav_en.lang = 'en'
  LEFT JOIN i18n_text itcu_lang ON itcu_lang.id = ir.time_craft_unit_id AND itcu_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text itcu_en ON itcu_en.id = ir.time_craft_unit_id AND itcu_en.lang = 'en'
  LEFT JOIN i18n_text iteu_lang ON iteu_lang.id = ir.time_effect_unit_id AND iteu_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text iteu_en ON iteu_en.id = ir.time_effect_unit_id AND iteu_en.lang = 'en'
  LEFT JOIN (
    -- Expand formula array, join on i18n, then group back as readable list
    SELECT ir2.r_id
         , i18n.lang
         , string_agg(i18n.text, E',\n' ORDER BY pos) AS formula_text
      FROM wcc_item_recipes ir2
      CROSS JOIN LATERAL unnest(ir2.formula) WITH ORDINALITY AS formula_entry(formula_uuid, pos)
     JOIN i18n_text i18n ON i18n.id = formula_entry.formula_uuid AND i18n.entity = 'items' AND i18n.entity_field = 'dict'
     WHERE ir2.formula IS NOT NULL
     GROUP BY ir2.r_id, i18n.lang
  ) formula_ingredients_lang ON ir.r_id = formula_ingredients_lang.r_id AND formula_ingredients_lang.lang = iname_lang.lang
  LEFT JOIN (
    SELECT ir2.r_id
         , i18n.lang
         , string_agg(i18n.text, E',\n' ORDER BY pos) AS formula_text
      FROM wcc_item_recipes ir2
      CROSS JOIN LATERAL unnest(ir2.formula) WITH ORDINALITY AS formula_entry(formula_uuid, pos)
      JOIN i18n_text i18n ON i18n.id = formula_entry.formula_uuid AND i18n.entity = 'items' AND i18n.entity_field = 'dict'
     WHERE ir2.formula IS NOT NULL
     GROUP BY ir2.r_id, i18n.lang
  ) formula_ingredients_en ON ir.r_id = formula_ingredients_en.r_id AND formula_ingredients_en.lang = 'en'
  LEFT JOIN (
    -- Same as formula_ingredients but always English, space-separated (for PDF formula images)
    SELECT ir2.r_id
         , string_agg(i18n.text, ' ' ORDER BY pos) AS formula_en_text
      FROM wcc_item_recipes ir2
      CROSS JOIN LATERAL unnest(ir2.formula) WITH ORDINALITY AS formula_entry(formula_uuid, pos)
      JOIN i18n_text i18n ON i18n.id = formula_entry.formula_uuid AND i18n.entity = 'items' AND i18n.entity_field = 'dict' AND i18n.lang = 'en'
     WHERE ir2.formula IS NOT NULL
     GROUP BY ir2.r_id
  ) formula_en_ingredients ON ir.r_id = formula_en_ingredients.r_id
 WHERE ir.group_id != ck_id('reciples.group.medicine') OR ir.group_id IS NULL
 ORDER BY coalesce(iname_lang.text, iname_en.text);

-- Helpful indexes for shop queries
CREATE UNIQUE INDEX IF NOT EXISTS wcc_item_recipes_v_rid_lang_uidx ON wcc_item_recipes_v (r_id, lang);
CREATE INDEX IF NOT EXISTS wcc_item_recipes_v_lang_dlc_idx ON wcc_item_recipes_v (lang, dlc_id);
CREATE INDEX IF NOT EXISTS wcc_item_recipes_v_lang_group_idx ON wcc_item_recipes_v (lang, recipe_group);
