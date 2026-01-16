USE creative_collective;

-- Добавляем поля для верификации
ALTER TABLE users ADD COLUMN is_verified BOOLEAN DEFAULT FALSE COMMENT 'Верифицирован ли пользователь';
ALTER TABLE users ADD COLUMN verified_at TIMESTAMP NULL COMMENT 'Дата верификации';
ALTER TABLE users ADD COLUMN verification_note TEXT COMMENT 'Примечание о верификации';

