# 🚀 Развертывание через GitHub + Portainer

## Шаг 1: Залить проект на GitHub

### 1.1 Создайте репозиторий на GitHub

1. Откройте https://github.com
2. Нажмите **New repository**
3. Название: `creative-collective`
4. Выберите **Public** или **Private**
5. Нажмите **Create repository**

### 1.2 Залейте код на GitHub

На вашем компьютере откройте терминал (PowerShell или Git Bash):

```bash
# Перейдите в папку проекта
cd C:\Users\Yozik\creative_collective

# Инициализируйте git (если еще не сделано)
git init

# Добавьте все файлы
git add .

# Сделайте первый коммит
git commit -m "Initial commit - Creative Collective Backend"

# Добавьте remote (замените YOUR_USERNAME на ваш GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/creative-collective.git

# Отправьте на GitHub
git branch -M main
git push -u origin main
```

**Если Git запросит авторизацию:**
- Используйте **Personal Access Token** вместо пароля
- Создать токен: GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic) → Generate new token

---

## Шаг 2: Настройте Portainer

### 2.1 Создайте Stack в Portainer

1. Откройте Portainer: `https://85.198.103.11:9443`
2. Перейдите: **Stacks → Add stack**
3. Название: `creative-collective`

### 2.2 Выберите метод: **Repository**

Выберите третью кнопку **"Repository"** (с иконкой Git)

### 2.3 Заполните настройки репозитория:

**Repository URL:**
```
https://github.com/YOUR_USERNAME/creative-collective
```

**Repository reference:**
```
refs/heads/main
```

**Compose path:**
```
backend/docker-compose.github.yml
```

**Если репозиторий Private:**
- Включите **Authentication**
- Username: ваш GitHub username
- Personal Access Token: ваш GitHub token

### 2.4 Настройте переменные окружения (Environment variables)

Добавьте важные переменные (нажмите "+ Add an environment variable"):

```
DB_PASSWORD=your_secure_password_123
JWT_SECRET=your_super_secret_jwt_key_at_least_32_characters_long
JWT_REFRESH_SECRET=your_refresh_secret_also_very_long_key_here
API_PORT=3000
MYSQL_PORT=3306
```

**⚠️ ВАЖНО:** Используйте безопасные пароли для production!

### 2.5 Deploy

1. Прокрутите вниз
2. Нажмите **Deploy the stack**
3. Подождите 1-2 минуты (Docker собирает образ)

---

## Шаг 3: Проверьте работу

### 3.1 Проверьте контейнеры

В Portainer:
1. Перейдите: **Stacks → creative-collective**
2. Убедитесь, что оба контейнера запущены (зеленые)
3. Кликните на `creative_collective_api` → **Logs**

### 3.2 Проверьте API

Откройте в браузере:
```
http://85.198.103.11:3000/health
```

Должен вернуть:
```json
{
  "success": true,
  "status": "healthy",
  "database": "connected",
  "uptime": 123.45,
  "timestamp": "2025-12-31T..."
}
```

### 3.3 Протестируйте вход

```bash
curl -X POST http://85.198.103.11:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"denis@creative.com","password":"password123"}'
```

---

## 🔄 Обновление приложения

Когда вы внесете изменения в код:

### На компьютере:
```bash
cd C:\Users\Yozik\creative_collective
git add .
git commit -m "Update: описание изменений"
git push
```

### В Portainer:
1. Откройте **Stacks → creative-collective**
2. Нажмите **Pull and redeploy** (иконка обновления)
3. Подтвердите
4. Portainer автоматически:
   - Скачает новый код с GitHub
   - Пересоберет Docker образ
   - Перезапустит контейнеры

**Готово!** Обновление займет 1-2 минуты.

---

## 📊 Мониторинг

### Логи в реальном времени:
1. **Stacks → creative-collective**
2. Кликните на контейнер
3. **Logs** → включите **Auto-refresh**

### Статистика ресурсов:
1. **Containers**
2. Кликните на контейнер
3. **Stats** - график CPU, RAM, Network

---

## ⚠️ Устранение проблем

### Контейнер не запускается

**Проверьте логи:**
```
Stacks → creative-collective → api → Logs
```

**Частые причины:**
1. Неверные переменные окружения
2. Порт уже занят (измените `API_PORT=3001`)
3. MySQL не запустился (проверьте `DB_PASSWORD`)

### Порт занят

Измените в Environment variables:
```
API_PORT=3001
MYSQL_PORT=3307
```

### База данных не инициализируется

1. Удалите volume:
```bash
docker volume rm creative-collective_mysql_data
```
2. Redeploy stack в Portainer

---

## 🔐 Безопасность

**Обязательно измените в production:**

1. **DB_PASSWORD** - сложный пароль для MySQL
2. **JWT_SECRET** - случайная строка 32+ символов
3. **JWT_REFRESH_SECRET** - другая случайная строка
4. **CORS_ORIGIN** - укажите домен фронтенда

**Генерация случайных ключей:**

```bash
# Linux/Mac
openssl rand -base64 32

# Windows PowerShell
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }))
```

---

## 📚 Полезные команды

### Остановить stack:
Portainer: **Stacks → creative-collective → Stop**

### Просмотр всех контейнеров:
Portainer: **Containers**

### Удалить stack полностью:
Portainer: **Stacks → creative-collective → Remove** (удалит и volumes!)

### Сделать backup БД:
```bash
docker exec creative_collective_db mysqldump -u creative_user -p creative_collective > backup.sql
```

---

## ✅ Преимущества этого метода

✅ Версионирование через Git  
✅ Легкие обновления одной кнопкой  
✅ Можно откатиться к любой версии  
✅ Вся команда может работать с одним репозиторием  
✅ Автоматическая сборка образов  
✅ CI/CD готовность  

---

## 🎯 Следующие шаги

1. ✅ Залить на GitHub
2. ✅ Настроить Stack в Portainer через Repository
3. ✅ Проверить работу API
4. 🔜 Подключить Flutter приложение
5. 🔜 Настроить домен и SSL
6. 🔜 Добавить GitHub Actions для CI/CD

---

**Готово!** Ваш backend теперь развернут профессионально! 🚀

