const { query } = require('../config/database');
const { newId } = require('./id');

/**
 * Запись расхода в transactions (разные схемы БД на проде).
 * Не бросает ошибку — отклик не должен падать из‑за истории транзакций.
 */
async function recordMarketplaceExpense(userId, orderId, amount, description) {
  const transactionId = newId();

  try {
    await query(
      `INSERT INTO transactions (id, user_id, type, amount, description, status, order_id)
       VALUES (?, ?, 'expense', ?, ?, 'completed', ?)`,
      [transactionId, userId, amount, description, orderId]
    );
    return;
  } catch (err) {
    console.warn('[transactions] marketplace insert failed:', err.message);
  }

  try {
    const finances = await query('SELECT id FROM finances WHERE user_id = ? LIMIT 1', [userId]);
    if (finances.length === 0) return;

    await query(
      `INSERT INTO transactions (id, finance_id, type, amount, description)
       VALUES (?, ?, 'spent', ?, ?)`,
      [transactionId, finances[0].id, amount, description]
    );
  } catch (err) {
    console.warn('[transactions] finances insert skipped:', err.message);
  }
}

module.exports = { recordMarketplaceExpense };
