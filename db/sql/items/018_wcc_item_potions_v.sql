\echo '018_wcc_item_potions_v.sql'
-- Materialized view for shop UI (potions catalog)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

DROP MATERIALIZED VIEW IF EXISTS wcc_item_potions_v;

CREATE MATERIALIZED VIEW wcc_item_potions_v AS
SELECT ip.p_id
     , ip.dlc_dlc_id AS dlc_id
     , idlcs.text AS dlc
     , iname.text AS potion_name
     , igroup.text AS potion_group
     , coalesce(ip.weight, 0) AS weight
     , coalesce(ip.price, 0) AS price
     , CASE 
         WHEN ip.time_effect_val IS NOT NULL AND ip.time_effect_unit_id IS NOT NULL THEN
           ip.time_effect_val || ' ' || coalesce(iteu.text, '')
         WHEN ip.time_effect_val IS NOT NULL THEN ip.time_effect_val
         ELSE NULL
       END AS time_effect
     , ip.toxicity
     , iav.text AS availability
     , ieffect.text AS effect
     , iname.lang
  FROM wcc_item_potions ip
  JOIN i18n_text iname ON iname.id = ip.name_id
  LEFT JOIN i18n_text ieffect ON ieffect.id = ip.effect_id AND ieffect.lang = iname.lang
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = ip.dlc_dlc_id
  JOIN i18n_text idlcs ON idlcs.id = dlcs.name_id AND idlcs.lang = iname.lang
  LEFT JOIN i18n_text igroup ON igroup.id = ip.group_id AND igroup.lang = iname.lang
  LEFT JOIN i18n_text iav ON iav.id = ip.availability_id AND iav.lang = iname.lang
  LEFT JOIN i18n_text iteu ON iteu.id = ip.time_effect_unit_id AND iteu.lang = iname.lang
ORDER BY iname.text;

-- Helpful indexes for shop queries
CREATE UNIQUE INDEX IF NOT EXISTS wcc_item_potions_v_pid_lang_uidx ON wcc_item_potions_v (p_id, lang);
CREATE INDEX IF NOT EXISTS wcc_item_potions_v_lang_dlc_idx ON wcc_item_potions_v (lang, dlc_id);
CREATE INDEX IF NOT EXISTS wcc_item_potions_v_lang_group_idx ON wcc_item_potions_v (lang, potion_group);

