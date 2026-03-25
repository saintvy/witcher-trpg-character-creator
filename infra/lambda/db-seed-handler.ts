import { readFileSync } from 'node:fs';
import { Client } from 'pg';

type CfnEvent = {
  RequestType: 'Create' | 'Update' | 'Delete';
  ResourceProperties?: Record<string, unknown>;
};

function requireEnv(name: string): string {
  const value = process.env[name]?.trim();
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function loadSql(): string {
  const raw = readFileSync('/var/task/wcc_sql_deploy.sql', 'utf8');
  const withoutBom = raw.replace(/^\uFEFF/, '');
  return withoutBom
    .split(/\r?\n/)
    .filter((line) => !line.trimStart().startsWith('\\'))
    .join('\n');
}

async function applySeedSql(): Promise<void> {
  const host = requireEnv('POSTGRES_HOST');
  const port = Number.parseInt(requireEnv('POSTGRES_PORT'), 10);
  const user = requireEnv('POSTGRES_USER');
  const password = requireEnv('POSTGRES_PASSWORD');
  const database = requireEnv('POSTGRES_DB');
  const sql = loadSql();

  const client = new Client({
    host,
    port,
    database,
    user,
    password,
    ssl: {
      rejectUnauthorized: false,
    },
  });

  await client.connect();
  try {
    await client.query(sql);
  } finally {
    await client.end();
  }
}

export async function handler(event: CfnEvent): Promise<{ PhysicalResourceId: string; Data?: Record<string, string> }> {
  console.log('[db-seed] event', {
    requestType: event.RequestType,
    sqlBundleVersion:
      typeof event.ResourceProperties?.sqlBundleVersion === 'string'
        ? event.ResourceProperties.sqlBundleVersion
        : undefined,
  });

  if (event.RequestType === 'Delete') {
    return { PhysicalResourceId: 'wcc-db-seed' };
  }

  await applySeedSql();
  return {
    PhysicalResourceId: 'wcc-db-seed',
    Data: { status: event.RequestType === 'Create' ? 'seeded-create' : 'seeded-update' },
  };
}
