-- Materialized view for shop UI (weapons catalog)
-- Provides localized rows per language, plus dlc_id for filtering by allowedDlcs.

DROP MATERIALIZED VIEW IF EXISTS wcc_item_weapons_v;

CREATE MATERIALIZED VIEW wcc_item_weapons_v AS
SELECT wiw.w_id
     , wiw.dlc_dlc_id AS dlc_id
     , idlcs.text AS dlc
     , iic.text AS weapon_class
     , i.text AS weapon_name
     , wiw.dmg
     , coalesce(wiw.weight, 0) AS weight
     , coalesce(wiw.price, 0) AS price
     , coalesce(wiw.hands, 0) AS hands
     , iav.text AS availability
     , icb.text AS crafted_by
     , icon.text AS concealment
     , concat_ws(', ',
         CASE WHEN wiw.is_piercing IS NOT NULL THEN idp.text ELSE NULL END,
         CASE WHEN wiw.is_slashing IS NOT NULL THEN ids.text ELSE NULL END,
         CASE WHEN wiw.is_bludgeoning IS NOT NULL THEN idb.text ELSE NULL END,
         CASE WHEN wiw.is_elemental IS NOT NULL THEN ide.text ELSE NULL END
       ) AS dmg_types
     , ef.effect_names
     , ef.effect_descriptions
     , i.lang
  FROM wcc_item_weapons wiw
  JOIN i18n_text i ON i.id = wiw.name_id
  JOIN i18n_text iic ON iic.id = wiw.weapon_class_id AND iic.lang = i.lang
  JOIN wcc_dlcs dlcs ON dlcs.dlc_id = wiw.dlc_dlc_id
  JOIN i18n_text idlcs ON idlcs.id = dlcs.name_id AND idlcs.lang = i.lang
  LEFT JOIN i18n_text iav ON iav.id = wiw.availability_id AND iav.lang = i.lang
  LEFT JOIN i18n_text icb ON icb.id = wiw.crafted_by_id AND icb.lang = i.lang
  LEFT JOIN i18n_text icon ON icon.id = wiw.concealment_id AND icon.lang = i.lang
  LEFT JOIN i18n_text idp ON idp.id = wiw.is_piercing AND idp.lang = i.lang
  LEFT JOIN i18n_text ids ON ids.id = wiw.is_slashing AND ids.lang = i.lang
  LEFT JOIN i18n_text idb ON idb.id = wiw.is_bludgeoning AND idb.lang = i.lang
  LEFT JOIN i18n_text ide ON ide.id = wiw.is_elemental AND ide.lang = i.lang
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
     WHERE ite.item_id LIKE 'W%'
     GROUP BY ite.item_id, ie.lang
  ) ef ON wiw.w_id = ef.item_id AND ef.lang = i.lang
 ORDER BY i.text;

-- Helpful indexes for shop queries
CREATE UNIQUE INDEX IF NOT EXISTS wcc_item_weapons_v_wid_lang_uidx ON wcc_item_weapons_v (w_id, lang);
CREATE INDEX IF NOT EXISTS wcc_item_weapons_v_lang_dlc_idx ON wcc_item_weapons_v (lang, dlc_id);


