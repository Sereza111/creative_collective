// Централизованная обработка ошибок
const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);
  
  // Ошибки валидации
  if (err.name === 'ValidationError') {
    return res.status(400).json({
      success: false,
      message: 'Ошибка валидации',
      errors: err.errors
    });
  }
  
  // Ошибки базы данных
  if (err.code === 'ER_DUP_ENTRY') {
    return res.status(409).json({
      success: false,
      message: 'Запись уже существует'
    });
  }
  
  if (err.code === 'ER_NO_REFERENCED_ROW_2') {
    return res.status(400).json({
      success: false,
      message: 'Связанная запись не найдена'
    });
  }
  
  // JWT ошибки
  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({
      success: false,
      message: 'Неверный токен'
    });
  }
  
  if (err.name === 'TokenExpiredError') {
    return res.status(401).json({
      success: false,
      message: 'Токен истек'
    });
  }
  
  // Multer ошибки (загрузка файлов)
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(413).json({
      success: false,
      message: 'Файл слишком большой'
    });
  }
  
  // Дефолтная ошибка сервера
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Внутренняя ошибка сервера',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};

// 404 обработчик
const notFound = (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Маршрут не найден'
  });
};

module.exports = {
  errorHandler,
  notFound
};

