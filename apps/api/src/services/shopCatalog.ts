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
      const filterType = filters.type;
      const filterIsNull = filters.isNull;
      const filterIsNotNull = filters.isNotNull;

      // Базовые условия WHERE
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

      if (typeof filterIsNull === 'string' && isSafeIdentifier(filterIsNull)) {
        whereParts.push(`"${filterIsNull}" IS NULL`);
      }

      if (typeof filterIsNotNull === 'string' && isSafeIdentifier(filterIsNotNull)) {
        whereParts.push(`"${filterIsNotNull}" IS NOT NULL`);
      }

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

      if (filterType !== undefined) {
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


