\echo '051_mage_events_benefit_details.sql'

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id,
           'wcc_mage_events_benefit_details' AS qu_id,
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
        ('ru', 'Раскройте подробности выбранной выгоды.'),
        ('en', 'Pick the specific outcome for your benefit.')
      ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
  ),
  c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Уточнение'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Detail')
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
           ck_id('witcher_cc.hierarchy.mage_events_benefit')::text,
           ck_id('witcher_cc.hierarchy.mage_events_benefit_details')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO UPDATE
SET body = EXCLUDED.body,
    qtype = EXCLUDED.qtype,
    metadata = EXCLUDED.metadata;

INSERT INTO rules (ru_id, name, body)
VALUES
  (ck_id('witcher_cc.rules.wcc_mage_events_benefit_details_group_02'), 'wcc_mage_events_benefit_details_group_02', '{"==":[{"reduce":[{"var":["answers.byQuestion.wcc_mage_events_benefit",[]]},{"var":"current"},null]},"wcc_mage_events_benefit_o0002"]}'::jsonb),
  (ck_id('witcher_cc.rules.wcc_mage_events_benefit_details_group_03'), 'wcc_mage_events_benefit_details_group_03', '{"==":[{"reduce":[{"var":["answers.byQuestion.wcc_mage_events_benefit",[]]},{"var":"current"},null]},"wcc_mage_events_benefit_o0003"]}'::jsonb),
  (ck_id('witcher_cc.rules.wcc_mage_events_benefit_details_group_04'), 'wcc_mage_events_benefit_details_group_04', '{"==":[{"reduce":[{"var":["answers.byQuestion.wcc_mage_events_benefit",[]]},{"var":"current"},null]},"wcc_mage_events_benefit_o0004"]}'::jsonb),
  (ck_id('witcher_cc.rules.wcc_mage_events_benefit_details_group_05'), 'wcc_mage_events_benefit_details_group_05', '{"==":[{"reduce":[{"var":["answers.byQuestion.wcc_mage_events_benefit",[]]},{"var":"current"},null]},"wcc_mage_events_benefit_o0005"]}'::jsonb),
  (ck_id('witcher_cc.rules.wcc_mage_events_benefit_details_group_06'), 'wcc_mage_events_benefit_details_group_06', '{"==":[{"reduce":[{"var":["answers.byQuestion.wcc_mage_events_benefit",[]]},{"var":"current"},null]},"wcc_mage_events_benefit_o0006"]}'::jsonb),
  (ck_id('witcher_cc.rules.wcc_mage_events_benefit_details_group_07'), 'wcc_mage_events_benefit_details_group_07', '{"==":[{"reduce":[{"var":["answers.byQuestion.wcc_mage_events_benefit",[]]},{"var":"current"},null]},"wcc_mage_events_benefit_o0007"]}'::jsonb),
  (ck_id('witcher_cc.rules.wcc_mage_events_benefit_details_group_09'), 'wcc_mage_events_benefit_details_group_09', '{"==":[{"reduce":[{"var":["answers.byQuestion.wcc_mage_events_benefit",[]]},{"var":"current"},null]},"wcc_mage_events_benefit_o0009"]}'::jsonb)
ON CONFLICT (ru_id) DO UPDATE
SET name = EXCLUDED.name,
    body = EXCLUDED.body;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id,
           'wcc_mage_events_benefit_details' AS qu_id,
           'answer_options' AS entity,
           'label' AS entity_field
  ),
  region_vals AS (
    SELECT *
      FROM (VALUES
        (1,  'Каэдвен', 'Северные королевства', 'Kaedwen', 'Northern Kingdoms'),
        (2,  'Ковир и Повисс', 'Северные королевства', 'Kovir and Poviss', 'Northern Kingdoms'),
        (3,  'Редания', 'Северные королевства', 'Redania', 'Northern Kingdoms'),
        (4,  'Аэдирн', 'Северные королевства', 'Aedirn', 'Northern Kingdoms'),
        (5,  'Лирия и Ривия', 'Северные королевства', 'Lyria and Rivia', 'Northern Kingdoms'),
        (6,  'Темерия', 'Северные королевства', 'Temeria', 'Northern Kingdoms'),
        (7,  'Цидарис', 'Северные королевства', 'Cidaris', 'Northern Kingdoms'),
        (8,  'Керак', 'Северные королевства', 'Kerack', 'Northern Kingdoms'),
        (9,  'Вердэн', 'Северные королевства', 'Verden', 'Northern Kingdoms'),
        (10, 'Скеллиге', 'Северные королевства', 'Skellige', 'Northern Kingdoms'),
        (11, 'Цинтра', 'Нильфгаард', 'Cintra', 'Nilfgaard'),
        (12, 'Ангрен', 'Нильфгаард', 'Angren', 'Nilfgaard'),
        (13, 'Назаир', 'Нильфгаард', 'Nazair', 'Nilfgaard'),
        (14, 'Меттина', 'Нильфгаард', 'Mettina', 'Nilfgaard'),
        (15, 'Туссент', 'Нильфгаард', 'Toussaint', 'Nilfgaard'),
        (16, 'Маг Турга', 'Нильфгаард', 'Mag Turga', 'Nilfgaard'),
        (17, 'Гесо', 'Нильфгаард', 'Gheso', 'Nilfgaard'),
        (18, 'Эббинг', 'Нильфгаард', 'Ebbing', 'Nilfgaard'),
        (19, 'Мехт', 'Нильфгаард', 'Maecht', 'Nilfgaard'),
        (20, 'Этолия', 'Нильфгаард', 'Etolia', 'Nilfgaard'),
        (21, 'Геммера', 'Нильфгаард', 'Gemmera', 'Nilfgaard'),
        (22, 'Доль Блатанна', 'Земли старших народов', 'Dol Blathanna', 'Elderlands'),
        (23, 'Махакам', 'Земли старших народов', 'Mahakam', 'Elderlands')
      ) AS v(sort_order, ru_name, ru_group, en_name, en_group)
  ),
  raw_data AS (
    SELECT 'ru' AS lang, 2 AS group_id, sort_order AS num, (1.0 / 23.0)::numeric AS probability,
           '<b>Сблизился с местными</b>: (' || ru_group || ') ' || ru_name AS txt,
           'wcc_mage_events_benefit_details_group_02' AS rule_name
      FROM region_vals

    UNION ALL

    SELECT 'en' AS lang, 2 AS group_id, sort_order AS num, (1.0 / 23.0)::numeric AS probability,
           '<b>Moved into a Community</b>: (' || en_group || ') ' || en_name AS txt,
           'wcc_mage_events_benefit_details_group_02' AS rule_name
      FROM region_vals

    UNION ALL

    SELECT *
      FROM (VALUES
        ('ru', 3, 1, (1.0 / 6.0)::numeric, '<b>Возврат долга</b>: 100 крон', 'wcc_mage_events_benefit_details_group_03'),
        ('ru', 3, 2, (1.0 / 6.0)::numeric, '<b>Возврат долга</b>: 200 крон', 'wcc_mage_events_benefit_details_group_03'),
        ('ru', 3, 3, (1.0 / 6.0)::numeric, '<b>Возврат долга</b>: 300 крон', 'wcc_mage_events_benefit_details_group_03'),
        ('ru', 3, 4, (1.0 / 6.0)::numeric, '<b>Возврат долга</b>: 400 крон', 'wcc_mage_events_benefit_details_group_03'),
        ('ru', 3, 5, (1.0 / 6.0)::numeric, '<b>Возврат долга</b>: 500 крон', 'wcc_mage_events_benefit_details_group_03'),
        ('ru', 3, 6, (1.0 / 6.0)::numeric, '<b>Возврат долга</b>: 600 крон', 'wcc_mage_events_benefit_details_group_03'),
        ('en', 3, 1, (1.0 / 6.0)::numeric, '<b>Payment Due</b>: 100 crowns', 'wcc_mage_events_benefit_details_group_03'),
        ('en', 3, 2, (1.0 / 6.0)::numeric, '<b>Payment Due</b>: 200 crowns', 'wcc_mage_events_benefit_details_group_03'),
        ('en', 3, 3, (1.0 / 6.0)::numeric, '<b>Payment Due</b>: 300 crowns', 'wcc_mage_events_benefit_details_group_03'),
        ('en', 3, 4, (1.0 / 6.0)::numeric, '<b>Payment Due</b>: 400 crowns', 'wcc_mage_events_benefit_details_group_03'),
        ('en', 3, 5, (1.0 / 6.0)::numeric, '<b>Payment Due</b>: 500 crowns', 'wcc_mage_events_benefit_details_group_03'),
        ('en', 3, 6, (1.0 / 6.0)::numeric, '<b>Payment Due</b>: 600 crowns', 'wcc_mage_events_benefit_details_group_03'),

        ('ru', 4, 1, 0.25::numeric, '<b>Фамильяр</b>: кошка', 'wcc_mage_events_benefit_details_group_04'),
        ('ru', 4, 2, 0.25::numeric, '<b>Фамильяр</b>: собака', 'wcc_mage_events_benefit_details_group_04'),
        ('ru', 4, 3, 0.25::numeric, '<b>Фамильяр</b>: птица', 'wcc_mage_events_benefit_details_group_04'),
        ('ru', 4, 4, 0.25::numeric, '<b>Фамильяр</b>: змея', 'wcc_mage_events_benefit_details_group_04'),
        ('en', 4, 1, 0.25::numeric, '<b>Familiar</b>: cat', 'wcc_mage_events_benefit_details_group_04'),
        ('en', 4, 2, 0.25::numeric, '<b>Familiar</b>: dog', 'wcc_mage_events_benefit_details_group_04'),
        ('en', 4, 3, 0.25::numeric, '<b>Familiar</b>: bird', 'wcc_mage_events_benefit_details_group_04'),
        ('en', 4, 4, 0.25::numeric, '<b>Familiar</b>: serpent', 'wcc_mage_events_benefit_details_group_04'),

        ('ru', 5, 1, 0.6::numeric, '<b>Любовная связь</b>: всё длилось несколько месяцев', 'wcc_mage_events_benefit_details_group_05'),
        ('ru', 5, 2, 0.2::numeric, '<b>Любовная связь</b>: всё длилось несколько лет', 'wcc_mage_events_benefit_details_group_05'),
        ('ru', 5, 3, 0.2::numeric, '<b>Любовная связь</b>: всё продолжается с переменным успехом', 'wcc_mage_events_benefit_details_group_05'),
        ('en', 5, 1, 0.6::numeric, '<b>Love Affair</b>: it lasted a few months', 'wcc_mage_events_benefit_details_group_05'),
        ('en', 5, 2, 0.2::numeric, '<b>Love Affair</b>: it lasted a few years', 'wcc_mage_events_benefit_details_group_05'),
        ('en', 5, 3, 0.2::numeric, '<b>Love Affair</b>: it is still going on and off', 'wcc_mage_events_benefit_details_group_05'),

        ('ru', 6, 1, 0.4::numeric, '<b>Победил в дуэли</b>: Эльфийский дорожный посох', 'wcc_mage_events_benefit_details_group_06'),
        ('ru', 6, 2, 0.4::numeric, '<b>Победил в дуэли</b>: гномий посох', 'wcc_mage_events_benefit_details_group_06'),
        ('ru', 6, 3, 0.2::numeric, '<b>Победил в дуэли</b>: хрустальный череп', 'wcc_mage_events_benefit_details_group_06'),
        ('en', 6, 1, 0.4::numeric, '<b>Won a Duel</b>: Elven Walking Staff', 'wcc_mage_events_benefit_details_group_06'),
        ('en', 6, 2, 0.4::numeric, '<b>Won a Duel</b>: Gnomish Staff', 'wcc_mage_events_benefit_details_group_06'),
        ('en', 6, 3, 0.2::numeric, '<b>Won a Duel</b>: Crystal Skull', 'wcc_mage_events_benefit_details_group_06'),

        ('ru', 7, 1, 0.15::numeric, '<b>Активный портал</b>: старая поляна в Доль Блатанне', 'wcc_mage_events_benefit_details_group_07'),
        ('ru', 7, 2, 0.10::numeric, '<b>Активный портал</b>: горы Тир Тохаир', 'wcc_mage_events_benefit_details_group_07'),
        ('ru', 7, 3, 0.15::numeric, '<b>Активный портал</b>: болото в северном Каэдвене', 'wcc_mage_events_benefit_details_group_07'),
        ('ru', 7, 4, 0.10::numeric, '<b>Активный портал</b>: глубоко под Новиградом', 'wcc_mage_events_benefit_details_group_07'),
        ('ru', 7, 5, 0.00::numeric, '<b>Активный портал</b>: другое место назначения', 'wcc_mage_events_benefit_details_group_07'),
        ('ru', 7, 6, 0.15::numeric, '<b>Пассивный портал</b>: старая поляна в Доль Блатанне', 'wcc_mage_events_benefit_details_group_07'),
        ('ru', 7, 7, 0.10::numeric, '<b>Пассивный портал</b>: горы Тир Тохаир', 'wcc_mage_events_benefit_details_group_07'),
        ('ru', 7, 8, 0.15::numeric, '<b>Пассивный портал</b>: болото в северном Каэдвене', 'wcc_mage_events_benefit_details_group_07'),
        ('ru', 7, 9, 0.10::numeric, '<b>Пассивный портал</b>: глубоко под Новиградом', 'wcc_mage_events_benefit_details_group_07'),
        ('ru', 7,10, 0.00::numeric, '<b>Пассивный портал</b>: другое место назначения', 'wcc_mage_events_benefit_details_group_07'),
        ('en', 7, 1, 0.15::numeric, '<b>Active Portal</b>: an old glade in Dol Blathanna', 'wcc_mage_events_benefit_details_group_07'),
        ('en', 7, 2, 0.10::numeric, '<b>Active Portal</b>: the Tir Tochair mountains', 'wcc_mage_events_benefit_details_group_07'),
        ('en', 7, 3, 0.15::numeric, '<b>Active Portal</b>: a swamp in northern Kaedwen', 'wcc_mage_events_benefit_details_group_07'),
        ('en', 7, 4, 0.10::numeric, '<b>Active Portal</b>: deep under the city of Novigrad', 'wcc_mage_events_benefit_details_group_07'),
        ('en', 7, 5, 0.00::numeric, '<b>Active Portal</b>: another destination', 'wcc_mage_events_benefit_details_group_07'),
        ('en', 7, 6, 0.15::numeric, '<b>Dormant Portal</b>: an old glade in Dol Blathanna', 'wcc_mage_events_benefit_details_group_07'),
        ('en', 7, 7, 0.10::numeric, '<b>Dormant Portal</b>: the Tir Tochair mountains', 'wcc_mage_events_benefit_details_group_07'),
        ('en', 7, 8, 0.15::numeric, '<b>Dormant Portal</b>: a swamp in northern Kaedwen', 'wcc_mage_events_benefit_details_group_07'),
        ('en', 7, 9, 0.10::numeric, '<b>Dormant Portal</b>: deep under the city of Novigrad', 'wcc_mage_events_benefit_details_group_07'),
        ('en', 7,10, 0.00::numeric, '<b>Dormant Portal</b>: another destination', 'wcc_mage_events_benefit_details_group_07')
      ) AS v(lang, group_id, num, probability, txt, rule_name)

    UNION ALL

    SELECT 'ru' AS lang, 9 AS group_id, sort_order AS num, (1.0 / 23.0)::numeric AS probability,
           '<b>Место Силы</b>: (' || ru_group || ') ' || ru_name AS txt,
           'wcc_mage_events_benefit_details_group_09' AS rule_name
      FROM region_vals

    UNION ALL

    SELECT 'en' AS lang, 9 AS group_id, sort_order AS num, (1.0 / 23.0)::numeric AS probability,
           '<b>Place of Power</b>: (' || en_group || ') ' || en_name AS txt,
           'wcc_mage_events_benefit_details_group_09' AS rule_name
      FROM region_vals
  ),
  vals AS (
    SELECT lang,
           group_id,
           num,
           probability,
           rule_name,
           CASE WHEN group_id IN (2, 3, 4, 5, 6, 7)
                THEN jsonb_build_object(
                       'probability', probability,
                       'counterIncrement', jsonb_build_object('id', 'lifeEventsCounter', 'step', 10)
                     )
                ELSE jsonb_build_object('probability', probability)
            END AS metadata,
           '<td style="color: grey;">' || to_char(probability * 100, 'FM990.00') || '%</td><td>' || txt || '</td>' AS text
      FROM raw_data
  ),
  ins_lbl AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id || '.' || meta.qu_id || '_o' || to_char(100 * vals.group_id + vals.num, 'FM0000') || '.' || meta.entity || '.' || meta.entity_field),
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
SELECT 'wcc_mage_events_benefit_details_o' || to_char(vals.group_id, 'FM00') || to_char(vals.num, 'FM00'),
       meta.su_su_id,
       meta.qu_id,
       ck_id(meta.su_su_id || '.' || meta.qu_id || '_o' || to_char(100 * vals.group_id + vals.num, 'FM0000') || '.' || meta.entity || '.' || meta.entity_field),
       (SELECT ru_id FROM rules WHERE name = vals.rule_name ORDER BY ru_id LIMIT 1),
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
