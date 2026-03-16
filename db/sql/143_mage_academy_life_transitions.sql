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
  ('wcc_mage_events_danger', 'wcc_mage_events_enemy_victim', 'wcc_mage_events_danger_o0201', NULL, 1),

  -- from: wcc_mage_events_is_in_danger
  ('wcc_mage_events_is_in_danger', 'wcc_mage_events_danger', 'wcc_mage_events_is_in_danger_o0102', NULL, 1),
  ('wcc_mage_events_is_in_danger', 'wcc_mage_events_danger', 'wcc_mage_events_is_in_danger_o0202', NULL, 1),
  ('wcc_mage_events_is_in_danger', 'wcc_mage_events_danger', 'wcc_mage_events_is_in_danger_o0302', NULL, 1),
  ('wcc_mage_events_is_in_danger', 'wcc_mage_events_danger', 'wcc_mage_events_is_in_danger_o0402', NULL, 1),

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
  ('wcc_life_events_relationshipsstory_details', 'wcc_past_academy_life', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_1' ORDER BY ru_id LIMIT 1), 2),

  -- from: wcc_mage_events_enemy_victim
  ('wcc_mage_events_enemy_victim', 'wcc_mage_events_enemy_position', NULL, NULL, 0),

  -- from: wcc_past_academy_life
  ('wcc_past_academy_life', 'wcc_mage_events_enemy_position', 'wcc_past_academy_life_o0206', NULL, 2),
  ('wcc_past_academy_life', 'wcc_mage_events_enemy_position', 'wcc_past_academy_life_o0306', NULL, 2),
  ('wcc_past_academy_life', 'wcc_mage_events_enemy_how_far', 'wcc_past_academy_life_o0103', NULL, 2),

  -- from: wcc_mage_events_danger
  ('wcc_mage_events_danger', 'wcc_mage_events_danger_details', 'wcc_mage_events_danger_o0101', NULL, 1),
  ('wcc_mage_events_danger', 'wcc_mage_events_danger_details', 'wcc_mage_events_danger_o0102', NULL, 1),
  ('wcc_mage_events_danger', 'wcc_mage_events_danger_details', 'wcc_mage_events_danger_o0104', NULL, 1),
  ('wcc_mage_events_danger', 'wcc_mage_events_danger_details', 'wcc_mage_events_danger_o0105', NULL, 1),
  ('wcc_mage_events_danger', 'wcc_mage_events_danger_details', 'wcc_mage_events_danger_o0106', NULL, 1),
  ('wcc_mage_events_danger', 'wcc_mage_events_danger_details', 'wcc_mage_events_danger_o0110', NULL, 1),
  ('wcc_mage_events_danger', 'wcc_mage_events_danger_details', 'wcc_mage_events_danger_o0202', NULL, 1),
  ('wcc_mage_events_danger', 'wcc_mage_events_danger_details', 'wcc_mage_events_danger_o0207', NULL, 1),
  ('wcc_mage_events_danger', 'wcc_mage_events_danger_details', 'wcc_mage_events_danger_o0208', NULL, 1),
  ('wcc_mage_events_danger', 'wcc_mage_events_danger_details', 'wcc_mage_events_danger_o0301', NULL, 1),
  ('wcc_mage_events_danger', 'wcc_mage_events_danger_details', 'wcc_mage_events_danger_o0302', NULL, 1),
  ('wcc_mage_events_danger', 'wcc_mage_events_danger_details', 'wcc_mage_events_danger_o0310', NULL, 1),
  ('wcc_mage_events_danger', 'wcc_mage_events_danger_details', 'wcc_mage_events_danger_o0403', NULL, 1),
  ('wcc_mage_events_danger', 'wcc_mage_events_danger_details', 'wcc_mage_events_danger_o0410', NULL, 1),
  ('wcc_mage_events_danger', 'wcc_mage_events_enemy_position', 'wcc_mage_events_danger_o0205', NULL, 1),
  ('wcc_mage_events_danger', 'wcc_mage_events_enemy_position', 'wcc_mage_events_danger_o0209', NULL, 1),

  -- from: wcc_mage_events_danger_details
  ('wcc_mage_events_danger_details', 'wcc_mage_events_danger_details_2', 'wcc_mage_events_danger_details_o010502', NULL, 1),
  ('wcc_mage_events_danger_details', 'wcc_mage_events_danger_details_2', 'wcc_mage_events_danger_details_o010503', NULL, 1),
  ('wcc_mage_events_danger_details', 'wcc_mage_events_outcome', NULL, NULL, 0),
  ('wcc_mage_events_danger_details_2', 'wcc_mage_events_outcome', NULL, NULL, 0),

  -- from: wcc_mage_events_enemy_position
  ('wcc_mage_events_enemy_position', 'wcc_mage_events_enemy_cause', NULL, NULL, 0),
  ('wcc_mage_events_enemy_position', 'wcc_mage_events_enemy_how_far', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_enemy_skip_cause' ORDER BY ru_id LIMIT 1), 1),

  -- from: wcc_mage_events_enemy_cause
  ('wcc_mage_events_enemy_cause', 'wcc_mage_events_enemy_how_far', NULL, NULL, 0),

  -- from: wcc_mage_events_enemy_how_far
  ('wcc_mage_events_enemy_how_far', 'wcc_mage_events_enemy_the_power', NULL, NULL, 0),
  ('wcc_mage_events_enemy_how_far', 'wcc_mage_events_outcome', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_outcome_from_life_events_2_5' ORDER BY ru_id LIMIT 1), 1),

  -- from: wcc_mage_events_enemy_the_power
  ('wcc_mage_events_enemy_the_power', 'wcc_mage_events_outcome', NULL, NULL, 0),

  -- from: wcc_life_events_fortune_or_not_details_curse
  ('wcc_life_events_fortune_or_not_details_curse', 'wcc_mage_events_outcome', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_outcome_from_life_events_4_10' ORDER BY ru_id LIMIT 1), 2),

  -- from: wcc_life_events_fortune_or_not_details_addiction
  ('wcc_life_events_fortune_or_not_details_addiction', 'wcc_mage_events_outcome', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_outcome_from_life_events_1_2' ORDER BY ru_id LIMIT 1), 2);
