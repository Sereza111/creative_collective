/**
 * Проверяет наличие ключевых таблиц прод-контура в текущей БД (env из .env / Portainer).
 * Запуск: npm run verify-schema
 * Exit 0 — все таблицы есть; 1 — чего-то не хватает.
 */
require('dotenv').config();
const mysql = require('mysql2/promise');

const REQUIRED_TABLES = [
  // management
  'users',
  'teams',
  'team_members',
  'projects',
  'project_members',
  'tasks',
  'comments',
  'files',
  'refresh_tokens',
  'finances',
  // marketplace
  'orders',
  'order_applications',
  'chats',
  'messages',
  'reviews',
  'favorites',
  'disputes',
  'dispute_messages',
  'dispute_history',
  // legal / finance / notifications
  'legal_documents',
  'user_agreements',
  'user_balances',
  'transactions',
  'withdrawal_requests',
  'notifications',
  'notification_settings',
  // migrations bookkeeping
  'schema_migrations',
  // optional but expected after full migrations
  'application_views',
  'application_refunds',
  'portfolio',
];

async function main() {
  const dbName = process.env.DB_NAME || 'creative_collective';
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: dbName,
  });

  const [rows] = await conn.query(
    `SELECT TABLE_NAME AS name FROM information_schema.TABLES
     WHERE TABLE_SCHEMA = ?`,
    [dbName]
  );
  await conn.end();

  const have = new Set(rows.map((r) => r.name));
  const missing = REQUIRED_TABLES.filter((t) => !have.has(t));

  if (missing.length) {
    console.error('❌ Отсутствуют таблицы:', missing.join(', '));
    console.error('   Примените миграции: npm run migrate');
    console.error('   Для старого MySQL см. backend/migrations_uuid/000_hotfix_existing_db.sql');
    process.exit(1);
  }

  console.log(`✅ Все ${REQUIRED_TABLES.length} ключевых таблиц присутствуют в БД "${dbName}".`);
}

main().catch((e) => {
  console.error('❌ Ошибка проверки схемы:', e.message);
  process.exit(1);
});
