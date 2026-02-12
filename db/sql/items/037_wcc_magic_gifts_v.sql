\echo '037_wcc_magic_gifts_v.sql'
-- Materialized view for shop UI (magic gifts)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

CREATE MATERIALIZED VIEW wcc_magic_gifts_v AS
WITH langs AS (
  SELECT 'ru'::text AS lang
  UNION ALL
  SELECT 'en'::text AS lang
)
SELECT g.mg_id
     , g.dlc_dlc_id AS dlc_id
     , idlcs.text AS dlc
     , (g.group_id = ck_id('witcher_cc.magic.gift.group.major')) AS is_major
     , igroup.text AS group_name
     , iname.text AS gift_name
     , g.dc
     , g.vigor_cost
     , iac.text AS action_cost
     , ieffect.text AS effect
     , iside.text AS side_effect
     , replace(replace(COALESCE(itpl.text, 'Эффект: {effect}' || E'\n' || 'Побочный эффект: {side_effect}'), '{effect}', COALESCE(ieffect.text, '')), '{side_effect}', COALESCE(iside.text, '')) AS description
     , (COALESCE(igroup.text,'') || '|' || COALESCE(iname.text,'')) AS sort_key
     , l.lang
  FROM wcc_magic_gifts g
  CROSS JOIN langs l
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = g.dlc_dlc_id
  JOIN i18n_text idlcs ON idlcs.id = dlcs.name_id AND idlcs.lang = l.lang
  JOIN i18n_text igroup ON igroup.id = g.group_id AND igroup.lang = l.lang
  JOIN i18n_text iname ON iname.id = g.name_id AND iname.lang = l.lang
  LEFT JOIN i18n_text iac ON iac.lang = l.lang
    AND iac.id = CASE WHEN g.group_id = ck_id('witcher_cc.magic.gift.group.minor') THEN ck_id('witcher_cc.magic.gift.action_cost.minor') WHEN g.group_id = ck_id('witcher_cc.magic.gift.group.major') THEN ck_id('witcher_cc.magic.gift.action_cost.major') END
  LEFT JOIN i18n_text ieffect ON ieffect.id = g.effect_id AND ieffect.lang = l.lang
  LEFT JOIN i18n_text iside ON iside.id = g.side_effect_id AND iside.lang = l.lang
  LEFT JOIN i18n_text itpl ON itpl.id = ck_id('witcher_cc.magic.gift.description_tpl') AND itpl.lang = l.lang
 ORDER BY gift_name;

CREATE UNIQUE INDEX IF NOT EXISTS wcc_magic_gifts_v_mg_lang_uidx ON wcc_magic_gifts_v (mg_id, lang);
CREATE INDEX IF NOT EXISTS wcc_magic_gifts_v_lang_dlc_idx ON wcc_magic_gifts_v (lang, dlc_id);
CREATE INDEX IF NOT EXISTS wcc_magic_gifts_v_lang_sort_idx ON wcc_magic_gifts_v (lang, sort_key);
