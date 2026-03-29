# Riy Müəllim Agent v3.3

**Azərbaycan Respublikası 1-11-ci sinif riyaziyyat müəllimləri üçün AI agent sistemi**

ARTI 2026 — Azərbaycan Respublikası Təhsil İnstitutu

---

## Haqqında

Riy Müəllim Agent — riyaziyyat müəllimlərinin gündəlik işini asanlaşdıran, beynəlxalq standartlara (TIMSS, PISA, PIRLS) uyğun dərs planları, testlər, şagird analizləri və metodiki materiallar yaradan süni intellekt sistemidir.

Sistem Claude AI (Anthropic) modeli üzərində işləyir və R Shiny interfeysi vasitəsilə müəllimlərə istifadəyə hazır sənədlər təqdim edir.

### Əsas xüsusiyyətlər

- 1-11-ci sinif üçün tam kurikulum dəstəyi (178 standart, 254 mövzu)
- 17 dərslik PDF-dən çıxarılmış 519 chunk bilik bazası
- TIMSS/PISA/PIRLS beynəlxalq çərçivələrə uyğunluq
- Blum taksonomiyası və Sinqapur CPA modeli inteqrasiyası
- HTML5 + DOCX formatında fayl çıxışı
- 3 dildə interfeys: Azərbaycanca, Rusca, İngiliscə
- Real vaxt generasiya statistikası (token, xərc, vaxt)

---

## Sistem Arxitekturası

```
Riy_Muellim_Agent/
├── r_shiny/app/
│   └── app.R                 # R Shiny interfeys (əsas proqram)
├── src/
│   ├── server.js             # Node.js API server
│   ├── core/
│   │   └── ai_engine.js      # Claude + OpenAI multi-model engine
│   ├── agents/
│   │   ├── lesson_planning/  # Dərs planlama agenti
│   │   ├── assessment/       # Qiymətləndirmə agenti
│   │   ├── communication/    # Kommunikasiya agenti
│   │   ├── student_progress/ # Şagird inkişafı agenti
│   │   ├── pedagogical/      # Metodiki kömək agenti
│   │   └── digital_assistant/# Rəqəmsal assistant
│   ├── api/
│   │   └── routes.js         # API endpoint-ları
│   └── middleware/
│       └── auth.js           # JWT autentifikasiya
├── database/
│   ├── migrations/           # PostgreSQL schema
│   └── seeds/                # İlkin verilənlər
├── derslikler/
│   ├── pdf/                  # 17 dərslik PDF (gitignore)
│   ├── chunks/               # 519 chunk (JSON)
│   ├── standards.json        # 178 kurikulum standartı
│   └── topics.json           # Mövzular
├── config/
│   └── database.js           # DB konfiqurasiyası
├── scripts/
│   ├── pdf_pipeline.py       # PDF → chunk pipeline
│   ├── pdf_to_chunks.py      # PDF parçalama
│   ├── search_chunks.py      # Chunk axtarış
│   └── setup.sh              # Quraşdırma skripti
├── Ders_planlari/            # Generasiya olunmuş dərs planları
├── Testler/                  # Generasiya olunmuş testlər
├── Mesajlar/                 # Generasiya olunmuş mesajlar
├── .env.example              # Konfiqurasiya nümunəsi
├── package.json              # Node.js asılılıqlar
├── Dockerfile                # Docker image
├── docker-compose.yml        # Docker compose
└── CLAUDE.md                 # AI agent təlimatı
```

---

## Quraşdırma

### Tələblər

| Komponent | Versiya | Məqsəd |
|-----------|---------|--------|
| R | >= 4.3 | Shiny interfeys |
| Node.js | >= 18 | API server |
| PostgreSQL | >= 14 | Verilənlər bazası (optional) |
| Pandoc | >= 2.19 | DOCX generasiyası |
| Python | >= 3.9 | PDF pipeline (birdəfəlik) |

### R paketləri

```r
install.packages(c(
  "shiny", "shinydashboard", "DT",
  "httr", "jsonlite", "plotly"
))
```

### Addım 1: Klonlama

```bash
git clone https://github.com/Ttariyel-1954/Riy_Muellim_Agent.git
cd Riy_Muellim_Agent
```

### Addım 2: .env faylını yaradın

```bash
cp .env.example .env
```

`.env` faylını redaktə edin:

```env
# Mütləq lazımdır:
ANTHROPIC_API_KEY=sk-ant-api03-YOUR_KEY_HERE

# Optional:
DB_HOST=localhost
DB_PORT=5432
DB_NAME=riy_muellim_agent
DB_USER=your_user
DB_PASSWORD=your_password
SHINY_PORT=4040
DEFAULT_AI_MODEL=claude-sonnet-4-20250514
```

### Addım 3: R Shiny interfeysi işə salın

```bash
cd r_shiny/app
Rscript -e "shiny::runApp('.', port = 4040, host = '0.0.0.0')"
```

Və ya:

```bash
npm run shiny
```

Brauzer: `http://localhost:4040`

### Addım 4: Node.js API (optional)

```bash
npm install
npm run db:setup   # PostgreSQL lazımdır
npm start          # http://localhost:3000
```

---

## Docker ilə işə salma

```bash
docker-compose up -d
```

Bu komanda həm Node.js API-ni (`localhost:3000`), həm PostgreSQL-i (`localhost:5432`), həm də R Shiny-ni işə salır.

---

## İstifadə Təlimatı

### Tab 1: Dərs Planı Generasiyası

Müəllim aşağıdakı parametrləri seçir:

| Parametr | Seçim |
|----------|-------|
| Sinif | 1-11 |
| Mövzu | Kurikulumdan seçim və ya azad daxiletmə |
| Standart | Avtomatik yüklənir (178 standart) |
| Dərs tipi | Yeni mövzu / Möhkəmləndirmə / Qiymətləndirmə |
| Beynəlxalq çərçivə | TIMSS / PISA / PIRLS / Blum / CPA |
| Diferensial təlim | 3 səviyyə (zəif/orta/güclü) |

**Çıxış:** HTML5 + DOCX fayl — dərhal çap üçün hazır, 2500+ söz ətraflı dərs planı.

**Dərs planının strukturu:**

1. Ümumi məlumat (sinif, mövzu, standart, tarix)
2. Təlim nəticələri — Blum taksonomiyasına görə ölçülə bilən feillər
3. Beynəlxalq standart uyğunluğu (TIMSS domen/koqnitiv, PISA prosesi/konteksti)
4. Sinqapur CPA (Concrete → Pictorial → Abstract) ardıcıllığı
5. Yaponiya Lesson Study elementləri (Hatsumon, Kikan-shido, Neriage, Matome)
6. Dəqiqəlik dərs gedişi (45 dəqiqə, 5 mərhələ)
7. Diferensial tapşırıqlar (3 səviyyə, hər birinin TIMSS koqnitiv doməni)
8. STEAM inteqrasiyası (Science, Technology, Engineering, Arts, Mathematics)
9. Formativ qiymətləndirmə alətləri
10. Ev tapşırığı (diferensiyalaşdırılmış)

### Tab 2: Test Generasiyası

TIMSS/PISA formatında testlər yaradır:

- Çoxseçimli suallar (Blum səviyyələri ilə)
- Qısa cavablı suallar
- Açıq suallar (rubrika ilə)
- Həll yolu + izah + dərslik istinad
- Distraktor analizi

**Çətinlik səviyyələri:** Asan → Orta → Çətin → Qarışıq

### Tab 3: Aylıq Plan

Bütöv ay üçün həftəlik cədvəl:
- Hər həftə: mövzu + standart + saat bölgüsü
- PISA/PIRLS uyğunluq göstəricisi
- Formativ/summativ qiymətləndirmə nöqtələri
- Dərs tipi variantları

### Tab 4: Kommunikasiya

Müəllim üçün hazır sənədlər:
- Valideyn məktubu
- İdari hesabat
- Pedaqoji şura çıxışı
- Şagird xasiyyətnaməsi

### Tab 5: Şagird Analizi

Fərdi şagird profili yaradır:
- Güclü/zəif tərəfləri
- TIMSS koqnitiv domen profili
- Fərdiləşdirilmiş tövsiyələr
- Valideyn üçün təklif məktubu

### Tab 6: Standartlar

Bütün kurikulum standartlarını cədvəl şəklində göstərir:
- 178 əsas standart
- Sinifə görə filtrasiya
- Sahəyə görə qruplaşdırma (ədəd, həndəsə, cəbr, statistika)

### Tab 7: Statistika

Generasiya statistikası:
- Vaxt, token sayı, təxmini xərc
- Arxiv cədvəli (keçmiş planlar/testlər)
- HTML və DOCX yükləmə düyməsi

---

## Bilik Bazası

### Dərslik Chunk-ları

17 riyaziyyat dərsliyi (1-11-ci sinif, I və II hissə) PDF formatından parçalanıb JSON chunk-larına çevrilib:

| Sinif | Dərslik | Chunk sayı |
|-------|---------|------------|
| 1 | I hissə + II hissə | ~50 |
| 2 | I hissə + II hissə | ~50 |
| 3 | I hissə + II hissə | ~50 |
| 4 | I hissə + II hissə | ~50 |
| 5 | I hissə + II hissə | ~50 |
| 6 | I hissə + II hissə | ~50 |
| 7 | Tam | ~40 |
| 8 | Tam | ~40 |
| 9 | Tam | ~40 |
| 10 | Tam | ~35 |
| 11 | Tam | ~35 |
| **Cəmi** | **17 PDF** | **519 chunk** |

Hər chunk tərkibi: sinif, hissə, mövzu, sahə, mətn, səhifə aralığı, söz sayı.

### Kurikulum Standartları

178 standart 5 sahə üzrə:

| Sahə | İzah |
|------|------|
| Ədədlər və əməliyyatlar | Natural ədədlər, kəsrlər, onluq kəsrlər, rasional ədədlər |
| Cəbr və funksiyalar | Dəyişənlər, tənliklər, bərabərsizliklər, funksiyalar |
| Həndəsə | Fiqurlar, ölçülər, koordinat, çevirmələr |
| Ölçmə | Uzunluq, sahə, həcm, kütlə, vaxt |
| Statistika və ehtimal | Məlumat toplama, diaqram, orta, ehtimal |

---

## Beynəlxalq Standartlar

### TIMSS İnteqrasiyası

**Kontekt domenlər:** Ədəd, Cəbr, Həndəsə, Məlumat və Ehtimal

**Koqnitiv domenlər:**
- **[B] Bilmək (Knowing):** Faktlar, prosedurlar, anlayışlar
- **[T] Tətbiq etmək (Applying):** Standart məsələ həlli
- **[M] Mühakimə yürütmək (Reasoning):** Qeyri-standart, çoxaddımlı məsələlər

Hər tapşırıq [B], [T], [M] etiketi ilə işarələnir.

### PISA İnteqrasiyası

**Proseslər:** Formulasiya → Tətbiq → Şərh/Qiymətləndirmə

**Kontekstlər:** Şəxsi, Peşəkar, Sosial, Elmi

**Bacarıq səviyyələri:** 1-6 (hər test sualında göstərilir)

### Sinqapur CPA Modeli

Hər dərs planında 3 mərhələ:
1. **Concrete (Əşyavi):** Manipulyativlər — sayğac çubuqları, onluq bloklar, tangram
2. **Pictorial (Təsviri):** Vizual modellər — ədəd xətti, bar modeli, diaqram
3. **Abstract (Mücərrəd):** Riyazi simvol və formulalar

### Yaponiya Lesson Study

- **Hatsumon:** Dərsin əvvəlində düşündürücü sual
- **Kikan-shido:** Fərdi müşahidə, sinif boyu gəzərək
- **Neriage:** Müxtəlif həll yollarının müzakirəsi
- **Matome:** Dərsin sonunda ümumiləşdirmə
- **Bansho:** Lövhədə planlaşdırılmış yazı

---

## API Endpoint-ları

Node.js API (optional, R Shiny müstəqil işləyir):

| Metod | Endpoint | Funksiyası |
|-------|----------|-----------|
| GET | `/api/v1/health` | Sağlamlıq yoxlaması |
| POST | `/api/v1/ders-plani` | Dərs planı generasiyası |
| POST | `/api/v1/test-yarat` | Test generasiyası |
| POST | `/api/v1/aylik-plan` | Aylıq plan |
| POST | `/api/v1/mesaj-yaz` | Mesaj generasiyası |
| POST | `/api/v1/shagird-analiz` | Şagird analizi |
| GET | `/api/v1/arxiv/ders-planlari` | Keçmiş planlar |
| GET | `/api/v1/arxiv/testler` | Keçmiş testlər |

---

## Verilənlər Bazası (PostgreSQL)

### Əsas cədvəllər

| Cədvəl | Məqsəd | Sütun sayı |
|--------|--------|------------|
| `riy_standartlari` | Kurikulum standartları | 11 |
| `riy_movzular` | 254 mövzu | 7 |
| `riy_derslikler` | 519 chunk | 10 |
| `ders_planlari` | Generasiya olunmuş planlar | 10 |
| `testler` | Generasiya olunmuş testlər | 10 |
| `mesajlar` | Mesajlar | 5 |
| `timss_framework` | TIMSS çərçivəsi | 8 |
| `pisa_framework` | PISA çərçivəsi | 7 |
| `steam_activities` | STEAM fəaliyyətlər kitabxanası | 10 |
| `international_practices` | Beynəlxalq yaxşı təcrübələr | 9 |

### Migration

```bash
npm run db:migrate   # Schema yaradır
npm run db:seed      # İlkin məlumatları daxil edir
```

---

## Fayl Çıxışı

Hər generasiya nəticəsi 2 formatda saxlanır:

### HTML5
- Responsive dizayn, mobil uyumlu
- Gradient başlıqlar, rəngli fazalar
- Çap üçün optimizasiya olunmuş (`@media print`)
- İnteraktiv hover effektləri

### DOCX (Word)
- Pandoc vasitəsilə avtomatik çevrilir
- Azərbaycan əlifbası dəstəyi (UTF-8)
- ARTI 2026 altbilgi

### Fayl adlandırma

```
sinif{N}_{movzu_slug}_{tip}_{timestamp}.html
sinif{N}_{movzu_slug}_{tip}_{timestamp}.docx
```

Misal: `sinif7_Nisb_t__m_t_nasiblik_ders_plani_20260303_093906.html`

---

## Konfiqurasiya

### AI Model Seçimi

`.env` faylında:

```env
DEFAULT_AI_MODEL=claude-sonnet-4-20250514
```

Dəstəklənən modellər:
- `claude-sonnet-4-20250514` (default, optimal balans)
- `claude-haiku-4-5-20251001` (sürətli, ucuz)
- `gpt-4o` (OpenAI alternativi)

### Token Limitləri

| Model | Default max_tokens |
|-------|--------------------|
| Claude Sonnet/Opus | 16384 |
| Claude Haiku | 4096 |
| GPT-4o | 16384 |

---

## İnkişaf

### Lokal inkişaf

```bash
# R Shiny (live reload)
cd r_shiny/app
Rscript -e "shiny::runApp('.', port = 4040)"

# Node.js (nodemon ilə)
npm run dev

# PDF pipeline (birdəfəlik)
python3 scripts/pdf_pipeline.py
```

### Layihə strukturuna yeni agent əlavə etmək

1. `src/agents/` altında yeni qovluq yaradın
2. `index.js` faylında agent sinifini yaradın
3. `src/api/routes.js`-ə endpoint əlavə edin
4. `r_shiny/app/app.R`-ə yeni tab əlavə edin

---

## Texnoloji Stek

| Komponent | Texnologiya | Versiya |
|-----------|-------------|---------|
| Frontend | R Shiny + shinydashboard | 1.8.x |
| AI Engine | Claude API (Anthropic) | v2023-06-01 |
| Backend | Node.js + Express | 18+ |
| Database | PostgreSQL | 14+ |
| Vizualizasiya | Plotly.js | 2.x |
| Sənəd generasiyası | Pandoc (HTML → DOCX) | 2.19+ |
| PDF pipeline | Python (PyPDF2, tiktoken) | 3.9+ |
| Konteynerləşdirmə | Docker + Docker Compose | 24+ |

---

## Lisenziya

MIT License — ARTI 2026, Tariyel Talibov

---

## Əlaqə

- **Müəllif:** Tariyel Talibov
- **Təşkilat:** ARTI — Azərbaycan Respublikası Təhsil İnstitutu
- **GitHub:** [Ttariyel-1954/Riy_Muellim_Agent](https://github.com/Ttariyel-1954/Riy_Muellim_Agent)
