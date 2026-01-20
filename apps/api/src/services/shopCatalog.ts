import { db } from '../db/pool.js';

const DEFAULT_SURVEY_ID = 'witcher_cc';
const DEFAULT_LANG = 'en';

function isSafeIdentifier(value: string): boolean {
  // We only allow simple identifiers to avoid SQL injection via metadata
  return /^[a-zA-Z_][a-zA-Z0-9_]*$/.test(value);
}

function asStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((v): v is string => typeof v === 'string' && v.length > 0);
}

function getAtPath(source: unknown, path: string): unknown {
  if (!path) return undefined;
  const parts = path.split('.').filter(Boolean);
  let cursor: any = source;
  for (const part of parts) {
    if (cursor == null || typeof cursor !== 'object') return undefined;
    cursor = cursor[part];
  }
  return cursor;
}

/**
 * Extract values from nested arrays using a path with [] syntax.
 * Example: "characterRaw.professional_gear_options.bundles[].items[].itemId"
 */
function catArray(state: Record<string, unknown>, path: string): unknown[] {
  // Helper: simple get by path parts (no [] support)
  const getValueAtPath = (obj: unknown, pathParts: string[]): unknown => {
    if (pathParts.length === 0) return obj;
    if (obj === null || obj === undefined || typeof obj !== 'object') return undefined;
    const [first, ...rest] = pathParts;
    const objRecord = obj as Record<string, unknown>;
    if (first in objRecord) return getValueAtPath(objRecord[first], rest);
    return undefined;
  };

  const extractFromNestedArrays = (currentValue: unknown, remainingPath: string): unknown[] => {
    if (remainingPath === '') {
      if (currentValue === undefined || currentValue === null) return [];
      return Array.isArray(currentValue) ? currentValue : [currentValue];
    }

    const nextArrayIndex = remainingPath.indexOf('[]');
    if (nextArrayIndex === -1) {
      const parts = remainingPath.split('.').filter((p) => p);
      const value = getValueAtPath(currentValue, parts);
      if (value === undefined || value === null) return [];
      return Array.isArray(value) ? value : [value];
    }

    const pathBeforeArray = remainingPath.substring(0, nextArrayIndex);
    const pathAfterArray = remainingPath.substring(nextArrayIndex + 2); // skip []
    const pathParts = pathBeforeArray.split('.').filter((p) => p);
    const arrayValue = getValueAtPath(currentValue, pathParts);
    if (!Array.isArray(arrayValue)) return [];

    const results: unknown[] = [];
    for (const item of arrayValue) {
      results.push(...extractFromNestedArrays(item, pathAfterArray));
    }
    return results;
  };

  const firstArrayIndex = path.indexOf('[]');
  if (firstArrayIndex === -1) {
    const parts = path.split('.').filter((p) => p);
    const value = getValueAtPath(state, parts);
    return Array.isArray(value) ? value : (value !== undefined ? [value] : []);
  }

  const basePath = path.substring(0, firstArrayIndex);
  const remainingPath = path.substring(firstArrayIndex + 2);
  const basePathParts = basePath.split('.').filter((p) => p);
  const baseValue = getValueAtPath(state, basePathParts);
  if (!Array.isArray(baseValue)) return [];

  const results: unknown[] = [];
  for (const item of baseValue) {
    results.push(...extractFromNestedArrays(item, remainingPath));
  }
  return results;
}

/**
 * Minimal json-logic evaluator for shop filters.
 * Supports: var, concat_arrays, cat_array.
 */
function evalJsonLogicLite(expr: unknown, state: Record<string, unknown>): unknown {
  if (expr === null || expr === undefined) return expr;
  if (typeof expr !== 'object' || Array.isArray(expr)) return expr;

  const obj = expr as Record<string, unknown>;

  if ('var' in obj) {
    const v = obj.var;
    if (typeof v === 'string') {
      return getAtPath(state, v);
    }
    if (Array.isArray(v) && typeof v[0] === 'string') {
      const value = getAtPath(state, v[0]);
      return value === undefined ? v[1] : value;
    }
    return undefined;
  }

  if ('cat_array' in obj) {
    const path = obj.cat_array;
    if (typeof path !== 'string') return [];
    return catArray(state, path);
  }

  if ('concat_arrays' in obj) {
    const args = obj.concat_arrays;
    const parts = Array.isArray(args) ? args : [args];
    const result: unknown[] = [];
    for (const part of parts) {
      const evaluated = evalJsonLogicLite(part, state);
      if (Array.isArray(evaluated)) {
        result.push(...evaluated);
      } else if (evaluated !== null && evaluated !== undefined) {
        result.push(evaluated);
      }
    }
    return result;
  }

  return expr;
}

function evalJsonLogicExpressionWrapper(value: unknown, state: Record<string, unknown>): unknown {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    const obj = value as Record<string, unknown>;
    if ('jsonlogic_expression' in obj && Object.keys(obj).length === 1) {
      return evalJsonLogicLite(obj.jsonlogic_expression, state);
    }
  }
  return value;
}

type ShopSourceConfig = {
  id: string;
  title?: unknown;
  table: string;
  dlcColumn: string;
  keyColumn: string;
  langColumn?: string;
  langPath?: string;
  groupColumn?: string;
  tooltipField?: string;
  filters?: Record<string, unknown>;
  columns?: Array<{ field: string; label?: unknown }>;
};

type ShopQuestionConfig = {
  allowedDlcs?: unknown;
  sources?: unknown;
};

const ALLOWED_TABLES = new Set(['wcc_item_weapons_v', 'wcc_item_armors_v', 'wcc_item_ingredients_v', 'wcc_item_upgrades_v', 'wcc_item_general_gear_v', 'wcc_item_vehicles_v', 'wcc_item_recipes_v', 'wcc_item_potions_v', 'wcc_item_mutagens_v', 'wcc_item_trophies_v', 'wcc_item_blueprints_v']);

export type GetAllShopItemsRequest = {
  surveyId?: string;
  lang?: string;
  questionId: string;
  allowedDlcs?: string[];
  /**
   * Optional survey state to evaluate jsonlogic_expression inside shop filters.
   * (Needed for professional shop filters based on professional_gear_options.)
   */
  state?: Record<string, unknown>;
};

export type GetAllShopItemsResponse = {
  [sourceId: string]: {
    groups?: Array<{ value: string; count: number }>;
    rowsByGroup?: Record<string, Record<string, unknown>[]>;
    rows?: Record<string, unknown>[];
  };
};

/**
 * Загружает все товары для всех источников магазина сразу
 */
export async function getAllShopItems(
  payload: GetAllShopItemsRequest,
): Promise<GetAllShopItemsResponse> {
  const surveyId = payload.surveyId ?? DEFAULT_SURVEY_ID;
  const lang = payload.lang ?? DEFAULT_LANG;

  const metaResult = await db.query<{ metadata: Record<string, unknown> }>(
    `
      SELECT q.metadata
      FROM questions q
      WHERE q.su_su_id = $1 AND q.qu_id = $2
    `,
    [surveyId, payload.questionId],
  );

  if (metaResult.rows.length === 0) {
    throw new Error('Question not found');
  }

  const questionMeta = metaResult.rows[0]!.metadata ?? {};
  const renderer = (questionMeta as Record<string, unknown>).renderer;
  if (renderer !== 'shop') {
    throw new Error('Question is not a shop renderer');
  }

  const shop = (questionMeta as Record<string, unknown>).shop as ShopQuestionConfig | undefined;
  const sourcesRaw = shop?.sources;
  const sources = Array.isArray(sourcesRaw) ? (sourcesRaw as unknown[]) : [];

  const allowedFromRequest = asStringArray(payload.allowedDlcs);
  const allowedFromMeta = asStringArray(shop?.allowedDlcs);
  const base = allowedFromRequest.length > 0 ? allowedFromRequest : allowedFromMeta;
  // core всегда разрешён
  const dlcs = Array.from(new Set(['core', ...base]));

  const evalState = payload.state && typeof payload.state === 'object' && !Array.isArray(payload.state)
    ? (payload.state as Record<string, unknown>)
    : {};

  const result: GetAllShopItemsResponse = {};

  // Загружаем товары для каждого источника параллельно
  await Promise.all(
    sources.map(async (s) => {
      const source = s && typeof s === 'object' && !Array.isArray(s) ? (s as ShopSourceConfig) : null;
      if (!source) return;

      const table = source.table;
      const keyColumn = source.keyColumn;
      const dlcColumn = source.dlcColumn;
      const langColumn = source.langColumn;
      const groupColumn = source.groupColumn;
      const tooltipField = source.tooltipField;

      if (!ALLOWED_TABLES.has(table)) return;
      if (!isSafeIdentifier(keyColumn) || !isSafeIdentifier(dlcColumn)) return;
      if (langColumn && !isSafeIdentifier(langColumn)) return;
      if (groupColumn && !isSafeIdentifier(groupColumn)) return;
      if (tooltipField && !isSafeIdentifier(tooltipField)) return;

      const filters = (source.filters && typeof source.filters === 'object')
        ? (source.filters as Record<string, unknown>)
        : {};

      // Extra DLC eligibility (rare cases): allow specific item ids even if their dlcColumn is not in allowed dlcs.
      // We do it via a small "extra ids" list to keep queries cheap (no table-wide EXISTS checks).
      const extraIdsResult = await db.query<{ item_key: string }>(
        `
          SELECT x.item_key
          FROM wcc_shop_item_dlc_extra x
          WHERE x.table_name = $1
            AND x.dlc_id = ANY($2::text[])
        `,
        [table, dlcs],
      );
      const extraIds = extraIdsResult.rows
        .map((r) => r.item_key)
        .filter((v): v is string => typeof v === 'string' && v.length > 0);

      // Базовые условия WHERE
      const whereParts: string[] = [];
      const params: unknown[] = [];
      let paramIndex = 1;

      if (extraIds.length > 0) {
        // NOTE: OR does not duplicate rows; it only relaxes DLC filter for explicitly whitelisted items.
        whereParts.push(`("${dlcColumn}" = ANY($1::text[]) OR "${keyColumn}" = ANY($2::varchar[]))`);
        params.push(dlcs, extraIds);
        paramIndex = 3;
      } else {
        whereParts.push(`"${dlcColumn}" = ANY($1::text[])`);
        params.push(dlcs);
        paramIndex = 2;
      }

      if (langColumn && lang) {
        whereParts.push(`"${langColumn}" = $${paramIndex}`);
        params.push(lang);
        paramIndex++;
      }

      const applyFilters = (node: unknown) => {
        if (!node || typeof node !== 'object' || Array.isArray(node)) return;
        const f = node as Record<string, unknown>;

        // AND-combinator
        if ('all' in f && Array.isArray(f.all)) {
          for (const child of f.all) applyFilters(child);
        }

        // type filter (column name is fixed)
        if (typeof f.type === 'string' && f.type.length > 0) {
          whereParts.push(`"type" = $${paramIndex}`);
          params.push(f.type);
          paramIndex++;
        }

        // isNull / isNotNull
        if (typeof f.isNull === 'string' && isSafeIdentifier(f.isNull)) {
          whereParts.push(`"${f.isNull}" IS NULL`);
        }
        if (typeof f.isNotNull === 'string' && isSafeIdentifier(f.isNotNull)) {
          whereParts.push(`"${f.isNotNull}" IS NOT NULL`);
        }

        // IN filter
        if ('in' in f && f.in && typeof f.in === 'object' && !Array.isArray(f.in)) {
          const inFilter = f.in as Record<string, unknown>;
          const columnRaw = typeof inFilter.column === 'string' && inFilter.column.length > 0
            ? inFilter.column
            : keyColumn;
          if (!isSafeIdentifier(columnRaw)) return;

          const evaluated = evalJsonLogicExpressionWrapper(inFilter.values, evalState);
          const values = asStringArray(evaluated);
          if (values.length === 0) {
            // empty IN should return no rows
            whereParts.push('FALSE');
          } else {
            whereParts.push(`"${columnRaw}" = ANY($${paramIndex}::text[])`);
            params.push(values);
            paramIndex++;
          }
        }
      };

      applyFilters(filters);

      // Определяем поля для SELECT
      const fields = new Set<string>();
      fields.add(keyColumn);
      fields.add(dlcColumn);
      if (langColumn) {
        fields.add(langColumn);
      }
      if (groupColumn) {
        fields.add(groupColumn);
      }
      if (tooltipField) {
        fields.add(tooltipField);
      }

      const columns = Array.isArray(source.columns) ? source.columns : [];
      for (const col of columns) {
        if (!col || typeof col !== 'object') continue;
        const field = (col as { field?: unknown }).field;
        if (typeof field === 'string' && isSafeIdentifier(field)) {
          fields.add(field);
        }
      }

      // Keep "type" available if user filtered by it (for debugging / compatibility)
      if (filters && typeof filters === 'object' && ('type' in filters)) {
        fields.add('type');
      }

      const selectList = Array.from(fields).map((f) => `"${f}"`).join(', ');

      if (groupColumn) {
        // Если есть группировка, загружаем группы и товары по группам
        const groupsWhereParts = [...whereParts];
        groupsWhereParts.push(`"${groupColumn}" IS NOT NULL`);
        groupsWhereParts.push(`NULLIF("${groupColumn}"::text, '') IS NOT NULL`);

        const { rows: groupRows } = await db.query<{ value: string; count: string }>(
          `
            SELECT "${groupColumn}"::text AS "value", COUNT(*)::text AS "count"
            FROM "${table}"
            WHERE ${groupsWhereParts.join(' AND ')}
            GROUP BY "${groupColumn}"
            ORDER BY "${groupColumn}" ASC
          `,
          params,
        );

        const groups = groupRows
          .filter((r) => typeof r.value === 'string' && r.value.length > 0)
          .map((r) => ({ value: r.value, count: Number(r.count) }));

        // Загружаем товары для каждой группы
        const rowsByGroup: Record<string, Record<string, unknown>[]> = {};
        await Promise.all(
          groups.map(async (group) => {
            const groupWhereParts = [...whereParts];
            groupWhereParts.push(`"${groupColumn}"::text = $${paramIndex}`);
            const groupParams = [...params, group.value];

            const { rows } = await db.query<Record<string, unknown>>(
              `
                SELECT ${selectList}
                FROM "${table}"
                WHERE ${groupWhereParts.join(' AND ')}
                ORDER BY "${keyColumn}" ASC
              `,
              groupParams,
            );

            rowsByGroup[group.value] = rows;
          }),
        );

        result[source.id] = {
          groups,
          rowsByGroup,
        };
      } else {
        // Если нет группировки, загружаем все товары сразу
        const { rows } = await db.query<Record<string, unknown>>(
          `
            SELECT ${selectList}
            FROM "${table}"
            WHERE ${whereParts.join(' AND ')}
            ORDER BY "${keyColumn}" ASC
          `,
          params,
        );

        result[source.id] = {
          rows,
        };
      }
    }),
  );

  return result;
}


