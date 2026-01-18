USE creative_collective;

-- Добавляем поле order_id в таблицы projects и tasks
ALTER TABLE projects
ADD COLUMN order_id INT DEFAULT NULL,
ADD FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE SET NULL;

ALTER TABLE tasks
ADD COLUMN order_id INT DEFAULT NULL,
ADD FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE SET NULL;

