\echo '022_wcc_item_vehicles_v.sql'
-- Materialized view for shop UI (vehicles catalog)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

DROP MATERIALIZED VIEW IF EXISTS wcc_item_vehicles_v;

CREATE MATERIALIZED VIEW wcc_item_vehicles_v AS
SELECT iv.wt_id
     , iv.dlc_dlc_id AS dlc_id
     , coalesce(idlcs_lang.text, idlcs_en.text) AS dlc
     , coalesce(iname_lang.text, iname_en.text) AS vehicle_name
     , coalesce(isubgrp_lang.text, isubgrp_en.text) AS subgroup_name
     , iv.base
     , iv.control_modifier
     , iv.speed
     , iv.occupancy
     , iv.upgrade_slots
     , iv.hp
     , coalesce(iv.weight, 0) AS weight
     , coalesce(iv.price, 0) AS price
     , iname_lang.lang
  FROM wcc_item_vehicles iv
  JOIN i18n_text iname_lang ON iname_lang.id = iv.name_id
  LEFT JOIN i18n_text iname_en ON iname_en.id = iv.name_id AND iname_en.lang = 'en'
  LEFT JOIN i18n_text isubgrp_lang
    ON isubgrp_lang.id = iv.subgroup_id
   AND isubgrp_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text isubgrp_en
    ON isubgrp_en.id = iv.subgroup_id
   AND isubgrp_en.lang = 'en'
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = iv.dlc_dlc_id
  LEFT JOIN i18n_text idlcs_lang ON idlcs_lang.id = dlcs.name_id AND idlcs_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text idlcs_en ON idlcs_en.id = dlcs.name_id AND idlcs_en.lang = 'en'
 ORDER BY coalesce(iname_lang.text, iname_en.text);

-- Helpful indexes for shop queries
CREATE UNIQUE INDEX IF NOT EXISTS wcc_item_vehicles_v_wtid_lang_uidx ON wcc_item_vehicles_v (wt_id, lang);
CREATE INDEX IF NOT EXISTS wcc_item_vehicles_v_lang_dlc_idx ON wcc_item_vehicles_v (lang, dlc_id);

