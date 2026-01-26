\echo '051_witcher_trials.sql'
-- Узел: Как прошли испытания?

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_trials' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
         , meta.entity, 'body', v.lang, v.text
    FROM (VALUES
      ('ru', 'Результат Испытания травами.'),
      ('en', 'Result of the Trial of the Grasses.')
    ) AS v(lang, text)
    CROSS JOIN meta
  )
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Эффект'),
      ('ru', 3, 'Исход испытаний'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Effect'),
      ('en', 3, 'Outcome of the Trials')
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
           SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_witcher_trials' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
           FROM (SELECT DISTINCT num FROM c_vals) AS cols
         ),
         'diceModifier', jsonb_build_object(
           'jsonlogic_expression', jsonb_build_object(
             'var', 'values.byQuestion.wcc_witcher_when'
           )
         ),
         'path', jsonb_build_array(
           ck_id('witcher_cc.hierarchy.witcher')::text,
           ck_id('witcher_cc.hierarchy.witcher_trials')::text
         )
       )
    FROM meta;

-- Ответы
WITH
raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
  FROM (VALUES
    (1, 0.1, '-1 к Эмп и -1 к Тел', '<b>Почти смертельно</b><br>Испытание травами практически разрушило ваше тело. Вы пережили процесс, но ваши тело и разум навсегда повреждены.'),
    (2, 0.2, '-1 к Эмп', '<b>Тяжёлые последствия</b><br>Испытание травами у вас прошло тяжело, и ведьмаки, следившие за процессом, не были до конца уверены, что вы справитесь. Вы выжили, но разум ваш травмирован.'),
    (3, 0.6, 'Нет эффектов', '<b>Приемлемые мутации</b><br>Испытание травами прошло успешно. Вы стали ведьмаком без тяжёлых последствий, если не считать воспоминаний об ужасной боли.'),
    (4, 0.1, '+1 к Эмп и +1 к Лвк', '<b>Дополнительные мутации</b><br>Ваше тело очень хорошо отозвалось на Испытание травами, и вы получили дополнительные мутации. Вы успешно перенесли испытания, и вся испытанная боль того стоила.')
  ) AS raw_data_ru(num, probability, effect, txt)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
  FROM (VALUES
    (1, 0.1, '-1 EMP & -1 BODY', '<b>Nearly Fatal</b><br>The Trial of the Grasses nearly destroyed your body. Though you survived the process, your body and mind were damaged permanently.'),
    (2, 0.2, '-1 EMP', '<b>Poorly Accepted</b><br>The Trial of the Grasses went poorly and the witchers in charge of mutation weren’t entirely sure you would make it. You survived, but not without mental scars.'),
    (3, 0.6, 'No Modifiers', '<b>Passable Mutations</b><br>The Trial of the Grasses went well. You passed into the ranks of witchers with nothing more than memories of horrible pain.'),
    (4, 0.1, '+1 EMP & +1 DEX', '<b>Extra Mutations</b><br>Your body was very receptive to the Trial of the Grasses and you had extra mutations applied to you. Your body handled it well, and all of the pain paid off in the end.')
  ) AS raw_data_en(num, probability, effect, txt)
),

vals AS (
  SELECT
    ('<td>' || to_char(probability*100, 'FM990.00') || '%</td>'
     || '<td>' || effect || '</td>'
     || '<td>' || txt || '</td>') AS text,
    num, probability, lang
  FROM raw_data
)
, meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_trials' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, ins_lbl AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
       , meta.entity, meta.entity_field, vals.lang, vals.text
  FROM vals
  CROSS JOIN meta
)

INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
SELECT
  'wcc_witcher_trials_o' || to_char(vals.num, 'FM00') AS an_id,
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

-- Создаем i18n записи для типов событий (Неудача, Удача)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_trials' AS qu_id)
, ins_event_types AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  VALUES
    (ck_id('witcher_cc.wcc_witcher_trials.event_type_misfortune'), 'character', 'event_type', 'ru', 'Неудача'),
    (ck_id('witcher_cc.wcc_witcher_trials.event_type_misfortune'), 'character', 'event_type', 'en', 'Misfortune'),
    (ck_id('witcher_cc.wcc_witcher_trials.event_type_fortune'), 'character', 'event_type', 'ru', 'Удача'),
    (ck_id('witcher_cc.wcc_witcher_trials.event_type_fortune'), 'character', 'event_type', 'en', 'Fortune')
  ON CONFLICT (id, lang) DO NOTHING
)
-- Создаем i18n записи для кратких описаний событий
, ins_event_descriptions AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  VALUES
    -- Вариант 1: Почти смертельно
    (ck_id('witcher_cc.wcc_witcher_trials_o01.event_desc'), 'character', 'event_desc', 'ru', 'Едва пережил испытания травами. [-1 к Эмпатии] и [-1 к Телосложению]'),
    (ck_id('witcher_cc.wcc_witcher_trials_o01.event_desc'), 'character', 'event_desc', 'en', 'Almost survived the Trial of the Grasses. [-1 to EMP] and [-1 to BODY]'),
    -- Вариант 2: Тяжёлые последствия
    (ck_id('witcher_cc.wcc_witcher_trials_o02.event_desc'), 'character', 'event_desc', 'ru', 'Испытания травами прошли тяжело. [-1 к Эмпатии]'),
    (ck_id('witcher_cc.wcc_witcher_trials_o02.event_desc'), 'character', 'event_desc', 'en', 'The Trial of the Grasses went poorly. [-1 to EMP]'),
    -- Вариант 3: Приемлемые мутации
    (ck_id('witcher_cc.wcc_witcher_trials_o04.event_desc'), 'character', 'event_desc', 'ru', 'Испытания травами прошли превосходно. [+1 к Эмпатии] и [+1 к Ловкости]'),
    (ck_id('witcher_cc.wcc_witcher_trials_o04.event_desc'), 'character', 'event_desc', 'en', 'The Trial of the Grasses went perfectly. [+1 to EMP] and [+1 to DEX]')
  ON CONFLICT (id, lang) DO NOTHING
)
SELECT 1 FROM meta;

-- Эффекты для вариантов ответа
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_trials' AS qu_id)
INSERT INTO effects (scope, an_an_id, body)
-- Вариант 1: Неудача, -1 EMP.bonus, -1 BODY.bonus
SELECT 'character', 'wcc_witcher_trials_o01',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.lifeEvents'),
      jsonb_build_object(
        'timePeriod', jsonb_build_object(
          'jsonlogic_expression', jsonb_build_object('cat', jsonb_build_array(
            '0-',
            jsonb_build_object('var', 'counters.lifeEventsCounter')
          ))
        ),
        'eventType', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_witcher_trials.event_type_misfortune')::text),
        'description', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_witcher_trials_o01.event_desc')::text)
      )
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_trials_o01',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.statistics.EMP.bonus'),
      -1
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_trials_o01',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.statistics.BODY.bonus'),
      -1
    )
  )
FROM meta
UNION ALL
-- Вариант 2: Неудача, -1 EMP.bonus
SELECT 'character', 'wcc_witcher_trials_o02',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.lifeEvents'),
      jsonb_build_object(
        'timePeriod', jsonb_build_object(
          'jsonlogic_expression', jsonb_build_object('cat', jsonb_build_array(
            '0-',
            jsonb_build_object('var', 'counters.lifeEventsCounter')
          ))
        ),
        'eventType', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_witcher_trials.event_type_misfortune')::text),
        'description', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_witcher_trials_o02.event_desc')::text)
      )
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_trials_o02',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.statistics.EMP.bonus'),
      -1
    )
  )
FROM meta
UNION ALL
-- Вариант 3: Удача, +1 EMP.bonus, +1 DEX.bonus
SELECT 'character', 'wcc_witcher_trials_o04',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.lifeEvents'),
      jsonb_build_object(
        'timePeriod', jsonb_build_object(
          'jsonlogic_expression', jsonb_build_object('cat', jsonb_build_array(
            '0-',
            jsonb_build_object('var', 'counters.lifeEventsCounter')
          ))
        ),
        'eventType', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_witcher_trials.event_type_fortune')::text),
        'description', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_witcher_trials_o04.event_desc')::text)
      )
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_trials_o04',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.statistics.EMP.bonus'),
      1
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_trials_o04',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.statistics.DEX.bonus'),
      1
    )
  )
FROM meta;

-- Переход с предыдущего узла
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_witcher_first_trainings', 'wcc_witcher_trials';




























