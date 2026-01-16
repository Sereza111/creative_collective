const { query } = require('../config/database');
const { successResponse, errorResponse } = require('../utils/responseHandler');

// Получить или создать чат для заказа
exports.getOrCreateChat = async (req, res) => {
  try {
    const { orderId } = req.params;
    const userId = req.user.id;
    console.log(`💬 Получение/создание чата для заказа ${orderId}, пользователь ${userId}`);

    // Проверяем заказ
    const orders = await query('SELECT * FROM orders WHERE id = ?', [orderId]);
    if (orders.length === 0) {
      return errorResponse(res, 'Заказ не найден', 404);
    }

    const order = orders[0];
    console.log(`📦 Заказ найден: client_id=${order.client_id}, freelancer_id=${order.freelancer_id}`);
    
    // Проверяем доступ
    if (userId !== order.client_id && userId !== order.freelancer_id) {
      return errorResponse(res, 'Вы не участник этого заказа', 403);
    }

    if (!order.freelancer_id) {
      return errorResponse(res, 'Фрилансер еще не назначен на этот заказ', 400);
    }

    // Ищем существующий чат
    let chats = await query(
      `SELECT id FROM chats WHERE order_id = ?`,
      [orderId]
    );

    let chatId;
    if (chats.length === 0) {
      console.log('➕ Создаем новый чат');
      // Создаем новый чат
      const result = await query(
        'INSERT INTO chats (order_id, client_id, freelancer_id) VALUES (?, ?, ?)',
        [orderId, order.client_id, order.freelancer_id]
      );
      chatId = result.insertId;
      console.log(`✅ Чат создан с ID: ${chatId}`);
    } else {
      chatId = chats[0].id;
      console.log(`✅ Найден существующий чат с ID: ${chatId}`);
    }

    // Получаем полную информацию о чате в том же формате, что getUserChats
    const fullChatInfo = await query(
      `SELECT c.*, 
              o.title as order_title,
              CASE 
                WHEN c.client_id = ? THEN c.freelancer_id
                ELSE c.client_id
              END as other_user_id,
              CASE 
                WHEN c.client_id = ? THEN u2.full_name
                ELSE u1.full_name
              END as other_user_name,
              CASE 
                WHEN c.client_id = ? THEN u2.email
                ELSE u1.email
              END as other_user_email,
              CASE 
                WHEN c.client_id = ? THEN u2.avatar_url
                ELSE u1.avatar_url
              END as other_user_avatar,
              0 as unread_count
       FROM chats c
       LEFT JOIN users u1 ON c.client_id = u1.id
       LEFT JOIN users u2 ON c.freelancer_id = u2.id
       LEFT JOIN orders o ON c.order_id = o.id
       WHERE c.id = ?`,
      [userId, userId, userId, userId, chatId]
    );

    successResponse(res, fullChatInfo[0]);
  } catch (error) {
    console.error('Get or create chat error:', error);
    errorResponse(res, 'Ошибка получения чата');
  }
};

// Получить все чаты пользователя
exports.getUserChats = async (req, res) => {
  try {
    const userId = req.user.id;
    console.log(`📨 Получение чатов для пользователя ${userId}`);

    const chats = await query(
      `SELECT c.*, 
              o.title as order_title,
              CASE 
                WHEN c.client_id = ? THEN c.freelancer_id
                ELSE c.client_id
              END as other_user_id,
              CASE 
                WHEN c.client_id = ? THEN u2.full_name
                ELSE u1.full_name
              END as other_user_name,
              CASE 
                WHEN c.client_id = ? THEN u2.email
                ELSE u1.email
              END as other_user_email,
              CASE 
                WHEN c.client_id = ? THEN u2.avatar_url
                ELSE u1.avatar_url
              END as other_user_avatar,
              (SELECT COUNT(*) FROM messages WHERE chat_id = c.id AND sender_id != ? AND is_read = FALSE) as unread_count
       FROM chats c
       LEFT JOIN users u1 ON c.client_id = u1.id
       LEFT JOIN users u2 ON c.freelancer_id = u2.id
       LEFT JOIN orders o ON c.order_id = o.id
       WHERE c.client_id = ? OR c.freelancer_id = ?
       ORDER BY COALESCE(c.last_message_at, c.created_at) DESC`,
      [userId, userId, userId, userId, userId, userId, userId]
    );

    console.log(`✅ Найдено чатов: ${chats.length}`);
    if (chats.length > 0) {
      console.log('Первый чат:', JSON.stringify(chats[0], null, 2));
    }

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
      'SELECT * FROM chats WHERE id = ? AND (client_id = ? OR freelancer_id = ?)',
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

    // Счетчиков непрочитанных больше нет - они вычисляются динамически

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
    console.log(`📤 Отправка сообщения в чат ${chatId} от пользователя ${senderId}`);

    if (!message || message.trim().length === 0) {
      return errorResponse(res, 'Сообщение не может быть пустым', 400);
    }

    // Проверяем доступ к чату
    const chats = await query(
      'SELECT * FROM chats WHERE id = ? AND (client_id = ? OR freelancer_id = ?)',
      [chatId, senderId, senderId]
    );

    if (chats.length === 0) {
      return errorResponse(res, 'Чат не найден или доступ запрещен', 404);
    }

    console.log(`✅ Доступ к чату разрешен`);

    // Сохраняем сообщение
    const result = await query(
      'INSERT INTO messages (chat_id, sender_id, message) VALUES (?, ?, ?)',
      [chatId, senderId, message.trim()]
    );

    console.log(`✅ Сообщение сохранено с ID: ${result.insertId}`);

    // Обновляем чат (last_message и last_message_at)
    await query(
      'UPDATE chats SET last_message = ?, last_message_at = NOW() WHERE id = ?',
      [message.trim().substring(0, 100), chatId]
    );

    console.log(`✅ Чат обновлен (last_message, last_message_at)`);

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
      `SELECT COUNT(*) as total_unread
       FROM messages m
       INNER JOIN chats c ON m.chat_id = c.id
       WHERE (c.client_id = ? OR c.freelancer_id = ?)
         AND m.sender_id != ?
         AND m.is_read = FALSE`,
      [userId, userId, userId]
    );

    successResponse(res, { unread_count: result[0].total_unread || 0 });
  } catch (error) {
    console.error('Get unread count error:', error);
    errorResponse(res, 'Ошибка получения количества непрочитанных');
  }
};

module.exports = exports;

