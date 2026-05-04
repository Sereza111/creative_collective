USE creative_collective;

SET @db := DATABASE();

CREATE TABLE IF NOT EXISTS legal_documents (
  id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
  document_type VARCHAR(50) NOT NULL,
  version VARCHAR(20) NOT NULL,
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_legal_doc (document_type, version)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_agreements (
  id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
  user_id VARCHAR(36) NOT NULL,
  document_id VARCHAR(36) NOT NULL,
  document_type VARCHAR(50) NOT NULL,
  document_version VARCHAR(20) NOT NULL,
  agreed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ip_address VARCHAR(45) NULL,
  user_agent TEXT NULL,
  order_id VARCHAR(36) NULL,
  INDEX idx_user_id (user_id),
  INDEX idx_document_type (document_type),
  INDEX idx_order_id (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS application_views (
  id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
  application_id VARCHAR(36) NOT NULL,
  order_id VARCHAR(36) NOT NULL,
  client_id VARCHAR(36) NOT NULL,
  viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_application_id (application_id),
  INDEX idx_order_id (order_id),
  INDEX idx_client_id (client_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS application_refunds (
  id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
  application_id VARCHAR(36) NOT NULL,
  freelancer_id VARCHAR(36) NOT NULL,
  order_id VARCHAR(36) NOT NULL,
  refund_amount DECIMAL(10, 2) NOT NULL,
  reason VARCHAR(50) NOT NULL,
  refunded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  transaction_id VARCHAR(36) NULL,
  INDEX idx_freelancer_id (freelancer_id),
  INDEX idx_order_id (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_balances (
  id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
  user_id VARCHAR(36) NOT NULL,
  balance DECIMAL(18,2) DEFAULT 0,
  total_earned DECIMAL(18,2) DEFAULT 0,
  total_spent DECIMAL(18,2) DEFAULT 0,
  total_withdrawn DECIMAL(18,2) DEFAULT 0,
  pending_amount DECIMAL(18,2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY unique_user_balance (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS withdrawal_requests (
  id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
  user_id VARCHAR(36) NOT NULL,
  amount DECIMAL(18,2) NOT NULL,
  payment_method VARCHAR(50) NOT NULL,
  payment_details JSON NOT NULL,
  status VARCHAR(32) DEFAULT 'pending',
  admin_comment TEXT NULL,
  processed_by_admin_id VARCHAR(36) NULL,
  processed_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_withdrawals_user (user_id),
  INDEX idx_withdrawals_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notification_settings (
  id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
  user_id VARCHAR(36) NOT NULL,
  email_enabled BOOLEAN DEFAULT TRUE,
  push_enabled BOOLEAN DEFAULT TRUE,
  order_notifications BOOLEAN DEFAULT TRUE,
  application_notifications BOOLEAN DEFAULT TRUE,
  message_notifications BOOLEAN DEFAULT TRUE,
  review_notifications BOOLEAN DEFAULT TRUE,
  dispute_notifications BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY unique_user_settings (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- notifications compatibility
SET @exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='notifications' AND COLUMN_NAME='related_id'
);
SET @sql := IF(@exists=0, 'ALTER TABLE notifications ADD COLUMN related_id VARCHAR(36) NULL', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='notifications' AND COLUMN_NAME='related_type'
);
SET @sql := IF(@exists=0, 'ALTER TABLE notifications ADD COLUMN related_type VARCHAR(50) NULL', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='notifications' AND COLUMN_NAME='title'
);
SET @sql := IF(@exists=0, 'ALTER TABLE notifications ADD COLUMN title VARCHAR(200) NULL', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @notifType := (
  SELECT DATA_TYPE FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='notifications' AND COLUMN_NAME='type'
  LIMIT 1
);
SET @sql := IF(@notifType IS NOT NULL AND @notifType <> 'varchar',
  'ALTER TABLE notifications MODIFY COLUMN type VARCHAR(50) NOT NULL',
  'SELECT 1'
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- transactions compatibility
SET @exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='transactions' AND COLUMN_NAME='order_id'
);
SET @sql := IF(@exists=0, 'ALTER TABLE transactions ADD COLUMN order_id VARCHAR(36) NULL', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='transactions' AND COLUMN_NAME='related_user_id'
);
SET @sql := IF(@exists=0, 'ALTER TABLE transactions ADD COLUMN related_user_id VARCHAR(36) NULL', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='transactions' AND COLUMN_NAME='status'
);
SET @sql := IF(@exists=0, "ALTER TABLE transactions ADD COLUMN status VARCHAR(32) DEFAULT 'pending'", 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='transactions' AND COLUMN_NAME='completed_at'
);
SET @sql := IF(@exists=0, 'ALTER TABLE transactions ADD COLUMN completed_at TIMESTAMP NULL', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @txType := (
  SELECT DATA_TYPE FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='transactions' AND COLUMN_NAME='type'
  LIMIT 1
);
SET @sql := IF(@txType IS NOT NULL AND @txType <> 'varchar',
  'ALTER TABLE transactions MODIFY COLUMN type VARCHAR(32) NOT NULL',
  'SELECT 1'
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='projects' AND COLUMN_NAME='order_id'
);
SET @sql := IF(@exists=0, 'ALTER TABLE projects ADD COLUMN order_id VARCHAR(36) NULL', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

SET @exists := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='tasks' AND COLUMN_NAME='order_id'
);
SET @sql := IF(@exists=0, 'ALTER TABLE tasks ADD COLUMN order_id VARCHAR(36) NULL', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
