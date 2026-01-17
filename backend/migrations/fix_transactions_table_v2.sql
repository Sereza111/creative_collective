USE creative_collective;

-- Добавляем столбец status (если возникнет ошибка что столбец существует - это нормально, просто игнорируй)
ALTER TABLE transactions
ADD COLUMN status ENUM('pending', 'completed', 'cancelled', 'refunded') DEFAULT 'pending' AFTER description;

-- Добавляем столбец related_user_id
ALTER TABLE transactions
ADD COLUMN related_user_id INT DEFAULT NULL COMMENT 'Связанный пользователь (от кого/кому)' AFTER payment_method;

-- Добавляем столбец completed_at
ALTER TABLE transactions
ADD COLUMN completed_at TIMESTAMP NULL DEFAULT NULL AFTER updated_at;

-- Добавляем внешний ключ для related_user_id
ALTER TABLE transactions
ADD FOREIGN KEY (related_user_id) REFERENCES users(id) ON DELETE SET NULL;

