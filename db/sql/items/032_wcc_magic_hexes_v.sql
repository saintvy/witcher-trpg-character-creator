\echo '032_wcc_magic_hexes_v.sql'
-- Materialized view for shop UI (magic hexes)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

CREATE MATERIALIZED VIEW wcc_magic_hexes_v AS
WITH langs AS (
  SELECT 'ru'::text AS lang
  UNION ALL
  SELECT 'en'::text AS lang
),
components_expanded AS (
  SELECT h.ms_id
       , l.lang
       , comp_elt.ord AS pos
       , (comp_elt.val->>'id')::uuid AS comp_name_id
       , NULLIF(comp_elt.val->>'qty', '') AS qty
    FROM wcc_magic_hexes h
    CROSS JOIN langs l
    CROSS JOIN LATERAL (
      SELECT val, ord
        FROM jsonb_array_elements(COALESCE(h.remove_components, '[]'::jsonb)) WITH ORDINALITY AS t(val, ord)
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
         ) AS remove_components
    FROM components_expanded ce
    LEFT JOIN i18n_text i18n
      ON i18n.id = ce.comp_name_id
     AND i18n.lang = ce.lang
   GROUP BY ce.ms_id, ce.lang
),
hex_rows AS (
  SELECT h.ms_id
       , h.dlc_dlc_id AS dlc_id
       , idlcs.text AS dlc
       , iname.text AS hex_name
       , ilevel.text AS level
       , h.stamina_cast
       , ieffect.text AS effect
       , iremove.text AS remove_instructions
       , cp.remove_components
       , CASE h.level_id
           WHEN ck_id('level.novice') THEN 1
           WHEN ck_id('level.journeyman') THEN 2
           WHEN ck_id('level.master') THEN 3
           WHEN ck_id('level.arch_priest') THEN 4
           WHEN ck_id('level.arch_druid') THEN 5
           ELSE 99
         END AS level_sort
       , l.lang
    FROM wcc_magic_hexes h
    CROSS JOIN langs l
    JOIN wcc_dlcs dlcs ON dlcs.dlc_id = h.dlc_dlc_id
    JOIN i18n_text idlcs ON idlcs.id = dlcs.name_id AND idlcs.lang = l.lang
    JOIN i18n_text iname ON iname.id = h.name_id AND iname.lang = l.lang
    LEFT JOIN i18n_text ilevel ON ilevel.id = h.level_id AND ilevel.lang = l.lang
    LEFT JOIN i18n_text ieffect ON ieffect.id = h.effect_id AND ieffect.lang = l.lang
    LEFT JOIN i18n_text iremove ON iremove.id = h.remove_instructions_id AND iremove.lang = l.lang
    LEFT JOIN components_pretty cp ON cp.ms_id = h.ms_id AND cp.lang = l.lang
)
SELECT hr.ms_id
     , hr.dlc_id
     , hr.dlc
     , hr.hex_name
     , hr.level
     , hr.stamina_cast
     , hr.effect
     , hr.remove_instructions
     , hr.remove_components
     , (COALESCE(hr.effect,'') || E'\n\n' || COALESCE(hr.remove_instructions,'') || E'\n\n' || COALESCE(hr.remove_components,'')) AS tooltip
     , lpad(hr.level_sort::text, 2, '0') || '|' || COALESCE(hr.hex_name,'') AS sort_key
     , hr.lang
  FROM hex_rows hr
 ORDER BY hex_name;

CREATE UNIQUE INDEX IF NOT EXISTS wcc_magic_hexes_v_ms_lang_uidx ON wcc_magic_hexes_v (ms_id, lang);
CREATE INDEX IF NOT EXISTS wcc_magic_hexes_v_lang_dlc_idx ON wcc_magic_hexes_v (lang, dlc_id);
CREATE INDEX IF NOT EXISTS wcc_magic_hexes_v_lang_sort_idx ON wcc_magic_hexes_v (lang, sort_key);


