\echo '018_past_mage_school.sql'

-- Иерархия: Школа мага
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
VALUES
  (ck_id('witcher_cc.hierarchy.mage_school'), 'hierarchy', 'path', 'ru', 'Школа мага'),
  (ck_id('witcher_cc.hierarchy.mage_school'), 'hierarchy', 'path', 'en', 'Mage school')
ON CONFLICT (id, lang) DO NOTHING;

-- Правила видимости для школ мага по родине и полу
WITH
north_ids AS (
  SELECT unnest(ARRAY[
    'wcc_past_homeland_mage_o01','wcc_past_homeland_mage_o02','wcc_past_homeland_mage_o03','wcc_past_homeland_mage_o04',
    'wcc_past_homeland_mage_o05','wcc_past_homeland_mage_o06','wcc_past_homeland_mage_o07','wcc_past_homeland_mage_o08',
    'wcc_past_homeland_mage_o09','wcc_past_homeland_mage_o10','wcc_past_homeland_mage_o11'
  ]) AS an_id
),
nilf_ids AS (
  SELECT unnest(ARRAY[
    'wcc_past_homeland_mage_o12','wcc_past_homeland_mage_o13','wcc_past_homeland_mage_o14','wcc_past_homeland_mage_o15',
    'wcc_past_homeland_mage_o16','wcc_past_homeland_mage_o17','wcc_past_homeland_mage_o18','wcc_past_homeland_mage_o19',
    'wcc_past_homeland_mage_o20','wcc_past_homeland_mage_o21','wcc_past_homeland_mage_o22','wcc_past_homeland_mage_o23',
    'wcc_past_homeland_mage_o24'
  ]) AS an_id
),
elder_ids AS (
  SELECT unnest(ARRAY['wcc_past_homeland_mage_o25','wcc_past_homeland_mage_o26']) AS an_id
),
homeland_exprs AS (
  SELECT
    jsonb_build_object(
      'or',
      (SELECT jsonb_agg(
        jsonb_build_object(
          'in',
          jsonb_build_array(
            n.an_id,
            jsonb_build_object('var', jsonb_build_array('answers.byQuestion.wcc_past_homeland_mage', jsonb_build_array()))
          )
        )
      ) FROM north_ids n)
    ) AS north_expr,
    jsonb_build_object(
      'or',
      (SELECT jsonb_agg(
        jsonb_build_object(
          'in',
          jsonb_build_array(
            n.an_id,
            jsonb_build_object('var', jsonb_build_array('answers.byQuestion.wcc_past_homeland_mage', jsonb_build_array()))
          )
        )
      ) FROM nilf_ids n)
    ) AS nilf_expr,
    jsonb_build_object(
      'or',
      (SELECT jsonb_agg(
        jsonb_build_object(
          'in',
          jsonb_build_array(
            n.an_id,
            jsonb_build_object('var', jsonb_build_array('answers.byQuestion.wcc_past_homeland_mage', jsonb_build_array()))
          )
        )
      ) FROM elder_ids n)
    ) AS elder_expr
),
sex_exprs AS (
  SELECT
    jsonb_build_object(
      '==',
      jsonb_build_array(jsonb_build_object('var', 'characterRaw.logicFields.sex'), 'Female')
    ) AS female_expr,
    jsonb_build_object(
      '==',
      jsonb_build_array(jsonb_build_object('var', 'characterRaw.logicFields.sex'), 'Male')
    ) AS male_expr
)
INSERT INTO rules (ru_id, name, body)
SELECT
  ck_id('witcher_cc.rules.is_mage_school_north_female') AS ru_id,
  'is_mage_school_north_female' AS name,
  jsonb_build_object('and', jsonb_build_array(h.north_expr, s.female_expr)) AS body
FROM homeland_exprs h
CROSS JOIN sex_exprs s
UNION ALL
SELECT
  ck_id('witcher_cc.rules.is_mage_school_north_male') AS ru_id,
  'is_mage_school_north_male' AS name,
  jsonb_build_object('and', jsonb_build_array(h.north_expr, s.male_expr)) AS body
FROM homeland_exprs h
CROSS JOIN sex_exprs s
UNION ALL
SELECT
  ck_id('witcher_cc.rules.is_mage_school_nilfgaard') AS ru_id,
  'is_mage_school_nilfgaard' AS name,
  h.nilf_expr AS body
FROM homeland_exprs h
UNION ALL
SELECT
  ck_id('witcher_cc.rules.is_mage_school_elderlands') AS ru_id,
  'is_mage_school_elderlands' AS name,
  h.elder_expr AS body
FROM homeland_exprs h
ON CONFLICT (ru_id) DO UPDATE SET body = EXCLUDED.body;

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_mage_school' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
              ('ru', 'Строго следуя правилам, ваша школа определяется на основании родины и пола (в случае Северных королевств), но вы также можете выбрать любую школу по своему вкусу. Учтите, однако, что вам потребуется обосновать несоответствие школы и родины, связав его с каким-нибудь событием из прошлого вашего персонажа.'),
              ('en', 'Strictly by the rules, your school is determined by your homeland and, in the case of the Northern Kingdoms, by your sex. You can also choose any school you prefer. Keep in mind, however, that if your school does not match your homeland, you should justify it with an event from your character''s past.')
           ) AS v(lang, text)
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
)
, c_vals(lang, num, text) AS (
    VALUES
      ('ru', 1, 'Шанс'),
      ('ru', 2, 'Имя школы'),
      ('ru', 3, 'Эффект'),
      ('en', 1, 'Chance'),
      ('en', 2, 'School'),
      ('en', 3, 'Effect')
)
, ins_c AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| to_char(c_vals.num, 'FM9900') ||'.'|| meta.entity ||'.column_name') AS id
         , meta.entity, 'column_name', c_vals.lang, c_vals.text
      FROM c_vals
      CROSS JOIN meta
    ON CONFLICT (id, lang) DO NOTHING
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
         'path', jsonb_build_array(
           ck_id('witcher_cc.hierarchy.identity')::text,
           ck_id('witcher_cc.hierarchy.mage_school')::text
         )
       )
  FROM meta
ON CONFLICT (qu_id) DO NOTHING;

-- Ответы
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_mage_school' AS qu_id
                , 'answer_options' AS entity)
, raw_data AS (
  SELECT 'ru' AS lang, raw_ru.*
    FROM (VALUES
      ( 1, 'aretuza',  'Аретуза',                       '<b>Исток Аретузы</b><br>Потратив 10 дополнительных Вын в свой ход, вы можете повысить порог энергии на 2 на время этого хода. Это увеличение суммируется с предметами фокуса.', 1.0, 'is_mage_school_north_female'),
      ( 2, 'ban_ard',  'Бан Ард',                       '<b>Косвенный контроль Бан Арда</b><br>Когда вы страдаете от магического провала, вы можете пожертвовать 10 Вын, чтобы уменьшить результат провала на 5 (минимум 1).', 0.0, 'is_mage_school_north_female'),
      ( 3, 'minor',    'Малая Академия',               '<b>Универсальный заклинатель Малой академии</b><br>Потратив 10 дополнительных Вын, когда вы произносите заклинание, вы можете либо добавить +4 м к дальности заклинания, либо +2 раунда продолжительности к неподдерживаемым заклинаниям.', 0.0, 'is_mage_school_north_female'),
      ( 4, 'gweison',  'Гвейсон Хайль',                '<b>Устойчивость Гвейсон Хайль</b><br>При контакте с димеритом вы можете потратить 10 Вын, чтобы получить +3 к проверке выносливости, чтобы сопротивляться эффектам.', 0.0, 'is_mage_school_north_female'),
      ( 5, 'imperial', 'Имперская Магическая Академия','<b>Устойчивость Гвейсон Хайль</b><br>При контакте с димеритом вы можете потратить 10 Вын, чтобы получить +3 к проверке выносливости, чтобы сопротивляться эффектам.', 0.0, 'is_mage_school_north_female'),

      ( 6, 'aretuza',  'Аретуза',                       '<b>Исток Аретузы</b><br>Потратив 10 дополнительных Вын в свой ход, вы можете повысить порог энергии на 2 на время этого хода. Это увеличение суммируется с предметами фокуса.', 0.0, 'is_mage_school_north_male'),
      ( 7, 'ban_ard',  'Бан Ард',                       '<b>Косвенный контроль Бан Арда</b><br>Когда вы страдаете от магического провала, вы можете пожертвовать 10 Вын, чтобы уменьшить результат провала на 5 (минимум 1).', 1.0, 'is_mage_school_north_male'),
      ( 8, 'minor',    'Малая Академия',               '<b>Универсальный заклинатель Малой академии</b><br>Потратив 10 дополнительных Вын, когда вы произносите заклинание, вы можете либо добавить +4 м к дальности заклинания, либо +2 раунда продолжительности к неподдерживаемым заклинаниям.', 0.0, 'is_mage_school_north_male'),
      ( 9, 'gweison',  'Гвейсон Хайль',                '<b>Устойчивость Гвейсон Хайль</b><br>При контакте с димеритом вы можете потратить 10 Вын, чтобы получить +3 к проверке выносливости, чтобы сопротивляться эффектам.', 0.0, 'is_mage_school_north_male'),
      (10, 'imperial', 'Имперская Магическая Академия','<b>Устойчивость Гвейсон Хайль</b><br>При контакте с димеритом вы можете потратить 10 Вын, чтобы получить +3 к проверке выносливости, чтобы сопротивляться эффектам.', 0.0, 'is_mage_school_north_male'),

      (11, 'aretuza',  'Аретуза',                       '<b>Исток Аретузы</b><br>Потратив 10 дополнительных Вын в свой ход, вы можете повысить порог энергии на 2 на время этого хода. Это увеличение суммируется с предметами фокуса.', 0.0, 'is_mage_school_nilfgaard'),
      (12, 'ban_ard',  'Бан Ард',                       '<b>Косвенный контроль Бан Арда</b><br>Когда вы страдаете от магического провала, вы можете пожертвовать 10 Вын, чтобы уменьшить результат провала на 5 (минимум 1).', 0.0, 'is_mage_school_nilfgaard'),
      (13, 'minor',    'Малая Академия',               '<b>Универсальный заклинатель Малой академии</b><br>Потратив 10 дополнительных Вын, когда вы произносите заклинание, вы можете либо добавить +4 м к дальности заклинания, либо +2 раунда продолжительности к неподдерживаемым заклинаниям.', 0.0, 'is_mage_school_nilfgaard'),
      (14, 'gweison',  'Гвейсон Хайль',                '<b>Устойчивость Гвейсон Хайль</b><br>При контакте с димеритом вы можете потратить 10 Вын, чтобы получить +3 к проверке выносливости, чтобы сопротивляться эффектам.', 0.5, 'is_mage_school_nilfgaard'),
      (15, 'imperial', 'Имперская Магическая Академия','<b>Устойчивость Гвейсон Хайль</b><br>При контакте с димеритом вы можете потратить 10 Вын, чтобы получить +3 к проверке выносливости, чтобы сопротивляться эффектам.', 0.5, 'is_mage_school_nilfgaard'),

      (16, 'aretuza',  'Аретуза',                       '<b>Исток Аретузы</b><br>Потратив 10 дополнительных Вын в свой ход, вы можете повысить порог энергии на 2 на время этого хода. Это увеличение суммируется с предметами фокуса.', 0.0, 'is_mage_school_elderlands'),
      (17, 'ban_ard',  'Бан Ард',                       '<b>Косвенный контроль Бан Арда</b><br>Когда вы страдаете от магического провала, вы можете пожертвовать 10 Вын, чтобы уменьшить результат провала на 5 (минимум 1).', 0.0, 'is_mage_school_elderlands'),
      (18, 'minor',    'Малая Академия',               '<b>Универсальный заклинатель Малой академии</b><br>Потратив 10 дополнительных Вын, когда вы произносите заклинание, вы можете либо добавить +4 м к дальности заклинания, либо +2 раунда продолжительности к неподдерживаемым заклинаниям.', 1.0, 'is_mage_school_elderlands'),
      (19, 'gweison',  'Гвейсон Хайль',                '<b>Устойчивость Гвейсон Хайль</b><br>При контакте с димеритом вы можете потратить 10 Вын, чтобы получить +3 к проверке выносливости, чтобы сопротивляться эффектам.', 0.0, 'is_mage_school_elderlands'),
      (20, 'imperial', 'Имперская Магическая Академия','<b>Устойчивость Гвейсон Хайль</b><br>При контакте с димеритом вы можете потратить 10 Вын, чтобы получить +3 к проверке выносливости, чтобы сопротивляться эффектам.', 0.0, 'is_mage_school_elderlands')
    ) AS raw_ru(num, school_key, school_name, perk_html, probability, rule_name)
  UNION ALL
  SELECT 'en' AS lang, raw_en.*
    FROM (VALUES
      ( 1, 'aretuza',  'Aretuza',                 '<b>Aretuza Wellspring</b><br>By spending 10 extra STA on your turn, you can raise your Vigor Threshold by 2 for the duration of that turn. This increase stacks with Focus Items.', 1.0, 'is_mage_school_north_female'),
      ( 2, 'ban_ard',  'Ban Ard',                 '<b>Ban Ard Controlled Collateral</b><br>When you suffer a Magical Fumble, you can sacrifice 10 STA to lower the amount fumbled by 5 (minimum 1).', 0.0, 'is_mage_school_north_female'),
      ( 3, 'minor',    'Minor Academia',          '<b>Minor Academia Versatile Caster</b><br>By spending 10 extra STA when you cast a spell, you can either add +4m of range to a spell, +2 Rounds of duration to a Non-Active.', 0.0, 'is_mage_school_north_female'),
      ( 4, 'gweison',  'Gweison Haul',            '<b>Gweison Haul Tolerance</b><br>When coming in contact with dimeritium, you can spend 10 STA to give yourself a +3 to your Endurance check to resist the effects.', 0.0, 'is_mage_school_north_female'),
      ( 5, 'imperial', 'Imperial Magic Academy',  '<b>Gweison Haul Tolerance</b><br>When coming in contact with dimeritium, you can spend 10 STA to give yourself a +3 to your Endurance check to resist the effects.', 0.0, 'is_mage_school_north_female'),

      ( 6, 'aretuza',  'Aretuza',                 '<b>Aretuza Wellspring</b><br>By spending 10 extra STA on your turn, you can raise your Vigor Threshold by 2 for the duration of that turn. This increase stacks with Focus Items.', 0.0, 'is_mage_school_north_male'),
      ( 7, 'ban_ard',  'Ban Ard',                 '<b>Ban Ard Controlled Collateral</b><br>When you suffer a Magical Fumble, you can sacrifice 10 STA to lower the amount fumbled by 5 (minimum 1).', 1.0, 'is_mage_school_north_male'),
      ( 8, 'minor',    'Minor Academia',          '<b>Minor Academia Versatile Caster</b><br>By spending 10 extra STA when you cast a spell, you can either add +4m of range to a spell, +2 Rounds of duration to a Non-Active.', 0.0, 'is_mage_school_north_male'),
      ( 9, 'gweison',  'Gweison Haul',            '<b>Gweison Haul Tolerance</b><br>When coming in contact with dimeritium, you can spend 10 STA to give yourself a +3 to your Endurance check to resist the effects.', 0.0, 'is_mage_school_north_male'),
      (10, 'imperial', 'Imperial Magic Academy',  '<b>Gweison Haul Tolerance</b><br>When coming in contact with dimeritium, you can spend 10 STA to give yourself a +3 to your Endurance check to resist the effects.', 0.0, 'is_mage_school_north_male'),

      (11, 'aretuza',  'Aretuza',                 '<b>Aretuza Wellspring</b><br>By spending 10 extra STA on your turn, you can raise your Vigor Threshold by 2 for the duration of that turn. This increase stacks with Focus Items.', 0.0, 'is_mage_school_nilfgaard'),
      (12, 'ban_ard',  'Ban Ard',                 '<b>Ban Ard Controlled Collateral</b><br>When you suffer a Magical Fumble, you can sacrifice 10 STA to lower the amount fumbled by 5 (minimum 1).', 0.0, 'is_mage_school_nilfgaard'),
      (13, 'minor',    'Minor Academia',          '<b>Minor Academia Versatile Caster</b><br>By spending 10 extra STA when you cast a spell, you can either add +4m of range to a spell, +2 Rounds of duration to a Non-Active.', 0.0, 'is_mage_school_nilfgaard'),
      (14, 'gweison',  'Gweison Haul',            '<b>Gweison Haul Tolerance</b><br>When coming in contact with dimeritium, you can spend 10 STA to give yourself a +3 to your Endurance check to resist the effects.', 0.5, 'is_mage_school_nilfgaard'),
      (15, 'imperial', 'Imperial Magic Academy',  '<b>Gweison Haul Tolerance</b><br>When coming in contact with dimeritium, you can spend 10 STA to give yourself a +3 to your Endurance check to resist the effects.', 0.5, 'is_mage_school_nilfgaard'),

      (16, 'aretuza',  'Aretuza',                 '<b>Aretuza Wellspring</b><br>By spending 10 extra STA on your turn, you can raise your Vigor Threshold by 2 for the duration of that turn. This increase stacks with Focus Items.', 0.0, 'is_mage_school_elderlands'),
      (17, 'ban_ard',  'Ban Ard',                 '<b>Ban Ard Controlled Collateral</b><br>When you suffer a Magical Fumble, you can sacrifice 10 STA to lower the amount fumbled by 5 (minimum 1).', 0.0, 'is_mage_school_elderlands'),
      (18, 'minor',    'Minor Academia',          '<b>Minor Academia Versatile Caster</b><br>By spending 10 extra STA when you cast a spell, you can either add +4m of range to a spell, +2 Rounds of duration to a Non-Active.', 1.0, 'is_mage_school_elderlands'),
      (19, 'gweison',  'Gweison Haul',            '<b>Gweison Haul Tolerance</b><br>When coming in contact with dimeritium, you can spend 10 STA to give yourself a +3 to your Endurance check to resist the effects.', 0.0, 'is_mage_school_elderlands'),
      (20, 'imperial', 'Imperial Magic Academy',  '<b>Gweison Haul Tolerance</b><br>When coming in contact with dimeritium, you can spend 10 STA to give yourself a +3 to your Endurance check to resist the effects.', 0.0, 'is_mage_school_elderlands')
    ) AS raw_en(num, school_key, school_name, perk_html, probability, rule_name)
)
, ins_i18n AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM00') ||'.'|| meta.entity ||'.label') AS id
       , meta.entity, 'label', raw_data.lang
       , '<td style="color: grey;">' || to_char(raw_data.probability * 100, 'FM990.00') || '%</td><td>' || raw_data.school_name || '</td><td>' || raw_data.perk_html || '</td>'
    FROM raw_data
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO answer_options (an_id, su_su_id, qu_qu_id, label, sort_order, visible_ru_ru_id, metadata)
SELECT meta.qu_id || '_o' || to_char(raw_data.num, 'FM00') AS an_id
     , meta.su_su_id
     , meta.qu_id
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'_o'|| to_char(raw_data.num, 'FM00') ||'.'|| meta.entity ||'.label') AS label
     , raw_data.num
     , (SELECT ru_id FROM rules WHERE name = raw_data.rule_name ORDER BY ru_id LIMIT 1) AS visible_ru_ru_id
     , jsonb_build_object('probability', raw_data.probability)
  FROM raw_data
 CROSS JOIN meta
 WHERE raw_data.lang = 'ru'
ON CONFLICT (an_id) DO NOTHING;

-- i18n для школы, лора и перков
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_mage_school' AS qu_id)
, school_data AS (
  SELECT 'ru' AS lang, v.*
    FROM (VALUES
      ('aretuza',  'Аретуза'),
      ('ban_ard',  'Бан Ард'),
      ('minor',    'Малая Академия'),
      ('gweison',  'Гвейсон Хайль'),
      ('imperial', 'Имперская Магическая Академия')
    ) v(school_key, school_name)
  UNION ALL
  SELECT 'en' AS lang, v.*
    FROM (VALUES
      ('aretuza',  'Aretuza'),
      ('ban_ard',  'Ban Ard'),
      ('minor',    'Minor Academia'),
      ('gweison',  'Gweison Haul'),
      ('imperial', 'Imperial Magic Academy')
    ) v(school_key, school_name)
)
, perk_data AS (
  SELECT 'ru' AS lang, v.*
    FROM (VALUES
      ('aretuza',  '<b>Исток Аретузы</b><br>Потратив 10 дополнительных Вын в свой ход, вы можете повысить порог энергии на 2 на время этого хода. Это увеличение суммируется с предметами фокуса.'),
      ('ban_ard',  '<b>Косвенный контроль Бан Арда</b><br>Когда вы страдаете от магического провала, вы можете пожертвовать 10 Вын, чтобы уменьшить результат провала на 5 (минимум 1).'),
      ('minor',    '<b>Универсальный заклинатель Малой академии</b><br>Потратив 10 дополнительных Вын, когда вы произносите заклинание, вы можете либо добавить +4 м к дальности заклинания, либо +2 раунда продолжительности к неподдерживаемым заклинаниям.'),
      ('gweison',  '<b>Устойчивость Гвейсон Хайль</b><br>При контакте с димеритом вы можете потратить 10 Вын, чтобы получить +3 к проверке выносливости, чтобы сопротивляться эффектам.'),
      ('imperial', '<b>Устойчивость Гвейсон Хайль</b><br>При контакте с димеритом вы можете потратить 10 Вын, чтобы получить +3 к проверке выносливости, чтобы сопротивляться эффектам.')
    ) v(school_key, perk_text)
  UNION ALL
  SELECT 'en' AS lang, v.*
    FROM (VALUES
      ('aretuza',  '<b>Aretuza Wellspring</b><br>By spending 10 extra STA on your turn, you can raise your Vigor Threshold by 2 for the duration of that turn. This increase stacks with Focus Items.'),
      ('ban_ard',  '<b>Ban Ard Controlled Collateral</b><br>When you suffer a Magical Fumble, you can sacrifice 10 STA to lower the amount fumbled by 5 (minimum 1).'),
      ('minor',    '<b>Minor Academia Versatile Caster</b><br>By spending 10 extra STA when you cast a spell, you can either add +4m of range to a spell, +2 Rounds of duration to a Non-Active.'),
      ('gweison',  '<b>Gweison Haul Tolerance</b><br>When coming in contact with dimeritium, you can spend 10 STA to give yourself a +3 to your Endurance check to resist the effects.'),
      ('imperial', '<b>Gweison Haul Tolerance</b><br>When coming in contact with dimeritium, you can spend 10 STA to give yourself a +3 to your Endurance check to resist the effects.')
    ) v(school_key, perk_text)
)
, ins_school_name AS (
  INSERT INTO i18n_text (id, entity, entity_field, lang, text)
  SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| school_data.school_key ||'.school.name') AS id
       , 'character', 'school', school_data.lang, school_data.school_name
    FROM school_data
    CROSS JOIN meta
  ON CONFLICT (id, lang) DO NOTHING
)
INSERT INTO i18n_text (id, entity, entity_field, lang, text)
SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| perk_data.school_key ||'.perk.description') AS id
     , 'perks', 'description', perk_data.lang, perk_data.perk_text
  FROM perk_data
 CROSS JOIN meta
ON CONFLICT (id, lang) DO NOTHING;

-- Эффекты: перк + школа + lore + логическое поле
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_past_mage_school' AS qu_id)
, option_map AS (
  SELECT *
    FROM (VALUES
      ( 1, 'aretuza',  'aretuza'),
      ( 2, 'ban_ard',  'ban_ard'),
      ( 3, 'minor',    'minor_academia'),
      ( 4, 'gweison',  'gweison_haul'),
      ( 5, 'imperial', 'imperial_magic_academy'),
      ( 6, 'aretuza',  'aretuza'),
      ( 7, 'ban_ard',  'ban_ard'),
      ( 8, 'minor',    'minor_academia'),
      ( 9, 'gweison',  'gweison_haul'),
      (10, 'imperial', 'imperial_magic_academy'),
      (11, 'aretuza',  'aretuza'),
      (12, 'ban_ard',  'ban_ard'),
      (13, 'minor',    'minor_academia'),
      (14, 'gweison',  'gweison_haul'),
      (15, 'imperial', 'imperial_magic_academy'),
      (16, 'aretuza',  'aretuza'),
      (17, 'ban_ard',  'ban_ard'),
      (18, 'minor',    'minor_academia'),
      (19, 'gweison',  'gweison_haul'),
      (20, 'imperial', 'imperial_magic_academy')
    ) AS v(num, school_key, school_code)
)
INSERT INTO effects (scope, an_an_id, body)
SELECT
  'character' AS scope,
  meta.qu_id || '_o' || to_char(option_map.num, 'FM00') AS an_an_id,
  jsonb_build_object(
    'add',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.perks'),
      jsonb_build_object(
        'i18n_uuid',
        ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| option_map.school_key ||'.perk.description')::text
      )
    )
  ) AS body
FROM option_map
CROSS JOIN meta
UNION ALL
SELECT
  'character' AS scope,
  meta.qu_id || '_o' || to_char(option_map.num, 'FM00') AS an_an_id,
  jsonb_build_object(
    'set',
    jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.lore.school'),
      jsonb_build_object(
        'i18n_uuid',
        ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| option_map.school_key ||'.school.name')::text
      )
    )
  ) AS body
FROM option_map
CROSS JOIN meta
UNION ALL
SELECT
  'character' AS scope,
  meta.qu_id || '_o' || to_char(option_map.num, 'FM00') AS an_an_id,
  jsonb_build_object(
    'set',
      jsonb_build_array(
      jsonb_build_object('var', 'characterRaw.logicFields.school'),
      option_map.school_code
    )
  ) AS body
FROM option_map
CROSS JOIN meta;

-- Связи
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, priority)
SELECT 'wcc_past_homeland_mage', 'wcc_past_mage_school', 0;
