// ============================================================
// Agent 5: Şagird Analizi və İnkişaf (Student Progress Agent)
// - Öyrənmə profili
// - Real-time monitorinq
// - Risk qrupları avtomatik aşkarlama
// - İnklyuziv şagird modulu
// ============================================================
const { AIEngine } = require('../../core/ai_engine');
const { query, transaction } = require('../../../config/database');

class StudentProgressAgent {
    constructor() {
        this.ai = new AIEngine();
    }

    // ─── Öyrənmə Profili Yaratma/Yeniləmə ──────────────
    async updateLearningProfile(studentId) {
        // Gather all data
        const student = await query('SELECT * FROM students WHERE id = $1', [studentId]);
        const assessmentResults = await query(`
            SELECT ar.*, a.title, s.name_az as subject_name
            FROM assessment_results ar
            JOIN assessments a ON ar.assessment_id = a.id
            JOIN subjects s ON a.subject_id = s.id
            WHERE ar.student_id = $1
            ORDER BY ar.completed_at DESC LIMIT 20
        `, [studentId]);

        const progressLogs = await query(`
            SELECT spl.*, s.name_az as subject_name
            FROM student_progress_logs spl
            LEFT JOIN subjects s ON spl.subject_id = s.id
            WHERE spl.student_id = $1
            ORDER BY spl.log_date DESC LIMIT 50
        `, [studentId]);

        const attendance = await query(`
            SELECT status, COUNT(*) as count
            FROM attendance WHERE student_id = $1 AND attendance_date > NOW() - INTERVAL '90 days'
            GROUP BY status
        `, [studentId]);

        // AI analysis
        const prompt = `Şagird profili analiz et:

ŞAGİRD: ${student.rows[0]?.first_name} ${student.rows[0]?.last_name}
SİNİF: ${student.rows[0]?.grade}
İnklyuziv: ${student.rows[0]?.is_inclusive ? 'Bəli - ' + student.rows[0]?.inclusive_type : 'Xeyr'}

SON QİYMƏTLƏNDİRMƏ NƏTİCƏLƏRİ:
${assessmentResults.rows.map(r => `- ${r.subject_name}: ${r.percentage}% (${r.mastery_level})`).join('\n')}

DAVAMIYYƏT (son 90 gün):
${attendance.rows.map(a => `${a.status}: ${a.count}`).join(', ')}

SON QEYDLƏR:
${progressLogs.rows.slice(0, 10).map(l => `[${l.log_date}] ${l.subject_name}: ${l.title} - ${l.score}/${l.max_score}`).join('\n')}

ANALİZ ET:
1. Güclü tərəflər (fənn üzrə)
2. Zəif tərəflər (fənn üzrə)
3. Bilik boşluqları
4. İnkişaf tendensiyası
5. Risk faktorları
6. Tövsiyələr (müəllim üçün)
7. Tövsiyələr (valideyn üçün)
8. Öyrənmə stili təxmini`;

        const analysis = await this.ai.completeJSON({
            prompt,
            schema: {
                overallLevel: '', strengths: [], weaknesses: [], knowledgeGaps: [],
                trend: '', riskFactors: [], teacherRecommendations: [],
                parentRecommendations: [], learningStyle: '',
                subjectProfiles: {}
            }
        });

        if (analysis.parsed) {
            // Upsert learning profile
            await query(`
                INSERT INTO student_learning_profiles (student_id, overall_level, strengths, weaknesses,
                    knowledge_gaps, recommended_actions, learning_style, subject_profiles, last_updated)
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
                ON CONFLICT (student_id) DO UPDATE SET
                    overall_level = $2, strengths = $3, weaknesses = $4,
                    knowledge_gaps = $5, recommended_actions = $6, learning_style = $7,
                    subject_profiles = $8, last_updated = NOW()
            `, [
                studentId,
                analysis.parsed.overallLevel || 'orta',
                JSON.stringify(analysis.parsed.strengths),
                JSON.stringify(analysis.parsed.weaknesses),
                JSON.stringify(analysis.parsed.knowledgeGaps),
                JSON.stringify([...analysis.parsed.teacherRecommendations, ...analysis.parsed.parentRecommendations]),
                analysis.parsed.learningStyle,
                JSON.stringify(analysis.parsed.subjectProfiles),
            ]);
        }

        return analysis.parsed;
    }

    // ─── Sinif Üzrə Analiz ─────────────────────────────
    async analyzeClass(classId) {
        const students = await query(`
            SELECT s.*, slp.overall_level, slp.strengths, slp.weaknesses
            FROM class_students cs
            JOIN students s ON cs.student_id = s.id
            LEFT JOIN student_learning_profiles slp ON slp.student_id = s.id
            WHERE cs.class_id = $1
        `, [classId]);

        const levelDistribution = { zeif: 0, orta: 0, yuksek: 0, ela: 0 };
        students.rows.forEach(s => {
            const level = s.overall_level || s.learning_level || 'orta';
            if (levelDistribution[level] !== undefined) levelDistribution[level]++;
        });

        const atRiskStudents = await query(`
            SELECT DISTINCT s.id, s.first_name, s.last_name, ra.alert_type, ra.severity
            FROM class_students cs
            JOIN students s ON cs.student_id = s.id
            JOIN risk_alerts ra ON ra.student_id = s.id AND ra.is_resolved = false
            WHERE cs.class_id = $1
        `, [classId]);

        const inclusiveStudents = students.rows.filter(s => s.is_inclusive);

        return {
            totalStudents: students.rows.length,
            levelDistribution,
            atRiskStudents: atRiskStudents.rows,
            inclusiveStudents: inclusiveStudents.map(s => ({
                name: `${s.first_name} ${s.last_name}`,
                type: s.inclusive_type,
            })),
            averageLevel: this._calculateAverageLevel(levelDistribution),
        };
    }

    // ─── Məktəb Üzrə Dashboard ─────────────────────────
    async getSchoolDashboard(schoolId) {
        const stats = await query(`
            SELECT 
                COUNT(DISTINCT s.id) as total_students,
                COUNT(DISTINCT CASE WHEN s.is_inclusive THEN s.id END) as inclusive_count,
                COUNT(DISTINCT t.id) as total_teachers,
                COUNT(DISTINCT c.id) as total_classes,
                (SELECT COUNT(*) FROM risk_alerts ra 
                 JOIN students st ON ra.student_id = st.id 
                 WHERE st.school_id = $1 AND ra.is_resolved = false) as active_alerts
            FROM students s
            FULL OUTER JOIN teachers t ON t.school_id = $1
            FULL OUTER JOIN classes c ON c.school_id = $1
            WHERE s.school_id = $1
        `, [schoolId]);

        const gradeDistribution = await query(`
            SELECT grade, COUNT(*) as count, 
                   AVG(CASE WHEN learning_level = 'zeif' THEN 1 WHEN learning_level = 'orta' THEN 2 ELSE 3 END) as avg_level
            FROM students WHERE school_id = $1 AND is_active = true
            GROUP BY grade ORDER BY grade
        `, [schoolId]);

        const recentResults = await query(`
            SELECT s.name_az as subject, AVG(ar.percentage) as avg_score, COUNT(ar.id) as test_count
            FROM assessment_results ar
            JOIN assessments a ON ar.assessment_id = a.id
            JOIN subjects s ON a.subject_id = s.id
            JOIN students st ON ar.student_id = st.id
            WHERE st.school_id = $1 AND ar.completed_at > NOW() - INTERVAL '30 days'
            GROUP BY s.name_az
        `, [schoolId]);

        return {
            overview: stats.rows[0],
            gradeDistribution: gradeDistribution.rows,
            subjectPerformance: recentResults.rows,
        };
    }

    // ─── Tapşırıq Trendi ────────────────────────────────
    async getProgressTrend(studentId, subjectCode = null, days = 90) {
        let sql = `
            SELECT spl.log_date, spl.log_type, spl.score, spl.max_score,
                   s.name_az as subject_name,
                   ROUND(spl.score / NULLIF(spl.max_score, 0) * 100, 1) as percentage
            FROM student_progress_logs spl
            LEFT JOIN subjects s ON spl.subject_id = s.id
            WHERE spl.student_id = $1 AND spl.log_date > NOW() - INTERVAL '${days} days'
        `;
        const params = [studentId];

        if (subjectCode) {
            sql += ` AND s.code = $2`;
            params.push(subjectCode);
        }
        sql += ` ORDER BY spl.log_date ASC`;

        const result = await query(sql, params);

        // Calculate trend line
        const dataPoints = result.rows.filter(r => r.percentage !== null);
        const trend = this._calculateTrend(dataPoints.map(d => parseFloat(d.percentage)));

        return {
            data: result.rows,
            trend: trend, // 'improving', 'declining', 'stable'
            average: dataPoints.reduce((sum, d) => sum + parseFloat(d.percentage), 0) / (dataPoints.length || 1),
        };
    }

    // ─── Risk Qrupları Aşkarlaması ──────────────────────
    async detectAtRiskStudents(schoolId) {
        // Academic decline: average dropped >15% in last 30 days
        const academicDecline = await query(`
            WITH recent AS (
                SELECT ar.student_id, AVG(ar.percentage) as recent_avg
                FROM assessment_results ar JOIN students s ON ar.student_id = s.id
                WHERE s.school_id = $1 AND ar.completed_at > NOW() - INTERVAL '30 days'
                GROUP BY ar.student_id
            ),
            previous AS (
                SELECT ar.student_id, AVG(ar.percentage) as prev_avg
                FROM assessment_results ar JOIN students s ON ar.student_id = s.id
                WHERE s.school_id = $1 AND ar.completed_at BETWEEN NOW() - INTERVAL '60 days' AND NOW() - INTERVAL '30 days'
                GROUP BY ar.student_id
            )
            SELECT r.student_id, r.recent_avg, p.prev_avg, (p.prev_avg - r.recent_avg) as decline
            FROM recent r JOIN previous p ON r.student_id = p.student_id
            WHERE p.prev_avg - r.recent_avg > 15
        `, [schoolId]);

        // Attendance issues: >5 absences in 30 days
        const attendanceIssues = await query(`
            SELECT a.student_id, COUNT(*) as absences,
                   s.first_name, s.last_name, s.grade
            FROM attendance a JOIN students s ON a.student_id = s.id
            WHERE s.school_id = $1 AND a.status = 'absent' AND a.attendance_date > NOW() - INTERVAL '30 days'
            GROUP BY a.student_id, s.first_name, s.last_name, s.grade
            HAVING COUNT(*) > 5
        `, [schoolId]);

        // Create alerts
        for (const student of academicDecline.rows) {
            await query(`
                INSERT INTO risk_alerts (student_id, alert_type, severity, description, recommended_action)
                VALUES ($1, 'academic_decline', $2, $3, $4)
            `, [
                student.student_id,
                student.decline > 25 ? 'critical' : 'high',
                `Son 30 gündə orta bal ${student.decline.toFixed(1)}% düşüb (${student.prev_avg.toFixed(1)}% → ${student.recent_avg.toFixed(1)}%)`,
                'Fərdi müdaxilə planı hazırlayın. Valideynlə görüş təyin edin.',
            ]);
        }

        return {
            academicDecline: academicDecline.rows,
            attendanceIssues: attendanceIssues.rows,
            totalAtRisk: academicDecline.rows.length + attendanceIssues.rows.length,
        };
    }

    // ─── İnklyuziv Şagird Modulu ────────────────────────
    async getInclusiveStudentPlan(studentId) {
        const student = await query('SELECT * FROM students WHERE id = $1', [studentId]);
        const s = student.rows[0];

        if (!s?.is_inclusive) return { message: 'Bu şagird inklyuziv kateqoriyada deyil' };

        const profile = await query('SELECT * FROM student_learning_profiles WHERE student_id = $1', [studentId]);

        const prompt = `İnklyuziv şagird üçün fərdi plan hazırla:

Şagird: ${s.first_name} ${s.last_name}
Sinif: ${s.grade}
İnklyuziv tipi: ${s.inclusive_type || 'Ümumi'}
Qeydlər: ${s.inclusive_notes || 'Yoxdur'}
Profil: ${JSON.stringify(profile.rows[0] || {})}

PLAN:
1. Davranış izləmə forması (həftəlik)
2. Uyğunlaşdırılmış tapşırıqlar (hər fənn üçün)
3. Sadələşdirilmiş izahlar
4. Vizual dəstək materialları
5. Sosial bacarıqlar inkişaf planı
6. Valideyn əməkdaşlıq planı
7. Terapevtik fəaliyyətlər`;

        return await this.ai.completeJSON({
            prompt,
            schema: {
                behaviorForm: { criteria: [], frequency: '', scale: '' },
                adaptedTasks: { subjects: {} },
                simplifiedExplanations: [],
                visualSupports: [],
                socialSkillsPlan: [],
                parentPlan: [],
                therapeuticActivities: []
            }
        });
    }

    // ─── Helpers ─────────────────────────────────────────
    _calculateTrend(scores) {
        if (scores.length < 3) return 'insufficient_data';
        const recent = scores.slice(-3).reduce((a, b) => a + b, 0) / 3;
        const earlier = scores.slice(0, 3).reduce((a, b) => a + b, 0) / 3;
        const diff = recent - earlier;
        if (diff > 5) return 'improving';
        if (diff < -5) return 'declining';
        return 'stable';
    }

    _calculateAverageLevel(dist) {
        const total = Object.values(dist).reduce((a, b) => a + b, 0);
        if (total === 0) return 'N/A';
        const weighted = (dist.zeif * 1 + dist.orta * 2 + dist.yuksek * 3 + dist.ela * 4) / total;
        if (weighted < 1.5) return 'zeif';
        if (weighted < 2.5) return 'orta';
        if (weighted < 3.5) return 'yuksek';
        return 'ela';
    }
}

module.exports = { StudentProgressAgent };
