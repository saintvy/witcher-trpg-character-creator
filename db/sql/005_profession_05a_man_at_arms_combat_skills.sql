\echo '005_profession_05a_man_at_arms_combat_skills.sql'
-- Нода: Выбор боевых навыков для профессии "Воин"

-- i18n записи для сообщений валидации
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_man_at_arms_combat_skills.warning.' || v.key) AS id
     , 'questions' AS entity
     , 'metadata' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          ('min_selected', 'ru', 'Выбрано опций меньше требуемого. Минимум: '),
          ('min_selected', 'en', 'Selected options are less than required. Minimum: '),
          ('max_selected', 'ru', 'Выбрано опций больше допустимого. Максимум: '),
          ('max_selected', 'en', 'Selected options are more than allowed. Maximum: ')
       ) AS v(key, lang, text)
ON CONFLICT (id, lang) DO NOTHING;

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_man_at_arms_combat_skills' AS qu_id
                , 'questions' AS entity
                , 'multiple'::question_type AS qtype)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| v.entity_field) AS id
           , meta.entity, v.entity_field, v.lang, v.text
        FROM (VALUES
                ('ru', 'Выберите 5 боевых навыков', 'body'),
                ('en', 'Pick 5 combat skills', 'body')
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
           'allowEmptySelection', false,
           'minSelected', 5,
           'maxSelected', 5,
           'warningMinSelected', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_man_at_arms_combat_skills.warning.min_selected')::text),
           'warningMaxSelected', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_man_at_arms_combat_skills.warning.max_selected')::text),
           'path', jsonb_build_array(ck_id('witcher_cc.hierarchy.profession')::text,ck_id('witcher_cc.hierarchy.battle_skills')::text)
         )
     FROM meta;

-- Опции: боевые навыки
WITH raw_data (sort_order, skill_id, name_ru, name_en) AS ( VALUES
    (1,  'tactics',           '[Интеллект] Тактика',                   '[INT] Tactics'),
    (2,  'archery',           '[Ловкость] Стрельба из лука',           '[DEX] Archery'),
    (3,  'athletics',         '[Ловкость] Атлетика',                   '[DEX] Athletics'),
    (4,  'crossbow',          '[Ловкость] Стрельба из арбалета',       '[DEX] Crossbow'),
    (5,  'small_blades',      '[Реакция] Владение лёгкими клинками',   '[REF] Small Blades'),
    (6,  'staff_spear',       '[Реакция] Владение древковым оружием',  '[REF] Staff/Spear'),
    (7,  'swordsmanship',     '[Реакция] Владение мечом',              '[REF] Swordsmanship'),
    (8,  'melee',             '[Реакция] Ближний бой',                 '[REF] Melee'),
    (9,  'brawling',          '[Реакция] Борьба',                      '[REF] Brawling'),
    (10, 'riding',            '[Реакция] Верховая езда',               '[REF] Riding')
),
ins_names AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    SELECT ck_id('witcher_cc.wcc_man_at_arms_combat_skills.skill.'||rd.skill_id),
           'answer_options',
           'title',
           'ru',
           rd.name_ru
      FROM raw_data rd
     WHERE nullif(rd.name_ru,'') is not null
    UNION ALL
    SELECT ck_id('witcher_cc.wcc_man_at_arms_combat_skills.skill.'||rd.skill_id),
           'answer_options',
           'title',
           'en',
           rd.name_en
      FROM raw_data rd
     WHERE nullif(rd.name_en,'') is not null
  ) foo
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
  SELECT 'wcc_man_at_arms_combat_skills_' || rd.skill_id AS an_id
       , 'witcher_cc' AS su_su_id
       , 'wcc_man_at_arms_combat_skills' AS qu_qu_id
       , ck_id('witcher_cc.wcc_man_at_arms_combat_skills.skill.'||rd.skill_id)::text AS label
       , rd.sort_order
       , jsonb_build_object('skill_id', rd.skill_id)
    FROM raw_data rd
  ON CONFLICT (an_id) DO NOTHING;

-- Переход из ноды профессии при выборе "Воин"
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_profession', 'wcc_man_at_arms_combat_skills', 'wcc_profession_o05', 2;

-- Эффекты: добавление выбранных навыков в characterRaw.skills.initial[]
-- Маппинг skill_id -> название навыка в defaultCharacter.json
WITH skill_mapping (skill_id, skill_name) AS ( VALUES
    ('tactics', 'tactics'),
    ('archery', 'archery'),
    ('athletics', 'athletics'),
    ('crossbow', 'crossbow'),
    ('small_blades', 'small_blades'),
    ('staff_spear', 'staff'),  -- в defaultCharacter.json это 'staff'
    ('swordsmanship', 'swordsmanship'),
    ('melee', 'melee'),
    ('brawling', 'brawling'),
    ('riding', 'riding')
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_man_at_arms_combat_skills_' || sm.skill_id AS an_an_id,
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.initial'),
      sm.skill_name
    )
  ) AS body
FROM skill_mapping sm;



