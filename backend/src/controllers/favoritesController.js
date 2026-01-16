const { query } = require('../config/database');
const { successResponse, errorResponse } = require('../utils/responseHandler');

// Добавить в избранное
exports.addFavorite = async (req, res) => {
  try {
    const userId = req.user.id;
    const { item_type, item_id } = req.body;

    if (!item_type || !item_id) {
      return errorResponse(res, 'Необходимо указать тип и ID элемента', 400);
    }

    if (!['order', 'freelancer'].includes(item_type)) {
      return errorResponse(res, 'Неверный тип элемента', 400);
    }

    // Проверяем существование элемента
    if (item_type === 'order') {
      const orders = await query('SELECT id FROM orders WHERE id = ?', [item_id]);
      if (orders.length === 0) {
        return errorResponse(res, 'Заказ не найден', 404);
      }
    } else if (item_type === 'freelancer') {
      const users = await query('SELECT id FROM users WHERE id = ? AND user_role = "freelancer"', [item_id]);
      if (users.length === 0) {
        return errorResponse(res, 'Фрилансер не найден', 404);
      }
    }

    // Добавляем в избранное (игнорируем дубликаты)
    await query(
      'INSERT IGNORE INTO favorites (user_id, item_type, item_id) VALUES (?, ?, ?)',
      [userId, item_type, item_id]
    );

    successResponse(res, { message: 'Добавлено в избранное' }, 'Успешно', 201);
  } catch (error) {
    console.error('Add favorite error:', error);
    errorResponse(res, 'Ошибка добавления в избранное');
  }
};

// Удалить из избранного
exports.removeFavorite = async (req, res) => {
  try {
    const userId = req.user.id;
    const { item_type, item_id } = req.body;

    if (!item_type || !item_id) {
      return errorResponse(res, 'Необходимо указать тип и ID элемента', 400);
    }

    await query(
      'DELETE FROM favorites WHERE user_id = ? AND item_type = ? AND item_id = ?',
      [userId, item_type, item_id]
    );

    successResponse(res, { message: 'Удалено из избранного' });
  } catch (error) {
    console.error('Remove favorite error:', error);
    errorResponse(res, 'Ошибка удаления из избранного');
  }
};

// Получить избранное
exports.getFavorites = async (req, res) => {
  try {
    const userId = req.user.id;
    const { item_type } = req.query;

    let whereClause = 'WHERE f.user_id = ?';
    const params = [userId];

    if (item_type && ['order', 'freelancer'].includes(item_type)) {
      whereClause += ' AND f.item_type = ?';
      params.push(item_type);
    }

    const favorites = await query(
      `SELECT f.*, 
              CASE 
                WHEN f.item_type = 'order' THEN o.title
                WHEN f.item_type = 'freelancer' THEN u.full_name
              END as item_name,
              CASE 
                WHEN f.item_type = 'order' THEN o.budget
                ELSE NULL
              END as item_budget,
              CASE 
                WHEN f.item_type = 'freelancer' THEN u.average_rating
                ELSE NULL
              END as item_rating,
              CASE 
                WHEN f.item_type = 'freelancer' THEN u.is_verified
                ELSE NULL
              END as item_is_verified,
              CASE 
                WHEN f.item_type = 'freelancer' THEN u.avatar_url
                ELSE NULL
              END as item_avatar
       FROM favorites f
       LEFT JOIN orders o ON f.item_type = 'order' AND f.item_id = o.id
       LEFT JOIN users u ON f.item_type = 'freelancer' AND f.item_id = u.id
       ${whereClause}
       ORDER BY f.created_at DESC`,
      params
    );

    successResponse(res, favorites);
  } catch (error) {
    console.error('Get favorites error:', error);
    errorResponse(res, 'Ошибка получения избранного');
  }
};

// Проверить, находится ли элемент в избранном
exports.checkFavorite = async (req, res) => {
  try {
    const userId = req.user.id;
    const { item_type, item_id } = req.query;

    if (!item_type || !item_id) {
      return errorResponse(res, 'Необходимо указать тип и ID элемента', 400);
    }

    const favorites = await query(
      'SELECT id FROM favorites WHERE user_id = ? AND item_type = ? AND item_id = ?',
      [userId, item_type, item_id]
    );

    successResponse(res, { is_favorite: favorites.length > 0 });
  } catch (error) {
    console.error('Check favorite error:', error);
    errorResponse(res, 'Ошибка проверки избранного');
  }
};

module.exports = exports;
