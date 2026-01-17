USE creative_collective;

-- Удаляем старые триггеры если есть
DROP TRIGGER IF EXISTS after_transaction_insert;
DROP TRIGGER IF EXISTS after_transaction_update;

-- Триггер для автоматического обновления баланса при создании транзакции
DELIMITER $$

CREATE TRIGGER after_transaction_insert
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
CREATE TRIGGER after_transaction_update
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

