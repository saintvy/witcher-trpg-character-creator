\echo '014_wcc_item_ingredients.sql'
CREATE TABLE IF NOT EXISTS wcc_item_ingredients (
    i_id                    varchar(10) PRIMARY KEY,          -- e.g. 'I047'
    dlc_dlc_id              varchar(64) NOT NULL REFERENCES wcc_dlcs(dlc_id), -- source (core, hb, dlc_*, exp_*)

    name_id                 uuid NOT NULL,                    -- ck_id('witcher_cc.items.ingredient.name.'||i_id)

    group_id                uuid NULL,                        -- ck_id('ingredients.*') - category
    availability_id         uuid NULL,                        -- ck_id('availability.*')
    ingredient_id           uuid NULL,                        -- ck_id('ingredients.*') - alchemy substance

    harvesting_complexity   integer NULL,                     -- complexity of harvesting (integer)
    weight                  numeric(12,2) NULL,               -- weight with decimal
    price                   integer NULL                      -- price (integer)
);

COMMENT ON TABLE wcc_item_ingredients IS
  'Ингредиенты для крафта и алхимии. Источник (DLC) через wcc_dlcs, локализуемые поля через i18n_text UUID (ck_id).';

COMMENT ON COLUMN wcc_item_ingredients.dlc_dlc_id IS
  'FK на wcc_dlcs.dlc_id (источник/пакет: core/hb/dlc_*/exp_*).';

COMMENT ON COLUMN wcc_item_ingredients.name_id IS
  'i18n UUID для названия ингредиента. Генерируется детерминированно: ck_id(''witcher_cc.items.ingredient.name.''||i_id).';

COMMENT ON COLUMN wcc_item_ingredients.group_id IS
  'i18n UUID для категории ингредиента. Использует ключи из словаря: ck_id(''ingredients.*'').';

COMMENT ON COLUMN wcc_item_ingredients.availability_id IS
  'i18n UUID для доступности ингредиента. Использует ключи из словаря: ck_id(''availability.*'').';

COMMENT ON COLUMN wcc_item_ingredients.ingredient_id IS
  'i18n UUID для типа алхимического вещества. Использует ключи из словаря: ck_id(''ingredients.*'').';

WITH raw_data (name_ru, name_en, i_id, source_id, group_key, harvesting_complexity, availability_key, weight, price, ingredient_key) AS ( VALUES
    ('Купорос', 'Vitriol', 'I047', 'core', 'ingredients.alchemy.extracted_alchemical_components', NULL, 'availability.C', '0,1', 8, 'ingredients.vitriol'),
    ('Ребис', 'Rebis', 'I048', 'core', 'ingredients.alchemy.extracted_alchemical_components', NULL, 'availability.C', '0,1', 8, 'ingredients.rebis'),
    ('Эфир', 'Aether', 'I049', 'core', 'ingredients.alchemy.extracted_alchemical_components', NULL, 'availability.E', '0,1', 5, 'ingredients.aether'),
    ('Квебрит', 'Quebrith', 'I050', 'core', 'ingredients.alchemy.extracted_alchemical_components', NULL, 'availability.E', '0,1', 2, 'ingredients.quebrith'),
    ('Гидраген', 'Hydragenum', 'I051', 'core', 'ingredients.alchemy.extracted_alchemical_components', NULL, 'availability.P', '0,1', 8, 'ingredients.hydragenum'),
    ('Киноварь', 'Vermilion', 'I052', 'core', 'ingredients.alchemy.extracted_alchemical_components', NULL, 'availability.P', '0,1', 9, 'ingredients.vermilion'),
    ('Солнце', 'Sol', 'I053', 'core', 'ingredients.alchemy.extracted_alchemical_components', NULL, 'availability.P', '0,1', 18, 'ingredients.sol'),
    ('Аер', 'Caelum', 'I054', 'core', 'ingredients.alchemy.extracted_alchemical_components', NULL, 'availability.C', '0,1', 8, 'ingredients.caelum'),
    ('Фульгор', 'Fulgur', 'I055', 'core', 'ingredients.alchemy.extracted_alchemical_components', NULL, 'availability.C', '0,1', 10, 'ingredients.fulgur'),
    ('Чистый Эфир', 'Pure Aether', 'I210', 'dlc_rw2', 'ingredients.alchemy.extracted_alchemical_components', NULL, 'availability.P', '0,1', 50, 'ingredients.aether'),
    ('Чистый Аер', 'Pure Caelum', 'I211', 'dlc_rw2', 'ingredients.alchemy.extracted_alchemical_components', NULL, 'availability.P', '0,1', 50, 'ingredients.caelum'),
    ('Чистый Фульгор', 'Pure Fulgur', 'I212', 'dlc_rw2', 'ingredients.alchemy.extracted_alchemical_components', NULL, 'availability.P', '0,1', 100, 'ingredients.fulgur'),
    ('Чистый Гидраген', 'Pure Hydragenum', 'I213', 'dlc_rw2', 'ingredients.alchemy.extracted_alchemical_components', NULL, 'availability.P', '0,1', 100, 'ingredients.hydragenum'),
    ('Чистый Квебрит', 'Pure Quebrith', 'I214', 'dlc_rw2', 'ingredients.alchemy.extracted_alchemical_components', NULL, 'availability.P', '0,1', 50, 'ingredients.quebrith'),
    ('Чистый Ребис', 'Pure Rebis', 'I215', 'dlc_rw2', 'ingredients.alchemy.extracted_alchemical_components', NULL, 'availability.P', '0,1', 100, 'ingredients.rebis'),
    ('Чистое Солнце', 'Pure Sol', 'I216', 'dlc_rw2', 'ingredients.alchemy.extracted_alchemical_components', NULL, 'availability.P', '0,1', 100, 'ingredients.sol'),
    ('Чистая Киноварь', 'Pure Vermilion', 'I217', 'dlc_rw2', 'ingredients.alchemy.extracted_alchemical_components', NULL, 'availability.P', '0,1', 100, 'ingredients.vermilion'),
    ('Чистый Купорос', 'Pure Vitriol', 'I218', 'dlc_rw2', 'ingredients.alchemy.extracted_alchemical_components', NULL, 'availability.P', '0,1', 50, 'ingredients.vitriol'),
    ('Коготь гуля', 'Ghoul Claw', 'I060', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '1', 60, 'ingredients.vitriol'),
    ('Зубы накера', 'Nekker Teeth', 'I061', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.P', '0,1', 30, 'ingredients.vitriol'),
    ('Шкура тролля', 'Troll Hide', 'I063', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '4,5', 147, 'ingredients.vitriol'),
    ('Мозг утопца', 'Drowner Brain', 'I066', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.P', '1', 80, 'ingredients.rebis'),
    ('Зубы кладбищенской бабы', 'Hag Teeth', 'I068', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '0,1', 90, 'ingredients.rebis'),
    ('Сердце накера', 'Nekker Heart', 'I070', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.P', '0,5', 30, 'ingredients.rebis'),
    ('Эссенция призрака', 'Essence of Wraith', 'I074', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '0,1', 95, 'ingredients.aether'),
    ('Костный мозг гуля', 'Ghoul Marrow', 'I083', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '0,5', 80, 'ingredients.quebrith'),
    ('Эссенция воды', 'Essence of Water', 'I088', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '0,1', 46, 'ingredients.hydragenum'),
    ('Дымная пыль', 'Infused Dust', 'I089', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '0,1', 146, 'ingredients.hydragenum'),
    ('Коготь накера', 'Nekker Claw', 'I091', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.P', '0,5', 40, 'ingredients.hydragenum'),
    ('Печень тролля', 'Troll Liver', 'I092', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '1', 87, 'ingredients.hydragenum'),
    ('Слюна волколака', 'Werewolf Saliva', 'I093', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '0,1', 60, 'ingredients.hydragenum'),
    ('Хитин', 'Chitin', 'I094', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '5', 106, 'ingredients.vermilion'),
    ('Слюна эндриаги', 'Endrega Saliva', 'I095', 'core', 'ingredients.alchemy.from_monsters', 15, 'availability.P', '0,1', 38, 'ingredients.vermilion'),
    ('Яйцо грифона', 'Griffin Egg', 'I096', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '1', 150, 'ingredients.vermilion'),
    ('Перья грифона', 'Griffin Feathers', 'I097', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '0,1', 148, 'ingredients.vermilion'),
    ('Глаза беса', 'Wyvern Eyes', 'I101', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '0,5', 149, 'ingredients.sol'),
    ('Эссенция света', 'Light Essence', 'I102', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.P', '0,1', 43, 'ingredients.sol'),
    ('Голосовые связки сирены', 'Siren Vocal Chords', 'I103', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '0,1', 65, 'ingredients.sol'),
    ('Слюна вампира', 'Vampire Saliva', 'I104', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '0,5', 155, 'ingredients.sol'),
    ('Глаза виверны', 'Fiend''s Eye', 'I107', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '0,1', 75, 'ingredients.sol'),
    ('Яд главоглаза', 'Arachas Venom', 'I108', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '0,5', 76, 'ingredients.caelum'),
    ('Язык утопца', 'Drowner Tongue', 'I110', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '0,5', 86, 'ingredients.caelum'),
    ('Помёт беса', 'Fiend Dung', 'I111', 'core', 'ingredients.alchemy.from_monsters', 20, 'availability.R', '1', 106, 'ingredients.caelum'),
    ('Язык кладбищенской бабы', 'Grave Hag Tongue', 'I112', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '0,5', 80, 'ingredients.caelum'),
    ('Зубы вампира', 'Vampire Teeth', 'I114', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '0,1', 150, 'ingredients.caelum'),
    ('Экстракт яда', 'Venom Extract', 'I115', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.P', '0,1', 38, 'ingredients.caelum'),
    ('Глаза', 'Arachas Eyes', 'I116', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '0,5', 95, 'ingredients.fulgur'),
    ('Собачье сало', 'Dog Tallow', 'I117', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.C', '0,1', 10, 'ingredients.fulgur'),
    ('Эмбрион эндриаги', 'Endrega Embryo', 'I119', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '1,5', 55, 'ingredients.fulgur'),
    ('Сердце голема', 'Golem Heart', 'I120', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '1', 167, 'ingredients.fulgur'),
    ('Ухо кладбищенской бабы', 'Grave Hag Ear', 'I121', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '0,1', 134, 'ingredients.fulgur'),
    ('Призрачная пыль', 'Specter Dust', 'I122', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.P', '0', 30, 'ingredients.fulgur'),
    ('Яйцо виверны', 'Wyvern Egg', 'I123', 'core', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '2', 150, 'ingredients.fulgur'),
    ('Слюна альпа', 'Alp Saliva', 'I129', 'dlc_sh_mothr', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 145, 'ingredients.hydragenum'),
    ('Эссенция смерти', 'Essence of Death', 'I130', 'dlc_rw5', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '0,1', 155, 'ingredients.fulgur'),
    ('Желудок жагницы', 'Glustyworp Stomach', 'I131', 'dlc_sh_mothr', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,5', 96, 'ingredients.caelum'),
    ('Зубы котолака', 'Werecat Teeth', 'I132', 'dlc_sh_mothr', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 88, 'ingredients.rebis'),
    ('Медвежий жир', 'Bear Fat', 'I133', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, 'availability.C', '0,5', 90, 'ingredients.rebis'),
    ('Рога демона диявола', 'Bes Horn', 'I134', 'exp_toc', 'ingredients.alchemy.from_monsters', NULL, 'availability.P', '1', 166, 'ingredients.fulgur'),
    ('Череп демона Мари Лвид', 'Mari Lwyd Skull', 'I135', 'exp_toc', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '2', 200, 'ingredients.hydragenum'),
    ('Волокно лешего', 'Leshen Fiber', 'I136', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 106, 'ingredients.vermilion'),
    ('Волосы стучака', 'Knocker Hair', 'I137', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 33, 'ingredients.quebrith'),
    ('Выделения сколопендроморфа', 'Giant Centipede Discharge', 'I138', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 40, 'ingredients.caelum'),
    ('Глаз циклопа', 'Cyclops'' Eye', 'I139', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '1', 159, 'ingredients.vermilion'),
    ('Глаза прибожка', 'Godling Eyes', 'I140', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 55, 'ingredients.aether'),
    ('Глаза утковола', 'Bullvore Eyes', 'I141', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,5', 87, 'ingredients.vitriol'),
    ('Глаза химеры', 'Frightener Eyes', 'I142', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 192, 'ingredients.sol'),
    ('Голосовые связки ослизга', 'Slyzard Vocal Chords', 'I143', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 99, 'ingredients.vitriol'),
    ('Жвалы сколопендроморфа', 'Giant Centipede Mandibles', 'I144', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,5', 48, 'ingredients.vitriol'),
    ('Желудок куролиска', 'Cockatrice Stomach', 'I145', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '1', 92, 'ingredients.vermilion'),
    ('Желудок мантихора', 'Manticore Stomach', 'I146', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '2', 189, 'ingredients.quebrith'),
    ('Желудок плюмарда', 'Plumard Stomach', 'I147', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 30, 'ingredients.aether'),
    ('Зубы дракона', 'Dragon Teeth', 'I148', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '1', 192, 'ingredients.fulgur'),
    ('Зубы стучака', 'Knocker Teeth', 'I149', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 46, 'ingredients.vermilion'),
    ('Зубы туманника', 'Foglet Teeth', 'I150', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 40, 'ingredients.rebis'),
    ('Камень элементаля', 'Elemental Stone', 'I151', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,5', 134, 'ingredients.quebrith'),
    ('Клыки вепря', 'Boar Tusks', 'I152', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 82, 'ingredients.vitriol'),
    ('Клыки высшего вампира', 'Higher Vampire Fangs', 'I153', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 250, 'ingredients.fulgur'),
    ('Клыки мантихора', 'Manticore Fangs', 'I154', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 132, 'ingredients.vitriol'),
    ('Когти гарпии', 'Harpy Talons', 'I155', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 40, 'ingredients.caelum'),
    ('Когти ослизга', 'Slyzard Talons', 'I156', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,5', 69, 'ingredients.caelum'),
    ('Когти химеры', 'Frightener Claws', 'I157', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '5', 205, 'ingredients.fulgur'),
    ('Кости игоши', 'Botchling Bones', 'I159', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 55, 'ingredients.hydragenum'),
    ('Кости лешего', 'Leshen Bone', 'I160', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '1', 92, 'ingredients.hydragenum'),
    ('Кости циклопа', 'Cyclops'' Bones', 'I161', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '4', 87, 'ingredients.aether'),
    ('Кристаллическая эссенция', 'Crystallized Essence', 'I162', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 292, 'ingredients.hydragenum'),
    ('Кровь бруксы', 'Bruxa Blood', 'I163', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 97, 'ingredients.vitriol'),
    ('Кровь гнильца', 'Rotfiend Blood', 'I164', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 30, 'ingredients.rebis'),
    ('Кровь дракона', 'Dragon Blood', 'I165', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '1', 250, 'ingredients.rebis'),
    ('Кровь игоши', 'Botchling Blood', 'I166', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 66, 'ingredients.vitriol'),
    ('Кровь утковола', 'Bullvore Blood', 'I167', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 85, 'ingredients.rebis'),
    ('Летательные перепонки', 'Wing Membrane', 'I168', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,5', 36, 'ingredients.rebis'),
    ('Летательные перепонки мантихора', 'Manticore Wing Membranes', 'I169', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '2', 145, 'ingredients.sol'),
    ('Лимфа чудовища', 'Abomination Lymph', 'I170', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 152, 'ingredients.quebrith'),
    ('Мех вендиго', 'Vendigo Fur', 'I171', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 76, 'ingredients.fulgur'),
    ('Мозг игоши', 'Botchling Brain', 'I172', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 164, 'ingredients.caelum'),
    ('Мозг утковола', 'Bullvore Brain', 'I173', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '1', 150, 'ingredients.fulgur'),
    ('Мозг циклопа', 'Cyclops'' Brain', 'I174', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '2', 136, 'ingredients.rebis'),
    ('Наезанская соль', 'Naezan Salts', 'I175', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 146, 'ingredients.aether'),
    ('Пальцы стучака', 'Knocker Toes', 'I176', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 62, 'ingredients.rebis'),
    ('Панцирь куролиска', 'Cockatrice Carapace', 'I177', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '2', 75, 'ingredients.hydragenum'),
    ('Пепел феникса', 'Phoenix Ash', 'I178', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 94, 'ingredients.sol'),
    ('Перья гарпии', 'Harpy Feathers', 'I179', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 28, 'ingredients.vermilion'),
    ('Перья феникса', 'Phoenix Feathers', 'I180', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 176, 'ingredients.fulgur'),
    ('Печень гнильца', 'Rotfiend Liver', 'I181', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,5', 42, 'ingredients.caelum'),
    ('Пыль шарлея', 'Shaelmaar Dust', 'I182', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 79, 'ingredients.rebis'),
    ('Рог мантихора', 'Manticore Horn', 'I183', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '1', 120, 'ingredients.hydragenum'),
    ('Рог суккуба', 'Succubus Horn', 'I184', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,5', 87, 'ingredients.caelum'),
    ('Сердце вендиго', 'Vendigo Heart', 'I185', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '1', 167, 'ingredients.aether'),
    ('Сердце суккуба', 'Succubus Heart', 'I186', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,5', 95, 'ingredients.vermilion'),
    ('Слёзы дракона', 'Dragon Tears', 'I187', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 276, 'ingredients.sol'),
    ('Слюна гаркаина', 'Garkain Saliva', 'I188', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 70, 'ingredients.quebrith'),
    ('Смола лешего', 'Leshen Resin', 'I189', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 140, 'ingredients.vitriol'),
    ('Сок археспоры', 'Archespore Juice', 'I190', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 38, 'ingredients.vitriol'),
    ('Усики археспоры', 'Archespore Tendrils', 'I191', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,5', 44, 'ingredients.quebrith'),
    ('Ухо игоши', 'Botchling Ear', 'I192', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 100, 'ingredients.fulgur'),
    ('Хвост дракона', 'Dragon Tail', 'I193', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '4', 310, 'ingredients.hydragenum'),
    ('Хвостовые перья куролиска', 'Cockatrice Tail Feathers', 'I194', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 135, 'ingredients.aether'),
    ('Чешуя ослизга', 'Slyzard Scales', 'I195', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '3', 82, 'ingredients.fulgur'),
    ('Шерсть барбегаза', 'Barbegazi Fur', 'I196', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 21, 'ingredients.hydragenum'),
    ('Шерсть шарлея', 'Shaelmaar Hair', 'I197', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 100, 'ingredients.caelum'),
    ('Эссенция баргеста', 'Barghest Essence', 'I198', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 36, 'ingredients.vermilion'),
    ('Эссенция пламени', 'Essence of Fire', 'I199', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 46, 'ingredients.sol'),
    ('Эссенция туманника', 'Foglet Essence', 'I200', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 43, 'ingredients.aether'),
    ('Яд Бохун Упас', 'Bohun Upas Poison', 'I201', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 200, 'ingredients.vermilion'),
    ('Язык тролля', 'Troll Tongue', 'I202', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,1', 66, 'ingredients.aether'),
    ('Язык циклопа', 'Cyclops'' Tongue', 'I203', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '1', 90, 'ingredients.fulgur'),
    ('Яйца гарпии', 'Harpy Eggs', 'I204', 'exp_wj', 'ingredients.alchemy.from_monsters', NULL, NULL, '0,5', 50, 'ingredients.quebrith'),
    ('Копыто сильвана', 'Sylvan Hoof', 'I208', 'dlc_rw5', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '1', 75, 'ingredients.hydragenum'),
    ('Рог сильвана', 'Sylvan Horn', 'I209', 'dlc_rw5', 'ingredients.alchemy.from_monsters', NULL, 'availability.R', '0,5', 80, 'ingredients.quebrith'),
    ('Плод балиссы', 'Balisse Fruit', 'I056', 'core', 'ingredients.alchemy.from_the_environment', 12, 'availability.C', '0,1', 8, 'ingredients.vitriol'),
    ('Ячмень', 'Barley', 'I057', 'core', 'ingredients.alchemy.from_the_environment', 12, 'availability.C', '0,1', 9, 'ingredients.vitriol'),
    ('Calcium equum', 'Calcium Equum', 'I058', 'core', 'ingredients.alchemy.from_the_environment', 12, 'availability.C', '0,1', 12, 'ingredients.vitriol'),
    ('Вороний глаз', 'Crow''s Eye', 'I059', 'core', 'ingredients.alchemy.from_the_environment', 15, 'availability.P', '0,1', 17, 'ingredients.vitriol'),
    ('Грибы-шибальцы', 'Sewant Mushrooms', 'I062', 'core', 'ingredients.alchemy.from_the_environment', 15, 'availability.P', '0,1', 17, 'ingredients.vitriol'),
    ('Лепестки белого мирта', 'White Myrtle Petals', 'I064', 'core', 'ingredients.alchemy.from_the_environment', 12, 'availability.C', '0,1', 8, 'ingredients.vitriol'),
    ('Ласточкина трава', 'Celandine', 'I065', 'core', 'ingredients.alchemy.from_the_environment', 12, 'availability.C', '0,1', 8, 'ingredients.rebis'),
    ('Волокна хана', 'Han Fiber', 'I067', 'core', 'ingredients.alchemy.from_the_environment', 15, 'availability.P', '0,1', 17, 'ingredients.rebis'),
    ('Лунная крошка', 'Lunar Shards', 'I069', 'core', 'ingredients.alchemy.from_the_environment', 18, 'availability.R', '0,1', 91, 'ingredients.rebis'),
    ('Винный камень', 'Wine Stone', 'I071', 'core', 'ingredients.alchemy.from_the_environment', 18, 'availability.R', '0,5', 88, 'ingredients.rebis'),
    ('Корень зарника', 'Allspice Root', 'I072', 'core', 'ingredients.alchemy.from_the_environment', 15, 'availability.P', '0,1', 18, 'ingredients.aether'),
    ('Плод берберки', 'Berbercane Fruit', 'I073', 'core', 'ingredients.alchemy.from_the_environment', 12, 'availability.C', '0,1', 9, 'ingredients.aether'),
    ('Явер', 'Sweet Flag', 'I252', 'dlc_wpaw', 'ingredients.alchemy.from_the_environment', 12, 'availability.C', '1', 18, 'ingredients.aether'),
    ('Лепестки гинации', 'Ginatia Petals', 'I075', 'core', 'ingredients.alchemy.from_the_environment', 15, 'availability.P', '0,1', 17, 'ingredients.aether'),
    ('Лепестки морозника', 'Hellebore Petals', 'I076', 'core', 'ingredients.alchemy.from_the_environment', 15, 'availability.P', '0,1', 19, 'ingredients.aether'),
    ('Жемчуг', 'Pearl', 'I077', 'core', 'ingredients.alchemy.from_the_environment', 20, 'availability.R', '0,1', 100, 'ingredients.aether'),
    ('Ртутный раствор', 'Quicksilver Solution', 'I078', 'core', 'ingredients.alchemy.from_the_environment', 18, 'availability.R', '0,1', 77, 'ingredients.aether'),
    ('Склеродерм', 'Scleroderm', 'I079', 'core', 'ingredients.alchemy.from_the_environment', 10, 'availability.E', '0,1', 5, 'ingredients.aether'),
    ('Листья балиссы', 'Balisse Leaves', 'I080', 'core', 'ingredients.alchemy.from_the_environment', 12, 'availability.C', '0,1', 8, 'ingredients.quebrith'),
    ('Царская водка', 'Ducal Water', 'I081', 'core', 'ingredients.alchemy.from_the_environment', 12, 'availability.C', '0,1', 20, 'ingredients.quebrith'),
    ('Собачья петрушка', 'Fool''s Parsley', 'I082', 'core', 'ingredients.alchemy.from_the_environment', 10, 'availability.E', '0,1', 2, 'ingredients.quebrith'),
    ('Жимолость', 'Honeysuckle', 'I084', 'core', 'ingredients.alchemy.from_the_environment', 12, 'availability.C', '0,1', 21, 'ingredients.quebrith'),
    ('Optima Mater', 'Optima Mater', 'I085', 'core', 'ingredients.alchemy.from_the_environment', 18, 'availability.R', '0,1', 100, 'ingredients.quebrith'),
    ('Сера', 'Sulfur', 'I086', 'core', 'ingredients.alchemy.from_the_environment', 12, 'availability.C', '0,1', 14, 'ingredients.quebrith'),
    ('Паутинник', 'Cortinarius', 'I087', 'core', 'ingredients.alchemy.from_the_environment', 15, 'availability.P', '0,1', 18, 'ingredients.hydragenum'),
    ('Омела', 'Mistletoe', 'I090', 'core', 'ingredients.alchemy.from_the_environment', 15, 'availability.P', '0,1', 8, 'ingredients.hydragenum'),
    ('Корень мандрагоры', 'Mandrake Root', 'I098', 'core', 'ingredients.alchemy.from_the_environment', 18, 'availability.R', '0,1', 65, 'ingredients.vermilion'),
    ('Фосфор', 'Phosphorus', 'I099', 'core', 'ingredients.alchemy.from_the_environment', 15, 'availability.P', '0,5', 20, 'ingredients.vermilion'),
    ('Аконит', 'Wolfsbane', 'I100', 'core', 'ingredients.alchemy.from_the_environment', 15, 'availability.P', '0,1', 9, 'ingredients.vermilion'),
    ('Вербена', 'Verbena', 'I105', 'core', 'ingredients.alchemy.from_the_environment', 15, 'availability.P', '0,1', 18, 'ingredients.sol'),
    ('Листья волчьего алоэ', 'Wolf''s Aloe Leaves', 'I106', 'core', 'ingredients.alchemy.from_the_environment', 15, 'availability.P', '0,1', 39, 'ingredients.sol'),
    ('Переступень', 'Bryonia', 'I109', 'core', 'ingredients.alchemy.from_the_environment', 12, 'availability.C', '0,1', 8, 'ingredients.caelum'),
    ('Зелёная плесень', 'Green Mold', 'I113', 'core', 'ingredients.alchemy.from_the_environment', 12, 'availability.C', '0,1', 8, 'ingredients.caelum'),
    ('Краснолюдский бессмертник', 'Dwarven Immortelle', 'I118', 'core', 'ingredients.alchemy.from_the_environment', 18, 'availability.R', '0,1', 75, 'ingredients.fulgur'),
    ('Корень лопуха', 'Burdock Root', 'I158', 'exp_wj', 'ingredients.alchemy.from_the_environment', 16, 'availability.C', '0,1', 32, 'ingredients.vermilion'),
    ('Чернящее масло', 'Darkening Oil', 'I023', 'core', 'ingredients.craft.alchemical_treatments', 16, 'availability.P', '0,1', 24, NULL),
    ('Драконье масло', 'Drake Oil', 'I024', 'core', 'ingredients.craft.alchemical_treatments', 16, 'availability.P', '0,1', 45, NULL),
    ('Эфирная смазка', 'Ester Grease', 'I025', 'core', 'ingredients.craft.alchemical_treatments', 14, 'availability.C', '0,1', 8, NULL),
    ('Травильная кислота', 'Etching Acid', 'I026', 'core', 'ingredients.craft.alchemical_treatments', 14, 'availability.C', '0,1', 2, NULL),
    ('Пятая эссенция', 'Fifth Essence', 'I027', 'core', 'ingredients.craft.alchemical_treatments', NULL, 'availability.R', '0,1', 82, NULL),
    ('Огров воск', 'Ogre Wax', 'I028', 'core', 'ingredients.craft.alchemical_treatments', 14, 'availability.C', '0,1', 10, NULL),
    ('Точильный порошок', 'Sharpening Grit', 'I029', 'core', 'ingredients.craft.alchemical_treatments', 16, 'availability.P', '0,1', 32, NULL),
    ('Дубильные травы', 'Tanning Herbs', 'I030', 'core', 'ingredients.craft.alchemical_treatments', 14, 'availability.C', '0,1', 3, NULL),
    ('Пепел', 'Ashes', 'I001', 'core', 'ingredients.craft.crafting_materials', 10, 'availability.E', '0,1', 1, NULL),
    ('Уголь', 'Coal', 'I002', 'core', 'ingredients.craft.crafting_materials', 14, 'availability.C', '0,1', 1, NULL),
    ('Хлопок', 'Cotton', 'I003', 'core', 'ingredients.craft.crafting_materials', 12, 'availability.C', '0,1', 1, NULL),
    ('Двойное полотно', 'Double Woven Linen', 'I004', 'core', 'ingredients.craft.crafting_materials', NULL, 'availability.P', '0,1', 22, NULL),
    ('Стекло', 'Glass', 'I005', 'core', 'ingredients.craft.crafting_materials', NULL, 'availability.P', '0,5', 5, NULL),
    ('Укреплённое дерево', 'Hardened Timber', 'I006', 'core', 'ingredients.craft.crafting_materials', NULL, 'availability.P', '0,1', 16, NULL),
    ('Полотно', 'Linen', 'I007', 'core', 'ingredients.craft.crafting_materials', NULL, 'availability.C', '0,1', 9, NULL),
    ('Масло', 'Oil', 'I008', 'core', 'ingredients.craft.crafting_materials', NULL, 'availability.C', '0,1', 3, NULL),
    ('Смола', 'Resin', 'I009', 'core', 'ingredients.craft.crafting_materials', 10, 'availability.C', '0,1', 2, NULL),
    ('Шёлк', 'Silk', 'I010', 'core', 'ingredients.craft.crafting_materials', NULL, 'availability.P', '0,1', 50, NULL),
    ('Нитки', 'Thread', 'I011', 'core', 'ingredients.craft.crafting_materials', NULL, 'availability.C', '0,1', 3, NULL),
    ('Древесина', 'Timber', 'I012', 'core', 'ingredients.craft.crafting_materials', 8, 'availability.E', '1', 3, NULL),
    ('Воск', 'Wax', 'I013', 'core', 'ingredients.craft.crafting_materials', 12, 'availability.C', '0,1', 2, NULL),
    ('Древесина орешника', 'Hazel Timber', 'I128', 'exp_toc', 'ingredients.craft.crafting_materials', NULL, 'availability.E', '1', 3, NULL),
    ('Кости животных', 'Beast Bones', 'I014', 'core', 'ingredients.craft.hidesand_animal_parts', NULL, 'availability.C', '4', 8, NULL),
    ('Коровья шкура', 'Cow Hide', 'I015', 'core', 'ingredients.craft.hidesand_animal_parts', NULL, 'availability.C', '5', 10, NULL),
    ('Кожа драконида', 'Draconid Leather', 'I016', 'core', 'ingredients.craft.hidesand_animal_parts', NULL, 'availability.R', '5', 58, NULL),
    ('Чешуя драконида', 'Draconid Scales', 'I017', 'core', 'ingredients.craft.hidesand_animal_parts', NULL, 'availability.R', '5', 30, NULL),
    ('Перья', 'Feathers', 'I018', 'core', 'ingredients.craft.hidesand_animal_parts', NULL, 'availability.E', '0,1', 4, NULL),
    ('Укреплённая кожа', 'Hardened Leather', 'I019', 'core', 'ingredients.craft.hidesand_animal_parts', NULL, 'availability.P', '3', 48, NULL),
    ('Кожа', 'Leather', 'I020', 'core', 'ingredients.craft.hidesand_animal_parts', NULL, 'availability.C', '2', 28, NULL),
    ('Лирийская кожа', 'Lyrian Leather', 'I021', 'core', 'ingredients.craft.hidesand_animal_parts', NULL, 'availability.P', '2', 60, NULL),
    ('Волчья шкура', 'Wolf Hide', 'I022', 'core', 'ingredients.craft.hidesand_animal_parts', NULL, 'availability.C', '3', 14, NULL),
    ('Мозг кошки', 'Feline Brain', 'I126', 'exp_toc', 'ingredients.craft.hidesand_animal_parts', NULL, 'availability.C', '0,1', 0, NULL),
    ('Шкура медведя', 'Bear Hide', 'I127', 'exp_wj', 'ingredients.craft.hidesand_animal_parts', NULL, 'availability.C', '6', 30, NULL),
    ('Шкура вепря', 'Boar Pelt', 'I205', 'exp_wj', 'ingredients.craft.hidesand_animal_parts', NULL, 'availability.C', '2', 10, NULL),
    ('Шкура пантеры', 'Panther Hide', 'I206', 'exp_wj', 'ingredients.craft.hidesand_animal_parts', NULL, 'availability.C', '3', 38, NULL),
    ('Тёмное железо', 'Dark Iron', 'I031', 'core', 'ingredients.craft.ingots_and_minerals', 18, 'availability.R', '1,5', 52, NULL),
    ('Тёмная сталь', 'Dark Steel', 'I032', 'core', 'ingredients.craft.ingots_and_minerals', NULL, 'availability.R', '1', 82, NULL),
    ('Двимерит', 'Dimeritium', 'I033', 'core', 'ingredients.craft.ingots_and_minerals', NULL, 'availability.R', '1', 240, NULL),
    ('Самоцветы', 'Gemstone', 'I034', 'core', 'ingredients.craft.ingots_and_minerals', 24, 'availability.R', '0,1', 100, NULL),
    ('Светящаяся руда', 'Glowing Ore', 'I035', 'core', 'ingredients.craft.ingots_and_minerals', 20, 'availability.R', '1', 80, NULL),
    ('Золото', 'Gold', 'I036', 'core', 'ingredients.craft.ingots_and_minerals', 18, 'availability.R', '1', 85, NULL),
    ('Железо', 'Iron', 'I037', 'core', 'ingredients.craft.ingots_and_minerals', 16, 'availability.P', '1,5', 30, NULL),
    ('Махакамский двимерит', 'Mahakaman Dimeritium', 'I038', 'core', 'ingredients.craft.ingots_and_minerals', NULL, 'availability.R', '1', 300, NULL),
    ('Махакамская сталь', 'Mahakaman Steel', 'I039', 'core', 'ingredients.craft.ingots_and_minerals', NULL, 'availability.P', '1', 114, NULL),
    ('Метеорит', 'Meteorite', 'I040', 'core', 'ingredients.craft.ingots_and_minerals', 24, 'availability.R', '1', 98, NULL),
    ('Речная глина', 'River Clay', 'I041', 'core', 'ingredients.craft.ingots_and_minerals', 14, 'availability.P', '1,5', 5, NULL),
    ('Серебро', 'Silver', 'I042', 'core', 'ingredients.craft.ingots_and_minerals', 16, 'availability.R', '1', 72, NULL),
    ('Сталь', 'Steel', 'I043', 'core', 'ingredients.craft.ingots_and_minerals', NULL, 'availability.P', '1', 48, NULL),
    ('Камень', 'Stone', 'I044', 'core', 'ingredients.craft.ingots_and_minerals', 8, 'availability.E', '2', 4, NULL),
    ('Третогорская сталь', 'Tretogor Steel', 'I045', 'core', 'ingredients.craft.ingots_and_minerals', NULL, 'availability.P', '1', 64, NULL),
    ('Зерриканская смесь', 'Zerrikanian Powder', 'I046', 'core', 'ingredients.craft.ingots_and_minerals', 18, 'availability.P', '0,1', 30, NULL),
    ('Изумрудная пыль', 'Emerald Dust', 'I124', 'dlc_rw5', 'ingredients.craft.ingots_and_minerals', 22, 'availability.R', '0,1', 90, NULL),
    ('Рубиновая пыль', 'Ruby Dust', 'I125', 'dlc_rw5', 'ingredients.craft.ingots_and_minerals', 22, 'availability.R', '0,1', 90, NULL),

    -- Custom / technical components (used by rituals & hexes as "ingredients")
    ('Плошка чистой воды', 'Bowl of Pure Water', 'I253', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Бутылёк чернил', 'Vial of Ink', 'I254', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Ветвь белого мирта', 'Branch of White Myrtle', 'I255', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Серебряный гвоздь', 'Silver Nail', 'I256', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Локон волос девственницы', 'Lock of a Virgin''s Hair', 'I257', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Живое животное', 'Live Animal', 'I258', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Ведро', 'Bucket', 'I259', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Коралл из Великого Моря', 'Coral from the Great Sea', 'I260', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Мясо волка', 'Wolf Meat', 'I261', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Небольшая водная поверхность', 'Small Body of Water', 'I262', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Небольшой огонь', 'Small Fire', 'I263', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Кровь умершего или его родственника', 'Blood of the Deceased or Their Relative', 'I264', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Место с возможностью поспать', 'A Place to Sleep', 'I265', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Череп животного', 'Animal Skull', 'I266', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Хрустальный череп животного', 'Crystal Animal Skull', 'I267', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Трофей из монстра', 'Monster Trophy', 'I268', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Сыр', 'Cheese', 'I269', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Мутаген', 'Mutagen', 'I270', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Алкоголь (на 40 крон)', 'Alcohol (worth 40 crowns)', 'I271', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Бутылка спиртного', 'Bottle of Spirits', 'I272', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Труп', 'Corpse', 'I273', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Свечи', 'Candles', 'I274', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Мелок', 'Chalk', 'I275', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Ваша собственная кровь', 'Your Own Blood', 'I276', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Череп (от существа, убитого за последние 24 часа)', 'Skull (from a creature killed within the last 24 hours)', 'I277', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('10 трупов (от существ, убитых за последние 24 часа)', '10 Corpses (from creatures killed within the last 24 hours)', 'I278', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Труп (с работающими голосовыми связками, легкими, мозгом и ртом)', 'Corpse (with working vocal cords, lungs, brain, and mouth)', 'I279', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Головная броня', 'Head Armor', 'I280', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Корпусная броня', 'Torso Armor', 'I281', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Ножная броня', 'Leg Armor', 'I282', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL),
    ('Боевой конь', 'War Horse', 'I283', 'core', 'custom.technical', NULL, NULL, NULL, 0, NULL)
),
ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    -- Ingredient names RU
    SELECT ck_id('witcher_cc.items.ingredient.name.'||rd.i_id),
           'items',
           'ingredient_names',
           'ru',
           rd.name_ru
      FROM raw_data rd
     WHERE nullif(rd.name_ru,'') IS NOT NULL
    UNION ALL
    -- Ingredient names EN
    SELECT ck_id('witcher_cc.items.ingredient.name.'||rd.i_id),
           'items',
           'ingredient_names',
           'en',
           rd.name_en
      FROM raw_data rd
     WHERE nullif(rd.name_en,'') IS NOT NULL
  ) foo
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO wcc_item_ingredients (
  i_id, dlc_dlc_id, name_id,
  group_id, availability_id, ingredient_id,
  harvesting_complexity, weight, price
)
SELECT rd.i_id
     , rd.source_id AS dlc_dlc_id
     , ck_id('witcher_cc.items.ingredient.name.'||rd.i_id) AS name_id
     , CASE WHEN rd.group_key IS NOT NULL THEN ck_id(rd.group_key) ELSE NULL END AS group_id
     , CASE WHEN rd.availability_key IS NOT NULL THEN ck_id(rd.availability_key) ELSE NULL END AS availability_id
     , CASE WHEN rd.ingredient_key IS NOT NULL THEN ck_id(rd.ingredient_key) ELSE NULL END AS ingredient_id
     , rd.harvesting_complexity
     , CAST(NULLIF(REPLACE(rd.weight, ',', '.'), '') AS numeric) AS weight
     , rd.price
  FROM raw_data rd
ON CONFLICT (i_id) DO UPDATE
SET
  dlc_dlc_id = EXCLUDED.dlc_dlc_id,
  name_id = EXCLUDED.name_id,
  group_id = EXCLUDED.group_id,
  availability_id = EXCLUDED.availability_id,
  ingredient_id = EXCLUDED.ingredient_id,
  harvesting_complexity = EXCLUDED.harvesting_complexity,
  weight = EXCLUDED.weight,
  price = EXCLUDED.price;



