#!/usr/bin/env python3
"""
╔══════════════════════════════════════════════════════════════════╗
║  🔍 Dərslik Chunk Axtarış Utility                               ║
║                                                                  ║
║  Sinif + mövzu verildikdə müvafiq dərslik chunk-larını tapır.   ║
║                                                                  ║
║  İstifadə:                                                       ║
║    python3 scripts/search_chunks.py --grade 6 --topic "faiz"    ║
║    python3 scripts/search_chunks.py --grade 8 --topic "Pifaqor" ║
║    python3 scripts/search_chunks.py --grade 5 --area "ededler"  ║
║    python3 scripts/search_chunks.py --grade 3 --list-topics     ║
╚══════════════════════════════════════════════════════════════════╝
"""

import os
import sys
import json
import argparse
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent.parent
CHUNKS_DIR = BASE_DIR / "derslikler" / "chunks"
INDEX_FILE = BASE_DIR / "derslikler" / "index.json"


def load_index() -> dict | None:
    """Master indeksi yüklə."""
    if not INDEX_FILE.exists():
        print("❌ İndeks tapılmadı. Əvvəlcə pipeline işlədin:")
        print("   python3 scripts/pdf_pipeline.py")
        return None
    with open(INDEX_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


def load_chunks_for_grade(grade: int) -> list[dict]:
    """Müəyyən sinif üçün bütün chunk-ları yüklə."""
    chunks = []
    for chunk_file in sorted(CHUNKS_DIR.glob(f"sinif{grade}_*_chunks.json")):
        with open(chunk_file, "r", encoding="utf-8") as f:
            chunks.extend(json.load(f))
    return chunks


def search_by_topic(grade: int, topic: str, max_results: int = 5) -> list[dict]:
    """Sinif + mövzu üzrə axtarış."""
    chunks = load_chunks_for_grade(grade)
    if not chunks:
        return []

    topic_lower = topic.lower()
    topic_words = topic_lower.split()

    scored = []
    for chunk in chunks:
        score = 0
        searchable = (
            chunk["text"].lower() + " " +
            (chunk["topic"] or "").lower() + " " +
            (chunk["chapter"] or "").lower() + " " +
            " ".join(chunk.get("keywords", []))
        )

        # Tam uyğunluq
        if topic_lower in searchable:
            score += 10

        # Söz-söz uyğunluq
        for word in topic_words:
            if len(word) >= 3:  # Qısa sözləri keç
                count = searchable.count(word)
                score += min(count, 5)  # Max 5 hit per word

        # Keyword uyğunluq
        for kw in chunk.get("keywords", []):
            if any(w in kw.lower() for w in topic_words):
                score += 3

        # Chapter uyğunluq (böyük bonus)
        if chunk.get("chapter"):
            if topic_lower in chunk["chapter"].lower():
                score += 15

        if score > 0:
            scored.append((score, chunk))

    # Ən yüksək xal sırası
    scored.sort(key=lambda x: -x[0])
    return [c for _, c in scored[:max_results]]


def search_by_content_area(grade: int, area: str) -> list[dict]:
    """Sinif + məzmun sahəsi üzrə axtarış."""
    chunks = load_chunks_for_grade(grade)
    return [c for c in chunks if c["content_area"] == area]


def search_by_keyword(keyword: str) -> list[dict]:
    """Açar söz üzrə bütün siniflərdə axtarış."""
    index = load_index()
    if not index:
        return []

    keyword_lower = keyword.lower()
    chunk_ids = set()

    for kw, ids in index["index"]["by_keyword"].items():
        if keyword_lower in kw:
            chunk_ids.update(ids)

    # Chunk-ları yüklə
    results = []
    for grade_str in index["grades"]:
        grade = int(grade_str)
        chunks = load_chunks_for_grade(grade)
        for chunk in chunks:
            if chunk["id"] in chunk_ids:
                results.append(chunk)

    return results


def list_topics_for_grade(grade: int) -> list[str]:
    """Müəyyən sinif üçün mövcud mövzuları siyahıla."""
    chunks = load_chunks_for_grade(grade)
    topics = []
    for chunk in chunks:
        if chunk.get("chapter"):
            topics.append(f"📍 {chunk['chapter']} (səh. {chunk['page_start']}-{chunk['page_end']})")
        elif chunk.get("topic"):
            topics.append(f"  • {chunk['topic'][:80]} (səh. {chunk['page_start']}-{chunk['page_end']})")
    return topics


def format_chunk_for_output(chunk: dict, include_text: bool = True) -> str:
    """Chunk-ı oxunaqlı formatda çap et."""
    lines = []
    lines.append(f"┌──────────────────────────────────────────────────────────────")
    lines.append(f"│ 📦 Chunk: {chunk['id']}")
    lines.append(f"│ 📚 Sinif: {chunk['grade']}, Hissə: {chunk['part']}")
    lines.append(f"│ 📄 Səhifə: {chunk['page_start']}-{chunk['page_end']}")
    lines.append(f"│ 📍 Fəsil: {chunk.get('chapter', '—')}")
    lines.append(f"│ 🏷️  Mövzu: {chunk.get('topic', '—')[:80]}")
    lines.append(f"│ 📊 Sahə: {chunk['content_area']}")
    lines.append(f"│ 📝 Söz: {chunk['word_count']}, Simvol: {chunk['char_count']}")
    lines.append(f"│ 🔑 Açar sözlər: {', '.join(chunk.get('keywords', [])[:10])}")
    if chunk.get("has_tables"):
        lines.append(f"│ 📊 Cədvəl: Bəli")
    lines.append(f"└──────────────────────────────────────────────────────────────")

    if include_text:
        text = chunk["text"]
        if len(text) > 2000:
            text = text[:2000] + "\n... [kəsildi]"
        lines.append("")
        lines.append(text)
        lines.append("")

    return "\n".join(lines)


def get_context_for_generation(grade: int, topic: str) -> str:
    """
    TEST/DƏRS PLANI GENERASIYASI ÜÇÜN KONTEKST HAZIRLA.

    Bu funksiya Claude Code-un əsas axtarış funksiyasıdır.
    Sinif + mövzu verilir, dərslikdən müvafiq kontekst qaytarılır.
    """
    results = search_by_topic(grade, topic, max_results=3)

    if not results:
        return f"⚠️ Sinif {grade}, mövzu '{topic}' üçün dərslik konteksti tapılmadı."

    output = []
    output.append(f"═══ DƏRSLİK KONTEKSTİ: Sinif {grade}, «{topic}» ═══")
    output.append("")

    for i, chunk in enumerate(results, 1):
        output.append(f"━━━ Mənbə {i}: {chunk.get('source_file', '?')}, "
                       f"səh. {chunk['page_start']}-{chunk['page_end']} ━━━")
        if chunk.get("chapter"):
            output.append(f"Fəsil: {chunk['chapter']}")
        output.append("")
        # Tam mətni ver (max 3000 simvol per chunk)
        text = chunk["text"]
        if len(text) > 3000:
            text = text[:3000] + "\n... [davamı var, səh. " + str(chunk['page_end']) + "]"
        output.append(text)
        output.append("")

        if chunk.get("tables"):
            output.append("[CƏDVƏLLƏR]")
            output.append(chunk["tables"][:1000])
            output.append("")

    output.append(f"═══ KONTEKSTİN SONU ═══")
    return "\n".join(output)


# ─── KLİ ──────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="📐 Riyaziyyat dərslik chunk axtarışı"
    )
    parser.add_argument("--grade", "-g", type=int, help="Sinif (1-11)")
    parser.add_argument("--topic", "-t", type=str, help="Mövzu adı")
    parser.add_argument("--area", "-a", type=str,
                        choices=["ededler", "cebr", "hendese", "statistika", "olcme"],
                        help="Məzmun sahəsi")
    parser.add_argument("--keyword", "-k", type=str, help="Açar söz (bütün siniflərdə)")
    parser.add_argument("--list-topics", "-l", action="store_true",
                        help="Sinif üçün mövzu siyahısı")
    parser.add_argument("--context", "-c", action="store_true",
                        help="AI generasiya üçün kontekst formatı")
    parser.add_argument("--max", "-m", type=int, default=5,
                        help="Maksimum nəticə sayı")
    parser.add_argument("--stats", "-s", action="store_true",
                        help="Ümumi statistika göstər")
    parser.add_argument("--no-text", action="store_true",
                        help="Mətn göstərmə, yalnız metadata")

    args = parser.parse_args()

    # Statistika
    if args.stats:
        index = load_index()
        if index:
            print(f"\n📊 Dərslik İndeks Statistikası")
            print(f"   Yaradılma: {index['created_at']}")
            print(f"   Chunk sayı: {index['total_chunks']}")
            print(f"   Sinifler: {', '.join(index['grades'])}")
            print(f"   Sahələr: {', '.join(index['content_areas'])}")
            print()
            print("   Sinif üzrə chunk sayı:")
            for g, ids in sorted(index["index"]["by_grade"].items(), key=lambda x: int(x[0])):
                bar = "█" * (len(ids) * 30 // max(len(v) for v in index["index"]["by_grade"].values()))
                print(f"   Sinif {g:>2}: {bar} {len(ids)}")
        return

    # Mövzu siyahısı
    if args.list_topics and args.grade:
        topics = list_topics_for_grade(args.grade)
        if topics:
            print(f"\n📚 Sinif {args.grade} — Mövcud Mövzular:\n")
            for t in topics:
                print(f"  {t}")
        else:
            print(f"❌ Sinif {args.grade} üçün chunk tapılmadı.")
        return

    # AI kontekst
    if args.context and args.grade and args.topic:
        context = get_context_for_generation(args.grade, args.topic)
        print(context)
        return

    # Mövzu axtarışı
    if args.grade and args.topic:
        results = search_by_topic(args.grade, args.topic, args.max)
        if results:
            print(f"\n🔍 Sinif {args.grade}, mövzu «{args.topic}» — {len(results)} nəticə:\n")
            for chunk in results:
                print(format_chunk_for_output(chunk, include_text=not args.no_text))
        else:
            print(f"❌ Nəticə tapılmadı: sinif {args.grade}, mövzu «{args.topic}»")
        return

    # Content area axtarışı
    if args.grade and args.area:
        results = search_by_content_area(args.grade, args.area)
        print(f"\n🔍 Sinif {args.grade}, sahə «{args.area}» — {len(results)} chunk:\n")
        for chunk in results[:args.max]:
            print(format_chunk_for_output(chunk, include_text=not args.no_text))
        return

    # Keyword axtarışı
    if args.keyword:
        results = search_by_keyword(args.keyword)
        print(f"\n🔍 Açar söz «{args.keyword}» — {len(results)} nəticə:\n")
        for chunk in results[:args.max]:
            print(format_chunk_for_output(chunk, include_text=not args.no_text))
        return

    parser.print_help()


if __name__ == "__main__":
    main()
