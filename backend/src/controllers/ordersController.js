const { query } = require('../config/database');
const { successResponse, errorResponse } = require('../utils/responseHandler');

// Получить все заказы (маркетплейс)
exports.getAllOrders = async (req, res) => {
  try {
    const { status, category } = req.query;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;

    let sql = `
      SELECT o.*, 
             c.full_name as client_name, c.email as client_email,
             f.full_name as freelancer_name, f.email as freelancer_email,
             (SELECT COUNT(*) FROM order_applications WHERE order_id = o.id) as applications_count
      FROM orders o
      LEFT JOIN users c ON o.client_id = c.id
      LEFT JOIN users f ON o.freelancer_id = f.id
      WHERE 1=1
    `;

    const params = [];

    if (status) {
      sql += ' AND o.status = ?';
      params.push(status);
    }

    if (category) {
      sql += ' AND o.category = ?';
      params.push(category);
    }

    sql += ' ORDER BY o.created_at DESC LIMIT ? OFFSET ?';
    params.push(limit, offset);

    const orders = await query(sql, params);
    successResponse(res, orders);
  } catch (error) {
    console.error('Get orders error:', error);
    errorResponse(res, 'Ошибка получения заказов');
  }
};

// Получить заказ по ID
exports.getOrderById = async (req, res) => {
  try {
    const { id } = req.params;

    const orders = await query(
      `SELECT o.*, 
              c.full_name as client_name, c.email as client_email, c.avatar_url as client_avatar,
              f.full_name as freelancer_name, f.email as freelancer_email, f.avatar_url as freelancer_avatar,
              (SELECT COUNT(*) FROM order_applications WHERE order_id = o.id) as applications_count
       FROM orders o
       LEFT JOIN users c ON o.client_id = c.id
       LEFT JOIN users f ON o.freelancer_id = f.id
       WHERE o.id = ?`,
      [id]
    );

    if (orders.length === 0) {
      return errorResponse(res, 'Заказ не найден', 404);
    }

    successResponse(res, orders[0]);
  } catch (error) {
    console.error('Get order error:', error);
    errorResponse(res, 'Ошибка получения заказа');
  }
};

// Создать заказ (только для client)
exports.createOrder = async (req, res) => {
  try {
    const { title, description, budget, deadline, category } = req.body;
    const clientId = req.user.id;

    // Проверка роли
    if (req.user.user_role !== 'client' && req.user.user_role !== 'admin') {
      return errorResponse(res, 'Только заказчики могут создавать заказы', 403);
    }

    const result = await query(
      `INSERT INTO orders (title, description, budget, deadline, category, client_id, status)
       VALUES (?, ?, ?, ?, ?, ?, 'published')`,
      [title, description || null, budget, deadline, category || null, clientId]
    );

    const newOrder = await query(
      `SELECT o.*, 
              c.full_name as client_name, c.email as client_email
       FROM orders o
       LEFT JOIN users c ON o.client_id = c.id
       WHERE o.id = ?`,
      [result.insertId]
    );

    successResponse(res, newOrder[0], 'Заказ создан', 201);
  } catch (error) {
    console.error('Create order error:', error);
    errorResponse(res, 'Ошибка создания заказа');
  }
};

// Обновить заказ
exports.updateOrder = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, budget, deadline, category, status } = req.body;
    const userId = req.user.id;

    // Проверка прав
    const orders = await query('SELECT * FROM orders WHERE id = ?', [id]);
    if (orders.length === 0) {
      return errorResponse(res, 'Заказ не найден', 404);
    }

    const order = orders[0];
    if (order.client_id !== userId && req.user.user_role !== 'admin') {
      return errorResponse(res, 'Нет прав для редактирования этого заказа', 403);
    }

    const updates = {};
    if (title !== undefined) updates.title = title;
    if (description !== undefined) updates.description = description;
    if (budget !== undefined) updates.budget = budget;
    if (deadline !== undefined) updates.deadline = deadline;
    if (category !== undefined) updates.category = category;
    if (status !== undefined) updates.status = status;

    if (Object.keys(updates).length === 0) {
      return errorResponse(res, 'Нет данных для обновления', 400);
    }

    const updateQuery = `UPDATE orders SET ${Object.keys(updates).map(key => `${key} = ?`).join(', ')} WHERE id = ?`;
    const updateValues = [...Object.values(updates), id];

    await query(updateQuery, updateValues);

    const updatedOrder = await query(
      `SELECT o.*, 
              c.full_name as client_name, c.email as client_email,
              f.full_name as freelancer_name, f.email as freelancer_email
       FROM orders o
       LEFT JOIN users c ON o.client_id = c.id
       LEFT JOIN users f ON o.freelancer_id = f.id
       WHERE o.id = ?`,
      [id]
    );

    successResponse(res, updatedOrder[0], 'Заказ обновлен');
  } catch (error) {
    console.error('Update order error:', error);
    errorResponse(res, 'Ошибка обновления заказа');
  }
};

// Удалить заказ
exports.deleteOrder = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const orders = await query('SELECT * FROM orders WHERE id = ?', [id]);
    if (orders.length === 0) {
      return errorResponse(res, 'Заказ не найден', 404);
    }

    const order = orders[0];
    if (order.client_id !== userId && req.user.user_role !== 'admin') {
      return errorResponse(res, 'Нет прав для удаления этого заказа', 403);
    }

    await query('DELETE FROM orders WHERE id = ?', [id]);
    successResponse(res, null, 'Заказ удален');
  } catch (error) {
    console.error('Delete order error:', error);
    errorResponse(res, 'Ошибка удаления заказа');
  }
};

// Откликнуться на заказ (для freelancer)
exports.applyToOrder = async (req, res) => {
  try {
    const { id } = req.params;
    const { message, proposed_budget, proposed_deadline } = req.body;
    const freelancerId = req.user.id;

    // Проверка роли
    if (req.user.user_role !== 'freelancer' && req.user.user_role !== 'admin') {
      return errorResponse(res, 'Только фрилансеры могут откликаться на заказы', 403);
    }

    // Проверка существования заказа
    const orders = await query('SELECT * FROM orders WHERE id = ?', [id]);
    if (orders.length === 0) {
      return errorResponse(res, 'Заказ не найден', 404);
    }

    const order = orders[0];
    if (order.status !== 'published') {
      return errorResponse(res, 'На этот заказ нельзя откликнуться', 400);
    }

    // Проверка, не откликался ли уже
    const existingApplications = await query(
      'SELECT * FROM order_applications WHERE order_id = ? AND freelancer_id = ?',
      [id, freelancerId]
    );

    if (existingApplications.length > 0) {
      return errorResponse(res, 'Вы уже откликнулись на этот заказ', 400);
    }

    const result = await query(
      `INSERT INTO order_applications (order_id, freelancer_id, message, proposed_budget, proposed_deadline)
       VALUES (?, ?, ?, ?, ?)`,
      [id, freelancerId, message || null, proposed_budget || null, proposed_deadline || null]
    );

    const newApplication = await query(
      `SELECT oa.*, 
              f.full_name as freelancer_name, f.email as freelancer_email, f.avatar_url as freelancer_avatar
       FROM order_applications oa
       LEFT JOIN users f ON oa.freelancer_id = f.id
       WHERE oa.id = ?`,
      [result.insertId]
    );

    successResponse(res, newApplication[0], 'Отклик отправлен', 201);
  } catch (error) {
    console.error('Apply to order error:', error);
    errorResponse(res, 'Ошибка отправки отклика');
  }
};

// Получить отклики на заказ
exports.getOrderApplications = async (req, res) => {
  try {
    const { id } = req.params;

    const applications = await query(
      `SELECT oa.*, 
              f.full_name as freelancer_name, f.email as freelancer_email, f.avatar_url as freelancer_avatar
       FROM order_applications oa
       LEFT JOIN users f ON oa.freelancer_id = f.id
       WHERE oa.order_id = ?
       ORDER BY oa.created_at DESC`,
      [id]
    );

    successResponse(res, applications);
  } catch (error) {
    console.error('Get applications error:', error);
    errorResponse(res, 'Ошибка получения откликов');
  }
};

// Получить мои отклики (для фрилансера)
exports.getMyApplications = async (req, res) => {
  try {
    const freelancerId = req.user.id;

    const applications = await query(
      `SELECT oa.*, 
              o.title as order_title, o.description as order_description, 
              o.budget as order_budget, o.deadline as order_deadline, 
              o.status as order_status, o.category as order_category
       FROM order_applications oa
       LEFT JOIN orders o ON oa.order_id = o.id
       WHERE oa.freelancer_id = ?
       ORDER BY oa.created_at DESC`,
      [freelancerId]
    );

    successResponse(res, applications);
  } catch (error) {
    console.error('Get my applications error:', error);
    errorResponse(res, 'Ошибка получения откликов');
  }
};

// Принять отклик (назначить фрилансера)
exports.acceptApplication = async (req, res) => {
  try {
    const { id, applicationId } = req.params;
    const userId = req.user.id;

    // Проверка заказа
    const orders = await query('SELECT * FROM orders WHERE id = ?', [id]);
    if (orders.length === 0) {
      return errorResponse(res, 'Заказ не найден', 404);
    }

    const order = orders[0];
    if (order.client_id !== userId && req.user.user_role !== 'admin') {
      return errorResponse(res, 'Нет прав для назначения исполнителя', 403);
    }

    // Получить отклик
    const applications = await query(
      'SELECT * FROM order_applications WHERE id = ? AND order_id = ?',
      [applicationId, id]
    );

    if (applications.length === 0) {
      return errorResponse(res, 'Отклик не найден', 404);
    }

    const application = applications[0];

    // Обновить заказ
    await query(
      'UPDATE orders SET freelancer_id = ?, status = ? WHERE id = ?',
      [application.freelancer_id, 'in_progress', id]
    );

    // Обновить статус отклика
    await query(
      'UPDATE order_applications SET status = ? WHERE id = ?',
      ['accepted', applicationId]
    );

    // Отклонить остальные отклики
    await query(
      'UPDATE order_applications SET status = ? WHERE order_id = ? AND id != ?',
      ['rejected', id, applicationId]
    );

    successResponse(res, null, 'Исполнитель назначен');
  } catch (error) {
    console.error('Accept application error:', error);
    errorResponse(res, 'Ошибка назначения исполнителя');
  }
};

