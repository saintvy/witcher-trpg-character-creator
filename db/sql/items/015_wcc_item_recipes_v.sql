\echo '015_wcc_item_recipes_v.sql'
-- Materialized view for shop UI (recipes catalog)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.
-- Filters out medicine group (reciples.group.medicine).

DROP MATERIALIZED VIEW IF EXISTS wcc_item_recipes_v;

CREATE MATERIALIZED VIEW wcc_item_recipes_v AS
SELECT ir.r_id
     , ir.dlc_dlc_id AS dlc_id
     , idlcs.text AS dlc
     , iname.text AS recipe_name
     , igroup.text AS recipe_group
     , icl.text AS craft_level
     , coalesce(ir.weight, 0) AS weight_potion
     , coalesce(ir.minimal_ingredients_cost, 0) AS minimal_ingredients_cost
     , coalesce(ir.price_potion, 0) AS price_potion
     , coalesce(ir.price_formula, 0) AS price_formula
     , coalesce(ir.price_formula, 0) AS price
     , coalesce(ir.complexity, 0) AS complexity
     , CASE 
         WHEN ir.time_craft_val IS NOT NULL AND ir.time_craft_unit_id IS NOT NULL THEN
           ir.time_craft_val || ' ' || coalesce(itcu.text, '')
         WHEN ir.time_craft_val IS NOT NULL THEN ir.time_craft_val
         ELSE NULL
       END AS time_craft
     , CASE 
         WHEN ir.time_effect_val IS NOT NULL AND ir.time_effect_unit_id IS NOT NULL THEN
           ir.time_effect_val || ' ' || coalesce(iteu.text, '')
         WHEN ir.time_effect_val IS NOT NULL THEN ir.time_effect_val
         ELSE NULL
       END AS time_effect
     , ir.toxicity
     , formula_ingredients.formula_text AS formula
     , formula_en_ingredients.formula_en_text AS formula_en
     , iav.text AS availability
     , idesc.text AS recipe_description
     , iname.lang
  FROM wcc_item_recipes ir
  JOIN i18n_text iname ON iname.id = ir.name_id
  LEFT JOIN i18n_text idesc ON idesc.id = ir.description_id AND idesc.lang = iname.lang
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = ir.dlc_dlc_id
  JOIN i18n_text idlcs ON idlcs.id = dlcs.name_id AND idlcs.lang = iname.lang
  LEFT JOIN i18n_text igroup ON igroup.id = ir.group_id AND igroup.lang = iname.lang
  LEFT JOIN i18n_text icl ON icl.id = ir.craft_level_id AND icl.lang = iname.lang
  LEFT JOIN i18n_text iav ON iav.id = ir.availability_id AND iav.lang = iname.lang
  LEFT JOIN i18n_text itcu ON itcu.id = ir.time_craft_unit_id AND itcu.lang = iname.lang
  LEFT JOIN i18n_text iteu ON iteu.id = ir.time_effect_unit_id AND iteu.lang = iname.lang
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
  ) formula_ingredients ON ir.r_id = formula_ingredients.r_id AND formula_ingredients.lang = iname.lang
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
 ORDER BY iname.text;

-- Helpful indexes for shop queries
CREATE UNIQUE INDEX IF NOT EXISTS wcc_item_recipes_v_rid_lang_uidx ON wcc_item_recipes_v (r_id, lang);
CREATE INDEX IF NOT EXISTS wcc_item_recipes_v_lang_dlc_idx ON wcc_item_recipes_v (lang, dlc_id);
CREATE INDEX IF NOT EXISTS wcc_item_recipes_v_lang_group_idx ON wcc_item_recipes_v (lang, recipe_group);
