\echo '005_profession_06_priest.sql'
-- Вариант ответа: Жрец

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_profession' AS qu_id
                , 'answer_options' AS entity)
-- Базовые правила видимости (профессия "Жрец" только для расы Human или Elf, и НЕ включен DLC exp_toc)
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
    ck_id('witcher_cc.rules.wcc_profession.priest') AS ru_id,
    'wcc_profession_priest' AS name,
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
        jsonb_build_object('!', rule_parts.exp_toc_expr)
      )
    ) AS body
  FROM rule_parts
  ON CONFLICT (ru_id) DO NOTHING
  RETURNING ru_id
)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
            ( 6, 'Жрец', '
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
                <li>[Интеллект] - Выживание в дикой природе</li>
                <li>[Интеллект] - Передача знаний</li>
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
                <li>Священный символ</li>
                <li>Обеззараживающая жидкость ×5</li>
                <li>Инструменты алхимика</li>
                <li>Хирургические инструменты</li>
                <li>Песочные часы (час)</li>
                <li>Кинжал</li>
                <li>Посох</li>
                <li>Кровосвёртывающий порошок ×5</li>
                <li>Обезболивающие травы ×5</li>
                <li>Ингредиенты общей стоимостью 100 крон</li>
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
        <td class="header">Посвящённый (Эмп)</td>
    </tr>
    <tr>
        <td class="opt_content">
            В большинстве церквей мира рады посетителям. Служители храмов помогают местным жителям и с радостью принимают новообращённых в свою веру. Жрец может совершить проверку навыка <strong>Посвящённый</strong> (СЛ определяет ведущий) в храме своей религии, чтобы получить бесплатный кров, исцеление и прочие услуги на усмотрение ведущего. Навык <strong>Посвящённый</strong> также можно использовать при общении с единоверцами, но получите вы куда меньше, чем в церкви. <strong>Посвящённый</strong> не действует при общении с теми, кто исповедует другую веру.
        </td>
    </tr>
</table>

<h3>Профессиональные навыки</h3>

<table class="skills_branch_1">
    <tr>
        <td class="header">Проповедник</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Божественная сила</strong><br>
            Укрепляя связь с божеством, жрец может повысить своё значение Энергии на 1 за каждый уровень <strong>Божественной силы</strong>. Таким образом, значение Энергии жреца на 10 уровне будет равно 12. Эта способность развивается аналогично прочим навыкам и суммируется с <strong>Единением с природой</strong>. Значение Энергии в этом случае общее
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Божественный авторитет (Эмп)</strong><br>
            Для крестьян и простого люда жрец — проводник воли богов. Жрец может добавить значение <strong>Божественного авторитета</strong> к своим проверкам Лидерства, если он находится в области, где исповедуют ту же религию. Если жрец находится за пределами такой области, то он добавляет половину значения способности.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Предвидение (Воля)</strong><br>
            По решению ведущего жрец может получить видение будущего, на 3 раунда впав в состояние кататонии. После этого жрец может совершить проверку <strong>Предвидения</strong> со СЛ, определяемой ведущим, чтобы расшифровать полученные видения, которые представляют собой смесь символов и метафор.
        </td>
    </tr>
</table>

<table class="skills_branch_2">
    <tr>
        <td class="header">Друид</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Единение с природой</strong><br>
            Укрепляя связь с природой, жрец может повысить своё значение Энергии на 1 за каждый уровень <strong>Единения с природой</strong>. Таким образом, значение Энергии жреца на 10 уровне будет равно 12. Эта способность развивается аналогично прочим навыкам и суммируется с <strong>Божественной силой</strong>. Значение Энергии в этом случае общее.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Знаки природы (Инт)</strong><br>
            Находясь среди природы, друид может совершить проверку способности <strong>Знаки природы</strong> со СЛ, определяемой ведущим. При успехе друид по знакам узнаёт, кто в этом месте был и что делал. Эта проверка даёт только локальную информацию и не позволяет отслеживать.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Союзник природы (Воля)</strong><br>
            Друид добавляет способность <strong>Союзник природы</strong> к любым проверкам Выживания в дикой природе для обращения с животными. Друид также может сдружиться с животным, потратив полный раунд и совершив проверку <strong>Союзника природы</strong>. Зверь или иное животное становится союзником друида на количество часов, равное значению способности <strong>Союзник природы</strong>. Данная способность не действует на чудовищ.
            <br><table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr>
                    <th>Приказ</th>
                    <th>СЛ</th>
                </tr>
                <tr><td>Нападай</td><td>10</td></tr>
                <tr><td>Защищай цель</td><td>14</td></tr>
                <tr><td>Подвези меня</td><td>15</td></tr>
                <tr><td>Принеси мне кое-что</td><td>17</td></tr>
                <tr><td>Притащи мне кое-кого</td><td>15</td></tr>
                <tr><td>Стой</td><td>10</td></tr>
                <tr><td>Карауль</td><td>16</td></tr>
                <tr><td>Охраняй территорию</td><td>15</td></tr>
                <tr><td>Иди в знакомое место</td><td>15</td></tr>
                <tr><td>Не трогай</td><td>14</td></tr>
                <tr><td>Отступай</td><td>10</td></tr>
            </table>
            <div style="display: inline-block; margin-left: 12px;">
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr>
                    <th>Животное (зверь)</th>
                    <th>СЛ</th>
                </tr>
                <tr><td>Кошка</td><td>12</td></tr>
                <tr><td>Собака</td><td>10</td></tr>
                <tr><td>Птица</td><td>14</td></tr>
                <tr><td>Змея</td><td>16</td></tr>
                <tr><td>Лошадь</td><td>14</td></tr>
                <tr><td>Боевой конь</td><td>16</td></tr>
                <tr><td>Вол</td><td>17</td></tr>
                <tr><td>Мул</td><td>14</td></tr>
                <tr><td>Волк</td><td>16</td></tr>
                <tr><td>Дикая собака</td><td>15</td></tr>
            </table>
            </div>
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
            Жрец может совершить проверку <strong>Рвения</strong> против текущего значения ИнтхЗ цели. При успехе слова жреца ободряют цель, что даёт ей 1d6 временных ПЗ за каждый пункт сверх СЛ (максимум 5). Этот эффект длится количество раундов, равное значению <strong>Рвения</strong> х 2, и на одну цель его можно использовать только раз в день.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Слово божье (Эмп)</strong><br>
            Жрец может совершить проверку способности <strong>Слово божье</strong>, чтобы убедить слушателей, что его устами говорит божество. Любой, кто провалит проверку Сопротивления убеждению, будет считать жреца мессией и следовать за ним. Количество последователей жреца равно значению его <strong>Слова божьего</strong>. Если у последователей нет блоков параметров, используйте для них параметры разбойников.
            <br><br>
            Когда ваш персонаж отдаёт своим последователям действительно странный или неестественный для него приказ, совершите проверку <strong>Слова божьего</strong> со СЛ, определяемой ведущим. Вы можете провалить проверку 3 раза, после чего последователи покинут вашего персонажа. Если при последней проверке выпадает 1, то последователи нападут на вас или объявят еретиком.
        </td>
    </tr>
</table>
</div>
'
         )) AS raw_data_ru(num, title, description)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
            ( 6, 'Priest', '
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
                <li>[INT] - Wilderness Survival</li>
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
                <li>100 crowns of components</li>
                <li>Alchemy set</li>
                <li>Clotting powder ×5</li>
                <li>Dagger</li>
                <li>Holy symbol</li>
                <li>Hourglass</li>
                <li>Numbing herbs ×5</li>
                <li>Staff</li>
                <li>Sterilizing fluid ×5</li>
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
            The churches of the world are often warm and inviting places, helping their communities and welcoming new converts. A Priest can roll <strong>Initiate of the Gods</strong> at a DC set by the GM at churches of the same faith to get free lodging, healing, and other services at the GM''s discretion. <strong>Initiate of the Gods</strong> also works when dealing with members of the same faith, though they will likely be able to offer less than a fully supplied church. Keep in mind that <strong>Initiate of the Gods</strong> doesn''t work with members of other faiths.
        </td>
    </tr>
</table>

<h3>Professional Skills</h3>

<table class="skills_branch_1">
    <tr>
        <td class="header">The Preacher</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Divine Power</strong><br>
            A Priest can become more in tune with their god, gaining 1 point of Vigor threshold per skill level in <strong>Divine Power</strong>. This brings your Vigor threshold to a total of 12 at level 10. <strong>Divine Power</strong> can be trained like other skills and stacks with <strong>Nature Attunement</strong>. The Vigor thresholds are not separate.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Divine Authority (EMP)</strong><br>
            Peasants and the common folk of the world see Priests as agents of the god''s will. A Priest can add their <strong>Divine Authority</strong> to their Leadership rolls if they are in an area where their religion is worshiped. Even when outside such areas of worship a Priest adds half this value, due to their presence.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Precognition (WILL)</strong><br>
            At the will of the GM, a Priest can be overcome by visions of the future, sending them into a catatonic state for 3 rounds. After this time the Priest can roll <strong>Precognition</strong> at a DC set by the GM to decipher the visions that they are stricken by. Such visions are composed of symbolism and metaphors.
        </td>
    </tr>
</table>

<table class="skills_branch_2">
    <tr>
        <td class="header">The Druid</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Nature Attunement</strong><br>
            A Priest can become more in tune with nature, gaining 1 point of Vigor threshold per skill level in <strong>Nature Attunement</strong>. This brings your Vigor threshold to a total of 12 at level 10. <strong>Nature Attunement</strong> can be trained like other skills and stacks with <strong>Divine Power</strong>. The Vigor thresholds are not separate.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Read Nature (INT)</strong><br>
            When in a purely natural environment a druid can roll <strong>Read Nature</strong> at a DC set by the GM. On a success, the druid reads the signs around them to learn everything that passed through that area and what they did in the area. <strong>Read Nature</strong> renders a very localized picture and cannot track things.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Animal Compact (WILL)</strong><br>
            A Druid adds <strong>Animal Compact</strong> to any Wilderness Survival rolls they make to handle animals. A Druid can also make a compact with an animal. By taking a full round and rolling <strong>Animal Compact</strong>, they make one Beast or animal their ally for a number of hours equal to their <strong>Animal Compact</strong> value. Monsters are unaffected.
            <br>
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr>
                    <th>Order</th>
                    <th>DC</th>
                </tr>
                <tr><td>Attack</td><td>10</td></tr>
                <tr><td>Defend a target</td><td>14</td></tr>
                <tr><td>Let me ride you</td><td>15</td></tr>
                <tr><td>Fetch an object</td><td>17</td></tr>
                <tr><td>Fetch a target</td><td>15</td></tr>
                <tr><td>Stop</td><td>10</td></tr>
                <tr><td>Keep lookout</td><td>16</td></tr>
                <tr><td>Guard an area</td><td>15</td></tr>
                <tr><td>Go to a known location</td><td>15</td></tr>
                <tr><td>Don''t touch</td><td>14</td></tr>
                <tr><td>Retreat</td><td>10</td></tr>
            </table>
            <div style="display: inline-block; margin-left: 12px;">
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr>
                    <th>Animal/Beast</th>
                    <th>DC</th>
                </tr>
                <tr><td>Cat</td><td>12</td></tr>
                <tr><td>Dog</td><td>10</td></tr>
                <tr><td>Bird</td><td>14</td></tr>
                <tr><td>Serpent</td><td>16</td></tr>
                <tr><td>Horse</td><td>14</td></tr>
                <tr><td>War horse</td><td>16</td></tr>
                <tr><td>Ox</td><td>17</td></tr>
                <tr><td>Mule</td><td>14</td></tr>
                <tr><td>Wolf</td><td>16</td></tr>
                <tr><td>Wild dog</td><td>15</td></tr>
            </table>
            </div>
        </td>
    </tr>
</table>

<table class="skills_branch_3">
    <tr>
        <td class="header">The Fanatic</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Blood Rituals (WILL)</strong><br>
            A Priest casting a ritual can make a <strong>Blood Ritual</strong> check against the casting DC of the ritual. If they succeed, they can cast the ritual without required alchemical substances by sacrificing 5 HP in blood per missing alchemical substance. This blood can come from others, but must be spilled at the time of the ritual.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Fervor (EMP)</strong><br>
            A Priest can roll <strong>Fervor</strong> against a target''s current INT×3. On success, the rallying power of the Priest''s words grants 1d6 temporary health for every point rolled over the DC (maximum 5). This lasts for as many rounds as their <strong>Fervor</strong> ×2 and only works once per target per day.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Word of God (EMP)</strong><br>
            A Priest can roll <strong>Word of God</strong> to convince people that they are speaking directly for the gods. Anyone who fails a Resist Coercion roll sees the Priest as a messiah and follows along as an apostle. A Priest can have as many apostles as their <strong>Word of God</strong> value. In combat, use bandit stats for apostles with stat outs.
            <br><br>
            Any time you give a truly strange or uncharacteristic command to your apostles, you must make a <strong>Word of God</strong> roll at a DC set by the GM. You can fail 3 times before your apostles leave you. If your last failure is a fumble, your apostles will attack you or brand you as a heretic.
        </td>
    </tr>
</table>
</div>
'
         )) AS raw_data_en(num, title, description)
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
       ck_id('witcher_cc.rules.wcc_profession.priest') AS visible_ru_ru_id,
       jsonb_build_object(
           'title', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.title')::text),
           'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.description')::text)
       ) AS metadata
FROM raw_data
CROSS JOIN meta
ON CONFLICT (an_id) DO NOTHING;

-- Priest (pick 5)
-- 100 crowns of components - budget(100) - source_id = 'ingredients_craft', 'ingredients_alchemy'
-- Alchemy set - T105
-- Clotting powder ×5 - P048 x5
-- Dagger - W082
-- Holy symbol - T080
-- Hourglass - T091
-- Numbing herbs ×5 - P053 x5
-- Staff - W157
-- Sterilizing fluid ×5 - P054 x5
-- Surgeon''s kit - T111

-- Эффекты: заполнение professional_gear_options
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_profession_shop.bundle.priest_clotting_powder') AS id
     , 'questions' AS entity
     , 'metadata' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          ('ru', 'Порошок для остановки крови ×5'),
          ('en', 'Clotting powder ×5')
       ) AS v(lang, text)
ON CONFLICT (id, lang) DO NOTHING;

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_profession_shop.bundle.priest_numbing_herbs') AS id
     , 'questions' AS entity
     , 'metadata' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          ('ru', 'Обезболивающие травы ×5'),
          ('en', 'Numbing herbs ×5')
       ) AS v(lang, text)
ON CONFLICT (id, lang) DO NOTHING;

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_profession_shop.bundle.priest_sterilizing_fluid') AS id
     , 'questions' AS entity
     , 'metadata' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          ('ru', 'Обеззараживающая жидкость ×5'),
          ('en', 'Sterilizing fluid ×5')
       ) AS v(lang, text)
ON CONFLICT (id, lang) DO NOTHING;

INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o06' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.professional_gear_options'),
      jsonb_build_object(
        'tokens', 5,
        'items', jsonb_build_array('T105', 'W082', 'T080', 'T091', 'W157', 'T111'),
        'bundles', jsonb_build_array(
          jsonb_build_object(
            'bundleId', 'priest_clotting_powder',
            'displayName', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_profession_shop.bundle.priest_clotting_powder')::text),
            'items', jsonb_build_array(
              jsonb_build_object(
                'sourceId', 'potions',
                'itemId', 'P048',
                'quantity', 5
              )
            )
          ),
          jsonb_build_object(
            'bundleId', 'priest_numbing_herbs',
            'displayName', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_profession_shop.bundle.priest_numbing_herbs')::text),
            'items', jsonb_build_array(
              jsonb_build_object(
                'sourceId', 'potions',
                'itemId', 'P053',
                'quantity', 5
              )
            )
          ),
          jsonb_build_object(
            'bundleId', 'priest_sterilizing_fluid',
            'displayName', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_profession_shop.bundle.priest_sterilizing_fluid')::text),
            'items', jsonb_build_array(
              jsonb_build_object(
                'sourceId', 'potions',
                'itemId', 'P054',
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
  'wcc_profession_o06' AS an_an_id,
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

-- Эффекты: бюджет на алхимические ингредиенты (100) для магазина
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o06' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.money.alchemyIngredientsCrowns'),
      100
    )
  ) AS body;

-- Эффекты: жетоны для магии (2 инвокации новичка, 2 ритуала новичка, 2 порчи с низкой опасностью)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o06' AS an_an_id,
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
  'wcc_profession_o06' AS an_an_id,
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
  'wcc_profession_o06' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.professional_gear_options.novice_hexes_tokens'),
      2
    )
  ) AS body;