# Деплой через Docker Compose с внешней MySQL

По умолчанию схема запускает два контейнера на приложенческом сервере:

- `api` - Express API;
- `web` - release-сборка Flutter Web;
- системный Nginx сервера принимает HTTPS и проксирует запросы в контейнеры.

MySQL в compose не запускается. Приложение подключается к существующему серверу БД.

## 1. Подготовка DNS и firewall

Создайте A-запись `creative.yozik.ru`, указывающую на публичный IP нового сервера. Откройте входящие TCP-порты `22`, `80` и `443`.

На сервере MySQL разрешите подключения с IP приложенческого сервера. Не открывайте MySQL для всего интернета. Пользователю приложения нужны права на выбранную базу, включая DDL для миграций (`CREATE`, `ALTER`, `INDEX`), но не глобальные административные права.

База `creative_collective` должна существовать заранее. Backend не создаёт базу в production, но создаёт и обновляет таблицы внутри неё.

## 2. Клонирование

```bash
sudo mkdir -p /opt/creative-collective
sudo chown "$USER":"$USER" /opt/creative-collective
git clone https://github.com/Sereza111/creative_collective.git /opt/creative-collective
cd /opt/creative-collective
```

До слияния production-изменений можно использовать подготовленную ветку:

```bash
git switch codex/creative-collective-hardening
```

## 3. Переменные окружения

```bash
cp .env.production.example .env
chmod 600 .env
nano .env
```

Обязательно замените:

- `ACME_EMAIL`;
- все `DB_*` значения;
- `JWT_SECRET` и `JWT_REFRESH_SECRET`;
- домен, если используется не `creative.yozik.ru`.

Сгенерировать JWT-секреты можно командой:

```bash
openssl rand -base64 48
```

Каждый секрет генерируется отдельно. Файл `.env` нельзя добавлять в Git.

## 4. Проверка внешней MySQL

Сначала проверьте сетевой доступ с нового сервера:

```bash
nc -vz DB_HOST DB_PORT
```

Если установлен MySQL client:

```bash
mysql -h DB_HOST -P DB_PORT -u DB_USER -p DB_NAME -e "SELECT 1"
```

## 5. Запуск

```bash
docker compose config
docker compose build --pull
docker compose up -d api web
docker compose ps
docker compose logs --tail=100 api
```

Контейнеры доступны только локально на `127.0.0.1:3080` (API) и `127.0.0.1:3081` (Flutter Web). Добавьте virtual host в системный Nginx:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name creative.yozik.ru;

    location /api/ {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://127.0.0.1:3080;
    }

    location = /health {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://127.0.0.1:3080/health;
    }

    location / {
        proxy_set_header Host $host;
        proxy_pass http://127.0.0.1:3081;
    }
}
```

Проверьте конфигурацию и получите сертификат:

```bash
sudo nginx -t
sudo systemctl reload nginx
sudo certbot --nginx -d creative.yozik.ru
```

## 6. Проверка

```bash
curl --fail https://creative.yozik.ru/health
```

Запрос должен вернуть `success: true`, `status: healthy` и `database: connected`.

Проверьте миграции:

```bash
docker compose exec api npm run verify-schema
```

## 7. Обновление

```bash
cd /opt/creative-collective
git pull --ff-only
docker compose build --pull
docker compose up -d
```

Перед обновлением с новыми миграциями сделайте резервную копию внешней MySQL.

## Диагностика

```bash
docker compose ps
docker compose logs --tail=200 api
docker compose logs --tail=200 web
```

Если `api` остаётся unhealthy, сначала проверьте доступ к внешней MySQL и значения `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_NAME`. Если Certbot не получает сертификат, проверьте DNS и доступность портов `80/443`.
