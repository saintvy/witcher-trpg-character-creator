\echo '022_past_magic_discovery_how.sql'

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_magic_discovery_how' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
              ('ru', 'Как обнаружились ваши способности?'),
              ('en', 'How were your powers discovered?')
           ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
)
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Эффект'),
      ('ru', 3, 'Событие'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Effect'),
      ('en', 3, 'Event')
)
, ins_c AS (
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
           ck_id('witcher_cc.hierarchy.magic_discovery')::text,
           ck_id('witcher_cc.hierarchy.magic_discovery_how')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO NOTHING;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_magic_discovery_how' AS qu_id
                , 'answer_options' AS entity)
, raw_data AS (
  SELECT 'ru' AS lang, raw_ru.*
    FROM (VALUES
            (1,  '-3 к Реакции Людей', '<b>Катастрофа</b><br>Открытие вашей магии было связано с ужасной катастрофой, когда вы были молоды. Однажды, не подозревая о своей связи с Хаосом, вы позволили своим эмоциям взять над вами верх. Возможно, вы сожгли своих родителей заживо, вызвали обвал или заморозили другого ребенка.', 1.0),
            (2,  '-2 к Реакции Людей', '<b>Случайное проклятие</b><br>Открытие твоей магии было связано с мощной ненавистью. Даже не планируя этого, вы набросились на кого-то в раннем детстве и прокляли его. Ведьмак мог снять проклятие, а может быть, оно до сих пор преследует их.', 1.0),
            (3,  NULL, '<b>Обнаружен магом</b><br>Когда вы были молоды, к вам домой пришел маг и поговорил наедине с вашими родителями. Он объяснил твоим родителям, что у тебя магический дар и без должной подготовки ты станешь опасен для всех.', 1.0),
            (4,  NULL, '<b>Вдохновлен магом</b><br>Однажды вы попали на демонстрацию странствующего мага, который показал вам чудеса магии. После демонстрации мага вы попытались скопировать их и обнаружили, что у вас есть дар. Твое вдохновение изучать магию полностью соответствовало планам мага.', 1.0),
            (5,  NULL, '<b>Ужасающее магическое развитие</b><br>Ваша магия развивалась в виде небольшой магической черты и расширялась оттуда. Однажды вы применили небольшой магический эффект во время игры, и это событие вас чертовски напугало. Вы понятия не имели, как это произошло или что может случиться, если вы попытаетесь сделать это снова.', 1.0),
            (6,  NULL, '<b>Радостное магическое развитие</b><br>Ваша магия развивалась в виде небольшой магической черты и расширялась оттуда. Однажды вы поняли как выполнить небольшой магический эффект, и быстро продемонстрировали его своей семье и друзьям.', 1.0),
            (7,  NULL, '<b>Насильно завербован магом</b><br>Странствующий маг увидел в вас потенциал и решил взять вас на обучение. Они могли запугать вашу семью, чтобы она выдала вас, или они могли украсть вас напрямую. Но в итоге тебя взяли на тренировку против твоей воли.', 1.0),
            (8,  NULL, '<b>Выкуплен магом</b><br>Странствующий маг увидел ваш потенциал, проезжая через родной город, и сделал предложение вашим родителям. Ты можешь даже не знать, сколько ты стоишь для своих родителей, но когда цена была согласована, и маг забрал тебя.', 1.0),
            (9,  '-2 к Реакции Людей', '<b>Проклятие, порожденное ненавистью</b><br>Ваш дар проявился, когда вы прокляли кого-то в своем родном городе. Злоба, которую вы держали против этого человека, росла и гнилась прямо под поверхностью, пока в конце концов не стала достаточно мощной, чтобы привлечь магию извне и не сформировала ужасное проклятие.', 1.0),
            (10, '-3 к Реакции Людей', '<b>Катастрофа</b><br>Вы узнали, что обладаете магическими способностями в юном возрасте, но скрывали это и пытались учиться самостоятельно. Неизбежно это имело неприятные последствия. Возможно, вы подожгли свой семейный дом, вызвали наводнение или вызвали опасную бурю. Так или иначе, все рухнуло.', 1.0)
         ) AS raw_ru(num, effect_txt, event_html, probability)
  UNION ALL
  SELECT 'en' AS lang, raw_en.*
    FROM (VALUES
            (1,  '-3 to People Reaction', '<b>Catastrophe</b><br>The discovery of your magic was tied to an unfortunate catastrophe when you were young. One day, unaware of your connection to Chaos, you let your emotions get the better of you. You may have burned your parents alive, triggered a cave-in, or frozen another child solid.', 1.0),
            (2,  '-2 to People Reaction', '<b>Accidental Curse</b><br>The discovery of your magic was tied to a powerful hatred. Without really planning on it, you lashed out at someone in your early childhood and cursed them. A witcher may have lifted the curse-or maybe it still plagues them to this day.', 1.0),
            (3,  NULL, '<b>Discovered by a Mage</b><br>When you were young, a mage came to your home and spoke with your parents privately. They explained to your parents that you had a magical gift and without proper training you would become a danger to everyone.', 1.0),
            (4,  NULL, '<b>Inspired by a Mage</b><br>One day you were treated to a demonstration by a traveling mage who showed you the wonders of magic. After the mage''s demonstration, you tried to copy them and found that you had a gift. Your inspiration to study magic was all according to the plans of the mage.', 1.0),
            (5,  NULL, '<b>Terrifying Magical Development</b><br>Your magic developed in the form of a small magical trait and expanded from there. One day you performed a small magical effect while playing and the event scared the hell out of you. You had no idea how it happened or what might happen if you tried to do it again.', 1.0),
            (6,  NULL, '<b>Joyous Magical Development</b><br>Your magic developed in the form of a small magical trait and expanded from there. One day you figured out how to perform a small magical effect and you quickly showed it off to your family and friends.', 1.0),
            (7,  NULL, '<b>Press-ganged by a Mage</b><br>A traveling mage saw potential in you and decided it was their duty to take you away to train. They may have intimidated your family into giving you over, or they may have directly stolen you. But in the end, you were taken to train against your will.', 1.0),
            (8,  NULL, '<b>Bought by a Mage</b><br>A traveling mage saw your potential while passing through your hometown and made an offer to your parents. You may not even know how much you were worth to your parents, but a price was agreed upon and you were taken away by the mage.', 1.0),
            (9,  '-2 to People Reaction', '<b>Grudge-born Curse</b><br>Your gift became apparent when you cursed someone in your hometown. A grudge you held against this person grew and festered just below the surface until it eventually became powerful enough to draw magic from the beyond and formed a terrible curse.', 1.0),
            (10, '-3 to People Reaction', '<b>Catastrophe</b><br>You learned you had magical capability at a young age but kept it hidden and tried to study on your own. Inevitably this backfired. You may have set fire to your family home, caused a flood, or summoned a dangerous storm. Either way, everything came crashing down.', 1.0)
         ) AS raw_en(num, effect_txt, event_html, probability)
)
, lore_data AS (
  SELECT 'ru' AS lang, raw_ru.*
    FROM (VALUES
            (1,  'Катастрофа', 'Открытие вашей магии было связано с ужасной катастрофой, когда вы были молоды.'),
            (2,  'Случайное проклятие', 'Открытие твоей магии было связано с мощной ненавистью.'),
            (3,  'Обнаружен магом', 'К вам домой пришел маг и объяснил вашим родителям, что у вас магический дар.'),
            (4,  'Вдохновлен магом', 'После демонстрации странствующего мага вы обнаружили у себя дар.'),
            (5,  'Ужасающее магическое развитие', 'Первый магический эффект во время игры вас сильно напугал.'),
            (6,  'Радостное магическое развитие', 'Вы поняли, как выполнить небольшой магический эффект, и показали его семье и друзьям.'),
            (7,  'Насильно завербован магом', 'Маг увидел в вас потенциал и забрал вас на обучение против воли.'),
            (8,  'Выкуплен магом', 'Маг договорился с вашими родителями и забрал вас на обучение.'),
            (9,  'Проклятие, порожденное ненавистью', 'Ваш дар проявился как сильное проклятие из личной вражды.'),
            (10, 'Катастрофа', 'Вы пытались тайно изучать магию, и это привело к катастрофическим последствиям.')
         ) AS raw_ru(num, short_title, short_description)
  UNION ALL
  SELECT 'en' AS lang, raw_en.*
    FROM (VALUES
            (1,  'Catastrophe', 'The discovery of your magic was tied to an unfortunate catastrophe when you were young.'),
            (2,  'Accidental Curse', 'The discovery of your magic was tied to a powerful hatred.'),
            (3,  'Discovered by a Mage', 'A mage came to your home and explained your magical gift to your parents.'),
            (4,  'Inspired by a Mage', 'You discovered your gift after a traveling mage''s demonstration.'),
            (5,  'Terrifying Magical Development', 'Your first magical effect happened in play and frightened you badly.'),
            (6,  'Joyous Magical Development', 'You figured out a small magical effect and quickly showed your family and friends.'),
            (7,  'Press-ganged by a Mage', 'A mage saw your potential and took you away for training against your will.'),
            (8,  'Bought by a Mage', 'A mage made a deal with your parents and took you away to train.'),
            (9,  'Grudge-born Curse', 'Your gift appeared as a powerful curse born from hatred.'),
            (10, 'Catastrophe', 'You studied magic in secret and it ended in disaster.')
         ) AS raw_en(num, short_title, short_description)
)
, ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM00') ||'.'|| meta.entity ||'.label') AS id
       , meta.entity, 'label', raw_data.lang
       , '<td style="color: grey;">' || to_char(raw_data.probability * 100, 'FM990.00') || '%</td><td>' || coalesce(raw_data.effect_txt, '') || '</td><td>' || raw_data.event_html || '</td>'
    FROM raw_data
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
, ins_lore_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(lore_data.num, 'FM00') ||'.lore.discovery_how') AS id
       , 'effects', 'discovery_how', lore_data.lang, '<b>' || lore_data.short_title || '</b><br>' || lore_data.short_description
    FROM lore_data
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
SELECT meta.qu_id || '_o' || to_char(raw_data.num, 'FM00') AS an_id
     , meta.su_su_id
     , meta.qu_id
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM00') ||'.'|| meta.entity ||'.label') AS label
     , raw_data.num
     , jsonb_build_object('probability', raw_data.probability)
  FROM raw_data
  CROSS JOIN meta
 WHERE raw_data.lang = 'ru'
ON CONFLICT (an_id) DO NOTHING;

WITH meta AS (
  SELECT 'witcher_cc' AS su_su_id
       , 'wcc_past_magic_discovery_how' AS qu_id
)
, nums AS (
  SELECT generate_series(1, 10) AS num
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  meta.qu_id || '_o' || to_char(nums.num, 'FM00') AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.discovery_how'),
      jsonb_build_object(
        'i18n_uuid',
        ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(nums.num, 'FM00') ||'.lore.discovery_how')::text
      )
    )
  ) AS body
FROM nums
CROSS JOIN meta;

-- Эффект: модификатор броска для "Реакция людей" (-3/-2/0), нормализованный под 6 равных исходов
WITH
  meta AS (
    SELECT 'wcc_past_magic_discovery_how' AS qu_id
  )
, mods AS (
    SELECT *
      FROM (VALUES
              (1,  -0.5::numeric),          -- -3 к броску d6
              (2,  -0.3333333333::numeric), -- -2 к броску d6
              (3,   0.0::numeric),
              (4,   0.0::numeric),
              (5,   0.0::numeric),
              (6,   0.0::numeric),
              (7,   0.0::numeric),
              (8,   0.0::numeric),
              (9,  -0.3333333333::numeric), -- -2 к броску d6
              (10, -0.5::numeric)           -- -3 к броску d6
           ) v(num, dice_modifier)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  meta.qu_id || '_o' || to_char(mods.num, 'FM00') AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'values.byQuestion.wcc_past_magic_discovery_how'),
      mods.dice_modifier
    )
  ) AS body
FROM mods
CROSS JOIN meta;

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, priority)
SELECT 'wcc_past_family_status_mage', 'wcc_past_magic_discovery_how', 1;
