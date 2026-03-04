\echo '016_wcc_item_ingredients_v.sql'
-- Materialized view for shop UI (ingredients catalog)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.
-- Use filters in shop metadata to split into alchemy (alchemy_substance IS NOT NULL) 
-- and craft (alchemy_substance IS NULL) ingredients.

DROP MATERIALIZED VIEW IF EXISTS wcc_item_ingredients_v;

CREATE MATERIALIZED VIEW wcc_item_ingredients_v AS
SELECT ii.i_id
     , ii.dlc_dlc_id AS dlc_id
     , coalesce(idlcs_lang.text, idlcs_en.text) AS dlc
     , coalesce(iname_lang.text, iname_en.text) AS ingredient_name
     , coalesce(igrp_lang.text, igrp_en.text) AS ingredient_group
     , coalesce(iav_lang.text, iav_en.text) AS availability
     , coalesce(iingr_lang.text, iingr_en.text) AS alchemy_substance
     , coalesce(iingr_en.text, iingr_lang.text) AS alchemy_substance_en
     , coalesce(ii.harvesting_complexity, 0) AS harvesting_complexity
     , coalesce(ii.weight, 0) AS weight
     , coalesce(ii.price, 0) AS price
     , iname_lang.lang
  FROM wcc_item_ingredients ii
  JOIN i18n_text iname_lang ON iname_lang.id = ii.name_id
  LEFT JOIN i18n_text iname_en ON iname_en.id = ii.name_id AND iname_en.lang = 'en'
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = ii.dlc_dlc_id
  LEFT JOIN i18n_text idlcs_lang ON idlcs_lang.id = dlcs.name_id AND idlcs_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text idlcs_en ON idlcs_en.id = dlcs.name_id AND idlcs_en.lang = 'en'
  LEFT JOIN i18n_text igrp_lang ON igrp_lang.id = ii.group_id AND igrp_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text igrp_en ON igrp_en.id = ii.group_id AND igrp_en.lang = 'en'
  LEFT JOIN i18n_text iav_lang ON iav_lang.id = ii.availability_id AND iav_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text iav_en ON iav_en.id = ii.availability_id AND iav_en.lang = 'en'
  LEFT JOIN i18n_text iingr_lang ON iingr_lang.id = ii.ingredient_id AND iingr_lang.lang = iname_lang.lang
  LEFT JOIN i18n_text iingr_en ON iingr_en.id = ii.ingredient_id AND iingr_en.lang = 'en'
 ORDER BY coalesce(iname_lang.text, iname_en.text);

-- Helpful indexes for shop queries
CREATE UNIQUE INDEX IF NOT EXISTS wcc_item_ingredients_v_iid_lang_uidx ON wcc_item_ingredients_v (i_id, lang);
CREATE INDEX IF NOT EXISTS wcc_item_ingredients_v_lang_dlc_idx ON wcc_item_ingredients_v (lang, dlc_id);



