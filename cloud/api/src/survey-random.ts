import jsonLogic from 'json-logic-js';
import { getNextQuestion } from '@wcc/core';

type AnswerValue =
  | { type: 'number'; data: number }
  | { type: 'string'; data: string };

type AnswerInput = {
  questionId: string;
  answerIds: string[];
  value?: AnswerValue;
};

type Question = {
  id: string;
  body: string | null;
  qtype: string;
  metadata: Record<string, unknown>;
};

type AnswerOption = {
  id: string;
  label: string | null;
  sortOrder: number;
  metadata: Record<string, unknown>;
};

type HistoryQuestion = {
  questionId: string;
  path: string[];
  pathTexts: string[];
};

type NextQuestionResponse = {
  done: boolean;
  question?: Question;
  answerOptions?: AnswerOption[];
  state: Record<string, unknown>;
  historyAnswers: AnswerInput[];
  historyQuestions?: HistoryQuestion[];
};

type RandomToEndRequest = {
  surveyId?: string;
  lang?: string;
  seed?: string;
  answers?: AnswerInput[];
};

const __wccJsonLogicOpsRegistered = (() => {
  try {
    jsonLogic.add_operation('d6', () => Math.floor(Math.random() * 6) + 1);
    jsonLogic.add_operation('d10', () => Math.floor(Math.random() * 10) + 1);
  } catch {
    // no-op if already registered
  }
  return true;
})();
void __wccJsonLogicOpsRegistered;

function resolveNumericValue(
  expr: unknown,
  evalState: Record<string, unknown>,
  treatNullAsUndefined: boolean,
): number | undefined {
  if (expr === undefined || expr === null) return undefined;
  try {
    if (typeof expr === 'number') {
      return Number.isFinite(expr) ? expr : undefined;
    }
    const result = jsonLogic.apply(expr, evalState);
    if (treatNullAsUndefined && (result === null || result === undefined)) {
      return undefined;
    }
    const numValue = typeof result === 'number' ? result : Number(result);
    return Number.isFinite(numValue) ? numValue : undefined;
  } catch {
    return undefined;
  }
}

function computeNumericMinMax(
  metadata: Record<string, unknown>,
  evalState: Record<string, unknown>,
) {
  return {
    min: resolveNumericValue(metadata.min, evalState, true),
    max: resolveNumericValue(metadata.max, evalState, true),
  };
}

function computeNumericRandMinMax(
  metadata: Record<string, unknown>,
  evalState: Record<string, unknown>,
) {
  return {
    minRand: resolveNumericValue(metadata.min_rand, evalState, false),
    maxRand: resolveNumericValue(metadata.max_rand, evalState, false),
  };
}

function resolveTextboxRandomList(
  metadata: Record<string, unknown>,
  evalState: Record<string, unknown>,
): string[] | undefined {
  const randomListExpr = metadata.randomList;
  if (randomListExpr === undefined || randomListExpr === null) return undefined;
  try {
    const result = jsonLogic.apply(randomListExpr, evalState);
    if (Array.isArray(result)) {
      return result.filter(
        (item): item is string => typeof item === 'string' && item.length > 0,
      );
    }
  } catch {
    return undefined;
  }
  return undefined;
}

function canRandomiseQuestionFor(
  valueQuestion: Question | null,
  valueOptions: AnswerOption[],
  evalState: Record<string, unknown>,
): boolean {
  if (!valueQuestion) return false;
  const metadata = (valueQuestion.metadata ?? {}) as Record<string, unknown>;
  if (
    valueQuestion.qtype === 'single' ||
    valueQuestion.qtype === 'single_table' ||
    valueQuestion.qtype === 'multiple' ||
    valueQuestion.qtype === 'drop_down_detailed'
  ) {
    return valueOptions.length > 0;
  }
  if (valueQuestion.qtype === 'value_numeric') {
    const { minRand, maxRand } = computeNumericRandMinMax(metadata, evalState);
    return minRand !== undefined && maxRand !== undefined;
  }
  if (valueQuestion.qtype === 'value_textbox') {
    const randomList = resolveTextboxRandomList(metadata, evalState);
    return randomList !== undefined || metadata.defaultValue !== undefined;
  }
  return false;
}

function pickRandomOptionFor(
  valueOptions: AnswerOption[],
  metadata: Record<string, unknown>,
  evalState: Record<string, unknown>,
): AnswerOption | null {
  if (!valueOptions.length) return null;

  const weightedOptions: Array<{ option: AnswerOption; weight: number }> = [];
  for (const option of valueOptions) {
    const optionMetadata = option.metadata ?? {};
    const weight = Number(
      (optionMetadata as Record<string, unknown>)['probability'],
    );
    const validWeight = Number.isFinite(weight) && weight >= 0 ? weight : 1;
    weightedOptions.push({ option, weight: validWeight });
  }

  const totalWeight = weightedOptions.reduce((sum, item) => sum + item.weight, 0);
  if (totalWeight <= 0) {
    return valueOptions[Math.floor(Math.random() * valueOptions.length)] ?? null;
  }

  let random = Math.random() * totalWeight;
  const diceModifierExpr = metadata.diceModifier;
  if (diceModifierExpr !== undefined && diceModifierExpr !== null) {
    try {
      let modifier = 0;
      if (typeof diceModifierExpr === 'number') {
        modifier = Number.isFinite(diceModifierExpr) ? diceModifierExpr : 0;
      } else if (typeof diceModifierExpr === 'object') {
        const expr = (diceModifierExpr as Record<string, unknown>)
          .jsonlogic_expression;
        const result =
          expr !== undefined
            ? jsonLogic.apply(expr as any, evalState)
            : jsonLogic.apply(diceModifierExpr as any, evalState);
        if (result !== null && result !== undefined) {
          const numValue = typeof result === 'number' ? result : Number(result);
          if (Number.isFinite(numValue)) modifier = numValue;
        }
      }
      random = random + modifier * totalWeight;
      random = Math.max(0, Math.min(totalWeight - 0.0001, random));
    } catch {
      // ignore invalid modifier
    }
  }

  let accumulated = 0;
  for (const { option, weight } of weightedOptions) {
    accumulated += weight;
    if (random < accumulated) {
      return option;
    }
  }
  return weightedOptions[weightedOptions.length - 1]?.option ?? null;
}

function buildRandomAnswer(
  valueQuestion: Question | null,
  valueOptions: AnswerOption[],
  evalState: Record<string, unknown>,
): AnswerInput | null {
  if (!valueQuestion) return null;
  const metadata = (valueQuestion.metadata ?? {}) as Record<string, unknown>;

  if (valueQuestion.qtype === 'value_numeric') {
    const { minRand, maxRand } = computeNumericRandMinMax(metadata, evalState);
    if (minRand === undefined || maxRand === undefined || minRand > maxRand) {
      return null;
    }
    const allowFloatValue =
      typeof metadata.type === 'string' && metadata.type.toLowerCase() === 'float';
    const randomValue = Math.random() * (maxRand - minRand) + minRand;
    const finalValue = allowFloatValue
      ? Number(randomValue.toFixed(6))
      : Math.round(randomValue);
    const { min, max } = computeNumericMinMax(metadata, evalState);
    let clamped = finalValue;
    if (min !== undefined && clamped < min) clamped = min;
    if (max !== undefined && clamped > max) clamped = max;
    return {
      questionId: valueQuestion.id,
      answerIds: [],
      value: { type: 'number', data: clamped },
    };
  }

  if (valueQuestion.qtype === 'value_textbox') {
    const randomList = resolveTextboxRandomList(metadata, evalState);
    let randomText: string | null = null;
    if (randomList !== undefined && randomList.length > 0) {
      randomText = randomList[Math.floor(Math.random() * randomList.length)] ?? null;
    } else if (metadata.defaultValue !== undefined && metadata.defaultValue !== null) {
      randomText =
        typeof metadata.defaultValue === 'string'
          ? metadata.defaultValue
          : String(metadata.defaultValue);
    }
    return {
      questionId: valueQuestion.id,
      answerIds: [],
      value: { type: 'string', data: randomText ?? '' },
    };
  }

  if (valueQuestion.qtype === 'multiple') {
    if (!valueOptions.length) return null;
    const allowEmptySelection = Boolean(metadata.allowEmptySelection);
    const minSelected =
      typeof metadata.minSelected === 'number' ? metadata.minSelected : 0;
    const maxSelectedRaw =
      typeof metadata.maxSelected === 'number'
        ? metadata.maxSelected
        : valueOptions.length;
    const maxSelected = Math.min(maxSelectedRaw, valueOptions.length);
    const requiredMin = allowEmptySelection ? minSelected : Math.max(1, minSelected);
    const effectiveMin = Math.min(requiredMin, valueOptions.length);
    const effectiveMax = Math.max(effectiveMin, maxSelected);
    const count =
      Math.floor(Math.random() * (effectiveMax - effectiveMin + 1)) +
      effectiveMin;
    const shuffled = [...valueOptions].sort(() => Math.random() - 0.5);
    return {
      questionId: valueQuestion.id,
      answerIds: shuffled.slice(0, count).map((option) => option.id),
    };
  }

  if (
    valueQuestion.qtype === 'single' ||
    valueQuestion.qtype === 'single_table' ||
    valueQuestion.qtype === 'drop_down_detailed'
  ) {
    const picked = pickRandomOptionFor(valueOptions, metadata, evalState);
    if (!picked) return null;
    return { questionId: valueQuestion.id, answerIds: [picked.id] };
  }

  return null;
}

export async function getSurveyRandomToStable(
  payload: RandomToEndRequest,
): Promise<NextQuestionResponse> {
  let current = (await getNextQuestion(payload)) as NextQuestionResponse;
  let currentQuestion = (current.question ?? null) as Question | null;
  let currentOptions = (current.answerOptions ?? []) as AnswerOption[];
  let currentState = (current.state ?? {}) as Record<string, unknown>;
  let currentDone = Boolean(current.done);
  let currentHistory = (current.historyAnswers ?? payload.answers ?? []) as AnswerInput[];
  let safety = 0;

  while (currentQuestion && !currentDone) {
    if (!canRandomiseQuestionFor(currentQuestion, currentOptions, currentState)) {
      break;
    }

    const randomAnswer = buildRandomAnswer(currentQuestion, currentOptions, currentState);
    if (!randomAnswer) {
      break;
    }

    const nextHistory = [...currentHistory, randomAnswer];
    current = (await getNextQuestion({
      surveyId: payload.surveyId,
      lang: payload.lang,
      seed: payload.seed,
      answers: nextHistory,
    })) as NextQuestionResponse;

    currentHistory = (current.historyAnswers ?? nextHistory) as AnswerInput[];
    currentState = (current.state ?? {}) as Record<string, unknown>;
    currentDone = Boolean(current.done);
    currentQuestion = (current.question ?? null) as Question | null;
    currentOptions = (current.answerOptions ?? []) as AnswerOption[];

    safety += 1;
    if (safety > 5000) {
      break;
    }
  }

  return current;
}
