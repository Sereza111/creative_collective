const cron = require('node-cron');
const { refundIgnoredApplications } = require('./refundIgnoredApplications');

/**
 * Инициализация всех запланированных задач
 */
function initScheduler() {
  console.log('[SCHEDULER] Initializing scheduled jobs...');

  // Запускаем возврат за игнорированные отклики каждый день в 03:00
  cron.schedule('0 3 * * *', async () => {
    console.log('[SCHEDULER] Running refund job...');
    try {
      const result = await refundIgnoredApplications();
      console.log(`[SCHEDULER] Refund job completed: ${result.refunded}/${result.processed}`);
    } catch (error) {
      console.error('[SCHEDULER] Refund job failed:', error);
    }
  });

  console.log('[SCHEDULER] Scheduled jobs initialized successfully');
  console.log('[SCHEDULER] - Refund ignored applications: Daily at 03:00');
}

module.exports = { initScheduler };

