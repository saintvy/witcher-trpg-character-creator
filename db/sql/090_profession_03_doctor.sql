\echo '090_profession_03_doctor.sql'
-- Вариант ответа: Медик

WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_profession' AS qu_id
                , 'answer_options' AS entity)
, raw_data AS (
  SELECT 'ru' AS lang, raw_data_ru.*
    FROM (VALUES
            ( 3, 'Медик',
'<div class="ddlist_option">
<table class="profession_table">
    <tr>
        <td>
            <strong>Энергия: </strong> 0<br><br>
            <strong>Магические способности:</strong><br>нет
        </td>
        <td>
            <strong>Навыки</strong>
            <ul>
                <li>[Воля] - Сопротивление убеждению</li>
                <li>[Воля] - Храбрость</li>
                <li>[Интеллект] - Выживание в дикой природе</li>
                <li>[Интеллект] - Дедукция</li>
                <li>[Интеллект] - Торговля</li>
                <li>[Интеллект] - Этикет</li>
                <li>[Ловкость] - Владение лёгкими клинками</li>
                <li>[Ремесло] - Алхимия</li>
                <li>[Эмпатия] - Понимание людей</li>
                <li>[Эмпатия] - Харизма</li>
            </ul>
        </td>
        <td>
            <strong>Снаряжение</strong><br>
            <strong class="section-title">(выберите 5)</strong>
            <ul>
                <li>Кровосвёртывающий порошок ×10</li>
                <li>Обеззараживающая жидкость ×10</li>
                <li>Обезболивающие травы ×10</li>
                <li>Хирургические инструменты</li>
                <li>Письменные принадлежности</li>
                <li>Песочные часы (час)</li>
                <li>Свечи ×10</li>
                <li>Одеяло</li>
                <li>Большая палатка</li>
                <li>Кинжал</li>
            </ul>
        </td>
    </tr>
</table>

<h3>Определяющий навык</h3>
<table class="main_skill">
    <tr>
        <td class="header">Лечащее прикосновение (Рем)</td>
    </tr>
    <tr>
        <td class="opt_content">
            Кто угодно может перевязать рану, но только у медика достаточно знаний, чтобы Лечение критических ранений Подробнее о лечении критических ранений см. на стр. 173. проводить сложные хирургические операции. Медик с навыком <strong>Лечащее прикосновение</strong> — единственный, кто способен вылечить критическое ранение. Для исцеления критического ранения медик должен успешно совершить несколько проверок <strong>Лечащего прикосновения</strong> — число их зависит от серьёзности критического ранения. СЛ проверки также зависит от серьёзности критического ранения. Помимо этого, <strong>Лечащее прикосновение</strong> можно использовать вместо проверки Первой помощи. 
        </td>
    </tr>
</table>
<h3>Профессиональные навыки</h3>
<table class="skills_branch_1">
    <tr>
        <td class="header">Хирург</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Диагноз (Инт)</strong><br>
            При возможности осмотреть раненое существо медик может совершить проверку <strong>Диагноза</strong> со СЛ, определяемой ведущим. При успехе он обнаруживает все критические ранения цели и узнаёт, сколько пунктов здоровья у неё осталось. Это также даёт бонус +2 ко всем проверкам <strong>Лечащего прикосновения</strong> для лечения этих ран.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Осмотр (Инт)</strong><br>
            Перед проверкой <strong>Лечащего прикосновения</strong> медик может потратить ход и совершить проверку <strong>Осмотра</strong> со СЛ, зависящей от серьёзности критического ранения. При успехе медик понимает природу ранения и за каждые 2 пункта проверки свыше СЛ (минимум 1) хирургическая операция займёт на 1 ход меньше.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Эффективная хирургия (Рем)</strong><br>
            Перед тем как начать лечить критическое ранение, медик может совершить проверку <strong>Эффективной хирургии</strong> со СЛ, равной СЛ проверки <strong>Лечащего прикосновения</strong>, необходимой для лечения данного ранения. При успехе медик зашивает раны столь искусно, что они исцеляются в два раза быстрее. Эту способность можно использовать при лечении как критических ранений, так и обычных.
        </td>
    </tr>
</table>

<table class="skills_branch_2">
    <tr>
        <td class="header">Травник</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Палатка лекаря (Рем)</strong><br>
            Палатка лекаря позволяет совершить проверку со СЛ, определяемой ведущим, чтобы создать укрытие с оптимальными условиями для лечения. Это требует 1 часа, но добавляет бонус +3 к совершённым внутри проверкам <strong>Лечащего прикосновения</strong>/Первой помощи и +2 к скорости исцеления любого, кто находится в палатке, на количество дней, равное значению <strong>Палатки лекаря</strong>.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Подручные средства (Инт)</strong><br>
            Медик может совершить проверку <strong>Подручных средств</strong> со СЛ, равной СЛ Изготовления определённого лечащего алхимического состава, чтобы заменить его чем-то, что у него есть в наличии. Проверка занимает 1 раунд, и её можно повторить при провале. <strong>Подручные средства</strong> весьма специфичны и действуют только на конкретную рану.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Растительное лекарство (Рем)</strong><br>
            Смешав алхимические субстанции, медик может создать растительное лекарство, которое даёт бонусы/эффекты в зависимости от состава (см. таблицу Растительные лекарства на полях). Каждое лекарство хранится максимум 3 дня, после истечения этого срока его нельзя использовать. Чтобы получить бонус, лекарство следует сжечь или разжевать; его хватает только на одно применение. Создание лекарства занимает 1 ход.
            <br><br>
            <div style="display: inline-block;">
              <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr>
                    <th>Лекарство</th>
                    <th>СЛ</th>
                </tr>
                <tr>
                    <td><b>Купорос + Ребис</b><br>
                        +15 ПЗ на 1 час
                    </td>
                    <td>18</td>
                </tr>
                <tr>
                    <td><b>Квебрит + Солнце</b><br>
                        Избавляет от боли на 1 час, уменьшая на 4 штрафы от критических ранений и состояния при смерти.
                    </td>
                    <td>14</td>
                </tr>
                <tr>
                    <td><b>Эфир + Аер</b><br>
                        Отменяет штрафы за слабое освещение на 1 час, но в 2 раза увеличивает штрафы за яркий свет.
                    </td>
                    <td>14</td>
                </tr>
                <tr>
                    <td><b>Фульгор + Киноварь</b><br>
                        +3 против Запугивания на 1 час
                    </td>
                    <td>15</td>
                </tr>
                <tr>
                    <td><b>Гидраген + Ребис</b><br>
                        +3 к Соблазнению на 1 час
                    </td>
                    <td>15</td>
                </tr>
                <tr>
                    <td><b>Эфир + Купорос</b><br>
                        +3 к Вниманию на 1 час
                    </td>
                    <td>15</td>
                </tr>
                <tr>
                    <td><b>Киноварь + Квебрит</b><br>
                        +15 к Выносливости на 1 час
                    </td>
                    <td>18</td>
                </tr>
                <tr>
                    <td><b>Фульгор + Солнце</b><br>
                        Погружает вас в подобную смерти кому на 1 час.
                    </td>
                    <td>18</td>
                </tr>
                <tr>
                    <td><b>Аер + Гидраген</b><br>
                        Позволяет без штрафов не спать ночь.
                    </td>
                    <td>17</td>
                </tr>
                <tr>
                    <td><b>Киноварь + Солнце</b><br>
                        +3 к Реакции на 10 раундов
                    </td>
                    <td>15</td>
                </tr>
              </table>
            </div>
        </td>
    </tr>
</table>

<table class="skills_branch_3">
    <tr>
        <td class="header">Анатом</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Кровавая рана (Инт)</strong><br>
            Нанося урон клинковым оружием, медик может совершить проверку способности <strong>Кровавая рана</strong> со СЛ 15. При успехе после этой атаки цель начинает истекать кровью со скоростью 1 урон за каждые 2 пункта свыше установленной СЛ за раунд. Кровотечение можно остановить только проверкой Первой помощи со СЛ, равной результату проверки <strong>Кровавой раны</strong>.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Практическая резня (Инт)</strong><br>
            Медикможет совершить проверку способности <strong>Практическая резня</strong> со СЛ, равной Тел х 3 противника, чтобы обычные и критические ранения противника исцелялись в два раза медленнее. Другие медики могут нейтрализовать этот эффект при помощи <strong>Эффективной хирургии</strong> и предметов, повышающих скорость исцеления обычных и критических ран.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Калечащая рана (Инт)</strong><br>
            Медик может совершить проверку способности <strong>Калечащая рана</strong> против защиты цели. Эта атака даёт штраф -6 к попаданию, но при успехе снижает Реакцию, Телосложение или Скорость цели на 1 пункт за каждые 3 пункта свыше броска защиты. Штраф можно снять, только совершив проверку <strong>Эффективной хирургии</strong> с результатом выше результата атаки медика.
        </td>
    </tr>
</table>
</div>
'
         )) AS raw_data_ru(num, title, description)
  UNION ALL
  SELECT 'en' AS lang, raw_data_en.*
    FROM (VALUES
            ( 3, 'Doctor', '
<div class="ddlist_option">
<table class="profession_table">
    <tr>
        <td>
            <strong>Vigor:</strong> 0<br>
            <strong>Magical Perks:</strong> None
        </td>
        <td>
            <strong>Skills</strong>
            <ul>
                <li>[CRA] - Alchemy</li>
                <li>[DEX] - Small Blades</li>
                <li>[EMP] - Charisma</li>
                <li>[EMP] - Human Perception</li>
                <li>[INT] - Business</li>
                <li>[INT] - Deduction</li>
                <li>[INT] - Social Etiquette</li>
                <li>[INT] - Wilderness Survival</li>
                <li>[WILL] - Courage</li>
                <li>[WILL] - Resist Coercion</li>
            </ul>
        </td>
        <td>
            <strong>Gear</strong><br>
            <strong class="section-title">(Pick 5)</strong>
            <ul>
                <li>Blanket</li>
                <li>Candles x10</li>
                <li>Clotting powder x10</li>
                <li>Dagger</li>
                <li>Hourglass</li>
                <li>Large tent</li>
                <li>Numbing herbs x10</li>
                <li>Sterilizing fluid x10</li>
                <li>Surgeon''s kit</li>
                <li>Writing kit</li>
            </ul>
        </td>
    </tr>
</table>

<h3>Defining Skill</h3>
<table class="main_skill">
    <tr>
        <td class="header">Healing Hands (CRA)</td>
    </tr>
    <tr>
        <td class="opt_content">
            Anyone can apply some ointment and wrap a bandage around a cut, but a Doctor has true medical training which allows them to perform complex surgeries. A Doctor with <strong>Healing Hands</strong> is the only person who can heal a critical wound. To heal critical wounds a doctor must make a number of successful <strong>Healing Hands</strong> rolls based on the severity of the critical wound. The DC of the roll is based on the severity of the critical wound as well. <strong>Healing Hands</strong> can also be used for any First Aid task.
        </td>
    </tr>
</table>
<h3>Professional Skills</h3>
<table class="skills_branch_1">
    <tr>
        <td class="header">The Surgeon</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Diagnose (INT)</strong><br>
            When able to look over a wounded person or monster, a Doctor can roll Diagnose at a DC determined by the GM. If they succeed they assess any Critical Wounds the subject has and learn how many Health Points it has left. This also gives a +2 to any Healing Hands checks to heal those wounds.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Analysis (INT)</strong><br>
            When about to perform a Healing Hands roll, a Doctor can take a turn to make an Analysis roll at a DC equal to the severity of the Critical Wound. If they succeed they gain insight into the wounds, and for every 2 they roll over the DC (minimum 1) the surgery takes 1 turn less.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Effective Surgery (CRA)</strong><br>
            Before starting to heal a Critical Wound a Doctor can make an Effective Surgery roll at a DC equal to the wound''s Healing Hands DC. If they succeed they treat the wounds so skilfully that they heal twice as fast. This ability can be used on critical wounds and can also be used on regular wounds.
        </td>
    </tr>
</table>

<table class="skills_branch_2">
    <tr>
        <td class="header">The Herbalist</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Healing Tent (CRA)</strong><br>
            Healing Tent allows a Doctor to roll against a DC set by the GM to create a covered area that provides an optimal medical environment. This takes 1 hour but adds +3 to Healing Hands/First Aid rolls inside, and +2 to the healing rate of anyone in the tent for a number of days equal to your Healing Tent value.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Improvisation (INT)</strong><br>
            A Doctor can make an Improvisation roll at a DC equal to the crafting DC for a specific medical alchemical item to substitute something else on hand for the same effect. This roll takes one round and if it is failed it can be made again. Improvisation is very specific and works only on this one injury.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Herbal Remedy (CRA)</strong><br>
            By mixing alchemical substances, a Doctor can create an herbal remedy that grants bonuses/effects based on what was put into it (see the Healing Remedy chart in the sidebar). Each remedy remains viable for 3 days and must be burned or chewed to provide the bonus, allowing only 1 use. Making a remedy takes 1 turn.
            <br><br>
            <div style="display: inline-block;">
              <table border="1" cellpadding="4" cellspacing="0" class="table-small">
                <tr>
                    <th>Remedy</th>
                    <th>DC</th>
                </tr>
                <tr>
                    <td><b>Vitriol + Rebis</b><br>
                        +15 Health for 1 hour.
                    </td>
                    <td>18</td>
                </tr>
                <tr>
                    <td><b>Quebrith + Sol</b><br>
                        Negates all pain for 1 hour lessening penalties from criticals and being near death by 4.
                    </td>
                    <td>14</td>
                </tr>
                <tr>
                    <td><b>Aether + Caelum</b><br>
                        Negates dim light penalties for an hour but doubles bright light penalties
                    </td>
                    <td>14</td>
                </tr>
                <tr>
                    <td><b>Fulgur + Vermillion</b><br>
                        +3 against Intimidation for 1 hour.
                    </td>
                    <td>15</td>
                </tr>
                <tr>
                    <td><b>Hydragenum + Rebis</b><br>
                        +3 to Seduction for 1 hour
                    </td>
                    <td>15</td>
                </tr>
                <tr>
                    <td><b>Aether + Vitriol</b><br>
                        +3 to Awareness for 1 hour
                    </td>
                    <td>15</td>
                </tr>
                <tr>
                    <td><b>Vermillion + Quebrith</b><br>
                        +15 Stamina for 1 hour
                    </td>
                    <td>18</td>
                </tr>
                <tr>
                    <td><b>Fulgur + Sol</b><br>
                        Puts you into a death-like coma for 1 hour
                    </td>
                    <td>18</td>
                </tr>
                <tr>
                    <td><b>Caelum + Hydragenum</b><br>
                        Allows you to stay awake all night with no penalties
                    </td>
                    <td>17</td>
                </tr>
                <tr>
                    <td><b>Vermillion + Sol</b><br>
                        +3 to Reflex for 10 rounds
                    </td>
                    <td>15</td>
                </tr>
              </table>
            </div>
        </td>
    </tr>
</table>

<table class="skills_branch_3">
    <tr>
        <td class="header">The Anatomist</td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Bleeding Wound (INT)</strong><br>
            A Doctor who does damage with a bladed weapon can make a Bleeding Wound roll against a DC of 15. On success, the attack causes bleeding at a rate of 1 point per 2 points rolled over the DC. The bleeding can only be stopped by a First Aid roll, at a DC equal to the Doctor''s Bleeding Wound roll.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Practical Carnage (INT)</strong><br>
            A Doctor can roll Practical Carnage against a DC equal to the opponent''s BODYx3 to cause the target''s wounds and critical wounds to heal half as fast. Other Doctors with the Effective Surgery skill and items that raise the healing rate of wounds and critical wounds can counteract the effect.
        </td>
    </tr>
    <tr>
        <td class="opt_content">
            <strong>Crippling Wound (INT)</strong><br>
            A Doctor can make a Crippling Wound roll against the target''s defense. This attack takes a -6 to hit but imposes a negative to the target''s REFLEX, BODY, or SPEED equal to 1 per 3 points above their defense roll. This negative can only be removed with an Effective Surgery roll that beats your attack roll.
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

-- Doctor (pick 5)
-- Blanket - custom T068
-- Candles x10 - T081
-- Clotting powder x10 - P048
-- Dagger - W082
-- Hourglass - T091
-- Large tent - T071
-- Numbing herbs x10 - P053
-- Sterilizing fluid x10 - P054
-- Surgeon''s kit - T111
-- Writing kit - T115

-- Эффекты: заполнение professional_gear_options
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_profession_shop.bundle.doctor_candles') AS id
     , 'questions' AS entity
     , 'metadata' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          ('ru', 'Свечи ×10'),
          ('en', 'Candles ×10')
       ) AS v(lang, text)
ON CONFLICT (id, lang) DO NOTHING;

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_profession_shop.bundle.doctor_clotting_powder') AS id
     , 'questions' AS entity
     , 'metadata' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          ('ru', 'Порошок для остановки крови ×10'),
          ('en', 'Clotting powder ×10')
       ) AS v(lang, text)
ON CONFLICT (id, lang) DO NOTHING;

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_profession_shop.bundle.doctor_numbing_herbs') AS id
     , 'questions' AS entity
     , 'metadata' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          ('ru', 'Обезболивающие травы ×10'),
          ('en', 'Numbing herbs ×10')
       ) AS v(lang, text)
ON CONFLICT (id, lang) DO NOTHING;

INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id('witcher_cc.wcc_profession_shop.bundle.doctor_sterilizing_fluid') AS id
     , 'questions' AS entity
     , 'metadata' AS entity_field
     , v.lang
     , v.text
  FROM (VALUES
          ('ru', 'Обеззараживающая жидкость ×10'),
          ('en', 'Sterilizing fluid ×10')
       ) AS v(lang, text)
ON CONFLICT (id, lang) DO NOTHING;

INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  'wcc_profession_o03' AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.professional_gear_options'),
      jsonb_build_object(
        'tokens', 5,
        'items', jsonb_build_array('W082', 'T091', 'T071', 'T111', 'T115'),
        'bundles', jsonb_build_array(
          jsonb_build_object(
            'bundleId', 'doctor_candles',
            'displayName', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_profession_shop.bundle.doctor_candles')::text),
            'items', jsonb_build_array(
              jsonb_build_object(
                'sourceId', 'general_gear',
                'itemId', 'T081',
                'quantity', 10
              )
            )
          ),
          jsonb_build_object(
            'bundleId', 'doctor_clotting_powder',
            'displayName', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_profession_shop.bundle.doctor_clotting_powder')::text),
            'items', jsonb_build_array(
              jsonb_build_object(
                'sourceId', 'potions',
                'itemId', 'P048',
                'quantity', 10
              )
            )
          ),
          jsonb_build_object(
            'bundleId', 'doctor_numbing_herbs',
            'displayName', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_profession_shop.bundle.doctor_numbing_herbs')::text),
            'items', jsonb_build_array(
              jsonb_build_object(
                'sourceId', 'potions',
                'itemId', 'P053',
                'quantity', 10
              )
            )
          ),
          jsonb_build_object(
            'bundleId', 'doctor_sterilizing_fluid',
            'displayName', jsonb_build_object('i18n_uuid', ck_id('witcher_cc.wcc_profession_shop.bundle.doctor_sterilizing_fluid')::text),
            'items', jsonb_build_array(
              jsonb_build_object(
                'sourceId', 'potions',
                'itemId', 'P054',
                'quantity', 10
              )
            )
          )
        )
      )
    )
  ) AS body;