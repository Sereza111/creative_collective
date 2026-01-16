const { query } = require('../config/database');
const { successResponse, errorResponse } = require('../utils/responseHandler');

// Получить или создать чат для заказа
exports.getOrCreateChat = async (req, res) => {
  try {
    const { orderId } = req.params;
    const userId = req.user.id;

    // Проверяем заказ
    const orders = await query('SELECT * FROM orders WHERE id = ?', [orderId]);
    if (orders.length === 0) {
      return errorResponse(res, 'Заказ не найден', 404);
    }

    const order = orders[0];
    
    // Определяем участников чата
    let participant1Id, participant2Id;
    if (userId === order.client_id) {
      participant1Id = order.client_id;
      participant2Id = order.freelancer_id;
    } else if (userId === order.freelancer_id) {
      participant1Id = order.freelancer_id;
      participant2Id = order.client_id;
    } else {
      return errorResponse(res, 'Вы не участник этого заказа', 403);
    }

    if (!participant2Id) {
      return errorResponse(res, 'Фрилансер еще не назначен на этот заказ', 400);
    }

    // Ищем существующий чат
    let chats = await query(
      `SELECT c.*, 
              u1.full_name as p1_name, u1.email as p1_email, u1.avatar_url as p1_avatar,
              u2.full_name as p2_name, u2.email as p2_email, u2.avatar_url as p2_avatar
       FROM chats c
       LEFT JOIN users u1 ON c.participant1_id = u1.id
       LEFT JOIN users u2 ON c.participant2_id = u2.id
       WHERE c.order_id = ? AND 
             ((c.participant1_id = ? AND c.participant2_id = ?) OR 
              (c.participant1_id = ? AND c.participant2_id = ?))`,
      [orderId, participant1Id, participant2Id, participant2Id, participant1Id]
    );

    let chat;
    if (chats.length === 0) {
      // Создаем новый чат
      const result = await query(
        'INSERT INTO chats (order_id, participant1_id, participant2_id) VALUES (?, ?, ?)',
        [orderId, participant1Id, participant2Id]
      );

      chats = await query(
        `SELECT c.*, 
                u1.full_name as p1_name, u1.email as p1_email, u1.avatar_url as p1_avatar,
                u2.full_name as p2_name, u2.email as p2_email, u2.avatar_url as p2_avatar
         FROM chats c
         LEFT JOIN users u1 ON c.participant1_id = u1.id
         LEFT JOIN users u2 ON c.participant2_id = u2.id
         WHERE c.id = ?`,
        [result.insertId]
      );
      chat = chats[0];
    } else {
      chat = chats[0];
    }

    successResponse(res, chat);
  } catch (error) {
    console.error('Get or create chat error:', error);
    errorResponse(res, 'Ошибка получения чата');
  }
};

// Получить все чаты пользователя
exports.getUserChats = async (req, res) => {
  try {
    const userId = req.user.id;

    const chats = await query(
      `SELECT c.*, 
              o.title as order_title,
              CASE 
                WHEN c.participant1_id = ? THEN c.participant2_id
                ELSE c.participant1_id
              END as other_user_id,
              CASE 
                WHEN c.participant1_id = ? THEN u2.full_name
                ELSE u1.full_name
              END as other_user_name,
              CASE 
                WHEN c.participant1_id = ? THEN u2.email
                ELSE u1.email
              END as other_user_email,
              CASE 
                WHEN c.participant1_id = ? THEN u2.avatar_url
                ELSE u1.avatar_url
              END as other_user_avatar,
              CASE 
                WHEN c.participant1_id = ? THEN c.unread_count_p1
                ELSE c.unread_count_p2
              END as unread_count
       FROM chats c
       LEFT JOIN users u1 ON c.participant1_id = u1.id
       LEFT JOIN users u2 ON c.participant2_id = u2.id
       LEFT JOIN orders o ON c.order_id = o.id
       WHERE c.participant1_id = ? OR c.participant2_id = ?
       ORDER BY c.last_message_at DESC`,
      [userId, userId, userId, userId, userId, userId, userId]
    );

    successResponse(res, chats);
  } catch (error) {
    console.error('Get user chats error:', error);
    errorResponse(res, 'Ошибка получения чатов');
  }
};

// Получить сообщения чата
exports.getChatMessages = async (req, res) => {
  try {
    const { chatId } = req.params;
    const userId = req.user.id;
    const { limit = 50, offset = 0 } = req.query;

    // Проверяем доступ к чату
    const chats = await query(
      'SELECT * FROM chats WHERE id = ? AND (participant1_id = ? OR participant2_id = ?)',
      [chatId, userId, userId]
    );

    if (chats.length === 0) {
      return errorResponse(res, 'Чат не найден или доступ запрещен', 404);
    }

    const messages = await query(
      `SELECT m.*, 
              u.full_name as sender_name, u.email as sender_email, u.avatar_url as sender_avatar
       FROM messages m
       LEFT JOIN users u ON m.sender_id = u.id
       WHERE m.chat_id = ?
       ORDER BY m.created_at DESC
       LIMIT ? OFFSET ?`,
      [chatId, parseInt(limit), parseInt(offset)]
    );

    // Отмечаем сообщения как прочитанные
    await query(
      'UPDATE messages SET is_read = TRUE WHERE chat_id = ? AND sender_id != ? AND is_read = FALSE',
      [chatId, userId]
    );

    // Обновляем счетчик непрочитанных
    const chat = chats[0];
    if (chat.participant1_id === userId) {
      await query('UPDATE chats SET unread_count_p1 = 0 WHERE id = ?', [chatId]);
    } else {
      await query('UPDATE chats SET unread_count_p2 = 0 WHERE id = ?', [chatId]);
    }

    successResponse(res, messages.reverse()); // Возвращаем в хронологическом порядке
  } catch (error) {
    console.error('Get chat messages error:', error);
    errorResponse(res, 'Ошибка получения сообщений');
  }
};

// Отправить сообщение
exports.sendMessage = async (req, res) => {
  try {
    const { chatId } = req.params;
    const { message } = req.body;
    const senderId = req.user.id;

    if (!message || message.trim().length === 0) {
      return errorResponse(res, 'Сообщение не может быть пустым', 400);
    }

    // Проверяем доступ к чату
    const chats = await query(
      'SELECT * FROM chats WHERE id = ? AND (participant1_id = ? OR participant2_id = ?)',
      [chatId, senderId, senderId]
    );

    if (chats.length === 0) {
      return errorResponse(res, 'Чат не найден или доступ запрещен', 404);
    }

    const chat = chats[0];

    // Сохраняем сообщение
    const result = await query(
      'INSERT INTO messages (chat_id, sender_id, message) VALUES (?, ?, ?)',
      [chatId, senderId, message.trim()]
    );

    // Обновляем чат
    const updateFields = {
      last_message: message.trim().substring(0, 100),
      last_message_at: new Date()
    };

    // Увеличиваем счетчик непрочитанных для получателя
    if (chat.participant1_id === senderId) {
      await query(
        'UPDATE chats SET last_message = ?, last_message_at = ?, unread_count_p2 = unread_count_p2 + 1 WHERE id = ?',
        [updateFields.last_message, updateFields.last_message_at, chatId]
      );
    } else {
      await query(
        'UPDATE chats SET last_message = ?, last_message_at = ?, unread_count_p1 = unread_count_p1 + 1 WHERE id = ?',
        [updateFields.last_message, updateFields.last_message_at, chatId]
      );
    }

    // Получаем созданное сообщение с данными отправителя
    const newMessage = await query(
      `SELECT m.*, 
              u.full_name as sender_name, u.email as sender_email, u.avatar_url as sender_avatar
       FROM messages m
       LEFT JOIN users u ON m.sender_id = u.id
       WHERE m.id = ?`,
      [result.insertId]
    );

    successResponse(res, newMessage[0], 'Сообщение отправлено', 201);
  } catch (error) {
    console.error('Send message error:', error);
    errorResponse(res, 'Ошибка отправки сообщения');
  }
};

// Получить количество непрочитанных сообщений
exports.getUnreadCount = async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await query(
      `SELECT SUM(
        CASE 
          WHEN participant1_id = ? THEN unread_count_p1
          ELSE unread_count_p2
        END
      ) as total_unread
      FROM chats
      WHERE participant1_id = ? OR participant2_id = ?`,
      [userId, userId, userId]
    );

    successResponse(res, { unread_count: result[0].total_unread || 0 });
  } catch (error) {
    console.error('Get unread count error:', error);
    errorResponse(res, 'Ошибка получения количества непрочитанных');
  }
};

module.exports = exports;

