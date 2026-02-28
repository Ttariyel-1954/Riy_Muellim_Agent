<p align="center">
  <img src="https://img.shields.io/badge/ARTI-2026-003366?style=for-the-badge&labelColor=002244" alt="ARTI 2026"/>
  <img src="https://img.shields.io/badge/Riyaziyyat-1--11_sinif-blue?style=for-the-badge" alt="Riyaziyyat"/>
</p>

<h1 align="center">📐 Riy_Muellim_Agent</h1>

<p align="center">
  <strong>Riyaziyyat Müəllimləri üçün AI Agent Sistemi — 1-11-ci siniflər</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Node.js-20+-339933?logo=nodedotjs&logoColor=white" alt="Node.js"/>
  <img src="https://img.shields.io/badge/PostgreSQL-16-336791?logo=postgresql&logoColor=white" alt="PostgreSQL"/>
  <img src="https://img.shields.io/badge/Claude-Sonnet_4.5-CC785C?logo=anthropic&logoColor=white" alt="Claude"/>
  <img src="https://img.shields.io/badge/R_Shiny-Dashboard-276DC3?logo=r&logoColor=white" alt="R Shiny"/>
</p>

---

## 📂 Struktur

```
Riy_Muellim_Agent/
├── database/
│   ├── migrations/001_schema.sql     ← 25+ cədvəl
│   ├── seeds/
│   │   ├── 001_base_seed.sql         ← Standartlar (1-11 sinif)
│   │   └── 002_lesson_plans_tasks.sql← Dərs planları + 36 tapşırıq
│   └── queries/
│       └── Riy_SQL.sql               ← 18 gözəl sorğu
├── derslikler/                        ← 🆕 Dərslik RAG sistemi
│   ├── pdf/                           ← PDF dərslikləri bura qoyun
│   ├── chunks/                        ← AI parçalama
│   └── embeddings/                    ← pgvector
├── src/                               ← 6 AI Agent + API
├── r_shiny/                           ← Dashboard
├── output/
│   ├── ders_planlari/                 ← Yaradılmış dərs planları
│   ├── tapshiriqlar/                  ← Tapşırıq bankası
│   ├── resurslar/                     ← PPTX, DOCX, XLSX
│   └── imtahanlar/                    ← İmtahan materialları
└── docs/
```

## 📐 Məzmun Sahələri

| Sahə | Siniflər | Nümunə mövzular |
|:-----|:---------|:----------------|
| 🔢 Ədədlər və əməllər | 1-8 | Natural ədədlər, kəsrlər, faizlər, rasional ədədlər |
| 🔤 Cəbr və funksiyalar | 1-11 | Tənliklər, funksiyalar, törəmə, inteqral |
| 📏 Həndəsə | 1-11 | Fiqurlar, Pifaqor, vektorlar, fəza həndəsəsi |
| 📊 Statistika və ehtimal | 1-11 | Diaqramlar, orta, median, ehtimal, kombinatorika |
| 📐 Ölçmə | 1-4 | Uzunluq, kütlə, tutum, zaman, pul |

## 🚀 Quraşdırma

```bash
# 1. Bazanı yaradın
createdb riy_muellim_agent

# 2. Cədvəlləri yaradın
psql -d riy_muellim_agent -f database/migrations/001_schema.sql

# 3. Standartları yükləyin
psql -d riy_muellim_agent -f database/seeds/001_base_seed.sql

# 4. Dərs planları + tapşırıqları yükləyin
psql -d riy_muellim_agent -f database/seeds/002_lesson_plans_tasks.sql

# 5. Sorğulara baxın
psql -d riy_muellim_agent
\pset border 2
\pset linestyle unicode
\i database/queries/Riy_SQL.sql
```

## 📚 Dərslik İnteqrasiyası (RAG)

Dərslik PDF-lərini `derslikler/pdf/` papkasına qoyduqda:

```
Müəllim: "6-cı sinif, Faizlər, 15 tapşırıq yaz"
    │
    ▼
┌─────────────────┐
│ PostgreSQL:     │ → R6.3.1 standartı tapılır
│ Standart seçimi │
└────────┬────────┘
         │
┌────────▼────────┐
│ pgvector:       │ → Dərslikdən "Faizlər" hissəsi
│ Dərslik axtarış│   (səh. 84-92) qaytarılır
└────────┬────────┘
         │
┌────────▼────────┐
│ Claude AI:      │ → Standart + Dərslik + Bloom/DOK
│ Generasiya      │   əsasında keyfiyyətli nəticə
└─────────────────┘
```

---

<p align="center">
  <strong>ARTI 2026</strong> — Tariyel Talibov<br/>
  <em>Qiymətləndirmə, Analiz və Monitorinq Departamenti</em>
</p>
