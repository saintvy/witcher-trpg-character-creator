\echo '006_wcc_item_armors.sql'
CREATE TABLE IF NOT EXISTS wcc_item_armors (
    a_id            varchar(10) PRIMARY KEY,          -- e.g. 'A002'
    dlc_dlc_id      varchar(64) NOT NULL REFERENCES wcc_dlcs(dlc_id), -- source_id (core, hb, dlc_*, exp_*)

    name_id         uuid NOT NULL,                    -- ck_id('witcher_cc.items.armor.name.'||a_id)

    -- Reused dictionary fields (see 000_wcc_items_dict.sql)
    body_part_id    uuid NULL,                        -- ck_id('bodypart.*')
    armor_class_id  uuid NULL,                        -- ck_id('armor_class.*')
    crafted_by_id   uuid NULL,                        -- ck_id('crafted_by.*')
    availability_id uuid NULL,                        -- ck_id('availability.*')

    reliability     integer NULL,
    stopping_power  integer NULL,
    enhancements    integer NOT NULL DEFAULT 0,

    encumbrance     integer NULL,
    weight          numeric(12,1) NULL,
    price           integer NULL,

    description_id  uuid NOT NULL                     -- ck_id('witcher_cc.items.armor.description.'||a_id)
);

COMMENT ON TABLE wcc_item_armors IS
  'Доспехи/щиты. Источник (DLC) через wcc_dlcs, локализуемые поля через i18n_text UUID (ck_id). Часть тела/класс/производитель/доступность — из общего словаря (000_wcc_items_dict.sql).';

COMMENT ON COLUMN wcc_item_armors.dlc_dlc_id IS
  'FK на wcc_dlcs.dlc_id (источник/пакет: core/hb/dlc_*/exp_*).';

COMMENT ON COLUMN wcc_item_armors.name_id IS
  'i18n UUID для названия доспеха. Генерируется детерминированно: ck_id(''witcher_cc.items.armor.name.''||a_id).';

COMMENT ON COLUMN wcc_item_armors.description_id IS
  'i18n UUID для описания доспеха. Генерируется детерминированно: ck_id(''witcher_cc.items.armor.description.''||a_id).';

WITH raw_data (
  a_id, source_id, body_part, armor_class,
  name_ru, name_en,
  is_piercing, is_slashing, is_bludgeoning, is_elemental, is_poison, is_bleeding,
  crafted_by, availability,
  reliability, stopping_power, enhancements, encumbrance, weight, price,
  description_ru, description_en
) AS ( VALUES
  ('A002','core','bodypart.head','armor_class.light',
    $$Капюшон вардэнского лучника$$, $$Verden Archer’s Hood$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.C',
    NULL,3,1,'0','0,5','100',
    $$Вердэнские лучники - крепкие ребята. Обычно они не слишком усердствуют с бронёй - дриады-то всё равно в щели между доспехами дротик-другой засадят. Зато они носят хорошие плотные капюшоны, расшитые сине-чёрным стрельчатым узором.$$,
    $$Verden archers are tough folk. They usually don’t bother too much with armor—dryads will still stick a dart or two into the gaps. But they do wear good, thick hoods embroidered with a blue-and-black chevron pattern.$$),

  ('A003','core','bodypart.head','armor_class.light',
    $$Каркасный шлем с полумаской$$, $$Spectacled Helm$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.C',
    NULL,8,0,'0','1','200',
    $$Такие шлемы куда чаще встречаются на Скеллиге и в Нильфгаарде. На севере шлемы обычно либо полностью закрытые, либо просто конусом. Полумаска защищает лицо и глаза. Порой снизу ещё и крепится кольчуга для защиты шеи.$$,
    $$Such helms are far more common in Skellige and Nilfgaard. In the North, helms are usually either fully enclosed or just a simple cone. The half-mask protects the face and eyes. Sometimes a mail curtain is attached below to protect the neck.$$),

  ('A007','core','bodypart.head','armor_class.medium',
    $$Усиленный капюшон$$, $$Armored Hood$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.C',
    NULL,14,0,'0','2','250',
    $$В дебрях нужен обзор получше, потому народ, в особенности эльфы, носит капюшоны из крепкой кожи и нескольких слоёв льна, и всё это прошито крепкими нитками. Такие капюшоны достаточно плотные, чтобы не пропустить режущий удар или болт, пущеный из небольшого ручного арбалета$$,
    $$In the wilds you need better visibility, so people—especially elves—wear hoods made of sturdy leather and several layers of linen, all stitched with strong thread. These hoods are dense enough to stop a slashing blow or a bolt from a small hand crossbow.$$),

  ('A028','core','bodypart.legs','armor_class.light',
    $$Кавалерийские штаны$$, $$Cavalry Trousers$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.C',
    NULL,3,0,'0','0,5','75',
    $$Кавалеристы обычно не носят тонну брони, если только это не драгуны какие-нибудь. Вот эти плотные штаны только кожаными полосками укреплены, и всё.$$,
    $$Cavalrymen don’t usually wear a ton of armor—unless they’re dragoons. These thick trousers are reinforced only with leather straps, that’s all.$$),

  ('A029','core','bodypart.legs','armor_class.light',
    $$Стёганые штаны$$, $$Padded Trousers$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.C',
    NULL,5,1,'0','1','125',
    $$По сути, гамбезон для ног. Не пропустит небольшой клинок, но я бы не стал слишком сильно на такую броню полагаться. А вот над гульфиком можно изрядно поржать.$$,
    $$Basically a gambeson for the legs. It won’t let a small blade through, but I wouldn’t rely on this armor too much. Still, you can have a good laugh at the codpiece.$$),

  ('A053','core','bodypart.shield','armor_class.light',
    $$Стальной баклер$$, $$Steel Buckler$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.C',
    '6',NULL,0,'0','1','150',
    $$Баклер - это такой маленький щит. Всего около фута в ширину, но им можно парировать удар клинка.$$,
    $$A buckler is a small shield—about a foot across—but you can use it to parry a blade strike.$$),

  ('A054','core','bodypart.shield','armor_class.light',
    $$Темерский щит$$, $$Temerian Shield$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.C',
    '8',NULL,1,'0','1,5','225',
    $$Ммм, старая добрая темерская работа! Каплевидный щит, пожалуй, встречается чаще всего. Темерский щит достаточно долго будет защищать тебя от мечей и стрел.$$,
    $$Mmm, good old Temerian work! The teardrop shield is probably the most common. A Temerian shield will protect you from swords and arrows for quite a while.$$),

  ('A056','core','bodypart.shield','armor_class.medium',
    $$Стальной каплевидный щит$$, $$Steel Kite Shield$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.C',
    '16',NULL,4,'0','3','400',
    $$Щит, полностью сделанный из стали, - вещица любопытная. Гудит, что твой колокол, если по нему шибануть, но куда крепче других щитов, да и двинуть в рыло им можно.$$,
    $$A shield made entirely of steel is a curious thing. It rings like a bell when struck, but it’s much sturdier than other shields—and you can smack someone in the face with it.$$),

  ('A017','core','bodypart.torso','armor_class.medium',
    $$Бригантина$$, $$Brigandine$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.C',
    NULL,12,0,'1','7','300',
    $$Обычно наёмники носят бригантину до тех пор, пока не разживутся бронёй получше. Это простенький кожаный жилет с прикреплёнными к нему пластинами из толстой дублёной кожи. Сам-то я бригантину носил под Бренной и Содденом. И скажу, что в ней плохо: неудобная она, жестковата.$$,
    $$Mercenaries usually wear a brigandine until they can get something better. It’s a simple leather vest with plates of thick boiled leather attached to it. I wore one myself at Brenna and Sodden. And here’s what’s bad about it: it’s uncomfortable and stiff.$$),

  ('A021','hb','bodypart.torso','armor_class.medium',
    $$Каэдвенская кираса$$, $$Kaedweni Cuirass$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.C',
    NULL,13,0,'1','7,5','355',
    $$$$,
    $$$$),

  ('A005','core','bodypart.head','armor_class.medium',
    $$Кольчужный капюшон$$, $$Chain Coif$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.E',
    NULL,12,0,'0','1,5','250',
    $$Ищешь простую и крепкую броньку? В таком случае, приятель, тебе нужен кольчужный капюшон. И удар меча остановит, и от молота спасёт. Некоторые носят его полноценную часть брони, другие же поверх ещё и шлем надевают. Полезная штука, как ни крути.$$,
    $$Looking for simple, sturdy armor? Then, friend, you need a chain coif. It will stop a sword blow and save you from a hammer. Some wear it as a full piece of armor; others put a helmet over it. Useful no matter how you look at it.$$),

  ('A004','hb','bodypart.head','armor_class.medium',
    $$Капеллина$$, $$Capelline$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.E',
    NULL,10,0,'0','1','230',
    $$$$,
    $$$$),

  ('A033','core','bodypart.legs','armor_class.medium',
    $$Усиленные штаны$$, $$Armored Trousers$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.E',
    NULL,12,0,'0','3,5','250',
    $$Честно скажу, ранашивать пару недель точно придётся. Но это не так важно, как тот факт, что дублёная кожа да стальные пластины и защищают, и не слишком сковывают движения.$$,
    $$I’ll be honest: you’ll have to break them in for a couple of weeks. But that’s less important than the fact that boiled leather and steel plates protect you without restricting movement too much.$$),

  ('A052','core','bodypart.shield','armor_class.light',
    $$Кожаный щит$$, $$Leather Shield$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.E',
    '4',NULL,0,'0','0,5','50',
    $$Проще щита, чем обтянутый кожей кусок дерева, не найти. Такие щиты не очень-то поулярны в наши дни - слкшмо хлипкие в сравнении с деревянными или стальными. Но зато дешёвые и лёгкие.$$,
    $$You won’t find a simpler shield than a piece of wood wrapped in leather. These shields aren’t very popular these days—too flimsy compared to wooden or steel ones. But they’re cheap and light.$$),

  ('A012','core','bodypart.torso','armor_class.light',
    $$Гамбезон$$, $$Gambeson$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.E',
    NULL,3,0,'0','1','100',
    $$Ну, по-хорошему, гамбезон - это поддоспешник для более тяжёлых доспехов, но многие бедняки используют его вместо брони. Против меча не поможет, зато спасёт от кинжала и тому подобного.$$,
    $$Properly speaking, a gambeson is padding worn under heavier armor, but many poor folk use it as armor on its own. It won’t help against a sword, but it will save you from a dagger and the like.$$),

  ('A009','core','bodypart.head','armor_class.heavy',
    $$Скеллигский шлем$$, $$Skellige Helm$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.P',
    NULL,25,1,'0','3,5','700',
    $$Выходцам со Скеллиге нравятся украшения, особенно если, напялив их, они выглядят брутальнее. И их шлемы - тому подтверждение. Скеллигский шлем крепкий, с кольчужной бармицей, на лице полумаска и пластины на щеках... а по бокам часто рога крепятся. По ходу, самые крепкие сотровитяне бодают врагов этими рогами.$$,
    $$Skelligers like ornaments, especially if they look more brutal when wearing them, and their helms prove it. The Skellige helm is sturdy: a mail aventail, a half-mask on the face, plates on the cheeks… and horns are often attached on the sides. Seems the toughest islanders gore their enemies with them.$$),

  ('A001','core','bodypart.head','armor_class.light',
    $$Двуслойный капюшон$$, $$Double Woven Hood$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.P',
    NULL,5,1,'0','1','175',
    $$Капюшон укрепить легко - просто добавь вставки из кожи, кольчужного полотна и тому подобного. Такие капюшоны куда плотнее обычных, отчего их сложнее повредить оружием. Простенько и защищает.$$,
    $$Reinforcing a hood is easy—just add inserts of leather, mail, and the like. Such hoods are much denser than ordinary ones, making them harder to damage. Simple and protective.$$),

  ('A006','core','bodypart.head','armor_class.medium',
    $$Темерский армет$$, $$Temerian Armet$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.P',
    NULL,16,1,'0','1,5','475',
    $$Темерские рыцари обычно носят арметы - стандартные рыцарские шлемы. Это полностью закрытый металлический шлем с острым "клювом" на забрале и узкой прорезью для обзора. ОДна проблема: через эту прорезь ни черта не видно.$$,
    $$Temerian knights usually wear armets—standard knightly helms. It’s a fully enclosed metal helm with a sharp “beak” on the visor and a narrow slit for vision. One problem: you can’t see a damn thing through that slit.$$),

  ('A027','core','bodypart.legs','armor_class.light',
    $$Двуслойные штаны$$, $$Double Woven Trousers$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.P',
    NULL,8,0,'0','1,5','225',
    $$Двойная ткань - лучший выбор. Не столь раздутая, как средней руки стёганка, а зад твой прикрыт.$$,
    $$Double cloth is the best choice. Not as puffed up as a mediocre quilted padding, and it keeps your ass covered.$$),

  ('A030','hb','bodypart.legs','armor_class.light',
    $$Штаны темерского пехотинца$$, $$Temerian Infantry Trousers$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.P',
    NULL,10,1,'0','2','255',
    $$$$,
    $$$$),

  ('A032','core','bodypart.legs','armor_class.medium',
    $$Реданские поножи$$, $$Redanian Greaves$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.P',
    NULL,14,1,'0','4','400',
    $$Что гамбезон, что поножи - реданские алебардщики особо не изгаляются. Простые кожаные штаны, поножи и гульфик. Манёвренность ценой прочности.$$,
    $$Whether gambeson or greaves, Redanian halberdiers don’t overthink it. Simple leather trousers, greaves, and a codpiece. Mobility at the cost of durability.$$),

  ('A063','core','bodypart.shield','armor_class.heavy',
    $$Павеза$$, $$Pavise$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.P',
    '20',NULL,4,'1','4','500',
    $$Если тебе надо за настоящую стенку запрятаться от врага, то пряься за павезой. Павеза здоровенная - по плечо человеку и ширной с краснолюда. За такой можно присесть и просто переждать, пока тебя поливают дождём из стрел.$$,
    $$If you need to hide behind a real wall from the enemy, hide behind a pavise. It’s huge—up to a man’s shoulder and as wide as a dwarf. You can crouch behind it and simply wait out a rain of arrows.$$),

  ('A055','core','bodypart.shield','armor_class.medium',
    $$Каэдвенский щит$$, $$Kaedweni Shield$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.P',
    '14',NULL,1,'0','2,5','400',
    $$Каэдвенский щит несильно отличается от темерского. Они, правда, на внешнюю сторону тратят черное железо. Каэдвенские щиты потяжелее, зато более прочные.$$,
    $$A Kaedweni shield doesn’t differ much from a Temerian one. They do use black iron on the outer face, though. Kaedweni shields are heavier, but tougher.$$),

  ('A058','core','bodypart.shield','armor_class.medium',
    $$Щит налётчика со Скеллиге$$, $$Skellige Raider Shield$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.P',
    '10',NULL,4,'0','2','325',
    $$В отличие от остального мира, выходцы со Скеллиге использую большие круглые щиты с умбоном по центру и рукоятью с обратной стороны. Думаю, благодаря такому больше манёвренность, поскольку щит не прикреплён к руке.$$,
    $$Unlike the rest of the world, Skelligers use large round shields with a boss in the center and a grip on the back. I think that gives better maneuverability, since the shield isn’t strapped to the arm.$$),

  ('A011','core','bodypart.torso','armor_class.light',
    $$Аэдирнский гамбезон$$, $$Aedirnian Gambeson$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.P',
    NULL,5,1,'0','1,5','175',
    $$Когда напал Нильфгаард, аэдирнцам пришлось, пожалуй, тяжелее всех. Они лишились короля, и я даже не знаю, избрали ли они нового до того, как их захлестнуло черно-золотой волной. Аэдирнский гамбезон - наглядное тому свидетельство. Это простой гамбезон с нашитыми кусками кожи и дублёной шкуры.$$,
    $$When Nilfgaard attacked, Aedirn probably had it worst of all. They lost their king, and I don’t even know if they elected a new one before they were swallowed by the black-and-gold wave. The Aedirnian gambeson is proof enough: a simple gambeson with patches of leather and boiled hide sewn on.$$),

  ('A014','core','bodypart.torso','armor_class.light',
    $$Двуслойный гамбезон$$, $$Double Woven Gambeson$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.P',
    NULL,8,1,'0','2,5','250',
    $$Как и капюшон из того же материала, двуслойный гамбезон - неплохое сочетание цены и качества. Спасёт от удара дешёвого меча или от болта из ручного арбалета, да и весит не так уж много. Обычно я такой и ношу, когда путешествую или хожу по городу. И защищает, и не вызывает лишних вопросов.$$,
    $$Like the hood made from the same material, the double woven gambeson is a good balance of price and quality. It will save you from a cheap sword blow or a bolt from a hand crossbow, and it doesn’t weigh much. It’s what I usually wear when traveling or walking around town—protective, and it doesn’t raise too many questions.$$),

  ('A013','hb','bodypart.torso','armor_class.light',
    $$Гамбезон верденского лучника$$, $$Verden Archer’s Gambeson$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.P',
    NULL,10,1,'0','2,5','300',
    $$$$,
    $$$$),

  ('A018','core','bodypart.torso','armor_class.medium',
    $$Броня реданского алебардщика$$, $$Redanian Halberdier’s Armor$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.P',
    NULL,14,1,'1','8,5','400',
    $$Как ни странно, реданский алебардщики много брони на себя не напяливают - берут простенький, длиной до колен гамбезон из кожи и ткани, кольчугу, горжет и наплечники. полагаю, когда между собой и противником алебарда, тажёлая броня особо-то и не нужна. От клинка в случае чего спасёт, да и манёвренность примерно такая же, как в гамбезоне.$$,
    $$Strangely enough, Redanian halberdiers don’t pile on armor—they take a simple knee-length gambeson of leather and cloth, a mail shirt, a gorget, and pauldrons. I suppose when there’s a halberd between you and the enemy, heavy armor isn’t that necessary. It’ll still save you from a blade if it comes to it, and the mobility is about the same as in a gambeson.$$),

  ('A020','hb','bodypart.torso','armor_class.medium',
    $$Доспех охотника за колдуньями$$, $$Witch Hunter Armor$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.P',
    NULL,15,1,'1','6','500',
    $$$$,
    $$$$),

  ('A008','core','bodypart.head','armor_class.heavy',
    $$Нильфгаардский шлем$$, $$Nilfgaardian Helm$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.R',
    NULL,30,2,'0','3','800',
    $$Шлемаки чёрных созданы весьма интересным образом - они состоят из двух частей. Первая - шлем-салад, у которого спереди либо кусок вырезан, либо прорезь есть для глаз. Вторая часть - бувигер, или нашейник, выступающий вперёд и закрывающий шею, нос и рот. Всё это вместе даёт неплохую защиту.$$,
    $$Nilfgaardian helms are made in an interesting way: they consist of two parts. The first is a sallet with either a cut-out front or an eye-slit. The second is a bevor—a neck guard that juts forward and covers the neck, nose, and mouth. Together, it offers solid protection.$$),

  ('A010','core','bodypart.head','armor_class.heavy',
    $$Топфхельм$$, $$Great Helm$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.R',
    NULL,20,1,'0','3,5','575',
    $$Топфхельмы носят высший класс рыцарей. Это большие шлемы цилиндрической формы с широкими прорезями для глаз и отверстиями, через которые можно нормально дышать. Они очень крепкие и часто украшены плетёными кисточками, рогами или даже орлами с раскинутыми крыльями. Ужасно вычурно, но небесполезно.$$,
    $$Great helms are worn by the highest class of knights. They’re big cylindrical helms with wide eye slits and holes you can breathe through. Very sturdy, often decorated with braided tassels, horns, or even eagles with outstretched wings. Awfully gaudy, but not useless.$$),

  ('A034','core','bodypart.legs','armor_class.heavy',
    $$Латные поножи$$, $$Plate Greaves$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.R',
    NULL,20,1,'1','7,5','625',
    $$Поножи, сабатоны, набедренники - всё это защищает твои ноги. Большие пластины из обработанной стали спасут от мечей, булав и стрел, пущеных из длинного лука.$$,
    $$Greaves, sabatons, cuisses—whatever you call them, they protect your legs. Large plates of worked steel will save you from swords, maces, and arrows loosed from a longbow.$$),

  ('A035','core','bodypart.legs','armor_class.heavy',
    $$Нильфгаардские поножи$$, $$Nilfgaardian Greaves$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.R',
    NULL,30,2,'1','6','850',
    $$Поножи у нильфгаардской брони чуточку легче, чем верхняя часть доспеха. Обычно это сабатоны, собственно поножи и надеваемые под них штаны в клетку из плотной кожи и ткани.$$,
    $$Nilfgaardian greaves are a bit lighter than the upper part of the armor. Usually it’s sabatons, the greaves themselves, and checked trousers of thick leather and cloth worn beneath.$$),

  ('A036','core','bodypart.legs','armor_class.heavy',
    $$Хиндарсфьяльские тяжёлые поножи$$, $$Hindarsfjall Heavy Chausses$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.R',
    NULL,25,3,'1','5','650',
    $$В состав тяжёлого хиндарсфьяльского доспеха входят шоссы. По сути кольчужные штаны. Крепкие. Большинство даже не заморачиваются напяливать на ноги тяжёлую броню, но в данном случае кольчужная броня неплоха. И при этом она очень гибкая.$$,
    $$The Hindarsfjall heavy armor includes chausses—basically mail trousers. Sturdy. Most don’t bother putting heavy armor on their legs, but in this case mail is a good choice. And it’s very flexible.$$),

  ('A031','core','bodypart.legs','armor_class.medium',
    $$Кожаные штаны из Лирии$$, $$Lyrian Leather Trousers$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.R',
    NULL,16,1,'0','3,5','525',
    $$Штаны из кожи лирийской работы. Грубоваты, не дышат, но ноги защищают. Правда, внимание к себе ты точно привлечешь.$$,
    $$Lyrian leatherwork. Rough, doesn’t breathe, but it protects the legs. You’ll definitely draw attention, though.$$),

  ('A062','core','bodypart.shield','armor_class.heavy',
    $$Нильфгаардская павеза$$, $$Nilfgaardian Pavise$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.R',
    '25',NULL,4,'1','5','600',
    $$Неприятно, конечно, такое говорить, но это лучший щит для арбалетчиков и всех, кто работает с механизмами под вражеским огнём. По размерам нильфгаардская павеза не отличается от обычной, но у неё есть сзади подставка, чтобы щит сам стоял, пока ты оружие перезаряжаешь или работашеь.$$,
    $$Hate to say it, but it’s the best shield for crossbowmen and anyone working mechanisms under enemy fire. It’s the same size as a normal pavise, but it has a stand on the back so it can stand on its own while you reload or work.$$),

  ('A057','dlc_rw2','bodypart.shield','armor_class.medium',
    $$Щит из чешуи виверны$$, $$Wyvern Scale Shield$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.R',
    '18',NULL,1,'0','2,5','500',
    $$$$,
    $$$$),

  ('A024','core','bodypart.torso','armor_class.heavy',
    $$Латный доспех$$, $$Plate Armor$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.R',
    NULL,20,1,'2','14','625',
    $$Такую броню пристало носить рыцарям да королям - крепкие стальные пластины, подогнанные по телу. Тяжеловата, порой в ней едва дышать можно, но много от чего защитит. Иногда выглядит просто и неброско, а иногда пафосно до ужаса.$$,
    $$Armor fit for knights and kings: sturdy steel plates fitted to the body. Heavy—sometimes you can hardly breathe in it—but it protects from a lot. Sometimes it looks simple and plain; sometimes it’s unbearably pompous.$$),

  ('A025','core','bodypart.torso','armor_class.heavy',
    $$Нильфгаардский латный доспех$$, $$Nilfgaardian Plate Armor$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.R',
    NULL,30,2,'2','12','850',
    $$Это такой чёрно-золотой доспех, крепкий, с высокими наплечниками и кучей деталей. Должен признать, сработан хорошо. От арбалетного болта на нём разве что царапинка останется.$$,
    $$A black-and-gold suit of armor, sturdy, with high pauldrons and lots of details. I have to admit, it’s well made. An arbalest bolt would leave no more than a scratch.$$),

  ('A026','core','bodypart.torso','armor_class.heavy',
    $$Хиндарсфьяльский тяжёлый доспех$$, $$Hindarsfjall Heavy Armor$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.R',
    NULL,25,3,'2','15','750',
    $$Пару раз всего я на островах Скеллиге бывал. Давным-давно на Хиндарсфьялле посещал храм Фрейи. Снаружи там торчали мечники в совершенно чудовищной броне: тяжёлая кольчуга до колена, кожаная куртка под ней и дублёная кожа сверху, и толстый такой широкий пояс. Думаю, удар алебарды эта дрянь точно выдержит.$$,
    $$I’ve only been to Skellige a couple of times. Long ago, on Hindarsfjall, I visited Freya’s temple. Outside stood swordsmen in truly monstrous armor: heavy mail down to the knees, a leather jacket under it, boiled leather on top, and a thick, wide belt. I think this stuff would definitely take a halberd hit.$$),

  ('A023','hb','bodypart.torso','armor_class.heavy',
    $$Доспех с Ундвика$$, $$Undvik Armor$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.R',
    NULL,28,3,'2','15','815',
    $$$$,
    $$$$),

  ('A015','hb','bodypart.torso','armor_class.light',
    $$Доспех чародея из Бан Арда$$, $$Ban Ard Mage Armor$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.R',
    NULL,5,1,'0','3','930',
    $$$$,
    $$$$),

  ('A022','core','bodypart.torso','armor_class.medium',
    $$Кожаная куртка из Лирии$$, $$Lyrian Leather Jacket$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.humans','availability.R',
    NULL,16,1,'1','6,5','525',
    $$Мне однажды довелось примерить кожаную куртку из Лирии. Курва, по ощущениям я на себя напялил чёртовы латы. Лирийцы каким-то особым образом обрабатывают кожу, отчего она становится крепкой, как шкура василиска. Я позволил торговцу в себя из длинного лука выстрелить, так меня даже не поцарапало! Хотя, может, я просто слегка пьян был в тот день.$$,
    $$Once I tried on a Lyrian leather jacket. Damn, it felt like I was putting on plate armor. Lyrians treat leather in a special way, making it as tough as a basilisk hide. I even let a merchant shoot me with a longbow and it didn’t scratch me! Though maybe I was a bit drunk that day.$$),

  ('A019','hb','bodypart.torso','armor_class.medium',
    $$Доспех боевого чародея$$, $$Battlemage Armor$$,
    NULL,NULL,NULL,NULL,'TRUE','TRUE',
    'crafted_by.humans','availability.R',
    NULL,16,1,'1','6','2200',
    $$$$,
    $$$$),

  ('A043','core','bodypart.full','armor_class.heavy',
    $$Доспехи драуга$$, $$Draug Armor$$,
    NULL,NULL,NULL,NULL,'TRUE','TRUE',
    'crafted_by.humans','availability.U',
    NULL,36,3,'3','37',NULL,
    $$$$,
    $$$$),

  ('A041','core','bodypart.full','armor_class.heavy',
    $$Драгунская броня гномьей работы$$, $$Gnomish Dragoon Armor$$,
    'TRUE','TRUE',NULL,NULL,NULL,NULL,
    'crafted_by.non-humans','availability.R',
    NULL,25,2,'2','20','2850',
    $$Обычно гномы кавалеристами не становятся, по вполне понятным причинам. Но они выковали броню для людей - командиров кавалерии Нильфгаарда. Лёгкие латы, чёрные с голубым отливом, покрыты гномьей гравировкой. Удар держат как на турнирах, так и на поле боя.$$,
    $$Dwarves don’t become cavalrymen, for obvious reasons. But they forged armor for humans—Nilfgaardian cavalry commanders. Light plate, black with a blue sheen, covered in dwarven engraving. It can take hits both in tournaments and on the battlefield.$$),

  ('A042','core','bodypart.full','armor_class.heavy',
    $$Махакамские латы$$, $$Mahakaman Plate Armor$$,
    'TRUE','TRUE','TRUE',NULL,NULL,NULL,
    'crafted_by.non-humans','availability.R',
    NULL,30,3,'2','30','3525',
    $$Махакаская сталь - прочнее её в мире нет. И потому броня из этой стали всегда будет самой лучшей. Махакамские латы тяжелы, да - тёмная броня, покрытая позолотой и бронзой, угловатыми узорами и краснолюскими рунами. Сам я такую никогда не носил, но разок вёз комплект лат из Махакама в Ангрен. Продал за несколько тысяч.$$,
    $$Mahakaman steel is the strongest in the world, and so armor made from it is always the best. Mahakaman plate is heavy, yes—dark armor covered with gold and bronze, angular patterns and dwarven runes. I’ve never worn it, but once I hauled a set from Mahakam to Angren and sold it for several thousand.$$),

  ('A037','core','bodypart.full','armor_class.light',
    $$Кольчуга гномьей работы$$, $$Gnomish Chain$$,
    NULL,'TRUE',NULL,NULL,NULL,NULL,
    'crafted_by.non-humans','availability.R',
    NULL,10,1,'0','5','975',
    $$Созданная гномами кольчужка вся чернёная и полностью тело закрывает - там и капюшо, и хауберг, и шоссы. Просто, красиво и носится без труда. Колечки небольшие, но крепкие, так что кольчужка еще и лёгкая.$$,
    $$The dwarves’ mail is all blackened and covers the whole body—hood, hauberk, and chausses. Simple, beautiful, and comfortable to wear. The rings are small but strong, so the mail is also light.$$),

  ('A038','core','bodypart.full','armor_class.medium',
    $$Броня скоя'таэля$$, $$Scoia’tael Armor$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.non-humans','availability.R',
    NULL,20,2,'1','12','2325',
    $$Не все "белки" носят такую броню - обычно это привилегия командиров спецотрядов, вроде того же Иорвета. Броня хорошая, создана специально, чтобы сливаться с окружением. Вот хоть и ненавижу я скоя'таэлей, но бронька у них отменная.$$,
    $$Not every “squirrel” wears such armor—usually it’s a privilege of special forces commanders, like Iorveth. It’s good armor, made specifically to blend with the surroundings. And though I hate Scoia’tael, their armor is excellent.$$),

  ('A040','core','bodypart.full','armor_class.medium',
    $$Краснолюдский плащ$$, $$Dwarven Cloak$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.non-humans','availability.R',
    NULL,16,1,'0','5','1400',
    $$Такие плащи хороши в дороге. Они и защищают неплохо. Так-то это просто кожа, но настолько хорошо обработанная особым краснолюдским способом, что она не только броню может заменить, но и не промогает.$$,
    $$These cloaks are great on the road. They protect well. It’s just leather, but it’s treated so well in a special dwarven way that it can replace armor—and it doesn’t soak through.$$),

  ('A061','core','bodypart.shield','armor_class.heavy',
    $$Махакамская павеза$$, $$Mahakaman Pavise$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.non-humans','availability.R',
    '35',NULL,4,'1','5,5','1050',
    $$Махакамские бойцы с такими штуковинами защищают свои города. По строению эти павезы аналогичны нильфгаардским, да только сделаны они краснолюдскими ремесленниками, чьё искусство ковки совершенствовалось много веков. Если бы мне пришлось выбирать, за каким щитом спрятаться, я бы выбрал махакамскую павезу.$$,
    $$Mahakam warriors defend their cities with these. Built like Nilfgaardian pavises, but made by dwarven craftsmen whose forging art has been refined over centuries. If I had to choose a shield to hide behind, I’d choose the Mahakaman pavise.$$),

  ('A051','core','bodypart.shield','armor_class.light',
    $$Гномий баклер$$, $$Gnomish Buckler$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.non-humans','availability.R',
    '15',NULL,2,'0','1','450',
    $$То, что для людей баклер, для гнома - полноценный щит. Правда, сомневаюсь, что так эта странная штука на свет появилась. Щит этот сделан по той же технологии, что и прочьи гномьи изделия, да и удар держит получше более крупных щитов.$$,
    $$What is a buckler for humans is a full shield for a dwarf. I doubt that’s how this odd thing first appeared. This shield is made with the same techniques as other dwarven products, and it holds blows better than larger shields.$$),

  ('A060','core','bodypart.shield','armor_class.medium',
    $$Эльфский щит$$, $$Elven Shield$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.non-humans','availability.R',
    '25',NULL,4,'0','3','700',
    $$Теперь таких почти не сыщешь. Партизанская война не особо способствует бою с мечом и щитом. Или же храбрые повстанцы не хотят показаться трусами. Однако эльфский щит прекрасен. По форме каплевидный, с золочением и украшениями в форме листьев.$$,
    $$You can hardly find these anymore. Guerrilla war doesn’t encourage fighting with sword and shield. Or perhaps brave rebels don’t want to look like cowards. Still, the elven shield is splendid: teardrop-shaped, gilded, and decorated with leaf motifs.$$),

  ('A016','core','bodypart.torso','armor_class.light',
    $$Низушечий защитный дублет$$, $$Halfling Protective Doublet$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.non-humans','availability.R',
    NULL,8,1,'0','1','375',
    $$Броня - это хорошо. А уж в такие-то времена броню всем носить стоит. Но не каждый может себе позволить кольчугу или латы. Ну и низушки какое-то время назад придумали такой защитный дублет. Снаружи-то он яркий и всячески украшенный, а под тканью скрыт неплохой слой брони.$$,
    $$Armor is good—and in times like these everyone should wear it. But not everyone can afford mail or plate. So halflings came up with a protective doublet some time ago: bright and ornate on the outside, with a decent layer of protection hidden under the fabric.$$),

  ('A039','core','bodypart.full','armor_class.medium',
    $$Доспехи Горного народа$$, $$Mountain Folk Armor$$,
    'TRUE','TRUE','TRUE',NULL,'TRUE',NULL,
    'crafted_by.non-humans','availability.U',
    NULL,24,3,'0','15',NULL,
    $$$$,
    $$$$),

  ('A044','dlc_wt','bodypart.full_wo_head','armor_class.light',
    $$Броня школы Змеи$$, $$Serpentine Armor$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.witchers','availability.R',
    NULL,8,2,'0','5',NULL,
    $$$$,
    $$$$),

  ('A045','dlc_wt','bodypart.full_wo_head','armor_class.light',
    $$Броня школы Кота$$, $$Feline Armor$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.witchers','availability.R',
    NULL,6,2,'0','3',NULL,
    $$$$,
    $$$$),

  ('A047','dlc_wt','bodypart.full_wo_head','armor_class.medium',
    $$Броня школы Волка$$, $$Wolven Armor$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.witchers','availability.R',
    NULL,14,2,'1','14',NULL,
    $$$$,
    $$$$),

  ('A048','dlc_wt','bodypart.full_wo_head','armor_class.medium',
    $$Броня школы Грифона$$, $$Griffin Armor$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.witchers','availability.R',
    NULL,16,2,'1','18',NULL,
    $$$$,
    $$$$),

  ('A049','dlc_wt','bodypart.full_wo_head','armor_class.medium',
    $$Броня школы Мантикоры$$, $$Manticore Armor$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.witchers','availability.R',
    NULL,12,2,'1','10',NULL,
    $$$$,
    $$$$),

  ('A050','dlc_wt','bodypart.full_wo_head','armor_class.medium',
    $$Броня школы Медведя$$, $$Ursine Armor $$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.witchers','availability.R',
    NULL,20,2,'3','24',NULL,
    $$$$,
    $$$$),

  ('A059','dlc_wt','bodypart.shield','armor_class.medium',
    $$Щит школы Мантикоры$$, $$Manticore Shield$$,
    NULL,NULL,NULL,NULL,NULL,NULL,
    'crafted_by.witchers','availability.R',
    '20',NULL,1,'0','2',NULL,
    $$$$,
    $$$$),

  ('A046','core','bodypart.full_wo_head','armor_class.light',
    $$Доспехи Ворона$$, $$Raven’s Armor$$,
    NULL,NULL,NULL,NULL,'TRUE','TRUE',
    'crafted_by.witchers','availability.U',
    NULL,12,3,'0','12',NULL,
    $$$$,
    $$$$),

  ('A064','dlc_sch_snail','bodypart.full','armor_class.heavy',
    $$Броня школы Улитки$$, $$Gastropod Armor$$,
    'TRUE','TRUE','TRUE','TRUE',NULL,NULL,
    'crafted_by.witchers','availability.R',
    NULL,30,1,'6','42',NULL,
    $$$$,
    $$$$)
),
ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    -- Armor names
    SELECT ck_id('witcher_cc.items.armor.name.'||rd.a_id),
           'items',
           'armor_names',
           'ru',
           rd.name_ru
      FROM raw_data rd
     WHERE nullif(rd.name_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.items.armor.name.'||rd.a_id),
           'items',
           'armor_names',
           'en',
           rd.name_en
      FROM raw_data rd
     WHERE nullif(rd.name_en,'') IS NOT NULL
    UNION ALL
    -- Armor descriptions
    SELECT ck_id('witcher_cc.items.armor.description.'||rd.a_id),
           'items',
           'armor_descriptions',
           'ru',
           rd.description_ru
      FROM raw_data rd
     WHERE nullif(rd.description_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.items.armor.description.'||rd.a_id),
           'items',
           'armor_descriptions',
           'en',
           rd.description_en
      FROM raw_data rd
     WHERE nullif(rd.description_en,'') IS NOT NULL
  ) foo
  ON CONFLICT (id, lang) DO NOTHING
)
,
upsert_armors AS (
  INSERT INTO wcc_item_armors (
    a_id, dlc_dlc_id, name_id,
    body_part_id, armor_class_id, crafted_by_id, availability_id,
    reliability, stopping_power, enhancements, encumbrance, weight, price,
    description_id
  )
  SELECT rd.a_id
       , rd.source_id AS dlc_dlc_id
       , ck_id('witcher_cc.items.armor.name.'||rd.a_id) AS name_id
       , ck_id(rd.body_part) AS body_part_id
       , ck_id(rd.armor_class) AS armor_class_id
       , ck_id(rd.crafted_by) AS crafted_by_id
       , ck_id(rd.availability) AS availability_id
       , CAST(NULLIF(rd.reliability,'') AS integer) AS reliability
       , CAST(NULLIF(rd.stopping_power::text,'') AS integer) AS stopping_power
       , coalesce(CAST(NULLIF(rd.enhancements::text,'') AS integer), 0) AS enhancements
       , CAST(NULLIF(REPLACE(rd.encumbrance, ',', '.'), '') AS numeric) AS encumbrance
       , CAST(NULLIF(REPLACE(rd.weight, ',', '.'), '') AS numeric) AS weight
       , CAST(NULLIF(REPLACE(rd.price, ',', '.'), '') AS numeric) AS price
       , ck_id('witcher_cc.items.armor.description.'||rd.a_id) AS description_id
    FROM raw_data rd
  ON CONFLICT (a_id) DO UPDATE
  SET
    dlc_dlc_id = EXCLUDED.dlc_dlc_id,
    name_id = EXCLUDED.name_id,
    body_part_id = EXCLUDED.body_part_id,
    armor_class_id = EXCLUDED.armor_class_id,
    crafted_by_id = EXCLUDED.crafted_by_id,
    availability_id = EXCLUDED.availability_id,
    reliability = EXCLUDED.reliability,
    stopping_power = EXCLUDED.stopping_power,
    enhancements = EXCLUDED.enhancements,
    encumbrance = EXCLUDED.encumbrance,
    weight = EXCLUDED.weight,
    price = EXCLUDED.price,
    description_id = EXCLUDED.description_id
  RETURNING a_id
),
prot_effects AS (
  -- Protection flags (from source data) are stored as effects (instead of boolean columns on wcc_item_armors)
  SELECT rd.a_id AS item_id, 'E077'::varchar(10) AS e_e_id, NULL::varchar(10) AS ec_ec_id, NULL::varchar(50) AS modifier
    FROM raw_data rd
   WHERE coalesce(rd.is_piercing, '') = 'TRUE'
  UNION ALL
  SELECT rd.a_id, 'E078', NULL, NULL
    FROM raw_data rd
   WHERE coalesce(rd.is_slashing, '') = 'TRUE'
  UNION ALL
  SELECT rd.a_id, 'E076', NULL, NULL
    FROM raw_data rd
   WHERE coalesce(rd.is_bludgeoning, '') = 'TRUE'
  UNION ALL
  SELECT rd.a_id, 'E079', NULL, NULL
    FROM raw_data rd
   WHERE coalesce(rd.is_elemental, '') = 'TRUE'
  UNION ALL
  SELECT rd.a_id, 'E080', NULL, NULL
    FROM raw_data rd
   WHERE coalesce(rd.is_bleeding, '') = 'TRUE'
  UNION ALL
  SELECT rd.a_id, 'E082', NULL, NULL
    FROM raw_data rd
   WHERE coalesce(rd.is_poison, '') = 'TRUE'
),
ins_prot_effects AS (
  INSERT INTO wcc_item_to_effects (item_id, e_e_id, ec_ec_id, modifier)
  SELECT pe.item_id, pe.e_e_id, pe.ec_ec_id, pe.modifier
    FROM prot_effects pe
   WHERE NOT EXISTS (
     SELECT 1
       FROM wcc_item_to_effects ite
      WHERE ite.item_id = pe.item_id
        AND ite.e_e_id = pe.e_e_id
        AND coalesce(ite.ec_ec_id, '') = coalesce(pe.ec_ec_id, '')
        AND coalesce(ite.modifier, '') = coalesce(pe.modifier, '')
   )
  RETURNING 1
)
SELECT 1;