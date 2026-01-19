CREATE TABLE IF NOT EXISTS wcc_item_effects (
    e_id           varchar(10) PRIMARY KEY, -- e.g. 'E001'
    name_id        uuid NOT NULL,           -- ck_id('witcher_cc.items.effect.name.'||e_id)
    description_id uuid                     -- ck_id('witcher_cc.items.effect.description.'||e_id)
);

COMMENT ON TABLE wcc_item_effects IS
  'Справочник эффектов для предметов/оружия. Локализуемые поля вынесены в i18n_text через детерминированные UUID (ck_id).';

COMMENT ON COLUMN wcc_item_effects.e_id IS
  'ID эффекта (например E001). Первичный ключ.';

COMMENT ON COLUMN wcc_item_effects.name_id IS
  'i18n UUID для названия эффекта. Генерируется детерминированно: ck_id(''witcher_cc.items.effect.name.''||e_id).';

COMMENT ON COLUMN wcc_item_effects.description_id IS
  'i18n UUID для описания эффекта. Генерируется детерминированно: ck_id(''witcher_cc.items.effect.description.''||e_id).';

WITH raw_data (e_id, name_ru, name_en, description_ru, description_en) AS ( VALUES
    ('E001', 'Бешенство', 'Fury', 'Цель атакует ближайшее существо каждый раунд, пока не пройдет проверку на устойчивость (СЛ18)', 'The target attacks the nearest creature each round until it passes a Stamina check (DC 18).'),
    ('E002', 'Ближний бой арбалетом', 'Crossbow Melee', 'Арбалет можно использовать как Дробящее оружие с тем же уроном, но штрафом к Точности (-1)', 'A crossbow can be used as a bludgeoning weapon with the same damage, but with an Accuracy penalty (-1).'),
    ('E003', 'Взрывное (<mod>м)', 'Explosive (<mod>m)', 'Урон по всем частям тела в радиусе <mod> метров', 'Deals damage to all body locations within a radius of <mod> meters.'),
    ('E004', 'Горение (<mod>)', 'Burning (<mod>)', 'С вероятностью <mod> поджигает цель при нанесении урона.', 'With a <mod>% chance, sets the target on fire when dealing damage.'),
    ('E005', 'Густая кровь (-<mod>)', 'Thick Blood (-<mod>)', 'Шанс кровотечения снижается на <mod>', 'Bleeding chance is reduced by <mod>.'),
    ('E006', 'Двимеритовая пыль', 'Dimeritium Dust', 'Не позволяет использовать магию в зоне действия в течение 20 ходов.', 'Prevents the use of magic in the affected area for 20 rounds.'),
    ('E007', 'Двойной урон ядом', 'Double Poison Damage', 'Если цель отравлена, то получает 6 урона ядом каждый ход вместо 3.', 'If the target is poisoned, it takes 6 poison damage each turn instead of 3.'),
    ('E008', 'Дезориентирующее (<mod>)', 'Disorienting (<mod>)', 'При ударе по туловищу или голове, цель должна совершить проверку Устойчивости со штрафом (<mod>)', 'When hit in the torso or head, the target must make a Stamina check with a (<mod>) penalty.'),
    ('E009', 'Длинное', 'Long', '', ''),
    ('E010', 'Доп. Атлетика (<mod>)', 'Bonus Athletics (<mod>)', '', ''),
    ('E011', 'Доп. Верховая езда (<mod>)', 'Bonus Riding (<mod>)', '', ''),
    ('E012', 'Доп. Внешний вид (<mod>)', 'Bonus Appearance (<mod>)', '', ''),
    ('E013', 'Доп. Здоровье (<mod>)', 'Bonus Health (<mod>)', '', ''),
    ('E014', 'Доп. Лидерство (<mod>)', 'Bonus Leadership (<mod>)', '', ''),
    ('E015', 'Доп. Наведение порчи (<mod>)', 'Bonus Hex Weaving (<mod>)', '', ''),
    ('E016', 'Доп. Надёжность (<mod>)', 'Bonus Reliability (<mod>)', '', ''),
    ('E017', 'Доп. Пункты Брони (<mod>)', 'Bonus Armor Points (<mod>)', '', ''),
    ('E018', 'Доп. Скорость ездового животного (<mod>)', 'Bonus Mount Speed (<mod>)', '', ''),
    ('E019', 'Доп. Скрытность (<mod>)', 'Bonus Stealth (<mod>)', '', ''),
    ('E020', 'Доп. слот на броне', 'Extra Armor Slot', 'Место на броне под глиф или руну. Максимум (3). Для добавления броня должна быть в идеально не поврежденном состоянии.', 'A slot on the armor for a glyph or rune. Maximum (3). To add it, the armor must be in perfect, undamaged condition.'),
    ('E021', 'Доп. Соблазнение (<mod>)', 'Bonus Seduction (<mod>)', '', ''),
    ('E022', 'Доп. Сопротивление магии (<mod>)', 'Bonus Magic Resistance (<mod>)', '', ''),
    ('E023', 'Доп. Сотворение заклинаний (<mod>)', 'Bonus Spell Casting (<mod>)', '', ''),
    ('E024', 'Доп. Точность (<mod>)', 'Bonus Accuracy (<mod>)', '', ''),
    ('E025', 'Доп. Урон (<mod>)', 'Bonus Damage (<mod>)', '', ''),
    ('E026', 'Доп. урон призракам (<mod>)', 'Bonus Damage vs Ghosts (<mod>)', '', ''),
    ('E027', 'Доп. Харизма (<mod>)', 'Bonus Charisma (<mod>)', '', ''),
    ('E028', 'Доп. Храбрость (<mod>)', 'Bonus Courage (<mod>)', '', ''),
    ('E029', 'Заморозка (<mod>)', 'Freeze (<mod>)', 'С вероятностью 30% замораживает цель при нанесении урона.', 'With a 30% chance, freezes the target when dealing damage.'),
    ('E030', 'Застревающий наконечник', 'Barbed Head', 'Кровотечение можно прекратить только совершив проверку Первой помощи (СЛ16) для извлечения наконечника из раны.', 'Bleeding can only be stopped by making a First Aid check (DC 16) to remove the head from the wound.'),
    ('E031', 'Захватное', 'Grappling', 'Можно использовать для захвата и подсечки противника в пределах дистанции.', 'Can be used to grapple and trip an opponent within reach.'),
    ('E032', 'Зима', 'Winter', 'С вероятностью 100% замораживает цель на 8 ходов. Можно снять проверкой на Силу (СЛ18) или будучи атакованным, тогда Доп. урон (2d6)', 'With a 100% chance, freezes the target for 8 rounds. Can be removed with a Strength check (DC 18), or by being attacked (then bonus damage (2d6)).'),
    ('E033', 'Командная перезарядка', 'Team Reload', 'Чтобы перезарядить это оружие, требуется потратить 2 действия. Эти действия могут быть совершены двумя разными персонажами.', 'Reloading this weapon requires spending 2 actions. These actions may be taken by two different characters.'),
    ('E034', 'Критическая казнь', 'Critical Execution', 'При крите ведьмачьим оружием тяжесть крита поднимается на ступень. Лёгкое ранение становится средним, среднее - тяжёлым, а тяжёлое - смертельным.', 'On a critical hit with a witcher weapon, the critical severity increases by one step: Light becomes Medium, Medium becomes Severe, and Severe becomes Deadly.'),
    ('E035', 'Критическая магия', 'Critical Magic', 'При крите ведьмачьим оружием можете пробросить проверку Сотворения заклинаний чтобы сотворить знак без штрафов и траты выносливости (кроме базовой цены сотворения знака).', 'On a critical hit with a witcher weapon, you may roll Spell Casting to cast a Sign without penalties and without spending Stamina (except the Sign’s base cost).'),
    ('E036', 'Критический натиск', 'Critical Rush', 'При крите ведьмачьим оружием можете пробросить проверку Разоружения или Подсечки без штрафов и траты выносливости.', 'On a critical hit with a witcher weapon, you may roll Disarm or Trip without penalties and without spending Stamina.'),
    ('E037', 'Критическое блокирование', 'Critical Shield Bash', 'Когда проброс попытки Парирования или Блокирования ведьмачьим щитом сильнее попытки атаки на 5 и больше, вы можете нанести удар щитом без штрафов и траты выносливости, который отбросит противника на 4м и собьет его с ног.', 'When your Parry or Block attempt with a witcher shield exceeds the attack roll by 5 or more, you may bash with the shield without penalties or Stamina cost, knocking the opponent back 4m and knocking them prone.'),
    ('E038', 'Критическое парирование', 'Critical Riposte', 'Когда проброс попытки Парирования ведьмачьим оружием сильнее попытки атаки на 5 и больше, вы можете нанести удар этим оружием без штрафов и траты выносливости.', 'When your Parry attempt with a witcher weapon exceeds the attack roll by 5 or more, you may strike with that weapon without penalties or Stamina cost.'),
    ('E039', 'Критическое ускорение', 'Critical Speed', 'При крите ведьмачьим оружием можете нанести дополнительный удар без штрафов и траты выносливости.', 'On a critical hit with a witcher weapon, you may make an additional strike without penalties or Stamina cost.'),
    ('E040', 'Кровопускающее (<mod>)', 'Bloodletting (<mod>)', 'С вероятностью <mod> вызывает у цели кровотечение при нанесении урона.', 'With a <mod>% chance, causes the target to bleed when dealing damage.'),
    ('E041', 'Крупный калибр', 'Large Caliber', 'Боеприпас предназначен для оружия "Скорпио".', 'This ammunition is intended for the weapon "Scorpio".'),
    ('E042', 'Ловящие лезвия', 'Catching Blades', 'При успешном блоке атаки этим оружием, оба оружия становятся бесполезными и не могут быть разделены до тех пор, пока противник не сможет пройти проверку Силы или Ловкости рук, которая превзойдет изначальную проверку Владения лёгкими клинками, или пока владелец не выпустит свое оружие.', 'On a successful block with this weapon, both weapons become locked together and cannot be separated until the opponent passes a Strength or Sleight of Hand check that exceeds the original Small Blade skill check, or until the wielder releases their weapon.'),
    ('E043', 'Лунная пыль', 'Moon Dust', 'Покрывает невидимые объекты россыпью частиц на 20 ходов, делая их видимыми, осязаемыми, а также цель не может регенировать и трансформироваться.', 'Covers invisible objects with a cloud of particles for 20 rounds, making them visible and tangible; the target also cannot regenerate or transform.'),
    ('E044', 'Магические путы', 'Magic Shackles', 'Невозможность невидимости, неосязаемости и телепорта при контакте с оружием.', 'Prevents invisibility, intangibility, and teleportation while in contact with the weapon.'),
    ('E045', 'Медленно перезаряжающееся', 'Slow Reload', 'Для перезарядки требуется 1 действие.', 'Reloading requires 1 action.'),
    ('E046', 'Метаемое (<mod>)', 'Thrown (<mod>)', 'Оружие можно метать на <mod> метра(ов)', 'The weapon can be thrown up to <mod> meter(s).'),
    ('E047', 'Метеоритное', 'Meteorite', 'Полный урон чудовищам, уязвимым к метеоритной стали. Доп. Надёжность снаряжения (+5)', 'Deals full damage to monsters vulnerable to meteorite steel. Bonus gear reliability (+5).'),
    ('E048', 'Метка вонючей краской', 'Stinky Paint Mark', 'Метка держится 1 сутки на расстоянии до полутора километров. Дополнительные +5 к проверке при попытке выследить или заметить цель. Можно смыть за 3 хода или перебить чем-то (духи, валяние в грязи), тогда Доп. Выслеживание падает до (+2).', 'The mark lasts 1 day at a distance of up to 1.5 km. Grants +5 to checks to track or notice the target. Can be washed off in 3 rounds or masked (perfume, rolling in mud), reducing the tracking bonus to (+2).'),
    ('E049', 'Незаметное', 'Inconspicuous', 'Дополнительные (+2) при попытке скрыть это оружие.', 'Grants an additional (+2) when attempting to conceal this weapon.'),
    ('E050', 'Несмертельное', 'Nonlethal', 'Можно использовать для нанесения несмертельного урона без штрафов.', 'Can be used to deal nonlethal damage without penalties.'),
    ('E051', 'Облако газа', 'Gas Cloud', 'Создает на 3 хода взрывоопасное облако газа, которое может дрейфовать в случайном направлении. При взрыве наносит 5d6 урона.', 'Creates an explosive gas cloud for 3 rounds that may drift in a random direction. If ignited, it deals 5d6 damage.'),
    ('E052', 'Огнеупорный', 'Fireproof', 'Элемент брони не получает повреждений от огненных атак.', 'This armor element takes no damage from fire attacks.'),
    ('E053', 'Ограничение зрения', 'Restricted Vision', 'При опущенном забрале, конус поля зрения сужается до 90 градусов и для ведьмаков отключается способность "Обостренные чувства".', 'With the visor down, the field of view narrows to a 90-degree cone and witchers lose the "Heightened Senses" ability.'),
    ('E054', 'Опутывающее', 'Entangling', 'Опутывает цель. Опутанная цель снижает Скор на 5 и получает (-2) штраф ко всем физическим действиям. Чтобы высвободиться нужен проброс со СЛ18 Уклонение/Изворотливость/Борьбу или 1 действие помощи кого-то другого.', 'Entangles the target. An entangled target reduces SPD by 5 and takes a (-2) penalty to all physical actions. To break free requires a DC 18 Dodge/Escape Artist/Wrestling check, or 1 action of help from another character.'),
    ('E055', 'Отравленное (<mod>)', 'Poisoned (<mod>)', 'С вероятностью <mod> отравляет цель при нанесении урона', 'With a <mod>% chance, poisons the target when dealing damage.'),
    ('E056', 'Отторжение магии', 'Magic Rejection', 'Если доспех надет на адепта магии, то скованность движений доспеха равна (5).', 'If the armor is worn by a magic adept, the armor’s encumbrance is (5).'),
    ('E057', 'Ошеломление (<mod>)', 'Stun (<mod>)', 'С вероятностью <mod> ошеломляет цель при нанесении урона', 'With a <mod>% chance, stuns the target when dealing damage.'),
    ('E058', 'Парирующее', 'Parrying', '(-2) к штрафу при парировании.', 'Reduces the Parry penalty by (-2).'),
    ('E059', 'Пахучее', 'Scented', 'Пока боеприпас остаётся в теле цели, выслеживание по запаху не требует проверок, если следу менее половины суток.', 'While the ammunition remains in the target’s body, tracking by smell requires no checks if the trail is less than half a day old.'),
    ('E060', 'Перелом ноги', 'Broken Leg', 'Критическое ранение "Перелом ноги" при отсутстви брони ног.', 'Inflicts the "Broken Leg" critical injury if the target has no leg armor.'),
    ('E061', 'Подвижная перезарядка', 'Mobile Reload', '', ''),
    ('E062', 'Полное укрытие', 'Full Cover', 'Если присесть за щитом, то щит рассматривается как укрытие, снижая любой проходящий урон на количество своей прочности.', 'If you crouch behind the shield, it counts as cover, reducing any incoming damage by its durability.'),
    ('E063', 'Пробивающее броню', 'Armor Piercing', 'Игнорирует сопротивление урону любой брони, по которой оно попадает.', 'Ignores the damage resistance of any armor it hits.'),
    ('E064', 'Пробивающее броню (+)', 'Armor Piercing (+)', 'Игнорирует сопротивление урону любой брони и половину прочности брони, по которой оно попадает.', 'Ignores the damage resistance of any armor it hits and half of that armor’s durability.'),
    ('E065', 'Прочность Чернобога', 'Blackbog Durability', 'С вероятностью 50% оружие не получает урон, когда должно.', 'With a 50% chance, the weapon takes no damage when it otherwise would.'),
    ('E066', 'Разделяющееся (<mod>)', 'Splitting', 'При выстреле связка снарядов разделяется на <mod> отдельных. Цель получает дополнительное попадание в случайную часть тела за каждое очко выше защиты до <mod>.', 'When fired, the bundle splits into <mod> separate projectiles. The target suffers an additional hit to a random body location for each point your roll exceeds the target’s defense (up to <mod>).'),
    ('E067', 'Разрушающее', 'Ablating', 'При попадании это оружие наносит 1d6/2 урона Прочности брони.', 'On a hit, this weapon deals 1d6/2 damage to armor durability.'),
    ('E068', 'Рвение Перуна', 'Perun’s Zeal', 'Удваивает количество получаемых дайсов адреналина.', 'Doubles the number of adrenaline dice gained.'),
    ('E069', 'Реликвия (<mod>)', 'Relic (<mod>)', 'Если пробросить Образование со СЛ<mod>, то вы вспомните историю этой реликвии', 'If you roll Education at DC <mod>, you recall the history of this relic.'),
    ('E070', 'Рукопашное', 'Brawling', 'Такое оружие использует навык Борьба. Его урон прибавляется к урону от атаки без оружия.', 'This weapon uses the Wrestling skill. Its damage is added to your unarmed attack damage.'),
    ('E071', 'Сбалансированное', 'Balanced', 'При крит.ранении по цели бросаете 2d6+2 вместо 2d6 и 1d6+1 вместо 1d6.', 'When rolling for critical injuries on the target, roll 2d6+2 instead of 2d6, and 1d6+1 instead of 1d6.'),
    ('E072', 'Свечение', 'Glow', 'В радиусе пяти метров повышает уровень освещенности на 1.', 'Within a 5-meter radius, increases the light level by 1.'),
    ('E073', 'Серебряное (<mod>)', 'Silvered (<mod>)', 'Доп.урон <mod> по существам, уязвимым к серебру.', 'Deals bonus damage <mod> to creatures vulnerable to silver.'),
    ('E074', 'Скользкий пол', 'Slippery Floor', 'Цель с ногами бросает Атлетику чтобы не оказаться сбитой с ног. СЛ14 для двуногого, СЛ12 для четвероногого, СЛ10 для остальных.', 'A target with legs rolls Athletics to avoid being knocked prone: DC 14 for bipeds, DC 12 for quadrupeds, DC 10 for others.'),
    ('E075', 'Сложные раны', 'Complex Wounds', 'Проверки стабилизации критических ранений получают (+3) к Сложности.', 'Stabilization checks for critical wounds gain (+3) Difficulty.'),
    ('E076', 'Сопротивление (Д)', 'Resistance (B)', 'Урон атак с дробящим уроном снижается вдвое.', 'Damage from bludgeoning attacks is halved.'),
    ('E077', 'Сопротивление (К)', 'Resistance (P)', 'Урон атак с колящим уроном снижается вдвое.', 'Damage from piercing attacks is halved.'),
    ('E078', 'Сопротивление (Р)', 'Resistance (S)', 'Урон атак с рубящим уроном снижается вдвое.', 'Damage from slashing attacks is halved.'),
    ('E079', 'Сопротивление (С)', 'Resistance (E)', 'Урон атак со стихийным уроном снижается вдвое.', 'Damage from elemental attacks is halved.'),
    ('E080', 'Сопротивление кровотечению', 'Bleeding Resistance', 'Урон от эффектов кровотечения уменьшен вдвое.', 'Damage from bleeding effects is halved.'),
    ('E081', 'Сопротивление огню', 'Fire Resistance', 'Урон от атак огнем снижается вдвое.', 'Damage from fire attacks is halved.'),
    ('E082', 'Сопротивление отравлению', 'Poison Resistance', 'Урон от эффектов отравления уменьшен вдвое.', 'Damage from poison effects is halved.'),
    ('E083', 'Таранящее', 'Charging', 'В случае атаки оружием верхом и с резбега, количество бонусных кубов урона (до 5) равно расстоянию до цели, т.е. не нужно делить расстояние пополам как для обычного оружия.', 'When attacking while mounted and with a run-up, the number of bonus damage dice (up to 5) equals the distance to the target; you do not halve the distance as with normal weapons.'),
    ('E084', 'Текстиль низушков', 'Halfling Textile', 'Доспех выглядит как обычная одежда. Можно понять, что это броня при успешной проверке Внимания со СЛ20.', 'The armor looks like ordinary clothing. You can tell it is armor with a successful Awareness check (DC 20).'),
    ('E085', 'Удар щитом', 'Shield Strike', 'Пробросьте Ближний бой. При успехе цель получает смертельный урон, равный урону ударом рукой.', 'Roll Melee. On success, the target takes lethal damage equal to your fist strike damage.'),
    ('E086', 'Удар щитом (<mod>)', 'Shield Strike (<mod>)', 'Пробросьте Ближний бой. При успехе цель получает смертельный урон, равный урону ударом рукой и дополнительно (<mod>).', 'Roll Melee. On success, the target takes lethal damage equal to your fist strike damage, plus (<mod>).'),
    ('E087', 'Улучшение лечения (+1)', 'Improved Healing (+1)', 'При каждом лечении вы получаете 1 дополнительный Пункт Здоровья.', 'Each time you heal, you gain 1 additional Health Point.'),
    ('E088', 'Усиление магии', 'Magic Amplification', 'При атаке магией вы можете выбрать или СЛ защиты от магии возрастет на (+3), или урон возрастет на 1d6', 'When attacking with magic, you may choose either to increase the DC to defend against your spell by (+3), or increase the damage by 1d6.'),
    ('E089', 'Устанавливаемое', 'Deployable', 'Для использования оружие нужно разложить за 1 действие. Переносить разложенное оружие нельзя. Чтобы собрать нужно также потратить 1 действие.', 'To use this weapon, you must deploy it with 1 action. You cannot carry it while deployed. Packing it up also requires 1 action.'),
    ('E090', 'Установка на подставку', 'Stand Mount', 'Щит может стоять сам без поддержки (требует действие на установку, переустановку), но тогда используется только как укрытие (без блокирования). Падает при получении урона больше половины прочности.', 'A shield can stand on its own (requires an action to set up or reposition), but then it is used only as cover (no blocking). It falls if it takes damage greater than half its durability.'),
    ('E091', 'Фокусирующее (+)', 'Focusing (+)', '(+2) к СЛ проверок против вашего заклинания', '(+2) to the DC of checks made against your spell.'),
    ('E092', 'Фокусирующее (<mod>)', 'Focusing (<mod>)', 'При сотворении магии с помощью этого оружия вычтите <mod> из стоимости заклинания в Выносливости.', 'When casting magic using this weapon, subtract <mod> from the spell’s Stamina cost.'),
    ('E093', 'Шприц', 'Syringe', 'Это оружие может быть заряжено флаконом с любым ядом или эликсиром. (+3) к СЛ для избавления от яда или (+3 хода) к продолжительности действия эликсира', 'This weapon can be loaded with a vial of any poison or potion. Grants (+3) to the DC to resist/remove the poison, or (+3 rounds) to the potion’s duration.'),
    ('E094', 'Эффект синергии "Баланс"', 'Synergy Effect "Balance"', 'Изменение Скованности Движений брони на (-1)', 'Changes armor encumbrance by (-1).'),
    ('E095', 'Эффект синергии "Воздаяние"', 'Synergy Effect "Retribution"', 'При получении урона атакующий полчает (3) неблокируемого урона в туловище.', 'When you take damage, the attacker takes (3) unblockable damage to the torso.'),
    ('E096', 'Эффект синергии "Закрепление"', 'Synergy Effect "Reinforcement"', 'Доп. Надёжность экипировки (+5)', 'Bonus gear reliability (+5).'),
    ('E097', 'Эффект синергии "Истощение"', 'Synergy Effect "Exhaustion"', 'Доп. Нелетальный урон (+1d6) магией при использовании оружия как фокусирующее.', 'Bonus nonlethal magic damage (+1d6) when using the weapon as a focus.'),
    ('E098', 'Эффект синергии "Кольцо"', 'Synergy Effect "Ring"', 'Атакующее существо не получает бонусов при атаке за пределами вашего обзора.', 'An attacking creature gains no bonuses when attacking from outside your field of view.'),
    ('E099', 'Эффект синергии "Обновление"', 'Synergy Effect "Refresh"', 'Восстановление выносливости на значение Отдых при убийстве врага этим оружием.', 'Restore Stamina equal to your Rest value when you kill an enemy with this weapon.'),
    ('E100', 'Эффект синергии "Отражение"', 'Synergy Effect "Reflection"', 'Даёт навык Отбивание стрел с двойным штрафом. Или Доп. Отбивание стрел (+2), если оно уже есть.', 'Grants the Deflect Arrows skill with double penalty, or Bonus Deflect Arrows (+2) if you already have it.'),
    ('E101', 'Эффект синергии "Продление"', 'Synergy Effect "Extension"', 'Удваивает количество дайсов для получение времени действия магии, если оружие использовано как фокусирующее.', 'Doubles the number of dice used to determine the duration of magic if the weapon is used as a focus.'),
    ('E102', 'Эффект синергии "Пылание"', 'Synergy Effect "Blazing"', 'Смена типа урона на стихийный (огонь). Не поджигает цель.', 'Changes the damage type to elemental (fire). Does not set the target on fire.'),
    ('E103', 'Эффект синергии "Рассечение"', 'Synergy Effect "Cleave"', 'Доп. Разрушение брони или щита (+1) при пробитии.', 'Bonus Sunder Armor or Shield (+1) on penetration.'),
    ('E104', 'Эффект синергии "Сияние"', 'Synergy Effect "Radiance"', 'Доспех сияет, доводя уровень освещенности вокруг до дневного света. Нужно (1) действие для активации на 30 минут. На монстров влияет как Солнце.', 'The armor shines, raising the surrounding light level to daylight. Requires (1) action to activate for 30 minutes. Affects monsters as sunlight.'),
    ('E105', 'Эффект синергии "Спокойствие"', 'Synergy Effect "Calm"', 'Снижает вдвое затраты Выносливости на использование дайсов Адреналин.', 'Halves the Stamina cost of spending Adrenaline dice.'),
    ('E106', 'Эффект синергии "Тяжесть"', 'Synergy Effect "Heaviness"', 'Доп. Прочность Брони (+2), Скованность Движений брони удваивается.', 'Bonus armor durability (+2); armor encumbrance is doubled.'),
    ('E107', 'Яркая вспышка', 'Bright Flash', 'Штраф к Устойчивости к ослеплению (-2). Цель получает слепоту на 6 ходов.', 'Penalty to Stamina vs blinding (-2). The target is blinded for 6 rounds.'),
    ('E108', 'Яркая вспышка (+)', 'Bright Flash (+)', 'Цель получает слепоту на 5 ходов. Если цель обладает ночным зрением, то получает дополнительные 5 ходов слепоты и ошеломление (дезориентацию для ночного зрения (+)).', 'The target is blinded for 5 rounds. If the target has night vision, it suffers an additional 5 rounds of blindness and is stunned (disoriented for night vision (+)).'),
    ('E109', 'Сокрушающая сила', 'Crushing Force', 'Удары оружием невозможно парировать. Разрушающий урон оружия удваивается.', 'Weapon strikes cannot be parried. The weapon''s bludgeoning damage is doubled.')
),
ins_names AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    SELECT ck_id('witcher_cc.items.effect.name.'||rd.e_id),
           'items',
           'effect_names',
           'ru',
           rd.name_ru
      FROM raw_data rd
     WHERE nullif(rd.name_ru,'') is not null
    UNION ALL
    SELECT ck_id('witcher_cc.items.effect.name.'||rd.e_id),
           'items',
           'effect_names',
           'en',
           rd.name_en
      FROM raw_data rd
     WHERE nullif(rd.name_en,'') is not null
  ) foo
  ON CONFLICT (id, lang) DO NOTHING
),
ins_descriptions AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    SELECT ck_id('witcher_cc.items.effect.description.'||rd.e_id),
           'items',
           'effect_descriptions',
           'ru',
           rd.description_ru
      FROM raw_data rd
     WHERE nullif(rd.description_ru,'') is not null
    UNION ALL
    SELECT ck_id('witcher_cc.items.effect.description.'||rd.e_id),
           'items',
           'effect_descriptions',
           'en',
           rd.description_en
      FROM raw_data rd
     WHERE nullif(rd.description_en,'') is not null
  ) foo
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO wcc_item_effects (e_id, name_id, description_id)
SELECT rd.e_id,
       ck_id('witcher_cc.items.effect.name.'||rd.e_id) AS name_id,
       CASE 
         WHEN nullif(rd.description_ru,'') IS NOT NULL OR nullif(rd.description_en,'') IS NOT NULL 
         THEN ck_id('witcher_cc.items.effect.description.'||rd.e_id)
         ELSE NULL
       END AS description_id
  FROM raw_data rd
ON CONFLICT (e_id) DO UPDATE
SET name_id = EXCLUDED.name_id,
    description_id = EXCLUDED.description_id;


