\echo '028_wcc_magic_hexes.sql'
-- Magic hexes from temp TSV

CREATE TABLE IF NOT EXISTS wcc_magic_hexes (
  ms_id              varchar(10) PRIMARY KEY,  -- e.g. 'MS119'
  dlc_dlc_id         varchar(64) NOT NULL REFERENCES wcc_dlcs(dlc_id),

  level_id           uuid NULL,                -- ck_id('level.*')

  name_id            uuid NOT NULL,            -- ck_id('witcher_cc.magic.hex.name.'||ms_id)
  effect_id          uuid NOT NULL,            -- ck_id('witcher_cc.magic.hex.effect.'||ms_id)
  remove_instructions_id uuid NOT NULL,        -- ck_id('witcher_cc.magic.hex.remove_instructions.'||ms_id)

  remove_components  jsonb NULL,               
  stamina_cast       text NULL
);

WITH raw_data (
  ms_id, dlc_dlc_id,
  level_key,
  name_ru, name_en,
  effect_ru,
  remove_components_raw,
  remove_instructions_ru,
  stamina_cast
) AS ( VALUES
  ('MS119', 'core', 'level.novice', 'Теневая порча', 'The Hex of Shadows', 'Жертва слышит шёпот в тенях и видит призрачные силуэты. Она должна совершать случайные проверки <i>(Внимания)</i> с неопределённой <b>Сл</b>, замечая кого-то или что-то краем глаза. Эти проверки не несут угрозы, это лишь видения', 'I253 (1), I254 (1), I255 (1)', 'Жертва должна прийти на поляну, когда в небе полумесяц. Когда месяц в зените, нужно вылить чернила в воду, смокнуть раствором ветвь и, задержав дыхание, разбрызгать раствор вокруг.', '4'),
  ('MS120', 'core', 'level.novice', 'Вечный зуд', 'The Eternal Itch', 'На гениталиях жертвы высыпают воспалённые зудящие прыщи, чем причиняет жертве постоянный дискомфорт. Штраф -1 к любым броскам. Также штраф -5 к <i>(Соблазнению)</i> при раздевании.', 'I079 (1), I082 (1), I109 (1)', 'Связать травы в пучок, развести костёр, поджечь пучок и пеплом посыпать между ног, произнося магические слова.', '4'),
  ('MS121', 'core', 'level.journeyman', 'Дьявольская удача', 'The Devil''s Luck', 'В особо стрессовых ситуациях крит. провалом считаются броски d10 не только 1, но и 2. Примеры ситуаций: - В бою. - При необходимости выполнить что-то за установленный срок. - При проверке со <b>Сл</b> выше 15.', 'I256 (1), I100 (2), I257 (1)', 'Жертва должна вбить гвоздь в раму у себя дома, повесить на него пучок аконита, перевязанный волосами. Встать под этот аконит, пожечь его и поглубже вдохнуть дым.', '8'),
  ('MS122', 'core', 'level.journeyman', 'Кошмар', 'The Nightmare', 'Жертва видит повторяющийся кошмар. Каждую ночь она бросает <i>(Сопротивление убеждению)</i> со <b>Сл</b> равной начальному броску <i>(Наведения порчи)</i>. При успехе беспокойно спит, при провале не спит и не восстанавливает <b>Вын</b> или ПЗ. При трёх провалах подряд <b>Вын</b> теряет 50%, штраф -2 ко всем броскам до полного ночного сна', 'I274 (5), I014 (5), I035 (1)', 'Расставить свечи вокруг жертвы, соединив костями, а руду положить на голову. Так нужно успешно проспать одну ночь.', '8'),
  ('MS123', 'core', 'level.master', 'Поцелуй Песты', 'The Pesta''s Kiss', 'Жертва ослабевает, становясь уязвимой к болезням и тошноте. Заболевает при контакте с заражённым с вероятностью 75%. При малейшем тошнотворном запахе проходит проверку Стойкости <b>Сл:16</b>, при провале мучается тошнотой.', 'I041 (3), I002 (1), I009 (3), I089 (1)', 'Вылепить тотем из глины и пыли, покрыть смолой, использовать угли как глаза, бросив <i>(Искусство)</i> со <b>Сл:14</b>. Произнести магические слова, разбить тотем, измельчить угли и съесть.', '12'),
  ('MS124', 'core', 'level.master', 'Звериная порча', 'The Hex of the Beast', 'Жертва становится ненавистна животным. В радиусе 10м от животных:   * Штраф -3 к <i>(Выживанию в дикой при-роде)</i>   * Животные нападают с вероятностью 50%.', 'I258 (1), I090 (2), I099 (1), I059 (2), I098 (3)', 'Под полной луной жертва вспарывает глотку животному и пьёт его кровь. Тело обкладывают растениями, затем сжигают. Когда шкура начнёт гореть, бросить фосфор. После угасания огня, жертва носит кости животного целый день.', '12'),
  ('MS222', 'exp_toc', 'level.novice', 'Проклятие трезвости', 'Curse of Temperance', 'Проклятие сдержанности насыщает желудок алкоголем, усугубляя влияние спиртного. При потреблении любого алкоголя жертва немедленно страдает от: <b><i>Опьянения</i></b>: Штраф -2 к <b>Реа</b>, <b>Лвк</b> и <b>Инт.</b> и -3 в <i>(Словесной дуэли)</i>. Шанс 25% плохо помнить события. <b><i>Тошноты</i></b>: Каждые три хода при броске d10 не ниже <b>Тел</b> блюет и пропускает ход.', 'I259 (1), I271 (1)', 'Наполнить ведро алкоголем и окунуть голову жертвы, пока та не начнет <b><i>задыхаться</i></b>.', '4'),
  ('MS223', 'exp_toc', 'level.novice', 'Отвратительная порча', 'The Odious Hex', 'Делает жертву отталкивающей для представителей той же расы. То есть понижает социальный статус на один уровень, если она не была ненавидима.', 'I067 (1), I057 (1), I082 (1)', 'Жертва должна сделать свою фигурку из растений. Оскорблять чучело будто себя, пока не закончатся оскорбления. А потом жертва должна сжечь фигурку.', '4'),
  ('MS224', 'exp_toc', 'level.journeyman', 'Дурной сглаз', 'The Evil Eye', 'Плетёт паутину несчастий вокруг цели. - При каждом крит.провале d10 нужно бросить дважды и выбрать худший результат. - Кроме того, ГМу рекомендовано выбирать жертву как цель угрозы (атаки, ловушки, и т.д.), когда она должны была бы быть выбрана случайно.', 'I260 (1)', 'Нужно сделать из коралла подвеску, пробросил (Искусство) со Сл:14. Нужно носить её всё полнолуние. На рассвете подвеска расколется, сняв порчу.', '8'),
  ('MS225', 'exp_toc', 'level.journeyman', 'Бесконечная потребность', 'Unending Need', E'Заставляет жертву быть ленивой и обжорливой.\n - Нужны 10 часов сна каждую ночь, иначе штраф -3 ко всем броскам.\n - Требуется 5 приёмов пищи в день, иначе <b>Вын</b> уменьшается вдвое на следующий день.', 'T033 (1)', 'Жертва должна голодать 3 дня и ночи, пить только воду и спать со сладостями под подушкой. Если жертва справится и не притронется к сладостям, порча исчезнет утром четвёртого дня.', '8'),
  ('MS226', 'exp_toc', 'level.master', 'Стеклянные кости', 'Bones of Glass', 'Стеклянные кости делают кости жертвы полыми и склонными к расщеплению. Критические ранения заменяются на более серьёзные: треснутые ребра — на сломанные, перелом руки/ноги — на открытый перелом, небольшая травма головы — на проломленный череп. Штраф -3 на стабилизацию и лечение этих ран.', 'I283 (1), I092 (1), I261 (1), I080 (3), I272 (1)', 'Обескровить коня, собрать кровь в котел, добавить печень, мясо и листья, готовить 3 часа. Съесть всю похлёбку за 1 час и выпить бутылку спиртного.', '12'),
  ('MS227', 'exp_toc', 'level.master', 'Порча забвения', 'Hex of Forgetfulness', 'Порча забвения затрудняет сохранение знаний и воспоминаний. Субъект не может получать О.У. за обучение или изучать новую магию, как и сам обучать. Раз в день ГМ может заставить цель пробросить <i>(Сопротивления магии)</i> со <b>Сл:20</b>, а при провале забыть выбранное воспоминание, рецепт или магию до снятия порчи.', 'I088 (2), I041 (2), I085 (1)', 'Нужно обрить голову, нанести на неё замешанную пасту в виде знаков, а в рот взять Optima Mater. Молча ждать день и ночь высыхание глины. Удалить глину и вынуть Optima Mater, которая станет серой и теперь дает Фокусировку (2) для тёмных искусств.', '12')
),
hex_effects_en (ms_id, text_en) AS (
  VALUES
    ('MS119', E'The victim hears whispers in the shadows and sees ghostly silhouettes.\nThey must make random (Awareness) checks at an unspecified DC, noticing someone or something out of the corner of their eye. These checks are not dangerous—just visions.'),
    ('MS120', E'Inflamed, itchy pimples appear on the victim''s genitals, causing constant discomfort.\n-1 to all rolls. Additionally, -5 to (Seduction) when undressing.'),
    ('MS121', E'In highly stressful situations, a critical failure is considered to be a d10 roll of 1 or 2 (instead of only 1).\nExamples:\n- in combat\n- when you must do something under a time limit\n- when making a check with DC higher than 15'),
    ('MS122', E'The victim suffers a recurring nightmare.\nEach night they roll (Resist Coercion) vs a DC equal to the original (Hex Weaving) roll.\nOn success they sleep restlessly; on failure they do not sleep and recover no STA or HP.\nAfter three failures in a row, the victim loses 50% STA and takes -2 to all rolls until they get a full night''s sleep.'),
    ('MS123', E'The victim weakens, becoming vulnerable to disease and nausea.\nThey become ill on contact with infection with a 75% chance.\nAt any nauseating smell they must make an Endurance check at DC 16; on failure they are overcome with nausea.'),
    ('MS124', E'Animals come to hate the victim.\nWithin 10 meters of animals:\n* -3 to (Wilderness Survival)\n* Animals attack with a 50% chance.'),
    ('MS222', E'Fills the victim''s stomach with alcohol, worsening the effects of drinking.\nWhenever the victim consumes any alcohol, they immediately suffer:\nDrunk: -2 to REF, DEX, and INT, and -3 to (Verbal Combat). 25% chance to remember events poorly.\nNausea: every three turns, if a d10 roll is not lower than BODY, the victim vomits and loses their turn.'),
    ('MS223', E'Makes the victim repulsive to members of their own race.\nEffectively lowers their social status by one level (if they were not already hated).'),
    ('MS224', E'Weaves a web of misfortune around the victim.\n- On every critical failure, roll d10 twice and take the worse result.\n- Additionally, the GM is encouraged to choose the victim as the target of threats (attacks, traps, etc.) whenever the target would otherwise be chosen randomly.'),
    ('MS225', E'Makes the victim lazy and gluttonous.\n- They need 10 hours of sleep each night; otherwise they take -3 to all rolls.\n- They must eat 5 meals per day; otherwise their STA is halved the next day.'),
    ('MS226', E'Makes the victim''s bones hollow and prone to splintering.\nCritical wounds are replaced with more severe ones: cracked ribs become broken ribs, a broken arm/leg becomes an open fracture, a minor head injury becomes a crushed skull.\n-3 to stabilizing and treating these wounds.'),
    ('MS227', 'Makes it difficult to retain knowledge and memories.
The subject cannot gain IP from training or learn new magic, and cannot teach either.
Once per day the GM may force the target to roll (Resist Magic) at DC 20; on a failure they forget a chosen memory, recipe, or spell until the hex is removed.')
),
hex_remove_en (ms_id, text_en) AS (
  VALUES
    ('MS119', E'The victim must come to a clearing when the moon is a half-moon.\nWhen the moon is at its zenith, pour ink into water, soak a branch in the mixture, then—holding your breath—spray the mixture around you.'),
    ('MS120', 'Tie the herbs into a bundle, build a fire, burn the bundle, and sprinkle the ash between the legs while speaking magical words.'),
    ('MS121', 'The victim must hammer a nail into the window frame at home, hang a bundle of aconite tied with a virgin''s hair from it, stand beneath it, burn it, and inhale the smoke deeply.'),
    ('MS122', 'Place candles around the victim, connecting them with animal bones, and place the glowing ore on their head. The victim must successfully sleep through one night like this.'),
    ('MS123', E'Sculpt a totem from clay and powder, coat it with resin, use charcoal as eyes, and make an (Art) check at DC 14.\nSpeak magical words, smash the totem, grind the charcoal, and eat it.'),
    ('MS124', E'Under a full moon the victim slits a living animal''s throat and drinks its blood.\nCover the body with the plants, then burn it. When the hide starts to burn, throw in the phosphorus.\nAfter the fire dies, the victim must wear the animal''s bones for a whole day.'),
    ('MS222', 'Fill a bucket with alcohol and dunk the victim''s head until they begin to Suffocate.'),
    ('MS223', E'The victim must make a small figure of themselves from plants.\nThey must insult the effigy as if insulting themselves until they run out of insults, then burn the figure.'),
    ('MS224', E'Make a pendant from coral with an (Art) check at DC 14.\nThe victim must wear it for the entire full moon. At dawn the pendant cracks, removing the hex.'),
    ('MS225', E'The victim must fast for 3 days and nights, drink only water, and sleep with sweets under their pillow.\nIf they endure and do not touch the sweets, the hex ends on the morning of the fourth day.'),
    ('MS226', E'Bleed a warhorse dry, collect the blood in a cauldron, add the liver, meat, and leaves, and cook for 3 hours.\nEat all the stew within 1 hour and drink a bottle of alcohol.'),
    ('MS227', E'Shave the victim''s head, apply a mixed paste in the shape of signs, and place Optima Mater in their mouth.\nSilently wait day and night for the clay to dry.\nRemove the clay and take out the Optima Mater; it turns grey and now provides Focusing (2) for dark arts.')
),
ins_i18n AS (
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT * FROM (
SELECT ck_id('witcher_cc.magic.hex.name.'||rd.ms_id),
'magic',
           'hex_names',
           'ru',
           rd.name_ru
      FROM raw_data rd
     WHERE nullif(rd.name_ru,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.magic.hex.name.'||rd.ms_id),
           'magic',
           'hex_names',
           'en',
           rd.name_en
      FROM raw_data rd
     WHERE nullif(rd.name_en,'') IS NOT NULL
    UNION ALL
    SELECT ck_id('witcher_cc.magic.hex.effect.'||rd.ms_id),
           'magic',
           'hex_effects',
           'ru',
           regexp_replace(replace(replace(rd.effect_ru, chr(11), E'\n'), chr(13), ''), '<[^>]+>', '', 'g')
      FROM raw_data rd
     WHERE nullif(rd.effect_ru,'') IS NOT NULL
    UNION ALL
    -- effects EN (from manual translations)
    SELECT ck_id('witcher_cc.magic.hex.effect.'||hee.ms_id),
           'magic',
           'hex_effects',
           'en',
           hee.text_en
      FROM hex_effects_en hee
    UNION ALL
    SELECT ck_id('witcher_cc.magic.hex.remove_instructions.'||rd.ms_id),
           'magic',
           'hex_remove_instructions',
           'ru',
           regexp_replace(replace(replace(rd.remove_instructions_ru, chr(11), E'\n'), chr(13), ''), '<[^>]+>', '', 'g')
      FROM raw_data rd
     WHERE nullif(rd.remove_instructions_ru,'') IS NOT NULL
    UNION ALL
    -- remove instructions EN (from manual translations)
    SELECT ck_id('witcher_cc.magic.hex.remove_instructions.'||hre.ms_id),
           'magic',
           'hex_remove_instructions',
           'en',
           hre.text_en
      FROM hex_remove_en hre
  ) foo
  ON CONFLICT (id, lang) DO UPDATE
    SET text = EXCLUDED.text
)
INSERT INTO wcc_magic_hexes (
  ms_id, dlc_dlc_id,
  level_id,
  name_id, effect_id, remove_instructions_id,
  remove_components,
  stamina_cast
)
SELECT rd.ms_id
     , rd.dlc_dlc_id
     , CASE WHEN nullif(rd.level_key,'') IS NOT NULL THEN ck_id(rd.level_key) ELSE NULL END AS level_id
     , ck_id('witcher_cc.magic.hex.name.'||rd.ms_id) AS name_id
     , ck_id('witcher_cc.magic.hex.effect.'||rd.ms_id) AS effect_id
     , ck_id('witcher_cc.magic.hex.remove_instructions.'||rd.ms_id) AS remove_instructions_id
     , CASE
         WHEN rd.remove_components_raw IS NULL OR trim(rd.remove_components_raw) = '' THEN NULL
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
                 FROM regexp_split_to_table(rd.remove_components_raw, '\s*,\s*') WITH ORDINALITY AS s(token, ord)
               ) part
             ) pieces
             WHERE pieces.code IS NOT NULL AND pieces.code <> '' AND pieces.code ~ '^[IT][0-9]{3}$'
           ) comp
           WHERE (comp.obj->>'id') IS NOT NULL
         )
       END AS remove_components
     , nullif(rd.stamina_cast,'')
  FROM raw_data rd
ON CONFLICT (ms_id) DO UPDATE
SET
  dlc_dlc_id = EXCLUDED.dlc_dlc_id,
  level_id = EXCLUDED.level_id,
  name_id = EXCLUDED.name_id,
  effect_id = EXCLUDED.effect_id,
  remove_instructions_id = EXCLUDED.remove_instructions_id,
  remove_components = EXCLUDED.remove_components,
  stamina_cast = EXCLUDED.stamina_cast;
