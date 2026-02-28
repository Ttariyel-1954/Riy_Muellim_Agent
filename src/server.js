// ============================================================
// MÜƏLLİM AGENT - Main Server
// ARTI 2026 - Azərbaycan Respublikası Təhsil İnstitutu
// Author: Tariyel Talibov
// ============================================================
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const path = require('path');
const fs = require('fs');

const { testConnection } = require('../config/database');
const routes = require('./api/routes');

const app = express();
const PORT = process.env.PORT || 3000;

// ─── Security ───────────────────────────────────────────
app.use(helmet());
app.use(cors({
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP
    message: { error: 'Çox sayda sorğu. 15 dəqiqə gözləyin.' },
});
app.use('/api/', limiter);

// AI endpoint rate limiting (more restrictive)
const aiLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 10, // 10 AI calls per minute
    message: { error: 'AI sorğu limiti aşılıb. 1 dəqiqə gözləyin.' },
});
app.use('/api/v1/lessons/generate', aiLimiter);
app.use('/api/v1/assessments/generate', aiLimiter);

// ─── Middleware ──────────────────────────────────────────
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan('combined'));

// Ensure upload directory exists
const uploadDir = process.env.UPLOAD_DIR || './uploads';
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

// ─── Routes ─────────────────────────────────────────────
app.use('/api/v1', routes);

// Root endpoint
app.get('/', (req, res) => {
    res.json({
        name: '🎓 Müəllim Agent - ARTI 2026',
        description: 'Orta məktəb müəllimləri üçün AI agent sistemi',
        version: '1.0.0',
        author: 'Tariyel Talibov - ARTI',
        agents: {
            '1. Tədris Planlaşdırılması': '/api/v1/lessons/*',
            '2. Qiymətləndirmə': '/api/v1/assessments/*',
            '3. Pedaqoji Dəstək': '/api/v1/pedagogy/*',
            '4. Rəqəmsal Köməkçi': '/api/v1/documents/*',
            '5. Şagird Analizi': '/api/v1/students/*',
            '6. Kommunikasiya': '/api/v1/communication/*',
        },
        endpoints: {
            health: '/api/v1/health',
            subjects: '/api/v1/subjects',
            standards: '/api/v1/standards/:subjectCode/:grade',
            frameworks: '/api/v1/frameworks',
        },
        documentation: '/docs',
    });
});

// ─── Error Handling ─────────────────────────────────────
app.use((err, req, res, next) => {
    console.error('❌ Server xətası:', err);
    res.status(err.status || 500).json({
        success: false,
        error: process.env.NODE_ENV === 'production' ? 'Daxili server xətası' : err.message,
    });
});

// 404
app.use((req, res) => {
    res.status(404).json({ success: false, error: 'Endpoint tapılmadı' });
});

// ─── Start Server ───────────────────────────────────────
async function start() {
    console.log('╔══════════════════════════════════════════╗');
    console.log('║   🎓 MÜƏLLİM AGENT - ARTI 2026         ║');
    console.log('║   AI Agent for Teachers                  ║');
    console.log('╚══════════════════════════════════════════╝');

    // Test database
    const dbConnected = await testConnection();
    if (!dbConnected) {
        console.warn('⚠️  Verilənlər bazası əlçatan deyil. Demo rejimində işləyir.');
    }

    app.listen(PORT, () => {
        console.log(`\n🚀 Server işləyir: http://localhost:${PORT}`);
        console.log(`📊 API: http://localhost:${PORT}/api/v1`);
        console.log(`💚 Health: http://localhost:${PORT}/api/v1/health`);
        console.log(`📚 Fənlər: http://localhost:${PORT}/api/v1/subjects`);
        console.log(`\n📋 6 Agent aktiv:`);
        console.log('   1️⃣  Tədris Planlaşdırılması');
        console.log('   2️⃣  Qiymətləndirmə və İmtahan');
        console.log('   3️⃣  Pedaqoji Dəstək');
        console.log('   4️⃣  Rəqəmsal Köməkçi');
        console.log('   5️⃣  Şagird Analizi');
        console.log('   6️⃣  Kommunikasiya');
    });
}

start().catch(console.error);

module.exports = app;
