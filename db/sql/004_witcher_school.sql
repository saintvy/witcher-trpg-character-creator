\echo '004_witcher_school.sql'
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
      (1, 0.2, 'Нет штрафов при сильной атаке', '<b><span style="color: #808080">Школа Волка</span></b><br>Вы учились в Каэр Морхене в высоких Синих горах. Обучение было трудным и структурированным, основанным на сбалансированном подходе к ведьмачьей профессии. Вас учили бить сильно и быстро, чтобы как можно скорее закончить охоту.'),
      (2, 0.2, '+2 к Энергии', '<b><span style="color: #4A9BD6">Школа Грифона</span></b><br>Вас обучали в Каэр И Серен на побережье у Драконьих гор. Обучение было сосредоточено на сражении с несколькими противниками одновременно и на максимальном использовании ваших ограниченных магических способностей.'),
      (3, 0.2, 'Невосприимчивость ко всем немагическим попыткам обольщения', '<b><span style="color: #E85A7F">Школа Кота</span></b><br>Вы обучались в караване Дин Марв — странствующем отряде ведьмаков, готовых работать на любого, кто заплатит. Мутации и тренировки искалечили вашу психику, и вам приходится сдерживать жестокость и тягу к насилию.'),
      (4, 0.2, 'Нет штрафов за парное оружие', '<b><span style="color: #4EC04E">Школа Змеи</span></b><br>Вы тренировались в Гортгур Гвед в глубинных пещерах хребта Тир Тохаир. В отличие от прочих ведьмаков, вы обучены владению двумя клинками и убийству чудовищ методами наёмных убийц.'),
      (5, 0.2, '-2 к Скованности Движений', '<b><span style="color: #A67C00">Школа Медведя</span></b><br>Вы проходили обучение на заснеженных вершинах гор Амелл, в Хэрн Кадух. Вы закалили тело, чтобы выдерживать любые повреждения, и научились быстро и эффективно двигаться в тяжёлой стальной броне.'),
      (6, 0.2, 'Не требуется действие для извлечения/убирания щита, нет штрафов за парирование щитом, можно использовать руку со щитом для знаков, бомб и эликсиров.', '<b><span style="color: #FF8800">Школа Мантикоры</span></b><br>Ведьмаки школы Мантикоры — это в первую очередь защитники, что прекрасно отражено в их боевой подготовке. Они великолепно обучены обращению со специальными щитами, которые для них производит мастер-оружейник из крепости Бехельт Нар.'),
      (7, 0.2, '-3 к проверке врага на захват, +3 к сопротивлению разоружению на 1 минуту за 1 Вын и 1 Действие.', '<b><span style="color: #8B8B5A">Школа Улитки</span></b><br>Неудачные мутации “Школы Улитки” оказали несколько мощных воздействий на ее членов, наиболее заметным из которых было изменение их потовых желез. В стрессовых ситуациях, когда пульс учащается, таких как бой, ведьмак Школы Улитки потеет вязким, похожим на слизь веществом, которое неизменно просачивается сквозь его одежду или доспехи, делая их скользкими на ощупь.')
    ) AS raw_data_ru(num, probability, effect, txt)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
      (1, 0.2, 'No Penalty For Strong Strikes', '<b><span style="color: #808080">The Wolf School</span></b><br>You trained at Kaer Morhen in the heights of the Blue Mountains. Your training was tough and structured, focusing on a very rounded approach to the Witcher profession. You were taught to strike hard and fast to end hunts quickly.'),
      (2, 0.2, '+2 Vigor Threshold', '<b><span style="color: #4A9BD6">The Gryphon School</span></b><br>You were trained at Kaer Y Seren along the coastal side of the Dragon Mountains. Your training was heavily focused on fighting any number of opponents and using your limited magical power to its greatest potential.'),
      (3, 0.2, 'Immune to Non-Magical Charm Attempts', '<b><span style="color: #E85A7F">The Cat School</span></b><br>You trained in the Dyn Marv Caravan, a traveling troop of witchers who sold their skills to anyone who could pay, for any job. Their mutations and training flayed your emotions, and you struggle against violent, cruel impulses.'),
      (4, 0.2, 'No Penalties for Dual Wielding', '<b><span style="color: #4EC04E">The Viper School</span></b><br>You trained at Gorthwr Gvaed in the deep chasms of the Tir Tochair Mountains. Unlike other witchers, you were trained on twin blades and an assassination-based approach to killing monsters.'),
      (5, 0.2, '-2 to Overall Armor Penalty', '<b><span style="color: #A67C00">The Bear School</span></b><br>You trained in the snowy heights of the Amell Mountains at Haern Cadvch. You conditioned your body to endure all manner of punishment and move quickly and efficiently in heavy steel armor.'),
      (6, 0.2, 'No action required to draw/stow a shield; no penalties for parrying with a shield; you can use the shield hand for signs, bombs, and potions.', '<b><span style="color: #FF8800">The Manticore School</span></b><br>Witchers of the Manticore School are defenders first and foremost and their training reflects that. These witchers are extensively trained in the use of special shields crafted for them by master craftsman at Behelt Nar.'),
      (7, 0.2, '-3 to enemy grapple checks; +3 to resist Disarm for 1 minute for 1 Stamina and 1 Action.', '<b><span style="color: #8B8B5A">The Snail School</span></b><br>The botched mutations of The School of the Snail had a few potent effects on its members, most notably being a change to their sweat glands. When in stressful or pulse pounding situations such as combat, a witcher of The School of the Snail sweats a viscous, mucus-like substance which invariably leaks through their clothing or armor, making them slick to the touch.')
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
, ins_visible_rules AS (
  -- Правила видимости DLC-вариантов школ и проверки DLC (проверяем наличие DLC в state.dlcs)
  INSERT INTO rules (ru_id, name, body)
  VALUES
    (ck_id('witcher_cc.rules.is_manticore_school'), 'is_manticore_school', '{"in":["dlc_sch_manticore",{"var":["dlcs",[]]}]}'::jsonb),
    (ck_id('witcher_cc.rules.is_snail_school'), 'is_snail_school', '{"in":["dlc_sch_snail",{"var":["dlcs",[]]}]}'::jsonb),
    (ck_id('witcher_cc.rules.is_dlc_wt_enabled'), 'is_dlc_wt_enabled', '{"in":["dlc_wt",{"var":["dlcs",[]]}]}'::jsonb)
  ON CONFLICT (ru_id) DO NOTHING
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
    (ck_id('witcher_cc.wcc_witcher_school_o05.perks.description'), 'perks', 'description', 'en', '<b>The Bear School</b>: -2 to Overall Armor Penalty.'),
    -- Школа Мантикоры (o06) [DLC]
    (ck_id('witcher_cc.wcc_witcher_school_o06.perks.description'), 'perks', 'description', 'ru', '<b>Школа Мантикоры</b>: Не требуется действие для извлечения/убирания щита, нет штрафов за парирование щитом, можно использовать руку со щитом для знаков, бомб и эликсиров.'),
    (ck_id('witcher_cc.wcc_witcher_school_o06.perks.description'), 'perks', 'description', 'en', '<b>The Manticore School</b>: No action required to draw/stow a shield; no penalties for parrying with a shield; you can use the shield hand for signs, bombs, and potions.'),
    -- Школа Улитки (o07) [DLC]
    (ck_id('witcher_cc.wcc_witcher_school_o07.perks.description'), 'perks', 'description', 'ru', '<b>Школа Улитки</b>: -3 к проверке врага на захват, +3 к сопротивлению разоружению на 1 минуту за 1 Вын и 1 Действие (нельзя бросить оружие), слизь оставляет шелушащуюся корочку.'),
    (ck_id('witcher_cc.wcc_witcher_school_o07.perks.description'), 'perks', 'description', 'en', '<b>The Snail School</b>: -3 to enemy grapple checks; +3 to resist Disarm for 1 minute for 1 Stamina and 1 Action (you can''t drop your weapon); the slime leaves a flaky residue.')
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
    (ck_id('witcher_cc.wcc_witcher_school_o05.lore.school'), 'lore', 'school', 'en', 'You trained at the Bear School, located at Haern Cadvch in the Amell Mountains. The training hardened your body and taught you to move efficiently in heavy steel armor.'),
    -- Школа Мантикоры (o06) [DLC]
    (ck_id('witcher_cc.wcc_witcher_school_o06.lore.school'), 'lore', 'school', 'ru', 'Вы учились в Школе Мантикоры. Ведьмаки этой школы — защитники, обученные обращению со специальными щитами, изготовленными мастерами из Бехельт Нара.'),
    (ck_id('witcher_cc.wcc_witcher_school_o06.lore.school'), 'lore', 'school', 'en', 'You trained at the Manticore School. Witchers of this school are defenders trained to use special shields crafted by master craftsmen at Behelt Nar.'),
    -- Школа Улитки (o07) [DLC]
    (ck_id('witcher_cc.wcc_witcher_school_o07.lore.school'), 'lore', 'school', 'ru', 'Вы учились в Школе Улитки. Неудачные мутации изменили их потовые железы: в стрессовых ситуациях ведьмаки выделяют вязкую слизь, делая доспех и одежду скользкими.'),
    (ck_id('witcher_cc.wcc_witcher_school_o07.lore.school'), 'lore', 'school', 'en', 'You trained at the Snail School. Their botched mutations altered their sweat glands, causing them to exude a viscous slime in stressful situations, leaving clothing and armor slick.')
  ON CONFLICT (id, lang) DO NOTHING
)
, ins_school_names AS (
  -- Короткое локализованное название школы (для characterRaw.school)
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  VALUES
    (ck_id('witcher_cc.wcc_witcher_school_o01.school.name'), 'character', 'school', 'ru', 'Школа Волка'),
    (ck_id('witcher_cc.wcc_witcher_school_o01.school.name'), 'character', 'school', 'en', 'The Wolf School'),
    (ck_id('witcher_cc.wcc_witcher_school_o02.school.name'), 'character', 'school', 'ru', 'Школа Грифона'),
    (ck_id('witcher_cc.wcc_witcher_school_o02.school.name'), 'character', 'school', 'en', 'The Gryphon School'),
    (ck_id('witcher_cc.wcc_witcher_school_o03.school.name'), 'character', 'school', 'ru', 'Школа Кота'),
    (ck_id('witcher_cc.wcc_witcher_school_o03.school.name'), 'character', 'school', 'en', 'The Cat School'),
    (ck_id('witcher_cc.wcc_witcher_school_o04.school.name'), 'character', 'school', 'ru', 'Школа Змеи'),
    (ck_id('witcher_cc.wcc_witcher_school_o04.school.name'), 'character', 'school', 'en', 'The Viper School'),
    (ck_id('witcher_cc.wcc_witcher_school_o05.school.name'), 'character', 'school', 'ru', 'Школа Медведя'),
    (ck_id('witcher_cc.wcc_witcher_school_o05.school.name'), 'character', 'school', 'en', 'The Bear School'),
    (ck_id('witcher_cc.wcc_witcher_school_o06.school.name'), 'character', 'school', 'ru', 'Школа Мантикоры'),
    (ck_id('witcher_cc.wcc_witcher_school_o06.school.name'), 'character', 'school', 'en', 'The Manticore School'),
    (ck_id('witcher_cc.wcc_witcher_school_o07.school.name'), 'character', 'school', 'ru', 'Школа Улитки'),
    (ck_id('witcher_cc.wcc_witcher_school_o07.school.name'), 'character', 'school', 'en', 'The Snail School')
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT
  'wcc_witcher_school_o' || to_char(vals.num, 'FM00') AS an_id,
  meta.su_su_id,
  meta.qu_id,
  ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
  vals.num,
  CASE
    WHEN vals.num = 6 THEN ck_id('witcher_cc.rules.is_manticore_school')
    WHEN vals.num = 7 THEN ck_id('witcher_cc.rules.is_snail_school')
    ELSE NULL
  END AS visible_ru_ru_id,
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

-- DLC: Мантикора (o06) и Улитка (o07)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_school' AS qu_id)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_witcher_school_o06',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o06.perks.description')::text)
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_school_o06',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.school'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o06.lore.school')::text)
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_school_o07',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o07.perks.description')::text)
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_school_o07',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.school'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o07.lore.school')::text)
    )
  )
FROM meta
;

-- Эффекты: короткое название школы + латинский код (для будущих правил)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_school' AS qu_id)
, schools(opt, school_code) AS (
  VALUES
    ('o01', 'wolf'),
    ('o02', 'gryphon'),
    ('o03', 'cat'),
    ('o04', 'viper'),
    ('o05', 'bear'),
    ('o06', 'manticore'),
    ('o07', 'snail')
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  meta.qu_id || '_' || schools.opt AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.school'),
      jsonb_build_object(
        'i18n_uuid',
        ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_'|| schools.opt ||'.school.name')::text
      )
    )
  ) AS body
FROM meta
CROSS JOIN schools
UNION ALL
SELECT
  'character' AS scope,
  meta.qu_id || '_' || schools.opt AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.logicFields.witcher_school'),
      schools.school_code
    )
  ) AS body
FROM meta
CROSS JOIN schools
;

-- DLC "Снаряжение ведьмака" (dlc_wt): стартовое снаряжение школы
-- Кладём предметы в те же места и в том же формате, что и магазин: объект + {amount, sourceId}
-- (как в applyShopNode: { ...row, amount, sourceId }).
WITH
  wt AS (
    SELECT body AS expr
      FROM rules
     WHERE ru_id = ck_id('witcher_cc.rules.is_dlc_wt_enabled')
  )
INSERT INTO effects (scope, an_an_id, body)
-- Волк
SELECT 'character', 'wcc_witcher_school_o01',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.gear.weapons'),
      jsonb_build_object(
        'jsonlogic_expression',
        jsonb_build_object(
          'if',
          jsonb_build_array(
            wt.expr,
            jsonb_build_object(
              'concat_arrays',
              jsonb_build_array(
                jsonb_build_object('var', jsonb_build_array('characterRaw.gear.weapons', jsonb_build_array())),
                jsonb_build_array(
                  jsonb_build_object('w_id', 'W136', 'sourceId', 'weapons', 'amount', 1),
                  jsonb_build_object('w_id', 'W129', 'sourceId', 'weapons', 'amount', 1)
                )
              )
            ),
            jsonb_build_object('var', jsonb_build_array('characterRaw.gear.weapons', jsonb_build_array()))
          )
        )
      )
    )
  )
FROM wt
UNION ALL
SELECT 'character', 'wcc_witcher_school_o01',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.gear.armors'),
      jsonb_build_object(
        'jsonlogic_expression',
        jsonb_build_object(
          'if',
          jsonb_build_array(
            wt.expr,
            jsonb_build_object(
              'concat_arrays',
              jsonb_build_array(
                jsonb_build_object('var', jsonb_build_array('characterRaw.gear.armors', jsonb_build_array())),
                jsonb_build_array(
                  jsonb_build_object('a_id', 'A047', 'sourceId', 'armors', 'amount', 1)
                )
              )
            ),
            jsonb_build_object('var', jsonb_build_array('characterRaw.gear.armors', jsonb_build_array()))
          )
        )
      )
    )
  )
FROM wt

-- Грифон
UNION ALL
SELECT 'character', 'wcc_witcher_school_o02',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.gear.weapons'),
      jsonb_build_object(
        'jsonlogic_expression',
        jsonb_build_object(
          'if',
          jsonb_build_array(
            wt.expr,
            jsonb_build_object(
              'concat_arrays',
              jsonb_build_array(
                jsonb_build_object('var', jsonb_build_array('characterRaw.gear.weapons', jsonb_build_array())),
                jsonb_build_array(
                  jsonb_build_object('w_id', 'W137', 'sourceId', 'weapons', 'amount', 1),
                  jsonb_build_object('w_id', 'W130', 'sourceId', 'weapons', 'amount', 1),
                  jsonb_build_object('w_id', 'W004', 'sourceId', 'weapons', 'amount', 1)
                )
              )
            ),
            jsonb_build_object('var', jsonb_build_array('characterRaw.gear.weapons', jsonb_build_array()))
          )
        )
      )
    )
  )
FROM wt
UNION ALL
SELECT 'character', 'wcc_witcher_school_o02',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.gear.armors'),
      jsonb_build_object(
        'jsonlogic_expression',
        jsonb_build_object(
          'if',
          jsonb_build_array(
            wt.expr,
            jsonb_build_object(
              'concat_arrays',
              jsonb_build_array(
                jsonb_build_object('var', jsonb_build_array('characterRaw.gear.armors', jsonb_build_array())),
                jsonb_build_array(
                  jsonb_build_object('a_id', 'A048', 'sourceId', 'armors', 'amount', 1)
                )
              )
            ),
            jsonb_build_object('var', jsonb_build_array('characterRaw.gear.armors', jsonb_build_array()))
          )
        )
      )
    )
  )
FROM wt

-- Кот
UNION ALL
SELECT 'character', 'wcc_witcher_school_o03',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.gear.weapons'),
      jsonb_build_object(
        'jsonlogic_expression',
        jsonb_build_object(
          'if',
          jsonb_build_array(
            wt.expr,
            jsonb_build_object(
              'concat_arrays',
              jsonb_build_array(
                jsonb_build_object('var', jsonb_build_array('characterRaw.gear.weapons', jsonb_build_array())),
                jsonb_build_array(
                  jsonb_build_object('w_id', 'W139', 'sourceId', 'weapons', 'amount', 1),
                  jsonb_build_object('w_id', 'W132', 'sourceId', 'weapons', 'amount', 1),
                  jsonb_build_object('w_id', 'W006', 'sourceId', 'weapons', 'amount', 1)
                )
              )
            ),
            jsonb_build_object('var', jsonb_build_array('characterRaw.gear.weapons', jsonb_build_array()))
          )
        )
      )
    )
  )
FROM wt
UNION ALL
SELECT 'character', 'wcc_witcher_school_o03',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.gear.armors'),
      jsonb_build_object(
        'jsonlogic_expression',
        jsonb_build_object(
          'if',
          jsonb_build_array(
            wt.expr,
            jsonb_build_object(
              'concat_arrays',
              jsonb_build_array(
                jsonb_build_object('var', jsonb_build_array('characterRaw.gear.armors', jsonb_build_array())),
                jsonb_build_array(
                  jsonb_build_object('a_id', 'A045', 'sourceId', 'armors', 'amount', 1)
                )
              )
            ),
            jsonb_build_object('var', jsonb_build_array('characterRaw.gear.armors', jsonb_build_array()))
          )
        )
      )
    )
  )
FROM wt

-- Змея
UNION ALL
SELECT 'character', 'wcc_witcher_school_o04',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.gear.weapons'),
      jsonb_build_object(
        'jsonlogic_expression',
        jsonb_build_object(
          'if',
          jsonb_build_array(
            wt.expr,
            jsonb_build_object(
              'concat_arrays',
              jsonb_build_array(
                jsonb_build_object('var', jsonb_build_array('characterRaw.gear.weapons', jsonb_build_array())),
                jsonb_build_array(
                  jsonb_build_object('w_id', 'W138', 'sourceId', 'weapons', 'amount', 1),
                  jsonb_build_object('w_id', 'W131', 'sourceId', 'weapons', 'amount', 1),
                  jsonb_build_object('w_id', 'W081', 'sourceId', 'weapons', 'amount', 2)
                )
              )
            ),
            jsonb_build_object('var', jsonb_build_array('characterRaw.gear.weapons', jsonb_build_array()))
          )
        )
      )
    )
  )
FROM wt
UNION ALL
SELECT 'character', 'wcc_witcher_school_o04',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.gear.armors'),
      jsonb_build_object(
        'jsonlogic_expression',
        jsonb_build_object(
          'if',
          jsonb_build_array(
            wt.expr,
            jsonb_build_object(
              'concat_arrays',
              jsonb_build_array(
                jsonb_build_object('var', jsonb_build_array('characterRaw.gear.armors', jsonb_build_array())),
                jsonb_build_array(
                  jsonb_build_object('a_id', 'A044', 'sourceId', 'armors', 'amount', 1)
                )
              )
            ),
            jsonb_build_object('var', jsonb_build_array('characterRaw.gear.armors', jsonb_build_array()))
          )
        )
      )
    )
  )
FROM wt

-- Медведь
UNION ALL
SELECT 'character', 'wcc_witcher_school_o05',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.gear.weapons'),
      jsonb_build_object(
        'jsonlogic_expression',
        jsonb_build_object(
          'if',
          jsonb_build_array(
            wt.expr,
            jsonb_build_object(
              'concat_arrays',
              jsonb_build_array(
                jsonb_build_object('var', jsonb_build_array('characterRaw.gear.weapons', jsonb_build_array())),
                jsonb_build_array(
                  jsonb_build_object('w_id', 'W141', 'sourceId', 'weapons', 'amount', 1),
                  jsonb_build_object('w_id', 'W134', 'sourceId', 'weapons', 'amount', 1),
                  jsonb_build_object('w_id', 'W008', 'sourceId', 'weapons', 'amount', 1)
                )
              )
            ),
            jsonb_build_object('var', jsonb_build_array('characterRaw.gear.weapons', jsonb_build_array()))
          )
        )
      )
    )
  )
FROM wt
UNION ALL
SELECT 'character', 'wcc_witcher_school_o05',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.gear.armors'),
      jsonb_build_object(
        'jsonlogic_expression',
        jsonb_build_object(
          'if',
          jsonb_build_array(
            wt.expr,
            jsonb_build_object(
              'concat_arrays',
              jsonb_build_array(
                jsonb_build_object('var', jsonb_build_array('characterRaw.gear.armors', jsonb_build_array())),
                jsonb_build_array(
                  jsonb_build_object('a_id', 'A050', 'sourceId', 'armors', 'amount', 1)
                )
              )
            ),
            jsonb_build_object('var', jsonb_build_array('characterRaw.gear.armors', jsonb_build_array()))
          )
        )
      )
    )
  )
FROM wt

-- Мантикора
UNION ALL
SELECT 'character', 'wcc_witcher_school_o06',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.gear.weapons'),
      jsonb_build_object(
        'jsonlogic_expression',
        jsonb_build_object(
          'if',
          jsonb_build_array(
            wt.expr,
            jsonb_build_object(
              'concat_arrays',
              jsonb_build_array(
                jsonb_build_object('var', jsonb_build_array('characterRaw.gear.weapons', jsonb_build_array())),
                jsonb_build_array(
                  jsonb_build_object('w_id', 'W140', 'sourceId', 'weapons', 'amount', 1),
                  jsonb_build_object('w_id', 'W133', 'sourceId', 'weapons', 'amount', 1)
                )
              )
            ),
            jsonb_build_object('var', jsonb_build_array('characterRaw.gear.weapons', jsonb_build_array()))
          )
        )
      )
    )
  )
FROM wt
UNION ALL
SELECT 'character', 'wcc_witcher_school_o06',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.gear.armors'),
      jsonb_build_object(
        'jsonlogic_expression',
        jsonb_build_object(
          'if',
          jsonb_build_array(
            wt.expr,
            jsonb_build_object(
              'concat_arrays',
              jsonb_build_array(
                jsonb_build_object('var', jsonb_build_array('characterRaw.gear.armors', jsonb_build_array())),
                jsonb_build_array(
                  jsonb_build_object('a_id', 'A059', 'sourceId', 'armors', 'amount', 1),
                  jsonb_build_object('a_id', 'A049', 'sourceId', 'armors', 'amount', 1)
                )
              )
            ),
            jsonb_build_object('var', jsonb_build_array('characterRaw.gear.armors', jsonb_build_array()))
          )
        )
      )
    )
  )
FROM wt

-- Улитка
UNION ALL
SELECT 'character', 'wcc_witcher_school_o07',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.gear.weapons'),
      jsonb_build_object(
        'jsonlogic_expression',
        jsonb_build_object(
          'if',
          jsonb_build_array(
            wt.expr,
            jsonb_build_object(
              'concat_arrays',
              jsonb_build_array(
                jsonb_build_object('var', jsonb_build_array('characterRaw.gear.weapons', jsonb_build_array())),
                jsonb_build_array(
                  jsonb_build_object('w_id', 'W169', 'sourceId', 'weapons', 'amount', 1),
                  jsonb_build_object('w_id', 'W170', 'sourceId', 'weapons', 'amount', 1)
                )
              )
            ),
            jsonb_build_object('var', jsonb_build_array('characterRaw.gear.weapons', jsonb_build_array()))
          )
        )
      )
    )
  )
FROM wt
UNION ALL
SELECT 'character', 'wcc_witcher_school_o07',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.gear.armors'),
      jsonb_build_object(
        'jsonlogic_expression',
        jsonb_build_object(
          'if',
          jsonb_build_array(
            wt.expr,
            jsonb_build_object(
              'concat_arrays',
              jsonb_build_array(
                jsonb_build_object('var', jsonb_build_array('characterRaw.gear.armors', jsonb_build_array())),
                jsonb_build_array(
                  jsonb_build_object('a_id', 'A064', 'sourceId', 'armors', 'amount', 1)
                )
              )
            ),
            jsonb_build_object('var', jsonb_build_array('characterRaw.gear.armors', jsonb_build_array()))
          )
        )
      )
    )
  )
FROM wt
;


-- Переход в ноду выбора школы ведьмака (только для расы "Ведьмак")
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_race', 'wcc_witcher_school', 'wcc_race_witcher', 1;























