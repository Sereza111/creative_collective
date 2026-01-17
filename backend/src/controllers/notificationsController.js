const { query } = require('../config/database');
const { successResponse, errorResponse } = require('../utils/responseHandler');

// Создание уведомления
exports.createNotification = async (userId, type, title, message, relatedId = null, relatedType = null) => {
  try {
    const result = await query(
      `INSERT INTO notifications (user_id, type, title, message, related_id, related_type) 
       VALUES (?, ?, ?, ?, ?, ?)`,
      [userId, type, title, message, relatedId, relatedType]
    );
    return result.insertId;
  } catch (error) {
    console.error('Create notification error:', error);
    throw error;
  }
};

// Получить все уведомления пользователя
exports.getUserNotifications = async (req, res) => {
  try {
    const userId = req.user.id;
    const { limit = 50, offset = 0, unread_only = 'false' } = req.query;

    let sql = `
      SELECT 
        n.*,
        CASE 
          WHEN n.related_type = 'order' THEN o.title
          WHEN n.related_type = 'application' THEN o2.title
          ELSE NULL
        END as related_title
      FROM notifications n
      LEFT JOIN orders o ON n.related_type = 'order' AND n.related_id = o.id
      LEFT JOIN order_applications oa ON n.related_type = 'application' AND n.related_id = oa.id
      LEFT JOIN orders o2 ON oa.order_id = o2.id
      WHERE n.user_id = ?
    `;

    const params = [userId];

    if (unread_only === 'true') {
      sql += ' AND n.is_read = FALSE';
    }

    sql += ' ORDER BY n.created_at DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit), parseInt(offset));

    const notifications = await query(sql, params);

    // Получить количество непрочитанных
    const unreadCount = await query(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = FALSE',
      [userId]
    );

    successResponse(res, {
      notifications,
      unread_count: unreadCount[0].count,
      total: notifications.length,
    });
  } catch (error) {
    console.error('Get notifications error:', error);
    errorResponse(res, 'Ошибка получения уведомлений');
  }
};

// Получить количество непрочитанных уведомлений
exports.getUnreadCount = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await query(
      'SELECT COUNT(*) as count FROM notifications WHERE user_id = ? AND is_read = FALSE',
      [userId]
    );

    successResponse(res, { unread_count: result[0].count });
  } catch (error) {
    console.error('Get unread count error:', error);
    errorResponse(res, 'Ошибка получения количества уведомлений');
  }
};

// Отметить уведомление как прочитанное
exports.markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Проверяем, что уведомление принадлежит пользователю
    const notification = await query(
      'SELECT * FROM notifications WHERE id = ? AND user_id = ?',
      [id, userId]
    );

    if (notification.length === 0) {
      return errorResponse(res, 'Уведомление не найдено', 404);
    }

    await query(
      'UPDATE notifications SET is_read = TRUE, read_at = NOW() WHERE id = ?',
      [id]
    );

    successResponse(res, { message: 'Уведомление отмечено как прочитанное' });
  } catch (error) {
    console.error('Mark as read error:', error);
    errorResponse(res, 'Ошибка обновления уведомления');
  }
};

// Отметить все уведомления как прочитанные
exports.markAllAsRead = async (req, res) => {
  try {
    const userId = req.user.id;

    await query(
      'UPDATE notifications SET is_read = TRUE, read_at = NOW() WHERE user_id = ? AND is_read = FALSE',
      [userId]
    );

    successResponse(res, { message: 'Все уведомления отмечены как прочитанные' });
  } catch (error) {
    console.error('Mark all as read error:', error);
    errorResponse(res, 'Ошибка обновления уведомлений');
  }
};

// Удалить уведомление
exports.deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Проверяем, что уведомление принадлежит пользователю
    const notification = await query(
      'SELECT * FROM notifications WHERE id = ? AND user_id = ?',
      [id, userId]
    );

    if (notification.length === 0) {
      return errorResponse(res, 'Уведомление не найдено', 404);
    }

    await query('DELETE FROM notifications WHERE id = ?', [id]);

    successResponse(res, { message: 'Уведомление удалено' });
  } catch (error) {
    console.error('Delete notification error:', error);
    errorResponse(res, 'Ошибка удаления уведомления');
  }
};

// Получить настройки уведомлений
exports.getNotificationSettings = async (req, res) => {
  try {
    const userId = req.user.id;

    let settings = await query(
      'SELECT * FROM notification_settings WHERE user_id = ?',
      [userId]
    );

    // Если настроек нет, создаем дефолтные
    if (settings.length === 0) {
      await query(
        'INSERT INTO notification_settings (user_id) VALUES (?)',
        [userId]
      );
      settings = await query(
        'SELECT * FROM notification_settings WHERE user_id = ?',
        [userId]
      );
    }

    successResponse(res, settings[0]);
  } catch (error) {
    console.error('Get settings error:', error);
    errorResponse(res, 'Ошибка получения настроек');
  }
};

// Обновить настройки уведомлений
exports.updateNotificationSettings = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      email_enabled,
      push_enabled,
      order_notifications,
      application_notifications,
      message_notifications,
      review_notifications,
      dispute_notifications,
    } = req.body;

    // Проверяем, есть ли настройки
    let settings = await query(
      'SELECT * FROM notification_settings WHERE user_id = ?',
      [userId]
    );

    if (settings.length === 0) {
      // Создаем новые настройки
      await query(
        `INSERT INTO notification_settings 
         (user_id, email_enabled, push_enabled, order_notifications, application_notifications, 
          message_notifications, review_notifications, dispute_notifications) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          userId,
          email_enabled ?? true,
          push_enabled ?? true,
          order_notifications ?? true,
          application_notifications ?? true,
          message_notifications ?? true,
          review_notifications ?? true,
          dispute_notifications ?? true,
        ]
      );
    } else {
      // Обновляем существующие
      const updates = [];
      const values = [];

      if (email_enabled !== undefined) {
        updates.push('email_enabled = ?');
        values.push(email_enabled);
      }
      if (push_enabled !== undefined) {
        updates.push('push_enabled = ?');
        values.push(push_enabled);
      }
      if (order_notifications !== undefined) {
        updates.push('order_notifications = ?');
        values.push(order_notifications);
      }
      if (application_notifications !== undefined) {
        updates.push('application_notifications = ?');
        values.push(application_notifications);
      }
      if (message_notifications !== undefined) {
        updates.push('message_notifications = ?');
        values.push(message_notifications);
      }
      if (review_notifications !== undefined) {
        updates.push('review_notifications = ?');
        values.push(review_notifications);
      }
      if (dispute_notifications !== undefined) {
        updates.push('dispute_notifications = ?');
        values.push(dispute_notifications);
      }

      if (updates.length > 0) {
        values.push(userId);
        await query(
          `UPDATE notification_settings SET ${updates.join(', ')} WHERE user_id = ?`,
          values
        );
      }
    }

    // Получаем обновленные настройки
    settings = await query(
      'SELECT * FROM notification_settings WHERE user_id = ?',
      [userId]
    );

    successResponse(res, settings[0], 'Настройки обновлены');
  } catch (error) {
    console.error('Update settings error:', error);
    errorResponse(res, 'Ошибка обновления настроек');
  }
};

// Вспомогательная функция для создания уведомлений при различных событиях
exports.notifyOrderCreated = async (freelancerId, orderId, orderTitle) => {
  await exports.createNotification(
    freelancerId,
    'order_created',
    'Новый заказ',
    `Создан новый заказ: "${orderTitle}"`,
    orderId,
    'order'
  );
};

exports.notifyApplicationReceived = async (clientId, orderId, orderTitle, freelancerName) => {
  await exports.createNotification(
    clientId,
    'application_received',
    'Новый отклик',
    `${freelancerName} откликнулся на ваш заказ "${orderTitle}"`,
    orderId,
    'order'
  );
};

exports.notifyApplicationAccepted = async (freelancerId, orderId, orderTitle) => {
  await exports.createNotification(
    freelancerId,
    'application_accepted',
    'Отклик принят',
    `Ваш отклик на заказ "${orderTitle}" принят!`,
    orderId,
    'order'
  );
};

exports.notifyApplicationRejected = async (freelancerId, orderId, orderTitle) => {
  await exports.createNotification(
    freelancerId,
    'application_rejected',
    'Отклик отклонен',
    `Ваш отклик на заказ "${orderTitle}" отклонен`,
    orderId,
    'order'
  );
};

exports.notifyOrderCompleted = async (userId, orderId, orderTitle) => {
  await exports.createNotification(
    userId,
    'order_completed',
    'Заказ завершен',
    `Заказ "${orderTitle}" завершен`,
    orderId,
    'order'
  );
};

exports.notifyReviewReceived = async (userId, orderId, orderTitle, rating) => {
  await exports.createNotification(
    userId,
    'review_received',
    'Новый отзыв',
    `Вы получили отзыв (${rating}★) за заказ "${orderTitle}"`,
    orderId,
    'review'
  );
};

