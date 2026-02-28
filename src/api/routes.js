// ============================================================
// API Routes - Müəllim Agent
// RESTful API for all 6 agents
// ============================================================
const express = require('express');
const router = express.Router();
const { authenticate, authorize, login, setupMFA, enableMFA, auditMiddleware } = require('../middleware/auth');

// Import agents
const { LessonPlanningAgent } = require('../agents/lesson_planning');
const { AssessmentAgent } = require('../agents/assessment');
const { PedagogicalAgent } = require('../agents/pedagogical');
const { DigitalAssistantAgent } = require('../agents/digital_assistant');
const { StudentProgressAgent } = require('../agents/student_progress');
const { CommunicationAgent } = require('../agents/communication');

// Initialize agents
const lessonAgent = new LessonPlanningAgent();
const assessmentAgent = new AssessmentAgent();
const pedagogicalAgent = new PedagogicalAgent();
const digitalAgent = new DigitalAssistantAgent();
const studentAgent = new StudentProgressAgent();
const communicationAgent = new CommunicationAgent();

// ═══════════════════════════════════════════════
// AUTH ROUTES
// ═══════════════════════════════════════════════
router.post('/auth/login', login);
router.post('/auth/mfa/setup', authenticate, setupMFA);
router.post('/auth/mfa/enable', authenticate, enableMFA);

// ═══════════════════════════════════════════════
// 1. LESSON PLANNING ROUTES
// ═══════════════════════════════════════════════
router.post('/lessons/generate', authenticate, async (req, res) => {
    try {
        const result = await lessonAgent.generateLessonPlan({
            teacherId: req.user.id,
            ...req.body
        });
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/lessons/weekly', authenticate, async (req, res) => {
    try {
        const result = await lessonAgent.generateWeeklyPlan({ teacherId: req.user.id, ...req.body });
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/lessons/worksheet', authenticate, async (req, res) => {
    try {
        const result = await lessonAgent.generateWorksheet(req.body);
        res.json({ success: true, data: result.parsed });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/lessons/project', authenticate, async (req, res) => {
    try {
        const result = await lessonAgent.generateProjectTask(req.body);
        res.json({ success: true, data: result.parsed });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/lessons/homework', authenticate, async (req, res) => {
    try {
        const result = await lessonAgent.generateHomework(req.body);
        res.json({ success: true, data: result.parsed });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/lessons/differentiate', authenticate, async (req, res) => {
    try {
        const result = await lessonAgent.generateDifferentiatedPlan(req.body);
        res.json({ success: true, data: result.parsed });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// ═══════════════════════════════════════════════
// 2. ASSESSMENT ROUTES
// ═══════════════════════════════════════════════
router.post('/assessments/generate', authenticate, async (req, res) => {
    try {
        const result = await assessmentAgent.generateTest({ teacherId: req.user.id, ...req.body });
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/assessments/cat/start', authenticate, async (req, res) => {
    try {
        const session = await assessmentAgent.initCATSession(req.body);
        res.json({ success: true, data: session });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/assessments/cat/respond', authenticate, async (req, res) => {
    try {
        const result = await assessmentAgent.processCATResponse(req.body);
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/assessments/score-open', authenticate, async (req, res) => {
    try {
        const result = await assessmentAgent.scoreOpenResponse(req.body);
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.get('/assessments/:id/analyze', authenticate, async (req, res) => {
    try {
        const analysis = await assessmentAgent.analyzeAssessment(req.params.id);
        res.json({ success: true, data: analysis });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// ═══════════════════════════════════════════════
// 3. PEDAGOGICAL ROUTES
// ═══════════════════════════════════════════════
router.post('/pedagogy/suggest-method', authenticate, async (req, res) => {
    try {
        const result = await pedagogicalAgent.suggestMethod(req.body);
        res.json({ success: true, data: result.parsed });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/pedagogy/formative-strategies', authenticate, async (req, res) => {
    try {
        const result = await pedagogicalAgent.getFormativeStrategies(req.body);
        res.json({ success: true, data: result.parsed });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/pedagogy/experiment', authenticate, async (req, res) => {
    try {
        const result = await pedagogicalAgent.generateExperimentScenario(req.body);
        res.json({ success: true, data: result.parsed });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/pedagogy/warmup', authenticate, async (req, res) => {
    try {
        const result = await pedagogicalAgent.generateWarmUpActivities(req.body);
        res.json({ success: true, data: result.parsed });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/pedagogy/real-world', authenticate, async (req, res) => {
    try {
        const result = await pedagogicalAgent.generateRealWorldExamples(req.body);
        res.json({ success: true, data: result.parsed });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/pedagogy/gamification', authenticate, async (req, res) => {
    try {
        const result = await pedagogicalAgent.generateGamification(req.body);
        res.json({ success: true, data: result.parsed });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/pedagogy/debate', authenticate, async (req, res) => {
    try {
        const result = await pedagogicalAgent.generateDebateTopic(req.body);
        res.json({ success: true, data: result.parsed });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/pedagogy/weak-student-strategies', authenticate, async (req, res) => {
    try {
        const result = await pedagogicalAgent.getWeakStudentStrategies(req.body);
        res.json({ success: true, data: result.parsed });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// ═══════════════════════════════════════════════
// 4. DIGITAL ASSISTANT ROUTES
// ═══════════════════════════════════════════════
router.post('/documents/journal', authenticate, async (req, res) => {
    try {
        const result = await digitalAgent.generateJournalEntry({ teacherId: req.user.id, ...req.body });
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/documents/monthly-plan', authenticate, async (req, res) => {
    try {
        const result = await digitalAgent.generateMonthlyPlan({ teacherId: req.user.id, ...req.body });
        res.json({ success: true, data: result.parsed });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/documents/activity-report', authenticate, async (req, res) => {
    try {
        const result = await digitalAgent.generateActivityReport({ teacherId: req.user.id, ...req.body });
        res.json({ success: true, data: result.parsed });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/documents/presentation', authenticate, async (req, res) => {
    try {
        const result = await digitalAgent.generatePresentation(req.body);
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/documents/word', authenticate, async (req, res) => {
    try {
        const result = await digitalAgent.generateWordDocument(req.body);
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/documents/excel', authenticate, async (req, res) => {
    try {
        const result = await digitalAgent.generateExcelReport(req.body);
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/documents/edit-text', authenticate, async (req, res) => {
    try {
        const result = await digitalAgent.editText(req.body);
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/documents/parent-message', authenticate, async (req, res) => {
    try {
        const result = await digitalAgent.generateParentMessage(req.body);
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// LMS Integration
router.post('/lms/google-classroom', authenticate, async (req, res) => {
    try {
        const result = await digitalAgent.syncToGoogleClassroom(req.body);
        res.json(result);
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/lms/teams', authenticate, async (req, res) => {
    try {
        const result = await digitalAgent.syncToMicrosoftTeams(req.body);
        res.json(result);
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/lms/moodle', authenticate, async (req, res) => {
    try {
        const result = await digitalAgent.syncToMoodle(req.body);
        res.json(result);
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// ═══════════════════════════════════════════════
// 5. STUDENT PROGRESS ROUTES
// ═══════════════════════════════════════════════
router.post('/students/:id/update-profile', authenticate, async (req, res) => {
    try {
        const profile = await studentAgent.updateLearningProfile(req.params.id);
        res.json({ success: true, data: profile });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.get('/classes/:id/analyze', authenticate, async (req, res) => {
    try {
        const analysis = await studentAgent.analyzeClass(req.params.id);
        res.json({ success: true, data: analysis });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.get('/schools/:id/dashboard', authenticate, async (req, res) => {
    try {
        const dashboard = await studentAgent.getSchoolDashboard(req.params.id);
        res.json({ success: true, data: dashboard });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.get('/students/:id/trend', authenticate, async (req, res) => {
    try {
        const trend = await studentAgent.getProgressTrend(req.params.id, req.query.subject, req.query.days);
        res.json({ success: true, data: trend });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/schools/:id/detect-risks', authenticate, authorize('admin', 'super_admin', 'head_teacher'), async (req, res) => {
    try {
        const risks = await studentAgent.detectAtRiskStudents(req.params.id);
        res.json({ success: true, data: risks });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.get('/students/:id/inclusive-plan', authenticate, async (req, res) => {
    try {
        const plan = await studentAgent.getInclusiveStudentPlan(req.params.id);
        res.json({ success: true, data: plan.parsed || plan });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// ═══════════════════════════════════════════════
// 6. COMMUNICATION ROUTES
// ═══════════════════════════════════════════════
router.post('/communication/parent-report', authenticate, async (req, res) => {
    try {
        const result = await communicationAgent.generateWeeklyParentReport(req.body);
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/communication/alert', authenticate, async (req, res) => {
    try {
        const result = await communicationAgent.generateAlertMessage(req.body);
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/communication/praise', authenticate, async (req, res) => {
    try {
        const result = await communicationAgent.generatePraiseMessage(req.body);
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/communication/student-motivation', authenticate, async (req, res) => {
    try {
        const result = await communicationAgent.generateStudentMotivation(req.body);
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/communication/homework-reminder', authenticate, async (req, res) => {
    try {
        const result = await communicationAgent.generateHomeworkReminder(req.body);
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/communication/collaboration', authenticate, async (req, res) => {
    try {
        const result = await communicationAgent.generateCollaborationContent(req.body);
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/communication/bulk', authenticate, async (req, res) => {
    try {
        const result = await communicationAgent.sendBulkMessages({ teacherId: req.user.id, ...req.body });
        res.json({ success: true, data: result });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.get('/communication/templates', authenticate, (req, res) => {
    res.json({ success: true, data: communicationAgent.getTemplates() });
});

// ═══════════════════════════════════════════════
// STANDARDS & CURRICULUM ROUTES
// ═══════════════════════════════════════════════
const { query: dbQuery } = require('../../config/database');

router.get('/subjects', async (req, res) => {
    try {
        const result = await dbQuery('SELECT * FROM subjects WHERE is_active = true ORDER BY sort_order');
        res.json({ success: true, data: result.rows });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.get('/standards/:subjectCode/:grade', async (req, res) => {
    try {
        const result = await dbQuery(`
            SELECT cs.*, s.name_az as subject_name
            FROM curriculum_standards cs JOIN subjects s ON cs.subject_id = s.id
            WHERE s.code = $1 AND cs.grade = $2
            ORDER BY cs.standard_code
        `, [req.params.subjectCode, req.params.grade]);
        res.json({ success: true, data: result.rows });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.get('/frameworks', async (req, res) => {
    try {
        const result = await dbQuery('SELECT * FROM international_frameworks ORDER BY framework_name');
        res.json({ success: true, data: result.rows });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// ─── Health Check ───────────────────────────────────────
router.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        service: 'Müəllim Agent API',
        version: '1.0.0',
        timestamp: new Date().toISOString(),
        agents: ['lesson_planning', 'assessment', 'pedagogical', 'digital_assistant', 'student_progress', 'communication']
    });
});

module.exports = router;
