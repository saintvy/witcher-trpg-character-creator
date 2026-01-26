\echo '012_ch_age.sql'
-- Узел: Братья и сёстры - Основная черта характера

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_ch_age' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru', 'Сколько вам лет? Ведьмакам может быть от 50 до 260 лет, для остальных рас в правилах нет ограничений..'),
        ('en', 'How old are you? Witchers can be anywhere from 50 to 260 years old. For other races, there are no restrictions in the rules.')
      ) AS v(lang, text)
      CROSS JOIN meta
  )
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
SELECT meta.qu_id
     , meta.su_su_id
     , NULL
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body')
       , 'value_numeric'
       , jsonb_build_object(
          'type'        , 'int',
          'defaultValue', 18,
          'placeholder' , 'Years',
          'valueTarget' , 'characterRaw.age',
          'counterSet'  , jsonb_build_array(
                            jsonb_build_object('id','lifeEventsCounter','value', 0)
                          ),
          'path', jsonb_build_array(
            ck_id('witcher_cc.hierarchy.identity')::text,
            ck_id('witcher_cc.hierarchy.character_age')::text
          ),
          -- min: 50 для ведьмака, 0 для остальных рас
          'min', jsonb_build_object(
            'if', jsonb_build_array(
              jsonb_build_object('==', jsonb_build_array(
                jsonb_build_object('var', 'characterRaw.logicFields.race'),
                'Witcher'
              )),
              50,
              0
            )
          ),
          -- max: 260 для ведьмака, не выставляем для остальных (null)
          'max', jsonb_build_object(
            'if', jsonb_build_array(
              jsonb_build_object('==', jsonb_build_array(
                jsonb_build_object('var', 'characterRaw.logicFields.race'),
                'Witcher'
              )),
              260,
              null
            )
          ),
          -- min_rand: 50 для ведьмака, 18 для остальных рас
          'min_rand', jsonb_build_object(
            'if', jsonb_build_array(
              jsonb_build_object('==', jsonb_build_array(
                jsonb_build_object('var', 'characterRaw.logicFields.race'),
                'Witcher'
              )),
              50,
              18
            )
          ),
          -- max_rand: 260 для ведьмака, 60 для человека, 150 для краснолюда, 300 для эльфа
          'max_rand', jsonb_build_object(
            'if', jsonb_build_array(
              jsonb_build_object('==', jsonb_build_array(
                jsonb_build_object('var', 'characterRaw.logicFields.race'),
                'Witcher'
              )),
              260,
              jsonb_build_object(
                'if', jsonb_build_array(
                  jsonb_build_object('==', jsonb_build_array(
                    jsonb_build_object('var', 'characterRaw.logicFields.race'),
                    'Human'
                  )),
                  60,
                  jsonb_build_object(
                    'if', jsonb_build_array(
                      jsonb_build_object('==', jsonb_build_array(
                        jsonb_build_object('var', 'characterRaw.logicFields.race'),
                        'Dwarf'
                      )),
                      150,
                      jsonb_build_object(
                        'if', jsonb_build_array(
                          jsonb_build_object('==', jsonb_build_array(
                            jsonb_build_object('var', 'characterRaw.logicFields.race'),
                            'Elf'
                          )),
                          300,
                          null
                        )
                      )
                    )
                  )
                )
              )
            )
          )
         ) AS metadata
  FROM meta;
  
-- Связи

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_ch_name', 'wcc_ch_age';

-- Правила
INSERT INTO rules(name, body)
VALUES ('lifeEventsCounter_is_valid',
'{
  "<=":
    [
      {
        "+":
          [
            {
              "var":"counters.lifeEventsCounter"
            },
            10
          ]
      },
      {
        "var": "characterRaw.age"
      }
    ]
}'::jsonb);