import { readFileSync } from 'node:fs';
import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';
import { Client } from 'pg';

type CfnEvent = {
  RequestType: 'Create' | 'Update' | 'Delete';
  ResourceProperties?: Record<string, unknown>;
};

type DbSecret = {
  username?: string;
  password?: string;
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

async function getDbCredentials(secretArn: string): Promise<Required<DbSecret>> {
  const client = new SecretsManagerClient({});
  const response = await client.send(new GetSecretValueCommand({ SecretId: secretArn }));
  if (!response.SecretString) {
    throw new Error('DB secret has no SecretString');
  }

  const parsed = JSON.parse(response.SecretString) as DbSecret;
  if (!parsed.username || !parsed.password) {
    throw new Error('DB secret is missing username and/or password');
  }

  return {
    username: parsed.username,
    password: parsed.password,
  };
}

async function applySeedSql(): Promise<void> {
  const host = requireEnv('POSTGRES_HOST');
  const port = Number.parseInt(requireEnv('POSTGRES_PORT'), 10);
  const database = requireEnv('POSTGRES_DB');
  const secretArn = requireEnv('DB_SECRET_ARN');
  const { username, password } = await getDbCredentials(secretArn);
  const sql = loadSql();

  const client = new Client({
    host,
    port,
    database,
    user: username,
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
