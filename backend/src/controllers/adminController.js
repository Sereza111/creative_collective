const { query } = require('../config/database');
const { successResponse, errorResponse } = require('../utils/responseHandler');

// Получить всех пользователей (только админ)
exports.getAllUsers = async (req, res) => {
  try {
    if (req.user.user_role !== 'admin') {
      return errorResponse(res, 'Недостаточно прав', 403);
    }

    const { page = 1, limit = 50, search, role } = req.query;
    const offset = (page - 1) * limit;

    let whereConditions = [];
    let params = [];

    if (search) {
      whereConditions.push('(full_name LIKE ? OR email LIKE ?)');
      params.push(`%${search}%`, `%${search}%`);
    }

    if (role) {
      whereConditions.push('user_role = ?');
      params.push(role);
    }

    const whereClause = whereConditions.length > 0 
      ? 'WHERE ' + whereConditions.join(' AND ')
      : '';

    const users = await query(
      `SELECT id, email, full_name, avatar_url, user_role, is_active, is_verified, 
              average_rating, reviews_count, created_at, last_login
       FROM users
       ${whereClause}
       ORDER BY created_at DESC
       LIMIT ? OFFSET ?`,
      [...params, parseInt(limit), parseInt(offset)]
    );

    const countResult = await query(
      `SELECT COUNT(*) as total FROM users ${whereClause}`,
      params
    );

    successResponse(res, {
      users,
      total: countResult[0].total,
      page: parseInt(page),
      limit: parseInt(limit),
    });
  } catch (error) {
    console.error('Get all users error:', error);
    errorResponse(res, 'Ошибка получения пользователей');
  }
};

// Получить статистику платформы (только админ)
exports.getPlatformStats = async (req, res) => {
  try {
    if (req.user.user_role !== 'admin') {
      return errorResponse(res, 'Недостаточно прав', 403);
    }

    // Общая статистика
    const stats = {};

    // Пользователи
    const usersStats = await query(
      `SELECT 
        COUNT(*) as total_users,
        SUM(CASE WHEN user_role = 'client' THEN 1 ELSE 0 END) as clients,
        SUM(CASE WHEN user_role = 'freelancer' THEN 1 ELSE 0 END) as freelancers,
        SUM(CASE WHEN is_verified = TRUE THEN 1 ELSE 0 END) as verified_users
       FROM users`
    );
    stats.users = usersStats[0];

    // Заказы
    const ordersStats = await query(
      `SELECT 
        COUNT(*) as total_orders,
        SUM(CASE WHEN status = 'open' THEN 1 ELSE 0 END) as open_orders,
        SUM(CASE WHEN status = 'in_progress' THEN 1 ELSE 0 END) as in_progress_orders,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_orders,
        SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) as cancelled_orders,
        AVG(budget) as average_budget
       FROM orders`
    );
    stats.orders = ordersStats[0];

    // Отзывы
    const reviewsStats = await query(
      `SELECT 
        COUNT(*) as total_reviews,
        AVG(rating) as average_rating
       FROM reviews`
    );
    stats.reviews = reviewsStats[0];

    // Чаты
    const chatsStats = await query(
      `SELECT COUNT(*) as total_chats FROM chats`
    );
    stats.chats = chatsStats[0];

    successResponse(res, stats);
  } catch (error) {
    console.error('Get platform stats error:', error);
    errorResponse(res, 'Ошибка получения статистики');
  }
};

// Верифицировать пользователя (только админ)
exports.verifyUser = async (req, res) => {
  try {
    // Проверка прав администратора
    if (req.user.user_role !== 'admin') {
      return errorResponse(res, 'Недостаточно прав', 403);
    }

    const { userId } = req.params;
    const { verification_note } = req.body;

    console.log(`✅ Верификация пользователя ${userId} администратором ${req.user.id}`);

    await query(
      'UPDATE users SET is_verified = TRUE, verified_at = NOW(), verification_note = ? WHERE id = ?',
      [verification_note || 'Верифицирован администратором', userId]
    );

    successResponse(res, null, 'Пользователь верифицирован');
  } catch (error) {
    console.error('Verify user error:', error);
    errorResponse(res, 'Ошибка верификации пользователя');
  }
};

// Отменить верификацию пользователя (только админ)
exports.unverifyUser = async (req, res) => {
  try {
    if (req.user.user_role !== 'admin') {
      return errorResponse(res, 'Недостаточно прав', 403);
    }

    const { userId } = req.params;

    console.log(`❌ Отмена верификации пользователя ${userId} администратором ${req.user.id}`);

    await query(
      'UPDATE users SET is_verified = FALSE, verified_at = NULL, verification_note = NULL WHERE id = ?',
      [userId]
    );

    successResponse(res, null, 'Верификация отменена');
  } catch (error) {
    console.error('Unverify user error:', error);
    errorResponse(res, 'Ошибка отмены верификации');
  }
};

module.exports = exports;

