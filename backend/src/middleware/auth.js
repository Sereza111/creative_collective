const jwt = require('jsonwebtoken');
const { query } = require('../config/database');

// Middleware для проверки JWT токена
const authenticate = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Токен не предоставлен'
      });
    }
    
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Проверяем, существует ли пользователь
    const users = await query(
      'SELECT id, email, full_name, role, user_role, is_active FROM users WHERE id = ?',
      [decoded.userId]
    );
    
    if (users.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Пользователь не найден'
      });
    }
    
    const user = users[0];
    
    if (!user.is_active) {
      return res.status(403).json({
        success: false,
        message: 'Аккаунт заблокирован'
      });
    }
    
    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        message: 'Неверный токен'
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Токен истек'
      });
    }
    
    console.error('Auth error:', error);
    res.status(500).json({
      success: false,
      message: 'Ошибка аутентификации'
    });
  }
};

// Middleware для проверки роли
const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Необходима аутентификация'
      });
    }
    
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'Недостаточно прав'
      });
    }
    
    next();
  };
};

// Опциональная аутентификация (не возвращает ошибку если токена нет)
const optionalAuth = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (token) {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const users = await query(
        'SELECT id, email, full_name, role, user_role FROM users WHERE id = ? AND is_active = TRUE',
        [decoded.userId]
      );
      
      if (users.length > 0) {
        req.user = users[0];
      }
    }
    
    next();
  } catch (error) {
    // Игнорируем ошибки для опциональной аутентификации
    next();
  }
};

module.exports = {
  authenticate,
  authorize,
  optionalAuth
};

