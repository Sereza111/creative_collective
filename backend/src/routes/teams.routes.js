const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const teamsController = require('../controllers/teamsController');
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validation');

// Валидация для команды
const teamValidation = [
  body('name').isLength({ min: 1, max: 200 }).withMessage('Название обязательно'),
  body('description').optional()
];

router.use(authenticate);

// GET /api/teams - Получить все команды
router.get('/', teamsController.getAllTeams);

// GET /api/teams/:id - Получить команду по ID
router.get('/:id', teamsController.getTeamById);

// POST /api/teams - Создать команду
router.post('/', teamValidation, validate, teamsController.createTeam);

// PUT /api/teams/:id - Обновить команду
router.put('/:id', teamValidation, validate, teamsController.updateTeam);

// DELETE /api/teams/:id - Удалить команду
router.delete('/:id', teamsController.deleteTeam);

// POST /api/teams/:id/members - Добавить участника
router.post('/:id/members', teamsController.addTeamMember);

// DELETE /api/teams/:id/members/:user_id - Удалить участника
router.delete('/:id/members/:user_id', teamsController.removeTeamMember);

// PUT /api/teams/:id/members/:user_id - Обновить информацию участника
router.put('/:id/members/:user_id', teamsController.updateTeamMember);

module.exports = router;

