# 🔍 Проверка подключения к серверу

## Шаг 1: Проверка что сервер вообще доступен

Открой в браузере или через curl:

```
http://85.198.103.11:3000
```

Должно вернуть что-то или ошибку (но не таймаут).

---

## Шаг 2: Проверка что MySQL работает

```
http://85.198.103.11:3306
```

Или в Portainer:
1. Открой контейнер `creative_collective_db`
2. Проверь что Status = **running** (зеленый)
3. Кликни **Logs** - не должно быть ошибок

---

## Шаг 3: Проверка что API запущен

В Portainer:
1. Открой контейнер `creative_collective_api`
2. Проверь **Status = running**
3. Кликни **Logs** - смотри что там пишет:
   - Если пишет "Server running on port 3000" - ✅ работает
   - Если ошибки про MySQL - база не доступна
   - Если ошибки про npm - проблема с зависимостями

---

## Шаг 4: Проверка endpoint'а

Открой в браузере:

```
http://85.198.103.11:3000/api/v1/auth/login
```

Должно вернуть JSON с ошибкой (это нормально, просто проверяем что сервер отвечает):
```json
{"success":false,"message":"Email и пароль обязательны"}
```

---

## Шаг 5: Проверка из Flutter приложения

Запусти Flutter app и посмотри в консоль - там будут ошибки от API.

---

## 🐛 Если ничего не работает - минимальный тест

### Создай простой HTML файл для проверки:

```html
<!DOCTYPE html>
<html>
<head>
    <title>Test API</title>
</head>
<body>
    <h1>Test Creative Collective API</h1>
    <button onclick="testConnection()">Test Connection</button>
    <pre id="result"></pre>

    <script>
        async function testConnection() {
            const result = document.getElementById('result');
            result.textContent = 'Connecting...';
            
            try {
                const response = await fetch('http://85.198.103.11:3000/api/v1/auth/login', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        email: 'admin@creative.local',
                        password: 'YOUR_PASSWORD'
                    })
                });
                
                const data = await response.json();
                result.textContent = JSON.stringify(data, null, 2);
            } catch (error) {
                result.textContent = 'ERROR: ' + error.message;
            }
        }
    </script>
</body>
</html>
```

Открой этот файл в браузере и нажми кнопку.

---

## 📊 Что смотреть в Portainer:

### Вкладка **Logs** контейнера API:

✅ **Хорошие признаки:**
```
Server running on port 3000
Database connected successfully
```

❌ **Плохие признаки:**
```
ECONNREFUSED - база не доступна
npm ERR! - проблема с установкой пакетов
Error: Cannot find module - не хватает файлов
```

---

## 🔧 Быстрый фикс если API не запускается:

В Portainer → контейнер API → **Console** → выполни:

```bash
cd /app/backend
npm install
node src/server.js
```

Смотри что выдаст - там будет точная ошибка.

