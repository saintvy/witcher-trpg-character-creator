\echo '092_values_feelings_on_people.sql'
-- Узел: Повлиявший друг

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_values_feelings_on_people' AS qu_id
                , 'questions' AS entity)
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Мысли'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Feelings')
  )
, ins_c AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| 'column_name') AS id
         , meta.entity, 'column_name', c_vals.lang, c_vals.text
      FROM c_vals
      CROSS JOIN meta
  )
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
SELECT meta.qu_id
     , meta.su_su_id
     , NULL
     , NULL
     , 'single_table'
     , jsonb_build_object(
         'dice', 'd_weighed',
         'columns', (
           SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_values_feelings_on_people' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
           FROM (SELECT DISTINCT num FROM c_vals) AS cols
         ),
         'path', jsonb_build_array(
           ck_id('witcher_cc.hierarchy.values')::text,
           ck_id('witcher_cc.hierarchy.values_feelings_on_people')::text
         )
       )
  FROM meta;


-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_values_feelings_on_people' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
            ( 1, 0.1, 'Все вокруг — инструменты, которыми можно воспользоваться'),
            ( 2, 0.1, 'Наш народ — лучший, и плевать на остальных'),
            ( 3, 0.1, 'Другим доверять нельзя'),
            ( 4, 0.1, 'Пускай другие сначала себя покажут'),
            ( 5, 0.2, 'Нейтральное отношение'),
            ( 7, 0.1, 'Плохих людей не бывает'),
            ( 8, 0.1, 'Все заслуживают смерти'),
            ( 9, 0.1, 'Вокруг одни самовлюблённые свиньи'),
            (10, 0.1, 'Ценна любая жизнь')
         ) AS raw_data_ru(num, probability, friend_txt)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
            ( 1, 0.1, 'People Are Tools to Be Used'),
            ( 2, 0.1, 'Our Kind Are Fine but Plough the Rest'),
            ( 3, 0.1, 'People Can Never Be Trusted'),
            ( 4, 0.1, 'People Have to Prove Themselves'),
            ( 5, 0.2, 'Neutral'),
            ( 7, 0.1, 'People Are Great'),
            ( 8, 0.1, 'Everyone Deserves to Die'),
            ( 9, 0.1, 'People Are Hedonistic Swine'),
            (10, 0.1, 'All Life Is Valuable')
         ) AS raw_data_en(num, probability, friend_txt)
),
vals AS (
         SELECT ('<td>' || to_char(probability*100, 'FM990.00') || '%</td>' ||
                 '<td>' || friend_txt || '</td>') AS text,
                num,
                probability,
                lang,
                friend_txt
         FROM raw_data
)
, ins_label AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
       , meta.entity, meta.entity_field, vals.lang, vals.text
    FROM vals
    CROSS JOIN meta
)
, ins_label_value AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field || '_value') AS id
       , meta.entity, meta.entity_field || '_value', raw_data.lang, raw_data.friend_txt
    FROM raw_data
    CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
SELECT 'wcc_values_feelings_on_people_o' || to_char(vals.num, 'FM00') AS an_id,
       meta.su_su_id,
       meta.qu_id,
       ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
       vals.num,
       jsonb_build_object(
           'probability', vals.probability
       ) AS metadata
FROM vals
CROSS JOIN meta
ON CONFLICT (an_id) DO NOTHING;


-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_values_value', 'wcc_values_feelings_on_people';

-- Эффекты: установка значения в characterRaw.lore.values.feelings_on_people
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_values_feelings_on_people' AS qu_id)
, answer_nums AS (
  SELECT num FROM (VALUES (1), (2), (3), (4), (5), (7), (8), (9), (10)) AS v(num)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_values_feelings_on_people_o' || to_char(answer_nums.num, 'FM00'),
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.values.feelings_on_people'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(answer_nums.num, 'FM9900') ||'.answer_options.label_value')::text)
    )
  )
FROM answer_nums
CROSS JOIN meta;