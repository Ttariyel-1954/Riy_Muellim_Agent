-- ============================================================
-- MÜƏLLİM AGENT - PostgreSQL Database Schema
-- ARTI 2026 - Azərbaycan Respublikası Təhsil İnstitutu
-- Author: Tariyel Talibov
-- ============================================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 1. CORE TABLES - İstifadəçilər və Təşkilat
-- ============================================================

CREATE TABLE schools (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    city VARCHAR(100),
    district VARCHAR(100),
    school_type VARCHAR(50) CHECK (school_type IN ('orta_mekteb', 'gimnaziya', 'lisey', 'ibtidai')),
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    director_name VARCHAR(150),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE teachers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID REFERENCES schools(id),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    patronymic VARCHAR(100),
    email VARCHAR(150) UNIQUE,
    phone VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL,
    mfa_secret VARCHAR(100),
    mfa_enabled BOOLEAN DEFAULT false,
    role VARCHAR(30) DEFAULT 'teacher' CHECK (role IN ('teacher', 'head_teacher', 'methodist', 'admin', 'super_admin')),
    specialization VARCHAR(100),
    experience_years INTEGER DEFAULT 0,
    qualification_category VARCHAR(50),
    avatar_url VARCHAR(500),
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID REFERENCES schools(id),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    patronymic VARCHAR(100),
    birth_date DATE,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female')),
    grade INTEGER NOT NULL CHECK (grade BETWEEN 1 AND 11),
    class_section VARCHAR(5),
    parent_name VARCHAR(200),
    parent_phone VARCHAR(20),
    parent_email VARCHAR(150),
    is_inclusive BOOLEAN DEFAULT false,
    inclusive_type VARCHAR(100),
    inclusive_notes TEXT,
    learning_level VARCHAR(20) DEFAULT 'orta' CHECK (learning_level IN ('zeif', 'orta', 'yuksek')),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE classes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID REFERENCES schools(id),
    grade INTEGER NOT NULL,
    section VARCHAR(5) NOT NULL,
    academic_year VARCHAR(10) NOT NULL,
    homeroom_teacher_id UUID REFERENCES teachers(id),
    student_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE class_students (
    class_id UUID REFERENCES classes(id) ON DELETE CASCADE,
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (class_id, student_id)
);

-- ============================================================
-- 2. FƏNN STANDARTLARI (Subject Standards) - Kurikulum
-- ============================================================

CREATE TABLE subjects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(20) UNIQUE NOT NULL,
    name_az VARCHAR(150) NOT NULL,
    name_en VARCHAR(150),
    subject_area VARCHAR(50) NOT NULL,
    description_az TEXT,
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE curriculum_standards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subject_id UUID REFERENCES subjects(id) ON DELETE CASCADE,
    grade INTEGER NOT NULL CHECK (grade BETWEEN 1 AND 11),
    standard_code VARCHAR(30) NOT NULL,
    standard_text_az TEXT NOT NULL,
    standard_text_en TEXT,
    content_area VARCHAR(100),
    sub_content_area VARCHAR(100),
    bloom_level VARCHAR(30) CHECK (bloom_level IN (
        'xatırlama', 'anlama', 'tətbiqetmə', 'təhlil', 'qiymətləndirmə', 'yaratma'
    )),
    dok_level INTEGER CHECK (dok_level BETWEEN 1 AND 4),
    taxonomy_level VARCHAR(50),
    keywords TEXT[],
    prerequisites UUID[],
    learning_outcomes TEXT[],
    is_core BOOLEAN DEFAULT true,
    semester INTEGER CHECK (semester IN (1, 2)),
    week_range INT4RANGE,
    hours_allocated NUMERIC(4,1),
    international_alignment JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(subject_id, grade, standard_code)
);

CREATE TABLE content_standards_detail (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    standard_id UUID REFERENCES curriculum_standards(id) ON DELETE CASCADE,
    sub_standard_code VARCHAR(30) NOT NULL,
    sub_standard_text_az TEXT NOT NULL,
    indicator_text_az TEXT,
    assessment_criteria TEXT[],
    example_activities TEXT[],
    resources TEXT[],
    cross_curricular_links JSONB DEFAULT '[]',
    differentiation_notes JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE international_frameworks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    framework_name VARCHAR(50) NOT NULL,
    framework_code VARCHAR(20) UNIQUE NOT NULL,
    description TEXT,
    version VARCHAR(20),
    country VARCHAR(50),
    url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE standard_framework_mapping (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    standard_id UUID REFERENCES curriculum_standards(id) ON DELETE CASCADE,
    framework_id UUID REFERENCES international_frameworks(id) ON DELETE CASCADE,
    framework_standard_code VARCHAR(50),
    alignment_level VARCHAR(20) CHECK (alignment_level IN ('full', 'partial', 'related')),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 3. DƏRS PLANLARI (Lesson Plans)
-- ============================================================

CREATE TABLE lesson_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    teacher_id UUID REFERENCES teachers(id),
    subject_id UUID REFERENCES subjects(id),
    class_id UUID REFERENCES classes(id),
    plan_type VARCHAR(20) NOT NULL CHECK (plan_type IN ('daily', 'weekly', 'monthly', 'unit')),
    title VARCHAR(300) NOT NULL,
    topic VARCHAR(300),
    lesson_date DATE,
    week_number INTEGER,
    month VARCHAR(20),
    duration_minutes INTEGER DEFAULT 45,
    
    -- Bloom / DOK / Taksonimiya
    bloom_levels TEXT[] DEFAULT '{}',
    dok_level INTEGER CHECK (dok_level BETWEEN 1 AND 4),
    
    -- Plan Content (JSONB for flexibility)
    objectives JSONB DEFAULT '[]',
    prerequisites TEXT,
    warm_up TEXT,
    main_activity TEXT,
    practice_activity TEXT,
    assessment_activity TEXT,
    closure TEXT,
    homework TEXT,
    
    -- Differentiation
    differentiation JSONB DEFAULT '{
        "zeif": "",
        "orta": "",
        "yuksek": ""
    }',
    inclusive_adaptations TEXT,
    
    -- Resources
    materials TEXT[],
    digital_resources TEXT[],
    
    -- Methods
    teaching_methods TEXT[] DEFAULT '{}',
    cross_curricular TEXT[],
    
    -- AI metadata
    ai_generated BOOLEAN DEFAULT false,
    ai_model VARCHAR(50),
    ai_prompt_used TEXT,
    
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'approved', 'active', 'archived')),
    approved_by UUID REFERENCES teachers(id),
    approved_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE lesson_plan_standards (
    lesson_plan_id UUID REFERENCES lesson_plans(id) ON DELETE CASCADE,
    standard_id UUID REFERENCES curriculum_standards(id) ON DELETE CASCADE,
    PRIMARY KEY (lesson_plan_id, standard_id)
);

-- ============================================================
-- 4. RESURLAR (Teaching Resources)
-- ============================================================

CREATE TABLE resources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    teacher_id UUID REFERENCES teachers(id),
    subject_id UUID REFERENCES subjects(id),
    title VARCHAR(300) NOT NULL,
    resource_type VARCHAR(30) NOT NULL CHECK (resource_type IN (
        'presentation', 'worksheet', 'project', 'homework',
        'video', 'audio', 'image', 'document', 'interactive', 'game'
    )),
    description TEXT,
    grade INTEGER,
    topic VARCHAR(200),
    file_path VARCHAR(500),
    file_size BIGINT,
    file_format VARCHAR(20),
    content_json JSONB,
    tags TEXT[] DEFAULT '{}',
    is_shared BOOLEAN DEFAULT false,
    download_count INTEGER DEFAULT 0,
    rating NUMERIC(3,2) DEFAULT 0,
    ai_generated BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE resource_standards (
    resource_id UUID REFERENCES resources(id) ON DELETE CASCADE,
    standard_id UUID REFERENCES curriculum_standards(id) ON DELETE CASCADE,
    PRIMARY KEY (resource_id, standard_id)
);

-- ============================================================
-- 5. QİYMƏTLƏNDİRMƏ (Assessment)
-- ============================================================

CREATE TABLE assessments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    teacher_id UUID REFERENCES teachers(id),
    subject_id UUID REFERENCES subjects(id),
    class_id UUID REFERENCES classes(id),
    title VARCHAR(300) NOT NULL,
    assessment_type VARCHAR(30) NOT NULL CHECK (assessment_type IN (
        'formative', 'summative', 'diagnostic', 'cat', 'mst', 'quiz', 'exam'
    )),
    description TEXT,
    grade INTEGER,
    total_points NUMERIC(6,2),
    duration_minutes INTEGER,
    is_adaptive BOOLEAN DEFAULT false,
    adaptive_config JSONB DEFAULT '{}',
    security_config JSONB DEFAULT '{
        "shuffle_questions": true,
        "shuffle_options": true,
        "time_limit": true,
        "browser_lockdown": false,
        "ip_restriction": false
    }',
    rubric JSONB DEFAULT '{}',
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'active', 'completed', 'archived')),
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    ai_generated BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE assessment_standards (
    assessment_id UUID REFERENCES assessments(id) ON DELETE CASCADE,
    standard_id UUID REFERENCES curriculum_standards(id) ON DELETE CASCADE,
    PRIMARY KEY (assessment_id, standard_id)
);

CREATE TABLE questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assessment_id UUID REFERENCES assessments(id) ON DELETE CASCADE,
    question_type VARCHAR(30) NOT NULL CHECK (question_type IN (
        'mcq', 'multiple_response', 'true_false', 'fill_blank',
        'short_answer', 'essay', 'matching', 'ordering', 'numeric'
    )),
    question_text TEXT NOT NULL,
    question_text_html TEXT,
    options JSONB DEFAULT '[]',
    correct_answer JSONB,
    explanation TEXT,
    points NUMERIC(5,2) DEFAULT 1,
    difficulty NUMERIC(4,3),
    discrimination NUMERIC(4,3),
    guessing NUMERIC(4,3) DEFAULT 0.25,
    
    -- IRT Parameters
    irt_a NUMERIC(6,4),
    irt_b NUMERIC(6,4),
    irt_c NUMERIC(6,4),
    
    bloom_level VARCHAR(30),
    dok_level INTEGER CHECK (dok_level BETWEEN 1 AND 4),
    standard_id UUID REFERENCES curriculum_standards(id),
    topic VARCHAR(200),
    tags TEXT[] DEFAULT '{}',
    
    -- Rubric for open questions
    scoring_rubric JSONB DEFAULT '{}',
    
    -- Statistics
    times_used INTEGER DEFAULT 0,
    avg_correct_rate NUMERIC(5,4),
    avg_time_seconds INTEGER,
    
    position INTEGER,
    is_active BOOLEAN DEFAULT true,
    ai_generated BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE student_responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assessment_id UUID REFERENCES assessments(id),
    student_id UUID REFERENCES students(id),
    question_id UUID REFERENCES questions(id),
    response_text TEXT,
    response_json JSONB,
    is_correct BOOLEAN,
    points_earned NUMERIC(5,2) DEFAULT 0,
    time_spent_seconds INTEGER,
    
    -- AI Scoring
    ai_score NUMERIC(5,2),
    ai_feedback TEXT,
    ai_rubric_scores JSONB DEFAULT '{}',
    ai_model_used VARCHAR(50),
    
    -- Manual override
    manual_score NUMERIC(5,2),
    manual_feedback TEXT,
    scored_by UUID REFERENCES teachers(id),
    
    -- CAT metadata
    cat_theta_before NUMERIC(6,4),
    cat_theta_after NUMERIC(6,4),
    cat_se NUMERIC(6,4),
    
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    scored_at TIMESTAMP
);

CREATE TABLE assessment_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assessment_id UUID REFERENCES assessments(id),
    student_id UUID REFERENCES students(id),
    total_score NUMERIC(6,2),
    max_score NUMERIC(6,2),
    percentage NUMERIC(5,2),
    grade_letter VARCHAR(5),
    mastery_level VARCHAR(20) CHECK (mastery_level IN ('zeif', 'orta', 'yuksek', 'ela')),
    theta_estimate NUMERIC(6,4),
    theta_se NUMERIC(6,4),
    time_total_seconds INTEGER,
    strengths TEXT[],
    weaknesses TEXT[],
    recommendations TEXT[],
    ai_analysis TEXT,
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 6. ŞAGİRD İNKİŞAF PROFİLİ (Student Progress)
-- ============================================================

CREATE TABLE student_learning_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID REFERENCES students(id) UNIQUE,
    overall_level VARCHAR(20) DEFAULT 'orta',
    strengths JSONB DEFAULT '[]',
    weaknesses JSONB DEFAULT '[]',
    knowledge_gaps JSONB DEFAULT '[]',
    recommended_actions JSONB DEFAULT '[]',
    learning_style VARCHAR(50),
    preferred_activities TEXT[],
    subject_profiles JSONB DEFAULT '{}',
    behavior_notes JSONB DEFAULT '[]',
    inclusive_plan JSONB DEFAULT '{}',
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE student_progress_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID REFERENCES students(id),
    subject_id UUID REFERENCES subjects(id),
    log_type VARCHAR(30) NOT NULL CHECK (log_type IN (
        'assessment', 'homework', 'classwork', 'project', 'behavior', 'attendance', 'note'
    )),
    title VARCHAR(300),
    score NUMERIC(5,2),
    max_score NUMERIC(5,2),
    notes TEXT,
    metadata JSONB DEFAULT '{}',
    recorded_by UUID REFERENCES teachers(id),
    log_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID REFERENCES students(id),
    class_id UUID REFERENCES classes(id),
    attendance_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('present', 'absent', 'late', 'excused')),
    notes TEXT,
    recorded_by UUID REFERENCES teachers(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(student_id, class_id, attendance_date)
);

CREATE TABLE risk_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID REFERENCES students(id),
    alert_type VARCHAR(30) NOT NULL CHECK (alert_type IN (
        'academic_decline', 'attendance_issue', 'behavior_concern',
        'knowledge_gap', 'at_risk', 'intervention_needed'
    )),
    severity VARCHAR(10) CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    description TEXT,
    recommended_action TEXT,
    is_resolved BOOLEAN DEFAULT false,
    resolved_by UUID REFERENCES teachers(id),
    resolved_at TIMESTAMP,
    resolved_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 7. KOMMUNİKASİYA (Communication)
-- ============================================================

CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID REFERENCES teachers(id),
    message_type VARCHAR(30) NOT NULL CHECK (message_type IN (
        'parent_report', 'parent_alert', 'parent_praise',
        'student_motivation', 'student_reminder', 'student_explanation',
        'teacher_collaboration', 'teacher_resource', 'system_notification'
    )),
    recipient_type VARCHAR(20) CHECK (recipient_type IN ('parent', 'student', 'teacher', 'class', 'school')),
    recipient_id UUID,
    subject VARCHAR(300),
    body TEXT NOT NULL,
    body_html TEXT,
    channel VARCHAR(20) CHECK (channel IN ('app', 'email', 'sms', 'whatsapp')),
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'delivered', 'read', 'failed')),
    scheduled_at TIMESTAMP,
    sent_at TIMESTAMP,
    ai_generated BOOLEAN DEFAULT false,
    template_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 8. MÜƏLLİMLƏRARASI ƏMƏKDAŞLIQ (Collaboration)
-- ============================================================

CREATE TABLE shared_resources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    resource_id UUID REFERENCES resources(id),
    shared_by UUID REFERENCES teachers(id),
    shared_with_school UUID REFERENCES schools(id),
    shared_with_subject UUID REFERENCES subjects(id),
    shared_with_grade INTEGER,
    access_type VARCHAR(20) DEFAULT 'view' CHECK (access_type IN ('view', 'copy', 'edit')),
    download_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE collaboration_groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    group_type VARCHAR(30) CHECK (group_type IN ('methodical_union', 'subject_group', 'project_team', 'school_team')),
    school_id UUID REFERENCES schools(id),
    created_by UUID REFERENCES teachers(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE collaboration_members (
    group_id UUID REFERENCES collaboration_groups(id) ON DELETE CASCADE,
    teacher_id UUID REFERENCES teachers(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'member' CHECK (role IN ('admin', 'moderator', 'member')),
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (group_id, teacher_id)
);

-- ============================================================
-- 9. SƏNƏDLƏR VƏ RAPORTLAR (Documents & Reports)
-- ============================================================

CREATE TABLE generated_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    teacher_id UUID REFERENCES teachers(id),
    doc_type VARCHAR(30) NOT NULL CHECK (doc_type IN (
        'journal', 'monthly_plan', 'activity_report', 'parent_letter',
        'analysis_report', 'grade_sheet', 'attendance_report', 'custom'
    )),
    title VARCHAR(300) NOT NULL,
    content_json JSONB,
    file_path VARCHAR(500),
    file_format VARCHAR(10),
    template_used VARCHAR(100),
    ai_generated BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 10. AUDIT VƏ TƏHLÜKƏSİZLİK (Audit & Security)
-- ============================================================

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    user_role VARCHAR(30),
    action VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50),
    entity_id UUID,
    details JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    teacher_id UUID REFERENCES teachers(id),
    token_hash VARCHAR(255) NOT NULL,
    ip_address INET,
    user_agent TEXT,
    expires_at TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 11. AI AGENT LOGS
-- ============================================================

CREATE TABLE ai_agent_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    teacher_id UUID REFERENCES teachers(id),
    agent_type VARCHAR(50) NOT NULL CHECK (agent_type IN (
        'lesson_planning', 'assessment', 'pedagogical',
        'digital_assistant', 'student_progress', 'communication'
    )),
    sub_agent VARCHAR(50),
    input_prompt TEXT,
    output_response TEXT,
    model_used VARCHAR(50),
    tokens_input INTEGER,
    tokens_output INTEGER,
    latency_ms INTEGER,
    status VARCHAR(20) DEFAULT 'success',
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_teachers_school ON teachers(school_id);
CREATE INDEX idx_teachers_email ON teachers(email);
CREATE INDEX idx_students_school ON students(school_id);
CREATE INDEX idx_students_grade ON students(grade, class_section);
CREATE INDEX idx_curriculum_subject_grade ON curriculum_standards(subject_id, grade);
CREATE INDEX idx_curriculum_bloom ON curriculum_standards(bloom_level);
CREATE INDEX idx_curriculum_dok ON curriculum_standards(dok_level);
CREATE INDEX idx_lesson_plans_teacher ON lesson_plans(teacher_id);
CREATE INDEX idx_lesson_plans_date ON lesson_plans(lesson_date);
CREATE INDEX idx_lesson_plans_subject ON lesson_plans(subject_id);
CREATE INDEX idx_assessments_teacher ON assessments(teacher_id);
CREATE INDEX idx_assessments_type ON assessments(assessment_type);
CREATE INDEX idx_questions_assessment ON questions(assessment_id);
CREATE INDEX idx_questions_difficulty ON questions(difficulty);
CREATE INDEX idx_questions_irt ON questions(irt_a, irt_b, irt_c);
CREATE INDEX idx_student_responses_assessment ON student_responses(assessment_id, student_id);
CREATE INDEX idx_progress_logs_student ON student_progress_logs(student_id, subject_id);
CREATE INDEX idx_attendance_student_date ON attendance(student_id, attendance_date);
CREATE INDEX idx_risk_alerts_student ON risk_alerts(student_id, is_resolved);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id, created_at);
CREATE INDEX idx_ai_logs_teacher ON ai_agent_logs(teacher_id, created_at);

-- Full text search on standards
CREATE INDEX idx_standards_text_search ON curriculum_standards 
    USING gin(to_tsvector('simple', standard_text_az));

-- JSONB indexes
CREATE INDEX idx_lesson_plans_objectives ON lesson_plans USING gin(objectives);
CREATE INDEX idx_questions_options ON questions USING gin(options);
CREATE INDEX idx_student_profiles_gaps ON student_learning_profiles USING gin(knowledge_gaps);

-- ============================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_teachers_updated BEFORE UPDATE ON teachers
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();
CREATE TRIGGER trg_students_updated BEFORE UPDATE ON students
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();
CREATE TRIGGER trg_curriculum_updated BEFORE UPDATE ON curriculum_standards
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();
CREATE TRIGGER trg_lesson_plans_updated BEFORE UPDATE ON lesson_plans
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();
CREATE TRIGGER trg_assessments_updated BEFORE UPDATE ON assessments
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();
CREATE TRIGGER trg_questions_updated BEFORE UPDATE ON questions
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();
CREATE TRIGGER trg_resources_updated BEFORE UPDATE ON resources
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- Auto risk detection function
CREATE OR REPLACE FUNCTION check_student_risk()
RETURNS TRIGGER AS $$
DECLARE
    absent_count INTEGER;
    low_scores INTEGER;
BEGIN
    -- Check attendance (>5 absences in 30 days)
    SELECT COUNT(*) INTO absent_count
    FROM attendance
    WHERE student_id = NEW.student_id
      AND status = 'absent'
      AND attendance_date > CURRENT_DATE - INTERVAL '30 days';
    
    IF absent_count > 5 THEN
        INSERT INTO risk_alerts (student_id, alert_type, severity, description, recommended_action)
        VALUES (NEW.student_id, 'attendance_issue', 'high',
                'Şagird son 30 gündə ' || absent_count || ' dəfə dərsə gəlməyib.',
                'Valideynlə əlaqə saxlayın. Davamiyyət planı hazırlayın.')
        ON CONFLICT DO NOTHING;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_risk_attendance 
    AFTER INSERT ON attendance
    FOR EACH ROW EXECUTE FUNCTION check_student_risk();

-- View: Student dashboard summary
CREATE OR REPLACE VIEW v_student_dashboard AS
SELECT 
    s.id AS student_id,
    s.first_name || ' ' || s.last_name AS full_name,
    s.grade,
    s.class_section,
    s.learning_level,
    s.is_inclusive,
    sch.name AS school_name,
    slp.overall_level,
    slp.strengths,
    slp.weaknesses,
    slp.knowledge_gaps,
    (SELECT COUNT(*) FROM attendance a WHERE a.student_id = s.id AND a.status = 'absent' 
     AND a.attendance_date > CURRENT_DATE - INTERVAL '30 days') AS absences_30d,
    (SELECT AVG(ar.percentage) FROM assessment_results ar WHERE ar.student_id = s.id
     AND ar.completed_at > CURRENT_DATE - INTERVAL '90 days') AS avg_score_90d,
    (SELECT COUNT(*) FROM risk_alerts ra WHERE ra.student_id = s.id AND ra.is_resolved = false) AS active_alerts
FROM students s
LEFT JOIN schools sch ON s.school_id = sch.id
LEFT JOIN student_learning_profiles slp ON slp.student_id = s.id
WHERE s.is_active = true;

-- View: Teacher workload
CREATE OR REPLACE VIEW v_teacher_workload AS
SELECT
    t.id AS teacher_id,
    t.first_name || ' ' || t.last_name AS full_name,
    t.specialization,
    sch.name AS school_name,
    (SELECT COUNT(*) FROM lesson_plans lp WHERE lp.teacher_id = t.id AND lp.status = 'active') AS active_plans,
    (SELECT COUNT(*) FROM assessments a WHERE a.teacher_id = t.id AND a.status IN ('published', 'active')) AS active_assessments,
    (SELECT COUNT(*) FROM resources r WHERE r.teacher_id = t.id) AS total_resources,
    (SELECT COUNT(*) FROM messages m WHERE m.sender_id = t.id AND m.sent_at > CURRENT_DATE - INTERVAL '7 days') AS messages_7d
FROM teachers t
LEFT JOIN schools sch ON t.school_id = sch.id
WHERE t.is_active = true;

COMMENT ON TABLE curriculum_standards IS 'Azərbaycan Kurikulum Standartları - bütün fənlər və siniflər üçün';
COMMENT ON TABLE questions IS 'Sual bankı - IRT parametrləri ilə birlikdə';
COMMENT ON TABLE student_learning_profiles IS 'Hər şagirdin öyrənmə profili - güclü/zəif tərəflər';
COMMENT ON TABLE risk_alerts IS 'Şagirdlər üçün avtomatik risk xəbərdarlıqları';
