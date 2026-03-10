\echo '023_past_magic_reaction.sql'

-- Visibility rules by homeland branch
WITH north_ids AS (
  SELECT unnest(ARRAY[
    'wcc_past_homeland_mage_o01','wcc_past_homeland_mage_o02','wcc_past_homeland_mage_o03','wcc_past_homeland_mage_o04',
    'wcc_past_homeland_mage_o05','wcc_past_homeland_mage_o06','wcc_past_homeland_mage_o07','wcc_past_homeland_mage_o08',
    'wcc_past_homeland_mage_o09','wcc_past_homeland_mage_o10','wcc_past_homeland_mage_o11'
  ]) AS an_id
), nilf_ids AS (
  SELECT unnest(ARRAY[
    'wcc_past_homeland_mage_o12','wcc_past_homeland_mage_o13','wcc_past_homeland_mage_o14','wcc_past_homeland_mage_o15',
    'wcc_past_homeland_mage_o16','wcc_past_homeland_mage_o17','wcc_past_homeland_mage_o18','wcc_past_homeland_mage_o19',
    'wcc_past_homeland_mage_o20','wcc_past_homeland_mage_o21','wcc_past_homeland_mage_o22','wcc_past_homeland_mage_o23',
    'wcc_past_homeland_mage_o24'
  ]) AS an_id
), elder_ids AS (
  SELECT unnest(ARRAY['wcc_past_homeland_mage_o25','wcc_past_homeland_mage_o26']) AS an_id
)
INSERT INTO rules (ru_id, name, body)
SELECT ck_id('witcher_cc.rules.is_mage_reaction_north'), 'is_mage_reaction_north',
       jsonb_build_object(
         'or',
         (SELECT jsonb_agg(
            jsonb_build_object(
              'in',
              jsonb_build_array(
                n.an_id,
                jsonb_build_object('var', jsonb_build_array('answers.byQuestion.wcc_past_homeland_mage', jsonb_build_array()))
              )
            )
          ) FROM north_ids n)
       )
UNION ALL
SELECT ck_id('witcher_cc.rules.is_mage_reaction_nilfgaard'), 'is_mage_reaction_nilfgaard',
       jsonb_build_object(
         'or',
         (SELECT jsonb_agg(
            jsonb_build_object(
              'in',
              jsonb_build_array(
                n.an_id,
                jsonb_build_object('var', jsonb_build_array('answers.byQuestion.wcc_past_homeland_mage', jsonb_build_array()))
              )
            )
          ) FROM nilf_ids n)
       )
UNION ALL
SELECT ck_id('witcher_cc.rules.is_mage_reaction_elderlands'), 'is_mage_reaction_elderlands',
       jsonb_build_object(
         'or',
         (SELECT jsonb_agg(
            jsonb_build_object(
              'in',
              jsonb_build_array(
                n.an_id,
                jsonb_build_object('var', jsonb_build_array('answers.byQuestion.wcc_past_homeland_mage', jsonb_build_array()))
              )
            )
          ) FROM elder_ids n)
       )
ON CONFLICT (ru_id) DO UPDATE SET body = EXCLUDED.body;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_magic_reaction' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
              ('ru', 'Как люди реагировали на вашу магию?'),
              ('en', 'How did people react to your magic?')
           ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
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
    ON CONFLICT (id, lang) DO NOTHING
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
         'diceModifier', jsonb_build_object(
           'jsonlogic_expression', jsonb_build_object(
             'var', 'values.byQuestion.wcc_past_magic_discovery_how'
           )
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
            (1,1,'Твоя семья бросила тебя',1.0),
            (1,2,'Твоя семья ужасно боялась тебя',1.0),
            (1,3,'Ваша семья пыталась продать вас семье с высоким положением',1.0),
            (1,4,'Твоя семья немедленно отправила тебя в Аретузу или Бан Ард',1.0),
            (1,5,'Твоя семья пыталась игнорировать твой дар',1.0),
            (1,6,'Ваша семья и друзья обрадовались твоему таланту',1.0),
            (2,1,'Твоя семья ужасно боялась тебя',1.0),
            (2,2,'Твоя семья пыталась игнорировать твой дар',1.0),
            (2,3,'Твоя семья немедленно отправила тебя учиться',1.0),
            (2,4,'Твои братья, сестры и друзья стали ужасно ревнивыми',1.0),
            (2,5,'Твоя семья подтолкнула тебя стать великим магом',1.0),
            (2,6,'Ваша семья и друзья обрадовались твоему таланту',1.0),
            (3,1,'Твоя семья отправила тебя в церковь',1.0),
            (3,2,'Твоя семья немедленно отправила тебя в Гвейсон Хайл',1.0),
            (3,3,'Твоя семья подтолкнула тебя к изучению магии и участию в политике',1.0),
            (3,4,'Твоя семья пыталась использовать твою силу для себя',1.0),
            (3,5,'Твоя семья ужасно боялась тебя',1.0),
            (3,6,'Ваша семья и друзья обрадовались твоему таланту',1.0)
         ) AS raw_ru(group_id, num, reaction_txt, probability)
  UNION ALL
  SELECT 'en' AS lang, raw_en.*
    FROM (VALUES
            (1,1,'Your family cast you out',1.0),
            (1,2,'Your family became terribly scared of you',1.0),
            (1,3,'Your family tried to sell you to a family of high standing',1.0),
            (1,4,'Your family immediately sent you to Aretuza or Ban Ard',1.0),
            (1,5,'Your family tried to ignore your gift',1.0),
            (1,6,'Your family and friends celebrated your talent',1.0),
            (2,1,'Your family became terribly scared of you',1.0),
            (2,2,'Your family tried to ignore your gift',1.0),
            (2,3,'Your family sent you to train immediately',1.0),
            (2,4,'Your siblings and friends became horribly jealous',1.0),
            (2,5,'Your family pushed you to become a great mage',1.0),
            (2,6,'Your family and friends celebrated your talent',1.0),
            (3,1,'Your family sent you to the church',1.0),
            (3,2,'Your family immediately sent you to Gweison Haul',1.0),
            (3,3,'Your family pushed you to study magic and get into politics',1.0),
            (3,4,'Your family tried to use your power for themselves',1.0),
            (3,5,'Your family became terribly scared of you',1.0),
            (3,6,'Your family and friends celebrated your talent',1.0)
         ) AS raw_en(group_id, num, reaction_txt, probability)
)
, ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100 * raw_data.group_id + raw_data.num, 'FM0000') ||'.'|| meta.entity ||'.label') AS id
       , meta.entity, 'label', raw_data.lang
       , '<td>' || to_char(raw_data.probability * 100, 'FM990.00') || '%</td><td>' || raw_data.reaction_txt || '</td>'
    FROM raw_data
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
, ins_lore_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100 * raw_data.group_id + raw_data.num, 'FM0000') ||'.lore.people_reaction') AS id
       , 'character', 'people_reaction', raw_data.lang, raw_data.reaction_txt
    FROM raw_data
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT meta.qu_id || '_o' || to_char(raw_data.group_id, 'FM00') || to_char(raw_data.num, 'FM00') AS an_id
     , meta.su_su_id
     , meta.qu_id
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100 * raw_data.group_id + raw_data.num, 'FM0000') ||'.'|| meta.entity ||'.label') AS label
     , raw_data.num
     , CASE raw_data.group_id
         WHEN 1 THEN ck_id('witcher_cc.rules.is_mage_reaction_north')
         WHEN 2 THEN ck_id('witcher_cc.rules.is_mage_reaction_nilfgaard')
         WHEN 3 THEN ck_id('witcher_cc.rules.is_mage_reaction_elderlands')
       END
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
         ) v(group_id, num)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character' AS scope
     , meta.qu_id || '_o' || to_char(nums.group_id, 'FM00') || to_char(nums.num, 'FM00') AS an_an_id
     , jsonb_build_object(
         'set',
         jsonb_build_array(
           jsonb_build_object('var','characterRaw.lore.people_reaction'),
           jsonb_build_object(
             'i18n_uuid',
             ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100 * nums.group_id + nums.num, 'FM0000') ||'.lore.people_reaction')::text
           )
         )
       ) AS body
  FROM nums
 CROSS JOIN meta;

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, priority)
SELECT 'wcc_past_magic_discovery_how', 'wcc_past_magic_reaction', 1;
