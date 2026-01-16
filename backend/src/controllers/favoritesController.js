const { query } = require('../config/database');
const { successResponse, errorResponse } = require('../utils/responseHandler');

// Добавить в избранное
exports.addFavorite = async (req, res) => {
  try {
    const { favorited_type, favorited_id } = req.body;
    const userId = req.user.id;

    // Проверка типа
    if (!['order', 'freelancer'].includes(favorited_type)) {
      return errorResponse(res, 'Неверный тип объекта', 400);
    }

    // Проверка существования
    if (favorited_type === 'order') {
      const order = await query('SELECT id FROM orders WHERE id = ?', [favorited_id]);
      if (order.length === 0) {
        return errorResponse(res, 'Заказ не найден', 404);
      }
    } else if (favorited_type === 'freelancer') {
      const freelancer = await query(
        'SELECT id FROM users WHERE id = ? AND user_role = ?',
        [favorited_id, 'freelancer']
      );
      if (freelancer.length === 0) {
        return errorResponse(res, 'Фрилансер не найден', 404);
      }
    }

    // Добавление в избранное (игнорируем дубликаты)
    await query(
      `INSERT INTO favorites (user_id, favorited_type, favorited_id)
       VALUES (?, ?, ?)
       ON DUPLICATE KEY UPDATE created_at = created_at`,
      [userId, favorited_type, favorited_id]
    );

    successResponse(res, { message: 'Добавлено в избранное' });
  } catch (error) {
    console.error('Add favorite error:', error);
    errorResponse(res, 'Ошибка добавления в избранное');
  }
};

// Удалить из избранного
exports.removeFavorite = async (req, res) => {
  try {
    const { favorited_type, favorited_id } = req.body;
    const userId = req.user.id;

    await query(
      'DELETE FROM favorites WHERE user_id = ? AND favorited_type = ? AND favorited_id = ?',
      [userId, favorited_type, favorited_id]
    );

    successResponse(res, { message: 'Удалено из избранного' });
  } catch (error) {
    console.error('Remove favorite error:', error);
    errorResponse(res, 'Ошибка удаления из избранного');
  }
};

// Получить избранное пользователя
exports.getFavorites = async (req, res) => {
  try {
    const userId = req.user.id;
    const { type } = req.query; // order или freelancer

    let whereClause = 'WHERE f.user_id = ?';
    const params = [userId];

    if (type && ['order', 'freelancer'].includes(type)) {
      whereClause += ' AND f.favorited_type = ?';
      params.push(type);
    }

    const favorites = await query(
      `SELECT 
        f.id,
        f.user_id,
        f.favorited_type,
        f.favorited_id,
        f.created_at,
        CASE 
          WHEN f.favorited_type = 'order' THEN o.title
          WHEN f.favorited_type = 'freelancer' THEN u.full_name
        END as title,
        CASE 
          WHEN f.favorited_type = 'order' THEN o.description
          WHEN f.favorited_type = 'freelancer' THEN u.bio
        END as description,
        CASE 
          WHEN f.favorited_type = 'order' THEN o.budget
          ELSE NULL
        END as budget,
        CASE 
          WHEN f.favorited_type = 'order' THEN o.status
          ELSE NULL
        END as status,
        CASE 
          WHEN f.favorited_type = 'freelancer' THEN u.average_rating
          ELSE NULL
        END as rating,
        CASE 
          WHEN f.favorited_type = 'freelancer' THEN u.reviews_count
          ELSE NULL
        END as reviews_count
       FROM favorites f
       LEFT JOIN orders o ON f.favorited_type = 'order' AND f.favorited_id = o.id
       LEFT JOIN users u ON f.favorited_type = 'freelancer' AND f.favorited_id = u.id
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

// Проверить, в избранном ли объект
exports.checkFavorite = async (req, res) => {
  try {
    const userId = req.user.id;
    const { favorited_type, favorited_id } = req.query;

    const result = await query(
      'SELECT id FROM favorites WHERE user_id = ? AND favorited_type = ? AND favorited_id = ?',
      [userId, favorited_type, favorited_id]
    );

    successResponse(res, { is_favorite: result.length > 0 });
  } catch (error) {
    console.error('Check favorite error:', error);
    errorResponse(res, 'Ошибка проверки избранного');
  }
};

