USE creative_collective;

-- Проверяем и добавляем недостающие столбцы в таблицу transactions
ALTER TABLE transactions
ADD COLUMN IF NOT EXISTS status ENUM('pending', 'completed', 'cancelled', 'refunded') DEFAULT 'pending' AFTER description;

-- Если столбец related_user_id отсутствует
ALTER TABLE transactions
ADD COLUMN IF NOT EXISTS related_user_id INT DEFAULT NULL COMMENT 'Связанный пользователь (от кого/кому)' AFTER payment_method;

-- Если столбец completed_at отсутствует
ALTER TABLE transactions
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP NULL DEFAULT NULL AFTER updated_at;

-- Добавляем внешний ключ для related_user_id если его нет
-- Сначала проверим, есть ли уже этот ключ
SET @exist := (SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS 
WHERE CONSTRAINT_SCHEMA = 'creative_collective' 
AND TABLE_NAME = 'transactions' 
AND CONSTRAINT_NAME = 'transactions_ibfk_3');

SET @sqlstmt := IF(@exist = 0, 
'ALTER TABLE transactions ADD FOREIGN KEY (related_user_id) REFERENCES users(id) ON DELETE SET NULL',
'SELECT "Foreign key already exists"');

PREPARE stmt FROM @sqlstmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

