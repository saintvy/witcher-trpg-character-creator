\echo '017_wcc_item_mutagens_v.sql'
-- Materialized view for shop UI (mutagens catalog)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

DROP MATERIALIZED VIEW IF EXISTS wcc_item_mutagens_v;

CREATE MATERIALIZED VIEW wcc_item_mutagens_v AS
SELECT im.m_id
     , im.dlc_dlc_id AS dlc_id
     , idlcs.text AS dlc
     , iname.text AS mutagen_name
     , icolor.text AS mutagen_color
     , ieffect.text AS effect
     , im.alchemy_dc
     , iminor.text AS minor_mutation
     , coalesce(im.price, 0) AS price
     , iav.text AS availability
     , iname.lang
  FROM wcc_item_mutagens im
  JOIN i18n_text iname ON iname.id = im.name_id
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = im.dlc_dlc_id
  JOIN i18n_text idlcs ON idlcs.id = dlcs.name_id AND idlcs.lang = iname.lang
  LEFT JOIN i18n_text icolor ON icolor.id = im.color_id AND icolor.lang = iname.lang
  LEFT JOIN i18n_text ieffect ON ieffect.id = im.effect_id AND ieffect.lang = iname.lang
  LEFT JOIN i18n_text iminor ON iminor.id = im.minor_mutation_id AND iminor.lang = iname.lang
  LEFT JOIN i18n_text iav ON iav.id = im.availability_id AND iav.lang = iname.lang
 ORDER BY iname.text;

-- Helpful indexes for shop queries
CREATE UNIQUE INDEX IF NOT EXISTS wcc_item_mutagens_v_mid_lang_uidx ON wcc_item_mutagens_v (m_id, lang);
CREATE INDEX IF NOT EXISTS wcc_item_mutagens_v_lang_dlc_idx ON wcc_item_mutagens_v (lang, dlc_id);
CREATE INDEX IF NOT EXISTS wcc_item_mutagens_v_lang_color_idx ON wcc_item_mutagens_v (lang, mutagen_color);

