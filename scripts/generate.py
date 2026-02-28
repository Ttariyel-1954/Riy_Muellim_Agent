#!/usr/bin/env python3
"""
Sinif + movzu verilende derslikden kontekst cixarir ve prompt yaradir.
Istifade: python3 scripts/generate.py 6 faiz test 15
"""
import sys, json, os
from pathlib import Path
from datetime import date

BASE_DIR = Path(__file__).resolve().parent.parent
CHUNKS_DIR = BASE_DIR / "derslikler" / "chunks"
OUTPUT_DIR = BASE_DIR / "output"

STANDARDS = {
    1: {"ededler":"R1.1 — Natural ədədləri 100 daxilində tanıyır, sayır, müqayisə edir","hendese":"R1.3 — Sadə həndəsi fiqurları tanıyır","olcme":"R1.5 — Uzunluğu qeyri-standart vahidlərlə ölçür"},
    2: {"ededler":"R2.1 — Natural ədədləri 1000 daxilində tanıyır, toplama-çıxma","hendese":"R2.3 — Həndəsi fiqurların xassələrini müqayisə edir","olcme":"R2.5 — Uzunluq, kütlə vahidlərini bilir"},
    3: {"ededler":"R3.1 — Çoxrəqəmli ədədlərlə toplama, çıxma; vurma cədvəli","hendese":"R3.3 — Perimetri hesablayır, simmetriya","olcme":"R3.5 — Zaman, pul vahidləri"},
    4: {"ededler":"R4.1 — Çoxrəqəmli ədədlərlə vurma, bölmə; sadə kəsrlər","hendese":"R4.3 — Sahəni hesablayır","olcme":"R4.5 — Həcm, tutum vahidləri"},
    5: {"ededler":"R5.1 — Onluq kəsrlər, adi kəsrlər, əməllər","cebr":"R5.2 — Sadə tənliklər","hendese":"R5.3 — Üçbucaq və dördbucaqlıların sahəsi","statistika":"R5.4 — Diaqramlar, orta ədəd"},
    6: {"ededler":"R6.1 — Müsbət və mənfi ədədlər, rasional ədədlər, faiz","cebr":"R6.2 — Cəbri ifadələr, xətti tənliklər","hendese":"R6.3 — Bucaqlar, paralel xətlər, üçbucaq","statistika":"R6.4 — Statistik verilənlər, median, moda"},
    7: {"ededler":"R7.1 — Nisbət, tənasüb, faiz hesablamaları","cebr":"R7.2 — Xətti funksiya, qrafik, tənliklər sistemi","hendese":"R7.3 — Çevrə, dairə, Pifaqor teoremi","statistika":"R7.4 — Ehtimal, kombinatorika əsasları"},
    8: {"cebr":"R8.1 — Kvadrat köklər, irrasional ədədlər, çoxhədlilər","hendese":"R8.2 — Pifaqor teoremi, oxşar üçbucaqlar, vektor","statistika":"R8.3 — Ehtimal, statistika"},
    9: {"cebr":"R9.1 — Kvadrat tənliklər, diskriminant, Vyet teoremi","hendese":"R9.2 — Triqonometriya, sin/cos/tg, vektor əməlləri","statistika":"R9.3 — Kombinatorika, ehtimal"},
    10: {"cebr":"R10.1 — Funksiyalar (triqonometrik, göstərici, loqarifmik)","hendese":"R10.2 — Fəza həndəsəsi, prizma, piramida","statistika":"R10.3 — Statistik paylanmalar"},
    11: {"cebr":"R11.1 — Limit, törəmə, inteqral","hendese":"R11.2 — Silindr, konus, kürə","statistika":"R11.3 — Ehtimal nəzəriyyəsi"},
}

TOPIC_AREA = {
    "faiz":"ededler","kəsr":"ededler","onluq":"ededler","ədəd":"ededler","natural":"ededler","rasional":"ededler",
    "toplama":"ededler","çıxma":"ededler","vurma":"ededler","bölmə":"ededler","nisbət":"ededler","tənasüb":"ededler",
    "tənlik":"cebr","funksiya":"cebr","ifadə":"cebr","çoxhədli":"cebr","kvadrat":"cebr","xətti":"cebr",
    "sistem":"cebr","köklər":"cebr","diskriminant":"cebr","törəmə":"cebr","inteqral":"cebr","limit":"cebr","loqarifm":"cebr","proqressiya":"cebr",
    "üçbucaq":"hendese","dördbucaqlı":"hendese","dairə":"hendese","çevrə":"hendese","bucaq":"hendese",
    "sahə":"hendese","perimetr":"hendese","həcm":"hendese","pifaqor":"hendese","vektor":"hendese",
    "simmetriya":"hendese","koordinat":"hendese","triqonometriya":"hendese","sin":"hendese","cos":"hendese",
    "fiqur":"hendese","prizma":"hendese","piramida":"hendese","silindr":"hendese",
    "statistika":"statistika","ehtimal":"statistika","diaqram":"statistika","orta":"statistika","median":"statistika","kombinatorika":"statistika",
    "uzunluq":"olcme","kütlə":"olcme","zaman":"olcme","pul":"olcme","ölçmə":"olcme","litr":"olcme",
}

def detect_area(topic):
    t = topic.lower()
    for k, v in TOPIC_AREA.items():
        if k in t:
            return v
    return "ededler"

def find_standard(grade, topic):
    area = detect_area(topic)
    gs = STANDARDS.get(grade, {})
    return gs.get(area, list(gs.values())[0] if gs else f"R{grade}.1 — {grade}-ci sinif standart")

def load_chunks(grade):
    chunks = []
    for f in sorted(CHUNKS_DIR.glob(f"sinif{grade}_*_chunks.json")):
        with open(f, "r", encoding="utf-8") as fh:
            chunks.extend(json.load(fh))
    return chunks

def search_chunks(grade, topic, max_r=3):
    chunks = load_chunks(grade)
    if not chunks: return []
    tl = topic.lower()
    tw = [w for w in tl.split() if len(w) >= 3]
    scored = []
    for c in chunks:
        score = 0
        s = (c.get("text","").lower() + " " + (c.get("topic","") or "").lower() + " " + (c.get("chapter","") or "").lower() + " " + " ".join(c.get("keywords",[])))
        if tl in s: score += 10
        for w in tw:
            score += min(s.count(w), 5)
        if c.get("chapter") and tl in c["chapter"].lower(): score += 15
        if score > 0: scored.append((score, c))
    scored.sort(key=lambda x: -x[0])
    return [c for _, c in scored[:max_r]]

def build_context(grade, topic):
    results = search_chunks(grade, topic)
    if not results: return f"[Dərslikdə '{topic}' tapılmadı. Ümumi bilik əsasında yazılacaq.]"
    parts = []
    for c in results:
        text = c.get("text","")
        if len(text) > 4000: text = text[:4000] + "\n... [davamı dərslikdə]"
        parts.append(f"\n━━━ Dərslik: {c.get('source_file','?')}, səh. {c['page_start']}-{c['page_end']} ━━━\nFəsil: {c.get('chapter','—')}\nMövzu: {c.get('topic','—')}\nAçar sözlər: {', '.join(c.get('keywords',[])[:10])}\n\n{text}\n")
    return "\n".join(parts)

def gen_test(grade, topic, count):
    std = find_standard(grade, topic)
    ctx = build_context(grade, topic)
    return f"""╔══════════════════════════════════════════════════════════════════╗
║  📐 TEST TAPŞIRIQLARI GENERASİYASI                               ║
║  Sinif: {grade}-ci sinif  │  Mövzu: {topic}  │  Say: {count}            ║
║  Standart: {std}
╚══════════════════════════════════════════════════════════════════╝

═══ DƏRSLİKDƏN KONTEKST ═══
{ctx}

═══ TAPŞIRIQ YARATMA TƏLİMATI ═══

Yuxarıdakı dərslik kontekstini oxu. {count} tapşırıq yarat.

QAYDALAR:
1. Dərslikdəki TERMİNOLOGİYANI istifadə et
2. Dərslikdəki NÜMUNƏ tiplərinə oxşar tapşırıqlar yaz
3. Dərslik SƏHİFƏ NÖMRƏSİNƏ istinad et

BLOOM PAYLANMASI ({count} tapşırıq):
🟤 Xatırlama (DOK-1): {max(1,count*15//100)} tapşırıq — çoxseçimli
🟢 Anlama (DOK-1-2): {max(1,count*20//100)} tapşırıq — qısa cavab
🔵 Tətbiqetmə (DOK-2): {max(1,count*25//100)} tapşırıq — hesablama
🟡 Təhlil (DOK-3): {max(1,count*25//100)} tapşırıq — çox addımlı
🟠 Qiymətləndirmə (DOK-3): {max(1,count*10//100)} tapşırıq — əsaslandırma
🔴 Yaratma (DOK-4): {max(1,count*5//100)} tapşırıq — layihə

HƏR TAPŞIRIQ FORMATI:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🟤 BLOOM: XATIRLAMA │ DOK-1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  1. [Tapşırıq — dərslikdəki terminologiya ilə]
     A) ...    B) ...    C) ...    D) ...
     ┌─────────────────────────────────────┐
     │ ✅ Cavab: [X]                       │
     │ 📖 Dərslik: səh. XX                │
     │ 📊 Çətinlik: Asan │ ⏱️ 1 dəq       │
     │ 📝 Distraktor: A—[xəta], C—[xəta] │
     └─────────────────────────────────────┘

Real həyat konteksti: Bakı, manat, Xəzər, metro, ASAN xidmət
Açıq cavablarda rubrika: 0-1-2-3 bal
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

def gen_lesson(grade, topic, dur):
    std = find_standard(grade, topic)
    ctx = build_context(grade, topic)
    return f"""╔══════════════════════════════════════════════════════════════════╗
║  📐 DƏRS PLANI GENERASİYASI                                     ║
║  Sinif: {grade}-ci sinif  │  Mövzu: {topic}  │  Müddət: {dur} dəq       ║
║  Standart: {std}
╚══════════════════════════════════════════════════════════════════╝

═══ DƏRSLİKDƏN KONTEKST ═══
{ctx}

═══ DƏRS PLANI TƏLİMATI ═══

Yuxarıdakı dərslik kontekstini oxu. {dur} dəqiqəlik dərs planı yarat.

QAYDALAR:
1. Dərslikdəki TERMİNOLOGİYANI istifadə et
2. Dərslikdəki TAPŞIRIQ NÖMRƏLƏRİNƏ istinad et (səh. XX, tapşırıq №YY)
3. Dərslikdəki "Araşdır-müzakirə" bölmələrini motivasiya üçün istifadə et

5 MƏRHƏLƏ:

📍 MƏRHƏLƏ 1: MOTİVASİYA ({dur*10//100} dəq)
- Dərslikdəki "Araşdır" tapşırığı
- Real həyat sualı (Azərbaycan konteksti)

📍 MƏRHƏLƏ 2: YENİ BİLİYİN KƏŞFİ ({dur*30//100} dəq)
- Sinqapur CPA: Konkret → Təsviri → Mücərrəd
- Dərslikdəki izah, lövhə yazısı

📍 MƏRHƏLƏ 3: BİRGƏ TƏTBİQ ({dur*25//100} dəq)
- Mən edirəm → Biz edirik → Sən edirsən
- Dərslikdən tapşırıq №... (səhifə ilə)

📍 MƏRHƏLƏ 4: MÜSTƏQİL TƏTBİQ ({dur*25//100} dəq)
- 🟢 Baza: standart tapşırıqlar
- 🟡 Orta: tətbiqi tapşırıqlar
- 🔴 Yüksək: PISA tipli

📍 MƏRHƏLƏ 5: YEKUNLAŞDİRMA ({dur*10//100} dəq)
- Çıxış bileti, ev tapşırığı

FORMAT:
╔═════════════════════════════════════════════════════════════╗
║  📐 DƏRS PLANI                                             ║
║  Sinif: {grade}-ci sinif  │  Mövzu: [DƏRSLİKDƏKİ ADI]    ║
║  Müddət: {dur} dəq  │  Dərslik: səh. XX-YY               ║
║  Standart: {std}
╚═════════════════════════════════════════════════════════════╝

Hər mərhələdə: 👨‍🏫 müəllim, 👨‍🎓 şagird, 📖 dərslik istinadı, ⏱️ vaxt

SONDA ANALİZ BLOKU:
┌───────────────────────────────────────────────────┐
│  📊 Bloom: 🟤15% 🟢20% 🔵30% 🟡25% 🟠5% 🔴5%  │
│  Zaman: Müəllim 30% │ Şagird 50% │ Müzakirə 20% │
│  📖 Dərslik istinadları: səh. XX, YY, ZZ         │
│  🌍 PISA ✅ TIMSS ✅ Sinqapur CPA ✅              │
└───────────────────────────────────────────────────┘

Faylı yaz: output/ders_planlari/sinif{grade}_{topic.replace(' ','_')}_ders_{date.today()}.md
"""

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("""
İstifadə: python3 scripts/generate.py <sinif> <mövzu> <tip> [say/müddət]

Nümunələr:
  python3 scripts/generate.py 6 faiz test 15
  python3 scripts/generate.py 8 pifaqor ders 45
  python3 scripts/generate.py 5 kəsr test 20
""")
        sys.exit(0)
    grade = int(sys.argv[1])
    topic = sys.argv[2]
    ttype = sys.argv[3]
    param = int(sys.argv[4]) if len(sys.argv)>4 else (15 if ttype=="test" else 45)
    if ttype == "test":
        print(gen_test(grade, topic, param))
    elif ttype in ("ders","lesson"):
        print(gen_lesson(grade, topic, param))
    else:
        print(f"Naməlum tip: {ttype}. 'test' və ya 'ders' istifadə edin.")
