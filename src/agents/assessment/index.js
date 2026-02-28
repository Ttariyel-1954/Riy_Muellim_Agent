// ============================================================
// Agent 2: Qiymətləndirmə və İmtahan (Assessment Agent)
// - MCQ, açıq sual, adaptiv test yaratma
// - IRT/CAT/MST modellər
// - Rubrik əsaslı AI qiymətləndirmə
// - Psixometrik analiz
// ============================================================
const { AIEngine } = require('../../core/ai_engine');
const { query, transaction } = require('../../../config/database');

class AssessmentAgent {
    constructor() {
        this.ai = new AIEngine();
    }

    // ─── Test Yaratma ────────────────────────────────────
    async generateTest({ teacherId, subjectCode, grade, topic, assessmentType = 'formative', config = {} }) {
        const standards = await this._getStandards(subjectCode, grade, config.standardCodes);

        const questionConfig = {
            mcqCount: config.mcqCount || 10,
            shortAnswerCount: config.shortAnswerCount || 3,
            essayCount: config.essayCount || 1,
            trueFalseCount: config.trueFalseCount || 5,
            matchingCount: config.matchingCount || 2,
            bloomDistribution: config.bloomDistribution || {
                'xatırlama': 20, 'anlama': 25, 'tətbiqetmə': 30, 'təhlil': 15, 'qiymətləndirmə': 5, 'yaratma': 5
            },
            dokRange: config.dokRange || [1, 3],
            difficultyRange: config.difficultyRange || [0.3, 0.8],
        };

        const prompt = this._buildTestPrompt(subjectCode, grade, topic, standards, questionConfig);

        const result = await this.ai.completeJSON({
            prompt,
            systemPrompt: `Sən təcrübəli testologsan. IRT (Item Response Theory) prinsiplərinə uyğun suallar hazırlayırsan. Hər sualın çətinlik (difficulty), fərqləndirmə (discrimination) parametrləri olmalıdır. Azərbaycan dilində yaz.`,
            schema: this._testSchema(),
        });

        if (!result.success || !result.parsed) {
            throw new Error('Test yaratma xətası: ' + (result.error || result.parseError));
        }

        // Save to database
        const saved = await this._saveAssessment(teacherId, subjectCode, grade, topic, assessmentType, result.parsed);
        return saved;
    }

    // ─── Adaptiv Test (CAT) ──────────────────────────────
    async initCATSession({ assessmentId, studentId }) {
        // Start with medium difficulty
        const initialTheta = 0.0;
        const initialSE = 1.0;

        // Get first question (medium difficulty)
        const question = await this._selectCATQuestion(assessmentId, initialTheta, []);

        return {
            sessionId: `cat_${Date.now()}`,
            assessmentId,
            studentId,
            currentTheta: initialTheta,
            currentSE: initialSE,
            questionsAnswered: 0,
            answeredIds: [],
            currentQuestion: question,
            maxQuestions: 30,
            stopCriteria: { minQuestions: 10, sePrecision: 0.3 },
        };
    }

    async processCATResponse({ session, questionId, response, isCorrect }) {
        // IRT 3PL model: P(θ) = c + (1-c) / (1 + exp(-a(θ-b)))
        const questionData = await query('SELECT * FROM questions WHERE id = $1', [questionId]);
        const q = questionData.rows[0];

        const a = q.irt_a || 1.0;  // discrimination
        const b = q.irt_b || 0.0;  // difficulty
        const c = q.irt_c || 0.25; // guessing

        // Update theta using Newton-Raphson
        const newTheta = this._updateTheta(session.currentTheta, a, b, c, isCorrect ? 1 : 0);
        const newSE = this._calculateSE(newTheta, session.answeredIds, a, b, c);

        session.currentTheta = newTheta;
        session.currentSE = newSE;
        session.questionsAnswered += 1;
        session.answeredIds.push(questionId);

        // Save response
        await query(`
            INSERT INTO student_responses (assessment_id, student_id, question_id, is_correct, 
                cat_theta_before, cat_theta_after, cat_se)
            VALUES ($1, $2, $3, $4, $5, $6, $7)
        `, [session.assessmentId, session.studentId, questionId, isCorrect,
            session.currentTheta, newTheta, newSE]);

        // Check stop criteria
        const shouldStop = session.questionsAnswered >= session.maxQuestions ||
            (session.questionsAnswered >= session.stopCriteria.minQuestions &&
                newSE <= session.stopCriteria.sePrecision);

        if (shouldStop) {
            return { finished: true, finalTheta: newTheta, finalSE: newSE, totalQuestions: session.questionsAnswered };
        }

        // Select next question
        const nextQuestion = await this._selectCATQuestion(session.assessmentId, newTheta, session.answeredIds);
        session.currentQuestion = nextQuestion;

        return { finished: false, session, nextQuestion };
    }

    // ─── AI Qiymətləndirmə (Açıq Cavablar) ──────────────
    async scoreOpenResponse({ questionId, studentResponse, rubric = null }) {
        const questionData = await query('SELECT * FROM questions WHERE id = $1', [questionId]);
        const q = questionData.rows[0];

        const scoringRubric = rubric || q.scoring_rubric || this._defaultRubric();

        const prompt = `Aşağıdakı açıq suala verilmiş cavabı qiymətləndir.

SUAL: ${q.question_text}

ŞAGİRDİN CAVABI: ${studentResponse}

QİYMƏTLƏNDİRMƏ RUBRİKASI:
${JSON.stringify(scoringRubric, null, 2)}

Hər kriteriya üzrə bal ver (0-dan maksimum bala qədər).
Ətraflı rəy (feedback) yaz - güclü tərəfləri və inkişaf sahələrini göstər.
Azərbaycan dilində cavab ver.`;

        const result = await this.ai.completeJSON({
            prompt,
            schema: {
                scores: { content: 0, coherence: 0, grammar: 0, depth: 0, creativity: 0 },
                totalScore: 0, maxScore: 0, percentage: 0,
                feedback: '', strengths: [], improvements: [], grade: ''
            }
        });

        return result.parsed;
    }

    // ─── Psixometrik Analiz ──────────────────────────────
    async analyzeAssessment(assessmentId) {
        // Get all responses
        const responses = await query(`
            SELECT q.id as question_id, q.question_text, q.difficulty, q.discrimination,
                   COUNT(sr.id) as total_responses,
                   SUM(CASE WHEN sr.is_correct THEN 1 ELSE 0 END) as correct_count,
                   AVG(sr.time_spent_seconds) as avg_time
            FROM questions q
            LEFT JOIN student_responses sr ON q.id = sr.question_id
            WHERE q.assessment_id = $1
            GROUP BY q.id
        `, [assessmentId]);

        const analysis = responses.rows.map(q => {
            const pValue = q.total_responses > 0 ? q.correct_count / q.total_responses : 0;
            return {
                questionId: q.question_id,
                questionText: q.question_text?.substring(0, 80),
                totalResponses: parseInt(q.total_responses),
                correctRate: parseFloat(pValue.toFixed(4)),
                avgTimeSeconds: parseFloat(q.avg_time || 0),
                difficulty: parseFloat(q.difficulty || pValue),
                discrimination: parseFloat(q.discrimination || 0),
                quality: this._classifyQuestionQuality(pValue, q.discrimination),
            };
        });

        // Class-level statistics
        const classStats = await query(`
            SELECT ar.student_id, ar.percentage, ar.mastery_level,
                   s.first_name, s.last_name, s.learning_level
            FROM assessment_results ar
            JOIN students s ON ar.student_id = s.id
            WHERE ar.assessment_id = $1
            ORDER BY ar.percentage DESC
        `, [assessmentId]);

        const scores = classStats.rows.map(r => parseFloat(r.percentage));
        const mean = scores.reduce((a, b) => a + b, 0) / scores.length || 0;
        const variance = scores.reduce((sum, s) => sum + Math.pow(s - mean, 2), 0) / scores.length || 0;
        const stdDev = Math.sqrt(variance);

        return {
            questions: analysis,
            classStatistics: {
                totalStudents: scores.length,
                mean: mean.toFixed(2),
                stdDev: stdDev.toFixed(2),
                median: this._median(scores).toFixed(2),
                min: Math.min(...scores, 0).toFixed(2),
                max: Math.max(...scores, 0).toFixed(2),
                masteryDistribution: this._countBy(classStats.rows, 'mastery_level'),
            },
            students: classStats.rows,
            recommendations: this._generateRecommendations(analysis, mean, stdDev),
        };
    }

    // ─── IRT Helper Methods ──────────────────────────────
    _updateTheta(theta, a, b, c, response) {
        // Newton-Raphson single step
        const p = c + (1 - c) / (1 + Math.exp(-a * (theta - b)));
        const pStar = (p - c) / (1 - c);
        const info = Math.pow(a, 2) * pStar * (1 - pStar) * Math.pow((1 - c), 2) / (p * (1 - p) || 0.001);
        const gradient = a * (response - p) * pStar / (p || 0.001);
        return theta + gradient / (info || 0.001);
    }

    _calculateSE(theta, answeredIds, a, b, c) {
        // Fisher information
        const p = c + (1 - c) / (1 + Math.exp(-a * (theta - b)));
        const info = Math.pow(a, 2) * Math.pow(p - c, 2) / (Math.pow(1 - c, 2) * p * (1 - p) || 0.001);
        return 1 / Math.sqrt(info * Math.max(answeredIds.length, 1));
    }

    async _selectCATQuestion(assessmentId, theta, answeredIds) {
        // Select question with difficulty closest to current theta (max info)
        let sql = `
            SELECT * FROM questions 
            WHERE assessment_id = $1 AND is_active = true
        `;
        const params = [assessmentId];

        if (answeredIds.length > 0) {
            sql += ` AND id != ALL($2)`;
            params.push(answeredIds);
        }
        sql += ` ORDER BY ABS(COALESCE(irt_b, difficulty, 0.5) - $${params.length + 1}) LIMIT 1`;
        params.push(theta);

        const result = await query(sql, params);
        return result.rows[0];
    }

    _classifyQuestionQuality(pValue, discrimination) {
        if (pValue < 0.1 || pValue > 0.95) return 'zəif';
        if (discrimination < 0.2) return 'orta';
        if (pValue >= 0.3 && pValue <= 0.7 && discrimination >= 0.3) return 'əla';
        return 'yaxşı';
    }

    _median(arr) {
        if (arr.length === 0) return 0;
        const sorted = [...arr].sort((a, b) => a - b);
        const mid = Math.floor(sorted.length / 2);
        return sorted.length % 2 !== 0 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
    }

    _countBy(arr, key) {
        return arr.reduce((acc, item) => {
            acc[item[key]] = (acc[item[key]] || 0) + 1;
            return acc;
        }, {});
    }

    _generateRecommendations(questions, mean, stdDev) {
        const recs = [];
        const hardQuestions = questions.filter(q => q.correctRate < 0.3);
        const easyQuestions = questions.filter(q => q.correctRate > 0.9);
        const poorDiscrimination = questions.filter(q => q.discrimination < 0.15);

        if (hardQuestions.length > 0)
            recs.push(`${hardQuestions.length} sual çox çətindir (p < 0.30). Mövzunu yenidən izah etmək lazımdır.`);
        if (easyQuestions.length > 0)
            recs.push(`${easyQuestions.length} sual çox asandır (p > 0.90). Daha çətin variantlarla əvəz edin.`);
        if (poorDiscrimination.length > 0)
            recs.push(`${poorDiscrimination.length} sualın fərqləndirmə gücü zəifdir. Sualları yenidən nəzərdən keçirin.`);
        if (mean < 50)
            recs.push('Sinifin orta balı aşağıdır. Mövzunun yenidən tədris edilməsi tövsiyə olunur.');
        if (stdDev > 25)
            recs.push('Ballar arasında böyük fərq var. Diferensiallaşdırılmış yanaşma lazımdır.');

        return recs;
    }

    _buildTestPrompt(subjectCode, grade, topic, standards, config) {
        return `${grade}-ci sinif ${subjectCode} fənni üçün test hazırla.

MÖVZU: ${topic}

STANDARTLAR:
${standards.map(s => `[${s.standard_code}] ${s.standard_text_az}`).join('\n')}

SUAL STRUKTURU:
- MCQ (çoxseçimli): ${config.mcqCount} sual (hər birinin 4 variantı)
- Qısa cavab: ${config.shortAnswerCount} sual
- Esse/açıq: ${config.essayCount} sual
- Doğru/Yanlış: ${config.trueFalseCount} sual
- Uyğunlaşdırma: ${config.matchingCount} sual

BLOOM PAYLANMASI: ${JSON.stringify(config.bloomDistribution)}
ÇƏTİNLİK ARALIĞI: ${config.difficultyRange[0]} - ${config.difficultyRange[1]}

HƏR SUAL ÜÇÜN:
- IRT parametrləri: difficulty (b), discrimination (a)  
- Bloom səviyyəsi
- DOK səviyyəsi
- Düzgün cavab və izah`;
    }

    _testSchema() {
        return {
            title: '', totalPoints: 0, duration: 0,
            questions: [{
                type: '', text: '', options: [], correctAnswer: '',
                explanation: '', points: 0, difficulty: 0, discrimination: 0,
                bloom: '', dok: 0, standardCode: ''
            }]
        };
    }

    _defaultRubric() {
        return {
            content: { max: 4, description: 'Məzmunun dolğunluğu və dəqiqliyi' },
            coherence: { max: 3, description: 'Fikrin ardıcıllığı və məntiqi bağlılıq' },
            grammar: { max: 2, description: 'Qrammatik düzgünlük' },
            depth: { max: 3, description: 'Təhlilin dərinliyi' },
            creativity: { max: 2, description: 'Orijinallıq və yaradıcılıq' },
        };
    }

    async _getStandards(subjectCode, grade, codes = []) {
        let sql = `SELECT cs.* FROM curriculum_standards cs JOIN subjects s ON cs.subject_id = s.id WHERE s.code = $1 AND cs.grade = $2`;
        const params = [subjectCode, grade];
        if (codes?.length > 0) { sql += ` AND cs.standard_code = ANY($3)`; params.push(codes); }
        const result = await query(sql, params);
        return result.rows;
    }

    async _saveAssessment(teacherId, subjectCode, grade, topic, type, testData) {
        return await transaction(async (client) => {
            const subj = await client.query('SELECT id FROM subjects WHERE code = $1', [subjectCode]);
            const subjectId = subj.rows[0]?.id;

            const assessment = await client.query(`
                INSERT INTO assessments (teacher_id, subject_id, title, assessment_type, grade, 
                    total_points, duration_minutes, ai_generated, status)
                VALUES ($1, $2, $3, $4, $5, $6, $7, true, 'draft') RETURNING *
            `, [teacherId, subjectId, testData.title, type, grade, testData.totalPoints, testData.duration]);

            const assessmentId = assessment.rows[0].id;

            for (let i = 0; i < (testData.questions || []).length; i++) {
                const q = testData.questions[i];
                await client.query(`
                    INSERT INTO questions (assessment_id, question_type, question_text, options, 
                        correct_answer, explanation, points, difficulty, discrimination, 
                        bloom_level, dok_level, position, ai_generated)
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, true)
                `, [assessmentId, q.type, q.text, JSON.stringify(q.options || []),
                    JSON.stringify(q.correctAnswer), q.explanation, q.points || 1,
                    q.difficulty, q.discrimination, q.bloom, q.dok || 2, i + 1]);
            }

            return assessment.rows[0];
        });
    }
}

module.exports = { AssessmentAgent };
