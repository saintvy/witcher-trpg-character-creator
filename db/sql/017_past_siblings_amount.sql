\echo '017_past_siblings_amount.sql'
-- Узел: Братья и сёстры - количество

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_siblings_amount' AS qu_id
                , 'questions' AS entity)
, ins_body AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
                       , meta.entity, 'body', v.lang, v.text
                    FROM (VALUES
                            ('ru', 'Определим какие братья и сёстры есть у вас.'),
                            ('en', 'Determine what siblings you have.')) AS v(lang, text)
                    CROSS JOIN meta)
, c_vals(lang, num, text) AS (VALUES ('ru', 1, 'Шанс'),
                                     ('ru', 2, 'Количество'),
                                     ('en', 1, 'Chance'),
                                     ('en', 2, 'Amount'))
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
             SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_past_siblings_amount' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
             FROM (SELECT DISTINCT num FROM c_vals) AS cols
           ),
           'path', jsonb_build_array(
             ck_id('witcher_cc.hierarchy.family')::text,
             ck_id('witcher_cc.hierarchy.siblings')::text,
             ck_id('witcher_cc.hierarchy.siblings_amount')::text
           )
         )
    FROM meta;


-- Ответы (каждый вариант 10%)
WITH
raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
            -- group 1: Северянин
            (1, 1, 0.2, 'Единственный ребенок'),
            (1, 2, 0.1, '1'),
            (1, 3, 0.1, '2'),
            (1, 4, 0.1, '3'),
            (1, 5, 0.1, '4'),
            (1, 6, 0.1, '5'),
            (1, 7, 0.1, '6'),
            (1, 8, 0.1, '7'),
            (1, 9, 0.1, '8'),

            -- group 2: Нильфгаардец и Краснолюд
            (2, 1, 0.5, 'Единственный ребенок'),
            (2, 2, 0.1, '1'),
            (2, 3, 0.1, '2'),
            (2, 4, 0.1, '3'),
            (2, 5, 0.1, '4'),
            (2, 6, 0.1, '5'),

            -- group 3: Эльфы
            (3, 1, 0.6, 'Единственный ребенок'),
            (3, 2, 0.2, '1'),
            (3, 3, 0.2, '2')
          ) AS raw_data_ru(group_id, num, probability, amount)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
            -- group 1: Northern
            (1, 1, 0.2, 'Only Child'),
            (1, 2, 0.1, '1'),
            (1, 3, 0.1, '2'),
            (1, 4, 0.1, '3'),
            (1, 5, 0.1, '4'),
            (1, 6, 0.1, '5'),
            (1, 7, 0.1, '6'),
            (1, 8, 0.1, '7'),
            (1, 9, 0.1, '8'),

            -- group 2: Nilfgaardian or Dwarf
            (2, 1, 0.5, 'Only Child'),
            (2, 2, 0.1, '1'),
            (2, 3, 0.1, '2'),
            (2, 4, 0.1, '3'),
            (2, 5, 0.1, '4'),
            (2, 6, 0.1, '5'),

            -- group 3: Elf
            (3, 1, 0.6, 'Only Child'),
            (3, 2, 0.2, '1'),
            (3, 3, 0.2, '2')
         ) AS raw_data_en(group_id, num, probability, amount)
),
vals AS (
         SELECT ('<td>' || to_char(probability*100, 'FM990.00') || '%</td>' ||
                 '<td>' || amount || '</td>') AS text,
                num,
                probability,
                lang,
                group_id
         FROM raw_data
)
, meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_siblings_amount' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, ins_label AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*vals.group_id+vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
                     , meta.entity, meta.entity_field, vals.lang, vals.text
                  FROM vals
                  CROSS JOIN meta
)
, rules_vals(group_id, id, body) AS (
  SELECT 1, gen_random_uuid(),
('{
  "and": [
    ' || body::text || ',
    {"in":[{"var":"characterRaw.logicFields.race"},["Witcher","Human"]]}
  ]
}')::jsonb FROM rules WHERE name = 'is_nordman' UNION ALL
  SELECT 2, gen_random_uuid(),
('{
  "or": [
    {
      "and": [
        ' || body::text || ',
        {"in":[{"var":"characterRaw.logicFields.race"},["Witcher","Human"]]}
      ]
    },
    {"in":[{"var":"characterRaw.logicFields.race"},["Dwarf"]]}
  ]
}')::jsonb FROM rules WHERE name = 'is_nilfgaardian' UNION ALL
  SELECT 3, ru_id, body FROM rules WHERE name = 'is_elf'
)
, ins_rules AS (
  INSERT INTO rules(ru_id, body) SELECT r.id, r.body FROM rules_vals r WHERE group_id !=3
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT 'wcc_past_siblings_amount_o' || to_char(vals.group_id, 'FM00') || to_char(vals.num, 'FM00') AS an_id,
       meta.su_su_id,
       meta.qu_id,
       ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*vals.group_id+vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
       vals.num AS sort_order,
       rules_vals.id AS visible_ru_ru_id,
         jsonb_build_object(
           'probability', vals.probability,
           'counterSet', jsonb_build_array(
                           jsonb_build_object('id','siblingsAmount','value', greatest(0, vals.num - 1)),
                           jsonb_build_object('id','siblingsCounter','value', 1)
                         )
         ) AS metadata
FROM vals
CROSS JOIN meta
JOIN rules_vals ON rules_vals.group_id = vals.group_id
ON CONFLICT (an_id) DO NOTHING;

-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_past_friend', 'wcc_past_siblings_amount';

-- Правила
INSERT INTO rules(name, body) VALUES ('is_there_more_siblings',
'{
  "<=": [
    {
      "var": "counters.siblingsCounter"
    },
    {
      "var": "counters.siblingsAmount"
    }
  ]
}'::jsonb);