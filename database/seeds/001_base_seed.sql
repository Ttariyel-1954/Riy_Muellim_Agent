-- ============================================================
-- SEED DATA: Fənn Standartları
-- Azərbaycan Kurikulumu - Orta Məktəb (5-9 sinif)
-- ============================================================

-- ===== FƏNLƏR =====
INSERT INTO subjects (code, name_az, name_en, subject_area, description_az, sort_order) VALUES
('AZ_DIL', 'Azərbaycan dili', 'Azerbaijani Language', 'dil_edebiyyat', 'Azərbaycan dilinin qrammatikası, orfoqrafiyası, nitq inkişafı', 1),
('AZ_ED', 'Azərbaycan ədəbiyyatı', 'Azerbaijani Literature', 'dil_edebiyyat', 'Azərbaycan və dünya ədəbiyyatının öyrənilməsi', 2),
('RUS_DIL', 'Rus dili', 'Russian Language', 'dil_edebiyyat', 'Rus dilinin öyrənilməsi (ikinci dil kimi)', 3),
('ING_DIL', 'İngilis dili', 'English Language', 'dil_edebiyyat', 'İngilis dilinin öyrənilməsi (xarici dil)', 4),
('RIYAZ', 'Riyaziyyat', 'Mathematics', 'riyaziyyat', 'Riyaziyyatın əsas sahələri: cəbr, həndəsə, statistika', 5),
('INFORM', 'İnformatika', 'Informatics', 'texnologiya', 'Kompüter elmləri və proqramlaşdırma əsasları', 6),
('FIZIKA', 'Fizika', 'Physics', 'tebiet_elmleri', 'Mexanika, termodinamika, elektrik, optika', 7),
('KIMYA', 'Kimya', 'Chemistry', 'tebiet_elmleri', 'Üzvi və qeyri-üzvi kimya', 8),
('BIOL', 'Biologiya', 'Biology', 'tebiet_elmleri', 'Canlılar aləmi, ekologiya, insan anatomiyası', 9),
('TARIX', 'Tarix', 'History', 'ictimai_elmlər', 'Azərbaycan və dünya tarixi', 10),
('COGRAFIYA', 'Coğrafiya', 'Geography', 'ictimai_elmlər', 'Fiziki və iqtisadi coğrafiya', 11),
('MUSIQI', 'Musiqi', 'Music', 'incesenet', 'Musiqi nəzəriyyəsi və icra', 12),
('RESM', 'Təsviri incəsənət', 'Visual Arts', 'incesenet', 'Rəsm, heykəltəraşlıq, dizayn', 13),
('TEXNOL', 'Texnologiya', 'Technology', 'texnologiya', 'Əmək təlimi və texnologiya', 14),
('BEDEN', 'Bədən tərbiyəsi', 'Physical Education', 'saglamliq', 'Fiziki inkişaf və idman', 15),
('HAYAT', 'Həyat bilgisi', 'Life Skills', 'ictimai_elmlər', 'Həyat bacarıqları (1-4 sinif)', 16);

-- ===== RİYAZİYYAT STANDARTLARI (5-9 sinif) =====

-- 5-ci sinif Riyaziyyat
INSERT INTO curriculum_standards (subject_id, grade, standard_code, standard_text_az, content_area, sub_content_area, bloom_level, dok_level, learning_outcomes, is_core, semester, hours_allocated)
SELECT s.id, 5, v.code, v.text_az, v.content_area, v.sub_content, v.bloom, v.dok, v.outcomes, true, v.sem, v.hours
FROM subjects s, (VALUES
    ('R5.1.1', 'Natural ədədlər üzərində əməlləri yerinə yetirir və ədəd sistemlərini anlayır', 'ededler', 'natural_ededler', 'tətbiqetmə', 2, ARRAY['Natural ədədləri oxuyur və yazır','Ədədlər üzərində dörd əməl aparır'], 1, 8),
    ('R5.1.2', 'Kəsr anlayışını başa düşür, adi və onluq kəsrlər üzərində əməllər aparır', 'ededler', 'kesrler', 'anlama', 2, ARRAY['Adi kəsrləri müqayisə edir','Onluq kəsrlərlə hesablama aparır'], 1, 10),
    ('R5.1.3', 'Bölünmə əlamətlərini bilir və tətbiq edir', 'ededler', 'bolunme', 'tətbiqetmə', 2, ARRAY['2, 3, 5, 9, 10-a bölünmə əlamətlərini tətbiq edir'], 1, 6),
    ('R5.2.1', 'Sadə həndəsi fiqurların xassələrini bilir', 'hendese', 'fiqurlar', 'anlama', 2, ARRAY['Üçbucaq və dördbucaqlıların xassələrini izah edir'], 1, 8),
    ('R5.2.2', 'Perimetr və sahə hesablayır', 'hendese', 'olcu', 'tətbiqetmə', 2, ARRAY['Düzbucaqlının sahəsini hesablayır','Perimetr tapır'], 2, 8),
    ('R5.3.1', 'Cədvəl və diaqramları oxuyur və qurur', 'statistika', 'verilenlerin_teqdimati', 'təhlil', 3, ARRAY['Sütunlu diaqram qurur','Verilənləri cədvəldə təqdim edir'], 2, 6),
    ('R5.4.1', 'Tənlik və bərabərsizlik anlayışını bilir', 'cebr', 'tenliklər', 'anlama', 2, ARRAY['Sadə tənlikləri həll edir'], 2, 8),
    ('R5.4.2', 'Düsturla hesablama aparır', 'cebr', 'dusurlar', 'tətbiqetmə', 2, ARRAY['Verilmiş düsturda əvəzetmə aparır'], 2, 6)
) AS v(code, text_az, content_area, sub_content, bloom, dok, outcomes, sem, hours)
WHERE s.code = 'RIYAZ';

-- 6-cı sinif Riyaziyyat
INSERT INTO curriculum_standards (subject_id, grade, standard_code, standard_text_az, content_area, sub_content_area, bloom_level, dok_level, learning_outcomes, is_core, semester, hours_allocated)
SELECT s.id, 6, v.code, v.text_az, v.content_area, v.sub_content, v.bloom, v.dok, v.outcomes, true, v.sem, v.hours
FROM subjects s, (VALUES
    ('R6.1.1', 'Tam ədədlər (mənfi ədədlər daxil) üzərində əməllər aparır', 'ededler', 'tam_ededler', 'tətbiqetmə', 2, ARRAY['Mənfi ədədləri ədəd oxu üzərində göstərir','Tam ədədlərlə əməllər aparır'], 1, 10),
    ('R6.1.2', 'Rasional ədədlər anlayışını bilir', 'ededler', 'rasional_ededler', 'anlama', 2, ARRAY['Rasional ədədləri müqayisə edir'], 1, 8),
    ('R6.1.3', 'Nisbət və proporsiya məsələlərini həll edir', 'ededler', 'nisbet', 'tətbiqetmə', 3, ARRAY['Düz və tərs mütənasiblik məsələlərini həll edir'], 1, 8),
    ('R6.2.1', 'Bucaq və bucaq ölçülərini bilir', 'hendese', 'bucaqlar', 'anlama', 2, ARRAY['Bucaqları ölçür və təsnif edir'], 2, 6),
    ('R6.2.2', 'Simmetriya və çevirmələri başa düşür', 'hendese', 'simmetriya', 'anlama', 2, ARRAY['Ox simmetriyasını tətbiq edir'], 2, 6),
    ('R6.3.1', 'Faiz anlayışını bilir və tətbiq edir', 'ededler', 'faiz', 'tətbiqetmə', 3, ARRAY['Faiz hesablamaları aparır','Real həyat məsələlərində faiz tətbiq edir'], 2, 8),
    ('R6.4.1', 'Birməchullu tənlikləri həll edir', 'cebr', 'tenliklər', 'tətbiqetmə', 2, ARRAY['ax+b=c tipli tənlikləri həll edir'], 2, 10),
    ('R6.4.2', 'Koordinat müstəvisini bilir', 'cebr', 'koordinat', 'anlama', 2, ARRAY['Nöqtələri koordinat müstəvisində göstərir'], 2, 6)
) AS v(code, text_az, content_area, sub_content, bloom, dok, outcomes, sem, hours)
WHERE s.code = 'RIYAZ';

-- 7-ci sinif Riyaziyyat
INSERT INTO curriculum_standards (subject_id, grade, standard_code, standard_text_az, content_area, sub_content_area, bloom_level, dok_level, learning_outcomes, is_core, semester, hours_allocated)
SELECT s.id, 7, v.code, v.text_az, v.content_area, v.sub_content, v.bloom, v.dok, v.outcomes, true, v.sem, v.hours
FROM subjects s, (VALUES
    ('R7.1.1', 'Həqiqi ədədlər çoxluğunu və xassələrini bilir', 'ededler', 'hequqi_ededler', 'anlama', 2, ARRAY['İrrasional ədədlər haqqında məlumat verir'], 1, 8),
    ('R7.2.1', 'Çevrə və dairənin xassələrini öyrənir', 'hendese', 'cevre_daire', 'anlama', 2, ARRAY['Çevrənin uzunluğunu hesablayır','Dairənin sahəsini tapır'], 1, 8),
    ('R7.2.2', 'Üçbucağın xassələrini və növlərini bilir', 'hendese', 'ucbucaq', 'təhlil', 3, ARRAY['Üçbucağın daxili bucaqlarının cəmini isbat edir'], 1, 10),
    ('R7.3.1', 'Ehtimal anlayışını başa düşür', 'statistika', 'ehtimal', 'anlama', 2, ARRAY['Sadə hadisələrin ehtimalını hesablayır'], 2, 6),
    ('R7.4.1', 'Xətti funksiya və onun qrafikini qurur', 'cebr', 'funksiyalar', 'tətbiqetmə', 3, ARRAY['y=kx+b funksiyasının qrafikini qurur'], 2, 10),
    ('R7.4.2', 'Tənliklər sistemini həll edir', 'cebr', 'tenlikler_sistemi', 'tətbiqetmə', 3, ARRAY['İki məchullu tənliklər sistemini həll edir'], 2, 10),
    ('R7.4.3', 'Qüvvət və kök anlayışını bilir', 'cebr', 'quvvet', 'tətbiqetmə', 2, ARRAY['Tam üstlü qüvvəti hesablayır','Kvadrat kökü tapır'], 1, 8)
) AS v(code, text_az, content_area, sub_content, bloom, dok, outcomes, sem, hours)
WHERE s.code = 'RIYAZ';

-- ===== AZƏRBAYCAN DİLİ STANDARTLARI (5-9 sinif) =====

-- 5-ci sinif Azərbaycan dili
INSERT INTO curriculum_standards (subject_id, grade, standard_code, standard_text_az, content_area, sub_content_area, bloom_level, dok_level, learning_outcomes, is_core, semester, hours_allocated)
SELECT s.id, 5, v.code, v.text_az, v.content_area, v.sub_content, v.bloom, v.dok, v.outcomes, true, v.sem, v.hours
FROM subjects s, (VALUES
    ('AD5.1.1', 'Dinləyib-anlama bacarığını inkişaf etdirir', 'dinleme', 'anlama', 'anlama', 2, ARRAY['Dinlədiyi mətndən əsas fikri müəyyən edir','Faktları fikirlərdən ayırır'], 1, 8),
    ('AD5.1.2', 'Oxu bacarığını inkişaf etdirir', 'oxu', 'anlama', 'anlama', 2, ARRAY['Mətni səsli və səssiz oxuyur','Mətn üzərində sualları cavablandırır'], 1, 10),
    ('AD5.2.1', 'Nitq hissələrini tanıyır və düzgün istifadə edir', 'qrammatika', 'nitq_hisseleri', 'tətbiqetmə', 2, ARRAY['İsim, sifət, feli ayırd edir','Cümlədə düzgün istifadə edir'], 1, 12),
    ('AD5.2.2', 'Cümlə quruluşunu bilir', 'qrammatika', 'cumle', 'təhlil', 3, ARRAY['Sadə və mürəkkəb cümləni fərqləndirir'], 2, 10),
    ('AD5.3.1', 'Düzgün yazı qaydalarını tətbiq edir', 'orfoqrafiya', 'yazilis', 'tətbiqetmə', 2, ARRAY['Sözlərin düzgün yazılışını bilir','Durğu işarələrini qoyur'], 2, 10),
    ('AD5.4.1', 'Esse və inşa yazır', 'yazma', 'yaradici_yazma', 'yaratma', 4, ARRAY['Verilmiş mövzuda esse yazır','Öz fikrini əsaslandırır'], 2, 8),
    ('AD5.4.2', 'Danışıq bacarığını inkişaf etdirir', 'danisiq', 'sifahi_nitq', 'yaratma', 3, ARRAY['Mövzu üzərində şifahi təqdimat edir'], 2, 6)
) AS v(code, text_az, content_area, sub_content, bloom, dok, outcomes, sem, hours)
WHERE s.code = 'AZ_DIL';

-- ===== FİZİKA STANDARTLARI (7-9 sinif) =====

INSERT INTO curriculum_standards (subject_id, grade, standard_code, standard_text_az, content_area, sub_content_area, bloom_level, dok_level, learning_outcomes, is_core, semester, hours_allocated)
SELECT s.id, 7, v.code, v.text_az, v.content_area, v.sub_content, v.bloom, v.dok, v.outcomes, true, v.sem, v.hours
FROM subjects s, (VALUES
    ('F7.1.1', 'Fiziki kəmiyyətləri, ölçü vahidlərini bilir', 'mexanika', 'olcu', 'xatırlama', 1, ARRAY['SI sistemini bilir','Fiziki kəmiyyətləri ölçür'], 1, 8),
    ('F7.1.2', 'Hərəkət növlərini fərqləndirir', 'mexanika', 'hereket', 'anlama', 2, ARRAY['Bərabərsürətli hərəkəti izah edir','Sürət hesablayır'], 1, 10),
    ('F7.2.1', 'Qüvvə anlayışını bilir', 'mexanika', 'quvve', 'anlama', 2, ARRAY['Qüvvənin ölçü vahidini bilir','Nyuton qanunlarını izah edir'], 2, 10),
    ('F7.3.1', 'Təzyiq anlayışını tətbiq edir', 'mexanika', 'tezyiq', 'tətbiqetmə', 3, ARRAY['Bərk cisimlərdə təzyiqi hesablayır','Maye və qaz təzyiqini izah edir'], 2, 8)
) AS v(code, text_az, content_area, sub_content, bloom, dok, outcomes, sem, hours)
WHERE s.code = 'FIZIKA';

-- ===== BEYNƏLXALQ ÇƏRÇIVƏLƏR =====

INSERT INTO international_frameworks (framework_name, framework_code, description, version, country, url) VALUES
('Programme for International Student Assessment', 'PISA', 'OECD-nin 15 yaşlı şagirdlər üçün beynəlxalq qiymətləndirmə proqramı', '2025', 'International', 'https://www.oecd.org/pisa/'),
('Progress in International Reading Literacy Study', 'PIRLS', '4-cü sinif oxu savadlığı beynəlxalq tədqiqatı', '2026', 'International', 'https://pirls2026.org/'),
('Trends in International Mathematics and Science Study', 'TIMSS', 'Riyaziyyat və elm üzrə beynəlxalq tendensiyalar', '2023', 'International', 'https://timss2023.org/'),
('Early Grade Reading Assessment', 'EGRA', 'İbtidai siniflərdə oxu qiymətləndirməsi', '2.0', 'International', 'https://www.usaid.gov/'),
('Common European Framework of Reference', 'CEFR', 'Dil öyrənmə üçün Avropa çərçivəsi', '2020', 'Europe', 'https://www.coe.int/'),
('Finland National Core Curriculum', 'FIN_NCC', 'Finlandiya milli kurikulum standartları', '2014', 'Finland', 'https://www.oph.fi/'),
('Singapore Mathematics Framework', 'SG_MATH', 'Sinqapur riyaziyyat təlimi çərçivəsi', '2020', 'Singapore', 'https://www.moe.gov.sg/'),
('Estonia National Curriculum', 'EST_NC', 'Estoniya milli kurikulum standartları', '2014', 'Estonia', 'https://www.hm.ee/');

-- ===== DEMO MƏKTƏB VƏ MÜƏLLIMLƏR =====

INSERT INTO schools (name, code, city, district, school_type, email) VALUES
('1 nömrəli tam orta məktəb', 'SCH001', 'Bakı', 'Nəsimi', 'orta_mekteb', 'school1@edu.gov.az'),
('12 nömrəli gimnaziya', 'GYM012', 'Bakı', 'Yasamal', 'gimnaziya', 'gym12@edu.gov.az'),
('5 nömrəli lisey', 'LIS005', 'Bakı', 'Xətai', 'lisey', 'lis5@edu.gov.az');

-- Demo teacher (password: Arti2026!)
INSERT INTO teachers (school_id, first_name, last_name, patronymic, email, password_hash, role, specialization, experience_years, qualification_category)
SELECT s.id, 'Aynur', 'Həsənova', 'Rəşid qızı', 'aynur@demo.edu.az', 
    '$2b$12$LJ3m4ks9Yx5ABCDEFGHIJ.klmnopqrstuvwxyz1234567890', 
    'teacher', 'Riyaziyyat', 15, 'ali_kateqoriya'
FROM schools s WHERE s.code = 'SCH001';

INSERT INTO teachers (school_id, first_name, last_name, patronymic, email, password_hash, role, specialization, experience_years, qualification_category)
SELECT s.id, 'Kamran', 'Əliyev', 'Fuad oğlu', 'kamran@demo.edu.az',
    '$2b$12$LJ3m4ks9Yx5ABCDEFGHIJ.klmnopqrstuvwxyz1234567890',
    'teacher', 'Azərbaycan dili', 10, 'birinci_kateqoriya'
FROM schools s WHERE s.code = 'SCH001';
