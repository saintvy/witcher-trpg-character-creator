\echo '039_life_events_ally_position.sql'

-- Узел: 
-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_ally_position' AS qu_id
                , 'questions' AS entity)
, c_vals(lang, num, text) AS (VALUES ('ru', 1, 'Шанс'),
                                     ('ru', 2, 'Кто ваш союзник'),
                                     ('en', 1, 'Chance'),
                                     ('en', 2, 'Position'))
, ins_c AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| 'column_name') AS id
                       , meta.entity, 'column_name', c_vals.lang, c_vals.text
				    FROM c_vals
					CROSS JOIN meta)
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
  SELECT meta.qu_id
       , meta.su_su_id
       , NULL
       , NULL
       , 'single_table'
       , jsonb_build_object(
           'dice','d_weighed',
           'columns', (
             SELECT jsonb_agg(
                      ck_id('witcher_cc' ||'.'|| 'wcc_life_events_ally_position' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text
                      ORDER BY num
                    )
               FROM (SELECT DISTINCT num FROM c_vals) AS cols
           ),
           'path', jsonb_build_array(
             ck_id('witcher_cc.hierarchy.life_events')::text,
             jsonb_build_object('jsonlogic_expression', jsonb_build_object('cat', jsonb_build_array(
              jsonb_build_object('var', 'counters.lifeEventsCounter'),
              '-',
              jsonb_build_object('+', jsonb_build_array(
                jsonb_build_object('var', 'counters.lifeEventsCounter'),
                10
              ))
            ))),
             ck_id('witcher_cc.hierarchy.life_events_ally')::text,
             ck_id('witcher_cc.hierarchy.life_events_ally_position')::text
           )
         )
    FROM meta;

-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_ally_position' AS qu_id
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
                  ('ru', 1, 'Охотник за головами', 0.1::numeric),
                  ('ru', 2, 'Маг', 0.1),
                  ('ru', 3, 'Наставник или учитель', 0.1),
                  ('ru', 4, 'Друг детства', 0.1),
                  ('ru', 5, 'Ремесленник', 0.1),
                  ('ru', 6, 'Бывший враг', 0.1),
                  ('ru', 7, 'Князь/княгиня', 0.1),
                  ('ru', 8, 'Жрец/жрица', 0.1),
                  ('ru', 9, 'Солдат', 0.1),
                  ('ru', 10, 'Бард', 0.1),
                  ('en', 1, 'A Bounty Hunter', 0.1),
                  ('en', 2, 'A Mage', 0.1),
                  ('en', 3, 'A Mentor or Teacher', 0.1),
                  ('en', 4, 'A Childhood Friend', 0.1),
                  ('en', 5, 'A Craftsman', 0.1),
                  ('en', 6, 'An Old Enemy', 0.1),
                  ('en', 7, 'A Duke/Duchess', 0.1),
                  ('en', 8, 'A Priest/Priestess', 0.1),
                  ('en', 9, 'A Soldier', 0.1),
                  ('en', 10, 'A Bard', 0.1)
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
  SELECT 'wcc_life_events_ally_position_o' || to_char(vals.num, 'FM9900') AS an_id,
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
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_life_events_ally_gender', 'wcc_life_events_ally_position';