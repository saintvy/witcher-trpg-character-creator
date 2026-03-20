\echo '050_mage_events_benefit.sql'

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.hierarchy.mage_events_benefit'), 'hierarchy', 'path', 'ru', 'Выгода'),
  (ck_id('witcher_cc.hierarchy.mage_events_benefit'), 'hierarchy', 'path', 'en', 'Benefit'),
  (ck_id('witcher_cc.hierarchy.mage_events_benefit_details'), 'hierarchy', 'path', 'ru', 'Детали'),
  (ck_id('witcher_cc.hierarchy.mage_events_benefit_details'), 'hierarchy', 'path', 'en', 'Details'),
  (ck_id('witcher_cc.hierarchy.mage_events_benefit_details_2'), 'hierarchy', 'path', 'ru', 'Детали 2'),
  (ck_id('witcher_cc.hierarchy.mage_events_benefit_details_2'), 'hierarchy', 'path', 'en', 'Details 2')
ON CONFLICT (id, lang) DO NOTHING;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id,
           'wcc_mage_events_benefit' AS qu_id,
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
        ('ru', 'Выберите полученную выгоду.'),
        ('en', 'Choose the benefit you gained.')
      ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
  ),
  c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Событие'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Event')
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
           ck_id('witcher_cc.hierarchy.mage_events_benefit')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO UPDATE
SET body = EXCLUDED.body,
    qtype = EXCLUDED.qtype,
    metadata = EXCLUDED.metadata;

INSERT INTO rules (ru_id, name, body)
VALUES
  (
    ck_id('witcher_cc.rules.is_mage_events_benefit_not_selected_10'),
    'is_mage_events_benefit_not_selected_10',
    '{"!":{"in":["wcc_mage_events_benefit_o0010",{"var":["answers.byQuestion.wcc_mage_events_benefit",[]]}]}}'::jsonb
  )
ON CONFLICT (ru_id) DO UPDATE
SET name = EXCLUDED.name,
    body = EXCLUDED.body;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id,
           'wcc_mage_events_benefit' AS qu_id,
           'answer_options' AS entity,
           'label' AS entity_field
  ),
  raw_data AS (
    SELECT 'ru' AS lang, *
      FROM (VALUES
        (1, 0.1::numeric, 'Нашёл одарённого Хаосом ученика', 'Вы нашли молодого человека, одарённого Хаосом. Вы помогли ему взять силы под контроль и обучили магии. Вы поддерживаете постоянную связь и можете просить его искать для вас магические сведения. Вы получаете союзника-мага.'),
        (2, 0.1::numeric, 'Влился в местное сообщество', 'Вы поселились неподалёку от маленькой деревни. Пока вы помогали местным с их бедами, они постепенно приняли вас. Там вам всегда будут рады и при необходимости предложат кров и еду. В этом регионе к вам всегда относятся как к Равному.'),
        (3, 0.1::numeric, 'Возврат долга', 'Кто-то должен вам 600 крон, и вы сохранили право взыскать этот долг в любой момент, даже спустя десятилетия.'),
        (4, 0.1::numeric, 'Фамильяр', 'Вы подружились с животным, которое всюду следует за вами. Это может быть кошка, собака, птица или змея. Животное обучено и слушается ваших команд, если вы не злоупотребляете этим.'),
        (5, 0.1::numeric, 'Любовная связь', 'Вы нашли возлюбленного(ую), который(ая) оценил(а) ваш магический талант, и между вами возникла глубокая связь. Бросьте 1d10. 1-6: всё длилось несколько месяцев, 7-8: всё длилось несколько лет, 9-10: всё продолжается с переменным успехом.'),
        (6, 0.1::numeric, 'Победил в дуэли', 'Вы сразились с другим магом в магической дуэли и победили. В качестве трофея вы забрали один из его предметов. Бросьте 1d10. 1-4: Эльфийский дорожный посох, 5-8: гномий посох, 9-10: хрустальный череп.'),
        (7, 0.1::numeric, 'Нашёл портал', 'Вы обнаружили местонахождение старого эльфского портала. Бросьте 1d10. На чётном числе он всё ещё активен; снова бросьте 1d10, чтобы определить место назначения: 1-3: старая поляна в Доль Блатанне, 4-5: горы Тир Тохаир, 6-8: болото в северном Каэдвене, 9-10: глубоко под Новиградом. По усмотрению ведущего портал может вести и в другое место.'),
        (8, 0.1::numeric, 'Тренировки боевой магии', 'Вы провели это десятилетие, тренируясь сражаться с другими магами и сопротивляться их силе. Вы получаете +1 к Сопротивлению магии.'),
        (9, 0.1::numeric, 'Место Силы', 'Вы нашли Место Силы и воспользовались его энергией. Вы получаете 5 единиц Пятой сущности. Вместе с ведущим определите, где оно находится и на какую стихию настроено.'),
        (10, 0.1::numeric, 'Колдовство в доспехах', 'Вы практиковались в колдовстве в доспехах. Вычтите 1 из общего СД всех доспехов, которые вы носите, для целей сотворения заклинаний. Если у вас уже есть это преимущество, перебросьте результат.')
      ) AS v(num, probability, head, txt)

    UNION ALL

    SELECT 'en' AS lang, *
      FROM (VALUES
        (1, 0.1::numeric, 'Scouted out a Prospective Mage', 'You found a young person gifted with Chaos. You helped them bring their powers under control and trained them to be a mage. You are in constant communication and can ask them to research magical matters for you. You gain a Mage Ally.'),
        (2, 0.1::numeric, 'Moved into a Community', 'You moved near a small village. The people there slowly opened up to you as you helped them with their woes. You will always be welcome there, and they will even offer shelter and food should you need it. While in this region you are always treated as Equal.'),
        (3, 0.1::numeric, 'Payment Due', 'Someone owes you 600 crowns and you have kept the right to collect at any moment, even after decades.'),
        (4, 0.1::numeric, 'Familiar', 'You have gained the friendship of an animal that follows you everywhere. This can be a cat, a dog, a bird, or a serpent. This animal is trained and follows your commands unless you abuse it.'),
        (5, 0.1::numeric, 'Love Affair', 'You found a lover who appreciated your magical talents and made a meaningful connection. Roll 1d10. 1-6: it lasted a few months, 7-8: it lasted a few years, 9-10: it is still going on and off.'),
        (6, 0.1::numeric, 'Won a Duel', 'You fought another mage in a magical duel and came out the victor. You took one item of theirs as a trophy. Roll 1d10. 1-4: an Elven Walking Staff, 5-8: a Gnomish Staff, 9-10: a Crystal Skull.'),
        (7, 0.1::numeric, 'Found a Portal', 'You discovered the location of an old elven portal. Roll 1d10. On an even number it is still active; roll 1d10 again for the destination: 1-3: an old glade in Dol Blathanna, 4-5: the Tir Tochair mountains, 6-8: a swamp in northern Kaedwen, 9-10: deep under the city of Novigrad. The portal can also, at the GM''s discretion, lead to another destination.'),
        (8, 0.1::numeric, 'Battle Magic Training', 'You spent the decade training to battle other magic users and resist their power. You gain +1 to Resist Magic.'),
        (9, 0.1::numeric, 'Place of Power', 'You have found the location of a Place of Power and harnessed its energy. You gain 5 Units of Fifth Essence. Work with the GM to determine where it is, and which element it is attuned to.'),
        (10, 0.1::numeric, 'Armored Casting', 'You have practiced casting in armor. Subtract 1 from the total EV of all the armor you are wearing for the purpose of spell casting. If you already have this benefit you re-roll this result.')
      ) AS v(num, probability, head, txt)
  ),
  vals AS (
    SELECT lang,
           num,
           probability,
           CASE WHEN num IN (1, 8, 10)
                AND num NOT IN (1)
                THEN jsonb_build_object(
                       'probability', probability,
                       'counterIncrement', jsonb_build_object('id', 'lifeEventsCounter', 'step', 10)
                     )
                WHEN num = 1
                THEN jsonb_build_object('probability', probability)
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
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, visible_ru_ru_id, sort_order, metadata)
SELECT 'wcc_mage_events_benefit_o' || to_char(vals.num, 'FM0000'),
       meta.su_su_id,
       meta.qu_id,
       ck_id(meta.su_su_id || '.' || meta.qu_id || '_o' || to_char(vals.num, 'FM0000') || '.' || meta.entity || '.' || meta.entity_field),
       CASE
         WHEN vals.num = 10
           THEN (SELECT ru_id FROM rules WHERE name = 'is_mage_events_benefit_not_selected_10' ORDER BY ru_id LIMIT 1)
         ELSE NULL
       END,
       vals.num,
       vals.metadata
  FROM vals
 CROSS JOIN meta
 WHERE vals.lang = 'ru'
ON CONFLICT (an_id) DO UPDATE
SET label = EXCLUDED.label,
    visible_ru_ru_id = EXCLUDED.visible_ru_ru_id,
    sort_order = EXCLUDED.sort_order,
    metadata = EXCLUDED.metadata;

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.wcc_mage_events_benefit.event_type_benefit'), 'character', 'event_type', 'ru', 'Выгода'),
  (ck_id('witcher_cc.wcc_mage_events_benefit.event_type_benefit'), 'character', 'event_type', 'en', 'Benefit'),
  (ck_id('witcher_cc.wcc_mage_events_benefit_o0001.event_desc'), 'character', 'event_desc', 'ru', 'Союзник (Маг)'),
  (ck_id('witcher_cc.wcc_mage_events_benefit_o0001.event_desc'), 'character', 'event_desc', 'en', 'Ally (Mage)'),
  (ck_id('witcher_cc.wcc_mage_events_benefit_o0008.event_desc'), 'character', 'event_desc', 'ru', 'Тренировки в боевой магии, [+1 к Сопротивлению магии]'),
  (ck_id('witcher_cc.wcc_mage_events_benefit_o0008.event_desc'), 'character', 'event_desc', 'en', 'Battle magic training, [+1 to Resist Magic]'),
  (ck_id('witcher_cc.wcc_mage_events_benefit_o0010.event_desc'), 'character', 'event_desc', 'ru', 'Научился колдовать в доспехах'),
  (ck_id('witcher_cc.wcc_mage_events_benefit_o0010.event_desc'), 'character', 'event_desc', 'en', 'Learned to cast in armor'),
  (ck_id('witcher_cc.wcc_mage_events_benefit.perk_armored_casting_name'), 'character', 'perk_name', 'ru', 'Колдовство в доспехах'),
  (ck_id('witcher_cc.wcc_mage_events_benefit.perk_armored_casting_name'), 'character', 'perk_name', 'en', 'Armored Casting'),
  (ck_id('witcher_cc.wcc_mage_events_benefit.perk_armored_casting_desc'), 'character', 'perk_desc', 'ru', '-1 к Скованности Движений доспеха при использовании магии'),
  (ck_id('witcher_cc.wcc_mage_events_benefit.perk_armored_casting_desc'), 'character', 'perk_desc', 'en', '-1 Encumbrance of armor when using magic')
ON CONFLICT (id, lang) DO UPDATE
SET text = EXCLUDED.text;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id,
           'wcc_mage_events_benefit' AS qu_id
  ),
  event_vals(num) AS (
    VALUES (1), (8), (10)
  )
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character',
       meta.qu_id || '_o' || to_char(event_vals.num, 'FM0000'),
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
             jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id || '.' || meta.qu_id || '.event_type_benefit')::text),
             'description',
             jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id || '.' || meta.qu_id || '_o' || to_char(event_vals.num, 'FM0000') || '.event_desc')::text)
           )
         )
       )
  FROM meta
  CROSS JOIN event_vals;

INSERT INTO effects (scope, an_an_id, body)
VALUES
  (
    'character',
    'wcc_mage_events_benefit_o0001',
    jsonb_build_object(
      'set',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.logicFields.last_node_and_answer'),
        'Profit 1'
      )
    )
  ),
  (
    'character',
    'wcc_mage_events_benefit_o0001',
    jsonb_build_object(
      'set',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.logicFields.flags.academy_life'),
        4
      )
    )
  ),
  (
    'character',
    'wcc_mage_events_benefit_o0008',
    jsonb_build_object(
      'inc',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.skills.common.resist_magic.bonus'),
        1
      )
    )
  ),
  (
    'character',
    'wcc_mage_events_benefit_o0010',
    jsonb_build_object(
      'add_unique',
      jsonb_build_array(
        jsonb_build_object('var', 'characterRaw.perks'),
        jsonb_build_object(
          'name', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_benefit.perk_armored_casting_name')::text),
          'description', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_mage_events_benefit.perk_armored_casting_desc')::text)
        )
      )
    )
  )
ON CONFLICT DO NOTHING;
