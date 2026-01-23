\echo '011_wcc_item_mutagens.sql'
CREATE TABLE IF NOT EXISTS wcc_item_mutagens (
    m_id            varchar(10) PRIMARY KEY,          -- e.g. 'M001'
    dlc_dlc_id      varchar(64) NOT NULL REFERENCES wcc_dlcs(dlc_id), -- source_id (core, hb, dlc_*, exp_*)

    name_id         uuid NOT NULL,                    -- ck_id('witcher_cc.items.mutagen.name.'||m_id)

    -- Reused dictionary fields (see 001_wcc_items_dict.sql)
    color_id        uuid NULL,                        -- ck_id('mutagen.color.*')
    availability_id uuid NULL,                        -- ck_id('availability.*')

    effect_id       uuid NOT NULL,                    -- ck_id('witcher_cc.items.mutagen.effect.'||m_id)
    alchemy_dc      integer NOT NULL,
    minor_mutation_id uuid NOT NULL,                 -- ck_id('witcher_cc.items.mutagen.minor_mutation.'||m_id)
    price           integer NOT NULL DEFAULT 0
);

COMMENT ON TABLE wcc_item_mutagens IS
  'Мутагены. Источник (DLC) через wcc_dlcs, локализуемые поля через i18n_text UUID (ck_id). Цвет/доступность — из общего словаря (001_wcc_items_dict.sql).';

COMMENT ON COLUMN wcc_item_mutagens.dlc_dlc_id IS
  'FK на wcc_dlcs.dlc_id (источник/пакет: core/hb/dlc_*/exp_*).';

COMMENT ON COLUMN wcc_item_mutagens.name_id IS
  'i18n UUID для названия мутагена. Генерируется детерминированно: ck_id(''witcher_cc.items.mutagen.name.''||m_id).';

COMMENT ON COLUMN wcc_item_mutagens.effect_id IS
  'i18n UUID для эффекта мутагена. Генерируется детерминированно: ck_id(''witcher_cc.items.mutagen.effect.''||m_id).';

COMMENT ON COLUMN wcc_item_mutagens.minor_mutation_id IS
  'i18n UUID для малой мутации. Генерируется детерминированно: ck_id(''witcher_cc.items.mutagen.minor_mutation.''||m_id).';

WITH raw_data (
  m_id, source_id, color_key, availability_key,
  name_ru, name_en,
  effect_ru, effect_en,
  alchemy_dc,
  minor_mutation_ru, minor_mutation_en
) AS ( VALUES
  -- Core mutagens (first screenshot pair with "Полуденница")
  ('M001','core','mutagen.color.red','availability.U',
    'Грифон','Griffin',
    '+2 к урону в ближнем бою','+2 melee damage',
    18,
    'Прорастание перьев','Feather growth'),
  ('M002','core','mutagen.color.red','availability.U',
    'Катакан','Katakan',
    '+1 к Реа','+1 REF',
    22,
    'Долговязость','Gangly proportions'),
  ('M003','core','mutagen.color.red','availability.U',
    'Накер','Nekker',
    '+1 к урону в ближнем бою','+1 melee damage',
    15,
    'Облысение и серая кожа','Baldness & grey skin'),
  ('M004','core','mutagen.color.red','availability.U',
    'Волколак','Werewolf',
    '+3 к урону в ближнем бою','+3 melee damage',
    20,
    'Рост волос по всему телу','Rapid hair growth'),
  ('M005','core','mutagen.color.red','availability.U',
    'Виверна','Wyvern',
    '+3 к урону в ближнем бою','+3 melee damage',
    20,
    'Огрубение кожи','Rough skin'),
  ('M006','core','mutagen.color.green','availability.U',
    'Главоглаз','Arachas',
    '+5 ПЗ','+5 HP',
    18,
    'Зелёная кровь и другие жидкости','Green bodily fluids'),
  ('M007','core','mutagen.color.green','availability.U',
    'Бес','Fiend',
    '+1 к Тел','+1 BODY',
    22,
    'Небольшие рожки','Small antlers'),
  ('M008','core','mutagen.color.green','availability.U',
    'Кладбищенская баба','Grave Hag',
    '+5 ПЗ','+5 HP',
    18,
    'Длинный серый язык','Long grey tongue'),
  ('M009','core','mutagen.color.green','availability.U',
    'Полуденница','Noonwraith',
    '+10 ПЗ','+10 HP',
    20,
    'Сухая, туго обтягивающая кожа','Dry, taut skin'),
  ('M010','core','mutagen.color.green','availability.U',
    'Скальный тролль','Rock Troll',
    '+10 ПЗ','+10 HP',
    20,
    'Сгорбленность','Hunched posture'),
  ('M011','core','mutagen.color.blue','availability.U',
    'Голем','Golem',
    '+2 к Энергии','+2 Vigor threshold',
    18,
    'Твёрдые наросты на теле','Hard protrusions'),
  ('M012','core','mutagen.color.blue','availability.U',
    'Сирена','Siren',
    '+1 к Энергии','+1 Vigor threshold',
    15,
    'Небольшие плавники','Small fins'),
  -- exp_wj mutagens (second screenshot pair with "Гаркаин")
  ('M013','exp_wj','mutagen.color.red','availability.U',
    'Вендиго','Vendigo',
    '+3 к урону в ближнем бою','+3 melee damage',
    20,
    'Клочки меха и болезненно-серая кожа','Patchy fur & sickly grey skin'),
  ('M014','exp_wj','mutagen.color.red','availability.U',
    'Игоша','Igosh',
    '+2 к урону в ближнем бою','+2 melee damage',
    18,
    'Волчья пасть и красные белки глаз','Wolf''s maw & red eye whites'),
  ('M015','exp_wj','mutagen.color.red','availability.U',
    'Куролиск','Kurolisk',
    '+2 к урону в ближнем бою','+2 melee damage',
    18,
    'Пучки зелёных перьев','Tufts of green feathers'),
  ('M016','exp_wj','mutagen.color.red','availability.U',
    'Мантихор','Manticore',
    '+1 к Реа','+1 REF',
    22,
    'Рожки и кошачьи черты лица','Small horns & feline features'),
  ('M017','exp_wj','mutagen.color.red','availability.U',
    'Феникс','Phoenix',
    '+3 к урону в ближнем бою','+3 melee damage',
    20,
    'Пучки серых перьев и свечение изнутри','Tufts of grey feathers & an internal glow'),
  ('M018','exp_wj','mutagen.color.green','availability.U',
    'Гаркаин','Garkain',
    '+10 ПЗ','+10 HP',
    20,
    'Мягкие наросты на голове','Fleshy growths on the head'),
  ('M019','exp_wj','mutagen.color.green','availability.U',
    'Медведь','Bear',
    '+10 ПЗ','+10 HP',
    20,
    'Усиленный рост волос на теле','Prolific fur growth'),
  ('M020','exp_wj','mutagen.color.green','availability.U',
    'Суккуб','Succubus',
    '+5 ПЗ','+5 HP',
    18,
    'Рожки и хвост','Small horns and a tail'),
  ('M021','exp_wj','mutagen.color.green','availability.U',
    'Тролль','Troll',
    '+5 ПЗ','+5 HP',
    18,
    'Жёсткая голубоватая кожа','Blue-ish skin leathery skin'),
  ('M022','exp_wj','mutagen.color.green','availability.U',
    'Утковол','Utkovol',
    '+10 ПЗ','+10 HP',
    20,
    'Твёрдые наросты по всему телу','Hard growths all over the body'),
  ('M023','exp_wj','mutagen.color.green','availability.U',
    'Химера','Frightener',
    '+1 к Тел','+1 BODY',
    22,
    'Фасеточные глаза и участки хитина','Multi-faceted eyes & patches of chitin'),
  ('M024','exp_wj','mutagen.color.green','availability.U',
    'Шарлей','Shaelmaar',
    '+10 ПЗ','+10 HP',
    20,
    'Участки твёрдой, как камень, кожи','Patches of thick rock textured skin'),
  ('M025','exp_wj','mutagen.color.blue','availability.U',
    'Брукса','Bruxa',
    '+1 к Воле','+1 WILL',
    22,
    'Полупрозрачная кожа и шипящий голос','Semi-translucent skin & a hissing voice'),
  ('M026','exp_wj','mutagen.color.blue','availability.U',
    'Леший','Leshen',
    '+1 к Воле','+1 WILL',
    22,
    'На теле вырастают побеги и листья','Plants growth on the body'),
  ('M027','exp_wj','mutagen.color.blue','availability.U',
    'Песта','Pesta',
    '+2 к Энергии','+2 Vigor threshold',
    18,
    'Болезненно-бледная кожа и впалые щёки','Sickly, pale skin & gaunt features'),
  ('M028','exp_wj','mutagen.color.blue','availability.U',
    'Туманник','Foglet',
    '+2 к Энергии','+2 Vigor threshold',
    18,
    'Слабый свет изнутри и осунувшееся лицо','A weak internal glow & gaunt features'),
  ('M029','exp_wj','mutagen.color.blue','availability.U',
    'Элементаль','Elemental',
    '+3 к Энергии','+3 Vigor threshold',
    20,
    'Земли: каменные наросты по всему телу; Огня: струйки пламени изо рта; Льда: всегда холодная на ощупь кожа','Earth: Rocky growths along your body; Fire: Small spouts of fire from your mouth; Ice: You are always cold to the touch'),
  -- dlc_sh_mothr mutagens (third screenshot pair with "Альп")
  ('M030','dlc_sh_mothr','mutagen.color.blue','availability.U',
    'Альпа','Alp',
    '+1 ВОЛЯ','+1 WILL',
    20,
    'Тело покрывается темно-красными подкожными венами','A patchwork of dark red veins under your skin'),
  ('M031','dlc_sh_mothr','mutagen.color.green','availability.U',
    'Жагница','Glustyworp',
    '+10 ПЗ','+10 HP',
    18,
    'Небольшие участки хитина на теле','Small patches of chitin'),
  ('M032','dlc_sh_mothr','mutagen.color.red','availability.U',
    'Котолак','Werecat',
    '+3 Урона в ближнем бою','+3 Melee Damage',
    18,
    'Кошачьи глаза и усиленный рост волос','Cat''s eyes and increased hair growth'),
  -- exp_toc mutagens (fourth screenshot pair with "Медведь")
  ('M033','exp_toc','mutagen.color.green','availability.U',
    'Медведь','Bear',
    '+10 ПЗ','+10HP',
    20,
    'Обильный рост волос','Prolific Hair Growth'),
  ('M034','exp_toc','mutagen.color.blue','availability.U',
    'Кающийся','Penitent',
    '+2 к Энергии','+2 Vigor Threshold',
    18,
    'Светящиеся белые отметины','Glowing White Markings')
),
ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT * FROM (
    -- Mutagen names
    SELECT ck_id('witcher_cc.items.mutagen.name.'||rd.m_id),
           'items',
           'mutagen_names',
           'ru',
           rd.name_ru
      FROM raw_data rd
     WHERE nullif(rd.name_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.items.mutagen.name.'||rd.m_id),
           'items',
           'mutagen_names',
           'en',
           rd.name_en
      FROM raw_data rd
     WHERE nullif(rd.name_en,'') IS NOT NULL
    UNION ALL
    -- Mutagen effects
    SELECT ck_id('witcher_cc.items.mutagen.effect.'||rd.m_id),
           'items',
           'mutagen_effects',
           'ru',
           rd.effect_ru
      FROM raw_data rd
     WHERE nullif(rd.effect_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.items.mutagen.effect.'||rd.m_id),
           'items',
           'mutagen_effects',
           'en',
           rd.effect_en
      FROM raw_data rd
     WHERE nullif(rd.effect_en,'') IS NOT NULL
    UNION ALL
    -- Minor mutations
    SELECT ck_id('witcher_cc.items.mutagen.minor_mutation.'||rd.m_id),
           'items',
           'mutagen_minor_mutations',
           'ru',
           rd.minor_mutation_ru
      FROM raw_data rd
     WHERE nullif(rd.minor_mutation_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.items.mutagen.minor_mutation.'||rd.m_id),
           'items',
           'mutagen_minor_mutations',
           'en',
           rd.minor_mutation_en
      FROM raw_data rd
     WHERE nullif(rd.minor_mutation_en,'') IS NOT NULL
  ) foo
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO wcc_item_mutagens (
  m_id, dlc_dlc_id, name_id,
  color_id, availability_id,
  effect_id, alchemy_dc, minor_mutation_id,
  price
)
SELECT rd.m_id
     , rd.source_id AS dlc_dlc_id
     , ck_id('witcher_cc.items.mutagen.name.'||rd.m_id) AS name_id
     , ck_id(rd.color_key) AS color_id
     , ck_id(rd.availability_key) AS availability_id
     , ck_id('witcher_cc.items.mutagen.effect.'||rd.m_id) AS effect_id
     , rd.alchemy_dc
     , ck_id('witcher_cc.items.mutagen.minor_mutation.'||rd.m_id) AS minor_mutation_id
     , 0 AS price
  FROM raw_data rd
ON CONFLICT (m_id) DO UPDATE
SET
  dlc_dlc_id = EXCLUDED.dlc_dlc_id,
  name_id = EXCLUDED.name_id,
  color_id = EXCLUDED.color_id,
  availability_id = EXCLUDED.availability_id,
  effect_id = EXCLUDED.effect_id,
  alchemy_dc = EXCLUDED.alchemy_dc,
  minor_mutation_id = EXCLUDED.minor_mutation_id,
  price = EXCLUDED.price;

