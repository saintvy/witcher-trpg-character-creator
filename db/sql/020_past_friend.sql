\echo '020_past_friend.sql'
-- Узел: Повлиявший друг

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_friend' AS qu_id
                , 'questions' AS entity)
, ins_body AS (INSERT INTO i18n_text (id, entity, entity_field, lang, text)
                  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
                       , meta.entity, 'body', v.lang, v.text
                    FROM (VALUES
                            ('ru', 'Кто больше всего повлиял на ваше мировоззрение?'),
                            ('en', 'Who influenced your worldview the most?')) AS v(lang, text)
                    CROSS JOIN meta)
, c_vals(lang, num, text) AS (VALUES ('ru', 1, 'Шанс'),
                                     ('ru', 2, 'Друг/Влияние'),
                                     ('ru', 3, 'Начальное снаряжение'),
                                     ('en', 1, 'Chance'),
                                     ('en', 2, 'Friend/Influence'),
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
             SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_past_friend' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
             FROM (SELECT DISTINCT num FROM c_vals) AS cols
           ),
           'path', jsonb_build_array(
             ck_id('witcher_cc.hierarchy.family')::text,
             ck_id('witcher_cc.hierarchy.friend')::text
           )
         )
    FROM meta;


-- Ответы (каждый вариант 10%)
WITH
raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
            -- group 1: Северянин
            (1, 1, 0.1, '<b>Церковь</b> На вас сильно повлияла местная религия. Вы ежедневно проводили много часов в церкви.', 'Священный текст'),
            (1, 2, 0.1, '<b>Ремесленник</b> Вдохновением вам служил ремесленник, научивший ценить искусство и мастерство.', 'Изготовленный вами сувенир'),
            (1, 3, 0.1, '<b>Граф</b> Наибольшее влияние на вас оказал граф (графиня), научивший брать себя в руки.', 'Серебряное кольцо'),
            (1, 4, 0.1, '<b>Маг</b> Наибольшее влияние оказал маг, научивший не бояться магии и всё подвергать сомнению.', 'Подвеска'),
            (1, 5, 0.1, '<b>Ведьма</b> Наибольшее влияние на вас оказала деревенская ведьма, показавшая ценность знаний.', 'Кукла для чёрной магии'),
            (1, 6, 0.1, '<b>Проклятый</b> Наибольшее влияние на вас оказал человек, страдавший от проклятия; он научил вас никогда никого не судить слишком строго.', 'Резной тотем'),
            (1, 7, 0.1, '<b>Артист</b> Наибольшее влияние на вас оказал артист, что научил множеству способов привлечь к себе внимание.', 'Афиша или билет'),
            (1, 8, 0.1, '<b>Торговец</b> Наибольшее влияние оказал торговец, научивший изворотливости и сообразительности.', 'Заработанная вами монетка'),
            (1, 9, 0.1, '<b>Преступник</b> Наибольшее влияние на вас оказал преступник, научивший вас, как о себе позаботиться.', 'Маска'),
            (1,10, 0.1, '<b>Воин</b> Наибольшее влияние на вас оказал солдат, научивший защищаться.', 'Боевой трофей'),

            -- group 2: Нильфгаардец
            (2, 1, 0.1, '<b>Культ Великого Солнца</b> На вас сильно повлияла церковь. Вы посвятили годы изучению ритуалов и песнопений.', 'Церемониальная маска'),
            (2, 2, 0.1, '<b>Изгнанник</b> Наибольшее влияние на вас оказал изгнанник, научивший сомневаться в устоях общества.', 'Яркий разноцветный значок'),
            (2, 3, 0.1, '<b>Граф</b> Наибольшее влияние на вас оказал граф, научивший вести других за собой и управлять людьми.', 'Серебряное ожерелье'),
            (2, 4, 0.1, '<b>Маг</b> Наибольшее влияние на вас оказал маг, научивший важности порядка и осторожности.', 'Эмблема'),
            (2, 5, 0.1, '<b>Следователь</b> Наибольшее влияние на вас оказал имперский детектив; вы провели много времени за разгадыванием тайн.', 'Лупа'),
            (2, 6, 0.1, '<b>Охотник на магов</b> Наибольшее влияние оказал охотник на магов, научивший остерегаться магии и магов.', 'Кольцо с димеритом'),
            (2, 7, 0.1, '<b>Воин</b> Наибольшее влияние на вас оказал солдат, травивший байки об опасностях и приключениях.', 'Боевой трофей'),
            (2, 8, 0.1, '<b>Ремесленник</b> Вдохновением вам служил ремесленник, научивший ценить навыки и точность.', 'Изготовленная вами безделушка'),
            (2, 9, 0.1, '<b>Разумное чудовище</b> Наибольшее влияние оказало разумное чудовище, научившее вас, что не все чудовища — зло.', 'Странный тотем'),
            (2,10, 0.1, '<b>Артист</b> Наибольшее влияние на вас оказал артист, у которого вы научились самовыражаться.', 'Подарок от поклонника'),

            -- group 3: Нелюдь (Elderland)
            (3, 1, 0.1, '<b>Человек</b> Наибольшее влияние на вас оказал человек, благодаря которому вы узнали, что расизм не всегда имеет основания.', 'Соломенная кукла'),
            (3, 2, 0.1, '<b>Ремесленник</b> Вдохновением вам служил ремесленник, научивший ценить искусство Старших Народов.', 'Изготовленный вами небольшой сувенир'),
            (3, 3, 0.1, '<b>Благородный воин</b> Наибольшее влияние на вас оказал боевой танцор или защитник Махакама, научивший вас понятию чести.', 'Подарок в память о битве'),
            (3, 4, 0.1, '<b>Высокорожденный</b> Наибольшее влияние оказал высокорожденный, научивший вас гордости и правилам этикета.', 'Кольцо-печатка'),
            (3, 5, 0.1, '<b>Артисты</b> Наибольшее влияние на вас оказали артисты, благодаря которым вы познали важность счастья и красоты.', 'Афиша или билет'),
            (3, 6, 0.1, '<b>Налётчик</b> Наибольшее влияние на вас оказал налётчик, благодаря которому вы поняли, что у вас есть право брать то, что нужно.', 'Наплечная сумка'),
            (3, 7, 0.1, '<b>Мудрец</b> Наибольшее влияние на вас оказал мудрец, благодаря которому вы познали важность истории Старших Народов.', 'Книга сказок'),
            (3, 8, 0.1, '<b>Преступник</b> Наибольшее влияние на вас оказал преступник, научивший следовать собственным правилам.', 'Маска'),
            (3, 9, 0.1, '<b>Охотник</b> Наибольшее влияние на вас оказал охотник, научивший вас выживать в дикой природе.', 'Охотничий трофей'),
            (3,10, 0.1, '<b>Крестьянин из низин</b> Наибольшее влияние на вас оказал крестьянин из низин, научивший вас жить счастливо.', 'Крестьянская лопата')
          ) AS raw_data_ru(group_id, num, probability, friend_txt, gear)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
            -- group 1: Northern
            (1, 1, 0.1, '<b>A Church</b> You grew up with influence from your local religion and spent hours a day at church.', 'A Holy Text'),
            (1, 2, 0.1, '<b>An Artisan</b> Your greatest influence was an artisan who taught you to appreciate art and skill.', 'A Token You Made'),
            (1, 3, 0.1, '<b>A Count</b> Your greatest influence was a count or countess who taught you how to compose yourself.', 'A Silver Ring'),
            (1, 4, 0.1, '<b>A Mage</b> Your greatest influence was a mage who taught you not to fear magic and to always question.', 'A Small Pendant'),
            (1, 5, 0.1, '<b>A Witch</b> Your greatest influence was a village witch who taught you the importance of knowledge.', 'A Black Magic Doll'),
            (1, 6, 0.1, '<b>A Cursed Person</b> Your greatest influence was a cursed person who taught you to never judge others too harshly.', 'A Carved Totem'),
            (1, 7, 0.1, '<b>An Entertainer</b> Your greatest influence was an entertainer who taught you plenty about showmanship.', 'A Playbill or Ticket'),
            (1, 8, 0.1, '<b>A Merchant</b> Your greatest influence was a merchant who taught you how to be shrewd and clever.', 'A Coin You Earned'),
            (1, 9, 0.1, '<b>A Criminal</b> Your greatest influence was a criminal who taught you how to take care of yourself.', 'A Mask'),
            (1,10, 0.1, '<b>A Man At Arms</b> Your greatest influence was a soldier who taught you how to defend yourself.', 'A Battle Trophy'),

            -- group 2: Nilfgaardian
            (2, 1, 0.1, '<b>The Cult of the Great Sun</b> Your greatest influence was the Church. You spent years learning chants and rituals.', 'A Ceremonial Mask'),
            (2, 2, 0.1, '<b>An Outcast</b> Your greatest influence was a social outcast who taught you to always question society.', 'A Bright Colorful Badge'),
            (2, 3, 0.1, '<b>A Count</b> Your greatest influence was a count who taught you how to lead and instill order.', 'A Silver Necklace'),
            (2, 4, 0.1, '<b>A Mage</b> Your greatest influence was a mage who taught you the importance of order and caution.', 'An Emblem'),
            (2, 5, 0.1, '<b>A Solicitor</b> Your greatest influence was an imperial detective. You spent a lot of time solving mysteries.', 'A Magnifying Lens'),
            (2, 6, 0.1, '<b>A Mage Hunter</b> Your greatest influence was a mage hunter who taught you to be cautious of magic and mages.', 'A Ring with Dimeritium'),
            (2, 7, 0.1, '<b>A Man At Arms</b> Your greatest influence was a soldier who shared stories of danger and excitement.', 'A Trophy of Battle'),
            (2, 8, 0.1, '<b>An Artisan</b> Your greatest influence was an artisan who taught you to appreciate skill and precision.', 'A Trinket You Made'),
            (2, 9, 0.1, '<b>A Sentient Monster</b> Your greatest influence was a sentient monster that taught you that not all monsters are evil.', 'A Strange Totem'),
            (2,10, 0.1, '<b>An Entertainer</b> Your greatest influence was an entertainer who taught you to express yourself.', 'A Token from a Fan'),

            -- group 3: Elderland (non-human)
            (3, 1, 0.1, '<b>A Human</b> Your greatest influence was a human who taught you that sometimes racism is unfounded.', 'A Straw Doll'),
            (3, 2, 0.1, '<b>An Artisan</b> Your greatest influence was an artisan who taught you great elderfolk art.', 'A Small Token You Made'),
            (3, 3, 0.1, '<b>A Noble Warrior</b> Your greatest influence was a War Dancer or a Mahakaman Defender who taught you honor.', 'A Token of Battle'),
            (3, 4, 0.1, '<b>A Highborn</b> Your greatest influence was a highborn who taught you pride and how to comport yourself.', 'A Signet Ring'),
            (3, 5, 0.1, '<b>An Entertainer</b> Your greatest influence was an entertainer who taught you the importance of happiness and beauty.', 'A Playbill or Ticket'),
            (3, 6, 0.1, '<b>A Raider</b> Your greatest influence was a raider who taught you that you have the right to take what you need.', 'A Satchel'),
            (3, 7, 0.1, '<b>A Sage</b> Your greatest influence was a sage who taught you about the importance of elderfolk history.', 'A Book of Tales'),
            (3, 8, 0.1, '<b>A Criminal</b> Your greatest influence was a criminal who taught you to follow your own rules.', 'A Mask'),
            (3, 9, 0.1, '<b>A Hunter</b> Your greatest influence was a hunter who taught you how to survive in the wilderness.', 'A Trophy of a Hunt'),
            (3,10, 0.1, '<b>A Lowland Farmer</b> Your greatest influence was a lowland farmer who taught you how to live happily.', 'A Farmer''s Spade')
         ) AS raw_data_en(group_id, num, probability, friend_txt, gear)
),
vals AS (
         SELECT ('<td>' || to_char(probability*100, 'FM990.00') || '%</td>' ||
                 '<td>' || friend_txt || '</td>' ||
                 '<td>' || gear || '</td>') AS text,
                num,
                probability,
                lang,
                group_id
         FROM raw_data
)
, meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_friend' AS qu_id
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
SELECT 'wcc_past_friend_o' || to_char(vals.group_id, 'FM00') || to_char(vals.num, 'FM00') AS an_id,
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

-- i18n записи для friend_txt и предметов из gear
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_friend' AS qu_id
                , 'character' AS entity)
, friend_data AS (
  SELECT 'ru' AS lang, friend_ru.*
    FROM (VALUES
            (1, 1, '<b>Церковь</b> На вас сильно повлияла местная религия. Вы ежедневно проводили много часов в церкви.'),
            (1, 2, '<b>Ремесленник</b> Вдохновением вам служил ремесленник, научивший ценить искусство и мастерство.'),
            (1, 3, '<b>Граф</b> Наибольшее влияние на вас оказал граф (графиня), научивший брать себя в руки.'),
            (1, 4, '<b>Маг</b> Наибольшее влияние оказал маг, научивший не бояться магии и всё подвергать сомнению.'),
            (1, 5, '<b>Ведьма</b> Наибольшее влияние на вас оказала деревенская ведьма, показавшая ценность знаний.'),
            (1, 6, '<b>Проклятый</b> Наибольшее влияние на вас оказал человек, страдавший от проклятия; он научил вас никогда никого не судить слишком строго.'),
            (1, 7, '<b>Артист</b> Наибольшее влияние на вас оказал артист, что научил множеству способов привлечь к себе внимание.'),
            (1, 8, '<b>Торговец</b> Наибольшее влияние оказал торговец, научивший изворотливости и сообразительности.'),
            (1, 9, '<b>Преступник</b> Наибольшее влияние на вас оказал преступник, научивший вас, как о себе позаботиться.'),
            (1,10, '<b>Воин</b> Наибольшее влияние на вас оказал солдат, научивший защищаться.'),
            (2, 1, '<b>Культ Великого Солнца</b> На вас сильно повлияла церковь. Вы посвятили годы изучению ритуалов и песнопений.'),
            (2, 2, '<b>Изгнанник</b> Наибольшее влияние на вас оказал изгнанник, научивший сомневаться в устоях общества.'),
            (2, 3, '<b>Граф</b> Наибольшее влияние на вас оказал граф, научивший вести других за собой и управлять людьми.'),
            (2, 4, '<b>Маг</b> Наибольшее влияние на вас оказал маг, научивший важности порядка и осторожности.'),
            (2, 5, '<b>Следователь</b> Наибольшее влияние на вас оказал имперский детектив; вы провели много времени за разгадыванием тайн.'),
            (2, 6, '<b>Охотник на магов</b> Наибольшее влияние оказал охотник на магов, научивший остерегаться магии и магов.'),
            (2, 7, '<b>Воин</b> Наибольшее влияние на вас оказал солдат, травивший байки об опасностях и приключениях.'),
            (2, 8, '<b>Ремесленник</b> Вдохновением вам служил ремесленник, научивший ценить навыки и точность.'),
            (2, 9, '<b>Разумное чудовище</b> Наибольшее влияние оказало разумное чудовище, научившее вас, что не все чудовища — зло.'),
            (2,10, '<b>Артист</b> Наибольшее влияние на вас оказал артист, у которого вы научились самовыражаться.'),
            (3, 1, '<b>Человек</b> Наибольшее влияние на вас оказал человек, благодаря которому вы узнали, что расизм не всегда имеет основания.'),
            (3, 2, '<b>Ремесленник</b> Вдохновением вам служил ремесленник, научивший ценить искусство Старших Народов.'),
            (3, 3, '<b>Благородный воин</b> Наибольшее влияние на вас оказал боевой танцор или защитник Махакама, научивший вас понятию чести.'),
            (3, 4, '<b>Высокорожденный</b> Наибольшее влияние оказал высокорожденный, научивший вас гордости и правилам этикета.'),
            (3, 5, '<b>Артисты</b> Наибольшее влияние на вас оказали артисты, благодаря которым вы познали важность счастья и красоты.'),
            (3, 6, '<b>Налётчик</b> Наибольшее влияние на вас оказал налётчик, благодаря которому вы поняли, что у вас есть право брать то, что нужно.'),
            (3, 7, '<b>Мудрец</b> Наибольшее влияние на вас оказал мудрец, благодаря которому вы познали важность истории Старших Народов.'),
            (3, 8, '<b>Преступник</b> Наибольшее влияние на вас оказал преступник, научивший следовать собственным правилам.'),
            (3, 9, '<b>Охотник</b> Наибольшее влияние на вас оказал охотник, научивший вас выживать в дикой природе.'),
            (3,10, '<b>Крестьянин из низин</b> Наибольшее влияние на вас оказал крестьянин из низин, научивший вас жить счастливо.')
          ) AS friend_ru(group_id, num, friend_txt)
  UNION ALL
  SELECT 'en' AS lang, friend_en.*
    FROM (VALUES
            (1, 1, '<b>A Church</b> You grew up with influence from your local religion and spent hours a day at church.'),
            (1, 2, '<b>An Artisan</b> Your greatest influence was an artisan who taught you to appreciate art and skill.'),
            (1, 3, '<b>A Count</b> Your greatest influence was a count or countess who taught you how to compose yourself.'),
            (1, 4, '<b>A Mage</b> Your greatest influence was a mage who taught you not to fear magic and to always question.'),
            (1, 5, '<b>A Witch</b> Your greatest influence was a village witch who taught you the importance of knowledge.'),
            (1, 6, '<b>A Cursed Person</b> Your greatest influence was a cursed person who taught you to never judge others too harshly.'),
            (1, 7, '<b>An Entertainer</b> Your greatest influence was an entertainer who taught you plenty about showmanship.'),
            (1, 8, '<b>A Merchant</b> Your greatest influence was a merchant who taught you how to be shrewd and clever.'),
            (1, 9, '<b>A Criminal</b> Your greatest influence was a criminal who taught you how to take care of yourself.'),
            (1,10, '<b>A Man At Arms</b> Your greatest influence was a soldier who taught you how to defend yourself.'),
            (2, 1, '<b>The Cult of the Great Sun</b> Your greatest influence was the Church. You spent years learning chants and rituals.'),
            (2, 2, '<b>An Outcast</b> Your greatest influence was a social outcast who taught you to always question society.'),
            (2, 3, '<b>A Count</b> Your greatest influence was a count who taught you how to lead and instill order.'),
            (2, 4, '<b>A Mage</b> Your greatest influence was a mage who taught you the importance of order and caution.'),
            (2, 5, '<b>A Solicitor</b> Your greatest influence was an imperial detective. You spent a lot of time solving mysteries.'),
            (2, 6, '<b>A Mage Hunter</b> Your greatest influence was a mage hunter who taught you to be cautious of magic and mages.'),
            (2, 7, '<b>A Man At Arms</b> Your greatest influence was a soldier who shared stories of danger and excitement.'),
            (2, 8, '<b>An Artisan</b> Your greatest influence was an artisan who taught you to appreciate skill and precision.'),
            (2, 9, '<b>A Sentient Monster</b> Your greatest influence was a sentient monster that taught you that not all monsters are evil.'),
            (2,10, '<b>An Entertainer</b> Your greatest influence was an entertainer who taught you to express yourself.'),
            (3, 1, '<b>A Human</b> Your greatest influence was a human who taught you that sometimes racism is unfounded.'),
            (3, 2, '<b>An Artisan</b> Your greatest influence was an artisan who taught you great elderfolk art.'),
            (3, 3, '<b>A Noble Warrior</b> Your greatest influence was a War Dancer or a Mahakaman Defender who taught you honor.'),
            (3, 4, '<b>A Highborn</b> Your greatest influence was a highborn who taught you pride and how to comport yourself.'),
            (3, 5, '<b>An Entertainer</b> Your greatest influence was an entertainer who taught you the importance of happiness and beauty.'),
            (3, 6, '<b>A Raider</b> Your greatest influence was a raider who taught you that you have the right to take what you need.'),
            (3, 7, '<b>A Sage</b> Your greatest influence was a sage who taught you about the importance of elderfolk history.'),
            (3, 8, '<b>A Criminal</b> Your greatest influence was a criminal who taught you to follow your own rules.'),
            (3, 9, '<b>A Hunter</b> Your greatest influence was a hunter who taught you how to survive in the wilderness.'),
            (3,10, '<b>A Lowland Farmer</b> Your greatest influence was a lowland farmer who taught you how to live happily.')
         ) AS friend_en(group_id, num, friend_txt)
)
, ins_friend_txt AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*friend_data.group_id+friend_data.num, 'FM0000') ||'.'|| meta.entity ||'.'|| 'friend') AS id
       , meta.entity, 'friend', friend_data.lang, friend_data.friend_txt
    FROM friend_data
    CROSS JOIN meta
)
, gear_data AS (
  SELECT 'ru' AS lang, gear_ru.*
    FROM (VALUES
            (1, 1, 'Священный текст'),
            (1, 2, 'Изготовленный вами сувенир'),
            (1, 3, 'Серебряное кольцо'),
            (1, 4, 'Подвеска'),
            (1, 5, 'Кукла для чёрной магии'),
            (1, 6, 'Резной тотем'),
            (1, 7, 'Афиша или билет'),
            (1, 8, 'Заработанная вами монетка'),
            (1, 9, 'Маска'),
            (1,10, 'Боевой трофей'),
            (2, 1, 'Церемониальная маска'),
            (2, 2, 'Яркий разноцветный значок'),
            (2, 3, 'Серебряное ожерелье'),
            (2, 4, 'Эмблема'),
            (2, 5, 'Лупа'),
            (2, 6, 'Кольцо с димеритом'),
            (2, 7, 'Боевой трофей'),
            (2, 8, 'Изготовленная вами безделушка'),
            (2, 9, 'Странный тотем'),
            (2,10, 'Подарок от поклонника'),
            (3, 1, 'Соломенная кукла'),
            (3, 2, 'Изготовленный вами небольшой сувенир'),
            (3, 3, 'Подарок в память о битве'),
            (3, 4, 'Кольцо-печатка'),
            (3, 5, 'Афиша или билет'),
            (3, 6, 'Наплечная сумка'),
            (3, 7, 'Книга сказок'),
            (3, 8, 'Маска'),
            (3, 9, 'Охотничий трофей'),
            (3,10, 'Крестьянская лопата')
          ) AS gear_ru(group_id, num, gear_name)
  UNION ALL
  SELECT 'en' AS lang, gear_en.*
    FROM (VALUES
            (1, 1, 'A Holy Text'),
            (1, 2, 'A Token You Made'),
            (1, 3, 'A Silver Ring'),
            (1, 4, 'A Small Pendant'),
            (1, 5, 'A Black Magic Doll'),
            (1, 6, 'A Carved Totem'),
            (1, 7, 'A Playbill or Ticket'),
            (1, 8, 'A Coin You Earned'),
            (1, 9, 'A Mask'),
            (1,10, 'A Battle Trophy'),
            (2, 1, 'A Ceremonial Mask'),
            (2, 2, 'A Bright Colorful Badge'),
            (2, 3, 'A Silver Necklace'),
            (2, 4, 'An Emblem'),
            (2, 5, 'A Magnifying Lens'),
            (2, 6, 'A Ring with Dimeritium'),
            (2, 7, 'A Trophy of Battle'),
            (2, 8, 'A Trinket You Made'),
            (2, 9, 'A Strange Totem'),
            (2,10, 'A Token from a Fan'),
            (3, 1, 'A Straw Doll'),
            (3, 2, 'A Small Token You Made'),
            (3, 3, 'A Token of Battle'),
            (3, 4, 'A Signet Ring'),
            (3, 5, 'A Playbill or Ticket'),
            (3, 6, 'A Satchel'),
            (3, 7, 'A Book of Tales'),
            (3, 8, 'A Mask'),
            (3, 9, 'A Trophy of a Hunt'),
            (3,10, 'A Farmer''s Spade')
         ) AS gear_en(group_id, num, gear_name)
)
, ins_gear_name AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*gear_data.group_id+gear_data.num, 'FM0000') ||'.'|| 'gear' ||'.'|| 'name') AS id
       , 'character', 'gear_name', gear_data.lang, gear_data.gear_name
    FROM gear_data
    CROSS JOIN meta
)
-- Эффекты для всех вариантов ответов
, raw_data AS (
  SELECT DISTINCT group_id, num
  FROM (VALUES
          (1, 1), (1, 2), (1, 3), (1, 4), (1, 5), (1, 6), (1, 7), (1, 8), (1, 9), (1,10),
          (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8), (2, 9), (2,10),
          (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3,10)
        ) AS v(group_id, num)
)
, gear_items AS (
  SELECT DISTINCT group_id, num
  FROM gear_data
)
INSERT INTO effects (scope, an_an_id, body)
-- Эффект: Установка friend
SELECT 'character', 'wcc_past_friend_o' || to_char(raw_data.group_id, 'FM00') || to_char(raw_data.num, 'FM00'),
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.lore.friend'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*raw_data.group_id+raw_data.num, 'FM0000') ||'.'|| meta.entity ||'.'|| 'friend')::text)
    )
  )
FROM raw_data
CROSS JOIN meta
UNION ALL
-- Эффект: Добавление предметов в gear
SELECT 'character', 'wcc_past_friend_o' || to_char(gear_items.group_id, 'FM00') || to_char(gear_items.num, 'FM00'),
  jsonb_build_object(
    'when', '{"!==":[{"var":"characterRaw.logicFields.race"},"Witcher"]}'::jsonb,
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.gear'),
      jsonb_build_object(
        'name', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*gear_items.group_id+gear_items.num, 'FM0000') ||'.'|| 'gear' ||'.'|| 'name')::text),
        'weight', 0
      )
    )
  )
FROM gear_items
CROSS JOIN meta;

-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_past_family_status', 'wcc_past_friend';