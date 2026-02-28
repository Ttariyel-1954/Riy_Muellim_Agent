-- ============================================================
-- DƏRS PLANLARI VƏ TAPŞIRIQ BANKASI — PostgreSQL
-- Bu fayl MD-dəki bütün tapşırıqları bazaya yazır
-- ============================================================

-- ═══════════════════════════════════════════════
-- 1. RİYAZİYYAT 6-cı sinif — FAİZLƏR
-- ═══════════════════════════════════════════════

-- Dərs planı
INSERT INTO lesson_plans (
    teacher_id, subject_id, plan_type, title, topic,
    duration_minutes, bloom_levels, dok_level,
    objectives, warm_up, main_activity, practice_activity,
    assessment_activity, closure, homework,
    differentiation, materials, teaching_methods,
    ai_generated, status
)
SELECT
    t.id,
    s.id,
    'daily',
    'Faizlər — Anlayış, Hesablama və Real Həyat Tətbiqləri',
    'Faizlər',
    45,
    ARRAY['anlama', 'tətbiqetmə'],
    2,
    '[
        {"text": "Şagird faiz anlayışını izah edir və kəsr/onluq kəsr ilə əlaqəsini göstərir", "bloom": "anlama", "dok": 2},
        {"text": "Verilmiş ədədin faizini hesablayır", "bloom": "tətbiqetmə", "dok": 2},
        {"text": "Gündəlik həyatdan faiz nümunələrini müəyyən edir", "bloom": "anlama", "dok": 2}
    ]'::jsonb,
    'Ssenari: Bakıda Bravo mağazasında 120 manatlıq paltar 25% endirimlə satılır. Yeni qiyməti nə qədərdir?',
    'Faiz anlayışı, Faiz=Hissə/Bütöv×100, kəsr-faiz-onluq əlaqəsi, 4 qrupa tapşırıq kartları',
    'İş Vərəqi №1 — 5 sual, 15 bal, müxtəlif çətinlik',
    'Çıxış Bileti: 100 manatlıq əşya əvvəlcə 20% bahalaşdı, sonra 20% ucuzlaşdı. Son qiyməti?',
    'KWL cədvəli doldurulması',
    'Əsas: 4 tapşırıq (Tətbiq, DOK-2). Əlavə: Faiz artım-azalma paradoksu (Təhlil, DOK-3). Yaradıcı: Ailə büdcəsi araşdırması (Yaratma, DOK-4)',
    '{"zeif": "Vizual kartlar, addımlı təlimat, kalkulyator, azaldılmış həcm (3 tapşırıq)",
      "orta": "Standart plan, 5 tapşırıq, müstəqil iş",
      "yuksek": "Bank depoziti tədqiqatı, Faiz Oyunu layihəsi, mentorluq"}'::jsonb,
    ARRAY['İş vərəqi', 'Qrup kartları', 'KWL cədvəli', '100-lük cədvəl'],
    ARRAY['Problem-based Learning', 'Cooperative Learning'],
    true,
    'approved'
FROM teachers t, subjects s
WHERE t.email = 'aynur@demo.edu.az' AND s.code = 'RIYAZ'
LIMIT 1;

-- Tapşırıqlar — Faizlər (Səviyyə 1: Xatırlama + Anlama)
INSERT INTO questions (assessment_id, question_type, question_text, correct_answer, explanation, points, difficulty, discrimination, bloom_level, dok_level, topic, tags, ai_generated, position)
VALUES
-- Mən assessment_id-siz yazıram ki, müstəqil sual bankası olsun
(NULL, 'short_answer', '100% nə deməkdir?', '"Bütöv, tam"', 'Faiz anlayışının əsası', 1, 0.15, 0.3, 'xatırlama', 1, 'Faizlər', ARRAY['faiz', 'anlayış', '6-cı sinif'], true, 1),
(NULL, 'short_answer', '50% kəsr kimi necə yazılır?', '"1/2"', '50/100 = 1/2', 1, 0.20, 0.35, 'xatırlama', 1, 'Faizlər', ARRAY['faiz', 'kəsr', '6-cı sinif'], true, 2),
(NULL, 'short_answer', '0,25 faiz kimi neçədir?', '"25%"', '0.25 × 100 = 25%', 1, 0.25, 0.40, 'anlama', 1, 'Faizlər', ARRAY['faiz', 'onluq', '6-cı sinif'], true, 3),
(NULL, 'short_answer', '3/4 faiz kimi neçədir?', '"75%"', '3/4 = 0.75 = 75%', 1, 0.25, 0.40, 'anlama', 1, 'Faizlər', ARRAY['faiz', 'kəsr', '6-cı sinif'], true, 4),
(NULL, 'essay', '"Əhalinin 30%-i uşaqlardır" — bu nə deməkdir? Öz sözlərinlə izah et', '"Hər 100 nəfərdən 30-u uşaqdır"', 'Faiz anlayışının real kontekstdə izahı', 2, 0.35, 0.45, 'anlama', 2, 'Faizlər', ARRAY['faiz', 'izah', '6-cı sinif'], true, 5);

-- Tapşırıqlar — Faizlər (Səviyyə 2: Tətbiqetmə)
INSERT INTO questions (assessment_id, question_type, question_text, correct_answer, explanation, points, difficulty, discrimination, bloom_level, dok_level, topic, tags, ai_generated, position)
VALUES
(NULL, 'numeric', '250-nin 40%-ni tapın', '100', '250 × 40/100 = 100', 2, 0.35, 0.50, 'tətbiqetmə', 2, 'Faizlər', ARRAY['faiz', 'hesablama', '6-cı sinif'], true, 6),
(NULL, 'numeric', '90 kq-ın 15%-ni tapın', '13.5', '90 × 15/100 = 13.5', 2, 0.40, 0.50, 'tətbiqetmə', 2, 'Faizlər', ARRAY['faiz', 'hesablama', '6-cı sinif'], true, 7),
(NULL, 'numeric', '360 şagirddən 90-ı 5 aldı. Bu neçə faizdir?', '25', '90/360 × 100 = 25%', 3, 0.45, 0.55, 'tətbiqetmə', 2, 'Faizlər', ARRAY['faiz', 'hesablama', '6-cı sinif'], true, 8),
(NULL, 'numeric', 'Ədədin 35%-i 70-dir. Ədədi tapın', '200', '70 × 100/35 = 200', 3, 0.50, 0.55, 'tətbiqetmə', 2, 'Faizlər', ARRAY['faiz', 'bütövü tapmaq', '6-cı sinif'], true, 9),
(NULL, 'numeric', 'Əmək haqqı 800 AZN idi, 15% artdı. Yeni əmək haqqı?', '920', '800 × 1.15 = 920', 3, 0.45, 0.55, 'tətbiqetmə', 2, 'Faizlər', ARRAY['faiz', 'artım', '6-cı sinif'], true, 10),
(NULL, 'numeric', 'Noutbuk 1200 AZN, 30% endirim. Endirimli qiyməti?', '840', '1200 × 0.70 = 840', 3, 0.45, 0.55, 'tətbiqetmə', 2, 'Faizlər', ARRAY['faiz', 'endirim', '6-cı sinif'], true, 11),
(NULL, 'numeric', 'Tərəvəz 2 kq idi, qurudulduqda 80% su itirdi. Quru çəkisi?', '0.4', '2 × 0.20 = 0.4 kq', 3, 0.55, 0.60, 'tətbiqetmə', 2, 'Faizlər', ARRAY['faiz', 'azalma', '6-cı sinif'], true, 12);

-- Tapşırıqlar — Faizlər (Səviyyə 3: Təhlil)
INSERT INTO questions (assessment_id, question_type, question_text, correct_answer, explanation, points, difficulty, discrimination, bloom_level, dok_level, topic, tags, ai_generated, position)
VALUES
(NULL, 'essay', 'Əli imtahanda 40 sualdan 32-ni düzgün cavabladı. Aynur 50 sualdan 38-ni. Kim daha yaxşı nəticə göstərib? Niyə?', '"Əli: 32/40=80%, Aynur: 38/50=76%. Əli daha yaxşıdır"', 'Müqayisə üçün faiz hesablama lazımdır', 5, 0.60, 0.65, 'təhlil', 3, 'Faizlər', ARRAY['faiz', 'müqayisə', 'təhlil', '6-cı sinif'], true, 13),
(NULL, 'essay', 'Mağaza A: 200 AZN, 25% endirim. Mağaza B: 180 AZN, 15% endirim. Hansı sərfəlidir?', '"A: 150 AZN, B: 153 AZN. A sərfəlidir, 3 AZN fərq"', 'İki endirimi müqayisə etmək', 5, 0.60, 0.65, 'təhlil', 3, 'Faizlər', ARRAY['faiz', 'müqayisə', '6-cı sinif'], true, 14),
(NULL, 'essay', 'Şəhərin əhalisi 2020-də 100000. 2021-də 10% artdı, 2022-də 5% azaldı. 2022 əhalisi? Niyə 105000 deyil?', '"110000 × 0.95 = 104500. Çünki 5% 110000-dən hesablanır"', 'Mürəkkəb faiz anlayışı', 5, 0.65, 0.70, 'təhlil', 3, 'Faizlər', ARRAY['faiz', 'mürəkkəb', '6-cı sinif'], true, 15),
(NULL, 'essay', 'Bank A: illik 12%. Bank B: yarımillik 6% (ildə 2 dəfə). 1000 AZN, 1 il. Hansı çox?', '"A: 1120, B: 1000×1.06×1.06=1123.6. B çox"', 'Mürəkkəb faiz praktik tətbiqi', 7, 0.75, 0.75, 'təhlil', 3, 'Faizlər', ARRAY['faiz', 'bank', 'mürəkkəb', '6-cı sinif'], true, 16);

-- Tapşırıqlar — Faizlər (Səviyyə 4: Qiymətləndirmə + Yaratma)
INSERT INTO questions (assessment_id, question_type, question_text, correct_answer, explanation, points, difficulty, discrimination, bloom_level, dok_level, topic, tags, scoring_rubric, ai_generated, position)
VALUES
(NULL, 'essay', 'Sinif yoldaşınız deyir: "50% artım + 50% azalma = dəyişiklik yoxdur". Bu fikir düzgündürmü? Sübut edin', '"Yanlışdır. 100×1.5=150, 150×0.5=75. Nəticə 75, 100 yox"', 'Faiz paradoksunun izahı', 7, 0.70, 0.75, 'qiymətləndirmə', 3, 'Faizlər', ARRAY['faiz', 'sübut', '6-cı sinif'],
    '{"riyazi_duzgunluk": {"max": 3, "tesvir": "Hesablama düzgünlüyü"}, "izahat": {"max": 2, "tesvir": "İzahın keyfiyyəti"}, "subut": {"max": 2, "tesvir": "Sübutun tamlığı"}}'::jsonb,
    true, 18),
(NULL, 'essay', 'Azərbaycanda inflyasiya haqqında araşdırma aparın. Son 3 ilin faizlərini tapın, cədvəl və qrafik hazırlayın. Gələn il üçün proqnoz verin', '"Araşdırma layihəsi"', 'Real həyat tədqiqatı', 10, 0.85, 0.80, 'yaratma', 4, 'Faizlər', ARRAY['faiz', 'layihə', 'tədqiqat', '6-cı sinif'],
    '{"melumat_toplama": {"max": 2}, "cedvel_qrafik": {"max": 3}, "tehlil": {"max": 3}, "proqnoz": {"max": 2}}'::jsonb,
    true, 19),
(NULL, 'essay', 'Məktəbiniz üçün Faiz Olimpiadası hazırlayın: 10 sual, hər səviyyədən. Rubrik və cavab açarı ilə', '"Olimpiada layihəsi"', 'Yaradıcı tapşırıq', 10, 0.85, 0.80, 'yaratma', 4, 'Faizlər', ARRAY['faiz', 'olimpiada', 'yaratma', '6-cı sinif'],
    '{"sual_keyfiyyeti": {"max": 4}, "seviyeleme": {"max": 2}, "rubrik": {"max": 2}, "cavab_acari": {"max": 2}}'::jsonb,
    true, 20);

-- ═══════════════════════════════════════════════
-- 2. RİYAZİYYAT 7-ci sinif — XƏTTİ FUNKSİYA
-- ═══════════════════════════════════════════════

INSERT INTO lesson_plans (
    teacher_id, subject_id, plan_type, title, topic,
    duration_minutes, bloom_levels, dok_level,
    objectives, warm_up, main_activity,
    differentiation, materials, teaching_methods,
    ai_generated, status
)
SELECT
    t.id, s.id, 'daily',
    'Xətti Funksiya — y = kx + b',
    'Xətti funksiya',
    45,
    ARRAY['anlama', 'tətbiqetmə', 'təhlil'],
    3,
    '[
        {"text": "Funksiya anlayışını izah edir, giriş-çıxış əlaqəsini göstərir", "bloom": "anlama", "dok": 2},
        {"text": "y=kx+b funksiyasının cədvəlini tərtib edir və qrafikini qurur", "bloom": "tətbiqetmə", "dok": 2},
        {"text": "k və b parametrlərinin qrafikə təsirini təhlil edir", "bloom": "təhlil", "dok": 3}
    ]'::jsonb,
    'Taksi tarifi: 2 AZN + 0.80 AZN/km. Müxtəlif məsafələr üçün cədvəl, qanunauyğunluq tapmaq',
    'Funksiya anlayışı, y=kx+b, k=maillik, b=başlanğıc, cədvəl tərtibatı, qrafik qurma',
    '{"zeif": "Hazır cədvəl, nöqtələri birləşdirmə, 3 tapşırıq",
      "orta": "Standart plan, 8 tapşırıq",
      "yuksek": "İnternet tarif tədqiqatı, boy-ayaq ölçüsü korrelyasiyası layihəsi"}'::jsonb,
    ARRAY['Koordinat kağızı', 'Xətkeş', 'Rəngli qələmlər', 'Kalkulyator'],
    ARRAY['Inquiry-based Learning', 'Visual Discovery'],
    true, 'approved'
FROM teachers t, subjects s
WHERE t.email = 'aynur@demo.edu.az' AND s.code = 'RIYAZ'
LIMIT 1;

-- Xətti funksiya tapşırıqları
INSERT INTO questions (assessment_id, question_type, question_text, correct_answer, explanation, points, difficulty, discrimination, bloom_level, dok_level, topic, tags, ai_generated, position)
VALUES
(NULL, 'short_answer', 'y = 3x + 1 funksiyasında k və b-ni müəyyən edin', '"k=3, b=1"', 'k maillik, b y-kəsişmə', 2, 0.20, 0.35, 'anlama', 1, 'Xətti funksiya', ARRAY['funksiya', '7-ci sinif'], true, 1),
(NULL, 'short_answer', 'y = -2x + 5 artan yoxsa azalandır? Niyə?', '"Azalan, çünki k=-2<0"', 'k<0 olduqda funksiya azalır', 2, 0.30, 0.40, 'anlama', 2, 'Xətti funksiya', ARRAY['funksiya', '7-ci sinif'], true, 2),
(NULL, 'essay', 'y=2x-3 üçün cədvəl doldurun (x=-2,-1,0,1,2,3) və qrafik qurun', '"(-2,-7),(-1,-5),(0,-3),(1,-1),(2,1),(3,3)"', 'Cədvəl+qrafik', 5, 0.40, 0.55, 'tətbiqetmə', 2, 'Xətti funksiya', ARRAY['funksiya', 'qrafik', '7-ci sinif'], true, 5),
(NULL, 'essay', 'İki taksi: A: 3AZN+0.60/km, B: 1AZN+0.90/km. Hansı km-dən sonra B bahalı olur?', '"3+0.6x = 1+0.9x → x=6.67km"', 'Tənliklər sistemi ilə həll', 8, 0.65, 0.70, 'təhlil', 3, 'Xətti funksiya', ARRAY['funksiya', 'real həyat', '7-ci sinif'], true, 11),
(NULL, 'essay', 'İnternet provayderləri araşdırın, tarifləri funksiya kimi yazın, müqayisə edin', '"Tədqiqat layihəsi"', 'Real data ilə funksiya analizi', 10, 0.80, 0.80, 'yaratma', 4, 'Xətti funksiya', ARRAY['funksiya', 'layihə', '7-ci sinif'],
    true, 12);

-- ═══════════════════════════════════════════════
-- 3. AZƏRBAYCAN DİLİ 5-ci sinif — NİTQ HİSSƏLƏRİ
-- ═══════════════════════════════════════════════

INSERT INTO lesson_plans (
    teacher_id, subject_id, plan_type, title, topic,
    duration_minutes, bloom_levels, dok_level,
    objectives, warm_up, main_activity,
    teaching_methods, ai_generated, status
)
SELECT
    (SELECT id FROM teachers WHERE specialization = 'Azərbaycan dili' LIMIT 1),
    s.id, 'daily',
    'Nitq Hissələri — İsim, Sifət, Fel',
    'Nitq hissələri',
    45,
    ARRAY['xatırlama', 'anlama', 'tətbiqetmə'],
    2,
    '[
        {"text": "İsim, sifət və feli tanıyır və fərqləndirir", "bloom": "xatırlama", "dok": 1},
        {"text": "Verilmiş cümlədə nitq hissələrini müəyyən edir", "bloom": "anlama", "dok": 2},
        {"text": "Nitq hissələrindən istifadə edərək cümlə qurur", "bloom": "tətbiqetmə", "dok": 2}
    ]'::jsonb,
    'Oyun: Söz ovu — sinifə baxıb əşyaları sadalamaq (İsim), təsvir etmək (Sifət), hərəkət (Fel)',
    'Nitq hissələri cədvəli, Qrup işi: Cümlə fabrikası — 15 söz kartı ilə cümlə qurmaq',
    ARRAY['Gamification', 'Cooperative Learning'],
    true, 'approved'
FROM subjects s WHERE s.code = 'AZ_DIL'
LIMIT 1;

-- Nitq hissələri tapşırıqları
INSERT INTO questions (assessment_id, question_type, question_text, correct_answer, explanation, points, difficulty, discrimination, bloom_level, dok_level, topic, tags, ai_generated, position)
VALUES
(NULL, 'matching', 'Sözləri qruplara ayırın: dağ, yaşıl, qaçır, çay, gözəl, yazır, Bakı, ağıllı, düşünür, sevgi', '{"isim":["dağ","çay","Bakı","sevgi"],"sifət":["yaşıl","gözəl","ağıllı"],"fel":["qaçır","yazır","düşünür"]}'::jsonb, 'Nitq hissələrinin təyini', 3, 0.25, 0.40, 'xatırlama', 1, 'Nitq hissələri', ARRAY['isim','sifət','fel','5-ci sinif'], true, 1),
(NULL, 'essay', '"Gözəl qız bağda oynayır" cümləsindəki isim, sifət və feli göstərin', '"İsim: qız, bağ. Sifət: gözəl. Fel: oynayır"', 'Cümlə təhlili', 3, 0.30, 0.45, 'anlama', 1, 'Nitq hissələri', ARRAY['isim','sifət','fel','5-ci sinif'], true, 2),
(NULL, 'essay', '"Gözəllik" sözü sifətdir — Doğru/Yanlış? İzah edin', '"Yanlışdır. -lıq,-lik şəkilçisi ilə sifətdən düzəlmiş isimdir"', 'Söz yaradıcılığı', 3, 0.50, 0.55, 'anlama', 2, 'Nitq hissələri', ARRAY['isim','sözdüzəltmə','5-ci sinif'], true, 4),
(NULL, 'essay', '"Yaşıl" sözü: a) "Yaşıl yarpaq düşdü" b) "Hər tərəf yaşıla bürünüb" c) "Yaşıllıq gözəl idi" — hər birində hansı nitq hissəsidir?', '"a) sifət, b) isim (substantivləşmiş), c) isim (-lıq ilə)"', 'Kontekstə görə nitq hissəsi dəyişir', 7, 0.65, 0.70, 'təhlil', 3, 'Nitq hissələri', ARRAY['sifət','substantivləşmə','5-ci sinif'], true, 9),
(NULL, 'essay', 'Mənim sevimli fəslim mövzusunda esse yazın (150-200 söz). Hər abzasda ≥3 sifət, ≥2 fel, ≥2 isim. Rəngli qələmlə fərqləndir, cədvəldə say', '"Yaradıcı esse + nitq hissəsi analizi"', 'Yazma + qrammatik analiz', 10, 0.75, 0.75, 'yaratma', 4, 'Nitq hissələri', ARRAY['esse','yaratma','5-ci sinif'],
    true, 12);

-- ═══════════════════════════════════════════════
-- 4. FİZİKA 7-ci sinif — QÜVVƏ
-- ═══════════════════════════════════════════════

INSERT INTO questions (assessment_id, question_type, question_text, correct_answer, explanation, points, difficulty, discrimination, bloom_level, dok_level, topic, tags, ai_generated, position)
VALUES
(NULL, 'short_answer', 'Qüvvənin SI ölçü vahidi nədir?', '"Nyuton (N)"', 'Əsas fiziki kəmiyyət', 1, 0.15, 0.30, 'xatırlama', 1, 'Qüvvə', ARRAY['qüvvə','nyuton','7-ci sinif'], true, 1),
(NULL, 'essay', 'Niyə avtomobil qəfil dayandıqda sərnişinlər irəli atılır?', '"Ətalət qanunu — Nyuton I. Cisim hərəkət vəziyyətini saxlamağa meyllidir"', 'Nyuton I qanunu tətbiqi', 3, 0.35, 0.45, 'anlama', 2, 'Qüvvə', ARRAY['ətalət','nyuton','7-ci sinif'], true, 3),
(NULL, 'numeric', 'F=ma: m=5kq, a=3m/s². F=?', '15', 'F = 5×3 = 15 N', 3, 0.35, 0.50, 'tətbiqetmə', 2, 'Qüvvə', ARRAY['nyuton II','hesablama','7-ci sinif'], true, 5),
(NULL, 'numeric', '60 kq kütləli insanın Yerdəki çəkisi? (g=10)', '600', 'P = mg = 60×10 = 600 N', 3, 0.40, 0.50, 'tətbiqetmə', 2, 'Qüvvə', ARRAY['çəki','hesablama','7-ci sinif'], true, 7),
(NULL, 'essay', 'Futbol topuna və basketbol topuna eyni qüvvə vurulur. Niyə futbol topu daha uzağa gedir?', '"Nyuton II: a=F/m. Futbol topunun kütləsi az → təcil çox → uzağa gedir"', 'Nyuton II qanununun real tətbiqi', 7, 0.60, 0.70, 'təhlil', 3, 'Qüvvə', ARRAY['nyuton II','təhlil','7-ci sinif'], true, 9),
(NULL, 'essay', 'Eksperiment: Müxtəlif səthlərddə (parket, xalça, plitka) sürtünmə qüvvəsini ölçün. Cədvəl, qrafik, nəticə yazın', '"Eksperiment layihəsi"', 'Praktik tədqiqat', 10, 0.80, 0.80, 'yaratma', 4, 'Qüvvə', ARRAY['sürtünmə','eksperiment','7-ci sinif'], true, 12);

-- ═══════════════════════════════════════════════
-- TOPLAM STATİSTİKA
-- ═══════════════════════════════════════════════
-- Riyaziyyat 6 (Faizlər): 20 sual, 4 səviyyə
-- Riyaziyyat 7 (Funksiya): 5 sual, 4 səviyyə
-- Azərbaycan dili 5 (Nitq): 5 sual, 4 səviyyə
-- Fizika 7 (Qüvvə): 6 sual, 4 səviyyə
-- Cəmi: 36 sual + 4 dərs planı
