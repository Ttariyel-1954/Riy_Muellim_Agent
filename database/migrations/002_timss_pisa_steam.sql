-- ============================================================
-- TIMSS / PISA / STEAM Framework Tables
-- Migration 002 — Beynəlxalq Standart İnteqrasiyası
-- ARTI 2026
-- ============================================================

-- TIMSS çərçivə cədvəli
CREATE TABLE IF NOT EXISTS timss_framework (
    id SERIAL PRIMARY KEY,
    grade_level VARCHAR(10),
    content_domain VARCHAR(50),
    cognitive_domain VARCHAR(20),
    description_az TEXT,
    sample_task_az TEXT,
    keywords TEXT[]
);

-- PISA çərçivə cədvəli
CREATE TABLE IF NOT EXISTS pisa_framework (
    id SERIAL PRIMARY KEY,
    process VARCHAR(50),
    context VARCHAR(30),
    proficiency_level INT,
    description_az TEXT,
    sample_task_az TEXT,
    grade_relevance INT[]
);

-- Beynəlxalq yaxşı təcrübələr cədvəli
CREATE TABLE IF NOT EXISTS international_practices (
    id SERIAL PRIMARY KEY,
    country VARCHAR(50),
    approach_name VARCHAR(100),
    approach_name_az VARCHAR(100),
    description_az TEXT,
    applicable_grades INT[],
    math_topics TEXT[],
    steam_component CHAR(1),
    implementation_steps_az TEXT
);

-- STEAM fəaliyyətlər kitabxanası
CREATE TABLE IF NOT EXISTS steam_activities (
    id SERIAL PRIMARY KEY,
    activity_name_az VARCHAR(200),
    grade_min INT,
    grade_max INT,
    steam_components CHAR(1)[],
    math_topic VARCHAR(100),
    duration_minutes INT,
    materials_az TEXT,
    procedure_az TEXT,
    learning_outcomes_az TEXT,
    timss_cognitive_domain VARCHAR(20)
);

-- İndekslər
CREATE INDEX IF NOT EXISTS idx_timss_grade ON timss_framework(grade_level);
CREATE INDEX IF NOT EXISTS idx_timss_domain ON timss_framework(content_domain, cognitive_domain);
CREATE INDEX IF NOT EXISTS idx_pisa_process ON pisa_framework(process, proficiency_level);
CREATE INDEX IF NOT EXISTS idx_steam_grade ON steam_activities(grade_min, grade_max);
CREATE INDEX IF NOT EXISTS idx_steam_topic ON steam_activities(math_topic);
