const { query } = require('../config/database');
const { successResponse, errorResponse } = require('../utils/responseHandler');

// Получить баланс пользователя
exports.getUserBalance = async (req, res) => {
  try {
    const userId = req.user.id;

    // Получаем или создаем баланс
    let balance = await query('SELECT * FROM user_balances WHERE user_id = ?', [userId]);
    
    if (balance.length === 0) {
      // Создаем баланс, если его нет
      await query('INSERT INTO user_balances (user_id) VALUES (?)', [userId]);
      balance = await query('SELECT * FROM user_balances WHERE user_id = ?', [userId]);
    }

    successResponse(res, balance[0]);
  } catch (error) {
    console.error('Get balance error:', error);
    errorResponse(res, 'Ошибка получения баланса');
  }
};

// Получить транзакции пользователя
exports.getUserTransactions = async (req, res) => {
  try {
    const userId = req.user.id;
    const { limit = 50, offset = 0, type, status } = req.query;

    let sql = `
      SELECT 
        t.*,
        o.title as order_title,
        u.full_name as related_user_name
      FROM transactions t
      LEFT JOIN orders o ON t.order_id = o.id
      LEFT JOIN users u ON t.related_user_id = u.id
      WHERE t.user_id = ?
    `;

    const params = [userId];

    if (type) {
      sql += ' AND t.type = ?';
      params.push(type);
    }

    if (status) {
      sql += ' AND t.status = ?';
      params.push(status);
    }

    sql += ' ORDER BY t.created_at DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit), parseInt(offset));

    const transactions = await query(sql, params);

    // Получаем общее количество
    let countSql = 'SELECT COUNT(*) as total FROM transactions WHERE user_id = ?';
    const countParams = [userId];

    if (type) {
      countSql += ' AND type = ?';
      countParams.push(type);
    }

    if (status) {
      countSql += ' AND status = ?';
      countParams.push(status);
    }

    const countResult = await query(countSql, countParams);

    successResponse(res, {
      transactions,
      total: countResult[0].total,
    });
  } catch (error) {
    console.error('Get transactions error:', error);
    errorResponse(res, 'Ошибка получения транзакций');
  }
};

// Создать транзакцию (для заказов)
exports.createTransaction = async (req, res) => {
  try {
    const { user_id, order_id, type, amount, description, related_user_id } = req.body;

    // Проверяем права (только админ или создание транзакции для себя)
    if (req.user.user_role !== 'admin' && req.user.id !== user_id) {
      return errorResponse(res, 'Недостаточно прав', 403);
    }

    const result = await query(
      `INSERT INTO transactions (user_id, order_id, type, amount, description, related_user_id, status)
       VALUES (?, ?, ?, ?, ?, ?, 'pending')`,
      [user_id, order_id, type, amount, description, related_user_id]
    );

    const transaction = await query('SELECT * FROM transactions WHERE id = ?', [result.insertId]);

    successResponse(res, transaction[0], 'Транзакция создана', 201);
  } catch (error) {
    console.error('Create transaction error:', error);
    errorResponse(res, 'Ошибка создания транзакции');
  }
};

// Завершить транзакцию (изменить статус на completed)
exports.completeTransaction = async (req, res) => {
  try {
    const { id } = req.params;

    // Только админ может завершать транзакции
    if (req.user.user_role !== 'admin') {
      return errorResponse(res, 'Только администратор может завершать транзакции', 403);
    }

    const transaction = await query('SELECT * FROM transactions WHERE id = ?', [id]);

    if (transaction.length === 0) {
      return errorResponse(res, 'Транзакция не найдена', 404);
    }

    if (transaction[0].status === 'completed') {
      return errorResponse(res, 'Транзакция уже завершена', 400);
    }

    await query(
      'UPDATE transactions SET status = ?, completed_at = NOW() WHERE id = ?',
      ['completed', id]
    );

    const updatedTransaction = await query('SELECT * FROM transactions WHERE id = ?', [id]);

    successResponse(res, updatedTransaction[0], 'Транзакция завершена');
  } catch (error) {
    console.error('Complete transaction error:', error);
    errorResponse(res, 'Ошибка завершения транзакции');
  }
};

// Создать запрос на вывод средств
exports.createWithdrawalRequest = async (req, res) => {
  try {
    const userId = req.user.id;
    const { amount, payment_method, payment_details } = req.body;

    // Проверяем баланс
    const balance = await query('SELECT balance FROM user_balances WHERE user_id = ?', [userId]);

    if (balance.length === 0 || balance[0].balance < amount) {
      return errorResponse(res, 'Недостаточно средств', 400);
    }

    // Минимальная сумма вывода
    if (amount < 100) {
      return errorResponse(res, 'Минимальная сумма вывода 100 ₽', 400);
    }

    // Создаем запрос
    const result = await query(
      `INSERT INTO withdrawal_requests (user_id, amount, payment_method, payment_details)
       VALUES (?, ?, ?, ?)`,
      [userId, amount, payment_method, JSON.stringify(payment_details)]
    );

    // Замораживаем средства
    await query(
      'UPDATE user_balances SET balance = balance - ?, pending_amount = pending_amount + ? WHERE user_id = ?',
      [amount, amount, userId]
    );

    const withdrawalRequest = await query('SELECT * FROM withdrawal_requests WHERE id = ?', [result.insertId]);

    successResponse(res, withdrawalRequest[0], 'Запрос на вывод создан', 201);
  } catch (error) {
    console.error('Create withdrawal request error:', error);
    errorResponse(res, 'Ошибка создания запроса на вывод');
  }
};

// Получить запросы на вывод пользователя
exports.getUserWithdrawalRequests = async (req, res) => {
  try {
    const userId = req.user.id;

    const requests = await query(
      'SELECT * FROM withdrawal_requests WHERE user_id = ? ORDER BY created_at DESC',
      [userId]
    );

    successResponse(res, requests);
  } catch (error) {
    console.error('Get withdrawal requests error:', error);
    errorResponse(res, 'Ошибка получения запросов на вывод');
  }
};

// Получить все запросы на вывод (админ)
exports.getAllWithdrawalRequests = async (req, res) => {
  try {
    if (req.user.user_role !== 'admin') {
      return errorResponse(res, 'Только администратор может просматривать все запросы', 403);
    }

    const { status } = req.query;

    let sql = `
      SELECT 
        wr.*,
        u.full_name as user_name,
        u.email as user_email,
        ub.balance as user_balance
      FROM withdrawal_requests wr
      JOIN users u ON wr.user_id = u.id
      LEFT JOIN user_balances ub ON u.id = ub.user_id
    `;

    const params = [];

    if (status) {
      sql += ' WHERE wr.status = ?';
      params.push(status);
    }

    sql += ' ORDER BY wr.created_at DESC';

    const requests = await query(sql, params);

    successResponse(res, requests);
  } catch (error) {
    console.error('Get all withdrawal requests error:', error);
    errorResponse(res, 'Ошибка получения запросов на вывод');
  }
};

// Обработать запрос на вывод (админ)
exports.processWithdrawalRequest = async (req, res) => {
  try {
    if (req.user.user_role !== 'admin') {
      return errorResponse(res, 'Только администратор может обрабатывать запросы', 403);
    }

    const { id } = req.params;
    const { status, admin_comment } = req.body;

    if (!['completed', 'rejected'].includes(status)) {
      return errorResponse(res, 'Неверный статус', 400);
    }

    const request = await query('SELECT * FROM withdrawal_requests WHERE id = ?', [id]);

    if (request.length === 0) {
      return errorResponse(res, 'Запрос не найден', 404);
    }

    if (request[0].status !== 'pending') {
      return errorResponse(res, 'Запрос уже обработан', 400);
    }

    const requestData = request[0];

    // Обновляем статус запроса
    await query(
      `UPDATE withdrawal_requests 
       SET status = ?, admin_comment = ?, processed_by_admin_id = ?, processed_at = NOW()
       WHERE id = ?`,
      [status, admin_comment, req.user.id, id]
    );

    if (status === 'completed') {
      // Создаем транзакцию вывода
      await query(
        `INSERT INTO transactions (user_id, type, amount, description, status, completed_at)
         VALUES (?, 'withdrawal', ?, ?, 'completed', NOW())`,
        [requestData.user_id, requestData.amount, `Вывод средств (${requestData.payment_method})`]
      );

      // Уменьшаем pending_amount
      await query(
        'UPDATE user_balances SET pending_amount = pending_amount - ?, total_withdrawn = total_withdrawn + ? WHERE user_id = ?',
        [requestData.amount, requestData.amount, requestData.user_id]
      );
    } else {
      // Возвращаем средства
      await query(
        'UPDATE user_balances SET balance = balance + ?, pending_amount = pending_amount - ? WHERE user_id = ?',
        [requestData.amount, requestData.amount, requestData.user_id]
      );
    }

    const updatedRequest = await query('SELECT * FROM withdrawal_requests WHERE id = ?', [id]);

    successResponse(res, updatedRequest[0], `Запрос ${status === 'completed' ? 'одобрен' : 'отклонен'}`);
  } catch (error) {
    console.error('Process withdrawal request error:', error);
    errorResponse(res, 'Ошибка обработки запроса');
  }
};

// Получить статистику финансов (админ)
exports.getFinanceStats = async (req, res) => {
  try {
    if (req.user.user_role !== 'admin') {
      return errorResponse(res, 'Только администратор может просматривать статистику', 403);
    }

    const stats = await query(`
      SELECT 
        COUNT(DISTINCT user_id) as total_users_with_balance,
        SUM(balance) as total_platform_balance,
        SUM(total_earned) as total_platform_earned,
        SUM(total_spent) as total_platform_spent,
        SUM(total_withdrawn) as total_platform_withdrawn,
        SUM(pending_amount) as total_pending
      FROM user_balances
    `);

    const transactionStats = await query(`
      SELECT 
        type,
        status,
        COUNT(*) as count,
        SUM(amount) as total_amount
      FROM transactions
      GROUP BY type, status
    `);

    successResponse(res, {
      overview: stats[0],
      transactions_breakdown: transactionStats,
    });
  } catch (error) {
    console.error('Get finance stats error:', error);
    errorResponse(res, 'Ошибка получения статистики');
  }
};
