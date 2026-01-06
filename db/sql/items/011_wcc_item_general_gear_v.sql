-- Materialized view for shop UI (general gear catalog)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

DROP MATERIALIZED VIEW IF EXISTS wcc_item_general_gear_v;

CREATE MATERIALIZED VIEW wcc_item_general_gear_v AS
SELECT ig.t_id
     , ig.dlc_dlc_id AS dlc_id
     , idlcs.text AS dlc
     , iname.text AS gear_name
     , igroup.text AS group_name
     , isubgroup.text AS subgroup_name
     , coalesce(ig.weight, 0) AS weight
     , coalesce(ig.price, 0) AS price
     , iav.text AS availability
     , iconc.text AS concealment
     , idesc.text AS gear_description
     , iname.lang
  FROM wcc_item_general_gear ig
  JOIN i18n_text iname ON iname.id = ig.name_id
  LEFT JOIN i18n_text idesc ON idesc.id = ig.description_id AND idesc.lang = iname.lang
  LEFT JOIN i18n_text isubgroup ON isubgroup.id = ig.subgroup_name_id AND isubgroup.lang = iname.lang
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = ig.dlc_dlc_id
  JOIN i18n_text idlcs ON idlcs.id = dlcs.name_id AND idlcs.lang = iname.lang
  LEFT JOIN i18n_text igroup ON igroup.id = ig.group_key_id AND igroup.lang = iname.lang
  LEFT JOIN i18n_text iav ON iav.id = ig.availability_id AND iav.lang = iname.lang
  LEFT JOIN i18n_text iconc ON iconc.id = ig.concealment_id AND iconc.lang = iname.lang
 ORDER BY isubgroup.text, iname.text;

-- Helpful indexes for shop queries
CREATE UNIQUE INDEX IF NOT EXISTS wcc_item_general_gear_v_tid_lang_uidx ON wcc_item_general_gear_v (t_id, lang);
CREATE INDEX IF NOT EXISTS wcc_item_general_gear_v_lang_dlc_idx ON wcc_item_general_gear_v (lang, dlc_id);

