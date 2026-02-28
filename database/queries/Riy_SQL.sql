-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║                                                                      ║
-- ║   📐 RİYAZİYYAT — STANDARTLAR VƏ ALT STANDARTLAR SORĞULARI          ║
-- ║   ARTI 2026 — Müəllim Agent                                         ║
-- ║   Müəllif: Tariyel Talibov                                           ║
-- ║                                                                      ║
-- ╚══════════════════════════════════════════════════════════════════════╝

-- ═══════════════════════════════════════════════════════════════
-- 1. BÜTÜN SİNİFLƏRİN STANDARTLARI — GÖZƏL XÜLASƏ CƏDVƏLİ
-- ═══════════════════════════════════════════════════════════════

SELECT 
    '┃' AS "│",
    '📐 ' || cs.standard_code AS "📐 Standart Kodu",
    cs.grade || '-ci sinif' AS "🎓 Sinif",
    cs.standard_text_az AS "📋 Standart Mətni",
    CASE cs.content_area
        WHEN 'ededler' THEN '🔢 Ədədlər'
        WHEN 'hendese' THEN '📏 Həndəsə'
        WHEN 'cebr' THEN '🔤 Cəbr'
        WHEN 'statistika' THEN '📊 Statistika'
        ELSE cs.content_area
    END AS "📁 Məzmun Sahəsi",
    CASE cs.bloom_level
        WHEN 'xatırlama' THEN '🟤 Xatırlama'
        WHEN 'anlama' THEN '🟢 Anlama'
        WHEN 'tətbiqetmə' THEN '🔵 Tətbiqetmə'
        WHEN 'təhlil' THEN '🟡 Təhlil'
        WHEN 'qiymətləndirmə' THEN '🟠 Qiymətləndirmə'
        WHEN 'yaratma' THEN '🔴 Yaratma'
    END AS "🧠 Bloom",
    'DOK-' || cs.dok_level AS "🎯 DOK",
    cs.hours_allocated || ' saat' AS "⏱️ Saat",
    CASE cs.semester WHEN 1 THEN 'I yarım' WHEN 2 THEN 'II yarım' END AS "📅 Sem."
FROM curriculum_standards cs
JOIN subjects s ON cs.subject_id = s.id
WHERE s.code = 'RIYAZ'
ORDER BY cs.grade, cs.standard_code;


-- ═══════════════════════════════════════════════════════════════
-- 2. HƏR SİNİF AYRI-AYRI (5-ci sinif)
-- ═══════════════════════════════════════════════════════════════

SELECT 
    repeat('─', 80) AS "═══════ 5-ci SİNİF — RİYAZİYYAT ═══════"
UNION ALL
SELECT '';

SELECT
    ROW_NUMBER() OVER (ORDER BY cs.standard_code) AS "№",
    cs.standard_code AS "Kod",
    cs.standard_text_az AS "Standart mətni (AZ)",
    UPPER(cs.content_area) AS "Sahə",
    cs.sub_content_area AS "Alt sahə",
    INITCAP(cs.bloom_level) AS "Bloom",
    cs.dok_level AS "DOK",
    cs.hours_allocated AS "Saat",
    CASE WHEN cs.is_core THEN '✅' ELSE '◻️' END AS "Əsas",
    array_to_string(cs.learning_outcomes, ' │ ') AS "Öyrənmə nəticələri"
FROM curriculum_standards cs
JOIN subjects s ON cs.subject_id = s.id
WHERE s.code = 'RIYAZ' AND cs.grade = 5
ORDER BY cs.standard_code;


-- ═══════════════════════════════════════════════════════════════
-- 3. HƏR SİNİF AYRI-AYRI (6-cı sinif)
-- ═══════════════════════════════════════════════════════════════

SELECT
    ROW_NUMBER() OVER (ORDER BY cs.standard_code) AS "№",
    cs.standard_code AS "Kod",
    cs.standard_text_az AS "Standart mətni (AZ)",
    UPPER(cs.content_area) AS "Sahə",
    cs.sub_content_area AS "Alt sahə",
    INITCAP(cs.bloom_level) AS "Bloom",
    cs.dok_level AS "DOK",
    cs.hours_allocated AS "Saat",
    array_to_string(cs.learning_outcomes, ' │ ') AS "Öyrənmə nəticələri"
FROM curriculum_standards cs
JOIN subjects s ON cs.subject_id = s.id
WHERE s.code = 'RIYAZ' AND cs.grade = 6
ORDER BY cs.standard_code;


-- ═══════════════════════════════════════════════════════════════
-- 4. HƏR SİNİF AYRI-AYRI (7-ci sinif)
-- ═══════════════════════════════════════════════════════════════

SELECT
    ROW_NUMBER() OVER (ORDER BY cs.standard_code) AS "№",
    cs.standard_code AS "Kod",
    cs.standard_text_az AS "Standart mətni (AZ)",
    UPPER(cs.content_area) AS "Sahə",
    cs.sub_content_area AS "Alt sahə",
    INITCAP(cs.bloom_level) AS "Bloom",
    cs.dok_level AS "DOK",
    cs.hours_allocated AS "Saat",
    array_to_string(cs.learning_outcomes, ' │ ') AS "Öyrənmə nəticələri"
FROM curriculum_standards cs
JOIN subjects s ON cs.subject_id = s.id
WHERE s.code = 'RIYAZ' AND cs.grade = 7
ORDER BY cs.standard_code;


-- ═══════════════════════════════════════════════════════════════
-- 5. STANDART + ALT STANDARTLAR BİRLƏŞDİRİLMİŞ
--    (curriculum_standards + content_standards_detail)
-- ═══════════════════════════════════════════════════════════════

SELECT
    cs.grade || '-ci sinif' AS "Sinif",
    cs.standard_code AS "Standart",
    cs.standard_text_az AS "Standart Mətni",
    COALESCE(csd.sub_standard_code, '—') AS "Alt Standart",
    COALESCE(csd.sub_standard_text_az, '(alt standart hələ əlavə edilməyib)') AS "Alt Standart Mətni",
    COALESCE(csd.indicator_text_az, '—') AS "Göstərici",
    COALESCE(array_to_string(csd.assessment_criteria, '; '), '—') AS "Qiymətləndirmə meyarları",
    COALESCE(array_to_string(csd.example_activities, '; '), '—') AS "Nümunə fəaliyyətlər"
FROM curriculum_standards cs
JOIN subjects s ON cs.subject_id = s.id
LEFT JOIN content_standards_detail csd ON csd.standard_id = cs.id
WHERE s.code = 'RIYAZ'
ORDER BY cs.grade, cs.standard_code, csd.sub_standard_code;


-- ═══════════════════════════════════════════════════════════════
-- 6. BLOOM TAKSONOMİYASINA GÖRƏ QRUPLAŞDIRMA
-- ═══════════════════════════════════════════════════════════════

SELECT
    CASE cs.bloom_level
        WHEN 'xatırlama' THEN '1 🟤 XATIRLAMA'
        WHEN 'anlama' THEN '2 🟢 ANLAMA'
        WHEN 'tətbiqetmə' THEN '3 🔵 TƏTBİQETMƏ'
        WHEN 'təhlil' THEN '4 🟡 TƏHLİL'
        WHEN 'qiymətləndirmə' THEN '5 🟠 QİYMƏTLƏNDİRMƏ'
        WHEN 'yaratma' THEN '6 🔴 YARATMA'
    END AS "🧠 BLOOM SƏVİYYƏSİ",
    COUNT(*) AS "Standart sayı",
    STRING_AGG(cs.standard_code, ', ' ORDER BY cs.grade, cs.standard_code) AS "Standartlar",
    STRING_AGG(DISTINCT cs.grade::text || '-ci sinif', ', ' ORDER BY cs.grade::text || '-ci sinif') AS "Siniflər",
    ROUND(AVG(cs.hours_allocated), 1) AS "Ort. saat",
    ROUND(AVG(cs.dok_level), 1) AS "Ort. DOK"
FROM curriculum_standards cs
JOIN subjects s ON cs.subject_id = s.id
WHERE s.code = 'RIYAZ'
GROUP BY cs.bloom_level
ORDER BY 1;


-- ═══════════════════════════════════════════════════════════════
-- 7. DOK SƏVİYYƏLƏRİNƏ GÖRƏ QRUPLAŞDIRMA
-- ═══════════════════════════════════════════════════════════════

SELECT
    CASE cs.dok_level
        WHEN 1 THEN '🎯 DOK-1: Xatırlama / Reproduksiya'
        WHEN 2 THEN '🎯 DOK-2: Bacarıq / Konsept'
        WHEN 3 THEN '🎯 DOK-3: Strateji Düşüncə'
        WHEN 4 THEN '🎯 DOK-4: Genişləndirilmiş Düşüncə'
    END AS "DOK Səviyyəsi",
    COUNT(*) AS "Say",
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) || '%' AS "Faiz",
    STRING_AGG(cs.standard_code, ', ' ORDER BY cs.standard_code) AS "Standartlar"
FROM curriculum_standards cs
JOIN subjects s ON cs.subject_id = s.id
WHERE s.code = 'RIYAZ'
GROUP BY cs.dok_level
ORDER BY cs.dok_level;


-- ═══════════════════════════════════════════════════════════════
-- 8. MƏZMUN SAHƏLƏRİNƏ GÖRƏ STATİSTİKA
-- ═══════════════════════════════════════════════════════════════

SELECT
    CASE cs.content_area
        WHEN 'ededler' THEN '🔢 ƏDƏDLƏR'
        WHEN 'hendese' THEN '📏 HƏNDƏSƏ'
        WHEN 'cebr' THEN '🔤 CƏBR'
        WHEN 'statistika' THEN '📊 STATİSTİKA'
    END AS "Məzmun Sahəsi",
    COUNT(*) AS "Standart sayı",
    SUM(cs.hours_allocated) AS "Cəmi saat",
    ROUND(AVG(cs.dok_level), 1) AS "Ort. DOK",
    STRING_AGG(DISTINCT cs.sub_content_area, ', ') AS "Alt sahələr",
    STRING_AGG(DISTINCT cs.grade::text, ', ' ORDER BY cs.grade::text) AS "Siniflər"
FROM curriculum_standards cs
JOIN subjects s ON cs.subject_id = s.id
WHERE s.code = 'RIYAZ'
GROUP BY cs.content_area
ORDER BY 2 DESC;


-- ═══════════════════════════════════════════════════════════════
-- 9. SİNİF × BLOOM MATRİSİ (Cross-tab görüntü)
-- ═══════════════════════════════════════════════════════════════

SELECT
    cs.grade || '-ci sinif' AS "Sinif",
    COUNT(*) FILTER (WHERE cs.bloom_level = 'xatırlama') AS "🟤 Xatırlama",
    COUNT(*) FILTER (WHERE cs.bloom_level = 'anlama') AS "🟢 Anlama",
    COUNT(*) FILTER (WHERE cs.bloom_level = 'tətbiqetmə') AS "🔵 Tətbiq",
    COUNT(*) FILTER (WHERE cs.bloom_level = 'təhlil') AS "🟡 Təhlil",
    COUNT(*) FILTER (WHERE cs.bloom_level = 'qiymətləndirmə') AS "🟠 Qiym.",
    COUNT(*) FILTER (WHERE cs.bloom_level = 'yaratma') AS "🔴 Yaratma",
    COUNT(*) AS "CƏMİ",
    SUM(cs.hours_allocated) AS "Cəmi saat"
FROM curriculum_standards cs
JOIN subjects s ON cs.subject_id = s.id
WHERE s.code = 'RIYAZ'
GROUP BY cs.grade
ORDER BY cs.grade;


-- ═══════════════════════════════════════════════════════════════
-- 10. SİNİF × MƏZMUN SAHƏSİ MATRİSİ
-- ═══════════════════════════════════════════════════════════════

SELECT
    cs.grade || '-ci sinif' AS "Sinif",
    COUNT(*) FILTER (WHERE cs.content_area = 'ededler') AS "🔢 Ədədlər",
    COUNT(*) FILTER (WHERE cs.content_area = 'hendese') AS "📏 Həndəsə",
    COUNT(*) FILTER (WHERE cs.content_area = 'cebr') AS "🔤 Cəbr",
    COUNT(*) FILTER (WHERE cs.content_area = 'statistika') AS "📊 Statistika",
    COUNT(*) AS "CƏMİ",
    SUM(cs.hours_allocated) || ' saat' AS "⏱️ Cəmi"
FROM curriculum_standards cs
JOIN subjects s ON cs.subject_id = s.id
WHERE s.code = 'RIYAZ'
GROUP BY cs.grade
ORDER BY cs.grade;


-- ═══════════════════════════════════════════════════════════════
-- 11. ÖYRƏNMƏ NƏTİCƏLƏRİ — TƏFSİLATLI
-- ═══════════════════════════════════════════════════════════════

SELECT
    cs.grade || '-ci sinif' AS "Sinif",
    cs.standard_code AS "Kod",
    cs.standard_text_az AS "Standart",
    INITCAP(cs.bloom_level) AS "Bloom",
    outcome AS "🎯 Öyrənmə nəticəsi"
FROM curriculum_standards cs
JOIN subjects s ON cs.subject_id = s.id,
LATERAL unnest(cs.learning_outcomes) AS outcome
WHERE s.code = 'RIYAZ'
ORDER BY cs.grade, cs.standard_code;


-- ═══════════════════════════════════════════════════════════════
-- 12. SEMESTER ÜZRƏ BÖLGÜ
-- ═══════════════════════════════════════════════════════════════

SELECT
    cs.grade || '-ci sinif' AS "Sinif",
    CASE cs.semester 
        WHEN 1 THEN '📗 I Yarımil' 
        WHEN 2 THEN '📘 II Yarımil' 
    END AS "Semester",
    COUNT(*) AS "Standart sayı",
    SUM(cs.hours_allocated) || ' saat' AS "Cəmi saat",
    STRING_AGG(cs.standard_code, ', ' ORDER BY cs.standard_code) AS "Standartlar"
FROM curriculum_standards cs
JOIN subjects s ON cs.subject_id = s.id
WHERE s.code = 'RIYAZ'
GROUP BY cs.grade, cs.semester
ORDER BY cs.grade, cs.semester;


-- ═══════════════════════════════════════════════════════════════
-- 13. ÜMUMİ STATİSTİKA PANELİ
-- ═══════════════════════════════════════════════════════════════

SELECT '📐 RİYAZİYYAT — ÜMUMİ STATİSTİKA' AS "═══════════════════════════════"
UNION ALL
SELECT '───────────────────────────────────────';

SELECT
    'Standart sayı' AS "Göstərici",
    COUNT(*)::text AS "Dəyər"
FROM curriculum_standards cs JOIN subjects s ON cs.subject_id = s.id WHERE s.code = 'RIYAZ'
UNION ALL
SELECT
    'Sinif aralığı',
    MIN(cs.grade) || ' - ' || MAX(cs.grade) || '-ci siniflər'
FROM curriculum_standards cs JOIN subjects s ON cs.subject_id = s.id WHERE s.code = 'RIYAZ'
UNION ALL
SELECT
    'Cəmi saat ayrılmış',
    SUM(cs.hours_allocated)::text || ' saat'
FROM curriculum_standards cs JOIN subjects s ON cs.subject_id = s.id WHERE s.code = 'RIYAZ'
UNION ALL
SELECT
    'Orta DOK səviyyəsi',
    ROUND(AVG(cs.dok_level), 2)::text
FROM curriculum_standards cs JOIN subjects s ON cs.subject_id = s.id WHERE s.code = 'RIYAZ'
UNION ALL
SELECT
    'Məzmun sahələri',
    COUNT(DISTINCT cs.content_area)::text || ' sahə'
FROM curriculum_standards cs JOIN subjects s ON cs.subject_id = s.id WHERE s.code = 'RIYAZ'
UNION ALL
SELECT
    'Bloom səviyyəsi diapazonu',
    STRING_AGG(DISTINCT INITCAP(cs.bloom_level), ' → ' ORDER BY INITCAP(cs.bloom_level))
FROM curriculum_standards cs JOIN subjects s ON cs.subject_id = s.id WHERE s.code = 'RIYAZ'
UNION ALL
SELECT
    'Öyrənmə nəticəsi sayı',
    SUM(array_length(cs.learning_outcomes, 1))::text
FROM curriculum_standards cs JOIN subjects s ON cs.subject_id = s.id WHERE s.code = 'RIYAZ';


-- ═══════════════════════════════════════════════════════════════
-- 14. KONKRETSİNİF SORĞUSU — Parametrli
--     (Dəyişdirmək üçün: WHERE cs.grade = 6 hissəsini dəyişin)
-- ═══════════════════════════════════════════════════════════════

-- 📌 İSTİFADƏ: Aşağıdakı sorğuda '6' əvəzinə istədiyiniz sinifi yazın

SELECT
    '╔══════════════════════════════════════════════════════════════╗' AS ""
UNION ALL
SELECT '║  📐 ' || cs.grade || '-ci SİNİF RİYAZİYYAT — TAM STANDART CƏDVƏLİ         ║'
FROM curriculum_standards cs JOIN subjects s ON cs.subject_id = s.id 
WHERE s.code = 'RIYAZ' AND cs.grade = 6 LIMIT 1
UNION ALL
SELECT '╚══════════════════════════════════════════════════════════════╝';

SELECT
    E'\n┌───────────────────────────────────────────────────┐' AS "",
    cs.standard_code AS "Standart",
    E'│ ' || cs.standard_text_az AS "Mətni"
FROM curriculum_standards cs
JOIN subjects s ON cs.subject_id = s.id
WHERE s.code = 'RIYAZ' AND cs.grade = 6
ORDER BY cs.standard_code;

-- Seçilmiş sinifin standartlarının ətraflı görüntüsü
SELECT
    cs.standard_code AS "📐 Kod",
    cs.standard_text_az AS "📋 Standart",
    '────────────────────────' AS "──────────",
    CASE cs.content_area
        WHEN 'ededler' THEN '🔢 Ədədlər'
        WHEN 'hendese' THEN '📏 Həndəsə'
        WHEN 'cebr' THEN '🔤 Cəbr'
        WHEN 'statistika' THEN '📊 Statistika'
    END AS "📁 Sahə",
    cs.sub_content_area AS "📂 Alt sahə",
    '────────────────────────' AS "──────────",
    CASE cs.bloom_level
        WHEN 'xatırlama' THEN '🟤 1. Xatırlama (Remember)'
        WHEN 'anlama' THEN '🟢 2. Anlama (Understand)'
        WHEN 'tətbiqetmə' THEN '🔵 3. Tətbiqetmə (Apply)'
        WHEN 'təhlil' THEN '🟡 4. Təhlil (Analyze)'
        WHEN 'qiymətləndirmə' THEN '🟠 5. Qiymətləndirmə (Evaluate)'
        WHEN 'yaratma' THEN '🔴 6. Yaratma (Create)'
    END AS "🧠 Bloom Taksonomiyası",
    'DOK-' || cs.dok_level || CASE cs.dok_level
        WHEN 1 THEN ': Xatırlama / Reproduksiya'
        WHEN 2 THEN ': Bacarıq / Konsept'
        WHEN 3 THEN ': Strateji Düşüncə'
        WHEN 4 THEN ': Genişləndirilmiş Düşüncə'
    END AS "🎯 DOK Səviyyəsi",
    '────────────────────────' AS "──────────",
    cs.hours_allocated || ' saat' AS "⏱️ Ayrılan saat",
    CASE cs.semester WHEN 1 THEN '📗 I Yarımil' WHEN 2 THEN '📘 II Yarımil' END AS "📅 Semester",
    CASE WHEN cs.is_core THEN '✅ Əsas standart' ELSE '◻️ Əlavə' END AS "📌 Status",
    '────────────────────────' AS "──────────",
    array_to_string(cs.learning_outcomes, E'\n  ✦ ') AS "🎓 Öyrənmə nəticələri"
FROM curriculum_standards cs
JOIN subjects s ON cs.subject_id = s.id
WHERE s.code = 'RIYAZ' AND cs.grade = 6
ORDER BY cs.standard_code;


-- ═══════════════════════════════════════════════════════════════
-- 15. STANDART AXTARIŞ — Açar söz ilə
--     (Dəyişdirmək üçün: ILIKE '%faiz%' hissəsini dəyişin)
-- ═══════════════════════════════════════════════════════════════

-- 📌 İSTİFADƏ: '%faiz%' əvəzinə istədiyiniz açar sözü yazın

SELECT
    cs.grade || '-ci sinif' AS "Sinif",
    cs.standard_code AS "Kod",
    cs.standard_text_az AS "Standart",
    INITCAP(cs.bloom_level) AS "Bloom",
    cs.dok_level AS "DOK"
FROM curriculum_standards cs
JOIN subjects s ON cs.subject_id = s.id
WHERE s.code = 'RIYAZ'
  AND (
      cs.standard_text_az ILIKE '%faiz%'
      OR cs.sub_content_area ILIKE '%faiz%'
      OR EXISTS (
          SELECT 1 FROM unnest(cs.learning_outcomes) lo 
          WHERE lo ILIKE '%faiz%'
      )
      OR EXISTS (
          SELECT 1 FROM unnest(cs.keywords) kw 
          WHERE kw ILIKE '%faiz%'
      )
  )
ORDER BY cs.grade;


-- ═══════════════════════════════════════════════════════════════
-- 16. STANDART İLƏ ƏLAQƏLİ TAPŞIRIQLAR
-- ═══════════════════════════════════════════════════════════════

SELECT
    cs.standard_code AS "📐 Standart",
    cs.grade || '-ci sinif' AS "Sinif",
    q.question_text AS "📝 Tapşırıq mətni",
    INITCAP(q.bloom_level) AS "Bloom",
    q.dok_level AS "DOK",
    q.points AS "Bal",
    ROUND(q.difficulty::numeric, 2) AS "Çətinlik",
    q.topic AS "Mövzu"
FROM curriculum_standards cs
JOIN subjects s ON cs.subject_id = s.id
LEFT JOIN questions q ON q.topic = cs.sub_content_area 
    OR cs.standard_text_az ILIKE '%' || q.topic || '%'
WHERE s.code = 'RIYAZ' AND q.id IS NOT NULL
ORDER BY cs.grade, cs.standard_code, q.bloom_level;


-- ═══════════════════════════════════════════════════════════════
-- 17. STANDART İLƏ DƏRS PLANLARI ƏLAQƏSİ
-- ═══════════════════════════════════════════════════════════════

SELECT
    cs.standard_code AS "📐 Standart",
    cs.standard_text_az AS "Standart mətni",
    lp.title AS "📝 Dərs planı",
    lp.topic AS "Mövzu",
    array_to_string(lp.bloom_levels, ', ') AS "Bloom",
    lp.plan_type AS "Plan tipi",
    lp.status AS "Status"
FROM curriculum_standards cs
JOIN subjects s ON cs.subject_id = s.id
JOIN lesson_plan_standards lps ON lps.standard_id = cs.id
JOIN lesson_plans lp ON lp.id = lps.lesson_plan_id
WHERE s.code = 'RIYAZ'
ORDER BY cs.grade, cs.standard_code;


-- ═══════════════════════════════════════════════════════════════
-- 18. BEYNƏLXALQ ÇƏRÇIVƏ UYĞUNLUĞU
-- ═══════════════════════════════════════════════════════════════

SELECT
    cs.standard_code AS "📐 AZ Standart",
    cs.standard_text_az AS "Standart",
    f.framework_code AS "🌍 Çərçivə",
    f.framework_name AS "Çərçivə adı",
    sfm.framework_standard_code AS "Beynəlxalq kod",
    CASE sfm.alignment_level
        WHEN 'full' THEN '🟢 Tam uyğun'
        WHEN 'partial' THEN '🟡 Qismən'
        WHEN 'related' THEN '🔵 Əlaqəli'
    END AS "Uyğunluq"
FROM curriculum_standards cs
JOIN subjects s ON cs.subject_id = s.id
LEFT JOIN standard_framework_mapping sfm ON sfm.standard_id = cs.id
LEFT JOIN international_frameworks f ON f.id = sfm.framework_id
WHERE s.code = 'RIYAZ'
ORDER BY cs.grade, cs.standard_code, f.framework_code;


-- ╔══════════════════════════════════════════════════════════════╗
-- ║  📊 BONUS: psql üçün formatlaşdırma parametrləri            ║
-- ║  Bu əmrləri psql-dən əvvəl işlədin ki gözəl görünsün:      ║
-- ║                                                              ║
-- ║  \pset border 2                                              ║
-- ║  \pset linestyle unicode                                     ║
-- ║  \pset format wrapped                                        ║
-- ║  \pset columns 200                                           ║
-- ║  \x auto                                                     ║
-- ║  \encoding UTF8                                              ║
-- ╚══════════════════════════════════════════════════════════════╝
