import jsonLogic from 'json-logic-js';
import { db } from '../db/pool.js';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import crypto from 'crypto';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const defaultCharacterPath = path.join(__dirname, '../data/defaultCharacter.json');
const defaultCharacter = JSON.parse(fs.readFileSync(defaultCharacterPath, 'utf-8'));

type AnswerValue = { type: "number"; data: number } | { type: "string"; data: string };
type AnswerInput = { questionId: string; answerIds: string[]; value?: AnswerValue };

type NextQuestionRequest = {
  surveyId?: string;
  lang?: string;
  answers?: AnswerInput[];
};

type ShopPurchase = {
  sourceId: string;
  id: string;
  qty: number;
};

type ShopAnswerValue = {
  v?: number;
  purchases?: ShopPurchase[];
  ignoreWarnings?: boolean;
};

type QuestionRow = {
  id: string;
  body: string | null;
  qtype: string;
  metadata: Record<string, unknown>;
};

type AnswerOptionRow = {
  id: string;
  label: string | null;
  sortOrder: number;
  metadata: Record<string, unknown>;
};

type AnswerOptionQueryRow = AnswerOptionRow & {
  visibleRule: Record<string, unknown> | null;
};

type AnswerOptionMetaRow = {
  id: string;
  metadata: Record<string, unknown>;
};

type QuestionMetaRow = {
  id: string;
  metadata: Record<string, unknown>;
};

type CounterSetConfig = {
  id: string;
  value: unknown;
};

type CounterIncrementConfig = {
  id: string;
  step?: unknown;
};

const SHOP_ALLOWED_TABLES = new Set(['wcc_items_weapons', 'wcc_items_armor', 'wcc_item_weapons_v', 'wcc_item_armors_v']);

function isSafeIdentifier(value: string): boolean {
  return /^[a-zA-Z_][a-zA-Z0-9_]*$/.test(value);
}

function toStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((v): v is string => typeof v === 'string' && v.length > 0);
}

function toFiniteNumber(value: unknown, fallback = 0): number {
  const n = typeof value === 'number' ? value : Number(value);
  return Number.isFinite(n) ? n : fallback;
}

function parseShopAnswerValue(raw: string): ShopAnswerValue | null {
  if (typeof raw !== 'string' || raw.trim().length === 0) return null;
  try {
    const parsed = JSON.parse(raw) as unknown;
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) return null;
    return parsed as ShopAnswerValue;
  } catch {
    return null;
  }
}

type EvaluateContext = {
  i18nTexts?: Map<string, string>;
};

type TransitionRow = {
  toQuestionId: string;
  viaAnswerId: string | null;
  priority: number;
  rule: Record<string, unknown> | null;
};

type EffectRow = {
  answerId: string;
  body: Record<string, unknown>;
};

type QuestionEffectRow = {
  questionId: string;
  body: Record<string, unknown>;
};

type I18nRow = {
  id: string;
  lang: string;
  text: string;
};

type SurveyState = Record<string, unknown>;

type HistoryQuestion = {
  questionId: string;
  path: string[];
  pathTexts: string[];
};

type NextQuestionResponse = {
  done: boolean;
  question?: QuestionRow;
  answerOptions?: AnswerOptionRow[];
  state: SurveyState;
  historyAnswers: AnswerInput[];
  historyQuestions?: HistoryQuestion[];
  debug_info?: {
    state_lang?: string;
    state_answers?: SurveyState['answers'];
    state_values?: SurveyState['values'];
    state_counters?: SurveyState['counters'];
    question_metadata?: Record<string, unknown>;
  };
};

// Structure for preloaded survey data
type SurveyData = {
  // i18n texts: Map<id, Map<lang, text>>
  i18nTexts: Map<string, Map<string, string>>;
  // Questions: Map<questionId, QuestionRow>
  questions: Map<string, QuestionRow>;
  // Answer options: Map<questionId, AnswerOptionRow[]>
  answerOptions: Map<string, AnswerOptionRow[]>;
  // Visibility rules: Map<answerId, rule>
  visibleRules: Map<string, Record<string, unknown>>;
  // Effects: Map<answerId, EffectRow[]>
  effects: Map<string, EffectRow[]>;
  // Question effects: Map<questionId, QuestionEffectRow[]>
  questionEffects: Map<string, QuestionEffectRow[]>;
  // Answer metadata: Map<answerId, metadata>
  answerMetadata: Map<string, Record<string, unknown>>;
  // Question metadata: Map<questionId, metadata>
  questionMetadata: Map<string, Record<string, unknown>>;
  // Transitions: Map<fromQuestionId, TransitionRow[]>
  transitions: Map<string, TransitionRow[]>;
  // Entry question ID
  entryQuestionId: string;
};

const DEFAULT_SURVEY_ID = 'witcher_cc';
const DEFAULT_LANG = 'en';

/**
 * Generates UUID from string, identical to SQL function ck_id
 * @param src - source string
 * @returns UUID as string
 */
function ck_id(src: string): string {
  const _ns = '12345678-9098-7654-3212-345678909876';
  const hash = crypto.createHash('md5').update(_ns + src).digest('hex');
  return (
    hash.substring(0, 8) + '-' +
    hash.substring(8, 12) + '-' +
    hash.substring(12, 16) + '-' +
    hash.substring(16, 20) + '-' +
    hash.substring(20, 32)
  );
};

/**
 * Extracts string values from jsonlogic expression that may be UUIDs
 */
function extractStringsFromJsonLogic(expr: unknown, strings: Set<string>): void {
  if (typeof expr === 'string') {
    const jsonLogicOperators = ['if', '==', '!=', '>', '<', '>=', '<=', 'and', 'or', '!', '!!', 'var', 'cat', '+', '-', '*', '/', '%', 'in', 'missing', 'missing_some'];
    if (!jsonLogicOperators.includes(expr) && expr.length > 3) {
      strings.add(expr);
    }
  } else if (Array.isArray(expr)) {
    for (const item of expr) {
      extractStringsFromJsonLogic(item, strings);
    }
  } else if (expr && typeof expr === 'object') {
    // Skip objects with 'var' (these are variables, not static values)
    if (!('var' in expr)) {
      for (const value of Object.values(expr)) {
        extractStringsFromJsonLogic(value, strings);
      }
    }
  }
}

/**
 * Recursively collects all i18n_uuid from object
 */
function collectI18nUuids(value: unknown, uuids: Set<string>): void {
  if (value === null || value === undefined) {
    return;
  }

  if (typeof value === 'object' && !Array.isArray(value)) {
    const obj = value as Record<string, unknown>;
    
    // Check if this is an object with i18n_uuid
    if ('i18n_uuid' in obj && typeof obj.i18n_uuid === 'string') {
      uuids.add(obj.i18n_uuid);
    }
    
    // Check if this is an object with i18n_uuid_array
    if ('i18n_uuid_array' in obj && Array.isArray(obj.i18n_uuid_array)) {
      // First element is separator, rest are UUIDs
      const arr = obj.i18n_uuid_array as unknown[];
      for (let i = 1; i < arr.length; i++) {
        if (typeof arr[i] === 'string') {
          uuids.add(arr[i] as string);
        }
      }
    }
    
    // Recursively process all object values
    for (const val of Object.values(obj)) {
      collectI18nUuids(val, uuids);
    }
  } else if (Array.isArray(value)) {
    for (const item of value) {
      collectI18nUuids(item, uuids);
    }
  }
}

/**
 * Recursively resolves i18n_uuid objects in a value using i18nTextsMap
 */
function resolveI18nValue(value: unknown, i18nTextsMap: Map<string, Map<string, string>>, lang: string): unknown {
  if (value === null || value === undefined) {
    return value;
  }
  
  if (typeof value === 'object' && !Array.isArray(value)) {
    const obj = value as Record<string, unknown>;
    
    // Check if this is an object with i18n_uuid
    if ('i18n_uuid' in obj && typeof obj.i18n_uuid === 'string' && Object.keys(obj).length === 1) {
      const texts = i18nTextsMap.get(obj.i18n_uuid);
      if (texts) {
        return texts.get(lang) ?? texts.get('en') ?? obj.i18n_uuid;
      }
      return obj.i18n_uuid;
    }
    
    // Recursively process object
    const resolved: Record<string, unknown> = {};
    for (const key in obj) {
      resolved[key] = resolveI18nValue(obj[key], i18nTextsMap, lang);
    }
    return resolved;
  }
  
  if (Array.isArray(value)) {
    return value.map(item => resolveI18nValue(item, i18nTextsMap, lang));
  }
  
  return value;
}

/**
 * Evaluates path segment value (handles var and jsonlogic_expression)
 */
function evaluatePathSegment(segment: unknown, state: SurveyState): string {
  if (typeof segment === 'string') {
    return segment;
  } else if (segment && typeof segment === 'object') {
    if ('var' in segment) {
      const value = evaluate(segment, state);
      return value !== undefined && value !== null ? String(value) : '';
    } else if ('jsonlogic_expression' in segment) {
      const value = evaluateJsonLogicExpression(segment.jsonlogic_expression, state);
      return value !== undefined && value !== null ? String(value) : '';
    }
  }
  return String(segment);
}

/**
 * Resolves i18n text for path segment value
 */
function resolvePathSegmentText(
  segment: unknown,
  state: SurveyState,
  i18nTexts: Map<string, Map<string, string>>,
  lang: string,
): string {
  if (typeof segment === 'string') {
    const texts = i18nTexts.get(segment);
    return texts?.get(lang) ?? texts?.get('en') ?? segment;
  } else if (segment && typeof segment === 'object') {
    if ('var' in segment) {
      const value = evaluate(segment, state);
      if (value !== undefined && value !== null) {
        const valueStr = String(value);
        const texts = i18nTexts.get(valueStr);
        return texts?.get(lang) ?? texts?.get('en') ?? valueStr;
      }
      return '';
    } else if ('jsonlogic_expression' in segment) {
      const value = evaluateJsonLogicExpression(segment.jsonlogic_expression, state);
      if (value !== undefined && value !== null) {
        const valueStr = String(value);
        const texts = i18nTexts.get(valueStr);
        return texts?.get(lang) ?? texts?.get('en') ?? valueStr;
      }
      return '';
    }
  }
  return String(segment);
}

/**
 * Resolves i18n_uuid objects and UUID strings in computed state
 * Only resolves UUIDs that actually exist in i18n_text table
 */
async function resolveI18nInState(
  state: SurveyState,
  lang: string,
  surveyId: string,
): Promise<void> {
  // Collect all UUIDs from state (strings that look like UUIDs, and i18n_uuid objects)
  const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  const uuidsToResolve = new Set<string>();
  
  const collectUuidsFromValue = (value: unknown): void => {
    if (value === null || value === undefined) {
      return;
    }
    
    if (typeof value === 'string' && uuidPattern.test(value)) {
      uuidsToResolve.add(value);
    } else if (typeof value === 'object' && !Array.isArray(value)) {
      const obj = value as Record<string, unknown>;
      if ('i18n_uuid' in obj && typeof obj.i18n_uuid === 'string') {
        uuidsToResolve.add(obj.i18n_uuid);
      }
      for (const val of Object.values(obj)) {
        collectUuidsFromValue(val);
      }
    } else if (Array.isArray(value)) {
      for (const item of value) {
        collectUuidsFromValue(item);
      }
    }
  };
  
  collectUuidsFromValue(state);
  
  if (uuidsToResolve.size === 0) {
    return;
  }
  
  // Load i18n texts for found UUIDs (only those that exist in DB)
  const i18nResult = await db.query<I18nRow>(
    `
      SELECT id::text AS "id", lang AS "lang", text AS "text"
      FROM i18n_text
      WHERE id::text = ANY($1::text[])
        AND lang IN ($2, 'en')
    `,
    [Array.from(uuidsToResolve), lang],
  );
  
  const i18nTextsMap = new Map<string, Map<string, string>>();
  for (const row of i18nResult.rows) {
    if (!i18nTextsMap.has(row.id)) {
      i18nTextsMap.set(row.id, new Map());
    }
    i18nTextsMap.get(row.id)!.set(row.lang, row.text);
  }
  
  // Resolve UUIDs in state (only those that exist in i18nTextsMap)
  const resolveValue = (value: unknown): unknown => {
    if (value === null || value === undefined) {
      return value;
    }
    
    if (typeof value === 'string' && uuidPattern.test(value)) {
      const texts = i18nTextsMap.get(value);
      if (texts) {
        return texts.get(lang) ?? texts.get('en') ?? value;
      }
      return value;
    }
    
    if (typeof value === 'object' && !Array.isArray(value)) {
      const obj = value as Record<string, unknown>;
      if ('i18n_uuid' in obj && typeof obj.i18n_uuid === 'string' && Object.keys(obj).length === 1) {
        const texts = i18nTextsMap.get(obj.i18n_uuid);
        if (texts) {
          return texts.get(lang) ?? texts.get('en') ?? obj.i18n_uuid;
        }
        return obj.i18n_uuid;
      }
      
      // Recursively process object
      const resolved: Record<string, unknown> = {};
      for (const key in obj) {
        resolved[key] = resolveValue(obj[key]);
      }
      return resolved;
    }
    
    if (Array.isArray(value)) {
      return value.map(item => resolveValue(item));
    }
    
    return value;
  };
  
  // Apply resolution to entire state recursively
  const updateStateRecursively = (target: Record<string, unknown>, source: unknown): void => {
    if (source === null || source === undefined) {
      return;
    }
    
    if (typeof source === 'object' && !Array.isArray(source)) {
      const sourceObj = source as Record<string, unknown>;
      for (const key in sourceObj) {
        const sourceValue = sourceObj[key];
        const targetValue = target[key];
        
        if (typeof sourceValue === 'string' && uuidPattern.test(sourceValue)) {
          const texts = i18nTextsMap.get(sourceValue);
          if (texts) {
            target[key] = texts.get(lang) ?? texts.get('en') ?? sourceValue;
          }
        } else if (typeof sourceValue === 'object' && sourceValue !== null && !Array.isArray(sourceValue)) {
          const sourceObjValue = sourceValue as Record<string, unknown>;
          if ('i18n_uuid' in sourceObjValue && typeof sourceObjValue.i18n_uuid === 'string' && Object.keys(sourceObjValue).length === 1) {
            const texts = i18nTextsMap.get(sourceObjValue.i18n_uuid);
            if (texts) {
              target[key] = texts.get(lang) ?? texts.get('en') ?? sourceObjValue.i18n_uuid;
            }
          } else if (typeof targetValue === 'object' && targetValue !== null && !Array.isArray(targetValue)) {
            updateStateRecursively(targetValue as Record<string, unknown>, sourceValue);
          } else {
            target[key] = resolveValue(sourceValue);
          }
        } else if (Array.isArray(sourceValue)) {
          target[key] = resolveValue(sourceValue);
        } else {
          target[key] = sourceValue;
        }
      }
    }
  };
  
  updateStateRecursively(state as Record<string, unknown>, state);
}

// Register ck_id operation in jsonLogic
jsonLogic.add_operation('ck_id', (src: unknown): string => {
  if (typeof src === 'string') {
    return ck_id(src);
  }
  // If argument is not a string, convert to string
  const strArg = src !== null && src !== undefined ? String(src) : '';
  return ck_id(strArg);
});

/**
 * Loads minimal data only for state computation
 * (only metadata and effects, without body/label of questions and answers)
 */
async function loadStateData(
  surveyId: string,
  historyAnswers: AnswerInput[],
): Promise<{
  questionMetadata: Map<string, Record<string, unknown>>;
  answerMetadata: Map<string, Record<string, unknown>>;
  effects: Map<string, EffectRow[]>;
  questionEffects: Map<string, QuestionEffectRow[]>;
  entryQuestionId: string;
}> {
  // Collect unique question and answer IDs from history
  const neededQuestionIds = new Set<string>();
  const neededAnswerIds = new Set<string>();
  
  for (const answer of historyAnswers) {
    neededQuestionIds.add(answer.questionId);
    for (const answerId of answer.answerIds) {
      neededAnswerIds.add(answerId);
    }
  }
  
  // If no history, need to find entry question
  let entryQuestionId = '';
  if (neededQuestionIds.size === 0) {
    const entryQuestionResult = await db.query<{ qu_id: string }>(
      `
        SELECT q.qu_id
        FROM questions q
        WHERE q.su_su_id = $1
          AND NOT EXISTS (
            SELECT 1 FROM transitions t WHERE t.to_qu_qu_id = q.qu_id
          )
        ORDER BY q.qu_id
        LIMIT 1
      `,
      [surveyId],
    );
    
    entryQuestionId = entryQuestionResult.rows[0]?.qu_id ?? '';
    if (entryQuestionId) {
      neededQuestionIds.add(entryQuestionId);
    }
  }
  
  const questionIdsArray = Array.from(neededQuestionIds);
  const answerIdsArray = Array.from(neededAnswerIds);
  
  if (questionIdsArray.length === 0) {
    throw new Error(`No questions found for survey ${surveyId}`);
  }

  // 1. Load only question metadata (without body)
  const questionsResult = await db.query<{
    qu_id: string;
    metadata: Record<string, unknown>;
  }>(
    `
      SELECT q.qu_id, q.metadata
      FROM questions q
      WHERE q.su_su_id = $1 AND q.qu_id = ANY($2::text[])
    `,
    [surveyId, questionIdsArray],
  );

  // 2. Load only selected answer metadata (without label)
  const answerMetadataResult = answerIdsArray.length > 0
    ? await db.query<{
        an_id: string;
        metadata: Record<string, unknown>;
      }>(
          `
            SELECT a.an_id, a.metadata
            FROM answer_options a
            WHERE a.an_id = ANY($1::text[])
          `,
          [answerIdsArray],
        )
    : { rows: [] };

  // 3. Load effects only for selected answers
  const effectsResult = answerIdsArray.length > 0
    ? await db.query<EffectRow>(
        `
          SELECT e.an_an_id AS "answerId", e.body AS "body"
          FROM effects e
          WHERE e.an_an_id = ANY($1::text[])
            AND e.an_an_id IS NOT NULL
        `,
        [answerIdsArray],
      )
    : { rows: [] };

  // 4. Load effects only for questions from history
  const questionEffectsResult = questionIdsArray.length > 0
    ? await db.query<QuestionEffectRow>(
        `
          SELECT e.qu_qu_id AS "questionId", e.body AS "body"
          FROM effects e
          WHERE e.qu_qu_id = ANY($1::text[])
            AND e.qu_qu_id IS NOT NULL
        `,
        [questionIdsArray],
      )
    : { rows: [] };

  // Collect UUIDs for i18n from effects (may be needed for jsonlogic computation)

  const i18nUuids = new Set<string>();
  for (const row of effectsResult.rows) {
    collectI18nUuids(row.body, i18nUuids);
  }
  for (const row of questionEffectsResult.rows) {
    collectI18nUuids(row.body, i18nUuids);
  }
  for (const row of answerMetadataResult.rows) {
    if (row.metadata) {
      collectI18nUuids(row.metadata, i18nUuids);
    }
  }

  // Load i18n texts only for effects (if needed)
  const i18nTextsMap = new Map<string, Map<string, string>>();
  if (i18nUuids.size > 0) {
    const i18nResult = await db.query<I18nRow>(
      `
        SELECT id::text AS "id", lang AS "lang", text AS "text"
        FROM i18n_text
        WHERE id::text = ANY($1::text[])
          AND lang IN ('en', 'ru')
      `,
      [Array.from(i18nUuids)],
    );

    for (const row of i18nResult.rows) {
      if (!i18nTextsMap.has(row.id)) {
        i18nTextsMap.set(row.id, new Map());
      }
      i18nTextsMap.get(row.id)!.set(row.lang, row.text);
    }
  }

  // Build data structures
  const questionMetadata = new Map<string, Record<string, unknown>>();
  for (const row of questionsResult.rows) {
    questionMetadata.set(row.qu_id, row.metadata ?? {});
  }

  const answerMetadata = new Map<string, Record<string, unknown>>();
  for (const row of answerMetadataResult.rows) {
    answerMetadata.set(row.an_id, row.metadata ?? {});
  }

  const effects = new Map<string, EffectRow[]>();
  for (const row of effectsResult.rows) {
    if (!effects.has(row.answerId)) {
      effects.set(row.answerId, []);
    }
    effects.get(row.answerId)!.push(row);
  }

  const questionEffects = new Map<string, QuestionEffectRow[]>();
  for (const row of questionEffectsResult.rows) {
    if (!questionEffects.has(row.questionId)) {
      questionEffects.set(row.questionId, []);
    }
    questionEffects.get(row.questionId)!.push(row);
  }

  return {
    questionMetadata,
    answerMetadata,
    effects,
    questionEffects,
    entryQuestionId,
  };
}

/**
 * Загружает минимально необходимые данные для формирования ответа
 * на основе переданных ответов и следующего вопроса
 */
async function loadMinimalSurveyData(
  surveyId: string,
  lang: string,
  historyAnswers: AnswerInput[],
  nextQuestionId: string | null,
): Promise<SurveyData> {
  // Collect unique question and answer IDs we need
  const neededQuestionIds = new Set<string>();
  const neededAnswerIds = new Set<string>();
  
  // Add only next question (history loaded separately)
  if (nextQuestionId) {
    neededQuestionIds.add(nextQuestionId);
  }
  
  // If no history and no next question, need to find entry question
  if (neededQuestionIds.size === 0 && historyAnswers.length === 0) {
    const entryQuestionResult = await db.query<{ qu_id: string }>(
      `
        SELECT q.qu_id
        FROM questions q
        WHERE q.su_su_id = $1
          AND NOT EXISTS (
            SELECT 1 FROM transitions t WHERE t.to_qu_qu_id = q.qu_id
          )
        ORDER BY q.qu_id
        LIMIT 1
      `,
      [surveyId],
    );
    
    const entryQuestionId = entryQuestionResult.rows[0]?.qu_id;
    if (entryQuestionId) {
      neededQuestionIds.add(entryQuestionId);
    }
  }
  
  // Add questions that transitions from last question lead to
  if (historyAnswers.length > 0) {
    const lastQuestionId = historyAnswers[historyAnswers.length - 1]!.questionId;
    const transitionsResult = await db.query<{
      to_qu_qu_id: string;
    }>(
      `
        SELECT DISTINCT t.to_qu_qu_id
        FROM transitions t
        WHERE t.from_qu_qu_id = $1
      `,
      [lastQuestionId],
    );
    
    for (const row of transitionsResult.rows) {
      if (row.to_qu_qu_id) {
        neededQuestionIds.add(row.to_qu_qu_id);
      }
    }
  }
  
  const questionIdsArray = Array.from(neededQuestionIds);
  
  if (questionIdsArray.length === 0) {
    // Return empty structure if no questions to load
    return {
      i18nTexts: new Map(),
      questions: new Map(),
      answerOptions: new Map(),
      visibleRules: new Map(),
      effects: new Map(),
      questionEffects: new Map(),
      answerMetadata: new Map(),
      questionMetadata: new Map(),
      transitions: new Map(),
      entryQuestionId: '',
    };
  }

  // 1. Load only needed questions (for next question and transitions)
  const questionsResult = await db.query<{
    qu_id: string;
    body: string | null;
    qtype: string;
    metadata: Record<string, unknown>;
  }>(
    `
      SELECT
        q.qu_id,
        q.qtype,
        q.metadata,
        COALESCE(b_lang.text, b_en.text) AS "body"
      FROM questions q
      LEFT JOIN i18n_text b_lang ON b_lang.id = q.body AND b_lang.lang = $2
      LEFT JOIN i18n_text b_en ON b_en.id = q.body AND b_en.lang = 'en'
      WHERE q.su_su_id = $1
        AND q.qu_id = ANY($3::text[])
    `,
    [surveyId, lang, questionIdsArray],
  );

  // 2. Load only answer options for next questions
  const answerOptionsResult = await db.query<{
    an_id: string;
    qu_qu_id: string;
    label: string | null;
    sort_order: number;
    metadata: Record<string, unknown>;
    visible_rule: Record<string, unknown> | null;
  }>(
    `
      SELECT
        a.an_id,
        a.qu_qu_id,
        a.metadata,
        a.sort_order,
        COALESCE(l_lang.text, l_en.text) AS "label",
        r.body AS "visible_rule"
      FROM answer_options a
      LEFT JOIN i18n_text l_lang ON l_lang.id::text = a.label AND l_lang.lang = $2
      LEFT JOIN i18n_text l_en ON l_en.id::text = a.label AND l_en.lang = 'en'
      LEFT JOIN rules r ON r.ru_id = a.visible_ru_ru_id
      WHERE a.su_su_id = $1
        AND a.qu_qu_id = ANY($3::text[])
      ORDER BY a.qu_qu_id, a.sort_order, a.an_id
    `,
    [surveyId, lang, questionIdsArray],
  );

  const answerIdsArray = answerOptionsResult.rows.map((r) => r.an_id);
  const uniqueAnswerIds = Array.from(new Set(answerIdsArray));

  // 3. Load effects only for needed answers
  const effectsResult = uniqueAnswerIds.length > 0
    ? await db.query<EffectRow>(
        `
          SELECT e.an_an_id AS "answerId", e.body AS "body"
          FROM effects e
          WHERE e.an_an_id = ANY($1::text[])
            AND e.an_an_id IS NOT NULL
        `,
        [uniqueAnswerIds],
      )
    : { rows: [] };

  // 3a. Load effects only for needed questions
  const questionEffectsResult = questionIdsArray.length > 0
    ? await db.query<QuestionEffectRow>(
        `
          SELECT e.qu_qu_id AS "questionId", e.body AS "body"
          FROM effects e
          WHERE e.qu_qu_id = ANY($1::text[])
            AND e.qu_qu_id IS NOT NULL
        `,
        [questionIdsArray],
      )
    : { rows: [] };

  // 4. Load transitions only from last question (to determine next question)
  // and from all history questions (may be needed for question history)
  const transitionsFromQuestions = historyAnswers.length > 0
    ? [historyAnswers[historyAnswers.length - 1]!.questionId, ...questionIdsArray.filter(id => 
        historyAnswers.some(a => a.questionId === id)
      )]
    : questionIdsArray;
  const uniqueTransitionFromQuestions = Array.from(new Set(transitionsFromQuestions));
  
  const transitionsResult = await db.query<{
    from_qu_qu_id: string;
    toQuestionId: string;
    viaAnswerId: string | null;
    priority: number;
    rule: Record<string, unknown> | null;
  }>(
    `
      SELECT
        t.from_qu_qu_id,
        t.to_qu_qu_id AS "toQuestionId",
        t.via_an_an_id AS "viaAnswerId",
        t.priority,
        r.body AS "rule"
      FROM transitions t
      LEFT JOIN rules r ON r.ru_id = t.ru_ru_id
      WHERE t.from_qu_qu_id = ANY($1::text[])
      ORDER BY t.from_qu_qu_id, t.priority DESC, t.tr_id
    `,
    [uniqueTransitionFromQuestions],
  );

  // 5. Collect UUIDs for i18n texts

  const i18nUuids = new Set<string>();
  
  // Collect UUIDs from question metadata.path and metadata.columns
  for (const row of questionsResult.rows) {
    const metadata = row.metadata as { path?: unknown[]; columns?: unknown[] } | undefined;
    
    if (metadata?.path && Array.isArray(metadata.path)) {
      for (const segment of metadata.path) {
        if (typeof segment === 'string') {
          i18nUuids.add(segment);
        } else if (segment && typeof segment === 'object' && 'jsonlogic_expression' in segment) {
          extractStringsFromJsonLogic(segment.jsonlogic_expression, i18nUuids);
        }
      }
    }
    
    if (metadata?.columns && Array.isArray(metadata.columns)) {
      for (const col of metadata.columns) {
        if (typeof col === 'string') {
          i18nUuids.add(col);
        }
      }
    }
    
    // Collect i18n UUIDs from entire metadata (for shop, drop_down_detailed, etc.)
    if (row.metadata) {
      collectI18nUuids(row.metadata, i18nUuids);
    }
  }

  // Collect UUIDs from effects
  for (const row of effectsResult.rows) {
    collectI18nUuids(row.body, i18nUuids);
  }

  for (const row of questionEffectsResult.rows) {
    collectI18nUuids(row.body, i18nUuids);
  }

  for (const row of answerOptionsResult.rows) {
    if (row.metadata) {
      collectI18nUuids(row.metadata, i18nUuids);
    }
  }

  // Add UUIDs from question and answer body and label
  for (const row of questionsResult.rows) {
    if (row.body) {
      // body already loaded via JOIN, but UUID may be needed for other languages
      // Skip for now, as already loaded via JOIN
    }
  }

  // 6. Load i18n texts
  const i18nTextsMap = new Map<string, Map<string, string>>();
  if (i18nUuids.size > 0) {
    const i18nResult = await db.query<I18nRow>(
      `
        SELECT id::text AS "id", lang AS "lang", text AS "text"
        FROM i18n_text
        WHERE id::text = ANY($1::text[])
          AND lang IN ($2, 'en')
      `,
      [Array.from(i18nUuids), lang],
    );

    for (const row of i18nResult.rows) {
      if (!i18nTextsMap.has(row.id)) {
        i18nTextsMap.set(row.id, new Map());
      }
      i18nTextsMap.get(row.id)!.set(row.lang, row.text);
    }
  }

  // 7. Find entry question (if needed)
  let entryQuestionId: string | undefined;
  if (historyAnswers.length === 0) {
    const entryQuestionResult = await db.query<{ qu_id: string }>(
      `
        SELECT q.qu_id
        FROM questions q
        WHERE q.su_su_id = $1
          AND NOT EXISTS (
            SELECT 1 FROM transitions t WHERE t.to_qu_qu_id = q.qu_id
          )
        ORDER BY q.qu_id
        LIMIT 1
      `,
      [surveyId],
    );

    entryQuestionId = entryQuestionResult.rows[0]?.qu_id;
    if (!entryQuestionId) {
      throw new Error(`No entry question found for survey ${surveyId}`);
    }
  } else {
    // If there's history, entryQuestionId is not needed
    entryQuestionId = undefined;
  }

  // 8. Build data structures (same logic as before)
  const questions = new Map<string, QuestionRow>();
  for (const row of questionsResult.rows) {
    const question: QuestionRow = {
      id: row.qu_id,
      body: row.body,
      qtype: row.qtype,
      metadata: row.metadata,
    };
    
    if (question.qtype === 'single_table') {
      const metadata = question.metadata as { columns?: unknown[] } | undefined;
      const columnIds = extractColumnIds(metadata?.columns);
      if (columnIds.length) {
        const resolvedColumns = columnIds.map((columnId) => {
          const texts = i18nTextsMap.get(columnId);
          return texts?.get(lang) ?? texts?.get('en') ?? columnId;
        });
        question.metadata = {
          ...question.metadata,
          columns: resolvedColumns,
        };
      }
    }
    
    // Resolve i18n UUIDs in metadata for shop renderer
    if (question.metadata && typeof question.metadata === 'object') {
      const metadata = question.metadata as Record<string, unknown>;
      if (metadata.renderer === 'shop') {
        question.metadata = resolveI18nValue(question.metadata, i18nTextsMap, lang) as Record<string, unknown>;
      }
    }
    
    questions.set(row.qu_id, question);
  }

  const answerOptions = new Map<string, AnswerOptionRow[]>();
  const visibleRules = new Map<string, Record<string, unknown>>();
  const answerMetadata = new Map<string, Record<string, unknown>>();

  for (const row of answerOptionsResult.rows) {
    if (!answerOptions.has(row.qu_qu_id)) {
      answerOptions.set(row.qu_qu_id, []);
    }
    
      // Resolve i18n UUIDs in metadata for drop_down_detailed
      let resolvedMetadata = row.metadata ?? {};
      const question = questions.get(row.qu_qu_id);
      if (question?.qtype === 'drop_down_detailed' && resolvedMetadata) {
        resolvedMetadata = resolveI18nValue(resolvedMetadata, i18nTextsMap, lang) as Record<string, unknown>;
      }
    
    const option: AnswerOptionRow = {
      id: row.an_id,
      label: row.label,
      sortOrder: row.sort_order,
      metadata: resolvedMetadata,
    };
    
    answerOptions.get(row.qu_qu_id)!.push(option);
    
    if (row.visible_rule) {
      visibleRules.set(row.an_id, row.visible_rule);
    }
    
    answerMetadata.set(row.an_id, resolvedMetadata);
  }

  const effects = new Map<string, EffectRow[]>();
  for (const row of effectsResult.rows) {
    if (!effects.has(row.answerId)) {
      effects.set(row.answerId, []);
    }
    effects.get(row.answerId)!.push(row);
  }

  const questionEffects = new Map<string, QuestionEffectRow[]>();
  for (const row of questionEffectsResult.rows) {
    if (!questionEffects.has(row.questionId)) {
      questionEffects.set(row.questionId, []);
    }
    questionEffects.get(row.questionId)!.push(row);
  }

  const questionMetadata = new Map<string, Record<string, unknown>>();
  for (const row of questionsResult.rows) {
    questionMetadata.set(row.qu_id, row.metadata ?? {});
  }

  const transitions = new Map<string, TransitionRow[]>();
  for (const row of transitionsResult.rows) {
    if (!transitions.has(row.from_qu_qu_id)) {
      transitions.set(row.from_qu_qu_id, []);
    }
    transitions.get(row.from_qu_qu_id)!.push({
      toQuestionId: row.toQuestionId,
      viaAnswerId: row.viaAnswerId,
      priority: row.priority,
      rule: row.rule,
    });
  }

  return {
    i18nTexts: i18nTextsMap,
    questions,
    answerOptions,
    visibleRules,
    effects,
    questionEffects,
    answerMetadata,
    questionMetadata,
    transitions,
    entryQuestionId: entryQuestionId ?? '',
  };
}

/**
 * Загружает все необходимые данные для опроса один раз
 * @deprecated Используйте loadMinimalSurveyData для лучшей производительности
 */
async function loadSurveyData(surveyId: string, lang: string): Promise<SurveyData> {
  // 1. Load all questions
  const questionsResult = await db.query<{
    qu_id: string;
    body: string | null;
    qtype: string;
    metadata: Record<string, unknown>;
  }>(
    `
      SELECT
        q.qu_id,
        q.qtype,
        q.metadata,
        COALESCE(b_lang.text, b_en.text) AS "body"
      FROM questions q
      LEFT JOIN i18n_text b_lang ON b_lang.id = q.body AND b_lang.lang = $2
      LEFT JOIN i18n_text b_en ON b_en.id = q.body AND b_en.lang = 'en'
      WHERE q.su_su_id = $1
    `,
    [surveyId, lang],
  );

  const questionIds = questionsResult.rows.map((r) => r.qu_id);
  if (!questionIds.length) {
    throw new Error(`No questions found for survey ${surveyId}`);
  }

  // 2. Load all answer options with visibility rules
  const answerOptionsResult = await db.query<{
    an_id: string;
    qu_qu_id: string;
    label: string | null;
    sort_order: number;
    metadata: Record<string, unknown>;
    visible_rule: Record<string, unknown> | null;
  }>(
    `
      SELECT
        a.an_id,
        a.qu_qu_id,
        a.metadata,
        a.sort_order,
        COALESCE(l_lang.text, l_en.text) AS "label",
        r.body AS "visible_rule"
      FROM answer_options a
      LEFT JOIN i18n_text l_lang ON l_lang.id::text = a.label AND l_lang.lang = $2
      LEFT JOIN i18n_text l_en ON l_en.id::text = a.label AND l_en.lang = 'en'
      LEFT JOIN rules r ON r.ru_id = a.visible_ru_ru_id
      WHERE a.su_su_id = $1
      ORDER BY a.qu_qu_id, a.sort_order, a.an_id
    `,
    [surveyId, lang],
  );

  const answerIds = answerOptionsResult.rows.map((r) => r.an_id);

  // 3. Load all effects for answers
  const effectsResult = answerIds.length > 0
    ? await db.query<EffectRow>(
        `
          SELECT e.an_an_id AS "answerId", e.body AS "body"
          FROM effects e
          WHERE e.an_an_id = ANY($1::text[])
            AND e.an_an_id IS NOT NULL
        `,
        [answerIds],
      )
    : { rows: [] };

  // 3a. Load all effects for questions
  const questionEffectsResult = questionIds.length > 0
    ? await db.query<QuestionEffectRow>(
        `
          SELECT e.qu_qu_id AS "questionId", e.body AS "body"
          FROM effects e
          WHERE e.qu_qu_id = ANY($1::text[])
            AND e.qu_qu_id IS NOT NULL
        `,
        [questionIds],
      )
    : { rows: [] };

  // 4. Load all transitions
  const transitionsResult = await db.query<{
    from_qu_qu_id: string;
    toQuestionId: string;
    viaAnswerId: string | null;
    priority: number;
    rule: Record<string, unknown> | null;
  }>(
    `
      SELECT
        t.from_qu_qu_id,
        t.to_qu_qu_id AS "toQuestionId",
        t.via_an_an_id AS "viaAnswerId",
        t.priority,
        r.body AS "rule"
      FROM transitions t
      LEFT JOIN rules r ON r.ru_id = t.ru_ru_id
      WHERE t.from_qu_qu_id = ANY($1::text[])
      ORDER BY t.from_qu_qu_id, t.priority DESC, t.tr_id
    `,
    [questionIds],
  );

  // 5. Collect all UUIDs for i18n texts from metadata.path, metadata.columns and effects

  const i18nUuids = new Set<string>();
  
  // Collect UUIDs from question metadata.path and metadata.columns
  for (const row of questionsResult.rows) {
    const metadata = row.metadata as { path?: unknown[]; columns?: unknown[] } | undefined;
    
    // Collect UUIDs from path
    if (metadata?.path && Array.isArray(metadata.path)) {
      for (const segment of metadata.path) {
        if (typeof segment === 'string') {
          i18nUuids.add(segment);
        } else if (segment && typeof segment === 'object' && 'jsonlogic_expression' in segment) {
          // Extract all string values from jsonlogic_expression
          // that may be UUIDs (static values, not variables)
          extractStringsFromJsonLogic(segment.jsonlogic_expression, i18nUuids);
        }
      }
    }
    
    // Collect UUIDs from columns
    if (metadata?.columns && Array.isArray(metadata.columns)) {
      for (const col of metadata.columns) {
        if (typeof col === 'string') {
          i18nUuids.add(col);
        }
      }
    }
  }

  // Collect UUIDs from answer effects
  for (const row of effectsResult.rows) {
    collectI18nUuids(row.body, i18nUuids);
  }

  // Collect UUIDs from question effects
  for (const row of questionEffectsResult.rows) {
    collectI18nUuids(row.body, i18nUuids);
  }

  // Collect UUIDs from answer metadata (in case there are i18n_uuid there)
  for (const row of answerOptionsResult.rows) {
    if (row.metadata) {
      collectI18nUuids(row.metadata, i18nUuids);
    }
  }

  // 6. Load all i18n texts in one query
  const i18nTextsMap = new Map<string, Map<string, string>>();
  if (i18nUuids.size > 0) {
    const i18nResult = await db.query<I18nRow>(
      `
        SELECT id::text AS "id", lang AS "lang", text AS "text"
        FROM i18n_text
        WHERE id::text = ANY($1::text[])
          AND lang IN ($2, 'en')
      `,
      [Array.from(i18nUuids), lang],
    );

    for (const row of i18nResult.rows) {
      if (!i18nTextsMap.has(row.id)) {
        i18nTextsMap.set(row.id, new Map());
      }
      i18nTextsMap.get(row.id)!.set(row.lang, row.text);
    }
  }

  // 7. Find entry question
  const entryQuestionResult = await db.query<{ qu_id: string }>(
    `
      SELECT q.qu_id
      FROM questions q
      WHERE q.su_su_id = $1
        AND NOT EXISTS (
          SELECT 1 FROM transitions t WHERE t.to_qu_qu_id = q.qu_id
        )
      ORDER BY q.qu_id
      LIMIT 1
    `,
    [surveyId],
  );

  const entryQuestionId = entryQuestionResult.rows[0]?.qu_id;
  if (!entryQuestionId) {
    throw new Error(`No entry question found for survey ${surveyId}`);
  }

  // 8. Build data structures
  const questions = new Map<string, QuestionRow>();
  for (const row of questionsResult.rows) {
    const question: QuestionRow = {
      id: row.qu_id,
      body: row.body,
      qtype: row.qtype,
      metadata: row.metadata,
    };
    
    // Process single_table questions
    if (question.qtype === 'single_table') {
      const metadata = question.metadata as { columns?: unknown[] } | undefined;
      const columnIds = extractColumnIds(metadata?.columns);
      if (columnIds.length) {
        const resolvedColumns = columnIds.map((columnId) => {
          const texts = i18nTextsMap.get(columnId);
          return texts?.get(lang) ?? texts?.get('en') ?? columnId;
        });
        question.metadata = {
          ...question.metadata,
          columns: resolvedColumns,
        };
      }
    }
    
    questions.set(row.qu_id, question);
  }

  const answerOptions = new Map<string, AnswerOptionRow[]>();
  const visibleRules = new Map<string, Record<string, unknown>>();
  const answerMetadata = new Map<string, Record<string, unknown>>();

  for (const row of answerOptionsResult.rows) {
    if (!answerOptions.has(row.qu_qu_id)) {
      answerOptions.set(row.qu_qu_id, []);
    }
    
    const option: AnswerOptionRow = {
      id: row.an_id,
      label: row.label,
      sortOrder: row.sort_order,
      metadata: row.metadata ?? {},
    };
    
    answerOptions.get(row.qu_qu_id)!.push(option);
    
    if (row.visible_rule) {
      visibleRules.set(row.an_id, row.visible_rule);
    }
    
    answerMetadata.set(row.an_id, row.metadata ?? {});
  }

  const effects = new Map<string, EffectRow[]>();
  for (const row of effectsResult.rows) {
    if (!effects.has(row.answerId)) {
      effects.set(row.answerId, []);
    }
    effects.get(row.answerId)!.push(row);
  }

  const questionEffects = new Map<string, QuestionEffectRow[]>();
  for (const row of questionEffectsResult.rows) {
    if (!questionEffects.has(row.questionId)) {
      questionEffects.set(row.questionId, []);
    }
    questionEffects.get(row.questionId)!.push(row);
  }

  const questionMetadata = new Map<string, Record<string, unknown>>();
  for (const row of questionsResult.rows) {
    questionMetadata.set(row.qu_id, row.metadata ?? {});
  }

  const transitions = new Map<string, TransitionRow[]>();
  for (const row of transitionsResult.rows) {
    if (!transitions.has(row.from_qu_qu_id)) {
      transitions.set(row.from_qu_qu_id, []);
    }
    transitions.get(row.from_qu_qu_id)!.push({
      toQuestionId: row.toQuestionId,
      viaAnswerId: row.viaAnswerId,
      priority: row.priority,
      rule: row.rule,
    });
  }

  return {
    i18nTexts: i18nTextsMap,
    questions,
    answerOptions,
    visibleRules,
    effects,
    questionEffects,
    answerMetadata,
    questionMetadata,
    transitions,
    entryQuestionId,
  };
}

export async function getNextQuestion(payload: NextQuestionRequest): Promise<NextQuestionResponse> {
  const surveyId = payload.surveyId ?? DEFAULT_SURVEY_ID;
  const lang = payload.lang ?? DEFAULT_LANG;
  const historyAnswers = normaliseAnswers(payload.answers);

  // Step 1: Load only minimal data for state computation
  // (only metadata and effects, without body/label)
  const stateData = await loadStateData(surveyId, historyAnswers);

  // Step 2: Compute state using minimal data
  const { state } = deriveStateFromStateData(historyAnswers, lang, stateData);

  // Step 2a: Apply "smart" nodes requiring DB access (e.g., shop renderer)
  // This is done after basic deriveState to avoid complicating the synchronous pipeline.
  await applyDynamicNodes(historyAnswers, stateData.questionMetadata, state);
  
  // Step 3: Determine next question
  let nextQuestionId: string | null = null;
  
  if (historyAnswers.length === 0) {
    // If no history, use entry question
    nextQuestionId = stateData.entryQuestionId;
  } else {
    // Load transitions from last question to determine next
    const lastAnswer = historyAnswers[historyAnswers.length - 1]!;
    const transitionsResult = await db.query<{
      to_qu_qu_id: string;
      via_an_an_id: string | null;
      priority: number;
      rule: Record<string, unknown> | null;
    }>(
      `
        SELECT
          t.to_qu_qu_id,
          t.via_an_an_id,
          t.priority,
          r.body AS "rule"
        FROM transitions t
        LEFT JOIN rules r ON r.ru_id = t.ru_ru_id
        WHERE t.from_qu_qu_id = $1
        ORDER BY t.priority DESC, t.tr_id
      `,
      [lastAnswer.questionId],
    );
    
    const selected = new Set(lastAnswer.answerIds);
    for (const row of transitionsResult.rows) {
      if (row.via_an_an_id && !selected.has(row.via_an_an_id)) {
        continue;
      }
      if (row.rule && !jsonLogic.apply(row.rule, state)) {
        continue;
      }
      nextQuestionId = row.to_qu_qu_id;
      break;
    }
  }
  
  // Step 4: Load data for next question and history (if needed)
  let question: QuestionRow | undefined;
  let answerOptions: AnswerOptionRow[] = [];
  let surveyDataForHistory: SurveyData | null = null;
  
  if (nextQuestionId) {
    // Load next question
    const questionResult = await db.query<{
      qu_id: string;
      body: string | null;
      qtype: string;
      metadata: Record<string, unknown>;
    }>(
      `
        SELECT
          q.qu_id,
          q.qtype,
          q.metadata,
          COALESCE(b_lang.text, b_en.text) AS "body"
        FROM questions q
        LEFT JOIN i18n_text b_lang ON b_lang.id = q.body AND b_lang.lang = $2
        LEFT JOIN i18n_text b_en ON b_en.id = q.body AND b_en.lang = 'en'
        WHERE q.su_su_id = $1 AND q.qu_id = $3
      `,
      [surveyId, lang, nextQuestionId],
    );
    
    if (questionResult.rows.length > 0) {
      const row = questionResult.rows[0]!;
      question = {
        id: row.qu_id,
        body: row.body,
        qtype: row.qtype,
        metadata: row.metadata,
      };
      
      // Load answer options for this question
      const answerOptionsResult = await db.query<{
        an_id: string;
        qu_qu_id: string;
        label: string | null;
        sort_order: number;
        metadata: Record<string, unknown>;
        visible_rule: Record<string, unknown> | null;
      }>(
        `
          SELECT
            a.an_id,
            a.qu_qu_id,
            a.metadata,
            a.sort_order,
            COALESCE(l_lang.text, l_en.text) AS "label",
            r.body AS "visible_rule"
          FROM answer_options a
          LEFT JOIN i18n_text l_lang ON l_lang.id::text = a.label AND l_lang.lang = $2
          LEFT JOIN i18n_text l_en ON l_en.id::text = a.label AND l_en.lang = 'en'
          LEFT JOIN rules r ON r.ru_id = a.visible_ru_ru_id
          WHERE a.su_su_id = $1 AND a.qu_qu_id = $3
          ORDER BY a.sort_order, a.an_id
        `,
        [surveyId, lang, nextQuestionId],
      );
      
      // Collect UUIDs from answer option metadata for drop_down_detailed
      // and column headers for single_table, and shop metadata
      const metadataI18nUuids = new Set<string>();
      if (question.qtype === 'drop_down_detailed') {
        for (const row of answerOptionsResult.rows) {
          if (row.metadata) {
            collectI18nUuids(row.metadata, metadataI18nUuids);
          }
        }
      }
      if (question.qtype === 'single_table') {
        const qMeta = question.metadata as { columns?: unknown[] } | undefined;
        const columnIds = extractColumnIds(qMeta?.columns);
        for (const id of columnIds) {
          metadataI18nUuids.add(id);
        }
      }
      // Collect UUIDs from shop metadata
      if (question.metadata && typeof question.metadata === 'object') {
        const qMeta = question.metadata as Record<string, unknown>;
        if (qMeta.renderer === 'shop') {
          collectI18nUuids(question.metadata, metadataI18nUuids);
        }
      }
      
      // Load i18n texts for answer option metadata
      const metadataI18nTextsMap = new Map<string, Map<string, string>>();
      if (metadataI18nUuids.size > 0) {
        const metadataI18nResult = await db.query<I18nRow>(
          `
            SELECT id::text AS "id", lang AS "lang", text AS "text"
            FROM i18n_text
            WHERE id::text = ANY($1::text[])
              AND lang IN ($2, 'en')
          `,
          [Array.from(metadataI18nUuids), lang],
        );
        
        for (const i18nRow of metadataI18nResult.rows) {
          if (!metadataI18nTextsMap.has(i18nRow.id)) {
            metadataI18nTextsMap.set(i18nRow.id, new Map());
          }
          metadataI18nTextsMap.get(i18nRow.id)!.set(i18nRow.lang, i18nRow.text);
        }
      }

      // Resolve single_table column headers from the same batch
      if (question.qtype === 'single_table') {
        const qMeta = question.metadata as { columns?: unknown[] } | undefined;
        const columnIds = extractColumnIds(qMeta?.columns);
        if (columnIds.length > 0) {
          const resolvedColumns = columnIds.map((columnId) => {
            const texts = metadataI18nTextsMap.get(columnId);
            return texts?.get(lang) ?? texts?.get('en') ?? columnId;
          });
          question.metadata = {
            ...question.metadata,
            columns: resolvedColumns,
          };
        }
      }
      
      // Resolve i18n UUIDs in metadata for shop renderer
      if (question.metadata && typeof question.metadata === 'object') {
        const qMeta = question.metadata as Record<string, unknown>;
        if (qMeta.renderer === 'shop') {
          question.metadata = resolveI18nValue(question.metadata, metadataI18nTextsMap, lang) as Record<string, unknown>;
        }
      }
      
      const visibleRules = new Map<string, Record<string, unknown>>();
      for (const row of answerOptionsResult.rows) {
        // Resolve i18n UUIDs in metadata for drop_down_detailed
        let resolvedMetadata = row.metadata ?? {};
        if (question.qtype === 'drop_down_detailed' && resolvedMetadata) {
          resolvedMetadata = resolveI18nValue(resolvedMetadata, metadataI18nTextsMap, lang) as Record<string, unknown>;
        }
        
        const option: AnswerOptionRow = {
          id: row.an_id,
          label: row.label,
          sortOrder: row.sort_order,
          metadata: resolvedMetadata,
        };
        answerOptions.push(option);
        if (row.visible_rule) {
          visibleRules.set(row.an_id, row.visible_rule);
        }
      }
      
      // Filter answer options by visibility rules
      answerOptions = answerOptions.filter((option) => {
        const visibleRule = visibleRules.get(option.id);
        if (!visibleRule) {
          return true;
        }
        try {
          return Boolean(jsonLogic.apply(visibleRule, state));
        } catch (error) {
          console.error('[survey] option visibility', option.id, error);
          return false;
        }
      });
    }
  }
  
  // Load data for question history (only metadata for path)
  const historyQuestionIds = Array.from(new Set(historyAnswers.map(a => a.questionId)));
  let historyQuestions: HistoryQuestion[] = [];
  
  if (historyQuestionIds.length > 0) {
    // Load only question metadata for history
    const historyQuestionsResult = await db.query<{
      qu_id: string;
      metadata: Record<string, unknown>;
    }>(
      `
        SELECT q.qu_id, q.metadata
        FROM questions q
        WHERE q.su_su_id = $1 AND q.qu_id = ANY($2::text[])
      `,
      [surveyId, historyQuestionIds],
    );
    
    const historyQuestionsMap = new Map<string, Record<string, unknown>>();
    for (const row of historyQuestionsResult.rows) {
      historyQuestionsMap.set(row.qu_id, row.metadata ?? {});
    }
    
    // Collect UUIDs from path for i18n (including jsonlogic expressions)
    
    const pathI18nUuids = new Set<string>();
    for (const answer of historyAnswers) {
      const metadata = historyQuestionsMap.get(answer.questionId);
      if (metadata?.path && Array.isArray(metadata.path)) {
        for (const segment of metadata.path) {
          if (typeof segment === 'string') {
            pathI18nUuids.add(segment);
          } else if (segment && typeof segment === 'object' && 'jsonlogic_expression' in segment) {
            extractStringsFromJsonLogic(segment.jsonlogic_expression, pathI18nUuids);
          }
        }
      }
    }
    
    // Load i18n texts for path
    const i18nTextsMap = new Map<string, Map<string, string>>();
    if (pathI18nUuids.size > 0) {
      const i18nResult = await db.query<I18nRow>(
        `
          SELECT id::text AS "id", lang AS "lang", text AS "text"
          FROM i18n_text
          WHERE id::text = ANY($1::text[])
            AND lang IN ($2, 'en')
        `,
        [Array.from(pathI18nUuids), lang],
      );
      
      for (const row of i18nResult.rows) {
        if (!i18nTextsMap.has(row.id)) {
          i18nTextsMap.set(row.id, new Map());
        }
        i18nTextsMap.get(row.id)!.set(row.lang, row.text);
      }
    }
    
    // Build question history with proper jsonlogic expression handling
    // Compute state incrementally for each question
    let currentState: SurveyState = {
      ...JSON.parse(JSON.stringify(defaultCharacter)),
      lang,
      answers: {
        byQuestion: {},
        byAnswer: {},
        lastQuestion: null,
        lastAnswer: null,
      },
      values: {
        byQuestion: {},
      },
    } as SurveyState;
    getCounters(currentState);
    
    historyQuestions = [];
    for (let i = 0; i < historyAnswers.length; i++) {
      const answer = historyAnswers[i]!;
      const metadata = historyQuestionsMap.get(answer.questionId);
      const path = (metadata?.path as unknown[] | undefined) || [];
      
      // Use state BEFORE applying current answer to compute path
      const pathTexts = path.map((segment) => {
        if (typeof segment === 'string') {
          const texts = i18nTextsMap.get(segment);
          return texts?.get(lang) ?? texts?.get('en') ?? segment;
        } else if (segment && typeof segment === 'object') {
          if ('var' in segment) {
            const value = evaluate(segment, currentState);
            if (value !== undefined && value !== null) {
              const valueStr = String(value);
              const texts = i18nTextsMap.get(valueStr);
              return texts?.get(lang) ?? texts?.get('en') ?? valueStr;
            }
            return '';
          } else if ('jsonlogic_expression' in segment) {
            const value = evaluateJsonLogicExpression(segment.jsonlogic_expression, currentState);
            if (value !== undefined && value !== null) {
              const valueStr = String(value);
              const texts = i18nTextsMap.get(valueStr);
              return texts?.get(lang) ?? texts?.get('en') ?? valueStr;
            }
            return '';
          }
        }
        return String(segment);
      });
      
      const resolvedPath = path.map((segment) => {
        if (typeof segment === 'string') {
          return segment;
        } else if (segment && typeof segment === 'object') {
          if ('var' in segment) {
            const value = evaluate(segment, currentState);
            return value !== undefined && value !== null ? String(value) : '';
          } else if ('jsonlogic_expression' in segment) {
            const value = evaluateJsonLogicExpression(segment.jsonlogic_expression, currentState);
            return value !== undefined && value !== null ? String(value) : '';
          }
        }
        return String(segment);
      });
      
      historyQuestions.push({
        questionId: answer.questionId,
        path: resolvedPath,
        pathTexts,
      });
      
      // Apply current answer effects to state for next iteration
      const questionMeta = stateData.questionMetadata.get(answer.questionId);
      if (questionMeta) {
        applyQuestionCounters(questionMeta, currentState);
      }
      
      if (answer.value !== undefined) {
        applyValueTarget(answer.value, questionMeta, currentState);
      }
      
      const answersIndex = currentState.answers as {
        byQuestion: Record<string, string[]>;
        byAnswer: Record<string, boolean>;
        lastQuestion: { id: string; metadata?: Record<string, unknown> } | null;
        lastAnswer: { questionId: string; answerIds: string[]; value?: AnswerValue } | null;
      };
      const valuesIndex = currentState.values as { byQuestion: Record<string, AnswerValue | undefined> };
      
      const existing = answersIndex.byQuestion[answer.questionId] ?? [];
      const recordedValues = [...answer.answerIds];
      if (answer.value !== undefined) {
        recordedValues.push(String(answer.value.data));
        valuesIndex.byQuestion[answer.questionId] = answer.value;
      }
      answersIndex.byQuestion[answer.questionId] = [...existing, ...recordedValues];
      answersIndex.lastQuestion = questionMeta
        ? { id: answer.questionId, metadata: questionMeta }
        : { id: answer.questionId };
      const lastAnswer: { questionId: string; answerIds: string[]; value?: AnswerValue } = {
        questionId: answer.questionId,
        answerIds: [...answer.answerIds],
      };
      if (answer.value !== undefined) {
        lastAnswer.value = answer.value;
      }
      answersIndex.lastAnswer = lastAnswer;
      
      for (const answerId of answer.answerIds) {
        answersIndex.byAnswer[answerId] = true;
        const effects = stateData.effects.get(answerId) ?? [];
        for (const effect of effects) {
          applyEffect(effect.body, currentState);
        }
        const optionMeta = stateData.answerMetadata.get(answerId);
        if (optionMeta) {
          applyAnswerCounters(optionMeta, currentState);
        }
      }
      
      const questionEffects = stateData.questionEffects?.get(answer.questionId) ?? [];
      for (const effect of questionEffects) {
        applyEffect(effect.body, currentState);
      }
    }
  }

  if (!nextQuestionId || !question) {
    // Create debug_info for completed survey
    const debugInfo: NextQuestionResponse['debug_info'] = {};
    
    if ('lang' in state) {
      debugInfo.state_lang = state.lang as string;
    }
    if ('answers' in state) {
      debugInfo.state_answers = state.answers as SurveyState['answers'];
    }
    if ('values' in state) {
      debugInfo.state_values = state.values as SurveyState['values'];
    }
    if ('counters' in state) {
      debugInfo.state_counters = state.counters as SurveyState['counters'];
    }

    // Create cleaned state without debug fields
    const cleanedState = { ...state };
    delete cleanedState.lang;
    delete cleanedState.answers;
    delete cleanedState.values;
    delete cleanedState.counters;

    // Compute jsonlogic_expression in state before sending
    evaluateJsonLogicExpressions(cleanedState, state);
    
    // Resolve i18n_uuid and UUID strings in computed state
    await resolveI18nInState(cleanedState, lang, surveyId);

    return {
      done: true,
      state: cleanedState,
      historyAnswers,
      historyQuestions,
      debug_info: Object.keys(debugInfo).length > 0 ? debugInfo : undefined,
    };
  }

  // Add current question to historyQuestions with correct path from metadata
  const metadata = question.metadata as { path?: unknown[] } | undefined;
  const path = metadata?.path || [];
  
  // Collect UUIDs from current question path (including jsonlogic expressions)
  
  const pathI18nUuids = new Set<string>();
  for (const segment of path) {
    if (typeof segment === 'string') {
      pathI18nUuids.add(segment);
    } else if (segment && typeof segment === 'object' && 'jsonlogic_expression' in segment) {
      extractStringsFromJsonLogic(segment.jsonlogic_expression, pathI18nUuids);
    }
  }
  
  // Load i18n texts for current question path
  const currentQuestionI18nTexts = new Map<string, Map<string, string>>();
  if (pathI18nUuids.size > 0) {
    const i18nResult = await db.query<I18nRow>(
      `
        SELECT id::text AS "id", lang AS "lang", text AS "text"
        FROM i18n_text
        WHERE id::text = ANY($1::text[])
          AND lang IN ($2, 'en')
      `,
      [Array.from(pathI18nUuids), lang],
    );
    
    for (const row of i18nResult.rows) {
      if (!currentQuestionI18nTexts.has(row.id)) {
        currentQuestionI18nTexts.set(row.id, new Map());
      }
      currentQuestionI18nTexts.get(row.id)!.set(row.lang, row.text);
    }
  }
  
  // Build pathTexts with proper jsonlogic expression handling
  const pathTexts = path.map((segment) => resolvePathSegmentText(segment, state, currentQuestionI18nTexts, lang));
  const resolvedPath = path.map((segment) => evaluatePathSegment(segment, state));
  
  const currentQuestionHistory: HistoryQuestion = {
    questionId: question.id,
    path: resolvedPath,
    pathTexts,
  };
  const allHistoryQuestions = [...historyQuestions, currentQuestionHistory];

  // Create debug_info and move needed fields there
  const debugInfo: NextQuestionResponse['debug_info'] = {};
  
  // Move fields from state
  if ('lang' in state) {
    debugInfo.state_lang = state.lang as string;
  }
  if ('answers' in state) {
    debugInfo.state_answers = state.answers as SurveyState['answers'];
  }
  if ('values' in state) {
    debugInfo.state_values = state.values as SurveyState['values'];
  }
  if ('counters' in state) {
    debugInfo.state_counters = state.counters as SurveyState['counters'];
  }

  // IMPORTANT: do not remove metadata — it's needed by frontend for custom renderers (shop, etc.)
  // If you need to debug metadata — just put its copy in debug_info.
  const questionMetadata = { ...question.metadata } as Record<string, unknown>;
  if (Object.keys(questionMetadata).length > 0) {
    debugInfo.question_metadata = { ...questionMetadata };
  }

  // Create cleaned state without debug fields
  const cleanedState = { ...state };
  delete cleanedState.lang;
  delete cleanedState.answers;
  delete cleanedState.values;
  delete cleanedState.counters;

    // Compute jsonlogic_expression in state before sending
    evaluateJsonLogicExpressions(cleanedState, state);
    
    // Compute jsonlogic_expression in questionMetadata before sending
    // (needed for diceModifier and other fields that use jsonlogic)
    evaluateJsonLogicExpressions(questionMetadata, state);
    
    // Resolve i18n_uuid and UUID strings in computed state
    await resolveI18nInState(cleanedState, lang, surveyId);

  // Create cleaned question with filtered metadata
  const cleanedQuestion = {
    ...question,
    metadata: questionMetadata,
  };

  return {
    done: false,
    question: cleanedQuestion,
    answerOptions,
    state: cleanedState,
    historyAnswers,
    historyQuestions: allHistoryQuestions,
    debug_info: Object.keys(debugInfo).length > 0 ? debugInfo : undefined,
  };
}
function normaliseAnswers(entries?: AnswerInput[]): AnswerInput[] {
  if (!entries?.length) {
    return [];
  }

  return entries
    .map((entry) => {
      if (typeof entry.questionId !== "string" || entry.questionId.length === 0) {
        return null;
      }
      const questionId = entry.questionId;

      const answerIds = Array.isArray(entry.answerIds)
        ? entry.answerIds
            .map((id) => {
              if (typeof id === "string") {
                return id;
              }
              if (id === undefined || id === null) {
                return "";
              }
              return String(id);
            })
            .filter((id) => id.length > 0)
        : [];

      const value = normaliseAnswerValue(entry.value);

      const normalised: AnswerInput = { questionId, answerIds };
      if (value !== undefined) {
        normalised.value = value;
      }

      return normalised;
    })
    .filter((entry): entry is AnswerInput => entry !== null);
}

function normaliseAnswerValue(candidate: unknown): AnswerValue | undefined {
  if (!candidate || typeof candidate !== "object") {
    return undefined;
  }

  const { type, data } = candidate as { type?: string; data?: unknown };

  if (type === "number") {
    const numeric = typeof data === "number" ? data : Number(data);
    if (Number.isFinite(numeric)) {
      return { type: "number", data: numeric };
    }
    return undefined;
  }

  if (type === "string") {
    if (typeof data === "string") {
      return { type: "string", data };
    }
    if (data !== undefined && data !== null) {
      return { type: "string", data: String(data) };
    }
  }

  return undefined;
}

// fetchQuestion is no longer needed, use surveyData.questions directly

function extractColumnIds(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value.filter((entry): entry is string => typeof entry === 'string');
}

/**
 * Получает варианты ответов из предзагруженных данных с фильтрацией по правилам видимости
 */
function fetchAnswerOptions(
  questionId: string,
  state: SurveyState,
  surveyData: SurveyData,
): AnswerOptionRow[] {
  const options = surveyData.answerOptions.get(questionId) ?? [];

  const filtered = options.filter((option) => {
    const visibleRule = surveyData.visibleRules.get(option.id);
    if (!visibleRule) {
      return true;
    }
    try {
      return Boolean(jsonLogic.apply(visibleRule, state));
    } catch (error) {
      console.error('[survey] option visibility', option.id, error);
      return false;
    }
  });

  return filtered;
}/**
 * Определяет следующий вопрос используя предзагруженные данные
 */
function resolveNextQuestionId(
  answers: AnswerInput[],
  state: SurveyState,
  surveyData: SurveyData,
): string | null {
  if (!answers.length) {
    return surveyData.entryQuestionId;
  }

  const last = answers[answers.length - 1];
  if (!last) {
    return surveyData.entryQuestionId;
  }

  const transitions = surveyData.transitions.get(last.questionId) ?? [];
  const selected = new Set(last.answerIds);

  for (const transition of transitions) {
    if (transition.viaAnswerId && !selected.has(transition.viaAnswerId)) {
      continue;
    }
    if (transition.rule && !jsonLogic.apply(transition.rule, state)) {
      continue;
    }
    return transition.toQuestionId;
  }

  return null;
}

/**
 * Вычисляет состояние, применяя ответы по одному с использованием минимальных данных
 * (только метаданные и эффекты, без body/label)
 */
function deriveStateFromStateData(
  answers: AnswerInput[],
  lang: string,
  stateData: {
    questionMetadata: Map<string, Record<string, unknown>>;
    answerMetadata: Map<string, Record<string, unknown>>;
    effects: Map<string, EffectRow[]>;
    questionEffects: Map<string, QuestionEffectRow[]>;
    entryQuestionId: string;
  },
): { state: SurveyState } {
  const state: SurveyState = {
    ...JSON.parse(JSON.stringify(defaultCharacter)),
    lang,
    answers: {
      byQuestion: {} as Record<string, string[]>,
      byAnswer: {} as Record<string, boolean>,
      lastQuestion: null as { id: string; metadata?: Record<string, unknown> } | null,
      lastAnswer: null as { questionId: string; answerIds: string[]; value?: AnswerValue } | null,
    },
    values: {
      byQuestion: {} as Record<string, AnswerValue | undefined>,
    },
  } as SurveyState;

  const answersIndex = state.answers as {
    byQuestion: Record<string, string[]>;
    byAnswer: Record<string, boolean>;
    lastQuestion: { id: string; metadata?: Record<string, unknown> } | null;
    lastAnswer: { questionId: string; answerIds: string[]; value?: AnswerValue } | null;
  };
  const valuesIndex = state.values as { byQuestion: Record<string, AnswerValue | undefined> };
  getCounters(state);

  // Apply answers one by one, computing state at each step
  for (const entry of answers) {
    // 1. Update answer indices
    const existing = answersIndex.byQuestion[entry.questionId] ?? [];
    const recordedValues = [...entry.answerIds];
    if (entry.value !== undefined) {
      recordedValues.push(String(entry.value.data));
      valuesIndex.byQuestion[entry.questionId] = entry.value;
    }
    answersIndex.byQuestion[entry.questionId] = [...existing, ...recordedValues];
    
    // 2. Get question metadata from preloaded data
    const questionMeta = stateData.questionMetadata.get(entry.questionId);
    answersIndex.lastQuestion = questionMeta
      ? { id: entry.questionId, metadata: questionMeta }
      : { id: entry.questionId };
    
    // 3. Update lastAnswer (before applying counters)
    const lastAnswer: { questionId: string; answerIds: string[]; value?: AnswerValue } = {
      questionId: entry.questionId,
      answerIds: [...entry.answerIds],
    };
    if (entry.value !== undefined) {
      lastAnswer.value = entry.value;
    }
    answersIndex.lastAnswer = lastAnswer;

    // 5. Apply value target (using current state)
    if (entry.value !== undefined) {
      applyValueTarget(entry.value, questionMeta, state);
    }
    
    // 6. Apply answer effects (using current state)
    // IMPORTANT: effects are applied BEFORE counter increment to use current counter value
    for (const answerId of entry.answerIds) {
      answersIndex.byAnswer[answerId] = true;
      
      // Get effects from preloaded data and apply them FIRST
      // This allows using current counter value (e.g., 0 for first event)
      const effects = stateData.effects.get(answerId) ?? [];
      for (const effect of effects) {
        applyEffect(effect.body, state);
      }

      // Get answer metadata from preloaded data and apply counters AFTER effects
      // This increments counter for next application (e.g., 0 -> 1 after first event)
      const optionMeta = stateData.answerMetadata.get(answerId);
      if (optionMeta) {
        applyAnswerCounters(optionMeta, state);
      }
    }

    // 5a. Apply question effects (after valueTarget, so value is already written)
    const questionEffects = stateData.questionEffects?.get(entry.questionId) ?? [];
    for (const effect of questionEffects) {
      applyEffect(effect.body, state);
    }

    // 4. Apply question counters (using current state)
    if (questionMeta) {
      applyQuestionCounters(questionMeta, state);
    }
    
    // 7. Clean up values if needed
    if (entry.value === undefined && valuesIndex.byQuestion[entry.questionId] === undefined) {
      delete valuesIndex.byQuestion[entry.questionId];
    }
  }

  return { state };
}

type ShopSourceConfig = {
  id: string;
  table: string;
  dlcColumn: string;
  keyColumn: string;
  langColumn?: string;
  targetPath: string;
  filters?: Record<string, unknown>;
};

type ShopBudgetCoverageMoney = {
  sources?: string[];
  items?: string[];
};

type ShopBudgetCoverageTokensItem = {
  cost?: number;
  ids: string[];
};

type ShopBudgetCoverageTokens = {
  sources?: ShopBudgetCoverageTokensItem[];
  items?: ShopBudgetCoverageTokensItem[];
};

type ShopBudgetConfig = {
  id: string;
  type: 'money' | 'tokens';
  source: string;
  coverage?: ShopBudgetCoverageMoney | ShopBudgetCoverageTokens;
  priority: number;
  is_default?: boolean;
  is_with_default?: boolean; // only for money
  is_with_money?: boolean; // only for tokens
  name?: unknown; // i18n resolved
};

type ShopQuestionConfig = {
  budget?: { currency?: unknown; path?: unknown }; // legacy
  budgets?: ShopBudgetConfig[];
  allowedDlcs?: unknown;
  sources?: unknown;
};

function normaliseShopSources(value: unknown): ShopSourceConfig[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => (item && typeof item === 'object' && !Array.isArray(item) ? (item as Record<string, unknown>) : null))
    .filter((item): item is Record<string, unknown> => !!item)
    .filter((item) => typeof item.id === 'string')
    .map((item) => ({
      id: String(item.id),
      table: String(item.table ?? ''),
      dlcColumn: String(item.dlcColumn ?? 'dlc'),
      keyColumn: String(item.keyColumn ?? 'id'),
      langColumn: typeof item.langColumn === 'string' ? String(item.langColumn) : undefined,
      targetPath: String(item.targetPath ?? 'characterRaw.gear'),
      filters: item.filters && typeof item.filters === 'object' && !Array.isArray(item.filters) ? (item.filters as Record<string, unknown>) : undefined,
    }))
    .filter((item) => item.table.length > 0 && item.keyColumn.length > 0 && item.dlcColumn.length > 0);
}

function addToArrayAtPath(state: SurveyState, path: string, value: unknown) {
  const existing = getAtPath(state, path);
  if (Array.isArray(existing)) {
    existing.push(value);
    return;
  }
  if (existing === undefined) {
    setAtPath(state, path, [value]);
    return;
  }
  setAtPath(state, path, [existing, value]);
}

function normaliseShopBudgets(value: unknown): ShopBudgetConfig[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((item) => (item && typeof item === 'object' && !Array.isArray(item) ? (item as Record<string, unknown>) : null))
    .filter((item): item is Record<string, unknown> => !!item)
    .filter((item) => typeof item.id === 'string' && typeof item.source === 'string')
    .map((item) => ({
      id: String(item.id),
      type: (item.type === 'tokens' ? 'tokens' : 'money') as 'money' | 'tokens',
      source: String(item.source),
      coverage: item.coverage && typeof item.coverage === 'object' && !Array.isArray(item.coverage) ? (item.coverage as ShopBudgetCoverageMoney | ShopBudgetCoverageTokens) : undefined,
      priority: toFiniteNumber(item.priority, 999),
      is_default: Boolean(item.is_default),
      is_with_default: item.is_with_default === true,
      is_with_money: item.is_with_money === true,
      name: item.name,
    }));
}

function isItemCoveredByBudget(budget: ShopBudgetConfig, sourceId: string, itemId: string): boolean {
  if (!budget.coverage) return true; // No coverage = covers everything
  
  if (budget.type === 'money') {
    const coverage = budget.coverage as ShopBudgetCoverageMoney;
    // Check sources
    if (coverage.sources && Array.isArray(coverage.sources)) {
      if (coverage.sources.includes(sourceId)) return true;
    }
    // Check items
    if (coverage.items && Array.isArray(coverage.items)) {
      if (coverage.items.includes(itemId)) return true;
    }
    // If coverage exists but item not found, not covered
    if (coverage.sources || coverage.items) return false;
    return true; // Empty coverage = covers everything
  } else {
    // tokens
    const coverage = budget.coverage as ShopBudgetCoverageTokens;
    // Check sources
    if (coverage.sources && Array.isArray(coverage.sources)) {
      for (const sourceItem of coverage.sources) {
        if (sourceItem.ids && sourceItem.ids.includes(sourceId)) return true;
      }
    }
    // Check items
    if (coverage.items && Array.isArray(coverage.items)) {
      for (const item of coverage.items) {
        if (item.ids && item.ids.includes(itemId)) return true;
      }
    }
    // If coverage exists but item not found, not covered
    if (coverage.sources || coverage.items) return false;
    return true; // Empty coverage = covers everything
  }
}

function getTokenCostForItem(budget: ShopBudgetConfig, sourceId: string, itemId: string): number {
  if (budget.type !== 'tokens' || !budget.coverage) return 1;
  const coverage = budget.coverage as ShopBudgetCoverageTokens;
  
  // Check items first
  if (coverage.items && Array.isArray(coverage.items)) {
    for (const item of coverage.items) {
      if (item.ids && item.ids.includes(itemId)) {
        return item.cost ?? 1;
      }
    }
  }
  // Check sources
  if (coverage.sources && Array.isArray(coverage.sources)) {
    for (const sourceItem of coverage.sources) {
      if (sourceItem.ids && sourceItem.ids.includes(sourceId)) {
        return sourceItem.cost ?? 1;
      }
    }
  }
  return 1; // default cost
}

async function applyShopNode(
  rawValue: string,
  questionMeta: Record<string, unknown>,
  state: SurveyState,
) {
  const shop = questionMeta.shop as ShopQuestionConfig | undefined;
  const sources = normaliseShopSources(shop?.sources);
  if (sources.length === 0) {
    return;
  }

  // Get budgets - support both old and new format
  let budgets: ShopBudgetConfig[] = [];
  if (shop?.budgets && Array.isArray(shop.budgets)) {
    budgets = normaliseShopBudgets(shop.budgets);
  } else if (shop?.budget) {
    // Legacy format: single budget
    const budgetPath = typeof shop.budget.path === 'string' ? shop.budget.path : 'characterRaw.money.crowns';
    const budgetCurrency = typeof shop.budget.currency === 'string' ? shop.budget.currency : 'crowns';
    if (budgetCurrency === 'crowns') {
      budgets = [{
        id: 'crowns',
        type: 'money',
        source: budgetPath,
        priority: 0,
        is_default: true,
      }];
    }
  }
  
  if (budgets.length === 0) {
    return; // No budgets configured
  }

  const dlcs = (() => {
    const allowedDlcs = toStringArray(shop?.allowedDlcs);
    return allowedDlcs.length > 0 ? allowedDlcs : ['core'];
  })();

  const parsed = parseShopAnswerValue(rawValue);
  const purchases = Array.isArray(parsed?.purchases) ? parsed!.purchases! : [];
  if (purchases.length === 0) {
    return;
  }

  // Validate + normalise purchases
  const validPurchases: ShopPurchase[] = purchases
    .filter((p) => p && typeof p === 'object')
    .map((p) => p as ShopPurchase)
    .filter((p) => typeof p.sourceId === 'string' && typeof p.id === 'string')
    .map((p) => ({
      sourceId: p.sourceId,
      id: p.id,
      qty: Math.max(0, Math.floor(toFiniteNumber((p as any).qty, 0))),
    }))
    .filter((p) => p.qty > 0);

  if (validPurchases.length === 0) {
    return;
  }

  // Group by sourceId
  const bySource = new Map<string, ShopPurchase[]>();
  for (const p of validPurchases) {
    const list = bySource.get(p.sourceId) ?? [];
    list.push(p);
    bySource.set(p.sourceId, list);
  }

  // Initialize budget states
  const budgetStates = new Map<string, number>();
  for (const budget of budgets) {
    const value = toFiniteNumber(getAtPath(state, budget.source), 0);
    budgetStates.set(budget.id, value);
  }

  // First pass: compute cost and validate items exist
  const lookedUp = new Map<string, Array<{ purchase: ShopPurchase; row: Record<string, unknown>; targetPath: string }>>();

  for (const [sourceId, sourcePurchases] of bySource.entries()) {
    const source = sources.find((s) => s.id === sourceId);
    if (!source) {
      throw new Error(`Unknown shop source: ${sourceId}`);
    }

    const { table, keyColumn, dlcColumn, langColumn } = source;
    if (!SHOP_ALLOWED_TABLES.has(table)) {
      throw new Error(`Shop table not allowed: ${table}`);
    }
    if (!isSafeIdentifier(keyColumn) || !isSafeIdentifier(dlcColumn)) {
      throw new Error('Unsafe shop column identifier');
    }
    if (langColumn && !isSafeIdentifier(langColumn)) {
      throw new Error('Unsafe shop lang column identifier');
    }

    const ids = Array.from(new Set(sourcePurchases.map((p) => p.id)));
    const filterType = source.filters?.type;

    const whereParts: string[] = [
      `"${keyColumn}" = ANY($1::text[])`,
      `"${dlcColumn}" = ANY($2::text[])`,
    ];
    const params: unknown[] = [ids, dlcs];
    let paramIndex = 3;

    // If the source is language-specific, keep the row language consistent with state.lang
    if (langColumn && typeof (state as any).lang === 'string' && (state as any).lang.length > 0) {
      whereParts.push(`"${langColumn}" = $${paramIndex}`);
      params.push(String((state as any).lang));
      paramIndex++;
    }

    if (typeof filterType === 'string' && filterType.length > 0) {
      whereParts.push(`"type" = $${paramIndex}`);
      params.push(filterType);
      paramIndex++;
    }

    const { rows } = await db.query<Record<string, unknown>>(
      `
        SELECT *
        FROM "${table}"
        WHERE ${whereParts.join(' AND ')}
      `,
      params,
    );

    const byId = new Map<string, Record<string, unknown>>();
    for (const row of rows) {
      const rowId = row[keyColumn];
      if (typeof rowId === 'string') {
        byId.set(rowId, row);
      }
    }

    for (const purchase of sourcePurchases) {
      const row = byId.get(purchase.id);
      if (!row) {
        throw new Error(`Shop item not found or not allowed by filters: ${sourceId}:${purchase.id}`);
      }
      const list = lookedUp.get(sourceId) ?? [];
      list.push({ purchase, row, targetPath: source.targetPath });
      lookedUp.set(sourceId, list);
    }
  }

  // Second pass: calculate budget spending
  for (const [sourceId, entries] of lookedUp.entries()) {
    for (const entry of entries) {
      const price = toFiniteNumber(entry.row.price, 0);
      const qty = entry.purchase.qty;
      
      // Find applicable budgets for this item, sorted by priority
      const applicableBudgets = budgets
        .filter(b => isItemCoveredByBudget(b, sourceId, entry.purchase.id))
        .sort((a, b) => a.priority - b.priority);
      
      if (applicableBudgets.length === 0) continue;
      
      let remainingCost = price * qty;
      let remainingQty = qty;
      
      for (const budget of applicableBudgets) {
        if (budget.type === 'money') {
          if (remainingCost <= 0) break;
          const budgetRemaining = budgetStates.get(budget.id) ?? 0;
          const toSpend = Math.min(remainingCost, budgetRemaining);
          if (toSpend > 0) {
            budgetStates.set(budget.id, budgetRemaining - toSpend);
            remainingCost -= toSpend;
          }
          
          // If is_with_default and not default budget, also spend from default
          if (budget.is_with_default && !budget.is_default) {
            const defaultBudget = budgets.find(b => b.is_default);
            if (defaultBudget && remainingCost > 0) {
              const defaultRemaining = budgetStates.get(defaultBudget.id) ?? 0;
              const toSpendDefault = Math.min(remainingCost, defaultRemaining);
              if (toSpendDefault > 0) {
                budgetStates.set(defaultBudget.id, defaultRemaining - toSpendDefault);
                remainingCost -= toSpendDefault;
              }
            }
          }
        } else {
          // tokens
          if (remainingQty <= 0) break;
          const costPerUnit = getTokenCostForItem(budget, sourceId, entry.purchase.id);
          const tokensNeeded = costPerUnit * remainingQty;
          const budgetRemaining = budgetStates.get(budget.id) ?? 0;
          const toSpend = Math.min(tokensNeeded, budgetRemaining);
          if (toSpend > 0) {
            budgetStates.set(budget.id, budgetRemaining - toSpend);
            remainingQty -= Math.floor(toSpend / costPerUnit);
          }
          
          // If is_with_money, also spend money
          if (budget.is_with_money && remainingCost > 0) {
            const moneyBudgets = budgets
              .filter(b => b.type === 'money' && isItemCoveredByBudget(b, sourceId, entry.purchase.id))
              .sort((a, b) => a.priority - b.priority);
            for (const moneyBudget of moneyBudgets) {
              if (remainingCost <= 0) break;
              const moneyRemaining = budgetStates.get(moneyBudget.id) ?? 0;
              const toSpendMoney = Math.min(remainingCost, moneyRemaining);
              if (toSpendMoney > 0) {
                budgetStates.set(moneyBudget.id, moneyRemaining - toSpendMoney);
                remainingCost -= toSpendMoney;
              }
            }
          }
        }
      }
    }
  }

  // Check for exceeded budgets (but allow if user ignored warnings - save as 0)
  const ignoreWarnings = parsed?.ignoreWarnings === true;
  for (const [budgetId, remaining] of budgetStates.entries()) {
    const budget = budgets.find(b => b.id === budgetId);
    if (!budget) continue;
    
    if (remaining < 0 && !ignoreWarnings) {
      throw new Error(`Budget ${budget.id} exceeded. Remaining: ${remaining}`);
    }
    
    // Save budget (0 if negative and warnings ignored)
    const finalValue = remaining < 0 ? 0 : remaining;
    setAtPath(state, budget.source, finalValue);
  }

  // Remove non-default budgets after purchase
  for (const budget of budgets) {
    if (!budget.is_default) {
      // Remove the budget from state by setting to undefined
      // setAtPath will handle the deletion properly
      const pathParts = budget.source.split('.');
      if (pathParts.length > 0) {
        let cursor: any = state;
        for (let i = 0; i < pathParts.length - 1; i++) {
          if (cursor == null || typeof cursor !== 'object') break;
          cursor = cursor[pathParts[i]];
        }
        if (cursor != null && typeof cursor === 'object') {
          const lastKey = pathParts[pathParts.length - 1];
          delete cursor[lastKey];
        }
      }
    }
  }

  // Third pass: add items to targets
  for (const [sourceId, entries] of lookedUp.entries()) {
    for (const entry of entries) {
      const item = {
        ...entry.row,
        amount: entry.purchase.qty,
        sourceId,
      };
      addToArrayAtPath(state, entry.targetPath, item);
    }
  }
}

async function applyDynamicNodes(
  answers: AnswerInput[],
  questionMetadata: Map<string, Record<string, unknown>>,
  state: SurveyState,
) {
  for (const entry of answers) {
    if (entry.value?.type !== 'string') continue;
    const qMeta = questionMetadata.get(entry.questionId);
    if (!qMeta) continue;
    const renderer = (qMeta as Record<string, unknown>).renderer;
    if (renderer === 'shop') {
      await applyShopNode(String(entry.value.data), qMeta, state);
    }
  }
}

/**
 * Вычисляет состояние, применяя ответы по одному с использованием предзагруженных данных
 * @deprecated Используйте deriveStateFromStateData для лучшей производительности
 */
function deriveState(
  answers: AnswerInput[],
  lang: string,
  surveyData: SurveyData,
): { state: SurveyState } {
  const state: SurveyState = {
    ...JSON.parse(JSON.stringify(defaultCharacter)),
    lang,
    answers: {
      byQuestion: {} as Record<string, string[]>,
      byAnswer: {} as Record<string, boolean>,
      lastQuestion: null as { id: string; metadata?: Record<string, unknown> } | null,
      lastAnswer: null as { questionId: string; answerIds: string[]; value?: AnswerValue } | null,
    },
    values: {
      byQuestion: {} as Record<string, AnswerValue | undefined>,
    },
  } as SurveyState;

  const answersIndex = state.answers as {
    byQuestion: Record<string, string[]>;
    byAnswer: Record<string, boolean>;
    lastQuestion: { id: string; metadata?: Record<string, unknown> } | null;
    lastAnswer: { questionId: string; answerIds: string[]; value?: AnswerValue } | null;
  };
  const valuesIndex = state.values as { byQuestion: Record<string, AnswerValue | undefined> };
  getCounters(state);

  // Apply answers one by one, computing state at each step
  for (const entry of answers) {
    // 1. Update answer indices
    const existing = answersIndex.byQuestion[entry.questionId] ?? [];
    const recordedValues = [...entry.answerIds];
    if (entry.value !== undefined) {
      recordedValues.push(String(entry.value.data));
      valuesIndex.byQuestion[entry.questionId] = entry.value;
    }
    answersIndex.byQuestion[entry.questionId] = [...existing, ...recordedValues];
    
    // 2. Get question metadata from preloaded data
    const questionMeta = surveyData.questionMetadata.get(entry.questionId);
    answersIndex.lastQuestion = questionMeta
      ? { id: entry.questionId, metadata: questionMeta }
      : { id: entry.questionId };
    
    // 3. Update lastAnswer (before applying counters)
    const lastAnswer: { questionId: string; answerIds: string[]; value?: AnswerValue } = {
      questionId: entry.questionId,
      answerIds: [...entry.answerIds],
    };
    if (entry.value !== undefined) {
      lastAnswer.value = entry.value;
    }
    answersIndex.lastAnswer = lastAnswer;

    // 5. Apply value target (using current state)
    if (entry.value !== undefined) {
      applyValueTarget(entry.value, questionMeta, state);
    }
    
    // 6. Apply answer effects (using current state)
    // IMPORTANT: effects are applied BEFORE counter increment to use current counter value
    for (const answerId of entry.answerIds) {
      answersIndex.byAnswer[answerId] = true;
      
      // Get effects from preloaded data and apply them FIRST
      // This allows using current counter value (e.g., 0 for first event)
      const effects = surveyData.effects.get(answerId) ?? [];
      for (const effect of effects) {
        applyEffect(effect.body, state);
      }

      // Get answer metadata from preloaded data and apply counters AFTER effects
      // This increments counter for next application (e.g., 0 -> 1 after first event)
      const optionMeta = surveyData.answerMetadata.get(answerId);
      if (optionMeta) {
        applyAnswerCounters(optionMeta, state);
      }
    }

    // 5a. Apply question effects (after valueTarget, so value is already written)
    const questionEffects = surveyData.questionEffects?.get(entry.questionId) ?? [];
    for (const effect of questionEffects) {
      applyEffect(effect.body, state);
    }

    // 4. Apply question counters (using current state)
    if (questionMeta) {
      applyQuestionCounters(questionMeta, state);
    }
    
    // 7. Clean up values if needed
    if (entry.value === undefined && valuesIndex.byQuestion[entry.questionId] === undefined) {
      delete valuesIndex.byQuestion[entry.questionId];
    }
  }

  return { state };
}

function getCounters(state: SurveyState): Record<string, number> {
  const existing = (state as Record<string, unknown>).counters;
  if (existing && typeof existing === 'object' && !Array.isArray(existing)) {
    return existing as Record<string, number>;
  }

  const container: Record<string, number> = {};
  (state as Record<string, unknown>).counters = container;
  return container;
}

function applyQuestionCounters(
  metadata: Record<string, unknown>,
  state: SurveyState,
) {
  if (!metadata || typeof metadata !== 'object') {
    return;
  }

  const counters = getCounters(state);

  const setsValue = readMetadataValue(metadata, ['counterSet', 'counter', 'counterSets', 'counters']);
  const setConfigs = normaliseCounterSetConfigs(setsValue);
  for (const config of setConfigs) {
    try {
      const value = evaluateNumberExpression(config.value, state, 0);
      counters[config.id] = value;
    } catch (error) {
      console.error('[survey] counter set failed', config.id, error);
    }
  }

  let incrementsValue = readMetadataValue(metadata, ['counterIncrement', 'counterIncrements']);
  // Process jsonlogic_expression in counterIncrement
  if (incrementsValue && typeof incrementsValue === 'object' && !Array.isArray(incrementsValue)) {
    const incValueRecord = incrementsValue as Record<string, unknown>;
    if ('jsonlogic_expression' in incValueRecord) {
      try {
        incrementsValue = evaluateJsonLogicExpression(incValueRecord.jsonlogic_expression, state);
      } catch (error) {
        console.error('[survey] counterIncrement jsonlogic_expression evaluation failed', error);
        incrementsValue = undefined;
      }
    }
  }
  const incConfigs = normaliseCounterIncrementConfigs(incrementsValue);
  for (const config of incConfigs) {
    try {
      const delta = evaluateNumberExpression(config.step ?? 1, state, 1);
      counters[config.id] = (counters[config.id] ?? 0) + delta;
    } catch (error) {
      console.error('[survey] counter increment failed', config.id, error);
    }
  }
}

function applyAnswerCounters(
  metadata: Record<string, unknown>,
  state: SurveyState,
) {
  if (!metadata || typeof metadata !== 'object') {
    return;
  }

  const counters = getCounters(state);

  const setsValue = readMetadataValue(metadata, ['counterSet', 'counter', 'counterSets', 'counters']);
  const setConfigs = normaliseCounterSetConfigs(setsValue);
  for (const config of setConfigs) {
    try {
      const value = evaluateNumberExpression(config.value, state, 0);
      counters[config.id] = value;
    } catch (error) {
      console.error('[survey] counter set failed', config.id, error);
    }
  }

  let incValue = readMetadataValue(metadata, ['counterIncrement', 'counterIncrements']);
  // Process jsonlogic_expression in counterIncrement
  if (incValue && typeof incValue === 'object' && !Array.isArray(incValue)) {
    const incValueRecord = incValue as Record<string, unknown>;
    if ('jsonlogic_expression' in incValueRecord) {
      try {
        incValue = evaluateJsonLogicExpression(incValueRecord.jsonlogic_expression, state);
      } catch (error) {
        console.error('[survey] counterIncrement jsonlogic_expression evaluation failed', error);
        incValue = undefined;
      }
    }
  }
  const incConfigs = normaliseCounterIncrementConfigs(incValue);
  for (const config of incConfigs) {
    try {
      const delta = evaluateNumberExpression(config.step ?? 1, state, 1);
      counters[config.id] = (counters[config.id] ?? 0) + delta;
    } catch (error) {
      console.error('[survey] counter increment failed', config.id, error);
    }
  }
}

function applyValueTarget(
  value: AnswerValue,
  metadata: Record<string, unknown> | undefined,
  state: SurveyState,
) {
  if (!metadata || typeof metadata !== 'object') {
    return;
  }

  const target = readMetadataValue(metadata, ['valueTarget', 'value_target']);
  if (typeof target !== 'string' || target.length === 0) {
    return;
  }

  const storedValue = value.type === 'number' ? value.data : value.data;
  setAtPath(state, target, storedValue);
}

function readMetadataValue(metadata: Record<string, unknown>, keys: string[]): unknown {
  for (const key of keys) {
    if (Object.prototype.hasOwnProperty.call(metadata, key)) {
      return (metadata as Record<string, unknown>)[key];
    }
  }
  return undefined;
}

function normaliseCounterSetConfigs(value: unknown): CounterSetConfig[] {
  return ensureArray(value)
    .map((item) => (typeof item === 'object' && item !== null ? (item as Record<string, unknown>) : null))
    .filter((item): item is Record<string, unknown> => !!item && typeof item.id === 'string' && Object.prototype.hasOwnProperty.call(item, 'value'))
    .map((item) => ({ id: String(item.id), value: item.value }));
}

function normaliseCounterIncrementConfigs(value: unknown): CounterIncrementConfig[] {
  return ensureArray(value)
    .map((item) => (typeof item === 'object' && item !== null ? (item as Record<string, unknown>) : null))
    .filter((item): item is Record<string, unknown> => !!item && typeof item.id === 'string')
    .map((item) => ({ id: String(item.id), step: item.step }));
}

function ensureArray(value: unknown): unknown[] {
  if (Array.isArray(value)) {
    return value;
  }
  if (value === undefined || value === null) {
    return [];
  }
  return [value];
}

function evaluateNumberExpression(
  expr: unknown,
  state: SurveyState,
  defaultValue: number,
  context?: EvaluateContext,
): number {
  const evaluated = expr === undefined ? defaultValue : evaluate(expr, state, context);
  const numeric = typeof evaluated === 'number' ? evaluated : Number(evaluated);
  if (!Number.isFinite(numeric)) {
    throw new Error('Counter expression must resolve to a finite number');
  }
  return numeric;
}

/**
 * Рекурсивно вычисляет jsonlogic_expression в значении, используя текущее состояние
 * Это нужно для правильного вычисления счетчиков на момент применения эффекта
 */
function evaluateJsonLogicExpressionsInValue(
  value: unknown,
  state: SurveyState,
): unknown {
  if (value === null || value === undefined) {
    return value;
  }

  if (typeof value !== 'object') {
    return value;
  }

  if (Array.isArray(value)) {
    return value.map((item) => evaluateJsonLogicExpressionsInValue(item, state));
  }

  const obj = value as Record<string, unknown>;
  
  // Check if this is an object with jsonlogic_expression
  if ('jsonlogic_expression' in obj) {
    const keys = Object.keys(obj);
    if (keys.length === 1 && keys[0] === 'jsonlogic_expression') {
      // Evaluate expression using current state
      try {
        const evaluated = evaluateJsonLogicExpression(obj.jsonlogic_expression, state);
        // Рекурсивно обрабатываем вычисленное значение
        return evaluateJsonLogicExpressionsInValue(evaluated, state);
      } catch (error) {
        console.error('[survey] jsonlogic_expression evaluation failed in effect', error);
        return value;
      }
    } else {
      // If there are other keys, evaluate only jsonlogic_expression
      const newObj: Record<string, unknown> = {};
      // First process jsonlogic_expression
      try {
        const evaluated = evaluateJsonLogicExpression(obj.jsonlogic_expression, state);
        // Recursively process computed value and replace jsonlogic_expression
        newObj.jsonlogic_expression = evaluateJsonLogicExpressionsInValue(evaluated, state);
      } catch (error) {
        console.error('[survey] jsonlogic_expression evaluation failed in effect', error);
        newObj.jsonlogic_expression = obj.jsonlogic_expression;
      }
      // Recursively process remaining fields
      for (const key in obj) {
        if (key !== 'jsonlogic_expression') {
          newObj[key] = evaluateJsonLogicExpressionsInValue(obj[key], state);
        }
      }
      return newObj;
    }
  }

  // Recursively process all object fields
  const newObj: Record<string, unknown> = {};
  for (const key in obj) {
    newObj[key] = evaluateJsonLogicExpressionsInValue(obj[key], state);
  }
  return newObj;
}

function applyEffect(
  effect: Record<string, unknown>,
  state: SurveyState,
) {
  if ('set' in effect) {
    const [target, valueExpr] = normalisePair((effect as Record<string, unknown>).set);
    const path = extractPath(target);
    const value = evaluate(valueExpr, state, undefined);
    setAtPath(state, path, value);
    return;
  }

  if ('inc' in effect) {
    const [target, deltaExpr] = normalisePair((effect as Record<string, unknown>).inc);
    const path = extractPath(target);
    const current = Number(getAtPath(state, path) ?? 0);
    const delta = Number(evaluate(deltaExpr, state, undefined) ?? 0);
    setAtPath(state, path, current + delta);
    return;
  }

  if ('add' in effect) {
    const [target, valueExpr] = normalisePair((effect as Record<string, unknown>).add);
    const path = extractPath(target);
    const value = evaluate(valueExpr, state, undefined);
    
    // Evaluate jsonlogic_expression in value immediately, using current state
    // This is important for correct counter computation at effect application time
    const evaluatedValue = evaluateJsonLogicExpressionsInValue(value, state);
    
    const existing = getAtPath(state, path);
    if (Array.isArray(existing)) {
      existing.push(evaluatedValue);
    } else if (existing === undefined) {
      setAtPath(state, path, [evaluatedValue]);
    } else {
      setAtPath(state, path, [existing, evaluatedValue]);
    }
  }
}

function normalisePair(input: unknown): [unknown, unknown] {
  if (Array.isArray(input)) {
    return [input[0], input[1]];
  }

  if (typeof input === 'object' && input !== null) {
    const { target, value } = input as { target: unknown; value: unknown };
    if (target !== undefined && value !== undefined) {
      return [target, value];
    }
  }

  throw new Error('Unsupported effect payload shape');
}

function extractPath(targetExpr: unknown): string {
  if (typeof targetExpr === 'object' && targetExpr !== null && 'var' in (targetExpr as Record<string, unknown>)) {
    return String((targetExpr as { var: unknown }).var);
  }
  throw new Error('Effect target must be a var expression');
}

function evaluate(
  expr: unknown,
  state: SurveyState,
  context?: EvaluateContext,
): unknown {
  if (expr === null || typeof expr !== 'object') {
    return expr;
  }

  if (Array.isArray(expr)) {
    return expr.map((item) => evaluate(item, state, context));
  }

  const node = expr as Record<string, unknown>;

  if ('var' in node) {
    if (node.var === 'counters') {
      return getCounters(state);
    }
    return getAtPath(state, String(node.var));
  }
  if ('cat' in node) {
    const parts = ensureArray(node.cat).map((part) => evaluate(part, state, context));
    return parts
      .map((part) => {
        if (part === undefined || part === null) {
          return '';
        }
        if (typeof part === 'object') {
          if (Array.isArray(part)) {
            return part.map((inner) => (inner === undefined || inner === null ? '' : String(inner))).join('');
          }
          try {
            return JSON.stringify(part);
          } catch {
            return String(part);
          }
        }
        return String(part);
      })
      .join('');
  }
  if ('+' in node && Array.isArray(node['+'])) {
    return (node['+'] as unknown[]).reduce<number>((total, part) => {
      const value = Number(evaluate(part, state, context) ?? 0);
      return total + value;
    }, 0);
  }
  if ('min' in node && Array.isArray(node.min)) {
    const values = (node.min as unknown[]).map((part) => Number(evaluate(part, state, context)));
    return Math.min(...values);
  }
  if ('max' in node && Array.isArray(node.max)) {
    const values = (node.max as unknown[]).map((part) => Number(evaluate(part, state, context)));
    return Math.max(...values);
  }
  if ('ck_id' in node) {
    // jsonLogic передает аргументы как массив, но может быть и одно значение
    const args = Array.isArray(node.ck_id) ? node.ck_id : [node.ck_id];
    if (args.length === 0) {
      return ck_id('');
    }
    // Вычисляем первый аргумент (ck_id принимает один аргумент)
    // Если аргумент - объект, который может быть JSONLogic-выражением, используем jsonLogic.apply для его вычисления
    let arg = args[0];
    if (arg !== null && typeof arg === 'object' && !Array.isArray(arg)) {
      // Try to evaluate via jsonLogic.apply to handle JSONLogic expressions (cat, reduce, var, etc.)
      try {
        arg = jsonLogic.apply(arg, state);
      } catch {
        // If can't evaluate via jsonLogic, try via evaluate
        arg = evaluate(arg, state, context);
      }
    } else {
      arg = evaluate(arg, state, context);
    }
    if (typeof arg === 'string') {
      return ck_id(arg);
    }
    // If argument is not string, convert to string
    const strArg = arg !== null && arg !== undefined ? String(arg) : '';
    return ck_id(strArg);
  }

  // If object is not special case, recursively process all its properties
  // This allows evaluating nested var expressions in objects (e.g., { "description": { "var": "_temp.curse_description" } })
  const result: Record<string, unknown> = {};
  for (const key in node) {
    result[key] = evaluate(node[key], state, context);
  }
  return result;
}

function getAtPath(source: unknown, path: string): unknown {
  const parts = path.split('.');
  let cursor: any = source;

  for (const part of parts) {
    if (cursor == null || typeof cursor !== 'object') {
      return undefined;
    }
    cursor = cursor[part];
  }

  return cursor;
}

function setAtPath(target: Record<string, unknown>, path: string, value: unknown) {
  const parts = path.split('.');
  let cursor: Record<string, unknown> = target;

  for (let index = 0; index < parts.length - 1; index += 1) {
    const part = parts[index]!;
    const next = cursor[part];
    if (typeof next !== 'object' || next === null) {
      const newBranch: Record<string, unknown> = {};
      cursor[part] = newBranch;
      cursor = newBranch;
    } else {
      cursor = next as Record<string, unknown>;
    }
  }

  const last = parts[parts.length - 1]!;
  cursor[last] = value;
}

/**
 * Вычисляет jsonLogic выражение, обрабатывая специальные случаи (например, i18n_uuid)
 */
function evaluateJsonLogicExpression(
  expression: unknown,
  state: SurveyState,
): unknown {
  const createEvaluationState = (): SurveyState => {
    return state;
  };

  try {
    const evaluationState = createEvaluationState();
    return jsonLogic.apply(expression, evaluationState);
  } catch (error) {
    // Если jsonLogic не может обработать выражение (например, из-за i18n_uuid в результате),
    // попробуем обработать его вручную для операций if
    if (typeof expression === 'object' && expression !== null && !Array.isArray(expression)) {
      const expr = expression as Record<string, unknown>;
      
      // Обрабатываем операцию if
      if ('if' in expr && Array.isArray(expr.if)) {
        const ifArgs = expr.if;
        const evaluationState = createEvaluationState();
        
        // if принимает нечетное количество аргументов: [condition1, value1, condition2, value2, ..., defaultValue]
        for (let i = 0; i < ifArgs.length - 1; i += 2) {
          const condition = ifArgs[i];
          const value = ifArgs[i + 1];
          
          try {
            const conditionResult = jsonLogic.apply(condition, evaluationState);
            if (Boolean(conditionResult)) {
              // Если значение - объект с i18n_uuid, возвращаем его как есть
              if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
                const valueObj = value as Record<string, unknown>;
                if ('i18n_uuid' in valueObj && Object.keys(valueObj).length === 1) {
                  return valueObj;
                }
              }
              // Иначе пытаемся вычислить значение через jsonLogic
              try {
                return jsonLogic.apply(value, evaluationState);
              } catch {
                // Если не получается, возвращаем значение как есть
                return value;
              }
            }
          } catch {
            // Продолжаем проверять следующие условия
            continue;
          }
        }
        
        // Если ни одно условие не выполнилось, возвращаем последнее значение (default)
        const defaultValue = ifArgs[ifArgs.length - 1];
        if (typeof defaultValue === 'object' && defaultValue !== null && !Array.isArray(defaultValue)) {
          const defaultObj = defaultValue as Record<string, unknown>;
          if ('i18n_uuid' in defaultObj && Object.keys(defaultObj).length === 1) {
            return defaultObj;
          }
        }
        try {
          return jsonLogic.apply(defaultValue, evaluationState);
        } catch {
          return defaultValue;
        }
      }
    }
    
    // Если не удалось обработать, пробрасываем ошибку дальше
    throw error;
  }
}

/**
 * Рекурсивно находит и вычисляет все jsonlogic_expression в объекте state.
 * Заменяет jsonlogic_expression на вычисленное значение.
 * @param obj - объект для обработки (будет изменен на месте)
 * @param state - полное состояние для использования в вычислениях jsonLogic
 */
function evaluateJsonLogicExpressions(
  obj: unknown,
  state: SurveyState,
): void {
  if (obj === null || obj === undefined) {
    return;
  }

  if (Array.isArray(obj)) {
    for (let i = 0; i < obj.length; i++) {
      const item = obj[i];
      // Обрабатываем элемент рекурсивно
      evaluateJsonLogicExpressions(item, state);
      
      // Затем проверяем текущее значение элемента (после рекурсивной обработки)
      const currentItem = obj[i];
      if (currentItem !== null && typeof currentItem === 'object' && !Array.isArray(currentItem)) {
        const itemRecord = currentItem as Record<string, unknown>;
        if ('jsonlogic_expression' in itemRecord) {
          const keys = Object.keys(itemRecord);
          if (keys.length === 1 && keys[0] === 'jsonlogic_expression') {
            // Заменяем весь элемент на вычисленное значение
            try {
              const evaluated = evaluateJsonLogicExpression(
                itemRecord.jsonlogic_expression, 
                state
              );
              obj[i] = evaluated;
              // Обрабатываем вычисленное значение рекурсивно
              evaluateJsonLogicExpressions(evaluated, state);
            } catch (error) {
              console.error('[survey] jsonlogic_expression evaluation failed', error);
            }
          }
        }
      }
    }
    return;
  }

  if (typeof obj !== 'object') {
    return;
  }

  const record = obj as Record<string, unknown>;

  // Проверяем, является ли сам объект объектом с jsonlogic_expression
  // Если да, не обрабатываем его здесь - это будет обработано родительским объектом
  if ('jsonlogic_expression' in record) {
    const keys = Object.keys(record);
    if (keys.length === 1 && keys[0] === 'jsonlogic_expression') {
      return;
    }
  }

  // Проверяем все свойства на наличие jsonlogic_expression и заменяем их
  // Используем массив ключей, чтобы избежать проблем с изменением объекта во время итерации
  const keys = Object.keys(record);
  for (const key of keys) {
    const value = record[key];
    
    // Если значение - объект с jsonlogic_expression
    if (value !== null && typeof value === 'object' && !Array.isArray(value)) {
      const valueRecord = value as Record<string, unknown>;
      
      if ('jsonlogic_expression' in valueRecord) {
        const valueKeys = Object.keys(valueRecord);
        
        // Если объект содержит только jsonlogic_expression, заменяем весь объект
        if (valueKeys.length === 1 && valueKeys[0] === 'jsonlogic_expression') {
          try {
            const evaluated = evaluateJsonLogicExpression(
              valueRecord.jsonlogic_expression, 
              state
            );
            record[key] = evaluated;
            // Обрабатываем вычисленное значение рекурсивно на случай вложенных выражений
            evaluateJsonLogicExpressions(evaluated, state);
            // Пропускаем рекурсивную обработку исходного значения, так как оно уже заменено
            continue;
          } catch (error) {
            console.error('[survey] jsonlogic_expression evaluation failed', error, key);
          }
        } else {
          // Если есть другие ключи, заменяем только значение jsonlogic_expression
          try {
            const evaluated = evaluateJsonLogicExpression(
              valueRecord.jsonlogic_expression, 
              state
            );
            valueRecord.jsonlogic_expression = evaluated;
            // Обрабатываем вычисленное значение рекурсивно
            evaluateJsonLogicExpressions(evaluated, state);
          } catch (error) {
            console.error('[survey] jsonlogic_expression evaluation failed', error);
          }
        }
      }
    }
    
    // Рекурсивно обрабатываем значение (если оно еще не было заменено)
    if (record[key] === value) {
      evaluateJsonLogicExpressions(value, state);
    }
  }
}

/**
 * Получает историю вопросов используя предзагруженные данные и пошаговое применение ответов
 */
function fetchHistoryQuestions(
  answers: AnswerInput[],
  lang: string,
  finalState: SurveyState,
  surveyData: SurveyData,
): HistoryQuestion[] {
  if (!answers.length) {
    return [];
  }


  // 1. Collect all UUIDs from path using preloaded metadata
  const allPathUuids = new Set<string>();
  const questionPaths = new Map<string, unknown[]>();

  for (const answer of answers) {
    const question = surveyData.questions.get(answer.questionId);
    if (!question) continue;
    
    const metadata = question.metadata as { path?: unknown[] } | undefined;
    const path = metadata?.path || [];
    questionPaths.set(answer.questionId, path);
    path.forEach((segment) => {
      if (typeof segment === 'string') {
        allPathUuids.add(segment);
      } else if (segment && typeof segment === 'object' && 'jsonlogic_expression' in segment) {
        // Extract all string values from jsonlogic_expression
        // that may be UUIDs (static values, not variables)
        extractStringsFromJsonLogic(segment.jsonlogic_expression, allPathUuids);
      }
      // Objects with var are not added to allPathUuids, they will be evaluated dynamically
    });
  }

  // 2. Get i18n texts from preloaded data
  const pathTextsMap: Record<string, string> = {};
  for (const uuid of allPathUuids) {
    const texts = surveyData.i18nTexts.get(uuid);
    if (texts) {
      pathTextsMap[uuid] = texts.get(lang) ?? texts.get('en') ?? uuid;
    }
  }

  // 3. Compute state incrementally (O(n) instead of O(n²))
  // For each question use state BEFORE its processing to compute path
  const result: HistoryQuestion[] = [];
  let currentState: SurveyState = {
    ...JSON.parse(JSON.stringify(defaultCharacter)),
    lang,
    answers: {
      byQuestion: {},
      byAnswer: {},
      lastQuestion: null,
      lastAnswer: null,
    },
    values: {
      byQuestion: {},
    },
  } as SurveyState;
  getCounters(currentState);
  
  for (let i = 0; i < answers.length; i++) {
    const answer = answers[i]!;
    
    // Используем состояние ДО применения текущего ответа для вычисления path
    // (состояние уже содержит все предыдущие ответы)
    const path = questionPaths.get(answer.questionId) || [];
    // Создаем Map из pathTextsMap для использования в resolvePathSegmentText
    const i18nTextsMapForPath = new Map<string, Map<string, string>>();
    for (const [uuid, text] of Object.entries(pathTextsMap)) {
      const langMap = new Map<string, string>();
      langMap.set(lang, text);
      i18nTextsMapForPath.set(uuid, langMap);
    }
    
    const pathTexts = path.map((segment) => {
      if (typeof segment === 'string') {
        return pathTextsMap[segment] || segment;
      }
      return resolvePathSegmentText(segment, currentState, surveyData.i18nTexts, lang);
    });
    const resolvedPath = path.map((segment) => evaluatePathSegment(segment, currentState));
    
    result.push({
      questionId: answer.questionId,
      path: resolvedPath,
      pathTexts,
    });

    // Теперь применяем эффекты текущего ответа к состоянию для следующей итерации
    // Используем предзагруженные метаданные
    const questionMeta = surveyData.questionMetadata.get(answer.questionId);
    if (questionMeta) {
      applyQuestionCounters(questionMeta, currentState);
    }

    if (answer.value !== undefined) {
      applyValueTarget(answer.value, questionMeta, currentState);
    }

    // Обновляем индексы ответов
    const answersIndex = currentState.answers as {
      byQuestion: Record<string, string[]>;
      byAnswer: Record<string, boolean>;
      lastQuestion: { id: string; metadata?: Record<string, unknown> } | null;
      lastAnswer: { questionId: string; answerIds: string[]; value?: AnswerValue } | null;
    };
    const valuesIndex = currentState.values as { byQuestion: Record<string, AnswerValue | undefined> };

    const existing = answersIndex.byQuestion[answer.questionId] ?? [];
    const recordedValues = [...answer.answerIds];
    if (answer.value !== undefined) {
      recordedValues.push(String(answer.value.data));
      valuesIndex.byQuestion[answer.questionId] = answer.value;
    }
    answersIndex.byQuestion[answer.questionId] = [...existing, ...recordedValues];
    answersIndex.lastQuestion = questionMeta
      ? { id: answer.questionId, metadata: questionMeta }
      : { id: answer.questionId };
    const lastAnswer: { questionId: string; answerIds: string[]; value?: AnswerValue } = {
      questionId: answer.questionId,
      answerIds: [...answer.answerIds],
    };
    if (answer.value !== undefined) {
      lastAnswer.value = answer.value;
    }
    answersIndex.lastAnswer = lastAnswer;
    for (const answerId of answer.answerIds) {
      answersIndex.byAnswer[answerId] = true;
    }
    if (answer.value === undefined && valuesIndex.byQuestion[answer.questionId] === undefined) {
      delete valuesIndex.byQuestion[answer.questionId];
    }

    // Применяем эффекты ответов используя предзагруженные данные
    for (const answerId of answer.answerIds) {
      const optionMeta = surveyData.answerMetadata.get(answerId);
      if (optionMeta) {
        applyAnswerCounters(optionMeta, currentState);
      }

      const effects = surveyData.effects.get(answerId) ?? [];
      for (const effect of effects) {
        applyEffect(effect.body, currentState);
      }
    }
  }
  
  return result;
}

/**
 * Получает историю текущего вопроса используя предзагруженные данные
 */
function fetchCurrentQuestionHistory(
  question: QuestionRow,
  lang: string,
  state: SurveyState,
  surveyData: SurveyData,
): HistoryQuestion {
  const metadata = question.metadata as { path?: unknown[] } | undefined;
  const path = metadata?.path || [];

  // Если path пустой, используем questionId
  if (path.length === 0) {
    return {
      questionId: question.id,
      path: [question.id],
      pathTexts: [question.id],
    };
  }

  // Формируем pathTexts, обрабатывая как UUID, так и объекты с var или jsonlogic_expression
  // Используем предзагруженные i18n тексты
  const pathTexts = path.map((segment) => resolvePathSegmentText(segment, state, surveyData.i18nTexts, lang));
  const resolvedPath = path.map((segment) => evaluatePathSegment(segment, state));

  return {
    questionId: question.id,
    path: resolvedPath,
    pathTexts,
  };
}
