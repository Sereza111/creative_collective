FROM node:18-alpine

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем манифест и lock-файл отдельно для кеширования слоя зависимостей
COPY package.json package-lock.json ./

# Воспроизводимая production-установка зависимостей
RUN npm ci --omit=dev

# Копируем исходный код
COPY . .

# Создаем директорию для загрузок
RUN mkdir -p uploads

# Открываем порт
EXPOSE 3000

# Запускаем приложение
CMD ["node", "src/server.js"]

