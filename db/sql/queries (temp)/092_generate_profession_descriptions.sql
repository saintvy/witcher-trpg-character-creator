\echo '092_generate_profession_descriptions.sql'
-- Генерация описаний профессий на основе данных из таблиц профессий, навыков и параметров
-- Этот запрос генерирует HTML-описание, аналогичное тому, что хранится в answer_options

WITH
  -- Получение локализованных названий параметров
  params_i18n AS (
    SELECT 
      p.param_id,
      p.param_name_id,
      p.param_short_name_id,
      COALESCE(pn_ru.text, pn_en.text) AS param_name,
      COALESCE(psn_ru.text, psn_en.text) AS param_short_name
    FROM wcc_params p
    LEFT JOIN i18n_text pn_ru ON p.param_name_id = pn_ru.id AND pn_ru.lang = 'ru'
    LEFT JOIN i18n_text pn_en ON p.param_name_id = pn_en.id AND pn_en.lang = 'en'
    LEFT JOIN i18n_text psn_ru ON p.param_short_name_id = psn_ru.id AND psn_ru.lang = 'ru'
    LEFT JOIN i18n_text psn_en ON p.param_short_name_id = psn_en.id AND psn_en.lang = 'en'
  ),
  -- Получение локализованных названий навыков
  skills_i18n AS (
    SELECT 
      s.skill_id,
      s.skill_type,
      s.professional_number,
      s.branch_number,
      s.param_param_id,
      s.skill_desc_id,
      COALESCE(sn_ru.text, sn_en.text) AS skill_name,
      -- Пытаемся найти описание через skill_desc_id, если не найдено - ищем напрямую по ID
      COALESCE(
        sd_ru.text, 
        sd_en.text,
        sd_direct_ru.text,
        sd_direct_en.text
      ) AS skill_description,
      COALESCE(bn_ru.text, bn_en.text) AS branch_name,
      p.param_short_name
    FROM wcc_skills s
    LEFT JOIN i18n_text sn_ru ON s.skill_name_id = sn_ru.id AND sn_ru.lang = 'ru'
    LEFT JOIN i18n_text sn_en ON s.skill_name_id = sn_en.id AND sn_en.lang = 'en'
    -- Прямой поиск через skill_desc_id
    LEFT JOIN i18n_text sd_ru ON s.skill_desc_id = sd_ru.id AND sd_ru.lang = 'ru'
    LEFT JOIN i18n_text sd_en ON s.skill_desc_id = sd_en.id AND sd_en.lang = 'en'
    -- Резервный поиск напрямую по сформированному ID (на случай если skill_desc_id NULL)
    LEFT JOIN i18n_text sd_direct_ru ON ck_id('witcher_cc.wcc_skills.' || s.skill_id || '.description') = sd_direct_ru.id AND sd_direct_ru.lang = 'ru'
    LEFT JOIN i18n_text sd_direct_en ON ck_id('witcher_cc.wcc_skills.' || s.skill_id || '.description') = sd_direct_en.id AND sd_direct_en.lang = 'en'
    LEFT JOIN i18n_text bn_ru ON s.branch_name_id = bn_ru.id AND bn_ru.lang = 'ru'
    LEFT JOIN i18n_text bn_en ON s.branch_name_id = bn_en.id AND bn_en.lang = 'en'
    LEFT JOIN params_i18n p ON s.param_param_id = p.param_id
  ),
  -- Навыки профессий с группировкой
  profession_skills_grouped AS (
    SELECT 
      ps.prof_id,
      s.skill_type,
      s.branch_number,
      s.branch_name,
      s.professional_number,
      s.skill_id,
      s.skill_name,
      s.skill_description,
      s.param_short_name,
      s.param_param_id,
      ROW_NUMBER() OVER (PARTITION BY ps.prof_id, s.skill_type, s.branch_number ORDER BY s.professional_number) AS skill_order
    FROM wcc_profession_skills ps
    JOIN skills_i18n s ON ps.skill_skill_id = s.skill_id
  ),
  -- Общие навыки профессии
  common_skills AS (
    SELECT 
      psg.prof_id,
      string_agg(
        '<li>[' || COALESCE(NULLIF(p.param_name, ''), COALESCE(NULLIF(psg.param_short_name, ''), '?')) || '] - ' || psg.skill_name || '</li>',
        E'\n                ' ORDER BY psg.skill_id
      ) AS skills_list
    FROM profession_skills_grouped psg
    LEFT JOIN params_i18n p ON psg.param_param_id = p.param_id
    WHERE psg.skill_type = 'common'
    GROUP BY psg.prof_id
  ),
  -- Определяющий навык
  main_skills AS (
    SELECT 
      prof_id,
      skill_id,
      skill_name,
      skill_description,
      param_short_name
    FROM profession_skills_grouped
    WHERE skill_type = 'main'
  ),
  -- Профессиональные навыки по веткам
  professional_skills_by_branch AS (
    SELECT 
      prof_id,
      branch_number,
      branch_name,
      string_agg(
        '<tr>' || E'\n        ' ||
        '<td class="opt_content">' || E'\n            ' ||
        '<strong>' || skill_name || 
        CASE WHEN param_short_name IS NOT NULL AND param_short_name != '' THEN ' (' || param_short_name || ')' ELSE '' END ||
        '</strong><br>' || E'\n            ' ||
        COALESCE(NULLIF(skill_description, ''), '[Описание отсутствует]') ||
        '</td>' || E'\n    ' ||
        '</tr>',
        E'\n    ' ORDER BY professional_number NULLS LAST
      ) AS branch_skills_html
    FROM profession_skills_grouped
    WHERE skill_type = 'professional' AND branch_number IS NOT NULL
    GROUP BY prof_id, branch_number, branch_name
  ),
  -- HTML для профессиональных навыков
  professional_skills_html AS (
    SELECT 
      prof_id,
      string_agg(
        '<table class="skills_branch_' || branch_number || '">' || E'\n    ' ||
        '<tr>' || E'\n        ' ||
        '<td class="header">' || branch_name || '</td>' || E'\n    ' ||
        '</tr>' || E'\n    ' ||
        branch_skills_html ||
        E'\n</table>',
        E'\n\n' ORDER BY branch_number
      ) AS html
    FROM professional_skills_by_branch
    GROUP BY prof_id
  ),
  -- Локализованные названия профессий
  professions_i18n AS (
    SELECT 
      p.prof_id,
      COALESCE(pn_ru.text, pn_en.text) AS prof_name,
      COALESCE(pd_ru.text, pd_en.text) AS prof_description
    FROM wcc_professions p
    LEFT JOIN i18n_text pn_ru ON p.prof_name_id = pn_ru.id AND pn_ru.lang = 'ru'
    LEFT JOIN i18n_text pn_en ON p.prof_name_id = pn_en.id AND pn_en.lang = 'en'
    LEFT JOIN i18n_text pd_ru ON p.prof_desc_id = pd_ru.id AND pd_ru.lang = 'ru'
    LEFT JOIN i18n_text pd_en ON p.prof_desc_id = pd_en.id AND pd_en.lang = 'en'
  )
-- Финальный запрос, генерирующий HTML-описание
SELECT 
  pi.prof_id,
  pi.prof_name,
  '<div class="ddlist_option">' || E'\n' ||
  '<table class="profession_table">' || E'\n    ' ||
  '<tr>' || E'\n        ' ||
  '<td>' || E'\n            ' ||
  '<strong>Энергия:</strong> <span class="profession-vigor">[НЕ УКАЗАНО]</span><br><br>' || E'\n            ' ||
  '<strong>Магические способности:</strong><br>' || E'\n            ' ||
  '<span class="profession-magical-perks">[НЕ УКАЗАНО]</span>' || E'\n        ' ||
  '</td>' || E'\n        ' ||
  '<td>' || E'\n            ' ||
  '<strong>Базовые навыки</strong>' || E'\n            ' ||
  '<ul>' || E'\n                ' ||
  COALESCE(cs.skills_list, '') || E'\n            ' ||
  '</ul>' || E'\n        ' ||
  '</td>' || E'\n        ' ||
  '<td>' || E'\n            ' ||
  '<strong>Снаряжение</strong><br>' || E'\n            ' ||
  '<span class="profession-gear">[НЕ УКАЗАНО]</span>' || E'\n        ' ||
  '</td>' || E'\n    ' ||
  '</tr>' || E'\n' ||
  '</table>' || E'\n' ||
  E'\n' ||
    CASE WHEN ms.skill_id IS NOT NULL THEN
    '<h3>Определяющий навык</h3>' || E'\n' ||
    '<table class="main_skill">' || E'\n    ' ||
    '<tr>' || E'\n        ' ||
    '<td class="header">' || ms.skill_name ||
    CASE WHEN ms.param_short_name IS NOT NULL AND ms.param_short_name != '' THEN ' (' || ms.param_short_name || ')' ELSE '' END ||
    '</td>' || E'\n    ' ||
    '</tr>' || E'\n    ' ||
    '<tr>' || E'\n        ' ||
    '<td class="opt_content">' || E'\n            ' ||
    COALESCE(NULLIF(ms.skill_description, ''), '[Описание отсутствует]') || E'\n        ' ||
    '</td>' || E'\n    ' ||
    '</tr>' || E'\n' ||
    '</table>'
  ELSE '' END ||
  E'\n' ||
  CASE WHEN psh.html IS NOT NULL THEN
    '<h3>Профессиональные навыки</h3>' || E'\n' ||
    E'\n' ||
    psh.html
  ELSE '' END ||
  E'\n</div>' AS description_html
FROM professions_i18n pi
LEFT JOIN common_skills cs ON pi.prof_id = cs.prof_id
LEFT JOIN main_skills ms ON pi.prof_id = ms.prof_id
LEFT JOIN professional_skills_html psh ON pi.prof_id = psh.prof_id
ORDER BY pi.prof_id;

