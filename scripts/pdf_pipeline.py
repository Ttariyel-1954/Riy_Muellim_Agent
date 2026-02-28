#!/usr/bin/env python3
"""
╔══════════════════════════════════════════════════════════════════╗
║  📐 Riy_Muellim_Agent — PDF Dərslik Emal Pipeline              ║
║                                                                  ║
║  Bu skript riyaziyyat dərsliklərini (PDF) oxuyur,                ║
║  mövzulara görə parçalayır və axtarış üçün indeksləyir.         ║
║                                                                  ║
║  İstifadə: python3 scripts/pdf_pipeline.py                      ║
║  Nəticə:  derslikler/chunks/ — JSON chunk faylları              ║
║           derslikler/index.json — Master indeks                  ║
╚══════════════════════════════════════════════════════════════════╝
"""

import os
import sys
import json
import re
import hashlib
from pathlib import Path
from datetime import datetime
from typing import Optional, List, Dict

try:
    import pdfplumber
except ImportError:
    print("❌ pdfplumber yüklənməyib. Yükləyin:")
    print("   pip install pdfplumber")
    sys.exit(1)


# ─── KONFİQURASİYA ────────────────────────────────────────────────

BASE_DIR = Path(__file__).resolve().parent.parent
PDF_DIR = BASE_DIR / "derslikler" / "pdf"
CHUNKS_DIR = BASE_DIR / "derslikler" / "chunks"
INDEX_FILE = BASE_DIR / "derslikler" / "index.json"

# Dərslik fayl adları → sinif + hissə mapping
TEXTBOOK_MAP = {
    "riyaziyyat_1_I_hisse.pdf":  {"grade": 1, "part": 1, "parts_total": 2},
    "riyaziyyat_1_II_hisse.pdf": {"grade": 1, "part": 2, "parts_total": 2},
    "riyaziyyat_2_I_hisse.pdf":  {"grade": 2, "part": 1, "parts_total": 2},
    "riyaziyyat_2_II_hisse.pdf": {"grade": 2, "part": 2, "parts_total": 2},
    "riyaziyyat_3_I_hisse.pdf":  {"grade": 3, "part": 1, "parts_total": 2},
    "riyaziyyat_3_II_hisse.pdf": {"grade": 3, "part": 2, "parts_total": 2},
    "riyaziyyat_4_I_hisse.pdf":  {"grade": 4, "part": 1, "parts_total": 2},
    "riyaziyyat_4_II_hisse.pdf": {"grade": 4, "part": 2, "parts_total": 2},
    "riyaziyyat_5_I_hisse.pdf":  {"grade": 5, "part": 1, "parts_total": 2},
    "riyaziyyat_5_II_hisse.pdf": {"grade": 5, "part": 2, "parts_total": 2},
    "riyaziyyat_6_I_hisse.pdf":  {"grade": 6, "part": 1, "parts_total": 2},
    "riyaziyyat_6_II_hisse.pdf": {"grade": 6, "part": 2, "parts_total": 2},
    "riyaziyyat_7.pdf":          {"grade": 7, "part": 1, "parts_total": 1},
    "riyaziyyat_8.pdf":          {"grade": 8, "part": 1, "parts_total": 1},
    "riyaziyyat_9.pdf":          {"grade": 9, "part": 1, "parts_total": 1},
    "riyaziyyat_10.pdf":         {"grade": 10, "part": 1, "parts_total": 1},
    "riyaziyyat_11.pdf":         {"grade": 11, "part": 1, "parts_total": 1},
}

# Riyaziyyat mövzu açar sözləri (Azərbaycan dilində)
TOPIC_KEYWORDS = {
    "ededler": [
        "natural ədəd", "tam ədəd", "rasional ədəd", "irrasional",
        "həqiqi ədəd", "mürəkkəb ədəd", "sadə ədəd", "bölünmə",
        "qalıqlı bölmə", "böyük ortaq böl", "kiçik ortaq böl",
        "ƏBOB", "ƏKOB", "ədədlər", "rəqəm", "say", "onluq",
        "kəsr", "düzgün kəsr", "düzgün olmayan", "qarışıq ədəd",
        "faiz", "nisbət", "tənasüb", "mütənasib"
    ],
    "cebr": [
        "tənlik", "bərabərsizlik", "ifadə", "dəyişən", "əmsal",
        "çoxhədli", "birhədli", "vuruqlara ayırma", "kvadrat tənlik",
        "diskriminant", "köklər", "Vyet teoremi", "sistem",
        "funksiya", "xətti funksiya", "kvadrat funksiya",
        "qrafik", "ardıcıllıq", "proqressiya", "arifmetik",
        "həndəsi proqressiya", "limit", "törəmə", "inteqral",
        "logarifm", "triqonometriya", "sin", "cos", "tg"
    ],
    "hendese": [
        "nöqtə", "düz xətt", "şüa", "parça", "bucaq",
        "üçbucaq", "dördbucaqlı", "çevrə", "dairə",
        "perimetr", "sahə", "həcm", "paralel", "perpendikulyar",
        "simmetriya", "oxşarlıq", "bərabərlik", "Pifaqor",
        "teorem", "sinus", "kosinus", "tangens",
        "vektor", "koordinat", "fəza", "prizma", "piramida",
        "silindr", "konus", "kürə", "müstəvi",
        "trapesiya", "paraleloqram", "romb", "düzbucaqlı",
        "kvadrat", "beşbucaqlı", "altıbucaqlı", "çoxbucaqlı"
    ],
    "statistika": [
        "statistika", "verilən", "diaqram", "qrafik",
        "orta", "median", "moda", "yayılma",
        "ehtimal", "hadisə", "təsadüfi", "eksperiment",
        "kombinatorika", "yerləşdirmə", "birləşmə",
        "dairəvi diaqram", "sütunlu diaqram", "xətti diaqram",
        "tezlik", "cədvəl", "histoqram"
    ],
    "olcme": [
        "uzunluq", "kütlə", "həcm", "zaman", "pul",
        "metr", "santimetr", "kilometr", "litr",
        "kiloqram", "qram", "ton", "saat", "dəqiqə",
        "saniyə", "manat", "qəpik", "ölçmə",
        "temperatur", "dərəcə"
    ]
}

# Fəsil/Bölmə başlıq patternləri
CHAPTER_PATTERNS = [
    r'(?:FƏSİL|FƏSIL|Fəsil)\s*[\dIVXLCM]+[.:]\s*(.+)',
    r'(?:BÖLMƏ|Bölmə|BOLME)\s*[\dIVXLCM]+[.:]\s*(.+)',
    r'(?:MÖVZU|Mövzu|MOVZU)\s*[\dIVXLCM]+[.:]\s*(.+)',
    r'^(\d+)\.\s+([A-ZƏÜÖĞIŞÇa-zəüöğışç].{5,60})$',
    r'^§\s*(\d+)\.\s*(.+)',
    r'^(\d+\.\d+)\.\s*(.+)',
]


# ─── PDF MƏTN ÇIXARMA ─────────────────────────────────────────────

def extract_text_from_pdf(pdf_path: Path) -> List[Dict]:
    """PDF-dən səhifə-səhifə mətn çıxarır."""
    pages = []
    print(f"  📖 Oxunur: {pdf_path.name}", end="", flush=True)

    try:
        with pdfplumber.open(pdf_path) as pdf:
            total = len(pdf.pages)
            for i, page in enumerate(pdf.pages):
                text = page.extract_text() or ""
                # Cədvəlləri də çıxar
                tables = page.extract_tables() or []
                table_text = ""
                for table in tables:
                    if table:
                        for row in table:
                            cells = [str(c) if c else "" for c in row]
                            table_text += " | ".join(cells) + "\n"

                pages.append({
                    "page_num": i + 1,
                    "text": text.strip(),
                    "tables": table_text.strip(),
                    "has_tables": len(tables) > 0,
                    "char_count": len(text)
                })

                # Progress
                if (i + 1) % 20 == 0:
                    print(f" [{i+1}/{total}]", end="", flush=True)

        print(f" ✅ {len(pages)} səhifə")
    except Exception as e:
        print(f" ❌ Xəta: {e}")

    return pages


# ─── MÖVZU DETEKTORU ──────────────────────────────────────────────

def detect_chapter_boundary(text: str) -> Optional[str]:
    """Mətndə fəsil/bölmə başlığı axtarır."""
    for pattern in CHAPTER_PATTERNS:
        match = re.search(pattern, text, re.MULTILINE)
        if match:
            return match.group(0).strip()
    return None


def detect_content_area(text: str) -> str:
    """Mətnin hansı riyaziyyat sahəsinə aid olduğunu müəyyən edir."""
    text_lower = text.lower()
    scores = {}
    for area, keywords in TOPIC_KEYWORDS.items():
        score = sum(1 for kw in keywords if kw.lower() in text_lower)
        scores[area] = score

    if max(scores.values()) == 0:
        return "umumi"

    return max(scores, key=scores.get)


def extract_topic_from_text(text: str) -> str:
    """Mətndən mövzu adını çıxarmağa çalışır."""
    # Fəsil/mövzu başlığı
    for pattern in CHAPTER_PATTERNS:
        match = re.search(pattern, text, re.MULTILINE)
        if match:
            groups = match.groups()
            # Son qrupu başlıq kimi götür
            return groups[-1].strip()[:100]

    # Əgər başlıq tapılmadısa, ilk 100 simvol
    first_line = text.split("\n")[0].strip()
    return first_line[:100] if first_line else "Adsız bölmə"


# ─── CHUNK YARATMA ────────────────────────────────────────────────

def create_chunks(pages, grade: int, part: int,
                  filename: str, chunk_size: int = 3) -> List[Dict]:
    """
    Səhifələri mövzu əsaslı chunk-lara böl.

    Strategiya:
    1. Fəsil/bölmə başlıqları tapıldıqda yeni chunk başla
    2. Əks halda, hər chunk_size səhifəni birləşdir
    3. Hər chunk-a metadata əlavə et
    """
    chunks = []
    current_chunk_pages = []
    current_chapter = None
    chunk_id = 0

    for page in pages:
        text = page["text"]
        if not text or len(text) < 30:
            continue

        # Fəsil başlığı?
        new_chapter = detect_chapter_boundary(text)
        if new_chapter and current_chunk_pages:
            # Əvvəlki chunk-ı saxla
            chunk_id += 1
            chunks.append(_build_chunk(
                current_chunk_pages, grade, part, filename,
                chunk_id, current_chapter
            ))
            current_chunk_pages = []
            current_chapter = new_chapter

        if new_chapter:
            current_chapter = new_chapter

        current_chunk_pages.append(page)

        # chunk_size səhifəyə çatdıqda (fəsil başlığı olmadan)
        if len(current_chunk_pages) >= chunk_size and not new_chapter:
            chunk_id += 1
            chunks.append(_build_chunk(
                current_chunk_pages, grade, part, filename,
                chunk_id, current_chapter
            ))
            current_chunk_pages = []

    # Son qalan səhifələr
    if current_chunk_pages:
        chunk_id += 1
        chunks.append(_build_chunk(
            current_chunk_pages, grade, part, filename,
            chunk_id, current_chapter
        ))

    return chunks


def _build_chunk(pages, grade: int, part: int,
                 filename: str, chunk_id: int, chapter=None) -> dict:
    """Bir chunk obyekti yaradır."""
    full_text = "\n\n".join(p["text"] for p in pages if p["text"])
    table_text = "\n".join(p["tables"] for p in pages if p["tables"])

    page_start = pages[0]["page_num"]
    page_end = pages[-1]["page_num"]

    content_area = detect_content_area(full_text)
    topic = extract_topic_from_text(full_text) if not chapter else chapter

    # Unikal ID
    uid = hashlib.md5(f"{filename}_{chunk_id}_{page_start}".encode()).hexdigest()[:12]

    return {
        "id": f"g{grade}_p{part}_c{chunk_id:03d}_{uid}",
        "grade": grade,
        "part": part,
        "source_file": filename,
        "page_start": page_start,
        "page_end": page_end,
        "chapter": chapter,
        "topic": topic,
        "content_area": content_area,
        "text": full_text,
        "tables": table_text,
        "char_count": len(full_text),
        "word_count": len(full_text.split()),
        "has_tables": any(p["has_tables"] for p in pages),
        "keywords": _extract_keywords(full_text)
    }


def _extract_keywords(text: str) -> List[str]:
    """Mətndən açar sözlər çıxarır."""
    keywords = set()
    text_lower = text.lower()
    for area, kws in TOPIC_KEYWORDS.items():
        for kw in kws:
            if kw.lower() in text_lower:
                keywords.add(kw)
    return sorted(keywords)[:20]


# ─── İNDEKS YARATMA ──────────────────────────────────────────────

def build_master_index(all_chunks) -> dict:
    """Bütün chunk-lar üçün master axtarış indeksi yaradır."""

    # Sinif → mövzu → chunk ID mapping
    grade_index = {}
    topic_index = {}
    content_area_index = {}
    keyword_index = {}

    for chunk in all_chunks:
        g = chunk["grade"]
        ca = chunk["content_area"]
        cid = chunk["id"]

        # Sinif indeksi
        grade_index.setdefault(str(g), []).append(cid)

        # Mövzu indeksi
        if chunk["topic"]:
            topic_key = chunk["topic"][:60].lower()
            topic_index.setdefault(topic_key, []).append(cid)

        # Content area indeksi
        content_area_index.setdefault(ca, []).append(cid)

        # Keyword indeksi
        for kw in chunk["keywords"]:
            keyword_index.setdefault(kw.lower(), []).append(cid)

    return {
        "created_at": datetime.now().isoformat(),
        "total_chunks": len(all_chunks),
        "grades": sorted(set(str(c["grade"]) for c in all_chunks)),
        "content_areas": sorted(set(c["content_area"] for c in all_chunks)),
        "index": {
            "by_grade": grade_index,
            "by_topic": topic_index,
            "by_content_area": content_area_index,
            "by_keyword": keyword_index
        },
        "chunk_summary": [
            {
                "id": c["id"],
                "grade": c["grade"],
                "part": c["part"],
                "pages": f"{c['page_start']}-{c['page_end']}",
                "topic": c["topic"][:80],
                "content_area": c["content_area"],
                "words": c["word_count"]
            }
            for c in all_chunks
        ]
    }


# ─── ƏSAS PROQRAM ────────────────────────────────────────────────

def main():
    print()
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║  📐 Riy_Muellim_Agent — PDF Dərslik Emal Pipeline          ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    print()

    # Papkaları yarat
    CHUNKS_DIR.mkdir(parents=True, exist_ok=True)

    # PDF faylları tap
    pdf_files = sorted(PDF_DIR.glob("*.pdf"))
    if not pdf_files:
        print(f"❌ PDF tapılmadı: {PDF_DIR}")
        print("   Dərslikləri bu papkaya qoyun:")
        print(f"   {PDF_DIR}/")
        print()
        print("   Gözlənilən fayllar:")
        for name in sorted(TEXTBOOK_MAP.keys()):
            print(f"     • {name}")
        sys.exit(1)

    print(f"📁 PDF papkası: {PDF_DIR}")
    print(f"📁 Chunk papkası: {CHUNKS_DIR}")
    print(f"📄 Tapılmış PDF: {len(pdf_files)}")
    print()

    # Tapılmayan faylları yoxla
    found = {f.name for f in pdf_files}
    expected = set(TEXTBOOK_MAP.keys())
    missing = expected - found
    extra = found - expected

    if missing:
        print(f"⚠️  Çatışmayan dərsliklər ({len(missing)}):")
        for m in sorted(missing):
            print(f"   • {m}")
        print()

    if extra:
        print(f"ℹ️  Əlavə PDF-lər (emal edilməyəcək): {sorted(extra)}")
        print()

    # ═══ HƏR PDF-Nİ EMAL ET ═══
    all_chunks = []
    stats = {"files": 0, "pages": 0, "chunks": 0, "words": 0}

    for pdf_file in pdf_files:
        if pdf_file.name not in TEXTBOOK_MAP:
            continue

        meta = TEXTBOOK_MAP[pdf_file.name]
        grade = meta["grade"]
        part = meta["part"]

        print(f"━━━ Sinif {grade}, Hissə {part} ━━━")

        # 1. Mətn çıxar
        pages = extract_text_from_pdf(pdf_file)
        if not pages:
            continue

        # 2. Chunk-lara böl
        chunks = create_chunks(pages, grade, part, pdf_file.name)
        print(f"  📦 {len(chunks)} chunk yaradıldı")

        # 3. Chunk-ları fayla yaz
        chunk_file = CHUNKS_DIR / f"sinif{grade}_hisse{part}_chunks.json"
        with open(chunk_file, "w", encoding="utf-8") as f:
            json.dump(chunks, f, ensure_ascii=False, indent=2)
        print(f"  💾 Saxlandı: {chunk_file.name}")

        # 4. Tam mətni də saxla (reference üçün)
        full_text_file = CHUNKS_DIR / f"sinif{grade}_hisse{part}_fulltext.txt"
        with open(full_text_file, "w", encoding="utf-8") as f:
            for page in pages:
                f.write(f"\n{'='*60}\n")
                f.write(f"SƏHİFƏ {page['page_num']}\n")
                f.write(f"{'='*60}\n\n")
                f.write(page["text"])
                f.write("\n")
                if page["tables"]:
                    f.write(f"\n[CƏDVƏL]\n{page['tables']}\n")
        print(f"  📝 Tam mətn: {full_text_file.name}")

        all_chunks.extend(chunks)
        stats["files"] += 1
        stats["pages"] += len(pages)
        stats["chunks"] += len(chunks)
        stats["words"] += sum(c["word_count"] for c in chunks)
        print()

    # ═══ MASTER İNDEKS ═══
    if all_chunks:
        print("━━━ Master İndeks Yaradılır ━━━")
        index = build_master_index(all_chunks)
        with open(INDEX_FILE, "w", encoding="utf-8") as f:
            json.dump(index, f, ensure_ascii=False, indent=2)
        print(f"  📊 Saxlandı: {INDEX_FILE.name}")
        print()

    # ═══ NƏTİCƏ STATİSTİKA ═══
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║  📊 NƏTİCƏ                                                 ║")
    print("╠══════════════════════════════════════════════════════════════╣")
    print(f"║  📄 Emal edilən PDF:     {stats['files']:>4}                              ║")
    print(f"║  📃 Ümumi səhifə:        {stats['pages']:>4}                              ║")
    print(f"║  📦 Yaradılmış chunk:    {stats['chunks']:>4}                              ║")
    print(f"║  📝 Ümumi söz sayı:     {stats['words']:>6}                            ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    print()

    # Content area paylanması
    ca_counts = {}
    for c in all_chunks:
        ca_counts[c["content_area"]] = ca_counts.get(c["content_area"], 0) + 1
    print("  Məzmun sahəsi paylanması:")
    for ca, cnt in sorted(ca_counts.items(), key=lambda x: -x[1]):
        bar = "█" * (cnt * 30 // max(ca_counts.values()))
        print(f"    {ca:15s} {bar} {cnt}")
    print()

    print("✅ Pipeline tamamlandı!")
    print()
    print("Növbəti addım: Claude Code-da bu əmri işlədin:")
    print('  "6-cı sinif, Faizlər, 15 test tapşırığı yaz"')
    print()


if __name__ == "__main__":
    main()
