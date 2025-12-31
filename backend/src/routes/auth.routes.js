const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const authController = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validation');

// Валидация для регистрации
const registerValidation = [
  body('email').isEmail().withMessage('Некорректный email'),
  body('username').isLength({ min: 3, max: 50 }).withMessage('Username должен быть от 3 до 50 символов'),
  body('password').isLength({ min: 6 }).withMessage('Пароль должен содержать минимум 6 символов'),
  body('first_name').optional().isLength({ max: 100 }),
  body('last_name').optional().isLength({ max: 100 })
];

// Валидация для входа
const loginValidation = [
  body('email').notEmpty().withMessage('Email обязателен'),
  body('password').notEmpty().withMessage('Пароль обязателен')
];

// POST /api/auth/register - Регистрация
router.post('/register', registerValidation, validate, authController.register);

// POST /api/auth/login - Вход
router.post('/login', loginValidation, validate, authController.login);

// POST /api/auth/refresh - Обновление токена
router.post('/refresh', authController.refreshToken);

// POST /api/auth/logout - Выход
router.post('/logout', authController.logout);

// GET /api/auth/me - Получить информацию о текущем пользователе
router.get('/me', authenticate, authController.me);

module.exports = router;

