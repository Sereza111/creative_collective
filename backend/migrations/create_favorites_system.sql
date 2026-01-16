USE creative_collective;

-- Таблица избранного
CREATE TABLE IF NOT EXISTS favorites (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  item_type ENUM('order', 'freelancer') NOT NULL,
  item_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY unique_favorite (user_id, item_type, item_id),
  INDEX idx_user_id (user_id),
  INDEX idx_item_type (item_type),
  INDEX idx_item_id (item_id)
);
