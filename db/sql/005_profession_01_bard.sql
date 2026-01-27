\echo '005_profession_01_bard.sql'
-- Вариант ответа: Бард

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_profession' AS qu_id
                , 'answer_options' AS entity)
-- Базовые правила видимости (профессия "Бард" только для расы НЕ ведьмак)
, rule_parts AS (
  SELECT
    (SELECT r.body FROM rules r WHERE r.name = 'is_witcher' ORDER BY r.ru_id LIMIT 1) AS is_witcher_expr
)
, vis_rules AS (
  INSERT INTO rules (ru_id, name, body)
  SELECT
    ck_id('witcher_cc.rules.wcc_profession.bard') AS ru_id,
    'wcc_profession_bard' AS name,
    jsonb_build_object('!', rule_parts.is_witcher_expr) AS body
  FROM rule_parts
  ON CONFLICT (ru_id) DO NOTHING
  RETURNING ru_id
)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
            ( 1, 'Бард',
'<div class="ddlist_option">
<table class="profession_table">
    <tr>
        <td>
            <strong>Энергия: </strong> 0<br><br>
            <strong>Магические способности:</strong><br>нет
        </td>
        <td>
            <strong>Базовые навыки</strong>
            <ul>
                <li>[Интеллект] - Язык (выберите 1)</li>
                <li>[Интеллект] - Ориентирование в городе</li>
                <li>[Интеллект] - Этикет</li>
                <li>[Эмпатия] - Выступление</li>
                <li>[Эмпатия] - Искусство</li>
                <li>[Эмпатия] - Обман</li>
                <li>[Эмпатия] - Понимание людей</li>
                <li>[Эмпатия] - Соблазнение</li>
                <li>[Эмпатия] - Убеждение</li>
                <li>[Эмпатия] - Харизма</li>
            </ul>
        </td>
        <td>
            <strong>Снаряжение</strong><br>
            <strong class="section-title">(выберите 5)</strong>
            <ul>
                <li>Доска для покера на костях</li>
                <li>Колода для гвинта</li>
                <li>Ручное зеркальце</li>
                <li>Музыкальный инструмент</li>
                <li>Фляга с выпивкой</li>
                <li>Кинжал</li>
                <li>Духи / одеколон</li>
                <li>Поясная сумка</li>
                <li>Набедренные ножны</li>
                <li>Дневник с замком</li>
            </ul>
            <br><br><strong>Деньги</strong>
            <ul>
                <li>120 крон × 2d6</li>
            </ul>
        </td>
    </tr>
</table>

<h3>Определяющий навык</h3>
<table class="main_skill">
    <tr>
        <td class="header">Уличное выступление (Эмп)</td>
    </tr>
    <tr>
        <td class="opt_content">
            Бард весьма полезен в группе, особенно когда у вас не хватает денег. Бард может потратить час времени и совершить проверку <strong>Уличного выступления</strong> в центре ближайшего города. Результат броска — это сумма, которую бард заработал за время уличного выступления. Критический провал может снизить результат броска. Отрицательный результат означает, что бард не только не заработал денег, но и был освистан местными, что даёт ему штраф -2 к Харизме при контакте со всеми в этом городе на остаток дня.
            <br><br>
            При попытке заворожить публику на достаточно большой площади с множеством людей успешно пройденная проверка со СЛ 15 позволяет создать вокруг барда плотную толпу, для прохода через которую требуется проверка Силы или Атлетики со СЛ 15. Помните, что враги и неразумные существа получают бонус +10 против завораживания.
        </td>
    </tr>
</table>
<h3>Профессиональные навыки</h3>
<table class="skills_branch_1">
    <tr>
        <td class="header">Обольститель</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Повторное выступление (Эмп)</strong><br>
            Перед проверкой <strong>Уличного выступления</strong> бард может совершить проверку <strong>Повторного выступления</strong> со СЛ, установленной ведущим, чтобы определить, выступал ли он в этом городе раньше. При успехе бард уже завоевал популярность в этом городе. В таком случае доход с его <strong>Уличного выступления</strong> удваивается, а сам бард получает бонус +2 к Харизме при общении со всеми, кто пришёл на выступление.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Заворожить публику (Эмп)</strong><br>
            Выступая в течение полного раунда, вы можете совершить проверку способности <strong>Заворожить публику</strong>, чтобы привлечь внимание всех в радиусе 20 метров. Любой персонаж, чей результат проверки Сопротивления убеждению будет ниже вашего изначального, может только стоять и наблюдать, пока не выбросит более высокий результат. Атакованные цели автоматически перестают быть заворожёнными.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Добрый друг (Эмп)</strong><br>
            Один раз за игровую партию бард может совершить проверку способности <strong>Добрый друг</strong>, чтобы найти друга, который помог бы ему. Результат броска необходимо распределить между 3 категориями, указанными в таблице «Добрый друг» на полях. Друг по старой памяти окажет вам одну услугу в пределах разумного, после чего не будет больше помогать бесплатно и его нужно будет уговаривать.
              <div style="display: inline-block;">
              <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr>
                    <th colspan="2">Поселение</th>
                    <th colspan="2">Профессия</th>
                    <th colspan="2">Влиятельность</th>
                </tr>
                <tr>
                    <th>Значение</th> <th>Стоимость</th>
                    <th>Значение</th> <th>Стоимость</th>
                    <th>Значение</th> <th>Стоимость</th>
                </tr>
                <tr>
                    <td>Деревня</td>     <td>3</td>
                    <td>Простолюдин</td> <td>3</td>
                    <td>Низкая</td>      <td>2</td>
                </tr>
                <tr>
                    <td>Посёлок</td>  <td>4</td>
                    <td>Корчмарь</td> <td>5</td>
                    <td>Средняя</td>  <td>5</td>
                </tr>
                <tr>
                    <td>Город</td>       <td>5</td>
                    <td>Ремесленник</td> <td>6</td>
                    <td>Высокая</td>     <td>10</td>
                </tr>
                <tr>
                    <td>Столица</td>  <td>10</td>
                    <td>Стражник</td> <td>8</td>
                    <td></td>         <td></td>
                </tr>
                <tr>
                    <td></td>         <td></td>
                    <td>Дворянин</td> <td>10</td>
                    <td></td>         <td></td>
                </tr>
              </table>
              </div>
        </td>
    </tr>
</table>

<table class="skills_branch_2">
    <tr>
        <td class="header">Информатор</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Незаметность (Инт)</strong><br>
            Бард может совершить проверку <strong>Незаметности</strong> против Внимания нескольких целей, чтобы слиться с толпой. Эта способность позволяет барду прятаться даже там, где нет подходящих укрытий, — бард попросту вклинивается в разговор, переключает внимание окружающих на другой предмет и тому подобное. Эта способность не работает в том случае, если бард одет во что-то очень броское.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Пустить слух (Инт)</strong><br>
            После успешного броска Обмана против цели бард может совершить встречный бросок способности <strong>Пустить слух</strong> против Сопротивления убеждению цели. При успехе барда цель распространяет рассказанную им ложь в своём поселении или группе, что даёт барду бонус +2 к Обману при попытке рассказать ту же ложь кому-то ещё.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Сойти за своего (Инт)</strong><br>
            Находясь в поселении, бард может совершить проверку <strong>Сойти за своего</strong> (см. таблицу на полях). При успехе бард узнаёт, как выдать себя за местного, и его больше не считают чужим. Он получает бонус +2 к Харизме и Убеждению при общении с местными. При этом к нему не будут относиться с подозрением или подвергать травле, как чужака.
            <br>
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr> <th>Поселение</th> <th>СЛ</th> </tr>
                <tr> <td>Деревня</td>   <td>25</td> </tr>
                <tr> <td>Посёлок</td>   <td>20</td> </tr>
                <tr> <td>Город</td>     <td>15</td> </tr>
                <tr> <td>Столица</td>   <td>10</td> </tr>
            </table>
        </td>
    </tr>
</table>

<table class="skills_branch_3">
    <tr>
        <td class="header">Интриган</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Коварство (Эмп)</strong><br>
           Когда бард пытается повлиять на одного или нескольких собеседников, он может совершить проверку <strong>Коварства</strong> против Эмп х 3 цели. При успехе бард делает ехидное замечание, которое даёт штраф -1 к Соблазнению, Убеждению, Лидерству, Запугиванию или Харизме цели за каждый пункт свыше СЛ.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Подколка (Эмп)</strong><br>
            Бард может совершить встречную проверку способности <strong>Подколка</strong> против Сопротивления убеждению цели. При успехе бард дразнит цель, осыпает её угрозами и ругательствами до тех пор, пока цель не нападёт. Цель получает штраф к атаке и защите, равный половине значения <strong>Подколки</strong> барда и длящийся количество раундов, равное значению способности <strong>Подколка</strong>.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>И ты, Брут (Эмп)</strong><br>
            Бард может совершить проверку способности <strong>И ты, Брут</strong> против Воли хЗ цели, чтобы настроить цель против одного союзника. При успехе ложь или полуправда, сказанная бардом, заставляет цель относиться к своему союзнику с подозрением и враждебностью количество дней, равное значению <strong>И ты, Брут</strong>, или пока цель не совершит проверку Сопротивления убеждению, результат которой выше результата <strong>И ты, Брут</strong>.
    </tr>
</table>
</div>
'
         )) AS raw_data_ru(num, title, description)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
            ( 1, 'Bard',
'
<div class="ddlist_option">
<table class="profession_table">
    <tr>
        <td>
            <strong>Vigor:</strong> 0<br>
            <strong>Magical Perks:</strong> None
        </td>
        <td>
            <strong>Skills</strong>
            <ul>
                <li>[EMP] - Charisma</li>
                <li>[EMP] - Deceit</li>
                <li>[EMP] - Performance</li>
                <li>[INT] - Language (Choose 1)</li>
                <li>[EMP] - Human Perception</li>
                <li>[EMP] - Persuasion</li>
                <li>[INT] - Streetwise</li>
                <li>[EMP] - Fine Arts</li>
                <li>[EMP] - Seduction</li>
                <li>[INT] - Social Etiquette</li>
            </ul>
        </td>
        <td>
            <strong>Gear </strong><br>
            <strong class="section-title">(Pick 5)</strong>
            <ul>
                <li>Dice poker board</li>
                <li>Gwent deck</li>
                <li>Hand mirror</li>
                <li>An instrument</li>
                <li>Flask of spirits</li>
                <li>Dagger</li>
                <li>Perfume/cologne</li>
                <li>Belt pouch</li>
                <li>Garter sheath</li>
                <li>A journal with a lock</li>
            </ul>
            <br><br><strong>Money</strong>
            <ul>
                <li>120 crowns × 2d6</li>
            </ul>
        </td>
    </tr>
</table>

<h3>Defining Skill</h3>
<table class="main_skill">
    <tr>
        <td class="header">Busking (EMP)</td>
    </tr>
    <tr>
        <td class="opt_content">
            A Bard is a wonderful thing to have around, especially when the party’s low on money. A Bard can take an hour and make a Busking roll in the nearest town center. The total of this roll is the amount of money raked in by the Bard while they perform on the street. A fumble can lower the roll, and a negative value means that not only do you fail to make any coin but you are also harrassed by the locals for your poor performance, resulting in a −2 to Charisma with anyone in the town for the rest of the day.
            <br><br>
            When raising a crowd in a large area full of people, a DC:15 is sufficient to create a crowd around the Bard dense enough to require a DC:15 Physique or Athletics check to pass through. Also keep in mind that enemies and non-sentient creatures gain a +10 to resist.
        </td>
    </tr>
</table>

<h3>Professional Skills</h3>
<table class="skills_branch_1">
    <tr>
        <td class="header">The Charmer</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Return Act (EMP)</strong><br>
            Before attempting a Busking roll a Bard can roll Return Act at a DC set by the GM to see whether they have played in this town before. If the roll is successful the Bard has made a name for themselves in this town already. Not only is their Busking income doubled but they gain a +2 Charisma with everyone in at that venue.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Raise A Crowd (EMP)</strong><br>
            By taking a full round to perform, you can roll Raise A Crowd to captivate anyone within 20m. Anyone who doesn’t make a Resist Coercion roll higher than your initial roll can do nothing but watch you perform until they succeed at rolling above your initial roll. If attacked a target will snap out of it.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Good Friend (EMP)</strong><br>
            Once per session a Bard can make a Good Friend roll to find a friend to aid them. Take the total roll and split these points up between the 3 categories in the Good Friend chart in the sidebar. This friend will do one reasonable thing for old times’ sake, then cannot be called on again for free and must be convinced.
            <br>
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr>
                    <th colspan="2">Settlement</th>
                    <th colspan="2">Profession</th>
                    <th colspan="2">Importance</th>
                </tr>
                <tr>
                    <th>Value</th> <th>Cost</th>
                    <th>Value</th> <th>Cost</th>
                    <th>Value</th> <th>Cost</th>
                </tr>
                <tr>
                    <td>Hamlet</td>   <td>3</td>
                    <td>Commoner</td> <td>3</td>
                    <td>Low</td>      <td>2</td>
                </tr>
                <tr>
                    <td>Town</td>     <td>4</td>
                    <td>Inn Keep</td> <td>5</td>
                    <td>Average</td>  <td>5</td>
                </tr>
                <tr>
                    <td>City</td>     <td>5</td>
                    <td>Artisan</td>  <td>6</td>
                    <td>High</td>     <td>10</td>
                </tr>
                <tr>
                    <td>Capital</td>  <td>10</td>
                    <td>Guard</td>    <td>8</td>
                    <td></td>         <td></td>
                </tr>
                <tr>
                    <td></td>         <td></td>
                    <td>Noble</td>    <td>10</td>
                    <td></td>         <td></td>
                </tr>
            </table>
        </td>
    </tr>
</table>

<table class="skills_branch_2">
    <tr>
        <td class="header">The Informant</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Fade (INT)</strong><br>
            A Bard can make a Fade roll against multiple targets’ Awareness rolls to fade into the background. This ability allows a Bard to hide even when there are no good hiding places, by slipping into a conversation, drawing attention to something else, or the like. This ability doesn’t work if you are wearing really flashy clothing.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Spread the Word (INT)</strong><br>
            A Bard who rolls a successful Deceit roll against a target can then roll Spread the Word against the target’s Resist Coercion roll. If they succeed the target spreads the Bard’s lie around the target’s settlement or group, giving the Bard a +2 to Deceit when trying to pass off that lie again to someone else.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Acclimatize (INT)</strong><br>
            When in a settlement a Bard can roll Acclimatize (see Acclimatize chart for DC). If successful, the Bard learns how to appear as a local and will no longer be treated as an outsider. This grants a +2 to Charisma &amp; Persuasion with locals and means that they won’t be questioned or harassed like an outsider.
            <br>
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr> <th>Settlement</th> <th>DC</th> </tr>
                <tr> <td>Hamlet</td>   <td>25</td> </tr>
                <tr> <td>Town</td>     <td>20</td> </tr>
                <tr> <td>City</td>     <td>15</td> </tr>
                <tr> <td>Capital</td>  <td>10</td> </tr>
            </table>
        </td>
    </tr>
</table>

<table class="skills_branch_3">
    <tr>
        <td class="header">The Manipulator</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Poison The Well (EMP)</strong><br>
            A Bard can make a Poison The Well roll against a target’s EMP×3 when they are trying to influence a person or people. If successful, the Bard makes a pointed comment that imposes a −1 for each point they rolled above the DC to the target’s Seduction, Persuasion, Leadership, Intimidation or Charisma rolls.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Needling (EMP)</strong><br>
            A Bard can make a Needling roll against a target’s Resist Coercion roll. If successful, the Bard goads them with obscenities and threats until they attack. The target takes a negative to their attack and defense equal to half the Bard’s Needling value, lasting for as many rounds as the Needling value.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Et Tu Brute (EMP)</strong><br>
            A Bard can roll Et Tu Brute against a target’s WILL×3 to turn them against one ally. If successful the Bard’s lies and half-truths makes the target treat that ally with mistrust and animosity for as many days as the Et Tu Brute value or until they make a Resist Coercion roll that beats the Et Tu Brute roll.
        </td>
    </tr>
</table>
</div>
')
         ) AS raw_data_en(num, title, description)
)
, ins_title AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.title') AS id
       , meta.entity, 'title', raw_data.lang, raw_data.title
    FROM raw_data
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
, ins_description AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.description') AS id
       , meta.entity, 'description', raw_data.lang, raw_data.description
    FROM raw_data
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT 'wcc_profession_o' || to_char(raw_data.num, 'FM00') AS an_id,
       meta.su_su_id,
       meta.qu_id,
       ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.title') AS label,
       raw_data.num AS sort_order,
       ck_id('witcher_cc.rules.wcc_profession.bard') AS visible_ru_ru_id,
       jsonb_build_object(
           'title', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.title')::text),
           'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.description')::text)
       ) AS metadata
FROM raw_data
CROSS JOIN meta
ON CONFLICT (an_id) DO NOTHING;

-- Bard (pick 5)
-- Dice poker board - T065
-- Gwent deck - T066
-- Hand mirror - T048
-- An instrument - T101
-- Flask of spirits - custom
-- Dagger - W082
-- Perfume/cologne - T050
-- Belt pouch - T012
-- Garter sheath - T020
-- A journal with a lock - Customized T060

-- Эффекты: заполнение professional_gear_options
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o01' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.professional_gear_options'),
      jsonb_build_object(
        'tokens', 5,
        'items', jsonb_build_array('T065', 'T066', 'T048', 'T101', 'W082', 'T050', 'T012', 'T020', 'T060'),
        'bundles', jsonb_build_array()
      )
    )
  ) AS body;

-- Эффекты: стартовые деньги
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o01' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.money.crowns'),
      jsonb_build_object(
        '*',
        jsonb_build_array(
          120,
          jsonb_build_object(
            '+',
            jsonb_build_array(
              jsonb_build_object('d6', jsonb_build_array()),
              jsonb_build_object('d6', jsonb_build_array())
            )
          )
        )
      )
    )
  ) AS body;

-- Эффекты: добавление начальных навыков в characterRaw.skills.initial[]
WITH skill_mapping (skill_name) AS ( VALUES
    ('streetwise'),           -- Ориентирование в городе
    ('social_etiquette'),    -- Этикет
    ('performance'),         -- Выступление
    ('fine_arts'),           -- Искусство
    ('deceit'),              -- Обман
    ('human_perception'),    -- Понимание людей
    ('seduction'),           -- Соблазнение
    ('persuasion'),          -- Убеждение
    ('charisma')             -- Харизма
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o01' AS an_an_id,
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.initial'),
      sm.skill_name
    )
  ) AS body
FROM skill_mapping sm;