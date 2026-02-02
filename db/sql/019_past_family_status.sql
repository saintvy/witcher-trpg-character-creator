\echo '019_past_family_status.sql'
-- Узел: Положение семьи (wcc_past_family_status) — полный текст ячеек со снаряжением

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_family_status' AS qu_id
                , 'questions' AS entity)
, ins_body AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
                       , meta.entity, 'body', v.lang, v.text
                    FROM (VALUES
                            ('ru', 'Время определить положение вашей семьи.'),
                            ('en', 'Time to determine your family status.')) AS v(lang, text)
                    CROSS JOIN meta)
, c_vals(lang, num, text) AS (VALUES ('ru', 1, 'Шанс'),
                                     ('ru', 2, 'Положение'),
                                     ('ru', 3, 'Начальное снаряжение'),
                                     ('en', 1, 'Chance'),
                                     ('en', 2, 'Status'),
                                     ('en', 3, 'Starting Gear'))
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
           'dice', 'd_weighed',
           'columns', (
             SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_past_family_status' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
             FROM (SELECT DISTINCT num FROM c_vals) AS cols
           ),
           'path', jsonb_build_array(
             ck_id('witcher_cc.hierarchy.family')::text,
             ck_id('witcher_cc.hierarchy.family_status')::text
           )
         )
    FROM meta;

-- Ответы
WITH
raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
            -- group 1: Северянин
            (1, 1, 0.1, '<b>Аристократия</b> Вы выросли в богатом особняке, где слуги исполняли любую вашу прихоть. От вас ожидали хорошего поведения и умения произвести впечатление.', 'Дворянская грамота<br>(+2 к репутации)'),
            (1, 2, 0.1, '<b>Под опекой мага</b> В юном возрасте вас отдали под опеку мага. Вы жили в комфортных условиях, но опекуна практически не видели — он постоянно был занят.', 'Летопись<br>(+1 к Образованию)'),
            (1, 3, 0.1, '<b>Рыцарство</b> Вы жили в особняке, где из вас растили настоящего лорда или леди. Ваша судьба была предрешена с рождения.', 'Личный герб<br>(+1 к репутации)'),
            (1, 4, 0.1, '<b>Семья торговцев</b> Вы выросли в купеческой среде, под крики продавцов и звон монет.', '2 знакомых'),
            (1, 5, 0.1, '<b>Семья мастеров</b> Вы выросли в ремесленной мастерской, где каждый день стучали молотки или раздавались другие звуки творчества.', '3 обычных чертежа/формулы'),
            (1, 6, 0.2, '<b>Семья артистов</b> Вы выросли в актёрской труппе. Возможно, вы вместе с ними странствовали или же выступали в театре.', '1 музыкальный инструмент и 1 друг'),
            (1, 8 ,0.3, '<b>Крестьянская семья</b> Вы выросли на ферме в сельской глуши. За душой у вас почти ничего нет, а жизнь была простой, но опасной.', 'Счастливый талисман<br>(+1 к Удаче)'),

            -- group 2: Нильфгаардец
            (2, 1, 0.1, '<b>Аристократия</b> Вы выросли в богатом особняке, где вас неплохо научили выживать в мире придворных интриг. Роскошь служила лишь стимулом к обучению.', 'Дворянская грамота<br>(+2 к репутации)'),
            (2, 2, 0.1, '<b>Высшее жречество</b> Вы выросли среди жрецов Великого Солнца. Вы были набожным ребёнком, уверенным, что церковь всегда укажет верный путь.', 'Священный символ<br>(+1 к Храбрости)'),
            (2, 3, 0.1, '<b>Рыцарство</b> Вы росли, зная, что ваш долг — служить императору, и роскошь — награда за будущую службу.', 'Личный герб<br>(+1 к репутации)'),
            (2, 4, 0.1, '<b>Семья мастеров</b> Вы выросли в мастерской, учась создавать вещи, которые ценились за качество.', '3 обычных чертежа/формулы'),
            (2, 5, 0.1, '<b>Семья торговцев</b> Вы росли, продавая товары по всей Империи, и повидали разные экзотические изделия со всего мира.', '2 знакомых'),
            (2, 6, 0.2, '<b>Рабство</b> Вы раб с рождения. Вы жили в простой комнатушке и много работали, а скарб был скуден.', 'Обученная птица или змей'),
            (2, 8 ,0.3, '<b>Крестьянская семья</b> Вы выросли на одной из тысяч ферм Империи. За душой у вас почти ничего нет, но жизнь была простой.', 'Счастливый талисман<br>(+1 к Удаче)'),

            -- group 3: Нелюдь (Elderland)
            (3, 1, 0.1, '<b>Аристократия</b> Вы выросли во дворце, где вам постоянно напоминали о славном прошлом, ожидая, что вы будете достойны своих предков.', 'Дворянская грамота<br>(+2 к репутации)'),
            (3, 2, 0.1, '<b>Благородный воин</b> Вы дитя благородного воина. От вас ожидают, что вы оправдаете репутацию семьи и не опозорите своё наследие.', 'Личный герб<br>(+1 к репутации)'),
            (3, 3, 0.1, '<b>Семья торговцев</b> Вы выросли в семье странствующих торговцев. Иногда жизнь была трудна, но созданные нелюдями товары всегда ценятся.', '2 знакомых'),
            (3, 4, 0.1, '<b>Семья грамотев</b> Вы выросли в семье грамотев. Ваши родители берегли летописи Старших Народов, старательно их записывая и храня.', 'Летопись<br>(+1 к Образованию)'),
            (3, 5, 0.1, '<b>Артисты</b> С детства вы исполняли песни и играли на сцене, а в свободное время помогали писать песни и чинили музыкальные инструменты.', '1 музыкальный инструмент и 1 друг'),
            (3, 6, 0.2, '<b>Семья мастеров</b> Вы выросли в семье мастеров, посещали древние дворцы для вдохновения и ежедневно проводили за работой много часов.', '3 обычных чертежа/формулы'),
            (3, 8 ,0.3, '<b>Низкое происхождение</b> Вы из простой семьи и зарабатывали на жизнь, прислуживая в чужих домах либо перебиваясь случайными работами в родном городе.', 'Счастливый талисман<br>(+1 к Удаче)')
          ) AS raw_data_ru(group_id, num, probability, status_txt, gear)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
            -- group 1: Northern
            (1, 1, 0.1, '<b>Aristocracy</b> You grew up in a noble manor with servants to wait on you, but you were always expected to behave and impress.', 'Paper of Nobility<br>(+2 Reputation)'),
            (1, 2, 0.1, '<b>Adopted by a Mage</b> You were given to a mage at a young age. You lived in comfort but barely saw your caretaker, who was always busy.', 'A Chronicle<br>(+1 Education)'),
            (1, 3, 0.1, '<b>Knights</b> You grew up in a manor where you learned to be a proper lady or lord. Your fate was set from birth.', 'Personal Heraldry<br>(+1 Reputation)'),
            (1, 4, 0.1, '<b>Merchant Family</b> You grew up among merchants, always surrounded by yelling, haggling, and money.', '2 Acquaintances'),
            (1, 5, 0.1, '<b>Artisan Family</b> You grew up in an artisan’s workshop. Your days were filled with the incessant sounds of creation.', '3 Common Diagrams/Formulae'),
            (1, 6, 0.2, '<b>Entertainer Family</b> You grew up with a band of performers. You may have traveled or you may have performed at a theater.', '1 Instrument & 1 Friend'),
            (1, 8 ,0.3, '<b>Peasant Family</b> You grew up on a farm in the countryside. You didn’t have much to your name and life was simple, but dangerous.', 'A Lucky Token (+1 Luck)'),

            -- group 2: Nilfgaardian
            (2, 1, 0.1, '<b>Aristocracy</b> You grew up in a manor, trained to be well-versed in the world of the court. The luxury was just your incentive.', 'Paper of Nobility<br>(+2 Reputation)'),
            (2, 2, 0.1, '<b>High Clergy</b> You were raised among the clergy of the Great Sun. You grew up pious and always aware that the Church would guide you.', 'A Holy Symbol<br>(+1 Courage)'),
            (2, 3, 0.1, '<b>Knights</b> You grew up knowing that your duty was to the Emperor, and that all of your luxury was reward for your eventual service.', 'Personal Heraldry<br>(+1 Reputation)'),
            (2, 4, 0.1, '<b>Artisan Family</b> You grew up in an artisan’s shop, learning to craft products valued for their quality.', '3 Common Diagrams/Formulae'),
            (2, 5, 0.1, '<b>Merchant Family</b> You grew up selling products around the Empire. You saw exotic goods from all around the world.', '2 Acquaintances'),
            (2, 6, 0.2, '<b>Born into Servitude</b> You were born into servitude and lived in simple quarters. You owned very little and toiled often.', 'A trained bird or serpent'),
            (2, 8 ,0.3, '<b>Peasant Family</b> You grew up on one of the thousands of farms across the Empire. You had little to your name but life was simple.', 'A Lucky Token<br>(+1 Luck)'),

            -- group 3: Elderland (non-human)
            (3, 1, 0.1, '<b>Aristocracy</b> You grew up in a palace and were constantly reminded of the glory of the past. You were expected to live up to your heritage.', 'Paper of Nobility<br>(+2 Reputation)'),
            (3, 2, 0.1, '<b>Noble Warrior</b> You grew up as a noble warrior’s child, expected to rise to your family’s reputation and to never dishonor your heritage.', 'Personal Heraldry<br>(+1 Reputation)'),
            (3, 3, 0.1, '<b>Merchants</b> You grew up among traveling merchants. Life was difficult sometimes but non-human crafts are always valuable.', '2 Acquaintances'),
            (3, 4, 0.1, '<b>Scribe Family</b> You grew up as the child of scribes, recording and protecting elderfolk history.', 'A Chronicle<br>(+1 Education)'),
            (3, 5, 0.1, '<b>Entertainers</b> You grew up singing songs and performing plays. You worked backstage, helped write songs, and fixed instruments.', '1 Instrument & 1 Friend'),
            (3, 6, 0.2, '<b>Artisan Family</b> You grew up in a family of artisans, visiting ancient palaces for inspiration and spending hours every day on projects.', '3 Common Diagrams/Formulae'),
            (3, 8 ,0.3, '<b>Lowborn Family</b> You grew up in a lowborn family, tending to the manors of others or working small jobs around your home city.', 'A Lucky Token<br>(+1 Luck)')
         ) AS raw_data_en(group_id, num, probability, status_txt, gear)
),
vals AS (
         SELECT ('<td>' || to_char(probability*100, 'FM990.00') || '%</td>' ||
                 '<td>' || status_txt || '</td>' ||
                 '<td>' || gear || '</td>') AS text,
                num,
                probability,
                lang,
                group_id
         FROM raw_data
)
, meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_family_status' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, ins_label AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
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
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT 'wcc_past_family_status_o' || to_char(vals.group_id, 'FM00') || to_char(vals.num, 'FM00') AS an_id,
       meta.su_su_id,
       meta.qu_id,
       ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*vals.group_id+vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
       vals.num AS sort_order,
       rules_vals.id AS visible_ru_ru_id,
         jsonb_build_object(
           'probability', vals.probability
         ) AS metadata
FROM vals
CROSS JOIN meta
JOIN rules_vals ON rules_vals.group_id = vals.group_id
ON CONFLICT (an_id) DO NOTHING;

-- i18n записи для status_txt и предметов из gear
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_family_status' AS qu_id
                , 'character' AS entity)
, status_data AS (
  SELECT 'ru' AS lang, status_ru.*
    FROM (VALUES
            (1, 1, '<b>Аристократия</b> Вы выросли в богатом особняке, где слуги исполняли любую вашу прихоть. От вас ожидали хорошего поведения и умения произвести впечатление.'),
            (1, 2, '<b>Под опекой мага</b> В юном возрасте вас отдали под опеку мага. Вы жили в комфортных условиях, но опекуна практически не видели — он постоянно был занят.'),
            (1, 3, '<b>Рыцарство</b> Вы жили в особняке, где из вас растили настоящего лорда или леди. Ваша судьба была предрешена с рождения.'),
            (1, 4, '<b>Семья торговцев</b> Вы выросли в купеческой среде, под крики продавцов и звон монет.'),
            (1, 5, '<b>Семья мастеров</b> Вы выросли в ремесленной мастерской, где каждый день стучали молотки или раздавались другие звуки творчества.'),
            (1, 6, '<b>Семья артистов</b> Вы выросли в актёрской труппе. Возможно, вы вместе с ними странствовали или же выступали в театре.'),
            (1, 8, '<b>Крестьянская семья</b> Вы выросли на ферме в сельской глуши. За душой у вас почти ничего нет, а жизнь была простой, но опасной.'),
            (2, 1, '<b>Аристократия</b> Вы выросли в богатом особняке, где вас неплохо научили выживать в мире придворных интриг. Роскошь служила лишь стимулом к обучению.'),
            (2, 2, '<b>Высшее жречество</b> Вы выросли среди жрецов Великого Солнца. Вы были набожным ребёнком, уверенным, что церковь всегда укажет верный путь.'),
            (2, 3, '<b>Рыцарство</b> Вы росли, зная, что ваш долг — служить императору, и роскошь — награда за будущую службу.'),
            (2, 4, '<b>Семья мастеров</b> Вы выросли в мастерской, учась создавать вещи, которые ценились за качество.'),
            (2, 5, '<b>Семья торговцев</b> Вы росли, продавая товары по всей Империи, и повидали разные экзотические изделия со всего мира.'),
            (2, 6, '<b>Рабство</b> Вы раб с рождения. Вы жили в простой комнатушке и много работали, а скарб был скуден.'),
            (2, 8, '<b>Крестьянская семья</b> Вы выросли на одной из тысяч ферм Империи. За душой у вас почти ничего нет, но жизнь была простой.'),
            (3, 1, '<b>Аристократия</b> Вы выросли во дворце, где вам постоянно напоминали о славном прошлом, ожидая, что вы будете достойны своих предков.'),
            (3, 2, '<b>Благородный воин</b> Вы дитя благородного воина. От вас ожидают, что вы оправдаете репутацию семьи и не опозорите своё наследие.'),
            (3, 3, '<b>Семья торговцев</b> Вы выросли в семье странствующих торговцев. Иногда жизнь была трудна, но созданные нелюдями товары всегда ценятся.'),
            (3, 4, '<b>Семья грамотев</b> Вы выросли в семье грамотев. Ваши родители берегли летописи Старших Народов, старательно их записывая и храня.'),
            (3, 5, '<b>Артисты</b> С детства вы исполняли песни и играли на сцене, а в свободное время помогали писать песни и чинили музыкальные инструменты.'),
            (3, 6, '<b>Семья мастеров</b> Вы выросли в семье мастеров, посещали древние дворцы для вдохновения и ежедневно проводили за работой много часов.'),
            (3, 8, '<b>Низкое происхождение</b> Вы из простой семьи и зарабатывали на жизнь, прислуживая в чужих домах либо перебиваясь случайными работами в родном городе.')
          ) AS status_ru(group_id, num, status_txt)
  UNION ALL
  SELECT 'en' AS lang, status_en.*
    FROM (VALUES
            (1, 1, '<b>Aristocracy</b> You grew up in a noble manor with servants to wait on you, but you were always expected to behave and impress.'),
            (1, 2, '<b>Adopted by a Mage</b> You were given to a mage at a young age. You lived in comfort but barely saw your caretaker, who was always busy.'),
            (1, 3, '<b>Knights</b> You grew up in a manor where you learned to be a proper lady or lord. Your fate was set from birth.'),
            (1, 4, '<b>Merchant Family</b> You grew up among merchants, always surrounded by yelling, haggling, and money.'),
            (1, 5, '<b>Artisan Family</b> You grew up in an artisan''s workshop. Your days were filled with the incessant sounds of creation.'),
            (1, 6, '<b>Entertainer Family</b> You grew up with a band of performers. You may have traveled or you may have performed at a theater.'),
            (1, 8, '<b>Peasant Family</b> You grew up on a farm in the countryside. You didn''t have much to your name and life was simple, but dangerous.'),
            (2, 1, '<b>Aristocracy</b> You grew up in a manor, trained to be well-versed in the world of the court. The luxury was just your incentive.'),
            (2, 2, '<b>High Clergy</b> You were raised among the clergy of the Great Sun. You grew up pious and always aware that the Church would guide you.'),
            (2, 3, '<b>Knights</b> You grew up knowing that your duty was to the Emperor, and that all of your luxury was reward for your eventual service.'),
            (2, 4, '<b>Artisan Family</b> You grew up in an artisan''s shop, learning to craft products valued for their quality.'),
            (2, 5, '<b>Merchant Family</b> You grew up selling products around the Empire. You saw exotic goods from all around the world.'),
            (2, 6, '<b>Born into Servitude</b> You were born into servitude and lived in simple quarters. You owned very little and toiled often.'),
            (2, 8, '<b>Peasant Family</b> You grew up on one of the thousands of farms across the Empire. You had little to your name but life was simple.'),
            (3, 1, '<b>Aristocracy</b> You grew up in a palace and were constantly reminded of the glory of the past. You were expected to live up to your heritage.'),
            (3, 2, '<b>Noble Warrior</b> You grew up as a noble warrior''s child, expected to rise to your family''s reputation and to never dishonor your heritage.'),
            (3, 3, '<b>Merchants</b> You grew up among traveling merchants. Life was difficult sometimes but non-human crafts are always valuable.'),
            (3, 4, '<b>Scribe Family</b> You grew up as the child of scribes, recording and protecting elderfolk history.'),
            (3, 5, '<b>Entertainers</b> You grew up singing songs and performing plays. You worked backstage, helped write songs, and fixed instruments.'),
            (3, 6, '<b>Artisan Family</b> You grew up in a family of artisans, visiting ancient palaces for inspiration and spending hours every day on projects.'),
            (3, 8, '<b>Lowborn Family</b> You grew up in a lowborn family, tending to the manors of others or working small jobs around your home city.')
         ) AS status_en(group_id, num, status_txt)
)
, ins_status_txt AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*status_data.group_id+status_data.num, 'FM0000') ||'.'|| meta.entity ||'.'|| 'family_status') AS id
       , meta.entity, 'family_status', status_data.lang, status_data.status_txt
    FROM status_data
    CROSS JOIN meta
)
, gear_data AS (
  SELECT 'ru' AS lang, gear_ru.*
    FROM (VALUES
            (1, 1, 1, 'Дворянская грамота', '+2 к репутации', NULL),
            (1, 2, 1, 'Летопись', '+1 к Образованию', NULL),
            (1, 3, 1, 'Личный герб', '+1 к репутации', NULL),
            (1, 4, 1, 'знакомый', NULL, 2),
            (1, 5, 1, 'обычный чертеж/формула', NULL, 3),
            (1, 6, 1, 'музыкальный инструмент', NULL, 1),
            (1, 6, 2, 'друг', NULL, 1),
            (1, 8, 1, 'Счастливый талисман', '+1 к Удаче', NULL),
            (2, 1, 1, 'Дворянская грамота', '+2 к репутации', NULL),
            (2, 2, 1, 'Священный символ', '+1 к Храбрости', NULL),
            (2, 3, 1, 'Личный герб', '+1 к репутации', NULL),
            (2, 4, 1, 'обычный чертеж/формула', NULL, 3),
            (2, 5, 1, 'знакомый', NULL, 2),
            (2, 6, 1, 'Обученная птица или змей', NULL, NULL),
            (2, 8, 1, 'Счастливый талисман', '+1 к Удаче', NULL),
            (3, 1, 1, 'Дворянская грамота', '+2 к репутации', NULL),
            (3, 2, 1, 'Личный герб', '+1 к репутации', NULL),
            (3, 3, 1, 'знакомый', NULL, 2),
            (3, 4, 1, 'Летопись', '+1 к Образованию', NULL),
            (3, 5, 1, 'музыкальный инструмент', NULL, 1),
            (3, 5, 2, 'друг', NULL, 1),
            (3, 6, 1, 'обычный чертеж/формула', NULL, 3),
            (3, 8, 1, 'Счастливый талисман', '+1 к Удаче', NULL)
          ) AS gear_ru(group_id, num, item_num, gear_name, gear_notes, gear_amount)
  UNION ALL
  SELECT 'en' AS lang, gear_en.*
    FROM (VALUES
            (1, 1, 1, 'Paper of Nobility', '+2 Reputation', NULL),
            (1, 2, 1, 'A Chronicle', '+1 Education', NULL),
            (1, 3, 1, 'Personal Heraldry', '+1 Reputation', NULL),
            (1, 4, 1, 'Acquaintance', NULL, 2),
            (1, 5, 1, 'Common Diagram/Formula', NULL, 3),
            (1, 6, 1, 'Instrument', NULL, 1),
            (1, 6, 2, 'Friend', NULL, 1),
            (1, 8, 1, 'A Lucky Token', '+1 Luck', NULL),
            (2, 1, 1, 'Paper of Nobility', '+2 Reputation', NULL),
            (2, 2, 1, 'A Holy Symbol', '+1 Courage', NULL),
            (2, 3, 1, 'Personal Heraldry', '+1 Reputation', NULL),
            (2, 4, 1, 'Common Diagram/Formula', NULL, 3),
            (2, 5, 1, 'Acquaintance', NULL, 2),
            (2, 6, 1, 'A trained bird or serpent', NULL, NULL),
            (2, 8, 1, 'A Lucky Token', '+1 Luck', NULL),
            (3, 1, 1, 'Paper of Nobility', '+2 Reputation', NULL),
            (3, 2, 1, 'Personal Heraldry', '+1 Reputation', NULL),
            (3, 3, 1, 'Acquaintance', NULL, 2),
            (3, 4, 1, 'A Chronicle', '+1 Education', NULL),
            (3, 5, 1, 'Instrument', NULL, 1),
            (3, 5, 2, 'Friend', NULL, 1),
            (3, 6, 1, 'Common Diagram/Formula', NULL, 3),
            (3, 8, 1, 'A Lucky Token', '+1 Luck', NULL)
         ) AS gear_en(group_id, num, item_num, gear_name, gear_notes, gear_amount)
)
, ins_gear_name AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*gear_data.group_id+gear_data.num, 'FM0000') ||'.'|| 'gear' ||'.'|| gear_data.item_num ||'.'|| 'name') AS id
       , 'character', 'gear_name', gear_data.lang, gear_data.gear_name
    FROM gear_data
    CROSS JOIN meta
)
, ins_gear_notes AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*gear_data.group_id+gear_data.num, 'FM0000') ||'.'|| 'gear' ||'.'|| gear_data.item_num ||'.'|| 'notes') AS id
       , 'character', 'gear_notes', gear_data.lang, gear_data.gear_notes
    FROM gear_data
    CROSS JOIN meta
    WHERE gear_data.gear_notes IS NOT NULL
)
-- Эффекты для всех вариантов ответов
, raw_data AS (
  SELECT DISTINCT group_id, num
  FROM (VALUES
          (1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 8),
          (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (2, 6), (2, 8),
          (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (3, 6), (3, 8)
        ) AS v(group_id, num)
)
, gear_items AS (
  SELECT DISTINCT group_id, num, item_num, CASE WHEN gear_notes IS NOT NULL THEN 1 ELSE 0 END AS is_gear_notes, gear_amount
  FROM gear_data
)
INSERT INTO effects (scope, an_an_id, body)
-- Эффект: Установка family_status
SELECT 'character', 'wcc_past_family_status_o' || to_char(raw_data.group_id, 'FM00') || to_char(raw_data.num, 'FM00'),
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.lore.family_status'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*raw_data.group_id+raw_data.num, 'FM0000') ||'.'|| meta.entity ||'.'|| 'family_status')::text)
    )
  )
FROM raw_data
CROSS JOIN meta
UNION ALL
-- Эффект: Добавление предметов в gear (кроме чертежей — для них выдаётся жетон)
SELECT 'character', 'wcc_past_family_status_o' || to_char(gear_items.group_id, 'FM00') || to_char(gear_items.num, 'FM00'),
  jsonb_build_object(
    'when', '{"!==":[{"var":"characterRaw.logicFields.race"},"Witcher"]}'::jsonb,
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.gear'),
      (
        jsonb_build_object(
          'name', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*gear_items.group_id+gear_items.num, 'FM0000') ||'.'|| 'gear' ||'.'|| gear_items.item_num ||'.'|| 'name')::text),
          'weight', 0
        ) ||
        CASE WHEN gear_items.is_gear_notes = 1
          THEN jsonb_build_object('notes', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*gear_items.group_id+gear_items.num, 'FM0000') ||'.'|| 'gear' ||'.'|| gear_items.item_num ||'.'|| 'notes')::text))
          ELSE '{}'::jsonb
        END ||
        CASE WHEN gear_items.gear_amount IS NOT NULL 
          THEN jsonb_build_object('amount', gear_items.gear_amount)
          ELSE '{}'::jsonb
        END
      )
    )
  )
FROM gear_items
CROSS JOIN meta
WHERE gear_items.gear_amount IS DISTINCT FROM 3
UNION ALL
-- Эффект: вместо чертежей в инвентарь — 1 жетон simple_blueprint_tokens (3 варианта: Семья мастеров / Артисты по группам)
SELECT 'character', 'wcc_past_family_status_o' || to_char(blueprint_opt.group_id, 'FM00') || to_char(blueprint_opt.num, 'FM00'),
  jsonb_build_object(
    'when', '{"!==":[{"var":"characterRaw.logicFields.race"},"Witcher"]}'::jsonb,
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.money.simple_blueprint_tokens'),
      1
    )
  )
FROM (VALUES (1, 5), (2, 4), (3, 6)) AS blueprint_opt(group_id, num);
  
-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_past_family_fate' , 'wcc_past_family_status' UNION ALL
  SELECT 'wcc_past_parents'     , 'wcc_past_family_status' UNION ALL
  SELECT 'wcc_past_parents_fate', 'wcc_past_family_status' UNION ALL
  SELECT 'wcc_past_parents_who' , 'wcc_past_family_status';