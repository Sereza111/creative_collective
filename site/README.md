# Лендинг (не полное Flutter Web-приложение)

В проде контейнер `creative_collective_web` (Caddy) отдаёт **статическую страницу** `index.html`.

**Полный функционал** — в **Flutter desktop** (`flutter run -d windows`), не в браузере.

## Как открыть сайт

- **Прод:** `https://arc303.ru` (через nginx на VPS)
- **Проверка на VPS:** `http://127.0.0.1:8081/` (после `8081:80` в Portainer)
- **Не работает:** `http://IP:8081` снаружи, если порт 8081 не открыт в firewall — используй домен

## API

- `https://arc303.ru/api/v1/...` или `https://api.arc303.ru/api/v1/...`

