\echo '053_witcher_current_situation.sql'
-- Узел: Каково ваше нынешнее положение?

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_current_situation' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
         , meta.entity, 'body', v.lang, v.text
    FROM (VALUES
      ('ru', 'Определите текущее положение ведьмака.'),
      ('en', 'Determine your witcher''s current situation.')
    ) AS v(lang, text)
    CROSS JOIN meta
  )
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Нынешнее положение'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Where You Are Now')
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
           SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_witcher_current_situation' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
           FROM (SELECT DISTINCT num FROM c_vals) AS cols
         ),
         'path', jsonb_build_array(
           ck_id('witcher_cc.hierarchy.witcher')::text,
           ck_id('witcher_cc.hierarchy.witcher_current_situation')::text
         )
       )
    FROM meta;

-- Ответы
WITH
raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
  FROM (VALUES
    (1, 0.1, '<b>Личный ведьмак</b><br>Вы подписали контракт с группой торговцев, знатным домом или важной персоной и стали личным ведьмаком. Вы работаете за скромную плату и охотитесь на кого скажут. Обычно на чудовищ…'),
    (2, 0.1, '<b>В поисках работы</b><br>Тяжёлая ведьмачья жизнь продолжается. Вы много странствуете, с грустью думая об отмирании профессии ведьмака и о редкости чудовищ. Вы постоянно в дороге, никогда не задерживаетесь на одном месте.'),
    (3, 0.6, '<b>Отшельник</b><br>Вы перестали быть ведьмаком и отправились в дикие земли, чтобы жить как отшельник. Лишь теперь, когда чудовища стали возвращаться, вы решили вновь выбраться в мир.'),
    (4, 0.1, '<b>Нормальная жизнь</b><br>Вы уже десятки лет пытаетесь оставить жизнь ведьмака. Это трудно, поскольку люди никогда не примут вас полностью, но вы кое-как ведёте практически нормальную жизнь. Желаем успехов!'),
    (5, 0.1, '<b>Опасный преступник</b><br>В итоге весь негатив и людская неблагодарность вас добили — вы решили, что поскольку чудовищ становится всё меньше, стоит переключиться на людей. Можете сами решить, чем вы промышляли ради выживания.')
  ) AS raw_data_ru(num, probability, txt)

  UNION ALL

  SELECT 'en' AS lang, raw_data_en.*
  FROM (VALUES
    (1, 0.1, '<b>Became a Personal Witcher</b><br>You signed on to work for a merchant group, noble house, or important person as a personal witcher. You work for modest pay and hunt what they tell you to hunt. Mostly it’s monsters…'),
    (2, 0.1, '<b>Looking For Work</b><br>The hard life of a witcher continues. You spend a lot of time on the road, lamenting the efficiency of your kind and the extinction of monsters. You travel constantly and never settle down.'),
    (3, 0.6, '<b>Became a Hermit</b><br>You gave up on the life of a witcher and traveled out into the wilderness. Now you live as a hermit in the wilds. Only now that monsters are returning have you started to venture out again.'),
    (4, 0.1, '<b>Turned to a Normal Life</b><br>You’ve tried for decades to leave the witcher life behind. It’s difficult, since people won’t ever really accept you, but you have managed to cobble together an almost normal life. Good luck.'),
    (5, 0.1, '<b>Became a Dangerous Criminal</b><br>Eventually all the negativity and thankless people got to you— you decided that with fewer and fewer monsters, it was time to start hunting people. You can determine what you do to survive.')
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
                , 'wcc_witcher_current_situation' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, ins_lbl AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
       , meta.entity, meta.entity_field, vals.lang, vals.text
  FROM vals
  CROSS JOIN meta
)
-- Создаем i18n записи для текстов без заголовков (для current_situation)
, ins_current_situation_text AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| 'lore' ||'.'|| 'current_situation') AS id
       , 'lore', 'current_situation', vals.lang, vals.text_after_br
  FROM vals
  CROSS JOIN meta
  WHERE vals.text_after_br != ''
  ON CONFLICT (id, lang) DO NOTHING
)

INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
SELECT
  'wcc_witcher_current_situation_o' || to_char(vals.num, 'FM00') AS an_id,
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

-- Эффекты: сохранение текста события в characterRaw.lore.current_situation
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_current_situation' AS qu_id)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_witcher_current_situation_o' || to_char(vals.num, 'FM00'),
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.current_situation'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| 'lore' ||'.'|| 'current_situation')::text)
    )
  )
FROM (SELECT DISTINCT num FROM (VALUES (1), (2), (3), (4), (5)) AS v(num)) AS vals
CROSS JOIN meta;

-- Переход с предыдущего узла
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_witcher_most_important_event', 'wcc_witcher_current_situation' UNION ALL
  SELECT 'wcc_witcher_child_who', 'wcc_witcher_current_situation' UNION ALL
  SELECT 'wcc_witcher_child_fate', 'wcc_witcher_current_situation';