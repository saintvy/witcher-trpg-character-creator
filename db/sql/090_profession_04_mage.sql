\echo '090_profession_04_mage.sql'
-- Вариант ответа: Маг

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_profession' AS qu_id
                , 'answer_options' AS entity)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
            ( 4, 'Маг',
'<div class="ddlist_option">
<table class="profession_table">
    <tr>
        <td>
            <strong>Энергия:</strong> 5<br><br>
            <strong>Магические способности:</strong>
            <ul>
                <li>5 заклинаний новичка</li>
                <li>1 ритуал новичка</li>
                <li>1 порча с низкой опасностью</li>
            </ul>
        </td>
        <td>
            <strong>Навыки</strong>
            <ul>
                <li>[Воля] - Наведение порчи</li>
                <li>[Воля] - Проведение ритуалов</li>
                <li>[Воля] - Сопротивление магии</li>
                <li>[Воля] - Сотворение заклинаний</li>
                <li>[Интеллект] - Образование</li>
                <li>[Интеллект] - Этикет</li>
                <li>[Ловкость] - Владение древковым оружием</li>
                <li>[Эмпатия] - Внешний вид</li>
                <li>[Эмпатия] - Соблазнение</li>
                <li>[Эмпатия] - Понимание людей</li>
            </ul>
        </td>
        <td>
            <strong>Снаряжение</strong><br>
            <strong class="section-title">(выберите 5)</strong>
            <ul>
                <li>Песочные часы (час)</li>
                <li>Набор для макияжа</li>
                <li>Поясная сумка</li>
                <li>Письменные принадлежности</li>
                <li>Ручное зеркальце</li>
                <li>Кинжал</li>
                <li>Посох</li>
                <li>Набедренные ножны</li>
                <li>Дневник</li>
                <li>Ингредиенты общей стоимостью 100 крон</li>
            </ul>
            <br><br><strong>Деньги</strong>
            <ul>
                <li>200 крон × 2d6</li>
            </ul>
        </td>
    </tr>
</table>

<h3>Определяющий навык</h3>
<table class="main_skill">
    <tr>
        <td class="header">Магические познания (Инт)</td>
    </tr>
    <tr>
        <td class="opt_content">
            Для того чтобы стать полноправным магом, способный к магии адепт должен пройти обучение в одной из магических академий. Маг может совершить проверку <strong>Магических познаний</strong>, если ему попадётся магический феномен, если он увидит незнакомое заклинание или захочет узнать ответ на какой-то теоретический вопрос. СЛ проверки определяется ведущим. При успехе маг узнаёт всё, что касается данного магического феномена. Проверка <strong>Магических познаний</strong> также может заменить проверку Внимания для обнаружения использованной магии и духов. 
        </td>
    </tr>
</table>
<h3>Профессиональные навыки</h3>
<table class="skills_branch_1">
    <tr>
        <td class="header">Политик</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Строить козни (Инт)</strong><br>
            Маг может совершить проверку способности <strong>Строить козни</strong> со СЛ, равной ИнтхЗ цели. При успехе маг получает бонус +3 к Обману, Соблазнению, Запугиванию или Убеждению против этой цели благодаря знаниям о её сильных и слабых сторонах. Бонус действует количество дней, равное значению способности <strong>Строить козни</strong>.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Сплетни (Инт)</strong><br>
            Потратив час времени, маг может совершить проверку <strong>Сплетен</strong> против ЭмпхЗ цели. При успехе маг успешно распускает слухи о цели по всему поселению, что снижает репутацию цели на половину значения <strong>Сплетен</strong> мага на количество дней, равное значению этой способности.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Полезные связи (Инт)</strong><br>
            Один раз за игру маг может совершить проверку <strong>Полезных связей</strong>, чтобы вспомнить о комто, кто мог бы быть полезен. Результат проверки необходимо распределить между четырьмя категориями, указанными в таблице на полях, чтобы понять, кто этот знакомый. То, как агент будет помогать магу, зависит от их отношений.
              <br>
              <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr>
                    <th colspan="2">Поселение</th>
                    <th colspan="2">Профессия</th>
                    <th colspan="2">Влиятельность</th>
                    <th colspan="2">Отношения</th>
                </tr>
                <tr>
                    <th>Значение</th> <th>Очки</th>
                    <th>Значение</th> <th>Очки</th>
                    <th>Значение</th> <th>Очки</th>
                    <th>Значение</th> <th>Очки</th>
                </tr>
                <tr>
                    <td>Деревня</td>     <td>3</td>
                    <td>Корчмарь</td> <td>3</td>
                    <td>Низкая</td>      <td>2</td>
                    <td>Шантаж</td>      <td>3</td>
                </tr>
                <tr>
                    <td>Посёлок</td>  <td>4</td>
                    <td>Ремесленник</td> <td>5</td>
                    <td>Средняя</td>  <td>3</td>
                    <td>Долг</td>  <td>5</td>
                </tr>
                <tr>
                    <td>Город</td>       <td>5</td>
                    <td>Стражник</td> <td>6</td>
                    <td>Высокая</td>     <td>5</td>
                    <td>Дружелюбие</td>     <td>6</td>
                </tr>
                <tr>
                    <td>Столица</td>  <td>10</td>
                    <td>Маг</td> <td>8</td>
                    <td></td>         <td></td>
                    <td>Роман</td>  <td>8</td>
                </tr>
                <tr>
                    <td></td>         <td></td>
                    <td>Дворянин</td> <td>10</td>
                    <td></td>         <td></td>
                    <td>Подчинение</td> <td>10</td>
                </tr>
              </table><br><br>
              Отношения с агентом показывают, насколько этот агент готов вам помогать. 
              <ul>
                <li>Полностью подчинённые существа помогут в любом случае.</li>
                <li>Те, с кем у вас роман, помогут практически во всём, пока вы поддерживаете романтические отношения.</li>
                <li>Дружелюбных агентов нужно убедить рискнуть ради вас.</li>
                <li>Должники окажут только одну услугу.</li>
                <li>Шантажируемые агенты сделают всё что угодно, но есть 50%-ный шанс, что они вас предадут.</li>
              </ul>
        </td>
    </tr>
</table>

<table class="skills_branch_2">
    <tr>
        <td class="header">Учёный</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Анализ (Инт)</strong><br>
            Потратив час на изучение алхимического состава, маг может совершить проверку <strong>Анализа</strong> со СЛ, равной СЛ Изготовления этого алхимического состава + 3. При успехе маг выводит и записывает формулу этого состава. СЛ создания предмета по воссозданной формуле на 3 пункта выше, но в итоге маг получает желаемый предмет.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Дистилляция (Рем)</strong><br>
            Маг может совершить проверку <strong>Дистилляции</strong> вместо Алхимии при изготовлении алхимического состава. При успехе маг создаёт порцию состава, действующую в полтора раза эффективнее обычной порции — это относится к длительности, урону или СЛ сопротивления на выбор мага. Округление эффекта всегда идёт вниз.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Мутация (Инт)</strong><br>
            Маг может потратить полный день и всю свою Выносливость на проведение экспериментов над целью, чтобы совершить бросок <strong>Мутации</strong> со СЛ, равной (28 -(Тел+ Воля цели)/ 2), и мутацией изменить цель. При успехе цель получает возможность использовать мутаген с подходящей малой мутацией. При провале цель оказывается при смерти и получает крупную мутацию.
            <br><br>
            Мутировать одного персонажа можно максимум два раза. Новые мутации применяются взамен имеющихся.
        </td>
    </tr>
</table>

<table class="skills_branch_3">
    <tr>
        <td class="header">Архимаг</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Укрепление связи</strong><br>
            По мере того как маг всё больше использует магию, его тело постепенно привыкает к течению магической энергии. Каждое очко, вложенное в способность <strong>Укрепление связи</strong>, повышает значение Энергии мага на 2. Когда эта способность достигает 10 уровня, максимальное значение Энергии мага равно 25. Эта способность развивается аналогично прочим навыкам.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Устойчивость к двимериту (Воля)</strong><br>
            Маг может совершить проверку <strong>Устойчивости к двимериту</strong> со СЛ 16 в любой момент, когда на него обычно может воздействовать двимерит. При успехе маг способен противостоять эффекту двимерита: у него кружится голова и он испытывает дискомфорт, но сохраняет половину Энергии и способность сотворять заклинания.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Усиление магии (Воля)</strong><br>
            Маг может обрести огромное могущество, проводя магическую энергию через разные фокусирующие магические предметы. Маг может совершить проверку <strong>Усиления магии</strong> со СЛ 16 перед сотворением заклинания или проведением ритуала. При успехе маг может провести магическую энергию через любые 2 фокусирующих предмета по своему выбору, снижая затраты Выносливости вдвое.
        </td>
    </tr>
</table>
</div>
'
         )) AS raw_data_ru(num, title, description)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
            ( 4, 'Mage',
'
<div class="ddlist_option">
<table class="profession_table">
    <tr>
        <td>
            <strong>Vigor:</strong> 5<br><br>
            <strong>Magical Perks:</strong>
            <ul>
                <li>5 Novice Spells</li>
                <li>1 Novice Ritual</li>
                <li>1 Low Danger Hex</li>
            </ul>
        </td>
        <td>
            <strong>Skills</strong>
            <ul>
                <li>[EMP] - Grooming &amp; Style</li>
                <li>[EMP] - Human Perception</li>
                <li>[EMP] - Seduction</li>
                <li>[INT] - Education</li>
                <li>[INT] - Social Etiquette</li>
                <li>[REF] - Staff/Spear</li>
                <li>[WILL] - Hex Weaving</li>
                <li>[WILL] - Resist Magic</li>
                <li>[WILL] - Ritual Crafting</li>
                <li>[WILL] - Spell Casting</li>
            </ul>
        </td>
        <td>
            <strong>Gear</strong><br>
            <strong class="section-title">(Pick 5)</strong>
            <ul>
                <li>100 crowns of components</li>
                <li>Belt pouch</li>
                <li>Dagger</li>
                <li>Garter sheath</li>
                <li>Hand mirror</li>
                <li>Hourglass</li>
                <li>Journal</li>
                <li>Makeup kit</li>
                <li>Staff</li>
                <li>Writing kit</li>
            </ul>
            <br><br><strong>Money</strong>
            <ul>
                <li>200 crowns × 2d6</li>
            </ul>
        </td>
    </tr>
</table>

<h3>Defining Skill</h3>
<table class="main_skill">
    <tr>
        <td class="header">Magical Training (INT)</td>
    </tr>
    <tr>
        <td class="opt_content">
            To qualify as a Mage, a magically adept person must pass through the halls of one of the world’s magical academies and learn the fundamentals of the magical arts. A Mage can roll <strong>Magical Training</strong> whenever they encounter a magical phenomenon, an unknown spell, or a question of magical theory. The DC is set by the GM, and a success allows the Mage to recall everything there is to know about the phenomenon. <strong>Magical Training</strong> can also be rolled as a form of Awareness that detects magic that is in use, or specters.
        </td>
    </tr>
</table>
<h3>Professional Skills</h3>
<table class="skills_branch_1">
    <tr>
        <td class="header">The Politician</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Scheming (INT)</strong><br>
            A Mage can make a <strong>Scheming</strong> roll at a DC equal to a target’s INT×3. On success the Mage gets a +3 to Deceit, Seduction, Intimidation, or Persuasion against that target from their observations of how the target works. The bonus from this ability applies for a number of days equal to the Mage’s <strong>Scheming</strong> value.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Grape Vine (INT)</strong><br>
            A Mage can take 1 hour and make a <strong>Grape Vine</strong> roll against a target’s EMP×3. Success spreads rumors throughout a settlement or city, lowering the target’s reputation there by half your <strong>Grape Vine</strong> value for a number of days equal to your <strong>Grape Vine</strong> value.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Assets (INT)</strong><br>
            Once per game a Mage can make an <strong>Assets</strong> roll to remember an asset they ‘acquired’ some time ago. Take the total of your roll and distribute it between the 4 columns on the table in the sidebar to find out who you know. This asset will help you, but how much depends on their relationship with you.
              <br><table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr>
                    <th colspan="2">Settlement</th>
                    <th colspan="2">Profession</th>
                    <th colspan="2">Importance</th>
                    <th colspan="2">Relationship</th>
                </tr>
                <tr>
                    <th>Value</th> <th>Cost</th>
                    <th>Value</th> <th>Cost</th>
                    <th>Value</th> <th>Cost</th>
                    <th>Value</th> <th>Cost</th>
                </tr>
                <tr>
                    <td>Hamlet</td>     <td>3</td>
                    <td>Innkeep</td> <td>3</td>
                    <td>Low</td>      <td>2</td>
                    <td>Blackmailed</td>      <td>3</td>
                </tr>
                <tr>
                    <td>Town</td>  <td>4</td>
                    <td>Artisan</td> <td>5</td>
                    <td>Average</td>  <td>3</td>
                    <td>Indebted</td>  <td>5</td>
                </tr>
                <tr>
                    <td>City</td>       <td>5</td>
                    <td>Guard</td> <td>6</td>
                    <td>High</td>     <td>5</td>
                    <td>Friendly</td>     <td>6</td>
                </tr>
                <tr>
                    <td>Capital</td>  <td>10</td>
                    <td>Mage</td> <td>8</td>
                    <td></td>         <td></td>
                    <td>Romanced</td>  <td>8</td>
                </tr>
                <tr>
                    <td></td>         <td></td>
                    <td>Noble</td> <td>10</td>
                    <td></td>         <td></td>
                    <td>Enthralled</td> <td>10</td>
                </tr>
              </table>
            <br><br>
            Your relationship to an asset establishes how willing to help you they are.
            <ul>
                <li>Enthralled assets will help you with absolutely anything.</li>
                <li>Romanced assets will help you with almost anything as long as you reaffirm your romance.</li>
                <li>Friendly assets must be convinced to stick their necks out for you.</li>
                <li>Indebted assets will only do one thing for you.</li>
                <li>Blackmailed assets will do anything for you but there is a 50% chance that they will betray you.</li>
            </ul>
        </td>
    </tr>
</table>

<table class="skills_branch_2">
    <tr>
        <td class="header">The Scientist</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Reverse Engineer (INT)</strong><br>
            By taking 1 hour to study an alchemical solution a Mage can roll <strong>Reverse Engineer</strong> at a DC equal to the Crafting DC for the alchemical item +3. Success allows them to reverse-engineer and write down the item’s formula. This formula is 3 points harder to craft, but reliably creates the desired item.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Distillation (CRA)</strong><br>
            A Mage can roll <strong>Distillation</strong> instead of Alchemy when creating an alchemical solution. Success at this roll creates a dose of that solution that has half again the effect that they would normally have, either in duration, damage, or resistance DC (your choice). Always round down when increasing.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Mutate (INT)</strong><br>
            A mage can spend all of their stamina and a full day experimenting on a subject to roll <strong>Mutate</strong> at a DC equal to (28 − (subject’s BODY + WILL)/2) to mutate the subject. Success grants the subject use of the Mutagen with the appropriate minor mutation. Failure throws the subject into Death State and inflicts the larger mutation.
            <br><br>
            An individual can only be mutated twice. Further mutations will replace existing ones.
        </td>
    </tr>
</table>

<table class="skills_branch_3">
    <tr>
        <td class="header">The Arch Mage</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>In Touch</strong><br>
            As a Mage utilizes magic more and more, their body becomes more used to the flow. Every point a Mage has in <strong>In Touch</strong> grants +2 points to Vigor threshold. When this ability reaches level 10 your maximum Vigor threshold becomes 25. This skill can be trained, like other skills.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Immutable (WILL)</strong><br>
            A Mage can roll <strong>Immutable</strong> at DC:16 whenever they would normally be affected by dimetrium. Success means that the Mage mostly shrugs off the dimetrium. They are still somewhat dizzy and uncomfortable but retain half of their total Vigor threshold and can perform magic.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Expanded Magic (WILL)</strong><br>
            By channelling magic through various magical foci a Mage can wield incredible power. A Mage can roll <strong>Expanded Magic</strong> before attempting to cast a spell or ritual, at a DC of 16. On success the mage can channel the spell or ritual through any 2 of their foci they choose, reducing the Stamina cost twice.
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

-- Mage (pick 5)
-- 100 crowns of components - budget(100) - source_id = 'ingredients_craft', 'ingredients_alchemy'
-- Belt pouch - T012
-- Dagger - W082
-- Garter sheath - T020
-- Hand mirror - T048
-- Hourglass - T091
-- Journal - T060
-- Makeup kit - T049
-- Staff - W157
-- Writing kit - T115

-- Эффекты: заполнение professional_gear_options
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o04' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.professional_gear_options'),
      jsonb_build_object(
        'tokens', 5,
        'items', jsonb_build_array('T012', 'W082', 'T020', 'T048', 'T091', 'T060', 'T049', 'W157', 'T115'),
        'bundles', jsonb_build_array()
      )
    )
  ) AS body;

-- Эффекты: стартовые деньги
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o04' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.money.crowns'),
      jsonb_build_object(
        '*',
        jsonb_build_array(
          200,
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

-- Эффекты: бюджет на алхимические ингредиенты (для теста распределения бюджетов в магазине 091_shop.sql)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o04' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.money.alchemyIngredientsCrowns'),
      100
    )
  ) AS body;