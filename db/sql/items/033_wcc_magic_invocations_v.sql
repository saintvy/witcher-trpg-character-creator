\echo '033_wcc_magic_invocations_v.sql'
-- Materialized view for shop UI (magic invocations)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

CREATE MATERIALIZED VIEW wcc_magic_invocations_v AS
WITH langs AS (
  SELECT 'ru'::text AS lang
  UNION ALL
  SELECT 'en'::text AS lang
)
SELECT i.ms_id
     , i.dlc_dlc_id AS dlc_id
     , idlcs.text AS dlc
     , iname.text AS invocation_name
     , ilevel.text AS level
     , icult.text AS cult_or_circle
     , i.stamina_cast
     , i.stamina_keeping
     , i.damage
     , i.distance
     , i.zone_size
     , iform.text AS form
     , CASE
         WHEN i.effect_time_value IS NOT NULL AND i.effect_time_unit_id IS NOT NULL THEN
           i.effect_time_value || ' ' || COALESCE(itcu.text, '')
         WHEN i.effect_time_value IS NOT NULL THEN i.effect_time_value
         ELSE NULL
       END AS effect_time
     , ieffect.text AS effect
     , CASE
         WHEN i.magic_type_id = ck_id('magic.gruid_invocations') THEN 'druid'
         WHEN i.magic_type_id = ck_id('magic.priest_invocations') THEN 'priest'
         ELSE 'unknown'
       END AS type
     , l.lang
  FROM wcc_magic_invocations i
  CROSS JOIN langs l
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = i.dlc_dlc_id
  JOIN i18n_text idlcs ON idlcs.id = dlcs.name_id AND idlcs.lang = l.lang
  JOIN i18n_text iname ON iname.id = i.name_id AND iname.lang = l.lang
  LEFT JOIN i18n_text ilevel ON ilevel.id = i.level_id AND ilevel.lang = l.lang
  LEFT JOIN i18n_text icult ON icult.id = i.cult_or_circle_id AND icult.lang = l.lang
  LEFT JOIN i18n_text iform ON iform.id = i.form_id AND iform.lang = l.lang
  LEFT JOIN i18n_text itcu ON itcu.id = i.effect_time_unit_id AND itcu.lang = l.lang
  LEFT JOIN i18n_text ieffect ON ieffect.id = i.effect_id AND ieffect.lang = l.lang
 ORDER BY invocation_name;

CREATE UNIQUE INDEX IF NOT EXISTS wcc_magic_invocations_v_ms_lang_uidx ON wcc_magic_invocations_v (ms_id, lang);
CREATE INDEX IF NOT EXISTS wcc_magic_invocations_v_lang_dlc_idx ON wcc_magic_invocations_v (lang, dlc_id);
CREATE INDEX IF NOT EXISTS wcc_magic_invocations_v_lang_type_idx ON wcc_magic_invocations_v (lang, type);
CREATE INDEX IF NOT EXISTS wcc_magic_invocations_v_lang_level_idx ON wcc_magic_invocations_v (lang, level);


