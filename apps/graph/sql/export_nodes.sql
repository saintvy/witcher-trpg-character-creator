SELECT COALESCE(
  jsonb_pretty(
    jsonb_agg(
      jsonb_build_object(
        'id', q.qu_id,
        'type', q.qtype,
        'isEntry', NOT EXISTS (
          SELECT 1
          FROM transitions AS t_in
          WHERE t_in.to_qu_qu_id = q.qu_id
        ),
        'title', jsonb_build_object(
          'ru', (
            SELECT it.text
            FROM i18n_text AS it
            WHERE it.id = q.title
              AND it.lang = 'ru'
            LIMIT 1
          ),
          'en', (
            SELECT it.text
            FROM i18n_text AS it
            WHERE it.id = q.title
              AND it.lang = 'en'
            LIMIT 1
          )
        ),
        'body', jsonb_build_object(
          'ru', (
            SELECT it.text
            FROM i18n_text AS it
            WHERE it.id = q.body
              AND it.lang = 'ru'
            LIMIT 1
          ),
          'en', (
            SELECT it.text
            FROM i18n_text AS it
            WHERE it.id = q.body
              AND it.lang = 'en'
            LIMIT 1
          )
        )
      )
      ORDER BY q.qu_id
    )
  ),
  '[]'
) AS nodes_json
FROM questions AS q;
