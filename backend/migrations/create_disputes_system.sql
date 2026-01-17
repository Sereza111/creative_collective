USE creative_collective;

-- Создание таблицы споров
CREATE TABLE IF NOT EXISTS disputes (
  id INT PRIMARY KEY AUTO_INCREMENT,
  order_id INT NOT NULL,
  opened_by_user_id INT NOT NULL COMMENT 'Пользователь, открывший спор',
  against_user_id INT NOT NULL COMMENT 'Пользователь, против которого спор',
  reason ENUM('payment', 'quality', 'deadline', 'communication', 'other') NOT NULL,
  description TEXT NOT NULL,
  status ENUM('open', 'in_review', 'resolved', 'closed') DEFAULT 'open',
  resolution TEXT DEFAULT NULL COMMENT 'Решение админа',
  resolved_by_admin_id INT DEFAULT NULL,
  resolved_at TIMESTAMP NULL DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY (opened_by_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (against_user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (resolved_by_admin_id) REFERENCES users(id) ON DELETE SET NULL,
  
  INDEX idx_order_id (order_id),
  INDEX idx_opened_by (opened_by_user_id),
  INDEX idx_against (against_user_id),
  INDEX idx_status (status),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Создание таблицы сообщений в споре
CREATE TABLE IF NOT EXISTS dispute_messages (
  id INT PRIMARY KEY AUTO_INCREMENT,
  dispute_id INT NOT NULL,
  user_id INT NOT NULL,
  message TEXT NOT NULL,
  attachments JSON DEFAULT NULL COMMENT 'Массив URL вложений',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (dispute_id) REFERENCES disputes(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  
  INDEX idx_dispute_id (dispute_id),
  INDEX idx_user_id (user_id),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Создание таблицы истории изменений спора
CREATE TABLE IF NOT EXISTS dispute_history (
  id INT PRIMARY KEY AUTO_INCREMENT,
  dispute_id INT NOT NULL,
  action ENUM('opened', 'status_changed', 'message_added', 'resolved', 'closed') NOT NULL,
  old_value VARCHAR(255) DEFAULT NULL,
  new_value VARCHAR(255) DEFAULT NULL,
  performed_by_user_id INT NOT NULL,
  details TEXT DEFAULT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (dispute_id) REFERENCES disputes(id) ON DELETE CASCADE,
  FOREIGN KEY (performed_by_user_id) REFERENCES users(id) ON DELETE CASCADE,
  
  INDEX idx_dispute_id (dispute_id),
  INDEX idx_action (action),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

