const fs = require('fs');
const path = require('path');
const { pool, createMigrationConnection } = require('../config/database');

async function seedLegalDocuments() {
  const [rows] = await pool.query('SELECT COUNT(*) AS count FROM legal_documents');
  if (rows[0].count > 0) {
    return { seeded: false, reason: 'already_has_rows' };
  }

  const sqlPath = path.join(__dirname, '..', '..', 'migrations', 'insert_legal_documents.sql');
  if (!fs.existsSync(sqlPath)) {
    throw new Error(`Legal seed file not found: ${sqlPath}`);
  }

  let sql = fs.readFileSync(sqlPath, 'utf8');
  sql = sql.replace(/^USE\s+\w+\s*;\s*/i, '');

  const conn = await createMigrationConnection();
  try {
    await conn.query(sql);
  } finally {
    await conn.end();
  }

  const [after] = await pool.query('SELECT COUNT(*) AS count FROM legal_documents');
  return { seeded: true, count: after[0].count };
}

module.exports = { seedLegalDocuments };
