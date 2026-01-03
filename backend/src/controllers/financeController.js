const { query } = require('../config/database');
const { successResponse, errorResponse, generateUUID, getPagination, paginatedResponse } = require('../utils/helpers');

// Получить финансовую информацию пользователя
exports.getUserFinance = async (req, res) => {
  try {
    const { user_id } = req.params;
    
    // Проверяем доступ (пользователь может видеть только свои финансы, кроме админов)
    if (req.user.role !== 'admin' && req.user.id !== user_id) {
      return errorResponse(res, 'Недостаточно прав', 403);
    }
    
    const finances = await query(
      `SELECT f.*, u.username, u.full_name 
       FROM finances f
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
       WHERE t.finance_id = ?
       ORDER BY t.date DESC
       LIMIT 10`,
      [finances[0].id]
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
    if (req.user.role !== 'admin' && req.user.id !== user_id) {
      return errorResponse(res, 'Недостаточно прав', 403);
    }
    
    const { limit: limitNum, offset } = getPagination(page, limit);
    
    // Получаем finance_id
    const finances = await query('SELECT id FROM finances WHERE user_id = ?', [user_id]);
    if (finances.length === 0) {
      return errorResponse(res, 'Финансовая информация не найдена', 404);
    }
    
    const finance_id = finances[0].id;
    
    let whereConditions = ['t.finance_id = ?'];
    let params = [finance_id];
    
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
    
    // Получаем finance_id
    const finances = await query('SELECT id FROM finances WHERE user_id = ?', [user_id]);
    if (finances.length === 0) {
      return errorResponse(res, 'Финансовая информация не найдена', 404);
    }
    
    const finance_id = finances[0].id;
    const transactionId = generateUUID();
    
    await query(
      `INSERT INTO transactions (id, finance_id, type, amount, description, category, date)
       VALUES (?, ?, ?, ?, ?, ?, NOW())`,
      [transactionId, finance_id, type, amount, description, category]
    );
    
    // Обновляем баланс вручную (триггеры удалены)
    if (type === 'earned' || type === 'bonus') {
      await query(
        `UPDATE finances SET balance = balance + ?, total_earned = total_earned + ? WHERE id = ?`,
        [amount, amount, finance_id]
      );
    } else if (type === 'spent' || type === 'penalty') {
      await query(
        `UPDATE finances SET balance = balance - ?, total_spent = total_spent + ? WHERE id = ?`,
        [amount, amount, finance_id]
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
    
    const finances = await query('SELECT id FROM finances WHERE user_id = ?', [user_id]);
    if (finances.length === 0) {
      return errorResponse(res, 'Финансовая информация не найдена', 404);
    }
    
    const finance_id = finances[0].id;
    
    let dateCondition = '';
    let params = [finance_id];
    
    if (start_date && end_date) {
      dateCondition = 'AND date BETWEEN ? AND ?';
      params.push(start_date, end_date);
    }
    
    // Статистика по типам транзакций
    const typeStats = await query(
      `SELECT type, SUM(amount) as total, COUNT(*) as count
       FROM transactions
       WHERE finance_id = ? ${dateCondition}
       GROUP BY type`,
      params
    );
    
    // Статистика по категориям
    const categoryStats = await query(
      `SELECT category, SUM(amount) as total, COUNT(*) as count
       FROM transactions
       WHERE finance_id = ? ${dateCondition} AND category IS NOT NULL
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

