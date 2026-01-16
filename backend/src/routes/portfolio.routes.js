const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const { authenticate } = require('../middleware/auth');
const portfolioController = require('../controllers/portfolioController');

// Валидация для создания работы
const createPortfolioValidation = [
  body('title').notEmpty().withMessage('Название работы обязательно'),
  body('title').isLength({ max: 255 }).withMessage('Название не должно превышать 255 символов'),
  body('description').optional().isLength({ max: 5000 }).withMessage('Описание не должно превышать 5000 символов'),
  body('category').optional().isLength({ max: 100 }).withMessage('Категория не должна превышать 100 символов'),
];

// Создать работу в портфолио
router.post('/', authenticate, createPortfolioValidation, portfolioController.createPortfolioItem);

// Получить портфолио пользователя (публичный доступ)
router.get('/user/:userId', portfolioController.getUserPortfolio);

// Получить работу по ID
router.get('/:itemId', portfolioController.getPortfolioItemById);

// Обновить работу
router.put('/:itemId', authenticate, createPortfolioValidation, portfolioController.updatePortfolioItem);

// Удалить работу
router.delete('/:itemId', authenticate, portfolioController.deletePortfolioItem);

// Обновить порядок работ
router.post('/reorder', authenticate, portfolioController.updatePortfolioOrder);

// Обновить профиль фрилансера
router.put('/profile/update', authenticate, portfolioController.updateFreelancerProfile);

module.exports = router;

