\echo '089_style_affectations.sql'

-- Узел: Выжные события - Кто потерпевший
-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_style_affectations' AS qu_id
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
             ck_id('witcher_cc.hierarchy.style_affectations')::text
           )
         )
     FROM meta;
	   
-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_style_affectations' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
  SELECT v.*
  FROM (VALUES
    ('ru', 1, 'Трофеи'),
    ('ru', 2, 'Кольца и драгоценности'),
    ('ru', 3, 'Безделушки'),
    ('ru', 4, 'Татуировки'),
    ('ru', 5, 'Боевая раскраска'),
    ('ru', 6, 'Тёмный плащ'),
    ('ru', 7, 'Яркие банданы'),
    ('ru', 8, 'Повязка на глаз'),
    ('ru', 9, 'Меха'),
    ('ru', 10, 'Эмблемы и значки'),
    ('en', 1, 'Trophies'),
    ('en', 2, 'Rings & Jewlery'),
    ('en', 3, 'Trinkets'),
    ('en', 4, 'Tattoos'),
    ('en', 5, 'War Paint'),
    ('en', 6, 'Shadowy Cloak'),
    ('en', 7, 'Bright Bandanas'),
    ('en', 8, 'Eye Patch'),
    ('en', 9, 'Furs'),
    ('en', 10, 'Insignias & Plaques')
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
  SELECT 'wcc_style_affectations_o' || to_char(vals.num, 'FM9900') AS an_id,
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
  SELECT 'wcc_style_hair', 'wcc_style_affectations';

-- Эффекты: установка значения в characterRaw.lore.style.affectations
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_style_affectations' AS qu_id)
, answer_nums AS (
  SELECT num FROM (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10)) AS v(num)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_style_affectations_o' || to_char(answer_nums.num, 'FM9900'),
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.style.affectations'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(answer_nums.num, 'FM9900') ||'.answer_options.label')::text)
    )
  )
FROM answer_nums
CROSS JOIN meta;