\echo '033_wcc_magic_invocations_v.sql'
-- Materialized view for shop UI (magic invocations)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

CREATE MATERIALIZED VIEW wcc_magic_invocations_v AS
WITH langs AS (
  SELECT DISTINCT i18n.lang
    FROM wcc_magic_invocations i
    JOIN i18n_text i18n ON i18n.id = i.name_id
)
SELECT i.ms_id
     , i.dlc_dlc_id AS dlc_id
     , coalesce(idlcs_lang.text, idlcs_en.text) AS dlc
     , coalesce(iname_lang.text, iname_en.text) AS invocation_name
     , coalesce(ilevel_lang.text, ilevel_en.text) AS level
     , coalesce(icult_lang.text, icult_en.text) AS cult_or_circle
     , i.stamina_cast
     , i.stamina_keeping
     , i.damage
     , i.distance
     , i.zone_size
     , coalesce(iform_lang.text, iform_en.text) AS form
     , CASE
         WHEN i.effect_time_value IS NOT NULL AND i.effect_time_unit_id IS NOT NULL THEN
           i.effect_time_value || ' ' || COALESCE(itcu_lang.text, itcu_en.text, '')
         WHEN i.effect_time_value IS NOT NULL THEN i.effect_time_value
         ELSE NULL
       END AS effect_time
     , coalesce(ieffect_lang.text, ieffect_en.text) AS effect
     , CASE
         WHEN i.magic_type_id = ck_id('magic.gruid_invocations') THEN 'druid'
         WHEN i.magic_type_id = ck_id('magic.priest_invocations') THEN 'priest'
         ELSE 'unknown'
       END AS type
     , l.lang
  FROM wcc_magic_invocations i
  CROSS JOIN langs l
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = i.dlc_dlc_id
  LEFT JOIN i18n_text idlcs_lang ON idlcs_lang.id = dlcs.name_id AND idlcs_lang.lang = l.lang
  LEFT JOIN i18n_text idlcs_en ON idlcs_en.id = dlcs.name_id AND idlcs_en.lang = 'en'
  LEFT JOIN i18n_text iname_lang ON iname_lang.id = i.name_id AND iname_lang.lang = l.lang
  LEFT JOIN i18n_text iname_en ON iname_en.id = i.name_id AND iname_en.lang = 'en'
  LEFT JOIN i18n_text ilevel_lang ON ilevel_lang.id = i.level_id AND ilevel_lang.lang = l.lang
  LEFT JOIN i18n_text ilevel_en ON ilevel_en.id = i.level_id AND ilevel_en.lang = 'en'
  LEFT JOIN i18n_text icult_lang ON icult_lang.id = i.cult_or_circle_id AND icult_lang.lang = l.lang
  LEFT JOIN i18n_text icult_en ON icult_en.id = i.cult_or_circle_id AND icult_en.lang = 'en'
  LEFT JOIN i18n_text iform_lang ON iform_lang.id = i.form_id AND iform_lang.lang = l.lang
  LEFT JOIN i18n_text iform_en ON iform_en.id = i.form_id AND iform_en.lang = 'en'
  LEFT JOIN i18n_text itcu_lang ON itcu_lang.id = i.effect_time_unit_id AND itcu_lang.lang = l.lang
  LEFT JOIN i18n_text itcu_en ON itcu_en.id = i.effect_time_unit_id AND itcu_en.lang = 'en'
  LEFT JOIN i18n_text ieffect_lang ON ieffect_lang.id = i.effect_id AND ieffect_lang.lang = l.lang
  LEFT JOIN i18n_text ieffect_en ON ieffect_en.id = i.effect_id AND ieffect_en.lang = 'en'
 ORDER BY invocation_name;

CREATE UNIQUE INDEX IF NOT EXISTS wcc_magic_invocations_v_ms_lang_uidx ON wcc_magic_invocations_v (ms_id, lang);
CREATE INDEX IF NOT EXISTS wcc_magic_invocations_v_lang_dlc_idx ON wcc_magic_invocations_v (lang, dlc_id);
CREATE INDEX IF NOT EXISTS wcc_magic_invocations_v_lang_type_idx ON wcc_magic_invocations_v (lang, type);
CREATE INDEX IF NOT EXISTS wcc_magic_invocations_v_lang_level_idx ON wcc_magic_invocations_v (lang, level);


