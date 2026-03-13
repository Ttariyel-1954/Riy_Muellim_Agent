-- ============================================================
-- TIMSS / PISA / STEAM İlkin Məlumatlar
-- Seed 003
-- ============================================================

-- TIMSS 4-cü sinif çərçivəsi
INSERT INTO timss_framework (grade_level, content_domain, cognitive_domain, description_az, sample_task_az) VALUES
('4', 'Number', 'Knowing', 'Tam ədədlər, kəsrlər, onluq kəsrlər haqqında əsas biliklər; hesablama qaydaları; riyazi faktlar', 'Hesabla: 356 + 247 = ?'),
('4', 'Number', 'Applying', 'Ədəd biliklərinin standart məsələ həllində tətbiqi; ölçmə, pul hesablamaları', 'Əhməd bazardan 3 kq alma aldı. Hər kilosu 2 manat olarsa, nə qədər pul ödədi?'),
('4', 'Number', 'Reasoning', 'Ədədlər arasında qanunauyğunluq tapma; qeyri-standart məsələ həlli; mühakimə', 'Ardıcıllıqdakı növbəti ədədi tap: 2, 6, 18, 54, ...'),
('4', 'Geometry', 'Knowing', 'Həndəsi fiqurların xassələri; xətlər, bucaqlar; simmetriya anlayışı', 'Düzbucaqlının neçə bucağı var? Hər bucaq neçə dərəcədir?'),
('4', 'Geometry', 'Applying', 'Perimetr, sahə hesablanması; fiqurların çəkilməsi; koordinat müstəvisində nöqtə', 'Tərəfləri 5 sm və 3 sm olan düzbucaqlının perimetrini tap'),
('4', 'Geometry', 'Reasoning', 'Fiqurları müqayisə, təsnif etmə; mürəkkəb fiqurlar; fəzavi mühakimə', 'Bu fiqurlardan hansıları simmetrikdir? Niyə?'),
('4', 'Data and Probability', 'Knowing', 'Cədvəl, diaqram oxuma; sadə statistik anlayışlar', 'Cədvəldəki məlumata görə ən çox satılan məhsul hansıdır?'),
('4', 'Data and Probability', 'Applying', 'Məlumat toplamaq, diaqram qurmaq; orta hesabi tapmaq', 'Sinif yoldaşlarının boylarını ölç və sütun diaqramı çək'),
('4', 'Data and Probability', 'Reasoning', 'Məlumat əsasında nəticə çıxarma; proqnoz vermə; mühakimə', 'Bu diaqrama əsasən gələn ay hansı məhsul daha çox satılacaq? Niyə belə düşünürsən?')
ON CONFLICT DO NOTHING;

-- TIMSS 8-ci sinif çərçivəsi
INSERT INTO timss_framework (grade_level, content_domain, cognitive_domain, description_az, sample_task_az) VALUES
('8', 'Number', 'Knowing', 'Rasional ədədlər, faiz, nisbət, mütənasiblik; ədəd xassələri', 'İfadəni sadələşdir: 3/4 + 5/6 = ?'),
('8', 'Algebra', 'Knowing', 'Dəyişən, ifadə, tənlik anlayışları; funksiya qrafiki oxuma', 'x + 5 = 12 tənliyini həll et'),
('8', 'Algebra', 'Applying', 'Tənlik və bərabərsizlik qurmaq və həll etmək; funksiya tətbiqləri', 'Əgər taksi xidmətinin başlanğıc qiyməti 3 AZN, hər km üçün 0.5 AZN olarsa, 10 km üçün xərci hesabla'),
('8', 'Algebra', 'Reasoning', 'Qanunauyğunluq ümumiləşdirmə; isbat; qeyri-standart tənlik', 'Sübut et ki, ardıcıl iki tam ədədin cəmi həmişə tək ədəddir'),
('8', 'Geometry', 'Applying', 'Üçbucaq, çevrə, həcm hesablamaları; Pifaqor teoremi tətbiqi', 'Otağın diaqonalını Pifaqor teoremi ilə hesabla: en=3m, uzunluq=4m'),
('8', 'Data and Probability', 'Reasoning', 'Ehtimal hesablamaları; statistik nəticələrin şərhi', '50 şagirddən 30-u futbol oynayır. Təsadüfi seçilən şagirdin futbolçu olma ehtimalı nədir?')
ON CONFLICT DO NOTHING;

-- PISA çərçivəsi
INSERT INTO pisa_framework (process, context, proficiency_level, description_az, sample_task_az, grade_relevance) VALUES
('Formulate', 'Personal', 2, 'Şəxsi həyatdakı vəziyyəti riyazi modelə çevirmə', 'Cib telefonu tarifini müqayisə et: A tarif (aylıq 10 AZN + hər dəqiqə 0.05 AZN) vs B tarif (aylıq 5 AZN + hər dəqiqə 0.10 AZN). Hansı tarif sənin üçün sərfəlidir?', ARRAY[7,8,9,10,11]),
('Employ', 'Occupational', 3, 'Peşəkar kontekstdə riyazi prosedurların tətbiqi', 'Çörəkxana sahibi 200 çörək bişirmək istəyir. Hər çörək üçün 300g un lazımdırsa, neçə kq un almalıdır? Əgər 1 kq un 1.5 AZN-dirsə, xərci nə qədər olar?', ARRAY[5,6,7,8]),
('Interpret', 'Societal', 4, 'İctimai statistik məlumatların şərhi və tənqidi qiymətləndirilməsi', 'Bu qrafikə görə Bakıdakı havanın temperaturu son 10 ildə necə dəyişib? Bu tendensiyanın davam edəcəyini düşünürsən? Əsaslandır.', ARRAY[8,9,10,11]),
('Formulate', 'Scientific', 5, 'Elmi konteksti riyazi modelə çevirmə', 'Bakteriya koloniyası hər 30 dəqiqədə ikiqat artır. Əgər başlanğıcda 100 bakteriya varsa, 5 saatdan sonra neçə bakteriya olacaq?', ARRAY[9,10,11])
ON CONFLICT DO NOTHING;

-- STEAM fəaliyyətlər: 1-4-cü siniflər
INSERT INTO steam_activities (activity_name_az, grade_min, grade_max, steam_components, math_topic, duration_minutes, materials_az, procedure_az, learning_outcomes_az, timss_cognitive_domain) VALUES
('Həndəsi Fiqur Şəhəri', 1, 4, ARRAY['E','A','M'], 'Həndəsi fiqurlar', 10, 'Karton, qayçı, yapışqan, rəngli kağız, hökmdar', '1) Şagirdlər müxtəlif həndəsi fiqurlar kəsir (5 dəq). 2) Fiqurlardan şəhər kompozisiyası yaradır (5 dəq). 3) İstifadə etdikləri fiqurları sayır və təsnif edir.', 'Fiqurları tanıyır, xassələrini bilir, yaradıcı şəkildə tətbiq edir', 'Applying'),
('Ritmik Saymaq', 1, 2, ARRAY['A','M'], 'Ədədlər və saymaq', 5, 'Heç bir material lazım deyil', '1) Müəllim ritm verir (əl çalma). 2) Şagirdlər ritmə uyğun 2-2, 5-5, 10-10 sayır. 3) Ritmləri dəyişdirirlər.', 'Qaydaya uyğun saymaq, musiqi-riyaziyyat əlaqəsi', 'Knowing'),
('Təbiətdə Simmetriya Ovu', 2, 4, ARRAY['S','A','M'], 'Simmetriya', 7, 'Planşet/telefon (foto çəkmək üçün), iş vərəqi', '1) Şagirdlər məktəb həyətində simmetrik obyektlər tapır (yarpaq, kəpənək şəkli, bina). 2) Foto çəkir. 3) Simmetriya oxunu çəkir.', 'Simmetriyanı real obyektlərdə tanıyır, elm-sənət əlaqəsini görür', 'Reasoning'),
('Kəsr Pizza Mətbəxi', 3, 4, ARRAY['S','E','A','M'], 'Kəsrlər', 10, 'Dairəvi karton, qayçı, marker', '1) Şagirdlər pizza kəsir: yarım, dörddəbir, səkkizdəbir. 2) Kəsrləri müqayisə edir. 3) Kəsrləri toplayır.', 'Kəsr anlayışını əyani şəkildə dərk edir, müqayisə və toplama bacarığı', 'Applying'),
('Kodlaşdırma ilə Naxış', 2, 4, ARRAY['T','A','M'], 'Qanunauyğunluq', 7, 'Rəngli kublar və ya kağız, iş vərəqi', '1) Müəllim naxış nümunəsi göstərir (qırmızı-mavi-qırmızı-mavi). 2) Şagirdlər naxışı kodla yazır (Q-M-Q-M). 3) Öz naxışlarını yaradır.', 'Alqoritmik düşüncə, pattern recognition', 'Reasoning'),
('Ölçmə Olimpiadası', 1, 3, ARRAY['S','E','M'], 'Uzunluq ölçmə', 10, 'Hökmdar, lent metr, əşyalar', '1) Şagirdlər qruplara bölünür. 2) Hər qrup sinifdəki 5 əşyanı ölçür. 3) Nəticələri cədvələ yazır. 4) Qruplar nəticələrini müqayisə edir.', 'Ölçmə bacarıqları, cədvələ yazma, müqayisə', 'Applying')
ON CONFLICT DO NOTHING;

-- STEAM fəaliyyətlər: 5-7-ci siniflər
INSERT INTO steam_activities (activity_name_az, grade_min, grade_max, steam_components, math_topic, duration_minutes, materials_az, procedure_az, learning_outcomes_az, timss_cognitive_domain) VALUES
('Körpü Mühəndisliyi', 5, 7, ARRAY['S','T','E','M'], 'Həndəsə, ölçü', 15, 'Spaghetti, marshmallow, lent, hökmdar', '1) Qruplar ən möhkəm körpü dizayn edir. 2) Üçbucaq strukturlarının möhkəmliyini sınayır. 3) Nəticələri cədvəldə müqayisə edir.', 'Həndəsi strukturların möhkəmliyi, mühəndislik dizayn prosesi', 'Reasoning'),
('Məlumat Jurnalisti', 5, 7, ARRAY['T','A','M'], 'Statistika, diaqram', 10, 'Kağız, hökmdar, kompüter (əgər varsa)', '1) Sinif anketlə məlumat toplayır. 2) Excel və ya əllə diaqram çəkir. 3) Nəticəni xəbər kimi təqdim edir.', 'Məlumat toplama, diaqram qurma, şərh etmə bacarığı', 'Applying'),
('GeoGebra ilə Həndəsə Kəşfi', 5, 7, ARRAY['T','M'], 'Həndəsə', 10, 'Kompüter/planşet, GeoGebra', '1) GeoGebra-da fiqur çəkir. 2) Xassələri dəyişdirərək nəticəni müşahidə edir. 3) Hipotez qurur.', 'Rəqəmsal alətlə kəşf etmə, hipotez qurma', 'Reasoning')
ON CONFLICT DO NOTHING;

-- STEAM fəaliyyətlər: 8-11-ci siniflər
INSERT INTO steam_activities (activity_name_az, grade_min, grade_max, steam_components, math_topic, duration_minutes, materials_az, procedure_az, learning_outcomes_az, timss_cognitive_domain) VALUES
('Populyasiya Modelləşdirməsi', 9, 11, ARRAY['S','T','M'], 'Eksponensial funksiya', 10, 'Kompüter, Excel/GeoGebra', '1) Bakteriya artımını modelləşdirir. 2) Eksponensial funksiya qrafiki çəkir. 3) Proqnoz verir.', 'Riyazi modelləşdirmə, elmi kontekstdə tətbiq', 'Reasoning'),
('Maliyyə Savadlılığı Layihəsi', 8, 10, ARRAY['T','E','M'], 'Faiz, nisbət', 10, 'Kalkulyator, real bank məlumatları', '1) Kredit/depozit faizlərini müqayisə edir. 2) 5 illik proqnoz hesablayır. 3) Ən sərfəli variantı seçir.', 'Faiz hesablamaları, real həyat tətbiqi, maliyyə savadlılığı', 'Applying')
ON CONFLICT DO NOTHING;

-- Beynəlxalq yaxşı təcrübələr
INSERT INTO international_practices (country, approach_name, approach_name_az, description_az, applicable_grades, math_topics, steam_component, implementation_steps_az) VALUES
('Singapore', 'CPA Model', 'Konkret-Təsviri-Mücərrəd', 'Öyrənmə prosesi: əyani vasitələrdən vizual modellərə, sonra simvolik ifadəyə keçid', ARRAY[1,2,3,4,5,6,7], ARRAY['Ədədlər','Kəsrlər','Həndəsə','Cəbr'], 'M', '1) Manipulyativlərlə iş (5 dəq) 2) Şəkil/model çəkmə (5 dəq) 3) Formula/simvola keçid (5 dəq)'),
('Singapore', 'Bar Model', 'Bar Model Metodu', 'Məsələ həllində vizual bar diaqramı ilə kəmiyyətləri göstərmə', ARRAY[2,3,4,5,6,7], ARRAY['Məsələ həlli','Kəsrlər','Faiz','Nisbət'], 'M', '1) Məsələni oxu 2) Bilinən kəmiyyətləri bar ilə göstər 3) Bilinməyəni tap 4) Tənlik qur'),
('Finland', 'Phenomenon-Based Learning', 'Fenomen əsaslı öyrənmə', 'Real həyat fenomeni ətrafında fənlərarası öyrənmə', ARRAY[1,2,3,4,5,6], ARRAY['Ölçmə','Statistika','Həndəsə'], 'S', '1) Real fenomen seç 2) Riyazi tərəfi araşdır 3) Elmi eksperiment 4) Nəticəni təqdim et'),
('Japan', 'Lesson Study', 'Dərs Araşdırması (Jugyou Kenkyuu)', 'Açıq sual → müstəqil araşdırma → müxtəlif həllərin müzakirəsi → ümumiləşdirmə', ARRAY[1,2,3,4,5,6,7,8,9,10,11], ARRAY['Bütün mövzular'], 'M', '1) Hatsumon (açıq sual) 2) Kikan-shido (gəzmə müşahidə) 3) Neriage (həll müzakirəsi) 4) Matome (ümumiləşdirmə)'),
('South Korea', 'Technology Integration', 'Texnologiya İnteqrasiyası', 'Rəqəmsal alətlər və interaktiv platformalarla riyaziyyat tədris', ARRAY[5,6,7,8,9,10,11], ARRAY['Funksiyalar','Həndəsə','Statistika'], 'T', '1) GeoGebra/Desmos ilə vizuallaşdır 2) İnteraktiv tapşırıq 3) Rəqəmsal portfolio'),
('Estonia', 'Digital Literacy', 'Rəqəmsal Savadlılıq', 'Proqramlaşdırma və alqoritmik düşüncə inteqrasiyası', ARRAY[5,6,7,8,9,10,11], ARRAY['Alqoritm','Funksiyalar','Statistika'], 'T', '1) Alqoritm yaz 2) Scratch/Python ilə həll et 3) Data analiz et')
ON CONFLICT DO NOTHING;
