\echo '088_style_hair.sql'

-- Узел: Выжные события - Кто потерпевший
-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_style_hair' AS qu_id
                , 'questions' AS entity
                , 'single'::question_type AS qtype
	              , '
{
  "dice":"d0"
}'::jsonb AS metadata)
INSERT INTO questions (qu_id, su_su_id, title, qtype, metadata)
  SELECT meta.qu_id
       , meta.su_su_id
       , NULL
       , meta.qtype
	     , meta.metadata || jsonb_build_object(
           'path', jsonb_build_array(
             ck_id('witcher_cc.hierarchy.style')::text,
             ck_id('witcher_cc.hierarchy.style_hair')::text
           )
         )
     FROM meta;
	   
-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_style_hair' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
  SELECT v.*
  FROM (VALUES
    ('ru', 1, 'Длинные распущенные волосы'),
    ('ru', 2, 'Коротко остриженные волосы'),
    ('ru', 3, 'Самостоятельно остриженные волосы'),
    ('ru', 4, 'Заплетённые в косу волосы'),
    ('ru', 5, 'Длинные растрёпанные волосы'),
    ('ru', 6, 'Лысая голова'),
    ('ru', 7, 'Военная стрижка'),
    ('ru', 8, 'Лохматые грязные волосы'),
    ('ru', 9, 'Сложная причёска'),
    ('ru', 10, 'Выбритые виски'),
    ('en', 1, 'Long & Loose'),
    ('en', 2, 'Cropped Short'),
    ('en', 3, 'Self-Cut Short'),
    ('en', 4, 'Braided'),
    ('en', 5, 'Long & Wild'),
    ('en', 6, 'Bald'),
    ('en', 7, 'Uniformly Short'),
    ('en', 8, 'Ragged & Messy'),
    ('en', 9, 'Complicated Hairstyle'),
    ('en', 10, 'Shaven Sides')
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
  SELECT 'wcc_style_hair_o' || to_char(vals.num, 'FM9900') AS an_id,
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
  SELECT 'wcc_style_personality', 'wcc_style_hair';

-- Эффекты: установка значения в characterRaw.lore.style.hair
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_style_hair' AS qu_id)
, answer_nums AS (
  SELECT num FROM (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10)) AS v(num)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_style_hair_o' || to_char(answer_nums.num, 'FM9900'),
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.style.hair_style'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(answer_nums.num, 'FM9900') ||'.answer_options.label')::text)
    )
  )
FROM answer_nums
CROSS JOIN meta;