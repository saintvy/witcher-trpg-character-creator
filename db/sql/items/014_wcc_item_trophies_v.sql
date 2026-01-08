-- Materialized view for shop UI (trophies catalog)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

DROP MATERIALIZED VIEW IF EXISTS wcc_item_trophies_v;

CREATE MATERIALIZED VIEW wcc_item_trophies_v AS
SELECT it.tr_id
     , it.dlc_dlc_id AS dlc_id
     , idlcs.text AS dlc
     , iname.text AS trophy_name
     , imtype.text AS monster_type
     , ieffect.text AS effect
     , coalesce(it.price, 0) AS price
     , iav.text AS availability
     , iname.lang
  FROM wcc_item_trophies it
  JOIN i18n_text iname ON iname.id = it.name_id
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = it.dlc_dlc_id
  JOIN i18n_text idlcs ON idlcs.id = dlcs.name_id AND idlcs.lang = iname.lang
  LEFT JOIN i18n_text imtype ON imtype.id = it.monster_type_id AND imtype.lang = iname.lang
  LEFT JOIN i18n_text ieffect ON ieffect.id = it.effect_id AND ieffect.lang = iname.lang
  LEFT JOIN i18n_text iav ON iav.id = it.availability_id AND iav.lang = iname.lang
 ORDER BY iname.text;

-- Helpful indexes for shop queries
CREATE UNIQUE INDEX IF NOT EXISTS wcc_item_trophies_v_trid_lang_uidx ON wcc_item_trophies_v (tr_id, lang);
CREATE INDEX IF NOT EXISTS wcc_item_trophies_v_lang_dlc_idx ON wcc_item_trophies_v (lang, dlc_id);
CREATE INDEX IF NOT EXISTS wcc_item_trophies_v_lang_type_idx ON wcc_item_trophies_v (lang, monster_type);

