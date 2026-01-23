\echo '007_wcc_item_general_gear.sql'
CREATE TABLE IF NOT EXISTS wcc_item_general_gear (
    t_id            varchar(10) PRIMARY KEY,          -- e.g. 'T001'
    dlc_dlc_id      varchar(64) NOT NULL REFERENCES wcc_dlcs(dlc_id), -- source_id (core, hb, dlc_*, exp_*)

    name_id         uuid NOT NULL,                    -- ck_id('witcher_cc.items.general_gear.name.'||t_id)

    -- Reused dictionary fields (see 001_wcc_items_dict.sql)
    group_key_id    uuid NULL,                        -- ck_id('general_gear.group.*')
    concealment_id  uuid NULL,                        -- ck_id('concealment.*')
    availability_id uuid NULL,                        -- ck_id('availability.*')

    weight          numeric(12,1) NULL,
    price           integer NULL,

    description_id  uuid NOT NULL,                    -- ck_id('witcher_cc.items.general_gear.description.'||t_id)
    subgroup_name_id uuid NOT NULL                    -- ck_id('witcher_cc.items.general_gear.subgroup_name.'||t_id)
);

COMMENT ON TABLE wcc_item_general_gear IS
  'Обычные вещи. Источник (DLC) через wcc_dlcs, локализуемые поля через i18n_text UUID (ck_id). Группа/скрытность/доступность — из общего словаря (001_wcc_items_dict.sql).';

COMMENT ON COLUMN wcc_item_general_gear.dlc_dlc_id IS
  'FK на wcc_dlcs.dlc_id (источник/пакет: core/hb/dlc_*/exp_*).';

COMMENT ON COLUMN wcc_item_general_gear.name_id IS
  'i18n UUID для названия вещи. Генерируется детерминированно: ck_id(''witcher_cc.items.general_gear.name.''||t_id).';

COMMENT ON COLUMN wcc_item_general_gear.description_id IS
  'i18n UUID для описания вещи. Генерируется детерминированно: ck_id(''witcher_cc.items.general_gear.description.''||t_id).';

COMMENT ON COLUMN wcc_item_general_gear.subgroup_name_id IS
  'i18n UUID для названия подгруппы. Генерируется детерминированно: ck_id(''witcher_cc.items.general_gear.subgroup_name.''||t_id).';

WITH raw_data (
  t_id, group_key, subgroup_name_ru, subgroup_name_en,
  name_ru, name_en,
  description_ru, description_en,
  source_id, concealment, weight, price, availability
) AS ( VALUES
  ('T001','general_gear.group.clothing','Маска','Mask','Карнавальная маска','Masquerade Mask','','','exp_lal','',0.1,36,''),
  ('T002','general_gear.group.clothing','Маска','Mask','Чумная маска','Plague Mask','+3 к Стойкости против воздушнокапельных болезней, яда и тошноты.','+3 to Endurance against airborne diseases, poison, and nausea.','exp_bot','',0.5,400,'availability.R'),
  ('T003','general_gear.group.clothing','Маска','Mask','Чумная маска','Plague Mask','+3 к Стойкости против переносимых по воздуху болезней, ядов и тошноты.','+3 to Endurance against airborne diseases, poisons, and nausea.','exp_lal','',0.1,38,'availability.R'),
  ('T004','general_gear.group.clothing','Одежда','Clothing','Простая одежда','Basic Clothing','Базовая одежда, опционально плащ.','Basic clothing, optionally with a cloak.','core','',2,10,''),
  ('T005','general_gear.group.clothing','Одежда','Clothing','Камуфляжный плащ','Camouflage Cloak','Потратив минуту, можно вплести окружающую листву в петли плаща. Даёт +1 к Скрытности в дикой местности.','Spending a minute, you can weave surrounding foliage into the cloak loops. Gives +1 to Stealth in the wilderness.','dlc_rw2','concealment.L',1,50,'availability.C'),
  ('T006','general_gear.group.clothing','Одежда','Clothing','Тёплая одежда','Cold Weather Clothing','+5 к проверкам Стойкости в холодных погодных условиях','+5 to Endurance checks in cold weather conditions.','core','',3,45,''),
  ('T007','general_gear.group.clothing','Одежда','Clothing','Модная одежда','Fashionable Clothing','Модная одежда для светских мероприятий. Может морально устареть уже через 2 месяца.','Fashionable clothing for social events. It may go out of style in as little as 2 months.','core','',2,70,''),
  ('T008','general_gear.group.clothing','Одежда','Clothing','Плащ с карманами [6x5][М][СЛ16]','Pocketed Cloak','Шесть потайных карманов вместимостью 5кг (маленькие предметы). Обнаружение: проверка Внимания СЛ16.','Six secret pockets with capacity 5 kg each (Tiny items). Detection: Awareness check DC 16.','exp_lal','',2.5,60,''),
  ('T009','general_gear.group.clothing','Одежда','Clothing','Тёмная одежда','Rogue''s Clothing','Ночью +1 к Скрытности. Есть капюшон.','At night, +1 to Stealth. Has a hood.','core','',1.5,50,''),
  ('T010','general_gear.group.containers','','','Бандольера [25][Н]','Bandolier','Вмещает 25 кг маленьких предметов внутри или небольших снаружи','Holds 25 kg of Tiny items inside or Small items attached outside.','core','concealment.S',1,19,''),
  ('T011','general_gear.group.containers','','','Корзина [15][Н]','Basket','Вмещает 15 кг небольших предметов.','Holds 15 kg of Small items.','core','concealment.T',0.5,10,''),
  ('T012','general_gear.group.containers','','','Поясная сумка [5][М]','Belt Pouch','Вмещает 5 кг маленьких предметов.','Holds 5 kg of Tiny items.','core','concealment.S',0.1,7,''),
  ('T013','general_gear.group.containers','','','Пустая склянка','Bottle','','','dlc_rw1','',0.1,3,''),
  ('T014','general_gear.group.containers','','','Скрытый сундук [30][Н][СЛ18]','Concealed Chest','Вмещает до 30 кг небольших предметов. Деревянный. Можно скрыть в тайнике. Обнаружение: проверка Восприятия СЛ18.','Holds up to 30 kg of Small items. Wooden. Can be hidden in a stash. Detection: Awareness check DC 18.','dlc_rw2','concealment.L',1.5,40,'availability.C'),
  ('T015','general_gear.group.containers','','','Мешок [20][М]','Sack','Вмещает 20 кг маленьких предметов.','Holds 20 kg of Tiny items.','core','concealment.S',0.1,3,''),
  ('T016','general_gear.group.containers','','','Наплечная сумка [30][Н]','Satchel','Вмещает 30 кг небольших предметов.','Holds 30 kg of Small items.','core','concealment.T',1,14,''),
  ('T017','general_gear.group.containers','','','Сумка с двумя потайными карманами [30][Н], [2x5][М][СЛ16]','Satchel with 2 Secret Pockets [30][S], [2x5][T][DC:16]','Вмещает 30 кг небольших предметов. Два потайных кармана вместимостью 5кг (маленькие предметы). Обнаружение: проверка Внимания СЛ16.','Holds 30 kg of Small items. Two secret pockets with capacity 5 kg each (Tiny items). Detection: Awareness check DC 16.','dlc_sh_tothr','',1.0,NULL,''),
  ('T018','general_gear.group.containers','','','Потайной карман [5][М][СЛ16]','Secret Pocket','Вмещает 5 кг маленьких предметов. Обнаружение: проверка Внимания СЛ16.','Holds 5 kg of Tiny items. Detection: Awareness check DC 16.','core','concealment.S',0.1,11,''),
  ('T019','general_gear.group.containers','','','Чехол для лука','Sheath, Bow','Вместилище для лука и колчана со стрелами.','Container for a bow and a quiver of arrows.','core','',1.5,24,''),
  ('T020','general_gear.group.containers','','','Набедренные ножны [СЛ18]','Sheath, Garter','Скрытые ножны для легких клинков на бедре. Обнаружение: проверка Внимания СЛ18.','Hidden sheath for small blades on the thigh. Detection: Awareness check DC 18.','core','',0.1,11,''),
  ('T021','general_gear.group.containers','','','Наручные ножны [СЛ15]','Sheath, Sleeve','Скрытые ножны для лёгких клинков на внутренней стороне руки. Обнаружение: проверка Внимания СЛ15.','Hidden sheath for small blades on the inside of the forearm. Detection: Awareness check DC 15.','core','',0.1,13,''),
  ('T022','general_gear.group.containers','','','Бурдюк','Waterskin','Емкость для хранения питьевой воды.','Container for storing drinking water.','core','',1,8,''),
  ('T023','general_gear.group.containers','','','Деревянный сундук [30][Н]','Wooden Chest','Вмещает 30 кг небольших предметов.','Holds 30 kg of Small items.','core','concealment.T',1,18,''),
  ('T024','general_gear.group.containers','','','Большой деревянный сундук [50][К]','Wooden Chest, Large','Вмещает 50 кг крупных предметов.','Holds 50 kg of Large items.','core','concealment.L',10,30,''),
  ('T025','general_gear.group.food','Напитки','Drinks','Алкагест','Alcohest','Чистый спирт для алхимии. При питье: опьянение на (12 - Тел) часов. При провале Стойкости (СЛ16) еще и отравление. Снимается "Слёзами жён".','Pure alcohol for alchemy. When drunk: intoxication for (12 - BODY) hours. On a failed Endurance check (DC 16) you also get poisoned. Removed with "Women''s Tears".','core','',1,8,''),
  ('T026','general_gear.group.food','Напитки','Drinks','Пиво','Beer','','','core','',1,5,''),
  ('T027','general_gear.group.food','Напитки','Drinks','Крепкий алкоголь','Spirits','','','core','',1,10,''),
  ('T028','general_gear.group.food','Напитки','Drinks','Вино','Wine','','','core','',1,8,''),
  ('T029','general_gear.group.food','Пища','Food','Пир','A Feast','Очень обильный прием пищи.','A very hearty meal.','core','',5,100,''),
  ('T030','general_gear.group.food','Пища','Food','Хороший обед','A Good Meal','','','core','',2.5,30,''),
  ('T031','general_gear.group.food','Пища','Food','Простой обед','A Simple Meal','','','core','',1,10,''),
  ('T032','general_gear.group.food','Пища','Food','Сырое мясо','Raw Meat','','','core','',1,8,''),
  ('T033','general_gear.group.food','Пища','Food','Сладости','Sweets','','','core','',1,5,''),
  ('T034','general_gear.group.food','Пища','Food','Сухой паёк (на 1 день)','Trail Rations (1 day)','','','core','',1,5,''),
  ('T035','general_gear.group.jewerly','','','Амулет с самоцветом','Amulet, Gemstone','Фокусирующее (3)','Focus (3).','core','concealment.S',0.1,500,'availability.R'),
  ('T036','general_gear.group.jewerly','','','Простой амулет','Amulet, Simple','Фокусирующее (1)','Focus (1).','core','concealment.S',0.1,250,'availability.R'),
  ('T037','general_gear.group.jewerly','','','Позолота','Gilding','Для оружия и брони. +1 к репутации (не стакается).','For weapons and armor. +1 to reputation (doesn''t stack).','exp_lal','',0.5,100,''),
  ('T038','general_gear.group.jewerly','','','Украшения','Jewelry','','','core','',0.5,50,''),
  ('T039','general_gear.group.jewerly','','','Совершенный самоцвет','Perfect Gemstone','','','core','',0.1,1000,'availability.R'),
  ('T040','general_gear.group.jewerly','','','Кольцо благосклонности','Ring of Favor','Восстанавливает все очки удачи при выпавших 1, 5 и 10 на броске 1d10.','Restores all Luck points when you roll 1, 5, and 10 on a 1d10 roll.','dlc_rw2','concealment.S',0.1,500,'availability.R'),
  ('T041','general_gear.group.jewerly','','','Ведьмачий медальон','Witcher medallion','','','core','',NULL,NULL,''),
  ('T042','general_gear.group.other','','','Фальшивые монеты (100 крон)','False Coins','Обнаружение подделки: проверка Внимания или Торговли СЛ15.','Counterfeit detection: Awareness or Business check DC 15.','exp_lal','',0.1,10,''),
  ('T043','general_gear.group.other','','','Сосуд с глистами','Vial of Gut Worms','Заражает глистами при проглатывании яиц. Снижает ВЫН на 25%. При еде тошнота с шансом 25%, которая прекращается успешным броском Стойкости СЛ14. Попытка не заразиться: проверка Стойкости СЛ16. Излечение: проверка Лечащего прикосновения СЛ14.','Infects with gut worms when swallowing the eggs. Reduces VIGOR by 25%. When eating, nausea with a 25% chance, which ends with a successful Endurance roll (DC 14). Avoid infection: Endurance check DC 16. Cure: First Aid check DC 14.','exp_lal','',0.1,89,''),
  ('T044','general_gear.group.quest','','','Головоломка Коллекционера','Centerpiece','','','exp_toc','',NULL,NULL,''),
  ('T045','general_gear.group.quest','','','Церебральный эликсир','Cerebral Elixir','','','exp_toc','',NULL,NULL,''),
  ('T046','general_gear.group.quest','','','Земные ленты','Earthly Ribbons','','','exp_toc','',NULL,NULL,''),
  ('T047','general_gear.group.quest','','','Жезл изгнания','Wand of Banishment','','','exp_toc','',NULL,NULL,''),
  ('T048','general_gear.group.standard','Гигиена','Hygiene','Ручное зеркальце','Hand Mirror','','','core','',0.5,27,''),
  ('T049','general_gear.group.standard','Гигиена','Hygiene','Набор для макияжа','Makeup Kit','+2 к Соблазнению и Харизме','+2 to Seduction and Charisma.','core','concealment.S',0.5,35,'availability.E'),
  ('T050','general_gear.group.standard','Гигиена','Hygiene','Духи/одеколон','Perfume/Cologne','Может прикрыть неприятный запах','Can mask an unpleasant smell.','core','',0.1,22,''),
  ('T051','general_gear.group.standard','Гигиена','Hygiene','Мыло','Soap','','','core','',0.1,4,''),
  ('T052','general_gear.group.standard','Замок','Lock','Замок обычный','Lock','Позволяет запирать двери и крышки. Взлом: проверка Взлома замков СЛ15.','Allows you to lock doors and lids. Picking: Pick Lock check DC 15.','core','',0.1,34,''),
  ('T053','general_gear.group.standard','Замок','Lock','Замок надежный','Lock, Strong','Позволяет запирать двери и крышки. Взлом: проверка Взлома замков СЛ18.','Allows you to lock doors and lids. Picking: Pick Lock check DC 18.','core','',0.1,68,''),
  ('T054','general_gear.group.standard','Замок','Lock','Замок-ловушка','Trapped Lock','Взлом: проверка Взлома СЛ17. При провале игла наносит эффекты загруженного яда. Требуется перезарядка.','Picking: Pick Lock check DC 17. On a failure, a needle applies the effects of the loaded poison. Requires reloading.','dlc_rw2','concealment.S',0.5,85,'availability.P'),
  ('T055','general_gear.group.standard','Карабанье','Climbing','Крюк-кошка','Grappling Hook','+2 к Атлетике при лазании.','+2 to Athletics when climbing.','core','',0.5,13,''),
  ('T056','general_gear.group.standard','Карабанье','Climbing','Колышки (х5)','Pitons (x5)','Для закрепления верёвок. Оружие ближнего боя: 1d6 урона.','For securing ropes. Melee weapon: 1d6 damage.','core','',0.5,10,''),
  ('T057','general_gear.group.standard','Карабанье','Climbing','Верёвка (20м)','Rope, 20m','','','core','',1.5,50,''),
  ('T058','general_gear.group.standard','Книги','Books','Книга сказок','Book of Tales','Автоматически раскрывает суеверия простолюдинов о монстрах. +1 к проверкам знаний о монстрах.','Automatically reveals commoners'' superstitions about monsters. +1 to Monster Lore checks.','dlc_rw2','concealment.S',0.5,40,'availability.C'),
  ('T059','general_gear.group.standard','Книги','Books','Руководство собирателя','Forager''s Guide','При поиске ингредиента СЛ добычи -2, количество найденных единиц +2.','When searching for an ingredient, the harvest DC is -2, and the number of units found is +2.','dlc_rw2','concealment.S',0.5,50,'availability.C'),
  ('T060','general_gear.group.standard','Книги','Books','Дневник/гроссбух','Journal/Ledger','Книжка с пустыми страницами в кожаной обложке.','Notebook with blank pages in a leather cover.','core','',0.5,8,''),
  ('T061','general_gear.group.standard','Навигация','Navigation','Компас','Compass','+3 к Выживанию в дикой природе при навигации и ориентировании','+3 to Wilderness Survival when navigating and orienting.','dlc_rw1','',0.1,32,''),
  ('T062','general_gear.group.standard','Навигация','Navigation','Магический компас','Magic Compass','Действие: проверка Сопротивления Убеждению (СЛ от ГМа). При успехе указывает направление к объекту о котором думает юзер. Провал говорит о желании чего-то другого.','Action: Resist Coercion check (DC set by the GM). On success, points toward the object the user is thinking about. On failure, indicates the desire for something else.','dlc_rw2','concealment.S',0.1,500,'availability.R'),
  ('T063','general_gear.group.standard','Навигация','Navigation','Карта Континента','Map of the Continent','+3 к Выживанию в дикой природе при навигации и ориентировании','+3 to Wilderness Survival when navigating and orienting.','core','',0.1,18,''),
  ('T064','general_gear.group.standard','Навигация','Navigation','Солнечный камень','Sun Stone','+2 к Выживанию в дикой природе при навигации и ориентировании.','+2 to Wilderness Survival when navigating and orienting.','dlc_rw1','',0.1,36,''),
  ('T065','general_gear.group.standard','Настольные игры','Board Games','Доска для покера на костях','Dice Poker Board','Настольная игра с десятью костями','Board game with ten dice.','core','',0.5,25,''),
  ('T066','general_gear.group.standard','Настольные игры','Board Games','Колода для гвинта','Gwent Deck','','','core','',0.1,5,''),
  ('T067','general_gear.group.standard','Настольные игры','Board Games','Шулерские кости','Loaded Dice','+3 к Азартным играм. Обнаружение: проверка Внимания СЛ16','+3 to Gambling. Detection: Awareness check DC 16.','core','',0.1,12,''),
  ('T068','general_gear.group.standard','Ночевка','Camping','Походная постель','Bedroll','Подстилка и одеяло','Mat and blanket.','core','',1.5,16,''),
  ('T069','general_gear.group.standard','Ночевка','Camping','Брезент','Tarp','Огромный кусок водонепроницаемога материала','Large piece of waterproof material.','core','',1.5,10,''),
  ('T070','general_gear.group.standard','Ночевка','Camping','Палатка','Tent','Укрывает от непогоды.','Shelters from bad weather.','core','',4,19,''),
  ('T071','general_gear.group.standard','Ночевка','Camping','Палатка большая','Tent, Large','Большая палатка для 8 человек, подходит для торговли.','Large tent for 8 people, suitable for trading.','core','',8,36,''),
  ('T072','general_gear.group.standard','Полезно в бою','Useful in Combat','Краснолюдский точильный камень','Dwarven Whetstone','За полчаса дает эффект пробивания брони одному острому оружию (или 10 стрелам) на следующий бой. Используется 3 раза.','After half an hour, grants the Armor Piercing effect to one bladed weapon (or 10 arrows) for the next fight. Can be used 3 times.','dlc_rw2','concealment.S',0.1,300,'availability.R'),
  ('T073','general_gear.group.standard','Полезно в бою','Useful in Combat','Банка с пиявками','Jar of Leeches','+3 к проверкам Стойкости для снятия отравления.','+3 to Endurance checks to remove poisoning.','exp_lal','',0.1,25,''),
  ('T074','general_gear.group.standard','Полезно в бою','Useful in Combat','Намордник','Muzzle','Блокирует атаки укусом. Надевается на цель атакой разоружения. Цель может снять: действие + проверка Ловкости рук или Силы СЛ16.','Blocks bite attacks. Put on the target with a disarm attack. Target can remove: action + Sleight of Hand or Physique check DC 16.','exp_lal','',0.1,8,''),
  ('T075','general_gear.group.standard','Полезно в бою','Useful in Combat','Пара скоб','Pair of Braces','Укрепляет укрытыие на +3 ПБ. Установка и снятие - действие полного хода. Уничтожаются вместе с укрытием. Одна пара на укрытие.','Reinforces cover by +3 SP. Installing and removing is a full-turn action. Destroyed along with the cover. One pair per cover.','dlc_rw2','concealment.L',2,45,'availability.E'),
  ('T076','general_gear.group.standard','Протез','Prosthetic','Протез простой','Prosthetic, Basic','Деревяшка для ноги или крюк для руки','A wooden peg leg or a hook for a hand.','core','',1,50,''),
  ('T077','general_gear.group.standard','Протез','Prosthetic','Протез качественный','Prosthetic, Quality','Повторяет форму конечности, не гнется.','Replicates the shape of a limb and does not bend.','core','',1.5,100,''),
  ('T078','general_gear.group.standard','Прочее','Miscellaneous','Мелок','Chalk','','','core','',0.1,2,''),
  ('T079','general_gear.group.standard','Ритуалы','Rituals','Кукла черной магии','Black Magic Doll','Нанеся себе 10 урона за действие полного раунда можно окропить куклу кровью и наложить порчу с низкой опасностью, связанную с куклой, на ненавистную цель. Бросок Наведения порчи против Защиты от магии.','By dealing yourself 10 damage as a full-round action, you can smear the doll with blood and place a low-danger hex tied to the doll on a hated target. Roll Hex Weaving against the target''s Magic Defense.','dlc_rw2','concealment.S',0.1,500,'availability.R'),
  ('T080','general_gear.group.standard','Ритуалы','Rituals','Священный символ','Holy Symbol','Религиозный символ из дерева.','Wooden religious symbol.','core','',0.1,14,''),
  ('T081','general_gear.group.standard','Свет','Light','Свеча','Candles (x5)','Повышает уровень освещенности на 1 в пределах 2 м. Сильный ветер задувает.','Increases light level by 1 within 2 m. Strong wind blows it out.','core','',0.1,1,''),
  ('T082','general_gear.group.standard','Свет','Light','Огниво','Flint & Steel','Инструмент для разведения огня.','Tool for starting a fire.','core','',0.1,6,''),
  ('T083','general_gear.group.standard','Свет','Light','Фонарь','Lantern','Повышает уровень освещенности на 2 в радиусе 3 м.','Increases light level by 2 within a 3 m radius.','core','',1,33,''),
  ('T084','general_gear.group.standard','Свет','Light','Фонарь "бычий глаз"','Lantern, Bullseye','Повышает уровень освещенности на 3 в 5-метровом конусе. Можно прикрыть окошко.','Increases light level by 3 in a 5-meter cone. You can cover the shutter.','core','',1,39,''),
  ('T085','general_gear.group.standard','Свет','Light','Факел','Torch','Повышает уровень освещенности на 1 в радиусе 5 м. Можно использовать как дубинку.','Increases light level by 1 within a 5 m radius. Can be used as a club.','core','',0.1,1,''),
  ('T086','general_gear.group.standard','Связывание','Restraints','Наручники','Manacles','Сковывают запястья. Освобождение: Взлом замков СЛ16 или Сила СЛ18.','Shackle wrists. Escape: Pick Lock DC 16 or Physique DC 18.','core','',0.5,30,''),
  ('T087','general_gear.group.standard','Связывание','Restraints','Кандалы','Shackles','Сковывают запястья и лодыжки. Скорость не больше 3. Освобождение: Взлом замков СЛ20 или Сила СЛ22.','Shackle wrists and ankles. Speed no more than 3. Escape: Pick Lock DC 20 or Physique DC 22.','core','',2,50,''),
  ('T088','general_gear.group.standard','Табак','Tobacco','Трубка','Pipe','Требуется табак для использования','Tobacco required for use.','core','',0.1,19,''),
  ('T089','general_gear.group.standard','Табак','Tobacco','Табак','Tobacco','','','core','',0.1,4,''),
  ('T090','general_gear.group.tools','Гаджет','Gadget','Рыболовные снасти','Fishing Gear','+2 к Выживанию в дикой природе при ловле рыбы','+2 to Wilderness Survival when fishing.','core','concealment.S',0.5,27,'availability.E'),
  ('T091','general_gear.group.tools','Гаджет','Gadget','Песочные часа (час)','Hourglass','','','core','',1,38,''),
  ('T092','general_gear.group.tools','Гаджет','Gadget','Песочные часа (минута)','Hourglass, Minute','','','core','',0.1,18,''),
  ('T093','general_gear.group.tools','Гаджет','Gadget','Медицинская кадильница','Medical Censer','Через дым накладывает эффекты химсостава в радиусе 6м. Нужно поджечь, сгорает 1 единица за раунд. Применимо к: Ароматное зелье, Галлюциноген, Дыхание суккуба, Могила Адды, Свертывающий порошок, Слёзы жён, Обезболивающие травы, Обеззараживающая жидкость, Хлороформ, Шелочной порошок, Эликсир Пантаграна.','Through smoke, applies the effects of a chemical compound within a 6 m radius. Must be lit; burns 1 unit per round. Applicable to: Scented Potion, Hallucinogen, Succubus Breath, Adda''s Grave, Coagulating Powder, Women''s Tears, Pain-Relief Herbs, Disinfecting Liquid, Chloroform, Alkaline Powder, Pentagram Elixir.','dlc_rw2','concealment.T',1,80,'availability.C'),
  ('T094','general_gear.group.tools','Гаджет','Gadget','Миниатюрный стол битвы','Miniature War Table','При успешной проверке Тактики (СЛ от ГМа) можно узнать у ГМа 3 вещи о предстоящей битве: первый ход врагов, лучший подход к битве, полезные элементы окружения, опасные элементы окружения, реакция врага на конкретный план, наличие ловушек врага.','On a successful Tactics check (DC set by the GM) you can learn 3 things from the GM about an upcoming battle: enemies'' first turn, the best approach to the battle, useful environment elements, dangerous environment elements, the enemy''s reaction to a specific plan, the presence of enemy traps.','dlc_rw2','concealment.T',1,60,'availability.P'),
  ('T095','general_gear.group.tools','Гаджет','Gadget','Потестаквизитор','Potestaquisitor','Обнаруживает магические возмущения в радиусе 20м. Обнаруживает темную магию, порчи, проклятия, демонов, призраков, двимерит, настоящих драконов и котов.','Detects magical disturbances within 20 m. Detects dark magic, hexes, curses, demons, ghosts, dimeritium, true dragons, and cats.','dlc_rw2','concealment.T',1,1000,'availability.R'),
  ('T096','general_gear.group.tools','Гаджет','Gadget','Усилитель звука','Sound Amplifier','Позволяет слышать звуки с другой стороны поверхности средней толщины (стена, дверь).','Allows you to hear sounds on the other side of a surface of medium thickness (wall, door).','dlc_rw2','concealment.S',0.1,50,'availability.C'),
  ('T097','general_gear.group.tools','Гаджет профессиональный','Professional Gadget','Разделитель монет','Coin Splitter','За 30 минут можно расщепить монеты (до 100 крон), удвоив сумму. Обнаружение фальшивки: проверка Внимания со СЛ 18 (или автоматически с набором инструментов торговца).','In 30 minutes, you can split coins (up to 100 crowns), doubling the amount. Counterfeit detection: Awareness check DC 18 (or automatic with Merchant''s Tools).','dlc_rw2','concealment.T',1,75,'availability.P'),
  ('T098','general_gear.group.tools','Гаджет профессиональный','Professional Gadget','Набор для маскировки','Disguise Kit','+2 к Маскировке','+2 to Disguise.','core','concealment.T',1,58,'availability.P'),
  ('T099','general_gear.group.tools','Гаджет профессиональный','Professional Gadget','Дистилляционная камера','Distillation Chamber','За 1 час при успешном броске Алхимии СЛ14 превращает до 10 единиц ингредиента в чистую форму (в 2 раза активнее стандартных).','In 1 hour, with a successful Alchemy roll (DC 14), turns up to 10 units of ingredient into pure form (twice as potent as standard).','dlc_rw2','concealment.L',2,100,'availability.C'),
  ('T100','general_gear.group.tools','Гаджет профессиональный','Professional Gadget','Эльфийский музыкальный инструмент','Elven Instrument','Лира, лютня или флейта. Цель получает -2 к действиям, отвлекающим внимание от слушания пока слышит музыку. Требует тратить действие. Проверка: Искусство против Сопротивления Магии цели каждый раунд.','Lyre, lute, or flute. Target gets -2 to actions that divert attention from listening while they can hear the music. Requires spending an action. Check: Fine Arts vs the target''s Resist Magic each round.','dlc_rw2','concealment.T',1,250,'availability.P'),
  ('T101','general_gear.group.tools','Гаджет профессиональный','Professional Gadget','Музыкальный инструмент','Instrument','','','core','',1,38,''),
  ('T102','general_gear.group.tools','Гаджет профессиональный','Professional Gadget','Инструменты торговца','Merchant''s Tools','+2 к Торговле при оценке товара','+2 to Business when appraising goods.','core','concealment.T',1.5,60,'availability.C'),
  ('T103','general_gear.group.tools','Гаджет шум','Noise Gadget','Сигнальный рожок','Signal Horn','Издает громкий звук на мили вокруг','Emits a loud sound for miles around.','dlc_rw1','',0.1,30,''),
  ('T104','general_gear.group.tools','Гаджет шум','Noise Gadget','Свисток','Signal Whistle','Издает громкий звук на десятки метров','Emits a loud sound for dozens of meters.','dlc_rw1','',0.1,6,''),
  ('T105','general_gear.group.tools','Инструменты','Tools','Инструменты алхимика','Alchemy Set','Позволяют создавать алхимические составы','Allow you to create alchemical preparations.','core','concealment.L',3,80,'availability.P'),
  ('T106','general_gear.group.tools','Инструменты','Tools','Принадлежности для готовки','Cooking Tools','Позволяют готовить еду','Allow you to cook food.','core','concealment.L',3,15,'availability.E'),
  ('T107','general_gear.group.tools','Инструменты','Tools','Инструменты ремесленника','Crafting Tools','Позволяют создавать оружие и броню','Allow you to craft weapons and armor.','core','concealment.L',5,83,'availability.C'),
  ('T108','general_gear.group.tools','Инструменты','Tools','Инструменты для творчества','Fine Art Tools','Позволяют создавать произведения искусства','Allow you to create works of art.','core','concealment.T',2,55,'availability.C'),
  ('T109','general_gear.group.tools','Инструменты','Tools','Инструменты для подделки','Forgery Kit','Позволяют создавать поддельные монеты и документы','Allow you to create counterfeit coins and documents.','core','concealment.S',0.5,58,'availability.P'),
  ('T110','general_gear.group.tools','Инструменты','Tools','Инструменты резчика рун','Runewright''s Tools','Позволяют наносить рунные и глифные слова и на первые пол часа усиливают стандартные руны и глифы','Allow you to inscribe runic and glyph words, and for the first half hour enhance standard runes and glyphs.','exp_toc','concealment.T',1.5,550,''),
  ('T111','general_gear.group.tools','Инструменты','Tools','Хирургические инструменты','Surgeon''s Kit','Позволяют проводить хирургические операции','Allow you to perform surgical operations.','core','concealment.T',1,83,'availability.C'),
  ('T112','general_gear.group.tools','Инструменты','Tools','Телекоммуникатор','Telecommunicator','Позволяет общаться при помощи ритуала Телекоммуникация','Allows you to communicate via the Telecommunication ritual.','core','concealment.L',4,1000,'availability.R'),
  ('T113','general_gear.group.tools','Инструменты','Tools','Воровские инструменты','Thieves'' Tools','Позволяют вскрывать замки','Allow you to pick locks.','core','concealment.S',1,80,'availability.P'),
  ('T114','general_gear.group.tools','Инструменты','Tools','Походная кузница','Tinker''s Forge','Позволяет ковать оружие и броню в любом месте','Allows you to forge weapons and armor anywhere.','core','concealment.L',5,111,'availability.P'),
  ('T115','general_gear.group.tools','Инструменты','Tools','Письменные принадлежности','Writing Kit','Позволяют писать письма, записи и т.п.','Allow you to write letters, notes, etc.','core','concealment.T',1,25,'availability.E'),
  ('T116','general_gear.group.transport','Транспорт - Средства личной мобильности','Transport - Personal Mobility','Коньки','Ice Skates','Транспорт без тарана (СКОР 12). Игнорирует эффекты Снега и Льда. Проверка: РЕА + Атлетика + 2 + 1d10. При провале кидаем 1d6: 1-2 - скользим дальше 1d6м, 3-6 - споткнулись, бросок Атлетики чтобы не упасть (СЛ15 для 3-5, СЛ20 для 5-6).','Vehicle without a ram (SPD 12). Ignores the effects of Snow and Ice. Check: REF + Athletics + 2 + 1d10. On failure, roll 1d6: 1-2 - you slide another 1d6 m; 3-6 - you stumble; roll Athletics to avoid falling (DC 15 for 3-5, DC 20 for 5-6).','exp_bot','',1,100,'availability.C'),
  ('T117','general_gear.group.harness','Сёдла','Saddles','Седло','Saddle','Нет штрафов к Верховой езде','No penalties for Riding.','core','',5,100,'availability.E'),
  ('T118','general_gear.group.harness','Сёдла','Saddles','Кавалерийское седло','Cavalry Saddle','+1 к проверкам управления для атаки. Встроенные ножны для оружия.','+1 to Control checks for attacking. Built-in sheath for a weapon.','core','',6,325,'availability.P'),
  ('T119','general_gear.group.harness','Сёдла','Saddles','Скаковое седло','Racing Saddle','+1 к проверкам управления для Верховой езды. +1 Скор.','+1 to Control checks for Riding. +1 SPD.','core','',3,200,'availability.C'),
  ('T120','general_gear.group.harness','Шоры','Blinders','Шоры','Blinders','+1 к успокоению скакуна','+1 to calm your mount.','core','',0.1,100,'availability.E'),
  ('T121','general_gear.group.harness','Шоры','Blinders','Скаковые шоры','Racing Blinders','+2 к успокоению скакуна','+2 to calm your mount.','core','',0.1,125,'availability.C'),
  ('T122','general_gear.group.harness','Перемётные сумы','Saddlebags','Перемётная сума','Saddlebags','В каждое из двух отделений влезает 25 кг предметов небольшого или среднего размера.','Saddlebags have enough room to carry 25kg of small or medium items in each of the two bags.','core','',1.5,100,'availability.E'),
  ('T123','general_gear.group.harness','Перемётные сумы','Saddlebags','Военная перемётная сума','Military Saddlebags','В каждое из двух отделений влезает 50 кг предметов небольшого или среднего размера. Снаружи есть крепления для 6 крупных предметов.','Rugged saddlebags that have enough room to carry 50kg of small or medium items in each of the two bags, with straps for up to 6 large items on the outside.','core','',2,150,'availability.P'),
  ('T124','general_gear.group.harness','Конские доспехи','Barding','Кожаные доспехи','Leather Barding','Прочность 10.','SP: 10 to your whole mount.','core','',10,550,'availability.P'),
  ('T125','general_gear.group.harness','Конские доспехи','Barding','Кольчужные доспехи','Chain Barding','Прочность 15. -1 к проверкам управления для Верховой езды.','SP: 15 to your whole mount. -1 to Control checks for Riding.','core','',25,1050,'availability.R'),

  -- Wheelchairs & prostheses (Transport)
  ('T126','general_gear.group.transport','Транспорт - Средства личной мобильности','Transport - Personal Mobility','Обычная инвалидная коляска','Basic Wheelchair','Нивелирует штрафы Скор, Уклонения/Изворотливости и Атлетики от инвалидности. Плавание/лазанье: -3. Атаки по коляске попадают во владельца.','Negates SPD, Dodge/Escape, and Athletics penalties from disability. Swimming/climbing checks: -3. Attacks against the wheelchair hit its user.','dlc_wpaw','',6,50,'availability.E'),
  ('T127','general_gear.group.transport','Транспорт - Средства личной мобильности','Transport - Personal Mobility','Качественная инвалидная коляска','Quality Wheelchair','Нивелирует штрафы Скор, Уклонения/Изворотливости и Атлетики от инвалидности. Плавание/лазанье: -1. Атаки по коляске попадают во владельца.','Negates SPD, Dodge/Escape, and Athletics penalties from disability. Swimming/climbing checks: -1. Attacks against the wheelchair hit its user.','dlc_wpaw','',3,200,'availability.P'),

  ('T128','general_gear.group.transport','Транспорт - Средства личной мобильности','Transport - Personal Mobility','Обычный протез','Basic Prosthesis','Полная функциональность; штраф Скор игнорируется. Броски атаки/защиты этой рукой -3; нога: Уклонение/Изворотливость -1. Не проводник Хаоса. Атаки по протезу попадают во владельца.','Full functionality; SPD penalty is ignored. Attacks/defenses with this arm are made at -3; with a prosthetic leg, Dodge/Escape checks are made at -1. Not a Chaos conduit. Attacks against the prosthesis hit the wearer.','dlc_wpaw','',2,50,'availability.E'),
  ('T129','general_gear.group.transport','Транспорт - Средства личной мобильности','Transport - Personal Mobility','Магический протез','Magical Prosthesis','Полная функциональность; штраф Скор игнорируется. Не проводник Хаоса. Атаки по протезу попадают во владельца.','Full functionality; SPD penalty is ignored. Not a Chaos conduit. Attacks against the prosthesis hit the wearer.','dlc_wpaw','',1,500,'availability.R'),
  ('T130','general_gear.group.transport','Транспорт - Средства личной мобильности','Transport - Personal Mobility','Ведьмачий протез','Witcher Prosthesis','Полная функциональность; штраф Скор игнорируется. Проводник для Хаоса; Бонус 1d6 урона серебром к удару протезом. Атаки по протезу попадают во владельца.','Full functionality; SPD penalty is ignored. Chaos conduit; +1d6 silver damage to attacks made with the prosthesis. Attacks against the prosthesis hit the wearer.','dlc_wpaw','',2,800,'availability.R'),
  ('T131','general_gear.group.transport','Транспорт - Средства личной мобильности','Transport - Personal Mobility','Протез-проводник','Conduit Prosthesis','Полная функциональность; штраф Скор игнорируется. Проводник для Хаоса; "Фокусирующее (2)" и "Улучшенное фокусирующее". Атаки по протезу попадают во владельца.','Full functionality; SPD penalty is ignored. Chaos conduit; Focus (2) and Greater Focus. Attacks against the prosthesis hit the wearer.','dlc_wpaw','',3,1000,'availability.R'),

  -- Wagon upgrades (General Gear)
  ('T132','general_gear.group.vehicle_upgrades','Ходовая часть','Undercarriage','Открывающийся желоб','Deployment Chute','Желоб вмещает до 1 кг. Действие: потянуть рычаг и высыпать содержимое за фургон.','Holds up to 1kg. Action: pull a lever to open the chute and dump contents behind the wagon.','dlc_sh_wat','',10,200,'availability.P'),
  ('T133','general_gear.group.vehicle_upgrades','Ходовая часть','Undercarriage','Передний мост','Front Axle Assembly','+1 к проверкам управления транспортом.','+1 to Control checks.','dlc_sh_wat','',10,400,'availability.C'),
  ('T134','general_gear.group.vehicle_upgrades','Ходовая часть','Undercarriage','Потайной отсек','Hidden Compartment','Отсек под фургоном до 80 кг. Скрыт, пока не заглянуть под фургон и не пройти Внимание СЛ16.','Adds a compartment under the wagon holding up to 80kg. Hidden until someone checks under the wagon and passes an Awareness check (DC 16).','dlc_sh_wat','',10,180,'availability.P'),

  ('T135','general_gear.group.vehicle_upgrades','Колёса','Wheels','Колёса с зубьями','Spiked Wheels','При управлении: атака навыком Верховой езды по цели рядом с фургоном; урон 4d6.','While driving: make an attack using Riding against a target adjacent to the wagon; deals 4d6 damage.','dlc_sh_wat','',20,350,'availability.C'),
  ('T136','general_gear.group.vehicle_upgrades','Колёса','Wheels','Стальные колёса','Steel Wheels','+20 ПЗ транспорта.','+20 vehicle HP.','dlc_sh_wat','',50,460,'availability.C'),
  ('T137','general_gear.group.vehicle_upgrades','Колёса','Wheels','Колёса с шипами','Studded Wheels','+1 к проверкам управления транспортом.','+1 to Control checks.','dlc_sh_wat','',10,400,'availability.E'),

  ('T138','general_gear.group.vehicle_upgrades','Покрытие','Cover','Камуфляж','Camouflage','Действие: накрыть фургон матом из листвы/искусственных растений. В дикой местности, пока фургон отпряжён и стоит, заметить его: Внимание СЛ16 (зрением).','Action: cover the wagon with a woven mat of foliage/fake plant life. In the wilderness, while detached and stationary, spotting it by sight requires an Awareness check (DC 16).','dlc_sh_wat','',10,300,'availability.P'),
  ('T139','general_gear.group.vehicle_upgrades','Покрытие','Cover','Рейлинги тента','Cover Railing','Действие: поднять или опустить покрытие фургона.','Action: raise or lower the wagon cover.','dlc_sh_wat','',20,150,'availability.C'),
  ('T140','general_gear.group.vehicle_upgrades','Покрытие','Cover','Стальная крыша','Steel Top','Даёт полное укрытие всем внутри. Укрытие имеет 20 ПБ, но ПБ транспорта не увеличивает.','Provides total cover to anyone inside. The cover has 20 SP but does not increase the vehicle''s SP.','dlc_sh_wat','',50,550,'availability.P'),

  ('T141','general_gear.group.vehicle_upgrades','Обшивка','Siding','Колючая обшивка','Barbed Siding','Попытка забраться на фургон: Атлетика СЛ16 или 3d6 урона и нужно отпустить.','Climbing onto the wagon requires an Athletics check (DC 16) or you take 3d6 damage and are forced to let go.','dlc_sh_wat','',20,550,'availability.P'),
  ('T142','general_gear.group.vehicle_upgrades','Обшивка','Siding','Усиленная обшивка','Hardened Siding','+10 ПБ транспорта. Не стакается с Железной обшивкой.','+10 vehicle SP. Does not stack with Iron Siding.','dlc_sh_wat','',50,2500,'availability.C'),
  ('T143','general_gear.group.vehicle_upgrades','Обшивка','Siding','Железная обшивка','Iron Siding','+20 ПБ транспорта. Не стакается с Усиленной обшивкой.','+20 vehicle SP. Does not stack with Hardened Siding.','dlc_sh_wat','',100,5000,'availability.P'),

  ('T144','general_gear.group.vehicle_upgrades','Интерьер','Interior','Защищённое хранилище','Secure Storage','Запертый отсек в полу до 80 кг. В комплекте стандартный замок и ключ.','A locked compartment in the floor holding up to 80kg. Comes with a standard lock and key.','dlc_sh_wat','',10,200,'availability.E'),
  ('T145','general_gear.group.vehicle_upgrades','Интерьер','Interior','Спальное место','Sleeping Upgrade','+1 к вместимости (Occupancy).','+1 Occupancy.','dlc_sh_wat','',10,220,'availability.E'),
  ('T146','general_gear.group.vehicle_upgrades','Интерьер','Interior','Мастерская','Workshop','Выбери 1 навык: Алхимия/Ремесло/Маскировка/Первая помощь/Подделка. Считается, что есть все нужные инструменты; +2 к проверкам этого навыка.','Pick one skill: Alchemy, Crafting, Disguise, First Aid, or Forgery. Counts as having all required tools; +2 to checks of that skill.','dlc_sh_wat','',20,800,'availability.C')
),
ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    -- General gear names
    SELECT ck_id('witcher_cc.items.general_gear.name.'||rd.t_id),
           'items',
           'general_gear_names',
           'ru',
           rd.name_ru
      FROM raw_data rd
     WHERE nullif(rd.name_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.items.general_gear.name.'||rd.t_id),
           'items',
           'general_gear_names',
           'en',
           rd.name_en
      FROM raw_data rd
     WHERE nullif(rd.name_en,'') IS NOT NULL
    UNION ALL
    -- General gear descriptions
    SELECT ck_id('witcher_cc.items.general_gear.description.'||rd.t_id),
           'items',
           'general_gear_descriptions',
           'ru',
           rd.description_ru
      FROM raw_data rd
     WHERE nullif(rd.description_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.items.general_gear.description.'||rd.t_id),
           'items',
           'general_gear_descriptions',
           'en',
           rd.description_en
      FROM raw_data rd
     WHERE nullif(rd.description_en,'') IS NOT NULL
    UNION ALL
    -- Subgroup names
    SELECT ck_id('witcher_cc.items.general_gear.subgroup_name.'||rd.t_id),
           'items',
           'general_gear_subgroup_names',
           'ru',
           rd.subgroup_name_ru
      FROM raw_data rd
     WHERE nullif(rd.subgroup_name_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.items.general_gear.subgroup_name.'||rd.t_id),
           'items',
           'general_gear_subgroup_names',
           'en',
           rd.subgroup_name_en
      FROM raw_data rd
     WHERE nullif(rd.subgroup_name_en,'') IS NOT NULL
  ) foo
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO wcc_item_general_gear (
  t_id, dlc_dlc_id, name_id,
  group_key_id, concealment_id, availability_id,
  weight, price,
  description_id, subgroup_name_id
)
SELECT rd.t_id
     , rd.source_id AS dlc_dlc_id
     , ck_id('witcher_cc.items.general_gear.name.'||rd.t_id) AS name_id
     , ck_id(rd.group_key) AS group_key_id
     , CASE WHEN nullif(rd.concealment,'') IS NOT NULL THEN ck_id(rd.concealment) ELSE NULL END AS concealment_id
     , CASE WHEN nullif(rd.availability,'') IS NOT NULL THEN ck_id(rd.availability) ELSE NULL END AS availability_id
     , rd.weight
     , rd.price
     , ck_id('witcher_cc.items.general_gear.description.'||rd.t_id) AS description_id
     , ck_id('witcher_cc.items.general_gear.subgroup_name.'||rd.t_id) AS subgroup_name_id
  FROM raw_data rd
ON CONFLICT (t_id) DO UPDATE
SET
  dlc_dlc_id = EXCLUDED.dlc_dlc_id,
  name_id = EXCLUDED.name_id,
  group_key_id = EXCLUDED.group_key_id,
  concealment_id = EXCLUDED.concealment_id,
  availability_id = EXCLUDED.availability_id,
  weight = EXCLUDED.weight,
  price = EXCLUDED.price,
  description_id = EXCLUDED.description_id,
  subgroup_name_id = EXCLUDED.subgroup_name_id;

