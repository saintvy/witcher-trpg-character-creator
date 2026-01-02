\echo '003_past_witcher_q1.sql'
-- Узел: Нужна предистория?

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_witcher_q1' AS qu_id
                , 'questions' AS entity
                , 'single'::question_type AS qtype)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| v.entity_field) AS id
           , meta.entity, v.entity_field, v.lang, v.text
        FROM (VALUES
                ('ru',
'Вы выбрали расу ведьмака, а значит выбор происхождения и семьи не будут влиять на его характеристики. Вы можете пропустить '
  || 'выбор происхождения вовсе, так как ведьмаками становятся в глубоком детстве и не редко ведьмаки вовсе не знают ничего '
  || 'о своей семье. Хотите определить происхождение и семью персонажа?', 'body'),
                ('en',
'You''ve chosen your witcher''s race, meaning your origin and family choices won''t affect their stats. You can skip choosing '
  || 'your origin entirely, as witchers become witchers in early childhood, and it''s not uncommon for them to know nothing '
  || 'about their family. Want to determine your character''s origin and family?', 'body')
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
       , jsonb_build_object(
           'dice', 'd0',
           'path', jsonb_build_array(
             ck_id('witcher_cc.hierarchy.identity')::text,
             ck_id('witcher_cc.hierarchy.witcher_family')::text
           )
         )
     FROM meta;
-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_witcher_q1' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
  SELECT v.*
  FROM (VALUES
    ('ru', 1, 'Я не хочу определять прошлое ведьмака до его попадания в свою школу'),
    ('en', 1, 'I don''t want to define the witcher''s past before he gets to his school.'),
    ('ru', 2, 'Я выберу прошлое для ведьмака, хотя это и не повлияет на характеристики, а сам ведьмак может даже не сможет его вспомнить.'),
    ('en', 2, 'I will choose the past for the witcher, although it will not affect the characteristics, and the witcher himself may not even be able to remember it.')
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
  SELECT 'wcc_past_witcher_q1_o' || to_char(vals.num, 'FM9900') AS an_id,
         meta.su_su_id,
         meta.qu_id,
         ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
         vals.num AS sort_order,
         '{}'::jsonb AS metadata
    FROM vals
    CROSS JOIN meta
  ON CONFLICT (an_id) DO NOTHING;
-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id)
  SELECT 'wcc_race', 'wcc_past_witcher_q1', 'wcc_race_witcher';