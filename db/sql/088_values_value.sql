\echo '088_values_value.sql'

-- Узел: Выжные события - Кто потерпевший
-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_values_value' AS qu_id
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
             ck_id('witcher_cc.hierarchy.values')::text,
             ck_id('witcher_cc.hierarchy.values_value')::text
           )
         )
     FROM meta;
	   
-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_values_value' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
  SELECT v.*
  FROM (VALUES
    ('ru', 1, 'Деньги'),
    ('ru', 2, 'Честь'),
    ('ru', 3, 'Своё слово'),
    ('ru', 4, 'Земные удовольствия'),
    ('ru', 5, 'Знание'),
    ('ru', 6, 'Месть'),
    ('ru', 7, 'Силу'),
    ('ru', 8, 'Любовь'),
    ('ru', 9, 'Выживание'),
    ('ru', 10, 'Дружбу'),
    ('en', 1, 'Money'),
    ('en', 2, 'Honor'),
    ('en', 3, 'Your Word'),
    ('en', 4, 'Hedonistic Pursuits'),
    ('en', 5, 'Knowledge'),
    ('en', 6, 'Vengeance'),
    ('en', 7, 'Power'),
    ('en', 8, 'Love'),
    ('en', 9, 'Survival'),
    ('en', 10, 'Friendship')
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
  SELECT 'wcc_values_value_o' || to_char(vals.num, 'FM9900') AS an_id,
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
  SELECT 'wcc_values_valued_person', 'wcc_values_value';

-- Эффекты: установка значения в characterRaw.lore.values.value
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_values_value' AS qu_id)
, answer_nums AS (
  SELECT num FROM (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10)) AS v(num)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_values_value_o' || to_char(answer_nums.num, 'FM9900'),
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.values.value'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(answer_nums.num, 'FM9900') ||'.answer_options.label')::text)
    )
  )
FROM answer_nums
CROSS JOIN meta;