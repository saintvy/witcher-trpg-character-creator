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

    -- 3-9 Lost a sense
    UNION ALL
    SELECT 'ru',
           'wcc_mage_events_danger_details_o0309' || to_char(v.num, 'FM00'),
           v.num,
           (1.0::numeric / 3),
           'wcc_mage_events_danger_o0309',
           NULL,
           '<b>Потеря чувств</b>',
           v.ru_name,
           'Из-за потери ' || lower(v.ru_gen) || ' вы имеете штраф -2 при проверке навыков, использующих это чувство.'
      FROM (VALUES
        (1, 'Вкус', 'вкуса'),
        (2, 'Обоняние', 'обоняния'),
        (3, 'Осязание', 'осязания')
      ) AS v(num, ru_name, ru_gen)

    UNION ALL
    SELECT 'en',
           'wcc_mage_events_danger_details_o0309' || to_char(v.num, 'FM00'),
           v.num,
           (1.0::numeric / 3),
           'wcc_mage_events_danger_o0309',
           NULL,
           '<b>Lost a Sense</b>',
           v.en_name,
           'Because of the loss of ' || lower(v.en_name) || ', you suffer a -2 penalty on skill checks that rely on that sense.'
      FROM (VALUES
        (1, 'Taste'),
        (2, 'Smell'),
        (3, 'Touch')
      ) AS v(num, en_name)

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

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_mage_events_danger_details' AS qu_id
  )
, region_vals AS (
    SELECT *
      FROM (VALUES
        (1,  'Каэдвен', 'Северные королевства', 'Kaedwen', 'Northern Kingdoms'),
        (2,  'Ковир и Повисс', 'Северные королевства', 'Kovir and Poviss', 'Northern Kingdoms'),
        (3,  'Редания', 'Северные королевства', 'Redania', 'Northern Kingdoms'),
        (4,  'Аэдирн', 'Северные королевства', 'Aedirn', 'Northern Kingdoms'),
        (5,  'Лирия и Ривия', 'Северные королевства', 'Lyria and Rivia', 'Northern Kingdoms'),
        (6,  'Темерия', 'Северные королевства', 'Temeria', 'Northern Kingdoms'),
        (7,  'Цидарис', 'Северные королевства', 'Cidaris', 'Northern Kingdoms'),
        (8,  'Керак', 'Северные королевства', 'Kerack', 'Northern Kingdoms'),
        (9,  'Вердэн', 'Северные королевства', 'Verden', 'Northern Kingdoms'),
        (10, 'Скеллиге', 'Северные королевства', 'Skellige', 'Northern Kingdoms'),
        (11, 'Цинтра', 'Нильфгаард', 'Cintra', 'Nilfgaard'),
        (12, 'Ангрен', 'Нильфгаард', 'Angren', 'Nilfgaard'),
        (13, 'Назаир', 'Нильфгаард', 'Nazair', 'Nilfgaard'),
        (14, 'Меттина', 'Нильфгаард', 'Mettina', 'Nilfgaard'),
        (15, 'Туссент', 'Нильфгаард', 'Toussaint', 'Nilfgaard'),
        (16, 'Маг Турга', 'Нильфгаард', 'Mag Turga', 'Nilfgaard'),
        (17, 'Гесо', 'Нильфгаард', 'Gheso', 'Nilfgaard'),
        (18, 'Эббинг', 'Нильфгаард', 'Ebbing', 'Nilfgaard'),
        (19, 'Мехт', 'Нильфгаард', 'Maecht', 'Nilfgaard'),
        (20, 'Этолия', 'Нильфгаард', 'Etolia', 'Nilfgaard'),
        (21, 'Геммера', 'Нильфгаард', 'Gemmera', 'Nilfgaard'),
        (22, 'Доль Блатанна', 'Земли старших народов', 'Dol Blathanna', 'Elderlands'),
        (23, 'Махакам', 'Земли старших народов', 'Mahakam', 'Elderlands')
      ) AS v(sort_order, ru_name, ru_group, en_name, en_group)
)
, addiction_vals AS (
    SELECT *
      FROM (VALUES
        (1, 'Алкоголь', 'Alcohol'),
        (2, 'Табак', 'Tobacco'),
        (3, 'Фисштех', 'Fisstech'),
        (4, 'Азартные игры', 'Gambling'),
        (5, 'Клептомания', 'Kleptomania'),
        (6, 'Похоть', 'Lust'),
        (7, 'Обжорство', 'Gluttony'),
        (8, 'Адреналиновая зависимость', 'Adrenaline addiction'),
        (10, 'Другое', 'Other')
      ) AS v(num, ru_name, en_name)
)
, accusation_vals AS (
    SELECT *
      FROM (VALUES
        (1, 'Кража', 'Theft'),
        (2, 'Трусость', 'Cowardice'),
        (3, 'Измена', 'Treason'),
        (4, 'Изнасилование', 'Rape'),
        (5, 'Убийство', 'Murder'),
        (6, 'Мошенничество', 'Fraud'),
        (7, 'Запретная магия', 'Forbidden Magic'),
        (8, 'Уклонение от уплаты налогов', 'Tax Evasion'),
        (9, 'Неэтичные действия', 'Unethical Practices')
      ) AS v(num, ru_name, en_name)
)
, element_vals AS (
    SELECT *
      FROM (VALUES
        (1, 'Вода', 'Water'),
        (2, 'Земля', 'Earth'),
        (3, 'Огонь', 'Fire'),
        (4, 'Воздух', 'Air')
      ) AS v(num, ru_name, en_name)
)
, curse_vals AS (
    SELECT *
      FROM (VALUES
        (1, 'Проклятие чудовищности', 'Curse of Monstrosity', 'Интенсивность: Средняя', 'Intensity: Moderate'),
        (2, 'Проклятие призраков', 'Curse of Phantoms', 'Интенсивность: Средняя', 'Intensity: Moderate'),
        (3, 'Проклятие заразы', 'Curse of Pestilence', 'Интенсивность: Высокая', 'Intensity: High'),
        (4, 'Проклятие странника', 'Curse of the Wanderer', 'Интенсивность: Высокая', 'Intensity: High'),
        (5, 'Проклятие ликантропии', 'Curse of Lycanthropy', 'Интенсивность: Высокая', 'Intensity: High'),
        (6, 'Другое проклятие', 'Other Curse', 'Кастомное проклятие', 'Custom curse')
      ) AS v(num, ru_name, en_name, ru_detail, en_detail)
)
, monster_vals AS (
    SELECT *
      FROM (VALUES
        (1,  'Вампиры', 'Alp', 'Vampires', 'Alp'),
        (2,  'Вампиры', 'Bruxa', 'Vampires', 'Bruxa'),
        (3,  'Вампиры', 'Garkain', 'Vampires', 'Garkain'),
        (4,  'Вампиры', 'Katakan', 'Vampires', 'Katakan'),
        (5,  'Вампиры', 'On Shadow Wings', 'Vampires', 'On Shadow Wings'),
        (6,  'Вампиры', 'Plumard', 'Vampires', 'Plumard'),
        (7,  'Гибриды', 'Гарпия', 'Hybrids', 'Harpy'),
        (8,  'Гибриды', 'Глаз охотника', 'Hybrids', 'With Hunting Eyes'),
        (9,  'Гибриды', 'Грифон', 'Hybrids', 'Griffin'),
        (10, 'Гибриды', 'Мантикора', 'Hybrids', 'Manticore'),
        (11, 'Гибриды', 'Сирена', 'Hybrids', 'Siren'),
        (12, 'Гибриды', 'Суккуб', 'Hybrids', 'Succubus'),
        (13, 'Дракониды', 'Виверна', 'Draconids', 'Wyvern'),
        (14, 'Дракониды', 'Куролиск', 'Draconids', 'Cockatrice'),
        (15, 'Дракониды', 'Огонь с небес', 'Draconids', 'Fire From The Sky'),
        (16, 'Дракониды', 'Осгазир', 'Draconids', 'Slyzard'),
        (17, 'Дракониды', 'Феникс', 'Draconids', 'Phoenix'),
        (18, 'Духи', 'Амальгама трупов', 'Specters', 'Corpse Amalgam'),
        (19, 'Духи', 'Варгест', 'Specters', 'Barghest'),
        (20, 'Духи', 'Демон Рогатый', 'Specters', 'Bes'),
        (21, 'Духи', 'Касглидд', 'Specters', 'Casglydd'),
        (22, 'Духи', 'Мари Луид', 'Specters', 'Mari Lwyd'),
        (23, 'Духи', 'Песта', 'Specters', 'Pesta'),
        (24, 'Духи', 'Покаянник', 'Specters', 'Penitent'),
        (25, 'Духи', 'Полуденница', 'Specters', 'Noon Wraith'),
        (26, 'Духи', 'Призрак', 'Specters', 'Wraith'),
        (27, 'Духи', 'Среди мертвых тел', 'Specters', 'Among Corpses'),
        (28, 'Духи', 'Хим', 'Specters', 'Hym'),
        (29, 'Духи стихий', 'Голем', 'Elementa', 'Golem'),
        (30, 'Духи стихий', 'Живая броня', 'Elementa', 'Living Armor'),
        (31, 'Духи стихий', 'Пожар', 'Elementa', 'Wildfire'),
        (32, 'Духи стихий', 'Элементаль земли', 'Elementa', 'Earth Elemental'),
        (33, 'Духи стихий', 'Элементаль льда', 'Elementa', 'Ice Elemental'),
        (34, 'Духи стихий', 'Элементаль огня', 'Elementa', 'Fire Elemental'),
        (35, 'Инсектоиды', 'Барбегази', 'Insectoids', 'Barbegazi'),
        (36, 'Инсектоиды', 'Главоглаз', 'Insectoids', 'Arachas'),
        (37, 'Инсектоиды', 'Жагница', 'Insectoids', 'Glustyworp'),
        (38, 'Инсектоиды', 'Из-под земли', 'Insectoids', 'Scurrying From Tunnels'),
        (39, 'Инсектоиды', 'Сколопендроморф', 'Insectoids', 'Giant Centipede'),
        (40, 'Инсектоиды', 'Химера', 'Insectoids', 'Frigher'),
        (41, 'Инсектоиды', 'Эндриага', 'Insectoids', 'Endrega'),
        (42, 'Огры', 'Накер', 'Ogroids', 'Nekker'),
        (43, 'Огры', 'Нежеланный гость', 'Ogroids', 'Unwanted Hunter'),
        (44, 'Огры', 'Скальный тролль', 'Ogroids', 'Rock Troll'),
        (45, 'Огры', 'Стукач', 'Ogroids', 'Knockers'),
        (46, 'Огры', 'Тролль', 'Ogroids', 'Troll'),
        (47, 'Огры', 'Циклоп', 'Ogroids', 'Cyclops'),
        (48, 'Проклятые', 'Археспора', 'Cursed Ones', 'Archespore'),
        (49, 'Проклятые', 'Вендиго', 'Cursed Ones', 'Vendigo'),
        (50, 'Проклятые', 'Волколак', 'Cursed Ones', 'Werewolf'),
        (51, 'Проклятые', 'Игоша', 'Cursed Ones', 'Botchling'),
        (52, 'Проклятые', 'Котолак', 'Cursed Ones', 'Werecat'),
        (53, 'Проклятые', 'Сирота', 'Cursed Ones', 'The Orphan'),
        (54, 'Реликты', 'Бес', 'Relicts', 'Fiend'),
        (55, 'Реликты', 'Леший', 'Relicts', 'Leshy'),
        (56, 'Реликты', 'Мелкая пакость', 'Relicts', 'Undermining'),
        (57, 'Реликты', 'Прибожек', 'Relicts', 'Godling'),
        (58, 'Реликты', 'Шарлей', 'Relicts', 'Shalmaar'),
        (59, 'Трупоеды', 'В туманной мгле', 'Necrophages', 'In Cirrus Gloom'),
        (60, 'Трупоеды', 'Гнилец', 'Necrophages', 'Rotfiend'),
        (61, 'Трупоеды', 'Гуль', 'Necrophages', 'Ghoul'),
        (62, 'Трупоеды', 'Кладбищенская баба', 'Necrophages', 'Grave Hag'),
        (63, 'Трупоеды', 'Туманник', 'Necrophages', 'Foglet'),
        (64, 'Трупоеды', 'Утковол', 'Necrophages', 'Bullvore'),
        (65, 'Трупоеды', 'Утопец', 'Necrophages', 'Drowner')
      ) AS v(sort_order, ru_type, ru_name, en_type, en_name)
)
, mutation_vals AS (
    SELECT *
      FROM (VALUES
        (1, 'Альп', 'Тёмно-красные вены по всему телу', 'Alp', 'A patchwork of dark red veins under your skin'),
        (2, 'Гаркон', 'Мягкие наросты на голове', 'Garkain', 'Fleshy growths on the head'),
        (3, 'Катакан', 'Долговязость', 'Katakan', 'Gangly proportions'),
        (4, 'Брукса', 'Полупрозрачная кожа и шипящий голос', 'Bruxa', 'Semi-translucent skin & a hissing voice'),
        (5, 'Грифон', 'Прорастание перьев', 'Griffin', 'Feather growth'),
        (6, 'Мантикора', 'Рожки и кошачьи черты лица', 'Manticore', 'Small horns & feline features'),
        (7, 'Суккуб', 'Рожки и хвост', 'Succubus', 'Small horns and a tail'),
        (8, 'Виверна', 'Огрубение кожи', 'Wyvern', 'Rough skin'),
        (9, 'Куролиск', 'Пучки зелёных перьев', 'Cockatrice', 'Tufts of green feathers'),
        (10, 'Феникс', 'Пучки серых перьев и свечение изнутри', 'Phoenix', 'Tufts of grey feathers & an internal glow'),
        (11, 'Песта', 'Болезненно-бледная кожа и впалые щёки', 'Pesta', 'Sickly pale skin & gaunt features'),
        (12, 'Покаянник', 'Светящиеся белые отметины', 'Penitent', 'Glowing white markings'),
        (13, 'Полуденница', 'Сухая, туго обтягивающая кожа', 'Noon Wraith', 'Dry, taut skin'),
        (14, 'Голем', 'Твёрдые наросты на теле', 'Golem', 'Hard protrusions'),
        (15, 'Элементаль Земли', 'Каменные наросты по всему телу', 'Earth Elemental', 'Rocky growths along your body'),
        (16, 'Элементаль Льда', 'Вечно холодная на ощупь кожа', 'Ice Elemental', 'Skin cold to the touch'),
        (17, 'Элементаль Огня', 'Струйки пламени изо рта', 'Fire Elemental', 'Small spouts of flame from your mouth'),
        (18, 'Главоглаз', 'Зелёная кровь и другие жидкости', 'Arachas', 'Green bodily fluids'),
        (19, 'Жагница', 'Небольшие участки хитина на теле', 'Glustyworp', 'Small patches of chitin'),
        (20, 'Химера', 'Фасеточные глаза и участки хитина', 'Frigher', 'Multi-faceted eyes & patches of chitin'),
        (21, 'Накер', 'Облысение и серая кожа', 'Nekker', 'Baldness & grey skin'),
        (22, 'Скальный тролль', 'Сгорбленность', 'Rock Troll', 'Hunched posture'),
        (23, 'Тролль', 'Жёсткая голубоватая кожа', 'Troll', 'Blue-ish leathery skin'),
        (24, 'Вендиго', 'Клочки меха и болезненно-серая кожа', 'Vendigo', 'Patchy fur & sickly grey skin'),
        (25, 'Волколак', 'Рост волос по всему телу', 'Werewolf', 'Rapid hair growth'),
        (26, 'Игоша', 'Волчья пасть и красные белки глаз', 'Botchling', 'Wolf''s maw & red eye whites'),
        (27, 'Котолак', 'Кошачьи глаза и усиленный рост волос', 'Werecat', 'Cat''s eyes and increased hair growth'),
        (28, 'Бес', 'Небольшие рожки', 'Fiend', 'Small antlers'),
        (29, 'Леший', 'На теле вырастают побеги и листья', 'Leshy', 'Plants growing on the body'),
        (30, 'Шарлей', 'Участки твёрдой, как камень, кожи', 'Shalmaar', 'Patches of thick rock-textured skin'),
        (31, 'Утковол', 'Твёрдые наросты по всему телу', 'Bullvore', 'Hard growths all over the body'),
        (32, 'Медведь', 'Усиленный рост волос на теле', 'Bear', 'Prolific fur growth')
      ) AS v(sort_order, ru_name, ru_mutation, en_name, en_mutation)
)
, event_desc_vals(lang, group_id, option_id, text) AS (
    SELECT 'ru', 101, gs.num, 'Долг: ' || (gs.num * 100)::text || ' крон.'
      FROM generate_series(1, 10) AS gs(num)
    UNION ALL
    SELECT 'en', 101, gs.num, 'Debt: ' || (gs.num * 100)::text || ' crowns.'
      FROM generate_series(1, 10) AS gs(num)

    UNION ALL
    SELECT 'ru', 102, v.num, 'Зависимость: ' || v.ru_name || '.'
      FROM addiction_vals v
    UNION ALL
    SELECT 'en', 102, v.num, 'Addiction: ' || v.en_name || '.'
      FROM addiction_vals v

    UNION ALL
    SELECT 'ru', 104, v.sort_order, 'Разгневанные горожане: (' || v.ru_group || ') ' || v.ru_name || '.'
      FROM region_vals v
    UNION ALL
    SELECT 'en', 104, v.sort_order, 'Angered City Folk: (' || v.en_group || ') ' || v.en_name || '.'
      FROM region_vals v

    UNION ALL
    VALUES
      ('ru', 105, 1, 'Несчастный случай: Изуродованы.'),
      ('en', 105, 1, 'Accident: Disfigured.'),
      ('ru', 105, 4, 'Несчастный случай: Ужасные кошмары.'),
      ('en', 105, 4, 'Accident: Horrible nightmares.')

    UNION ALL
    SELECT 'ru', 106, gs.num,
           'Заключение в тюрьму: ' || gs.num::text || CASE WHEN gs.num = 1 THEN ' год.' WHEN gs.num BETWEEN 2 AND 4 THEN ' года.' ELSE ' лет.' END
      FROM generate_series(1, 10) AS gs(num)
    UNION ALL
    SELECT 'en', 106, gs.num,
           'Imprisonment: ' || gs.num::text || CASE WHEN gs.num = 1 THEN ' year.' ELSE ' years.' END
      FROM generate_series(1, 10) AS gs(num)

    UNION ALL
    SELECT 'ru', 110, v.num, 'Проклятие: ' || v.ru_name || ' (' || v.ru_detail || ').'
      FROM curse_vals v
    UNION ALL
    SELECT 'en', 110, v.num, 'Curse: ' || v.en_name || ' (' || v.en_detail || ').'
      FROM curse_vals v

    UNION ALL
    SELECT 'ru', 202, v.num, 'Ложное обвинение: ' || v.ru_name || '.'
      FROM accusation_vals v
    UNION ALL
    SELECT 'en', 202, v.num, 'False Accusation: ' || v.en_name || '.'
      FROM accusation_vals v

    UNION ALL
    SELECT 'ru', 207, gs.num, 'Цель охоты: ' || (gs.num + 5)::text || CASE WHEN gs.num + 5 BETWEEN 2 AND 4 THEN ' охотника.' ELSE ' охотников.' END
      FROM generate_series(1, 6) AS gs(num)
    UNION ALL
    SELECT 'en', 207, gs.num, 'Hunted: ' || (gs.num + 5)::text || ' bounty hunters.'
      FROM generate_series(1, 6) AS gs(num)

    UNION ALL
    SELECT 'ru', 208, v.sort_order, 'Враг государства: (' || v.ru_group || ') ' || v.ru_name || '.'
      FROM region_vals v
    UNION ALL
    SELECT 'en', 208, v.sort_order, 'Enemy of the State: (' || v.en_group || ') ' || v.en_name || '.'
      FROM region_vals v

    UNION ALL
    SELECT 'ru', 301, v.num, 'Магическая блокировка: ' || v.ru_name || ', штраф -2 к Сотворению заклинаний.'
      FROM element_vals v
    UNION ALL
    SELECT 'en', 301, v.num, 'Magical Block: ' || v.en_name || ', -2 to Spell Casting.'
      FROM element_vals v

    UNION ALL
    SELECT 'ru', 302, v.sort_order, 'Встреча с монстром: ' || v.ru_type || ' - ' || v.ru_name || '.'
      FROM monster_vals v
    UNION ALL
    SELECT 'en', 302, v.sort_order, 'Monster Encounter: ' || v.en_type || ' - ' || v.en_name || '.'
      FROM monster_vals v

    UNION ALL
    SELECT 'ru', 309, 1, 'Потеря чувств: вкус.'
    UNION ALL
    SELECT 'en', 309, 1, 'Lost a Sense: taste.'
    UNION ALL
    SELECT 'ru', 309, 2, 'Потеря чувств: обоняние.'
    UNION ALL
    SELECT 'en', 309, 2, 'Lost a Sense: smell.'
    UNION ALL
    SELECT 'ru', 309, 3, 'Потеря чувств: осязание.'
    UNION ALL
    SELECT 'en', 309, 3, 'Lost a Sense: touch.'

    UNION ALL
    SELECT 'ru', 310, v.sort_order, 'Малая мутация (' || v.ru_name || ').'
      FROM mutation_vals v
    UNION ALL
    SELECT 'en', 310, v.sort_order, 'Minor Mutation (' || v.en_name || ').'
      FROM mutation_vals v

    UNION ALL
    SELECT 'ru', 403, v.sort_order, 'Признан опасным: (' || v.ru_group || ') ' || v.ru_name || '.'
      FROM region_vals v
    UNION ALL
    SELECT 'en', 403, v.sort_order, 'Deemed Dangerous: (' || v.en_group || ') ' || v.en_name || '.'
      FROM region_vals v

    UNION ALL
    SELECT 'ru', 410, v.num, 'Проклятие: ' || v.ru_name || '.'
      FROM curse_vals v
    UNION ALL
    SELECT 'en', 410, v.num, 'Cursed: ' || v.en_name || '.'
      FROM curse_vals v
)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(event_desc_vals.group_id, 'FM0000') || to_char(event_desc_vals.option_id, 'FM00') ||'.event_desc')
     , 'character'
     , 'event_desc'
     , event_desc_vals.lang
     , event_desc_vals.text
  FROM event_desc_vals
  CROSS JOIN meta
ON CONFLICT (id, lang) DO UPDATE
SET text = EXCLUDED.text;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_mage_events_danger_details' AS qu_id
  )
, event_effects(group_id, option_id) AS (
    VALUES
      (101, 1), (101, 2), (101, 3), (101, 4), (101, 5), (101, 6), (101, 7), (101, 8), (101, 9), (101,10),
      (102, 1), (102, 2), (102, 3), (102, 4), (102, 5), (102, 6), (102, 7), (102, 8), (102,10),
      (104, 1), (104, 2), (104, 3), (104, 4), (104, 5), (104, 6), (104, 7), (104, 8), (104, 9), (104,10),
      (104,11), (104,12), (104,13), (104,14), (104,15), (104,16), (104,17), (104,18), (104,19), (104,20),
      (104,21), (104,22), (104,23),
      (105, 1), (105, 4),
      (106, 1), (106, 2), (106, 3), (106, 4), (106, 5), (106, 6), (106, 7), (106, 8), (106, 9), (106,10),
      (110, 1), (110, 2), (110, 3), (110, 4), (110, 5), (110, 6),
      (202, 1), (202, 2), (202, 3), (202, 4), (202, 5), (202, 6), (202, 7), (202, 8), (202, 9),
      (207, 1), (207, 2), (207, 3), (207, 4), (207, 5), (207, 6),
      (208, 1), (208, 2), (208, 3), (208, 4), (208, 5), (208, 6), (208, 7), (208, 8), (208, 9), (208,10),
      (208,11), (208,12), (208,13), (208,14), (208,15), (208,16), (208,17), (208,18), (208,19), (208,20),
      (208,21), (208,22), (208,23),
      (301, 1), (301, 2), (301, 3), (301, 4),
      (302, 1), (302, 2), (302, 3), (302, 4), (302, 5), (302, 6), (302, 7), (302, 8), (302, 9), (302,10),
      (302,11), (302,12), (302,13), (302,14), (302,15), (302,16), (302,17), (302,18), (302,19), (302,20),
      (302,21), (302,22), (302,23), (302,24), (302,25), (302,26), (302,27), (302,28), (302,29), (302,30),
      (302,31), (302,32), (302,33), (302,34), (302,35), (302,36), (302,37), (302,38), (302,39), (302,40),
      (302,41), (302,42), (302,43), (302,44), (302,45), (302,46), (302,47), (302,48), (302,49), (302,50),
      (302,51), (302,52), (302,53), (302,54), (302,55), (302,56), (302,57), (302,58), (302,59), (302,60),
      (302,61), (302,62), (302,63), (302,64), (302,65),
      (309, 1), (309, 2), (309, 3),
      (310, 1), (310, 2), (310, 3), (310, 4), (310, 5), (310, 6), (310, 7), (310, 8), (310, 9), (310,10),
      (310,11), (310,12), (310,13), (310,14), (310,15), (310,16), (310,17), (310,18), (310,19), (310,20),
      (310,21), (310,22), (310,23), (310,24), (310,25), (310,26), (310,27), (310,28), (310,29), (310,30),
      (310,31), (310,32),
      (403, 1), (403, 2), (403, 3), (403, 4), (403, 5), (403, 6), (403, 7), (403, 8), (403, 9), (403,10),
      (403,11), (403,12), (403,13), (403,14), (403,15), (403,16), (403,17), (403,18), (403,19), (403,20),
      (403,21), (403,22), (403,23),
      (410, 1), (410, 2), (410, 3), (410, 4), (410, 5), (410, 6)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character'
     , meta.qu_id || '_o' || to_char(event_effects.group_id, 'FM0000') || to_char(event_effects.option_id, 'FM00')
     , jsonb_build_object(
         'add',
         jsonb_build_array(
           jsonb_build_object('var', 'characterRaw.lore.lifeEvents'),
           jsonb_build_object(
             'timePeriod',
             jsonb_build_object(
               'jsonlogic_expression',
               jsonb_build_object(
                 'cat',
                 jsonb_build_array(
                   jsonb_build_object('var', 'counters.lifeEventsCounter'),
                   '-',
                   jsonb_build_object(
                     '+',
                     jsonb_build_array(
                       jsonb_build_object('var', 'counters.lifeEventsCounter'),
                       10
                     )
                   )
                 )
               )
             ),
             'eventType',
             jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.wcc_mage_events_danger.life_event_type.danger')::text),
             'description',
             jsonb_build_object(
               'i18n_uuid',
               ck_id(meta.su_su_id ||'.'|| meta.qu_id || '_o' || to_char(event_effects.group_id, 'FM0000') || to_char(event_effects.option_id, 'FM00') ||'.event_desc')::text
             )
           )
         )
       )
  FROM event_effects
 CROSS JOIN meta;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_mage_events_danger_details' AS qu_id
  )
, perk_desc_vals(key_suffix, lang, text) AS (
    VALUES
      ('o030901.disease_name', 'ru', 'Потеря чувств (Вкус)'),
      ('o030901.disease_name', 'en', 'Lost a Sense (Taste)'),
      ('o030901.disease_desc', 'ru', 'Из-за потери вкуса вы имеете штраф -2 при проверке навыков, использующих это чувство.'),
      ('o030901.disease_desc', 'en', 'Because of the loss of taste, you suffer a -2 penalty on skill checks that rely on that sense.'),
      ('o030902.disease_name', 'ru', 'Потеря чувств (Обоняние)'),
      ('o030902.disease_name', 'en', 'Lost a Sense (Smell)'),
      ('o030902.disease_desc', 'ru', 'Из-за потери обоняния вы имеете штраф -2 при проверке навыков, использующих это чувство.'),
      ('o030902.disease_desc', 'en', 'Because of the loss of smell, you suffer a -2 penalty on skill checks that rely on that sense.'),
      ('o030903.disease_name', 'ru', 'Потеря чувств (Осязание)'),
      ('o030903.disease_name', 'en', 'Lost a Sense (Touch)'),
      ('o030903.disease_desc', 'ru', 'Из-за потери осязания вы имеете штраф -2 при проверке навыков, использующих это чувство.'),
      ('o030903.disease_desc', 'en', 'Because of the loss of touch, you suffer a -2 penalty on skill checks that rely on that sense.')
)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| perk_desc_vals.key_suffix)
     , 'character'
     , 'disease'
     , perk_desc_vals.lang
     , perk_desc_vals.text
  FROM perk_desc_vals
 CROSS JOIN meta
ON CONFLICT (id, lang) DO UPDATE
SET text = EXCLUDED.text;

WITH
  meta AS (
    SELECT 'witcher_cc' AS su_su_id
         , 'wcc_mage_events_danger_details' AS qu_id
  )
, mutation_vals AS (
    SELECT *
      FROM (VALUES
        (1, 'Альп', 'Тёмно-красные вены по всему телу', 'Alp', 'A patchwork of dark red veins under your skin'),
        (2, 'Гаркон', 'Мягкие наросты на голове', 'Garkain', 'Fleshy growths on the head'),
        (3, 'Катакан', 'Долговязость', 'Katakan', 'Gangly proportions'),
        (4, 'Брукса', 'Полупрозрачная кожа и шипящий голос', 'Bruxa', 'Semi-translucent skin & a hissing voice'),
        (5, 'Грифон', 'Прорастание перьев', 'Griffin', 'Feather growth'),
        (6, 'Мантикора', 'Рожки и кошачьи черты лица', 'Manticore', 'Small horns & feline features'),
        (7, 'Суккуб', 'Рожки и хвост', 'Succubus', 'Small horns and a tail'),
        (8, 'Виверна', 'Огрубение кожи', 'Wyvern', 'Rough skin'),
        (9, 'Куролиск', 'Пучки зелёных перьев', 'Cockatrice', 'Tufts of green feathers'),
        (10, 'Феникс', 'Пучки серых перьев и свечение изнутри', 'Phoenix', 'Tufts of grey feathers & an internal glow'),
        (11, 'Песта', 'Болезненно-бледная кожа и впалые щёки', 'Pesta', 'Sickly pale skin & gaunt features'),
        (12, 'Покаянник', 'Светящиеся белые отметины', 'Penitent', 'Glowing white markings'),
        (13, 'Полуденница', 'Сухая, туго обтягивающая кожа', 'Noon Wraith', 'Dry, taut skin'),
        (14, 'Голем', 'Твёрдые наросты на теле', 'Golem', 'Hard protrusions'),
        (15, 'Элементаль Земли', 'Каменные наросты по всему телу', 'Earth Elemental', 'Rocky growths along your body'),
        (16, 'Элементаль Льда', 'Вечно холодная на ощупь кожа', 'Ice Elemental', 'Skin cold to the touch'),
        (17, 'Элементаль Огня', 'Струйки пламени изо рта', 'Fire Elemental', 'Small spouts of flame from your mouth'),
        (18, 'Главоглаз', 'Зелёная кровь и другие жидкости', 'Arachas', 'Green bodily fluids'),
        (19, 'Жагница', 'Небольшие участки хитина на теле', 'Glustyworp', 'Small patches of chitin'),
        (20, 'Химера', 'Фасеточные глаза и участки хитина', 'Frigher', 'Multi-faceted eyes & patches of chitin'),
        (21, 'Накер', 'Облысение и серая кожа', 'Nekker', 'Baldness & grey skin'),
        (22, 'Скальный тролль', 'Сгорбленность', 'Rock Troll', 'Hunched posture'),
        (23, 'Тролль', 'Жёсткая голубоватая кожа', 'Troll', 'Blue-ish leathery skin'),
        (24, 'Вендиго', 'Клочки меха и болезненно-серая кожа', 'Vendigo', 'Patchy fur & sickly grey skin'),
        (25, 'Волколак', 'Рост волос по всему телу', 'Werewolf', 'Rapid hair growth'),
        (26, 'Игоша', 'Волчья пасть и красные белки глаз', 'Botchling', 'Wolf''s maw & red eye whites'),
        (27, 'Котолак', 'Кошачьи глаза и усиленный рост волос', 'Werecat', 'Cat''s eyes and increased hair growth'),
        (28, 'Бес', 'Небольшие рожки', 'Fiend', 'Small antlers'),
        (29, 'Леший', 'На теле вырастают побеги и листья', 'Leshy', 'Plants growing on the body'),
        (30, 'Шарлей', 'Участки твёрдой, как камень, кожи', 'Shalmaar', 'Patches of thick rock-textured skin'),
        (31, 'Утковол', 'Твёрдые наросты по всему телу', 'Bullvore', 'Hard growths all over the body'),
        (32, 'Медведь', 'Усиленный рост волос на теле', 'Bear', 'Prolific fur growth')
      ) AS v(sort_order, ru_name, ru_mutation, en_name, en_mutation)
)
, mutation_perk_vals AS (
    SELECT sort_order,
           'o0310' || to_char(sort_order, 'FM00') || '.disease_name' AS name_key_suffix,
           'o0310' || to_char(sort_order, 'FM00') || '.disease_desc' AS desc_key_suffix,
           'Малая мутация (' || ru_name || ')' AS ru_name_text,
           'Minor Mutation (' || en_name || ')' AS en_name_text,
           ru_mutation || '.' AS ru_desc_text,
           en_mutation || '.' AS en_desc_text
      FROM mutation_vals
)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| key_vals.key_suffix)
     , 'character'
     , 'disease'
     , key_vals.lang
     , key_vals.text
  FROM mutation_perk_vals
 CROSS JOIN meta
 CROSS JOIN LATERAL (
   VALUES
     (mutation_perk_vals.name_key_suffix, 'ru', mutation_perk_vals.ru_name_text),
     (mutation_perk_vals.name_key_suffix, 'en', mutation_perk_vals.en_name_text),
     (mutation_perk_vals.desc_key_suffix, 'ru', mutation_perk_vals.ru_desc_text),
     (mutation_perk_vals.desc_key_suffix, 'en', mutation_perk_vals.en_desc_text)
 ) AS key_vals(key_suffix, lang, text)
ON CONFLICT (id, lang) DO UPDATE
SET text = EXCLUDED.text;

WITH meta AS (
  SELECT 'witcher_cc' AS su_su_id
       , 'wcc_mage_events_danger_details' AS qu_id
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character'
     , meta.qu_id || '_o010501'
     , jsonb_build_object('set_all_social_status_feared', true)
  FROM meta
UNION ALL
SELECT 'character'
     , meta.qu_id || '_o0309' || to_char(v.num, 'FM00')
     , jsonb_build_object(
         'add_unique',
         jsonb_build_array(
           jsonb_build_object('var', 'characterRaw.lore.diseases_and_curses'),
           jsonb_build_object(
             'name', jsonb_build_object(
               'i18n_uuid',
               ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.o0309' || to_char(v.num, 'FM00') || '.disease_name')::text
             ),
             'description', jsonb_build_object(
               'i18n_uuid',
               ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.o0309' || to_char(v.num, 'FM00') || '.disease_desc')::text
             )
           )
         )
       )
  FROM meta
 CROSS JOIN (VALUES (1), (2), (3)) AS v(num)
UNION ALL
SELECT 'character'
     , meta.qu_id || '_o0310' || to_char(v.sort_order, 'FM00')
     , jsonb_build_object(
         'add_unique',
         jsonb_build_array(
           jsonb_build_object('var', 'characterRaw.lore.diseases_and_curses'),
           jsonb_build_object(
             'name', jsonb_build_object(
               'i18n_uuid',
               ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.o0310' || to_char(v.sort_order, 'FM00') || '.disease_name')::text
             ),
             'description', jsonb_build_object(
               'i18n_uuid',
               ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.o0310' || to_char(v.sort_order, 'FM00') || '.disease_desc')::text
             )
           )
         )
       )
  FROM meta
 CROSS JOIN generate_series(1, 32) AS v(sort_order);
