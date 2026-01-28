\echo '050_witcher_when.sql'
-- Узел: Повлиявший друг

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_when' AS qu_id
                , 'questions' AS entity)
, ins_body AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
                       , meta.entity, 'body', v.lang, v.text
                    FROM (VALUES
                            ('ru', 'Когда вы стали ведьмаком?'),
                            ('en', 'When did you become a witcher?')) AS v(lang, text)
                    CROSS JOIN meta)
, c_vals(lang, num, text) AS (VALUES ('ru', 1, 'Шанс'),
                                     ('ru', 2, 'Эффект'),
                                     ('ru', 3, 'Возраст'),
                                     ('en', 1, 'Chance'),
                                     ('en', 2, 'Effect'),
                                     ('en', 3, 'Age'))
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
             SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_witcher_when' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
             FROM (SELECT DISTINCT num FROM c_vals) AS cols
           ),
           'path', jsonb_build_array(
             ck_id('witcher_cc.hierarchy.witcher')::text,
             ck_id('witcher_cc.hierarchy.witcher_when')::text
           )
         )
    FROM meta;


-- Ответы
WITH
raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
            ( 1, 0.2, '-2 к Испытанию травами', '<b>Младенчество</b><br>Вас забрали в ведьмачью школу ещё младенцем, в возрасте от 1 до 2 лет. Вы не помните о жизни до ведьмачества, и вам не о чем вспоминать, когда приходит время Испытания травами.'),
            ( 2, 0.6, 'Нет эффекта', '<b>Раннее детство</b><br>Вас забрали в ведьмачью школу в возрасте от 4 до 6 лет. У вас есть воспоминания о нормальной жизни, что помогло при Испытании травами.'),
            ( 3, 0.2, '+2 к Испытанию травами', '<b>Позднее детство</b><br>Вас забрали в ведьмачью школу довольно большим, в возрасте от 8 до 11 лет. Тренироваться вам было несколько труднее, зато воспоминания о нормальной жизни помогли при прохождении Испытания травами.')
         ) AS raw_data_ru(num, probability, effect, txt)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
            ( 1, 0.2, '-2 to the Trial of the Grasses', '<b>Infancy</b><br>You were taken to become a witcher when you were a toddler, between 1 and 2 years old. You have no memories of life before becoming a witcher and had nothing to cling to when taking the Trial of the Grasses.' ),
            ( 2, 0.6, 'No Modifiers', '<b>Early Childhood</b><br>You were taken to become a witcher when you were young, between 4 and 6 years old. You had some normal memories to aid you when taking the Trial of the Grasses.' ),
            ( 3, 0.2, '+2 to the Trial of the Grasses', '<b>Late Childhood</b><br>You were taken to become a witcher when you were relatively old, between 8 and 11 years old. While training was somewhat harder, your many memories bolstered you when you took the Trial of the Grasses.' )
         ) AS raw_data_en(num, probability, effect, txt)

),
vals AS (
         SELECT ('<td>' || to_char(probability*100, 'FM990.00') || '%</td>' ||
                 '<td>' || effect || '</td>' ||
                 '<td>' || txt || '</td>') AS text,
                num,
                probability,
                lang,
                -- Извлекаем текст после <br>
                CASE 
                  WHEN position('<br>' in txt) > 0 
                  THEN substring(txt from position('<br>' in txt) + 4)
                  ELSE ''
                END AS text_after_br
         FROM raw_data
)
, meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_when' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, ins_label AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
                     , meta.entity, meta.entity_field, vals.lang, vals.text
                  FROM vals
                  CROSS JOIN meta
)
, ins_text_after_br AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| 'description') AS id
                     , meta.entity, 'description', vals.lang, vals.text_after_br
                  FROM vals
                  CROSS JOIN meta
                  WHERE vals.text_after_br != ''
                ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
SELECT 'wcc_witcher_when_o' || to_char(vals.num, 'FM00') AS an_id,
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

-- Эффекты: сохранение модификатора для Испытания травами в values.byQuestion
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_when' AS qu_id)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_witcher_when_o01',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'values.byQuestion.wcc_witcher_when'),
      -0.2
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_when_o02',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'values.byQuestion.wcc_witcher_when'),
      0.0
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_when_o03',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'values.byQuestion.wcc_witcher_when'),
      0.2
    )
  )
FROM meta;

-- Эффекты: сохранение текста после <br> в characterRaw.lore.witcher_initiation_moment
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_when' AS qu_id
                , 'answer_options' AS entity)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_witcher_when_o01',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.witcher_initiation_moment'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o01.'|| meta.entity ||'.description')::text)
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_when_o02',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.witcher_initiation_moment'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o02.'|| meta.entity ||'.description')::text)
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_when_o03',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.witcher_initiation_moment'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o03.'|| meta.entity ||'.description')::text)
    )
  )
FROM meta;


-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_witcher_graduation_age', 'wcc_witcher_when';