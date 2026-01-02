\echo '034_life_events_enemy_cause.sql'

-- Узел: 
-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_enemy_cause' AS qu_id
                , 'questions' AS entity)
, c_vals(lang, num, text) AS (VALUES ('ru', 1, 'Шанс'),
                                     ('ru', 2, 'Причина вражды'),
                                     ('en', 1, 'Chance'),
                                     ('en', 2, 'The cause'))
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
                      ck_id('witcher_cc' ||'.'|| 'wcc_life_events_enemy_cause' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text
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
             ck_id('witcher_cc.hierarchy.life_events_enemy')::text,
             ck_id('witcher_cc.hierarchy.life_events_enemy_cause')::text
           )
         )
    FROM meta;

-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_enemy_cause' AS qu_id
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
                  ('ru', 1, 'Нападение', 0.1::numeric),
                  ('ru', 2, 'Потеря возлюбленного', 0.1),
                  ('ru', 3, 'Серьёзное унижение', 0.1),
                  ('ru', 4, 'Проклятие', 0.1),
                  ('ru', 5, 'Обвинение в нелегальном колдовстве', 0.1),
                  ('ru', 6, 'Отказ в романтических притязаниях', 0.1),
                  ('ru', 7, 'Нанесение серьёзной раны', 0.1),
                  ('ru', 8, 'Шантаж', 0.1),
                  ('ru', 9, 'Сорванные планы', 0.1),
                  ('ru', 10, 'Провокация нападения чудовищ', 0.1),
                  ('en', 1, 'Assaulted the Offended Party', 0.1),
                  ('en', 2, 'Caused the Loss of a Loved One', 0.1),
                  ('en', 3, 'Caused Major Humiliation', 0.1),
                  ('en', 4, 'Caused a Curse', 0.1),
                  ('en', 5, 'Accused of Illegal Witchcraft', 0.1),
                  ('en', 6, 'Turned Down Romantically', 0.1),
                  ('en', 7, 'Caused a Terrible Wound', 0.1),
                  ('en', 8, 'Blackmail', 0.1),
                  ('en', 9, 'Foiled Plans', 0.1),
                  ('en', 10, 'Caused a Monster Attack', 0.1)
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
  SELECT 'wcc_life_events_enemy_cause_o' || to_char(vals.num, 'FM9900') AS an_id,
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
  SELECT 'wcc_life_events_enemy_position', 'wcc_life_events_enemy_cause';