-- Materialized view for shop UI (upgrades catalog)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

DROP MATERIALIZED VIEW IF EXISTS wcc_item_upgrades_v;

CREATE MATERIALIZED VIEW wcc_item_upgrades_v AS
SELECT iu.u_id
     , iu.dlc_dlc_id AS dlc_id
     , idlcs.text AS dlc
     , iname.text AS upgrade_name
     , igroup.text AS upgrade_group
     , itarget.text AS target
     , coalesce(iu.slots, 1) AS slots
     , coalesce(iu.price, 0) AS price
     , coalesce(iu.weight, 0) AS weight
     , iav.text AS availability
     , ef.effect_names
     , ef.effect_descriptions
     , iname.lang
  FROM wcc_item_upgrades iu
  JOIN i18n_text iname ON iname.id = iu.name_id
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = iu.dlc_dlc_id
  JOIN i18n_text idlcs ON idlcs.id = dlcs.name_id AND idlcs.lang = iname.lang
  LEFT JOIN i18n_text igroup ON igroup.id = iu.group_id AND igroup.lang = iname.lang
  LEFT JOIN i18n_text itarget ON itarget.id = iu.target_id AND itarget.lang = iname.lang
  LEFT JOIN i18n_text iav ON iav.id = iu.availability_id AND iav.lang = iname.lang
  LEFT JOIN (
    SELECT ite.item_id
         , ie.lang
         , string_agg(
             replace(coalesce(ie.text, ''), '<mod>', coalesce(ite.modifier::text, ''))
             || coalesce(nullif('[' || coalesce(iec.text, '') || ']', '[]'), ''),
             E'\n'
             ORDER BY ite.e_e_id
           ) AS effect_names
         , string_agg(CASE WHEN e.description_id is not null then
             replace(coalesce(ie.text, ''), '<mod>', coalesce(ite.modifier::text, ''))
             || ' -' || coalesce(nullif(' [' || coalesce(iec.text, '') || ']', ' []'), '')
             || ' ' || replace(coalesce(ide.text, ''), '<mod>', coalesce(ite.modifier::text, ''))
			 end,
             E'\n'
             ORDER BY ite.e_e_id
           ) AS effect_descriptions
      FROM wcc_item_to_effects ite
      LEFT JOIN wcc_item_effects e ON e.e_id = ite.e_e_id
      LEFT JOIN i18n_text ie ON ie.id = e.name_id
      LEFT JOIN i18n_text ide ON ide.id = e.description_id AND ide.lang = ie.lang
      LEFT JOIN wcc_item_effect_conditions ec ON ec.ec_id = ite.ec_ec_id
      LEFT JOIN i18n_text iec ON iec.id = ec.description_id AND iec.lang = ie.lang
     WHERE ite.item_id LIKE 'U%'
     GROUP BY ite.item_id, ie.lang
  ) ef ON iu.u_id = ef.item_id AND ef.lang = iname.lang
 ORDER BY iname.text;

-- Helpful indexes for shop queries
CREATE UNIQUE INDEX IF NOT EXISTS wcc_item_upgrades_v_uid_lang_uidx ON wcc_item_upgrades_v (u_id, lang);
CREATE INDEX IF NOT EXISTS wcc_item_upgrades_v_lang_dlc_idx ON wcc_item_upgrades_v (lang, dlc_id);



