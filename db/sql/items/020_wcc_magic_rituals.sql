\echo '020_wcc_magic_rituals.sql'
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
  ingredients,
  form_key,
  zone_size,
  stamina_cast, stamina_keeping,
  effect_time_value, effect_time_unit_key
) AS ( VALUES
  ('MS104', 'core', 'level.novice', $$Ритуал очищения$$, $$Cleansing Ritual$$, $$Очищает цель от ядов и болезней. - Избавляет на выбор с разной <b>Сл</b>:   * <b>Сл:12</b> - Алкоголь и нарктоики   * <b>Сл:15</b> - Яд и масла   * <b>Сл:18</b> - Болезни - Не может излечить Бич Катреоны.$$, $$$$, $$12-18$$, $$5$$, $$[{"id":"f83ae1de-fe30-55a1-1380-3a5cfa14c34d","qty":"1"},{"id":"1c5af2d4-aa3e-68fc-2266-4098a9793d5b","qty":"1"},{"id":"816486fb-5bb8-1be3-8e5a-e4114da71e22","qty":"2"},{"id":"e8f91bf7-3048-dc71-c826-0d0c9863c3c9","qty":"2"},{"id":"7859070f-17e4-5d22-6a61-59a051398a10","qty":"1"}]$$::jsonb, 'magic.form.direct', $$$$, $$3$$, $$$$, $$$$, ''),
  ('MS105', 'core', 'level.novice', $$Гидромантия$$, $$Hydromancy$$, $$Позволяет видеть на воде события послдних 2 дней.   * <b>Сл:15</b> - прошлые события   * <b>Сл:18</b> - текущие события - Маг в месте текущих событий может заметить слежку, пробросив <i>(Магические познания)</i> против вашего <i>(Проведения ритуалов)</i>$$, $$$$, $$15-18$$, $$5$$, $$[{"id":"24e92c6f-408a-7d95-5311-5b05c1fae6b9","qty":"1"},{"id":"ce077dac-df9d-6ec7-3c6a-ecbffb270c7c","qty":"1"},{"id":"1014034b-15bc-1af7-9cef-74b36adf2384","qty":"2"},{"id":"1953927a-2193-63c6-8f30-2a79ab70c14d","qty":"2"},{"id":"d999c288-beda-400e-5292-ea2b7e54136b","qty":"2"},{"id":"fa3d7973-3c3f-7183-9565-58105aa093d5","qty":"1"}]$$::jsonb, 'magic.form.self', $$$$, $$5$$, $$2$$, $$$$, ''),
  ('MS106', 'core', 'level.novice', $$Магическое сообщение$$, $$Magical Message$$, $$Записывает в носитель сообщение в виде голограммы мага в полный рост. - Длительность до 5 минут. - Можно воспроизвести 1-3 раза (по желанию мага). - При записи на совершенный самоцвет запись как живая.$$, $$$$, $$12$$, $$5$$, $$[{"id":"1014034b-15bc-1af7-9cef-74b36adf2384","qty":"1"},{"id":"5237ea83-af92-99bd-fa9e-30cc6013131a","qty":"1"},{"id":"d0732ae7-c4ba-c419-6de2-3c93e7026267","qty":"1"},{"id":"ac0903af-a2e3-d03e-0325-7973c185dd36","qty":null},{"id":"4291ed31-6d63-6bb7-adf4-63af0601b590","qty":"1"}]$$::jsonb, 'magic.form.direct', $$$$, $$3$$, $$$$, $$$$, ''),
  ('MS107', 'core', 'level.novice', $$Пиромантия$$, $$Pyromancy$$, $$Позволяет видеть в пламени текущие события. - Маг в месте слежки может заметить её, пробросив <i>(Магические познания)</i> против вашего <i>(Проведения ритуалов)</i>$$, $$$$, $$15$$, $$5$$, $$[{"id":"7e55e976-8983-ad78-45fb-d6413f822421","qty":"1"},{"id":"1014034b-15bc-1af7-9cef-74b36adf2384","qty":"2"},{"id":"4f5fdc10-102f-dc7c-1b8e-bdcd2b7d32cf","qty":"2"},{"id":"ca6d9545-19e5-6b59-02bc-36de56f7fc61","qty":"5"},{"id":"1c5af2d4-aa3e-68fc-2266-4098a9793d5b","qty":"2"},{"id":"32a89107-2b4b-9df2-3977-c74dcf92c69a","qty":"2"}]$$::jsonb, 'magic.form.self', $$$$, $$5$$, $$5$$, $$$$, ''),
  ('MS108', 'core', 'level.novice', $$Ритуал жизни$$, $$Ritual of Life$$, $$Создает круг, исцеляющий круг.  - Действует на 1 цель  - Лечит 3 ПЗ в ход для цели внутри.  - Если цель покидает круг, он исчезает.$$, $$$$, $$15$$, $$5$$, $$[{"id":"816486fb-5bb8-1be3-8e5a-e4114da71e22","qty":"2"},{"id":"4f5fdc10-102f-dc7c-1b8e-bdcd2b7d32cf","qty":"2"},{"id":"32a89107-2b4b-9df2-3977-c74dcf92c69a","qty":"2"},{"id":"d6ec8e24-4144-df24-b895-64030c4b551d","qty":"2"}]$$::jsonb, 'magic.form.zone_circle', $$$$, $$5$$, $$$$, $$10$$, 'time.unit.round'),
  ('MS109', 'core', 'level.novice', $$Магический ритуал$$, $$Ritual of Magic$$, $$Создаёт круг, наполненный магией:  - Первая вошедшая цель, способ-ная к магии, получает к <b>Энергии</b> бонус +<i>(Проведение ритуалов)/2</i>.  - Действует только на 1 цель.  - Альтернатива: истощить круг, получив (1d6)/2 пятой эссенции$$, $$$$, $$15$$, $$5$$, $$[{"id":"816486fb-5bb8-1be3-8e5a-e4114da71e22","qty":"2"},{"id":"d0732ae7-c4ba-c419-6de2-3c93e7026267","qty":"2"},{"id":"313d1550-d961-8dc6-0f7b-79dc213cf428","qty":"2"},{"id":"0b9430ff-a3b5-47c7-80de-7519ef60e9ad","qty":"1"}]$$::jsonb, 'magic.form.zone_circle', $$$$, $$3$$, $$$$, $$5$$, 'time.unit.hour'),
  ('MS110', 'core', 'level.novice', $$Сосуд заклятия$$, $$Spell Jar$$, $$<align="left">Создает в запечатанном гляняном сосуде вихрь. - Срок годности ограничен. - При разбитии срабатывает случай-ное заклинание (1d10/2):   * Тюрьма Тальфрина   * Зефир   * Танио Ильхар   * Туман Дормина   * Статическая буря</align>$$, $$$$, $$15$$, $$5$$, $$[{"id":"9f875b0e-d9e1-cf8c-1bd1-56bd30d496ba","qty":"5"},{"id":"1014034b-15bc-1af7-9cef-74b36adf2384","qty":"1"},{"id":"1a6d0a65-e77f-e110-1933-1bf2f13c572f","qty":"2"},{"id":"816486fb-5bb8-1be3-8e5a-e4114da71e22","qty":"1"},{"id":"32a89107-2b4b-9df2-3977-c74dcf92c69a","qty":"1"},{"id":"a4d7a49d-434f-23f4-d2e5-9c41a7249c3d","qty":"2"},{"id":"0b9430ff-a3b5-47c7-80de-7519ef60e9ad","qty":"1"}]$$::jsonb, 'magic.form.self', $$$$, $$5$$, $$$$, $$1d6$$, 'time.unit.day'),
  ('MS111', 'core', 'level.novice', $$Спиритический сеанс$$, $$Spirit Seance$$, $$Призывает дух умершего с его разумом и памятью, включая причину смерти.
 - Прогнать духа можно по его желанию или уничтожив.
 - Говорить с ним можно в месте захоронения.
 - Призывает и всех родственников ближе 20м.
 - Дух может вселиться в цель. Защита - бросок <i>(Сопротивления магии)</i> против <i>(Сотворения заклинаний)</i> сразу и каждые 1d6 ходов с той же <b>Сл</b>. При провале дух контролирует тело. Бонус +5 к <i>(Сопротивлению магии)</i> если поведение неприемлемо и +10, если опасно для жизни.$$, $$$$, $$12$$, $$5$$, $$[{"id":"98d106ee-ff20-248d-b53e-1070f9ba28a8","qty":"1"},{"id":"d6ec8e24-4144-df24-b895-64030c4b551d","qty":"1"},{"id":"5c6123e2-d555-f2c5-e75e-e4b87dbbe969","qty":"2"},{"id":"46b9acc3-bafb-cc61-b682-2dc69f2273e4","qty":"2"},{"id":"313d1550-d961-8dc6-0f7b-79dc213cf428","qty":"2"}]$$::jsonb, 'magic.form.direct', $$$$, $$5$$, $$$$, $$$$, ''),
  ('MS112', 'core', 'level.novice', $$Телекоммуникация$$, $$Telecommunication$$, $$Позволяет общаться с другим обладателем такого устройства.  - Оба участника должны провести ритуал одновременно.$$, $$$$, $$0$$, $$5$$, $$[{"id":"8f0f6c64-82e2-3114-c60d-08ea16d8402a","qty":"1"}]$$::jsonb, 'magic.form.self', $${inf}$$, $$3$$, $$$$, $$1$$, 'time.unit.hour'),
  ('MS113', 'core', 'level.journeyman', $$Освящение$$, $$Consecrate$$, $$Создает в обе стороны непрони-цаемый круг для чудовищ.  - Пройти в 1 сторону можно пробросив <i>(Сопротивление магии)</i> против броска <i>(Проведения ритуалов)</i> при сотворении барьера.  - Блокирует внутри магию чудовищ, но не физические снаряды.  - Металл должен соответствовать уязвимости чудовища  - Работает пока не рассеян$$, $$$$, $$18$$, $$10$$, $$[{"id":"1014034b-15bc-1af7-9cef-74b36adf2384","qty":"5"},{"id":"0b9430ff-a3b5-47c7-80de-7519ef60e9ad","qty":"2"},{"id":"816486fb-5bb8-1be3-8e5a-e4114da71e22","qty":"4"},{"id":"fcecc5bf-0107-79ff-1576-69ccf67ab813","qty":"5"},{"id":"ac0903af-a2e3-d03e-0325-7973c185dd36","qty":null},{"id":"654cf387-e835-8a8a-a00a-0aeba4713289","qty":"1"}]$$::jsonb, 'magic.form.zone_circle', $$0-10$$, $$12$$, $$$$, $$$$, ''),
  ('MS114', 'core', 'level.journeyman', $$Магический барьер$$, $$Magic Barrier$$, $$Создает материальный барьер из света. - Барьер имеет 50ПЗ. - Барьер непроницаем для материальных объектов, но не бестелесных сущностей. - Возможно телепортироваться внутрь и наружу. - Можно остановить обмен воздухом, тогда его хватит на 20-[количество целей внутри] ходов. - Можно восполнять ПЗ барьера по 5ПЗ за 1 <b>ВЫН</b>.$$, $$$$, $$18$$, $$10$$, $$[{"id":"1014034b-15bc-1af7-9cef-74b36adf2384","qty":"5"},{"id":"0b9430ff-a3b5-47c7-80de-7519ef60e9ad","qty":"2"},{"id":"816486fb-5bb8-1be3-8e5a-e4114da71e22","qty":"4"}]$$::jsonb, 'magic.form.zone_circle', $$10$$, $$10$$, $$2$$, $$$$, ''),
  ('MS115', 'core', 'level.journeyman', $$Онейромантия$$, $$Oneiromancy$$, $$Позволяет увидеть во сне истину.   * <b>Сл:15</b> - прошлые события   * <b>Сл:18</b> - текущие события - Маг в месте слежки может заметить её, пробросив <i>(Магические познания)</i> против вашего <i>(Проведения ритуалов)</i> - Можно поделиться сном с другими в количестве <i>(Проведения ритуалов)</i>, но для этого они должны ответить на несколько личных вопросов. - Сон длится до конца ритуала.$$, $$$$, $$15-18$$, $$10$$, $$[{"id":"9c3a2f0d-d179-db90-d28e-8a38c63ffec5","qty":"1"}]$$::jsonb, 'magic.form.self', $$$$, $$8$$, $$$$, $$1d10$$, 'time.unit.round'),
  ('MS116', 'core', 'level.master', $$Артефактная компрессия$$, $$Artifact Compression$$, $$Превращает цель в нефритовую фигурку в 10 раз меньше оригинала на дистанции 10м. - Цель получает 6d6 урона в корпус при провале <i>(Стойкости)</i> со <b>Сл:15</b> - Цель не стареет, но имеет 20% ПЗ. - Можно отломить голову или конечность броском <i>(Силы)</i> со <b>Сл:14</b> или нанеся 5 урона. Эффекты соответствуют крит.ране после декомпрессии. - Расколдованная цель <b><i>дезориенти-рована</i></b>.$$, $$$$, $$18$$, $$10$$, $$[{"id":"4291ed31-6d63-6bb7-adf4-63af0601b590","qty":"1"},{"id":"1014034b-15bc-1af7-9cef-74b36adf2384","qty":"5"},{"id":"0b9430ff-a3b5-47c7-80de-7519ef60e9ad","qty":"2"},{"id":"9f875b0e-d9e1-cf8c-1bd1-56bd30d496ba","qty":"4"}]$$::jsonb, 'magic.form.direct', $$$$, $$16$$, $$$$, $$$$, ''),
  ('MS117', 'core', 'level.master', $$Сотворение голема$$, $$Golem Crafting$$, $$Создает простого голема, исполняющие приказы создателя. - Не может использовать мелкую моторику. - Не может исполнять точные детализированные приказы. - Не думает, исполняет приказ до отмены или своей смерти.$$, $$$$, $$20$$, $$10$$, $$[{"id":"e37f8b67-a08c-eafd-a3d9-053d6105dfe6","qty":"10"},{"id":"816486fb-5bb8-1be3-8e5a-e4114da71e22","qty":"2"},{"id":"4291ed31-6d63-6bb7-adf4-63af0601b590","qty":"1"},{"id":"9d0b8763-9253-3963-b65f-78693871d6fe","qty":"10"},{"id":"0b9430ff-a3b5-47c7-80de-7519ef60e9ad","qty":"5"},{"id":"1014034b-15bc-1af7-9cef-74b36adf2384","qty":"2"}]$$::jsonb, 'magic.form.direct', $$$$, $$15$$, $$$$, $$$$, ''),
  ('MS118', 'core', 'level.master', $$Интерактивная иллюзия$$, $$Interactive Illusion$$, $$Создает управляемую иллюзию рядом с магом. - Иллюзия ощущается реальной на вид, ощупь, звук и запах. - Если иллюзия атакует, то цель бросает <i>(Сопротивление магии)</i> или <i>(Стойкость)</i> со <b>Сл:12</b>. При успехе иллюзия раскрыта, при провале цель бросает испытание <i>(Устойчивости)</i>. При повторном провале цель <b><i>дезориентирована</i></b> - Работает пока не рассеяна$$, $$$$, $$18$$, $$10$$, $$[{"id":"52e64738-f69d-cc35-24cd-13490d9ff5c7","qty":"3"},{"id":"4291ed31-6d63-6bb7-adf4-63af0601b590","qty":"1"},{"id":"1014034b-15bc-1af7-9cef-74b36adf2384","qty":"5"},{"id":"0b9430ff-a3b5-47c7-80de-7519ef60e9ad","qty":"1"},{"id":"d0732ae7-c4ba-c419-6de2-3c93e7026267","qty":"2"}]$$::jsonb, 'magic.form.zone_circle', $$20$$, $$12$$, $$$$, $$$$, ''),
  ('MS212', 'exp_toc', 'level.novice', $$Создание хрустального черепа$$, $$Create Crystal Skull$$, $$Превращает череп кошки, собаки, птицы или змеи в хрустальный. - Его можно активировать, превратив в животное из которого он сделан. - Животное выполняет мысленные приказы, которые слышит пока рядом. - При смерти животного череп деактивируется, но его можно зарядить тем же ритуалом с [2] пятой эссенции.$$, $$$$, $$14$$, $$10$$, $$[{"id":"9d09d66b-7988-0b7b-a55d-82119bdaf55a","qty":null},{"id":"1014034b-15bc-1af7-9cef-74b36adf2384","qty":"5"},{"id":"ac0903af-a2e3-d03e-0325-7973c185dd36","qty":null},{"id":"414957cf-96dd-b82f-a518-ffe6626ad035","qty":null},{"id":"1014034b-15bc-1af7-9cef-74b36adf2384","qty":"2"}]$$::jsonb, 'magic.form.self', $$$$, $$5$$, $$$$, $$$$, ''),
  ('MS213', 'exp_toc', 'level.novice', $$Наполнить трофей$$, $$Imbue Trophy$$, $$Зачаровывает трофей из монстра, которого помог убить пользователь. Эффект при ношении зависит от чудовища: <b>Бес</b>: +2 к броскам <i>(Сотворения заклинаний)</i> и <i>(Сопротивления магии)</i>. 
 <b>Брукса</b>: Вы общаетесь телепатией на 20м. 
 <b>Вендниго</b>: Иммунитет к болезням.
 <b>Виверна</b>: Эффект к атакам Отравление (25%) 
 <b>Гаркаин</b>: +1 к спас.броску от Оглушения. 
 <b>Главоглаз</b>: Иммунитет к яду. 
 <b>Голем</b>: Иммунитет к кровотечению.
<b>Грифон</b>: При получении крит.раны бросайте d10 дважды и выберите результат.
 <b>Игоша</b>: Получаете соц.статус Опасение. Если статус уже был, то эффекты удваиваются.
 <b>Катакан</b>: Эффект к атакам Кровотечение (25%)
 <b>Кладбищенская баба</b>: +2 к броскам <i>(Проведения Ритуалов)</i> и <i>(Наложению Порчи)</i>.
 <b>Куролиск</b>: Эффект к атакам Ослепление (10%)
 <b>Леший</b>: Можете общаться с животными и подчинить их после словесного боя. Но вредить себе зверь не будет.
 <b>Мантикора</b>: +2 к Сл сопротивления и снятию ваших ядов.
 <b>Медведь</b>: -2 штраф людям к попыткам вырваться из вашего захвата.
 <b>Моровая дева</b>: Вас окружают мухи. Штраф к броскам врагов -2 рядом и болезнь (10%). Вам штраф -2 к <i>(Соблазнению)</i>, <i>(Убеждению)</i>, <i>(Внешнему виду)</i>
 <b>Оборотень</b>: +2 к броскам <i>(Силы)</i> и <i>(Выживания)</i>
 <b>Ослизг</b>: +2 к <i>(Сотворению заклинаний)</i> для огенной магии.
 <b>Пантера</b>: Скорость лазания х2.
 <b>Полуденица</b>: Иммунитет к страху.
 <b>Скальный тролль</b>: +1 к множителю дистанции для метательного оружия.
 <b>Суккуб</b>: +1 к соц.статусу.
 <b>Тролль</b>: Пьянеете в 2 раза дольше и без похмелья.
 <b>Туманник</b>: +2 к броскам <i>(Скрытности)</i> и <i>(Ловкости рук)</i>.
 <b>Утковол</b>: Трупоед всегда выберет другую цель, если она есть.
 <b>Феникс</b>: Минус 50% к шансу загореться <i>(не меньше нуля)</i>.
 <b>Хим</b>: Минимум 4ед урона всегда проходят через броню врагов.
 <b>Химера</b>: Раз в день выбираете сопротивление 1 виду урона от оружия.
 <b>Циклоп</b>: Вместо <b><i>дезориентации</i></b> от магии вы атакуете ближайшую живую цель в следующем раунде.
 <b>Шарлей</b>: +2 к <i>(Сотворению заклинаний)</i> для земляной магии.
 <b>Элементаль Земляной</b>: Разрушающий урон по ПБ или Н удваивается.
 <b>Элементаль Ледяной</b>: Эффект к атакам Заморозка (25%)
 <b>Элементаль Огненный</b>: Эффект к атакам Горение (25%)$$, $$$$, $$12$$, $$10$$, $$[{"id":"043792ba-bbab-1b6f-7f3f-65f6be30db7e","qty":null},{"id":"1014034b-15bc-1af7-9cef-74b36adf2384","qty":"1"},{"id":"0b9430ff-a3b5-47c7-80de-7519ef60e9ad","qty":"1"},{"id":"71c38def-8454-d3a2-eb12-7ce4b8a4452e","qty":"10"},{"id":"64013aae-2345-6f2f-b31e-2509f82edac7","qty":"1"},{"id":"24bea45b-e3ca-9004-bfb6-cdcd7965e918","qty":"2"}]$$::jsonb, '', $$$$, $$3$$, $$$$, $$$$, ''),
  ('MS214', 'exp_toc', 'level.novice', $$Тиромантия$$, $$Tyromancy$$, $$Позволяет узнать повлекут ли действия положительный или отрицательный результат. Сложность зависит от сыра (1d6 мастер кидает тайно):
   * Стандартный сыр: <b>Сл:</b>[13 + 1d6]
   * Высококачественный сыр: <b>Сл:</b>[13 - 1d6]
 Если пробросить <i>(Проведение ритуалов)</i> с этой <b>Сл</b>, то ГМ должен правдиво ответить. - При неудаче ГМ даст случайный ответ. - Если результат разносторонний, то ГМ даст результат, который наступит раньше.$$, $$$$, $$7-19$$, $$5$$, $$[{"id":"d15a724f-080a-2381-098e-3a080e7307d7","qty":"2"}]$$::jsonb, '', $$$$, $$2$$, $$$$, $$$$, ''),
  ('MS215', 'exp_toc', 'level.novice', $$Спорная подвеска$$, $$Wagerer's Pendant$$, $$Создает подвеску, которая отключает любые эффекты порч уже имеющихся и новых.
 - При снятии подвески эффекты возвращаются.
 - Если к концу действия ритуала на пользователе еще будут активные порчи, подвеска расколется и пользователь, как и цели в пределах 2м получат ряд новых порч по решению ГМа.$$, $$$$, $$14$$, $$10$$, $$[{"id":"d0732ae7-c4ba-c419-6de2-3c93e7026267","qty":"2"},{"id":"94a8241e-b596-42bc-cf72-63d170b8a3e8","qty":"1"},{"id":"46b9acc3-bafb-cc61-b682-2dc69f2273e4","qty":"2"},{"id":"ac5a3e24-237c-7c82-c231-7b3d3b9a08cf","qty":"2"},{"id":"816486fb-5bb8-1be3-8e5a-e4114da71e22","qty":"2"},{"id":"53567104-8ef6-8947-39c6-d8b8a4194491","qty":"5"},{"id":"4f5fdc10-102f-dc7c-1b8e-bdcd2b7d32cf","qty":"2"}]$$::jsonb, '', $$$$, $$6$$, $$$$, $$7$$, 'time.unit.day'),
  ('MS216', 'exp_toc', 'level.journeyman', $$Живой доспех$$, $$Animate Armor$$, $$"Оживляет" набор доспехов, исполняющие приказы создателя.
 - Выполняет простые приказы (как пёс).
 - Не думает, исполняет приказ в точности до отмены или своей смерти.
 - Если разрушить ПБ корпуса, то следующий удар в корпус "убьёт" доспех, уничтожив сердце голема.
 - Двимеритовая бомба дает штраф -2 ко всем броскам и не дает пользоваться "Перегрузкой".$$, $$$$, $$18$$, $$10$$, $$[{"id":"041738db-1b4f-578e-7c98-b04a1b884df6","qty":"1"},{"id":"e7cf622c-22be-f0e8-63c8-da58b853d3c8","qty":"1"},{"id":"0a416bc0-e095-814d-9297-9f5508a492b0","qty":"1"},{"id":"1014034b-15bc-1af7-9cef-74b36adf2384","qty":"3"},{"id":"0b9430ff-a3b5-47c7-80de-7519ef60e9ad","qty":"3"},{"id":"de6f5338-aa3b-f318-3a1b-67a6672d3ff0","qty":"1"}]$$::jsonb, 'magic.form.direct', $$$$, $$14$$, $$$$, $$$$, ''),
  ('MS217', 'exp_toc', 'level.journeyman', $$Маяк неестественного$$, $$Beacon of the Unnatural$$, $$Создает мрачный тотем, который привлекает всех монстров в радиусе 1.6км для строительства гнезда в этом месте.
 - Каждый год радиус влияния растет на 1.6км. 
 - Рост тотема 2м, прочность 20ПЗ.$$, $$$$, $$18$$, $$15$$, $$[{"id":"9f1fb9fd-2675-38d5-3d4a-8668e5c18652","qty":"1"},{"id":"9d0b8763-9253-3963-b65f-78693871d6fe","qty":"4"},{"id":"bdb5ae41-e8fe-9565-c659-2ba7b71ea360","qty":"1"},{"id":"94a8241e-b596-42bc-cf72-63d170b8a3e8","qty":"5"},{"id":"1014034b-15bc-1af7-9cef-74b36adf2384","qty":"1"}]$$::jsonb, 'magic.form.direct', $$$$, $$14$$, $$$$, $$$$, ''),
  ('MS218', 'exp_toc', 'level.journeyman', $$Туман прошлого$$, $$Fog of the Past$$, $$Создает стеклянную конструкцию, окруженную свечами, которая показывает наиболее эмоцио-нальное событие из прошлого в месте создания.
 - Событие в ведении может длиться до 5 минут.
 - Видение повторяется раз за разом до конца ритуала.$$, $$$$, $$18$$, $$10$$, $$[{"id":"d0732ae7-c4ba-c419-6de2-3c93e7026267","qty":"5"},{"id":"ce077dac-df9d-6ec7-3c6a-ecbffb270c7c","qty":"1"},{"id":"ca5a14fb-9e24-90b1-658c-bff2e4c6126e","qty":"5"},{"id":"cc8795c1-50a5-6aa4-b240-e444ce657163","qty":"2"}]$$::jsonb, 'magic.form.direct', $$$$, $$10$$, $$$$, $$20$$, 'м'),
  ('MS219', 'exp_toc', 'level.journeyman', $$Волшебная гостевая книга$$, $$Magical Guestbook$$, $$Создает невидимую завесу на арке или дверной раме.
 - Записывает лица любых прошедших, которые вы можете получить телепатически по запросу.
 - Телепатически само предупреждает вас, если прошел кто-то конкретный, кого вы указали при создании завесы.
 - Для телепатической связи вы должны быть в пределах 100м.
 - После конца ритуала, все записи хранятся в глиняной фигурке, которую может считать любой, способный к магии, пока фигурка цела.$$, $$$$, $$16$$, $$10$$, $$[{"id":"816486fb-5bb8-1be3-8e5a-e4114da71e22","qty":"2"},{"id":"381b9ffe-9391-30fe-d5bf-b0cc9bf710d6","qty":"2"},{"id":"9f875b0e-d9e1-cf8c-1bd1-56bd30d496ba","qty":"1"},{"id":"1014034b-15bc-1af7-9cef-74b36adf2384","qty":"1"}]$$::jsonb, 'magic.form.direct', $$$$, $$8$$, $$$$, $$1$$, 'time.unit.day'),
  ('MS220', 'exp_toc', 'level.master', $$Создание места силы$$, $$Create Place of Power$$, $$Создаёт Место Силы на пересечении двух Лей-линий с одинаковым элементом. - При крит.провале маг:   * Получает стихийный смешанный эффект   * Фокусирующие предметы при себе взрывается на 1d10 в радиусе 2м.   * Используемые камни взрываются, нанося 7d6 урона в радиусе 6м.$$, $$$$, $$20$$, $$20$$, $$[{"id":"e2492c2e-b990-8c75-95f0-4447473d0591","qty":null},{"id":"e37f8b67-a08c-eafd-a3d9-053d6105dfe6","qty":"40"}]$$::jsonb, 'magic.form.direct', $$$$, $$18$$, $$$$, $$$$, ''),
  ('MS221', 'exp_toc', 'level.master', $$Зачарованный амулет$$, $$Enchant Amulet$$, $$Создает амулет, позволяющий использовать 1-4 спеллов и инвокаций, не знакомых пользователю  - При создании нужно знать каждую вложенную магию и потратить цену <b>ВЫН</b> каждой. Для активных нужно потратить по 4*<b>ВЫН</b> цены поддержки. Причем, любой предмет фокусировки бесполезен при создании.
- При создании, если вложено больше 1 магии, нужно выбрать один негативный эффект:   * Штраф -5 к максимальным ПЗ.   * Штраф -10 к максимальной <b>ВЫН</b>.   * Штраф -1 к <b>ИНТ</b>, <b>РЕА</b>, <b>Воле</b>. Всегда болит голова. Эти штрафы сохраняются еще 24ч после снятия амулета. - Амулет дает фокусировку (2). Нельзя использовать любой другой предмет фокусировки при использовании магии амулета. - Перегрузка невозможна, нужно иметь достаточно <b>Энергии</b> для использования магии из амулета. - Жрецы и друиды могут использовать спеллы магов, но не наоборот.$$, $$$$, $$18$$, $$15$$, $$[{"id":"6b5fb14c-834f-dc98-b696-dc7fb62b679b","qty":"1"},{"id":"e2492c2e-b990-8c75-95f0-4447473d0591","qty":"1"},{"id":"4291ed31-6d63-6bb7-adf4-63af0601b590","qty":"1 шт. на спелл"},{"id":"1014034b-15bc-1af7-9cef-74b36adf2384","qty":"2"}]$$::jsonb, 'magic.form.self', $$$$, $$$$, $$$$, $$$$, '')
),
ritual_effects_en (ms_id, text_en) AS (
  VALUES
    ('MS104', 'Cleanses the target of poisons and diseases.
- Removes (choose one, with different DCs):
  * DC 12 — alcohol and drugs
  * DC 15 — poison and oils
  * DC 18 — diseases
- Cannot cure the Catriona Plague.'),
    ('MS105', 'Allows you to see events from the last 2 days on the surface of water.
* DC 15 — past events
* DC 18 — current events
- A mage at the location of the current events may notice they are being watched by rolling (Magical Knowledge) vs your (Ritual Crafting).'),
    ('MS106', 'Records a message into a medium as a full-height hologram of the mage.
- Up to 5 minutes long.
- Can be played back 1–3 times (at the mage''s choice).
- If recorded into a perfect gemstone, the recording looks lifelike.'),
    ('MS107', 'Allows you to see current events in a flame.
- A mage at the watched location may notice the scrying by rolling (Magical Knowledge) vs your (Ritual Crafting).'),
    ('MS108', 'Creates a healing circle.
- Affects 1 target.
- Heals 3 HP per turn for a target inside the circle.
- If the target leaves the circle, it disappears.'),
    ('MS109', 'Creates a circle filled with magic.
- The first target to enter who is capable of magic gains a bonus to Energy equal to (Ritual Crafting)/2.
- Affects only 1 target.
- Alternative: drain the circle to gain (1d6)/2 Fifth Essence.'),
    ('MS110', 'Creates a vortex inside a sealed clay jar.
- Limited shelf life.
- When the jar is broken, a random spell triggers (1d10/2):
  * Talfryn''s Prison
  * Zephyr
  * Tanio Ilchar
  * Dormyn''s Fog
  * Static Storm'),
    ('MS111', 'Summons the spirit of the dead with its mind and memories, including the cause of death.
- The spirit can be dismissed at its will or destroyed.
- You can speak with it at the burial site.
- Also summons all relatives within 20 m.
- The spirit may possess a target. Defense: roll (Resist Magic) vs (Spell Casting) immediately and every 1d6 turns at the same DC. On a failure, the spirit controls the body.
The target gets +5 to (Resist Magic) if the behavior is unacceptable and +10 if it is life-threatening.'),
    ('MS112', 'Allows communication with another owner of the same device.
- Both participants must perform the ritual simultaneously.'),
    ('MS113', 'Creates a one-way (both directions) impenetrable circle for monsters.
- To pass through in one direction, a creature rolls (Resist Magic) vs the (Ritual Crafting) roll used to create the barrier.
- Blocks monster magic inside, but not physical projectiles.
- The metal used must match the monster''s vulnerability.
- Lasts until dispelled.'),
    ('MS114', 'Creates a solid barrier of light.
- The barrier has 50 HP.
- Impenetrable to material objects, but not to incorporeal entities.
- Teleportation in and out is possible.
- You may stop air exchange; then the air lasts 20 - [number of targets inside] turns.
- You may restore the barrier by 5 HP for each 1 STA.'),
    ('MS115', 'Allows you to see the truth in a dream.
* DC 15 — past events
* DC 18 — current events
- A mage at the watched location may notice the scrying by rolling (Magical Knowledge) vs your (Ritual Crafting).
- You may share the dream with up to (Ritual Crafting) other people, but they must answer several personal questions.
- The dream lasts until the end of the ritual.'),
    ('MS116', 'Compresses the target into a jade figurine 10× smaller than the original (range 10 m).
- If the target fails an Endurance check at DC 15, they take 6d6 damage to the torso.
- The target does not age, but has only 20% HP.
- You may snap off a head or limb with a Strength check at DC 14, or by dealing 5 damage. The effects correspond to critical wounds after decompression.
- The released target is Dazed.'),
    ('MS117', 'Creates a simple golem that obeys the creator''s commands.
- Cannot use fine motor skills.
- Cannot follow precise, highly detailed orders.
- Does not think; it follows orders until canceled or until it is destroyed.'),
    ('MS118', 'Creates a controllable illusion next to the mage.
- The illusion feels real: sight, touch, sound, and smell.
- If the illusion attacks, the target rolls (Resist Magic) or (Endurance) at DC 12.
On success the illusion is revealed; on failure the target makes a Stability test. On a second failure the target is Dazed.
- Lasts until dispelled.'),
    ('MS212', 'Turns the skull of a cat, dog, bird, or snake into a crystal skull.
- You can activate it to turn it into the animal it was made from.
- The animal follows mental commands it can hear while nearby.
- When the animal dies, the skull deactivates, but can be recharged with the same ritual using [2] Fifth Essence.'),
    ('MS213', 'Enchants a trophy from a monster that the user helped kill. The worn effect depends on the monster:
- Demon: +2 to (Spell Casting) and (Resist Magic) rolls.
- Bruxa: you can communicate telepathically within 20 m.
- Wendigo: immunity to diseases.
- Wyvern: attacks gain Poison (25%).
- Garkain: +1 to saves vs Stun.
- Fiend: immunity to poison.
- Golem: immunity to bleeding.
- Griffin: when you take a critical wound, roll d10 twice and take one result.
- Igosha: you gain the social standing "Feared"; if you already had it, the effects double.
- Katakan: attacks gain Bleeding (25%).
- Grave Hag: +2 to (Ritual Crafting) and (Hex Weaving).
- Cockatrice: attacks gain Blinded (10%).
- Leshen: you can speak with animals and can dominate them after a verbal duel; animals will not harm themselves.
- Manticore: +2 to the DC to resist and remove your poisons.
- Bear: enemies suffer -2 when attempting to break out of your grapple.
- Plague Maiden: flies swarm around you. Enemies nearby take -2 to rolls and may contract Disease (10%). You suffer -2 to (Seduction), (Persuasion), and Appearance.
- Werewolf: +2 to (Strength) and (Wilderness Survival) rolls.
- Ozzrel: +2 to (Spell Casting) for fire magic.
- Panther: climbing speed ×2.
- Noonwraith: immunity to fear.
- Rock Troll: +1 to the range multiplier for thrown weapons.
- Succubus: +1 social standing.
- Troll: you get drunk twice as slowly and without a hangover.
- Foglet: +2 to (Stealth) and (Sleight of Hand).
- Graveir: a corpse-eater will always choose another target if one exists.
- Phoenix: -50% to the chance to ignite (minimum 0).
- Hym: a minimum of 4 damage always bypasses enemy armor.
- Chimera: once per day you choose resistance to one weapon damage type.
- Cyclops: instead of being Dazed by magic, you attack the nearest living target next round.
- Shaelmaar: +2 to (Spell Casting) for earth magic.
- Earth Elemental: destructive damage to SP or HP is doubled.
- Ice Elemental: attacks gain Freezing (25%).
- Fire Elemental: attacks gain Burning (25%).'),
    ('MS214', 'Lets you learn whether an action will have a positive or negative outcome. The DC depends on the cheese (1d6, rolled secretly by the GM):
* Standard cheese: DC [13 + 1d6]
* High-quality cheese: DC [13 - 1d6]
If you succeed on (Ritual Crafting) at that DC, the GM must answer truthfully.
- On a failure, the GM gives a random answer.
- If the outcome is mixed, the GM gives the outcome that will happen sooner.'),
    ('MS215', 'Creates a pendant that suppresses all active and newly applied hex effects.
- When the pendant is removed, the effects return.
- If, by the end of the ritual''s duration, the wearer still has active hexes, the pendant cracks and the wearer (and targets within 2 m) gain several new hexes at the GM''s discretion.'),
    ('MS216', '"Animates" a suit of armor that obeys the creator''s commands.
- Follows simple commands (like a dog).
- Does not think; follows orders until canceled or destroyed.
- If the torso SP is destroyed, the next hit to the torso "kills" the armor by destroying the golem''s heart.
- A dimeritium bomb gives -2 to all rolls and prevents using "Overcharge".'),
    ('MS217', 'Creates a grim totem that attracts all monsters within 1.6 km to build nests in the area.
- Each year, the radius increases by 1.6 km.
- The totem is 2 m tall and has 20 HP.'),
    ('MS218', 'Creates a glass construction surrounded by candles that shows the most emotional event from the past at the place of casting.
- The scene may last up to 5 minutes.
- The vision repeats over and over until the ritual ends.'),
    ('MS219', 'Creates an invisible veil on an arch or door frame.
- Records the faces of anyone who passes through; you can receive them telepathically on request.
- Warns you telepathically if a specific person (named during creation) passes through.
- You must be within 100 m for the telepathic link.
- After the ritual ends, all records are stored in a clay figurine; any magic user can read it while the figurine remains intact.'),
    ('MS220', 'Creates a Place of Power at the intersection of two Ley Lines of the same element.
On a critical failure the mage:
* gains a random mixed elemental effect
* any focusing items they carry explode for 1d10 damage in a 2 m radius
* the stones used explode, dealing 7d6 damage in a 6 m radius'),
    ('MS221', 'Creates an amulet that allows the user to cast 1–4 spells and invocations the user does not know.
- To create it, you must know each embedded magic and pay the full STA cost of each. For active effects, you must also pay 4*STA of each sustain cost. Any focusing item is useless during creation.
- If more than 1 magic is embedded, choose one negative effect:
  * -5 to maximum HP
  * -10 to maximum STA
  * -1 to INT, REF, and WILL; constant headache
These penalties also remain for 24 hours after removing the amulet.
- The amulet provides Focusing (2).
- You cannot use any other focusing item when casting from the amulet.
- Overcharge is impossible; you must have enough Energy to use the magic from the amulet.
- Priests and druids can use mage spells, but not vice versa.')
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
     , rd.ingredients
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
