\echo '048_witcher_graduation_age.sql'
-- Узел: Братья и сёстры - Основная черта характера

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_graduation_age' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru', 'Во сколько вы вышли на Большак? Вам было от 20 до 29 лет.'),
        ('en', 'At what age did you take the path? You were between 20 and 29 years old.')
      ) AS v(lang, text)
      CROSS JOIN meta
  )
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
SELECT meta.qu_id
     , meta.su_su_id
     , NULL
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body')
     , 'value_numeric'
     , jsonb_build_object(
        'type'        , 'int',
        'defaultValue', 29,
        'placeholder' , 'Years',
        'valueTarget' , 'counters.lifeEventsCounter',
        'path', jsonb_build_array(
          ck_id('witcher_cc.hierarchy.witcher')::text,
          ck_id('witcher_cc.hierarchy.witcher_graduation_age')::text
        ),
        'min', 20,
        -- max: 29
        'max', 29,
        -- min_rand: 20
        'min_rand', 20,
        -- max_rand: 29
        'max_rand', 29
      ) AS metadata
  FROM meta;
  
-- Связи


WITH
  is_witcher_rule AS (SELECT ru_id, body FROM rules WHERE name = 'is_witcher'),
  combined_rule AS (
    INSERT INTO rules(ru_id, body)
      SELECT gen_random_uuid()
          , jsonb_build_object(
              'and', jsonb_build_array(
                is_witcher_rule.body,
                jsonb_build_object(
                  'in', jsonb_build_array(
                    'wcc_past_witcher_q1_o01',
                    jsonb_build_object(
                      'reduce', jsonb_build_array(
                        jsonb_build_object('var', jsonb_build_array('answers.byQuestion.wcc_past_witcher_q1', jsonb_build_array())),
                        jsonb_build_object('var', 'current'),
                        jsonb_build_array()
                      )
                    )
                  )
                )
              )
            )
        FROM is_witcher_rule
      RETURNING ru_id
  )
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_ch_age', 'wcc_witcher_graduation_age', cr.ru_id, 1 FROM combined_rule cr UNION ALL
  SELECT 'wcc_past_siblings_personality', 'wcc_witcher_graduation_age', r.ru_id, 2 FROM is_witcher_rule r UNION ALL
  SELECT 'wcc_past_siblings_amount', 'wcc_witcher_graduation_age', r.ru_id, 2 FROM is_witcher_rule r;