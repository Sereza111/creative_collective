const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const authController = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validation');

// Валидация для регистрации
const registerValidation = [
  body('email').isEmail().withMessage('Некорректный email'),
  body('password').isLength({ min: 6 }).withMessage('Пароль должен содержать минимум 6 символов'),
  body('full_name').optional().isLength({ max: 255 })
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

// PUT /api/auth/profile - Обновить профиль пользователя
const updateProfileValidation = [
  body('email').optional().isEmail().withMessage('Некорректный email'),
  body('full_name').optional().isLength({ min: 1, max: 255 }).withMessage('Имя должно быть от 1 до 255 символов')
];
router.put('/profile', authenticate, updateProfileValidation, validate, authController.updateProfile);

module.exports = router;

