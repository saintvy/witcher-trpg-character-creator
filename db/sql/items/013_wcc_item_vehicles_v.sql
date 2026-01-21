-- Materialized view for shop UI (vehicles catalog)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

DROP MATERIALIZED VIEW IF EXISTS wcc_item_vehicles_v;

CREATE MATERIALIZED VIEW wcc_item_vehicles_v AS
SELECT iv.wt_id
     , iv.dlc_dlc_id AS dlc_id
     , idlcs.text AS dlc
     , iname.text AS vehicle_name
     , isubgrp.text AS subgroup_name
     , iv.base
     , iv.control_modifier
     , iv.speed
     , iv.occupancy
     , iv.upgrade_slots
     , iv.hp
     , coalesce(iv.weight, 0) AS weight
     , coalesce(iv.price, 0) AS price
     , iname.lang
  FROM wcc_item_vehicles iv
  JOIN i18n_text iname ON iname.id = iv.name_id
  LEFT JOIN i18n_text isubgrp
    ON isubgrp.id = iv.subgroup_id
   AND isubgrp.lang = iname.lang
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = iv.dlc_dlc_id
  JOIN i18n_text idlcs ON idlcs.id = dlcs.name_id AND idlcs.lang = iname.lang
 ORDER BY iname.text;

-- Helpful indexes for shop queries
CREATE UNIQUE INDEX IF NOT EXISTS wcc_item_vehicles_v_wtid_lang_uidx ON wcc_item_vehicles_v (wt_id, lang);
CREATE INDEX IF NOT EXISTS wcc_item_vehicles_v_lang_dlc_idx ON wcc_item_vehicles_v (lang, dlc_id);

