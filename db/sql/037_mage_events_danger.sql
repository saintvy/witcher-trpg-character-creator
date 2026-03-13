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
        {
          "or": [
            { "!!": { "var": "answers.byAnswer.wcc_past_mentor_relationship_end_o03" } },
            { "!!": { "var": "answers.byAnswer.wcc_past_mentor_relationship_end_o04" } },
            { "!!": { "var": "answers.byAnswer.wcc_past_mentor_relationship_end_o05" } },
            { "!!": { "var": "answers.byAnswer.wcc_past_mentor_relationship_end_o06" } },
            { "!!": { "var": "answers.byAnswer.wcc_past_mentor_relationship_end_o07" } },
            { "!!": { "var": "answers.byAnswer.wcc_past_mentor_relationship_end_o08" } }
          ]
        }
      ]
    }'::jsonb
  )
ON CONFLICT (ru_id) DO UPDATE
SET name = EXCLUDED.name,
    body = EXCLUDED.body;

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
      ('wcc_mage_events_danger_o0101', 1, 0.1::numeric, 'is_mage_danger_cautious', '<b>Долг</b><br>За вами долг от 100 до 1000 крон.'),
      ('wcc_mage_events_danger_o0102', 2, 0.1::numeric, 'is_mage_danger_cautious', '<b>Зависимость</b><br>У вас есть зависимость на ваш выбор:<br> - Алкоголь<br> - Табак<br> - Фисштех<br> - Азартные игры<br> - Клептомания<br> - Похоть<br> - Обжорство<br> - Адреналиновая зависимость<br> - Другое (можете придумать сами)'),
      ('wcc_mage_events_danger_o0103', 3, 0.1::numeric, 'is_mage_danger_cautious', '<b>Болезнь</b><br>Вы заболели изнурительной болезнью. В конце концов, вы выздоровели, но выздоровление далось тяжело. Ваша Вын снижается на 2.'),
      ('wcc_mage_events_danger_o0104', 4, 0.1::numeric, 'is_mage_danger_cautious', '<b>Разгневанные горожане</b><br>Это может быть что-то, что вы сделали (или чего не сделали), но вы разозлили жителей крупного города. Если вы вернетесь в этот город, горожане сразу увидят в вас угрозу или цель.'),
      ('wcc_mage_events_danger_o0105', 5, 0.1::numeric, 'is_mage_danger_cautious', '<b>Несчастный случай</b><br>С вами произошел несчастный случай.'),
      ('wcc_mage_events_danger_o0106', 6, 0.1::numeric, 'is_mage_danger_cautious', '<b>Заключение в тюрьму</b><br>Вас посадили в тюрьму на срок от 1 до 10 лет за то, что вы совершили (либо по ложному обвинению).'),
      ('wcc_mage_events_danger_o0107', 7, 0.1::numeric, 'is_mage_danger_cautious_mentor_friend', '<b>Смерть наставника</b><br>Если ваш наставник был еще жив, он умер в течение этого десятилетия. Если у вас не было наставника, вы можете перебросить этот результат. Вы и ведущий решаете, как он умер.'),
      ('wcc_mage_events_danger_o0108', 8, 0.1::numeric, 'is_mage_danger_cautious', '<b>Выпадение волос</b><br>В результате неудачного заклинания все волосы на вашем теле выпали и отказываются расти обратно.'),
      ('wcc_mage_events_danger_o0109', 9, 0.1::numeric, 'is_mage_danger_cautious', '<b>Артрит</b><br>Ваши руки не могут делать замысловатые жесты, необходимые для произнесения заклинаний без боли. Вы получаете штраф -1 к Сотворению заклинаний всякий раз, когда произносите заклинание, требующее движения рук.'),
      ('wcc_mage_events_danger_o0110', 10, 0.1::numeric, 'is_mage_danger_cautious', '<b>Порча</b><br>На вас наложил порчу кто-то, кого вы раздражали или вы сами, своими руками.'),

      ('wcc_mage_events_danger_o0201', 1, 0.1::numeric, 'is_mage_danger_politics', '<b>Обида</b><br>Кто-то задел ваши чувства, или вы задели их. Тем не менее, один из вас держит обиду на это происшествие.'),
      ('wcc_mage_events_danger_o0202', 2, 0.1::numeric, 'is_mage_danger_politics', '<b>Ложное обвинение</b><br>Вас в чем-то ложно обвинили.'),
      ('wcc_mage_events_danger_o0203', 3, 0.1::numeric, 'is_mage_danger_politics', '<b>Предательство</b><br>Вас предал друг или знакомый. Имеющийся друг становится врагом.'),
      ('wcc_mage_events_danger_o0204', 4, 0.1::numeric, 'is_mage_danger_politics', '<b>Друг или возлюбленный(-ая) убит</b><br>Друг или возлюбленный(-ая) погиб(ла) в результате несчастного случая или, возможно, из-за заговора.'),
      ('wcc_mage_events_danger_o0205', 5, 0.1::numeric, 'is_mage_danger_politics', '<b>Поймали с поличным</b><br>Вас поймали на попытке манипулировать другими, заставляя их делать вашу грязную работу. Вы получаете врага, чья сила основывается на слугах.'),
      ('wcc_mage_events_danger_o0206', 6, 0.1::numeric, 'is_mage_danger_politics', '<b>Социальные оплошности</b><br>Вы совершили ужасную социальную оплошность на собрании магов, и теперь другие маги относятся к вам как к Терпимому, а не как к Равному.'),
      ('wcc_mage_events_danger_o0207', 7, 0.1::numeric, 'is_mage_danger_politics', '<b>Цель охоты</b><br>За вас назначена награда. Вас активно ищет группа от 6 до 11 охотников за головами.'),
      ('wcc_mage_events_danger_o0208', 8, 0.1::numeric, 'is_mage_danger_politics', '<b>Враг государства</b><br>Ваши политические планы были раскрыты, и вас заклеймили врагом нации, против которой вы замышляли заговор. Ваш статус Ненависть в этой стране независимо от вашего социального положения в этом регионе.'),
      ('wcc_mage_events_danger_o0209', 9, 0.1::numeric, 'is_mage_danger_politics', '<b>Соперник</b><br>Своими действиями вы сделали соперником другого члена вашей школы.'),
      ('wcc_mage_events_danger_o0210', 10, 0.1::numeric, 'is_mage_danger_politics', '<b>На службе у дворянина</b><br>Мелкий аристократ нанял вас за ваши магические способности и тайные знания. Каждый месяц вы получаете жалование в размере 100 крон. Тем не менее, вы должны немедленно отправляться к нему/ней, когда позовут вас, и выполнять любые поручения, которые он(а) потребуют от вас, иначе вы рискуете разозлить их.'),

      ('wcc_mage_events_danger_o0301', 1, 0.1::numeric, 'is_mage_danger_study', '<b>Магическая блокировка</b><br>В своих исследованиях вы пренебрегали одним из элементов в пользу других. При произнесении заклинаний этого элемента вы получаете штраф -2 к проверке Сотворения заклинаний. Эффект стакается.'),
      ('wcc_mage_events_danger_o0302', 2, 0.1::numeric, 'is_mage_danger_study', '<b>Встреча с монстром</b><br>Вы однажды чуть не умерли, когда изучали монстра. Теперь у вас есть фобия перед ним, а также получите -2 к проверкам Храбрости против него. Кроме того, вы должны пройти проверку Храбрости со СЛ 15, когда впервые столкнетесь с любым экземпляром этого существа, иначе будете ошеломлены.'),
      ('wcc_mage_events_danger_o0303', 3, 0.1::numeric, 'is_mage_danger_study', '<b>Перегрузка с Местом силы</b><br>Вы нашли Место Силы, но по своей неопытности взяли слишком много энергии из него, и в процессе остались шрамы. Каждое Место Силы, из которого вы черпаете, требует пройти проверку Вын так, как если бы вы брали из него во второй раз.'),
      ('wcc_mage_events_danger_o0304', 4, 0.1::numeric, 'is_mage_danger_study', '<b>Преследуется големом</b><br>В процессе учебы вам удалось перейти дорогу могущественному магу, который послал голема за вами. Теперь он ищет вас по всему континенту. Если он найдет вас, он попытается вас убить.'),
      ('wcc_mage_events_danger_o0305', 5, 0.1::numeric, 'is_mage_danger_study', '<b>Громкая телепатия</b><br>Вы изучали заклинание телепатии. Вы пытались улучшить базовое заклинание телепатии, но результат оказался не таким, как вы ожидали. Когда вы телепатически шпионите за целью, вы не можете не издать низкое бормотание в ее голове, которое может насторожить ее. Любой, за кем вы шпионите, может пройти проверку Внимания.'),
      ('wcc_mage_events_danger_o0306', 6, 0.1::numeric, 'is_mage_danger_study', '<b>Полиморфный</b><br>Вы провели десятилетие, будучи превращенными другим магом. Потребовалось много времени, чтобы найти способ обратиться обратно. Вы до сих пор сохранили некоторые манеры того существа. Вы получаете -2 к вашему Этикету.'),
      ('wcc_mage_events_danger_o0307', 7, 0.1::numeric, 'is_mage_danger_study', '<b>Экстремальная уязвимость</b><br>Ты пытался сделать себя устойчивым к двимериту. Вы получили обратный результат. Вы получаете штраф -3 к проверкам Стойкости, чтобы сопротивляться эффектам двимерита.'),
      ('wcc_mage_events_danger_o0308', 8, 0.1::numeric, 'is_mage_danger_study', '<b>Телепортационная болезнь</b><br>Вы испытываете телепортационную болезнь. Всякий раз, когда вы телепортируетесь или путешествуете через портал, вы должны пройти проверку Стойкости со СЛ 12, иначе вы будете страдать от тошноты в течение 10 минут.'),
      ('wcc_mage_events_danger_o0309', 9, 0.1::numeric, 'is_mage_danger_study', '<b>Потеря чувств</b><br>Ваши эксперименты дорого вам обошлись. Вы потеряли чувство вкуса, обоняния или осязания. У вас есть штраф -2 к проверкам навыков, основанным на этом чувстве.'),
      ('wcc_mage_events_danger_o0310', 10, 0.1::numeric, 'is_mage_danger_study', '<b>Мутация</b><br>Твои попытки понять мутагены привели к обратным результатам. Вы получаете физические изменения малой Мутации Мутагена по вашему выбору и изменения в социальном положении.'),

      ('wcc_mage_events_danger_o0401', 1, 0.1::numeric, 'is_mage_danger_experiments', '<b>Перегрузка</b><br>Из-за своего высокомерия или своего невежества вы втянули в свое тело слишком много энергии и пострадали от последствий. Понизьте свои ПЗ на 2.'),
      ('wcc_mage_events_danger_o0402', 2, 0.1::numeric, 'is_mage_danger_experiments', '<b>Встреча с демоном</b><br>В какой-то момент, будь то ваши собственные действия или действия сокурсника, вы вступили в контакт с демоном. Возможно, вы бежали или, возможно, боролись за свою жизнь, но в любом случае вы несете Люцифуг (печать, истинное имя) демона, и тот всегда знает, где вы находитесь.'),
      ('wcc_mage_events_danger_o0403', 3, 0.1::numeric, 'is_mage_danger_experiments', '<b>Признан опасным</b><br>Что-то, что вы сделали, заклеймило вас как опасного для жителей королевства. В этом королевстве вас разыскивают власти.'),
      ('wcc_mage_events_danger_o0404', 4, 0.1::numeric, 'is_mage_danger_experiments', '<b>Алхимическое происшествие</b><br>Вы смешали неправильные реагенты и пострадали от последствий. Вы получаете штраф -2 к Вын.'),
      ('wcc_mage_events_danger_o0405', 5, 0.1::numeric, 'is_mage_danger_experiments', '<b>Старые шрамы</b><br>Один из ваших экспериментов привел к ужасным неприятным последствиям, исказив ваше лицо. Измените свое социальное положение на Опасение.'),
      ('wcc_mage_events_danger_o0406', 6, 0.1::numeric, 'is_mage_danger_experiments', '<b>Магическая аллергия</b><br>У вас развилась аллергия на магию. Всякий раз, когда вы пьете зелье или эликсир, помимо стандартных эффектов, вы также страдаете от тошноты на время действия эликсира.'),
      ('wcc_mage_events_danger_o0407', 7, 0.1::numeric, 'is_mage_danger_experiments', '<b>Опьянение</b><br>Вы попробовали на себе плохо приготовленную смесь, и она навсегда изменила ваш метаболизм. Когда вы пьете зелье или эликсир, вы должны сделать бросок 1d10 ниже своего Тел или будете опьяненны.'),
      ('wcc_mage_events_danger_o0408', 8, 0.1::numeric, 'is_mage_danger_experiments', '<b>Алхимическая зависимость</b><br>Благодаря постоянному тестированию эликсиров и зелий у вас развилась зависимость от эликсиров. Это работает точно так же, как и любая другая зависимость.'),
      ('wcc_mage_events_danger_o0409', 9, 0.1::numeric, 'is_mage_danger_experiments', '<b>Разыскивается охотниками</b><br>Вы сделали что-то настолько неосторожное и отвратительное своей магией, что церковь послала за вами пару охотников на ведьм (или охотников на магов в Нильфгаарде). Это враги, которые сделают все, чтобы подчинить или убить вас.'),
      ('wcc_mage_events_danger_o0410', 10, 0.1::numeric, 'is_mage_danger_experiments', '<b>Проклят</b><br>Вы случайно прокляли себя, пытаясь понять действие проклятий.')
    ) AS v(an_id, sort_order, probability, rule_name, txt)

  UNION ALL

  SELECT 'en' AS lang, v.*
    FROM (VALUES
      ('wcc_mage_events_danger_o0101', 1, 0.1::numeric, 'is_mage_danger_cautious', '<b>Debt</b><br>You owe between 100 and 1,000 crowns.'),
      ('wcc_mage_events_danger_o0102', 2, 0.1::numeric, 'is_mage_danger_cautious', '<b>Addiction</b><br>You have an addiction of your choice:<br> - Alcohol<br> - Tobacco<br> - Fisstech<br> - Gambling<br> - Kleptomania<br> - Lust<br> - Gluttony<br> - Adrenaline Addiction<br> - Other (create your own)'),
      ('wcc_mage_events_danger_o0103', 3, 0.1::numeric, 'is_mage_danger_cautious', '<b>Fell Ill</b><br>You fell ill from a wasting disease. You eventually recovered, but it left behind lasting fatigue. Lower your STA by 2.'),
      ('wcc_mage_events_danger_o0104', 4, 0.1::numeric, 'is_mage_danger_cautious', '<b>Angered City Folk</b><br>It might be something you did (or something you did not do), but you have riled up the citizens of a major city. If you return to that city, the citizens will immediately see you as a threat or a target.'),
      ('wcc_mage_events_danger_o0105', 5, 0.1::numeric, 'is_mage_danger_cautious', '<b>Accident</b><br>You suffered an accident.'),
      ('wcc_mage_events_danger_o0106', 6, 0.1::numeric, 'is_mage_danger_cautious', '<b>Imprisonment</b><br>Something you did, or a false accusation, had you imprisoned for between 1 and 10 years.'),
      ('wcc_mage_events_danger_o0107', 7, 0.1::numeric, 'is_mage_danger_cautious_mentor_friend', '<b>Mentor Passed Away</b><br>If your mentor was still alive, they passed away during this decade. If you did not have a mentor, you can re-roll this result. It is up to you and the GM to determine how they died.'),
      ('wcc_mage_events_danger_o0108', 8, 0.1::numeric, 'is_mage_danger_cautious', '<b>Hair Fell Out</b><br>A spell went awry and as a result, all of the hair on your body has fallen out and refuses to grow back.'),
      ('wcc_mage_events_danger_o0109', 9, 0.1::numeric, 'is_mage_danger_cautious', '<b>Arthritis</b><br>Your hands have trouble making the intricate gestures required for spell casting without pain. You suffer a -1 penalty to your Spell Casting checks whenever you cast a spell that requires hand movement.'),
      ('wcc_mage_events_danger_o0110', 10, 0.1::numeric, 'is_mage_danger_cautious', '<b>Hexed</b><br>You were hexed either by someone you irritated or by your own hand.'),

      ('wcc_mage_events_danger_o0201', 1, 0.1::numeric, 'is_mage_danger_politics', '<b>Grudge</b><br>Someone hurt your feelings, or you hurt theirs. Nevertheless, one of you is holding a grudge from this event.'),
      ('wcc_mage_events_danger_o0202', 2, 0.1::numeric, 'is_mage_danger_politics', '<b>False Accusation</b><br>You were falsely accused of something.'),
      ('wcc_mage_events_danger_o0203', 3, 0.1::numeric, 'is_mage_danger_politics', '<b>Betrayed</b><br>You were betrayed by a friend or acquaintance. One of your existing friends becomes an enemy.'),
      ('wcc_mage_events_danger_o0204', 4, 0.1::numeric, 'is_mage_danger_politics', '<b>Friend or Lover Killed</b><br>A friend or lover was killed in an accident or perhaps due to a scheme.'),
      ('wcc_mage_events_danger_o0205', 5, 0.1::numeric, 'is_mage_danger_politics', '<b>Caught Red Handed</b><br>You were caught attempting to manipulate others into doing your dirty work. You gain an enemy whose power is based on minions.'),
      ('wcc_mage_events_danger_o0206', 6, 0.1::numeric, 'is_mage_danger_politics', '<b>Social Faux Pas</b><br>You made a terrible social faux pas at a gathering of mages and are now treated as Tolerated by other mages instead of Equal.'),
      ('wcc_mage_events_danger_o0207', 7, 0.1::numeric, 'is_mage_danger_politics', '<b>Hunted</b><br>There are bounties out on you. A group of 6 to 11 bounty hunters is actively looking for you.'),
      ('wcc_mage_events_danger_o0208', 8, 0.1::numeric, 'is_mage_danger_politics', '<b>Enemy of the State</b><br>Your political schemes were discovered, and you have been branded the enemy of a nation you were conspiring against. You are Hated in that nation regardless of what your Social Standing is in that region.'),
      ('wcc_mage_events_danger_o0209', 9, 0.1::numeric, 'is_mage_danger_politics', '<b>Rival</b><br>Through your actions, you have made a rival of another school member.'),
      ('wcc_mage_events_danger_o0210', 10, 0.1::numeric, 'is_mage_danger_politics', '<b>Retained by a Noble</b><br>A minor noble hired you for your magical abilities and arcane knowledge. Each month, you gain a stipend of 100 crowns. However, you must go to them immediately whenever they summon you and perform any tasks they require of you, or risk angering them.'),

      ('wcc_mage_events_danger_o0301', 1, 0.1::numeric, 'is_mage_danger_study', '<b>Magical Block</b><br>In your studies you neglected one of the elements in favor of others. When casting spells of that element, you take a -2 penalty to the Spell Casting check. This effect stacks.'),
      ('wcc_mage_events_danger_o0302', 2, 0.1::numeric, 'is_mage_danger_study', '<b>Monster Encounter</b><br>You once nearly died while studying a monster. You now have a phobia of this creature and take a -2 penalty to Courage checks against it. Additionally, you must make a Courage check at DC 15 when first encountering any instance of this creature or be Staggered.'),
      ('wcc_mage_events_danger_o0303', 3, 0.1::numeric, 'is_mage_danger_study', '<b>Overdrew from a Place of Power</b><br>You found a Place of Power, but in your inexperience over-drew from it and was permanently scarred in the process. Every Place of Power you draw from requires an Endurance save as if you were drawing from it a second time.'),
      ('wcc_mage_events_danger_o0304', 4, 0.1::numeric, 'is_mage_danger_study', '<b>Hunted by a Golem</b><br>In your studies you managed to step on the toes of a powerful mage who sent a golem after you. It now seeks you out across the Continent. If it finds you it will try to destroy you.'),
      ('wcc_mage_events_danger_o0305', 5, 0.1::numeric, 'is_mage_danger_study', '<b>Loud Telepathy</b><br>You learn the Telepathy Spell. You tried to improve upon the basic telepathy spell, but the result was not what you expected. When you spy telepathically on a target, you cannot help but emit a low mumble in their mind that may alert them. Anyone you spy upon can roll an Awareness check at a DC 15 to sense you.'),
      ('wcc_mage_events_danger_o0306', 6, 0.1::numeric, 'is_mage_danger_study', '<b>Polymorphed</b><br>You spent the decade polymorphed by another mage. It took a long time to find a way to reverse it. To this day, you have kept some of the manners of that animal. You suffer a -2 to your Social Etiquette.'),
      ('wcc_mage_events_danger_o0307', 7, 0.1::numeric, 'is_mage_danger_study', '<b>Extreme Vulnerability</b><br>You tried to make yourself resistant to dimeritium. You got the opposite result. You suffer a -3 penalty to your Endurance checks to resist the effects of dimeritium.'),
      ('wcc_mage_events_danger_o0308', 8, 0.1::numeric, 'is_mage_danger_study', '<b>Teleportation Sickness</b><br>You experience teleportation sickness. Whenever you teleport or travel through a portal, you must make an Endurance check at a DC 12 or suffer from the Nausea condition for 10 minutes.'),
      ('wcc_mage_events_danger_o0309', 9, 0.1::numeric, 'is_mage_danger_study', '<b>Lost a Sense</b><br>Your experiments have cost you much. You lost the sense of taste, smell or touch. You have a -2 penalty on skill checks that rely on that sense.'),
      ('wcc_mage_events_danger_o0310', 10, 0.1::numeric, 'is_mage_danger_study', '<b>Mutation</b><br>Your attempts at understanding mutagens backfired. You gain the physical changes of a Minor Mutation of a Mutagen of your choice and the changes in Social Standing.'),

      ('wcc_mage_events_danger_o0401', 1, 0.1::numeric, 'is_mage_danger_experiments', '<b>Overdraw</b><br>In your arrogance or your ignorance, you drew too much power into your body and suffered the consequences. Lower your Hit Points by 2.'),
      ('wcc_mage_events_danger_o0402', 2, 0.1::numeric, 'is_mage_danger_experiments', '<b>Demonic Encounter</b><br>At some point, whether it was your own doing or the workings of a fellow student, you came in contact with a demon. You may have fled or perhaps you fought for your life, but either way you bear the demon''s lucifuge (seal, true name) and they always know where you are.'),
      ('wcc_mage_events_danger_o0403', 3, 0.1::numeric, 'is_mage_danger_experiments', '<b>Deemed Dangerous</b><br>Something you did labeled you as dangerous to the people of a kingdom. In this kingdom you are wanted by the authorities.'),
      ('wcc_mage_events_danger_o0404', 4, 0.1::numeric, 'is_mage_danger_experiments', '<b>Alchemical Incident</b><br>You mixed the wrong reagents and suffered consequences. You take a -2 penalty to STA.'),
      ('wcc_mage_events_danger_o0405', 5, 0.1::numeric, 'is_mage_danger_experiments', '<b>Lasting Scars</b><br>One of your experiments backfired horrendously, deforming your face. Change your social standing to Feared.'),
      ('wcc_mage_events_danger_o0406', 6, 0.1::numeric, 'is_mage_danger_experiments', '<b>Magical Allergy</b><br>You have developed an allergy to magic. Whenever you drink a potion or elixir, in addition to the standard effects, you also suffer from the Nausea condition for the duration of the elixir.'),
      ('wcc_mage_events_danger_o0407', 7, 0.1::numeric, 'is_mage_danger_experiments', '<b>Intoxicated</b><br>You tried a poorly made concoction on yourself and it changed your metabolism forever. When drinking a potion or an elixir, you must roll beneath your BODY on 1d10 or become Intoxicated.'),
      ('wcc_mage_events_danger_o0408', 8, 0.1::numeric, 'is_mage_danger_experiments', '<b>Alchemical Dependency</b><br>Through constant testing of elixirs and potions, you have developed an addiction to Elixirs. This works exactly the same as any other addiction.'),
      ('wcc_mage_events_danger_o0409', 9, 0.1::numeric, 'is_mage_danger_experiments', '<b>Wanted by Hunters</b><br>You did something so careless and heinous with your magic that a church sent a pair of Witch Hunters (or Mage Hunters in Nilfgaard) after you. They are enemies that will do anything to subdue or kill you.'),
      ('wcc_mage_events_danger_o0410', 10, 0.1::numeric, 'is_mage_danger_experiments', '<b>Cursed</b><br>You cursed yourself by accident while trying to understand curses.')
    ) AS v(an_id, sort_order, probability, rule_name, txt)
)
, vals AS (
  SELECT
    lang,
    an_id,
    sort_order,
    probability,
    rule_name,
    '<td style="color: grey;">' || to_char(probability * 100, 'FM990.00') || '%</td><td>' || txt || '</td>' AS text
  FROM raw_data
)
, ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id('witcher_cc.' || vals.an_id || '.answer_options.label') AS id
       , 'answer_options', 'label', vals.lang, vals.text
    FROM vals
  ON CONFLICT (id, lang) DO UPDATE
  SET text = EXCLUDED.text
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT vals.an_id
     , 'witcher_cc'
     , 'wcc_mage_events_danger'
     , ck_id('witcher_cc.' || vals.an_id || '.answer_options.label')
     , vals.sort_order
     , (SELECT ru_id FROM rules WHERE name = vals.rule_name ORDER BY ru_id LIMIT 1)
     , jsonb_build_object('probability', vals.probability)
  FROM vals
 WHERE vals.lang = 'ru'
ON CONFLICT (an_id) DO UPDATE
SET label = EXCLUDED.label,
    sort_order = EXCLUDED.sort_order,
    visible_ru_ru_id = EXCLUDED.visible_ru_ru_id,
    metadata = EXCLUDED.metadata;

-- Links from previous node through danger outcomes
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
SELECT *
  FROM (VALUES
    ('wcc_mage_events_is_in_danger', 'wcc_mage_events_danger', 'wcc_mage_events_is_in_danger_o0102', 1),
    ('wcc_mage_events_is_in_danger', 'wcc_mage_events_danger', 'wcc_mage_events_is_in_danger_o0202', 1),
    ('wcc_mage_events_is_in_danger', 'wcc_mage_events_danger', 'wcc_mage_events_is_in_danger_o0302', 1),
    ('wcc_mage_events_is_in_danger', 'wcc_mage_events_danger', 'wcc_mage_events_is_in_danger_o0402', 1)
  ) AS v(from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
WHERE NOT EXISTS (
  SELECT 1
    FROM transitions t
   WHERE t.from_qu_qu_id = v.from_qu_qu_id
     AND t.to_qu_qu_id = v.to_qu_qu_id
     AND t.via_an_an_id = v.via_an_an_id
);
