# nginx для бота + arc303.ru (без отключения nginx)

На VPS **nginx на 80/443 нужен боту** — его **не останавливаем**.

`creative_collective` слушает **только localhost**:

| Сервис | Порт на VPS |
|--------|-------------|
| Caddy (сайт) | `127.0.0.1:8081` |
| API | `127.0.0.1:8080` → контейнер 3000 |

Let's Encrypt для `arc303.ru` / `api.arc303.ru` — через **certbot + nginx**, не через Caddy на 80.

## 1. Portainer — deploy stack

В compose у `web` должно быть **`127.0.0.1:8081:80`**, не `80:80`.

Update stack → контейнеры `creative_collective_api` и `creative_collective_web` running.

## 2. nginx — отдельный vhost (бот не трогаем)

На сервере (из клона репо или скопируй файл):

```bash
sudo cp deploy/nginx-host-arc303.conf /etc/nginx/sites-available/arc303.conf
sudo ln -sf /etc/nginx/sites-available/arc303.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

Конфиг бота в `sites-enabled` **оставь как есть** — у него другой `server_name`.

Проверка:

```bash
curl -s -o /dev/null -w "%{http_code}\n" -H "Host: arc303.ru" http://127.0.0.1/
curl -s http://127.0.0.1:8080/health
```

## 3. SSL

```bash
sudo certbot --nginx -d arc303.ru -d api.arc303.ru
```

Потом в браузере: `https://arc303.ru/health`, `https://api.arc303.ru/health`.

## 4. Flutter

```powershell
flutter build windows --dart-define=API_BASE_URL=https://api.arc303.ru/api/v1
```

или `https://arc303.ru/api/v1` если API только на основном домене.

## Ошибки

| Симптом | Причина |
|---------|---------|
| `address already in use` на 80 в Docker | В compose снова `80:80` — верни `127.0.0.1:8081:80` |
| ACME 404 | Нет vhost `arc303.ru` в nginx или certbot не прошёл |
| Бот упал | Трогали default_server бота — откати, добавь только `arc303.conf` |
