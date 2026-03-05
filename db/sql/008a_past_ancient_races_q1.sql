\echo '008a_past_ancient_races_q1.sql'
-- Узел: Выбор направления родины для древнейших рас (гном, вран, баболак)

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_ancient_races_q1' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
           , meta.entity, 'body', v.lang, v.text
        FROM (VALUES
                ('ru', 'Вы выбрали одну из древнейших рас на континенте. Правила не уточняют явно где именно живут её представители, поэтому вы можете сами выбрать родину персонажа. Но имейте в виду, что представители вашего народа исторически подавлялись людьми, поэтому они тяготеют к землям старших народов, особенно Махакаму.'),
                ('en', 'You have chosen one of the oldest races on the Continent. The rules do not clearly define where exactly its people live, so you may choose your character''s homeland yourself. Keep in mind that your folk were historically oppressed by humans, so they tend to gravitate toward elderfolk lands, especially Mahakam.')
             ) AS v(lang, text)
        CROSS JOIN meta
)
, c_vals(lang, num, text) AS (VALUES
    ('ru', 1, 'Шанс'),
    ('ru', 2, 'Вариант'),
    ('en', 1, 'Chance'),
    ('en', 2, 'Option')
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
       , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body')
       , 'single_table'
       , jsonb_build_object(
           'dice', 'd_weighed',
           'columns', (
             SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_past_ancient_races_q1' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
             FROM (SELECT DISTINCT num FROM c_vals) AS cols
           ),
           'path', jsonb_build_array(
             ck_id('witcher_cc.hierarchy.identity')::text,
             ck_id('witcher_cc.hierarchy.homeland_nonhuman')::text
           )
         )
    FROM meta;

-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_ancient_races_q1' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
    SELECT
      ('<td>' || to_char(probability*100, 'FM990.00') || '%</td>' ||
       '<td>' || option_text || '</td>') AS text,
      num,
      probability,
      lang
    FROM (VALUES
      ('ru', 1, 'Я хочу выбрать что-то из земель старших народов.', 0.75::numeric),
      ('ru', 2, 'Я хочу выбрать что-то из людских поселений.', 0.25::numeric),
      ('en', 1, 'I want to choose something from the lands of the elder peoples.', 0.75::numeric),
      ('en', 2, 'I want to choose something from human settlements.', 0.25::numeric)
    ) AS v(lang, num, option_text, probability)
)
, ins_label AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
           , meta.entity, meta.entity_field, vals.lang, vals.text
        FROM vals
        CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
  SELECT 'wcc_past_ancient_races_q1_o' || to_char(vals.num, 'FM9900') AS an_id
       , meta.su_su_id
       , meta.qu_id
       , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label
       , vals.num AS sort_order
       , jsonb_build_object('probability', vals.probability) AS metadata
    FROM vals
    CROSS JOIN meta
  ON CONFLICT (an_id) DO NOTHING;

-- Правило для рас: is_gnome OR is_vran OR is_werebbubb OR is_halfling
WITH
  rule_parts AS (
    SELECT
      (SELECT r.body FROM rules r WHERE r.name = 'is_gnome' ORDER BY r.ru_id LIMIT 1) AS is_gnome_expr,
      (SELECT r.body FROM rules r WHERE r.name = 'is_vran' ORDER BY r.ru_id LIMIT 1) AS is_vran_expr,
      (SELECT r.body FROM rules r WHERE r.name = 'is_werebbubb' ORDER BY r.ru_id LIMIT 1) AS is_werebbubb_expr,
      (SELECT r.body FROM rules r WHERE r.name = 'is_halfling' ORDER BY r.ru_id LIMIT 1) AS is_halfling
  )
INSERT INTO rules (ru_id, name, body)
SELECT
  ck_id('witcher_cc.rules.is_ancient_nonhuman') AS ru_id,
  'is_ancient_nonhuman' AS name,
  jsonb_build_object(
    'or',
    jsonb_build_array(
      rule_parts.is_gnome_expr,
      rule_parts.is_vran_expr,
      rule_parts.is_werebbubb_expr,
      rule_parts.is_halfling
    )
  ) AS body
FROM rule_parts
ON CONFLICT (ru_id) DO NOTHING;

-- Связи
-- Переход из профессии для древнейших рас
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_profession', 'wcc_past_ancient_races_q1', r.ru_id, 1
    FROM (SELECT ru_id FROM rules WHERE name = 'is_ancient_nonhuman' ORDER BY ru_id LIMIT 1) r;

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_man_at_arms_combat_skills', 'wcc_past_ancient_races_q1', r.ru_id, 1
    FROM (SELECT ru_id FROM rules WHERE name = 'is_ancient_nonhuman') r;