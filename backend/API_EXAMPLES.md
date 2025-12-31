# API Examples - Creative Collective

Примеры использования API Creative Collective

## Базовый URL

```
http://localhost:3000/api/v1
```

## 🔑 Аутентификация

### 1. Регистрация нового пользователя

**POST** `/auth/register`

```json
{
  "email": "test@example.com",
  "username": "testuser",
  "password": "password123",
  "first_name": "Test",
  "last_name": "User"
}
```

**Ответ:**
```json
{
  "success": true,
  "message": "Регистрация успешна",
  "data": {
    "user": {
      "id": "uuid",
      "email": "test@example.com",
      "username": "testuser",
      "first_name": "Test",
      "last_name": "User",
      "role": "member"
    },
    "accessToken": "jwt_token",
    "refreshToken": "refresh_token"
  }
}
```

### 2. Вход в систему

**POST** `/auth/login`

```json
{
  "email": "denis@creative.com",
  "password": "password123"
}
```

**Тестовые аккаунты:**
- `denis@creative.com` (Admin)
- `ivan@creative.com` (Битмейкер)
- `maria@creative.com` (Дизайнер)
- `alexey@creative.com` (Монтажер)

Пароль для всех: `password123`

### 3. Получить текущего пользователя

**GET** `/auth/me`

Headers: `Authorization: Bearer {accessToken}`

### 4. Обновить токен

**POST** `/auth/refresh`

```json
{
  "refreshToken": "your_refresh_token"
}
```

## 📋 Задачи

### 1. Получить все задачи

**GET** `/tasks`

Query параметры:
- `page` - номер страницы (default: 1)
- `limit` - количество на странице (default: 20)
- `project_id` - фильтр по проекту
- `status` - фильтр по статусу (todo, in_progress, review, done, cancelled)
- `assigned_to` - фильтр по исполнителю
- `priority` - фильтр по приоритету (1-5)
- `search` - поиск по названию и описанию

**Пример:**
```
GET /tasks?status=in_progress&priority=3&page=1&limit=10
```

### 2. Получить задачу по ID

**GET** `/tasks/{task_id}`

### 3. Создать задачу

**POST** `/tasks`

```json
{
  "title": "Создать дизайн главной страницы",
  "description": "Разработать современный дизайн для главной страницы приложения",
  "status": "todo",
  "priority": 4,
  "due_date": "2025-12-31T23:59:59",
  "project_id": "proj-1",
  "assigned_to": "user-3"
}
```

### 4. Обновить задачу

**PUT** `/tasks/{task_id}`

```json
{
  "status": "in_progress",
  "priority": 5
}
```

### 5. Удалить задачу

**DELETE** `/tasks/{task_id}`

## 📁 Проекты

### 1. Получить все проекты

**GET** `/projects`

Query параметры:
- `page`, `limit` - пагинация
- `status` - фильтр (planning, active, on_hold, completed, cancelled)
- `team_id` - фильтр по команде
- `search` - поиск

### 2. Получить проект по ID

**GET** `/projects/{project_id}`

### 3. Создать проект

**POST** `/projects`

```json
{
  "name": "Мобильное приложение для доставки",
  "description": "Разработка полнофункционального приложения для доставки еды",
  "status": "planning",
  "start_date": "2025-01-01",
  "end_date": "2025-06-30",
  "progress": 0,
  "budget": 500000.00,
  "spent": 0,
  "team_id": "team-1"
}
```

### 4. Обновить проект

**PUT** `/projects/{project_id}`

```json
{
  "progress": 45,
  "spent": 225000.00,
  "status": "active"
}
```

### 5. Добавить участника в проект

**POST** `/projects/{project_id}/members`

```json
{
  "user_id": "user-2",
  "role": "Backend Developer"
}
```

### 6. Удалить участника из проекта

**DELETE** `/projects/{project_id}/members/{user_id}`

## 💰 Финансы

### 1. Получить финансовую информацию

**GET** `/finance/{user_id}`

Получить баланс, общую статистику и последние транзакции пользователя.

### 2. Получить транзакции

**GET** `/finance/{user_id}/transactions`

Query параметры:
- `page`, `limit` - пагинация
- `type` - фильтр (earned, spent, bonus, penalty)
- `category` - фильтр по категории
- `start_date`, `end_date` - период

**Пример:**
```
GET /finance/user-1/transactions?type=earned&start_date=2025-12-01&end_date=2025-12-31
```

### 3. Создать транзакцию

**POST** `/finance/{user_id}/transactions`

```json
{
  "type": "earned",
  "amount": 15000.00,
  "description": "Оплата за разработку модуля авторизации",
  "project_id": "proj-1",
  "category": "Разработка"
}
```

Типы транзакций:
- `earned` - заработок
- `spent` - расход
- `bonus` - бонус
- `penalty` - штраф

### 4. Получить статистику

**GET** `/finance/{user_id}/stats`

Query параметры:
- `start_date`, `end_date` - период

Возвращает статистику по типам, категориям и проектам.

## 👥 Команды

### 1. Получить все команды

**GET** `/teams`

### 2. Получить команду по ID

**GET** `/teams/{team_id}`

Возвращает команду с участниками и проектами.

### 3. Создать команду

**POST** `/teams`

```json
{
  "name": "Design Team",
  "description": "Команда дизайнеров и UI/UX специалистов"
}
```

### 4. Обновить команду

**PUT** `/teams/{team_id}`

```json
{
  "name": "Creative Design Team",
  "description": "Обновленное описание"
}
```

### 5. Добавить участника в команду

**POST** `/teams/{team_id}/members`

```json
{
  "user_id": "user-3",
  "role": "UI/UX Designer",
  "skills": ["Figma", "Sketch", "Adobe XD", "Prototyping"]
}
```

### 6. Обновить участника команды

**PUT** `/teams/{team_id}/members/{user_id}`

```json
{
  "role": "Lead UI/UX Designer",
  "skills": ["Figma", "Sketch", "Adobe XD", "Prototyping", "Design Systems"]
}
```

### 7. Удалить участника из команды

**DELETE** `/teams/{team_id}/members/{user_id}`

## 📊 Примеры сложных запросов

### Получить задачи с высоким приоритетом в активных проектах

```
GET /tasks?priority=5&status=todo&page=1
```

### Получить финансовую статистику за декабрь 2025

```
GET /finance/user-1/stats?start_date=2025-12-01&end_date=2025-12-31
```

### Поиск проектов по ключевому слову

```
GET /projects?search=видеоклип&status=active
```

## ⚠️ Обработка ошибок

Все ошибки возвращаются в формате:

```json
{
  "success": false,
  "message": "Описание ошибки",
  "errors": [...]  // опционально
}
```

HTTP коды ошибок:
- `400` - Bad Request (неверные данные)
- `401` - Unauthorized (нет/неверный токен)
- `403` - Forbidden (недостаточно прав)
- `404` - Not Found (ресурс не найден)
- `409` - Conflict (конфликт данных)
- `500` - Internal Server Error

## 🧪 Тестирование с curl

### Полный workflow

```bash
# 1. Вход
TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"denis@creative.com","password":"password123"}' \
  | jq -r '.data.accessToken')

# 2. Получить задачи
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/tasks

# 3. Создать задачу
curl -X POST http://localhost:3000/api/v1/tasks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test task",
    "description": "Test description",
    "priority": 3,
    "due_date": "2025-12-31",
    "project_id": "proj-1"
  }'

# 4. Получить финансы
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/v1/finance/user-1
```

## 📦 Postman Collection

Импортируйте следующий JSON в Postman для быстрого старта:

```json
{
  "info": {
    "name": "Creative Collective API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Auth",
      "item": [
        {
          "name": "Login",
          "request": {
            "method": "POST",
            "header": [],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"email\": \"denis@creative.com\",\n  \"password\": \"password123\"\n}",
              "options": {
                "raw": {
                  "language": "json"
                }
              }
            },
            "url": {
              "raw": "{{baseUrl}}/auth/login",
              "host": ["{{baseUrl}}"],
              "path": ["auth", "login"]
            }
          }
        }
      ]
    }
  ],
  "variable": [
    {
      "key": "baseUrl",
      "value": "http://localhost:3000/api/v1"
    }
  ]
}
```

## 🎯 Tips & Best Practices

1. **Всегда используйте пагинацию** для списков
2. **Обрабатывайте 401 ошибки** - обновляйте токен
3. **Валидируйте данные** перед отправкой
4. **Используйте фильтры** для оптимизации запросов
5. **Кешируйте токены** на клиенте
6. **Логируйте ошибки** для отладки

