// ============================================================
// Database Migration Runner
// Usage: node database/migrations/run.js
// ============================================================
const fs = require('fs');
const path = require('path');
const { pool, testConnection } = require('../../config/database');

async function runMigrations() {
    console.log('🔄 Migrasiya başlayır...\n');

    const connected = await testConnection();
    if (!connected) {
        console.error('❌ Verilənlər bazasına qoşulmaq mümkün olmadı.');
        process.exit(1);
    }

    const migrationsDir = __dirname;
    const files = fs.readdirSync(migrationsDir)
        .filter(f => f.endsWith('.sql'))
        .sort();

    for (const file of files) {
        console.log(`📄 Migrasiya: ${file}`);
        const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf8');

        try {
            await pool.query(sql);
            console.log(`   ✅ Uğurlu: ${file}\n`);
        } catch (error) {
            console.error(`   ❌ Xəta: ${file}`, error.message);
            process.exit(1);
        }
    }

    console.log('✅ Bütün migrasiyalar tamamlandı!');
    await pool.end();
}

runMigrations();
