const fs = require('fs');
const path = require('path');
const { pool, createDatabaseIfNotExists } = require('../config/database');
const { runMigrations } = require('./migrations/run');
const { seedLegalDocuments } = require('./seedLegalDocuments');

async function initializeDatabase() {
  try {
    console.log('🔄 Initializing database...');
    
    // Создаем базу данных если не существует
    await createDatabaseIfNotExists();

    // Применяем baseline schema.sql + миграции (атомарнее, без split(';'))
    console.log('📝 Applying database migrations...');
    await runMigrations();
    console.log('✅ Database migrations applied successfully');

    try {
      const legalSeed = await seedLegalDocuments();
      if (legalSeed.seeded) {
        console.log(`✅ Legal documents seeded (${legalSeed.count} rows)`);
      }
    } catch (error) {
      console.error('⚠️  Legal documents seed failed:', error.message);
    }

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

