\echo '053_mage_events_knowledge.sql'

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.hierarchy.mage_events_knowledge'), 'hierarchy', 'path', 'ru', 'Знание'),
  (ck_id('witcher_cc.hierarchy.mage_events_knowledge'), 'hierarchy', 'path', 'en', 'Knowledge'),
  (ck_id('witcher_cc.hierarchy.mage_events_knowledge_details'), 'hierarchy', 'path', 'ru', 'Детали'),
  (ck_id('witcher_cc.hierarchy.mage_events_knowledge_details'), 'hierarchy', 'path', 'en', 'Details')
ON CONFLICT (id, lang) DO NOTHING;

INSERT INTO rules (ru_id, name, body)
VALUES
  (
    ck_id('witcher_cc.rules.is_mage_events_knowledge_not_selected_03'),
    'is_mage_events_knowledge_not_selected_03',
    '{"!":{"in":["wcc_mage_events_knowledge_o0003",{"var":["answers.byQuestion.wcc_mage_events_knowledge",[]]}]}}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_mage_events_knowledge_not_selected_04'),
    'is_mage_events_knowledge_not_selected_04',
    '{"!":{"in":["wcc_mage_events_knowledge_o0004",{"var":["answers.byQuestion.wcc_mage_events_knowledge",[]]}]}}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_mage_events_knowledge_not_selected_06'),
    'is_mage_events_knowledge_not_selected_06',
    '{"!":{"in":["wcc_mage_events_knowledge_o0006",{"var":["answers.byQuestion.wcc_mage_events_knowledge",[]]}]}}'::jsonb
  ),
  (
    ck_id('witcher_cc.rules.is_mage_events_knowledge_selected_lt_4_10'),
    'is_mage_events_knowledge_selected_lt_4_10',
    '{"<":[{"reduce":[{"var":["answers.byQuestion.wcc_mage_events_knowledge",[]]},{"+":[{"var":"accumulator"},{"if":[{"==":[{"var":"current"},"wcc_mage_events_knowledge_o0010"]},1,0]}]},0]},4]}'::jsonb
  )
ON CONFLICT (ru_id) DO UPDATE
SET name = EXCLUDED.name,
    body = EXCLUDED.body;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id,
           'wcc_mage_events_knowledge' AS qu_id,
           'questions' AS entity
  ),
  ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id || '.' || meta.qu_id || '.' || meta.entity || '.body'),
           meta.entity,
           'body',
           v.lang,
           v.text
      FROM (VALUES
        ('ru', 'Выберите приобретённое знание.'),
        ('en', 'Choose the knowledge you gained.')
      ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
  ),
  c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Знание'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Knowledge')
  ),
  ins_cols AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id || '.' || meta.qu_id || '.' || to_char(c_vals.num, 'FM9900') || '.' || meta.entity || '.column_name'),
           meta.entity,
           'column_name',
           c_vals.lang,
           c_vals.text
      FROM c_vals
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
  )
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
SELECT meta.qu_id,
       meta.su_su_id,
       NULL,
       ck_id(meta.su_su_id || '.' || meta.qu_id || '.' || meta.entity || '.body'),
       'single_table',
       jsonb_build_object(
         'dice', 'd_weighed',
         'columns', (
           SELECT jsonb_agg(
                    ck_id(meta.su_su_id || '.' || meta.qu_id || '.' || to_char(num, 'FM9900') || '.' || meta.entity || '.column_name')::text
                    ORDER BY num
                  )
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
           ck_id('witcher_cc.hierarchy.mage_events_outcome')::text,
           ck_id('witcher_cc.hierarchy.mage_events_knowledge')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO UPDATE
SET body = EXCLUDED.body,
    qtype = EXCLUDED.qtype,
    metadata = EXCLUDED.metadata;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id,
           'wcc_mage_events_knowledge' AS qu_id,
           'answer_options' AS entity,
           'label' AS entity_field
  ),
  raw_data AS (
    SELECT 'ru' AS lang, *
      FROM (VALUES
        (1, 0.1::numeric, 'Сведущий в порче', 'Вы начали вникать в устройство особенно мерзкого проклятия, которое затрагивало одну семью несколько поколений. Хотя вы не смогли его рассеять, ваши открытия дали вам представление о природе проклятий. Вы получаете +1 к Магическому познанию и +1 к Наведению порчи.', NULL),
        (2, 0.1::numeric, 'Заученные формулы', 'Вы потратили десятилетие на заучивание формул заклинаний. Выберите одно заклинание новичка и одно заклинание подмастерья. Вы начинаете игру, зная оба этих заклинания.', NULL),
        (3, 0.1::numeric, 'Магический биолог', 'Вы потратили много времени, изучая магию, присущую чудовищам, таким как лешие и бесы. Вы начинаете игру, зная ритуал «Наполнение трофея». Если у вас уже есть это знание, вы перебрасываете результат.', 'is_mage_events_knowledge_not_selected_03'),
        (4, 0.1::numeric, 'Зерриканская алхимия', 'Вы проводили время, изучая алхимию зерриканских учёных. Вы начинаете игру с заученной формулой Зерриканского огня.', 'is_mage_events_knowledge_not_selected_04'),
        (5, 0.1::numeric, 'Знаки и предзнаменования', 'Вы заглянули в будущее и увидели событие, которое должны предотвратить или которому должны помочь случиться. Вместе с ведущим определите, что это было. Видение пришло через символы и метафоры.', NULL),
        (6, 0.1::numeric, 'Энциклопедия арканы', 'Вы провели это десятилетие, погружаясь в законы Хаоса, его эволюцию и применение. Вы получаете +2 к Магическому познанию. Если у вас уже есть это знание, вы перебрасываете результат.', 'is_mage_events_knowledge_not_selected_06'),
        (7, 0.1::numeric, 'Исследования лей-линий', 'Вы провели десятилетие, изучая лей-линии континента. Когда вы пытаетесь вытянуть силу из лей-линии, вы делаете это с бонусом +2. Кроме того, вы начинаете игру, зная заклинание «Обнаружение лей-линий».', NULL),
        (8, 0.1::numeric, 'Помощник учителя', 'Вы провели время, помогая учителю или, возможно, наставнику. Обучая других магов новым заклинаниям, вы вдвое уменьшаете количество требуемых проверок обучения.', NULL),
        (9, 0.1::numeric, 'Ученик алхимика', 'Вы потратили некоторое время на изучение тонкостей алхимии. Вы начинаете игру с любыми двумя алхимическими формулами новичка и получаете +1 к Алхимии.', NULL),
        (10, 0.1::numeric, 'Эксперт по предсказаниям', 'Вы углубились в изучение гадания и ясновидения. Вы начинаете игру, зная один из ритуалов: Гидромантия, Пиромантия, Тиромантия или Онейромантия.', 'is_mage_events_knowledge_selected_lt_4_10')
      ) AS v(num, probability, head, txt, rule_name)

    UNION ALL

    SELECT 'en' AS lang, *
      FROM (VALUES
        (1, 0.1::numeric, 'Stumped by a Curse', 'You began delving into the workings of a particularly vile curse that has been affecting a family for generations. While you could not dispel it, your findings gave you insight into the nature of curses. You gain a +1 to Magical Training and a +1 to Hex Weaving.', NULL),
        (2, 0.1::numeric, 'Memorized Formulae', 'You spent your decade memorizing spell formulae. Choose one Novice and one Journeyman spell. You begin the game knowing both of these spells.', NULL),
        (3, 0.1::numeric, 'Magical Biologist', 'You spent a great deal of time studying the inherent magic of monsters like leshen and fiends. You begin the game knowing the Imbue Trophy Ritual. If you already have this knowledge you re-roll this result.', 'is_mage_events_knowledge_not_selected_03'),
        (4, 0.1::numeric, 'Zerrikanian Alchemy', 'You spent your time studying the alchemy of the Zerrikanian scholars. You begin the game with the Formula for Zerrikanian Fire memorized.', 'is_mage_events_knowledge_not_selected_04'),
        (5, 0.1::numeric, 'Signs and Portents', 'You peered into the future and saw an event you must prevent or must ensure happens. Work with your GM to determine what it is. This vision was conveyed through symbols and metaphors.', NULL),
        (6, 0.1::numeric, 'Encyclopedia Arcana', 'You spent this decade diving into the laws of Chaos, its evolution, and its uses. You gain a +2 to Magic Training. If you already have this knowledge you re-roll this result.', 'is_mage_events_knowledge_not_selected_06'),
        (7, 0.1::numeric, 'Ley Line Studies', 'You spent the decade studying the Ley Lines of the Continent. When you try to draw on a Ley Line you do so with a +2 bonus. Additionally, you begin the game knowing the Detect Ley Line Spell.', NULL),
        (8, 0.1::numeric, 'Teacher''s Assistant', 'You spent your time helping a teacher or perhaps your mentor. When teaching new spells to other mages, you halve the number of learning checks required.', NULL),
        (9, 0.1::numeric, 'Apprenticed to an Alchemist', 'You spent some time studying the finer points of alchemy. You begin the game with any 2 novice alchemical formulae and gain a +1 to Alchemy.', NULL),
        (10, 0.1::numeric, 'Divination Expert', 'You delved into the study of divination and clairvoyance. You begin the game knowing either the Hydromancy, Pyromancy, Tyromancy, or Oneiromancy Ritual.', 'is_mage_events_knowledge_selected_lt_4_10')
      ) AS v(num, probability, head, txt, rule_name)
  ),
  vals AS (
    SELECT lang,
           num,
           probability,
           rule_name,
           CASE WHEN num BETWEEN 1 AND 9
                THEN jsonb_build_object(
                       'probability', probability,
                       'counterIncrement', jsonb_build_object('id', 'lifeEventsCounter', 'step', 10)
                     )
                ELSE jsonb_build_object('probability', probability)
            END AS metadata,
           '<td style="color: grey;">' || to_char(probability * 100, 'FM990.00') || '%</td><td><b>' || head || '</b><br>' || txt || '</td>' AS text
      FROM raw_data
  ),
  ins_lbl AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id || '.' || meta.qu_id || '_o' || to_char(vals.num, 'FM0000') || '.' || meta.entity || '.' || meta.entity_field),
           meta.entity,
           meta.entity_field,
           vals.lang,
           vals.text
      FROM vals
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
  )
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT 'wcc_mage_events_knowledge_o' || to_char(vals.num, 'FM0000'),
       meta.su_su_id,
       meta.qu_id,
       ck_id(meta.su_su_id || '.' || meta.qu_id || '_o' || to_char(vals.num, 'FM0000') || '.' || meta.entity || '.' || meta.entity_field),
       vals.num,
       CASE WHEN vals.rule_name IS NULL THEN NULL ELSE (SELECT ru_id FROM rules WHERE name = vals.rule_name ORDER BY ru_id LIMIT 1) END,
       vals.metadata
  FROM vals
 CROSS JOIN meta
 WHERE vals.lang = 'ru'
ON CONFLICT (an_id) DO UPDATE
SET label = EXCLUDED.label,
    sort_order = EXCLUDED.sort_order,
    visible_ru_ru_id = EXCLUDED.visible_ru_ru_id,
    metadata = EXCLUDED.metadata;

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.wcc_mage_events_knowledge.event_type_knowledge'), 'character', 'event_type', 'ru', 'Знания'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge.event_type_knowledge'), 'character', 'event_type', 'en', 'Knowledge'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge_o0001.event_desc'), 'character', 'event_desc', 'ru', 'Сведущий в порче, [+1 к Магическому познанию] и [+1 к Наведению порчи]'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge_o0001.event_desc'), 'character', 'event_desc', 'en', 'Stumped by a curse, [+1 to Magical Training] and [+1 to Hex Weaving]'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge_o0002.event_desc'), 'character', 'event_desc', 'ru', 'Заучивание формул заклинаний'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge_o0002.event_desc'), 'character', 'event_desc', 'en', 'Memorized spell formulae'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge_o0003.event_desc'), 'character', 'event_desc', 'ru', 'Изучение магии в останках монстров'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge_o0003.event_desc'), 'character', 'event_desc', 'en', 'Studied magic in monster remains'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge_o0004.event_desc'), 'character', 'event_desc', 'ru', 'Изучение зерриканского огня'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge_o0004.event_desc'), 'character', 'event_desc', 'en', 'Studied Zerrikanian Fire'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge_o0005.event_desc'), 'character', 'event_desc', 'ru', 'В символах и метафорах видел значимые события будущего. Уточнить у ведущего'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge_o0005.event_desc'), 'character', 'event_desc', 'en', 'Saw significant future events through symbols and metaphors. Clarify with the GM'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge_o0006.event_desc'), 'character', 'event_desc', 'ru', 'Изучение законов хаоса, [+2 к Магическому познанию]'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge_o0006.event_desc'), 'character', 'event_desc', 'en', 'Studied the laws of Chaos, [+2 to Magical Training]'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge_o0007.event_desc'), 'character', 'event_desc', 'ru', 'Исследования Лей-линий'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge_o0007.event_desc'), 'character', 'event_desc', 'en', 'Ley Line studies'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge_o0008.event_desc'), 'character', 'event_desc', 'ru', 'Учился быть учителем'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge_o0008.event_desc'), 'character', 'event_desc', 'en', 'Learned to be a teacher'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge_o0009.event_desc'), 'character', 'event_desc', 'ru', 'Учился алхимии, [+1 к Алхимии]'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge_o0009.event_desc'), 'character', 'event_desc', 'en', 'Studied alchemy, [+1 to Alchemy]'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge_o0010.event_desc'), 'character', 'event_desc', 'ru', 'Изучал гадания и ясновидение'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge_o0010.event_desc'), 'character', 'event_desc', 'en', 'Studied divination and clairvoyance'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge.perk_ley_lines_name'), 'character', 'perk_name', 'ru', 'Понимание Лей-линий'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge.perk_ley_lines_name'), 'character', 'perk_name', 'en', 'Understanding of Ley Lines'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge.perk_ley_lines_desc'), 'character', 'perk_desc', 'ru', '+2 при попытке вытягивания силы из Лей-линии'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge.perk_ley_lines_desc'), 'character', 'perk_desc', 'en', '+2 when attempting to draw power from a Ley Line'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge.perk_teacher_name'), 'character', 'perk_name', 'ru', 'Учитель магии'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge.perk_teacher_name'), 'character', 'perk_name', 'en', 'Teacher of Magic'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge.perk_teacher_desc'), 'character', 'perk_desc', 'ru', 'Требуется вдвое меньше успешных проверок при обучении других магов новым заклинаниям'),
  (ck_id('witcher_cc.wcc_mage_events_knowledge.perk_teacher_desc'), 'character', 'perk_desc', 'en', 'Teaching other mages new spells requires half as many successful learning checks')
ON CONFLICT (id, lang) DO UPDATE
SET text = EXCLUDED.text;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id,
           'wcc_mage_events_knowledge' AS qu_id
  ),
  vals AS (
    SELECT generate_series(1, 10) AS num
  )
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character',
       meta.qu_id || '_o' || to_char(vals.num, 'FM0000'),
       jsonb_build_object(
         'add',
         jsonb_build_array(
           jsonb_build_object('var','characterRaw.lore.lifeEvents'),
           jsonb_build_object(
             'timePeriod',
             jsonb_build_object(
               'jsonlogic_expression',
               jsonb_build_object(
                 'cat',
                 jsonb_build_array(
                   jsonb_build_object('var','counters.lifeEventsCounter'),
                   '-',
                   jsonb_build_object('+', jsonb_build_array(
                     jsonb_build_object('var','counters.lifeEventsCounter'),
                     10
                   ))
                 )
               )
             ),
             'eventType',
             jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id || '.' || meta.qu_id || '.event_type_knowledge')::text),
             'description',
             jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id || '.' || meta.qu_id || '_o' || to_char(vals.num, 'FM0000') || '.event_desc')::text)
           )
         )
       )
  FROM meta
  CROSS JOIN vals;

INSERT INTO effects (scope, an_an_id, body)
VALUES
  (
    'character',
    'wcc_mage_events_knowledge_o0001',
    jsonb_build_object(
      'inc',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.skills.defining.bonus'),
        1
      )
    )
  ),
  (
    'character',
    'wcc_mage_events_knowledge_o0001',
    jsonb_build_object(
      'inc',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.skills.common.hex_weaving.bonus'),
        1
      )
    )
  ),
  (
    'character',
    'wcc_mage_events_knowledge_o0002',
    jsonb_build_object(
      'inc',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.professional_gear_options.novice_spells_tokens'),
        1
      )
    )
  ),
  (
    'character',
    'wcc_mage_events_knowledge_o0002',
    jsonb_build_object(
      'inc',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.professional_gear_options.journeyman_spells_tokens'),
        1
      )
    )
  ),
  (
    'character',
    'wcc_mage_events_knowledge_o0003',
    jsonb_build_object(
      'inc',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.professional_gear_options.imbue_trophy_tokens'),
        1
      )
    )
  ),
  (
    'character',
    'wcc_mage_events_knowledge_o0004',
    jsonb_build_object(
      'add',
      jsonb_build_array(
        jsonb_build_object('var','characterRaw.gear.recipes'),
        jsonb_build_object('r_id','R046','sourceId','recipes','amount',0)
      )
    )
  ),
  (
    'character',
    'wcc_mage_events_knowledge_o0006',
    jsonb_build_object(
      'inc',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.skills.defining.bonus'),
        2
      )
    )
  ),
  (
    'character',
    'wcc_mage_events_knowledge_o0007',
    jsonb_build_object(
      'add_unique',
      jsonb_build_array(
        jsonb_build_object('var','characterRaw.perks'),
        jsonb_build_object(
          'name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_knowledge.perk_ley_lines_name')::text),
          'description', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_knowledge.perk_ley_lines_desc')::text)
        )
      )
    )
  ),
  (
    'character',
    'wcc_mage_events_knowledge_o0007',
    jsonb_build_object(
      'set',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.professional_gear_options.detect_ley_line_tokens'),
        1
      )
    )
  ),
  (
    'character',
    'wcc_mage_events_knowledge_o0008',
    jsonb_build_object(
      'add_unique',
      jsonb_build_array(
        jsonb_build_object('var','characterRaw.perks'),
        jsonb_build_object(
          'name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_knowledge.perk_teacher_name')::text),
          'description', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_knowledge.perk_teacher_desc')::text)
        )
      )
    )
  ),
  (
    'character',
    'wcc_mage_events_knowledge_o0009',
    jsonb_build_object(
      'inc',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.skills.common.alchemy.bonus'),
        1
      )
    )
  ),
  (
    'character',
    'wcc_mage_events_knowledge_o0009',
    jsonb_build_object(
      'inc',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.professional_gear_options.novice_recipe_tokens'),
        2
      )
    )
  )
ON CONFLICT DO NOTHING;
