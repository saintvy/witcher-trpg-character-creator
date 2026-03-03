\echo '031_wcc_magic_spells_v.sql'
-- Materialized view for shop UI (magic spells & signs)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

CREATE MATERIALIZED VIEW wcc_magic_spells_v AS
WITH langs AS (
  SELECT DISTINCT i.lang
    FROM wcc_magic_spells s
    JOIN i18n_text i ON i.id = s.name_id
)
SELECT s.ms_id
     , s.dlc_dlc_id AS dlc_id
     , coalesce(idlcs_lang.text, idlcs_en.text) AS dlc
     , coalesce(iname_lang.text, iname_en.text) AS spell_name
     , coalesce(ilevel_lang.text, ilevel_en.text) AS level
     , coalesce(ielement_lang.text, ielement_en.text) AS element
     , s.stamina_cast
     , s.stamina_keeping
     , s.damage
     , s.distance
     , s.zone_size
     , coalesce(iform_lang.text, iform_en.text) AS form
     , CASE
         WHEN s.effect_time_value IS NOT NULL AND s.effect_time_unit_id IS NOT NULL THEN
           s.effect_time_value || ' ' || COALESCE(itcu_lang.text, itcu_en.text, '')
         WHEN s.effect_time_value IS NOT NULL THEN s.effect_time_value
         ELSE NULL
       END AS effect_time
     , coalesce(ieffect_lang.text, ieffect_en.text) AS effect
     , (coalesce(ielement_lang.text, ielement_en.text, '') || '|' || coalesce(iname_lang.text, iname_en.text, '')) AS sort_key
     , s.type
     , l.lang
  FROM wcc_magic_spells s
  CROSS JOIN langs l
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = s.dlc_dlc_id
  LEFT JOIN i18n_text idlcs_lang ON idlcs_lang.id = dlcs.name_id AND idlcs_lang.lang = l.lang
  LEFT JOIN i18n_text idlcs_en ON idlcs_en.id = dlcs.name_id AND idlcs_en.lang = 'en'
  LEFT JOIN i18n_text iname_lang ON iname_lang.id = s.name_id AND iname_lang.lang = l.lang
  LEFT JOIN i18n_text iname_en ON iname_en.id = s.name_id AND iname_en.lang = 'en'
  LEFT JOIN i18n_text ilevel_lang ON ilevel_lang.id = s.level_id AND ilevel_lang.lang = l.lang
  LEFT JOIN i18n_text ilevel_en ON ilevel_en.id = s.level_id AND ilevel_en.lang = 'en'
  LEFT JOIN i18n_text ielement_lang ON ielement_lang.id = s.element_id AND ielement_lang.lang = l.lang
  LEFT JOIN i18n_text ielement_en ON ielement_en.id = s.element_id AND ielement_en.lang = 'en'
  LEFT JOIN i18n_text iform_lang ON iform_lang.id = s.form_id AND iform_lang.lang = l.lang
  LEFT JOIN i18n_text iform_en ON iform_en.id = s.form_id AND iform_en.lang = 'en'
  LEFT JOIN i18n_text itcu_lang ON itcu_lang.id = s.effect_time_unit_id AND itcu_lang.lang = l.lang
  LEFT JOIN i18n_text itcu_en ON itcu_en.id = s.effect_time_unit_id AND itcu_en.lang = 'en'
  LEFT JOIN i18n_text ieffect_lang ON ieffect_lang.id = s.effect_id AND ieffect_lang.lang = l.lang
  LEFT JOIN i18n_text ieffect_en ON ieffect_en.id = s.effect_id AND ieffect_en.lang = 'en'
 ORDER BY spell_name;

CREATE UNIQUE INDEX IF NOT EXISTS wcc_magic_spells_v_ms_lang_uidx ON wcc_magic_spells_v (ms_id, lang);
CREATE INDEX IF NOT EXISTS wcc_magic_spells_v_lang_dlc_idx ON wcc_magic_spells_v (lang, dlc_id);
CREATE INDEX IF NOT EXISTS wcc_magic_spells_v_lang_level_idx ON wcc_magic_spells_v (lang, level);
CREATE INDEX IF NOT EXISTS wcc_magic_spells_v_lang_sort_idx ON wcc_magic_spells_v (lang, sort_key);


