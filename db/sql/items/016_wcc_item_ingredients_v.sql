\echo '016_wcc_item_ingredients_v.sql'
-- Materialized view for shop UI (ingredients catalog)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.
-- Use filters in shop metadata to split into alchemy (alchemy_substance IS NOT NULL) 
-- and craft (alchemy_substance IS NULL) ingredients.

DROP MATERIALIZED VIEW IF EXISTS wcc_item_ingredients_v;

CREATE MATERIALIZED VIEW wcc_item_ingredients_v AS
SELECT ii.i_id
     , ii.dlc_dlc_id AS dlc_id
     , idlcs.text AS dlc
     , iname.text AS ingredient_name
     , igrp.text AS ingredient_group
     , iav.text AS availability
     , iingr.text AS alchemy_substance
     , coalesce(ii.harvesting_complexity, 0) AS harvesting_complexity
     , coalesce(ii.weight, 0) AS weight
     , coalesce(ii.price, 0) AS price
     , iname.lang
  FROM wcc_item_ingredients ii
  JOIN i18n_text iname ON iname.id = ii.name_id
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = ii.dlc_dlc_id
  JOIN i18n_text idlcs ON idlcs.id = dlcs.name_id AND idlcs.lang = iname.lang
  LEFT JOIN i18n_text igrp ON igrp.id = ii.group_id AND igrp.lang = iname.lang
  LEFT JOIN i18n_text iav ON iav.id = ii.availability_id AND iav.lang = iname.lang
  LEFT JOIN i18n_text iingr ON iingr.id = ii.ingredient_id AND iingr.lang = iname.lang
 ORDER BY iname.text;

-- Helpful indexes for shop queries
CREATE UNIQUE INDEX IF NOT EXISTS wcc_item_ingredients_v_iid_lang_uidx ON wcc_item_ingredients_v (i_id, lang);
CREATE INDEX IF NOT EXISTS wcc_item_ingredients_v_lang_dlc_idx ON wcc_item_ingredients_v (lang, dlc_id);



