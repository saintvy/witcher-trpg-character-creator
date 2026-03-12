\echo '030_past_mentor_key_event.sql'

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_mentor_key_event' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
              ('ru', 'Каким был самый запоминающийся момент?'),
              ('en', 'What was your most memorable moment with your Mentor?')
           ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
)
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Момент'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Moment')
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
         'path', jsonb_build_array(
           jsonb_build_object('jsonlogic_expression', jsonb_build_object('if', jsonb_build_array(
             jsonb_build_object('>', jsonb_build_array(jsonb_build_object('var', 'counters.lifeEventsCounter'), 0)),
             ck_id('witcher_cc.hierarchy.life_events')::text,
             ''
           ))),
           jsonb_build_object('jsonlogic_expression', jsonb_build_object('if', jsonb_build_array(
             jsonb_build_object('>', jsonb_build_array(jsonb_build_object('var', 'counters.lifeEventsCounter'), 0)),
             jsonb_build_object('cat', jsonb_build_array(
               jsonb_build_object('var', 'counters.lifeEventsCounter'),
               '-',
               jsonb_build_object('+', jsonb_build_array(
                 jsonb_build_object('var', 'counters.lifeEventsCounter'),
                 10
               ))
             )),
             ''
           ))),
           jsonb_build_object('jsonlogic_expression', jsonb_build_object('if', jsonb_build_array(
             jsonb_build_object('>', jsonb_build_array(jsonb_build_object('var', 'counters.lifeEventsCounter'), 0)),
             ck_id('witcher_cc.hierarchy.academy_life')::text,
             ''
           ))),
           ck_id('witcher_cc.hierarchy.mentor')::text,
           ck_id('witcher_cc.hierarchy.mentor_key_event')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO NOTHING;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_mentor_key_event' AS qu_id
                , 'answer_options' AS entity)
, raw_data AS (
  SELECT 'ru' AS lang, raw_ru.*
    FROM (VALUES
            (1, 'Вы поделились трогательной историей', 1.0),
            (2, 'Он использовал вас для достижения цели', 1.0),
            (3, 'Он каким-то образом оскорбил вас', 1.0),
            (4, 'Он рисковал своей жизнью, чтобы помочь вам', 1.0),
            (5, 'Он предал ваше доверие', 1.0),
            (6, 'Он взял вас, чтобы встретиться с вашей семьей', 1.0),
            (7, 'Вас пытались бросить', 1.0),
            (8, 'Он помог вам оправиться от чего-то', 1.0),
            (9, 'Он убил или ранил близкого вам человека', 1.0),
            (10, 'Он спас вам жизнь', 1.0)
         ) AS raw_ru(num, label_txt, probability)
  UNION ALL
  SELECT 'en' AS lang, raw_en.*
    FROM (VALUES
            (1, 'You shared a touching moment', 1.0),
            (2, 'They used you to achieve a goal', 1.0),
            (3, 'They abused you in some way', 1.0),
            (4, 'They risked their life to help you', 1.0),
            (5, 'They betrayed your trust', 1.0),
            (6, 'They took you to meet your family', 1.0),
            (7, 'They tried to ditch you', 1.0),
            (8, 'They helped you recover from something', 1.0),
            (9, 'They killed or hurt someone close to you', 1.0),
            (10, 'They saved your life', 1.0)
         ) AS raw_en(num, label_txt, probability)
)
, ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM00') ||'.'|| meta.entity ||'.label') AS id
       , meta.entity, 'label', raw_data.lang
       , '<td>' || to_char(raw_data.probability * 100, 'FM990.00') || '%</td><td>' || raw_data.label_txt || '</td>'
    FROM raw_data
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
, ins_lore_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM00') ||'.lore.mentor.key_event') AS id
       , 'character', 'mentor_key_event', raw_data.lang, raw_data.label_txt
    FROM raw_data
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
SELECT meta.qu_id || '_o' || to_char(raw_data.num, 'FM00') AS an_id
     , meta.su_su_id
     , meta.qu_id
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM00') ||'.'|| meta.entity ||'.label') AS label
     , raw_data.num
     , jsonb_build_object('probability', raw_data.probability)
  FROM raw_data
 CROSS JOIN meta
 WHERE raw_data.lang = 'ru'
ON CONFLICT (an_id) DO NOTHING;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_mentor_key_event' AS qu_id)
, nums AS (
    SELECT generate_series(1, 10) AS num
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character'
     , meta.qu_id || '_o' || to_char(nums.num, 'FM00')
     , jsonb_build_object(
         'set',
         jsonb_build_array(
           jsonb_build_object('var','characterRaw.lore.mentor.key_event'),
           jsonb_build_object(
             'i18n_uuid',
             ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(nums.num, 'FM00') ||'.lore.mentor.key_event')::text
           )
         )
       )
  FROM nums
 CROSS JOIN meta;

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, priority)
SELECT 'wcc_past_mentor_teaching_style', 'wcc_past_mentor_key_event', 1;
