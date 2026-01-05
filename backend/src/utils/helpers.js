const crypto = require('crypto');

// Генерация UUID v4
const generateUUID = () => {
  return crypto.randomUUID();
};

// Форматирование даты для MySQL
const formatDateForMySQL = (date) => {
  if (!date) return null;
  const d = new Date(date);
  return d.toISOString().slice(0, 19).replace('T', ' ');
};

// Пагинация
const getPagination = (page = 1, limit = 10) => {
  const pageNum = parseInt(page) || 1;
  const limitNum = parseInt(limit) || 10;
  const offset = (pageNum - 1) * limitNum;
  return {
    limit: limitNum,
    offset: offset
  };
};

// Ответ с пагинацией
const paginatedResponse = (data, total, page, limit) => {
  const totalPages = Math.ceil(total / limit);
  return {
    data,
    pagination: {
      total,
      page: parseInt(page),
      limit: parseInt(limit),
      totalPages,
      hasNext: page < totalPages,
      hasPrev: page > 1
    }
  };
};

// Успешный ответ
const successResponse = (res, data, message = 'Success', statusCode = 200) => {
  res.status(statusCode).json({
    success: true,
    message,
    data
  });
};

// Ответ с ошибкой
const errorResponse = (res, message = 'Error', statusCode = 500, errors = null) => {
  res.status(statusCode).json({
    success: false,
    message,
    ...(errors && { errors })
  });
};

module.exports = {
  generateUUID,
  formatDateForMySQL,
  getPagination,
  paginatedResponse,
  successResponse,
  errorResponse
};

