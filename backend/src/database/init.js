const fs = require('fs');
const path = require('path');
const { pool, createDatabaseIfNotExists } = require('../config/database');

async function initializeDatabase() {
  try {
    console.log('🔄 Initializing database...');
    
    // Создаем базу данных если не существует
    await createDatabaseIfNotExists();
    
    // Читаем и выполняем schema.sql
    console.log('📝 Creating tables...');
    const schemaSQL = fs.readFileSync(
      path.join(__dirname, 'schema.sql'),
      'utf8'
    );
    
    // Разбиваем на отдельные запросы
    const queries = schemaSQL
      .split(';')
      .map(q => q.trim())
      .filter(q => q.length > 0 && !q.startsWith('--'));
    
    for (const query of queries) {
      if (query.includes('DELIMITER')) continue;
      try {
        await pool.query(query);
      } catch (error) {
        if (!error.message.includes('already exists')) {
          console.error('Error executing query:', error.message);
        }
      }
    }
    
    console.log('✅ Database schema created successfully');
    
    // Проверяем, есть ли уже данные
    const [users] = await pool.query('SELECT COUNT(*) as count FROM users');
    
    if (users[0].count === 0) {
      console.log('📝 Seeding database with initial data...');
      const seedSQL = fs.readFileSync(
        path.join(__dirname, 'seed.sql'),
        'utf8'
      );
      
      const seedQueries = seedSQL
        .split(';')
        .map(q => q.trim())
        .filter(q => q.length > 0 && !q.startsWith('--'));
      
      for (const query of seedQueries) {
        try {
          await pool.query(query);
        } catch (error) {
          console.error('Error seeding data:', error.message);
        }
      }
      
      console.log('✅ Database seeded successfully');
    } else {
      console.log('ℹ️  Database already contains data, skipping seed');
    }
    
    console.log('✅ Database initialization complete!');
    return true;
  } catch (error) {
    console.error('❌ Database initialization failed:', error);
    throw error;
  }
}

// Запуск если файл вызван напрямую
if (require.main === module) {
  initializeDatabase()
    .then(() => {
      console.log('Done!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Failed:', error);
      process.exit(1);
    });
}

module.exports = { initializeDatabase };

