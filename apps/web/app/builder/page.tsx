"use client";

import { ChangeEvent, KeyboardEvent, useCallback, useEffect, useMemo, useRef, useState } from "react";
import jsonLogic from "json-logic-js";
import { useLanguage } from "../language-context";
import { Topbar } from "../components/Topbar";
import { ShopRenderer } from "../components/ShopRenderer";

type AnswerValue = { type: "number"; data: number } | { type: "string"; data: string };
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

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:4000";

export default function BuilderPage() {
  const { lang, mounted } = useLanguage();
  // Use default language until mounted to avoid hydration mismatch
  const displayLang = mounted ? lang : "en";
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [history, setHistory] = useState<AnswerInput[]>([]);
  const [historyQuestions, setHistoryQuestions] = useState<HistoryQuestion[]>([]);
  const [question, setQuestion] = useState<Question | null>(null);
  const [options, setOptions] = useState<AnswerOption[]>([]);
  const [state, setState] = useState<Record<string, unknown>>({});
  const [done, setDone] = useState(false);
  const [pendingMultiple, setPendingMultiple] = useState<string[]>([]);
  const [hoveredOptionId, setHoveredOptionId] = useState<string | null>(null);
  const [valueString, setValueString] = useState("");
  const [valueNumber, setValueNumber] = useState("0");
  const [selectedDropDownOptionId, setSelectedDropDownOptionId] = useState<string | null>(null);
  const [showDebug, setShowDebug] = useState(false);
  const [lastResponseJson, setLastResponseJson] = useState<string>("");
  const [copySuccess, setCopySuccess] = useState(false);
  const [showGenerateResult, setShowGenerateResult] = useState(false);
  const [generateResultJson, setGenerateResultJson] = useState<string>("");
  const [loadingGenerateResult, setLoadingGenerateResult] = useState(false);
  const [generateResultError, setGenerateResultError] = useState<string | null>(null);
  const [copyGenerateSuccess, setCopyGenerateSuccess] = useState(false);
  const historyContainerRef = useRef<HTMLDivElement>(null);

  const questionMetadata = useMemo(() => (question?.metadata ?? {}) as Record<string, unknown>, [question]);
  const shopConfig = useMemo(() => {
    if (!question) return null;
    if (questionMetadata.renderer !== "shop") return null;
    const shop = questionMetadata.shop;
    return shop && typeof shop === "object" && !Array.isArray(shop) ? (shop as any) : null;
  }, [question, questionMetadata]);

  // Вычисление min/max из метаданных через jsonLogic
  const numericMin = useMemo(() => {
    if (!question || question.qtype !== "value_numeric") {
      return undefined;
    }
    const minExpr = questionMetadata.min;
    if (minExpr === undefined || minExpr === null) {
      return undefined;
    }
    try {
      // Если это просто число, возвращаем его
      if (typeof minExpr === "number") {
        return Number.isFinite(minExpr) ? minExpr : undefined;
      }
      // Иначе вычисляем через jsonLogic
      const result = jsonLogic.apply(minExpr, state);
      // Если результат null или undefined, возвращаем undefined
      if (result === null || result === undefined) {
        return undefined;
      }
      const numValue = typeof result === "number" ? result : Number(result);
      if (!Number.isFinite(numValue)) {
        return undefined;
      }
      return numValue;
    } catch (error) {
      return undefined;
    }
  }, [question, questionMetadata, state]);

  const numericMax = useMemo(() => {
    if (!question || question.qtype !== "value_numeric") {
      return undefined;
    }
    const maxExpr = questionMetadata.max;
    if (maxExpr === undefined || maxExpr === null) {
      return undefined;
    }
    try {
      // Если это просто число, возвращаем его
      if (typeof maxExpr === "number") {
        return Number.isFinite(maxExpr) ? maxExpr : undefined;
      }
      // Иначе вычисляем через jsonLogic
      const result = jsonLogic.apply(maxExpr, state);
      // Если результат null или undefined, возвращаем undefined (нет ограничения)
      if (result === null || result === undefined) {
        return undefined;
      }
      const numValue = typeof result === "number" ? result : Number(result);
      if (!Number.isFinite(numValue)) {
        return undefined;
      }
      return numValue;
    } catch (error) {
      return undefined;
    }
  }, [question, questionMetadata, state]);

  // Вычисление min_rand/max_rand из метаданных через jsonLogic (для кнопки случайного выбора)
  const numericMinRand = useMemo(() => {
    if (!question || question.qtype !== "value_numeric") {
      return undefined;
    }
    const minRandExpr = questionMetadata.min_rand;
    if (minRandExpr === undefined || minRandExpr === null) {
      return undefined;
    }
    try {
      // Если это просто число, возвращаем его
      if (typeof minRandExpr === "number") {
        return Number.isFinite(minRandExpr) ? minRandExpr : undefined;
      }
      // Иначе вычисляем через jsonLogic
      const result = jsonLogic.apply(minRandExpr, state);
      const numValue = typeof result === "number" ? result : Number(result);
      return Number.isFinite(numValue) ? numValue : undefined;
    } catch (error) {
      return undefined;
    }
  }, [question, questionMetadata, state]);

  const numericMaxRand = useMemo(() => {
    if (!question || question.qtype !== "value_numeric") {
      return undefined;
    }
    const maxRandExpr = questionMetadata.max_rand;
    if (maxRandExpr === undefined || maxRandExpr === null) {
      return undefined;
    }
    try {
      // Если это просто число, возвращаем его
      if (typeof maxRandExpr === "number") {
        return Number.isFinite(maxRandExpr) ? maxRandExpr : undefined;
      }
      // Иначе вычисляем через jsonLogic
      const result = jsonLogic.apply(maxRandExpr, state);
      const numValue = typeof result === "number" ? result : Number(result);
      return Number.isFinite(numValue) ? numValue : undefined;
    } catch (error) {
      return undefined;
    }
  }, [question, questionMetadata, state]);

  // Функция для ограничения значения в диапазоне min/max
  const clampValue = useCallback(
    (value: number): number => {
      let clamped = value;
      if (numericMin !== undefined && clamped < numericMin) {
        clamped = numericMin;
      }
      if (numericMax !== undefined && clamped > numericMax) {
        clamped = numericMax;
      }
      return clamped;
    },
    [numericMin, numericMax],
  );


  // Вычисление randomList из метаданных через jsonLogic (для value_textbox)
  const textboxRandomList = useMemo(() => {
    if (!question || question.qtype !== "value_textbox") {
      return undefined;
    }
    const randomListExpr = questionMetadata.randomList;
    if (randomListExpr === undefined || randomListExpr === null) {
      return undefined;
    }
    try {
      // Вычисляем через jsonLogic
      const result = jsonLogic.apply(randomListExpr, state);
      // Проверяем, что результат - массив строк
      if (Array.isArray(result)) {
        return result.filter((item): item is string => typeof item === "string" && item.length > 0);
      }
      return undefined;
    } catch (error) {
      return undefined;
    }
  }, [question, questionMetadata, state]);

  const canRandomiseQuestion = useMemo(() => {
    if (!question) return false;
    if (question.qtype === "single" || question.qtype === "single_table" || question.qtype === "multiple" || question.qtype === "drop_down_detailed") {
      return options.length > 0;
    }
    if (question.qtype === "value_numeric") {
      return numericMinRand !== undefined && numericMaxRand !== undefined;
    }
    if (question.qtype === "value_textbox") {
      // Доступна если есть randomList или defaultValue
      return textboxRandomList !== undefined || questionMetadata.defaultValue !== undefined;
    }
    return false;
  }, [options.length, question, numericMinRand, numericMaxRand, textboxRandomList, questionMetadata]);

  const tableColumns = useMemo(() => {
    if (!question || question.qtype !== "single_table") return [] as string[];
    const metadataColumns = (question.metadata as { columns?: unknown })?.columns;
    return Array.isArray(metadataColumns)
      ? metadataColumns.filter((value): value is string => typeof value === "string")
      : [];
  }, [question]);

  const fetchNext = useCallback(
    async (answers: AnswerInput[]) => {
      setLoading(true);
      setError(null);
      try {
        const response = await fetch(`${API_URL}/survey/next`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ answers, lang }),
        });

        if (!response.ok) {
          throw new Error(`Survey API responded with status ${response.status}`);
        }

        const responseText = await response.text();
        const payload: NextQuestionResponse = JSON.parse(responseText);
        
        // Сохраняем отформатированный JSON для debug
        setLastResponseJson(JSON.stringify(payload, null, 2));
        setHistory(payload.historyAnswers ?? answers);
        setHistoryQuestions(payload.historyQuestions ?? []);
        setState(payload.state ?? {});
        setDone(Boolean(payload.done));
        setQuestion(payload.question ?? null);
        setOptions(payload.answerOptions ?? []);
      } catch (err) {
        setError(err instanceof Error ? err.message : String(err));
      } finally {
        setLoading(false);
      }
    },
    [lang],
  );

  // Инициализация опроса только при первом монтировании
  useEffect(() => {
    void fetchNext([]);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // При изменении языка во время создания персонажа сохраняем текущее состояние
  useEffect(() => {
    // Если есть история ответов, значит мы в процессе создания персонажа
    // В этом случае вызываем fetchNext с текущей историей, но новым языком
    if (history.length > 0) {
      void fetchNext(history);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [lang]);

  useEffect(() => {
    setPendingMultiple([]);
    setHoveredOptionId(null);
    setSelectedDropDownOptionId(null);

    if (!question) {
      setValueString("");
      setValueNumber("0");
      return;
    }

    if (question.qtype === "value_string" || question.qtype === "value_textbox") {
      const defaultValue = questionMetadata.defaultValue;
      setValueString(typeof defaultValue === "string" ? defaultValue : "");
      setValueNumber("0");
    } else if (question.qtype === "value_numeric") {
      const defaultValue = questionMetadata.defaultValue;
      let initialValue = 0;
      if (typeof defaultValue === "number") {
        initialValue = defaultValue;
      } else if (typeof defaultValue === "string" && defaultValue.trim().length > 0 && !Number.isNaN(Number(defaultValue))) {
        initialValue = Number(defaultValue);
      }
      // Применяем ограничения min/max к начальному значению
      // Но только если clampValue уже определен (numericMin/numericMax вычислены)
      if (clampValue) {
        const clamped = clampValue(initialValue);
        setValueNumber(String(clamped));
      } else {
        setValueNumber(String(initialValue));
      }
      setValueString("");
    } else {
      setValueString("");
      setValueNumber("0");
    }
  }, [question, questionMetadata, state]);

  // Применяем ограничения min/max к текущему значению при изменении min/max
  // НЕ применяем при изменении valueNumber, чтобы не блокировать ввод
  useEffect(() => {
    if (question?.qtype !== "value_numeric" || valueNumber === "") {
      return;
    }
    const numValue = Number(valueNumber);
    if (!Number.isFinite(numValue)) {
      return;
    }
    const clamped = clampValue(numValue);
    if (clamped !== numValue) {
      setValueNumber(String(clamped));
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [question?.id, numericMin, numericMax]);

  const submitAnswer = useCallback(
    async (answerIds: string[]) => {
      if (!question) return;
      const nextHistory = [...history, { questionId: question.id, answerIds }];
      await fetchNext(nextHistory);
    },
    [fetchNext, history, question],
  );

  const submitValue = useCallback(
    async (value: AnswerValue) => {
      if (!question) return;
      // Применяем ограничения min/max перед отправкой
      if (value.type === "number") {
        const clamped = clampValue(value.data);
        // Обновляем значение в состоянии, если оно было ограничено
        if (clamped !== value.data) {
          setValueNumber(String(clamped));
        }
        value = { type: "number", data: clamped };
      }
      const nextHistory = [...history, { questionId: question.id, answerIds: [], value }];
      await fetchNext(nextHistory);
    },
    [fetchNext, history, question, clampValue],
  );

  const toggleMultiple = useCallback((answerId: string) => {
    setPendingMultiple((prev) => (prev.includes(answerId) ? prev.filter((id) => id !== answerId) : [...prev, answerId]));
  }, []);

  const handleStringChange = useCallback((event: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    setValueString(event.target.value);
  }, []);

  const allowFloat = useMemo(() => {
    if (!question || question.qtype !== "value_numeric") {
      return false;
    }
    const typeValue = questionMetadata.type;
    return typeof typeValue === "string" && typeValue.toLowerCase() === "float";
  }, [question, questionMetadata]);

  const handleNumberChange = useCallback(
    (event: ChangeEvent<HTMLInputElement>) => {
      const raw = event.target.value;
      if (raw === "") {
        setValueNumber("");
        return;
      }
      const pattern = allowFloat ? /^-?\d*(?:\.\d*)?$/ : /^-?\d*$/;
      if (pattern.test(raw)) {
        setValueNumber(raw);
      }
    },
    [allowFloat],
  );

  const adjustNumber = useCallback(
    (delta: number) => {
      setValueNumber((prev) => {
        const base = prev === "" ? 0 : Number(prev);
        if (!Number.isFinite(base)) {
          return prev;
        }
        const nextRaw = base + delta;
        const nextValue = allowFloat ? Number(nextRaw.toFixed(6)) : Math.round(nextRaw);
        const clamped = clampValue(nextValue);
        return String(clamped);
      });
    },
    [allowFloat, clampValue],
  );

  const handleNumberKeyDown = useCallback(
    (event: KeyboardEvent<HTMLInputElement>) => {
      if (event.key === "ArrowUp") {
        event.preventDefault();
        adjustNumber(1);
      } else if (event.key === "ArrowDown") {
        event.preventDefault();
        adjustNumber(-1);
      }
    },
    [adjustNumber],
  );

  // Обработка потери фокуса для применения ограничений
  const handleNumberBlur = useCallback(() => {
    setValueNumber((prev) => {
      if (prev === "") {
        return prev;
      }
      const numValue = Number(prev);
      if (!Number.isFinite(numValue)) {
        return prev;
      }
      const clamped = clampValue(numValue);
      return String(clamped);
    });
  }, [clampValue]);

  // Функция для случайного выбора значения в диапазоне min_rand-max_rand
  const pickRandomNumericValue = useCallback(() => {
    if (numericMinRand === undefined || numericMaxRand === undefined) {
      return;
    }
    if (numericMinRand > numericMaxRand) {
      return;
    }
    // Генерируем случайное значение в диапазоне [min_rand, max_rand] включительно
    const randomValue = Math.random() * (numericMaxRand - numericMinRand) + numericMinRand;
    // Округляем в зависимости от типа (int или float)
    const finalValue = allowFloat ? Number(randomValue.toFixed(6)) : Math.round(randomValue);
    // Применяем ограничения min/max к случайному значению перед установкой
    const clamped = clampValue(finalValue);
    setValueNumber(String(clamped));
  }, [numericMinRand, numericMaxRand, allowFloat, clampValue]);

  const bodyMarkup = useMemo(() => {
    if (!question?.body) return undefined;
    return { __html: question.body };
  }, [question?.body]);

  const renderLabel = (option: AnswerOption) => {
    if (!option.label) return option.id;
    return <span dangerouslySetInnerHTML={{ __html: option.label ?? "" }} />;
  };

  const pickRandomOption = useCallback((): AnswerOption | null => {
    if (!options.length) {
      return null;
    }

    // Собираем варианты с весами
    const weightedOptions: Array<{ option: AnswerOption; weight: number }> = [];
    
    for (const option of options) {
      const metadata = option.metadata ?? {};
      const weight = Number((metadata as Record<string, unknown>)["probability"]);
      
      // Если вес невалидный, используем равномерное распределение (вес = 1)
      const validWeight = Number.isFinite(weight) && weight > 0 ? weight : 1;
      weightedOptions.push({ option, weight: validWeight });
    }

    if (!weightedOptions.length) {
      // Fallback: равномерный выбор
      const randomIndex = Math.floor(Math.random() * options.length);
      return options[randomIndex] ?? null;
    }

    // Вычисляем сумму весов
    const totalWeight = weightedOptions.reduce((sum, item) => sum + item.weight, 0);
    if (totalWeight <= 0) {
      const randomIndex = Math.floor(Math.random() * options.length);
      return options[randomIndex] ?? null;
    }

    // Генерируем случайное число в диапазоне [0, totalWeight)
    let random = Math.random() * totalWeight;
    
    // Применяем модификатор из metadata вопроса, если он есть
    const diceModifierExpr = questionMetadata.diceModifier;
    if (diceModifierExpr !== undefined && diceModifierExpr !== null) {
      try {
        let modifier = 0;
        if (typeof diceModifierExpr === "number") {
          modifier = Number.isFinite(diceModifierExpr) ? diceModifierExpr : 0;
        } else if (typeof diceModifierExpr === "object") {
          // Проверяем, есть ли jsonlogic_expression
          const expr = (diceModifierExpr as Record<string, unknown>).jsonlogic_expression;
          if (expr !== undefined) {
            // Вычисляем через jsonLogic
            const result = jsonLogic.apply(expr, state);
            if (result !== null && result !== undefined) {
              const numValue = typeof result === "number" ? result : Number(result);
              if (Number.isFinite(numValue)) {
                modifier = numValue;
              }
            }
          } else {
            // Если нет jsonlogic_expression, пытаемся применить напрямую
            const result = jsonLogic.apply(diceModifierExpr, state);
            if (result !== null && result !== undefined) {
              const numValue = typeof result === "number" ? result : Number(result);
              if (Number.isFinite(numValue)) {
                modifier = numValue;
              }
            }
          }
        }
        
        // Применяем модификатор к случайному значению
        // Модификатор применяется как абсолютное значение, умноженное на totalWeight
        // (модификатор в диапазоне [-0.2, 0.2] означает изменение на ±20% от диапазона)
        random = random + (modifier * totalWeight);
        
        // Ограничиваем значение в пределах [0, totalWeight)
        random = Math.max(0, Math.min(totalWeight - 0.0001, random));
      } catch (error) {
        // В случае ошибки игнорируем модификатор
      }
    }
    
    // Находим вариант по накопленным весам
    let accumulated = 0;
    for (const { option, weight } of weightedOptions) {
      accumulated += weight;
      if (random < accumulated) {
        return option;
      }
    }
    
    // Fallback: возвращаем последний вариант
    return weightedOptions[weightedOptions.length - 1]?.option ?? null;
  }, [options, questionMetadata, state]);

  const randomiseAnswer = useCallback(() => {
    if (!question || !canRandomiseQuestion || loading) {
      return;
    }

    // Для value_numeric используем случайное значение из диапазона и сразу отправляем
    if (question.qtype === "value_numeric") {
      if (numericMinRand === undefined || numericMaxRand === undefined) {
        return;
      }
      if (numericMinRand > numericMaxRand) {
        return;
      }
      // Генерируем случайное значение в диапазоне [min_rand, max_rand] включительно
      const randomValue = Math.random() * (numericMaxRand - numericMinRand) + numericMinRand;
      // Округляем в зависимости от типа (int или float)
      const finalValue = allowFloat ? Number(randomValue.toFixed(6)) : Math.round(randomValue);
      // Применяем ограничения min/max к случайному значению
      const clamped = clampValue(finalValue);
      // Сразу отправляем значение
      void submitValue({ type: "number", data: clamped });
      return;
    }

    // Для value_textbox используем случайное значение из randomList или defaultValue
    if (question.qtype === "value_textbox") {
      let randomText: string | null = null;
      
      // Если есть randomList, выбираем случайную строку из массива
      if (textboxRandomList !== undefined && textboxRandomList.length > 0) {
        const randomIndex = Math.floor(Math.random() * textboxRandomList.length);
        randomText = textboxRandomList[randomIndex] ?? null;
      } 
      // Иначе если есть defaultValue, используем его
      else if (questionMetadata.defaultValue !== undefined && questionMetadata.defaultValue !== null) {
        randomText = typeof questionMetadata.defaultValue === "string" 
          ? questionMetadata.defaultValue 
          : String(questionMetadata.defaultValue);
      }
      // Иначе отправляем пустую строку (null будет интерпретироваться на бэкенде)
      
      // Сразу отправляем значение (пустая строка для null, так как тип требует string)
      void submitValue({ type: "string", data: randomText ?? "" });
      return;
    }

    const picked = pickRandomOption();
    if (!picked) {
      return;
    }

    if (question.qtype === "multiple") {
      setPendingMultiple([picked.id]);
    } else {
      void submitAnswer([picked.id]);
    }
  }, [canRandomiseQuestion, loading, pickRandomOption, question, submitAnswer, numericMinRand, numericMaxRand, allowFloat, clampValue, submitValue]);

  const content = {
    en: {
      title: "Character Creation",
      subtitle: "Step-by-step character creation wizard",
      step1: "Identity",
      step2: "Parameters",
      step3: "Skills",
      step4: "Lifepath",
      step5: "Equipment",
      step6: "Final Card",
    },
    ru: {
      title: "Создание персонажа",
      subtitle: "Мастер создания персонажа шаг за шагом",
      step1: "Идентичность",
      step2: "Параметры",
      step3: "Навыки",
      step4: "Жизненный путь",
      step5: "Снаряжение",
      step6: "Итоговая карточка",
    },
  };

  const t = content[displayLang];

  // Функции для группировки истории
  const getCommonPrefix = (path1: string[], path2: string[]): string[] => {
    const result: string[] = [];
    const minLength = Math.min(path1.length, path2.length);
    for (let i = 0; i < minLength; i++) {
      if (path1[i] === path2[i]) {
        result.push(path1[i]!);
      } else {
        break;
      }
    }
    return result;
  };

  type HistoryGroup = {
    path: string[];
    pathTexts: string[];
    level: number;
    isGroup: boolean;
    questionId?: string;
    questionIndex?: number;
    isCurrent?: boolean;
  };

  const groupedHistory = useMemo(() => {
    // Если нет historyQuestions или они пустые, показываем просто questionId
    if (historyQuestions.length === 0 && history.length > 0) {
      return history.map((answer, index): HistoryGroup => ({
        path: [answer.questionId],
        pathTexts: [answer.questionId],
        level: 0,
        isGroup: false,
        questionId: answer.questionId,
        questionIndex: index + 1,
      }));
    }

    if (historyQuestions.length === 0) {
      return [];
    }

    const result: HistoryGroup[] = [];
    const colorPalette = [
      '#3b82f6', // blue
      '#10b981', // green
      '#ef4444', // red
      '#8b5cf6', // purple
      '#f59e0b', // orange
    ];

    let currentGroupPath: string[] = [];
    let previousQuestionPath: string[] = [];
    let questionCounter = 0;

    for (let i = 0; i < historyQuestions.length; i++) {
      const historyItem = historyQuestions[i]!;
      const path = historyItem.path.length > 0 ? historyItem.path : [historyItem.questionId];
      const pathTexts =
        historyItem.pathTexts.length > 0 ? historyItem.pathTexts : [historyItem.questionId];
      const level = path.length - 1;

      // Проверяем, является ли путь предыдущего вопроса префиксом текущего пути
      const isPreviousPathPrefix = previousQuestionPath.length > 0 && 
        previousQuestionPath.every((segment, idx) => path[idx] === segment);

      // Определяем общий префикс с текущей группой
      const commonPrefix = getCommonPrefix(currentGroupPath, path);

      // Если префикс изменился, закрываем старые группы и открываем новые
      if (commonPrefix.length < currentGroupPath.length) {
        currentGroupPath = commonPrefix;
      }

      // Добавляем заголовки для новых уровней
      // Если предыдущий путь является префиксом, но разница больше чем один элемент,
      // нужно создать группы для промежуточных уровней
      if (isPreviousPathPrefix) {
        // Если предыдущий путь отличается только последним элементом, не создаем группы
        if (previousQuestionPath.length < path.length - 1) {
          // Есть промежуточные уровни - создаем группы для них
          for (let l = previousQuestionPath.length; l < path.length - 1; l++) {
            const groupPath = path.slice(0, l + 1);
            const groupPathTexts = pathTexts.slice(0, l + 1);
            result.push({
              path: groupPath,
              pathTexts: groupPathTexts,
              level: l,
              isGroup: true,
            });
            currentGroupPath = groupPath;
          }
        } else {
          // Предыдущий путь отличается только последним элементом - обновляем currentGroupPath
          currentGroupPath = previousQuestionPath;
        }
      } else {
        // Предыдущий путь не является префиксом - создаем группы для всех новых уровней
        for (let l = currentGroupPath.length; l < path.length - 1; l++) {
          const groupPath = path.slice(0, l + 1);
          const groupPathTexts = pathTexts.slice(0, l + 1);
          result.push({
            path: groupPath,
            pathTexts: groupPathTexts,
            level: l,
            isGroup: true,
          });
          currentGroupPath = groupPath;
        }
      }

      // Добавляем сам вопрос
      questionCounter++;
      result.push({
        path,
        pathTexts,
        level,
        isGroup: false,
        questionId: historyItem.questionId,
        questionIndex: questionCounter,
      });

      // Обновляем текущий путь группы и сохраняем путь текущего вопроса
      currentGroupPath = path.slice(0, -1);
      previousQuestionPath = path;
    }

    // Помечаем последний вопрос как текущий, если он соответствует текущему вопросу
    if (question && result.length > 0) {
      const lastItem = result[result.length - 1];
      if (lastItem && !lastItem.isGroup && lastItem.questionId === question.id) {
        lastItem.isCurrent = true;
      }
    }

    return result;
  }, [historyQuestions, history, question]);

  const questionPathTitle = useMemo(() => {
    if (!question) {
      return null;
    }

    if (historyQuestions.length === 0) {
      return question.id ?? null;
    }

    for (let index = historyQuestions.length - 1; index >= 0; index -= 1) {
      const historyItem = historyQuestions[index];
      if (!historyItem || historyItem.questionId !== question.id) {
        continue;
      }

      const segments =
        historyItem.pathTexts.length > 0
          ? historyItem.pathTexts
          : historyItem.path;

      const cleanedSegments = segments
        .map((segment) => segment?.trim())
        .filter((segment): segment is string => Boolean(segment && segment.length > 0));

      if (cleanedSegments.length > 0) {
        return cleanedSegments.join(" -> ");
      }
    }

    return question.id ?? null;
  }, [historyQuestions, question]);

  // Автоматическая прокрутка к последнему элементу истории при обновлении
  useEffect(() => {
    if (historyContainerRef.current && groupedHistory.length > 0) {
      const container = historyContainerRef.current;
      // Используем requestAnimationFrame для обеспечения рендеринга перед прокруткой
      requestAnimationFrame(() => {
        container.scrollTop = container.scrollHeight;
      });
    }
  }, [groupedHistory]);

  // Функция для загрузки результата generate-character
  const loadGenerateResult = useCallback(async () => {
    setLoadingGenerateResult(true);
    setGenerateResultError(null);
    try {
      // Send characterRaw only (generate-character expects characterRaw, not full survey state)
      const payload =
        state && typeof state === "object" && !Array.isArray(state) && "characterRaw" in (state as any)
          ? (state as any).characterRaw
          : state;
      const response = await fetch(`${API_URL}/generate-character?lang=${lang}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        throw new Error(`Request failed with status ${response.status}`);
      }

      const data = await response.json();
      setGenerateResultJson(JSON.stringify(data, null, 2));
    } catch (error) {
      setGenerateResultError(error instanceof Error ? error.message : String(error));
      setGenerateResultJson("");
    } finally {
      setLoadingGenerateResult(false);
    }
  }, [state, lang]);

  // Функция для копирования результата generate-character в буфер обмена
  const copyGenerateResultToClipboard = useCallback(async () => {
    const textToCopy = generateResultJson || (displayLang === "ru" ? "(нет данных)" : "(no data)");
    try {
      await navigator.clipboard.writeText(textToCopy);
      setCopyGenerateSuccess(true);
      setTimeout(() => setCopyGenerateSuccess(false), 2000);
    } catch (err) {
      // Fallback для старых браузеров
      const textArea = document.createElement("textarea");
      textArea.value = textToCopy;
      textArea.style.position = "fixed";
      textArea.style.opacity = "0";
      document.body.appendChild(textArea);
      textArea.select();
      try {
        document.execCommand("copy");
        setCopyGenerateSuccess(true);
        setTimeout(() => setCopyGenerateSuccess(false), 2000);
      } catch (fallbackErr) {
        console.error("Failed to copy:", fallbackErr);
      }
      document.body.removeChild(textArea);
    }
  }, [generateResultJson, displayLang]);

  // Функция для копирования debug информации в буфер обмена
  const copyDebugToClipboard = useCallback(async () => {
    const textToCopy = lastResponseJson || (displayLang === "ru" ? "(нет данных)" : "(no data)");
    try {
      await navigator.clipboard.writeText(textToCopy);
      setCopySuccess(true);
      setTimeout(() => setCopySuccess(false), 2000);
    } catch (err) {
      // Fallback для старых браузеров
      const textArea = document.createElement("textarea");
      textArea.value = textToCopy;
      textArea.style.position = "fixed";
      textArea.style.opacity = "0";
      document.body.appendChild(textArea);
      textArea.select();
      try {
        document.execCommand("copy");
        setCopySuccess(true);
        setTimeout(() => setCopySuccess(false), 2000);
      } catch (fallbackErr) {
        console.error("Failed to copy:", fallbackErr);
      }
      document.body.removeChild(textArea);
    }
  }, [lastResponseJson, displayLang]);

  return (
    <>
      <Topbar title={t.title} subtitle={t.subtitle} />
      <section className="content" suppressHydrationWarning>
        <div className="wizard">
          <div className="wizard-steps">
            {groupedHistory.length > 0 ? (
              <div className="question-history" ref={historyContainerRef}>
                {groupedHistory.map((item, index) => {
                  const colorPalette = [
                    '#3b82f6', // blue
                    '#10b981', // green
                    '#ef4444', // red
                    '#8b5cf6', // purple
                    '#f59e0b', // orange
                  ];
                  const color = colorPalette[item.level % colorPalette.length];
                  const paddingLeft = `${item.level * 1.5}rem`;

                  if (item.isGroup) {
                    // Заголовок группы
                    const groupTitle = item.pathTexts[item.pathTexts.length - 1] || '';
                    return (
                      <div
                        key={`group-${index}`}
                        className="history-group-header"
                        style={{
                          paddingLeft,
                          color,
                          fontWeight: 600,
                          marginTop: index > 0 ? '0.5rem' : '0',
                        }}
                      >
                        {groupTitle}
                      </div>
                    );
                  } else {
                    // Вопрос
                    const questionTitle = item.pathTexts[item.pathTexts.length - 1] || item.questionId || '';
                    const questionIndex = item.questionIndex || 0;
                    const isCurrent = item.isCurrent || false;
                    // Используем комбинацию questionId и path для создания уникального ключа
                    // Это важно, так как один и тот же questionId может появляться несколько раз
                    // (например, для разных siblings)
                    const uniqueKey = item.questionId 
                      ? `${item.questionId}-${item.path.join('-')}-${index}`
                      : `question-${index}`;
                    // Делаем вопрос интерактивным только если у него есть questionIndex (пронумерован)
                    const isClickable = questionIndex > 0 && !isCurrent;
                    const handleQuestionClick = () => {
                      if (isClickable && questionIndex > 0) {
                        // Берем все ответы до этого вопроса (не включительно)
                        // questionIndex начинается с 1, поэтому берем первые (questionIndex - 1) ответов
                        const answersToSend = history.slice(0, questionIndex - 1);
                        void fetchNext(answersToSend);
                      }
                    };
                    return (
                      <div
                        key={uniqueKey}
                        className={`history-question ${isCurrent ? 'history-question-current' : ''} ${isClickable ? 'history-question-clickable' : ''}`}
                        style={{
                          paddingLeft,
                          color,
                          fontSize: '0.875rem',
                          cursor: isClickable ? 'pointer' : 'default',
                        }}
                        onClick={handleQuestionClick}
                      >
                        <div 
                          className="history-question-index" 
                          style={{ 
                            borderColor: color, 
                            backgroundColor: isCurrent ? `${color}40` : `${color}20` 
                          }}
                        >
                          {questionIndex}
                        </div>
                        <div className="history-question-text">{questionTitle}</div>
                      </div>
                    );
                  }
                })}
              </div>
            ) : (
              <div className="question-history-empty">
                {displayLang === "ru" ? "История пуста" : "History is empty"}
              </div>
            )}
            <div className="wizard-footer">
              <button
                type="button"
                onClick={() => setShowDebug(true)}
                className="debug-btn"
              >
                🐛 {displayLang === "ru" ? "Debug" : "Debug"}
              </button>
              <button
                type="button"
                onClick={() => {
                  setShowGenerateResult(true);
                  void loadGenerateResult();
                }}
                className="debug-btn"
                disabled={loadingGenerateResult}
              >
                {loadingGenerateResult ? "⏳" : "✨"} {displayLang === "ru" ? "Generate" : "Generate"}
              </button>
            </div>
          </div>
          <div className="wizard-body">
            <div className="section-title-row">
              <div>
                <div className="section-title">
                  {questionPathTitle ?? question?.id ?? "Loading..."}
                </div>
                <div className="section-note">
                  {displayLang === "ru"
                    ? "Поля и структуры должны соответствовать API контракту персонажа."
                    : "Fields and structures must match the character API contract."}
                </div>
              </div>
              {canRandomiseQuestion && (
                <button
                  type="button"
                  onClick={randomiseAnswer}
                  disabled={loading || !canRandomiseQuestion}
                  className="badge-inline"
                  style={{ cursor: "pointer", border: "1px solid rgba(242,199,68,0.5)" }}
                >
                  🎲 {displayLang === "ru" ? "Случайный ответ" : "Random answer"}
                </button>
              )}
            </div>

            {error && <div className="survey-error">{error}</div>}

            {done && (
              <div className="survey-done">
                <p>{displayLang === "ru" ? "Опрос завершён." : "Survey completed."}</p>
                <button
                  type="button"
                  onClick={() => fetchNext([])}
                  disabled={loading}
                  className="btn btn-primary"
                >
                  {displayLang === "ru" ? "Начать заново" : "Restart"}
                </button>
              </div>
            )}

            {!done && question && (
              <div className={loading ? "survey-loading" : ""}>
                {bodyMarkup && (
                  <div
                    className="survey-question-body"
                    dangerouslySetInnerHTML={bodyMarkup}
                  />
                )}

                {shopConfig && (
                  <ShopRenderer
                    questionId={question.id}
                    shop={shopConfig}
                    lang={lang}
                    state={state}
                    disabled={loading}
                    onSubmit={(payload) => {
                      void submitValue({ type: "string", data: JSON.stringify(payload) });
                    }}
                  />
                )}

                {!shopConfig && question.qtype === "value_string" && (
                  <div style={{ display: "flex", flexDirection: "column", gap: "0.75rem", width: "100%" }}>
                    <input
                      type="text"
                      value={valueString}
                      onChange={handleStringChange}
                      disabled={loading}
                      placeholder={
                        typeof questionMetadata.placeholder === "string"
                          ? questionMetadata.placeholder
                          : undefined
                      }
                      className="survey-value-input"
                    />
                    <div className="survey-actions">
                      <button
                        type="button"
                        onClick={() => submitValue({ type: "string", data: valueString })}
                        disabled={loading || valueString.trim().length === 0}
                        className="btn btn-primary"
                      >
                        {displayLang === "ru" ? "Продолжить" : "Continue"}
                      </button>
                    </div>
                  </div>
                )}

                {!shopConfig && question.qtype === "value_textbox" && (
                  <div style={{ display: "flex", flexDirection: "column", gap: "0.75rem", width: "100%" }}>
                    <textarea
                      value={valueString}
                      onChange={handleStringChange}
                      disabled={loading}
                      placeholder={
                        typeof questionMetadata.placeholder === "string"
                          ? questionMetadata.placeholder
                          : undefined
                      }
                      rows={
                        typeof questionMetadata.rows === "number" && questionMetadata.rows > 0
                          ? Math.floor(questionMetadata.rows)
                          : 6
                      }
                      maxLength={
                        typeof questionMetadata.maxLength === "number"
                          ? Math.floor(questionMetadata.maxLength)
                          : undefined
                      }
                      className="survey-value-textarea"
                    />
                    <div className="survey-actions">
                      <button
                        type="button"
                        onClick={() => submitValue({ type: "string", data: valueString })}
                        disabled={loading || valueString.trim().length === 0}
                        className="btn btn-primary"
                      >
                        {displayLang === "ru" ? "Продолжить" : "Continue"}
                      </button>
                    </div>
                  </div>
                )}

                {!shopConfig && question.qtype === "value_numeric" && (
                  <div style={{ display: "flex", flexDirection: "column", gap: "0.75rem", width: "100%" }}>
                    <div className="survey-value-numeric-container">
                      <input
                        type="text"
                        value={valueNumber}
                        onChange={handleNumberChange}
                        onKeyDown={handleNumberKeyDown}
                        onBlur={handleNumberBlur}
                        disabled={loading}
                        inputMode={allowFloat ? "decimal" : "numeric"}
                        placeholder={
                          typeof questionMetadata.placeholder === "string"
                            ? questionMetadata.placeholder
                            : undefined
                        }
                        className="survey-value-numeric-input"
                      />
                      <div className="survey-numeric-controls">
                        <button
                          type="button"
                          onClick={() => adjustNumber(1)}
                          disabled={loading}
                          title={displayLang === "ru" ? "Увеличить" : "Increase"}
                          aria-label={displayLang === "ru" ? "Увеличить" : "Increase"}
                          className="survey-numeric-btn"
                        >
                          <svg width="12" height="12" viewBox="0 0 12 12" aria-hidden="true" focusable="false">
                            <path d="M6 3l4 6H2z" fill="currentColor" />
                          </svg>
                        </button>
                        <button
                          type="button"
                          onClick={() => adjustNumber(-1)}
                          disabled={loading}
                          title={displayLang === "ru" ? "Уменьшить" : "Decrease"}
                          aria-label={displayLang === "ru" ? "Уменьшить" : "Decrease"}
                          className="survey-numeric-btn"
                        >
                          <svg width="12" height="12" viewBox="0 0 12 12" aria-hidden="true" focusable="false">
                            <path d="M2 3h8l-4 6z" fill="currentColor" />
                          </svg>
                        </button>
                      </div>
                    </div>
                    <div className="survey-actions">
                      <button
                        type="button"
                        onClick={() => {
                          const numValue = Number(valueNumber === "" ? "0" : valueNumber);
                          if (!Number.isFinite(numValue)) {
                            return;
                          }
                          // Применяем ограничения перед отправкой
                          const clamped = clampValue(numValue);
                          submitValue({
                            type: "number",
                            data: clamped,
                          });
                        }}
                        disabled={loading || valueNumber === "" || Number.isNaN(Number(valueNumber))}
                        className="btn btn-primary"
                      >
                        {displayLang === "ru" ? "Продолжить" : "Continue"}
                      </button>
                    </div>
                  </div>
                )}

                {!shopConfig && question.qtype === "single" && (
                  <ul className="survey-options-list">
                    {options.map((option) => (
                      <li key={option.id}>
                        <button
                          type="button"
                          onClick={() => submitAnswer([option.id])}
                          disabled={loading}
                          className="survey-option-btn"
                        >
                          {renderLabel(option)}
                        </button>
                      </li>
                    ))}
                  </ul>
                )}

                {!shopConfig && question.qtype === "single_table" && (
                  <div style={{ overflowX: "auto" }}>
                    <table className="survey-table">
                      {tableColumns.length > 0 && (
                        <thead>
                          <tr>
                            {tableColumns.map((column) => (
                              <th key={column}>{column}</th>
                            ))}
                          </tr>
                        </thead>
                      )}
                      <tbody>
                        {options.map((option) => {
                          const isHovered = hoveredOptionId === option.id;
                          return (
                            <tr
                              key={option.id}
                              onClick={() => submitAnswer([option.id])}
                              onMouseEnter={() => setHoveredOptionId(option.id)}
                              onMouseLeave={() => setHoveredOptionId(null)}
                              style={{
                                cursor: loading ? "not-allowed" : "pointer",
                                opacity: loading ? 0.7 : 1,
                              }}
                              dangerouslySetInnerHTML={{ __html: option.label ?? "" }}
                            />
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                )}

                {!shopConfig && question.qtype === "multiple" && (
                  <>
                    {/*
                      allowEmptySelection:
                      If true, user can continue with empty selection (submitAnswer([])).
                    */}
                    {(() => {
                      const allowEmptySelection =
                        Boolean((questionMetadata as Record<string, unknown>).allowEmptySelection);
                      return (
                    <div className="survey-multiple-toolbar">
                      <button
                        type="button"
                        onClick={() => submitAnswer(pendingMultiple)}
                        disabled={loading || (!allowEmptySelection && pendingMultiple.length === 0)}
                        className="btn btn-primary"
                      >
                        {displayLang === "ru" ? "Продолжить" : "Continue"}
                      </button>

                      <div className="survey-multiple-toolbar-right">
                        <button
                          type="button"
                          onClick={() => setPendingMultiple(options.map((o) => o.id))}
                          disabled={loading || options.length === 0 || pendingMultiple.length === options.length}
                          className="btn btn-ghost"
                          title={displayLang === "ru" ? "Выбрать всё" : "Select all"}
                          aria-label={displayLang === "ru" ? "Выбрать всё" : "Select all"}
                        >
                          {displayLang === "ru" ? "Выбрать всё" : "Select all"}
                        </button>
                        <button
                          type="button"
                          onClick={() => setPendingMultiple([])}
                          disabled={loading || pendingMultiple.length === 0}
                          className="btn btn-ghost"
                          title={displayLang === "ru" ? "Снять всё" : "Clear"}
                          aria-label={displayLang === "ru" ? "Снять всё" : "Clear"}
                        >
                          {displayLang === "ru" ? "Снять всё" : "Clear"}
                        </button>
                      </div>
                    </div>
                      );
                    })()}

                    <ul className="survey-options-list">
                      {options.map((option) => {
                        const active = pendingMultiple.includes(option.id);
                        return (
                          <li key={option.id}>
                            <button
                              type="button"
                              onClick={() => toggleMultiple(option.id)}
                              disabled={loading}
                              className={`survey-option-btn survey-option-multiple ${active ? "active" : ""}`}
                            >
                              {renderLabel(option)}
                            </button>
                          </li>
                        );
                      })}
                    </ul>
                  </>
                )}

                {!shopConfig && question.qtype === "drop_down_detailed" && (
                  <div style={{ display: "flex", flexDirection: "column", gap: "0.75rem", width: "100%" }}>
                    <select
                      value={selectedDropDownOptionId ?? ""}
                      onChange={(e) => setSelectedDropDownOptionId(e.target.value || null)}
                      disabled={loading}
                      className="survey-dropdown-select"
                    >
                      <option value="">
                        {displayLang === "ru" ? "-- Выберите вариант --" : "-- Select an option --"}
                      </option>
                      {options.map((option) => {
                        const metadata = option.metadata ?? {};
                        const title = (metadata.title as string | undefined) ?? option.label ?? option.id;
                        return (
                          <option key={option.id} value={option.id}>
                            {typeof title === "string" ? title : option.id}
                          </option>
                        );
                      })}
                    </select>
                    {selectedDropDownOptionId && (
                      <div
                        className="survey-dropdown-details"
                      >
                        {(() => {
                          const selectedOption = options.find((opt) => opt.id === selectedDropDownOptionId);
                          if (!selectedOption) return null;
                          const metadata = selectedOption.metadata ?? {};
                          const description = (metadata.description as string | undefined) ?? selectedOption.label ?? "";
                          return (
                            <div
                              dangerouslySetInnerHTML={{
                                __html: typeof description === "string" ? description : "",
                              }}
                            />
                          );
                        })()}
                      </div>
                    )}
                    <div className="survey-actions">
                      <button
                        type="button"
                        onClick={() => {
                          if (selectedDropDownOptionId) {
                            void submitAnswer([selectedDropDownOptionId]);
                          }
                        }}
                        disabled={loading || !selectedDropDownOptionId}
                        className="btn btn-primary"
                      >
                        {displayLang === "ru" ? "Продолжить" : "Continue"}
                      </button>
                    </div>
                  </div>
                )}

                {!shopConfig &&
                  question.qtype !== "single" &&
                  question.qtype !== "multiple" &&
                  question.qtype !== "single_table" &&
                  question.qtype !== "value_string" &&
                  question.qtype !== "value_numeric" &&
                  question.qtype !== "value_textbox" &&
                  question.qtype !== "drop_down_detailed" && (
                    <p>
                      {displayLang === "ru"
                        ? `Неподдерживаемый тип вопроса: ${question.qtype}`
                        : `Unsupported question type: ${question.qtype}`}
                    </p>
                  )}
              </div>
            )}

            {!question && !done && !loading && (
              <div className="survey-done">
                <p>{displayLang === "ru" ? "Загрузка..." : "Loading..."}</p>
              </div>
            )}
          </div>
        </div>
      </section>

      {showDebug && (
        <div className="modal-overlay" onClick={() => setShowDebug(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <div className="modal-title">
                {displayLang === "ru" ? "Debug информация" : "Debug Information"}
              </div>
              <div style={{ display: "flex", gap: "8px", alignItems: "center" }}>
                <button
                  type="button"
                  onClick={copyDebugToClipboard}
                  className="btn btn-secondary"
                  style={{
                    padding: "6px 12px",
                    fontSize: "14px",
                    display: "flex",
                    alignItems: "center",
                    gap: "6px",
                  }}
                  title={displayLang === "ru" ? "Копировать в буфер обмена" : "Copy to clipboard"}
                >
                  {copySuccess ? (
                    <>
                      ✓ {displayLang === "ru" ? "Скопировано" : "Copied"}
                    </>
                  ) : (
                    <>
                      📋 {displayLang === "ru" ? "Копировать" : "Copy"}
                    </>
                  )}
                </button>
                <button
                  type="button"
                  className="modal-close"
                  onClick={() => setShowDebug(false)}
                  aria-label={displayLang === "ru" ? "Закрыть" : "Close"}
                >
                  ×
                </button>
              </div>
            </div>
            <div className="modal-body">
              <textarea
                readOnly
                value={lastResponseJson || (displayLang === "ru" ? "(нет данных)" : "(no data)")}
                style={{
                  width: "100%",
                  minHeight: "400px",
                  fontFamily: "monospace",
                  fontSize: "12px",
                  padding: "12px",
                  border: "1px solid var(--border)",
                  borderRadius: "4px",
                  backgroundColor: "var(--bg-secondary)",
                  color: "var(--text)",
                  resize: "vertical",
                }}
              />
            </div>
          </div>
        </div>
      )}

      {showGenerateResult && (
        <div className="modal-overlay" onClick={() => setShowGenerateResult(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <div className="modal-title">
                {displayLang === "ru" ? "Результат generate-character" : "Generate-character Result"}
              </div>
              <div style={{ display: "flex", gap: "8px", alignItems: "center" }}>
                <button
                  type="button"
                  onClick={copyGenerateResultToClipboard}
                  className="btn btn-secondary"
                  style={{
                    padding: "6px 12px",
                    fontSize: "14px",
                    display: "flex",
                    alignItems: "center",
                    gap: "6px",
                  }}
                  title={displayLang === "ru" ? "Копировать в буфер обмена" : "Copy to clipboard"}
                >
                  {copyGenerateSuccess ? (
                    <>
                      ✓ {displayLang === "ru" ? "Скопировано" : "Copied"}
                    </>
                  ) : (
                    <>
                      📋 {displayLang === "ru" ? "Копировать" : "Copy"}
                    </>
                  )}
                </button>
                <button
                  type="button"
                  className="modal-close"
                  onClick={() => setShowGenerateResult(false)}
                  aria-label={displayLang === "ru" ? "Закрыть" : "Close"}
                >
                  ×
                </button>
              </div>
            </div>
            <div className="modal-body">
              <div className="debug-section">
                <div className="debug-section-title">Ответ /generate-character</div>
                <pre className="debug-code debug-json">
                  {loadingGenerateResult
                    ? "Загрузка..."
                    : generateResultError
                    ? `Ошибка: ${generateResultError}`
                    : generateResultJson || (displayLang === "ru" ? "(пусто)" : "(empty)")}
                </pre>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
}

