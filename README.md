# Riyaziyyat Müəllim Agenti (Riy_Muellim_Agent)

[![R](https://img.shields.io/badge/R-4.2+-blue.svg)](https://www.r-project.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-336791.svg)](https://www.postgresql.org/)
[![Claude](https://img.shields.io/badge/AI-Claude%20Sonnet%204-purple.svg)](https://www.anthropic.com/)
[![Shiny](https://img.shields.io/badge/R%20Shiny-Dashboard-149eca.svg)](https://shiny.rstudio.com/)

**Azərbaycan Respublikasında 1-11-ci siniflər üzrə Riyaziyyat müəllimlərinə dəstək verən, Claude AI əsasında işləyən R Shiny dashboard-u. Müəllimlər üçün dərs planı, test, məsələlər və STEAM fəaliyyətlərini TIMSS, PISA, NCTM standartlarına uyğun avtomatik generasiya edir.**

---

## Mündəricat

- [Layihənin Məqsədi](#layihənin-məqsədi)
- [Əsas Xüsusiyyətlər](#əsas-xüsusiyyətlər)
- [Dashboard Bölmələri](#dashboard-bölmələri)
- [Beynəlxalq Çərçəvələr](#beynəlxalq-çərçəvələr)
- [STEAM Yanaşması](#steam-yanaşması)
- [Texniki Stek](#texniki-stek)
- [Layihə Strukturu](#layihə-strukturu)
- [Verilənlər Bazası](#verilənlər-bazası)
- [Quraşdırma](#quraşdırma)
- [İstifadə Qaydası](#i̇stifadə-qaydası)
- [Konfiqurasiya](#konfiqurasiya)
- [Təhlükəsizlik](#təhlükəsizlik)
- [Layihə Rəhbəri](#layihə-rəhbəri)

---

## Layihənin Məqsədi

Riyaziyyat müəllimlərinin gündəlik pedaqoji fəaliyyətini avtomatlaşdırmaq və dünya standartlarına uyğun tədris materialları yaratmaq. Əsas məqsədlər:

- **Dərs planlarının avtomatik generasiyası** — 1-11-ci siniflər üçün TIMSS, PISA, NCTM çərçivələrinə uyğun dərs planları
- **Test və məsələ generasiyası** — Bloom taksonomiyasına əsaslanan çoxsəviyyəli testlər
- **STEAM fəaliyyətlər** — aşağı siniflərdə riyaziyyatın elmi, texnoloji, mühəndislik, incəsənət sahələri ilə inteqrasiyası
- **Beynəlxalq tələblərə uyğunluq** — Sinqapur, Finlandiya, Yaponiya, Kanada, Cənubi Koreya, Estoniya təcrübəsindən istifadə
- **Dərsliklərdən kontekst çıxarma** — PDF dərsliklərdən RAG vasitəsilə məlumat istifadəsi

---

## Əsas Xüsusiyyətlər

### 🤖 Süni İntellekt Əsaslı Generasiya
- Claude Sonnet 4 modelindən istifadə
- Azərbaycan riyaziyyat standartlarına tam uyğunluq
- TIMSS, PISA, NCTM çərçivələri ilə tənzimləmə

### 📚 Dərs Planı Generatoru
- Sinif, mövzu və standart əsaslı avtomatik dərs planları
- 10 bölməli genişləndirilmiş struktur:
  1. Beynəlxalq uyğunluq
  2. STEAM inteqrasiyası (1-6 siniflər üçün məcburi)
  3. Dəqiqəlik dərs gedişi
  4. Differensiasiya (zəif/güclü şagirdlər üçün)
  5. Qiymətləndirmə alətləri
  6. İnklüziv uyğunlaşdırmalar
  7. Koqnitiv domen etiketləri (Bilmə / Tətbiq / Mühakimə)
  8. Resurslar və materiallar
  9. Ev tapşırığı
  10. Refleksiya

### ✍️ Test və Məsələ Generatoru
- Çoxvariantlı, qısa cavab, problem həlli məsələləri
- Bloom taksonomiyası 6 səviyyəsi üzrə
- TIMSS koqnitiv domen etiketləri
- PISA kontekst tipləri (real həyat, elm, peşə, şəxsi)
- Avtomatik qiymətləndirmə rubrikası

### 💬 Müəllim Yazışmaları
- Valideyn bildirişləri
- Şagird motivasiya mesajları
- Rəsmi yazışmalar
- Hadisə təsvirləri

### 🔬 STEAM Fəaliyyət Kitabxanası
- Həndəsi Fiqur Şəhəri (1-2 sinif)
- Kəsr Pizza Mətbəxi (3-4 sinif)
- Körpü Mühəndisliyi (5-6 sinif)
- və s.

### 🎨 Çıxışlar
- HTML (nəfis rəngli)
- DOCX (Word sənəd)
- Plotly ilə interaktiv qrafiklər

---

## Dashboard Bölmələri

| Bölmə | Funksiyası |
|-------|------------|
| **Ana Səhifə** | Ümumi statistika, qısa rəhbər |
| **Dərs Planı** | Sinif, standart, mövzu → AI dərs planı |
| **Testlər** | Standartlara əsaslanan test generasiyası |
| **Məsələlər** | Bloom səviyyəsinə görə məsələ generasiyası |
| **Mesajlar** | Hazır mesaj şablonları + AI generasiya |
| **STEAM** | Fəaliyyətlər kitabxanası və generasiya |
| **Standartlar** | 178 riyaziyyat standartının interaktiv baxışı |
| **Dərsliklər** | PDF dərsliklərdən kontekst axtarışı (RAG) |
| **Konfiqurasiya** | API key, model seçimi, dil parametrləri |

---

## Beynəlxalq Çərçəvələr

### TIMSS — Trends in International Mathematics and Science Study

**Koqnitiv sahələr:**
- **Bilmə (Knowing)** — faktlar, prosedurlar, anlayışlar
- **Tətbiq etmə (Applying)** — riyazi alətlərin istifadəsi
- **Mühakimə yürütmə (Reasoning)** — məntiqi düşüncə

**Məzmun sahələri:** Ədədlər, Cəbr, Həndəsə, Verilənlər və Ehtimal

### PISA — Riyazi Savadlılıq

**Proses kateqoriyaları:**
- **Formulə etmə** — real situasiyaları riyaziləşdirmək
- **Tətbiq etmə** — riyazi anlayışları istifadə etmək
- **İnterpretasiya** — nəticələri kontekstə uyğun şərh etmək
- **Mühakimə yürütmə** — məntiqi arqumentləşdirmə

**PISA 2025 yenilikləri:** hesablama düşüncəsi, modelləşdirmə, riyazi ünsiyyət

### NCTM — ABŞ Riyaziyyat Standartları

**5 proses standartı:**
1. Problemin həlli
2. Mühakimə yürütmə və sübut
3. Ünsiyyət
4. Əlaqələr
5. Təqdimat

### Bloom Taksonomiyası

1. **Xatırlama** — düsturları, qaydaları yadda saxlama
2. **Anlama** — riyazi anlayışların mahiyyətini dərk etmə
3. **Tətbiq etmə** — tanış olmayan situasiyalarda istifadə
4. **Təhlil etmə** — mürəkkəb məsələləri komponentlərə ayırma
5. **Qiymətləndirmə** — həll yollarının effektivliyini qiymətləndirmə
6. **Yaratma** — yeni riyazi modellər və həll yolları qurma

### Aparıcı 6 Ölkənin Təcrübəsi

| Ölkə | Xüsusi yanaşma |
|------|----------------|
| **Sinqapur** | CPA (Concrete-Pictorial-Abstract), Bar Model, Singapore Math |
| **Finlandiya** | Fenomen-əsaslı öyrənmə, PBL, fənlərarası layihələr |
| **Yaponiya** | Lesson Study, Hatsumon, Neriage, Matome, Bansho |
| **Cənubi Koreya** | Texnologiya inteqrasiyası, yaradıcılıq |
| **Kanada (Ontario)** | Kodlaşdırma, hesablama düşüncəsi |
| **Estoniya** | Rəqəmsal alətlər, statistik düşüncə |

---

## STEAM Yanaşması

STEAM = **S**cience + **T**echnology + **E**ngineering + **A**rts + **M**athematics

Aşağı siniflərdə (1-6) riyaziyyat dərslərinə STEAM inteqrasiyası **məcburidir**:

### 1-4 Siniflər (İbtidai)
- **STEAM məcburi** (hər dərsdə ən azı bir element)
- Oyun əsaslı öyrənmə
- CPA (Concrete-Pictorial-Abstract) tam tətbiq
- Nümunə fəaliyyətlər: Həndəsi Fiqur Şəhəri, Ədədlərlə Rəsm, Kəsr Pizza

### 5-7 Siniflər (Orta)
- GeoGebra istifadəsi
- Layihə əsaslı öyrənmə
- Texnoloji modelləşdirmə
- Nümunə: Körpü Mühəndisliyi, Statistik Araşdırma

### 8-11 Siniflər (Yuxarı)
- Modelləşdirmə və proqnozlaşdırma
- PISA Advanced səviyyəli məsələlər
- Real həyat problemləri
- Fənlərarası inteqrasiya (fizika, kimya, iqtisadiyyat)

---

## Texniki Stek

| Komponent | Texnologiya |
|-----------|-------------|
| **Proqramlaşdırma dili** | R (>= 4.2) |
| **Veb interfeys** | R Shiny + shinydashboard |
| **Süni intellekt** | Claude API (Anthropic) — Sonnet 4 |
| **Verilənlər bazası** | PostgreSQL |
| **PDF emalı** | pdftools (RAG üçün) |
| **Vizuallaşdırma** | Plotly |
| **HTTP sorğular** | httr paketi |
| **JSON emal** | jsonlite paketi |
| **DOCX ixrac** | officer, flextable |

---

## Layihə Strukturu

```
Riy_Muellim_Agent/
├── r_shiny/
│   └── app/
│       ├── app.R                 # Əsas Shiny tətbiqi (~80KB)
│       ├── .env                  # Lokal konfiqurasiya (git-də deyil)
│       ├── .Renviron             # R environment (git-də deyil)
│       ├── Ders_planlari/        # Generasiya olunmuş dərs planları
│       ├── Testler/              # Generasiya olunmuş testlər
│       ├── Mesajlar/             # Generasiya olunmuş mesajlar
│       └── derslikler/           # PDF dərsliklər (RAG üçün)
├── scripts/                      # Köməkçi skriptlər
├── database/                     # PostgreSQL schema və seed
├── CLAUDE.md                     # AI təlimatları
├── README.md                     # Bu fayl
├── .env.example                  # .env nümunəsi
├── .gitignore                    # Git ignore qaydaları
└── setup.sh                      # İlkin quraşdırma
```

---

## Verilənlər Bazası

Baza adı: `riy_muellim_agent` və ya `muellim_agent`

### Əsas cədvəllər
- **subjects** — Fənlər (Riyaziyyat və s.)
- **curriculum_standards** — 178 riyaziyyat standartı (1-11 siniflər)
- **topics** — 254 riyaziyyat mövzusu
- **generated_content** — AI tərəfindən yaradılmış məzmun
- **timss_framework** — TIMSS çərçivəsi
- **pisa_framework** — PISA çərçivəsi
- **international_practices** — 6 ölkənin təcrübəsi
- **steam_activities** — STEAM fəaliyyət kitabxanası

### Sinif üzrə paylanma
| Sinif | Standart sayı | Mövzu sayı |
|-------|---------------|------------|
| 1-4 | 62 | 98 |
| 5-9 | 86 | 124 |
| 10-11 | 30 | 32 |
| **Yekun** | **178** | **254** |

---

## Quraşdırma

### Tələblər
- **R** >= 4.2
- **PostgreSQL** >= 14
- **Anthropic API açarı**
- R paketləri: `shiny`, `shinydashboard`, `DT`, `httr`, `jsonlite`, `plotly`

### Addımlar

```bash
# 1. Repo-nu klonla
git clone https://github.com/Ttariyel-1954/Riy_Muellim_Agent.git
cd Riy_Muellim_Agent

# 2. R paketlərini qur
Rscript -e 'install.packages(c("shiny","shinydashboard","DT","httr","jsonlite","plotly"))'

# 3. .env faylını yarat
cp .env.example r_shiny/app/.env
nano r_shiny/app/.env
# ANTHROPIC_API_KEY=sk-ant-api03-SİZİN_AÇARINIZ yazın

# 4. APP_DIR yolunu yoxlayın (r_shiny/app/app.R başında)
# Əgər layihəniz ~/projects/standards/Riy_Muellim_Agent altındadırsa,
# app.R-də PROJECT_DIR-i düzəldin:
# PROJECT_DIR <- normalizePath("~/projects/standards/Riy_Muellim_Agent", mustWork = FALSE)

# 5. PostgreSQL bazasını yarat
createdb riy_muellim_agent
psql -d riy_muellim_agent -f database/migrations/001_schema.sql
psql -d riy_muellim_agent -f database/seeds/001_standards_seed.sql

# 6. Dashboard-u işə sal
Rscript -e "shiny::runApp('r_shiny/app/app.R', port=4040)"
```

Brauzer: **http://localhost:4040**

### RStudio ilə işə salmaq (tövsiyə olunur)
1. RStudio-da `r_shiny/app/app.R` faylını açın
2. Yuxarıdan **"Run App"** düyməsini basın
3. Dashboard yeni pəncərədə açılacaq

---

## İstifadə Qaydası

### Dərs planı yaratmaq
1. **Dərs Planı** tabını açın
2. Sinif (1-11) və mövzu seçin
3. İsteğe bağlı: konkret standart seçin
4. **"Dərs planı yarat"** düyməsini basın
5. 60-90 saniyə ərzində 10 bölməli genişləndirilmiş dərs planı hazır olacaq
6. HTML və ya DOCX formatında yükləyin

### Test yaratmaq
1. **Testlər** tabına keçin
2. Sinif və standart seçin
3. Sual növlərini və saylarını təyin edin
4. Bloom səviyyəsini seçin
5. **"Test yarat"** düyməsi ilə generasiya edin

### STEAM fəaliyyəti yaratmaq
1. **STEAM** tabına keçin
2. Sinif və mövzu seçin
3. STEAM komponenti seçin (Science, Technology, Engineering, Arts)
4. Fəaliyyət hazırlanacaq

---

## Konfiqurasiya

### `.env` və ya `.Renviron` faylı

Fayl yeri: `r_shiny/app/.env` **və ya** `~/projects/standards/Riy_Muellim_Agent/.env`

```bash
# PostgreSQL
DB_HOST=localhost
DB_PORT=5432
DB_NAME=riy_muellim_agent
DB_USER=your_username
DB_PASSWORD=

# Claude AI
ANTHROPIC_API_KEY=sk-ant-api03-SİZİN_AÇARINIZ
DEFAULT_AI_MODEL=claude-sonnet-4-20250514

# Shiny
SHINY_PORT=4040
```

### Avtomatik API Key Yükləmə

Dashboard açılanda API açarı `.env` faylından avtomatik oxunur və **görünməz** (password format) olaraq daxil edilir.

### APP_DIR Problemi

Əgər dashboard açılır amma API key işləmirsə, `app.R` faylının başında `PROJECT_DIR` yolunu yoxlayın. Layihəni köçürəndə bu yol yenilənməlidir:

```r
PROJECT_DIR <- normalizePath("~/projects/standards/Riy_Muellim_Agent", mustWork = FALSE)
```

---

## Təhlükəsizlik

### API Açarları
- **HEÇ VAXT** `.env`, `.Renviron` fayllarını git-ə commit etməyin
- `.gitignore` faylı bu faylları avtomatik istisna edir
- API açarı sızarsa, dərhal [console.anthropic.com](https://console.anthropic.com) saytından **revoke** edin
- Git-də yalnız `.env.example` saxlanılır (açarsız nümunə)

### Fayl Uzantıları Problemi

macOS Finder bəzən `.env` yaradanda avtomatik `.sh` əlavə edir. Düzəltmək üçün:

```bash
mv .env.sh .env
```

### Backup
- `database/` qovluğundakı SQL faylları (schema və seed) əsas bərpa mənbəyidir
- AI-generasiya məzmunu `Ders_planlari/`, `Testler/`, `Mesajlar/` qovluqlarında lokal saxlanılır (git-də deyil)

---

## Onlayn Platformalar

| Platforma | Link |
|-----------|------|
| **GitHub** | [github.com/Ttariyel-1954/Riy_Muellim_Agent](https://github.com/Ttariyel-1954/Riy_Muellim_Agent) |

---

## Əlaqəli Layihələr

Bu layihə ARTI-nin riyaziyyat təhsili ekosisteminin bir hissəsidir:

| Layihə | Təsvir |
|--------|--------|
| [Riy_standartlar](https://github.com/Ttariyel-1954/Riy_Yeni_standartlar) | 238 riyaziyyat standartının AI ilə yenilənməsi |
| [Az_agent](https://github.com/Ttariyel-1954/Az_Agent) | Azərbaycan dili müəllim agenti |
| [Az_dili_standartlar](https://github.com/Ttariyel-1954/Az_dili_standartlar) | 442 Azərbaycan dili standartının yenilənməsi |

---

## Layihə Rəhbəri

**Talıbov Tariyel İsmayıl oğlu**
Riyaziyyat üzrə fəlsəfə doktoru
Azərbaycan Respublikası Təhsil İnstitutunun direktor müavini

**ARTI — 2026**

---

## Lisenziya

Bu layihə təhsil məqsədli istifadə üçün nəzərdə tutulub.
Azərbaycan Respublikası Elm və Təhsil Nazirliyi — ARTI
