import { db } from '../db/pool.js';

const DEFAULT_SURVEY_ID = 'witcher_cc';
const DEFAULT_LANG = 'en';

export type GetSkillsCatalogRequest = {
  surveyId?: string;
  lang?: string;
};

export type SkillCatalogEntry = {
  id: string;
  name: string;
  type: 'common' | 'main' | 'professional';
  param: string | null;
  isDifficult: boolean;
  professionalNumber: number | null;
  branchNumber: number | null;
  profId: string | null;
};

export async function getSkillsCatalog(payload: GetSkillsCatalogRequest): Promise<{ skills: SkillCatalogEntry[] }> {
  const surveyId = payload?.surveyId ?? DEFAULT_SURVEY_ID;
  const lang = payload?.lang ?? DEFAULT_LANG;

  const { rows } = await db.query<{
    id: string;
    name: string;
    type: 'common' | 'main' | 'professional';
    param: string | null;
    is_difficult: boolean;
    professional_number: number | null;
    branch_number: number | null;
    prof_id: string | null;
  }>(
    `
      SELECT
        s.skill_id AS id,
        COALESCE(t_lang.text, t_en.text, s.skill_name_id::text) AS name,
        s.skill_type AS "type",
        s.param_param_id AS param,
        COALESCE(s.is_difficult, false) AS is_difficult,
        s.professional_number,
        s.branch_number,
        s.prof_id
      FROM wcc_skills s
      LEFT JOIN i18n_text t_lang ON t_lang.id = s.skill_name_id AND t_lang.lang = $1
      LEFT JOIN i18n_text t_en ON t_en.id = s.skill_name_id AND t_en.lang = 'en'
      WHERE s.skill_name_id IS NOT NULL
      ORDER BY s.skill_aid
    `,
    [lang],
  );

  return {
    skills: rows.map((r) => ({
      id: r.id,
      name: r.name,
      type: r.type,
      param: r.param,
      isDifficult: Boolean(r.is_difficult),
      professionalNumber: r.professional_number,
      branchNumber: r.branch_number,
      profId: r.prof_id,
    })),
  };
}

