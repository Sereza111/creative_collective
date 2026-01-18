const { query } = require('../config/database');
const { successResponse, errorResponse } = require('../utils/responseHandler');

// Получить активный документ по типу
exports.getActiveDocument = async (req, res) => {
  try {
    const { type } = req.params;

    const documents = await query(
      'SELECT * FROM legal_documents WHERE document_type = ? AND is_active = TRUE ORDER BY created_at DESC LIMIT 1',
      [type]
    );

    if (documents.length === 0) {
      return errorResponse(res, 'Документ не найден', 404);
    }

    successResponse(res, documents[0]);
  } catch (error) {
    console.error('Get document error:', error);
    errorResponse(res, 'Ошибка получения документа');
  }
};

// Получить все активные документы
exports.getAllActiveDocuments = async (req, res) => {
  try {
    const documents = await query(
      `SELECT id, document_type, version, title, created_at 
       FROM legal_documents 
       WHERE is_active = TRUE 
       ORDER BY document_type, created_at DESC`
    );

    // Группируем по типу и берем последнюю версию
    const latestDocs = {};
    documents.forEach(doc => {
      if (!latestDocs[doc.document_type]) {
        latestDocs[doc.document_type] = doc;
      }
    });

    successResponse(res, Object.values(latestDocs));
  } catch (error) {
    console.error('Get documents error:', error);
    errorResponse(res, 'Ошибка получения документов');
  }
};

// Подписать документ
exports.signDocument = async (req, res) => {
  try {
    const { document_id, document_type, order_id } = req.body;
    const userId = req.user.id;
    const ipAddress = req.ip || req.connection.remoteAddress;
    const userAgent = req.get('User-Agent');

    // Получаем версию документа
    const documents = await query('SELECT version FROM legal_documents WHERE id = ?', [document_id]);
    
    if (documents.length === 0) {
      return errorResponse(res, 'Документ не найден', 404);
    }

    const documentVersion = documents[0].version;

    // Проверяем, не подписан ли уже
    const existing = await query(
      'SELECT id FROM user_agreements WHERE user_id = ? AND document_id = ? AND order_id <=> ?',
      [userId, document_id, order_id || null]
    );

    if (existing.length > 0) {
      return successResponse(res, { id: existing[0].id }, 'Документ уже подписан');
    }

    // Создаем подпись
    const result = await query(
      `INSERT INTO user_agreements (user_id, document_id, document_type, document_version, ip_address, user_agent, order_id)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [userId, document_id, document_type, documentVersion, ipAddress, userAgent, order_id || null]
    );

    successResponse(res, { id: result.insertId }, 'Документ подписан', 201);
  } catch (error) {
    console.error('Sign document error:', error);
    errorResponse(res, 'Ошибка подписания документа');
  }
};

// Проверить, подписал ли пользователь документ
exports.checkUserAgreement = async (req, res) => {
  try {
    const { document_type, order_id } = req.query;
    const userId = req.user.id;

    let sql = 'SELECT * FROM user_agreements WHERE user_id = ? AND document_type = ?';
    const params = [userId, document_type];

    if (order_id) {
      sql += ' AND order_id = ?';
      params.push(order_id);
    }

    sql += ' ORDER BY agreed_at DESC LIMIT 1';

    const agreements = await query(sql, params);

    successResponse(res, {
      signed: agreements.length > 0,
      agreement: agreements.length > 0 ? agreements[0] : null
    });
  } catch (error) {
    console.error('Check agreement error:', error);
    errorResponse(res, 'Ошибка проверки подписи');
  }
};

// Получить историю подписанных документов пользователя
exports.getUserAgreements = async (req, res) => {
  try {
    const userId = req.user.id;

    const agreements = await query(
      `SELECT ua.*, ld.title, ld.content
       FROM user_agreements ua
       LEFT JOIN legal_documents ld ON ua.document_id = ld.id
       WHERE ua.user_id = ?
       ORDER BY ua.agreed_at DESC`,
      [userId]
    );

    successResponse(res, agreements);
  } catch (error) {
    console.error('Get user agreements error:', error);
    errorResponse(res, 'Ошибка получения подписей');
  }
};

// Отметить просмотр отклика заказчиком
exports.markApplicationViewed = async (req, res) => {
  try {
    const { applicationId } = req.params;
    const userId = req.user.id;

    // Получаем информацию об отклике
    const applications = await query(
      'SELECT oa.*, o.client_id FROM order_applications oa LEFT JOIN orders o ON oa.order_id = o.id WHERE oa.id = ?',
      [applicationId]
    );

    if (applications.length === 0) {
      return errorResponse(res, 'Отклик не найден', 404);
    }

    const application = applications[0];

    // Проверяем, что это заказчик
    if (application.client_id !== userId) {
      return errorResponse(res, 'Только заказчик может отметить просмотр', 403);
    }

    // Обновляем отклик
    await query(
      'UPDATE order_applications SET viewed_by_client = TRUE, viewed_at = NOW() WHERE id = ?',
      [applicationId]
    );

    // Записываем в историю просмотров
    await query(
      'INSERT INTO application_views (application_id, order_id, client_id) VALUES (?, ?, ?)',
      [applicationId, application.order_id, userId]
    );

    successResponse(res, null, 'Просмотр отмечен');
  } catch (error) {
    console.error('Mark viewed error:', error);
    errorResponse(res, 'Ошибка отметки просмотра');
  }
};

// Автоматический возврат средств за игнорированные отклики
exports.processIgnoredApplications = async (req, res) => {
  try {
    // Только админ может запускать
    if (req.user.user_role !== 'admin') {
      return errorResponse(res, 'Только администратор', 403);
    }

    // Находим отклики старше 7 дней без просмотра или ответа
    const ignoredApplications = await query(`
      SELECT oa.id, oa.freelancer_id, oa.order_id, o.client_id
      FROM order_applications oa
      LEFT JOIN orders o ON oa.order_id = o.id
      WHERE oa.status = 'pending'
        AND oa.viewed_by_client = FALSE
        AND oa.created_at < DATE_SUB(NOW(), INTERVAL 7 DAY)
        AND o.status = 'published'
        AND NOT EXISTS (
          SELECT 1 FROM application_refunds ar WHERE ar.application_id = oa.id
        )
    `);

    let refundedCount = 0;
    const applicationFee = 50; // Стоимость отклика

    for (const app of ignoredApplications) {
      try {
        // Возвращаем деньги фрилансеру
        await query(
          'UPDATE user_balances SET balance = balance + ? WHERE user_id = ?',
          [applicationFee, app.freelancer_id]
        );

        // Создаем транзакцию возврата
        const transactionResult = await query(
          `INSERT INTO transactions (user_id, type, amount, description, status, order_id)
           VALUES (?, 'refund', ?, ?, 'completed', ?)`,
          [app.freelancer_id, applicationFee, 'Возврат за игнорированный отклик', app.order_id]
        );

        // Записываем возврат
        await query(
          `INSERT INTO application_refunds (application_id, freelancer_id, order_id, refund_amount, reason, transaction_id)
           VALUES (?, ?, ?, ?, 'ignored_by_client', ?)`,
          [app.id, app.freelancer_id, app.order_id, applicationFee, transactionResult.insertId]
        );

        // Обновляем статус отклика
        await query(
          'UPDATE order_applications SET status = ? WHERE id = ?',
          ['refunded', app.id]
        );

        refundedCount++;
      } catch (refundError) {
        console.error(`Error refunding application ${app.id}:`, refundError);
      }
    }

    successResponse(res, {
      processed: ignoredApplications.length,
      refunded: refundedCount
    }, `Обработано ${refundedCount} возвратов`);
  } catch (error) {
    console.error('Process ignored applications error:', error);
    errorResponse(res, 'Ошибка обработки игнорированных откликов');
  }
};

