# Почему не работает HTTPS и как починить (arc303.ru)

Ошибки в браузере/Flutter:

- `NET::ERR_CERT_COMMON_NAME_INVALID` — сертификат **не на то имя** (например, выдан только для `api.arc303.ru`, а открываешь `arc303.ru`).
- `Hostname mismatch` — то же самое в клиенте.

## Как должно быть

1. DNS **A-запись**:
   - `arc303.ru` → IP VPS (например `93.189.230.198`)
   - `api.arc303.ru` → **тот же IP**
   - `www.arc303.ru` → тот же IP (по желанию)

2. На VPS порты **80 и 443** слушает только контейнер **`creative_collective_web` (Caddy)**.  
   Если на хосте ещё nginx/apache — выключи, иначе отдаётся чужой сертификат.

3. Caddy в `site/Caddyfile` запрашивает **один** сертификат на три имени:  
   `arc303.ru`, `www.arc303.ru`, `api.arc303.ru`.

## Обязательный сброс старых сертификатов (Portainer)

Старый неверный cert лежит в volume **`caddy_data`**.

1. Останови стек `creative_collective`.
2. **Volumes** → удали **`caddy_data`** (и при необходимости `caddy_config`).
3. **Pull and redeploy** стека (пересобери `creative_collective_web`).
4. Подожди 1–2 минуты, смотри логи `creative_collective_web` — должны быть строки про `certificate obtained` / `succeeded`.

## Проверка

В браузере (без предупреждений):

- `https://arc303.ru/`
- `https://arc303.ru/health`
- `https://api.arc303.ru/health`

Flutter:

```powershell
flutter build windows --dart-define=API_BASE_URL=https://arc303.ru/api/v1
```

или

```powershell
flutter build windows --dart-define=API_BASE_URL=https://api.arc303.ru/api/v1
```

## Если снова не выдаётся cert

- Проверь `nslookup arc303.ru` — IP = твой VPS.
- Открой с VPS: `curl -I http://arc303.ru` (должен ответить Caddy, не Beget-заглушка).
- У хостера открой входящие TCP **80** и **443**.
- Временно для защиты: `http://IP:3000/api/v1` без HTTPS.
