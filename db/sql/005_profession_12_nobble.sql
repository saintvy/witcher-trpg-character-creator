\echo '005_profession_12_nobble.sql'
-- Вариант ответа: Аристократ

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_profession' AS qu_id
                , 'answer_options' AS entity)
-- Базовые правила видимости (профессия "Аристократ" только для расы НЕ ведьмак, и включен DLC exp_lal)
, ensure_rules AS (
  -- гарантируем, что is_dlc_exp_lal_enabled существует
  INSERT INTO rules (ru_id, name, body)
  VALUES
    (ck_id('witcher_cc.rules.is_dlc_exp_lal_enabled'), 'is_dlc_exp_lal_enabled', '{"in":["exp_lal",{"var":["dlcs",[]]}]}'::jsonb)
  ON CONFLICT (ru_id) DO UPDATE
  SET name = EXCLUDED.name,
      body = EXCLUDED.body
  RETURNING body AS exp_lal_expr
)
, rule_parts AS (
  SELECT
    (SELECT r.body FROM rules r WHERE r.name = 'is_witcher' ORDER BY r.ru_id LIMIT 1) AS is_witcher_expr,
    (SELECT er.exp_lal_expr FROM ensure_rules er LIMIT 1) AS exp_lal_expr
)
, vis_rules AS (
  INSERT INTO rules (ru_id, name, body)
  SELECT
    ck_id('witcher_cc.rules.wcc_profession.nobble') AS ru_id,
    'wcc_profession_nobble' AS name,
    jsonb_build_object(
      'and',
      jsonb_build_array(
        jsonb_build_object('!', rule_parts.is_witcher_expr),
        rule_parts.exp_lal_expr
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
            ( 12, 'Аристократ', '
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
                <li>Боевой навык (выберите 1)</li>
                <li>[Реакция] - Верховая езда</li>
                <li>[Эмпатия] - Внешний вид</li>
                <li>[Интеллект] - Внимание</li>
                <li>[Эмпатия] - Лидерство</li>
                <li>[Эмпатия] - Обман</li>
                <li>[Интеллект] - Образование</li>
                <li>[Эмпатия] - Понимание людей</li>
                <li>[Эмпатия] - Убеждение</li>
                <li>[Интеллект] - Этикет</li>
            </ul>
        </td>
        <td>
            <strong>Снаряжение</strong><br>
            <strong class="section-title">(выберите 5)</strong>
            <ul>
                <li>Дневник с замком</li>
                <li>Духи/одеколон</li>
                <li>Лошадь</li>
                <li>Модная одежда</li>
                <li>Набор для макияжа</li>
                <li>Невидимые чернила</li>
                <li>Письменные принадлежности</li>
                <li>Потайной карман</li>
                <li>Украшения</li>
                <li>Эсбода</li>
            </ul>
            <br><strong>Начальный капитал</strong>
            <ul>
                <li>200 крон × 2d6</li>
            </ul>
        </td>
    </tr>
</table>

<h3>Определяющий навык</h3>
<table class="main_skill">
    <tr>
        <td class="header">Известность (Эмп)</td>
    </tr>
    <tr>
        <td class="opt_content">
            Титул и статус делают аристократа заметной фигурой. Он добавляет <strong>Известность</strong> к своей репутации в родной стране и союзных с ней государствах. В нейтральной стране или в государстве, воюющем с его страной, этот бонус уменьшается вдвое.
        </td>
    </tr>
</table>

<h3>Профессиональные навыки</h3>

<table class="skills_branch_1">
    <tr>
        <td class="header">Дилетант</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Любительство</strong><br>
            Каждый раз, когда дворянин повышает уровень <strong>Любительства</strong>, он получает количество очков навыков, равное новому уровню плюс предыдущий уровень. Эти очки можно вложить в любые навыки один к одному, но не выше 4 уровня для каждого навыка. Для повышения сложного навыка на 1 уровень нужно потратить 2 очка.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>С видом знатока (Эмп)</strong><br>
            Успешно пройдя проверку этого навыка, аристократ навсегда убеждает собеседника, что разбирается в данной теме. Цель доверяет мнению аристократа, и тот получает бонус +3 к проверкам <strong>Обмана</strong> против этой цели, когда дело касается данной темы.
            <br><br>Если у того, кого вы пытаетесь убедить в своей эрудиции, более 4 очков соответствующего навыка, он может прибавить значение этого навыка к результату своей проверки <strong>Сопротивления убеждению</strong>.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Радушный хозяин (Эмп)</strong><br>
            Потратив день и количество денег, равное значению навыка <strong>Радушный хозяин</strong>×100, аристократ может устроить торжественный приём. На этом приёме он получает +3 к <strong>Харизме</strong>, <strong>Соблазнению</strong> и <strong>Убеждению</strong>. Все, кого аристократ пригласил, должны пройти встречную проверку <strong>Сопротивления убеждению</strong> против навыка аристократа <strong>Радушный хозяин</strong>, чтобы не явиться на приём.
            <br><br>На праздниках устраивают роскошный пир, игры и развлечения в зависимости от цели и места его проведения. Организуя праздник, аристократ может по желанию снизить своё значение навыка <strong>Радушный хозяин</strong>. Тогда на подготовку уйдёт меньше денег, но и СЛ отказа от приглашения будет ниже.
        </td>
    </tr>
</table>

<table class="skills_branch_2">
    <tr>
        <td class="header">Лидер</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Приказ (Воля)</strong><br>
            В качестве действия аристократ может приказать цели выполнить в её следующий ход то или иное задание. Если результат проверки <strong>Приказа</strong> выше СЛ, равной Воле × 3 цели, то цель получает бонус к одной проверке для этого задания, равный половине значения <strong>Приказа</strong> аристократа (минимум 1).
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Слуги</strong><br>
            Аристократ получает количество слуг, равное половине его навыка <strong>Слуги</strong> (минимум 1). Слуги стараются как можно лучше выполнять приказы аристократа, но для того, чтобы они рискнули жизнью, нужно убедить их или отдать приказ. Если по той или иной причине слуга не справляется со своими обязанностями, аристократ может попросить прислать кого-нибудь из поместья на замену.
            <br><br><strong>Слуги:</strong> Ваши слуги — простолюдины из персонажей ведущего. Слуг можно выбирать из следующего списка: ремесленники, рабочие, артисты и учёные. Слуги не получают О. У. и не могут улучшать свои навыки.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Поместье</strong><br>
            Аристократу принадлежит поместье, состоящее из главного здания, конюшни и надела земли. Аристократ сам решает, где расположено его поместье (в пределах разумного). Он управляет этими землями и получает с них доход. Все, кто живёт на этой земле, — его подданные.
            <br><br>
            <strong>Ключевые тезисы:</strong>
            <ul>
                <li>Преимущества поместья работают при физическом присутствии в нем; Для сбора ресурсов нужно его навещать.</li>
                <li>Делами управляет дворецкий (учёный).</li>
                <li>Слуг-рабочих: <strong>Поместье</strong> ×2; они ведут хозяйство и не идут в бой без уговоров.</li>
                <li>Планировку может придумать игрок, но менять нельзя, только дополнять пристройками.</li>
                <li>Слуги из дополнений не входят в лимит навыка <strong>Поместье</strong>.</li>
            </ul>
            <br>За каждый уровень навыка <strong>Поместье</strong> можно построить одну пристройку.
            <br>
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr><th>Дополнение</th><th>Игромеханика</th></tr>
                <tr><td>Казарма</td><td>Кирпичное здание с 10 стражниками с параметрами разбойников (повторно: +5). Охраняют поместье, не покидая его, и подчиняются приказам. Докладывают о странностях вам или дворецкому.</td></tr>
                <tr><td>Оранжерея</td><td>Дает 10 ед. растений в месяц каждого вида. 4 обычных/повседневных и 2 редких после строительства и любые другие, какие принесете (до 10 видов в сумме в одной оранжерее). В комплекте садовник с Выживанием в дикой природе 15. Можно строить несколько.</td></tr>
                <tr><td>Охотничьи угодья</td><td>Охота в дне пути от поместья приносит по 1d6 в час костей, перьев и кожи (максимум 3d6). В комплекте егерь с Выживанием в дикой природе 15.</td></tr>
                <tr><td>Личный лекарь</td><td>В поместье постоянно есть ученый-лекарь с <strong>Лечащим прикосновением 15</strong>.</td></tr>
                <tr><td>Тайные комнаты</td><td>За каждый уровень: 2 тайные комнаты и 2 коридора (соединяет до 3 комнат). Обнаружение входа: <strong>Внимание СЛ 16</strong>. Взлом дверей: <strong>СЛ 20</strong>. У вас есть ключ для каждого замка (они разные).</td></tr>
                <tr><td>Безопасность</td><td>Замки дверей и окон улучшаются до <strong>СЛ 18</strong> (стандарт - СЛ 15). Повторный выбор: до <strong>СЛ 20</strong>.</td></tr>
                <tr><td>Пыточная</td><td>Помещение с замками <strong>СЛ 18</strong>, +3 к <strong>Запугиванию</strong> внутри комнаты, но цель получает 2d6 урона. При словесной дуэли во время пытки дает дополнительно +2 к <strong>Запугиванию</strong> (то есть +5 вместо обычных +3).</td></tr>
                <tr><td>Мастерская</td><td>В ней есть любые крафтовые инструменты; +2 к проверкам выбранного ремесла. Можно строить несколько разных мастерских.</td></tr>
            </table>
        </td>
    </tr>
</table>

<table class="skills_branch_3">
    <tr>
        <td class="header">Рыцарь</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Непоколебимость</strong><br>
            Аристократ может прибавлять значение навыка <strong>Непоколебимость</strong> к своим проверкам <strong>Храбрости</strong> или <strong>Сопротивления убеждению</strong>. Если он успешно прошёл проверку <strong>Храбрости</strong> или <strong>Сопротивления убеждению</strong>, любой союзник, который был тому свидетелем, до конца столкновения получает бонус к собственной проверке <strong>Храбрости</strong> или <strong>Сопротивления убеждению</strong> в размере 1/2 <strong>Непоколебимости</strong> аристократа (минимум 1).
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Кавалерист (Эмп)</strong><br>
            Потратив час, аристократ может совершить проверку навыка <strong>Кавалерист</strong> против Воли × 3 скакуна, чтобы навсегда с ним подружиться. Когда на нём едет аристократ, у скакуна увеличивается модификатор управления на половину значения навыка <strong>Кавалерист</strong>. Также аристократ может снизить результат броска при потере управления на половину этого значения.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Смягчение броней (Реа)</strong><br>
            Если враг наносит аристократу критическое ранение, тот может немедленно совершить проверку <strong>Смягчения броней</strong> со СЛ, равной результату изначальной проверки атаки противника. При успехе критическое ранение отменяется, а броня на той части тела, по которой пришёлся удар, получает по 1d10 разрушающего урона за каждый уровень критического ранения.
            <br><br>Если аристократ успешно отменяет критическое ранение <strong>Смягчением броней</strong>, он также отменяет бонусный урон от критического ранения. Однако аристократ получает стандартный урон от оружия после того, как его броня выдержит урон.
        </td>
    </tr>
</table>
</div>
')
         ) AS raw_data_ru(num, title, description)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
            ( 12, 'Nobble', '
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
                <li>Awareness</li>
                <li>1 Combat Skill</li>
                <li>Deceit</li>
                <li>Education</li>
                <li>Grooming &amp; Style</li>
                <li>Human Perception</li>
                <li>Leadership</li>
                <li>Persuasion</li>
                <li>Riding</li>
                <li>Social Etiquette</li>
            </ul>
        </td>
        <td>
            <strong>Gear</strong><br>
            <strong class="section-title">(Pick 5)</strong>
            <ul>
                <li>Esboda</li>
                <li>Fashionable clothing</li>
                <li>Horse</li>
                <li>Invisible ink</li>
                <li>Jewelry</li>
                <li>Journal with a lock</li>
                <li>Makeup kit</li>
                <li>Perfume/cologne</li>
                <li>Secret pocket</li>
                <li>Writing kit</li>
            </ul>
            <br><strong>Starting Coin</strong>
            <ul>
                <li>200 crowns x 2d6</li>
            </ul>
        </td>
    </tr>
</table>

<h3>Defining Skill</h3>
<table class="main_skill">
    <tr>
        <td class="header">Notoriety (EMP)</td>
    </tr>
    <tr>
        <td class="opt_content">
            Nobility, whether earned by noble deeds or conferred by birth, grants a person a grandeur that must be acknowledged. Peasants may curse a noble''s name and mock them in the safety of their hovels but most dare not insult a noble to their face. A Noble adds their <strong>Notoriety</strong> value to their Reputation score when in their home country or a country allied with their homeland. If a Noble travels to a kingdom or territory that is actively at war with or neutral toward their homeland, they gain only half their <strong>Notoriety</strong> value.
        </td>
    </tr>
</table>

<h3>Professional Skills</h3>

<table class="skills_branch_1">
    <tr>
        <td class="header">The Dilettante</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Dabble</strong><br>
            Each time a Noble takes a rank in <strong>Dabble</strong>, they gain a pool of skill points equal to their new rank plus the previous rank. These points can be spent to gain or raise skill ranks at a one-to-one rate but cannot raise a skill rank above 4. When used to raise the rank of a Difficult Skill, 2 points must be spent to raise the skill by 1 rank.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Expert Guise (EMP)</strong><br>
            By rolling <strong>Expert Guise</strong> against a target''s Resist Coercion, the Noble can permanently convince a person of the Noble''s expertise in a specific subject. The target then defers to the Noble and the Noble gains a +3 to Deceit checks against the target when that specific topic is involved.
            <br><br>If the person you are trying to convince of your expertise has more than four points in an appropriate skill, they can add their skill value to their Resist Coercion check.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Host (EMP)</strong><br>
            By taking a day and spending an amount of money equal to their <strong>Host</strong> value times 100, a Noble can arrange a festive gathering. While at this gathering, the Noble gains a +3 to Charisma, Seduction, and Persuasion. Anyone the Noble invites must make a Resist Coercion check against the Noble''s <strong>Host</strong> check to not attend.
            <br><br>A festival is furnished with a full feast, games, and entertainment as appropriate for its function and location. If a Noble wishes, they can voluntarily lower their <strong>Host</strong> rank when putting on a festival. The event requires less money but the DC to refuse an invitation is based on the lowered <strong>Host</strong> rank.
        </td>
    </tr>
</table>

<table class="skills_branch_2">
    <tr>
        <td class="header">The Leader</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Command (WILL)</strong><br>
            As an action, a Noble can command a target to perform a specific task on their next turn. If the Noble''s <strong>Command</strong> check beats a DC equal to the target''s WILLx3, the target gains a bonus to one check involved in this task equal to one-half the Noble''s <strong>Command</strong> value (minimum 1).
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Servants</strong><br>
            A Noble gains a number of servants equal to half their <strong>Servants</strong> value (minimum 1). These subjects follow the Noble''s orders to the best of their ability but must be commanded or persuaded to risk their lives. If a servant can no longer serve for any reason, the Noble can request a new one from their household be sent.
            <br><br><strong>Servants:</strong> Your servants are Everyman NPCs. When you generate your Servants, you can use any combination of the following Everyman NPCs: Artisans, Laborers, Entertainers, or Scholars. Your Servants do not gain I.P. and cannot improve their skills.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Estate</strong><br>
            A Noble personally owns an estate that consists of a main house, a stable, and a parcel of land. The Noble decides where this estate is located (within reason). The Noble serves as the land''s manager and gains benefit from it. Anyone living on the land is their subject.
            <br><br>
            <strong>Key gameplay points:</strong>
            <ul>
                <li>The estate''s benefits work while you are physically present in it; to collect resources, you need to visit it.</li>
                <li>The estate is managed by a majordomo (Scholar).</li>
                <li>Servant laborers: <strong>Estate</strong> x2; they handle household work and do not go into battle without persuasion.</li>
                <li>The player can design the layout, but it cannot be changed, only expanded with additions.</li>
                <li>Servants from additions do not count toward the limit of the <strong>Estate</strong> skill.</li>
            </ul>
            <br>
            <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr><th>Addition</th><th>Gameplay</th></tr>
                <tr><td>Barracks</td><td>A brick building with 10 Guards using Bandit stats (repeat pick: +5). They protect the estate, do not leave it, obey your orders, and report anything suspicious to you or your majordomo.</td></tr>
                <tr><td>Greenhouse</td><td>Produces 10 units per month of each chosen plant type. After construction, choose 4 Everyday/Common and 2 Poor components; later you can add any components you bring back (up to 10 total types in one greenhouse). Includes a Gardener with Wilderness Survival 15. You can build multiple greenhouses.</td></tr>
                <tr><td>Hunting Grounds</td><td>Hunting within one day of travel from the estate yields 1d6 per hour of bones, feathers, and leather (maximum 3d6). Includes a Huntsmaster with Wilderness Survival 15.</td></tr>
                <tr><td>Personal Physician</td><td>A resident Scholar physician is always present at the estate with <strong>Healing Hands Base 15</strong>.</td></tr>
                <tr><td>Secret Rooms</td><td>Per level: 2 secret rooms and 2 passages (a passage can connect up to 3 rooms). Spotting an entrance: <strong>Awareness DC:16</strong>. Opening the door: <strong>Pick Lock DC:20</strong>. You have a separate key for each lock.</td></tr>
                <tr><td>Security</td><td>Door and window locks improve to <strong>Pick Lock DC:18</strong> (standard is DC:15). Taking this addition again raises them to <strong>DC:20</strong>.</td></tr>
                <tr><td>Torture Chamber</td><td>A chamber with <strong>DC:18</strong> locks, +3 to <strong>Intimidation</strong> inside the room, but each attempt deals 2d6 damage to the target. During Verbal Combat while torturing, it grants an additional +2 to <strong>Intimidation</strong> (for a total of +5 instead of the usual +3).</td></tr>
                <tr><td>Workshop</td><td>Contains all crafting tools; grants +2 to checks of the chosen craft. Multiple workshops of different specializations can be built.</td></tr>
            </table>
        </td>
    </tr>
</table>

<table class="skills_branch_3">
    <tr>
        <td class="header">The Knight</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Resolute</strong><br>
            A Noble can add their <strong>Resolute</strong> value to their Courage and Resist Coercion checks. If they succeed a Courage or Resist Coercion check, any ally who witnesses them do so gains a bonus on their own Courage or Resist Coercion check equal to one-half the Noble''s <strong>Resolute</strong> value (minimum 1) until the end of the scene.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Chevalier (EMP)</strong><br>
            By taking an hour, a Noble can make a <strong>Chevalier</strong> check against a mount''s WILLx3 to permanently bond with it. When being ridden by the Noble, the mount''s Control Modifier is raised by half the Noble''s <strong>Chevalier</strong> value. The Noble can also lower the result of a control loss by half this value.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Armored Buffer (REF)</strong><br>
            If an enemy scores a critical wound on a Noble, the Noble can immediately make an <strong>Armored Buffer</strong> check against a DC equal to the enemy''s original Attack Check. If the Noble succeeds, they can negate the critical wound by sacrificing the armor in the hit location. The armor suffers 1d10 ablation damage per level of the critical wound to the hit location.
            <br><br>If a Noble successfully negates a critical wound with <strong>Armored Buffer</strong>, they also negate the bonus damage from the critical wound. However, standard weapon damage applies to the Noble after their armor sustains damage.
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
       ck_id('witcher_cc.rules.wcc_profession.nobble') AS visible_ru_ru_id,
       jsonb_build_object(
           'title', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.title')::text),
           'description', jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM9900') ||'.'|| meta.entity ||'.description')::text)
       ) AS metadata
FROM raw_data
CROSS JOIN meta
ON CONFLICT (an_id) DO NOTHING;

-- Nobble (pick 5)
-- Bundle: locked journal - T060 + T052
-- Perfume/Cologne - T050
-- Horse - WT004
-- Stylish clothes - T007
-- Makeup set - T049
-- Invisible ink - P051
-- Writing kit - T115
-- Hidden pocket - T018
-- Jewelry - T038
-- Esboda - W146

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_profession_shop.bundle.nobble_locked_journal') AS id
     , 'questions' AS entity
     , 'metadata' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          ('ru', 'Дневник с замком'),
          ('en', 'Locked journal')
       ) AS v(lang, text)
ON CONFLICT (id, lang) DO NOTHING;

-- Эффекты: заполнение professional_gear_options
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o12' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.professional_gear_options'),
      jsonb_build_object(
        'tokens', 5,
        'items', jsonb_build_array('T050', 'WT004', 'T007', 'T049', 'P051', 'T115', 'T018', 'T038', 'W146'),
        'bundles', jsonb_build_array(
          jsonb_build_object(
            'bundleId', 'nobble_locked_journal',
            'displayName', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_profession_shop.bundle.nobble_locked_journal')::text),
            'items', jsonb_build_array(
              jsonb_build_object(
                'sourceId', 'general_gear',
                'itemId', 'T060',
                'quantity', 1
              ),
              jsonb_build_object(
                'sourceId', 'general_gear',
                'itemId', 'T052',
                'quantity', 1
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
  'wcc_profession_o12' AS an_an_id,
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
  'wcc_profession_o12' AS an_an_id,
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

-- Эффекты: добавление начальных навыков в characterRaw.skills.initial[] (без боевого навыка)
WITH skill_mapping (skill_name) AS ( VALUES
    ('riding'),               -- Верховая езда
    ('grooming_and_style'),   -- Внешний вид
    ('awareness'),            -- Внимание
    ('leadership'),           -- Лидерство
    ('deceit'),               -- Обман
    ('education'),            -- Образование
    ('human_perception'),     -- Понимание людей
    ('persuasion'),           -- Убеждение
    ('social_etiquette')      -- Этикет
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o12' AS an_an_id,
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.initial'),
      sm.skill_name
    )
  ) AS body
FROM skill_mapping sm;

-- Эффекты: добавление профессиональных навыков в characterRaw.skills.professional
WITH prof_skill_mapping (skill_id, branch_number, professional_number) AS ( VALUES
  ('dilettante', 1, 1),
  ('connoisseur', 1, 2),
  ('gracious_host', 1, 3),
  ('command', 2, 1),
  ('servants', 2, 2),
  ('estate', 2, 3),
  ('steadfastness', 3, 1),
  ('cavalier', 3, 2),
  ('armor_softening', 3, 3)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o12' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.professional.skill_' || sm.branch_number || '_' || sm.professional_number),
      jsonb_build_object('id', sm.skill_id, 'name', ck_id('witcher_cc.wcc_skills.' || sm.skill_id || '.name')::text)
    )
  ) AS body
FROM prof_skill_mapping sm;

-- Эффекты: массив UUID названий веток professional.branches[]
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o12' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.professional.branches'),
      jsonb_build_array(
        ck_id('witcher_cc.wcc_skills.branch.nobble.1.name')::text,
        ck_id('witcher_cc.wcc_skills.branch.nobble.2.name')::text,
        ck_id('witcher_cc.wcc_skills.branch.nobble.3.name')::text
      )
    )
  ) AS body;

-- Эффекты: добавление определяющего навыка в characterRaw.skills.defining
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o12' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.skills.defining'),
      jsonb_build_object('id', 'renown', 'name', ck_id('witcher_cc.wcc_skills.renown.name')::text)
    )
  ) AS body;

-- i18n записи для названия профессии
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_profession' AS qu_id
                , 'character' AS entity)
, ins_profession AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o12' ||'.'|| meta.entity ||'.'|| 'profession') AS id
       , meta.entity, 'profession', v.lang, v.text
    FROM (VALUES
            ('ru', 'Аристократ'),
            ('en', 'Nobble')
         ) AS v(lang, text)
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
-- Эффекты: установка профессии
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o12' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.profession'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| 'o12' ||'.'|| meta.entity ||'.'|| 'profession')::text)
    )
  ) AS body
FROM meta
UNION ALL
SELECT
  'character' AS scope,
  'wcc_profession_o12' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.logicFields.profession'),
      'Nobble'
    )
  ) AS body;
