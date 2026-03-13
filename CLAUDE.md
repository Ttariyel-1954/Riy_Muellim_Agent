# CLAUDE.md — Riy_Muellim_Agent: Dərs Planı Generasiya Modulunun Əsaslı Təkmilləşdirilməsi

## 📋 LAYİHƏ KONTEKSTİ

**Layihə:** Riy_Muellim_Agent v3.1 — Azərbaycan Riyaziyyat Müəllimləri üçün AI Köməkçi
**Texnoloji stek:** R Shiny + Claude API (Sonnet/Opus) + PostgreSQL
**İstifadəçilər:** 22 məktəb və gimnaziyanın 1-11-ci sinif riyaziyyat müəllimləri
**Kurikulum:** Azərbaycan Respublikası Riyaziyyat fənni üzrə kurikulum (254 mövzu, 178 standart)

## 🎯 PROBLEM TƏSVİRİ

Hazırkı dərs planı generasiya modulu aşağıdakı **kritik qüsurları** ehtiva edir:

1. **Dərs planları səthi və qısa yazılır** — müəllimə praktiki dəyər verəcək dərinlik yoxdur
2. **Beynəlxalq qiymətləndirmə standartları (TIMSS, PIRLS, PISA, EGRA) nəzərə alınmır**
3. **Dünya təhsil liderlərinin riyazi təhsil yanaşmaları inteqrasiya olunmur** (Sinqapur, Finlandiya, Yaponiya, Cənubi Koreya, Estoniya, Kanada)
4. **Aşağı siniflərdə (1-4) STEAM yanaşmalarına demək olar ki, yer verilmir**

## ✅ İCRA TƏLİMATLARI

### Addım 1: Mövcud Strukturun Analizi

Aşağıdakı faylları tap və oxu:
- Dərs planı generasiya üçün prompt/system message olan R faylı (adətən `app.R`, `server.R`, və ya `modules/` qovluğunda)
- Claude API çağırışı olan funksiyalar
- PostgreSQL-dən kurikulum məlumatlarını çəkən sorğular
- UI-da dərs planı bölməsini göstərən hissə

```bash
# Layihə strukturunu öyrən
find . -name "*.R" -o -name "*.r" | head -50
grep -rl "lesson_plan\|ders_plan\|dərs.*plan" --include="*.R" .
grep -rl "claude\|anthropic\|api.*message" --include="*.R" .
grep -rl "system.*prompt\|system_message\|system_content" --include="*.R" .
```

### Addım 2: Yeni Dərs Planı Prompt Arxitekturası

Mövcud system prompt-u aşağıdakı **yeni genişləndirilmiş versiya** ilə əvəz et. Bu prompt Claude API-yə göndərilən `system` mesajıdır.

**MÜHÜM:** Prompt Azərbaycan dilində olmalıdır, çünki müəllimlər Azərbaycan dilində işləyir.

---

#### YENİ SYSTEM PROMPT (dərs planı generasiyası üçün):

```
Sən Azərbaycan Respublikasının 1-11-ci sinif riyaziyyat müəllimləri üçün peşəkar dərs planı yazan ekspert metodistdir. Sənin yazdığın dərs planları beynəlxalq standartlara cavab verən, ətraflı, praktiki tətbiqə yararlı sənədlərdir.

## DƏRS PLANI STRUKTURU

Hər dərs planı mütləq aşağıdakı bölmələri əhatə etməlidir:

### 1. ÜMUMİ MƏLUMAT
- Sinif, fənn, mövzu, tarix, müddət (45 dəqiqə)
- Kurikulum standart(lar)ı — standart kodu və tam mətni
- Alt-standartlar (əgər varsa)
- Mövzunun kurikulumdakı yeri (əvvəlki və sonrakı mövzularla əlaqə)

### 2. BEYNƏLXALQ UYĞUNLUQ VƏ ƏSASLANDIRMA
Bu bölmədə mövzunun beynəlxalq qiymətləndirmə çərçivələri ilə əlaqəsini göstər:

**TIMSS (Trends in International Mathematics and Science Study):**
- TIMSS kontekt domenləri: Ədəd, Həndəsə, Məlumat və Ehtimal, Cəbr
- TIMSS koqnitiv domenlər: Bilmək (Knowing), Tətbiq etmək (Applying), Mühakimə yürütmək (Reasoning)
- Bu mövzu TIMSS-in hansı domen və koqnitiv səviyyəsinə uyğun gəlir — konkret göstər
- TIMSS-dən nümunə tapşırıq tipini təsvir et

**PISA (Programme for International Student Assessment):**
- PISA riyazi savadlılıq çərçivəsi: Formulasiya, Tətbiq, Şərh/Qiymətləndirmə
- PISA kontekstlər: Şəxsi, Peşəkar, Sosial, Elmi
- PISA riyazi bacarıq səviyyələri (1-6)
- Bu dərsdəki tapşırıqların hansı PISA kontekstinə və bacarıq səviyyəsinə uyğun gəldiyini göstər
- Real həyat kontekstli PISA tipli tapşırıq nümunəsi ver

**PIRLS (əsasən 1-4-cü siniflər üçün):**
- Riyazi mətnlərin oxunması və anlaşılması ilə əlaqəli bacarıqlar
- Riyazi terminologiyanın düzgün istifadəsi
- Məsələ mətni oxuma və anlama bacarıqları

**EGRA (Early Grade Reading/Mathematics Assessment — 1-3-cü siniflər):**
- Ədəd tanıma, müqayisə, əməliyyatlar bacarıqları
- Sözlü hesablama sürəti

### 3. BEYNƏLXALQ YAXŞI TƏCRÜBƏLƏRİN İNTEQRASİYASI
Bu mövzunu tədris edərkən dünya təhsil liderlərinin yanaşmalarını nəzərə al:

**Sinqapur modeli (CPA — Concrete-Pictorial-Abstract):**
- **Konkret (əşyavi):** Hansı manipulyativlər/əyani vasitələr istifadə olunmalıdır? (məsələn: sayğac çubuqları, onluq bloklar, kəsrlər lövhəsi, geoboard, tangram)
- **Təsviri (şəkilli):** Hansı vizual modellər çəkilməlidir? (ədəd xətti, ləçək diaqramı, bar modeli, cədvəl, qrafik)
- **Mücərrəd (simvolik):** Riyazi simvol və formulaya keçid necə edilir?
- Sinqapur "Bar Model" metodu ilə məsələ həlli nümunəsi (əgər uyğundursa)
- "Anchor Task" yanaşması — əsas tapşırıq ətrafında dərsin qurulması

**Finlandiya yanaşması:**
- Fenomen əsaslı öyrənmə (Phenomenon-Based Learning) — bu mövzu hansı real həyat fenomeni ilə əlaqələndirilə bilər?
- Oyun əsaslı öyrənmə elementləri (xüsusilə 1-6-cı siniflər)
- Şagird muxtariyyəti — fərqli həll yolları üçün azadlıq
- 15 dəqiqəlik tənəffüs/hərəkət fasilələri

**Yaponiya yanaşması (Lesson Study — 授業研究):**
- "Hatsumon" — açıq sual strategiyası: dərsin əvvəlində düşündürücü sual
- "Kikan-shido" — müəllimin sinif boyu gəzərək fərdi müşahidə
- "Neriage" — müxtəlif həll yollarının müzakirəsi və müqayisəsi
- "Matome" — dərsin sonunda ümumiləşdirmə və əsas ideyanın vurğulanması
- "Bansho" — lövhədə planlaşdırılmış yazı strategiyası

**Cənubi Koreya yanaşması:**
- Texnologiya inteqrasiyası (rəqəmsal alətlər, interaktiv lövhə)
- Rəqabət və əməkdaşlıq balansı
- Çoxlu təmrin (deliberate practice) ilə ustalığa nail olma

**Estoniya modeli:**
- Rəqəmsal savadlılıq inteqrasiyası
- Proqramlaşdırma elementləri riyaziyyatda (xüsusilə 5-11-ci siniflər)
- Fərdləşdirilmiş öyrənmə marşrutları

### 4. ÖYRƏNMƏNİN NƏTİCƏLƏRİ (DƏQİQ VƏ ÖLÇÜLƏBİLƏN)
SMART formatında (Specific, Measurable, Achievable, Relevant, Time-bound):
- **Bilik səviyyəsi:** Şagird nəyi biləcək? (minimum 2 nəticə)
- **Bacarıq səviyyəsi:** Şagird nəyi edə biləcək? (minimum 2 nəticə)
- **Tətbiq səviyyəsi:** Şagird harada istifadə edə biləcək? (minimum 1 nəticə)
- Hər nəticənin TIMSS koqnitiv domen əlaqəsini göstər (Bilmək/Tətbiq/Mühakimə)
- Bloom taksonomiyası səviyyəsini göstər

### 5. STEAM İNTEQRASİYASI

**Bu bölmə 1-6-cı siniflər üçün MƏCBURI, 7-11-ci siniflər üçün tövsiyə olunandır.**

Hər dərs planında mövzu ilə əlaqəli STEAM (Science, Technology, Engineering, Arts, Mathematics) komponentləri:

**S — Elm (Science):**
- Bu riyazi konsepsiya hansı təbiət hadisəsini izah edir?
- Ölçmə, müqayisə, qruplaşdırma ilə hansı elmi təcrübə aparıla bilər?
- Nümunə: Həndəsik fiqurları təbiətdə tapma (pətəklərdə altıbucaq, gül ləçəklərində simmetriya)

**T — Texnologiya (Technology):**
- Hansı rəqəmsal alətlər istifadə oluna bilər? (GeoGebra, Khan Academy, Photomath, kalkulyator)
- Kodlaşdırma/alqoritmik düşüncə əlaqəsi (Scratch, code.org)
- QR kodlar, interaktiv lövhə, planşet tətbiqləri

**E — Mühəndislik (Engineering):**
- Layihə-əsaslı tapşırıq: "Tikin/Yarat/Dizayn et" tipli fəaliyyət
- Problem həlli dövrü: Müəyyənləşdir → Planla → Yarat → Sına → Təkmilləşdir
- Nümunə: Müəyyən perimetrlə maksimal sahəli bağça dizaynı (4-cü sinif)

**A — İncəsənət (Arts):**
- Riyazi anlayışların vizual sənət vasitəsilə ifadəsi
- Simmetriya, naxış, fraktal — dekorativ sənət əlaqəsi
- Musiqi və riyaziyyat (ritm, vuruş, kəsr əlaqəsi)
- Nümunə: Həndəsik fiqurlardan ornament yaratma

**M — Riyaziyyat (Mathematics):**
- Fənlərarası əlaqə: Bu mövzu digər fənlərlə (fizika, coğrafiya, biologiya, iqtisadiyyat) necə əlaqəlidir?
- Real həyat tətbiqi misalları (bazarda, mətbəxdə, idmanda, tikintidə)

### 6. DƏRS GEDİŞİ (DƏQİQƏLİK PLAN)

Tam 45 dəqiqəlik dərsin addım-addım gedişi:

**a) Motivasiya/Başlanğıc mərhələsi (5-7 dəqiqə):**
- Açıq sual (Yaponiya "Hatsumon" prinsipi)
- Real həyatdan giriş situasiyası
- Əvvəlki biliklərin aktivləşdirilməsi — konkret suallar
- STEAM əlaqəsi olan maraqlı fakt və ya demonstrasiya

**b) Yeni biliklərin kəşfi/Tədqiqat mərhələsi (12-15 dəqiqə):**
- Sinqapur CPA ardıcıllığı ilə keçid:
  1. Əşyavi (Concrete): 3-5 dəqiqə — manipulyativlərlə iş
  2. Təsviri (Pictorial): 3-5 dəqiqə — vizual modelləşdirmə
  3. Mücərrəd (Abstract): 3-5 dəqiqə — simvolik yazılışa keçid
- Müəllimin izahı + şagirdlərin fəal iştirakı
- Lövhədəki planlaşdırılmış yazı (Bansho strategiyası)
- Açar suallar siyahısı (ən azı 5 sual)
- Gözlənilən tipik şagird səhvləri və onların aradan qaldırılması yolları

**c) Praktika/Möhkəmləndirmə mərhələsi (12-15 dəqiqə):**
- Rəhbərli təcrübə (guided practice) — 2-3 nümunə birlikdə
- Müstəqil təcrübə — fərdi iş
- Qrup/cüt iş — əməkdaşlıq tapşırığı
- Differensiasiya:
  - 🟢 **Əsas səviyyə** (bütün şagirdlər üçün): 3-4 tapşırıq
  - 🟡 **Orta səviyyə** (əksər şagirdlər üçün): 2-3 tapşırıq
  - 🔴 **Yüksək səviyyə** (istedadlı şagirdlər üçün): 1-2 çağırıcı tapşırıq
- Hər səviyyə üçün TIMSS koqnitiv domen göstəricisi

**d) STEAM Praktikası (5-7 dəqiqə — xüsusilə 1-6-cı siniflər):**
- Mini layihə, təcrübə, və ya yaradıcı fəaliyyət
- Fənlərarası əlaqəli tapşırıq
- Texnologiya istifadəsi elementi (əgər mümkündürsə)

**e) Qiymətləndirmə/Refleksiya (5 dəqiqə):**
- "Çıxış bileti" (Exit Ticket) — 2-3 qısa sual
- Şagirdlərin özünüqiymətləndirməsi (trafik işığı: yaşıl/sarı/qırmızı)
- Dərsin əsas ideyasının ümumiləşdirilməsi (Yaponiya "Matome")
- Ev tapşırığının təqdimi (differensiyalaşdırılmış)

### 7. QİYMƏTLƏNDİRMƏ ALƏTLƏRİ

**Formativ qiymətləndirmə (dərs zamanı):**
- Mini-lövhə cavabları
- "Baş barmaq" texnikası (başa düşdüm/az-az/başa düşmədim)
- Cüt müzakirə-paylaşım (Think-Pair-Share)
- Müəllimin müşahidə qeydləri üçün yoxlama siyahısı

**Summativ qiymətləndirmə (ev tapşırığı/test):**
- TIMSS formatında test sualı nümunəsi (çoxseçimli + açıq cavablı)
- PISA formatında kontekst əsaslı tapşırıq
- Rubrika (qiymətləndirmə meyarları)

### 8. RESURSLARVASİLƏLƏR
- Zəruri əyani vasitələr siyahısı (manipulyativlər, iş vərəqləri)
- Rəqəmsal resurslar (link/tətbiq adları)
- Müəllim üçün əlavə oxu materialları
- Valideyn əlaqəsi — bu mövzuda evdə nə edə bilərlər

### 9. İNKLÜZİV TƏDRİS UYĞUNLAŞDIRMALARI
- Xüsusi ehtiyaclı şagirdlər üçün uyğunlaşdırmalar
- Dil dəstəyi tədbirləri (riyazi terminologiya lüğəti)
- İstedadlı şagirdlər üçün genişləndirmə tapşırıqları

### 10. MÜƏLLİM ÜÇÜN QEYDLƏR VƏ TÖVSİYƏLƏR
- Bu mövzunu tədris edərkən diqqət yetiriləcək ən vacib məqamlar
- Ən çox rast gəlinən şagird anlaşılmazlıqları (misconceptions) və onların həlli
- Alternativ tədris strategiyaları
- Dərs plan variantları (zəif sinif / güclü sinif üçün)
```

---

### Addım 3: Sinif Səviyyəsinə Görə Prompt Differensiasiyası

System prompt-a əlavə olaraq, **sinif parametrinə görə** aşağıdakı kontekst əlavə et:

```r
# R kodunda sinif səviyyəsinə görə əlavə kontekst
get_grade_context <- function(grade) {
  if (grade >= 1 && grade <= 4) {
    return("
## SİNİF SEVİYƏSİ KONTEKST: İBTİDAİ (1-4)
- STEAM inteqrasiyası MƏCBURI və geniş olmalıdır (minimum 7-10 dəqiqə)
- Sinqapur CPA modeli tam tətbiq olunmalıdır (hər üç mərhələ)
- Oyun əsaslı öyrənmə elementləri daxil edilməlidir (minimum 2 oyun/fəaliyyət)
- TIMSS 4-cü sinif çərçivəsinə uyğunluq
- EGRA/EGMA uyğunluğu göstərilməlidir
- PIRLS ilə riyazi mətn oxuma əlaqəsi qurulmalıdır
- Fiziki hərəkət/kinestetik fəaliyyətlər daxil edilməlidir (say-say tullan, əl çal, ritmik say)
- Manipulyativlər: sayğac çubuqları, onluq bloklar, rəngli fişlər, tangram, pattern blocks, geoboard
- Hekayə əsaslı məsələlər (story problems) Azərbaycan mədəni kontekstində
- Mahnı, şeir, nağıl vasitəsilə riyazi anlayışların möhkəmləndirilməsi
- Müddət: konkret mərhələyə əlavə vaxt (CPA-da 'C' üçün 5-7 dəqiqə)
- Finlandiya: mütləq 15 dəqiqədən sonra qısa hərəkət fasiləsi
")
  } else if (grade >= 5 && grade <= 7) {
    return("
## SİNİF SEVİYƏSİ KONTEKST: ORTA (5-7)
- STEAM inteqrasiyası güclü tövsiyə olunur (5-7 dəqiqə)
- CPA modelinin Pictorial və Abstract mərhələlərinə vurğu
- TIMSS 8-ci sinif çərçivəsinə hazırlıq
- PISA riyazi savadlılıq çərçivəsinə giriş
- Cəbri düşüncənin inkişafı (pattern → generalization → formula)
- Mühəndislik dizayn prosesi əsaslı layihə tapşırıqları
- GeoGebra, Desmos kimi rəqəmsal alətlər tövsiyə olunur
- Qrup layihələri və poster prezentasiyaları
- Real statistik məlumatlarla iş (Azərbaycan statistikası)
- Proqramlaşdırma əlaqəsi: alqoritm, dövr, şərt anlayışları
")
  } else {
    return("
## SİNİF SEVİYƏSİ KONTEKST: YUXARI (8-11)
- STEAM inteqrasiyası kontekst əsaslıdır
- PISA riyazi savadlılıq tam çərçivəsi tətbiq olunur
- TIMSS Advanced çərçivəsinə uyğunluq
- Abstrakt düşüncə və isbat bacarıqları
- Modelləşdirmə və real həyat tətbiqləri (iqtisadiyyat, fizika, mühəndislik)
- Rəqəmsal alətlər: GeoGebra, Desmos, Python/R ilə data analizi
- Cənubi Koreya: deliberate practice ilə imtahan hazırlığı
- Estoniya: proqramlaşdırma-riyaziyyat inteqrasiyası
- Universitet hazırlığı perspektivi
- Peşə yönümü — riyaziyyatın istifadə olunduğu peşələr
- Tənqidi düşüncə və arqumentasiya bacarıqları
")
  }
}
```

### Addım 4: Claude API Çağırışının Yenilənməsi

Mövcud API çağırışını tap və aşağıdakı kimi yenilə:

```r
generate_lesson_plan <- function(grade, topic, standard_code, standard_text, subtopics = NULL) {

  grade_context <- get_grade_context(grade)

  # STEAM vurğusu 1-4 üçün daha güclü
  steam_emphasis <- if (grade <= 4) {
    "STEAM bölməsi bu dərs planının ən mühüm hissələrindən biridir. Hər bir STEAM komponenti (S, T, E, A, M) üçün konkret, sinifdə tətbiq oluna bilən fəaliyyət yaz. Minimum 2 əl işi / təcrübə / yaradıcılıq fəaliyyəti daxil et."
  } else if (grade <= 7) {
    "STEAM inteqrasiyası bu sinif səviyyəsində çox vacibdir. Ən azı S, T, E komponentlərindən ikisini ətraflı yaz."
  } else {
    "STEAM inteqrasiyasını real həyat konteksti və peşə yönümü ilə əlaqələndir."
  }

  user_message <- glue::glue("
Aşağıdakı məlumatlar əsasında ƏTRAFLİ və TAM dərs planı yaz:

**Sinif:** {grade}-ci sinif
**Mövzu:** {topic}
**Standart kodu:** {standard_code}
**Standart mətni:** {standard_text}
{if (!is.null(subtopics)) paste0('**Alt-mövzular:** ', paste(subtopics, collapse=', ')) else ''}

{grade_context}

{steam_emphasis}

## MÜHÜM TƏLİMATLAR:
1. Dərs planı ƏTRAFLİ olmalıdır — hər bölmə dolğun yazılmalıdır, qısa başlıqlarla kifayətlənmə
2. TIMSS, PISA, PIRLS uyğunluğunu KONKRET göstər — hansı domen, hansı koqnitiv səviyyə
3. Beynəlxalq yaxşı təcrübələrdən ən azı 3 fərqli ölkənin yanaşmasını inteqrasiya et
4. Tapşırıqları TAM yaz — sual mətni, cavab, izah ilə birlikdə
5. Differensiasiya 3 səviyyədə olmalıdır (əsas, orta, yüksək)
6. Müəllimə birbaşa istifadə üçün hazır material ver — nəzəri deyil, praktiki
7. Azərbaycan mədəni kontekstini nəzərə al (yer adları, yemək, bayramlar, idman, milli dəyərlər)
8. Gözlənilən şagird səhvlərini (misconceptions) ətraflı yaz — minimum 3 tipik səhv
9. Lövhədə yazılacaq qeydləri planla (Bansho strategiyası)
10. Hər tapşırığın TIMSS koqnitiv domenini göstər: [B] Bilmək, [T] Tətbiq, [M] Mühakimə

**FORMAT:** Markdown formatında yaz. Hər bölmə aydın başlıq altında olsun. Cədvəllərdən, siyahılardan, emoji işarələrindən istifadə et.
**HƏCİM:** Minimum 2500 söz. Bu qısa dərs planı deyil, müəllim üçün ətraflı metodiki vəsaitdir.
")

  # Claude API çağırışı
  response <- call_claude_api(
    model = "claude-sonnet-4-20250514",
    system = system_prompt_lesson_plan,  # Yuxarıdakı yeni system prompt
    messages = list(
      list(role = "user", content = user_message)
    ),
    max_tokens = 8000,  # Ətraflı cavab üçün artırılmış limit
    temperature = 0.4   # Yaradıcılıq + dəqiqlik balansı
  )

  return(response)
}
```

### Addım 5: TIMSS/PISA Referans Verilənlər Bazası

PostgreSQL-ə yeni cədvəllər əlavə et (əgər mövcud deyilsə):

```sql
-- TIMSS çərçivə cədvəli
CREATE TABLE IF NOT EXISTS timss_framework (
    id SERIAL PRIMARY KEY,
    grade_level VARCHAR(10),  -- '4' və ya '8'
    content_domain VARCHAR(50),  -- 'Number', 'Geometry', 'Data and Probability', 'Algebra'
    cognitive_domain VARCHAR(20),  -- 'Knowing', 'Applying', 'Reasoning'
    description_az TEXT,  -- Azərbaycan dilində izah
    sample_task_az TEXT,  -- Nümunə tapşırıq
    keywords TEXT[]  -- Axtarış üçün açar sözlər
);

-- PISA çərçivə cədvəli
CREATE TABLE IF NOT EXISTS pisa_framework (
    id SERIAL PRIMARY KEY,
    process VARCHAR(50),  -- 'Formulate', 'Employ', 'Interpret'
    context VARCHAR(30),  -- 'Personal', 'Occupational', 'Societal', 'Scientific'
    proficiency_level INT,  -- 1-6
    description_az TEXT,
    sample_task_az TEXT,
    grade_relevance INT[]  -- Hansı siniflərdə istifadə oluna bilər
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
    steam_component CHAR(1),  -- S, T, E, A, M
    implementation_steps_az TEXT
);

-- STEAM fəaliyyətlər kitabxanası
CREATE TABLE IF NOT EXISTS steam_activities (
    id SERIAL PRIMARY KEY,
    activity_name_az VARCHAR(200),
    grade_range INT4RANGE,
    steam_components CHAR(1)[],  -- ['S','T','E','A','M']
    math_topic VARCHAR(100),
    duration_minutes INT,
    materials_az TEXT,
    procedure_az TEXT,
    learning_outcomes_az TEXT,
    timss_cognitive_domain VARCHAR(20)
);
```

### Addım 6: TIMSS/PISA İlkin Məlumatların Daxil Edilməsi

```sql
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
('4', 'Data and Probability', 'Reasoning', 'Məlumat əsasında nəticə çıxarma; proqnoz vermə; mühakimə', 'Bu diaqrama əsasən gələn ay hansı məhsul daha çox satılacaq? Niyə belə düşünürsən?');

-- TIMSS 8-ci sinif çərçivəsi
INSERT INTO timss_framework (grade_level, content_domain, cognitive_domain, description_az, sample_task_az) VALUES
('8', 'Number', 'Knowing', 'Rasional ədədlər, faiz, nisbət, mütənasiblik; ədəd xassələri', 'İfadəni sadələşdir: 3/4 + 5/6 = ?'),
('8', 'Algebra', 'Knowing', 'Dəyişən, ifadə, tənlik anlayışları; funksiya qrafiki oxuma', 'x + 5 = 12 tənliyini həll et'),
('8', 'Algebra', 'Applying', 'Tənlik və bərabərsizlik qurmaq və həll etmək; funksiya tətbiqləri', 'Əgər taksi xidmətinin başlanğıc qiyməti 3 AZN, hər km üçün 0.5 AZN olarsa, 10 km üçün xərci hesabla'),
('8', 'Algebra', 'Reasoning', 'Qanunauyğunluq ümumiləşdirmə; isbat; qeyri-standart tənlik', 'Sübut et ki, ardıcıl iki tam ədədin cəmi həmişə tək ədəddir'),
('8', 'Geometry', 'Applying', 'Üçbucaq, çevrə, həcm hesablamaları; Pifaqor teoremi tətbiqi', 'Otağın diaqonalını Pifaqor teoremi ilə hesabla: en=3m, uzunluq=4m'),
('8', 'Data and Probability', 'Reasoning', 'Ehtimal hesablamaları; statistik nəticələrin şərhi', '50 şagirddən 30-u futbol oynayır. Təsadüfi seçilən şagirdin futbolçu olma ehtimalı nədir?');

-- PISA çərçivəsi
INSERT INTO pisa_framework (process, context, proficiency_level, description_az, sample_task_az, grade_relevance) VALUES
('Formulate', 'Personal', 2, 'Şəxsi həyatdakı vəziyyəti riyazi modelə çevirmə', 'Cib telefonu tarifini müqayisə et: A tarif (aylıq 10 AZN + hər dəqiqə 0.05 AZN) vs B tarif (aylıq 5 AZN + hər dəqiqə 0.10 AZN). Hansı tarif sənin üçün sərfəlidir?', ARRAY[7,8,9,10,11]),
('Employ', 'Occupational', 3, 'Peşəkar kontekstdə riyazi prosedurların tətbiqi', 'Çörəkxana sahibi 200 çörək bişirmək istəyir. Hər çörək üçün 300g un lazımdırsa, neçə kq un almalıdır? Əgər 1 kq un 1.5 AZN-dirsə, xərci nə qədər olar?', ARRAY[5,6,7,8]),
('Interpret', 'Societal', 4, 'İctimai statistik məlumatların şərhi və tənqidi qiymətləndirilməsi', 'Bu qrafikə görə Bakıdakı havanın temperaturu son 10 ildə necə dəyişib? Bu tendensiyanın davam edəcəyini düşünürsən? Əsaslandır.', ARRAY[8,9,10,11]),
('Formulate', 'Scientific', 5, 'Elmi konteksti riyazi modelə çevirmə', 'Bakteriya koloniyası hər 30 dəqiqədə ikiqat artır. Əgər başlanğıcda 100 bakteriya varsa, 5 saatdan sonra neçə bakteriya olacaq? Eksponensial artım formulası yaz.', ARRAY[9,10,11]);
```

### Addım 7: STEAM Fəaliyyətlər Kitabxanası

```sql
-- 1-4-cü siniflər üçün STEAM fəaliyyətlər
INSERT INTO steam_activities (activity_name_az, grade_range, steam_components, math_topic, duration_minutes, materials_az, procedure_az, learning_outcomes_az, timss_cognitive_domain) VALUES
('Həndəsi Fiqur Şəhəri', '[1,4]', ARRAY['E','A','M'], 'Həndəsi fiqurlar', 10, 'Karton, qayçı, yapışqan, rəngli kağız, hökmdar', '1) Şagirdlər müxtəlif həndəsi fiqurlar kəsir (5 dəq). 2) Fiqurlardan "şəhər" kompozisiyası yaradır (5 dəq). 3) İstifadə etdikləri fiqurları sayır və təsnif edir.', 'Fiqurları tanıyır, xassələrini bilir, yaradıcı şəkildə tətbiq edir', 'Applying'),
('Ritmik Saymaq', '[1,2]', ARRAY['A','M'], 'Ədədlər və saymaq', 5, 'Heç bir material lazım deyil', '1) Müəllim ritm verir (əl çalma). 2) Şagirdlər ritmə uyğun 2-2, 5-5, 10-10 sayır. 3) Ritmləri dəyişdirirlər.', 'Qaydaya uyğun saymaq, musiqi-riyaziyyat əlaqəsi', 'Knowing'),
('Təbiətdə Simmetriya Ovu', '[2,4]', ARRAY['S','A','M'], 'Simmetriya', 7, 'Planşet/telefon (foto çəkmək üçün), iş vərəqi', '1) Şagirdlər məktəb həyətində simmetrik obyektlər tapır (yarpaq, kəpənək şəkli, bina). 2) Foto çəkir. 3) Simmetriya oxunu çəkir.', 'Simmetriyanı real obyektlərdə tanıyır, elm-sənət əlaqəsini görür', 'Reasoning'),
('Kəsr Pizza Mətbəxi', '[3,4]', ARRAY['S','E','A','M'], 'Kəsrlər', 10, 'Dairəvi karton, qayçı, marker', '1) Şagirdlər "pizza" kəsir: yarım, dörddəbir, səkkizdəbir. 2) Kəsrləri müqayisə edir. 3) Kəsrləri toplayır — pizza parçalarını birləşdirir.', 'Kəsr anlayışını əyani şəkildə dərk edir, müqayisə və toplama bacarığı', 'Applying'),
('Kodlaşdırma ilə Naxış', '[2,4]', ARRAY['T','A','M'], 'Qanunauyğunluq', 7, 'Rəngli kublar və ya kağız, iş vərəqi', '1) Müəllim naxış nümunəsi göstərir (qırmızı-mavi-qırmızı-mavi...). 2) Şagirdlər naxışı kodla yazır (Q-M-Q-M). 3) Öz naxışlarını yaradır və yoldaşlarına "kod"u verir.', 'Alqoritmik düşüncə, pattern recognition', 'Reasoning'),
('Ölçmə Olimpiadası', '[1,3]', ARRAY['S','E','M'], 'Uzunluq ölçmə', 10, 'Hökmdar, lent metr, əşyalar', '1) Şagirdlər qruplara bölünür. 2) Hər qrup sinifdəki 5 əşyanı ölçür (uzunluq, en). 3) Nəticələri cədvələ yazır. 4) Qruplar nəticələrini müqayisə edir.', 'Ölçmə bacarıqları, cədvələ yazma, müqayisə', 'Applying');

-- 5-7-ci siniflər üçün STEAM fəaliyyətlər
INSERT INTO steam_activities (activity_name_az, grade_range, steam_components, math_topic, duration_minutes, materials_az, procedure_az, learning_outcomes_az, timss_cognitive_domain) VALUES
('Körpü Mühəndisliyi', '[5,7]', ARRAY['S','T','E','M'], 'Həndəsə, ölçü', 15, 'Spaghetti, marshmallow, lent, hökmdar', '1) Qruplar ən möhkəm körpü dizayn edir. 2) Üçbucaq strukturlarının möhkəmliyini sınayır. 3) Nəticələri cədvəldə müqayisə edir.', 'Həndəsi strukturların möhkəmliyi, mühəndislik dizayn prosesi', 'Reasoning'),
('Məlumat Jurnalisti', '[5,7]', ARRAY['T','A','M'], 'Statistika, diaqram', 10, 'Kağız, hökmdar, kompüter (əgər varsa)', '1) Sinif anketlə məlumat toplayır. 2) Excel və ya əllə diaqram çəkir. 3) Nəticəni "xəbər" kimi təqdim edir.', 'Məlumat toplama, diaqram qurma, şərh etmə bacarığı', 'Applying'),
('GeoGebra ilə Həndəsə Kəşfi', '[5,7]', ARRAY['T','M'], 'Həndəsə', 10, 'Kompüter/planşet, GeoGebra', '1) GeoGebra-da fiqur çəkir. 2) Xassələri dəyişdirərək nəticəni müşahidə edir. 3) Hipotez qurur.', 'Rəqəmsal alətlə kəşf etmə, hipotez qurma', 'Reasoning');

-- 8-11-ci siniflər üçün STEAM fəaliyyətlər
INSERT INTO steam_activities (activity_name_az, grade_range, steam_components, math_topic, duration_minutes, materials_az, procedure_az, learning_outcomes_az, timss_cognitive_domain) VALUES
('Populyasiya Modelləşdirməsi', '[9,11]', ARRAY['S','T','M'], 'Eksponensial funksiya', 10, 'Kompüter, Excel/GeoGebra', '1) Bakteriya artımını modelləşdirir. 2) Eksponensial funksiya qrafiki çəkir. 3) Proqnoz verir.', 'Riyazi modelləşdirmə, elmi kontekstdə tətbiq', 'Reasoning'),
('Maliyyə Savadlılığı Layihəsi', '[8,10]', ARRAY['T','E','M'], 'Faiz, nisbət', 10, 'Kalkulyator, real bank məlumatları', '1) Kredit/depozit faizlərini müqayisə edir. 2) 5 illik proqnoz hesablayır. 3) Ən sərfəli variantı seçir.', 'Faiz hesablamaları, real həyat tətbiqi, maliyyə savadlılığı', 'Applying');
```

### Addım 8: UI Dəyişiklikləri (R Shiny)

Dərs planı UI bölməsində aşağıdakı yeniliklər et:

```r
# 1. Beynəlxalq standart filtri əlavə et
checkboxGroupInput("intl_standards", "Beynəlxalq Standartlar:",
  choices = c(
    "TIMSS" = "timss",
    "PISA" = "pisa",
    "PIRLS" = "pirls",
    "EGRA/EGMA" = "egra"
  ),
  selected = c("timss", "pisa"),
  inline = TRUE
),

# 2. STEAM intensivliyi seçimi
radioButtons("steam_level", "STEAM inteqrasiya səviyyəsi:",
  choices = c(
    "Tam (bütün komponentlər)" = "full",
    "Orta (3 komponent)" = "medium",
    "Əsas (yalnız M + 1)" = "basic"
  ),
  selected = "full"
),

# 3. Beynəlxalq yanaşma seçimi
checkboxGroupInput("intl_approaches", "Beynəlxalq Yanaşmalar:",
  choices = c(
    "Sinqapur CPA" = "singapore",
    "Finlandiya (oyun əsaslı)" = "finland",
    "Yaponiya (Lesson Study)" = "japan",
    "C.Koreya (texnologiya)" = "korea",
    "Estoniya (rəqəmsal)" = "estonia"
  ),
  selected = c("singapore", "japan"),
  inline = TRUE
),

# 4. Dərs planı həcmi seçimi
radioButtons("plan_detail", "Dərs planı ətraflılığı:",
  choices = c(
    "Ətraflı (2500+ söz)" = "detailed",
    "Standart (1500+ söz)" = "standard",
    "Qısa (800+ söz)" = "brief"
  ),
  selected = "detailed"
)
```

### Addım 9: Token və Performans Optimallaşdırması

```r
# max_tokens dəyərini plan həcminə görə tənzimlə
get_max_tokens <- function(plan_detail) {
  switch(plan_detail,
    "detailed" = 8000,
    "standard" = 5000,
    "brief"    = 3000
  )
}

# Cavab vaxtı haqqında istifadəçiyə məlumat
output$generation_info <- renderText({
  detail <- input$plan_detail
  msg <- switch(detail,
    "detailed" = "⏱ Ətraflı dərs planı generasiya olunur... (30-60 saniyə)",
    "standard" = "⏱ Standart dərs planı generasiya olunur... (20-40 saniyə)",
    "brief"    = "⏱ Qısa dərs planı generasiya olunur... (10-20 saniyə)"
  )
  msg
})
```

### Addım 10: Test və Doğrulama

Aşağıdakı test ssenarilarını icra et:

```r
# Test 1: 2-ci sinif — Toplama əməli (STEAM intensive)
test1 <- generate_lesson_plan(
  grade = 2,
  topic = "İkirəqəmli ədədlərin toplanması",
  standard_code = "2.1.1",
  standard_text = "İkirəqəmli ədədləri toplayır"
)
# Yoxla: STEAM bölməsi var? CPA var? TIMSS uyğunluğu var? Minimum 2500 söz?

# Test 2: 5-ci sinif — Kəsrlər (orta STEAM)
test2 <- generate_lesson_plan(
  grade = 5,
  topic = "Adi kəsrlərin müqayisəsi",
  standard_code = "5.2.3",
  standard_text = "Adi kəsrləri müqayisə edir və sıralayır"
)
# Yoxla: PISA konteksti var? GeoGebra istifadəsi var? Differensiasiya var?

# Test 3: 10-cu sinif — Triqonometriya (yuxarı sinif)
test3 <- generate_lesson_plan(
  grade = 10,
  topic = "Triqonometrik funksiyaların qrafiki",
  standard_code = "10.4.2",
  standard_text = "Triqonometrik funksiyaların qrafiklərini çəkir və xassələrini müəyyən edir"
)
# Yoxla: Desmos/GeoGebra var? Real tətbiq var? PISA Level 4-5 tapşırıq var?
```

## ⚠️ KRİTİK QAYDALAR

1. **Mövcud kodu zədələmə** — yalnız dərs planı generasiya bölməsini dəyişdir
2. **Hər dəyişiklikdən sonra tətbiqi işə sal** (`shiny::runApp()`) və yoxla
3. **System prompt Azərbaycan dilində olmalıdır**
4. **API key-ə toxunma** — mövcud `.Renviron` və ya konfiqurasiya faylından oxunsun
5. **PostgreSQL əlaqəsi** — mövcud bağlantı parametrlərindən istifad et
6. **Əgər SQL cədvəlləri artıq mövcuddursa** — `IF NOT EXISTS` istifadə et
7. **Git commit** — hər mənalı dəyişiklikdən sonra commit et:
   ```bash
   git add -A
   git commit -m "feat: Enhanced lesson plan generation with TIMSS/PISA/STEAM integration"
   ```
8. **Yedəkləmə** — dəyişiklikdən əvvəl mövcud faylların surətini çıxar:
   ```bash
   cp app.R app.R.backup
   ```

## 📊 UĞUR METRİKALARI

Aşağıdakıları yoxla:
- [ ] Dərs planı minimum 2500 sözdür (ətraflı rejim)
- [ ] TIMSS koqnitiv domen göstəriciləri ([B], [T], [M]) var
- [ ] PISA kontekst tipləri göstərilib
- [ ] CPA (Concrete-Pictorial-Abstract) ardıcıllığı var
- [ ] STEAM-ın minimum 3 komponenti əhatə olunub (1-4-cü siniflər üçün hamısı)
- [ ] 3 səviyyəli differensiasiya var
- [ ] Minimum 3 beynəlxalq yanaşma inteqrasiya olunub
- [ ] Tapşırıqlar tam yazılıb (sual + cavab + izah)
- [ ] Gözlənilən şagird səhvləri (misconceptions) siyahısı var
- [ ] Dəqiqəlik dərs gedişi planı var (45 dəqiqə)
- [ ] Ev tapşırığı differensiyalaşdırılıb
- [ ] Formativ + summativ qiymətləndirmə alətləri var
- [ ] Azərbaycan mədəni konteksti nəzərə alınıb
