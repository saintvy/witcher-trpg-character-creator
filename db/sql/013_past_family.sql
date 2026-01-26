\echo '013_past_family.sql'
-- Узел: Семья

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_family' AS qu_id
                , 'questions' AS entity
                , 'single'::question_type AS qtype)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| v.entity_field) AS id
           , meta.entity, v.entity_field, v.lang, v.text
        FROM (VALUES
                ('ru', 'Нужно определить всё ли в порядке с семьей.', 'body'),
                ('en', 'Determine whether your family is all right.', 'body')
             ) AS v(lang, text, entity_field)
        CROSS JOIN meta
      RETURNING id AS body_id
)
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
  SELECT meta.qu_id
       , meta.su_su_id
       , NULL
       , (SELECT DISTINCT body_id FROM ins_body)
       , meta.qtype
       , jsonb_build_object(
           'dice', 'd0',
           'path', jsonb_build_array(
             ck_id('witcher_cc.hierarchy.family')::text,
             ck_id('witcher_cc.hierarchy.family_threat')::text
           )
         )
     FROM meta;
	   
-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_family' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
  SELECT v.*
  FROM (VALUES ('ru', 1, 'С семьей ничего особенного не произошло... А что насчет только родителей?'),
               ('ru', 2, 'С семьей что-то случилось.'),
               ('en', 1, 'Nothing special has happened to your family... But what about your parents?'),
               ('en', 2, 'Something happened to your family')
         ) AS v(lang, num, text)
)
, ins_label AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
           , meta.entity, meta.entity_field, vals.lang, vals.text
        FROM vals
        CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
  SELECT 'wcc_past_family_o' || to_char(vals.num, 'FM9900') AS an_id,
         meta.su_su_id,
         meta.qu_id,
         ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
         vals.num AS sort_order,
         '{}'::jsonb AS metadata
    FROM vals
    CROSS JOIN meta
  ON CONFLICT (an_id) DO NOTHING;
  
-- Связи
-- INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id)
--   SELECT 'wcc_past_elf_q1', 'wcc_past_family', 'wcc_past_elf_q1_o01' UNION ALL
--   SELECT 'wcc_past_dwarf_q1', 'wcc_past_family', 'wcc_past_dwarf_q1_o01';

-- INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
--   SELECT 'wcc_past_homeland_human', 'wcc_past_family' UNION ALL
--   SELECT 'wcc_past_homeland_elders', 'wcc_past_family';
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_ch_age', 'wcc_past_family';