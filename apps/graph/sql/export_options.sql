SELECT COALESCE(
  jsonb_pretty(
    jsonb_agg(
      jsonb_build_object(
        'nodeId', q.qu_id,
        'options', q.options_json
      )
      ORDER BY q.qu_id
    )
  ),
  '[]'
) AS options_json
FROM (
  SELECT
    questions.qu_id,
    COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'id', answer_options.an_id,
          'labelKey', answer_options.label,
          'sortOrder', answer_options.sort_order,
          'text', jsonb_build_object(
            'ru', COALESCE(
              (
                SELECT it.text
                FROM i18n_text AS it
                WHERE it.id = answer_options.visible_ru_ru_id
                  AND it.lang = 'ru'
                LIMIT 1
              ),
              (
                SELECT it.text
                FROM i18n_text AS it
                WHERE it.id::text = answer_options.label
                  AND it.lang = 'ru'
                LIMIT 1
              ),
              answer_options.label
            ),
            'en', COALESCE(
              (
                SELECT it.text
                FROM i18n_text AS it
                WHERE it.id::text = answer_options.label
                  AND it.lang = 'en'
                LIMIT 1
              ),
              (
                SELECT it.text
                FROM i18n_text AS it
                WHERE it.id::text = answer_options.label
                  AND it.lang = 'ru'
                LIMIT 1
              ),
              answer_options.label
            )
          )
        )
        ORDER BY answer_options.sort_order, answer_options.an_id
      ) FILTER (WHERE answer_options.an_id IS NOT NULL),
      '[]'::jsonb
    ) AS options_json
  FROM questions
  LEFT JOIN answer_options
    ON answer_options.qu_qu_id = questions.qu_id
  GROUP BY questions.qu_id
) AS q;
