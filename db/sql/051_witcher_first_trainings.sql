\echo '051_witcher_first_trainings.sql'
-- Узел: Как прошли начальные тренировки?

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_first_trainings' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
              ('ru', 'Определите событие времён раннего обучения.'),
              ('en', 'Determine an event from your earliest witcher training.')
           ) AS v(lang, text)
      CROSS JOIN meta
  )
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Эффект'),
      ('ru', 3, 'Событие начальных тренировок'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Effect'),
      ('en', 3, 'Early Training Event')
)
, ins_c   AS (
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
           SELECT jsonb_agg(ck_id('witcher_cc' ||'.'|| 'wcc_witcher_first_trainings' ||'.'|| to_char(num, 'FM9900') ||'.'|| 'questions' ||'.'|| 'column_name')::text ORDER BY num)
           FROM (SELECT DISTINCT num FROM c_vals) AS cols
         ),
         'path', jsonb_build_array(
           ck_id('witcher_cc.hierarchy.witcher')::text,
           ck_id('witcher_cc.hierarchy.witcher_first_trainings')::text
         )
       )
    FROM meta;

-- Ответы
WITH
raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
      (1, 0.1, '-1 к Скор', '<b>Травма на Мучильне</b><br>Вы получили травму, пробегая полосу препятствий вокруг школы. У вас сильно сломана нога, и даже после исцеления она гнётся чуть хуже.'),
      (2, 0.1, '+1 ведьмачий чертёж', '<b>Украденное знание</b><br>Обучаясь в школе, вы прокрались в библиотеку крепости и скопировали один из секретных ведьмачьих чертежей, а копию взяли с собой.'),
      (3, 0.1, '1 враг-ведьмак', '<b>Завёл соперника</b><br>В ходе обучения у вас возникло соперничество с другим будущим ведьмаком. Даже после мутаций он продолжает вас ненавидеть.'),
      (4, 0.1, '+2 к Испытанию травами', '<b>Лёгкие мутации</b><br>Вы хорошо приспособились к малым мутациям и действию мутагенных грибов, которыми вас кормили в начале обучения. Когда пришло время Испытания травами, вы были готовы.'),
      (5, 0.1, '-1 к Энергии', '<b>Негативные последствия магии</b><br>Неправильно сотворённый знак немного повредил ваше тело. Было ужасно больно, и даже после исцеления ваше значение Энергии снижено.'),
      (6, 0.1, '+1 к Владению мечом', '<b>Лучший в классе</b><br>Вы были одним из лучших мечников среди сверстников, и с годами ваши навыки не притупились. Вы с лёгкостью выполняете сложные движения, пируэты и развороты.'),
      (7, 0.1, '-2 к Испытанию травами', '<b>Плохая реакция на мутагены</b><br>У вас была аллергия на мутагенные грибы и химические составы, которые вам давали в начале обучения. Когда пришло время Испытания травами, вам пришлось куда труднее.'),
      (8, 0.1, '1 друг-ведьмак', '<b>Завёл друга</b><br>Во время обучения вы сдружились с другим будущим ведьмаком. Суровые испытания и опасности лишь закалили вашу дружбу.'),
      (9, 0.1, '-1 к Реа', '<b>Травма на маятнике</b><br>Вы получили травму во время тренировок на маятнике. Вы упали со столбов и сломали несколько костей, ударившись о камни внизу. Даже после исцеления вы не столь гибки, как раньше.'),
      (10, 0.1, '+1 к Подготовке ведьмака', '<b>Глубокое изучение</b><br>Обучение владению мечом важно, но большую часть свободного времени вы проводили в библиотеках крепости: изучали монстров и чудовищ и делали записи.')
    ) AS raw_data_ru(num, probability, effect, txt)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
      (1, 0.1, '-1 SPD', '<b>Wounded on the Gauntlet</b><br>You were wounded while running the gauntlet around your School. Your leg was broken badly, and even after healing it is still slightly stiff.'),
      (2, 0.1, '+1 Witcher Diagram', '<b>Stolen Knowledge</b><br>While training at your School you snuck into the libraries of the keep and copied one of the secret witcher diagrams, smuggling the information out with you.'),
      (3, 0.1, 'Make 1 Witcher Enemy', '<b>Made a Rival</b><br>While training at the keep you formed a rivalry with another witcher in training. Even after mutations, their hatred of you continues to boil.'),
      (4, 0.1, '+2 to the Trial of the Grasses', '<b>Easy Mutations</b><br>You adapted well to the lesser mutations and mutagenic mushrooms you were fed early in training. When the time came for the Trial of the Grasses, you were well prepared.'),
      (5, 0.1, '-1 Vigor Threshold', '<b>Magical Backfire</b><br>A failure casting a sign caused minor damage to your body. It was horrifically painful, and even after your body healed your Vigor Threshold was lowered.'),
      (6, 0.1, '+1 Swordsmanship', '<b>Top of Your Class</b><br>You were one of the best swordsmen in your class and your skills haven’t dulled. You perform the complex movements, pirouettes, and spins of the witcher with ease.'),
      (7, 0.1, '-2 to the Trial of the Grasses', '<b>Bad Reaction to Mutagens</b><br>You had allergic reactions to the mutagenic mushrooms and chemical compounds given to you in early training. When the Trial of the Grasses came, it was more difficult.'),
      (8, 0.1, 'Make a Witcher Friend', '<b>Made a Friend</b><br>You made a fast friend in your early years of witcher training. The rough training and dangerous situations sealed your bond.'),
      (9, 0.1, '-1 REF', '<b>Wounded by the Pendulum</b><br>You were wounded while training on the pendulum. You fell from the posts and broke several bones on the rocks below. While healed, you are a little stiffer than before.'),
      (10, 0.1, '+1 Witcher Training', '<b>Extensive Research</b><br>While sword training was important, you spent most of your free time in the libraries of the keep studying the monsters of the world and taking notes.')
    ) AS raw_data_en(num, probability, effect, txt)
),
vals AS (
  SELECT
    ('<td>' || to_char(probability*100, 'FM990.00') || '%</td>'
     || '<td>' || effect || '</td>'
     || '<td>' || txt || '</td>') AS text,
    num, probability, lang, txt
  FROM raw_data
)
, meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_first_trainings' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, ins_label AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM9900') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
       , meta.entity, meta.entity_field, vals.lang, vals.text
  FROM vals
  CROSS JOIN meta
)
-- Создаем i18n записи для characterRaw.lore.trainings (краткое описание тренировок)
, ins_trainings_lore AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  VALUES
    -- Вариант 1: Травма на Мучильне
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o01.lore.trainings'), 'lore', 'trainings', 'ru', 'Травма на Мучильне. Сломана нога, даже после исцеления гнётся хуже.'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o01.lore.trainings'), 'lore', 'trainings', 'en', 'Wounded on the Gauntlet. Leg broken badly, still slightly stiff after healing.'),
    -- Вариант 2: Украденное знание
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o02.lore.trainings'), 'lore', 'trainings', 'ru', 'Украденное знание. Скопировал секретный ведьмачий чертёж из библиотеки крепости.'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o02.lore.trainings'), 'lore', 'trainings', 'en', 'Stolen Knowledge. Copied a secret witcher diagram from the keep library.'),
    -- Вариант 3: Завёл соперника
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o03.lore.trainings'), 'lore', 'trainings', 'ru', 'Завёл соперника. Соперничество с другим будущим ведьмаком, который продолжает ненавидеть.'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o03.lore.trainings'), 'lore', 'trainings', 'en', 'Made a Rival. Formed a rivalry with another witcher in training who continues to hate.'),
    -- Вариант 4: Лёгкие мутации
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o04.lore.trainings'), 'lore', 'trainings', 'ru', 'Лёгкие мутации. Хорошо приспособился к малым мутациям и мутагенным грибам, был готов к Испытанию травами.'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o04.lore.trainings'), 'lore', 'trainings', 'en', 'Easy Mutations. Adapted well to lesser mutations and mutagenic mushrooms, was well prepared for the Trial of the Grasses.'),
    -- Вариант 5: Негативные последствия магии
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o05.lore.trainings'), 'lore', 'trainings', 'ru', 'Негативные последствия магии. Неправильно сотворённый знак повредил тело, значение Энергии снижено.'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o05.lore.trainings'), 'lore', 'trainings', 'en', 'Magical Backfire. A failure casting a sign caused minor damage, Vigor Threshold was lowered.'),
    -- Вариант 6: Лучший в классе
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o06.lore.trainings'), 'lore', 'trainings', 'ru', 'Лучший в классе. Один из лучших мечников среди сверстников, навыки не притупились.'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o06.lore.trainings'), 'lore', 'trainings', 'en', 'Top of Your Class. One of the best swordsmen in class, skills haven''t dulled.'),
    -- Вариант 7: Плохая реакция на мутагены
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o07.lore.trainings'), 'lore', 'trainings', 'ru', 'Плохая реакция на мутагены. Аллергия на мутагенные грибы и химические составы, Испытание травами было труднее.'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o07.lore.trainings'), 'lore', 'trainings', 'en', 'Bad Reaction to Mutagens. Allergic reactions to mutagenic mushrooms and compounds, Trial of the Grasses was more difficult.'),
    -- Вариант 8: Завёл друга
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o08.lore.trainings'), 'lore', 'trainings', 'ru', 'Завёл друга. Сдружился с другим будущим ведьмаком, суровые испытания закалили дружбу.'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o08.lore.trainings'), 'lore', 'trainings', 'en', 'Made a Friend. Made a fast friend in early training, rough training sealed the bond.'),
    -- Вариант 9: Травма на маятнике
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o09.lore.trainings'), 'lore', 'trainings', 'ru', 'Травма на маятнике. Упал со столбов, сломал кости, даже после исцеления не столь гибок.'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o09.lore.trainings'), 'lore', 'trainings', 'en', 'Wounded by the Pendulum. Fell from posts, broke bones, not as flexible after healing.'),
    -- Вариант 10: Глубокое изучение
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o10.lore.trainings'), 'lore', 'trainings', 'ru', 'Глубокое изучение. Большую часть свободного времени проводил в библиотеках, изучая монстров и чудовищ.'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o10.lore.trainings'), 'lore', 'trainings', 'en', 'Extensive Research. Spent most free time in libraries studying monsters and taking notes.')
  ON CONFLICT (id, lang) DO NOTHING
)
-- Создаем i18n записи для eventType (Ранения, Удача, Неудача, Союзники и враги)
, ins_event_types AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  VALUES
    (ck_id('witcher_cc.wcc_witcher_first_trainings.event_type_wounds'), 'character', 'event_type', 'ru', 'Ранения'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings.event_type_wounds'), 'character', 'event_type', 'en', 'Wounds'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings.event_type_fortune'), 'character', 'event_type', 'ru', 'Удача'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings.event_type_fortune'), 'character', 'event_type', 'en', 'Fortune'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings.event_type_misfortune'), 'character', 'event_type', 'ru', 'Неудача'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings.event_type_misfortune'), 'character', 'event_type', 'en', 'Misfortune')
  ON CONFLICT (id, lang) DO NOTHING
)
-- i18n для eventType "Союзники и враги" (создается также в других нодах, используем ON CONFLICT)
, ins_event_type_allies_and_enemies AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id('witcher_cc' ||'.'|| 'wcc_life_events_allies_and_enemies' ||'.'|| 'event_type_allies_and_enemies') AS id
       , 'character', 'event_type', v.lang, v.text
    FROM (VALUES
      ('ru', 'Союзники и враги'),
      ('en', 'Allies and Enemies')
    ) AS v(lang, text)
  ON CONFLICT (id, lang) DO NOTHING
)
-- i18n для description "Враг" и "Союзник"
, ins_event_desc_enemy_ally AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  VALUES
    (ck_id('witcher_cc.wcc_witcher_first_trainings.event_desc_enemy'), 'character', 'event_desc', 'ru', 'Враг'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings.event_desc_enemy'), 'character', 'event_desc', 'en', 'Enemy'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings.event_desc_ally'), 'character', 'event_desc', 'ru', 'Союзник'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings.event_desc_ally'), 'character', 'event_desc', 'en', 'Ally')
  ON CONFLICT (id, lang) DO NOTHING
)
-- Создаем i18n записи для описаний событий (краткие из вариантов ответа)
, ins_event_descriptions AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  VALUES
    -- Вариант 1: Травма на Мучильне
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o01.event_desc'), 'character', 'event_desc', 'ru', 'Травма на Мучильне. Сломана нога. [-1 к Скор]'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o01.event_desc'), 'character', 'event_desc', 'en', 'Wounded on the Gauntlet. Leg broken. [-1 to SPD]'),
    -- Вариант 2: Украденное знание
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o02.event_desc'), 'character', 'event_desc', 'ru', 'Украденное знание. Скопировал секретный ведьмачий чертёж.'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o02.event_desc'), 'character', 'event_desc', 'en', 'Stolen Knowledge. Copied a secret witcher diagram.'),
    -- Вариант 3: Завёл соперника
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o03.event_desc'), 'character', 'event_desc', 'ru', 'Соперничество с другим будущим ведьмаком.'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o03.event_desc'), 'character', 'event_desc', 'en', 'Rivalry with another witcher in training.'),
    -- Вариант 4: Лёгкие мутации
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o04.event_desc'), 'character', 'event_desc', 'ru', 'Лёгкие мутации. Хорошо приспособился к мутагенам.'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o04.event_desc'), 'character', 'event_desc', 'en', 'Easy Mutations. Adapted well to mutagens.'),
    -- Вариант 5: Негативные последствия магии
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o05.event_desc'), 'character', 'event_desc', 'ru', 'Неправильно сотворённый знак повредил тело. [-1 к Энергии]'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o05.event_desc'), 'character', 'event_desc', 'en', 'A failure casting a sign caused damage. [-1 to Vigor]'),
    -- Вариант 6: Лучший в классе
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o06.event_desc'), 'character', 'event_desc', 'ru', 'Один из лучших мечников среди сверстников. [-1 к Владению мечом]'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o06.event_desc'), 'character', 'event_desc', 'en', 'One of the best swordsmen in class. [-1 to Swordsmanship]'),
    -- Вариант 7: Плохая реакция на мутагены
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o07.event_desc'), 'character', 'event_desc', 'ru', 'Плохая реакция на мутагены. Аллергия на мутагенные грибы.'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o07.event_desc'), 'character', 'event_desc', 'en', 'Bad Reaction to Mutagens. Allergic reactions to mutagenic mushrooms.'),
    -- Вариант 8: Завёл друга
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o08.event_desc'), 'character', 'event_desc', 'ru', 'Сдружился с другим будущим ведьмаком.'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o08.event_desc'), 'character', 'event_desc', 'en', 'Made a fast friend in early training.'),
    -- Вариант 9: Травма на маятнике
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o09.event_desc'), 'character', 'event_desc', 'ru', 'Травма на маятнике. Упал со столбов, сломал кости. [-1 к Реакции]'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o09.event_desc'), 'character', 'event_desc', 'en', 'Wounded by the Pendulum. Fell from posts, broke bones. [-1 to REF]'),
    -- Вариант 10: Глубокое изучение
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o10.event_desc'), 'character', 'event_desc', 'ru', 'Проводил время в библиотеках, изучая монстров. [+1 к Подготовке Ведьмака]'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o10.event_desc'), 'character', 'event_desc', 'en', 'Spent time in libraries studying monsters. [+1 to Witcher Training]')
  ON CONFLICT (id, lang) DO NOTHING
)
-- Ведьмачий чертеж теперь добавляется как жетон в магазине (см. 094_shop.sql)
-- Создаем i18n записи для союзника (вариант 8)
, ins_ally_data AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  VALUES
    -- Пол союзника
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o08.ally.gender'), 'character', 'gender', 'ru', 'Мужской'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o08.ally.gender'), 'character', 'gender', 'en', 'Male'),
    -- Позиция союзника
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o08.ally.position'), 'character', 'position', 'ru', 'Ведьмак'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o08.ally.position'), 'character', 'position', 'en', 'Witcher'),
    -- Как познакомились
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o08.ally.how_met'), 'character', 'how_met', 'ru', 'Вместе проходили обучение'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o08.ally.how_met'), 'character', 'how_met', 'en', 'Trained together')
  ON CONFLICT (id, lang) DO NOTHING
)
-- Создаем i18n записи для врага (вариант 3)
, ins_enemy_data AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  VALUES
    -- Пол врага
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o03.enemy.gender'), 'character', 'gender', 'ru', 'Мужской'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o03.enemy.gender'), 'character', 'gender', 'en', 'Male'),
    -- Позиция врага
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o03.enemy.position'), 'character', 'position', 'ru', 'Ведьмак'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o03.enemy.position'), 'character', 'position', 'en', 'Witcher'),
    -- Причина вражды
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o03.enemy.the_cause'), 'character', 'the_cause', 'ru', 'Соперничество при обучении'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o03.enemy.the_cause'), 'character', 'the_cause', 'en', 'Rivalry during training'),
    -- Итог (эскалация)
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o03.enemy.escalation_level'), 'character', 'escalation_level', 'ru', 'Ненависть'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o03.enemy.escalation_level'), 'character', 'escalation_level', 'en', 'Hatred'),
    -- Статус жизни
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o03.enemy.is_alive'), 'character', 'is_alive', 'ru', 'Враг жив'),
    (ck_id('witcher_cc.wcc_witcher_first_trainings_o03.enemy.is_alive'), 'character', 'is_alive', 'en', 'Enemy is alive')
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
SELECT
  'wcc_witcher_first_trainings_o' || to_char(vals.num, 'FM00') AS an_id,
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

-- Эффекты: сохранение описания тренировок в characterRaw.lore.trainings
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_first_trainings' AS qu_id)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_witcher_first_trainings_o' || to_char(vals.num, 'FM00'),
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.trainings'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(vals.num, 'FM00') ||'.lore.trainings')::text)
    )
  )
FROM (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10)) AS vals(num)
CROSS JOIN meta;

-- Эффекты: добавление событий в lifeEvents и различные игромеханические эффекты
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_witcher_first_trainings' AS qu_id)
INSERT INTO effects (scope, an_an_id, body)
-- Вариант 1: Ранения, -1 к SPD.bonus
SELECT 'character', 'wcc_witcher_first_trainings_o01',
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
        'eventType', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.event_type_wounds')::text),
        'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o01.event_desc')::text)
      )
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_first_trainings_o01',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.statistics.SPD.bonus'),
      -1
    )
  )
FROM meta
UNION ALL
-- Вариант 2: Удача, +1 ведьмачий чертёж в gear
SELECT 'character', 'wcc_witcher_first_trainings_o02',
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
        'eventType', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.event_type_fortune')::text),
        'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o02.event_desc')::text)
      )
    )
  )
FROM meta
UNION ALL
-- Ведьмачий чертеж: добавляем жетон для бюджета чертежей
SELECT 'character', 'wcc_witcher_first_trainings_o02',
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.professional_gear_options.witcher_blueprint_tokens'),
      1
    )
  )
FROM meta
UNION ALL
-- Вариант 3: Союзники и враги (Враг), враг-ведьмак в enemies
SELECT 'character', 'wcc_witcher_first_trainings_o03',
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
        'eventType', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_life_events_allies_and_enemies.event_type_allies_and_enemies')::text),
        'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.event_desc_enemy')::text)
      )
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_first_trainings_o03',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.enemies'),
      jsonb_build_object(
        'gender', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_witcher_first_trainings_o03.enemy.gender')::text),
        'position', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_witcher_first_trainings_o03.enemy.position')::text),
        'the_cause', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_witcher_first_trainings_o03.enemy.the_cause')::text),
        'escalation_level', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_witcher_first_trainings_o03.enemy.escalation_level')::text),
        'is_alive', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_witcher_first_trainings_o03.enemy.is_alive')::text)
      )
    )
  )
FROM meta
UNION ALL
-- Вариант 4: Удача, модификатор дайсов +0.2
SELECT 'character', 'wcc_witcher_first_trainings_o04',
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
        'eventType', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.event_type_fortune')::text),
        'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o04.event_desc')::text)
      )
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_first_trainings_o04',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var', 'values.byQuestion.wcc_witcher_when'),
      0.2
    )
  )
FROM meta
UNION ALL
-- Вариант 5: Неудача, -1 к vigor.bonus
SELECT 'character', 'wcc_witcher_first_trainings_o05',
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
        'eventType', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.event_type_misfortune')::text),
        'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o05.event_desc')::text)
      )
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_first_trainings_o05',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.statistics.vigor.bonus'),
      -1
    )
  )
FROM meta
UNION ALL
-- Вариант 6: Удача, +1 к swordsmanship.bonus
SELECT 'character', 'wcc_witcher_first_trainings_o06',
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
        'eventType', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.event_type_fortune')::text),
        'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o06.event_desc')::text)
      )
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_first_trainings_o06',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.common.swordsmanship.bonus'),
      1
    )
  )
FROM meta
UNION ALL
-- Вариант 7: Неудача, модификатор дайсов -0.2
SELECT 'character', 'wcc_witcher_first_trainings_o07',
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
        'eventType', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.event_type_misfortune')::text),
        'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o07.event_desc')::text)
      )
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_first_trainings_o07',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var', 'values.byQuestion.wcc_witcher_when'),
      -0.2
    )
  )
FROM meta
UNION ALL
-- Вариант 8: Союзники и враги (Союзник), друг-ведьмак в allies
SELECT 'character', 'wcc_witcher_first_trainings_o08',
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
        'eventType', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_life_events_allies_and_enemies.event_type_allies_and_enemies')::text),
        'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.event_desc_ally')::text)
      )
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_first_trainings_o08',
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.allies'),
      jsonb_build_object(
        'gender', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_witcher_first_trainings_o08.ally.gender')::text),
        'position', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_witcher_first_trainings_o08.ally.position')::text),
        'how_met', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_witcher_first_trainings_o08.ally.how_met')::text)
      )
    )
  )
FROM meta
UNION ALL
-- Вариант 9: Ранения, -1 к REF.bonus
SELECT 'character', 'wcc_witcher_first_trainings_o09',
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
        'eventType', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.event_type_wounds')::text),
        'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o09.event_desc')::text)
      )
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_first_trainings_o09',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.statistics.REF.bonus'),
      -1
    )
  )
FROM meta
UNION ALL
-- Вариант 10: Удача, +1 к defining.bonus
SELECT 'character', 'wcc_witcher_first_trainings_o10',
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
        'eventType', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.event_type_fortune')::text),
        'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o10.event_desc')::text)
      )
    )
  )
FROM meta
UNION ALL
SELECT 'character', 'wcc_witcher_first_trainings_o10',
  jsonb_build_object(
    'inc',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.defining.bonus'),
      1
    )
  )
FROM meta;

-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_witcher_when', 'wcc_witcher_first_trainings';


























