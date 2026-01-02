\echo '090_profession_05_man_at_arms.sql'
-- Вариант ответа: Воин

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_profession' AS qu_id
                , 'answer_options' AS entity)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
            ( 5, 'Воин', '
<div class="ddlist_option">
<table class="profession_table">
    <tr>
        <td>
            <strong>Энергия:</strong> 0<br><br>
            <strong>Магические способности:</strong><br>
            <strong class="section-title">Нет</strong>
        </td>
        <td>
            <strong>Боевые навыки</strong><br>
            <strong class="section-title">(Выберите 5)</strong>
            <ul>
                <li>[Ловкость] - Атлетика</li>
                <li>[Ловкость] - Владение древковым оружием</li>
                <li>[Ловкость] - Владение лёгкими клинками</li>
                <li>[Ловкость] - Владение мечом</li>
                <li>[Ловкость] - Стрельба из арбалета</li>
                <li>[Ловкость] - Стрельба из лука</li>
                <li>[Интеллект] - Тактика</li>
                <li>[Реакция] - Ближний бой</li>
                <li>[Реакция] - Борьба</li>
                <li>[Реакция] - Верховая езда</li>
                <li>Любой другой навык, одобренный вашим ГМ</li>
            </ul><br>
            <strong>Обычные навыки</strong>
            <ul>
                <li>[Воля] - Запугивание</li>
                <li>[Воля] - Храбрость</li>
                <li>[Интеллект] - Выживание в дикой природе</li>
                <li>[Реакция] - Уклонение / Изворотливость</li>
                <li>[Телосложение] - Сила</li>
            </ul>
        </td>
        <td>
            <strong>Снаряжение</strong><br>
            <strong class="section-title">(выберите 5)</strong>
            <ul>
                <li>Корд</li>
                <li>Копьё</li>
                <li>Боевой топор</li>
                <li>Метательные ножи ×5</li>
                <li>Наплечная сумка</li>
                <li>Кольчужный капюшон</li>
                <li>Бригантина</li>
                <li>Усиленные штаны</li>
                <li>Арбалет и арбалетные болты ×20</li>
                <li>Стальной баклер</li>
            </ul>
        </td>
    </tr>
</table>

<h3>Определяющий навык</h3>
<table class="main_skill">
    <tr>
        <td class="header">Крепче стали (Тел)</td>
    </tr>
    <tr>
        <td class="opt_content">
            Настоящие воины — будь то темерские «Синие полоски» или нильфгаардцы из бригады «Импера» — никогда не сдаются. Когда ПЗ воина опускается до 0 или ниже, он может совершить проверку навыка <strong>Крепче стали</strong> со СЛ, равной количеству отрицательных ПЗ х 2, чтобы продолжить сражаться. При провале воин оказывается при смерти. При успехе он может продолжать сражение, как если бы его ПЗ были ниже порога ранения. Получив урон, он вновь должен совершить проверку со СЛ, зависящей от его ПЗ.
        </td>
    </tr>
</table>

<h3>Профессиональные навыки</h3>

<!-- ВЕТКА 1 — Стрелок -->
<table class="skills_branch_1">
    <tr>
        <td class="header">Стрелок</td>
    </tr>

    <tr>
        <td class="opt_content">
            <strong>Максимальная дистанция (Лвк)</strong><br>
            Совершая дистанционную атаку, которая получила бы штраф за дистанцию, воин может уменьшить штраф на половину <strong>Максимальной дистанции</strong>. Он также может совершить проверку способности <strong>Максимальная дистанция</strong> со СЛ 16, чтобы атаковать цель на расстоянии до 3 дистанций своего оружия со штрафом -10. Этот штраф можно уменьшить, применив данную способность.
        </td>
    </tr>

    <tr>
        <td class="opt_content">
            <strong>Двойной выстрел (Лвк)</strong><br>
            Совершая дистанционную атаку из лука или метательным оружием, воин может совершить проверку способности <strong>Двойной выстрел</strong> вместо соответствующего оружию навыка. При попадании воин выпускает в цель два снаряда, повреждая две случайные части тела. Даже если атака была прицельной, второй снаряд попадёт в случайную часть тела.
        </td>
    </tr>

    <tr>
        <td class="opt_content">
            <strong>Точный прицел (Лвк)</strong><br>
            Если воин совершает критическую атаку дистанционным оружием, он может немедленно совершить проверку <strong>Точного прицела</strong> со СЛ, равной Лвк х 3 цели. При успехе воин добавляет значение способности <strong>Точный прицел</strong> к критическому броску. Эти очки влияют только на определение положения критического ранения.
       </td>
    </tr>
</table>

<!-- ВЕТКА 2 — Охотник за головами -->
<table class="skills_branch_2">
    <tr>
        <td class="header">Охотник за головами</td>
    </tr>

    <tr>
        <td class="opt_content">
            <strong>Ищейка (Инт)</strong><br>
            При выслеживании цели воин добавляет значение <strong>Ищейки</strong> к проверкам Выживания в дикой природе, чтобы найти след или пройти по нему. Если воин теряет след во время выслеживания с помощью этой способности, он может совершить проверку <strong>Ищейки</strong> со СЛ, определяемой ведущим, чтобы немедленно вновь найти след.
        </td>
    </tr>

    <tr>
        <td class="opt_content">
            <strong>Ловушка воина (Рем)</strong><br>
            Воин может совершить проверку способности <strong>Ловушка воина</strong>, чтобы установить самодельную ловушку в определённой зоне. Вид ловушки определите по таблице «Ловушки воина». Воин может создать ловушку только одного вида за раз. У каждой ловушки есть растяжка радиусом 2 метра, для её обнаружения требуется совершить проверку Внимания со СЛ, равной проверке <strong>Ловушки воина</strong>.
            <br><br>
            <table class="table-small" border="1" cellspacing="0" cellpadding="4">
                <tr><th>Вид ловушки</th><th>СЛ</th></tr>
                <tr>
                    <td><b>Опутывающая</b><br>
                        Жертва должна пройти проверку с определённой СЛ, чтобы высвободиться из захвата.
                    </td>
                    <td>14</td>
                </tr>
                <tr>
                    <td><b>Обезоруживающая</b><br>
                        Эта ловушка бьёт в районе плеч жертвы, выбивая у неё из рук оружие.
                    </td>
                    <td>18</td>
                </tr>
                <tr>
                    <td><b>Ослепляющая</b><br>
                        Эта ловушка бросает песок/грязь в глаза жертвы, ослепляя её.
                    </td>
                    <td>16</td>
                </tr>
                <tr>
                    <td><b>Подсекающая</b><br>
                        Эта ловушка бьёт невысоко над землёй, сбивая жертву с ног.
                    </td>
                    <td>14</td>
                </tr>
                <tr>
                    <td><b>Кровопускающая</b><br>
                        Эта ловушка забрасывает шипами, после попадания которых жертва начинает истекать кровью.
                    </td>
                    <td>18</td>
                </tr>
                <tr>
                    <td><b>Дезориентирующая</b><br>
                        Эта ловушка бьёт жертву по голове или в живот с достаточной силой, чтобы дезориентировать её.
                    </td>
                    <td>16</td>
                </tr>
            </table>
        </td>
    </tr>

    <tr>
        <td class="opt_content">
            <strong>Тактическое преимущество (Инт)</strong><br>
            Вместо перемещения воин может совершить проверку <strong>Тактического преимущества</strong>, чтобы оценить группу противников. Воин получает бонус +3 к атаке и защите на один раунд против всех врагов в пределах 10 метров, чья ЛвкхЗ меньше, чем результат проверки. Также эта способность позволяет понять, что собирается делать каждый из врагов, на которых она действует.
        </td>
    </tr>
</table>

<!-- ВЕТКА 3 — Потрошитель -->
<table class="skills_branch_3">
    <tr>
        <td class="header">Потрошитель</td>
    </tr>

    <tr>
        <td class="opt_content">
            <strong>Неистовство (Воля)</strong><br>
            Воин может совершить проверку <strong>Неистовства</strong> со СЛ, равной его ЭмпхЗ. При успехе воин становится невосприимчив к ужасу, влияющим на эмоции заклинаниям и Словесной дуэли на количество раундов, равное удвоенному значению <strong>Неистовства</strong>. В это время ярость застилает разум воина и он полностью отдаётся во власть инстинктов.
        </td>
    </tr>

    <tr>
        <td class="opt_content">
            <strong>Двуручник (Тел)</strong><br>
            Потратив 10 очков Вын и совершив проверку способности <strong>Двуручник</strong> со штрафом -3 против защиты противника, воин может совершить одну атаку, которая наносит двойной урон и считается пробивающей броню. Если его оружие уже пробивающее броню, оно становится улучшенным пробивающим броню. Улучшенное пробивающее броню оружие с этой способностью наносит 3d6 дополнительного урона.
        </td>
    </tr>

    <tr>
        <td class="opt_content">
            <strong>Игнорировать удар (Тел)</strong><br>
            Количество раз за игровую партию, равное Тел воина, он может потратить 10 очков Вын, чтобы немедленно совершить проверку способности <strong>Игнорировать удар</strong>, когда противник наносит ему критическое ранение. Если результат проверки выше проверки атаки противника, воин отменяет критическое ранение, как если бы атака противника не была критической.
        </td>
    </tr>
</table>
</div>
')
         ) AS raw_data_ru(num, title, description)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
            ( 5, 'Man At Arms', '
<div class="ddlist_option">
<table class="profession_table">
    <tr>
        <td>
            <strong>Vigor:</strong> 0<br><br>
            <strong>Magical Perks:</strong><br>
            <strong class="section-title">None</strong>
        </td>
        <td>
            <strong>Combat Skills</strong><br>
            <strong class="section-title">(pick 5)</strong>
            <ul>
                <li>[DEX] - Archery</li>
                <li>[DEX] - Athletics</li>
                <li>[DEX] - Crossbow</li>
                <li>[DEX] - Small Blades</li>
                <li>[DEX] - Staff/Spear</li>
                <li>[DEX] - Swordsmanship</li>
                <li>[REF] - Riding</li>
                <li>[REF] - Brawling</li>
                <li>[REF] - Melee</li>
                <li>[INT] - Tactics</li>
                <li>Any other skill your GM approves</li>
            </ul><br>
            <strong>Common Skills</strong>
            <ul>
                <li>[BODY] - Physique</li>
                <li>[INT] - Wilderness Survival</li>
                <li>[REF] - Dodge/Escape</li>
                <li>[WILL] - Courage</li>
                <li>[WILL] - Intimidation</li>
            </ul>
        </td>
        <td>
            <strong>Gear</strong><br>
            <strong class="section-title">(pick 5)</strong>
            <ul>
                <li>Armored trousers</li>
                <li>Battle axe</li>
                <li>Brigandine</li>
                <li>Chain coif</li>
                <li>Crossbow &amp; bolts ×20</li>
                <li>Kord</li>
                <li>Satchel</li>
                <li>Spear</li>
                <li>Steel buckler</li>
                <li>Throwing knives ×5</li>
            </ul>
        </td>
    </tr>
</table>

<h3>Defining Skill</h3>
<table class="main_skill">
    <tr>
        <td class="header">Tough As Nails (BODY)</td>
    </tr>
    <tr>
        <td class="opt_content">
            True Men At Arms like the Blue Stripes of Temeria and the Impera Brigade of Nilfgaard are hardened
            soldiers who never give in or surrender. When a Man At Arms falls to or below 0 Health, they can roll
            <strong>Tough As Nails</strong> at a DC equal to the number of negative Health times 2 to keep fighting.
            If they fail, they fall into death state as per usual. If they succeed they can keep fighting as if they
            were only at their Wound Threshold. Any damage forces them to make another roll against a DC based on
            their Health.
        </td>
    </tr>
</table>

<h3>Professional Skills</h3>

<!-- BRANCH 1 — The Marksman -->
<table class="skills_branch_1">
    <tr>
        <td class="header">The Marksman</td>
    </tr>

    <tr>
        <td class="opt_content">
            <strong>Extreme Range (DEX)</strong><br>
            When making a ranged attack that would take range penalties, a Man At Arms can lower the penalty by up to
            half their <strong>Extreme Range</strong> value. They can also make an <strong>Extreme Range</strong> roll
            (DC:16) to attack targets within 3 times the range of their weapon at a −10, which can be modified by
            <strong>Extreme Range</strong>.
        </td>
    </tr>

    <tr>
        <td class="opt_content">
            <strong>Twin Shot (DEX)</strong><br>
            When making a ranged attack with a thrown weapon or a bow, a Man At Arms can roll
            <strong>Twin Shot</strong> in place of their normal weapon skill. If they hit, they strike with two
            projectiles and damage two randomly rolled parts of the body. Even if the attack is aimed, the second
            projectile will hit a random location.
            <br><br>
            <b>Blocking Twin Shot.</b><br>
            A <strong>Twin Shot</strong> can be dodged with one action, and can be blocked as one action by a shield.
            Parrying a <strong>Twin Shot</strong> has a −6 penalty rather than a −3.
        </td>
    </tr>

    <tr>
        <td class="opt_content">
            <strong>Pin Point Aim (DEX)</strong><br>
            A Man At Arms who scores a critical with their ranged weapon can immediately roll
            <strong>Pin Point Aim</strong> at a DC equal to the target’s DEX×3. If they succeed, they add their
            <strong>Pin Point Aim</strong> value to their critical roll. These points only affect the location value
            of the Critical Wound.
        </td>
    </tr>
</table>

<!-- BRANCH 2 — The Bounty Hunter -->
<table class="skills_branch_2">
    <tr>
        <td class="header">The Bounty Hunter</td>
    </tr>

    <tr>
        <td class="opt_content">
            <strong>Bloodhound (INT)</strong><br>
            When tracking a target or trying to find a trail, a Man At Arms adds their
            <strong>Bloodhound</strong> value to <strong>Wilderness Survival</strong> rolls to find the trail or follow
            it. If the Man At Arms loses the trail while tracking with this ability, they can roll
            <strong>Bloodhound</strong> at a DC set by the GM to pick the trail back up immediately.
        </td>
    </tr>

    <tr>
        <td class="opt_content">
            <strong>Booby Trap (CRA)</strong><br>
            A Man At Arms can make a <strong>Booby Trap</strong> roll to set a makeshift trap in a specific area.
            See the Booby Trap table for traps that can be built. The Man At Arms can only build one type of trap at a
            time. Every trap has a 2m radius tripwire and requires an <strong>Awareness</strong> roll at a DC equal
            to your <strong>Booby Trap</strong> roll to spot.
            <br><br>
            <div style="display:inline-block;">
                <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                    <tr>
                        <th>Traps</th>
                        <th>DC</th>
                    </tr>
                    <tr>
                        <td><b>Snaring</b>: The trap has a DC the target must beat to free themselves from a Grapple.</td>
                        <td>14</td>
                    </tr>
                    <tr>
                        <td><b>Disarming</b>: The trap swings at shoulder height striking the target’s arm, knocking their weapon away.</td>
                        <td>18</td>
                    </tr>
                    <tr>
                        <td><b>Blinding</b>: The trap throws sand or dirt in the target’s eyes, blinding them.</td>
                        <td>16</td>
                    </tr>
                    <tr>
                        <td><b>Tripping</b>: The trap swings low and knocks the target’s legs out from under them, knocking them prone.</td>
                        <td>14</td>
                    </tr>
                    <tr>
                        <td><b>Bleeding</b>: The trap throws or swings spikes into the target, causing them to begin bleeding.</td>
                        <td>18</td>
                    </tr>
                    <tr>
                        <td><b>Stunning</b>: The trap clubs the target in the head or stomach with enough force to stun the target.</td>
                        <td>16</td>
                    </tr>
                </table>
            </div>
        </td>
    </tr>

    <tr>
        <td class="opt_content">
            <strong>Tactical Awareness (INT)</strong><br>
            Instead of moving, a Man At Arms can roll <strong>Tactical Awareness</strong> to gain insight into a whole
            group of opponents. The Man At Arms gains +3 to attack and defense rolls against every enemy within 10m
            whose DEX×3 is lower than that roll, for one round. This ability also tells the Man At Arms what each
            affected opponent is about to do.
        </td>
    </tr>
</table>

<!-- BRANCH 3 — The Reaver -->
<table class="skills_branch_3">
    <tr>
        <td class="header">The Reaver</td>
    </tr>

    <tr>
        <td class="opt_content">
            <strong>Fury (WILL)</strong><br>
            A Man At Arms can roll <strong>Fury</strong> at a DC equal to their EMP×3. If they succeed, the Man At Arms
            becomes immune to fear, spells that change emotions, and Verbal Combat for a number of rounds equal to
            their <strong>Fury</strong> value times 2. During this time, rage clouds their thinking and instinct takes
            over.
        </td>
    </tr>

    <tr>
        <td class="opt_content">
            <strong>Zweihand (BODY)</strong><br>
            By spending 10 STA and rolling <strong>Zweihand</strong> minus 3 against an opponent’s defense, a Man At
            Arms can make one attack which does double damage and has armor piercing. If the weapon already has armor
            piercing, it gains improved armor piercing. A weapon with improved armor piercing gains 3d6 damage.
        </td>
    </tr>

    <tr>
        <td class="opt_content">
            <strong>Shrug It Off (BODY)</strong><br>
            A number of times per game session equal to their BODY value, a Man At Arms can spend 10 STA to immediately
            roll <strong>Shrug It Off</strong> when an enemy strikes a Critical Wound on them. If their roll beats the
            enemy’s attack roll, they can negate the Critical Wound, taking the damage as if the enemy hadn’t rolled a
            critical.
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
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, metadata)
SELECT 'wcc_profession_o' || to_char(raw_data.num, 'FM00') AS an_id,
       meta.su_su_id,
       meta.qu_id,
       ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.title') AS label,
       raw_data.num AS sort_order,
       jsonb_build_object(
           'title', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.title')::text),
           'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.description')::text)
       ) AS metadata
FROM raw_data
CROSS JOIN meta
ON CONFLICT (an_id) DO NOTHING;

