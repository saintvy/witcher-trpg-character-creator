\echo '015_past_family_fate.sql'
-- Узел: Судьба семьи

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_family_fate' AS qu_id
                , 'questions' AS entity
                , 'single'::question_type AS qtype)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| v.entity_field) AS id
           , meta.entity, v.entity_field, v.lang, v.text
        FROM (VALUES
                ('ru', 'Время понять что случилось с вашей семьей.', 'body'),
                ('en', 'Time to determine what happened to your family.', 'body')
             ) AS v(lang, text, entity_field)
        CROSS JOIN meta
      RETURNING id AS body_id
)
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
  SELECT meta.qu_id
       , meta.su_su_id
       , NULL
       , (SELECT DISTINCT body_id FROM ins_body)
       , meta.qtype
       , jsonb_build_object(
           'dice', 'd0',
           'path', jsonb_build_array(
             ck_id('witcher_cc.hierarchy.family')::text,
             ck_id('witcher_cc.hierarchy.family_fate')::text
           )
         )
     FROM meta;
	   
-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_family_fate' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
    SELECT 'ru' lang, raw_data_ru.*
      FROM (VALUES
              (1, 'Из-за войн ваша семья была вынуждена разделиться, и вы не знаете, где большинство родственников.', 1),
              (1, 'Ваша семья обращена в рабство за преступление против Империи или по ложному обвинению. Только вам удалось сбежать.', 2),
              (1, 'Считается, что ваша семья симпатизирует людям, поэтому ваших родственников не очень любят на родине.', 3),
              
              (2, 'Вашу семью посадили в тюрьму за преступление или по ложному обвинению. Вы единственный, кому удалось сбежать. И теперь вы хотите освободить родных… или не хотите?', 1),
              (2, 'Вашу семью изгнали в пустыню Корат, и, скорее всего, большую часть юности вы провели в попытках выжить в этих суровых условиях.', 2),
              (2, 'Ваши родные стали изгоями из-за того, что не согласны с мнением большинства, и теперь с вами или со всей вашей семьёй не разговаривают.', 3),
              
              (3, 'Дом вашей семьи проклят. Либо на полях нет урожая, либо по комнатам бродят духи. Оставаться там слишком опасно.', 1),
              (3, 'Вашу семью убил мятежный маг, который то ли затаил зло на вашу семью, то ли просто хотел крови. Так или иначе, вы одиноки.', 2),
              (3, 'Ваша семья погибла во время войны с Нильфгаардом. Возможно, они сражались на войне, а может, просто были её жертвами.', 3),
              
              (4, 'Из-за войн ваша семья оказалась в плачевном положении. Чтобы выжить, им пришлось встать на путь преступности.', 1),
              (4, 'Вы не знаете, где ваши родственники. Однажды они просто взяли и ушли.', 2),
              (4, 'Ваша семья не первый век в ссоре с другой семьёй. Возможно, вы даже не помните, с чего началась эта вражда.', 3),
              
              (5, 'Ваша семья в долгах из-за азартных игр или займов. Вам очень нужны деньги.', 1),
              (5, 'Вашу семью казнили за государственную измену. Только вам удалось избежать столь мрачной участи.', 2),
              (5, 'По какой-то причине вашу семью лишили всех титулов. Вас выселили из дома, и вы еле сводили концы с концами.', 3),
              
              (6, 'Ваша семья в ссоре с другой семьёй. Возможно, вы даже не помните, с чего всё началось.', 1),
              (6, 'По какой-то причине вашу семью лишили всех титулов. Вас выселили из дома, и вам пришлось выживать среди простолюдинов.', 2),
              (6, 'Когда вы были совсем юны, ваша семья совершала набеги на человеческие поселения, чтобы добыть еду, а, возможно, отомстить людям.', 3),
              
              (7, 'По какой-то причине вашу семью ненавидят в родном городе, и никто не хочет иметь дела с вашими родственниками.', 1),
              (7, 'Ваш родственник-маг запятнал имя семьи, выставляя напоказ свой магический дар, словно какой-то северянин.', 2),
              (7, 'В доме вашей семьи поселилось привидение. Скорее всего, причина в том, что в этом доме многие погибли во время войны против людей.', 3),
              
              (8, 'Однажды вашу семью дочиста ограбила банда разбойников. Всех ваших родных зарезали, вы единственный выживший.', 1),
              (8, 'Вы очернили свою семью перед Империей. То, что вы сделали (или не смогли сделать), запятнало ваше имя и навредило вашей семье.', 2),
              (8, 'Ваша семья разделилась из-за человека, состоящего в браке с вашим братом, сестрой или другим родственником. Часть семьи принимает этого человека, а другая — ненавидит.', 3),
              
              (9, 'У вашей семьи есть зловещая тайна. Если о ней кто-то узнает, вам конец. Вы можете придумать тайну сами или оставить это на усмотрение ведущего.', 1),
              (9, 'У вашей семьи есть зловещая тайна. Если о ней кто-то узнает, конец. Вы должны защищать эту тайну даже ценой своей жизни.', 2),
              (9, 'Ваших родных убили люди, посчитав их скоя''таэлями. Возможно, их попросту зарезали или повесили без суда и следствия.', 3),
              
              (10, 'Члены вашей семьи презирают друг друга. Все, кто был рядом, пока вы росли, не говорят друг с другом, и вы можете считать себя счастливчиком, если брат или сестра с вами хотя бы поздоровается.', 1),
              (10, 'Вашу семью убили. Возможно, они встали у кого-то на пути или же через них пытались подобраться к кому-то более могущественному. Так или иначе, ваши родные мертвы.', 2),
              (10, 'Один из ваших предков — известный предатель. Из-за этого другие представители Старших Народов относятся к вашей семье предвзято, и жить среди соплеменников вам нелегко.', 3)
              ) AS raw_data_ru(num, text, group_id)
    UNION ALL
    SELECT 'en' lang, raw_data_en.*
      FROM (VALUES
              (1, 'Your family was scattered to the winds by the wars and you have no idea where most of them are.', 1),
              (1, 'Your family was indentured for crimes against the Empire or on trumped-up charges. Only you escaped.', 2),
              (1, 'Your family were marked as human sympathizers and are not particularly loved in their homeland.', 3),
              
              (2, 'Your family was imprisoned for crimes or on trumped-up charges. You were the only one to escape. You may want to free them...or maybe not.', 1),
              (2, 'Your family was exiled to the Korath Desert and you likely spent most of your early life struggling to survive in the deadly wasteland.', 2),
              (2, 'Your family was ostracized for dissenting opinions and now people won''t socialize with you or your family at all.', 3),
              
              (3, 'Your family house was cursed and now either crops won''t grow or specters roam the halls. It became too dangerous for you to stay in this home.', 1),
              (3, 'Your family was killed by a rogue mage who either had a vendetta against your family, or just wanted blood. Either way, you are alone.', 2),
              (3, 'Your family died in the Northern Wars. They may have actually fought in the war, or were casualties of war who just happened to get in the way.', 3),
              
              (4, 'With so many wars your family''s livelihood was destroyed. Your family turned to crime to survive.', 1),
              (4, 'Your family disappeared and you have no idea where they went. One day they just up and left.', 2),
              (4, 'Your family has been caught in a feud for centuries. You may not remember why this feud started, but it is dire.', 3),
              
              (5, 'Your family accumulated a huge debt through gambling or favors from others. You need money desperately.', 1),
              (5, 'Your family was executed for treason against the Empire. You were the only one to escape this fate.', 2),
              (5, 'Your family was stripped of its title for some reason. You were evicted from your home and left scrambling to survive.', 3),
              
              (6, 'Your family has fallen into a feud with another family. You may not even remember why this feud started in the first place.', 1),
              (6, 'Your family was stripped of its title for some reason. You were evicted from your home and left scrambling to survive among the un-washed masses.', 2),
              (6, 'Your family turned to raiding human settlements early in your life to get food and perhaps strike back at the humans.', 3),
              
              (7, 'Due to some action or inaction your family has become hated in your home town and now no one there wants to have anything to do with them.', 1),
              (7, 'Your family name was tarnished by a magic relative who flaunted their magical gift disgracefully like a Northern mage.', 2),
              (7, 'Your family house is haunted. Most likely this is because your home was the site of many, many deaths during the war against humans.', 3),
              
              (8, 'One day everything you had was ripped away by a bandit mob. Your family was massacred, leaving you entirely alone.', 1),
              (8, 'You disgraced your family in the eyes of the Empire. Something you did or failed to do has ruined your personal name and harmed your family.', 2),
              (8, 'Your family has been split by a human in-law who was brought into your family by a sibling or relative. Some of your family like them and some hate them.', 3),
              
              (9, 'Your family has a deep, dark secret that if discovered would ruin you all completely. You can decide what this secret is, or the Game Master can decide.', 1),
              (9, 'Your family has a deep, dark secret that if discovered would destroy them and their name forever. You must protect this secret with your life.', 2),
              (9, 'Your family was killed by humans who thought they were Scoia''tael. They may have been slaughtered or hung with no court proceedings or trials.', 3),
              
              (10, 'Your family has come to despise each other. No one you grew up with will talk with each other any more and you''re lucky to get a passing hello from your siblings.', 1),
              (10, 'Your family was assassinated. They may have been in the way of someone''s plan or they may have been used to get at someone more powerful. Either way, your family is gone now.', 2),
              (10, 'Your family is descended from an infamous traitor. It taints your family''s interactions with others of the elder races and has made living in the elderland difficult.', 3)
              ) AS raw_data_en(num, text, group_id)
)
, ins_label AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
      SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*vals.group_id+vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS id
           , meta.entity, meta.entity_field, vals.lang, vals.text
        FROM vals
        CROSS JOIN meta
)
, rules_vals(group_id, body, name, id) AS ( VALUES (1,
'{
  "or": [
    { "!!": { "var": "answers.byAnswer.wcc_past_homeland_human_o0101" } },
    { "!!": { "var": "answers.byAnswer.wcc_past_homeland_human_o0102" } },
    { "!!": { "var": "answers.byAnswer.wcc_past_homeland_human_o0103" } },
    { "!!": { "var": "answers.byAnswer.wcc_past_homeland_human_o0104" } },
    { "!!": { "var": "answers.byAnswer.wcc_past_homeland_human_o0105" } },
    { "!!": { "var": "answers.byAnswer.wcc_past_homeland_human_o0106" } },
    { "!!": { "var": "answers.byAnswer.wcc_past_homeland_human_o0107" } },
    { "!!": { "var": "answers.byAnswer.wcc_past_homeland_human_o0108" } },
    { "!!": { "var": "answers.byAnswer.wcc_past_homeland_human_o0109" } },
    { "!!": { "var": "answers.byAnswer.wcc_past_homeland_human_o0110" } }
  ]
}'::jsonb, 'is_nordman', gen_random_uuid())
                                               , (2,
'{
  "or": [
    { "!!": { "var": "answers.byAnswer.wcc_past_homeland_human_o0201" } },
    { "!!": { "var": "answers.byAnswer.wcc_past_homeland_human_o0301" } },
    { "!!": { "var": "answers.byAnswer.wcc_past_homeland_human_o0302" } },
    { "!!": { "var": "answers.byAnswer.wcc_past_homeland_human_o0303" } },
    { "!!": { "var": "answers.byAnswer.wcc_past_homeland_human_o0304" } },
    { "!!": { "var": "answers.byAnswer.wcc_past_homeland_human_o0305" } },
    { "!!": { "var": "answers.byAnswer.wcc_past_homeland_human_o0306" } },
    { "!!": { "var": "answers.byAnswer.wcc_past_homeland_human_o0307" } },
    { "!!": { "var": "answers.byAnswer.wcc_past_homeland_human_o0308" } },
    { "!!": { "var": "answers.byAnswer.wcc_past_homeland_human_o0309" } },
    { "!!": { "var": "answers.byAnswer.wcc_past_homeland_human_o0310" } }
  ]
}'::jsonb, 'is_nilfgaardian', gen_random_uuid())
                                               , (3,
'{
  "or": [
    { "!!": { "var": "answers.byAnswer.wcc_past_homeland_elders_o01" } },
    { "!!": { "var": "answers.byAnswer.wcc_past_homeland_elders_o02" } },
    { "!!": { "var": "answers.byAnswer.wcc_past_elf_q1_o01" } },
    { "!!": { "var": "answers.byAnswer.wcc_past_dwarf_q1_o01" } }
  ]
}'::jsonb, 'is_elderland', gen_random_uuid())
),
ins_rules AS (
  INSERT INTO rules(ru_id, name, body) SELECT r.id, r.name, r.body FROM rules_vals r
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id)
  SELECT 'wcc_past_family_fate_o' || to_char(vals.group_id, 'FM9900') || to_char(vals.num, 'FM9900') AS an_id,
         meta.su_su_id,
         meta.qu_id,
         ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*vals.group_id+vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field) AS label,
         vals.num AS sort_order,
         rules_vals.id AS visible_ru_ru_id
    FROM vals
    CROSS JOIN meta
    JOIN rules_vals ON rules_vals.group_id = vals.group_id
  ON CONFLICT (an_id) DO NOTHING;

-- Эффекты для всех вариантов ответов
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_family_fate' AS qu_id
                , 'answer_options' AS entity
                , 'label' AS entity_field)
, vals AS (
    SELECT 'ru' lang, raw_data_ru.*
      FROM (VALUES
              (1, 1), (1, 2), (1, 3),
              (2, 1), (2, 2), (2, 3),
              (3, 1), (3, 2), (3, 3),
              (4, 1), (4, 2), (4, 3),
              (5, 1), (5, 2), (5, 3),
              (6, 1), (6, 2), (6, 3),
              (7, 1), (7, 2), (7, 3),
              (8, 1), (8, 2), (8, 3),
              (9, 1), (9, 2), (9, 3),
              (10, 1), (10, 2), (10, 3)
              ) AS raw_data_ru(num, group_id)
    UNION ALL
    SELECT 'en' lang, raw_data_en.*
      FROM (VALUES
              (1, 1), (1, 2), (1, 3),
              (2, 1), (2, 2), (2, 3),
              (3, 1), (3, 2), (3, 3),
              (4, 1), (4, 2), (4, 3),
              (5, 1), (5, 2), (5, 3),
              (6, 1), (6, 2), (6, 3),
              (7, 1), (7, 2), (7, 3),
              (8, 1), (8, 2), (8, 3),
              (9, 1), (9, 2), (9, 3),
              (10, 1), (10, 2), (10, 3)
              ) AS raw_data_en(num, group_id)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT 'character', 'wcc_past_family_fate_o' || to_char(vals.group_id, 'FM9900') || to_char(vals.num, 'FM9900'),
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var','characterRaw.lore.family_fate'),
      jsonb_build_object('i18n_uuid', ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(100*vals.group_id+vals.num, 'FM0000') ||'.'|| meta.entity ||'.'|| meta.entity_field)::text)
    )
  )
FROM vals
CROSS JOIN meta;
  
-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id)
  SELECT 'wcc_past_family', 'wcc_past_family_fate', 'wcc_past_family_o02';