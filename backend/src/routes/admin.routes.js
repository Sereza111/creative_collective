const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const adminController = require('../controllers/adminController');

// Верифицировать пользователя (только админ)
router.post('/users/:userId/verify', authenticate, adminController.verifyUser);

// Отменить верификацию (только админ)
router.post('/users/:userId/unverify', authenticate, adminController.unverifyUser);

module.exports = router;

