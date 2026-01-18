const { query } = require('../config/database');

/**
 * Автоматический возврат средств за игнорированные отклики
 * Запускается по расписанию (cron job)
 */
async function refundIgnoredApplications() {
  console.log('[REFUND JOB] Starting refund process for ignored applications...');

  try {
    // Находим отклики старше 7 дней без просмотра или ответа
    const ignoredApplications = await query(`
      SELECT oa.id, oa.freelancer_id, oa.order_id, o.client_id, o.title as order_title
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

    console.log(`[REFUND JOB] Found ${ignoredApplications.length} ignored applications`);

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
          [
            app.freelancer_id,
            applicationFee,
            `Возврат за игнорированный отклик на заказ "${app.order_title}"`,
            app.order_id
          ]
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

        // Создаем уведомление фрилансеру
        await query(
          `INSERT INTO notifications (user_id, type, entity_type, entity_id, message)
           VALUES (?, 'admin_message', 'order', ?, ?)`,
          [
            app.freelancer_id,
            app.order_id,
            `Возврат 50 ₽ за игнорированный отклик на заказ "${app.order_title}"`
          ]
        );

        // Создаем уведомление заказчику (предупреждение)
        await query(
          `INSERT INTO notifications (user_id, type, entity_type, entity_id, message)
           VALUES (?, 'admin_message', 'order', ?, ?)`,
          [
            app.client_id,
            app.order_id,
            `⚠️ Вы игнорировали отклик на заказ "${app.order_title}". Средства возвращены фрилансеру.`
          ]
        );

        refundedCount++;
        console.log(`[REFUND JOB] Refunded application ${app.id} for freelancer ${app.freelancer_id}`);
      } catch (refundError) {
        console.error(`[REFUND JOB] Error refunding application ${app.id}:`, refundError);
      }
    }

    console.log(`[REFUND JOB] Completed. Refunded ${refundedCount} out of ${ignoredApplications.length} applications`);
    
    return {
      processed: ignoredApplications.length,
      refunded: refundedCount
    };
  } catch (error) {
    console.error('[REFUND JOB] Error:', error);
    throw error;
  }
}

module.exports = { refundIgnoredApplications };

