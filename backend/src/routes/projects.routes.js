const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const projectsController = require('../controllers/projectsController');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validation');

// Валидация для проекта
const projectValidation = [
  body('name').isLength({ min: 1, max: 200 }).withMessage('Название обязательно'),
  body('description').optional(),
  body('status').optional().isIn(['planning', 'active', 'on_hold', 'completed', 'cancelled']),
  body('start_date').notEmpty().withMessage('Дата начала обязательна'),
  body('end_date').notEmpty().withMessage('Дата окончания обязательна'),
  body('progress').optional().isInt({ min: 0, max: 100 }),
  body('budget').optional().isFloat({ min: 0 }),
  body('spent').optional().isFloat({ min: 0 }),
  body('team_id').optional()
];

router.use(authenticate);

// GET /api/projects - Получить все проекты
router.get('/', projectsController.getAllProjects);

// GET /api/projects/:id - Получить проект по ID
router.get('/:id', projectsController.getProjectById);

// POST /api/projects - Создать проект
router.post('/', projectValidation, validate, projectsController.createProject);

// PUT /api/projects/:id - Обновить проект
router.put('/:id', projectsController.updateProject);

// DELETE /api/projects/:id - Удалить проект
router.delete('/:id', projectsController.deleteProject);

// POST /api/projects/:id/members - Добавить участника
router.post('/:id/members', projectsController.addProjectMember);

// DELETE /api/projects/:id/members/:user_id - Удалить участника
router.delete('/:id/members/:user_id', projectsController.removeProjectMember);

module.exports = router;

