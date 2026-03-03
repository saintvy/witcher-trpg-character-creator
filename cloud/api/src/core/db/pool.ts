import { Pool, type QueryResult, type QueryResultRow } from 'pg';

const pool = new Pool({
  host: process.env.POSTGRES_HOST ?? 'localhost',
  port: Number(process.env.POSTGRES_PORT ?? '5433'),
  user: process.env.POSTGRES_USER ?? 'cc_user',
  password: process.env.POSTGRES_PASSWORD ?? 'cc_pass',
  database: process.env.POSTGRES_DB ?? 'witcher_cc',
  ssl: process.env.POSTGRES_SSL === 'true' ? { rejectUnauthorized: false } : undefined,
});

export const db = {
  query<T extends QueryResultRow = QueryResultRow>(text: string, params: unknown[] = []): Promise<QueryResult<T>> {
    return pool.query<T>(text, params);
  },
  close: () => pool.end(),
};
