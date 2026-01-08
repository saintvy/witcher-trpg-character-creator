CREATE TABLE IF NOT EXISTS wcc_item_trophies (
    tr_id           varchar(10) PRIMARY KEY,          -- e.g. 'TR001'
    dlc_dlc_id      varchar(64) NOT NULL REFERENCES wcc_dlcs(dlc_id), -- source_id (exp_toc)

    name_id         uuid NOT NULL,                    -- ck_id('witcher_cc.items.trophy.name.'||tr_id)

    -- Monster type (stored in i18n in this node)
    monster_type_id uuid NULL,                       -- ck_id('trophy.monster_type.*')
    availability_id uuid NULL,                        -- ck_id('availability.*')

    effect_id       uuid NOT NULL,                    -- ck_id('witcher_cc.items.trophy.effect.'||tr_id)
    price           integer NOT NULL DEFAULT 0
);

COMMENT ON TABLE wcc_item_trophies IS
  'Трофеи. Источник (DLC) через wcc_dlcs, локализуемые поля через i18n_text UUID (ck_id). Тип монстра хранится в i18n в этой ноде.';

COMMENT ON COLUMN wcc_item_trophies.dlc_dlc_id IS
  'FK на wcc_dlcs.dlc_id (источник/пакет: exp_toc).';

COMMENT ON COLUMN wcc_item_trophies.name_id IS
  'i18n UUID для названия трофея. Генерируется детерминированно: ck_id(''witcher_cc.items.trophy.name.''||tr_id).';

COMMENT ON COLUMN wcc_item_trophies.effect_id IS
  'i18n UUID для эффекта трофея. Генерируется детерминированно: ck_id(''witcher_cc.items.trophy.effect.''||tr_id).';

COMMENT ON COLUMN wcc_item_trophies.monster_type_id IS
  'i18n UUID для типа монстра. Генерируется детерминированно: ck_id(''trophy.monster_type.*'').';

-- Insert monster types into i18n
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT * FROM (
  SELECT ck_id('trophy.monster_type.cursed'),
         'items',
         'trophy_monster_types',
         'ru',
         'Проклятые'
    WHERE true
  UNION ALL
  SELECT ck_id('trophy.monster_type.cursed'),
         'items',
         'trophy_monster_types',
         'en',
         'Cursed'
    WHERE true
  UNION ALL
  SELECT ck_id('trophy.monster_type.draconids'),
         'items',
         'trophy_monster_types',
         'ru',
         'Дракониды'
    WHERE true
  UNION ALL
  SELECT ck_id('trophy.monster_type.draconids'),
         'items',
         'trophy_monster_types',
         'en',
         'Draconids'
    WHERE true
  UNION ALL
  SELECT ck_id('trophy.monster_type.elementals'),
         'items',
         'trophy_monster_types',
         'ru',
         'Элементали'
    WHERE true
  UNION ALL
  SELECT ck_id('trophy.monster_type.elementals'),
         'items',
         'trophy_monster_types',
         'en',
         'Elementals'
    WHERE true
  UNION ALL
  SELECT ck_id('trophy.monster_type.hybrids'),
         'items',
         'trophy_monster_types',
         'ru',
         'Гибриды'
    WHERE true
  UNION ALL
  SELECT ck_id('trophy.monster_type.hybrids'),
         'items',
         'trophy_monster_types',
         'en',
         'Hybrids'
    WHERE true
  UNION ALL
  SELECT ck_id('trophy.monster_type.insectoids'),
         'items',
         'trophy_monster_types',
         'ru',
         'Инсектоиды'
    WHERE true
  UNION ALL
  SELECT ck_id('trophy.monster_type.insectoids'),
         'items',
         'trophy_monster_types',
         'en',
         'Insectoids'
    WHERE true
  UNION ALL
  SELECT ck_id('trophy.monster_type.necrophages'),
         'items',
         'trophy_monster_types',
         'ru',
         'Некрофаги'
    WHERE true
  UNION ALL
  SELECT ck_id('trophy.monster_type.necrophages'),
         'items',
         'trophy_monster_types',
         'en',
         'Necrophages'
    WHERE true
  UNION ALL
  SELECT ck_id('trophy.monster_type.relicts'),
         'items',
         'trophy_monster_types',
         'ru',
         'Реликты'
    WHERE true
  UNION ALL
  SELECT ck_id('trophy.monster_type.relicts'),
         'items',
         'trophy_monster_types',
         'en',
         'Relicts'
    WHERE true
  UNION ALL
  SELECT ck_id('trophy.monster_type.spirits'),
         'items',
         'trophy_monster_types',
         'ru',
         'Духи'
    WHERE true
  UNION ALL
  SELECT ck_id('trophy.monster_type.spirits'),
         'items',
         'trophy_monster_types',
         'en',
         'Spirits'
    WHERE true
  UNION ALL
  SELECT ck_id('trophy.monster_type.vampires'),
         'items',
         'trophy_monster_types',
         'ru',
         'Вампиры'
    WHERE true
  UNION ALL
  SELECT ck_id('trophy.monster_type.vampires'),
         'items',
         'trophy_monster_types',
         'en',
         'Vampires'
    WHERE true
  UNION ALL
  SELECT ck_id('trophy.monster_type.ogres'),
         'items',
         'trophy_monster_types',
         'ru',
         'Огры'
    WHERE true
  UNION ALL
  SELECT ck_id('trophy.monster_type.ogres'),
         'items',
         'trophy_monster_types',
         'en',
         'Ogres'
    WHERE true
  UNION ALL
  SELECT ck_id('trophy.monster_type.beasts'),
         'items',
         'trophy_monster_types',
         'ru',
         'Звери'
    WHERE true
  UNION ALL
  SELECT ck_id('trophy.monster_type.beasts'),
         'items',
         'trophy_monster_types',
         'en',
         'Beasts'
    WHERE true
) foo
ON CONFLICT (id, lang) DO NOTHING;

WITH raw_data (
  tr_id, source_id, monster_type_key, availability_key,
  name_ru, name_en,
  effect_ru, effect_en
) AS ( VALUES
  -- Проклятые (Cursed)
  ('TR001','exp_toc','trophy.monster_type.cursed','availability.U',
    'Игоша','Botchling',
    'Вас Опасаются, и если вас уже опасались, бонусы удваиваются.','You become Feared and if you already were Feared the bonuses are doubled.'),
  ('TR002','exp_toc','trophy.monster_type.cursed','availability.U',
    'Вендиго','Vendigo',
    'Вы невосприимчивы к болезням.','You are immune to diseases.'),
  ('TR003','exp_toc','trophy.monster_type.cursed','availability.U',
    'Оборотень','Werewolf',
    'Вы получаете +2 к проверкам Силы и Выживания в дикой природе.','You gain a +2 to Physique and Wilderness Survival checks.'),
  -- Дракониды (Draconids)
  ('TR004','exp_toc','trophy.monster_type.draconids','availability.U',
    'Куролиск','Cockatrice',
    'Ваши атаки имеют 10% шанс ошеломить противника.','Your attacks have a 10% chance to stagger your opponent.'),
  ('TR005','exp_toc','trophy.monster_type.draconids','availability.U',
    'Феникс','Phoenix',
    'Вы снижаете вероятность загореться на 50% (минимум до 0%).','You reduce the chances you have to catch on fire by 50% (Minimum 0%).'),
  ('TR006','exp_toc','trophy.monster_type.draconids','availability.U',
    'Ослизг','Slyzard',
    'Вы получаете +2 к Сотворению заклинаний при сотворении огненных заклинаний и знаков.','You add +2 to Spell Casting when casting fire-based spells and signs.'),
  ('TR007','exp_toc','trophy.monster_type.draconids','availability.U',
    'Виверна','Wyvern',
    'Существа, которым вы наносите урон своими атаками, с вероятностью 25% могут быть отравлены.','Creatures you damage with your attacks have a 25% chance to be poisoned.'),
  -- Элементали (Elementals)
  ('TR008','exp_toc','trophy.monster_type.elementals','availability.U',
    'Земляной элементаль','Earth Elemental',
    'Ваши атаки наносят двойной разрушающий урон оружию, щитам или доспехам.','Your attacks deal double ablation damage to weapons, shields, or armor.'),
  ('TR009','exp_toc','trophy.monster_type.elementals','availability.U',
    'Огненный элементаль','Fire Elemental',
    'Существа, которым вы наносите урон своими атаками, имеют 25% шанс загореться.','Creatures you damage with your attacks have a 25% chance to catch on fire.'),
  ('TR010','exp_toc','trophy.monster_type.elementals','availability.U',
    'Голем','Golem',
    'Вы невосприимчивы к кровотечению.','You are immune to bleeding.'),
  ('TR011','exp_toc','trophy.monster_type.elementals','availability.U',
    'Ледяной элементаль','Ice Elemental',
    'Существа, которым вы наносите урон своими атаками, с вероятностью 25% могут быть заморожены.','Creatures you damage with your attacks have a 25% chance to be frozen.'),
  -- Гибриды (Hybrids)
  ('TR012','exp_toc','trophy.monster_type.hybrids','availability.U',
    'Грифон','Griffin',
    'При броске на критическое ранение сделайте бросок дважды и сохраните результат по вашему выбору.','When rolling for a critical wound, roll twice and keep the result of your choice.'),
  ('TR013','exp_toc','trophy.monster_type.hybrids','availability.U',
    'Мантикора','Manticore',
    'Вы повышаете СЛ сопротивления или снятия эффектов используемых вами ядов на 2.','You raise the DC to resist or remove the effects of poisons you use by 2.'),
  ('TR014','exp_toc','trophy.monster_type.hybrids','availability.U',
    'Суккуб','Succubus',
    'Ваш социальный статус повышается на одну ступень (Ненавидимые → Терпимые, Терпимые → Равные).','Your social standing improves by one step (Hated becomes Tolerated, Tolerated becomes Equal).'),
  -- Инсектоиды (Insectoids)
  ('TR015','exp_toc','trophy.monster_type.insectoids','availability.U',
    'Главоглаз','Arachasae',
    'Вы невосприимчивы к яду.','You are immune to poison.'),
  ('TR016','exp_toc','trophy.monster_type.insectoids','availability.U',
    'Химера','Frightener',
    'Вы получаете сопротивление рубящему, колющему или дробящему урону. Каждый день вы можете менять тип урона, к которому у вас есть сопротивление.','You gain resistance to either slashing, piercing, or bludgeoning damage. Each day, you can change which type of damage you have resistance to.'),
  -- Некрофаги (Necrophages)
  ('TR017','exp_toc','trophy.monster_type.necrophages','availability.U',
    'Утковол','Bullvore',
    'Если вы станете целью Некрофага, а в пределах досягаемости есть другая цель, Некрофаг выбирает другую цель.','If you would be targeted by a Necrophage and there is another target within range, the Necrophage chooses the other target.'),
  ('TR018','exp_toc','trophy.monster_type.necrophages','availability.U',
    'Туманник','Foglet',
    'Вы получаете +2 к проверкам Скрытности и Ловкости рук.','You gain a +2 to Stealth and Sleight of Hand checks'),
  ('TR019','exp_toc','trophy.monster_type.necrophages','availability.U',
    'Кладбищенская баба','Grave Hag',
    'Вы получаете +2 к проверкам Проведения Ритуалов и Наложению Порчи.','You gain a +2 to Ritual Crafting and Hex Weaving checks'),
  -- Реликты (Relicts)
  ('TR020','exp_toc','trophy.monster_type.relicts','availability.U',
    'Бес','Fiend',
    'Вы получаете +2 к проверкам Сотворения заклинаний и Сопротивления магии.','You gain a +2 to Spell Casting and Resist Magic checks'),
  ('TR021','exp_toc','trophy.monster_type.relicts','availability.U',
    'Леший','Leshen',
    'Животные и звери понимают вашу речь, и вы можете вступить с ними в словесную дуэль, чтобы заставить их подчиняться. Однако животное или зверь никогда не сделает для вас того, чего не сделал бы ради себя (например, не прыгнет со скалы).','Animals and beasts can understand you when you speak and you can enter verbal combat with them to get them to obey you. Regardless, an animal or a beast will never do something for you it would not do for itself (for example, jump off a cliff).'),
  ('TR022','exp_toc','trophy.monster_type.relicts','availability.U',
    'Шарлей','Shaelmaar',
    'Вы получаете +2 к Сотворению заклинаний при сотворении заклинаний и знаков, основанных на земле.','You add +2 to Spell Casting when casting earth-based spells and signs'),
  -- Духи (Spirits)
  ('TR023','exp_toc','trophy.monster_type.spirits','availability.U',
    'Хим','Hym',
    'Когда наносимый вами урон полностью нейтрализуется бронёй, цель всё равно получает 4 урона, который проходит сквозь броню.','When the damage you deal is negated by armor, your target still takes 4 points of damage that goes through their armor.'),
  ('TR024','exp_toc','trophy.monster_type.spirits','availability.U',
    'Полуденница','Noonwraith',
    'Вы становитесь невосприимчивы к страху.','You become immune to fear.'),
  ('TR025','exp_toc','trophy.monster_type.spirits','availability.U',
    'Моровая дева','Pesta',
    'Вас постоянно окружает туча мух. Противники в ближнем бою с вами получают -2 ко всем действиям и с вероятностью 10% получают состояние «Болезнь». Из-за мух вы также получаете -2 к проверкам Соблазнения, Убеждения и Внешнего вида.','You are constantly surrounded by a cloud of flies. Opponents in melee with you have a -2 to their actions and a 10% chance to gain the diseased condition. You also take a -2 to Seduction, Persuasion, and Grooming and Style because of the flies.'),
  -- Вампиры (Vampires)
  ('TR026','exp_toc','trophy.monster_type.vampires','availability.U',
    'Брукса','Bruxa',
    'Вы можете телепатически общаться с персонажами в пределах 20 метров от вас.','You can communicate telepathically with characters within 20m of you.'),
  ('TR027','exp_toc','trophy.monster_type.vampires','availability.U',
    'Гаркаин','Garkain',
    'Если при Спасброске от оглушения вы должны уменьшить своё Оглушение, уменьшите его на 1 меньше. Если уменьшения нет, ваше Значение оглушения считается на 1 выше.','If you would subtract from your Stun on a Stun Save subtract one less. If there is no subtraction your Stun Value is counted as 1 higher.'),
  ('TR028','exp_toc','trophy.monster_type.vampires','availability.U',
    'Катакан','Katakan',
    'Существа, которым вы наносите урон своими атаками, с вероятностью 25% могут получить кровотечение.','Creatures you damage with your attacks have a 25% chance to bleed.'),
  -- Огры (Ogres)
  ('TR029','exp_toc','trophy.monster_type.ogres','availability.U',
    'Циклоп','Cyclops',
    'Когда заклинание должно оглушить вас, вы можете атаковать ближайшую живую цель, чтобы сопротивляться эффекту оглушения. Любые другие эффекты магии применяются как обычно.','When you would be stunned by a spell, you can choose to attack the nearest living target to you to resist the stun effect. Any other effects from the magic apply as normal.'),
  ('TR030','exp_toc','trophy.monster_type.ogres','availability.U',
    'Скальный тролль','Rock Trolls',
    'Вы увеличиваете на 1 множитель дальности метательного оружия, которым владеете.','You add 1 to the range multiplier of thrown weapons you wield.'),
  ('TR031','exp_toc','trophy.monster_type.ogres','availability.U',
    'Тролль','Troll',
    'Чтобы опьянеть, вам требуется вдвое больше алкоголя, и у вас никогда не бывает похмелья.','It takes twice as much alcohol to get you intoxicated, and you never get hung over.'),
  -- Звери (Beasts)
  ('TR032','exp_toc','trophy.monster_type.beasts','availability.U',
    'Медведь','Bear',
    'Люди, которых вы захватываете, получают штраф -2 при попытке вырваться из захвата.','People you grapple have a -2 penalty on their attempt to escape your grapple.'),
  ('TR033','exp_toc','trophy.monster_type.beasts','availability.U',
    'Пантера','Panther',
    'Вы удваиваете свою скорость лазания.','You double your climbing speed.')
),
ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    -- Trophy names
    SELECT ck_id('witcher_cc.items.trophy.name.'||rd.tr_id),
           'items',
           'trophy_names',
           'ru',
           rd.name_ru
      FROM raw_data rd
     WHERE nullif(rd.name_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.items.trophy.name.'||rd.tr_id),
           'items',
           'trophy_names',
           'en',
           rd.name_en
      FROM raw_data rd
     WHERE nullif(rd.name_en,'') IS NOT NULL
    UNION ALL
    -- Trophy effects
    SELECT ck_id('witcher_cc.items.trophy.effect.'||rd.tr_id),
           'items',
           'trophy_effects',
           'ru',
           rd.effect_ru
      FROM raw_data rd
     WHERE nullif(rd.effect_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.items.trophy.effect.'||rd.tr_id),
           'items',
           'trophy_effects',
           'en',
           rd.effect_en
      FROM raw_data rd
     WHERE nullif(rd.effect_en,'') IS NOT NULL
  ) foo
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO wcc_item_trophies (
  tr_id, dlc_dlc_id, name_id,
  monster_type_id, availability_id,
  effect_id, price
)
SELECT rd.tr_id
     , rd.source_id AS dlc_dlc_id
     , ck_id('witcher_cc.items.trophy.name.'||rd.tr_id) AS name_id
     , ck_id(rd.monster_type_key) AS monster_type_id
     , ck_id(rd.availability_key) AS availability_id
     , ck_id('witcher_cc.items.trophy.effect.'||rd.tr_id) AS effect_id
     , 0 AS price
  FROM raw_data rd
ON CONFLICT (tr_id) DO UPDATE
SET
  dlc_dlc_id = EXCLUDED.dlc_dlc_id,
  name_id = EXCLUDED.name_id,
  monster_type_id = EXCLUDED.monster_type_id,
  availability_id = EXCLUDED.availability_id,
  effect_id = EXCLUDED.effect_id,
  price = EXCLUDED.price;

