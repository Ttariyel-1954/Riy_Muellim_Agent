// ============================================================
// Authentication & Security Middleware
// JWT + MFA (TOTP) + Audit Logging
// ============================================================
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const speakeasy = require('speakeasy');
const QRCode = require('qrcode');
const { query } = require('../../config/database');

// ─── JWT Authentication ─────────────────────────────────
const authenticate = async (req, res, next) => {
    try {
        const token = req.headers.authorization?.replace('Bearer ', '');
        if (!token) return res.status(401).json({ error: 'Token tələb olunur' });

        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const teacher = await query('SELECT id, email, role, first_name, last_name, school_id, mfa_enabled FROM teachers WHERE id = $1 AND is_active = true', [decoded.userId]);

        if (teacher.rows.length === 0) return res.status(401).json({ error: 'İstifadəçi tapılmadı' });

        req.user = teacher.rows[0];
        next();
    } catch (error) {
        if (error.name === 'TokenExpiredError') return res.status(401).json({ error: 'Token vaxtı bitib' });
        return res.status(401).json({ error: 'Yanlış token' });
    }
};

// ─── Role-based Authorization ───────────────────────────
const authorize = (...roles) => {
    return (req, res, next) => {
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({ error: 'Bu əməliyyat üçün icazəniz yoxdur' });
        }
        next();
    };
};

// ─── Login ──────────────────────────────────────────────
const login = async (req, res) => {
    try {
        const { email, password, mfaCode } = req.body;
        const teacher = await query('SELECT * FROM teachers WHERE email = $1 AND is_active = true', [email]);

        if (teacher.rows.length === 0) return res.status(401).json({ error: 'Email və ya şifrə yanlışdır' });

        const user = teacher.rows[0];
        const validPassword = await bcrypt.compare(password, user.password_hash);
        if (!validPassword) return res.status(401).json({ error: 'Email və ya şifrə yanlışdır' });

        // MFA check
        if (user.mfa_enabled) {
            if (!mfaCode) return res.status(200).json({ mfaRequired: true, message: 'MFA kodu tələb olunur' });
            const verified = speakeasy.totp.verify({ secret: user.mfa_secret, encoding: 'base32', token: mfaCode });
            if (!verified) return res.status(401).json({ error: 'MFA kodu yanlışdır' });
        }

        const token = jwt.sign({ userId: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '24h' });
        const refreshToken = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d' });

        // Update last login
        await query('UPDATE teachers SET last_login = NOW() WHERE id = $1', [user.id]);

        // Audit log
        await auditLog(user.id, user.role, 'login', 'teacher', user.id, { ip: req.ip }, req);

        res.json({
            token, refreshToken,
            user: { id: user.id, email: user.email, name: `${user.first_name} ${user.last_name}`, role: user.role }
        });
    } catch (error) {
        res.status(500).json({ error: 'Giriş xətası: ' + error.message });
    }
};

// ─── MFA Setup ──────────────────────────────────────────
const setupMFA = async (req, res) => {
    try {
        const secret = speakeasy.generateSecret({ name: `ARTI:${req.user.email}`, issuer: process.env.MFA_ISSUER || 'ARTI' });
        await query('UPDATE teachers SET mfa_secret = $1 WHERE id = $2', [secret.base32, req.user.id]);

        const qrCode = await QRCode.toDataURL(secret.otpauth_url);
        res.json({ secret: secret.base32, qrCode });
    } catch (error) {
        res.status(500).json({ error: 'MFA quraşdırma xətası' });
    }
};

const enableMFA = async (req, res) => {
    try {
        const { code } = req.body;
        const user = await query('SELECT mfa_secret FROM teachers WHERE id = $1', [req.user.id]);
        const verified = speakeasy.totp.verify({ secret: user.rows[0].mfa_secret, encoding: 'base32', token: code });

        if (!verified) return res.status(400).json({ error: 'Kod yanlışdır' });

        await query('UPDATE teachers SET mfa_enabled = true WHERE id = $1', [req.user.id]);
        await auditLog(req.user.id, req.user.role, 'mfa_enabled', 'teacher', req.user.id, {}, req);

        res.json({ success: true, message: 'MFA aktivləşdirildi' });
    } catch (error) {
        res.status(500).json({ error: 'MFA aktivləşdirmə xətası' });
    }
};

// ─── Audit Logging ──────────────────────────────────────
const auditLog = async (userId, userRole, action, entityType, entityId, details = {}, req = null) => {
    try {
        await query(`
            INSERT INTO audit_logs (user_id, user_role, action, entity_type, entity_id, details, ip_address, user_agent)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        `, [userId, userRole, action, entityType, entityId, JSON.stringify(details),
            req?.ip || null, req?.get('user-agent') || null]);
    } catch (e) {
        console.error('Audit log xətası:', e.message);
    }
};

// ─── Audit Middleware ───────────────────────────────────
const auditMiddleware = (action, entityType) => {
    return async (req, res, next) => {
        const originalSend = res.json.bind(res);
        res.json = (body) => {
            if (res.statusCode < 400) {
                auditLog(req.user?.id, req.user?.role, action, entityType, req.params?.id, { method: req.method, path: req.path }, req);
            }
            return originalSend(body);
        };
        next();
    };
};

module.exports = { authenticate, authorize, login, setupMFA, enableMFA, auditLog, auditMiddleware };
