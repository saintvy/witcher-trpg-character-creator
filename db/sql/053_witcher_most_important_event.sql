\echo '053_witcher_most_important_event.sql'
-- Узел: Самое важное событие

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_most_important_event' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
         , meta.entity, 'body', v.lang, v.text
    FROM (VALUES
      ('ru', 'Определите ключевое событие вашей ведьмачьей жизни.'),
      ('en', 'Determine a defining event from your witcher''s life.')
    ) AS v(lang, text)
    CROSS JOIN meta
  )
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Самое важное событие'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Most Important Event')
  )
, ins_cols AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| 'column_name') AS id
         , meta.entity, 'column_name', c_vals.lang, c_vals.text
    FROM c_vals
    CROSS JOIN meta
  )

INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
SELECT meta.qu_id
     , meta.su_su_id
     , NULL
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body')
     , 'single_table'
     , jsonb_build_object(
         'dice', 'd_weighed',
         'columns', (
           SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_witcher_most_important_event' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
           FROM (SELECT DISTINCT num FROM c_vals) AS cols
         ),
         'path', jsonb_build_array(
           ck_id('witcher_cc.hierarchy.witcher')::text,
           ck_id('witcher_cc.hierarchy.witcher_most_important_event')::text
         )
       )
    FROM meta;

-- Ответы
WITH
raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
  FROM (VALUES
    (1, 0.1, '<b>Получил дитя по Праву Неожиданности</b><br>Во время своих путешествий вы воспользовались Правом Неожиданности и получили дитя. Это мог быть мальчик — тогда вы отдали его в ведьмаки. Если же девочка, её судьба была в ваших руках.'),
    (2, 0.1, '<b>Нападение разумного чудовища</b><br>На охоте ситуация обернулась против вас. Разумные чудовища вроде кладбищенских баб и катаканов крайне опасны, и добычей едва не стали вы.'),
    (3, 0.1, '<b>Сражался плечом к плечу с рыцарем</b><br>Вы дрались вместе с благородным рыцарем. Случайно это было или нет, после этой битвы вы иначе смотрите на рыцарей и на работу ведьмака.'),
    (4, 0.1, '<b>Был схвачен магом для экспериментов</b><br>Маги жаждут раскрыть тайны ведьмачьих мутаций. Однажды вас захватил маг и ставил над вами эксперименты, пытаясь разгадать секрет.'),
    (5, 0.1, '<b>Работал на дворянина</b><br>Некоторое время вы служили дворянину. Платили хорошо, но приходилось скрывать большинство поступков, чтобы не позорить нанявшую вас семью, вытаскивая их тайны на свет.'),
    (6, 0.1, '<b>Выход за пределы</b><br>Вы отправлялись за пределы Континента — через Драконьи горы, Тир Тохаир, Синие горы или Великое море. Увидели дальние земли, неизвестные большинству.'),
    (7, 0.1, '<b>Серьёзные отношения</b><br>Обычно ведьмаки избегают привязанностей, но вы влюбились и даже подумывали осесть. До сих пор иногда вспоминаете об этом.'),
    (8, 0.1, '<b>Сражение за свою крепость</b><br>Вы пережили осаду ведьмачьего замка. Вас было мало, но вы остались. Вы выжили с тяжёлыми ранениями, наблюдая, как гибнут товарищи.'),
    (9, 0.1, '<b>Дурная слава</b><br>Вы избавили город от чудовища, но люди испугались и отвернулись. Возможно, даже пытались убить вас. Так вы узнали, какой «награды» можно ждать.'),
    (10, 0.1, '<b>Слава героя</b><br>В другом месте, избавив людей от чудовища, вы были приняты как герой. Не ожидали бесплатной выпивки и восхищённых взглядов — но получили их. Больше такой доброты вы не встречали.')
  ) AS raw_data_ru(num, probability, txt)

  UNION ALL

  SELECT 'en' AS lang, raw_data_en.*
  FROM (VALUES
    (1, 0.1, '<b>Given a Child by the Law of Surprises</b><br>Along your travels you invoked the Law of Surprises and received a child. They may have been a boy, in which case they were made into a witcher, or a girl, in which case their fate was up to you.'),
    (2, 0.1, '<b>Hunted by a Sentient Monster</b><br>The tables turned during one of your hunts. Sentient monsters like grave hags and katakan can be dangerous quarry, and you wound up becoming the hunted for a stressful night.'),
    (3, 0.1, '<b>Fought Alongside a Knight</b><br>You did battle alongside a noble knight. This may have been against both of your wishes or even an accident, but fighting beside a noble changed your outlook on knights and your job as a witcher.'),
    (4, 0.1, '<b>Captured by a Mage for Testing</b><br>Mages lust after the secrets of Witcher mutations. At some point you were captured by a mage who experimented on you in an attempt to reverse-engineer them.'),
    (5, 0.1, '<b>Worked for a Nobleman</b><br>For a time you worked for a nobleman. The pay was good, but it was strange and aggravating to have to hide most of your actions to avoid shaming the family by bringing their secrets to light.'),
    (6, 0.1, '<b>Went Beyond the Boundaries</b><br>Once, you traveled beyond the borders of the Continent—past the Dragon Mountains, the Tir Tochair or the Blue Mountains, or the Great Sea. You have seen far lands unknown to most others.'),
    (7, 0.1, '<b>Meaningful Romance</b><br>Most witchers remain neutral and avoid meaningful relationships. However, this didn’t stop you. You fell in love and actually considered settling down. It still occurs to you sometimes.'),
    (8, 0.1, '<b>Fought for Your Keep</b><br>You fought at a siege of your keep. You were outnumbered and overpowered, but you stayed nonetheless. You survived the siege with serious wounds, but saw your brethren dying around you.'),
    (9, 0.1, '<b>Gained Infamy</b><br>After helping a city with a monster, the people became afraid and turned on you. They might even have tried to kill you. Either way, you’ve seen what kind of reward you can expect from people.'),
    (10, 0.1, '<b>Gained Fame</b><br>You were well-received in a town after helping them with a monster. You didn’t expect free drinks or women casting you glances, but that’s what you got. You haven’t seen such kindness again, but it was heartening.')
  ) AS raw_data_en(num, probability, txt)
),

vals AS (
  SELECT
    ('<td>' || to_char(probability*100, 'FM990.00') || '%</td>'
     || '<td>' || txt || '</td>') AS text,
    num, probability, lang,
    -- Извлекаем текст после <br> (убираем <b>...</b><br>)
    CASE 
      WHEN position('<br>' in txt) > 0 
      THEN substring(txt from position('<br>' in txt) + 4)
      ELSE ''
    END AS text_after_br
  FROM raw_data
)
, meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_most_important_event' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, ins_lbl AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
       , meta.entity, meta.entity_field, vals.lang, vals.text
  FROM vals
  CROSS JOIN meta
)
-- Создаем i18n записи для текстов без заголовков (для most_important_event)
, ins_most_important_event_text AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| 'lore' ||'.'|| 'most_important_event') AS id
       , 'lore', 'most_important_event', vals.lang, vals.text_after_br
  FROM vals
  CROSS JOIN meta
  WHERE vals.num > 1 AND vals.text_after_br != ''
  ON CONFLICT (id, lang) DO NOTHING
)

INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
SELECT
  'wcc_witcher_most_important_event_o' || to_char(vals.num, 'FM00') AS an_id,
  meta.su_su_id,
  meta.qu_id,
  ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
  vals.num,
  jsonb_build_object(
           'probability', vals.probability
  )
FROM vals
CROSS JOIN meta
ON CONFLICT (an_id) DO NOTHING;

-- Эффекты: сохранение текста события в characterRaw.lore.most_important_event (для вариантов 2-10)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_most_important_event' AS qu_id)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_witcher_most_important_event_o' || to_char(vals.num, 'FM00'),
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.most_important_event'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| 'lore' ||'.'|| 'most_important_event')::text)
    )
  )
FROM (SELECT DISTINCT num FROM (VALUES (2), (3), (4), (5), (6), (7), (8), (9), (10)) AS v(num)) AS vals
CROSS JOIN meta;

-- Переход с предыдущего узла
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_witcher_trials', 'wcc_witcher_most_important_event';





























