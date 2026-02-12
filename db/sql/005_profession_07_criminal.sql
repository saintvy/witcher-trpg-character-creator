\echo '005_profession_07_criminal.sql'
-- Вариант ответа: Преступник

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_profession' AS qu_id
                , 'answer_options' AS entity)
-- Базовые правила видимости (профессия "Преступник" только для расы НЕ ведьмак)
, rule_parts AS (
  SELECT
    (SELECT r.body FROM rules r WHERE r.name = 'is_witcher' ORDER BY r.ru_id LIMIT 1) AS is_witcher_expr
)
, vis_rules AS (
  INSERT INTO rules (ru_id, name, body)
  SELECT
    ck_id('witcher_cc.rules.wcc_profession.criminal') AS ru_id,
    'wcc_profession_criminal' AS name,
    jsonb_build_object('!', rule_parts.is_witcher_expr) AS body
  FROM rule_parts
  ON CONFLICT (ru_id) DO NOTHING
  RETURNING ru_id
)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
            ( 7, 'Преступник', '
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
                <li>[Воля] - Запугивание</li>
                <li>[Интеллект] - Внимание</li>
                <li>[Интеллект] - Ориентирование в городе</li>
                <li>[Ловкость] - Атлетика</li>
                <li>[Ловкость] - Ловкость рук</li>
                <li>[Ловкость] - Скрытность</li>
                <li>[Реакция] - Владение лёгкими клинками</li>
                <li>[Ремесло] - Взлом замков</li>
                <li>[Ремесло] - Подделывание</li>
                <li>[Эмпатия] - Обман</li>
            </ul>
        </td>
        <td>
            <strong>Снаряжение</strong><br>
            <strong class="section-title">(выберите 5)</strong>
            <ul>
                <li>Шулерские кости</li>
                <li>Фонарь «бычий глаз»</li>
                <li>Потайной карман</li>
                <li>Воровские инструменты</li>
                <li>Наручные ножны</li>
                <li>Стилет</li>
                <li>Кастет</li>
                <li>Метательные ножи ×5</li>
                <li>Хлороформ</li>
                <li>Наплечная сумка</li>
            </ul>
            <br><br><strong>Деньги</strong>
            <ul>
                <li>100 крон × 2d6</li>
            </ul>
        </td>
    </tr>
</table>

<h3>Определяющий навык</h3>
<table class="main_skill">
    <tr>
        <td class="header">Профессиональная паранойя (Инт)</td>
    </tr>
    <tr>
        <td class="opt_content">
            Все преступники, будь то убийцы, воры, фальшивомонетчики или контрабандисты, обладают обострённым чутьём на опасность — фактически профессиональной паранойей, благодаря которой они избегают поимки. Когда преступник оказывается в пределах 10 метров от ловушки (включая экспериментальные ловушки, ловушки воина и засады), он может немедленно совершить проверку <strong>Профессиональной паранойи</strong> либо против СЛ обнаружения ловушки, либо против Скрытности засады, либо против заданной ведущим СЛ. Даже если преступник не заметит ловушки, чутьё всё равно ему подскажет, что тут что-то не так.
        </td>
    </tr>
</table>

<h3>Профессиональные навыки</h3>

<table class="skills_branch_1">
    <tr>
        <td class="header">Вор</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Присмотреться (Инт)</strong><br>
            Преступник может потратить час, чтобы побродить по улицам поселения и совершить проверку способности <strong>Присмотреться</strong> со СЛ, указанной в таблице на полях. При успехе преступник запоминает маршруты патрулей, расположение улиц и укрытий, что даёт ему бонус +2 к Скрытности в этом районе на количество дней, равное значению <strong>Присмотреться</strong>.
            <br><br>
            <div style="display: inline-block;">
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr> <th>Поселение</th> <th>СЛ</th> </tr>
                <tr> <td>Деревня</td>   <td>16</td> </tr>
                <tr> <td>Посёлок</td>   <td>18</td> </tr>
                <tr> <td>Город</td>     <td>20</td> </tr>
                <tr> <td>Столица</td>   <td>22</td> </tr>
            </table>
            </div>
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Повторный взлом (Инт)</strong><br>
            Когда преступник успешно вскрывает замок, он может совершить проверку <strong>Повторного взлома</strong> со СЛ, равной СЛ Взлома замков (для данного замка), чтобы запомнить положение штифтов. Это позволит ему открыть тот же замок без проверки навыка Взлома замков. Преступник может запомнить столько замков, сколько у него очков Инт. Всегда можно запомнить новый замок, забыв старый.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Залечь на дно (Инт)</strong><br>
            Один раз за игровую партию преступник может совершить проверку способности <strong>Залечь на дно</strong>, чтобы найти тайное убежище, где он может спрятаться на какое-то время. Результат проверки <strong>Залечь на дно</strong> распределите между тремя категориями по соответствующей таблице на полях. Тайное убежище существует, пока его не уничтожат, и преступник всегда может в него вернуться.
            <br><br>
            <div style="display: inline-block;">
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr>
                    <th colspan="2">Расположение</th>
                    <th colspan="2">Меры безопасности (несколько)</th>
                    <th colspan="2">Преимущества (несколько)</th>
                </tr>
                <tr>
                    <th>Значение</th>
                    <th>Стоимость</th>
                    <th>Значение</th>
                    <th>Стоимость</th>
                    <th>Значение</th>
                    <th>Стоимость</th>
                </tr>
                <tr>
                    <td>Неделя езды</td>
                    <td>3</td>
                    <td>Замки</td>
                    <td>1</td>
                    <td>Еда и вода</td>
                    <td>1</td>
                </tr>
                <tr>
                    <td>День езды</td>
                    <td>5</td>
                    <td>Скрытность</td>
                    <td>2</td>
                    <td>Хирургические инструменты</td>
                    <td>2</td>
                </tr>
                <tr>
                    <td>День пешком</td>
                    <td>8</td>
                    <td>2 охранника-разбойника</td>
                    <td>5</td>
                    <td>Кузница</td>
                    <td>3</td>
                </tr>
                <tr>
                    <td>В том же районе</td>
                    <td>10</td>
                    <td>5 ловушек (на выбор ведущего)</td>
                    <td>3</td>
                    <td>Инструменты алхимика</td>
                    <td>3</td>
                </tr>
            </table>
            </div>
        </td>
    </tr>
</table>

<table class="skills_branch_2">
    <tr>
        <td class="header">Атаман</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Уязвимость (Эмп)</strong><br>
            Преступник может совершить встречную проверку <strong>Уязвимости</strong> против навыка Обмана разумной цели, чтобы определить самую дорогую для цели вещь или личность. Это также даёт преступнику бонус +1 к Запугиванию за каждые 2 пункта свыше Обмана цели. Этот бонус действует до тех пор, пока уязвимость цели не изменится.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Взять на заметку (Воля)</strong><br>
            Преступник может совершить проверку способности <strong>Взять на заметку</strong> со СЛ, равной Эмп х 3 цели, чтобы оставить метку на её двери или что-то подобное. При успехе цель должна проходить проверку Харизмы, Убеждения или Запугивания, результат которой должен быть выше проверки <strong>Взять на заметку</strong> преступника, чтобы получить помощь или услугу у кого-либо в своём поселении.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Сбор (Воля)</strong><br>
            Один раз в день, потратив час, преступник может совершить проверку <strong>Сбора</strong> с установленной ведущим СЛ. За каждые 2 пункта свыше установленной СЛ преступник может завербовать 1 разбойника на количество дней, равное значению <strong>Сбора</strong>. Если у разбойника меньше половины ПЗ, он должен совершить бросок десятигранной кости, результат которого должен быть ниже значения Воли преступника; в противном случае разбойник убегает.
        </td>
    </tr>
</table>

<table class="skills_branch_3">
    <tr>
        <td class="header">Ассасин</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Прицеливание (Лвк)</strong><br>
            Преступник, не участвующий в бою, может потратить раунд, чтобы прицелиться, и совершить проверку <strong>Прицеливания</strong> со СЛ, равной Реа х 3 цели, чтобы получить бонус к следующей атаке, равный половине значения <strong>Прицеливания</strong>. Если преступника заметят после броска, но до атаки, бонус снижается в два раза.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Прямо в глаз (Лвк)</strong><br>
            Вместо атаки преступник может совершить проверку способности <strong>Прямо в глаз</strong>, чтобы временно ослепить цель. Для этого необходимо, чтобы преступник находился на дистанции ближнего боя; к удару при этом применяется штраф -3. При попадании цель получает 2d6 урона без модификаторов и ослепляется на количество раундов, равное значению <strong>Прямо в глаз</strong>.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Удар ассасина (Лвк)</strong><br>
            Устраивая засаду, преступник может совершить встречную проверку способности <strong>Удар ассасина</strong> против Внимания цели, чтобы скрыться после атаки. Эту способность можно использовать в любой ситуации, но к ней применяются штрафы в зависимости от освещённости и других условий. Если противников несколько, каждый может совершить по броску, чтобы попытаться заметить преступника.
            <br><br>
            <div style="display: inline-block;">
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr>
                    <th>Условие</th>
                    <th>Мод.</th>
                </tr>
                <tr> <td>Дистанция ближнего боя</td> <td>-3</td> </tr>
                <tr> <td>Светлое место</td> <td>-5</td> </tr>
                <tr> <td>В темноте</td> <td>+5</td> </tr>
                <tr> <td>При слабом свете</td> <td>+2</td> </tr>
                <tr> <td>В толпе</td> <td>+3</td> </tr>
                <tr> <td>В тихом месте</td> <td>-1</td> </tr>
                <tr> <td>Дальше 20 метров от цели</td> <td>+3</td> </tr>
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
            ( 7, 'Criminal', '
<div class="ddlist_option">
<table class="profession_table">
    <tr>
        <td>
            <strong>Vigor:</strong> 0<br><br>
            <strong>Magical Perks:</strong><br>
            <strong class="section-title">None</strong>
        </td>
        <td>
            <strong class="section-title">Skills</strong>
            <ul>
                <li>[CRA] - Forgery</li>
                <li>[CRA] - Pick Locks</li>
                <li>[DEX] - Athletics</li>
                <li>[DEX] - Sleight of Hand</li>
                <li>[DEX] - Stealth</li>
                <li>[EMP] - Deceit</li>
                <li>[INT] - Awareness</li>
                <li>[INT] - Streetwise</li>
                <li>[REF] - Small Blades</li>
                <li>[WILL] - Intimidate</li>
            </ul>
        </td>
        <td>
            <strong>Gear</strong><br>
            <strong class="section-title">(Pick 5)</strong>
            <ul>
                <li>Brass knuckles</li>
                <li>Bullseye lantern</li>
                <li>Chloroform</li>
                <li>Loaded dice</li>
                <li>Satchel</li>
                <li>Secret pocket</li>
                <li>Sleeve sheath</li>
                <li>Stiletto</li>
                <li>Thieves’ tools</li>
                <li>Throwing knives x5</li>
            </ul>
            <br><br><strong>Money</strong>
            <ul>
                <li>100 crowns × 2d6</li>
            </ul>
        </td>
    </tr>
</table>

<h3>Defining Skill</h3>
<table class="main_skill">
    <tr>
        <td class="header">Practiced Paranoia (INT)</td>
    </tr>
    <tr>
        <td class="opt_content">
            Whether they’re an assassin, a thief, a counterfeitter, or a smuggler, criminals all share a practiced paranoia that keeps them out of trouble. Whenever a Criminal comes within 10m of a trap (this includes experimental traps, Man at Arms booby traps, and ambushes) they immediately can make a <strong>Practiced Paranoia</strong> roll at either the DC to spot the trap, the ambushing party’s Stealth roll, or a DC set by the GM. Even if they don’t succeed in spotting the trap, they are still aware that something is wrong.
        </td>
    </tr>
</table>

<h3>Professional Skills</h3>

<table class="skills_branch_1">
    <tr>
        <td class="header">The Thief</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Case The Area (INT)</strong><br>
            A Criminal can take an hour to wander the streets of a Settlement and roll <strong>Case The Area</strong> against a DC in the Case The Area chart. If successful, the Criminal memorizes guard patterns, street layouts, and hiding spots for a +2 to Stealth in that area for a number of days equal to their <strong>Case The Area</strong> value.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Mental Key (INT)</strong><br>
            Whenever a Criminal successfully picks a lock they can roll <strong>Mental Key</strong> at a DC equal to the Lock Picking DC to memorize its tumbler positions. This allows the Criminal to open the lock without a Lock Picking roll. You can memorize as many locks as you have points in INT and can always replace one.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Go To Ground (INT)</strong><br>
            Once per session a Criminal can roll <strong>Go To Ground</strong> to find a hideout where they can lie low for a while. Take the total value of your <strong>Go To Ground</strong> roll and split the points between the 3 categories in the Go To Ground table in the sidebar. This hideout remains until destroyed, and you can always return to it.
            <br><br>
            <div style="display: inline-block;">
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr>
                    <th colspan="2">Area</th>
                    <th colspan="2">Security (Multiple)</th>
                    <th colspan="2">Perks (Multiple)</th>
                </tr>
                <tr>
                    <th>Value</th>
                    <th>Cost</th>
                    <th>Value</th>
                    <th>Cost</th>
                    <th>Value</th>
                    <th>Cost</th>
                </tr>
                <tr>
                    <td>A week’s ride</td> <td>3</td>
                    <td>Locks</td> <td>1</td>
                    <td>Food &amp; water</td> <td>1</td>
                </tr>
                <tr>
                    <td>A day’s ride</td> <td>5</td>
                    <td>Hidden</td> <td>2</td>
                    <td>Surgeon’s kit</td> <td>2</td>
                </tr>
                <tr>
                    <td>A day’s walk</td> <td>8</td>
                    <td>2 bandit guards</td> <td>5</td>
                    <td>A forge</td> <td>3</td>
                </tr>
                <tr>
                    <td>In the area</td> <td>10</td>
                    <td>5 traps (GMs choice)</td> <td>3</td>
                    <td>Alchemy set</td> <td>3</td>
                </tr>
            </table>
            </div>
        </td>
    </tr>
</table>

<table class="skills_branch_2">
    <tr>
        <td class="header">The Gang Boss</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Weak Spot (EMP)</strong><br>
            A Criminal can roll <strong>Weak Spot</strong> against a sentient target’s Deceit roll to identify the target’s most valued possession or person. This also grants the Criminal a +1 to Intimidate for every 2 points they rolled above the target’s Deceit. This Intimidation bonus lasts until something happens to change the target’s weak spot.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Marked Man (WILL)</strong><br>
            A Criminal can roll <strong>Marked Man</strong> at a DC equal the target’s EMP×3 to mark a target by carving a mark on their door, or the like. If successful the target must make a Charisma, Persuasion, or Intimidation check that beats your <strong>Marked Man</strong> roll to get any help or service from anyone in their settlement.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Rally (WILL)</strong><br>
            Once per day, by taking an hour,a Criminal can roll a <strong>Rally</strong> check against a DC set by the GM. For every 2 you roll above the DC they recruit 1 Bandit for a number of days equal to your <strong>Rally</strong> value. If a Bandit is knocked below half health they must roll under the Criminal’s WILL on a 10 sided die or flee.
        </td>
    </tr>
</table>

<table class="skills_branch_3">
    <tr>
        <td class="header">The Assassin</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Careful Aim (DEX)</strong><br>
            A Criminal who’s not in active combat and takes a round to aim can roll <strong>Careful Aim</strong> at a DC equal to their target’s REF×3 to gain a bonus on their next attack equal to half their <strong>Careful Aim</strong> value. Being spotted after making this roll but before attacking halves the bonus.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Eye Gouge (DEX)</strong><br>
            A Criminal can roll <strong>Eye Gouge</strong> in place of an attack to temporarily blind a target. <strong>Eye Gouge</strong> requires the Criminal to be in melee range and imposes a -3 to hit. However if it hits, the target takes an unmodified 2d6 damage and is blinded for a number of rounds equal to the <strong>Eye Gouge</strong> value.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Assassin’s Strike (DEX)</strong><br>
            When ambushing a target, a Criminal can make an <strong>Assassin’s Strike</strong> roll against the target’s Awareness roll to conceal themselves after an attack. This ability can be used in any situation but it imposes penalties based on light and cover conditions. Multiple opponents can each roll to spot the Criminal.
            <br><br>
            <div style="display: inline-block;">
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr>
                    <th>Condition</th>
                    <th>Mod.</th>
                </tr>
                <tr> <td>In melee range</td> <td>-3</td> </tr>
                <tr> <td>In light</td> <td>-5</td> </tr>
                <tr> <td>In darkness</td> <td>+5</td> </tr>
                <tr> <td>In dim light</td> <td>+2</td> </tr>
                <tr> <td>In a heavily crowded area</td> <td>+3</td> </tr>
                <tr> <td>In a silent area</td> <td>-1</td> </tr>
                <tr> <td>Beyond 20m of the target</td> <td>+3</td> </tr>
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
       ck_id('witcher_cc.rules.wcc_profession.criminal') AS visible_ru_ru_id,
       jsonb_build_object(
           'title', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.title')::text),
           'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.description')::text)
       ) AS metadata
FROM raw_data
CROSS JOIN meta
ON CONFLICT (an_id) DO NOTHING;

-- Criminal (pick 5)
-- Brass knuckles - W072
-- Bullseye lantern - T084
-- Chloroform - P062
-- Loaded dice - T067
-- Satchel - T016
-- Secret pocket - T018
-- Sleeve sheath - T021
-- Stiletto - W089
-- Thieves' tools - T113
-- Throwing knives ×5 - W107 x5

-- Эффекты: заполнение professional_gear_options
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_profession_shop.bundle.criminal_throwing_knives') AS id
     , 'questions' AS entity
     , 'metadata' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          ('ru', 'Метательные ножи ×5'),
          ('en', 'Throwing knives ×5')
       ) AS v(lang, text)
ON CONFLICT (id, lang) DO NOTHING;

INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o07' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.professional_gear_options'),
      jsonb_build_object(
        'tokens', 5,
        'items', jsonb_build_array('W072', 'T084', 'P062', 'T067', 'T016', 'T018', 'T021', 'W089', 'T113'),
        'bundles', jsonb_build_array(
          jsonb_build_object(
            'bundleId', 'criminal_throwing_knives',
            'displayName', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_profession_shop.bundle.criminal_throwing_knives')::text),
            'items', jsonb_build_array(
              jsonb_build_object(
                'sourceId', 'weapons',
                'itemId', 'W107',
                'quantity', 5
              )
            )
          )
        )
      )
    )
  ) AS body;

-- Эффекты: 1 жетон магических даров (если раса не полурослик и не дварф)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o07' AS an_an_id,
  jsonb_build_object(
    'when', '{"and":[{"!==":[{"var":"characterRaw.logicFields.race"},"Halfling"]},{"!==":[{"var":"characterRaw.logicFields.race"},"Dwarf"]}]}'::jsonb,
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.professional_gear_options.magic_gifts_tokens'),
      1
    )
  ) AS body;

-- Эффекты: стартовые деньги
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o07' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.money.crowns'),
      jsonb_build_object(
        '*',
        jsonb_build_array(
          100,
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
    ('intimidation'),         -- Запугивание
    ('awareness'),            -- Внимание
    ('streetwise'),           -- Ориентирование в городе
    ('athletics'),            -- Атлетика
    ('sleight_of_hand'),     -- Ловкость рук
    ('stealth'),             -- Скрытность
    ('small_blades'),        -- Владение лёгкими клинками
    ('pick_lock'),           -- Взлом замков
    ('forgery'),             -- Подделывание
    ('deceit')               -- Обман
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o07' AS an_an_id,
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
  ('case_joint', 1, 1),
  ('repeat_lockpick', 1, 2),
  ('lay_low', 1, 3),
  ('vulnerability', 2, 1),
  ('take_note', 2, 2),
  ('intimidating_presence', 2, 3),
  ('smuggler', 3, 1),
  ('false_identity', 3, 2),
  ('black_market', 3, 3)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o07' AS an_an_id,
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
  'wcc_profession_o07' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.professional.branches'),
      jsonb_build_array(
        ck_id('witcher_cc.wcc_skills.branch.вор.name')::text,
        ck_id('witcher_cc.wcc_skills.branch.атаман.name')::text,
        ck_id('witcher_cc.wcc_skills.branch.контрабандист.name')::text
      )
    )
  ) AS body;

-- Эффекты: добавление определяющего навыка в characterRaw.skills.defining
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o07' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.defining'),
      jsonb_build_object('id', 'professional_paranoia', 'name', ck_id('witcher_cc.wcc_skills.professional_paranoia.name')::text)
    )
  ) AS body;

-- i18n записи для названия профессии
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_profession' AS qu_id
                , 'character' AS entity)
, ins_profession AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o07' ||'.'|| meta.entity ||'.'|| 'profession') AS id
       , meta.entity, 'profession', v.lang, v.text
    FROM (VALUES
            ('ru', 'Преступник'),
            ('en', 'Criminal')
         ) AS v(lang, text)
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
-- Эффекты: установка профессии
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o07' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.profession'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o07' ||'.'|| meta.entity ||'.'|| 'profession')::text)
    )
  ) AS body
FROM meta
UNION ALL
SELECT
  'character' AS scope,
  'wcc_profession_o07' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.logicFields.profession'),
      'Criminal'
    )
  ) AS body;