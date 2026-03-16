\echo '038_mage_events_danger_details.sql'

-- Hierarchy key
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.hierarchy.mage_events_danger_details'), 'hierarchy', 'path', 'ru', 'Детали'),
  (ck_id('witcher_cc.hierarchy.mage_events_danger_details'), 'hierarchy', 'path', 'en', 'Details')
ON CONFLICT (id, lang) DO NOTHING;

-- Question
WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_mage_events_danger_details' AS qu_id
         , 'questions' AS entity
  )
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru', 'Определите детали реализовавшейся опасности.'),
        ('en', 'Determine the details of the danger that befell you.')
      ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
)
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Событие'),
      ('ru', 3, 'Деталь'),
      ('ru', 4, 'Опасность'),
      ('en', 1, 'Chance'),
      ('en', 2, 'Event'),
      ('en', 3, 'Detail'),
      ('en', 4, 'Danger')
)
, ins_cols AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.column_name') AS id
         , meta.entity, 'column_name', c_vals.lang, c_vals.text
      FROM c_vals
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
)
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
SELECT meta.qu_id
     , meta.su_su_id
     , NULL
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body')
     , 'single_table'
     , jsonb_build_object(
         'dice', 'd_weighed',
         'columns', (
           SELECT jsonb_agg(ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(num, 'FM9900') ||'.'|| meta.entity ||'.column_name')::text ORDER BY num)
           FROM (SELECT DISTINCT num FROM c_vals) cols
         ),
         'columnLayout', jsonb_build_array(
           jsonb_build_object('fit', true, 'align', 'center'),
           jsonb_build_object('fit', true, 'align', 'center'),
           jsonb_build_object('fit', true, 'align', 'center'),
           jsonb_build_object('fit', false, 'align', 'left')
         ),
         'path', jsonb_build_array(
           ck_id('witcher_cc.hierarchy.life_events')::text,
           jsonb_build_object('jsonlogic_expression', jsonb_build_object('cat', jsonb_build_array(
             jsonb_build_object('var', 'counters.lifeEventsCounter'),
             '-',
             jsonb_build_object('+', jsonb_build_array(
               jsonb_build_object('var', 'counters.lifeEventsCounter'),
               10
             ))
           ))),
           ck_id('witcher_cc.hierarchy.mage_events_risk')::text,
           ck_id('witcher_cc.hierarchy.mage_events_danger_details')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO UPDATE
SET body = EXCLUDED.body,
    qtype = EXCLUDED.qtype,
    metadata = EXCLUDED.metadata;

-- Answer options
WITH
  region_vals AS (
    SELECT *
      FROM (VALUES
        (1,  'Каэдвен', 'Каэдвене', 'Каэдвена', 'Северные королевства', 'Kaedwen', 'Northern Kingdoms'),
        (2,  'Ковир и Повисс', 'Ковире и Повиссе', 'Ковира и Повисса', 'Северные королевства', 'Kovir and Poviss', 'Northern Kingdoms'),
        (3,  'Редания', 'Редании', 'Редании', 'Северные королевства', 'Redania', 'Northern Kingdoms'),
        (4,  'Аэдирн', 'Аэдирне', 'Аэдирна', 'Северные королевства', 'Aedirn', 'Northern Kingdoms'),
        (5,  'Лирия и Ривия', 'Лирии и Ривии', 'Лирии и Ривии', 'Северные королевства', 'Lyria and Rivia', 'Northern Kingdoms'),
        (6,  'Темерия', 'Темерии', 'Темерии', 'Северные королевства', 'Temeria', 'Northern Kingdoms'),
        (7,  'Цидарис', 'Цидарисе', 'Цидариса', 'Северные королевства', 'Cidaris', 'Northern Kingdoms'),
        (8,  'Керак', 'Кераке', 'Керака', 'Северные королевства', 'Kerack', 'Northern Kingdoms'),
        (9,  'Вердэн', 'Вердэне', 'Вердэна', 'Северные королевства', 'Verden', 'Northern Kingdoms'),
        (10, 'Скеллиге', 'Скеллиге', 'Скеллиге', 'Северные королевства', 'Skellige', 'Northern Kingdoms'),
        (11, 'Цинтра', 'Цинтре', 'Цинтры', 'Нильфгаард', 'Cintra', 'Nilfgaard'),
        (12, 'Ангрен', 'Ангрене', 'Ангрена', 'Нильфгаард', 'Angren', 'Nilfgaard'),
        (13, 'Назаир', 'Назаире', 'Назаира', 'Нильфгаард', 'Nazair', 'Nilfgaard'),
        (14, 'Меттина', 'Меттине', 'Меттины', 'Нильфгаард', 'Mettina', 'Nilfgaard'),
        (15, 'Туссент', 'Туссенте', 'Туссента', 'Нильфгаард', 'Toussaint', 'Nilfgaard'),
        (16, 'Маг Турга', 'Маг Турге', 'Маг Турги', 'Нильфгаард', 'Mag Turga', 'Nilfgaard'),
        (17, 'Гесо', 'Гесо', 'Гесо', 'Нильфгаард', 'Gheso', 'Nilfgaard'),
        (18, 'Эббинг', 'Эббинге', 'Эббинга', 'Нильфгаард', 'Ebbing', 'Nilfgaard'),
        (19, 'Мехт', 'Мехте', 'Мехта', 'Нильфгаард', 'Maecht', 'Nilfgaard'),
        (20, 'Этолия', 'Этолии', 'Этолии', 'Нильфгаард', 'Etolia', 'Nilfgaard'),
        (21, 'Геммера', 'Геммере', 'Геммеры', 'Нильфгаард', 'Gemmera', 'Nilfgaard'),
        (22, 'Доль Блатанна', 'Доль Блатанне', 'Доль Блатанны', 'Земли старших народов', 'Dol Blathanna', 'Elderlands'),
        (23, 'Махакам', 'Махакаме', 'Махакама', 'Земли старших народов', 'Mahakam', 'Elderlands')
      ) AS v(sort_order, ru_name, ru_name_prep, ru_name_gen, ru_group, en_name, en_group)
  ),
  hex_vals AS (
    SELECT *
      FROM (VALUES
        (1, 'MS119', NULL, 'Теневая порча', 'The Hex of Shadows'),
        (2, 'MS120', NULL, 'Вечный зуд', 'The Eternal Itch'),
        (3, 'MS121', NULL, 'Дьявольская удача', 'The Devil''s Luck'),
        (4, 'MS122', NULL, 'Кошмар', 'The Nightmare'),
        (5, 'MS123', NULL, 'Поцелуй Песты', 'The Pesta''s Kiss'),
        (6, 'MS124', NULL, 'Звериная порча', 'The Hex of the Beast'),
        (7, 'MS222', 'exp_toc', 'Проклятие трезвости', 'Curse of Temperance'),
        (8, 'MS223', 'exp_toc', 'Отвратительная порча', 'The Odious Hex'),
        (9, 'MS224', 'exp_toc', 'Дурной сглаз', 'The Evil Eye'),
        (10, 'MS225', 'exp_toc', 'Бесконечная потребность', 'Unending Need'),
        (11, 'MS226', 'exp_toc', 'Стеклянные кости', 'Bones of Glass'),
        (12, 'MS227', 'exp_toc', 'Порча забвения', 'Hex of Forgetfulness')
      ) AS v(sort_order, ms_id, required_dlc, ru_name, en_name)
  ),
  curse_vals AS (
    SELECT *
      FROM (VALUES
        (1, 0.2::numeric, NULL, '<b>Проклятие чудовищности</b>', '<b>Curse of Monstrosity</b>', 'Интенсивность: Средняя', 'Intensity: Moderate'),
        (2, 0.2::numeric, NULL, '<b>Проклятие призраков</b>', '<b>Curse of Phantoms</b>', 'Интенсивность: Средняя', 'Intensity: Moderate'),
        (3, 0.2::numeric, NULL, '<b>Проклятие заразы</b>', '<b>Curse of Pestilence</b>', 'Интенсивность: Высокая', 'Intensity: High'),
        (4, 0.2::numeric, NULL, '<b>Проклятие странника</b>', '<b>Curse of the Wanderer</b>', 'Интенсивность: Высокая', 'Intensity: High'),
        (5, 0.2::numeric, NULL, '<b>Проклятие ликантропии</b>', '<b>Curse of Lycanthropy</b>', 'Интенсивность: Высокая', 'Intensity: High'),
        (6, 0.0::numeric, NULL, '<b>Другое проклятие</b>', '<b>Other Curse</b>', 'Кастомное проклятие', 'Custom curse')
      ) AS v(sort_order, probability, required_dlc, ru_name, en_name, ru_detail, en_detail)
  ),
  addiction_vals AS (
    SELECT *
      FROM (VALUES
        (1, 0.125::numeric, 'Алкоголь', 'Alcohol'),
        (2, 0.125::numeric, 'Табак', 'Tobacco'),
        (3, 0.125::numeric, 'Фисштех', 'Fisstech'),
        (4, 0.125::numeric, 'Азартные игры', 'Gambling'),
        (5, 0.125::numeric, 'Клептомания', 'Kleptomania'),
        (6, 0.125::numeric, 'Похоть', 'Lust'),
        (7, 0.125::numeric, 'Обжорство', 'Gluttony'),
        (8, 0.125::numeric, 'Адреналиновая зависимость', 'Adrenaline addiction'),
        (10, 0.0::numeric, 'Другое', 'Other (create your own)')
      ) AS v(num, probability, ru_name, en_name)
  ),
  accident_vals AS (
    SELECT *
      FROM (VALUES
        (1, 0.4::numeric, 'Изуродованы', 'Disfigured', 'Вы были изуродованы. Ваш социальный статус теперь "Опасение" в каждой группе.', 'You were disfigured. Your social status is now "Feared" in every group.'),
        (2, 0.2::numeric, 'Прикованы к постели', 'Bedridden', 'Вы были прикованы к постели на срок от 1 до 10 лет.', 'You were bedridden for between 1 and 10 years.'),
        (3, 0.2::numeric, 'Потеря воспоминаний', 'Lost memories', 'Вы потеряли память об от 1 до 10 годах из этой декады.', 'You lost your memory of 1 to 10 years from this decade.'),
        (4, 0.2::numeric, 'Ужасные кошмары', 'Horrible nightmares', 'Вы страдаете от ужасных кошмаров.', 'You suffer from horrible nightmares.')
      ) AS v(num, probability, ru_result, en_result, ru_danger, en_danger)
  ),
  accusation_vals AS (
    SELECT *
      FROM (VALUES
        (1, 0.2::numeric, 'Кража', 'в краже', 'Theft'),
        (2, 0.1::numeric, 'Трусость', 'в трусости', 'Cowardice'),
        (3, 0.1::numeric, 'Измена', 'в измене', 'Treason'),
        (4, 0.1::numeric, 'Изнасилование', 'в изнасиловании', 'Rape'),
        (5, 0.1::numeric, 'Убийство', 'в убийстве', 'Murder'),
        (6, 0.1::numeric, 'Мошенничество', 'в мошенничестве', 'Fraud'),
        (7, 0.1::numeric, 'Запретная магия', 'в запретной магии', 'Forbidden Magic'),
        (8, 0.1::numeric, 'Уклонение от уплаты налогов', 'в уклонении от уплаты налогов', 'Tax Evasion'),
        (9, 0.1::numeric, 'Неэтичные действия', 'в неэтичных действиях', 'Unethical Practices')
      ) AS v(num, probability, ru_name, ru_case, en_name)
  ),
  element_vals AS (
    SELECT *
      FROM (VALUES
        (1, 'Вода', 'Water'),
        (2, 'Земля', 'Earth'),
        (3, 'Огонь', 'Fire'),
        (4, 'Воздух', 'Air')
      ) AS v(num, ru_name, en_name)
  ),
  monster_vals AS (
    SELECT *
      FROM (VALUES
        (1,  'dlc_sh_mothr', 'Вампиры', 'Vampires', '#d45d5d', 'Альп', 'Alp'),
        (2,  'exp_wj',       'Вампиры', 'Vampires', '#d45d5d', 'Брукса', 'Bruxa'),
        (3,  'exp_wj',       'Вампиры', 'Vampires', '#d45d5d', 'Гаркон', 'Garkain'),
        (4,  NULL,           'Вампиры', 'Vampires', '#d45d5d', 'Катакан', 'Katakan'),
        (5,  'exp_wj',       'Вампиры', 'Vampires', '#d45d5d', 'На крыльях тени', 'On Shadow Wings'),
        (6,  'exp_wj',       'Вампиры', 'Vampires', '#d45d5d', 'Пакомара', 'Plumard'),
        (7,  'exp_wj',       'Гибриды', 'Hybrids', '#53b5c8', 'Гарпия', 'Harpy'),
        (8,  'exp_wj',       'Гибриды', 'Hybrids', '#53b5c8', 'Глаз охотника', 'With Hunting Eyes'),
        (9,  NULL,           'Гибриды', 'Hybrids', '#53b5c8', 'Грифон', 'Griffin'),
        (10, 'exp_wj',       'Гибриды', 'Hybrids', '#53b5c8', 'Мантикора', 'Manticore'),
        (11, NULL,           'Гибриды', 'Hybrids', '#53b5c8', 'Сирена', 'Siren'),
        (12, 'exp_wj',       'Гибриды', 'Hybrids', '#53b5c8', 'Суккуб', 'Succubus'),
        (13, NULL,           'Дракониды', 'Draconids', '#d78a4c', 'Виверна', 'Wyvern'),
        (14, 'exp_wj',       'Дракониды', 'Draconids', '#d78a4c', 'Куролиск', 'Cockatrice'),
        (15, 'exp_wj',       'Дракониды', 'Draconids', '#d78a4c', 'Огонь с небес', 'Fire From The Sky'),
        (16, 'exp_wj',       'Дракониды', 'Draconids', '#d78a4c', 'Осгазир', 'Slyzard'),
        (17, 'exp_wj',       'Дракониды', 'Draconids', '#d78a4c', 'Феникс', 'Phoenix'),
        (18, 'exp_toc',      'Духи', 'Specters', '#a87be8', 'Амальгама трупов', 'Corpse Amalgam'),
        (19, 'exp_wj',       'Духи', 'Specters', '#a87be8', 'Варгест', 'Barghest'),
        (20, 'exp_toc',      'Духи', 'Specters', '#a87be8', 'Демон Рогатый', 'Bes'),
        (21, 'exp_toc',      'Духи', 'Specters', '#a87be8', 'Касглидд', 'Casglydd'),
        (22, 'exp_toc',      'Духи', 'Specters', '#a87be8', 'Мари Луид', 'Mari Lwyd'),
        (23, 'exp_wj',       'Духи', 'Specters', '#a87be8', 'Песта', 'Pesta'),
        (24, 'exp_toc',      'Духи', 'Specters', '#a87be8', 'Покаянник', 'Penitent'),
        (25, NULL,           'Духи', 'Specters', '#a87be8', 'Полуденница', 'Noon Wraith'),
        (26, NULL,           'Духи', 'Specters', '#a87be8', 'Призрак', 'Wraith'),
        (27, 'exp_wj',       'Духи', 'Specters', '#a87be8', 'Среди мертвых тел', 'Among Corpses'),
        (28, 'exp_wj',       'Духи', 'Specters', '#a87be8', 'Хим', 'Hym'),
        (29, NULL,           'Духи стихий', 'Elementa', '#79bde8', 'Голем', 'Golem'),
        (30, 'exp_toc',      'Духи стихий', 'Elementa', '#79bde8', 'Живая броня', 'Living Armor'),
        (31, 'exp_wj',       'Духи стихий', 'Elementa', '#79bde8', 'Пожар', 'Wildfire'),
        (32, 'exp_wj',       'Духи стихий', 'Elementa', '#79bde8', 'Элементаль земли', 'Earth Elemental'),
        (33, 'exp_wj',       'Духи стихий', 'Elementa', '#79bde8', 'Элементаль льда', 'Ice Elemental'),
        (34, 'exp_wj',       'Духи стихий', 'Elementa', '#79bde8', 'Элементаль огня', 'Fire Elemental'),
        (35, 'exp_wj',       'Инсектоиды', 'Insectoids', '#c6a84b', 'Барбегази', 'Barbegazi'),
        (36, NULL,           'Инсектоиды', 'Insectoids', '#c6a84b', 'Главоглаз', 'Arachas'),
        (37, 'dlc_sh_mothr', 'Инсектоиды', 'Insectoids', '#c6a84b', 'Жагница', 'Glustyworp'),
        (38, 'exp_wj',       'Инсектоиды', 'Insectoids', '#c6a84b', 'Из-под земли', 'Scurrying From Tunnels'),
        (39, 'exp_wj',       'Инсектоиды', 'Insectoids', '#c6a84b', 'Сколопендроморф', 'Giant Centipede'),
        (40, 'exp_wj',       'Инсектоиды', 'Insectoids', '#c6a84b', 'Химера', 'Frigher'),
        (41, NULL,           'Инсектоиды', 'Insectoids', '#c6a84b', 'Эндриага', 'Endrega'),
        (42, NULL,           'Огры', 'Ogroids', '#c08a61', 'Накер', 'Nekker'),
        (43, 'exp_wj',       'Огры', 'Ogroids', '#c08a61', 'Нежеланный гость', 'Unwanted Hunter'),
        (44, NULL,           'Огры', 'Ogroids', '#c08a61', 'Скальный тролль', 'Rock Troll'),
        (45, 'exp_wj',       'Огры', 'Ogroids', '#c08a61', 'Стукач', 'Knockers'),
        (46, 'exp_wj',       'Огры', 'Ogroids', '#c08a61', 'Тролль', 'Troll'),
        (47, 'exp_wj',       'Огры', 'Ogroids', '#c08a61', 'Циклоп', 'Cyclops'),
        (48, 'exp_wj',       'Проклятые', 'Cursed Ones', '#8c6bd6', 'Археспора', 'Archespore'),
        (49, 'exp_wj',       'Проклятые', 'Cursed Ones', '#8c6bd6', 'Вендиго', 'Vendigo'),
        (50, NULL,           'Проклятые', 'Cursed Ones', '#8c6bd6', 'Волколак', 'Werewolf'),
        (51, 'exp_wj',       'Проклятые', 'Cursed Ones', '#8c6bd6', 'Игоша', 'Botchling'),
        (52, 'dlc_sh_mothr', 'Проклятые', 'Cursed Ones', '#8c6bd6', 'Котолак', 'Werecat'),
        (53, 'exp_wj',       'Проклятые', 'Cursed Ones', '#8c6bd6', 'Сирота', 'The Orphan'),
        (54, NULL,           'Реликты', 'Relicts', '#67ba93', 'Бес', 'Fiend'),
        (55, 'exp_wj',       'Реликты', 'Relicts', '#67ba93', 'Леший', 'Leshy'),
        (56, 'exp_wj',       'Реликты', 'Relicts', '#67ba93', 'Мелкая пакость', 'Undermining'),
        (57, 'exp_wj',       'Реликты', 'Relicts', '#67ba93', 'Прибожек', 'Godling'),
        (58, 'exp_wj',       'Реликты', 'Relicts', '#67ba93', 'Шарлей', 'Shalmaar'),
        (59, 'exp_wj',       'Трупоеды', 'Necrophages', '#7ab26a', 'В туманной мгле', 'In Cirrus Gloom'),
        (60, 'exp_wj',       'Трупоеды', 'Necrophages', '#7ab26a', 'Гнилец', 'Rotfiend'),
        (61, NULL,           'Трупоеды', 'Necrophages', '#7ab26a', 'Гуль', 'Ghoul'),
        (62, NULL,           'Трупоеды', 'Necrophages', '#7ab26a', 'Кладбищенская баба', 'Grave Hag'),
        (63, 'exp_wj',       'Трупоеды', 'Necrophages', '#7ab26a', 'Туманник', 'Foglet'),
        (64, 'exp_wj',       'Трупоеды', 'Necrophages', '#7ab26a', 'Утковол', 'Bullvore'),
        (65, NULL,           'Трупоеды', 'Necrophages', '#7ab26a', 'Утопец', 'Drowner')
      ) AS v(sort_order, required_dlc, ru_type, en_type, type_color, ru_name, en_name)
  ),
  mutation_vals AS (
    SELECT *
      FROM (VALUES
        (1,  'dlc_sh_mothr', '#d45d5d', 'Альп', 'Alp', 'Тёмно-красные вены по всему телу', 'A patchwork of dark red veins under your skin'),
        (2,  'exp_wj',       '#d45d5d', 'Гаркон', 'Garkain', 'Мягкие наросты на голове', 'Fleshy growths on the head'),
        (3,  NULL,           '#d45d5d', 'Катакан', 'Katakan', 'Долговязость', 'Gangly proportions'),
        (4,  'exp_wj',       '#d45d5d', 'Брукса', 'Bruxa', 'Полупрозрачная кожа и шипящий голос', 'Semi-translucent skin & a hissing voice'),
        (5,  NULL,           '#53b5c8', 'Грифон', 'Griffin', 'Прорастание перьев', 'Feather growth'),
        (6,  'exp_wj',       '#53b5c8', 'Мантикора', 'Manticore', 'Рожки и кошачьи черты лица', 'Small horns & feline features'),
        (7,  'exp_wj',       '#53b5c8', 'Суккуб', 'Succubus', 'Рожки и хвост', 'Small horns and a tail'),
        (8,  NULL,           '#d78a4c', 'Виверна', 'Wyvern', 'Огрубение кожи', 'Rough skin'),
        (9,  'exp_wj',       '#d78a4c', 'Куролиск', 'Cockatrice', 'Пучки зелёных перьев', 'Tufts of green feathers'),
        (10, 'exp_wj',       '#d78a4c', 'Феникс', 'Phoenix', 'Пучки серых перьев и свечение изнутри', 'Tufts of grey feathers & an internal glow'),
        (11, 'exp_wj',       '#a87be8', 'Песта', 'Pesta', 'Болезненно-бледная кожа и впалые щёки', 'Sickly pale skin & gaunt features'),
        (12, 'exp_toc',      '#a87be8', 'Покаянник', 'Penitent', 'Светящиеся белые отметины', 'Glowing white markings'),
        (13, NULL,           '#a87be8', 'Полуденница', 'Noon Wraith', 'Сухая, туго обтягивающая кожа', 'Dry, taut skin'),
        (14, NULL,           '#79bde8', 'Голем', 'Golem', 'Твёрдые наросты на теле', 'Hard protrusions'),
        (15, 'exp_wj',       '#79bde8', 'Элементаль Земли', 'Earth Elemental', 'Каменные наросты по всему телу', 'Rocky growths along your body'),
        (16, 'exp_wj',       '#79bde8', 'Элементаль Льда', 'Ice Elemental', 'Вечно холодная на ощупь кожа', 'Skin cold to the touch'),
        (17, 'exp_wj',       '#79bde8', 'Элементаль Огня', 'Fire Elemental', 'Струйки пламени изо рта', 'Small spouts of flame from your mouth'),
        (18, NULL,           '#c6a84b', 'Главоглаз', 'Arachas', 'Зелёная кровь и другие жидкости', 'Green bodily fluids'),
        (19, 'dlc_sh_mothr', '#c6a84b', 'Жагница', 'Glustyworp', 'Небольшие участки хитина на теле', 'Small patches of chitin'),
        (20, 'exp_wj',       '#c6a84b', 'Химера', 'Frigher', 'Фасеточные глаза и участки хитина', 'Multi-faceted eyes & patches of chitin'),
        (21, NULL,           '#c08a61', 'Накер', 'Nekker', 'Облысение и серая кожа', 'Baldness & grey skin'),
        (22, NULL,           '#c08a61', 'Скальный тролль', 'Rock Troll', 'Сгорбленность', 'Hunched posture'),
        (23, 'exp_wj',       '#c08a61', 'Тролль', 'Troll', 'Жёсткая голубоватая кожа', 'Blue-ish leathery skin'),
        (24, 'exp_wj',       '#8c6bd6', 'Вендиго', 'Vendigo', 'Клочки меха и болезненно-серая кожа', 'Patchy fur & sickly grey skin'),
        (25, NULL,           '#8c6bd6', 'Волколак', 'Werewolf', 'Рост волос по всему телу', 'Rapid hair growth'),
        (26, 'exp_wj',       '#8c6bd6', 'Игоша', 'Botchling', 'Волчья пасть и красные белки глаз', 'Wolf''s maw & red eye whites'),
        (27, 'dlc_sh_mothr', '#8c6bd6', 'Котолак', 'Werecat', 'Кошачьи глаза и усиленный рост волос', 'Cat''s eyes and increased hair growth'),
        (28, NULL,           '#67ba93', 'Бес', 'Fiend', 'Небольшие рожки', 'Small antlers'),
        (29, 'exp_wj',       '#67ba93', 'Леший', 'Leshy', 'На теле вырастают побеги и листья', 'Plants growing on the body'),
        (30, 'exp_wj',       '#67ba93', 'Шарлей', 'Shalmaar', 'Участки твёрдой, как камень, кожи', 'Patches of thick rock-textured skin'),
        (31, 'exp_wj',       '#7ab26a', 'Утковол', 'Bullvore', 'Твёрдые наросты по всему телу', 'Hard growths all over the body'),
        (32, 'exp_wj',       NULL, 'Медведь', 'Bear', 'Усиленный рост волос на теле', 'Prolific fur growth')
      ) AS v(sort_order, required_dlc, type_color, ru_name, en_name, ru_mutation, en_mutation)
  ),
  raw_data AS (
    -- 1-1 Debt
    SELECT 'ru' AS lang,
           'wcc_mage_events_danger_details_o0101' || to_char(gs.num, 'FM00') AS an_id,
           gs.num AS sort_order,
           0.1::numeric AS probability,
           'wcc_mage_events_danger_o0101' AS from_answer_id,
           NULL::text AS required_dlc,
           '<b>Долг</b>' AS col2,
           '' AS col3,
           'За тобой долг ' || (gs.num * 100)::text || ' крон.' AS col4
      FROM generate_series(1, 10) AS gs(num)

    UNION ALL
    SELECT 'en',
           'wcc_mage_events_danger_details_o0101' || to_char(gs.num, 'FM00'),
           gs.num,
           0.1::numeric,
           'wcc_mage_events_danger_o0101',
           NULL,
           '<b>Debt</b>',
           '',
           'A debt of ' || (gs.num * 100)::text || ' crowns is hanging over you.'
      FROM generate_series(1, 10) AS gs(num)

    -- 1-2 Addiction
    UNION ALL
    SELECT 'ru',
           'wcc_mage_events_danger_details_o0102' || to_char(v.num, 'FM00'),
           v.num,
           v.probability,
           'wcc_mage_events_danger_o0102',
           NULL,
           '<b>Зависимость</b>',
           v.ru_name,
           CASE WHEN v.num = 10 THEN 'Другая зависимость на ваш выбор.' ELSE 'У вас зависимость: ' || v.ru_name || '.' END
      FROM addiction_vals v

    UNION ALL
    SELECT 'en',
           'wcc_mage_events_danger_details_o0102' || to_char(v.num, 'FM00'),
           v.num,
           v.probability,
           'wcc_mage_events_danger_o0102',
           NULL,
           '<b>Addiction</b>',
           v.en_name,
           CASE WHEN v.num = 10 THEN 'A custom addiction of your choice.' ELSE 'You are addicted to ' || lower(v.en_name) || '.' END
      FROM addiction_vals v

    -- 1-4 Angered city folk
    UNION ALL
    SELECT 'ru',
           'wcc_mage_events_danger_details_o0104' || to_char(v.sort_order, 'FM00'),
           v.sort_order,
           (1.0::numeric / 23),
           'wcc_mage_events_danger_o0104',
           NULL,
           '<b>Разгневанные горожане</b>',
           '',
           'Жители одного города в (' || v.ru_group || ') ' || v.ru_name_prep || ' разозлены на вас по какой-то причине. Горожане сразу воспримут вас как угрозу и цель, лишь только завидев.'
      FROM region_vals v

    UNION ALL
    SELECT 'en',
           'wcc_mage_events_danger_details_o0104' || to_char(v.sort_order, 'FM00'),
           v.sort_order,
           (1.0::numeric / 23),
           'wcc_mage_events_danger_o0104',
           NULL,
           '<b>Angered City Folk</b>',
           '',
           'The people of one city in (' || v.en_group || ') ' || v.en_name || ' are angry with you for some reason. Its citizens will see you as a threat and a target the moment they lay eyes on you.'
      FROM region_vals v

    -- 1-5 Accident
    UNION ALL
    SELECT 'ru',
           'wcc_mage_events_danger_details_o0105' || to_char(v.num, 'FM00'),
           v.num,
           v.probability,
           'wcc_mage_events_danger_o0105',
           NULL,
           '<b>Несчастный случай</b>',
           v.ru_result,
           v.ru_danger
      FROM accident_vals v

    UNION ALL
    SELECT 'en',
           'wcc_mage_events_danger_details_o0105' || to_char(v.num, 'FM00'),
           v.num,
           v.probability,
           'wcc_mage_events_danger_o0105',
           NULL,
           '<b>Accident</b>',
           v.en_result,
           v.en_danger
      FROM accident_vals v

    -- 1-6 Imprisonment in years
    UNION ALL
    SELECT 'ru',
           'wcc_mage_events_danger_details_o0106' || to_char(gs.num, 'FM00'),
           gs.num,
           0.1::numeric,
           'wcc_mage_events_danger_o0106',
           NULL,
           '<b>Заключение в тюрьму</b>',
           '',
           'Вы провели в тюрьме ' || gs.num::text || CASE WHEN gs.num = 1 THEN ' год' WHEN gs.num BETWEEN 2 AND 4 THEN ' года' ELSE ' лет' END || '.'
      FROM generate_series(1, 10) AS gs(num)

    UNION ALL
    SELECT 'en',
           'wcc_mage_events_danger_details_o0106' || to_char(gs.num, 'FM00'),
           gs.num,
           0.1::numeric,
           'wcc_mage_events_danger_o0106',
           NULL,
           '<b>Imprisonment</b>',
           '',
           'You spent ' || gs.num::text || CASE WHEN gs.num = 1 THEN ' year' ELSE ' years' END || ' in prison.'
      FROM generate_series(1, 10) AS gs(num)

    -- 1-10 Hex choice
    UNION ALL
    SELECT 'ru',
           'wcc_mage_events_danger_details_o0110' || to_char(v.sort_order, 'FM00'),
           v.sort_order,
           (1.0::numeric / 12),
           'wcc_mage_events_danger_o0110',
           v.required_dlc,
           '<b>Порча</b>',
           v.ru_name,
           'На вас наложена ' || CASE WHEN v.ru_name = 'Теневая порча' THEN 'Теневая порча' ELSE 'порча "' || v.ru_name || '"' END || '.'
      FROM hex_vals v

    UNION ALL
    SELECT 'en',
           'wcc_mage_events_danger_details_o0110' || to_char(v.sort_order, 'FM00'),
           v.sort_order,
           (1.0::numeric / 12),
           'wcc_mage_events_danger_o0110',
           v.required_dlc,
           '<b>Hex</b>',
           v.en_name,
           'You are afflicted with ' || CASE WHEN v.en_name = 'The Hex of Shadows' THEN 'The Hex of Shadows' ELSE '"' || v.en_name || '"' END || '.'
      FROM hex_vals v

    -- 2-2 False accusation
    UNION ALL
    SELECT 'ru',
           'wcc_mage_events_danger_details_o0202' || to_char(v.num, 'FM00'),
           v.num,
           v.probability,
           'wcc_mage_events_danger_o0202',
           NULL,
           '<b>Ложное обвинение</b>',
           v.ru_name,
           'Вас ложно обвинили ' || v.ru_case || '.'
      FROM accusation_vals v

    UNION ALL
    SELECT 'en',
           'wcc_mage_events_danger_details_o0202' || to_char(v.num, 'FM00'),
           v.num,
           v.probability,
           'wcc_mage_events_danger_o0202',
           NULL,
           '<b>False Accusation</b>',
           v.en_name,
           'You were falsely accused of ' || lower(v.en_name) || '.'
      FROM accusation_vals v

    -- 2-7 Hunted
    UNION ALL
    SELECT 'ru',
           'wcc_mage_events_danger_details_o0207' || to_char(gs.num, 'FM00'),
           gs.num,
           (1.0::numeric / 6),
           'wcc_mage_events_danger_o0207',
           NULL,
           '<b>Цель охоты</b>',
           '',
           'За вами охотятся ' || (gs.num + 5)::text || CASE WHEN gs.num + 5 = 1 THEN ' охотник' WHEN gs.num + 5 BETWEEN 2 AND 4 THEN ' охотника' ELSE ' охотников' END || ' за головами.'
      FROM generate_series(1, 6) AS gs(num)

    UNION ALL
    SELECT 'en',
           'wcc_mage_events_danger_details_o0207' || to_char(gs.num, 'FM00'),
           gs.num,
           (1.0::numeric / 6),
           'wcc_mage_events_danger_o0207',
           NULL,
           '<b>Hunted</b>',
           '',
           'A group of ' || (gs.num + 5)::text || ' bounty hunters is looking for you.'
      FROM generate_series(1, 6) AS gs(num)

    -- 2-8 Enemy of the state
    UNION ALL
    SELECT 'ru',
           'wcc_mage_events_danger_details_o0208' || to_char(v.sort_order, 'FM00'),
           v.sort_order,
           (1.0::numeric / 23),
           'wcc_mage_events_danger_o0208',
           NULL,
           '<b>Враг государства</b>',
           '',
           'Ваши политические планы были раскрыты, и вас заклеймили врагом ' ||
           '(' || v.ru_group || ') ' || v.ru_name_gen || '. Ваш статус там теперь "Ненависть".'
      FROM region_vals v

    UNION ALL
    SELECT 'en',
           'wcc_mage_events_danger_details_o0208' || to_char(v.sort_order, 'FM00'),
           v.sort_order,
           (1.0::numeric / 23),
           'wcc_mage_events_danger_o0208',
           NULL,
           '<b>Enemy of the State</b>',
           '',
           'Your political schemes were exposed, and you were branded an enemy of ' ||
           '(' || v.en_group || ') ' || v.en_name || '. Your status there is now "Hated".'
      FROM region_vals v

    -- 3-1 Magical block by element
    UNION ALL
    SELECT 'ru',
           'wcc_mage_events_danger_details_o0301' || to_char(v.num, 'FM00'),
           v.num,
           0.25::numeric,
           'wcc_mage_events_danger_o0301',
           NULL,
           '<b>Магическая блокировка</b>',
           v.ru_name,
           'В своих исследованиях вы пренебрегали магией ' || lower(v.ru_name) || '. Штраф -2 при сотворении соответствующего заклинания.'
      FROM element_vals v

    UNION ALL
    SELECT 'en',
           'wcc_mage_events_danger_details_o0301' || to_char(v.num, 'FM00'),
           v.num,
           0.25::numeric,
           'wcc_mage_events_danger_o0301',
           NULL,
           '<b>Magical Block</b>',
           v.en_name,
           'In your studies you neglected ' || lower(v.en_name) || ' magic. You suffer a -2 penalty when casting spells of that element.'
      FROM element_vals v

    -- 3-2 Monster phobia
    UNION ALL
    SELECT 'ru',
           'wcc_mage_events_danger_details_o0302' || to_char(v.sort_order, 'FM00'),
           v.sort_order,
           (1.0::numeric / 65),
           'wcc_mage_events_danger_o0302',
           v.required_dlc,
           '<span style="color:' || v.type_color || ';"><b>' || v.ru_type || '</b></span>',
           v.ru_name,
           'Вы однажды чуть не умерли, когда изучали ' || v.ru_name || '. Теперь у вас есть фобия и штраф -2 к проверкам Храбрости перед ним. При первой встрече при провале броска Храбрости со СЛ15 будете Ошеломлены.'
      FROM monster_vals v

    UNION ALL
    SELECT 'en',
           'wcc_mage_events_danger_details_o0302' || to_char(v.sort_order, 'FM00'),
           v.sort_order,
           (1.0::numeric / 65),
           'wcc_mage_events_danger_o0302',
           v.required_dlc,
           '<span style="color:' || v.type_color || ';"><b>' || v.en_type || '</b></span>',
           v.en_name,
           'You once nearly died while studying ' || v.en_name || '. You now have a phobia of it and suffer a -2 penalty to Courage checks against it. The first time you meet one, a failed Courage check at DC 15 leaves you Staggered.'
      FROM monster_vals v

    -- 3-10 Minor mutation
    UNION ALL
    SELECT 'ru',
           'wcc_mage_events_danger_details_o0310' || to_char(v.sort_order, 'FM00'),
           v.sort_order,
           (1.0::numeric / 33),
           'wcc_mage_events_danger_o0310',
           v.required_dlc,
           CASE
             WHEN v.type_color IS NULL THEN v.ru_name
             ELSE '<span style="color:' || v.type_color || ';"><b>' || v.ru_name || '</b></span>'
           END,
           v.ru_mutation,
           'Попытки изучения мутагена из ' || v.ru_name || ' закончились провалом, а вы получили малую мутацию.'
      FROM mutation_vals v

    UNION ALL
    SELECT 'en',
           'wcc_mage_events_danger_details_o0310' || to_char(v.sort_order, 'FM00'),
           v.sort_order,
           (1.0::numeric / 33),
           'wcc_mage_events_danger_o0310',
           v.required_dlc,
           CASE
             WHEN v.type_color IS NULL THEN v.en_name
             ELSE '<span style="color:' || v.type_color || ';"><b>' || v.en_name || '</b></span>'
           END,
           v.en_mutation,
           'Your attempts to study a mutagen from ' || v.en_name || ' ended in failure, and you gained a minor mutation.'
      FROM mutation_vals v

    -- 4-3 Deemed dangerous in a region
    UNION ALL
    SELECT 'ru',
           'wcc_mage_events_danger_details_o0403' || to_char(v.sort_order, 'FM00'),
           v.sort_order,
           (1.0::numeric / 23),
           'wcc_mage_events_danger_o0403',
           NULL,
           '<b>Признан опасным</b>',
           '',
           'Что-то, что вы сделали, заклеймило вас как опасного для жителей ' ||
           '(' || v.ru_group || ') ' || v.ru_name_gen || '. Там вас разыскивают власти.'
      FROM region_vals v

    UNION ALL
    SELECT 'en',
           'wcc_mage_events_danger_details_o0403' || to_char(v.sort_order, 'FM00'),
           v.sort_order,
           (1.0::numeric / 23),
           'wcc_mage_events_danger_o0403',
           NULL,
           '<b>Deemed Dangerous</b>',
           '',
           'Something you did marked you as dangerous to the people of ' ||
           '(' || v.en_group || ') ' || v.en_name || '. The authorities want you there.'
      FROM region_vals v

    -- 4-10 Curse choice
    UNION ALL
    SELECT 'ru',
           'wcc_mage_events_danger_details_o0410' || to_char(v.sort_order, 'FM00'),
           v.sort_order,
           v.probability,
           'wcc_mage_events_danger_o0410',
           v.required_dlc,
           '<b>Проклятие</b>',
           '',
           CASE
             WHEN v.sort_order = 1 THEN 'Вы навлекли на себя проклятие чудовищности.'
             WHEN v.sort_order = 2 THEN 'Вы навлекли на себя проклятие призраков.'
             WHEN v.sort_order = 3 THEN 'Вы навлекли на себя проклятие заразы.'
             WHEN v.sort_order = 4 THEN 'Вы навлекли на себя проклятие странника.'
             WHEN v.sort_order = 5 THEN 'Вы навлекли на себя проклятие ликантропии.'
             ELSE 'Перейдите к уточнению кастомного проклятия.'
           END
      FROM curse_vals v

    UNION ALL
    SELECT 'en',
           'wcc_mage_events_danger_details_o0410' || to_char(v.sort_order, 'FM00'),
           v.sort_order,
           v.probability,
           'wcc_mage_events_danger_o0410',
           v.required_dlc,
           '<b>Curse</b>',
           '',
           CASE
             WHEN v.sort_order = 1 THEN 'You brought the Curse of Monstrosity upon yourself.'
             WHEN v.sort_order = 2 THEN 'You brought the Curse of Phantoms upon yourself.'
             WHEN v.sort_order = 3 THEN 'You brought the Curse of Pestilence upon yourself.'
             WHEN v.sort_order = 4 THEN 'You brought the Curse of the Wanderer upon yourself.'
             WHEN v.sort_order = 5 THEN 'You brought the Curse of Lycanthropy upon yourself.'
             ELSE 'Proceed to custom curse details.'
           END
      FROM curse_vals v
  )
, vals AS (
  SELECT
    lang,
    an_id,
    sort_order,
    probability,
    from_answer_id,
    required_dlc,
    '<td style="color: grey;">' ||
      CASE
        WHEN probability * 100 = trunc(probability * 100)
          THEN to_char(probability * 100, 'FM990')
        ELSE to_char(probability * 100, 'FM990.00')
      END || '%</td><td>' ||
      coalesce(col2, '') || '</td><td>' ||
      coalesce(col3, '') || '</td><td>' ||
      coalesce(col4, '') || '</td>' AS text
  FROM raw_data
)
, rules_vals AS (
  SELECT DISTINCT
         ck_id('witcher_cc.rules.' || vals.an_id || '_visible') AS ru_id,
         vals.an_id || '_visible' AS name,
         CASE
           WHEN vals.required_dlc IS NULL THEN jsonb_build_object(
             'and', jsonb_build_array(
               jsonb_build_object('==', jsonb_build_array(jsonb_build_object('var', 'answers.lastAnswer.questionId'), 'wcc_mage_events_danger')),
               jsonb_build_object('in', jsonb_build_array(vals.from_answer_id, jsonb_build_object('var', 'answers.lastAnswer.answerIds')))
             )
           )
           ELSE jsonb_build_object(
             'and', jsonb_build_array(
               jsonb_build_object('==', jsonb_build_array(jsonb_build_object('var', 'answers.lastAnswer.questionId'), 'wcc_mage_events_danger')),
               jsonb_build_object('in', jsonb_build_array(vals.from_answer_id, jsonb_build_object('var', 'answers.lastAnswer.answerIds'))),
               jsonb_build_object('in', jsonb_build_array(vals.required_dlc, jsonb_build_object('var', 'dlcs')))
             )
           )
         END AS body
    FROM vals
   WHERE vals.lang = 'ru'
)
, ins_rules AS (
  INSERT INTO rules (ru_id, name, body)
  SELECT ru_id, name, body
    FROM rules_vals
  ON CONFLICT (ru_id) DO UPDATE
  SET name = EXCLUDED.name,
      body = EXCLUDED.body
)
, ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id('witcher_cc.' || vals.an_id || '.answer_options.label') AS id
       , 'answer_options', 'label', vals.lang, vals.text
    FROM vals
  ON CONFLICT (id, lang) DO UPDATE
  SET text = EXCLUDED.text
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT vals.an_id
     , 'witcher_cc'
     , 'wcc_mage_events_danger_details'
     , ck_id('witcher_cc.' || vals.an_id || '.answer_options.label')
     , vals.sort_order
     , ck_id('witcher_cc.rules.' || vals.an_id || '_visible')
     , jsonb_build_object('probability', vals.probability)
  FROM vals
 WHERE vals.lang = 'ru'
ON CONFLICT (an_id) DO UPDATE
SET label = EXCLUDED.label,
    sort_order = EXCLUDED.sort_order,
    visible_ru_ru_id = EXCLUDED.visible_ru_ru_id,
    metadata = EXCLUDED.metadata;
