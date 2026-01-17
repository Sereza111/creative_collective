# СРОЧНОЕ ИСПРАВЛЕНИЕ БД!

## ❌ ПРОБЛЕМА: Таблица `favorites` НЕ СОЗДАНА!

### ✅ ВЫПОЛНИ В phpMyAdmin:

```sql
USE creative_collective;

-- Создаём таблицу favorites
CREATE TABLE IF NOT EXISTS favorites (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  item_type ENUM('order', 'freelancer') NOT NULL,
  item_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_favorite (user_id, item_type, item_id),
  INDEX idx_user_id (user_id),
  INDEX idx_item_type (item_type),
  INDEX idx_item_id (item_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### ✅ ПРОВЕРКА:

```sql
DESCRIBE favorites;
```

Должны быть столбцы: `id`, `user_id`, `item_type`, `item_id`, `created_at`

---

## ✅ ПОСЛЕ СОЗДАНИЯ ТАБЛИЦЫ - ПЕРЕЗАПУСТИ ПРИЛОЖЕНИЕ!

