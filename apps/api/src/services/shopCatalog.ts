import { db } from '../db/pool.js';

const DEFAULT_SURVEY_ID = 'witcher_cc';
const DEFAULT_LANG = 'en';

export type ShopSourceRowsRequest = {
  surveyId?: string;
  lang?: string;
  questionId: string;
  sourceId: string;
  groupValue?: string;
};

function isSafeIdentifier(value: string): boolean {
  // We only allow simple identifiers to avoid SQL injection via metadata
  return /^[a-zA-Z_][a-zA-Z0-9_]*$/.test(value);
}

function asStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((v): v is string => typeof v === 'string' && v.length > 0);
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

const ALLOWED_TABLES = new Set(['wcc_item_weapons_v', 'wcc_item_armors_v', 'wcc_item_ingredients_v', 'wcc_item_upgrades_v', 'wcc_item_general_gear_v', 'wcc_item_vehicles_v']);

export async function getShopSourceRows(
  payload: ShopSourceRowsRequest,
): Promise<{ rows?: Record<string, unknown>[]; groups?: Array<{ value: string; count: number }> }> {
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

  const source = sources
    .map((s) => (s && typeof s === 'object' && !Array.isArray(s) ? (s as ShopSourceConfig) : null))
    .find((s) => s?.id === payload.sourceId);

  if (!source) {
    throw new Error('Unknown sourceId');
  }

  const table = source.table;
  const keyColumn = source.keyColumn;
  const dlcColumn = source.dlcColumn;
  const langColumn = source.langColumn;
  const groupColumn = source.groupColumn;
  const tooltipField = source.tooltipField;
  if (!ALLOWED_TABLES.has(table)) {
    throw new Error('Table is not allowed');
  }
  if (!isSafeIdentifier(keyColumn) || !isSafeIdentifier(dlcColumn)) {
    throw new Error('Unsafe column identifier');
  }
  if (langColumn && !isSafeIdentifier(langColumn)) {
    throw new Error('Unsafe lang column identifier');
  }
  if (groupColumn && !isSafeIdentifier(groupColumn)) {
    throw new Error('Unsafe group column identifier');
  }
  if (tooltipField && !isSafeIdentifier(tooltipField)) {
    throw new Error('Unsafe tooltip field identifier');
  }

  const allowedDlcs = asStringArray(shop?.allowedDlcs);
  const dlcs = allowedDlcs.length > 0 ? allowedDlcs : ['core'];

  const filters = (source.filters && typeof source.filters === 'object')
    ? (source.filters as Record<string, unknown>)
    : {};
  const filterType = filters.type;
  const filterIsNull = filters.isNull;
  const filterIsNotNull = filters.isNotNull;

  // Common WHERE for both "groups" and "rows"
  const whereParts: string[] = [`"${dlcColumn}" = ANY($1::text[])`];
  const params: unknown[] = [dlcs];
  let paramIndex = 2;

  if (langColumn && lang) {
    whereParts.push(`"${langColumn}" = $${paramIndex}`);
    params.push(lang);
    paramIndex++;
  }

  if (typeof filterType === 'string' && filterType.length > 0) {
    whereParts.push(`"type" = $${paramIndex}`);
    params.push(filterType);
    paramIndex++;
  }

  // Support isNull filter: column IS NULL
  if (typeof filterIsNull === 'string' && isSafeIdentifier(filterIsNull)) {
    whereParts.push(`"${filterIsNull}" IS NULL`);
  }

  // Support isNotNull filter: column IS NOT NULL
  if (typeof filterIsNotNull === 'string' && isSafeIdentifier(filterIsNotNull)) {
    whereParts.push(`"${filterIsNotNull}" IS NOT NULL`);
  }

  // If grouping is enabled and caller didn't request a specific group, return only group headers.
  if (groupColumn && (payload.groupValue === undefined || payload.groupValue === null || payload.groupValue === '')) {
    whereParts.push(`"${groupColumn}" IS NOT NULL`);
    whereParts.push(`NULLIF("${groupColumn}"::text, '') IS NOT NULL`);

    const { rows } = await db.query<{ value: string; count: string }>(
      `
        SELECT "${groupColumn}"::text AS "value", COUNT(*)::text AS "count"
        FROM "${table}"
        WHERE ${whereParts.join(' AND ')}
        GROUP BY "${groupColumn}"
        ORDER BY "${groupColumn}" ASC
      `,
      params,
    );

    return {
      groups: rows
        .filter((r) => typeof r.value === 'string' && r.value.length > 0)
        .map((r) => ({ value: r.value, count: Number(r.count) })),
    };
  }

  // Otherwise return rows (optionally filtered by groupValue)

  if (groupColumn && payload.groupValue) {
    whereParts.push(`"${groupColumn}"::text = $${paramIndex}`);
    params.push(payload.groupValue);
    paramIndex++;
  }

  // Select only declared columns (plus key/dlc/lang and filter columns if needed)
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

  if (filterType !== undefined) {
    fields.add('type');
  }

  const selectList = Array.from(fields).map((f) => `"${f}"`).join(', ');

  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  const { rows } = await db.query<Record<string, unknown>>(
    `
      SELECT ${selectList}
      FROM "${table}"
      WHERE ${whereParts.join(' AND ')}
      ORDER BY "${keyColumn}" ASC
    `,
    params,
  );

  return { rows };
}


