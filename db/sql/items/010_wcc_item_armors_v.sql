\echo '010_wcc_item_armors_v.sql'
-- Materialized view for shop UI (armors catalog)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

DROP MATERIALIZED VIEW IF EXISTS wcc_item_armors_v;

CREATE MATERIALIZED VIEW wcc_item_armors_v AS
SELECT ia.a_id
     , ia.dlc_dlc_id AS dlc_id
     , coalesce(idlcs_lang.text, idlcs_en.text) AS dlc
     , coalesce(iname_lang.text, iname_en.text) AS armor_name
     , coalesce(ibp_lang.text, ibp_en.text) AS body_part
     , coalesce(iac_lang.text, iac_en.text) AS armor_class
     , coalesce(ia.stopping_power, ia.reliability, 0) AS stopping_power
     , coalesce(ia.enhancements, 0) AS enhancements
     , coalesce(ia.encumbrance, 0) AS encumbrance
     , coalesce(ia.weight, 0) AS weight
     , coalesce(ia.price, 0) AS price
     , coalesce(iav_lang.text, iav_en.text) AS availability
     , coalesce(icb_lang.text, icb_en.text) AS crafted_by
     , coalesce(ef_lang.effect_names, ef_en.effect_names) AS effect_names
     , coalesce(ef_lang.effect_descriptions, ef_en.effect_descriptions) AS effect_descriptions
     , coalesce(idesc_lang.text, idesc_en.text) AS armor_description
     , iname_lang.lang
  FROM wcc_item_armors ia
  JOIN i18n_text iname_lang ON iname_lang.id = ia.name_id
  LEFT JOIN i18n_text iname_en ON iname_en.id = ia.name_id AND iname_en.lang = 'en'
  LEFT JOIN i18n_text idesc_lang ON idesc_lang.id = ia.description_id AND idesc_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text idesc_en ON idesc_en.id = ia.description_id AND idesc_en.lang = 'en'
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = ia.dlc_dlc_id
  LEFT JOIN i18n_text idlcs_lang ON idlcs_lang.id = dlcs.name_id AND idlcs_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text idlcs_en ON idlcs_en.id = dlcs.name_id AND idlcs_en.lang = 'en'
  LEFT JOIN i18n_text ibp_lang ON ibp_lang.id = ia.body_part_id AND ibp_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text ibp_en ON ibp_en.id = ia.body_part_id AND ibp_en.lang = 'en'
  LEFT JOIN i18n_text iac_lang ON iac_lang.id = ia.armor_class_id AND iac_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text iac_en ON iac_en.id = ia.armor_class_id AND iac_en.lang = 'en'
  LEFT JOIN i18n_text iav_lang ON iav_lang.id = ia.availability_id AND iav_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text iav_en ON iav_en.id = ia.availability_id AND iav_en.lang = 'en'
  LEFT JOIN i18n_text icb_lang ON icb_lang.id = ia.crafted_by_id AND icb_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text icb_en ON icb_en.id = ia.crafted_by_id AND icb_en.lang = 'en'
  LEFT JOIN (
    SELECT ite.item_id
         , ie.lang
         , string_agg(
             replace(coalesce(ie.text, ''), '<mod>', coalesce(ite.modifier::text, ''))
             || coalesce(nullif('[' || coalesce(iec.text, '') || ']', '[]'), ''),
             E'\n'
             ORDER BY ite.e_e_id
           ) AS effect_names
         , string_agg(CASE WHEN e.description_id is not null then
             replace(coalesce(ie.text, ''), '<mod>', coalesce(ite.modifier::text, ''))
             || ' -' || coalesce(nullif(' [' || coalesce(iec.text, '') || ']', ' []'), '')
             || ' ' || replace(coalesce(ide.text, ''), '<mod>', coalesce(ite.modifier::text, ''))
			 end,
             E'\n'
             ORDER BY ite.e_e_id
           ) AS effect_descriptions
      FROM wcc_item_to_effects ite
      LEFT JOIN wcc_item_effects e ON e.e_id = ite.e_e_id
      LEFT JOIN i18n_text ie ON ie.id = e.name_id
      LEFT JOIN i18n_text ide ON ide.id = e.description_id AND ide.lang = ie.lang
      LEFT JOIN wcc_item_effect_conditions ec ON ec.ec_id = ite.ec_ec_id
      LEFT JOIN i18n_text iec ON iec.id = ec.description_id AND iec.lang = ie.lang
     WHERE ite.item_id LIKE 'A%'
     GROUP BY ite.item_id, ie.lang
  ) ef_lang ON ia.a_id = ef_lang.item_id AND ef_lang.lang = iname_lang.lang
  LEFT JOIN (
    SELECT ite.item_id
         , ie.lang
         , string_agg(
             replace(coalesce(ie.text, ''), '<mod>', coalesce(ite.modifier::text, ''))
             || coalesce(nullif('[' || coalesce(iec.text, '') || ']', '[]'), ''),
             E'\n'
             ORDER BY ite.e_e_id
           ) AS effect_names
         , string_agg(CASE WHEN e.description_id is not null then
             replace(coalesce(ie.text, ''), '<mod>', coalesce(ite.modifier::text, ''))
             || ' -' || coalesce(nullif(' [' || coalesce(iec.text, '') || ']', ' []'), '')
             || ' ' || replace(coalesce(ide.text, ''), '<mod>', coalesce(ite.modifier::text, ''))
             end,
             E'\n'
             ORDER BY ite.e_e_id
           ) AS effect_descriptions
      FROM wcc_item_to_effects ite
      LEFT JOIN wcc_item_effects e ON e.e_id = ite.e_e_id
      LEFT JOIN i18n_text ie ON ie.id = e.name_id
      LEFT JOIN i18n_text ide ON ide.id = e.description_id AND ide.lang = ie.lang
      LEFT JOIN wcc_item_effect_conditions ec ON ec.ec_id = ite.ec_ec_id
      LEFT JOIN i18n_text iec ON iec.id = ec.description_id AND iec.lang = ie.lang
     WHERE ite.item_id LIKE 'A%'
     GROUP BY ite.item_id, ie.lang
  ) ef_en ON ia.a_id = ef_en.item_id AND ef_en.lang = 'en'
 ORDER BY coalesce(iname_lang.text, iname_en.text);

-- Helpful indexes for shop queries
CREATE UNIQUE INDEX IF NOT EXISTS wcc_item_armors_v_aid_lang_uidx ON wcc_item_armors_v (a_id, lang);
CREATE INDEX IF NOT EXISTS wcc_item_armors_v_lang_dlc_idx ON wcc_item_armors_v (lang, dlc_id);


