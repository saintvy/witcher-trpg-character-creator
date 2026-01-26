\echo '053_witcher_child_who.sql'
-- Узел: Пол ребёнка по Праву Неожиданности

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_child_who' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
         , meta.entity, 'body', v.lang, v.text
    FROM (VALUES
      ('ru', 'Определите пол ребёнка по Праву Неожиданности.'),
      ('en', 'Determine the gender of the Child of Surprise.')
    ) AS v(lang, text)
    CROSS JOIN meta
  )
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Пол ребёнка'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Child Gender')
  )
, ins_cols AS (
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
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body')
     , 'single_table'
     , jsonb_build_object(
         'dice', 'd_weighed',
         'columns', (
           SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_witcher_child_who' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
           FROM (SELECT DISTINCT num FROM c_vals) AS cols
         ),
         'path', jsonb_build_array(
           ck_id('witcher_cc.hierarchy.witcher')::text,
           ck_id('witcher_cc.hierarchy.witcher_most_important_event')::text,
           ck_id('witcher_cc.hierarchy.witcher_child_who')::text
         )
       )
    FROM meta;

-- Ответы (50/50)
WITH
raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
  FROM (VALUES
    (1, 0.5, 'Мужской'),
    (2, 0.5, 'Женский')
  ) AS raw_data_ru(num, probability, txt)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
  FROM (VALUES
    (1, 0.5, 'Male'),
    (2, 0.5, 'Female')
  ) AS raw_data_en(num, probability, txt)
),

vals AS (
  SELECT
    ('<td>' || to_char(probability*100, 'FM990.00') || '%</td>'
     || '<td>' || txt || '</td>') AS text,
    num, probability, lang
  FROM raw_data
)
, meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_child_who' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, ins_lbl AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
       , meta.entity, meta.entity_field, vals.lang, vals.text
  FROM vals
  CROSS JOIN meta
)

INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
SELECT
  'wcc_witcher_child_who_o' || to_char(vals.num, 'FM00') AS an_id,
  meta.su_su_id,
  meta.qu_id,
  ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
  vals.num,
  jsonb_build_object(
           'probability', vals.probability
  )
FROM vals
CROSS JOIN meta
ON CONFLICT (an_id) DO NOTHING;

-- Создаем i18n записи для текста события (вариант 2 - женский)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_child_who' AS qu_id)
, ins_event_text AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  VALUES
    (ck_id('witcher_cc.wcc_witcher_child_who_o02.lore.most_important_event'), 'lore', 'most_important_event', 'ru', 'Во время своих путешествий вы воспользовались Правом Неожиданности и получили девочку, её судьба была в ваших руках.'),
    (ck_id('witcher_cc.wcc_witcher_child_who_o02.lore.most_important_event'), 'lore', 'most_important_event', 'en', 'During your travels, you invoked the Law of Surprise and received a girl, her fate was in your hands.')
  ON CONFLICT (id, lang) DO NOTHING
)
SELECT 1 FROM meta;

-- Эффекты: сохранение текста события в characterRaw.lore.most_important_event (для варианта 2 - женский)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_child_who' AS qu_id)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_witcher_child_who_o02',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.most_important_event'),
      jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_witcher_child_who_o02.lore.most_important_event')::text)
    )
  )
FROM meta;

-- Переход: если выбран вариант 01 «Ребёнок по Праву Неожиданности», сначала уточняем пол
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_witcher_most_important_event', 'wcc_witcher_child_who', 'wcc_witcher_most_important_event_o01', 1;