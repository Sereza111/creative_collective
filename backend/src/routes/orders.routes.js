const express = require('express');
const router = express.Router();
const ordersController = require('../controllers/ordersController');
const { authenticate } = require('../middleware/auth');
const { body } = require('express-validator');
const { validate } = require('../middleware/validation');

// Валидация создания заказа
const createOrderValidation = [
  body('title').notEmpty().withMessage('Название заказа обязательно'),
  body('budget').optional().isFloat({ min: 0 }).withMessage('Бюджет должен быть положительным числом'),
  body('deadline').optional().isISO8601().withMessage('Неверный формат даты'),
];

// Валидация отклика
const applyValidation = [
  body('message').optional().isString(),
  body('proposed_budget').optional().isFloat({ min: 0 }),
  body('proposed_deadline').optional().isISO8601(),
];

// GET /api/v1/orders - Получить все заказы (маркетплейс)
router.get('/', authenticate, ordersController.getAllOrders);

// GET /api/v1/orders/my-applications - Получить мои отклики (freelancer)
router.get('/my-applications', authenticate, ordersController.getMyApplications);

// GET /api/v1/orders/:id - Получить заказ по ID
router.get('/:id', authenticate, ordersController.getOrderById);

// POST /api/v1/orders - Создать заказ (только client)
router.post('/', authenticate, createOrderValidation, validate, ordersController.createOrder);

// PUT /api/v1/orders/:id - Обновить заказ
router.put('/:id', authenticate, ordersController.updateOrder);

// DELETE /api/v1/orders/:id - Удалить заказ
router.delete('/:id', authenticate, ordersController.deleteOrder);

// POST /api/v1/orders/:id/apply - Откликнуться на заказ (freelancer)
router.post('/:id/apply', authenticate, applyValidation, validate, ordersController.applyToOrder);

// GET /api/v1/orders/:id/applications - Получить отклики на заказ
router.get('/:id/applications', authenticate, ordersController.getOrderApplications);

// POST /api/v1/orders/:id/applications/:applicationId/accept - Принять отклик
router.post('/:id/applications/:applicationId/accept', authenticate, ordersController.acceptApplication);

module.exports = router;

