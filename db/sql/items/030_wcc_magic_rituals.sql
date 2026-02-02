\echo '030_wcc_magic_rituals.sql'
-- Magic rituals from temp TSV

CREATE TABLE IF NOT EXISTS wcc_magic_rituals (
  ms_id                 varchar(10) PRIMARY KEY,  -- e.g. 'MS104'
  dlc_dlc_id            varchar(64) NOT NULL REFERENCES wcc_dlcs(dlc_id),

  level_id              uuid NULL,                -- ck_id('level.*')
  form_id               uuid NULL,                -- ck_id('magic.form.*')
  effect_time_unit_id   uuid NULL,                -- ck_id('time.unit.*')
  preparing_time_unit_id uuid NOT NULL,           -- always time.unit.round (per rules)

  name_id               uuid NOT NULL,            -- ck_id('witcher_cc.magic.ritual.name.'||ms_id)
  effect_id             uuid NOT NULL,            -- ck_id('witcher_cc.magic.ritual.effect.'||ms_id)
  how_to_remove_id      uuid NULL,                -- ck_id('witcher_cc.magic.ritual.how_to_remove.'||ms_id)

  dc                    text NULL,
  preparing_time_value  integer NULL,
  ingredients           jsonb NULL,               -- [{"id":"<uuid>","qty":"<text|null>"}, ...]

  zone_size             text NULL,
  stamina_cast          text NULL,
  stamina_keeping       text NULL,
  effect_time_value     text NULL
);

WITH raw_data (
  ms_id, dlc_dlc_id,
  level_key,
  name_ru, name_en,
  effect_ru,
  how_to_remove_ru,
  dc,
  preparing_time_value,
  ingredients_raw,
  form_key,
  zone_size,
  stamina_cast, stamina_keeping,
  effect_time_value, effect_time_unit_key
) AS ( VALUES
  ('MS104', 'core', 'level.novice', 'Ритуал очищения', 'Cleansing Ritual', 'Очищает цель от ядов и болезней. - Избавляет на выбор с разной <b>Сл</b>:   * <b>Сл:12</b> - Алкоголь и нарктоики   * <b>Сл:15</b> - Яд и масла   * <b>Сл:18</b> - Болезни - Не может излечить Бич Катреоны.', '', '12-18', '5', 'I080 (1), I059 (1), I275 (2), I090 (2), T027 (1)', 'magic.form.direct', '', '3', '', '', ''),
  ('MS105', 'core', 'level.novice', 'Гидромантия', 'Hydromancy', 'Позволяет видеть на воде события послдних 2 дней.   * <b>Сл:15</b> - прошлые события   * <b>Сл:18</b> - текущие события - Маг в месте текущих событий может заметить слежку, пробросив <i>(Магические познания)</i> против вашего <i>(Проведения ритуалов)</i>', '', '15-18', '5', 'I262 (1), I069 (1), I027 (2), I064 (2), I077 (2), I073 (1)', 'magic.form.self', '', '5', '2', '', ''),
  ('MS106', 'core', 'level.novice', 'Магическое сообщение', 'Magical Message', 'Записывает в носитель сообщение в виде голограммы мага в полный рост. - Длительность до 5 минут. - Можно воспроизвести 1-3 раза (по желанию мага). - При записи на совершенный самоцвет запись как живая.', '', '12', '5', 'I027 (1), I078 (1), I005 (1), T039 (1)', 'magic.form.direct', '', '3', '', '', ''),
  ('MS107', 'core', 'level.novice', 'Пиромантия', 'Pyromancy', 'Позволяет видеть в пламени текущие события. - Маг в месте слежки может заметить её, пробросив <i>(Магические познания)</i> против вашего <i>(Проведения ритуалов)</i>', '', '15', '5', 'I263 (1), I027 (2), I001 (2), I058 (5), I059 (2), I013 (2)', 'magic.form.self', '', '5', '5', '', ''),
  ('MS108', 'core', 'level.novice', 'Ритуал жизни', 'Ritual of Life', 'Создает круг, исцеляющий круг.  - Действует на 1 цель  - Лечит 3 ПЗ в ход для цели внутри.  - Если цель покидает круг, он исчезает.', '', '15', '5', 'I275 (2), I001 (2), I013 (2), I098 (2)', 'magic.form.zone_circle', '', '5', '', '10', 'time.unit.round'),
  ('MS109', 'core', 'level.novice', 'Магический ритуал', 'Ritual of Magic', 'Создаёт круг, наполненный магией:  - Первая вошедшая цель, способ-ная к магии, получает к <b>Энергии</b> бонус +<i>(Проведение ритуалов)/2</i>.  - Действует только на 1 цель.  - Альтернатива: истощить круг, получив (1d6)/2 пятой эссенции', '', '15', '5', 'I275 (2), I005 (2), I086 (2), I089 (1)', 'magic.form.zone_circle', '', '3', '', '5', 'time.unit.hour'),
  ('MS110', 'core', 'level.novice', 'Сосуд заклятия', 'Spell Jar', '<align="left">Создает в запечатанном гляняном сосуде вихрь. - Срок годности ограничен. - При разбитии срабатывает случай-ное заклинание (1d10/2):   * Тюрьма Тальфрина   * Зефир   * Танио Ильхар   * Туман Дормина   * Статическая буря</align>', '', '15', '5', 'I041 (5), I027 (1), I011 (2), I275 (1), I013 (1), I067 (2), I089 (1)', 'magic.form.self', '', '5', '', '1d6', 'time.unit.day'),
  ('MS111', 'core', 'level.novice', 'Спиритический сеанс', 'Spirit Seance', E'Призывает дух умершего с его разумом и памятью, включая причину смерти.\n - Прогнать духа можно по его желанию или уничтожив.\n - Говорить с ним можно в месте захоронения.\n - Призывает и всех родственников ближе 20м.\n - Дух может вселиться в цель. Защита - бросок <i>(Сопротивления магии)</i> против <i>(Сотворения заклинаний)</i> сразу и каждые 1d6 ходов с той же <b>Сл</b>. При провале дух контролирует тело. Бонус +5 к <i>(Сопротивлению магии)</i> если поведение неприемлемо и +10, если опасно для жизни.', '', '12', '5', 'I264 (1), I098 (1), I062 (2), I100 (2), I086 (2)', 'magic.form.direct', '', '5', '', '', ''),
  ('MS112', 'core', 'level.novice', 'Телекоммуникация', 'Telecommunication', 'Позволяет общаться с другим обладателем такого устройства.  - Оба участника должны провести ритуал одновременно.', '', '0', '5', 'T112 (1)', 'magic.form.self', '{inf}', '3', '', '1', 'time.unit.hour'),
  ('MS113', 'core', 'level.journeyman', 'Освящение', 'Consecrate', 'Создает в обе стороны непрони-цаемый круг для чудовищ.  - Пройти в 1 сторону можно пробросив <i>(Сопротивление магии)</i> против броска <i>(Проведения ритуалов)</i> при сотворении барьера.  - Блокирует внутри магию чудовищ, но не физические снаряды.  - Металл должен соответствовать уязвимости чудовища  - Работает пока не рассеян', '', '18', '10', 'I027 (5), I089 (2), I275 (4), I042 (5), I040 (1)', 'magic.form.zone_circle', '0-10', '12', '', '', ''),
  ('MS114', 'core', 'level.journeyman', 'Магический барьер', 'Magic Barrier', 'Создает материальный барьер из света. - Барьер имеет 50ПЗ. - Барьер непроницаем для материальных объектов, но не бестелесных сущностей. - Возможно телепортироваться внутрь и наружу. - Можно остановить обмен воздухом, тогда его хватит на 20-[количество целей внутри] ходов. - Можно восполнять ПЗ барьера по 5ПЗ за 1 <b>ВЫН</b>.', '', '18', '10', 'I027 (5), I089 (2), I275 (4)', 'magic.form.zone_circle', '10', '10', '2', '', ''),
  ('MS115', 'core', 'level.journeyman', 'Онейромантия', 'Oneiromancy', 'Позволяет увидеть во сне истину.   * <b>Сл:15</b> - прошлые события   * <b>Сл:18</b> - текущие события - Маг в месте слежки может заметить её, пробросив <i>(Магические познания)</i> против вашего <i>(Проведения ритуалов)</i> - Можно поделиться сном с другими в количестве <i>(Проведения ритуалов)</i>, но для этого они должны ответить на несколько личных вопросов. - Сон длится до конца ритуала.', '', '15-18', '10', 'I265 (1)', 'magic.form.self', '', '8', '', '1d10', 'time.unit.round'),
  ('MS116', 'core', 'level.master', 'Артефактная компрессия', 'Artifact Compression', 'Превращает цель в нефритовую фигурку в 10 раз меньше оригинала на дистанции 10м. - Цель получает 6d6 урона в корпус при провале <i>(Стойкости)</i> со <b>Сл:15</b> - Цель не стареет, но имеет 20% ПЗ. - Можно отломить голову или конечность броском <i>(Силы)</i> со <b>Сл:14</b> или нанеся 5 урона. Эффекты соответствуют крит.ране после декомпрессии. - Расколдованная цель <b><i>дезориенти-рована</i></b>.', '', '18', '10', 'T039 (1), I027 (5), I089 (2), I041 (4)', 'magic.form.direct', '', '16', '', '', ''),
  ('MS117', 'core', 'level.master', 'Сотворение голема', 'Golem Crafting', 'Создает простого голема, исполняющие приказы создателя. - Не может использовать мелкую моторику. - Не может исполнять точные детализированные приказы. - Не думает, исполняет приказ до отмены или своей смерти.', '', '20', '10', 'I044 (10), I275 (2), T039 (1), I006 (10), I089 (5), I027 (2)', 'magic.form.direct', '', '15', '', '', ''),
  ('MS118', 'core', 'level.master', 'Интерактивная иллюзия', 'Interactive Illusion', 'Создает управляемую иллюзию рядом с магом. - Иллюзия ощущается реальной на вид, ощупь, звук и запах. - Если иллюзия атакует, то цель бросает <i>(Сопротивление магии)</i> или <i>(Стойкость)</i> со <b>Сл:12</b>. При успехе иллюзия раскрыта, при провале цель бросает испытание <i>(Устойчивости)</i>. При повторном провале цель <b><i>дезориентирована</i></b> - Работает пока не рассеяна', '', '18', '10', 'I081 (3), T039 (1), I027 (5), I089 (1), I005 (2)', 'magic.form.zone_circle', '20', '12', '', '', ''),
  ('MS212', 'exp_toc', 'level.novice', 'Создание хрустального черепа', 'Create Crystal Skull', 'Превращает череп кошки, собаки, птицы или змеи в хрустальный. - Его можно активировать, превратив в животное из которого он сделан. - Животное выполняет мысленные приказы, которые слышит пока рядом. - При смерти животного череп деактивируется, но его можно зарядить тем же ритуалом с [2] пятой эссенции.', '', '14', '10', 'I266, I027 (5), I267, I027 (2)', 'magic.form.self', '', '5', '', '', ''),
  ('MS213', 'exp_toc', 'level.novice', 'Наполнить трофей', 'Imbue Trophy', E'Зачаровывает трофей из монстра, которого помог убить пользователь. Эффект при ношении зависит от чудовища: <b>Бес</b>: +2 к броскам <i>(Сотворения заклинаний)</i> и <i>(Сопротивления магии)</i>. \n <b>Брукса</b>: Вы общаетесь телепатией на 20м. \n <b>Вендниго</b>: Иммунитет к болезням.\n <b>Виверна</b>: Эффект к атакам Отравление (25%) \n <b>Гаркаин</b>: +1 к спас.броску от Оглушения. \n <b>Главоглаз</b>: Иммунитет к яду. \n <b>Голем</b>: Иммунитет к кровотечению.\n<b>Грифон</b>: При получении крит.раны бросайте d10 дважды и выберите результат.\n <b>Игоша</b>: Получаете соц.статус Опасение. Если статус уже был, то эффекты удваиваются.\n <b>Катакан</b>: Эффект к атакам Кровотечение (25%)\n <b>Кладбищенская баба</b>: +2 к броскам <i>(Проведения Ритуалов)</i> и <i>(Наложению Порчи)</i>.\n <b>Куролиск</b>: Эффект к атакам Ослепление (10%)\n <b>Леший</b>: Можете общаться с животными и подчинить их после словесного боя. Но вредить себе зверь не будет.\n <b>Мантикора</b>: +2 к Сл сопротивления и снятию ваших ядов.\n <b>Медведь</b>: -2 штраф людям к попыткам вырваться из вашего захвата.\n <b>Моровая дева</b>: Вас окружают мухи. Штраф к броскам врагов -2 рядом и болезнь (10%). Вам штраф -2 к <i>(Соблазнению)</i>, <i>(Убеждению)</i>, <i>(Внешнему виду)</i>\n <b>Оборотень</b>: +2 к броскам <i>(Силы)</i> и <i>(Выживания)</i>\n <b>Ослизг</b>: +2 к <i>(Сотворению заклинаний)</i> для огенной магии.\n <b>Пантера</b>: Скорость лазания х2.\n <b>Полуденица</b>: Иммунитет к страху.\n <b>Скальный тролль</b>: +1 к множителю дистанции для метательного оружия.\n <b>Суккуб</b>: +1 к соц.статусу.\n <b>Тролль</b>: Пьянеете в 2 раза дольше и без похмелья.\n <b>Туманник</b>: +2 к броскам <i>(Скрытности)</i> и <i>(Ловкости рук)</i>.\n <b>Утковол</b>: Трупоед всегда выберет другую цель, если она есть.\n <b>Феникс</b>: Минус 50% к шансу загореться <i>(не меньше нуля)</i>.\n <b>Хим</b>: Минимум 4ед урона всегда проходят через броню врагов.\n <b>Химера</b>: Раз в день выбираете сопротивление 1 виду урона от оружия.\n <b>Циклоп</b>: Вместо <b><i>дезориентации</i></b> от магии вы атакуете ближайшую живую цель в следующем раунде.\n <b>Шарлей</b>: +2 к <i>(Сотворению заклинаний)</i> для земляной магии.\n <b>Элементаль Земляной</b>: Разрушающий урон по ПБ или Н удваивается.\n <b>Элементаль Ледяной</b>: Эффект к атакам Заморозка (25%)\n <b>Элементаль Огненный</b>: Эффект к атакам Горение (25%)', '', '12', '10', 'I268, I027 (1), I089 (1), I030 (10), I028 (1), I025 (2)', '', '', '3', '', '', ''),
  ('MS214', 'exp_toc', 'level.novice', 'Тиромантия', 'Tyromancy', E'Позволяет узнать повлекут ли действия положительный или отрицательный результат. Сложность зависит от сыра (1d6 мастер кидает тайно):\n   * Стандартный сыр: <b>Сл:</b>[13 + 1d6]\n   * Высококачественный сыр: <b>Сл:</b>[13 - 1d6]\n Если пробросить <i>(Проведение ритуалов)</i> с этой <b>Сл</b>, то ГМ должен правдиво ответить. - При неудаче ГМ даст случайный ответ. - Если результат разносторонний, то ГМ даст результат, который наступит раньше.', '', '7-19', '5', 'I269 (2)', '', '', '2', '', '', ''),
  ('MS215', 'exp_toc', 'level.novice', 'Спорная подвеска', 'Wagerer''s Pendant', E'Создает подвеску, которая отключает любые эффекты порч уже имеющихся и новых.\n - При снятии подвески эффекты возвращаются.\n - Если к концу действия ритуала на пользователе еще будут активные порчи, подвеска расколется и пользователь, как и цели в пределах 2м получат ряд новых порч по решению ГМа.', '', '14', '10', 'I005 (2), I014 (1), I100 (2), I020 (2), I275 (2), I026 (5), I001 (2)', '', '', '6', '', '7', 'time.unit.day'),
  ('MS216', 'exp_toc', 'level.journeyman', 'Живой доспех', 'Animate Armor', E'"Оживляет" набор доспехов, исполняющие приказы создателя.\n - Выполняет простые приказы (как пёс).\n - Не думает, исполняет приказ в точности до отмены или своей смерти.\n - Если разрушить ПБ корпуса, то следующий удар в корпус "убьёт" доспех, уничтожив сердце голема.\n - Двимеритовая бомба дает штраф -2 ко всем броскам и не дает пользоваться "Перегрузкой".', '', '18', '10', 'I280 (1), I281 (1), I282 (1), I027 (3), I089 (3), I120 (1)', 'magic.form.direct', '', '14', '', '', ''),
  ('MS217', 'exp_toc', 'level.journeyman', 'Маяк неестественного', 'Beacon of the Unnatural', E'Создает мрачный тотем, который привлекает всех монстров в радиусе 1.6км для строительства гнезда в этом месте.\n - Каждый год радиус влияния растет на 1.6км. \n - Рост тотема 2м, прочность 20ПЗ.', '', '18', '15', 'I270 (1), I006 (4), T057 (1), I014 (5), I027 (1)', 'magic.form.direct', '', '14', '', '', ''),
  ('MS218', 'exp_toc', 'level.journeyman', 'Туман прошлого', 'Fog of the Past', E'Создает стеклянную конструкцию, окруженную свечами, которая показывает наиболее эмоцио-нальное событие из прошлого в месте создания.\n - Событие в ведении может длиться до 5 минут.\n - Видение повторяется раз за разом до конца ритуала.', '', '18', '10', 'I005 (5), I069 (1), I274 (5), I074 (2)', 'magic.form.direct', '', '10', '', '20', 'м'),
  ('MS219', 'exp_toc', 'level.journeyman', 'Волшебная гостевая книга', 'Magical Guestbook', E'Создает невидимую завесу на арке или дверной раме.\n - Записывает лица любых прошедших, которые вы можете получить телепатически по запросу.\n - Телепатически само предупреждает вас, если прошел кто-то конкретный, кого вы указали при создании завесы.\n - Для телепатической связи вы должны быть в пределах 100м.\n - После конца ритуала, все записи хранятся в глиняной фигурке, которую может считать любой, способный к магии, пока фигурка цела.', '', '16', '10', 'I275 (2), I002 (2), I041 (1), I027 (1)', 'magic.form.direct', '', '8', '', '1', 'time.unit.day'),
  ('MS220', 'exp_toc', 'level.master', 'Создание места силы', 'Create Place of Power', 'Создаёт Место Силы на пересечении двух Лей-линий с одинаковым элементом. - При крит.провале маг:   * Получает стихийный смешанный эффект   * Фокусирующие предметы при себе взрывается на 1d10 в радиусе 2м.   * Используемые камни взрываются, нанося 7d6 урона в радиусе 6м.', '', '20', '20', 'T110, I044 (40)', 'magic.form.direct', '', '18', '', '', ''),
  ('MS221', 'exp_toc', 'level.master', 'Зачарованный амулет', 'Enchant Amulet', E'Создает амулет, позволяющий использовать 1-4 спеллов и инвокаций, не знакомых пользователю  - При создании нужно знать каждую вложенную магию и потратить цену <b>ВЫН</b> каждой. Для активных нужно потратить по 4*<b>ВЫН</b> цены поддержки. Причем, любой предмет фокусировки бесполезен при создании.\n- При создании, если вложено больше 1 магии, нужно выбрать один негативный эффект:   * Штраф -5 к максимальным ПЗ.   * Штраф -10 к максимальной <b>ВЫН</b>.   * Штраф -1 к <b>ИНТ</b>, <b>РЕА</b>, <b>Воле</b>. Всегда болит голова. Эти штрафы сохраняются еще 24ч после снятия амулета. - Амулет дает фокусировку (2). Нельзя использовать любой другой предмет фокусировки при использовании магии амулета. - Перегрузка невозможна, нужно иметь достаточно <b>Энергии</b> для использования магии из амулета. - Жрецы и друиды могут использовать спеллы магов, но не наоборот.', '', '18', '15', 'T036 (1), T110 (1), T039 (1), I027 (2)', 'magic.form.self', '', '', '', '', ''),
  ('MS236', 'exp_toc', 'level.master', 'Голубой сон Ханмарвина (Некромантия)', 'Hanmarvyn''s Blue Dream (Necromancy)', 'Позволяет одному человеку в пределах 4м стать свидетелем последних 10 минут жизни трупа. Цель должна пройти проверку <i>(Выносливости)</i> со <b>Сл:24</b> или окажется присмерти. На время ритуала цель теряет сознание и переживает воспоминания умершего как свои собственные, чувствуя его эмоции. Под воздействием галлюциногена длительность увеличивается до 20 минут.', '', '18', '10', 'I273 (1), I027 (10), I069 (2), I074 (3), I075 (2), I078 (1), I113 (2), I098 (1), I099 (3), I122 (2)', 'magic.form.direct', '', '16', '', '10', 'time.unit.minute'),
  ('MS237', 'exp_toc', 'level.journeyman', 'Оживить труп (Некромантия)', 'Reanimate Corpse (Necromancy)', 'Насильственно возвращает душу в мёртвое тело. Труп ведёт себя как живой, но испытывает мучительную боль, не может двигаться и получает штраф -3 к сопротивлению принуждению. Для ответов на вопросы нужны неповреждённые голосовой аппарат (лёгкие, голосовые связки, рот, язык) и мозг минимум на 50%. Пытка в словесной дуэли не даёт бонусов, так как труп уже в невообразимой боли.', '', '18', '10', 'I279 (1), I275 (4), I027 (5), I274 (5), I059 (2), I122 (5), I074 (2)', 'magic.form.direct', '', '10', '3', '', ''),
  ('MS238', 'exp_toc', 'level.master', 'Синтез Кадфана (Некромантия)', 'Cadfan''s Synthesis (Necromancy)', 'Частично оживляет множество трупов, связывая их в одно амальгамированное существо - Амальгаму Трупов. Существо выполняет ваши команды, двигается и действует как голем, но не способно к высшему мышлению.', '', '22', '15', 'I278 (10), I275 (5), I030 (10), I069 (1), I076 (2), I081 (3), I027 (10), I274 (10), I059 (5), I122 (5), I074 (5)', 'magic.form.direct', '', '16', '', 'постоянное', ''),
  ('MS239', 'exp_toc', 'level.journeyman', 'Создать маяк душ (Некромантия)', 'Create Soul Beacon (Necromancy)', 'Создаёт тотем высотой 1м с черепом (10 ПЗ), усиливающий способности некроманта в пределах 6м. Только один маяк действует одновременно. Бонусы зависят от черепа: <b>Человек/Эльф:</b> -3 к Сл и стоимости ВЫН ритуалов некромантии, при провале/перегрузке бросок 1d10-2 вместо 1d10 на таблицу Беспокойных Духов. <b>Зверь/Чудовище:</b> +2 к Атаке и Защите существ, созданных некромантией, а также Отслеживание по запаху и Ночное зрение для человека в Голубом Сне Ханмарвина.', '', '16', '10', 'I277 (1), I001 (10), I027 (2), I089 (3), I012 (5), I044 (2), I020 (3), I122 (2)', 'magic.form.direct', '', '10', '', '1', 'time.unit.day'),
  ('MS240', 'exp_toc', 'level.novice', 'Неконтролируемый призыв (Гоэтия)', 'Uncontrolled Summoning (Goetia)', E'<b>Эффект:</b> Этот ритуал призыва невероятно опасен. Призванный демон не связан каким-либо кодексом поведения и не контролируется игроками. Он может напасть на них или отказаться от любой сделки без последствий. В призыве может появиться демон любого вида, в том числе старший демон. Этот ритуал является причиной большинства смертей, связанных с гоэтией.\n \n<b>Процесс:</b> Назначьте главного призывателя, который возглавит пение. Пусть они встанут вперед, а остальная часть группы будет позади них полукругом. Начертите мелом круг на земле, чтобы направить демона к вашему ритуалу. Выберите три случайных слога из своего сердца (Генератор истинного имени демона на стр. 143) и повторяйте их, визуализируя желание вашего сердца, по одному слогу за раз, не переставая, пока демон не появится.', '', '10', '10', 'I275 (1)', 'magic.form.direct', '', '0', '', 'мгновенно', ''),
  ('MS241', 'exp_toc', 'level.novice', 'Контролируемый призыв (Гоэтия)', 'Controlled Summoning (Goetia)', E'<b>Эффект:</b> Позволяет игрокам выбирать вид демона и возможность вызвать более могущественного демона. Без защиты (например, мантия из козьей шкуры) ритуал невероятно опасен и часто смертелен.\n \n<b>Процесс:</b> В миску с маслом добавьте дымную пыль и эссенцию призрака, смешав в густую пасту. Начертите этой пастой круг и поместите по краям пять незажженных свечей. Добавьте в круг предмет, привлекающий демона: для диавола - свежесрезанная плоть (больше плоти может призвать старшего диавола), для мари лвид - свежая еда и эль (пир на 100 крон для старшего), для касглидда - письмо с обещанием взаимной выгоды (большая выгода для старшего). Повторите имя демона пять раз. Если знаете настоящее имя, оно заставит демона призвать. Иначе выберите три слога из своего сердца (Генератор на стр. 143), которые звучат как настоящее имя. После каждого повторения должна загореться одна свеча. Когда все пять зажгутся, появится демон.', '', '16', '15', 'I274 (5), I074 (2), I089 (3), I008 (2)', 'magic.form.direct', '', '0', '', 'мгновенно', ''),
  ('MS242', 'exp_toc', 'level.novice', 'Ритуал Имени (Гоэтия)', 'Ritual of Naming (Goetia)', E'<b>Эффект:</b> Позволяет узнать истинное имя конкретного демона. После извлечения из огня имя можно безопасно записать. При провале проверки Проведения ритуалов уголь сгорает, а настоящее имя демона выжигается на вашей коже, отмечая вас люцифугом. Демон всегда будет знать ваше местоположение, пока вы носите эту метку, и может явиться вам на своих условиях.\n \n<b>Процесс:</b> Разожгите костер из костей зверя, угля и сухих дров (огонь должен гореть яркооранжевым). Нанесите смесь угля, пятой эссенции и собственной крови на открытую кожу. Удерживая ветку лещины, погрузите обработанную кожу в огонь. Огонь безвреден для вас и должен гореть добела некоторое время. Пока горит огонь, думайте о демоне, имя которого хотите узнать. Когда огонь погаснет, истинное имя появится в корке угля на вашей коже.', '', '18-24', '20', 'I002 (10), I006 (20), I014 (10), I089 (3), I276 (1)', 'magic.form.direct', '', '0', '', 'мгновенно', '')
),
ritual_effects_en (ms_id, text_en) AS (
  VALUES
    ('MS104', E'Cleanses the target of poisons and diseases.\n- Removes (choose one, with different DCs):\n* DC 12 — alcohol and drugs\n* DC 15 — poison and oils\n* DC 18 — diseases\n- Cannot cure the Catriona Plague.'),
    ('MS105', E'Allows you to see events from the last 2 days on the surface of water.\n* DC 15 — past events\n* DC 18 — current events\n- A mage at the location of the current events may notice they are being watched by rolling (Magical Knowledge) vs your (Ritual Crafting).'),
    ('MS106', E'Records a message into a medium as a full-height hologram of the mage.\n- Up to 5 minutes long.\n- Can be played back 1–3 times (at the mage''s choice).\n- If recorded into a perfect gemstone, the recording looks lifelike.'),
    ('MS107', E'Allows you to see current events in a flame.\n- A mage at the watched location may notice the scrying by rolling (Magical Knowledge) vs your (Ritual Crafting).'),
    ('MS108', E'Creates a healing circle.\n- Affects 1 target.\n- Heals 3 HP per turn for a target inside the circle.\n- If the target leaves the circle, it disappears.'),
    ('MS109', E'Creates a circle filled with magic.\n- The first target to enter who is capable of magic gains a bonus to Energy equal to (Ritual Crafting)/2.\n- Affects only 1 target.\n- Alternative: drain the circle to gain (1d6)/2 Fifth Essence.'),
    ('MS110', E'Creates a vortex inside a sealed clay jar.\n- Limited shelf life.\n- When the jar is broken, a random spell triggers (1d10/2):\n* Talfryn''s Prison\n* Zephyr\n* Tanio Ilchar\n* Dormyn''s Fog\n* Static Storm'),
    ('MS111', E'Summons the spirit of the dead with its mind and memories, including the cause of death.\n- The spirit can be dismissed at its will or destroyed.\n- You can speak with it at the burial site.\n- Also summons all relatives within 20 m.\n- The spirit may possess a target. Defense: roll (Resist Magic) vs (Spell Casting) immediately and every 1d6 turns at the same DC. On a failure, the spirit controls the body.\nThe target gets +5 to (Resist Magic) if the behavior is unacceptable and +10 if it is life-threatening.'),
    ('MS112', E'Allows communication with another owner of the same device.\n- Both participants must perform the ritual simultaneously.'),
    ('MS113', E'Creates a one-way (both directions) impenetrable circle for monsters.\n- To pass through in one direction, a creature rolls (Resist Magic) vs the (Ritual Crafting) roll used to create the barrier.\n- Blocks monster magic inside, but not physical projectiles.\n- The metal used must match the monster''s vulnerability.\n- Lasts until dispelled.'),
    ('MS114', E'Creates a solid barrier of light.\n- The barrier has 50 HP.\n- Impenetrable to material objects, but not to incorporeal entities.\n- Teleportation in and out is possible.\n- You may stop air exchange; then the air lasts 20 - [number of targets inside] turns.\n- You may restore the barrier by 5 HP for each 1 STA.'),
    ('MS115', E'Allows you to see the truth in a dream.\n* DC 15 — past events\n* DC 18 — current events\n- A mage at the watched location may notice the scrying by rolling (Magical Knowledge) vs your (Ritual Crafting).\n- You may share the dream with up to (Ritual Crafting) other people, but they must answer several personal questions.\n- The dream lasts until the end of the ritual.'),
    ('MS116', E'Compresses the target into a jade figurine 10× smaller than the original (range 10 m).\n- If the target fails an Endurance check at DC 15, they take 6d6 damage to the torso.\n- The target does not age, but has only 20% HP.\n- You may snap off a head or limb with a Strength check at DC 14, or by dealing 5 damage. The effects correspond to critical wounds after decompression.\n- The released target is Dazed.'),
    ('MS117', E'Creates a simple golem that obeys the creator''s commands.\n- Cannot use fine motor skills.\n- Cannot follow precise, highly detailed orders.\n- Does not think; it follows orders until canceled or until it is destroyed.'),
    ('MS118', E'Creates a controllable illusion next to the mage.\n- The illusion feels real: sight, touch, sound, and smell.\n- If the illusion attacks, the target rolls (Resist Magic) or (Endurance) at DC 12.\nOn success the illusion is revealed; on failure the target makes a Stability test. On a second failure the target is Dazed.\n- Lasts until dispelled.'),
    ('MS212', E'Turns the skull of a cat, dog, bird, or snake into a crystal skull.\n- You can activate it to turn it into the animal it was made from.\n- The animal follows mental commands it can hear while nearby.\n- When the animal dies, the skull deactivates, but can be recharged with the same ritual using [2] Fifth Essence.'),
    ('MS213', E'Enchants a trophy from a monster that the user helped kill. The worn effect depends on the monster:\n- Demon: +2 to (Spell Casting) and (Resist Magic) rolls.\n- Bruxa: you can communicate telepathically within 20 m.\n- Wendigo: immunity to diseases.\n- Wyvern: attacks gain Poison (25%).\n- Garkain: +1 to saves vs Stun.\n- Fiend: immunity to poison.\n- Golem: immunity to bleeding.\n- Griffin: when you take a critical wound, roll d10 twice and take one result.\n- Igosha: you gain the social standing "Feared"; if you already had it, the effects double.\n- Katakan: attacks gain Bleeding (25%).\n- Grave Hag: +2 to (Ritual Crafting) and (Hex Weaving).\n- Cockatrice: attacks gain Blinded (10%).\n- Leshen: you can speak with animals and can dominate them after a verbal duel; animals will not harm themselves.\n- Manticore: +2 to the DC to resist and remove your poisons.\n- Bear: enemies suffer -2 when attempting to break out of your grapple.\n- Plague Maiden: flies swarm around you. Enemies nearby take -2 to rolls and may contract Disease (10%). You suffer -2 to (Seduction), (Persuasion), and Appearance.\n- Werewolf: +2 to (Strength) and (Wilderness Survival) rolls.\n- Ozzrel: +2 to (Spell Casting) for fire magic.\n- Panther: climbing speed ×2.\n- Noonwraith: immunity to fear.\n- Rock Troll: +1 to the range multiplier for thrown weapons.\n- Succubus: +1 social standing.\n- Troll: you get drunk twice as slowly and without a hangover.\n- Foglet: +2 to (Stealth) and (Sleight of Hand).\n- Graveir: a corpse-eater will always choose another target if one exists.\n- Phoenix: -50% to the chance to ignite (minimum 0).\n- Hym: a minimum of 4 damage always bypasses enemy armor.\n- Chimera: once per day you choose resistance to one weapon damage type.\n- Cyclops: instead of being Dazed by magic, you attack the nearest living target next round.\n- Shaelmaar: +2 to (Spell Casting) for earth magic.\n- Earth Elemental: destructive damage to SP or HP is doubled.\n- Ice Elemental: attacks gain Freezing (25%).\n- Fire Elemental: attacks gain Burning (25%).'),
    ('MS214', E'Lets you learn whether an action will have a positive or negative outcome. The DC depends on the cheese (1d6, rolled secretly by the GM):\n* Standard cheese: DC [13 + 1d6]\n* High-quality cheese: DC [13 - 1d6]\nIf you succeed on (Ritual Crafting) at that DC, the GM must answer truthfully.\n- On a failure, the GM gives a random answer.\n- If the outcome is mixed, the GM gives the outcome that will happen sooner.'),
    ('MS215', E'Creates a pendant that suppresses all active and newly applied hex effects.\n- When the pendant is removed, the effects return.\n- If, by the end of the ritual''s duration, the wearer still has active hexes, the pendant cracks and the wearer (and targets within 2 m) gain several new hexes at the GM''s discretion.'),
    ('MS216', E'"Animates" a suit of armor that obeys the creator''s commands.\n- Follows simple commands (like a dog).\n- Does not think; follows orders until canceled or destroyed.\n- If the torso SP is destroyed, the next hit to the torso "kills" the armor by destroying the golem''s heart.\n- A dimeritium bomb gives -2 to all rolls and prevents using "Overcharge".'),
    ('MS217', E'Creates a grim totem that attracts all monsters within 1.6 km to build nests in the area.\n- Each year, the radius increases by 1.6 km.\n- The totem is 2 m tall and has 20 HP.'),
    ('MS218', E'Creates a glass construction surrounded by candles that shows the most emotional event from the past at the place of casting.\n- The scene may last up to 5 minutes.\n- The vision repeats over and over until the ritual ends.'),
    ('MS219', E'Creates an invisible veil on an arch or door frame.\n- Records the faces of anyone who passes through; you can receive them telepathically on request.\n- Warns you telepathically if a specific person (named during creation) passes through.\n- You must be within 100 m for the telepathic link.\n- After the ritual ends, all records are stored in a clay figurine; any magic user can read it while the figurine remains intact.'),
    ('MS220', E'Creates a Place of Power at the intersection of two Ley Lines of the same element.\nOn a critical failure the mage:\n* gains a random mixed elemental effect\n* any focusing items they carry explode for 1d10 damage in a 2 m radius\n* the stones used explode, dealing 7d6 damage in a 6 m radius'),
    ('MS221', E'Creates an amulet that allows the user to cast 1–4 spells and invocations the user does not know.\n- To create it, you must know each embedded magic and pay the full STA cost of each. For active effects, you must also pay 4*STA of each sustain cost. Any focusing item is useless during creation.\n- If more than 1 magic is embedded, choose one negative effect:\n* -5 to maximum HP\n* -10 to maximum STA\n* -1 to INT, REF, and WILL; constant headache\nThese penalties also remain for 24 hours after removing the amulet.\n- The amulet provides Focusing (2).\n- You cannot use any other focusing item when casting from the amulet.\n- Overcharge is impossible; you must have enough Energy to use the magic from the amulet.\n- Priests and druids can use mage spells, but not vice versa.'),
    ('MS236', 'Allows one person within 4m to witness the last 10 minutes of a corpse''s life. The target must make a DC:24 Endurance check or fall into a dying state. For the ritual''s duration, the target falls unconscious and experiences the corpse''s memories as their own, feeling that person''s emotions. Under the influence of a Hallucinogen, duration increases to 20 minutes.'),
    ('MS237', 'Forcibly returns a soul to its dead body. The corpse acts as though alive but is in excruciating pain, cannot move, and suffers -3 to Resist Coercion checks. To answer questions, it needs intact vocal apparatus (lungs, vocal cords, mouth, tongue) and at least 50% of its brain. Torture in Verbal Combat gives no bonuses as the corpse is already in unimaginable pain.'),
    ('MS238', 'Partially animates many corpses, binding them into a single amalgamated creature - a Corpse Amalgam. The creature follows your commands, moves and acts like a golem, but is no longer capable of higher thought.'),
    ('MS239', 'Creates a 1m tall totem with a skull (10 HP) that enhances a Necromancer''s abilities within 6m. Only one beacon works at a time. Bonuses depend on the skull: <b>Human/Elderfolk:</b> -3 to DC and STA cost of necromancy rituals, roll 1d10-2 instead of 1d10 on Restless Spirits table on fumble/overdraw. <b>Beast/Monster:</b> +2 to Attack and Defense for creatures created by necromancy, plus Scent Tracking and Night Vision for a person in Hanmarvyn''s Blue Dream.'),
    ('MS240', E'<b>Effect:</b> This summoning ritual is incredibly dangerous. The summoned demon is not bound by any code of conduct and is not controlled by the players. It may attack them or go back on any deal made with them, with no consequences. A demon of any species, including greater demons, may appear. This ritual is responsible for most deaths associated with goetia.\n\n<b>Process:</b> Designate a chief summoner to lead the chant. Have the chief summoner stand forward, with the rest of your group behind them in a semicircle. Scribe a chalk circle into the ground before them to guide the demon. Pick three syllables from your heart (the Demon True Name Generator on Pg.143) at random. Chant these syllables one at a time, without ceasing, while visualizing your heart''s desire, until a demon appears.'),
    ('MS241', E'<b>Effect:</b> This ritual allows players to choose the demon species and whether to summon a more powerful version. It is incredibly dangerous, and often deadly, without specific protections (e.g., a Goatskin Mantle) or protections tailored to the summoned demon.\n\n<b>Process:</b> Mix infused dust and essence of wraith into a thick paste in a bowl of oil. Spread this paste into a circle. Place five unlit candles equally spread outside the circle. Add an item beloved by the specific demon species to be summoned into the circle. For Bes: participants offer freshly cut flesh. More flesh can summon a greater bes. For Mari Lywd: fill the circle with fresh food and ale. To attract a greater mari lywd, prepare a feast (100 crowns). For Casglydd: place a letter of introduction in the circle, promising mutual benefit. To attract a greater casglydd, over-promise in the letter. Chant the demon''s name five times. If the true name is known, it forces the summoning. Otherwise, pick three syllables "from your heart" (referencing a "Demon True Name Generator on Pg.143"), which sounds like a true name and attracts a demon. After each repetition of the chant, one candle lights itself. When all five are lit, the demon appears.'),
    ('MS242', E'<b>Effect:</b> This ritual allows the player to learn the true name of a specific demon. Once removed from the fire, the name can be safely recorded to save for later. If you fail the Ritual Crafting check: Upon removing your skin from the fire, you find the coal had burned off during the ritual and the true name of a demon has been burned into your skin, marking you with a Lucifuge. You may have discovered the true name of a demon, but it will forever know where you are while you bear this mark, and may appear to you on its own terms, as it wishes.\n\n<b>Process:</b> Create a bonfire of beast bones, coal, and dry wood. The fire must be hot enough to burn bright orange. Rub a mixture of coal, fifth essence, and your own blood onto your exposed skin to protect it. While holding a branch of hazel, submerge the treated skin into the fire. The fire will be harmless to you, and should burn white hot for a while before going out. While the fire burns hot, think of a demon whose true name you wish to discover. When the fire expires, remove your skin from the fire. The true name of the demon should appear in the crust of the coal coating your skin.')
),
ins_i18n AS (
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT * FROM (
SELECT ck_id('witcher_cc.magic.ritual.name.'||rd.ms_id),
'magic',
           'ritual_names',
           'ru',
           rd.name_ru
      FROM raw_data rd
     WHERE nullif(rd.name_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.magic.ritual.name.'||rd.ms_id),
           'magic',
           'ritual_names',
           'en',
           rd.name_en
      FROM raw_data rd
     WHERE nullif(rd.name_en,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.magic.ritual.effect.'||rd.ms_id),
           'magic',
           'ritual_effects',
           'ru',
           regexp_replace(replace(replace(rd.effect_ru, chr(11), E'\n'), chr(13), ''), '<[^>]+>', '', 'g')
      FROM raw_data rd
     WHERE nullif(rd.effect_ru,'') IS NOT NULL
    UNION ALL
    -- effects EN (from manual translations)
    SELECT ck_id('witcher_cc.magic.ritual.effect.'||ree.ms_id),
           'magic',
           'ritual_effects',
           'en',
           ree.text_en
      FROM ritual_effects_en ree
    UNION ALL
    SELECT ck_id('witcher_cc.magic.ritual.how_to_remove.'||rd.ms_id),
           'magic',
           'ritual_how_to_remove',
           'ru',
           regexp_replace(replace(replace(rd.how_to_remove_ru, chr(11), E'\n'), chr(13), ''), '<[^>]+>', '', 'g')
      FROM raw_data rd
     WHERE nullif(rd.how_to_remove_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.magic.ritual.how_to_remove.'||rd.ms_id),
           'magic',
           'ritual_how_to_remove',
           'en',
           regexp_replace(replace(replace(rd.how_to_remove_ru, chr(11), E'\n'), chr(13), ''), '<[^>]+>', '', 'g')
      FROM raw_data rd
     WHERE nullif(rd.how_to_remove_ru,'') IS NOT NULL
  ) foo
  ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
)
INSERT INTO wcc_magic_rituals (
  ms_id, dlc_dlc_id,
  level_id, form_id,
  effect_time_unit_id,
  preparing_time_unit_id,
  name_id, effect_id, how_to_remove_id,
  dc,
  preparing_time_value,
  ingredients,
  zone_size,
  stamina_cast, stamina_keeping,
  effect_time_value
)
SELECT rd.ms_id
     , rd.dlc_dlc_id
     , CASE WHEN nullif(rd.level_key,'') IS NOT NULL THEN ck_id(rd.level_key) ELSE NULL END AS level_id
     , CASE WHEN nullif(rd.form_key,'') IS NOT NULL THEN ck_id(rd.form_key) ELSE NULL END AS form_id
     , CASE
         WHEN rd.effect_time_unit_key LIKE 'time.unit.%' THEN ck_id(rd.effect_time_unit_key)
         ELSE NULL
       END AS effect_time_unit_id
     , ck_id('time.unit.round') AS preparing_time_unit_id
     , ck_id('witcher_cc.magic.ritual.name.'||rd.ms_id) AS name_id
     , ck_id('witcher_cc.magic.ritual.effect.'||rd.ms_id) AS effect_id
     , CASE WHEN nullif(rd.how_to_remove_ru,'') IS NOT NULL THEN ck_id('witcher_cc.magic.ritual.how_to_remove.'||rd.ms_id) ELSE NULL END AS how_to_remove_id
     , nullif(rd.dc,'')
     , NULLIF(rd.preparing_time_value,'')::int
     , CASE
         WHEN rd.ingredients_raw IS NULL OR trim(rd.ingredients_raw) = '' THEN NULL
         ELSE (
           SELECT
             CASE
               WHEN jsonb_agg(comp.obj ORDER BY comp.pos) IS NULL THEN NULL
               ELSE jsonb_agg(comp.obj ORDER BY comp.pos)
             END
           FROM (
             SELECT
               pieces.pos,
               jsonb_build_object(
                 'id',
                 (
                   CASE
                     WHEN pieces.code ~ '^I[0-9]{3}$' THEN ck_id('witcher_cc.items.ingredient.name.'||pieces.code)
                     WHEN pieces.code ~ '^T[0-9]{3}$' THEN ck_id('witcher_cc.items.general_gear.name.'||pieces.code)
                     ELSE NULL
                   END
                 )::text,
                 'qty',
                 pieces.qty
               ) AS obj
             FROM (
               SELECT
                 part.ord * 10 AS pos,
                 CASE
                   WHEN (regexp_match(trim(part.part_raw), '\((\d+)\)\s*$')) IS NOT NULL 
                   THEN (regexp_match(trim(part.part_raw), '\((\d+)\)\s*$'))[1]::int
                   ELSE NULL
                 END AS qty,
                 trim(regexp_replace(trim(part.part_raw), '\s*\([^)]*\)\s*$', '')) AS code
               FROM (
                 SELECT token AS part_raw, ord
                 FROM regexp_split_to_table(rd.ingredients_raw, '\s*,\s*') WITH ORDINALITY AS s(token, ord)
               ) part
             ) pieces
             WHERE pieces.code IS NOT NULL AND pieces.code <> '' AND pieces.code ~ '^[IT][0-9]{3}$'
           ) comp
           WHERE (comp.obj->>'id') IS NOT NULL
         )
       END AS ingredients
     , nullif(rd.zone_size,'')
     , nullif(rd.stamina_cast,'')
     , nullif(rd.stamina_keeping,'')
     , CASE
         WHEN nullif(rd.effect_time_value,'') IS NULL THEN NULL
         WHEN rd.effect_time_unit_key LIKE 'time.unit.%' THEN nullif(rd.effect_time_value,'')
         WHEN nullif(rd.effect_time_unit_key,'') IS NOT NULL THEN (nullif(rd.effect_time_value,'') || ' ' || rd.effect_time_unit_key)
         ELSE nullif(rd.effect_time_value,'')
       END AS effect_time_value
  FROM raw_data rd
ON CONFLICT (ms_id) DO UPDATE
SET
  dlc_dlc_id = EXCLUDED.dlc_dlc_id,
  level_id = EXCLUDED.level_id,
  form_id = EXCLUDED.form_id,
  effect_time_unit_id = EXCLUDED.effect_time_unit_id,
  preparing_time_unit_id = EXCLUDED.preparing_time_unit_id,
  name_id = EXCLUDED.name_id,
  effect_id = EXCLUDED.effect_id,
  how_to_remove_id = EXCLUDED.how_to_remove_id,
  dc = EXCLUDED.dc,
  preparing_time_value = EXCLUDED.preparing_time_value,
  ingredients = EXCLUDED.ingredients,
  zone_size = EXCLUDED.zone_size,
  stamina_cast = EXCLUDED.stamina_cast,
  stamina_keeping = EXCLUDED.stamina_keeping,
  effect_time_value = EXCLUDED.effect_time_value;
