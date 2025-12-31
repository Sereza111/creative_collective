# Creative Collective - Backend API

Backend API для системы управления творческим коллективом Creative Collective.

## 🚀 Технологии

- **Node.js** - Runtime environment
- **Express.js** - Web framework
- **MySQL** - Database
- **JWT** - Authentication
- **bcryptjs** - Password hashing
- **Docker** - Containerization

## 📋 Требования

- Node.js 18+ или Docker
- MySQL 8.0+ (если без Docker)
- npm или yarn

## 🛠️ Установка и запуск

### Вариант 1: С помощью Docker (Рекомендуется)

1. **Убедитесь, что Docker и Docker Compose установлены**

2. **Склонируйте репозиторий и перейдите в директорию backend:**
```bash
cd backend
```

3. **Создайте файл .env (или используйте существующий):**
```bash
cp .env.example .env
```

4. **Запустите контейнеры:**
```bash
docker-compose up -d
```

Это запустит:
- MySQL на порту 3306
- API Server на порту 3000

5. **Проверьте статус:**
```bash
docker-compose ps
```

6. **Проверьте работу API:**
```bash
curl http://localhost:3000/health
```

### Вариант 2: Локальный запуск

1. **Установите зависимости:**
```bash
npm install
```

2. **Настройте MySQL:**
- Создайте базу данных `creative_collective`
- Обновите файл `.env` с вашими настройками БД

3. **Инициализируйте базу данных:**
```bash
npm run migrate
```

4. **Запустите сервер:**

Для разработки (с hot-reload):
```bash
npm run dev
```

Для production:
```bash
npm start
```

## 📡 API Endpoints

### Аутентификация

- `POST /api/v1/auth/register` - Регистрация пользователя
- `POST /api/v1/auth/login` - Вход в систему
- `POST /api/v1/auth/refresh` - Обновление токена
- `POST /api/v1/auth/logout` - Выход
- `GET /api/v1/auth/me` - Получить текущего пользователя

### Задачи

- `GET /api/v1/tasks` - Получить все задачи (с фильтрацией)
- `GET /api/v1/tasks/:id` - Получить задачу по ID
- `POST /api/v1/tasks` - Создать задачу
- `PUT /api/v1/tasks/:id` - Обновить задачу
- `DELETE /api/v1/tasks/:id` - Удалить задачу

### Проекты

- `GET /api/v1/projects` - Получить все проекты
- `GET /api/v1/projects/:id` - Получить проект по ID
- `POST /api/v1/projects` - Создать проект
- `PUT /api/v1/projects/:id` - Обновить проект
- `DELETE /api/v1/projects/:id` - Удалить проект
- `POST /api/v1/projects/:id/members` - Добавить участника
- `DELETE /api/v1/projects/:id/members/:user_id` - Удалить участника

### Финансы

- `GET /api/v1/finance/:user_id` - Получить финансовую информацию
- `GET /api/v1/finance/:user_id/transactions` - Получить транзакции
- `POST /api/v1/finance/:user_id/transactions` - Создать транзакцию
- `GET /api/v1/finance/:user_id/stats` - Статистика

### Команды

- `GET /api/v1/teams` - Получить все команды
- `GET /api/v1/teams/:id` - Получить команду по ID
- `POST /api/v1/teams` - Создать команду
- `PUT /api/v1/teams/:id` - Обновить команду
- `DELETE /api/v1/teams/:id` - Удалить команду
- `POST /api/v1/teams/:id/members` - Добавить участника
- `DELETE /api/v1/teams/:id/members/:user_id` - Удалить участника
- `PUT /api/v1/teams/:id/members/:user_id` - Обновить участника

## 🔑 Аутентификация

API использует JWT токены для аутентификации. После входа вы получите:
- `accessToken` - для доступа к защищенным маршрутам (срок: 7 дней)
- `refreshToken` - для обновления accessToken (срок: 30 дней)

Используйте accessToken в заголовке:
```
Authorization: Bearer <accessToken>
```

## 📝 Примеры запросов

### Регистрация

```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "username": "johndoe",
    "password": "password123",
    "first_name": "John",
    "last_name": "Doe"
  }'
```

### Вход

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "denis@creative.com",
    "password": "password123"
  }'
```

### Получить задачи

```bash
curl -X GET "http://localhost:3000/api/v1/tasks?status=in_progress" \
  -H "Authorization: Bearer <your_token>"
```

### Создать задачу

```bash
curl -X POST http://localhost:3000/api/v1/tasks \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Новая задача",
    "description": "Описание задачи",
    "status": "todo",
    "priority": 3,
    "due_date": "2025-12-31",
    "project_id": "proj-1"
  }'
```

## 🗃️ База данных

### Схема

База данных включает следующие таблицы:
- `users` - Пользователи
- `teams` - Команды
- `team_members` - Участники команд
- `projects` - Проекты
- `project_members` - Участники проектов
- `tasks` - Задачи
- `finances` - Финансовые счета
- `transactions` - Транзакции
- `comments` - Комментарии
- `files` - Файлы
- `notifications` - Уведомления
- `refresh_tokens` - Refresh токены

### Тестовые данные

При первом запуске автоматически создаются тестовые данные:

**Пользователи** (пароль для всех: `password123`):
- `denis@creative.com` - Admin
- `ivan@creative.com` - Member (Битмейкер)
- `maria@creative.com` - Member (Дизайнер)
- `alexey@creative.com` - Member (Монтажер)

## 🐳 Docker команды

```bash
# Запустить контейнеры
docker-compose up -d

# Остановить контейнеры
docker-compose down

# Просмотр логов
docker-compose logs -f api

# Перезапустить API
docker-compose restart api

# Выполнить команду в контейнере
docker-compose exec api sh

# Удалить все (включая данные БД)
docker-compose down -v
```

## 🔧 Переменные окружения

Основные переменные в `.env`:

```env
# Server
NODE_ENV=development
PORT=3000

# Database
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=root
DB_NAME=creative_collective

# JWT
JWT_SECRET=your_secret_key
JWT_EXPIRES_IN=7d
JWT_REFRESH_SECRET=your_refresh_secret
JWT_REFRESH_EXPIRES_IN=30d

# CORS
CORS_ORIGIN=*
```

## 🧪 Тестирование

```bash
# Запустить тесты
npm test

# Запустить тесты с покрытием
npm run test:coverage
```

## 📦 Структура проекта

```
backend/
├── src/
│   ├── config/           # Конфигурация
│   │   └── database.js   # Настройки БД
│   ├── controllers/      # Контроллеры
│   │   ├── authController.js
│   │   ├── tasksController.js
│   │   ├── projectsController.js
│   │   ├── financeController.js
│   │   └── teamsController.js
│   ├── database/         # БД
│   │   ├── schema.sql    # Схема БД
│   │   ├── seed.sql      # Тестовые данные
│   │   └── init.js       # Инициализация
│   ├── middleware/       # Middleware
│   │   ├── auth.js
│   │   ├── errorHandler.js
│   │   └── validation.js
│   ├── routes/           # Маршруты
│   │   ├── auth.routes.js
│   │   ├── tasks.routes.js
│   │   ├── projects.routes.js
│   │   ├── finance.routes.js
│   │   └── teams.routes.js
│   ├── utils/            # Утилиты
│   │   └── helpers.js
│   └── server.js         # Главный файл
├── uploads/              # Загруженные файлы
├── .env                  # Переменные окружения
├── .gitignore
├── docker-compose.yml    # Docker конфигурация
├── Dockerfile
├── package.json
└── README.md
```

## 🚨 Устранение неполадок

### Ошибка подключения к БД

```bash
# Проверьте, что MySQL запущен
docker-compose ps

# Проверьте логи MySQL
docker-compose logs mysql

# Перезапустите контейнеры
docker-compose restart
```

### Порт уже занят

Измените порт в `.env` или `docker-compose.yml`:
```yaml
ports:
  - "3001:3000"  # Изменить внешний порт
```

## 📄 Лицензия

MIT

## 👨‍💻 Разработка

Для разработки используйте:

```bash
npm run dev  # Запуск с nodemon
```

## 🔗 Ссылки

- [Express.js Documentation](https://expressjs.com/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [JWT.io](https://jwt.io/)
- [Docker Documentation](https://docs.docker.com/)

