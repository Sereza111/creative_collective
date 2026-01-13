const { query } = require('../config/database');
const { successResponse, errorResponse, generateUUID, getPagination, paginatedResponse } = require('../utils/helpers');

// Получить финансовую информацию пользователя
exports.getUserFinance = async (req, res) => {
  try {
    const { user_id } = req.params;
    
    // Проверяем доступ (пользователь может видеть только свои финансы, кроме админов)
    if (req.user.role !== 'admin' && req.user.id !== parseInt(user_id)) {
      return errorResponse(res, 'Недостаточно прав', 403);
    }
    
    const finances = await query(
      `SELECT f.*, u.full_name 
       FROM finance f
       LEFT JOIN users u ON f.user_id = u.id
       WHERE f.user_id = ?`,
      [user_id]
    );
    
    if (finances.length === 0) {
      return errorResponse(res, 'Финансовая информация не найдена', 404);
    }
    
    // Получаем последние транзакции
    const transactions = await query(
      `SELECT t.*
       FROM transactions t
       WHERE t.user_id = ?
       ORDER BY t.date DESC
       LIMIT 10`,
      [user_id]
    );
    
    successResponse(res, {
      ...finances[0],
      recent_transactions: transactions
    });
    
  } catch (error) {
    console.error('Get finance error:', error);
    errorResponse(res, 'Ошибка при получении финансовой информации');
  }
};

// Получить все транзакции пользователя
exports.getUserTransactions = async (req, res) => {
  try {
    const { user_id } = req.params;
    const { page = 1, limit = 20, type, category, start_date, end_date } = req.query;
    
    // Проверяем доступ
    if (req.user.role !== 'admin' && req.user.id !== parseInt(user_id)) {
      return errorResponse(res, 'Недостаточно прав', 403);
    }
    
    const { limit: limitNum, offset } = getPagination(page, limit);
    
    let whereConditions = ['t.user_id = ?'];
    let params = [user_id];
    
    if (type) {
      whereConditions.push('t.type = ?');
      params.push(type);
    }
    
    if (category) {
      whereConditions.push('t.category = ?');
      params.push(category);
    }
    
    if (start_date) {
      whereConditions.push('t.date >= ?');
      params.push(start_date);
    }
    
    if (end_date) {
      whereConditions.push('t.date <= ?');
      params.push(end_date);
    }
    
    const whereClause = 'WHERE ' + whereConditions.join(' AND ');
    
    const countResult = await query(
      `SELECT COUNT(*) as total FROM transactions t ${whereClause}`,
      params
    );
    const total = countResult[0].total;
    
    const transactions = await query(
      `SELECT t.*
       FROM transactions t
       ${whereClause}
       ORDER BY t.date DESC
       LIMIT ? OFFSET ?`,
      [...params, limitNum, offset]
    );
    
    successResponse(res, paginatedResponse(transactions, total, page, limit));
    
  } catch (error) {
    console.error('Get transactions error:', error);
    errorResponse(res, 'Ошибка при получении транзакций');
  }
};

// Создать новую транзакцию
exports.createTransaction = async (req, res) => {
  try {
    const { user_id } = req.params;
    const { type, amount, description, project_id, category } = req.body;
    
    // Проверяем доступ
    if (req.user.role !== 'admin' && req.user.id !== user_id) {
      return errorResponse(res, 'Недостаточно прав', 403);
    }
    
    const result = await query(
      `INSERT INTO transactions (user_id, type, amount, description, category, date)
       VALUES (?, ?, ?, ?, ?, NOW())`,
      [user_id, type, amount, description, category]
    );
    
    const transactionId = result.insertId;
    
    // Обновляем баланс вручную (триггеры удалены)
    if (type === 'income') {
      await query(
        `UPDATE finance SET balance = balance + ?, total_earned = total_earned + ? WHERE user_id = ?`,
        [amount, amount, user_id]
      );
    } else if (type === 'expense') {
      await query(
        `UPDATE finance SET balance = balance - ?, total_spent = total_spent + ? WHERE user_id = ?`,
        [amount, amount, user_id]
      );
    }
    
    const newTransaction = await query(
      `SELECT t.*
       FROM transactions t
       WHERE t.id = ?`,
      [transactionId]
    );
    
    // Создаем уведомление
    const notifMessage = type === 'earned' || type === 'bonus' 
      ? `Получено: ₽${amount}` 
      : `Списано: ₽${amount}`;
    
    await query(
      'INSERT INTO notifications (id, user_id, title, message, type, entity_id) VALUES (?, ?, ?, ?, ?, ?)',
      [generateUUID(), user_id, 'Финансовая операция', notifMessage, 'finance', transactionId]
    );
    
    successResponse(res, newTransaction[0], 'Транзакция создана', 201);
    
  } catch (error) {
    console.error('Create transaction error:', error);
    errorResponse(res, 'Ошибка при создании транзакции');
  }
};

// Получить статистику по финансам
exports.getFinanceStats = async (req, res) => {
  try {
    const { user_id } = req.params;
    const { start_date, end_date } = req.query;
    
    // Проверяем доступ
    if (req.user.role !== 'admin' && req.user.id !== user_id) {
      return errorResponse(res, 'Недостаточно прав', 403);
    }
    
    const finances = await query('SELECT id FROM finance WHERE user_id = ?', [user_id]);
    if (finances.length === 0) {
      return errorResponse(res, 'Финансовая информация не найдена', 404);
    }
    
    let dateCondition = '';
    let params = [user_id];
    
    if (start_date && end_date) {
      dateCondition = 'AND date BETWEEN ? AND ?';
      params.push(start_date, end_date);
    }
    
    // Статистика по типам транзакций
    const typeStats = await query(
      `SELECT type, SUM(amount) as total, COUNT(*) as count
       FROM transactions
       WHERE user_id = ? ${dateCondition}
       GROUP BY type`,
      params
    );
    
    // Статистика по категориям
    const categoryStats = await query(
      `SELECT category, SUM(amount) as total, COUNT(*) as count
       FROM transactions
       WHERE user_id = ? ${dateCondition} AND category IS NOT NULL
       GROUP BY category
       ORDER BY total DESC`,
      params
    );
    
    successResponse(res, {
      by_type: typeStats,
      by_category: categoryStats
    });
    
  } catch (error) {
    console.error('Get finance stats error:', error);
    errorResponse(res, 'Ошибка при получении статистики');
  }
};

