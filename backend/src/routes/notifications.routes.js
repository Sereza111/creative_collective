const express = require('express');
const router = express.Router();
const notificationsController = require('../controllers/notificationsController');
const { authenticate } = require('../middleware/auth');

// Все роуты требуют аутентификации
router.use(authenticate);

// GET /api/v1/notifications - Получить уведомления пользователя
router.get('/', notificationsController.getUserNotifications);

// GET /api/v1/notifications/unread-count - Получить количество непрочитанных
router.get('/unread-count', notificationsController.getUnreadCount);

// GET /api/v1/notifications/settings - Получить настройки уведомлений
router.get('/settings', notificationsController.getNotificationSettings);

// PUT /api/v1/notifications/settings - Обновить настройки уведомлений
router.put('/settings', notificationsController.updateNotificationSettings);

// PUT /api/v1/notifications/:id/read - Отметить уведомление как прочитанное
router.put('/:id/read', notificationsController.markAsRead);

// PUT /api/v1/notifications/read-all - Отметить все как прочитанные
router.put('/read-all', notificationsController.markAllAsRead);

// DELETE /api/v1/notifications/:id - Удалить уведомление
router.delete('/:id', notificationsController.deleteNotification);

module.exports = router;

