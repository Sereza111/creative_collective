const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { query } = require('../config/database');
const { successResponse, errorResponse, generateUUID } = require('../utils/helpers');

// Регистрация нового пользователя
exports.register = async (req, res) => {
  try {
    const { email, password, full_name, role = 'member' } = req.body;
    
    // Проверяем, существует ли пользователь
    const existingUser = await query(
      'SELECT id FROM users WHERE email = ?',
      [email]
    );
    
    if (existingUser.length > 0) {
      return errorResponse(res, 'Пользователь с таким email уже существует', 409);
    }
    
    // Хешируем пароль
    const hashedPassword = await bcrypt.hash(password, 10);
    
    // Создаем пользователя
    const userResult = await query(
      `INSERT INTO users (email, password, full_name, role) 
       VALUES (?, ?, ?, ?)`,
      [email, hashedPassword, full_name || null, role]
    );
    
    const userId = userResult.insertId;
    
    // Создаем финансовый аккаунт для пользователя
    await query(
      'INSERT INTO finance (user_id, balance, total_earned, total_spent) VALUES (?, 0, 0, 0)',
      [userId]
    );
    
    // Генерируем токены
    const accessToken = jwt.sign(
      { userId, email, role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );
    
    const refreshToken = jwt.sign(
      { userId },
      process.env.JWT_REFRESH_SECRET,
      { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN }
    );
    
    // Сохраняем refresh token
    await query(
      'INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 30 DAY))',
      [userId, refreshToken]
    );
    
    successResponse(res, {
      user: {
        id: userId,
        email,
        full_name,
        role
      },
      accessToken,
      refreshToken
    }, 'Регистрация успешна', 201);
    
  } catch (error) {
    console.error('Register error:', error);
    errorResponse(res, 'Ошибка при регистрации');
  }
};

// Вход в систему
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Находим пользователя
    const users = await query(
      'SELECT * FROM users WHERE email = ?',
      [email]
    );
    
    if (users.length === 0) {
      return errorResponse(res, 'Неверный email или пароль', 401);
    }
    
    const user = users[0];
    
    // Проверяем статус
    if (!user.is_active) {
      return errorResponse(res, 'Аккаунт заблокирован', 403);
    }
    
    // Проверяем пароль
    const isPasswordValid = await bcrypt.compare(password, user.password);
    
    if (!isPasswordValid) {
      return errorResponse(res, 'Неверный email или пароль', 401);
    }
    
    // Обновляем last_login
    await query(
      'UPDATE users SET last_login = NOW() WHERE id = ?',
      [user.id]
    );
    
    // Генерируем токены
    const accessToken = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );
    
    const refreshToken = jwt.sign(
      { userId: user.id },
      process.env.JWT_REFRESH_SECRET,
      { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN }
    );
    
    // Сохраняем refresh token
    await query(
      'INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 30 DAY))',
      [user.id, refreshToken]
    );
    
    successResponse(res, {
      user: {
        id: user.id,
        email: user.email,
        full_name: user.full_name,
        role: user.role,
        user_role: user.user_role || 'freelancer',
        avatar_url: user.avatar_url
      },
      accessToken,
      refreshToken
    }, 'Вход выполнен успешно');
    
  } catch (error) {
    console.error('Login error:', error);
    errorResponse(res, 'Ошибка при входе');
  }
};

// Обновление access token через refresh token
exports.refreshToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;
    
    if (!refreshToken) {
      return errorResponse(res, 'Refresh token не предоставлен', 400);
    }
    
    // Проверяем refresh token
    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    
    // Проверяем, существует ли токен в БД
    const tokens = await query(
      'SELECT * FROM refresh_tokens WHERE token = ? AND user_id = ? AND expires_at > NOW()',
      [refreshToken, decoded.userId]
    );
    
    if (tokens.length === 0) {
      return errorResponse(res, 'Недействительный refresh token', 401);
    }
    
    // Получаем пользователя
    const users = await query(
      'SELECT id, email, role FROM users WHERE id = ? AND status = ?',
      [decoded.userId, 'active']
    );
    
    if (users.length === 0) {
      return errorResponse(res, 'Пользователь не найден', 404);
    }
    
    const user = users[0];
    
    // Генерируем новый access token
    const accessToken = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN }
    );
    
    successResponse(res, { accessToken }, 'Токен обновлен');
    
  } catch (error) {
    console.error('Refresh token error:', error);
    errorResponse(res, 'Ошибка при обновлении токена', 401);
  }
};

// Выход из системы
exports.logout = async (req, res) => {
  try {
    const { refreshToken } = req.body;
    
    if (refreshToken) {
      // Удаляем refresh token из БД
      await query('DELETE FROM refresh_tokens WHERE token = ?', [refreshToken]);
    }
    
    successResponse(res, null, 'Выход выполнен успешно');
    
  } catch (error) {
    console.error('Logout error:', error);
    errorResponse(res, 'Ошибка при выходе');
  }
};

// Получение информации о текущем пользователе
exports.me = async (req, res) => {
  try {
    const userId = req.user.id;
    
    const users = await query(
      `SELECT u.id, u.email, u.full_name, u.avatar_url, 
              u.role, u.user_role, u.created_at,
              f.balance, f.total_earned, f.total_spent
       FROM users u
       LEFT JOIN finance f ON f.user_id = u.id
       WHERE u.id = ?`,
      [userId]
    );
    
    if (users.length === 0) {
      return errorResponse(res, 'Пользователь не найден', 404);
    }
    
    successResponse(res, users[0], 'Данные пользователя получены');
    
  } catch (error) {
    console.error('Get me error:', error);
    errorResponse(res, 'Ошибка при получении данных пользователя');
  }
};

exports.updateProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const { full_name, email } = req.body;
    
    // Check if email already exists for other users
    if (email) {
      const existingUsers = await query(
        'SELECT id FROM users WHERE email = ? AND id != ?',
        [email, userId]
      );
      
      if (existingUsers.length > 0) {
        return errorResponse(res, 'Email уже используется', 400);
      }
    }
    
    // Update user data
    const updateData = {};
    if (full_name !== undefined) updateData.full_name = full_name;
    if (email !== undefined) updateData.email = email;
    updateData.updated_at = new Date();
    
    const updateFields = Object.keys(updateData).map(key => `${key} = ?`).join(', ');
    const updateValues = [...Object.values(updateData), userId];
    
    await query(
      `UPDATE users SET ${updateFields} WHERE id = ?`,
      updateValues
    );
    
    // Get updated user data
    const users = await query(
      `SELECT u.id, u.email, u.full_name, u.avatar_url, 
              u.role, u.created_at,
              f.balance, f.total_earned, f.total_spent
       FROM users u
       LEFT JOIN finance f ON f.user_id = u.id
       WHERE u.id = ?`,
      [userId]
    );
    
    successResponse(res, users[0], 'Профиль обновлен');
    
  } catch (error) {
    console.error('Update profile error:', error);
    errorResponse(res, 'Ошибка при обновлении профиля');
  }
};

