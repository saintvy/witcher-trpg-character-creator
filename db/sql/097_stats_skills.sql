\echo '097_stats_skills.sql'
-- Node: Attributes & Skills distribution (custom renderer)

-- Add hierarchy label for history
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.hierarchy.stats_skills') AS id
     , 'hierarchy' AS entity
     , 'path' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
    ('ru', 'Параметры и Навыки'),
    ('en', 'Stats and Skills')
  ) AS v(lang, text)
ON CONFLICT (id, lang) DO NOTHING;

WITH
  meta AS (
    SELECT
      'witcher_cc' AS su_su_id,
      'wcc_stats_skills' AS qu_id,
      'questions' AS entity
  ),
  ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru', 'Распределите параметры и навыки.'),
        ('en', 'Distribute attributes and skills.')
      ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
  )
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
SELECT meta.qu_id
     , meta.su_su_id
     , NULL
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body')
     , 'value_textbox'
     , jsonb_build_object(
         'path', jsonb_build_array(
           ck_id('witcher_cc.hierarchy.profession')::text,
           ck_id('witcher_cc.hierarchy.stats_skills')::text
         ),
         'renderer', 'stats_skills'
       )
  FROM meta
ON CONFLICT (qu_id) DO UPDATE
SET
  su_su_id = EXCLUDED.su_su_id,
  title = EXCLUDED.title,
  body = EXCLUDED.body,
  qtype = EXCLUDED.qtype,
  metadata = EXCLUDED.metadata;

-- Transition: after magic shop -> stats/skills node
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
SELECT 'wcc_shop_magic', 'wcc_stats_skills'
WHERE NOT EXISTS (
  SELECT 1
  FROM transitions t
  WHERE t.from_qu_qu_id = 'wcc_shop_magic'
    AND t.to_qu_qu_id = 'wcc_stats_skills'
);
