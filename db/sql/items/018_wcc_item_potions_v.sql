\echo '018_wcc_item_potions_v.sql'
-- Materialized view for shop UI (potions catalog)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

DROP MATERIALIZED VIEW IF EXISTS wcc_item_potions_v;

CREATE MATERIALIZED VIEW wcc_item_potions_v AS
SELECT ip.p_id
     , ip.dlc_dlc_id AS dlc_id
     , coalesce(idlcs_lang.text, idlcs_en.text) AS dlc
     , coalesce(iname_lang.text, iname_en.text) AS potion_name
     , coalesce(igroup_lang.text, igroup_en.text) AS potion_group
     , coalesce(ip.weight, 0) AS weight
     , coalesce(ip.price, 0) AS price
     , CASE 
         WHEN ip.time_effect_val IS NOT NULL AND ip.time_effect_unit_id IS NOT NULL THEN
           ip.time_effect_val || ' ' || coalesce(iteu_lang.text, iteu_en.text, '')
         WHEN ip.time_effect_val IS NOT NULL THEN ip.time_effect_val
         ELSE NULL
       END AS time_effect
     , ip.toxicity
     , coalesce(iav_lang.text, iav_en.text) AS availability
     , coalesce(ieffect_lang.text, ieffect_en.text) AS effect
     , iname_lang.lang
  FROM wcc_item_potions ip
  JOIN i18n_text iname_lang ON iname_lang.id = ip.name_id
  LEFT JOIN i18n_text iname_en ON iname_en.id = ip.name_id AND iname_en.lang = 'en'
  LEFT JOIN i18n_text ieffect_lang ON ieffect_lang.id = ip.effect_id AND ieffect_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text ieffect_en ON ieffect_en.id = ip.effect_id AND ieffect_en.lang = 'en'
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = ip.dlc_dlc_id
  LEFT JOIN i18n_text idlcs_lang ON idlcs_lang.id = dlcs.name_id AND idlcs_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text idlcs_en ON idlcs_en.id = dlcs.name_id AND idlcs_en.lang = 'en'
  LEFT JOIN i18n_text igroup_lang ON igroup_lang.id = ip.group_id AND igroup_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text igroup_en ON igroup_en.id = ip.group_id AND igroup_en.lang = 'en'
  LEFT JOIN i18n_text iav_lang ON iav_lang.id = ip.availability_id AND iav_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text iav_en ON iav_en.id = ip.availability_id AND iav_en.lang = 'en'
  LEFT JOIN i18n_text iteu_lang ON iteu_lang.id = ip.time_effect_unit_id AND iteu_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text iteu_en ON iteu_en.id = ip.time_effect_unit_id AND iteu_en.lang = 'en'
ORDER BY coalesce(iname_lang.text, iname_en.text);

-- Helpful indexes for shop queries
CREATE UNIQUE INDEX IF NOT EXISTS wcc_item_potions_v_pid_lang_uidx ON wcc_item_potions_v (p_id, lang);
CREATE INDEX IF NOT EXISTS wcc_item_potions_v_lang_dlc_idx ON wcc_item_potions_v (lang, dlc_id);
CREATE INDEX IF NOT EXISTS wcc_item_potions_v_lang_group_idx ON wcc_item_potions_v (lang, potion_group);

