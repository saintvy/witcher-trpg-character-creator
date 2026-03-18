\echo '037_mage_events_danger.sql'

-- Hierarchy key
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.hierarchy.mage_events_danger'), 'hierarchy', 'path', 'ru', 'Реализация'),
  (ck_id('witcher_cc.hierarchy.mage_events_danger'), 'hierarchy', 'path', 'en', 'Realization')
ON CONFLICT (id, lang) DO NOTHING;

-- Visibility rules by selected danger type
INSERT INTO rules (ru_id, name, body)
VALUES
  (
    ck_id('witcher_cc.rules.is_mage_danger_cautious'),
    'is_mage_danger_cautious',
    '{
      "and": [
        { "==": [ { "var": "answers.lastAnswer.questionId" }, "wcc_mage_events_is_in_danger" ] },
        { "in": [ "wcc_mage_events_is_in_danger_o0102", { "var": "answers.lastAnswer.answerIds" } ] }
      ]
    }'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_mage_danger_politics'),
    'is_mage_danger_politics',
    '{
      "and": [
        { "==": [ { "var": "answers.lastAnswer.questionId" }, "wcc_mage_events_is_in_danger" ] },
        { "in": [ "wcc_mage_events_is_in_danger_o0202", { "var": "answers.lastAnswer.answerIds" } ] }
      ]
    }'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_mage_danger_study'),
    'is_mage_danger_study',
    '{
      "and": [
        { "==": [ { "var": "answers.lastAnswer.questionId" }, "wcc_mage_events_is_in_danger" ] },
        { "in": [ "wcc_mage_events_is_in_danger_o0302", { "var": "answers.lastAnswer.answerIds" } ] }
      ]
    }'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_mage_danger_experiments'),
    'is_mage_danger_experiments',
    '{
      "and": [
        { "==": [ { "var": "answers.lastAnswer.questionId" }, "wcc_mage_events_is_in_danger" ] },
        { "in": [ "wcc_mage_events_is_in_danger_o0402", { "var": "answers.lastAnswer.answerIds" } ] }
      ]
    }'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_mage_danger_cautious_mentor_friend'),
    'is_mage_danger_cautious_mentor_friend',
    '{
      "and": [
        { "==": [ { "var": "answers.lastAnswer.questionId" }, "wcc_mage_events_is_in_danger" ] },
        { "in": [ "wcc_mage_events_is_in_danger_o0102", { "var": "answers.lastAnswer.answerIds" } ] },
        { "!!": { "var": "characterRaw.lore.mentor.relationship_end" } }
      ]
    }'::jsonb
  )
ON CONFLICT (ru_id) DO UPDATE
SET name = EXCLUDED.name,
    body = EXCLUDED.body;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_mage_events_danger' AS qu_id
         , 'character' AS entity
  )
, ally_status_vals(lang, text) AS (
    VALUES
      ('ru', 'Погиб'),
      ('en', 'Was killed')
)
, traitor_cause_vals(kind, num, ru_text, en_text) AS (
    VALUES
      ('mage', 1, 'Вы обучались вместе, но вас предали', 'You studied together, but you were betrayed'),
      ('mage', 2, 'Вы спасли от несчастного случая, но вас предали', 'You saved them from an accident, but you were betrayed'),
      ('mage', 3, 'Вы поддержали в трудную минуту, но вас предали', 'You supported them in a hard time, but you were betrayed'),
      ('mage', 4, 'Вы помогли справиться с предательством, но вас предали', 'You helped them through a betrayal, but you were betrayed'),
      ('mage', 5, 'У вас была разовая интрижка, но вас предали', 'You were one-time romantic partners, but you were betrayed'),
      ('mage', 6, 'Вы собирались манипулировать, но вас предали', 'You set out to manipulate them, but you were betrayed'),
      ('mage', 7, 'Вы показали искреннюю доброту, но вас предали', 'You showed them genuine kindness, but you were betrayed'),
      ('mage', 8, 'Вы познакомились чтобы изучить, но вас предали', 'You set out to study them, but you were betrayed'),
      ('mage', 9, 'Вы помогли ударить кого-то в спину, но вас предали', 'You helped them backstab someone, but you were betrayed'),
      ('mage', 10, 'Вы были наказаны вместе, но вас предали', 'You were punished together, but you were betrayed'),
      ('mage', 11, 'Вы помогли укрыться этому магу-отступнику, но вас предали', 'You helped shelter this rogue mage, but you were betrayed'),
      ('witcher', 1, 'Вы его спасли от чего-то, но вас предали', 'You saved them from something, but you were betrayed'),
      ('witcher', 2, 'Вы встретились в таверне, но вас предали', 'You met in a tavern, but you were betrayed'),
      ('witcher', 3, 'Он вас от чего-то спас, но вас предали', 'They saved you from something, but you were betrayed'),
      ('witcher', 4, 'Он вас нанял, но вас предали', 'They hired you for something, but you were betrayed'),
      ('witcher', 5, 'Вы вместе попали в ловушку, но вас предали', 'You were trapped together, but you were betrayed'),
      ('witcher', 6, 'Вас заставили работать вместе, но вас предали', 'You were forced to work together, but you were betrayed'),
      ('witcher', 7, 'Вы его наняли, но вас предали', 'You hired them for something, but you were betrayed'),
      ('witcher', 8, 'Вы повстречались пьяными и сблизились, но вас предали', 'You met while drunk and hit it off, but you were betrayed'),
      ('witcher', 9, 'Вы встретились во время путешествий, но вас предали', 'You met while traveling, but you were betrayed'),
      ('witcher', 10, 'Вы вместе сражались, но вас предали', 'You fought together, but you were betrayed')
)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id(v2.key), meta.entity, v.entity_field, v.lang, v.text
FROM (
  SELECT 'common.ally_status.was_killed' AS key_suffix
       , 'ally_field' AS entity_field
       , ally_status_vals.lang
       , ally_status_vals.text
    FROM ally_status_vals

  UNION ALL

  SELECT meta.qu_id || '.traitor_cause_' || traitor_cause_vals.kind || '_' || to_char(traitor_cause_vals.num, 'FM00')
       , 'enemy_field'
       , 'ru'
       , traitor_cause_vals.ru_text
    FROM traitor_cause_vals
    CROSS JOIN meta

  UNION ALL

  SELECT meta.qu_id || '.traitor_cause_' || traitor_cause_vals.kind || '_' || to_char(traitor_cause_vals.num, 'FM00')
       , 'enemy_field'
       , 'en'
       , traitor_cause_vals.en_text
    FROM traitor_cause_vals
    CROSS JOIN meta
) AS v(key_suffix, entity_field, lang, text)
CROSS JOIN meta
CROSS JOIN LATERAL (VALUES (meta.su_su_id || '.' || v.key_suffix)) AS v2(key)
ON CONFLICT (id, lang) DO UPDATE
SET text = EXCLUDED.text;

-- Question
WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_mage_events_danger' AS qu_id
         , 'questions' AS entity
  )
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru', 'Определите, как именно реализовалась эта опасность.'),
        ('en', 'Determine how this danger manifested.')
      ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
)
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Реализация'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Manifestation')
)
, ins_cols AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.column_name') AS id
         , meta.entity, 'column_name', c_vals.lang, c_vals.text
      FROM c_vals
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
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
           ck_id('witcher_cc.hierarchy.mage_events_risk')::text,
           ck_id('witcher_cc.hierarchy.mage_events_danger')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO UPDATE
SET body = EXCLUDED.body,
    qtype = EXCLUDED.qtype,
    metadata = EXCLUDED.metadata;

-- Answers
WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_mage_events_danger' AS qu_id
         , 'answer_options' AS entity
         , 'label' AS entity_field
  )
, raw_data AS (
  SELECT 'ru' AS lang, v.*
    FROM (VALUES
      (1, 1, 0.1, '<b>Долг</b><br>За вами долг от 100 до 1000 крон.'),
      (1, 2, 0.1, '<b>Зависимость</b><br>У вас есть зависимость на ваш выбор:<br> - Алкоголь<br> - Табак<br> - Фисштех<br> - Азартные игры<br> - Клептомания<br> - Похоть<br> - Обжорство<br> - Адреналиновая зависимость<br> - Другое (можете придумать сами)'),
      (1, 3, 0.1, '<b>Болезнь</b><br>Вы заболели изнурительной болезнью. В конце концов, вы выздоровели, но выздоровление далось тяжело. Ваша Вын снижается на 2.'),
      (1, 4, 0.1, '<b>Разгневанные горожане</b><br>Это может быть что-то, что вы сделали (или чего не сделали), но вы разозлили жителей крупного города. Если вы вернетесь в этот город, горожане сразу увидят в вас угрозу или цель.'),
      (1, 5, 0.1, '<b>Несчастный случай</b><br>С вами произошел несчастный случай.'),
      (1, 6, 0.1, '<b>Заключение в тюрьму</b><br>Вас посадили в тюрьму на срок от 1 до 10 лет за то, что вы совершили (либо по ложному обвинению).'),
      (1, 7, 0.1, '<b>Смерть наставника</b><br>Если ваш наставник был еще жив, он умер в течение этого десятилетия. Если у вас не было наставника, вы можете перебросить этот результат. Вы и ведущий решаете, как он умер.'),
      (1, 8, 0.1, '<b>Выпадение волос</b><br>В результате неудачного заклинания все волосы на вашем теле выпали и отказываются расти обратно.'),
      (1, 9, 0.1, '<b>Артрит</b><br>Ваши руки не могут делать замысловатые жесты, необходимые для произнесения заклинаний без боли. Вы получаете штраф -1 к Сотворению заклинаний всякий раз, когда произносите заклинание, требующее движения рук.'),
      (1, 10, 0.1, '<b>Порча</b><br>На вас наложил порчу кто-то, кого вы раздражали или вы сами, своими руками.'),

      (2, 1, 0.1, '<b>Обида</b><br>Кто-то задел ваши чувства, или вы задели их. Тем не менее, один из вас держит обиду на это происшествие.'),
      (2, 2, 0.1, '<b>Ложное обвинение</b><br>Вас в чем-то ложно обвинили.'),
      (2, 3, 0.1, '<b>Предательство</b><br>Вас предал друг или знакомый. Имеющийся друг становится врагом.'),
      (2, 4, 0.1, '<b>Друг или возлюбленный(-ая) убит</b><br>Друг или возлюбленный(-ая) погиб(ла) в результате несчастного случая или, возможно, из-за заговора.'),
      (2, 5, 0.1, '<b>Поймали с поличным</b><br>Вас поймали на попытке манипулировать другими, заставляя их делать вашу грязную работу. Вы получаете врага, чья сила основывается на слугах.'),
      (2, 6, 0.1, '<b>Социальные оплошности</b><br>Вы совершили ужасную социальную оплошность на собрании магов, и теперь другие маги относятся к вам как к Терпимому, а не как к Равному.'),
      (2, 7, 0.1, '<b>Цель охоты</b><br>За вас назначена награда. Вас активно ищет группа от 6 до 11 охотников за головами.'),
      (2, 8, 0.1, '<b>Враг государства</b><br>Ваши политические планы были раскрыты, и вас заклеймили врагом нации, против которой вы замышляли заговор. Ваш статус Ненависть в этой стране независимо от вашего социального положения в этом регионе.'),
      (2, 9, 0.1, '<b>Соперник</b><br>Своими действиями вы сделали соперником другого члена вашей школы.'),
      (2, 10, 0.1, '<b>На службе у дворянина</b><br>Мелкий аристократ нанял вас за ваши магические способности и тайные знания. Каждый месяц вы получаете жалование в размере 100 крон. Тем не менее, вы должны немедленно отправляться к нему/ней, когда позовут вас, и выполнять любые поручения, которые он(а) потребуют от вас, иначе вы рискуете разозлить их.'),

      (3, 1, 0.1, '<b>Магическая блокировка</b><br>В своих исследованиях вы пренебрегали одним из элементов в пользу других. При произнесении заклинаний этого элемента вы получаете штраф -2 к проверке Сотворения заклинаний. Эффект стакается.'),
      (3, 2, 0.1, '<b>Встреча с монстром</b><br>Вы однажды чуть не умерли, когда изучали монстра. Теперь у вас есть фобия перед ним, а также получите -2 к проверкам Храбрости против него. Кроме того, вы должны пройти проверку Храбрости со СЛ 15, когда впервые столкнетесь с любым экземпляром этого существа, иначе будете ошеломлены.'),
      (3, 3, 0.1, '<b>Перегрузка с Местом силы</b><br>Вы нашли Место Силы, но по своей неопытности взяли слишком много энергии из него, и в процессе остались шрамы. Каждое Место Силы, из которого вы черпаете, требует пройти проверку Вын так, как если бы вы брали из него во второй раз.'),
      (3, 4, 0.1, '<b>Преследуется големом</b><br>В процессе учебы вам удалось перейти дорогу могущественному магу, который послал голема за вами. Теперь он ищет вас по всему континенту. Если он найдет вас, он попытается вас убить.'),
      (3, 5, 0.1, '<b>Громкая телепатия</b><br>Вы изучали заклинание телепатии. Вы пытались улучшить базовое заклинание телепатии, но результат оказался не таким, как вы ожидали. Когда вы телепатически шпионите за целью, вы не можете не издать низкое бормотание в ее голове, которое может насторожить ее. Любой, за кем вы шпионите, может пройти проверку Внимания.'),
      (3, 6, 0.1, '<b>Полиморфный</b><br>Вы провели десятилетие, будучи превращенными другим магом. Потребовалось много времени, чтобы найти способ обратиться обратно. Вы до сих пор сохранили некоторые манеры того существа. Вы получаете -2 к вашему Этикету.'),
      (3, 7, 0.1, '<b>Экстремальная уязвимость</b><br>Ты пытался сделать себя устойчивым к двимериту. Вы получили обратный результат. Вы получаете штраф -3 к проверкам Стойкости, чтобы сопротивляться эффектам двимерита.'),
      (3, 8, 0.1, '<b>Телепортационная болезнь</b><br>Вы испытываете телепортационную болезнь. Всякий раз, когда вы телепортируетесь или путешествуете через портал, вы должны пройти проверку Стойкости со СЛ 12, иначе вы будете страдать от тошноты в течение 10 минут.'),
      (3, 9, 0.1, '<b>Потеря чувств</b><br>Ваши эксперименты дорого вам обошлись. Вы потеряли чувство вкуса, обоняния или осязания. У вас есть штраф -2 к проверкам навыков, основанным на этом чувстве.'),
      (3, 10, 0.1, '<b>Мутация</b><br>Твои попытки понять мутагены привели к обратным результатам. Вы получаете физические изменения малой Мутации Мутагена по вашему выбору и изменения в социальном положении.'),

      (4, 1, 0.1, '<b>Перегрузка</b><br>Из-за своего высокомерия или своего невежества вы втянули в свое тело слишком много энергии и пострадали от последствий. Понизьте свои ПЗ на 2.'),
      (4, 2, 0.1, '<b>Встреча с демоном</b><br>В какой-то момент, будь то ваши собственные действия или действия сокурсника, вы вступили в контакт с демоном. Возможно, вы бежали или, возможно, боролись за свою жизнь, но в любом случае вы несете Люцифуг (печать, истинное имя) демона, и тот всегда знает, где вы находитесь.'),
      (4, 3, 0.1, '<b>Признан опасным</b><br>Что-то, что вы сделали, заклеймило вас как опасного для жителей королевства. В этом королевстве вас разыскивают власти.'),
      (4, 4, 0.1, '<b>Алхимическое происшествие</b><br>Вы смешали неправильные реагенты и пострадали от последствий. Вы получаете штраф -2 к Вын.'),
      (4, 5, 0.1, '<b>Старые шрамы</b><br>Один из ваших экспериментов привел к ужасным неприятным последствиям, исказив ваше лицо. Измените свое социальное положение на Опасение.'),
      (4, 6, 0.1, '<b>Магическая аллергия</b><br>У вас развилась аллергия на магию. Всякий раз, когда вы пьете зелье или эликсир, помимо стандартных эффектов, вы также страдаете от тошноты на время действия эликсира.'),
      (4, 7, 0.1, '<b>Опьянение</b><br>Вы попробовали на себе плохо приготовленную смесь, и она навсегда изменила ваш метаболизм. Когда вы пьете зелье или эликсир, вы должны сделать бросок 1d10 ниже своего Тел или будете опьяненны.'),
      (4, 8, 0.1, '<b>Алхимическая зависимость</b><br>Благодаря постоянному тестированию эликсиров и зелий у вас развилась зависимость от эликсиров. Это работает точно так же, как и любая другая зависимость.'),
      (4, 9, 0.1, '<b>Разыскивается охотниками</b><br>Вы сделали что-то настолько неосторожное и отвратительное своей магией, что церковь послала за вами пару охотников на ведьм (или охотников на магов в Нильфгаарде). Это враги, которые сделают все, чтобы подчинить или убить вас.'),
      (4, 10, 0.1, '<b>Проклят</b><br>Вы случайно прокляли себя, пытаясь понять действие проклятий.')
    ) AS v(group_id, option_id, probability, txt)

  UNION ALL

  SELECT 'en' AS lang, v.*
    FROM (VALUES
      (1, 1, 0.1, '<b>Debt</b><br>You owe between 100 and 1,000 crowns.'),
      (1, 2, 0.1, '<b>Addiction</b><br>You have an addiction of your choice:<br> - Alcohol<br> - Tobacco<br> - Fisstech<br> - Gambling<br> - Kleptomania<br> - Lust<br> - Gluttony<br> - Adrenaline Addiction<br> - Other (create your own)'),
      (1, 3, 0.1, '<b>Fell Ill</b><br>You fell ill from a wasting disease. You eventually recovered, but it left behind lasting fatigue. Lower your STA by 2.'),
      (1, 4, 0.1, '<b>Angered City Folk</b><br>It might be something you did (or something you did not do), but you have riled up the citizens of a major city. If you return to that city, the citizens will immediately see you as a threat or a target.'),
      (1, 5, 0.1, '<b>Accident</b><br>You suffered an accident.'),
      (1, 6, 0.1, '<b>Imprisonment</b><br>Something you did, or a false accusation, had you imprisoned for between 1 and 10 years.'),
      (1, 7, 0.1, '<b>Mentor Passed Away</b><br>If your mentor was still alive, they passed away during this decade. If you did not have a mentor, you can re-roll this result. It is up to you and the GM to determine how they died.'),
      (1, 8, 0.1, '<b>Hair Fell Out</b><br>A spell went awry and as a result, all of the hair on your body has fallen out and refuses to grow back.'),
      (1, 9, 0.1, '<b>Arthritis</b><br>Your hands have trouble making the intricate gestures required for spell casting without pain. You suffer a -1 penalty to your Spell Casting checks whenever you cast a spell that requires hand movement.'),
      (1, 10, 0.1, '<b>Hexed</b><br>You were hexed either by someone you irritated or by your own hand.'),

      (2, 1, 0.1, '<b>Grudge</b><br>Someone hurt your feelings, or you hurt theirs. Nevertheless, one of you is holding a grudge from this event.'),
      (2, 2, 0.1, '<b>False Accusation</b><br>You were falsely accused of something.'),
      (2, 3, 0.1, '<b>Betrayed</b><br>You were betrayed by a friend or acquaintance. One of your existing friends becomes an enemy.'),
      (2, 4, 0.1, '<b>Friend or Lover Killed</b><br>A friend or lover was killed in an accident or perhaps due to a scheme.'),
      (2, 5, 0.1, '<b>Caught Red Handed</b><br>You were caught attempting to manipulate others into doing your dirty work. You gain an enemy whose power is based on minions.'),
      (2, 6, 0.1, '<b>Social Faux Pas</b><br>You made a terrible social faux pas at a gathering of mages and are now treated as Tolerated by other mages instead of Equal.'),
      (2, 7, 0.1, '<b>Hunted</b><br>There are bounties out on you. A group of 6 to 11 bounty hunters is actively looking for you.'),
      (2, 8, 0.1, '<b>Enemy of the State</b><br>Your political schemes were discovered, and you have been branded the enemy of a nation you were conspiring against. You are Hated in that nation regardless of what your Social Standing is in that region.'),
      (2, 9, 0.1, '<b>Rival</b><br>Through your actions, you have made a rival of another school member.'),
      (2, 10, 0.1, '<b>Retained by a Noble</b><br>A minor noble hired you for your magical abilities and arcane knowledge. Each month, you gain a stipend of 100 crowns. However, you must go to them immediately whenever they summon you and perform any tasks they require of you, or risk angering them.'),

      (3, 1, 0.1, '<b>Magical Block</b><br>In your studies you neglected one of the elements in favor of others. When casting spells of that element, you take a -2 penalty to the Spell Casting check. This effect stacks.'),
      (3, 2, 0.1, '<b>Monster Encounter</b><br>You once nearly died while studying a monster. You now have a phobia of this creature and take a -2 penalty to Courage checks against it. Additionally, you must make a Courage check at DC 15 when first encountering any instance of this creature or be Staggered.'),
      (3, 3, 0.1, '<b>Overdrew from a Place of Power</b><br>You found a Place of Power, but in your inexperience over-drew from it and was permanently scarred in the process. Every Place of Power you draw from requires an Endurance save as if you were drawing from it a second time.'),
      (3, 4, 0.1, '<b>Hunted by a Golem</b><br>In your studies you managed to step on the toes of a powerful mage who sent a golem after you. It now seeks you out across the Continent. If it finds you it will try to destroy you.'),
      (3, 5, 0.1, '<b>Loud Telepathy</b><br>You learn the Telepathy Spell. You tried to improve upon the basic telepathy spell, but the result was not what you expected. When you spy telepathically on a target, you cannot help but emit a low mumble in their mind that may alert them. Anyone you spy upon can roll an Awareness check at a DC 15 to sense you.'),
      (3, 6, 0.1, '<b>Polymorphed</b><br>You spent the decade polymorphed by another mage. It took a long time to find a way to reverse it. To this day, you have kept some of the manners of that animal. You suffer a -2 to your Social Etiquette.'),
      (3, 7, 0.1, '<b>Extreme Vulnerability</b><br>You tried to make yourself resistant to dimeritium. You got the opposite result. You suffer a -3 penalty to your Endurance checks to resist the effects of dimeritium.'),
      (3, 8, 0.1, '<b>Teleportation Sickness</b><br>You experience teleportation sickness. Whenever you teleport or travel through a portal, you must make an Endurance check at a DC 12 or suffer from the Nausea condition for 10 minutes.'),
      (3, 9, 0.1, '<b>Lost a Sense</b><br>Your experiments have cost you much. You lost the sense of taste, smell or touch. You have a -2 penalty on skill checks that rely on that sense.'),
      (3, 10, 0.1, '<b>Mutation</b><br>Your attempts at understanding mutagens backfired. You gain the physical changes of a Minor Mutation of a Mutagen of your choice and the changes in Social Standing.'),

      (4, 1, 0.1, '<b>Overdraw</b><br>In your arrogance or your ignorance, you drew too much power into your body and suffered the consequences. Lower your Hit Points by 2.'),
      (4, 2, 0.1, '<b>Demonic Encounter</b><br>At some point, whether it was your own doing or the workings of a fellow student, you came in contact with a demon. You may have fled or perhaps you fought for your life, but either way you bear the demon''s lucifuge (seal, true name) and they always know where you are.'),
      (4, 3, 0.1, '<b>Deemed Dangerous</b><br>Something you did labeled you as dangerous to the people of a kingdom. In this kingdom you are wanted by the authorities.'),
      (4, 4, 0.1, '<b>Alchemical Incident</b><br>You mixed the wrong reagents and suffered consequences. You take a -2 penalty to STA.'),
      (4, 5, 0.1, '<b>Lasting Scars</b><br>One of your experiments backfired horrendously, deforming your face. Change your social standing to Feared.'),
      (4, 6, 0.1, '<b>Magical Allergy</b><br>You have developed an allergy to magic. Whenever you drink a potion or elixir, in addition to the standard effects, you also suffer from the Nausea condition for the duration of the elixir.'),
      (4, 7, 0.1, '<b>Intoxicated</b><br>You tried a poorly made concoction on yourself and it changed your metabolism forever. When drinking a potion or an elixir, you must roll beneath your BODY on 1d10 or become Intoxicated.'),
      (4, 8, 0.1, '<b>Alchemical Dependency</b><br>Through constant testing of elixirs and potions, you have developed an addiction to Elixirs. This works exactly the same as any other addiction.'),
      (4, 9, 0.1, '<b>Wanted by Hunters</b><br>You did something so careless and heinous with your magic that a church sent a pair of Witch Hunters (or Mage Hunters in Nilfgaard) after you. They are enemies that will do anything to subdue or kill you.'),
      (4, 10, 0.1, '<b>Cursed</b><br>You cursed yourself by accident while trying to understand curses.')
    ) AS v(group_id, option_id, probability, txt)
)
, vals AS (
  SELECT
    lang,
    meta.qu_id || '_o' || to_char(100 * raw_data.group_id + raw_data.option_id, 'FM0000') AS an_id,
    raw_data.option_id AS sort_order,
    probability,
    CASE raw_data.group_id
      WHEN 1 THEN CASE raw_data.option_id WHEN 7 THEN 'is_mage_danger_cautious_mentor_friend' ELSE 'is_mage_danger_cautious' END
      WHEN 2 THEN 'is_mage_danger_politics'
      WHEN 3 THEN 'is_mage_danger_study'
      WHEN 4 THEN 'is_mage_danger_experiments'
    END AS rule_name,
    '<td style="color: grey;">' || to_char(probability * 100, 'FM990.00') || '%</td><td>' || txt || '</td>' AS text
  FROM raw_data
  CROSS JOIN meta
)
, ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| vals.an_id ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
       , meta.entity, meta.entity_field, vals.lang, vals.text
    FROM vals
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO UPDATE
  SET text = EXCLUDED.text
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT vals.an_id
     , meta.su_su_id
     , meta.qu_id
     , ck_id(meta.su_su_id ||'.'|| vals.an_id ||'.'|| meta.entity ||'.'|| meta.entity_field)
     , vals.sort_order
     , (SELECT ru_id FROM rules WHERE name = vals.rule_name ORDER BY ru_id LIMIT 1)
     , jsonb_build_object('probability', vals.probability)
  FROM vals
 CROSS JOIN meta
 WHERE vals.lang = 'ru'
ON CONFLICT (an_id) DO UPDATE
SET label = EXCLUDED.label,
    sort_order = EXCLUDED.sort_order,
    visible_ru_ru_id = EXCLUDED.visible_ru_ru_id,
    metadata = EXCLUDED.metadata;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_mage_events_danger' AS qu_id
         , 'character' AS entity
         , 'event_desc' AS entity_field
  )
, event_type_vals(lang, text) AS (
    VALUES
      ('ru', 'Опасность'),
      ('en', 'Danger')
)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.life_event_type.danger') AS id
     , meta.entity
     , 'event_type'
     , event_type_vals.lang
     , event_type_vals.text
  FROM event_type_vals
  CROSS JOIN meta
ON CONFLICT (id, lang) DO UPDATE
SET text = EXCLUDED.text;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_mage_events_danger' AS qu_id
         , 'character' AS entity
         , 'event_desc' AS entity_field
  )
, event_desc_vals(group_id, option_id, ru_text, en_text) AS (
    VALUES
      (1, 3, 'Болезнь.', 'Fell ill.'),
      (1, 7, 'Смерть наставника.', 'Mentor passed away.'),
      (1, 8, 'Выпадение волос.', 'Hair fell out.'),
      (1, 9, 'Артрит.', 'Arthritis.'),

      (2, 1, 'Обида.', 'Grudge.'),
      (2, 3, 'Предательство.', 'Betrayed.'),
      (2, 4, 'Друг или возлюбленный(-ая) убит(а).', 'Friend or lover killed.'),
      (2, 5, 'Поймали с поличным.', 'Caught red-handed.'),
      (2, 6, 'Социальные оплошности.', 'Social faux pas.'),
      (2, 9, 'Соперник.', 'Rival.'),
      (2, 10, 'На службе у дворянина.', 'Retained by a noble.'),

      (3, 3, 'Перегрузка с Местом силы.', 'Overdrew from a Place of Power.'),
      (3, 4, 'Преследуется големом.', 'Hunted by a golem.'),
      (3, 5, 'Громкая телепатия.', 'Loud telepathy.'),
      (3, 6, 'Полиморфный.', 'Polymorphed.'),
      (3, 7, 'Экстремальная уязвимость.', 'Extreme vulnerability.'),
      (3, 8, 'Телепортационная болезнь.', 'Teleportation sickness.'),

      (4, 1, 'Перегрузка.', 'Overdraw.'),
      (4, 2, 'Встреча с демоном.', 'Demonic encounter.'),
      (4, 4, 'Алхимическое происшествие.', 'Alchemical incident.'),
      (4, 5, 'Старые шрамы.', 'Lasting scars.'),
      (4, 6, 'Магическая аллергия.', 'Magical allergy.'),
      (4, 7, 'Опьянение.', 'Intoxicated.'),
      (4, 8, 'Алхимическая зависимость.', 'Alchemical dependency.'),
      (4, 9, 'Разыскивается охотниками.', 'Wanted by hunters.')
)
, vals(lang, group_id, option_id, text) AS (
    SELECT 'ru', group_id, option_id, ru_text FROM event_desc_vals
    UNION ALL
    SELECT 'en', group_id, option_id, en_text FROM event_desc_vals
)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100 * vals.group_id + vals.option_id, 'FM0000') ||'.'|| meta.entity_field) AS id
     , meta.entity
     , meta.entity_field
     , vals.lang
     , vals.text
  FROM vals
  CROSS JOIN meta
ON CONFLICT (id, lang) DO UPDATE
SET text = EXCLUDED.text;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_mage_events_danger' AS qu_id
  )
, i18n_vals(key_suffix, entity, entity_field, lang, text) AS (
    VALUES
      ('enemy_position_golem', 'character', 'enemy_field', 'ru', 'Голем'),
      ('enemy_position_golem', 'character', 'enemy_field', 'en', 'Golem'),
      ('enemy_cause_crossed_powerful_mage', 'character', 'enemy_field', 'ru', 'Перешел дорогу могущественному магу'),
      ('enemy_cause_crossed_powerful_mage', 'character', 'enemy_field', 'en', 'Crossed a powerful mage'),
      ('enemy_how_far_relentless_hunt', 'character', 'enemy_field', 'ru', 'Неустанно преследует вас, чтобы убить'),
      ('enemy_how_far_relentless_hunt', 'character', 'enemy_field', 'en', 'Relentlessly hunts you down to kill you'),

      ('disease_loud_telepathy_name', 'character', 'disease', 'ru', 'Громкая телепатия'),
      ('disease_loud_telepathy_name', 'character', 'disease', 'en', 'Loud Telepathy'),
      ('disease_loud_telepathy_desc', 'character', 'disease', 'ru', 'Ваша цель слышит бормотание в голове при телепатической слежке. Пройдя проверку Внимания СЛ15, она почувствует слежку.'),
      ('disease_loud_telepathy_desc', 'character', 'disease', 'en', 'Your target hears muttering in their head when you spy on them telepathically. Passing an Awareness check at DC 15 lets them sense the surveillance.'),

      ('disease_extreme_vulnerability_name', 'character', 'disease', 'ru', 'Экстремальная уязвимость'),
      ('disease_extreme_vulnerability_name', 'character', 'disease', 'en', 'Extreme Vulnerability'),
      ('disease_extreme_vulnerability_desc', 'character', 'disease', 'ru', 'Штраф -3 к проверкам Стойкости при сопротивлении эффектам двимерита.'),
      ('disease_extreme_vulnerability_desc', 'character', 'disease', 'en', 'You suffer a -3 penalty to Endurance checks when resisting dimeritium effects.'),
      ('disease_teleportation_sickness_name', 'character', 'disease', 'ru', 'Телепортационная болезнь'),
      ('disease_teleportation_sickness_name', 'character', 'disease', 'en', 'Teleportation Sickness'),
      ('disease_teleportation_sickness_desc', 'character', 'disease', 'ru', 'После телепортации или прохода через портал вы 10 минут испытываете тошноту при провале Стойкости со СЛ12.'),
      ('disease_teleportation_sickness_desc', 'character', 'disease', 'en', 'After teleporting or passing through a portal, you suffer nausea for 10 minutes if you fail an Endurance check at DC 12.'),

      ('disease_magical_allergy_name', 'character', 'disease', 'ru', 'Магическая аллергия'),
      ('disease_magical_allergy_name', 'character', 'disease', 'en', 'Magical Allergy'),
      ('disease_magical_allergy_desc', 'character', 'disease', 'ru', 'Вы страдаете от тошноты на время действия выпитого зелья или эликсира.'),
      ('disease_magical_allergy_desc', 'character', 'disease', 'en', 'You suffer nausea for the duration of any potion or elixir you drink.'),

      ('disease_intoxicated_name', 'character', 'disease', 'ru', 'Одурманенный'),
      ('disease_intoxicated_name', 'character', 'disease', 'en', 'Intoxicated'),
      ('disease_intoxicated_desc', 'character', 'disease', 'ru', 'Выпивая эликсир или зелье, вы получаете опьянение при броске 1d10 выше вашего Тел.'),
      ('disease_intoxicated_desc', 'character', 'disease', 'en', 'When you drink a potion or elixir, you become intoxicated on a 1d10 roll higher than your BODY.'),

      ('addiction_potions_elixirs_desc', 'character', 'disease', 'ru', 'Зависимость: Зелья и эликсиры.'),
      ('addiction_potions_elixirs_desc', 'character', 'disease', 'en', 'Addiction: Potions and elixirs.')
)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| i18n_vals.key_suffix)
     , i18n_vals.entity
     , i18n_vals.entity_field
     , i18n_vals.lang
     , i18n_vals.text
  FROM i18n_vals
 CROSS JOIN meta
ON CONFLICT (id, lang) DO UPDATE
SET text = EXCLUDED.text;

-- Effects: remember selected danger outcomes for downstream branches
WITH effect_vals(an_id, marker) AS (
  VALUES
    ('wcc_mage_events_danger_o0102', 'life events 1-2'),
    ('wcc_mage_events_danger_o0201', 'life events 2-1'),
    ('wcc_mage_events_danger_o0203', 'life events 2-3'),
    ('wcc_mage_events_danger_o0204', 'life events 2-4'),
    ('wcc_mage_events_danger_o0205', 'life events 2-5'),
    ('wcc_mage_events_danger_o0209', 'life events 2-9'),
    ('wcc_mage_events_danger_o0410', 'life events 4-10')
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  effect_vals.an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.logicFields.last_node_and_answer'),
      effect_vals.marker
    )
  )
FROM effect_vals;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_mage_events_danger' AS qu_id
  )
, event_effects(group_id, option_id) AS (
    VALUES
      (1, 3), (1, 7), (1, 8), (1, 9),
      (2, 1), (2, 3), (2, 4), (2, 5), (2, 6), (2, 9), (2, 10),
      (3, 3), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8),
      (4, 1), (4, 2), (4, 4), (4, 5), (4, 6), (4, 7), (4, 8), (4, 9)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  meta.qu_id || '_o' || to_char(100 * event_effects.group_id + event_effects.option_id, 'FM0000'),
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.lifeEvents'),
      jsonb_build_object(
        'timePeriod',
        jsonb_build_object(
          'jsonlogic_expression',
          jsonb_build_object(
            'cat',
            jsonb_build_array(
              jsonb_build_object('var', 'counters.lifeEventsCounter'),
              '-',
              jsonb_build_object(
                '+',
                jsonb_build_array(
                  jsonb_build_object('var', 'counters.lifeEventsCounter'),
                  10
                )
              )
            )
          )
        ),
        'eventType',
        jsonb_build_object(
          'i18n_uuid',
          ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.life_event_type.danger')::text
        ),
        'description',
        jsonb_build_object(
          'i18n_uuid',
          ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100 * event_effects.group_id + event_effects.option_id, 'FM0000') ||'.event_desc')::text
        )
      )
    )
  )
FROM event_effects
CROSS JOIN meta;

INSERT INTO effects (scope, an_an_id, body)
VALUES
  ('character', 'wcc_mage_events_danger_o0203', '{"make_a_traitor": true}'::jsonb),
  ('character', 'wcc_mage_events_danger_o0204', '{"kill_a_friend": true}'::jsonb);

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_mage_events_danger' AS qu_id
  )
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character'
     , meta.qu_id || '_o0103'
     , jsonb_build_object(
         'inc',
         jsonb_build_array(
           jsonb_build_object('var', 'characterRaw.skills.common.endurance.bonus'),
           -2
         )
       )
  FROM meta
UNION ALL
SELECT 'character'
     , meta.qu_id || '_o0107'
     , jsonb_build_object(
         'set',
         jsonb_build_array(
           jsonb_build_object('var', 'characterRaw.lore.mentor.is_alive'),
           jsonb_build_object(
             'i18n_uuid',
             ck_id(meta.su_su_id ||'.wcc_past_mentor_relationship_end.mentor.is_alive.dead')::text
           )
         )
       )
  FROM meta
UNION ALL
SELECT 'character'
     , meta.qu_id || '_o0304'
     , jsonb_build_object(
         'add',
         jsonb_build_array(
           jsonb_build_object('var', 'characterRaw.enemies'),
           jsonb_build_object(
             'gender', '',
             'victim', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_enemy_victim_o0002.answer_options.label_value')::text),
             'position', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.enemy_position_golem')::text),
             'cause', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.enemy_cause_crossed_powerful_mage')::text),
             'power_level', '',
             'how_far', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.enemy_how_far_relentless_hunt')::text),
             'the_power', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_enemy_the_power_o0003.answer_options.label_value')::text)
           )
         )
       )
  FROM meta
UNION ALL
SELECT 'character'
     , meta.qu_id || '_o0305'
     , jsonb_build_object(
         'add_unique',
         jsonb_build_array(
           jsonb_build_object('var', 'characterRaw.lore.diseases_and_curses'),
           jsonb_build_object(
             'name', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.disease_loud_telepathy_name')::text),
             'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.disease_loud_telepathy_desc')::text)
           )
         )
       )
  FROM meta
UNION ALL
SELECT 'character'
     , meta.qu_id || '_o0306'
     , jsonb_build_object(
         'inc',
         jsonb_build_array(
           jsonb_build_object('var', 'characterRaw.skills.common.social_etiquette.bonus'),
           -2
         )
       )
  FROM meta
UNION ALL
SELECT 'character'
     , meta.qu_id || '_o0307'
     , jsonb_build_object(
         'add_unique',
         jsonb_build_array(
           jsonb_build_object('var', 'characterRaw.lore.diseases_and_curses'),
           jsonb_build_object(
             'name', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.disease_extreme_vulnerability_name')::text),
             'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.disease_extreme_vulnerability_desc')::text)
           )
         )
       )
  FROM meta
UNION ALL
SELECT 'character'
     , meta.qu_id || '_o0308'
     , jsonb_build_object(
         'add_unique',
         jsonb_build_array(
           jsonb_build_object('var', 'characterRaw.lore.diseases_and_curses'),
           jsonb_build_object(
             'name', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.disease_teleportation_sickness_name')::text),
             'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.disease_teleportation_sickness_desc')::text)
           )
         )
       )
  FROM meta
UNION ALL
SELECT 'character'
     , meta.qu_id || '_o0401'
     , jsonb_build_object(
         'inc',
         jsonb_build_array(
           jsonb_build_object('var', 'characterRaw.statistics.calculated.max_HP.bonus'),
           -2
         )
       )
  FROM meta
UNION ALL
SELECT 'character'
     , meta.qu_id || '_o0404'
     , jsonb_build_object(
         'inc',
         jsonb_build_array(
           jsonb_build_object('var', 'characterRaw.skills.common.endurance.bonus'),
           -2
         )
       )
  FROM meta
UNION ALL
SELECT 'character'
     , meta.qu_id || '_o0406'
     , jsonb_build_object(
         'add_unique',
         jsonb_build_array(
           jsonb_build_object('var', 'characterRaw.lore.diseases_and_curses'),
           jsonb_build_object(
             'name', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.disease_magical_allergy_name')::text),
             'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.disease_magical_allergy_desc')::text)
           )
         )
       )
  FROM meta
UNION ALL
SELECT 'character'
     , meta.qu_id || '_o0407'
     , jsonb_build_object(
         'add_unique',
         jsonb_build_array(
           jsonb_build_object('var', 'characterRaw.lore.diseases_and_curses'),
           jsonb_build_object(
             'name', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.disease_intoxicated_name')::text),
             'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.disease_intoxicated_desc')::text)
           )
         )
       )
  FROM meta
UNION ALL
SELECT 'character'
     , meta.qu_id || '_o0408'
     , jsonb_build_object(
         'add_unique',
         jsonb_build_array(
           jsonb_build_object('var', 'characterRaw.lore.diseases_and_curses'),
           jsonb_build_object(
             'type', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_life_events_fortune_or_not_details.disease_type_addiction')::text),
             'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.addiction_potions_elixirs_desc')::text)
           )
         )
       )
  FROM meta
UNION ALL
SELECT 'character'
     , meta.qu_id || '_o0108'
     , jsonb_build_object(
         'set',
         jsonb_build_array(
           jsonb_build_object('var', 'characterRaw.lore.style.hair_style'),
           jsonb_build_object(
             'i18n_uuid',
             ck_id(meta.su_su_id ||'.wcc_style_hair_o0006.answer_options.label')::text
           )
         )
       )
  FROM meta;
