const express = require('express');
const router = express.Router();
const financeController = require('../controllers/financeController');
const { authenticate, adminOnly } = require('../middleware/auth');

// Все роуты требуют аутентификации
router.use(authenticate);

// GET /api/v1/finance/balance - Получить свой баланс
router.get('/balance', financeController.getUserBalance);

// GET /api/v1/finance/transactions - Получить свои транзакции
router.get('/transactions', financeController.getUserTransactions);

// POST /api/v1/finance/transactions - Создать транзакцию
router.post('/transactions', financeController.createTransaction);

// PUT /api/v1/finance/transactions/:id/complete - Завершить транзакцию (админ)
router.put('/transactions/:id/complete', adminOnly, financeController.completeTransaction);

// POST /api/v1/finance/withdrawal - Создать запрос на вывод
router.post('/withdrawal', financeController.createWithdrawalRequest);

// GET /api/v1/finance/withdrawal - Получить свои запросы на вывод
router.get('/withdrawal', financeController.getUserWithdrawalRequests);

// GET /api/v1/finance/withdrawal/all - Получить все запросы на вывод (админ)
router.get('/withdrawal/all', adminOnly, financeController.getAllWithdrawalRequests);

// PUT /api/v1/finance/withdrawal/:id - Обработать запрос на вывод (админ)
router.put('/withdrawal/:id', adminOnly, financeController.processWithdrawalRequest);

// GET /api/v1/finance/stats - Получить статистику (админ)
router.get('/stats', adminOnly, financeController.getFinanceStats);

module.exports = router;
