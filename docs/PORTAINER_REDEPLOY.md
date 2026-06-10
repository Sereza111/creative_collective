# Portainer: обновить creative_collective

1. **Stacks** → `creative_collective` → **Editor** → **Pull from repository**.
2. **Update the stack** — включи **Re-pull** и **Rebuild** (сборка `web` включает Flutter Web, ~3–5 мин).
3. Env переменные API (`DB_*`, `JWT_*`) не трогай.

## Что поднимается

| URL | Что |
|-----|-----|
| `https://arc303.ru/` | Лендинг |
| `https://arc303.ru/app/` | **Веб-приложение** (задачи, проекты, команды, маркет, чаты) |
| `https://arc303.ru/api/v1` | API |
| `https://api.arc303.ru/health` | Health API (прямой порт 8080) |

Проверка на VPS:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8081/
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8081/app/
curl -s -o /dev/null -w "%{http_code}\n" https://arc303.ru/app/
```

Ожидается **200** на все три.
