# 🔧 ПОЛНАЯ ПЕРЕЗАГРУЗКА БД (РЕШЕНИЕ ПРОБЛЕМЫ)

## Проблема:
Триггеры в schema.sql вызывают ошибку синтаксиса MySQL, из-за чего таблицы не создаются.

## ✅ Решение:

### Шаг 1: Удалить старые данные
В Portainer → Console контейнера `creative_collective_db`:

```bash
mysql -u root -proot
```

Затем:
```sql
DROP DATABASE IF EXISTS creative_collective;
CREATE DATABASE creative_collective CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON creative_collective.* TO 'creative_user'@'%';
FLUSH PRIVILEGES;
EXIT;
```

### Шаг 2: Перезапустить API контейнер
В Portainer → Containers → `creative_collective_api` → **Restart**

### Шаг 3: Проверить логи
Должно быть:
```
✅ Database schema created successfully
✅ Database seeding completed
🚀 Server is running on port 3000
```

---

## 🎯 ИЛИ БЫСТРЫЙ СПОСОБ - пересоздать весь стек:

1. **Stacks** → `creative-collective` → **Stop**
2. **Volumes** → удали `creative-collective_mysql_data`
3. **Stacks** → `creative-collective` → **Start**

Всё пересоздастся с нуля!

---

## После успешного запуска проверь:

```bash
curl http://85.198.103.11:3000
```

Должен вернуть ответ (любой, главное не таймаут).

