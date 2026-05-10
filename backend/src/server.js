const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const { testConnection, createDatabaseIfNotExists } = require('./config/database');
const { initializeDatabase } = require('./database/init');
const { errorHandler, notFound } = require('./middleware/errorHandler');

// Импорт роутеров
const authRoutes = require('./routes/auth.routes');
const tasksRoutes = require('./routes/tasks.routes');
const projectsRoutes = require('./routes/projects.routes');
const financeRoutes = require('./routes/finance.routes');
const teamsRoutes = require('./routes/teams.routes');
const chatRoutes = require('./routes/chat.routes');
const reviewsRoutes = require('./routes/reviews.routes');
const portfolioRoutes = require('./routes/portfolio.routes');
const adminRoutes = require('./routes/admin.routes');
const favoritesRoutes = require('./routes/favorites.routes');
const notificationsRoutes = require('./routes/notifications.routes');
const disputesRoutes = require('./routes/disputes.routes');
const legalRoutes = require('./routes/legal.routes');

const app = express();
const PORT = process.env.PORT || 3000;
const API_VERSION = process.env.API_VERSION || 'v1';

// ===== MIDDLEWARE =====

// Безопасность
app.use(helmet());

// CORS (default * if unset; production should set comma-separated origins)
const corsOriginEnv = process.env.CORS_ORIGIN;
const corsOrigin =
  !corsOriginEnv || corsOriginEnv === '*'
    ? '*'
    : corsOriginEnv.split(',').map((s) => s.trim()).filter(Boolean);
app.use(cors({
  origin: corsOrigin,
  credentials: true
}));

// Логирование
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// Парсинг тела запроса
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Сжатие ответов
app.use(compression());

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 минут
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: 'Слишком много запросов с этого IP, попробуйте позже'
});
app.use(`/api/${API_VERSION}`, limiter);

// ===== ROUTES =====

// Базовый роут для проверки работы сервера
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Creative Collective API Server',
    version: API_VERSION,
    timestamp: new Date().toISOString()
  });
});

// Health check
app.get('/health', async (req, res) => {
  const dbConnected = await testConnection();
  res.status(dbConnected ? 200 : 503).json({
    success: dbConnected,
    status: dbConnected ? 'healthy' : 'unhealthy',
    database: dbConnected ? 'connected' : 'disconnected',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

// API роуты
app.use(`/api/${API_VERSION}/auth`, authRoutes);
app.use(`/api/${API_VERSION}/tasks`, tasksRoutes);
app.use(`/api/${API_VERSION}/projects`, projectsRoutes);
app.use(`/api/${API_VERSION}/finance`, require('./routes/finance.routes'));
app.use(`/api/${API_VERSION}/teams`, teamsRoutes);
app.use(`/api/${API_VERSION}/orders`, require('./routes/orders.routes'));
app.use(`/api/${API_VERSION}/chat`, chatRoutes);
app.use(`/api/${API_VERSION}/reviews`, reviewsRoutes);
app.use(`/api/${API_VERSION}/portfolio`, portfolioRoutes);
app.use(`/api/${API_VERSION}/admin`, adminRoutes);
app.use(`/api/${API_VERSION}/favorites`, favoritesRoutes);
app.use(`/api/${API_VERSION}/notifications`, notificationsRoutes);
app.use(`/api/${API_VERSION}/disputes`, disputesRoutes);
app.use(`/api/${API_VERSION}/legal`, legalRoutes);

// 404 обработчик
app.use(notFound);

// Обработчик ошибок
app.use(errorHandler);

// ===== ЗАПУСК СЕРВЕРА =====

async function startServer() {
  try {
    console.log('🚀 Starting Creative Collective API Server...');
    console.log(`📦 Environment: ${process.env.NODE_ENV || 'development'}`);
    
    // Создаем БД если не существует
    await createDatabaseIfNotExists();
    
    // Проверяем подключение к БД
    const connected = await testConnection();
    if (!connected) {
      throw new Error('Failed to connect to database');
    }
    
    // Инициализируем схему БД
    await initializeDatabase();
    
    // Инициализируем планировщик задач
    const { initScheduler } = require('./jobs/scheduler');
    initScheduler();
    
    // Запускаем сервер
    app.listen(PORT, () => {
      console.log(`✅ Server is running on port ${PORT}`);
      console.log(`🌐 API: http://localhost:${PORT}/api/${API_VERSION}`);
      console.log(`📝 Health check: http://localhost:${PORT}/health`);
      console.log('');
      console.log('📚 Available endpoints:');
      console.log(`   POST   /api/${API_VERSION}/auth/register`);
      console.log(`   POST   /api/${API_VERSION}/auth/login`);
      console.log(`   GET    /api/${API_VERSION}/tasks`);
      console.log(`   GET    /api/${API_VERSION}/projects`);
      console.log(`   GET    /api/${API_VERSION}/teams`);
      console.log(`   GET    /api/${API_VERSION}/finance/:user_id`);
      console.log('');
    });
    
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

// Обработка необработанных отклонений промисов
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

// Обработка необработанных исключений
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT signal received: closing HTTP server');
  process.exit(0);
});

// Запускаем сервер
startServer();

module.exports = app;

