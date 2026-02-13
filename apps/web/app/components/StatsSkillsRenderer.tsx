"use client";

import { useEffect, useMemo, useRef, useState } from "react";

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:4000";

type SkillCatalogEntry = {
  id: string;
  name: string;
  type: "common" | "main" | "professional";
  param: string | null;
  isDifficult: boolean;
  professionalNumber?: number | null;
  branchNumber?: number | null;
  profId?: string | null;
};

type SkillRowEntry = SkillCatalogEntry & {
  isDefining?: boolean;
};

type GameLevelKey = "Average" | "Skilled" | "Heroes" | "Legends";

const GAME_LEVELS: Array<{ key: GameLevelKey; points: number }> = [
  { key: "Average", points: 60 },
  { key: "Skilled", points: 70 },
  { key: "Heroes", points: 75 },
  { key: "Legends", points: 80 },
];

const STAT_KEYS = ["INT", "REF", "DEX", "BODY", "SPD", "EMP", "CRA", "WILL", "LUCK"] as const;
type StatKey = (typeof STAT_KEYS)[number];

const STAT_META: Record<
  StatKey,
  { en: { name: string; abbr: string }; ru: { name: string; abbr: string } }
> = {
  INT: { en: { name: "Intelligence", abbr: "INT" }, ru: { name: "Интеллект", abbr: "Инт" } },
  REF: { en: { name: "Reflexes", abbr: "REF" }, ru: { name: "Реакция", abbr: "Реа" } },
  DEX: { en: { name: "Dexterity", abbr: "DEX" }, ru: { name: "Ловкость", abbr: "Лвк" } },
  BODY: { en: { name: "Body", abbr: "BODY" }, ru: { name: "Телосложение", abbr: "Тел" } },
  SPD: { en: { name: "Speed", abbr: "SPD" }, ru: { name: "Скорость", abbr: "Скор" } },
  EMP: { en: { name: "Empathy", abbr: "EMP" }, ru: { name: "Эмпатия", abbr: "Эмп" } },
  CRA: { en: { name: "Craft", abbr: "CRA" }, ru: { name: "Ремесло", abbr: "Рем" } },
  WILL: { en: { name: "Will", abbr: "WILL" }, ru: { name: "Воля", abbr: "Воля" } },
  LUCK: { en: { name: "Luck", abbr: "LUCK" }, ru: { name: "Удача", abbr: "Удача" } },
};

// DB skill_id -> legacy key used in characterRaw.skills.common (defaultCharacter.json)
const SKILL_ID_TO_STATE_ID: Record<string, string> = {
  staff_spear: "staff",
  dodge_escape: "dodge",
};

function toStateSkillId(skillId: string): string {
  return SKILL_ID_TO_STATE_ID[skillId] ?? skillId;
}

function normaliseStatKey(raw: unknown): StatKey | null {
  if (typeof raw !== "string") return null;
  const up = raw.toUpperCase();
  return (STAT_KEYS as readonly string[]).includes(up) ? (up as StatKey) : null;
}

function fetchJsonOrThrow(res: Response) {
  if (!res.ok) {
    return res.text().then((t) => {
      throw new Error(t || `Request failed: ${res.status}`);
    });
  }
  return res.json();
}

function toNumber(value: unknown, fallback = 0): number {
  const n = typeof value === "number" ? value : Number(value);
  return Number.isFinite(n) ? n : fallback;
}

function clampInt(n: number, min: number, max: number): number {
  const rounded = Math.trunc(n);
  return Math.max(min, Math.min(max, rounded));
}

function getAtPath(source: unknown, path: string): unknown {
  if (!path) return undefined;
  const parts = path.split(".").filter(Boolean);
  let cursor: any = source;
  for (const part of parts) {
    if (cursor == null || typeof cursor !== "object") return undefined;
    cursor = cursor[part];
  }
  return cursor;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function statVigorByProfession(profession: unknown): number | null {
  const p = typeof profession === "string" ? profession : null;
  if (!p) return null;
  switch (p) {
    case "Witcher":
      return 2;
    case "Mage":
      return 5;
    case "Priest":
      return 2;
    case "Druid":
      return 2;
    case "Bard":
    case "Doctor":
    case "Man At Arms":
    case "Criminal":
    case "Craftsman":
    case "Merchant":
      return 0;
    default:
      return null;
  }
}

function diceWithMod(base: string, mod: number): string {
  if (!Number.isFinite(mod) || mod === 0) return base;
  const val = Math.trunc(mod);
  return `${base}${val > 0 ? "+" : ""}${val}`;
}

function normaliseLevel(value: unknown): GameLevelKey {
  return value === "Average" || value === "Skilled" || value === "Heroes" || value === "Legends"
    ? value
    : "Average";
}

function buildNextStatsWithDelta(
  current: Record<StatKey, number>,
  key: StatKey,
  delta: number,
  baseline: number,
): Record<StatKey, number> {
  return {
    ...current,
    [key]: clampInt(current[key] + delta, Math.max(1, baseline), 10),
  };
}

export function StatsSkillsRenderer(props: {
  questionId: string;
  lang: "ru" | "en";
  state: Record<string, unknown>;
  disabled?: boolean;
  onSubmit: (payload: {
    v: 1;
    level: GameLevelKey;
    stats: Record<StatKey, number>;
    skills: Record<string, number>;
  }) => void;
}) {
  const { questionId, lang, state, disabled, onSubmit } = props;

  const commonSkillsState = useMemo(() => {
    const cr: any = (state as any)?.characterRaw;
    const common = cr?.skills?.common;
    return isRecord(common) ? (common as Record<string, any>) : ({} as Record<string, any>);
  }, [state]);

  const getSkillNumber = useMemo(() => {
    return (skillId: string, field: "bonus" | "race_bonus") => {
      const v = commonSkillsState[skillId]?.[field];
      return clampInt(toNumber(v, 0), -99, 99);
    };
  }, [commonSkillsState]);

  const t = useMemo(() => {
    const ru = lang === "ru";
    return {
      sections: {
        budgets: ru ? "Бюджет" : "Budget",
        level: ru ? "Уровень игры" : "Game level",
        stats: ru ? "Параметры" : "Attributes",
        computed: ru ? "Вычисляемые параметры" : "Derived",
        skills: ru ? "Навыки" : "Skills",
        professional: ru ? "Профессиональные навыки" : "Professional skills",
      },
      budgets: {
        professional: ru ? "Профессиональные знания (остаток)" : "Professional knowledge (remaining)",
        common: ru ? "Общие знания (остаток)" : "General knowledge (remaining)",
        stats: ru ? "Параметры (остаток)" : "Attributes (remaining)",
      },
      levels: {
        Average: ru ? "Середнячки" : "Average",
        Skilled: ru ? "Опытные" : "Skilled",
        Heroes: ru ? "Герои" : "Heroes",
        Legends: ru ? "Легенды" : "Legends",
      } satisfies Record<GameLevelKey, string>,
      cols: {
        value: ru ? "Знач." : "Val",
        bonus: ru ? "Бонус" : "Bonus",
        racial: ru ? "Рас." : "Race",
        base: ru ? "Основа" : "Base",
      },
      computedLabels: {
        vigor: ru ? "Энергия (Vigor)" : "Vigor",
        stun: ru ? "Устойчивость (Уст)" : "Stun",
        run: ru ? "Бег" : "Run",
        leap: ru ? "Прыжок (Прж)" : "Leap",
        hp: ru ? "Пункты здоровья (ПЗ)" : "Health Points (HP)",
        sta: ru ? "Выносливость (Вын)" : "Stamina (STA)",
        enc: ru ? "Переносимый вес (Вес)" : "Encumbrance (ENC)",
        rec: ru ? "Отдых" : "Recovery (REC)",
        punch: ru ? "Удар рукой" : "Punch",
        kick: ru ? "Удар ногой" : "Kick",
      },
      languagesHeader: ru ? "Языки" : "Languages",
      loading: ru ? "Загрузка…" : "Loading…",
    };
  }, [lang]);

  const [catalog, setCatalog] = useState<SkillCatalogEntry[] | null>(null);
  const [catalogError, setCatalogError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setCatalog(null);
    setCatalogError(null);
    fetch(`${API_URL}/skills/catalog`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ lang }),
    })
      .then(fetchJsonOrThrow)
      .then((data) => {
        const skills = (data?.skills ?? data) as unknown;
        const parsed = Array.isArray(skills) ? (skills as SkillCatalogEntry[]) : null;
        if (!cancelled) setCatalog(parsed);
      })
      .catch((e) => {
        if (!cancelled) setCatalogError(e instanceof Error ? e.message : String(e));
      });
    return () => {
      cancelled = true;
    };
  }, [lang]);

  const initialLevel = useMemo(() => {
    const saved = getAtPath(state, "characterRaw.logicFields.stats_skills.level");
    return normaliseLevel(saved);
  }, [state]);

  const [level, setLevel] = useState<GameLevelKey>(initialLevel);

  const baselineRef = useRef<{
    stats: Record<StatKey, number>;
    skills: Record<string, number>;
  } | null>(null);

  const [statCurById, setStatCurById] = useState<Record<StatKey, number>>(() => {
    const initial: Record<StatKey, number> = {} as any;
    for (const k of STAT_KEYS) {
      initial[k] = clampInt(toNumber(getAtPath(state, `characterRaw.statistics.${k}.cur`), 1), 1, 10);
    }
    return initial;
  });

  const [skillCurById, setSkillCurById] = useState<Record<string, number>>(() => {
    const common = getAtPath(state, "characterRaw.skills.common");
    const out: Record<string, number> = {};
    if (isRecord(common)) {
      for (const skillId of Object.keys(common)) {
        out[skillId] = clampInt(toNumber(getAtPath(state, `characterRaw.skills.common.${skillId}.cur`), 0), 0, 99);
      }
    }

    const initialSkillsRaw = getAtPath(state, "characterRaw.skills.initial");
    const initialSkills = Array.isArray(initialSkillsRaw)
      ? initialSkillsRaw.filter((x): x is string => typeof x === "string" && x.length > 0)
      : [];
    const definingRaw = getAtPath(state, "characterRaw.skills.defining");
    const definingSkillId =
      typeof definingRaw === "string"
        ? definingRaw
        : isRecord(definingRaw) && typeof definingRaw.skill_id === "string"
          ? definingRaw.skill_id
          : isRecord(definingRaw) && typeof definingRaw.id === "string"
            ? definingRaw.id
            : null;

    const required = new Set<string>(initialSkills);
    if (definingSkillId) required.add(definingSkillId);
    for (const skillId of required) {
      out[skillId] = Math.max(out[skillId] ?? 0, 1);
    }

    return out;
  });

  const [, setCommonSpendLog] = useState<string[]>([]);

  useEffect(() => {
    setLevel(initialLevel);

    const nextStats: Record<StatKey, number> = {} as any;
    for (const k of STAT_KEYS) {
      nextStats[k] = clampInt(toNumber(getAtPath(state, `characterRaw.statistics.${k}.cur`), 1), 1, 10);
    }
    setStatCurById(nextStats);

    const common = getAtPath(state, "characterRaw.skills.common");
    const nextSkills: Record<string, number> = {};
    if (isRecord(common)) {
      for (const skillId of Object.keys(common)) {
        nextSkills[skillId] = clampInt(toNumber(getAtPath(state, `characterRaw.skills.common.${skillId}.cur`), 0), 0, 99);
      }
    }

    const initialSkillsRaw = getAtPath(state, "characterRaw.skills.initial");
    const initialSkills = Array.isArray(initialSkillsRaw)
      ? initialSkillsRaw.filter((x): x is string => typeof x === "string" && x.length > 0)
      : [];
    const definingRaw = getAtPath(state, "characterRaw.skills.defining");
    const definingSkillId =
      typeof definingRaw === "string"
        ? definingRaw
        : isRecord(definingRaw) && typeof definingRaw.skill_id === "string"
          ? definingRaw.skill_id
          : isRecord(definingRaw) && typeof definingRaw.id === "string"
            ? definingRaw.id
            : null;

    const required = new Set<string>(initialSkills);
    if (definingSkillId) required.add(definingSkillId);
    for (const skillId of required) {
      nextSkills[skillId] = Math.max(nextSkills[skillId] ?? 0, 1);
    }

    setSkillCurById(nextSkills);

    baselineRef.current = { stats: nextStats, skills: nextSkills };
    setCommonSpendLog([]);
  }, [questionId, initialLevel, state]);

  const initialSkills = useMemo(() => {
    const raw = getAtPath(state, "characterRaw.skills.initial");
    if (!Array.isArray(raw)) return [];
    return raw.filter((x): x is string => typeof x === "string" && x.length > 0);
  }, [state]);

  const definingSkillId = useMemo(() => {
    const raw = getAtPath(state, "characterRaw.skills.defining");
    if (typeof raw === "string") return raw;
    if (isRecord(raw) && typeof raw.skill_id === "string") return raw.skill_id;
    if (isRecord(raw) && typeof raw.id === "string") return raw.id;
    return null;
  }, [state]);

  const professionalSkillSet = useMemo(() => {
    const set = new Set<string>(initialSkills);
    if (definingSkillId) set.add(definingSkillId);
    return set;
  }, [initialSkills, definingSkillId]);

  const stateCommonSkillIdSet = useMemo(() => {
    const common = getAtPath(state, "characterRaw.skills.common");
    return isRecord(common) ? new Set(Object.keys(common)) : new Set<string>();
  }, [state]);

  const skillMetaById = useMemo(() => {
    const map = new Map<string, SkillCatalogEntry>();
    (catalog ?? []).forEach((s) => map.set(s.id, s));
    return map;
  }, [catalog]);

  const statBonusById = useMemo(() => {
    const out: Record<StatKey, { bonus: number; race: number }> = {} as any;
    for (const k of STAT_KEYS) {
      out[k] = {
        bonus: clampInt(toNumber(getAtPath(state, `characterRaw.statistics.${k}.bonus`), 0), -99, 99),
        race: clampInt(toNumber(getAtPath(state, `characterRaw.statistics.${k}.race_bonus`), 0), -99, 99),
      };
    }
    return out;
  }, [state]);

  const statTotalById = useMemo(() => {
    const out: Record<StatKey, number> = {} as any;
    for (const k of STAT_KEYS) {
      const b = statBonusById[k];
      out[k] = clampInt(statCurById[k] + b.bonus + b.race, -99, 99);
    }
    return out;
  }, [statBonusById, statCurById]);

  const statForSkillsById = useMemo(() => {
    const out: Record<StatKey, { base: number; extra: number; total: number }> = {} as any;
    for (const k of STAT_KEYS) {
      const base = statCurById[k];
      const b = statBonusById[k];
      const extra = Math.min(10 - base, b.bonus) + b.race;
      out[k] = { base, extra, total: base + extra };
    }
    return out;
  }, [statBonusById, statCurById]);

  const derived = useMemo(() => {
    const body = statTotalById.BODY;
    const will = statTotalById.WILL;
    const spd = statTotalById.SPD;
    const avg = Math.trunc((body + will) / 2);

    const vigorFromState = toNumber(getAtPath(state, "characterRaw.statistics.vigor.cur"), NaN);
    const vigor =
      Number.isFinite(vigorFromState)
        ? Math.trunc(vigorFromState)
        : statVigorByProfession(getAtPath(state, "characterRaw.logicFields.profession")) ?? 0;

    return {
      vigor,
      stun: Math.max(avg, 10),
      run: spd * 3,
      leap: Math.trunc(spd * 0.6),
      hp: 5 * avg,
      sta: 5 * avg,
      enc: 10 * body,
      rec: avg,
      punch: diceWithMod("1d6", 2 * Math.trunc((body - 1) / 2) - 4),
      kick: diceWithMod("1d6", 2 * Math.trunc((body - 1) / 2)),
    };
  }, [state, statTotalById]);

  const levelBudget = useMemo(() => GAME_LEVELS.find((l) => l.key === level)?.points ?? 60, [level]);

  const spentStatPoints = useMemo(() => {
    return STAT_KEYS.reduce((acc, k) => acc + statCurById[k], 0);
  }, [statCurById]);

  const remainingStatPoints = useMemo(() => levelBudget - spentStatPoints, [levelBudget, spentStatPoints]);

  const generalBudget = useMemo(() => statForSkillsById.INT.total + statForSkillsById.REF.total, [statForSkillsById]);

  const budgets = useMemo(() => {
    let spentProfessional = 0;
    let spentCommon = 0;

    for (const [skillId, cur] of Object.entries(skillCurById)) {
      const meta = skillMetaById.get(skillId);
      const cost = meta?.isDifficult ? 2 : 1;
      const tokens = Math.max(0, clampInt(cur, 0, 99)) * cost;
      if (professionalSkillSet.has(skillId)) spentProfessional += tokens;
      else spentCommon += tokens;
    }

    return {
      spentProfessional,
      spentCommon,
      remainingProfessional: 44 - spentProfessional,
      remainingCommon: generalBudget - spentCommon,
    };
  }, [generalBudget, professionalSkillSet, skillCurById, skillMetaById]);

  const groupedCommonSkills = useMemo(() => {
    const list: SkillRowEntry[] = (catalog ?? [])
      .filter((s) => s.type === "common" && stateCommonSkillIdSet.has(toStateSkillId(s.id)))
      .map((s) => ({ ...s }));

    const definingStateId = definingSkillId ? toStateSkillId(definingSkillId) : null;
    if (definingStateId) {
      const existing = list.some((s) => toStateSkillId(s.id) === definingStateId);
      if (!existing) {
        const meta = (catalog ?? []).find((s) => toStateSkillId(s.id) === definingStateId);
        if (meta) {
          list.push({ ...meta, isDefining: true });
        }
      }
    }

    const languageIds = new Set(["language_dwarvish", "language_common_speech", "language_elder_speech"]);
    const languages = list
      .filter((s) => languageIds.has(s.id))
      .sort((a, b) => a.name.localeCompare(b.name));
    const rest = list.filter((s) => !languageIds.has(s.id));

    const byParam = new Map<string, SkillRowEntry[]>();
    for (const s of rest) {
      const p = normaliseStatKey(s.param) ?? "OTHER";
      const arr = byParam.get(p) ?? [];
      arr.push(s);
      byParam.set(p, arr);
    }
    for (const [p, arr] of byParam.entries()) {
      byParam.set(p, [...arr].sort((a, b) => a.name.localeCompare(b.name)));
    }

    const fmt = (k: StatKey) => {
      const v = statForSkillsById[k];
      const extra = v.extra;
      if (extra === 0) return `(${v.base})`;
      return `(${v.base}${extra > 0 ? `+${extra}` : `${extra}`})`;
    };

    // NOTE: BODY/WILL swapped as requested.
    const order: Array<{ key: string; title: string }> = [
      { key: "INT", title: `${lang === "ru" ? "ИНТЕЛЛЕКТ" : "INTELLIGENCE"} ${fmt("INT")}` },
      { key: "REF", title: `${lang === "ru" ? "РЕАКЦИЯ" : "REFLEX"} ${fmt("REF")}` },
      { key: "DEX", title: `${lang === "ru" ? "ЛОВКОСТЬ" : "DEXTERITY"} ${fmt("DEX")}` },
      { key: "WILL", title: `${lang === "ru" ? "ВОЛЯ" : "WILL"} ${fmt("WILL")}` },
      { key: "EMP", title: `${lang === "ru" ? "ЭМПАТИЯ" : "EMPATHY"} ${fmt("EMP")}` },
      { key: "CRA", title: `${lang === "ru" ? "РЕМЕСЛО" : "CRAFT"} ${fmt("CRA")}` },
      { key: "BODY", title: `${lang === "ru" ? "ТЕЛОСЛОЖЕНИЕ" : "BODY"} ${fmt("BODY")}` },
    ];

    const groups: Array<{ key: string; title: string; skills: SkillRowEntry[] }> = [];
    for (const o of order) {
      const arr = byParam.get(o.key) ?? [];
      if (arr.length > 0) groups.push({ key: o.key, title: o.title, skills: arr });
    }
    if (languages.length > 0) {
      groups.push({ key: "LANG", title: t.languagesHeader, skills: languages });
    }
    return groups;
  }, [catalog, lang, statForSkillsById, stateCommonSkillIdSet, t.languagesHeader]);

  const professionalSkillEntries = useMemo(() => {
    const raw = getAtPath(state, "characterRaw.skills.professional");
    const ids = isRecord(raw) ? Object.keys(raw) : [];
    return ids
      .map((id) => skillMetaById.get(id))
      .filter((x): x is SkillCatalogEntry => Boolean(x))
      .sort((a, b) => {
        const ab = (a.branchNumber ?? 0) - (b.branchNumber ?? 0);
        if (ab !== 0) return ab;
        return (a.professionalNumber ?? 0) - (b.professionalNumber ?? 0);
      });
  }, [skillMetaById, state]);

  const professionalBranches = useMemo(() => {
    const raw = getAtPath(state, "characterRaw.skills.professional");
    if (!isRecord(raw)) {
      return null as null | Array<{ title: string; skills: Array<{ id: string; name: string }> }>;
    }

    const branchesRaw = raw.branches;
    if (Array.isArray(branchesRaw)) {
      const titles = branchesRaw.map((v) => (typeof v === "string" ? v : String(v ?? "")));
      const byBranch: Array<Array<{ id: string; name: string; idx: number }>> = [[], [], []];

      for (const [key, value] of Object.entries(raw)) {
        const m = /^skill_(\d+)_(\d+)$/.exec(key);
        if (!m) continue;
        const branch = Number(m[1]);
        const idx = Number(m[2]);
        if (!Number.isFinite(branch) || !Number.isFinite(idx)) continue;
        if (branch < 1 || branch > 3) continue;
        if (!isRecord(value)) continue;
        const id = typeof value.id === "string" ? value.id : "";
        const name = typeof value.name === "string" ? value.name : String(value.name ?? "");
        if (!name) continue;
        byBranch[branch - 1]!.push({ id, name, idx });
      }

      return [0, 1, 2].map((i) => ({
        title:
          titles[i] && titles[i].trim().length > 0
            ? titles[i]
            : lang === "ru"
              ? `Ветка ${i + 1}`
              : `Branch ${i + 1}`,
        skills: byBranch[i]!.sort((a, b) => a.idx - b.idx).map((s) => ({ id: s.id, name: s.name })),
      }));
    }

    if (professionalSkillEntries.length === 0) {
      return null;
    }

    return [1, 2, 3].map((branchNum) => {
      const skills = professionalSkillEntries
        .filter((s) => (s.branchNumber ?? 0) === branchNum)
        .sort((a, b) => (a.professionalNumber ?? 0) - (b.professionalNumber ?? 0))
        .map((s) => ({ id: s.id, name: s.name }));
      return {
        title: lang === "ru" ? `Ветка ${branchNum}` : `Branch ${branchNum}`,
        skills,
      };
    });
  }, [lang, professionalSkillEntries, state, skillMetaById]);

  const canSubmit = useMemo(() => {
    if (remainingStatPoints < 0) return false;
    if (budgets.remainingProfessional < 0) return false;
    if (budgets.remainingCommon < 0) return false;
    return true;
  }, [budgets.remainingCommon, budgets.remainingProfessional, remainingStatPoints]);

  const rollbackCommonSkillsIfNeeded = (
    prevSkills: Record<string, number>,
    nextGeneralBudget: number,
    log: string[],
  ): Record<string, number> => {
    let spentCommon = 0;
    for (const [sid, cur] of Object.entries(prevSkills)) {
      if (professionalSkillSet.has(sid)) continue;
      const meta = skillMetaById.get(sid);
      const cost = meta?.isDifficult ? 2 : 1;
      spentCommon += Math.max(0, clampInt(cur, 0, 99)) * cost;
    }

    const baselineSkills = baselineRef.current?.skills ?? {};
    const skillsNext = { ...prevSkills };

    while (spentCommon > nextGeneralBudget && log.length > 0) {
      const lastSkillId = log.pop()!;
      const cur = skillsNext[lastSkillId] ?? 0;
      const minCur = baselineSkills[lastSkillId] ?? 0;
      if (cur <= minCur) continue;
      const meta = skillMetaById.get(lastSkillId);
      const cost = meta?.isDifficult ? 2 : 1;
      skillsNext[lastSkillId] = cur - 1;
      spentCommon -= cost;
    }

    return skillsNext;
  };

  const adjustStat = (key: StatKey, delta: number) => {
    const baseline = baselineRef.current?.stats?.[key] ?? 1;
    const nextStats = buildNextStatsWithDelta(statCurById, key, delta, baseline);
    setStatCurById(nextStats);

    if ((key === "INT" || key === "REF") && delta < 0) {
      const nextIntTotal = nextStats.INT + statBonusById.INT.bonus + statBonusById.INT.race;
      const nextRefTotal = nextStats.REF + statBonusById.REF.bonus + statBonusById.REF.race;
      const nextGeneralBudget = nextIntTotal + nextRefTotal;

      setCommonSpendLog((prevLog) => {
        const log = [...prevLog];
        setSkillCurById((prevSkills) => rollbackCommonSkillsIfNeeded(prevSkills, nextGeneralBudget, log));
        return log;
      });
    }
  };

  const adjustSkill = (skillId: string, delta: number) => {
    const baseline = baselineRef.current?.skills?.[skillId] ?? 0;
    const bonus = getSkillNumber(skillId, "bonus");
    const maxCur = Math.max(Math.max(6 - bonus, 0), Math.max(0, baseline));
    const meta = skillMetaById.get(skillId);
    const cost = meta?.isDifficult ? 2 : 1;
    const isProfessional = professionalSkillSet.has(skillId);

    setSkillCurById((prev) => {
      const current = prev[skillId] ?? 0;
      const nextVal = clampInt(current + delta, Math.max(0, baseline), maxCur);
      if (nextVal === current) return prev;

      if (delta > 0) {
        const remaining = isProfessional ? budgets.remainingProfessional : budgets.remainingCommon;
        if (remaining < cost) return prev;
      }

      return { ...prev, [skillId]: nextVal };
    });

    if (!isProfessional) {
      setCommonSpendLog((prevLog) => {
        const log = [...prevLog];
        if (delta > 0) {
          log.push(skillId);
          return log;
        }
        if (delta < 0) {
          for (let i = log.length - 1; i >= 0; i--) {
            if (log[i] === skillId) {
              log.splice(i, 1);
              break;
            }
          }
          return log;
        }
        return log;
      });
    }
  };

  const renderStepper = (
    value: number,
    opts: { onInc?: () => void; onDec?: () => void; disabled?: boolean; blankWhenZero?: boolean },
  ) => {
    const display = opts.blankWhenZero && value === 0 ? "" : String(value);
    return (
      <div className="ss-stepper">
        <input className="ss-stepper-input" value={display} readOnly disabled={opts.disabled} />
        <div className="ss-stepper-controls">
          <button
            type="button"
            className="ss-stepper-btn"
            disabled={opts.disabled || !opts.onInc}
            onClick={opts.onInc}
            aria-label="Increase"
          >
            <svg width="12" height="12" viewBox="0 0 12 12" aria-hidden="true" focusable="false">
              <path d="M6 3l4 6H2z" fill="currentColor" />
            </svg>
          </button>
          <button
            type="button"
            className="ss-stepper-btn"
            disabled={opts.disabled || !opts.onDec}
            onClick={opts.onDec}
            aria-label="Decrease"
          >
            <svg width="12" height="12" viewBox="0 0 12 12" aria-hidden="true" focusable="false">
              <path d="M2 3h8l-4 6z" fill="currentColor" />
            </svg>
          </button>
        </div>
      </div>
    );
  };

  const pillValue = (path: string) => clampInt(toNumber(getAtPath(state, path), 0), -99, 99);

  if (catalogError) {
    return <div className="survey-error">{catalogError}</div>;
  }

  return (
    <div className="stats-skills-node">
      <div className="ss-section">
        <div className="ss-section-title">{t.sections.budgets}</div>
        <div className="ss-budgets">
          <div className={`ss-budget ${remainingStatPoints < 0 ? "bad" : ""}`}>
            <div className="label">{t.budgets.stats}</div>
            <div className="value">{remainingStatPoints}</div>
          </div>
          <div className={`ss-budget ${budgets.remainingProfessional < 0 ? "bad" : ""}`}>
            <div className="label">{t.budgets.professional}</div>
            <div className="value">{budgets.remainingProfessional}</div>
          </div>
          <div className={`ss-budget ${budgets.remainingCommon < 0 ? "bad" : ""}`}>
            <div className="label">{t.budgets.common}</div>
            <div className="value">{budgets.remainingCommon}</div>
          </div>
        </div>
      </div>

      <div className="ss-section">
        <div className="ss-section-title">{t.sections.level}</div>
        <div className="ss-radio-row">
          {GAME_LEVELS.map((l) => (
            <label key={l.key} className={`ss-radio ${level === l.key ? "active" : ""}`}>
              <input
                type="radio"
                name={`level-${questionId}`}
                checked={level === l.key}
                onChange={() => setLevel(l.key)}
                disabled={disabled}
              />
              <span>
                {t.levels[l.key]} ({l.points})
              </span>
            </label>
          ))}
        </div>
      </div>

      <div className="ss-section">
        <div className="ss-section-title">{t.sections.stats}</div>
        <div className="ss-grid-3">
          {STAT_KEYS.map((k) => {
            const base = statCurById[k];
            const b = statBonusById[k];
            const baseline = baselineRef.current?.stats?.[k] ?? 1;
            const canInc = !disabled && remainingStatPoints > 0 && base < 10;
            const canDec = !disabled && base > Math.max(1, baseline);
            return (
              <div key={k} className="ss-stat-card">
                <div className="ss-stat-title">
                  {STAT_META[k][lang].name} <span className="muted">({STAT_META[k][lang].abbr})</span>
                </div>
                <div className="ss-stat-row">
                  {renderStepper(base, {
                    disabled,
                    onInc: canInc ? () => adjustStat(k, 1) : undefined,
                    onDec: canDec ? () => adjustStat(k, -1) : undefined,
                  })}
                  <div className="ss-pill" title={t.cols.bonus}>
                    {b.bonus}
                  </div>
                  <div className="ss-pill" title={t.cols.racial}>
                    {b.race}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      <div className="ss-section">
        <div className="ss-section-title">{t.sections.computed}</div>
        <div className="ss-grid-3">
          <div className="ss-stat-card">
            <div className="ss-stat-title">{t.computedLabels.vigor}</div>
            <div className="ss-stat-row">
              <div className="ss-pill wide">{derived.vigor}</div>
              <div className="ss-pill">{pillValue("characterRaw.statistics.vigor.bonus")}</div>
              <div className="ss-pill">{pillValue("characterRaw.statistics.vigor.race_bonus")}</div>
            </div>
          </div>
          <div className="ss-stat-card">
            <div className="ss-stat-title">{t.computedLabels.stun}</div>
            <div className="ss-stat-row">
              <div className="ss-pill wide">{derived.stun}</div>
              <div className="ss-pill">{pillValue("characterRaw.statistics.calculated.STUN.bonus")}</div>
              <div className="ss-pill">{pillValue("characterRaw.statistics.calculated.STUN.race_bonus")}</div>
            </div>
          </div>
          <div className="ss-stat-card">
            <div className="ss-stat-title">{t.computedLabels.run}</div>
            <div className="ss-stat-row">
              <div className="ss-pill wide">{derived.run}</div>
              <div className="ss-pill">{pillValue("characterRaw.statistics.calculated.run.bonus")}</div>
              <div className="ss-pill">{pillValue("characterRaw.statistics.calculated.run.race_bonus")}</div>
            </div>
          </div>
          <div className="ss-stat-card">
            <div className="ss-stat-title">{t.computedLabels.leap}</div>
            <div className="ss-stat-row">
              <div className="ss-pill wide">{derived.leap}</div>
              <div className="ss-pill">{pillValue("characterRaw.statistics.calculated.leap.bonus")}</div>
              <div className="ss-pill">{pillValue("characterRaw.statistics.calculated.leap.race_bonus")}</div>
            </div>
          </div>
          <div className="ss-stat-card">
            <div className="ss-stat-title">{t.computedLabels.hp}</div>
            <div className="ss-stat-row">
              <div className="ss-pill wide">{derived.hp}</div>
              <div className="ss-pill">{pillValue("characterRaw.statistics.calculated.max_HP.bonus")}</div>
              <div className="ss-pill">{pillValue("characterRaw.statistics.calculated.max_HP.race_bonus")}</div>
            </div>
          </div>
          <div className="ss-stat-card">
            <div className="ss-stat-title">{t.computedLabels.sta}</div>
            <div className="ss-stat-row">
              <div className="ss-pill wide">{derived.sta}</div>
              <div className="ss-pill">{pillValue("characterRaw.statistics.calculated.STA.bonus")}</div>
              <div className="ss-pill">{pillValue("characterRaw.statistics.calculated.STA.race_bonus")}</div>
            </div>
          </div>
          <div className="ss-stat-card">
            <div className="ss-stat-title">{t.computedLabels.enc}</div>
            <div className="ss-stat-row">
              <div className="ss-pill wide">{derived.enc}</div>
              <div className="ss-pill">{pillValue("characterRaw.statistics.calculated.ENC.bonus")}</div>
              <div className="ss-pill">{pillValue("characterRaw.statistics.calculated.ENC.race_bonus")}</div>
            </div>
          </div>
          <div className="ss-stat-card">
            <div className="ss-stat-title">{t.computedLabels.rec}</div>
            <div className="ss-stat-row">
              <div className="ss-pill wide">{derived.rec}</div>
              <div className="ss-pill">{pillValue("characterRaw.statistics.calculated.REC.bonus")}</div>
              <div className="ss-pill">{pillValue("characterRaw.statistics.calculated.REC.race_bonus")}</div>
            </div>
          </div>
          <div className="ss-stat-card">
            <div className="ss-stat-title">{t.computedLabels.punch}</div>
            <div className="ss-stat-row">
              <div className="ss-pill wide">{derived.punch}</div>
              <div className="ss-pill">{pillValue("characterRaw.statistics.calculated.bonus_punch.bonus")}</div>
              <div className="ss-pill">{pillValue("characterRaw.statistics.calculated.bonus_punch.race_bonus")}</div>
            </div>
          </div>
          <div className="ss-stat-card">
            <div className="ss-stat-title">{t.computedLabels.kick}</div>
            <div className="ss-stat-row">
              <div className="ss-pill wide">{derived.kick}</div>
              <div className="ss-pill">{pillValue("characterRaw.statistics.calculated.bonus_kick.bonus")}</div>
              <div className="ss-pill">{pillValue("characterRaw.statistics.calculated.bonus_kick.race_bonus")}</div>
            </div>
          </div>
        </div>
      </div>

      <div className="ss-section">
        <div className="ss-section-title">{t.sections.skills}</div>
        {!catalog && <div className="shop-muted">{t.loading}</div>}
        {catalog && (
          <>
            <div className="ss-skills-header">
              <span>{t.cols.value}</span>
              <span>{t.cols.bonus}</span>
              <span>{t.cols.racial}</span>
              <span>{t.cols.base}</span>
              <span></span>
            </div>
            <div className="ss-groups-grid">
              {groupedCommonSkills.map((g) => (
                <div key={g.key} className="ss-skill-group">
                  <div className="ss-skill-group-title">{g.title}</div>
                  <div className="ss-skill-list">
                    {g.skills.map((s) => {
                      const stateId = toStateSkillId(s.id);
                      const isDefining = Boolean((s as SkillRowEntry).isDefining);
                      const cur = clampInt(skillCurById[stateId] ?? 0, 0, 99);
                      const baseline = baselineRef.current?.skills?.[stateId] ?? 0;
                      const bonus = getSkillNumber(stateId, "bonus");
                      const race = getSkillNumber(stateId, "race_bonus");
                      const maxCur = Math.max(Math.max(6 - bonus, 0), Math.max(0, baseline));
                      const statKey = normaliseStatKey(s.param) ?? "INT";
                      const base = (statForSkillsById[statKey]?.total ?? 0) + cur + bonus + race;

                      const cost = s.isDifficult ? 2 : 1;
                      const isProfessional = professionalSkillSet.has(stateId);
                      const remaining = isProfessional ? budgets.remainingProfessional : budgets.remainingCommon;
                      const canInc = !disabled && cur < maxCur && remaining >= cost;
                      const canDec = !disabled && cur > Math.max(0, baseline);

                      return (
                        <div
                          key={s.id}
                          className={`ss-skill-row ${isProfessional ? "pro-skill" : ""} ${isDefining ? "defining-skill" : ""}`}
                        >
                          {renderStepper(cur, {
                            disabled,
                            blankWhenZero: true,
                            onInc: canInc ? () => adjustSkill(stateId, 1) : undefined,
                            onDec: canDec ? () => adjustSkill(stateId, -1) : undefined,
                          })}
                          <div className="ss-pill ss-pill-num">{bonus}</div>
                          <div className="ss-pill ss-pill-num">{race}</div>
                          <div className="ss-pill ss-pill-base">{base}</div>
                          <div className="ss-skill-name">
                            {s.name}
                            {s.isDifficult && <span className="muted"> (2)</span>}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              ))}
            </div>
          </>
        )}
      </div>

      <div className="ss-section">
        <div className="ss-section-title">{t.sections.professional}</div>
        {!professionalBranches && <div className="shop-muted">—</div>}
        {professionalBranches && (
          <div className="ss-pro-grid">
            {professionalBranches.map((b, idx) => (
              <div
                key={`${idx}-${b.title}`}
                className={`ss-pro-branch ${idx === 0 ? "blue" : idx === 1 ? "green" : "red"}`}
              >
                <div className="ss-pro-title">{b.title}</div>
                <div className="ss-pro-list">
                  {b.skills.length === 0 && <div className="shop-muted">—</div>}
                  {b.skills.map((s) => {
                    const meta = skillMetaById.get(s.id);
                    const statKey = meta?.param ? normaliseStatKey(meta.param) : null;
                    const rawAbbr = statKey ? (STAT_META[statKey]?.[lang]?.abbr ?? statKey) : "";
                    const paramAbbr = rawAbbr ? (lang === "ru" ? rawAbbr.toUpperCase() : rawAbbr) : "";
                    const suffix = paramAbbr ? ` (${paramAbbr})` : "";
                    return (
                      <div key={`${s.id}-${s.name}`} className="ss-pro-row">
                        {renderStepper(0, { disabled: true })}
                        <div className="ss-pro-name">
                          {s.name}
                          {suffix ? <span className="ss-skill-param">{suffix}</span> : null}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      <div className="survey-actions">
        <button
          type="button"
          onClick={() => {
            onSubmit({ v: 1, level, stats: statCurById, skills: skillCurById });
          }}
          disabled={disabled || !canSubmit}
          className="btn btn-primary"
        >
          {lang === "ru" ? "Продолжить" : "Continue"}
        </button>
      </div>
    </div>
  );
}
