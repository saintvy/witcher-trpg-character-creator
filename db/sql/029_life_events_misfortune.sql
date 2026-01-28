\echo '029_life_events_misfortune.sql'

-- Узел: Выжные события - Кто потерпевший
-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_misfortune' AS qu_id
                , 'questions' AS entity
                , 'single'::question_type AS qtype
	              , jsonb_build_object('dice','d0') AS metadata)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| v.entity_field) AS id
           , meta.entity, v.entity_field, v.lang, v.text
        FROM (VALUES
                ('ru', 'Определите, как именно неудача с вами приключилась.', 'body'),
                ('en', 'Determine how misfortune came your way.', 'body')
             ) AS v(lang, text, entity_field)
        CROSS JOIN meta
      RETURNING id AS body_id
)
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
  SELECT meta.qu_id
       , meta.su_su_id
       , NULL
       , (SELECT DISTINCT body_id FROM ins_body)
       , meta.qtype
	     , meta.metadata || jsonb_build_object(
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
            ck_id('witcher_cc.hierarchy.life_events_misfortune')::text,
            ck_id('witcher_cc.hierarchy.life_events_misfortune_kind')::text
          )
        )
     FROM meta;
	   
-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_life_events_misfortune' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
  SELECT v.*
  FROM (VALUES ('ru', 1, '<b>Долг:</b><br>Вы задолжали от 100 до 1000 крон.'),
               ('ru', 2, '<b>Заключение:</b><br>За какой-то проступок (или по ложному обвинению) вы попали в тюрьму на срок от 1 до 10 месяцев.'),
               ('ru', 3, '<b>Зависимость:</b><br>У вас есть зависимость на ваш выбор:<br> - Алкоголь<br> - Табак<br> - Фисштех<br> - Азартные игры<br> - Клептомания<br> - Похоть<br> - Обжорство<br> - Адреналиновая зависимость<br> - Другое (можете придумать сами)'),
               ('ru', 4, '<b>Любимый, друг или родственник убит:</b><br>Произошло одно из списка:<br> - это был несчастный случай<br> - убит чудовищами<br> - убит разбойниками'),
               ('ru', 5, '<b>Ложное обвинение:</b><br>Произошло одно из списка:<br> - воровство<br> - трусость или предательство<br> - убийство<br> - изнасилование<br> - нелегальное колдовство'),
               ('ru', 6, '<b>В розыске:</b><br>Вас разыскивают...<br> - ...несколько стражников<br> - ...в посёлке<br> - ...в городе<br> - ...во всём королевстве'),
               ('ru', 7, '<b>Предательство:</b><br>Произошло одно из списка:<br> - вас шантажируют<br> - ваша тайна раскрыта<br> - вас предал ктото из близких.'),
               ('ru', 8, '<b>Несчастный случай:</b><br>Произошло одно из списка:<br> - вы изуродованы, измените ваш социальный статус на опасение<br> - вы лечились от 1 до 10 месяцев<br> - вы потеряли память о нескольких (от 1 до 10) месяцах того года<br> - вас мучают жуткие кошмары (вероятно каждый раз во время сна)'),
               ('ru', 9, '<b>Физическая или психическая травма:</b><br>Произошло одно из списка:<br> - Вас отравили, навсегда потеряйте 5 ПЗ.<br> - Вы страдаете от панических атак и должны совершать испытание Устойчивости (каждые 5 раундов) в стрессовой ситуации.<br> - У вас серьёзное душевное расстройство, вы агрессивны, иррациональны и депрессивны, а также слышите голоса, за которые отвечает ведущий.'),
               ('ru', 10, '<b>Проклятие:</b><br>Вас прокляли одним проклятием из списка:<br> - Проклятие чудовищности<br> - Проклятие призраков<br> - Проклятие заразы<br> - Проклятие странника<br> - Проклятие ликантропии<br> - Другое (можете придумать сами)'),
               ('en', 1, '<b>Debt:</b><br>You owe between 100 and 1,000 crowns.'),
               ('en', 2, '<b>Imprisonment:</b><br>Something you did (or a false accusation) landed you in prison for a period of 1 to 10 months.'),
               ('en', 3, '<b>Addiction:</b><br>You have an addiction of your choice:<br> - Alcohol<br> - Tobacco<br> - Fisstech<br> - Gambling<br> - Kleptomania<br> - Lust<br> - Gluttony<br> - Other (create your own)'),
               ('en', 4, '<b>Lover, Friend or Relative Killed:</b><br>One of the following occurred:<br> - They died in an accident<br> - They were slain by monsters<br> - They were murdered by bandits'),
               ('en', 5, '<b>False Accusation:</b><br>One of the following occurred:<br> - Theft<br> - Cowardice or betrayal<br> - Murder<br> - Rape<br> - Illegal witchcraft'),
               ('en', 6, '<b>Wanted:</b><br>You are wanted...<br> - ...by a few guards<br> - ...in a small village<br> - ...in a major city<br> - ...throughout the entire kingdom'),
               ('en', 7, '<b>Betrayal:</b><br>One of the following occurred:<br> - You are being blackmailed<br> - Your secret was exposed<br> - You were betrayed by someone close to you'),
               ('en', 8, '<b>Accident:</b><br>One of the following occurred:<br> - You were disfigured; change your social status to Feared<br> - You were recovering for a period of 1 to 10 months<br> - You lost several (1 to 10) months of memory from that year<br> - You suffer from dreadful nightmares (likely every time you sleep)'),
               ('en', 9, '<b>Physical or Mental Trauma:</b><br>One of the following occurred:<br> - You were poisoned; permanently lose 5 HP<br> - You suffer from panic attacks and must make Stun saves (every 5 rounds) in stressful situations<br> - You have a severe mental disorder; you are aggressive, irrational, depressive, and hear voices controlled by the GM'),
               ('en', 10, '<b>Curse:</b><br>You have been afflicted by one of the following curses:<br> - Curse of Monstrosity<br> - Curse of the Phantom<br> - Curse of Pestilence<br> - Curse of the Wanderer<br> - Curse of Lycanthropy<br> - Other (create your own)')
         ) AS v(lang, num, text)
)
, ins_label AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
           , meta.entity, meta.entity_field, vals.lang, vals.text
        FROM vals
        CROSS JOIN meta
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
  SELECT 'wcc_life_events_misfortune_o' || to_char(vals.num, 'FM9900') AS an_id,
         meta.su_su_id,
         meta.qu_id,
         ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
         vals.num AS sort_order,
         '{}'::jsonb AS metadata
    FROM vals
    CROSS JOIN meta
  ON CONFLICT (an_id) DO NOTHING;
  
-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id)
  SELECT 'wcc_life_events_fortune_or_not', 'wcc_life_events_misfortune', 'wcc_life_events_fortune_or_not_o02';

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, ru_ru_id, priority)
  SELECT 'wcc_life_events_misfortune', 'wcc_life_events_event', r.ru_id, 1
    FROM (SELECT ru_id FROM rules WHERE name = 'lifeEventsCounter_is_valid') r;