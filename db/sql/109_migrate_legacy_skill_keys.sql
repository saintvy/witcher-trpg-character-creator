\echo '109_migrate_legacy_skill_keys.sql'

-- Migrate legacy skill keys to canonical ids:
--   staff -> staff_spear
--   dodge -> dodge_escape

CREATE OR REPLACE FUNCTION pg_temp.wcc_canonical_skill_id(skill_id text)
RETURNS text AS $$
BEGIN
  RETURN CASE skill_id
    WHEN 'staff' THEN 'staff_spear'
    WHEN 'dodge' THEN 'dodge_escape'
    ELSE skill_id
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION pg_temp.wcc_merge_skill_value(current_value jsonb, legacy_value jsonb)
RETURNS jsonb AS $$
BEGIN
  IF legacy_value IS NULL THEN
    RETURN current_value;
  END IF;
  IF current_value IS NULL THEN
    RETURN legacy_value;
  END IF;
  IF jsonb_typeof(current_value) = 'object' AND jsonb_typeof(legacy_value) = 'object' THEN
    RETURN current_value || legacy_value;
  END IF;
  RETURN legacy_value;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION pg_temp.wcc_normalize_skill_array(raw_value jsonb)
RETURNS jsonb AS $$
BEGIN
  IF jsonb_typeof(raw_value) <> 'array' THEN
    RETURN raw_value;
  END IF;

  RETURN COALESCE(
    (
      SELECT jsonb_agg(to_jsonb(skill_id) ORDER BY first_ord)
      FROM (
        SELECT
          pg_temp.wcc_canonical_skill_id(value) AS skill_id,
          MIN(ord) AS first_ord
        FROM jsonb_array_elements_text(raw_value) WITH ORDINALITY AS e(value, ord)
        GROUP BY pg_temp.wcc_canonical_skill_id(value)
      ) deduped
    ),
    '[]'::jsonb
  );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION pg_temp.wcc_normalize_stats_skills_payload(raw_text text)
RETURNS text AS $$
DECLARE
  payload jsonb;
  skills jsonb;
  normalized_skills jsonb;
BEGIN
  IF raw_text IS NULL OR btrim(raw_text) = '' THEN
    RETURN raw_text;
  END IF;

  BEGIN
    payload := raw_text::jsonb;
  EXCEPTION WHEN others THEN
    RETURN raw_text;
  END;

  IF jsonb_typeof(payload) <> 'object' OR jsonb_typeof(payload -> 'skills') <> 'object' THEN
    RETURN raw_text;
  END IF;

  skills := payload -> 'skills';
  normalized_skills := (skills - 'staff' - 'dodge');

  IF skills ? 'staff' OR skills ? 'staff_spear' THEN
    normalized_skills := normalized_skills || jsonb_build_object(
      'staff_spear',
      COALESCE(skills -> 'staff', skills -> 'staff_spear')
    );
  END IF;

  IF skills ? 'dodge' OR skills ? 'dodge_escape' THEN
    normalized_skills := normalized_skills || jsonb_build_object(
      'dodge_escape',
      COALESCE(skills -> 'dodge', skills -> 'dodge_escape')
    );
  END IF;

  payload := jsonb_set(payload, '{skills}', normalized_skills, true);
  RETURN payload::text;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.wcc_normalize_raw_character(raw_character jsonb)
RETURNS jsonb AS $$
DECLARE
  result jsonb := raw_character;
  common_skills jsonb;
  initial_skills jsonb;
  defining_skill jsonb;
BEGIN
  IF jsonb_typeof(raw_character) <> 'object' THEN
    RETURN raw_character;
  END IF;

  common_skills := raw_character #> '{skills,common}';
  IF jsonb_typeof(common_skills) = 'object' THEN
    common_skills := (common_skills - 'staff' - 'dodge');

    IF (raw_character #> '{skills,common}') ? 'staff' OR (raw_character #> '{skills,common}') ? 'staff_spear' THEN
      common_skills := common_skills || jsonb_build_object(
        'staff_spear',
        pg_temp.wcc_merge_skill_value(
          raw_character #> '{skills,common,staff_spear}',
          raw_character #> '{skills,common,staff}'
        )
      );
    END IF;

    IF (raw_character #> '{skills,common}') ? 'dodge' OR (raw_character #> '{skills,common}') ? 'dodge_escape' THEN
      common_skills := common_skills || jsonb_build_object(
        'dodge_escape',
        pg_temp.wcc_merge_skill_value(
          raw_character #> '{skills,common,dodge_escape}',
          raw_character #> '{skills,common,dodge}'
        )
      );
    END IF;

    result := jsonb_set(result, '{skills,common}', common_skills, true);
  END IF;

  initial_skills := raw_character #> '{skills,initial}';
  IF jsonb_typeof(initial_skills) = 'array' THEN
    result := jsonb_set(result, '{skills,initial}', pg_temp.wcc_normalize_skill_array(initial_skills), true);
  END IF;

  defining_skill := raw_character #> '{skills,defining}';
  IF jsonb_typeof(defining_skill) = 'string' THEN
    result := jsonb_set(
      result,
      '{skills,defining}',
      to_jsonb(pg_temp.wcc_canonical_skill_id(trim(both '"' FROM defining_skill::text))),
      true
    );
  ELSIF jsonb_typeof(defining_skill) = 'object' THEN
    IF defining_skill ? 'id' THEN
      result := jsonb_set(
        result,
        '{skills,defining,id}',
        to_jsonb(pg_temp.wcc_canonical_skill_id(defining_skill ->> 'id')),
        true
      );
    END IF;
    IF defining_skill ? 'skill_id' THEN
      result := jsonb_set(
        result,
        '{skills,defining,skill_id}',
        to_jsonb(pg_temp.wcc_canonical_skill_id(defining_skill ->> 'skill_id')),
        true
      );
    END IF;
  END IF;

  RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION pg_temp.wcc_normalize_answers_export(raw_answers jsonb)
RETURNS jsonb AS $$
DECLARE
  normalized_answers jsonb;
BEGIN
  IF jsonb_typeof(raw_answers) <> 'object' OR jsonb_typeof(raw_answers -> 'answers') <> 'array' THEN
    RETURN raw_answers;
  END IF;

  SELECT COALESCE(
    jsonb_agg(
      CASE
        WHEN answer ->> 'questionId' = 'wcc_stats_skills'
          AND jsonb_typeof(answer -> 'value') = 'object'
          AND (answer -> 'value') ? 'data'
        THEN jsonb_set(
          answer,
          '{value,data}',
          to_jsonb(pg_temp.wcc_normalize_stats_skills_payload(answer -> 'value' ->> 'data')),
          true
        )
        ELSE answer
      END
      ORDER BY ord
    ),
    '[]'::jsonb
  )
  INTO normalized_answers
  FROM jsonb_array_elements(raw_answers -> 'answers') WITH ORDINALITY AS e(answer, ord);

  RETURN jsonb_set(raw_answers, '{answers}', normalized_answers, true);
END;
$$ LANGUAGE plpgsql;

WITH normalized AS (
  SELECT
    id,
    pg_temp.wcc_normalize_raw_character(raw_character_json) AS raw_character_json,
    pg_temp.wcc_normalize_answers_export(answers_export_json) AS answers_export_json
  FROM wcc_user_characters
),
updated AS (
  UPDATE wcc_user_characters uc
  SET raw_character_json = n.raw_character_json,
      answers_export_json = n.answers_export_json,
      updated_at = NOW()
  FROM normalized n
  WHERE uc.id = n.id
    AND (
      uc.raw_character_json IS DISTINCT FROM n.raw_character_json
      OR uc.answers_export_json IS DISTINCT FROM n.answers_export_json
    )
  RETURNING uc.id
)
SELECT COUNT(*) AS migrated_rows
FROM updated;

DROP FUNCTION IF EXISTS pg_temp.wcc_normalize_answers_export(jsonb);
DROP FUNCTION IF EXISTS pg_temp.wcc_normalize_raw_character(jsonb);
DROP FUNCTION IF EXISTS pg_temp.wcc_normalize_stats_skills_payload(text);
DROP FUNCTION IF EXISTS pg_temp.wcc_normalize_skill_array(jsonb);
DROP FUNCTION IF EXISTS pg_temp.wcc_merge_skill_value(jsonb, jsonb);
DROP FUNCTION IF EXISTS pg_temp.wcc_canonical_skill_id(text);
