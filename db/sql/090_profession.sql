\echo '090_profession.sql'
-- Узел: Выбор профессии

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_profession' AS qu_id
                , 'questions' AS entity)
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
SELECT meta.qu_id
     , meta.su_su_id
     , NULL
     , NULL
     , 'drop_down_detailed'
     , jsonb_build_object(
         'path', jsonb_build_array(
           ck_id('witcher_cc.hierarchy.profession')::text
         )
       )
  FROM meta;

-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_values_feelings_on_people', 'wcc_profession';

