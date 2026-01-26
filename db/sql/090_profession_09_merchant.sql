\echo '090_profession_09_merchant.sql'
-- Вариант ответа: Торговец

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_profession' AS qu_id
                , 'answer_options' AS entity)
-- Базовые правила видимости (профессия "Торговец" только для расы НЕ ведьмак)
, rule_parts AS (
  SELECT
    (SELECT r.body FROM rules r WHERE r.name = 'is_witcher' ORDER BY r.ru_id LIMIT 1) AS is_witcher_expr
)
, vis_rules AS (
  INSERT INTO rules (ru_id, name, body)
  SELECT
    ck_id('witcher_cc.rules.wcc_profession.merchant') AS ru_id,
    'wcc_profession_merchant' AS name,
    jsonb_build_object('!', rule_parts.is_witcher_expr) AS body
  FROM rule_parts
  ON CONFLICT (ru_id) DO NOTHING
  RETURNING ru_id
)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
            ( 9, 'Торговец', '
<div class="ddlist_option">
<table class="profession_table">
    <tr>
        <td>
            <strong>Энергия:</strong> 0<br><br>
            <strong>Магические способности:</strong><br>
            <strong class="section-title">Нет</strong>
        </td>
        <td>
            <strong>Навыки</strong>
            <ul>
                <li>[Воля] - Сопротивление убеждению</li>
                <li>[Интеллект] - Образование</li>
                <li>[Интеллект] - Ориентирование в городе</li>
                <li>[Интеллект] - Торговля</li>
                <li>[Интеллект] - Язык (выберите 1)</li>
                <li>[Реакция] - Владение лёгкими клинками</li>
                <li>[Эмпатия] - Азартные игры</li>
                <li>[Эмпатия] - Понимание людей</li>
                <li>[Эмпатия] - Убеждение</li>
                <li>[Эмпатия] - Харизма</li>
            </ul>
        </td>
        <td>
            <strong>Снаряжение</strong><br>
            <strong class="section-title">(выберите 3)</strong>
            <ul>
                <li>Письменные принадлежности</li>
                <li>Инструменты торговца</li>
                <li>Большая палатка</li>
                <li>Дневник</li>
                <li>Арбалет и арбалетные болты x20</li>
                <li>Кинжал</li>
            </ul>
            <br><strong>Особое снаряжение</strong>
            <ul>
                <li>Мул</li>
                <li>Повозка</li>
                <li>Обычные или повседневные товары общей стоимостью 1000 крон</li>
            </ul>
            <br><br><strong>Деньги</strong>
            <ul>
                <li>180 крон × 2d6</li>
            </ul>
        </td>
    </tr>
</table>

<h3>Определяющий навык</h3>
<table class="main_skill">
    <tr>
        <td class="header">Бывалый путешественник (Инт)</td>
    </tr>
    <tr>
        <td class="opt_content">
            Обычный торговец зарабатывает на жизнь тем, что продаёт товар приходящим к нему покупателям. Странствующий же торговец сам приходит к покупателю. Он ездит по миру и узнаёт обо всём, что там происходит. Торговец может в любой момент по своему желанию совершить проверку навыка <strong>Бывалый путешественник</strong>, чтобы узнать один факт об определённом предмете, культуре или области. СЛ проверки определяет ведущий. При успехе торговец получает ответ на вопрос, вспомнив те времена, когда он в прошлый раз был в этом месте.
        </td>
    </tr>
</table>

<h3>Профессиональные навыки</h3>

<table class="skills_branch_1">
    <tr>
        <td class="header">Посредник</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Рынок (Инт)</strong><br>
            Торговец может совершить проверку <strong>Рынка</strong> с определяемой ведущим СЛ, чтобы найти нужный предмет по более низкой цене. При успехе торговец находит того, кто продаст ему тот же предмет за полцены. Чем более редкий предмет, тем выше СЛ поиска. <strong>Рынок</strong> не действует на экспериментальные, ведьмачьи предметы и реликвии.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Нечестная сделка (Эмп)</strong><br>
            Совершая подкуп, торговец может совершить проверку способности <strong>Нечестная сделка</strong> со СЛ, равной Воле х 3 цели. При успехе торговец даёт взятку любым предметом, который у него есть и который стоит не менее 5 крон. Взятка всегда даёт +3 к Убеждению. Если взятка совсем уж несуразна, СЛ увеличивается на 5.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Обещание (Эмп)</strong><br>
            При попытке купить предмет торговец может совершить проверку <strong>Обещания</strong> со СЛ, равной Эмп х 3 продавца. При успехе продавец верит обещанию торговца заплатить позже. Количество недель, через которое необходимо выполнить это обязательство, равно значению <strong>Обещания</strong>.
        </td>
    </tr>
</table>

<table class="skills_branch_2">
    <tr>
        <td class="header">Человек со связями</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Трущобы (Эмп)</strong><br>
            Торговец может совершить проверку способности <strong>Трущобы</strong> со СЛ в зависимости от размера поселения, чтобы заручиться помощью 1 беспризорника или бездомного за каждый пункт свыше СЛ (максимум 10). Торговец может спросить у них совета и получить бонус +1 к проверкам Ориентирования в городе за каждого. Информаторы берут плату в 1 крону на каждого, когда с ними советуются.
            <br><br>
            <div style="display:inline-block;">
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr>
                    <th colspan="2">Поселения</th>
                </tr>
                <tr>
                    <th>Значение</th> <th>Стоимость</th>
                </tr>
                <tr>
                    <td>Деревня</td> <td>14</td>
                </tr>
                <tr>
                    <td>Небольшой город</td> <td>18</td>
                </tr>
                <tr>
                    <td>Столица</td> <td>22</td>
                </tr>
            </table>
            </div>
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Свой человек (Инт)</strong><br>
            Торговец со способностью <strong>Свой человек</strong> может убедить другого персонажа пошпионить на него. Заплатите 10 крон и совершите встречную проверку <strong>Своего человека</strong> против Сопротивления убеждению цели. При успехе персонаж будет шпионить для торговца количество дней, равное значению способности <strong>Свой человек</strong>. По истечении этого срока торговец может снова совершить проверку, опять же заплатив.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Карта сокровищ (Инт)</strong><br>
            Один раз за игровую партию торговец может совершить проверку способности <strong>Карта сокровищ</strong> со СЛ, определяемой ведущим, чтобы вспомнить предполагаемое местонахождение реликвии или руин, в которых может оказаться что-то полезное. Место, где находится этот предмет или руины, расположено достаточно далеко или же кишит опасностями. Чтобы добраться до него, потребуется целая игровая партия.
        </td>
    </tr>
</table>

<table class="skills_branch_3">
    <tr>
        <td class="header">Гавенкар</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Хорошие связи (Воля)</strong><br>
            Входя в поселение впервые, торговец может потратить час на распространение вести о своём прибытии, а затем совершить проверку <strong>Хороших связей</strong> со СЛ в зависимости от размера поселения. При успехе репутация торговца в этом поселении на 1d6 недель увеличивается на значение проверки свыше указанной СЛ, делённое на 2 (минимум 1).
        <br><br>
            <div style="display:inline-block;">
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr>
                    <th colspan="2">Поселения</th>
                </tr>
                <tr>
                    <th>Значение</th> <th>Стоимость</th>
                </tr>
                <tr>
                    <td>Деревня</td> <td>14</td>
                </tr>
                <tr>
                    <td>Небольшой город</td> <td>18</td>
                </tr>
                <tr>
                    <td>Столица</td> <td>22</td>
                </tr>
            </table>
            </div>
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Сбытчик (Инт)</strong><br>
            Торговец, которому необходимо избавиться от предмета с сомнительным происхождением или краденого, может совершить проверку способности <strong>Сбытчик</strong> со СЛ, определяемой ведущим. При успехе торговец продаст предмет по полной рыночной цене покупателю, который не станет задавать лишних вопросов и не сдаст торговца страже.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Воинский долг (Эмп)</strong><br>
            Торговец может совершить проверку способности <strong>Воинский долг</strong>, чтобы попросить о помощи воина, который у него в долгу. Результат броска необходимо распределить по 3 категориям, указанным в таблице на полях. Воин будет работать на торговца количество дней, равное значению <strong>Воинского долга</strong>, и без лишних вопросов исполнит любой приказ в пределах разумного.
            <br><br>
            <div style="display:inline-block;">
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr>
                    <th>Значение</th>
                    <th>Стоимость</th>
                </tr>
                <tr>
                    <th colspan="2">Атака и защита</th>
                </tr>
                <tr>
                    <td>10</td>
                    <td>4</td>
                </tr>
                <tr>
                    <td>14</td>
                    <td>8</td>
                </tr>
                <tr>
                    <td>16</td>
                    <td>10</td>
                </tr>
                <tr>
                    <th colspan="2">Интеллект</th>
                </tr>
                <tr>
                    <td>3</td>
                    <td>2</td>
                </tr>
                <tr>
                    <td>5</td>
                    <td>5</td>
                </tr>
                <tr>
                    <td>9</td>
                    <td>10</td>
                </tr>
                <tr>
                    <th colspan="2">Оружие и броня</th>
                </tr>
                <tr>
                    <td>Корпусная броня (ПБ 3), зириканский кинжал, ручной арбалет и 10 арбалетных болтов</td>
                    <td>4</td>
                </tr>
                <tr>
                    <td>Корпусная броня (ПБ 5), длинный лук и 30 стрел</td>
                    <td>6</td>
                </tr>
                <tr>
                    <td>Полный латный доспех и тортур</td>
                    <td>10</td>
                </tr>
            </table>
            </div>
        </td>
    </tr>
</table>
</div>
')
         ) AS raw_data_ru(num, title, description)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
            ( 9, 'Merchant', '
<div class="ddlist_option">
<table class="profession_table">
    <tr>
        <td>
            <strong>Vigor:</strong> 0<br><br>
            <strong>Magical Perks:</strong><br>
            <strong class="section-title">None</strong>
        </td>
        <td>
            <strong>Skills</strong>
            <ul>
                <li>[EMP] - Charisma</li>
                <li>[EMP] - Gambling</li>
                <li>[EMP] - Human Perception</li>
                <li>[EMP] - Persuasion</li>
                <li>[INT] - Business</li>
                <li>[INT] - Education</li>
                <li>[INT] - Language (Choose 1)</li>
                <li>[INT] - Streetwise</li>
                <li>[REF] - Small Blades</li>
                <li>[WILL] - Resist Coercion</li>
            </ul>
        </td>
        <td>
            <strong>Gear</strong><br>
            <strong class="section-title">(Pick 3)</strong>
            <ul>
                <li>Crossbow &amp; bolts x20</li>
                <li>Dagger</li>
                <li>Journal</li>
                <li>Large tent</li>
                <li>Merchant’s tools</li>
                <li>Writing kit</li>
            </ul>
            <br><strong>Special Gear</strong>
            <ul>
                <li>Mule</li>
                <li>Cart</li>
                <li>Common or everyday items worth 1000 crowns</li>
            </ul>
            <br><br><strong>Money</strong>
            <ul>
                <li>180 crowns × 2d6</li>
            </ul>
        </td>
    </tr>
</table>

<h3>Defining Skill</h3>
<table class="main_skill">
    <tr>
        <td class="header">Well Traveled (INT)</td>
    </tr>
    <tr>
        <td class="opt_content">
            Your average merchant makes a living from trade, and that trade brings in customers from all around. But a traveling merchant goes to their customers, wandering the roads of the world and learning from its people. A Merchant can make a <strong>Well Traveled</strong> roll any time they want to know a fact about a specific item, culture, or area. The DC is set by the GM, and if the roll is successful the Merchant remembers the answer to that question, calling on memories of the last time they traveled through the applicable area.
        </td>
    </tr>
</table>

<h3>Professional Skills</h3>

<table class="skills_branch_1">
    <tr>
        <td class="header">The Broker</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Options (INT)</strong><br>
            A Merchant can roll <strong>Options</strong> against a DC set by the GM to find a lower price on an item. If they succeed the Merchant finds another person selling the same item for half the price. The higher the item rarity, the higher the DC should be. <strong>Options</strong> does not affect experimental, witcher, or relic items.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Hard Bargain (EMP)</strong><br>
            When bribing a target a Merchant can roll <strong>Hard Bargain</strong> at a DC equal to the opponent’s WILLx3. If they succeed, they can bribe the opponent with any item they have at hand that is worth 5 crowns. The object always grants +3 to Persuasion. The DC rises by 5 for truly ridiculous bribes.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Promise (EMP)</strong><br>
            When attempting to buy an item, a Merchant can make a <strong>Promise</strong> roll at a DC equal to the Salesperson’s EMPx3. If they succeed the salesperson accepts the Merchant’s promise to pay for the item later. This promise holds the salesperson over for a number of weeks equal to your <strong>Promise</strong> ability.
        </td>
    </tr>
</table>

<table class="skills_branch_2">
    <tr>
        <td class="header">The Contact</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Rookery (EMP)</strong><br>
            A Merchant can make a <strong>Rookery</strong> roll at a DC based on the settlement they are in to gain the aid of 1 urchin or vagrant per 1 point they rolled over the DC (maximum 10). These people can be consulted to grant +1 per person on Streetwise rolls. Informants take 1 crown each as payment each time they are consulted.
            <br><br>
            <div style="display:inline-block;">
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr>
                    <th colspan="2">Settlements</th>
                </tr>
                <tr>
                    <th>Value</th> <th>Cost</th>
                </tr>
                <tr>
                    <td>Thorp</td> <td>14</td>
                </tr>
                <tr>
                    <td>Small city</td> <td>18</td>
                </tr>
                <tr>
                    <td>Capital</td> <td>22</td>
                </tr>
            </table>
            </div>
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Insider (INT)</strong><br>
            A Merchant with <strong>Insider</strong> can convince a person to spy for them. Spend 10 crowns and roll <strong>Insider</strong> versus the person’s Resist Coercion roll. If it is successful the person will spy on a target for as many days as your <strong>Insider</strong> value. At the end of this time you can roll again, but must pay again.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Treasure Map (INT)</strong><br>
            Once per session a Merchant can roll <strong>Treasure Map</strong> at a DC set by the GM to remember the supposed location of a relic item, or a ruin that may hide something useful. This location will, of course, be out of the way or exceedingly dangerous, requiring a quest. Reaching this item or ruin should require a full session.
        </td>
    </tr>
</table>

<table class="skills_branch_3">
    <tr>
        <td class="header">The Havekar</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Well Connected (WILL)</strong><br>
            On first entering a settlement, a Merchant can spend an hour spreading word of their arrival, then roll <strong>Well Connected</strong> at a DC based on the settlement. Success raises their reputation in that settlement by a number equal to the amount you rolled over the DC divided by 2 (minimum 1), for 1d6 Weeks.
            <br><br><div style="display:inline-block;">
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr>
                    <th colspan="2">Settlements</th>
                </tr>
                <tr>
                    <th>Value</th> <th>Cost</th>
                </tr>
                <tr>
                    <td>Thorp</td> <td>14</td>
                </tr>
                <tr>
                    <td>Small city</td> <td>18</td>
                </tr>
                <tr>
                    <td>Capital</td> <td>22</td>
                </tr>
            </table>
            </div>
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Fence (INT)</strong><br>
            A Merchant who has to get rid of a dubious or stolen item can make a <strong>Fence</strong> roll at a DC determined by the GM. If they succeed, they sell the item (at full market price) to a buyer who won’t ask any serious questions and won’t turn them in to the Guard.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Warrior’s Debt (EMP)</strong><br>
            A Merchant can roll <strong>Warrior’s Debt</strong> to call on a fighter who owes them. Split your roll between the 3 sections on the Warrior table in the sidebar. This warrior will work for you for a number of days equal to your <strong>Warrior’s Debt</strong> value and takes any reasonable order you give without asking questions.
            <br><br>
            <div style="display:inline-block;">
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr>
                    <th>Value</th>
                    <th>Cost</th>
                </tr>
                <tr>
                    <th colspan="2">Attack &amp; Defense</th>
                </tr>
                <tr>
                    <td>10</td>
                    <td>4</td>
                </tr>
                <tr>
                    <td>14</td>
                    <td>8</td>
                </tr>
                <tr>
                    <td>16</td>
                    <td>10</td>
                </tr>
                <tr>
                    <th colspan="2">Intelligence</th>
                </tr>
                <tr>
                    <td>3</td>
                    <td>2</td>
                </tr>
                <tr>
                    <td>5</td>
                    <td>5</td>
                </tr>
                <tr>
                    <td>9</td>
                    <td>10</td>
                </tr>
                <tr>
                    <th colspan="2">Weapons &amp; Armor</th>
                </tr>
                <tr>
                    <td>SP:3 body armor, a zerrikanian dagger &amp; a hand crossbow &amp; 10 arbalet bolts</td>
                    <td>4</td>
                </tr>
                <tr>
                    <td>SP:5 body armor &amp; a longbow with 30 arrows</td>
                    <td>6</td>
                </tr>
                <tr>
                    <td>Full plate &amp; torrrw</td>
                    <td>10</td>
                </tr>
            </table>
            </div>
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
       ck_id('witcher_cc.rules.wcc_profession.merchant') AS visible_ru_ru_id,
       jsonb_build_object(
           'title', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.title')::text),
           'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.description')::text)
       ) AS metadata
FROM raw_data
CROSS JOIN meta
ON CONFLICT (an_id) DO NOTHING;

-- Merchant (pick 3)
-- Crossbow & bolts ×20 - W001 & W024 x 2
-- Dagger - W082
-- Journal - T060
-- Large tent - T071
-- Merchant's tools - T102
-- Writing kit - T115

-- Mule - WT005
-- Cart - WT002
-- Common or everyday items worth 1000 crowns - custom

-- Эффекты: заполнение professional_gear_options
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_profession_shop.bundle.crossbow_bolts') AS id
     , 'questions' AS entity
     , 'metadata' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          ('ru', 'Арбалет и болты ×20'),
          ('en', 'Crossbow & bolts ×20')
       ) AS v(lang, text)
ON CONFLICT (id, lang) DO NOTHING;

INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o09' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.professional_gear_options'),
      jsonb_build_object(
        'tokens', 3,
        'items', jsonb_build_array('W082', 'T060', 'T071', 'T102', 'T115', 'WT005', 'WT002'),
        'bundles', jsonb_build_array(
          jsonb_build_object(
            'bundleId', 'crossbow_bolts_set',
            'displayName', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_profession_shop.bundle.crossbow_bolts')::text),
            'items', jsonb_build_array(
              jsonb_build_object(
                'sourceId', 'weapons',
                'itemId', 'W001',
                'quantity', 1
              ),
              jsonb_build_object(
                'sourceId', 'weapons',
                'itemId', 'W024',
                'quantity', 2
              )
            )
          )
        )
      )
    )
  ) AS body;

-- Эффекты: стартовые деньги
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o09' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.money.crowns'),
      jsonb_build_object(
        '*',
        jsonb_build_array(
          180,
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

-- Эффекты: торговцу сразу в инвентарь мул (WT005) и телега (WT002)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o09' AS an_an_id,
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.gear'),
      jsonb_build_object(
        'wt_id', 'WT005',
        'sourceId', 'vehicles',
        'amount', 1
      )
    )
  ) AS body;

INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o09' AS an_an_id,
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.gear'),
      jsonb_build_object(
        'wt_id', 'WT002',
        'sourceId', 'vehicles',
        'amount', 1
      )
    )
  ) AS body;