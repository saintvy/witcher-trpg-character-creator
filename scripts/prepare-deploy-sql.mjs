import { createHash } from 'node:crypto';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { spawnSync } from 'node:child_process';

const repoRoot = resolve(import.meta.dirname, '..');
const dbDir = resolve(repoRoot, 'db');
const deploySqlPath = resolve(repoRoot, 'db/sql/wcc_sql_deploy.sql');
const generatedVersionPath = resolve(
  repoRoot,
  'cloud/infra/generated/sql-bundle-version.json',
);

const seedResult = spawnSync('bash', ['-lc', 'WCC_SEED_MERGE_ONLY=true ./seed.sh'], {
  cwd: dbDir,
  stdio: 'inherit',
  env: process.env,
});

if (seedResult.status !== 0) {
  process.exit(seedResult.status ?? 1);
}

const sqlContent = readFileSync(deploySqlPath);
const sqlHash = createHash('sha256').update(sqlContent).digest('hex');
let previousHash = null;
let previousCounter = 0;

try {
  const previous = JSON.parse(readFileSync(generatedVersionPath, 'utf8'));
  previousHash =
    typeof previous?.sqlHash === 'string' && previous.sqlHash.trim().length > 0
      ? previous.sqlHash.trim()
      : null;
  previousCounter = Number.isFinite(previous?.sqlCounter)
    ? Number(previous.sqlCounter)
    : 0;
} catch {
  // No previous generated file yet.
}

const sqlCounter = previousHash === sqlHash ? Math.max(previousCounter, 1) : Math.max(previousCounter, 0) + 1;
const sqlBundleVersion = `wcc_sql_${sqlCounter}_${sqlHash.slice(0, 16)}`;

mkdirSync(dirname(generatedVersionPath), { recursive: true });
writeFileSync(
  generatedVersionPath,
  `${JSON.stringify({ sqlBundleVersion, sqlHash, sqlCounter }, null, 2)}\n`,
  'utf8',
);

console.log(`[prepare-deploy-sql] sqlBundleVersion=${sqlBundleVersion} (counter=${sqlCounter})`);
