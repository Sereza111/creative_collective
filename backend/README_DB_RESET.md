## DB reset / bootstrap (dev)

Этот проект использует MySQL и UUID-ключи.

### Пересоздать БД с нуля (удалит данные)

Из папки `backend/`:

```bash
npm install
npm run db:reset
```

Скрипт:
- создаст/пересоздаст базу `DB_NAME` (по умолчанию `creative_collective`)
- применит baseline [`src/database/schema.sql`](src/database/schema.sql)
- применит UUID-миграции из [`migrations_uuid/`](migrations_uuid/)

### Просто применить миграции (без DROP DATABASE)

```bash
npm run migrate
```

### Hotfix для уже заполненной БД (phpMyAdmin / старый MySQL)

Если импорт падает на `ADD COLUMN IF NOT EXISTS`, используй файл:

- [`migrations_uuid/000_hotfix_existing_db.sql`](migrations_uuid/000_hotfix_existing_db.sql)

Он **не использует** `IF NOT EXISTS` для колонок и совместим со старыми версиями MySQL.

### Smoke-тест API (когда сервер поднят)

```powershell
.\scripts\smoke.ps1
```

Можно переопределить базовый URL:

```powershell
$env:SMOKE_API_BASE="http://localhost:3000"; .\scripts\smoke.ps1
```

