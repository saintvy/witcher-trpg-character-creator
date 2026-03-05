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

-- Правила видимости DLC-рас
INSERT INTO rules (ru_id, name, body)
VALUES
  (ck_id('witcher_cc.rules.is_dlc_exp_bot_enabled'), 'is_dlc_exp_bot_enabled', '{"in":["exp_bot",{"var":["dlcs",[]]}]}'::jsonb),
  (ck_id('witcher_cc.rules.is_dlc_exp_lal_enabled'), 'is_dlc_exp_lal_enabled', '{"in":["exp_lal",{"var":["dlcs",[]]}]}'::jsonb)
ON CONFLICT (ru_id) DO UPDATE
SET name = EXCLUDED.name,
    body = EXCLUDED.body;

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
'<h1 style="color:#c8762b;">Люди</h1>
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
<h2 style="color:#c8762b;">Черты</h2>
<h3>🟡 Доверие</h3>
В мире, где нелюдям не доверяют, людям довериться куда проще. У людей есть врождённый бонус +1 к проверкам Харизмы'
  || ', Соблазнения и Убеждения против других людей.
<h3>🟡 Изобретательность</h3>
Люди умны и зачастую находят великолепные решения сложных проблем. Люди получают врождённый бонус +1 к Дедукции.
<h3>🟡 Упрямство</h3>
Одно из величайших преимуществ человеческой расы — нежелание отступать даже в опасной ситуации. Они могут собраться '
  || 'с духом и перебросить неудачный результат проверки Сопротивления убеждению или Храбрости, но не более 3 раз за '
  || 'игровую партию. В таком случае из двух результатов выбирают наивысший, но если результат всё равно провальный, то '
  || 'вновь использовать Упрямство нельзя.
<h2 style="color:#c8762b;">Социальный статус</h2>
<table>
  <tr>
    <th>Территория</th>
    <th>Север</th>
    <th>Нильфгаард</th>
    <th>Скеллиге</th>
    <th>Доль Блатанна</th>
    <th>Махакам</th>
  </tr>
  <tr>
    <th>Социальный статус</th>
    <td>Равенство</td>
    <td>Равенство</td>
    <td>Равенство</td>
    <td>Ненависть</td>
    <td>Терпимость</td>
  </tr>
</table>'),
                ('en',
'<h1 style="color:#c8762b;">Humans</h1>
<i>If I were a worse person I''d vent my spleen and tell ya all the terrible things humans have done to my people and the other '
  || 'elder races. But I''m better than that. Worked with a lot of humans during the Northern Wars. Hell, most of the Temerian '
  || 'army''s humans. Humans can be fine folks. They''re varied in nature and usually a pretty resilient race. They tend to get '
  || 'swept up in causes and fears pretty easily, though. They''re the dominant species on the Continent right now and they know '
  || 'it. Heh. It''s easy to speak ill of ''em. They just about destroyed the elder races, wiped out the vran, killed all but a '
  || 'few hundred of the werebbubbs, built their cities on top of elderfolk cities, and depending on where you are they''re '
  || 'still killing elderfolk by the score every day. But they''re not all bad. Heh, most mages are human and they may '
  || 'destabilize countries and plunge the world into chaos, but they''ve also made the world better with magic and science. '
  || 'Human are a clever bunch, and in a pinch, a human you know well will probably have your back.
<b>–Rodolf Kazmer</b></i>
<h2 style="color:#c8762b;">Perks</h2>
<h3>🟡 Trustworthy</h3>
In a world where non-humans can''t be trusted, humans look more trustworthy. Humans have an inherent +1 to their Charisma, '
  || 'Seduction, and Persuasion checks against other humans.
<h3>🟡 Ingenuity</h3>
Humans are clever and often have brilliant solutions to difficult problems. Humans gain an inherent +1 to Deduction.
<h3>🟡 Blindly Stubborn</h3>
Part of the human race''s greatest strength is its willingness to charge forward endlessly, even into truly life-threatening '
  || 'situations. A human can summon up their courage and reroll a failed Resist Coercion or Courage roll 3 times per game '
  || 'session. They take the higher of the two rolls, but if they still fail they cannot re-use the ability to roll again.
<h2 style="color:#c8762b;">Social Standing</h2>
<table>
  <tr>
    <th>Territory</th>
    <th>The North</th>
    <th>Nilfgaard</th>
    <th>Skellige</th>
    <th>Dol Blathanna</th>
    <th>Mahakam</th>
  </tr>
  <tr>
    <th>Social Standing</th>
    <td>Equal</td>
    <td>Equal</td>
    <td>Equal</td>
    <td>Hated</td>
    <td>Tolerated</td>
  </tr>
</table>')) AS v(lang, text)
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
'<h1 style="color:#c8762b;">Краснолюды</h1>
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
<h2 style="color:#c8762b;">Черты</h2>
<h3>🟡 Закалённый</h3>
У краснолюдов весьма крепкая кожа, имеющая врождённую прочность 2. Эта величина прибавляется к прочности любой брони и не '
  || 'может быть понижена разрушающим уроном.
<h3>🟡 Силач</h3>
Благодаря невысокому росту и склонности к тяжёлой работе, требующей физических усилий, краснолюды получают +1 к Силе '
  || '(Навыку «Сила») и повышают своё значение Переносимого веса на 25.
<h3>🟡 Намётанный глаз</h3>
Краснолюды — прекрасные оценщики, обладающие вниманием к деталям; обмануть их трудно. Краснолюды получают врождённый '
  || 'бонус +1 к Торговле.
<h2 style="color:#c8762b;">Социальный статус</h2>
<table>
  <tr>
    <th>Территория</th>
    <th>Север</th>
    <th>Нильфгаард</th>
    <th>Скеллиге</th>
    <th>Доль Блатанна</th>
    <th>Махакам</th>
  </tr>
  <tr>
    <th>Социальный статус</th>
    <td>Терпимость</td>
    <td>Равенство</td>
    <td>Равенство</td>
    <td>Равенство</td>
    <td>Равенство</td>
  </tr>
</table>'),
        ('en',
'<h1 style="color:#c8762b;">Dwarves</h1>
<i>Heh. My friend, rivers dry up, mountains crumble, but dwarves are a constant. We may be short compared to the elves and '
  || 'the humans but we''re sturdier than they''ll ever be—the definition of barrel-chested! We dwarves have been around '
  || 'for ages, livin'' in the mountains and plyin'' our trade: forg in''. We''re friendly enough when ya get to know us '
  || 'and easy to get along with as long as ya don''t piss in our faces. The humans may not love us dwarves, but they need '
  || 'us for our skill and our steel. ''Sides, unlike the damn elves we don''t hold an in-born grudge against the humans. '
  || 'We keep to our business and them to theirs. Share a drink here and there. Heh, sadly, madness is spreadin'' quick '
  || 'through the North and dwarves are targets now more than ever. Lucky the humans have a hard time pickin'' out our women! '
  || 'Never find a prettier lass than a dwarven girl. They say the fuller the beard, the fuller the...well. Ya get my point.
<b>-Rodolf Kazmer</b></i>
<h2 style="color:#c8762b;">Perks</h2>
<h3>🟡 Tough</h3>
Spending much of their time in the mountains and mines, dwarves have naturally tough skin. A dwarf''s skin has a natural '
  || 'Stopping Power of 2. This SP is applied on top of any armor the dwarf is already wearing and cannot be lowered via '
  || 'weapon attacks or ablation damage.
<h3>🟡 Strong</h3>
Due to their compact frame and propensity for tough, physically demanding professions, dwarves gain a +1 to their Physique '
  || 'skill and raise their Encumbrance by 25.
<h3>🟡 Crafter''s Eye</h3>
With their eye for fine detail and appraisal it is hard to bluff a dwarf. Dwarves have an inherent +1 to their Business skill.
<h2 style="color:#c8762b;">Social Standing</h2>
<table>
  <tr>
    <th>Territory</th>
    <th>The North</th>
    <th>Nilfgaard</th>
    <th>Skellige</th>
    <th>Dol Blathanna</th>
    <th>Mahakam</th>
  </tr>
  <tr>
    <th>Social Standing</th>
    <td>Tolerated</td>
    <td>Equal</td>
    <td>Equal</td>
    <td>Equal</td>
    <td>Equal</td>
  </tr>
</table>')
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
'<h1 style="color:#c8762b;">Эльфы (Aen Seidhe)</h1>
<i>История эльфов (точнее Aen Seidhe, поскольку наши эльфы далеко не единственные) весьма грустная. Они прибыли сюда неизвестно '
  || 'откуда на огромных белых кораблях. Случилось это незадолго до появления людей. Я бы не назвал эльфов добряками, но с '
  || 'остальными они как-то уживались. От людей они не сильно отличаются: высокие, худые, любят на другиe народы свысока '
  || 'смотреть. Разве что уши острые, жизнь вечная, да, считай, полное единение с природой — эльфы много поколений только и '
  || 'делали, что занимались собирательством и строили дворцы. У них за время поедания ягод да кореньев и клыков-то не осталось. '
  || 'Правда, всё равно не советую их из себя выводить — на поле боя эльфы могут устроить вам ещё ад. Броню они толком не носят, '
  || 'но заприметить эльфа в лесу так же тяжело, как зимой лягушку найти. А уж искуснее лучника, чем эльф, днём с огнём не сыщешь.
<b>Родольф Казмер</b></i>
<h2 style="color:#c8762b;">Черты</h2>
<h3>🟡 Чувство прекрасного</h3>
У эльфов есть врождённая творческая жилка и развитое чувство прекрасного. Эльфы получают врождённый бонус +1 к Искусству.
<h3>🟡 Стрелок</h3>
Благодаря давним традициям и постоянным тренировкам эльфы — одни из лучших лучников в мире. Эльфы получают врождённый бонус +2 '
  || 'к Стрельбе из лука и способны взводить и натягивать лук, не тратя на это действие.
<h3>🟡 Единение с природой</h3>
Эльфы тесно связаны с природой. Они не тревожат животных — любой зверь, встреченный эльфом, будет относиться к нему дружелюбно '
  || 'и не нападёт без провокации. Эльфы также автоматически находят любые обычные и повсеместные растительные субстанции, если '
  || 'искомое растение естественно обитает на данной территории.
<h2 style="color:#c8762b;">Социальный статус</h2>
<table>
  <tr>
    <th>Территория</th>
    <th>Север</th>
    <th>Нильфгаард</th>
    <th>Скеллиге</th>
    <th>Доль Блатанна</th>
    <th>Махакам</th>
  </tr>
  <tr>
    <th>Социальный статус</th>
    <td>Ненависть</td>
    <td>Равенство</td>
    <td>Равенство</td>
    <td>Равенство</td>
    <td>Равенство</td>
  </tr>
</table>'),
        ('en',
'<h1 style="color:#c8762b;">Elves (The Aen Seidhe)</h1>
<i>Elves, or the Aen Seidhe, since ours aren''t the only elves out there, are a sad tale indeed. Heh. They came to the world '
  || 'not long before humans, in great white ships from somewhere. Wouldn''t call ''em the kindest of the races but they get '
  || 'along well enough with the rest of us. They''re not too unlike humans: tall, thin, prone to lookin'' down on others. '
  || 'Only difference is their pointed ears, their seemingly eternal lives, and their bond with the land. Heh, the elves are '
  || 'at one with nature or somethin''. Lived off the land for generations, foragin'' for food and buildin'' great palaces. '
  || 'Don''t even have sharp teeth after all those years of eatin'' berries and plants. Don''t get ''em cross though; an elf''s '
  || 'hell on the battlefield too. They may not wear much armor but they''re hard as frogs in winter to find in the wilderness, '
  || 'and probably the best archers you''ll ever see.
<b>Rodolf Kazmer</b></i>
<h2 style="color:#c8762b;">Perks</h2>
<h3>🟡 Artistic</h3>
Elves have a natural eye for beauty and a talent for artistic endeavours. Elves gain an inherent +1 to their Fine Arts skill.
<h3>🟡 Marksman</h3>
Years of tradition and practice make elves some of the best archers in the world. Elves gain an inherent +2 to their Archery '
  || 'skill and can draw and string a bow without taking an action.
<h3>🟡 Natural Attunement</h3>
Elves have a deep magical bond with nature itself. Elves do not disturb animals, meaning any beast they encounter is considered '
  || 'friendly and will not attack unless provoked. Elves also automatically find any plant substance rated as commonly '
  || 'available (or lower) that they are seeking, as long as the substance would occur naturally in the surrounding terrain.
<h2 style="color:#c8762b;">Social Standing</h2>
<table>
  <tr>
    <th>Territory</th>
    <th>The North</th>
    <th>Nilfgaard</th>
    <th>Skellige</th>
    <th>Dol Blathanna</th>
    <th>Mahakam</th>
  </tr>
  <tr>
    <th>Social Standing</th>
    <td>Hated</td>
    <td>Equal</td>
    <td>Equal</td>
    <td>Equal</td>
    <td>Equal</td>
  </tr>
</table>')
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
'<h1 style="color:#c8762b;">Ведьмаки</h1>
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
<h2 style="color:#c8762b;">Черты</h2>
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
  || 'и Ловкости, позволяющий превышать 10.</i>
<h2 style="color:#c8762b;">Социальный статус</h2>
<table>
  <tr>
    <th>Территория</th>
    <th>Север</th>
    <th>Нильфгаард</th>
    <th>Скеллиге</th>
    <th>Доль Блатанна</th>
    <th>Махакам</th>
  </tr>
  <tr>
    <th>Социальный статус</th>
    <td>Ненависть и Опасение</td>
    <td>Ненависть и Опасение</td>
    <td>Терпимость</td>
    <td>Терпимость</td>
    <td>Терпимость</td>
  </tr>
</table>'),
        ('en',
'<h1 style="color:#c8762b;">Witchers</h1>
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
<h2 style="color:#c8762b;">Perks</h2>
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
  || 'Reflex and Dexterity that can raise these stats above 10.
<h2 style="color:#c8762b;">Social Standing</h2>
<table>
  <tr>
    <th>Territory</th>
    <th>The North</th>
    <th>Nilfgaard</th>
    <th>Skellige</th>
    <th>Dol Blathanna</th>
    <th>Mahakam</th>
  </tr>
  <tr>
    <th>Social Standing</th>
    <td>Hated & Feared</td>
    <td>Hated & Feared</td>
    <td>Tolerated</td>
    <td>Tolerated</td>
    <td>Tolerated</td>
  </tr>
</table>')
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

-- Опция ответа: Низушки / Halflings
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_race' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, ins_label AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(5, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
         , meta.entity, meta.entity_field, v.lang, v.text
      FROM (VALUES
        ('ru',
$$<h1 style="color:#c8762b;">Низушки</h1>
<i>Забавные они, низушки. Невысокие, как краснолюды, но не такие коренастые. Ушки острые, прям как у эльфов, да только с природой низушки не настолько ладят. Не будь у них таких мохнатых ног, были б вылитые полуэльфы! А если серьёзно, низушки - хорошие малые. Что самое странное, они не поддаются магии. Никто не знает почему, но на низушков вроде как не действуют некоторые виды волшебства - многие заклинания, зелья и всякое такое. Похоже, они появились здесь при Сопряжении, так что, может, дело в их родине. Сейчас низушки живут в человеческих городах, но стараются не особо светиться. Не то чтобы они прятались, просто не высовываются. Видать, из-за того, что они не претендуют на свою территорию и живут в мире с людьми, их не так сильно гонят, как остальных нелюдей.
<b>-Родольф Казмер</b></i>
<h2 style="color:#c8762b;">Черты</h2>
<h3>🟡 Проворство</h3>
Низушки от природы шустры и ловки. Они получают врождённый бонус [+1 к Атлетике].
<h3>🟡 Сельский труженик</h3>
Низушки часто тянет к сельскому хозяйству благодаря вековым традициям и врождённой склонности к разведению животных. Низушки получают врождённый бонус [+2 к выживанию в диких условиях], а также при попытке успокоить, приручить или подчинить себе животное.
<h3>🟡 Защита против магии</h3>
По неизвестной причине низушки обладают сопротивлением определённым формам магии. Они получают врождённый бонус [+5 к Сопротивлению магии] и могут совершать проверки Сопротивления магии, чтобы отменять эффекты любого заклинания, воздействующего на разум, даже если обычно такая проверка запрещена. Однако ведьмачьи эликсиры и прочие магические зелья не приносят низушкам пользы (даже если низушек успешно пройдёт проверку Стойкости).
Благодаря врождённому сопротивлению магии низушки неспособны проводить через своё тело силу хаоса и потому не могут быть магами или жрецами.
Маг, обладающий способностью Мутация, может изменить с её помощью низушка. Однако из-за врождённого сопротивления магии низушки не мутируют под действием синих мутагенов.

<h2 style="color:#c8762b;">Социальный статус</h2>
<table>
  <tr>
    <th>Территория</th>
    <th>Север</th>
    <th>Нильфгаард</th>
    <th>Скеллиге</th>
    <th>Доль Блатанна</th>
    <th>Махакам</th>
  </tr>
  <tr>
    <th>Социальный статус</th>
    <td>Терпимость</td>
    <td>Равенство</td>
    <td>Равенство</td>
    <td>Равенство</td>
    <td>Равенство</td>
  </tr>
</table>$$),
        ('en',
$$<h1 style="color:#c8762b;">Halflings</h1>
<i>Interestin' folk, halflings. Short as a dwarf but not as stocky. Got pointy ears like an elf but they ain't as "in tune" with nature and whatnot. Heh, if it weren't for their big hairy feet, I'd say they're a cross-breed! All kiddin' aside though, they're fine folk! Strangest part about a halfling's the way they sorta repel magic or somethin'. Nobody knows why but halflings are immune to certain magics or some such. Lotsa spells and elixirs and whatnot just don't work on 'em. Think they came through durin' the Conjunction so maybe it's somethin' to do with their home. These days ya can find halfling's livin' in human cities makin' their way in the background. Don't really try to hide, they just don't come up much. Guess since they don't claim land and they like livin' among humans, they don't get harassed as much.
<b>-Rodolf Kazmer</b></i>
<h2 style="color:#c8762b;">Perks</h2>
<h3>🟡 Nimble</h3>
Halflings are naturally nimble and dexterous people. Halflings gain an inherent bonus [+1 to Athletics].
<h3>🟡 Farmhand</h3>
Halflings are often drawn to agriculture, thanks to years of tradition and an apparently inborn aptitude at animal husbandry. Halflings gain an inherent bonus [+2 to Wilderness Survival], as well as when calming, taming, or controlling animals.
<h3>🟡 Magic Resistant</h3>
For unknown reasons, halflings are resistant to certain forces of magic. Halflings gain an inherent bonus [+5 to Resist Magic] and are able to roll Resist Magic to negate the effects of any spell that would affect their mind even if it would not normally be allowed. However, Witcher potions and other magic potions do not positively affect halflings (even if they succeed at the Endurance check).
Due to their magic-resistant nature, halflings are unable to channel magic through their bodies and cannot become Mages or Priests.
Halflings can be mutated, with the Mages' Mutate Ability. However, due to their magic resistance, halflings cannot be mutated by Blue Mutagens.

<h2 style="color:#c8762b;">Social Standing</h2>
<table>
  <tr>
    <th>Territory</th>
    <th>The North</th>
    <th>Nilfgaard</th>
    <th>Skellige</th>
    <th>Dol Blathanna</th>
    <th>Mahakam</th>
  </tr>
  <tr>
    <th>Social Standing</th>
    <td>Tolerated</td>
    <td>Equal</td>
    <td>Equal</td>
    <td>Equal</td>
    <td>Equal</td>
  </tr>
</table>$$)
      ) AS v(lang, text)
      CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT 'wcc_race_halfling'
     , meta.su_su_id
     , meta.qu_id
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(5, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label
     , 5 AS sort_order
     , (SELECT ru_id FROM rules WHERE ru_id = ck_id('witcher_cc.rules.is_dlc_exp_lal_enabled') LIMIT 1) AS visible_ru_ru_id
     , '{}'::jsonb AS metadata
  FROM meta;

-- Эффекты выбора расы: Низушек
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_race' AS qu_id
                , 'character' AS entity)
, ins_r_halfling AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'halfling' ||'.'|| meta.entity ||'.'|| 'race') AS id
       , meta.entity, 'race', v.lang, v.text
    FROM (VALUES
      ('ru', 'Низушек'),
      ('en', 'Halfling')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_halfling_f1 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'halfling' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '1') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Проворство</b>: врождённый бонус [+1 к Атлетике]'),
      ('en', '<b>Nimble</b>: inherent bonus [+1 to Athletics]')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_halfling_f2 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'halfling' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '2') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Сельский труженик</b>: [+2 к выживанию в диких условиях] и при взаимодействии с животными'),
      ('en', '<b>Farmhand</b>: [+2 to Wilderness Survival] and when interacting with animals')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_halfling_f3 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'halfling' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '3') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Защита против магии</b>: [+5 к Сопротивлению магии]; отмена ментальных заклинаний через бросок Сопротивления магии; магический Элексиры и Зелья бесполезны; не мутирует от синих мутагенов'),
      ('en', '<b>Magic Resistant</b>: [+5 to Resist Magic]; can roll Resist Magic against mind-affecting spells; magic Elixirs and Potions give no positive effect; cannot be mutated by Blue Mutagens')
    ) AS v(lang, text)
    CROSS JOIN meta
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_race_halfling',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.race'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'halfling' ||'.'|| meta.entity ||'.'|| 'race')::text)
    )
  )
FROM meta UNION ALL
SELECT
  'character' AS scope,
  'wcc_race_halfling' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.logicFields.race'),
      'Halfling'
    )
  ) AS body
UNION ALL
SELECT
  'character',
  'wcc_race_halfling',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'halfling' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '1')::text)
    )
  )
FROM meta
UNION ALL
SELECT
  'character',
  'wcc_race_halfling',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'halfling' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '2')::text)
    )
  )
FROM meta
UNION ALL
SELECT
  'character',
  'wcc_race_halfling',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'halfling' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '3')::text)
    )
  )
FROM meta UNION ALL
-- Эффекты черт расы: Низушек - Проворство (+1 к Атлетике)
SELECT 'character', 'wcc_race_halfling',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.athletics.race_bonus'),
      1
    )
  )
UNION ALL
-- Эффекты черт расы: Низушек - Сельский труженик (+2 к выживанию в диких условиях)
SELECT 'character', 'wcc_race_halfling',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.wilderness_survival.race_bonus'),
      2
    )
  )
UNION ALL
-- Эффекты черт расы: Низушек - Защита против магии (+5 к Сопротивлению магии)
SELECT 'character', 'wcc_race_halfling',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.resist_magic.race_bonus'),
      5
    )
  );

-- Опция ответа: Гномы / Gnomes
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_race' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, ins_label AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(6, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
         , meta.entity, meta.entity_field, v.lang, v.text
      FROM (VALUES
        ('ru',
$$<h1 style="color:#c8762b;">Гномы</h1>
Гномы образуют большие коммуны, как и краснолюды, но склонны к менее авторитарной структуре. Эти коммуны, самые известные две из которых находятся в горах Тир-Тохайр и Махакам, обычно возглавляются особенно уважаемым гномом, который имеет решающий голос на больших народных собраниях, управляемых посредством прямой демократии. Гномы имеют давнюю историю дружбы с краснолюдами Континента, особенно с их представителями в Махакаме, с которыми они мирно жили многие сотни лет, работая вместе в шахтах и мастерских.
<h2 style="color:#c8762b;">Черты</h2>
<h3>🟡 Приятное поведение</h3>
По всему Континенту гномы известны своим весёлым жизнерадостным характером и озорной натурой. Среди людей гномы часто считаются самыми приятными из нелюдей. Гномы получают врождённый [+1 к Харизме].
<h3>🟡 Внимание к деталям</h3>
В то время, как эльфы и краснолюды являются величайшими мастерами изготовления в мире, гномы обладают лучшим вниманием к деталям на всём Континенте, что делает их превосходными мастерами в разном ремесленном деле. Нет ничего необычного в том, чтобы найти гнома, который одновременно занимается огранкой драгоценных камней, изготовливанием мечей и алхимией. Гномы получают врождённые +2 к любым 3 навыкам РЕМЕСЛА на выбор. Этот бонус игнорирует правило для сложных навыков.
<h3>🟡 Острый нюх</h3>
Обострённое чутьё гномов на детали распространяется на все их органы чувств, включая обоняние. Гномы получают врождённый [+1 к Вниманию], а также способность ориентироваться по запаху.
<h3>🟡 Низкий рост</h3>
Гномы — самая низкая раса на Континенте, в среднем около одного метра высотой. Хотя они могут быть такими же выносливыми, как и другие расы, но как правило, физически они слабее. Гномы получают врождённый штраф -5 к Силе и рассчитывают свой урон рукой/ногой, бонусный урон в ближнем бою и Вес, как если бы их ТЕЛ было на 3 очка ниже. Зато гном может проскользнуть в любую щель диаметром не менее 0.5 м и спрятаться за объектом не меньше 1 м на 1 м.

<h2 style="color:#c8762b;">Социальный статус</h2>
<table>
  <tr>
    <th>Территория</th>
    <th>Север</th>
    <th>Нильфгаард</th>
    <th>Скеллиге</th>
    <th>Доль Блатанна</th>
    <th>Махакам</th>
  </tr>
  <tr>
    <th>Социальный статус</th>
    <td>Терпимость</td>
    <td>Равенство</td>
    <td>Равенство</td>
    <td>Равенство</td>
    <td>Равенство</td>
  </tr>
</table>$$),
        ('en',
$$<h1 style="color:#c8762b;">Gnomes</h1>
With their eye for detail and exceptional sensory abilities, gnomes are the finest craftsmen on the Continent. The finest swords in the world, Gwyhyr, are gnomish. They also excel in alchemy, metallurgy, and engineering. Due to their majestic works, gnomes are tolerated in human societies, though they rarely visit. Gnomes are generally known for being friendly, puckish, and liking to party. They are less abrasive than dwarves, less stern than elves, and less fussy than halflings, all of which contribute to their appeal, according to humans. In small human communities, a gnome can expect not only tolerance, but also friendship. Trouble might arise for them in larger human cities, however.
<h2 style="color:#c8762b;">Perks</h2>
<h3>🟡 Pleasant Demeanor</h3>
Across the continent, gnomes are known for their fun-loving joyous personalities and puckish nature. Among humans, gnomes are often considered the most pleasant of the Non-humans. Gnomes gain an inherent [+1 to Charisma].
<h3>🟡 Eye for Detail</h3>
While elves and dwarves are among the greatest craftsmen in the world, gnomes possess the finest eye for detail on the entire continent making them excellent at many different crafts. It is not unusual to find a gnome who trades in gem-cutting, sword smith, and alchemy all at the same time. Gnomes gain an inherent [+2 to any 3 Craft Skills] they choose. This bonus ignores the modifier for learning Difficult Skill.
<h3>🟡 Scent Tracking</h3>
A gnome’s keen sense for detail extends to all their senses including their sense of smell. Gnomes gain an inherent [+1 to their Awareness skill], as well as the ability to track things by scent alone.
<h3>🟡 Small Stature</h3>
Gnomes are the smallest race on the Continent, measuring in around 1m tall on average. While they can be just as resilient as other races, they are generally physically weaker. Gnomes take an inherent -5 to Physique and calculate their hand-to-hand damage, bonus melee damage, and Encumbrance as though their BODY was 3 points lower. However, a gnome can slip into any area at least 0.5m wide with no issue and can fully conceal themselves behind an item or creature at least 1m by 1m.

<h2 style="color:#c8762b;">Social Standing</h2>
<table>
  <tr>
    <th>Territory</th>
    <th>The North</th>
    <th>Nilfgaard</th>
    <th>Skellige</th>
    <th>Dol Blathanna</th>
    <th>Mahakam</th>
  </tr>
  <tr>
    <th>Social Standing</th>
    <td>Tolerated</td>
    <td>Equal</td>
    <td>Equal</td>
    <td>Equal</td>
    <td>Equal</td>
  </tr>
</table>$$)
      ) AS v(lang, text)
      CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT 'wcc_race_gnome'
     , meta.su_su_id
     , meta.qu_id
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(6, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label
     , 6 AS sort_order
     , (SELECT ru_id FROM rules WHERE ru_id = ck_id('witcher_cc.rules.is_dlc_exp_bot_enabled') LIMIT 1) AS visible_ru_ru_id
     , '{}'::jsonb AS metadata
  FROM meta;

-- Эффекты выбора расы: Гном
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_race' AS qu_id
                , 'character' AS entity)
, ins_r_gnome AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'gnome' ||'.'|| meta.entity ||'.'|| 'race') AS id
       , meta.entity, 'race', v.lang, v.text
    FROM (VALUES
      ('ru', 'Гном'),
      ('en', 'Gnome')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_gnome_f1 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'gnome' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '1') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Приятное поведение</b>: врождённый бонус [+1 к Харизме]'),
      ('en', '<b>Pleasant Demeanor</b>: inherent bonus [+1 to Charisma]')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_gnome_f2 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'gnome' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '2') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Внимание к деталям</b>: врождённый бонус [+2 к любым 3 навыкам Ремесла по выбору]'),
      ('en', '<b>Eye for Detail</b>: inherent bonus [+2 to any 3 Craft Skills]')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_gnome_f3 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'gnome' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '3') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Острый нюх</b>: врождённый бонус [+1 к Вниманию]; может ориентироваться по запаху'),
      ('en', '<b>Scent Tracking</b>: inherent bonus [+1 to Awareness]; can track by scent alone')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_gnome_f4 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'gnome' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '4') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Низкий рост</b>: [-5 к Силе]; [ТЕЛ-3 при рассчете удара рукой/ногой, бонусного урона в ближнем бою и переносимого веса]; пролезает в щели от 0.5 м и прятаться за объектом от 1x1 м'),
      ('en', '<b>Small Stature</b>: [-5 to Physique]; [BODY-3 for hand-to-hand damage, bonus melee damage, and Encumbrance]; can slip through 0.5m gaps and fully conceal behind 1x1m cover')
    ) AS v(lang, text)
    CROSS JOIN meta
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_race_gnome',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.race'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'gnome' ||'.'|| meta.entity ||'.'|| 'race')::text)
    )
  )
FROM meta UNION ALL
SELECT
  'character' AS scope,
  'wcc_race_gnome' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.logicFields.race'),
      'Gnome'
    )
  ) AS body
UNION ALL
SELECT
  'character',
  'wcc_race_gnome',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'gnome' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '1')::text)
    )
  )
FROM meta
UNION ALL
SELECT
  'character',
  'wcc_race_gnome',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'gnome' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '2')::text)
    )
  )
FROM meta
UNION ALL
SELECT
  'character',
  'wcc_race_gnome',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'gnome' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '3')::text)
    )
  )
FROM meta
UNION ALL
SELECT
  'character',
  'wcc_race_gnome',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'gnome' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '4')::text)
    )
  )
FROM meta UNION ALL
-- Эффекты черт расы: Гном - Приятное поведение (+1 к Харизме)
SELECT 'character', 'wcc_race_gnome',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.charisma.race_bonus'),
      1
    )
  )
UNION ALL
-- Эффекты черт расы: Гном - Острый нюх (+1 к Вниманию)
SELECT 'character', 'wcc_race_gnome',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.awareness.race_bonus'),
      1
    )
  )
UNION ALL
-- Эффекты черт расы: Гном - Низкий рост (-5 к Силе / Physique)
SELECT 'character', 'wcc_race_gnome',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.physique.race_bonus'),
      -5
    )
  );

-- Опция ответа: Враны / Vrans
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_race' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, ins_label AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(7, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
         , meta.entity, meta.entity_field, v.lang, v.text
      FROM (VALUES
        ('ru',
$$<h1 style="color:#c8762b;">Враны</h1>
Иногда называемые людо-ящерами, враны являются одной из старейших и наиболее физически развитых рас на Континенте и, к сожалению, также одной из самых презираемых людьми. Ещё до Первой Высадки враны были преобладающей и развитой культурой, которая охватывала Континент от Великого Моря до Синих Гор и дальше. Среди разумных рас Континента враны были известны своими искусно построенными городами, уникальной архитектурой и горами золота и драгоценностей. Несмотря на то, что враны были известны, как бесстрастный и холодный народ, они заслужили большое уважение за свою хладнокровную политику и всеобъемлющую культуру. Даже сегодня многие излюбленные афоризмы, используемые учёными по всему Континенту, берут свое начало в культуре вранов.
<h2 style="color:#c8762b;">Черты</h2>
<h3>🟡 Хладнокровный</h3>
Многие знают, что Враны — бессердечные существа, не способные сочувствовать. Однако, это далеко от истины. Враны также способны переживать, как и любой человек, но они гораздо более сдержанны и менее склонны показывать свои эмоции. Вран получает врождённый [+1 к Сопротивлению убеждению].
<h3>🟡 Когти и клыки</h3>
Хоть Враны, как и все пользуются оружием, они также способны причинять серьезный вред врагам своими естественными когтями и клыками. У Врана есть два естественных оружия, которые нельзя отобрать. Удары Врана руками и ногами наносят смертельный урон, и он может совершить атаку своими клыками через Ближний бой, которая наносит 3d6 урона с 50%-й вероятностью отравления.
<h3>🟡 Чешуя</h3>
У Врана есть естественный слой чешуи, который дает им определенное естественное сопротивление урону. Чешуя Врана имеет естественную броню, равную 4. Эта ПБ не может быть снижена с помощью атак оружием или разрушающим уроном.
<h3>🟡 Физиология Рептилий</h3>
Враны — единственная признанная разумная раса, которая также является рептилией, а их физиология немного отличается от физиологии человека и других нечеловеческих рас. Эта разница может быть небольшой, но она оказывает большое влияние двумя способами. Во-первых, тело Врана отличается настолько, что любой медик, который не является Враном и не лечил Врана успешно в прошлом, получает штраф -2 при использовании Первой помощи и штраф -5 при стабилизации или лечении Критических ранений Врана. Во-вторых, если на Врана действует эффект Замораживания, он получает -2 на все действия на 1d6 раундов после окончания эффекта.

<h2 style="color:#c8762b;">Социальный статус</h2>
<table>
  <tr>
    <th>Территория</th>
    <th>Север</th>
    <th>Нильфгаард</th>
    <th>Скеллиге</th>
    <th>Доль Блатанна</th>
    <th>Махакам</th>
  </tr>
  <tr>
    <th>Социальный статус</th>
    <td>Ненависть и Опасение</td>
    <td>Терпимость и Опасение</td>
    <td>Ненависть и Опасение</td>
    <td>Ненависть</td>
    <td>Терпимость</td>
  </tr>
</table>$$),
        ('en',
$$<h1 style="color:#c8762b;">Vrans</h1>
Sometimes referred to as Lizardfolk, the vran are among the oldest and most physically varied races on the continent and unfortunately also among the most despised by humans. In the time before the Landing of the Exiles, the vran were a prevalent and accomplished culture who spanned the Continent from the Great Sea to the Blue Mountains and beyond. Among the sapient races of the Continent, the vran were known for their carefully constructed cities, their unique architecture, and their hordes of gold and jewels. Despite being known as dispassionate and cold, vran earned a great deal of respect for their cool-headed politics, and pervasive culture. Even today, many favored aphorisms used by scholars across the continent have their origins in vrani culture.
<h2 style="color:#c8762b;">Perks</h2>
<h3>🟡 Calm Hearted</h3>
Vran are known by many to be heartless creatures with no empathy to speak of. However, this is far from the truth. Vran have as much capability for empathy as any human but they are far more reserved and less likely to show their emotion. Vran gain an inherent [+1 Resist Coercion].
<h3>🟡 Claws & Fangs</h3>
While the vran are known to use weapons, they are also capable of dealing grievous harm to their enemies with their natural claws and fangs. A vran has two natural weapons that cannot be disarmed. A vran’s punches and kicks deal lethal damage and they can make a Melee attack with their fangs, which deals 3d6 damage with a 50% chance of poisoning the target.
<h3>🟡 Scaled Hide</h3>
Vran have a natural layer of scales which grant them a certain amount of natural resistance to damage. A vran’s scales have a natural stopping power of 4. This SP cannot be lowered via weapon attacks or ablation damage.
<h3>🟡 Reptilian Physiology</h3>
The vran are the only accepted sapient race that is also reptilian and their physiology differs ever so slightly from that of humans and other non-human races. This difference may be small, but it makes a big impact in two ways. First, a vran’s body is different enough that any doctor who is not a vran and has not treated a vran successfully in the past takes a -2 penalty when using First Aid on a wounded vran and a -5 penalty when attempting to stabilize or treat Critical Wounds on a wounded vran. Second, if a vran is affected by the Frozen condition, they take a -2 to all actions until 1d6 rounds after the condition is ended.

<h2 style="color:#c8762b;">Social Standing</h2>
<table>
  <tr>
    <th>Territory</th>
    <th>The North</th>
    <th>Nilfgaard</th>
    <th>Skellige</th>
    <th>Dol Blathanna</th>
    <th>Mahakam</th>
  </tr>
  <tr>
    <th>Social Standing</th>
    <td>Hated & Feared</td>
    <td>Tolerated & Feared</td>
    <td>Hated & Feared</td>
    <td>Hated</td>
    <td>Tolerated</td>
  </tr>
</table>$$)
      ) AS v(lang, text)
      CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT 'wcc_race_vran'
     , meta.su_su_id
     , meta.qu_id
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(7, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label
     , 7 AS sort_order
     , (SELECT ru_id FROM rules WHERE ru_id = ck_id('witcher_cc.rules.is_dlc_exp_bot_enabled') LIMIT 1) AS visible_ru_ru_id
     , '{}'::jsonb AS metadata
  FROM meta;

-- Эффекты выбора расы: Вран
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_race' AS qu_id
                , 'character' AS entity)
, ins_r_vran AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'vran' ||'.'|| meta.entity ||'.'|| 'race') AS id
       , meta.entity, 'race', v.lang, v.text
    FROM (VALUES
      ('ru', 'Вран'),
      ('en', 'Vran')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_vran_f1 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'vran' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '1') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Хладнокровный</b>: врождённый бонус [+1 к Сопротивлению убеждению]'),
      ('en', '<b>Calm Hearted</b>: inherent bonus [+1 Resist Coercion]')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_vran_f2 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'vran' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '2') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Когти и клыки</b>: атаки руками/ногами наносят смертельный урон; атака клыками через Ближний бой наносит 3d6 урона с вероятностью отравления 50%'),
      ('en', '<b>Claws & Fangs</b>: punches and kicks deal lethal damage; fangs can make a Melee attack for 3d6 damage with 50% poison chance')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_vran_f3 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'vran' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '3') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Чешуя</b>: естественная неснижаемая броня 4 ПБ'),
      ('en', '<b>Scaled Hide</b>: natural SP 4 which cannot be lowered')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_vran_f4 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'vran' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '4') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Физиология Рептилий</b>: -2 к Первой помощи и -5 к стабилизации/лечению критических ранений для медика не-врана или без опыта лечения вранов; -2 на все действия на 1d6 раундов после Замораживания'),
      ('en', '<b>Reptilian Physiology</b>: non-vran medics or those without experience take -2 on First Aid and -5 on stabilizing/treating Critical Wounds on a vran; Frozen condition causes -2 to all actions for 1d6 rounds after it ends')
    ) AS v(lang, text)
    CROSS JOIN meta
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_race_vran',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.race'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'vran' ||'.'|| meta.entity ||'.'|| 'race')::text)
    )
  )
FROM meta UNION ALL
SELECT
  'character' AS scope,
  'wcc_race_vran' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.logicFields.race'),
      'Vran'
    )
  ) AS body
UNION ALL
SELECT
  'character',
  'wcc_race_vran',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'vran' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '1')::text)
    )
  )
FROM meta
UNION ALL
SELECT
  'character',
  'wcc_race_vran',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'vran' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '2')::text)
    )
  )
FROM meta
UNION ALL
SELECT
  'character',
  'wcc_race_vran',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'vran' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '3')::text)
    )
  )
FROM meta
UNION ALL
SELECT
  'character',
  'wcc_race_vran',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'vran' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '4')::text)
    )
  )
FROM meta UNION ALL
-- Эффекты черт расы: Вран - Хладнокровный (+1 к Сопротивлению убеждению)
SELECT 'character', 'wcc_race_vran',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.resist_coercion.race_bonus'),
      1
    )
  );

-- Опция ответа: Баболаки / Werebbubbs
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_race' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, ins_label AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(8, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
         , meta.entity, meta.entity_field, v.lang, v.text
      FROM (VALUES
        ('ru',
$$<h1 style="color:#c8762b;">Баболаки</h1>
Баболаки относятся к менее гуманоидным Старшим Расам, которые были почти уничтожены после Первой Высадки много веков назад. Подобно своим собратьям-вранам, Баболаки жили в низменных долинах и в предгорьях Континента, соблюдая вековые традиции и стремясь жить в относительной гармонии с окружающей их природой. Баболаки были и остаются гордой расой с долгой историей героизма и доблести. Фактически, вместо того, чтобы поклоняться богам, Баболаки почитают память своих предков и духов легендарных героев и героинь. Баболаки воспитываются на историях о великих воинах и знающих мудрецах, которые использовали свои дары, чтобы помочь своему народу и победить ужасных врагов.
<h2 style="color:#c8762b;">Черты</h2>
<h3>🟡 Львиное Сердце</h3>
Баболаки — не самая многочисленная раса на Континенте, но они одни из самых храбрых. Их культура ценит героизм, а молодым Баболакам рассказывают об их древних героях предках. Баболаки получают врождённый [+1 к Храбрости].
<h3>🟡 Странная Физиология</h3>
Тело и метаболизм Баболаков работают совершенно не так, как у людей и большинства других Старших рас. При тяжелом ранении срабатывает какой-то аспект физиологии Баболака, часто позволяя ему пережить рану, которая быстро убила бы любого другого героя. Всякий раз, когда Баболаки получают Критическое Ранение, они могут пройти проверку Стойкости со СЛ, равной СЛ, необходимой для Стабилизации Критического Ранения. В случае успеха Критическое ранение немедленно считается Стабилизированным. Игроки могут сделать этот бросок только в тот момент, когда Баболаки получают ранение, и в случае неудачи повторная попытка невозможна.
<h3>🟡 Зубы-бритвы</h3>
Хотя Баболаки не обладают мощными челюстями и ядовитыми клыками вранов, их зубы острые, как бритва и отточены до тонкой кромки. Своими зубами Баболаки могут через Ближний бой совершить атаку, которая наносит 2d6 урона и обладает Улучшенным пробиванием брони.
<h3>🟡 Плохое зрение</h3>
Как правило, Баболаки подвержены ухудшенному зрению. Хотя их острый слух позволяет им без особых проблем ориентироваться в мире, они далеко не самая внимательная раса на Континенте. Баболаки получают врождённый штраф -4 к проверкам Внимания из-за своего плохого зрения. Если Баболака просят сделать проверку Понимания людей, основанную только на слухе (например, услышать шаги наверху или прислушаться к рычанию волков), этот штраф не применяется.

<h2 style="color:#c8762b;">Социальный статус</h2>
<table>
  <tr>
    <th>Территория</th>
    <th>Север</th>
    <th>Нильфгаард</th>
    <th>Скеллиге</th>
    <th>Доль Блатанна</th>
    <th>Махакам</th>
  </tr>
  <tr>
    <th>Социальный статус</th>
    <td>Терпимость</td>
    <td>Терпимость</td>
    <td>Терпимость</td>
    <td>Терпимость</td>
    <td>Равенство</td>
  </tr>
</table>$$),
        ('en',
$$<h1 style="color:#c8762b;">Werebbubbs</h1>
Werebbubbs are among the less humanoid Elder Races to be nearly destroyed by the Landing of the Exiles many centuries ago. Much like their vran counterparts, werebbubbs lived in the lowland valleys and mountainous foothills of the Continent, practicing age-old traditions, and seeking to live in relative harmony with the land around them. The werebbubbs were and still are a proud race with a long history of heroics and valor. In fact, instead of worshiping gods, werebbubbs worship the memories of their ancestors and the spirits of the legendary heroes and heroines. Werebbubbs are raised with stories of great warriors and wise sages who used their gifts to help their people and defeat terrifying enemies.
<h2 style="color:#c8762b;">Perks</h2>
<h3>🟡 Lionhearted</h3>
Werebbubbs are not the largest race on the continent but they are among the bravest. Their culture values heroism and young Werebbubbs hear tales of ancient ancestral heroes. Werebbubbs gain an inherent [+1 to Courage].
<h3>🟡 Strange Physiology</h3>
A werebbubb’s body and metabolism work in a manner entirely alien to humans and most other elder races. When grievously wounded, some aspect of a werebbubb’s physiology goes into high gear, often allowing them to survive wound that would quickly kill any other person. Whenever a werebbubb takes a Critical Wound, they can roll an Endurance check with a DC equal to the DC required to Stabilize the Critical Wound. If they succeed, the Critical Wound is immediately considered Stabilized. Players may only make this roll in the moment the werebbubb takes the wound and cannot be attempted again in the case of a failure.
<h3>🟡 Razor Teeth</h3>
While werebbubb don’t possess the powerful jaws and venomous fangs of the vran, their teeth are razor sharp and honed to a fine edge. A werebbubb can make a Melee attack with their fangs which deals 2d6 damage and has Improved Armor Piercing.
<h3>🟡 Poor Eyesight</h3>
In general, werebbubb suffer from poor eyesight. While their keen hearing allows them to navigate the world without any significant problems, they are far from the most perceptive race on the Continent. Werebbubbs take an inherent -4 on Awareness checks thanks to this poor vision. If a werebbubb is called on to make a perception check based only on hearing (such as hearing footsteps upstairs or listening for growling wolves) this penalty does not apply.

<h2 style="color:#c8762b;">Social Standing</h2>
<table>
  <tr>
    <th>Territory</th>
    <th>The North</th>
    <th>Nilfgaard</th>
    <th>Skellige</th>
    <th>Dol Blathanna</th>
    <th>Mahakam</th>
  </tr>
  <tr>
    <th>Social Standing</th>
    <td>Tolerated</td>
    <td>Tolerated</td>
    <td>Tolerated</td>
    <td>Tolerated</td>
    <td>Equal</td>
  </tr>
</table>$$)
      ) AS v(lang, text)
      CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT 'wcc_race_werebbubb'
     , meta.su_su_id
     , meta.qu_id
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(8, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label
     , 8 AS sort_order
     , (SELECT ru_id FROM rules WHERE ru_id = ck_id('witcher_cc.rules.is_dlc_exp_bot_enabled') LIMIT 1) AS visible_ru_ru_id
     , '{}'::jsonb AS metadata
  FROM meta;

-- Эффекты выбора расы: Баболак
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_race' AS qu_id
                , 'character' AS entity)
, ins_r_werebbubb AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'werebbubb' ||'.'|| meta.entity ||'.'|| 'race') AS id
       , meta.entity, 'race', v.lang, v.text
    FROM (VALUES
      ('ru', 'Баболак'),
      ('en', 'Werebbubb')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_werebbubb_f1 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'werebbubb' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '1') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Львиное Сердце</b>: врождённый бонус [+1 к Храбрости]'),
      ('en', '<b>Lionhearted</b>: inherent bonus [+1 to Courage]')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_werebbubb_f2 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'werebbubb' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '2') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Странная Физиология</b>: проверкой Стойкости сразу стабилизирует крит. рану (1 попытка на раненеие)'),
      ('en', '<b>Strange Physiology</b>: can make one immediate Endurance check to stabilize a Critical Wound (1 attempt per wound)')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_werebbubb_f3 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'werebbubb' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '3') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Зубы-бритвы</b>: атака зубами через Ближний бой с 2d6 смертельного урона и улучшенным пробиванием брони'),
      ('en', '<b>Razor Teeth</b>: melee attack with fangs for 2d6 lethal damage with Improved Armor Piercing')
    ) AS v(lang, text)
    CROSS JOIN meta
)
, ins_r_werebbubb_f4 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'werebbubb' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '4') AS id
       , meta.entity, 'perks', v.lang, v.text
    FROM (VALUES
      ('ru', '<b>Плохое зрение</b>: -4 к Вниманию с участием зрения'),
      ('en', '<b>Poor Eyesight</b>: -4 to Awareness checks involving vision')
    ) AS v(lang, text)
    CROSS JOIN meta
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_race_werebbubb',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.race'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'werebbubb' ||'.'|| meta.entity ||'.'|| 'race')::text)
    )
  )
FROM meta UNION ALL
SELECT
  'character' AS scope,
  'wcc_race_werebbubb' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.logicFields.race'),
      'Werebbubb'
    )
  ) AS body
UNION ALL
SELECT
  'character',
  'wcc_race_werebbubb',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'werebbubb' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '1')::text)
    )
  )
FROM meta
UNION ALL
SELECT
  'character',
  'wcc_race_werebbubb',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'werebbubb' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '2')::text)
    )
  )
FROM meta
UNION ALL
SELECT
  'character',
  'wcc_race_werebbubb',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'werebbubb' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '3')::text)
    )
  )
FROM meta
UNION ALL
SELECT
  'character',
  'wcc_race_werebbubb',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'werebbubb' ||'.'|| meta.entity ||'.'|| 'perks' ||'.'|| '4')::text)
    )
  )
FROM meta UNION ALL
-- Эффекты черт расы: Баболак - Львиное Сердце (+1 к Храбрости)
SELECT 'character', 'wcc_race_werebbubb',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.courage.race_bonus'),
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

-- Эффекты social_status для расы: Низушек
-- Север: Терпимость
-- Нильфгаард: Равенство
-- Скеллиге: Равенство
-- Доль Блатанна: Равенство
-- Махакам: Равенство
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_race_halfling',
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
SELECT 'character', 'wcc_race_halfling',
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
SELECT 'character', 'wcc_race_halfling',
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
SELECT 'character', 'wcc_race_halfling',
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
SELECT 'character', 'wcc_race_halfling',
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

-- Эффекты social_status для расы: Гном
-- Север: Терпимость
-- Нильфгаард: Равенство
-- Скеллиге: Равенство
-- Доль Блатанна: Равенство
-- Махакам: Равенство
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_race_gnome',
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
SELECT 'character', 'wcc_race_gnome',
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
SELECT 'character', 'wcc_race_gnome',
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
SELECT 'character', 'wcc_race_gnome',
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
SELECT 'character', 'wcc_race_gnome',
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

-- Эффекты social_status для расы: Вран
-- Север: Ненависть и Опасение
-- Нильфгаард: Терпимость и Опасение
-- Скеллиге: Ненависть и Опасение
-- Доль Блатанна: Ненависть
-- Махакам: Терпимость
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_race_vran',
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
SELECT 'character', 'wcc_race_vran',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.social_status'),
      jsonb_build_object(
        'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_race.territory.nilfgaard')::text),
        'group_status', 2,
        'group_is_feared', true
      )
    )
  )
UNION ALL
SELECT 'character', 'wcc_race_vran',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.social_status'),
      jsonb_build_object(
        'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_race.territory.skellige')::text),
        'group_status', 1,
        'group_is_feared', true
      )
    )
  )
UNION ALL
SELECT 'character', 'wcc_race_vran',
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
SELECT 'character', 'wcc_race_vran',
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

-- Эффекты social_status для расы: Баболак
-- Север: Терпимость
-- Нильфгаард: Терпимость
-- Скеллиге: Терпимость
-- Доль Блатанна: Терпимость
-- Махакам: Равенство
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_race_werebbubb',
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
SELECT 'character', 'wcc_race_werebbubb',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.social_status'),
      jsonb_build_object(
        'group_name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_race.territory.nilfgaard')::text),
        'group_status', 2,
        'group_is_feared', false
      )
    )
  )
UNION ALL
SELECT 'character', 'wcc_race_werebbubb',
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
SELECT 'character', 'wcc_race_werebbubb',
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
SELECT 'character', 'wcc_race_werebbubb',
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

-- Правила
INSERT INTO rules(name, body) VALUES ('is_elf', '{"==":[{"var":"characterRaw.logicFields.race"},"Elf"]}'::jsonb);
INSERT INTO rules(name, body) VALUES ('is_human', '{"==":[{"var":"characterRaw.logicFields.race"},"Human"]}'::jsonb);
INSERT INTO rules(name, body) VALUES ('is_dwarf', '{"==":[{"var":"characterRaw.logicFields.race"},"Dwarf"]}'::jsonb);
INSERT INTO rules(name, body) VALUES ('is_gnome', '{"==":[{"var":"characterRaw.logicFields.race"},"Gnome"]}'::jsonb);
INSERT INTO rules(name, body) VALUES ('is_halfling', '{"==":[{"var":"characterRaw.logicFields.race"},"Halfling"]}'::jsonb);
INSERT INTO rules(name, body) VALUES ('is_vran', '{"==":[{"var":"characterRaw.logicFields.race"},"Vran"]}'::jsonb);
INSERT INTO rules(name, body) VALUES ('is_werebbubb', '{"==":[{"var":"characterRaw.logicFields.race"},"Werebbubb"]}'::jsonb);
INSERT INTO rules(name, body) VALUES ('is_witcher', '{"==":[{"var":"characterRaw.logicFields.race"},"Witcher"]}'::jsonb);



