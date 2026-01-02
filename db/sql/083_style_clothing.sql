\echo '083_style_clothing.sql'

-- Узел: Выжные события - Кто потерпевший
-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_style_clothing' AS qu_id
                , 'questions' AS entity
                , 'single'::question_type AS qtype
	              , '
{
  "dice":"d0"
}'::jsonb AS metadata)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| v.entity_field) AS id
           , meta.entity, v.entity_field, v.lang, v.text
        FROM (VALUES
                ('ru', 'Какую одежду вы носите?', 'body'),
                ('en', 'What clothes do you wear?', 'body')
             ) AS v(lang, text, entity_field)
        CROSS JOIN meta
      RETURNING id AS body_id
)
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
  SELECT meta.qu_id
       , meta.su_su_id
       , NULL
       , (SELECT DISTINCT body_id FROM ins_body)
       , meta.qtype
	     , meta.metadata || jsonb_build_object(
           'path', jsonb_build_array(
             ck_id('witcher_cc.hierarchy.style')::text,
             ck_id('witcher_cc.hierarchy.style_clothing')::text
           )
         )
     FROM meta;
	   
-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_style_clothing' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
  SELECT v.*
  FROM (VALUES
    ('ru', 1, 'Военная форма'),
    ('ru', 2, 'Одежда для путешествий'),
    ('ru', 3, 'Роскошная одежда'),
    ('ru', 4, 'Потрёпанная одежда'),
    ('ru', 5, 'Практичная одежда'),
    ('ru', 6, 'Традиционная одежда'),
    ('ru', 7, 'Открытая одежда'),
    ('ru', 8, 'Тёплая одежда'),
    ('ru', 9, 'Странная одежда'),
    ('ru', 10, 'Вычурная одежда'),
    ('en', 1, 'A Uniform'),
    ('en', 2, 'Traveling Clothing'),
    ('en', 3, 'Fancy Clothing'),
    ('en', 4, 'Ragged Clothing'),
    ('en', 5, 'Utilitarian Clothing'),
    ('en', 6, 'Traditional Clothing'),
    ('en', 7, 'Revealing Clothing'),
    ('en', 8, 'Heavy Clothing'),
    ('en', 9, 'Strange Clothing'),
    ('en', 10, 'Flamboyant Clothing')
  ) AS v(lang, num, text)
)
, ins_label AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
           , meta.entity, meta.entity_field, vals.lang, vals.text
        FROM vals
        CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
  SELECT 'wcc_style_clothing_o' || to_char(vals.num, 'FM9900') AS an_id,
         meta.su_su_id,
         meta.qu_id,
         ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
         vals.num AS sort_order,
         '{}'::jsonb AS metadata
    FROM vals
    CROSS JOIN meta
  ON CONFLICT (an_id) DO NOTHING;
  
-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_life_events_enemy_the_power', 'wcc_style_clothing' UNION ALL
  SELECT 'wcc_life_events_ally_where', 'wcc_style_clothing' UNION ALL
  SELECT 'wcc_life_events_fortune', 'wcc_style_clothing' UNION ALL
  SELECT 'wcc_life_events_misfortune', 'wcc_style_clothing' UNION ALL
  SELECT 'wcc_life_events_fortune_or_not_details', 'wcc_style_clothing' UNION ALL
  SELECT 'wcc_life_events_relationshipsstory', 'wcc_style_clothing' UNION ALL
  SELECT 'wcc_life_events_relationshipsstory_details', 'wcc_style_clothing' UNION ALL
  SELECT 'wcc_life_events_fortune_or_not_details_dice', 'wcc_style_clothing' UNION ALL
  SELECT 'wcc_life_events_fortune_or_not_details_addiction', 'wcc_style_clothing' UNION ALL
  SELECT 'wcc_life_events_fortune_or_not_details_curse', 'wcc_style_clothing' UNION ALL
  SELECT 'wcc_witcher_events_benefit', 'wcc_style_clothing' UNION ALL
  SELECT 'wcc_witcher_events_benefit_details', 'wcc_style_clothing' UNION ALL
  SELECT 'wcc_witcher_events_benefit_details_2', 'wcc_style_clothing' UNION ALL
  SELECT 'wcc_witcher_events_ally_is_alive', 'wcc_style_clothing' UNION ALL
  SELECT 'wcc_witcher_events_ally_death_reason', 'wcc_style_clothing' UNION ALL
  SELECT 'wcc_witcher_events_hunt_twist', 'wcc_style_clothing' UNION ALL
  SELECT 'wcc_witcher_events_hunt_twist_details', 'wcc_style_clothing' UNION ALL
  SELECT 'wcc_past_siblings_personality', 'wcc_style_clothing' UNION ALL
  SELECT 'wcc_past_siblings_amount', 'wcc_style_clothing';

  INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_witcher_events_risk', 'wcc_style_clothing', r.ru_id, 0
    FROM (SELECT ru_id FROM rules WHERE name = 'lifeEventsCounter_is_invalid') r;

WITH
  ins_rules AS (
    INSERT INTO rules(ru_id, body)
      SELECT gen_random_uuid()
          , jsonb_build_object(
              'and', jsonb_build_array(
                jsonb_build_object('!', r.body),
                jsonb_build_object(
                  'in', jsonb_build_array(
                    jsonb_build_object(
                      'reduce', jsonb_build_array(
                        jsonb_build_object('var', jsonb_build_array('answers.byQuestion.wcc_witcher_events', jsonb_build_array())),
                        jsonb_build_object('var', 'current'),
                        null
                      )
                    ),
                    jsonb_build_array(
                      'wcc_witcher_events_o0104',
                      'wcc_witcher_events_o0204',
                      'wcc_witcher_events_o0304',
                      'wcc_witcher_events_o0404'
                    )
                  )
                )
              )
            )
        FROM rules r
      WHERE r.name = 'lifeEventsCounter_is_valid'
    RETURNING ru_id
  )
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_witcher_events', 'wcc_style_clothing', r.ru_id, 1
    FROM ins_rules r;

-- Эффекты: установка значения в characterRaw.lore.style.clothing
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_style_clothing' AS qu_id)
, answer_nums AS (
  SELECT num FROM (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10)) AS v(num)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_style_clothing_o' || to_char(answer_nums.num, 'FM9900'),
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.style.clothing'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(answer_nums.num, 'FM9900') ||'.answer_options.label')::text)
    )
  )
FROM answer_nums
CROSS JOIN meta;