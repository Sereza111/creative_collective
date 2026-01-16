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

-- Добавляем поля для навыков и категорий в профиль пользователя
ALTER TABLE users 
  ADD COLUMN IF NOT EXISTS skills TEXT COMMENT 'Навыки пользователя (JSON массив)',
  ADD COLUMN IF NOT EXISTS categories TEXT COMMENT 'Категории работы (JSON массив)',
  ADD COLUMN IF NOT EXISTS bio TEXT COMMENT 'О себе',
  ADD COLUMN IF NOT EXISTS portfolio_url VARCHAR(500) COMMENT 'Ссылка на внешнее портфолио';

-- Индексы для быстрого поиска
CREATE INDEX IF NOT EXISTS idx_user_skills ON users(skills(100));
CREATE INDEX IF NOT EXISTS idx_user_categories ON users(categories(100));

