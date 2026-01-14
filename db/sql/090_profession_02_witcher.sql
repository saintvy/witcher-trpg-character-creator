\echo '090_profession_02_witcher.sql'
-- Вариант ответа: Ведьмак

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_profession' AS qu_id
                , 'answer_options' AS entity)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
            ( 2, 'Ведьмак', '
<div class="ddlist_option">
<table class="profession_table">
    <tr>
        <td>
            <strong>Энергия:</strong> 2<br><br>
            <strong>Магические способности:</strong><br>
            <strong class="section-title">(Все базовые знаки)</strong>
            <ul>
                <li>Аксий</li>
                <li>Аард</li>
                <li>Квен</li>
                <li>Игни</li>
                <li>Ирден</li>
            </ul>
        </td>
        <td>
            <strong>Навыки</strong>
            <ul>
                <li>[Воля] - Сотворение заклинаний</li>
                <li>[Интеллект] - Внимание</li>
                <li>[Интеллект] - Выживание в дикой природе</li>
                <li>[Интеллект] - Дедукция</li>
                <li>[Ловкость] - Атлетика</li>
                <li>[Ловкость] - Скрытность</li>
                <li>[Реакция] - Верховая езда</li>
                <li>[Реакция] - Владение мечом</li>
                <li>[Реакция] - Уклонение / Изворотливость</li>
                <li>[Ремесло] - Алхимия</li>
            </ul>
        </td>
        <td>
            <strong>Снаряжение</strong><br>
            <strong class="section-title">(выберите 2)</strong>
            <ul>
                <li>Инструменты алхимика</li>
                <li>Лошадь</li>
                <li>Метательные ножи ×5</li>
                <li>Ручной арбалет</li>
                <li>Двуслойный гамбезон</li>
            </ul>
            <br><strong>Особое снаряжение</strong>
            <ul>
                <li>Ведьмачий медальон</li>
                <li>Стальной ведьмачий меч</li>
                <li>Серебряный ведьмачий меч</li>
                <li>Формула эликсира ×2</li>
                <li>Формула масла ×2</li>
                <li>Формула отвара</li>
            </ul>
        </td>
    </tr>
</table>

<h3>Определяющий навык</h3>
<table class="main_skill">
    <tr>
        <td class="header">Подготовка ведьмака (Инт)</td>
    </tr>
    <tr>
        <td class="opt_content">
            Большинство ведьмаков проводят детство и юность в крепости, корпя над пыльными томами и проходя чудовищные боевые тренировки. Многие говорят, что главное оружие ведьмака — это знания о чудовищах и умение найти выход из любой ситуации. Находясь в опасной среде или на пересечённой местности, ведьмак может снизить соответствующие штрафы на половину значения своего навыка <strong>Подготовка ведьмака</strong> (минимум 1). <strong>Подготовку ведьмака</strong> также можно использовать в любой ситуации, где понадобился бы навык <strong>Монстрология</strong>. 
        </td>
    </tr>
</table>

<h3>Профессиональные навыки</h3>

<table class="skills_branch_1">
    <tr>
        <td class="header">Магический клинок</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Медитация</strong><br>
            Ведьмак может войти в медитативный транс, что позволяет ему получить все преимущества сна, но при этом сохранять бдительность. Во время медитации ведьмак считается находящимся в сознании для того, чтобы заметить что-либо в радиусе в метрах, равном удвоенному значению его <strong>Медитации</strong>.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Магический источник</strong><br>
            По мере того как ведьмак всё больше использует знаки, его тело постепенно привыкает к течению магической энергии. Каждые 2 очка, вложенные в способность <strong>Магический источник</strong>, повышают значение Энергии ведьмака на 1. Когда эта способность достигает 10 уровня, максимальное значение Энергии ведьмака становится равно 7. Эта способность развивается аналогично прочим навыкам.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Гелиотроп (Воля)</strong><br>
            Когда ведьмак становится целью заклинания, инвокации или порчи, он может совершить проверку способности <strong>Гелиотроп</strong>, чтобы попытаться отменить эффект. Он должен выкинуть результат, который больше либо равен результату его противника, а также потратить количество Выносливости, равное половине Выносливости, затраченной на сотворение магии.
        </td>
    </tr>
</table>

<table class="skills_branch_2">
    <tr>
        <td class="header">Мутант</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Крепкий желудок</strong><br>
            За годы употребления ядовитых ведьмачьих эликсиров ведьмаки привыкают к токсинам. Ведьмак может выдержать отвары и эликсиры суммарной токсичностью на 5% больше за каждые 2 очка, вложенные в способность <strong>Крепкий желудок</strong>. Эта способность развивается аналогично прочим навыкам. На 10 уровне максимальная токсичность для ведьмака равна 150%.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Ярость</strong><br>
            Будучи отравленным, ведьмак впадает в ярость и наносит дополнительно 1 урон в ближнем бою за каждый уровень <strong>Ярости</strong>. В этом состоянии единственная цель ведьмака — добраться до безопасного места или убить отравителя. Действие <strong>Ярости</strong> заканчивается одновременно с действием яда. Ведьмак может попытаться избавиться от <strong>Ярости</strong> раньше, совершив проверку Стойкости со СЛ 15.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Трансмутация (Тел)</strong><br>
            Принимая отвар, ведьмак может совершить проверку <strong>Трансмутации</strong> со СЛ 18. При успехе тело ведьмака принимает в себя несколько больше мутагена, чем обычно, что позволяет получить бонус в зависимости от принятого отвара (см. таблицу на полях). Длительность действия отвара уменьшается вдвое. Дополнительные мутации слишком малы, чтобы их заметить.
            <br><br>
            <div style="display:inline-block;">
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr>
                    <th>Отвар</th>
                    <th>Эффект</th>
                </tr>
                <tr>
                    <td><b>Главоглаз</b></td>
                    <td>Любой, кто контактирует с вашей слюной, имеет 50%-ный шанс отравиться.</td>
                </tr>
                <tr>
                    <td><b>Накер</b></td>
                    <td>Ваши ноги становятся сильнее, и значение Прж увеличивается на 3 м.</td>
                </tr>
                <tr>
                    <td><b>Полуденница</b></td>
                    <td>Ваши глаза меняются, и уровень освещения на вас больше не влияет.</td>
                </tr>
                <tr>
                    <td><b>Катакан</b></td>
                    <td>Ваши надпочечники меняются, позволяя восстанавливать 3 ПЗ, когда вы наносите урон.</td>
                </tr>
                <tr>
                    <td><b>Виверна</b></td>
                    <td>Ваши мускулы становятся сильнее, что даёт +5 к Скор, что также влияет на Бег.</td>
                </tr>
                <tr>
                    <td><b>Тролль</b></td>
                    <td>Ваше тело и кости становятся крепче. Вы наносите дополнительно 1d6 физического урона.</td>
                </tr>
                <tr>
                    <td><b>Бес</b></td>
                    <td>Ваши глаза незаметно меняются, взгляд становится зачаровывающим. Вы получаете +4 к Харизме, Соблазнению и Убеждению.</td>
                </tr>
                <tr>
                    <td><b>Кладбищенская баба</b></td>
                    <td>Ваше тело незаметно меняется, позволяя получить 10 Вын при убийстве цели.</td>
                </tr>
                <tr>
                    <td><b>Волколак</b></td>
                    <td>Ваши челюсти становятся сильнее, а зубы слегка заостряются. Вы можете атаковать укусом, нанося 2d6 урона.</td>
                </tr>
                <tr>
                    <td><b>Грифон</b></td>
                    <td>Ваши глаза меняются, позволяя видеть куда дальше. Вы получаете +4 к Вниманию.</td>
                </tr>
            </table>
            </div>
        </td>
    </tr>
</table>

<table class="skills_branch_3">
    <tr>
        <td class="header">Убийца</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Отбивание стрел (Лвк)</strong><br>
            Ведьмак может совершить проверку этой способности со штрафом -3, чтобы отбить летящий физический снаряд. При отбивании ведьмак может выбрать цель в пределах 10 м. Эта цель должна совершить действие защиты против броска <strong>Отбивания стрел</strong> ведьмака, или она будет ошеломлена из-за попадания отбитого снаряда.
            <br><br>
            <b>Отбивание бомб.</b> Бомбы и другие атаки, поражающие зону, взрываются после отбивания. Если вторая цель уклоняется от атаки, совершите бросок по таблице разброса (см. стр. 152), чтобы определить, куда попадёт снаряд.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Быстрый удар (Реа)</strong><br>
            Закончив свой ход, ведьмак может потратить 5 очков Вын и совершить проверку <strong>Быстрого удара</strong> со СЛ, равной Реа противника хЗ. При успехе ведьмак совершает ещё одну атаку в этот раунд против этого противника, которая может включать в себя разоружение, подсечку и прочие атаки.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Вихрь (Реа)</strong><br>
            Потратив 5 очков Вын за раунд, ведьмак может закрутиться в <strong>Вихре</strong>, совершая каждый ход по одной атаке против всех, кто находится в пределах дистанции его меча. Проверка <strong>Вихря</strong> считается проверкой атаки. Находясь в <strong>Вихре</strong>, ведьмак может только поддерживать его, уклоняться и передвигаться на 2 метра за раунд. Любое другое действие или полученный удар прекращают <strong>Вихрь</strong>.
        </td>
    </tr>
</table>
</div>
')
         ) AS raw_data_ru(num, title, description)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
            ( 2, 'Witcher', '
<div class="ddlist_option">
<table class="profession_table">
    <tr>
        <td>
            <strong>Vigor:</strong> 2<br><br>
            <strong>Magical Perks:</strong><br>
            <strong class="section-title">(All Basic Signs)</strong>
            <ul>
                <li>Axii</li>
                <li>Aard</li>
                <li>Quen</li>
                <li>Igni</li>
                <li>Yrden</li>
            </ul>
        </td>
        <td>
            <strong class="section-title">Skills</strong>
            <ul>
                <li>[CRA] - Alchemy</li>
                <li>[DEX] - Athletics</li>
                <li>[DEX] - Stealth</li>
                <li>[INT] - Awareness</li>
                <li>[INT] - Deduction</li>
                <li>[INT] - Wilderness Survival</li>
                <li>[REF] - Dodge/Escape</li>
                <li>[REF] - Riding</li>
                <li>[REF] - Swordsmanship</li>
                <li>[WILL] - Spell Casting</li>
            </ul>
        </td>
        <td>
            <strong>Gear</strong><br>
            <strong class="section-title">(Pick 2)</strong>
            <ul>
                <li>Alchemy set</li>
                <li>Double woven gambeson</li>
                <li>Hand crossbow</li>
                <li>Horse</li>
                <li>Throwing knives ×5</li>
            </ul><br>
            <strong>Special</strong>
            <ul>
                <li>Decoction formulae</li>
                <li>Oil formulae ×2</li>
                <li>Potion formulae ×2</li>
                <li>Witcher medallion</li>
                <li>Witcher’s steel sword</li>
                <li>Witcher’s silver sword</li>
            </ul>
        </td>
    </tr>
</table>

<h3>Defining Skill</h3>
<table class="main_skill">
    <tr>
        <td class="header">Witcher Training (INT)</td>
    </tr>
    <tr>
        <td class="opt_content">
            Most of a Witcher’s early life is spent within the walls of their keep, studying huge, dusty tomes and going through hellish combat training. Many have argued that the Witcher’s greatest weapon is their knowledge of monsters and their adaptability in any situation. When in a hostile environment or difficult terrain, a Witcher can lessen the penalties by half their <strong>Witcher Training</strong> value (minimum 1). <strong>Witcher Training</strong> can also be used in any situation that you would normally use Monster Lore for.
        </td>
    </tr>
</table>

<h3>Professional Skills</h3>

<table class="skills_branch_1">
    <tr>
        <td class="header">The Spellsword</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Meditation</strong><br>
            A Witcher can enter a meditative trance which grants all the benefits of sleeping but allows them to remain vigilant. While meditating a Witcher is considered awake for the purpose of noticing anything within double their <strong>Meditation</strong> value in meters.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Magical Source</strong><br>
            As a Witcher uses signs more often their body becomes more used to the effort. For every 2 points a Witcher has in <strong>Magical Source</strong> they gain 1 points of Vigor threshold. When this ability reaches level 10, your maximum Vigor threshold becomes 7. This skill can be trained like other skills.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Heliotrope (WILL)</strong><br>
            When a Witcher is targeted by a spell, invocation, or hex they can roll <strong>Heliotrope</strong> to attempt to negate the effects. They must roll a Heliotrope roll that equals or beats the opponent’s roll and then expend an amount of Stamina equal to half the Stamina spent to cast the magic.
        </td>
    </tr>
</table>

<table class="skills_branch_2">
    <tr>
        <td class="header">The Mutant</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Iron Stomach</strong><br>
            After decades of drinking toxic witcher potions, witcher bodies adapt to the toxins. A witcher can endure 5% more toxicity from drinking potions and decoctions per 2 points they spend on <strong>Iron Stomach</strong>. This skill can be trained like other skills. At level 10, a witcher’s maximum toxicity is 150%.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Frenzy</strong><br>
            When poisoned, a witcher goes into a frenzy and deals an extra 1 melee damage per level in <strong>Frenzy</strong>. While in a <strong>Frenzy</strong>, your single goal is to get to a place of safety or kill the target that poisoned you. When the poison wears off, the <strong>Frenzy</strong> ends. You can attempt to end Frenzy early with a DC:15 Endurance roll.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Transmutation (BODY)</strong><br>
            When taking decoctions a Witcher can roll <strong>Transmutation</strong> at DC:18. A success allows their body to assimilate slightly more of the mutagen than usual and gain a bonus based on which decoction they take. The decoction lasts half as long as it normally would. The extra mutations are too subtle to spot.
            <br><br>
            <div style="display:inline-block;">
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr>
                    <th>Decoction</th>
                    <th>Effect</th>
                </tr>
                <tr>
                    <td><b>Arachas</b></td>
                    <td>Anyone who comes in contact with your saliva has a 50% chance of being poisoned.</td>
                </tr>
                <tr>
                    <td><b>Nekker</b></td>
                    <td>Your legs become stronger, raising your LEAP by 3m.</td>
                </tr>
                <tr>
                    <td><b>Noon Wraith</b></td>
                    <td>Your eyes change, and you aren’t affected by light conditions.</td>
                </tr>
                <tr>
                    <td><b>Katakan</b></td>
                    <td>Your adrenal glands change, allowing you to regenerate 3 HP when you deal damage.</td>
                </tr>
                <tr>
                    <td><b>Wyvern</b></td>
                    <td>Your muscles strengthen, giving you a +5 to SPD which carries over to RUN.</td>
                </tr>
                <tr>
                    <td><b>Troll</b></td>
                    <td>Your body hardens, and so do your bones. You do an extra 1d6 physical damage.</td>
                </tr>
                <tr>
                    <td><b>Fiend</b></td>
                    <td>Your eyes change imperceptibly and your gaze becomes subtly enthralling, giving a +4 to Charisma, Seduction, and Persuasion.</td>
                </tr>
                <tr>
                    <td><b>Grave Hag</b></td>
                    <td>Your body changes imperceptibly, allowing you to gain 10 STA by killing targets.</td>
                </tr>
                <tr>
                    <td><b>Werewolf</b></td>
                    <td>Your jaws strengthen and your teeth sharpen just a hair, giving you a bite attack of 2d6.</td>
                </tr>
                <tr>
                    <td><b>Griffin</b></td>
                    <td>Your eyes change, allowing you to see for a great distance, giving a +4 to Awareness.</td>
                </tr>
            </table>
            </div>
        </td>
    </tr>
</table>

<table class="skills_branch_3">
    <tr>
        <td class="header">The Slayer</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Parry Arrows (DEX)</strong><br>
            A Witcher can roll <strong>Parry Arrows</strong> at a −3 to deflect physical projectiles. When parrying, the Witcher can choose a target within 10m. That target must take a defense action against the Witcher’s <strong>Parry Arrows</strong> roll or be Staggered by the flying projectile.
            <br><br>
            <b>Parrying Bombs.</b> Bombs and other area of effect attacks detonate after the parry resolves. If the second target dodged the attack, roll on the Scatter Table to see where the attack lands.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Quick Strike (REF)</strong><br>
            After a Witcher takes their turn they can spend 5 STA and make a <strong>Quick Strike</strong> roll at a DC equal to their opponent’s REF×3. On success, they make another single strike in that round. This attack must be made against the opponent they rolled against, but can include disarms, trips, and other attacks.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Whirl (REF)</strong><br>
            By spending 5 STA per round, a witcher can enter a <strong>Whirl</strong>, where the witcher makes one attack against everyone within sword range each turn, with their <strong>Whirl</strong> roll acting as the attack roll. The witcher can only maintain this Whirl, dodge, and move 2m each round. Doing anything else or being hit halts the <strong>Whirl</strong>.
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

-- Witcher (pick 2)
-- Alchemy set - T105
-- Double woven gambeson - A014
-- Hand crossbow - W012
-- Horse - WT004
-- Throwing knives ×5 - W107 x5

-- Decoction formulae - budget(1) - R028, R029, R030, R031, R032, R033, R034, R035, R036, R037
-- Oil formulae ×2 - budget(2) - R016, R017, R018, R019, R020, R021, R022, R023, R024, R025, R026, R027
-- Potion formulae ×2 - budget(2) - R001, R002, R005, R007, R008, R009, R010, R011, R012, R013, R014, R015
-- Witcher medallion - T041
-- Witcher’s steel sword - budget(1) - W135, W136, W137, W138, W139, W140, W141
-- Witcher’s silver sword - budget(1) - W128, W129, W130, W131, W132, W133, W134