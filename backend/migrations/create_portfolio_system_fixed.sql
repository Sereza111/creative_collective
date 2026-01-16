USE creative_collective;

-- Таблица для портфолио фрилансеров
CREATE TABLE IF NOT EXISTS portfolio (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  image_url VARCHAR(500),
  project_url VARCHAR(500) COMMENT 'Ссылка на проект (если есть)',
  category VARCHAR(100) COMMENT 'Категория работы',
  skills TEXT COMMENT 'Навыки, использованные в проекте (JSON массив)',
  completed_at DATE COMMENT 'Дата завершения проекта',
  display_order INT DEFAULT 0 COMMENT 'Порядок отображения',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  
  INDEX idx_user_id (user_id),
  INDEX idx_category (category),
  INDEX idx_display_order (display_order)
);

-- Добавляем поля в users (БЕЗ IF NOT EXISTS - выполняй по одному!)
-- Если колонка уже существует, получишь ошибку - это нормально, просто пропусти её

-- Попробуй выполнить каждую команду отдельно:
ALTER TABLE users ADD COLUMN skills TEXT COMMENT 'Навыки пользователя (JSON массив)';

ALTER TABLE users ADD COLUMN categories TEXT COMMENT 'Категории работы (JSON массив)';

ALTER TABLE users ADD COLUMN bio TEXT COMMENT 'О себе';

ALTER TABLE users ADD COLUMN portfolio_url VARCHAR(500) COMMENT 'Ссылка на внешнее портфолио';

