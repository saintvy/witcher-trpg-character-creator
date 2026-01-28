\echo '018_past_parents_who.sql'
-- Узел: Родители - С кем из родителей?

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_parents_who' AS qu_id
                , 'questions' AS entity)
, ins_body AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
                       , meta.entity, 'body', v.lang, v.text
                    FROM (VALUES
                            ('ru', 'Могли пострадать сразу оба родителя или только один из них.'),
                            ('en', 'Both parents may have suffered, or only one of them.')) AS v(lang, text)
                    CROSS JOIN meta)
, c_vals(lang, num, text) AS (VALUES ('ru', 1, 'Шанс'),
                                     ('ru', 3, 'Родитель'),
                                     ('en', 1, 'Chance'),
                                     ('en', 3, 'Parent'))
, ins_c AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| 'column_name') AS id
                       , meta.entity, 'column_name', c_vals.lang, c_vals.text
				    FROM c_vals
					CROSS JOIN meta)
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
  SELECT meta.qu_id
       , meta.su_su_id
       , NULL
       , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body')
       , 'single_table'
       , jsonb_build_object(
           'dice', 'd_weighed',
           'columns', (
             SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_past_parents_who' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
             FROM (SELECT DISTINCT num FROM c_vals) AS cols
           ),
           'path', jsonb_build_array(
             ck_id('witcher_cc.hierarchy.family')::text,
             ck_id('witcher_cc.hierarchy.parents_fate')::text,
             ck_id('witcher_cc.hierarchy.parents_who')::text
           )
         )
    FROM meta;

-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_parents_who' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
           SELECT ('<td>' || to_char(probability*100, 'FM990.00') || '%</td>' ||
                   '<td>' || parent || '</td>') AS text,
                  num,
                  probability,
                  lang,
                  parent
           FROM (VALUES
                  -- RU: Northern Kingdoms (10* по 0.05)
                  ('ru', 1, 'Отец', 0.4::numeric),
                  ('ru', 2, 'Мать', 0.4),
                  ('ru', 3, 'Оба', 0.2),
                  ('en', 1, 'Father', 0.4),
                  ('en', 2, 'Mother', 0.4),
                  ('en', 3, 'Both', 0.2)
           ) AS v(lang, num, parent, probability)
)
, ins_label AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
                     , meta.entity, meta.entity_field, vals.lang, vals.text
                  FROM vals
                  CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
  SELECT 'wcc_past_parents_who_o' || to_char(vals.num, 'FM9900') AS an_id,
         meta.su_su_id,
         meta.qu_id,
         ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
         vals.num AS sort_order,
         jsonb_build_object(
           'probability', vals.probability
         ) AS metadata
    FROM vals
    CROSS JOIN meta
  ON CONFLICT (an_id) DO NOTHING;

-- i18n записи для опций (Отец/Мать/Оба)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_parents_who' AS qu_id
                , 'character' AS entity)
, parent_options AS (
  SELECT 'ru' AS lang, parent_ru.*
    FROM (VALUES
            (1, 'Отец'),
            (2, 'Мать'),
            (3, 'Оба')
          ) AS parent_ru(num, parent)
  UNION ALL
  SELECT 'en' AS lang, parent_en.*
    FROM (VALUES
            (1, 'Father'),
            (2, 'Mother'),
            (3, 'Both')
          ) AS parent_en(num, parent)
)
, ins_parent AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(parent_options.num, 'FM9900') ||'.'|| meta.entity ||'.'|| 'parents_fate_who') AS id
       , meta.entity, 'parents_fate_who', parent_options.lang, parent_options.parent
    FROM parent_options
    CROSS JOIN meta
)
SELECT 1; -- Заглушка для завершения CTE

-- Эффекты для всех вариантов ответов
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_parents_who' AS qu_id
                , 'character' AS entity)
, vals AS (
    SELECT num
    FROM (VALUES (1), (2), (3)) AS v(num)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_past_parents_who_o' || to_char(vals.num, 'FM9900'),
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.lore.parents_fate_who'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| 'parents_fate_who')::text)
    )
  )
FROM vals
CROSS JOIN meta;
  
-- Связи
WITH
  r AS (INSERT INTO rules(name, body) VALUES (NULL,
'{
  "!": {
    "or": [
      { "var": "answers.byAnswer.wcc_past_parents_fate_o0102" },
      { "var": "answers.byAnswer.wcc_past_parents_fate_o0104" },
      { "var": "answers.byAnswer.wcc_past_parents_fate_o0201" },
      { "var": "answers.byAnswer.wcc_past_parents_fate_o0202" },
      { "var": "answers.byAnswer.wcc_past_parents_fate_o0308" }
    ]
  }
}'::jsonb) RETURNING ru_id)
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_past_parents_fate', 'wcc_past_parents_who', r.ru_id, 1 FROM r;