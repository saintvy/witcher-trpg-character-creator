\echo '032_wcc_magic_hexes_v.sql'
-- Materialized view for shop UI (magic hexes)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

CREATE MATERIALIZED VIEW wcc_magic_hexes_v AS
WITH langs AS (
  SELECT DISTINCT i18n.lang
    FROM wcc_magic_hexes h
    JOIN i18n_text i18n ON i18n.id = h.name_id
),
components_expanded AS (
  SELECT h.ms_id
       , l.lang
       , comp_elt.ord AS pos
       , (comp_elt.val->>'id')::uuid AS comp_name_id
       , NULLIF(comp_elt.val->>'qty', '')::int AS qty
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
       , E'\n - ' || string_agg(
           CASE
             WHEN ce.qty IS NOT NULL THEN (coalesce(i18n_lang.text, i18n_en.text, '') || ' (' || ce.qty::text || ')')
             ELSE coalesce(i18n_lang.text, i18n_en.text, '')
           END,
           E',\n - ' ORDER BY ce.pos
         ) AS remove_components
    FROM components_expanded ce
    LEFT JOIN i18n_text i18n_lang
      ON i18n_lang.id = ce.comp_name_id
     AND i18n_lang.lang = ce.lang
    LEFT JOIN i18n_text i18n_en
      ON i18n_en.id = ce.comp_name_id
     AND i18n_en.lang = 'en'
   GROUP BY ce.ms_id, ce.lang
),
hex_rows AS (
  SELECT h.ms_id
       , h.dlc_dlc_id AS dlc_id
       , coalesce(idlcs_lang.text, idlcs_en.text) AS dlc
       , coalesce(iname_lang.text, iname_en.text) AS hex_name
       , coalesce(ilevel_lang.text, ilevel_en.text) AS level
       , h.stamina_cast
       , coalesce(ieffect_lang.text, ieffect_en.text) AS effect
       , coalesce(iremove_lang.text, iremove_en.text) AS remove_instructions
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
    LEFT JOIN i18n_text idlcs_lang ON idlcs_lang.id = dlcs.name_id AND idlcs_lang.lang = l.lang
    LEFT JOIN i18n_text idlcs_en ON idlcs_en.id = dlcs.name_id AND idlcs_en.lang = 'en'
    LEFT JOIN i18n_text iname_lang ON iname_lang.id = h.name_id AND iname_lang.lang = l.lang
    LEFT JOIN i18n_text iname_en ON iname_en.id = h.name_id AND iname_en.lang = 'en'
    LEFT JOIN i18n_text ilevel_lang ON ilevel_lang.id = h.level_id AND ilevel_lang.lang = l.lang
    LEFT JOIN i18n_text ilevel_en ON ilevel_en.id = h.level_id AND ilevel_en.lang = 'en'
    LEFT JOIN i18n_text ieffect_lang ON ieffect_lang.id = h.effect_id AND ieffect_lang.lang = l.lang
    LEFT JOIN i18n_text ieffect_en ON ieffect_en.id = h.effect_id AND ieffect_en.lang = 'en'
    LEFT JOIN i18n_text iremove_lang ON iremove_lang.id = h.remove_instructions_id AND iremove_lang.lang = l.lang
    LEFT JOIN i18n_text iremove_en ON iremove_en.id = h.remove_instructions_id AND iremove_en.lang = 'en'
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
     , replace(
         replace(
           replace(
             COALESCE(itpl_lang.text, itpl_en.text, ''),
             '{effect}',
             COALESCE(hr.effect, '')
           ),
           '{remove}',
           COALESCE(hr.remove_instructions, '')
         ),
         '{components}',
         COALESCE(hr.remove_components, '')
       ) AS tooltip
     , lpad(hr.level_sort::text, 2, '0') || '|' || COALESCE(hr.hex_name,'') AS sort_key
     , hr.lang
  FROM hex_rows hr
  LEFT JOIN i18n_text itpl_lang ON itpl_lang.id = ck_id('witcher_cc.magic.hex.tooltip_tpl') AND itpl_lang.lang = hr.lang
  LEFT JOIN i18n_text itpl_en ON itpl_en.id = ck_id('witcher_cc.magic.hex.tooltip_tpl') AND itpl_en.lang = 'en'
 ORDER BY hex_name;

CREATE UNIQUE INDEX IF NOT EXISTS wcc_magic_hexes_v_ms_lang_uidx ON wcc_magic_hexes_v (ms_id, lang);
CREATE INDEX IF NOT EXISTS wcc_magic_hexes_v_lang_dlc_idx ON wcc_magic_hexes_v (lang, dlc_id);
CREATE INDEX IF NOT EXISTS wcc_magic_hexes_v_lang_sort_idx ON wcc_magic_hexes_v (lang, sort_key);



