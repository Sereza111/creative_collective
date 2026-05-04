# ⚡ Быстрый старт - Creative Collective Backend

## 🚀 Запуск за 3 минуты

### Вариант 1: С Docker (самый простой)

```bash
# 1. Перейдите в директорию backend
cd backend

# 2. Запустите все сервисы
docker-compose up -d

# 3. Проверьте статус
docker-compose ps

# 4. Проверьте работу API
curl http://localhost:3000/health
```

**Готово!** API работает на `http://localhost:3000`

### Вариант 2: Без Docker (требуется MySQL)

```bash
# 1. Убедитесь, что MySQL запущен
# Windows: проверьте в Services
# Linux: sudo systemctl status mysql

# 2. Создайте базу данных (один раз)
mysql -u root -p
CREATE DATABASE creative_collective;
EXIT;

# 3. Установите зависимости (уже сделано)
npm install

# 4. Настройте .env
# Файл уже создан, просто проверьте настройки БД

# 5. Запустите сервер
npm start
```

## 📱 Тестовые аккаунты

При первом запуске автоматически создаются тестовые данные:

| Email | Пароль | Роль |
|-------|--------|------|
| `denis@creative.com` | `password123` | Admin |
| `ivan@creative.com` | `password123` | Member |
| `maria@creative.com` | `password123` | Member |
| `alexey@creative.com` | `password123` | Member |

## 🧪 Быстрый тест API

### 1. Войти в систему

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"denis@creative.com","password":"password123"}'
```

Сохраните полученный `accessToken`

### 2. Получить задачи

```bash
ACCESS_TOKEN="paste_access_token_here"

curl http://localhost:3000/api/v1/tasks \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

### 3. Создать задачу

```bash
curl -X POST http://localhost:3000/api/v1/tasks \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Моя первая задача",
    "description": "Тестовая задача",
    "status": "todo",
    "priority": 3,
    "due_date": "2025-12-31T23:59:59",
    "project_id": "proj-1"
  }'
```

## 📊 Endpoints

```
GET  /health                      - Проверка здоровья
POST /api/v1/auth/login          - Вход
GET  /api/v1/tasks               - Все задачи
GET  /api/v1/projects            - Все проекты
GET  /api/v1/teams               - Все команды
GET  /api/v1/finance/:user_id    - Финансы пользователя
```

Полный список: см. `API_EXAMPLES.md`

## 🔧 Полезные команды

### Docker

```bash
# Просмотр логов
docker-compose logs -f api

# Перезапуск
docker-compose restart api

# Остановка
docker-compose down

# Полная очистка (включая данные БД!)
docker-compose down -v
```

### Без Docker

```bash
# Разработка (auto-reload)
npm run dev

# Production
npm start

# Инициализация БД заново
npm run migrate
```

## ❗ Решение проблем

### Порт 3000 занят

Измените PORT в `.env`:
```env
PORT=3001
```

### MySQL не подключается

Проверьте настройки в `.env`:
```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=ваш_пароль
DB_NAME=creative_collective
```

### Docker не запускается

```bash
# Проверьте Docker
docker --version

# Проверьте, что Docker запущен
docker ps

# Пересоздайте контейнеры
docker-compose down
docker-compose up -d --build
```

## 📚 Дополнительные материалы

- `README.md` - Полная документация
- `API_EXAMPLES.md` - Примеры всех API запросов
- `DEPLOY.md` - Инструкция по развертыванию на сервере

## ✅ Чеклист

- [ ] MySQL установлен и запущен (или используется Docker)
- [ ] `npm install` выполнен
- [ ] `.env` настроен
- [ ] Сервер запущен
- [ ] `http://localhost:3000/health` возвращает OK
- [ ] Вход через тестовый аккаунт работает

## 🎯 Следующие шаги

1. **Изучите API**: откройте `API_EXAMPLES.md`
2. **Протестируйте endpoints**: используйте Postman или curl
3. **Подключите Frontend**: обновите `lib/services/api_service.dart`
4. **Разверните на сервер**: следуйте `DEPLOY.md`

## 💡 Tips

- Используйте `npm run dev` для разработки (auto-reload)
- Логи Docker: `docker-compose logs -f`
- Health check: `http://localhost:3000/health`
- Тестовые данные создаются автоматически при первом запуске

---

**Нужна помощь?** Проверьте раздел "Устранение проблем" в `README.md`

