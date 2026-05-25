-- Если transactions из schema.sql (только finance_id) — добавить user_id для маркетплейса
USE creative_collective;

SET @db := DATABASE();

SET @exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'transactions' AND COLUMN_NAME = 'user_id'
);
SET @sql := IF(@exists = 0,
  'ALTER TABLE transactions ADD COLUMN user_id VARCHAR(36) NULL AFTER id',
  'SELECT 1'
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
