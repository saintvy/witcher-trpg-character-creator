\echo '005_profession_13_peasant.sql'
-- Вариант ответа: Крестьянин

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_profession' AS qu_id
                , 'answer_options' AS entity)
, ensure_rules AS (
  INSERT INTO rules (ru_id, name, body)
  VALUES
    (ck_id('witcher_cc.rules.is_dlc_prof_peasant_enabled'), 'is_dlc_prof_peasant_enabled', '{"in":["dlc_prof_peasant",{"var":["dlcs",[]]}]}'::jsonb)
  ON CONFLICT (ru_id) DO UPDATE
  SET name = EXCLUDED.name,
      body = EXCLUDED.body
  RETURNING body AS dlc_prof_peasant_expr
)
, rule_parts AS (
  SELECT
    (SELECT r.body FROM rules r WHERE r.name = 'is_witcher' ORDER BY r.ru_id LIMIT 1) AS is_witcher_expr,
    (SELECT er.dlc_prof_peasant_expr FROM ensure_rules er LIMIT 1) AS dlc_prof_peasant_expr
)
, vis_rules AS (
  INSERT INTO rules (ru_id, name, body)
  SELECT
    ck_id('witcher_cc.rules.wcc_profession.peasant') AS ru_id,
    'wcc_profession_peasant' AS name,
    jsonb_build_object(
      'and',
      jsonb_build_array(
        jsonb_build_object('!', rule_parts.is_witcher_expr),
        rule_parts.dlc_prof_peasant_expr
      )
    ) AS body
  FROM rule_parts
  ON CONFLICT (ru_id) DO UPDATE
  SET name = EXCLUDED.name,
      body = EXCLUDED.body
  RETURNING ru_id
)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
      (13, 'Крестьянин', $ru$
<div class="ddlist_option">
<table class="profession_table"><tr>
<td><strong>Энергия:</strong> 0<br><br><strong>Магические способности:</strong><br><strong class="section-title">Нет</strong></td>
<td><strong>Навыки</strong><ul>
<li>[Воля] - Храбрость</li>
<li>[Ловкость] - Атлетика</li>
<li>[Интеллект] - Выживание в дикой природе</li>
<li>[Реакция] - Борьба</li>
<li>[Реакция] - Владение легкими клинками</li>
<li>[Ремесло] - Изготовление</li>
<li>[Ремесло] - Первая помощь</li>
<li>[Телосложение] - Стойкость</li>
<li>[Телосложение] - Сила</li>
<li>[Эмпатия] - Азартные игры</li>
</ul></td>
<td><strong>Снаряжение</strong><br><strong class="section-title">(выберите 5)</strong><ul>
<li>Пиво</li><li>Ещё одно Пиво</li><li>Корзина</li><li>Теплая Одежда</li><li>Принадлежности для Готовки</li>
<li>Огниво</li><li>Колода Гвинта</li><li>Священный символ</li><li>Трубка с Табаком</li><li>Мешок</li>
</ul><br><strong>Стартовые Деньги</strong><ul><li>20 крон x 2d6</li></ul></td>
</tr></table>

<h3>Определяющий навык</h3>
<table class="main_skill"><tr><td class="header">Нетерпимость (Воля)</td></tr><tr><td class="opt_content">
Крестьяне боязливы и часто не зря. При первой встрече с разумным существом со статусом Ненависть или Опасение, крестьянин может сделать проверку <strong>Нетерпимость</strong> против СЛ, равной Эмп x3 цели. При успехе страх превращается в ярость: до конца схватки крестьянин получает бонус, равный значению <strong>Нетерпимости</strong>, к <strong>Сопротивлению убеждению</strong> и <strong>Храбрости</strong> против этой цели. Также крестьянин получает бонус к <strong>Лидерству</strong>, равный 1/2 значения <strong>Нетерпимости</strong>, когда сплачивает других крестьян.
<br><br>В контексте этой способности любой NPC без профессии или выраженной социальной роли вне крестьянства (например, тайная полиция, профессор Оксенфурта) считается крестьянином.
</td></tr></table>

<h3>Профессиональные навыки</h3>
<table class="skills_branch_1">
<tr><td class="header">Фермер</td></tr>
<tr><td class="opt_content"><strong>Время Жатвы</strong><br>Знание правильного времени и способа сбора урожая - это навык, на освоение которого уходят годы. При добыче алхимических компонентов растительного происхождения крестьянин получает дополнительное количество единиц, равное половине значения его <strong>Времени Жатвы</strong> (минимум 1).</td></tr>
<tr><td class="opt_content"><strong>Шепот Животным (Эмп)</strong><br>Действием крестьянин делает проверку <strong>Шепот Животным</strong> против Воли животного x3, чтобы командовать прирученным животным.
<br><br><table border="1" cellpadding="4" cellspacing="0" class="table-small">
<tr><th>Прирученные Звери</th><th>СЛ</th></tr>
<tr><td>Пчелы</td><td>21</td></tr><tr><td>Курицы</td><td>15</td></tr><tr><td>Коровы</td><td>12</td></tr>
<tr><td>Козы</td><td>18</td></tr><tr><td>Свиньи</td><td>15</td></tr><tr><td>Кролики</td><td>12</td></tr><tr><td>Овцы</td><td>9</td></tr>
</table></td></tr>
<tr><td class="opt_content"><strong>Фермерская Мудрость (Рем)</strong><br>Хоть магией обладают не все, есть некоторые трюки, которым можно научиться, чтобы склонить чашу весов в свою пользу. Крестьянин может совершить одно действие и пройти проверку <strong>Фермерской Мудрости</strong>, чтобы выполнить один из народных ритуалов на соседней странице. У каждого ритуала есть своя СЛ и требования.
<br><br><table border="1" cellpadding="4" cellspacing="0" class="table-small">
<tr><th>Ритуал</th><th>СЛ</th><th>Ингредиенты</th><th>Описание</th><th>Эффект</th></tr>
<tr><td>Кровоочиститель</td><td>8</td><td>Эфир x2, Купорос x1</td><td>Смешать ингредиенты в лосьон</td><td>Стирает кровь с площади до 5 м3.</td></tr>
<tr><td>Предсказание Погоды</td><td>10</td><td>—</td><td>Осмотреть небо и понаблюдать за поведением животных</td><td>Погода на следующие 24 часа.</td></tr>
<tr><td>Венок из Трав</td><td>12</td><td>Растительные алх. материалы x3</td><td>Сплести венок и надеть</td><td>Идеальная память на 24 часа.</td></tr>
<tr><td>Круг от Вредителей</td><td>14</td><td>Любое алх. вещество x5</td><td>Рассыпать вещество по кругу (радиус 20 м)</td><td>Инсектоиды/Звери проходят Стойкость против СЛ броска до входа в круг 20м.</td></tr>
<tr><td>Убийца Кошмаров</td><td>16</td><td>—</td><td>Вывернуть одежду наизнанку, надеть шляпу задом наперёд, произнести стишок</td><td>Иммунитет к кошмарам на ночь.</td></tr>
<tr><td>Раскрытие Черной Магии</td><td>18</td><td>Кусок дерева x1</td><td>Вырезать символы на куске дерева</td><td>Одноразовый тотем чернеет рядом с проклятым/порченым.</td></tr>
<tr><td>Талисман</td><td>20</td><td>Перья x1, различные алх. вещества x3</td><td>Создать амулет из ингредиентов</td><td>Одноразовый бонус к УДАЧЕ, равный Фермерской Мудрости; не восстанавливается, не суммируется.</td></tr>
</table></td></tr>
</table>

<table class="skills_branch_2">
<tr><td class="header">Повар</td></tr>
<tr><td class="opt_content"><strong>Мясник (Рем)</strong><br>Когда крестьянин обирает физического монстра или животное, он может пройти проверку <strong>Мясника</strong> со СЛ зависящей от подкатегории зверя. При успехе, он может получить максимальное количество единиц одного типа органической добычи с этого животного. Этот бросок можно сделать несколько раз на одном трупе, но крестьянин не может сделать две попытки на одну и ту же часть зверя.
<br><br><table border="1" cellpadding="4" cellspacing="0" class="table-small">
<tr><th>Категория монстра</th><th>СЛ</th></tr>
<tr><td>Обычные</td><td>12</td></tr><tr><td>Незаурядные</td><td>16</td></tr><tr><td>Трудные</td><td>20</td></tr>
</table></td></tr>
<tr><td class="opt_content"><strong>Панацея от всех бед (Рем)</strong><br>Используя по одной единице трех разных типов алхимических компонентов, за 10 минут Крестьянин может создать народную <strong>Панацею от всех бед</strong>. У этой смеси есть процентный шанс излечить человека, потребляющего ее, от <strong>отравления</strong>, <strong>опьянения</strong> и <strong>тошноты</strong>. Процент равен значению навыка <strong>Панацея от всех бед</strong> x 5. Это лекарство нужно использовать в течении суток, прежде чем оно испортится. При использовании оно тратится полностью.</td></tr>
<tr><td class="opt_content"><strong>Мамино Рагу (Рем)</strong><br>Раз в день, если у крестьянина есть принадлежности для готовки и необходимые ингредиенты, он может потратить 1 час на приготовление рагу по старому семейному рецепту. Этого рагу достаточно, чтобы накормить 6 человек, и его эффекты зависят от того, какие ингредиенты были использованы. Эффекты длятся в течение 24 часов.
<br><br><table border="1" cellpadding="4" cellspacing="0" class="table-small">
<tr><th>Рецепт</th><th>Ингредиенты</th><th>Эффекты</th></tr>
<tr><td>Урожайная Симфония</td><td>Сырое мясо x2, Пиво x3, Собачья петрушка x3, Плод берберки x4</td><td>Иммунитет к страху и ПБ = 1/3 <strong>Мамино Рагу</strong>.</td></tr>
<tr><td><strong>Мамино Рагу</strong></td><td>Вороний глаз x5, Лепестки морозника x3, Переступень x2, Собачья петрушка x2</td><td>Состояние тошноты до проверки Стойкости против проверки <strong>Мамино Рагу</strong>.</td></tr>
<tr><td>Особый Бульон</td><td>Звериные кости x4, Собачье сало x2, Омела x3, Волокна хана x3</td><td>Сокращает срок лечения критрана на 1/2 <strong>Мамино Рагу</strong> (мин. 1 день).</td></tr>
<tr><td>Весеннее Рагу</td><td>Плод балиссы x3, Сырое мясо x2, Грибы-шибальцы x4, Жимолость x3</td><td>Бонус к соблазнению = 1/2 <strong>Мамино Рагу</strong>, к выносливости = x3 <strong>Мамино Рагу</strong>.</td></tr>
<tr><td>Рагу из Тролля</td><td>Ячмень x3, Склеродерм x4, Сера x2, Сырое мясо x3</td><td>Бонус к снятию отравления = 1/2 <strong>Мамино Рагу</strong> и сопротивление урону от яда.</td></tr>
<tr><td>Зимнее Рагу</td><td>Ячмень x5, Звериные кости x2, Склеродерм x3, Корень зарника x2</td><td>Иммунитет к заморозке и доп. часы выживания в холоде = <strong>Мамино Рагу</strong>.</td></tr>
</table></td></tr>
</table>

<table class="skills_branch_3">
<tr><td class="header">Рабочий</td></tr>
<tr><td class="opt_content"><strong>Землекоп</strong><br>Годы ручного труда укрепили тело крестьянина и научили его технике, позволяющей сделать даже самый изнурительный труд выполнимым. Двойное значение навыка <strong>Землекоп</strong> добавляется к параметру Вес крестьянина. Также, проходя проверки на Телосложение или Выносливость при выполнении физического труда, Крестьянин может добавлять половину своего значения <strong>Землекоп</strong>.</td></tr>
<tr><td class="opt_content"><strong>Грог (Рем)</strong><br>Крестьянин знает, как выжать максимум из любого пойла. Совершая действие смешивания одной единицы алхимического компонента с порцией алкоголя, Крестьянин может сделать проверку навыка <strong>Грог</strong> со СЛ 14. При успехе, любой, кто выпьет этот алкоголь, должен пройти проверку Выносливости с СЛ, равной уровню навыка <strong>Грог + 12</strong> или он опьянен. Как только значение навыка <strong>Грог</strong> становится 5 и выше, последствия опьянения удваиваются.</td></tr>
<tr><td class="opt_content"><strong>Укус за Ухо (Тел)</strong><br>Когда крестьянина схватили или прижали к себе существо или человек, крестьянин может действием пройти проверку навыка <strong>Укуса Уха</strong> против Лвк x 3 цели. При успехе, он откусывает часть уха (или другую поверхностную часть тела) цели, немедленно освобождаясь от захвата, нанося 1d6 неизменяемого урона. Цель навсегда получает -1 к проверкам Харизмы и Соблазнения.</td></tr>
</table>
</div>
$ru$)
    ) AS raw_data_ru(num, title, description)
    UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
      (13, 'Peasant', $en$
<div class="ddlist_option">
<table class="profession_table"><tr>
<td><strong>Vigor:</strong> 0<br><br><strong>Magical Perks:</strong><br><strong class="section-title">None</strong></td>
<td><strong>Skills</strong><ul>
<li>[BODY] - Endurance</li>
<li>[BODY] - Physique</li>
<li>[CRA] - Crafting</li>
<li>[CRA] - First Aid</li>
<li>[DEX] - Athletics</li>
<li>[EMP] - Gambling</li>
<li>[INT] - Wilderness Survival</li>
<li>[REF] - Brawling</li>
<li>[REF] - Small Blades</li>
<li>[WILL] - Courage</li>
</ul></td>
<td><strong>Gear</strong><br><strong class="section-title">(Pick 5)</strong><ul>
<li>Beer</li><li>Another Beer</li><li>Cart</li><li>Cold Weather Clothing</li><li>Cooking Tools</li>
<li>Flint &amp; Steel</li><li>Gwent Deck</li><li>Holy Symbol</li><li>Pipe / Tobacco</li><li>Sack</li>
</ul><br><strong>Starting Coin</strong><ul><li>20 crowns x 2d6</li></ul></td>
</tr></table>

<h3>Defining Skill</h3>
<table class="main_skill"><tr><td class="header">Intolerance (WILL)</td></tr><tr><td class="opt_content">
Peasants are a fearful lot for good reason. When first encountering a sapient being with a Social Standing of Feared or Hated, they can roll <strong>Intolerance</strong> against DC = target EMPx3. On success, fear becomes rage and grants a bonus equal to their <strong>Intolerance</strong> value to <strong>Resist Coercion</strong> and <strong>Courage</strong> against that target for the rest of the encounter. The Peasant also gains a bonus to <strong>Leadership</strong> equal to half their <strong>Intolerance</strong> when rallying other peasants.
<br><br><strong>Intolerance &amp; Peasants:</strong> for this ability, any NPC without a Profession or a distinct non-peasant role (for example secret police or an Oxenfurt professor) counts as a peasant.
</td></tr></table>

<h3>Professional Skills</h3>
<table class="skills_branch_1">
<tr><td class="header">The Farmer</td></tr>
<tr><td class="opt_content"><strong>Harvest Time</strong><br>Knowing the proper time and way to harvest a crop is a skill that takes years to master. When foraging for plant-based alchemical components the peasant gains an extra number of units equal to half their <strong>Harvest Time</strong> value (Minimum 1).</td></tr>
<tr><td class="opt_content"><strong>Animal Whisper (EMP)</strong><br>By taking an action, the Peasant can roll an <strong>Animal Whisperer</strong> check against a DC equal to the animal's WILLx3, to convey commands and requests to any domesticated animal. If the check succeeds, the animal carries out these commands to the best of its ability.
<br><br><table border="1" cellpadding="4" cellspacing="0" class="table-small">
<tr><th>Unlisted Animals</th><th>DC</th></tr>
<tr><td>Bees</td><td>21</td></tr><tr><td>Chickens</td><td>15</td></tr><tr><td>Cows</td><td>12</td></tr>
<tr><td>Goats</td><td>18</td></tr><tr><td>Pigs</td><td>15</td></tr><tr><td>Rabbits</td><td>12</td></tr><tr><td>Sheep</td><td>9</td></tr>
</table></td></tr>
<tr><td class="opt_content"><strong>Farm Wisdom (CRA)</strong><br>While magic may not be a talent for everyone, there are some tricks that the layperson can learn to tip the scale of life in their favor. A Peasant can take one action and roll <strong>Farm Wisdom</strong> to perform one of the folk rituals in the sidebar. Each ritual has its own DC and requirements.
<br><br><table border="1" cellpadding="4" cellspacing="0" class="table-small">
<tr><th>Ritual</th><th>DC</th><th>Ingredients</th><th>Description</th><th>Effect</th></tr>
<tr><td>Blood Eraser</td><td>8</td><td>Aether x2, Vitriol x1</td><td>Mix ingredients into a wash</td><td>Erases blood stains from up to five cubic meters.</td></tr>
<tr><td>Discern Weather</td><td>10</td><td>—</td><td>Check the sky and watch animal reactions</td><td>Predicts weather for the next 24 hours.</td></tr>
<tr><td>Herbal Crown</td><td>12</td><td>Plant-based alch. materials x3</td><td>Weave a crown and wear it</td><td>Perfect memory for 24 hours.</td></tr>
<tr><td>Vermin Circle</td><td>14</td><td>Any alch. substance x5</td><td>Spread substance in a circle (20m radius)</td><td>Insectoids &amp; Beasts must pass Endurance vs your Farm Wisdom roll to enter a 20m circle.</td></tr>
<tr><td>Nightmare Killer</td><td>16</td><td>—</td><td>Turn clothes inside out, wear hat backwards, speak a rhyme</td><td>No nightmares (mundane or magical) that night.</td></tr>
<tr><td>Black Magic Revealer</td><td>18</td><td>Wood x1</td><td>Carve symbols on a piece of wood</td><td>One-use totem blackens near cursed/hexed people.</td></tr>
<tr><td>Good Luck Charm</td><td>20</td><td>Feathers x1, different alch. substances x3</td><td>Craft a charm from ingredients</td><td>One-use LUCK bonus equal to Farm Wisdom; does not regenerate and does not stack.</td></tr>
</table></td></tr>
</table>

<table class="skills_branch_2">
<tr><td class="header">The Cook</td></tr>
<tr><td class="opt_content"><strong>Butchery (CRA)</strong><br>When a Peasant loots a monster or animal with a physical form, they can roll a <strong>Butchery</strong> roll at a DC based on the beasts complexity. If they succeed, they are able to gain the maximum number of units of one organic loot item from the animal. This roll can be made multiple times on a single corpse but the peasant cannot make two attempts on the same part of the beast.
<br><br><table border="1" cellpadding="4" cellspacing="0" class="table-small">
<tr><th>Beast Complexity</th><th>DC</th></tr>
<tr><td>Simple</td><td>12</td></tr><tr><td>Complex</td><td>16</td></tr><tr><td>Difficult</td><td>20</td></tr>
</table></td></tr>
<tr><td class="opt_content"><strong>Cure All (CRA)</strong><br>By taking 10 minutes and using one unit of three different types of alchemical component, the Peasant can create a folk cure all. This concoction has a percentage chance of curing the person who consumes it of the <strong>poison</strong>, <strong>intoxication</strong>, and <strong>nausea</strong> conditions. The percentage is equal to the Peasant's <strong>Cure All</strong> value times 5%. This <strong>Cure All</strong> lasts for 24 hours before going bad. Once used, this cure all is consumed.</td></tr>
<tr><td class="opt_content"><strong>Ma's Stew (CRA)</strong><br>Once per day, if a Peasant has access to cooking tools and the ingredients required, they can spend 1 hour to create a stew from an old family recipe. This stew is large enough to feed 6 people and its effects are based on what basic ingredients are added (See the table in the sidebar). Effects conferred by the stew last for a full 24 hours.
<br><br><table border="1" cellpadding="4" cellspacing="0" class="table-small">
<tr><th>Recipe</th><th>Ingredients</th><th>Effect</th></tr>
<tr><td>Harvest Medley</td><td>Raw Meat x2, Beer x3, Fool's Parsely x3, Berbercane Fruit x4</td><td>Immunity to fear and natural SP = 1/3 Ma's Stew.</td></tr>
<tr><td>Ma's Gut Cleanser</td><td>Crow'e Eye x5, Hellebore Petals x3, Bryonia x2, Fool's Parsley x2</td><td>Nausea until Endurance vs Ma's Stew check succeeds.</td></tr>
<tr><td>Special Broth</td><td>Beast Bones x4, Dog Tallow x2, Mistletoe x3, Han Fiber x3</td><td>Critical wound healing days reduced by half Ma's Stew (min 1 day).</td></tr>
<tr><td>Springtime Stew</td><td>Balisse Fruit x3, Raw Meat x2, Sewant Mushrooms x4, Honey Suckle x3</td><td>Seduction bonus = 1/2 Ma's Stew, Stamina bonus = 3x Ma's Stew.</td></tr>
<tr><td>Troll Brew</td><td>Barley x3, Scleroderm x4, Sulfur x2, Raw Meat x3</td><td>Poison removal bonus = 1/2 Ma's Stew and poison damage resistance.</td></tr>
<tr><td>Winter Stew</td><td>Barley x5, Beast Bones x2, Scleroderm x3, Allspice Rooth x2</td><td>Immunity to Freeze and extra icy-survival hours = Ma's Stew.</td></tr>
</table></td></tr>
</table>

<table class="skills_branch_3">
<tr><td class="header">The Laborer</td></tr>
<tr><td class="opt_content"><strong>Ditch Digger</strong><br>Years of manual labor have strengthened the Peasant's body and taught them technique to make even the most grueling labor manageable. The Peasant adds double their <strong>Ditch Digger</strong> value to their ENC. Also, when making Physique or Endurance rolls to perform manual labor, the Peasant can add half their <strong>Ditch Digger</strong> value.</td></tr>
<tr><td class="opt_content"><strong>Grog (CRA)</strong><br>A peasant knows how to get the most out of any brew. By taking an action to mix one unit of an alchemical component with a serving of alcohol, a Peasant can make a <strong>Grog</strong> roll at a DC of 14. If the Peasant succeeds anyone who drinks the alcohol must make an Endurance check at a DC equal to the peasant's <strong>Grog</strong> value plus 12 or become intoxicated. Once the peasant has a <strong>Grog</strong> value of 5, the effects of the intoxication condition are doubled.</td></tr>
<tr><td class="opt_content"><strong>Bite The Ear (BODY)</strong><br>When grappled or pinned by a creature or person, the Peasant can take an action to make a <strong>Bite the Ear</strong> roll against the target's DEXx3. If the peasant succeeds they bite off part of the ear (or other superficial body part) of the target, breaking the grapple/pin immediately, dealing 1d6 unmodified damage, and giving the target a permanent -1 to Charisma &amp; Seduction checks.</td></tr>
</table>
</div>
$en$)
    ) AS raw_data_en(num, title, description)
)
, ins_title AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.title') AS id
       , meta.entity, 'title', raw_data.lang, raw_data.title
    FROM raw_data
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO UPDATE
  SET text = EXCLUDED.text
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
       ck_id('witcher_cc.rules.wcc_profession.peasant') AS visible_ru_ru_id,
       jsonb_build_object(
           'title', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.title')::text),
           'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.description')::text)
       ) AS metadata
FROM raw_data
CROSS JOIN meta
ON CONFLICT (an_id) DO NOTHING;

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_profession_shop.bundle.peasant_another_beer') AS id
     , 'questions' AS entity
     , 'metadata' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          ('ru', 'Ещё одно Пиво'),
          ('en', 'Another Beer')
       ) AS v(lang, text)
ON CONFLICT (id, lang) DO NOTHING;

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_profession_shop.bundle.peasant_pipe_tobacco') AS id
     , 'questions' AS entity
     , 'metadata' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          ('ru', 'Трубка с Табаком'),
          ('en', 'Pipe / Tobacco')
       ) AS v(lang, text)
ON CONFLICT (id, lang) DO NOTHING;

INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o13' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.professional_gear_options'),
      jsonb_build_object(
        'tokens', 5,
        'items', jsonb_build_array('T026', 'T011', 'T006', 'T106', 'T082', 'T066', 'T080', 'T015'),
        'bundles', jsonb_build_array(
          jsonb_build_object(
            'bundleId', 'peasant_another_beer',
            'displayName', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_profession_shop.bundle.peasant_another_beer')::text),
            'items', jsonb_build_array(
              jsonb_build_object('sourceId', 'general_gear', 'itemId', 'T026', 'quantity', 1)
            )
          ),
          jsonb_build_object(
            'bundleId', 'peasant_pipe_tobacco',
            'displayName', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_profession_shop.bundle.peasant_pipe_tobacco')::text),
            'items', jsonb_build_array(
              jsonb_build_object('sourceId', 'general_gear', 'itemId', 'T088', 'quantity', 1),
              jsonb_build_object('sourceId', 'general_gear', 'itemId', 'T089', 'quantity', 1)
            )
          )
        )
      )
    )
  ) AS body;

INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o13' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.money.crowns'),
      jsonb_build_object(
        '*',
        jsonb_build_array(
          20,
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

WITH skill_mapping (skill_name) AS ( VALUES
    ('athletics'),
    ('brawling'),
    ('courage'),
    ('crafting'),
    ('endurance'),
    ('first_aid'),
    ('gambling'),
    ('physique'),
    ('small_blades'),
    ('wilderness_survival')
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o13' AS an_an_id,
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.initial'),
      sm.skill_name
    )
  ) AS body
FROM skill_mapping sm;

WITH prof_skill_mapping (skill_id, branch_number, professional_number) AS ( VALUES
  ('harvest_time', 1, 1),
  ('animal_whisperer', 1, 2),
  ('farm_wisdom', 1, 3),
  ('butchery', 2, 1),
  ('cure_all', 2, 2),
  ('mas_stew', 2, 3),
  ('ditch_digger', 3, 1),
  ('grog', 3, 2),
  ('bite_the_ear', 3, 3)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o13' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.professional.skill_' || sm.branch_number || '_' || sm.professional_number),
      jsonb_build_object('id', sm.skill_id, 'name', ck_id('witcher_cc.wcc_skills.' || sm.skill_id || '.name')::text)
    )
  ) AS body
FROM prof_skill_mapping sm;

INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o13' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.professional.branches'),
      jsonb_build_array(
        ck_id('witcher_cc.wcc_skills.branch.peasant.1.name')::text,
        ck_id('witcher_cc.wcc_skills.branch.peasant.2.name')::text,
        ck_id('witcher_cc.wcc_skills.branch.peasant.3.name')::text
      )
    )
  ) AS body;

INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o13' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.defining'),
      jsonb_build_object('id', 'intolerance', 'name', ck_id('witcher_cc.wcc_skills.intolerance.name')::text)
    )
  ) AS body;

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_profession' AS qu_id
                , 'character' AS entity)
, ins_profession AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o13' ||'.'|| meta.entity ||'.'|| 'profession') AS id
       , meta.entity, 'profession', v.lang, v.text
    FROM (VALUES
            ('ru', 'Крестьянин'),
            ('en', 'Peasant')
         ) AS v(lang, text)
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o13' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.profession'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o13' ||'.'|| meta.entity ||'.'|| 'profession')::text)
    )
  ) AS body
FROM meta
UNION ALL
SELECT
  'character' AS scope,
  'wcc_profession_o13' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.logicFields.profession'),
      'Peasant'
    )
  ) AS body;
