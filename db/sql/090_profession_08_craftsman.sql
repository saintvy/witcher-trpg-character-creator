\echo '090_profession_08_craftsman.sql'
-- Вариант ответа: Ремесленник

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_profession' AS qu_id
                , 'answer_options' AS entity)
-- Базовые правила видимости (профессия "Ремесленник" только для расы НЕ ведьмак)
, rule_parts AS (
  SELECT
    (SELECT r.body FROM rules r WHERE r.name = 'is_witcher' ORDER BY r.ru_id LIMIT 1) AS is_witcher_expr
)
, vis_rules AS (
  INSERT INTO rules (ru_id, name, body)
  SELECT
    ck_id('witcher_cc.rules.wcc_profession.craftsman') AS ru_id,
    'wcc_profession_craftsman' AS name,
    jsonb_build_object('!', rule_parts.is_witcher_expr) AS body
  FROM rule_parts
  ON CONFLICT (ru_id) DO NOTHING
  RETURNING ru_id
)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
            ( 8, 'Ремесленник', '
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
                <li>[Интеллект] - Образование</li>
                <li>[Интеллект] - Ориентирование в городе</li>
                <li>[Интеллект] - Торговля</li>
                <li>[Ловкость] - Атлетика</li>
                <li>[Ремесло] - Алхимия</li>
                <li>[Ремесло] - Изготовление</li>
                <li>[Телосложение] - Сила</li>
                <li>[Телосложение] - Стойкость</li>
                <li>[Эмпатия] - Искусство</li>
                <li>[Эмпатия] - Убеждение</li>
            </ul>
        </td>
        <td>
            <strong>Снаряжение</strong><br>
            <strong class="section-title">(выберите 5)</strong>
            <ul>
                <li>Походная кузница</li>
                <li>Инструменты торговца</li>
                <li>Железный полуторный меч</li>
                <li>Инструменты ремесленника</li>
                <li>Инструменты алхимика</li>
                <li>Песочные часы (час)</li>
                <li>Небольшой сундучок</li>
                <li>Булава</li>
                <li>Компоненты общей стоимостью 50 крон</li>
                <li>Замок</li>
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
        <td class="header">Быстрый ремонт (Рем)</td>
    </tr>
    <tr>
        <td class="opt_content">
            Умелый ремесленник способен наскоро подлатать оружие или броню, чтобы их владелец мог продолжать сражаться. Ремесленник свяжет вместе обрывки лопнувшей тетивы, заострит край сломанного клинка или приколотит металлическую пластину поверх треснувшего щита. Ремесленник может потратить ход и совершить проверку <strong>Быстрого ремонта</strong> со сложностью, равной СЛ Изготовления данного предмета минус 3, чтобы восстановить 1/2 прочности брони или 1/2 надёжности сломанного оружия или щита. Пока оружие после <strong>Быстрого ремонта</strong> не починят в кузнице, оно наносит половину обычного урона.
            <br><br>
            <strong>Слишком много поломок</strong><br>
            Ранее подлатанное оружие, щит или броню после повторной поломки можно подлатать ещё только один раз. Во второй раз <strong>Быстрый ремонт</strong> восстановит лишь 1/4 значения надёжности/прочности (с округлением вниз).
        </td>
    </tr>
</table>

<h3>Профессиональные навыки</h3>

<!-- ВЕТКА 1 — Оружейник -->
<table class="skills_branch_1">
    <tr>
        <td class="header">Оружейник</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Большой каталог (Инт)</strong><br>
            Умелый ремесленник способен запомнить огромное количество чертежей на все случаи жизни. Когда ремесленник уже запомнил максимальное доступное ему количество чертежей, он может совершить проверку способности <strong>Большой каталог</strong> со СЛ 15, чтобы запомнить ещё один. Нет ограничения на количество запомненных чертежей, но за каждые 10 запоминаний СЛ проверки повышается на 1.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Подмастерье (Рем)</strong><br>
            Когда ремесленник начинает изготавливать какой-либо предмет, он может совершить проверку способности <strong>Подмастерье</strong> со СЛ, равной СЛ Изготовления данного предмета. При успехе он прибавляет 1 к урону или к прочности за каждые 2 пункта сверх указанной СЛ. Максимальный бонус к урону или прочности равен 5. Ремесленник не может использовать Удачу для увеличения этого бонуса.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Мастерская работа (Рем)</strong><br>
            <strong>Мастерская работа</strong> позволяет ремесленнику изготавливать предметы уровня мастера. Ремесленник может также в любой момент совершить проверку способности <strong>Мастерская работа</strong> со СЛ, равной СЛ Изготовления предмета, чтобы навсегда придать броне сопротивление (он сам решает чему именно) или бонус оружию: дробящее оружие получает свойство дезориентирующее (-2), колющее или режущее — кровопускающее (50%).
        </td>
    </tr>
</table>

<!-- ВЕТКА 2 — Алхимик -->
<table class="skills_branch_2">
    <tr>
        <td class="header">Алхимик</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Список лекарств (Инт)</strong><br>
            Умелый ремесленник способен запомнить огромное количество формул на все случаи жизни. Когда ремесленник уже запомнил доступное ему число формул, он может совершить проверку способности <strong>Список лекарств</strong> со СЛ 15, чтобы запомнить ещё одну. Нет ограничения на количество запомненных формул, но за каждые 10 запоминаний СЛ проверки повышается на 1.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Двойная порция (Рем)</strong><br>
            Когда ремесленник собирается изготовить алхимический состав, он может совершить проверку <strong>Двойной порции</strong> со СЛ, равной СЛ Изготовления данной формулы. При успехе он создаёт две порции состава из ингредиентов, рассчитанных на одну порцию. Это применимо ко всем алхимическим предметам, включая эликсиры, масла, отвары и бомбы.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Адаптация (Рем)</strong><br>
            Перед созданием ведьмачьего эликсира ремесленник может совершить проверку <strong>Адаптации</strong> (3 + СЛ Изготовления), чтобы уменьшить СЛ избегания отравления на 1 за каждый пункт свыше СЛ Изготовления. При провале ядовитость эликсира не меняется. СЛ избегания отравления не может опускаться ниже 12.
        </td>
    </tr>
</table>

<!-- ВЕТКА 3 — Импровизатор -->
<table class="skills_branch_3">
    <tr>
        <td class="header">Импровизатор</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Улучшение (Рем)</strong><br>
            Ремесленник может совершить проверку <strong>Улучшения</strong> со СЛ, указанной в таблице на полях, чтобы придать оружию или броне особые свойства (при наличии инструментов ремесленника). На улучшение необходимо потратить 3 раунда. Для улучшения не обязательно использовать кузницу, но она даёт бонус +2 к проверке. Критический провал наносит предмету урон, равный значению провала.
            <br><br>
            <div style="display:inline-block;">
            <table class="table-small" border="1" cellspacing="0" cellpadding="4">
                <tr>
                    <th>Улучшение</th>
                    <th>СЛ</th>
                </tr>
                <tr>
                    <td><b>Оружие</b></td>
                    <td></td>
                </tr>
                <tr>
                    <td>Укрепление (+2 к надёжности)</td>
                    <td>14</td>
                </tr>
                <tr>
                    <td>Зазубривание/шипы (+25 % к вероятности кровотечения)</td>
                    <td>16</td>
                </tr>
                <tr>
                    <td>Облегчение (+1 к точности)</td>
                    <td>18</td>
                </tr>
                <tr>
                    <td><b>Броня</b></td>
                    <td></td>
                </tr>
                <tr>
                    <td>Укрепление (+2 к прочности)</td>
                    <td>14</td>
                </tr>
                <tr>
                    <td>Камуфляж (+1 к Скрытности)</td>
                    <td>16</td>
                </tr>
                <tr>
                    <td>Шипы (2 урона тому, кто проводит захват)</td>
                    <td>18</td>
                </tr>
            </table>
            </div>
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Серебрение (Рем)</strong><br>
            Ремесленник может посеребрить имеющееся оружие в кузнице, совершив проверку со СЛ 16. Количество необходимых для этого серебряных слитков зависит от размера оружия. При успехе оружие наносит +1d6 урона серебром за каждые 3 пункта свыше сложности, но не более 5d6. При провале оружие ломается.
            <br><br>
            Для серебрения одноручного оружия требуется 2 слитка серебра, двуручного — 4 слитка серебра, и 1 слиток уйдёт на серебрение 10 или менее стрел или арбалетных болтов.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Прицельный удар (Рем)</strong><br>
            Ремесленник может совершить проверку способности <strong>Прицельный удар</strong> со СЛ, равной СЛ Изготовления предмета, чтобы найти в нём изъян. На осмотр предмета уходит 1 раунд, но это позволяет ремесленнику совершить прицельную атаку со штрафом −6, чтобы нанести разрушающий урон оружию или броне, равный результату броска шестигранных костей в количестве, равном значению <strong>Прицельного удара</strong>.
        </td>
    </tr>
</table>
</div>
')
         ) AS raw_data_ru(num, title, description)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
            ( 8, 'Craftsman', '
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
                <li>[BODY] - Endurance</li>
                <li>[BODY] - Physique</li>
                <li>[CRA] - Alchemy</li>
                <li>[CRA] - Crafting</li>
                <li>[DEX] - Athletics</li>
                <li>[EMP] - Fine Arts</li>
                <li>[EMP] - Persuasion</li>
                <li>[INT] - Business</li>
                <li>[INT] - Education</li>
                <li>[INT] - Streetwise</li>
            </ul>
        </td>
        <td>
            <strong>Gear</strong><br>
            <strong class="section-title">(Pick 5)</strong>
            <ul>
                <li>50 crowns of components</li>
                <li>Alchemy set</li>
                <li>Crafting tools</li>
                <li>Hourglass</li>
                <li>Iron long sword</li>
                <li>Lock</li>
                <li>Mace</li>
                <li>Merchant’s tools</li>
                <li>Small chest</li>
                <li>Tinker’s forge</li>
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
        <td class="header">Patch Job (CRA)</td>
    </tr>
    <tr>
        <td class="opt_content">
            A skilled craftsman can patch a weapon or armor well enough to keep it working and keep its wearer/wielder in the fight, whether that be by tying a bowstring back together, sharpening the edge of a broken blade, or nailing a plate over a cracked shield. By taking a turn to roll <strong>Patch Job</strong> at a DC equal to the item’s Crafting DC-3 a Craftsman can restore a broken shield or armor to half its full SP or restore a broken weapon to half its durability. Until fixed at a forge, a patched weapon does half its normal damage.
            <br><br>
            <strong>Too Many Patches</strong><br>
            A weapon, shield, or armor which has already been patched once can only be patched again 1 more time, and this patch only brings it to 1/4th SP/Durability (rounding down).
        </td>
    </tr>
</table>

<h3>Professional Skills</h3>
<table class="skills_branch_1">
    <tr>
        <td class="header">The Forge Master</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Extensive Catalogue (INT)</strong><br>
            A skilled Craftsman can keep a mental catalogue of diagrams in their head at all times. When a Craftsman has memorized as many diagrams as they can, they may roll <strong>Extensive Catalogue</strong> at DC:15 to memorize one more. There is no limit, but every 10 diagrams they have memorized adds 1 to the DC.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Journeyman (CRA)</strong><br>
            A Craftsman who begins crafting an item can roll <strong>Journeyman</strong> at a DC equal to the item’s crafting DC. If they succeed they add +1 DMG for weapons or +1 SP for armor for every 2 points they rolled above the DC. The maximum bonus they can give to DMG or SP is 5.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Master Crafting (CRA)</strong><br>
            Master Crafting allows a Craftsman to make items that are master grade. They can also roll a <strong>Master Crafting</strong> roll at any time at a DC equal to the item’s crafting DC to permanently grant armor resistance (their choice) or weapons a 50% bleeding or -2 Stun value based on damage type.
        </td>
    </tr>
</table>
<table class="skills_branch_2">
    <tr>
        <td class="header">The Alchemist</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Mental Pharmacy (INT)</strong><br>
            A skilled Craftsman can keep a mental catalogue of formulae in their head at all times. When a Craftsman has memorized as many formulae as they can, they may roll <strong>Mental Pharmacy</strong> at DC:15 to memorize one more. There is no limit, but every 10 formulae they have memorized adds 1 to the DC.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Double Dose (CRA)</strong><br>
            Any time a craftsman sets out to make an alchemical item they can make a <strong>Double Dose</strong> roll at a DCequal to the formula’s crafting DC. If they succeed they create two units of the formula with the ingredients of one. This applies to all items created with alchemy, including potions, oils, decoctions, and bombs.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Adaptation (CRA)</strong><br>
            Craftsmen can roll an <strong>Adaptation</strong> check (3 + the crafting DC) before making a witcher potion to lower its DC to avoid poisoning by 1 for every point they rolled over the crafting DC. If they fail, the potion comes out as poisonous as it normally would be. The DC to avoid poisoning can never be lower than 12.
        </td>
    </tr>
</table>
<table class="skills_branch_3">
    <tr>
        <td class="header">The Improviser</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Augmentation (CRA)</strong><br>
            A Craftsman can make an <strong>Augmentation</strong> roll at a DC listed in the Augmentation chart to augment a weapon or Armor with their crafting tools. This augmentation takes 3 rounds. While a forge isn’t required, it grants a +2 to the roll. A fumble results in the item taking damage equal to the fumble value.
            <br><br>
            <div style="display:inline-block;">
            <table class="table-small" border="1" cellspacing="0" cellpadding="4">
                <tr>
                    <th>Augmentation</th>
                    <th>DC</th>
                </tr>
                <tr>
                    <td><b>Weapons</b></td>
                    <td></td>
                </tr>
                <tr>
                    <td>Reinforced<br>+2 Reliability</td>
                    <td>14</td>
                </tr>
                <tr>
                    <td>Serration/Spikes<br>+25% Bleed</td>
                    <td>16</td>
                </tr>
                <tr>
                    <td>Lighten<br>+1 Accuracy</td>
                    <td>18</td>
                </tr>
                <tr>
                    <td><b>Armors</b></td>
                    <td></td>
                </tr>
                <tr>
                    <td>Reinforced<br>+2 SP</td>
                    <td>14</td>
                </tr>
                <tr>
                    <td>Camouflage<br>+1 Stealth</td>
                    <td>16</td>
                </tr>
                <tr>
                    <td>Studded<br>2 Damage to Grapplers</td>
                    <td>18</td>
                </tr>
            </table>
            </div>
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Silver Coating (CRA)</strong><br>
            A Craftsman can coat an existing weapon in silver with a forge and a number of units of silver ingots based on the size of the weapon. The DC for this roll is 16. If you succeed, add +1d6 silver damage to a weapon per 3 points you rolled above the DC, up to 5d6. Failing the roll breaks the weapon.
            <br><br>
            <strong>Silver Coating</strong><br>
            Silver coating requires 2 ingots of silver for 1-handed weapons, 4 ingots of silver for 2-handed weapons, and 1 ingot of silver for up to 10 arrows or crossbow bolts
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Pinpoint (CRA)</strong><br>
            A Craftsman can roll <strong>Pinpoint</strong> with a DC equal an item’s crafting DC to search for a flaw in the item’s design. This takes 1 turn studying, but allows the Craftsman to make a targeted attack at a -6 to do ablation damage to the armor or weapon equal to half their <strong>Pinpoint</strong> value in 6-sided dice.
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
       ck_id('witcher_cc.rules.wcc_profession.craftsman') AS visible_ru_ru_id,
       jsonb_build_object(
           'title', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.title')::text),
           'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.description')::text)
       ) AS metadata
FROM raw_data
CROSS JOIN meta
ON CONFLICT (an_id) DO NOTHING;

-- Craftsman (pick 5)
-- 50 crowns of components - budget(50) - source_id = 'ingredients_craft', 'ingredients_alchemy'
-- Alchemy set - T105
-- Crafting tools - T107
-- Hourglass - T091
-- Iron long sword - W116
-- Lock - T053
-- Mace - W069
-- Merchant's tools - T102
-- Small chest - T023
-- Tinker's forge - T114

-- Эффекты: заполнение professional_gear_options
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o08' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.professional_gear_options'),
      jsonb_build_object(
        'tokens', 5,
        'items', jsonb_build_array('T105', 'T107', 'T091', 'W116', 'T053', 'W069', 'T102', 'T023', 'T114'),
        'bundles', jsonb_build_array()
      )
    )
  ) AS body;

-- Эффекты: стартовые деньги
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o08' AS an_an_id,
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

-- Эффекты: бюджет на алхимические ингредиенты (50) для магазина
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o08' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.money.alchemyIngredientsCrowns'),
      50
    )
  ) AS body;