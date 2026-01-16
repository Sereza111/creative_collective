const { query } = require('../config/database');
const { successResponse, errorResponse, generateUUID } = require('../utils/helpers');

// Получить все команды
exports.getAllTeams = async (req, res) => {
  try {
    const userId = req.user?.id; // Получаем ID текущего пользователя
    
    // ВАЖНО: Фильтруем команды по текущему пользователю
    // Показываем только команды, где пользователь - владелец или участник
    const teams = await query(
      `SELECT t.*, u.full_name as owner_name,
              (SELECT COUNT(*) FROM team_members tm WHERE tm.team_id = t.id) as members_count
       FROM teams t
       LEFT JOIN users u ON t.owner_id = u.id
       WHERE t.owner_id = ? OR EXISTS (SELECT 1 FROM team_members tm WHERE tm.team_id = t.id AND tm.user_id = ?)
       ORDER BY t.created_at DESC`,
      [userId, userId]
    );
    
    successResponse(res, teams);
    
  } catch (error) {
    console.error('Get teams error:', error);
    errorResponse(res, 'Ошибка при получении команд');
  }
};

// Получить команду по ID
exports.getTeamById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const teams = await query(
      `SELECT t.*, u.username as owner_name, u.full_name as owner_full_name
       FROM teams t
       LEFT JOIN users u ON t.owner_id = u.id
       WHERE t.id = ?`,
      [id]
    );
    
    if (teams.length === 0) {
      return errorResponse(res, 'Команда не найдена', 404);
    }
    
    // Получаем участников
    const members = await query(
      `SELECT tm.*, u.full_name, u.avatar_url, u.email, u.role as user_role
       FROM team_members tm
       LEFT JOIN users u ON tm.user_id = u.id
       WHERE tm.team_id = ?
       ORDER BY tm.joined_at ASC`,
      [id]
    );
    
    // Получаем проекты команды
    const projects = await query(
      `SELECT id, name, status, progress, budget, spent
       FROM projects
       WHERE team_id = ?
       ORDER BY created_at DESC`,
      [id]
    );
    
    successResponse(res, {
      ...teams[0],
      members,
      projects
    });
    
  } catch (error) {
    console.error('Get team error:', error);
    errorResponse(res, 'Ошибка при получении команды');
  }
};

// Создать новую команду
exports.createTeam = async (req, res) => {
  try {
    const { name, description } = req.body;
    const owner_id = req.user.id;
    
    const teamId = generateUUID();
    
    await query(
      'INSERT INTO teams (id, name, description, owner_id) VALUES (?, ?, ?, ?)',
      [teamId, name, description, owner_id]
    );
    
    // Автоматически добавляем владельца в участники
    await query(
      'INSERT INTO team_members (id, team_id, user_id, role, skills) VALUES (?, ?, ?, ?, ?)',
      [generateUUID(), teamId, owner_id, 'Owner', '[]']
    );
    
    const newTeam = await query('SELECT * FROM teams WHERE id = ?', [teamId]);
    
    successResponse(res, newTeam[0], 'Команда создана', 201);
    
  } catch (error) {
    console.error('Create team error:', error);
    errorResponse(res, 'Ошибка при создании команды');
  }
};

// Обновить команду
exports.updateTeam = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description } = req.body;
    
    // Проверяем существование и права
    const teams = await query('SELECT owner_id FROM teams WHERE id = ?', [id]);
    if (teams.length === 0) {
      return errorResponse(res, 'Команда не найдена', 404);
    }
    
    if (req.user.role !== 'admin' && teams[0].owner_id !== req.user.id) {
      return errorResponse(res, 'Недостаточно прав', 403);
    }
    
    await query(
      'UPDATE teams SET name = ?, description = ? WHERE id = ?',
      [name, description, id]
    );
    
    const updatedTeam = await query('SELECT * FROM teams WHERE id = ?', [id]);
    
    successResponse(res, updatedTeam[0], 'Команда обновлена');
    
  } catch (error) {
    console.error('Update team error:', error);
    errorResponse(res, 'Ошибка при обновлении команды');
  }
};

// Удалить команду
exports.deleteTeam = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Проверяем права
    const teams = await query('SELECT owner_id FROM teams WHERE id = ?', [id]);
    if (teams.length === 0) {
      return errorResponse(res, 'Команда не найдена', 404);
    }
    
    if (req.user.role !== 'admin' && teams[0].owner_id !== req.user.id) {
      return errorResponse(res, 'Недостаточно прав', 403);
    }
    
    await query('DELETE FROM teams WHERE id = ?', [id]);
    
    successResponse(res, null, 'Команда удалена');
    
  } catch (error) {
    console.error('Delete team error:', error);
    errorResponse(res, 'Ошибка при удалении команды');
  }
};

// Добавить участника в команду
exports.addTeamMember = async (req, res) => {
  try {
    const { id } = req.params;
    const { user_id, role, skills = [] } = req.body;
    
    // Проверяем существование команды
    const teams = await query('SELECT owner_id, name FROM teams WHERE id = ?', [id]);
    if (teams.length === 0) {
      return errorResponse(res, 'Команда не найдена', 404);
    }
    
    // Проверяем права
    if (req.user.role !== 'admin' && teams[0].owner_id !== req.user.id) {
      return errorResponse(res, 'Недостаточно прав', 403);
    }
    
    // Проверяем, не добавлен ли уже пользователь
    const existing = await query(
      'SELECT id FROM team_members WHERE team_id = ? AND user_id = ?',
      [id, user_id]
    );
    
    if (existing.length > 0) {
      return errorResponse(res, 'Пользователь уже в команде', 409);
    }
    
    const memberId = generateUUID();
    await query(
      'INSERT INTO team_members (id, team_id, user_id, role, skills) VALUES (?, ?, ?, ?, ?)',
      [memberId, id, user_id, role, JSON.stringify(skills)]
    );
    
    // Уведомление
    await query(
      'INSERT INTO notifications (id, user_id, title, message, type, entity_id) VALUES (?, ?, ?, ?, ?, ?)',
      [generateUUID(), user_id, 'Новая команда', `Вы добавлены в команду: ${teams[0].name}`, 'team', id]
    );
    
    successResponse(res, { id: memberId }, 'Участник добавлен в команду', 201);
    
  } catch (error) {
    console.error('Add team member error:', error);
    errorResponse(res, 'Ошибка при добавлении участника');
  }
};

// Удалить участника из команды
exports.removeTeamMember = async (req, res) => {
  try {
    const { id, user_id } = req.params;
    
    // Проверяем права
    const teams = await query('SELECT owner_id FROM teams WHERE id = ?', [id]);
    if (teams.length === 0) {
      return errorResponse(res, 'Команда не найдена', 404);
    }
    
    if (req.user.role !== 'admin' && teams[0].owner_id !== req.user.id) {
      return errorResponse(res, 'Недостаточно прав', 403);
    }
    
    // Нельзя удалить владельца
    if (teams[0].owner_id === user_id) {
      return errorResponse(res, 'Нельзя удалить владельца команды', 400);
    }
    
    const result = await query(
      'DELETE FROM team_members WHERE team_id = ? AND user_id = ?',
      [id, user_id]
    );
    
    if (result.affectedRows === 0) {
      return errorResponse(res, 'Участник не найден в команде', 404);
    }
    
    successResponse(res, null, 'Участник удален из команды');
    
  } catch (error) {
    console.error('Remove team member error:', error);
    errorResponse(res, 'Ошибка при удалении участника');
  }
};

// Обновить информацию участника команды
exports.updateTeamMember = async (req, res) => {
  try {
    const { id, user_id } = req.params;
    const { role, skills } = req.body;
    
    // Проверяем права
    const teams = await query('SELECT owner_id FROM teams WHERE id = ?', [id]);
    if (teams.length === 0) {
      return errorResponse(res, 'Команда не найдена', 404);
    }
    
    if (req.user.role !== 'admin' && teams[0].owner_id !== req.user.id && req.user.id !== user_id) {
      return errorResponse(res, 'Недостаточно прав', 403);
    }
    
    const updateFields = [];
    const updateValues = [];
    
    if (role !== undefined) {
      updateFields.push('role = ?');
      updateValues.push(role);
    }
    
    if (skills !== undefined) {
      updateFields.push('skills = ?');
      updateValues.push(JSON.stringify(skills));
    }
    
    if (updateFields.length === 0) {
      return errorResponse(res, 'Нет полей для обновления', 400);
    }
    
    updateValues.push(id, user_id);
    
    await query(
      `UPDATE team_members SET ${updateFields.join(', ')} WHERE team_id = ? AND user_id = ?`,
      updateValues
    );
    
    successResponse(res, null, 'Информация участника обновлена');
    
  } catch (error) {
    console.error('Update team member error:', error);
    errorResponse(res, 'Ошибка при обновлении информации участника');
  }
};

