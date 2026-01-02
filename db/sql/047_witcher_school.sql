\echo '047_witcher_school.sql'
-- Узел: В какой школе вы обучались?

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_school' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
              ('ru', 'Где проходили обучение и какие особенности школы вы унаследовали?'),
              ('en', 'Where did you train and what traits of the school did you inherit?')
           ) AS v(lang, text)
      CROSS JOIN meta
  )
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Эффект'),
      ('ru', 3, 'Школа'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Effect'),
      ('en', 3, 'School')
)
, ins_c   AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| 'column_name') AS id
         , meta.entity, 'column_name', c_vals.lang, c_vals.text
      FROM c_vals
      CROSS JOIN meta
)
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
SELECT meta.qu_id
     , meta.su_su_id
     , NULL
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body')
     , 'single_table'
     , jsonb_build_object(
         'dice', 'd_weighed',
         'columns', (
           SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_witcher_school' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
           FROM (SELECT DISTINCT num FROM c_vals) AS cols
         ),
         'path', jsonb_build_array(
           ck_id('witcher_cc.hierarchy.witcher')::text,
           ck_id('witcher_cc.hierarchy.witcher_school')::text
         )
       )
    FROM meta;

-- Ответы
WITH
raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
      (1, 0.2, 'Нет штрафов при сильной атаке', '<b>Школа Волка</b><br>Вы учились в Каэр Морхене в высоких Синих горах. Обучение было трудным и структурированным, основанным на сбалансированном подходе к ведьмачьей профессии. Вас учили бить сильно и быстро, чтобы как можно скорее закончить охоту.'),
      (2, 0.2, '+2 к Энергии', '<b>Школа Грифона</b><br>Вас обучали в Каэр И Серен на побережье у Драконьих гор. Обучение было сосредоточено на сражении с несколькими противниками одновременно и на максимальном использовании ваших ограниченных магических способностей.'),
      (3, 0.2, 'Невосприимчивость ко всем немагическим попыткам обольщения', '<b>Школа Кота</b><br>Вы обучались в караване Дин Марв — странствующем отряде ведьмаков, готовых работать на любого, кто заплатит. Мутации и тренировки искалечили вашу психику, и вам приходится сдерживать жестокость и тягу к насилию.'),
      (4, 0.2, 'Нет штрафов за парное оружие', '<b>Школа Змеи</b><br>Вы тренировались в Гортгур Гвед в глубинных пещерах хребта Тир Тохаир. В отличие от прочих ведьмаков, вы обучены владению двумя клинками и убийству чудовищ методами наёмных убийц.'),
      (5, 0.2, '-2 к Скованности Движений', '<b>Школа Медведя</b><br>Вы проходили обучение на заснеженных вершинах гор Амелл, в Хэрн Кадух. Вы закалили тело, чтобы выдерживать любые повреждения, и научились быстро и эффективно двигаться в тяжёлой стальной броне.')
    ) AS raw_data_ru(num, probability, effect, txt)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
      (1, 0.2, 'No Penalty For Strong Strikes', '<b>The Wolf School</b><br>You trained at Kaer Morhen in the heights of the Blue Mountains. Your training was tough and structured, focusing on a very rounded approach to the Witcher profession. You were taught to strike hard and fast to end hunts quickly.'),
      (2, 0.2, '+2 Vigor Threshold', '<b>The Gryphon School</b><br>You were trained at Kaer Y Seren along the coastal side of the Dragon Mountains. Your training was heavily focused on fighting any number of opponents and using your limited magical power to its greatest potential.'),
      (3, 0.2, 'Immune to Non-Magical Charm Attempts', '<b>The Cat School</b><br>You trained in the Dyn Marv Caravan, a traveling troop of witchers who sold their skills to anyone who could pay, for any job. Their mutations and training flayed your emotions, and you struggle against violent, cruel impulses.'),
      (4, 0.2, 'No Penalties for Dual Wielding', '<b>The Viper School</b><br>You trained at Gorthwr Gvaed in the deep chasms of the Tir Tochair Mountains. Unlike other witchers, you were trained on twin blades and an assassination-based approach to killing monsters.'),
      (5, 0.2, '-2 to Overall Armor Penalty', '<b>The Bear School</b><br>You trained in the snowy heights of the Amell Mountains at Haern Cadvch. You conditioned your body to endure all manner of punishment and move quickly and efficiently in heavy steel armor.')
    ) AS raw_data_en(num, probability, effect, txt)
),
vals AS (
  SELECT
    ('<td>' || to_char(probability*100, 'FM990.00') || '%</td>'
     || '<td>' || effect || '</td>'
     || '<td>' || txt || '</td>') AS text,
    num, probability, lang
  FROM raw_data
)
, meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_school' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, ins_label AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
       , meta.entity, meta.entity_field, vals.lang, vals.text
  FROM vals
  CROSS JOIN meta
)
-- Создаем i18n записи для перков (название и описание в одной строке)
, ins_perks AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  VALUES
    -- Школа Волка (o01)
    (ck_id('witcher_cc.wcc_witcher_school_o01.perks.description'), 'perks', 'description', 'ru', '<b>Школа Волка</b>: Нет штрафов при сильной атаке.'),
    (ck_id('witcher_cc.wcc_witcher_school_o01.perks.description'), 'perks', 'description', 'en', '<b>The Wolf School</b>: No Penalty For Strong Strikes.'),
    -- Школа Грифона (o02)
    (ck_id('witcher_cc.wcc_witcher_school_o02.perks.description'), 'perks', 'description', 'ru', '<b>Школа Грифона</b>: [+2 к Энергии].'),
    (ck_id('witcher_cc.wcc_witcher_school_o02.perks.description'), 'perks', 'description', 'en', '<b>The Gryphon School</b>: [+2 to Vigor Threshold].'),
    -- Школа Кота (o03)
    (ck_id('witcher_cc.wcc_witcher_school_o03.perks.description'), 'perks', 'description', 'ru', '<b>Школа Кота</b>: Невосприимчивость ко всем немагическим попыткам обольщения.'),
    (ck_id('witcher_cc.wcc_witcher_school_o03.perks.description'), 'perks', 'description', 'en', '<b>The Cat School</b>: Immune to Non-Magical Charm Attempts.'),
    -- Школа Змеи (o04)
    (ck_id('witcher_cc.wcc_witcher_school_o04.perks.description'), 'perks', 'description', 'ru', '<b>Школа Змеи</b>: Нет штрафов за парное оружие.'),
    (ck_id('witcher_cc.wcc_witcher_school_o04.perks.description'), 'perks', 'description', 'en', '<b>The Viper School</b>: No Penalties for Dual Wielding.'),
    -- Школа Медведя (o05)
    (ck_id('witcher_cc.wcc_witcher_school_o05.perks.description'), 'perks', 'description', 'ru', '<b>Школа Медведя</b>: -2 к Скованности Движений.'),
    (ck_id('witcher_cc.wcc_witcher_school_o05.perks.description'), 'perks', 'description', 'en', '<b>The Bear School</b>: -2 to Overall Armor Penalty.')
  ON CONFLICT (id, lang) DO NOTHING
)
-- Создаем i18n записи для characterRaw.lore.school (литературное описание)
, ins_school_lore AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  VALUES
    -- Школа Волка (o01)
    (ck_id('witcher_cc.wcc_witcher_school_o01.lore.school'), 'lore', 'school', 'ru', 'Вы учились в Школе Волка, что в Каэр Морхене, в высоких Синих горах. Вас учили бить сильно и быстро, чтобы как можно скорее закончить охоту.'),
    (ck_id('witcher_cc.wcc_witcher_school_o01.lore.school'), 'lore', 'school', 'en', 'You trained at the Wolf School, located at Kaer Morhen in the heights of the Blue Mountains. You were taught to strike hard and fast to end hunts quickly.'),
    -- Школа Грифона (o02)
    (ck_id('witcher_cc.wcc_witcher_school_o02.lore.school'), 'lore', 'school', 'ru', 'Вы учились в Школе Грифона, что в Каэр И Серен, на побережье у Драконьих гор. Вас учили сосредотачиваться на магических способностях в сражениях с несколькими противниками.'),
    (ck_id('witcher_cc.wcc_witcher_school_o02.lore.school'), 'lore', 'school', 'en', 'You trained at the Gryphon School, located at Kaer Y Seren along the coastal side of the Dragon Mountains. You were taught to focus on magical abilities in battles against multiple opponents.'),
    -- Школа Кота (o03)
    (ck_id('witcher_cc.wcc_witcher_school_o03.lore.school'), 'lore', 'school', 'ru', 'Вы учились в Школе Кота, в караване Дин Марв — странствующем отряде ведьмаков. Обучение повредило психику, вам приходится сдерживать жестокость и тягу к насилию.'),
    (ck_id('witcher_cc.wcc_witcher_school_o03.lore.school'), 'lore', 'school', 'en', 'You trained at the Cat School, in the Dyn Marv Caravan, a traveling troop of witchers. The training damaged your psyche, and you must restrain cruelty and the urge for violence.'),
    -- Школа Змеи (o04)
    (ck_id('witcher_cc.wcc_witcher_school_o04.lore.school'), 'lore', 'school', 'ru', 'Вы учились в Школе Змеи, что в Гортгур Гвед, в пещерах хребта Тир Тохаир. Вы обучены владению двумя клинками и убийству чудовищ методами наёмных убийц.'),
    (ck_id('witcher_cc.wcc_witcher_school_o04.lore.school'), 'lore', 'school', 'en', 'You trained at the Viper School, located at Gorthwr Gvaed in the caves of the Tir Tochair Mountains. You were trained in dual blades and killing monsters using assassin methods.'),
    -- Школа Медведя (o05)
    (ck_id('witcher_cc.wcc_witcher_school_o05.lore.school'), 'lore', 'school', 'ru', 'Вы учились в Школе Медведя, что в Хэрн Кадух, в горах Амелл. Тренировки закалили тело и научили эффективно двигаться в тяжёлой стальной броне.'),
    (ck_id('witcher_cc.wcc_witcher_school_o05.lore.school'), 'lore', 'school', 'en', 'You trained at the Bear School, located at Haern Cadvch in the Amell Mountains. The training hardened your body and taught you to move efficiently in heavy steel armor.')
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
SELECT
  'wcc_witcher_school_o' || to_char(vals.num, 'FM00') AS an_id,
  meta.su_su_id,
  meta.qu_id,
  ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
  vals.num,
  jsonb_build_object(
           'probability', vals.probability
  )
FROM vals
CROSS JOIN meta
ON CONFLICT (an_id) DO NOTHING;

-- Эффекты: добавление перков в characterRaw.perks и сохранение описания школы в characterRaw.lore.school
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_school' AS qu_id)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_witcher_school_o01',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o01.perks.description')::text)
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_school_o01',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.school'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o01.lore.school')::text)
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_school_o02',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o02.perks.description')::text)
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_school_o02',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.school'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o02.lore.school')::text)
    )
  )
FROM meta
UNION ALL
-- Эффект для Школы Грифона: +2 к vigor.bonus
SELECT 'character', 'wcc_witcher_school_o02',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.statistics.vigor.bonus'),
      2
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_school_o03',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o03.perks.description')::text)
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_school_o03',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.school'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o03.lore.school')::text)
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_school_o04',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o04.perks.description')::text)
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_school_o04',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.school'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o04.lore.school')::text)
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_school_o05',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o05.perks.description')::text)
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_school_o05',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.school'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o05.lore.school')::text)
    )
  )
FROM meta;

-- Прямая связь со следующим шагом
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_witcher_when', 'wcc_witcher_school';






















