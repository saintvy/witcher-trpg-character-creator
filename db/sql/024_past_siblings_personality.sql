\echo '024_past_siblings_personality.sql'
-- Узел: Братья и сёстры - Основная черта характера

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_siblings_personality' AS qu_id
                , 'questions' AS entity)
, ins_body AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
                       , meta.entity, 'body', v.lang, v.text
                    FROM (VALUES
                            ('ru', 'Выберете пол брата/сестры.'),
                            ('en', 'Choose sibling''s gender.')) AS v(lang, text)
                    CROSS JOIN meta)
, c_vals(lang, num, text) AS (VALUES ('ru', 1, 'Шанс'),
                                     ('ru', 2, 'Основная черта характера'),
                                     ('en', 1, 'Chance'),
                                     ('en', 2, 'Personality'))
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
             SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_past_siblings_personality' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
             FROM (SELECT DISTINCT num FROM c_vals) AS cols
           ),
           'counterIncrement', jsonb_build_object(
             'id', 'siblingsCounter',
             'step', 1
           ),
           'path', jsonb_build_array(
             ck_id('witcher_cc.hierarchy.family')::text,
             ck_id('witcher_cc.hierarchy.siblings')::text,
             jsonb_build_object('var', 'counters.siblingsCounter'),
             ck_id('witcher_cc.hierarchy.personality')::text
           )
         )
    FROM meta;

-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_siblings_personality' AS qu_id
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
                  -- RU: Northern Kingdoms (10* по 0.05)
                  ('ru', 1, 'Скромность', 0.1::numeric),
                  ('ru', 2, 'Агрессивность', 0.1),
                  ('ru', 3, 'Доброта', 0.1),
                  ('ru', 4, 'С причудами', 0.1),
                  ('ru', 5, 'Вдумчивость', 0.1),
                  ('ru', 6, 'Болтливость', 0.1),
                  ('ru', 7, 'Романтичность', 0.1),
                  ('ru', 8, 'Строгость', 0.1),
                  ('ru', 9, 'Уныние', 0.1),
                  ('ru', 10, 'Инфантильность', 0.1),
                  ('en', 1, 'Shy', 0.1),
                  ('en', 2, 'Aggressive', 0.1),
                  ('en', 3, 'Kind', 0.1),
                  ('en', 4, 'Strange', 0.1),
                  ('en', 5, 'Thoughtful', 0.1),
                  ('en', 6, 'Talkative', 0.1),
                  ('en', 7, 'Romantic', 0.1),
                  ('en', 8, 'Stern', 0.1),
                  ('en', 9, 'Depressive', 0.1),
                  ('en', 10, 'Immature', 0.1)
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
  SELECT 'wcc_past_siblings_personality_o' || to_char(vals.num, 'FM9900') AS an_id,
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
  
-- Эффекты для всех вариантов ответов
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_siblings_personality' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
    SELECT num FROM (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10)) AS v(num)
)

INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_past_siblings_personality_o' || to_char(vals.num, 'FM9900'),
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.lore.siblings'),
      jsonb_build_object(
        'gender',      jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_past_siblings_gender'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'age',         jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_past_siblings_age'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'attitude',    jsonb_build_object('i18n_uuid', jsonb_build_object('ck_id', jsonb_build_object('cat', jsonb_build_array('witcher_cc.', jsonb_build_object('reduce', jsonb_build_array(jsonb_build_object('var', 'answers.byQuestion.wcc_past_siblings_attitude'), jsonb_build_object('var', 'current'), NULL)), '.answer_options.label_value')))),
        'personality', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field || '_value')::text)
      )
    )
  )
FROM vals
CROSS JOIN meta;

-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_past_siblings_attitude', 'wcc_past_siblings_personality';

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_past_siblings_personality', 'wcc_past_siblings_gender', r.ru_id, 3
    FROM rules r WHERE name = 'is_there_more_siblings';