\echo '013_past_parents_fate.sql'
-- Узел: Судьба родителей (wcc_past_parents_fate)

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_parents_fate' AS qu_id
                , 'questions' AS entity
                , 'single'::question_type AS qtype)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| v.entity_field) AS id
           , meta.entity, v.entity_field, v.lang, v.text
        FROM (VALUES
                ('ru', 'Время понять, что случилось с вашими родителями.', 'body'),
                ('en', 'Time to determine what happened to your parents.', 'body')
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
             ck_id('witcher_cc.hierarchy.family')::text,
             ck_id('witcher_cc.hierarchy.parents_fate')::text
           )
         )
     FROM meta;


-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_parents_fate' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
    SELECT 'ru' AS lang, raw_data_ru.*
      FROM (VALUES
              -- group 1: Северянин
              (1, 'Один или оба ваших родителя погибли во время войны с Нильфгаардом. Скорее всего, это был отец, но мать также могла сражаться или стать жертвой войны.', 1),
              (2, 'Родители бросили вас в лесу. Возможно, семья не могла прокормить ещё один рот, а может, это была случайность.', 1),
              (3, 'Один или оба ваших родителя прокляты магом или кем-то, кто ненавидел их всей душой. Проклятие оказалось смертельным.', 1),
              (4, 'Родители продали вас за золото или обменяли на какие-то вещи или услуги. Похоже, золото было им нужнее, чем вы.', 1),
              (5, 'Один или оба ваших родителя вступили в банду. Вы часто встречались с членами той банды, а порой были вынуждены на неё работать.', 1),
              (6, 'Одного или обоих ваших родителей убило чудовище. Решите сами, что это была за тварь.', 1),
              (7, 'Одного или обоих ваших родителей казнили по ложному обвинению. То ли они стали козлами отпущения, то ли оказались не в том месте и не в то время.', 1),
              (8, 'Один или оба ваших родителя умерли от чумы. Болезнь была неизлечима, оставалось лишь облегчить страдания.', 1),
              (9, 'Один или оба ваших родителя дезертировали к нильфгаардцам, продав им информацию или просто перейдя границу.', 1),
              (10, 'Одного или обоих ваших родителя похитили аристократы. Скорее всего, это была ваша мать, приглянувшаяся местному князю или его сыну.', 1),

              -- group 2: Нильфгаардец
              (1, 'Ваш отец погиб в одной из Северных войн. Возможно, он уже был военным или же его призвали на службу, когда началась война.', 2),
              (2, 'Одного или обоих ваших родителей отравили. Возможно, это дело рук соперника или кого-то, кто хотел убрать их с пути.', 2),
              (3, 'Тайная полиция забрала кого-то из ваших родителей (или обоих) на допрос. Неделю спустя их тела нашли повешенными на городской улице.', 2),
              (4, 'Одного или обоих ваших родителей убил мятежный маг. Скорее всего, они пытались сдать этого мага Империи и поплатились за это.', 2),
              (5, 'Одного или обоих ваших родителей посадили за незаконное владение магией. Возможно, преступление действительно было, либо это была подстава.', 2),
              (6, 'Одного или обоих ваших родителей изгнали в пустыню Корат. Скорее всего, они совершили серьёзное преступление, но казнить их было опасно.', 2),
              (7, 'Одного или обоих ваших родителей проклял маг. Скорее всего, у мага была личная вендетта.', 2),
              (8, 'Однажды ваши родители просто оставили вас. Взяли и исчезли. Вероятно, вы не знаете причины.', 2),
              (9, 'Один или оба ваших родителя попали в рабство за преступление против Империи или по ложному доносу.', 2),
              (10, 'Одного или обоих ваших родителей отправили на Север в качестве двойных агентов. Вы, вероятно, даже не знаете, где они теперь, но они служат Императору.', 2),

              -- group 3: Нелюдь
              (1, 'Одного или обоих ваших родителей считают членами банды скоя''таэлей, из-за чего на них косо смотрят.', 3),
              (2, 'Один или оба ваших родителя предали свой народ и сдали членов Старших Народов людям, так что им не рады на родине.', 3),
              (3, 'Один или оба ваших родителя в отчаянии покончили с собой, утратив надежду на возвращение былой славы своего народа.', 3),
              (4, 'Во время странствий один или оба ваших родителя стали жертвами людского расизма. После погрома их тела выставили на пиках на всеобщее обозрение.', 3),
              (5, 'Один или оба ваших родителя одержимы восстановлением былой славы своего народа и жертвуют всем ради этой цели.', 3),
              (6, 'Одного или обоих ваших родителей изгнали с родины — за преступление, несогласие с мнением большинства или по какой-либо иной причине.', 3),
              (7, 'Одного или обоих ваших родителей прокляли. Выберите сами, что это за проклятие, или оставьте на усмотрение ведущего.', 3),
              (8, 'Ваши родители отдали вас другой семье, чтобы вы выжили, поскольку они не могли позаботиться о вас сами.', 3),
              (9, 'Один или оба ваших родителя вступили в ряды скоя''таэлей, чтобы отомстить людям, которые, как они считают, исковеркали им жизнь.', 3),
              (10, 'Один или оба ваших родителя погибли в результате «несчастного случая». Скорее всего, у них был могущественный враг, который наконец нашёл способ избавиться от них.', 3)
            ) AS raw_data_ru(num, text, group_id)
    UNION ALL
    SELECT 'en' AS lang, raw_data_en.*
      FROM (VALUES
              -- group 1: Northern
              (1, 'One or more of your parents were killed in the Northern Wars. Most likely your father, but it is also possible that your mother fought or was a casualty.', 1),
              (2, 'One or more of your parents left you in the wilderness to fend for yourself. Maybe they couldn''t afford to keep you; maybe you were an accident.', 1),
              (3, 'One or more of your parents were cursed by a mage or due to the intense hatred of someone they encountered. The curse took their life.', 1),
              (4, 'One or more of your parents sold you for coin, or perhaps traded you for some goods or service. Your parents needed the money more than you.', 1),
              (5, 'One or more of your parents joined a gang. You saw this gang often and were sometimes forced to work with them.', 1),
              (6, 'One or more of your parents were killed by monsters. It is your decision as to what they may have fallen prey to.', 1),
              (7, 'One or more of your parents were falsely executed. They may have been a scapegoat for something or just in the wrong place.', 1),
              (8, 'One or more of your parents died of a plague. There was nothing that could be done but try to ease their passing.', 1),
              (9, 'One or more of your parents defected to Nilfgaard. They may have been given a deal for information or they may just have jumped the border.', 1),
              (10, 'One or more of your parents were kidnapped by nobles. Likely it was your mother, who attracted the attention of a local lord or his son.', 1),

              -- group 2: Nilfgaardian
              (1, 'Your father died in one of the Northern Wars. He may have already been in the military or he may have been conscripted into service during that war.', 2),
              (2, 'One or more of your parents were poisoned. This may have been the work of a professional rival, or it may have been to get your parents out of the way.', 2),
              (3, 'The secret police took your parent or parents for ''questioning.'' The next week their bodies were found hung in the streets of the city.', 2),
              (4, 'One or more of your parents were killed by a rogue mage. Most likely they tried to turn the mage in question in to the Empire and paid the price.', 2),
              (5, 'One or more of your parents were imprisoned for unlawful magic. Maybe they actually committed the crime or maybe it was a setup.', 2),
              (6, 'One or more of your parents were exiled to the Korath Desert. Likely they committed a major crime but killing them would cause trouble.', 2),
              (7, 'One or more of your parents were cursed by a mage. The mage likely had a vendetta against them.', 2),
              (8, 'Your parents simply left you one day. You may not even know why they did it. One day your parents just disappeared.', 2),
              (9, 'One or more of your parents were enslaved. They either committed a crime against the Empire or were set up by a rival.', 2),
              (10, 'One or more of your parents were sent to the North as double agents. You likely don''t even know where they are now, but they''re serving the Emperor.', 2),

              -- group 3: Elderland (non-human)
              (1, 'One or more of your parents were accused of being Scoia''tael. The people around you give your parents sidelong glances.', 3),
              (2, 'One or more of your parents turned on your own people and sold out the elder races to the humans. Your parents are unwelcome in your homeland.', 3),
              (3, 'One or more of your parents killed themselves out of despair. With no hope of regaining the former glory of the past, they gave up and ended it.', 3),
              (4, 'While traveling, one or more of your parents fell prey to human racism. They died in a pogrom and their bodies were displayed on pikes.', 3),
              (5, 'One or more of your parents have become obsessed with regaining the former glory of their race. They sacrifice everything for this cause.', 3),
              (6, 'One or more of your parents were exiled from your homeland. There are many possible reasons, from crime to dissenting opinions.', 3),
              (7, 'One or more of your parents were cursed. You can decide what this curse is, or the Game Master can decide.', 3),
              (8, 'Your parents gave you to another family so that you could survive, because they couldn''t care for you.', 3),
              (9, 'One or more of your parents joined the Scoia''tael in an attempt to get revenge on the humans who they see as ruining their lives.', 3),
              (10, 'One or more of your parents died in an ''accident''. Most likely they made a powerful enemy that finally found a way to get rid of them.', 3)
           ) AS raw_data_en(num, text, group_id)
)
, ins_label AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*vals.group_id+vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
         , meta.entity, meta.entity_field, vals.lang, vals.text
      FROM vals
      CROSS JOIN meta
)
, rules_vals(group_id, body, name, id) AS (
  SELECT CASE name WHEN 'is_nordman' THEN 1
                   WHEN 'is_nilfgaardian' THEN 2
                   WHEN 'is_elderland' THEN 3 END
       , body, name, ru_id FROM rules WHERE name in ('is_nordman','is_nilfgaardian', 'is_elderland')
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id)
SELECT
  'wcc_past_parents_fate_o' || to_char(vals.group_id, 'FM00') || to_char(vals.num, 'FM00') AS an_id,
  meta.su_su_id,
  meta.qu_id,
  ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*vals.group_id+vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
  vals.num AS sort_order,
  rules_vals.id AS visible_ru_ru_id
FROM vals
CROSS JOIN meta
JOIN rules_vals ON rules_vals.group_id = vals.group_id
ON CONFLICT (an_id) DO NOTHING;

-- Эффекты для всех вариантов ответов
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_parents_fate' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
    SELECT 'ru' AS lang, raw_data_ru.*
      FROM (VALUES
              (1, 1), (2, 1), (3, 1), (4, 1), (5, 1), (6, 1), (7, 1), (8, 1), (9, 1), (10, 1),
              (1, 2), (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2), (8, 2), (9, 2), (10, 2),
              (1, 3), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (8, 3), (9, 3), (10, 3)
              ) AS raw_data_ru(num, group_id)
    UNION ALL
    SELECT 'en' AS lang, raw_data_en.*
      FROM (VALUES
              (1, 1), (2, 1), (3, 1), (4, 1), (5, 1), (6, 1), (7, 1), (8, 1), (9, 1), (10, 1),
              (1, 2), (2, 2), (3, 2), (4, 2), (5, 2), (6, 2), (7, 2), (8, 2), (9, 2), (10, 2),
              (1, 3), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (8, 3), (9, 3), (10, 3)
              ) AS raw_data_en(num, group_id)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_past_parents_fate_o' || to_char(vals.group_id, 'FM00') || to_char(vals.num, 'FM00'),
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.lore.parents_fate'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*vals.group_id+vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field)::text)
    )
  )
FROM vals
CROSS JOIN meta;

-- Связи  
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_past_parents', 'wcc_past_parents_fate', 'wcc_past_parents_o02', 1;