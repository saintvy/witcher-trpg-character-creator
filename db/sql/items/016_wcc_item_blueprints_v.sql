-- Materialized view for shop UI (blueprints catalog)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

DROP MATERIALIZED VIEW IF EXISTS wcc_item_blueprints_v;

CREATE MATERIALIZED VIEW wcc_item_blueprints_v AS
WITH langs AS (
  SELECT 'ru'::text AS lang
  UNION ALL
  SELECT 'en'::text AS lang
),
components_expanded AS (
  SELECT b.b_id
       , l.lang
       , comp_elt.ord AS pos
       , (comp_elt.val->>'id')::uuid AS comp_name_id
       , NULLIF(comp_elt.val->>'qty', '')::int AS qty
    FROM wcc_item_blueprints b
    CROSS JOIN langs l
    CROSS JOIN LATERAL (
      SELECT val, ord
        FROM jsonb_array_elements(COALESCE(b.components, '[]'::jsonb)) WITH ORDINALITY AS t(val, ord)
    ) comp_elt
),
components_pretty AS (
  SELECT ce.b_id
       , ce.lang
       , string_agg(
           CASE
             WHEN ce.qty IS NOT NULL THEN (i18n.text || ' (' || ce.qty::text || ')')
             ELSE i18n.text
           END,
           E',\n' ORDER BY ce.pos
         ) AS components
    FROM components_expanded ce
    LEFT JOIN i18n_text i18n
      ON i18n.id = ce.comp_name_id
     AND i18n.lang = ce.lang
   GROUP BY ce.b_id, ce.lang
)
SELECT b.b_id
     , b.item_id
     , b.dlc_dlc_id AS dlc_id
     , idlcs.text AS dlc
     , COALESCE(iname.text, CASE l.lang WHEN 'ru' THEN b.name_ru ELSE b.name_en END) AS blueprint_name
     , COALESCE(ibg.text, igroup.text) AS blueprint_group
     , icl.text AS craft_level
     , b.difficulty_check
     , CASE
         WHEN b.time_value IS NOT NULL AND b.time_unit_id IS NOT NULL THEN
           b.time_value::text || ' ' || COALESCE(itcu.text, '')
         WHEN b.time_value IS NOT NULL THEN b.time_value::text
         ELSE NULL
       END AS time_craft
     , cp.components
     , COALESCE(b.price_components, 0) AS price_components
     , COALESCE(b.price_blueprint, 0) AS price
     , COALESCE(b.price_item, 0) AS price_item
     , l.lang
  FROM wcc_item_blueprints b
  CROSS JOIN langs l
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = b.dlc_dlc_id
  JOIN i18n_text idlcs ON idlcs.id = dlcs.name_id AND idlcs.lang = l.lang
  LEFT JOIN i18n_text iname ON iname.id = b.name_id AND iname.lang = l.lang
  LEFT JOIN i18n_text igroup ON igroup.id = b.group_id AND igroup.lang = l.lang
  LEFT JOIN i18n_text ibg ON ibg.id = ck_id('blueprint_groups.' || b.group_id::text) AND ibg.lang = l.lang
  LEFT JOIN i18n_text icl ON icl.id = b.craft_level_id AND icl.lang = l.lang
  LEFT JOIN i18n_text itcu ON itcu.id = b.time_unit_id AND itcu.lang = l.lang
  LEFT JOIN components_pretty cp ON cp.b_id = b.b_id AND cp.lang = l.lang
 ORDER BY blueprint_name;

-- Helpful indexes for shop queries
CREATE UNIQUE INDEX IF NOT EXISTS wcc_item_blueprints_v_bid_lang_uidx ON wcc_item_blueprints_v (b_id, lang);
CREATE INDEX IF NOT EXISTS wcc_item_blueprints_v_lang_dlc_idx ON wcc_item_blueprints_v (lang, dlc_id);
CREATE INDEX IF NOT EXISTS wcc_item_blueprints_v_lang_group_idx ON wcc_item_blueprints_v (lang, blueprint_group);


