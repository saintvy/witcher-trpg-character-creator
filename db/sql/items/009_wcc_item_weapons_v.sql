\echo '009_wcc_item_weapons_v.sql'
-- Materialized view for shop UI (weapons catalog)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

DROP MATERIALIZED VIEW IF EXISTS wcc_item_weapons_v;

CREATE MATERIALIZED VIEW wcc_item_weapons_v AS
SELECT wiw.w_id
     , wiw.dlc_dlc_id AS dlc_id
     , coalesce(idlcs_lang.text, idlcs_en.text) AS dlc
     , coalesce(iic_lang.text, iic_en.text) AS weapon_class
     , coalesce(i_lang.text, i_en.text) AS weapon_name
     , wiw.dmg
     , coalesce(wiw.weight, 0) AS weight
     , coalesce(wiw.price, 0) AS price
     , coalesce(wiw.hands, 0) AS hands
     , coalesce(wiw.reliability, 0) AS reliability
     , coalesce(wiw.enhancements, 0) AS enhancements
     , coalesce(iav_lang.text, iav_en.text) AS availability
     , coalesce(icb_lang.text, icb_en.text) AS crafted_by
     , coalesce(icon_lang.text, icon_en.text) AS concealment
     , concat_ws(', ',
         CASE WHEN wiw.is_piercing IS NOT NULL THEN coalesce(idp_lang.text, idp_en.text) ELSE NULL END,
         CASE WHEN wiw.is_slashing IS NOT NULL THEN coalesce(ids_lang.text, ids_en.text) ELSE NULL END,
         CASE WHEN wiw.is_bludgeoning IS NOT NULL THEN coalesce(idb_lang.text, idb_en.text) ELSE NULL END,
         CASE WHEN wiw.is_elemental IS NOT NULL THEN coalesce(ide_lang.text, ide_en.text) ELSE NULL END
       ) AS dmg_types
     , coalesce(ef_lang.effect_names, ef_en.effect_names) AS effect_names
     , coalesce(ef_lang.effect_descriptions, ef_en.effect_descriptions) AS effect_descriptions
     , i_lang.lang
  FROM wcc_item_weapons wiw
  JOIN i18n_text i_lang ON i_lang.id = wiw.name_id
  LEFT JOIN i18n_text i_en ON i_en.id = wiw.name_id AND i_en.lang = 'en'
  LEFT JOIN i18n_text iic_lang ON iic_lang.id = wiw.weapon_class_id AND iic_lang.lang = i_lang.lang
  LEFT JOIN i18n_text iic_en ON iic_en.id = wiw.weapon_class_id AND iic_en.lang = 'en'
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = wiw.dlc_dlc_id
  LEFT JOIN i18n_text idlcs_lang ON idlcs_lang.id = dlcs.name_id AND idlcs_lang.lang = i_lang.lang
  LEFT JOIN i18n_text idlcs_en ON idlcs_en.id = dlcs.name_id AND idlcs_en.lang = 'en'
  LEFT JOIN i18n_text iav_lang ON iav_lang.id = wiw.availability_id AND iav_lang.lang = i_lang.lang
  LEFT JOIN i18n_text iav_en ON iav_en.id = wiw.availability_id AND iav_en.lang = 'en'
  LEFT JOIN i18n_text icb_lang ON icb_lang.id = wiw.crafted_by_id AND icb_lang.lang = i_lang.lang
  LEFT JOIN i18n_text icb_en ON icb_en.id = wiw.crafted_by_id AND icb_en.lang = 'en'
  LEFT JOIN i18n_text icon_lang ON icon_lang.id = wiw.concealment_id AND icon_lang.lang = i_lang.lang
  LEFT JOIN i18n_text icon_en ON icon_en.id = wiw.concealment_id AND icon_en.lang = 'en'
  LEFT JOIN i18n_text idp_lang ON idp_lang.id = wiw.is_piercing AND idp_lang.lang = i_lang.lang
  LEFT JOIN i18n_text idp_en ON idp_en.id = wiw.is_piercing AND idp_en.lang = 'en'
  LEFT JOIN i18n_text ids_lang ON ids_lang.id = wiw.is_slashing AND ids_lang.lang = i_lang.lang
  LEFT JOIN i18n_text ids_en ON ids_en.id = wiw.is_slashing AND ids_en.lang = 'en'
  LEFT JOIN i18n_text idb_lang ON idb_lang.id = wiw.is_bludgeoning AND idb_lang.lang = i_lang.lang
  LEFT JOIN i18n_text idb_en ON idb_en.id = wiw.is_bludgeoning AND idb_en.lang = 'en'
  LEFT JOIN i18n_text ide_lang ON ide_lang.id = wiw.is_elemental AND ide_lang.lang = i_lang.lang
  LEFT JOIN i18n_text ide_en ON ide_en.id = wiw.is_elemental AND ide_en.lang = 'en'
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
     WHERE ite.item_id LIKE 'W%'
     GROUP BY ite.item_id, ie.lang
  ) ef_lang ON wiw.w_id = ef_lang.item_id AND ef_lang.lang = i_lang.lang
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
     WHERE ite.item_id LIKE 'W%'
     GROUP BY ite.item_id, ie.lang
  ) ef_en ON wiw.w_id = ef_en.item_id AND ef_en.lang = 'en'
 ORDER BY coalesce(i_lang.text, i_en.text);

-- Helpful indexes for shop queries
CREATE UNIQUE INDEX IF NOT EXISTS wcc_item_weapons_v_wid_lang_uidx ON wcc_item_weapons_v (w_id, lang);
CREATE INDEX IF NOT EXISTS wcc_item_weapons_v_lang_dlc_idx ON wcc_item_weapons_v (lang, dlc_id);


