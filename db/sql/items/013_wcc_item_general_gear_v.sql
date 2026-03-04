\echo '013_wcc_item_general_gear_v.sql'
-- Materialized view for shop UI (general gear catalog)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

DROP MATERIALIZED VIEW IF EXISTS wcc_item_general_gear_v;

CREATE MATERIALIZED VIEW wcc_item_general_gear_v AS
SELECT ig.t_id
     , ig.dlc_dlc_id AS dlc_id
     , coalesce(idlcs_lang.text, idlcs_en.text) AS dlc
     , coalesce(iname_lang.text, iname_en.text) AS gear_name
     , coalesce(igroup_lang.text, igroup_en.text) AS group_name
     , coalesce(isubgroup_lang.text, isubgroup_en.text) AS subgroup_name
     , coalesce(ig.weight, 0) AS weight
     , coalesce(ig.price, 0) AS price
     , coalesce(iav_lang.text, iav_en.text) AS availability
     , coalesce(iconc_lang.text, iconc_en.text) AS concealment
     , coalesce(idesc_lang.text, idesc_en.text) AS gear_description
     , iname_lang.lang
  FROM wcc_item_general_gear ig
  JOIN i18n_text iname_lang ON iname_lang.id = ig.name_id
  LEFT JOIN i18n_text iname_en ON iname_en.id = ig.name_id AND iname_en.lang = 'en'
  LEFT JOIN i18n_text idesc_lang ON idesc_lang.id = ig.description_id AND idesc_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text idesc_en ON idesc_en.id = ig.description_id AND idesc_en.lang = 'en'
  LEFT JOIN i18n_text isubgroup_lang ON isubgroup_lang.id = ig.subgroup_name_id AND isubgroup_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text isubgroup_en ON isubgroup_en.id = ig.subgroup_name_id AND isubgroup_en.lang = 'en'
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = ig.dlc_dlc_id
  LEFT JOIN i18n_text idlcs_lang ON idlcs_lang.id = dlcs.name_id AND idlcs_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text idlcs_en ON idlcs_en.id = dlcs.name_id AND idlcs_en.lang = 'en'
  LEFT JOIN i18n_text igroup_lang ON igroup_lang.id = ig.group_key_id AND igroup_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text igroup_en ON igroup_en.id = ig.group_key_id AND igroup_en.lang = 'en'
  LEFT JOIN i18n_text iav_lang ON iav_lang.id = ig.availability_id AND iav_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text iav_en ON iav_en.id = ig.availability_id AND iav_en.lang = 'en'
  LEFT JOIN i18n_text iconc_lang ON iconc_lang.id = ig.concealment_id AND iconc_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text iconc_en ON iconc_en.id = ig.concealment_id AND iconc_en.lang = 'en'
 ORDER BY coalesce(isubgroup_lang.text, isubgroup_en.text), coalesce(iname_lang.text, iname_en.text);

-- Helpful indexes for shop queries
CREATE UNIQUE INDEX IF NOT EXISTS wcc_item_general_gear_v_tid_lang_uidx ON wcc_item_general_gear_v (t_id, lang);
CREATE INDEX IF NOT EXISTS wcc_item_general_gear_v_lang_dlc_idx ON wcc_item_general_gear_v (lang, dlc_id);

