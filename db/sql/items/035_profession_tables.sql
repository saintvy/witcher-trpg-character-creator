\echo '035_profession_tables.sql'
-- Таблицы для профессий, навыков и параметров

-- Удаление таблиц при передеплое
DROP TABLE IF EXISTS wcc_profession_skills CASCADE;
DROP TABLE IF EXISTS wcc_professions CASCADE;
DROP TABLE IF EXISTS wcc_skills CASCADE;
DROP TABLE IF EXISTS wcc_params CASCADE;

-- Создание таблиц
CREATE TABLE IF NOT EXISTS wcc_params (
  param_id varchar(64) PRIMARY KEY,
  param_name_id uuid NOT NULL,
  param_short_name_id uuid NOT NULL,
  is_calculated boolean NOT NULL DEFAULT false
  -- Note: Foreign keys to i18n_text(id) are not possible because i18n_text has composite PK (id, lang)
  -- The UUIDs reference i18n_text entries but integrity is maintained at application level
);

CREATE TABLE IF NOT EXISTS wcc_skills (
  skill_aid integer PRIMARY KEY,
  skill_id varchar(64) UNIQUE NOT NULL,
  skill_name_id uuid NOT NULL,
  skill_desc_id uuid,
  param_param_id varchar(64) REFERENCES wcc_params(param_id) ON DELETE RESTRICT,
  skill_type varchar(20) NOT NULL CHECK (skill_type IN ('common', 'main', 'professional')),
  professional_number integer CHECK (professional_number IS NULL OR (professional_number >= 1 AND professional_number <= 3)),
  branch_number integer CHECK (branch_number IS NULL OR (branch_number >= 1 AND branch_number <= 3)),
  branch_name_id uuid,
  is_difficult boolean NOT NULL DEFAULT false
  -- Note: Foreign keys to i18n_text(id) are not possible because i18n_text has composite PK (id, lang)
  -- The UUIDs reference i18n_text entries but integrity is maintained at application level
);

CREATE TABLE IF NOT EXISTS wcc_professions (
  prof_id varchar(64) PRIMARY KEY,
  dlc varchar(64) NOT NULL REFERENCES wcc_dlcs(dlc_id) ON DELETE RESTRICT,
  prof_name_id uuid NOT NULL,
  prof_desc_id uuid
  -- Note: Foreign keys to i18n_text(id) are not possible because i18n_text has composite PK (id, lang)
  -- The UUIDs reference i18n_text entries but integrity is maintained at application level
);

CREATE TABLE IF NOT EXISTS wcc_profession_skills (
  prof_id varchar(64) NOT NULL REFERENCES wcc_professions(prof_id) ON DELETE CASCADE,
  skill_skill_id varchar(64) NOT NULL REFERENCES wcc_skills(skill_id) ON DELETE CASCADE,
  PRIMARY KEY (prof_id, skill_skill_id)
);

-- Вставка параметров
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id, 'wcc_params' AS entity),
  raw_params AS (
    SELECT 'ru' AS lang, param_id, name AS name_text, short_name AS short_name_text, is_calculated
      FROM (VALUES
        ('int', 'Интеллект', 'Инт', false),
        ('ref', 'Реакция', 'Реа', false),
        ('dex', 'Ловкость', 'Лвк', false),
        ('body', 'Телосложение', 'Тел', false),
        ('spd', 'Скорость', 'Скор', false),
        ('emp', 'Эмпатия', 'Эмп', false),
        ('cra', 'Ремесло', 'Рем', false),
        ('will', 'Воля', 'Воля', false),
        ('luck', 'Удача', 'Удача', false),
        ('stun', 'Ошеломление', 'Уст', true),
        ('run', 'Бег', 'Бег', true),
        ('leap', 'Прыжок', 'Прж', true),
        ('sta', 'Выносливость', 'Вын', true),
        ('enc', 'Нагрузка', 'Вес', true),
        ('rec', 'Восстановление', 'Отдых', true),
        ('hp', 'Здоровье', 'ПЗ', true),
        ('vigor', 'Энергия', 'Энергия', true)
      ) AS raw_data_ru(param_id, name, short_name, is_calculated)
    UNION ALL
    SELECT 'en' AS lang, param_id, name AS name_text, short_name AS short_name_text, is_calculated
      FROM (VALUES
        ('int', 'Intelligence', 'INT', false),
        ('ref', 'Reflex', 'REF', false),
        ('dex', 'Dexterity', 'DEX', false),
        ('body', 'Body', 'BODY', false),
        ('spd', 'Speed', 'SPD', false),
        ('emp', 'Empathy', 'EMP', false),
        ('cra', 'Craft', 'CRA', false),
        ('will', 'Will', 'WILL', false),
        ('luck', 'Luck', 'LUCK', false),
        ('stun', 'Stun', 'STUN', true),
        ('run', 'Run', 'RUN', true),
        ('leap', 'Leap', 'LEAP', true),
        ('sta', 'Stamina', 'STA', true),
        ('enc', 'Encumbrance', 'ENC', true),
        ('rec', 'Recovery', 'REC', true),
        ('hp', 'Hit Points', 'HP', true),
        ('vigor', 'Vigor', 'VIGOR', true)
      ) AS raw_data_en(param_id, name, short_name, is_calculated)
  ),
  ins_param_names AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id || '.wcc_params.' || raw_params.param_id || '.name') AS id
         , meta.entity, 'name', raw_params.lang, raw_params.name_text
      FROM raw_params
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
  ),
  ins_param_short_names AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id || '.wcc_params.' || raw_params.param_id || '.short_name') AS id
         , meta.entity, 'short_name', raw_params.lang, raw_params.short_name_text
      FROM raw_params
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
  )
INSERT INTO wcc_params (param_id, param_name_id, param_short_name_id, is_calculated)
SELECT DISTINCT
  raw_params.param_id,
  ck_id(meta.su_su_id || '.wcc_params.' || raw_params.param_id || '.name') AS param_name_id,
  ck_id(meta.su_su_id || '.wcc_params.' || raw_params.param_id || '.short_name') AS param_short_name_id,
  raw_params.is_calculated
FROM raw_params
CROSS JOIN meta
ON CONFLICT (param_id) DO NOTHING;

-- Вставка навыков
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id, 'wcc_skills' AS entity),
  raw_skills AS (
    SELECT 'ru' AS lang, raw_data_ru.*
      FROM (VALUES
        -- Common skills (INT)
        (1, 'awareness', 'Внимание', NULL, 'int', 'common', NULL, NULL, NULL, false),
        (2, 'business', 'Торговля', NULL, 'int', 'common', NULL, NULL, NULL, false),
        (3, 'deduction', 'Дедукция', NULL, 'int', 'common', NULL, NULL, NULL, false),
        (4, 'education', 'Образование', NULL, 'int', 'common', NULL, NULL, NULL, false),
        (5, 'language', 'Язык', NULL, 'int', 'common', NULL, NULL, NULL, true),
        (6, 'monster_lore', 'Монстрология', NULL, 'int', 'common', NULL, NULL, NULL, true),
        (7, 'social_etiquette', 'Этикет', NULL, 'int', 'common', NULL, NULL, NULL, false),
        (8, 'streetwise', 'Ориентирование в городе', NULL, 'int', 'common', NULL, NULL, NULL, false),
        (9, 'tactics', 'Тактика', NULL, 'int', 'common', NULL, NULL, NULL, true),
        (10, 'teaching', 'Передача знаний', NULL, 'int', 'common', NULL, NULL, NULL, false),
        (11, 'wilderness_survival', 'Выживание в дикой природе', NULL, 'int', 'common', NULL, NULL, NULL, false),
        -- Common skills (DEX)
        (12, 'archery', 'Стрельба из лука', NULL, 'dex', 'common', NULL, NULL, NULL, false),
        (13, 'athletics', 'Атлетика', NULL, 'dex', 'common', NULL, NULL, NULL, false),
        (14, 'crossbow', 'Стрельба из арбалета', NULL, 'dex', 'common', NULL, NULL, NULL, false),
        (15, 'sleight_of_hand', 'Ловкость рук', NULL, 'dex', 'common', NULL, NULL, NULL, false),
        (16, 'stealth', 'Скрытность', NULL, 'dex', 'common', NULL, NULL, NULL, false),
        -- Common skills (REF)
        (17, 'brawling', 'Борьба', NULL, 'ref', 'common', NULL, NULL, NULL, false),
        (18, 'dodge_escape', 'Уклонение/Изворотливость', NULL, 'ref', 'common', NULL, NULL, NULL, false),
        (19, 'melee', 'Ближний бой', NULL, 'ref', 'common', NULL, NULL, NULL, false),
        (20, 'riding', 'Верховая езда', NULL, 'ref', 'common', NULL, NULL, NULL, false),
        (21, 'sailing', 'Мореходство', NULL, 'ref', 'common', NULL, NULL, NULL, false),
        (22, 'small_blades', 'Владение лёгкими клинками', NULL, 'ref', 'common', NULL, NULL, NULL, false),
        (23, 'staff_spear', 'Владение древковым оружием', NULL, 'ref', 'common', NULL, NULL, NULL, false),
        (24, 'swordsmanship', 'Владение мечом', NULL, 'ref', 'common', NULL, NULL, NULL, false),
        -- Common skills (BODY)
        (25, 'physique', 'Сила', NULL, 'body', 'common', NULL, NULL, NULL, false),
        (26, 'endurance', 'Стойкость', NULL, 'body', 'common', NULL, NULL, NULL, false),
        -- Common skills (EMP)
        (27, 'charisma', 'Харизма', NULL, 'emp', 'common', NULL, NULL, NULL, false),
        (28, 'deceit', 'Обман', NULL, 'emp', 'common', NULL, NULL, NULL, false),
        (29, 'fine_arts', 'Искусство', NULL, 'emp', 'common', NULL, NULL, NULL, false),
        (30, 'gambling', 'Азартные игры', NULL, 'emp', 'common', NULL, NULL, NULL, false),
        (31, 'grooming_and_style', 'Внешний вид', NULL, 'emp', 'common', NULL, NULL, NULL, false),
        (32, 'human_perception', 'Понимание людей', NULL, 'emp', 'common', NULL, NULL, NULL, false),
        (33, 'leadership', 'Лидерство', NULL, 'emp', 'common', NULL, NULL, NULL, false),
        (34, 'persuasion', 'Убеждение', NULL, 'emp', 'common', NULL, NULL, NULL, false),
        (35, 'performance', 'Выступление', NULL, 'emp', 'common', NULL, NULL, NULL, false),
        (36, 'seduction', 'Соблазнение', NULL, 'emp', 'common', NULL, NULL, NULL, false),
        -- Common skills (CRA)
        (37, 'alchemy', 'Алхимия', NULL, 'cra', 'common', NULL, NULL, NULL, true),
        (38, 'crafting', 'Изготовление', NULL, 'cra', 'common', NULL, NULL, NULL, true),
        (39, 'disguise', 'Маскировка', NULL, 'cra', 'common', NULL, NULL, NULL, false),
        (40, 'first_aid', 'Первая помощь', NULL, 'cra', 'common', NULL, NULL, NULL, false),
        (41, 'forgery', 'Подделывание', NULL, 'cra', 'common', NULL, NULL, NULL, false),
        (42, 'pick_lock', 'Взлом замков', NULL, 'cra', 'common', NULL, NULL, NULL, false),
        (43, 'trap_crafting', 'Знание ловушек', NULL, 'cra', 'common', NULL, NULL, NULL, true),
        -- Common skills (WILL)
        (44, 'courage', 'Храбрость', NULL, 'will', 'common', NULL, NULL, NULL, false),
        (45, 'hex_weaving', 'Наведение порчи', NULL, 'will', 'common', NULL, NULL, NULL, true),
        (46, 'intimidation', 'Запугивание', NULL, 'will', 'common', NULL, NULL, NULL, false),
        (47, 'spell_casting', 'Сотворение заклинаний', NULL, 'will', 'common', NULL, NULL, NULL, true),
        (48, 'resist_magic', 'Сопротивление магии', NULL, 'will', 'common', NULL, NULL, NULL, true),
        (49, 'resist_coercion', 'Сопротивление убеждению', NULL, 'will', 'common', NULL, NULL, NULL, false),
        (50, 'ritual_crafting', 'Проведение ритуалов', NULL, 'will', 'common', NULL, NULL, NULL, true)
      ) AS raw_data_ru(skill_aid, skill_id, name, desc_text, param_id, skill_type, prof_num, branch_num, branch_name, is_difficult)
    UNION ALL
    SELECT 'en' AS lang, skill_aid, skill_id, name, desc_text, param_id, skill_type, prof_num, branch_num, branch_name, is_difficult
      FROM (VALUES
        -- Common skills (INT)
        (1, 'awareness', 'Awareness', NULL, 'int', 'common', NULL, NULL, NULL, false),
        (2, 'business', 'Business', NULL, 'int', 'common', NULL, NULL, NULL, false),
        (3, 'deduction', 'Deduction', NULL, 'int', 'common', NULL, NULL, NULL, false),
        (4, 'education', 'Education', NULL, 'int', 'common', NULL, NULL, NULL, false),
        (5, 'language', 'Language', NULL, 'int', 'common', NULL, NULL, NULL, true),
        (6, 'monster_lore', 'Monster Lore', NULL, 'int', 'common', NULL, NULL, NULL, true),
        (7, 'social_etiquette', 'Social Etiquette', NULL, 'int', 'common', NULL, NULL, NULL, false),
        (8, 'streetwise', 'Streetwise', NULL, 'int', 'common', NULL, NULL, NULL, false),
        (9, 'tactics', 'Tactics', NULL, 'int', 'common', NULL, NULL, NULL, true),
        (10, 'teaching', 'Teaching', NULL, 'int', 'common', NULL, NULL, NULL, false),
        (11, 'wilderness_survival', 'Wilderness Survival', NULL, 'int', 'common', NULL, NULL, NULL, false),
        -- Common skills (DEX)
        (12, 'archery', 'Archery', NULL, 'dex', 'common', NULL, NULL, NULL, false),
        (13, 'athletics', 'Athletics', NULL, 'dex', 'common', NULL, NULL, NULL, false),
        (14, 'crossbow', 'Crossbow', NULL, 'dex', 'common', NULL, NULL, NULL, false),
        (15, 'sleight_of_hand', 'Sleight of Hand', NULL, 'dex', 'common', NULL, NULL, NULL, false),
        (16, 'stealth', 'Stealth', NULL, 'dex', 'common', NULL, NULL, NULL, false),
        -- Common skills (REF)
        (17, 'brawling', 'Brawling', NULL, 'ref', 'common', NULL, NULL, NULL, false),
        (18, 'dodge_escape', 'Dodge/Escape', NULL, 'ref', 'common', NULL, NULL, NULL, false),
        (19, 'melee', 'Melee', NULL, 'ref', 'common', NULL, NULL, NULL, false),
        (20, 'riding', 'Riding', NULL, 'ref', 'common', NULL, NULL, NULL, false),
        (21, 'sailing', 'Sailing', NULL, 'ref', 'common', NULL, NULL, NULL, false),
        (22, 'small_blades', 'Small Blades', NULL, 'ref', 'common', NULL, NULL, NULL, false),
        (23, 'staff_spear', 'Staff/Spear', NULL, 'ref', 'common', NULL, NULL, NULL, false),
        (24, 'swordsmanship', 'Swordsmanship', NULL, 'ref', 'common', NULL, NULL, NULL, false),
        -- Common skills (BODY)
        (25, 'physique', 'Physique', NULL, 'body', 'common', NULL, NULL, NULL, false),
        (26, 'endurance', 'Endurance', NULL, 'body', 'common', NULL, NULL, NULL, false),
        -- Common skills (EMP)
        (27, 'charisma', 'Charisma', NULL, 'emp', 'common', NULL, NULL, NULL, false),
        (28, 'deceit', 'Deceit', NULL, 'emp', 'common', NULL, NULL, NULL, false),
        (29, 'fine_arts', 'Fine Arts', NULL, 'emp', 'common', NULL, NULL, NULL, false),
        (30, 'gambling', 'Gambling', NULL, 'emp', 'common', NULL, NULL, NULL, false),
        (31, 'grooming_and_style', 'Grooming & Style', NULL, 'emp', 'common', NULL, NULL, NULL, false),
        (32, 'human_perception', 'Human Perception', NULL, 'emp', 'common', NULL, NULL, NULL, false),
        (33, 'leadership', 'Leadership', NULL, 'emp', 'common', NULL, NULL, NULL, false),
        (34, 'persuasion', 'Persuasion', NULL, 'emp', 'common', NULL, NULL, NULL, false),
        (35, 'performance', 'Performance', NULL, 'emp', 'common', NULL, NULL, NULL, false),
        (36, 'seduction', 'Seduction', NULL, 'emp', 'common', NULL, NULL, NULL, false),
        -- Common skills (CRA)
        (37, 'alchemy', 'Alchemy', NULL, 'cra', 'common', NULL, NULL, NULL, true),
        (38, 'crafting', 'Crafting', NULL, 'cra', 'common', NULL, NULL, NULL, true),
        (39, 'disguise', 'Disguise', NULL, 'cra', 'common', NULL, NULL, NULL, false),
        (40, 'first_aid', 'First Aid', NULL, 'cra', 'common', NULL, NULL, NULL, false),
        (41, 'forgery', 'Forgery', NULL, 'cra', 'common', NULL, NULL, NULL, false),
        (42, 'pick_lock', 'Pick Lock', NULL, 'cra', 'common', NULL, NULL, NULL, false),
        (43, 'trap_crafting', 'Trap Crafting', NULL, 'cra', 'common', NULL, NULL, NULL, true),
        -- Common skills (WILL)
        (44, 'courage', 'Courage', NULL, 'will', 'common', NULL, NULL, NULL, false),
        (45, 'hex_weaving', 'Hex Weaving', NULL, 'will', 'common', NULL, NULL, NULL, true),
        (46, 'intimidation', 'Intimidation', NULL, 'will', 'common', NULL, NULL, NULL, false),
        (47, 'spell_casting', 'Spell Casting', NULL, 'will', 'common', NULL, NULL, NULL, true),
        (48, 'resist_magic', 'Resist Magic', NULL, 'will', 'common', NULL, NULL, NULL, true),
        (49, 'resist_coercion', 'Resist Coercion', NULL, 'will', 'common', NULL, NULL, NULL, false),
        (50, 'ritual_crafting', 'Ritual Crafting', NULL, 'will', 'common', NULL, NULL, NULL, true)
      ) AS raw_data_en(skill_aid, skill_id, name, desc_text, param_id, skill_type, prof_num, branch_num, branch_name, is_difficult)
  ),
  ins_skill_names AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id || '.wcc_skills.' || raw_skills.skill_id || '.name') AS id
         , meta.entity, 'name', raw_skills.lang, raw_skills.name
      FROM raw_skills
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
  )
INSERT INTO wcc_skills (skill_aid, skill_id, skill_name_id, skill_desc_id, param_param_id, skill_type, professional_number, branch_number, branch_name_id, is_difficult)
SELECT DISTINCT
  raw_skills.skill_aid,
  raw_skills.skill_id,
  ck_id(meta.su_su_id || '.wcc_skills.' || raw_skills.skill_id || '.name') AS skill_name_id,
  NULL::uuid AS skill_desc_id,
  raw_skills.param_id,
  raw_skills.skill_type,
  raw_skills.prof_num::integer AS professional_number,
  raw_skills.branch_num::integer AS branch_number,
  NULL::uuid AS branch_name_id,
  raw_skills.is_difficult
FROM raw_skills
CROSS JOIN meta
WHERE raw_skills.lang = 'ru'
ON CONFLICT (skill_aid) DO NOTHING;

-- Вставка определяющих навыков (main skills)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id, 'wcc_skills' AS entity),
  raw_main_skills AS (
    SELECT 'ru' AS lang, raw_data_ru.*
      FROM (VALUES
        (101, 'busking', 'Уличное выступление', 'emp', 'main'),
        (102, 'witcher_training', 'Подготовка ведьмака', 'int', 'main'),
        (103, 'healing_hands', 'Лечащее прикосновение', 'cra', 'main'),
        (104, 'magical_training', 'Магические познания', 'int', 'main'),
        (105, 'tough_as_nails', 'Крепче стали', 'body', 'main'),
        (106, 'dedicated', 'Посвящённый', 'emp', 'main'),
        (107, 'professional_paranoia', 'Профессиональная паранойя', 'int', 'main'),
        (108, 'quick_fix', 'Быстрый ремонт', 'cra', 'main'),
        (109, 'well_traveled', 'Бывалый путешественник', 'int', 'main')
      ) AS raw_data_ru(skill_aid, skill_id, name, param_id, skill_type)
    UNION ALL
    SELECT 'en' AS lang, skill_aid, skill_id, name, param_id, skill_type
      FROM (VALUES
        (101, 'busking', 'Busking', 'emp', 'main'),
        (102, 'witcher_training', 'Witcher Training', 'int', 'main'),
        (103, 'healing_hands', 'Healing Hands', 'cra', 'main'),
        (104, 'magical_training', 'Magical Training', 'int', 'main'),
        (105, 'tough_as_nails', 'Tough As Nails', 'body', 'main'),
        (106, 'dedicated', 'Dedicated', 'emp', 'main'),
        (107, 'professional_paranoia', 'Professional Paranoia', 'int', 'main'),
        (108, 'quick_fix', 'Quick Fix', 'cra', 'main'),
        (109, 'well_traveled', 'Well Traveled', 'int', 'main')
      ) AS raw_data_en(skill_aid, skill_id, name, param_id, skill_type)
  ),
  ins_main_skill_names AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id || '.wcc_skills.' || raw_main_skills.skill_id || '.name') AS id
         , meta.entity, 'name', raw_main_skills.lang, raw_main_skills.name
      FROM raw_main_skills
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
  )
INSERT INTO wcc_skills (skill_aid, skill_id, skill_name_id, skill_desc_id, param_param_id, skill_type, professional_number, branch_number, branch_name_id, is_difficult)
SELECT DISTINCT
  raw_main_skills.skill_aid,
  raw_main_skills.skill_id,
  ck_id(meta.su_su_id || '.wcc_skills.' || raw_main_skills.skill_id || '.name') AS skill_name_id,
  NULL::uuid AS skill_desc_id,
  raw_main_skills.param_id,
  raw_main_skills.skill_type,
  NULL::integer,
  NULL::integer,
  NULL::uuid,
  false
FROM raw_main_skills
CROSS JOIN meta
WHERE raw_main_skills.lang = 'ru'
ON CONFLICT (skill_id) DO NOTHING;

-- Вставка профессиональных навыков (professional skills)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id, 'wcc_skills' AS entity),
  raw_prof_skills AS (
    SELECT 'ru' AS lang, raw_data_ru.*
      FROM (VALUES
        -- Bard branch 1: Обольститель
        (201, 'return_act', 'Повторное выступление', 'emp', 'professional', 1, 1, 'Обольститель', false),
        (202, 'raise_a_crowd', 'Заворожить публику', 'emp', 'professional', 2, 1, 'Обольститель', false),
        (203, 'good_friend', 'Добрый друг', 'emp', 'professional', 3, 1, 'Обольститель', false),
        -- Bard branch 2: Информатор
        (204, 'fade', 'Незаметность', 'int', 'professional', 1, 2, 'Информатор', false),
        (205, 'spread_the_word', 'Пустить слух', 'int', 'professional', 2, 2, 'Информатор', false),
        (206, 'acclimatize', 'Сойти за своего', 'int', 'professional', 3, 2, 'Информатор', false),
        -- Bard branch 3: Интриган
        (207, 'poison_the_well', 'Коварство', 'emp', 'professional', 1, 3, 'Интриган', false),
        (208, 'needling', 'Подколка', 'emp', 'professional', 2, 3, 'Интриган', false),
        (209, 'et_tu_brute', 'И ты, Брут', 'emp', 'professional', 3, 3, 'Интриган', false),
        -- Witcher branch 1: Магический клинок
        (210, 'meditation', 'Медитация', NULL, 'professional', 1, 1, 'Магический клинок', false),
        (211, 'magical_source', 'Магический источник', NULL, 'professional', 2, 1, 'Магический клинок', false),
        (212, 'heliotrope', 'Гелиотроп', 'will', 'professional', 3, 1, 'Магический клинок', false),
        -- Witcher branch 2: Мутант
        (213, 'iron_stomach', 'Крепкий желудок', NULL, 'professional', 1, 2, 'Мутант', false),
        (214, 'frenzy', 'Ярость', NULL, 'professional', 2, 2, 'Мутант', false),
        (215, 'transmutation', 'Трансмутация', 'body', 'professional', 3, 2, 'Мутант', false),
        -- Witcher branch 3: Убийца
        (216, 'parry_arrows', 'Отбивание стрел', 'dex', 'professional', 1, 3, 'Убийца', false),
        (217, 'quick_strike', 'Быстрый удар', 'ref', 'professional', 2, 3, 'Убийца', false),
        (218, 'whirl', 'Вихрь', 'ref', 'professional', 3, 3, 'Убийца', false),
        -- Mage branch 1: Политик
        (219, 'scheming', 'Строить козни', 'int', 'professional', 1, 1, 'Политик', false),
        (220, 'grape_vine', 'Сплетни', 'int', 'professional', 2, 1, 'Политик', false),
        (221, 'assets', 'Полезные связи', 'int', 'professional', 3, 1, 'Политик', false),
        -- Mage branch 2: Учёный
        (222, 'reverse_engineer', 'Анализ', 'int', 'professional', 1, 2, 'Учёный', false),
        (223, 'distillation', 'Дистилляция', 'cra', 'professional', 2, 2, 'Учёный', false),
        (224, 'mutate', 'Мутация', 'int', 'professional', 3, 2, 'Учёный', false),
        -- Mage branch 3: Архимаг
        (225, 'in_touch', 'Укрепление связи', NULL, 'professional', 1, 3, 'Архимаг', false),
        (226, 'immutable', 'Устойчивость к двимериту', 'will', 'professional', 2, 3, 'Архимаг', false),
        (227, 'expanded_magic', 'Усиление магии', 'will', 'professional', 3, 3, 'Архимаг', false),
        -- Doctor branch 1: Хирург
        (228, 'diagnose', 'Диагноз', 'int', 'professional', 1, 1, 'Хирург', false),
        (229, 'analysis', 'Осмотр', 'int', 'professional', 2, 1, 'Хирург', false),
        (230, 'effective_surgery', 'Эффективная хирургия', 'cra', 'professional', 3, 1, 'Хирург', false),
        -- Doctor branch 2: Травник
        (231, 'healing_tent', 'Палатка лекаря', 'cra', 'professional', 1, 2, 'Травник', false),
        (232, 'improvised_medicine', 'Подручные средства', 'int', 'professional', 2, 2, 'Травник', false),
        (233, 'herbal_remedy', 'Растительное лекарство', 'cra', 'professional', 3, 2, 'Травник', false),
        -- Doctor branch 3: Анатом
        (234, 'bloody_wound', 'Кровавая рана', 'int', 'professional', 1, 3, 'Анатом', false),
        (235, 'practical_butchery', 'Практическая резня', 'int', 'professional', 2, 3, 'Анатом', false),
        (236, 'crippling_wound', 'Калечащая рана', 'int', 'professional', 3, 3, 'Анатом', false),
        -- Man At Arms branch 1: Стрелок
        (237, 'extreme_range', 'Максимальная дистанция', 'dex', 'professional', 1, 1, 'Стрелок', false),
        (238, 'twin_shot', 'Двойной выстрел', 'dex', 'professional', 2, 1, 'Стрелок', false),
        (239, 'precise_aim', 'Точный прицел', 'dex', 'professional', 3, 1, 'Стрелок', false),
        -- Man At Arms branch 2: Охотник за головами
        (240, 'bloodhound', 'Ищейка', 'int', 'professional', 1, 2, 'Охотник за головами', false),
        (241, 'warrior_trap', 'Ловушка воина', 'cra', 'professional', 2, 2, 'Охотник за головами', false),
        (242, 'tactical_advantage', 'Тактическое преимущество', 'int', 'professional', 3, 2, 'Охотник за головами', false),
        -- Man At Arms branch 3: Потрошитель
        (243, 'fury', 'Неистовство', 'will', 'professional', 1, 3, 'Потрошитель', false),
        (244, 'two_handed', 'Двуручник', 'body', 'professional', 2, 3, 'Потрошитель', false),
        (245, 'ignore_pain', 'Игнорировать удар', 'body', 'professional', 3, 3, 'Потрошитель', false),
        -- Priest branch 1: Проповедник
        (246, 'divine_power', 'Божественная сила', NULL, 'professional', 1, 1, 'Проповедник', false),
        (247, 'divine_authority', 'Божественный авторитет', 'emp', 'professional', 2, 1, 'Проповедник', false),
        (248, 'foresight', 'Предвидение', 'will', 'professional', 3, 1, 'Проповедник', false),
        -- Priest branch 2: Друид
        (249, 'one_with_nature', 'Единение с природой', NULL, 'professional', 1, 2, 'Друид', false),
        (250, 'nature_s_signs', 'Знаки природы', 'int', 'professional', 2, 2, 'Друид', false),
        (251, 'nature_s_ally', 'Союзник природы', 'will', 'professional', 3, 2, 'Друид', false),
        -- Priest branch 3: Фанатик
        (252, 'bloody_rituals', 'Кровавые ритуалы', 'will', 'professional', 1, 3, 'Фанатик', false),
        (253, 'zeal', 'Рвение', 'emp', 'professional', 2, 3, 'Фанатик', false),
        (254, 'holy_fire', 'Священный огонь', 'will', 'professional', 3, 3, 'Фанатик', false),
        -- Criminal branch 1: Вор
        (255, 'case_joint', 'Присмотреться', 'int', 'professional', 1, 1, 'Вор', false),
        (256, 'repeat_lockpick', 'Повторный взлом', 'int', 'professional', 2, 1, 'Вор', false),
        (257, 'lay_low', 'Залечь на дно', 'int', 'professional', 3, 1, 'Вор', false),
        -- Criminal branch 2: Атаман
        (258, 'vulnerability', 'Уязвимость', 'emp', 'professional', 1, 2, 'Атаман', false),
        (259, 'take_note', 'Взять на заметку', 'will', 'professional', 2, 2, 'Атаман', false),
        (260, 'intimidating_presence', 'Устрашающее присутствие', 'will', 'professional', 3, 2, 'Атаман', false),
        -- Criminal branch 3: Контрабандист
        (261, 'smuggler', 'Контрабандист', 'int', 'professional', 1, 3, 'Контрабандист', false),
        (262, 'false_identity', 'Поддельная личность', 'cra', 'professional', 2, 3, 'Контрабандист', false),
        (263, 'black_market', 'Чёрный рынок', 'int', 'professional', 3, 3, 'Контрабандист', false),
        -- Craftsman branch 1: Оружейник
        (264, 'large_catalog', 'Большой каталог', 'int', 'professional', 1, 1, 'Оружейник', false),
        (265, 'apprentice', 'Подмастерье', 'cra', 'professional', 2, 1, 'Оружейник', false),
        (266, 'masterwork', 'Мастерская работа', 'cra', 'professional', 3, 1, 'Оружейник', false),
        -- Craftsman branch 2: Алхимик
        (267, 'alchemical_concoction', 'Алхимический состав', 'cra', 'professional', 1, 2, 'Алхимик', false),
        (268, 'enhanced_potion', 'Усиленный эликсир', 'cra', 'professional', 2, 2, 'Алхимик', false),
        (269, 'experimental_formula', 'Экспериментальная формула', 'cra', 'professional', 3, 2, 'Алхимик', false),
        -- Craftsman branch 3: Мастер
        (270, 'workshop', 'Мастерская', NULL, 'professional', 1, 3, 'Мастер', false),
        (271, 'repair', 'Ремонт', 'cra', 'professional', 2, 3, 'Мастер', false),
        (272, 'upgrade', 'Улучшение', 'cra', 'professional', 3, 3, 'Мастер', false),
        -- Merchant branch 1: Посредник
        (273, 'market', 'Рынок', 'int', 'professional', 1, 1, 'Посредник', false),
        (274, 'dirty_deal', 'Нечестная сделка', 'emp', 'professional', 2, 1, 'Посредник', false),
        (275, 'promise', 'Обещание', 'emp', 'professional', 3, 1, 'Посредник', false),
        -- Merchant branch 2: Человек со связями
        (276, 'slums', 'Трущобы', 'emp', 'professional', 1, 2, 'Человек со связями', false),
        (277, 'contacts', 'Связи', 'int', 'professional', 2, 2, 'Человек со связями', false),
        (278, 'merchant_network', 'Торговая сеть', 'int', 'professional', 3, 2, 'Человек со связями', false),
        -- Merchant branch 3: Торговец
        (279, 'haggle', 'Торг', 'emp', 'professional', 1, 3, 'Торговец', false),
        (280, 'merchant_sense', 'Торговая жилка', 'int', 'professional', 2, 3, 'Торговец', false),
        (281, 'merchant_king', 'Король торговли', 'int', 'professional', 3, 3, 'Торговец', false)
      ) AS raw_data_ru(skill_aid, skill_id, name, param_id, skill_type, prof_num, branch_num, branch_name, is_difficult)
    UNION ALL
    SELECT 'en' AS lang, skill_aid, skill_id, name, param_id, skill_type, prof_num, branch_num, branch_name, is_difficult
      FROM (VALUES
        -- Bard branch 1: The Charmer
        (201, 'return_act', 'Return Act', 'emp', 'professional', 1, 1, 'The Charmer', false),
        (202, 'raise_a_crowd', 'Raise A Crowd', 'emp', 'professional', 2, 1, 'The Charmer', false),
        (203, 'good_friend', 'Good Friend', 'emp', 'professional', 3, 1, 'The Charmer', false),
        -- Bard branch 2: The Informant
        (204, 'fade', 'Fade', 'int', 'professional', 1, 2, 'The Informant', false),
        (205, 'spread_the_word', 'Spread the Word', 'int', 'professional', 2, 2, 'The Informant', false),
        (206, 'acclimatize', 'Acclimatize', 'int', 'professional', 3, 2, 'The Informant', false),
        -- Bard branch 3: The Manipulator
        (207, 'poison_the_well', 'Poison The Well', 'emp', 'professional', 1, 3, 'The Manipulator', false),
        (208, 'needling', 'Needling', 'emp', 'professional', 2, 3, 'The Manipulator', false),
        (209, 'et_tu_brute', 'Et Tu Brute', 'emp', 'professional', 3, 3, 'The Manipulator', false),
        -- Witcher branch 1: The Spellsword
        (210, 'meditation', 'Meditation', NULL, 'professional', 1, 1, 'The Spellsword', false),
        (211, 'magical_source', 'Magical Source', NULL, 'professional', 2, 1, 'The Spellsword', false),
        (212, 'heliotrope', 'Heliotrope', 'will', 'professional', 3, 1, 'The Spellsword', false),
        -- Witcher branch 2: The Mutant
        (213, 'iron_stomach', 'Iron Stomach', NULL, 'professional', 1, 2, 'The Mutant', false),
        (214, 'frenzy', 'Frenzy', NULL, 'professional', 2, 2, 'The Mutant', false),
        (215, 'transmutation', 'Transmutation', 'body', 'professional', 3, 2, 'The Mutant', false),
        -- Witcher branch 3: The Slayer
        (216, 'parry_arrows', 'Parry Arrows', 'dex', 'professional', 1, 3, 'The Slayer', false),
        (217, 'quick_strike', 'Quick Strike', 'ref', 'professional', 2, 3, 'The Slayer', false),
        (218, 'whirl', 'Whirl', 'ref', 'professional', 3, 3, 'The Slayer', false),
        -- Mage branch 1: The Politician
        (219, 'scheming', 'Scheming', 'int', 'professional', 1, 1, 'The Politician', false),
        (220, 'grape_vine', 'Grape Vine', 'int', 'professional', 2, 1, 'The Politician', false),
        (221, 'assets', 'Assets', 'int', 'professional', 3, 1, 'The Politician', false),
        -- Mage branch 2: The Scientist
        (222, 'reverse_engineer', 'Reverse Engineer', 'int', 'professional', 1, 2, 'The Scientist', false),
        (223, 'distillation', 'Distillation', 'cra', 'professional', 2, 2, 'The Scientist', false),
        (224, 'mutate', 'Mutate', 'int', 'professional', 3, 2, 'The Scientist', false),
        -- Mage branch 3: The Arch Mage
        (225, 'in_touch', 'In Touch', NULL, 'professional', 1, 3, 'The Arch Mage', false),
        (226, 'immutable', 'Immutable', 'will', 'professional', 2, 3, 'The Arch Mage', false),
        (227, 'expanded_magic', 'Expanded Magic', 'will', 'professional', 3, 3, 'The Arch Mage', false),
        -- Doctor branch 1: The Surgeon
        (228, 'diagnose', 'Diagnose', 'int', 'professional', 1, 1, 'The Surgeon', false),
        (229, 'analysis', 'Analysis', 'int', 'professional', 2, 1, 'The Surgeon', false),
        (230, 'effective_surgery', 'Effective Surgery', 'cra', 'professional', 3, 1, 'The Surgeon', false),
        -- Doctor branch 2: The Herbalist
        (231, 'healing_tent', 'Healing Tent', 'cra', 'professional', 1, 2, 'The Herbalist', false),
        (232, 'improvised_medicine', 'Improvised Medicine', 'int', 'professional', 2, 2, 'The Herbalist', false),
        (233, 'herbal_remedy', 'Herbal Remedy', 'cra', 'professional', 3, 2, 'The Herbalist', false),
        -- Doctor branch 3: The Anatomist
        (234, 'bloody_wound', 'Bloody Wound', 'int', 'professional', 1, 3, 'The Anatomist', false),
        (235, 'practical_butchery', 'Practical Butchery', 'int', 'professional', 2, 3, 'The Anatomist', false),
        (236, 'crippling_wound', 'Crippling Wound', 'int', 'professional', 3, 3, 'The Anatomist', false),
        -- Man At Arms branch 1: The Marksman
        (237, 'extreme_range', 'Extreme Range', 'dex', 'professional', 1, 1, 'The Marksman', false),
        (238, 'twin_shot', 'Twin Shot', 'dex', 'professional', 2, 1, 'The Marksman', false),
        (239, 'precise_aim', 'Precise Aim', 'dex', 'professional', 3, 1, 'The Marksman', false),
        -- Man At Arms branch 2: The Bounty Hunter
        (240, 'bloodhound', 'Bloodhound', 'int', 'professional', 1, 2, 'The Bounty Hunter', false),
        (241, 'warrior_trap', 'Warrior Trap', 'cra', 'professional', 2, 2, 'The Bounty Hunter', false),
        (242, 'tactical_advantage', 'Tactical Advantage', 'int', 'professional', 3, 2, 'The Bounty Hunter', false),
        -- Man At Arms branch 3: The Butcher
        (243, 'fury', 'Fury', 'will', 'professional', 1, 3, 'The Butcher', false),
        (244, 'two_handed', 'Two Handed', 'body', 'professional', 2, 3, 'The Butcher', false),
        (245, 'ignore_pain', 'Ignore Pain', 'body', 'professional', 3, 3, 'The Butcher', false),
        -- Priest branch 1: The Preacher
        (246, 'divine_power', 'Divine Power', NULL, 'professional', 1, 1, 'The Preacher', false),
        (247, 'divine_authority', 'Divine Authority', 'emp', 'professional', 2, 1, 'The Preacher', false),
        (248, 'foresight', 'Foresight', 'will', 'professional', 3, 1, 'The Preacher', false),
        -- Priest branch 2: The Druid
        (249, 'one_with_nature', 'One With Nature', NULL, 'professional', 1, 2, 'The Druid', false),
        (250, 'nature_s_signs', 'Nature''s Signs', 'int', 'professional', 2, 2, 'The Druid', false),
        (251, 'nature_s_ally', 'Nature''s Ally', 'will', 'professional', 3, 2, 'The Druid', false),
        -- Priest branch 3: The Fanatic
        (252, 'bloody_rituals', 'Bloody Rituals', 'will', 'professional', 1, 3, 'The Fanatic', false),
        (253, 'zeal', 'Zeal', 'emp', 'professional', 2, 3, 'The Fanatic', false),
        (254, 'holy_fire', 'Holy Fire', 'will', 'professional', 3, 3, 'The Fanatic', false),
        -- Criminal branch 1: The Thief
        (255, 'case_joint', 'Case Joint', 'int', 'professional', 1, 1, 'The Thief', false),
        (256, 'repeat_lockpick', 'Repeat Lockpick', 'int', 'professional', 2, 1, 'The Thief', false),
        (257, 'lay_low', 'Lay Low', 'int', 'professional', 3, 1, 'The Thief', false),
        -- Criminal branch 2: The Leader
        (258, 'vulnerability', 'Vulnerability', 'emp', 'professional', 1, 2, 'The Leader', false),
        (259, 'take_note', 'Take Note', 'will', 'professional', 2, 2, 'The Leader', false),
        (260, 'intimidating_presence', 'Intimidating Presence', 'will', 'professional', 3, 2, 'The Leader', false),
        -- Criminal branch 3: The Smuggler
        (261, 'smuggler', 'Smuggler', 'int', 'professional', 1, 3, 'The Smuggler', false),
        (262, 'false_identity', 'False Identity', 'cra', 'professional', 2, 3, 'The Smuggler', false),
        (263, 'black_market', 'Black Market', 'int', 'professional', 3, 3, 'The Smuggler', false),
        -- Craftsman branch 1: The Weaponsmith
        (264, 'large_catalog', 'Large Catalog', 'int', 'professional', 1, 1, 'The Weaponsmith', false),
        (265, 'apprentice', 'Apprentice', 'cra', 'professional', 2, 1, 'The Weaponsmith', false),
        (266, 'masterwork', 'Masterwork', 'cra', 'professional', 3, 1, 'The Weaponsmith', false),
        -- Craftsman branch 2: The Alchemist
        (267, 'alchemical_concoction', 'Alchemical Concoction', 'cra', 'professional', 1, 2, 'The Alchemist', false),
        (268, 'enhanced_potion', 'Enhanced Potion', 'cra', 'professional', 2, 2, 'The Alchemist', false),
        (269, 'experimental_formula', 'Experimental Formula', 'cra', 'professional', 3, 2, 'The Alchemist', false),
        -- Craftsman branch 3: The Master
        (270, 'workshop', 'Workshop', NULL, 'professional', 1, 3, 'The Master', false),
        (271, 'repair', 'Repair', 'cra', 'professional', 2, 3, 'The Master', false),
        (272, 'upgrade', 'Upgrade', 'cra', 'professional', 3, 3, 'The Master', false),
        -- Merchant branch 1: The Middleman
        (273, 'market', 'Market', 'int', 'professional', 1, 1, 'The Middleman', false),
        (274, 'dirty_deal', 'Dirty Deal', 'emp', 'professional', 2, 1, 'The Middleman', false),
        (275, 'promise', 'Promise', 'emp', 'professional', 3, 1, 'The Middleman', false),
        -- Merchant branch 2: The Connected
        (276, 'slums', 'Slums', 'emp', 'professional', 1, 2, 'The Connected', false),
        (277, 'contacts', 'Contacts', 'int', 'professional', 2, 2, 'The Connected', false),
        (278, 'merchant_network', 'Merchant Network', 'int', 'professional', 3, 2, 'The Connected', false),
        -- Merchant branch 3: The Merchant
        (279, 'haggle', 'Haggle', 'emp', 'professional', 1, 3, 'The Merchant', false),
        (280, 'merchant_sense', 'Merchant Sense', 'int', 'professional', 2, 3, 'The Merchant', false),
        (281, 'merchant_king', 'Merchant King', 'int', 'professional', 3, 3, 'The Merchant', false)
      ) AS raw_data_en(skill_aid, skill_id, name, param_id, skill_type, prof_num, branch_num, branch_name, is_difficult)
  ),
  ins_prof_skill_names AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id || '.wcc_skills.' || raw_prof_skills.skill_id || '.name') AS id
         , meta.entity, 'name', raw_prof_skills.lang, raw_prof_skills.name
      FROM raw_prof_skills
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
  ),
  ins_branch_names AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT DISTINCT
      ck_id(meta.su_su_id || '.wcc_skills.branch.' || 
        LOWER(REPLACE(REPLACE(REPLACE(raw_prof_skills.branch_name, ' ', '_'), '/', '_'), '&', 'and')) || '.name') AS id
         , meta.entity, 'branch_name', raw_prof_skills.lang, raw_prof_skills.branch_name
      FROM raw_prof_skills
      CROSS JOIN meta
      WHERE raw_prof_skills.branch_name IS NOT NULL
    ON CONFLICT (id, lang) DO NOTHING
  )
INSERT INTO wcc_skills (skill_aid, skill_id, skill_name_id, skill_desc_id, param_param_id, skill_type, professional_number, branch_number, branch_name_id, is_difficult)
SELECT DISTINCT
  raw_prof_skills.skill_aid,
  raw_prof_skills.skill_id,
  ck_id(meta.su_su_id || '.wcc_skills.' || raw_prof_skills.skill_id || '.name') AS skill_name_id,
  NULL::uuid AS skill_desc_id,
  raw_prof_skills.param_id,
  raw_prof_skills.skill_type,
  raw_prof_skills.prof_num::integer AS professional_number,
  raw_prof_skills.branch_num::integer AS branch_number,
  CASE 
    WHEN raw_prof_skills.branch_name IS NOT NULL THEN
      ck_id(meta.su_su_id || '.wcc_skills.branch.' || 
        LOWER(REPLACE(REPLACE(REPLACE(raw_prof_skills.branch_name, ' ', '_'), '/', '_'), '&', 'and')) || '.name')
    ELSE NULL
  END AS branch_name_id,
  raw_prof_skills.is_difficult
FROM raw_prof_skills
CROSS JOIN meta
WHERE raw_prof_skills.lang = 'ru'
ON CONFLICT (skill_aid) DO NOTHING;

-- Вставка описаний определяющих навыков (main skills)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id, 'wcc_skills' AS entity),
  raw_main_skill_descriptions AS (
    SELECT 'ru' AS lang, skill_id, description
      FROM (VALUES
        ('busking', 'Бард весьма полезен в группе, особенно когда у вас не хватает денег. Бард может потратить час времени и совершить проверку <strong>Уличного выступления</strong> в центре ближайшего города. Результат броска — это сумма, которую бард заработал за время уличного выступления. Критический провал может снизить результат броска. Отрицательный результат означает, что бард не только не заработал денег, но и был освистан местными, что даёт ему штраф -2 к Харизме при контакте со всеми в этом городе на остаток дня.<br><br>При попытке заворожить публику на достаточно большой площади с множеством людей успешно пройденная проверка со СЛ 15 позволяет создать вокруг барда плотную толпу, для прохода через которую требуется проверка Силы или Атлетики со СЛ 15. Помните, что враги и неразумные существа получают бонус +10 против завораживания.'),
        ('witcher_training', 'Большинство ведьмаков проводят детство и юность в крепости, корпя над пыльными томами и проходя чудовищные боевые тренировки. Многие говорят, что главное оружие ведьмака — это знания о чудовищах и умение найти выход из любой ситуации. Находясь в опасной среде или на пересечённой местности, ведьмак может снизить соответствующие штрафы на половину значения своего навыка <strong>Подготовка ведьмака</strong> (минимум 1). <strong>Подготовку ведьмака</strong> также можно использовать в любой ситуации, где понадобился бы навык <strong>Монстрология</strong>.'),
        ('healing_hands', 'Кто угодно может перевязать рану, но только у медика достаточно знаний, чтобы Лечение критических ранений Подробнее о лечении критических ранений см. на стр. 173. проводить сложные хирургические операции. Медик с навыком <strong>Лечащее прикосновение</strong> — единственный, кто способен вылечить критическое ранение. Для исцеления критического ранения медик должен успешно совершить несколько проверок <strong>Лечащего прикосновения</strong> — число их зависит от серьёзности критического ранения. СЛ проверки также зависит от серьёзности критического ранения. Помимо этого, <strong>Лечащее прикосновение</strong> можно использовать вместо проверки Первой помощи.'),
        ('magical_training', 'Для того чтобы стать полноправным магом, способный к магии адепт должен пройти обучение в одной из магических академий. Маг может совершить проверку <strong>Магических познаний</strong>, если ему попадётся магический феномен, если он увидит незнакомое заклинание или захочет узнать ответ на какой-то теоретический вопрос. СЛ проверки определяется ведущим. При успехе маг узнаёт всё, что касается данного магического феномена. Проверка <strong>Магических познаний</strong> также может заменить проверку Внимания для обнаружения использованной магии и духов.'),
        ('tough_as_nails', 'Настоящие воины — будь то темерские «Синие полоски» или нильфгаардцы из бригады «Импера» — никогда не сдаются. Когда ПЗ воина опускается до 0 или ниже, он может совершить проверку навыка <strong>Крепче стали</strong> со СЛ, равной количеству отрицательных ПЗ х 2, чтобы продолжить сражаться. При провале воин оказывается при смерти. При успехе он может продолжать сражение, как если бы его ПЗ были ниже порога ранения. Получив урон, он вновь должен совершить проверку со СЛ, зависящей от его ПЗ.'),
        ('dedicated', 'В большинстве церквей мира рады посетителям. Служители храмов помогают местным жителям и с радостью принимают новообращённых в свою веру. Жрец может совершить проверку навыка <strong>Посвящённый</strong> (СЛ определяет ведущий) в храме своей религии, чтобы получить бесплатный кров, исцеление и прочие услуги на усмотрение ведущего. Навык <strong>Посвящённый</strong> также можно использовать при общении с единоверцами, но получите вы куда меньше, чем в церкви. <strong>Посвящённый</strong> не действует при общении с теми, кто исповедует другую веру.'),
        ('professional_paranoia', 'Все преступники, будь то убийцы, воры, фальшивомонетчики или контрабандисты, обладают обострённым чутьём на опасность — фактически профессиональной паранойей, благодаря которой они избегают поимки. Когда преступник оказывается в пределах 10 метров от ловушки (включая экспериментальные ловушки, ловушки воина и засады), он может немедленно совершить проверку <strong>Профессиональной паранойи</strong> либо против СЛ обнаружения ловушки, либо против Скрытности засады, либо против заданной ведущим СЛ. Даже если преступник не заметит ловушки, чутьё всё равно ему подскажет, что тут что-то не так.'),
        ('quick_fix', 'Умелый ремесленник способен наскоро подлатать оружие или броню, чтобы их владелец мог продолжать сражаться. Ремесленник свяжет вместе обрывки лопнувшей тетивы, заострит край сломанного клинка или приколотит металлическую пластину поверх треснувшего щита. Ремесленник может потратить ход и совершить проверку <strong>Быстрого ремонта</strong> со сложностью, равной СЛ Изготовления данного предмета минус 3, чтобы восстановить 1/2 прочности брони или 1/2 надёжности сломанного оружия или щита. Пока оружие после <strong>Быстрого ремонта</strong> не починят в кузнице, оно наносит половину обычного урона.<br><br><strong>Слишком много поломок</strong><br>Ранее подлатанное оружие, щит или броню после повторной поломки можно подлатать ещё только один раз. Во второй раз <strong>Быстрый ремонт</strong> восстановит лишь 1/4 значения надёжности/прочности (с округлением вниз).'),
        ('well_traveled', 'Обычный торговец зарабатывает на жизнь тем, что продаёт товар приходящим к нему покупателям. Странствующий же торговец сам приходит к покупателю. Он ездит по миру и узнаёт обо всём, что там происходит. Торговец может в любой момент по своему желанию совершить проверку навыка <strong>Бывалый путешественник</strong>, чтобы узнать один факт об определённом предмете, культуре или области. СЛ проверки определяет ведущий. При успехе торговец получает ответ на вопрос, вспомнив те времена, когда он в прошлый раз был в этом месте.')
      ) AS raw_data_ru(skill_id, description)
    UNION ALL
    SELECT 'en' AS lang, skill_id, description
      FROM (VALUES
        ('busking', 'A Bard is a wonderful thing to have around, especially when the party''s low on money. A Bard can take an hour and make a Busking roll in the nearest town center. The total of this roll is the amount of money raked in by the Bard while they perform on the street. A fumble can lower the roll, and a negative value means that not only do you fail to make any coin but you are also harrassed by the locals for your poor performance, resulting in a −2 to Charisma with anyone in the town for the rest of the day.<br><br>When raising a crowd in a large area full of people, a DC:15 is sufficient to create a crowd around the Bard dense enough to require a DC:15 Physique or Athletics check to pass through. Also keep in mind that enemies and non-sentient creatures gain a +10 to resist.'),
        ('witcher_training', 'Most of a Witcher''s early life is spent within the walls of their keep, studying huge, dusty tomes and going through hellish combat training. Many have argued that the Witcher''s greatest weapon is their knowledge of monsters and their adaptability in any situation. When in a hostile environment or difficult terrain, a Witcher can lessen the penalties by half their <strong>Witcher Training</strong> value (minimum 1). <strong>Witcher Training</strong> can also be used in any situation that you would normally use Monster Lore for.'),
        ('healing_hands', 'Anyone can apply some ointment and wrap a bandage around a cut, but a Doctor has true medical training which allows them to perform complex surgeries. A Doctor with <strong>Healing Hands</strong> is the only person who can heal a critical wound. To heal critical wounds a doctor must make a number of successful <strong>Healing Hands</strong> rolls based on the severity of the critical wound. The DC of the roll is based on the severity of the critical wound as well. <strong>Healing Hands</strong> can also be used for any First Aid task.'),
        ('magical_training', 'To qualify as a Mage, a magically adept person must pass through the halls of one of the world''s magical academies and learn the fundamentals of the magical arts. A Mage can roll <strong>Magical Training</strong> whenever they encounter a magical phenomenon, an unknown spell, or a question of magical theory. The DC is set by the GM, and a success allows the Mage to recall everything there is to know about the phenomenon. <strong>Magical Training</strong> can also be rolled as a form of Awareness that detects magic that is in use, or specters.'),
        ('tough_as_nails', 'True Men At Arms like the Blue Stripes of Temeria and the Impera Brigade of Nilfgaard are hardened soldiers who never give in or surrender. When a Man At Arms falls to or below 0 Health, they can roll <strong>Tough As Nails</strong> at a DC equal to the number of negative Health times 2 to keep fighting. If they fail, they fall into death state as per usual. If they succeed they can keep fighting as if they were only at their Wound Threshold. Any damage forces them to make another roll against a DC based on their Health.'),
        ('dedicated', 'The churches of the world are often warm and inviting places, helping their communities and welcoming new converts. A Priest can roll <strong>Initiate of the Gods</strong> at a DC set by the GM at churches of the same faith to get free lodging, healing, and other services at the GM''s discretion. <strong>Initiate of the Gods</strong> also works when dealing with members of the same faith, though they will likely be able to offer less than a fully supplied church. Keep in mind that <strong>Initiate of the Gods</strong> doesn''t work with members of other faiths.'),
        ('professional_paranoia', 'Whether they''re an assassin, a thief, a counterfeitter, or a smuggler, criminals all share a practiced paranoia that keeps them out of trouble. Whenever a Criminal comes within 10m of a trap (this includes experimental traps, Man at Arms booby traps, and ambushes) they immediately can make a <strong>Practiced Paranoia</strong> roll at either the DC to spot the trap, the ambushing party''s Stealth roll, or a DC set by the GM. Even if they don''t succeed in spotting the trap, they are still aware that something is wrong.'),
        ('quick_fix', 'A skilled craftsman can patch a weapon or armor well enough to keep it working and keep its wearer/wielder in the fight, whether that be by tying a bowstring back together, sharpening the edge of a broken blade, or nailing a plate over a cracked shield. By taking a turn to roll <strong>Patch Job</strong> at a DC equal to the item''s Crafting DC-3 a Craftsman can restore a broken shield or armor to half its full SP or restore a broken weapon to half its durability. Until fixed at a forge, a patched weapon does half its normal damage.<br><br><strong>Too Many Patches</strong><br>A weapon, shield, or armor which has already been patched once can only be patched again 1 more time, and this patch only brings it to 1/4th SP/Durability (rounding down).'),
        ('well_traveled', 'Your average merchant makes a living from trade, and that trade brings in customers from all around. But a traveling merchant goes to their customers, wandering the roads of the world and learning from its people. A Merchant can make a <strong>Well Traveled</strong> roll any time they want to know a fact about a specific item, culture, or area. The DC is set by the GM, and if the roll is successful the Merchant remembers the answer to that question, calling on memories of the last time they traveled through the applicable area.')
      ) AS raw_data_en(skill_id, description)
  ),
  ins_main_skill_descriptions AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id || '.wcc_skills.' || raw_main_skill_descriptions.skill_id || '.description') AS id
         , meta.entity, 'description', raw_main_skill_descriptions.lang, raw_main_skill_descriptions.description
      FROM raw_main_skill_descriptions
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
  )
UPDATE wcc_skills
SET skill_desc_id = ck_id('witcher_cc.wcc_skills.' || skill_id || '.description')
WHERE skill_type = 'main'
  AND skill_desc_id IS NULL
  AND EXISTS (
    SELECT 1 FROM i18n_text 
    WHERE id = ck_id('witcher_cc.wcc_skills.' || wcc_skills.skill_id || '.description')
  );

-- Вставка описаний профессиональных навыков (professional skills)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id, 'wcc_skills' AS entity),
  raw_prof_skill_descriptions AS (
    SELECT 'ru' AS lang, skill_id, description
      FROM (VALUES
        -- Bard skills
        ('return_act', 'Перед проверкой <strong>Уличного выступления</strong> бард может совершить проверку <strong>Повторного выступления</strong> со СЛ, установленной ведущим, чтобы определить, выступал ли он в этом городе раньше. При успехе бард уже завоевал популярность в этом городе. В таком случае доход с его <strong>Уличного выступления</strong> удваивается, а сам бард получает бонус +2 к Харизме при общении со всеми, кто пришёл на выступление.'),
        ('raise_a_crowd', 'Выступая в течение полного раунда, вы можете совершить проверку способности <strong>Заворожить публику</strong>, чтобы привлечь внимание всех в радиусе 20 метров. Любой персонаж, чей результат проверки Сопротивления убеждению будет ниже вашего изначального, может только стоять и наблюдать, пока не выбросит более высокий результат. Атакованные цели автоматически перестают быть заворожёнными.'),
        ('good_friend', 'Один раз за игровую партию бард может совершить проверку способности <strong>Добрый друг</strong>, чтобы найти друга, который помог бы ему. Результат броска необходимо распределить между 3 категориями, указанными в таблице «Добрый друг» на полях. Друг по старой памяти окажет вам одну услугу в пределах разумного, после чего не будет больше помогать бесплатно и его нужно будет уговаривать.'),
        ('fade', 'Бард может совершить проверку <strong>Незаметности</strong> против Внимания нескольких целей, чтобы слиться с толпой. Эта способность позволяет барду прятаться даже там, где нет подходящих укрытий, — бард попросту вклинивается в разговор, переключает внимание окружающих на другой предмет и тому подобное. Эта способность не работает в том случае, если бард одет во что-то очень броское.'),
        ('spread_the_word', 'После успешного броска Обмана против цели бард может совершить встречный бросок способности <strong>Пустить слух</strong> против Сопротивления убеждению цели. При успехе барда цель распространяет рассказанную им ложь в своём поселении или группе, что даёт барду бонус +2 к Обману при попытке рассказать ту же ложь кому-то ещё.'),
        ('acclimatize', 'Находясь в поселении, бард может совершить проверку <strong>Сойти за своего</strong> (см. таблицу на полях). При успехе бард узнаёт, как выдать себя за местного, и его больше не считают чужим. Он получает бонус +2 к Харизме и Убеждению при общении с местными. При этом к нему не будут относиться с подозрением или подвергать травле, как чужака.'),
        ('poison_the_well', 'Когда бард пытается повлиять на одного или нескольких собеседников, он может совершить проверку <strong>Коварства</strong> против Эмп х 3 цели. При успехе бард делает ехидное замечание, которое даёт штраф -1 к Соблазнению, Убеждению, Лидерству, Запугиванию или Харизме цели за каждый пункт свыше СЛ.'),
        ('needling', 'Бард может совершить встречную проверку способности <strong>Подколка</strong> против Сопротивления убеждению цели. При успехе бард дразнит цель, осыпает её угрозами и ругательствами до тех пор, пока цель не нападёт. Цель получает штраф к атаке и защите, равный половине значения <strong>Подколки</strong> барда и длящийся количество раундов, равное значению способности <strong>Подколка</strong>.'),
        ('et_tu_brute', 'Бард может совершить проверку способности <strong>И ты, Брут</strong> против Воли хЗ цели, чтобы настроить цель против одного союзника. При успехе ложь или полуправда, сказанная бардом, заставляет цель относиться к своему союзнику с подозрением и враждебностью количество дней, равное значению <strong>И ты, Брут</strong>, или пока цель не совершит проверку Сопротивления убеждению, результат которой выше результата <strong>И ты, Брут</strong>.'),
        -- Witcher skills
        ('meditation', 'Ведьмак может войти в медитативный транс, что позволяет ему получить все преимущества сна, но при этом сохранять бдительность. Во время медитации ведьмак считается находящимся в сознании для того, чтобы заметить что-либо в радиусе в метрах, равном удвоенному значению его <strong>Медитации</strong>.'),
        ('magical_source', 'По мере того как ведьмак всё больше использует знаки, его тело постепенно привыкает к течению магической энергии. Каждые 2 очка, вложенные в способность <strong>Магический источник</strong>, повышают значение Энергии ведьмака на 1. Когда эта способность достигает 10 уровня, максимальное значение Энергии ведьмака становится равно 7. Эта способность развивается аналогично прочим навыкам.'),
        ('heliotrope', 'Когда ведьмак становится целью заклинания, инвокации или порчи, он может совершить проверку способности <strong>Гелиотроп</strong>, чтобы попытаться отменить эффект. Он должен выкинуть результат, который больше либо равен результату его противника, а также потратить количество Выносливости, равное половине Выносливости, затраченной на сотворение магии.'),
        ('iron_stomach', 'За годы употребления ядовитых ведьмачьих эликсиров ведьмаки привыкают к токсинам. Ведьмак может выдержать отвары и эликсиры суммарной токсичностью на 5% больше за каждые 2 очка, вложенные в способность <strong>Крепкий желудок</strong>. Эта способность развивается аналогично прочим навыкам. На 10 уровне максимальная токсичность для ведьмака равна 150%.'),
        ('frenzy', 'Будучи отравленным, ведьмак впадает в ярость и наносит дополнительно 1 урон в ближнем бою за каждый уровень <strong>Ярости</strong>. В этом состоянии единственная цель ведьмака — добраться до безопасного места или убить отравителя. Действие <strong>Ярости</strong> заканчивается одновременно с действием яда. Ведьмак может попытаться избавиться от <strong>Ярости</strong> раньше, совершив проверку Стойкости со СЛ 15.'),
        ('transmutation', 'Принимая отвар, ведьмак может совершить проверку <strong>Трансмутации</strong> со СЛ 18. При успехе тело ведьмака принимает в себя несколько больше мутагена, чем обычно, что позволяет получить бонус в зависимости от принятого отвара (см. таблицу на полях). Длительность действия отвара уменьшается вдвое. Дополнительные мутации слишком малы, чтобы их заметить.'),
        ('parry_arrows', 'Ведьмак может совершить проверку этой способности со штрафом -3, чтобы отбить летящий физический снаряд. При отбивании ведьмак может выбрать цель в пределах 10 м. Эта цель должна совершить действие защиты против броска <strong>Отбивания стрел</strong> ведьмака, или она будет ошеломлена из-за попадания отбитого снаряда.<br><br><b>Отбивание бомб.</b> Бомбы и другие атаки, поражающие зону, взрываются после отбивания. Если вторая цель уклоняется от атаки, совершите бросок по таблице разброса (см. стр. 152), чтобы определить, куда попадёт снаряд.'),
        ('quick_strike', 'Закончив свой ход, ведьмак может потратить 5 очков Вын и совершить проверку <strong>Быстрого удара</strong> со СЛ, равной Реа противника хЗ. При успехе ведьмак совершает ещё одну атаку в этот раунд против этого противника, которая может включать в себя разоружение, подсечку и прочие атаки.'),
        ('whirl', 'Потратив 5 очков Вын за раунд, ведьмак может закрутиться в <strong>Вихре</strong>, совершая каждый ход по одной атаке против всех, кто находится в пределах дистанции его меча. Проверка <strong>Вихря</strong> считается проверкой атаки. Находясь в <strong>Вихре</strong>, ведьмак может только поддерживать его, уклоняться и передвигаться на 2 метра за раунд. Любое другое действие или полученный удар прекращают <strong>Вихрь</strong>.'),
        -- Doctor skills
        ('diagnose', 'При возможности осмотреть раненое существо медик может совершить проверку <strong>Диагноза</strong> со СЛ, определяемой ведущим. При успехе он обнаруживает все критические ранения цели и узнаёт, сколько пунктов здоровья у неё осталось. Это также даёт бонус +2 ко всем проверкам <strong>Лечащего прикосновения</strong> для лечения этих ран.'),
        ('analysis', 'Перед проверкой <strong>Лечащего прикосновения</strong> медик может потратить ход и совершить проверку <strong>Осмотра</strong> со СЛ, зависящей от серьёзности критического ранения. При успехе медик понимает природу ранения и за каждые 2 пункта проверки свыше СЛ (минимум 1) хирургическая операция займёт на 1 ход меньше.'),
        ('effective_surgery', 'Перед тем как начать лечить критическое ранение, медик может совершить проверку <strong>Эффективной хирургии</strong> со СЛ, равной СЛ проверки <strong>Лечащего прикосновения</strong>, необходимой для лечения данного ранения. При успехе медик зашивает раны столь искусно, что они исцеляются в два раза быстрее. Эту способность можно использовать при лечении как критических ранений, так и обычных.'),
        ('healing_tent', 'Палатка лекаря позволяет совершить проверку со СЛ, определяемой ведущим, чтобы создать укрытие с оптимальными условиями для лечения. Это требует 1 часа, но добавляет бонус +3 к совершённым внутри проверкам <strong>Лечащего прикосновения</strong>/Первой помощи и +2 к скорости исцеления любого, кто находится в палатке, на количество дней, равное значению <strong>Палатки лекаря</strong>.'),
        ('improvised_medicine', 'Медик может совершить проверку <strong>Подручных средств</strong> со СЛ, равной СЛ Изготовления определённого лечащего алхимического состава, чтобы заменить его чем-то, что у него есть в наличии. Проверка занимает 1 раунд, и её можно повторить при провале. <strong>Подручные средства</strong> весьма специфичны и действуют только на конкретную рану.'),
        ('herbal_remedy', 'Смешав алхимические субстанции, медик может создать растительное лекарство, которое даёт бонусы/эффекты в зависимости от состава (см. таблицу Растительные лекарства на полях). Каждое лекарство хранится максимум 3 дня, после истечения этого срока его нельзя использовать. Чтобы получить бонус, лекарство следует сжечь или разжевать; его хватает только на одно применение. Создание лекарства занимает 1 ход.'),
        ('bloody_wound', 'Нанося урон клинковым оружием, медик может совершить проверку способности <strong>Кровавая рана</strong> со СЛ 15. При успехе после этой атаки цель начинает истекать кровью со скоростью 1 урон за каждые 2 пункта свыше установленной СЛ за раунд. Кровотечение можно остановить только проверкой Первой помощи со СЛ, равной результату проверки <strong>Кровавой раны</strong>.'),
        ('practical_butchery', 'Медикможет совершить проверку способности <strong>Практическая резня</strong> со СЛ, равной Тел х 3 противника, чтобы обычные и критические ранения противника исцелялись в два раза медленнее. Другие медики могут нейтрализовать этот эффект при помощи <strong>Эффективной хирургии</strong> и предметов, повышающих скорость исцеления обычных и критических ран.'),
        ('crippling_wound', 'Медик может совершить проверку способности <strong>Калечащая рана</strong> против защиты цели. Эта атака даёт штраф -6 к попаданию, но при успехе снижает Реакцию, Телосложение или Скорость цели на 1 пункт за каждые 3 пункта свыше броска защиты. Штраф можно снять, только совершив проверку <strong>Эффективной хирургии</strong> с результатом выше результата атаки медика.'),
        -- Mage skills
        ('scheming', 'Маг может совершить проверку способности <strong>Строить козни</strong> со СЛ, равной ИнтхЗ цели. При успехе маг получает бонус +3 к Обману, Соблазнению, Запугиванию или Убеждению против этой цели благодаря знаниям о её сильных и слабых сторонах. Бонус действует количество дней, равное значению способности <strong>Строить козни</strong>.'),
        ('grape_vine', 'Потратив час времени, маг может совершить проверку <strong>Сплетен</strong> против ЭмпхЗ цели. При успехе маг успешно распускает слухи о цели по всему поселению, что снижает репутацию цели на половину значения <strong>Сплетен</strong> мага на количество дней, равное значению этой способности.'),
        ('assets', 'Один раз за игру маг может совершить проверку <strong>Полезных связей</strong>, чтобы вспомнить о комто, кто мог бы быть полезен. Результат проверки необходимо распределить между четырьмя категориями, указанными в таблице на полях, чтобы понять, кто этот знакомый. То, как агент будет помогать магу, зависит от их отношений.'),
        ('reverse_engineer', 'Потратив час на изучение алхимического состава, маг может совершить проверку <strong>Анализа</strong> со СЛ, равной СЛ Изготовления этого алхимического состава + 3. При успехе маг выводит и записывает формулу этого состава. СЛ создания предмета по воссозданной формуле на 3 пункта выше, но в итоге маг получает желаемый предмет.'),
        ('distillation', 'Маг может совершить проверку <strong>Дистилляции</strong> вместо Алхимии при изготовлении алхимического состава. При успехе маг создаёт порцию состава, действующую в полтора раза эффективнее обычной порции — это относится к длительности, урону или СЛ сопротивления на выбор мага. Округление эффекта всегда идёт вниз.'),
        ('mutate', 'Маг может потратить полный день и всю свою Выносливость на проведение экспериментов над целью, чтобы совершить бросок <strong>Мутации</strong> со СЛ, равной (28 -(Тел+ Воля цели)/ 2), и мутацией изменить цель. При успехе цель получает возможность использовать мутаген с подходящей малой мутацией. При провале цель оказывается при смерти и получает крупную мутацию.<br><br>Мутировать одного персонажа можно максимум два раза. Новые мутации применяются взамен имеющихся.'),
        ('in_touch', 'По мере того как маг всё больше использует магию, его тело постепенно привыкает к течению магической энергии. Каждое очко, вложенное в способность <strong>Укрепление связи</strong>, повышает значение Энергии мага на 2. Когда эта способность достигает 10 уровня, максимальное значение Энергии мага равно 25. Эта способность развивается аналогично прочим навыкам.'),
        ('immutable', 'Маг может совершить проверку <strong>Устойчивости к двимериту</strong> со СЛ 16 в любой момент, когда на него обычно может воздействовать двимерит. При успехе маг способен противостоять эффекту двимерита: у него кружится голова и он испытывает дискомфорт, но сохраняет половину Энергии и способность сотворять заклинания.'),
        ('expanded_magic', 'Маг может обрести огромное могущество, проводя магическую энергию через разные фокусирующие магические предметы. Маг может совершить проверку <strong>Усиления магии</strong> со СЛ 16 перед сотворением заклинания или проведением ритуала. При успехе маг может провести магическую энергию через любые 2 фокусирующих предмета по своему выбору, снижая затраты Выносливости вдвое.'),
        -- Man At Arms skills
        ('extreme_range', 'Совершая дистанционную атаку, которая получила бы штраф за дистанцию, воин может уменьшить штраф на половину <strong>Максимальной дистанции</strong>. Он также может совершить проверку способности <strong>Максимальная дистанция</strong> со СЛ 16, чтобы атаковать цель на расстоянии до 3 дистанций своего оружия со штрафом -10. Этот штраф можно уменьшить, применив данную способность.'),
        ('twin_shot', 'Совершая дистанционную атаку из лука или метательным оружием, воин может совершить проверку способности <strong>Двойной выстрел</strong> вместо соответствующего оружию навыка. При попадании воин выпускает в цель два снаряда, повреждая две случайные части тела. Даже если атака была прицельной, второй снаряд попадёт в случайную часть тела.'),
        ('precise_aim', 'Если воин совершает критическую атаку дистанционным оружием, он может немедленно совершить проверку <strong>Точного прицела</strong> со СЛ, равной Лвк х 3 цели. При успехе воин добавляет значение способности <strong>Точный прицел</strong> к критическому броску. Эти очки влияют только на определение положения критического ранения.'),
        ('bloodhound', 'При выслеживании цели воин добавляет значение <strong>Ищейки</strong> к проверкам Выживания в дикой природе, чтобы найти след или пройти по нему. Если воин теряет след во время выслеживания с помощью этой способности, он может совершить проверку <strong>Ищейки</strong> со СЛ, определяемой ведущим, чтобы немедленно вновь найти след.'),
        ('warrior_trap', 'Воин может совершить проверку способности <strong>Ловушка воина</strong>, чтобы установить самодельную ловушку в определённой зоне. Вид ловушки определите по таблице «Ловушки воина». Воин может создать ловушку только одного вида за раз. У каждой ловушки есть растяжка радиусом 2 метра, для её обнаружения требуется совершить проверку Внимания со СЛ, равной проверке <strong>Ловушки воина</strong>.'),
        ('tactical_advantage', 'Вместо перемещения воин может совершить проверку <strong>Тактического преимущества</strong>, чтобы оценить группу противников. Воин получает бонус +3 к атаке и защите на один раунд против всех врагов в пределах 10 метров, чья ЛвкхЗ меньше, чем результат проверки. Также эта способность позволяет понять, что собирается делать каждый из врагов, на которых она действует.'),
        ('fury', 'Воин может совершить проверку <strong>Неистовства</strong> со СЛ, равной его ЭмпхЗ. При успехе воин становится невосприимчив к ужасу, влияющим на эмоции заклинаниям и Словесной дуэли на количество раундов, равное удвоенному значению <strong>Неистовства</strong>. В это время ярость застилает разум воина и он полностью отдаётся во власть инстинктов.'),
        ('two_handed', 'Потратив 10 очков Вын и совершив проверку способности <strong>Двуручник</strong> со штрафом -3 против защиты противника, воин может совершить одну атаку, которая наносит двойной урон и считается пробивающей броню. Если его оружие уже пробивающее броню, оно становится улучшенным пробивающим броню. Улучшенное пробивающее броню оружие с этой способностью наносит 3d6 дополнительного урона.'),
        ('ignore_pain', 'Количество раз за игровую партию, равное Тел воина, он может потратить 10 очков Вын, чтобы немедленно совершить проверку способности <strong>Игнорировать удар</strong>, когда противник наносит ему критическое ранение. Если результат проверки выше проверки атаки противника, воин отменяет критическое ранение, как если бы атака противника не была критической.'),
        -- Priest skills
        ('divine_power', 'Укрепляя связь с божеством, жрец может повысить своё значение Энергии на 1 за каждый уровень <strong>Божественной силы</strong>. Таким образом, значение Энергии жреца на 10 уровне будет равно 12. Эта способность развивается аналогично прочим навыкам и суммируется с <strong>Единением с природой</strong>. Значение Энергии в этом случае общее'),
        ('divine_authority', 'Для крестьян и простого люда жрец — проводник воли богов. Жрец может добавить значение <strong>Божественного авторитета</strong> к своим проверкам Лидерства, если он находится в области, где исповедуют ту же религию. Если жрец находится за пределами такой области, то он добавляет половину значения способности.'),
        ('foresight', 'По решению ведущего жрец может получить видение будущего, на 3 раунда впав в состояние кататонии. После этого жрец может совершить проверку <strong>Предвидения</strong> со СЛ, определяемой ведущим, чтобы расшифровать полученные видения, которые представляют собой смесь символов и метафор.'),
        ('one_with_nature', 'Укрепляя связь с природой, жрец может повысить своё значение Энергии на 1 за каждый уровень <strong>Единения с природой</strong>. Таким образом, значение Энергии жреца на 10 уровне будет равно 12. Эта способность развивается аналогично прочим навыкам и суммируется с <strong>Божественной силой</strong>. Значение Энергии в этом случае общее.'),
        ('nature_s_signs', 'Находясь среди природы, друид может совершить проверку способности <strong>Знаки природы</strong> со СЛ, определяемой ведущим. При успехе друид по знакам узнаёт, кто в этом месте был и что делал. Эта проверка даёт только локальную информацию и не позволяет отслеживать.'),
        ('nature_s_ally', 'Друид добавляет способность <strong>Союзник природы</strong> к любым проверкам Выживания в дикой природе для обращения с животными. Друид также может сдружиться с животным, потратив полный раунд и совершив проверку <strong>Союзника природы</strong>. Зверь или иное животное становится союзником друида на количество часов, равное значению способности <strong>Союзник природы</strong>. Данная способность не действует на чудовищ.'),
        ('bloody_rituals', 'Проводя ритуал, жрец может совершить проверку способности <strong>Кровавые ритуалы</strong> со СЛ, равной СЛ ритуала. При успехе жрец проводит ритуал без необходимых алхимических субстанций, жертвуя при этом 5 ПЗ в виде крови за каждую недостающую субстанцию. Это может быть и чужая кровь, но только пролитая во время данного ритуала.'),
        ('zeal', 'Жрец может совершить проверку <strong>Рвения</strong> против текущего значения ИнтхЗ цели. При успехе слова жреца ободряют цель, что даёт ей 1d6 временных ПЗ за каждый пункт сверх СЛ (максимум 5). Этот эффект длится количество раундов, равное значению <strong>Рвения</strong> х 2, и на одну цель его можно использовать только раз в день.'),
        ('holy_fire', 'Жрец может совершить проверку способности <strong>Слово божье</strong>, чтобы убедить слушателей, что его устами говорит божество. Любой, кто провалит проверку Сопротивления убеждению, будет считать жреца мессией и следовать за ним. Количество последователей жреца равно значению его <strong>Слова божьего</strong>. Если у последователей нет блоков параметров, используйте для них параметры разбойников.<br><br>Когда ваш персонаж отдаёт своим последователям действительно странный или неестественный для него приказ, совершите проверку <strong>Слова божьего</strong> со СЛ, определяемой ведущим. Вы можете провалить проверку 3 раза, после чего последователи покинут вашего персонажа. Если при последней проверке выпадает 1, то последователи нападут на вас или объявят еретиком.'),
        -- Criminal skills
        ('case_joint', 'Преступник может потратить час, чтобы побродить по улицам поселения и совершить проверку способности <strong>Присмотреться</strong> со СЛ, указанной в таблице на полях. При успехе преступник запоминает маршруты патрулей, расположение улиц и укрытий, что даёт ему бонус +2 к Скрытности в этом районе на количество дней, равное значению <strong>Присмотреться</strong>.'),
        ('repeat_lockpick', 'Когда преступник успешно вскрывает замок, он может совершить проверку <strong>Повторного взлома</strong> со СЛ, равной СЛ Взлома замков (для данного замка), чтобы запомнить положение штифтов. Это позволит ему открыть тот же замок без проверки навыка Взлома замков. Преступник может запомнить столько замков, сколько у него очков Инт. Всегда можно запомнить новый замок, забыв старый.'),
        ('lay_low', 'Один раз за игровую партию преступник может совершить проверку способности <strong>Залечь на дно</strong>, чтобы найти тайное убежище, где он может спрятаться на какое-то время. Результат проверки <strong>Залечь на дно</strong> распределите между тремя категориями по соответствующей таблице на полях. Тайное убежище существует, пока его не уничтожат, и преступник всегда может в него вернуться.'),
        ('vulnerability', 'Преступник может совершить встречную проверку <strong>Уязвимости</strong> против навыка Обмана разумной цели, чтобы определить самую дорогую для цели вещь или личность. Это также даёт преступнику бонус +1 к Запугиванию за каждые 2 пункта свыше Обмана цели. Этот бонус действует до тех пор, пока уязвимость цели не изменится.'),
        ('take_note', 'Преступник может совершить проверку способности <strong>Взять на заметку</strong> со СЛ, равной Эмп х 3 цели, чтобы оставить метку на её двери или что-то подобное. При успехе цель должна проходить проверку Харизмы, Убеждения или Запугивания, результат которой должен быть выше проверки <strong>Взять на заметку</strong> преступника, чтобы получить помощь или услугу у кого-либо в своём поселении.'),
        ('intimidating_presence', 'Один раз в день, потратив час, преступник может совершить проверку <strong>Сбора</strong> с установленной ведущим СЛ. За каждые 2 пункта свыше установленной СЛ преступник может завербовать 1 разбойника на количество дней, равное значению <strong>Сбора</strong>. Если у разбойника меньше половины ПЗ, он должен совершить бросок десятигранной кости, результат которого должен быть ниже значения Воли преступника; в противном случае разбойник убегает.'),
        ('smuggler', 'Преступник, не участвующий в бою, может потратить раунд, чтобы прицелиться, и совершить проверку <strong>Прицеливания</strong> со СЛ, равной Реа х 3 цели, чтобы получить бонус к следующей атаке, равный половине значения <strong>Прицеливания</strong>. Если преступника заметят после броска, но до атаки, бонус снижается в два раза.'),
        ('false_identity', 'Вместо атаки преступник может совершить проверку способности <strong>Прямо в глаз</strong>, чтобы временно ослепить цель. Для этого необходимо, чтобы преступник находился на дистанции ближнего боя; к удару при этом применяется штраф -3. При попадании цель получает 2d6 урона без модификаторов и ослепляется на количество раундов, равное значению <strong>Прямо в глаз</strong>.'),
        ('black_market', 'Устраивая засаду, преступник может совершить встречную проверку способности <strong>Удар ассасина</strong> против Внимания цели, чтобы скрыться после атаки. Эту способность можно использовать в любой ситуации, но к ней применяются штрафы в зависимости от освещённости и других условий. Если противников несколько, каждый может совершить по броску, чтобы попытаться заметить преступника.'),
        -- Craftsman skills
        ('large_catalog', 'Умелый ремесленник способен запомнить огромное количество чертежей на все случаи жизни. Когда ремесленник уже запомнил максимальное доступное ему количество чертежей, он может совершить проверку способности <strong>Большой каталог</strong> со СЛ 15, чтобы запомнить ещё один. Нет ограничения на количество запомненных чертежей, но за каждые 10 запоминаний СЛ проверки повышается на 1.'),
        ('apprentice', 'Когда ремесленник начинает изготавливать какой-либо предмет, он может совершить проверку способности <strong>Подмастерье</strong> со СЛ, равной СЛ Изготовления данного предмета. При успехе он прибавляет 1 к урону или к прочности за каждые 2 пункта сверх указанной СЛ. Максимальный бонус к урону или прочности равен 5. Ремесленник не может использовать Удачу для увеличения этого бонуса.'),
        ('masterwork', '<strong>Мастерская работа</strong> позволяет ремесленнику изготавливать предметы уровня мастера. Ремесленник может также в любой момент совершить проверку способности <strong>Мастерская работа</strong> со СЛ, равной СЛ Изготовления предмета, чтобы навсегда придать броне сопротивление (он сам решает чему именно) или бонус оружию: дробящее оружие получает свойство дезориентирующее (-2), колющее или режущее — кровопускающее (50%).'),
        ('alchemical_concoction', 'Умелый ремесленник способен запомнить огромное количество формул на все случаи жизни. Когда ремесленник уже запомнил доступное ему число формул, он может совершить проверку способности <strong>Список лекарств</strong> со СЛ 15, чтобы запомнить ещё одну. Нет ограничения на количество запомненных формул, но за каждые 10 запоминаний СЛ проверки повышается на 1.'),
        ('enhanced_potion', 'Когда ремесленник собирается изготовить алхимический состав, он может совершить проверку <strong>Двойной порции</strong> со СЛ, равной СЛ Изготовления данной формулы. При успехе он создаёт две порции состава из ингредиентов, рассчитанных на одну порцию. Это применимо ко всем алхимическим предметам, включая эликсиры, масла, отвары и бомбы.'),
        ('experimental_formula', 'Перед созданием ведьмачьего эликсира ремесленник может совершить проверку <strong>Адаптации</strong> (3 + СЛ Изготовления), чтобы уменьшить СЛ избегания отравления на 1 за каждый пункт свыше СЛ Изготовления. При провале ядовитость эликсира не меняется. СЛ избегания отравления не может опускаться ниже 12.'),
        ('workshop', 'Ремесленник может совершить проверку <strong>Улучшения</strong> со СЛ, указанной в таблице на полях, чтобы придать оружию или броне особые свойства (при наличии инструментов ремесленника). На улучшение необходимо потратить 3 раунда. Для улучшения не обязательно использовать кузницу, но она даёт бонус +2 к проверке. Критический провал наносит предмету урон, равный значению провала.'),
        ('repair', 'Ремесленник может посеребрить имеющееся оружие в кузнице, совершив проверку со СЛ 16. Количество необходимых для этого серебряных слитков зависит от размера оружия. При успехе оружие наносит +1d6 урона серебром за каждые 3 пункта свыше сложности, но не более 5d6. При провале оружие ломается.<br><br>Для серебрения одноручного оружия требуется 2 слитка серебра, двуручного — 4 слитка серебра, и 1 слиток уйдёт на серебрение 10 или менее стрел или арбалетных болтов.'),
        ('upgrade', 'Ремесленник может совершить проверку способности <strong>Прицельный удар</strong> со СЛ, равной СЛ Изготовления предмета, чтобы найти в нём изъян. На осмотр предмета уходит 1 раунд, но это позволяет ремесленнику совершить прицельную атаку со штрафом −6, чтобы нанести разрушающий урон оружию или броне, равный результату броска шестигранных костей в количестве, равном значению <strong>Прицельного удара</strong>.'),
        -- Merchant skills
        ('market', 'Торговец может совершить проверку <strong>Рынка</strong> с определяемой ведущим СЛ, чтобы найти нужный предмет по более низкой цене. При успехе торговец находит того, кто продаст ему тот же предмет за полцены. Чем более редкий предмет, тем выше СЛ поиска. <strong>Рынок</strong> не действует на экспериментальные, ведьмачьи предметы и реликвии.'),
        ('dirty_deal', 'Совершая подкуп, торговец может совершить проверку способности <strong>Нечестная сделка</strong> со СЛ, равной Воле х 3 цели. При успехе торговец даёт взятку любым предметом, который у него есть и который стоит не менее 5 крон. Взятка всегда даёт +3 к Убеждению. Если взятка совсем уж несуразна, СЛ увеличивается на 5.'),
        ('promise', 'При попытке купить предмет торговец может совершить проверку <strong>Обещания</strong> со СЛ, равной Эмп х 3 продавца. При успехе продавец верит обещанию торговца заплатить позже. Количество недель, через которое необходимо выполнить это обязательство, равно значению <strong>Обещания</strong>.'),
        ('slums', 'Торговец может совершить проверку способности <strong>Трущобы</strong> со СЛ в зависимости от размера поселения, чтобы заручиться помощью 1 беспризорника или бездомного за каждый пункт свыше СЛ (максимум 10). Торговец может спросить у них совета и получить бонус +1 к проверкам Ориентирования в городе за каждого. Информаторы берут плату в 1 крону на каждого, когда с ними советуются.'),
        ('contacts', 'Торговец со способностью <strong>Свой человек</strong> может убедить другого персонажа пошпионить на него. Заплатите 10 крон и совершите встречную проверку <strong>Своего человека</strong> против Сопротивления убеждению цели. При успехе персонаж будет шпионить для торговца количество дней, равное значению способности <strong>Свой человек</strong>. По истечении этого срока торговец может снова совершить проверку, опять же заплатив.'),
        ('merchant_network', 'Один раз за игровую партию торговец может совершить проверку способности <strong>Карта сокровищ</strong> со СЛ, определяемой ведущим, чтобы вспомнить предполагаемое местонахождение реликвии или руин, в которых может оказаться что-то полезное. Место, где находится этот предмет или руины, расположено достаточно далеко или же кишит опасностями. Чтобы добраться до него, потребуется целая игровая партия.'),
        ('haggle', 'Входя в поселение впервые, торговец может потратить час на распространение вести о своём прибытии, а затем совершить проверку <strong>Хороших связей</strong> со СЛ в зависимости от размера поселения. При успехе репутация торговца в этом поселении на 1d6 недель увеличивается на значение проверки свыше указанной СЛ, делённое на 2 (минимум 1).'),
        ('merchant_sense', 'Торговец, которому необходимо избавиться от предмета с сомнительным происхождением или краденого, может совершить проверку способности <strong>Сбытчик</strong> со СЛ, определяемой ведущим. При успехе торговец продаст предмет по полной рыночной цене покупателю, который не станет задавать лишних вопросов и не сдаст торговца страже.'),
        ('merchant_king', 'Торговец может совершить проверку способности <strong>Воинский долг</strong>, чтобы попросить о помощи воина, который у него в долгу. Результат броска необходимо распределить по 3 категориям, указанным в таблице на полях. Воин будет работать на торговца количество дней, равное значению <strong>Воинского долга</strong>, и без лишних вопросов исполнит любой приказ в пределах разумного.')
      ) AS raw_data_ru(skill_id, description)
    UNION ALL
    SELECT 'en' AS lang, skill_id, description
      FROM (VALUES
        -- Bard skills
        ('return_act', 'Before attempting a Busking roll a Bard can roll Return Act at a DC set by the GM to see whether they have played in this town before. If the roll is successful the Bard has made a name for themselves in this town already. Not only is their Busking income doubled but they gain a +2 Charisma with everyone in at that venue.'),
        ('raise_a_crowd', 'By taking a full round to perform, you can roll Raise A Crowd to captivate anyone within 20m. Anyone who doesn''t make a Resist Coercion roll higher than your initial roll can do nothing but watch you perform until they succeed at rolling above your initial roll. If attacked a target will snap out of it.'),
        ('good_friend', 'Once per session a Bard can make a Good Friend roll to find a friend to aid them. Take the total roll and split these points up between the 3 categories in the Good Friend chart in the sidebar. This friend will do one reasonable thing for old times'' sake, then cannot be called on again for free and must be convinced.'),
        ('fade', 'A Bard can make a Fade roll against multiple targets'' Awareness rolls to fade into the background. This ability allows a Bard to hide even when there are no good hiding places, by slipping into a conversation, drawing attention to something else, or the like. This ability doesn''t work if you are wearing really flashy clothing.'),
        ('spread_the_word', 'A Bard who rolls a successful Deceit roll against a target can then roll Spread the Word against the target''s Resist Coercion roll. If they succeed the target spreads the Bard''s lie around the target''s settlement or group, giving the Bard a +2 to Deceit when trying to pass off that lie again to someone else.'),
        ('acclimatize', 'When in a settlement a Bard can roll Acclimatize (see Acclimatize chart for DC). If successful, the Bard learns how to appear as a local and will no longer be treated as an outsider. This grants a +2 to Charisma &amp; Persuasion with locals and means that they won''t be questioned or harassed like an outsider.'),
        ('poison_the_well', 'A Bard can make a Poison The Well roll against a target''s EMP×3 when they are trying to influence a person or people. If successful, the Bard makes a pointed comment that imposes a −1 for each point they rolled above the DC to the target''s Seduction, Persuasion, Leadership, Intimidation or Charisma rolls.'),
        ('needling', 'A Bard can make a Needling roll against a target''s Resist Coercion roll. If successful, the Bard goads them with obscenities and threats until they attack. The target takes a negative to their attack and defense equal to half the Bard''s Needling value, lasting for as many rounds as the Needling value.'),
        ('et_tu_brute', 'A Bard can roll Et Tu Brute against a target''s WILL×3 to turn them against one ally. If successful the Bard''s lies and half-truths makes the target treat that ally with mistrust and animosity for as many days as the Et Tu Brute value or until they make a Resist Coercion roll that beats the Et Tu Brute roll.'),
        -- Witcher skills
        ('meditation', 'A Witcher can enter a meditative trance which grants all the benefits of sleeping but allows them to remain vigilant. While meditating a Witcher is considered awake for the purpose of noticing anything within double their <strong>Meditation</strong> value in meters.'),
        ('magical_source', 'As a Witcher uses signs more often their body becomes more used to the effort. For every 2 points a Witcher has in <strong>Magical Source</strong> they gain 1 points of Vigor threshold. When this ability reaches level 10, your maximum Vigor threshold becomes 7. This skill can be trained like other skills.'),
        ('heliotrope', 'When a Witcher is targeted by a spell, invocation, or hex they can roll <strong>Heliotrope</strong> to attempt to negate the effects. They must roll a Heliotrope roll that equals or beats the opponent''s roll and then expend an amount of Stamina equal to half the Stamina spent to cast the magic.'),
        ('iron_stomach', 'After decades of drinking toxic witcher potions, witcher bodies adapt to the toxins. A witcher can endure 5% more toxicity from drinking potions and decoctions per 2 points they spend on <strong>Iron Stomach</strong>. This skill can be trained like other skills. At level 10, a witcher''s maximum toxicity is 150%.'),
        ('frenzy', 'When poisoned, a witcher goes into a frenzy and deals an extra 1 melee damage per level in <strong>Frenzy</strong>. While in a <strong>Frenzy</strong>, your single goal is to get to a place of safety or kill the target that poisoned you. When the poison wears off, the <strong>Frenzy</strong> ends. You can attempt to end Frenzy early with a DC:15 Endurance roll.'),
        ('transmutation', 'When taking decoctions a Witcher can roll <strong>Transmutation</strong> at DC:18. A success allows their body to assimilate slightly more of the mutagen than usual and gain a bonus based on which decoction they take. The decoction lasts half as long as it normally would. The extra mutations are too subtle to spot.'),
        ('parry_arrows', 'A Witcher can roll <strong>Parry Arrows</strong> at a −3 to deflect physical projectiles. When parrying, the Witcher can choose a target within 10m. That target must take a defense action against the Witcher''s <strong>Parry Arrows</strong> roll or be Staggered by the flying projectile.<br><br><b>Parrying Bombs.</b> Bombs and other area of effect attacks detonate after the parry resolves. If the second target dodged the attack, roll on the Scatter Table to see where the attack lands.'),
        ('quick_strike', 'After a Witcher takes their turn they can spend 5 STA and make a <strong>Quick Strike</strong> roll at a DC equal to their opponent''s REF×3. On success, they make another single strike in that round. This attack must be made against the opponent they rolled against, but can include disarms, trips, and other attacks.'),
        ('whirl', 'By spending 5 STA per round, a witcher can enter a <strong>Whirl</strong>, where the witcher makes one attack against everyone within sword range each turn, with their <strong>Whirl</strong> roll acting as the attack roll. The witcher can only maintain this Whirl, dodge, and move 2m each round. Doing anything else or being hit halts the <strong>Whirl</strong>.'),
        -- Doctor skills
        ('diagnose', 'When able to look over a wounded person or monster, a Doctor can roll Diagnose at a DC determined by the GM. If they succeed they assess any Critical Wounds the subject has and learn how many Health Points it has left. This also gives a +2 to any Healing Hands checks to heal those wounds.'),
        ('analysis', 'When about to perform a Healing Hands roll, a Doctor can take a turn to make an Analysis roll at a DC equal to the severity of the Critical Wound. If they succeed they gain insight into the wounds, and for every 2 they roll over the DC (minimum 1) the surgery takes 1 turn less.'),
        ('effective_surgery', 'Before starting to heal a Critical Wound a Doctor can make an Effective Surgery roll at a DC equal to the wound''s Healing Hands DC. If they succeed they treat the wounds so skilfully that they heal twice as fast. This ability can be used on critical wounds and can also be used on regular wounds.'),
        ('healing_tent', 'Healing Tent allows a Doctor to roll against a DC set by the GM to create a covered area that provides an optimal medical environment. This takes 1 hour but adds +3 to Healing Hands/First Aid rolls inside, and +2 to the healing rate of anyone in the tent for a number of days equal to your Healing Tent value.'),
        ('improvised_medicine', 'A Doctor can make an Improvisation roll at a DC equal to the crafting DC for a specific medical alchemical item to substitute something else on hand for the same effect. This roll takes one round and if it is failed it can be made again. Improvisation is very specific and works only on this one injury.'),
        ('herbal_remedy', 'By mixing alchemical substances, a Doctor can create an herbal remedy that grants bonuses/effects based on what was put into it (see the Healing Remedy chart in the sidebar). Each remedy remains viable for 3 days and must be burned or chewed to provide the bonus, allowing only 1 use. Making a remedy takes 1 turn.'),
        ('bloody_wound', 'A Doctor who does damage with a bladed weapon can make a Bleeding Wound roll against a DC of 15. On success, the attack causes bleeding at a rate of 1 point per 2 points rolled over the DC. The bleeding can only be stopped by a First Aid roll, at a DC equal to the Doctor''s Bleeding Wound roll.'),
        ('practical_butchery', 'A Doctor can roll Practical Carnage against a DC equal to the opponent''s BODYx3 to cause the target''s wounds and critical wounds to heal half as fast. Other Doctors with the Effective Surgery skill and items that raise the healing rate of wounds and critical wounds can counteract the effect.'),
        ('crippling_wound', 'A Doctor can make a Crippling Wound roll against the target''s defense. This attack takes a -6 to hit but imposes a negative to the target''s REFLEX, BODY, or SPEED equal to 1 per 3 points above their defense roll. This negative can only be removed with an Effective Surgery roll that beats your attack roll.'),
        -- Mage skills
        ('scheming', 'A Mage can make a <strong>Scheming</strong> roll at a DC equal to a target''s INT×3. On success the Mage gets a +3 to Deceit, Seduction, Intimidation, or Persuasion against that target from their observations of how the target works. The bonus from this ability applies for a number of days equal to the Mage''s <strong>Scheming</strong> value.'),
        ('grape_vine', 'A Mage can take 1 hour and make a <strong>Grape Vine</strong> roll against a target''s EMP×3. Success spreads rumors throughout a settlement or city, lowering the target''s reputation there by half your <strong>Grape Vine</strong> value for a number of days equal to your <strong>Grape Vine</strong> value.'),
        ('assets', 'Once per game a Mage can make an <strong>Assets</strong> roll to remember an asset they ''acquired'' some time ago. Take the total of your roll and distribute it between the 4 columns on the table in the sidebar to find out who you know. This asset will help you, but how much depends on their relationship with you.'),
        ('reverse_engineer', 'By taking 1 hour to study an alchemical solution a Mage can roll <strong>Reverse Engineer</strong> at a DC equal to the Crafting DC for the alchemical item +3. Success allows them to reverse-engineer and write down the item''s formula. This formula is 3 points harder to craft, but reliably creates the desired item.'),
        ('distillation', 'A Mage can roll <strong>Distillation</strong> instead of Alchemy when creating an alchemical solution. Success at this roll creates a dose of that solution that has half again the effect that they would normally have, either in duration, damage, or resistance DC (your choice). Always round down when increasing.'),
        ('mutate', 'A mage can spend all of their stamina and a full day experimenting on a subject to roll <strong>Mutate</strong> at a DC equal to (28 − (subject''s BODY + WILL)/2) to mutate the subject. Success grants the subject use of the Mutagen with the appropriate minor mutation. Failure throws the subject into Death State and inflicts the larger mutation.<br><br>An individual can only be mutated twice. Further mutations will replace existing ones.'),
        ('in_touch', 'As a Mage utilizes magic more and more, their body becomes more used to the flow. Every point a Mage has in <strong>In Touch</strong> grants +2 points to Vigor threshold. When this ability reaches level 10 your maximum Vigor threshold becomes 25. This skill can be trained, like other skills.'),
        ('immutable', 'A Mage can roll <strong>Immutable</strong> at DC:16 whenever they would normally be affected by dimetrium. Success means that the Mage mostly shrugs off the dimetrium. They are still somewhat dizzy and uncomfortable but retain half of their total Vigor threshold and can perform magic.'),
        ('expanded_magic', 'By channelling magic through various magical foci a Mage can wield incredible power. A Mage can roll <strong>Expanded Magic</strong> before attempting to cast a spell or ritual, at a DC of 16. On success the mage can channel the spell or ritual through any 2 of their foci they choose, reducing the Stamina cost twice.'),
        -- Man At Arms skills
        ('extreme_range', 'When making a ranged attack that would take range penalties, a Man At Arms can lower the penalty by up to half their <strong>Extreme Range</strong> value. They can also make an <strong>Extreme Range</strong> roll (DC:16) to attack targets within 3 times the range of their weapon at a −10, which can be modified by <strong>Extreme Range</strong>.'),
        ('twin_shot', 'When making a ranged attack with a thrown weapon or a bow, a Man At Arms can roll <strong>Twin Shot</strong> in place of their normal weapon skill. If they hit, they strike with two projectiles and damage two randomly rolled parts of the body. Even if the attack is aimed, the second projectile will hit a random location.'),
        ('precise_aim', 'A Man At Arms who scores a critical with their ranged weapon can immediately roll <strong>Pin Point Aim</strong> at a DC equal to the target''s DEX×3. If they succeed, they add their <strong>Pin Point Aim</strong> value to their critical roll. These points only affect the location value of the Critical Wound.'),
        ('bloodhound', 'When tracking a target or trying to find a trail, a Man At Arms adds their <strong>Bloodhound</strong> value to <strong>Wilderness Survival</strong> rolls to find the trail or follow it. If the Man At Arms loses the trail while tracking with this ability, they can roll <strong>Bloodhound</strong> at a DC set by the GM to pick the trail back up immediately.'),
        ('warrior_trap', 'A Man At Arms can make a <strong>Booby Trap</strong> roll to set a makeshift trap in a specific area. See the Booby Trap table for traps that can be built. The Man At Arms can only build one type of trap at a time. Every trap has a 2m radius tripwire and requires an <strong>Awareness</strong> roll at a DC equal to your <strong>Booby Trap</strong> roll to spot.'),
        ('tactical_advantage', 'Instead of moving, a Man At Arms can roll <strong>Tactical Awareness</strong> to gain insight into a whole group of opponents. The Man At Arms gains +3 to attack and defense rolls against every enemy within 10m whose DEX×3 is lower than that roll, for one round. This ability also tells the Man At Arms what each affected opponent is about to do.'),
        ('fury', 'A Man At Arms can roll <strong>Fury</strong> at a DC equal to their EMP×3. If they succeed, the Man At Arms becomes immune to fear, spells that change emotions, and Verbal Combat for a number of rounds equal to their <strong>Fury</strong> value times 2. During this time, rage clouds their thinking and instinct takes over.'),
        ('two_handed', 'By spending 10 STA and rolling <strong>Zweihand</strong> minus 3 against an opponent''s defense, a Man At Arms can make one attack which does double damage and has armor piercing. If the weapon already has armor piercing, it gains improved armor piercing. A weapon with improved armor piercing gains 3d6 damage.'),
        ('ignore_pain', 'A number of times per game session equal to their BODY value, a Man At Arms can spend 10 STA to immediately roll <strong>Shrug It Off</strong> when an enemy strikes a Critical Wound on them. If their roll beats the enemy''s attack roll, they can negate the Critical Wound, taking the damage as if the enemy hadn''t rolled a critical.'),
        -- Priest skills
        ('divine_power', 'A Priest can become more in tune with their god, gaining 1 point of Vigor threshold per skill level in <strong>Divine Power</strong>. This brings your Vigor threshold to a total of 12 at level 10. <strong>Divine Power</strong> can be trained like other skills and stacks with <strong>Nature Attunement</strong>. The Vigor thresholds are not separate.'),
        ('divine_authority', 'Peasants and the common folk of the world see Priests as agents of the god''s will. A Priest can add their <strong>Divine Authority</strong> to their Leadership rolls if they are in an area where their religion is worshiped. Even when outside such areas of worship a Priest adds half this value, due to their presence.'),
        ('foresight', 'At the will of the GM, a Priest can be overcome by visions of the future, sending them into a catatonic state for 3 rounds. After this time the Priest can roll <strong>Precognition</strong> at a DC set by the GM to decipher the visions that they are stricken by. Such visions are composed of symbolism and metaphors.'),
        ('one_with_nature', 'A Priest can become more in tune with nature, gaining 1 point of Vigor threshold per skill level in <strong>Nature Attunement</strong>. This brings your Vigor threshold to a total of 12 at level 10. <strong>Nature Attunement</strong> can be trained like other skills and stacks with <strong>Divine Power</strong>. The Vigor thresholds are not separate.'),
        ('nature_s_signs', 'When in a purely natural environment a druid can roll <strong>Read Nature</strong> at a DC set by the GM. On a success, the druid reads the signs around them to learn everything that passed through that area and what they did in the area. <strong>Read Nature</strong> renders a very localized picture and cannot track things.'),
        ('nature_s_ally', 'A Druid adds <strong>Animal Compact</strong> to any Wilderness Survival rolls they make to handle animals. A Druid can also make a compact with an animal. By taking a full round and rolling <strong>Animal Compact</strong>, they make one Beast or animal their ally for a number of hours equal to their <strong>Animal Compact</strong> value. Monsters are unaffected.'),
        ('bloody_rituals', 'A Priest casting a ritual can make a <strong>Blood Ritual</strong> check against the casting DC of the ritual. If they succeed, they can cast the ritual without required alchemical substances by sacrificing 5 HP in blood per missing alchemical substance. This blood can come from others, but must be spilled at the time of the ritual.'),
        ('zeal', 'A Priest can roll <strong>Fervor</strong> against a target''s current INT×3. On success, the rallying power of the Priest''s words grants 1d6 temporary health for every point rolled over the DC (maximum 5). This lasts for as many rounds as their <strong>Fervor</strong> ×2 and only works once per target per day.'),
        ('holy_fire', 'A Priest can roll <strong>Word of God</strong> to convince people that they are speaking directly for the gods. Anyone who fails a Resist Coercion roll sees the Priest as a messiah and follows along as an apostle. A Priest can have as many apostles as their <strong>Word of God</strong> value. In combat, use bandit stats for apostles with stat outs.<br><br>Any time you give a truly strange or uncharacteristic command to your apostles, you must make a <strong>Word of God</strong> roll at a DC set by the GM. You can fail 3 times before your apostles leave you. If your last failure is a fumble, your apostles will attack you or brand you as a heretic.'),
        -- Criminal skills
        ('case_joint', 'A Criminal can take an hour to wander the streets of a Settlement and roll <strong>Case The Area</strong> against a DC in the Case The Area chart. If successful, the Criminal memorizes guard patterns, street layouts, and hiding spots for a +2 to Stealth in that area for a number of days equal to their <strong>Case The Area</strong> value.'),
        ('repeat_lockpick', 'Whenever a Criminal successfully picks a lock they can roll <strong>Mental Key</strong> at a DC equal to the Lock Picking DC to memorize its tumbler positions. This allows the Criminal to open the lock without a Lock Picking roll. You can memorize as many locks as you have points in INT and can always replace one.'),
        ('lay_low', 'Once per session a Criminal can roll <strong>Go To Ground</strong> to find a hideout where they can lie low for a while. Take the total value of your <strong>Go To Ground</strong> roll and split the points between the 3 categories in the Go To Ground table in the sidebar. This hideout remains until destroyed, and you can always return to it.'),
        ('vulnerability', 'A Criminal can roll <strong>Weak Spot</strong> against a sentient target''s Deceit roll to identify the target''s most valued possession or person. This also grants the Criminal a +1 to Intimidate for every 2 points they rolled above the target''s Deceit. This Intimidation bonus lasts until something happens to change the target''s weak spot.'),
        ('take_note', 'A Criminal can roll <strong>Marked Man</strong> at a DC equal the target''s EMP×3 to mark a target by carving a mark on their door, or the like. If successful the target must make a Charisma, Persuasion, or Intimidation check that beats your <strong>Marked Man</strong> roll to get any help or service from anyone in their settlement.'),
        ('intimidating_presence', 'Once per day, by taking an hour,a Criminal can roll a <strong>Rally</strong> check against a DC set by the GM. For every 2 you roll above the DC they recruit 1 Bandit for a number of days equal to your <strong>Rally</strong> value. If a Bandit is knocked below half health they must roll under the Criminal''s WILL on a 10 sided die or flee.'),
        ('smuggler', 'A Criminal who''s not in active combat and takes a round to aim can roll <strong>Careful Aim</strong> at a DC equal to their target''s REF×3 to gain a bonus on their next attack equal to half their <strong>Careful Aim</strong> value. Being spotted after making this roll but before attacking halves the bonus.'),
        ('false_identity', 'A Criminal can roll <strong>Eye Gouge</strong> in place of an attack to temporarily blind a target. <strong>Eye Gouge</strong> requires the Criminal to be in melee range and imposes a -3 to hit. However if it hits, the target takes an unmodified 2d6 damage and is blinded for a number of rounds equal to the <strong>Eye Gouge</strong> value.'),
        ('black_market', 'When ambushing a target, a Criminal can make an <strong>Assassin''s Strike</strong> roll against the target''s Awareness roll to conceal themselves after an attack. This ability can be used in any situation but it imposes penalties based on light and cover conditions. Multiple opponents can each roll to spot the Criminal.'),
        -- Craftsman skills
        ('large_catalog', 'A skilled Craftsman can keep a mental catalogue of diagrams in their head at all times. When a Craftsman has memorized as many diagrams as they can, they may roll <strong>Extensive Catalogue</strong> at DC:15 to memorize one more. There is no limit, but every 10 diagrams they have memorized adds 1 to the DC.'),
        ('apprentice', 'A Craftsman who begins crafting an item can roll <strong>Journeyman</strong> at a DC equal to the item''s crafting DC. If they succeed they add +1 DMG for weapons or +1 SP for armor for every 2 points they rolled above the DC. The maximum bonus they can give to DMG or SP is 5.'),
        ('masterwork', 'Master Crafting allows a Craftsman to make items that are master grade. They can also roll a <strong>Master Crafting</strong> roll at any time at a DC equal to the item''s crafting DC to permanently grant armor resistance (their choice) or weapons a 50% bleeding or -2 Stun value based on damage type.'),
        ('alchemical_concoction', 'A skilled Craftsman can keep a mental catalogue of formulae in their head at all times. When a Craftsman has memorized as many formulae as they can, they may roll <strong>Mental Pharmacy</strong> at DC:15 to memorize one more. There is no limit, but every 10 formulae they have memorized adds 1 to the DC.'),
        ('enhanced_potion', 'Any time a craftsman sets out to make an alchemical item they can make a <strong>Double Dose</strong> roll at a DCequal to the formula''s crafting DC. If they succeed they create two units of the formula with the ingredients of one. This applies to all items created with alchemy, including potions, oils, decoctions, and bombs.'),
        ('experimental_formula', 'Craftsmen can roll an <strong>Adaptation</strong> check (3 + the crafting DC) before making a witcher potion to lower its DC to avoid poisoning by 1 for every point they rolled over the crafting DC. If they fail, the potion comes out as poisonous as it normally would be. The DC to avoid poisoning can never be lower than 12.'),
        ('workshop', 'A Craftsman can make an <strong>Augmentation</strong> roll at a DC listed in the Augmentation chart to augment a weapon or Armor with their crafting tools. This augmentation takes 3 rounds. While a forge isn''t required, it grants a +2 to the roll. A fumble results in the item taking damage equal to the fumble value.'),
        ('repair', 'A Craftsman can coat an existing weapon in silver with a forge and a number of units of silver ingots based on the size of the weapon. The DC for this roll is 16. If you succeed, add +1d6 silver damage to a weapon per 3 points you rolled above the DC, up to 5d6. Failing the roll breaks the weapon.'),
        ('upgrade', 'A Craftsman can roll <strong>Pinpoint</strong> with a DC equal an item''s crafting DC to search for a flaw in the item''s design. This takes 1 turn studying, but allows the Craftsman to make a targeted attack at a -6 to do ablation damage to the armor or weapon equal to half their <strong>Pinpoint</strong> value in 6-sided dice.'),
        -- Merchant skills
        ('market', 'A Merchant can roll <strong>Options</strong> against a DC set by the GM to find a lower price on an item. If they succeed the Merchant finds another person selling the same item for half the price. The higher the item rarity, the higher the DC should be. <strong>Options</strong> does not affect experimental, witcher, or relic items.'),
        ('dirty_deal', 'When bribing a target a Merchant can roll <strong>Hard Bargain</strong> at a DC equal to the opponent''s WILLx3. If they succeed, they can bribe the opponent with any item they have at hand that is worth 5 crowns. The object always grants +3 to Persuasion. The DC rises by 5 for truly ridiculous bribes.'),
        ('promise', 'When attempting to buy an item, a Merchant can make a <strong>Promise</strong> roll at a DC equal to the Salesperson''s EMPx3. If they succeed the salesperson accepts the Merchant''s promise to pay for the item later. This promise holds the salesperson over for a number of weeks equal to your <strong>Promise</strong> ability.'),
        ('slums', 'A Merchant can make a <strong>Rookery</strong> roll at a DC based on the settlement they are in to gain the aid of 1 urchin or vagrant per 1 point they rolled over the DC (maximum 10). These people can be consulted to grant +1 per person on Streetwise rolls. Informants take 1 crown each as payment each time they are consulted.'),
        ('contacts', 'A Merchant with <strong>Insider</strong> can convince a person to spy for them. Spend 10 crowns and roll <strong>Insider</strong> versus the person''s Resist Coercion roll. If it is successful the person will spy on a target for as many days as your <strong>Insider</strong> value. At the end of this time you can roll again, but must pay again.'),
        ('merchant_network', 'Once per session a Merchant can roll <strong>Treasure Map</strong> at a DC set by the GM to remember the supposed location of a relic item, or a ruin that may hide something useful. This location will, of course, be out of the way or exceedingly dangerous, requiring a quest. Reaching this item or ruin should require a full session.'),
        ('haggle', 'On first entering a settlement, a Merchant can spend an hour spreading word of their arrival, then roll <strong>Well Connected</strong> at a DC based on the settlement. Success raises their reputation in that settlement by a number equal to the amount you rolled over the DC divided by 2 (minimum 1), for 1d6 Weeks.'),
        ('merchant_sense', 'A Merchant who has to get rid of a dubious or stolen item can make a <strong>Fence</strong> roll at a DC determined by the GM. If they succeed, they sell the item (at full market price) to a buyer who won''t ask any serious questions and won''t turn them in to the Guard.'),
        ('merchant_king', 'A Merchant can roll <strong>Warrior''s Debt</strong> to call on a fighter who owes them. Split your roll between the 3 sections on the Warrior table in the sidebar. This warrior will work for you for a number of days equal to your <strong>Warrior''s Debt</strong> value and takes any reasonable order you give without asking questions.')
      ) AS raw_data_en(skill_id, description)
  ),
  ins_prof_skill_descriptions AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id || '.wcc_skills.' || raw_prof_skill_descriptions.skill_id || '.description') AS id
         , meta.entity, 'description', raw_prof_skill_descriptions.lang, raw_prof_skill_descriptions.description
      FROM raw_prof_skill_descriptions
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
  )
UPDATE wcc_skills
SET skill_desc_id = ck_id('witcher_cc.wcc_skills.' || skill_id || '.description')
WHERE skill_type = 'professional'
  AND skill_desc_id IS NULL
  AND skill_id IN (
    'return_act', 'raise_a_crowd', 'good_friend', 'fade', 'spread_the_word', 'acclimatize',
    'poison_the_well', 'needling', 'et_tu_brute', 'meditation', 'magical_source', 'heliotrope',
    'iron_stomach', 'frenzy', 'transmutation', 'parry_arrows', 'quick_strike', 'whirl',
    'diagnose', 'analysis', 'effective_surgery', 'healing_tent', 'improvised_medicine', 'herbal_remedy',
    'bloody_wound', 'practical_butchery', 'crippling_wound', 'scheming', 'grape_vine', 'assets',
    'reverse_engineer', 'distillation', 'mutate', 'in_touch', 'immutable', 'expanded_magic',
    'extreme_range', 'twin_shot', 'precise_aim', 'bloodhound', 'warrior_trap', 'tactical_advantage',
    'fury', 'two_handed', 'ignore_pain', 'divine_power', 'divine_authority', 'foresight',
    'one_with_nature', 'nature_s_signs', 'nature_s_ally', 'bloody_rituals', 'zeal', 'holy_fire',
    'case_joint', 'repeat_lockpick', 'lay_low', 'vulnerability', 'take_note', 'intimidating_presence',
    'smuggler', 'false_identity', 'black_market', 'large_catalog', 'apprentice', 'masterwork',
    'alchemical_concoction', 'enhanced_potion', 'experimental_formula', 'workshop', 'repair', 'upgrade',
    'market', 'dirty_deal', 'promise', 'slums', 'contacts', 'merchant_network', 'haggle', 'merchant_sense', 'merchant_king'
  )
  AND EXISTS (
    SELECT 1 FROM i18n_text 
    WHERE id = ck_id('witcher_cc.wcc_skills.' || wcc_skills.skill_id || '.description')
  );

-- Вставка профессий (Bard, Witcher, Mage)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id, 'wcc_professions' AS entity),
  raw_professions AS (
    SELECT 'ru' AS lang, raw_data_ru.*
      FROM (VALUES
        ('bard', 'Бард', 'core'),
        ('witcher', 'Ведьмак', 'core'),
        ('doctor', 'Медик', 'core'),
        ('mage', 'Маг', 'core'),
        ('man_at_arms', 'Воин', 'core'),
        ('priest', 'Жрец', 'core'),
        ('criminal', 'Преступник', 'core'),
        ('craftsman', 'Ремесленник', 'core'),
        ('merchant', 'Торговец', 'core')
      ) AS raw_data_ru(prof_id, name, dlc)
    UNION ALL
    SELECT 'en' AS lang, prof_id, name, dlc
      FROM (VALUES
        ('bard', 'Bard', 'core'),
        ('witcher', 'Witcher', 'core'),
        ('doctor', 'Doctor', 'core'),
        ('mage', 'Mage', 'core'),
        ('man_at_arms', 'Man At Arms', 'core'),
        ('priest', 'Priest', 'core'),
        ('criminal', 'Criminal', 'core'),
        ('craftsman', 'Craftsman', 'core'),
        ('merchant', 'Merchant', 'core')
      ) AS raw_data_en(prof_id, name, dlc)
  ),
  ins_prof_names AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id || '.wcc_professions.' || raw_professions.prof_id || '.name') AS id
         , meta.entity, 'name', raw_professions.lang, raw_professions.name
      FROM raw_professions
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
  )
INSERT INTO wcc_professions (prof_id, dlc, prof_name_id, prof_desc_id)
SELECT DISTINCT
  raw_professions.prof_id,
  raw_professions.dlc,
  ck_id(meta.su_su_id || '.wcc_professions.' || raw_professions.prof_id || '.name') AS prof_name_id,
  -- prof_desc_id will be set to NULL initially and updated later when profession descriptions 
  -- are inserted in 090_* files. The ID format matches: witcher_cc.wcc_profession_o{NN}.answer_options.description
  NULL::uuid AS prof_desc_id
FROM raw_professions
CROSS JOIN meta
WHERE raw_professions.lang = 'ru'
ON CONFLICT (prof_id) DO NOTHING;

-- Update prof_desc_id after profession descriptions are created in 090_* files
-- This will be executed after those files run
UPDATE wcc_professions
SET prof_desc_id = ck_id('witcher_cc.wcc_profession_o' || 
  CASE prof_id
    WHEN 'bard' THEN '01'
      WHEN 'witcher' THEN '02'
      WHEN 'doctor' THEN '03'
      WHEN 'mage' THEN '04'
      WHEN 'man_at_arms' THEN '05'
      WHEN 'priest' THEN '06'
      WHEN 'criminal' THEN '07'
      WHEN 'craftsman' THEN '08'
      WHEN 'merchant' THEN '09'
    END || '.answer_options.description')
WHERE prof_desc_id IS NULL
  AND EXISTS (
    SELECT 1 FROM i18n_text 
    WHERE id = ck_id('witcher_cc.wcc_profession_o' || 
      CASE wcc_professions.prof_id
        WHEN 'bard' THEN '01'
        WHEN 'witcher' THEN '02'
        WHEN 'doctor' THEN '03'
        WHEN 'mage' THEN '04'
        WHEN 'man_at_arms' THEN '05'
        WHEN 'priest' THEN '06'
        WHEN 'criminal' THEN '07'
        WHEN 'craftsman' THEN '08'
        WHEN 'merchant' THEN '09'
      END || '.answer_options.description')
  );

-- Вставка связей профессий и навыков (Bard)
INSERT INTO wcc_profession_skills (prof_id, skill_skill_id)
SELECT 'bard', skill_id
FROM wcc_skills
WHERE skill_id IN (
  'language', 'streetwise', 'social_etiquette', 'performance', 'fine_arts', 
  'deceit', 'human_perception', 'seduction', 'persuasion', 'charisma'
)
ON CONFLICT (prof_id, skill_skill_id) DO NOTHING;

-- Вставка связей профессий и навыков (Witcher)
INSERT INTO wcc_profession_skills (prof_id, skill_skill_id)
SELECT 'witcher', skill_id
FROM wcc_skills
WHERE skill_id IN (
  'spell_casting', 'awareness', 'wilderness_survival', 'deduction', 
  'athletics', 'stealth', 'riding', 'swordsmanship', 'dodge_escape', 'alchemy'
)
ON CONFLICT (prof_id, skill_skill_id) DO NOTHING;

-- Вставка связей профессий и навыков (Mage)
INSERT INTO wcc_profession_skills (prof_id, skill_skill_id)
SELECT 'mage', skill_id
FROM wcc_skills
WHERE skill_id IN (
  'hex_weaving', 'ritual_crafting', 'resist_magic', 'spell_casting',
  'education', 'social_etiquette', 'staff_spear', 'grooming_and_style',
  'seduction', 'human_perception'
)
ON CONFLICT (prof_id, skill_skill_id) DO NOTHING;

-- Вставка определяющих навыков (main skills) в связи профессий
INSERT INTO wcc_profession_skills (prof_id, skill_skill_id)
VALUES
  ('bard', 'busking'),
  ('witcher', 'witcher_training'),
  ('doctor', 'healing_hands'),
  ('mage', 'magical_training'),
  ('man_at_arms', 'tough_as_nails'),
  ('priest', 'dedicated'),
  ('criminal', 'professional_paranoia'),
  ('craftsman', 'quick_fix'),
  ('merchant', 'well_traveled')
ON CONFLICT (prof_id, skill_skill_id) DO NOTHING;

-- Вставка связей профессий и навыков (Doctor)
INSERT INTO wcc_profession_skills (prof_id, skill_skill_id)
SELECT 'doctor', skill_id
FROM wcc_skills
WHERE skill_id IN (
  'resist_coercion', 'courage', 'wilderness_survival', 'deduction',
  'business', 'social_etiquette', 'small_blades', 'alchemy',
  'human_perception', 'charisma'
)
ON CONFLICT (prof_id, skill_skill_id) DO NOTHING;

-- Вставка связей профессий и навыков (Man At Arms)
INSERT INTO wcc_profession_skills (prof_id, skill_skill_id)
SELECT 'man_at_arms', skill_id
FROM wcc_skills
WHERE skill_id IN (
  'athletics', 'staff_spear', 'small_blades', 'swordsmanship',
  'crossbow', 'archery', 'tactics', 'melee', 'brawling',
  'riding', 'intimidation', 'courage', 'wilderness_survival',
  'dodge_escape', 'physique'
)
ON CONFLICT (prof_id, skill_skill_id) DO NOTHING;

-- Вставка связей профессий и навыков (Priest)
INSERT INTO wcc_profession_skills (prof_id, skill_skill_id)
SELECT 'priest', skill_id
FROM wcc_skills
WHERE skill_id IN (
  'hex_weaving', 'ritual_crafting', 'spell_casting', 'courage',
  'wilderness_survival', 'teaching', 'first_aid', 'leadership',
  'human_perception', 'charisma'
)
ON CONFLICT (prof_id, skill_skill_id) DO NOTHING;

-- Вставка связей профессий и навыков (Criminal)
INSERT INTO wcc_profession_skills (prof_id, skill_skill_id)
SELECT 'criminal', skill_id
FROM wcc_skills
WHERE skill_id IN (
  'intimidation', 'awareness', 'streetwise', 'athletics',
  'sleight_of_hand', 'stealth', 'small_blades', 'pick_lock',
  'forgery', 'deceit'
)
ON CONFLICT (prof_id, skill_skill_id) DO NOTHING;

-- Вставка связей профессий и навыков (Craftsman)
INSERT INTO wcc_profession_skills (prof_id, skill_skill_id)
SELECT 'craftsman', skill_id
FROM wcc_skills
WHERE skill_id IN (
  'education', 'streetwise', 'business', 'athletics',
  'alchemy', 'crafting', 'physique', 'endurance',
  'fine_arts', 'persuasion'
)
ON CONFLICT (prof_id, skill_skill_id) DO NOTHING;

-- Вставка связей профессий и навыков (Merchant)
INSERT INTO wcc_profession_skills (prof_id, skill_skill_id)
SELECT 'merchant', skill_id
FROM wcc_skills
WHERE skill_id IN (
  'resist_coercion', 'education', 'streetwise', 'business',
  'language', 'small_blades', 'gambling', 'human_perception',
  'persuasion', 'charisma'
)
ON CONFLICT (prof_id, skill_skill_id) DO NOTHING;

-- Вставка связей профессий с профессиональными навыками (Bard)
INSERT INTO wcc_profession_skills (prof_id, skill_skill_id)
SELECT 'bard', skill_id
FROM wcc_skills
WHERE skill_id IN (
  'return_act', 'raise_a_crowd', 'good_friend',
  'fade', 'spread_the_word', 'acclimatize',
  'poison_the_well', 'needling', 'et_tu_brute'
)
ON CONFLICT (prof_id, skill_skill_id) DO NOTHING;

-- Вставка связей профессий с профессиональными навыками (Witcher)
INSERT INTO wcc_profession_skills (prof_id, skill_skill_id)
SELECT 'witcher', skill_id
FROM wcc_skills
WHERE skill_id IN (
  'meditation', 'magical_source', 'heliotrope',
  'iron_stomach', 'frenzy', 'transmutation',
  'parry_arrows', 'quick_strike', 'whirl'
)
ON CONFLICT (prof_id, skill_skill_id) DO NOTHING;

-- Вставка связей профессий с профессиональными навыками (Mage)
INSERT INTO wcc_profession_skills (prof_id, skill_skill_id)
SELECT 'mage', skill_id
FROM wcc_skills
WHERE skill_id IN (
  'scheming', 'grape_vine', 'assets',
  'reverse_engineer', 'distillation', 'mutate',
  'in_touch', 'immutable', 'expanded_magic'
)
ON CONFLICT (prof_id, skill_skill_id) DO NOTHING;

-- Вставка связей профессий с профессиональными навыками (Doctor)
INSERT INTO wcc_profession_skills (prof_id, skill_skill_id)
SELECT 'doctor', skill_id
FROM wcc_skills
WHERE skill_id IN (
  'diagnose', 'analysis', 'effective_surgery',
  'healing_tent', 'improvised_medicine', 'herbal_remedy',
  'bloody_wound', 'practical_butchery', 'crippling_wound'
)
ON CONFLICT (prof_id, skill_skill_id) DO NOTHING;

-- Вставка связей профессий с профессиональными навыками (Man At Arms)
INSERT INTO wcc_profession_skills (prof_id, skill_skill_id)
SELECT 'man_at_arms', skill_id
FROM wcc_skills
WHERE skill_id IN (
  'extreme_range', 'twin_shot', 'precise_aim',
  'bloodhound', 'warrior_trap', 'tactical_advantage',
  'fury', 'two_handed', 'ignore_pain'
)
ON CONFLICT (prof_id, skill_skill_id) DO NOTHING;

-- Вставка связей профессий с профессиональными навыками (Priest)
INSERT INTO wcc_profession_skills (prof_id, skill_skill_id)
SELECT 'priest', skill_id
FROM wcc_skills
WHERE skill_id IN (
  'divine_power', 'divine_authority', 'foresight',
  'one_with_nature', 'nature_s_signs', 'nature_s_ally',
  'bloody_rituals', 'zeal', 'holy_fire'
)
ON CONFLICT (prof_id, skill_skill_id) DO NOTHING;

-- Вставка связей профессий с профессиональными навыками (Criminal)
INSERT INTO wcc_profession_skills (prof_id, skill_skill_id)
SELECT 'criminal', skill_id
FROM wcc_skills
WHERE skill_id IN (
  'case_joint', 'repeat_lockpick', 'lay_low',
  'vulnerability', 'take_note', 'intimidating_presence',
  'smuggler', 'false_identity', 'black_market'
)
ON CONFLICT (prof_id, skill_skill_id) DO NOTHING;

-- Вставка связей профессий с профессиональными навыками (Craftsman)
INSERT INTO wcc_profession_skills (prof_id, skill_skill_id)
SELECT 'craftsman', skill_id
FROM wcc_skills
WHERE skill_id IN (
  'large_catalog', 'apprentice', 'masterwork',
  'alchemical_concoction', 'enhanced_potion', 'experimental_formula',
  'workshop', 'repair', 'upgrade'
)
ON CONFLICT (prof_id, skill_skill_id) DO NOTHING;

-- Вставка связей профессий с профессиональными навыками (Merchant)
INSERT INTO wcc_profession_skills (prof_id, skill_skill_id)
SELECT 'merchant', skill_id
FROM wcc_skills
WHERE skill_id IN (
  'market', 'dirty_deal', 'promise',
  'slums', 'contacts', 'merchant_network',
  'haggle', 'merchant_sense', 'merchant_king'
)
ON CONFLICT (prof_id, skill_skill_id) DO NOTHING;

