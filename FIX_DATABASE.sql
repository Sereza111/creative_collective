-- ИСПРАВЛЕНИЕ БД: Добавление недостающих полей для отзывов и портфолио
USE creative_collective;

-- Проверь, какие колонки уже есть, и добавь только недостающие:

-- 1. Поля для рейтингов (если их нет)
ALTER TABLE users ADD COLUMN average_rating DECIMAL(3,2) DEFAULT NULL;
ALTER TABLE users ADD COLUMN reviews_count INT DEFAULT 0;

-- 2. Поля для верификации (если их нет)
ALTER TABLE users ADD COLUMN is_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN verified_at TIMESTAMP NULL;
ALTER TABLE users ADD COLUMN verification_note TEXT;

-- 3. Поля для портфолио (если их нет)
ALTER TABLE users ADD COLUMN skills TEXT;
ALTER TABLE users ADD COLUMN categories TEXT;
ALTER TABLE users ADD COLUMN bio TEXT;
ALTER TABLE users ADD COLUMN portfolio_url VARCHAR(500);

-- 4. Создание триггеров для автоматического обновления рейтинга
DELIMITER $$

DROP TRIGGER IF EXISTS update_user_rating_after_insert$$
CREATE TRIGGER update_user_rating_after_insert
AFTER INSERT ON reviews
FOR EACH ROW
BEGIN
  UPDATE users 
  SET 
    average_rating = (SELECT AVG(rating) FROM reviews WHERE reviewee_id = NEW.reviewee_id),
    reviews_count = (SELECT COUNT(*) FROM reviews WHERE reviewee_id = NEW.reviewee_id)
  WHERE id = NEW.reviewee_id;
END$$

DROP TRIGGER IF EXISTS update_user_rating_after_update$$
CREATE TRIGGER update_user_rating_after_update
AFTER UPDATE ON reviews
FOR EACH ROW
BEGIN
  UPDATE users 
  SET 
    average_rating = (SELECT AVG(rating) FROM reviews WHERE reviewee_id = NEW.reviewee_id),
    reviews_count = (SELECT COUNT(*) FROM reviews WHERE reviewee_id = NEW.reviewee_id)
  WHERE id = NEW.reviewee_id;
END$$

DROP TRIGGER IF EXISTS update_user_rating_after_delete$$
CREATE TRIGGER update_user_rating_after_delete
AFTER DELETE ON reviews
FOR EACH ROW
BEGIN
  UPDATE users 
  SET 
    average_rating = (SELECT AVG(rating) FROM reviews WHERE reviewee_id = OLD.reviewee_id),
    reviews_count = (SELECT COUNT(*) FROM reviews WHERE reviewee_id = OLD.reviewee_id)
  WHERE id = OLD.reviewee_id;
END$$

DELIMITER ;

-- Проверка результата
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    IS_NULLABLE
FROM 
    INFORMATION_SCHEMA.COLUMNS 
WHERE 
    TABLE_SCHEMA = 'creative_collective' 
    AND TABLE_NAME = 'users'
    AND COLUMN_NAME IN ('average_rating', 'reviews_count', 'is_verified', 'skills', 'bio');

