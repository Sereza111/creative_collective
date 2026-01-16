-- Система избранного для заказов и фрилансеров
USE creative_collective;

CREATE TABLE IF NOT EXISTS favorites (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL COMMENT 'Кто добавил в избранное',
  favorited_type ENUM('order', 'freelancer') NOT NULL COMMENT 'Тип объекта',
  favorited_id INT NOT NULL COMMENT 'ID заказа или фрилансера',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  
  UNIQUE KEY unique_favorite (user_id, favorited_type, favorited_id),
  INDEX idx_user_type (user_id, favorited_type),
  INDEX idx_favorited (favorited_type, favorited_id)
);

