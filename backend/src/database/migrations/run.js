const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { createDatabaseIfNotExists, createMigrationConnection, getDbConfig } = require('../../config/database');

function sortSqlFiles(files) {
  return files
    .filter((f) => f.toLowerCase().endsWith('.sql'))
    .sort((a, b) => a.localeCompare(b));
}

async function ensureMigrationsTable(conn) {
  await conn.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      id VARCHAR(36) PRIMARY KEY,
      filename VARCHAR(255) NOT NULL UNIQUE,
      checksum_sha256 VARCHAR(64) NOT NULL,
      applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
  `);
}

function sha256(content) {
  return crypto.createHash('sha256').update(content, 'utf8').digest('hex');
}

async function getAppliedMigrations(conn) {
  const [rows] = await conn.query('SELECT filename, checksum_sha256 FROM schema_migrations');
  const map = new Map();
  for (const r of rows) map.set(r.filename, r.checksum_sha256);
  return map;
}

async function applySqlFile(conn, filename, fullPath, expectedChecksum) {
  const sql = fs.readFileSync(fullPath, 'utf8');
  const checksum = sha256(sql);
  if (expectedChecksum && expectedChecksum !== checksum) {
    throw new Error(`Migration checksum mismatch for ${filename}. Expected ${expectedChecksum}, got ${checksum}`);
  }

  // Execute as a whole script (supports DELIMITER blocks in files that avoid client-side delimiter changes).
  await conn.query(sql);

  const id = crypto.randomUUID();
  await conn.query(
    'INSERT INTO schema_migrations (id, filename, checksum_sha256) VALUES (?, ?, ?)',
    [id, filename, checksum]
  );
}

async function runMigrations(options = {}) {
  const migrationsDir =
    options.migrationsDir ||
    path.join(__dirname, '..', '..', '..', 'migrations_uuid');

  const baselineFile =
    options.baselineFile ||
    path.join(__dirname, '..', 'schema.sql');

  await createDatabaseIfNotExists();

  const conn = await createMigrationConnection();
  try {
    await ensureMigrationsTable(conn);
    const applied = await getAppliedMigrations(conn);

    const baselineName = path.basename(baselineFile);
    if (!applied.has(baselineName)) {
      await applySqlFile(conn, baselineName, baselineFile);
    }

    if (!fs.existsSync(migrationsDir)) return { applied: [baselineName], skipped: [] };

    const files = sortSqlFiles(fs.readdirSync(migrationsDir));
    const appliedList = [];
    const skippedList = [];

    for (const file of files) {
      if (applied.has(file)) {
        skippedList.push(file);
        continue;
      }
      await applySqlFile(conn, file, path.join(migrationsDir, file));
      appliedList.push(file);
    }

    return { applied: [baselineName, ...appliedList], skipped: skippedList };
  } finally {
    await conn.end();
  }
}

async function resetDatabase() {
  const cfg = getDbConfig();
  const adminConn = await createMigrationConnection();
  try {
    // Drop & recreate DB (destructive) — intended for local/dev reset.
    await adminConn.query(`DROP DATABASE IF EXISTS \`${cfg.database}\`;`);
    await adminConn.query(
      `CREATE DATABASE IF NOT EXISTS \`${cfg.database}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`
    );
  } finally {
    await adminConn.end();
  }
  return runMigrations();
}

if (require.main === module) {
  const mode = process.argv[2];
  const fn = mode === 'reset' ? resetDatabase : runMigrations;
  fn()
    .then((res) => {
      console.log('✅ Migrations complete');
      console.log(JSON.stringify(res, null, 2));
      process.exit(0);
    })
    .catch((err) => {
      console.error('❌ Migrations failed:', err);
      process.exit(1);
    });
}

module.exports = { runMigrations, resetDatabase };

