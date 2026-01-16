const express = require('express');
const router = express.Router();
const favoritesController = require('../controllers/favoritesController');
const { authenticate } = require('../middleware/auth');

// Все роуты требуют аутентификации
router.use(authenticate);

// POST /api/v1/favorites - Добавить в избранное
router.post('/', favoritesController.addFavorite);

// DELETE /api/v1/favorites - Удалить из избранного
router.delete('/', favoritesController.removeFavorite);

// GET /api/v1/favorites - Получить избранное
router.get('/', favoritesController.getFavorites);

// GET /api/v1/favorites/check - Проверить, находится ли элемент в избранном
router.get('/check', favoritesController.checkFavorite);

module.exports = router;
