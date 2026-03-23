\echo '033_past_academy_life.sql'

-- Hierarchy key
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.hierarchy.academy_life'), 'hierarchy', 'path', 'ru', 'Жизнь в академии'),
  (ck_id('witcher_cc.hierarchy.academy_life'), 'hierarchy', 'path', 'en', 'Life in the academy')
ON CONFLICT (id, lang) DO NOTHING;

-- Rule for academy loop while counter <= 19
INSERT INTO rules (ru_id, name, body)
VALUES (
  ck_id('witcher_cc.rules.magic_academy_life_counter_le_19'),
  'magic_academy_life_counter_le_19',
  jsonb_build_object(
    '<=',
    jsonb_build_array(
      jsonb_build_object('var', 'counters.lifeEventsCounter'),
      19
    )
  )
)
ON CONFLICT (ru_id) DO UPDATE SET body = EXCLUDED.body;

-- Rules: show apprentice outcomes only when mentor is absent
INSERT INTO rules (ru_id, name, body)
VALUES (
  ck_id('witcher_cc.rules.is_mentor_school_ban_ard_and_no_mentor'),
  'is_mentor_school_ban_ard_and_no_mentor',
  jsonb_build_object(
    'and',
    jsonb_build_array(
      jsonb_build_object(
        'or',
        jsonb_build_array(
          jsonb_build_object('==', jsonb_build_array(jsonb_build_object('var', 'characterRaw.logicFields.school'), 'ban_ard'))
        )
      ),
      jsonb_build_object('==', jsonb_build_array(jsonb_build_object('var', 'characterRaw.lore.mentor.personality'), NULL))
    )
  )
)
ON CONFLICT (ru_id) DO UPDATE SET body = EXCLUDED.body;

INSERT INTO rules (ru_id, name, body)
VALUES (
  ck_id('witcher_cc.rules.is_mentor_school_gweison_or_imperial_and_no_mentor'),
  'is_mentor_school_gweison_or_imperial_and_no_mentor',
  jsonb_build_object(
    'and',
    jsonb_build_array(
      jsonb_build_object(
        'or',
        jsonb_build_array(
          jsonb_build_object('==', jsonb_build_array(jsonb_build_object('var', 'characterRaw.logicFields.school'), 'gweison_haul')),
          jsonb_build_object('==', jsonb_build_array(jsonb_build_object('var', 'characterRaw.logicFields.school'), 'imperial_magic_academy'))
        )
      ),
      jsonb_build_object('==', jsonb_build_array(jsonb_build_object('var', 'characterRaw.lore.mentor.personality'), NULL))
    )
  )
)
ON CONFLICT (ru_id) DO UPDATE SET body = EXCLUDED.body;

-- Question
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_academy_life' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru', 'Как прошли ваши годы в магической академии?'),
        ('en', 'How did your years in a magical academy go?')
      ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
)
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Событие'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Event')
)
, ins_cols AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.column_name') AS id
         , meta.entity, 'column_name', c_vals.lang, c_vals.text
      FROM c_vals
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
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
           ck_id('witcher_cc.hierarchy.academy_life')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO NOTHING;

-- Answer options grouped by school
WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_past_academy_life' AS qu_id
         , 'answer_options' AS entity
  )
, raw_data AS (
  SELECT 'ru' AS lang, ru.*
    FROM (VALUES
      -- Group 1: Aretuza
      (1, 1, 'Отдача заклинания', 'Заклинание, которое вы произнесли, имело ужасные неприятные последствия. Порог Энергии понижен на 1.', 1.0::numeric, 'is_mentor_school_aretuza'),
      (1, 2, 'Сблизилась с другой ученицей', 'Вы и еще одна студента проводили время вместе, расслабляясь. Вы получаете союзника-мага. Сделайте бросок по таблице союзников, чтобы увидеть, насколько вы близки и какова их ценность.', 1.0::numeric, 'is_mentor_school_aretuza'),
      (1, 3, 'Выгнали соперницу', 'Из Аретузы выгнали твоего соперницу. Вы получаете врага-мага. Сделайте бросок по таблице Обиды, чтобы увидеть, как это обострилось и какова их сила.', 1.0::numeric, 'is_mentor_school_aretuza'),
      (1, 4, 'Любимица учителя', 'Вы получили персональное обучение от учителя. Начните с дополнительного известного заклинания новичка.', 1.0::numeric, 'is_mentor_school_aretuza'),
      (1, 5, 'Впечатлила иностранного сановника', 'Вы впечатлили иностранного сановника. Выберите королевство, при дворе которого о вас говорят.', 1.0::numeric, 'is_mentor_school_aretuza'),
      (1, 6, 'Украла ритуальные компоненты', 'Вы припрятали крошечные кусочки редких ритуальных компонентов. Начните с дополнительными компонентами стоимостью 100 крон.', 1.0::numeric, 'is_mentor_school_aretuza'),
      (1, 7, 'Нашла материал для шантажа учителя', 'Вы можете использовать эту информацию, чтобы добиться от них одной услуги на усмотрение ведущего.', 1.0::numeric, 'is_mentor_school_aretuza'),
      (1, 8, 'Найдены подсказки о местонахождении реликвии', 'Проконсультируйтесь с ведущим, чтобы определить, что это за реликвия и что вы знаете.', 1.0::numeric, 'is_mentor_school_aretuza'),
      (1, 9, 'Вас послали в открытый мир', 'Вы были привязаны к магу, живущему за пределами Аретузы. Совершите бросок на событие в жизни из таблицы Основной книги. Вас сделали ученицей.', 1.0::numeric, 'is_mentor_school_aretuza'),
      (1, 10, 'Проклят', 'Вы были прокляты либо собственной рукой, либо гневом кого-то из вашей школы. Вместе с ведущим выберите подходящее проклятие из перечисленных в Основной книге.', 1.0::numeric, 'is_mentor_school_aretuza'),

      -- Group 2: Ban Ard
      (2, 1, 'Отдача заклинания', 'Заклинание, которое вы произнесли, имело ужасные неприятные последствия. Порог Энергии понижен на 1.', 1.0::numeric, 'is_mentor_school_ban_ard'),
      (2, 2, 'Пойман на контрабанде', 'Вы тайно вынесли тома из школы и были пойманы. Вы получили наставника.', 1.0::numeric, 'is_mentor_school_ban_ard_and_no_mentor'),
      (2, 3, 'Украли свиток заклинаний', 'Начните со свитка заклинаний подмастерья. Определите с ведущим, какое заклинание записано в свитке.', 1.0::numeric, 'is_mentor_school_ban_ard'),
      (2, 4, 'Помогли с несанкционированным исследованием', 'Бросьте один раз по таблице Знаний. Если информация об этом исследовании выйдет наружу, у вас будут большие проблемы с выпускниками Бан Арда.', 1.0::numeric, 'is_mentor_school_ban_ard'),
      (2, 5, 'Охота на монстра', 'Вы вышли на охоту на чудовищ в густых лесах Каэдвена. Получите +1 к Монстрологии.', 1.0::numeric, 'is_mentor_school_ban_ard'),
      (2, 6, 'Ошибка заклинания', 'Вы случайно наложили магию на ученика или преподавателя и испортили им день. Сделайте бросок по таблице Обиды.', 1.0::numeric, 'is_mentor_school_ban_ard'),
      (2, 7, 'Наемничество', 'Вы сражались за мелкого дворянина в земельном споре. Вы сохранили часть своей зарплаты, после того как академия забрала свою долю, конечно. Получите 1d6 x 100 крон.', 1.0::numeric, 'is_mentor_school_ban_ard'),
      (2, 8, 'Проклят', 'Вы были прокляты либо собственной рукой, либо гневом кого-то из вашей школы. Вместе с ведущим выберите подходящее проклятие из перечисленных в Основной книге.', 1.0::numeric, 'is_mentor_school_ban_ard'),
      (2, 9, 'Посвящение в тайное общество: +2 к репутации среди выпускников Бан Арда', 'Вас приняли в тайное общество внутри школы. Получите +2 к репутации с другими выпускниками Бан Арда.', 1.0::numeric, 'is_mentor_school_ban_ard'),
      (2, 10, 'Перевел древний том', 'Вы помогли перевести древний эльфийский том. Вы получаете +2 к Старшей Речи.', 1.0::numeric, 'is_mentor_school_ban_ard'),

      -- Group 3: Gweison Haul (+ Imperial)
      (3, 1, 'Отдача заклинания', 'Заклинание, которое вы произнесли, имело ужасные неприятные последствия. Порог Энергии понижен на 1.', 1.0::numeric, 'is_mentor_school_gweison_or_imperial'),
      (3, 2, 'Нарушитель правил', 'Вы нарушили одно из многих правил Гвейсон Хайль, но были пойманы в процессе. Вы получили наставника.', 1.0::numeric, 'is_mentor_school_gweison_or_imperial_and_no_mentor'),
      (3, 3, 'Помогал разрабатывать оружие для Империи', 'Начните с 1 формулы бомбы. Определите с ведущим, какая это формула бомбы.', 1.0::numeric, 'is_mentor_school_gweison_or_imperial'),
      (3, 4, 'Законник', 'Вы помогли властям с преступлением, связанным с магией.', 1.0::numeric, 'is_mentor_school_gweison_or_imperial'),
      (3, 5, 'Исследовал катакомбы', 'Вы нашли свиток в катакомбах школы. Получите 1 свиток заклинаний подмастерья. Определите с ведущим, какое заклинание записано в свитке.', 1.0::numeric, 'is_mentor_school_gweison_or_imperial'),
      (3, 6, 'Влияние цензуры', 'Вас попросили найти и стереть все следы запрещенного произведения. Его автор теперь жаждет мести. Сделайте бросок по таблице Обиды, чтобы определить, кто это.', 1.0::numeric, 'is_mentor_school_gweison_or_imperial'),
      (3, 7, 'Помогли выследить маг-отступника', 'Вы помогли Охотникам на магов найти мага-изгоя. Получите +1 к любому боевому навыку или начните новый боевой навык с +2.', 1.0::numeric, 'is_mentor_school_gweison_or_imperial'),
      (3, 8, 'Приютили мага-отступника', 'Вы помогли приютить мага-изгоя. Вы получаете союзника-мага. Сделайте бросок по таблице союзников, чтобы увидеть, насколько вы близки и какова их ценность.', 1.0::numeric, 'is_mentor_school_gweison_or_imperial'),
      (3, 9, 'Связь с церковью', 'Вас послали помочь Церкви Великого Солнца в магических делах. Вы получаете +1 к Харизме и Этикету.', 1.0::numeric, 'is_mentor_school_gweison_or_imperial'),
      (3, 10, 'Благоразумие', 'Вас обучили основам шпионского ремесла. Вы получаете +1 к Маскировке и можете пытаться маскироваться без набора для маскировки без штрафа.', 1.0::numeric, 'is_mentor_school_gweison_or_imperial'),

      -- Group 4: Minor Academia
      (4, 1, 'Отдача заклинания', 'Заклинание, которое вы произнесли, имело ужасные неприятные последствия. Порог Энергии понижен на 1.', 1.0::numeric, 'is_mentor_school_minor'),
      (4, 2, 'Занимался темной магией', 'Вы баловались темной магией и выпустили в мир демона. Ты носишь Люцифуг демона, и они всегда знают, где ты.', 1.0::numeric, 'is_mentor_school_minor'),
      (4, 3, 'Цель ведьмака', 'Ваше неконтролируемое использование магии нанесло достаточно ущерба, чтобы ведьмак из школы Кота был нанят, чтобы убить вас. Этот ведьмак все еще ищет тебя.', 1.0::numeric, 'is_mentor_school_minor'),
      (4, 4, 'Аптекарь', 'Частью вашего обучения была способность диагностировать и лечить болезни людей из вашего сообщества. Получите +2 к Первой помощи.', 1.0::numeric, 'is_mentor_school_minor'),
      (4, 5, 'Ботаник', 'Вы ухаживали за школьным садом. Получите +2 к Выживанию.', 1.0::numeric, 'is_mentor_school_minor'),
      (4, 6, 'Помогали местным жителям с различными проблемами', 'Вы использовали свою магию, чтобы помочь нуждающемуся региону. Ваше социальное положение равно Равенству в этой области. Определите с ведущим, что это за область.', 1.0::numeric, 'is_mentor_school_minor'),
      (4, 7, 'Прокляты', 'Вы были прокляты либо собственной рукой, либо гневом кого-то из вашей школы. Вместе с ведущим выберите подходящее проклятие из перечисленных в Основной книге.', 1.0::numeric, 'is_mentor_school_minor'),
      (4, 8, 'Защитили деревню от чудовища', 'Вы использовали свою магию, чтобы отразить атаку монстра из деревни. Получите +1 к Монстрологии.', 1.0::numeric, 'is_mentor_school_minor'),
      (4, 9, 'Обучение вне академии', 'Вы учились у многих наставников, узнавая столько, сколько могли. Начните с двумя дополнительными заклинаниями новичка.', 1.0::numeric, 'is_mentor_school_minor'),
      (4, 10, 'Создал собственный фокус', 'Вы создали свой первый фокусирующий предмет. Вы получаете Амулет, который считается для вас предметом Фокус (2).', 1.0::numeric, 'is_mentor_school_minor')
    ) AS ru(group_id, num, title_txt, desc_txt, probability, rule_name)

  UNION ALL

  SELECT 'en' AS lang, en.*
    FROM (VALUES
      -- Group 1: Aretuza
      (1, 1, 'Spell Backfired', 'A spell you cast backfired horribly. You lower your Vigor Threshold by 1.', 1.0::numeric, 'is_mentor_school_aretuza'),
      (1, 2, 'Developed a Bond with Another Student', 'You and another student spent time together to unwind. You gain a Mage Ally. Roll on the Ally table to see how close you are and what their value is.', 1.0::numeric, 'is_mentor_school_aretuza'),
      (1, 3, 'Got a Rival Expelled', 'You got a rival of yours expelled from Aretuza. You gain a Mage Enemy. Roll on the Grudges table to see how it''s escalated and what their power is.', 1.0::numeric, 'is_mentor_school_aretuza'),
      (1, 4, 'Teacher''s Pet', 'You got preferential treatment from a teacher. Start with an extra known Novice spell.', 1.0::numeric, 'is_mentor_school_aretuza'),
      (1, 5, 'Impressed a Foreign Dignitary', 'You impressed a foreign dignitary. Choose the kingdom where your reputation at court grew.', 1.0::numeric, 'is_mentor_school_aretuza'),
      (1, 6, 'Stole Ritual Components', 'You squirreled away tiny bits of rare ritual components. Start with an extra 100 crowns of components.', 1.0::numeric, 'is_mentor_school_aretuza'),
      (1, 7, 'Found Blackmail Material on a Teacher', 'You can use this information to force a single favor out of them at the GM''s discretion.', 1.0::numeric, 'is_mentor_school_aretuza'),
      (1, 8, 'Found Clues on the Location of a Relic', 'Consult with the GM to determine which Relic and what you know.', 1.0::numeric, 'is_mentor_school_aretuza'),
      (1, 9, 'You Were Sent into the World', 'You were leashed to a mage living outside of Aretuza. Roll a regular life event from the Core Book table. You were made an apprentice.', 1.0::numeric, 'is_mentor_school_aretuza'),
      (1, 10, 'Cursed', 'You were cursed, either by your own hand or the ire of another at your school. Work with the GM to pick an appropriate curse from the ones listed in the Core Book.', 1.0::numeric, 'is_mentor_school_aretuza'),

      -- Group 2: Ban Ard
      (2, 1, 'Spell Backfired', 'A spell you cast backfired horribly. You lower your Vigor Threshold by 1.', 1.0::numeric, 'is_mentor_school_ban_ard'),
      (2, 2, 'Caught Smuggling', 'You smuggled tomes out of the school and were caught. You were made an apprentice.', 1.0::numeric, 'is_mentor_school_ban_ard_and_no_mentor'),
      (2, 3, 'Stole a Spell Scroll', 'Start with a journeyman spell scroll. Work with the GM to determine which spell.', 1.0::numeric, 'is_mentor_school_ban_ard'),
      (2, 4, 'Helped with Unsanctioned Research', 'Roll once on the Knowledge table. If knowledge of this research comes out, you will be in major trouble with Ban Ard Alumni.', 1.0::numeric, 'is_mentor_school_ban_ard'),
      (2, 5, 'Hunted a Monster', 'You went out to hunt a monster in the dense forests of Kaedwen. Gain +1 to Monster Lore.', 1.0::numeric, 'is_mentor_school_ban_ard'),
      (2, 6, 'Miscast', 'You accidentally cast magic on a school member or faculty and ruined their day. Roll on the Grudges table.', 1.0::numeric, 'is_mentor_school_ban_ard'),
      (2, 7, 'Mercenary Work', 'You fought for a minor noble in a land dispute. You kept part of your pay, after the school took its cut of course. Gain 1d6 x 100 crowns.', 1.0::numeric, 'is_mentor_school_ban_ard'),
      (2, 8, 'Cursed', 'You were cursed, either by your own hand or the ire of another at your school. Work with the GM to pick an appropriate curse from the ones listed in the Core Book.', 1.0::numeric, 'is_mentor_school_ban_ard'),
      (2, 9, 'Secret Society Initiation: +2 Reputation with Ban Ard alumni', 'You were inducted into a secret society within the school. Gain +2 Reputation with the other alumni of Ban Ard.', 1.0::numeric, 'is_mentor_school_ban_ard'),
      (2, 10, 'Translated a Tome', 'You helped translate an old elven tome. You gain +2 to Elder Speech.', 1.0::numeric, 'is_mentor_school_ban_ard'),

      -- Group 3: Gweison Haul (+ Imperial)
      (3, 1, 'Spell Backfired', 'A spell you cast backfired horribly. You lower your Vigor Threshold by 1.', 1.0::numeric, 'is_mentor_school_gweison_or_imperial'),
      (3, 2, 'Rule-Breaker', 'You broke one of the many rules of Gweison Haul but were caught in the process. You were made an apprentice.', 1.0::numeric, 'is_mentor_school_gweison_or_imperial_and_no_mentor'),
      (3, 3, 'Helped Develop Weapons of War for the Empire', 'Start with 1 bomb formula. Work with the GM to determine which bomb.', 1.0::numeric, 'is_mentor_school_gweison_or_imperial'),
      (3, 4, 'Law Bringer', 'You helped the authorities with a magic-related crime.', 1.0::numeric, 'is_mentor_school_gweison_or_imperial'),
      (3, 5, 'Explored the Catacombs', 'You found a scroll in the catacombs of the school. Gain 1 journeyman spell scroll. Work with the GM to determine which spell.', 1.0::numeric, 'is_mentor_school_gweison_or_imperial'),
      (3, 6, 'Censorship', 'You were asked to find and erase all traces of a banned work. Its author is now out for revenge. Roll on the Grudges table to determine who it is.', 1.0::numeric, 'is_mentor_school_gweison_or_imperial'),
      (3, 7, 'Helped hunt down a Renegade Mage', 'You helped the Mage Hunters bring in a rogue mage. Gain +1 in any combat skill or start a new combat skill at +2.', 1.0::numeric, 'is_mentor_school_gweison_or_imperial'),
      (3, 8, 'Harbored a Renegade Mage', 'You helped shelter a rogue mage. You gain a Mage Ally. Roll on the Ally table to see how close you are and what their value is.', 1.0::numeric, 'is_mentor_school_gweison_or_imperial'),
      (3, 9, 'Church Liaison', 'You were sent to help the Church of the Great Sun with magical matters. You gain a +1 to Charisma and Social Etiquette.', 1.0::numeric, 'is_mentor_school_gweison_or_imperial'),
      (3, 10, 'Better Part of Valor', 'You were trained in the basis of spy work. You gain a +1 to Disguise and can attempt to disguise yourself without a disguise kit at no penalty.', 1.0::numeric, 'is_mentor_school_gweison_or_imperial'),

      -- Group 4: Minor Academia
      (4, 1, 'Spell Backfired', 'A spell you cast backfired horribly. You lower your Vigor Threshold by 1.', 1.0::numeric, 'is_mentor_school_minor'),
      (4, 2, 'Dabbled in Dark Magic', 'You have dabbled in Dark Magic and unleashed a demon on the world. You bear the demon''s lucifuge and they always know where you are.', 1.0::numeric, 'is_mentor_school_minor'),
      (4, 3, 'Witcher Target', 'Your unsupervised use of magic caused enough damage that a Cat school witcher was hired to kill you. This witcher is still looking for you.', 1.0::numeric, 'is_mentor_school_minor'),
      (4, 4, 'Apothecary', 'Part of your learning involved being able to diagnose and cure ailments for the people of your community. Gain a +2 to First Aid.', 1.0::numeric, 'is_mentor_school_minor'),
      (4, 5, 'Botanist', 'You tended to your school''s garden. Gain +2 to Wilderness Survival.', 1.0::numeric, 'is_mentor_school_minor'),
      (4, 6, 'Helped Locals with Various Issues', 'You have used your magic to aid a region in need. Your Social Standing is Equal in this area. Work with the GM to determine where this is.', 1.0::numeric, 'is_mentor_school_minor'),
      (4, 7, 'Cursed', 'You were cursed, either by your own hand or the ire of another at your school. Work with the GM to pick an appropriate curse from the ones listed in the Core Book.', 1.0::numeric, 'is_mentor_school_minor'),
      (4, 8, 'Defended a Village from a Monster', 'You used your magic to repel a monster attack from a village. Gain +1 to Monster Lore.', 1.0::numeric, 'is_mentor_school_minor'),
      (4, 9, 'Extracurricular Learning', 'You studied under many mentors, learning as much as you could. Start with two extra Novice spells.', 1.0::numeric, 'is_mentor_school_minor'),
      (4, 10, 'Crafted your Own Focus', 'You built your first focus item. You gain an Amulet which counts as a Focus (2) item for you.', 1.0::numeric, 'is_mentor_school_minor')
    ) AS en(group_id, num, title_txt, desc_txt, probability, rule_name)
)
, ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100 * raw_data.group_id + raw_data.num, 'FM0000') ||'.'|| meta.entity ||'.label') AS id
       , meta.entity, 'label', raw_data.lang
       , '<td style="color: grey;">' || to_char(raw_data.probability * 100, 'FM990.00') || '%</td><td><b>' || raw_data.title_txt || '</b><br>' || raw_data.desc_txt || '</td>'
    FROM raw_data
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
, ins_event_desc AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100 * raw_data.group_id + raw_data.num, 'FM0000') ||'.event_desc') AS id
       , 'character', 'event_desc', raw_data.lang, raw_data.title_txt
    FROM raw_data
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT meta.qu_id || '_o' || to_char(raw_data.group_id, 'FM00') || to_char(raw_data.num, 'FM00') AS an_id
     , meta.su_su_id
     , meta.qu_id
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100 * raw_data.group_id + raw_data.num, 'FM0000') ||'.'|| meta.entity ||'.label') AS label
     , raw_data.num
     , (SELECT ru_id FROM rules WHERE name = raw_data.rule_name ORDER BY ru_id LIMIT 1) AS visible_ru_ru_id
     , jsonb_build_object('probability', raw_data.probability)
       || CASE
            WHEN
              (raw_data.group_id = 1 AND raw_data.num IN (1, 4, 6, 7, 8))
              OR (raw_data.group_id = 2 AND raw_data.num IN (1, 3, 5, 9, 10))
              OR (raw_data.group_id = 3 AND raw_data.num IN (1, 3, 4, 5, 9, 10))
              OR (raw_data.group_id = 4 AND raw_data.num IN (1, 2, 3, 4, 5, 8, 9, 10))
            THEN jsonb_build_object('counterIncrement', jsonb_build_object('id', 'lifeEventsCounter', 'step', 10))
            ELSE '{}'::jsonb
          END
  FROM raw_data
 CROSS JOIN meta
 WHERE raw_data.lang = 'ru'
ON CONFLICT (an_id) DO NOTHING;

-- i18n for academy life events and extra effects
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.wcc_past_academy_life.life_event_type.academy_life'), 'character', 'event_type', 'ru', 'Жизнь в Академии'),
  (ck_id('witcher_cc.wcc_past_academy_life.life_event_type.academy_life'), 'character', 'event_type', 'en', 'Academy Life'),
  (ck_id('witcher_cc.wcc_past_academy_life_o0107.gear_name'), 'items', 'general_gear_names', 'ru', 'Услуга учителя, полученная шантажом'),
  (ck_id('witcher_cc.wcc_past_academy_life_o0107.gear_name'), 'items', 'general_gear_names', 'en', 'Teacher''s Favor Obtained by Blackmail'),
  (ck_id('witcher_cc.wcc_past_academy_life.journeyman_scroll.name'), 'items', 'general_gear_names', 'ru', 'Свиток заклинания (Подмастерье)'),
  (ck_id('witcher_cc.wcc_past_academy_life.journeyman_scroll.name'), 'items', 'general_gear_names', 'en', 'Spell Scroll (Journeyman)'),
  (ck_id('witcher_cc.wcc_past_academy_life.journeyman_scroll.description'), 'items', 'general_gear_description', 'ru', 'Потратив 20 О.У., 7 дней и пройдя 4 проверки со СЛ18, вы выучите это заклинание.'),
  (ck_id('witcher_cc.wcc_past_academy_life.journeyman_scroll.description'), 'items', 'general_gear_description', 'en', 'By spending 20 i.P., 7 days, and passing 4 checks at DC 18, you can learn this spell.'),
  (ck_id('witcher_cc.wcc_past_academy_life_o0310.perks.description'), 'perks', 'description', 'ru', '<b>Шпионаж</b>: Маскировка без набора для маскировки происходит без штрафа.'),
  (ck_id('witcher_cc.wcc_past_academy_life_o0310.perks.description'), 'perks', 'description', 'en', '<b>Spycraft</b>: You can disguise yourself without a disguise kit and suffer no penalty.')
ON CONFLICT (id, lang) DO NOTHING;

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id(v.key), 'character', 'event_desc', v.lang, v.text
FROM (VALUES
  ('witcher_cc.wcc_past_academy_life_o0101.event_desc', 'ru', 'Отдача заклинания: [-1 к Энергии]'),
  ('witcher_cc.wcc_past_academy_life_o0101.event_desc', 'en', 'Spell backfired: [-1 to Vigor]'),
  ('witcher_cc.wcc_past_academy_life_o0102.event_desc', 'ru', 'Сблизилась с другой ученицей: получила союзника'),
  ('witcher_cc.wcc_past_academy_life_o0102.event_desc', 'en', 'Developed a bond with another student: gained an ally'),
  ('witcher_cc.wcc_past_academy_life_o0103.event_desc', 'ru', 'Выгнали мага-соперницу: получили врага'),
  ('witcher_cc.wcc_past_academy_life_o0103.event_desc', 'en', 'Expelled a rival mage: gained an enemy'),
  ('witcher_cc.wcc_past_academy_life_o0104.event_desc', 'ru', 'Персональное обучение: [+1 заклинание новичка]'),
  ('witcher_cc.wcc_past_academy_life_o0104.event_desc', 'en', 'Personal tutoring: [+1 novice spell]'),
  ('witcher_cc.wcc_past_academy_life_o0106.event_desc', 'ru', 'Украла ритуальные компоненты на 100 крон'),
  ('witcher_cc.wcc_past_academy_life_o0106.event_desc', 'en', 'Stole ritual components worth 100 crowns'),
  ('witcher_cc.wcc_past_academy_life_o0108.event_desc', 'ru', 'Найдены подсказки о местонахождении реликвии, уточнить у ГМа'),
  ('witcher_cc.wcc_past_academy_life_o0108.event_desc', 'en', 'Found clues to a relic''s location, ask the GM'),
  ('witcher_cc.wcc_past_academy_life_o0201.event_desc', 'ru', 'Отдача заклинания: [-1 к Энергии]'),
  ('witcher_cc.wcc_past_academy_life_o0201.event_desc', 'en', 'Spell backfired: [-1 to Vigor]'),
  ('witcher_cc.wcc_past_academy_life_o0203.event_desc', 'ru', 'Украл магическую формулу'),
  ('witcher_cc.wcc_past_academy_life_o0203.event_desc', 'en', 'Stole a spell formula'),
  ('witcher_cc.wcc_past_academy_life_o0205.event_desc', 'ru', 'Охота на монстра: [+1 к Монстрологии]'),
  ('witcher_cc.wcc_past_academy_life_o0205.event_desc', 'en', 'Hunted a monster: [+1 to Monster Lore]'),
  ('witcher_cc.wcc_past_academy_life_o0206.event_desc', 'ru', 'Новый враг из-за ошибки в заклинании'),
  ('witcher_cc.wcc_past_academy_life_o0206.event_desc', 'en', 'A new enemy because of a spell mishap'),
  ('witcher_cc.wcc_past_academy_life_o0209.event_desc', 'ru', 'Посвящение в тайное общество: +2 к репутации среди выпускников Бан Арда'),
  ('witcher_cc.wcc_past_academy_life_o0209.event_desc', 'en', 'Secret society initiation: +2 Reputation with Ban Ard alumni'),
  ('witcher_cc.wcc_past_academy_life_o0210.event_desc', 'ru', 'Перевел древний том: [+2 к Старшей речи]'),
  ('witcher_cc.wcc_past_academy_life_o0210.event_desc', 'en', 'Translated a tome: [+2 to Elder Speech]'),
  ('witcher_cc.wcc_past_academy_life_o0301.event_desc', 'ru', 'Отдача заклинания: [-1 к Энергии]'),
  ('witcher_cc.wcc_past_academy_life_o0301.event_desc', 'en', 'Spell backfired: [-1 to Vigor]'),
  ('witcher_cc.wcc_past_academy_life_o0304.event_desc', 'ru', 'Помог властям Нильфгаарда: +2 к репутации у властей Нильфгаарда'),
  ('witcher_cc.wcc_past_academy_life_o0304.event_desc', 'en', 'Helped Nilfgaardian authorities: +2 Reputation with Nilfgaardian authorities'),
  ('witcher_cc.wcc_past_academy_life_o0305.event_desc', 'ru', 'Исследовал катакомбы: нашел свиток'),
  ('witcher_cc.wcc_past_academy_life_o0305.event_desc', 'en', 'Explored the catacombs: found a scroll'),
  ('witcher_cc.wcc_past_academy_life_o0306.event_desc', 'ru', 'Подвергли кого-то цензуре: получили врага'),
  ('witcher_cc.wcc_past_academy_life_o0306.event_desc', 'en', 'Censored someone: gained an enemy'),
  ('witcher_cc.wcc_past_academy_life_o0308.event_desc', 'ru', 'Укрыли мага-отступника: получили союзника'),
  ('witcher_cc.wcc_past_academy_life_o0308.event_desc', 'en', 'Sheltered a renegade mage: gained an ally'),
  ('witcher_cc.wcc_past_academy_life_o0309.event_desc', 'ru', 'Помощь Церкви Великого Солнца: [+1 к Харизме и Этикету]'),
  ('witcher_cc.wcc_past_academy_life_o0309.event_desc', 'en', 'Aided the Church of the Great Sun: [+1 to Charisma and Social Etiquette]'),
  ('witcher_cc.wcc_past_academy_life_o0310.event_desc', 'ru', 'Обучался шпионажу: [+1 к Маскировке] и [перк Шпионаж]'),
  ('witcher_cc.wcc_past_academy_life_o0310.event_desc', 'en', 'Studied spycraft: [+1 to Disguise] and [Spycraft perk]'),
  ('witcher_cc.wcc_past_academy_life_o0401.event_desc', 'ru', 'Отдача заклинания: [-1 к Энергии]'),
  ('witcher_cc.wcc_past_academy_life_o0401.event_desc', 'en', 'Spell backfired: [-1 to Vigor]'),
  ('witcher_cc.wcc_past_academy_life_o0402.event_desc', 'ru', 'Занимался темной магией: на тебе Люцифуг демона, который всегда знает, где ты'),
  ('witcher_cc.wcc_past_academy_life_o0402.event_desc', 'en', 'Dabbled in dark magic: you bear a demon''s lucifuge that always knows where you are'),
  ('witcher_cc.wcc_past_academy_life_o0403.event_desc', 'ru', 'Нанесли ущерб магией: стал целью ведьмака школы Кота'),
  ('witcher_cc.wcc_past_academy_life_o0403.event_desc', 'en', 'Caused magical damage: became the target of a Cat School witcher'),
  ('witcher_cc.wcc_past_academy_life_o0404.event_desc', 'ru', 'Изучал лечение болезней: [+2 к Первой помощи]'),
  ('witcher_cc.wcc_past_academy_life_o0404.event_desc', 'en', 'Studied how to treat illnesses: [+2 to First Aid]'),
  ('witcher_cc.wcc_past_academy_life_o0405.event_desc', 'ru', 'Ухаживал за школьным садом: [+2 к Выживанию]'),
  ('witcher_cc.wcc_past_academy_life_o0405.event_desc', 'en', 'Tended the school garden: [+2 to Wilderness Survival]'),
  ('witcher_cc.wcc_past_academy_life_o0408.event_desc', 'ru', 'Защитили деревню от чудовища: [+1 к Монстрологии]'),
  ('witcher_cc.wcc_past_academy_life_o0408.event_desc', 'en', 'Defended a village from a monster: [+1 to Monster Lore]'),
  ('witcher_cc.wcc_past_academy_life_o0409.event_desc', 'ru', 'Обучение вне академии: [+2 заклинания Новичка]'),
  ('witcher_cc.wcc_past_academy_life_o0409.event_desc', 'en', 'Extracurricular learning: [+2 novice spells]'),
  ('witcher_cc.wcc_past_academy_life_o0410.event_desc', 'ru', 'Создал [Амулет с эффектом Фокусирующий(2)]'),
  ('witcher_cc.wcc_past_academy_life_o0410.event_desc', 'en', 'Crafted [an amulet with the Focus(2) effect]')
) AS v(key, lang, text)
ON CONFLICT (id, lang) DO UPDATE
SET text = EXCLUDED.text;

-- Effects: save every selected option to life events
WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_past_academy_life' AS qu_id
  )
, options AS (
    SELECT g.group_id, n.num
      FROM generate_series(1, 4) AS g(group_id)
      CROSS JOIN generate_series(1, 10) AS n(num)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  meta.qu_id || '_o' || to_char(options.group_id, 'FM00') || to_char(options.num, 'FM00'),
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.lifeEvents'),
      jsonb_build_object(
        'timePeriod',
        jsonb_build_object(
          'jsonlogic_expression', jsonb_build_object(
            'cat', jsonb_build_array(
              jsonb_build_object('var', 'counters.lifeEventsCounter'),
              '-',
              jsonb_build_object(
                '+', jsonb_build_array(
                  jsonb_build_object('var', 'counters.lifeEventsCounter'),
                  10
                )
              )
            )
          )
        ),
        'eventType',
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'life_event_type.academy_life')::text),
        'description',
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100 * options.group_id + options.num, 'FM0000') ||'.event_desc')::text)
      )
    )
  )
FROM options
CROSS JOIN meta
WHERE NOT (
  (options.group_id = 1 AND options.num = 5) OR
  (options.group_id = 1 AND options.num = 10) OR
  (options.group_id = 2 AND options.num = 8) OR
  (options.group_id = 3 AND options.num = 7) OR
  (options.group_id = 4 AND options.num IN (6, 7))
);

-- Effects: option 1 in each group => -1 to Vigor bonus
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  v.an_id,
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.statistics.vigor.bonus'),
      -1
    )
  )
FROM (VALUES
  ('wcc_past_academy_life_o0101'),
  ('wcc_past_academy_life_o0201'),
  ('wcc_past_academy_life_o0301'),
  ('wcc_past_academy_life_o0401')
) AS v(an_id);

-- Effects: tokens for bomb formulae / novice spells
WITH token_effects(an_id, target_path, delta) AS (
  VALUES
    ('wcc_past_academy_life_o0303', 'characterRaw.professional_gear_options.bomb_formulae_tokens', 1),
    ('wcc_past_academy_life_o0104', 'characterRaw.professional_gear_options.novice_spells_tokens', 1),
    ('wcc_past_academy_life_o0409', 'characterRaw.professional_gear_options.novice_spells_tokens', 2)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  token_effects.an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', token_effects.target_path),
      jsonb_build_object(
        'jsonlogic_expression',
        jsonb_build_object(
          '+',
          jsonb_build_array(
            jsonb_build_object('var', jsonb_build_array(token_effects.target_path, 0)),
            token_effects.delta
          )
        )
      )
    )
  )
FROM token_effects;

-- Effects: custom localized item "Spell Scroll (Journeyman)" for Ban Ard#3 and Gweison#5
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  v.an_id,
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.gear.general_gear'),
      jsonb_build_object(
        'name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_past_academy_life.journeyman_scroll.name')::text),
        'description', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_past_academy_life.journeyman_scroll.description')::text),
        'weight', 0.1,
        'price', 0,
        'amount', 1
      )
    )
  )
FROM (VALUES
  ('wcc_past_academy_life_o0203'),
  ('wcc_past_academy_life_o0305')
) AS v(an_id);

-- Effects: skill bonuses
WITH skill_effects(an_id, skill_id, delta) AS (
  VALUES
    ('wcc_past_academy_life_o0404', 'first_aid', 2),
    ('wcc_past_academy_life_o0205', 'monster_lore', 1),
    ('wcc_past_academy_life_o0405', 'wilderness_survival', 2),
    ('wcc_past_academy_life_o0408', 'monster_lore', 1),
    ('wcc_past_academy_life_o0309', 'charisma', 1),
    ('wcc_past_academy_life_o0309', 'social_etiquette', 1),
    ('wcc_past_academy_life_o0210', 'language_elder_speech', 2),
    ('wcc_past_academy_life_o0310', 'disguise', 1)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  skill_effects.an_id,
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.common.' || skill_effects.skill_id || '.bonus'),
      skill_effects.delta
    )
  )
FROM skill_effects;

-- Effects: +100 crowns to alchemy ingredients budget (Aretuza option 6)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_past_academy_life_o0106',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.money.alchemyIngredientsCrowns'),
      100
    )
  );

-- Effects: custom item in general gear (Aretuza option 7)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_past_academy_life_o0107',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.gear.general_gear'),
      jsonb_build_object(
        'name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_past_academy_life_o0107.gear_name')::text),
        'weight', 0,
        'amount', 1
      )
    )
  );

-- Effects: perk for Gweison/Imperial option 10
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_past_academy_life_o0310',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.perks'),
      jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_past_academy_life_o0310.perks.description')::text)
    )
  );

-- Effects: focused amulet in general gear (Minor Academia option 10)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_past_academy_life_o0410',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.gear.general_gear'),
      jsonb_build_object(
        't_id', 'T147',
        'sourceId', 'general_gear',
        'amount', 1
      )
    )
  );

-- Effects: remember key academy life outcomes for downstream branches
WITH effect_vals(an_id, marker) AS (
  VALUES
    ('wcc_past_academy_life_o0102', 'academy life 1-2'),
    ('wcc_past_academy_life_o0103', 'academy life 1-3'),
    ('wcc_past_academy_life_o0109', 'academy life 1-9'),
    ('wcc_past_academy_life_o0110', 'academy life 1-10'),
    ('wcc_past_academy_life_o0202', 'academy life 2-2'),
    ('wcc_past_academy_life_o0203', 'academy life 2-3'),
    ('wcc_past_academy_life_o0204', 'academy life 2-4'),
    ('wcc_past_academy_life_o0206', 'academy life 2-6'),
    ('wcc_past_academy_life_o0208', 'academy life 2-8'),
    ('wcc_past_academy_life_o0306', 'academy life 3-6'),
    ('wcc_past_academy_life_o0308', 'academy life 3-8'),
    ('wcc_past_academy_life_o0403', 'academy life 4-3'),
    ('wcc_past_academy_life_o0406', 'academy life 4-6'),
    ('wcc_past_academy_life_o0407', 'academy life 4-7')
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

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id(v.key), 'character', 'enemy_field', v.lang, v.text
FROM (VALUES
  ('witcher_cc.wcc_past_academy_life_o0403.enemy.position', 'ru', 'Ведьмак'),
  ('witcher_cc.wcc_past_academy_life_o0403.enemy.position', 'en', 'Witcher'),
  ('witcher_cc.wcc_past_academy_life_o0403.enemy.cause', 'ru', 'Ущерб из-за вашей магии'),
  ('witcher_cc.wcc_past_academy_life_o0403.enemy.cause', 'en', 'Damage caused by your magic')
) AS v(key, lang, text)
ON CONFLICT (id, lang) DO UPDATE
SET text = EXCLUDED.text;

INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character',
  'wcc_past_academy_life_o0403',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.enemies'),
      jsonb_build_object(
        'gender', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_life_events_enemy_gender_o0001.answer_options.label_value')::text),
        'victim', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_enemy_victim_o0002.answer_options.label_value')::text),
        'position', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_past_academy_life_o0403.enemy.position')::text),
        'cause', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_past_academy_life_o0403.enemy.cause')::text),
        'power_level', '',
        'how_far', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_enemy_how_far_o0009.answer_options.label_value')::text),
        'the_power', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_enemy_the_power_o0003.answer_options.label_value')::text)
      )
    )
  );
