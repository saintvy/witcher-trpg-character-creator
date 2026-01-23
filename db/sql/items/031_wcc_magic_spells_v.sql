\echo '031_wcc_magic_spells_v.sql'
-- Materialized view for shop UI (magic spells & signs)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

CREATE MATERIALIZED VIEW wcc_magic_spells_v AS
WITH langs AS (
  SELECT 'ru'::text AS lang
  UNION ALL
  SELECT 'en'::text AS lang
)
SELECT s.ms_id
     , s.dlc_dlc_id AS dlc_id
     , idlcs.text AS dlc
     , iname.text AS spell_name
     , ilevel.text AS level
     , ielement.text AS element
     , s.stamina_cast
     , s.stamina_keeping
     , s.damage
     , s.distance
     , s.zone_size
     , iform.text AS form
     , CASE
         WHEN s.effect_time_value IS NOT NULL AND s.effect_time_unit_id IS NOT NULL THEN
           s.effect_time_value || ' ' || COALESCE(itcu.text, '')
         WHEN s.effect_time_value IS NOT NULL THEN s.effect_time_value
         ELSE NULL
       END AS effect_time
     , ieffect.text AS effect
     , (COALESCE(ielement.text,'') || '|' || COALESCE(iname.text,'')) AS sort_key
     , s.type
     , l.lang
  FROM wcc_magic_spells s
  CROSS JOIN langs l
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = s.dlc_dlc_id
  JOIN i18n_text idlcs ON idlcs.id = dlcs.name_id AND idlcs.lang = l.lang
  JOIN i18n_text iname ON iname.id = s.name_id AND iname.lang = l.lang
  LEFT JOIN i18n_text ilevel ON ilevel.id = s.level_id AND ilevel.lang = l.lang
  LEFT JOIN i18n_text ielement ON ielement.id = s.element_id AND ielement.lang = l.lang
  LEFT JOIN i18n_text iform ON iform.id = s.form_id AND iform.lang = l.lang
  LEFT JOIN i18n_text itcu ON itcu.id = s.effect_time_unit_id AND itcu.lang = l.lang
  LEFT JOIN i18n_text ieffect ON ieffect.id = s.effect_id AND ieffect.lang = l.lang
 ORDER BY spell_name;

CREATE UNIQUE INDEX IF NOT EXISTS wcc_magic_spells_v_ms_lang_uidx ON wcc_magic_spells_v (ms_id, lang);
CREATE INDEX IF NOT EXISTS wcc_magic_spells_v_lang_dlc_idx ON wcc_magic_spells_v (lang, dlc_id);
CREATE INDEX IF NOT EXISTS wcc_magic_spells_v_lang_level_idx ON wcc_magic_spells_v (lang, level);
CREATE INDEX IF NOT EXISTS wcc_magic_spells_v_lang_sort_idx ON wcc_magic_spells_v (lang, sort_key);


