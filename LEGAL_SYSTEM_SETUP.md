# 📜 УСТАНОВКА СИСТЕМЫ ЮРИДИЧЕСКИХ ДОКУМЕНТОВ

## ✅ ЧТО СДЕЛАНО

### 1. **Система электронной подписи документов**
- ✅ Таблицы БД для хранения документов и подписей
- ✅ API для получения и подписания документов
- ✅ UI с прокруткой до конца + галочка "Я согласен"
- ✅ Проверка подписи перед откликом на заказ
- ✅ Хранение IP-адреса и User-Agent при подписи

### 2. **Защита от игнорирования откликов**
- ✅ Отслеживание просмотров откликов заказчиком
- ✅ Автоматический возврат 50 ₽ через 7 дней игнорирования
- ✅ Cron job для ежедневной проверки (03:00)
- ✅ Уведомления фрилансеру и заказчику

### 3. **Юридические документы**
- ✅ Пользовательское соглашение
- ✅ Условия для фрилансеров
- ✅ Условия для заказчиков

---

## 🚀 ИНСТРУКЦИЯ ПО УСТАНОВКЕ

### **ШАГ 1: Создание таблиц БД**

Выполни в **phpMyAdmin** (по порядку):

```sql
-- 1. Создание таблиц
USE creative_collective;
SOURCE backend/migrations/create_legal_agreements_system.sql;

-- 2. Вставка юридических документов
SOURCE backend/migrations/insert_legal_documents.sql;
```

**Или вручную:**

1. Открой `backend/migrations/create_legal_agreements_system.sql`
2. Скопируй весь SQL
3. Вставь в phpMyAdmin → SQL → Выполнить

4. Открой `backend/migrations/insert_legal_documents.sql`
5. Скопируй весь SQL
6. Вставь в phpMyAdmin → SQL → Выполнить

---

### **ШАГ 2: Pull and Redeploy в Portainer**

1. Открой **Portainer**
2. Найди контейнер `creative_collective_backend`
3. Нажми **"Pull and Redeploy"**
4. Дождись перезапуска

---

### **ШАГ 3: Проверка работы**

1. **Запусти приложение:**
   ```bash
   flutter run -d windows
   ```

2. **Проверь подписание документов:**
   - Зайди в приложение
   - Попробуй откликнуться на заказ
   - Должен появиться экран с документом "Условия для фрилансеров"
   - Прокрути до конца
   - Поставь галочку "Я согласен"
   - Нажми "ПОДПИСАТЬ ДОКУМЕНТ"

3. **Проверь автоматический возврат:**
   - Создай отклик на заказ (будет списано 50 ₽)
   - Заказчик должен игнорировать отклик 7 дней
   - Через 7 дней в 03:00 автоматически вернутся 50 ₽

---

## 📊 ПРОВЕРКА ТАБЛИЦ

Выполни в **phpMyAdmin**:

```sql
USE creative_collective;

-- Проверка таблиц
SHOW TABLES LIKE 'legal%';
SHOW TABLES LIKE 'application%';

-- Проверка документов
SELECT id, document_type, version, title FROM legal_documents;

-- Проверка подписей (после того, как подпишешь)
SELECT * FROM user_agreements ORDER BY agreed_at DESC LIMIT 10;

-- Проверка возвратов (через 7 дней)
SELECT * FROM application_refunds ORDER BY refunded_at DESC LIMIT 10;
```

**Ожидаемый результат:**

```
Tables:
- legal_documents
- user_agreements
- application_views
- application_refunds

Documents (3 rows):
1. user_agreement (v1.0) - Пользовательское соглашение
2. freelancer_terms (v1.0) - Условия для фрилансеров
3. client_terms (v1.0) - Условия для заказчиков
```

---

## 🔧 КАК ЭТО РАБОТАЕТ

### **1. Подписание документов**

**Фрилансер:**
- При первом отклике → показывается `freelancer_terms`
- Должен прокрутить до конца
- Поставить галочку
- Нажать "ПОДПИСАТЬ"
- Подпись сохраняется в `user_agreements`

**Заказчик:**
- При создании заказа → показывается `client_terms`
- Аналогичный процесс

### **2. Защита от игнорирования**

**Как работает:**

1. Фрилансер откликается на заказ → списывается 50 ₽
2. Заказчик получает уведомление
3. Если заказчик **не просматривает отклик 7 дней**:
   - Cron job (ежедневно в 03:00) находит игнорированные отклики
   - Возвращает 50 ₽ фрилансеру
   - Создает уведомление фрилансеру: "Возврат 50 ₽"
   - Создает предупреждение заказчику: "⚠️ Вы игнорировали отклик"
   - Статус отклика меняется на `refunded`

**Как заказчик может избежать возврата:**
- Просмотреть отклик (нажать на него)
- Принять или отклонить отклик

---

## 🛠️ РУЧНОЙ ЗАПУСК ВОЗВРАТА (ДЛЯ ТЕСТА)

Если хочешь протестировать возврат **прямо сейчас** (не ждать 7 дней):

1. **Измени срок в SQL (для теста):**

```sql
-- Временно изменяем срок с 7 дней на 1 минуту
UPDATE order_applications 
SET created_at = DATE_SUB(NOW(), INTERVAL 8 DAY) 
WHERE status = 'pending' AND viewed_by_client = FALSE 
LIMIT 1;
```

2. **Запусти возврат через API (Postman или curl):**

```bash
ACCESS_TOKEN="paste_admin_access_token_here"

curl -X POST http://localhost:3000/api/v1/legal/process-ignored \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

3. **Проверь результат:**

```sql
SELECT * FROM application_refunds ORDER BY refunded_at DESC LIMIT 1;
SELECT * FROM transactions WHERE type = 'refund' ORDER BY date DESC LIMIT 1;
```

---

## 📋 ДОПОЛНИТЕЛЬНЫЕ КОМАНДЫ

### **Просмотр логов Cron Job**

Если хочешь увидеть, как работает автоматический возврат:

```bash
# В Docker контейнере
docker logs creative_collective_backend -f --tail 100
```

Ищи строки:
```
[SCHEDULER] Running refund job...
[REFUND JOB] Found X ignored applications
[REFUND JOB] Refunded application #123
[SCHEDULER] Refund job completed: 5/5
```

### **Ручное добавление документа**

Если хочешь добавить новый документ:

```sql
INSERT INTO legal_documents (document_type, version, title, content, is_active) 
VALUES (
  'privacy_policy', 
  '1.0', 
  'Политика конфиденциальности', 
  '# ПОЛИТИКА КОНФИДЕНЦИАЛЬНОСТИ\n\n...', 
  TRUE
);
```

---

## ⚠️ ВАЖНЫЕ МОМЕНТЫ

### **1. Комиссия и стоимость отклика**

Текущие значения:
- **Комиссия платформы:** 3% (было 10%)
- **Стоимость отклика:** 50 ₽
- **Срок игнорирования:** 7 дней

Если хочешь изменить:

```javascript
// backend/src/controllers/ordersController.js
const applicationFee = 50; // Измени здесь

// backend/src/controllers/financeController.js
const platformCommissionRate = 0.03; // 3%

// backend/src/jobs/refundIgnoredApplications.js
const applicationFee = 50; // Измени здесь
INTERVAL 7 DAY // Измени срок здесь
```

### **2. Время запуска Cron Job**

Текущее время: **03:00 ежедневно**

Если хочешь изменить:

```javascript
// backend/src/jobs/scheduler.js
cron.schedule('0 3 * * *', async () => { // '0 3 * * *' = 03:00 каждый день
  // Формат: минута час день месяц день_недели
  // Примеры:
  // '0 */6 * * *' - каждые 6 часов
  // '30 2 * * *' - в 02:30 каждый день
  // '0 0 * * 0' - в 00:00 каждое воскресенье
});
```

---

## 🎯 СЛЕДУЮЩИЕ ШАГИ

После установки системы:

1. ✅ **Протестируй подписание документов**
2. ✅ **Проверь возврат средств (ручной запуск)**
3. ✅ **Дождись автоматического возврата (через 7 дней)**
4. ✅ **Проверь уведомления**

---

## 🆘 ПРОБЛЕМЫ И РЕШЕНИЯ

### **Проблема: "Документ не найден"**

**Решение:**
```sql
-- Проверь, что документы вставлены
SELECT * FROM legal_documents WHERE is_active = TRUE;

-- Если пусто, выполни:
SOURCE backend/migrations/insert_legal_documents.sql;
```

### **Проблема: "Cron job не запускается"**

**Решение:**
```bash
# Проверь логи
docker logs creative_collective_backend -f

# Должна быть строка:
# [SCHEDULER] Scheduled jobs initialized successfully
```

### **Проблема: "Возврат не происходит"**

**Решение:**
```sql
-- Проверь, что отклик старше 7 дней и не просмотрен
SELECT oa.id, oa.created_at, oa.viewed_by_client, oa.status
FROM order_applications oa
WHERE oa.status = 'pending' 
  AND oa.viewed_by_client = FALSE
  AND oa.created_at < DATE_SUB(NOW(), INTERVAL 7 DAY);

-- Если есть такие отклики, запусти возврат вручную через API
```

---

## ✅ ГОТОВО!

Теперь у тебя есть:
- ✅ Система электронной подписи документов
- ✅ Защита от игнорирования откликов
- ✅ Автоматический возврат средств
- ✅ Уведомления для пользователей

**ЗАПУСКАЙ И ТЕСТИРУЙ!** 🚀

