\echo '034_past_academy_life_details.sql'

-- Hierarchy key
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.hierarchy.academy_life_details'), 'hierarchy', 'path', 'ru', 'Уточнение'),
  (ck_id('witcher_cc.hierarchy.academy_life_details'), 'hierarchy', 'path', 'en', 'Detail')
ON CONFLICT (id, lang) DO NOTHING;

-- Visibility rules by selected option in academy life node
INSERT INTO rules (ru_id, name, body)
VALUES
  (
    ck_id('witcher_cc.rules.is_academy_life_details_from_curse'),
    'is_academy_life_details_from_curse',
    '{
      "and": [
        { "==": [ { "var": "answers.lastAnswer.questionId" }, "wcc_past_academy_life" ] },
        {
          "or": [
            { "in": [ "wcc_past_academy_life_o0110", { "var": "answers.lastAnswer.answerIds" } ] },
            { "in": [ "wcc_past_academy_life_o0208", { "var": "answers.lastAnswer.answerIds" } ] },
            { "in": [ "wcc_past_academy_life_o0407", { "var": "answers.lastAnswer.answerIds" } ] }
          ]
        }
      ]
    }'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_academy_life_details_from_o0207'),
    'is_academy_life_details_from_o0207',
    '{
      "and": [
        { "==": [ { "var": "answers.lastAnswer.questionId" }, "wcc_past_academy_life" ] },
        { "in": [ "wcc_past_academy_life_o0207", { "var": "answers.lastAnswer.answerIds" } ] }
      ]
    }'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_academy_life_details_from_o0307'),
    'is_academy_life_details_from_o0307',
    '{
      "and": [
        { "==": [ { "var": "answers.lastAnswer.questionId" }, "wcc_past_academy_life" ] },
        { "in": [ "wcc_past_academy_life_o0307", { "var": "answers.lastAnswer.answerIds" } ] }
      ]
    }'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_academy_life_details_from_o0406'),
    'is_academy_life_details_from_o0406',
    '{
      "and": [
        { "==": [ { "var": "answers.lastAnswer.questionId" }, "wcc_past_academy_life" ] },
        { "in": [ "wcc_past_academy_life_o0406", { "var": "answers.lastAnswer.answerIds" } ] }
      ]
    }'::jsonb
  )
ON CONFLICT (ru_id) DO UPDATE
SET name = EXCLUDED.name,
    body = EXCLUDED.body;

-- Visibility rules for o0307 details by combat skill state
WITH skills AS (
  SELECT *
    FROM (VALUES
      ('tactics', 'tactics'),
      ('archery', 'archery'),
      ('athletics', 'athletics'),
      ('crossbow', 'crossbow'),
      ('small_blades', 'small_blades'),
      ('staff', 'staff'),
      ('swordsmanship', 'swordsmanship'),
      ('melee', 'melee'),
      ('brawling', 'brawling'),
      ('riding', 'riding')
    ) AS v(skill_key, skill_path)
)
INSERT INTO rules (ru_id, name, body)
SELECT
  ck_id('witcher_cc.rules.is_academy_life_details_from_o0307_' || skills.skill_key || '_new'),
  'is_academy_life_details_from_o0307_' || skills.skill_key || '_new',
  jsonb_build_object(
    'and',
    jsonb_build_array(
      jsonb_build_object('==', jsonb_build_array(jsonb_build_object('var', 'answers.lastAnswer.questionId'), 'wcc_past_academy_life')),
      jsonb_build_object('in', jsonb_build_array('wcc_past_academy_life_o0307', jsonb_build_object('var', 'answers.lastAnswer.answerIds'))),
      jsonb_build_object(
        '==',
        jsonb_build_array(
          jsonb_build_object('var', jsonb_build_array('characterRaw.skills.common.' || skills.skill_path || '.cur', 0)),
          0
        )
      )
    )
  )
FROM skills
UNION ALL
SELECT
  ck_id('witcher_cc.rules.is_academy_life_details_from_o0307_' || skills.skill_key || '_existing'),
  'is_academy_life_details_from_o0307_' || skills.skill_key || '_existing',
  jsonb_build_object(
    'and',
    jsonb_build_array(
      jsonb_build_object('==', jsonb_build_array(jsonb_build_object('var', 'answers.lastAnswer.questionId'), 'wcc_past_academy_life')),
      jsonb_build_object('in', jsonb_build_array('wcc_past_academy_life_o0307', jsonb_build_object('var', 'answers.lastAnswer.answerIds'))),
      jsonb_build_object(
        '>',
        jsonb_build_array(
          jsonb_build_object('var', jsonb_build_array('characterRaw.skills.common.' || skills.skill_path || '.cur', 0)),
          0
        )
      )
    )
  )
FROM skills
ON CONFLICT (ru_id) DO UPDATE
SET name = EXCLUDED.name,
    body = EXCLUDED.body;

-- Question
WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_past_academy_life_details' AS qu_id
         , 'questions' AS entity
  )
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru', 'Уточните последствия выбранного события из жизни в академии.'),
        ('en', 'Specify the details of the selected academy-life outcome.')
      ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
)
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Уточнение'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Detail')
)
, ins_cols AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.column_name') AS id
         , meta.entity, 'column_name', c_vals.lang, c_vals.text
      FROM c_vals
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
SELECT meta.qu_id
     , meta.su_su_id
     , NULL
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body')
     , 'single_table'
     , jsonb_build_object(
         'dice', 'd_weighed',
         'columns', (
           SELECT jsonb_agg(ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(num, 'FM9900') ||'.'|| meta.entity ||'.column_name')::text ORDER BY num)
           FROM (SELECT DISTINCT num FROM c_vals) cols
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
           ck_id('witcher_cc.hierarchy.academy_life')::text,
           ck_id('witcher_cc.hierarchy.academy_life_details')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO NOTHING;

-- Answer options
WITH
  raw_data AS (
    SELECT 'ru' AS lang, v.*
      FROM (VALUES
        -- Group 1: details for o0110/o0208/o0407
        ('wcc_past_academy_life_o011001', 1, 0.2::numeric, '<b>Проклятие чудовищности</b> (Интенсивность: Средняя)', 'is_academy_life_details_from_curse'),
        ('wcc_past_academy_life_o011002', 2, 0.2::numeric, '<b>Проклятие призраков</b> (Интенсивность: Средняя)', 'is_academy_life_details_from_curse'),
        ('wcc_past_academy_life_o011003', 3, 0.2::numeric, '<b>Проклятие заразы</b> (Интенсивность: Высокая)', 'is_academy_life_details_from_curse'),
        ('wcc_past_academy_life_o011004', 4, 0.2::numeric, '<b>Проклятие странника</b> (Интенсивность: Высокая)', 'is_academy_life_details_from_curse'),
        ('wcc_past_academy_life_o011005', 5, 0.2::numeric, '<b>Проклятие ликантропии</b> (Интенсивность: Высокая)', 'is_academy_life_details_from_curse'),
        ('wcc_past_academy_life_o011006', 6, 0.0::numeric, '<b>Другое проклятие</b> (кастомное)', 'is_academy_life_details_from_curse'),

        -- Group 2: details for o0207
        ('wcc_past_academy_life_o020701', 1, 0.1666666667::numeric, 'Сражаясь за мелкого дворянина, вы получили 100 крон после того как отдали часть дохода в Академию.', 'is_academy_life_details_from_o0207'),
        ('wcc_past_academy_life_o020702', 2, 0.1666666667::numeric, 'Сражаясь за мелкого дворянина, вы получили 200 крон после того как отдали часть дохода в Академию.', 'is_academy_life_details_from_o0207'),
        ('wcc_past_academy_life_o020703', 3, 0.1666666667::numeric, 'Сражаясь за мелкого дворянина, вы получили 300 крон после того как отдали часть дохода в Академию.', 'is_academy_life_details_from_o0207'),
        ('wcc_past_academy_life_o020704', 4, 0.1666666667::numeric, 'Сражаясь за мелкого дворянина, вы получили 400 крон после того как отдали часть дохода в Академию.', 'is_academy_life_details_from_o0207'),
        ('wcc_past_academy_life_o020705', 5, 0.1666666667::numeric, 'Сражаясь за мелкого дворянина, вы получили 500 крон после того как отдали часть дохода в Академию.', 'is_academy_life_details_from_o0207'),
        ('wcc_past_academy_life_o020706', 6, 0.1666666667::numeric, 'Сражаясь за мелкого дворянина, вы получили 600 крон после того как отдали часть дохода в Академию.', 'is_academy_life_details_from_o0207'),

        -- Group 3: details for o0307
        ('wcc_past_academy_life_o030701', 1, 1.0::numeric, 'Помощь охотникам на магов: +2 к новому навыку Тактика', 'is_academy_life_details_from_o0307_tactics_new'),
        ('wcc_past_academy_life_o030702', 2, 1.0::numeric, 'Помощь охотникам на магов: +1 к имеющемуся навыку Тактика', 'is_academy_life_details_from_o0307_tactics_existing'),
        ('wcc_past_academy_life_o030703', 3, 1.0::numeric, 'Помощь охотникам на магов: +2 к новому навыку Стрельба из лука', 'is_academy_life_details_from_o0307_archery_new'),
        ('wcc_past_academy_life_o030704', 4, 1.0::numeric, 'Помощь охотникам на магов: +1 к имеющемуся навыку Стрельба из лука', 'is_academy_life_details_from_o0307_archery_existing'),
        ('wcc_past_academy_life_o030705', 5, 1.0::numeric, 'Помощь охотникам на магов: +2 к новому навыку Атлетика', 'is_academy_life_details_from_o0307_athletics_new'),
        ('wcc_past_academy_life_o030706', 6, 1.0::numeric, 'Помощь охотникам на магов: +1 к имеющемуся навыку Атлетика', 'is_academy_life_details_from_o0307_athletics_existing'),
        ('wcc_past_academy_life_o030707', 7, 1.0::numeric, 'Помощь охотникам на магов: +2 к новому навыку Стрельба из арбалета', 'is_academy_life_details_from_o0307_crossbow_new'),
        ('wcc_past_academy_life_o030708', 8, 1.0::numeric, 'Помощь охотникам на магов: +1 к имеющемуся навыку Стрельба из арбалета', 'is_academy_life_details_from_o0307_crossbow_existing'),
        ('wcc_past_academy_life_o030709', 9, 1.0::numeric, 'Помощь охотникам на магов: +2 к новому навыку Владение легкими клинками', 'is_academy_life_details_from_o0307_small_blades_new'),
        ('wcc_past_academy_life_o030710', 10, 1.0::numeric, 'Помощь охотникам на магов: +1 к имеющемуся навыку Владение легкими клинками', 'is_academy_life_details_from_o0307_small_blades_existing'),
        ('wcc_past_academy_life_o030711', 11, 1.0::numeric, 'Помощь охотникам на магов: +2 к новому навыку Владение древковым оружием', 'is_academy_life_details_from_o0307_staff_new'),
        ('wcc_past_academy_life_o030712', 12, 1.0::numeric, 'Помощь охотникам на магов: +1 к имеющемуся навыку Владение древковым оружием', 'is_academy_life_details_from_o0307_staff_existing'),
        ('wcc_past_academy_life_o030713', 13, 1.0::numeric, 'Помощь охотникам на магов: +2 к новому навыку Владение мечом', 'is_academy_life_details_from_o0307_swordsmanship_new'),
        ('wcc_past_academy_life_o030714', 14, 1.0::numeric, 'Помощь охотникам на магов: +1 к имеющемуся навыку Владение мечом', 'is_academy_life_details_from_o0307_swordsmanship_existing'),
        ('wcc_past_academy_life_o030715', 15, 1.0::numeric, 'Помощь охотникам на магов: +2 к новому навыку Ближний бой', 'is_academy_life_details_from_o0307_melee_new'),
        ('wcc_past_academy_life_o030716', 16, 1.0::numeric, 'Помощь охотникам на магов: +1 к имеющемуся навыку Ближний бой', 'is_academy_life_details_from_o0307_melee_existing'),
        ('wcc_past_academy_life_o030717', 17, 1.0::numeric, 'Помощь охотникам на магов: +2 к новому навыку Борьба', 'is_academy_life_details_from_o0307_brawling_new'),
        ('wcc_past_academy_life_o030718', 18, 1.0::numeric, 'Помощь охотникам на магов: +1 к имеющемуся навыку Борьба', 'is_academy_life_details_from_o0307_brawling_existing'),
        ('wcc_past_academy_life_o030719', 19, 1.0::numeric, 'Помощь охотникам на магов: +2 к новому навыку Верховая езда', 'is_academy_life_details_from_o0307_riding_new'),
        ('wcc_past_academy_life_o030720', 20, 1.0::numeric, 'Помощь охотникам на магов: +1 к имеющемуся навыку Верховая езда', 'is_academy_life_details_from_o0307_riding_existing'),

        -- Group 4: details for o0406
        ('wcc_past_academy_life_o040601', 1,  0.043::numeric, 'Социальный статус "Равенство" в регионе, благодаря помощи жителям (Северные королевства) Редании.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040602', 2,  0.043::numeric, 'Социальный статус "Равенство" в регионе, благодаря помощи жителям (Северные королевства) Каэдвена.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040603', 3,  0.043::numeric, 'Социальный статус "Равенство" в регионе, благодаря помощи жителям (Северные королевства) Темерии.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040604', 4,  0.043::numeric, 'Социальный статус "Равенство" в регионе, благодаря помощи жителям (Северные королевства) Аэдирна.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040605', 5,  0.043::numeric, 'Социальный статус "Равенство" в регионе, благодаря помощи жителям (Северные королевства) Лирии и Ривии.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040606', 6,  0.043::numeric, 'Социальный статус "Равенство" в регионе, благодаря помощи жителям (Северные королевства) Ковира и Повисса.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040607', 7,  0.043::numeric, 'Социальный статус "Равенство" в регионе, благодаря помощи жителям (Северные королевства) Скеллиге.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040608', 8,  0.043::numeric, 'Социальный статус "Равенство" в регионе, благодаря помощи жителям (Северные королевства) Цидариса.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040609', 9,  0.043::numeric, 'Социальный статус "Равенство" в регионе, благодаря помощи жителям (Северные королевства) Вердэна.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040610', 10, 0.043::numeric, 'Социальный статус "Равенство" в регионе, благодаря помощи жителям (Северные королевства) Цинтры.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040611', 11, 0.043::numeric, 'Социальный статус "Равенство" в регионе, благодаря помощи жителям (Нильфгаард) Сердца Нильфгаарда.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040612', 12, 0.043::numeric, 'Социальный статус "Равенство" в регионе, благодаря помощи жителям (Нильфгаард) Виковаро.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040613', 13, 0.043::numeric, 'Социальный статус "Равенство" в регионе, благодаря помощи жителям (Нильфгаард) Аигрена.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040614', 14, 0.043::numeric, 'Социальный статус "Равенство" в регионе, благодаря помощи жителям (Нильфгаард) Назаира.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040615', 15, 0.043::numeric, 'Социальный статус "Равенство" в регионе, благодаря помощи жителям (Нильфгаард) Метиины.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040616', 16, 0.043::numeric, 'Социальный статус "Равенство" в регионе, благодаря помощи жителям (Нильфгаард) Маг Турги.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040617', 17, 0.043::numeric, 'Социальный статус "Равенство" в регионе, благодаря помощи жителям (Нильфгаард) Гесо.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040618', 18, 0.043::numeric, 'Социальный статус "Равенство" в регионе, благодаря помощи жителям (Нильфгаард) Эббинга.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040619', 19, 0.043::numeric, 'Социальный статус "Равенство" в регионе, благодаря помощи жителям (Нильфгаард) Мехта.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040620', 20, 0.043::numeric, 'Социальный статус "Равенство" в регионе, благодаря помощи жителям (Нильфгаард) Геммеры.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040621', 21, 0.043::numeric, 'Социальный статус "Равенство" в регионе, благодаря помощи жителям (Нильфгаард) Этолии.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040622', 22, 0.043::numeric, 'Социальный статус "Равенство" в регионе, благодаря помощи жителям (Земли старших народов) Доль Блатанны.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040623', 23, 0.043::numeric, 'Социальный статус "Равенство" в регионе, благодаря помощи жителям (Земли старших народов) Махакама.', 'is_academy_life_details_from_o0406')
      ) AS v(an_id, sort_order, probability, txt, rule_name)

    UNION ALL

    SELECT 'en' AS lang, v.*
      FROM (VALUES
        -- Group 1: details for o0110/o0208/o0407
        ('wcc_past_academy_life_o011001', 1, 0.2::numeric, '<b>Curse of Monstrosity</b> (Intensity: Moderate)', 'is_academy_life_details_from_curse'),
        ('wcc_past_academy_life_o011002', 2, 0.2::numeric, '<b>Curse of Phantoms</b> (Intensity: Moderate)', 'is_academy_life_details_from_curse'),
        ('wcc_past_academy_life_o011003', 3, 0.2::numeric, '<b>Curse of Pestilence</b> (Intensity: High)', 'is_academy_life_details_from_curse'),
        ('wcc_past_academy_life_o011004', 4, 0.2::numeric, '<b>Curse of the Wanderer</b> (Intensity: High)', 'is_academy_life_details_from_curse'),
        ('wcc_past_academy_life_o011005', 5, 0.2::numeric, '<b>Curse of Lycanthropy</b> (Intensity: High)', 'is_academy_life_details_from_curse'),
        ('wcc_past_academy_life_o011006', 6, 0.0::numeric, '<b>Other Curse</b> (custom)', 'is_academy_life_details_from_curse'),

        -- Group 2: details for o0207
        ('wcc_past_academy_life_o020701', 1, 0.1666666667::numeric, 'Fighting for a minor noble, you kept 100 crowns after paying the Academy''s cut.', 'is_academy_life_details_from_o0207'),
        ('wcc_past_academy_life_o020702', 2, 0.1666666667::numeric, 'Fighting for a minor noble, you kept 200 crowns after paying the Academy''s cut.', 'is_academy_life_details_from_o0207'),
        ('wcc_past_academy_life_o020703', 3, 0.1666666667::numeric, 'Fighting for a minor noble, you kept 300 crowns after paying the Academy''s cut.', 'is_academy_life_details_from_o0207'),
        ('wcc_past_academy_life_o020704', 4, 0.1666666667::numeric, 'Fighting for a minor noble, you kept 400 crowns after paying the Academy''s cut.', 'is_academy_life_details_from_o0207'),
        ('wcc_past_academy_life_o020705', 5, 0.1666666667::numeric, 'Fighting for a minor noble, you kept 500 crowns after paying the Academy''s cut.', 'is_academy_life_details_from_o0207'),
        ('wcc_past_academy_life_o020706', 6, 0.1666666667::numeric, 'Fighting for a minor noble, you kept 600 crowns after paying the Academy''s cut.', 'is_academy_life_details_from_o0207'),

        -- Group 3: details for o0307
        ('wcc_past_academy_life_o030701', 1, 1.0::numeric, 'Mage Hunters Support: +2 to new skill Tactics', 'is_academy_life_details_from_o0307_tactics_new'),
        ('wcc_past_academy_life_o030702', 2, 1.0::numeric, 'Mage Hunters Support: +1 to existing skill Tactics', 'is_academy_life_details_from_o0307_tactics_existing'),
        ('wcc_past_academy_life_o030703', 3, 1.0::numeric, 'Mage Hunters Support: +2 to new skill Archery', 'is_academy_life_details_from_o0307_archery_new'),
        ('wcc_past_academy_life_o030704', 4, 1.0::numeric, 'Mage Hunters Support: +1 to existing skill Archery', 'is_academy_life_details_from_o0307_archery_existing'),
        ('wcc_past_academy_life_o030705', 5, 1.0::numeric, 'Mage Hunters Support: +2 to new skill Athletics', 'is_academy_life_details_from_o0307_athletics_new'),
        ('wcc_past_academy_life_o030706', 6, 1.0::numeric, 'Mage Hunters Support: +1 to existing skill Athletics', 'is_academy_life_details_from_o0307_athletics_existing'),
        ('wcc_past_academy_life_o030707', 7, 1.0::numeric, 'Mage Hunters Support: +2 to new skill Crossbow', 'is_academy_life_details_from_o0307_crossbow_new'),
        ('wcc_past_academy_life_o030708', 8, 1.0::numeric, 'Mage Hunters Support: +1 to existing skill Crossbow', 'is_academy_life_details_from_o0307_crossbow_existing'),
        ('wcc_past_academy_life_o030709', 9, 1.0::numeric, 'Mage Hunters Support: +2 to new skill Small Blades', 'is_academy_life_details_from_o0307_small_blades_new'),
        ('wcc_past_academy_life_o030710', 10, 1.0::numeric, 'Mage Hunters Support: +1 to existing skill Small Blades', 'is_academy_life_details_from_o0307_small_blades_existing'),
        ('wcc_past_academy_life_o030711', 11, 1.0::numeric, 'Mage Hunters Support: +2 to new skill Staff/Spear', 'is_academy_life_details_from_o0307_staff_new'),
        ('wcc_past_academy_life_o030712', 12, 1.0::numeric, 'Mage Hunters Support: +1 to existing skill Staff/Spear', 'is_academy_life_details_from_o0307_staff_existing'),
        ('wcc_past_academy_life_o030713', 13, 1.0::numeric, 'Mage Hunters Support: +2 to new skill Swordsmanship', 'is_academy_life_details_from_o0307_swordsmanship_new'),
        ('wcc_past_academy_life_o030714', 14, 1.0::numeric, 'Mage Hunters Support: +1 to existing skill Swordsmanship', 'is_academy_life_details_from_o0307_swordsmanship_existing'),
        ('wcc_past_academy_life_o030715', 15, 1.0::numeric, 'Mage Hunters Support: +2 to new skill Melee', 'is_academy_life_details_from_o0307_melee_new'),
        ('wcc_past_academy_life_o030716', 16, 1.0::numeric, 'Mage Hunters Support: +1 to existing skill Melee', 'is_academy_life_details_from_o0307_melee_existing'),
        ('wcc_past_academy_life_o030717', 17, 1.0::numeric, 'Mage Hunters Support: +2 to new skill Brawling', 'is_academy_life_details_from_o0307_brawling_new'),
        ('wcc_past_academy_life_o030718', 18, 1.0::numeric, 'Mage Hunters Support: +1 to existing skill Brawling', 'is_academy_life_details_from_o0307_brawling_existing'),
        ('wcc_past_academy_life_o030719', 19, 1.0::numeric, 'Mage Hunters Support: +2 to new skill Riding', 'is_academy_life_details_from_o0307_riding_new'),
        ('wcc_past_academy_life_o030720', 20, 1.0::numeric, 'Mage Hunters Support: +1 to existing skill Riding', 'is_academy_life_details_from_o0307_riding_existing'),

        -- Group 4: details for o0406
        ('wcc_past_academy_life_o040601', 1, 0.0434782609::numeric, 'Social Standing "Equal" in this region, thanks to helping the people of (Northern Kingdoms) Redania.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040602', 2, 0.0434782609::numeric, 'Social Standing "Equal" in this region, thanks to helping the people of (Northern Kingdoms) Kaedwen.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040603', 3, 0.0434782609::numeric, 'Social Standing "Equal" in this region, thanks to helping the people of (Northern Kingdoms) Temeria.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040604', 4, 0.0434782609::numeric, 'Social Standing "Equal" in this region, thanks to helping the people of (Northern Kingdoms) Aedirn.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040605', 5, 0.0434782609::numeric, 'Social Standing "Equal" in this region, thanks to helping the people of (Northern Kingdoms) Lyria & Rivia.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040606', 6, 0.0434782609::numeric, 'Social Standing "Equal" in this region, thanks to helping the people of (Northern Kingdoms) Kovir & Poviss.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040607', 7, 0.0434782609::numeric, 'Social Standing "Equal" in this region, thanks to helping the people of (Northern Kingdoms) Skellige.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040608', 8, 0.0434782609::numeric, 'Social Standing "Equal" in this region, thanks to helping the people of (Northern Kingdoms) Cidaris.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040609', 9, 0.0434782609::numeric, 'Social Standing "Equal" in this region, thanks to helping the people of (Northern Kingdoms) Verden.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040610', 10, 0.0434782609::numeric, 'Social Standing "Equal" in this region, thanks to helping the people of (Northern Kingdoms) Cintra.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040611', 11, 0.0434782609::numeric, 'Social Standing "Equal" in this region, thanks to helping the people of (Nilfgaard) The Heart of Nilfgaard.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040612', 12, 0.0434782609::numeric, 'Social Standing "Equal" in this region, thanks to helping the people of (Nilfgaard) Vicovaro.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040613', 13, 0.0434782609::numeric, 'Social Standing "Equal" in this region, thanks to helping the people of (Nilfgaard) Angren.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040614', 14, 0.0434782609::numeric, 'Social Standing "Equal" in this region, thanks to helping the people of (Nilfgaard) Nazair.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040615', 15, 0.0434782609::numeric, 'Social Standing "Equal" in this region, thanks to helping the people of (Nilfgaard) Mettina.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040616', 16, 0.0434782609::numeric, 'Social Standing "Equal" in this region, thanks to helping the people of (Nilfgaard) Mag Turga.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040617', 17, 0.0434782609::numeric, 'Social Standing "Equal" in this region, thanks to helping the people of (Nilfgaard) Gheso.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040618', 18, 0.0434782609::numeric, 'Social Standing "Equal" in this region, thanks to helping the people of (Nilfgaard) Ebbing.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040619', 19, 0.0434782609::numeric, 'Social Standing "Equal" in this region, thanks to helping the people of (Nilfgaard) Maecht.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040620', 20, 0.0434782609::numeric, 'Social Standing "Equal" in this region, thanks to helping the people of (Nilfgaard) Gemmeria.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040621', 21, 0.0434782609::numeric, 'Social Standing "Equal" in this region, thanks to helping the people of (Nilfgaard) Etolia.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040622', 22, 0.0434782609::numeric, 'Social Standing "Equal" in this region, thanks to helping the people of (Elderlands) Dol Blathanna.', 'is_academy_life_details_from_o0406'),
        ('wcc_past_academy_life_o040623', 23, 0.0434782609::numeric, 'Social Standing "Equal" in this region, thanks to helping the people of (Elderlands) Mahakam.', 'is_academy_life_details_from_o0406')
      ) AS v(an_id, sort_order, probability, txt, rule_name)
  )
, vals AS (
    SELECT lang
         , an_id
         , sort_order
         , rule_name
         , probability
         , '<td style="color: grey;">' || to_char(probability * 100, 'FM990.00') || '%</td><td>' || txt || '</td>' AS text
      FROM raw_data
)
, ins_i18n AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id('witcher_cc.' || vals.an_id || '.answer_options.label') AS id
         , 'answer_options', 'label', vals.lang, vals.text
      FROM vals
    ON CONFLICT (id, lang) DO NOTHING
)
, ins_event_desc AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id('witcher_cc.' || raw_data.an_id || '.event_desc') AS id
         , 'character', 'event_desc', raw_data.lang,
           CASE
             WHEN raw_data.an_id LIKE 'wcc_past_academy_life_o0406%'
               THEN regexp_replace(split_part(raw_data.txt, '.', 1), '\s+$', '')
             ELSE raw_data.txt
           END
      FROM raw_data
     WHERE raw_data.an_id LIKE 'wcc_past_academy_life_o0307%'
        OR raw_data.an_id LIKE 'wcc_past_academy_life_o0406%'
    ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT vals.an_id
     , 'witcher_cc'
     , 'wcc_past_academy_life_details'
     , ck_id('witcher_cc.' || vals.an_id || '.answer_options.label')::text
     , vals.sort_order
     , (SELECT ru_id FROM rules WHERE name = vals.rule_name ORDER BY ru_id LIMIT 1)
     , jsonb_build_object('probability', vals.probability)
       || CASE
            WHEN vals.an_id IN ('wcc_past_academy_life_o011001', 'wcc_past_academy_life_o011006')
              THEN '{}'::jsonb
            ELSE jsonb_build_object('counterIncrement', jsonb_build_object('id', 'lifeEventsCounter', 'step', 10))
          END
  FROM vals
 WHERE vals.lang = 'ru'
ON CONFLICT (an_id) DO NOTHING;

-- Region names for social status effects (group o0406)
WITH region_vals AS (
  SELECT *
    FROM (VALUES
      (1,  'Редания (Северные королевства)', 'Redania (Northern Kingdoms)'),
      (2,  'Каэдвен (Северные королевства)', 'Kaedwen (Northern Kingdoms)'),
      (3,  'Темерия (Северные королевства)', 'Temeria (Northern Kingdoms)'),
      (4,  'Аэдирн (Северные королевства)', 'Aedirn (Northern Kingdoms)'),
      (5,  'Лирия и Ривия (Северные королевства)', 'Lyria & Rivia (Northern Kingdoms)'),
      (6,  'Ковир и Повисс (Северные королевства)', 'Kovir & Poviss (Northern Kingdoms)'),
      (7,  'Скеллиге (Северные королевства)', 'Skellige (Northern Kingdoms)'),
      (8,  'Цидарис (Северные королевства)', 'Cidaris (Northern Kingdoms)'),
      (9,  'Вердэн (Северные королевства)', 'Verden (Northern Kingdoms)'),
      (10, 'Цинтра (Северные королевства)', 'Cintra (Northern Kingdoms)'),
      (11, 'Сердце Нильфгаарда (Нильфгаард)', 'The Heart of Nilfgaard (Nilfgaard)'),
      (12, 'Виковаро (Нильфгаард)', 'Vicovaro (Nilfgaard)'),
      (13, 'Аигрен (Нильфгаард)', 'Angren (Nilfgaard)'),
      (14, 'Назаир (Нильфгаард)', 'Nazair (Nilfgaard)'),
      (15, 'Метиина (Нильфгаард)', 'Mettina (Nilfgaard)'),
      (16, 'Маг Турга (Нильфгаард)', 'Mag Turga (Nilfgaard)'),
      (17, 'Гесо (Нильфгаард)', 'Gheso (Nilfgaard)'),
      (18, 'Эббинг (Нильфгаард)', 'Ebbing (Nilfgaard)'),
      (19, 'Мехт (Нильфгаард)', 'Maecht (Nilfgaard)'),
      (20, 'Геммера (Нильфгаард)', 'Gemmeria (Nilfgaard)'),
      (21, 'Этолия (Нильфгаард)', 'Etolia (Nilfgaard)'),
      (22, 'Доль Блатанна (Земли старших народов)', 'Dol Blathanna (Elderlands)'),
      (23, 'Махакам (Земли старших народов)', 'Mahakam (Elderlands)')
    ) AS v(num, ru_name, en_name)
)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_past_academy_life_o0406' || to_char(v.num, 'FM00') || '.region_name') AS id
     , 'character' AS entity
     , 'social_status_group' AS entity_field
     , x.lang
     , x.text
  FROM region_vals v
 CROSS JOIN LATERAL (
    VALUES
      ('ru', v.ru_name),
      ('en', v.en_name)
 ) AS x(lang, text)
ON CONFLICT (id, lang) DO NOTHING;

-- Effects: set academy life pass flag on every academy_life option
WITH academy_answers AS (
  SELECT 'wcc_past_academy_life_o' || to_char(g.group_id, 'FM00') || to_char(n.num, 'FM00') AS an_id
    FROM generate_series(1, 4) AS g(group_id)
    CROSS JOIN generate_series(1, 10) AS n(num)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  academy_answers.an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.logicFields.flags.academy_life'),
      jsonb_build_object(
        'jsonlogic_expression',
        jsonb_build_object(
          'if',
          jsonb_build_array(
            jsonb_build_object(
              '<=',
              jsonb_build_array(
                jsonb_build_object('var', 'counters.lifeEventsCounter'),
                9
              )
            ),
            1,
            2
          )
        )
      )
    )
  )
FROM academy_answers;

-- Effects: curse details for options 2-5 (group from o0110/o0208/o0407)
WITH curse_mapping AS (
  SELECT *
    FROM (VALUES
      (2, 2),
      (3, 3),
      (4, 4),
      (5, 5)
    ) AS v(num, source_num)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_past_academy_life_o0110' || to_char(curse_mapping.num, 'FM00'),
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.diseases_and_curses'),
      jsonb_build_object(
        'type', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_life_events_fortune_or_not_details.disease_type_curse')::text),
        'name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_life_events_fortune_or_not_details_o' || to_char(2000 + curse_mapping.source_num, 'FM0000') || '.curse_name')::text),
        'intensity', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_life_events_fortune_or_not_details_o' || to_char(2000 + curse_mapping.source_num, 'FM0000') || '.curse_intensity')::text),
        'description', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_life_events_fortune_or_not_details_o' || to_char(2000 + curse_mapping.source_num, 'FM0000') || '.curse_desc')::text)
      )
    )
  )
FROM curse_mapping;

-- Effects: save curse detail choices to academy life events
WITH curse_event_mapping(detail_num, source_num) AS (
  VALUES
    (1, 1),
    (2, 2),
    (3, 3),
    (4, 4),
    (5, 5)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_past_academy_life_o0110' || to_char(curse_event_mapping.detail_num, 'FM00'),
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.lifeEvents'),
      jsonb_build_object(
        'timePeriod',
        jsonb_build_object(
          'jsonlogic_expression', jsonb_build_object(
            'cat', jsonb_build_array(
              jsonb_build_object('var', 'counters.lifeEventsCounter'),
              '-',
              jsonb_build_object(
                '+', jsonb_build_array(
                  jsonb_build_object('var', 'counters.lifeEventsCounter'),
                  10
                )
              )
            )
          )
        ),
        'eventType',
        jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_past_academy_life.life_event_type.academy_life')::text),
        'description',
        jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_life_events_fortune_or_not_details_o' || to_char(2000 + curse_event_mapping.source_num, 'FM0000') || '.event_desc')::text)
      )
    )
  )
FROM curse_event_mapping;

-- Effects: crowns for o0207 details
WITH crowns_vals AS (
  SELECT num, num * 100 AS crowns
    FROM generate_series(1, 6) AS num
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_past_academy_life_o0207' || to_char(crowns_vals.num, 'FM00'),
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.money.crowns'),
      crowns_vals.crowns
    )
  )
FROM crowns_vals;

-- Effects: combat skill increase for o0307 details
WITH skill_mapping AS (
  SELECT *
    FROM (VALUES
      (1, 2,  'tactics'),
      (3, 4,  'archery'),
      (5, 6,  'athletics'),
      (7, 8,  'crossbow'),
      (9, 10, 'small_blades'),
      (11, 12, 'staff'),
      (13, 14, 'swordsmanship'),
      (15, 16, 'melee'),
      (17, 18, 'brawling'),
      (19, 20, 'riding')
    ) AS v(new_num, existing_num, skill_path)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_past_academy_life_o0307' || to_char(skill_mapping.new_num, 'FM00'),
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.common.' || skill_mapping.skill_path || '.cur'),
      2
    )
  )
FROM skill_mapping
UNION ALL
SELECT
  'character',
  'wcc_past_academy_life_o0307' || to_char(skill_mapping.existing_num, 'FM00'),
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.common.' || skill_mapping.skill_path || '.cur'),
      1
    )
  )
FROM skill_mapping;

-- Effects: save o0307 detail choice to life events (new/existing skill)
WITH options AS (
  SELECT num
    FROM generate_series(1, 20) AS num
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_past_academy_life_o0307' || to_char(options.num, 'FM00'),
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.lifeEvents'),
      jsonb_build_object(
        'timePeriod',
        jsonb_build_object(
          'jsonlogic_expression', jsonb_build_object(
            'cat', jsonb_build_array(
              jsonb_build_object('var', 'counters.lifeEventsCounter'),
              '-',
              jsonb_build_object(
                '+', jsonb_build_array(
                  jsonb_build_object('var', 'counters.lifeEventsCounter'),
                  10
                )
              )
            )
          )
        ),
        'eventType',
        jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_past_academy_life.life_event_type.academy_life')::text),
        'description',
        jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_past_academy_life_o0307' || to_char(options.num, 'FM00') || '.event_desc')::text)
      )
    )
  )
FROM options;

-- Effects: save o0406 detail choice to life events (helped locals in region)
WITH options AS (
  SELECT num
    FROM generate_series(1, 23) AS num
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_past_academy_life_o0406' || to_char(options.num, 'FM00'),
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.lifeEvents'),
      jsonb_build_object(
        'timePeriod',
        jsonb_build_object(
          'jsonlogic_expression', jsonb_build_object(
            'cat', jsonb_build_array(
              jsonb_build_object('var', 'counters.lifeEventsCounter'),
              '-',
              jsonb_build_object(
                '+', jsonb_build_array(
                  jsonb_build_object('var', 'counters.lifeEventsCounter'),
                  10
                )
              )
            )
          )
        ),
        'eventType',
        jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_past_academy_life.life_event_type.academy_life')::text),
        'description',
        jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_past_academy_life_o0406' || to_char(options.num, 'FM00') || '.event_desc')::text)
      )
    )
  )
FROM options;

-- Effects: social status "Equal" in selected region for o0406 details
WITH regions AS (
  SELECT num
    FROM generate_series(1, 23) AS num
)
INSERT INTO effects (scope, an_an_id, body)
  SELECT
    'character',
    'wcc_past_academy_life_o0406' || to_char(regions.num, 'FM00'),
    jsonb_build_object(
      'when',
      jsonb_build_object(
        '!',
        jsonb_build_object(
          'in',
          jsonb_build_array(
            ck_id('witcher_cc.wcc_past_academy_life_o0406' || to_char(regions.num, 'FM00') || '.region_name')::text,
            jsonb_build_object('cat_array', 'characterRaw.social_status[].group_name.i18n_uuid')
          )
        )
      ),
      'add',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.social_status'),
        jsonb_build_object(
          'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_past_academy_life_o0406' || to_char(regions.num, 'FM00') || '.region_name')::text),
        'group_status', 3,
        'group_is_feared', false
      )
    )
  )
FROM regions;
