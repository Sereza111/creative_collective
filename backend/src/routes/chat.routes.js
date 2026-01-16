const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const { authenticate } = require('../middleware/auth');
const { body } = require('express-validator');
const { validate } = require('../middleware/validation');

// Валидация сообщения
const messageValidation = [
  body('message').notEmpty().withMessage('Сообщение обязательно').trim(),
];

// GET /api/v1/chat - Получить все чаты пользователя
router.get('/', authenticate, chatController.getUserChats);

// GET /api/v1/chat/unread - Получить количество непрочитанных
router.get('/unread', authenticate, chatController.getUnreadCount);

// GET /api/v1/chat/order/:orderId - Получить или создать чат для заказа
router.get('/order/:orderId', authenticate, chatController.getOrCreateChat);

// GET /api/v1/chat/:chatId/messages - Получить сообщения чата
router.get('/:chatId/messages', authenticate, chatController.getChatMessages);

// POST /api/v1/chat/:chatId/messages - Отправить сообщение
router.post('/:chatId/messages', authenticate, messageValidation, validate, chatController.sendMessage);

module.exports = router;

