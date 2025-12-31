const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const tasksController = require('../controllers/tasksController');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validation');

// Валидация для создания/обновления задачи
const taskValidation = [
  body('title').isLength({ min: 1, max: 300 }).withMessage('Название обязательно (до 300 символов)'),
  body('description').optional(),
  body('status').optional().isIn(['todo', 'in_progress', 'review', 'done', 'cancelled']),
  body('priority').optional().isInt({ min: 1, max: 5 }).withMessage('Приоритет от 1 до 5'),
  body('due_date').optional().isISO8601().withMessage('Некорректная дата'),
  body('project_id').notEmpty().withMessage('ID проекта обязателен'),
  body('assigned_to').optional()
];

// Все роуты требуют аутентификации
router.use(authenticate);

// GET /api/tasks - Получить все задачи
router.get('/', tasksController.getAllTasks);

// GET /api/tasks/:id - Получить задачу по ID
router.get('/:id', tasksController.getTaskById);

// POST /api/tasks - Создать задачу
router.post('/', taskValidation, validate, tasksController.createTask);

// PUT /api/tasks/:id - Обновить задачу
router.put('/:id', tasksController.updateTask);

// DELETE /api/tasks/:id - Удалить задачу
router.delete('/:id', tasksController.deleteTask);

module.exports = router;

