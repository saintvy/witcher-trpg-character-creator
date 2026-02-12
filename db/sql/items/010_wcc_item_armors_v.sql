\echo '010_wcc_item_armors_v.sql'
-- Materialized view for shop UI (armors catalog)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

DROP MATERIALIZED VIEW IF EXISTS wcc_item_armors_v;

CREATE MATERIALIZED VIEW wcc_item_armors_v AS
SELECT ia.a_id
     , ia.dlc_dlc_id AS dlc_id
     , idlcs.text AS dlc
     , iname.text AS armor_name
     , ibp.text AS body_part
     , iac.text AS armor_class
     , coalesce(ia.stopping_power, ia.reliability, 0) AS stopping_power
     , coalesce(ia.enhancements, 0) AS enhancements
     , coalesce(ia.encumbrance, 0) AS encumbrance
     , coalesce(ia.weight, 0) AS weight
     , coalesce(ia.price, 0) AS price
     , iav.text AS availability
     , icb.text AS crafted_by
     , ef.effect_names
     , ef.effect_descriptions
     , idesc.text AS armor_description
     , iname.lang
  FROM wcc_item_armors ia
  JOIN i18n_text iname ON iname.id = ia.name_id
  LEFT JOIN i18n_text idesc ON idesc.id = ia.description_id AND idesc.lang = iname.lang
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = ia.dlc_dlc_id
  JOIN i18n_text idlcs ON idlcs.id = dlcs.name_id AND idlcs.lang = iname.lang
  LEFT JOIN i18n_text ibp ON ibp.id = ia.body_part_id AND ibp.lang = iname.lang
  LEFT JOIN i18n_text iac ON iac.id = ia.armor_class_id AND iac.lang = iname.lang
  LEFT JOIN i18n_text iav ON iav.id = ia.availability_id AND iav.lang = iname.lang
  LEFT JOIN i18n_text icb ON icb.id = ia.crafted_by_id AND icb.lang = iname.lang
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
     WHERE ite.item_id LIKE 'A%'
     GROUP BY ite.item_id, ie.lang
  ) ef ON ia.a_id = ef.item_id AND ef.lang = iname.lang
 ORDER BY iname.text;

-- Helpful indexes for shop queries
CREATE UNIQUE INDEX IF NOT EXISTS wcc_item_armors_v_aid_lang_uidx ON wcc_item_armors_v (a_id, lang);
CREATE INDEX IF NOT EXISTS wcc_item_armors_v_lang_dlc_idx ON wcc_item_armors_v (lang, dlc_id);


