-- Seed data для Creative Collective
-- Тестовые данные для разработки

-- Очистка таблиц (осторожно! удаляет все данные)
-- SET FOREIGN_KEY_CHECKS = 0;
-- TRUNCATE TABLE notifications;
-- TRUNCATE TABLE files;
-- TRUNCATE TABLE comments;
-- TRUNCATE TABLE transactions;
-- TRUNCATE TABLE finances;
-- TRUNCATE TABLE tasks;
-- TRUNCATE TABLE project_members;
-- TRUNCATE TABLE projects;
-- TRUNCATE TABLE team_members;
-- TRUNCATE TABLE teams;
-- TRUNCATE TABLE refresh_tokens;
-- TRUNCATE TABLE users;
-- SET FOREIGN_KEY_CHECKS = 1;

-- =============================================
-- Пользователи (пароль для всех: password123)
-- =============================================
INSERT INTO users (id, email, username, password_hash, first_name, last_name, role, bio) VALUES
('user-1', 'denis@creative.com', 'denis', '$2a$10$rF8qYQm9h8wQX5KGqpXo1.5X9Y0zqJ3hK1vYxF9pZ8LmU7Vo8qRKu', 'Денис', 'Программист', 'admin', 'Full Stack Developer'),
('user-2', 'ivan@creative.com', 'ivan', '$2a$10$rF8qYQm9h8wQX5KGqpXo1.5X9Y0zqJ3hK1vYxF9pZ8LmU7Vo8qRKu', 'Иван', 'Битмейкер', 'member', 'Music Producer'),
('user-3', 'maria@creative.com', 'maria', '$2a$10$rF8qYQm9h8wQX5KGqpXo1.5X9Y0zqJ3hK1vYxF9pZ8LmU7Vo8qRKu', 'Мария', 'Дизайнер', 'member', 'UI/UX Designer'),
('user-4', 'alexey@creative.com', 'alexey', '$2a$10$rF8qYQm9h8wQX5KGqpXo1.5X9Y0zqJ3hK1vYxF9pZ8LmU7Vo8qRKu', 'Алексей', 'Монтажер', 'member', 'Video Editor');

-- =============================================
-- Команда
-- =============================================
INSERT INTO teams (id, name, description, owner_id) VALUES
('team-1', 'Creative Collective', 'Основная творческая команда', 'user-1');

-- =============================================
-- Участники команды
-- =============================================
INSERT INTO team_members (id, team_id, user_id, role, skills) VALUES
('tm-1', 'team-1', 'user-1', 'Программист', '["Flutter", "React", "Node.js"]'),
('tm-2', 'team-1', 'user-2', 'Битмейкер', '["FL Studio", "Ableton", "Logic Pro"]'),
('tm-3', 'team-1', 'user-3', 'Дизайнер', '["Figma", "Photoshop", "Illustrator"]'),
('tm-4', 'team-1', 'user-4', 'Монтажер', '["Premiere Pro", "After Effects"]');

-- =============================================
-- Проекты
-- =============================================
INSERT INTO projects (id, name, description, status, start_date, end_date, progress, budget, spent, team_id, created_by) VALUES
('proj-1', 'Видеоклип "Cyberpunk"', 'Создание полноценного видеоклипа в киберпанк стилистике', 'active', '2025-11-01', '2025-12-20', 75, 50000.00, 37500.00, 'team-1', 'user-1'),
('proj-2', 'Звуковой дизайн для игры', 'Разработка звукового оформления для инди игры', 'active', '2025-12-01', '2026-01-15', 40, 35000.00, 14000.00, 'team-1', 'user-2'),
('proj-3', '3D модели персонажей', 'Создание 3D моделей для анимационного проекта', 'active', '2025-11-15', '2025-12-30', 60, 45000.00, 27000.00, 'team-1', 'user-3'),
('proj-4', 'Анимация лого', 'Анимированный логотип для компании', 'active', '2025-12-01', '2025-12-12', 90, 15000.00, 13500.00, 'team-1', 'user-4');

-- =============================================
-- Участники проектов
-- =============================================
INSERT INTO project_members (id, project_id, user_id, role) VALUES
('pm-1', 'proj-1', 'user-1', 'Project Manager'),
('pm-2', 'proj-1', 'user-2', 'Music Producer'),
('pm-3', 'proj-1', 'user-4', 'Video Editor'),
('pm-4', 'proj-2', 'user-2', 'Lead Sound Designer'),
('pm-5', 'proj-3', 'user-3', 'Lead 3D Artist'),
('pm-6', 'proj-4', 'user-4', 'Animator');

-- =============================================
-- Задачи
-- =============================================
INSERT INTO tasks (id, title, description, status, priority, due_date, project_id, assigned_to, created_by) VALUES
('task-1', 'Создать биту для видеоклипа', 'Разработать основную музыкальную композицию', 'in_progress', 3, '2025-12-15 23:59:59', 'proj-1', 'user-2', 'user-1'),
('task-2', 'Записать вокал', 'Запись вокальных партий для трека', 'todo', 5, '2025-12-20 23:59:59', 'proj-1', 'user-2', 'user-1'),
('task-3', 'Микс и мастеринг', 'Финальное сведение и мастеринг трека', 'done', 2, '2025-12-10 23:59:59', 'proj-1', 'user-2', 'user-1'),
('task-4', 'Цветокоррекция видео', 'Обработка и цветокоррекция отснятого материала', 'in_progress', 4, '2025-12-18 23:59:59', 'proj-1', 'user-4', 'user-1'),
('task-5', 'Создать звуки окружения', 'Ambient звуки для игровых локаций', 'in_progress', 3, '2026-01-10 23:59:59', 'proj-2', 'user-2', 'user-2'),
('task-6', 'Моделирование главного героя', 'High-poly модель протагониста', 'in_progress', 5, '2025-12-25 23:59:59', 'proj-3', 'user-3', 'user-3');

-- =============================================
-- Финансы
-- =============================================
INSERT INTO finances (id, user_id, balance, total_earned, total_spent, currency) VALUES
('fin-1', 'user-1', 45250.00, 125000.00, 79750.00, 'RUB'),
('fin-2', 'user-2', 32500.00, 85000.00, 52500.00, 'RUB'),
('fin-3', 'user-3', 28750.00, 95000.00, 66250.00, 'RUB'),
('fin-4', 'user-4', 19800.00, 72000.00, 52200.00, 'RUB');

-- =============================================
-- Транзакции
-- =============================================
INSERT INTO transactions (id, finance_id, type, amount, description, project_id, category, transaction_date) VALUES
('trans-1', 'fin-1', 'earned', 8000.00, 'Оплата проекта "Видеоклип"', 'proj-1', 'Проект', '2025-12-15 14:30:00'),
('trans-2', 'fin-1', 'bonus', 500.00, 'Бонус за выполнение', 'proj-1', 'Бонус', '2025-12-14 10:00:00'),
('trans-3', 'fin-1', 'spent', 2000.00, 'Adobe Creative Cloud', NULL, 'Подписка', '2025-12-12 09:00:00'),
('trans-4', 'fin-1', 'earned', 12500.00, 'Оплата за анимацию', 'proj-4', 'Проект', '2025-12-10 16:45:00'),
('trans-5', 'fin-1', 'spent', 1500.00, 'Покупка плагинов', NULL, 'Инструменты', '2025-12-08 12:30:00'),
('trans-6', 'fin-2', 'earned', 15000.00, 'Оплата за музыку', 'proj-1', 'Проект', '2025-12-05 11:20:00'),
('trans-7', 'fin-3', 'earned', 18000.00, 'Дизайн персонажей', 'proj-3', 'Проект', '2025-12-03 15:00:00'),
('trans-8', 'fin-4', 'earned', 10000.00, 'Монтаж видео', 'proj-1', 'Проект', '2025-12-01 13:15:00');

-- =============================================
-- Комментарии
-- =============================================
INSERT INTO comments (id, content, entity_type, entity_id, user_id) VALUES
('com-1', 'Отличная работа! Бит звучит мощно', 'task', 'task-1', 'user-1'),
('com-2', 'Нужно добавить больше bass для киберпанк звучания', 'task', 'task-1', 'user-2'),
('com-3', 'Проект идет по плану, отличные результаты', 'project', 'proj-1', 'user-1'),
('com-4', 'Цветокоррекция выглядит потрясающе!', 'task', 'task-4', 'user-1');

-- =============================================
-- Уведомления
-- =============================================
INSERT INTO notifications (id, user_id, title, message, type, entity_id) VALUES
('notif-1', 'user-1', 'Новая задача', 'Вам назначена новая задача: Создать биту для видеоклипа', 'task', 'task-1'),
('notif-2', 'user-2', 'Комментарий к задаче', 'Новый комментарий к вашей задаче', 'task', 'task-1'),
('notif-3', 'user-1', 'Выполнена транзакция', 'Получена оплата: ₽8,000', 'finance', 'trans-1'),
('notif-4', 'user-4', 'Обновление проекта', 'Прогресс проекта "Видеоклип Cyberpunk" обновлен', 'project', 'proj-1');

