const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const { authenticate } = require('../middleware/auth');
const reviewsController = require('../controllers/reviewsController');

// Валидация для создания отзыва
const createReviewValidation = [
  body('rating').isInt({ min: 1, max: 5 }).withMessage('Рейтинг должен быть от 1 до 5'),
  body('comment').optional().isString().isLength({ max: 2000 }).withMessage('Комментарий не должен превышать 2000 символов'),
];

// Создать отзыв для заказа
router.post('/orders/:orderId/review', authenticate, createReviewValidation, reviewsController.createReview);

// Получить отзывы пользователя
router.get('/users/:userId/reviews', reviewsController.getUserReviews);

// Получить статистику рейтинга пользователя
router.get('/users/:userId/rating', reviewsController.getUserRating);

// Получить отзывы для заказа
router.get('/orders/:orderId/reviews', reviewsController.getOrderReviews);

// Обновить отзыв
router.put('/:reviewId', authenticate, createReviewValidation, reviewsController.updateReview);

// Удалить отзыв
router.delete('/:reviewId', authenticate, reviewsController.deleteReview);

module.exports = router;

