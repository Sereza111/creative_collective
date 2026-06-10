# Portainer: обновить creative_collective

1. **Stacks** → `creative_collective` → **Editor** → **Pull from repository** (или вставь `docker-compose.yml` из GitHub).
2. **Update the stack** — включи **Re-pull** и **Rebuild**.
3. Старые volumes `caddy_*` больше не нужны — в Portainer **Volumes** можно удалить `creative_collective_caddy_config` и `creative_collective_caddy_data` (если контейнер `web` остановлен).

Проверка на VPS:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8081/
curl -s -o /dev/null -w "%{http_code}\n" https://arc303.ru/
```

Ожидается **200**. API: `https://api.arc303.ru/health`.
