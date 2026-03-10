\echo '139_migrate_legacy_prof_branch_ids.sql'

-- Migrate legacy professional branch UUIDs stored in saved raw characters.
-- Legacy IDs were generated from RU branch names:
--   ck_id('witcher_cc.wcc_skills.branch.<ru_branch_name>.name')
-- New canonical IDs are taken from wcc_skills.branch_name_id.

WITH legacy_map AS (
  SELECT DISTINCT
    ck_id(
      'witcher_cc.wcc_skills.branch.'
      || LOWER(REPLACE(REPLACE(REPLACE(iru.text, ' ', '_'), '/', '_'), '&', 'and'))
      || '.name'
    )::text AS old_id,
    ws.branch_name_id::text AS new_id
  FROM wcc_skills ws
  JOIN i18n_text iru
    ON iru.id = ws.branch_name_id
   AND iru.lang = 'ru'
  WHERE ws.skill_type = 'professional'
    AND ws.branch_name_id IS NOT NULL
),
updated AS (
  UPDATE wcc_user_characters uc
  SET raw_character_json = jsonb_set(
    uc.raw_character_json,
    '{skills,professional,branches}',
    (
      SELECT jsonb_agg(to_jsonb(COALESCE(lm.new_id, e.value)) ORDER BY e.ord)
      FROM jsonb_array_elements_text(uc.raw_character_json #> '{skills,professional,branches}')
           WITH ORDINALITY AS e(value, ord)
      LEFT JOIN legacy_map lm
        ON lm.old_id = e.value
    ),
    true
  )
  WHERE jsonb_typeof(uc.raw_character_json #> '{skills,professional,branches}') = 'array'
    AND EXISTS (
      SELECT 1
      FROM jsonb_array_elements_text(uc.raw_character_json #> '{skills,professional,branches}') AS v(value)
      JOIN legacy_map lm
        ON lm.old_id = v.value
    )
  RETURNING id
)
SELECT COUNT(*) AS migrated_rows
FROM updated;

