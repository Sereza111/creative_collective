/**
 * Пополнить user_balances для E2E (отклик на заказ требует ≥50 ₽).
 * Требует прямой доступ к MySQL с теми же кредами, что и backend.
 *
 *   cd backend && node scripts/credit-user-balance.js <userId> 500
 */
require('dotenv').config();
const mysql = require('mysql2/promise');

async function main() {
  const userId = process.argv[2];
  const amount = parseFloat(process.argv[3] || '500');
  if (!userId) {
    console.error('Usage: node scripts/credit-user-balance.js <userId> [amount]');
    process.exit(1);
  }

  const conn = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'creative_collective',
  });

  const [rows] = await conn.query('SELECT balance FROM user_balances WHERE user_id = ?', [userId]);
  if (rows.length === 0) {
    await conn.end();
    console.error('No user_balances row for user', userId);
    process.exit(1);
  }

  await conn.query(
    'UPDATE user_balances SET balance = balance + ?, updated_at = NOW() WHERE user_id = ?',
    [amount, userId]
  );
  const [after] = await conn.query('SELECT balance FROM user_balances WHERE user_id = ?', [userId]);
  await conn.end();
  console.log(`✅ Credited ${amount}. New balance:`, after[0].balance);
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
