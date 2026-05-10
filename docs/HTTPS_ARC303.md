# HTTPS для `arc303.ru` и `api.arc303.ru` (пошагово)

Сейчас стек работает в **HTTP-first** режиме (чтобы nginx гарантированно стартовал):

- nginx (`site`) слушает `80`
- `arc303.ru` отдаёт landing
- `api.arc303.ru` проксирует backend (`api:3000`)
- ACME директория доступна как `/var/www/certbot`

## 0) DNS

Нужны A‑записи:

- `arc303.ru` → IP сервера
- `api.arc303.ru` → IP сервера

## 1) Первый выпуск сертификата (один раз, отдельно)

Это делается отдельной командой на сервере/в Portainer, потом включается HTTPS-конфиг.

1) Убедись, что стек поднят и порт 80 открыт.
2) Выпусти сертификат (пример):

```bash
certbot certonly --webroot -w /path/to/certbot_www \
  -d arc303.ru -d www.arc303.ru -d api.arc303.ru \
  --email YOU@EMAIL.COM --agree-tos --no-eff-email
```

3) После получения сертификатов включить HTTPS-конфиг и открыть 443.

## 2) Проверка

- `http://arc303.ru/`
- `http://arc303.ru/health`
- `http://api.arc303.ru/health`
- `http://api.arc303.ru/api/v1/auth/me` (нужен токен)

## 3) Важно

- После стабилизации можно отдельно включить HTTPS и убрать публичный `8080`.
- Основной nginx-конфиг: `site/conf.d/default.conf`.

