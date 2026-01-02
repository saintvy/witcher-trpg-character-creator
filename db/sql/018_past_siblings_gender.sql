\echo '018_past_siblings_gender.sql'
-- Узел: Братья и сёстры - Пол

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_siblings_gender' AS qu_id
                , 'questions' AS entity)
, ins_body AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
                       , meta.entity, 'body', v.lang, v.text
                    FROM (VALUES
                            ('ru', 'Выберете пол брата/сестры.'),
                            ('en', 'Choose sibling''s gender.')) AS v(lang, text)
                    CROSS JOIN meta)
, c_vals(lang, num, text) AS (VALUES ('ru', 1, 'Шанс'),
                                     ('ru', 2, 'Пол'),
                                     ('en', 1, 'Chance'),
                                     ('en', 2, 'Gender'))
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
             SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_past_siblings_gender' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
             FROM (SELECT DISTINCT num FROM c_vals) AS cols
           ),
           'path', jsonb_build_array(
             ck_id('witcher_cc.hierarchy.family')::text,
             ck_id('witcher_cc.hierarchy.siblings')::text,
             jsonb_build_object('var', 'counters.siblingsCounter'),
             ck_id('witcher_cc.hierarchy.gender')::text
           )
         )
    FROM meta;

-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_siblings_gender' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
           SELECT ('<td>' || to_char(probability*100, 'FM990.00') || '%</td>' ||
                   '<td>' || txt || '</td>') AS text,
                  txt,
                  num,
                  probability,
                  lang
           FROM (VALUES
                  ('ru', 1, 'Мужской', 0.5::numeric),
                  ('ru', 2, 'Женский', 0.5),
                  ('en', 1, 'Male', 0.5),
                  ('en', 2, 'Female', 0.5)
           ) AS v(lang, num, txt, probability)
)
, ins_label AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
                     , meta.entity, meta.entity_field, vals.lang, vals.text
                  FROM vals
                  CROSS JOIN meta
)
, ins_label_value AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field || '_value') AS id
                     , meta.entity, meta.entity_field || '_value', vals.lang, vals.txt
                  FROM vals
                  CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
  SELECT 'wcc_past_siblings_gender_o' || to_char(vals.num, 'FM9900') AS an_id,
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
  
-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_past_siblings_amount', 'wcc_past_siblings_gender', r.ru_id, 3
    FROM rules r WHERE name = 'is_there_more_siblings';