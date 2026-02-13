\echo '005_profession_10_druid.sql'
-- Вариант ответа: Друид

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_profession' AS qu_id
                , 'answer_options' AS entity)
-- Базовые правила видимости (профессия "Друид" только для расы Human или Elf, и включен DLC exp_toc)
, ensure_rules AS (
  -- гарантируем, что is_dlc_exp_toc_enabled существует
  INSERT INTO rules (ru_id, name, body)
  VALUES
    (ck_id('witcher_cc.rules.is_dlc_exp_toc_enabled'), 'is_dlc_exp_toc_enabled', '{"in":["exp_toc",{"var":["dlcs",[]]}]}'::jsonb)
  ON CONFLICT (ru_id) DO NOTHING
  RETURNING ru_id
)
, rule_parts AS (
  SELECT
    (SELECT r.body FROM rules r WHERE r.name = 'is_human' ORDER BY r.ru_id LIMIT 1) AS is_human_expr,
    (SELECT r.body FROM rules r WHERE r.name = 'is_elf' ORDER BY r.ru_id LIMIT 1) AS is_elf_expr,
    (SELECT r.body FROM rules r WHERE r.ru_id = ck_id('witcher_cc.rules.is_dlc_exp_toc_enabled') LIMIT 1) AS exp_toc_expr
)
, vis_rules AS (
  INSERT INTO rules (ru_id, name, body)
  SELECT
    ck_id('witcher_cc.rules.wcc_profession.druid') AS ru_id,
    'wcc_profession_druid' AS name,
    jsonb_build_object(
      'and',
      jsonb_build_array(
        jsonb_build_object(
          'or',
          jsonb_build_array(
            rule_parts.is_human_expr,
            rule_parts.is_elf_expr
          )
        ),
        rule_parts.exp_toc_expr
      )
    ) AS body
  FROM rule_parts
  ON CONFLICT (ru_id) DO NOTHING
  RETURNING ru_id
)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
            ( 10, 'Друид', '
<div class="ddlist_option">
<table class="profession_table">
    <tr>
        <td>
            <strong>Энергия: </strong>2<br><br>
            <strong>Магические способности</strong>
            <ul>
                <li>2 инвокации новичка</li>
                <li>2 ритуала новичка</li>
                <li>2 порчи с низкой опасностью</li>
            </ul>
            <br>
            <strong>Социальный статус</strong>:<br>
            Друиды считаются равными на Скеллиге<br>и в сельских общинах, но их терпят все<br>остальные группы и ненавидят и опасаются<br>те, кто ненавидит магию.
        </td>
        <td>
            <strong>Навыки</strong>
            <ul>
                <li>[Интеллект] - Выживание в дикой природе</li>
                <li>[Интеллект] - Внимание</li>
                <li>[Интеллект] - Монстрология</li>
                <li>[Воля] - Наведение порчи</li>
                <li>[Ремесло] - Первая помощь</li>
                <li>[Интеллект] - Передача знаний</li>
                <li>[Воля] - Проведение ритуалов</li>
                <li>[Воля] - Сотворение заклинаний</li>
                <li>[Телосложение] - Стойкость</li>
                <li>[Эмпатия] - Убеждение</li>
            </ul>
        </td>
        <td>
            <strong>Снаряжение</strong><br>
            <strong class="section-title">(выберите 5)</strong>
            <ul>
                <li>Ингредиенты общей стоимостью 100 крон</li>
                <li>Нюхательная соль ×2</li>
                <li>Обезболивающие травы ×3</li>
                <li>Посох</li>
                <li>Походная постель</li>
                <li>Поясная сумка</li>
                <li>Свечи ×5</li>
                <li>Друидский серп</li>
                <li>Тёплая одежда</li>
                <li>Трубка и Табак</li>
            </ul>
            <br><br><strong>Деньги</strong>
            <ul>
                <li>75 крон × 2d6</li>
            </ul>
        </td>
    </tr>
</table>

<h3>Определяющий навык</h3>
<table class="main_skill">
    <tr>
        <td class="header">Обряд дуба и омелы (Инт)</td>
    </tr>
    <tr>
        <td class="opt_content">
            Друид очень быстро учится собирать растения, обладающие магической силой, и превращать их в мощную основу своей магии, которая связывает их с землёй вокруг них. Друид может потратить день и совершить проверку <strong>Обряда дуба и омелы</strong> со СЛ, специфичной для области, в которой он оказался, чтобы собрать необходимые ингредиенты. В случае успеха друид создаёт посох, который может использовать только друид.
            <br><br>
            Этот посох действует точно так же, как посох (Основная книга, стр. 74), но его значение фокусировки увеличивается по мере того, как они улучшают значение <strong>Обряда дуба и омелы</strong>. Значение фокусировки равно 1 на уровне 1 и увеличивается на 1 за каждые 2 очка сверх первого вплоть до максимума 4 на уровне 7. На уровне 9 посох получает эффект <strong>улучшенное фокусирующее</strong>.
            <br><br>
            Кроме того, пока друид держит свой посох, он получает следующие преимущества в зависимости от уровня <strong>Обряда дуба и омелы</strong>. На уровне 2 друид игнорирует все штрафы окружающей среды в заросшей или болотистой местности. На уровне 4 друид игнорирует штрафы за снежные и ледяные условия. На уровне 6 друид игнорирует штрафы за сильную жару. На уровне 8 друид игнорирует все штрафы от пребывания под водой. На уровне 10 друид может сделать бросок для создания нового посоха, тратя лишь действие полного хода, а не целый день. СЛ для создания посоха — 14 в лесу, 16 в болотистой местности, 18 в горных районах и 20 в море.
        </td>
    </tr>
</table>

<h3>Профессиональные навыки</h3>

<table class="skills_branch_1">
    <tr>
        <td class="header">Посвященный</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Единение с природой</strong><br>
            Друид может укрепить свою гармонию с природой, получая 1 очко порога Энергии за каждый уровень <strong>Единения с природой</strong> вплоть до уровня 9. На 10-м уровне <strong>Единения с природой</strong> порог Энергии друида повышается на 5, доводя его суммарно до 16. <strong>Единение с природой</strong> можно тренировать, как и любой другой навык.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Знаки природы (Инт)</strong><br>
            Находясь среди природы, друид может сделать проверку способности <strong>Знаки природы</strong> со СЛ определяемой ведущим. При успехе друид по знакам узнает, кто и что здесь делал за последнюю неделю. <strong>Знаки природы</strong> показывают не только локальную информацию и не позволяют выслеживать, но дают очень подробное описание того, что произошло в этом районе.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Союзник природы (Воля)</strong><br>
            Друид добавляет способность <strong>Союзник природы</strong> к любым проверкам Выживания в дикой природе для обращения с животными. Друид также может сдружиться с животным, потратив полный раунд и совершив проверку <strong>Союзника природы</strong> с СЛ установленной ведущим. Они могут сделать одного Зверя или иное животное их союзником на количество часов, равных их значению способности <strong>Союзник природы</strong>. Данная способность не действует на чудовищ.
        </td>
    </tr>
</table>

<table class="skills_branch_2">
    <tr>
        <td class="header">Таинственный мудрец</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Хранитель знаний</strong><br>
            Частью посвящения в круг является запоминание множества знаний, которые могут пригодится друиду. Он может пройти проверку способности <strong>Хранитель знаний</strong> вместо любых проверок Выживания, Монстрологии, Понимании людей или Образования.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Кровь и кости (Воля)</strong><br>
            Бросив кости в чашу, наполненную кровью человека, друид может изменить судьбу этого человека. Друид делает проверку способности <strong>Кровь и кости</strong> со СЛ 10 + значение Воли цели. В случае успеха цель может добавить половину значения способности <strong>Кровь и кости</strong> друида к одной проверке, сделанной до следующего восхода солнца. При провале цель не сможет использовать эту способность в течение 1 недели. Эту способность можно применить к одной цели только один раз за сессию.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Облик зверя</strong><br>
            Познание древних ритуалов позволяет друиду включать в свое тело аспекты животных, превращаясь в гибридную форму без каких-либо действий. За каждые 2 уровня способности <strong>Облик зверя</strong>, друид может добавить новый животный аспект к своей гибридной форме. Кроме того, находясь в своей гибридной форме, друид может говорить с животными того типа, которого они включили, а также получить репутацию ненависти и опасения.
            <br><br>
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr><th>Зверь</th><th>Эффект</th></tr>
                <tr><td>Вепрь</td><td>Кожа друида утолщается и покрывается щетиной. Друид получает +3 ПБ во всех частях тела.</td></tr>
                <tr><td>Медведь</td><td>На руках друида вырастают когти. Когти наносят рубящий урон 4d6 и имеют 10 надежности. При повреждении эти когти отрастают со скоростью 1 очко в день.</td></tr>
                <tr><td>Волк</td><td>Уши друида становятся острыми, а рот и нос превращаются в морду. Он получает преимущества усиленных чувств, давая +1 к Вниманию и позволяя ему выслеживать вещи ориентируясь по запаху.</td></tr>
                <tr><td>Пантера</td><td>Ноги друида становятся узкими и пушистыми, что позволяет им прыгать в два раза больше, чем расстояние прыжка, используя действие движения с места. Этот прыжок может быть сделан горизонтально или вертикально.</td></tr>
                <tr><td>Змей</td><td>Друид отращивает ядовитые клыки. Он получает атаку укуса, которая наносит 3d6 урона и имеет 100% шанс вызвать эффект отравления.</td></tr>
                <tr><td>Сова</td><td>Глаза друида становятся большими, а вокруг лица вырастают перья. Он получает превосходное ночное зрение.</td></tr>
                <tr><td>Ворон</td><td>Тело друида покрывается черными перьями, а его разум обостряется, давая +1 к Инт, что может поднять его Инт выше 10. Кроме того, каждый раз, когда он применяет смену позиции, он может переместиться на полную скорость, а не половину.</td></tr>
            </table>
        </td>
    </tr>
</table>

<table class="skills_branch_3">
    <tr>
        <td class="header">Воинствующий</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Целитель зверей (Рем)</strong><br>
            Часто работая с животными для защиты природы, друид может лечить тяжелые раны своих звериных компаньонов. Друид может пройти проверку способности <strong>Целитель зверей</strong>, чтобы вылечить критические раны, нанесенные зверям. Этот бросок работает точно так же, как способность медика <strong>Лечащее прикосновение</strong>.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Священная роща (Воля)</strong><br>
            Друид может превратить участок природы в священную рощу. Это занимает 1 час и охватывает область радиусом 20 м. Друид берёт значение своей проверки способности <strong>Священная роща</strong> и использует как очки, чтобы добавить защиту своей священной роще. Друид и все, на кого он укажет, не восприимчивы к этой защите. Эта роща существует в течение 3 месяцев, и друид может поддерживать количество рощ, равное значению его <strong>Священной рощи</strong>.
            <br><br>
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr><th>Защита</th><th>Цена</th></tr>
                <tr><td><strong>Заросшая среда</strong><br>Растения в этом районе бесконтрольно разрастаются, налагая -2 на проверки Уклонения/Изворотливости и Атлетики.</td><td>2</td></tr>
                <tr><td><strong>Потерянные</strong><br>Волшебный туман окутывает рощу, каждый кто входит в нее, должен пройти проверку Сопротивление магии с СЛ 16, чтобы войти в эту область. Провалившиеся цели разворачиваются и немедленно покидают рощу.</td><td>10</td></tr>
                <tr><td><strong>Отравленный урожай</strong><br>Смертельная магия пропитывает растения рощи, в результате чего культуры, выращенные в этом районе, вызывают эффект отравления при употреблении в пищу.</td><td>6</td></tr>
                <tr><td><strong>Чудесный урожай</strong><br>Растения рощи дают обильный урожай, удваивая количество растительных ингредиентов, собранных с каждой проверки сбора.</td><td>4</td></tr>
                <tr><td><strong>Шипы</strong><br>Стена колючих лоз прорастает на краю рощи, каждый кто проходит через нее, должен пройти проверку Атлетики с СЛ 16 или получить состояние Кровотечения.</td><td>10</td></tr>
            </table>
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Страж рощи (Воля)</strong><br>
            Используя древний ритуал, друид может усилить животное или зверя. Потратив один полный раунд и пройдя проверку способности <strong>Страж рощи</strong> со СЛ 10 + Тел существа, существо увеличивается в два раза, его Тел увеличивается на 5 и получает бонус +5 к урону. Этот бонус также влияет на производную статистику существа. Существо также становится очень агрессивным по отношению к врагам друида. Это длится 24 часа, и на это время порог Энергии друида снижается на 5.
        </td>
    </tr>
</table>
</div>
'
         )) AS raw_data_ru(num, title, description)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
            ( 10, 'Druid', '
<div class="ddlist_option">
<table class="profession_table">
    <tr>
        <td>
            <strong>Vigor: </strong>2<br><br>
            <strong>Magical Perks</strong>
            <ul>
                <li>2 Novice Invocations</li>
                <li>2 Novice Rituals</li>
                <li>2 Low Danger Hexes</li>
            </ul>
            <br>
            <strong>Social Status</strong>:<br>
            Druids are considered equals in Skellige<br>and in rural communities, but all other<br>groups merely tolerate them, and those<br>who hate magic both hate and fear them.
        </td>
        <td>
            <strong>Skills</strong>
            <ul>
                <li>[BODY] - Endurance</li>
                <li>[CRA] - First Aid</li>
                <li>[EMP] - Persuasion</li>
                <li>[INT] - Awareness</li>
                <li>[INT] - Monster Lore</li>
                <li>[INT] - Teaching</li>
                <li>[INT] - Wilderness Survival</li>
                <li>[WILL] - Hex Weaving</li>
                <li>[WILL] - Ritual Crafting</li>
                <li>[WILL] - Spell Casting</li>
            </ul>
        </td>
        <td>
            <strong>Gear</strong><br>
            <strong class="section-title">(Pick 5)</strong>
            <ul>
                <li>100 crowns of ingredients</li>
                <li>Smelling salts ×2</li>
                <li>Numbing herbs ×3</li>
                <li>Staff</li>
                <li>Bedroll</li>
                <li>Belt pouch</li>
                <li>Candles ×5</li>
                <li>Druid''s sickle</li>
                <li>Cold Weather Clothing</li>
                <li>Pipe and Tobacco</li>
            </ul>
            <br><br><strong>Money</strong>
            <ul>
                <li>75 crowns × 2d6</li>
            </ul>
        </td>
    </tr>
</table>

<h3>Defining Skill</h3>
<table class="main_skill">
    <tr>
        <td class="header">Rite of Oak and Mistletoe (INT)</td>
    </tr>
    <tr>
        <td class="opt_content">
            A Druid learns very quickly how to harvest magically potent plants and turn them into a powerful focus for their magic which connects them to the land around them. A Druid can take a day and make a Rite of Oak and Mistletoe roll against a DC specific to the area in which they find themselves to harvest the necessary ingredients. If successful, the Druid creates a Staff which works only for the Druid.
            <br><br>
            This staff functions exactly as a Staff (Witcher Core Rule Book, pg. 74) but its Focus value rises as they improve their Rite of Oak &amp; Mistletoe value. The Focus value begins at 1 at level 1 and rises by 1 every 2 levels to a maximum of 4 at level 7. At level 9, the Staff gains the Greater Focus Effect.
            <br><br>
            Additionally, while the Druid is carrying their staff, they gain the following benefits based on their Rite of Oak &amp; Mistletoe value. At level 2, the Druid ignores all environmental penalties in overgrown or swampy terrain. At level 4, the Druid ignores the penalties for snow and ice conditions. At level 6, the Druid ignores the penalties for extreme heat conditions. At level 8, the Druid ignores all penalties from being underwater. At level 10, the Druid can roll to create a new staff by taking a full round action rather than 1 day. The DCs to create a staff are 14 when in a forest, 16 when in swampy areas, 18 when in mountainous regions, and 20 when at sea.
        </td>
    </tr>
</table>

<h3>Professional Skills</h3>

<table class="skills_branch_1">
    <tr>
        <td class="header">Initiate</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Nature Attunement</strong><br>
            A Druid can become more in tune with nature, gaining 1 point of Vigor threshold per level in Nature Attunement up to level 9. At the 10th level in Nature Attunement the Druid''s Vigor Threshold rises by 5 to a total of 16. Nature Attunement can be trained like any other skill.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Read Nature (INT)</strong><br>
            When in a purely natural environment, a Druid can roll Read Nature at a DC set by the GM. On a success, the Druid reads the signs around them to learn everything that passed through that area within the last week and what each creature did in the area. Read Nature renders a very localized picture and cannot track things but gives a very detailed description of what happened in the area.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Animal Compact (WILL)</strong><br>
            A Druid adds their Animal Compact value to any Wilderness Survival rolls they make to handle animals. The Druid can also make a compact with an animal. By taking a full round and rolling an Animal Compact check at a DC set by the GM, they can make one Beast or animal their ally for a number of hours equal to their Animal Compact value. Monsters are unaffected.
        </td>
    </tr>
</table>

<table class="skills_branch_2">
    <tr>
        <td class="header">Mystic Sage</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Lore Keeper</strong><br>
            Part of the initiation into a Circle is to memorize a plethora of topics that can come in handy to the Druid. They can roll their Lore Keeper Ability in place of any Wilderness Survival, Monster Lore, Human Perception, or Education checks.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Blood and Bones (WILL)</strong><br>
            By casting bones in a bowl filled with blood drawn from a person, the Druid can alter the fate of that person. The Druid rolls Blood and Bones against a DC:10 + the target''s WILL. On a success, the target can add half the Druid''s Blood and Bones value to one check made before the next sunrise. On a failure, the target cannot benefit from this ability for 1 week. A single target can only benefit from this ability once per session.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Bestial Form</strong><br>
            Unlocking ancient rituals allows the Druid to incorporate animal aspects into their body, transforming into a hybrid form without taking an action. For each 2 levels the Druid has in Bestial Form, they can add a new animalistic aspect to their hybrid form. Additionally, while in their hybrid form, the Druid can speak with animals of a type they have incorporated, and become Feared &amp; Hated by non-druids.
            <br><br>
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr><th>Animal</th><th>Effect</th></tr>
                <tr><td>Boar</td><td>The Druid''s skin thickens and grows bristles. The Druid gains +3 SP on all body locations.</td></tr>
                <tr><td>Bear</td><td>The Druid''s hands grow claws. The claws deal 4d6 slashing damage and have 10 REL. If damaged, these claws regrow at a rate of 1 REL per day.</td></tr>
                <tr><td>Wolf</td><td>The Druid''s ears grow to a point and their mouth and nose change into a snout. They gain the benefits of enhanced senses, granting a +1 to Awareness and allowing them to track things by scent alone.</td></tr>
                <tr><td>Panther</td><td>The Druid''s legs become digitigrade and furry allowing them to leap twice their Leap distance by using your move action from a standing start. This leap can be made horizontally or vertically.</td></tr>
                <tr><td>Serpent</td><td>The Druid grows poisonous fangs. They gain a bite attack that deals 3d6 damage and has a 100% chance to inflict the Poison Effect.</td></tr>
                <tr><td>Owl</td><td>The Druid''s eyes grow large and feathers sprout around their face. They gain Superior Night Vision.</td></tr>
                <tr><td>Crow</td><td>The Druid''s body sprouts black feathers and their mind sharpens granting a +1 to INT which can raise their INT above 10. Additionally, whenever they Reposition they can move their full SPD rather than half.</td></tr>
            </table>
        </td>
    </tr>
</table>

<table class="skills_branch_3">
    <tr>
        <td class="header">Militant</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Beast Healer (CRA)</strong><br>
            Working often with animals in defense of nature, a Druid can tend to grievous wounds in their beastly companions. A Druid can roll Beast Healer to treat Critical Wounds inflicted on Beasts. This roll works exactly like the Doctor''s Healing Hands ability.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Sacred Grove (WILL)</strong><br>
            A Druid can turn an area of nature into a sacred grove. This takes 1 hour, and covers an area with a 20m radius. The Druid takes the value of their Sacred Grove check and uses those points to add protections to their sacred grove. The Druid and anyone they specify are immune to these protections. This grove lasts for 3 months and the Druid can maintain a number of groves equal to their Sacred Grove value.
            <br><br>
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr><th>Protection</th><th>Cost</th></tr>
                <tr><td><strong>Overgrown Environment</strong><br>The plants of the area grow wildly out of control, imposing a -2 to Dodge/Escape and Athletics checks.</td><td>2</td></tr>
                <tr><td><strong>Lost</strong><br>A magical fog settle around the grove which forces anyone entering it to make a Resist Magic DC:16 to enter the area. Targets who fail are turned around and immediately exit the grove.</td><td>10</td></tr>
                <tr><td><strong>Poisoned Harvest</strong><br>Deadly magic suffuses the plants of the grove causing crops grown in the area inflict the poison effect when eaten.</td><td>6</td></tr>
                <tr><td><strong>Miracle Harvest</strong><br>The plants of the grove grow a bountiful harvest doubling the number of plant-based ingredients gathered from each gathering check.</td><td>4</td></tr>
                <tr><td><strong>Thorns</strong><br>A wall of thorny vines sprouts at the edge of the grove and anything that passes through it must make a DC:16 Athletics check or suffer the Bleeding condition.</td><td>10</td></tr>
            </table>
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Grove Guardian (WILL)</strong><br>
            By using an ancient ritual, the Druid can empower an animal or beast. By taking one full round and rolling Grove Guardian against a DC:10 + the creature''s BODY, the creature grows to twice its size, its BODY increases by 5, and gains a +5 bonus to damage. This bonus affects the creature''s Derived Statistics as well. The creature also becomes highly aggressive to enemies of the Druid. This lasts for 24 hours and during that time the Druid''s Vigor threshold is reduced by 5.
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
       ck_id('witcher_cc.rules.wcc_profession.druid') AS visible_ru_ru_id,
       jsonb_build_object(
           'title', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.title')::text),
           'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.description')::text)
       ) AS metadata
FROM raw_data
CROSS JOIN meta
ON CONFLICT (an_id) DO NOTHING;

-- Druid (pick 5)
-- 100 crowns of ingredients - option item T900 (grants budget(100) for ingredients sources)
-- Smelling salts ×2 - P052 x2
-- Numbing herbs ×3 - P053 x3
-- Staff - W157
-- Bedroll - T068
-- Belt pouch - T012
-- Candles ×5 - I274 x5
-- Druid''s sickle - W039
-- Cold Weather Clothing - T006
-- Pipe and Tobacco - T088 + T089

-- Эффекты: заполнение professional_gear_options
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_profession_shop.bundle.druid_smelling_salts') AS id
     , 'questions' AS entity
     , 'metadata' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          ('ru', 'Нюхательная соль ×2'),
          ('en', 'Smelling salts ×2')
       ) AS v(lang, text)
ON CONFLICT (id, lang) DO NOTHING;

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_profession_shop.bundle.druid_numbing_herbs') AS id
     , 'questions' AS entity
     , 'metadata' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          ('ru', 'Обезболивающие травы ×3'),
          ('en', 'Numbing herbs ×3')
       ) AS v(lang, text)
ON CONFLICT (id, lang) DO NOTHING;

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_profession_shop.bundle.druid_candles') AS id
     , 'questions' AS entity
     , 'metadata' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          ('ru', 'Свечи ×5'),
          ('en', 'Candles ×5')
       ) AS v(lang, text)
ON CONFLICT (id, lang) DO NOTHING;

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_profession_shop.bundle.druid_pipe_tobacco') AS id
     , 'questions' AS entity
     , 'metadata' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          ('ru', 'Трубка и Табак'),
          ('en', 'Pipe and Tobacco')
       ) AS v(lang, text)
ON CONFLICT (id, lang) DO NOTHING;

INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o10' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.professional_gear_options'),
      jsonb_build_object(
        'tokens', 5,
        'items', jsonb_build_array('T900', 'W157', 'T068', 'T012', 'W039', 'T006'),
        'bundles', jsonb_build_array(
          jsonb_build_object(
            'bundleId', 'druid_smelling_salts',
            'displayName', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_profession_shop.bundle.druid_smelling_salts')::text),
            'items', jsonb_build_array(
              jsonb_build_object(
                'sourceId', 'potions',
                'itemId', 'P052',
                'quantity', 2
              )
            )
          ),
          jsonb_build_object(
            'bundleId', 'druid_numbing_herbs',
            'displayName', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_profession_shop.bundle.druid_numbing_herbs')::text),
            'items', jsonb_build_array(
              jsonb_build_object(
                'sourceId', 'potions',
                'itemId', 'P053',
                'quantity', 3
              )
            )
          ),
          jsonb_build_object(
            'bundleId', 'druid_candles',
            'displayName', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_profession_shop.bundle.druid_candles')::text),
            'items', jsonb_build_array(
              jsonb_build_object(
                'sourceId', 'ingredients_craft',
                'itemId', 'I274',
                'quantity', 5
              )
            )
          ),
          jsonb_build_object(
            'bundleId', 'druid_pipe_tobacco',
            'displayName', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_profession_shop.bundle.druid_pipe_tobacco')::text),
            'items', jsonb_build_array(
              jsonb_build_object('sourceId', 'general_gear', 'itemId', 'T088', 'quantity', 1),
              jsonb_build_object('sourceId', 'general_gear', 'itemId', 'T089', 'quantity', 1)
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
  'wcc_profession_o10' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.money.crowns'),
      jsonb_build_object(
        '*',
        jsonb_build_array(
          75,
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

-- Эффекты: жетоны для магии (2 инвокации новичка, 2 ритуала новичка, 2 порчи с низкой опасностью)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o10' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.professional_gear_options.novice_invocation_tokens'),
      2
    )
  ) AS body;

INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o10' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.professional_gear_options.novice_rituals_tokens'),
      2
    )
  ) AS body;

INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o10' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.professional_gear_options.novice_hexes_tokens'),
      2
    )
  ) AS body;

-- Эффекты: добавление начальных навыков в characterRaw.skills.initial[]
WITH skill_mapping (skill_name) AS ( VALUES
    ('wilderness_survival'),   -- Выживание в дикой природе
    ('awareness'),             -- Внимание
    ('monster_lore'),          -- Монстрология
    ('hex_weaving'),           -- Наведение порчи
    ('first_aid'),             -- Первая помощь
    ('teaching'),              -- Передача знаний
    ('ritual_crafting'),       -- Проведение ритуалов
    ('spell_casting'),         -- Сотворение заклинаний
    ('endurance'),             -- Стойкость
    ('persuasion')             -- Убеждение
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o10' AS an_an_id,
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.initial'),
      sm.skill_name
    )
  ) AS body
FROM skill_mapping sm;

-- Эффекты: добавление профессиональных навыков в characterRaw.skills.professional (skill_<ветка>_<позиция> -> { name: "<skill_id>" })
WITH prof_skill_mapping (skill_id, branch_number, professional_number) AS ( VALUES
  ('nature_attunement', 1, 1),
  ('read_nature', 1, 2),
  ('animal_compact', 1, 3),
  ('lore_keeper', 2, 1),
  ('blood_and_bones', 2, 2),
  ('bestial_form', 2, 3),
  ('beast_healer', 3, 1),
  ('sacred_grove', 3, 2),
  ('grove_guardian', 3, 3)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o10' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.professional.skill_' || sm.branch_number || '_' || sm.professional_number),
      jsonb_build_object('id', sm.skill_id, 'name', ck_id('witcher_cc.wcc_skills.' || sm.skill_id || '.name')::text)
    )
  ) AS body
FROM prof_skill_mapping sm;

-- Эффекты: массив UUID названий веток professional.branches[] (порядок: ветка 1, 2, 3)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o10' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.professional.branches'),
      jsonb_build_array(
        ck_id('witcher_cc.wcc_skills.branch.посвященный.name')::text,
        ck_id('witcher_cc.wcc_skills.branch.таинственный_мудрец.name')::text,
        ck_id('witcher_cc.wcc_skills.branch.воинствующий.name')::text
      )
    )
  ) AS body;

-- Эффекты: добавление определяющего навыка в characterRaw.skills.defining
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o10' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.defining'),
      jsonb_build_object('id', 'rite_of_oak_and_mistletoe', 'name', ck_id('witcher_cc.wcc_skills.rite_of_oak_and_mistletoe.name')::text)
    )
  ) AS body;

-- i18n записи для названия профессии
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_profession' AS qu_id
                , 'character' AS entity)
, ins_profession AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o10' ||'.'|| meta.entity ||'.'|| 'profession') AS id
       , meta.entity, 'profession', v.lang, v.text
    FROM (VALUES
            ('ru', 'Друид'),
            ('en', 'Druid')
         ) AS v(lang, text)
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
-- Эффекты: установка профессии
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o10' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.profession'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o10' ||'.'|| meta.entity ||'.'|| 'profession')::text)
    )
  ) AS body
FROM meta
UNION ALL
SELECT
  'character' AS scope,
  'wcc_profession_o10' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.logicFields.profession'),
      'Druid'
    )
  ) AS body;

