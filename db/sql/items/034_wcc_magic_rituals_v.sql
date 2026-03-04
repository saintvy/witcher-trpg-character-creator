\echo '034_wcc_magic_rituals_v.sql'
-- Materialized view for shop UI (magic rituals)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

CREATE MATERIALIZED VIEW wcc_magic_rituals_v AS
WITH langs AS (
  SELECT DISTINCT i18n.lang
    FROM wcc_magic_rituals r
    JOIN i18n_text i18n ON i18n.id = r.name_id
),
components_expanded AS (
  SELECT r.ms_id
       , l.lang
       , comp_elt.ord AS pos
       , (comp_elt.val->>'id')::uuid AS comp_name_id
       , NULLIF(comp_elt.val->>'qty', '')::int AS qty
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
       , E'\n - ' || string_agg(
           CASE
             WHEN ce.qty IS NOT NULL THEN (COALESCE(i18n_lang.text, i18n_en.text, '') || ' (' || ce.qty::text || ')')
             ELSE COALESCE(i18n_lang.text, i18n_en.text, '')
           END,
           E',\n - ' ORDER BY ce.pos
         ) AS ingredients
    FROM components_expanded ce
    LEFT JOIN i18n_text i18n_lang
      ON i18n_lang.id = ce.comp_name_id
     AND i18n_lang.lang = ce.lang
    LEFT JOIN i18n_text i18n_en
      ON i18n_en.id = ce.comp_name_id
     AND i18n_en.lang = 'en'
   GROUP BY ce.ms_id, ce.lang
)
SELECT r.ms_id
     , r.dlc_dlc_id AS dlc_id
     , coalesce(idlcs_lang.text, idlcs_en.text) AS dlc
     , coalesce(iname_lang.text, iname_en.text) AS ritual_name
     , coalesce(ilevel_lang.text, ilevel_en.text) AS level
     , CASE r.level_id
         WHEN ck_id('level.novice') THEN 1
         WHEN ck_id('level.journeyman') THEN 2
         WHEN ck_id('level.master') THEN 3
         WHEN ck_id('level.arch_priest') THEN 4
         WHEN ck_id('level.arch_druid') THEN 5
         WHEN ck_id('craft.level.grand_master') THEN 6
         ELSE 99
       END AS level_sort
     , coalesce(iform_lang.text, iform_en.text) AS form
     , r.dc
     , r.preparing_time_value::text || ' ' || COALESCE(iunit_round_lang.text, iunit_round_en.text, '') AS preparing_time
     , cp.ingredients
     , r.zone_size
     , r.stamina_cast
     , r.stamina_keeping
     , CASE
         WHEN r.effect_time_value IS NOT NULL AND r.effect_time_unit_id IS NOT NULL THEN
           r.effect_time_value || ' ' || COALESCE(itcu_lang.text, itcu_en.text, '')
         WHEN r.effect_time_value IS NOT NULL THEN r.effect_time_value
         ELSE NULL
       END AS effect_time
     , CASE
         WHEN cp.ingredients IS NOT NULL THEN
           COALESCE(ieffect_lang.text, ieffect_en.text, '') || E'\n\n' || cp.ingredients
         ELSE
           COALESCE(ieffect_lang.text, ieffect_en.text, '')
       END AS effect
     , CASE
         WHEN cp.ingredients IS NOT NULL THEN
           replace(
             replace(
               COALESCE(itpl_lang.text, itpl_en.text, ''),
               '{effect}',
               COALESCE(ieffect_lang.text, ieffect_en.text, '')
             ),
             '{ingredients}',
             COALESCE(cp.ingredients, '')
           )
         ELSE
           COALESCE(ieffect_lang.text, ieffect_en.text, '')
       END AS effect_tpl
     , coalesce(iremove_lang.text, iremove_en.text) AS how_to_remove
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
       ) || '|' || COALESCE(iname_lang.text, iname_en.text,'') AS sort_key
     , l.lang
  FROM wcc_magic_rituals r
  CROSS JOIN langs l
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = r.dlc_dlc_id
  LEFT JOIN i18n_text idlcs_lang ON idlcs_lang.id = dlcs.name_id AND idlcs_lang.lang = l.lang
  LEFT JOIN i18n_text idlcs_en ON idlcs_en.id = dlcs.name_id AND idlcs_en.lang = 'en'
  LEFT JOIN i18n_text iname_lang ON iname_lang.id = r.name_id AND iname_lang.lang = l.lang
  LEFT JOIN i18n_text iname_en ON iname_en.id = r.name_id AND iname_en.lang = 'en'
  LEFT JOIN i18n_text ilevel_lang ON ilevel_lang.id = r.level_id AND ilevel_lang.lang = l.lang
  LEFT JOIN i18n_text ilevel_en ON ilevel_en.id = r.level_id AND ilevel_en.lang = 'en'
  LEFT JOIN i18n_text iform_lang ON iform_lang.id = r.form_id AND iform_lang.lang = l.lang
  LEFT JOIN i18n_text iform_en ON iform_en.id = r.form_id AND iform_en.lang = 'en'
  LEFT JOIN i18n_text itcu_lang ON itcu_lang.id = r.effect_time_unit_id AND itcu_lang.lang = l.lang
  LEFT JOIN i18n_text itcu_en ON itcu_en.id = r.effect_time_unit_id AND itcu_en.lang = 'en'
  LEFT JOIN i18n_text ieffect_lang ON ieffect_lang.id = r.effect_id AND ieffect_lang.lang = l.lang
  LEFT JOIN i18n_text ieffect_en ON ieffect_en.id = r.effect_id AND ieffect_en.lang = 'en'
  LEFT JOIN i18n_text iremove_lang ON iremove_lang.id = r.how_to_remove_id AND iremove_lang.lang = l.lang
  LEFT JOIN i18n_text iremove_en ON iremove_en.id = r.how_to_remove_id AND iremove_en.lang = 'en'
  LEFT JOIN i18n_text itpl_lang ON itpl_lang.id = ck_id('witcher_cc.magic.ritual.effect_tpl') AND itpl_lang.lang = l.lang
  LEFT JOIN i18n_text itpl_en ON itpl_en.id = ck_id('witcher_cc.magic.ritual.effect_tpl') AND itpl_en.lang = 'en'
  LEFT JOIN i18n_text iunit_round_lang ON iunit_round_lang.id = ck_id('time.unit.round') AND iunit_round_lang.lang = l.lang
  LEFT JOIN i18n_text iunit_round_en ON iunit_round_en.id = ck_id('time.unit.round') AND iunit_round_en.lang = 'en'
  LEFT JOIN components_pretty cp ON cp.ms_id = r.ms_id AND cp.lang = l.lang
 ORDER BY ritual_name;

CREATE UNIQUE INDEX IF NOT EXISTS wcc_magic_rituals_v_ms_lang_uidx ON wcc_magic_rituals_v (ms_id, lang);
CREATE INDEX IF NOT EXISTS wcc_magic_rituals_v_lang_dlc_idx ON wcc_magic_rituals_v (lang, dlc_id);
CREATE INDEX IF NOT EXISTS wcc_magic_rituals_v_lang_level_idx ON wcc_magic_rituals_v (lang, level);
CREATE INDEX IF NOT EXISTS wcc_magic_rituals_v_lang_sort_idx ON wcc_magic_rituals_v (lang, sort_key);
