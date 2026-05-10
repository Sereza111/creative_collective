# HTTPS для `arc303.ru` и `api.arc303.ru` (nginx + certbot)

В репозитории уже настроено:

- nginx (`site`) слушает `80` и `443`
- `arc303.ru` отдаёт landing
- `api.arc303.ru` проксирует backend (`api:3000`)
- сертификаты Let's Encrypt хранятся в volume `letsencrypt`
- `certbot` в фоне делает `renew` каждые 12 часов

## 0) DNS

Нужны A‑записи:

- `arc303.ru` → IP сервера
- `api.arc303.ru` → IP сервера

## 1) Первый выпуск сертификата (один раз)

Это нужно сделать через Portainer (Exec в контейнере `creative_collective_certbot`) или по SSH на сервере.

1) Убедись, что стек поднят и порт 80 открыт.
2) Выпусти сертификат:

```bash
certbot certonly --webroot -w /var/www/certbot \
  -d arc303.ru -d www.arc303.ru -d api.arc303.ru \
  --email YOU@EMAIL.COM --agree-tos --no-eff-email
```

3) Перезапусти nginx контейнер `creative_collective_site` (redeploy / restart).

## 2) Проверка

- `https://arc303.ru/`
- `https://arc303.ru/health`
- `https://api.arc303.ru/health`
- `https://api.arc303.ru/api/v1/auth/me` (нужен токен)

## 3) Важно

- После включения HTTPS можно убрать публичный порт `8080` (не обязателен, если используешь только `api.arc303.ru`).
- HSTS в `site/nginx.conf` закомментирован — включай после того, как убедишься, что HTTPS стабильно работает.
- Основной nginx-конфиг лежит в `site/conf.d/default.conf` и копируется в image `site` на этапе build (без bind-mount конфигов, чтобы не было проблем с путями в Portainer).

