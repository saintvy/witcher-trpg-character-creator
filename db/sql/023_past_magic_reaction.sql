\echo '023_past_magic_reaction.sql'

INSERT INTO rules (ru_id, name, body)
VALUES
  (
    ck_id('witcher_cc.rules.is_mage_reaction_family_discovery_1_10'),
    'is_mage_reaction_family_discovery_1_10',
    '{"or":[{"in":["wcc_past_magic_discovery_how_o01",{"var":["answers.byQuestion.wcc_past_magic_discovery_how",[]]}]},{"in":["wcc_past_magic_discovery_how_o10",{"var":["answers.byQuestion.wcc_past_magic_discovery_how",[]]}]}]}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_mage_reaction_family_discovery_2_9'),
    'is_mage_reaction_family_discovery_2_9',
    '{"or":[{"in":["wcc_past_magic_discovery_how_o02",{"var":["answers.byQuestion.wcc_past_magic_discovery_how",[]]}]},{"in":["wcc_past_magic_discovery_how_o09",{"var":["answers.byQuestion.wcc_past_magic_discovery_how",[]]}]}]}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_mage_reaction_family_discovery_3_8'),
    'is_mage_reaction_family_discovery_3_8',
    '{"or":[{"in":["wcc_past_magic_discovery_how_o03",{"var":["answers.byQuestion.wcc_past_magic_discovery_how",[]]}]},{"in":["wcc_past_magic_discovery_how_o04",{"var":["answers.byQuestion.wcc_past_magic_discovery_how",[]]}]},{"in":["wcc_past_magic_discovery_how_o05",{"var":["answers.byQuestion.wcc_past_magic_discovery_how",[]]}]},{"in":["wcc_past_magic_discovery_how_o06",{"var":["answers.byQuestion.wcc_past_magic_discovery_how",[]]}]},{"in":["wcc_past_magic_discovery_how_o07",{"var":["answers.byQuestion.wcc_past_magic_discovery_how",[]]}]},{"in":["wcc_past_magic_discovery_how_o08",{"var":["answers.byQuestion.wcc_past_magic_discovery_how",[]]}]}]}'::jsonb
  )
ON CONFLICT (ru_id) DO UPDATE
SET name = EXCLUDED.name,
    body = EXCLUDED.body;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_magic_reaction' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
              ('ru', 'Как семья отреагировала на вашу магию?'),
              ('en', 'How did your family react to your magic?')
           ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
)
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Реакция'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Reaction')
)
, ins_c AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.column_name') AS id
         , meta.entity, 'column_name', c_vals.lang, c_vals.text
      FROM c_vals
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
)
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
SELECT meta.qu_id
     , meta.su_su_id
     , NULL
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body')
     , 'single_table'
     , jsonb_build_object(
         'dice', 'd_weighed',
         'columns', (
           SELECT jsonb_agg(ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(num, 'FM9900') ||'.'|| meta.entity ||'.column_name')::text ORDER BY num)
           FROM (SELECT DISTINCT num FROM c_vals) cols
         ),
         'path', jsonb_build_array(
           ck_id('witcher_cc.hierarchy.magic_discovery')::text,
           ck_id('witcher_cc.hierarchy.magic_reaction')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO NOTHING;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_magic_reaction' AS qu_id
                , 'answer_options' AS entity)
, raw_data AS (
  SELECT 'ru' AS lang, raw_ru.*
    FROM (VALUES
      (1, 1, 4.0::numeric, 'Твоя семья бросила тебя', 'is_mage_reaction_family_discovery_1_10'),
      (1, 2, 1.0::numeric, 'Твоя семья ужасно боялась тебя', 'is_mage_reaction_family_discovery_1_10'),
      (1, 3, 1.0::numeric, 'Ваша семья пыталась продать вас семье с высоким положением', 'is_mage_reaction_family_discovery_1_10'),
      (1, 4, 0.0::numeric, 'Твоя семья немедленно отправила тебя в Аретузу или Бан Ард', 'is_mage_reaction_family_discovery_1_10'),
      (1, 5, 0.0::numeric, 'Твоя семья пыталась игнорировать твой дар', 'is_mage_reaction_family_discovery_1_10'),
      (1, 6, 0.0::numeric, 'Ваша семья и друзья обрадовались твоему таланту', 'is_mage_reaction_family_discovery_1_10'),
      (2, 1, 3.0::numeric, 'Твоя семья бросила тебя', 'is_mage_reaction_family_discovery_2_9'),
      (2, 2, 1.0::numeric, 'Твоя семья ужасно боялась тебя', 'is_mage_reaction_family_discovery_2_9'),
      (2, 3, 1.0::numeric, 'Ваша семья пыталась продать вас семье с высоким положением', 'is_mage_reaction_family_discovery_2_9'),
      (2, 4, 1.0::numeric, 'Твоя семья немедленно отправила тебя в Аретузу или Бан Ард', 'is_mage_reaction_family_discovery_2_9'),
      (2, 5, 0.0::numeric, 'Твоя семья пыталась игнорировать твой дар', 'is_mage_reaction_family_discovery_2_9'),
      (2, 6, 0.0::numeric, 'Ваша семья и друзья обрадовались твоему таланту', 'is_mage_reaction_family_discovery_2_9'),
      (3, 1, 1.0::numeric, 'Твоя семья бросила тебя', 'is_mage_reaction_family_discovery_3_8'),
      (3, 2, 1.0::numeric, 'Твоя семья ужасно боялась тебя', 'is_mage_reaction_family_discovery_3_8'),
      (3, 3, 1.0::numeric, 'Ваша семья пыталась продать вас семье с высоким положением', 'is_mage_reaction_family_discovery_3_8'),
      (3, 4, 1.0::numeric, 'Твоя семья немедленно отправила тебя в Аретузу или Бан Ард', 'is_mage_reaction_family_discovery_3_8'),
      (3, 5, 1.0::numeric, 'Твоя семья пыталась игнорировать твой дар', 'is_mage_reaction_family_discovery_3_8'),
      (3, 6, 1.0::numeric, 'Ваша семья и друзья обрадовались твоему таланту', 'is_mage_reaction_family_discovery_3_8')
    ) AS raw_ru(group_id, num, probability, reaction_txt, rule_name)
  UNION ALL
  SELECT 'en' AS lang, raw_en.*
    FROM (VALUES
      (1, 1, 4.0::numeric, 'Your family cast you out', 'is_mage_reaction_family_discovery_1_10'),
      (1, 2, 1.0::numeric, 'Your family became terribly scared of you', 'is_mage_reaction_family_discovery_1_10'),
      (1, 3, 1.0::numeric, 'Your family tried to sell you to a family of high standing', 'is_mage_reaction_family_discovery_1_10'),
      (1, 4, 0.0::numeric, 'Your family immediately sent you to Aretuza or Ban Ard', 'is_mage_reaction_family_discovery_1_10'),
      (1, 5, 0.0::numeric, 'Your family tried to ignore your gift', 'is_mage_reaction_family_discovery_1_10'),
      (1, 6, 0.0::numeric, 'Your family and friends celebrated your talent', 'is_mage_reaction_family_discovery_1_10'),
      (2, 1, 3.0::numeric, 'Your family cast you out', 'is_mage_reaction_family_discovery_2_9'),
      (2, 2, 1.0::numeric, 'Your family became terribly scared of you', 'is_mage_reaction_family_discovery_2_9'),
      (2, 3, 1.0::numeric, 'Your family tried to sell you to a family of high standing', 'is_mage_reaction_family_discovery_2_9'),
      (2, 4, 1.0::numeric, 'Your family immediately sent you to Aretuza or Ban Ard', 'is_mage_reaction_family_discovery_2_9'),
      (2, 5, 0.0::numeric, 'Your family tried to ignore your gift', 'is_mage_reaction_family_discovery_2_9'),
      (2, 6, 0.0::numeric, 'Your family and friends celebrated your talent', 'is_mage_reaction_family_discovery_2_9'),
      (3, 1, 1.0::numeric, 'Your family cast you out', 'is_mage_reaction_family_discovery_3_8'),
      (3, 2, 1.0::numeric, 'Your family became terribly scared of you', 'is_mage_reaction_family_discovery_3_8'),
      (3, 3, 1.0::numeric, 'Your family tried to sell you to a family of high standing', 'is_mage_reaction_family_discovery_3_8'),
      (3, 4, 1.0::numeric, 'Your family immediately sent you to Aretuza or Ban Ard', 'is_mage_reaction_family_discovery_3_8'),
      (3, 5, 1.0::numeric, 'Your family tried to ignore your gift', 'is_mage_reaction_family_discovery_3_8'),
      (3, 6, 1.0::numeric, 'Your family and friends celebrated your talent', 'is_mage_reaction_family_discovery_3_8')
    ) AS raw_en(group_id, num, probability, reaction_txt, rule_name)
)
, ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100 * raw_data.group_id + raw_data.num, 'FM0000') ||'.'|| meta.entity ||'.label')
       , meta.entity
       , 'label'
       , raw_data.lang
       , '<td style="color: grey;">' || to_char(raw_data.probability * 100, 'FM990.00') || '%</td><td>' || raw_data.reaction_txt || '</td>'
    FROM raw_data
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO UPDATE
  SET text = EXCLUDED.text
)
, ins_lore_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100 * raw_data.group_id + raw_data.num, 'FM0000') ||'.lore.people_reaction')
       , 'character'
       , 'people_reaction'
       , raw_data.lang
       , raw_data.reaction_txt
    FROM raw_data
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO UPDATE
  SET text = EXCLUDED.text
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT meta.qu_id || '_o' || to_char(raw_data.group_id, 'FM00') || to_char(raw_data.num, 'FM00')
     , meta.su_su_id
     , meta.qu_id
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100 * raw_data.group_id + raw_data.num, 'FM0000') ||'.'|| meta.entity ||'.label')
     , raw_data.num
     , (SELECT ru_id FROM rules WHERE name = raw_data.rule_name ORDER BY ru_id LIMIT 1)
     , jsonb_build_object('probability', raw_data.probability)
  FROM raw_data
 CROSS JOIN meta
 WHERE raw_data.lang = 'ru'
ON CONFLICT (an_id) DO NOTHING;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_magic_reaction' AS qu_id)
, nums AS (
  SELECT group_id, num
    FROM (VALUES
      (1,1),(1,2),(1,3),(1,4),(1,5),(1,6),
      (2,1),(2,2),(2,3),(2,4),(2,5),(2,6),
      (3,1),(3,2),(3,3),(3,4),(3,5),(3,6)
    ) AS v(group_id, num)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character'
     , meta.qu_id || '_o' || to_char(nums.group_id, 'FM00') || to_char(nums.num, 'FM00')
     , jsonb_build_object(
         'set',
         jsonb_build_array(
           jsonb_build_object('var', 'characterRaw.lore.people_reaction'),
           jsonb_build_object(
             'i18n_uuid',
             ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100 * nums.group_id + nums.num, 'FM0000') ||'.lore.people_reaction')::text
           )
         )
       )
  FROM nums
 CROSS JOIN meta;

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, priority)
SELECT 'wcc_past_magic_discovery_how', 'wcc_past_magic_reaction', 1;
