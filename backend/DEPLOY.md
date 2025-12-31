# 🚀 Инструкция по развертыванию Creative Collective Backend

## Вариант 1: Развертывание на существующем Node.js сервере

### Шаг 1: Подготовка сервера

```bash
# Подключитесь к серверу по SSH
ssh user@your-server-ip

# Установите Node.js (если еще не установлен)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Проверьте установку
node --version
npm --version
```

### Шаг 2: Загрузка проекта

```bash
# Создайте директорию для проекта
mkdir -p /var/www/creative_collective
cd /var/www/creative_collective

# Склонируйте или загрузите backend
# Вариант 1: Через git
git clone https://github.com/your-repo/creative_collective.git backend

# Вариант 2: Загрузите через SCP
# На локальной машине:
scp -r ./backend user@your-server-ip:/var/www/creative_collective/
```

### Шаг 3: Установка зависимостей

```bash
cd /var/www/creative_collective/backend
npm install --production
```

### Шаг 4: Настройка MySQL

```bash
# Войдите в MySQL
sudo mysql -u root -p

# Создайте базу данных и пользователя
CREATE DATABASE creative_collective CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'creative_user'@'localhost' IDENTIFIED BY 'your_secure_password';
GRANT ALL PRIVILEGES ON creative_collective.* TO 'creative_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### Шаг 5: Настройка окружения

```bash
# Создайте .env файл
nano .env
```

Вставьте конфигурацию:
```env
NODE_ENV=production
PORT=3000

DB_HOST=localhost
DB_PORT=3306
DB_USER=creative_user
DB_PASSWORD=your_secure_password
DB_NAME=creative_collective

JWT_SECRET=your_very_long_random_secret_key_min_32_chars
JWT_EXPIRES_IN=7d
JWT_REFRESH_SECRET=your_refresh_secret_also_very_long
JWT_REFRESH_EXPIRES_IN=30d

CORS_ORIGIN=https://your-frontend-domain.com

RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

### Шаг 6: Инициализация базы данных

```bash
# Запустите скрипт инициализации
node src/database/init.js
```

### Шаг 7: Установка PM2 (Process Manager)

```bash
# Установите PM2 глобально
sudo npm install -g pm2

# Запустите приложение с PM2
pm2 start src/server.js --name creative-api

# Настройте автозапуск при перезагрузке сервера
pm2 startup
pm2 save

# Проверьте статус
pm2 status
pm2 logs creative-api
```

### Шаг 8: Настройка Nginx (Reverse Proxy)

```bash
# Установите Nginx
sudo apt-get install nginx

# Создайте конфигурацию
sudo nano /etc/nginx/sites-available/creative-api
```

Вставьте конфигурацию:
```nginx
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Таймауты
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

```bash
# Активируйте конфигурацию
sudo ln -s /etc/nginx/sites-available/creative-api /etc/nginx/sites-enabled/

# Проверьте конфигурацию
sudo nginx -t

# Перезапустите Nginx
sudo systemctl restart nginx
```

### Шаг 9: Настройка SSL (Let's Encrypt)

```bash
# Установите Certbot
sudo apt-get install certbot python3-certbot-nginx

# Получите SSL сертификат
sudo certbot --nginx -d api.yourdomain.com

# Certbot автоматически настроит SSL и авто-обновление
```

### Шаг 10: Настройка Firewall

```bash
# Откройте необходимые порты
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
sudo ufw enable
```

### Проверка

```bash
# Проверьте работу API
curl https://api.yourdomain.com/health

# Должен вернуть:
# {"success":true,"status":"healthy","database":"connected",...}
```

## Вариант 2: Развертывание с Docker на сервере

### Шаг 1: Установка Docker

```bash
# Установите Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Установите Docker Compose
sudo apt-get install docker-compose

# Добавьте пользователя в группу docker
sudo usermod -aG docker $USER
newgrp docker
```

### Шаг 2: Загрузка проекта

```bash
# Создайте директорию
mkdir -p /var/www/creative_collective
cd /var/www/creative_collective

# Загрузите backend
# (через git или scp, как в варианте 1)
```

### Шаг 3: Настройка окружения

```bash
cd backend
nano .env
```

Используйте ту же конфигурацию, что и в варианте 1, но:
```env
DB_HOST=mysql  # Важно! Используйте имя сервиса из docker-compose
```

### Шаг 4: Запуск с Docker Compose

```bash
# Запустите контейнеры
docker-compose up -d

# Проверьте статус
docker-compose ps

# Проверьте логи
docker-compose logs -f api

# Проверьте работу
curl http://localhost:3000/health
```

### Шаг 5: Настройка Nginx

Используйте ту же конфигурацию Nginx, что и в варианте 1.

## Вариант 3: Использование Portainer (рекомендуется)

### Шаг 1: Установка Portainer

```bash
# Создайте volume для Portainer
docker volume create portainer_data

# Запустите Portainer
docker run -d \
  -p 9000:9000 \
  -p 9443:9443 \
  --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest
```

### Шаг 2: Доступ к Portainer

1. Откройте браузер: `https://your-server-ip:9443`
2. Создайте admin аккаунт
3. Выберите "Docker" environment

### Шаг 3: Создание Stack в Portainer

1. В Portainer перейдите: **Stacks → Add stack**
2. Название: `creative-collective`
3. Вставьте содержимое `docker-compose.yml`
4. В разделе "Environment variables" добавьте переменные из `.env`
5. Нажмите **Deploy the stack**

### Шаг 4: Мониторинг

В Portainer вы можете:
- Просматривать логи контейнеров
- Перезапускать сервисы
- Мониторить ресурсы (CPU, RAM)
- Обновлять конфигурацию

## 🔧 Управление приложением

### PM2 команды (Вариант 1)

```bash
# Просмотр логов
pm2 logs creative-api

# Перезапуск
pm2 restart creative-api

# Остановка
pm2 stop creative-api

# Удаление из PM2
pm2 delete creative-api

# Просмотр метрик
pm2 monit
```

### Docker команды (Вариант 2 и 3)

```bash
# Просмотр логов
docker-compose logs -f api

# Перезапуск сервисов
docker-compose restart

# Остановка
docker-compose down

# Обновление после изменений
docker-compose up -d --build

# Просмотр использования ресурсов
docker stats
```

## 🔄 Обновление приложения

### Для PM2:

```bash
cd /var/www/creative_collective/backend
git pull origin main  # или загрузите новые файлы
npm install --production
pm2 restart creative-api
```

### Для Docker:

```bash
cd /var/www/creative_collective/backend
git pull origin main  # или загрузите новые файлы
docker-compose down
docker-compose up -d --build
```

## 📊 Мониторинг и логи

### Просмотр логов Nginx

```bash
# Access logs
sudo tail -f /var/log/nginx/access.log

# Error logs
sudo tail -f /var/log/nginx/error.log
```

### Просмотр логов MySQL

```bash
# Для Docker
docker-compose logs -f mysql

# Для системного MySQL
sudo tail -f /var/log/mysql/error.log
```

## 🔐 Безопасность

### 1. Настройка автоматических обновлений

```bash
sudo apt-get install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

### 2. Ограничение доступа к MySQL

```bash
# Отредактируйте конфигурацию MySQL
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf

# Убедитесь, что:
bind-address = 127.0.0.1
```

### 3. Регулярные бэкапы БД

```bash
# Создайте скрипт бэкапа
nano /usr/local/bin/backup-db.sh
```

```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/var/backups/mysql"
mkdir -p $BACKUP_DIR

mysqldump -u creative_user -p'your_password' creative_collective \
  | gzip > $BACKUP_DIR/creative_collective_$DATE.sql.gz

# Удалить бэкапы старше 7 дней
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete
```

```bash
chmod +x /usr/local/bin/backup-db.sh

# Добавьте в cron (ежедневно в 3:00)
crontab -e
0 3 * * * /usr/local/bin/backup-db.sh
```

## ❗ Устранение проблем

### Приложение не запускается

```bash
# Проверьте порты
sudo netstat -tulpn | grep :3000

# Проверьте права на файлы
ls -la /var/www/creative_collective/backend

# Проверьте логи
pm2 logs creative-api --lines 100
# или
docker-compose logs --tail=100 api
```

### Ошибка подключения к БД

```bash
# Проверьте, что MySQL запущен
sudo systemctl status mysql
# или
docker-compose ps mysql

# Проверьте подключение
mysql -u creative_user -p -h localhost creative_collective
```

### Высокая нагрузка

```bash
# Увеличьте количество процессов PM2
pm2 scale creative-api +2  # Добавить 2 процесса

# Или используйте cluster mode
pm2 delete creative-api
pm2 start src/server.js -i max --name creative-api
```

## 📞 Поддержка

При возникновении проблем:
1. Проверьте логи: `pm2 logs` или `docker-compose logs`
2. Проверьте health endpoint: `curl http://localhost:3000/health`
3. Проверьте переменные окружения: `cat .env`
4. Проверьте подключение к БД

## ✅ Чеклист развертывания

- [ ] Node.js и npm установлены
- [ ] MySQL установлен и настроен
- [ ] Проект загружен на сервер
- [ ] Зависимости установлены
- [ ] .env файл настроен
- [ ] База данных инициализирована
- [ ] PM2/Docker запущен
- [ ] Nginx настроен
- [ ] SSL сертификат установлен
- [ ] Firewall настроен
- [ ] Бэкапы настроены
- [ ] Мониторинг работает
- [ ] Health check возвращает OK

