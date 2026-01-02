\echo '010_ch_name.sql'
-- Узел: Имя персонажа

-- Вопрос
WITH
  meta AS (SELECT 'witcher_cc' AS su_su_id
                , 'wcc_ch_name' AS qu_id
                , 'questions' AS entity)
, ins_body AS (
    INSERT INTO i18n_text (id, entity, entity_field, lang, text)
    SELECT ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body') AS id
         , meta.entity, 'body', v.lang, v.text
      FROM (VALUES
        ('ru', 'Как вас зовут?'),
        ('en', 'What is your name?')
      ) AS v(lang, text)
      CROSS JOIN meta
  )
INSERT INTO questions (qu_id, su_su_id, title, body, qtype, metadata)
SELECT meta.qu_id
     , meta.su_su_id
     , NULL
     , ck_id(meta.su_su_id ||'.'|| meta.qu_id ||'.'|| meta.entity ||'.'|| 'body')
       , 'value_textbox'
       , jsonb_build_object(
          'defaultValue', 'Character Name',
          'valueTarget' , 'characterRaw.name',
          'path', jsonb_build_array(
            ck_id('witcher_cc.hierarchy.identity')::text,
            ck_id('witcher_cc.hierarchy.character_name')::text
          ),
          -- randomList: массив имен в зависимости от расы
          'randomList', jsonb_build_object(
            'if', jsonb_build_array(
              jsonb_build_object('==', jsonb_build_array(
                jsonb_build_object('var', 'characterRaw.logicFields.race'),
                'Witcher'
              )),
              jsonb_build_array('Olsen', 'Dagread', 'Adalbert', 'John', 'Agnes', 'Aplegatt', 'Carduin'),
              jsonb_build_object(
                'if', jsonb_build_array(
                  jsonb_build_object('==', jsonb_build_array(
                    jsonb_build_object('var', 'characterRaw.logicFields.race'),
                    'Human'
                  )),
                  jsonb_build_array('Olsen', 'Dagread', 'Adalbert', 'John', 'Agnes', 'Aplegatt', 'Carduin'),
                  jsonb_build_object(
                    'if', jsonb_build_array(
                      jsonb_build_object('==', jsonb_build_array(
                        jsonb_build_object('var', 'characterRaw.logicFields.race'),
                        'Dwarf'
                      )),
                      jsonb_build_array('Rodolf', 'Zoltan', 'Yarpen', 'Barclay', 'Brouver', 'Golan', 'Rhundurin'),
                      jsonb_build_object(
                        'if', jsonb_build_array(
                          jsonb_build_object('==', jsonb_build_array(
                            jsonb_build_object('var', 'characterRaw.logicFields.race'),
                            'Elf'
                          )),
                          jsonb_build_array('Yaevinn', 'Iorveth', 'Aelirenn', 'Filavandrel', 'Ge''els', 'Shiadhal', 'Nithral'),
                          jsonb_build_array('Sigurd', 'Aksel', 'Laila', 'Ragnar', 'Brynhild', 'Olaf', 'Hakon')
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
-- Нода должна идти после выбора расы, но перед возрастом
-- Добавим переход от расы к имени

-- От имени к возрасту (для всех рас)


-- Переходы теперь идут через wcc_ch_name (имя персонажа)
-- Изменяем переходы так, чтобы они шли к имени, а не напрямую к возрасту
INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id, via_an_an_id)
  SELECT 'wcc_past_elf_q1', 'wcc_ch_name', 'wcc_past_elf_q1_o01' UNION ALL
  SELECT 'wcc_past_dwarf_q1', 'wcc_ch_name', 'wcc_past_dwarf_q1_o01'UNION ALL
  SELECT 'wcc_past_witcher_q1', 'wcc_ch_name', 'wcc_past_witcher_q1_o01';

INSERT INTO transitions (from_qu_qu_id, to_qu_qu_id)
  SELECT 'wcc_past_homeland_human', 'wcc_ch_name' UNION ALL
  SELECT 'wcc_past_homeland_elders', 'wcc_ch_name';