#!/usr/bin/env python3
"""Dərslik chunk axtarışı. İstifadə: python3 scripts/search_chunks.py --grade 6 --topic faiz"""
import sys, json, argparse
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
CHUNKS_DIR = BASE_DIR / "derslikler" / "chunks"
INDEX_FILE = BASE_DIR / "derslikler" / "index.json"

def load_chunks(grade):
    chunks = []
    for f in sorted(CHUNKS_DIR.glob(f"sinif{grade}_*_chunks.json")):
        with open(f,"r",encoding="utf-8") as fh:
            chunks.extend(json.load(fh))
    return chunks

def search(grade, topic, max_r=5):
    chunks = load_chunks(grade)
    if not chunks: return []
    tl = topic.lower()
    tw = [w for w in tl.split() if len(w)>=3]
    scored = []
    for c in chunks:
        score = 0
        s = (c.get("text","").lower()+" "+(c.get("topic","") or "").lower()+" "+(c.get("chapter","") or "").lower()+" "+" ".join(c.get("keywords",[])))
        if tl in s: score += 10
        for w in tw: score += min(s.count(w),5)
        if c.get("chapter") and tl in c["chapter"].lower(): score += 15
        if score > 0: scored.append((score,c))
    scored.sort(key=lambda x:-x[0])
    return [c for _,c in scored[:max_r]]

def main():
    p = argparse.ArgumentParser(description="Dərslik chunk axtarışı")
    p.add_argument("--grade","-g",type=int)
    p.add_argument("--topic","-t",type=str)
    p.add_argument("--list-topics","-l",action="store_true")
    p.add_argument("--context","-c",action="store_true")
    p.add_argument("--stats","-s",action="store_true")
    p.add_argument("--max","-m",type=int,default=5)
    args = p.parse_args()

    if args.stats:
        if INDEX_FILE.exists():
            idx = json.loads(INDEX_FILE.read_text(encoding="utf-8"))
            print(f"\n📊 Chunk sayı: {idx['total_chunks']}")
            print(f"   Sinifler: {', '.join(idx['grades'])}")
            print(f"   Sahələr: {', '.join(idx['content_areas'])}")
            for g,ids in sorted(idx["index"]["by_grade"].items(),key=lambda x:int(x[0])):
                print(f"   Sinif {g:>2}: {'█'*(len(ids)//3)} {len(ids)}")
        else:
            total = 0
            for g in range(1,12):
                c = load_chunks(g)
                if c:
                    print(f"Sinif {g:>2}: {len(c)} chunk")
                    total += len(c)
            print(f"\nCəmi: {total} chunk")
        return

    if args.list_topics and args.grade:
        chunks = load_chunks(args.grade)
        if chunks:
            print(f"\n📚 Sinif {args.grade} — Mövzular:\n")
            seen = set()
            for c in chunks:
                label = c.get("chapter") or c.get("topic","?")
                if label and label not in seen:
                    seen.add(label)
                    print(f"  📍 {label[:80]} (səh. {c['page_start']}-{c['page_end']})")
        return

    if args.grade and args.topic:
        results = search(args.grade, args.topic, args.max)
        if args.context:
            for c in results:
                text = c.get("text","")[:4000]
                print(f"\n━━━ {c.get('source_file','?')}, səh. {c['page_start']}-{c['page_end']} ━━━")
                print(f"Fəsil: {c.get('chapter','—')}")
                print(f"Açar sözlər: {', '.join(c.get('keywords',[])[:10])}")
                print(f"\n{text}\n")
        else:
            print(f"\n🔍 {len(results)} nəticə:\n")
            for c in results:
                print(f"  📦 {c['id']} │ səh.{c['page_start']}-{c['page_end']} │ {c.get('topic','?')[:60]}")
        return

    p.print_help()

if __name__=="__main__":
    main()
