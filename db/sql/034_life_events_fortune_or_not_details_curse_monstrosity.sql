\echo '034_life_events_fortune_or_not_details_curse_monstrosity.sql'
-- Узел: Детализация проклятия чудовищности — выбор животного

-- Вопрос
WITH
  meta AS (
    SELECT
      'witcher_cc' AS su_su_id,
      'wcc_life_events_fortune_or_not_details_curse_monstrosity' AS qu_id,
      'questions' AS entity,
      'single'::question_type AS qtype,
      jsonb_build_object('dice','d0') AS metadata
  )
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| v.entity_field) AS id
         , meta.entity, v.entity_field, v.lang, v.text
      FROM (VALUES
        ('ru', 'Выберите животное, на которое похожи черты лица проклятого.', 'body'),
        ('en', 'Choose the animal whose features the cursed resembles.', 'body')
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
     , meta.metadata
        || jsonb_build_object('counterIncrement', jsonb_build_object('id', 'lifeEventsCounter', 'step', 10))
        || jsonb_build_object(
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
          -- Условный элемент 3: для ведьмака или обычных рас
          jsonb_build_object('jsonlogic_expression', jsonb_build_object('if', jsonb_build_array(
            jsonb_build_object('==', jsonb_build_array(
              jsonb_build_object('var', 'characterRaw.logicFields.race'),
              'Witcher'
            )),
            ck_id('witcher_cc.hierarchy.witcher_events_danger')::text,
            ck_id('witcher_cc.hierarchy.life_events_misfortune')::text
          ))),
          -- Условный элемент 4: куда положить в иерархии
          jsonb_build_object('jsonlogic_expression', jsonb_build_object('if', jsonb_build_array(
            jsonb_build_object('==', jsonb_build_array(
              jsonb_build_object('var', 'characterRaw.logicFields.race'),
              'Witcher'
            )),
            ck_id('witcher_cc.hierarchy.witcher_events_danger_events_details_monstrosity')::text,
            ck_id('witcher_cc.hierarchy.life_events_misfortune_details_monstrosity')::text
          )))
        )
      )
  FROM meta;

-- Ответы
WITH
  meta AS (
    SELECT
      'witcher_cc' AS su_su_id,
      'wcc_life_events_fortune_or_not_details_curse_monstrosity' AS qu_id,
      'answer_options' AS entity,
      'label' AS entity_field
  )
, vals AS (
  SELECT v.*
    FROM (VALUES
      ('ru', 1, 'Медведь'),
      ('ru', 2, 'Кабан'),
      ('ru', 3, 'Птица'),
      ('ru', 4, 'Змея'),
      ('ru', 5, 'Насекомое'),
      ('en', 1, 'Bear'),
      ('en', 2, 'Boar'),
      ('en', 3, 'Bird'),
      ('en', 4, 'Snake'),
      ('en', 5, 'Insect')
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
  SELECT 'wcc_life_events_fortune_or_not_details_curse_monstrosity_o' || to_char(vals.num, 'FM9900') AS an_id,
         meta.su_su_id,
         meta.qu_id,
         ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
         vals.num AS sort_order,
         '{}'::jsonb AS metadata
    FROM (SELECT DISTINCT num FROM vals) vals
    CROSS JOIN meta
  ON CONFLICT (an_id) DO NOTHING;

-- i18n для описания проклятия (под конкретное животное)
WITH
  meta AS (
    SELECT
      'witcher_cc' AS su_su_id,
      'wcc_life_events_fortune_or_not_details_curse_monstrosity' AS qu_id
  )
, vals AS (
  SELECT v.*
    FROM (VALUES
      ('ru', 1, 'Жертва выглядит чудовищно для всех, кто её видит. Она остаётся гуманоидом, но черты лица приобретают сходство с медведем. Социальный статус проклятого меняется на «ненависть и опасение» вне зависимости от того, каким он был раньше. Проклятый на самом деле не является чудовищем и не получает урона от серебра, но с виду похож на чудовище, и его можно спутать с чудовищем, если провалить проверку Образования со СЛ 18.'),
      ('ru', 2, 'Жертва выглядит чудовищно для всех, кто её видит. Она остаётся гуманоидом, но черты лица приобретают сходство с кабаном. Социальный статус проклятого меняется на «ненависть и опасение» вне зависимости от того, каким он был раньше. Проклятый на самом деле не является чудовищем и не получает урона от серебра, но с виду похож на чудовище, и его можно спутать с чудовищем, если провалить проверку Образования со СЛ 18.'),
      ('ru', 3, 'Жертва выглядит чудовищно для всех, кто её видит. Она остаётся гуманоидом, но черты лица приобретают сходство с птицей. Социальный статус проклятого меняется на «ненависть и опасение» вне зависимости от того, каким он был раньше. Проклятый на самом деле не является чудовищем и не получает урона от серебра, но с виду похож на чудовище, и его можно спутать с чудовищем, если провалить проверку Образования со СЛ 18.'),
      ('ru', 4, 'Жертва выглядит чудовищно для всех, кто её видит. Она остаётся гуманоидом, но черты лица приобретают сходство со змеёй. Социальный статус проклятого меняется на «ненависть и опасение» вне зависимости от того, каким он был раньше. Проклятый на самом деле не является чудовищем и не получает урона от серебра, но с виду похож на чудовище, и его можно спутать с чудовищем, если провалить проверку Образования со СЛ 18.'),
      ('ru', 5, 'Жертва выглядит чудовищно для всех, кто её видит. Она остаётся гуманоидом, но черты лица приобретают сходство с насекомым. Социальный статус проклятого меняется на «ненависть и опасение» вне зависимости от того, каким он был раньше. Проклятый на самом деле не является чудовищем и не получает урона от серебра, но с виду похож на чудовище, и его можно спутать с чудовищем, если провалить проверку Образования со СЛ 18.'),
      ('en', 1, 'The victim appears monstrous to all who see them. They remain humanoid, but their features resemble a bear. The victim''s social status becomes "Hated & Feared." They are not actually a monster and do not take damage from silver, but can be mistaken for one on a failed Education check DC 18.'),
      ('en', 2, 'The victim appears monstrous to all who see them. They remain humanoid, but their features resemble a boar. The victim''s social status becomes "Hated & Feared." They are not actually a monster and do not take damage from silver, but can be mistaken for one on a failed Education check DC 18.'),
      ('en', 3, 'The victim appears monstrous to all who see them. They remain humanoid, but their features resemble a bird. The victim''s social status becomes "Hated & Feared." They are not actually a monster and do not take damage from silver, but can be mistaken for one on a failed Education check DC 18.'),
      ('en', 4, 'The victim appears monstrous to all who see them. They remain humanoid, but their features resemble a snake. The victim''s social status becomes "Hated & Feared." They are not actually a monster and do not take damage from silver, but can be mistaken for one on a failed Education check DC 18.'),
      ('en', 5, 'The victim appears monstrous to all who see them. They remain humanoid, but their features resemble an insect. The victim''s social status becomes "Hated & Feared." They are not actually a monster and do not take damage from silver, but can be mistaken for one on a failed Education check DC 18.')
    ) AS v(lang, num, text)
)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT
    ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| 'curse_desc') AS id,
    'curses' AS entity,
    'description' AS entity_field,
    vals.lang,
    vals.text
  FROM vals
  CROSS JOIN meta
ON CONFLICT (id, lang) DO NOTHING;

-- Эффекты: добавление проклятия в diseases_and_curses (уже с конкретным животным)
WITH
  meta AS (
    SELECT
      'witcher_cc' AS su_su_id,
      'wcc_life_events_fortune_or_not_details_curse_monstrosity' AS qu_id
  )
, nums AS (
  SELECT 1 AS num UNION ALL
  SELECT 2 UNION ALL
  SELECT 3 UNION ALL
  SELECT 4 UNION ALL
  SELECT 5
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_life_events_fortune_or_not_details_curse_monstrosity_o' || to_char(nums.num, 'FM9900'),
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.lore.diseases_and_curses'),
      jsonb_build_object(
        'type', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_life_events_fortune_or_not_details.disease_type_curse')::text),
        'name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_life_events_fortune_or_not_details_o2001.curse_name')::text),
        'intensity', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_life_events_fortune_or_not_details_o2001.curse_intensity')::text),
        'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(nums.num, 'FM9900') ||'.'|| 'curse_desc')::text)
      )
    )
  )
FROM nums
CROSS JOIN meta;

-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT
    'wcc_life_events_fortune_or_not_details',
    'wcc_life_events_fortune_or_not_details_curse_monstrosity',
    'wcc_life_events_fortune_or_not_details_o2001',
    2;

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT
    'wcc_life_events_fortune_or_not_details_curse_monstrosity',
    'wcc_life_events_event',
    r.ru_id,
    1
  FROM (SELECT ru_id FROM rules WHERE name = 'lifeEventsCounter_is_valid') r;

