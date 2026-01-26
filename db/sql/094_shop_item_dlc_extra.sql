\echo '094_shop_item_dlc_extra.sql'
-- Extra DLC eligibility for shop items (rare cases where an item should be available under multiple DLCs)
-- Motivation: avoid duplicating item rows (and double appearance) when both DLCs are enabled.

CREATE TABLE IF NOT EXISTS wcc_shop_item_dlc_extra (
  table_name text NOT NULL, -- e.g. 'wcc_item_weapons_v'
  item_key   text NOT NULL, -- value from metadata.shop.sources[].keyColumn (e.g. 'W140', 'A049', 'B046')
  dlc_id     text NOT NULL REFERENCES wcc_dlcs(dlc_id) ON DELETE CASCADE,
  PRIMARY KEY (table_name, item_key, dlc_id)
);

CREATE INDEX IF NOT EXISTS wcc_shop_item_dlc_extra_lookup_idx
  ON wcc_shop_item_dlc_extra (table_name, item_key, dlc_id);

-- Manticore School items: available with DLC "A Witcher’s Tools" (dlc_wt) OR DLC "The Manticore School" (dlc_sch_manticore)
-- We add dlc_sch_manticore as an extra eligibility for these items.
INSERT INTO wcc_shop_item_dlc_extra (table_name, item_key, dlc_id) VALUES
  ('wcc_item_armors_v',     'A049', 'dlc_sch_manticore'),
  ('wcc_item_armors_v',     'A059', 'dlc_sch_manticore'),
  ('wcc_item_weapons_v',    'W133', 'dlc_sch_manticore'),
  ('wcc_item_weapons_v',    'W140', 'dlc_sch_manticore'),
  ('wcc_item_blueprints_v', 'B223', 'dlc_sch_manticore'),
  ('wcc_item_blueprints_v', 'B230', 'dlc_sch_manticore'),
  ('wcc_item_blueprints_v', 'B046', 'dlc_sch_manticore'),
  ('wcc_item_blueprints_v', 'B056', 'dlc_sch_manticore')
ON CONFLICT DO NOTHING;









