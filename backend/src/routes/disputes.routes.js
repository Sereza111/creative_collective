const express = require('express');
const router = express.Router();
const disputesController = require('../controllers/disputesController');
const { authenticate, adminOnly } = require('../middleware/auth');

// Все роуты требуют аутентификации
router.use(authenticate);

// POST /api/v1/disputes - Создать спор
router.post('/', disputesController.createDispute);

// GET /api/v1/disputes - Получить споры пользователя
router.get('/', disputesController.getUserDisputes);

// GET /api/v1/disputes/all - Получить все споры (только админ)
router.get('/all', adminOnly, disputesController.getAllDisputes);

// GET /api/v1/disputes/:id - Получить спор по ID
router.get('/:id', disputesController.getDispute);

// POST /api/v1/disputes/:id/messages - Добавить сообщение в спор
router.post('/:id/messages', disputesController.addDisputeMessage);

// PUT /api/v1/disputes/:id/resolve - Разрешить спор (только админ)
router.put('/:id/resolve', adminOnly, disputesController.resolveDispute);

module.exports = router;

