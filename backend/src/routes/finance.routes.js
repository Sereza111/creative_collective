const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const financeController = require('../controllers/financeController');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validation');

// Валидация для транзакции
const transactionValidation = [
  body('type').isIn(['earned', 'spent', 'bonus', 'penalty']).withMessage('Некорректный тип транзакции'),
  body('amount').isFloat({ min: 0.01 }).withMessage('Сумма должна быть больше 0'),
  body('description').isLength({ max: 500 }).withMessage('Описание до 500 символов'),
  body('project_id').optional(),
  body('category').optional().isLength({ max: 100 })
];

router.use(authenticate);

// GET /api/finance/:user_id - Получить финансовую информацию пользователя
router.get('/:user_id', financeController.getUserFinance);

// GET /api/finance/:user_id/transactions - Получить транзакции пользователя
router.get('/:user_id/transactions', financeController.getUserTransactions);

// POST /api/finance/:user_id/transactions - Создать транзакцию
router.post('/:user_id/transactions', transactionValidation, validate, financeController.createTransaction);

// GET /api/finance/:user_id/stats - Получить статистику
router.get('/:user_id/stats', financeController.getFinanceStats);

module.exports = router;

