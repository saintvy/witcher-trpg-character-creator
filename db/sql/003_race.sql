\echo '003_race.sql'
-- Узел: Выбор расы

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_race' AS qu_id
                , 'questions' AS entity
                , 'single'::question_type AS qtype)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| v.entity_field) AS id
           , meta.entity, v.entity_field, v.lang, v.text
        FROM (VALUES
                ('ru', 'Надо выбрать расу в этой истории', 'body'),
                ('en', 'You should choose a race for your character', 'body')
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
           'path', jsonb_build_array(
             ck_id('witcher_cc.hierarchy.identity')::text,
             ck_id('witcher_cc.hierarchy.race')::text
           )
         )
     FROM meta;

-- Связи
-- Нода расы должна идти после выбора DLC
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_dlcs', 'wcc_race';

-- Опции: Выбор расы
-- Опция - человек
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_race' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, ins_label AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(1, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
           , meta.entity, meta.entity_field, v.lang, v.text
        FROM (VALUES
                ('ru',
'<h1>Люди</h1>
<i>Ох, будь я покозлистее, то всю желчь излил бы тебе о том, как людишки насолили моему народу и остальным Старшим Народам. '
  || 'Но я не такой. С людьми я служил бок о бок на войне с Нильфгаардом; в той же темерской армии большинство — люди. Не все '
  || 'они говнюки — бывают и хорошие. По характеру люди-то разные. Обычно они весьма стойкие ребята. Разве что частенько '
  || 'начинают то за «правое дело» воевать, то тыкать пальцами и бояться. Сейчас люди на Континенте — преобладающий вид, и они '
  || 'об этом прекрасно знают... чёрт, даже не надо стараться, чтобы о них гадости говорить. Люди почти уничтожили Старшие '
  || 'Народы, выkosили врагов, оставили в живых всего пару сотен боболаков, построили свои города на руинах Старших Народов и '
  || 'каждый день кого-то из Старших убивают. Но нет, они не все говнюки. Да, большинство магов — люди, и именно они погрузили '
  || 'мир в хаос, но они также сделали мир лучше с помощью науки и магии. Люди умные и, на самом деле, верные — если ты с '
  || 'человеком дружен, он тебя в беде не бросит.
<b>-Родольф Казмер</b></i>
<h2>Черты</h2>
<h3>🟡 Доверие</h3>
В мире, где нелюдям не доверяют, людям довериться куда проще. У людей есть врождённый бонус +1 к проверкам Харизмы'
  || ', Соблазнения и Убеждения против других людей.
<h3>🟡 Изобретательность</h3>
Люди умны и зачастую находят великолепные решения сложных проблем. Люди получают врождённый бонус +1 к Дедукции.
<h3>🟡 Упрямство</h3>
Одно из величайших преимуществ человеческой расы — нежелание отступать даже в опасной ситуации. Они могут собраться '
  || 'с духом и перебросить неудачный результат проверки Сопротивления убеждению или Храбрости, но не более 3 раз за '
  || 'игровую партию. В таком случае из двух результатов выбирают наивысший, но если результат всё равно провальный, то '
  || 'вновь использовать Упрямство нельзя.'),
                ('en',
'<h1>Humans</h1>
<i>If I were a worse person I''d vent my spleen and tell ya all the terrible things humans have done to my people and the other '
  || 'elder races. But I''m better than that. Worked with a lot of humans during the Northern Wars. Hell, most of the Temerian '
  || 'army''s humans. Humans can be fine folks. They''re varied in nature and usually a pretty resilient race. They tend to get '
  || 'swept up in causes and fears pretty easily, though. They''re the dominant species on the Continent right now and they know '
  || 'it. Heh. It''s easy to speak ill of ''em. They just about destroyed the elder races, wiped out the vran, killed all but a '
  || 'few hundred of the werebubbs, built their cities on top of elderfolk cities, and depending on where you are they''re '
  || 'still killing elderfolk by the score every day. But they''re not all bad. Heh, most mages are human and they may '
  || 'destabilize countries and plunge the world into chaos, but they''ve also made the world better with magic and science. '
  || 'Human are a clever bunch, and in a pinch, a human you know well will probably have your back.
<b>–Rodolf Kazmer</b></i>
<h2>Perks</h2>
<h3>🟡 Trustworthy</h3>
In a world where non-humans can''t be trusted, humans look more trustworthy. Humans have an inherent +1 to their Charisma, '
  || 'Seduction, and Persuasion checks against other humans.
<h3>🟡 Ingenuity</h3>
Humans are clever and often have brilliant solutions to difficult problems. Humans gain an inherent +1 to Deduction.
<h3>🟡 Blindly Stubborn</h3>
Part of the human race''s greatest strength is its willingness to charge forward endlessly, even into truly life-threatening '
  || 'situations. A human can summon up their courage and reroll a failed Resist Coercion or Courage roll 3 times per game '
  || 'session. They take the higher of the two rolls, but if they still fail they cannot re-use the ability to roll again.')) AS v(lang, text)
        CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
  SELECT 'wcc_race_human'
       , meta.su_su_id
       , meta.qu_id
       , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(1, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label
       , 1 AS sort_order
       , '{}'::jsonb AS metadata
    FROM meta;

-- Эффекты расы человек
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_race' AS qu_id
                , 'character' AS entity)
, ins_r_human AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'human' ||'.'|| meta.entity ||'.'|| 'race') AS id
         , meta.entity, 'race', v.lang, v.text
      FROM (VALUES
        ('ru', 'Человек'),
        ('en', 'Human')
      ) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_r_human_f1 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'human' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '1') AS id
         , meta.entity, 'perks', v.lang, v.text
      FROM (VALUES
        ('ru', '<b>Доверие</b>: +1 к проверкам Харизмы, Соблазнения и Убеждения против людей'),
        ('en', '<b>Trust</b>: +1 to Charisma, Persuasion, and Seduction checks against humans')
      ) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_r_human_f2 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'human' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '2') AS id
         , meta.entity, 'perks', v.lang, v.text
      FROM (VALUES
        ('ru', '<b>Изобретательность</b>: Врождённый бонус [+1 к Дедукции]'),
        ('en', '<b>Ingenuity</b>: [+1 to Deduction]')
      ) AS v(lang, text)
      CROSS JOIN meta
  )
, ins_r_human_f3 AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'human' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '3') AS id
         , meta.entity, 'perks', v.lang, v.text
      FROM (VALUES
        ('ru', '<b>Упрямство</b>: 3 проверки с преимуществом для Сопротивления убеждению или Храбрости за сессию'),
        ('en', '<b>Stubbornness</b>: 3 checks with advantage on Resist Coercion or Courage per session')
      ) AS v(lang, text)
      CROSS JOIN meta
  )
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_race_human' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.race'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'human' ||'.'|| meta.entity ||'.'|| 'race')::text)
    )
  ) AS body
FROM meta UNION ALL
SELECT
  'character' AS scope,
  'wcc_race_human' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.logicFields.race'),
      'Human'
    )
  ) AS body UNION ALL
SELECT
  'character',
  'wcc_race_human',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'human' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '1')::text)
    )
  )
FROM meta UNION ALL
SELECT
  'character',
  'wcc_race_human',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'human' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '2')::text)
    )
  )
FROM meta UNION ALL
SELECT
  'character',
  'wcc_race_human',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'human' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '3')::text)
    )
  )
FROM meta UNION ALL
-- Эффекты черт расы: Человек - Изобретательность (+1 к Дедукции)
SELECT 'character', 'wcc_race_human',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.deduction.race_bonus'),
      1
    )
  );

-- Опция - краснолюд
-- Опция ответа: Краснолюды / Dwarves
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_race' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, ins_label AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(2, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
         , meta.entity, meta.entity_field, v.lang, v.text
      FROM (VALUES
        ('ru',
'<h1>Краснолюды</h1>
<i>Друже, вот что я тебе скажу: реки высохнут, горы рассыплются, а краснолюды никуда не денутся. Может, мы и низенькие в '
  || 'сравнении с эльфами и людьми, да только в силе и закалке им с нами не тягаться. Мы — само воплощение стойкости! '
  || 'Краснолюды уже не первый век существуют в этом мире. Жили себе спокойно в горах, ковали. Мы народ достаточно дружелюбный, '
  || 'если познакомиться с нами поближе. Да и уживаемся спокойно со всеми… если нас не бесить, конечно. Человечки нас не '
  || 'особо любят, но мы им нужны — кто же сталь им ковать будем и торговать? К тому же, в отличие от сраных эльфов, мы '
  || 'не держим на людей зла. Нас не трогают — и мы их не трогаем в ответ. Порой даже кружечку-другую готовы разделить '
  || 'вместе с человеком. Жаль, конечно, что вся эта безумная расистская дрянь по Северу расползлась. Теперь и на краснолюдов '
  || 'травлю открыли. Повезло ещё, что люди наших девок нормально от мужиков отличить не могут, а то бы всех уже увели! '
  || 'Ведь нету бабы краше краснолудки. Правильно говорят: чем пышнее борода, тем приятнее… ну, ты понимаешь.
<b>-Родольф Казмер</b></i>
<h2>Черты</h2>
<h3>🟡 Закалённый</h3>
У краснолюдов весьма крепкая кожа, имеющая врождённую прочность 2. Эта величина прибавляется к прочности любой брони и не '
  || 'может быть понижена разрушающим уроном.
<h3>🟡 Силач</h3>
Благодаря невысокому росту и склонности к тяжёлой работе, требующей физических усилий, краснолюды получают +1 к Силе '
  || '(Навыку «Сила») и повышают своё значение Переносимого веса на 25.
<h3>🟡 Намётанный глаз</h3>
Краснолюды — прекрасные оценщики, обладающие вниманием к деталям; обмануть их трудно. Краснолюды получают врождённый '
  || 'бонус +1 к Торговле.'),
        ('en',
'<h1>Dwarves</h1>
<i>Heh. My friend, rivers dry up, mountains crumble, but dwarves are a constant. We may be short compared to the elves and '
  || 'the humans but we''re sturdier than they''ll ever be—the definition of barrel-chested! We dwarves have been around '
  || 'for ages, livin'' in the mountains and plyin'' our trade: forg in''. We''re friendly enough when ya get to know us '
  || 'and easy to get along with as long as ya don''t piss in our faces. The humans may not love us dwarves, but they need '
  || 'us for our skill and our steel. ''Sides, unlike the damn elves we don''t hold an in-born grudge against the humans. '
  || 'We keep to our business and them to theirs. Share a drink here and there. Heh, sadly, madness is spreadin'' quick '
  || 'through the North and dwarves are targets now more than ever. Lucky the humans have a hard time pickin'' out our women! '
  || 'Never find a prettier lass than a dwarven girl. They say the fuller the beard, the fuller the...well. Ya get my point.
<b>-Rodolf Kazmer</b></i>
<h2>Perks</h2>
<h3>🟡 Tough</h3>
Spending much of their time in the mountains and mines, dwarves have naturally tough skin. A dwarf''s skin has a natural '
  || 'Stopping Power of 2. This SP is applied on top of any armor the dwarf is already wearing and cannot be lowered via '
  || 'weapon attacks or ablation damage.
<h3>🟡 Strong</h3>
Due to their compact frame and propensity for tough, physically demanding professions, dwarves gain a +1 to their Physique '
  || 'skill and raise their Encumbrance by 25.
<h3>🟡 Crafter''s Eye</h3>
With their eye for fine detail and appraisal it is hard to bluff a dwarf. Dwarves have an inherent +1 to their Business skill.')
      ) AS v(lang, text)
      CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
SELECT 'wcc_race_dwarf'
     , meta.su_su_id
     , meta.qu_id
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(2, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label
     , 2 AS sort_order
     , '{}'::jsonb AS metadata
  FROM meta;

-- Эффекты выбора расы: Краснолюд
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_race' AS qu_id
                , 'character' AS entity)
, ins_r_dwarf AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'dwarf' ||'.'|| meta.entity ||'.'|| 'race') AS id
       , meta.entity, 'race', v.lang, v.text
    FROM (VALUES
      ('ru', 'Краснолюд'),
      ('en', 'Dwarf')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_dwarf_f1 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'dwarf' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '1') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Закалённый</b>: врождённая Прочность 2; суммируется с бронёй и не снижается разрушающим уроном'),
      ('en', '<b>Tough</b>: natural SP 2; stacks with worn armor; not lowered by ablation damage')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_dwarf_f2 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'dwarf' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '2') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Силач</b>: [+1 к Силе] и [+25 к Переносимому весу]'),
      ('en', '<b>Strong</b>: [+1 Physique] and [+25 Encumbrance]')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_dwarf_f3 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'dwarf' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '3') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Намётанный глаз</b>: [+1 к Торговле]'),
      ('en', '<b>Crafter''s Eye</b>: [+1 to Business]')
    ) AS v(lang, text)
    CROSS JOIN meta
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_race_dwarf',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.race'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'dwarf' ||'.'|| meta.entity ||'.'|| 'race')::text)
    )
  )
FROM meta UNION ALL
SELECT
  'character' AS scope,
  'wcc_race_dwarf' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.logicFields.race'),
      'Dwarf'
    )
  ) AS body
UNION ALL
SELECT
  'character',
  'wcc_race_dwarf',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'dwarf' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '1')::text)
    )
  )
FROM meta
UNION ALL
SELECT
  'character',
  'wcc_race_dwarf',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'dwarf' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '2')::text)
    )
  )
FROM meta
UNION ALL
SELECT
  'character',
  'wcc_race_dwarf',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'dwarf' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '3')::text)
    )
  )
FROM meta UNION ALL
-- Эффекты черт расы: Краснолюд - Силач (+1 к Силе)
SELECT 'character', 'wcc_race_dwarf',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.physique.race_bonus'),
      1
    )
  )
UNION ALL
-- Эффекты черт расы: Краснолюд - Силач (+25 к Переносимому весу)
SELECT 'character', 'wcc_race_dwarf',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.statistics.calculated.ENC.race_bonus'),
      25
    )
  )
UNION ALL
-- Эффекты черт расы: Краснолюд - Намётанный глаз (+1 к Торговле)
SELECT 'character', 'wcc_race_dwarf',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.business.race_bonus'),
      1
    )
  );

-- Опция ответа: Эльфы (Aen Seidhe) / Elves (The Aen Seidhe)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_race' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, ins_label AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(3, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
         , meta.entity, meta.entity_field, v.lang, v.text
      FROM (VALUES
        ('ru',
'<h1>Эльфы (Aen Seidhe)</h1>
<i>История эльфов (точнее Aen Seidhe, поскольку наши эльфы далеко не единственные) весьма грустная. Они прибыли сюда неизвестно '
  || 'откуда на огромных белых кораблях. Случилось это незадолго до появления людей. Я бы не назвал эльфов добряками, но с '
  || 'остальными они как-то уживались. От людей они не сильно отличаются: высокие, худые, любят на другиe народы свысока '
  || 'смотреть. Разве что уши острые, жизнь вечная, да, считай, полное единение с природой — эльфы много поколений только и '
  || 'делали, что занимались собирательством и строили дворцы. У них за время поедания ягод да кореньев и клыков-то не осталось. '
  || 'Правда, всё равно не советую их из себя выводить — на поле боя эльфы могут устроить вам ещё ад. Броню они толком не носят, '
  || 'но заприметить эльфа в лесу так же тяжело, как зимой лягушку найти. А уж искуснее лучника, чем эльф, днём с огнём не сыщешь.
<b>Родольф Казмер</b></i>
<h2>Черты</h2>
<h3>🟡 Чувство прекрасного</h3>
У эльфов есть врождённая творческая жилка и развитое чувство прекрасного. Эльфы получают врождённый бонус +1 к Искусству.
<h3>🟡 Стрелок</h3>
Благодаря давним традициям и постоянным тренировкам эльфы — одни из лучших лучников в мире. Эльфы получают врождённый бонус +2 '
  || 'к Стрельбе из лука и способны взводить и натягивать лук, не тратя на это действие.
<h3>🟡 Единение с природой</h3>
Эльфы тесно связаны с природой. Они не тревожат животных — любой зверь, встреченный эльфом, будет относиться к нему дружелюбно '
  || 'и не нападёт без провокации. Эльфы также автоматически находят любые обычные и повсеместные растительные субстанции, если '
  || 'искомое растение естественно обитает на данной территории.'),
        ('en',
'<h1>Elves (The Aen Seidhe)</h1>
<i>Elves, or the Aen Seidhe, since ours aren''t the only elves out there, are a sad tale indeed. Heh. They came to the world '
  || 'not long before humans, in great white ships from somewhere. Wouldn''t call ''em the kindest of the races but they get '
  || 'along well enough with the rest of us. They''re not too unlike humans: tall, thin, prone to lookin'' down on others. '
  || 'Only difference is their pointed ears, their seemingly eternal lives, and their bond with the land. Heh, the elves are '
  || 'at one with nature or somethin''. Lived off the land for generations, foragin'' for food and buildin'' great palaces. '
  || 'Don''t even have sharp teeth after all those years of eatin'' berries and plants. Don''t get ''em cross though; an elf''s '
  || 'hell on the battlefield too. They may not wear much armor but they''re hard as frogs in winter to find in the wilderness, '
  || 'and probably the best archers you''ll ever see.
<b>Rodolf Kazmer</b></i>
<h2>Perks</h2>
<h3>🟡 Artistic</h3>
Elves have a natural eye for beauty and a talent for artistic endeavours. Elves gain an inherent +1 to their Fine Arts skill.
<h3>🟡 Marksman</h3>
Years of tradition and practice make elves some of the best archers in the world. Elves gain an inherent +2 to their Archery '
  || 'skill and can draw and string a bow without taking an action.
<h3>🟡 Natural Attunement</h3>
Elves have a deep magical bond with nature itself. Elves do not disturb animals, meaning any beast they encounter is considered '
  || 'friendly and will not attack unless provoked. Elves also automatically find any plant substance rated as commonly '
  || 'available (or lower) that they are seeking, as long as the substance would occur naturally in the surrounding terrain.')
      ) AS v(lang, text)
      CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
SELECT 'wcc_race_elf'
     , meta.su_su_id
     , meta.qu_id
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(3, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label
     , 3 AS sort_order
     , '{}'::jsonb AS metadata
  FROM meta;

-- Эффекты выбора расы: Эльф
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_race' AS qu_id
                , 'character' AS entity)
, ins_r_elf AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elf' ||'.'|| meta.entity ||'.'|| 'race') AS id
       , meta.entity, 'race', v.lang, v.text
    FROM (VALUES
      ('ru', 'Эльф'),
      ('en', 'Elf')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_elf_f1 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elf' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '1') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Чувство прекрасного</b>: [+1 к Искусству]'),
      ('en', '<b>Artistic</b>: [+1 to Fine Arts]')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_elf_f2 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elf' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '2') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Стрелок</b>: [+2 к Стрельбе из лука]; выхватывает и натягивает лук без траты действия'),
      ('en', '<b>Marksman</b>: [+2 to Archery]; can draw & string a bow without taking an action')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_elf_f3 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elf' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '3') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Единение с природой</b>: звери относятся дружелюбно и не атакуют без провокации; автоматически находит '
  || 'обычные/повсеместные растительные субстанции, если они естественны для местности'),
      ('en', '<b>Natural Attunement</b>: beasts are friendly and won''t attack unless provoked; automatically finds '
  || 'commonly-available plant substances occurring naturally in the area')
    ) AS v(lang, text)
    CROSS JOIN meta
)
INSERT INTO effects (scope, an_an_id, body)
-- race text
SELECT
  'character',
  'wcc_race_elf',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.race'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elf' ||'.'|| meta.entity ||'.'|| 'race')::text)
    )
  )
FROM meta UNION ALL
SELECT
  'character' AS scope,
  'wcc_race_elf' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.logicFields.race'),
      'Elf'
    )
  ) AS body
UNION ALL
-- perks: Artistic / Marksman / Natural Attunement
SELECT
  'character',
  'wcc_race_elf',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elf' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '1')::text)
    )
  )
FROM meta
UNION ALL
SELECT
  'character',
  'wcc_race_elf',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elf' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '2')::text)
    )
  )
FROM meta
UNION ALL
SELECT
  'character',
  'wcc_race_elf',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'elf' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '3')::text)
    )
  )
FROM meta UNION ALL
-- Эффекты черт расы: Эльф - Чувство прекрасного (+1 к Искусству)
SELECT 'character', 'wcc_race_elf',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.fine_arts.race_bonus'),
      1
    )
  )
UNION ALL
-- Эффекты черт расы: Эльф - Стрелок (+2 к Стрельбе из лука)
SELECT 'character', 'wcc_race_elf',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.archery.race_bonus'),
      2
    )
  );

-- Опция ответа: Ведьмаки / Witchers
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_race' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, ins_label AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(4, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
         , meta.entity, meta.entity_field, v.lang, v.text
      FROM (VALUES
        ('ru',
'<h1>Ведьмаки</h1>
<i>Ведьмаки — тема деликатная с тех самых пор, как их создали много веков тому назад. Но, знаешь, даже когда они были '
  || 'нарасхват, их не особо-то любили. Ведьмаков выращивали из людских детей в ведьмачьих школах. Там дети проходили '
  || 'лютую подготовку, после которой становились живым оружием. Быстрые до одури, они могут сражаться вслепую и обучены '
  || 'охотиться почти на всех тварей, какие только можно встретить. Через пару лет тренировок их подвергают мутациям — '
  || 'известней всего Испытание травами. Ведьмак, с которым я странствовал, говорил, что переживает эту дрянь только один '
  || 'ребёнок из четырёх.</i>
<i>Те, кто выжил, меняются. Глаза у них становятся кошачьими, а эмоции почти отмирают. Вроде потом частично возвращаются — '
  || 'мой спутник по дороге и шутки отпускал. Но с той поры ведьмаки — убийцы, перерождённые для одной цели: убивать чудовищ. '
  || 'Увидишь ведьмака в деле — поймёшь, что все страдания были не зря. Одна беда: они мутанты, а людей мутанты пугают и злят. '
  || 'С адаптацией у ведьмаков туго, и большинство считает их хладнокровными бездушными выродками, что сперва обворуют тебя и '
  || 'твоих, а потом всадят меч в брюхо.</i>
<b>Родольф Казмер</b>
<h2>Черты</h2>
<h3>🟡 Обострённые чувства</h3>
Благодаря обострённым чувствам ведьмаки не получают штрафов при слабом свете и получают +1 к Вниманию, а также возможность '
  || 'выслеживания по запаху.
<h3>🟡 Стойкость мутанта</h3>
После всех мутаций ведьмаки невосприимчивы к болезням и способны использовать мутагены.
<h3>🟡 Притупление эмоций</h3>
Из-за пережитых страданий и мутаций эмоции у ведьмаков притупляются. Ведьмакам не нужно совершать проверки Храбрости против '
  || 'Запугивания; при этом они получают штраф −4 к Эмпатии, но значение Эмпатии не может быть ниже 1.
<h3>🟡 Молниеносная реакция</h3>
Благодаря интенсивным тренировкам и мутациям ведьмаки быстрее и проворнее людей. Они получают постоянный бонус +1 к Реакции '
  || 'и Ловкости, позволяющий превышать 10.</i>'),
        ('en',
'<h1>Witchers</h1>
<i>Witchers have been a touchy issue since they were made centuries ago. Even when they were sought after, nobody really '
  || 'liked ''em. They''re raised from human children in the Witcher Schools and put through gruelin'' trainin'' that '
  || 'turns ''em into livin'' weapons. Fast as hell, trained to fight blind and hunt just about any monster you''re likely '
  || 'to meet. After a few years they go through mutations — the Trial of the Grasses. The witcher I traveled with said '
  || 'only one in four kids survives.</i>
<i>The ones that survive are changed. Bright cat''s eyes and just about no feelin'' left, though it evens out some with '
  || 'time — the witcher I traveled with even cracked a few jokes on the road. From that point on they''re killers, reborn '
  || 'for one purpose: killin'' monsters. See a witcher in action and you''ll know the payoff of all that hardship. Problem '
  || 'is they''re mutants, and people hate mutants. Most folk think they''re cold, heartless murderers who''ll steal your '
  || 'gold and then put a sword in your gut.</i>
<b>Rodolf Kazmer</b>
<h2>Perks</h2>
<h3>🟡 Enhanced Senses</h3>
Due to their heightened senses, witchers take no penalties in dim light and gain an inherent +1 to Awareness, as well as the '
  || 'ability to track by scent alone.
<h3>🟡 Resilient Mutation</h3>
After all required mutations, witchers are immune to diseases and are able to use mutagens.
<h3>🟡 Dulled Emotions</h3>
Thanks to trauma and mutation, a witcher''s emotions are dulled. Witchers do not have to make courage checks against '
  || 'Intimidation, but they have a −4 to their Empathy; this cannot bring Empathy below 1.
<h3>🟡 Lightning Reflexes</h3>
After intensive training and mutation, witchers are faster and more agile than humans. They gain a permanent +1 to both '
  || 'Reflex and Dexterity that can raise these stats above 10.')
      ) AS v(lang, text)
      CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
SELECT 'wcc_race_witcher'
     , meta.su_su_id
     , meta.qu_id
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(4, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label
     , 4 AS sort_order
     , '{}'::jsonb AS metadata
  FROM meta;

-- Эффекты выбора расы: Ведьмак
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_race' AS qu_id
                , 'character' AS entity)
, ins_r_witcher AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'witcher' ||'.'|| meta.entity ||'.'|| 'race') AS id
       , meta.entity, 'race', v.lang, v.text
    FROM (VALUES
      ('ru', 'Ведьмак'),
      ('en', 'Witcher')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_witcher_f1 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'witcher' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '1') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Обострённые чувства</b>: нет штрафов за тусклый свет; [+1 к Вниманию]; выслеживание по запаху'),
      ('en', '<b>Enhanced Senses</b>: no penalties in dim light; [+1 Awareness]; can track by scent')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_witcher_f2 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'witcher' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '2') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Стойкость мутанта</b>: иммунитет к болезням; может использовать мутагены'),
      ('en', '<b>Resilient Mutation</b>: immune to diseases; can use mutagens')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_witcher_f3 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'witcher' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '3') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Притупление эмоций</b>: не делает проверки Храбрости против Запугивания; [−4 к Эмпатии] (не ниже 1)'),
      ('en', '<b>Dulled Emotions</b>: no Courage checks vs Intimidation; [−4 Empathy] (cannot go below 1)')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_witcher_f4 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'witcher' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '4') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Молниеносная реакция</b>: [+1 к Реакции и Ловкости]; может превышать 10'),
      ('en', '<b>Lightning Reflexes</b>: [+1 to Reflex and Dexterity]; may exceed 10')
    ) AS v(lang, text)
    CROSS JOIN meta
)
INSERT INTO effects (scope, an_an_id, body)
-- race text
SELECT
  'character',
  'wcc_race_witcher',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.race'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'witcher' ||'.'|| meta.entity ||'.'|| 'race')::text)
    )
  )
FROM meta UNION ALL
SELECT
  'character' AS scope,
  'wcc_race_witcher' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.logicFields.race'),
      'Witcher'
    )
  ) AS body
UNION ALL
-- perks (4 шт.)
SELECT 'character','wcc_race_witcher',
       jsonb_build_object('add', jsonb_build_array(
         jsonb_build_object('var','characterRaw.perks'),
         jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'witcher' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '1')::text)
       ))
FROM meta
UNION ALL
SELECT 'character','wcc_race_witcher',
       jsonb_build_object('add', jsonb_build_array(
         jsonb_build_object('var','characterRaw.perks'),
         jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'witcher' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '2')::text)
       ))
FROM meta
UNION ALL
SELECT 'character','wcc_race_witcher',
       jsonb_build_object('add', jsonb_build_array(
         jsonb_build_object('var','characterRaw.perks'),
         jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'witcher' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '3')::text)
       ))
FROM meta
UNION ALL
SELECT 'character','wcc_race_witcher',
       jsonb_build_object('add', jsonb_build_array(
         jsonb_build_object('var','characterRaw.perks'),
         jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'witcher' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '4')::text)
       ))
FROM meta UNION ALL
-- Эффекты черт расы: Ведьмак - Обострённые чувства (+1 к Вниманию)
SELECT 'character', 'wcc_race_witcher',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.awareness.race_bonus'),
      1
    )
  )
UNION ALL
-- Эффекты черт расы: Ведьмак - Притупление эмоций (-4 к Эмпатии, max = 6)
SELECT 'character', 'wcc_race_witcher',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.statistics.EMP.race_bonus'),
      -4
    )
  )
UNION ALL
-- Эффекты черт расы: Ведьмак - Молниеносная реакция (+1 к Реакции)
SELECT 'character', 'wcc_race_witcher',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.statistics.REF.race_bonus'),
      1
    )
  )
UNION ALL
-- Эффекты черт расы: Ведьмак - Молниеносная реакция (+1 к Ловкости)
SELECT 'character', 'wcc_race_witcher',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.statistics.DEX.race_bonus'),
      1
    )
  );

-- i18n записи для названий территорий (для social_status)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_race' AS qu_id
                , 'character' AS entity)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'territory' ||'.'|| v.territory_key) AS id
       , meta.entity, 'social_status_group', v.lang, v.text
    FROM (VALUES
      ('north', 'ru', 'Север'),
      ('north', 'en', 'The North'),
      ('nilfgaard', 'ru', 'Нильфгаард'),
      ('nilfgaard', 'en', 'Nilfgaard'),
      ('skellige', 'ru', 'Скеллиге'),
      ('skellige', 'en', 'Skellige'),
      ('dol_blathanna', 'ru', 'Доль Блатанна'),
      ('dol_blathanna', 'en', 'Dol Blathanna'),
      ('mahakam', 'ru', 'Махакам'),
      ('mahakam', 'en', 'Mahakam')
    ) AS v(territory_key, lang, text)
    CROSS JOIN meta;

-- Эффекты social_status для расы: Человек
-- Север: Люди=3, Эльфы=1, Краснолюды=2, Ведьмаки=1+true
-- Нильфгаард: все=3, Ведьмаки=1+true
-- Скеллиге: все=3, Ведьмаки=2+false
-- Доль Блатанна: Люди=1, остальные=3, Ведьмаки=2+false
-- Махакам: Люди=2, остальные=3, Ведьмаки=2+false
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_race_human',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.social_status'),
      jsonb_build_object(
        'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_race.territory.north')::text),
        'group_status', 3,
        'group_is_feared', false
      )
    )
  )
UNION ALL
SELECT 'character', 'wcc_race_human',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.social_status'),
      jsonb_build_object(
        'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_race.territory.nilfgaard')::text),
        'group_status', 3,
        'group_is_feared', false
      )
    )
  )
UNION ALL
SELECT 'character', 'wcc_race_human',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.social_status'),
      jsonb_build_object(
        'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_race.territory.skellige')::text),
        'group_status', 3,
        'group_is_feared', false
      )
    )
  )
UNION ALL
SELECT 'character', 'wcc_race_human',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.social_status'),
      jsonb_build_object(
        'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_race.territory.dol_blathanna')::text),
        'group_status', 1,
        'group_is_feared', false
      )
    )
  )
UNION ALL
SELECT 'character', 'wcc_race_human',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.social_status'),
      jsonb_build_object(
        'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_race.territory.mahakam')::text),
        'group_status', 2,
        'group_is_feared', false
      )
    )
  );

-- Эффекты social_status для расы: Краснолюд
-- Север: Люди=3, Эльфы=1, Краснолюды=2, Ведьмаки=1+true
-- Нильфгаард: все=3, Ведьмаки=1+true
-- Скеллиге: все=3, Ведьмаки=2+false
-- Доль Блатанна: Люди=1, остальные=3, Ведьмаки=2+false
-- Махакам: Люди=2, остальные=3, Ведьмаки=2+false
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_race_dwarf',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.social_status'),
      jsonb_build_object(
        'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_race.territory.north')::text),
        'group_status', 2,
        'group_is_feared', false
      )
    )
  )
UNION ALL
SELECT 'character', 'wcc_race_dwarf',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.social_status'),
      jsonb_build_object(
        'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_race.territory.nilfgaard')::text),
        'group_status', 3,
        'group_is_feared', false
      )
    )
  )
UNION ALL
SELECT 'character', 'wcc_race_dwarf',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.social_status'),
      jsonb_build_object(
        'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_race.territory.skellige')::text),
        'group_status', 3,
        'group_is_feared', false
      )
    )
  )
UNION ALL
SELECT 'character', 'wcc_race_dwarf',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.social_status'),
      jsonb_build_object(
        'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_race.territory.dol_blathanna')::text),
        'group_status', 3,
        'group_is_feared', false
      )
    )
  )
UNION ALL
SELECT 'character', 'wcc_race_dwarf',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.social_status'),
      jsonb_build_object(
        'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_race.territory.mahakam')::text),
        'group_status', 3,
        'group_is_feared', false
      )
    )
  );

-- Эффекты social_status для расы: Эльф
-- Север: Люди=3, Эльфы=1, Краснолюды=2, Ведьмаки=1+true
-- Нильфгаард: все=3, Ведьмаки=1+true
-- Скеллиге: все=3, Ведьмаки=2+false
-- Доль Блатанна: Люди=1, остальные=3, Ведьмаки=2+false
-- Махакам: Люди=2, остальные=3, Ведьмаки=2+false
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_race_elf',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.social_status'),
      jsonb_build_object(
        'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_race.territory.north')::text),
        'group_status', 1,
        'group_is_feared', false
      )
    )
  )
UNION ALL
SELECT 'character', 'wcc_race_elf',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.social_status'),
      jsonb_build_object(
        'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_race.territory.nilfgaard')::text),
        'group_status', 3,
        'group_is_feared', false
      )
    )
  )
UNION ALL
SELECT 'character', 'wcc_race_elf',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.social_status'),
      jsonb_build_object(
        'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_race.territory.skellige')::text),
        'group_status', 3,
        'group_is_feared', false
      )
    )
  )
UNION ALL
SELECT 'character', 'wcc_race_elf',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.social_status'),
      jsonb_build_object(
        'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_race.territory.dol_blathanna')::text),
        'group_status', 3,
        'group_is_feared', false
      )
    )
  )
UNION ALL
SELECT 'character', 'wcc_race_elf',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.social_status'),
      jsonb_build_object(
        'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_race.territory.mahakam')::text),
        'group_status', 3,
        'group_is_feared', false
      )
    )
  );

-- Эффекты social_status для расы: Ведьмак
-- Север: Люди=3, Эльфы=1, Краснолюды=2, Ведьмаки=1+true
-- Нильфгаард: все=3, Ведьмаки=1+true
-- Скеллиге: все=3, Ведьмаки=2+false
-- Доль Блатанна: Люди=1, остальные=3, Ведьмаки=2+false
-- Махакам: Люди=2, остальные=3, Ведьмаки=2+false
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_race_witcher',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.social_status'),
      jsonb_build_object(
        'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_race.territory.north')::text),
        'group_status', 1,
        'group_is_feared', true
      )
    )
  )
UNION ALL
SELECT 'character', 'wcc_race_witcher',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.social_status'),
      jsonb_build_object(
        'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_race.territory.nilfgaard')::text),
        'group_status', 1,
        'group_is_feared', true
      )
    )
  )
UNION ALL
SELECT 'character', 'wcc_race_witcher',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.social_status'),
      jsonb_build_object(
        'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_race.territory.skellige')::text),
        'group_status', 2,
        'group_is_feared', false
      )
    )
  )
UNION ALL
SELECT 'character', 'wcc_race_witcher',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.social_status'),
      jsonb_build_object(
        'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_race.territory.dol_blathanna')::text),
        'group_status', 2,
        'group_is_feared', false
      )
    )
  )
UNION ALL
SELECT 'character', 'wcc_race_witcher',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.social_status'),
      jsonb_build_object(
        'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_race.territory.mahakam')::text),
        'group_status', 2,
        'group_is_feared', false
      )
    )
  );

-- Правила
INSERT INTO rules(name, body) VALUES ('is_elf', '{"==":[{"var":"characterRaw.logicFields.race"},"Elf"]}'::jsonb);
INSERT INTO rules(name, body) VALUES ('is_human', '{"==":[{"var":"characterRaw.logicFields.race"},"Human"]}'::jsonb);
INSERT INTO rules(name, body) VALUES ('is_dwarf', '{"==":[{"var":"characterRaw.logicFields.race"},"Dwarf"]}'::jsonb);
INSERT INTO rules(name, body) VALUES ('is_witcher', '{"==":[{"var":"characterRaw.logicFields.race"},"Witcher"]}'::jsonb);



