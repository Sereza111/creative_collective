# Почему Caddy не выдаёт сертификат (по твоим логам)

## Что видно в логах

1. **HTTP challenge → 404** на `93.189.230.198`:
   - `http://arc303.ru/.well-known/acme-challenge/...` → **404**
   - `http://api.arc303.ru/.well-known/acme-challenge/...` → **404**  
   Let's Encrypt доходит до сервера, но **не Caddy отвечает токеном** (часто порт 80 занят не Caddy, или запрос уходит в API).

2. **`www.arc303.ru` → другой IP `5.101.152.161`** (Connection refused / 500).  
   Пока DNS `www` не на VPS `93.189.230.198`, сертификат на `www` **не выдастся**. В новом `Caddyfile` **www убран** из запроса.

3. **TLS challenge** `tls: no application protocol` на 443 — побочный эффект, пока нет валидного cert.

## Что сделать на VPS

### 1. Только Caddy на 80/443

На сервере (SSH):

```bash
sudo systemctl stop nginx
sudo systemctl disable nginx
sudo ss -tlnp | grep -E ':80|:443'
```

Должен быть **docker-proxy** → контейнер `creative_collective_web`, не `nginx`.

### 2. DNS (панель домена)

| Запись | A → |
|--------|-----|
| `arc303.ru` | `93.189.230.198` |
| `api.arc303.ru` | `93.189.230.198` |
| `www` | либо тот же IP, либо **удали** запись, пока не нужен |

### 3. Portainer

1. Stop stack  
2. Удали volume **`caddy_data`**  
3. Pull and redeploy (пересобери `creative_collective_web`)  
4. Подожди 2–3 мин, смотри логи — ищи **`certificate obtained successfully`**

### 4. Проверка

- `http://arc303.ru/.well-known/` — не обязательно открывать вручную  
- `https://arc303.ru/health` — без предупреждения в браузере  
- `https://api.arc303.ru/health` — то же  

## Flutter после успешного HTTPS

```powershell
flutter build windows --dart-define=API_BASE_URL=https://arc303.ru/api/v1
```

## Если снова 404 на acme-challenge

Значит **порт 80 не Caddy**. Проверь, не проброшен ли 80 на другой контейнер и не крутится ли nginx на хосте.

## Для диплома без HTTPS (работает уже сейчас)

API у тебя живой — используй:

```powershell
flutter build windows --dart-define=API_BASE_URL=http://93.189.230.198:3000/api/v1
```
