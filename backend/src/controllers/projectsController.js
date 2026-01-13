const { query } = require('../config/database');
const { successResponse, errorResponse, generateUUID, getPagination, paginatedResponse } = require('../utils/helpers');

// Получить все проекты
exports.getAllProjects = async (req, res) => {
  try {
    const { 
      page = '1', 
      limit = '20', 
      status, 
      team_id,
      search 
    } = req.query;
    
    const { limit: limitNum, offset } = getPagination(parseInt(page) || 1, parseInt(limit) || 20);
    
    let whereConditions = [];
    let params = [];
    
    if (status) {
      whereConditions.push('p.status = ?');
      params.push(status);
    }
    
    if (team_id) {
      whereConditions.push('p.team_id = ?');
      params.push(team_id);
    }
    
    if (search) {
      whereConditions.push('(p.name LIKE ? OR p.description LIKE ?)');
      params.push(`%${search}%`, `%${search}%`);
    }
    
    const whereClause = whereConditions.length > 0 
      ? 'WHERE ' + whereConditions.join(' AND ')
      : '';
    
    const countResult = await query(
      `SELECT COUNT(*) as total FROM projects p ${whereClause}`,
      params
    );
    const total = countResult[0].total;
    
    const projects = await query(
      `SELECT p.*, 
              u.full_name as created_by_name,
              (SELECT COUNT(*) FROM project_members pm WHERE pm.project_id = p.id) as members_count,
              (SELECT COUNT(*) FROM tasks WHERE project_id = p.id) as tasks_count
       FROM projects p
       LEFT JOIN users u ON p.created_by = u.id
       ${whereClause}
       ORDER BY p.created_at DESC
       LIMIT ? OFFSET ?`,
      [...params, limitNum, offset]
    );
    
    successResponse(res, paginatedResponse(projects, total, page, limit));
    
  } catch (error) {
    console.error('Get projects error:', error);
    errorResponse(res, 'Ошибка при получении проектов');
  }
};

// Получить проект по ID
exports.getProjectById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const projects = await query(
      `SELECT p.*, 
              u.full_name as created_by_name,
              u.full_name as created_by_full_name
       FROM projects p
       LEFT JOIN users u ON p.created_by = u.id
       WHERE p.id = ?`,
      [id]
    );
    
    if (projects.length === 0) {
      return errorResponse(res, 'Проект не найден', 404);
    }
    
    // Получаем участников проекта
    const members = await query(
      `SELECT pm.*, u.full_name, u.avatar_url, u.role as user_role
       FROM project_members pm
       LEFT JOIN users u ON pm.user_id = u.id
       WHERE pm.project_id = ?`,
      [id]
    );
    
    // Получаем задачи проекта
    const tasks = await query(
      `SELECT t.*, u.full_name as assigned_to_name
       FROM tasks t
       LEFT JOIN users u ON t.assigned_to = u.id
       WHERE t.project_id = ?
       ORDER BY t.due_date ASC`,
      [id]
    );
    
    successResponse(res, {
      ...projects[0],
      members,
      tasks
    });
    
  } catch (error) {
    console.error('Get project error:', error);
    errorResponse(res, 'Ошибка при получении проекта');
  }
};

// Создать новый проект
exports.createProject = async (req, res) => {
  try {
    const { 
      name, 
      description, 
      status = 'planning', 
      start_date, 
      end_date, 
      progress = 0, 
      budget = 0, 
      spent = 0
    } = req.body;
    const created_by = req.user.id;
    
    const result = await query(
      `INSERT INTO projects (name, description, status, start_date, end_date, progress, budget, spent, created_by) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [name, description, status, start_date, end_date, progress, budget, spent, created_by]
    );
    
    const projectId = result.insertId;
    
    // Автоматически добавляем создателя как участника
    await query(
      'INSERT INTO project_members (project_id, user_id, role) VALUES (?, ?, ?)',
      [projectId, created_by, 'owner']
    );
    
    const newProject = await query('SELECT * FROM projects WHERE id = ?', [projectId]);
    
    successResponse(res, newProject[0], 'Проект создан', 201);
    
  } catch (error) {
    console.error('Create project error:', error);
    errorResponse(res, 'Ошибка при создании проекта');
  }
};

// Обновить проект
exports.updateProject = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    
    const existing = await query('SELECT * FROM projects WHERE id = ?', [id]);
    if (existing.length === 0) {
      return errorResponse(res, 'Проект не найден', 404);
    }
    
    const allowedFields = ['name', 'description', 'status', 'start_date', 'end_date', 'progress', 'budget', 'spent', 'team_id'];
    const updateFields = [];
    const updateValues = [];
    
    allowedFields.forEach(field => {
      if (updates[field] !== undefined) {
        updateFields.push(`${field} = ?`);
        updateValues.push(updates[field]);
      }
    });
    
    if (updateFields.length === 0) {
      return errorResponse(res, 'Нет полей для обновления', 400);
    }
    
    updateValues.push(id);
    
    await query(
      `UPDATE projects SET ${updateFields.join(', ')} WHERE id = ?`,
      updateValues
    );
    
    const updatedProject = await query('SELECT * FROM projects WHERE id = ?', [id]);
    
    successResponse(res, updatedProject[0], 'Проект обновлен');
    
  } catch (error) {
    console.error('Update project error:', error);
    errorResponse(res, 'Ошибка при обновлении проекта');
  }
};

// Удалить проект
exports.deleteProject = async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await query('DELETE FROM projects WHERE id = ?', [id]);
    
    if (result.affectedRows === 0) {
      return errorResponse(res, 'Проект не найден', 404);
    }
    
    successResponse(res, null, 'Проект удален');
    
  } catch (error) {
    console.error('Delete project error:', error);
    errorResponse(res, 'Ошибка при удалении проекта');
  }
};

// Добавить участника в проект
exports.addProjectMember = async (req, res) => {
  try {
    const { id } = req.params;
    const { user_id, role } = req.body;
    
    // Проверяем существование проекта
    const projects = await query('SELECT id FROM projects WHERE id = ?', [id]);
    if (projects.length === 0) {
      return errorResponse(res, 'Проект не найден', 404);
    }
    
    // Проверяем, не добавлен ли уже пользователь
    const existing = await query(
      'SELECT id FROM project_members WHERE project_id = ? AND user_id = ?',
      [id, user_id]
    );
    
    if (existing.length > 0) {
      return errorResponse(res, 'Пользователь уже добавлен в проект', 409);
    }
    
    const memberId = generateUUID();
    await query(
      'INSERT INTO project_members (id, project_id, user_id, role) VALUES (?, ?, ?, ?)',
      [memberId, id, user_id, role]
    );
    
    // Уведомление
    const project = await query('SELECT name FROM projects WHERE id = ?', [id]);
    await query(
      'INSERT INTO notifications (id, user_id, title, message, type, entity_id) VALUES (?, ?, ?, ?, ?, ?)',
      [generateUUID(), user_id, 'Новый проект', `Вы добавлены в проект: ${project[0].name}`, 'project', id]
    );
    
    successResponse(res, { id: memberId }, 'Участник добавлен в проект', 201);
    
  } catch (error) {
    console.error('Add project member error:', error);
    errorResponse(res, 'Ошибка при добавлении участника');
  }
};

// Удалить участника из проекта
exports.removeProjectMember = async (req, res) => {
  try {
    const { id, user_id } = req.params;
    
    const result = await query(
      'DELETE FROM project_members WHERE project_id = ? AND user_id = ?',
      [id, user_id]
    );
    
    if (result.affectedRows === 0) {
      return errorResponse(res, 'Участник не найден в проекте', 404);
    }
    
    successResponse(res, null, 'Участник удален из проекта');
    
  } catch (error) {
    console.error('Remove project member error:', error);
    errorResponse(res, 'Ошибка при удалении участника');
  }
};

