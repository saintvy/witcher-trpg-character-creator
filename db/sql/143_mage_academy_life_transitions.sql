\echo '143_mage_academy_life_transitions.sql'

-- Rules for academy-life pass routing
INSERT INTO rules (ru_id, name, body)
VALUES
  (
    ck_id('witcher_cc.rules.is_mage_academy_life_flag_eq_1'),
    'is_mage_academy_life_flag_eq_1',
    '{"==":[{"var":"characterRaw.logic_fields.flags.academy_life"},1]}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_mage_academy_life_flag_eq_2'),
    'is_mage_academy_life_flag_eq_2',
    '{"==":[{"var":"characterRaw.logic_fields.flags.academy_life"},2]}'::jsonb
  )
ON CONFLICT (ru_id) DO UPDATE
SET name = EXCLUDED.name,
    body = EXCLUDED.body;

-- Transitions
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, ru_ru_id, priority)
VALUES
  -- from: wcc_past_magic_graduation_age
  ('wcc_past_magic_graduation_age', 'wcc_past_academy_life', NULL, NULL, 0),
  -- from: wcc_past_academy_life
  ('wcc_past_academy_life', 'wcc_past_academy_life_details', 'wcc_past_academy_life_o0110', NULL, 2),
  ('wcc_past_academy_life', 'wcc_past_academy_life_details', 'wcc_past_academy_life_o0207', NULL, 2),
  ('wcc_past_academy_life', 'wcc_past_academy_life_details', 'wcc_past_academy_life_o0208', NULL, 2),
  ('wcc_past_academy_life', 'wcc_past_mentor_personality', 'wcc_past_academy_life_o0202', NULL, 2),
  ('wcc_past_academy_life', 'wcc_past_academy_life_details', 'wcc_past_academy_life_o0307', NULL, 2),
  ('wcc_past_academy_life', 'wcc_past_mentor_personality', 'wcc_past_academy_life_o0302', NULL, 2),
  ('wcc_past_academy_life', 'wcc_past_academy_life_details', 'wcc_past_academy_life_o0406', NULL, 2),
  ('wcc_past_academy_life', 'wcc_past_academy_life_details', 'wcc_past_academy_life_o0407', NULL, 2),
  ('wcc_past_academy_life', 'wcc_life_events_event', 'wcc_past_academy_life_o0109', NULL, 2),
  ('wcc_past_academy_life', 'wcc_past_academy_life', NULL, (SELECT ru_id FROM rules WHERE name = 'magic_academy_life_counter_le_19'), 1),
  ('wcc_past_academy_life', 'wcc_mage_events_risk', NULL, NULL, 0),

  -- from: wcc_past_academy_life_details
  ('wcc_past_academy_life_details', 'wcc_life_events_fortune_or_not_details_curse', 'wcc_past_academy_life_o010706', NULL, 2),
  ('wcc_past_academy_life_details', 'wcc_life_events_fortune_or_not_details_curse_monstrosity', 'wcc_past_academy_life_o010701', NULL, 2),
  ('wcc_past_academy_life_details', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_2' ORDER BY ru_id LIMIT 1), 1),
  ('wcc_past_academy_life_details', 'wcc_past_academy_life', NULL, NULL, 0),

  -- from: wcc_past_mentor_relationship_end
  ('wcc_past_mentor_relationship_end', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_2' ORDER BY ru_id LIMIT 1), 1),
  ('wcc_past_mentor_relationship_end', 'wcc_past_academy_life', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_1' ORDER BY ru_id LIMIT 1), 1),

  -- from: wcc_mage_events_risk

  -- from: wcc_life_events_ally_where
  ('wcc_life_events_ally_where', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_2' ORDER BY ru_id LIMIT 1), 2),
  ('wcc_life_events_ally_where', 'wcc_past_academy_life', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_1' ORDER BY ru_id LIMIT 1), 2),

  -- from: wcc_life_events_enemy_the_power
  ('wcc_life_events_enemy_the_power', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_2' ORDER BY ru_id LIMIT 1), 2),
  ('wcc_life_events_enemy_the_power', 'wcc_past_academy_life', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_1' ORDER BY ru_id LIMIT 1), 2),

  -- from: wcc_life_events_fortune (priority 2)
  ('wcc_life_events_fortune', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_2' ORDER BY ru_id LIMIT 1), 2),
  ('wcc_life_events_fortune', 'wcc_past_academy_life', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_1' ORDER BY ru_id LIMIT 1), 2),

  -- from: wcc_life_events_fortune_or_not_details (priority 2)
  ('wcc_life_events_fortune_or_not_details', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_2' ORDER BY ru_id LIMIT 1), 2),
  ('wcc_life_events_fortune_or_not_details', 'wcc_past_academy_life', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_1' ORDER BY ru_id LIMIT 1), 2),

  -- from: wcc_life_events_fortune_or_not_details_addiction
  ('wcc_life_events_fortune_or_not_details_addiction', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_2' ORDER BY ru_id LIMIT 1), 2),
  ('wcc_life_events_fortune_or_not_details_addiction', 'wcc_past_academy_life', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_1' ORDER BY ru_id LIMIT 1), 2),

  -- from: wcc_life_events_fortune_or_not_details_curse
  ('wcc_life_events_fortune_or_not_details_curse', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_2' ORDER BY ru_id LIMIT 1), 2),
  ('wcc_life_events_fortune_or_not_details_curse', 'wcc_past_academy_life', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_1' ORDER BY ru_id LIMIT 1), 2),

  -- from: wcc_life_events_fortune_or_not_details_curse_monstrosity
  ('wcc_life_events_fortune_or_not_details_curse_monstrosity', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_2' ORDER BY ru_id LIMIT 1), 2),
  ('wcc_life_events_fortune_or_not_details_curse_monstrosity', 'wcc_past_academy_life', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_1' ORDER BY ru_id LIMIT 1), 2),

  -- from: wcc_life_events_fortune_or_not_details_dice
  ('wcc_life_events_fortune_or_not_details_dice', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_2' ORDER BY ru_id LIMIT 1), 2),
  ('wcc_life_events_fortune_or_not_details_dice', 'wcc_past_academy_life', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_1' ORDER BY ru_id LIMIT 1), 2),

  -- from: wcc_life_events_misfortune (priority 2)
  ('wcc_life_events_misfortune', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_2' ORDER BY ru_id LIMIT 1), 2),
  ('wcc_life_events_misfortune', 'wcc_past_academy_life', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_1' ORDER BY ru_id LIMIT 1), 2),

  -- from: wcc_life_events_relationshipsstory
  ('wcc_life_events_relationshipsstory', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_2' ORDER BY ru_id LIMIT 1), 2),
  ('wcc_life_events_relationshipsstory', 'wcc_past_academy_life', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_1' ORDER BY ru_id LIMIT 1), 2),

  -- from: wcc_life_events_relationshipsstory_details
  ('wcc_life_events_relationshipsstory_details', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_2' ORDER BY ru_id LIMIT 1), 2),
  ('wcc_life_events_relationshipsstory_details', 'wcc_past_academy_life', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_1' ORDER BY ru_id LIMIT 1), 2);
