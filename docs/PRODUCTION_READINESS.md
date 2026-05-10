# Production readiness (операторский чеклист)

Связанные файлы: [`docker-compose.yml`](../docker-compose.yml), [`backend/.env.example`](../backend/.env.example), [ротация секретов](SECRETS_AND_ROTATION.md), [релиз](RELEASE_PROCESS.md).

## 1. Секреты

- [ ] Сменить `DB_PASSWORD` на хостинге и в Portainer.
- [ ] Сгенерировать новые `JWT_SECRET` и `JWT_REFRESH_SECRET` (см. [SECRETS_AND_ROTATION.md](SECRETS_AND_ROTATION.md)).
- [ ] Убедиться, что в git нет реальных паролей (compose только `${...}`).

## 2. Схема БД

На машине с доступом к БД (или из CI):

```bash
cd backend
cp .env.example .env   # заполнить
npm install
npm run verify-schema
```

Если таблиц не хватает:

```bash
npm run migrate
```

На старом MySQL без `ADD COLUMN IF NOT EXISTS` при необходимости выполнить вручную фрагменты из `backend/migrations_uuid/000_hotfix_existing_db.sql` (через phpMyAdmin по частям).

## 3. Бэкапы MySQL

- [ ] Настроить ежедневный дамп (см. [`backend/scripts/backup-mysql.sh`](../backend/scripts/backup-mysql.sh)).
- [ ] Хранить минимум 7–14 дней (скрипт удаляет `.sql.gz` старше 14 дней при наличии `find`).
- [ ] Раз в квартал: восстановить дамп в **отдельную** БД и проверить `npm run verify-schema`.

Пример восстановления:

```bash
gunzip -c backup.sql.gz | mysql -h HOST -u USER -p NEW_DB_NAME
```

## 4. Логи и диск

- [ ] В корневом `docker-compose.yml` для сервиса `api` задано `logging: json-file` с `max-size` / `max-file` (ротация на уровне Docker).
- [ ] При деплое не через compose — задать те же лимиты в Portainer / daemon.

## 5. Прод-конфигурация

Рекомендуемые переменные (см. `.env.example`):

| Переменная | Примечание |
|------------|------------|
| `PORT` | Внутри контейнера обычно `3000`; снаружи маппинг `8080:3000`. |
| `CORS_ORIGIN` | Список origin через запятую; `*` только для отладки. |
| `RATE_LIMIT_WINDOW_MS` | Окно в мс (по умолчанию 15 мин). |
| `RATE_LIMIT_MAX_REQUESTS` | Лимит запросов на IP за окно. |
| Volume `creative_uploads` | Файлы в `/app/uploads` персистятся между перезапусками. |

Права MySQL-пользователя: только `SELECT/INSERT/UPDATE/DELETE` и DDL по политике хостинга; не использовать root для приложения.

## 6. E2E smoke

Отклик на заказ требует **минимум 50 ₽** на `user_balances`. Для прогона с машины, где есть доступ к MySQL:

```powershell
cd backend
$env:SMOKE_API_BASE = "http://YOUR_PUBLIC_IP:8080"
$env:SMOKE_CREDIT_BALANCE = "1"   # перед apply выполнит node scripts/credit-user-balance.js
.\scripts\smoke-e2e.ps1
```

Либо вручную пополнить баланс фрилансера в БД перед сценарием с откликом.

Базовый сценарий: [`backend/scripts/smoke.ps1`](../backend/scripts/smoke.ps1).

### Журнал прогонов (заполнять вручную)

| Дата | API base | Результат | Примечание |
|------|----------|-----------|------------|
| _YYYY-MM-DD_ | _http://..._ | PASS/FAIL | |

## 7. Если `/health` unhealthy

1. Логи контейнера API в Portainer.
2. Проверить `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, доступ с сервера к MySQL.
3. Redeploy stack после исправления env.

## Критерий «готово»

- `/health` стабильно 200, БД connected.
- `npm run verify-schema` — OK.
- `smoke-e2e.ps1` — PASS на целевом API.
- Бэкапы и понятный откат (см. [RELEASE_PROCESS.md](RELEASE_PROCESS.md)).
