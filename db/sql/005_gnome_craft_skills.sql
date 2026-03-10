\echo '005_gnome_craft_skills.sql'
-- Нода: Выбор ремесленных навыков для гнома (расовый бонус)

-- i18n записи для сообщений валидации
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_gnome_craft_skills.warning.' || v.key) AS id
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
                , 'wcc_gnome_craft_skills' AS qu_id
                , 'questions' AS entity
                , 'multiple'::question_type AS qtype)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| v.entity_field) AS id
           , meta.entity, v.entity_field, v.lang, v.text
        FROM (VALUES
                ('ru', 'Выберите 3 ремесленных навыка для расового бонуса гнома (+2 к каждому выбранному навыку)', 'body'),
                ('en', 'Pick 3 craft skills for the gnome racial bonus (+2 to each selected skill)', 'body')
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
           'minSelected', 3,
           'maxSelected', 3,
           'warningMinSelected', jsonb_build_object(
             'jsonlogic_expression',
             jsonb_build_array(
               ck_id('witcher_cc.wcc_gnome_craft_skills.warning.min_selected')::text,
               3
             )
           ),
           'warningMaxSelected', jsonb_build_object(
             'jsonlogic_expression',
             jsonb_build_array(
               ck_id('witcher_cc.wcc_gnome_craft_skills.warning.max_selected')::text,
               3
             )
           ),
           'path', jsonb_build_array(
             ck_id('witcher_cc.hierarchy.identity')::text,
             ck_id('witcher_cc.hierarchy.race')::text,
             ck_id('witcher_cc.hierarchy.gnome_skills')::text
           )
         )
     FROM meta;

-- Опции: ремесленные навыки (Common skills / CRA)
WITH raw_data (sort_order, skill_id, name_ru, name_en) AS ( VALUES
    (1, 'alchemy',       '[Ремесло] Алхимия',          '[CRA] Alchemy'),
    (2, 'pick_lock',     '[Ремесло] Взлом замков',     '[CRA] Pick Lock'),
    (3, 'trap_crafting', '[Ремесло] Знание ловушек',   '[CRA] Trap Crafting'),
    (4, 'crafting',      '[Ремесло] Изготовление',     '[CRA] Crafting'),
    (5, 'disguise',      '[Ремесло] Маскировка',       '[CRA] Disguise'),
    (6, 'first_aid',     '[Ремесло] Первая помощь',    '[CRA] First Aid'),
    (7, 'forgery',       '[Ремесло] Подделывание',     '[CRA] Forgery')
)
, ins_names AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    SELECT ck_id('witcher_cc.wcc_gnome_craft_skills.skill.'||rd.skill_id),
           'answer_options',
           'title',
           'ru',
           rd.name_ru
      FROM raw_data rd
    UNION ALL
    SELECT ck_id('witcher_cc.wcc_gnome_craft_skills.skill.'||rd.skill_id),
           'answer_options',
           'title',
           'en',
           rd.name_en
      FROM raw_data rd
  ) foo
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
  SELECT 'wcc_gnome_craft_skills_' || rd.skill_id AS an_id
       , 'witcher_cc' AS su_su_id
       , 'wcc_gnome_craft_skills' AS qu_qu_id
       , ck_id('witcher_cc.wcc_gnome_craft_skills.skill.'||rd.skill_id)::text AS label
       , rd.sort_order
       , jsonb_build_object('skill_id', rd.skill_id)
    FROM raw_data rd
  ON CONFLICT (an_id) DO NOTHING;

-- Эффекты: +2 к расовому бонусу выбранного навыка
WITH skill_mapping (skill_id) AS ( VALUES
    ('alchemy'),
    ('pick_lock'),
    ('trap_crafting'),
    ('crafting'),
    ('disguise'),
    ('first_aid'),
    ('forgery')
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_gnome_craft_skills_' || sm.skill_id AS an_an_id,
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.common.' || sm.skill_id || '.race_bonus'),
      2
    )
  ) AS body
FROM skill_mapping sm;

-- Переход в ноду выбора ремесленных навыков (только для расы "Гном")
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_race', 'wcc_gnome_craft_skills', 'wcc_race_gnome', 1;

