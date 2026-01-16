const { query } = require('../config/database');
const { successResponse, errorResponse } = require('../utils/responseHandler');

// Создать работу в портфолио
exports.createPortfolioItem = async (req, res) => {
  try {
    const userId = req.user.id;
    const { title, description, image_url, project_url, category, skills, completed_at } = req.body;

    console.log(`📁 Создание работы в портфолио пользователя ${userId}`);

    if (!title) {
      return errorResponse(res, 'Название работы обязательно', 400);
    }

    // Получаем максимальный порядок для определения нового
    const maxOrder = await query(
      'SELECT COALESCE(MAX(display_order), -1) as max_order FROM portfolio WHERE user_id = ?',
      [userId]
    );
    const newOrder = maxOrder[0].max_order + 1;

    const result = await query(
      `INSERT INTO portfolio (user_id, title, description, image_url, project_url, category, skills, completed_at, display_order) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [userId, title, description, image_url, project_url, category, skills ? JSON.stringify(skills) : null, completed_at, newOrder]
    );

    const newItem = await query(
      'SELECT * FROM portfolio WHERE id = ?',
      [result.insertId]
    );

    console.log(`✅ Работа добавлена в портфолио с ID: ${result.insertId}`);
    successResponse(res, newItem[0], 'Работа добавлена в портфолио', 201);
  } catch (error) {
    console.error('Create portfolio item error:', error);
    errorResponse(res, 'Ошибка добавления работы в портфолио');
  }
};

// Получить портфолио пользователя
exports.getUserPortfolio = async (req, res) => {
  try {
    const { userId } = req.params;

    console.log(`📋 Получение портфолио пользователя ${userId}`);

    const items = await query(
      `SELECT * FROM portfolio 
       WHERE user_id = ? 
       ORDER BY display_order ASC, created_at DESC`,
      [userId]
    );

    // Парсим JSON поля
    const parsedItems = items.map(item => ({
      ...item,
      skills: item.skills ? JSON.parse(item.skills) : []
    }));

    console.log(`✅ Найдено работ: ${items.length}`);
    successResponse(res, parsedItems);
  } catch (error) {
    console.error('Get user portfolio error:', error);
    errorResponse(res, 'Ошибка получения портфолио');
  }
};

// Получить работу по ID
exports.getPortfolioItemById = async (req, res) => {
  try {
    const { itemId } = req.params;

    const items = await query(
      'SELECT * FROM portfolio WHERE id = ?',
      [itemId]
    );

    if (items.length === 0) {
      return errorResponse(res, 'Работа не найдена', 404);
    }

    const item = items[0];
    item.skills = item.skills ? JSON.parse(item.skills) : [];

    successResponse(res, item);
  } catch (error) {
    console.error('Get portfolio item error:', error);
    errorResponse(res, 'Ошибка получения работы');
  }
};

// Обновить работу
exports.updatePortfolioItem = async (req, res) => {
  try {
    const { itemId } = req.params;
    const userId = req.user.id;
    const { title, description, image_url, project_url, category, skills, completed_at, display_order } = req.body;

    // Проверяем принадлежность работы пользователю
    const items = await query(
      'SELECT * FROM portfolio WHERE id = ? AND user_id = ?',
      [itemId, userId]
    );

    if (items.length === 0) {
      return errorResponse(res, 'Работа не найдена или у вас нет прав на её редактирование', 404);
    }

    await query(
      `UPDATE portfolio 
       SET title = ?, description = ?, image_url = ?, project_url = ?, category = ?, skills = ?, completed_at = ?, display_order = ?
       WHERE id = ?`,
      [
        title || items[0].title,
        description !== undefined ? description : items[0].description,
        image_url !== undefined ? image_url : items[0].image_url,
        project_url !== undefined ? project_url : items[0].project_url,
        category || items[0].category,
        skills ? JSON.stringify(skills) : items[0].skills,
        completed_at !== undefined ? completed_at : items[0].completed_at,
        display_order !== undefined ? display_order : items[0].display_order,
        itemId
      ]
    );

    const updatedItem = await query(
      'SELECT * FROM portfolio WHERE id = ?',
      [itemId]
    );

    const item = updatedItem[0];
    item.skills = item.skills ? JSON.parse(item.skills) : [];

    successResponse(res, item, 'Работа обновлена');
  } catch (error) {
    console.error('Update portfolio item error:', error);
    errorResponse(res, 'Ошибка обновления работы');
  }
};

// Удалить работу
exports.deletePortfolioItem = async (req, res) => {
  try {
    const { itemId } = req.params;
    const userId = req.user.id;

    // Проверяем принадлежность работы пользователю
    const items = await query(
      'SELECT * FROM portfolio WHERE id = ? AND user_id = ?',
      [itemId, userId]
    );

    if (items.length === 0) {
      return errorResponse(res, 'Работа не найдена или у вас нет прав на её удаление', 404);
    }

    await query('DELETE FROM portfolio WHERE id = ?', [itemId]);

    successResponse(res, null, 'Работа удалена');
  } catch (error) {
    console.error('Delete portfolio item error:', error);
    errorResponse(res, 'Ошибка удаления работы');
  }
};

// Обновить порядок работ
exports.updatePortfolioOrder = async (req, res) => {
  try {
    const userId = req.user.id;
    const { items } = req.body; // Массив { id, display_order }

    if (!Array.isArray(items)) {
      return errorResponse(res, 'Неверный формат данных', 400);
    }

    // Обновляем порядок для каждой работы
    for (const item of items) {
      await query(
        'UPDATE portfolio SET display_order = ? WHERE id = ? AND user_id = ?',
        [item.display_order, item.id, userId]
      );
    }

    successResponse(res, null, 'Порядок работ обновлен');
  } catch (error) {
    console.error('Update portfolio order error:', error);
    errorResponse(res, 'Ошибка обновления порядка');
  }
};

// Обновить профиль фрилансера (навыки, категории, био)
exports.updateFreelancerProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const { skills, categories, bio, portfolio_url } = req.body;

    await query(
      `UPDATE users 
       SET skills = ?, categories = ?, bio = ?, portfolio_url = ?
       WHERE id = ?`,
      [
        skills ? JSON.stringify(skills) : null,
        categories ? JSON.stringify(categories) : null,
        bio,
        portfolio_url,
        userId
      ]
    );

    const updatedUser = await query(
      'SELECT id, full_name, email, skills, categories, bio, portfolio_url FROM users WHERE id = ?',
      [userId]
    );

    const user = updatedUser[0];
    user.skills = user.skills ? JSON.parse(user.skills) : [];
    user.categories = user.categories ? JSON.parse(user.categories) : [];

    successResponse(res, user, 'Профиль обновлен');
  } catch (error) {
    console.error('Update freelancer profile error:', error);
    errorResponse(res, 'Ошибка обновления профиля');
  }
};

module.exports = exports;

