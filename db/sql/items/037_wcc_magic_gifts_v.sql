\echo '037_wcc_magic_gifts_v.sql'
-- Materialized view for shop UI (magic gifts)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

CREATE MATERIALIZED VIEW wcc_magic_gifts_v AS
WITH langs AS (
  SELECT DISTINCT i18n.lang
    FROM wcc_magic_gifts g
    JOIN i18n_text i18n ON i18n.id = g.name_id
)
SELECT g.mg_id
     , g.dlc_dlc_id AS dlc_id
     , coalesce(idlcs_lang.text, idlcs_en.text) AS dlc
     , (g.group_id = ck_id('witcher_cc.magic.gift.group.major')) AS is_major
     , coalesce(igroup_lang.text, igroup_en.text) AS group_name
     , coalesce(iname_lang.text, iname_en.text) AS gift_name
     , g.dc
     , g.vigor_cost
     , coalesce(iac_lang.text, iac_en.text) AS action_cost
     , coalesce(ieffect_lang.text, ieffect_en.text) AS effect
     , coalesce(iside_lang.text, iside_en.text) AS side_effect
     , replace(
         replace(
           coalesce(itpl_lang.text, itpl_en.text, ''),
           '{effect}',
           coalesce(ieffect_lang.text, ieffect_en.text, '')
         ),
         '{side_effect}',
         coalesce(iside_lang.text, iside_en.text, '')
       ) AS description
     , (coalesce(igroup_lang.text, igroup_en.text, '') || '|' || coalesce(iname_lang.text, iname_en.text, '')) AS sort_key
     , l.lang
  FROM wcc_magic_gifts g
  CROSS JOIN langs l
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = g.dlc_dlc_id
  LEFT JOIN i18n_text idlcs_lang ON idlcs_lang.id = dlcs.name_id AND idlcs_lang.lang = l.lang
  LEFT JOIN i18n_text idlcs_en ON idlcs_en.id = dlcs.name_id AND idlcs_en.lang = 'en'
  LEFT JOIN i18n_text igroup_lang ON igroup_lang.id = g.group_id AND igroup_lang.lang = l.lang
  LEFT JOIN i18n_text igroup_en ON igroup_en.id = g.group_id AND igroup_en.lang = 'en'
  LEFT JOIN i18n_text iname_lang ON iname_lang.id = g.name_id AND iname_lang.lang = l.lang
  LEFT JOIN i18n_text iname_en ON iname_en.id = g.name_id AND iname_en.lang = 'en'
  LEFT JOIN i18n_text iac_lang ON iac_lang.lang = l.lang
    AND iac_lang.id = CASE WHEN g.group_id = ck_id('witcher_cc.magic.gift.group.minor') THEN ck_id('witcher_cc.magic.gift.action_cost.minor') WHEN g.group_id = ck_id('witcher_cc.magic.gift.group.major') THEN ck_id('witcher_cc.magic.gift.action_cost.major') END
  LEFT JOIN i18n_text iac_en ON iac_en.lang = 'en'
    AND iac_en.id = CASE WHEN g.group_id = ck_id('witcher_cc.magic.gift.group.minor') THEN ck_id('witcher_cc.magic.gift.action_cost.minor') WHEN g.group_id = ck_id('witcher_cc.magic.gift.group.major') THEN ck_id('witcher_cc.magic.gift.action_cost.major') END
  LEFT JOIN i18n_text ieffect_lang ON ieffect_lang.id = g.effect_id AND ieffect_lang.lang = l.lang
  LEFT JOIN i18n_text ieffect_en ON ieffect_en.id = g.effect_id AND ieffect_en.lang = 'en'
  LEFT JOIN i18n_text iside_lang ON iside_lang.id = g.side_effect_id AND iside_lang.lang = l.lang
  LEFT JOIN i18n_text iside_en ON iside_en.id = g.side_effect_id AND iside_en.lang = 'en'
  LEFT JOIN i18n_text itpl_lang ON itpl_lang.id = ck_id('witcher_cc.magic.gift.description_tpl') AND itpl_lang.lang = l.lang
  LEFT JOIN i18n_text itpl_en ON itpl_en.id = ck_id('witcher_cc.magic.gift.description_tpl') AND itpl_en.lang = 'en'
 ORDER BY gift_name;

CREATE UNIQUE INDEX IF NOT EXISTS wcc_magic_gifts_v_mg_lang_uidx ON wcc_magic_gifts_v (mg_id, lang);
CREATE INDEX IF NOT EXISTS wcc_magic_gifts_v_lang_dlc_idx ON wcc_magic_gifts_v (lang, dlc_id);
CREATE INDEX IF NOT EXISTS wcc_magic_gifts_v_lang_sort_idx ON wcc_magic_gifts_v (lang, sort_key);
