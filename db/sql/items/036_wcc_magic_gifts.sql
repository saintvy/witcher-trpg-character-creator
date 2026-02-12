\echo '036_wcc_magic_gifts.sql'
-- Magical Gifts (Магические дары) from TOC

CREATE TABLE IF NOT EXISTS wcc_magic_gifts (
  mg_id               varchar(10) PRIMARY KEY,  -- e.g. 'MG001'
  dlc_dlc_id          varchar(64) NOT NULL REFERENCES wcc_dlcs(dlc_id),

  group_id            uuid NOT NULL,            -- ck_id('witcher_cc.magic.gift.group.minor')
  name_id             uuid NOT NULL,            -- ck_id('witcher_cc.magic.gift.name.'||mg_id)
  effect_id           uuid NOT NULL,           -- ck_id('witcher_cc.magic.gift.effect.'||mg_id)
  side_effect_id      uuid NOT NULL,           -- ck_id('witcher_cc.magic.gift.side_effect.'||mg_id)

  dc                  integer NOT NULL DEFAULT 0,
  vigor_cost          integer NOT NULL
);

WITH raw_data (
  mg_id, dlc_dlc_id, group_key,
  name_ru, name_en,
  effect_ru, effect_en,
  side_effect_ru, side_effect_en,
  dc, vigor_cost
) AS ( VALUES
  ('MG001', 'exp_toc', 'minor', 'Аура страха', 'Aura of Fear',
   'В качестве действия вы можете излучать ауру ощутимого страха. Все в пределах 4 м от вас должны пройти проверку Сопротивления магии со СЛ 12 или испугаться и получить -2 к любому действию против вас в течение 24 часов.',
   'As an action, you can emit an aura of tangible fear. Everyone within 4m of you must pass a Magic Resistance check with DC 12 or become frightened and receive a -2 penalty to any action against you for 24 hours.',
   'Вы считаетесь на один уровень ниже в таблице социального положения (минимум Ненависть), и члены вашей собственной расы теперь относятся к вам как к терпимому, а не как к равному.',
   'You are considered one level lower in the social standing table (minimum Hatred), and members of your own race now treat you as tolerable, not as an equal.',
   0, 1),
  ('MG002', 'exp_toc', 'minor', 'Зеленый росток', 'Green Thumb',
   'В качестве действия вы можете вырастить небольшое растение из семени. Это позволяет вам выращивать травы и алхимические растения, но не более крупные растения, такие как деревья.',
   'As an action, you can grow a small plant from a seed. This allows you to grow herbs and alchemical plants, but not larger plants like trees.',
   'Любая алхимическая смесь, которую вы создаете с веществом растительного происхождения в качестве одного из ее ингредиентов, дает вам состояние отравления, а также ожидаемый эффект при ее использовании.',
   'Any alchemical mixture you create with a plant-based substance as one of its ingredients gives you a poisoned condition, as well as the expected effect when used.',
   0, 1),
  ('MG003', 'exp_toc', 'minor', 'Крошечная иллюзия', 'Minuscule Illusion',
   'В качестве действия вы можете создать иллюзию в пределах 4 м, которая заполняет куб в 1 м³. Эта иллюзия должна быть простой и только визуальной.',
   'As an action, you can create an illusion within 4m that fills a 1m³ cube. This illusion must be simple and purely visual.',
   'Вы получаете штраф -3 к определению, реальны ли иллюзии или нет.',
   'You receive a -3 penalty to determining if illusions are real or not.',
   0, 1),
  ('MG004', 'exp_toc', 'minor', 'Пигмент', 'Pigment',
   'В качестве действия вы можете сделать отметку рукой на поверхности желаемого цвета, которая при желании может светиться. Светящаяся метка повышает уровень освещенности на 1 в радиусе 4 м от себя (максимум дневной свет). После того, как вы сделали метку, вы можете предпринять другое действие, пока вы находитесь в пределах 4 м, чтобы метка излучала вспышку яркого света в течение одного раунда, после чего она исчезает.',
   'As an action, you can make a mark with your hand on a surface of a desired color, which can glow if desired. A glowing mark increases the light level by 1 in a 4m radius around it (maximum daylight). After you have made the mark, you can take another action while you are within 4m, for the mark to emit a flash of bright light for one round, after which it disappears.',
   'Когда кто-то в пределах 10 м от вас подвергается эффекту магического провала, вы тоже подвергаетесь этому эффекту. Если вы уже страдаете от эффекта магического провала, вы не подвергаетесь второму эффекту.',
   'When someone within 10m of you is subjected to a magic failure effect, you are also subjected to this effect. If you are already suffering from a magic failure effect, you are not subjected to a second effect.',
   0, 1),
  ('MG005', 'exp_toc', 'minor', 'Сильные ноги', 'Strong Legs',
   'В качестве действия вы можете удвоить дальность своего прыжка на 1 раунд.',
   'As an action, you can double your jump distance for 1 round.',
   'Когда вас отбрасывает назад, вы перемещаетесь на 4 м больше, увеличивая возможный урон, получаемый от удара по объекту.',
   'When you are knocked back, you move 4m further, increasing potential damage received from hitting an object.',
   0, 1),
  ('MG006', 'exp_toc', 'minor', 'Успокоить животное', 'Calm Animal',
   'В качестве действия вы можете успокоить зверя, у которого нет среднего или высокого рейтинга угрозы. После этого эффекта зверь считает вас и ваших союзников дружественными и не будет атаковать, если его не спровоцировать.',
   'As an action, you can calm a beast that does not have a medium or high threat rating. After this effect, the beast considers you and your allies friendly and will not attack unless provoked.',
   'Звери со средней или высокой степенью угрозы разъярены вашим присутствием и, если возможно, будут атаковать вас в первую очередь, а не другие цели.',
   'Beasts with a medium or high threat level are enraged by your presence and, if possible, will attack you first rather than other targets.',
   0, 1),
  -- Major Gifts (Великие дары)
  ('MG007', 'exp_toc', 'major', 'Аэрокинез', 'Aerokinesis',
   'В качестве действия полного хода вы можете манипулировать до 5 Веса материала на расстоянии 8 м, как будто вы держите его.',
   'As a full round action, you can manipulate up to 5 ENC of material at a range of 8m as if you were holding it.',
   'Всякий раз, когда вы сбиты с ног или отброшены назад, ваша выносливость также снижается до 10, если только она уже не равна или меньше 10.',
   'Whenever you are knocked prone or knocked back you are also reduced to 10 STA unless you were currently at or below 10 STA.',
   9, 2),
  ('MG008', 'exp_toc', 'major', 'Геокинез', 'Geokinesis',
   'В качестве действия полного раунда вы можете создать сотрясение радиусом 8 м с центром на себе. Любой, кто находится в этой области, должен пройти проверку Атлетики СЛ 14, иначе он упадет в разлом и будет ошеломлен.',
   'As a full round action, you can create a tremor with an 8m radius centered on yourself. Anyone within this area must make a DC:14 Athletics check or fall prone and be staggered.',
   'Если вы попали в состояние ошеломления, вместо этого вы дезориентированы на 1 раунд.',
   'If you would suffer the Staggered condition you are instead Stunned for 1 round.',
   9, 2),
  ('MG009', 'exp_toc', 'major', 'Заточка оружия', 'Weapon Honing',
   'В качестве действия полного хода вы можете добавить 25% шанс кровотечения к оружию, наносящему колющий или рубящий урон.',
   'As a full round action, you can add a 25% Bleed chance to a weapon that deals Piercing or Slashing damage.',
   'Всякий раз, когда у вас есть шанс подвергнуться Кровотечению, вы ему подвергаетесь, несмотря ни на что.',
   'Whenever you have a chance of bleeding, you bleed no matter what.',
   9, 2),
  ('MG010', 'exp_toc', 'major', 'Криокинез', 'Cryokinesis',
   'В качестве действия полного хода вы можете заморозить до 2 м² жидкости или одну цель в пределах 8 метров.',
   'As a full round action, you can freeze up to 2 square meters of liquid or a single target within 8m.',
   'Всякий раз, когда у вас есть шанс быть замороженным, вы подвергаетесь эффекту заморозки. Кроме того, вместо стандартного состояния заморозки вы уменьшаете Скор на 6 и Реа на 4.',
   'Whenever you have a chance of being frozen, you are no matter what. Additionally, instead of the standard Frozen condition you reduce your SPD by 6 and REF by 4.',
   9, 2),
  ('MG011', 'exp_toc', 'major', 'Определение яда', 'Detect Poison',
   'В качестве действия полного хода вы можете почувствовать запах вещества, чтобы определить, было ли оно отравлено.',
   'As a full round action, you can smell a substance to detect whether it has been poisoned.',
   'Всякий раз, когда вы получаете состояния опьянения или отравления, в дополнение вы испытываете тошноту на время действия этих состояний.',
   'Whenever you would gain the Intoxicated or Poisoned conditions, you are additionally Nauseated for the duration of those conditions.',
   9, 2),
  ('MG012', 'exp_toc', 'major', 'Пирокинез', 'Pyrokinesis',
   'В качестве полного хода вы можете зажечь огонь или потушить огонь. Вы можете поджечь один объект или цель в пределах 8 м. Вы не можете поразить себя этой способностью.',
   'As a full round action, you can light a fire or put out a fire. You can light one object or target within 8m on fire. You cannot target yourself with this ability.',
   'Всякий раз, когда у вас есть шанс загореться, вы загораетесь, несмотря ни на что.',
   'Whenever you have a chance of being caught on fire you are caught on fire no matter what.',
   9, 2),
  ('MG013', 'exp_toc', 'major', 'Узреть ауру', 'See Aura',
   'В качестве действия полного хода вы можете видеть ауру всех целей в пределах 8 м от вас. Эта аура говорит вам, каков порог Энергии каждой цели. Это заставит многих людей предположить, что вы маг. Из-за этого ваше социальное положение считается положением мага.',
   'As a full round action, you can see the aura of all targets within 8m of you. This aura tells you what the Vigor Threshold of each target is. This will make many people assume you are a mage. Because of this your Social Standing is considered to be that of a mage.',
   'Вы испускаете ощутимое покалывание, которое предупреждает любого, кто прикоснется к вам, о ваших магических способностях.',
   'You give off a tangible tingle that alerts anyone who touches you to your magical capability.',
   9, 2),
  ('MG014', 'exp_toc', 'major', 'Укрепление', 'Fortify',
   'В качестве действия полного хода вы можете увеличить надежность или ПБ предмета, к которому можно прикоснуться, на 1. Предмет может получить эффект от Укрепления только один раз.',
   'As a full round action, you can increase the Reliability or SP of an item you can touch by 1. An item can only benefit from Fortify once.',
   'Если вы подходите ближе чем на 4 м к любому количеству двимерита, вы теряете весь порог энергии и должны сделать бросок Стойкости со штрафом -3 по таблице эффектов двимерита.',
   'If you come within 4m of any amount of dimeritium you lose all Vigor Threshold and must make an Endurance roll at a -3 against the Dimeritium Effect Table.',
   9, 2)
),
ins_i18n AS (
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT * FROM (
  -- group "Малые дары" / "Minor gifts"
  SELECT ck_id('witcher_cc.magic.gift.group.minor'), 'magic', 'gift_group', 'ru', 'Малые дары'
  UNION ALL
  SELECT ck_id('witcher_cc.magic.gift.group.minor'), 'magic', 'gift_group', 'en', 'Minor gifts'
  UNION ALL
  -- group "Великие дары" / "Major gifts"
  SELECT ck_id('witcher_cc.magic.gift.group.major'), 'magic', 'gift_group', 'ru', 'Великие дары'
  UNION ALL
  SELECT ck_id('witcher_cc.magic.gift.group.major'), 'magic', 'gift_group', 'en', 'Major gifts'
  UNION ALL
  -- description template for view (placeholders: {effect}, {side_effect})
  SELECT ck_id('witcher_cc.magic.gift.description_tpl'), 'magic', 'gift_description_tpl', 'ru', 'Эффект: {effect}' || E'\n' || 'Побочный эффект: {side_effect}'
  UNION ALL
  SELECT ck_id('witcher_cc.magic.gift.description_tpl'), 'magic', 'gift_description_tpl', 'en', 'Effect: {effect}' || E'\n' || 'Side effect: {side_effect}'
  UNION ALL
  -- action cost by group (column "Затраты": Действие / Действие полного хода)
  SELECT ck_id('witcher_cc.magic.gift.action_cost.minor'), 'magic', 'gift_action_cost', 'ru', 'Действие'
  UNION ALL
  SELECT ck_id('witcher_cc.magic.gift.action_cost.minor'), 'magic', 'gift_action_cost', 'en', 'Action'
  UNION ALL
  SELECT ck_id('witcher_cc.magic.gift.action_cost.major'), 'magic', 'gift_action_cost', 'ru', 'Действие полного хода'
  UNION ALL
  SELECT ck_id('witcher_cc.magic.gift.action_cost.major'), 'magic', 'gift_action_cost', 'en', 'Full round action'
  UNION ALL
  -- names
  SELECT ck_id('witcher_cc.magic.gift.name.'||rd.mg_id), 'magic', 'gift_names', 'ru', rd.name_ru
    FROM raw_data rd
   WHERE nullif(rd.name_ru,'') IS NOT NULL
  UNION ALL
  SELECT ck_id('witcher_cc.magic.gift.name.'||rd.mg_id), 'magic', 'gift_names', 'en', rd.name_en
    FROM raw_data rd
   WHERE nullif(rd.name_en,'') IS NOT NULL
  UNION ALL
  -- effects
  SELECT ck_id('witcher_cc.magic.gift.effect.'||rd.mg_id), 'magic', 'gift_effects', 'ru', rd.effect_ru
    FROM raw_data rd
   WHERE nullif(rd.effect_ru,'') IS NOT NULL
  UNION ALL
  SELECT ck_id('witcher_cc.magic.gift.effect.'||rd.mg_id), 'magic', 'gift_effects', 'en', rd.effect_en
    FROM raw_data rd
   WHERE nullif(rd.effect_en,'') IS NOT NULL
  UNION ALL
  -- side_effects
  SELECT ck_id('witcher_cc.magic.gift.side_effect.'||rd.mg_id), 'magic', 'gift_side_effects', 'ru', rd.side_effect_ru
    FROM raw_data rd
   WHERE nullif(rd.side_effect_ru,'') IS NOT NULL
  UNION ALL
  SELECT ck_id('witcher_cc.magic.gift.side_effect.'||rd.mg_id), 'magic', 'gift_side_effects', 'en', rd.side_effect_en
    FROM raw_data rd
   WHERE nullif(rd.side_effect_en,'') IS NOT NULL
) foo
ON CONFLICT (id, lang) DO UPDATE
  SET text = EXCLUDED.text
)
INSERT INTO wcc_magic_gifts (
  mg_id, dlc_dlc_id,
  group_id, name_id, effect_id, side_effect_id,
  dc, vigor_cost
)
SELECT rd.mg_id
     , rd.dlc_dlc_id
     , ck_id('witcher_cc.magic.gift.group.'||rd.group_key) AS group_id
     , ck_id('witcher_cc.magic.gift.name.'||rd.mg_id) AS name_id
     , ck_id('witcher_cc.magic.gift.effect.'||rd.mg_id) AS effect_id
     , ck_id('witcher_cc.magic.gift.side_effect.'||rd.mg_id) AS side_effect_id
     , rd.dc
     , rd.vigor_cost
  FROM raw_data rd
ON CONFLICT (mg_id) DO UPDATE
SET
  dlc_dlc_id = EXCLUDED.dlc_dlc_id,
  group_id = EXCLUDED.group_id,
  name_id = EXCLUDED.name_id,
  effect_id = EXCLUDED.effect_id,
  side_effect_id = EXCLUDED.side_effect_id,
  dc = EXCLUDED.dc,
  vigor_cost = EXCLUDED.vigor_cost;
