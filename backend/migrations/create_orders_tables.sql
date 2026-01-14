-- Таблица заказов (маркетплейс)
CREATE TABLE IF NOT EXISTS orders (
  id INT PRIMARY KEY AUTO_INCREMENT,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  budget DECIMAL(18,2),
  deadline DATE,
  status ENUM('draft', 'published', 'in_progress', 'review', 'completed', 'cancelled') DEFAULT 'draft',
  client_id INT NOT NULL,
  freelancer_id INT NULL,
  category VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (client_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (freelancer_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Таблица откликов фрилансеров на заказы
CREATE TABLE IF NOT EXISTS order_applications (
  id INT PRIMARY KEY AUTO_INCREMENT,
  order_id INT NOT NULL,
  freelancer_id INT NOT NULL,
  message TEXT,
  proposed_budget DECIMAL(18,2),
  proposed_deadline DATE,
  status ENUM('pending', 'accepted', 'rejected') DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
  FOREIGN KEY (freelancer_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Таблица платежей
CREATE TABLE IF NOT EXISTS payments (
  id INT PRIMARY KEY AUTO_INCREMENT,
  order_id INT NOT NULL,
  amount DECIMAL(18,2) NOT NULL,
  platform_fee DECIMAL(18,2) NOT NULL,
  freelancer_amount DECIMAL(18,2) NOT NULL,
  status ENUM('pending', 'completed', 'refunded') DEFAULT 'pending',
  payment_method VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP NULL,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);

-- Индексы для оптимизации
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_client ON orders(client_id);
CREATE INDEX idx_orders_freelancer ON orders(freelancer_id);
CREATE INDEX idx_applications_order ON order_applications(order_id);
CREATE INDEX idx_applications_freelancer ON order_applications(freelancer_id);
CREATE INDEX idx_payments_order ON payments(order_id);

