const { query } = require('../config/database');
const { successResponse, errorResponse } = require('../utils/responseHandler');
const { createNotification } = require('./notificationsController');

// Создать спор
exports.createDispute = async (req, res) => {
  try {
    const { order_id, reason, description } = req.body;
    const userId = req.user.id;

    // Проверяем, существует ли заказ
    const order = await query('SELECT * FROM orders WHERE id = ?', [order_id]);
    if (order.length === 0) {
      return errorResponse(res, 'Заказ не найден', 404);
    }

    // Проверяем, что пользователь является участником заказа
    const orderData = order[0];
    if (orderData.client_id !== userId && orderData.freelancer_id !== userId) {
      return errorResponse(res, 'Вы не являетесь участником этого заказа', 403);
    }

    // Определяем против кого спор
    const againstUserId = orderData.client_id === userId ? orderData.freelancer_id : orderData.client_id;

    // Проверяем, нет ли уже открытого спора по этому заказу
    const existingDispute = await query(
      'SELECT * FROM disputes WHERE order_id = ? AND status IN ("open", "in_review")',
      [order_id]
    );
    if (existingDispute.length > 0) {
      return errorResponse(res, 'По этому заказу уже существует открытый спор', 409);
    }

    // Создаем спор
    const result = await query(
      'INSERT INTO disputes (order_id, opened_by_user_id, against_user_id, reason, description) VALUES (?, ?, ?, ?, ?)',
      [order_id, userId, againstUserId, reason, description]
    );

    const disputeId = result.insertId;

    // Записываем в историю
    await query(
      'INSERT INTO dispute_history (dispute_id, action, performed_by_user_id, details) VALUES (?, ?, ?, ?)',
      [disputeId, 'opened', userId, `Спор открыт по причине: ${reason}`]
    );

    // Отправляем уведомление второй стороне
    await createNotification(
      againstUserId,
      'dispute_opened',
      'Открыт спор',
      `По заказу "${orderData.title}" открыт спор`,
      order_id,
      'dispute'
    );

    // Получаем созданный спор
    const dispute = await query(
      `SELECT d.*, 
        u1.full_name as opened_by_name,
        u2.full_name as against_name,
        o.title as order_title
       FROM disputes d
       JOIN users u1 ON d.opened_by_user_id = u1.id
       JOIN users u2 ON d.against_user_id = u2.id
       JOIN orders o ON d.order_id = o.id
       WHERE d.id = ?`,
      [disputeId]
    );

    successResponse(res, dispute[0], 'Спор создан', 201);
  } catch (error) {
    console.error('Create dispute error:', error);
    errorResponse(res, 'Ошибка создания спора');
  }
};

// Получить спор по ID
exports.getDispute = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const userRole = req.user.user_role;

    const dispute = await query(
      `SELECT d.*, 
        u1.full_name as opened_by_name,
        u2.full_name as against_name,
        u3.full_name as resolved_by_name,
        o.title as order_title,
        o.client_id,
        o.freelancer_id
       FROM disputes d
       JOIN users u1 ON d.opened_by_user_id = u1.id
       JOIN users u2 ON d.against_user_id = u2.id
       LEFT JOIN users u3 ON d.resolved_by_admin_id = u3.id
       JOIN orders o ON d.order_id = o.id
       WHERE d.id = ?`,
      [id]
    );

    if (dispute.length === 0) {
      return errorResponse(res, 'Спор не найден', 404);
    }

    const disputeData = dispute[0];

    // Проверяем доступ (участник спора или админ)
    if (
      userRole !== 'admin' &&
      disputeData.opened_by_user_id !== userId &&
      disputeData.against_user_id !== userId
    ) {
      return errorResponse(res, 'Нет доступа к этому спору', 403);
    }

    // Получаем сообщения спора
    const messages = await query(
      `SELECT dm.*, u.full_name as user_name
       FROM dispute_messages dm
       JOIN users u ON dm.user_id = u.id
       WHERE dm.dispute_id = ?
       ORDER BY dm.created_at ASC`,
      [id]
    );

    // Получаем историю
    const history = await query(
      `SELECT dh.*, u.full_name as performed_by_name
       FROM dispute_history dh
       JOIN users u ON dh.performed_by_user_id = u.id
       WHERE dh.dispute_id = ?
       ORDER BY dh.created_at DESC`,
      [id]
    );

    successResponse(res, {
      dispute: disputeData,
      messages,
      history,
    });
  } catch (error) {
    console.error('Get dispute error:', error);
    errorResponse(res, 'Ошибка получения спора');
  }
};

// Получить споры пользователя
exports.getUserDisputes = async (req, res) => {
  try {
    const userId = req.user.id;
    const { status } = req.query;

    let sql = `
      SELECT d.*, 
        u1.full_name as opened_by_name,
        u2.full_name as against_name,
        o.title as order_title
       FROM disputes d
       JOIN users u1 ON d.opened_by_user_id = u1.id
       JOIN users u2 ON d.against_user_id = u2.id
       JOIN orders o ON d.order_id = o.id
       WHERE (d.opened_by_user_id = ? OR d.against_user_id = ?)
    `;

    const params = [userId, userId];

    if (status) {
      sql += ' AND d.status = ?';
      params.push(status);
    }

    sql += ' ORDER BY d.created_at DESC';

    const disputes = await query(sql, params);

    successResponse(res, disputes);
  } catch (error) {
    console.error('Get user disputes error:', error);
    errorResponse(res, 'Ошибка получения споров');
  }
};

// Добавить сообщение в спор
exports.addDisputeMessage = async (req, res) => {
  try {
    const { id } = req.params;
    const { message, attachments } = req.body;
    const userId = req.user.id;

    // Проверяем, существует ли спор и имеет ли пользователь доступ
    const dispute = await query(
      'SELECT * FROM disputes WHERE id = ?',
      [id]
    );

    if (dispute.length === 0) {
      return errorResponse(res, 'Спор не найден', 404);
    }

    const disputeData = dispute[0];

    if (
      req.user.user_role !== 'admin' &&
      disputeData.opened_by_user_id !== userId &&
      disputeData.against_user_id !== userId
    ) {
      return errorResponse(res, 'Нет доступа к этому спору', 403);
    }

    // Добавляем сообщение
    const result = await query(
      'INSERT INTO dispute_messages (dispute_id, user_id, message, attachments) VALUES (?, ?, ?, ?)',
      [id, userId, message, attachments ? JSON.stringify(attachments) : null]
    );

    // Записываем в историю
    await query(
      'INSERT INTO dispute_history (dispute_id, action, performed_by_user_id) VALUES (?, ?, ?)',
      [id, 'message_added', userId]
    );

    // Отправляем уведомление другой стороне
    const notifyUserId = disputeData.opened_by_user_id === userId 
      ? disputeData.against_user_id 
      : disputeData.opened_by_user_id;

    const order = await query('SELECT title FROM orders WHERE id = ?', [disputeData.order_id]);
    await createNotification(
      notifyUserId,
      'dispute_opened',
      'Новое сообщение в споре',
      `Новое сообщение в споре по заказу "${order[0].title}"`,
      disputeData.order_id,
      'dispute'
    );

    // Получаем добавленное сообщение
    const addedMessage = await query(
      `SELECT dm.*, u.full_name as user_name
       FROM dispute_messages dm
       JOIN users u ON dm.user_id = u.id
       WHERE dm.id = ?`,
      [result.insertId]
    );

    successResponse(res, addedMessage[0], 'Сообщение добавлено', 201);
  } catch (error) {
    console.error('Add dispute message error:', error);
    errorResponse(res, 'Ошибка добавления сообщения');
  }
};

// Разрешить спор (только админ)
exports.resolveDispute = async (req, res) => {
  try {
    const { id } = req.params;
    const { resolution, winner_id } = req.body;
    const adminId = req.user.id;

    // Проверяем, что пользователь - админ
    if (req.user.user_role !== 'admin') {
      return errorResponse(res, 'Только админ может разрешать споры', 403);
    }

    // Проверяем, существует ли спор
    const dispute = await query('SELECT * FROM disputes WHERE id = ?', [id]);
    if (dispute.length === 0) {
      return errorResponse(res, 'Спор не найден', 404);
    }

    const disputeData = dispute[0];

    // Обновляем спор
    await query(
      `UPDATE disputes 
       SET status = 'resolved', resolution = ?, resolved_by_admin_id = ?, resolved_at = NOW()
       WHERE id = ?`,
      [resolution, adminId, id]
    );

    // Записываем в историю
    await query(
      'INSERT INTO dispute_history (dispute_id, action, old_value, new_value, performed_by_user_id, details) VALUES (?, ?, ?, ?, ?, ?)',
      [id, 'resolved', disputeData.status, 'resolved', adminId, resolution]
    );

    // Отправляем уведомления обеим сторонам
    const order = await query('SELECT title FROM orders WHERE id = ?', [disputeData.order_id]);
    const orderTitle = order[0].title;

    await createNotification(
      disputeData.opened_by_user_id,
      'dispute_resolved',
      'Спор разрешен',
      `Спор по заказу "${orderTitle}" разрешен администрацией`,
      disputeData.order_id,
      'dispute'
    );

    await createNotification(
      disputeData.against_user_id,
      'dispute_resolved',
      'Спор разрешен',
      `Спор по заказу "${orderTitle}" разрешен администрацией`,
      disputeData.order_id,
      'dispute'
    );

    // Получаем обновленный спор
    const updatedDispute = await query(
      `SELECT d.*, 
        u1.full_name as opened_by_name,
        u2.full_name as against_name,
        u3.full_name as resolved_by_name,
        o.title as order_title
       FROM disputes d
       JOIN users u1 ON d.opened_by_user_id = u1.id
       JOIN users u2 ON d.against_user_id = u2.id
       LEFT JOIN users u3 ON d.resolved_by_admin_id = u3.id
       JOIN orders o ON d.order_id = o.id
       WHERE d.id = ?`,
      [id]
    );

    successResponse(res, updatedDispute[0], 'Спор разрешен');
  } catch (error) {
    console.error('Resolve dispute error:', error);
    errorResponse(res, 'Ошибка разрешения спора');
  }
};

// Получить все споры (только админ)
exports.getAllDisputes = async (req, res) => {
  try {
    // Проверяем, что пользователь - админ
    if (req.user.user_role !== 'admin') {
      return errorResponse(res, 'Только админ может просматривать все споры', 403);
    }

    const { status } = req.query;

    let sql = `
      SELECT d.*, 
        u1.full_name as opened_by_name,
        u2.full_name as against_name,
        u3.full_name as resolved_by_name,
        o.title as order_title
       FROM disputes d
       JOIN users u1 ON d.opened_by_user_id = u1.id
       JOIN users u2 ON d.against_user_id = u2.id
       LEFT JOIN users u3 ON d.resolved_by_admin_id = u3.id
       JOIN orders o ON d.order_id = o.id
       WHERE 1=1
    `;

    const params = [];

    if (status) {
      sql += ' AND d.status = ?';
      params.push(status);
    }

    sql += ' ORDER BY d.created_at DESC';

    const disputes = await query(sql, params);

    successResponse(res, disputes);
  } catch (error) {
    console.error('Get all disputes error:', error);
    errorResponse(res, 'Ошибка получения споров');
  }
};

