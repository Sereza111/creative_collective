const http = require('http');

console.log('🔍 Проверка подключения к Creative Collective API...\n');

const testEndpoints = [
  { name: 'Основной API', url: 'http://85.198.103.11:3000' },
  { name: 'API Health', url: 'http://85.198.103.11:3000/api/v1' },
];

function testConnection(endpoint) {
  return new Promise((resolve) => {
    console.log(`Проверяю: ${endpoint.name} (${endpoint.url})`);
    
    const req = http.get(endpoint.url, { timeout: 5000 }, (res) => {
      console.log(`✅ Ответ получен: ${res.statusCode}`);
      
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        console.log(`📦 Данные: ${data.substring(0, 100)}...\n`);
        resolve({ success: true, status: res.statusCode });
      });
    });

    req.on('error', (error) => {
      console.log(`❌ Ошибка: ${error.message}\n`);
      resolve({ success: false, error: error.message });
    });

    req.on('timeout', () => {
      console.log(`⏱️ Таймаут: сервер не ответил за 5 секунд\n`);
      req.destroy();
      resolve({ success: false, error: 'timeout' });
    });
  });
}

async function runTests() {
  console.log('====================================\n');
  
  for (const endpoint of testEndpoints) {
    await testConnection(endpoint);
  }
  
  console.log('====================================');
  console.log('\n📊 РЕЗУЛЬТАТЫ:');
  console.log('\nЕсли видишь ✅ - сервер работает');
  console.log('Если видишь ❌ или ⏱️ - сервер недоступен\n');
  console.log('====================================\n');
}

runTests();

