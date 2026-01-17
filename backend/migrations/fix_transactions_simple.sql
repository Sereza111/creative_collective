USE creative_collective;

-- Добавляем столбцы БЕЗ указания позиции (если столбец существует - будет ошибка, это нормально)

-- Добавляем status
ALTER TABLE transactions
ADD COLUMN status ENUM('pending', 'completed', 'cancelled', 'refunded') DEFAULT 'pending';

-- Добавляем related_user_id
ALTER TABLE transactions
ADD COLUMN related_user_id INT DEFAULT NULL COMMENT 'Связанный пользователь (от кого/кому)';

-- Добавляем completed_at
ALTER TABLE transactions
ADD COLUMN completed_at TIMESTAMP NULL DEFAULT NULL;

-- Добавляем внешний ключ для related_user_id
ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_related_user
FOREIGN KEY (related_user_id) REFERENCES users(id) ON DELETE SET NULL;

