USE creative_collective;

-- Таблица отзывов
CREATE TABLE IF NOT EXISTS reviews (
  id INT PRIMARY KEY AUTO_INCREMENT,
  order_id INT NOT NULL,
  reviewer_id INT NOT NULL COMMENT 'Кто оставил отзыв',
  reviewee_id INT NOT NULL COMMENT 'Кому оставлен отзыв',
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY (reviewer_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (reviewee_id) REFERENCES users(id) ON DELETE CASCADE,
  
  -- Один пользователь может оставить только один отзыв на один заказ
  UNIQUE KEY unique_review (order_id, reviewer_id),
  
  INDEX idx_reviewee (reviewee_id),
  INDEX idx_reviewer (reviewer_id),
  INDEX idx_rating (rating)
);

-- Добавляем поля для кэширования рейтинга в таблицу users
ALTER TABLE users 
  ADD COLUMN IF NOT EXISTS average_rating DECIMAL(3,2) DEFAULT NULL COMMENT 'Средний рейтинг пользователя',
  ADD COLUMN IF NOT EXISTS reviews_count INT DEFAULT 0 COMMENT 'Количество отзывов';

-- Создаем триггер для автоматического обновления среднего рейтинга
DELIMITER $$

CREATE TRIGGER update_user_rating_after_insert
AFTER INSERT ON reviews
FOR EACH ROW
BEGIN
  UPDATE users 
  SET 
    average_rating = (
      SELECT AVG(rating) 
      FROM reviews 
      WHERE reviewee_id = NEW.reviewee_id
    ),
    reviews_count = (
      SELECT COUNT(*) 
      FROM reviews 
      WHERE reviewee_id = NEW.reviewee_id
    )
  WHERE id = NEW.reviewee_id;
END$$

CREATE TRIGGER update_user_rating_after_update
AFTER UPDATE ON reviews
FOR EACH ROW
BEGIN
  UPDATE users 
  SET 
    average_rating = (
      SELECT AVG(rating) 
      FROM reviews 
      WHERE reviewee_id = NEW.reviewee_id
    ),
    reviews_count = (
      SELECT COUNT(*) 
      FROM reviews 
      WHERE reviewee_id = NEW.reviewee_id
    )
  WHERE id = NEW.reviewee_id;
END$$

CREATE TRIGGER update_user_rating_after_delete
AFTER DELETE ON reviews
FOR EACH ROW
BEGIN
  UPDATE users 
  SET 
    average_rating = (
      SELECT AVG(rating) 
      FROM reviews 
      WHERE reviewee_id = OLD.reviewee_id
    ),
    reviews_count = (
      SELECT COUNT(*) 
      FROM reviews 
      WHERE reviewee_id = OLD.reviewee_id
    )
  WHERE id = OLD.reviewee_id;
END$$

DELIMITER ;

