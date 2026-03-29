# Riy Muellim Agent v3.3

**Azarbaycan Respublikasi 1-11-ci sinif riyaziyyat muallimllari ucun AI agent sistemi**

ARTI 2026 — Azarbaycan Respublikasi Tahsil Institutu

---

## Haqqinda

Riy Muellim Agent — riyaziyyat muallimlarinin gundalik isini asanlasdiran, baynalxalq standartlara (TIMSS, PISA, PIRLS) uygun dars planlari, testlar, sagird analizlari va metodiki materiallar yaradan suni intellekt sistemidir.

Sistem Claude AI (Anthropic) modeli uzarinda islayir va R Shiny interfeysi vasitasila muallimlara istifadaya hazir sanadlar taqdim edir.

### Asas xususiyyatlar

- 1-11-ci sinif ucun tam kurikulum dastayi (178 standart, 254 movzu)
- 17 darslik PDF-dan cixarilmis 519 chunk bilik bazasi
- TIMSS/PISA/PIRLS baynalxalq carcivalara uygunluq
- Blum taksonomiyasi va Sinqapur CPA modeli inteqrasiyasi
- HTML5 + DOCX formatinda fayl cixisi
- 3 dilda interfeys: Azerbaycanca, Rusca, Ingilisca
- Real vaxt generasiya statistikasi (token, xerc, vaxt)

---

## Sistem Arxitekturasi

```
Riy_Muellim_Agent/
├── r_shiny/app/
│   └── app.R                 # R Shiny interfeys (asas proqram)
├── src/
│   ├── server.js             # Node.js API server
│   ├── core/
│   │   └── ai_engine.js      # Claude + OpenAI multi-model engine
│   ├── agents/
│   │   ├── lesson_planning/  # Dars planlama agenti
│   │   ├── assessment/       # Qiymatlandirma agenti
│   │   ├── communication/    # Kommunikasiya agenti
│   │   ├── student_progress/ # Sagird inkisafi agenti
│   │   ├── pedagogical/      # Metodiki komak agenti
│   │   └── digital_assistant/# Raqamsal assistant
│   ├── api/
│   │   └── routes.js         # API endpoint-lari
│   └── middleware/
│       └── auth.js           # JWT autentifikasiya
├── database/
│   ├── migrations/           # PostgreSQL schema
│   └── seeds/                # Ilkin verilanlar
├── derslikler/
│   ├── pdf/                  # 17 darslik PDF (gitignore)
│   ├── chunks/               # 519 chunk (JSON)
│   ├── standards.json        # 178 kurikulum standarti
│   └── topics.json           # Movzular
├── config/
│   └── database.js           # DB konfiqurasiyasi
├── scripts/
│   ├── pdf_pipeline.py       # PDF → chunk pipeline
│   ├── pdf_to_chunks.py      # PDF parcalama
│   ├── search_chunks.py      # Chunk axtaris
│   └── setup.sh              # Qurasdirma skripti
├── Ders_planlari/            # Generasiya olunmus dars planlari
├── Testler/                  # Generasiya olunmus testlar
├── Mesajlar/                 # Generasiya olunmus mesajlar
├── .env.example              # Konfiqurasiya numunasi
├── package.json              # Node.js asililiqlar
├── Dockerfile                # Docker image
├── docker-compose.yml        # Docker compose
└── CLAUDE.md                 # AI agent talimati
```

---

## Qurasdirma

### Talablar

| Komponent | Versiya | Maqsad |
|-----------|---------|--------|
| R | >= 4.3 | Shiny interfeys |
| Node.js | >= 18 | API server |
| PostgreSQL | >= 14 | Verilanlar bazasi (optional) |
| Pandoc | >= 2.19 | DOCX generasiyasi |
| Python | >= 3.9 | PDF pipeline (birdafalik) |

### R paketlari

```r
install.packages(c(
  "shiny", "shinydashboard", "DT",
  "httr", "jsonlite", "plotly"
))
```

### Addim 1: Klonlama

```bash
git clone https://github.com/Ttariyel-1954/Riy_Muellim_Agent.git
cd Riy_Muellim_Agent
```

### Addim 2: .env faylini yaradin

```bash
cp .env.example .env
```

`.env` faylini redakta edin:

```env
# Mutlaq lazimdir:
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

### Addim 3: R Shiny interfeysi isa salin

```bash
cd r_shiny/app
Rscript -e "shiny::runApp('.', port = 4040, host = '0.0.0.0')"
```

Va ya:

```bash
npm run shiny
```

Brauzer: `http://localhost:4040`

### Addim 4: Node.js API (optional)

```bash
npm install
npm run db:setup   # PostgreSQL lazimdir
npm start          # http://localhost:3000
```

---

## Docker ila isa salma

```bash
docker-compose up -d
```

Bu komanda ham Node.js API-ni (`localhost:3000`), ham PostgreSQL-i (`localhost:5432`), ham da R Shiny-ni isa salir.

---

## Istifada Talimati

### Tab 1: Dars Plani Generasiyasi

Muallim asagidaki parametrlari secir:

| Parametr | Secim |
|----------|-------|
| Sinif | 1-11 |
| Movzu | Kurikulumdan secim va ya azad daxiletma |
| Standart | Avtomatik yuklanir (178 standart) |
| Dars tipi | Yeni movzu / Mohkamlandirma / Qiymatlandirma |
| Baynalxalq carciva | TIMSS / PISA / PIRLS / Blum / CPA |
| Diferensial talim | 3 saviyya (zaif/orta/guclu) |

**Cixis:** HTML5 + DOCX fayl — darhal cap ucun hazir, 2500+ soz atrafly dars plani.

**Dars planinin strukturu:**

1. Umumi malumat (sinif, movzu, standart, tarix)
2. Talim naticalar — Blum taksonomiyasina gora olculabilan feillar
3. Baynalxalq standart uygunlugu (TIMSS domen/koqnitiv, PISA prosesi/konteksti)
4. Sinqapur CPA (Concrete → Pictorial → Abstract) ardicilligi
5. Yaponiya Lesson Study elementlari (Hatsumon, Kikan-shido, Neriage, Matome)
6. Daqiqalik dars gedisi (45 daqiqa, 5 marhala)
7. Diferensial tapsiriqlar (3 saviyya, har birinin TIMSS koqnitiv domeni)
8. STEAM inteqrasiyasi (Science, Technology, Engineering, Arts, Mathematics)
9. Formativ qiymatlandirma alatlar
10. Ev tapsirigi (diferensiyalasdirilmis)

### Tab 2: Test Generasiyasi

TIMSS/PISA formatinda testlar yaradir:

- Cocsecimli suallar (Blum saviyyalari ila)
- Qisa cavabli suallar
- Aciq suallar (rubrika ila)
- Hall yolu + izah + darslik istinad
- Distraktor analizi

**Catinlik saviyyalari:** Asan → Orta → Catin → Qarisiq

### Tab 3: Ayliq Plan

Butov ay ucun haftalik cadval:
- Har hafta: movzu + standart + saat bolgusu
- PISA/PIRLS uygunluq gostaricisi
- Formativ/summativ qiymatlandirma noqtalari
- Dars tipi variantlari

### Tab 4: Kommunikasiya

Muallim ucun hazir sanadlar:
- Valideyn maktubu
- Idari hesabat
- Pedaqoji sura cixisi
- Sagird xasiyyatnamasi

### Tab 5: Sagird Analizi

Fardi sagird profili yaradir:
- Guclu/zaif taraflari
- TIMSS koqnitiv domen profili
- Fardilasdiriilmis tovsiyalar
- Valideyn ucun taklif maktubu

### Tab 6: Standartlar

Butun kurikulum standartlarini cadval saklinda gostarir:
- 178 asas standart
- Sinifa gora filtrasiya
- Sahaya gora qruplasdirma (adad, handasa, cabr, statistika)

### Tab 7: Statistika

Generasiya statistikasi:
- Vaxt, token sayi, taxmini xerc
- Arxiv cadvali (kecmis planlar/testlar)
- HTML va DOCX yuklama duymasi

---

## Bilik Bazasi

### Darslik Chunk-lari

17 riyaziyyat darsliyi (1-11-ci sinif, I va II hissa) PDF formatindan parcalanib JSON chunk-larina cevrilib:

| Sinif | Darslik | Chunk sayi |
|-------|---------|------------|
| 1 | I hissa + II hissa | ~50 |
| 2 | I hissa + II hissa | ~50 |
| 3 | I hissa + II hissa | ~50 |
| 4 | I hissa + II hissa | ~50 |
| 5 | I hissa + II hissa | ~50 |
| 6 | I hissa + II hissa | ~50 |
| 7 | Tam | ~40 |
| 8 | Tam | ~40 |
| 9 | Tam | ~40 |
| 10 | Tam | ~35 |
| 11 | Tam | ~35 |
| **Cami** | **17 PDF** | **519 chunk** |

Har chunk tarkibi: sinif, hissa, movzu, saha, matn, sahifa araligi, soz sayi.

### Kurikulum Standartlari

178 standart 5 saha uzra:

| Saha | Izah |
|------|------|
| Adadlar va amaliyyatlar | Natural adadlar, kasrlar, onluq kasrlar, rasional adadlar |
| Cabr va funksiyalar | Dayisanlar, tanliklar, barabarsizliklar, funksiyalar |
| Handasa | Fiqurlar, olcular, koordinat, cevirma |
| Olcma | Uzunluq, saha, hacm, kutla, vaxt |
| Statistika va ehtimal | Malumat toplama, diaqram, orta, ehtimal |

---

## Baynalxalq Standartlar

### TIMSS Inteqrasiyasi

**Kontekt domenlar:** Adad, Cabr, Handasa, Malumat va Ehtimal

**Koqnitiv domenlar:**
- **[B] Bilmak (Knowing):** Faktlar, prosedurlar, anlayislar
- **[T] Tatbiq etmak (Applying):** Standart masala halli
- **[M] Muhakima yurutmak (Reasoning):** Qeyri-standart, coxaddimli masalalar

Har tapsiriq [B], [T], [M] etiketi ila isaralanir.

### PISA Inteqrasiyasi

**Proseslar:** Formulasiya → Tatbiq → Sarh/Qiymatlandirma

**Kontekstlar:** Saxsi, Pasekar, Sosial, Elmi

**Bacariq saviyyalari:** 1-6 (har test sualinda gostarilir)

### Sinqapur CPA Modeli

Har dars planinda 3 marhala:
1. **Concrete (Asyavi):** Manipulyativlar — saygac cubuqlari, onluq bloklar, tangram
2. **Pictorial (Tasviri):** Vizual modellar — adad xatti, bar modeli, diaqram
3. **Abstract (Mucarrad):** Riyazi simvol va formulalar

### Yaponiya Lesson Study

- **Hatsumon:** Darsin avvalinda dusundrucu sual
- **Kikan-shido:** Fardi musahida, sinif boyu gazarak
- **Neriage:** Muxtalif hall yollarinin muzakirasi
- **Matome:** Darsin sonunda umulasdirma
- **Bansho:** Lovhada planlasdirilmis yazi

---

## API Endpoint-lari

Node.js API (optional, R Shiny mustaqil islayir):

| Metod | Endpoint | Funksiyasi |
|-------|----------|-----------|
| GET | `/api/v1/health` | Saglamliq yoxlamasi |
| POST | `/api/v1/ders-plani` | Dars plani generasiyasi |
| POST | `/api/v1/test-yarat` | Test generasiyasi |
| POST | `/api/v1/aylik-plan` | Ayliq plan |
| POST | `/api/v1/mesaj-yaz` | Mesaj generasiyasi |
| POST | `/api/v1/shagird-analiz` | Sagird analizi |
| GET | `/api/v1/arxiv/ders-planlari` | Kecmis planlar |
| GET | `/api/v1/arxiv/testler` | Kecmis testlar |

---

## Verilanlar Bazasi (PostgreSQL)

### Asas cadvallar

| Cadval | Maqsad | Sutun sayi |
|--------|--------|------------|
| `riy_standartlari` | Kurikulum standartlari | 11 |
| `riy_movzular` | 254 movzu | 7 |
| `riy_derslikler` | 519 chunk | 10 |
| `ders_planlari` | Generasiya olunmus planlar | 10 |
| `testler` | Generasiya olunmus testlar | 10 |
| `mesajlar` | Mesajlar | 5 |
| `timss_framework` | TIMSS carcivasi | 8 |
| `pisa_framework` | PISA carcivasi | 7 |
| `steam_activities` | STEAM faaliyyatlar kitabxanasi | 10 |
| `international_practices` | Baynalxalq yaxsi tacruubalar | 9 |

### Migration

```bash
npm run db:migrate   # Schema yaradir
npm run db:seed      # Ilkin malumatlari daxil edir
```

---

## Fayl Cixisi

Har generasiya naticasi 2 formatda saxlanir:

### HTML5
- Responsive dizayn, mobil uyumlu
- Gradient basliqlar, rangli fazalar
- Cap ucun optimizasiya olunmus (`@media print`)
- Interaktiv hover effektlari

### DOCX (Word)
- Pandoc vasitasila avtomatik cevrilir
- Azerbaycan alifbasi dastayi (UTF-8)
- ARTI 2026 altbilgi

### Fayl adlandirma

```
sinif{N}_{movzu_slug}_{tip}_{timestamp}.html
sinif{N}_{movzu_slug}_{tip}_{timestamp}.docx
```

Misal: `sinif7_Nisb_t__m_t_nasiblik_ders_plani_20260303_093906.html`

---

## Konfiqurasiya

### AI Model Secimi

`.env` faylinda:

```env
DEFAULT_AI_MODEL=claude-sonnet-4-20250514
```

Dastaklanan modellar:
- `claude-sonnet-4-20250514` (default, optimal balans)
- `claude-haiku-4-5-20251001` (suratli, ucuz)
- `gpt-4o` (OpenAI alternativi)

### Token Limitlari

| Model | Default max_tokens |
|-------|--------------------|
| Claude Sonnet/Opus | 16384 |
| Claude Haiku | 4096 |
| GPT-4o | 16384 |

---

## Inkisaf

### Lokal inkisaf

```bash
# R Shiny (live reload)
cd r_shiny/app
Rscript -e "shiny::runApp('.', port = 4040)"

# Node.js (nodemon ila)
npm run dev

# PDF pipeline (birdafalik)
python3 scripts/pdf_pipeline.py
```

### Layiha strukturuna yeni agent alava etmak

1. `src/agents/` altinda yeni qovluq yaradin
2. `index.js` faylinda agent sinifini yaradin
3. `src/api/routes.js`-a endpoint alava edin
4. `r_shiny/app/app.R`-a yeni tab alava edin

---

## Texnoloji Stek

| Komponent | Texnologiya | Versiya |
|-----------|-------------|---------|
| Frontend | R Shiny + shinydashboard | 1.8.x |
| AI Engine | Claude API (Anthropic) | v2023-06-01 |
| Backend | Node.js + Express | 18+ |
| Database | PostgreSQL | 14+ |
| Vizualizasiya | Plotly.js | 2.x |
| Sanad generasiyasi | Pandoc (HTML → DOCX) | 2.19+ |
| PDF pipeline | Python (PyPDF2, tiktoken) | 3.9+ |
| Konteynerlasdirma | Docker + Docker Compose | 24+ |

---

## Lisenziya

MIT License — ARTI 2026, Tariyel Talibov

---

## Alaqe

- **Muallif:** Tariyel Talibov
- **Taskilat:** ARTI — Azerbaycan Respublikasi Tahsil Institutu
- **GitHub:** [Ttariyel-1954/Riy_Muellim_Agent](https://github.com/Ttariyel-1954/Riy_Muellim_Agent)
