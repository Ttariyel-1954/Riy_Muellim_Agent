# Riy_Muellim_Agent — Riyaziyyat Müəllim AI Agent

Azərbaycan riyaziyyat müəllimləri üçün test tapşırıqları və dərs planları yaradan sistem.

## ƏSAS QAYDA

İstifadəçi sinif + mövzu verəndə bu 3 addımı HƏMİŞƏ icra et:

### ADDIM 1: Dərslikdən kontekst oxu

```bash
python3 scripts/generate.py <sinif> <mövzu> test <say>
```
və ya
```bash
python3 scripts/generate.py <sinif> <mövzu> ders <dəqiqə>
```

Bu skript dərslikdən chunk-ları tapır, standartı müəyyən edir, tam prompt qaytarır.

Nümunələr:
```bash
python3 scripts/generate.py 6 faiz test 15
python3 scripts/generate.py 8 pifaqor ders 45
python3 scripts/generate.py 5 kəsr test 20
python3 scripts/generate.py 7 "xətti funksiya" ders 90
```

### ADDIM 2: Prompt-un nəticəsinə bax

Skript ekrana tam prompt çıxarır:
- Dərslikdən kontekst (terminologiya, nümunələr, tapşırıq tipləri, səhifə nömrələri)
- Standart kodu və mətni
- Bloom/DOK paylanması
- Format qaydaları

### ADDIM 3: O prompt-a əsasən faylı yarat

Prompt-dakı təlimata əsasən tapşırıq və ya dərs planı yaz. Nəticəni fayla yaz:
- Test: `output/tapshiriqlar/sinif<N>_<mövzu>_test_<tarix>.md`
- Dərs planı: `output/ders_planlari/sinif<N>_<mövzu>_ders_<tarix>.md`

---

## DƏRSLİKDƏN İSTİFADƏ (ÇOX VACİB)

Tapşırıq yazarkən MÜTLƏQ:
1. Dərslikdəki **terminologiyanı** istifadə et (dərslik "ixtisar" deyirsə, "ixtisar" yaz)
2. Dərslikdəki **nümunə tiplərinə** oxşar tapşırıqlar yarat
3. Dərslikdəki **rəqəm diapazonunu** saxla (3-cü sinif 1000-ə qədər, 5-ci sinif milyona qədər)
4. Dərslik **səhifə nömrəsinə** istinad et (📖 Dərslik: səh. XX)
5. Dərslikdəki **düsturları/qaydaları** aynen istifadə et

## CHUNK AXTARIŞI (əlavə üsullar)

```bash
# Sinif üçün mövzu siyahısı
python3 scripts/search_chunks.py --grade 6 --list-topics

# Mövzu üzrə axtarış
python3 scripts/search_chunks.py --grade 6 --topic "faiz" --context

# Statistika
python3 scripts/search_chunks.py --stats

# Birbaşa tam mətn oxu
cat derslikler/chunks/sinif6_hisse1_fulltext.txt
```

## TEST FORMATI

```
╔═══════════════════════════════════════════════════════════╗
║  📐 RİYAZİYYAT TEST TAPŞIRIQLARI                        ║
║  Sinif: [N]-ci sinif  │  Mövzu: [AD]                    ║
║  Standart: [KOD] — [MƏTN]                               ║
║  Dərslik: Riyaziyyat [N], səh. [XX-YY]                  ║
╚═══════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🟤 BLOOM: XATIRLAMA │ DOK-1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  1. [tapşırıq]
     A) ...  B) ...  C) ...  D) ...

     ┌─────────────────────────────────────┐
     │ ✅ Cavab: B                         │
     │ 📖 Dərslik: səh. XX                │
     │ 📊 Çətinlik: Asan │ ⏱️ 1 dəq       │
     │ 📝 Distraktor: A—[xəta], C—[xəta] │
     └─────────────────────────────────────┘
```

Bloom paylanması: 🟤15% 🟢20% 🔵25% 🟡25% 🟠10% 🔴5%
DOK paylanması: DOK-1:15% DOK-2:35% DOK-3:35% DOK-4:15%
Real həyat: Bakı, manat, Xəzər, metro, ASAN xidmət
Açıq cavablarda rubrika: 0-1-2-3 bal

## DƏRS PLANI FORMATI

```
╔═════════════════════════════════════════════════════════════╗
║  📐 DƏRS PLANI                                             ║
║  Sinif: [N]  │  Mövzu: [AD]  │  Müddət: [XX] dəq         ║
║  Standart: [KOD]  │  Dərslik: səh. [XX-YY]                ║
╚═════════════════════════════════════════════════════════════╝
```

5 mərhələ:
1. **Motivasiya** (10%) — real həyat sualı, dərslikdən "Araşdır"
2. **Yeni bilik** (30%) — Sinqapur CPA: Konkret→Təsviri→Mücərrəd
3. **Birgə tətbiq** (25%) — Mən edirəm → Biz edirik → Sən edirsən
4. **Müstəqil tətbiq** (25%) — 🟢Baza / 🟡Orta / 🔴Yüksək diferensiasiya
5. **Yekunlaşdırma** (10%) — çıxış bileti, ev tapşırığı

Hər mərhələdə: 👨‍🏫 müəllim, 👨‍🎓 şagird, 📖 dərslik istinadı, ⏱️ vaxt

## DIL

Hər şey Azərbaycan dilində yazılmalıdır.
