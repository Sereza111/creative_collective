const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const favoritesController = require('../controllers/favoritesController');

// Добавить в избранное
router.post('/', authenticate, favoritesController.addFavorite);

// Удалить из избранного
router.delete('/', authenticate, favoritesController.removeFavorite);

// Получить избранное
router.get('/', authenticate, favoritesController.getFavorites);

// Проверить избранное
router.get('/check', authenticate, favoritesController.checkFavorite);

module.exports = router;

