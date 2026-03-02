#!/usr/bin/env python3
"""
╔══════════════════════════════════════════════════════════════╗
║  📐 Riy_Muellim_Agent — Kontekst Generatoru                 ║
║                                                              ║
║  Sinif + mövzu verildikdə dərslikdən kontekst çıxarır       ║
║  və Claude Code-un birbaşa istifadə edəcəyi prompt yaradır. ║
║                                                              ║
║  İstifadə:                                                   ║
║    python3 scripts/generate.py 6 faiz test 15                ║
║    python3 scripts/generate.py 8 pifaqor ders 45             ║
║    python3 scripts/generate.py 5 kəsr test 20                ║
╚══════════════════════════════════════════════════════════════╝
"""

import sys
import json
import os
from pathlib import Path
from datetime import date

BASE_DIR = Path(__file__).resolve().parent.parent
CHUNKS_DIR = BASE_DIR / "derslikler" / "chunks"
SEEDS_FILE = BASE_DIR / "database" / "seeds" / "001_base_seed.sql"
OUTPUT_DIR = BASE_DIR / "output"

# ─── STANDARTLAR (seed fayldan) ───────────────────────────────────

STANDARDS = {
    1: {
        "ededler": "R1.1 — Natural ədədləri 100 daxilində tanıyır, sayır, müqayisə edir",
        "hendese": "R1.3 — Sadə həndəsi fiqurları (dairə, üçbucaq, düzbucaqlı, kvadrat) tanıyır",
        "olcme": "R1.5 — Uzunluğu qeyri-standart vahidlərlə ölçür",
    },
    2: {
        "ededler": "R2.1 — Natural ədədləri 1000 daxilində tanıyır, toplama-çıxma əməlləri",
        "hendese": "R2.3 — Həndəsi fiqurların xassələrini müqayisə edir",
        "olcme": "R2.5 — Uzunluq, kütlə vahidlərini bilir (sm, m, kq)",
    },
    3: {
        "ededler": "R3.1 — Çoxrəqəmli ədədlərlə toplama, çıxma; vurma cədvəli",
        "hendese": "R3.3 — Perimetri hesablayır, simmetriya anlayışı",
        "olcme": "R3.5 — Zaman vahidləri (saat, dəqiqə), pul (manat, qəpik)",
    },
    4: {
        "ededler": "R4.1 — Çoxrəqəmli ədədlərlə vurma, bölmə; sadə kəsrlər",
        "hendese": "R4.3 — Sahəni hesablayır (düzbucaqlı, kvadrat)",
        "olcme": "R4.5 — Həcm, tutum vahidləri (litr, ml)",
    },
    5: {
        "ededler": "R5.1 — Onluq kəsrlər, adi kəsrlər, əməllər",
        "cebr": "R5.2 — Sadə tənliklər, bərabərsizliklər",
        "hendese": "R5.3 — Üçbucaq və dördbucaqlıların sahəsi, çevrə",
        "statistika": "R5.4 — Sütunlu və dairəvi diaqramlar, orta ədəd",
    },
    6: {
        "ededler": "R6.1 — Müsbət və mənfi ədədlər, rasional ədədlər, faiz",
        "cebr": "R6.2 — Cəbri ifadələr, xətti tənliklər",
        "hendese": "R6.3 — Bucaqlar, paralel xətlər, üçbucaq xassələri",
        "statistika": "R6.4 — Statistik verilənlər, median, moda, orta",
    },
    7: {
        "ededler": "R7.1 — Nisbət, tənasüb, faiz hesablamaları",
        "cebr": "R7.2 — Xətti funksiya, qrafik, tənliklər sistemi",
        "hendese": "R7.3 — Çevrə, dairə, sahə, Pifaqor teoremi (giriş)",
        "statistika": "R7.4 — Ehtimal anlayışı, kombinatorika əsasları",
    },
    8: {
        "cebr": "R8.1 — Kvadrat köklər, irrasional ədədlər, çoxhədlilər",
        "hendese": "R8.2 — Pifaqor teoremi, oxşar üçbucaqlar, vektor (giriş)",
        "statistika": "R8.3 — Ehtimal, statistika, yayılma göstəriciləri",
    },
    9: {
        "cebr": "R9.1 — Kvadrat tənliklər, diskriminant, Vyet teoremi",
        "hendese": "R9.2 — Triqonometriya, sin/cos/tg, vektor əməlləri",
        "statistika": "R9.3 — Kombinatorika, ehtimal, Bernulli sınağı",
    },
    10: {
        "cebr": "R10.1 — Funksiyalar (triqonometrik, göstərici, loqarifmik)",
        "hendese": "R10.2 — Fəza həndəsəsi, prizma, piramida",
        "statistika": "R10.3 — Statistik paylanmalar, standart kənarlaşma",
    },
    11: {
        "cebr": "R11.1 — Limit, törəmə, inteqral",
        "hendese": "R11.2 — Silindr, konus, kürə; həcm və sahə",
        "statistika": "R11.3 — Ehtimal nəzəriyyəsi, böyük ədədlər qanunu",
    },
}

TOPIC_AREA_MAP = {
    "faiz": "ededler", "kəsr": "ededler", "onluq": "ededler",
    "ədəd": "ededler", "natural": "ededler", "rasional": "ededler",
    "toplama": "ededler", "çıxma": "ededler", "vurma": "ededler",
    "bölmə": "ededler", "say": "ededler", "rəqəm": "ededler",
    "nisbət": "ededler", "tənasüb": "ededler",
    "tənlik": "cebr", "funksiya": "cebr", "ifadə": "cebr",
    "çoxhədli": "cebr", "kvadrat": "cebr", "xətti": "cebr",
    "sistem": "cebr", "köklər": "cebr", "diskriminant": "cebr",
    "törəmə": "cebr", "inteqral": "cebr", "limit": "cebr",
    "loqarifm": "cebr", "proqressiya": "cebr",
    "üçbucaq": "hendese", "dördbucaqlı": "hendese", "dairə": "hendese",
    "çevrə": "hendese", "bucaq": "hendese", "sahə": "hendese",
    "perimetr": "hendese", "həcm": "hendese", "pifaqor": "hendese",
    "vektor": "hendese", "simmetriya": "hendese", "paralel": "hendese",
    "koordinat": "hendese", "triqonometriya": "hendese",
    "sin": "hendese", "cos": "hendese", "fiqur": "hendese",
    "prizma": "hendese", "piramida": "hendese", "silindr": "hendese",
    "statistika": "statistika", "ehtimal": "statistika",
    "diaqram": "statistika", "orta": "statistika", "median": "statistika",
    "kombinatorika": "statistika",
    "uzunluq": "olcme", "kütlə": "olcme", "zaman": "olcme",
    "pul": "olcme", "ölçmə": "olcme", "litr": "olcme",
}


def detect_area(topic: str) -> str:
    topic_lower = topic.lower()
    for keyword, area in TOPIC_AREA_MAP.items():
        if keyword in topic_lower:
            return area
    return "ededler"


def find_standard(grade: int, topic: str) -> str:
    area = detect_area(topic)
    grade_standards = STANDARDS.get(grade, {})
    if area in grade_standards:
        return grade_standards[area]
    # İlk mövcud standartı qaytar
    if grade_standards:
        return list(grade_standards.values())[0]
    return f"R{grade}.1 — {grade}-ci sinif riyaziyyat standartı"


def load_chunks(grade: int) -> list:
    chunks = []
    for f in sorted(CHUNKS_DIR.glob(f"sinif{grade}_*_chunks.json")):
        with open(f, "r", encoding="utf-8") as fh:
            chunks.extend(json.load(fh))
    return chunks


def search_chunks(grade: int, topic: str, max_results: int = 3) -> list:
    chunks = load_chunks(grade)
    if not chunks:
        return []

    topic_lower = topic.lower()
    topic_words = [w for w in topic_lower.split() if len(w) >= 3]

    scored = []
    for chunk in chunks:
        score = 0
        searchable = (
            chunk.get("text", "").lower() + " " +
            (chunk.get("topic", "") or "").lower() + " " +
            (chunk.get("chapter", "") or "").lower() + " " +
            " ".join(chunk.get("keywords", []))
        )

        if topic_lower in searchable:
            score += 10
        for word in topic_words:
            count = searchable.count(word)
            score += min(count, 5)
        if chunk.get("chapter") and topic_lower in chunk["chapter"].lower():
            score += 15

        if score > 0:
            scored.append((score, chunk))

    scored.sort(key=lambda x: -x[0])
    return [c for _, c in scored[:max_results]]


def build_context(grade: int, topic: str) -> str:
    """Dərslikdən kontekst hazırla."""
    results = search_chunks(grade, topic)
    if not results:
        return f"[Dərslikdə '{topic}' mövzusu tapılmadı. Ümumi bilik əsasında yazılacaq.]"

    parts = []
    for i, chunk in enumerate(results, 1):
        text = chunk.get("text", "")
        if len(text) > 4000:
            text = text[:4000] + "\n... [davamı dərslikdə]"

        parts.append(f"""
━━━ Dərslik: {chunk.get('source_file','?')}, səh. {chunk['page_start']}-{chunk['page_end']} ━━━
Fəsil: {chunk.get('chapter', '—')}
Mövzu: {chunk.get('topic', '—')}
Açar sözlər: {', '.join(chunk.get('keywords', [])[:10])}

{text}
""")

    return "\n".join(parts)


def generate_test_prompt(grade: int, topic: str, count: int) -> str:
    standard = find_standard(grade, topic)
    context = build_context(grade, topic)

    return f"""╔══════════════════════════════════════════════════════════════════╗
║  📐 TEST TAPŞIRIQLARI GENERASİYASI                               ║
║  Sinif: {grade}-ci sinif  │  Mövzu: {topic}  │  Say: {count}       ║
║  Standart: {standard}
╚══════════════════════════════════════════════════════════════════╝

═══ DƏRSLİKDƏN KONTEKST ═══
{context}

═══ TAPŞIRIQ YARATMA TƏLİMATI ═══

Yuxarıdakı dərslik kontekstini oxu. {count} tapşırıq yarat.

QAYDALAR:
1. Dərslikdəki TERMİNOLOGİYANI istifadə et
2. Dərslikdəki NÜMUNƏ tiplərinə oxşar tapşırıqlar yaz
3. Dərslik SƏHİFƏ NÖMRƏSİNƏ istinad et

BLOOM PAYLANMASI ({count} tapşırıq):
🟤 Xatırlama (DOK-1): {max(1, count*15//100)} tapşırıq — çoxseçimli
🟢 Anlama (DOK-1-2): {max(1, count*20//100)} tapşırıq — qısa cavab
🔵 Tətbiqetmə (DOK-2): {max(1, count*25//100)} tapşırıq — hesablama
🟡 Təhlil (DOK-3): {max(1, count*25//100)} tapşırıq — çox addımlı
🟠 Qiymətləndirmə (DOK-3): {max(1, count*10//100)} tapşırıq — əsaslandırma
🔴 Yaratma (DOK-4): {max(1, count*5//100)} tapşırıq — layihə

HƏR TAPŞIRIQ FORMATI:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🟤 BLOOM: XATIRLAMA │ DOK-1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  1. [Tapşırıq mətni — dərslikdəki terminologiya ilə]

     A) ...    B) ...    C) ...    D) ...

     ┌─────────────────────────────────────┐
     │ ✅ Cavab: [X]                       │
     │ 📖 Dərslik: səh. XX                │
     │ 📊 Çətinlik: Asan │ ⏱️ 1 dəq │ 🎯 1 bal │
     │ 📝 Distraktor: A—[xəta], C—[xəta] │
     └─────────────────────────────────────┘

REAL HƏYAT konteksti: Bakı, manat, Xəzər, metro, ASAN xidmət
Açıq cavablarda MÜTLƏQ rubrika (0-1-2-3 bal)
DOK-3/4 tapşırıqlarda addım-addım həll

SONDA STATİSTİKA BLOKU:
╔═══════════════════════════════════════════════════╗
║  📊 Bloom: 🟤X 🟢X 🔵X 🟡X 🟠X 🔴X             ║
║  DOK: 1:15% │ 2:35% │ 3:35% │ 4:15%             ║
║  Vaxt: ~XX dəq │ Maks.bal: XX                     ║
║  📖 Dərslik: Riyaziyyat {grade}, səh. XX-YY      ║
║  🌍 PISA ✅ TIMSS ✅ Sinqapur ✅ Finlandiya ✅    ║
╚═══════════════════════════════════════════════════╝

Faylı yaz: output/tapshiriqlar/sinif{grade}_{topic.replace(' ','_')}_test_{date.today()}.md
"""


def generate_lesson_prompt(grade: int, topic: str, duration: int) -> str:
    standard = find_standard(grade, topic)
    context = build_context(grade, topic)

    return f"""╔══════════════════════════════════════════════════════════════════╗
║  📐 DƏRS PLANI GENERASİYASI                                     ║
║  Sinif: {grade}-ci sinif  │  Mövzu: {topic}  │  Müddət: {duration} dəq  ║
║  Standart: {standard}
╚══════════════════════════════════════════════════════════════════╝

═══ DƏRSLİKDƏN KONTEKST ═══
{context}

═══ DƏRS PLANI TƏLİMATI ═══

Yuxarıdakı dərslik kontekstini oxu. {duration} dəqiqəlik dərs planı yarat.

QAYDALAR:
1. Dərslikdəki TERMİNOLOGİYANI istifadə et
2. Dərslikdəki TAPŞIRIQ NÖMRƏLƏRİNƏ istinad et (səh. XX, tapşırıq №YY)
3. Dərslikdəki "Araşdır-müzakirə" bölmələrini motivasiya üçün istifadə et

5 MƏRHƏLƏ:

📍 MƏRHƏLƏ 1: MOTİVASİYA (10% — {duration*10//100} dəq)
- Dərslikdəki "Araşdır" tapşırığı
- Real həyat sualı (Azərbaycan konteksti)
- Əvvəlki mövzu ilə əlaqə

📍 MƏRHƏLƏ 2: YENİ BİLİYİN KƏŞFİ (30% — {duration*30//100} dəq)
- Sinqapur CPA: Konkret → Təsviri → Mücərrəd
- Dərslikdəki izah məntiqi ilə
- Lövhə yazısı = dərslikdəki qayda
- Qrup işi (4 nəfər)

📍 MƏRHƏLƏ 3: BİRGƏ TƏTBİQ (25% — {duration*25//100} dəq)
- "Mən edirəm" → "Biz edirik" → "Sən edirsən"
- Dərslikdən tapşırıq №... (səhifə ilə)
- DOK-1 → DOK-2 → DOK-3 artan çətinlik

📍 MƏRHƏLƏ 4: MÜSTƏQİL TƏTBİQ (25% — {duration*25//100} dəq)
- 🟢 Baza: Dərslikdən standart tapşırıqlar
- 🟡 Orta: Tətbiqi tapşırıqlar
- 🔴 Yüksək: PISA tipli — real həyat, çox addımlı

📍 MƏRHƏLƏ 5: YEKUNLAŞDİRMA (10% — {duration*10//100} dəq)
- 3-2-1 strategiyası
- Çıxış bileti (1 sual)
- Ev tapşırığı: dərslikdən səhifə/tapşırıq nömrəsi

FORMAT:
╔═════════════════════════════════════════════════════════════╗
║                    📐 DƏRS PLANI                            ║
║  Fənn: Riyaziyyat          Sinif: {grade}-ci sinif          ║
║  Mövzu: [DƏRSLİKDƏKİ ADI İLƏ]                             ║
║  Müddət: {duration} dəq         Dərslik: səh. XX-YY        ║
║  Standart: {standard}
╚═════════════════════════════════════════════════════════════╝

Hər mərhələdə:
👨‍🏫 Müəllim fəaliyyəti: [...]
👨‍🎓 Şagird fəaliyyəti: [...]
📖 Dərslik istinadı: səh. XX, tapşırıq №YY
⏱️ Zaman: X dəqiqə
📊 Qiymətləndirmə: [formativ/summativ]

SONDA ANALİZ BLOKU:
┌───────────────────────────────────────────────────┐
│  📊 DƏRS ANALİZİ                                  │
│  Bloom: 🟤15% 🟢20% 🔵30% 🟡25% 🟠5% 🔴5%     │
│  Zaman: Müəllim 30% │ Şagird 50% │ Müzakirə 20% │
│  📖 Dərslik istinadları: səh. XX, YY, ZZ         │
│  🌍 PISA ✅ TIMSS ✅ Sinqapur CPA ✅              │
└───────────────────────────────────────────────────┘

Faylı yaz: output/ders_planlari/sinif{grade}_{topic.replace(' ','_')}_ders_{date.today()}.md
"""


def main():
    if len(sys.argv) < 4:
        print("""
╔══════════════════════════════════════════════════════════════╗
║  📐 Riy_Muellim_Agent — Kontekst Generatoru                 ║
╚══════════════════════════════════════════════════════════════╝

İstifadə:
  python3 scripts/generate.py <sinif> <mövzu> <tip> [say/müddət]

Nümunələr:
  python3 scripts/generate.py 6 faiz test 15
  python3 scripts/generate.py 8 pifaqor ders 45
  python3 scripts/generate.py 5 kəsr test 20
  python3 scripts/generate.py 7 "xətti funksiya" ders 90
  python3 scripts/generate.py 3 vurma test 12

Parametrlər:
  sinif    — 1-dən 11-ə qədər
  mövzu    — dərslikdəki mövzu adı
  tip      — "test" və ya "ders"
  say      — test üçün tapşırıq sayı (default: 15)
  müddət   — dərs üçün dəqiqə (default: 45)
""")
        return

    grade = int(sys.argv[1])
    topic = sys.argv[2]
    task_type = sys.argv[3]
    param = int(sys.argv[4]) if len(sys.argv) > 4 else (15 if task_type == "test" else 45)

    if task_type == "test":
        prompt = generate_test_prompt(grade, topic, param)
    elif task_type in ("ders", "lesson"):
        prompt = generate_lesson_prompt(grade, topic, param)
    else:
        print(f"❌ Naməlum tip: {task_type}. 'test' və ya 'ders' istifadə edin.")
        return

    # Prompt-u fayla yaz
    prompt_file = OUTPUT_DIR / f"_last_prompt.md"
    with open(prompt_file, "w", encoding="utf-8") as f:
        f.write(prompt)

    # Ekrana çıxar
    print(prompt)
    print()
    print(f"💾 Prompt saxlandı: {prompt_file}")
    print()
    print("═══ NÖVBƏTİ ADDIM ═══")
    print("Yuxarıdakı prompt-u Claude Code-a yapışdırın,")
    print("və ya Claude Code-da yazın:")
    if task_type == "test":
        print(f'  "{grade}-ci sinif, {topic}, {param} test tapşırığı yaz"')
    else:
        print(f'  "{grade}-ci sinif, {topic}, {param} dəqiqəlik dərs planı"')


if __name__ == "__main__":
    main()
