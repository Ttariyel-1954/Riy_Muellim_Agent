#!/usr/bin/env python3
"""
🔍 Dərslik chunk axtarış — Claude Code bu skripti istifadə edir

İstifadə:
  python3 scripts/search_derslik.py 6 faiz
  python3 scripts/search_derslik.py 8 pifaqor
  python3 scripts/search_derslik.py 5 kəsr
"""

import os
import sys
import re

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHUNKS_DIR = os.path.join(BASE_DIR, "derslikler", "chunks")


def search(grade, keyword):
    if not os.path.exists(CHUNKS_DIR):
        print("❌ Chunks papkası boşdur. Əvvəlcə: python3 scripts/pdf_to_chunks.py")
        return

    keyword_lower = keyword.lower()
    found = []

    for fn in sorted(os.listdir(CHUNKS_DIR)):
        if not fn.endswith('.md'):
            continue
        if f"sinif{grade}" not in fn:
            continue

        path = os.path.join(CHUNKS_DIR, fn)
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()

        if keyword_lower in content.lower():
            # Açar sözün ətrafındakı konteksti tap
            idx = content.lower().find(keyword_lower)
            start = max(0, idx - 200)
            end = min(len(content), idx + 500)
            context = content[start:end]

            found.append({
                "file": fn,
                "path": path,
                "context": context
            })

    if not found:
        print(f"Tapılmadı: sinif {grade}, '{keyword}'")
        # Mövcud chunk-ları göstər
        all_chunks = [f for f in os.listdir(CHUNKS_DIR) if f"sinif{grade}" in f]
        if all_chunks:
            print(f"\nSinif {grade} üçün mövcud chunk-lar:")
            for c in all_chunks[:10]:
                print(f"  • {c}")
        return

    print(f"🔍 {len(found)} nəticə tapıldı: sinif {grade}, '{keyword}'")
    print("=" * 70)

    for r in found:
        print(f"\n📄 Fayl: {r['file']}")
        print(f"📂 Yol:  {r['path']}")
        print("─" * 70)
        print(r['context'])
        print("─" * 70)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("İstifadə: python3 scripts/search_derslik.py [sinif] [açar_söz]")
        print("Nümunə:   python3 scripts/search_derslik.py 6 faiz")
        sys.exit(1)

    grade = sys.argv[1]
    keyword = " ".join(sys.argv[2:])
    search(grade, keyword)
