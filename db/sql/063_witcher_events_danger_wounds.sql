\echo '063_witcher_events_danger_wounds.sql'

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_danger_wounds' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru','Выберите серьёзную рану, оставившую долгосрочные последствия.'),
        ('en','Choose a serious wound that left long-term effects.')
      ) AS v(lang,text)
      CROSS JOIN meta
  )
, c_vals(lang,num,text) AS (
    VALUES
      ('ru',1,'Рана'),
      ('ru',2,'Эффект'),
      ('ru',3,'Описание'),
      ('en',1,'Wound'),
      ('en',2,'Effect'),
      ('en',3,'Description')
  )
, ins_cols AS (
    INSERT INTO i18n_text (id,entity,entity_field,lang,text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| 'column_name') AS id
         , meta.entity, 'column_name', c_vals.lang, c_vals.text
      FROM c_vals
      CROSS JOIN meta
  )

INSERT INTO questions (qu_id,su_su_id,title,body,qtype,metadata)
SELECT meta.qu_id
     , meta.su_su_id
     , NULL
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body')
     , 'single_table'
     , jsonb_build_object(
         'dice', 'd0',
         'columns', (
           SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_witcher_events_danger_wounds' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
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
           ck_id('witcher_cc.hierarchy.witcher_events_danger')::text,
           ck_id('witcher_cc.hierarchy.witcher_events_danger_wounds')::text
         )
       )
  FROM meta;

-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_danger_wounds' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
  FROM (VALUES
    (1,'Плохо гнётся колено'             ,'-1 к Скор'                        , 'После ужасного ранения ваша нога была практически в невосстановимом состоянии. Даже после хирургического вмешательства и литров ведьмачьих эликсиров ваше колено не то, что раньше.'),
    (2,'Повреждённый глаз'               ,'-1 к зрительному Вниманию'        , 'Обычно ведьмаки двигаются достаточно быстро, чтобы уйти от удара по важному месту, но некоторые чудовища быстрее. Из-за удара в глаз вы чуть хуже видите.'),
    (3,'Плохо гнётся рука'               ,'-1 к Ближнему бою этой рукой'     , 'После удара по руке вы много месяцев лечились, но в итоге рука стала чуть жестче. Вы можете держать меч и сражаться, но скованность подвижности вам мешает.'),
    (4,'Повреждённые пальцы'             ,'Нельзя сотворять знаки этой рукой', 'Возможно, это следствие пытки или очень неудачного удара по руке в бою — в любом случае пальцы этой руки плохо слушаются.'),
    (5,'Наконечник стрелы застрял в теле','-1 к Силе'                        , 'В вас попали стрелой с зазубренным наконечником, который засел глубоко в мышцах. С тех пор вам больно поднимать тяжести.'),
    (6,'Одышка'                          ,'-5 к Выносливости'                , 'Вас проткнули лёгкое или вы вдохнули токсичный газ. Так или иначе, ваши лёгкие повреждены, дышать стало тяжелее.'),
    (7,'Огромный шрам'                   ,'-2 к Харизме и Соблазнению'       , 'Ничего необычного в том, что ведьмак покрыт шрамами, но вас изуродовало особенно сильно. На всё лицо у вас глубокий шрам.'),
    (8,'Повреждённый нос'                ,'-2 к Выживанию в дикой природе при выслеживании по запаху', 'Несколько ударов по лицу в драках (или ядовитые газы) повредили ваш нос и практически лишили способности выслеживать по запаху.'),
    (9,'Повреждение от яда'              ,'-5 Пункт Здоровья'                , 'Токсины, что некогда отравили вашу кровь, оставили на коже чёрные вены вокруг раны и ослабили тело.'),
    (10,'Полуплухой'                     ,'-1 к слуховому Вниманию'          , 'Многие чудовища используют смертельно опасные звуковые атаки. Вам повезло пережить такое нападение, но слух уже не тот.')
  ) AS raw_data_ru(num, wound, effect, descr)

  UNION ALL

  SELECT 'en' AS lang, raw_data_en.*
  FROM (VALUES
    (1,'Stiff Knee'         ,'-1 SPD'                       , 'A horrible wound to your leg left it shattered and nearly unrepairable. Even after surgery and a regimen of witcher potions, it has never been the same.'),
    (2,'Damaged Eye'        ,'-1 Sight Awareness'           , 'Usually witchers are fast enough to avoid a vital strike, but some monsters are too fast. A shot to your eye left it mildly hazy.'),
    (3,'Stiff Arm'          ,'-1 Melee with that arm'       , 'A shattering blow to your arm left you with weeks of recovery and a stiff arm. You can still hold a sword and fight, but the stiffness always aggravates you.'),
    (4,'Damaged Fingers'    ,'Can’t do signs with that hand', 'It may have been the result of torture or just a very unlucky strike to that hand in combat, but its fingers are stiff and awkward.'),
    (5,'Embedded Arrowhead' ,'-1 Physique'                  , 'A marksman’s shot and a barbed head left an arrow-head deep in your body, lodged in your muscle. Strenuous lifting has been painful ever since.'),
    (6,'Wheeze'             ,'-5 Stamina'                   , 'You may have been stabbed in the lung or inhaled a toxic gas. Either way, your lungs have been damaged; breathing normally is somewhat difficult.'),
    (7,'Huge Scar'          ,'-2 Charm & Seduction'         , 'It’s not uncommon for a witcher’s body to be a patchwork of scars. However you have sustained a blow that disfigured your face.'),
    (8,'Damaged Nose'       ,'-2 Scent Tracking'            , 'A number of punches to the face in bar fights (or toxic gases) have damaged your nose and nearly robbed you of your scent tracking.'),
    (9,'Venom Damage'       ,'-5 Health'                    , 'Toxins that once coursed through you left a patchwork of blackened veins around the wound and weakened your body.'),
    (10,'Half Deafened'     ,'-1 Hearing Awareness'         , 'Many monsters use deadly sonic attacks. You were lucky enough to survive one, but your ears will never be the same.')
  ) AS raw_data_en(num, wound, effect, descr)
),

vals AS (
  SELECT
    ('<td><b>'||wound||'</b></td>'
     ||'<td>'||effect||'</td>'
     ||'<td>'||descr||'</td>') AS text,
    num, lang
  FROM raw_data
)
, ins_lbl AS (
  INSERT INTO i18n_text (id,entity,entity_field,lang,text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
       , meta.entity, meta.entity_field, vals.lang, vals.text
    FROM vals
    CROSS JOIN meta
)

INSERT INTO answer_options (an_id,su_su_id,qu_qu_id,label,sort_order,metadata)
SELECT
  'wcc_witcher_events_danger_wounds_o'||to_char(vals.num,'FM00'),
  meta.su_su_id,
  meta.qu_id,
  ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
  vals.num,
  '{}'::jsonb
FROM vals
CROSS JOIN meta
ON CONFLICT (an_id) DO NOTHING;

-- i18n для eventType "Неудача"
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_danger_wounds' AS qu_id
                , 'character' AS entity)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'event_type_problems') AS id
     , meta.entity, 'event_type', v.lang, v.text
  FROM (VALUES
    ('ru', 'Ранения'),
    ('en', 'Wounds')
  ) AS v(lang, text)
  CROSS JOIN meta;

-- i18n для event_desc (краткие описания для lifeEvents)
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_danger_wounds' AS qu_id
                , 'character' AS entity)
, desc_vals AS (
  SELECT v.*
  FROM (VALUES
    -- Русский
    ('ru', 1, '[Скор -1] Плохо гнется колено. Нога была в невосстановимом состоянии.'),
    ('ru', 2, 'Поврежденный глаз. -1 к зрительному Вниманию.'),
    ('ru', 3, 'Плохо гнётся рука. -1 к Ближнему бою этой рукой.'),
    ('ru', 4, 'Повреждённые пальцы. Нельзя сотворять знаки этой рукой.'),
    ('ru', 5, '[Сила -1] Наконечник стрелы засел глубоко в мышцах.'),
    ('ru', 6, '[Выносливость -5] Лёгкие повреждены, дышать стало тяжелее.'),
    ('ru', 7, '[Харизма -2, Соблазнене -2] Уродливый шрам на лице.'),
    ('ru', 8, 'Поврежденный нос. -2 к Выживанию в дикой природе при выслеживании по запаху.'),
    ('ru', 9, '[Максимум Здоровья -5] Яд оставил черные вены вокруг раны и ослабил тело.'),
    ('ru', 10, 'Слух повреждён после звуковой атаки. -1 к слуховому Вниманию.'),
    -- English
    ('en', 1, '[SPD -1] Stiff knee. Leg was in an unrepairable state.'),
    ('en', 2, 'Damaged eye. -1 Sight Awareness.'),
    ('en', 3, 'Stiff arm. -1 Melee with that arm.'),
    ('en', 4, 'Damaged fingers. Can''t do signs with that hand.'),
    ('en', 5, '[Physique -1] Arrowhead lodged deep in muscles.'),
    ('en', 6, '[Stamina -5] Lungs damaged, breathing became harder.'),
    ('en', 7, '[Charisma -2, Seduction -2] Ugly scar on face.'),
    ('en', 8, 'Damaged nose. -2 Wilderness Survival when tracking by scent.'),
    ('en', 9, '[Max Health -5] Poison left black veins around wound and weakened body.'),
    ('en', 10, 'Hearing damaged after sonic attack. -1 Hearing Awareness.')
  ) AS v(lang, num, text)
)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(desc_vals.num, 'FM9900') ||'.'|| 'event_desc') AS id
     , meta.entity, 'event_desc', desc_vals.lang, desc_vals.text
  FROM desc_vals
  CROSS JOIN meta;

-- Эффекты: добавление в lifeEvents для всех вариантов
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_events_danger_wounds' AS qu_id)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character', 'wcc_witcher_events_danger_wounds_o' || to_char(vals.num, 'FM00'),
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
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'event_type_problems')::text),
        'description',
        jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| 'event_desc')::text)
      )
    )
  )
FROM (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10)) AS vals(num)
CROSS JOIN meta
UNION ALL
-- Штрафы для вариантов 1, 5, 6, 7, 9
-- Вариант 1: -1 к SPD.bonus
SELECT 'character', 'wcc_witcher_events_danger_wounds_o01',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.statistics.SPD.bonus'),
      -1
    )
  )
FROM meta
UNION ALL
-- Вариант 5: -1 к physique.bonus
SELECT 'character', 'wcc_witcher_events_danger_wounds_o05',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.physique.bonus'),
      -1
    )
  )
FROM meta
UNION ALL
-- Вариант 6: -5 к STA.bonus
SELECT 'character', 'wcc_witcher_events_danger_wounds_o06',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.statistics.calculated.STA.bonus'),
      -5
    )
  )
FROM meta
UNION ALL
-- Вариант 7: -2 к charisma.bonus и -2 к seduction.bonus
SELECT 'character', 'wcc_witcher_events_danger_wounds_o07',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.charisma.bonus'),
      -2
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_events_danger_wounds_o07',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.skills.common.seduction.bonus'),
      -2
    )
  )
FROM meta
UNION ALL
-- Вариант 9: -5 к max_HP.bonus
SELECT 'character', 'wcc_witcher_events_danger_wounds_o09',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.statistics.calculated.max_HP.bonus'),
      -5
    )
  )
FROM meta;

-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id, priority) 
  SELECT 'wcc_witcher_events_is_in_danger', 'wcc_witcher_events_danger_wounds', 'wcc_witcher_events_is_in_danger_o0102', 1 UNION ALL
  SELECT 'wcc_witcher_events_is_in_danger', 'wcc_witcher_events_danger_wounds', 'wcc_witcher_events_is_in_danger_o0202', 1 UNION ALL
  SELECT 'wcc_witcher_events_is_in_danger', 'wcc_witcher_events_danger_wounds', 'wcc_witcher_events_is_in_danger_o0302', 1 UNION ALL
  SELECT 'wcc_witcher_events_is_in_danger', 'wcc_witcher_events_danger_wounds', 'wcc_witcher_events_is_in_danger_o0402', 1
  ;