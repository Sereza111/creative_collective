USE creative_collective;

-- Таблица для хранения юридических документов
CREATE TABLE IF NOT EXISTS legal_documents (
  id INT AUTO_INCREMENT PRIMARY KEY,
  document_type ENUM('user_agreement', 'privacy_policy', 'freelancer_terms', 'client_terms', 'order_contract') NOT NULL,
  version VARCHAR(20) NOT NULL, -- Например: '1.0', '1.1'
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_document_type (document_type),
  INDEX idx_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Таблица для хранения подписей пользователей
CREATE TABLE IF NOT EXISTS user_agreements (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  document_id INT NOT NULL,
  document_type ENUM('user_agreement', 'privacy_policy', 'freelancer_terms', 'client_terms', 'order_contract') NOT NULL,
  document_version VARCHAR(20) NOT NULL,
  agreed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ip_address VARCHAR(45) NULL,
  user_agent TEXT NULL,
  order_id INT NULL, -- Для order_contract
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (document_id) REFERENCES legal_documents(id) ON DELETE CASCADE,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_document_type (document_type),
  INDEX idx_order_id (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Таблица для отслеживания просмотров откликов заказчиком
CREATE TABLE IF NOT EXISTS application_views (
  id INT AUTO_INCREMENT PRIMARY KEY,
  application_id INT NOT NULL,
  order_id INT NOT NULL,
  client_id INT NOT NULL,
  viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (application_id) REFERENCES order_applications(id) ON DELETE CASCADE,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY (client_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_application_id (application_id),
  INDEX idx_order_id (order_id),
  INDEX idx_client_id (client_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Таблица для системы возврата средств за игнорирование
CREATE TABLE IF NOT EXISTS application_refunds (
  id INT AUTO_INCREMENT PRIMARY KEY,
  application_id INT NOT NULL,
  freelancer_id INT NOT NULL,
  order_id INT NOT NULL,
  refund_amount DECIMAL(10, 2) NOT NULL,
  reason ENUM('ignored_by_client', 'order_cancelled', 'order_deleted', 'auto_refund') NOT NULL,
  refunded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  transaction_id INT NULL, -- Ссылка на транзакцию возврата
  FOREIGN KEY (application_id) REFERENCES order_applications(id) ON DELETE CASCADE,
  FOREIGN KEY (freelancer_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  INDEX idx_freelancer_id (freelancer_id),
  INDEX idx_order_id (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Добавляем поле в order_applications для отслеживания
ALTER TABLE order_applications
ADD COLUMN viewed_by_client BOOLEAN DEFAULT FALSE,
ADD COLUMN viewed_at TIMESTAMP NULL;

-- Добавляем поле в orders для отслеживания автоматического возврата
ALTER TABLE orders
ADD COLUMN auto_refund_processed BOOLEAN DEFAULT FALSE;

