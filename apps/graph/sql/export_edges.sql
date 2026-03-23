SELECT COALESCE(
  jsonb_pretty(
    jsonb_agg(
      jsonb_build_object(
        'id', t.tr_id,
        'from', t.from_qu_qu_id,
        'to', t.to_qu_qu_id,
        'viaOptionId', t.via_an_an_id,
        'hasOption', (t.via_an_an_id IS NOT NULL),
        'hasRule', (t.ru_ru_id IS NOT NULL),
        'priority', t.priority
      )
      ORDER BY t.from_qu_qu_id, t.to_qu_qu_id, t.priority DESC, t.tr_id
    )
  ),
  '[]'
) AS edges_json
FROM transitions AS t;
