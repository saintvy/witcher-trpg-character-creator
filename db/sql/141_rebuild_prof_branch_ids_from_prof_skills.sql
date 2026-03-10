\echo '141_rebuild_prof_branch_ids_from_prof_skills.sql'

-- Rebuild professional branch UUIDs in saved raw characters based on
-- canonical mapping from professional skill ids -> wcc_skills.branch_name_id.
--
-- Why this is universal:
-- - It does not rely on any legacy UUID format.
-- - It derives branch titles from actual saved professional skills.
-- - Priest vs Priest(exp_toc) is resolved by skill ids:
--   e.g. mystagogue/cult_mystery/blessings map to priest.2.exp_toc branch id.

WITH branch_skill_candidates AS (
  SELECT
    uc.id,
    branch_slot.branch_ord,
    COALESCE(
      NULLIF(uc.raw_character_json #>> ARRAY['skills', 'professional', ('skill_' || branch_slot.branch_ord::text || '_1'), 'id'], ''),
      NULLIF(uc.raw_character_json #>> ARRAY['skills', 'professional', ('skill_' || branch_slot.branch_ord::text || '_2'), 'id'], ''),
      NULLIF(uc.raw_character_json #>> ARRAY['skills', 'professional', ('skill_' || branch_slot.branch_ord::text || '_3'), 'id'], '')
    ) AS skill_id
  FROM wcc_user_characters uc
  CROSS JOIN (VALUES (1), (2), (3)) AS branch_slot(branch_ord)
  WHERE jsonb_typeof(uc.raw_character_json #> '{skills,professional}') = 'object'
),
derived_branch_ids AS (
  SELECT
    bsc.id,
    bsc.branch_ord,
    ws.branch_name_id::text AS branch_id
  FROM branch_skill_candidates bsc
  LEFT JOIN wcc_skills ws
    ON ws.skill_type = 'professional'
   AND ws.skill_id = bsc.skill_id
   AND ws.branch_name_id IS NOT NULL
),
old_branch_ids AS (
  SELECT
    uc.id,
    e.ord::int AS branch_ord,
    e.value AS branch_id
  FROM wcc_user_characters uc
  CROSS JOIN LATERAL jsonb_array_elements_text(
    CASE
      WHEN jsonb_typeof(uc.raw_character_json #> '{skills,professional,branches}') = 'array'
        THEN uc.raw_character_json #> '{skills,professional,branches}'
      ELSE '[]'::jsonb
    END
  ) WITH ORDINALITY AS e(value, ord)
  WHERE e.ord BETWEEN 1 AND 3
),
merged_slots AS (
  SELECT
    ids.id,
    slot.branch_ord,
    COALESCE(dbi.branch_id, obi.branch_id) AS branch_id,
    (dbi.branch_id IS NOT NULL) AS derived_hit
  FROM (SELECT DISTINCT id FROM wcc_user_characters) ids
  CROSS JOIN (VALUES (1), (2), (3)) AS slot(branch_ord)
  LEFT JOIN derived_branch_ids dbi
    ON dbi.id = ids.id
   AND dbi.branch_ord = slot.branch_ord
  LEFT JOIN old_branch_ids obi
    ON obi.id = ids.id
   AND obi.branch_ord = slot.branch_ord
),
prepared AS (
  SELECT
    ms.id,
    jsonb_agg(to_jsonb(ms.branch_id) ORDER BY ms.branch_ord) AS new_branches,
    bool_or(ms.derived_hit) AS has_derived
  FROM merged_slots ms
  GROUP BY ms.id
),
updated AS (
  UPDATE wcc_user_characters uc
  SET raw_character_json = jsonb_set(
    uc.raw_character_json,
    '{skills,professional,branches}',
    p.new_branches,
    true
  )
  FROM prepared p
  WHERE p.id = uc.id
    AND p.has_derived
    AND p.new_branches IS NOT NULL
    AND p.new_branches IS DISTINCT FROM (
      CASE
        WHEN jsonb_typeof(uc.raw_character_json #> '{skills,professional,branches}') = 'array'
          THEN uc.raw_character_json #> '{skills,professional,branches}'
        ELSE NULL
      END
    )
  RETURNING uc.id
)
SELECT COUNT(*) AS migrated_rows
FROM updated;
