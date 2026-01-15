import { useCallback, useMemo, useState, useRef, useEffect } from "react";

type ShopBudgetCoverageMoney = {
  sources?: string[];
  items?: string[];
};

type ShopBudgetCoverageTokensItem = {
  cost?: number;
  ids: string[];
};

type ShopBudgetCoverageTokens = {
  sources?: Array<ShopBudgetCoverageTokensItem | string>;
  items?: Array<ShopBudgetCoverageTokensItem | string>;
};

type ShopBudgetConfig = {
  id: string;
  type: 'money' | 'tokens';
  source: string;
  coverage?: ShopBudgetCoverageMoney | ShopBudgetCoverageTokens;
  priority: number;
  is_default?: boolean;
  is_required?: boolean;
  is_with_default?: boolean; // only for money
  is_with_money?: boolean; // only for tokens
  name: string; // resolved i18n text
};

type ShopSourceColumn = {
  field: string;
  label?: string;
};

type ShopSourceConfig = {
  id: string;
  title: string;
  table: string;
  dlcColumn: string;
  keyColumn: string;
  groupColumn?: string;
  tooltipField?: string;
  targetPath: string;
  filters?: Record<string, unknown>;
  columns: ShopSourceColumn[];
};

type ShopConfig = {
  isProfessional?: boolean;
  budgets?: ShopBudgetConfig[];
  warningPriceZero?: string; // resolved i18n text
  allowedDlcs?: string[];
  sources: ShopSourceConfig[];
};

type ShopPurchase = { sourceId: string; id: string; qty: number };

type ProfessionalBundleItem = {
  itemId: string;
  quantity?: number;
  sourceId: string;
};

type ProfessionalBundle = {
  bundleId: string;
  displayName?: unknown;
  items: ProfessionalBundleItem[];
};

const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:4000";

function getAtPath(obj: unknown, path: string): unknown {
  if (!path) return undefined;
  const parts = path.split(".");
  let cursor: any = obj;
  for (const part of parts) {
    if (cursor == null || typeof cursor !== "object") return undefined;
    cursor = cursor[part];
  }
  return cursor;
}

function toNumber(value: unknown, fallback = 0): number {
  const n = typeof value === "number" ? value : Number(value);
  return Number.isFinite(n) ? n : fallback;
}

function clampInt(value: number): number {
  if (!Number.isFinite(value)) return 0;
  return Math.max(0, Math.floor(value));
}

type SortColumn = 'checkbox' | 'qty' | string;

function sortRows<T extends Record<string, unknown>>(
  rows: T[],
  column: SortColumn,
  direction: 'asc' | 'desc',
  sourceId: string,
  keyColumn: string,
  qtyBySource: Record<string, Record<string, number>>,
  sourceColumns: ShopSourceColumn[],
): T[] {
  // Create a copy with original indices for stable sort
  const rowsWithIndex = rows.map((row, idx) => ({ row, originalIndex: idx }));
  
  rowsWithIndex.sort((a, b) => {
    let aVal: unknown;
    let bVal: unknown;
    
    if (column === 'checkbox') {
      // First column: checkbox (1 for checked, 0 for unchecked)
      const aKey = a.row[keyColumn];
      const bKey = b.row[keyColumn];
      const aId = typeof aKey === 'string' ? aKey : String(a.originalIndex);
      const bId = typeof bKey === 'string' ? bKey : String(b.originalIndex);
      const aChecked = (qtyBySource[sourceId]?.[aId] ?? 0) > 0 ? 1 : 0;
      const bChecked = (qtyBySource[sourceId]?.[bId] ?? 0) > 0 ? 1 : 0;
      aVal = aChecked;
      bVal = bChecked;
    } else if (column === 'qty') {
      // Second column: quantity
      const aKey = a.row[keyColumn];
      const bKey = b.row[keyColumn];
      const aId = typeof aKey === 'string' ? aKey : String(a.originalIndex);
      const bId = typeof bKey === 'string' ? bKey : String(b.originalIndex);
      aVal = qtyBySource[sourceId]?.[aId] ?? 0;
      bVal = qtyBySource[sourceId]?.[bId] ?? 0;
    } else {
      // Other columns: from row data
      aVal = a.row[column];
      bVal = b.row[column];
    }
    
    // Handle null/undefined values: treat as "largest" (end for asc, start for desc)
    const aIsEmpty = aVal === null || aVal === undefined || aVal === '';
    const bIsEmpty = bVal === null || bVal === undefined || bVal === '';
    
    if (aIsEmpty && bIsEmpty) {
      // Both empty: maintain original order (stable sort)
      return a.originalIndex - b.originalIndex;
    }
    if (aIsEmpty) {
      return direction === 'asc' ? 1 : -1;
    }
    if (bIsEmpty) {
      return direction === 'asc' ? -1 : 1;
    }
    
    // Compare values based on type
    let compare: number;
    
    // Try to compare as numbers first
    const aNum = typeof aVal === 'number' ? aVal : Number(aVal);
    const bNum = typeof bVal === 'number' ? bVal : Number(bVal);
    
    if (Number.isFinite(aNum) && Number.isFinite(bNum)) {
      compare = aNum - bNum;
    } else {
      // Compare as strings
      const aStr = String(aVal);
      const bStr = String(bVal);
      compare = aStr.localeCompare(bStr, undefined, { numeric: true, sensitivity: 'base' });
    }
    
    // Apply direction
    const result = direction === 'asc' ? compare : -compare;
    
    // If values are equal, maintain original order (stable sort)
    if (result === 0) {
      return a.originalIndex - b.originalIndex;
    }
    
    return result;
  });
  
  return rowsWithIndex.map((item) => item.row);
}

export function ShopRenderer(props: {
  questionId: string;
  shop: ShopConfig;
  lang: string;
  state: Record<string, unknown>;
  disabled?: boolean;
  onSubmit: (payload: { v: 1; purchases: ShopPurchase[]; bundles?: string[]; ignoreWarnings?: boolean }) => void;
}) {
  const { questionId, shop, lang, state, disabled, onSubmit } = props;

  const isProfessionalShop = Boolean((shop as any)?.isProfessional);

  const professionalOptions = useMemo(() => {
    const root = (state as any)?.characterRaw?.professional_gear_options;
    const items = (Array.isArray(root?.items) ? root.items : [])
      .filter((v: unknown) => typeof v === 'string' && v.length > 0) as string[];
    const bundlesRaw = Array.isArray(root?.bundles) ? (root.bundles as unknown[]) : [];
    const bundles: ProfessionalBundle[] = bundlesRaw
      .filter((b) => b && typeof b === 'object' && !Array.isArray(b))
      .map((b) => {
        const bb = b as any;
        const itemsRaw = Array.isArray(bb.items) ? (bb.items as unknown[]) : [];
        const bundleItems: ProfessionalBundleItem[] = itemsRaw
          .filter((it) => it && typeof it === 'object' && !Array.isArray(it))
          .map((it) => {
            const ii = it as any;
            return {
              itemId: typeof ii.itemId === 'string' ? ii.itemId : String(ii.itemId ?? ''),
              quantity: typeof ii.quantity === 'number' ? ii.quantity : Number(ii.quantity),
              sourceId: typeof ii.sourceId === 'string' ? ii.sourceId : String(ii.sourceId ?? ''),
            };
          })
          .filter((it) => it.itemId.length > 0 && it.sourceId.length > 0);

        return {
          bundleId: typeof bb.bundleId === 'string' ? bb.bundleId : String(bb.bundleId ?? ''),
          displayName: bb.displayName,
          items: bundleItems,
        };
      })
      .filter((b) => b.bundleId.length > 0 && b.items.length > 0);

    return { items, bundles };
  }, [state]);

  const professionalFreeItemIds = useMemo(() => new Set(professionalOptions.items), [professionalOptions.items]);

  const [bundleCheckedById, setBundleCheckedById] = useState<Record<string, boolean>>({});
  const selectedBundleIds = useMemo(() => {
    if (!isProfessionalShop) return [];
    return Object.entries(bundleCheckedById)
      .filter(([, v]) => v)
      .map(([k]) => k);
  }, [bundleCheckedById, isProfessionalShop]);

  // Prune removed bundles to avoid stale selections
  useEffect(() => {
    if (!isProfessionalShop) return;
    const allowed = new Set(professionalOptions.bundles.map((b) => b.bundleId));
    setBundleCheckedById((prev) => {
      const next: Record<string, boolean> = {};
      for (const [k, v] of Object.entries(prev)) {
        if (allowed.has(k)) next[k] = v;
      }
      return next;
    });
  }, [isProfessionalShop, professionalOptions.bundles]);

  const [expanded, setExpanded] = useState<Record<string, boolean>>({});
  const [expandedGroup, setExpandedGroup] = useState<Record<string, boolean>>({});
  // Единая структура для хранения всех товаров
  const [allItemsBySource, setAllItemsBySource] = useState<Record<string, {
    groups?: Array<{ value: string; count: number }>;
    rowsByGroup?: Record<string, Record<string, unknown>[]>;
    rows?: Record<string, unknown>[];
  }>>({});
  const [loadingAllItems, setLoadingAllItems] = useState(true);
  const [loadErrorAllItems, setLoadErrorAllItems] = useState<string | null>(null);
  // Обратная совместимость: используем allItemsBySource для заполнения старых состояний
  const groupsBySource = useMemo(() => {
    const result: Record<string, { value: string; count: number }[]> = {};
    for (const [sourceId, data] of Object.entries(allItemsBySource)) {
      if (data.groups) {
        result[sourceId] = data.groups;
      }
    }
    return result;
  }, [allItemsBySource]);
  const rowsBySource = useMemo(() => {
    const result: Record<string, Record<string, unknown>[]> = {};
    for (const [sourceId, data] of Object.entries(allItemsBySource)) {
      if (data.rows && !data.groups) {
        result[sourceId] = data.rows;
      }
    }
    return result;
  }, [allItemsBySource]);
  const rowsBySourceGroup = useMemo(() => {
    const result: Record<string, Record<string, Record<string, unknown>[]>> = {};
    for (const [sourceId, data] of Object.entries(allItemsBySource)) {
      if (data.rowsByGroup) {
        result[sourceId] = data.rowsByGroup;
      }
    }
    return result;
  }, [allItemsBySource]);
  const [qtyBySource, setQtyBySource] = useState<Record<string, Record<string, number>>>({});
  const qtyBySourceForCalculations = qtyBySource;
  const [sortBySource, setSortBySource] = useState<Record<string, { column: string | null; direction: 'asc' | 'desc' }>>({});
  const [ignoreWarnings, setIgnoreWarnings] = useState(false);
  const budgetSummaryRef = useRef<HTMLDivElement>(null);

  // Get all budgets, defaulting to old format for backward compatibility
  const budgets = useMemo(() => {
    if (shop.budgets && Array.isArray(shop.budgets) && shop.budgets.length > 0) {
      return shop.budgets;
    }
    // Fallback to old format
    return [{
      id: 'crowns',
      type: 'money' as const,
      source: 'characterRaw.money.crowns',
      priority: 0,
      is_default: true,
      name: 'Crowns',
    }];
  }, [shop.budgets]);

  // Check if item is covered by budget
  const isItemCoveredByBudget = useCallback((budget: ShopBudgetConfig, sourceId: string, itemId: string): boolean => {
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
      // Check sources (support both string[] and {ids,cost}[] formats)
      if (coverage.sources && Array.isArray(coverage.sources)) {
        for (const sourceItem of coverage.sources) {
          if (typeof sourceItem === 'string') {
            if (sourceItem === sourceId) return true;
          } else if (sourceItem?.ids && Array.isArray(sourceItem.ids) && sourceItem.ids.includes(sourceId)) {
            return true;
          }
        }
      }
      // Check items (support both string[] and {ids,cost}[] formats)
      if (coverage.items && Array.isArray(coverage.items)) {
        for (const item of coverage.items) {
          if (typeof item === 'string') {
            if (item === itemId) return true;
          } else if (item?.ids && Array.isArray(item.ids) && item.ids.includes(itemId)) {
            return true;
          }
        }
      }
      // If coverage exists but item not found, not covered
      if (coverage.sources || coverage.items) return false;
      return true; // Empty coverage = covers everything
    }
  }, []);

  // Calculate budget usage
  const budgetUsage = useMemo(() => {
    const usage: Record<string, { initial: number; spent: number; remaining: number }> = {};
    
    // Initialize budgets - always include default budgets, even if initial is 0
    // For non-default budgets, only initialize if source exists in state
    for (const budget of budgets) {
      // Check if source exists in state (for non-default budgets)
      if (!budget.is_default) {
        const sourceValue = getAtPath(state, budget.source);
        // If source doesn't exist (undefined), skip this budget
        if (sourceValue === undefined) {
          continue;
        }
      }
      
      const initial = clampInt(toNumber(getAtPath(state, budget.source), 0));
      if (initial > 0 || budget.is_default) {
        usage[budget.id] = { initial, spent: 0, remaining: initial };
      }
    }

    // Calculate spent amounts
    for (const source of shop.sources) {
      const flatRows = (() => {
        if (rowsBySource[source.id]) return rowsBySource[source.id] ?? [];
        const groups = rowsBySourceGroup[source.id] ?? {};
        return Object.values(groups).flat();
      })();
      const byId = new Map<string, Record<string, unknown>>();
      for (const r of flatRows) {
        const key = r[source.keyColumn];
        if (typeof key === "string") byId.set(key, r);
      }
      
      const selected = qtyBySourceForCalculations[source.id] ?? {};
      for (const [itemId, qty] of Object.entries(selected)) {
        if (qty <= 0) continue;
        const row = byId.get(itemId);
        const price = row ? toNumber(row.price, 0) : 0;
        
        // Find applicable budgets for this item, sorted by priority (higher first)
        const applicableBudgets = budgets
          .filter(b => isItemCoveredByBudget(b, source.id, itemId))
          .sort((a, b) => (b.priority ?? 0) - (a.priority ?? 0));
        
        if (applicableBudgets.length === 0) continue;
        
        // For money budgets: distribute cost across budgets by priority
        // For tokens: spend tokens per unit
        let remainingCost = price * qty;
        let remainingQty = qty;
        
        const moneyBudgets = applicableBudgets.filter((b) => b.type === 'money');
        const lastMoneyBudgetId = moneyBudgets.length > 0 ? moneyBudgets[moneyBudgets.length - 1]!.id : null;

        for (const budget of applicableBudgets) {
          // Ensure budget is initialized in usage
          if (!usage[budget.id]) {
            const initial = clampInt(toNumber(getAtPath(state, budget.source), 0));
            usage[budget.id] = { initial, spent: 0, remaining: initial };
          }
          
          if (budget.type === 'money') {
            if (remainingCost <= 0) break;
            
            const budgetRemaining = usage[budget.id].remaining;
            const isLastMoney = lastMoneyBudgetId === budget.id;
            // If this is not the last money budget, do not go negative here: spill to less priority budgets instead
            const available = isLastMoney ? budgetRemaining : Math.max(0, budgetRemaining);
            const toSpend = isLastMoney
              ? remainingCost // last budget may go negative
              : Math.min(remainingCost, available);
            
            // Spend from this budget (allows going negative)
            usage[budget.id].spent += toSpend;
            usage[budget.id].remaining -= toSpend;
            remainingCost -= toSpend; // Reduce remaining cost
            
            // If is_with_default and not default budget, also spend from default
            if (budget.is_with_default && !budget.is_default) {
              const defaultBudget = budgets.find(b => b.is_default);
              if (defaultBudget) {
                if (!usage[defaultBudget.id]) {
                  const initial = clampInt(toNumber(getAtPath(state, defaultBudget.source), 0));
                  usage[defaultBudget.id] = { initial, spent: 0, remaining: initial };
                }
                // Also spend from default budget (same amount as from this budget)
                const defaultRemaining = usage[defaultBudget.id].remaining;
                const defaultSpend = defaultRemaining >= 0 
                  ? Math.min(toSpend, defaultRemaining)
                  : toSpend;
                usage[defaultBudget.id].spent += defaultSpend;
                usage[defaultBudget.id].remaining -= defaultSpend;
              }
            }
          } else {
            // tokens
            if (remainingQty <= 0) break;
            
            const coverage = budget.coverage as ShopBudgetCoverageTokens | undefined;
            let costPerUnit = 1;
            
            // Find cost for this item
            if (coverage?.items) {
              for (const item of coverage.items) {
                if (typeof item === 'string') continue;
                if (item?.ids && item.ids.includes(itemId)) {
                  costPerUnit = item.cost ?? 1;
                  break;
                }
              }
            }
            if (coverage?.sources && costPerUnit === 1) {
              for (const sourceItem of coverage.sources) {
                if (typeof sourceItem === 'string') continue;
                if (sourceItem?.ids && sourceItem.ids.includes(source.id)) {
                  costPerUnit = sourceItem.cost ?? 1;
                  break;
                }
              }
            }
            
            const tokensNeeded = costPerUnit * remainingQty;
            // Always add to spent and subtract from remaining (allows negative)
            usage[budget.id].spent += tokensNeeded;
            usage[budget.id].remaining -= tokensNeeded;
            remainingQty = 0;
            
            // If is_with_money, also spend money
            if (budget.is_with_money && remainingCost > 0) {
              const moneyBudgets = budgets
                .filter(b => b.type === 'money' && isItemCoveredByBudget(b, source.id, itemId))
                .sort((a, b) => (b.priority ?? 0) - (a.priority ?? 0));
              for (const moneyBudget of moneyBudgets) {
                if (remainingCost <= 0) break;
                if (!usage[moneyBudget.id]) {
                  const initial = clampInt(toNumber(getAtPath(state, moneyBudget.source), 0));
                  usage[moneyBudget.id] = { initial, spent: 0, remaining: initial };
                }
                usage[moneyBudget.id].spent += remainingCost;
                usage[moneyBudget.id].remaining -= remainingCost;
                remainingCost = 0;
              }
            }
          }
        }
      }
    }
    
    // Professional bundles: 1 token per selected bundle (not per item/quantity)
    if (isProfessionalShop && selectedBundleIds.length > 0) {
      const tokenBudgets = budgets
        .filter((b) => b.type === 'tokens')
        .sort((a, b) => (b.priority ?? 0) - (a.priority ?? 0));
      if (tokenBudgets.length > 0) {
        const b = tokenBudgets[0]!;
        if (!usage[b.id]) {
          const initial = clampInt(toNumber(getAtPath(state, b.source), 0));
          usage[b.id] = { initial, spent: 0, remaining: initial };
        }
        usage[b.id].spent += selectedBundleIds.length;
        usage[b.id].remaining -= selectedBundleIds.length;
      }
    }

    return usage;
  }, [budgets, shop.sources, qtyBySourceForCalculations, rowsBySource, rowsBySourceGroup, state, isItemCoveredByBudget, isProfessionalShop, selectedBundleIds]);

  // Check if any budget is exceeded
  const hasExceededBudgets = useMemo(() => {
    return Object.values(budgetUsage).some(b => b.remaining < 0);
  }, [budgetUsage]);

  const hasUnmetRequiredBudgets = useMemo(() => {
    const required = budgets.filter((b) => b.is_required);
    if (required.length === 0) return false;
    return required.some((b) => {
      const u = budgetUsage[b.id];
      // Missing budget in usage: treat as unmet
      if (!u) return true;
      // Under-spent: remaining > 0
      return u.remaining > 0;
    });
  }, [budgets, budgetUsage]);

  const hasWarnings = hasExceededBudgets || hasUnmetRequiredBudgets;
  const canSubmit = (!hasWarnings || ignoreWarnings) && !disabled;

  const toggleExpanded = useCallback((sourceId: string) => {
    setExpanded((prev) => ({ ...prev, [sourceId]: !prev[sourceId] }));
  }, []);

  const resolvedAllowedDlcs = useMemo(() => {
    const fromMeta = (Array.isArray((shop as any)?.allowedDlcs) ? ((shop as any).allowedDlcs as unknown[]) : [])
      .filter((v) => typeof v === "string" && v.length > 0) as string[];
    const fromState = (Array.isArray((state as any)?.dlcs) ? ((state as any).dlcs as unknown[]) : [])
      .filter((v) => typeof v === "string" && v.length > 0) as string[];
    const base = fromMeta.length > 0 ? fromMeta : fromState;
    // core всегда разрешён
    return Array.from(new Set(["core", ...base]));
  }, [shop, state]);

  async function fetchJsonOrThrow(response: Response): Promise<any> {
    if (response.ok) return response.json();
    const bodyText = await response.text();
    let detail = bodyText?.trim() ?? "";
    try {
      const parsed = JSON.parse(bodyText) as any;
      if (parsed && typeof parsed === "object" && typeof parsed.error === "string") {
        detail = parsed.error;
      }
    } catch {
      // ignore
    }
    throw new Error(`HTTP ${response.status}${detail ? `: ${detail}` : ""}`);
  }

  // Загружаем все товары сразу при монтировании компонента
  const professionalItemsKey = useMemo(() => {
    if (!isProfessionalShop) return '';
    const bundleSignature = professionalOptions.bundles.map((b) => ({
      bundleId: b.bundleId,
      items: b.items.map((it) => ({ sourceId: it.sourceId, itemId: it.itemId, quantity: it.quantity })),
    }));
    return JSON.stringify({ items: professionalOptions.items, bundles: bundleSignature });
  }, [isProfessionalShop, professionalOptions]);

  const prefetchKey = useMemo(
    () => `${questionId}::${lang}::${resolvedAllowedDlcs.join(",")}::${professionalItemsKey}`,
    [questionId, lang, resolvedAllowedDlcs, professionalItemsKey],
  );
  const prefetchRef = useRef<string | null>(null);

  // Reset local UI state when shop node changes (prevents leaking selections between 091 and 092)
  useEffect(() => {
    setExpanded(isProfessionalShop
      ? Object.fromEntries(shop.sources.map((s) => [s.id, true]))
      : {});
    setExpandedGroup({});
    setQtyBySource({});
    setSortBySource({});
    setIgnoreWarnings(false);
    setBundleCheckedById({});
    setAllItemsBySource({});
    setLoadingAllItems(true);
    setLoadErrorAllItems(null);
    prefetchRef.current = null;
  }, [questionId, isProfessionalShop, shop.sources]);

  useEffect(() => {
    if (prefetchRef.current === prefetchKey) return;
    prefetchRef.current = prefetchKey;
    
    setLoadingAllItems(true);
    setLoadErrorAllItems(null);
    
    fetch(`${API_URL}/shop/allItems`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ questionId, lang, allowedDlcs: resolvedAllowedDlcs, state }),
    })
      .then(fetchJsonOrThrow)
      .then((data) => {
        setAllItemsBySource(data);
        setLoadingAllItems(false);
      })
      .catch((e) => {
        setLoadErrorAllItems(e instanceof Error ? e.message : String(e));
        setLoadingAllItems(false);
      });
  }, [prefetchKey, questionId, lang, resolvedAllowedDlcs, state]);

  const visibleSources = useMemo(() => {
    return shop.sources.filter((source) => {
      // If user already selected something in this source — keep it visible
      const selected = qtyBySource[source.id] ?? {};
      if (Object.values(selected).some((qty) => (qty ?? 0) > 0)) {
        return true;
      }

      const sourceData = allItemsBySource[source.id];
      if (!sourceData) {
        // Not loaded yet — keep it for now (will disappear once loaded if empty)
        return true;
      }

      if (isProfessionalShop) {
        const flatRows = sourceData.rows
          ?? (sourceData.rowsByGroup ? Object.values(sourceData.rowsByGroup).flat() : []);
        return flatRows.some((row) => {
          const key = (row as any)?.[source.keyColumn];
          const itemId = typeof key === 'string' ? key : String(key ?? '');
          return professionalFreeItemIds.has(itemId);
        });
      }

      if (sourceData.groups) {
        return (sourceData.groups.length ?? 0) > 0;
      }
      if (sourceData.rows) {
        return (sourceData.rows.length ?? 0) > 0;
      }

      return false;
    });
  }, [shop.sources, qtyBySource, allItemsBySource, isProfessionalShop, professionalFreeItemIds]);

  // Товары уже загружены, эта функция больше не нужна, но оставляем для совместимости
  const ensureLoadedGroupRows = useCallback(
    async (sourceId: string, groupValue: string) => {
      // Товары уже загружены в allItemsBySource, ничего не делаем
      return;
    },
    [],
  );

  const renderCell = useCallback((value: unknown) => {
    const text = value === null || value === undefined ? "" : String(value);
    if (typeof value === "string" && value.includes("\n")) {
      // Preserve newlines without using innerHTML
      return <span style={{ whiteSpace: "pre-line" }}>{text}</span>;
    }
    // Also preserve newlines for non-string values that stringify with \n
    if (text.includes("\n")) {
      return <span style={{ whiteSpace: "pre-line" }}>{text}</span>;
    }
    return text;
  }, []);

  const setQty = useCallback((sourceId: string, itemId: string, qty: number) => {
    const clean = isProfessionalShop ? (qty > 0 ? 1 : 0) : clampInt(qty);
    setQtyBySource((prev) => {
      const prevSource = prev[sourceId] ?? {};
      const nextSource = { ...prevSource };
      if (clean <= 0) {
        delete nextSource[itemId];
      } else {
        nextSource[itemId] = clean;
      }
      return { ...prev, [sourceId]: nextSource };
    });
  }, [isProfessionalShop]);

  const toggleChecked = useCallback(
    (sourceId: string, itemId: string) => {
      const current = qtyBySource[sourceId]?.[itemId] ?? 0;
      setQty(sourceId, itemId, current > 0 ? 0 : 1);
    },
    [qtyBySource, setQty],
  );

  const handleSort = useCallback(
    (sourceId: string, column: SortColumn) => {
      setSortBySource((prev) => {
        const current = prev[sourceId];
        if (current?.column === column) {
          // Toggle direction if same column
          return {
            ...prev,
            [sourceId]: { column, direction: current.direction === 'asc' ? 'desc' : 'asc' },
          };
        } else {
          // New column: start with ascending
          return {
            ...prev,
            [sourceId]: { column, direction: 'asc' },
          };
        }
      });
    },
    [],
  );

  const purchases = useMemo(() => {
    const out: ShopPurchase[] = [];
    for (const source of shop.sources) {
      const map = qtyBySourceForCalculations[source.id] ?? {};
      for (const [id, qty] of Object.entries(map)) {
        if (qty > 0) out.push({ sourceId: source.id, id, qty });
      }
    }
    return out;
  }, [qtyBySourceForCalculations, shop.sources]);

  // Check for items with price 0
  const hasPriceZeroItems = useMemo(() => {
    for (const source of shop.sources) {
      const flatRows = (() => {
        if (rowsBySource[source.id]) return rowsBySource[source.id] ?? [];
        const groups = rowsBySourceGroup[source.id] ?? {};
        return Object.values(groups).flat();
      })();
      const byId = new Map<string, Record<string, unknown>>();
      for (const r of flatRows) {
        const key = r[source.keyColumn];
        if (typeof key === "string") byId.set(key, r);
      }
      const selected = qtyBySourceForCalculations[source.id] ?? {};
      for (const [id, qty] of Object.entries(selected)) {
        if (qty <= 0) continue;
        const row = byId.get(id);
        const price = row ? toNumber(row.price, 0) : 0;
        if (price === 0) return true;
      }
    }
    return false;
  }, [qtyBySourceForCalculations, rowsBySource, rowsBySourceGroup, shop.sources]);

  const handleSubmit = useCallback(() => {
    if (hasWarnings && !ignoreWarnings) {
      // Scroll to top to show warning
      budgetSummaryRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' });
      return;
    }
    const bundles = isProfessionalShop ? selectedBundleIds : [];
    onSubmit({
      v: 1,
      purchases,
      bundles: bundles.length > 0 ? bundles : undefined,
      ignoreWarnings: ignoreWarnings || undefined,
    });
  }, [hasWarnings, ignoreWarnings, purchases, onSubmit, isProfessionalShop, selectedBundleIds]);

  // Helper to get sorted rows for a source
  const getSortedRows = useCallback(
    (
      rows: Record<string, unknown>[],
      sourceId: string,
      keyColumn: string,
      columns: ShopSourceColumn[],
    ): Record<string, unknown>[] => {
      const sortConfig = sortBySource[sourceId];
      if (!sortConfig || !sortConfig.column) {
        return rows;
      }
      const column: SortColumn = (isProfessionalShop && sortConfig.column === 'qty')
        ? 'checkbox'
        : sortConfig.column;
      return sortRows(
        rows,
        column,
        sortConfig.direction,
        sourceId,
        keyColumn,
        qtyBySourceForCalculations,
        columns,
      );
    },
    [sortBySource, qtyBySourceForCalculations, isProfessionalShop],
  );

  // Get visible budgets (non-zero or default, or if they have any usage)
  // Also filter out budgets whose source doesn't exist in state (except default)
  const visibleBudgets = useMemo(() => {
    return budgets.filter(b => {
      // Check if source exists in state (for non-default budgets)
      if (!b.is_default) {
        const sourceValue = getAtPath(state, b.source);
        // If source doesn't exist (undefined), don't show this budget
        if (sourceValue === undefined) {
          return false;
        }
      }
      
      const usage = budgetUsage[b.id];
      // Show if: has usage and (initial > 0 OR is_default OR has spent > 0)
      return usage && (usage.initial > 0 || b.is_default || usage.spent > 0);
    }).sort((a, b) => (b.priority ?? 0) - (a.priority ?? 0));
  }, [budgets, budgetUsage, state]);

  const sourcesById = useMemo(() => {
    const out: Record<string, ShopSourceConfig> = {};
    for (const s of shop.sources) out[s.id] = s;
    return out;
  }, [shop.sources]);

  const rowsIndexBySourceId = useMemo(() => {
    const out: Record<string, Map<string, Record<string, unknown>>> = {};
    for (const source of shop.sources) {
      const flatRows = (() => {
        if (rowsBySource[source.id]) return rowsBySource[source.id] ?? [];
        const groups = rowsBySourceGroup[source.id] ?? {};
        return Object.values(groups).flat();
      })();
      const byId = new Map<string, Record<string, unknown>>();
      for (const r of flatRows) {
        const key = (r as any)[source.keyColumn];
        const itemId = typeof key === 'string' ? key : String(key ?? '');
        if (itemId) byId.set(itemId, r);
      }
      out[source.id] = byId;
    }
    return out;
  }, [shop.sources, rowsBySource, rowsBySourceGroup]);

  return (
    <div className="shop-node">
      <div className="survey-actions" style={{ marginBottom: '16px' }}>
        <button
          type="button"
          className="btn btn-primary"
          disabled={!canSubmit}
          onClick={handleSubmit}
        >
          Continue
        </button>
        {hasWarnings && (
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginLeft: '12px' }}>
            <input
              type="checkbox"
              id="ignore-warnings"
              checked={ignoreWarnings}
              onChange={(e) => setIgnoreWarnings(e.target.checked)}
            />
            <label htmlFor="ignore-warnings" style={{ cursor: 'pointer' }}>
              {lang === 'ru' ? 'Игнорировать предупреждения' : 'Ignore warnings'}
            </label>
          </div>
        )}
      </div>

      <div className="shop-summary" ref={budgetSummaryRef}>
        {(shop.warningPriceZero && hasPriceZeroItems) && (
          <div className="shop-warning" style={{ 
            marginBottom: '12px', 
            padding: '8px 10px', 
            fontSize: '12px',
            color: '#ffdd63',
            background: 'rgba(242,199,68,0.12)',
            border: '1px solid rgba(242,199,68,0.35)',
            borderRadius: '10px'
          }}>
            {shop.warningPriceZero}
          </div>
        )}

        {hasExceededBudgets && (
          <div className="shop-error" style={{ marginBottom: '12px' }}>
            {lang === 'ru' ? 'Один или несколько бюджетов перевыполнены' : 'One or more budgets are exceeded'}
          </div>
        )}

        {hasUnmetRequiredBudgets && (
          <div className="shop-error" style={{ marginBottom: '12px' }}>
            {lang === 'ru'
              ? 'Один или несколько бюджетов, обязательных к выполнению, недовыполнены'
              : 'One or more required budgets are not fully spent'}
          </div>
        )}
        
        {visibleBudgets.map((budget) => {
          const usage = budgetUsage[budget.id];
          if (!usage) return null;
          const isExceeded = usage.remaining < 0;
          const isRequiredUnmet = Boolean(budget.is_required) && usage.remaining > 0;
          const isBad = isExceeded || isRequiredUnmet;
          return (
            <div key={budget.id} style={{ marginBottom: '12px' }}>
              <div style={{ marginBottom: '4px', fontWeight: 'bold' }}>
                {budget.name}
              </div>
              <div className="shop-summary-row">
                <div className="shop-summary-item">
                  <span className="shop-summary-label">INITIAL</span>
                  <span className="shop-summary-value">{usage.initial}</span>
                </div>
                <div className="shop-summary-item">
                  <span className="shop-summary-label">SPENT</span>
                  <span className={`shop-summary-value ${isBad ? "shop-bad" : ""}`}>
                    {usage.spent}
                  </span>
                </div>
                <div className="shop-summary-item">
                  <span className="shop-summary-label">REMAINING</span>
                  <span className={`shop-summary-value ${isBad ? "shop-bad" : ""}`}>
                    {usage.remaining}
                  </span>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {loadingAllItems && (
        <div className="shop-muted" style={{ marginBottom: '16px' }}>
          Loading all items...
        </div>
      )}
      {loadErrorAllItems && (
        <div className="shop-error" style={{ marginBottom: '16px' }}>
          Failed to load items: {loadErrorAllItems}
        </div>
      )}

      <div className="shop-sources">
        {visibleSources.map((source) => {
          const isOpen = Boolean(expanded[source.id]);
          const sourceData = allItemsBySource[source.id];
          const allFlatRows = sourceData?.rows
            ?? (sourceData?.rowsByGroup ? Object.values(sourceData.rowsByGroup).flat() : []);
          const rawRows = isProfessionalShop
            ? allFlatRows.filter((row) => {
              const key = (row as any)?.[source.keyColumn];
              const itemId = typeof key === 'string' ? key : String(key ?? '');
              return professionalFreeItemIds.has(itemId);
            })
            : (sourceData?.rows ?? []);
          const groups = isProfessionalShop ? null : (sourceData?.groups ?? null);
          const selected = qtyBySource[source.id] ?? {};
          const visibleColumns = (groups && source.groupColumn)
            ? source.columns.filter((c) => c.field !== source.groupColumn)
            : source.columns;
          const sortConfig = sortBySource[source.id];
          const rows = getSortedRows(rawRows, source.id, source.keyColumn, source.columns);
          const showQtyColumn = !isProfessionalShop;

          return (
            <div key={source.id} className="shop-source">
              <button
                type="button"
                className="shop-source-header"
                onClick={() => {
                  toggleExpanded(source.id);
                }}
                disabled={disabled}
              >
                <span className="shop-source-title">{source.title}</span>
                <span className="shop-source-meta">
                  {Object.keys(selected).length > 0 ? `${Object.keys(selected).length} selected` : ""}
                </span>
                <span className="shop-source-chevron">{isOpen ? "▾" : "▸"}</span>
              </button>

              {isOpen && (
                <div className="shop-source-body">
                  {groups && (
                    <div className="shop-sources">
                      {groups.map((g) => {
                        const gKey = `${source.id}::${g.value}`;
                        const gOpen = Boolean(expandedGroup[gKey]);
                        return (
                          <div key={gKey} className="shop-source">
                            <button
                              type="button"
                              className="shop-source-header"
                              onClick={() => {
                                setExpandedGroup((prev) => ({ ...prev, [gKey]: !prev[gKey] }));
                              }}
                              disabled={disabled}
                            >
                              <span className="shop-source-title">
                                {g.value} {Number.isFinite(g.count) ? `(${g.count})` : ""}
                              </span>
                              <span className="shop-source-chevron">{gOpen ? "▾" : "▸"}</span>
                            </button>
                            {gOpen && (() => {
                              const gRows = rowsBySourceGroup[source.id]?.[g.value] ?? [];
                              const sortedGRows = getSortedRows(gRows, source.id, source.keyColumn, source.columns);
                                  return (
                                    <div style={{ overflowX: "auto" }}>
                                      <table className="survey-table shop-table">
                                        <thead>
                                          <tr>
                                            <th
                                              style={{ width: 48, cursor: 'pointer' }}
                                              onClick={() => handleSort(source.id, 'checkbox')}
                                              className="shop-sortable-header"
                                            >
                                              <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                                                ✓
                                                {sortConfig?.column === 'checkbox' && (
                                                  <span>{sortConfig.direction === 'asc' ? '↑' : '↓'}</span>
                                                )}
                                              </span>
                                            </th>
                                            <th
                                              style={{ width: 110, cursor: 'pointer' }}
                                              onClick={() => handleSort(source.id, 'qty')}
                                              className="shop-sortable-header"
                                            >
                                              <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                                                Qty
                                                {sortConfig?.column === 'qty' && (
                                                  <span>{sortConfig.direction === 'asc' ? '↑' : '↓'}</span>
                                                )}
                                              </span>
                                            </th>
                                            {visibleColumns.map((col) => {
                                              const isSorted = sortConfig?.column === col.field;
                                              return (
                                                <th
                                                  key={col.field}
                                                  style={{ cursor: 'pointer' }}
                                                  onClick={() => handleSort(source.id, col.field)}
                                                  className="shop-sortable-header"
                                                >
                                                  <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                                                    {col.label ?? col.field}
                                                    {isSorted && (
                                                      <span>{sortConfig.direction === 'asc' ? '↑' : '↓'}</span>
                                                    )}
                                                  </span>
                                                </th>
                                              );
                                            })}
                                          </tr>
                                        </thead>
                                        <tbody>
                                          {sortedGRows.map((row, idx) => {
                                          const key = row[source.keyColumn];
                                          const itemId = typeof key === "string" ? key : String(idx);
                                          const qty = selected[itemId] ?? 0;
                                          const checked = qty > 0;
                                          const tooltip = source.tooltipField
                                            ? String((row as any)[source.tooltipField] ?? "")
                                            : "";
                                          return (
                                            <tr key={itemId} title={tooltip}>
                                              <td>
                                                <input
                                                  type="checkbox"
                                                  checked={checked}
                                                  disabled={disabled}
                                                  onChange={() => toggleChecked(source.id, itemId)}
                                                />
                                              </td>
                                              <td>
                                                <input
                                                  type="number"
                                                  min={0}
                                                  step={1}
                                                  value={qty}
                                                  disabled={disabled || !checked}
                                                  onChange={(e) => setQty(source.id, itemId, Number(e.target.value))}
                                                  className="shop-qty-input"
                                                />
                                              </td>
                                              {visibleColumns.map((col) => (
                                                <td key={col.field}>{renderCell((row as any)[col.field])}</td>
                                              ))}
                                            </tr>
                                          );
                                        })}
                                      </tbody>
                                    </table>
                                  </div>
                                  );
                            })()}
                          </div>
                        );
                      })}
                    </div>
                  )}

                  {!groups && (
                    <div style={{ overflowX: "auto" }}>
                      <table className="survey-table shop-table">
                        <thead>
                          <tr>
                            <th
                              style={{ width: 48, cursor: 'pointer' }}
                              onClick={() => handleSort(source.id, 'checkbox')}
                              className="shop-sortable-header"
                            >
                              <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                                ✓
                                {sortConfig?.column === 'checkbox' && (
                                  <span>{sortConfig.direction === 'asc' ? '↑' : '↓'}</span>
                                )}
                              </span>
                            </th>
                            {showQtyColumn && (
                              <th
                                style={{ width: 110, cursor: 'pointer' }}
                                onClick={() => handleSort(source.id, 'qty')}
                                className="shop-sortable-header"
                              >
                                <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                                  Qty
                                  {sortConfig?.column === 'qty' && (
                                    <span>{sortConfig.direction === 'asc' ? '↑' : '↓'}</span>
                                  )}
                                </span>
                              </th>
                            )}
                            {source.columns.map((col) => {
                              const isSorted = sortConfig?.column === col.field;
                              return (
                                <th
                                  key={col.field}
                                  style={{ cursor: 'pointer' }}
                                  onClick={() => handleSort(source.id, col.field)}
                                  className="shop-sortable-header"
                                >
                                  <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                                    {col.label ?? col.field}
                                    {isSorted && (
                                      <span>{sortConfig.direction === 'asc' ? '↑' : '↓'}</span>
                                    )}
                                  </span>
                                </th>
                              );
                            })}
                          </tr>
                        </thead>
                        <tbody>
                          {rows.map((row, idx) => {
                            const key = row[source.keyColumn];
                            const itemId = typeof key === "string" ? key : String(idx);
                            const qty = selected[itemId] ?? 0;
                            const checked = qty > 0;
                            const tooltip = source.tooltipField ? String((row as any)[source.tooltipField] ?? "") : "";
                            return (
                              <tr key={itemId} title={tooltip}>
                                <td>
                                  <input
                                    type="checkbox"
                                    checked={checked}
                                    disabled={disabled}
                                    onChange={() => toggleChecked(source.id, itemId)}
                                  />
                                </td>
                                {showQtyColumn && (
                                  <td>
                                    <input
                                      type="number"
                                      min={0}
                                      step={1}
                                      value={qty}
                                      disabled={disabled || !checked}
                                      onChange={(e) => setQty(source.id, itemId, Number(e.target.value))}
                                      className="shop-qty-input"
                                    />
                                  </td>
                                )}
                                {source.columns.map((col) => (
                                  <td key={col.field}>{renderCell((row as any)[col.field])}</td>
                                ))}
                              </tr>
                            );
                          })}
                        </tbody>
                      </table>
                    </div>
                  )}
                </div>
              )}
            </div>
          );
        })}
      </div>

      {isProfessionalShop && professionalOptions.bundles.length > 0 && (
        <div className="shop-sources" style={{ marginTop: '16px' }}>
          <div style={{ fontWeight: 'bold', marginBottom: '8px' }}>
            {lang === 'ru' ? 'Комплекты' : 'Bundles'}
          </div>

          {professionalOptions.bundles.map((bundle) => {
            const checked = Boolean(bundleCheckedById[bundle.bundleId]);
            const displayName = (() => {
              if (typeof bundle.displayName === 'string') return bundle.displayName;
              if (bundle.displayName && typeof bundle.displayName === 'object' && !Array.isArray(bundle.displayName)) {
                const obj = bundle.displayName as any;
                if (typeof obj.i18n_uuid === 'string') return obj.i18n_uuid;
              }
              return bundle.bundleId;
            })();

            const itemsBySource: Record<string, ProfessionalBundleItem[]> = {};
            for (const it of bundle.items) {
              const list = itemsBySource[it.sourceId] ?? [];
              list.push(it);
              itemsBySource[it.sourceId] = list;
            }

            return (
              <div key={bundle.bundleId} className="shop-source">
                <div className="shop-source-header" style={{ cursor: 'default' }}>
                  <span style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <input
                      type="checkbox"
                      checked={checked}
                      disabled={disabled}
                      onChange={(e) =>
                        setBundleCheckedById((prev) => ({ ...prev, [bundle.bundleId]: e.target.checked }))
                      }
                    />
                    <span className="shop-source-title">{displayName}</span>
                  </span>
                </div>

                <div className="shop-source-body">
                  {Object.entries(itemsBySource).map(([sourceId, bundleItems]) => {
                    const source = sourcesById[sourceId];
                    const byId = rowsIndexBySourceId[sourceId];
                    if (!source || !byId) return null;

                    return (
                      <div key={`${bundle.bundleId}::${sourceId}`} style={{ marginBottom: '12px' }}>
                        <div style={{ marginBottom: '6px', fontWeight: 600 }}>
                          {source.title}
                        </div>
                        <div style={{ overflowX: 'auto' }}>
                          <table className="survey-table shop-table">
                            <thead>
                              <tr>
                                <th style={{ width: 110 }}>
                                  {lang === 'ru' ? 'Кол-во' : 'Qty'}
                                </th>
                                {source.columns.map((col) => (
                                  <th key={col.field}>{col.label ?? col.field}</th>
                                ))}
                              </tr>
                            </thead>
                            <tbody>
                              {bundleItems.map((it, idx) => {
                                const qty = clampInt(toNumber(it.quantity, 0));
                                const row = byId.get(it.itemId) ?? { [source.keyColumn]: it.itemId };
                                const tooltip = source.tooltipField ? String((row as any)[source.tooltipField] ?? '') : '';
                                return (
                                  <tr key={`${it.itemId}::${idx}`} title={tooltip}>
                                    <td>{qty}</td>
                                    {source.columns.map((col) => (
                                      <td key={col.field}>{renderCell((row as any)[col.field])}</td>
                                    ))}
                                  </tr>
                                );
                              })}
                            </tbody>
                          </table>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}


