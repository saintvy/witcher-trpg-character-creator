import { useCallback, useMemo, useState } from "react";

type ShopBudgetConfig = {
  currency: string;
  path: string;
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
  budget: ShopBudgetConfig;
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

  const budgetValue = useMemo(() => {
    return clampInt(toNumber(getAtPath(state, shop.budget.path), 0));
  }, [shop.budget.path, state]);

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

  const totalCost = useMemo(() => {
    let sum = 0;
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
        const row = byId.get(id);
        const price = row ? toNumber(row.price, 0) : 0;
        sum += price * qty;
      }
    }
    return clampInt(sum);
  }, [qtyBySource, rowsBySource, shop.sources]);

  const canSubmit = totalCost <= budgetValue && !disabled;

  return (
    <div className="shop-node">
      <div className="shop-summary">
        <div className="shop-summary-row">
          <div className="shop-summary-item">
            <span className="shop-summary-label">Budget</span>
            <span className="shop-summary-value">
              {budgetValue} {shop.budget.currency}
            </span>
          </div>
          <div className="shop-summary-item">
            <span className="shop-summary-label">Total</span>
            <span className={`shop-summary-value ${totalCost > budgetValue ? "shop-bad" : ""}`}>
              {totalCost} {shop.budget.currency}
            </span>
          </div>
          <div className="shop-summary-item">
            <span className="shop-summary-label">Remaining</span>
            <span className={`shop-summary-value ${totalCost > budgetValue ? "shop-bad" : ""}`}>
              {Math.max(0, budgetValue - totalCost)} {shop.budget.currency}
            </span>
          </div>
        </div>

        {totalCost > budgetValue && (
          <div className="shop-error">Not enough funds. Remove items or reduce quantity.</div>
        )}
      </div>

      <div className="shop-sources">
        {shop.sources.map((source) => {
          const isOpen = Boolean(expanded[source.id]);
          const rows = rowsBySource[source.id] ?? [];
          const groups = groupsBySource[source.id] ?? null;
          const isLoading = Boolean(loadingSource[source.id]);
          const err = loadErrorSource[source.id];
          const selected = qtyBySource[source.id] ?? {};
          const visibleColumns = source.groupColumn
            ? source.columns.filter((c) => c.field !== source.groupColumn)
            : source.columns;

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
                                {!gLoading && !gErr && (
                                  <div style={{ overflowX: "auto" }}>
                                    <table className="survey-table shop-table">
                                      <thead>
                                        <tr>
                                          <th style={{ width: 48 }}>✓</th>
                                          <th style={{ width: 110 }}>Qty</th>
                                          {visibleColumns.map((col) => (
                                            <th key={col.field}>{col.label ?? col.field}</th>
                                          ))}
                                        </tr>
                                      </thead>
                                      <tbody>
                                        {gRows.map((row, idx) => {
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
                                )}
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
                            <th style={{ width: 48 }}>✓</th>
                            <th style={{ width: 110 }}>Qty</th>
                            {source.columns.map((col) => (
                              <th key={col.field}>{col.label ?? col.field}</th>
                            ))}
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

      <div className="survey-actions">
        <button
          type="button"
          className="btn btn-primary"
          disabled={!canSubmit}
          onClick={() => onSubmit({ v: 1, purchases })}
        >
          Continue
        </button>
      </div>
    </div>
  );
}


