\echo '030_life_events_fortune_or_not_details.sql'
-- Узел: Братья и сёстры - количество

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_fortune_or_not_details' AS qu_id
                , 'questions' AS entity)
, ins_body AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
                       , meta.entity, 'body', v.lang, v.text
                    FROM (VALUES
                            ('ru', 'Определите детали произошедшего события.'),
                            ('en', 'Determine the details of what happened.')) AS v(lang, text)
                    CROSS JOIN meta)
, c_vals(lang, num, text) AS (VALUES ('ru', 1, 'Шанс'),
                                     ('ru', 2, 'Уточнение'),
                                     ('en', 1, 'Chance'),
                                     ('en', 2, 'Clarification'))
, ins_c AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| 'column_name') AS id
                       , meta.entity, 'column_name', c_vals.lang, c_vals.text
				    FROM c_vals
					CROSS JOIN meta)
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
  SELECT meta.qu_id
       , meta.su_su_id
       , NULL
       , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body')
       , 'single_table'
       , jsonb_build_object(
           'dice','d_weighed',
           'columns', (
             SELECT jsonb_agg(
                      ck_id('witcher_cc' ||'.'|| 'wcc_life_events_fortune_or_not_details' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text
                      ORDER BY num
                    )
               FROM (SELECT DISTINCT num FROM c_vals) AS cols
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
           jsonb_build_object('jsonlogic_expression',
             jsonb_build_object('if',
               jsonb_build_array(
                 jsonb_build_object('==',
                   jsonb_build_array(
                     jsonb_build_object('var', 'answers.lastAnswer.questionId'),
                    'wcc_life_events_fortune'
                   )
                 ),
                 ck_id('witcher_cc.hierarchy.life_events_fortune')::text,
                 ck_id('witcher_cc.hierarchy.life_events_misfortune')::text
               )
             )
           ),
             ck_id('witcher_cc.hierarchy.life_events_misfortune_details')::text
           )
         )
    FROM meta;


-- Ответы (каждый вариант 10%)
WITH
raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
            -- group 1: Удача - Джекпот (o1)
            (1, 1, 0.1, 'Получаете 100 крон'),
            (1, 2, 0.1, 'Получаете 200 крон'),
            (1, 3, 0.1, 'Получаете 300 крон'),
            (1, 4, 0.1, 'Получаете 400 крон'),
            (1, 5, 0.1, 'Получаете 500 крон'),
            (1, 6, 0.1, 'Получаете 600 крон'),
            (1, 7, 0.1, 'Получаете 700 крон'),
            (1, 8, 0.1, 'Получаете 800 крон'),
            (1, 9, 0.1, 'Получаете 900 крон'),
            (1, 10, 0.1, 'Получаете 1000 крон'),

            -- group 2: Удача - Учитель (o2) - навыки интеллекта
            (2, 1, 0.0909, 'Внимание'),
            (2, 2, 0.0909, 'Выживание в дикой природе'),
            (2, 3, 0.0909, 'Дедукция'),
            (2, 4, 0.0909, 'Монстрология'),
            (2, 5, 0.0909, 'Образование'),
            (2, 6, 0.0909, 'Ориентирование в городе'),
            (2, 7, 0.0909, 'Передача знаний'),
            (2, 8, 0.0909, 'Тактика'),
            (2, 9, 0.0909, 'Торговля'),
            (2, 10, 0.0909, 'Этикет'),
            (2, 11, 0.0303, 'Язык - северный'),
            (2, 12, 0.0303, 'Язык - дварфийский'),
            (2, 13, 0.0303, 'Язык - старшая речь'),

            -- group 4: Удача - Боевой инструктор (o4) - боевые навыки
            (4, 1, 0.1, 'Атлетика'),
            (4, 2, 0.1, 'Ближний бой'),
            (4, 3, 0.1, 'Борьба'),
            (4, 4, 0.1, 'Верховая езда'),
            (4, 5, 0.1, 'Владение древковым оружием'),
            (4, 6, 0.1, 'Владение лёгкими клинками'),
            (4, 7, 0.1, 'Владение мечом'),
            (4, 8, 0.1, 'Стрельба из арбалета'),
            (4, 9, 0.1, 'Стрельба из лука'),
            (4, 10, 0.1, 'Тактика'),

            -- group 7: Удача - Прирученный зверь (o7)
            (7, 1, 0.7, 'Дикая собака'),
            (7, 2, 0.3, 'Волк'),

            -- group 10: Удача - Рыцарство (o10) - королевства
            (10, 1, 0.041, 'Редания'),
            (10, 2, 0.041, 'Каэдвен'),
            (10, 3, 0.041, 'Темерия'),
            (10, 4, 0.041, 'Аэдирн'),
            (10, 5, 0.041, 'Лирия'),
            (10, 6, 0.041, 'Ривия'),
            (10, 7, 0.041, 'Ковир'),
            (10, 8, 0.041, 'Повис'),
            (10, 9, 0.041, 'Скеллиге'),
            (10, 10, 0.041, 'Цидарис'),
            (10, 11, 0.041, 'Вердэн'),
            (10, 12, 0.041, 'Цинтра'),
            (10, 13, 0.041, 'Сердце Нильфгаарда'),
            (10, 14, 0.041, 'Вассальное государство Нильфгаарда - Виковаро'),
            (10, 15, 0.041, 'Вассальное государство Нильфгаарда - Аигрен'),
            (10, 16, 0.041, 'Вассальное государство Нильфгаарда - Назаир'),
            (10, 17, 0.041, 'Вассальное государство Нильфгаарда - Метиина'),
            (10, 18, 0.041, 'Вассальное государство Нильфгаарда - Маг Турга'),
            (10, 19, 0.041, 'Вассальное государство Нильфгаарда - Гесо'),
            (10, 20, 0.041, 'Вассальное государство Нильфгаарда - Эббинг'),
            (10, 21, 0.041, 'Вассальное государство Нильфгаарда - Мехт'),
            (10, 22, 0.041, 'Вассальное государство Нильфгаарда - Геммера'),
            (10, 23, 0.041, 'Вассальное государство Нильфгаарда - Этолия'),
            (10, 24, 0.041, 'Вассальное государство Нильфгаарда - Туссент'),
            (10, 25, 0.0, 'Другое'),

            -- group 11: Недача - Долг (o1)
            (11, 1, 0.1, 'Долг 100 крон'),
            (11, 2, 0.1, 'Долг 200 крон'),
            (11, 3, 0.1, 'Долг 300 крон'),
            (11, 4, 0.1, 'Долг 400 крон'),
            (11, 5, 0.1, 'Долг 500 крон'),
            (11, 6, 0.1, 'Долг 600 крон'),
            (11, 7, 0.1, 'Долг 700 крон'),
            (11, 8, 0.1, 'Долг 800 крон'),
            (11, 9, 0.1, 'Долг 900 крон'),
            (11, 10, 0.1, 'Долг 1000 крон'),

            -- group 12: Недача - Заключение (o2)
            (12, 1, 0.1, 'Отсидели в тюрьме 1 месяц'),
            (12, 2, 0.1, 'Отсидели в тюрьме 2 месяца'),
            (12, 3, 0.1, 'Отсидели в тюрьме 3 месяца'),
            (12, 4, 0.1, 'Отсидели в тюрьме 4 месяца'),
            (12, 5, 0.1, 'Отсидели в тюрьме 5 месяцев'),
            (12, 6, 0.1, 'Отсидели в тюрьме 6 месяцев'),
            (12, 7, 0.1, 'Отсидели в тюрьме 7 месяцев'),
            (12, 8, 0.1, 'Отсидели в тюрьме 8 месяцев'),
            (12, 9, 0.1, 'Отсидели в тюрьме 9 месяцев'),
            (12, 10, 0.1, 'Отсидели в тюрьме 10 месяцев'),

            -- group 13: Недача - Зависимость (o3)
            (13, 1, 0.125, 'Алкоголь'),
            (13, 2, 0.125, 'Табак'),
            (13, 3, 0.125, 'Фисштех'),
            (13, 4, 0.125, 'Азартные игры'),
            (13, 5, 0.125, 'Клептомания'),
            (13, 6, 0.125, 'Похоть'),
            (13, 7, 0.125, 'Обжорство'),
            (13, 8, 0.125, 'Адреналиновая зависимость'),
            (13, 10, 0.0, 'Другое (можете придумать сами)'),

            -- group 14: Недача - Любимый, друг или родственнник убит (o4)
            (14, 1, 0.5, 'Это был несчастный случай'),
            (14, 2, 0.3, 'Убит чудовищами'),
            (14, 3, 0.2, 'Убит разбойниками'),

            -- group 15: Недача - Ложное обвинение (o5)
            (15, 1, 0.3, 'Воровство'),
            (15, 2, 0.2, 'Трусость или предательство'),
            (15, 3, 0.3, 'Убийство'),
            (15, 4, 0.3, 'Изнасилование'),
            (15, 5, 0.3, 'Нелегальное колдовство'),

            -- group 16: Недача - В розыске (o6)
            (16, 1, 0.3, 'Вас разыскивают несколько стражников'),
            (16, 2, 0.3, 'Вас разыскивают в посёлке'),
            (16, 3, 0.2, 'Вас разыскивают в городе'),
            (16, 4, 0.2, 'Вас разыскивают во всём королевстве'),

            -- group 17: Недача - Предательство (o7)
            (17, 1, 0.3, 'Вас шантажируют'),
            (17, 2, 0.4, 'Ваша тайна раскрыта'),
            (17, 3, 0.3, 'Вас предал ктото из близких'),

            -- group 18: Недача - Несчастный случай (o8)
            (18, 1, 0.4, 'Вы изуродованы, измените ваш социальный статус на <i>опасение</i>'),
            (18, 2, 0.2, 'Вы лечились от 1 до 10 месяцев'),
            (18, 3, 0.2, 'Вы потеряли память о нескольких (от 1 до 10) месяцах того года'),
            (18, 4, 0.2, 'Вас мучают жуткие кошмары'),

            -- group 19: Недача - Физическая или психическая травма (o9)
            (19, 1, 0.3, 'Вас отравили, навсегда потеряйте 5 ПЗ.'),
            (19, 2, 0.4, 'Вы страдаете от панических атак и должны совершать испытание Устойчивости (каждые 5 раундов) в стрессовой ситуации.'),
            (19, 3, 0.3, 'У вас серьёзное душевное расстройство, вы агрессивны, иррациональны и депрессивны, а также слышите голоса, за которые отвечает ведущий.'),

            -- group 20: Недача - Проклятие (o10)
            (20, 1, 0.2, '<b style="font-size: 1.17em;">Проклятие чудовищности</b><br><b>Интенсивность:</b> Средняя<br><b>Эффект:</b> Жертва выглядит чудовищно для всех, кто её видит. Она остаётся гуманоидом, но черты лица приобретают сходство со случайным животным. Сделайте бросок IdlO, чтобы узнать, что это за животное: 1 или 2 — медведь, 3 или 4 — кабан, 5 или 6 — птица, 7 или 8 — змея, 9 или 10 — насекомое. Социальный статус проклятого меняется на «ненависть и опасение» вне зависимости от того, каким он был раньше. Проклятый на самом деле не является чудовищем и не получает урона от серебра, но с виду похож на чудовище, и его можно спутать с чудовищем, если провалить проверку Образования со СЛ 18.'),
            (20, 2, 0.2, '<b style="font-size: 1.17em;">Проклятие призраков</b><br><b>Интенсивность:</b> Средняя<br><b>Эффект:</b> Действует только на зону, призывая в виде призраков всех, к кому в этом месте отнеслись несправедливо. При создании этого проклятия сделайте бросок 5d6, чтобы определить, сколько призраков явится. Если зона особенно ужасна, бросьте дополнительно 2d6. Если зона достаточно спокойная, бросьте только 2d6. Призраки остаются в зоне до тех пор, пока не будут убиты, и возвращаются на следующую ночь. Они нападают на всё, что входит в зону действия проклятия. Единственный способ снять проклятие — каким-то образом исправить всю ту несправедливость, что случилась в этой зоне.'),
            (20, 3, 0.2, '<b style="font-size: 1.17em;">Проклятие заразы</b><br><b>Интенсивность:</b> Высокая<br><b>Эффект:</b> Делает жертву проклятия носителем опасной болезни. Болезнь не влияет на носителя, но любой, кто дотронется до него и провалит проверку Стойкости со СЛ 18, заражается. Если носитель остаётся в здании дольше 3 дней, то все, кто находится в этом здании, должны пройти проверку Стойкости со СЛ 16. Если носитель проводит в городе больше недели, то все в городе должны совершить проверку Стойкости со СЛ 14.'),
            (20, 4, 0.2, '<b style="font-size: 1.17em;">Проклятие странника</b><br><b>Интенсивность:</b> Высокая<br><b>Эффект:</b> Одно из самых жестоких проклятий. Самой жертве оно вреда не причиняет, но даже самый верный друг, близкий родственник или товарищ от неё отвернётся. Постепенно люди покидают жертву из-за разногласий, ссор, по естественным причинам или из-за похищений, пока (если носитель проклятия дольше месяца остаётся на одном месте) сама судьба не попытается убить несчастного.'),
            (20, 5, 0.2, '<b style="font-size: 1.17em;">Проклятие ликантропии</b><br><b>Интенсивность:</b> Высокая<br><b>Эффект:</b> Проклятый ликантропией с вероятностью 30 % каждую ночь на восходе луны превращается в волколака. После превращения персонаж становится жестоким хищником с человеческой хитростью и с желанием убивать. Если обратившийся — персонаж игрока, то до восхода солнца им управляет ведущий. Будучи волколаком, персонаж потакает самым ужасным своим порывам, без жалости убивая любого, кто встанет на пути. Находясь в зверином облике, проклятый получает всё оружие, броню и способности волколака. Персонаж также прибавляет бонус к четырём своим параметрам, как указано ниже.<br><b>Бонусы волколака:</b> Реакция +2, Телосложение +3, Скорость +4, Эмпатия -5'),
            (20, 6, 0.2, '<b style="font-size: 1.17em;">Проклятие айлурантропии</b><br><b>Интенсивность:</b> Высокая<br><b>Эффект:</b> Персонаж, страдающий айлурантропией, имеет 30% шанс превратиться в котолака каждую ночь, когда восходит луна. В своей форме котолака персонаж представляет собой злого, хитрого хищника с жаждою убивать. Если персонаж является игровым персонажем, он переходит в управление Мастера до восхода солнца. Находясь в зверином состоянии, айлурантроп обладает всем оружием, доспехами, уязвимостями и способностями котолака. Персонаж также прибавляет бонус к четырём своим параметрам, как указано ниже.<br><b>Бонусы котолака:</b> Реакция +2, Телосложение +1, Ловкость +2, Скорость +5, Эмпатия -5'),
            (20, 7, 0.0, '<b style="font-size: 1.17em;">Другое</b><br>Придумайте собственное!')
          ) AS raw_data_ru(group_id, num, probability, option_txt)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
            -- group 1: Fortune — Jackpot (o1)
            (1, 1, 0.1, 'Receive 100 crowns'),
            (1, 2, 0.1, 'Receive 200 crowns'),
            (1, 3, 0.1, 'Receive 300 crowns'),
            (1, 4, 0.1, 'Receive 400 crowns'),
            (1, 5, 0.1, 'Receive 500 crowns'),
            (1, 6, 0.1, 'Receive 600 crowns'),
            (1, 7, 0.1, 'Receive 700 crowns'),
            (1, 8, 0.1, 'Receive 800 crowns'),
            (1, 9, 0.1, 'Receive 900 crowns'),
            (1, 10, 0.1, 'Receive 1,000 crowns'),

            -- group 2: Fortune — Find a Teacher (o2) - INT skills
            (2, 1, 0.0909, 'Awareness'),
            (2, 2, 0.0909, 'Wilderness Survival'),
            (2, 3, 0.0909, 'Deduction'),
            (2, 4, 0.0909, 'Monster Lore'),
            (2, 5, 0.0909, 'Education'),
            (2, 6, 0.0909, 'Streetwise'),
            (2, 7, 0.0909, 'Teaching'),
            (2, 8, 0.0909, 'Tactics'),
            (2, 9, 0.0909, 'Business'),
            (2, 10, 0.0909, 'Social Etiquette'),
            (2, 11, 0.0303, 'Language - Common Speech'),
            (2, 12, 0.0303, 'Language - Dwarvish'),
            (2, 13, 0.0303, 'Language - Elder Speech'),

            -- group 4: Fortune — Find a Combat Teacher (o4) - combat skills
            (4, 1, 0.1, 'Athletics'),
            (4, 2, 0.1, 'Melee'),
            (4, 3, 0.1, 'Brawling'),
            (4, 4, 0.1, 'Riding'),
            (4, 5, 0.1, 'Staff'),
            (4, 6, 0.1, 'Small Blades'),
            (4, 7, 0.1, 'Swordsmanship'),
            (4, 8, 0.1, 'Crossbow'),
            (4, 9, 0.1, 'Archery'),
            (4, 10, 0.1, 'Tactics'),

            -- group 7: Fortune — Tamed a Wild Animal (o7)
            (7, 1, 0.7, 'Wild Dog'),
            (7, 2, 0.3, 'Wolf'),

            -- group 10: Fortune — Knighted (o10) - kingdoms
            (10, 1, 0.041, 'Redania'),
            (10, 2, 0.041, 'Kaedwen'),
            (10, 3, 0.041, 'Temeria'),
            (10, 4, 0.041, 'Aedirn'),
            (10, 5, 0.041, 'Lyria'),
            (10, 6, 0.041, 'Rivia'),
            (10, 7, 0.041, 'Kovir'),
            (10, 8, 0.041, 'Poviss'),
            (10, 9, 0.041, 'Skellige'),
            (10, 10, 0.041, 'Cidaris'),
            (10, 11, 0.041, 'Verden'),
            (10, 12, 0.041, 'Cintra'),
            (10, 13, 0.041, 'The Heart of Nilfgaard'),
            (10, 14, 0.041, 'Nilfgaardian Vassal State - Vicovaro'),
            (10, 15, 0.041, 'Nilfgaardian Vassal State - Angren'),
            (10, 16, 0.041, 'Nilfgaardian Vassal State - Nazair'),
            (10, 17, 0.041, 'Nilfgaardian Vassal State - Mettina'),
            (10, 18, 0.041, 'Nilfgaardian Vassal State - Mag Turga'),
            (10, 19, 0.041, 'Nilfgaardian Vassal State - Gheso'),
            (10, 20, 0.041, 'Nilfgaardian Vassal State - Ebbing'),
            (10, 21, 0.041, 'Nilfgaardian Vassal State - Maecht'),
            (10, 22, 0.041, 'Nilfgaardian Vassal State - Gemmeria'),
            (10, 23, 0.041, 'Nilfgaardian Vassal State - Etolia'),
            (10, 24, 0.041, 'Nilfgaardian Vassal State - Toussaint'),
            (10, 25, 0.0, 'Other'),

            -- group 11: Misfortune — Debt (o1)
            (11, 1, 0.1, 'Debt 100 crowns'),
            (11, 2, 0.1, 'Debt 200 crowns'),
            (11, 3, 0.1, 'Debt 300 crowns'),
            (11, 4, 0.1, 'Debt 400 crowns'),
            (11, 5, 0.1, 'Debt 500 crowns'),
            (11, 6, 0.1, 'Debt 600 crowns'),
            (11, 7, 0.1, 'Debt 700 crowns'),
            (11, 8, 0.1, 'Debt 800 crowns'),
            (11, 9, 0.1, 'Debt 900 crowns'),
            (11, 10, 0.1, 'Debt 1,000 crowns'),

            -- group 12: Misfortune — Imprisonment (o2)
            (12, 1, 0.1, 'You served 1 month in prison'),
            (12, 2, 0.1, 'You served 2 months in prison'),
            (12, 3, 0.1, 'You served 3 months in prison'),
            (12, 4, 0.1, 'You served 4 months in prison'),
            (12, 5, 0.1, 'You served 5 months in prison'),
            (12, 6, 0.1, 'You served 6 months in prison'),
            (12, 7, 0.1, 'You served 7 months in prison'),
            (12, 8, 0.1, 'You served 8 months in prison'),
            (12, 9, 0.1, 'You served 9 months in prison'),
            (12, 10, 0.1, 'You served 10 months in prison'),

            -- group 13: Misfortune — Addiction (o3)
            (13, 1, 0.125, 'Alcohol'),
            (13, 2, 0.125, 'Tobacco'),
            (13, 3, 0.125, 'Fisstech'),
            (13, 4, 0.125, 'Gambling'),
            (13, 5, 0.125, 'Kleptomania'),
            (13, 6, 0.125, 'Lust'),
            (13, 7, 0.125, 'Gluttony'),
            (13, 8, 0.125, 'Adrenaline addiction'),
            (13, 10, 0.0,  'Other (create your own)'),

            -- group 14: Misfortune — Lover, Friend or Relative Killed (o4)
            (14, 1, 0.5, 'It was an accident'),
            (14, 2, 0.3, 'Murdered by monsters'),
            (14, 3, 0.2, 'Murdered by bandits'),

            -- group 15: Misfortune — False Accusation (o5)
            (15, 1, 0.3, 'Theft'),
            (15, 2, 0.2, 'Cowardice or betrayal'),
            (15, 3, 0.3, 'Murder'),
            (15, 4, 0.3, 'Rape'),
            (15, 5, 0.3, 'Illegal witchcraft'),

            -- group 16: Misfortune — Wanted (o6)
            (16, 1, 0.3, 'Wanted by a few guards'),
            (16, 2, 0.3, 'Wanted in a village'),
            (16, 3, 0.2, 'Wanted in a major city'),
            (16, 4, 0.2, 'Wanted throughout the entire kingdom'),

            -- group 17: Misfortune — Betrayal (o7)
            (17, 1, 0.3, 'You are being blackmailed'),
            (17, 2, 0.4, 'Your secret was exposed'),
            (17, 3, 0.3, 'You were betrayed by someone close'),

            -- group 18: Misfortune — Accident (o8)
            (18, 1, 0.4, 'You were disfigured; change your social status to <i>Feared</i>'),
            (18, 2, 0.2, 'You were recovering for a period of 1 to 10 months'),
            (18, 3, 0.2, 'You lost several (1 to 10) months of memory from that year'),
            (18, 4, 0.2, 'You suffer dreadful nightmares'),

            -- group 19: Misfortune — Physical or Mental Trauma (o9)
            (19, 1, 0.3, 'You were poisoned; permanently lose 5 HP'),
            (19, 2, 0.4, 'You suffer panic attacks and must make Stun saves (every 5 rounds) in stressful situations'),
            (19, 3, 0.3, 'You have a severe mental disorder; you are aggressive, irrational, and depressive, and you hear voices controlled by the GM'),

            -- group 20: Misfortune — Curse (o10)
            (20, 1, 0.2, '<b style="font-size: 1.17em;">Curse of Monstrosity</b><br><b>Intensity:</b> Moderate<br><b>Effect:</b> The victim appears monstrous to all who see them. They remain humanoid, but their features resemble a random animal. Roll 1d10 to determine the animal: 1–2 bear, 3–4 boar, 5–6 bird, 7–8 snake, 9–10 insect. The victim’s social status becomes “Hated & Feared.” They are not actually a monster and do not take damage from silver, but can be mistaken for one on a failed Education check DC 18.'),
            (20, 2, 0.2, '<b style="font-size: 1.17em;">Curse of Phantoms</b><br><b>Intensity:</b> Moderate<br><b>Effect:</b> Affects an area, summoning as ghosts all who were wronged there. When casting, roll 5d6 to determine how many appear (add 2d6 if the area is especially horrific; only 2d6 if it is rather calm). Ghosts remain until destroyed and return the next night. They attack anything entering the cursed zone. The only way to lift the curse is to somehow right all the wrongs done there.'),
            (20, 3, 0.2, '<b style="font-size: 1.17em;">Curse of Pestilence</b><br><b>Intensity:</b> High<br><b>Effect:</b> The victim becomes a carrier of a dangerous disease. It does not affect the carrier, but anyone who touches them and fails a Physique check DC 18 is infected. If the carrier stays inside a building for more than 3 days, everyone inside must make a Physique check DC 16. If the carrier remains in a city for more than a week, everyone in the city must make a Physique check DC 14.'),
            (20, 4, 0.2, '<b style="font-size: 1.17em;">Curse of the Wanderer</b><br><b>Intensity:</b> High<br><b>Effect:</b> One of the cruelest curses. It does not harm the victim directly, but even the truest friend or closest kin will eventually abandon them. People drift away due to quarrels, distance, circumstance, or kidnappings until—if the victim stays in one place longer than a month—fate itself tries to kill them.'),
            (20, 5, 0.2, '<b style="font-size: 1.17em;">Curse of Lycanthropy</b><br><b>Intensity:</b> High<br><b>Effect:</b> Each night at moonrise there is a 30% chance the victim transforms into a werewolf. While transformed, the character becomes a brutal predator with human cunning and a lust for killing. If it is a PC, the GM controls them until sunrise. In beast form, the character gains the werewolf’s weapons, armor, and abilities plus the following bonuses:<br><b>Werewolf Bonuses:</b> Reflex +2, Body +3, Speed +4, Empathy −5'),
            (20, 6, 0.2, '<b style="font-size: 1.17em;">Curse of Ailuranthropy</b><br><b>Intensity:</b> High<br><b>Effect:</b> A character afflicted with ailuranthropy has a 30% chance of changing into a werecat every night, when the moon rises. In their werecat form, they are a vicious, cunning predator with an urge to kill. If the character is a player character, they are taken over by the Game Master until the sun rises. While in their beast state, the ailuranthrope has all of the werecat’s weapons, armor, vulnerabilities, and abilities. The character also augments their statistics with the following changes. They increase their Body Statistic by 1, their Reflex and Dexterity Statistics by 2, and their Speed Statistic by 5. Additionally, they lower their Empathy Statistic by 5.<br><b>Werecat Bonuses:</b> Reflex +2, Body +1, Dexterity +2, Speed +5, Empathy −5'),
            (20, 7, 0.0,  '<b style="font-size: 1.17em;">Other</b><br>Create your own!')
          ) AS raw_data_en(group_id, num, probability, option_txt)

),
vals AS (
         SELECT ('<td>' || to_char(probability*100, 'FM990.00') || '%</td>' ||
                 '<td>' || option_txt || '</td>') AS text,
                num,
                probability,
                lang,
                group_id
         FROM raw_data
)
, meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_fortune_or_not_details' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, ins_label AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*vals.group_id+vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
                     , meta.entity, meta.entity_field, vals.lang, vals.text
                  FROM vals
                  CROSS JOIN meta
)
, rules_vals(group_id, id, body) AS (
    SELECT v.num
         , gen_random_uuid()
         , ('{
               "and":
                 [
                   { "==":
                       [
                         { "var": "answers.lastAnswer.questionId" },
                         "wcc_life_events_' || case when v.num > 10 then 'mis' else '' end
                                            || 'fortune"
                       ]
                   },
                   { "in":
                       [
                         "wcc_life_events_' || case when v.num > 10 then 'mis' else '' end
                                            || 'fortune_o'
                                            || to_char(case when v.num > 10 then v.num - 10 else v.num end, 'FM00')
                                            || '" ,
                         { "var": "answers.lastAnswer.answerIds" }
                       ]
                   }
                 ]
             }')::jsonb FROM (SELECT DISTINCT group_id FROM raw_data) v(num)
)
, ins_rules AS (
  INSERT INTO rules(ru_id, body) SELECT r.id, r.body FROM rules_vals r
)
INSERT INTO answer_options (an_id, su_su_id, dlc_dlc_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT 'wcc_life_events_fortune_or_not_details_o' || to_char(vals.group_id, 'FM00') || to_char(vals.num, 'FM00') AS an_id,
       meta.su_su_id,
       CASE
         WHEN vals.group_id = 20 AND vals.num = 6 THEN 'dlc_sh_mothr'
         ELSE 'core'
       END AS dlc_dlc_id,
       meta.qu_id,
       ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*vals.group_id+vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
       vals.num AS sort_order,
       rules_vals.id AS visible_ru_ru_id,
       jsonb_build_object(
           'probability', vals.probability
       ) || CASE WHEN to_char(vals.group_id, 'FM00') || to_char(vals.num, 'FM00')
                  IN ('1802','1803','1310','2001','2007') THEN '{}'::jsonb
                  ELSE jsonb_build_object( 'counterIncrement'
                                         , jsonb_build_object('id', 'lifeEventsCounter', 'step', 10))
           END AS metadata
FROM vals
CROSS JOIN meta
LEFT JOIN rules_vals ON rules_vals.group_id = vals.group_id
ON CONFLICT (an_id) DO NOTHING;

-- Эффекты
WITH
  raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
            -- group 1: Удача - Джекпот (o1)
            (1, 1, 0.1, 'Получаете 100 крон'),
            (1, 2, 0.1, 'Получаете 200 крон'),
            (1, 3, 0.1, 'Получаете 300 крон'),
            (1, 4, 0.1, 'Получаете 400 крон'),
            (1, 5, 0.1, 'Получаете 500 крон'),
            (1, 6, 0.1, 'Получаете 600 крон'),
            (1, 7, 0.1, 'Получаете 700 крон'),
            (1, 8, 0.1, 'Получаете 800 крон'),
            (1, 9, 0.1, 'Получаете 900 крон'),
            (1, 10, 0.1, 'Получаете 1000 крон'),

            -- group 2: Удача - Учитель (o2) - навыки интеллекта
            (2, 1, 0.0909, 'Внимание'),
            (2, 2, 0.0909, 'Выживание в дикой природе'),
            (2, 3, 0.0909, 'Дедукция'),
            (2, 4, 0.0909, 'Монстрология'),
            (2, 5, 0.0909, 'Образование'),
            (2, 6, 0.0909, 'Ориентирование в городе'),
            (2, 7, 0.0909, 'Передача знаний'),
            (2, 8, 0.0909, 'Тактика'),
            (2, 9, 0.0909, 'Торговля'),
            (2, 10, 0.0909, 'Этикет'),
            (2, 11, 0.0303, 'Язык - северный'),
            (2, 12, 0.0303, 'Язык - дварфийский'),
            (2, 13, 0.0303, 'Язык - старшая речь'),

            -- group 4: Удача - Боевой инструктор (o4) - боевые навыки
            (4, 1, 0.1, 'Атлетика'),
            (4, 2, 0.1, 'Ближний бой'),
            (4, 3, 0.1, 'Борьба'),
            (4, 4, 0.1, 'Верховая езда'),
            (4, 5, 0.1, 'Владение древковым оружием'),
            (4, 6, 0.1, 'Владение лёгкими клинками'),
            (4, 7, 0.1, 'Владение мечом'),
            (4, 8, 0.1, 'Стрельба из арбалета'),
            (4, 9, 0.1, 'Стрельба из лука'),
            (4, 10, 0.1, 'Тактика'),

            -- group 7: Удача - Прирученный зверь (o7)
            (7, 1, 0.7, 'Дикая собака'),
            (7, 2, 0.3, 'Волк'),

            -- group 10: Удача - Рыцарство (o10) - королевства
            (10, 1, 0.041, 'Редания'),
            (10, 2, 0.041, 'Каэдвен'),
            (10, 3, 0.041, 'Темерия'),
            (10, 4, 0.041, 'Аэдирн'),
            (10, 5, 0.041, 'Лирия'),
            (10, 6, 0.041, 'Ривия'),
            (10, 7, 0.041, 'Ковир'),
            (10, 8, 0.041, 'Повис'),
            (10, 9, 0.041, 'Скеллиге'),
            (10, 10, 0.041, 'Цидарис'),
            (10, 11, 0.041, 'Вердэн'),
            (10, 12, 0.041, 'Цинтра'),
            (10, 13, 0.041, 'Сердце Нильфгаарда'),
            (10, 14, 0.041, 'Вассальное государство Нильфгаарда - Виковаро'),
            (10, 15, 0.041, 'Вассальное государство Нильфгаарда - Аигрен'),
            (10, 16, 0.041, 'Вассальное государство Нильфгаарда - Назаир'),
            (10, 17, 0.041, 'Вассальное государство Нильфгаарда - Метиина'),
            (10, 18, 0.041, 'Вассальное государство Нильфгаарда - Маг Турга'),
            (10, 19, 0.041, 'Вассальное государство Нильфгаарда - Гесо'),
            (10, 20, 0.041, 'Вассальное государство Нильфгаарда - Эббинг'),
            (10, 21, 0.041, 'Вассальное государство Нильфгаарда - Мехт'),
            (10, 22, 0.041, 'Вассальное государство Нильфгаарда - Геммера'),
            (10, 23, 0.041, 'Вассальное государство Нильфгаарда - Этолия'),
            (10, 24, 0.041, 'Вассальное государство Нильфгаарда - Туссент'),
            (10, 25, 0.0, 'Другое'),

            -- group 11: Недача - Долг (o1)
            (11, 1, 0.1, 'Долг 100 крон'),
            (11, 2, 0.1, 'Долг 200 крон'),
            (11, 3, 0.1, 'Долг 300 крон'),
            (11, 4, 0.1, 'Долг 400 крон'),
            (11, 5, 0.1, 'Долг 500 крон'),
            (11, 6, 0.1, 'Долг 600 крон'),
            (11, 7, 0.1, 'Долг 700 крон'),
            (11, 8, 0.1, 'Долг 800 крон'),
            (11, 9, 0.1, 'Долг 900 крон'),
            (11, 10, 0.1, 'Долг 1000 крон'),

            -- group 12: Недача - Заключение (o2)
            (12, 1, 0.1, 'Отсидели в тюрьме 1 месяц'),
            (12, 2, 0.1, 'Отсидели в тюрьме 2 месяца'),
            (12, 3, 0.1, 'Отсидели в тюрьме 3 месяца'),
            (12, 4, 0.1, 'Отсидели в тюрьме 4 месяца'),
            (12, 5, 0.1, 'Отсидели в тюрьме 5 месяцев'),
            (12, 6, 0.1, 'Отсидели в тюрьме 6 месяцев'),
            (12, 7, 0.1, 'Отсидели в тюрьме 7 месяцев'),
            (12, 8, 0.1, 'Отсидели в тюрьме 8 месяцев'),
            (12, 9, 0.1, 'Отсидели в тюрьме 9 месяцев'),
            (12, 10, 0.1, 'Отсидели в тюрьме 10 месяцев'),

            -- group 13: Недача - Зависимость (o3)
            (13, 1, 0.125, 'Алкоголь'),
            (13, 2, 0.125, 'Табак'),
            (13, 3, 0.125, 'Фисштех'),
            (13, 4, 0.125, 'Азартные игры'),
            (13, 5, 0.125, 'Клептомания'),
            (13, 6, 0.125, 'Похоть'),
            (13, 7, 0.125, 'Обжорство'),
            (13, 8, 0.125, 'Адреналиновая зависимость'),
            (13, 10, 0.0, 'Другое (можете придумать сами)'),

            -- group 14: Недача - Любимый, друг или родственнник убит (o4)
            (14, 1, 0.5, 'Это был несчастный случай'),
            (14, 2, 0.3, 'Убит чудовищами'),
            (14, 3, 0.2, 'Убит разбойниками'),

            -- group 15: Недача - Ложное обвинение (o5)
            (15, 1, 0.3, 'Воровство'),
            (15, 2, 0.2, 'Трусость или предательство'),
            (15, 3, 0.3, 'Убийство'),
            (15, 4, 0.3, 'Изнасилование'),
            (15, 5, 0.3, 'Нелегальное колдовство'),

            -- group 16: Недача - В розыске (o6)
            (16, 1, 0.3, 'Вас разыскивают несколько стражников'),
            (16, 2, 0.3, 'Вас разыскивают в посёлке'),
            (16, 3, 0.2, 'Вас разыскивают в городе'),
            (16, 4, 0.2, 'Вас разыскивают во всём королевстве'),

            -- group 17: Недача - Предательство (o7)
            (17, 1, 0.3, 'Вас шантажируют'),
            (17, 2, 0.4, 'Ваша тайна раскрыта'),
            (17, 3, 0.3, 'Вас предал ктото из близких'),

            -- group 18: Недача - Несчастный случай (o8)
            (18, 1, 0.4, 'Вы изуродованы, измените ваш социальный статус на <i>опасение</i>'),
            (18, 2, 0.2, 'Вы лечились от 1 до 10 месяцев'),
            (18, 3, 0.2, 'Вы потеряли память о нескольких (от 1 до 10) месяцах того года'),
            (18, 4, 0.2, 'Вас мучают жуткие кошмары'),

            -- group 19: Недача - Физическая или психическая травма (o9)
            (19, 1, 0.3, 'Вас отравили, навсегда потеряйте 5 ПЗ.'),
            (19, 2, 0.4, 'Вы страдаете от панических атак и должны совершать испытание Устойчивости (каждые 5 раундов) в стрессовой ситуации.'),
            (19, 3, 0.3, 'У вас серьёзное душевное расстройство, вы агрессивны, иррациональны и депрессивны, а также слышите голоса, за которые отвечает ведущий.'),

            -- group 20: Недача - Проклятие (o10)
            (20, 1, 0.2, '<b style="font-size: 1.17em;">Проклятие чудовищности</b><br><b>Интенсивность:</b> Средняя<br><b>Эффект:</b> Жертва выглядит чудовищно для всех, кто её видит. Она остаётся гуманоидом, но черты лица приобретают сходство со случайным животным. Сделайте бросок IdlO, чтобы узнать, что это за животное: 1 или 2 — медведь, 3 или 4 — кабан, 5 или 6 — птица, 7 или 8 — змея, 9 или 10 — насекомое. Социальный статус проклятого меняется на «ненависть и опасение» вне зависимости от того, каким он был раньше. Проклятый на самом деле не является чудовищем и не получает урона от серебра, но с виду похож на чудовище, и его можно спутать с чудовищем, если провалить проверку Образования со СЛ 18.'),
            (20, 2, 0.2, '<b style="font-size: 1.17em;">Проклятие призраков</b><br><b>Интенсивность:</b> Средняя<br><b>Эффект:</b> Действует только на зону, призывая в виде призраков всех, к кому в этом месте отнеслись несправедливо. При создании этого проклятия сделайте бросок 5d6, чтобы определить, сколько призраков явится. Если зона особенно ужасна, бросьте дополнительно 2d6. Если зона достаточно спокойная, бросьте только 2d6. Призраки остаются в зоне до тех пор, пока не будут убиты, и возвращаются на следующую ночь. Они нападают на всё, что входит в зону действия проклятия. Единственный способ снять проклятие — каким-то образом исправить всю ту несправедливость, что случилась в этой зоне.'),
            (20, 3, 0.2, '<b style="font-size: 1.17em;">Проклятие заразы</b><br><b>Интенсивность:</b> Высокая<br><b>Эффект:</b> Делает жертву проклятия носителем опасной болезни. Болезнь не влияет на носителя, но любой, кто дотронется до него и провалит проверку Стойкости со СЛ 18, заражается. Если носитель остаётся в здании дольше 3 дней, то все, кто находится в этом здании, должны пройти проверку Стойкости со СЛ 16. Если носитель проводит в городе больше недели, то все в городе должны совершить проверку Стойкости со СЛ 14.'),
            (20, 4, 0.2, '<b style="font-size: 1.17em;">Проклятие странника</b><br><b>Интенсивность:</b> Высокая<br><b>Эффект:</b> Одно из самых жестоких проклятий. Самой жертве оно вреда не причиняет, но даже самый верный друг, близкий родственник или товарищ от неё отвернётся. Постепенно люди покидают жертву из-за разногласий, ссор, по естественным причинам или из-за похищений, пока (если носитель проклятия дольше месяца остаётся на одном месте) сама судьба не попытается убить несчастного.'),
            (20, 5, 0.2, '<b style="font-size: 1.17em;">Проклятие ликантропии</b><br><b>Интенсивность:</b> Высокая<br><b>Эффект:</b> Проклятый ликантропией с вероятностью 30 % каждую ночь на восходе луны превращается в волколака. После превращения персонаж становится жестоким хищником с человеческой хитростью и с желанием убивать. Если обратившийся — персонаж игрока, то до восхода солнца им управляет ведущий. Будучи волколаком, персонаж потакает самым ужасным своим порывам, без жалости убивая любого, кто встанет на пути. Находясь в зверином облике, проклятый получает всё оружие, броню и способности волколака. Персонаж также прибавляет бонус к четырём своим параметрам, как указано ниже.<br><b>Бонусы волколака:</b> Реакция +2, Телосложение +3, Скорость +4, Эмпатия -5'),
            (20, 6, 0.2, '<b style="font-size: 1.17em;">Проклятие аилурантропии</b><br><b>Интенсивность:</b> Высокая<br><b>Эффект:</b> Персонаж, страдающий айлурантропией, имеет 30% шанс превратиться в котолака каждую ночь, когда восходит луна. В своей форме котолака персонаж представляет собой злого, хитрого хищника с жаждою убивать. Если персонаж является игровым персонажем, он переходит в управление Мастера до восхода солнца. Находясь в зверином состоянии, айлурантроп обладает всем оружием, доспехами, уязвимостями и способностями котолака. Персонаж также прибавляет бонус к четырём своим параметрам, как указано ниже.<br><b>Бонусы котолака:</b> Реакция +2, Телосложение +1, Ловкость +2, Скорость +5, Эмпатия -5'),
            (20, 7, 0.0, '<b style="font-size: 1.17em;">Другое</b><br>Придумайте собственное!')
          ) AS raw_data_ru(group_id, num, probability, option_txt)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
            -- group 1: Fortune — Jackpot (o1)
            (1, 1, 0.1, 'Receive 100 crowns'),
            (1, 2, 0.1, 'Receive 200 crowns'),
            (1, 3, 0.1, 'Receive 300 crowns'),
            (1, 4, 0.1, 'Receive 400 crowns'),
            (1, 5, 0.1, 'Receive 500 crowns'),
            (1, 6, 0.1, 'Receive 600 crowns'),
            (1, 7, 0.1, 'Receive 700 crowns'),
            (1, 8, 0.1, 'Receive 800 crowns'),
            (1, 9, 0.1, 'Receive 900 crowns'),
            (1, 10, 0.1, 'Receive 1,000 crowns'),

            -- group 2: Fortune — Find a Teacher (o2) - INT skills
            (2, 1, 0.0909, 'Awareness'),
            (2, 2, 0.0909, 'Wilderness Survival'),
            (2, 3, 0.0909, 'Deduction'),
            (2, 4, 0.0909, 'Monster Lore'),
            (2, 5, 0.0909, 'Education'),
            (2, 6, 0.0909, 'Streetwise'),
            (2, 7, 0.0909, 'Teaching'),
            (2, 8, 0.0909, 'Tactics'),
            (2, 9, 0.0909, 'Business'),
            (2, 10, 0.0909, 'Social Etiquette'),
            (2, 11, 0.0303, 'Language - Common Speech'),
            (2, 12, 0.0303, 'Language - Dwarvish'),
            (2, 13, 0.0303, 'Language - Elder Speech'),

            -- group 4: Fortune — Find a Combat Teacher (o4) - combat skills
            (4, 1, 0.1, 'Athletics'),
            (4, 2, 0.1, 'Melee'),
            (4, 3, 0.1, 'Brawling'),
            (4, 4, 0.1, 'Riding'),
            (4, 5, 0.1, 'Staff'),
            (4, 6, 0.1, 'Small Blades'),
            (4, 7, 0.1, 'Swordsmanship'),
            (4, 8, 0.1, 'Crossbow'),
            (4, 9, 0.1, 'Archery'),
            (4, 10, 0.1, 'Tactics'),

            -- group 7: Fortune — Tamed a Wild Animal (o7)
            (7, 1, 0.7, 'Wild Dog'),
            (7, 2, 0.3, 'Wolf'),

            -- group 10: Fortune — Knighted (o10) - kingdoms
            (10, 1, 0.041, 'Redania'),
            (10, 2, 0.041, 'Kaedwen'),
            (10, 3, 0.041, 'Temeria'),
            (10, 4, 0.041, 'Aedirn'),
            (10, 5, 0.041, 'Lyria'),
            (10, 6, 0.041, 'Rivia'),
            (10, 7, 0.041, 'Kovir'),
            (10, 8, 0.041, 'Poviss'),
            (10, 9, 0.041, 'Skellige'),
            (10, 10, 0.041, 'Cidaris'),
            (10, 11, 0.041, 'Verden'),
            (10, 12, 0.041, 'Cintra'),
            (10, 13, 0.041, 'The Heart of Nilfgaard'),
            (10, 14, 0.041, 'Nilfgaardian Vassal State - Vicovaro'),
            (10, 15, 0.041, 'Nilfgaardian Vassal State - Angren'),
            (10, 16, 0.041, 'Nilfgaardian Vassal State - Nazair'),
            (10, 17, 0.041, 'Nilfgaardian Vassal State - Mettina'),
            (10, 18, 0.041, 'Nilfgaardian Vassal State - Mag Turga'),
            (10, 19, 0.041, 'Nilfgaardian Vassal State - Gheso'),
            (10, 20, 0.041, 'Nilfgaardian Vassal State - Ebbing'),
            (10, 21, 0.041, 'Nilfgaardian Vassal State - Maecht'),
            (10, 22, 0.041, 'Nilfgaardian Vassal State - Gemmeria'),
            (10, 23, 0.041, 'Nilfgaardian Vassal State - Etolia'),
            (10, 24, 0.041, 'Nilfgaardian Vassal State - Toussaint'),
            (10, 25, 0.0, 'Other'),

            -- group 11: Misfortune — Debt (o1)
            (11, 1, 0.1, 'Debt 100 crowns'),
            (11, 2, 0.1, 'Debt 200 crowns'),
            (11, 3, 0.1, 'Debt 300 crowns'),
            (11, 4, 0.1, 'Debt 400 crowns'),
            (11, 5, 0.1, 'Debt 500 crowns'),
            (11, 6, 0.1, 'Debt 600 crowns'),
            (11, 7, 0.1, 'Debt 700 crowns'),
            (11, 8, 0.1, 'Debt 800 crowns'),
            (11, 9, 0.1, 'Debt 900 crowns'),
            (11, 10, 0.1, 'Debt 1,000 crowns'),

            -- group 12: Misfortune — Imprisonment (o2)
            (12, 1, 0.1, 'You served 1 month in prison'),
            (12, 2, 0.1, 'You served 2 months in prison'),
            (12, 3, 0.1, 'You served 3 months in prison'),
            (12, 4, 0.1, 'You served 4 months in prison'),
            (12, 5, 0.1, 'You served 5 months in prison'),
            (12, 6, 0.1, 'You served 6 months in prison'),
            (12, 7, 0.1, 'You served 7 months in prison'),
            (12, 8, 0.1, 'You served 8 months in prison'),
            (12, 9, 0.1, 'You served 9 months in prison'),
            (12, 10, 0.1, 'You served 10 months in prison'),

            -- group 13: Misfortune — Addiction (o3)
            (13, 1, 0.125, 'Alcohol'),
            (13, 2, 0.125, 'Tobacco'),
            (13, 3, 0.125, 'Fisstech'),
            (13, 4, 0.125, 'Gambling'),
            (13, 5, 0.125, 'Kleptomania'),
            (13, 6, 0.125, 'Lust'),
            (13, 7, 0.125, 'Gluttony'),
            (13, 8, 0.125, 'Adrenaline addiction'),
            (13, 10, 0.0,  'Other (create your own)'),

            -- group 14: Misfortune — Lover, Friend or Relative Killed (o4)
            (14, 1, 0.5, 'It was an accident'),
            (14, 2, 0.3, 'Murdered by monsters'),
            (14, 3, 0.2, 'Murdered by bandits'),

            -- group 15: Misfortune — False Accusation (o5)
            (15, 1, 0.3, 'Theft'),
            (15, 2, 0.2, 'Cowardice or betrayal'),
            (15, 3, 0.3, 'Murder'),
            (15, 4, 0.3, 'Rape'),
            (15, 5, 0.3, 'Illegal witchcraft'),

            -- group 16: Misfortune — Wanted (o6)
            (16, 1, 0.3, 'Wanted by a few guards'),
            (16, 2, 0.3, 'Wanted in a village'),
            (16, 3, 0.2, 'Wanted in a major city'),
            (16, 4, 0.2, 'Wanted throughout the entire kingdom'),

            -- group 17: Misfortune — Betrayal (o7)
            (17, 1, 0.3, 'You are being blackmailed'),
            (17, 2, 0.4, 'Your secret was exposed'),
            (17, 3, 0.3, 'You were betrayed by someone close'),

            -- group 18: Misfortune — Accident (o8)
            (18, 1, 0.4, 'You were disfigured; change your social status to <i>Feared</i>'),
            (18, 2, 0.2, 'You were recovering for a period of 1 to 10 months'),
            (18, 3, 0.2, 'You lost several (1 to 10) months of memory from that year'),
            (18, 4, 0.2, 'You suffer dreadful nightmares'),

            -- group 19: Misfortune — Physical or Mental Trauma (o9)
            (19, 1, 0.3, 'You were poisoned; permanently lose 5 HP'),
            (19, 2, 0.4, 'You suffer panic attacks and must make Stun saves (every 5 rounds) in stressful situations'),
            (19, 3, 0.3, 'You have a severe mental disorder; you are aggressive, irrational, and depressive, and you hear voices controlled by the GM'),

            -- group 20: Misfortune — Curse (o10)
            (20, 1, 0.2, '<b style="font-size: 1.17em;">Curse of Monstrosity</b><br><b>Intensity:</b> Moderate<br><b>Effect:</b> The victim appears monstrous to all who see them. They remain humanoid, but their features resemble a random animal. Roll 1d10 to determine the animal: 1–2 bear, 3–4 boar, 5–6 bird, 7–8 snake, 9–10 insect. The victim''s social status becomes "Hated & Feared." They are not actually a monster and do not take damage from silver, but can be mistaken for one on a failed Education check DC 18.'),
            (20, 2, 0.2, '<b style="font-size: 1.17em;">Curse of Phantoms</b><br><b>Intensity:</b> Moderate<br><b>Effect:</b> Affects an area, summoning as ghosts all who were wronged there. When casting, roll 5d6 to determine how many appear (add 2d6 if the area is especially horrific; only 2d6 if it is rather calm). Ghosts remain until destroyed and return the next night. They attack anything entering the cursed zone. The only way to lift the curse is to somehow right all the wrongs done there.'),
            (20, 3, 0.2, '<b style="font-size: 1.17em;">Curse of Pestilence</b><br><b>Intensity:</b> High<br><b>Effect:</b> The victim becomes a carrier of a dangerous disease. It does not affect the carrier, but anyone who touches them and fails a Physique check DC 18 is infected. If the carrier stays inside a building for more than 3 days, everyone inside must make a Physique check DC 16. If the carrier remains in a city for more than a week, everyone in the city must make a Physique check DC 14.'),
            (20, 4, 0.2, '<b style="font-size: 1.17em;">Curse of the Wanderer</b><br><b>Intensity:</b> High<br><b>Effect:</b> One of the cruelest curses. It does not harm the victim directly, but even the truest friend or closest kin will eventually abandon them. People drift away due to quarrels, distance, circumstance, or kidnappings until—if the victim stays in one place longer than a month—fate itself tries to kill them.'),
            (20, 5, 0.2, '<b style="font-size: 1.17em;">Curse of Lycanthropy</b><br><b>Intensity:</b> High<br><b>Effect:</b> Each night at moonrise there is a 30% chance the victim transforms into a werewolf. While transformed, the character becomes a brutal predator with human cunning and a lust for killing. If it is a PC, the GM controls them until sunrise. In beast form, the character gains the werewolf''s weapons, armor, and abilities plus the following bonuses:<br><b>Werewolf Bonuses:</b> Reflex +2, Body +3, Speed +4, Empathy −5'),
            (20, 6, 0.2, '<b style="font-size: 1.17em;">Curse of Ailuranthropy</b><br><b>Intensity:</b> High<br><b>Effect:</b> A character afflicted with ailuranthropy has a 30% chance of changing into a werecat every night, when the moon rises. In their werecat form, they are a vicious, cunning predator with an urge to kill. If the character is a player character, they are taken over by the Game Master until the sun rises. While in their beast state, the ailuranthrope has all of the werecat’s weapons, armor, vulnerabilities, and abilities. The character also augments their statistics with the following changes. They increase their Body Statistic by 1, their Reflex and Dexterity Statistics by 2, and their Speed Statistic by 5. Additionally, they lower their Empathy Statistic by 5.<br><b>Werecat Bonuses:</b> Reflex +2, Body +1, Dexterity +2, Speed +5, Empathy −5'),
            (20, 7, 0.0,  '<b style="font-size: 1.17em;">Other</b><br>Create your own!')
          ) AS raw_data_en(group_id, num, probability, option_txt)

)
, meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_fortune_or_not_details' AS qu_id
                , 'character' AS entity)
-- i18n для event_type_misfortune
, ins_event_type_misfortune AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'event_type_misfortune') AS id
         , meta.entity, 'event_type', v.lang, v.text
      FROM (VALUES
        ('ru', 'Неудача'),
        ('en', 'Misfortune')
      ) AS v(lang, text)
      CROSS JOIN meta
)
-- i18n для типов болезней (Проклятие и Зависимость)
, ins_disease_type_curse AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'disease_type_curse') AS id
         , 'character', 'disease_type', v.lang, v.text
      FROM (VALUES
        ('ru', 'Проклятие'),
        ('en', 'Curse')
      ) AS v(lang, text)
      CROSS JOIN meta
)
, ins_disease_type_addiction AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'disease_type_addiction') AS id
         , 'character', 'disease_type', v.lang, v.text
      FROM (VALUES
        ('ru', 'Зависимость'),
        ('en', 'Addiction')
      ) AS v(lang, text)
      CROSS JOIN meta
)
-- i18n для описаний зависимостей (группа 13)
, ins_addiction_desc_13 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*13+vals.num, 'FM0000') ||'.'|| 'addiction_desc') AS id
         , 'character', 'disease_description', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Алкоголь'),
        ('ru', 2, 'Табак'),
        ('ru', 3, 'Фисштех'),
        ('ru', 4, 'Азартные игры'),
        ('ru', 5, 'Клептомания'),
        ('ru', 6, 'Похоть'),
        ('ru', 7, 'Обжорство'),
        ('ru', 8, 'Адреналиновая зависимость'),
        ('ru', 9, 'Кастомная зависимость'),
        ('en', 1, 'Alcohol'),
        ('en', 2, 'Tobacco'),
        ('en', 3, 'Fisstech'),
        ('en', 4, 'Gambling'),
        ('en', 5, 'Kleptomania'),
        ('en', 6, 'Lust'),
        ('en', 7, 'Gluttony'),
        ('en', 8, 'Adrenaline addiction'),
        ('en', 9, 'Custom addiction')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- i18n для описаний событий (все группы 1-20)
-- Группа 1: Джекпот с детализацией суммы
, ins_desc_01 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*1+vals.num, 'FM0000') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Джекпот: Получили 100 крон.'),
        ('ru', 2, 'Джекпот: Получили 200 крон.'),
        ('ru', 3, 'Джекпот: Получили 300 крон.'),
        ('ru', 4, 'Джекпот: Получили 400 крон.'),
        ('ru', 5, 'Джекпот: Получили 500 крон.'),
        ('ru', 6, 'Джекпот: Получили 600 крон.'),
        ('ru', 7, 'Джекпот: Получили 700 крон.'),
        ('ru', 8, 'Джекпот: Получили 800 крон.'),
        ('ru', 9, 'Джекпот: Получили 900 крон.'),
        ('ru', 10, 'Джекпот: Получили 1000 крон.'),
        ('en', 1, 'Jackpot: Received 100 crowns.'),
        ('en', 2, 'Jackpot: Received 200 crowns.'),
        ('en', 3, 'Jackpot: Received 300 crowns.'),
        ('en', 4, 'Jackpot: Received 400 crowns.'),
        ('en', 5, 'Jackpot: Received 500 crowns.'),
        ('en', 6, 'Jackpot: Received 600 crowns.'),
        ('en', 7, 'Jackpot: Received 700 crowns.'),
        ('en', 8, 'Jackpot: Received 800 crowns.'),
        ('en', 9, 'Jackpot: Received 900 crowns.'),
        ('en', 10, 'Jackpot: Received 1,000 crowns.')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- Группа 2: Учитель с детализацией навыка
, ins_desc_02 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*2+vals.num, 'FM0000') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Учитель: +1 к Вниманию или новый навык +2.'),
        ('ru', 2, 'Учитель: +1 к Выживанию в дикой природе или новый +2.'),
        ('ru', 3, 'Учитель: +1 к Дедукции или новый навык +2.'),
        ('ru', 4, 'Учитель: +1 к Монстрологии или новый навык +2.'),
        ('ru', 5, 'Учитель: +1 к Образованию или новый навык +2.'),
        ('ru', 6, 'Учитель: +1 к Ориентированию в городе или новый +2.'),
        ('ru', 7, 'Учитель: +1 к Передаче знаний или новый навык +2.'),
        ('ru', 8, 'Учитель: +1 к Тактике или новый навык +2.'),
        ('ru', 9, 'Учитель: +1 к Торговле или новый навык +2.'),
        ('ru', 10, 'Учитель: +1 к Этикету или новый навык +2.'),
        ('ru', 11, 'Учитель: +1 к Языку - северный или новый +2.'),
        ('ru', 12, 'Учитель: +1 к Языку - дварфийский или новый +2.'),
        ('ru', 13, 'Учитель: +1 к Языку - старшая речь или новый +2.'),
        ('en', 1, 'Find a Teacher: +1 Awareness or new skill +2.'),
        ('en', 2, 'Find a Teacher: +1 Wilderness Survival or new +2.'),
        ('en', 3, 'Find a Teacher: +1 Deduction or new skill +2.'),
        ('en', 4, 'Find a Teacher: +1 Monster Lore or new skill +2.'),
        ('en', 5, 'Find a Teacher: +1 Education or new skill +2.'),
        ('en', 6, 'Find a Teacher: +1 Streetwise or new skill +2.'),
        ('en', 7, 'Find a Teacher: +1 Teaching or new skill +2.'),
        ('en', 8, 'Find a Teacher: +1 Tactics or new skill +2.'),
        ('en', 9, 'Find a Teacher: +1 Business or new skill +2.'),
        ('en', 10, 'Find a Teacher: +1 Social Etiquette or new +2.'),
        ('en', 11, 'Find a Teacher: +1 Language - Northern or new +2.'),
        ('en', 12, 'Find a Teacher: +1 Language - Dwarvish or new +2.'),
        ('en', 13, 'Find a Teacher: +1 Language - Elder Speech or new +2.')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- Группа 4: Боевой инструктор с детализацией навыка
, ins_desc_04 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*4+vals.num, 'FM0000') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Боевой инструктор: +1 к Атлетике или новый навык +2.'),
        ('ru', 2, 'Боевой инструктор: +1 к Ближнему бою или новый +2.'),
        ('ru', 3, 'Боевой инструктор: +1 к Борьбе или новый навык +2.'),
        ('ru', 4, 'Боевой инструктор: +1 к Верховой езде или новый +2.'),
        ('ru', 5, 'Боевой инструктор: +1 к Владению древковым оружием или новый +2.'),
        ('ru', 6, 'Боевой инструктор: +1 к Владению лёгкими клинками или новый +2.'),
        ('ru', 7, 'Боевой инструктор: +1 к Владению мечом или новый +2.'),
        ('ru', 8, 'Боевой инструктор: +1 к Стрельбе из арбалета или новый +2.'),
        ('ru', 9, 'Боевой инструктор: +1 к Стрельбе из лука или новый +2.'),
        ('ru', 10, 'Боевой инструктор: +1 к Тактике или новый навык +2.'),
        ('en', 1, 'Find a Combat Teacher: +1 Athletics or new skill +2.'),
        ('en', 2, 'Find a Combat Teacher: +1 Melee or new skill +2.'),
        ('en', 3, 'Find a Combat Teacher: +1 Brawling or new skill +2.'),
        ('en', 4, 'Find a Combat Teacher: +1 Riding or new skill +2.'),
        ('en', 5, 'Find a Combat Teacher: +1 Staff or new skill +2.'),
        ('en', 6, 'Find a Combat Teacher: +1 Small Blades or new +2.'),
        ('en', 7, 'Find a Combat Teacher: +1 Swordsmanship or new +2.'),
        ('en', 8, 'Find a Combat Teacher: +1 Crossbow or new skill +2.'),
        ('en', 9, 'Find a Combat Teacher: +1 Archery or new skill +2.'),
        ('en', 10, 'Find a Combat Teacher: +1 Tactics or new skill +2.')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- Группа 7: Прирученный зверь с детализацией
, ins_desc_07 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*7+vals.num, 'FM0000') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Приручённый зверь: Дикая собака.'),
        ('ru', 2, 'Приручённый зверь: Волк.'),
        ('en', 1, 'Tamed a Wild Animal: Wild Dog.'),
        ('en', 2, 'Tamed a Wild Animal: Wolf.')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- Группа 10: Рыцарство с детализацией королевства
, ins_desc_10 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*10+vals.num, 'FM0000') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Рыцарство: Посвящены в рыцари в Редании (+2 репутация).'),
        ('ru', 2, 'Рыцарство: Посвящены в рыцари в Каэдвене (+2 репутация).'),
        ('ru', 3, 'Рыцарство: Посвящены в рыцари в Темерии (+2 репутация).'),
        ('ru', 4, 'Рыцарство: Посвящены в рыцари в Аэдирне (+2 репутация).'),
        ('ru', 5, 'Рыцарство: Посвящены в рыцари в Лирии (+2 репутация).'),
        ('ru', 6, 'Рыцарство: Посвящены в рыцари в Ривии (+2 репутация).'),
        ('ru', 7, 'Рыцарство: Посвящены в рыцари в Ковире (+2 репутация).'),
        ('ru', 8, 'Рыцарство: Посвящены в рыцари в Повиссе (+2 репутация).'),
        ('ru', 9, 'Рыцарство: Посвящены в рыцари в Скеллиге (+2 репутация).'),
        ('ru', 10, 'Рыцарство: Посвящены в рыцари в Цидарисе (+2 репутация).'),
        ('ru', 11, 'Рыцарство: Посвящены в рыцари в Вердене (+2 репутация).'),
        ('ru', 12, 'Рыцарство: Посвящены в рыцари в Цинтре (+2 репутация).'),
        ('ru', 13, 'Рыцарство: Посвящены в рыцари в Сердце Нильфгаарда (+2 репутация).'),
        ('ru', 14, 'Рыцарство: Посвящены в рыцари в Виковаро (+2 репутация).'),
        ('ru', 15, 'Рыцарство: Посвящены в рыцари в Аигрене (+2 репутация).'),
        ('ru', 16, 'Рыцарство: Посвящены в рыцари в Назаире (+2 репутация).'),
        ('ru', 17, 'Рыцарство: Посвящены в рыцари в Метиине (+2 репутация).'),
        ('ru', 18, 'Рыцарство: Посвящены в рыцари в Маг Турге (+2 репутация).'),
        ('ru', 19, 'Рыцарство: Посвящены в рыцари в Гесо (+2 репутация).'),
        ('ru', 20, 'Рыцарство: Посвящены в рыцари в Эббинге (+2 репутация).'),
        ('ru', 21, 'Рыцарство: Посвящены в рыцари в Мехте (+2 репутация).'),
        ('ru', 22, 'Рыцарство: Посвящены в рыцари в Геммерии (+2 репутация).'),
        ('ru', 23, 'Рыцарство: Посвящены в рыцари в Этолии (+2 репутация).'),
        ('ru', 24, 'Рыцарство: Посвящены в рыцари в Туссенте (+2 репутация).'),
        ('en', 1, 'Knighted: Knighted in Redania (+2 reputation).'),
        ('en', 2, 'Knighted: Knighted in Kaedwen (+2 reputation).'),
        ('en', 3, 'Knighted: Knighted in Temeria (+2 reputation).'),
        ('en', 4, 'Knighted: Knighted in Aedirn (+2 reputation).'),
        ('en', 5, 'Knighted: Knighted in Lyria (+2 reputation).'),
        ('en', 6, 'Knighted: Knighted in Rivia (+2 reputation).'),
        ('en', 7, 'Knighted: Knighted in Kovir (+2 reputation).'),
        ('en', 8, 'Knighted: Knighted in Poviss (+2 reputation).'),
        ('en', 9, 'Knighted: Knighted in Skellige (+2 reputation).'),
        ('en', 10, 'Knighted: Knighted in Cidaris (+2 reputation).'),
        ('en', 11, 'Knighted: Knighted in Verden (+2 reputation).'),
        ('en', 12, 'Knighted: Knighted in Cintra (+2 reputation).'),
        ('en', 13, 'Knighted: Knighted in The Heart of Nilfgaard (+2 reputation).'),
        ('en', 14, 'Knighted: Knighted in Vicovaro (+2 reputation).'),
        ('en', 15, 'Knighted: Knighted in Angren (+2 reputation).'),
        ('en', 16, 'Knighted: Knighted in Nazair (+2 reputation).'),
        ('en', 17, 'Knighted: Knighted in Mettina (+2 reputation).'),
        ('en', 18, 'Knighted: Knighted in Mag Turga (+2 reputation).'),
        ('en', 19, 'Knighted: Knighted in Gheso (+2 reputation).'),
        ('en', 20, 'Knighted: Knighted in Ebbing (+2 reputation).'),
        ('en', 21, 'Knighted: Knighted in Maecht (+2 reputation).'),
        ('en', 22, 'Knighted: Knighted in Gemmeria (+2 reputation).'),
        ('en', 23, 'Knighted: Knighted in Etolia (+2 reputation).'),
        ('en', 24, 'Knighted: Knighted in Toussaint (+2 reputation).')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- i18n для групп 11-20 (описания из ноды 026 с детализацией)
-- Группа 11: Долг
, ins_desc_11 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*11+vals.num, 'FM0000') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Долг: Вы задолжали 100 крон.'),
        ('ru', 2, 'Долг: Вы задолжали 200 крон.'),
        ('ru', 3, 'Долг: Вы задолжали 300 крон.'),
        ('ru', 4, 'Долг: Вы задолжали 400 крон.'),
        ('ru', 5, 'Долг: Вы задолжали 500 крон.'),
        ('ru', 6, 'Долг: Вы задолжали 600 крон.'),
        ('ru', 7, 'Долг: Вы задолжали 700 крон.'),
        ('ru', 8, 'Долг: Вы задолжали 800 крон.'),
        ('ru', 9, 'Долг: Вы задолжали 900 крон.'),
        ('ru', 10, 'Долг: Вы задолжали 1000 крон.'),
        ('en', 1, 'Debt: You owe 100 crowns.'),
        ('en', 2, 'Debt: You owe 200 crowns.'),
        ('en', 3, 'Debt: You owe 300 crowns.'),
        ('en', 4, 'Debt: You owe 400 crowns.'),
        ('en', 5, 'Debt: You owe 500 crowns.'),
        ('en', 6, 'Debt: You owe 600 crowns.'),
        ('en', 7, 'Debt: You owe 700 crowns.'),
        ('en', 8, 'Debt: You owe 800 crowns.'),
        ('en', 9, 'Debt: You owe 900 crowns.'),
        ('en', 10, 'Debt: You owe 1,000 crowns.')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- Группа 12: Заключение
, ins_desc_12 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*12+vals.num, 'FM0000') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Заключение: Отсидели в тюрьме 1 месяц.'),
        ('ru', 2, 'Заключение: Отсидели в тюрьме 2 месяца.'),
        ('ru', 3, 'Заключение: Отсидели в тюрьме 3 месяца.'),
        ('ru', 4, 'Заключение: Отсидели в тюрьме 4 месяца.'),
        ('ru', 5, 'Заключение: Отсидели в тюрьме 5 месяцев.'),
        ('ru', 6, 'Заключение: Отсидели в тюрьме 6 месяцев.'),
        ('ru', 7, 'Заключение: Отсидели в тюрьме 7 месяцев.'),
        ('ru', 8, 'Заключение: Отсидели в тюрьме 8 месяцев.'),
        ('ru', 9, 'Заключение: Отсидели в тюрьме 9 месяцев.'),
        ('ru', 10, 'Заключение: Отсидели в тюрьме 10 месяцев.'),
        ('en', 1, 'Imprisonment: Served 1 month in prison.'),
        ('en', 2, 'Imprisonment: Served 2 months in prison.'),
        ('en', 3, 'Imprisonment: Served 3 months in prison.'),
        ('en', 4, 'Imprisonment: Served 4 months in prison.'),
        ('en', 5, 'Imprisonment: Served 5 months in prison.'),
        ('en', 6, 'Imprisonment: Served 6 months in prison.'),
        ('en', 7, 'Imprisonment: Served 7 months in prison.'),
        ('en', 8, 'Imprisonment: Served 8 months in prison.'),
        ('en', 9, 'Imprisonment: Served 9 months in prison.'),
        ('en', 10, 'Imprisonment: Served 10 months in prison.')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- Группа 13: Зависимость
, ins_desc_13 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*13+vals.num, 'FM0000') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Зависимость: Алкоголь.'),
        ('ru', 2, 'Зависимость: Табак.'),
        ('ru', 3, 'Зависимость: Фисштех.'),
        ('ru', 4, 'Зависимость: Азартные игры.'),
        ('ru', 5, 'Зависимость: Клептомания.'),
        ('ru', 6, 'Зависимость: Похоть.'),
        ('ru', 7, 'Зависимость: Обжорство.'),
        ('ru', 8, 'Зависимость: Адреналиновая зависимость.'),
        ('en', 1, 'Addiction: Alcohol.'),
        ('en', 2, 'Addiction: Tobacco.'),
        ('en', 3, 'Addiction: Fisstech.'),
        ('en', 4, 'Addiction: Gambling.'),
        ('en', 5, 'Addiction: Kleptomania.'),
        ('en', 6, 'Addiction: Lust.'),
        ('en', 7, 'Addiction: Gluttony.'),
        ('en', 8, 'Addiction: Adrenaline addiction.')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- Группа 14: Любимый, друг или родственник убит
, ins_desc_14 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*14+vals.num, 'FM0000') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Любимый/друг/родственник убит: Несчастный случай.'),
        ('ru', 2, 'Любимый/друг/родственник убит: Убит чудовищами.'),
        ('ru', 3, 'Любимый/друг/родственник убит: Убит разбойниками.'),
        ('en', 1, 'Lover/Friend/Relative Killed: Accident.'),
        ('en', 2, 'Lover/Friend/Relative Killed: Slain by monsters.'),
        ('en', 3, 'Lover/Friend/Relative Killed: Murdered by bandits.')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- Группа 15: Ложное обвинение
, ins_desc_15 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*15+vals.num, 'FM0000') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Ложное обвинение: Воровство.'),
        ('ru', 2, 'Ложное обвинение: Трусость или предательство.'),
        ('ru', 3, 'Ложное обвинение: Убийство.'),
        ('ru', 4, 'Ложное обвинение: Изнасилование.'),
        ('ru', 5, 'Ложное обвинение: Нелегальное колдовство.'),
        ('en', 1, 'False Accusation: Theft.'),
        ('en', 2, 'False Accusation: Cowardice or betrayal.'),
        ('en', 3, 'False Accusation: Murder.'),
        ('en', 4, 'False Accusation: Rape.'),
        ('en', 5, 'False Accusation: Illegal witchcraft.')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- Группа 16: В розыске
, ins_desc_16 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*16+vals.num, 'FM0000') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'В розыске: Несколько стражников.'),
        ('ru', 2, 'В розыске: В посёлке.'),
        ('ru', 3, 'В розыске: В городе.'),
        ('ru', 4, 'В розыске: Во всём королевстве.'),
        ('en', 1, 'Wanted: A few guards.'),
        ('en', 2, 'Wanted: In a village.'),
        ('en', 3, 'Wanted: In a major city.'),
        ('en', 4, 'Wanted: Throughout the entire kingdom.')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- Группа 17: Предательство
, ins_desc_17 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*17+vals.num, 'FM0000') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Предательство: Шантаж.'),
        ('ru', 2, 'Предательство: Раскрыта ваша тайна.'),
        ('ru', 3, 'Предательство: Предан близким.'),
        ('en', 1, 'Betrayal: Blackmailed.'),
        ('en', 2, 'Betrayal: Secret exposed.'),
        ('en', 3, 'Betrayal: Betrayed by someone close.')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- Группа 18: Несчастный случай
, ins_desc_18 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*18+vals.num, 'FM0000') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Несчастный случай: Изуродованы (социальный статус: опасение).'),
        ('ru', 2, 'Несчастный случай: Лечились 1-10 месяцев.'),
        ('ru', 3, 'Несчастный случай: Потеря памяти 1-10 месяцев.'),
        ('ru', 4, 'Несчастный случай: Жуткие кошмары.'),
        ('en', 1, 'Accident: Disfigured (social status: Feared).'),
        ('en', 2, 'Accident: Recovering 1-10 months.'),
        ('en', 3, 'Accident: Lost memory 1-10 months.'),
        ('en', 4, 'Accident: Dreadful nightmares.')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- Группа 19: Физическая или психическая травма
, ins_desc_19 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*19+vals.num, 'FM0000') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Травма: Отравление (-5 ПЗ навсегда).'),
        ('ru', 2, 'Травма: Панические атаки (проверка Устойчивости каждые 5 раундов).'),
        ('ru', 3, 'Травма: Душевное расстройство (агрессия, иррациональность, депрессия, голоса).'),
        ('en', 1, 'Trauma: Poisoned (-5 HP permanently).'),
        ('en', 2, 'Trauma: Panic attacks (Stun save every 5 rounds).'),
        ('en', 3, 'Trauma: Severe mental disorder (aggressive, irrational, depressive, voices).')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- Группа 20: Проклятие (только название и интенсивность для lifeEvents)
, ins_desc_20 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*20+vals.num, 'FM0000') ||'.'|| 'event_desc') AS id
         , meta.entity, 'event_desc', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Проклятие: Проклятие чудовищности (Интенсивность: Средняя).'),
        ('ru', 2, 'Проклятие: Проклятие призраков (Интенсивность: Средняя).'),
        ('ru', 3, 'Проклятие: Проклятие заразы (Интенсивность: Высокая).'),
        ('ru', 4, 'Проклятие: Проклятие странника (Интенсивность: Высокая).'),
        ('ru', 5, 'Проклятие: Проклятие ликантропии (Интенсивность: Высокая).'),
        ('ru', 6, 'Проклятие: Проклятие аилурантропии (Интенсивность: Высокая).'),
        ('ru', 7, 'Проклятие: Кастомное проклятие.'),
        ('en', 1, 'Curse: Curse of Monstrosity (Intensity: Moderate).'),
        ('en', 2, 'Curse: Curse of Phantoms (Intensity: Moderate).'),
        ('en', 3, 'Curse: Curse of Pestilence (Intensity: High).'),
        ('en', 4, 'Curse: Curse of the Wanderer (Intensity: High).'),
        ('en', 5, 'Curse: Curse of Lycanthropy (Intensity: High).'),
        ('en', 6, 'Curse: Curse of Ailuranthropy (Intensity: High).'),
        ('en', 7, 'Curse: Custom curse.')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- i18n для gear: звери (группа 7)
, ins_gear_07_name AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*7+vals.num, 'FM0000') ||'.'|| 'gear_name') AS id
         , 'gear', 'name', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Дикая собака'),
        ('ru', 2, 'Волк'),
        ('en', 1, 'Wild Dog'),
        ('en', 2, 'Wolf')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
, ins_gear_07_notes AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| '07' ||'.'|| 'gear_notes') AS id
         , 'gear', 'notes', vals.lang, vals.text
      FROM (VALUES
        ('ru', 'Зверь с оружием "Укус" на 2d6 урона и скоростью атаки 1'),
        ('en', 'Beast with "Bite" weapon dealing 2d6 damage and attack speed 1')
      ) AS vals(lang, text)
      CROSS JOIN meta
)
-- i18n для gear: рыцарский титул (группа 10)
, ins_gear_10_name AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| '10' ||'.'|| 'gear_name') AS id
         , 'gear', 'name', vals.lang, vals.text
      FROM (VALUES
        ('ru', 'Рыцарский титул'),
        ('en', 'Knight Title')
      ) AS vals(lang, text)
      CROSS JOIN meta
)
, ins_gear_10_notes AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*10+vals.num, 'FM0000') ||'.'|| 'gear_notes') AS id
         , 'gear', 'notes', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, '+2 к репутации в Редании'),
        ('ru', 2, '+2 к репутации в Каэдвене'),
        ('ru', 3, '+2 к репутации в Темерии'),
        ('ru', 4, '+2 к репутации в Аэдирне'),
        ('ru', 5, '+2 к репутации в Лирии'),
        ('ru', 6, '+2 к репутации в Ривии'),
        ('ru', 7, '+2 к репутации в Ковире'),
        ('ru', 8, '+2 к репутации в Повиссе'),
        ('ru', 9, '+2 к репутации в Скеллиге'),
        ('ru', 10, '+2 к репутации в Цидарисе'),
        ('ru', 11, '+2 к репутации в Вердене'),
        ('ru', 12, '+2 к репутации в Цинтре'),
        ('ru', 13, '+2 к репутации в Сердце Нильфгаарда'),
        ('ru', 14, '+2 к репутации в Виковаро'),
        ('ru', 15, '+2 к репутации в Аигрене'),
        ('ru', 16, '+2 к репутации в Назаире'),
        ('ru', 17, '+2 к репутации в Метиине'),
        ('ru', 18, '+2 к репутации в Маг Турге'),
        ('ru', 19, '+2 к репутации в Гесо'),
        ('ru', 20, '+2 к репутации в Эббинге'),
        ('ru', 21, '+2 к репутации в Мехте'),
        ('ru', 22, '+2 к репутации в Геммерии'),
        ('ru', 23, '+2 к репутации в Этолии'),
        ('ru', 24, '+2 к репутации в Туссенте'),
        ('en', 1, '+2 reputation in Redania'),
        ('en', 2, '+2 reputation in Kaedwen'),
        ('en', 3, '+2 reputation in Temeria'),
        ('en', 4, '+2 reputation in Aedirn'),
        ('en', 5, '+2 reputation in Lyria'),
        ('en', 6, '+2 reputation in Rivia'),
        ('en', 7, '+2 reputation in Kovir'),
        ('en', 8, '+2 reputation in Poviss'),
        ('en', 9, '+2 reputation in Skellige'),
        ('en', 10, '+2 reputation in Cidaris'),
        ('en', 11, '+2 reputation in Verden'),
        ('en', 12, '+2 reputation in Cintra'),
        ('en', 13, '+2 reputation in The Heart of Nilfgaard'),
        ('en', 14, '+2 reputation in Nilfgaardian Vassal State - Vicovaro'),
        ('en', 15, '+2 reputation in Nilfgaardian Vassal State - Angren'),
        ('en', 16, '+2 reputation in Nilfgaardian Vassal State - Nazair'),
        ('en', 17, '+2 reputation in Nilfgaardian Vassal State - Mettina'),
        ('en', 18, '+2 reputation in Nilfgaardian Vassal State - Mag Turga'),
        ('en', 19, '+2 reputation in Nilfgaardian Vassal State - Gheso'),
        ('en', 20, '+2 reputation in Nilfgaardian Vassal State - Ebbing'),
        ('en', 21, '+2 reputation in Nilfgaardian Vassal State - Maecht'),
        ('en', 22, '+2 reputation in Nilfgaardian Vassal State - Gemmeria'),
        ('en', 23, '+2 reputation in Nilfgaardian Vassal State - Etolia'),
        ('en', 24, '+2 reputation in Nilfgaardian Vassal State - Toussaint')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- i18n для проклятий (группа 20) - полное описание для curses
, ins_curse_20 AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*20+vals.num, 'FM0000') ||'.'|| 'curse_name') AS id
         , 'curses', 'name', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Проклятие чудовищности'),
        ('ru', 2, 'Проклятие призраков'),
        ('ru', 3, 'Проклятие заразы'),
        ('ru', 4, 'Проклятие странника'),
        ('ru', 5, 'Проклятие ликантропии'),
        ('ru', 6, 'Проклятие аилурантропии'),
        ('en', 1, 'Curse of Monstrosity'),
        ('en', 2, 'Curse of Phantoms'),
        ('en', 3, 'Curse of Pestilence'),
        ('en', 4, 'Curse of the Wanderer'),
        ('en', 5, 'Curse of Lycanthropy'),
        ('en', 6, 'Curse of Ailuranthropy')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
, ins_curse_20_intensity AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*20+vals.num, 'FM0000') ||'.'|| 'curse_intensity') AS id
         , 'curses', 'intensity', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Средняя'),
        ('ru', 2, 'Средняя'),
        ('ru', 3, 'Высокая'),
        ('ru', 4, 'Высокая'),
        ('ru', 5, 'Высокая'),
        ('ru', 6, 'Высокая'),
        ('en', 1, 'Moderate'),
        ('en', 2, 'Moderate'),
        ('en', 3, 'High'),
        ('en', 4, 'High'),
        ('en', 5, 'High'),
        ('en', 6, 'High')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
, ins_curse_20_desc AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*20+vals.num, 'FM0000') ||'.'|| 'curse_desc') AS id
         , 'curses', 'description', vals.lang, vals.text
      FROM (VALUES
        ('ru', 1, 'Жертва выглядит чудовищно для всех, кто её видит. Она остаётся гуманоидом, но черты лица приобретают сходство со случайным животным. Сделайте бросок IdlO, чтобы узнать, что это за животное: 1 или 2 — медведь, 3 или 4 — кабан, 5 или 6 — птица, 7 или 8 — змея, 9 или 10 — насекомое. Социальный статус проклятого меняется на «ненависть и опасение» вне зависимости от того, каким он был раньше. Проклятый на самом деле не является чудовищем и не получает урона от серебра, но с виду похож на чудовище, и его можно спутать с чудовищем, если провалить проверку Образования со СЛ 18.'),
        ('ru', 2, 'Действует только на зону, призывая в виде призраков всех, к кому в этом месте отнеслись несправедливо. При создании этого проклятия сделайте бросок 5d6, чтобы определить, сколько призраков явится. Если зона особенно ужасна, бросьте дополнительно 2d6. Если зона достаточно спокойная, бросьте только 2d6. Призраки остаются в зоне до тех пор, пока не будут убиты, и возвращаются на следующую ночь. Они нападают на всё, что входит в зону действия проклятия. Единственный способ снять проклятие — каким-то образом исправить всю ту несправедливость, что случилась в этой зоне.'),
        ('ru', 3, 'Делает жертву проклятия носителем опасной болезни. Болезнь не влияет на носителя, но любой, кто дотронется до него и провалит проверку Стойкости со СЛ 18, заражается. Если носитель остаётся в здании дольше 3 дней, то все, кто находится в этом здании, должны пройти проверку Стойкости со СЛ 16. Если носитель проводит в городе больше недели, то все в городе должны совершить проверку Стойкости со СЛ 14.'),
        ('ru', 4, 'Одно из самых жестоких проклятий. Самой жертве оно вреда не причиняет, но даже самый верный друг, близкий родственник или товарищ от неё отвернётся. Постепенно люди покидают жертву из-за разногласий, ссор, по естественным причинам или из-за похищений, пока (если носитель проклятия дольше месяца остаётся на одном месте) сама судьба не попытается убить несчастного.'),
        ('ru', 5, 'Проклятый ликантропией с вероятностью 30 % каждую ночь на восходе луны превращается в волколака. После превращения персонаж становится жестоким хищником с человеческой хитростью и с желанием убивать. Если обратившийся — персонаж игрока, то до восхода солнца им управляет ведущий. Будучи волколаком, персонаж потакает самым ужасным своим порывам, без жалости убивая любого, кто встанет на пути. Находясь в зверином облике, проклятый получает всё оружие, броню и способности волколака. Персонаж также прибавляет бонус к четырём своим параметрам, как указано ниже. Бонусы волколака: Реакция +2, Телосложение +3, Скорость +4, Эмпатия -5'),
        ('ru', 6, 'Проклятый айлурантропией с вероятностью 30 % каждую ночь, когда восходит луна, превращается в котолака. В форме котолака персонаж становится злым, хитрым хищником с жаждою убивать. Если обратившийся — персонаж игрока, то до восхода солнца им управляет ведущий. Находясь в зверином облике, проклятый получает всё оружие, броню, уязвимости и способности котолака. Персонаж также прибавляет бонус к четырём своим параметрам, как указано ниже. Бонусы котолака: Реакция +2, Телосложение +1, Ловкость +2, Скорость +5, Эмпатия -5'),
        ('en', 1, 'The victim appears monstrous to all who see them. They remain humanoid, but their features resemble a random animal. Roll 1d10 to determine the animal: 1–2 bear, 3–4 boar, 5–6 bird, 7–8 snake, 9–10 insect. The victim''s social status becomes "Hated & Feared." They are not actually a monster and do not take damage from silver, but can be mistaken for one on a failed Education check DC 18.'),
        ('en', 2, 'Affects an area, summoning as ghosts all who were wronged there. When casting, roll 5d6 to determine how many appear (add 2d6 if the area is especially horrific; only 2d6 if it is rather calm). Ghosts remain until destroyed and return the next night. They attack anything entering the cursed zone. The only way to lift the curse is to somehow right all the wrongs done there.'),
        ('en', 3, 'The victim becomes a carrier of a dangerous disease. It does not affect the carrier, but anyone who touches them and fails a Physique check DC 18 is infected. If the carrier stays inside a building for more than 3 days, everyone inside must make a Physique check DC 16. If the carrier remains in a city for more than a week, everyone in the city must make a Physique check DC 14.'),
        ('en', 4, 'One of the cruelest curses. It does not harm the victim directly, but even the truest friend or closest kin will eventually abandon them. People drift away due to quarrels, distance, circumstance, or kidnappings until—if the victim stays in one place longer than a month—fate itself tries to kill them.'),
        ('en', 5, 'Each night at moonrise there is a 30% chance the victim transforms into a werewolf. While transformed, the character becomes a brutal predator with human cunning and a lust for killing. If it is a PC, the GM controls them until sunrise. In beast form, the character gains the werewolf''s weapons, armor, and abilities plus the following bonuses: Reflex +2, Body +3, Speed +4, Empathy −5'),
        ('en', 6, 'A character afflicted with ailuranthropy has a 30% chance of changing into a werecat every night, when the moon rises. In their werecat form, they are a vicious, cunning predator with an urge to kill. If the character is a player character, they are taken over by the Game Master until the sun rises. While in their beast state, the ailuranthrope has all of the werecat’s weapons, armor, vulnerabilities, and abilities. The character also augments their statistics with the following changes. They increase their Body Statistic by 1, their Reflex and Dexterity Statistics by 2, and their Speed Statistic by 5. Additionally, they lower their Empathy Statistic by 5. Werecat Bonuses: Reflex +2, Body +1, Dexterity +2, Speed +5, Empathy −5')
      ) AS vals(lang, num, text)
      CROSS JOIN meta
)
-- Теперь добавляем эффекты
, all_groups AS (
  SELECT DISTINCT group_id FROM raw_data
)
, skill_mapping_group2 AS (
  SELECT 1 AS num, 'awareness' AS skill_path
  UNION ALL SELECT 2, 'wilderness_survival'
  UNION ALL SELECT 3, 'deduction'
  UNION ALL SELECT 4, 'monster_lore'
  UNION ALL SELECT 5, 'education'
  UNION ALL SELECT 6, 'streetwise'
  UNION ALL SELECT 7, 'teaching'
  UNION ALL SELECT 8, 'tactics'
  UNION ALL SELECT 9, 'business'
  UNION ALL SELECT 10, 'social_etiquette'
  UNION ALL SELECT 11, 'language_common_speech'
  UNION ALL SELECT 12, 'language_dwarvish'
  UNION ALL SELECT 13, 'language_elder_speech'
)
, skill_mapping_group4 AS (
  SELECT 1 AS num, 'athletics' AS skill_path
  UNION ALL SELECT 2, 'melee'
  UNION ALL SELECT 3, 'brawling'
  UNION ALL SELECT 4, 'riding'
  UNION ALL SELECT 5, 'staff'
  UNION ALL SELECT 6, 'small_blades'
  UNION ALL SELECT 7, 'swordsmanship'
  UNION ALL SELECT 8, 'crossbow'
  UNION ALL SELECT 9, 'archery'
  UNION ALL SELECT 10, 'tactics'
)
INSERT INTO effects (scope, an_an_id, body)
-- 1. Добавление в lifeEvents для всех групп (1-20)
SELECT DISTINCT
  'character', 'wcc_life_events_fortune_or_not_details_o' || to_char(raw_data.group_id, 'FM00') || to_char(raw_data.num, 'FM00'),
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.lore.lifeEvents'),
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
        CASE WHEN raw_data.group_id <= 10 THEN
          jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| 'wcc_life_events_fortune' ||'.'|| 'event_type_fortune')::text)
        ELSE
          jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'event_type_misfortune')::text)
        END,
        'description',
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*raw_data.group_id+raw_data.num, 'FM0000') ||'.'|| 'event_desc')::text)
      )
    )
  )
FROM raw_data
CROSS JOIN meta
WHERE raw_data.group_id IN (1,2,4,7,10) --AND raw_data.lang = 'en' -- Группы с детализацией из 025
UNION ALL
-- Группы 11-20: описания из 026 с детализацией
SELECT DISTINCT
  'character', 'wcc_life_events_fortune_or_not_details_o' || to_char(raw_data.group_id, 'FM00') || to_char(raw_data.num, 'FM00'),
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.lore.lifeEvents'),
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
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'event_type_misfortune')::text),
        'description',
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*raw_data.group_id+raw_data.num, 'FM0000') ||'.'|| 'event_desc')::text)
      )
    )
  )
FROM raw_data
CROSS JOIN meta
WHERE raw_data.group_id BETWEEN 11 AND 20 
  AND NOT (raw_data.group_id = 18 AND raw_data.num IN (2, 3)) --AND raw_data.lang = 'en'
UNION ALL
-- 2. Группа 1: Добавление денег (100-1000 крон)
SELECT DISTINCT
  'character', 'wcc_life_events_fortune_or_not_details_o' || to_char(raw_data.group_id, 'FM00') || to_char(raw_data.num, 'FM00'),
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.money.crowns'),
      raw_data.num * 100
    )
  )
FROM raw_data
CROSS JOIN meta
WHERE raw_data.group_id = 1 --AND raw_data.lang = 'en'
UNION ALL
-- 3. Группа 2: Навыки интеллекта (cur = max(2, cur + 1))
SELECT 'character', 'wcc_life_events_fortune_or_not_details_o' || to_char(2, 'FM00') || to_char(skill_mapping_group2.num, 'FM00'),
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.' || skill_mapping_group2.skill_path || '.cur'),
      jsonb_build_object(
        'jsonlogic_expression',
        jsonb_build_object(
          'max', jsonb_build_array(
            2,
            jsonb_build_object(
              '+', jsonb_build_array(
                jsonb_build_object('var', jsonb_build_array(('characterRaw.skills.common.' || skill_mapping_group2.skill_path || '.cur'), 0)),
                1
              )
            )
          )
        )
      )
    )
  )
FROM skill_mapping_group2
CROSS JOIN meta
UNION ALL
-- 4. Группа 4: Боевые навыки (cur = max(2, cur + 1))
SELECT 'character', 'wcc_life_events_fortune_or_not_details_o' || to_char(4, 'FM00') || to_char(skill_mapping_group4.num, 'FM00'),
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.' || skill_mapping_group4.skill_path || '.cur'),
      jsonb_build_object(
        'jsonlogic_expression',
        jsonb_build_object(
          'max', jsonb_build_array(
            2,
            jsonb_build_object(
              '+', jsonb_build_array(
                jsonb_build_object('var', jsonb_build_array(('characterRaw.skills.common.' || skill_mapping_group4.skill_path || '.cur'), 0)),
                1
              )
            )
          )
        )
      )
    )
  )
FROM skill_mapping_group4
CROSS JOIN meta
UNION ALL
-- 5. Группа 7: Добавление зверя в gear
SELECT DISTINCT
  'character', 'wcc_life_events_fortune_or_not_details_o' || to_char(raw_data.group_id, 'FM00') || to_char(raw_data.num, 'FM00'),
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.gear.general_gear'),
      jsonb_build_object(
        'name', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*raw_data.group_id+raw_data.num, 'FM0000') ||'.'|| 'gear_name')::text),
        'weight', 0,
        'notes', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| '07' ||'.'|| 'gear_notes')::text)
      )
    )
  )
FROM raw_data
CROSS JOIN meta
WHERE raw_data.group_id = 7 --AND raw_data.lang = 'en'
UNION ALL
-- 6. Группа 10: Рыцарский титул
SELECT DISTINCT
  'character', 'wcc_life_events_fortune_or_not_details_o' || to_char(raw_data.group_id, 'FM00') || to_char(raw_data.num, 'FM00'),
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.gear.general_gear'),
      jsonb_build_object(
        'name', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| '10' ||'.'|| 'gear_name')::text),
        'weight', 0,
        'notes', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*raw_data.group_id+raw_data.num, 'FM0000') ||'.'|| 'gear_notes')::text)
      )
    )
  )
FROM raw_data
CROSS JOIN meta
WHERE raw_data.group_id = 10 AND raw_data.num <= 24 --AND raw_data.lang = 'en'
UNION ALL
-- 7. Группа 19, ответ 1: Штраф -5 к max HP
SELECT 'character', 'wcc_life_events_fortune_or_not_details_o1901',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.statistics.calculated.max_HP.bonus'),
      -5
    )
  )
FROM meta
UNION ALL
-- 8. Группа 20: Проклятия (переносим в diseases_and_curses с типом "Проклятие")
SELECT DISTINCT
  'character', 'wcc_life_events_fortune_or_not_details_o' || to_char(raw_data.group_id, 'FM00') || to_char(raw_data.num, 'FM00'),
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.lore.diseases_and_curses'),
      jsonb_build_object(
        'type', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'disease_type_curse')::text),
        'name', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*raw_data.group_id+raw_data.num, 'FM0000') ||'.'|| 'curse_name')::text),
        'intensity', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*raw_data.group_id+raw_data.num, 'FM0000') ||'.'|| 'curse_intensity')::text),
        'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*raw_data.group_id+raw_data.num, 'FM0000') ||'.'|| 'curse_desc')::text)
      )
    )
  )
FROM raw_data
CROSS JOIN meta
WHERE raw_data.group_id = 20 AND raw_data.num BETWEEN 2 AND 6 --AND raw_data.lang = 'en'
UNION ALL
-- 9. Группа 13: Зависимости (добавляем в diseases_and_curses с типом "Зависимость")
SELECT DISTINCT
  'character', 'wcc_life_events_fortune_or_not_details_o' || to_char(raw_data.group_id, 'FM00') || to_char(raw_data.num, 'FM00'),
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.lore.diseases_and_curses'),
      jsonb_build_object(
        'type', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'disease_type_addiction')::text),
        'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*raw_data.group_id+raw_data.num, 'FM0000') ||'.'|| 'addiction_desc')::text)
      )
    )
  )
FROM raw_data
CROSS JOIN meta
WHERE raw_data.group_id = 13 AND raw_data.num <= 8 ;--AND raw_data.lang = 'en';

-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_life_events_fortune', 'wcc_life_events_fortune_or_not_details', 'wcc_life_events_fortune_o01', 2;
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_life_events_fortune', 'wcc_life_events_fortune_or_not_details', 'wcc_life_events_fortune_o02', 2;
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_life_events_fortune', 'wcc_life_events_fortune_or_not_details', 'wcc_life_events_fortune_o04', 2;
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_life_events_fortune', 'wcc_life_events_fortune_or_not_details', 'wcc_life_events_fortune_o07', 2;
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_life_events_fortune', 'wcc_life_events_fortune_or_not_details', 'wcc_life_events_fortune_o10', 2;
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_life_events_misfortune', 'wcc_life_events_fortune_or_not_details', 'wcc_life_events_misfortune_o01', 2;
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_life_events_misfortune', 'wcc_life_events_fortune_or_not_details', 'wcc_life_events_misfortune_o02', 2;
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_life_events_misfortune', 'wcc_life_events_fortune_or_not_details', 'wcc_life_events_misfortune_o03', 2;
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_life_events_misfortune', 'wcc_life_events_fortune_or_not_details', 'wcc_life_events_misfortune_o04', 2;
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_life_events_misfortune', 'wcc_life_events_fortune_or_not_details', 'wcc_life_events_misfortune_o05', 2;
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_life_events_misfortune', 'wcc_life_events_fortune_or_not_details', 'wcc_life_events_misfortune_o06', 2;
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_life_events_misfortune', 'wcc_life_events_fortune_or_not_details', 'wcc_life_events_misfortune_o07', 2;
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_life_events_misfortune', 'wcc_life_events_fortune_or_not_details', 'wcc_life_events_misfortune_o08', 2;
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_life_events_misfortune', 'wcc_life_events_fortune_or_not_details', 'wcc_life_events_misfortune_o09', 2;
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority)
  SELECT 'wcc_life_events_misfortune', 'wcc_life_events_fortune_or_not_details', 'wcc_life_events_misfortune_o10', 2;

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_life_events_fortune_or_not_details', 'wcc_life_events_event', r.ru_id, 1
    FROM (SELECT ru_id FROM rules WHERE name = 'lifeEventsCounter_is_valid') r;