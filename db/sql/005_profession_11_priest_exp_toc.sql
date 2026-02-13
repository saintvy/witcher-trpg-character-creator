\echo '005_profession_11_priest_exp_toc.sql'
-- Вариант ответа: Жрец (exp_toc)

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_profession' AS qu_id
                , 'answer_options' AS entity)
-- Базовые правила видимости (профессия "Жрец" только для расы Human или Elf, и включен DLC exp_toc)
, ensure_rules AS (
  -- гарантируем, что is_dlc_exp_toc_enabled существует
  INSERT INTO rules (ru_id, name, body)
  VALUES
    (ck_id('witcher_cc.rules.is_dlc_exp_toc_enabled'), 'is_dlc_exp_toc_enabled', '{"in":["exp_toc",{"var":["dlcs",[]]}]}'::jsonb)
  ON CONFLICT (ru_id) DO UPDATE
  SET name = EXCLUDED.name,
      body = EXCLUDED.body
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
    ck_id('witcher_cc.rules.wcc_profession.priest_exp_toc') AS ru_id,
    'wcc_profession_priest_exp_toc' AS name,
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
  ON CONFLICT (ru_id) DO UPDATE
  SET name = EXCLUDED.name,
      body = EXCLUDED.body
  RETURNING ru_id
)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
            ( 11, 'Жрец', '
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
        </td>
        <td>
            <strong>Навыки</strong>
            <ul>
                <li>[Воля] - Наведение порчи</li>
                <li>[Воля] - Проведение ритуалов</li>
                <li>[Воля] - Сотворение заклинаний</li>
                <li>[Воля] - Храбрость</li>
                <li>[Интеллект] - Передача знаний</li>
                <li>[Реакция] - Владение древковым оружием</li>
                <li>[Ремесло] - Первая помощь</li>
                <li>[Эмпатия] - Лидерство</li>
                <li>[Эмпатия] - Понимание людей</li>
                <li>[Эмпатия] - Харизма</li>
            </ul>
        </td>
        <td>
            <strong>Снаряжение</strong><br>
            <strong class="section-title">(выберите 5)</strong>
            <ul>
                <li>Двуслойный гамбезон</li>
                <li>Ингредиенты общей стоимостью 100 крон</li>
                <li>Кинжал</li>
                <li>Кровосвёртывающий порошок ×5</li>
                <li>Обезболивающие травы ×5</li>
                <li>Песочные часы (час)</li>
                <li>Посох</li>
                <li>Священный символ</li>
                <li>Украшения</li>
                <li>Хирургические инструменты</li>
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
        <td class="header">Посвященный (Эмп)</td>
    </tr>
    <tr>
        <td class="opt_content">
            Церкви в мире зачастую являются уютными и гостеприимными местами, которые помогают своим общинам и приветствуют новообращённых. Жрец может совершить проверку навыка <strong>Посвященный</strong> с СЛ, установленной ведущим, в церквах той же веры, чтобы получить бесплатное жильё, лечение и другие услуги по усмотрению ведущего. Навык <strong>Посвященный</strong> также работает, когда имеешь дело с членами той же веры, хотя они, вероятно, смогут предложить меньше, чем полностью укомплектованная церковь. По усмотрению ведущего, <strong>Посвященный</strong> также будет работать с поклонниками родственных божеств.
        </td>
    </tr>
</table>

<h3>Профессиональные навыки</h3>

<table class="skills_branch_1">
    <tr>
        <td class="header">Культист</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Мистагог (Эмп)</strong><br>
            Будучи в поселении, жрец, потратив день и пройдя проверку способности <strong>Мистагог</strong> со СЛ в зависимости от поселения, может построить святилище своего божества, которое привлекает людей и обращает их в свою религию. Количество единомышленников определяет ведущий. К тому же, находясь в пределах 20 м от этого святилища, жрец может использовать это святилище в качестве фокусирующего предмета со значением 3.
            <br><table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr><th>Поселение</th><th>СЛ</th></tr>
                <tr><td>Деревня</td><td>22</td></tr>
                <tr><td>Посёлок</td><td>20</td></tr>
                <tr><td>Город</td><td>18</td></tr>
                <tr><td>Столица</td><td>14</td></tr>
            </table>
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Тайна культа (Воля)</strong><br>
            На более высоких уровнях жрецу показывают внутреннюю работу его религии и посвящают в некоторые её секреты. <strong>Тайна культа</strong> жрецов зависит от типа религии, которой они следуют. Обратитесь к таблице Тайны культа, чтобы узнать, какая из них.
            <br><table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr><th>Тип духовенства</th><th>Тайна культа</th></tr>
                <tr>
                    <td>Организованные церкви</td>
                    <td>Жрец был посвящен в высшие дела вашей церкви. Они могут добавить свой уровень Тайны Культа к своим проверкам навыка Посвященный.</td>
                </tr>
                <tr>
                    <td>Старые боги</td>
                    <td>Жрецу были показаны пути древней магии. Когда они проводят ритуал, они могут пройти как проверку Тайны Культа, так и проверку Проведения ритуала и взять наивысшую из двух.</td>
                </tr>
                <tr>
                    <td>Темные культы</td>
                    <td>Секретность является ключевым моментом. Когда кто-то пытается с помощью магии распознать истинную веру Жреца или его мотивы, он должен сделать бросок против проверки Малой Тайны жреца. Если они терпят неудачу, жрец заставляет их поверить в то, во что они верят. Против немагических проверок жрец может добавить свой уровень Тайны Культа к своим проверкам Обмана.</td>
                </tr>
            </table>
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Благословения (Воля)</strong><br>
            Жрец может благословить группу людей, проведя часовую церемонию. В конце церемонии он проходит проверку навыка <strong>Благословения</strong> с СЛ 16. В течение одного дня после этого число людей, равное уровню <strong>Благословения</strong> жреца, получает бонусы в соответствии с таблицей Благословений.
            <br><table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr><th>Тип духовенства</th><th>Благословения</th><th>Божества</th></tr>
                <tr>
                    <td>Организованные церкви</td>
                    <td>Жрец наделяет своих последователей божественной властью своей церкви. При успехе они получают +4 к Лидерству и +4 к Репутации.</td>
                    <td>Вечный огонь, Крева, Великое Солнце, Мелитэле, Пророк Лебеда</td>
                </tr>
                <tr>
                    <td>Старые боги</td>
                    <td>Жрец наделяет своих последователей благословением, защищающим их разум и тело. При успехе они получают +3 к ПБ и +2 к Защите от магии.</td>
                    <td>Дана Медбх, Эпона, Фрейя, Лильвани, Морриган, Нехалена, Вейопатис</td>
                </tr>
                <tr>
                    <td>Темные культы</td>
                    <td>Жрец наделяет своих последователей стремительностью. При успехе они получают бонус +4 к Скрытности и Инициативе.</td>
                    <td>Корам Агх Тэра, Свальблод</td>
                </tr>
            </table>
        </td>
    </tr>
</table>

<table class="skills_branch_2">
    <tr>
        <td class="header">Проповедник</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Божественная сила</strong><br>
            Укрепляя связь с божеством, жрец может повысить своё значение Энергии на 1 за каждый уровень навыка <strong>Божественной силы</strong> вплоть до уровня 9. На 10-м уровне <strong>Божественной силы</strong> вы повышаете свой порог Энергии на 5, доводя его суммарно до 16. <strong>Божественную силу</strong> можно тренировать, как и любой другой навык.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Божественный авторитет (Эмп)</strong><br>
            Для крестьян и простого люда жрецы — проводники воли богов. Жрец может добавить значение <strong>Божественного авторитета</strong> к своим проверкам Лидерства, если он находится в области, где исповедуют ту же религию. Если жрец находится за пределами такой области, то он добавляет половину этого значения способности.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Предвидение (Воля)</strong><br>
            По решению ведущего жрец может получить видение будущего, на 3 раунда впав в состояние кататонии. После этого жрец может совершить проверку <strong>Предвидения</strong> со СЛ, определяемой ведущим, чтобы расшифровать полученные видения, которые представляют собой смесь символов и метафор.
        </td>
    </tr>
</table>

<table class="skills_branch_3">
    <tr>
        <td class="header">Фанатик</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Кровавые ритуалы (Воля)</strong><br>
            Проводя ритуал, жрец может совершить проверку способности <strong>Кровавые ритуалы</strong> со СЛ, равной СЛ ритуала. При успехе жрец проводит ритуал без необходимых алхимических субстанций, жертвуя при этом 5 ПЗ в виде крови за каждую недостающую субстанцию. Это может быть и чужая кровь, но только пролитая во время данного ритуала.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Рвение (Эмп)</strong><br>
            Жрец может совершить проверку <strong>Рвения</strong> против текущего Инт x3 цели. При успехе слова жреца ободряют цель, что даёт ей 1d6 временных ПЗ за каждый пункт, сверх СЛ (максимум 5). Этот эффект длится количество раундов, равное значению <strong>Рвения</strong> x2, и на одну цель его можно использовать только раз в день.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Слово божье (Эмп)</strong><br>
            Жрец может совершить проверку способности <strong>Слово божье</strong>, чтобы убедить слушателей, что его устами говорит божество. Любой, кто провалит проверку Сопротивления убеждению, будет считать жреца мессией и следует за ним. Количество последователей жреца равно значению его <strong>Слова божьего</strong>. Если у последователей нет блоков параметров, используйте параметры разбойников.
        </td>
    </tr>
</table>
</div>
'
         )) AS raw_data_ru(num, title, description)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
            ( 11, 'Priest', '
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
        </td>
        <td>
            <strong>Skills</strong>
            <ul>
                <li>[CRA] - First Aid</li>
                <li>[EMP] - Charisma</li>
                <li>[EMP] - Human Perception</li>
                <li>[EMP] - Leadership</li>
                <li>[INT] - Teaching</li>
                <li>[REF] - Staff/Spear</li>
                <li>[WILL] - Courage</li>
                <li>[WILL] - Hex Weaving</li>
                <li>[WILL] - Ritual Crafting</li>
                <li>[WILL] - Spell Casting</li>
            </ul>
        </td>
        <td>
            <strong>Gear</strong><br>
            <strong class="section-title">(Pick 5)</strong>
            <ul>
                <li>Double Woven Gambeson</li>
                <li>100 crowns of components</li>
                <li>Dagger</li>
                <li>Clotting powder ×5</li>
                <li>Numbing herbs ×5</li>
                <li>Hourglass</li>
                <li>Staff</li>
                <li>Holy symbol</li>
                <li>Jewelry</li>
                <li>Surgeon''s kit</li>
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
        <td class="header">Initiate of the Gods (EMP)</td>
    </tr>
    <tr>
        <td class="opt_content">
            The churches of the world are often warm and inviting places which aid their communities and welcome new converts. A Priest can roll <strong>Initiate of the Gods</strong> at a DC set by the GM at churches of the same faith to get free lodging, healing, and other services at the GM''s discretion. <strong>Initiate of the Gods</strong> also works when dealing with members of the same faith, though they will likely be able to offer less than a fully supplied church. At the GM''s discretion, <strong>Initiate of the Gods</strong> will also work with worshipers of related deities.
        </td>
    </tr>
</table>

<h3>Professional Skills</h3>

<table class="skills_branch_1">
    <tr>
        <td class="header">Cultist</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Mystagogue (EMP)</strong><br>
            When in a settlement, a Priest can spend a day and roll <strong>Mystagogue</strong> at a DC based on the settlement to build a shrine to their deity that attracts people and converts them to their religion. The GM determines how many people join. Additionally, while within 20m of this shrine, the Priest can use the shrine as a Focus with a value of 3.
            <br><table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr><th>Settlement</th><th>DC</th></tr>
                <tr><td>Village</td><td>22</td></tr>
                <tr><td>Town</td><td>20</td></tr>
                <tr><td>City</td><td>18</td></tr>
                <tr><td>Capital</td><td>14</td></tr>
            </table>
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Cult Mystery (WILL)</strong><br>
            At higher levels, a Priest is shown the inner workings of their religion and are privy to some of its secrets. The Priest''s cult mystery depends on the type of religion they follow. Refer to the Cult Mystery table to know which one.
            <br><table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr><th>Type of Priesthood</th><th>Cult Mystery</th></tr>
                <tr>
                    <td>Organized Churches</td>
                    <td>The Priest has been initiated into the higher workings of your church. They can add their Cult Mystery level to their Initiate of the Gods checks.</td>
                </tr>
                <tr>
                    <td>Old Gods</td>
                    <td>The Priest has been shown the ways of old magic. When they craft a ritual, they can roll both a Cult Mystery check and a Ritual Crafting check and take the highest of the two.</td>
                </tr>
                <tr>
                    <td>Dark Cults</td>
                    <td>Secrecy is key. When someone tries to discern the Priest''s true faith or their motives through magic, they must roll against the Priest''s Minor Mystery check. If they fail, the Priest makes them believe what they choose. Against non-magical scrutiny, the Priest can add their Cult Mystery level to their Deceit checks.</td>
                </tr>
            </table>
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Blessings (WILL)</strong><br>
            A Priest can bless a group of people through a 1-hour ceremony. At the end of the ceremony, they roll <strong>Blessings</strong> at a DC:16. For one day afterward, a number of people equal to the Priest''s <strong>Blessings</strong> level gain bonuses as per the Blessings table.
            <br><table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr><th>Type of Priesthood</th><th>Blessing</th><th>Deities</th></tr>
                <tr>
                    <td>Organized Churches</td>
                    <td>The Priest empowers their followers with the divine authority of their church. On a success, they gain a +4 to Leadership and +4 to Reputation.</td>
                    <td>Eternal Fire, Kreve, Great Sun, Melitele, Prophet Lebioda</td>
                </tr>
                <tr>
                    <td>Old Gods</td>
                    <td>The Priest empowers their followers with a blessing that shields their mind and bodies. On a success, they gain a +3 to SP and +2 to Resist Magic.</td>
                    <td>Dana Meadbh, Epona, Freya, Lilvani, Morrigan, Nehaleni, Veyopatis</td>
                </tr>
                <tr>
                    <td>Dark Cults</td>
                    <td>The Priest empowers their followers with a blessing of celerity. On a success, they gain a +4 bonus to Stealth and Initiative.</td>
                    <td>Coram Agh Tera, Svalblod</td>
                </tr>
            </table>
        </td>
    </tr>
</table>

<table class="skills_branch_2">
    <tr>
        <td class="header">Preacher</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Divine Power</strong><br>
            A Priest can become more in tune with their god, gaining 1 point of Vigor threshold per skill level in <strong>Divine Power</strong> up to level 9. At the 10th level in <strong>Divine Power</strong>, you raise your Vigor threshold by 5 bringing it to a total of 16. <strong>Divine Power</strong> can be trained like any other skill.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Divine Authority (EMP)</strong><br>
            The peasants and common folk of the world see Priests as agents of the gods'' will. A Priest can add their <strong>Divine Authority</strong> to their Leadership checks if they are in an area where their religion is worshiped. Even when outside such areas of worship, a Priest adds half this value, due to their presence.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Precognition (WILL)</strong><br>
            At the will of the GM, a Priest can be overcome by visions of the future, sending them into a catatonic state for 3 rounds. After this time the Priest can roll <strong>Precognition</strong> at a DC set by the GM to decipher the visions that they are stricken by. Such visions are composed of symbolism and metaphors.
        </td>
    </tr>
</table>

<table class="skills_branch_3">
    <tr>
        <td class="header">Fanatic</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Blood Rituals (WILL)</strong><br>
            A Priest casting a ritual can make a <strong>Blood Ritual</strong> check against the casting DC of the ritual. If they succeed, they can cast the ritual without required alchemical substances by sacrificing 5 HP in blood per missing unit of alchemical substance. This blood can come from others but must be spilled at the time of the ritual.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Fervor (EMP)</strong><br>
            A Priest can roll <strong>Fervor</strong> against a target''s current INT×3. On a success, the rallying power of the Priest''s words grants 1d6 temporary health for every point rolled over the DC (maximum 5). This lasts for as many rounds as their <strong>Fervor</strong> x2 and only works once per target per day.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Word of God (EMP)</strong><br>
            A Priest can roll <strong>Word of God</strong> to convince people that they are speaking directly for the gods. Anyone who fails to defend with Resist Coercion sees the Priest as a messiah and follows along as an apostle. A Priest can have as many apostles as their <strong>Word of God</strong> value. In combat, use bandit stats for apostles without stats.
        </td>
    </tr>
</table>
</div>
'
         )) AS raw_data_en(num, title, description)
)
-- i18n: title/description профессии для выпадающего списка
, ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.'|| raw_data.entity_field) AS id
       , meta.entity AS entity
       , raw_data.entity_field AS entity_field
       , raw_data.lang
       , raw_data.text
    FROM (
      SELECT lang, num, 'label'::text AS entity_field, title::text AS text FROM raw_data
      UNION ALL
      SELECT lang, num, 'description'::text AS entity_field, description::text AS text FROM raw_data
    ) raw_data
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
  RETURNING 1
)
-- вставка варианта ответа
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT
  meta.qu_id || '_o' || to_char(raw_data.num, 'FM9900') AS an_id,
  meta.su_su_id,
  meta.qu_id,
  raw_data.title AS label,
  raw_data.num AS sort_order,
  (SELECT ru_id FROM vis_rules LIMIT 1) AS visible_ru_ru_id,
  jsonb_build_object(
    'title', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.label')::text),
    'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.description')::text)
  ) AS metadata
FROM raw_data
CROSS JOIN meta
ON CONFLICT (an_id) DO NOTHING;

-- Priest (exp_toc) (pick 5)
-- 100 crowns of components - option item T900 (grants budget(100) for ingredients sources)
-- Double Woven Gambeson - A014
-- Dagger - W082
-- Holy symbol - T080
-- Hourglass - T091
-- Staff - W157
-- Jewelry - T038
-- Surgeon''s kit - T111
-- Clotting powder ×5 - P048 x5
-- Numbing herbs ×5 - P053 x5

-- Эффекты: заполнение professional_gear_options
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_profession_shop.bundle.priest_exp_toc_clotting_powder') AS id
     , 'questions' AS entity
     , 'metadata' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          ('ru', 'Кровосвёртывающий порошок ×5'),
          ('en', 'Clotting powder ×5')
       ) AS v(lang, text)
ON CONFLICT (id, lang) DO NOTHING;

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_profession_shop.bundle.priest_exp_toc_numbing_herbs') AS id
     , 'questions' AS entity
     , 'metadata' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          ('ru', 'Обезболивающие травы ×5'),
          ('en', 'Numbing herbs ×5')
       ) AS v(lang, text)
ON CONFLICT (id, lang) DO NOTHING;

INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o11' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.professional_gear_options'),
      jsonb_build_object(
        'tokens', 5,
        'items', jsonb_build_array('T900', 'A014', 'W082', 'T080', 'T091', 'W157', 'T038', 'T111'),
        'bundles', jsonb_build_array(
          jsonb_build_object(
            'bundleId', 'priest_exp_toc_clotting_powder',
            'displayName', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_profession_shop.bundle.priest_exp_toc_clotting_powder')::text),
            'items', jsonb_build_array(
              jsonb_build_object(
                'sourceId', 'potions',
                'itemId', 'P048',
                'quantity', 5
              )
            )
          ),
          jsonb_build_object(
            'bundleId', 'priest_exp_toc_numbing_herbs',
            'displayName', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_profession_shop.bundle.priest_exp_toc_numbing_herbs')::text),
            'items', jsonb_build_array(
              jsonb_build_object(
                'sourceId', 'potions',
                'itemId', 'P053',
                'quantity', 5
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
  'wcc_profession_o11' AS an_an_id,
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
  'wcc_profession_o11' AS an_an_id,
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
  'wcc_profession_o11' AS an_an_id,
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
  'wcc_profession_o11' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.professional_gear_options.novice_hexes_tokens'),
      2
    )
  ) AS body;

-- Эффекты: добавление начальных навыков в characterRaw.skills.initial[]
WITH skill_mapping (skill_name) AS ( VALUES
    ('staff_spear'),          -- Владение древковым оружием
    ('leadership'),           -- Лидерство
    ('hex_weaving'),          -- Наведение порчи
    ('first_aid'),            -- Первая помощь
    ('teaching'),             -- Передача знаний
    ('human_perception'),     -- Понимание людей
    ('ritual_crafting'),      -- Проведение ритуалов
    ('spell_casting'),        -- Сотворение заклинаний
    ('charisma'),             -- Харизма
    ('courage')               -- Храбрость
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o11' AS an_an_id,
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.initial'),
      sm.skill_name
    )
  ) AS body
FROM skill_mapping sm;

-- Эффекты: добавление профессиональных навыков в characterRaw.skills.professional (skill_<ветка>_<позиция> -> { id: "<skill_id>", name: "<i18n_uuid>" })
WITH prof_skill_mapping (skill_id, branch_number, professional_number) AS ( VALUES
  ('mystagogue', 1, 1),
  ('cult_mystery', 1, 2),
  ('blessings', 1, 3),
  ('divine_power', 2, 1),
  ('divine_authority', 2, 2),
  ('foresight', 2, 3),
  ('bloody_rituals', 3, 1),
  ('zeal', 3, 2),
  ('holy_fire', 3, 3)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o11' AS an_an_id,
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
  'wcc_profession_o11' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.professional.branches'),
      jsonb_build_array(
        ck_id('witcher_cc.wcc_skills.branch.культист.name')::text,
        ck_id('witcher_cc.wcc_skills.branch.проповедник.name')::text,
        ck_id('witcher_cc.wcc_skills.branch.фанатик.name')::text
      )
    )
  ) AS body;

-- Эффекты: добавление определяющего навыка в characterRaw.skills.defining
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o11' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.defining'),
      jsonb_build_object('id', 'dedicated', 'name', ck_id('witcher_cc.wcc_skills.dedicated.name')::text)
    )
  ) AS body;

-- i18n записи для названия профессии
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_profession' AS qu_id
                , 'character' AS entity)
, ins_profession AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o11' ||'.'|| meta.entity ||'.'|| 'profession') AS id
       , meta.entity, 'profession', v.lang, v.text
    FROM (VALUES
            ('ru', 'Жрец'),
            ('en', 'Priest')
         ) AS v(lang, text)
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
-- Эффекты: установка профессии
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o11' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.profession'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o11' ||'.'|| meta.entity ||'.'|| 'profession')::text)
    )
  ) AS body
FROM meta
UNION ALL
SELECT
  'character' AS scope,
  'wcc_profession_o11' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.logicFields.profession'),
      'Priest'
    )
  ) AS body
FROM meta;

