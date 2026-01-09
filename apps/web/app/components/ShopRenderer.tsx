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
  budgets?: ShopBudgetConfig[];
  warningPriceZero?: string; // resolved i18n text
  allowedDlcs: string[];
  sources: ShopSourceConfig[];
};

type ShopPurchase = { sourceId: string; id: string; qty: number };

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
  onSubmit: (payload: { v: 1; purchases: ShopPurchase[] }) => void;
}) {
  const { questionId, shop, lang, state, disabled, onSubmit } = props;

  const [expanded, setExpanded] = useState<Record<string, boolean>>({});
  const [expandedGroup, setExpandedGroup] = useState<Record<string, boolean>>({});
  const [groupsBySource, setGroupsBySource] = useState<Record<string, { value: string; count: number }[]>>({});
  const [rowsBySource, setRowsBySource] = useState<Record<string, Record<string, unknown>[]>>({});
  const [rowsBySourceGroup, setRowsBySourceGroup] = useState<Record<string, Record<string, Record<string, unknown>[]>>>({});
  const [loadingSource, setLoadingSource] = useState<Record<string, boolean>>({});
  const [loadErrorSource, setLoadErrorSource] = useState<Record<string, string | null>>({});
  const [loadingGroup, setLoadingGroup] = useState<Record<string, boolean>>({});
  const [loadErrorGroup, setLoadErrorGroup] = useState<Record<string, string | null>>({});
  const [qtyBySource, setQtyBySource] = useState<Record<string, Record<string, number>>>({});
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
      
      const selected = qtyBySource[source.id] ?? {};
      for (const [itemId, qty] of Object.entries(selected)) {
        if (qty <= 0) continue;
        const row = byId.get(itemId);
        const price = row ? toNumber(row.price, 0) : 0;
        
        // Find applicable budgets for this item, sorted by priority
        const applicableBudgets = budgets
          .filter(b => isItemCoveredByBudget(b, source.id, itemId))
          .sort((a, b) => (a.priority ?? 999) - (b.priority ?? 999));
        
        if (applicableBudgets.length === 0) continue;
        
        // For money budgets: distribute cost across budgets by priority
        // For tokens: spend tokens per unit
        let remainingCost = price * qty;
        let remainingQty = qty;
        
        for (const budget of applicableBudgets) {
          // Ensure budget is initialized in usage
          if (!usage[budget.id]) {
            const initial = clampInt(toNumber(getAtPath(state, budget.source), 0));
            usage[budget.id] = { initial, spent: 0, remaining: initial };
          }
          
          if (budget.type === 'money') {
            if (remainingCost <= 0) break;
            
            // Calculate how much we can spend from this budget
            // Distribute cost across budgets by priority: spend from this budget what we can, rest goes to next
            const budgetRemaining = usage[budget.id].remaining;
            // Spend as much as possible from this budget (can be all if budget is large enough)
            // If budget is exhausted (0 or negative), we still assign cost to show negative value
            const toSpend = budgetRemaining > 0 
              ? Math.min(remainingCost, budgetRemaining) 
              : remainingCost; // If exhausted or negative, assign all remaining cost to show negative
            
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
                if (item.ids && item.ids.includes(itemId)) {
                  costPerUnit = item.cost ?? 1;
                  break;
                }
              }
            }
            if (coverage?.sources && costPerUnit === 1) {
              for (const sourceItem of coverage.sources) {
                if (sourceItem.ids && sourceItem.ids.includes(source.id)) {
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
                .sort((a, b) => (a.priority ?? 999) - (b.priority ?? 999));
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
    
    return usage;
  }, [budgets, shop.sources, qtyBySource, rowsBySource, rowsBySourceGroup, state, isItemCoveredByBudget]);

  // Check if any budget is exceeded
  const hasExceededBudgets = useMemo(() => {
    return Object.values(budgetUsage).some(b => b.remaining < 0);
  }, [budgetUsage]);

  const canSubmit = (!hasExceededBudgets || ignoreWarnings) && !disabled;

  const toggleExpanded = useCallback((sourceId: string) => {
    setExpanded((prev) => ({ ...prev, [sourceId]: !prev[sourceId] }));
  }, []);

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

  const ensureLoadedSourceRoot = useCallback(
    async (sourceId: string) => {
      if (rowsBySource[sourceId] || groupsBySource[sourceId]) return;
      setLoadingSource((prev) => ({ ...prev, [sourceId]: true }));
      setLoadErrorSource((prev) => ({ ...prev, [sourceId]: null }));
      try {
        const response = await fetch(`${API_URL}/shop/sourceRows`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ questionId, sourceId, lang }),
        });
        const payload = (await fetchJsonOrThrow(response)) as
          | { rows?: Record<string, unknown>[]; groups?: { value: string; count: number }[] }
          | { rows: Record<string, unknown>[] };

        if (Array.isArray((payload as any).groups)) {
          setGroupsBySource((prev) => ({ ...prev, [sourceId]: (payload as any).groups ?? [] }));
        } else {
          setRowsBySource((prev) => ({ ...prev, [sourceId]: (payload as any).rows ?? [] }));
        }
      } catch (e) {
        setLoadErrorSource((prev) => ({
          ...prev,
          [sourceId]: e instanceof Error ? e.message : String(e),
        }));
      } finally {
        setLoadingSource((prev) => ({ ...prev, [sourceId]: false }));
      }
    },
    [questionId, rowsBySource, groupsBySource, lang],
  );

  const ensureLoadedGroupRows = useCallback(
    async (sourceId: string, groupValue: string) => {
      const existing = rowsBySourceGroup[sourceId]?.[groupValue];
      if (existing) return;
      const key = `${sourceId}::${groupValue}`;
      setLoadingGroup((prev) => ({ ...prev, [key]: true }));
      setLoadErrorGroup((prev) => ({ ...prev, [key]: null }));
      try {
        const response = await fetch(`${API_URL}/shop/sourceRows`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ questionId, sourceId, lang, groupValue }),
        });
        const payload = (await fetchJsonOrThrow(response)) as { rows?: Record<string, unknown>[] };
        const rows = payload.rows ?? [];
        setRowsBySourceGroup((prev) => ({
          ...prev,
          [sourceId]: { ...(prev[sourceId] ?? {}), [groupValue]: rows },
        }));
      } catch (e) {
        setLoadErrorGroup((prev) => ({
          ...prev,
          [key]: e instanceof Error ? e.message : String(e),
        }));
      } finally {
        setLoadingGroup((prev) => ({ ...prev, [key]: false }));
      }
    },
    [questionId, rowsBySourceGroup, lang],
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
    const clean = clampInt(qty);
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
  }, []);

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
      const map = qtyBySource[source.id] ?? {};
      for (const [id, qty] of Object.entries(map)) {
        if (qty > 0) out.push({ sourceId: source.id, id, qty });
      }
    }
    return out;
  }, [qtyBySource, shop.sources]);

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
      const selected = qtyBySource[source.id] ?? {};
      for (const [id, qty] of Object.entries(selected)) {
        if (qty <= 0) continue;
        const row = byId.get(id);
        const price = row ? toNumber(row.price, 0) : 0;
        if (price === 0) return true;
      }
    }
    return false;
  }, [qtyBySource, rowsBySource, rowsBySourceGroup, shop.sources]);

  const handleSubmit = useCallback(() => {
    if (hasExceededBudgets && !ignoreWarnings) {
      // Scroll to top to show warning
      budgetSummaryRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' });
      return;
    }
    onSubmit({ v: 1, purchases, ignoreWarnings: ignoreWarnings || undefined });
  }, [hasExceededBudgets, ignoreWarnings, purchases, onSubmit]);

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
      return sortRows(
        rows,
        sortConfig.column,
        sortConfig.direction,
        sourceId,
        keyColumn,
        qtyBySource,
        columns,
      );
    },
    [sortBySource, qtyBySource],
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
    }).sort((a, b) => (a.priority ?? 999) - (b.priority ?? 999));
  }, [budgets, budgetUsage, state]);

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
        {hasExceededBudgets && (
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
        {shop.warningPriceZero && hasPriceZeroItems && (
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
        
        {visibleBudgets.map((budget) => {
          const usage = budgetUsage[budget.id];
          if (!usage) return null;
          const isExceeded = usage.remaining < 0;
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
                  <span className={`shop-summary-value ${isExceeded ? "shop-bad" : ""}`}>
                    {usage.spent}
                  </span>
                </div>
                <div className="shop-summary-item">
                  <span className="shop-summary-label">REMAINING</span>
                  <span className={`shop-summary-value ${isExceeded ? "shop-bad" : ""}`}>
                    {usage.remaining}
                  </span>
                </div>
              </div>
            </div>
          );
        })}

        {hasExceededBudgets && (
          <div className="shop-error" style={{ marginTop: '12px' }}>
            {lang === 'ru' ? 'Один или несколько бюджетов перевыполнены' : 'One or more budgets are exceeded'}
          </div>
        )}
      </div>

      <div className="shop-sources">
        {shop.sources.map((source) => {
          const isOpen = Boolean(expanded[source.id]);
          const rawRows = rowsBySource[source.id] ?? [];
          const groups = groupsBySource[source.id] ?? null;
          const isLoading = Boolean(loadingSource[source.id]);
          const err = loadErrorSource[source.id];
          const selected = qtyBySource[source.id] ?? {};
          const visibleColumns = source.groupColumn
            ? source.columns.filter((c) => c.field !== source.groupColumn)
            : source.columns;
          const sortConfig = sortBySource[source.id];
          const rows = getSortedRows(rawRows, source.id, source.keyColumn, source.columns);

          return (
            <div key={source.id} className="shop-source">
              <button
                type="button"
                className="shop-source-header"
                onClick={() => {
                  toggleExpanded(source.id);
                  if (!isOpen) void ensureLoadedSourceRoot(source.id);
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
                  {isLoading && <div className="shop-muted">Loading...</div>}
                  {err && <div className="shop-error">Failed to load: {err}</div>}

                  {!isLoading && !err && groups && (
                    <div className="shop-sources">
                      {groups.map((g) => {
                        const gKey = `${source.id}::${g.value}`;
                        const gOpen = Boolean(expandedGroup[gKey]);
                        const gLoading = Boolean(loadingGroup[gKey]);
                        const gErr = loadErrorGroup[gKey];
                        const gRows = rowsBySourceGroup[source.id]?.[g.value] ?? [];
                        return (
                          <div key={gKey} className="shop-source">
                            <button
                              type="button"
                              className="shop-source-header"
                              onClick={() => {
                                setExpandedGroup((prev) => ({ ...prev, [gKey]: !prev[gKey] }));
                                if (!gOpen) void ensureLoadedGroupRows(source.id, g.value);
                              }}
                              disabled={disabled}
                            >
                              <span className="shop-source-title">
                                {g.value} {Number.isFinite(g.count) ? `(${g.count})` : ""}
                              </span>
                              <span className="shop-source-chevron">{gOpen ? "▾" : "▸"}</span>
                            </button>
                            {gOpen && (
                              <div className="shop-source-body">
                                {gLoading && <div className="shop-muted">Loading...</div>}
                                {gErr && <div className="shop-error">Failed to load: {gErr}</div>}
                                {!gLoading && !gErr && (() => {
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
                            )}
                          </div>
                        );
                      })}
                    </div>
                  )}

                  {!isLoading && !err && !groups && (
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
    </div>
  );
}


