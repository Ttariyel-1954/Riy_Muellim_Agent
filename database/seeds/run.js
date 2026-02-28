const fs = require('fs');
const path = require('path');
const { pool, testConnection } = require('../../config/database');

async function runSeeds() {
    console.log('🌱 Seed data yüklənir...\n');
    const connected = await testConnection();
    if (!connected) { process.exit(1); }

    const seedsDir = __dirname;
    const files = fs.readdirSync(seedsDir).filter(f => f.endsWith('.sql')).sort();

    for (const file of files) {
        console.log(`📄 Seed: ${file}`);
        const sql = fs.readFileSync(path.join(seedsDir, file), 'utf8');
        try {
            await pool.query(sql);
            console.log(`   ✅ Uğurlu: ${file}\n`);
        } catch (error) {
            console.error(`   ❌ Xəta: ${file}`, error.message);
        }
    }

    console.log('✅ Seed data yükləndi!');
    await pool.end();
}

runSeeds();
