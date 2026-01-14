/**
 * Утилиты для стандартизированных ответов API
 */

/**
 * Успешный ответ
 * @param {Object} res - Express response object
 * @param {*} data - Данные для отправки
 * @param {string} message - Сообщение (опционально)
 * @param {number} statusCode - HTTP код (по умолчанию 200)
 */
exports.successResponse = (res, data, message = 'Success', statusCode = 200) => {
  return res.status(statusCode).json({
    success: true,
    message,
    data,
  });
};

/**
 * Ответ с ошибкой
 * @param {Object} res - Express response object
 * @param {string} message - Сообщение об ошибке
 * @param {number} statusCode - HTTP код (по умолчанию 500)
 * @param {*} errors - Детали ошибок (опционально)
 */
exports.errorResponse = (res, message = 'Internal Server Error', statusCode = 500, errors = null) => {
  return res.status(statusCode).json({
    success: false,
    message,
    ...(errors && { errors }),
  });
};

