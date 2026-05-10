# Секреты и ротация (production)

## Обязательные переменные

| Переменная | Назначение |
|------------|------------|
| `DB_PASSWORD` | Пароль пользователя MySQL |
| `JWT_SECRET` | Подпись access token |
| `JWT_REFRESH_SECRET` | Подпись refresh token |

Все три **должны быть непустыми** в Portainer / `.env`.

## Когда ротировать

- Пароль или JWT когда-либо попали в git, скриншот, чат, публичный issue.
- После увольнения человека с доступом к Portainer/БД.
- Планово раз в год для JWT (опционально).

## Порядок ротации MySQL

1. В панели хостинга сменить пароль пользователя БД.
2. Обновить `DB_PASSWORD` в Portainer → redeploy stack.
3. Убедиться, что `/health` снова `database: connected`.

## Порядок ротации JWT

1. Сгенерировать два новых значения (разные друг от друга):

   ```powershell
   [Convert]::ToBase64String((1..48 | ForEach-Object { Get-Random -Maximum 256 }))
   ```

2. Обновить `JWT_SECRET` и `JWT_REFRESH_SECRET` в Portainer → redeploy.
3. **Все выданные ранее refresh-токены перестанут валидироваться** после смены `JWT_REFRESH_SECRET` (ожидаемо). Пользователи залогинятся заново.

## Compose

Корневой [`docker-compose.yml`](../docker-compose.yml) не содержит реальных паролей — только `${DB_PASSWORD}` и `${JWT_SECRET}`.
