const { query } = require('../config/database');
const { successResponse, errorResponse } = require('../utils/responseHandler');
const { newId } = require('../utils/id');

// Создать отзыв
exports.createReview = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { rating, comment } = req.body;
    const reviewerId = req.user.id;

    console.log(`⭐ Создание отзыва для заказа ${orderId} от пользователя ${reviewerId}`);

    // Валидация рейтинга
    if (!rating || rating < 1 || rating > 5) {
      return errorResponse(res, 'Рейтинг должен быть от 1 до 5', 400);
    }

    // Проверяем заказ
    const orders = await query('SELECT * FROM orders WHERE id = ?', [orderId]);
    if (orders.length === 0) {
      return errorResponse(res, 'Заказ не найден', 404);
    }

    const order = orders[0];

    // Проверяем, что заказ завершен
    if (order.status !== 'completed') {
      return errorResponse(res, 'Можно оставить отзыв только на завершенный заказ', 400);
    }

    // Определяем, кому оставляется отзыв
    let revieweeId;
    if (reviewerId === order.client_id) {
      // Клиент оставляет отзыв фрилансеру
      revieweeId = order.freelancer_id;
    } else if (reviewerId === order.freelancer_id) {
      // Фрилансер оставляет отзыв клиенту
      revieweeId = order.client_id;
    } else {
      return errorResponse(res, 'Вы не участник этого заказа', 403);
    }

    // Проверяем, не оставлял ли пользователь уже отзыв на этот заказ
    const existingReviews = await query(
      'SELECT id FROM reviews WHERE order_id = ? AND reviewer_id = ?',
      [orderId, reviewerId]
    );

    if (existingReviews.length > 0) {
      return errorResponse(res, 'Вы уже оставили отзыв на этот заказ', 400);
    }

    // Создаем отзыв
    const reviewId = newId();
    await query(
      'INSERT INTO reviews (id, order_id, reviewer_id, reviewee_id, rating, comment) VALUES (?, ?, ?, ?, ?, ?)',
      [reviewId, orderId, reviewerId, revieweeId, rating, comment]
    );

    // Получаем созданный отзыв с данными пользователей
    const newReview = await query(
      `SELECT r.*, 
              reviewer.full_name as reviewer_name, reviewer.email as reviewer_email, reviewer.avatar_url as reviewer_avatar,
              reviewee.full_name as reviewee_name, reviewee.email as reviewee_email
       FROM reviews r
       LEFT JOIN users reviewer ON r.reviewer_id = reviewer.id
       LEFT JOIN users reviewee ON r.reviewee_id = reviewee.id
       WHERE r.id = ?`,
      [reviewId]
    );

    console.log(`✅ Отзыв создан с ID: ${reviewId}`);
    successResponse(res, newReview[0], 'Отзыв успешно добавлен', 201);
  } catch (error) {
    console.error('Create review error:', error);
    errorResponse(res, 'Ошибка создания отзыва');
  }
};

// Получить отзывы для пользователя
exports.getUserReviews = async (req, res) => {
  try {
    const { userId } = req.params;
    const { limit = 20, offset = 0 } = req.query;

    console.log(`📋 Получение отзывов для пользователя ${userId}`);

    const reviews = await query(
      `SELECT r.*, 
              o.title as order_title,
              reviewer.full_name as reviewer_name, reviewer.email as reviewer_email, 
              reviewer.avatar_url as reviewer_avatar, reviewer.user_role as reviewer_role
       FROM reviews r
       LEFT JOIN orders o ON r.order_id = o.id
       LEFT JOIN users reviewer ON r.reviewer_id = reviewer.id
       WHERE r.reviewee_id = ?
       ORDER BY r.created_at DESC
       LIMIT ? OFFSET ?`,
      [userId, parseInt(limit), parseInt(offset)]
    );

    console.log(`✅ Найдено отзывов: ${reviews.length}`);
    successResponse(res, reviews);
  } catch (error) {
    console.error('Get user reviews error:', error);
    errorResponse(res, 'Ошибка получения отзывов');
  }
};

// Получить статистику рейтинга пользователя
exports.getUserRating = async (req, res) => {
  try {
    const { userId } = req.params;

    const users = await query(
      'SELECT average_rating, reviews_count FROM users WHERE id = ?',
      [userId]
    );

    if (users.length === 0) {
      return errorResponse(res, 'Пользователь не найден', 404);
    }

    // Получаем распределение рейтингов
    const distribution = await query(
      `SELECT rating, COUNT(*) as count 
       FROM reviews 
       WHERE reviewee_id = ? 
       GROUP BY rating 
       ORDER BY rating DESC`,
      [userId]
    );

    const ratingDistribution = {
      5: 0,
      4: 0,
      3: 0,
      2: 0,
      1: 0,
    };

    distribution.forEach((item) => {
      ratingDistribution[item.rating] = item.count;
    });

    successResponse(res, {
      average_rating: users[0].average_rating,
      reviews_count: users[0].reviews_count,
      rating_distribution: ratingDistribution,
    });
  } catch (error) {
    console.error('Get user rating error:', error);
    errorResponse(res, 'Ошибка получения рейтинга');
  }
};

// Получить отзыв для конкретного заказа
exports.getOrderReviews = async (req, res) => {
  try {
    const { orderId } = req.params;

    const reviews = await query(
      `SELECT r.*, 
              reviewer.full_name as reviewer_name, reviewer.email as reviewer_email, 
              reviewer.avatar_url as reviewer_avatar, reviewer.user_role as reviewer_role,
              reviewee.full_name as reviewee_name, reviewee.email as reviewee_email
       FROM reviews r
       LEFT JOIN users reviewer ON r.reviewer_id = reviewer.id
       LEFT JOIN users reviewee ON r.reviewee_id = reviewee.id
       WHERE r.order_id = ?
       ORDER BY r.created_at DESC`,
      [orderId]
    );

    successResponse(res, reviews);
  } catch (error) {
    console.error('Get order reviews error:', error);
    errorResponse(res, 'Ошибка получения отзывов');
  }
};

// Обновить отзыв
exports.updateReview = async (req, res) => {
  try {
    const { reviewId } = req.params;
    const { rating, comment } = req.body;
    const userId = req.user.id;

    // Валидация рейтинга
    if (rating && (rating < 1 || rating > 5)) {
      return errorResponse(res, 'Рейтинг должен быть от 1 до 5', 400);
    }

    // Проверяем, принадлежит ли отзыв пользователю
    const reviews = await query(
      'SELECT * FROM reviews WHERE id = ? AND reviewer_id = ?',
      [reviewId, userId]
    );

    if (reviews.length === 0) {
      return errorResponse(res, 'Отзыв не найден или у вас нет прав на его редактирование', 404);
    }

    // Обновляем отзыв
    await query(
      'UPDATE reviews SET rating = ?, comment = ? WHERE id = ?',
      [rating || reviews[0].rating, comment !== undefined ? comment : reviews[0].comment, reviewId]
    );

    // Получаем обновленный отзыв
    const updatedReview = await query(
      `SELECT r.*, 
              reviewer.full_name as reviewer_name, reviewer.email as reviewer_email, reviewer.avatar_url as reviewer_avatar,
              reviewee.full_name as reviewee_name, reviewee.email as reviewee_email
       FROM reviews r
       LEFT JOIN users reviewer ON r.reviewer_id = reviewer.id
       LEFT JOIN users reviewee ON r.reviewee_id = reviewee.id
       WHERE r.id = ?`,
      [reviewId]
    );

    successResponse(res, updatedReview[0], 'Отзыв успешно обновлен');
  } catch (error) {
    console.error('Update review error:', error);
    errorResponse(res, 'Ошибка обновления отзыва');
  }
};

// Удалить отзыв
exports.deleteReview = async (req, res) => {
  try {
    const { reviewId } = req.params;
    const userId = req.user.id;

    // Проверяем, принадлежит ли отзыв пользователю или пользователь админ
    const reviews = await query(
      'SELECT * FROM reviews WHERE id = ?',
      [reviewId]
    );

    if (reviews.length === 0) {
      return errorResponse(res, 'Отзыв не найден', 404);
    }

    if (reviews[0].reviewer_id !== userId && req.user.user_role !== 'admin') {
      return errorResponse(res, 'У вас нет прав на удаление этого отзыва', 403);
    }

    await query('DELETE FROM reviews WHERE id = ?', [reviewId]);

    successResponse(res, null, 'Отзыв успешно удален');
  } catch (error) {
    console.error('Delete review error:', error);
    errorResponse(res, 'Ошибка удаления отзыва');
  }
};

module.exports = exports;

