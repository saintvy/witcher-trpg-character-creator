\echo '026_wcc_item_blueprints_v.sql'
-- Materialized view for shop UI (blueprints catalog)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

CREATE MATERIALIZED VIEW wcc_item_blueprints_v AS
WITH langs AS (
  SELECT DISTINCT i.lang
    FROM wcc_item_blueprints b
    JOIN i18n_text i ON i.id = b.name_id
),
components_expanded AS (
  SELECT b.b_id
       , l.lang
       , comp_elt.ord AS pos
       , (comp_elt.val->>'id')::uuid AS comp_name_id
       , NULLIF(comp_elt.val->>'qty', '')::int AS qty
    FROM wcc_item_blueprints b
    CROSS JOIN langs l
    CROSS JOIN LATERAL (
      SELECT val, ord
        FROM jsonb_array_elements(COALESCE(b.components, '[]'::jsonb)) WITH ORDINALITY AS t(val, ord)
    ) comp_elt
),
components_pretty AS (
  SELECT ce.b_id
       , ce.lang
       , string_agg(
           CASE
             WHEN ce.qty IS NOT NULL THEN (coalesce(i18n_lang.text, i18n_en.text, '') || ' (' || ce.qty::text || ')')
             ELSE coalesce(i18n_lang.text, i18n_en.text, '')
           END,
           E',\n' ORDER BY ce.pos
         ) AS components
    FROM components_expanded ce
    LEFT JOIN i18n_text i18n_lang
      ON i18n_lang.id = ce.comp_name_id
     AND i18n_lang.lang = ce.lang
    LEFT JOIN i18n_text i18n_en
      ON i18n_en.id = ce.comp_name_id
     AND i18n_en.lang = 'en'
   GROUP BY ce.b_id, ce.lang
)
SELECT b.b_id
     , b.item_id
     , b.dlc_dlc_id AS dlc_id
     , coalesce(idlcs_lang.text, idlcs_en.text) AS dlc
     , coalesce(iname_lang.text, iname_en.text) AS blueprint_name
     , coalesce(iav_lang.text, iav_en.text) AS availability
     , COALESCE(ibg_lang.text, ibg_en.text, igroup_lang.text, igroup_en.text) AS blueprint_group
     , coalesce(icl_lang.text, icl_en.text) AS craft_level
     , b.difficulty_check
     , CASE
         WHEN b.time_value IS NOT NULL AND b.time_unit_id IS NOT NULL THEN
           b.time_value::text || ' ' || COALESCE(itcu_lang.text, itcu_en.text, '')
         WHEN b.time_value IS NOT NULL THEN b.time_value::text
         ELSE NULL
       END AS time_craft
     , cp.components
     , CASE
         WHEN b.item_id LIKE 'W%' AND coalesce(w_lang.w_id, w_en.w_id) IS NOT NULL THEN
           replace(
             replace(
               replace(
                 replace(
                   replace(
                     replace(
                       coalesce(tpl_w_lang.text, tpl_w_en.text, ''),
                       '{dmg}', coalesce(w_lang.dmg::text, w_en.dmg::text, '')
                     ),
                     '{reliability}', coalesce(w_lang.reliability::text, w_en.reliability::text, '')
                   ),
                   '{hands}', coalesce(w_lang.hands::text, w_en.hands::text, '')
                 ),
                 '{concealment}', coalesce(w_lang.concealment::text, w_en.concealment::text, '')
               ),
               '{enhancements}', coalesce(w_lang.enhancements::text, w_en.enhancements::text, '')
             ),
             '{effect_names}', coalesce(w_lang.effect_names::text, w_en.effect_names::text, '')
           )
         WHEN b.item_id LIKE 'A%' AND coalesce(a_lang.a_id, a_en.a_id) IS NOT NULL THEN
           replace(
             replace(
               replace(
                 replace(
                   coalesce(tpl_a_lang.text, tpl_a_en.text, ''),
                   '{stopping_power}', coalesce(a_lang.stopping_power::text, a_en.stopping_power::text, '')
                 ),
                 '{encumbrance}', coalesce(a_lang.encumbrance::text, a_en.encumbrance::text, '')
               ),
               '{enhancements}', coalesce(a_lang.enhancements::text, a_en.enhancements::text, '')
             ),
             '{effect_names}', coalesce(a_lang.effect_names::text, a_en.effect_names::text, '')
           )
         WHEN b.item_id LIKE 'I%' AND coalesce(ing_lang.i_id, ing_en.i_id) IS NOT NULL THEN
           replace(
             coalesce(tpl_i_lang.text, tpl_i_en.text, ''),
             '{weight}', coalesce(ing_lang.weight::text, ing_en.weight::text, '')
           )
         WHEN b.item_id LIKE 'T%' AND coalesce(gg_lang.t_id, gg_en.t_id) IS NOT NULL THEN
           replace(
             replace(
               replace(
                 replace(
                   coalesce(tpl_t_lang.text, tpl_t_en.text, ''),
                   '{group_name}', coalesce(gg_lang.group_name::text, gg_en.group_name::text, '')
                 ),
                 '{gear_description}', coalesce(gg_lang.gear_description::text, gg_en.gear_description::text, '')
               ),
               '{concealment}', coalesce(gg_lang.concealment::text, gg_en.concealment::text, '')
             ),
             '{weight}', coalesce(gg_lang.weight::text, gg_en.weight::text, '')
           )
         WHEN b.item_id LIKE 'U%' AND coalesce(upg_lang.u_id, upg_en.u_id) IS NOT NULL THEN
           replace(
             replace(
               replace(
                 replace(
                   coalesce(tpl_u_lang.text, tpl_u_en.text, ''),
                   '{upgrade_group}', coalesce(upg_lang.upgrade_group::text, upg_en.upgrade_group::text, '')
                 ),
                 '{target}', coalesce(upg_lang.target::text, upg_en.target::text, '')
               ),
               '{effect_names}', coalesce(upg_lang.effect_names::text, upg_en.effect_names::text, '')
             ),
             '{slots}', coalesce(upg_lang.slots::text, upg_en.slots::text, '')
           )
         ELSE NULL
       END AS item_desc
     , COALESCE(b.price_components, 0) AS price_components
     , COALESCE(b.price_blueprint, 0) AS price
     , COALESCE(b.price_item, 0) AS price_item
     , l.lang
  FROM wcc_item_blueprints b
  CROSS JOIN langs l
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = b.dlc_dlc_id
  LEFT JOIN i18n_text idlcs_lang ON idlcs_lang.id = dlcs.name_id AND idlcs_lang.lang = l.lang
  LEFT JOIN i18n_text idlcs_en ON idlcs_en.id = dlcs.name_id AND idlcs_en.lang = 'en'
  LEFT JOIN i18n_text iname_lang ON iname_lang.id = b.name_id AND iname_lang.lang = l.lang
  LEFT JOIN i18n_text iname_en ON iname_en.id = b.name_id AND iname_en.lang = 'en'
  LEFT JOIN i18n_text iav_lang ON iav_lang.id = b.availability_id AND iav_lang.lang = l.lang
  LEFT JOIN i18n_text iav_en ON iav_en.id = b.availability_id AND iav_en.lang = 'en'
  LEFT JOIN i18n_text igroup_lang ON igroup_lang.id = b.group_id AND igroup_lang.lang = l.lang
  LEFT JOIN i18n_text igroup_en ON igroup_en.id = b.group_id AND igroup_en.lang = 'en'
  LEFT JOIN i18n_text ibg_lang ON ibg_lang.id = ck_id('blueprint_groups.' || b.group_id::text) AND ibg_lang.lang = l.lang
  LEFT JOIN i18n_text ibg_en ON ibg_en.id = ck_id('blueprint_groups.' || b.group_id::text) AND ibg_en.lang = 'en'
  LEFT JOIN i18n_text icl_lang ON icl_lang.id = b.craft_level_id AND icl_lang.lang = l.lang
  LEFT JOIN i18n_text icl_en ON icl_en.id = b.craft_level_id AND icl_en.lang = 'en'
  LEFT JOIN i18n_text itcu_lang ON itcu_lang.id = b.time_unit_id AND itcu_lang.lang = l.lang
  LEFT JOIN i18n_text itcu_en ON itcu_en.id = b.time_unit_id AND itcu_en.lang = 'en'
  LEFT JOIN components_pretty cp ON cp.b_id = b.b_id AND cp.lang = l.lang
  LEFT JOIN wcc_item_weapons_v w_lang ON w_lang.w_id = b.item_id AND w_lang.lang = l.lang
  LEFT JOIN wcc_item_weapons_v w_en ON w_en.w_id = b.item_id AND w_en.lang = 'en'
  LEFT JOIN wcc_item_armors ia ON ia.a_id = b.item_id
  LEFT JOIN wcc_item_armors_v a_lang ON a_lang.a_id = b.item_id AND a_lang.lang = l.lang
  LEFT JOIN wcc_item_armors_v a_en ON a_en.a_id = b.item_id AND a_en.lang = 'en'
  LEFT JOIN wcc_item_ingredients_v ing_lang ON ing_lang.i_id = b.item_id AND ing_lang.lang = l.lang
  LEFT JOIN wcc_item_ingredients_v ing_en ON ing_en.i_id = b.item_id AND ing_en.lang = 'en'
  LEFT JOIN wcc_item_general_gear_v gg_lang ON gg_lang.t_id = b.item_id AND gg_lang.lang = l.lang
  LEFT JOIN wcc_item_general_gear_v gg_en ON gg_en.t_id = b.item_id AND gg_en.lang = 'en'
  LEFT JOIN wcc_item_upgrades_v upg_lang ON upg_lang.u_id = b.item_id AND upg_lang.lang = l.lang
  LEFT JOIN wcc_item_upgrades_v upg_en ON upg_en.u_id = b.item_id AND upg_en.lang = 'en'
  LEFT JOIN i18n_text tpl_w_lang ON tpl_w_lang.id = ck_id('witcher_cc.items.blueprint.item_desc_tpl.weapon') AND tpl_w_lang.lang = l.lang
  LEFT JOIN i18n_text tpl_w_en ON tpl_w_en.id = ck_id('witcher_cc.items.blueprint.item_desc_tpl.weapon') AND tpl_w_en.lang = 'en'
  LEFT JOIN i18n_text tpl_a_lang ON tpl_a_lang.id = CASE WHEN ia.body_part_id = ck_id('bodypart.shield') THEN ck_id('witcher_cc.items.blueprint.item_desc_tpl.armor_shield') ELSE ck_id('witcher_cc.items.blueprint.item_desc_tpl.armor') END AND tpl_a_lang.lang = l.lang
  LEFT JOIN i18n_text tpl_a_en ON tpl_a_en.id = CASE WHEN ia.body_part_id = ck_id('bodypart.shield') THEN ck_id('witcher_cc.items.blueprint.item_desc_tpl.armor_shield') ELSE ck_id('witcher_cc.items.blueprint.item_desc_tpl.armor') END AND tpl_a_en.lang = 'en'
  LEFT JOIN i18n_text tpl_i_lang ON tpl_i_lang.id = ck_id('witcher_cc.items.blueprint.item_desc_tpl.ingredient') AND tpl_i_lang.lang = l.lang
  LEFT JOIN i18n_text tpl_i_en ON tpl_i_en.id = ck_id('witcher_cc.items.blueprint.item_desc_tpl.ingredient') AND tpl_i_en.lang = 'en'
  LEFT JOIN i18n_text tpl_t_lang ON tpl_t_lang.id = ck_id('witcher_cc.items.blueprint.item_desc_tpl.general_gear') AND tpl_t_lang.lang = l.lang
  LEFT JOIN i18n_text tpl_t_en ON tpl_t_en.id = ck_id('witcher_cc.items.blueprint.item_desc_tpl.general_gear') AND tpl_t_en.lang = 'en'
  LEFT JOIN i18n_text tpl_u_lang ON tpl_u_lang.id = ck_id('witcher_cc.items.blueprint.item_desc_tpl.upgrade') AND tpl_u_lang.lang = l.lang
  LEFT JOIN i18n_text tpl_u_en ON tpl_u_en.id = ck_id('witcher_cc.items.blueprint.item_desc_tpl.upgrade') AND tpl_u_en.lang = 'en'
 ORDER BY blueprint_name;

-- Helpful indexes for shop queries
CREATE UNIQUE INDEX IF NOT EXISTS wcc_item_blueprints_v_bid_lang_uidx ON wcc_item_blueprints_v (b_id, lang);
CREATE INDEX IF NOT EXISTS wcc_item_blueprints_v_lang_dlc_idx ON wcc_item_blueprints_v (lang, dlc_id);
CREATE INDEX IF NOT EXISTS wcc_item_blueprints_v_lang_group_idx ON wcc_item_blueprints_v (lang, blueprint_group);


