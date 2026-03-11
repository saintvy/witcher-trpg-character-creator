\echo '032_past_magic_graduation_age.sql'

-- Hierarchy key for mage training graduation age
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.hierarchy.magic_graduation_age'), 'hierarchy', 'path', 'ru', 'Возраст завершения обучения'),
  (ck_id('witcher_cc.hierarchy.magic_graduation_age'), 'hierarchy', 'path', 'en', 'Training completion age')
ON CONFLICT (id, lang) DO NOTHING;

-- Question
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_magic_graduation_age' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru', 'Когда вы закончили магическое обучение?'),
        ('en', 'When did you complete your magical training?')
      ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
SELECT meta.qu_id
     , meta.su_su_id
     , NULL
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body')
     , 'value_numeric'
     , jsonb_build_object(
        'type'        , 'int',
        'defaultValue', 29,
        'placeholder' , 'Years',
        'valueTarget' , 'counters.lifeEventsCounter',
        'path', jsonb_build_array(
          ck_id('witcher_cc.hierarchy.life_events')::text,
          ck_id('witcher_cc.hierarchy.magic_graduation_age')::text
        ),
        'min', 20,
        'max', 29,
        'min_rand', 20,
        'max_rand', 29
      ) AS metadata
  FROM meta
ON CONFLICT (qu_id) DO NOTHING;

-- Normalize 20..29 to 0..9 in life events counter immediately after value is written
INSERT INTO effects (scope, qu_qu_id, body)
SELECT 'character'
     , 'wcc_past_magic_graduation_age'
     , jsonb_build_object(
         'set',
         jsonb_build_array(
           jsonb_build_object('var', 'counters.lifeEventsCounter'),
           jsonb_build_object(
             'jsonlogic_expression',
             jsonb_build_object(
               '-',
               jsonb_build_array(
                 jsonb_build_object('var', 'counters.lifeEventsCounter'),
                 20
               )
             )
           )
         )
       );

-- Transitions to this node
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
SELECT 'wcc_past_mentor_presence', 'wcc_past_magic_graduation_age', v.an_id, 1
  FROM (VALUES
          ('wcc_past_mentor_presence_o02'),
          ('wcc_past_mentor_presence_o04'),
          ('wcc_past_mentor_presence_o06'),
          ('wcc_past_mentor_presence_o08')
       ) AS v(an_id);

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, priority)
SELECT 'wcc_past_mentor_relationship_end', 'wcc_past_magic_graduation_age', 1;

