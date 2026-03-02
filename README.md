# 📐 Riy_Muellim_Agent v3.1

**AI ilə Riyaziyyat Müəllim İdarə Paneli**

ARTI 2026 © Tariyel Talibov (ARTI — Azərbaycan Respublikası Təhsil İnstitutu)

## 🎯 Haqqında

Azərbaycan riyaziyyat müəllimləri üçün süni intellekt əsaslı dərs planı və test generasiya sistemi.

- **254 dərslik mövzusu** (sinif 1-11, səhifə istinadları ilə)
- **178 kurikulum standartı** (Bloom taksonomiyası + DOK səviyyələri)
- **Claude AI** ilə dərs planı və test tapşırıqları generasiyası
- **Sinqapur CPA** + **Finlandiya** + **PISA/TIMSS** standartları
- **30% böyüdülmüş** nəfis HTML5 çıxış
- Token/vaxt izləmə + avtomatik HTML/DOCX saxlama

## 📁 Struktur

```
Riy_Muellim_Agent/
├── r_shiny/app/
│   └── app.R                 # Əsas Shiny dashboard
├── derslikler/
│   ├── topics.json           # 254 mövzu (sinif 1-11)
│   ├── standards.json        # 178 standart
│   ├── chunks/               # Dərslik PDF chunk-ları
│   └── *.pdf                 # Dərslik PDF-ləri
├── scripts/
│   ├── pdf_pipeline.py       # PDF → JSON chunk pipeline
│   ├── search_chunks.py      # Chunk axtarış aləti
│   └── generate.py           # CLI generator wrapper
├── database/seeds/
│   └── 001_base_seed.sql     # PostgreSQL seed data
├── Ders_planlari/            # Yaradılmış dərs planları (HTML+DOCX)
├── Testler/                  # Yaradılmış testlər (HTML+DOCX)
├── CLAUDE.md                 # Claude Code təlimatları
├── .env.example              # Konfiqurasiya nümunəsi
└── README.md
```

## 🚀 Quraşdırma

### Tələblər
- R (≥ 4.3) + RStudio
- R paketləri: `shiny`, `shinydashboard`, `DT`, `plotly`, `httr`, `jsonlite`
- Anthropic API açarı

### Addımlar

```bash
# 1. Klonlayın
git clone https://github.com/Ttariyel-1954/Riy_Muellim_Agent.git
cd Riy_Muellim_Agent

# 2. .env faylı yaradın
cp .env.example .env
# .env faylında ANTHROPIC_API_KEY-i daxil edin

# 3. R paketlərini quraşdırın
Rscript -e 'install.packages(c("shiny","shinydashboard","DT","plotly","httr","jsonlite"))'

# 4. İşə salın
Rscript -e 'shiny::runApp("r_shiny/app", port=4040, launch.browser=TRUE)'
```

Brauzer avtomatik açılacaq: http://127.0.0.1:4040

## 📋 İmkanlar

### Dərs Planı Yaratma
- Sinif, mövzu, standart seçin → AI 5 mərhələli dərs planı yaradır
- Sinqapur CPA: Konkret → Təsviri → Mücərrəd
- Diferensiasiya: 🟢 Baza / 🟡 Orta / 🔴 Yüksək
- Dərslik səhifə istinadları

### Test Generasiyası
- Bloom taksonomiyası (6 səviyyə) + DOK (4 səviyyə)
- Çoxseçimli + açıq cavablı tapşırıqlar
- Cavab açarı + addım-addım həll
- Distraktor analizi + rubrikalar
- PISA/TIMSS/Sinqapur standartlarına uyğun

### Token İzləmə
- Real vaxt göstəricisi (vaxt + token sayı)
- Giriş/çıxış token ayrıca
- Təxmini qiymət (USD)
- Avtomatik HTML + DOCX saxlama

## 📊 Texnologiyalar

| Komponent | Texnologiya |
|-----------|-------------|
| Frontend | R Shiny + shinydashboard |
| AI | Claude API (Anthropic) |
| Məlumat | JSON + PostgreSQL |
| Çıxış | HTML5 + DOCX (pandoc) |
| Pipeline | Python (PDF → chunks) |

## 📝 Lisenziya

© 2026 Tariyel Talibov, ARTI (Azərbaycan Respublikası Təhsil İnstitutu)
