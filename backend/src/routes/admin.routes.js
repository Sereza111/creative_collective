const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const adminController = require('../controllers/adminController');

// Получить всех пользователей (только админ)
router.get('/users', authenticate, adminController.getAllUsers);

// Получить статистику платформы (только админ)
router.get('/stats', authenticate, adminController.getPlatformStats);

// Верифицировать пользователя (только админ)
router.post('/users/:userId/verify', authenticate, adminController.verifyUser);

// Отменить верификацию (только админ)
router.post('/users/:userId/unverify', authenticate, adminController.unverifyUser);

module.exports = router;

