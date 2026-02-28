# 📐 Riy_Muellim_Agent — Riyaziyyat Müəllim Agent

## Layihə
Azərbaycan orta məktəbləri üçün **Riyaziyyat** fənninə ixtisaslaşmış AI Agent sistemi.
1-11-ci siniflərin bütün standartları PostgreSQL bazasındadır.

## Texnologiyalar
Node.js 20+ / Express, PostgreSQL 16 + pgvector, Claude Sonnet 4.5, R Shiny

## DB: `riy_muellim_agent`
- Standartlar: 1-11 sinif, 5 məzmun sahəsi (Ədədlər, Cəbr, Həndəsə, Ölçmə, Statistika)
- Bloom 6 səviyyə + DOK 4 səviyyə
- IRT/CAT adaptiv test parametrləri

## Dərslik RAG
- `derslikler/pdf/` → PDF dərslikləri
- `derslikler/chunks/` → Parçalanmış hissələr
- `derslikler/embeddings/` → Vektor embedding-lər
