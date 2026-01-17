USE creative_collective;

-- Создание таблицы транзакций
CREATE TABLE IF NOT EXISTS transactions (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL COMMENT 'Пользователь, которому принадлежит транзакция',
  order_id INT DEFAULT NULL COMMENT 'Связанный заказ',
  type ENUM('income', 'expense', 'commission', 'withdrawal', 'refund') NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  description TEXT,
  status ENUM('pending', 'completed', 'cancelled', 'refunded') DEFAULT 'pending',
  payment_method VARCHAR(100) DEFAULT NULL COMMENT 'Способ оплаты',
  related_user_id INT DEFAULT NULL COMMENT 'Связанный пользователь (от кого/кому)',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  completed_at TIMESTAMP NULL DEFAULT NULL,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE SET NULL,
  FOREIGN KEY (related_user_id) REFERENCES users(id) ON DELETE SET NULL,
  
  INDEX idx_user_id (user_id),
  INDEX idx_order_id (order_id),
  INDEX idx_type (type),
  INDEX idx_status (status),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Создание таблицы балансов пользователей
CREATE TABLE IF NOT EXISTS user_balances (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL UNIQUE,
  balance DECIMAL(10, 2) DEFAULT 0.00,
  total_earned DECIMAL(10, 2) DEFAULT 0.00 COMMENT 'Всего заработано',
  total_spent DECIMAL(10, 2) DEFAULT 0.00 COMMENT 'Всего потрачено',
  total_withdrawn DECIMAL(10, 2) DEFAULT 0.00 COMMENT 'Всего выведено',
  pending_amount DECIMAL(10, 2) DEFAULT 0.00 COMMENT 'Замороженные средства',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Создание таблицы для запросов на вывод средств
CREATE TABLE IF NOT EXISTS withdrawal_requests (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  payment_method VARCHAR(100) NOT NULL,
  payment_details TEXT COMMENT 'Реквизиты для вывода (JSON)',
  status ENUM('pending', 'processing', 'completed', 'rejected') DEFAULT 'pending',
  admin_comment TEXT DEFAULT NULL,
  processed_by_admin_id INT DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  processed_at TIMESTAMP NULL DEFAULT NULL,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (processed_by_admin_id) REFERENCES users(id) ON DELETE SET NULL,
  
  INDEX idx_user_id (user_id),
  INDEX idx_status (status),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Триггер для автоматического обновления баланса при создании транзакции
DELIMITER $$

CREATE TRIGGER IF NOT EXISTS after_transaction_insert
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
  -- Проверяем, есть ли запись баланса для пользователя
  INSERT INTO user_balances (user_id, balance, total_earned, total_spent)
  VALUES (NEW.user_id, 0, 0, 0)
  ON DUPLICATE KEY UPDATE user_id = user_id;
  
  -- Обновляем баланс только для завершенных транзакций
  IF NEW.status = 'completed' THEN
    IF NEW.type = 'income' THEN
      UPDATE user_balances 
      SET 
        balance = balance + NEW.amount,
        total_earned = total_earned + NEW.amount
      WHERE user_id = NEW.user_id;
    ELSEIF NEW.type = 'expense' OR NEW.type = 'withdrawal' OR NEW.type = 'commission' THEN
      UPDATE user_balances 
      SET 
        balance = balance - NEW.amount,
        total_spent = total_spent + NEW.amount
      WHERE user_id = NEW.user_id;
    ELSEIF NEW.type = 'refund' THEN
      UPDATE user_balances 
      SET 
        balance = balance + NEW.amount
      WHERE user_id = NEW.user_id;
    END IF;
  END IF;
END$$

-- Триггер для обновления баланса при изменении статуса транзакции
CREATE TRIGGER IF NOT EXISTS after_transaction_update
AFTER UPDATE ON transactions
FOR EACH ROW
BEGIN
  -- Если статус изменился на completed
  IF OLD.status != 'completed' AND NEW.status = 'completed' THEN
    IF NEW.type = 'income' THEN
      UPDATE user_balances 
      SET 
        balance = balance + NEW.amount,
        total_earned = total_earned + NEW.amount
      WHERE user_id = NEW.user_id;
    ELSEIF NEW.type = 'expense' OR NEW.type = 'withdrawal' OR NEW.type = 'commission' THEN
      UPDATE user_balances 
      SET 
        balance = balance - NEW.amount,
        total_spent = total_spent + NEW.amount
      WHERE user_id = NEW.user_id;
    ELSEIF NEW.type = 'refund' THEN
      UPDATE user_balances 
      SET 
        balance = balance + NEW.amount
      WHERE user_id = NEW.user_id;
    END IF;
  END IF;
  
  -- Если статус изменился с completed на cancelled/refunded
  IF OLD.status = 'completed' AND NEW.status IN ('cancelled', 'refunded') THEN
    IF OLD.type = 'income' THEN
      UPDATE user_balances 
      SET 
        balance = balance - OLD.amount,
        total_earned = total_earned - OLD.amount
      WHERE user_id = OLD.user_id;
    ELSEIF OLD.type = 'expense' OR OLD.type = 'withdrawal' OR OLD.type = 'commission' THEN
      UPDATE user_balances 
      SET 
        balance = balance + OLD.amount,
        total_spent = total_spent - OLD.amount
      WHERE user_id = OLD.user_id;
    ELSEIF OLD.type = 'refund' THEN
      UPDATE user_balances 
      SET 
        balance = balance - OLD.amount
      WHERE user_id = OLD.user_id;
    END IF;
  END IF;
END$$

DELIMITER ;

