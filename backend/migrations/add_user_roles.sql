-- Добавление ролей пользователей для маркетплейса
-- Роли: client (заказчик), freelancer (фрилансер), admin (администратор платформы)

ALTER TABLE users ADD COLUMN user_role ENUM('client', 'freelancer', 'admin') DEFAULT 'freelancer' AFTER role;

-- Обновить существующих пользователей
UPDATE users SET user_role = 'freelancer' WHERE user_role IS NULL;

