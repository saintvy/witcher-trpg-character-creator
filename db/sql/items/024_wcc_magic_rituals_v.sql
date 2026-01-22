-- Materialized view for shop UI (magic rituals)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

CREATE MATERIALIZED VIEW wcc_magic_rituals_v AS
WITH langs AS (
  SELECT 'ru'::text AS lang
  UNION ALL
  SELECT 'en'::text AS lang
),
components_expanded AS (
  SELECT r.ms_id
       , l.lang
       , comp_elt.ord AS pos
       , (comp_elt.val->>'id')::uuid AS comp_name_id
       , NULLIF(comp_elt.val->>'qty', '') AS qty
    FROM wcc_magic_rituals r
    CROSS JOIN langs l
    CROSS JOIN LATERAL (
      SELECT val, ord
        FROM jsonb_array_elements(COALESCE(r.ingredients, '[]'::jsonb)) WITH ORDINALITY AS t(val, ord)
    ) comp_elt
),
components_pretty AS (
  SELECT ce.ms_id
       , ce.lang
       , string_agg(
           CASE
             WHEN ce.qty IS NOT NULL THEN (COALESCE(i18n.text,'') || ' (' || ce.qty || ')')
             ELSE COALESCE(i18n.text,'')
           END,
           E',\n' ORDER BY ce.pos
         ) AS ingredients
    FROM components_expanded ce
    LEFT JOIN i18n_text i18n
      ON i18n.id = ce.comp_name_id
     AND i18n.lang = ce.lang
   GROUP BY ce.ms_id, ce.lang
)
SELECT r.ms_id
     , r.dlc_dlc_id AS dlc_id
     , idlcs.text AS dlc
     , iname.text AS ritual_name
     , ilevel.text AS level
     , CASE r.level_id
         WHEN ck_id('level.novice') THEN 1
         WHEN ck_id('level.journeyman') THEN 2
         WHEN ck_id('level.master') THEN 3
         WHEN ck_id('level.arch_priest') THEN 4
         WHEN ck_id('level.arch_druid') THEN 5
         WHEN ck_id('craft.level.grand_master') THEN 6
         ELSE 99
       END AS level_sort
     , iform.text AS form
     , r.dc
     , r.preparing_time_value::text || ' ' || (SELECT text FROM i18n_text t WHERE t.id = ck_id('time.unit.round') AND t.lang = l.lang) AS preparing_time
     , cp.ingredients
     , r.zone_size
     , r.stamina_cast
     , r.stamina_keeping
     , CASE
         WHEN r.effect_time_value IS NOT NULL AND r.effect_time_unit_id IS NOT NULL THEN
           r.effect_time_value || ' ' || COALESCE(itcu.text, '')
         WHEN r.effect_time_value IS NOT NULL THEN r.effect_time_value
         ELSE NULL
       END AS effect_time
     , ieffect.text AS effect
     , iremove.text AS how_to_remove
     , lpad(
         CASE r.level_id
           WHEN ck_id('level.novice') THEN 1
           WHEN ck_id('level.journeyman') THEN 2
           WHEN ck_id('level.master') THEN 3
           WHEN ck_id('level.arch_priest') THEN 4
           WHEN ck_id('level.arch_druid') THEN 5
           WHEN ck_id('craft.level.grand_master') THEN 6
           ELSE 99
         END::text,
         2,
         '0'
       ) || '|' || COALESCE(iname.text,'') AS sort_key
     , l.lang
  FROM wcc_magic_rituals r
  CROSS JOIN langs l
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = r.dlc_dlc_id
  JOIN i18n_text idlcs ON idlcs.id = dlcs.name_id AND idlcs.lang = l.lang
  JOIN i18n_text iname ON iname.id = r.name_id AND iname.lang = l.lang
  LEFT JOIN i18n_text ilevel ON ilevel.id = r.level_id AND ilevel.lang = l.lang
  LEFT JOIN i18n_text iform ON iform.id = r.form_id AND iform.lang = l.lang
  LEFT JOIN i18n_text itcu ON itcu.id = r.effect_time_unit_id AND itcu.lang = l.lang
  LEFT JOIN i18n_text ieffect ON ieffect.id = r.effect_id AND ieffect.lang = l.lang
  LEFT JOIN i18n_text iremove ON iremove.id = r.how_to_remove_id AND iremove.lang = l.lang
  LEFT JOIN components_pretty cp ON cp.ms_id = r.ms_id AND cp.lang = l.lang
 ORDER BY ritual_name;

CREATE UNIQUE INDEX IF NOT EXISTS wcc_magic_rituals_v_ms_lang_uidx ON wcc_magic_rituals_v (ms_id, lang);
CREATE INDEX IF NOT EXISTS wcc_magic_rituals_v_lang_dlc_idx ON wcc_magic_rituals_v (lang, dlc_id);
CREATE INDEX IF NOT EXISTS wcc_magic_rituals_v_lang_level_idx ON wcc_magic_rituals_v (lang, level);
CREATE INDEX IF NOT EXISTS wcc_magic_rituals_v_lang_sort_idx ON wcc_magic_rituals_v (lang, sort_key);


