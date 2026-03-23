\echo '164_mage_academy_life_transitions.sql'

-- Rules for academy-life pass routing
INSERT INTO rules (ru_id, name, body)
VALUES
  (
    ck_id('witcher_cc.rules.is_mage_academy_life_flag_eq_1'),
    'is_mage_academy_life_flag_eq_1',
    '{"==":[{"var":"characterRaw.logicFields.flags.academy_life"},1]}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_mage_academy_life_flag_eq_2'),
    'is_mage_academy_life_flag_eq_2',
    '{"==":[{"var":"characterRaw.logicFields.flags.academy_life"},2]}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_not_there_a_friend'),
    'is_not_there_a_friend',
    '{"!":{"is_there_a_friend":[]}}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_mage_mentor_personality_missing'),
    'is_mage_mentor_personality_missing',
    '{"==":[{"var":"characterRaw.lore.mentor.personality"},null]}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_mage_mentor_personality_present'),
    'is_mage_mentor_personality_present',
    '{"!=":[{"var":"characterRaw.lore.mentor.personality"},null]}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_mage_event_from_academy_life_1_9'),
    'is_mage_event_from_academy_life_1_9',
    '{"and":[{"==":[{"var":"characterRaw.logicFields.last_node_and_answer"},"academy life 1-9"]},{"or":[{"==":[{"var":"characterRaw.logicFields.flags.academy_life"},1]},{"==":[{"var":"characterRaw.logicFields.flags.academy_life"},2]}]}]}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_mage_academy_life_flag_eq_3_and_counter_valid'),
    'is_mage_academy_life_flag_eq_3_and_counter_valid',
    '{"and":[{"==":[{"var":"characterRaw.logicFields.flags.academy_life"},3]},{"<":[{"var":"counters.lifeEventsCounter"},{"var":"characterRaw.age"}]}]}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_mage_benefit_not_profit_1_and_counter_valid'),
    'is_mage_benefit_not_profit_1_and_counter_valid',
    '{"and":[{"<":[{"var":"counters.lifeEventsCounter"},{"var":"characterRaw.age"}]},{"!=":[{"reduce":[{"var":["answers.byQuestion.wcc_mage_events_benefit",[]]},{"var":"current"},null]},"wcc_mage_events_benefit_o0001"]}]}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_profit_1_and_academy_4_counter_valid'),
    'is_profit_1_and_academy_4_counter_valid',
    '{"and":[{"==":[{"var":"characterRaw.logicFields.last_node_and_answer"},"Profit 1"]},{"==":[{"var":"characterRaw.logicFields.flags.academy_life"},4]},{"<":[{"var":"counters.lifeEventsCounter"},{"var":"characterRaw.age"}]}]}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_profit_1_and_academy_4_counter_exhausted'),
    'is_profit_1_and_academy_4_counter_exhausted',
    '{"and":[{"==":[{"var":"characterRaw.logicFields.last_node_and_answer"},"Profit 1"]},{"==":[{"var":"characterRaw.logicFields.flags.academy_life"},4]},{">=":[{"var":"counters.lifeEventsCounter"},{"var":"characterRaw.age"}]}]}'::jsonb
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
  ('wcc_past_academy_life', 'wcc_past_academy_life_details', 'wcc_past_academy_life_o0105', NULL, 2),
  ('wcc_past_academy_life', 'wcc_past_academy_life_details', 'wcc_past_academy_life_o0110', NULL, 2),
  ('wcc_past_academy_life', 'wcc_past_academy_life_details', 'wcc_past_academy_life_o0207', NULL, 2),
  ('wcc_past_academy_life', 'wcc_past_academy_life_details', 'wcc_past_academy_life_o0208', NULL, 2),
  ('wcc_past_academy_life', 'wcc_past_mentor_personality', 'wcc_past_academy_life_o0202', NULL, 2),
  ('wcc_past_academy_life', 'wcc_past_academy_life_details', 'wcc_past_academy_life_o0307', NULL, 2),
  ('wcc_past_academy_life', 'wcc_past_mentor_personality', 'wcc_past_academy_life_o0302', NULL, 2),
  ('wcc_past_academy_life', 'wcc_past_academy_life_details', 'wcc_past_academy_life_o0406', NULL, 2),
  ('wcc_past_academy_life', 'wcc_past_academy_life_details', 'wcc_past_academy_life_o0407', NULL, 2),
  ('wcc_past_academy_life', 'wcc_past_mentor_personality', 'wcc_past_academy_life_o0109', (SELECT ru_id FROM rules WHERE name = 'is_mage_mentor_personality_missing' ORDER BY ru_id LIMIT 1), 2),
  ('wcc_past_academy_life', 'wcc_life_events_event', 'wcc_past_academy_life_o0109', (SELECT ru_id FROM rules WHERE name = 'is_mage_mentor_personality_present' ORDER BY ru_id LIMIT 1), 2),
  ('wcc_past_academy_life', 'wcc_past_academy_life', NULL, (SELECT ru_id FROM rules WHERE name = 'magic_academy_life_counter_le_19'), 1),
  ('wcc_past_academy_life', 'wcc_mage_events_risk', NULL, NULL, 0),

  -- from: wcc_past_academy_life_details
  ('wcc_past_academy_life_details', 'wcc_life_events_fortune_or_not_details_curse', 'wcc_past_academy_life_o011006', NULL, 2),
  ('wcc_past_academy_life_details', 'wcc_life_events_fortune_or_not_details_curse_monstrosity', 'wcc_past_academy_life_o011001', NULL, 2),
  ('wcc_past_academy_life_details', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_2' ORDER BY ru_id LIMIT 1), 1),
  ('wcc_past_academy_life_details', 'wcc_past_academy_life', NULL, NULL, 0),

  -- from: wcc_past_mentor_relationship_end
  ('wcc_past_mentor_relationship_end', 'wcc_life_events_event', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_event_from_academy_life_1_9' ORDER BY ru_id LIMIT 1), 2),
  ('wcc_past_mentor_relationship_end', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_2' ORDER BY ru_id LIMIT 1), 1),
  ('wcc_past_mentor_relationship_end', 'wcc_past_academy_life', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_1' ORDER BY ru_id LIMIT 1), 1),

  -- from: wcc_mage_events_risk
  ('wcc_mage_events_danger', 'wcc_mage_events_enemy_victim', 'wcc_mage_events_danger_o0201', NULL, 1),

  -- from: wcc_mage_events_is_in_danger
  ('wcc_mage_events_is_in_danger', 'wcc_mage_events_outcome', 'wcc_mage_events_is_in_danger_o0101', NULL, 1),
  ('wcc_mage_events_is_in_danger', 'wcc_mage_events_outcome', 'wcc_mage_events_is_in_danger_o0201', NULL, 1),
  ('wcc_mage_events_is_in_danger', 'wcc_mage_events_outcome', 'wcc_mage_events_is_in_danger_o0301', NULL, 1),
  ('wcc_mage_events_is_in_danger', 'wcc_mage_events_outcome', 'wcc_mage_events_is_in_danger_o0401', NULL, 1),
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
  ('wcc_mage_events_danger', 'wcc_mage_events_outcome', NULL, NULL, 0),
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
  ('wcc_mage_events_danger', 'wcc_mage_events_danger_details', 'wcc_mage_events_danger_o0309', NULL, 1),
  ('wcc_mage_events_danger', 'wcc_mage_events_danger_details', 'wcc_mage_events_danger_o0310', NULL, 1),
  ('wcc_mage_events_danger', 'wcc_mage_events_danger_details', 'wcc_mage_events_danger_o0403', NULL, 1),
  ('wcc_mage_events_danger', 'wcc_mage_events_danger_details', 'wcc_mage_events_danger_o0410', NULL, 1),
  ('wcc_mage_events_danger', 'wcc_mage_events_enemy_position', 'wcc_mage_events_danger_o0205', NULL, 1),
  ('wcc_mage_events_danger', 'wcc_mage_events_enemy_position', 'wcc_mage_events_danger_o0209', NULL, 1),
  ('wcc_mage_events_danger', 'wcc_mage_events_enemy_position', 'wcc_mage_events_danger_o0203', (SELECT ru_id FROM rules WHERE name = 'is_not_there_a_friend' ORDER BY ru_id LIMIT 1), 2),
  ('wcc_mage_events_danger', 'wcc_mage_events_ally_position', 'wcc_mage_events_danger_o0204', (SELECT ru_id FROM rules WHERE name = 'is_not_there_a_friend' ORDER BY ru_id LIMIT 1), 2),

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
  ('wcc_mage_events_enemy_the_power', 'wcc_past_academy_life', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_1' ORDER BY ru_id LIMIT 1), 1),
  ('wcc_mage_events_enemy_the_power', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_2' ORDER BY ru_id LIMIT 1), 1),

  -- from: wcc_mage_events_outcome
  ('wcc_mage_events_outcome', 'wcc_mage_events_benefit', 'wcc_mage_events_outcome_o0102', NULL, 1),
  ('wcc_mage_events_outcome', 'wcc_mage_events_benefit', 'wcc_mage_events_outcome_o0202', NULL, 1),
  ('wcc_mage_events_outcome', 'wcc_mage_events_benefit', 'wcc_mage_events_outcome_o0302', NULL, 1),
  ('wcc_mage_events_outcome', 'wcc_mage_events_benefit', 'wcc_mage_events_outcome_o0402', NULL, 1),
  ('wcc_mage_events_outcome', 'wcc_mage_events_ally_position', 'wcc_mage_events_outcome_o0103', NULL, 1),
  ('wcc_mage_events_outcome', 'wcc_mage_events_ally_position', 'wcc_mage_events_outcome_o0203', NULL, 1),
  ('wcc_mage_events_outcome', 'wcc_mage_events_ally_position', 'wcc_mage_events_outcome_o0303', NULL, 1),
  ('wcc_mage_events_outcome', 'wcc_mage_events_ally_position', 'wcc_mage_events_outcome_o0403', NULL, 1),
  ('wcc_mage_events_outcome', 'wcc_mage_events_knowledge', 'wcc_mage_events_outcome_o0104', NULL, 1),
  ('wcc_mage_events_outcome', 'wcc_mage_events_knowledge', 'wcc_mage_events_outcome_o0204', NULL, 1),
  ('wcc_mage_events_outcome', 'wcc_mage_events_knowledge', 'wcc_mage_events_outcome_o0304', NULL, 1),
  ('wcc_mage_events_outcome', 'wcc_mage_events_knowledge', 'wcc_mage_events_outcome_o0404', NULL, 1),

  -- from: wcc_mage_events_benefit
  ('wcc_mage_events_benefit', 'wcc_mage_events_ally_closeness', 'wcc_mage_events_benefit_o0001', NULL, 1),
  ('wcc_mage_events_benefit', 'wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_o0002', NULL, 2),
  ('wcc_mage_events_benefit', 'wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_o0003', NULL, 2),
  ('wcc_mage_events_benefit', 'wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_o0004', NULL, 2),
  ('wcc_mage_events_benefit', 'wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_o0005', NULL, 2),
  ('wcc_mage_events_benefit', 'wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_o0006', NULL, 2),
  ('wcc_mage_events_benefit', 'wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_o0007', NULL, 2),
  ('wcc_mage_events_benefit', 'wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_o0009', NULL, 2),
  ('wcc_mage_events_benefit', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_benefit_not_profit_1_and_counter_valid' ORDER BY ru_id LIMIT 1), 1),
  ('wcc_mage_events_benefit', 'wcc_style_clothing', NULL, NULL, 0),

  -- from: wcc_mage_events_benefit_details
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_details_2', 'wcc_mage_events_benefit_details_o0901', NULL, 2),
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_details_2', 'wcc_mage_events_benefit_details_o0902', NULL, 2),
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_details_2', 'wcc_mage_events_benefit_details_o0903', NULL, 2),
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_details_2', 'wcc_mage_events_benefit_details_o0904', NULL, 2),
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_details_2', 'wcc_mage_events_benefit_details_o0905', NULL, 2),
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_details_2', 'wcc_mage_events_benefit_details_o0906', NULL, 2),
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_details_2', 'wcc_mage_events_benefit_details_o0907', NULL, 2),
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_details_2', 'wcc_mage_events_benefit_details_o0908', NULL, 2),
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_details_2', 'wcc_mage_events_benefit_details_o0909', NULL, 2),
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_details_2', 'wcc_mage_events_benefit_details_o0910', NULL, 2),
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_details_2', 'wcc_mage_events_benefit_details_o0911', NULL, 2),
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_details_2', 'wcc_mage_events_benefit_details_o0912', NULL, 2),
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_details_2', 'wcc_mage_events_benefit_details_o0913', NULL, 2),
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_details_2', 'wcc_mage_events_benefit_details_o0914', NULL, 2),
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_details_2', 'wcc_mage_events_benefit_details_o0915', NULL, 2),
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_details_2', 'wcc_mage_events_benefit_details_o0916', NULL, 2),
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_details_2', 'wcc_mage_events_benefit_details_o0917', NULL, 2),
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_details_2', 'wcc_mage_events_benefit_details_o0918', NULL, 2),
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_details_2', 'wcc_mage_events_benefit_details_o0919', NULL, 2),
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_details_2', 'wcc_mage_events_benefit_details_o0920', NULL, 2),
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_details_2', 'wcc_mage_events_benefit_details_o0921', NULL, 2),
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_details_2', 'wcc_mage_events_benefit_details_o0922', NULL, 2),
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_benefit_details_2', 'wcc_mage_events_benefit_details_o0923', NULL, 2),
  ('wcc_mage_events_benefit_details', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'lifeEventsCounter_is_valid' ORDER BY ru_id LIMIT 1), 1),
  ('wcc_mage_events_benefit_details', 'wcc_style_clothing', NULL, NULL, 0),

  -- from: wcc_mage_events_benefit_details_2
  ('wcc_mage_events_benefit_details_2', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'lifeEventsCounter_is_valid' ORDER BY ru_id LIMIT 1), 1),
  ('wcc_mage_events_benefit_details_2', 'wcc_style_clothing', NULL, NULL, 0),

  -- from: wcc_mage_events_knowledge
  ('wcc_mage_events_knowledge', 'wcc_mage_events_knowledge_details', 'wcc_mage_events_knowledge_o0010', NULL, 3),
  ('wcc_mage_events_knowledge', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'lifeEventsCounter_is_valid' ORDER BY ru_id LIMIT 1), 2),
  ('wcc_mage_events_knowledge', 'wcc_style_clothing', NULL, NULL, 0),

  -- from: wcc_mage_events_knowledge_details
  ('wcc_mage_events_knowledge_details', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'lifeEventsCounter_is_valid' ORDER BY ru_id LIMIT 1), 2),
  ('wcc_mage_events_knowledge_details', 'wcc_style_clothing', NULL, NULL, 0),

  -- from: wcc_mage_events_ally_position
  ('wcc_mage_events_ally_position', 'wcc_mage_events_ally_how_met', NULL, NULL, 0),

  -- from: wcc_mage_events_ally_how_met
  ('wcc_mage_events_ally_how_met', 'wcc_mage_events_ally_closeness', NULL, NULL, 0),

  -- from: wcc_past_academy_life
  ('wcc_past_academy_life', 'wcc_mage_events_ally_closeness', 'wcc_past_academy_life_o0102', NULL, 1),
  ('wcc_past_academy_life', 'wcc_mage_events_ally_closeness', 'wcc_past_academy_life_o0308', NULL, 1),

  -- from: wcc_mage_events_ally_closeness
  ('wcc_mage_events_ally_closeness', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'is_profit_1_and_academy_4_counter_valid' ORDER BY ru_id LIMIT 1), 1),
  ('wcc_mage_events_ally_closeness', 'wcc_style_clothing', NULL, (SELECT ru_id FROM rules WHERE name = 'is_profit_1_and_academy_4_counter_exhausted' ORDER BY ru_id LIMIT 1), 1),
  ('wcc_mage_events_ally_closeness', 'wcc_mage_events_ally_value', NULL, NULL, 0),
  
  -- from: wcc_mage_events_ally_value
  ('wcc_mage_events_ally_value', 'wcc_past_academy_life', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_1' ORDER BY ru_id LIMIT 1), 1),
  ('wcc_mage_events_ally_value', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_2' ORDER BY ru_id LIMIT 1), 1),
  ('wcc_mage_events_ally_value', 'wcc_mage_events_risk', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_academy_life_flag_eq_3_and_counter_valid' ORDER BY ru_id LIMIT 1), 1),
  ('wcc_mage_events_ally_value', 'wcc_style_clothing', NULL, NULL, 0),

  -- from: wcc_life_events_fortune_or_not_details_curse
  ('wcc_life_events_fortune_or_not_details_curse', 'wcc_mage_events_outcome', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_outcome_from_life_events_4_10' ORDER BY ru_id LIMIT 1), 2),

  -- from: wcc_life_events_fortune_or_not_details_addiction
  ('wcc_life_events_fortune_or_not_details_addiction', 'wcc_mage_events_outcome', NULL, (SELECT ru_id FROM rules WHERE name = 'is_mage_outcome_from_life_events_1_2' ORDER BY ru_id LIMIT 1), 2);
