const { query } = require('../config/database');
const { successResponse, errorResponse, generateUUID, getPagination, paginatedResponse } = require('../utils/helpers');

// Получить все задачи с фильтрацией
exports.getAllTasks = async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      project_id, 
      status, 
      assigned_to, 
      priority,
      search 
    } = req.query;
    
    const { limit: limitNum, offset } = getPagination(page, limit);
    
    let whereConditions = [];
    let params = [];
    
    if (project_id) {
      whereConditions.push('t.project_id = ?');
      params.push(project_id);
    }
    
    if (status) {
      whereConditions.push('t.status = ?');
      params.push(status);
    }
    
    if (assigned_to) {
      whereConditions.push('t.assigned_to = ?');
      params.push(assigned_to);
    }
    
    if (priority) {
      whereConditions.push('t.priority = ?');
      params.push(priority);
    }
    
    if (search) {
      whereConditions.push('(t.title LIKE ? OR t.description LIKE ?)');
      params.push(`%${search}%`, `%${search}%`);
    }
    
    const whereClause = whereConditions.length > 0 
      ? 'WHERE ' + whereConditions.join(' AND ')
      : '';
    
    // Подсчет общего количества
    const countResult = await query(
      `SELECT COUNT(*) as total FROM tasks t ${whereClause}`,
      params
    );
    const total = countResult[0].total;
    
    // Получение задач
    const tasks = await query(
      `SELECT t.*, 
              p.name as project_name,
              u.username as assigned_to_name,
              u.first_name as assigned_first_name,
              c.username as created_by_name
       FROM tasks t
       LEFT JOIN projects p ON t.project_id = p.id
       LEFT JOIN users u ON t.assigned_to = u.id
       LEFT JOIN users c ON t.created_by = c.id
       ${whereClause}
       ORDER BY t.due_date ASC, t.priority DESC
       LIMIT ? OFFSET ?`,
      [...params, limitNum, offset]
    );
    
    successResponse(res, paginatedResponse(tasks, total, page, limit));
    
  } catch (error) {
    console.error('Get tasks error:', error);
    errorResponse(res, 'Ошибка при получении задач');
  }
};

// Получить задачу по ID
exports.getTaskById = async (req, res) => {
  try {
    const { id } = req.params;
    
    const tasks = await query(
      `SELECT t.*, 
              p.name as project_name,
              p.status as project_status,
              u.username as assigned_to_name,
              u.first_name as assigned_first_name,
              u.last_name as assigned_last_name,
              c.username as created_by_name
       FROM tasks t
       LEFT JOIN projects p ON t.project_id = p.id
       LEFT JOIN users u ON t.assigned_to = u.id
       LEFT JOIN users c ON t.created_by = c.id
       WHERE t.id = ?`,
      [id]
    );
    
    if (tasks.length === 0) {
      return errorResponse(res, 'Задача не найдена', 404);
    }
    
    // Получаем комментарии
    const comments = await query(
      `SELECT c.*, u.username, u.first_name, u.last_name, u.avatar_url
       FROM comments c
       LEFT JOIN users u ON c.user_id = u.id
       WHERE c.entity_type = 'task' AND c.entity_id = ?
       ORDER BY c.created_at DESC`,
      [id]
    );
    
    successResponse(res, {
      ...tasks[0],
      comments
    });
    
  } catch (error) {
    console.error('Get task error:', error);
    errorResponse(res, 'Ошибка при получении задачи');
  }
};

// Создать новую задачу
exports.createTask = async (req, res) => {
  try {
    const { title, description, status = 'todo', priority = 3, due_date, project_id, assigned_to } = req.body;
    const created_by = req.user.id;
    
    const taskId = generateUUID();
    
    await query(
      `INSERT INTO tasks (id, title, description, status, priority, due_date, project_id, assigned_to, created_by) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [taskId, title, description, status, priority, due_date, project_id, assigned_to, created_by]
    );
    
    // Создаем уведомление для назначенного пользователя
    if (assigned_to && assigned_to !== created_by) {
      await query(
        `INSERT INTO notifications (id, user_id, title, message, type, entity_id)
         VALUES (?, ?, ?, ?, 'task', ?)`,
        [generateUUID(), assigned_to, 'Новая задача', `Вам назначена задача: ${title}`, taskId]
      );
    }
    
    const newTask = await query('SELECT * FROM tasks WHERE id = ?', [taskId]);
    
    successResponse(res, newTask[0], 'Задача создана', 201);
    
  } catch (error) {
    console.error('Create task error:', error);
    errorResponse(res, 'Ошибка при создании задачи');
  }
};

// Обновить задачу
exports.updateTask = async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    
    // Проверяем существование задачи
    const existing = await query('SELECT * FROM tasks WHERE id = ?', [id]);
    if (existing.length === 0) {
      return errorResponse(res, 'Задача не найдена', 404);
    }
    
    const allowedFields = ['title', 'description', 'status', 'priority', 'due_date', 'assigned_to'];
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
      `UPDATE tasks SET ${updateFields.join(', ')} WHERE id = ?`,
      updateValues
    );
    
    // Если статус изменился на done, устанавливаем completed_at
    if (updates.status === 'done') {
      await query('UPDATE tasks SET completed_at = NOW() WHERE id = ?', [id]);
    }
    
    const updatedTask = await query('SELECT * FROM tasks WHERE id = ?', [id]);
    
    successResponse(res, updatedTask[0], 'Задача обновлена');
    
  } catch (error) {
    console.error('Update task error:', error);
    errorResponse(res, 'Ошибка при обновлении задачи');
  }
};

// Удалить задачу
exports.deleteTask = async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await query('DELETE FROM tasks WHERE id = ?', [id]);
    
    if (result.affectedRows === 0) {
      return errorResponse(res, 'Задача не найдена', 404);
    }
    
    successResponse(res, null, 'Задача удалена');
    
  } catch (error) {
    console.error('Delete task error:', error);
    errorResponse(res, 'Ошибка при удалении задачи');
  }
};

